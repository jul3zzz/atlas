extends Control
## Choix d'une arme à examiner dans l'atelier + accès au bureau d'études.

var era_id := ""


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	theme = UI.theme
	era_id = String(Nav.params.get("era", "e08"))
	var era := Content.era(era_id)
	Sfx.music("ambient")
	add_child(UI.map_background(Color(era.get("color", "#555")).darkened(0.85)))
	add_child(UI.top_bar("Atelier · " + String(era.get("name", "")), func(): Nav.goto("era", {"era": era_id})))
	var row := UI.hbox(26)
	var m := UI.margin(row, 50, 92, 50, 30)
	m.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(m)

	var left := UI.vbox(12)
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(left)
	left.add_child(UI.title("Armes et machines de l'époque", 30))
	var list := UI.vbox(10)
	left.add_child(UI.scroll(list))
	var mine := Content.weapons_for_era(era_id)
	for w in mine:
		list.add_child(_card(w, true))
	if mine.is_empty():
		list.add_child(UI.wrap_label("Pas encore d'arme à démonter pour cette époque : essaie le bureau d'études !", 18, UI.MUTED))
	var others: Array = Content.weapon_order.filter(func(id): return Content.weapons[id].era != era_id)
	if not others.is_empty():
		list.add_child(UI.label("LES AUTRES ÉPOQUES", 18, UI.MUTED, UI.font_ui_bold))
		for id in others:
			list.add_child(_card(Content.weapons[id], false))

	var right := UI.vbox(14)
	right.custom_minimum_size.x = 440
	row.add_child(right)
	var p := UI.panel(22, Color(UI.PANEL, 0.95), UI.GOLD_DARK)
	right.add_child(p)
	var v := UI.vbox(10)
	p.add_child(v)
	v.add_child(UI.title("Bureau d'études", 30))
	var brief := _brief()
	v.add_child(UI.wrap_label("L'État passe commande : à toi de concevoir l'arme qui répond le mieux à son cahier des charges. Chaque choix technique est un compromis !", 17, UI.MUTED))
	if not brief.is_empty():
		v.add_child(UI.rich("[b]Commande :[/b] %s" % brief.get("title", ""), false, 18))
	var best := Game.best("design_" + era_id, null)
	if best != null:
		v.add_child(UI.label("Meilleure note : %d / 100" % int(best), 17, UI.GOLD))
	v.add_child(UI.primary_button("Entrer au bureau d'études", func(): Nav.goto("design", {"era": era_id}), 21))
	var tip := UI.panel(16, Color(UI.PANEL, 0.85))
	right.add_child(tip)
	tip.add_child(UI.rich("[b]Comment gagner les étoiles de l'atelier ?[/b]\n★ Lire l'histoire d'une arme\n★★ Regarder son fonctionnement animé\n★★★ Réussir le démontage sans erreur dans le temps imparti (ou inspecter toutes les pièces), ou obtenir 80/100 au bureau d'études.", false, 16))


func _brief() -> Dictionary:
	for b in Content.briefs:
		if b.get("era", "") == era_id:
			return b
	return {}


func _card(w: Dictionary, highlight: bool) -> Control:
	var era := Content.era(String(w.era))
	var p := UI.panel(14, Color(UI.PANEL, 0.95), Color(era.get("color", "#888")).darkened(0.1) if highlight else UI.BORDER)
	var r := UI.hbox(14)
	p.add_child(r)
	var v := UI.vbox(3)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	r.add_child(v)
	v.add_child(UI.label(String(w.name), 24 if highlight else 20, UI.TEXT, UI.font_ui_bold))
	v.add_child(UI.label("%s · %s · %s" % [w.get("type", ""), w.get("country", ""), w.get("year", "")], 15, Color(era.get("color", "#888")).lightened(0.4)))
	var feats := []
	if w.has("cycle"):
		feats.append("fonctionnement animé")
	if w.get("strip", []).size() > 0:
		feats.append("démontage chronométré")
	else:
		feats.append("inspection des pièces")
	feats.append("%d pièces" % w.get("parts", []).size())
	v.add_child(UI.label(" · ".join(feats), 15, UI.MUTED))
	var best = Game.best("strip_" + String(w.id), null)
	if best != null:
		v.add_child(UI.label("Record de démontage : %.1f s" % float(best), 15, UI.GOLD))
	r.add_child(UI.primary_button("Examiner", func(): Nav.goto("workshop", {"weapon": w.id, "era": era_id}), 19, 130))
	return p
