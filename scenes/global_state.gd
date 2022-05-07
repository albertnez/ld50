extends Node


var level_completed = false
var level_lost = false
var in_menu = true
var level = 0
var in_true_end = false


func is_last_level() -> bool:
	return level == 11


# TODO: Encode it in the Level::TROLLEY_WAIT_TIME?
func trolley_waits_for_player() -> bool:
	return level < 3


func _ready() -> void:
	pass
