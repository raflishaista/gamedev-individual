extends CharacterBody2D
@onready var ray = $RayCast2D
@onready var anger = $anger
@onready var animplayer = $AnimatedSprite2D
@onready var spawner = $Spawner
@onready var bomb_spawner = $BombSpawner
@export var anger_jingle: AudioStream
@export var collision_jingle: AudioStream
@export var gameover_jingle: AudioStream

enum State { PATROL, ENRAGED, RAIN, ENRAGED_RAIN, BOMB, ENRAGED_BOMB }
var is_raining: bool = false
var current_state = State.PATROL
@export var speed: float = 100.0
var direction: int = 1
var can_flip: bool = true
var is_bombing: bool = false

func _ready():
	# Make entire antagonist subtree pause-aware
	process_mode = Node.PROCESS_MODE_PAUSABLE
	anger.visible = false
	var protagonist = get_tree().get_first_node_in_group("protagonist")
	if protagonist:
		protagonist.taunted.connect(on_taunted)
	run_pattern()

func update_ray_direction():
	ray.target_position = Vector2(direction * 40, 0)

func _physics_process(delta):
	match current_state:
		State.PATROL, State.ENRAGED:
			patrol_behavior()
		State.RAIN, State.ENRAGED_RAIN:
			rain_behavior()
		State.BOMB:
			bomb_behavior()
		State.ENRAGED_BOMB:
			enraged_bomb_behavior()
	move_and_slide()

func run_pattern():
	while true:
		# --- PATROL PHASE ---
		change_state(State.PATROL if not is_enraged() else State.ENRAGED)
		await get_tree().create_timer(8.0, true).timeout
		if not is_instance_valid(self): return

		# --- RAIN PHASE ---
		await do_rain()
		if not is_instance_valid(self): return

		# --- PATROL PHASE ---
		change_state(State.PATROL if not is_enraged() else State.ENRAGED)
		await get_tree().create_timer(5.0, true).timeout
		if not is_instance_valid(self): return

		# --- BOMB PHASE ---
		await do_bomb()
		if not is_instance_valid(self): return

func is_enraged() -> bool:
	return current_state in [State.ENRAGED, State.ENRAGED_RAIN, State.ENRAGED_BOMB]

func do_rain() -> void:
	is_raining = true
	change_state(State.ENRAGED_RAIN if is_enraged() else State.RAIN)

	await get_tree().create_timer(3.0, true).timeout
	if not is_instance_valid(self): return

	if spawner:
		spawner.set_rain_mode(false)
		spawner.set_paused(true)

	# Safety timeout — wait max 3 seconds for fireballs to clear
	var wait_time = 0.0
	var max_wait = 3.0
	while spawner and not spawner.all_fireballs_gone() and wait_time < max_wait:
		await get_tree().create_timer(0.1, true).timeout
		if not is_instance_valid(self): return
		wait_time += 0.1

	# Force clear in case counter got stuck
	if spawner:
		spawner.force_clear()
		spawner.set_paused(false)
	is_raining = false

func do_bomb() -> void:
	is_bombing = true
	change_state(State.ENRAGED_BOMB if is_enraged() else State.BOMB)

	if spawner:
		spawner.set_paused(true)

	await get_tree().create_timer(4.0, true).timeout
	if not is_instance_valid(self): return

	if bomb_spawner:
		bomb_spawner.set_paused(true)

	var wait_time = 0.0
	var max_wait = 3.0
	while bomb_spawner and not bomb_spawner.all_bombs_gone() and wait_time < max_wait:
		await get_tree().create_timer(0.1, true).timeout
		if not is_instance_valid(self): return
		wait_time += 0.1

	if bomb_spawner:
		bomb_spawner.force_clear()
	if spawner:
		spawner.set_paused(false)
	is_bombing = false

func patrol_behavior():
	# Wall bouncing via raycast — same as original
	if ray.is_colliding() and can_flip:
		flip_direction()
	velocity.y = sin(Time.get_ticks_msec() / 500.0) * 300
	velocity.x = direction * speed

	# Sprite faces protagonist, independent of movement direction
	var protagonist = get_tree().get_first_node_in_group("protagonist")
	if protagonist:
		animplayer.flip_h = protagonist.global_position.x < global_position.x


func bomb_behavior():
	# Same wall bouncing movement
	if ray.is_colliding() and can_flip:
		flip_direction()
	velocity.y = sin(Time.get_ticks_msec() / 500.0) * 300
	velocity.x = direction * speed * 3

	# Sprite faces protagonist
	var protagonist = get_tree().get_first_node_in_group("protagonist")
	if protagonist:
		animplayer.flip_h = protagonist.global_position.x < global_position.x
		
func enraged_bomb_behavior():
	# Same wall bouncing movement
	if ray.is_colliding() and can_flip:
		flip_direction()
	velocity.y = sin(Time.get_ticks_msec() / 500.0) * 300
	velocity.x = direction * speed * 4

	# Sprite faces protagonist
	var protagonist = get_tree().get_first_node_in_group("protagonist")
	if protagonist:
		animplayer.flip_h = protagonist.global_position.x < global_position.x

func rain_behavior():
	velocity.x = move_toward(velocity.x, 0, speed)
	velocity.y = 0.0

func flip_direction():
	can_flip = false
	direction *= -1
	update_ray_direction()
	get_tree().create_timer(0.3, true).timeout.connect(func(): can_flip = true)

func change_state(new_state):
	current_state = new_state
	match new_state:
		State.PATROL:
			anger.visible = false
			Global.tick_rate = 1.0
			if spawner:
				spawner.set_fire_rate(2.0)
				spawner.set_rain_mode(false)
				spawner.set_paused(false)
			if bomb_spawner:
				bomb_spawner.set_paused(true)
		State.ENRAGED:
			anger.visible = true
			Global.tick_rate = 2.0
			if spawner:
				spawner.set_fire_rate(1.2)
				spawner.set_rain_mode(false)
				spawner.set_paused(false)
			if bomb_spawner:
				bomb_spawner.set_paused(true)
		State.RAIN:
			anger.visible = false
			Global.tick_rate = 1.0
			if spawner:
				spawner.set_fire_rate(0.3)
				spawner.set_rain_mode(true)
				spawner.set_paused(false)
			if bomb_spawner:
				bomb_spawner.set_paused(true)
		State.ENRAGED_RAIN:
			anger.visible = true
			Global.tick_rate = 2.0
			if spawner:
				spawner.set_fire_rate(0.25)
				spawner.set_rain_mode(true)
				spawner.set_paused(false)
			if bomb_spawner:
				bomb_spawner.set_paused(true)
		State.BOMB:
			anger.visible = false
			Global.tick_rate = 1.0
			if spawner:
				spawner.set_paused(true)
			if bomb_spawner:
				bomb_spawner.set_paused(false)
				bomb_spawner.set_fire_rate(1.0)   # normal drop rate
		State.ENRAGED_BOMB:
			anger.visible = true                   # enraged visuals
			Global.tick_rate = 2.0                 # timer ticks faster
			if spawner:
				spawner.set_paused(true)
			if bomb_spawner:
				bomb_spawner.set_paused(false)
				bomb_spawner.set_fire_rate(0.9)    # drops bombs much faster

func on_taunted():
	SoundManager.play_at(anger_jingle, global_position)
	if is_enraged():
		return  
	
	match current_state:
		State.PATROL:
			change_state(State.ENRAGED)
		State.RAIN:
			change_state(State.ENRAGED_RAIN)
		State.BOMB:
			change_state(State.ENRAGED_BOMB)

	await get_tree().create_timer(10.0, true).timeout
	if not is_instance_valid(self): return

	# Downgrade back to normal equivalent after 10 seconds
	match current_state:
		State.ENRAGED:
			change_state(State.PATROL)
		State.ENRAGED_RAIN:
			change_state(State.RAIN)
		State.ENRAGED_BOMB:
			change_state(State.BOMB)

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("protagonist"):
		if not body.invulnerable:
			SoundManager.play_at(collision_jingle, global_position)
			Global.lives -= 1
			Global.life_lost.emit()
		if Global.lives <= 0:
			SoundManager.play_at(gameover_jingle, global_position)
			get_tree().change_scene_to_file("res://scenes/Game Over.tscn")
