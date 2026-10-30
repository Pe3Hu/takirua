@tool
class_name DropZone
extends Marker2D


@export var joint: Joint

func _draw():
	draw_circle(Vector2.ZERO, 32, Color.BLANCHED_ALMOND)

func select():
	for child in get_tree().get_nodes_in_group("zone"):
		child.deselect()
	modulate = Color.CORNFLOWER_BLUE

func deselect():
	modulate = Color.WHITE
