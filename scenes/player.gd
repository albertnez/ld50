extends Sprite

onready var _can_toggle := $CanToggle
export (float, 10, 3000, 10.0) var SPEED = 140.0

func _ready() -> void:
	pass


func set_toggle_is_visible(visible: bool) -> void:
	_can_toggle.visible = visible


func _process(delta: float) -> void:
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
