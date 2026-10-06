extends Control
## Carte des 10 époques (accès libre) + raccourcis.


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme = UI.theme
	Sfx.music("march")
	add_child(UI.map_background())
	add_child(UI.top_bar("Carte des époques", func(): Nav.goto("title")))

	var row := UI.hbox(24)
	var m := UI.margin(row, 40, 90, 40, 30)
	m.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(m)

	var left := UI.vbox(14)
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(left)
	var head := UI.hbox(14)
	left.add_child(head)
	head.add_child(UI.title("Choisis ton époque", 36))
	head.add_child(UI.expander())
	head.add_child(UI.label("Toutes les époques sont ouvertes : explore-les dans l'ordre que tu veux.", 17, UI.MUTED))
	var grid := GridContainer.new()
	grid.columns = 5
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 14)
	grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left.add_child(grid)
	for e in Content.eras:
		grid.add_child(_era_card(e))

	var side := UI.vbox(10)
	side.custom_minimum_size.x = 300
	row.add_child(side)
	side.add_child(_profile_panel())
	side.add_child(_daily_panel())
	for item in [
		["★  Caserne : ton soldat", "barracks", {}],
		["✦  Caisses et collection", "crates", {}],
		["⚔  Bataille libre / défis", "battle_menu", {"sandbox": true}],
		["▶  Vidéothèque", "videos", {}],
		["⚙  Paramètres", "settings", {}],
	]:
		var b := UI.button(item[0], func(): Nav.goto(item[1], item[2]), 19)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		side.add_child(b)


func _era_card(e: Dictionary) -> Control:
	var col := Color(e.color)
	var b := Button.new()
	b.custom_minimum_size = Vector2(230, 300)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.size_flags_vertical = Control.SIZE_EXPAND_FILL
	b.focus_mode = Control.FOCUS_NONE
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var sb := UI._sb(Color(UI.PANEL, 0.95), Color(col, 0.7), 2, 6, 0)
	var sbh := UI._sb(Color(UI.PANEL_LIGHT, 0.98), UI.GOLD, 3, 6, 0)
	b.add_theme_stylebox_override("normal", sb)
	b.add_theme_stylebox_override("hover", sbh)
	b.add_theme_stylebox_override("pressed", sbh)
	b.tooltip_text = String(e.tagline)
	var v := UI.vbox(4)
	v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(v)
	var band := ColorRect.new()
	band.color = col
	band.custom_minimum_size.y = 74
	band.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(band)
	var num := UI.title("%02d" % int(e.num), 52, Color(1, 1, 1, 0.92))
	num.position = Vector2(14, 6)
	num.mouse_filter = Control.MOUSE_FILTER_IGNORE
	band.add_child(num)
	var inner := UI.vbox(4)
	inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var im := UI.margin(inner, 14, 6, 14, 12)
	im.mouse_filter = Control.MOUSE_FILTER_IGNORE
	im.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(im)
	var name_l := UI.label(String(e.name), 23, UI.TEXT, UI.font_ui_bold)
	name_l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inner.add_child(name_l)
	var per := UI.label(String(e.period), 16, col.lightened(0.35), UI.font_ui_bold)
	per.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inner.add_child(per)
	var sub := UI.wrap_label(String(e.subtitle), 16, UI.MUTED)
	sub.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inner.add_child(sub)
	var sp := UI.expander()
	sp.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inner.add_child(sp)
	var pct := Game.era_completion(e.id)
	var pb := UI.progress_bar(pct * 100.0, 100.0, false, 8)
	pb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inner.add_child(pb)
	var pl := UI.label("%d %% exploré" % int(round(pct * 100.0)), 15, UI.MUTED)
	pl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inner.add_child(pl)
	b.pressed.connect(func():
		Sfx.play("click")
		Nav.goto("era", {"era": e.id}))
	b.mouse_entered.connect(func(): Sfx.play("hover", -14.0))
	return b


func _profile_panel() -> Control:
	var p := UI.panel(16)
	var v := UI.vbox(6)
	p.add_child(v)
	v.add_child(UI.label(String(Game.current.get("name", "")), 26, UI.GOLD, UI.font_ui_bold))
	v.add_child(UI.label(Game.rank_name(), 19, UI.TEXT, UI.font_ui_bold))
	var rp := Game.rank_progress()
	v.add_child(UI.progress_bar(rp[0], rp[1], false, 10))
	var next_i := Game.rank_index() + 1
	if next_i < Game.RANKS.size():
		v.add_child(UI.label("Prochain grade : %s (%d XP)" % [Game.RANKS[next_i][0], Game.RANKS[next_i][1]], 15, UI.MUTED))
	var st: Dictionary = Game.current.get("stats", {})
	v.add_child(UI.label("Batailles gagnées : %d · Cartes : %d / %d" % [int(st.get("battles_won", 0)), Game.current.get("cards", {}).size(), Content.cards.size()], 15, UI.MUTED))
	return p


## Ravitaillement quotidien : une caisse gratuite par jour (raison de revenir chaque jour).
func _daily_panel() -> Control:
	var p := UI.panel(14, Color(UI.PANEL, 0.95), UI.GOLD_DARK)
	var v := UI.vbox(6)
	p.add_child(v)
	v.add_child(UI.label("RAVITAILLEMENT DU JOUR", 17, UI.GOLD, UI.font_ui_bold))
	var today := Time.get_date_string_from_system()
	var got := String(Game.current.get("daily_crate", "")) == today
	if got:
		v.add_child(UI.wrap_label("Déjà récupéré aujourd'hui. Reviens demain pour une nouvelle caisse gratuite !", 16, UI.MUTED))
	else:
		v.add_child(UI.wrap_label("Une caisse gratuite t'attend au dépôt.", 16, UI.TEXT))
		v.add_child(UI.primary_button("Récupérer", func():
			Game.current["daily_crate"] = today
			Game.current["free_crates"] = int(Game.current.get("free_crates", 0)) + 1
			Game.save()
			Sfx.play("coin")
			Nav.goto("crates"), 19))
	return p
