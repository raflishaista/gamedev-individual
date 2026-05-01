extends Node
signal life_lost
signal time_up
var time: float = 90
var lives: int = 3
var tick_rate: float = 1.0
enum State { NORMAL, ENRAGED }
var current_state = State.NORMAL

func reset():
	lives = 3
	time = 90
	current_state = State.NORMAL
	tick_rate = 1.0

func _process(delta: float) -> void:
	if time > 0:
		time -= delta * tick_rate
		if time <= 0:
			time = 0
			time_up.emit()

func on_taunted():
	if current_state == State.NORMAL:
		current_state = State.ENRAGED
		tick_rate = 2.0
		await get_tree().create_timer(10).timeout
		current_state = State.NORMAL
		tick_rate = 1.0
