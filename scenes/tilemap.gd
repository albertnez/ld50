extends TileMap
class_name MyTileMap

export (float, 1.0, 10.0, 1.0) var TROLLEY_WAIT_TIME = 2.0

onready var _indicator_tilemap := $IndicatorTilemap
onready var _tile_wobbler_timer := $TileWobblerTimer
onready var _current_main_tileset_id := 1

var _trolley_world_position := Vector2.INF
var _player_starting_world_pos := Vector2.INF
var _visited_cells = {}

class VisitedCell:
	var _coord: Vector2
	var _x_flipped: bool
	var _y_flipped: bool
	var _transposed: bool
	var _from_dir: Vector2  # Which direction train came from, relative to cell
	
	func _init(coord: Vector2, x_flipped: bool, y_flipped: bool, transposed: bool, from_dir: Vector2):
		_coord = coord
		_x_flipped = x_flipped
		_y_flipped = y_flipped
		_transposed = transposed
		_from_dir = from_dir
	
	func hash():
		return hash([_coord, _x_flipped, _y_flipped, _transposed, _from_dir])


const CELL_SIZE = 32
const HALF_CELL = CELL_SIZE * 0.5

const PLAYER_START_COORD = Vector2(0, 2)
const TROLLEY_START_COORD = Vector2(0, 3)
const MAIN_INDICATOR_TILEMAP_ID = 0
const INDICATOR_TILEMAP_GREEN_COORD = Vector2(0, 0)

const TILEMAP_ENDPOINT_DIRS = {
	Vector2(0, 0):  # Straight horizontal
		[Vector2.LEFT, Vector2.RIGHT],
	Vector2(1, 0):  # Straight horizontal, can toggle left-down
		[Vector2.LEFT, Vector2.RIGHT],
	Vector2(2, 0):  # Left-Down, can toggle Left-Right
		[Vector2.LEFT, Vector2.DOWN],
	Vector2(3, 0):  # Left-Down
		[Vector2.LEFT, Vector2.DOWN],
	Vector2(0, 1):  # Victim
		[Vector2.LEFT, Vector2.RIGHT],
	Vector2(1, 1):  # Left-Right,Left-Down. Special case, has 2 parts
		[
			[Vector2.LEFT, Vector2.RIGHT],
			[Vector2.LEFT, Vector2.DOWN],
		],
	Vector2(2, 1):  # Trifurcation
		[
			[Vector2.LEFT, Vector2.RIGHT],
			[Vector2.LEFT, Vector2.UP],
			[Vector2.LEFT, Vector2.DOWN],
		],
}


func coord_is_bifurcation(coord: Vector2) -> bool:
	return coord in [Vector2(1, 1), Vector2(2, 1)]


const TILEMAP_FLIP_COORD = {
	Vector2(1, 0): Vector2(2, 0),
	Vector2(2, 0): Vector2(1, 0),
}


func get_from_dir_with_world_positions(world_pos: Vector2, world_prev_pos: Vector2) -> Vector2:
	var pos := world_to_map(world_pos)
	var prev_pos := world_to_map(world_prev_pos)
	return get_from_dir(pos, prev_pos)


func get_from_dir(pos: Vector2, from_pos: Vector2) -> Vector2:
	var from_dir = (from_pos - pos).normalized()  # TODO: See that this is unary
	assert(from_dir in [Vector2.UP, Vector2.LEFT, Vector2.DOWN, Vector2.RIGHT])
	return from_dir


func _has_visited_loop(pos: Vector2, from_dir: Vector2) -> bool:
	var starting_pos = pos  # Already evaluated as visited
	var old_pos = pos
	pos = get_tile_next_pos(pos, from_dir)
	assert(pos != Vector2.INF)
	from_dir = get_from_dir(pos, old_pos)
	while pos != starting_pos:
		if not is_cell_already_visited(pos, from_dir):
			return false
		old_pos = pos
		pos = get_tile_next_pos(pos, from_dir)
		if pos == Vector2.INF:
			return false
		from_dir = get_from_dir(pos, old_pos)
	return true
	

func _visited_cell_from_pos(pos: Vector2, from_dir: Vector2) -> VisitedCell:
	var coord = get_cell_autotile_coord(pos.x, pos.y)
	var x_flipped = is_cell_x_flipped(pos.x, pos.y)
	var y_flipped = is_cell_y_flipped(pos.x, pos.y)
	var transposed = is_cell_transposed(pos.x, pos.y)
	return VisitedCell.new(coord, x_flipped, y_flipped, transposed, from_dir)


func is_cell_already_visited(pos: Vector2, from_dir: Vector2):
	return _visited_cells.has(pos) and _visited_cells[pos].hash() == _visited_cell_from_pos(pos, from_dir).hash()


# We asume this is only called by trolley
func mark_cell_as_visited(pos: Vector2, from_dir: Vector2, clear: bool = false) -> void:
	if clear:
		_visited_cells.erase(pos)
		_indicator_tilemap.set_cell(pos.x, pos.y, -1)
		return
	
	if not GlobalState.level_lost and not GlobalState.level_completed and is_cell_already_visited(pos, from_dir):

		if _has_visited_loop(pos, from_dir):
			EventBus.emit_signal("level_completed")
			return
		pass
		

	_visited_cells[pos] = _visited_cell_from_pos(pos, from_dir)
	_indicator_tilemap.set_cell(pos.x, pos.y, MAIN_INDICATOR_TILEMAP_ID, false, false, false, INDICATOR_TILEMAP_GREEN_COORD)


func mark_world_pos_cell_as_visited(world_pos: Vector2, from_world_pos: Vector2) -> void:
	var pos = world_to_map(world_pos)
	var from_pos = world_to_map(from_world_pos)
	var from_dir = get_from_dir(pos, from_pos)
	mark_cell_as_visited(pos, from_dir)


func get_trolley_starting_world_position() -> Vector2:
	assert(_trolley_world_position != Vector2.INF)
	return _trolley_world_position


func get_player_starting_world_position() -> Vector2:
	assert(_player_starting_world_pos != Vector2.INF)
	return _player_starting_world_pos


func toggle_world_pos_cell(world_pos: Vector2) -> void:
	var pos = world_to_map(world_pos)
	var ind = get_cell(pos.x, pos.y)
	var coord = get_cell_autotile_coord(pos.x, pos.y)
	assert(is_autotile_coord_toggable(coord))
	var x_flipped = is_cell_x_flipped(pos.x, pos.y)
	var y_flipped = is_cell_y_flipped(pos.x, pos.y)
	var transposed = is_cell_transposed(pos.x, pos.y)
	set_cell(pos.x, pos.y, ind, x_flipped, y_flipped, transposed, TILEMAP_FLIP_COORD[coord])
	var clear_visited = true
	mark_cell_as_visited(pos, Vector2.INF, clear_visited)


func is_out_of_bounds(world_pos: Vector2) -> bool:
	var pos := world_to_map(world_pos)
	return get_cell(pos.x, pos.y) == -1


# Returns the next place to go, or INF if bogus
func get_tile_next_pos(pos: Vector2, from_dir: Vector2) -> Vector2:
	var tileset_ind = get_cell(pos.x, pos.y)
	var coord := get_cell_autotile_coord(pos.x, pos.y)
	var options = []  # List of Array Pairs of directions that you can come from.
	if coord_is_bifurcation(coord):
		options.append_array(TILEMAP_ENDPOINT_DIRS[coord].duplicate(true))
	else:
		options.append(TILEMAP_ENDPOINT_DIRS[coord].duplicate(true))
	
	var valid_options = []
	for option_pair in options:
		_apply_dirs_transpose_rotation(option_pair, pos)
		
		if from_dir == option_pair[0]:
			valid_options.append(option_pair[1])
		if from_dir == option_pair[1]:
			valid_options.append(option_pair[0])

	if valid_options.size() != 1:
		return Vector2.INF
	return pos + valid_options[0]


func _apply_dirs_transpose_rotation(dirs: Array, cell_pos: Vector2) -> void:
	for i in dirs.size():
		if is_cell_transposed(cell_pos.x, cell_pos.y):
			dirs[i] = Vector2(dirs[i].y, dirs[i].x)
		if is_cell_x_flipped(cell_pos.x, cell_pos.y):
			dirs[i].x *= -1
		if is_cell_y_flipped(cell_pos.x, cell_pos.y):
			dirs[i].y *= -1	


# Returns either the only value of `pair` that is different than `elem`, or null otherwise.
func _get_elem_not_in_pair_or_inf(pair: Array, elem: Vector2) -> Vector2:
	assert(pair.size() == 2)
	assert(elem != pair[0] or elem != pair[1], "At least one elem should be different than pair")
	if not elem in pair:
		return Vector2.INF
	return pair[0] if elem != pair[0] else pair[1]


func _target_dir_to_world_pos(tile_pos: Vector2, target_dir: Vector2):
	if target_dir == Vector2.INF:
		return Vector2.INF

	return (tile_pos * CELL_SIZE 
		+ Vector2.ONE * HALF_CELL  # Centered in the tile
		+ target_dir * HALF_CELL)
	
	
# Returns the next world_pos for the current `tile_world_pos`.
# Inf impossible, returns Vector2.INF
func get_next_world_pos(tile_world_pos: Vector2, prev_tile_world_pos: Vector2 = Vector2.INF) -> Vector2:
	var pos := world_to_map(tile_world_pos)
	var prev_pos := world_to_map(prev_tile_world_pos)
	var coord := get_cell_autotile_coord(pos.x, pos.y)
	var points = TILEMAP_ENDPOINT_DIRS[coord].duplicate(true)
	var from_dir = get_from_dir(pos, prev_pos)
	
	if not coord_is_bifurcation(coord):
		_apply_dirs_transpose_rotation(points, pos)
		return _target_dir_to_world_pos(pos, _get_elem_not_in_pair_or_inf(points, from_dir))
		
	# From the the various dir_pairs, use the one that connects where we come from (`from_dir`).
	# If there's more than one `dir_pairs` that connect, then we're splitting, and it's invalid.
	var result := Vector2.INF
	for dirs_pair in points:
		_apply_dirs_transpose_rotation(dirs_pair, pos)
		var dest := _get_elem_not_in_pair_or_inf(dirs_pair, from_dir)
		if dest != Vector2.INF:
			if result != Vector2.INF: 
				 # Two possible ways; we return INF
				return Vector2.INF
			result = dest
	return _target_dir_to_world_pos(pos, result)


func is_autotile_coord_toggable(ind: Vector2) -> bool:
	return ind in [Vector2(1, 0), Vector2(2, 0)]


func is_world_pos_a_toggable_tile(world_pos: Vector2) -> bool:
	var pos := world_to_map(world_pos)
	var coord := get_cell_autotile_coord(pos.x, pos.y)
	return is_autotile_coord_toggable(coord)


func _ready() -> void:
	for pos in get_used_cells_by_id(_current_main_tileset_id):
		var coord := get_cell_autotile_coord(pos.x, pos.y)
		if coord == PLAYER_START_COORD:
			assert(_player_starting_world_pos == Vector2.INF)
			_player_starting_world_pos = pos * CELL_SIZE + Vector2.ONE*HALF_CELL
			set_cell(pos.x, pos.y, -1)
		elif coord == TROLLEY_START_COORD:
			assert(_trolley_world_position == Vector2.INF)
			_trolley_world_position = pos * CELL_SIZE + Vector2.ONE*HALF_CELL
			set_cell(pos.x, pos.y, _current_main_tileset_id)

	pass


func _on_TileWobblerTimer_timeout() -> void:
	var next_id = [null, 2, 1][_current_main_tileset_id]
	for tm in [self, _indicator_tilemap]:
		# Since ids are not easy to change, and the Main tileset has ids 1,2
		# while the _indicator has 0,1.
		var id = _current_main_tileset_id
		var new_id = next_id
		if tm == _indicator_tilemap:
			id -= 1
			new_id -= 1
		for pos in tm.get_used_cells_by_id(id):
			tm.set_cell(
				pos.x,
				pos.y,
				new_id,
				tm.is_cell_x_flipped(pos.x, pos.y),
				tm.is_cell_y_flipped(pos.x, pos.y),
				tm.is_cell_transposed(pos.x, pos.y),
				tm.get_cell_autotile_coord(pos.x, pos.y))

	_current_main_tileset_id = next_id

