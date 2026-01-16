extends CharacterBody2D

const SPEED = 100.0
const ZOMBIE_SPEED = 100.0  # Faster when chasing as zombie
const ACCELERATION = 1000.0
const FRICTION = 800.0

@onready var animated_sprite = $AnimatedSprite2D
@onready var health_bar = $ProgressBar  # Reference to the health bar

var max_health = 100.0
var current_health = 100.0

var transformed = false  # Enemy starts normal, becomes zombie when in player's zone
var player_reference = null
var is_transforming = false  # Flag for playing transformation/idle animation once
var last_direction = Vector2.DOWN  # Track last direction for zombie_idle animation

# Roaming behavior variables
var roam_direction = Vector2.ZERO
var roam_timer = 0.0
var roam_change_interval = 2.0  # Change direction every 2 seconds
var is_part_of_wave = false # If true, this enemy counts towards a wave and shouldn't auto-increment global counter on spawn

# Particle Settings
@export var blood_color: Color = Color(0.0, 0.4, 0.0) # Dark Green
@export var blood_amount: int = 16
@export var blood_scale_min: float = 2.0
@export var blood_scale_max: float = 4.0


func _ready():
	# Connect animation finished signal for transformation sequence
	animated_sprite.animation_finished.connect(_on_animation_finished)
	
	add_to_group("enemy")
	
	# Initialize health bar
	if health_bar:
		health_bar.max_value = max_health
		health_bar.value = current_health
	
	# Initialize random roaming direction
	_change_roam_direction()
	
	add_to_group("enemy") # Ensure it's in the group for counting
	# if not is_part_of_wave:
	# 	Global.zombies_remaining += 1 # Register self if pre-placed



func _physics_process(delta: float) -> void:
	var input_direction = Vector2.ZERO
	
	# If transforming, don't move - wait for idle animation to finish
	if is_transforming:
		velocity = Vector2.ZERO
		move_and_slide()
		return
	
	if transformed and player_reference != null:
		# Chase the player as zombie
		var direction_to_player = player_reference.global_position - global_position
		input_direction = direction_to_player.normalized()
		last_direction = input_direction
	else:
		# Roam randomly
		roam_timer -= delta
		if roam_timer <= 0:
			_change_roam_direction()
		input_direction = roam_direction
		if input_direction.length() > 0.1:
			last_direction = input_direction
	
	# Choose speed based on transformation state
	var current_speed = ZOMBIE_SPEED if transformed else SPEED
	
	# Apply movement with acceleration
	if input_direction.length() > 0.1:
		velocity = velocity.move_toward(input_direction * current_speed, ACCELERATION * delta)
		play_movement_animation(input_direction)
	else:
		# Apply friction when no input
		velocity = velocity.move_toward(Vector2.ZERO, FRICTION * delta)
		play_idle_animation()
	
	move_and_slide()
	
	# If roaming and collided, change direction
	if not transformed and get_slide_collision_count() > 0:
		_change_roam_direction()

func _change_roam_direction():
	# Reset timer
	roam_timer = roam_change_interval
	
	# Randomly decide to move or stay idle
	if randf() < 0.7:  # 70% chance to move
		# Generate random direction
		var angle = randf() * TAU  # Random angle in radians
		roam_direction = Vector2(cos(angle), sin(angle))
	else:
		# Stay idle
		roam_direction = Vector2.ZERO

# Called by player when zone is activated and this enemy is inside
func transform_to_zombie(player):
	if transformed:
		return  # Already transformed
	
	print("Enemy: Transforming to zombie!")
	player_reference = player
	transformed = true
	is_transforming = true
	
	# Play zombie_idle animation once based on last direction
	var idle_anim = _get_zombie_idle_animation_name()
	print("Enemy: Playing transformation animation: ", idle_anim)
	
	# Check if animation exists
	if animated_sprite.sprite_frames.has_animation(idle_anim):
		animated_sprite.play(idle_anim)
		# Wait for the transformation animation to finish
		await get_tree().create_timer(0.5).timeout
		is_transforming = false
		print("Enemy: Transformation complete, now chasing!")
	else:
		print("Enemy: Animation not found, skipping transformation animation")
		is_transforming = false

# Called by player when zone is deactivated
func transform_to_normal():
	if not transformed:
		return  # Already normal
	
	print("Enemy: Reverting to normal!")
	player_reference = null
	transformed = false
	is_transforming = false

func _on_animation_finished():
	# Check if we just finished playing a zombie_idle animation
	if is_transforming and "zombie_idle_" in animated_sprite.animation:
		is_transforming = false
		print("Enemy: Transformation complete, now chasing!")

func _get_zombie_idle_animation_name() -> String:
	# Determine the zombie_idle animation based on last direction
	var angle = atan2(last_direction.y, last_direction.x)
	var degrees = rad_to_deg(angle)
	
	if degrees < 0:
		degrees += 360
	
	if degrees >= 337.5 or degrees < 22.5:
		return "zombie_idle_right"
	elif degrees >= 22.5 and degrees < 67.5:
		return "zombie_idle_right_down"
	elif degrees >= 67.5 and degrees < 112.5:
		return "zombie_idle_down"
	elif degrees >= 112.5 and degrees < 157.5:
		return "zombie_idle_left_down"
	elif degrees >= 157.5 and degrees < 202.5:
		return "zombie_idle_left"
	elif degrees >= 202.5 and degrees < 247.5:
		return "zombie_idle_left_up"
	elif degrees >= 247.5 and degrees < 292.5:
		return "zombie_idle_up"
	elif degrees >= 292.5 and degrees < 337.5:
		return "zombie_idle_right_up"
	
	return "zombie_idle_down"

func take_damage(damage: float):
	current_health -= damage
	print("Enemy: Took ", damage, " damage. Health: ", current_health, "/", max_health)
	
	# Spawn Dark Green Blood
	var blood = load("res://scenes/blood_particles.tscn").instantiate()
	blood.color = blood_color
	blood.amount = blood_amount
	blood.scale_amount_min = blood_scale_min
	blood.scale_amount_max = blood_scale_max
	blood.z_index = 5 # Ensure it appears on top
	get_tree().current_scene.add_child(blood)
	blood.global_position = global_position
	blood.emitting = true
	
	# Update health bar
	if health_bar:
		health_bar.value = current_health
	
	# Check if enemy is dead
	if current_health <= 0:
		die()

func die():
	print("Enemy: Died!")
	Global.coins += 10
	Global.zombies_remaining -= 1
	print("Global: Coins: ", Global.coins, " Zombies Left: ", Global.zombies_remaining)
	call_deferred("queue_free")

func play_movement_animation(direction: Vector2):
	var prefix = "zombie_" if transformed else ""
	
	# 8-directional movement with better thresholds
	var angle = atan2(direction.y, direction.x)
	var degrees = rad_to_deg(angle)
	
	# Normalize to 0-360
	if degrees < 0:
		degrees += 360
	
	# Determine animation based on angle
	if degrees >= 337.5 or degrees < 22.5:  # Right
		animated_sprite.play(prefix + "right")
	elif degrees >= 22.5 and degrees < 67.5:  # Right-Down
		animated_sprite.play(prefix + "right_down")
	elif degrees >= 67.5 and degrees < 112.5:  # Down
		animated_sprite.play(prefix + "down")
	elif degrees >= 112.5 and degrees < 157.5:  # Left-Down
		animated_sprite.play(prefix + "left_down")
	elif degrees >= 157.5 and degrees < 202.5:  # Left
		animated_sprite.play(prefix + "left")
	elif degrees >= 202.5 and degrees < 247.5:  # Left-Up
		animated_sprite.play(prefix + "left_up")
	elif degrees >= 247.5 and degrees < 292.5:  # Up
		animated_sprite.play(prefix + "up")
	elif degrees >= 292.5 and degrees < 337.5:  # Right-Up
		animated_sprite.play(prefix + "right_up")

func play_idle_animation():
	# Get the last direction from current animation
	var current_anim = animated_sprite.animation
	var prefix = "zombie_" if transformed else ""
	
	# Extract direction from current animation
	if "right_up" in current_anim:
		animated_sprite.play(prefix + "idle_right_up")
	elif "right_down" in current_anim:
		animated_sprite.play(prefix + "idle_right_down")
	elif "right" in current_anim:
		animated_sprite.play(prefix + "idle_right")
	elif "left_up" in current_anim:
		animated_sprite.play(prefix + "idle_left_up")
	elif "left_down" in current_anim:
		animated_sprite.play(prefix + "idle_left_down")
	elif "left" in current_anim:
		animated_sprite.play(prefix + "idle_left")
	elif "up" in current_anim:
		animated_sprite.play(prefix + "idle_up")
	elif "down" in current_anim:
		animated_sprite.play(prefix + "idle_down")
	else:
		# Default idle animation
		animated_sprite.play(prefix + "idle_down")
