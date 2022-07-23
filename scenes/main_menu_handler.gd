extends Node2D

onready var _root_for_menu := $CanvasLayer
onready var _current_menu_node := $CanvasLayer/Menu

const LEVEL_SELECT_SCENE = preload("res://scenes/ui/level_select.tscn")
const MAIN_MENU_SCENE = preload("res://scenes/ui/menu.tscn")

func _ready() -> void:
	EventBus.connect("change_menu_scene", self, "_on_EventBus_change_menu_scene")


func _on_EventBus_change_menu_scene(target_scene: int, starting_level: int) -> void:
	match target_scene:
		EventBus.TargetMenuScene.MAIN_GAME:
			var world_scene : GameWorld = load("res://scenes/world.tscn").instance()
			world_scene._current_level = starting_level
			var new_pack := PackedScene.new()
			new_pack.pack(world_scene)
			get_tree().change_scene_to(new_pack)
		EventBus.TargetMenuScene.LEVEL_SELECT:
			_current_menu_node.queue_free()
			_current_menu_node = LEVEL_SELECT_SCENE.instance()
			_root_for_menu.add_child(_current_menu_node)
		EventBus.TargetMenuScene.MAIN_MENU:
			_current_menu_node.queue_free()
			_current_menu_node = MAIN_MENU_SCENE.instance()
			_root_for_menu.add_child(_current_menu_node)