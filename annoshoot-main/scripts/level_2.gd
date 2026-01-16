extends Node2D

@onready var player = $Player
@onready var lift_entry = $LiftEntry

func _ready():
	# Wait one frame to ensure positions are ready
	await get_tree().process_frame
	
	if player and lift_entry:
		print("Level 2: Teleporting player below lift")
		# Position player 50 pixels below the lift (reduced from 80)
		player.global_position = lift_entry.global_position + Vector2(0, 50)
		
		# Disable lift interaction in Level 2 so it doesn't reload the scene
		if lift_entry.has_node("Area2D"):
			var area = lift_entry.get_node("Area2D")
			area.monitoring = false
			area.monitorable = false
			print("Level 2: Lift disabled")
	else:
		print("Level 2: Player or LiftEntry not found")
