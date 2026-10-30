class_name CustomTextureButton
extends TextureButton


@export var hover_scale: Vector2 = Vector2(1.2, 1.2)
@export var pressed_scale: Vector2 = Vector2(0.9, 0.9)

var scale_tween: Tween


#region init
func _ready() -> void:
	mouse_entered.connect(_button_enter)
	mouse_exited.connect(_button_exit)
	mouse_exited.connect(_button_pressed)
	
	call_deferred("_init_pivot")
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

func _init_pivot() -> void:
	pivot_offset = size / 2.0

func _button_enter() -> void:
	if scale_tween and scale_tween.is_running():
		scale_tween.kill()
	
	scale_tween = create_tween().set_trans(Tween.TRANS_SINE)
	scale_tween.tween_property(self, "offset_transform_scale", hover_scale, 0.1)

func _button_exit() -> void:
	if scale_tween and scale_tween.is_running():
		scale_tween.kill()
	
	scale_tween = create_tween().set_trans(Tween.TRANS_SINE)
	scale_tween.tween_property(self, "offset_transform_scale", Vector2.ONE, 0.1)

func _button_pressed() -> void:
	if scale_tween and scale_tween.is_running():
		scale_tween.kill()
	
	scale_tween = create_tween().set_trans(Tween.TRANS_SINE)
	scale_tween.tween_property(self, "offset_transform_scale", pressed_scale, 0.1)
	
	await scale_tween.finished
	scale_tween = create_tween().set_trans(Tween.TRANS_SINE)
	scale_tween.tween_property(self, "offset_transform_scale", Vector2.ONE, 0.1)
#endregion
