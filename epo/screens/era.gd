extends Control
## Écran d'une époque : présentation + les 6 activités + vidéos.

var era_id := "e01"
var era: Dictionary


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	theme = UI.theme
	era_id = String(Nav.params.get("era", "e01"))
	era = Content.era(era_id)
	var col := Color(era.get("color", "#888888"))
	Sfx.music("ambient")
	add_child(UI.map_background(col.darkened(0.82)))
	add_child(UI.top_bar("%02d · %s" % [int(era.num), era.name], func(): Nav.goto("hub")))

	var root := UI.hbox(26)
	var m := UI.margin(root, 40, 86, 40, 26)
	m.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(m)

	# Colonne gauche : présentation + soldat 3D
	var left := UI.vbox(10)
	left.custom_minimum_size.x = 430
	root.add_child(left)
	var view := ModelView.new()
	view.custom_minimum_size = Vector2(430, 330)
	left.add_child(view)
	var hero := String(era.get("hero", ""))
	if Content.units.has(hero):
		var u: Dictionary = Content.units[hero]
		var mounted: bool = u.get("model", {}).get("mount", "") == "horse"
		view.set_model(UnitFactory.build_model(u, col), 2.9 if mounted else 2.0)
	var t := UI.title(String(era.name), 38, UI.GOLD)
	t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	left.add_child(t)
	left.add_child(UI.label(String(era.period) + "  ·  " + String(era.subtitle), 18, col.lightened(0.4), UI.font_ui_bold))
	var intro := UI.rich(String(era.intro), true, 18)
	left.add_child(intro)
	if Content.units.has(hero):
		left.add_child(UI.rich("[i][color=#a8a48c]%s : %s[/color][/i]" % [Content.units[hero].name, Content.units[hero].get("desc", "")], true, 15))

	# Colonne droite : activités
	var right := UI.vbox(14)
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_child(right)
	var head := UI.hbox()
	right.add_child(head)
	head.add_child(UI.label("TES MISSIONS", 22, UI.TEXT, UI.font_ui_bold))
	head.add_child(UI.expander())
	head.add_child(UI.label("Exploration : %d %%" % int(round(Game.era_completion(era_id) * 100)), 20, UI.GOLD, UI.font_ui_bold))
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 14)
	grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right.add_child(grid)
	var hist := Content.history(era_id)
	var book: Dictionary = hist.get("book", {})
	var weapons := Content.weapons_for_era(era_id)
	var battles := Content.battles_for_era(era_id)
	var tiles := [
		["history", "✎", "Histoire et livres", "%d chapitres, des anecdotes et le livre de l'époque : %s." % [hist.get("chapters", []).size(), book.get("title", "—")], "history"],
		["workshop", "⚙", "Atelier d'armes", "Démonte, observe et comprends : %s." % (", ".join(weapons.map(func(w): return w.name)) if weapons.size() else "bureau d'études"), "workshop_menu"],
		["battle", "⚔", "Bataille 3D", "%s. Place tes troupes et regarde la bataille se jouer." % (", ".join(battles.map(func(b): return b.name)) if battles.size() else "Bac à sable de l'époque"), "battle_menu"],
		["state", "♜", "L'État en guerre", "Finances, opinion, armée, alliés : tiens ton pays debout pendant la guerre.", "state"],
		["daily", "✚", "Quotidien du soldat", "Une semaine dans la peau d'un soldat de l'époque : moral, santé, corvées, imprévus.", "daily"],
		["quiz", "✔", "Quiz final", "Teste ce que tu as appris. 3 étoiles = 9 bonnes réponses sur 10.", "quiz"],
	]
	for tile in tiles:
		grid.add_child(_tile(tile, col))
	var bottom := UI.hbox(12)
	right.add_child(bottom)
	var vids := Content.videos_for_era(era_id)
	var bv := UI.button("▶  Vidéos de l'époque (%d)" % vids.size(), func(): Nav.goto("videos", {"era": era_id}), 19)
	bv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom.add_child(bv)
	var cards := Content.cards_for_era(era_id)
	var owned := cards.filter(func(c): return Game.card_count(c.id) > 0).size()
	var bc := UI.button("✦  Cartes de l'époque : %d / %d" % [owned, cards.size()], func(): Nav.goto("crates", {"era": era_id}), 19)
	bc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom.add_child(bc)


func _tile(tile: Array, col: Color) -> Control:
	var step: String = tile[0]
	var score := Game.step_score(era_id, step)
	var b := Button.new()
	b.custom_minimum_size = Vector2(250, 230)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.size_flags_vertical = Control.SIZE_EXPAND_FILL
	b.focus_mode = Control.FOCUS_NONE
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.add_theme_stylebox_override("normal", UI._sb(Color(UI.PANEL, 0.95), Color(col, 0.6), 2, 8, 0))
	b.add_theme_stylebox_override("hover", UI._sb(Color(UI.PANEL_LIGHT, 0.98), UI.GOLD, 3, 8, 0))
	b.add_theme_stylebox_override("pressed", UI._sb(Color(UI.PANEL_LIGHT, 0.98), UI.GOLD, 3, 8, 0))
	var v := UI.vbox(6)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mm := UI.margin(v, 18, 14, 18, 14)
	mm.set_anchors_preset(Control.PRESET_FULL_RECT)
	mm.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(mm)
	var icon := UI.label(String(tile[1]), 44, col.lightened(0.3))
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(icon)
	var name_l := UI.label(String(tile[2]), 24, UI.TEXT, UI.font_ui_bold)
	name_l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(name_l)
	var d := UI.wrap_label(String(tile[3]), 16, UI.MUTED)
	d.mouse_filter = Control.MOUSE_FILTER_IGNORE
	d.size_flags_vertical = Control.SIZE_EXPAND_FILL
	d.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	d.max_lines_visible = 4
	v.add_child(d)
	var s := UI.label(UI.stars(max(score, 0)) if score >= 0 else "À découvrir", 24 if score >= 0 else 17, UI.GOLD if score >= 0 else UI.MUTED)
	s.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(s)
	b.pressed.connect(func():
		Sfx.play("click")
		Nav.goto(tile[4], {"era": era_id}))
	b.mouse_entered.connect(func(): Sfx.play("hover", -14.0))
	return b
