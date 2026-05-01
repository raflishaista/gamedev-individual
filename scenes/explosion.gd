extends Area2D
var spawn_position = Vector2.ZERO
@export var lifetime: float = 1.0  # how long explosion lasts
@export var hit_sound: AudioStream
@export var gameover_sound: AudioStream

func _ready():
	global_position = spawn_position
	# Auto destroy after lifetime
	await get_tree().create_timer(lifetime).timeout
	queue_free()

func _on_body_entered(body):
	if body.is_in_group("protagonist"):
		if not body.invulnerable:
			SoundManager.play_at(hit_sound, global_position)
			Global.lives -= 1
			Global.life_lost.emit()
		if Global.lives <= 0:
			SoundManager.play_at(gameover_sound, global_position)
			get_tree().change_scene_to_file("res://scenes/Game Over.tscn")
