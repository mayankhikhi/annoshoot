extends Node

var zombie_scene = preload("res://scenes/emeny.tscn")
var human_scene = preload("res://scenes/human.tscn")

@export var max_zombies = 10
@export var max_humans = 10
var current_zombies_spawned = 0
var current_humans_spawned = 0

# Fixed spawn points will now be fetched from child nodes (Marker2D)
var spawn_points: Array = []

var spawn_timer = 0.0
var spawn_interval = 2.0 # Starts at 2.0 seconds
var player_node: Node2D

func _ready():
	randomize()
	Global.zombies_remaining = max_zombies # Set the level goal dynamically
	
	# Try to find player by group first (best practice)
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player_node = players[0]
	else:
		# Fallback to naming convention
		player_node = get_parent().get_node_or_null("player")
		if not player_node:
			player_node = get_parent().get_node_or_null("Player")
	
	if not player_node:
		print("Spawner: Player not found!")
		
	# Find all Marker2D children to use as spawn points
	for child in get_children():
		if child is Marker2D:
			spawn_points.append(child)
			
	if spawn_points.size() == 0:
		print("Spawner: No Marker2D children found! Please add them in the editor.")

func _process(delta):
	if current_zombies_spawned >= max_zombies and current_humans_spawned >= max_humans:
		return # All spawned
	
	spawn_timer += delta
	if spawn_timer >= spawn_interval:
		spawn_timer = 0.0
		_attempt_spawn()
		_update_spawn_interval()

func _update_spawn_interval():
	# Gradually decrease from 2.0 to 1.0 as we spawn more
	var total_spawned = current_zombies_spawned + current_humans_spawned
	var progress = float(total_spawned) / (max_zombies + max_humans)
	spawn_interval = lerp(2.0, 1.0, progress)
	# print("Spawner: Next interval: ", spawn_interval)

func _attempt_spawn():
	if not player_node: return
	if spawn_points.size() == 0: return # Safety check
	
	# Decide what to spawn
	var spawn_zombie = false
	if current_zombies_spawned < max_zombies and current_humans_spawned < max_humans:
		spawn_zombie = randf() > 0.5 # 50/50 chance
	elif current_zombies_spawned < max_zombies:
		spawn_zombie = true
	elif current_humans_spawned < max_humans:
		spawn_zombie = false
	else:
		return
	
	# Pick a random spawn point node
	var random_point_node = spawn_points.pick_random()
	
	# Get global position from the node
	var spawn_pos = random_point_node.global_position
	
	if spawn_zombie:
		_spawn_zombie(spawn_pos)
	else:
		_spawn_human(spawn_pos)

func _spawn_zombie(pos):
	var enemy = zombie_scene.instantiate()
	
	# Add to scene FIRST so global_position works correctly with parent rotation
	get_parent().add_child(enemy)
	
	enemy.global_position = pos
	enemy.rotation = player_node.rotation # Match player rotation
	enemy.is_part_of_wave = true 
	enemy.visible = true # Ensure visible
	
	# Ensure proper collision (Layer 1=Walls, 2=Player)
	enemy.collision_layer = 3
	enemy.collision_mask = 3
	
	current_zombies_spawned += 1

func _spawn_human(pos):
	var human = human_scene.instantiate()
	
	# Add to scene FIRST so global_position works correctly with parent rotation
	get_parent().add_child(human)
	
	human.global_position = pos
	human.rotation = player_node.rotation # Match player rotation
	
	# Ensure proper collision
	human.collision_layer = 3
	human.collision_mask = 3
	
	current_humans_spawned += 1
