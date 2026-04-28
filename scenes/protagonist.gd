extends CharacterBody2D
var can_doublejump = false
signal taunted
const DASH := 800
@export var SPEED := 400
@export var JUMP_SPEED := -500
@export var GRAVITY := 1200
@onready var animplayer = $AnimatedSprite2D
@onready var finger = $finger
var tween: Tween
var dash_velocity := 0.0
var dash_direction := 0.0
var invulnerable = false

func _ready():
	Global.life_lost.connect(_on_life_lost)
	taunted.connect(Global.on_taunted)
	finger.visible = false

func _get_input():
	# Jumping
	if Input.is_action_just_pressed("ui_up"):
		if is_on_floor():
			velocity.y = JUMP_SPEED
			can_doublejump = true
		elif can_doublejump:
			velocity.y = JUMP_SPEED
			can_doublejump = false
	
	# Taunt
	if Input.is_action_just_pressed("z"):  # or whichever input you want
		show_finger()
		taunted.emit()
	
	# Fast fall
	if not is_on_floor() and Input.is_action_just_pressed("ui_down"):
		velocity.y = -JUMP_SPEED * 2

	# Dash
	if Input.is_action_just_pressed("shift"):
		dash_direction = Input.get_axis("ui_left", "ui_right")
		if dash_direction == 0:
			dash_direction = 1 if not animplayer.flip_h else -1
		dash_velocity = DASH
		if tween:
			tween.stop()
		tween = create_tween()
		tween.tween_property(self, "dash_velocity", 0.0, 0.3).set_ease(Tween.EASE_OUT)

func _physics_process(delta: float) -> void:
	velocity.y += delta * GRAVITY
	_get_input()

	# Horizontal movement and animation — only handled here, not in _get_input
	var direction = Input.get_axis("ui_left", "ui_right")
	var animation = "default"

	if dash_velocity > 0:
		velocity.x = dash_direction * (SPEED + dash_velocity)
		animation = "walk"
		animplayer.flip_h = dash_direction < 0
	elif direction:
		velocity.x = direction * SPEED
		animation = "walk"
		animplayer.flip_h = direction < 0
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	if animplayer.animation != animation:
		animplayer.play(animation)
	move_and_slide()

func _on_life_lost():
	if not invulnerable:
		start_invulnerability()
		
func show_finger():
	finger.flip_h = animplayer.flip_h  # match the protagonist's facing direction
	finger.visible = true
	await get_tree().create_timer(0.3).timeout
	finger.visible = false

func start_invulnerability():
	invulnerable = true
	var blink_count = 6
	for i in blink_count:
		animplayer.visible = false
		await get_tree().create_timer(0.15).timeout
		animplayer.visible = true
		await get_tree().create_timer(0.15).timeout
	invulnerable = false
