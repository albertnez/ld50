extends Control

onready var _new_game_button := get_node("%NewGameButton")
onready var _exit_button := $"%ExitButton"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if GlobalState.latest_level_unlocked > 0:
		_new_game_button.text = "Continue"
	_new_game_button.grab_focus()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_tree().set_input_as_handled()
		return


func _on_NewGameButton_pressed() -> void:
	EventBus.emit_signal("change_menu_scene", EventBus.TargetMenuScene.MAIN_GAME, 0)
	return


func _on_SelectLevelButton_pressed() -> void:
	EventBus.emit_signal("change_menu_scene", EventBus.TargetMenuScene.LEVEL_SELECT, 0)


func _on_ExitButton_pressed() -> void:
	get_tree().quit()
