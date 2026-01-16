extends TextureProgressBar

@export var player: CharacterBody2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	player.health_changed.connect(update)
	player.ammo.connect(update)
	player.coin_update.connect(update)
	player.zone_update.connect(update)
	update()




# Called every frame. 'delta' is the elapsed time since the previous frame.
func update():
	$".".value = player.current_health * 100 / player.max_health
	$"../../Panel2/Ammo".value = player.current_ammo * 3
	$"../../Panel2/Label".text = "  x " + str(player.magazines)
	$"../../Panel4/Label".text = ":  " + str(Global.coins)
	$"../../Panel3/Label".text = str(Global.demon_circle_uses)
	if player.game_started_safe and Global.zombies_remaining <= 0:
		$"../../Panel5/Label".text = "Enemies remaining: " + str(Global.zombies_remaining)
