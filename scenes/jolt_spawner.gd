extends Node2D

@export var jolt_scene: PackedScene
@export var jolt_sound: AudioStream

func spawn_jolt():
	if not jolt_scene:
		push_error("JoltSpawner: jolt_scene not assigned!")
		return
	SoundManager.play_at(jolt_sound, global_position)
	var spawned = jolt_scene.instantiate()
	var protagonist = get_tree().get_first_node_in_group("protagonist")
	if protagonist:
		var dir = (protagonist.global_position - global_position).normalized()
		spawned.set("direction", dir)
	spawned.set("spawn_position", global_position)
	get_tree().current_scene.call_deferred("add_child", spawned)
