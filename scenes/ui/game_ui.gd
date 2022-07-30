extends Control

onready var _game_over_control = $MarginContainer/GameOver
onready var _game_over_reason_label = $MarginContainer/GameOver/VBoxContainer/ReasonLabel
onready var _playing_ui = $MarginContainer/PlayingUI
onready var _level_completed = $MarginContainer/LevelCompleted
onready var _level_label = $MarginContainer/PlayingUI/LevelLabel
onready var _first_time_gameover = $MarginContainer/GameOver/VBoxContainer/FirstTimeGameOver
onready var _last_time_gameover = $MarginContainer/GameOver/VBoxContainer/LastTimeGameOver
onready var _restart_label = $MarginContainer/GameOver/VBoxContainer/RestartLabel
onready var _fast_forward_button = get_node("%FastForwardButton")


func _ready() -> void:
	var _u = null  # Unused
	_u = EventBus.connect("level_restart", self, "_on_EventBus_level_restart")
	_u = EventBus.connect("new_level_waiting_for_trolley", self, "_on_EventBus_new_level_waiting_for_trolley")
	_u = EventBus.connect("level_completed", self, "_on_EventBus_level_completed")
	_u = EventBus.connect("trolley_crashed", self, "_on_game_over", ["The trolley crashed off piste!", false])
	_u = EventBus.connect("person_crashed", self, "_on_game_over", ["You died!", false])
	_u = EventBus.connect("trolley_killed_someone", self, "_on_game_over", ["The trolley killed someone", true])
	_u = EventBus.connect("trolley_crash_with_trolley", self, "_on_game_over", ["The trolleys crashed with each other!", true])


func _on_game_over(msg: String, killed_someone: bool) -> void:
	_game_over_reason_label.text = str("Game Over: ", msg)
	_first_time_gameover.visible = killed_someone and GlobalState.level == 0
	_restart_label.visible = not (killed_someone and GlobalState.level == 0)
	if GlobalState.in_true_end:
		_game_over_reason_label.text = "Game Over: the end"
		_restart_label.hide()
		_last_time_gameover.show()
	_game_over_control.show()


func _on_EventBus_level_restart() -> void:
	_fast_forward_button.pressed = false
	_game_over_control.hide()
	_level_completed.hide()
	_level_label.text = str("Level ", GlobalState.level)
	_playing_ui.visible = not GlobalState.in_main_menu



func _on_EventBus_level_completed() -> void:
	_level_completed.show()


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("fast_forward"):
		_fast_forward_button.pressed = not _fast_forward_button.pressed


func _on_FastForwardButton_toggled(button_pressed: bool) -> void:
	GlobalState.fast_forward = button_pressed
	pass # Replace with function body.
