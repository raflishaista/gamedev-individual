extends Area2D

var spawn_position = Vector2.ZERO
@export var warning_sound: AudioStream
func _ready():
	SoundManager.play_at(warning_sound, global_position)
	global_position = spawn_position
