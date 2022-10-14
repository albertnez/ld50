extends Control


onready var _sfx_bus_idx := AudioServer.get_bus_index("Sfx")
onready var _music_bus_idx := AudioServer.get_bus_index("Music")

onready var _sfx_slider := $"%SfxSlider"
onready var _music_slider := $"%MusicSlider"
onready var _beep_player := $"%BeepPlayer"

func _ready() -> void:
	pass # Replace with function body.



func _on_SfxSlider_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(_sfx_bus_idx, linear2db(value / _sfx_slider.max_value))
	_beep_player.play()


func _on_MusicSlider_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(_music_bus_idx, linear2db(value / _music_slider.max_value))
