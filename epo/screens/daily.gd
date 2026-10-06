extends Control
## Quotidien du soldat : préparer son paquetage, puis vivre 5 jours au rythme de l'époque.
## 4 jauges : Moral, Santé, Énergie, Discipline. Des événements aléatoires testent ton paquetage.

const STATS := [
	["moral", "Moral", Color("4e9ee0")],
	["sante", "Santé", Color("7cb855")],
	["energie", "Énergie", Color("d4ac2b")],
	["discipline", "Discipline", Color("c0573a")],
]
const SLOTS := ["Matin", "Après-midi", "Soir"]

var era_id := ""
var data: Dictionary
var values := {"moral": 60.0, "sante": 70.0, "energie": 70.0, "discipline": 60.0}
var packed: Dictionary = {}
var day := 1
var slot := 0
var used_events: Array = []
var log_facts: Array = []
var _bars: Dictionary = {}
var _main: VBoxContainer
var _header: Label
var _weight_label: Label


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme = UI.theme
	era_id = String(Nav.params.get("era", "e06"))
	data = Content.daily.get(era_id, {})
	var era := Content.era(era_id)
	Sfx.music("ambient")
	add_child(UI.map_background(Color(era.get("color", "#555")).darkened(0.86)))
	add_child(UI.top_bar("Quotidien du soldat · " + String(era.get("name", "")), func(): Nav.goto("era", {"era": era_id})))
	var root := UI.hbox(24)
	var m := UI.margin(root, 50, 88, 50, 24)
	m.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(m)
	# Jauges à gauche
	var side := UI.panel(18)
	side.custom_minimum_size.x = 320
	root.add_child(side)
	var sv := UI.vbox(10)
	side.add_child(sv)
	_header = UI.label("", 22, UI.GOLD, UI.font_ui_bold)
	_header.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sv.add_child(_header)
	for s in STATS:
		sv.add_child(UI.label(String(s[1]), 18, s[2], UI.font_ui_bold))
		var pb := UI.progress_bar(values[s[0]], 100, false, 14)
		UI.gauge_style(pb, s[2])
		sv.add_child(pb)
		_bars[s[0]] = pb
	sv.add_child(UI.spacer(6))
	sv.add_child(UI.wrap_label("Si une jauge tombe à zéro, ta semaine s'arrête : blessé, malade, épuisé ou puni.", 15, UI.MUTED))
	_main = UI.vbox(14)
	_main.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_child(_main)
	if data.is_empty():
		_main.add_child(UI.label("Ce jeu sera bientôt disponible pour cette époque.", 22))
		return
	_pack_screen()


func _clear() -> void:
	for c in _main.get_children():
		c.queue_free()


func _refresh_bars() -> void:
	for k in _bars:
		var tw := create_tween()
		tw.tween_property(_bars[k], "value", float(values[k]), 0.3)


func _apply(fx: Dictionary) -> void:
	for k in fx:
		if values.has(k):
			values[k] = clamp(float(values[k]) + float(fx[k]), 0.0, 100.0)
	_refresh_bars()


func _fx_text(fx: Dictionary) -> String:
	var parts := []
	for s in STATS:
		if fx.has(s[0]) and int(fx[s[0]]) != 0:
			var v := int(fx[s[0]])
			parts.append("[color=#%s]%s %s%d[/color]" % [(UI.GREEN if v > 0 else UI.RED).to_html(false), s[1], "+" if v > 0 else "", v])
	return "   ".join(parts)


# --- Paquetage ------------------------------------------------------------------------

func _weight() -> float:
	var w := 0.0
	for it in data.get("items", []):
		if packed.get(it.id, false):
			w += float(it.kg)
	return w


func _pack_screen() -> void:
	_clear()
	_header.text = "Préparation"
	_main.add_child(UI.title(String(data.get("title", "")), 32))
	_main.add_child(UI.rich(String(data.get("role", "")), true, 19))
	_main.add_child(UI.label("PRÉPARE TON PAQUETAGE", 19, UI.GOLD, UI.font_ui_bold))
	_main.add_child(UI.wrap_label("Tu ne peux pas tout emporter : choisis ce qui te sera le plus utile cette semaine. Certains objets te sauveront lors d'événements imprévus…", 17, UI.MUTED))
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	_main.add_child(grid)
	_weight_label = UI.label("", 20, UI.TEXT, UI.font_ui_bold)
	for it in data.get("items", []):
		var b := Button.new()
		b.toggle_mode = true
		b.focus_mode = Control.FOCUS_NONE
		b.custom_minimum_size = Vector2(420, 74)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		b.add_theme_stylebox_override("pressed", UI._sb(Color("3b4630"), UI.GOLD))
		var v := UI.vbox(2)
		v.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var mm := UI.margin(v, 12, 6, 12, 6)
		mm.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		mm.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(mm)
		var t := UI.label("%s  ·  %s kg" % [it.name, UI.dec(float(it.kg))], 18, UI.TEXT, UI.font_ui_bold)
		t.mouse_filter = Control.MOUSE_FILTER_IGNORE
		v.add_child(t)
		var d := UI.label(String(it.get("desc", "")), 15, UI.MUTED)
		d.mouse_filter = Control.MOUSE_FILTER_IGNORE
		d.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		v.add_child(d)
		b.tooltip_text = String(it.get("desc", ""))
		b.toggled.connect(func(on):
			if on and _weight() + float(it.kg) > float(data.get("pack_limit", 10)):
				b.set_pressed_no_signal(false)
				Sfx.play("error")
				UI.toast("Trop lourd ! Retire d'abord un objet.", UI.RED, 1.5)
				return
			packed[it.id] = on
			Sfx.play("part", -6.0)
			_update_weight())
		grid.add_child(b)
	var row := UI.hbox(14)
	_main.add_child(row)
	row.add_child(_weight_label)
	row.add_child(UI.expander())
	row.add_child(UI.primary_button("Partir  ▶", _start_days, 22))
	_update_weight()


func _update_weight() -> void:
	_weight_label.text = "Poids : %s / %s kg" % [UI.dec(_weight()), UI.dec(float(data.get("pack_limit", 10)))]


func _start_days() -> void:
	day = 1
	slot = 0
	_slot_screen()


# --- Journée ---------------------------------------------------------------------------

func _slot_screen() -> void:
	_clear()
	var days := int(data.get("days", 5))
	_header.text = "Jour %d / %d — %s" % [day, days, SLOTS[slot]]
	_main.add_child(UI.title("Jour %d · %s" % [day, SLOTS[slot]], 34))
	_main.add_child(UI.label("Que fais-tu ?", 20, UI.MUTED))
	var acts: Array = data.get("activities", []).duplicate()
	acts = acts.filter(func(a): return not a.has("slots") or SLOTS[slot] in a.slots)
	acts.shuffle()
	var row := UI.hbox(14)
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_main.add_child(row)
	for a in acts.slice(0, 3):
		var b := Button.new()
		b.focus_mode = Control.FOCUS_NONE
		b.custom_minimum_size = Vector2(260, 260)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		var v := UI.vbox(8)
		v.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var mm := UI.margin(v, 16, 14, 16, 14)
		mm.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		mm.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(mm)
		var ic := UI.label(String(a.get("icon", "✦")), 40, UI.GOLD)
		ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
		v.add_child(ic)
		var t := UI.label(String(a.name), 21, UI.TEXT, UI.font_ui_bold)
		t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		t.mouse_filter = Control.MOUSE_FILTER_IGNORE
		v.add_child(t)
		var fx := UI.rich(_fx_text(a.get("fx", {})), false, 16)
		fx.mouse_filter = Control.MOUSE_FILTER_IGNORE
		v.add_child(fx)
		b.pressed.connect(func(): _do_activity(a))
		row.add_child(b)
	_main.add_child(UI.wrap_label("Astuce : alterne effort et repos, et garde un œil sur la discipline !", 15, UI.MUTED))


func _do_activity(a: Dictionary) -> void:
	Sfx.play("confirm")
	_apply(a.get("fx", {}))
	if a.has("fact"):
		log_facts.append(String(a.fact))
	_clear()
	_main.add_child(UI.title(String(a.name), 30))
	_main.add_child(UI.rich(_fx_text(a.get("fx", {})), false, 19))
	if a.has("fact"):
		var p := UI.paper_panel(20)
		var pv := UI.vbox(6)
		p.add_child(pv)
		pv.add_child(UI.label("LE SAVIEZ-VOUS ?", 16, Color("8a5a1a"), UI.font_ui_bold))
		pv.add_child(UI.rich(String(a.fact), true, 20, UI.INK))
		_main.add_child(p)
	if _check_dead():
		return
	_main.add_child(UI.primary_button("Continuer  ▶", _next_slot, 21))


func _next_slot() -> void:
	slot += 1
	if slot >= SLOTS.size():
		slot = 0
		_night_event()
	else:
		_slot_screen()


func _night_event() -> void:
	# Effets passifs des objets emportés (lettres, jeu de cartes…).
	for it in data.get("items", []):
		if packed.get(it.id, false) and it.has("daily"):
			_apply(it.daily)
	_apply({"energie": 10})
	var pool: Array = data.get("events", []).filter(func(e): return not (e.text in used_events))
	if pool.is_empty():
		used_events.clear()
		pool = data.get("events", [])
	var ev: Dictionary = pool[randi() % pool.size()]
	used_events.append(ev.text)
	Sfx.play("card")
	_clear()
	_header.text = "Jour %d — Nuit" % day
	_main.add_child(UI.label("ÉVÉNEMENT", 18, UI.RED, UI.font_ui_bold))
	_main.add_child(UI.rich("[b]%s[/b]" % ev.text, true, 24))
	if ev.has("needs"):
		var it := _item(String(ev.needs))
		var has: bool = bool(packed.get(ev.needs, false))
		var res: Dictionary = ev.ok if has else ev.ko
		var msg := ("[color=#7cb855]Heureusement, tu as emporté : %s ![/color]" % it.get("name", "")) if has else ("[color=#d0493a]Tu n'as pas emporté : %s…[/color]" % it.get("name", ""))
		_resolve(res, msg)
	else:
		var row := UI.hbox(12)
		_main.add_child(row)
		for o in ev.get("options", []):
			var b := UI.button(String(o.label), func(): _option(o), 19)
			b.custom_minimum_size = Vector2(300, 70)
			b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			row.add_child(b)


func _option(o: Dictionary) -> void:
	var res := {"fx": o.get("fx", {}), "note": o.get("note", "")}
	var msg := ""
	if o.has("chance"):
		if randf() < float(o.chance):
			msg = "[color=#7cb855]Ça a marché ![/color]"
		else:
			res.fx = o.get("fx_fail", {})
			res.note = o.get("note_fail", res.note)
			msg = "[color=#d0493a]Pas de chance…[/color]"
	for c in _main.get_children():
		if c is HBoxContainer:
			c.queue_free()
	_resolve(res, msg)


func _resolve(res: Dictionary, msg: String) -> void:
	_apply(res.get("fx", {}))
	if msg != "":
		_main.add_child(UI.rich(msg, false, 19))
	_main.add_child(UI.rich(_fx_text(res.get("fx", {})), false, 19))
	if String(res.get("note", "")) != "":
		var p := UI.paper_panel(18)
		p.add_child(UI.rich(String(res.note), true, 19, UI.INK))
		_main.add_child(p)
		log_facts.append(String(res.note))
	if _check_dead():
		return
	var days := int(data.get("days", 5))
	if day >= days:
		_main.add_child(UI.primary_button("Fin de la semaine  ▶", _finish, 21))
	else:
		_main.add_child(UI.primary_button("Jour suivant  ▶", func():
			day += 1
			_slot_screen(), 21))


func _item(id: String) -> Dictionary:
	for it in data.get("items", []):
		if it.id == id:
			return it
	return {}


func _check_dead() -> bool:
	for s in STATS:
		if float(values[s[0]]) <= 0.0:
			var endings := {"moral": "Ton moral s'est effondré : tu es évacué vers l'arrière, épuisé nerveusement.", "sante": "Malade ou blessé, tu es évacué vers l'hôpital.", "energie": "Épuisé, tu t'effondres : il faut te relever et t'envoyer au repos.", "discipline": "Tes chefs te sanctionnent : tu passes la fin de la semaine aux arrêts."}
			Sfx.play("defeat")
			var v := UI.vbox(12)
			v.add_child(UI.title("Semaine interrompue", 32))
			v.add_child(UI.rich(endings[s[0]] + "\n\n[color=#a8a48c]La vie de soldat est un équilibre : effort, repos, moral et discipline comptent tous.[/color]", true, 19))
			var row := UI.hbox(10)
			row.alignment = BoxContainer.ALIGNMENT_END
			v.add_child(row)
			row.add_child(UI.button("↻ Recommencer", func(): Nav.goto("daily", {"era": era_id}), 19))
			row.add_child(UI.primary_button("Retour", func(): Nav.goto("era", {"era": era_id}), 19))
			UI.modal(self, v, 640)
			return true
	return false


func _finish() -> void:
	var avg := 0.0
	for k in values:
		avg += float(values[k])
	avg /= values.size()
	var stars := 1
	if avg >= 50.0:
		stars = 2
	if avg >= 65.0:
		stars = 3
	var improved := Game.set_step(era_id, "daily", stars)
	Game.reward(60 + 40 * stars if improved else 20, 30 + 15 * stars, "Semaine terminée")
	Sfx.play("victory")
	_clear()
	_main.add_child(UI.title("Semaine terminée !", 36))
	_main.add_child(UI.label(UI.stars(stars) + "   (moyenne des jauges : %d)" % int(avg), 30, UI.GOLD))
	_main.add_child(UI.rich(String(data.get("outro", "")), true, 19))
	_main.add_child(UI.label("CE QUE TU AS APPRIS CETTE SEMAINE", 17, UI.GOLD, UI.font_ui_bold))
	var t := ""
	for f in log_facts.slice(0, 8):
		t += "• " + f + "\n"
	_main.add_child(UI.scroll(UI.rich(t, true, 17)))
	var row := UI.hbox(10)
	_main.add_child(row)
	row.add_child(UI.button("↻ Rejouer", func(): Nav.goto("daily", {"era": era_id}), 19))
	row.add_child(UI.primary_button("Retour à l'époque", func(): Nav.goto("era", {"era": era_id}), 19))


func test_action(_a: String) -> void:
	_start_days()
