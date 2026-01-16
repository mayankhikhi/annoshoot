extends Node2D


var button_type = null


func _on_button_pressed():
	button_type = "start"
	$"background/00FinalProduct/AnimationPlayer".play("slide down")
	$background/Cloud1/AnimationPlayer.play("slide out")
	$background/Cloud2/AnimationPlayer.play("slide out")
	$background/Cloud3/AnimationPlayer.play("slide out")
	$background/Cloud4/AnimationPlayer.play("slide out")
	$background/Cloud5/AnimationPlayer.play("slide out")
	$"background/00FinalProduct/Timer".start()

func _on_button_2_pressed():
	button_type = "quit"
	$"background/00FinalProduct/AnimationPlayer".play("slide down")
	$background/Cloud1/AnimationPlayer.play("slide out")
	$background/Cloud2/AnimationPlayer.play("slide out")
	$background/Cloud3/AnimationPlayer.play("slide out")
	$background/Cloud4/AnimationPlayer.play("slide out")
	$background/Cloud5/AnimationPlayer.play("slide out")
	$"background/00FinalProduct/Timer".start()


func _on_button_3_pressed() -> void:
	button_type = "options"
	$"background/00FinalProduct/AnimationPlayer".play("slide down")
	$background/Cloud1/AnimationPlayer.play("slide out")
	$background/Cloud2/AnimationPlayer.play("slide out")
	$background/Cloud3/AnimationPlayer.play("slide out")
	$background/Cloud4/AnimationPlayer.play("slide out")
	$background/Cloud5/AnimationPlayer.play("slide out")
	$"background/00FinalProduct/Timer".start()

func _on_timer_timeout() -> void:
	if button_type == "start":
		Global.reset_game_state()
		get_tree().change_scene_to_file("res://scenes/game.tscn")
	if button_type == "quit":
		get_tree().quit()
	if button_type == "options":
		get_tree().change_scene_to_file("res://scenes/options.tscn")
