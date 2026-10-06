extends Control
## Vidéothèque : sélection de vidéos YouTube par époque (ouvertes dans le navigateur).
## Les miniatures sont téléchargées si l'ordinateur est connecté à Internet.

var era_filter := ""
var _list: GridContainer
var _filter: OptionButton


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme = UI.theme
	era_filter = String(Nav.params.get("era", ""))
	Sfx.music("ambient")
	add_child(UI.map_background())
	var back := func(): Nav.goto("era", {"era": era_filter}) if era_filter != "" else Nav.goto("hub" if Game.has_profile() else "title")
	add_child(UI.top_bar("Vidéothèque", back))
	var v := UI.vbox(12)
	var m := UI.margin(v, 50, 90, 50, 24)
	m.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(m)
	var head := UI.hbox(12)
	v.add_child(head)
	var intro := UI.wrap_label("Une sélection de vidéos de chaînes d'histoire reconnues. Elles s'ouvrent dans ton navigateur.", 18, UI.MUTED)
	intro.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(intro)
	_filter = OptionButton.new()
	_filter.custom_minimum_size.x = 320
	_filter.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_filter.add_item("Toutes les époques")
	for e in Content.eras:
		_filter.add_item("%d. %s" % [e.num, e.name])
	_filter.selected = 0 if era_filter == "" else Content.era_index(era_filter) + 1
	_filter.item_selected.connect(func(_i): _refresh())
	head.add_child(_filter)
	_list = GridContainer.new()
	_list.columns = 3
	_list.add_theme_constant_override("h_separation", 16)
	_list.add_theme_constant_override("v_separation", 16)
	v.add_child(UI.scroll(_list))
	_refresh()


func _refresh() -> void:
	for c in _list.get_children():
		c.queue_free()
	var idx := _filter.selected
	var vids: Array = Content.videos if idx == 0 else Content.videos_for_era(Content.eras[idx - 1].id)
	if vids.is_empty():
		_list.add_child(UI.wrap_label("Pas encore de vidéo pour cette époque.", 20, UI.MUTED))
	for vd in vids:
		_list.add_child(_card(vd))


func _card(vd: Dictionary) -> Control:
	var p := UI.panel(12)
	p.custom_minimum_size.x = 480
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var v := UI.vbox(6)
	p.add_child(v)
	var thumb := TextureRect.new()
	thumb.custom_minimum_size = Vector2(320, 180)
	thumb.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	thumb.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	var bg := ColorRect.new()
	bg.color = Color("0d0f09")
	bg.custom_minimum_size = Vector2(320, 180)
	bg.add_child(thumb)
	thumb.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var play := UI.label("▶", 54, Color(1, 1, 1, 0.85))
	play.set_anchors_preset(Control.PRESET_CENTER)
	play.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bg.add_child(play)
	UI.pin(play, 0.5, 0.5, 0, 0)
	v.add_child(bg)
	_load_thumb(String(vd.id), thumb)
	var era := Content.era(String(vd.get("era", "")))
	v.add_child(UI.label("%s · %s" % [era.get("name", ""), vd.get("duration", "")], 14, Color(era.get("color", "#888")).lightened(0.4), UI.font_ui_bold))
	var t := UI.label(String(vd.title), 19, UI.TEXT, UI.font_ui_bold)
	t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(t)
	v.add_child(UI.label(String(vd.get("channel", "")), 16, UI.MUTED))
	if vd.has("why"):
		v.add_child(UI.wrap_label(String(vd.why), 15, UI.MUTED))
	v.add_child(UI.expander())
	v.add_child(UI.button("Regarder sur YouTube", func(): OS.shell_open("https://www.youtube.com/watch?v=" + String(vd.id)), 18))
	return p


func _load_thumb(id: String, target: TextureRect) -> void:
	var cache := "user://miniatures/%s.jpg" % id
	if FileAccess.file_exists(cache):
		var img := Image.load_from_file(ProjectSettings.globalize_path(cache))
		if img:
			target.texture = ImageTexture.create_from_image(img)
		return
	if DisplayServer.get_name() == "headless":
		return
	var req := HTTPRequest.new()
	add_child(req)
	req.request_completed.connect(func(result, code, _headers, body):
		req.queue_free()
		if result != HTTPRequest.RESULT_SUCCESS or code != 200 or not is_instance_valid(target):
			return
		var img2 := Image.new()
		if img2.load_jpg_from_buffer(body) == OK:
			DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("user://miniatures"))
			img2.save_jpg(ProjectSettings.globalize_path(cache))
			target.texture = ImageTexture.create_from_image(img2))
	req.request("https://i.ytimg.com/vi/%s/mqdefault.jpg" % id)
