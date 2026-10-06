extends Control
## Écran titre d'EPO.


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme = UI.theme
	Sfx.music("march")
	add_child(UI.map_background())

	# Diorama 3D : un soldat de chaque époque qui défile.
	var diorama := preload("res://screens/title_diorama.gd").new()
	diorama.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(diorama)

	var root := UI.margin(UI.vbox(0), 70, 50, 70, 40)
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(root)
	var col: VBoxContainer = root.get_child(0)

	var t := UI.title("EPO", 150)
	col.add_child(t)
	var sub := UI.label("L'HISTOIRE DE LA GUERRE — DE L'USINE AU CHAMP DE BATAILLE", 24, UI.TEXT, UI.font_ui_bold)
	col.add_child(sub)
	col.add_child(UI.label("10 époques · batailles 3D · atelier d'armes · stratégie · quotidien du soldat", 19, UI.MUTED))
	col.add_child(UI.spacer(36))

	var buttons := UI.vbox(10)
	buttons.custom_minimum_size.x = 420
	buttons.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	col.add_child(buttons)

	if Game.has_profile():
		var b := UI.primary_button("▶  Continuer — %s" % Game.current.name, func(): Nav.goto("hub"), 26)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		buttons.add_child(b)
		buttons.add_child(_menu_button("Changer de profil", func(): Nav.goto("profiles")))
	else:
		var b := UI.primary_button("▶  Nouvelle partie", func(): Nav.goto("profiles"), 26)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		buttons.add_child(b)
	buttons.add_child(_menu_button("⚔  Bataille libre (bac à sable)", func(): _need_profile("battle_menu", {"sandbox": true})))
	buttons.add_child(_menu_button("✦  Caisses et collection", func(): _need_profile("crates")))
	buttons.add_child(_menu_button("★  Caserne : ton soldat", func(): _need_profile("barracks")))
	buttons.add_child(_menu_button("▶  Vidéothèque", func(): Nav.goto("videos")))
	buttons.add_child(_menu_button("⚙  Paramètres", func(): Nav.goto("settings")))
	buttons.add_child(_menu_button("✖  Quitter", func(): get_tree().quit()))

	col.add_child(UI.expander())
	var foot := UI.label("Version %s — jeu éducatif réalisé avec Godot Engine" % ProjectSettings.get_setting("application/config/version"), 15, UI.MUTED)
	col.add_child(foot)

	t.modulate.a = 0.0
	t.position.y -= 20
	var tw := create_tween()
	tw.tween_property(t, "modulate:a", 1.0, 0.6)


func _menu_button(text: String, cb: Callable) -> Button:
	var b := UI.button(text, cb, 21)
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	return b


func _need_profile(screen: String, p := {}) -> void:
	if Game.has_profile():
		Nav.goto(screen, p)
	else:
		UI.message(self, "Profil requis", "Crée d'abord ton profil de soldat : ta progression, tes cartes et ton uniforme y seront enregistrés.", "Créer mon profil", func(): Nav.goto("profiles"))
