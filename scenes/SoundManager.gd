extends Node

func play_at(sound: AudioStream, position: Vector2):
	var player = AudioStreamPlayer2D.new()
	add_child(player)
	player.stream = sound
	player.global_position = position
	player.play()
	player.finished.connect(player.queue_free)
