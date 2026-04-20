extends CharacterBody2D

var can_doublejump = 0
const DASH := 800
@export var SPEED := 400
@export var JUMP_SPEED := -500
@export var GRAVITY := 1200
@onready var animplayer = $AnimatedSprite2D

var tween: Tween
var dash_velocity := 0.0

const UP = Vector2(0,-1)
var invulnerable = false

func _get_input():
	if Input.is_action_just_pressed("ui_accept"):
		if is_on_floor():
			velocity.y = JUMP_SPEED
			can_doublejump = true   # earn double jump on first jump
		elif can_doublejump:        # separate check — not on floor
			velocity.y = JUMP_SPEED
			can_doublejump = false  # use it up
	if is_on_floor()==false and Input.is_action_just_pressed('ui_down'):
		velocity.y = -JUMP_SPEED*2
	if Input.is_action_just_pressed("shift"):
		dash_velocity = DASH
		if tween:
			tween.stop()
		tween = create_tween()
		tween.tween_property(self, "dash_velocity", 0, 0.3).set_ease(Tween.EASE_OUT)
		var direction = Input.get_axis("move_left", "move_right")
		if direction:
			velocity.x = direction * (SPEED + dash_velocity)
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)
	var direction := Input.get_axis("ui_left", "ui_right")
	var animation = "default"
	if direction:
		animation = "walk"
		velocity.x = direction * SPEED
		if direction > 0:
			animplayer.flip_h = false
		else:
			animplayer.flip_h = true
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
	if animplayer.animation != animation:
		animplayer.play(animation)
	# ← NO move_and_slide() here
	
func _ready():
	Global.life_lost.connect(_on_life_lost)

func _on_life_lost():
	if not invulnerable:
		start_invulnerability()

func start_invulnerability():
	invulnerable = true
	# Blink using a timer loop
	var blink_count = 6  # how many times it blinks
	for i in blink_count:
		animplayer.visible = false
		await get_tree().create_timer(0.15).timeout
		animplayer.visible = true
		await get_tree().create_timer(0.15).timeout
	invulnerable = false

func _physics_process(delta: float) -> void:
	velocity.y += delta * GRAVITY
	_get_input()
	move_and_slide()  # ← only here
