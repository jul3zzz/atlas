extends Control
## Caserne : personnalisation du soldat du joueur.
## Mode « historique » : seulement ce qui existe à l'époque choisie. Mode « libre » : tout est permis.

const HEADGEAR_NAMES := {
	"hair": "Tête nue", "galea": "Casque romain (galea)", "hoplite": "Casque corinthien", "nemes": "Coiffe égyptienne (némès)",
	"gaul": "Casque gaulois", "nasal": "Casque à nasal", "great_helm": "Heaume", "kettle": "Chapel de fer", "morion": "Morion",
	"musketeer": "Chapeau à plume", "tricorne": "Tricorne", "bicorne": "Bicorne", "shako": "Shako", "bearskin": "Bonnet à poil",
	"kepi": "Képi", "pickelhaube": "Casque à pointe", "adrian": "Casque Adrian", "brodie": "Casque Brodie", "stahlhelm": "Casque allemand (Stahlhelm)",
	"m1": "Casque M1", "ssh40": "Casque soviétique SSh-40", "pilotka": "Calot (pilotka)", "ushanka": "Chapka", "beret": "Béret",
	"boonie": "Chapeau de brousse", "non_la": "Chapeau conique (nón lá)", "modern": "Casque moderne", "keffiyeh": "Keffieh", "crown": "Couronne (légendaire)",
}
const WEAPON_NAMES := {
	"": "Aucune", "gladius": "Glaive", "sword": "Épée", "sabre": "Sabre", "axe": "Hache", "mace": "Masse d'armes", "spear": "Lance",
	"pilum": "Pilum", "lance": "Lance de cavalerie", "pike": "Pique", "halberd": "Hallebarde", "bow": "Arc", "longbow": "Arc long",
	"crossbow": "Arbalète", "sling": "Fronde", "torch": "Torche", "flag": "Drapeau", "drum": "Tambour", "pistol": "Pistolet",
	"arquebus": "Arquebuse", "musket": "Mousquet", "musket_bayonet": "Fusil à baïonnette", "rifle": "Fusil", "rifle_bayonet": "Fusil et baïonnette",
	"garand": "M1 Garand", "ak": "AK-47", "m16": "M16", "famas": "FAMAS", "smg": "Pistolet-mitrailleur", "mg": "Mitrailleuse", "fal": "FAL",
	"bazooka": "Lance-roquettes", "rpg": "RPG-7", "sniper": "Fusil de précision", "binoculars": "Jumelles", "tablet": "Tablette",
}
const SHIELD_NAMES := {"": "Aucun", "scutum": "Scutum romain", "hoplon": "Hoplon grec", "round": "Bouclier rond", "kite": "Bouclier normand", "heater": "Écu", "riot": "Bouclier transparent"}
## Objets légendaires débloqués par le grade (index dans Game.RANKS).
const UNLOCKS := {"crown": 20, "flag": 6, "drum": 3, "bicorne": 10, "bearskin": 8}

var cfg: Dictionary = {}
var era_id := "e08"
var free_mode := false
var view: ModelView
var _opts: VBoxContainer
var _name: LineEdit


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme = UI.theme
	Sfx.music("march")
	add_child(UI.map_background())
	add_child(UI.top_bar("Caserne", func(): Nav.goto("hub")))
	cfg = Game.current.get("soldier", {}).duplicate(true)
	era_id = String(cfg.get("era", "e08"))
	free_mode = bool(cfg.get("free", false))
	if not cfg.has("uniform") or String(cfg.get("uniform", "")) == "":
		_apply_preset(_presets()[0] if _presets().size() else {})

	var row := UI.hbox(24)
	var m := UI.margin(row, 40, 86, 40, 24)
	m.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(m)
	var left := UI.vbox(10)
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(left)
	view = ModelView.new()
	view.size_flags_vertical = Control.SIZE_EXPAND_FILL
	view.custom_minimum_size = Vector2(600, 600)
	view.auto_rotate = 0.3
	left.add_child(view)
	var nrow := UI.hbox(10)
	left.add_child(nrow)
	nrow.add_child(UI.label("Nom :", 20))
	_name = LineEdit.new()
	_name.text = String(cfg.get("name", Game.current.get("name", "")))
	_name.max_length = 24
	_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_name.text_changed.connect(func(t): cfg["name"] = t)
	nrow.add_child(_name)
	nrow.add_child(UI.label(Game.rank_name(), 20, UI.GOLD, UI.font_ui_bold))

	var right := UI.panel(18)
	right.custom_minimum_size.x = 560
	row.add_child(right)
	var rv := UI.vbox(10)
	right.add_child(rv)
	var mrow := UI.hbox(8)
	rv.add_child(mrow)
	var bh := UI.button("Mode historique", func(): _set_free(false), 18)
	var bf := UI.button("Mode libre", func(): _set_free(true), 18)
	for b in [bh, bf]:
		b.toggle_mode = true
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		mrow.add_child(b)
	bh.button_pressed = not free_mode
	bf.button_pressed = free_mode
	bh.pressed.connect(func():
		bh.button_pressed = true
		bf.button_pressed = false)
	bf.pressed.connect(func():
		bf.button_pressed = true
		bh.button_pressed = false)
	_opts = UI.vbox(10)
	rv.add_child(UI.scroll(_opts))
	var brow := UI.hbox(10)
	rv.add_child(brow)
	brow.add_child(UI.button("Au hasard", _randomize, 18))
	brow.add_child(UI.expander())
	brow.add_child(UI.primary_button("Enregistrer", _save, 21))
	_build_options()
	_rebuild_model()


func _set_free(on: bool) -> void:
	free_mode = on
	cfg["free"] = on
	if not on:
		_apply_preset(_presets()[0] if _presets().size() else {})
	_build_options()
	_rebuild_model()


func _presets() -> Array:
	var out := []
	for u in Content.units_for_era(era_id):
		if not u.get("model", {}).has("vehicle"):
			out.append(u)
	return out


func _apply_preset(u: Dictionary) -> void:
	if u.is_empty():
		return
	var mdl: Dictionary = u.get("model", {})
	for k in ["uniform", "pants", "trim", "boots", "helmet", "accent", "headgear", "weapon", "shield", "shield_color", "shield_accent", "pack", "armor", "vest", "cape", "beard", "mustache", "mount", "horse_color"]:
		if mdl.has(k):
			cfg[k] = mdl[k]
		elif k in ["shield", "vest", "cape", "mount", "headgear", "weapon"]:
			cfg[k] = ""
		elif k in ["pack", "armor", "beard", "mustache"]:
			cfg[k] = false
	cfg["preset"] = u.id
	cfg["era"] = era_id


func _collect(key: String, all_eras: bool) -> Array:
	var out := []
	for id in Content.units:
		var u: Dictionary = Content.units[id]
		if not all_eras and u.era != era_id:
			continue
		var v = u.get("model", {}).get(key, "")
		if v is String and v != "" and not (v in out):
			out.append(v)
	return out


func _build_options() -> void:
	for c in _opts.get_children():
		c.queue_free()
	_opts.add_child(UI.label("ÉPOQUE", 16, UI.GOLD, UI.font_ui_bold))
	var eo := OptionButton.new()
	for e in Content.eras:
		eo.add_item("%d. %s" % [e.num, e.name])
	eo.selected = max(0, Content.era_index(era_id))
	eo.item_selected.connect(func(i):
		era_id = Content.eras[i].id
		cfg["era"] = era_id
		if not free_mode:
			_apply_preset(_presets()[0] if _presets().size() else {})
		_build_options()
		_rebuild_model())
	_opts.add_child(eo)

	_opts.add_child(UI.label("TENUE", 16, UI.GOLD, UI.font_ui_bold))
	var po := OptionButton.new()
	var presets := _presets()
	for i in presets.size():
		po.add_item(String(presets[i].name))
		if presets[i].id == cfg.get("preset", ""):
			po.selected = i
	po.item_selected.connect(func(i):
		_apply_preset(presets[i])
		_build_options()
		_rebuild_model())
	_opts.add_child(po)

	var heads := _collect("headgear", free_mode)
	if not ("hair" in heads):
		heads.push_front("hair")
	if free_mode:
		for h in HEADGEAR_NAMES:
			if not (h in heads):
				heads.append(h)
	_opts.add_child(_choice("Coiffe", "headgear", heads, HEADGEAR_NAMES))
	var weapons := _collect("weapon", free_mode)
	weapons.push_front("")
	if free_mode:
		for w in WEAPON_NAMES:
			if not (w in weapons):
				weapons.append(w)
	else:
		for w in ["flag", "drum"]:
			weapons.append(w)
	_opts.add_child(_choice("Arme ou objet", "weapon", weapons, WEAPON_NAMES))
	var shields := _collect("shield", free_mode)
	shields.push_front("")
	if free_mode:
		for s in SHIELD_NAMES:
			if not (s in shields):
				shields.append(s)
	if shields.size() > 1:
		_opts.add_child(_choice("Bouclier", "shield", shields, SHIELD_NAMES))
	var has_cav := free_mode or Content.units_for_era(era_id).any(func(u): return u.get("model", {}).get("mount", "") == "horse")
	if has_cav:
		var cb := CheckButton.new()
		cb.text = "À cheval"
		cb.button_pressed = String(cfg.get("mount", "")) == "horse"
		cb.toggled.connect(func(on):
			cfg["mount"] = "horse" if on else ""
			_rebuild_model())
		_opts.add_child(cb)

	_opts.add_child(UI.label("VISAGE", 16, UI.GOLD, UI.font_ui_bold))
	var skins := UI.hbox(6)
	for i in Models.SKINS.size():
		var b := Button.new()
		b.custom_minimum_size = Vector2(44, 34)
		b.focus_mode = Control.FOCUS_NONE
		b.add_theme_stylebox_override("normal", UI._sb(Color(Models.SKINS[i]), UI.GOLD if int(cfg.get("skin", 1)) == i else UI.BORDER, 2, 4, 0))
		b.add_theme_stylebox_override("hover", UI._sb(Color(Models.SKINS[i]), Color.WHITE, 2, 4, 0))
		b.pressed.connect(func():
			cfg["skin"] = i
			_build_options()
			_rebuild_model())
		skins.add_child(b)
	_opts.add_child(skins)
	var frow := UI.hbox(10)
	for k in [["beard", "Barbe"], ["mustache", "Moustache"]]:
		var c := CheckBox.new()
		c.text = k[1]
		c.button_pressed = bool(cfg.get(k[0], false))
		c.toggled.connect(func(on):
			cfg[k[0]] = on
			_rebuild_model())
		frow.add_child(c)
	_opts.add_child(frow)

	if free_mode:
		_opts.add_child(UI.label("COULEURS", 16, UI.GOLD, UI.font_ui_bold))
		for k in [["uniform", "Veste"], ["pants", "Pantalon"], ["trim", "Ceinture et galons"], ["helmet", "Coiffe"], ["accent", "Détails"]]:
			var r := UI.hbox(10)
			r.add_child(UI.label(k[1], 17))
			r.add_child(UI.expander())
			var cp := ColorPickerButton.new()
			cp.custom_minimum_size = Vector2(90, 30)
			cp.color = Models.col(cfg.get(k[0]), Color.GRAY)
			cp.edit_alpha = false
			cp.color_changed.connect(func(col):
				cfg[k[0]] = "#" + col.to_html(false)
				_rebuild_model())
			r.add_child(cp)
			_opts.add_child(r)
	else:
		_opts.add_child(UI.wrap_label("Mode historique : seuls les équipements de l'époque sont proposés. Passe en mode libre pour tout mélanger (et choisir tes couleurs) !", 15, UI.MUTED))
	var preset: Dictionary = Content.units.get(String(cfg.get("preset", "")), {})
	if not preset.is_empty():
		_opts.add_child(UI.rich("[i][color=#a8a48c]%s[/color][/i]" % preset.get("desc", ""), true, 15))


func _choice(title: String, key: String, values: Array, names: Dictionary) -> Control:
	var v := UI.vbox(4)
	v.add_child(UI.label(title.to_upper(), 16, UI.GOLD, UI.font_ui_bold))
	var ob := OptionButton.new()
	var rank := Game.rank_index()
	for i in values.size():
		var val: String = values[i]
		var label: String = names.get(val, val)
		var need := int(UNLOCKS.get(val, -1))
		if need > rank:
			label += "  🔒 (" + Game.RANKS[need][0] + ")"
		ob.add_item(label.replace("🔒", "✖"))
		ob.set_item_disabled(i, need > rank)
		if val == String(cfg.get(key, "")):
			ob.selected = i
	ob.item_selected.connect(func(i):
		cfg[key] = values[i]
		Sfx.play("part", -6.0)
		_rebuild_model())
	v.add_child(ob)
	return v


func _rebuild_model() -> void:
	var c := cfg.duplicate()
	c["team"] = UI.GOLD
	var mounted := String(c.get("mount", "")) == "horse"
	view.set_model(Models.soldier(c), 2.9 if mounted else 2.0)


func _randomize() -> void:
	var presets := _presets()
	if presets.is_empty():
		return
	_apply_preset(presets[randi() % presets.size()])
	cfg["skin"] = randi() % Models.SKINS.size()
	cfg["beard"] = randf() < 0.3
	cfg["mustache"] = randf() < 0.3
	if free_mode:
		var heads := HEADGEAR_NAMES.keys().filter(func(h): return int(UNLOCKS.get(h, -1)) <= Game.rank_index())
		cfg["headgear"] = heads[randi() % heads.size()]
		var ws := WEAPON_NAMES.keys().filter(func(w): return int(UNLOCKS.get(w, -1)) <= Game.rank_index())
		cfg["weapon"] = ws[randi() % ws.size()]
		cfg["uniform"] = "#" + Color.from_hsv(randf(), randf_range(0.2, 0.7), randf_range(0.3, 0.8)).to_html(false)
	Sfx.play("card")
	_build_options()
	_rebuild_model()


func _save() -> void:
	cfg["name"] = _name.text.strip_edges()
	cfg["era"] = era_id
	Game.current["soldier"] = cfg.duplicate(true)
	Game.save()
	Sfx.play("confirm")
	UI.toast("Ton soldat est enregistré !", UI.GREEN)


func test_action(_a: String) -> void:
	_set_free(true)
	_randomize()
