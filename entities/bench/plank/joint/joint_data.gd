class_name JointData
extends Resource


var plank: PlankData

@export var type: Bozo.Joint = Bozo.Joint.SQUARE:
	set(value):
		if type == value: return
		type = value
		changed.emit()
@export var windrose: Bozo.Windrose = Bozo.Windrose.N:
	set(value):
		if windrose == value: return
		windrose = value
		changed.emit()
@export var post: Bozo.Post = Bozo.Post.CORNER
@export var extent: Bozo.Extent = Bozo.Extent.SHORT
# 0 = 0°, 1 = 90°, 2 = 180°, 3 = 270°
@export_range(0, 3, 1) var rotation_step: int = 0:
	set(value):
		value = clampi(value, 0, 3)
		if rotation_step == value: return
		rotation_step = value
		changed.emit()
@export var rect_color: Color = Color.CORNFLOWER_BLUE:
	set(value):
		if rect_color == value: return
		rect_color = value
		changed.emit()
@export var is_filled: bool = false:
	set(value):
		if is_filled == value: return
		is_filled = value
		changed.emit()
@export var outline_color: Color = Color.BLACK:
	set(value):
		if outline_color == value: return
		outline_color = value
		changed.emit()


func _init(plank_: PlankData = null, type_: Bozo.Joint = Bozo.Joint.SQUARE, windrose_: Bozo.Windrose = Bozo.Windrose.N, extent_: Bozo.Extent = Bozo.Extent.SHORT) -> void:
	plank = plank_
	type = type_
	windrose = windrose_
	if Digest.windrose_to_extents[windrose].has(extent_):
		extent = extent_
	post = Digest.windrose_to_post[windrose]
	
	if Digest.joint_to_windrose_to_rotation.has(type):
		rotation_step = Digest.joint_to_windrose_to_rotation[type][windrose]

## Возвращает точки фигуры (уже повёрнутые) вокруг начала координат узла.
func get_points() -> PackedVector2Array:
	var h := Catalog.JOINT_SIDE_LENGTH / 2.0
	var pts := PackedVector2Array()

	match type:
		Bozo.Joint.SQUARE:
			pts = PackedVector2Array([
				Vector2(-h, -h),
				Vector2(h, -h),
				Vector2(h, h),
				Vector2(-h, h),
			])
		Bozo.Joint.TRIANGLE:
			# Прямоугольный треугольник: прямой угол в левом нижнем углу
			pts = PackedVector2Array([
				Vector2(-h, h),
				Vector2(-h, -h),
				Vector2(h, h),
			])
		Bozo.Joint.RECTANGLE:
			var rw := Catalog.JOINT_SIDE_LENGTH * Catalog.RECTANGLE_WIDTH_SCALE
			var rl := Catalog.JOINT_SIDE_LENGTH * float(Digest.extent_to_factor[extent])
			var hw := rw / 2.0
			var hl := rl / 2.0
			pts = PackedVector2Array([
				Vector2(-hl, -hw),
				Vector2(hl, -hw),
				Vector2(hl, hw),
				Vector2(-hl, hw),
			])

	var angle := float(rotation_step) * PI / 2.0

	if post == Bozo.Post.SIDE and type == Bozo.Joint.TRIANGLE:
		angle += PI / 4.0

	if angle != 0.0:
		for i in pts.size():
			pts[i] = pts[i].rotated(angle)

	return pts
