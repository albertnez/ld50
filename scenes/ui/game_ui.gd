extends Control

onready var _game_over_control = $GameOver
onready var _game_over_reason_label = $GameOver/VBoxContainer/ReasonLabel
onready var _person_crashed_label = $PlayingUI/LevelLabel/GameOver/PersonCrashedLabel
onready var _playing_ui = $PlayingUI
onready var _trolley_timer_container = $PlayingUI/TimeUntilTrolley
onready var _trolley_timer_progress_bar = $PlayingUI/TimeUntilTrolley/ProgressBar
onready var _level_completed = $LevelCompleted

func _ready() -> void:
	EventBus.connect("level_restart", self, "_on_EventBus_level_restart")
	EventBus.connect("new_level_waiting_for_trolley", self, "_on_EventBus_new_level_waiting_for_trolley")
	EventBus.connect("trolley_created", self, "_on_EventBus_trolley_created")
	EventBus.connect("level_completed", self, "_on_EventBus_level_completed")
	EventBus.connect("trolley_crashed", self, "_on_game_over", ["The trolley crashed!"])
	EventBus.connect("person_crashed", self, "_on_game_over", ["You died!"])
	EventBus.connect("trolley_killed_someone", self, "_on_game_over", ["The trolley killed someone"])
	pass # Replace with function body.


func _on_game_over(reason: String) -> void:
	_game_over_reason_label.text = str("Game Over: ", reason)
	_game_over_control.show()


func _on_EventBus_level_restart() -> void:
	_game_over_control.hide()
	_level_completed.hide()


func _on_EventBus_new_level_waiting_for_trolley(seconds: float) -> void:
	_trolley_timer_container.show()
	_trolley_timer_progress_bar.max_value = seconds
	_trolley_timer_progress_bar.value = seconds


func _on_EventBus_trolley_created() -> void:
	_trolley_timer_container.hide()


func _on_EventBus_level_completed() -> void:
	_level_completed.show()


func _process(delta: float) -> void:
	_trolley_timer_progress_bar.value = max(0, _trolley_timer_progress_bar.value - delta)


