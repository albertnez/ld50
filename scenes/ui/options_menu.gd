extends Control

onready var _volume_menu := $"%VolumeMenu"

func _ready() -> void:
	_volume_menu.grab_focus_for_first_slider()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_tree().set_input_as_handled()
		EventBus.emit_signal("change_menu_scene", EventBus.TargetMenuScene.MAIN_MENU, 0)


func _on_BackButton_pressed() -> void:
	EventBus.emit_signal("change_menu_scene", EventBus.TargetMenuScene.MAIN_MENU, 0)
