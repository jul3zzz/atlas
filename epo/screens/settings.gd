extends Control
## Paramètres (son, affichage) et crédits.


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	theme = UI.theme
	add_child(UI.map_background())
	add_child(UI.top_bar("Paramètres", func(): Nav.goto("hub" if Game.has_profile() else "title")))
	var row := UI.hbox(26)
	var m := UI.margin(row, 60, 100, 60, 30)
	m.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(m)

	var p := UI.panel(24)
	p.custom_minimum_size.x = 560
	p.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	row.add_child(p)
	var v := UI.vbox(14)
	p.add_child(v)
	v.add_child(UI.title("Son et affichage", 28))
	v.add_child(_slider("Volume général", "volume_master"))
	v.add_child(_slider("Volume de la musique", "volume_music"))
	var fs := CheckButton.new()
	fs.text = "Plein écran"
	fs.button_pressed = bool(Game.settings.fullscreen)
	fs.toggled.connect(func(on):
		Game.settings.fullscreen = on
		Game.save_settings()
		Game.apply_settings())
	v.add_child(fs)
	v.add_child(UI.rich("[b]Commandes de la caméra (batailles, atelier)[/b]\nClic droit glissé : tourner · Molette : zoom · ZQSD, WASD ou flèches : se déplacer · Maj : plus vite · Clic sur un soldat : le suivre · Échap : caméra libre · P : pause", false, 17))

	var c := UI.panel(24)
	c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	c.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	row.add_child(c)
	var cv := UI.vbox(10)
	c.add_child(cv)
	cv.add_child(UI.title("Crédits", 28))
	cv.add_child(UI.rich("[b]EPO[/b] — jeu éducatif sur l'histoire militaire : ingénierie, stratégie, organisation des États et vie des soldats.\n\nRéalisé avec [b]Godot Engine[/b] (licence MIT).\nModèles 3D, sons et musiques : générés par le code du jeu (aucun fichier externe).\nPolices : Black Ops One, Oswald et Lora (SIL Open Font License), DejaVu Sans (licence libre).\nVidéos : liens vers des chaînes YouTube, propriété de leurs auteurs.\n\n[i]Les contenus historiques sont des résumés pédagogiques. Les chiffres anciens (effectifs, pertes) sont souvent des estimations débattues par les historiens.[/i]", false, 17))
	cv.add_child(UI.button("Encyclopédie (unités, grades, livres)", func(): Nav.goto("codex"), 19))


func _slider(label: String, key: String) -> Control:
	var v := UI.vbox(4)
	var l := UI.label("%s : %d %%" % [label, int(float(Game.settings[key]) * 100)], 19)
	v.add_child(l)
	var s := HSlider.new()
	s.min_value = 0.0
	s.max_value = 1.0
	s.step = 0.05
	s.value = float(Game.settings[key])
	s.custom_minimum_size.y = 24
	s.value_changed.connect(func(val):
		Game.settings[key] = val
		l.text = "%s : %d %%" % [label, int(val * 100)]
		Game.apply_settings()
		Sfx.refresh_music_volume())
	s.drag_ended.connect(func(_c): Game.save_settings())
	v.add_child(s)
	return v
