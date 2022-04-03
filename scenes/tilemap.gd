extends TileMap
class_name MyTileMap

export (float, 1.0, 10.0, 1.0) var TROLLEY_WAIT_TIME = 1.0

var _trolley_world_position := Vector2.INF
var _player_starting_world_pos := Vector2.INF

const CELL_SIZE = 32
const HALF_CELL = CELL_SIZE * 0.5

const PLAYER_START_COORD = Vector2(0, 2)
const TROLLEY_START_COORD = Vector2(0, 3)
const MAIN_TILEMAP_ID = 0

const TILEMAP_ENDPOINTS = {
	Vector2(0, 0):  # Straight horizontal
		[Vector2(0, HALF_CELL), Vector2(CELL_SIZE, HALF_CELL)],
	Vector2(1, 0):  # Straight horizontal, can toggle left-down
		[Vector2(0, HALF_CELL), Vector2(CELL_SIZE, HALF_CELL)],
	Vector2(2, 0):  # Left-Down, can toggle Left-Right
		 [Vector2(0, HALF_CELL), Vector2(HALF_CELL, CELL_SIZE)],
	Vector2(3, 0):  # Left-Down
		[Vector2(0, HALF_CELL), Vector2(HALF_CELL, CELL_SIZE)],
	Vector2(0, 1):  # Victim
		[Vector2(0, HALF_CELL), Vector2(CELL_SIZE, HALF_CELL)],	
	Vector2(1, 1):  # Left-Right,Left-Down
		[]
}

const TILEMAP_FLIP_COORD = {
	Vector2(1, 0): Vector2(2, 0),
	Vector2(2, 0): Vector2(1, 0),
}


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


func is_out_of_bounds(world_pos: Vector2) -> bool:
	var pos := world_to_map(world_pos)
	return get_cell(pos.x, pos.y) == -1


func get_tile_world_endpoints(tile_world_pos: Vector2, coming_from_world_pos: Vector2 = Vector2.INF) -> Array:
	var pos := world_to_map(tile_world_pos)
	var tileset_ind = get_cell(pos.x, pos.y)
	var ind := get_cell_autotile_coord(pos.x, pos.y)
	var points = TILEMAP_ENDPOINTS[ind].duplicate()
	for i in 2:
		if is_cell_transposed(pos.x, pos.y):
			points[i] = Vector2(points[i].y, points[i].x)
		if is_cell_x_flipped(pos.x, pos.y):
			points[i].x = CELL_SIZE - points[i].x
		if is_cell_y_flipped(pos.x, pos.y):
			points[i].y = CELL_SIZE - points[i].y
		points[i] += pos * CELL_SIZE
	return points
	

func is_autotile_coord_toggable(ind: Vector2) -> bool:
	return ind in [Vector2(1, 0), Vector2(2, 0)]


func is_world_pos_a_toggable_tile(world_pos: Vector2) -> bool:
	var pos := world_to_map(world_pos)
	var coord := get_cell_autotile_coord(pos.x, pos.y)
	return is_autotile_coord_toggable(coord)


func _ready() -> void:
	for pos in get_used_cells_by_id(MAIN_TILEMAP_ID):
		var coord := get_cell_autotile_coord(pos.x, pos.y)
		if coord == PLAYER_START_COORD:
			assert(_player_starting_world_pos == Vector2.INF)
			_player_starting_world_pos = pos * CELL_SIZE + Vector2.ONE*HALF_CELL
			set_cell(pos.x, pos.y, -1)
		elif coord == TROLLEY_START_COORD:
			assert(_trolley_world_position == Vector2.INF)
			_trolley_world_position = pos * CELL_SIZE + Vector2.ONE*HALF_CELL
			set_cell(pos.x, pos.y, MAIN_TILEMAP_ID)
	print("done ready")
	pass
