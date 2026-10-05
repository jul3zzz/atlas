extends Control
## L'État en guerre : cartes de décision façon « Reigns ».
## 4 jauges (Trésor, Armée, Peuple, Alliés) : si l'une tombe à 0 ou atteint 100, c'est la chute.
## Glisse la carte à gauche ou à droite, ou clique sur un choix.

const GAUGES := [
	["tresor", "Trésor", "◉", Color("d4ac2b")],
	["armee", "Armée", "⚔", Color("c0573a")],
	["peuple", "Peuple", "♟", Color("4e9ee0")],
	["allies", "Alliés", "✉", Color("7cb855")],
]
const ENDINGS := {
	"tresor0": ["Banqueroute", "Les caisses sont vides : l'État ne peut plus payer ses soldats ni ses fournisseurs. L'armée se disperse."],
	"tresor100": ["Le trésor dort", "Tu as amassé de l'or au lieu d'équiper tes troupes : l'ennemi en profite et prend l'avantage."],
	"armee0": ["Armée anéantie", "Tes troupes sont battues ou épuisées : plus rien ne protège le pays."],
	"armee100": ["Coup d'État", "Les généraux, devenus trop puissants, prennent le pouvoir à ta place."],
	"peuple0": ["Révolte", "Épuisé par la guerre, le peuple se soulève. Tu dois abandonner le pouvoir."],
	"peuple100": ["Fièvre guerrière", "La foule exaltée exige une offensive immédiate et totale… qui tourne à la catastrophe."],
	"allies0": ["Seul contre tous", "Isolé, ton pays doit affronter seul toutes les puissances ennemies."],
	"allies100": ["Sous tutelle", "Tu dépends tellement de tes alliés qu'ils décident désormais à ta place."],
}

var era_id := ""
var deck: Dictionary
var cards: Array = []
var index := 0
var values := {"tresor": 50.0, "armee": 50.0, "peuple": 50.0, "allies": 50.0}
var over := false

var _bars: Dictionary = {}
var _dots: Dictionary = {}
var _card: PanelContainer
var _who: Label
var _icon: Label
var _text: RichTextLabel
var _left: Button
var _right: Button
var _note: RichTextLabel
var _turn: Label
var _drag := false
var _drag_from := 0.0
var _card_home := Vector2.ZERO


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	theme = UI.theme
	era_id = String(Nav.params.get("era", "e08"))
	deck = Content.state_decks.get(era_id, {})
	var era := Content.era(era_id)
	Sfx.music("ambient")
	add_child(UI.map_background(Color(era.get("color", "#555")).darkened(0.86)))
	add_child(UI.top_bar("L'État en guerre · " + String(era.get("name", "")), func(): Nav.goto("era", {"era": era_id})))
	cards = deck.get("cards", []).duplicate()
	cards.shuffle()

	var root := UI.vbox(14)
	var m := UI.margin(root, 60, 84, 60, 20)
	m.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(m)
	# Jauges
	var grow := UI.hbox(30)
	grow.alignment = BoxContainer.ALIGNMENT_CENTER
	root.add_child(grow)
	for g in GAUGES:
		var v := UI.vbox(4)
		v.custom_minimum_size.x = 190
		var head := UI.hbox(6)
		var dot := UI.label("", 18, Color.WHITE)
		_dots[g[0]] = dot
		head.add_child(UI.label("%s  %s" % [g[2], g[1]], 21, g[3], UI.font_ui_bold))
		head.add_child(UI.expander())
		head.add_child(dot)
		v.add_child(head)
		var pb := UI.progress_bar(50, 100, false, 16)
		UI.gauge_style(pb, g[3])
		v.add_child(pb)
		_bars[g[0]] = pb
		grow.add_child(v)
	_turn = UI.label("", 18, UI.MUTED, UI.font_ui_bold)
	_turn.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(_turn)
	# Carte
	var center := CenterContainer.new()
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(center)
	var holder := Control.new()
	holder.custom_minimum_size = Vector2(1100, 420)
	center.add_child(holder)
	_left = UI.button("", func(): _choose("left"), 20)
	_left.custom_minimum_size = Vector2(250, 120)
	_left.position = Vector2(0, 150)
	_left.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	holder.add_child(_left)
	_right = UI.button("", func(): _choose("right"), 20)
	_right.custom_minimum_size = Vector2(250, 120)
	_right.position = Vector2(850, 150)
	_right.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	holder.add_child(_right)
	_left.mouse_entered.connect(func(): _preview("left"))
	_right.mouse_entered.connect(func(): _preview("right"))
	_left.mouse_exited.connect(func(): _preview(""))
	_right.mouse_exited.connect(func(): _preview(""))
	_card = UI.paper_panel(26)
	_card.custom_minimum_size = Vector2(520, 410)
	_card.size = Vector2(520, 410)
	_card_home = Vector2(290, 0)
	_card.position = _card_home
	_card.pivot_offset = Vector2(260, 500)
	_card.mouse_filter = Control.MOUSE_FILTER_STOP
	_card.gui_input.connect(_card_input)
	holder.add_child(_card)
	var cv := UI.vbox(8)
	cv.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_card.add_child(cv)
	var top := UI.hbox(12)
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cv.add_child(top)
	_icon = UI.label("", 52, Color("8a5a1a"))
	top.add_child(_icon)
	_who = UI.label("", 26, UI.INK, UI.font_read_bold)
	_who.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_who.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(_who)
	_text = UI.rich("", true, 21, UI.INK)
	_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cv.add_child(_text)
	_note = UI.rich("", true, 17, UI.TEXT)
	var np := UI.panel(12, Color("12160e", 0.9), UI.GOLD_DARK)
	np.add_child(_note)
	np.custom_minimum_size.y = 90
	root.add_child(np)
	if cards.is_empty():
		_text.text = "Ce jeu sera bientôt disponible pour cette époque."
		_left.visible = false
		_right.visible = false
		return
	_note.text = UI.nbsp("[b]%s[/b]\n[color=#a8a48c]Glisse la carte à gauche ou à droite (ou clique sur un choix). Garde les 4 jauges en équilibre pendant %d décisions.[/color]" % [deck.get("role", ""), cards.size()])
	_refresh_bars(false)
	_show_card()


func _show_card() -> void:
	var c: Dictionary = cards[index]
	_who.text = String(c.get("who", ""))
	_icon.text = String(c.get("icon", "♛"))
	_text.text = UI.nbsp(String(c.get("text", "")))
	_left.text = "◀  " + String(c.left.label)
	_right.text = String(c.right.label) + "  ▶"
	_turn.text = "%s %d / %d" % [deck.get("turn_label", "Décision"), index + 1, cards.size()]
	_card.position = _card_home + Vector2(0, 30)
	_card.rotation = 0.0
	_card.modulate.a = 0.0
	var tw := create_tween().set_parallel()
	tw.tween_property(_card, "position", _card_home, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(_card, "modulate:a", 1.0, 0.2)
	Sfx.play("card")


func _preview(side: String) -> void:
	for g in GAUGES:
		_dots[g[0]].text = ""
	if side == "" or over or index >= cards.size():
		return
	var fx: Dictionary = cards[index][side].get("fx", {})
	for k in fx:
		if _dots.has(k):
			var v := float(fx[k])
			# Comme dans Reigns : on montre l'importance, pas le sens.
			_dots[k].text = "●" if abs(v) >= 15 else "•"


func _card_input(event: InputEvent) -> void:
	if over:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_drag = true
			_drag_from = event.global_position.x
		else:
			_drag = false
			var dx := _card.position.x - _card_home.x
			if dx < -110:
				_choose("left")
			elif dx > 110:
				_choose("right")
			else:
				var tw := create_tween().set_parallel()
				tw.tween_property(_card, "position", _card_home, 0.2)
				tw.tween_property(_card, "rotation", 0.0, 0.2)
				_preview("")
	elif event is InputEventMouseMotion and _drag:
		var dx2: float = event.global_position.x - _drag_from
		_card.position.x = _card_home.x + dx2
		_card.rotation = dx2 * 0.0007
		_preview("left" if dx2 < -40 else ("right" if dx2 > 40 else ""))


func _choose(side: String) -> void:
	if over or index >= cards.size():
		return
	var c: Dictionary = cards[index]
	var ch: Dictionary = c[side]
	Sfx.play("stamp")
	for k in ch.get("fx", {}):
		if values.has(k):
			values[k] = clamp(float(values[k]) + float(ch.fx[k]), 0.0, 100.0)
	_refresh_bars(true)
	_preview("")
	_note.text = UI.nbsp("[b]%s[/b] — %s" % [ch.label, ch.get("note", "")])
	var tw := create_tween().set_parallel()
	tw.tween_property(_card, "position", _card_home + Vector2(-700 if side == "left" else 700, 60), 0.3)
	tw.tween_property(_card, "rotation", -0.4 if side == "left" else 0.4, 0.3)
	tw.tween_property(_card, "modulate:a", 0.0, 0.3)
	var end := _check_end()
	index += 1
	var tw2 := create_tween()
	tw2.tween_interval(0.45)
	tw2.tween_callback(func():
		if end != "":
			_game_over(end)
		elif index >= cards.size():
			_victory()
		else:
			_show_card())


func _refresh_bars(animate: bool) -> void:
	for k in _bars:
		var pb: ProgressBar = _bars[k]
		if animate:
			var tw := create_tween()
			tw.tween_property(pb, "value", float(values[k]), 0.35)
		else:
			pb.value = float(values[k])


func _check_end() -> String:
	for k in values:
		if float(values[k]) <= 0.0:
			return k + "0"
		if float(values[k]) >= 100.0:
			return k + "100"
	return ""


func _game_over(key: String) -> void:
	over = true
	Sfx.play("defeat")
	var e: Array = ENDINGS.get(key, ["Fin", ""])
	var body := "%s\n\n[color=#a8a48c]Tu as tenu %d décisions sur %d. Toutes les jauges comptent : un État en guerre doit équilibrer finances, armée, moral de la population et diplomatie.[/color]" % [e[1], index, cards.size()]
	_end_modal(e[0], body, 0)


func _victory() -> void:
	over = true
	var balanced := 0
	for k in values:
		var v := float(values[k])
		if v >= 25.0 and v <= 75.0:
			balanced += 1
	var stars := 1
	if balanced == 4:
		stars = 2
		var all_tight := true
		for k in values:
			if float(values[k]) < 35.0 or float(values[k]) > 65.0:
				all_tight = false
		if all_tight:
			stars = 3
	var improved := Game.set_step(era_id, "state", stars)
	Game.reward(60 + 40 * stars if improved else 20, 30 + 15 * stars, "État en guerre")
	Sfx.play("victory")
	var body := "Ton pays a tenu bon pendant toute la guerre.\n\n[font_size=40][color=#d4ac2b]%s[/color][/font_size]\n\n%s\n\n[color=#a8a48c]2 étoiles : finir avec les 4 jauges entre 25 et 75. 3 étoiles : entre 35 et 65.[/color]" % [UI.stars(stars), String(deck.get("outro", ""))]
	_end_modal("Mission accomplie", body, stars)


func _end_modal(title: String, body: String, _stars: int) -> void:
	var v := UI.vbox(14)
	v.add_child(UI.title(title, 34))
	v.add_child(UI.rich(body, true, 19))
	var row := UI.hbox(10)
	row.alignment = BoxContainer.ALIGNMENT_END
	v.add_child(row)
	row.add_child(UI.button("↻ Rejouer", func(): Nav.goto("state", {"era": era_id}), 19))
	row.add_child(UI.primary_button("Retour à l'époque", func(): Nav.goto("era", {"era": era_id}), 19))
	UI.modal(self, v, 700)


func test_action(_a: String) -> void:
	for i in 3:
		_choose("right")
		await get_tree().create_timer(0.6).timeout
