extends Area2D
class_name Trolley

export (float, 10, 100, 5) var SPEED = 32
export (float, 0.1, 5.0, 0.1) var SECONDS_PER_CELL = 1.0

onready var _original_seconds_per_cell = SECONDS_PER_CELL
onready var _slowdown_timer := $SlowDownTimer

var _tilemap: MyTileMap = null

var _time_in_cell := 0.0
var _from_position := Vector2.ZERO
var _to_position := Vector2.ZERO
var _is_turning: bool = false
var _is_resetted: bool = false
var _is_crashed


func update_trolley_speed(new_seconds_per_cell: float) -> void:
	var ratio = new_seconds_per_cell / SECONDS_PER_CELL	
	_time_in_cell *= ratio
	SECONDS_PER_CELL = new_seconds_per_cell
	if SECONDS_PER_CELL > 1000:
		_slowdown_timer.stop()


func reset(tilemap: MyTileMap) -> void:
	SECONDS_PER_CELL = _original_seconds_per_cell
	_slowdown_timer.stop()
	_time_in_cell = 0.0
	_tilemap = tilemap
	position = _tilemap.get_trolley_starting_world_position()
	var initial_positions = _tilemap.get_tile_world_endpoints(position)
	_from_position = initial_positions[0]
	_to_position = initial_positions[1]
	position = _from_position
	_is_resetted = true
	_is_crashed = false
	set_process(true)


func _ready() -> void:
	EventBus.connect("trolley_crashed", self, "_handle_trolley_crash")
	EventBus.connect("trolley_killed_someone", self, "_handle_trolley_crash")
	EventBus.connect("person_crashed", self, "_handle_trolley_crash")
	pass


func _process(delta: float) -> void:
	assert(_is_resetted)
	if SECONDS_PER_CELL < 1000:
		_time_in_cell += delta
	if not GlobalState.level_lost and _time_in_cell > SECONDS_PER_CELL:
		var old_time_in_cell = _time_in_cell
		_time_in_cell -= SECONDS_PER_CELL
		# OK for curves to consider them as diagonals
		var direction = _to_position - _from_position
		var pos_in_new_tile = _to_position + direction*0.1
		var pos_in_old_tile = _to_position - direction*0.1
		var from_pos_in_old_tile = _from_position - direction*0.1
		if _tilemap.is_out_of_bounds(pos_in_new_tile):
			# Went out in the emptyness
			EventBus.emit_signal("trolley_crashed")
			return
		_tilemap.mark_world_pos_cell_as_visited(pos_in_old_tile, from_pos_in_old_tile)
		var next_tile_positions = _tilemap.get_tile_world_endpoints(pos_in_new_tile, _to_position)
		if not _to_position in next_tile_positions:
			# Took rail the wrong way
			# Undo the time subtraction from earlier:
			_time_in_cell = old_time_in_cell
			EventBus.emit_signal("trolley_crashed")
			return
		_from_position = _to_position
		_to_position = next_tile_positions[0]
		if _to_position == _from_position:
			_to_position = next_tile_positions[1]

	# TODO: Implement turning
	if not _is_turning or _is_turning:
		position = lerp(_from_position, _to_position, _time_in_cell/SECONDS_PER_CELL)
	



func _on_Trolley_body_entered(body: Node) -> void:
	if body is TileMap and not GlobalState.level_lost:
		EventBus.emit_signal("trolley_killed_someone")
	pass # Replace with function body.


func _handle_trolley_crash() -> void:
	GlobalState.level_lost = true
	_is_crashed = true
	_slowdown_timer.start()
	_on_SlowDownTimer_timeout()



func _on_SlowDownTimer_timeout() -> void:
	update_trolley_speed(SECONDS_PER_CELL * 2.0)
	pass # Replace with function body.
