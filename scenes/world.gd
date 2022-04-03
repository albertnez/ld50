extends Node2D


enum GameState {
	MENU,
	PLAYING,
	GAME_OVER,
}

var _current_level := 0
var _game_state: int
var _toggle_in_menu_used := false
onready var _player := $ScaledView/Player
onready var _tilemap := $ScaledView/TileMap
onready var _trolley := $ScaledView/Trolley
onready var _trolley_timer := $LevelStartTrolleyTimer
onready var _level_completed_timer := $LevelCompletedTimer

func _ready() -> void:
	EventBus.connect("trolley_created", self, "_on_EventBus_trolley_created")
	EventBus.connect("person_crashed", self, "_on_EventBus_person_crashed")
	EventBus.connect("level_restart", self, "_on_EventBus_level_restart")
	EventBus.connect("level_completed", self, "_on_EventBus_level_completed")
	_game_state = GameState.MENU
	_start_level()
	pass


func _start_level() -> void:
	GlobalState.level_completed = false
	_toggle_in_menu_used = false
	if _current_level == 0:
		_game_state = GameState.MENU
	else:
		_game_state = GameState.PLAYING
	var level = str(_current_level).pad_zeros(2)
	var path = str("res://scenes/levels/level", level, ".tscn")
	if _game_state == GameState.MENU:
		path = "res://scenes/levels/menu_level.tscn"
	var tilemap_scene := load(path)
	var new_tilemap = tilemap_scene.instance()
	_tilemap.get_parent().add_child_below_node(_tilemap, new_tilemap)
	_tilemap.queue_free()
	_tilemap = new_tilemap
	
	
	_player.position = _tilemap.get_player_starting_world_position()
	_trolley.set_process(false)
	_trolley.position = Vector2.INF
	if _game_state != GameState.MENU:
		# On Menu, trolley starts upon player action
		_trolley_timer.start(_tilemap.TROLLEY_WAIT_TIME)


func _process(delta: float) -> void:
	
	var player_toggled = false
	match _game_state:
		GameState.PLAYING, GameState.MENU:
			var player_can_toggle = _tilemap.is_world_pos_a_toggable_tile(_player.position)
#			if _game_state == GameState.MENU and _toggle_in_menu_used:
#				player_can_toggle = false
			_player.set_toggle_is_visible(player_can_toggle)
			if Input.is_action_just_pressed("ui_accept") and player_can_toggle:
				_tilemap.toggle_world_pos_cell(_player.position)
				player_toggled = true
			continue
		GameState.MENU:
			if player_toggled and not _toggle_in_menu_used:
				EventBus.emit_signal("trolley_created")
				_toggle_in_menu_used = true
				
		GameState.GAME_OVER:
			if Input.is_action_just_pressed("restart"):
				EventBus.emit_signal("level_restart")
			return


func _on_LevelStartTrolleyTimer_timeout() -> void:
	EventBus.emit_signal("trolley_created")


func _on_EventBus_person_crashed() -> void:
	_game_state = GameState.GAME_OVER


func _on_EventBus_trolley_created() -> void:
	_trolley.reset(_tilemap)


func _on_EventBus_level_restart() -> void:
	_start_level()


func _on_EventBus_level_completed() -> void:
	GlobalState.level_completed = true
	_level_completed_timer.start()
	yield(_level_completed_timer, "timeout")
	_current_level += 1
	_start_level()
