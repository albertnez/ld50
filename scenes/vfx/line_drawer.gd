extends Node2D
class_name LineDrawer

onready var _scene_points := $Points
var _points := []
var _point_transformations := []

# To quickly test with multiple trolleys
const COLOR_ARRAY = [Color.red, Color.aqua, Color.yellowgreen]

export (Color) var LINE_COLOR = Color.red
export (float, 0.5, 64.0) var LINE_WIDTH = 2.0
export (float, 0.0, 20.0) var POINT_SHIFT_RADIUS = 10.0

var TIP_POINT : Node2D = null


# Removes all points stored from beginning until the first occurrence of the given point, included.
func remove_points_until(point: Vector2) -> void:
	var index = _points.find(point)
	if index == -1:
		return
	_points = _points.slice(index+1, _points.size()-1)


func has_point(point : Vector2) -> bool:
	return _points.find(point) != -1


func add_point(point : Vector2) -> void:
	_points.append(point)
	_add_point_transformation()


func set_tip_point(tip : Node2D) -> void:
	TIP_POINT = tip


func _transform_point(point : Vector2) -> Vector2:
	var rot_shift = rand_range(0, 2*PI)
	return point + Vector2.ONE.rotated(rot_shift)*POINT_SHIFT_RADIUS


func _draw() -> void:
	var last_point := Vector2.INF
	var size = _points.size()

	for idx in size:
		var point : Vector2 = _points[idx] + _point_transformations[idx%size]
		if last_point == Vector2.INF:
			last_point = point
			continue

		draw_line(last_point, point, LINE_COLOR, LINE_WIDTH)
		last_point = point
	
	if TIP_POINT and TIP_POINT.position != Vector2.INF and last_point != Vector2.INF:
		draw_line(last_point, TIP_POINT.position, LINE_COLOR, LINE_WIDTH)


func _ready() -> void:
	# Debugging 
	var subscene_parent = _scene_points.get_parent().get_parent()
	if subscene_parent == get_tree().root:
		for point in _scene_points.get_children():
			_points.append(point.position)
	pass


func _process(_delta: float) -> void:
	update()


func _regenerate_point_transformations() -> void:
	_point_transformations.clear()
	# +1 for the tip point.
	for point in _points.size() + 1:
		_add_point_transformation()


func _add_point_transformation() -> void:
	var rotation = rand_range(0, 2*PI)
	_point_transformations.append(Vector2.ONE.rotated(rotation)*POINT_SHIFT_RADIUS)
