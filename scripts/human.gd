extends CharacterBody2D

const SPEED = 100.0
const ACCELERATION = 1000.0
const FRICTION = 800.0

@onready var animated_sprite = $AnimatedSprite2D
@onready var dialog_label = $Label
@onready var health_bar = $ProgressBar

var last_direction = Vector2.DOWN  # Track last direction for idle animation
var is_saying_dialog = false  # Flag for when human is speaking

# Roaming behavior variables
var roam_direction = Vector2.ZERO
var roam_timer = 0.0

var roam_change_interval = 2.0  # Change direction every 2 seconds

# Health System
var max_health = 50.0
var current_health = 50.0

# Particle Settings
@export var blood_color: Color = Color(0.8, 0.0, 0.0) # Red
@export var blood_amount: int = 16
@export var blood_scale_min: float = 2.0
@export var blood_scale_max: float = 4.0

# Dialogue Options
var dialogues = [
	"Leave me alone!", 
	"Stay back!", 
	"Help me!", 
	"Is that... blood?",
	"Did you hear that?",
	"I want to go home...",
	"radhe radhe",
	"jai hanuman gyan gun sagar",
	"@#!#$@#"
]

func _ready():
	# Initialize random roaming direction
	# Initialize random roaming direction
	_change_roam_direction()
	
	add_to_group("human")
	
	# Hide dialog label at start
	if dialog_label:
		dialog_label.visible = false
	
	# Initialize health bar
	if health_bar:
		health_bar.max_value = max_health
		health_bar.value = current_health

func _physics_process(delta: float) -> void:
	var input_direction = Vector2.ZERO
	
	# If saying dialog, don't move
	if is_saying_dialog:
		velocity = Vector2.ZERO
		play_idle_animation()
		move_and_slide()
		return
	
	# Roam randomly
	roam_timer -= delta
	if roam_timer <= 0:
		_change_roam_direction()
	input_direction = roam_direction
	if input_direction.length() > 0.1:
		last_direction = input_direction
	
	# Apply movement with acceleration
	if input_direction.length() > 0.1:
		velocity = velocity.move_toward(input_direction * SPEED, ACCELERATION * delta)
		play_movement_animation(input_direction)
	else:
		# Apply friction when no input
		velocity = velocity.move_toward(Vector2.ZERO, FRICTION * delta)
		play_idle_animation()
	
	move_and_slide()

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

# Called by player when zone is activated and this human is inside
func react_to_zone(_player):
	if is_saying_dialog:
		return  # Already reacting
	
	print("Human: Reacting to zone!")
	is_saying_dialog = true
	
	# Stop moving and play idle animation
	velocity = Vector2.ZERO
	play_idle_animation()
	
	# Say dialog
	var text = dialogues.pick_random()
	say_dialog(text)
	
	# Wait for dialog duration then resume roaming
	await get_tree().create_timer(2.0).timeout
	is_saying_dialog = false
	_change_roam_direction()
	print("Human: Resuming roaming")

func say_dialog(text: String):
	print("Human says: ", text)
	if dialog_label:
		dialog_label.text = text
		dialog_label.visible = true
		await get_tree().create_timer(1.5).timeout
		dialog_label.visible = false

# Alias for compatibility with player zone detection
func transform_to_zombie(player):
	react_to_zone(player)

	# Human doesn't transform, just stop dialog if active


func take_damage(damage: float):
	current_health -= damage
	print("Human: Took ", damage, " damage. Health: ", current_health, "/", max_health)
	
	# Spawn Red Blood
	# Spawn Red Blood
	var blood = load("res://scenes/blood_particles.tscn").instantiate()
	blood.color = blood_color
	blood.amount = blood_amount
	blood.scale_amount_min = blood_scale_min
	blood.scale_amount_max = blood_scale_max
	blood.z_index = 5
	get_tree().current_scene.add_child(blood)
	blood.global_position = global_position
	blood.emitting = true
	
	if health_bar:
		health_bar.value = current_health
	
	say_dialog("Ouch! Stop it!")
	
	if current_health <= 0:
		die()

func die():
	print("Human: Died! GAME OVER!")
	
	Global.game_over_message = "GAME OVER\nYOU KILLED A CITIZEN"
	get_tree().change_scene_to_file("res://scenes/end_secene.tscn")
	queue_free()

func play_movement_animation(direction: Vector2):
	# 8-directional movement with better thresholds
	var angle = atan2(direction.y, direction.x)
	var degrees = rad_to_deg(angle)
	
	# Normalize to 0-360
	if degrees < 0:
		degrees += 360
	
	# Determine animation based on angle
	if degrees >= 337.5 or degrees < 22.5:  # Right
		animated_sprite.play("right")
	elif degrees >= 22.5 and degrees < 67.5:  # Right-Down
		animated_sprite.play("right_down")
	elif degrees >= 67.5 and degrees < 112.5:  # Down
		animated_sprite.play("down")
	elif degrees >= 112.5 and degrees < 157.5:  # Left-Down
		animated_sprite.play("left_down")
	elif degrees >= 157.5 and degrees < 202.5:  # Left
		animated_sprite.play("left")
	elif degrees >= 202.5 and degrees < 247.5:  # Left-Up
		animated_sprite.play("left_up")
	elif degrees >= 247.5 and degrees < 292.5:  # Up
		animated_sprite.play("up")
	elif degrees >= 292.5 and degrees < 337.5:  # Right-Up
		animated_sprite.play("right_up")

func play_idle_animation():
	# Get the last direction from current animation
	var current_anim = animated_sprite.animation
	
	# Extract direction from current animation
	if "right_up" in current_anim:
		animated_sprite.play("idle_right_up")
	elif "right_down" in current_anim:
		animated_sprite.play("idle_right_down")
	elif "right" in current_anim:
		animated_sprite.play("idle_right")
	elif "left_up" in current_anim:
		animated_sprite.play("idle_left_up")
	elif "left_down" in current_anim:
		animated_sprite.play("idle_left_down")
	elif "left" in current_anim:
		animated_sprite.play("idle_left")
	elif "up" in current_anim:
		animated_sprite.play("idle_up")
	elif "down" in current_anim:
		animated_sprite.play("idle_down")
	else:
		# Default idle animation
		animated_sprite.play("idle_down")
