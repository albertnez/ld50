extends Node

var save_file = "user://savedata"
var latest_level_unlocked = 0

var level_selected_in_menu = 0

var level_completed = false
var level_lost = false
var in_main_menu = true
var menu_scene = EventBus.TargetMenuScene.MAIN_MENU
var level = 0
var in_true_end = false

var fast_forward := false
var mute := false

const TROLLEY_COLOR_LIST := [
	Color("ee8695"),  # Palette Red.
	Color.lawngreen,
	Color.aqua,
	Color.burlywood,
	Color.orange,
	Color.white,
	#Color.aquamarine,
	Color.rosybrown,
	Color.purple,
	Color.chartreuse,
]

const MENU_LEVEL := preload("res://scenes/levels/menu/menu_level.tscn")


class Level:
	var packed_scene : PackedScene
	var description : String
	
	func _init(scene: PackedScene, desc: String) -> void:
		packed_scene = scene
		description = desc
	
const LEVEL_LIST := [
	# 0
	preload("res://scenes/levels/tutorial/move_and_toggle.tscn"),
	preload("res://scenes/levels/tutorial/first_loop.tscn"),
	preload("res://scenes/levels/tutorial/bifurcation_direction.tscn"),
	preload("res://scenes/levels/tutorial/no_more_delay.tscn"),
	preload("res://scenes/levels/easy/first_offpiste.tscn"),
	# 5
	preload("res://scenes/levels/easy/wider_loop.tscn"),
	preload("res://scenes/levels/easy/going_across.tscn"),
	preload("res://scenes/levels/easy/first_reverse.tscn"),
	preload("res://scenes/levels/easy/wider_reverse.tscn"),
	preload("res://scenes/levels/medium/expand.tscn"),
	# 10
	preload("res://scenes/levels/medium/reverse_with_detour.tscn"),
	preload("res://scenes/levels/medium/two_train_delay_one.tscn"),
	preload("res://scenes/levels/medium/braid.tscn"),
	preload("res://scenes/levels/hard/density.tscn"),
	preload("res://scenes/levels/hard/through_the_loop.tscn"),
	# 15
	preload("res://scenes/levels/hard/three_trains.tscn"),
	preload("res://scenes/levels/hard/three_train_braid.tscn"),
	preload("res://scenes/levels/hard/find_a_loop.tscn"),
	preload("res://scenes/levels/hard/the_right_size.tscn"),
	preload("res://scenes/levels/ending/the_end.tscn"),
]


const NUM_MAX_TROLLEYS = 9
var _trolley_has_loop : Array


func _save_data():
	var file := File.new()
	var status := file.open(save_file, File.WRITE)
	if status != OK:
		print("Error opening file for write with error: ", status)
		return
	file.store_8(latest_level_unlocked)
	file.close()

func _load_data():
	var file := File.new()
	var status := file.open(save_file, File.READ)
	if status != OK:
		print("Error loading data with error: ", status)
		return
	latest_level_unlocked = file.get_8()


func set_mute(new_mute: bool) -> void:
	mute = new_mute
	var master_sound := AudioServer.get_bus_index("Master")
	AudioServer.set_bus_mute(master_sound, new_mute)


func set_trolley_has_loop(id: int, has_loop: bool) -> void:
	_trolley_has_loop[id] = has_loop


func all_trolleys_have_loop(num_trolleys: int) -> bool:
	for id in num_trolleys:
		if not _trolley_has_loop[id]:
			return false
	return true


func is_playing() -> bool:
	return not (in_main_menu or
				level_completed or
				level_lost)


func set_new_level(new_level: int, new_in_main_menu: bool) -> void:
	in_main_menu = new_in_main_menu
	level = new_level
	level_completed = false
	level_lost = false
	fast_forward = false
	for id in NUM_MAX_TROLLEYS:
		_trolley_has_loop[id] = false


# Needed because otherwise game is only saved once moved to the new level.
func set_level_completed() -> void:
	level_completed = true
	if level+1 > latest_level_unlocked and not is_last_level():
		latest_level_unlocked = level+1
		_save_data()


func get_level_scene() -> PackedScene:
	if in_main_menu:
		return MENU_LEVEL
	return LEVEL_LIST[level]


func get_level_name(level_idx: int) -> String:
	# We asume the scene file name will be our description.
	var scene_path : String = LEVEL_LIST[level_idx].resource_path
	return scene_path.get_file().trim_suffix(".tscn").replace("_", " ")


func is_last_level() -> bool:
	return level == LEVEL_LIST.size()-1


func jumping_from_game_to_menu(target_menu_scene: int):
	in_main_menu = true
	menu_scene = target_menu_scene


func _init() -> void:
	_load_data()

func _ready() -> void:
	_trolley_has_loop.resize(NUM_MAX_TROLLEYS)
