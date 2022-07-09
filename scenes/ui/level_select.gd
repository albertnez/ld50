extends Control

export (int, 10, 100, 10) var LEVEL_BUTTON_SIZE = 2

const BUTTON_HOVER_GETS_FOCUSED = preload("res://scenes/ui/button_hover_gets_focused.gd")
onready var _grid_container := get_node("%LevelGridContainer")
onready var _descritpion_label := get_node("LevelDescriptionLabel")


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var ind = 0
	var target_size := Vector2(LEVEL_BUTTON_SIZE, LEVEL_BUTTON_SIZE)
	for level_item in GlobalState.LEVEL_LIST:
		var level := level_item as Resource
		var button := Button.new()
		button.text = str(ind).pad_zeros(2)
		button.set_script(BUTTON_HOVER_GETS_FOCUSED)
		button.connect("pressed", self, "_on_LevelButton_pressed", [ind])
		button.connect("focus_entered", self, "_on_LevelButton_focus_entered", [ind])
		_grid_container.add_child(button)
		if ind == 0:
			button.grab_focus()
		ind += 1
		target_size.x = max(target_size.x, button.rect_size.x)
		target_size.y = max(target_size.y, button.rect_size.y)
	
	for child in _grid_container.get_children():
		var button := child as Button
		button.rect_min_size = target_size


func _process(delta: float) -> void:
	if Input.is_action_just_pressed("ui_cancel"):
		get_tree().change_scene_to(load("res://scenes/main_menu_handler.tscn"))


func _on_LevelButton_pressed(level: int) -> void:
	var world_scene : GameWorld = load("res://scenes/world.tscn").instance()
	world_scene._current_level = level
	var new_pack := PackedScene.new()
	new_pack.pack(world_scene)
	get_tree().change_scene_to(new_pack)

func _on_LevelButton_focus_entered(level: int) -> void:
	# We asume the scene file name will be our description.
	var scene_path : String = GlobalState.LEVEL_LIST[level].resource_path
	var description = scene_path.get_file().trim_suffix(".tscn").replace("_", " ")
	
	_descritpion_label.text = str("Level ", level, ":\n", description)
