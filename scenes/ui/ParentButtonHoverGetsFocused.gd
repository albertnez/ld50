extends Node
class_name ParentbuttonHoverGetsFocused


func _ready() -> void:
	var p := get_parent() as Control
	assert(p.connect("mouse_entered", p, "grab_focus") == OK)
