extends Node

# Menu stuff.
enum TargetMenuScene {
	LEVEL_SELECT,
	MAIN_MENU,
	MAIN_GAME,
	OPTIONS,
}
signal change_menu_scene(target_menu_scene, starting_level)
# Pause stuff
signal resume_game()

# Other stuff.
signal trolley_crashed(trolley_color)
signal trolley_killed_someone(trolley_color)
signal trolley_crash_with_trolley(trolley_color)  # Color of the first one, for calling convenience.
signal trolley_wrong_bifurcation(trolley_color)

# Level handling
signal go_to_next_level()
signal level_restart()
signal new_level_waiting_for_trolley(seconds)
signal trolley_created_later()
signal person_crashed(trolley_color)
signal toggle()
signal level_completed()
signal trolley_speed_changed(is_fast_forward)


func _ready() -> void:
	pass
