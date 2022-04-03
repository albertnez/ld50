extends Node2D


# Declare member variables here. Examples:
# var a: int = 2
# var b: String = "text"


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	EventBus.connect("level_completed", $LevelUpPlayer, "play")
	EventBus.connect("level_restart", $ClickPlayer, "play")
	EventBus.connect("toggle", $TogglePlayer, "play")
	EventBus.connect("person_crashed", $CrashPlayer, "play")
	EventBus.connect("trolley_crashed", $CrashPlayer, "play")
	EventBus.connect("trolley_killed_someone", $CrashPlayer, "play")
	
	pass # Replace with function body.

