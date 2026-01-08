extends Control

@onready var label = $Label

func _ready():
	if label:
		label.text = Global.game_over_message
		
		# Change color based on message content
		if "WIN" in Global.game_over_message:
			label.add_theme_color_override("font_color", Color(0, 1, 0)) # Green
		else:
			label.add_theme_color_override("font_color", Color(1, 0, 0)) # Red

func _on_button_pressed():
	print("EndScene: Restart Pressed")
	get_tree().change_scene_to_file("res://scenes/game.tscn")
