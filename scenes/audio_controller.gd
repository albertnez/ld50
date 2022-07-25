extends Node2D


# Declare member variables here. Examples:
# var a: int = 2
# var b: String = "text"


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var _u = null  # Unused
	_u = EventBus.connect("level_completed", $LevelUpPlayer, "play")
	_u = EventBus.connect("level_restart", $ClickPlayer, "play")
	_u = EventBus.connect("toggle", $TogglePlayer, "play")
	_u = EventBus.connect("person_crashed", $CrashPlayer, "play")
	_u = EventBus.connect("trolley_crashed", $CrashPlayer, "play")
	_u = EventBus.connect("trolley_killed_someone", $CrashPlayer, "play")
	_u = EventBus.connect("trolley_crash_with_trolley", $CrashPlayer, "play")
	
	pass # Replace with function body.

