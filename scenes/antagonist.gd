extends CharacterBody2D
@onready var ray = $RayCast2D
@onready var anger = $anger
@onready var animplayer = $AnimatedSprite2D
@onready var spawner = $Spawner

enum State { PATROL, ENRAGED , RAIN , ENRAGED_RAIN }
var rain_timer: float = 0.0
@export var rain_interval: float = 10.0
var current_state = State.PATROL
@export var speed: float = 100.0
var direction: int = 1
var can_flip: bool = true  # prevents repeated flipping

func _ready():
	anger.visible = false
	var protagonist = get_tree().get_first_node_in_group("protagonist")
	if protagonist:
		protagonist.taunted.connect(on_taunted)
	update_ray_direction()  # set ray correctly at start

func update_ray_direction():
	# Move ray target in front of enemy based on direction
	ray.target_position = Vector2(direction * 40, 0)

func _physics_process(delta):
	rain_timer += delta
	if rain_timer >= rain_interval:
		rain_timer = 0.0
		start_rain()

	match current_state:
		State.PATROL:
			patrol_behavior()
		State.ENRAGED:
			enraged_behavior()
		State.RAIN:
			rain_behavior()
		State.ENRAGED_RAIN:
			rain_behavior()  # same movement behavior as rain
	move_and_slide()

func patrol_behavior():
	if ray.is_colliding() and can_flip:
		flip_direction()
	velocity.y = sin(Time.get_ticks_msec() / 500.0) * 300
	velocity.x = direction * speed
	animplayer.flip_h = direction < 0  # sprite faces movement direction

func enraged_behavior():
	if ray.is_colliding() and can_flip:
		flip_direction()
	velocity.y = sin(Time.get_ticks_msec() / 500.0) * 300
	velocity.x = direction * speed * 2
	animplayer.flip_h = direction < 0

func flip_direction():
	can_flip = false
	direction *= -1
	update_ray_direction()  # point ray the new direction
	# Small cooldown so it doesn't flip repeatedly
	get_tree().create_timer(0.3).timeout.connect(func(): can_flip = true)

# ---- STATE TRANSITIONS ----
func change_state(new_state):
	current_state = new_state
	match new_state:
		State.PATROL:
			anger.visible = false
			Global.tick_rate = 1.0        # ← explicit every state
			if spawner:
				spawner.set_fire_rate(2.0)
				spawner.set_rain_mode(false)
		State.ENRAGED:
			anger.visible = true
			Global.tick_rate = 2.0        # ← explicit every state
			if spawner:
				spawner.set_fire_rate(1.0)
				spawner.set_rain_mode(false)
		State.RAIN:
			anger.visible = false
			Global.tick_rate = 1.0        # ← explicit every state
			if spawner:
				spawner.set_fire_rate(0.3)
				spawner.set_rain_mode(true)
		State.ENRAGED_RAIN:
			anger.visible = true          # enraged visuals
			Global.tick_rate = 2.0        # enraged tick rate
			if spawner:
				spawner.set_fire_rate(0.2)  # even faster than normal rain
				spawner.set_rain_mode(true)

func on_taunted():
	if current_state == State.PATROL:
		change_state(State.ENRAGED)
		await get_tree().create_timer(10).timeout
		if is_instance_valid(self):
			change_state(State.PATROL)

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("protagonist"):
		if not body.invulnerable:
			Global.lives -= 1
			Global.life_lost.emit()
		if Global.lives <= 0:
			get_tree().change_scene_to_file("res://scenes/Game Over.tscn")

func rain_behavior():
	velocity.x = move_toward(velocity.x, 0, speed)
	velocity.y = 0.0
	
func start_rain():
	var previous_state = current_state
	if current_state == State.ENRAGED:
		change_state(State.ENRAGED_RAIN)
	else:
		change_state(State.RAIN)

	# Spawn fireballs for 3 seconds
	await get_tree().create_timer(3.0).timeout

	# Stop spawning
	if spawner:
		spawner.set_rain_mode(false)
		spawner.set_fire_rate(99.0)  # effectively pause normal spawning

	# Wait until all rain fireballs are gone
	while spawner and not spawner.all_fireballs_gone():
		await get_tree().create_timer(0.1).timeout

	# Now safe to return to previous state
	if is_instance_valid(self):
		change_state(previous_state)
