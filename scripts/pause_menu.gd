extends Control

func _ready() -> void:
	$".".hide()
	$ColorRect/AnimationPlayer.play("RESET")

func resume():
	get_tree().paused = false
	$".".hide()
	$ColorRect/AnimationPlayer.play("fade out")

func pause():
	get_tree().paused = true
	$".".show()
	$ColorRect/AnimationPlayer.play("fade in")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func testEsc():
	if Input.is_action_pressed("pause") and get_tree().paused == false: 
		pause()
		
	elif Input.is_action_pressed("pause") and get_tree().paused == true:
		resume()
		



func _on_texture_button_pressed() -> void:
	resume()
	$AudioStreamPlayer2D.play()



func _on_texture_button_2_pressed() -> void:
	resume()
	Global.reset_game_state()
	get_tree().reload_current_scene()
	$AudioStreamPlayer2D.play()


func _on_texture_button_3_pressed() -> void:
	get_tree().quit()
	$AudioStreamPlayer2D.play()
	
func _unhandled_input(_event: InputEvent) -> void:
	testEsc()
