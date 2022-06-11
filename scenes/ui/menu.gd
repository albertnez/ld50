extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


func _on_NewGameButton_pressed() -> void:
	var packed_world := load("res://scenes/world.tscn")
	get_tree().change_scene_to(packed_world)


func _on_SelectLevelButton_pressed() -> void:
	var level_selection := load( "res://scenes/ui/level_select.tscn")
	get_tree().change_scene_to(level_selection)
