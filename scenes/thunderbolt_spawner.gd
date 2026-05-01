extends Node2D

@export var danger_scene: PackedScene    # danger.tscn warning sprite
@export var thunderbolt_scene: PackedScene  # the damaging bolt
@export var thunderbolt_sound: AudioStream
@export var warning_duration: float = 1.0  # how long warning shows before strike

func spawn_strike(target_position: Vector2) -> void:
	if not danger_scene or not thunderbolt_scene:
		push_error("ThunderboltSpawner: scenes not assigned!")
		return

	# Spawn warning marker — stays in place
	var warning = danger_scene.instantiate()
	warning.set("spawn_position", target_position)
	get_tree().current_scene.call_deferred("add_child", warning)

	# Wait for warning duration
	await get_tree().create_timer(warning_duration).timeout
	if not is_instance_valid(self): return

	# Remove warning, spawn actual bolt at same spot
	if is_instance_valid(warning):
		warning.queue_free()
	
	SoundManager.play_at(thunderbolt_sound, global_position)
	var bolt = thunderbolt_scene.instantiate()
	bolt.set("spawn_position", target_position)
	get_tree().current_scene.call_deferred("add_child", bolt)
