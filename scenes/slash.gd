extends MarginContainer
var time: float = 3
var tick_rate: float = 1.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if time > 0:
		time -= delta * tick_rate
		if time <= 0:
			time = 0
			get_tree().change_scene_to_file("res://scenes/Game Finish.tscn")
	pass
