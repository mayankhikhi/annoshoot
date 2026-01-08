extends Area2D

@export var speed: float = 500.0
var direction: Vector2 = Vector2.ZERO
var target_position: Vector2 = Vector2.ZERO
var start_position: Vector2 = Vector2.ZERO
var target_distance: float = 0.0
var traveled_distance: float = 0.0
var is_active: bool = false

func _ready():
	body_entered.connect(_on_body_entered)
	$Timer.timeout.connect(_on_timer_timeout)

func _setup_target():
	start_position = global_position
	target_distance = start_position.distance_to(target_position)
	if target_distance < 1.0:
		target_distance = 1.0  # Prevent instant destruction if clicking on player
	rotation = direction.angle()
	is_active = true

func _physics_process(delta: float) -> void:
	if not is_active:
		return
	
	var move_amount = speed * delta
	traveled_distance += move_amount
	
	# Check if we've reached or passed the target
	if traveled_distance >= target_distance:
		global_position = target_position
		queue_free()
	else:
		# Use global_position for world-space movement
		global_position += direction * move_amount

func _on_body_entered(body: Node2D):
	# Ignore the player who shot the bullet
	if body.name == "Player" or body.is_in_group("player"):
		return
	
	# Only process enemy or human hits
	if body.is_in_group("enemy") or body.is_in_group("human"):
		if body.has_method("take_damage"):
			body.take_damage(25)  # Deal 25 damage per bullet hit
		else:
			body.queue_free()  # Fallback if enemy doesn't have take_damage method
		queue_free()  # Destroy bullet after hitting enemy

func _on_timer_timeout():
	queue_free()
