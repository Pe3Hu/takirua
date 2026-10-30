extends Node2D

var selected = false
var rest_point
var rest_nodes = []
var _target := Vector2.ZERO

func _ready():
	rest_nodes = get_tree().get_nodes_in_group("zone")
	await get_tree().process_frame
	rest_point = rest_nodes[1].global_position
	rest_nodes[1].select()
	_target = global_position

func _physics_process(delta):
	if rest_point == null: return
	if selected:
		_target = _target.lerp(get_global_mouse_position(), 1.0 - exp(-8.0 * delta))
		global_position = global_position.lerp(_target, 1.0 - exp(-15.0 * delta))
		rotation = lerp_angle(rotation, (_target - global_position).angle(), 1.0 - exp(-8.0 * delta))
	else:
		global_position = global_position.lerp(rest_point, 1.0 - exp(-10.0 * delta))
		rotation = lerp_angle(rotation, 0.0, 1.0 - exp(-10.0 * delta))

func _input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		selected = false
		var shortest := 75.0
		for child in rest_nodes:
			var d = global_position.distance_to(child.global_position)
			if d < shortest:
				child.select()
				rest_point = child.global_position
				shortest = d

func _on_area_2d_input_event(_v, _e, _i):
	if Input.is_action_just_pressed("click"):
		selected = true
		_target = get_global_mouse_position()
