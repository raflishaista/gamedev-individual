extends MarginContainer
var time: float = 3
var tick_rate: float = 1.0
@export var slash1_sound: AudioStream  # Assign your sound in the Inspector
@export var slash2_sound: AudioStream

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	SoundManager.play_at(slash1_sound, global_position)
	SoundManager.play_at(slash2_sound, global_position)
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	
	if time > 0:
		time -= delta * tick_rate
		if time <= 0:
			time = 0
			get_tree().change_scene_to_file("res://scenes/Game Finish 2.tscn")
	pass
