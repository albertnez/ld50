extends Control


onready var _grid_container := get_node("%LevelGridContainer")


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var ind = 0
	for level_item in GlobalState.LEVEL_LIST:
		var level := level_item as Resource
		var button := Button.new()
		button.text = str(ind).pad_zeros(2)
		button.connect("pressed", self, "_on_LevelButton_pressed", [ind])
		_grid_container.add_child(button)
		if ind == 0:
			button.grab_focus()
		ind += 1


func _process(delta: float) -> void:
	if Input.is_action_just_pressed("ui_cancel"):
		get_tree().change_scene_to(load("res://scenes/main_menu_handler.tscn"))

func _on_LevelButton_pressed(level: int) -> void:
	var world_scene : GameWorld = load("res://scenes/world.tscn").instance()
	world_scene._current_level = level
	var new_pack := PackedScene.new()
	new_pack.pack(world_scene)
	get_tree().change_scene_to(new_pack)
