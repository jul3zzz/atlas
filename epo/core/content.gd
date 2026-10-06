extends Node
## Charge tout le contenu du jeu depuis les fichiers JSON de res://data.
## Pour ajouter du contenu (époques, unités, cartes, quiz...), on modifie les JSON :
## aucune ligne de code à toucher.

var eras: Array = []
var eras_by_id: Dictionary = {}
var units: Dictionary = {}
var battles: Array = []
var cards: Array = []
var cards_by_id: Dictionary = {}
var weapons: Dictionary = {}
var weapon_order: Array = []
var state_decks: Dictionary = {}
var daily: Dictionary = {}
var economy: Dictionary = {}
var videos: Array = []
var briefs: Array = []
var design_catalog: Dictionary = {}
var design_stats: Array = []
var _history_cache: Dictionary = {}


func _ready() -> void:
	reload()


func reload() -> void:
	eras = _load("res://data/eras.json", [])
	eras_by_id.clear()
	for e in eras:
		eras_by_id[e.id] = e
	units = _load("res://data/units.json", {})
	for id in units:
		units[id]["id"] = id
	battles = _load("res://data/battles.json", [])
	cards = _load("res://data/cards.json", [])
	cards_by_id.clear()
	for c in cards:
		cards_by_id[c.id] = c
	weapons.clear()
	weapon_order.clear()
	var dir := DirAccess.open("res://data/weapons")
	if dir:
		var files := Array(dir.get_files())
		files.sort()
		for f in files:
			if f.ends_with(".json"):
				var w = _load("res://data/weapons/" + f, null)
				if w is Dictionary:
					weapons[w.id] = w
					weapon_order.append(w.id)
	state_decks = _load("res://data/state.json", {})
	daily = _load("res://data/daily.json", {})
	economy = _load("res://data/economy.json", {})
	videos = _load("res://data/videos.json", [])
	var design: Dictionary = _load("res://data/briefs.json", {})
	briefs = design.get("briefs", [])
	design_catalog = design.get("catalog", {})
	design_stats = design.get("stats", [])
	_history_cache.clear()


func era(id: String) -> Dictionary:
	return eras_by_id.get(id, {})


func era_index(id: String) -> int:
	for i in eras.size():
		if eras[i].id == id:
			return i
	return -1


func history(era_id: String) -> Dictionary:
	if not _history_cache.has(era_id):
		_history_cache[era_id] = _load("res://data/history/%s.json" % era_id, {})
	return _history_cache[era_id]


func units_for_era(era_id: String) -> Array:
	var out := []
	for id in units:
		if units[id].get("era", "") == era_id:
			out.append(units[id])
	out.sort_custom(func(a, b): return a.get("cost", 0) < b.get("cost", 0))
	return out


func battles_for_era(era_id: String) -> Array:
	return battles.filter(func(b): return b.get("era", "") == era_id)


func battle(id: String) -> Dictionary:
	for b in battles:
		if b.id == id:
			return b
	return {}


func cards_for_era(era_id: String) -> Array:
	return cards.filter(func(c): return c.get("era", "") == era_id)


func weapons_for_era(era_id: String) -> Array:
	var out := []
	for id in weapon_order:
		if weapons[id].get("era", "") == era_id:
			out.append(weapons[id])
	return out


func videos_for_era(era_id: String) -> Array:
	return videos.filter(func(v): return v.get("era", "") == era_id)


func _load(path: String, fallback):
	if not FileAccess.file_exists(path):
		return fallback
	var txt := FileAccess.get_file_as_string(path)
	var json := JSON.new()
	var err := json.parse(txt)
	if err != OK:
		push_error("JSON invalide dans %s ligne %d : %s" % [path, json.get_error_line(), json.get_error_message()])
		return fallback
	return json.data
