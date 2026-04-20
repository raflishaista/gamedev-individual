extends Node2D
@export var obstacle: PackedScene

func spawn():
	var spawned = obstacle.instantiate()
	
	# Set all variables BEFORE adding to scene
	var protagonist = get_tree().get_first_node_in_group("protagonist")
	if protagonist:
		var dir = (protagonist.global_position - global_position).normalized()
		spawned.direction = dir
	spawned.spawn_position = global_position  # pass spawn position to fireball
	
	get_parent().call_deferred("add_child", spawned)  # fixes the busy error

func _ready():
	repeat()

func repeat():
	while true:
		spawn()
		await get_tree().create_timer(2).timeout
