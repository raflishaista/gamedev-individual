extends Area2D
@export var speed: float = 400.0
var direction = Vector2.ZERO
var spawn_position = Vector2.ZERO
@export var explosion_sound: AudioStream

@export var explosion_scene: PackedScene

func _ready():
	process_mode = Node.PROCESS_MODE_PAUSABLE
	global_position = spawn_position
	rotation = direction.angle()

func _process(delta):
	global_position += direction * speed * delta

func _on_body_entered(body):
	SoundManager.play_at(explosion_sound, global_position)
	explode()

func _on_visible_on_screen_notifier_2d_screen_exited():
	queue_free()

func explode():
	if explosion_scene:
		var explosion = explosion_scene.instantiate()
		explosion.set("spawn_position", global_position)
		get_tree().current_scene.call_deferred("add_child", explosion)
	queue_free()  # remove bomb, leave explosion
