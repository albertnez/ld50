extends Control

onready var _game_over_control = $GameOver
onready var _game_over_reason_label = $GameOver/VBoxContainer/ReasonLabel
onready var _person_crashed_label = $PlayingUI/LevelLabel/GameOver/PersonCrashedLabel
onready var _menu_ui = $Menu
onready var _playing_ui = $PlayingUI
onready var _trolley_timer_container = $PlayingUI/TimeUntilTrolley
onready var _trolley_timer_progress_bar = $PlayingUI/TimeUntilTrolley/ProgressBar

func _ready() -> void:
	EventBus.connect("trolley_crashed", self, "_on_EventBus_trolley_crashed")
	EventBus.connect("level_restart", self, "_on_EventBus_level_restart")
	EventBus.connect("new_level_waiting_for_trolley", self, "_on_EventBus_new_level_waiting_for_trolley")
	EventBus.connect("trolley_created", self, "_on_EventBus_trolley_created")
	EventBus.connect("person_crashed", self, "_on_EventBus_person_crashed")
	pass # Replace with function body.


func _on_EventBus_trolley_crashed() -> void:
	_game_over_reason_label.text = "Game Over: The trolley crashed!"
	_game_over_control.show()


func _on_EventBus_person_crashed() -> void:
	_game_over_reason_label.text = "Game Over: You died!"
	_game_over_control.show()


func _on_EventBus_level_restart() -> void:
	_game_over_control.hide()
	_menu_ui.hide()


func _on_EventBus_new_level_waiting_for_trolley(seconds: float) -> void:
	_trolley_timer_container.show()
	_trolley_timer_progress_bar.max_value = seconds
	_trolley_timer_progress_bar.value = seconds


func _on_EventBus_trolley_created() -> void:
	_trolley_timer_container.hide()



func _process(delta: float) -> void:
	_trolley_timer_progress_bar.value = max(0, _trolley_timer_progress_bar.value - delta)


