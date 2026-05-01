extends MarginContainer

@onready var label = $Label
var can_win: bool = false  # locked until timer ends

func _ready():
	Global.time_up.connect(_on_time_up)

func _on_time_up():
	can_win = true
	# Optional: show a prompt so the player knows they can escape
	label.text = "Press X to Win!"

func _input(event):
	if event.is_action_pressed("win") and can_win:
		get_tree().change_scene_to_file("res://scenes/SLASH.tscn")

func _process(delta: float) -> void:
	if Global.time > 0:
		label.text = "Timer : " + str(int(Global.time)) + "\n" + "Lives : " + str(int(Global.lives))
