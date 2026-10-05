extends Node
## Thème visuel commun + petites fonctions pour construire l'interface en code.

const BG := Color("14170f")
const PANEL := Color("212819")
const PANEL_LIGHT := Color("2e3723")
const BORDER := Color("4f5c39")
const GOLD := Color("d4ac2b")
const GOLD_DARK := Color("8a6f17")
const TEXT := Color("ece4cb")
const MUTED := Color("a8a48c")
const RED := Color("d0493a")
const GREEN := Color("7cb855")
const BLUE_TEAM := Color("3d7fd1")
const RED_TEAM := Color("cf3d3a")
const PAPER := Color("efe3c4")
const INK := Color("2a2418")

const RARITY_COLORS := {
	"commune": Color("b9b6a5"),
	"rare": Color("4e9ee0"),
	"epique": Color("b06ae0"),
	"legendaire": Color("f0b429"),
}
const RARITY_NAMES := {
	"commune": "Commune",
	"rare": "Rare",
	"epique": "Épique",
	"legendaire": "Légendaire",
}

var theme: Theme
var font_ui: FontFile
var font_ui_bold: FontFile
var font_title: FontFile
var font_read: FontFile
var font_read_bold: FontFile
var font_read_italic: FontFile
var bg_shader: Shader

var _toast_layer: CanvasLayer
var _toast_box: VBoxContainer


func _ready() -> void:
	font_ui = load("res://assets/fonts/Oswald-Regular.ttf")
	font_ui_bold = load("res://assets/fonts/Oswald-Bold.ttf")
	font_title = load("res://assets/fonts/BlackOpsOne-Regular.ttf")
	font_read = load("res://assets/fonts/Lora-Regular.ttf")
	font_read_bold = load("res://assets/fonts/Lora-Bold.ttf")
	font_read_italic = load("res://assets/fonts/Lora-Italic.ttf")
	# Les symboles (★ ◀ ⚔ …) manquent dans les polices principales : DejaVu Sans prend le relais.
	var symbols: FontFile = load("res://assets/fonts/DejaVuSans.ttf")
	for f in [font_ui, font_ui_bold, font_title, font_read, font_read_bold, font_read_italic]:
		f.fallbacks = [symbols]
	bg_shader = load("res://core/topo_bg.gdshader")
	_build_theme()
	_build_toasts()
	Game.xp_gained.connect(func(amount, reason):
		toast("+%d XP%s" % [amount, (" — " + reason) if reason != "" else ""], GOLD))
	Game.rank_up.connect(_on_rank_up)


# --- Thème --------------------------------------------------------------------

func _sb(bg: Color, border: Color, bw := 2, radius := 4, pad := 10) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(bw)
	s.set_corner_radius_all(radius)
	s.content_margin_left = pad + 4
	s.content_margin_right = pad + 4
	s.content_margin_top = pad * 0.6
	s.content_margin_bottom = pad * 0.6
	s.anti_aliasing = true
	return s


func _build_theme() -> void:
	theme = Theme.new()
	theme.default_font = font_ui
	theme.default_font_size = 20

	theme.set_stylebox("normal", "Button", _sb(PANEL_LIGHT, BORDER))
	theme.set_stylebox("hover", "Button", _sb(Color("3b4630"), GOLD))
	theme.set_stylebox("pressed", "Button", _sb(GOLD, GOLD))
	theme.set_stylebox("hover_pressed", "Button", _sb(GOLD, Color.WHITE))
	theme.set_stylebox("disabled", "Button", _sb(Color("1c2116"), Color("333a28")))
	var focus := _sb(Color(0, 0, 0, 0), GOLD, 2)
	theme.set_stylebox("focus", "Button", focus)
	theme.set_color("font_color", "Button", TEXT)
	theme.set_color("font_hover_color", "Button", Color.WHITE)
	theme.set_color("font_pressed_color", "Button", INK)
	theme.set_color("font_hover_pressed_color", "Button", INK)
	theme.set_color("font_focus_color", "Button", TEXT)
	theme.set_color("font_disabled_color", "Button", Color("6b6a5c"))
	theme.set_font("font", "Button", font_ui)

	for t in ["OptionButton", "MenuButton"]:
		theme.set_stylebox("normal", t, _sb(PANEL_LIGHT, BORDER))
		theme.set_stylebox("hover", t, _sb(Color("3b4630"), GOLD))
		theme.set_stylebox("pressed", t, _sb(Color("3b4630"), GOLD))
		theme.set_stylebox("focus", t, focus)
		theme.set_color("font_color", t, TEXT)
		theme.set_color("font_hover_color", t, Color.WHITE)

	var popup := _sb(PANEL, GOLD_DARK, 2, 4, 6)
	theme.set_stylebox("panel", "PopupMenu", popup)
	theme.set_stylebox("hover", "PopupMenu", _sb(Color("3b4630"), Color(0, 0, 0, 0), 0, 2, 4))
	theme.set_color("font_color", "PopupMenu", TEXT)
	theme.set_color("font_hover_color", "PopupMenu", GOLD)

	theme.set_stylebox("panel", "PanelContainer", _sb(Color(PANEL, 0.94), BORDER, 2, 6, 16))
	theme.set_stylebox("panel", "Panel", _sb(Color(PANEL, 0.94), BORDER, 2, 6, 16))
	theme.set_stylebox("panel", "TooltipPanel", _sb(Color("0f120b"), GOLD_DARK, 1, 3, 8))
	theme.set_color("font_color", "TooltipLabel", TEXT)
	theme.set_font_size("font_size", "TooltipLabel", 17)

	theme.set_color("font_color", "Label", TEXT)
	theme.set_color("font_shadow_color", "Label", Color(0, 0, 0, 0.0))

	var le := _sb(Color("10130c"), BORDER, 2, 4, 10)
	theme.set_stylebox("normal", "LineEdit", le)
	theme.set_stylebox("focus", "LineEdit", _sb(Color("10130c"), GOLD, 2, 4, 10))
	theme.set_color("font_color", "LineEdit", TEXT)
	theme.set_color("caret_color", "LineEdit", GOLD)
	theme.set_color("font_placeholder_color", "LineEdit", Color(MUTED, 0.6))
	theme.set_stylebox("normal", "TextEdit", le)
	theme.set_stylebox("focus", "TextEdit", _sb(Color("10130c"), GOLD, 2, 4, 10))
	theme.set_color("font_color", "TextEdit", TEXT)

	var pb_bg := _sb(Color("0d0f09"), BORDER, 1, 3, 0)
	var pb_fill := _sb(GOLD, GOLD, 0, 3, 0)
	theme.set_stylebox("background", "ProgressBar", pb_bg)
	theme.set_stylebox("fill", "ProgressBar", pb_fill)
	theme.set_color("font_color", "ProgressBar", INK)
	theme.set_font_size("font_size", "ProgressBar", 14)

	var slider := StyleBoxFlat.new()
	slider.bg_color = Color("0d0f09")
	slider.set_corner_radius_all(3)
	slider.content_margin_top = 3
	slider.content_margin_bottom = 3
	theme.set_stylebox("slider", "HSlider", slider)
	var area := slider.duplicate()
	area.bg_color = GOLD_DARK
	theme.set_stylebox("grabber_area", "HSlider", area)
	theme.set_stylebox("grabber_area_highlight", "HSlider", area)

	var sb_scroll := StyleBoxFlat.new()
	sb_scroll.bg_color = Color(0, 0, 0, 0.25)
	sb_scroll.set_corner_radius_all(4)
	sb_scroll.content_margin_left = 4
	sb_scroll.content_margin_right = 4
	var grab := StyleBoxFlat.new()
	grab.bg_color = Color(BORDER, 0.9)
	grab.set_corner_radius_all(4)
	var grab_h := grab.duplicate()
	grab_h.bg_color = GOLD_DARK
	for t in ["VScrollBar", "HScrollBar"]:
		theme.set_stylebox("scroll", t, sb_scroll)
		theme.set_stylebox("grabber", t, grab)
		theme.set_stylebox("grabber_highlight", t, grab_h)
		theme.set_stylebox("grabber_pressed", t, grab_h)

	theme.set_color("default_color", "RichTextLabel", TEXT)
	theme.set_font("normal_font", "RichTextLabel", font_ui)
	theme.set_font("bold_font", "RichTextLabel", font_ui_bold)
	theme.set_font("italics_font", "RichTextLabel", font_read_italic)
	theme.set_font_size("normal_font_size", "RichTextLabel", 20)
	theme.set_font_size("bold_font_size", "RichTextLabel", 20)
	theme.set_font_size("italics_font_size", "RichTextLabel", 19)

	theme.set_color("font_color", "CheckBox", TEXT)
	theme.set_color("font_hover_color", "CheckBox", Color.WHITE)
	theme.set_color("font_color", "CheckButton", TEXT)

	var tab_sel := _sb(PANEL_LIGHT, GOLD, 0, 4, 10)
	tab_sel.border_width_bottom = 3
	var tab_un := _sb(Color(PANEL, 0.7), BORDER, 0, 4, 10)
	theme.set_stylebox("tab_selected", "TabBar", tab_sel)
	theme.set_stylebox("tab_unselected", "TabBar", tab_un)
	theme.set_stylebox("tab_hovered", "TabBar", _sb(Color("3b4630"), GOLD, 0, 4, 10))
	theme.set_color("font_selected_color", "TabBar", GOLD)
	theme.set_color("font_unselected_color", "TabBar", MUTED)
	theme.set_color("font_hovered_color", "TabBar", TEXT)
	theme.set_stylebox("tab_selected", "TabContainer", tab_sel)
	theme.set_stylebox("tab_unselected", "TabContainer", tab_un)
	theme.set_stylebox("tab_hovered", "TabContainer", _sb(Color("3b4630"), GOLD, 0, 4, 10))
	theme.set_stylebox("panel", "TabContainer", _sb(Color(PANEL, 0.94), BORDER, 2, 6, 16))
	theme.set_color("font_selected_color", "TabContainer", GOLD)
	theme.set_color("font_unselected_color", "TabContainer", MUTED)
	theme.set_color("font_hovered_color", "TabContainer", TEXT)

	theme.set_stylebox("separator", "HSeparator", _line(BORDER))
	theme.set_constant("separation", "HSeparator", 12)


func _line(c: Color) -> StyleBoxLine:
	var l := StyleBoxLine.new()
	l.color = c
	l.thickness = 2
	return l


# --- Fabriques de nœuds -------------------------------------------------------

## Racine d'interface plein écran (à utiliser dans un CanvasLayer pour les écrans 3D).
func root_control() -> Control:
	var c := Control.new()
	c.set_anchors_preset(Control.PRESET_FULL_RECT)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.theme = theme
	return c


## Fond animé « carte d'état-major » (courbes de niveau).
func map_background(tint := Color("14170f")) -> ColorRect:
	var r := ColorRect.new()
	r.set_anchors_preset(Control.PRESET_FULL_RECT)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var m := ShaderMaterial.new()
	m.shader = bg_shader
	m.set_shader_parameter("base_color", tint)
	m.set_shader_parameter("line_color", tint.lightened(0.16))
	r.material = m
	return r


## Ancre un contrôle à un point de l'écran (ax, ay entre 0 et 1) avec un décalage.
## Le contrôle prend sa taille minimale et grandit vers l'intérieur de l'écran.
func pin(c: Control, ax: float, ay: float, ox := 0.0, oy := 0.0) -> void:
	c.anchor_left = ax
	c.anchor_right = ax
	c.anchor_top = ay
	c.anchor_bottom = ay
	c.offset_left = ox
	c.offset_right = ox
	c.offset_top = oy
	c.offset_bottom = oy
	c.grow_horizontal = Control.GROW_DIRECTION_END if ax < 0.25 else (Control.GROW_DIRECTION_BEGIN if ax > 0.75 else Control.GROW_DIRECTION_BOTH)
	c.grow_vertical = Control.GROW_DIRECTION_END if ay < 0.25 else (Control.GROW_DIRECTION_BEGIN if ay > 0.75 else Control.GROW_DIRECTION_BOTH)


func label(text: String, size := 20, color := TEXT, font: Font = null) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	if font:
		l.add_theme_font_override("font", font)
	return l


func wrap_label(text: String, size := 19, color := TEXT) -> Label:
	var l := label(text, size, color)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size.x = 120
	return l


func title(text: String, size := 48, color := GOLD) -> Label:
	var l := label(text, size, color, font_title)
	l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.6))
	l.add_theme_constant_override("shadow_offset_x", 3)
	l.add_theme_constant_override("shadow_offset_y", 3)
	return l


func button(text: String, cb: Callable = Callable(), size := 21, min_w := 0) -> Button:
	var b := Button.new()
	b.text = text
	b.add_theme_font_size_override("font_size", size)
	b.custom_minimum_size = Vector2(min_w, 0)
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.focus_mode = Control.FOCUS_NONE
	if cb.is_valid():
		b.pressed.connect(func():
			Sfx.play("click")
			cb.call())
	b.mouse_entered.connect(func(): Sfx.play("hover", -14.0))
	return b


## Gros bouton doré pour l'action principale d'un écran.
func primary_button(text: String, cb: Callable = Callable(), size := 24, min_w := 0) -> Button:
	var b := button(text, cb, size, min_w)
	b.add_theme_stylebox_override("normal", _sb(GOLD_DARK, GOLD))
	b.add_theme_stylebox_override("hover", _sb(GOLD, Color.WHITE))
	b.add_theme_color_override("font_color", Color.WHITE)
	b.add_theme_color_override("font_hover_color", INK)
	return b


func panel(pad := 16, bg := Color(PANEL, 0.94), border := BORDER) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", _sb(bg, border, 2, 6, pad))
	return p


func paper_panel(pad := 24) -> PanelContainer:
	var p := PanelContainer.new()
	var s := _sb(PAPER, Color("8c7a52"), 3, 4, pad)
	s.shadow_color = Color(0, 0, 0, 0.5)
	s.shadow_size = 12
	p.add_theme_stylebox_override("panel", s)
	return p


func vbox(sep := 10) -> VBoxContainer:
	var b := VBoxContainer.new()
	b.add_theme_constant_override("separation", sep)
	return b


func hbox(sep := 10) -> HBoxContainer:
	var b := HBoxContainer.new()
	b.add_theme_constant_override("separation", sep)
	return b


func spacer(h := 10, w := 0) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(w, h)
	return c


func expander() -> Control:
	var c := Control.new()
	c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	c.size_flags_vertical = Control.SIZE_EXPAND_FILL
	return c


func margin(child: Control, l := 24, t := 24, r := 24, b := 24) -> MarginContainer:
	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_left", l)
	m.add_theme_constant_override("margin_top", t)
	m.add_theme_constant_override("margin_right", r)
	m.add_theme_constant_override("margin_bottom", b)
	m.add_child(child)
	return m


## Texte riche (BBCode). reading=true : police de lecture (Lora) façon livre.
## Espaces insécables dans les nombres (« 80 000 ») et avant « : ; ! ? » à la française.
func nbsp(t: String) -> String:
	var re := RegEx.create_from_string("(\\d) (\\d{3})")
	t = re.sub(t, "$1\u00a0$2", true)
	for p in [" :", " ;", " !", " ?", " »", "« "]:
		t = t.replace(p, p.replace(" ", "\u00a0"))
	return t


func rich(bbcode: String, reading := false, size := 20, color := TEXT) -> RichTextLabel:
	bbcode = nbsp(bbcode)
	var r := RichTextLabel.new()
	r.bbcode_enabled = true
	r.fit_content = true
	r.scroll_active = false
	r.selection_enabled = false
	r.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	r.add_theme_color_override("default_color", color)
	if reading:
		r.add_theme_font_override("normal_font", font_read)
		r.add_theme_font_override("bold_font", font_read_bold)
		r.add_theme_font_override("italics_font", font_read_italic)
		r.add_theme_constant_override("line_separation", 6)
	r.add_theme_font_size_override("normal_font_size", size)
	r.add_theme_font_size_override("bold_font_size", size)
	r.add_theme_font_size_override("italics_font_size", size)
	r.text = bbcode
	return r


func scroll(child: Control) -> ScrollContainer:
	var s := ScrollContainer.new()
	s.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	s.size_flags_vertical = Control.SIZE_EXPAND_FILL
	s.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	child.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	s.add_child(child)
	return s


func stars(n: int, total := 3) -> String:
	var s := ""
	for i in total:
		s += "★" if i < n else "☆"
	return s


func progress_bar(value: float, max_value: float, show_pct := false, h := 14) -> ProgressBar:
	var p := ProgressBar.new()
	p.max_value = max_value
	p.value = value
	p.show_percentage = show_pct
	p.custom_minimum_size.y = h
	return p


func gauge_style(p: ProgressBar, color: Color) -> void:
	var fill := _sb(color, color, 0, 3, 0)
	p.add_theme_stylebox_override("fill", fill)


## Barre du haut commune : retour, titre de l'écran, grade, XP et solde.
func top_bar(screen_title: String, back: Callable = Callable()) -> PanelContainer:
	var bar := panel(10, Color("0f120b", 0.92), Color("2c3421"))
	bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	var row := hbox(16)
	bar.add_child(row)
	if back.is_valid():
		row.add_child(button("◀  Retour", back, 19))
	row.add_child(title(screen_title, 28))
	row.add_child(expander())
	if Game.has_profile():
		var info := vbox(2)
		var name_l := label("%s — %s" % [Game.current.name, Game.rank_name()], 18, TEXT, font_ui_bold)
		name_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		info.add_child(name_l)
		var rp := Game.rank_progress()
		var pb := progress_bar(rp[0], rp[1], false, 8)
		pb.custom_minimum_size.x = 220
		info.add_child(pb)
		row.add_child(info)
		var solde := label("◉ %d" % Game.solde(), 22, GOLD, font_ui_bold)
		solde.tooltip_text = "Ta solde : sert à ouvrir des caisses de ravitaillement."
		solde.mouse_filter = Control.MOUSE_FILTER_PASS
		row.add_child(solde)
		var on_solde := func(v): solde.text = "◉ %d" % v
		var on_xp := func(_a, _r):
			var p2 := Game.rank_progress()
			pb.max_value = p2[1]
			pb.value = p2[0]
			name_l.text = "%s — %s" % [Game.current.name, Game.rank_name()]
		Game.solde_changed.connect(on_solde)
		Game.xp_gained.connect(on_xp)
		bar.tree_exiting.connect(func():
			Game.solde_changed.disconnect(on_solde)
			Game.xp_gained.disconnect(on_xp))
	return bar


## Fenêtre modale simple (fond assombri + panneau centré).
func modal(parent: Node, content: Control, width := 640) -> Control:
	var shade := ColorRect.new()
	shade.color = Color(0, 0, 0, 0.65)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.add_child(center)
	var p := panel(24, Color(PANEL, 0.98), GOLD_DARK)
	p.custom_minimum_size.x = width
	p.add_child(content)
	center.add_child(p)
	parent.add_child(shade)
	p.scale = Vector2(0.9, 0.9)
	p.pivot_offset = Vector2(width / 2.0, 150)
	p.modulate.a = 0.0
	var tw := p.create_tween().set_parallel()
	tw.tween_property(p, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(p, "modulate:a", 1.0, 0.15)
	return shade


func message(parent: Node, heading: String, body: String, ok_text := "Compris", on_ok: Callable = Callable()) -> Control:
	var v := vbox(14)
	v.add_child(title(heading, 30))
	var r := rich(body, true, 19)
	r.custom_minimum_size.x = 560
	v.add_child(r)
	var row := hbox()
	row.alignment = BoxContainer.ALIGNMENT_END
	v.add_child(row)
	var shade := modal(parent, v)
	row.add_child(primary_button(ok_text, func():
		shade.queue_free()
		if on_ok.is_valid():
			on_ok.call()))
	return shade


# --- Notifications --------------------------------------------------------------

func _build_toasts() -> void:
	_toast_layer = CanvasLayer.new()
	_toast_layer.layer = 100
	add_child(_toast_layer)
	var root := root_control()
	_toast_layer.add_child(root)
	_toast_box = vbox(6)
	pin(_toast_box, 1.0, 0.0, -16, 84)
	_toast_box.custom_minimum_size.x = 400
	_toast_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_toast_box)


func toast(text: String, color := TEXT, duration := 2.6) -> void:
	var p := panel(8, Color("0f120b", 0.92), color.darkened(0.3))
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var l := label(text, 19, color, font_ui_bold)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	p.add_child(l)
	_toast_box.add_child(p)
	p.modulate.a = 0.0
	var tw := p.create_tween()
	tw.tween_property(p, "modulate:a", 1.0, 0.2)
	tw.tween_interval(duration)
	tw.tween_property(p, "modulate:a", 0.0, 0.4)
	tw.tween_callback(p.queue_free)


func _on_rank_up(rank: String) -> void:
	Sfx.play("rankup")
	var root := root_control()
	_toast_layer.add_child(root)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(center)
	var p := panel(28, Color("0f120b", 0.95), GOLD)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var v := vbox(6)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	var a := label("PROMOTION !", 22, MUTED, font_ui_bold)
	a.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(a)
	var t := title(rank, 44)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(t)
	p.add_child(v)
	center.add_child(p)
	p.modulate.a = 0.0
	var tw := root.create_tween()
	tw.tween_property(p, "modulate:a", 1.0, 0.3)
	tw.tween_interval(2.4)
	tw.tween_property(p, "modulate:a", 0.0, 0.5)
	tw.tween_callback(root.queue_free)
