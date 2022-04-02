extends Node2D


onready var _player := $ScaledView/Player
onready var _tilemap := $ScaledView/TileMap
onready var _trolley := $ScaledView/Trolley

func _ready() -> void:
	_trolley.reset(_tilemap)
	pass


func _process(delta: float) -> void:
	var player_can_toggle = _tilemap.is_world_pos_a_toggable_tile(_player.position)
	_player.set_toggle_is_visible(player_can_toggle)
		
	if Input.is_action_just_pressed("ui_accept") and player_can_toggle:
		_tilemap.toggle_world_pos_cell(_player.position)
		pass
