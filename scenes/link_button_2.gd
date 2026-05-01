extends LinkButton
@export var scene_to_load: String
@export var click_sound: AudioStream  # Assign your sound in the Inspector

var audio_player: AudioStreamPlayer2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	audio_player = AudioStreamPlayer2D.new()
	add_child(audio_player)
	audio_player.stream = click_sound
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_pressed() -> void:
	if audio_player and click_sound:
		audio_player.play()
	# Optional: wait for sound to finish before switching scenes
	await audio_player.finished
	get_tree().change_scene_to_file("res://scenes/" + scene_to_load + ".tscn")
