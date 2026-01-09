extends CharacterBody2D

const SPEED = 150.0
const ACCELERATION = 1000.0
const FRICTION = 800.0

# ### ADDED: Knockback settings
const KNOCKBACK_FORCE = 100.0
const KNOCKBACK_DECAY = 1000.0 # How fast the knockback stops
var knockback_vector = Vector2.ZERO
const ZONE_RADIUS = 300.0 # Radius for demon circle detection

@onready var animated_sprite = $AnimatedSprite2D
@onready var zone_area = $Area2D
@onready var zone_animation = $Area2D/AnimatedSprite2D
@onready var health_bar = $ProgressBar

var coin_label: Label
var ammo_label: Label
var enemy_label: Label
var demon_label: Label # Added for demon circle counter
var lift_label: Label # Added for lift message
var kill_all_label: Label # Added for kill all message
var go_to_lift_label: Label # Added for go to lift message
var fade_overlay: ColorRect # Added for transition
var lift_area: Area2D
var can_enter_lift = false

var max_health = 100.0
var current_health = 100.0
var can_take_damage = true
var damage_cooldown = 1.0

# Shooting Cooldown
const SHOOT_COOLDOWN = 0.5
var can_shoot = true

var weapon_equipped = false
var zone_active = false
var transformed_enemies: Array = []
var is_aiming = false
var last_direction = "down"

# Ammo System
var max_ammo = 6
var current_ammo = 6
var magazines = 5 # Starts with 5 magazines
var is_reloading = false
var reload_time = 1.0

# Shop System
var shop_open = false
var shop_panel: ColorRect
var shop_button: Button
var mag_button: Button
var blood_button: Button

# Zone Duration
var zone_duration = 3.0
var zone_timer = 0.0
var demon_circle_uses = 3
var max_demon_circle_uses = 5 # Increased max to 5
var game_started_safe = false

# Audio
var shoot_sound_player: AudioStreamPlayer
var reload_sound_player: AudioStreamPlayer

# Camera
@onready var camera = $Camera2D
var shake_intensity = 0.0
var shake_decay = 5.0


func _ready():
	add_to_group("player")
	
	if health_bar:
		health_bar.max_value = max_health
		health_bar.value = current_health
		health_bar.visible = true
		health_bar.show_percentage = false
		
		var style_bg = StyleBoxFlat.new()
		style_bg.bg_color = Color(0.2, 0.2, 0.2, 0.8)
		health_bar.add_theme_stylebox_override("background", style_bg)
		
		var style_fg = StyleBoxFlat.new()
		style_fg.bg_color = Color(0.0, 1.0, 0.0, 1.0)
		health_bar.add_theme_stylebox_override("fill", style_fg)
	else:
		print("ERROR: Health bar (ProgressBar) not found!")
	
	if zone_area:
		zone_area.monitoring = false
		zone_area.monitorable = false
		if zone_animation:
			zone_animation.visible = false
		zone_area.body_entered.connect(_on_zone_body_entered)
		zone_area.body_exited.connect(_on_zone_body_exited)
	
	setup_coin_ui()
	setup_shop_ui() # Initialize Shop UI
	setup_audio()
	setup_lift() # Setup lift logic
	# Global.zombies_remaining = 0 # REMOVED: Managed by Spawner now
	
	# Load Persistent Stats
	magazines = Global.magazines
	current_ammo = Global.current_ammo
	demon_circle_uses = Global.demon_circle_uses
	current_health = Global.current_health
	# max_health = Global.max_health # Optional if max health changes
	
	if health_bar:
		health_bar.value = current_health

	# Start fade in
	fade_in_scene()
	update_ui() # Ensure UI reflects loaded stats immediately
	
	if camera:
		camera.top_level = true
		camera.global_position = global_position

	
	await get_tree().create_timer(0.5).timeout
	game_started_safe = true


func setup_coin_ui():
	var canvas_layer = CanvasLayer.new()
	add_child(canvas_layer)
	
	# Spooky Overlay (Vignette)
	var spooky_overlay = ColorRect.new()
	spooky_overlay.color = Color(0.102, 0.11, 0.173) # Set default color to match shader to prevent white flash
	spooky_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	spooky_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var shader = Shader.new()
	shader.code = """
		shader_type canvas_item;
		
		void fragment() {
			vec3 color_rgb = vec3(0.102, 0.11, 0.173); // #1a1c2c
			float dist = distance(UV, vec2(0.5, 0.5));
			// Center alpha 0.6, Edge alpha 0.7
			float alpha = mix(0.6, 0.7, smoothstep(0.0, 0.5, dist));
			COLOR = vec4(color_rgb, alpha);
		}
	"""
	var shader_material = ShaderMaterial.new()
	shader_material.shader = shader
	spooky_overlay.material = shader_material
	
	canvas_layer.add_child(spooky_overlay)
	
	coin_label = Label.new()
	coin_label.position = Vector2(20, 20)
	coin_label.add_theme_font_size_override("font_size", 24)
	coin_label.modulate = Color(1, 1, 0)
	canvas_layer.add_child(coin_label)
	
	ammo_label = Label.new()
	ammo_label.position = Vector2(20, 50)
	ammo_label.add_theme_font_size_override("font_size", 24)
	ammo_label.modulate = Color(1, 1, 1)
	canvas_layer.add_child(ammo_label)
	
	enemy_label = Label.new()
	enemy_label.position = Vector2(20, 80)
	enemy_label.add_theme_font_size_override("font_size", 24)
	enemy_label.modulate = Color(1, 0, 0)
	enemy_label.modulate = Color(1, 0, 0)
	canvas_layer.add_child(enemy_label)
	
	demon_label = Label.new()
	demon_label.position = Vector2(20, 110) # "Arranged" below Enemy
	demon_label.add_theme_font_size_override("font_size", 24)
	demon_label.modulate = Color(1, 0, 0) # Red color
	canvas_layer.add_child(demon_label)
	
	lift_label = Label.new()
	lift_label.text = "Press F to enter lift"
	lift_label.position = Vector2(400, 300) # Center-ish? Better logic needed but fixed for now
	lift_label.add_theme_font_size_override("font_size", 32)
	lift_label.modulate = Color(0, 1, 0)
	lift_label.visible = false
	lift_label.set_anchors_preset(Control.PRESET_CENTER)
	canvas_layer.add_child(lift_label)
	
	kill_all_label = Label.new()
	kill_all_label.text = "Kill all zombies first!"
	kill_all_label.position = Vector2(300, 20)
	kill_all_label.add_theme_font_size_override("font_size", 24)
	kill_all_label.modulate = Color(1, 0, 0)
	kill_all_label.visible = false
	# kill_all_label.set_anchors_preset(Control.PRESET_CENTER)
	canvas_layer.add_child(kill_all_label)
	
	go_to_lift_label = Label.new()
	if get_tree().current_scene.name == "Level2":
		go_to_lift_label.text = "GO TO THE STAIRS!"
	else:
		go_to_lift_label.text = "GO TO THE LIFT!"
	go_to_lift_label.position = Vector2(300, 20)
	go_to_lift_label.add_theme_font_size_override("font_size", 24)
	go_to_lift_label.modulate = Color(1, 1, 0) # Yellow
	go_to_lift_label.visible = false
	# go_to_lift_label.set_anchors_preset(Control.PRESET_CENTER)
	canvas_layer.add_child(go_to_lift_label)
	
	# Transition Overlay
	fade_overlay = ColorRect.new()
	fade_overlay.color = Color(0, 0, 0, 0) # Start transparent
	fade_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	fade_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas_layer.add_child(fade_overlay)
	
	update_ui()

func setup_shop_ui():
	# Look for the "UI" CanvasLayer which should be a sibling of the player in game.tscn
	var ui_layer = get_parent().get_node_or_null("UI")
	
	if not ui_layer:
		print("Player: UI layer not found in parent!")
		return

	# Find nodes
	shop_button = ui_layer.get_node_or_null("ShopButton")
	shop_panel = ui_layer.get_node_or_null("ShopPanel")
	
	if not shop_button or not shop_panel:
		print("Player: Shop UI nodes missing in UI layer!")
		return
		
	# Connect Button Signal
	if not shop_button.pressed.is_connected(_on_shop_button_pressed):
		shop_button.pressed.connect(_on_shop_button_pressed)
	
	# Fix Shop Button Position (Below text stats)
	if shop_button:
		shop_button.position = Vector2(20, 150)
	
	# Find Panel Buttons
	mag_button = shop_panel.get_node_or_null("BuyMagButton")
	blood_button = shop_panel.get_node_or_null("BuyBloodButton")
	var close_btn = shop_panel.get_node_or_null("CloseButton")
	
	if mag_button and not mag_button.pressed.is_connected(_on_buy_mag_pressed):
		mag_button.pressed.connect(_on_buy_mag_pressed)
		
	if blood_button and not blood_button.pressed.is_connected(_on_buy_blood_pressed):
		blood_button.pressed.connect(_on_buy_blood_pressed)
		
	if close_btn and not close_btn.pressed.is_connected(_on_shop_button_pressed):
		close_btn.pressed.connect(_on_shop_button_pressed)
		
	# Add Health Pack Button Programmatically
	var health_button = Button.new()
	health_button.text = "Health Pack (20)"
	shop_panel.add_child(health_button)
	health_button.pressed.connect(_on_buy_health_pressed)
	
	# Style matches Blood Button if possible
	if blood_button:
		health_button.size = blood_button.size
		health_button.position = Vector2(blood_button.position.x, blood_button.position.y + blood_button.size.y + 10)
	else:
		health_button.position = Vector2(20, 200) # Fallback
	
	# Add Increase Damage Button
	var damage_button = Button.new()
	damage_button.text = "Increase Damage (50)"
	shop_panel.add_child(damage_button)
	damage_button.pressed.connect(_on_buy_damage_pressed)
	
	# Style matches Health Button
	damage_button.size = health_button.size
	damage_button.position = Vector2(health_button.position.x, health_button.position.y + health_button.size.y + 10)
	
	if Global.has_damage_upgrade:
		damage_button.disabled = true
		damage_button.text = "Increase Damage (SOLD OUT)"
	
	# Reposition Close Button
	if close_btn:
		close_btn.position = Vector2(damage_button.position.x, damage_button.position.y + damage_button.size.y + 10)

		
		# Resize Panel to fit content
		var required_height = close_btn.position.y + close_btn.size.y + 30
		if shop_panel.size.y < required_height:
			shop_panel.size.y = required_height


func _on_shop_button_pressed():
	shop_open = !shop_open
	
	if shop_panel:
		var tween = create_tween()
		if shop_open:
			shop_panel.visible = true
			shop_panel.modulate.a = 0.0
			tween.tween_property(shop_panel, "modulate:a", 1.0, 0.3)
		else:
			tween.tween_property(shop_panel, "modulate:a", 0.0, 0.3)
			await tween.finished
			shop_panel.visible = false

func _on_buy_mag_pressed():
	if Global.coins >= 5:
		Global.coins -= 5
		magazines += 1
		Global.magazines = magazines # Sync
		update_ui()
		# Optional: Play sound
	else:
		print("Not enough coins!")

func _on_buy_blood_pressed():
	if Global.coins >= 5:
		if demon_circle_uses < max_demon_circle_uses:
			Global.coins -= 5
			demon_circle_uses += 1
			Global.demon_circle_uses = demon_circle_uses # Sync
			update_ui()
		else:
			print("Demon Circle full!")
	else:
		print("Not enough coins!")

func _on_buy_health_pressed():
	if Global.coins >= 20:
		if current_health < max_health:
			Global.coins -= 20
			var heal_amount = max_health * 0.5
			current_health = min(current_health + heal_amount, max_health)
			Global.current_health = current_health # Sync
			if health_bar: health_bar.value = current_health
			print("Player: Healed! Health: ", current_health)
			update_ui()
		else:
			print("Health already full!")
	else:
		print("Not enough coins!")

func _on_buy_damage_pressed():
	if Global.has_damage_upgrade:
		print("Already purchased damage upgrade!")
		return

	if Global.coins >= 50:
		Global.coins -= 50
		Global.has_damage_upgrade = true
		update_ui()
		
		# Find the button and update it
		if shop_panel:
			for child in shop_panel.get_children():
				if child is Button and "Increase Damage" in child.text:
					child.disabled = true
					child.text = "Increase Damage (SOLD OUT)"
		print("Player: Bought Damage Upgrade!")
	else:
		print("Not enough coins!")

func transition_to_scene(target_path: String):
	if fade_overlay:
		var tween = get_tree().create_tween()
		tween.tween_property(fade_overlay, "color:a", 1.0, 1.0)
		await tween.finished
	get_tree().change_scene_to_file(target_path)

func fade_in_scene():
	if fade_overlay:
		fade_overlay.color.a = 1.0 # Start fully black if just loaded
		var tween = get_tree().create_tween()
		tween.tween_property(fade_overlay, "color:a", 0.0, 1.0)

func update_ui():
	if coin_label:
		coin_label.text = "Coins: " + str(Global.coins)
	if ammo_label:
		ammo_label.text = "Ammo: " + str(current_ammo) + "/" + str(max_ammo) + " | Mags: " + str(magazines)
	if enemy_label:
		enemy_label.text = "Enemies Left: " + str(Global.zombies_remaining)
	if demon_label:
		demon_label.text = "Demon Circles: " + str(demon_circle_uses) + "/" + str(max_demon_circle_uses)
		
	if game_started_safe and Global.zombies_remaining <= 0:
		if go_to_lift_label:
			if not has_meta("lift_message_shown"):
				set_meta("lift_message_shown", true)
				go_to_lift_label.visible = true
				get_tree().create_timer(3.0).timeout.connect(func(): if go_to_lift_label: go_to_lift_label.visible = false)

func show_win_screen():
	if Global.zombies_remaining > 0: return
	Global.game_over_message = "YOU WIN!\nALL ZOMBIES ELIMINATED"
	transition_to_scene("res://scenes/end_secene.tscn")

func handle_debug_input():
	if Input.is_key_pressed(KEY_G):
		print("DEBUG: Kill All Zombies triggered!")
		get_tree().call_group("enemy", "die")


func setup_audio():
	shoot_sound_player = AudioStreamPlayer.new()
	shoot_sound_player.stream = load("res://sounds/gun_shots.mp3")
	shoot_sound_player.volume_db = -5.0 
	shoot_sound_player.bus = "SFX"
	add_child(shoot_sound_player)
	
	reload_sound_player = AudioStreamPlayer.new()
	reload_sound_player.stream = load("res://sounds/gun_reload.mp3")
	reload_sound_player.volume_db = -2.0
	reload_sound_player.bus = "SFX"
	add_child(reload_sound_player)

func setup_lift():
	var lift_node = get_parent().find_child("lift entry", true, false)
	
	if lift_node:
		print("Player: FOUND 'lift entry' node.")
		var parent = lift_node.get_parent()
		
		# Check if the user already wrapped this in an Area2D (which seems to be the case now)
		if parent is Area2D:
			print("Player: 'lift entry' parent is an Area2D. Using existing Area2D.")
			lift_area = parent
			
			# Configure the existing Area2D to ensure it works
			lift_area.monitoring = true
			lift_area.monitorable = true
			lift_area.collision_layer = 0
			lift_area.collision_mask = 0xFFFFFFFF # Detect everything
			
			# Connect signals if not already connected to THIS script
			if not lift_area.body_entered.is_connected(_on_lift_body_entered):
				lift_area.body_entered.connect(_on_lift_body_entered)
			if not lift_area.body_exited.is_connected(_on_lift_body_exited):
				lift_area.body_exited.connect(_on_lift_body_exited)
				
			# Debug: print what it overlaps right now
			print("Player: Existing Area2D overlaps: ", lift_area.get_overlapping_bodies())
			
		elif lift_node is CollisionShape2D:
			print("Player: 'lift entry' is a standalone collision shape. Creating wrapper Area2D.")
			# Old logic: Create Area2D on top of it
			var shape = lift_node.shape
			var global_pos = lift_node.global_position
			
			lift_area = Area2D.new()
			lift_area.name = "LiftArea_Dynamic"
			lift_area.global_position = global_pos
			lift_area.scale = Vector2(2.0, 4.0) 
			lift_area.monitoring = true
			lift_area.monitorable = true
			lift_area.collision_layer = 0 
			lift_area.collision_mask = 0xFFFFFFFF 
			
			var collision_shape = CollisionShape2D.new()
			collision_shape.shape = shape 
			lift_area.add_child(collision_shape)
			
			get_parent().call_deferred("add_child", lift_area) 
			
			lift_area.body_entered.connect(_on_lift_body_entered)
			lift_area.body_exited.connect(_on_lift_body_exited)
			
	else:
		print("Player: CRITICAL - 'lift entry' node NOT FOUND in the scene tree!")

func _on_lift_body_entered(body):
	print("Lift Area Entered by: ", body.name)
	if body == self or body.name == "player" or body.is_in_group("player"):
		print("Player: Entered Lift Area (Verified)")
		
		# Immediate transition logic
		if Global.zombies_remaining <= 0:
			# Progress to next level
			print("Player: Entering lift - Level Completed!")
			call_deferred("transition_to_scene", "res://scenes/level_2.tscn")
		else:
			# Show warning
			print("Player: Cannot enter lift - Eliminate all zombies!")
			if kill_all_label:
				kill_all_label.visible = true
			
			# We don't hide it immediately here, maybe let it stay while in zone?
			# simpler to just show it. user will leave zone to kill more.
			can_enter_lift = true

func _on_lift_body_exited(body):
	if body == self or body.name == "player" or body.is_in_group("player"):
		print("Player: Exited Lift Area (Verified)")
		can_enter_lift = false
		if lift_label: lift_label.visible = false
		if kill_all_label: kill_all_label.visible = false

func _physics_process(delta: float) -> void:
	# Fallback: Manual check if signal fails
	if lift_area and is_instance_valid(lift_area):
		var bodies = lift_area.get_overlapping_bodies()
		var player_in_zone = false
		for body in bodies:
			if body == self:
				player_in_zone = true
				break
		
		if player_in_zone:
			# If we are in the zone, we might need to re-trigger logic if it didn't trigger
			# Or if we just killed the last zombie while standing in the lift?
			if Global.zombies_remaining <= 0:
				# Check if we should transition (maybe user was waiting in lift)
				call_deferred("transition_to_scene", "res://scenes/level_2.tscn")
			else:
				if kill_all_label: kill_all_label.visible = true
				
		elif not player_in_zone:
			if kill_all_label: kill_all_label.visible = false

	handle_weapon_toggle()
	handle_zone_toggle()
	handle_shooting()
	handle_reloading()
	handle_debug_input() # Debug Cheat
	# handle_lift_interaction() # Removed explicit F press check
	
	if zone_active:
		zone_timer += delta
		if zone_timer >= zone_duration:
			force_deactivate_zone()
	
	update_ui()
	update_camera(delta)

func update_camera(delta):
	if not camera: return
	
	# Shake Decay
	if shake_intensity > 0:
		shake_intensity = lerp(shake_intensity, 0.0, shake_decay * delta)
		
	var shake_offset = Vector2(
		randf_range(-shake_intensity, shake_intensity),
		randf_range(-shake_intensity, shake_intensity)
	)
	
	# Smooth Follow with Overshoot
	var target_pos = global_position
	if velocity.length() > 10:
		target_pos += velocity * 0.3 # Look ahead
	
	# Custom Lerp for Rubber-banding effect
	# We want a slightly springy feel, so specific lerp speed
	camera.global_position = camera.global_position.lerp(target_pos, 5.0 * delta)
	
	# Apply Shake (additive, don't accumulate to position)
	camera.offset = shake_offset
	
	# ### ADDED: Knockback Decay logic
	# This reduces the knockback force over time so you don't slide forever
	if knockback_vector != Vector2.ZERO:
		knockback_vector = knockback_vector.move_toward(Vector2.ZERO, KNOCKBACK_DECAY * delta)
	
	var input_direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	
	if input_direction != Vector2.ZERO:
		velocity = velocity.move_toward(input_direction * SPEED, ACCELERATION * delta)
		if not is_aiming:
			play_movement_animation(input_direction)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, FRICTION * delta)
		if not is_aiming:
			play_idle_animation()
	
	# ### ADDED: Apply knockback to the final velocity
	velocity += knockback_vector
	
	move_and_slide()
	
	check_enemy_collisions()

func handle_reloading():
	if Input.is_action_just_pressed("reload") and not is_reloading and current_ammo < max_ammo:
		if magazines > 0:
			reload()
		else:
			print("Player: Out of magazines!")

func reload():
	if magazines <= 0:
		print("Player: Cannot reload - Out of magazines!")
		return
	is_reloading = true
	if reload_sound_player:
		reload_sound_player.play()
	await get_tree().create_timer(reload_time).timeout
	current_ammo = max_ammo
	magazines -= 1
	Global.current_ammo = current_ammo # Sync
	Global.magazines = magazines # Sync
	update_ui()
	is_reloading = false

func handle_lift_interaction():
	if can_enter_lift and Input.is_action_just_pressed("interact"):
		if Global.zombies_remaining <= 0:
			# Progress to next level
			print("Player: Entering lift - Level Completed!")
			call_deferred("transition_to_scene", "res://scenes/level_2.tscn")
		else:
			# Show warning
			print("Player: Cannot enter lift - Eliminate all zombies!")
			if kill_all_label:
				kill_all_label.visible = true
				await get_tree().create_timer(2.0).timeout
				if kill_all_label: kill_all_label.visible = false

func force_deactivate_zone():
	zone_active = false
	zone_timer = 0.0
	if zone_area:
		zone_area.monitoring = false
		zone_area.monitorable = false
		if zone_animation:
			zone_animation.visible = false
	print("Player: Zone forcibly DEACTIVATED due to timeout!")

func handle_weapon_toggle():
	if Input.is_action_just_pressed("weapon_toggle"):
		weapon_equipped = !weapon_equipped

func handle_zone_toggle():
	if Input.is_action_just_pressed("zone_toggle"):
		zone_active = !zone_active
		if zone_area:
			if zone_active:
				if demon_circle_uses <= 0:
					zone_active = false
					return
				demon_circle_uses -= 1
				Global.demon_circle_uses = demon_circle_uses # Sync
				zone_timer = 0.0
				zone_area.monitoring = zone_active
				zone_area.monitorable = zone_active
				if zone_animation:
					zone_animation.visible = zone_active
					zone_animation.play()
				await get_tree().physics_frame
				_check_zone_bodies()
			else:
				zone_area.monitoring = zone_active
				zone_area.monitorable = zone_active
				if zone_animation:
					zone_animation.visible = zone_active

func handle_shooting():
	if Input.is_action_just_pressed("shoot") and weapon_equipped:
		if is_reloading: return
		
		# Prevent shooting if shop is open
		if shop_open: return
		
		# Prevent shooting if clicking shop button
		if shop_button and shop_button.is_visible_in_tree():
			if shop_button.get_global_rect().has_point(get_global_mouse_position()):
				return
		
		if current_ammo > 0:
			if can_shoot:
				shoot()
				current_ammo -= 1
				Global.current_ammo = current_ammo # Sync
		else:
			reload()

func shoot():
	var bullet_scene = preload("res://scenes/bullet.tscn")
	var bullet = bullet_scene.instantiate()
	var mouse_pos = get_global_mouse_position()
	var spawn_pos = global_position
	var direction = (mouse_pos - spawn_pos).normalized()
	
	shake_intensity = 5.0 # Screen Shake
	
	bullet.global_position = spawn_pos
	bullet.direction = direction
	
	is_aiming = true
	play_aim_animation(direction)
	
	bullet.direction = direction
	bullet.direction = direction
	bullet.target_position = mouse_pos
	
	# Apply Damage Upgrade
	if Global.has_damage_upgrade:
		bullet.damage = 25.0 * 2.0
	else:
		bullet.damage = 25.0
	
	get_tree().current_scene.add_child(bullet)
	bullet.global_position = spawn_pos
	bullet._setup_target()
	
	can_shoot = false
	await get_tree().create_timer(SHOOT_COOLDOWN).timeout
	can_shoot = true
	
	if shoot_sound_player:
		shoot_sound_player.play()
		
	# Muzzle Flash
	var muzzle = load("res://scenes/muzzle_particles.tscn").instantiate()
	muzzle.position = direction * 20.0 # Offset slightly in shooting direction
	muzzle.rotation = direction.angle()
	add_child(muzzle)
	muzzle.emitting = true
	
	await get_tree().create_timer(0.3).timeout
	is_aiming = false

func _check_zone_bodies():
	if not zone_active or not zone_area: return
	var bodies_in_zone = zone_area.get_overlapping_bodies()
	for body in bodies_in_zone:
		if body == self: continue
		
		# VISUAL CHECK: Only transform if actually close enough (circle radius)
		if global_position.distance_to(body.global_position) > ZONE_RADIUS:
			continue
			
		if body.has_method("transform_to_zombie"):
			body.transform_to_zombie(self)
			if body not in transformed_enemies:
				transformed_enemies.append(body)

func _on_zone_body_entered(body):
	if body == self: return
	
	# VISUAL CHECK: Only transform if actually close enough
	if global_position.distance_to(body.global_position) > ZONE_RADIUS:
		return
		
	if zone_active and body.has_method("transform_to_zombie"):
		body.transform_to_zombie(self)
		if body not in transformed_enemies:
			transformed_enemies.append(body)

func _on_zone_body_exited(body):
	if body == self: return

func play_movement_animation(direction: Vector2):
	var prefix = "gun_" if weapon_equipped else ""
	if direction.x > 0 and direction.y < 0:
		animated_sprite.play(prefix + "right_up"); last_direction = "right_up"
	elif direction.x > 0 and direction.y > 0:
		animated_sprite.play(prefix + "right_down"); last_direction = "right_down"
	elif direction.x < 0 and direction.y < 0:
		animated_sprite.play(prefix + "left_up"); last_direction = "left_up"
	elif direction.x < 0 and direction.y > 0:
		animated_sprite.play(prefix + "left_down"); last_direction = "left_down"
	elif direction.x > 0:
		animated_sprite.play(prefix + "right"); last_direction = "right"
	elif direction.x < 0:
		animated_sprite.play(prefix + "left"); last_direction = "left"
	elif direction.y < 0:
		animated_sprite.play(prefix + "up"); last_direction = "up"
	elif direction.y > 0:
		animated_sprite.play(prefix + "down"); last_direction = "down"

func play_idle_animation():
	var current_anim = animated_sprite.animation
	var prefix = "gun_" if weapon_equipped else ""
	if "right_up" in current_anim or "right" in current_anim:
		if "up" in current_anim: animated_sprite.play(prefix + "idle_right_up")
		elif "down" in current_anim: animated_sprite.play(prefix + "idle_right_down")
		else: animated_sprite.play(prefix + "idle_right")
	elif "left_up" in current_anim or "left" in current_anim:
		if "up" in current_anim: animated_sprite.play(prefix + "idle_left_up")
		elif "down" in current_anim: animated_sprite.play(prefix + "idle_left_down")
		else: animated_sprite.play(prefix + "idle_left")
	elif "up" in current_anim: animated_sprite.play(prefix + "idle_up")
	elif "down" in current_anim: animated_sprite.play(prefix + "idle_down")
	else: animated_sprite.play(prefix + "idle_down")

func play_aim_animation(direction: Vector2):
	if direction.x > 0 and abs(direction.y) < 0.5: animated_sprite.play("aim_right")
	elif direction.x < 0 and abs(direction.y) < 0.5: animated_sprite.play("aim_left")
	elif direction.y < 0 and abs(direction.x) < 0.5: animated_sprite.play("aim_up")
	elif direction.y > 0 and abs(direction.x) < 0.5: animated_sprite.play("aim_down")
	elif direction.x > 0 and direction.y < 0: animated_sprite.play("aim_right_up")
	elif direction.x > 0 and direction.y > 0: animated_sprite.play("aim_right_down")
	elif direction.x < 0 and direction.y < 0: animated_sprite.play("aim_left_up")
	elif direction.x < 0 and direction.y > 0: animated_sprite.play("aim_left_down")

func check_enemy_collisions():
	# Check all bodies we're colliding with
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		
		# ### UPDATED: Collision Logic
		if collider and collider.is_in_group("enemy") and can_take_damage:
			# Check if the enemy is actually transformed (a zombie)
			# We use .get("transformed") to be safe, but direct access works too
			if collider.get("transformed") == true:
				# Apply Knockback
				var knockback_dir = (global_position - collider.global_position).normalized()
				knockback_vector = knockback_dir * KNOCKBACK_FORCE
				
				take_damage(5) # Reduced damage from 10 to 5
				break # Only take damage once per frame

func take_damage(damage: float):
	if not can_take_damage:
		return
	
	current_health -= damage
	Global.current_health = current_health # Sync
	print("Player Health: ", current_health, "/", max_health)
	
	if health_bar:
		health_bar.value = current_health
		
	# Spawn Red Blood
	var blood = load("res://scenes/blood_particles.tscn").instantiate()
	blood.color = Color(0.8, 0.0, 0.0)
	get_tree().current_scene.add_child(blood)
	blood.global_position = global_position
	blood.emitting = true
	
	can_take_damage = false
	await get_tree().create_timer(damage_cooldown).timeout
	can_take_damage = true
	
	if current_health <= 0:
		die()

func die():
	print("Player: Died!")
	get_tree().change_scene_to_file("res://scenes/end_secene.tscn")
