extends Control
## Bureau d'études : concevoir une arme selon le cahier des charges de l'État.
## Chaque option modifie les caractéristiques ; la commission note le résultat sur 100.

var era_id := ""
var brief: Dictionary
var choice: Dictionary = {}     # catégorie -> id d'option
var _bars: Dictionary = {}
var _cat_buttons: Dictionary = {}
var _verdict: Control


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme = UI.theme
	era_id = String(Nav.params.get("era", "e08"))
	for b in Content.briefs:
		if b.get("era", "") == era_id:
			brief = b
	var era := Content.era(era_id)
	Sfx.music("ambient")
	add_child(UI.map_background(Color(era.get("color", "#555")).darkened(0.85)))
	add_child(UI.top_bar("Bureau d'études · " + String(era.get("name", "")), func(): Nav.goto("workshop_menu", {"era": era_id})))
	if brief.is_empty():
		var l := UI.label("Pas de commande pour cette époque.", 24)
		UI.pin(l, 0.5, 0.5)
		add_child(l)
		return
	for cat in brief.categories:
		choice[cat] = _options(cat)[0].id

	var row := UI.hbox(22)
	var m := UI.margin(row, 36, 88, 36, 24)
	m.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(m)

	# Commande de l'État
	var left := UI.paper_panel(22)
	left.custom_minimum_size.x = 400
	row.add_child(left)
	var lv := UI.vbox(10)
	left.add_child(UI.scroll(lv))
	lv.add_child(UI.label("ORDRE DE COMMANDE · " + String(brief.year), 16, Color("8c7a52"), UI.font_ui_bold))
	var t := UI.label(String(brief.title), 28, UI.INK, UI.font_read_bold)
	t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lv.add_child(t)
	lv.add_child(UI.label("De la part de : " + String(brief.client), 16, Color("5a4a2a"), UI.font_read_italic))
	lv.add_child(UI.rich(String(brief.text), true, 18, UI.INK))
	lv.add_child(UI.label("CE QUI COMPTE POUR L'ÉTAT", 16, Color("8c7a52"), UI.font_ui_bold))
	var prio := ""
	var names := _stat_names()
	var ws: Dictionary = brief.weights
	var keys := ws.keys()
	keys.sort_custom(func(a, b): return float(ws[a]) > float(ws[b]))
	for k in keys:
		if float(ws[k]) > 0:
			prio += "%s  %s\n" % ["●".repeat(int(ws[k])) + "○".repeat(3 - int(ws[k])), names.get(k, k)]
	lv.add_child(UI.rich(prio, false, 18, UI.INK))

	# Choix techniques
	var mid := UI.vbox(12)
	mid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(mid)
	mid.add_child(UI.title("Tes choix techniques", 28))
	var mid_list := UI.vbox(12)
	mid.add_child(UI.scroll(mid_list))
	for cat in brief.categories:
		var c: Dictionary = Content.design_catalog.get(cat, {})
		var p := UI.panel(12)
		var pv := UI.vbox(6)
		p.add_child(pv)
		pv.add_child(UI.label(String(c.get("name", cat)).to_upper(), 17, UI.GOLD, UI.font_ui_bold))
		var orow := UI.hbox(8)
		pv.add_child(orow)
		_cat_buttons[cat] = []
		for o in _options(cat):
			var b := UI.button(String(o.name), func(): _choose(cat, String(o.id)), 17)
			b.toggle_mode = true
			b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			b.tooltip_text = String(o.get("desc", ""))
			b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			b.set_meta("opt", o.id)
			orow.add_child(b)
			_cat_buttons[cat].append(b)
		var d := UI.wrap_label("", 15, UI.MUTED)
		d.name = "Desc"
		pv.add_child(d)
		_cat_buttons[cat + "_desc"] = d
		mid_list.add_child(p)

	# Caractéristiques
	var right := UI.panel(18)
	right.custom_minimum_size.x = 340
	row.add_child(right)
	var rv := UI.vbox(8)
	right.add_child(rv)
	rv.add_child(UI.title("Ton prototype", 26))
	for s in Content.design_stats:
		var l := UI.label(String(s[1]), 17)
		rv.add_child(l)
		var pb := UI.progress_bar(5, 10, false, 12)
		rv.add_child(pb)
		_bars[s[0]] = pb
	rv.add_child(UI.spacer(8))
	rv.add_child(UI.primary_button("Soumettre à la commission", _submit, 20))
	var best = Game.best("design_" + era_id, null)
	if best != null:
		rv.add_child(UI.label("Meilleure note : %d / 100" % int(best), 16, UI.GOLD))
	_refresh()


func _stat_names() -> Dictionary:
	var d := {}
	for s in Content.design_stats:
		d[s[0]] = s[1]
	return d


func _options(cat: String) -> Array:
	var all: Array = Content.design_catalog.get(cat, {}).get("options", [])
	var ex: Array = brief.get("exclude", [])
	return all.filter(func(o): return not (o.id in ex))


func _option(cat: String, id: String) -> Dictionary:
	for o in _options(cat):
		if o.id == id:
			return o
	return {}


func _choose(cat: String, id: String) -> void:
	choice[cat] = id
	Sfx.play("part", -6.0)
	_refresh()


func _stats_for(ch: Dictionary) -> Dictionary:
	var st := {}
	for s in Content.design_stats:
		st[s[0]] = 5.0
	for cat in ch:
		var o := _option(cat, ch[cat])
		for k in o.get("fx", {}):
			st[k] = clamp(float(st.get(k, 5.0)) + float(o.fx[k]), 0.0, 10.0)
	return st


func _value(st: Dictionary) -> float:
	var v := 0.0
	for k in brief.weights:
		v += float(brief.weights[k]) * float(st.get(k, 5.0))
	return v


## Note sur 100 : position entre la pire et la meilleure combinaison possible.
func _score() -> int:
	var cats: Array = brief.categories
	var best := -INF
	var worst := INF
	var combos: Array = [{}]
	for cat in cats:
		var next := []
		for c in combos:
			for o in _options(cat):
				var d: Dictionary = c.duplicate()
				d[cat] = o.id
				next.append(d)
		combos = next
	for c in combos:
		var v := _value(_stats_for(c))
		best = max(best, v)
		worst = min(worst, v)
	var mine := _value(_stats_for(choice))
	if best - worst < 0.001:
		return 100
	return int(round(100.0 * (mine - worst) / (best - worst)))


func _refresh() -> void:
	for cat in brief.categories:
		for b in _cat_buttons[cat]:
			b.button_pressed = b.get_meta("opt") == choice[cat]
		var o := _option(cat, choice[cat])
		_cat_buttons[cat + "_desc"].text = String(o.get("desc", ""))
	var st := _stats_for(choice)
	for k in _bars:
		var pb: ProgressBar = _bars[k]
		var tw := create_tween()
		tw.tween_property(pb, "value", float(st.get(k, 5.0)), 0.2)
		var w := float(brief.weights.get(k, 0))
		UI.gauge_style(pb, UI.GOLD if w >= 3 else (UI.GOLD_DARK if w >= 2 else Color("6b6a5c")))


func _submit() -> void:
	var score := _score()
	var stars := 3 if score >= 80 else (2 if score >= 60 else (1 if score >= 40 else 0))
	var improved := Game.set_best("design_" + era_id, score)
	if stars > 0:
		Game.set_step(era_id, "workshop", stars)
	if improved:
		Game.reward(score + 20, score / 2, "Bureau d'études")
	Sfx.play("stamp")
	var verdict: String = ["REFUSÉE", "ACCEPTÉE AVEC RÉSERVES", "ADOPTÉE", "ADOPTÉE AVEC FÉLICITATIONS"][stars]
	var body := "[font_size=40][color=#d4ac2b]%d / 100[/color][/font_size]   %s\n\n" % [score, UI.stars(stars)]
	body += "[b]Avis de la commission sur tes choix :[/b]\n"
	for cat in brief.categories:
		var o := _option(cat, choice[cat])
		body += "• [b]%s[/b] — %s\n" % [o.get("name", ""), o.get("lesson", "")]
	body += "\n[b]Ce que l'histoire a retenu :[/b] " + String(brief.get("real", ""))
	UI.message(self, "Commission : " + verdict, body, "Retour à la planche à dessin")


func test_action(_a: String) -> void:
	_submit()
