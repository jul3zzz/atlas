extends Control
## L'État en guerre, version « tableau de bord » : l'économie de guerre.
## À chaque tour, on fixe les impôts, on emprunte (ou pas) et on répartit le budget
## entre armement, recrutement, logistique, moral, diplomatie et recherche.
## La ligne de front bouge selon la force réelle de l'armée face à un ennemi qui se renforce.

const TURNS := 8
const STEP := 10
const BORROW := 50
const MAX_DEBT := 250
const INTEREST := 0.08
const LINES := ["armement", "recrutement", "logistique", "moral", "diplomatie", "recherche"]
const COL_US := Color("3d7fd1")
const COL_THEM := Color("cf3d3a")

var era_id := ""
var eco: Dictionary
var era_eco: Dictionary
var s := {}                 # état du pays
var alloc := {}             # budget réparti ce tour-ci
var tax := "normal"
var borrowed := false
var turn := 1
var enemy_mod := 0.0        # bonus/malus ponctuel de l'ennemi (événements)
var recruit_penalty := 0.0  # recrues retirées de l'économie
var over := false
var events_left: Array = []
var auto_mode := false

var _stat_labels := {}
var _stat_bars := {}
var _alloc_labels := {}
var _tax_buttons := {}
var _borrow_btn: Button
var _left_label: Label
var _turn_label: Label
var _front_bar: ProgressBar
var _front_label: Label
var _power_label: RichTextLabel
var _report: RichTextLabel
var _end_btn: Button


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme = UI.theme
	era_id = String(Nav.params.get("era", "e06"))
	eco = Content.economy
	era_eco = eco.get("eras", {}).get(era_id, {})
	var era := Content.era(era_id)
	Sfx.music("ambient")
	add_child(UI.map_background(Color(era.get("color", "#555")).darkened(0.86)))
	add_child(UI.top_bar("Économie de guerre · " + String(era.get("name", "")), func(): Nav.goto("era", {"era": era_id})))
	s = {"tresor": 120.0, "dette": 0.0, "soldats": 50.0, "materiel": 50.0, "ravit": 50.0, "moral": 60.0, "allies": 40.0, "tech": 0.0, "front": 0.0}
	for k in LINES:
		alloc[k] = 0
	_plan_events()
	_build()
	_report.text = UI.nbsp("[b]%s[/b]\n%s\n\n[color=#a8a48c]Répartis ton budget, puis valide le tour. Survole une ligne pour comprendre son rôle. Objectif : faire avancer la ligne de front en %d tours sans que le pays s'effondre.[/color]" % [era_eco.get("title", ""), era_eco.get("intro", ""), TURNS])
	_refresh()


## Les événements propres à l'époque tombent à des tours fixes ; les autres tours, un imprévu au hasard.
func _plan_events() -> void:
	var specific: Array = era_eco.get("events", []).duplicate()
	var generic: Array = eco.get("events", []).duplicate()
	generic.shuffle()
	events_left.resize(TURNS + 1)
	var slots := [2, 5, 7]
	for i in specific.size():
		if i < slots.size():
			events_left[slots[i]] = specific[i]
	var g := 0
	for t in range(1, TURNS):
		if events_left[t] == null and t % 2 == 1 and g < generic.size():
			events_left[t] = generic[g]
			g += 1


# --- Interface ----------------------------------------------------------------------

func _build() -> void:
	var root := UI.vbox(12)
	var m := UI.margin(root, 30, 76, 30, 16)
	m.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(m)
	# Bandeau : tour et ligne de front
	var head := UI.panel(12, Color(UI.PANEL, 0.95))
	root.add_child(head)
	var hv := UI.vbox(6)
	head.add_child(hv)
	var hr := UI.hbox(12)
	hv.add_child(hr)
	hr.add_child(UI.label(String(era_eco.get("title", "")), 24, UI.GOLD, UI.font_ui_bold))
	hr.add_child(UI.expander())
	_turn_label = UI.label("", 20, UI.TEXT, UI.font_ui_bold)
	hr.add_child(_turn_label)
	var fr := UI.hbox(10)
	hv.add_child(fr)
	fr.add_child(UI.label("Ton pays", 17, COL_US.lightened(0.25), UI.font_ui_bold))
	_front_bar = UI.progress_bar(100, 200, false, 18)
	_front_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_front_bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var bg := StyleBoxFlat.new()
	bg.bg_color = COL_THEM.darkened(0.25)
	bg.set_corner_radius_all(4)
	_front_bar.add_theme_stylebox_override("background", bg)
	var fill := StyleBoxFlat.new()
	fill.bg_color = COL_US
	fill.set_corner_radius_all(4)
	_front_bar.add_theme_stylebox_override("fill", fill)
	fr.add_child(_front_bar)
	fr.add_child(UI.label(String(era_eco.get("enemy", "Ennemi")), 17, COL_THEM.lightened(0.2), UI.font_ui_bold))
	_front_label = UI.label("", 16, UI.MUTED)
	_front_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hv.add_child(_front_label)

	var body := UI.hbox(14)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(body)
	body.add_child(_situation_panel())
	body.add_child(_budget_panel())
	var rp := UI.panel(16, Color(UI.PANEL, 0.95))
	rp.custom_minimum_size.x = 420
	body.add_child(rp)
	var rv := UI.vbox(8)
	rp.add_child(rv)
	rv.add_child(UI.label("RAPPORT", 18, UI.GOLD, UI.font_ui_bold))
	_report = UI.rich("", true, 17)
	_report.fit_content = false
	_report.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_report.scroll_active = true
	rv.add_child(_report)


func _situation_panel() -> Control:
	var p := UI.panel(16, Color(UI.PANEL, 0.95))
	p.custom_minimum_size.x = 360
	var v := UI.vbox(7)
	p.add_child(v)
	v.add_child(UI.label("SITUATION", 18, UI.GOLD, UI.font_ui_bold))
	var rows := [
		["tresor", "◉ Trésor", UI.GOLD, false],
		["dette", "✎ Dette", UI.MUTED, false],
		["soldats", "♞ Soldats", UI.TEXT, false],
		["materiel", "⚙ Matériel", UI.TEXT, false],
		["ravit", "⛟ Ravitaillement", Color("d39a4a"), true],
		["moral", "♥ Moral du pays", Color("4e9ee0"), true],
		["allies", "✉ Alliés", Color("7cb855"), true],
		["tech", "✦ Technologie", Color("b07ad8"), false],
	]
	for r in rows:
		var h := UI.hbox(8)
		h.add_child(UI.label(r[1], 18, r[2], UI.font_ui_bold))
		h.add_child(UI.expander())
		var val := UI.label("", 18, UI.TEXT, UI.font_ui_bold)
		h.add_child(val)
		_stat_labels[r[0]] = val
		v.add_child(h)
		if r[3]:
			var pb := UI.progress_bar(50, 100, false, 8)
			UI.gauge_style(pb, r[2])
			v.add_child(pb)
			_stat_bars[r[0]] = pb
	v.add_child(UI.spacer(4))
	_power_label = UI.rich("", false, 17)
	v.add_child(_power_label)
	return p


func _budget_panel() -> Control:
	var p := UI.panel(16, Color(UI.PANEL, 0.95))
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var v := UI.vbox(8)
	p.add_child(v)
	var th := UI.hbox(8)
	v.add_child(th)
	th.add_child(UI.label("IMPÔTS (rentrées du prochain tour)", 16, UI.GOLD, UI.font_ui_bold))
	var tr := UI.hbox(8)
	v.add_child(tr)
	for k in ["faible", "normal", "lourd"]:
		var t: Dictionary = eco.get("taxes", {}).get(k, {})
		var b := UI.button(String(t.get("name", k)), func(): _set_tax(k), 16)
		b.toggle_mode = true
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.tooltip_text = "Rentrées de base : %d ◉ · moral %+d par tour" % [int(t.get("revenue", 0)), int(t.get("moral", 0))]
		_tax_buttons[k] = b
		tr.add_child(b)
	_borrow_btn = UI.button("", _borrow, 16)
	_borrow_btn.tooltip_text = "L'argent arrive tout de suite, mais il faudra payer %d %% d'intérêts à chaque tour." % int(INTEREST * 100)
	v.add_child(_borrow_btn)
	v.add_child(UI.label("BUDGET DU TOUR", 16, UI.GOLD, UI.font_ui_bold))
	var names: Dictionary = era_eco.get("names", {})
	for k in LINES:
		var info: Dictionary = eco.get("lines", {}).get(k, {})
		var row := UI.panel(8, Color(UI.BG, 0.6))
		row.tooltip_text = String(info.get("lesson", ""))
		row.mouse_filter = Control.MOUSE_FILTER_PASS
		var h := UI.hbox(8)
		row.add_child(h)
		var nv := UI.vbox(0)
		nv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		nv.mouse_filter = Control.MOUSE_FILTER_IGNORE
		h.add_child(nv)
		nv.add_child(UI.label("%s  %s" % [info.get("icon", "•"), names.get(k, info.get("name", k))], 18, UI.TEXT, UI.font_ui_bold))
		nv.add_child(UI.label("%s · %s" % [info.get("name", k), info.get("effect", "")], 14, UI.MUTED))
		h.add_child(UI.button("−", func(): _change(k, -STEP), 20, 44))
		var amount := UI.label("0", 20, UI.GOLD, UI.font_ui_bold)
		amount.custom_minimum_size.x = 56
		amount.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		h.add_child(amount)
		_alloc_labels[k] = amount
		h.add_child(UI.button("+", func(): _change(k, STEP), 20, 44))
		v.add_child(row)
	var fr := UI.hbox(10)
	v.add_child(fr)
	_left_label = UI.label("", 18, UI.TEXT, UI.font_ui_bold)
	_left_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fr.add_child(_left_label)
	fr.add_child(UI.button("Tout annuler", func():
		for k in LINES:
			alloc[k] = 0
		_refresh(), 16))
	_end_btn = UI.primary_button("Valider le tour ▶", _end_turn, 20)
	fr.add_child(_end_btn)
	return p


func _set_tax(k: String) -> void:
	tax = k
	Sfx.play("click")
	_refresh()


func _borrow() -> void:
	if borrowed or float(s.dette) + BORROW > MAX_DEBT:
		Sfx.play("error")
		return
	borrowed = true
	s.tresor += BORROW
	s.dette += BORROW
	Sfx.play("coin")
	_refresh()


func _spent() -> int:
	var t := 0
	for k in LINES:
		t += int(alloc[k])
	return t


func _change(k: String, d: int) -> void:
	if over:
		return
	if d > 0 and _spent() + d > int(s.tresor):
		Sfx.play("error")
		return
	alloc[k] = maxi(0, int(alloc[k]) + d)
	Sfx.play("click", -10.0)
	_refresh()


## Force de l'armée : il faut à la fois des soldats ET du matériel, du ravitaillement,
## de la technologie et un pays qui tient moralement.
func _power(st: Dictionary) -> float:
	var base := minf(float(st.soldats), float(st.materiel) * 1.2)
	return base * (0.5 + float(st.ravit) / 100.0) * (1.0 + float(st.tech) / 200.0) * (0.7 + float(st.moral) / 200.0)


func _enemy_power() -> float:
	return 50.0 + 5.0 * turn + (10.0 if float(s.allies) < 20.0 else 0.0) + enemy_mod


## État après application du budget (sans les combats) : sert à l'aperçu et à la résolution.
func _apply_budget(st: Dictionary) -> Dictionary:
	var n := st.duplicate()
	n.materiel += alloc.armement * 0.8
	n.soldats += alloc.recrutement * 0.6
	n.moral = clampf(n.moral + alloc.moral * 0.35 - alloc.recrutement * 0.05, 0.0, 100.0)
	n.ravit = clampf(n.ravit * 0.7 + alloc.logistique * 1.0, 0.0, 100.0)
	n.allies = clampf(n.allies + alloc.diplomatie * 0.4 - 2.0, 0.0, 100.0)
	n.tech += alloc.recherche * 0.4
	return n


func _refresh() -> void:
	var labels: Array = era_eco.get("turns", [])
	var tl := String(labels[turn - 1]) if turn - 1 < labels.size() else ""
	_turn_label.text = "Tour %d / %d  ·  %s" % [mini(turn, TURNS), TURNS, tl]
	_front_bar.value = float(s.front) + 100.0
	var fl := String(era_eco.get("front", "Ligne de front"))
	var f := int(round(float(s.front)))
	_front_label.text = "%s : %+d  ·  %s" % [fl, f, "à ton avantage" if f > 5 else ("à l'avantage de l'ennemi" if f < -5 else "équilibre")]
	_stat_labels.tresor.text = "%d" % int(s.tresor)
	_stat_labels.dette.text = "%d  (intérêts %d/tour)" % [int(s.dette), int(round(float(s.dette) * INTEREST))]
	_stat_labels.soldats.text = "%d" % int(round(float(s.soldats)))
	_stat_labels.materiel.text = "%d" % int(round(float(s.materiel)))
	_stat_labels.tech.text = "+%d %%" % int(round(float(s.tech) / 2.0))
	for k in ["ravit", "moral", "allies"]:
		_stat_labels[k].text = "%d" % int(round(float(s[k])))
		_stat_bars[k].value = float(s[k])
	var preview := _apply_budget(s)
	var p_now := _power(s)
	var p_next := _power(preview)
	var e := _enemy_power()
	var col := "7cb855" if p_next >= e else "d0493a"
	_power_label.text = UI.nbsp("Force de ton armée : [b]%d[/b]\nAvec ce budget : [b][color=#%s]%d[/color][/b]\nForce ennemie estimée : [b][color=#cf3d3a]%d[/color][/b]" % [int(p_now), col, int(p_next), int(e)])
	for k in LINES:
		_alloc_labels[k].text = str(alloc[k])
	_left_label.text = "Reste : %d ◉" % (int(s.tresor) - _spent())
	for k in _tax_buttons:
		_tax_buttons[k].button_pressed = k == tax
	if borrowed:
		_borrow_btn.text = "Emprunt déjà fait ce tour"
	elif float(s.dette) + BORROW > MAX_DEBT:
		_borrow_btn.text = "Plus personne ne veut te prêter (dette max. %d)" % MAX_DEBT
	else:
		_borrow_btn.text = "Emprunter %d ◉  (intérêts %d %% par tour)" % [BORROW, int(INTEREST * 100)]
	_borrow_btn.disabled = borrowed or float(s.dette) + BORROW > MAX_DEBT or over
	_end_btn.disabled = over


# --- Résolution d'un tour -------------------------------------------------------------

func _end_turn() -> void:
	if over:
		return
	var rep := []
	var spent := _spent()
	s.tresor -= spent
	var before := s.duplicate()
	s = _apply_budget(s)
	recruit_penalty = alloc.recrutement * 0.15
	if float(s.allies) >= 60.0:
		s.materiel += 12.0
		s.tresor += 10.0
		rep.append("[color=#7cb855]✉ Tes alliés t'envoient du matériel et 10 ◉.[/color]")
	elif float(s.allies) < 20.0:
		rep.append("[color=#d0493a]✉ Isolé, ton pays attire les convoitises : l'ennemi se renforce.[/color]")
	var power := _power(s)
	var enemy := _enemy_power()
	var delta := clampf((power - enemy) * 0.5, -25.0, 25.0)
	s.front = clampf(float(s.front) + delta, -100.0, 100.0)
	s.soldats = maxf(0.0, float(s.soldats) - (8.0 + absf(power - enemy) * 0.1))
	s.materiel = maxf(0.0, float(s.materiel) - 10.0)
	rep.push_front("[b]Combats[/b] : ta force %d contre %d → front %+d." % [int(power), int(enemy), int(round(delta))])
	# Leçons tirées du tour
	if float(before.soldats) + alloc.recrutement * 0.6 > float(before.materiel) * 1.2 + alloc.armement * 0.96 + 5.0:
		rep.append("⚙ Trop de soldats pour trop peu d'armes : une partie de ton armée ne sert à rien.")
	elif float(before.materiel) * 1.2 + alloc.armement * 0.96 > float(before.soldats) + alloc.recrutement * 0.6 + 25.0:
		rep.append("♞ Tes arsenaux sont pleins, mais il manque des soldats pour utiliser ce matériel.")
	if float(s.ravit) < 35.0:
		rep.append("⛟ Ravitaillement insuffisant : munitions et vivres manquent, l'armée perd beaucoup de sa force.")
	# Usure de la guerre
	var wear := -2.0
	if float(s.front) < -30.0:
		wear -= 5.0
		rep.append("♥ Les mauvaises nouvelles du front abattent le pays.")
	elif float(s.front) > 30.0:
		wear += 3.0
		rep.append("♥ Les succès redonnent espoir au pays.")
	s.moral = clampf(float(s.moral) + wear, 0.0, 100.0)
	enemy_mod = 0.0
	_report.text = UI.nbsp("[b]Bilan — %s[/b]\n%s" % [_turn_name(turn), "\n".join(rep)])
	Sfx.play("stamp")
	# Le budget est dépensé : on affiche tout de suite la nouvelle situation.
	for k in LINES:
		alloc[k] = 0
	_refresh()
	if _check_end():
		return
	var ev = events_left[turn] if turn < events_left.size() else null
	if ev != null:
		_show_event(ev)
	else:
		_next_turn()


func _turn_name(t: int) -> String:
	var labels: Array = era_eco.get("turns", [])
	return String(labels[t - 1]) if t - 1 < labels.size() else "tour %d" % t


func _next_turn() -> void:
	turn += 1
	if turn > TURNS:
		_finish()
		return
	# Rentrées fiscales du nouveau tour, puis intérêts de la dette.
	var t: Dictionary = eco.get("taxes", {}).get(tax, {"revenue": 70, "moral": -2})
	var revenue := roundf(float(t.revenue) * (0.6 + float(s.moral) / 250.0) - recruit_penalty)
	var interest := roundf(float(s.dette) * INTEREST)
	s.tresor += revenue - interest
	s.moral = clampf(float(s.moral) + float(t.moral), 0.0, 100.0)
	_report.text += UI.nbsp("\n\n[b]Nouveau tour[/b] : impôts +%d ◉%s." % [int(revenue), (", intérêts −%d ◉" % int(interest)) if interest > 0 else ""])
	if recruit_penalty >= 3.0:
		_report.text += UI.nbsp("\n[color=#a8a48c]Les recrues manquent aux champs et aux ateliers : −%d ◉.[/color]" % int(recruit_penalty))
	for k in LINES:
		alloc[k] = 0
	borrowed = false
	if float(s.tresor) < 0.0:
		_collapse("Banqueroute", "Les intérêts de la dette dépassent les rentrées : l'État ne peut plus payer ses soldats ni ses fournisseurs.")
		return
	_refresh()


func _show_event(ev: Dictionary) -> void:
	if auto_mode:
		_apply_event(ev, ev.get("a", {}))
		return
	var v := UI.vbox(12)
	v.add_child(UI.label("IMPRÉVU · " + _turn_name(turn).to_upper(), 16, UI.GOLD, UI.font_ui_bold))
	v.add_child(UI.title(String(ev.get("title", "")), 32))
	var r := UI.rich(String(ev.get("text", "")), true, 19)
	r.custom_minimum_size.x = 560
	v.add_child(r)
	var row := UI.hbox(10)
	row.alignment = BoxContainer.ALIGNMENT_END
	v.add_child(row)
	var shade := UI.modal(self, v, 660)
	Sfx.play("card")
	for key in ["b", "a"]:
		var opt: Dictionary = ev.get(key, {})
		if opt.is_empty():
			continue
		var cb := func():
			shade.queue_free()
			_apply_event(ev, opt)
		var btn := UI.primary_button(String(opt.get("label", "")), cb, 18) if key == "a" else UI.button(String(opt.get("label", "")), cb, 18)
		btn.tooltip_text = _fx_text(opt.get("fx", {}))
		# Un choix qui coûte plus que le trésor disponible est impossible.
		var cost := -float(opt.get("fx", {}).get("tresor", 0))
		if cost > 0.0 and cost > float(s.tresor):
			btn.disabled = true
			btn.text += " (trésor insuffisant)"
		row.add_child(btn)


func _fx_text(fx: Dictionary) -> String:
	var names := {"tresor": "trésor", "dette": "dette", "soldats": "soldats", "materiel": "matériel", "ravit": "ravitaillement", "moral": "moral", "allies": "alliés", "tech": "technologie", "front": "front", "enemy": "force ennemie"}
	var parts := []
	for k in fx:
		parts.append("%s %+d" % [names.get(k, k), int(fx[k])])
	return ", ".join(parts) if parts.size() else "aucun effet immédiat"


func _apply_event(ev: Dictionary, opt: Dictionary) -> void:
	var fx: Dictionary = opt.get("fx", {})
	for k in fx:
		var d := float(fx[k])
		if k == "enemy":
			enemy_mod += d
		elif s.has(k):
			s[k] = float(s[k]) + d
	for k in ["ravit", "moral", "allies"]:
		s[k] = clampf(float(s[k]), 0.0, 100.0)
	s.front = clampf(float(s.front), -100.0, 100.0)
	for k in ["soldats", "materiel", "tech", "dette"]:
		s[k] = maxf(0.0, float(s[k]))
	var note := String(opt.get("note", ev.get("note", "")))
	_report.text += UI.nbsp("\n\n[b]%s[/b] — %s (%s)\n[i]%s[/i]" % [ev.get("title", ""), opt.get("label", ""), _fx_text(fx), note])
	if _check_end():
		return
	_next_turn()


func _check_end() -> bool:
	if float(s.moral) <= 0.0:
		_collapse("Révolte", "Épuisé par la guerre, le peuple se soulève. Un pays ne se bat pas seulement avec des armes : il faut aussi qu'il tienne moralement.")
		return true
	if float(s.front) <= -100.0:
		_collapse("Défaite militaire", "Ton armée est enfoncée. Il manquait sans doute d'équilibre entre soldats, matériel et ravitaillement.")
		return true
	if float(s.front) >= 100.0:
		_finish()
		return true
	return false


func _stars() -> int:
	var f := float(s.front)
	if f >= 50.0:
		return 3
	if f >= 10.0:
		return 2
	if f > -40.0:
		return 1
	return 0


func _finish() -> void:
	over = true
	_refresh()
	var stars := _stars()
	var improved := Game.set_step(era_id, "state", stars)
	if stars > 0:
		Game.reward(60 + 40 * stars if improved else 20, 30 + 15 * stars, "Économie de guerre")
		Sfx.play("victory")
	else:
		Sfx.play("defeat")
	var heading := "Victoire décisive" if float(s.front) >= 100.0 else ("Le pays a tenu" if stars > 0 else "Le front s'effondre")
	var body := "%s : [b]%+d[/b]\n\n[font_size=40][color=#d4ac2b]%s[/color][/font_size]\n\n%s\n\n[color=#a8a48c]1 étoile : front au-dessus de −40. 2 étoiles : +10. 3 étoiles : +50.[/color]" % [era_eco.get("front", "Ligne de front"), int(round(float(s.front))), UI.stars(stars), era_eco.get("outro", "")]
	_end_modal(heading, body)


func _collapse(heading: String, text: String) -> void:
	over = true
	_refresh()
	Sfx.play("defeat")
	Game.set_step(era_id, "state", 0)
	_end_modal(heading, "%s\n\n[font_size=40][color=#d4ac2b]%s[/color][/font_size]\n\n[color=#a8a48c]Conseil : surveille le moral, garde un ravitaillement correct et équilibre soldats et matériel.[/color]" % [text, UI.stars(0)])


func _end_modal(heading: String, body: String) -> void:
	var v := UI.vbox(14)
	v.add_child(UI.title(heading, 34))
	v.add_child(UI.rich(body, true, 19))
	var row := UI.hbox(10)
	row.alignment = BoxContainer.ALIGNMENT_END
	v.add_child(row)
	row.add_child(UI.button("↻ Rejouer", func(): Nav.goto("economy", {"era": era_id}), 19))
	row.add_child(UI.primary_button("Retour à l'époque", func(): Nav.goto("era", {"era": era_id}), 19))
	UI.modal(self, v, 700)


## Tests : « auto » joue une partie équilibrée (budget réparti, emprunts aux tours 1, 3 et 5)
## en choisissant toujours la première option des événements.
func test_action(a: String) -> void:
	if a == "budget" or a == "turn":
		_change("armement", 40)
		_change("recrutement", 40)
		_change("logistique", 20)
		_change("moral", 10)
		if a == "turn":
			_end_turn()
		return
	if a != "auto":
		return
	auto_mode = true
	var weights := {"armement": 3.0, "recrutement": 3.0, "logistique": 2.0, "moral": 1.0, "diplomatie": 1.0, "recherche": 0.5}
	while not over:
		if turn in [1, 3, 5]:
			_borrow()
		var budget := int(s.tresor)
		for k in LINES:
			alloc[k] = int(budget * weights[k] / 10.5 / STEP) * STEP
		_end_turn()
		await get_tree().process_frame
	print("ECONOMY ", era_id, " front=", int(s.front), " stars=", _stars(), " moral=", int(s.moral), " dette=", int(s.dette))
