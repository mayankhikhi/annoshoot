extends Area2D

func _ready():
	print("Area2D: Script Ready")
	monitoring = true
	monitorable = true
	# Ensure the signal is connected
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
		print("Area2D: Manually connected body_entered signal")
	
func _on_body_entered(body: Node2D) -> void:
	print("Area2D Body Entered: ", body.name)
	if body.is_in_group("player"):
		print("Player entered lift area")
		if Global.zombies_remaining <= 0:
			print("Level Complete! Teleporting...")
			call_deferred("change_level", body)
		else:
			print("Cannot enter yet: " + str(Global.zombies_remaining) + " zombies remaining")
			# You could also trigger the UI message here if you have access to the player
			if body.get("kill_all_label"):
				body.kill_all_label.visible = true
				await get_tree().create_timer(3.0).timeout
				if body and body.get("kill_all_label"):
					body.kill_all_label.visible = false

func change_level(body: Node2D = null):
	if body and body.has_method("transition_to_scene"):
		body.transition_to_scene("res://scenes/level_2.tscn")
	else:
		get_tree().change_scene_to_file("res://scenes/level_2.tscn")

func _on_area_entered(area: Node2D) -> void:
	# Optional: Handle area overlaps if the player uses an Area2D for detection
	if area.get_parent().is_in_group("player"):
		_on_body_entered(area.get_parent())
