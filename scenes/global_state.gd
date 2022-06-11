extends Node


var level_completed = false
var level_lost = false
var in_main_menu = false
var level = 0
var in_true_end = false

const TROLLEY_COLOR_LIST := [
	Color("ee8695"),  # Palette Red.
	Color.aquamarine,
]

const MENU_LEVEL := preload("res://scenes/levels/menu/menu_level.tscn")

const LEVEL_LIST := [
	# Introduction
	#0
	preload("res://scenes/levels/tutorial/move_and_toggle.tscn"),
	preload("res://scenes/levels/tutorial/first_loop.tscn"),
	preload("res://scenes/levels/tutorial/bifurcation_direction.tscn"),
	preload("res://scenes/levels/tutorial/no_more_delay.tscn"),

	# Easy
	preload("res://scenes/levels/easy/first_offpiste.tscn"),
	#5
	preload("res://scenes/levels/easy/wider_loop.tscn"),
	preload("res://scenes/levels/easy/first_reverse.tscn"),
	preload("res://scenes/levels/easy/wider_reverse.tscn"),
	
	# Medium
	preload("res://scenes/levels/medium/two_train_delay_one.tscn"),
	
	# Others
	preload("res://scenes/levels/level08.tscn"),
	#10
	preload("res://scenes/levels/medium/density.tscn"),
	preload("res://scenes/levels/level10.tscn"),
	preload("res://scenes/levels/level11.tscn"),
	preload("res://scenes/levels/level12.tscn"),
]

const NUM_MAX_TROLLEYS = 8
var _trolley_has_loop : Array


func set_trolley_has_loop(id: int, has_loop: bool) -> void:
	_trolley_has_loop[id] = has_loop


func all_trolleys_have_loop(num_trolleys: int) -> bool:
	for id in num_trolleys:
		if not _trolley_has_loop[id]:
			return false
	return true


func set_new_level(new_level: int, new_in_main_menu: bool) -> void:
	in_main_menu = new_in_main_menu
	level = new_level
	level_completed = false
	level_lost = false
	for id in NUM_MAX_TROLLEYS:
		_trolley_has_loop[id] = false


func get_level_scene() -> PackedScene:
	if in_main_menu:
		return MENU_LEVEL
	return LEVEL_LIST[level]


func is_last_level() -> bool:
	return level == LEVEL_LIST.size()


func _ready() -> void:
	_trolley_has_loop.resize(NUM_MAX_TROLLEYS)
