extends Node

signal life_lost

var time: float = 90 # starting time
var lives: int = 3

func reset():
	lives = 3
	time = 90

func _process(delta: float) -> void:
	if time > 0:
		time -= delta
		if time <= 0:
			get_tree().change_scene_to_file("res://scenes/Game Finish.tscn")
