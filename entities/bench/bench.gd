extends Node2D

const plank_scene = preload('uid://cffth16i5mnoo')

func _ready() -> void:
	position = get_viewport_rect().size / 2
	init_planks()

func init_planks() -> void:
	var grid = Vector2i(6, 3)
	var l = Catalog.PLANK_SIZE + Vector2.ONE * Catalog.JOINT_OUTLINE_WIDTH * 2
	
	for _x in grid.x:
		for _y in grid.y:
			var coord = Vector2(_x, _y) + Vector2.ONE * 0.5
			var anchor = (coord - grid * 0.5) * l
			add_plank(anchor)

func add_plank(position_: Vector2 = Vector2.ZERO) -> void:
	var plank = plank_scene.instantiate()
	plank.position = position_ 
	%Planks.add_child(plank)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_SPACE:
				var local_pos = %Planks.to_local(get_global_mouse_position())
				add_plank(local_pos)
