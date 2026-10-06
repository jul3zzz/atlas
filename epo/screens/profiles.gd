extends Control
## Création et choix du profil de joueur (sauvegardé sur l'ordinateur).

const NATIONS := [
	["france", "France"], ["royaume_uni", "Royaume-Uni"], ["etats_unis", "États-Unis"],
	["allemagne", "Allemagne"], ["russie", "Russie"], ["italie", "Italie"], ["espagne", "Espagne"],
	["japon", "Japon"], ["chine", "Chine"], ["pologne", "Pologne"], ["belgique", "Belgique"],
	["canada", "Canada"], ["suisse", "Suisse"], ["vietnam", "Vietnam"], ["algerie", "Algérie"],
	["maroc", "Maroc"], ["senegal", "Sénégal"], ["autre", "Autre"],
]

var _list: VBoxContainer
var _name: LineEdit
var _nation: OptionButton


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme = UI.theme
	add_child(UI.map_background())
	add_child(UI.top_bar("Profils", func(): Nav.goto("title")))

	var row := UI.hbox(30)
	var m := UI.margin(row, 60, 100, 60, 40)
	m.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(m)

	var left := UI.vbox(12)
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(left)
	left.add_child(UI.title("Tes soldats", 34))
	_list = UI.vbox(10)
	left.add_child(UI.scroll(_list))

	var right := UI.panel(24)
	right.custom_minimum_size.x = 520
	right.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	row.add_child(right)
	var form := UI.vbox(14)
	right.add_child(form)
	form.add_child(UI.title("Nouveau soldat", 32))
	form.add_child(UI.wrap_label("Ton profil enregistre ta progression, ton grade, ta solde, tes cartes et l'uniforme de ton soldat.", 18, UI.MUTED))
	form.add_child(UI.label("Ton nom de soldat", 19, UI.TEXT, UI.font_ui_bold))
	_name = LineEdit.new()
	_name.placeholder_text = "Ex. : Caporal Dupont"
	_name.max_length = 20
	_name.text_submitted.connect(func(_t): _create())
	form.add_child(_name)
	form.add_child(UI.label("Ta nation", 19, UI.TEXT, UI.font_ui_bold))
	_nation = OptionButton.new()
	for n in NATIONS:
		_nation.add_item(n[1])
	form.add_child(_nation)
	form.add_child(UI.spacer(6))
	form.add_child(UI.primary_button("Créer et partir au front  ▶", _create, 24))
	form.add_child(UI.wrap_label("Les profils sont enregistrés sur cet ordinateur. La connexion avec un compte Steam pourra être ajoutée lors de la publication du jeu.", 15, UI.MUTED))
	_refresh()
	if Game.profiles.is_empty():
		_name.call_deferred("grab_focus")


func _refresh() -> void:
	for c in _list.get_children():
		c.queue_free()
	if Game.profiles.is_empty():
		_list.add_child(UI.wrap_label("Aucun profil pour l'instant. Crée ton premier soldat à droite !", 20, UI.MUTED))
		return
	for p in Game.profiles:
		_list.add_child(_card(p))


func _card(p: Dictionary) -> Control:
	var panel := UI.panel(14, Color(UI.PANEL, 0.95), UI.GOLD if p.id == Game.current.get("id", "") else UI.BORDER)
	var row := UI.hbox(16)
	panel.add_child(row)
	var info := UI.vbox(2)
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(info)
	info.add_child(UI.label(String(p.name), 26, UI.TEXT, UI.font_ui_bold))
	var xp := int(p.get("xp", 0))
	var done := 0.0
	for e in Content.eras:
		var pr: Dictionary = p.get("progress", {}).get(e.id, {})
		for step in ["history", "quiz", "battle", "workshop", "state", "daily"]:
			done += clamp(float(pr.get(step, 0)), 0.0, 3.0) / 3.0
	var pct := int(round(done / (Content.eras.size() * 6.0) * 100.0)) if Content.eras.size() else 0
	info.add_child(UI.label("%s · %d XP · ◉ %d · %d %% du jeu terminé" % [Game.rank_name(xp), xp, int(p.get("solde", 0)), pct], 17, UI.MUTED))
	var play := UI.primary_button("Jouer", func():
		Game.select_profile(p.id)
		Nav.goto("hub"), 20)
	row.add_child(play)
	var del := UI.button("Supprimer", func(): _confirm_delete(p), 17)
	row.add_child(del)
	return panel


func _confirm_delete(p: Dictionary) -> void:
	var v := UI.vbox(14)
	v.add_child(UI.title("Supprimer ce profil ?", 28))
	v.add_child(UI.wrap_label("Le profil « %s » et toute sa progression seront définitivement effacés." % p.name, 19))
	var row := UI.hbox(10)
	row.alignment = BoxContainer.ALIGNMENT_END
	v.add_child(row)
	var shade: Control
	row.add_child(UI.button("Annuler", func(): shade.queue_free(), 19))
	var yes := UI.button("Supprimer définitivement", func():
		Game.delete_profile(p.id)
		shade.queue_free()
		_refresh(), 19)
	yes.add_theme_color_override("font_color", UI.RED)
	row.add_child(yes)
	shade = UI.modal(self, v, 560)


func _create() -> void:
	var n := _name.text.strip_edges()
	if n.length() < 2:
		Sfx.play("error")
		UI.toast("Choisis un nom d'au moins 2 lettres.", UI.RED)
		return
	Game.new_profile(n, NATIONS[_nation.selected][0])
	Sfx.play("confirm")
	UI.toast("Bienvenue sous les drapeaux, %s !" % n, UI.GOLD)
	Nav.goto("hub")
