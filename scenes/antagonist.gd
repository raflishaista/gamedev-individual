extends CharacterBody2D

@onready var ray = $RayCast2D
const JUMP_VELOCITY = -400.0

enum State { PATROL, CHASE }

var current_state = State.PATROL

@export var speed: float = 100.0
var direction: int = 1  # 1 = right, -1 = left

func _physics_process(delta):
	if ray.is_colliding():
		direction *= -1
		ray.scale.x *= -1  # flip ray direction
	
	velocity.y = sin(Time.get_ticks_msec() / 500.0) * 300
	velocity.x = direction * speed

	move_and_slide()


func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.get_name() == "protagonist":
		var protagonist = body
		if not protagonist.invulnerable:
			Global.lives -= 1
			Global.life_lost.emit()
		if Global.lives == 0:
			get_tree().change_scene_to_file("res://scenes/Game Over.tscn")
	pass # Replace with function body.
