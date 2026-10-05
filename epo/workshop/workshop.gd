extends Node3D
## Atelier d'armes : histoire, vue éclatée, fonctionnement animé, démontage chronométré.
## Paramètres Nav : {"weapon": id, "era": id}

var weapon_id := ""
var back_era := ""
var data: Dictionary
var weapon: WeaponModel
var holder: Node3D
var cam: Camera3D
var mode := "story"

# Caméra orbitale
var yaw := 0.3
var pitch := -0.2
var dist := 1.9
var target := Vector3(0, 1.1, 0)
var _yaw := 0.3
var _pitch := -0.2
var _dist := 1.9
var _rot_drag := false

# Interface
var ui: Control
var content: VBoxContainer
var info_panel: PanelContainer
var info_title: Label
var info_text: RichTextLabel
var tab_buttons: Dictionary = {}
var hovered := ""

# Fonctionnement
var cycle_t := 0.0
var cycle_playing := true
var cycle_speed := 0.35
var cycle_objects: Array = []
var step_label: RichTextLabel
var step_index := -1

# Démontage / inspection
var strip_state := "idle"   # idle, strip, assemble, done
var strip_index := 0
var strip_errors := 0
var strip_time := 0.0
var strip_label: RichTextLabel
var timer_label: Label
var inspected: Dictionary = {}
var _hover_time := 0.0


func _ready() -> void:
	weapon_id = String(Nav.params.get("weapon", "ak47"))
	back_era = String(Nav.params.get("era", ""))
	data = Content.weapons.get(weapon_id, {})
	if data.is_empty() and not Content.weapons.is_empty():
		data = Content.weapons.values()[0]
		weapon_id = data.id
	Sfx.music("ambient")
	_build_world()
	_build_ui()
	_set_mode("story")


func _era() -> String:
	return String(data.get("era", Nav.params.get("era", "e01")))


# --- Monde 3D --------------------------------------------------------------------

func _build_world() -> void:
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color("15130f")
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.55, 0.5, 0.42)
	e.ambient_light_energy = 0.55
	e.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	e.glow_enabled = true
	e.glow_intensity = 0.3
	env.environment = e
	add_child(env)
	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-45, 25, 0)
	key.light_energy = 0.75
	key.shadow_enabled = true
	add_child(key)
	var lamp := SpotLight3D.new()
	lamp.position = Vector3(0.3, 2.2, 0.8)
	lamp.light_energy = 1.4
	lamp.spot_range = 4.0
	lamp.spot_angle = 40.0
	lamp.light_color = Color(1.0, 0.88, 0.7)
	lamp.shadow_enabled = true
	add_child(lamp)
	lamp.look_at(Vector3(0, 1.0, 0))
	var fill := OmniLight3D.new()
	fill.position = Vector3(-1.2, 1.4, 1.0)
	fill.light_energy = 0.6
	fill.omni_range = 4.0
	fill.light_color = Color(0.7, 0.8, 1.0)
	add_child(fill)
	# Établi et mur de l'atelier
	add_child(Models.box(Vector3(2.4, 0.08, 1.2), Models.mat(Color("3d2817"), 0.8), Vector3(0, 0.66, 0)))
	add_child(Models.box(Vector3(2.4, 0.66, 0.06), Models.mat(Color("3a2616")), Vector3(0, 0.33, 0.55)))
	add_child(Models.box(Vector3(6, 4, 0.1), Models.mat(Color("2a2a24"), 0.95), Vector3(0, 2.0, -1.2)))
	for i in 6:
		add_child(Models.box(Vector3(0.05, 4, 0.12), Models.mat(Color("1d1c18")), Vector3(-2.5 + i, 2.0, -1.14)))
	add_child(Models.box(Vector3(6, 0.05, 4), Models.mat(Color("22201a"), 0.95), Vector3(0, 0.0, 0)))
	# Support de l'arme
	add_child(Models.box(Vector3(0.06, 0.28, 0.06), Models.mat(Color("2a2a2a"), 0.6, 0.5), Vector3(-0.1, 0.84, 0)))
	add_child(Models.box(Vector3(0.3, 0.03, 0.2), Models.mat(Color("2a2a2a"), 0.6, 0.5), Vector3(-0.1, 0.72, 0)))
	holder = Node3D.new()
	holder.position = Vector3(0, 1.05, 0)
	add_child(holder)
	weapon = WeaponModel.new()
	weapon.build(data)
	var size := float(data.get("camera", {}).get("size", 1.0))
	var k := 1.0 / maxf(size, 0.1)
	weapon.scale = Vector3.ONE * k
	var c := WeaponModel._v3(data.get("camera", {}).get("center", [0, 0, 0]))
	weapon.position = -c * k
	holder.add_child(weapon)
	cam = Camera3D.new()
	cam.fov = 40.0
	cam.near = 0.02
	add_child(cam)
	cam.current = true
	_update_cam(1.0)


func _update_cam(k: float) -> void:
	_yaw = lerp_angle(_yaw, yaw, k)
	_pitch = lerpf(_pitch, pitch, k)
	_dist = lerpf(_dist, dist, k)
	var b := Basis(Vector3.UP, _yaw) * Basis(Vector3.RIGHT, _pitch)
	cam.global_position = target + b * Vector3(0, 0, _dist)
	cam.look_at(target)
	# Décale l'image vers la droite pour ne pas cacher l'arme derrière le panneau de gauche.
	cam.h_offset = -0.16 * _dist


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		match event.button_index:
			MOUSE_BUTTON_WHEEL_UP:
				dist = clamp(dist * 0.9, 0.4, 4.0)
			MOUSE_BUTTON_WHEEL_DOWN:
				dist = clamp(dist * 1.1, 0.4, 4.0)
			MOUSE_BUTTON_RIGHT:
				_rot_drag = event.pressed
			MOUSE_BUTTON_LEFT:
				if event.pressed:
					if hovered != "":
						_on_part_clicked(hovered)
					else:
						_rot_drag = true
				else:
					_rot_drag = false
	elif event is InputEventMouseMotion and _rot_drag:
		yaw -= event.relative.x * 0.007
		pitch = clamp(pitch - event.relative.y * 0.005, -1.3, 1.1)


func _process(delta: float) -> void:
	_update_cam(clamp(delta * 10.0, 0.0, 1.0))
	_pick()
	if mode == "cycle" and data.has("cycle"):
		if cycle_playing:
			cycle_t = fmod(cycle_t + delta * cycle_speed / float(data.cycle.get("duration", 4.0)), 1.0)
		_apply_cycle(cycle_t)
	if mode == "strip" and strip_state in ["strip", "assemble"]:
		strip_time += delta
		timer_label.text = "Temps : %.1f s   ·   erreurs : %d" % [strip_time, strip_errors]
	if mode == "inspect" and hovered != "":
		_hover_time += delta
		if _hover_time > 0.5 and not inspected.has(hovered):
			inspected[hovered] = true
			Sfx.play("part", -4.0)
			_refresh_inspect()


func _pick() -> void:
	var vp := get_viewport()
	var mp := vp.get_mouse_position()
	var over_ui := vp.gui_get_hovered_control() != null and vp.gui_get_hovered_control() != ui
	var id := ""
	if not over_ui:
		var from := cam.project_ray_origin(mp)
		var to := from + cam.project_ray_normal(mp) * 10.0
		var q := PhysicsRayQueryParameters3D.create(from, to, 8)
		var hit := get_world_3d().direct_space_state.intersect_ray(q)
		if hit and hit.collider and hit.collider.has_meta("part"):
			id = String(hit.collider.get_meta("part"))
	if id != hovered:
		hovered = id
		_hover_time = 0.0
		weapon.highlight(id)
		_show_part_info(id)


func _show_part_info(id: String) -> void:
	if id == "" or not weapon.part_data.has(id):
		info_panel.visible = false
		return
	var p: Dictionary = weapon.part_data[id]
	info_title.text = String(p.get("name", id))
	info_text.text = UI.nbsp(String(p.get("desc", "")))
	info_panel.visible = true


# --- Modes -------------------------------------------------------------------------

func _set_mode(m: String) -> void:
	mode = m
	for k in tab_buttons:
		tab_buttons[k].button_pressed = k == m
	for c in content.get_children():
		c.queue_free()
	_clear_cycle_objects()
	weapon.removed.clear()
	weapon.reset_home()
	strip_state = "idle"
	match m:
		"story":
			_story()
		"explode":
			_explode_panel()
		"cycle":
			_cycle_panel()
		"strip":
			_strip_panel()
		"inspect":
			_inspect_panel()
		"specs":
			_specs()


func _story() -> void:
	content.add_child(UI.rich(String(data.get("story", "")), true, 18))
	for f in data.get("facts", []):
		var box := UI.panel(10, Color("2e2a1c"), UI.GOLD_DARK)
		box.add_child(UI.rich("[color=#d4ac2b][b]Le saviez-vous ?[/b][/color] " + String(f), true, 17))
		content.add_child(box)
	Game.set_step(_era(), "workshop", 1)


func _explode_panel() -> void:
	content.add_child(UI.wrap_label("Fais glisser le curseur pour écarter les pièces. Survole une pièce pour connaître son rôle.", 17, UI.MUTED))
	var s := HSlider.new()
	s.min_value = 0.0
	s.max_value = 1.0
	s.step = 0.01
	s.value = 1.0
	s.custom_minimum_size.y = 28
	s.value_changed.connect(func(v): weapon.set_explode(v))
	content.add_child(s)
	var row := UI.hbox(8)
	content.add_child(row)
	row.add_child(UI.button("Assembler", func():
		var tw := create_tween()
		tw.tween_method(func(v): s.value = v, s.value, 0.0, 0.8), 17))
	row.add_child(UI.button("Éclater", func():
		var tw := create_tween()
		tw.tween_method(func(v): s.value = v, s.value, 1.0, 0.8), 17))
	content.add_child(UI.label("PIÈCES", 17, UI.GOLD, UI.font_ui_bold))
	for p in data.get("parts", []):
		var b := UI.button(String(p.name), func(): _show_part_info(String(p.id)), 16)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.mouse_entered.connect(func(): weapon.highlight(String(p.id)))
		content.add_child(b)
	weapon.set_explode(0.0)
	var tw := create_tween()
	tw.tween_method(func(v): weapon.set_explode(v), 0.0, 1.0, 1.0).set_delay(0.2)


func _cycle_panel() -> void:
	if not data.has("cycle"):
		content.add_child(UI.wrap_label("Pas d'animation de fonctionnement pour cette pièce.", 18, UI.MUTED))
		return
	content.add_child(UI.wrap_label("Le cycle est montré au ralenti. Le couvercle de culasse est rendu invisible pour voir l'intérieur.", 16, UI.MUTED))
	step_label = UI.rich("", true, 19)
	var box := UI.panel(14, Color("2e2a1c"), UI.GOLD_DARK)
	box.add_child(step_label)
	box.custom_minimum_size.y = 170
	content.add_child(box)
	var row := UI.hbox(8)
	content.add_child(row)
	var pb := UI.button("❚❚ Pause", Callable(), 17)
	pb.pressed.connect(func():
		cycle_playing = not cycle_playing
		pb.text = "❚❚ Pause" if cycle_playing else "▶ Lecture")
	row.add_child(pb)
	row.add_child(UI.button("Étape suivante ▶", func():
		cycle_playing = false
		pb.text = "▶ Lecture"
		var steps: Array = data.cycle.get("steps", [])
		var nxt := 0.0
		for s in steps:
			if float(s[0]) > cycle_t + 0.001:
				nxt = float(s[0])
				break
		cycle_t = nxt + 0.03, 17))
	content.add_child(UI.label("Vitesse", 16, UI.MUTED))
	var sp := HSlider.new()
	sp.min_value = 0.05
	sp.max_value = 1.0
	sp.step = 0.05
	sp.value = cycle_speed
	sp.custom_minimum_size.y = 24
	sp.value_changed.connect(func(v): cycle_speed = v)
	content.add_child(sp)
	var steps_all := ""
	for s in data.cycle.get("steps", []):
		steps_all += "• " + String(s[1]) + "\n"
	content.add_child(UI.label("TOUTES LES ÉTAPES", 16, UI.GOLD, UI.font_ui_bold))
	content.add_child(UI.rich(steps_all, true, 16))
	# On cache les pièces qui masquent le mécanisme.
	for id in data.cycle.get("hide", ["dust_cover", "gas_tube"]):
		if weapon.parts.has(id):
			weapon.parts[id].visible = false
	_spawn_cycle_objects()
	cycle_t = 0.0
	step_index = -1
	Game.set_step(_era(), "workshop", 2)


func _strip_panel() -> void:
	content.add_child(UI.wrap_label("Démontage de campagne : clique sur les pièces dans le bon ordre, puis remonte l'arme dans l'ordre inverse. Le plus vite possible, avec le moins d'erreurs possible !", 17, UI.MUTED))
	timer_label = UI.label("Temps : 0.0 s", 26, UI.GOLD, UI.font_ui_bold)
	content.add_child(timer_label)
	strip_label = UI.rich("", true, 18)
	var box := UI.panel(14, Color("2e2a1c"), UI.GOLD_DARK)
	box.add_child(strip_label)
	content.add_child(box)
	var best = Game.best("strip_" + weapon_id, null)
	if best != null:
		content.add_child(UI.label("Ton record : %.1f s" % float(best), 17, UI.MUTED))
	content.add_child(UI.primary_button("▶ Commencer", _strip_start, 21))
	content.add_child(UI.button("Indice", func():
		var order: Array = data.get("strip", [])
		var expected := _strip_expected()
		if expected != "":
			strip_label.text = "[color=#d4ac2b]Indice :[/color] la prochaine pièce est « %s »." % weapon.part_data[expected].name
			strip_time += 5.0, 17))
	strip_label.text = "Prêt ? Le chronomètre démarre quand tu cliques sur « Commencer »."


func _inspect_panel() -> void:
	content.add_child(UI.wrap_label("Inspection : survole chaque pièce pendant une demi-seconde pour l'examiner. Toutes les pièces examinées = 3 étoiles.", 17, UI.MUTED))
	strip_label = UI.rich("", true, 18)
	content.add_child(strip_label)
	weapon.set_explode(0.6)
	_refresh_inspect()


func _refresh_inspect() -> void:
	if strip_label == null or mode != "inspect":
		return
	var total: int = weapon.parts.size()
	var txt := "[b]%d / %d pièces examinées[/b]\n" % [inspected.size(), total]
	for id in weapon.parts:
		txt += ("[color=#7cb855]✔ %s[/color]\n" if inspected.has(id) else "○ %s\n") % weapon.part_data[id].name
	strip_label.text = txt
	if inspected.size() >= total and total > 0:
		if Game.set_step(_era(), "workshop", 3):
			Game.reward(120, 50, "Inspection complète")
			Sfx.play("victory")


func _specs() -> void:
	var t := "[b]%s[/b]\n%s\n\n" % [data.get("full_name", data.get("name", "")), data.get("type", "")]
	t += "Pays : %s\nAnnée : %s\nConcepteur : %s\n\n" % [data.get("country", "—"), data.get("year", "—"), data.get("designer", "—")]
	for s in data.get("specs", []):
		t += "[b]%s :[/b] %s\n" % [s[0], s[1]]
	content.add_child(UI.rich(t, false, 19))


# --- Démontage -----------------------------------------------------------------------

func _strip_expected() -> String:
	var order: Array = data.get("strip", [])
	if strip_state == "strip" and strip_index < order.size():
		return order[strip_index]
	if strip_state == "assemble" and strip_index < order.size():
		return order[order.size() - 1 - strip_index]
	return ""


func _strip_start() -> void:
	weapon.removed.clear()
	weapon.reset_home()
	strip_state = "strip"
	strip_index = 0
	strip_errors = 0
	strip_time = 0.0
	Sfx.play("whistle", -8.0)
	strip_label.text = "[b]DÉMONTAGE[/b] — clique sur la première pièce à retirer."


func _on_part_clicked(id: String) -> void:
	if mode != "strip" or strip_state not in ["strip", "assemble"]:
		return
	var order: Array = data.get("strip", [])
	var expected := _strip_expected()
	if id == expected:
		Sfx.play("mech" if strip_state == "strip" else "part")
		if strip_state == "strip":
			weapon.removed[id] = true
			weapon.tween_part(id, true, 0.5)
			strip_label.text = "[color=#7cb855]✔ %s[/color]\n%s" % [weapon.part_data[id].name, data.get("strip_hints", {}).get(id, "")]
		else:
			weapon.removed.erase(id)
			weapon.tween_part(id, false, 0.5)
			strip_label.text = "[color=#7cb855]✔ %s remis en place.[/color]" % weapon.part_data[id].name
		strip_index += 1
		if strip_index >= order.size():
			if strip_state == "strip":
				strip_state = "assemble"
				strip_index = 0
				strip_label.text += "\n\n[b]Démontage terminé ![/b] Maintenant, [b]REMONTE[/b] l'arme dans l'ordre inverse."
				Sfx.play("confirm")
			else:
				_strip_done()
	else:
		strip_errors += 1
		strip_time += 3.0
		Sfx.play("error")
		if id in order:
			var hint := String(data.get("strip_hints", {}).get(expected, "")) if strip_state == "strip" else "Pense à l'ordre inverse du démontage."
			strip_label.text = "[color=#d0493a]✖ Pas encore : %s ![/color] (+3 s)\n%s" % [weapon.part_data[id].name, hint if strip_errors >= 2 else ""]
		else:
			strip_label.text = "[color=#d0493a]✖ %s ne se démonte pas lors du démontage de campagne.[/color] (+3 s)" % weapon.part_data[id].name


func _strip_done() -> void:
	strip_state = "done"
	var n: int = data.get("strip", []).size()
	var par := n * 2 * 2.5
	var stars := 1
	if strip_errors <= 2:
		stars = 2
	if strip_errors == 0 and strip_time <= par:
		stars = 3
	var record := Game.set_best("strip_" + weapon_id, strip_time, true)
	var improved := Game.set_step(_era(), "workshop", stars)
	Game.reward(60 + 30 * stars if improved else 20, 20 + 10 * stars, "Démontage")
	Sfx.play("victory")
	strip_label.text = "[b]Arme remontée ![/b]\nTemps : %.1f s · Erreurs : %d\n[font_size=34][color=#d4ac2b]%s[/color][/font_size]%s\n[color=#a8a48c]3 étoiles : aucune erreur et moins de %d s.[/color]" % [strip_time, strip_errors, UI.stars(stars), "\n[color=#7cb855]Nouveau record ![/color]" if record else "", int(par)]


# --- Cycle animé --------------------------------------------------------------------

func _clear_cycle_objects() -> void:
	for o in cycle_objects:
		if is_instance_valid(o[0]):
			o[0].queue_free()
	cycle_objects.clear()
	for id in weapon.parts:
		weapon.parts[id].visible = true


func _spawn_cycle_objects() -> void:
	for o in data.cycle.get("objects", []):
		var n := Node3D.new()
		match String(o.kind):
			"bullet":
				n.add_child(Models.cyl(0.0035, 0.004, 0.026, Models.metal_mat(Color("b8733a")), Vector3.ZERO, Vector3(0, 0, PI / 2), 10))
			"case":
				n.add_child(Models.cyl(0.0055, 0.0055, 0.038, Models.metal_mat(Color("c9a33a")), Vector3.ZERO, Vector3(0, 0, PI / 2), 10))
			"round":
				n.add_child(Models.cyl(0.0055, 0.0055, 0.038, Models.metal_mat(Color("c9a33a")), Vector3.ZERO, Vector3(0, 0, PI / 2), 10))
				n.add_child(Models.cyl(0.0, 0.0045, 0.016, Models.metal_mat(Color("b8733a")), Vector3(0.026, 0, 0), Vector3(0, 0, -PI / 2), 10))
			"gas":
				n.add_child(Models.sphere(0.012, Models.mat(Color(1.0, 0.55, 0.15), 0.5, 0.0, 4.0)))
			"flash":
				n.add_child(Models.sphere(0.03, Models.mat(Color(1.0, 0.8, 0.3), 0.5, 0.0, 6.0), Vector3.ZERO, Vector3(1.6, 1, 1)))
			"spark":
				n.add_child(Models.sphere(0.01, Models.mat(Color(1.0, 0.9, 0.4), 0.5, 0.0, 6.0)))
			"stone":
				n.add_child(Models.sphere(0.03, Models.mat(Color("8a8579"))))
			_:
				n.add_child(Models.sphere(0.01, Models.mat(Color.WHITE)))
		n.visible = false
		weapon.add_child(n)
		cycle_objects.append([n, o])


func _key_interp(keys: Array, t: float) -> Vector3:
	if keys.is_empty():
		return Vector3.ZERO
	var prev: Array = keys[0]
	for k in keys:
		if float(k[0]) >= t:
			var t0 := float(prev[0])
			var t1 := float(k[0])
			var a := Vector3(float(prev[1]), float(prev[2]), float(prev[3]))
			var b := Vector3(float(k[1]), float(k[2]), float(k[3]))
			if t1 - t0 < 0.0001:
				return b
			var f: float = clamp((t - t0) / (t1 - t0), 0.0, 1.0)
			return a.lerp(b, f * f * (3.0 - 2.0 * f))
		prev = k
	return Vector3(float(prev[1]), float(prev[2]), float(prev[3]))


func _path_interp(path: Array, f: float) -> Vector3:
	if path.size() == 1:
		return WeaponModel._v3(path[0])
	var segs := path.size() - 1
	var x: float = clamp(f, 0.0, 1.0) * segs
	var i: int = min(int(x), segs - 1)
	return WeaponModel._v3(path[i]).lerp(WeaponModel._v3(path[i + 1]), x - i)


func _apply_cycle(t: float) -> void:
	var c: Dictionary = data.cycle
	for id in c.get("moves", {}):
		if weapon.parts.has(id):
			var home: Transform3D = weapon.home[id]
			weapon.parts[id].position = home.origin + _key_interp(c.moves[id], t)
	for id in c.get("rotations", {}):
		if weapon.parts.has(id):
			var base := WeaponModel._v3(weapon.part_data[id].get("rot", [0, 0, 0]))
			weapon.parts[id].rotation_degrees = base + _key_interp(c.rotations[id], t)
	for id in c.get("scales", {}):
		if weapon.parts.has(id):
			weapon.parts[id].scale = _key_interp(c.scales[id], t)
	for pair in cycle_objects:
		var n: Node3D = pair[0]
		var o: Dictionary = pair[1]
		var t0 := float(o.t0)
		var t1 := float(o.t1)
		n.visible = t >= t0 and t <= t1
		if n.visible:
			var f := (t - t0) / maxf(0.0001, t1 - t0)
			n.position = _path_interp(o.get("path", [[0, 0, 0]]), f)
			if o.kind == "case":
				n.rotation.y = f * 12.0
	var steps: Array = c.get("steps", [])
	var idx := -1
	for i in steps.size():
		if t >= float(steps[i][0]):
			idx = i
	if idx != step_index and step_label:
		step_index = idx
		if idx >= 0:
			step_label.text = UI.nbsp("[b]Étape %d / %d[/b]\n%s" % [idx + 1, steps.size(), steps[idx][1]])
			if idx == 0:
				Sfx.play(String(c.get("sound", "rifle")), -10.0)


# --- Interface ----------------------------------------------------------------------

func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	ui = UI.root_control()
	layer.add_child(ui)
	ui.add_child(UI.top_bar("Atelier · " + String(data.get("name", "")), func(): Nav.goto("workshop_menu", {"era": back_era if back_era != "" else _era()})))
	var left := UI.panel(16, Color(UI.PANEL, 0.94))
	left.anchor_top = 0.0
	left.anchor_bottom = 1.0
	left.offset_top = 74
	left.offset_bottom = -12
	left.offset_left = 12
	left.offset_right = 452
	ui.add_child(left)
	var v := UI.vbox(10)
	left.add_child(v)
	var name_l := UI.title(String(data.get("name", "")), 34)
	v.add_child(name_l)
	v.add_child(UI.label("%s · %s · %s" % [data.get("type", ""), data.get("country", ""), data.get("year", "")], 16, UI.MUTED))
	var tabs := GridContainer.new()
	tabs.columns = 3
	tabs.add_theme_constant_override("h_separation", 6)
	tabs.add_theme_constant_override("v_separation", 6)
	v.add_child(tabs)
	var modes := [["story", "Histoire"], ["explode", "Vue éclatée"]]
	if data.has("cycle"):
		modes.append(["cycle", "Fonctionnement"])
	if data.get("strip", []).size() > 0:
		modes.append(["strip", "Démontage"])
	else:
		modes.append(["inspect", "Inspection"])
	modes.append(["specs", "Fiche"])
	for mm in modes:
		var b := UI.button(mm[1], func(): _set_mode(mm[0]), 16)
		b.toggle_mode = true
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tab_buttons[mm[0]] = b
		tabs.add_child(b)
	content = UI.vbox(10)
	v.add_child(UI.scroll(content))

	info_panel = UI.panel(14, Color("0f120b", 0.92), UI.GOLD_DARK)
	info_panel.custom_minimum_size.x = 620
	UI.pin(info_panel, 0.6, 1.0, 0, -16)
	info_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var iv := UI.vbox(4)
	info_panel.add_child(iv)
	info_title = UI.label("", 22, UI.GOLD, UI.font_ui_bold)
	iv.add_child(info_title)
	info_text = UI.rich("", true, 17)
	info_text.custom_minimum_size.x = 590
	iv.add_child(info_text)
	info_panel.visible = false
	ui.add_child(info_panel)
	var help := UI.label("Clic gauche sur une pièce : interagir · Glisser : tourner · Molette : zoom", 15, UI.MUTED)
	UI.pin(help, 1.0, 0.0, -16, 84)
	ui.add_child(help)


func test_action(a: String) -> void:
	match a:
		"explode":
			_set_mode("explode")
		"cycle":
			_set_mode("cycle")
			cycle_t = 0.35
			cycle_playing = false
		"strip":
			_set_mode("strip")
			_strip_start()
			for id in data.get("strip", []).slice(0, 4):
				_on_part_clicked(id)
