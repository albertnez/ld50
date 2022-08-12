extends Node

# Menu stuff.
enum TargetMenuScene {
	LEVEL_SELECT,
	MAIN_MENU,
	MAIN_GAME,
}
signal change_menu_scene(target_menu_scene, starting_level)
# Pause stuff
signal resume_game()

# Other stuff.
signal trolley_crashed()
signal trolley_killed_someone()
signal trolley_crash_with_trolley()
signal level_restart()
signal new_level_waiting_for_trolley(seconds)
signal trolley_created_later()
signal person_crashed()
signal toggle()
signal level_completed()
signal trolley_speed_changed(is_fast_forward)


func _ready() -> void:
	pass
