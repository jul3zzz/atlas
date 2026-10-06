extends Control
## Caisses de ravitaillement (tirage aléatoire) et album de cartes-anecdotes.
## Aucune vraie monnaie : la solde se gagne uniquement en jouant.

const ODDS := {"commune": 0.6, "rare": 0.27, "epique": 0.1, "legendaire": 0.03}
const DUPLICATE_REFUND := {"commune": 15, "rare": 30, "epique": 60, "legendaire": 150}
const CARDS_PER_CRATE := 3
const PITY := 8

var era_filter := ""
var _album: GridContainer
var _filter: OptionButton
var _status: Label
var _stage: Control


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme = UI.theme
	era_filter = String(Nav.params.get("era", ""))
	Sfx.music("ambient")
	add_child(UI.map_background())
	var back := func(): Nav.goto("era", {"era": era_filter}) if era_filter != "" else Nav.goto("hub")
	add_child(UI.top_bar("Caisses et collection", back))

	var row := UI.hbox(24)
	var m := UI.margin(row, 40, 88, 40, 24)
	m.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(m)

	var left := UI.vbox(12)
	left.custom_minimum_size.x = 420
	row.add_child(left)
	left.add_child(UI.title("Dépôt de ravitaillement", 30))
	left.add_child(UI.wrap_label("Chaque caisse contient 3 cartes-anecdotes tirées au hasard. Plus une carte est rare, plus son histoire est étonnante ! Les doublons sont échangés contre de la solde.", 17, UI.MUTED))
	_status = UI.label("", 19, UI.GOLD, UI.font_ui_bold)
	left.add_child(_status)
	var odds := UI.rich("[color=#b9b6a5]Commune 60 %%[/color] · [color=#4e9ee0]Rare 27 %%[/color] · [color=#b06ae0]Épique 10 %%[/color] · [color=#f0b429]Légendaire 3 %%[/color]\n[color=#a8a48c]Garantie : au moins une carte épique toutes les %d caisses.[/color]" % PITY, false, 16)
	left.add_child(odds)
	left.add_child(_crate_button("Caisse standard", "Toutes les époques", Game.CRATE_PRICE, ""))
	if era_filter != "":
		left.add_child(_crate_button("Caisse « %s »" % Content.era(era_filter).name, "Uniquement cette époque", Game.CRATE_PRICE + 20, era_filter))
	_stage = Control.new()
	_stage.custom_minimum_size = Vector2(420, 330)
	_stage.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left.add_child(_stage)

	var right := UI.vbox(10)
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(right)
	var head := UI.hbox(12)
	right.add_child(head)
	head.add_child(UI.title("Album", 30))
	head.add_child(UI.expander())
	_filter = OptionButton.new()
	_filter.add_item("Toutes les époques")
	for e in Content.eras:
		_filter.add_item("%d. %s" % [e.num, e.name])
	_filter.selected = 0 if era_filter == "" else Content.era_index(era_filter) + 1
	_filter.item_selected.connect(func(_i): _refresh_album())
	head.add_child(_filter)
	_album = GridContainer.new()
	_album.columns = 5
	_album.add_theme_constant_override("h_separation", 12)
	_album.add_theme_constant_override("v_separation", 12)
	right.add_child(UI.scroll(_album))
	_refresh_status()
	_refresh_album()


func _crate_button(title: String, sub: String, price: int, era: String) -> Control:
	var p := UI.panel(14, Color("3a2a18", 0.95), Color("8a6a3a"))
	var r := UI.hbox(12)
	p.add_child(r)
	var v := UI.vbox(2)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	r.add_child(v)
	v.add_child(UI.label(title, 21, UI.TEXT, UI.font_ui_bold))
	v.add_child(UI.label(sub, 15, UI.MUTED))
	var free := int(Game.current.get("free_crates", 0))
	var label := "Ouvrir (gratuite)" if free > 0 and era == "" else "Ouvrir ◉ %d" % price
	r.add_child(UI.primary_button(label, func(): _open(price, era), 19))
	return p


func _refresh_status() -> void:
	var owned := 0
	for c in Content.cards:
		if Game.card_count(c.id) > 0:
			owned += 1
	var free := int(Game.current.get("free_crates", 0))
	_status.text = "Solde : ◉ %d   ·   Collection : %d / %d%s" % [Game.solde(), owned, Content.cards.size(), ("   ·   %d caisse(s) gratuite(s)" % free) if free > 0 else ""]


func _roll_rarity(force_epic := false) -> String:
	var r := randf()
	if force_epic:
		return "legendaire" if r < 0.2 else "epique"
	var acc := 0.0
	for k in ["legendaire", "epique", "rare", "commune"]:
		acc += ODDS[k]
		if r < acc:
			return k
	return "commune"


func _draw_cards(era: String) -> Array:
	var pool := Content.cards if era == "" else Content.cards_for_era(era)
	var out := []
	var since := int(Game.current.get("crates_since_epic", 0))
	var force := since + 1 >= PITY
	var got_epic := false
	for i in CARDS_PER_CRATE:
		var rarity := _roll_rarity(force and i == CARDS_PER_CRATE - 1 and not got_epic)
		var candidates := pool.filter(func(c): return c.rarity == rarity)
		if candidates.is_empty():
			candidates = pool
		var card: Dictionary = candidates[randi() % candidates.size()]
		if card.rarity in ["epique", "legendaire"]:
			got_epic = true
		out.append(card)
	Game.current["crates_since_epic"] = 0 if got_epic else since + 1
	return out


func _open(price: int, era: String) -> void:
	if Content.cards.is_empty():
		return
	var free := int(Game.current.get("free_crates", 0))
	if free > 0 and era == "":
		Game.current["free_crates"] = free - 1
		Game.save()
	elif not Game.spend(price):
		Sfx.play("error")
		UI.toast("Solde insuffisante : gagne des batailles, lis des chapitres, réussis des quiz !", UI.RED, 3.0)
		return
	Game.stat_add("crates")
	var cards := _draw_cards(era)
	_animate_open(cards)


func _animate_open(cards: Array) -> void:
	for c in _stage.get_children():
		c.queue_free()
	Sfx.play("crate")
	var crate := UI.panel(10, Color("6b4a2a"), Color("3a2a18"))
	crate.custom_minimum_size = Vector2(200, 140)
	crate.position = Vector2(110, 80)
	crate.pivot_offset = Vector2(100, 70)
	var cl := UI.label("RAVITAILLEMENT", 18, Color("e8d4a0"), UI.font_title)
	cl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	crate.add_child(cl)
	_stage.add_child(crate)
	var tw := create_tween()
	for i in 6:
		tw.tween_property(crate, "rotation", 0.08 * (1 if i % 2 == 0 else -1), 0.06)
	tw.tween_property(crate, "rotation", 0.0, 0.05)
	tw.tween_property(crate, "scale", Vector2(1.3, 1.3), 0.12)
	tw.parallel().tween_property(crate, "modulate:a", 0.0, 0.15)
	tw.tween_callback(func():
		crate.queue_free()
		_reveal(cards))


func _reveal(cards: Array) -> void:
	var refund := 0
	var row := UI.hbox(10)
	row.position = Vector2(0, 20)
	_stage.add_child(row)
	for i in cards.size():
		var card: Dictionary = cards[i]
		var is_new := Game.add_card(card.id)
		if not is_new:
			refund += int(DUPLICATE_REFUND.get(card.rarity, 10))
		var w := card_widget(card, true, 136, is_new)
		w.pivot_offset = Vector2(68, 95)
		w.scale = Vector2(0.0, 1.0)
		row.add_child(w)
		var tw := create_tween()
		tw.tween_interval(0.25 + i * 0.45)
		tw.tween_callback(_rarity_sound.bind(String(card.rarity)))
		tw.tween_property(w, "scale", Vector2(1.0, 1.0), 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if refund > 0:
		Game.add_solde(refund)
		var tw2 := create_tween()
		tw2.tween_interval(1.6)
		tw2.tween_callback(func(): UI.toast("Doublons échangés : +%d de solde" % refund, UI.GOLD))
	var tw3 := create_tween()
	tw3.tween_interval(1.5)
	tw3.tween_callback(func():
		_refresh_status()
		_refresh_album())


func _rarity_sound(rarity: String) -> void:
	match rarity:
		"legendaire":
			Sfx.play("legendary")
		"epique", "rare":
			Sfx.play("rare")
		_:
			Sfx.play("card")


## Widget d'une carte. show=true : face visible ; sinon dos « ? ».
func card_widget(card: Dictionary, show: bool, width := 150, is_new := false) -> Control:
	var rc: Color = UI.RARITY_COLORS.get(card.rarity, UI.MUTED)
	var b := Button.new()
	b.custom_minimum_size = Vector2(width, width * 1.4)
	b.focus_mode = Control.FOCUS_NONE
	var sb := UI._sb(Color("1a1d14") if show else Color("12140e"), rc if show else Color("333a28"), 3, 8, 0)
	b.add_theme_stylebox_override("normal", sb)
	b.add_theme_stylebox_override("hover", UI._sb(Color("242a1b"), rc.lightened(0.3) if show else UI.BORDER, 3, 8, 0))
	b.add_theme_stylebox_override("pressed", sb)
	var v := UI.vbox(4)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mm := UI.margin(v, 10, 8, 10, 8)
	mm.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mm.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(mm)
	var era := Content.era(String(card.era))
	var band := UI.label("%02d · %s" % [int(era.get("num", 0)), String(era.get("name", "")).to_upper()], 12, Color(era.get("color", "#888")).lightened(0.35), UI.font_ui_bold)
	band.mouse_filter = Control.MOUSE_FILTER_IGNORE
	band.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	v.add_child(band)
	if show:
		var t := UI.label(String(card.title), 17 if width > 140 else 15, UI.TEXT, UI.font_ui_bold)
		t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		t.mouse_filter = Control.MOUSE_FILTER_IGNORE
		t.size_flags_vertical = Control.SIZE_EXPAND_FILL
		v.add_child(t)
		var icon := UI.label(String(card.get("icon", "✦")), 34, rc)
		icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		v.add_child(icon)
		var r := UI.label(UI.RARITY_NAMES.get(card.rarity, "") + ("  · NOUVEAU !" if is_new else ""), 13, rc, UI.font_ui_bold)
		r.mouse_filter = Control.MOUSE_FILTER_IGNORE
		v.add_child(r)
		b.tooltip_text = String(card.text)
		b.pressed.connect(func(): _card_modal(card))
	else:
		var q := UI.title("?", 60, Color("333a28"))
		q.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		q.size_flags_vertical = Control.SIZE_EXPAND_FILL
		q.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		q.mouse_filter = Control.MOUSE_FILTER_IGNORE
		v.add_child(q)
		var r2 := UI.label(UI.RARITY_NAMES.get(card.rarity, ""), 13, Color(rc, 0.5), UI.font_ui_bold)
		r2.mouse_filter = Control.MOUSE_FILTER_IGNORE
		v.add_child(r2)
	return b


func _card_modal(card: Dictionary) -> void:
	var rc: Color = UI.RARITY_COLORS.get(card.rarity, UI.MUTED)
	var body := "[color=#%s][b]%s[/b][/color] · %s\n\n%s" % [rc.to_html(false), UI.RARITY_NAMES.get(card.rarity, ""), Content.era(String(card.era)).get("name", ""), card.text]
	if card.has("source"):
		body += "\n\n[i][color=#a8a48c]Source : %s[/color][/i]" % card.source
	body += "\n\n[color=#a8a48c]Exemplaires : %d[/color]" % Game.card_count(card.id)
	UI.message(self, String(card.title), body, "Fermer")


func _refresh_album() -> void:
	for c in _album.get_children():
		c.queue_free()
	var idx := _filter.selected
	var cards: Array = Content.cards if idx == 0 else Content.cards_for_era(Content.eras[idx - 1].id)
	for card in cards:
		_album.add_child(card_widget(card, Game.card_count(card.id) > 0, 150))


func test_action(_a: String) -> void:
	Game.add_solde(500)
	_open(Game.CRATE_PRICE, "")
