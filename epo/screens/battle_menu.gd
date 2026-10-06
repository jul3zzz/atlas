extends Control
## Choix d'une bataille : scénarios historiques, bac à sable, codes de défi.

var era_id := ""
var sandbox := false


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme = UI.theme
	era_id = String(Nav.params.get("era", ""))
	sandbox = bool(Nav.params.get("sandbox", false)) or era_id == ""
	Sfx.music("march")
	add_child(UI.map_background())
	var back := func(): Nav.goto("era", {"era": era_id}) if era_id != "" and not sandbox else Nav.goto("hub")
	add_child(UI.top_bar("Batailles" if sandbox else "Batailles · " + String(Content.era(era_id).get("name", "")), back))

	var row := UI.hbox(26)
	var m := UI.margin(row, 50, 92, 50, 30)
	m.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(m)

	var left := UI.vbox(12)
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(left)
	left.add_child(UI.title("Scénarios historiques", 32))
	var list := UI.vbox(10)
	left.add_child(UI.scroll(list))
	var battles: Array = Content.battles if sandbox else Content.battles_for_era(era_id)
	for b in battles:
		list.add_child(_battle_card(b))

	var right := UI.vbox(14)
	right.custom_minimum_size.x = 440
	row.add_child(right)
	var sb := UI.panel(20)
	right.add_child(sb)
	var sv := UI.vbox(10)
	sb.add_child(sv)
	sv.add_child(UI.title("Bac à sable", 28))
	sv.add_child(UI.wrap_label("Place les deux armées comme tu veux, mélange les époques (légionnaires contre chars ?) et regarde ce qui se passe. Idéal pour tester des idées… ou pour rire.", 17, UI.MUTED))
	sv.add_child(UI.primary_button("Ouvrir le bac à sable", func(): Nav.goto("battle", {"sandbox": true, "era": era_id if not sandbox else ""}), 21))

	var cp := UI.panel(20)
	right.add_child(cp)
	var cv := UI.vbox(10)
	cp.add_child(cv)
	cv.add_child(UI.title("Code de défi", 28))
	cv.add_child(UI.wrap_label("Un ami t'a envoyé un code ? Colle-le ici. Pour créer ton propre défi, place une armée rouge dans le bac à sable puis clique sur « Code de défi ».", 17, UI.MUTED))
	var inp := LineEdit.new()
	inp.placeholder_text = "EPO1-…"
	cv.add_child(inp)
	cv.add_child(UI.button("Relever le défi", func():
		if Challenge.decode(inp.text).is_empty():
			Sfx.play("error")
			UI.toast("Ce code de défi n'est pas valide.", UI.RED)
			return
		Nav.goto("battle", {"challenge": inp.text.strip_edges()}), 20))

	var how := UI.panel(16, Color(UI.PANEL, 0.85))
	right.add_child(how)
	how.add_child(UI.rich("[b]Comment ça marche ?[/b]\n1. Dépense ton budget en plaçant tes unités dans la zone bleue.\n2. Lance la bataille : tes soldats combattent seuls.\n3. Victoire = 1 étoile. Garde 35 % de ton armée = 2 étoiles. Dépense 80 % du budget au maximum = 3 étoiles.\n\nAttaquer de flanc ou dans le dos fait plus de dégâts. Les abris (murets, tranchées) protègent des tirs.", false, 16))


func _battle_card(b: Dictionary) -> Control:
	var era := Content.era(String(b.era))
	var p := UI.panel(16, Color(UI.PANEL, 0.95), Color(era.get("color", "#888")).darkened(0.1))
	var row := UI.hbox(16)
	p.add_child(row)
	var v := UI.vbox(4)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(v)
	v.add_child(UI.label(String(b.name), 25, UI.TEXT, UI.font_ui_bold))
	v.add_child(UI.label("%s  ·  %s contre %s" % [b.get("date", ""), b.get("player_side", ""), b.get("enemy_side", "")], 16, Color(era.get("color", "#888")).lightened(0.4), UI.font_ui_bold))
	var intro := String(b.get("intro", ""))
	if intro.length() > 210:
		intro = intro.substr(0, 207) + "…"
	v.add_child(UI.wrap_label(intro, 16, UI.MUTED))
	var right := UI.vbox(6)
	right.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_child(right)
	var best := int(Game.best("battle_" + String(b.id), 0))
	var stars := UI.label(UI.stars(best), 28, UI.GOLD)
	stars.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	right.add_child(stars)
	right.add_child(UI.primary_button("Jouer", func(): Nav.goto("battle", {"battle": b.id}), 21, 140))
	right.add_child(UI.label("Budget ◉ %d" % int(b.get("budget", 0)), 15, UI.MUTED))
	return p
