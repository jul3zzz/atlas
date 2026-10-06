extends Node
## Profils locaux, progression (XP, grades, solde, cartes) et sauvegarde.
## Les sauvegardes sont dans user://profils.json
## (Windows : %APPDATA%/Godot/app_userdata/EPO/).

signal profile_changed
signal xp_gained(amount: int, reason: String)
signal solde_changed(value: int)
signal rank_up(rank_name: String)

const SAVE_PATH := "user://profils.json"
const SETTINGS_PATH := "user://parametres.json"
const CRATE_PRICE := 100

## Grades de l'armée française, du plus bas au plus haut, avec l'XP requise.
const RANKS := [
	["Soldat de 2e classe", 0],
	["Soldat de 1re classe", 200],
	["Caporal", 500],
	["Caporal-chef", 900],
	["Sergent", 1400],
	["Sergent-chef", 2000],
	["Adjudant", 2700],
	["Adjudant-chef", 3500],
	["Major", 4400],
	["Aspirant", 5400],
	["Sous-lieutenant", 6500],
	["Lieutenant", 7700],
	["Capitaine", 9000],
	["Commandant", 10500],
	["Lieutenant-colonel", 12200],
	["Colonel", 14000],
	["Général de brigade", 16500],
	["Général de division", 19500],
	["Général de corps d'armée", 23000],
	["Général d'armée", 27000],
	["Maréchal de France", 32000],
]

var profiles: Array = []
var current: Dictionary = {}
var settings := {
	"volume_master": 0.8,
	"volume_music": 0.5,
	"fullscreen": false,
	"last_profile": "",
}


func _ready() -> void:
	_setup_inputs()
	_load_settings()
	_load_profiles()
	if settings.last_profile != "":
		for p in profiles:
			if p.id == settings.last_profile:
				current = p
	apply_settings()


func _setup_inputs() -> void:
	var map := {
		"cam_left": [KEY_A, KEY_Q, KEY_LEFT],
		"cam_right": [KEY_D, KEY_RIGHT],
		"cam_forward": [KEY_W, KEY_Z, KEY_UP],
		"cam_back": [KEY_S, KEY_DOWN],
		"cam_up": [KEY_E, KEY_SPACE],
		"cam_down": [KEY_C, KEY_CTRL],
		"cam_fast": [KEY_SHIFT],
	}
	for action in map:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		for key in map[action]:
			var ev := InputEventKey.new()
			ev.physical_keycode = key
			InputMap.action_add_event(action, ev)


# --- Profils ---------------------------------------------------------------

func has_profile() -> bool:
	return not current.is_empty()


func new_profile(pseudo: String, nation: String) -> Dictionary:
	var p := {
		"id": "p%d" % Time.get_unix_time_from_system() + str(randi() % 1000),
		"name": pseudo.strip_edges().substr(0, 20),
		"nation": nation,
		"created": Time.get_datetime_string_from_system(),
		"xp": 0,
		"solde": 300,
		"cards": {},
		"progress": {},
		"best": {},
		"soldier": {
			"era": "e08",
			"nation": nation,
			"uniform": "",
			"headgear": "",
			"weapon": "",
			"skin": 1,
			"name": pseudo.strip_edges().substr(0, 20),
		},
		"stats": {"battles_won": 0, "battles_lost": 0, "crates": 0, "enemies": 0},
	}
	profiles.append(p)
	select_profile(p.id)
	return p


func select_profile(id: String) -> void:
	for p in profiles:
		if p.id == id:
			current = p
			settings.last_profile = id
			save_settings()
			save()
			profile_changed.emit()
			return


func delete_profile(id: String) -> void:
	profiles = profiles.filter(func(p): return p.id != id)
	if current.get("id", "") == id:
		current = {}
		settings.last_profile = ""
		save_settings()
	save()
	profile_changed.emit()


# --- Progression -------------------------------------------------------------

func xp() -> int:
	return int(current.get("xp", 0))


func solde() -> int:
	return int(current.get("solde", 0))


func rank_index(xp_value: int = -1) -> int:
	if xp_value < 0:
		xp_value = xp()
	var idx := 0
	for i in RANKS.size():
		if xp_value >= RANKS[i][1]:
			idx = i
	return idx


func rank_name(xp_value: int = -1) -> String:
	return RANKS[rank_index(xp_value)][0]


## Renvoie [xp dans le grade, xp nécessaire pour le grade suivant] (0 si grade max).
func rank_progress() -> Array:
	var i := rank_index()
	if i >= RANKS.size() - 1:
		return [1, 1]
	var lo: int = RANKS[i][1]
	var hi: int = RANKS[i + 1][1]
	return [xp() - lo, hi - lo]


func add_xp(amount: int, reason: String = "") -> void:
	if not has_profile() or amount <= 0:
		return
	var before := rank_index()
	current.xp = xp() + amount
	xp_gained.emit(amount, reason)
	var after := rank_index()
	if after > before:
		rank_up.emit(RANKS[after][0])
	save()


func add_solde(amount: int) -> void:
	if not has_profile():
		return
	current.solde = max(0, solde() + amount)
	solde_changed.emit(current.solde)
	save()


func spend(amount: int) -> bool:
	if solde() < amount:
		return false
	add_solde(-amount)
	return true


## Récompense standard d'une activité : XP + solde, avec un message.
func reward(xp_amount: int, solde_amount: int, reason: String) -> void:
	add_solde(solde_amount)
	add_xp(xp_amount, reason)


func progress(era_id: String) -> Dictionary:
	if not has_profile():
		return {}
	if not current.progress.has(era_id):
		current.progress[era_id] = {}
	return current.progress[era_id]


## Marque une étape d'époque (history, quiz, battle, workshop, state, daily).
## Garde toujours le meilleur score.
func set_step(era_id: String, step: String, score: int) -> bool:
	var p := progress(era_id)
	var improved: bool = score > int(p.get(step, -1))
	if improved:
		p[step] = score
		save()
	return improved


func step_score(era_id: String, step: String) -> int:
	return int(progress(era_id).get(step, -1))


## Pourcentage de complétion d'une époque (6 étapes, score max 3 étoiles chacune).
func era_completion(era_id: String) -> float:
	var p := progress(era_id)
	var total := 0.0
	for step in ["history", "quiz", "battle", "workshop", "state", "daily"]:
		total += clamp(float(p.get(step, 0)), 0.0, 3.0) / 3.0
	return total / 6.0


func set_best(key: String, value: float, lower_is_better := false) -> bool:
	if not has_profile():
		return false
	var b: Dictionary = current.best
	var improved: bool = not b.has(key) or (value < float(b[key]) if lower_is_better else value > float(b[key]))
	if improved:
		b[key] = value
		save()
	return improved


func best(key: String, fallback = null):
	if not has_profile():
		return fallback
	return current.best.get(key, fallback)


func stat_add(key: String, amount: int = 1) -> void:
	if not has_profile():
		return
	current.stats[key] = int(current.stats.get(key, 0)) + amount
	save()


# --- Cartes à collectionner --------------------------------------------------

func card_count(card_id: String) -> int:
	if not has_profile():
		return 0
	return int(current.cards.get(card_id, 0))


func add_card(card_id: String) -> bool:
	var is_new := card_count(card_id) == 0
	current.cards[card_id] = card_count(card_id) + 1
	save()
	return is_new


# --- Sauvegarde ----------------------------------------------------------------

func save() -> void:
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify({"version": 1, "profiles": profiles}, "\t"))


func _load_profiles() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var data = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
	if data is Dictionary and data.get("profiles") is Array:
		profiles = data.profiles


func save_settings() -> void:
	var f := FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(settings, "\t"))


func _load_settings() -> void:
	if not FileAccess.file_exists(SETTINGS_PATH):
		return
	var data = JSON.parse_string(FileAccess.get_file_as_string(SETTINGS_PATH))
	if data is Dictionary:
		for k in data:
			settings[k] = data[k]


func apply_settings() -> void:
	var master := AudioServer.get_bus_index("Master")
	AudioServer.set_bus_volume_db(master, linear_to_db(max(0.0001, float(settings.volume_master))))
	if DisplayServer.get_name() != "headless":
		var mode := DisplayServer.WINDOW_MODE_FULLSCREEN if settings.fullscreen else DisplayServer.WINDOW_MODE_WINDOWED
		if DisplayServer.window_get_mode() != mode:
			DisplayServer.window_set_mode(mode)
