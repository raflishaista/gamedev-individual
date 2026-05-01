extends Node2D
@export var bomb_scene: PackedScene
@export var fire_rate: float = 1.0
var is_paused: bool = true  # starts paused
var active_bombs: int = 0
@export var drop_sound: AudioStream

func set_paused(paused: bool):
	is_paused = paused

func set_fire_rate(new_rate: float):
	fire_rate = new_rate 

func force_clear():
	active_bombs = 0

func all_bombs_gone() -> bool:
	return active_bombs <= 0

func spawn():
	if is_paused:
		return          # ✅ Sound never plays when paused
	
	SoundManager.play_at(drop_sound, global_position)  # ✅ Moved here
	
	var spawned = bomb_scene.instantiate()
	spawned.set("spawn_position", global_position)
	spawned.set("direction", Vector2(0, 1))
	active_bombs += 1
	spawned.tree_exited.connect(func(): active_bombs -= 1)
	get_tree().current_scene.call_deferred("add_child", spawned)
	
func _ready():
	process_mode = Node.PROCESS_MODE_INHERIT
	repeat()

func repeat():
	while true:
		spawn()
		await get_tree().create_timer(fire_rate, true).timeout
