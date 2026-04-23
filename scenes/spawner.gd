extends Node2D
@export var obstacle: PackedScene
@export var fire_rate: float = 2.0  # default rate

func set_fire_rate(new_rate: float):
	fire_rate = new_rate  # antagonist calls this to change speed

func spawn():
	var spawned = obstacle.instantiate()
	var protagonist = get_tree().get_first_node_in_group("protagonist")
	if protagonist:
		var dir = (protagonist.global_position - global_position).normalized()
		spawned.direction = dir
	spawned.spawn_position = global_position
	get_parent().call_deferred("add_child", spawned)

func _ready():
	repeat()

func repeat():
	while true:
		spawn()
		await get_tree().create_timer(fire_rate).timeout
