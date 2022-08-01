extends Control

export (int, 10, 100, 10) var LEVEL_BUTTON_SIZE = 2

const BUTTON_HOVER_GETS_FOCUSED = preload("res://scenes/ui/button_hover_gets_focused.gd")

onready var _grid_container := get_node("%LevelGridContainer")
onready var _descritpion_label := get_node("LevelDescriptionLabel")
onready var _back_button := $"%BackButton"


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var ind = 0
	var target_size := Vector2(LEVEL_BUTTON_SIZE, LEVEL_BUTTON_SIZE)
	for level_item in GlobalState.LEVEL_LIST:
		var button := Button.new()
		if ind > GlobalState.latest_level_unlocked:
			button.disabled = true
		button.text = str(ind).pad_zeros(2)
		button.set_script(BUTTON_HOVER_GETS_FOCUSED)
		var _u = null  # Unused connect return value
		_u = button.connect("pressed", self, "_on_LevelButton_pressed", [ind])
		_u = button.connect("focus_entered", self, "_on_LevelButton_focus_entered", [ind])
		_grid_container.add_child(button)
		if ind == 0:
			button.grab_focus()
		ind += 1
		target_size.x = max(target_size.x, button.rect_size.x)
		target_size.y = max(target_size.y, button.rect_size.y)
	
	for child in _grid_container.get_children():
		var button := child as Button
		button.rect_min_size = target_size

	_back_button.connect("focus_entered", self, "_on_LevelButton_focus_entered", [-1])

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_tree().set_input_as_handled()
		EventBus.emit_signal("change_menu_scene", EventBus.TargetMenuScene.MAIN_MENU, 0)


func _on_BackButton_pressed() -> void:
	EventBus.emit_signal("change_menu_scene", EventBus.TargetMenuScene.MAIN_MENU, 0)


func _on_LevelButton_pressed(level: int) -> void:
	EventBus.emit_signal("change_menu_scene", EventBus.TargetMenuScene.MAIN_GAME, level)


func _on_LevelButton_focus_entered(level: int) -> void:
	if level == -1:
		_descritpion_label.text = ""
		return
	# We asume the scene file name will be our description.
	var scene_path : String = GlobalState.LEVEL_LIST[level].resource_path
	var description = "[LOCKED]"
	if level <= GlobalState.latest_level_unlocked:
		description = scene_path.get_file().trim_suffix(".tscn").replace("_", " ")
	var text := str("Level ", level, "\n", description)
	_descritpion_label.text = text
