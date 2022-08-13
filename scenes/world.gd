extends Node2D
class_name GameWorld

export (int, 0, 15) var _current_level := 0
export (bool) var _menu_demo_mode := false

var _toggle_triggered_trolley_already := false
onready var _player := $ScaledView/Player
onready var _tilemap : MyTileMap = $ScaledView/TileMap
onready var _trolleys := $ScaledView/Trolleys
onready var _trolley_timer := $LevelStartTrolleyTimer
onready var _level_completed_timer := $LevelCompletedTimer

onready var _pause_menu := $"%Pause"

const trolley_packed_scene := preload("res://scenes/trolley.tscn")

func _ready() -> void:
	var _s = null
	_s = EventBus.connect("trolley_created_later", _trolley_timer, "start", [1.0])
	_s = EventBus.connect("level_restart", self, "_on_EventBus_level_restart")
	_s = EventBus.connect("level_completed", self, "_on_EventBus_level_completed")
	
	_s = EventBus.connect("resume_game", self, "_toggle_pause", [false])
	_s = EventBus.connect("level_restart", self, "_toggle_pause", [false])
	_s = EventBus.connect("go_to_next_level", self, "_next_level")
	if not GlobalState.in_main_menu:
		_s = EventBus.connect("change_menu_scene", self, "_goto_main_menu")
	
	_current_level = GlobalState.level_selected_in_menu
	
	EventBus.emit_signal("level_restart")


func _start_level() -> void:
	_toggle_triggered_trolley_already = false
	GlobalState.set_new_level(_current_level, _menu_demo_mode)
	var tilemap_scene := GlobalState.get_level_scene()
	var new_tilemap = tilemap_scene.instance()
	_tilemap.get_parent().add_child_below_node(_tilemap, new_tilemap)
	_tilemap.queue_free()
	_tilemap = new_tilemap

	# TODO: It still gets out.
	_player.set_moving_bounds(_tilemap.get_level_bounds())
	_player.position = _tilemap.get_player_starting_world_position()
	
	for trolley in _trolleys.get_children():
		trolley.queue_free()
		_trolleys.remove_child(trolley)

	for id in _tilemap.get_num_trolleys():
		var trolley = trolley_packed_scene.instance()
		trolley._id = id
		trolley.position = Vector2.INF
		_trolleys.add_child(trolley)
		trolley.set_process(false)
	_tilemap.set_trolleys_for_vfx(_trolleys.get_children())
	if not _tilemap.trolley_waits_for_player() and not GlobalState.in_main_menu:
		# On Menu, trolley starts upon player action
		_trolley_timer.start(_tilemap.TROLLEY_WAIT_TIME)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_tree().set_input_as_handled()
		# TODO: Don't do this on the GameCmpleteMenu
		_toggle_pause(true)


func _toggle_pause(paused: bool) -> void:
	get_tree().paused = paused
	_pause_menu.visible = paused


func _goto_main_menu(target_scene: int, _unused_target_level: int) -> void:
	GlobalState.jumping_from_game_to_menu(target_scene)
	if get_tree().change_scene_to(load("res://scenes/main_menu_handler.tscn")) != OK:
		print("Error going from game to menu")
	return		


func _process(_delta: float) -> void:
	var player_toggled = false
	
	var player_can_toggle = (
			_tilemap.is_world_pos_a_toggable_tile(_player.position)
			and not _player.is_dead()
			and not GlobalState.level_completed
			and not GlobalState.level_lost)

	_player.set_toggle_is_visible(player_can_toggle)
	_tilemap.set_action_hover_visible(_player.position, player_can_toggle)
	if Input.is_action_just_pressed("ui_accept") and player_can_toggle:
		_tilemap.toggle_world_pos_cell(_player.position)
		EventBus.emit_signal("toggle")
		player_toggled = true

	var create_trolley = (
		_tilemap.trolley_waits_for_player() and
		player_toggled and 
		not _toggle_triggered_trolley_already)
	if create_trolley:
		EventBus.emit_signal("trolley_created_later")
		_toggle_triggered_trolley_already = true
	
	if GlobalState.in_true_end:
		return

	# TODO: Move these to a menu	
	if GlobalState.level_lost and Input.is_action_just_pressed("restart"):
		if GlobalState.level == 0 and GlobalState.level_completed:
			_next_level()
		else:
			EventBus.emit_signal("level_restart")


func _on_EventBus_level_restart() -> void:
	_start_level()


func _on_EventBus_level_completed() -> void:
	GlobalState.level_completed = true
	# Stop tracking the trolley for VFX
	_tilemap.stop_tracking_trolleys_for_vfx()
	
#	_level_completed_timer.start()
#	yield(_level_completed_timer, "timeout")
#	_next_level()


func _next_level():
	_current_level += 1
	EventBus.emit_signal("level_restart")


func _on_Any_trolley_created_later() -> void:
	for trolley in _trolleys.get_children():
		(trolley as Trolley).reset(_tilemap)
