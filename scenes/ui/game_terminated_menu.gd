extends Control

onready var _next_level_button := $"%NextLevelButton"

func _on_GameTerminatedMenu_visibility_changed() -> void:
	if visible:
		_next_level_button.grab_focus()


func _on_QuitToLevelSelectionButton_confirmed() -> void:
	EventBus.emit_signal("change_menu_scene", EventBus.TargetMenuScene.LEVEL_SELECT, -1)


func _on_QuitToMainMenuButton_confirmed() -> void:
	EventBus.emit_signal("change_menu_scene", EventBus.TargetMenuScene.MAIN_MENU, -1)


func _on_NextLevelButton_pressed() -> void:
	EventBus.emit_signal("go_to_next_level")


