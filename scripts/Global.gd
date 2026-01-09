extends Node

var coins = 20
var zombies_remaining = 0
var game_over_message = "GAME OVER"

var has_damage_upgrade = false

# Persistent Player Stats
var magazines = 5
var current_ammo = 6
var demon_circle_uses = 3
var current_health = 100.0
var max_health = 100.0

var music_player: AudioStreamPlayer
var ambient_player: AudioStreamPlayer

func _ready():
	_setup_global_audio()

func _setup_global_audio():
	# Music
	music_player = AudioStreamPlayer.new()
	music_player.stream = load("res://sounds/music/evil music.mp3")
	music_player.bus = "Music"
	music_player.autoplay = true
	add_child(music_player)
	
	# Ambience (Crickets)
	ambient_player = AudioStreamPlayer.new()
	ambient_player.stream = load("res://sounds/cricket-on-a-summer-night-_-cricket-sound-341501.mp3")
	ambient_player.bus = "Music"
	ambient_player.autoplay = true
	add_child(ambient_player)

func reset_game_state():
	coins = 20
	zombies_remaining = 0
	game_over_message = "GAME OVER"
	has_damage_upgrade = false
	magazines = 5
	current_ammo = 6
	demon_circle_uses = 3
	current_health = 100.0
	max_health = 100.0
