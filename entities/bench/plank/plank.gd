@tool
extends Node2D
class_name Plank

const SNAP_ATTACH_DISTANCE := 80.0
const SNAP_DETACH_DISTANCE := 160.0
const CANDIDATE_EXTRA_RADIUS := 240.0
const FLIP_DURATION := 0.25

var joint_scene = preload('uid://drtnjkchjbuad')

var data: PlankData:
	set(value_):
		data = value_
		init_joints()

var selected := false
var rest_point: Vector2
var rest_rotation := 0.0
var _target := Vector2.ZERO

var is_flipped := false
var _is_flipping := false

var _candidates: Array[Dictionary] = []
var _candidate_index: int = 0
var _snapped_pair: Dictionary = {}
var _snap_mouse_origin: Vector2 = Vector2.ZERO

var _highlight_self: Joint = null
var _highlight_other: Joint = null

var _outward_cache: Dictionary = {}
var _point_query: PhysicsPointQueryParameters2D = null

# Кеш формы тела для детекции пересечения (ищется один раз)
var _body_shape_info: Dictionary = {}
var _body_shape_info_done := false


func _ready() -> void:
	# Инициализируем до await, чтобы _physics_process не дёрнул плашку к (0,0)
	rest_point = global_position
	rest_rotation = rotation
	_target = global_position

	_point_query = PhysicsPointQueryParameters2D.new()
	_point_query.collide_with_areas = true
	_point_query.collide_with_bodies = false

	data = PlankData.new()

	if Engine.is_editor_hint():
		set_physics_process(false)
		set_process_input(false)
		return

	await get_tree().process_frame
	_target = global_position
	rest_point = global_position
	rest_rotation = rotation


func init_joints() -> void:
	_outward_cache.clear()
	for child in %Joints.get_children():
		child.queue_free()
	for joint_data in data.joints:
		add_joint(joint_data)


func add_joint(joint_data_: JointData) -> void:
	var joint = joint_scene.instantiate()
	joint.plank = self
	joint.data = joint_data_
	joint.overlapped.connect(_on_joint_overlapped.bind(joint))
	joint.unoverlapped.connect(_on_joint_unoverlapped.bind(joint))
	%Joints.add_child(joint)


# --- Движение ---

func _physics_process(delta: float) -> void:
	if not selected:
		global_position = global_position.lerp(rest_point, 1.0 - exp(-10.0 * delta))
		rotation = lerp_angle(rotation, rest_rotation, 1.0 - exp(-12.0 * delta))
		return

	var mouse := get_global_mouse_position()

	# Во время переворота снап не считаем: промежуточные scale.x ломают геометрию
	if _is_flipping:
		_target = _target.lerp(mouse, 1.0 - exp(-8.0 * delta))
		global_position = global_position.lerp(_target, 1.0 - exp(-15.0 * delta))
		rotation = lerp_angle(rotation, (_target - global_position).angle(), 1.0 - exp(-8.0 * delta))
		return

	var snap = _update_snapping(mouse)

	if snap is Transform2D:
		global_position = global_position.lerp(snap.origin, 1.0 - exp(-20.0 * delta))
		rotation = lerp_angle(rotation, snap.get_rotation(), 1.0 - exp(-25.0 * delta))
	else:
		_target = _target.lerp(mouse, 1.0 - exp(-8.0 * delta))
		global_position = global_position.lerp(_target, 1.0 - exp(-15.0 * delta))
		rotation = lerp_angle(rotation, (_target - global_position).angle(), 1.0 - exp(-8.0 * delta))


# --- Ввод ---

func _flip() -> void:
	if _is_flipping:
		return
	_is_flipping = true

	# Старые кандидаты/снап рассчитаны для другой ориентации — сбрасываем
	_snapped_pair = {}
	_candidates.clear()
	_candidate_index = 0
	_refresh_highlight()

	var to_x := 1.0 if is_flipped else -1.0
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(self, "scale:x", to_x, FLIP_DURATION)
	tween.finished.connect(func() -> void:
		is_flipped = not is_flipped
		_is_flipping = false
		_refresh_highlight()
	)


# Мгновенный переворот — без анимации. Меняет и флаг, и знак scale.x.
func _flip_instant() -> void:
	if _is_flipping:
		return
	is_flipped = not is_flipped
	scale.x = -1.0 if is_flipped else 1.0


func _on_area_2d_input_event(_v, _e, _i) -> void:
	if Engine.is_editor_hint(): return
	if not Input.is_action_just_pressed("click"): return
	if not _is_topmost_plank_under_mouse(): return

	selected = true
	_target = get_global_mouse_position()
	_snapped_pair = {}
	_candidate_index = 0
	_refresh_highlight()


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and selected:
		match event.keycode:
			KEY_W:
				_flip()
				get_viewport().set_input_as_handled()
				return
			KEY_SPACE:
				_regenerate_data()
				get_viewport().set_input_as_handled()
				return

	if event is InputEventKey and event.pressed and not event.echo and selected and not _candidates.is_empty():
		match event.keycode:
			KEY_E:
				_cycle_candidate(1)
				get_viewport().set_input_as_handled()
				return
			KEY_Q:
				_cycle_candidate(-1)
				get_viewport().set_input_as_handled()
				return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		if not selected: return
		selected = false
		rest_point = global_position
		rest_rotation = rotation
		_snapped_pair = {}
		_refresh_highlight()


func _cycle_candidate(dir: int) -> void:
	if _candidates.is_empty(): return
	_candidate_index = (_candidate_index + dir + _candidates.size()) % _candidates.size()

	var c = _candidates[_candidate_index]
	var sj = c.get("self_joint")
	var oj = c.get("other_joint")
	if not is_instance_valid(sj) or not is_instance_valid(oj): return

	_snapped_pair = _dup_pair(c)
	_snap_mouse_origin = get_global_mouse_position()

	# Учитываем возможный переворот — если текущая ориентация пересекается,
	# сразу переворачиваем и берём правильную трансформацию.
	var resolved := _compute_resolved_snap(sj, oj)
	if resolved.needs_flip:
		_flip_instant()

	var snap: Transform2D = resolved.transform
	global_position = snap.origin
	rotation = snap.get_rotation()
	_target = snap.origin

	_refresh_highlight()


# --- Коллизии ---

func _on_joint_overlapped(other: Joint, self_joint: Joint) -> void:
	if other.plank == self: return
	if self_joint.data == null or other.data == null: return

	# Без аллокации _all_joints(); мышь и тип вынесены из цикла
	var mouse := get_global_mouse_position()
	for child in %Joints.get_children():
		if not (child is Joint): continue
		if not _is_compatible(child, other): continue
		var snap := _compute_snap_transform_ex(child, other, is_flipped)
		var close := child == self_joint or mouse.distance_to(snap.origin) <= CANDIDATE_EXTRA_RADIUS
		if not close and _should_check_flip(child, other):
			var snap_alt := _compute_snap_transform_ex(child, other, not is_flipped)
			close = mouse.distance_to(snap_alt.origin) <= CANDIDATE_EXTRA_RADIUS
		if close:
			_add_candidate(child, other)

	_refresh_highlight()


func _on_joint_unoverlapped(_other: Joint, _self_joint: Joint) -> void:
	_prune_candidates()


func _prune_candidates() -> void:
	# in-place compact вместо remove_at в обратном цикле
	var mouse := get_global_mouse_position()
	var write := 0
	for i in range(_candidates.size()):
		var c = _candidates[i]
		var sj = c.get("self_joint")
		var oj = c.get("other_joint")
		if not is_instance_valid(sj) or not is_instance_valid(oj):
			continue
		if _same_pair(c, _snapped_pair):
			_candidates[write] = c
			write += 1
			continue
		var snap := _compute_snap_transform(sj, oj)
		if mouse.distance_to(snap.origin) > CANDIDATE_EXTRA_RADIUS:
			continue
		_candidates[write] = c
		write += 1
	_candidates.resize(write)
	_candidate_index = clampi(_candidate_index, 0, maxi(_candidates.size() - 1, 0))


# --- Кандидаты ---

func _add_candidate(mine: Joint, other: Joint) -> void:
	for c in _candidates:
		if c.self_joint == mine and c.other_joint == other: return
	_candidates.append({ self_joint = mine, other_joint = other })
func _is_compatible(mine: Joint, other: Joint) -> bool:
	if mine.data == null or other.data == null: return false
	if mine.data.type != other.data.type: return false

	if other.data.type == Bozo.Joint.TRIANGLE:
		var mp = Digest.windrose_to_post.get(mine.data.windrose)
		var op = Digest.windrose_to_post.get(other.data.windrose)
		if mp != null and op != null and mp == op:
			return false

	# Для прямоугольников проверка extent больше не нужна — тип сам по себе
	# кодирует длину (SHORT_RECTANGLE != LONG_RECTANGLE уже отсекается выше).

	return true


func _should_check_flip(sj: Joint, oj: Joint) -> bool:
	if sj.data == null or oj.data == null: return false
	# 180°-неоднозначность есть только у прямоугольных джойнтов.
	return sj.data.type == Bozo.Joint.SHORT_RECTANGLE \
		or sj.data.type == Bozo.Joint.LONG_RECTANGLE


func _same_pair(a: Dictionary, b: Dictionary) -> bool:
	if a.is_empty() or b.is_empty(): return false
	return a.get("self_joint") == b.get("self_joint") and a.get("other_joint") == b.get("other_joint")


func _dup_pair(p: Dictionary) -> Dictionary:
	return { self_joint = p.get("self_joint"), other_joint = p.get("other_joint") }


# --- Подсветка ---

func _refresh_highlight() -> void:
	for i in range(_candidates.size() - 1, -1, -1):
		var c = _candidates[i]
		if not is_instance_valid(c.get("self_joint")) or not is_instance_valid(c.get("other_joint")):
			_candidates.remove_at(i)

	if _highlight_self != null and is_instance_valid(_highlight_self):
		_highlight_self.modulate = Color.WHITE
	if _highlight_other != null and is_instance_valid(_highlight_other):
		_highlight_other.modulate = Color.WHITE
	_highlight_self = null
	_highlight_other = null

	if not selected: return

	var target: Dictionary = _snapped_pair if not _snapped_pair.is_empty() else {}
	if target.is_empty() and not _candidates.is_empty():
		target = _candidates[0]

	if target.is_empty(): return
	if not is_instance_valid(target.get("self_joint")) or not is_instance_valid(target.get("other_joint")): return

	_highlight_self = target.self_joint
	_highlight_other = target.other_joint
	_highlight_self.modulate = Color.CORNFLOWER_BLUE
	_highlight_other.modulate = Color.CORNFLOWER_BLUE


# --- Снап ---

func _update_snapping(mouse: Vector2) -> Variant:
	var sj: Joint
	var oj: Joint
	
	# Удержание уже активного снапа
	if not _snapped_pair.is_empty():
		sj = _snapped_pair.get("self_joint")
		oj = _snapped_pair.get("other_joint")
		if not is_instance_valid(sj) or not is_instance_valid(oj):
			_snapped_pair = {}
		elif mouse.distance_to(_snap_mouse_origin) <= SNAP_DETACH_DISTANCE:
			var resolved := _compute_resolved_snap(sj, oj)
			if resolved.needs_flip:
				_flip_instant()
			return resolved.transform
		else:
			_snapped_pair = {}

	if _candidates.is_empty():
		return null

	var best_idx := -1
	var best_dist := SNAP_ATTACH_DISTANCE
	var best_cur: Transform2D = Transform2D.IDENTITY
	var best_alt: Transform2D = Transform2D.IDENTITY
	#var best_needs_flip := false
	var best_alt_valid := false
	var write := 0

	for i in range(_candidates.size()):
		var c = _candidates[i]
		sj = c.get("self_joint")
		oj = c.get("other_joint")
		if not is_instance_valid(sj) or not is_instance_valid(oj):
			continue

		var snap_cur := _compute_snap_transform_ex(sj, oj, is_flipped)
		var d := mouse.distance_to(snap_cur.origin)
		var snap_alt := Transform2D.IDENTITY
		var d_alt := INF
		var alt_valid := false

		if _should_check_flip(sj, oj):
			snap_alt = _compute_snap_transform_ex(sj, oj, not is_flipped)
			d_alt = mouse.distance_to(snap_alt.origin)
			alt_valid = true

		var d_best = min(d, d_alt)
		if d_best > CANDIDATE_EXTRA_RADIUS:
			continue

		if d_best < best_dist:
			best_dist = d_best
			best_idx = write
			best_cur = snap_cur
			best_alt = snap_alt
			best_alt_valid = alt_valid
			#best_needs_flip = (d_alt < d)
			_snapped_pair = _dup_pair(c)
			_snap_mouse_origin = mouse

		_candidates[write] = c
		write += 1

	_candidates.resize(write)

	if best_idx == -1:
		return null

	_candidate_index = best_idx

	var best = _candidates[best_idx]
	sj = best.self_joint
	oj = best.other_joint

	# Разрешаем переворот только для прямоугольных джойнтов.
	if _should_check_flip(sj, oj):
		# Проверяем текущую ориентацию на пересечение тела
		if _would_overlap_at(best_cur, oj.plank, is_flipped):
			# Текущая пересекается — если противоположная нет, мгновенно переворачиваем
			if best_alt_valid and not _would_overlap_at(best_alt, oj.plank, not is_flipped):
				_flip_instant()
				return best_alt
		# Иначе остаёмся в текущей ориентации
		return best_cur

	return best_cur


func _compute_resolved_snap(sj: Joint, oj: Joint) -> Dictionary:
	var cur := _compute_snap_transform_ex(sj, oj, is_flipped)
	if not _should_check_flip(sj, oj) or not _would_overlap_at(cur, oj.plank, is_flipped):
		return { transform = cur, needs_flip = false }
	var alt := _compute_snap_transform_ex(sj, oj, not is_flipped)
	if not _would_overlap_at(alt, oj.plank, not is_flipped):
		return { transform = alt, needs_flip = true }
	return { transform = cur, needs_flip = false }



func _compute_snap_transform(self_joint: Joint, other_joint: Joint) -> Transform2D:
	return _compute_snap_transform_ex(self_joint, other_joint, is_flipped)


# to_local всегда возвращает «сырые» локальные координаты, независимо от текущего scale.
# Поэтому для симуляции перевёрнутого состояния достаточно домножить X на -1.
func _compute_snap_transform_ex(self_joint: Joint, other_joint: Joint, target_flipped: bool) -> Transform2D:
	var my_joint_local: Vector2 = to_local(self_joint.global_position)
	var my_dir_local: Vector2 = _joint_outward_dir(self_joint)

	if target_flipped:
		my_joint_local.x = -my_joint_local.x
		my_dir_local.x = -my_dir_local.x

	var other_outward_world: Vector2 = other_joint.plank.global_transform.basis_xform(
		_joint_outward_dir(other_joint)
	).normalized()

	var target_dir_world: Vector2
	if self_joint.data.type == Bozo.Joint.TRIANGLE:
		target_dir_world = other_outward_world
	else:
		target_dir_world = -other_outward_world

	var target_rot: float = target_dir_world.angle() - my_dir_local.angle()
	var my_joint_offset: Vector2 = my_joint_local.rotated(target_rot)
	var target_pos: Vector2 = other_joint.global_position - my_joint_offset

	return Transform2D(target_rot, target_pos)


# Кеш: outward-направление зависит только от j.data (неизменяемо в рантайме).
func _joint_outward_dir(j: Joint) -> Vector2:
	var cached = _outward_cache.get(j)
	if cached != null:
		return cached
	var result := _compute_joint_outward_dir(j)
	_outward_cache[j] = result
	return result


func _compute_joint_outward_dir(j: Joint) -> Vector2:
	var pts = j.data.get_points()
	if pts.size() < 3: return Vector2.RIGHT

	if j.data.type == Bozo.Joint.TRIANGLE:
		var max_d := -1.0
		var base_a := Vector2.ZERO
		var base_b := Vector2.ZERO
		var tip := Vector2.ZERO

		for i in range(3):
			var p1 = pts[i]
			var p2 = pts[(i + 1) % 3]
			var p3 = pts[(i + 2) % 3]
			var d = p1.distance_squared_to(p2)
			if d > max_d:
				max_d = d
				base_a = p1
				base_b = p2
				tip = p3

		var base_center = (base_a + base_b) * 0.5
		var outward = (tip - base_center).normalized()
		if outward.length_squared() > 0.001:
			return outward

	var m: Dictionary = Digest.joint_to_windrose_to_anchor[j.data.type]
	if not m.has(j.data.windrose): return Vector2.RIGHT
	var anchor: Vector2 = m[j.data.windrose]

	if anchor.length_squared() < 0.001:
		return Vector2.RIGHT

	var a = anchor.normalized()

	if abs(a.x) > abs(a.y):
		return Vector2(sign(a.x), 0)
	else:
		return Vector2(0, sign(a.y))


# --- Проверка пересечения тел ---

# Ищет форму тела плашки (первый CollisionShape2D/CollisionPolygon2D не под %Joints).
# Кешируется один раз.
func _get_body_shape_info() -> Dictionary:
	if _body_shape_info_done:
		return _body_shape_info
	_body_shape_info_done = true

	var joints_node := find_child("Joints", true, false)

	for cs in find_children("*", "CollisionShape2D", true, false):
		if joints_node != null and joints_node.is_ancestor_of(cs): continue
		var s := (cs as CollisionShape2D).shape
		if s == null: continue
		_body_shape_info = { shape = s, local_transform = (cs as Node2D).transform }
		return _body_shape_info

	for cp in find_children("*", "CollisionPolygon2D", true, false):
		if joints_node != null and joints_node.is_ancestor_of(cp): continue
		var poly := ConvexPolygonShape2D.new()
		poly.points = (cp as CollisionPolygon2D).polygon
		_body_shape_info = { shape = poly, local_transform = (cp as Node2D).transform }
		return _body_shape_info

	return {}


# Проверяет: если плашка встанет в target_transform (с учётом target_flipped),
# пересечётся ли её тело с телом other (исключая их joint'ы).
# Возвращает true при пересечении.
func _would_overlap_at(target_transform: Transform2D, other: Plank, target_flipped: bool) -> bool:
	var info := _get_body_shape_info()
	if info.is_empty():
		return false

	var sx := -1.0 if target_flipped else 1.0
	var scale_mat := Transform2D(Vector2(sx, 0), Vector2(0, 1), Vector2.ZERO)
	var plank_world := Transform2D(target_transform.get_rotation(), target_transform.origin) * scale_mat
	var shape_world: Transform2D = plank_world * (info.local_transform as Transform2D)

	var params := PhysicsShapeQueryParameters2D.new()
	params.shape = info.shape
	params.transform = shape_world
	params.collide_with_areas = true
	params.collide_with_bodies = true

	var other_joints := other.find_child("Joints", true, false)

	var hits := get_world_2d().direct_space_state.intersect_shape(params, 16)
	for h in hits:
		var col = h.collider
		if col == null or not is_instance_valid(col): continue
		var p := _find_plank(col)
		if p != other: continue
		# Пропускаем joint-области other — их пересечение ожидаемо при снапе
		if other_joints != null and other_joints.is_ancestor_of(col): continue
		return true
	return false


# --- Topmost ---

func _is_topmost_plank_under_mouse() -> bool:
	# Переиспользуемый _point_query вместо создания каждый вызов
	_point_query.position = get_global_mouse_position()
	var hits := get_world_2d().direct_space_state.intersect_point(_point_query, 32)

	var top: Plank = null
	for h in hits:
		var p := _find_plank(h.collider)
		if p == null: continue
		if top == null: top = p
		elif p.z_index > top.z_index: top = p
		elif p.z_index == top.z_index and p.is_greater_than(top): top = p
	return top == self


func _find_plank(n: Node) -> Plank:
	var cur: Node = n
	while cur != null:
		if cur is Plank: return cur as Plank
		cur = cur.get_parent()
	return null

func _regenerate_data() -> void:
	_snapped_pair = {}
	_candidates.clear()
	_candidate_index = 0
	_highlight_self = null
	_highlight_other = null
	
	data = PlankData.new()
	
	_refresh_highlight()
