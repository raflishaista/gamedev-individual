extends CanvasLayer

@onready var pause_menu = $PauseMenu

func _process(_delta):
	if Input.is_action_just_pressed("esc"):
		toggle_pause()

func _ready():
	pause_menu.visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS

func _unhandled_input(event):
	if event is InputEventAction:
		if event.is_action_just_pressed("esc"):
			toggle_pause()

func toggle_pause():
	var is_paused = not get_tree().paused
	get_tree().paused = is_paused
	pause_menu.visible = is_paused

func _on_resume_pressed():
	get_tree().paused = false
	pause_menu.visible = false

func _on_quit_pressed():
	get_tree().paused = false
	Global.reset()
	get_tree().change_scene_to_file("res://scenes/Game START.tscn")
