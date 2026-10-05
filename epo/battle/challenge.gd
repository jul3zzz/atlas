class_name Challenge
extends RefCounted
## Codes de défi partageables : l'armée ennemie + le budget, encodés dans un texte.
## Exemple : EPO1-eyJ2IjoxLC... (à copier-coller à un ami).

const PREFIX := "EPO1-"


static func encode(name: String, era: String, budget: int, red: Array, allowed: Array = []) -> String:
	var units := []
	for u in red:
		units.append([u.id, snappedf(u.global_position.x, 0.1), snappedf(u.global_position.z, 0.1)])
	var data := {"v": 1, "n": name.substr(0, 40), "e": era, "b": budget, "r": units, "u": allowed}
	return PREFIX + Marshalls.utf8_to_base64(JSON.stringify(data))


## Renvoie un scénario de bataille, ou {} si le code est invalide.
static func decode(code: String) -> Dictionary:
	var c := code.strip_edges().replace(" ", "").replace("\n", "")
	if not c.begins_with(PREFIX):
		return {}
	var raw := Marshalls.base64_to_utf8(c.substr(PREFIX.length()))
	var data = JSON.parse_string(raw)
	if not data is Dictionary or not data.get("r") is Array:
		return {}
	var enemy := []
	for entry in data.r:
		if entry is Array and entry.size() == 3 and Content.units.has(String(entry[0])):
			enemy.append({"unit": String(entry[0]), "x": clamp(float(entry[1]), -45.0, 45.0), "z": clamp(float(entry[2]), -43.0, -4.5)})
	if enemy.is_empty() or enemy.size() > 250:
		return {}
	var era := String(data.get("e", "e08"))
	return {
		"id": "defi",
		"era": era if Content.eras_by_id.has(era) else "e08",
		"name": "Défi : " + String(data.get("n", "sans nom")),
		"player_side": "Toi",
		"enemy_side": "L'armée de ton ami",
		"budget": clamp(int(data.get("b", 1500)), 100, 100000),
		"units": data.get("u", []),
		"enemy": enemy,
		"intro": "Un ami t'a lancé ce défi. Compose ton armée avec le budget imposé et écrase la sienne !",
		"debrief": "Défi relevé ! Renvoie-lui un code de défi à ton tour depuis le bac à sable.",
	}
