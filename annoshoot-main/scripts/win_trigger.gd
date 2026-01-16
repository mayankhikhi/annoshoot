extends Area2D

func _ready():
	monitoring = true
	body_entered.connect(_on_body_entered)
	print("WinTrigger: Ready at ", global_position)

func _on_body_entered(body):
	print("WinTrigger: Body entered -> ", body.name)
	if body.name == "Player" or body.is_in_group("player"):
		print("WinTrigger: Player detected. Zombies Remaining: ", Global.zombies_remaining)
		if Global.zombies_remaining <= 0:
			call_deferred("win_game")
		else:
			print("WinTrigger: Cannot exit yet. Zombies detected.")

func win_game():
	print("Player: Level 2 Complete - YOU WIN!")
	get_tree().change_scene_to_file("res://scenes/win_scene.tscn")
