extends Area2D
@export var speed = 300.0
var direction = Vector2.ZERO
var spawn_position = Vector2.ZERO  # receives position from spawner

func _ready() -> void:
	global_position = spawn_position  # set position here instead of spawner
	rotation = direction.angle() + PI

func _process(delta: float) -> void:
	global_position += direction * speed * delta

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("protagonist"):
		if not body.invulnerable:
			Global.lives -= 1
			Global.life_lost.emit()
		if Global.lives <= 0:
			get_tree().change_scene_to_file("res://scenes/Game Over.tscn")
		queue_free()

func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	queue_free()
