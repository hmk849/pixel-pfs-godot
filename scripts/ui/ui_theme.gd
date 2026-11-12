class_name UITheme
extends RefCounted
## Pixpfs UI 主题 - 无畏契约风格：深色底、锋利边角、红/青强调色

const ACCENT := Color(1.0, 0.28, 0.36)       # 猩红
const ACCENT2 := Color(0.0, 0.85, 0.95)      # 电光青
const BG_DARK := Color(0.07, 0.08, 0.11, 0.92)
const BG_MID := Color(0.11, 0.12, 0.16, 0.95)
const BG_LIGHT := Color(0.16, 0.17, 0.22, 0.98)
const TEXT := Color(0.93, 0.94, 0.96)
const TEXT_DIM := Color(0.6, 0.62, 0.68)

static var _font: FontFile = null
static var _font_bold: FontFile = null

static func font() -> FontFile:
	if _font == null:
		if ResourceLoader.exists("res://assets/fonts/main.ttf"):
			_font = load("res://assets/fonts/main.ttf")
		else:
			_font = FontFile.new()
	return _font

static func font_bold() -> FontFile:
	if _font_bold == null:
		if ResourceLoader.exists("res://assets/fonts/bold.ttf"):
			_font_bold = load("res://assets/fonts/bold.ttf")
		else:
			_font_bold = font()
	return _font_bold

static func make_theme() -> Theme:
	var t := Theme.new()
	t.default_font = font()
	return t

# ---------- 控件工厂 ----------
static func label(text: String, size := 16, col := TEXT, bold := false) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	if bold:
		l.add_theme_font_override("font", font_bold())
	return l

static func button(text: String, size := 16, accent := ACCENT) -> Button:
	var b := Button.new()
	b.text = text
	b.add_theme_font_size_override("font_size", size)
	b.add_theme_font_override("font", font_bold())
	b.add_theme_color_override("font_color", TEXT)
	b.add_theme_color_override("font_hover_color", Color.WHITE)
	b.add_theme_color_override("font_pressed_color", Color(0.85, 0.85, 0.88))
	b.add_theme_color_override("font_focus_color", TEXT)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(accent.r, accent.g, accent.b, 0.14)
	sb.set_corner_radius_all(3)
	sb.set_border_width_all(1)
	sb.border_color = Color(accent.r, accent.g, accent.b, 0.75)
	sb.content_margin_left = 16.0
	sb.content_margin_right = 16.0
	sb.content_margin_top = 8.0
	sb.content_margin_bottom = 8.0
	var sbh := sb.duplicate() as StyleBoxFlat
	sbh.bg_color = Color(accent.r, accent.g, accent.b, 0.42)
	var sbp := sb.duplicate() as StyleBoxFlat
	sbp.bg_color = Color(accent.r, accent.g, accent.b, 0.6)
	b.add_theme_stylebox_override("normal", sb)
	b.add_theme_stylebox_override("hover", sbh)
	b.add_theme_stylebox_override("pressed", sbp)
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	b.mouse_filter = Control.MOUSE_FILTER_STOP
	return b

static func panel(bg := BG_DARK, radius := 4, border := true, border_col := Color(1, 1, 1, 0.08)) -> PanelContainer:
	var p := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.set_corner_radius_all(radius)
	if border:
		sb.set_border_width_all(1)
		sb.border_color = border_col
	sb.content_margin_left = 14.0
	sb.content_margin_right = 14.0
	sb.content_margin_top = 12.0
	sb.content_margin_bottom = 12.0
	p.add_theme_stylebox_override("panel", sb)
	return p

static func overlay_panel(bg := BG_DARK, radius := 6) -> PanelContainer:
	return panel(bg, radius, true, Color(ACCENT.r, ACCENT.g, ACCENT.b, 0.35))

static func slider(minv: float, maxv: float, stepv: float, val: float) -> HSlider:
	var s := HSlider.new()
	s.min_value = minv
	s.max_value = maxv
	s.step = stepv
	s.value = val
	s.custom_minimum_size = Vector2(180, 24)
	var grab := StyleBoxFlat.new()
	grab.bg_color = ACCENT
	grab.set_corner_radius_all(2)
	var track := StyleBoxFlat.new()
	track.bg_color = Color(1, 1, 1, 0.14)
	track.set_corner_radius_all(2)
	track.content_margin_top = 4.0
	track.content_margin_bottom = 4.0
	s.add_theme_stylebox_override("grabber_area", track)
	s.add_theme_stylebox_override("grabber_area_highlight", track)
	s.add_theme_stylebox_override("slider", StyleBoxEmpty.new())
	var g := StyleBoxFlat.new()
	g.bg_color = Color.WHITE
	g.set_corner_radius_all(2)
	g.content_margin_left = 4.0
	g.content_margin_right = 4.0
	g.content_margin_top = 8.0
	g.content_margin_bottom = 8.0
	s.add_theme_stylebox_override("grabber", g)
	s.add_theme_stylebox_override("grabber_highlight", g)
	s.add_theme_stylebox_override("grabber_focus", g)
	return s

static func check(val: bool) -> CheckButton:
	var c := CheckButton.new()
	c.button_pressed = val
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(1, 1, 1, 0.08)
	sb.set_corner_radius_all(3)
	c.add_theme_stylebox_override("normal", sb)
	c.add_theme_font_size_override("font_size", 15)
	c.add_theme_color_override("font_color", TEXT)
	return c

static func option(items: Array, selected := 0) -> OptionButton:
	var o := OptionButton.new()
	for it in items:
		o.add_item(str(it))
	o.selected = selected
	o.add_theme_font_size_override("font_size", 15)
	var sb := StyleBoxFlat.new()
	sb.bg_color = BG_LIGHT
	sb.set_corner_radius_all(3)
	sb.set_border_width_all(1)
	sb.border_color = Color(1, 1, 1, 0.12)
	sb.content_margin_left = 10.0
	sb.content_margin_right = 10.0
	o.add_theme_stylebox_override("normal", sb)
	o.add_theme_stylebox_override("hover", sb)
	o.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	o.add_theme_stylebox_override("popup", sb)
	return o

static func sep() -> Control:
	var c := ColorRect.new()
	c.color = Color(1, 1, 1, 0.07)
	c.custom_minimum_size = Vector2(0, 1)
	return c

static func color_swatch(c: Color, size := 26) -> Panel:
	var p := Panel.new()
	p.custom_minimum_size = Vector2(size, size)
	var sb := StyleBoxFlat.new()
	sb.bg_color = c
	sb.set_corner_radius_all(3)
	sb.set_border_width_all(1)
	sb.border_color = Color(1, 1, 1, 0.25)
	p.add_theme_stylebox_override("panel", sb)
	return p

# ---------- 全屏遮罩 ----------
static func dim(parent: Control, alpha := 0.6) -> ColorRect:
	var d := ColorRect.new()
	d.color = Color(0, 0, 0, alpha)
	d.set_anchors_preset(Control.PRESET_FULL_RECT)
	parent.add_child(d)
	return d

static func center_wrap(parent: Control) -> CenterContainer:
	var c := CenterContainer.new()
	c.set_anchors_preset(Control.PRESET_FULL_RECT)
	parent.add_child(c)
	return c

# ---------- HUD 数值条 ----------
static func stat_bar(parent: Control, name_txt: String, frac: float, col := ACCENT) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	var l := label(name_txt, 13, TEXT_DIM)
	l.custom_minimum_size = Vector2(52, 0)
	row.add_child(l)
	var bg := ColorRect.new()
	bg.color = Color(1, 1, 1, 0.08)
	bg.custom_minimum_size = Vector2(150, 8)
	row.add_child(bg)
	var fill := ColorRect.new()
	fill.color = col
	fill.custom_minimum_size = Vector2(150 * clampf(frac, 0.02, 1.0), 8)
	bg.add_child(fill)
	parent.add_child(row)
