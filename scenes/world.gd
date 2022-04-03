extends Node2D

export (int, 0, 10) var _current_level := 0

var _toggle_triggered_trolley_already := false
onready var _player := $ScaledView/Player
onready var _tilemap := $ScaledView/TileMap
onready var _trolley := $ScaledView/Trolley
onready var _trolley_timer := $LevelStartTrolleyTimer
onready var _level_completed_timer := $LevelCompletedTimer

func _ready() -> void:
	GlobalState.in_menu = _current_level == 0
	EventBus.connect("trolley_created", self, "_on_EventBus_trolley_created")
	EventBus.connect("person_crashed", self, "_on_EventBus_person_crashed")
	EventBus.connect("level_restart", self, "_on_EventBus_level_restart")
	EventBus.connect("level_completed", self, "_on_EventBus_level_completed")
	
	EventBus.emit_signal("level_restart")
	pass


func _trolley_waits_for_player() -> bool:
	return GlobalState.level < 3


func _start_level() -> void:
	GlobalState.level = _current_level
	GlobalState.level_completed = false
	GlobalState.level_lost = false
	_toggle_triggered_trolley_already = false

	var level = str(_current_level).pad_zeros(2)
	var path = str("res://scenes/levels/level", level, ".tscn")
	var tilemap_scene := load(path)
	var new_tilemap = tilemap_scene.instance()
	_tilemap.get_parent().add_child_below_node(_tilemap, new_tilemap)
	_tilemap.queue_free()
	_tilemap = new_tilemap
	
	
	_player.position = _tilemap.get_player_starting_world_position()
	_trolley.set_process(false)
	_trolley.position = Vector2.INF
	if not _trolley_waits_for_player():
		# On Menu, trolley starts upon player action
		_trolley_timer.start(_tilemap.TROLLEY_WAIT_TIME)



func _process(delta: float) -> void:
	
	var player_toggled = false
	
	var player_can_toggle = (_tilemap.is_world_pos_a_toggable_tile(_player.position)
			and not _player.is_dead()
			and not GlobalState.level_completed
			and not GlobalState.level_lost)

	_player.set_toggle_is_visible(player_can_toggle)
	if Input.is_action_just_pressed("ui_accept") and player_can_toggle:
		_tilemap.toggle_world_pos_cell(_player.position)
		EventBus.emit_signal("toggle")
		player_toggled = true

	if _trolley_waits_for_player():
		if player_toggled and not _toggle_triggered_trolley_already:
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
	_trolley.reset(_tilemap)


func _on_EventBus_level_restart() -> void:
	_start_level()


func _on_EventBus_level_completed() -> void:
	GlobalState.level_completed = true
#	_level_completed_timer.start()
#	yield(_level_completed_timer, "timeout")
#	_next_level()


func _next_level():
	_current_level += 1
	GlobalState.in_menu = false
	EventBus.emit_signal("level_restart")
