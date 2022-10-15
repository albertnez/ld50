extends Control

onready var _playing_ui = $MarginContainer/PlayingUI

onready var _level_terminated_menu := $"%GameTerminatedMenu"
onready var _level_label = $MarginContainer/PlayingUI/LevelLabel


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
	""" Handles 3 situations of 'Game Over':
		- First level (tutorial), the trolley inevitably kills person on tracks.
		- Last level (true end), the trolley inevitably kills person on tracks.
		- Normal 'Game Over'
	"""
	# TODO: Wire this.
	if killed_someone and GlobalState.level == 0:
		_level_terminated_menu.show_first_level_completed()
	elif GlobalState.in_true_end:
		_level_terminated_menu.show_full_game_completed()
	else:
		_level_terminated_menu.show_game_over(msg)
	return


func _on_EventBus_level_restart() -> void:
	_level_terminated_menu.hide()
	var level = GlobalState.level
	_level_label.text = str("Level ", level+1, ": ", GlobalState.get_level_name(level))
	_playing_ui.visible = not GlobalState.in_main_menu


func _on_EventBus_level_completed() -> void:
	_level_terminated_menu.show_normal_level_completed()
