extends Control
class_name GameTerminatedMenu

onready var _next_level_button := $"%NextLevelButton"
onready var _restart_level_button := $"%RestartLevelButton"
onready var _quit_to_level_selection_button := $"%QuitToLevelSelectionButton"

onready var _first_level_completed_label := $"%FirstLevelCompleted"
onready var _level_completed_label := $"%LevelCompletedLabel"
onready var _full_game_completed_node := $"%FullGameCompleted"

onready var _game_over_label := $"%GameOverLabel"
onready var _game_over_reason_label := $"%GameOverReasonLabel"

onready var ALL_HIDEABLE_NODES = [
	_first_level_completed_label,
	_next_level_button,
	_level_completed_label,
	_full_game_completed_node,
	_restart_level_button,
	_game_over_label,
	_game_over_reason_label
]


func show_normal_level_completed() -> void:
	_update_visibility()
	_level_completed_label.show()
	_next_level_button.show()
	_next_level_button.grab_focus()


func show_first_level_completed() -> void:
	_update_visibility()
	_first_level_completed_label.show()
	_next_level_button.show()
	_next_level_button.grab_focus()


func show_full_game_completed() -> void:
	_update_visibility()
	_full_game_completed_node.show()
	_quit_to_level_selection_button.grab_focus()


func show_game_over(reason: String) -> void:
	_update_visibility()
	_game_over_reason_label.text = reason
	_game_over_reason_label.show()
	_game_over_label.show()
	_restart_level_button.show()
	_restart_level_button.grab_focus()


func _update_visibility() -> void:
	for node in ALL_HIDEABLE_NODES:
		node.hide()
	show()


func _on_QuitToLevelSelectionButton_confirmed() -> void:
	EventBus.emit_signal("change_menu_scene", EventBus.TargetMenuScene.LEVEL_SELECT, -1)


func _on_QuitToMainMenuButton_confirmed() -> void:
	EventBus.emit_signal("change_menu_scene", EventBus.TargetMenuScene.MAIN_MENU, -1)


func _on_NextLevelButton_pressed() -> void:
	EventBus.emit_signal("go_to_next_level")


func _on_RestartLevelButton_pressed() -> void:
	EventBus.emit_signal("level_restart")