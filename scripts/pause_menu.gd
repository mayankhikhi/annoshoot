extends Control


var button = null


func _on_texture_button_pressed() -> void:
	button = 'resume'
	$AudioStreamPlayer2D.play()
	$ColorRect/Timer.start()
	$ColorRect/AnimationPlayer.play("fade out")
	

func _on_texture_button_2_pressed() -> void:
	button = 'main menu'
	$AudioStreamPlayer2D.play()
	$ColorRect/Timer.start()
	$ColorRect/AnimationPlayer.play("fade out")


func _on_texture_button_3_pressed() -> void:
	button = 'quit'
	$AudioStreamPlayer2D.play()
	$ColorRect/Timer.start()
	$ColorRect/AnimationPlayer.play("fade out")

func _on_timer_timeout() -> void:
	if button == 'resume':
		get_tree().change_scene_to_file("res://scenes/game.tscn")
	if button == 'main menu':
		get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
	if button == 'quit':
		get_tree().quit()
