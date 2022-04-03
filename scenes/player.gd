extends Area2D
class_name Player

export (float, 10, 3000, 10.0) var SPEED = 140.0
onready var _can_toggle := $CanToggle
onready var _animation := $Animation
var _dead := false


func is_dead() -> bool:
	return _dead


func _ready() -> void:
	EventBus.connect("level_restart", self, "_on_Eventbus_level_restart")
	pass


func set_toggle_is_visible(visible: bool) -> void:
	_can_toggle.visible = visible


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
	
	position += dir.normalized() * SPEED * delta
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
	pass # Replace with function body.


func _on_Eventbus_level_restart() -> void:
	_animation.play("default")
	_dead = false
