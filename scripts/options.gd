extends Control

@onready var controls_panel = $ControlsPanel
@onready var audio_panel = $AudioPanel

@onready var master_slider = $AudioPanel/VBoxContainer/Master/MasterSlider
@onready var music_slider = $AudioPanel/VBoxContainer/Music/MusicSlider
@onready var sfx_slider = $AudioPanel/VBoxContainer/SFX/SFXSlider

func _ready():
	# Update sliders to current AudioServer volume
	var master_idx = AudioServer.get_bus_index("Master")
	var music_idx = AudioServer.get_bus_index("Music")
	var sfx_idx = AudioServer.get_bus_index("SFX")
	
	master_slider.value = db_to_linear(AudioServer.get_bus_volume_db(master_idx))
	music_slider.value = db_to_linear(AudioServer.get_bus_volume_db(music_idx))
	sfx_slider.value = db_to_linear(AudioServer.get_bus_volume_db(sfx_idx))

func _on_controls_btn_pressed():
	controls_panel.visible = true
	audio_panel.visible = false

func _on_audio_btn_pressed():
	controls_panel.visible = false
	audio_panel.visible = true

func _on_back_btn_pressed():
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _on_master_slider_value_changed(value):
	var bus_idx = AudioServer.get_bus_index("Master")
	AudioServer.set_bus_volume_db(bus_idx, linear_to_db(value))

func _on_music_slider_value_changed(value):
	var bus_idx = AudioServer.get_bus_index("Music")
	AudioServer.set_bus_volume_db(bus_idx, linear_to_db(value))

func _on_sfx_slider_value_changed(value):
	var bus_idx = AudioServer.get_bus_index("SFX")
	AudioServer.set_bus_volume_db(bus_idx, linear_to_db(value))
