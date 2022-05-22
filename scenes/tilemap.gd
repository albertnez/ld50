extends TileMap
class_name MyTileMap

const LINE_DRAWER_SCENE := preload("res://scenes/vfx/LineDrawer.tscn")
const TROLLEY_WARNING_SPRITE_SCENE := preload("res://scenes/vfx/TrolleyWarningSprite.tscn")
export (float, 1.0, 10.0, 1.0) var TROLLEY_WAIT_TIME = 2.0

onready var _indicator_tilemap : TileMap = $IndicatorTilemap
onready var _tile_wobbler_timer := $TileWobblerTimer
onready var _action_hover_indicator := $ActionHoverIndicator
onready var _trolley_warning_sprites := $TrolleyWarningSprites
onready var _trolley_warning_timer := $TrolleyWarningTimer
onready var _level_tile_hint_sprite := $LevelTileHintSprite

onready var _line_drawers := $LineDrawers
# onready var _line_drawer := $LineDrawer

onready var _camera = $Camera2D
onready var _current_main_tileset_id := 1

var _trolley_world_positions := []

var _player_starting_world_pos := Vector2.INF
var _level_tile_hint_pos := Vector2.INF
var _warning_shown := false
var _visited_cells = {}


func make_visited_cell_key(pos: Vector2, trolley_id: int) -> int:
	return hash([pos, trolley_id])


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
func _pos_to_tile_center_world(pos: Vector2) -> Vector2:
	return pos*CELL_SIZE + Vector2.ONE*HALF_CELL


const PLAYER_START_COORD = Vector2(0, 2)
const TROLLEY_START_COORD = Vector2(0, 3)
const TROLLEY_WARNING_COORD = Vector2(1, 3)
const MAIN_INDICATOR_TILEMAP_ID = 0
const INDICATOR_TILEMAP_GREEN_COORD = Vector2(0, 0)
const INDICATOR_TILEMAP_HINT_COORD = Vector2(1, 0)

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
	Vector2(1, 2):  # Toggleable corners bifurcation
		[Vector2.LEFT, Vector2.UP],
	Vector2(2, 2):  # Toggleable corners bifurcation
		[Vector2.LEFT, Vector2.DOWN],
}


func stop_tracking_trolleys_for_vfx() -> void:
	for line_drawer in _line_drawers.get_children():
		(line_drawer as LineDrawer).set_tip_point(null)


func set_trolleys_for_vfx(trolleys : Array) -> void:
	for child in _line_drawers.get_children():
		_line_drawers.remove_child(child)
	for i in trolleys.size():
		# Node2D instead of Trolley to avoid cyclic dependency.
		var trolley : Node2D = trolleys[i]
		assert(i == trolleys[i]._id)
		var line_drawer : LineDrawer = LINE_DRAWER_SCENE.instance()
		line_drawer.set_tip_point(trolley)
		line_drawer.LINE_COLOR = line_drawer.COLOR_ARRAY[i]
		_line_drawers.add_child(line_drawer)


func coord_is_bifurcation(coord: Vector2) -> bool:
	return coord in [Vector2(1, 1), Vector2(2, 1)]


# Note: For a toggleable tile with 3 states, can be encoded here with a 3-length cycle.
const TILEMAP_FLIP_COORD = {
	Vector2(1, 0): Vector2(2, 0),
	Vector2(2, 0): Vector2(1, 0),
	Vector2(1, 2): Vector2(2, 2),
	Vector2(2, 2): Vector2(1, 2),
}


func get_level_bounds() -> Rect2:
	# Assumes camera centered on (0, 0).
	return Rect2(Vector2.ZERO, _camera.get_viewport_rect().size * _camera.zoom)


func get_from_dir_with_world_positions(world_pos: Vector2, world_prev_pos: Vector2) -> Vector2:
	var pos := world_to_map(world_pos)
	var prev_pos := world_to_map(world_prev_pos)
	return get_from_dir(pos, prev_pos)


func get_from_dir(pos: Vector2, from_pos: Vector2) -> Vector2:
	var from_dir = (from_pos - pos).normalized()  # TODO: See that this is unary
	assert(from_dir in [Vector2.UP, Vector2.LEFT, Vector2.DOWN, Vector2.RIGHT])
	return from_dir


func _has_visited_loop(pos: Vector2, from_dir: Vector2, trolley_id: int) -> bool:
	var starting_pos = pos  # Already evaluated as visited
	var old_pos = pos
	pos = get_tile_next_pos(pos, from_dir)
	assert(pos != Vector2.INF)
	from_dir = get_from_dir(pos, old_pos)
	while pos != starting_pos:
		if not is_cell_already_visited(pos, from_dir, trolley_id):
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


func is_cell_already_visited(pos: Vector2, from_dir: Vector2, trolley_id: int):
	var key = make_visited_cell_key(pos, trolley_id)
	return _visited_cells.has(key) and _visited_cells[key].hash() == _visited_cell_from_pos(pos, from_dir).hash()


func mark_cell_as_cleared(pos: Vector2) -> void:
	# need to erase for any possible trolley staying here.
	# TODO: Use a better key for _visited_cells.
	for i in get_num_trolleys():
		_visited_cells.erase(make_visited_cell_key(pos, i))
	for line in _line_drawers.get_children():
		(line as LineDrawer).remove_points_until(_pos_to_tile_center_world(pos))
	_indicator_tilemap.set_cell(pos.x, pos.y, -1)


# We asume this is only called by trolley
func mark_cell_as_visited(pos: Vector2, from_dir: Vector2, trolley_id: int) -> void:	
	if not GlobalState.level_lost and not GlobalState.level_completed and is_cell_already_visited(pos, from_dir, trolley_id):
		if _has_visited_loop(pos, from_dir, trolley_id):
			EventBus.emit_signal("level_completed")
			return

	if GlobalState.level_completed:
		return

	var key = make_visited_cell_key(pos, trolley_id)
	_visited_cells[key] = _visited_cell_from_pos(pos, from_dir)


func mark_world_pos_cell_as_visited(world_pos: Vector2, from_world_pos: Vector2, trolley_id: int) -> void:
	var pos = world_to_map(world_pos)
	var from_pos = world_to_map(from_world_pos)
	var from_dir = get_from_dir(pos, from_pos)
	mark_cell_as_visited(pos, from_dir, trolley_id)

# TODO: consider doing the loop check here as well.
# These midpoints are important because the value is fetched when partially removing the trail.
func add_trolley_line_midpoint(world_pos: Vector2, trolley_id: int) -> void:
	var pos := world_to_map(world_pos)
	_line_drawers.get_child(trolley_id).add_point(_pos_to_tile_center_world(pos))


# These points are not that important, and we add them to make the line smoother
func add_trolley_line_decorative_point(world_pos: Vector2, trolley_id: int) -> void:
	_line_drawers.get_child(trolley_id).add_point(world_pos)


func get_num_trolleys() -> int:
	return _trolley_world_positions.size()


func get_trolley_starting_world_position(id: int) -> Vector2:
	assert(not _trolley_world_positions.empty())
	return _trolley_world_positions[id]


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
	mark_cell_as_cleared(pos)
	if pos == _level_tile_hint_pos:
		_level_tile_hint_sprite.hide()


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
	return _pos_to_tile_center_world(tile_pos) + target_dir * HALF_CELL


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
	return ind in TILEMAP_FLIP_COORD.keys()


func is_world_pos_a_toggable_tile(world_pos: Vector2) -> bool:
	var pos := world_to_map(world_pos)
	var coord := get_cell_autotile_coord(pos.x, pos.y)
	return is_autotile_coord_toggable(coord)


func set_action_hover_visible(world_pos: Vector2, set_visible: bool) -> void:
	var pos := world_to_map(world_pos)
	_action_hover_indicator.position = _pos_to_tile_center_world(pos)
	_action_hover_indicator.visible = set_visible


const EMPTY_TILE = -1
func _ready() -> void:
	EventBus.connect("trolley_created", self, "_on_EventBus_trolley_created")
	if not GlobalState.trolley_waits_for_player():
		_start_warning_sign(TROLLEY_WAIT_TIME)
	
	for pos in get_used_cells_by_id(_current_main_tileset_id):
		var coord := get_cell_autotile_coord(pos.x, pos.y)
		if coord == PLAYER_START_COORD:
			assert(_player_starting_world_pos == Vector2.INF)
			_player_starting_world_pos = _pos_to_tile_center_world(pos)
			set_cell(pos.x, pos.y, EMPTY_TILE)
		elif coord == TROLLEY_START_COORD:
			_trolley_world_positions.append(_pos_to_tile_center_world(pos))
			set_cell(pos.x, pos.y, _current_main_tileset_id)
		elif coord == TROLLEY_WARNING_COORD:
			var warning_sprite = TROLLEY_WARNING_SPRITE_SCENE.instance()
			warning_sprite.position = _pos_to_tile_center_world(pos)
			_trolley_warning_sprites.add_child(warning_sprite)
			set_cell(pos.x, pos.y, EMPTY_TILE)
	for pos in _indicator_tilemap.get_used_cells_by_id(MAIN_INDICATOR_TILEMAP_ID):
		var coord := _indicator_tilemap.get_cell_autotile_coord(pos.x, pos.y)
		if coord == INDICATOR_TILEMAP_HINT_COORD:
			assert(_level_tile_hint_pos == Vector2.INF)
			_level_tile_hint_pos = pos
			_level_tile_hint_sprite.position = _pos_to_tile_center_world(pos)
			_level_tile_hint_sprite.show()
			var backwards = true
			_level_tile_hint_sprite.play("", backwards)
			mark_cell_as_cleared(pos)


func _start_warning_sign(seconds: float) -> void:
	_trolley_warning_sprites.show()
	_trolley_warning_timer.start(seconds)


func _on_EventBus_trolley_created() -> void:
	if _warning_shown:
		return
	_start_warning_sign(1.0)


func _on_TrolleyWarningTimer_timeout() -> void:
	_trolley_warning_sprites.hide()


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

