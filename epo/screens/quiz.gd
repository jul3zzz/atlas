extends Control
## Quiz final d'une époque : 10 questions, réponses mélangées, explications.

var era_id := ""
var questions: Array = []
var index := 0
var score := 0
var answered := false
var _box: VBoxContainer
var _progress: ProgressBar
var _counter: Label


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme = UI.theme
	era_id = String(Nav.params.get("era", "e01"))
	var era := Content.era(era_id)
	Sfx.music("ambient")
	add_child(UI.map_background(Color(era.get("color", "#555")).darkened(0.85)))
	add_child(UI.top_bar("Quiz · " + String(era.get("name", "")), func(): Nav.goto("era", {"era": era_id})))
	var all: Array = Content.history(era_id).get("quiz", []).duplicate()
	all.shuffle()
	questions = all.slice(0, min(10, all.size()))

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.offset_top = 70
	add_child(center)
	var panel := UI.panel(30)
	panel.custom_minimum_size = Vector2(980, 0)
	center.add_child(panel)
	var v := UI.vbox(14)
	panel.add_child(v)
	var head := UI.hbox()
	v.add_child(head)
	_counter = UI.label("", 18, UI.MUTED, UI.font_ui_bold)
	head.add_child(_counter)
	head.add_child(UI.expander())
	_progress = UI.progress_bar(0, max(1, questions.size()), false, 10)
	_progress.custom_minimum_size.x = 400
	head.add_child(_progress)
	_box = UI.vbox(12)
	v.add_child(_box)
	if questions.is_empty():
		_box.add_child(UI.wrap_label("Le quiz de cette époque est en préparation.", 22))
		return
	_show_question()


func _show_question() -> void:
	answered = false
	for c in _box.get_children():
		c.queue_free()
	var q: Dictionary = questions[index]
	_counter.text = "QUESTION %d / %d   ·   SCORE %d" % [index + 1, questions.size(), score]
	_progress.value = index
	var ql := UI.rich("[b]%s[/b]" % q.q, false, 27)
	_box.add_child(ql)
	var order := range(q.a.size())
	order.shuffle()
	var buttons := []
	for i in order:
		var b := UI.button(String(q.a[i]), Callable(), 21)
		b.custom_minimum_size.y = 58
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		buttons.append([b, i])
		_box.add_child(b)
	for pair in buttons:
		var b: Button = pair[0]
		var i: int = pair[1]
		b.pressed.connect(func(): _answer(i, buttons, q))


func _answer(i: int, buttons: Array, q: Dictionary) -> void:
	if answered:
		return
	answered = true
	var ok := i == int(q.ok)
	if ok:
		score += 1
		Sfx.play("confirm")
	else:
		Sfx.play("error")
	for pair in buttons:
		var b: Button = pair[0]
		var idx: int = pair[1]
		b.disabled = true
		if idx == int(q.ok):
			b.add_theme_stylebox_override("disabled", UI._sb(Color("2f5a24"), UI.GREEN))
			b.add_theme_color_override("font_disabled_color", Color.WHITE)
		elif idx == i:
			b.add_theme_stylebox_override("disabled", UI._sb(Color("5a2420"), UI.RED))
			b.add_theme_color_override("font_disabled_color", Color.WHITE)
	var fb := UI.panel(14, Color("12160e"), UI.GREEN if ok else UI.RED)
	var fv := UI.vbox(4)
	fb.add_child(fv)
	fv.add_child(UI.label("BONNE RÉPONSE !" if ok else "RATÉ…", 20, UI.GREEN if ok else UI.RED, UI.font_ui_bold))
	if q.has("why"):
		fv.add_child(UI.rich(String(q.why), true, 18))
	_box.add_child(fb)
	var row := UI.hbox()
	row.alignment = BoxContainer.ALIGNMENT_END
	_box.add_child(row)
	var last := index >= questions.size() - 1
	row.add_child(UI.primary_button("Voir le résultat  ▶" if last else "Question suivante  ▶", func():
		if last:
			_finish()
		else:
			index += 1
			_show_question(), 21))
	_counter.text = "QUESTION %d / %d   ·   SCORE %d" % [index + 1, questions.size(), score]


func _finish() -> void:
	for c in _box.get_children():
		c.queue_free()
	_progress.value = questions.size()
	var n := questions.size()
	var stars := 0
	if score >= int(ceil(n * 0.9)):
		stars = 3
	elif score >= int(ceil(n * 0.7)):
		stars = 2
	elif score >= int(ceil(n * 0.5)):
		stars = 1
	var prev := Game.step_score(era_id, "quiz")
	var improved := Game.set_step(era_id, "quiz", stars)
	var xp := score * 15 if improved else score * 3
	Game.reward(xp, score * 5, "Quiz")
	Sfx.play("victory" if stars >= 2 else ("confirm" if stars == 1 else "defeat"))
	var t := UI.title("%d / %d" % [score, n], 72)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_box.add_child(t)
	var s := UI.label(UI.stars(stars), 54, UI.GOLD)
	s.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_box.add_child(s)
	var msg: String = ["Relis les chapitres et retente ta chance !", "Pas mal, soldat. Encore un effort !", "Très bien ! Presque parfait.", "Parfait ! Tu maîtrises cette époque."][stars]
	var ml := UI.label(msg, 22)
	ml.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_box.add_child(ml)
	if prev >= 0 and not improved:
		var pl := UI.label("Ton meilleur score reste %s." % UI.stars(prev), 17, UI.MUTED)
		pl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_box.add_child(pl)
	var row := UI.hbox(12)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	_box.add_child(row)
	row.add_child(UI.button("↻  Recommencer", func(): Nav.goto("quiz", {"era": era_id}), 20))
	row.add_child(UI.button("Relire les chapitres", func(): Nav.goto("history", {"era": era_id}), 20))
	row.add_child(UI.primary_button("Retour à l'époque", func(): Nav.goto("era", {"era": era_id}), 20))


func test_action(_a: String) -> void:
	if questions.size() > 0:
		_answer(int(questions[0].ok), [], questions[0])
