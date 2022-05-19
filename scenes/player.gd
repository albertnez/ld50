extends Area2D
class_name Player

export (float, 10, 3000, 10.0) var SPEED = 140.0
onready var _can_toggle := $CanToggle
onready var _animation := $Animation
var _dead := false
var _move_bounds := Rect2()


func is_dead() -> bool:
	return _dead


func _ready() -> void:
	EventBus.connect("level_restart", self, "_on_Eventbus_level_restart")


func set_toggle_is_visible(visible: bool) -> void:
	_can_toggle.visible = visible


func set_moving_bounds(bounds: Rect2) -> void:
	_move_bounds = bounds

func _process(delta: float) -> void:
	if _dead:
		return

	var dir := Vector2.ZERO
	
	if Input.is_action_pressed("ui_down"):
		dir += Vector2.DOWN
	if Input.is_action_pressed("ui_up"):
		dir += Vector2.UP
	if Input.is_action_pressed("ui_left"):
		dir += Vector2.LEFT
	if Input.is_action_pressed("ui_right"):
		dir += Vector2.RIGHT
	
	dir = dir.normalized() * SPEED * delta
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
		EventBus.emit_signal("person_crashed")
		_dead = true
		GlobalState.level_lost = true
		_animation.play("dead")


func _on_Eventbus_level_restart() -> void:
	_animation.play("default")
	_dead = false
