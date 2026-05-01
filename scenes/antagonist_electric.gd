extends CharacterBody2D

@onready var animplayer = $AnimatedSprite2D
@onready var jolt_spawner = $JoltSpawner
@onready var thunderbolt_spawner = $ThunderboltSpawner
@onready var anger = $anger

@export var anger_jingle: AudioStream
@export var collision_jingle: AudioStream
@export var gameover_jingle: AudioStream

@export var speed: float = 150.0
@export var gravity: float = 800.0
@export var jump_force: float = -500.0

enum State { PATROL, ENRAGED_PATROL, CHARGE, ENRAGED_CHARGE, THUNDER, ENRAGED_THUNDER }
var current_state = State.PATROL
var direction: int = 1
var is_enraged_flag: bool = false

func _ready():
	anger.visible = false
	var protagonist = get_protagonist()
	if protagonist:
		protagonist.taunted.connect(on_taunted)
	run_pattern()

func _physics_process(delta):
	if not is_on_floor() and current_state != State.CHARGE and current_state != State.ENRAGED_CHARGE:
		velocity.y += gravity * delta

	match current_state:
		State.CHARGE, State.ENRAGED_CHARGE:
			charge_movement(delta)
		State.THUNDER, State.ENRAGED_THUNDER:
			velocity.x = 0

	move_and_slide()

# =====================
# PATTERN LOOP
# =====================

func run_pattern():
	while true:
		# --- PATROL + JOLT PHASE ---
		await do_patrol()
		if not is_instance_valid(self): return

		# --- CHARGE PHASE ---
		await do_charge()
		if not is_instance_valid(self): return

		# --- THUNDER PHASE ---
		await do_thunder()
		if not is_instance_valid(self): return

# =====================
# PATROL PHASE
# Runs for a set duration, repeatedly patrolling and firing jolts
# =====================

func do_patrol() -> void:
	change_state(State.ENRAGED_PATROL if is_enraged_flag else State.PATROL)
	var phase_duration = 12.0
	var phase_timer = 0.0

	while phase_timer < phase_duration:
		if not is_instance_valid(self): return
		if not is_inside_tree(): return

		var run_speed = speed * 2 if is_enraged_flag else speed
		var jolts_per_stop = 3 if is_enraged_flag else 1
		var patrol_distance = 200.0
		var distance_traveled = 0.0

		animplayer.play("running")
		while distance_traveled < patrol_distance:
			velocity.x = direction * run_speed
			animplayer.flip_h = direction < 0
			if not await wait_frame(): return
			distance_traveled += abs(velocity.x) * get_process_delta_time()
			phase_timer += get_process_delta_time()
			if is_on_wall():
				direction *= -1
				break
			if phase_timer >= phase_duration:
				break

		velocity.x = 0
		var protagonist = get_protagonist()
		if not protagonist: return
		direction = 1 if protagonist.global_position.x > global_position.x else -1
		animplayer.flip_h = protagonist.global_position.x < global_position.x

		animplayer.play("default")
		for i in jolts_per_stop:
			if not is_instance_valid(self): return
			if not is_inside_tree(): return
			if jolt_spawner:
				jolt_spawner.spawn_jolt()
			await get_tree().create_timer(0.4).timeout
			if not is_inside_tree(): return
			phase_timer += 0.4

		if not is_inside_tree(): return
		await get_tree().create_timer(0.8).timeout
		if not is_inside_tree(): return
		phase_timer += 0.8
		direction *= -1

	animplayer.play("default")
	if not is_inside_tree(): return
	await get_tree().create_timer(0.5).timeout

# =====================
# CHARGE PHASE
# Repeatedly locks on and charges for a set duration
# =====================

func do_charge() -> void:
	change_state(State.ENRAGED_CHARGE if is_enraged_flag else State.CHARGE)

	for i in range(4):
		if not is_instance_valid(self): return
		if not is_inside_tree(): return

		var max_charges = 4 if is_enraged_flag else 2
		if i >= max_charges:
			break

		var charge_speed = speed * 5 if is_enraged_flag else speed * 4

		var protagonist = get_protagonist()
		if not protagonist: return

		var charge_target = protagonist.global_position
		direction = 1 if charge_target.x > global_position.x else -1
		animplayer.flip_h = direction < 0
		animplayer.play("default")
		velocity.x = 0

		if not is_inside_tree(): return
		await get_tree().create_timer(0.5).timeout
		if not is_inside_tree(): return

		velocity.y = jump_force
		animplayer.play("tackle")

		var timeout = 0.0
		while abs(global_position.x - charge_target.x) > 20 and timeout < 2.0:
			velocity.x = direction * charge_speed
			if not await wait_frame(): return
			timeout += get_process_delta_time()

		velocity.x = 0
		animplayer.play("default")

		# Wait to land with hard timeout
		var land_timeout = 0.0
		while not is_on_floor() and land_timeout < 2.0:
			if not await wait_frame(): return
			land_timeout += get_process_delta_time()

		# Force to floor if timeout hit
		if not is_on_floor():
			velocity.y = 0

		if not is_inside_tree(): return
		await get_tree().create_timer(0.8).timeout
		if not is_inside_tree(): return

	animplayer.play("default")
	if not is_inside_tree(): return
	await get_tree().create_timer(1.0).timeout

func charge_movement(delta):
	if not is_on_floor():
		velocity.y += gravity * delta

# =====================
# THUNDER PHASE
# Stays in place, repeatedly strikes for a set duration
# =====================

func do_thunder() -> void:
	change_state(State.ENRAGED_THUNDER if is_enraged_flag else State.THUNDER)
	velocity.x = 0
	var phase_duration = 10.0
	var phase_timer = 0.0

	animplayer.play("thunder")

	while phase_timer < phase_duration:
		if not is_instance_valid(self): return
		if not is_inside_tree(): return

		var strike_count = 4 if is_enraged_flag else 2
		var protagonist = get_protagonist()
		if not protagonist: return
		animplayer.flip_h = protagonist.global_position.x < global_position.x

		for i in strike_count:
			if not is_instance_valid(self): return
			if not is_inside_tree(): return
			protagonist = get_protagonist()
			if not protagonist: break
			if thunderbolt_spawner:
				thunderbolt_spawner.spawn_strike(protagonist.global_position)
			await get_tree().create_timer(0.4).timeout
			if not is_inside_tree(): return
			phase_timer += 0.4

		if not is_inside_tree(): return
		await get_tree().create_timer(1.5).timeout
		if not is_inside_tree(): return
		phase_timer += 1.5

	animplayer.play("default")
	if not is_inside_tree(): return
	await get_tree().create_timer(0.5).timeout

# =====================
# STATE TRANSITIONS
# =====================

func change_state(new_state):
	current_state = new_state
	match new_state:
		State.PATROL:
			anger.visible = false
			Global.tick_rate = 1.0
		State.ENRAGED_PATROL:
			anger.visible = true
			Global.tick_rate = 2.0
		State.CHARGE:
			anger.visible = false
			Global.tick_rate = 1.0
		State.ENRAGED_CHARGE:
			anger.visible = true
			Global.tick_rate = 2.0
		State.THUNDER:
			anger.visible = false
			Global.tick_rate = 1.0
		State.ENRAGED_THUNDER:
			anger.visible = true
			Global.tick_rate = 2.0

func is_enraged() -> bool:
	return current_state in [State.ENRAGED_PATROL, State.ENRAGED_CHARGE, State.ENRAGED_THUNDER]

func on_taunted():
	SoundManager.play_at(anger_jingle, global_position)
	if is_enraged_flag:
		return
	is_enraged_flag = true

	# Immediately upgrade visual/rates for current state
	match current_state:
		State.PATROL:
			change_state(State.ENRAGED_PATROL)
		State.CHARGE:
			change_state(State.ENRAGED_CHARGE)
		State.THUNDER:
			change_state(State.ENRAGED_THUNDER)

	await get_tree().create_timer(10.0).timeout
	if not is_instance_valid(self): return

	is_enraged_flag = false
	anger.visible = false
	Global.tick_rate = 1.0
	match current_state:
		State.ENRAGED_PATROL:
			change_state(State.PATROL)
		State.ENRAGED_CHARGE:
			change_state(State.CHARGE)
		State.ENRAGED_THUNDER:
			change_state(State.THUNDER)

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("protagonist"):
		if not body.invulnerable:
			SoundManager.play_at(collision_jingle, global_position)
			Global.lives -= 1
			Global.life_lost.emit()
		if Global.lives <= 0:
			SoundManager.play_at(gameover_jingle, global_position)
			get_tree().change_scene_to_file("res://scenes/Game Over.tscn")

func wait_frame() -> bool:
	if not is_inside_tree(): return false
	await get_tree().process_frame
	return is_instance_valid(self) and is_inside_tree()

func get_protagonist() -> Node:
	if not is_inside_tree(): return null
	return get_tree().get_first_node_in_group("protagonist")
