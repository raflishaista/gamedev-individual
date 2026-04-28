extends Node2D
@export var obstacle: PackedScene
@export var fire_rate: float = 2.0  # default rate

func set_fire_rate(new_rate: float):
	fire_rate = new_rate  # antagonist calls this to change speed

func spawn():
	var spawned = obstacle.instantiate()

func _ready():
	repeat()

func repeat():
	while true:
		spawn()
		await get_tree().create_timer(fire_rate).timeout
