extends Node2D


func _on_button_pressed() -> void:
	$Control/ColorRect/ColorRect/Timer.start()
	$Control/ColorRect/ColorRect/AnimationPlayer.play("slide down")


func _on_timer_timeout() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
