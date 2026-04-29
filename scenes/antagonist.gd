extends CharacterBody2D
@onready var ray = $RayCast2D
@onready var anger = $anger
@onready var animplayer = $AnimatedSprite2D
@onready var spawner = $Spawner
@onready var bomb_spawner = $BombSpawner


enum State { PATROL, ENRAGED , RAIN , ENRAGED_RAIN, BOMB }
var rain_timer: float = 0.0
@export var rain_interval: float = 10.0
var is_raining: bool = false
var current_state = State.PATROL
@export var speed: float = 100.0
var direction: int = 1
var can_flip: bool = true  # prevents repeated flipping
var bomb_timer: float = 0.0
@export var bomb_interval: float = 15.0  # how often bomb attack triggers
var is_bombing: bool = false

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
	if not is_raining and not is_bombing:
		rain_timer += delta
		if rain_timer >= rain_interval:
			rain_timer = 0.0
			start_rain()

		bomb_timer += delta
		if bomb_timer >= bomb_interval:
			bomb_timer = 0.0
			start_bomb()

	match current_state:
		State.PATROL:
			patrol_behavior()
		State.ENRAGED:
			enraged_behavior()
		State.RAIN:
			rain_behavior()
		State.ENRAGED_RAIN:
			rain_behavior()
		State.BOMB:
			bomb_behavior()
	move_and_slide()

func bomb_behavior():
	# Same as patrol but bombs drop below
	var protagonist = get_tree().get_first_node_in_group("protagonist")
	if protagonist:
		direction = 1 if protagonist.global_position.x > global_position.x else -1
	velocity.y = sin(Time.get_ticks_msec() / 500.0) * 300
	velocity.x = direction * speed
	animplayer.flip_h = direction < 0

func start_bomb():
	if is_bombing or is_raining:
		return
	is_bombing = true
	var previous_state = current_state
	change_state(State.BOMB)

	await get_tree().create_timer(4.0).timeout  # bomb phase lasts 4 seconds
	if not is_instance_valid(self):
		return

	if bomb_spawner:
		bomb_spawner.set_paused(true)

	while bomb_spawner and not bomb_spawner.all_bombs_gone():
		await get_tree().create_timer(0.1).timeout
		if not is_instance_valid(self):
			return

	if is_instance_valid(self):
		change_state(previous_state)  # fireballs resume here immediately
		if spawner:
			spawner.set_paused(false)  # unpause fireballs right away
			# don't wait for bombs — let explosions linger independently
		is_bombing = false

func patrol_behavior():
	if ray.is_colliding() and can_flip:
		flip_direction()
	velocity.y = sin(Time.get_ticks_msec() / 500.0) * 300
	velocity.x = direction * speed * 2
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
			Global.tick_rate = 1.0
			if spawner:
				spawner.set_fire_rate(2.0)
				spawner.set_rain_mode(false)
			if bomb_spawner:
				bomb_spawner.set_paused(true)  # no bombs in patrol
		State.ENRAGED:
			anger.visible = true
			Global.tick_rate = 2.0
			if spawner:
				spawner.set_fire_rate(1.0)
				spawner.set_rain_mode(false)
			if bomb_spawner:
				bomb_spawner.set_paused(true)
		State.RAIN:
			anger.visible = false
			Global.tick_rate = 1.0
			if spawner:
				spawner.set_fire_rate(0.3)
				spawner.set_rain_mode(true)
			if bomb_spawner:
				bomb_spawner.set_paused(true)
		State.ENRAGED_RAIN:
			anger.visible = true
			Global.tick_rate = 2.0
			if spawner:
				spawner.set_fire_rate(0.2)
				spawner.set_rain_mode(true)
			if bomb_spawner:
				bomb_spawner.set_paused(true)
		State.BOMB:
			anger.visible = false
			Global.tick_rate = 1.0
			if spawner:
				spawner.set_paused(true)   # pause fireballs during bomb phase
			if bomb_spawner:
				bomb_spawner.set_paused(false)

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
	if is_raining:  # prevent overlapping rain calls
		return
	is_raining = true

	# Capture state BEFORE any awaits
	var previous_state = current_state

	if previous_state == State.ENRAGED:
		change_state(State.ENRAGED_RAIN)
	else:
		change_state(State.RAIN)

	# Spawn rain fireballs for 3 seconds
	await get_tree().create_timer(3.0).timeout
	if not is_instance_valid(self):
		return

	# Stop spawning, wait for fireballs to clear
	if spawner:
		spawner.set_rain_mode(false)
		spawner.set_paused(true)

	while spawner and not spawner.all_fireballs_gone():
		await get_tree().create_timer(0.1).timeout
		if not is_instance_valid(self):
			return

	# Resume
	if spawner:
		spawner.set_paused(false)
	change_state(previous_state)
	is_raining = false
