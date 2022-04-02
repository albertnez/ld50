extends Sprite
class_name Trolley

export (float, 10, 100, 5) var SPEED = 32
export (float, 0.5, 5.0, 0.5) var SECONDS_PER_CELL = 1.0

var _tilemap: MyTileMap = null

var _time_in_cell := 0.0
var _from_position := Vector2.ZERO
var _to_position := Vector2.ZERO
var _is_turning: bool = false
var _is_resetted: bool = false
var _is_crashed


func reset(tilemap: MyTileMap) -> void:
	_tilemap = tilemap
	position = _tilemap.get_trolley_starting_world_position()
	var initial_positions = _tilemap.get_tile_world_endpoints(position)
	_from_position = initial_positions[0]
	_to_position = initial_positions[1]
	position = _from_position
	_is_resetted = true
	_is_crashed = false


func _ready() -> void:
	pass


func _process(delta: float) -> void:
	assert(_is_resetted)
	if _is_crashed:
		return
	_time_in_cell += delta
	if _time_in_cell > SECONDS_PER_CELL:
		_time_in_cell -= SECONDS_PER_CELL
		# OK for curves to consider them as diagonals
		var direction = _to_position - _from_position
		var pos_in_new_tile = _to_position + direction*0.1
		if _tilemap.is_out_of_bounds(pos_in_new_tile):
			EventBus.emit_signal("trolley_crashed")
			_is_crashed = true
			return
		var next_tile_positions = _tilemap.get_tile_world_endpoints(pos_in_new_tile)
		_from_position = _to_position
		_to_position = next_tile_positions[0]
		if _to_position == _from_position:
			_to_position = next_tile_positions[1]

	# TODO: Implement turning
	if not _is_turning or _is_turning:
		position = lerp(_from_position, _to_position, _time_in_cell)
	

