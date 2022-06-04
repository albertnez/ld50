extends Node


var level_completed = false
var level_lost = false
var in_menu = true
var level = 0
var in_true_end = false

const LEVEL_LIST := [
	# Introduction
	preload("res://scenes/levels/tutorial/move_and_toggle.tscn"),
	preload("res://scenes/levels/tutorial/first_loop.tscn"),
	preload("res://scenes/levels/tutorial/bifurcation_direction.tscn"),
	preload("res://scenes/levels/tutorial/no_more_delay.tscn"),

	# Easy
	preload("res://scenes/levels/easy/first_offpiste.tscn"),
	preload("res://scenes/levels/easy/wider_loop.tscn"),
	preload("res://scenes/levels/easy/first_reverse.tscn"),
	preload("res://scenes/levels/easy/wider_reverse.tscn"),
	
	# Others
	preload("res://scenes/levels/level08.tscn"),
	preload("res://scenes/levels/level09.tscn"),
	preload("res://scenes/levels/level10.tscn"),
	preload("res://scenes/levels/level11.tscn"),
	preload("res://scenes/levels/level12.tscn"),
	preload("res://scenes/levels/level13.tscn"),
]


func set_new_level(new_level: int) -> void:
	level = new_level
	level_completed = false
	level_lost = false


func get_level_scene() -> PackedScene:
	return LEVEL_LIST[level]


func is_last_level() -> bool:
	return level == LEVEL_LIST.size()


func _ready() -> void:
	pass
