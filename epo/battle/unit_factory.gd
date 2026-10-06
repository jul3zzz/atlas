class_name UnitFactory
extends RefCounted
## Construit le modèle 3D d'une unité à partir de sa fiche (data/units.json).


static func build_model(u: Dictionary, team_color: Color) -> Node3D:
	var m: Dictionary = u.get("model", {})
	if m.has("vehicle"):
		var crew: Dictionary = m.get("crew", {}).duplicate()
		if not crew.is_empty():
			crew["team"] = team_color
			if not crew.has("skin"):
				crew["skin"] = randi() % 4
		var v := Models.vehicle(String(m.vehicle), Models.col(m.get("color"), Color("555555")), Models.col(m.get("accent"), Color.WHITE), crew)
		# Fanion de l'équipe pour reconnaître les véhicules.
		var pole_h := 3.2 if String(m.vehicle) not in ["drone", "helicopter"] else 0.0
		if pole_h > 0.0:
			var flag := Node3D.new()
			flag.position = Vector3(0.0, 0.0, 0.0)
			v.add_child(flag)
			flag.add_child(Models.cyl(0.025, 0.025, pole_h, Models.mat(Color("2a2a2a")), Vector3(0.7, pole_h / 2, 1.0)))
			flag.add_child(Models.box(Vector3(0.03, 0.4, 0.6), Models.mat(team_color, 0.6, 0.0, 0.3), Vector3(0.7, pole_h - 0.22, 1.3)))
		else:
			v.add_child(Models.sphere(0.12, Models.mat(team_color, 0.5, 0.0, 1.5), Vector3(0, 0.25, 0)))
		return v
	var cfg := m.duplicate()
	cfg["team"] = team_color
	if not cfg.has("skin"):
		cfg["skin"] = randi() % 4
	return Models.soldier(cfg)
