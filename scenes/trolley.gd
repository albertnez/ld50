extends Area2D
class_name Trolley

export (float, 10.0, 100.0, 5.0) var SPEED = 32.0
export (float, 0.1, 5.0, 0.1) var SECONDS_PER_CELL = 1.0
export (float, 1.0, 3.0, 0.1) var FAST_SPEED_MODIFIER = 1.8

const CRASH_ROTATION := TAU/16.0

onready var _original_seconds_per_cell = SECONDS_PER_CELL
onready var _slowdown_timer := $SlowDownTimer
onready var _rotation_tween := $RotationTween

var _tilemap: MyTileMap = null
# There are N trolleys with ids [0, N-1], assigned by World.
var _id = 0

var _time_in_cell := 0.0

var _from_position := Vector2.ZERO
var _to_position := Vector2.ZERO
"""
Normalized direction from where the Train comes from, relative to the current tile.
If the Train is moving to the right, `_from_dir` will equal to Vector2.LEFT
If the Train is taking a curve, from left to down:
	* In the curve tile, _from_dir will be Vector2.LEFT
	* In the next tile,  _from_dir will be Vector2.UP
"""
var _from_dir := Vector2.INF

var _is_turning: bool = false
var _is_resetted: bool = false
var _is_crashed: bool = false
var _reached_tile_midpoint: bool = false


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
	var initial_setup := _tilemap.get_trolley_starting_world_position(_id)
	position = initial_setup.world_pos
	var initial_dir = initial_setup.dir
	var prev_world_pos = position - initial_dir*MyTileMap.CELL_SIZE
	_to_position = _tilemap.get_next_world_pos(position, prev_world_pos)
	_from_position = _to_position - initial_dir*MyTileMap.CELL_SIZE
	_from_dir = tilemap.get_from_dir(_to_position, _from_position)
	position = _from_position

	_rotation_tween.stop_all()
	rotation = 0.0
	
	_is_resetted = true
	_is_crashed = false
	set_process(true)


func _ready() -> void:
	var _s = null
	_s = EventBus.connect("trolley_crashed", self, "_handle_trolley_crash", [TrolleyMoveStrategy.STRAIGHT_LINE])
	_s = EventBus.connect("trolley_killed_someone", self, "_handle_trolley_crash", [TrolleyMoveStrategy.FOLLOW_TRACK])
	_s = EventBus.connect("trolley_crash_with_trolley", self, "_handle_trolley_crash", [TrolleyMoveStrategy.FOLLOW_TRACK])
	_s = EventBus.connect("person_crashed", self, "_handle_trolley_crash", [TrolleyMoveStrategy.FOLLOW_TRACK])

	add_to_group("Trolley")
	pass


func _process(delta: float) -> void:
	assert(_is_resetted)
	if SECONDS_PER_CELL < 1000:
		var dt := delta
		if GlobalState.fast_forward:
			dt *= FAST_SPEED_MODIFIER
		_time_in_cell += dt
	if not GlobalState.level_lost:
		if _time_in_cell > SECONDS_PER_CELL:
			# We move to the next cell.
			var old_time_in_cell = _time_in_cell
			_time_in_cell -= SECONDS_PER_CELL
			# OK for curves to consider them as diagonals
			var direction = _to_position - _from_position
			var pos_in_new_tile = _to_position + direction*0.1
			var pos_in_old_tile = _to_position - direction*0.1
			_from_dir = _tilemap.get_from_dir_with_world_positions(pos_in_new_tile, pos_in_old_tile)
			var from_pos_in_old_tile = _from_position - direction*0.1
			if _tilemap.is_out_of_bounds(pos_in_new_tile):
				# Went out in the emptyness
				_time_in_cell = old_time_in_cell
				EventBus.emit_signal("trolley_crashed")
				return
			_tilemap.mark_world_pos_cell_as_visited(pos_in_old_tile, from_pos_in_old_tile, _id)
			var next_position = _tilemap.get_next_world_pos(pos_in_new_tile, pos_in_old_tile)
			if next_position == Vector2.INF:
				# Took rail the wrong way
				# Undo the time subtraction from earlier:
				_time_in_cell = old_time_in_cell
				EventBus.emit_signal("trolley_crashed")
				return
			_from_position = _to_position
			_to_position = next_position
			var diff := _to_position - _from_position
			_is_turning = diff.x != 0 and diff.y != 0
			_reached_tile_midpoint = false
			if not GlobalState.level_completed:
				_tilemap.add_trolley_line_decorative_point(_from_position, _id)
		elif _time_in_cell*2 > SECONDS_PER_CELL and not _reached_tile_midpoint:
			_reached_tile_midpoint = true
			if not GlobalState.level_completed:
				_tilemap.add_trolley_line_midpoint(position, _id)


	var time_step : float = _time_in_cell / SECONDS_PER_CELL
	if not _is_turning:
		position = lerp(_from_position, _to_position, time_step)
	else:
		# To slowly turn:
		# - The axis in which we were already moving, slows down (ease_in lerp)
		# - The other axis slowly increases (ease_out lerp)
		var ease_in := sin(time_step * PI/2.0)
		var ease_out := 1.0 - cos(time_step * PI/2.0)
		var horizontal_dir = _from_dir in [Vector2.LEFT, Vector2.RIGHT]
		var x_step = ease_in if horizontal_dir else ease_out
		var y_step = ease_out if horizontal_dir else ease_in
		
		position.x = lerp(_from_position.x, _to_position.x, x_step)
		position.y = lerp(_from_position.y, _to_position.y, y_step)


func _on_Trolley_body_entered(body: Node) -> void:
	if GlobalState.level_lost:
		return
	if body is TileMap:
		if GlobalState.level == 0:
			GlobalState.set_level_completed()
		if GlobalState.is_last_level():
			GlobalState.in_true_end = true
		EventBus.emit_signal("trolley_killed_someone")


func _on_Trolley_area_entered(area: Area2D) -> void:
	if GlobalState.level_lost:
		return
	# Trolley as a group, because using 'Trolley' class check causes dependency cycle in godot3
	# Also check indices, to avoid triggering twice unnecessarily.
	if area.is_in_group("Trolley") and area.get_index() < get_index():
		EventBus.emit_signal("trolley_crash_with_trolley")


enum TrolleyMoveStrategy {
	FOLLOW_TRACK,
	STRAIGHT_LINE,
	RANDOM_DIR,
}
	
func _handle_trolley_crash(trolley_move_strategy: int) -> void:
	assert(TrolleyMoveStrategy.values().has(trolley_move_strategy))
	GlobalState.level_lost = true
	_is_crashed = true
	_slowdown_timer.start()
	_on_SlowDownTimer_timeout()
	var target_rotation := CRASH_ROTATION if (randi()%2) else -CRASH_ROTATION
	_rotation_tween.interpolate_property(self, "rotation", 0, target_rotation, 0.5, Tween.TRANS_QUAD, Tween.EASE_OUT)
	_rotation_tween.start()
	if trolley_move_strategy == TrolleyMoveStrategy.STRAIGHT_LINE and _is_turning:
		_is_turning = false
		_from_position = _to_position + _from_dir*MyTileMap.CELL_SIZE


func _on_SlowDownTimer_timeout() -> void:
	update_trolley_speed(SECONDS_PER_CELL * 2.0)
