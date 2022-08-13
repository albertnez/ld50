extends Control

onready var _resume_button := $"%ResumeButton"

func _ready() -> void:
	_resume_button.grab_focus()


func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel"):
		get_tree().set_input_as_handled()
		EventBus.emit_signal("resume_game")


func _on_ResumeButton_pressed() -> void:
	EventBus.emit_signal("resume_game")


func _on_RestartButton_pressed() -> void:
	EventBus.emit_signal("level_restart")


func _on_QuitToLevelSelectionButton_confirmed() -> void:
	EventBus.emit_signal("change_menu_scene", EventBus.TargetMenuScene.LEVEL_SELECT, -1)


func _on_QuitToMainMenuButton_confirmed() -> void:
	EventBus.emit_signal("change_menu_scene", EventBus.TargetMenuScene.MAIN_MENU, -1)


func _on_Pause_visibility_changed() -> void:
	if visible:
		_resume_button.grab_focus()
