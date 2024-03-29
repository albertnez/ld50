extends Node2D

onready var _root_for_menu := $CanvasLayer
onready var _current_menu_node := $CanvasLayer/Menu
onready var _canvas_layer_node := $"%CanvasLayer"
onready var _boot_splash_dimmer := $"%BootSplashDimmer"


const LEVEL_SELECT_SCENE = preload("res://scenes/ui/level_select.tscn")
const MAIN_MENU_SCENE = preload("res://scenes/ui/menu.tscn")
const OPTIONS_SCENE = preload("res://scenes/ui/options_menu.tscn")
const CREDITS_SCENE = preload("res://scenes/ui/credits_menu.tscn")

func _ready() -> void:
	var _unused = EventBus.connect("change_menu_scene", self, "_on_EventBus_change_menu_scene")
	# We instance the trolley in the main menu.
	EventBus.emit_signal("trolley_created_later")
	
	if GlobalState.menu_scene != EventBus.TargetMenuScene.MAIN_MENU:
		_on_EventBus_change_menu_scene(GlobalState.menu_scene, -1)
	
	# The first time we boot the game, we do a smooth transition from SplashScreen -> Menu
	if not GlobalState.game_launched:
		GlobalState.game_launched = true
		_boot_splash_dimmer.modulate = Color.black
		_boot_splash_dimmer.show()
		var tween := get_tree().create_tween()
		# warning-ignore:return_value_discarded
		tween.tween_property(_boot_splash_dimmer, "modulate", Color.transparent, 0.7)
		tween.tween_callback(_boot_splash_dimmer, "hide")
		tween.play()
	


func _on_EventBus_change_menu_scene(target_scene: int, starting_level: int) -> void:
	match target_scene:
		EventBus.TargetMenuScene.MAIN_GAME:
			GlobalState.level_selected_in_menu = starting_level
			GlobalState.in_main_menu = false
			var new_pack : PackedScene = load("res://scenes/world.tscn")
			if get_tree().change_scene_to(new_pack) != OK:
				print("Error changing scene to world_scene")
		EventBus.TargetMenuScene.LEVEL_SELECT:
			_current_menu_node.queue_free()
			_current_menu_node = LEVEL_SELECT_SCENE.instance()
			# These nodes need to be above Overlay buttons, or they won't be clickable.
			_root_for_menu.add_child_below_node(_canvas_layer_node.get_child(0), _current_menu_node)
		EventBus.TargetMenuScene.MAIN_MENU:
			_current_menu_node.queue_free()
			_current_menu_node = MAIN_MENU_SCENE.instance()
			# These nodes need to be above Overlay buttons, or they won't be clickable.
			_root_for_menu.add_child_below_node(_canvas_layer_node.get_child(0), _current_menu_node)
		EventBus.TargetMenuScene.OPTIONS:
			_current_menu_node.queue_free()
			_current_menu_node = OPTIONS_SCENE.instance()
			# These nodes need to be above Overlay buttons, or they won't be clickable.
			_root_for_menu.add_child_below_node(_canvas_layer_node.get_child(0), _current_menu_node)
		EventBus.TargetMenuScene.CREDITS:
			_current_menu_node.queue_free()
			_current_menu_node = CREDITS_SCENE.instance()
			# These nodes need to be above Overlay buttons, or they won't be clickable.
			_root_for_menu.add_child_below_node(_canvas_layer_node.get_child(0), _current_menu_node)
			
