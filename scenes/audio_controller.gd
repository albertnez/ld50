extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var _u = null  # Unused
	_u = EventBus.connect("level_completed", $LevelUpPlayer, "play")
	_u = EventBus.connect("level_restart", $ClickPlayer, "play")
	_u = EventBus.connect("toggle", $TogglePlayer, "play")
	_u = EventBus.connect("person_crashed", self, "_play_crash")
	_u = EventBus.connect("trolley_crashed", self, "_play_crash")
	_u = EventBus.connect("trolley_killed_someone", self, "_play_crash")
	_u = EventBus.connect("trolley_crash_with_trolley", self, "_play_crash")
	_u = EventBus.connect("trolley_wrong_bifurcation", self, "_play_crash")


# Needed only because some signals have one argument, and thus cannot call 'play' directly.
func _play_crash(_unused_color) -> void:
	$CrashPlayer.play()
