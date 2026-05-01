extends TextureButton

@export var scene_to_load: String
@export var click_sound: AudioStream  # Assign your sound in the Inspector

var audio_player: AudioStreamPlayer2D

func _ready() -> void:
	# Create the audio player as a child at runtime
	audio_player = AudioStreamPlayer2D.new()
	add_child(audio_player)
	audio_player.stream = click_sound

func _on_pressed() -> void:
	if audio_player and click_sound:
		audio_player.play()
	# Optional: wait for sound to finish before switching scenes
	await audio_player.finished
	get_tree().change_scene_to_file("res://scenes/" + scene_to_load + ".tscn")
