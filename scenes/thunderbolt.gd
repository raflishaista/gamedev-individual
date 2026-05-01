extends Area2D

var spawn_position = Vector2.ZERO
@export var lifetime: float = 0.5

func _ready():
	global_position = spawn_position
	await get_tree().create_timer(lifetime).timeout
	queue_free()

func _on_body_entered(body):
	if body.is_in_group("protagonist"):
		if not body.invulnerable:
			Global.lives -= 1
			Global.life_lost.emit()
		if Global.lives <= 0:
			get_tree().change_scene_to_file("res://scenes/Game Over.tscn")
