extends Control

onready var _trolley_crashed_label = $PlayingUI/TrolleyCrashedLabel
onready var _menu_ui = $Menu
onready var _playing_ui = $PlayingUI

func _ready() -> void:
	EventBus.connect("trolley_crashed", self, "_on_EventBus_trolley_crashed")
	EventBus.connect("level_restart", self, "_on_EventBus_level_restart")
	pass # Replace with function body.


func _on_EventBus_trolley_crashed() -> void:
	_trolley_crashed_label.visible = true


func _on_EventBus_level_restart() -> void:
	_menu_ui.hide()
