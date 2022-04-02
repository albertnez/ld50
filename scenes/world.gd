extends Node2D


enum GameState {
	MENU,
	PLAYING,
	GAME_OVER,
}

var _current_level := 0
var _game_state: int
onready var _player := $ScaledView/Player
onready var _tilemap := $ScaledView/TileMap
onready var _trolley := $ScaledView/Trolley

func _ready() -> void:
	_game_state = GameState.MENU
	_start_level()
	pass


func _start_level() -> void:
	var level = str(_current_level).pad_zeros(2)
	var path = str("res://scenes/levels/level", level, ".tscn")
	if _game_state == GameState.MENU:
		path = "res://scenes/levels/menu_level.tscn"
	var tilemap_scene := load(path)
	var new_tilemap = tilemap_scene.instance()
	_tilemap.replace_by(new_tilemap)
	_tilemap.queue_free()
	_tilemap = new_tilemap
	
	_player.position = _tilemap.get_player_starting_world_position()
	_trolley.reset(_tilemap)


func _process(delta: float) -> void:
	
	match _game_state:
		GameState.MENU:
			continue
		GameState.PLAYING:
			var player_can_toggle = _tilemap.is_world_pos_a_toggable_tile(_player.position)
			_player.set_toggle_is_visible(player_can_toggle)
			if Input.is_action_just_pressed("ui_accept") and player_can_toggle:
				_tilemap.toggle_world_pos_cell(_player.position)
		GameState.GAME_OVER:
			if Input.is_action_just_pressed("ui_accept"):
				EventBus.emit_signal("level_restart")
			return
	
