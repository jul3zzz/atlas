extends Node
## Bruitages et musique. Les sons sont générés par tools/gen_audio.py.
## Sfx.play("click") ; Sfx.play_3d("rifle", position, parent) ; Sfx.music("march")

const SOUNDS := [
	"click", "hover", "confirm", "error", "coin", "card", "page", "crate", "stamp",
	"rare", "legendary", "rankup", "victory", "defeat", "whistle",
	"rifle", "musket", "mg", "cannon", "explosion", "tank_gun", "sword", "arrow",
	"hit", "mech", "part", "engine",
]

var streams: Dictionary = {}
var _pool: Array[AudioStreamPlayer] = []
var _music_player: AudioStreamPlayer
var _music_name := ""
var _last_play: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for s in SOUNDS:
		var path := "res://assets/audio/%s.wav" % s
		if ResourceLoader.exists(path):
			streams[s] = load(path)
	for i in 12:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_pool.append(p)
	_music_player = AudioStreamPlayer.new()
	add_child(_music_player)
	_music_player.finished.connect(func(): if _music_name != "": _music_player.play())


func play(sound: String, volume_db := 0.0, pitch := 1.0) -> void:
	if not streams.has(sound):
		return
	# Évite d'empiler 30 fois le même son dans la même frame.
	var now := Time.get_ticks_msec()
	if now - int(_last_play.get(sound, -1000)) < 30:
		return
	_last_play[sound] = now
	for p in _pool:
		if not p.playing:
			p.stream = streams[sound]
			p.volume_db = volume_db
			p.pitch_scale = pitch
			p.play()
			return


## Son spatialisé (bataille). Le lecteur se supprime tout seul à la fin.
func play_3d(sound: String, pos: Vector3, parent: Node, volume_db := 0.0, max_per_sec := 14) -> void:
	if not streams.has(sound) or not is_instance_valid(parent):
		return
	var key := sound + "_3d"
	var now := Time.get_ticks_msec()
	var arr: Array = _last_play.get(key, [])
	arr = arr.filter(func(t): return now - t < 1000)
	if arr.size() >= max_per_sec:
		return
	arr.append(now)
	_last_play[key] = arr
	var p := AudioStreamPlayer3D.new()
	p.stream = streams[sound]
	p.volume_db = volume_db
	p.pitch_scale = randf_range(0.9, 1.1)
	p.unit_size = 18.0
	p.max_distance = 220.0
	parent.add_child(p)
	p.global_position = pos
	p.finished.connect(p.queue_free)
	p.play()


func music(name: String) -> void:
	if name == _music_name:
		return
	_music_name = name
	var path := "res://assets/audio/music_%s.wav" % name
	if name == "" or not ResourceLoader.exists(path):
		_music_player.stop()
		return
	_music_player.stream = load(path)
	_music_player.volume_db = linear_to_db(max(0.0001, float(Game.settings.volume_music))) - 6.0
	_music_player.play()


func refresh_music_volume() -> void:
	_music_player.volume_db = linear_to_db(max(0.0001, float(Game.settings.volume_music))) - 6.0
