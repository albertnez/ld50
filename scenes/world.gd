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

const trolley_packed_scene := preload("res://scenes/trolley.tscn")

func _ready() -> void:
	EventBus.connect("trolley_created", self, "_on_EventBus_trolley_created")
	EventBus.connect("person_crashed", self, "_on_EventBus_person_crashed")
	EventBus.connect("level_restart", self, "_on_EventBus_level_restart")
	EventBus.connect("level_completed", self, "_on_EventBus_level_completed")
	
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
	if not _tilemap.trolley_waits_for_player():
		# On Menu, trolley starts upon player action
		_trolley_timer.start(_tilemap.TROLLEY_WAIT_TIME)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_tree().set_input_as_handled()
		get_tree().change_scene_to(load("res://scenes/main_menu_handler.tscn"))
		return	


func _process(delta: float) -> void:
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
		EventBus.emit_signal("trolley_created")
		_toggle_triggered_trolley_already = true
	
	if GlobalState.in_true_end:
		return

	if GlobalState.level_completed and Input.is_action_just_pressed("restart"):
		_next_level()
		return
	
	if GlobalState.level_lost and Input.is_action_just_pressed("restart"):
		if GlobalState.level == 0 and GlobalState.level_completed:
			_next_level()
		else:
			EventBus.emit_signal("level_restart")


func _on_LevelStartTrolleyTimer_timeout() -> void:
	EventBus.emit_signal("trolley_created")


func _on_EventBus_trolley_created() -> void:
	for trolley in _trolleys.get_children():
		(trolley as Trolley).reset(_tilemap)


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
