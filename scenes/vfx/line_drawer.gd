extends Node2D

onready var _scene_points := $Points
var _points := []

export (Color) var LINE_COLOR = Color.red
export (float, 0.5, 64.0) var LINE_WIDTH = 2.0
export (float, 0.0, 20.0) var POINT_SHIFT_RADIUS = 10.0


func add_point(point : Vector2) -> void:
	_points.append(point)


func _shifted_point(point : Vector2) -> Vector2:
	var rot_shift = rand_range(0, 2*PI)
	return point + Vector2.ONE.rotated(rot_shift)*POINT_SHIFT_RADIUS


func _draw() -> void:
	var last_point := Vector2.INF

	for point in _points:
		point = _shifted_point(point)
		if last_point == Vector2.INF:
			last_point = point
			continue

		draw_line(last_point, point, LINE_COLOR, LINE_WIDTH)
		last_point = point


func _ready() -> void:
	# Debugging 
	var subscene_parent = _scene_points.get_parent().get_parent()
	if subscene_parent == get_tree().root:
		for point in _scene_points.get_children():
			_points.append(point.position)
	pass


func _process(delta: float) -> void:
	update()