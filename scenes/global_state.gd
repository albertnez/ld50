extends Node


var level_completed = false
var level_lost = false
var in_menu = true
var level
var in_true_end = false

func is_last_level() -> bool:
	return level == 10

func _ready() -> void:
	pass
