extends Node2D
@export var obstacle: PackedScene
@export var fire_rate: float = 2.0
@export var rain_spread: float = 300.0
var rain_mode: bool = false
var active_fireballs: int = 0
var is_paused: bool = false  # new flag
@export var click_sound: AudioStream  # Assign your sound in the Inspector

var audio_player: AudioStreamPlayer2D

func set_fire_rate(new_rate: float):
	fire_rate = new_rate

func set_rain_mode(enabled: bool):
	rain_mode = enabled

func set_paused(paused: bool):
	is_paused = paused

func spawn():
	audio_player.play()
	if is_paused:
		return
	if not obstacle:
		push_error("Spawner: obstacle scene not assigned!")
		return
	var spawned = obstacle.instantiate()
	var protagonist = get_tree().get_first_node_in_group("protagonist")

	if rain_mode and protagonist:
		spawned.set("spawn_position", Vector2(
			protagonist.global_position.x + randf_range(-rain_spread, rain_spread),
			protagonist.global_position.y - 400
		))
		spawned.set("direction", Vector2(randf_range(-0.2, 0.2), 1).normalized())
	elif protagonist:
		var dir = (protagonist.global_position - global_position).normalized()
		spawned.set("direction", dir)
		spawned.set("spawn_position", global_position)

	active_fireballs += 1
	# Use call_deferred on the connection to ensure node is ready
	spawned.tree_exiting.connect(func(): active_fireballs = max(0, active_fireballs - 1))
	get_tree().current_scene.call_deferred("add_child", spawned)

func all_fireballs_gone() -> bool:
	return active_fireballs <= 0

func force_clear():
	active_fireballs = 0

func _ready():
	audio_player = AudioStreamPlayer2D.new()
	add_child(audio_player)
	audio_player.stream = click_sound
	repeat()

func repeat():
	while true:
		spawn()
		await get_tree().create_timer(fire_rate).timeout
