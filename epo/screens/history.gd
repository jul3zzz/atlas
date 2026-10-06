extends Control
## Lecteur des chapitres d'histoire + page du livre de l'époque.

var era_id := ""
var era: Dictionary
var data: Dictionary
var chapters: Array = []
var page := 0
var _list: VBoxContainer
var _page_box: VBoxContainer
var _scroll: ScrollContainer
var _nav_label: Label


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme = UI.theme
	era_id = String(Nav.params.get("era", "e01"))
	era = Content.era(era_id)
	data = Content.history(era_id)
	chapters = data.get("chapters", [])
	Sfx.music("ambient")
	add_child(UI.map_background(Color(era.get("color", "#555")).darkened(0.85)))
	add_child(UI.top_bar("Histoire · " + String(era.get("name", "")), func(): Nav.goto("era", {"era": era_id})))

	var row := UI.hbox(24)
	var m := UI.margin(row, 40, 88, 40, 24)
	m.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(m)

	var side := UI.panel(14)
	side.custom_minimum_size.x = 330
	row.add_child(side)
	var sv := UI.vbox(8)
	side.add_child(sv)
	sv.add_child(UI.label("SOMMAIRE", 20, UI.GOLD, UI.font_ui_bold))
	_list = UI.vbox(6)
	sv.add_child(UI.scroll(_list))

	var main := UI.vbox(12)
	main.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(main)
	var paper := UI.paper_panel(34)
	paper.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main.add_child(paper)
	_page_box = UI.vbox(14)
	_scroll = UI.scroll(_page_box)
	paper.add_child(_scroll)
	var nav := UI.hbox(12)
	main.add_child(nav)
	nav.add_child(UI.button("◀  Précédent", func(): _show(page - 1), 19))
	nav.add_child(UI.expander())
	_nav_label = UI.label("", 18, UI.MUTED)
	nav.add_child(_nav_label)
	nav.add_child(UI.expander())
	nav.add_child(UI.primary_button("Suivant  ▶", func(): _next(), 19))
	_show(0)


func _read_list() -> Array:
	var p := Game.progress(era_id)
	if not p.has("read"):
		p["read"] = []
	return p.read


func _total_pages() -> int:
	return chapters.size() + 1


func _next() -> void:
	if page >= _total_pages() - 1:
		Nav.goto("quiz", {"era": era_id})
	else:
		_show(page + 1)


func _refresh_list() -> void:
	for c in _list.get_children():
		c.queue_free()
	var read := _read_list()
	for i in _total_pages():
		var title := String(chapters[i].title) if i < chapters.size() else "Le livre : " + String(data.get("book", {}).get("title", ""))
		var done := i in read
		var b := UI.button(("✔ " if done else "○ ") + title, func(): _show(i), 17)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		b.custom_minimum_size.x = 290
		if i == page:
			b.add_theme_stylebox_override("normal", UI._sb(Color("3b4630"), UI.GOLD))
		if done:
			b.add_theme_color_override("font_color", UI.GREEN)
		_list.add_child(b)


func _show(i: int) -> void:
	if chapters.is_empty() and data.get("book", {}).is_empty():
		for c in _page_box.get_children():
			c.queue_free()
		_page_box.add_child(UI.rich("[b]Contenu en préparation pour cette époque.[/b]", true, 20, UI.INK))
		return
	page = clamp(i, 0, _total_pages() - 1)
	Sfx.play("page", -4.0)
	for c in _page_box.get_children():
		c.queue_free()
	_scroll.scroll_vertical = 0
	if page < chapters.size():
		var ch: Dictionary = chapters[page]
		_page_box.add_child(UI.label("CHAPITRE %d" % (page + 1), 17, Color("8c7a52"), UI.font_ui_bold))
		var t := UI.label(String(ch.title), 36, UI.INK, UI.font_read_bold)
		t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_page_box.add_child(t)
		_page_box.add_child(UI.rich(String(ch.text), true, 21, UI.INK))
		if ch.has("fact"):
			var box := UI.panel(16, Color("e4d4ac"), Color("b0965a"))
			var bv := UI.vbox(6)
			box.add_child(bv)
			bv.add_child(UI.label("LE SAVIEZ-VOUS ?", 16, Color("8a5a1a"), UI.font_ui_bold))
			bv.add_child(UI.rich(String(ch.fact), true, 19, UI.INK))
			_page_box.add_child(box)
	else:
		_show_book()
	_mark_read(page)
	_refresh_list()
	_nav_label.text = "Page %d / %d" % [page + 1, _total_pages()]


func _show_book() -> void:
	var b: Dictionary = data.get("book", {})
	_page_box.add_child(UI.label("LE LIVRE DE L'ÉPOQUE", 17, Color("8c7a52"), UI.font_ui_bold))
	var t := UI.label(String(b.get("title", "")), 38, UI.INK, UI.font_read_bold)
	t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_page_box.add_child(t)
	_page_box.add_child(UI.label("%s — %s" % [b.get("author", ""), b.get("year", "")], 21, Color("5a4a2a"), UI.font_read_italic))
	_page_box.add_child(UI.rich(String(b.get("summary", "")), true, 21, UI.INK))
	if b.has("quote"):
		var q := UI.panel(18, Color("2a2418"), Color("8c7a52"))
		var qv := UI.vbox(6)
		q.add_child(qv)
		qv.add_child(UI.rich("[i]« %s »[/i]" % b.quote, true, 21, UI.PAPER))
		if b.has("quote_ref"):
			qv.add_child(UI.label("— " + String(b.quote_ref), 16, Color("c9b48a")))
		_page_box.add_child(q)
	if b.has("why"):
		_page_box.add_child(UI.rich("[b]Pourquoi le lire ?[/b] " + String(b.why), true, 20, UI.INK))
	var more: Array = data.get("more_books", [])
	if not more.is_empty():
		_page_box.add_child(UI.label("POUR ALLER PLUS LOIN", 17, Color("8c7a52"), UI.font_ui_bold))
		var txt := ""
		for mb in more:
			txt += "• [b]%s[/b] — %s. %s\n" % [mb.title, mb.author, mb.get("note", "")]
		_page_box.add_child(UI.rich(txt, true, 19, UI.INK))
	_page_box.add_child(UI.rich("[i]Page suivante : le quiz final de l'époque.[/i]", true, 18, Color("5a4a2a")))


func _mark_read(i: int) -> void:
	if not Game.has_profile():
		return
	var read := _read_list()
	if i in read:
		return
	read.append(i)
	Game.reward(30, 10, "Page lue")
	var stars := 0
	var ratio := float(read.size()) / float(_total_pages())
	if ratio >= 1.0:
		stars = 3
	elif ratio >= 0.66:
		stars = 2
	elif ratio >= 0.33:
		stars = 1
	Game.set_step(era_id, "history", stars)
	if stars == 3:
		UI.toast("Toutes les pages de l'époque sont lues !", UI.GREEN)
