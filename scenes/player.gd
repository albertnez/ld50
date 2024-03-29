extends Area2D
class_name Player

export (float, 10, 3000, 10.0) var SPEED = 140.0
export (float, 0, 32, 1.0) var TOGGLE_REACH = 16.0
onready var _animation := $Animation
var _dead := false
var _move_bounds := Rect2()


func is_dead() -> bool:
	return _dead


func _ready() -> void:
	# warning-ignore:return_value_discarded
	EventBus.connect("level_restart", self, "_on_Eventbus_level_restart")
	# warning-ignore:return_value_discarded
	EventBus.connect("trolley_crashed", self, "_update_animation_on_level_fail")
	# warning-ignore:return_value_discarded
	EventBus.connect("trolley_killed_someone", self, "_update_animation_on_level_fail")
	# warning-ignore:return_value_discarded
	EventBus.connect("trolley_crash_with_trolley", self, "_update_animation_on_level_fail")
	# warning-ignore:return_value_discarded
	EventBus.connect("trolley_wrong_bifurcation", self, "_update_animation_on_level_fail")
	


func _update_animation_on_level_fail(_unused_color) -> void:
	if _animation.animation == "walk":
		_animation.play("default")


func set_moving_bounds(bounds: Rect2) -> void:
	_move_bounds = bounds

func _process(delta: float) -> void:
	if _dead or not GlobalState.is_playing():
		return

	var dir : Vector2 = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down") * SPEED * delta
	
	var vertical = Vector2(0, dir.y)
	var horizontal = Vector2(dir.x, 0)
	if _move_bounds.has_point(position + vertical):
		position += vertical
	if _move_bounds.has_point(position + horizontal):
		position += horizontal

	if dir == Vector2.ZERO:
		_animation.play("default")
	else:
		_animation.play("walk")


func _on_Player_area_entered(area: Area2D) -> void:
	if area is Trolley and not GlobalState.level_lost and not GlobalState.level_completed:
		var trolley_color := (area as Trolley).modulate
		EventBus.emit_signal("person_crashed", trolley_color)
		_dead = true
		GlobalState.level_lost = true
		_animation.play("dead")


func _on_Eventbus_level_restart() -> void:
	_animation.play("default")
	_dead = false
