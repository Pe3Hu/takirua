@tool
extends Node2D
class_name Joint


signal overlapped(other: Joint)
signal unoverlapped(other: Joint)


@export var plank: Plank
@export var data: JointData:
	set(value):
		if data == value: return
		if data != null and data.changed.is_connected(_on_data_changed):
			data.changed.disconnect(_on_data_changed)
		data = value
		if data != null:
			data.changed.connect(_on_data_changed)
		_on_data_changed()


func _ready() -> void:
	if data == null:
		data = JointData.new()

	var area := get_node_or_null("Area2D") as Area2D
	if area != null:
		area.input_pickable = false
		if not area.area_entered.is_connected(_on_area_entered):
			area.area_entered.connect(_on_area_entered)
		if not area.area_exited.is_connected(_on_area_exited):
			area.area_exited.connect(_on_area_exited)

	_on_data_changed()


func _on_data_changed() -> void:
	queue_redraw()
	update_position()
	update_polygon()


func update_position() -> void:
	if data == null: return
	if not Digest.joint_to_windrose_to_anchor[data.type].has(data.windrose): return
	var l: float = Catalog.JOINT_SIDE_LENGTH
	var anchor: Vector2 = Digest.joint_to_windrose_to_anchor[data.type][data.windrose]
	position = anchor * l

	if data.type == Bozo.Joint.RECTANGLE:
		var shift_angle := float(data.rotation_step + 1) * PI / 2.0
		var shift := Vector2.from_angle(shift_angle) * Catalog.JOINT_SIDE_LENGTH * Catalog.RECTANGLE_WIDTH_SCALE / 2.0
		position += shift


func update_polygon() -> void:
	var cp := get_node_or_null("Area2D/CollisionPolygon2D") as CollisionPolygon2D
	if cp == null or data == null: return
	cp.polygon = PackedVector2Array(data.get_points())


# --- Area2D ---

func _on_area_entered(other_area: Area2D) -> void:
	var other := _joint_of(other_area)
	if other == null or other == self: return
	overlapped.emit(other)


func _on_area_exited(other_area: Area2D) -> void:
	var other := _joint_of(other_area)
	if other == null or other == self: return
	unoverlapped.emit(other)


func _joint_of(area: Area2D) -> Joint:
	var n: Node = area
	while n != null:
		if n is Joint:
			return n as Joint
		n = n.get_parent()
	return null


# --- Отрисовка ---

func _draw() -> void:
	if data == null: return
	var pts := data.get_points()

	if data.is_filled:
		draw_colored_polygon(pts, data.rect_color)

	if Catalog.JOINT_OUTLINE_WIDTH > 0.0:
		var outline_pts := pts.duplicate()
		outline_pts.append(pts[0])
		draw_polyline(outline_pts, data.outline_color, Catalog.JOINT_OUTLINE_WIDTH)
