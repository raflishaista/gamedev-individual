extends Node2D
@export var obstacle: PackedScene
@export var fire_rate: float = 2.0
@export var rain_spread: float = 300.0
var rain_mode: bool = false
const Fireball = preload("res://scenes/fireball.tscn")
var active_fireballs: int = 0  # counter

func set_fire_rate(new_rate: float):
	fire_rate = new_rate

func set_rain_mode(enabled: bool):
	rain_mode = enabled

func all_fireballs_gone() -> bool:
	return active_fireballs <= 0

func spawn():
	var spawned: Area2D = obstacle.instantiate()
	var fireball = spawned as Node  # cast to access script properties
	var protagonist = get_tree().get_first_node_in_group("protagonist")

	if rain_mode and protagonist:
		fireball.set("spawn_position", Vector2(
			protagonist.global_position.x + randf_range(-rain_spread, rain_spread),
			protagonist.global_position.y - 400
		))
		fireball.set("direction", Vector2(randf_range(-0.2, 0.2), 1).normalized())
	elif protagonist:
		var dir = (protagonist.global_position - global_position).normalized()
		fireball.set("direction", dir)
		fireball.set("spawn_position", global_position)

	active_fireballs += 1
	spawned.tree_exited.connect(func(): active_fireballs -= 1)
	get_tree().current_scene.call_deferred("add_child", spawned)

func _ready():
	repeat()

func repeat():
	while true:
		spawn()
		await get_tree().create_timer(fire_rate).timeout
