extends Control

onready var _trolley_crashed_label = $PlayingUI/TrolleyCrashedLabel
onready var _menu_ui = $Menu
onready var _playing_ui = $PlayingUI
onready var _trolley_timer_container = $PlayingUI/TimeUntilTrolley
onready var _trolley_timer_progress_bar = $PlayingUI/TimeUntilTrolley/ProgressBar

func _ready() -> void:
	EventBus.connect("trolley_crashed", self, "_on_EventBus_trolley_crashed")
	EventBus.connect("level_restart", self, "_on_EventBus_level_restart")
	EventBus.connect("new_level_waiting_for_trolley", self, "_on_EventBus_new_level_waiting_for_trolley")
	EventBus.connect("trolley_created", self, "_on_EventBus_trolley_created")
	pass # Replace with function body.


func _on_EventBus_trolley_crashed() -> void:
	_trolley_crashed_label.visible = true


func _on_EventBus_level_restart() -> void:
	_menu_ui.hide()


func _on_EventBus_new_level_waiting_for_trolley(seconds: float) -> void:
	_trolley_timer_container.show()
	_trolley_timer_progress_bar.max_value = seconds
	_trolley_timer_progress_bar.value = seconds


func _on_EventBus_trolley_created() -> void:
	_trolley_timer_container.hide()


func _process(delta: float) -> void:
	_trolley_timer_progress_bar.value = max(0, _trolley_timer_progress_bar.value - delta)


