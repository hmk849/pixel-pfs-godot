class_name SettingsScreen
extends CanvasLayer
## Pixpfs 设置中心：画面 / 键位 / 灵敏度 / 准心 / 音频

signal closed

var _tab := "video"
var _body: VBoxContainer
var _rebind_action := ""
var _rebind_btn: Button

func _ready() -> void:
	layer = 60
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(root)
	UITheme.dim(root, 0.8)

	var wrap := UITheme.center_wrap(root)
	var main := UITheme.overlay_panel()
	main.custom_minimum_size = Vector2(860, 600)
	wrap.add_child(main)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	main.add_child(v)

	var title_row := HBoxContainer.new()
	title_row.add_theme_constant_override("separation", 16)
	v.add_child(title_row)
	title_row.add_child(UITheme.label("设 置", 28, UITheme.TEXT, true))
	title_row.add_child(UITheme.label("SETTINGS", 12, UITheme.TEXT_DIM))
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_row.add_child(spacer)
	var close_btn := UITheme.button("保存并关闭", 15)
	close_btn.pressed.connect(func(): _close())
	title_row.add_child(close_btn)

	v.add_child(UITheme.sep())

	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 6)
	v.add_child(tabs)
	for t in [["video", "画面"], ["controls", "键位"], ["sens", "灵敏度"], ["crosshair", "准心"], ["audio", "音频"]]:
		var b := UITheme.button(t[1], 15, UITheme.ACCENT if _tab == t[0] else Color(1, 1, 1, 0.3))
		b.pressed.connect(func(): _switch_tab(t[0]))
		tabs.add_child(b)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(scroll)
	_body = VBoxContainer.new()
	_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_body.add_theme_constant_override("separation", 6)
	scroll.add_child(_body)

	_build_tab()

func _switch_tab(tab: String) -> void:
	_tab = tab
	Snd.play("ui_click")
	_rebind_action = ""
	for c in _body.get_children():
		c.queue_free()
	_build_tab()

func _row(name_txt: String, control: Control) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	var l := UITheme.label(name_txt, 15)
	l.custom_minimum_size = Vector2(170, 0)
	l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(l)
	row.add_child(control)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(spacer)
	_body.add_child(row)

func _build_tab() -> void:
	match _tab:
		"video": _tab_video()
		"controls": _tab_controls()
		"sens": _tab_sens()
		"crosshair": _tab_crosshair()
		"audio": _tab_audio()

# ================= 画面 =================
func _tab_video() -> void:
	var v: Dictionary = G.settings.video

	var fps := UITheme.option(["30", "60", "120", "144", "无限"], _fps_index(int(v.fps_cap)))
	fps.item_selected.connect(func(i):
		v.fps_cap = [30, 60, 120, 144, 0][i]
		G.apply_video())
	_row("帧率上限", fps)

	var color_modes := ["normal", "vivid", "soft", "realistic"]
	var color_names := ["正常", "鲜艳", "柔和", "写实"]
	var cm := UITheme.option(color_names, color_modes.find(str(v.color_mode)))
	cm.item_selected.connect(func(i):
		v.color_mode = color_modes[i]
		G.apply_color_mode())
	_row("画面颜色", cm)

	var ar := UITheme.option(["16:9", "4:3"], 0 if str(v.aspect) == "16:9" else 1)
	ar.item_selected.connect(func(i):
		v.aspect = "16:9" if i == 0 else "4:3"
		G.apply_aspect())
	_row("画面比例", ar)

	var scale := UITheme.slider(0.5, 1.0, 0.05, float(v.res_scale))
	scale.value_changed.connect(func(val):
		v.res_scale = val
		get_viewport().scaling_3d_scale = val)
	_row("渲染分辨率", scale)

	var msaa_modes := [Viewport.MSAA_DISABLED, Viewport.MSAA_2X, Viewport.MSAA_4X]
	var msaa := UITheme.option(["关闭", "2x", "4x"], msaa_modes.find(int(v.msaa)) as int)
	msaa.item_selected.connect(func(i):
		v.msaa = i
		get_viewport().msaa_3d = msaa_modes[i])
	_row("抗锯齿", msaa)

	var full := UITheme.check(bool(v.fullscreen))
	full.toggled.connect(func(on):
		v.fullscreen = on
		G.apply_video())
	_row("全屏", full)

	var shadows := UITheme.check(bool(v.shadows))
	shadows.toggled.connect(func(on):
		v.shadows = on
		G.save_settings())
	_row("阴影", shadows)

	var bright := UITheme.slider(0.7, 1.3, 0.05, float(v.brightness))
	bright.value_changed.connect(func(val):
		v.brightness = val
		G.apply_env())
	_row("亮度", bright)

	var fov := UITheme.slider(70, 110, 1.0, float(v.fov))
	fov.value_changed.connect(func(val):
		v.fov = val
		if G.player != null:
			G.player.call("refresh_fov"))
	_row("视野 FOV", fov)

# ================= 键位 =================
func _tab_controls() -> void:
	var c: Dictionary = G.settings.controls

	_body.add_child(_section("键盘按键（点击后按新键位重新绑定）"))
	for a in G.KEY_ACTIONS:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		var l := UITheme.label(str(a.name), 14)
		l.custom_minimum_size = Vector2(170, 0)
		row.add_child(l)
		var btn := UITheme.button(_bind_text(str(a.id)), 13, UITheme.ACCENT2)
		btn.custom_minimum_size = Vector2(160, 34)
		var aid := str(a.id)
		btn.pressed.connect(func():
			_rebind_action = aid
			_rebind_btn = btn
			btn.text = "按下新按键…")
		row.add_child(btn)
		var clear := UITheme.button("恢复", 12, Color(1, 1, 1, 0.3))
		clear.pressed.connect(func():
			c.binds.erase(aid)
			G._setup_input()
			G.save_settings()
			btn.text = _bind_text(aid))
		row.add_child(clear)
		_body.add_child(row)

	var reset := UITheme.button("全部恢复默认键位", 14, UITheme.ACCENT2)
	reset.pressed.connect(func():
		G.reset_binds()
		_switch_tab("controls"))
	_body.add_child(reset)
	_body.add_child(UITheme.sep())

	_body.add_child(_section("HUD 界面"))
	var hud_scale := UITheme.slider(0.6, 1.6, 0.05, float(c.hud_scale))
	hud_scale.value_changed.connect(func(val): c.hud_scale = val)
	_row("HUD 缩放", hud_scale)
	var hud_op := UITheme.slider(0.2, 1.0, 0.05, float(c.hud_opacity))
	hud_op.value_changed.connect(func(val): c.hud_opacity = val)
	_row("HUD 透明度", hud_op)
	_body.add_child(UITheme.sep())

	_body.add_child(_section("触屏按钮（移动端）"))
	var touch_mode := UITheme.option(["自动", "开启", "关闭"], ["auto", "on", "off"].find(str(c.touch_enabled)))
	touch_mode.item_selected.connect(func(i):
		c.touch_enabled = ["auto", "on", "off"][i])
	_row("触屏按钮", touch_mode)
	var tsize := UITheme.slider(0.6, 1.6, 0.05, float(c.touch_size))
	tsize.value_changed.connect(func(val): c.touch_size = val)
	_row("按钮大小", tsize)
	var top := UITheme.slider(0.2, 1.0, 0.05, float(c.touch_opacity))
	top.value_changed.connect(func(val): c.touch_opacity = val)
	_row("按钮透明度", top)
	var layout_edit := UITheme.check(false)
	layout_edit.toggled.connect(func(on):
		c.touch_layout_edit = on)
	_row("布局编辑模式（拖动按钮）", layout_edit)
	_body.add_child(UITheme.label("提示：开启布局编辑后，进入对局可直接拖动触屏按钮调整位置，自动保存。", 12, UITheme.TEXT_DIM))

func _section(txt: String) -> Label:
	var l := UITheme.label(txt, 17, UITheme.ACCENT2, true)
	return l

func _bind_text(action: String) -> String:
	if G.settings.controls.binds.has(action):
		var b: Dictionary = G.settings.controls.binds[action]
		if str(b.get("type", "")) == "mouse":
			return "鼠标 " + str(b.get("code"))
		var ev := InputEventKey.new()
		ev.physical_keycode = int(b.get("code", 0)) as Key
		return ev.as_text()
	var evs := InputMap.action_get_events(action)
	if evs.is_empty():
		return "未绑定"
	return evs[0].as_text()

func _unhandled_key_input(event: InputEvent) -> void:
	if _rebind_action == "":
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			_rebind_action = ""
			_rebuild_controls_tab()
			return
		G.rebind(_rebind_action, event)
		_rebind_action = ""
		_rebuild_controls_tab()
	elif event is InputEventMouseButton and event.pressed:
		G.rebind(_rebind_action, event)
		_rebind_action = ""
		_rebuild_controls_tab()

func _rebuild_controls_tab() -> void:
	_switch_tab("controls")

# ================= 灵敏度 =================
func _tab_sens() -> void:
	var s: Dictionary = G.settings.sens

	_body.add_child(_section("键鼠"))
	var mouse := UITheme.slider(0.1, 3.0, 0.05, float(s.mouse))
	mouse.value_changed.connect(func(val): s.mouse = val)
	_row("鼠标灵敏度", mouse)
	var ads := UITheme.slider(0.1, 1.5, 0.05, float(s.ads_mult))
	ads.value_changed.connect(func(val): s.ads_mult = val)
	_row("开镜灵敏度倍率", ads)

	var inv := UITheme.check(bool(s.invert_y))
	inv.toggled.connect(func(on): s.invert_y = on)
	_row("反转垂直视角", inv)
	_body.add_child(UITheme.sep())

	_body.add_child(_section("滑屏（触屏视角）"))
	var ts := UITheme.slider(0.1, 3.0, 0.05, float(s.touch))
	ts.value_changed.connect(func(val): s.touch = val)
	_row("滑屏灵敏度", ts)
	var da := UITheme.check(bool(s.dist_accel))
	da.toggled.connect(func(on): s.dist_accel = on)
	_row("距离加速", da)
	var das := UITheme.slider(0.0, 2.0, 0.1, float(s.dist_accel_str))
	das.value_changed.connect(func(val): s.dist_accel_str = val)
	_row("距离加速强度", das)
	var sa := UITheme.check(bool(s.speed_accel))
	sa.toggled.connect(func(on): s.speed_accel = on)
	_row("速度加速", sa)
	var sas := UITheme.slider(0.0, 2.0, 0.1, float(s.speed_accel_str))
	sas.value_changed.connect(func(val): s.speed_accel_str = val)
	_row("速度加速强度", sas)
	_body.add_child(UITheme.sep())

	_body.add_child(_section("陀螺仪"))
	var gyro := UITheme.check(bool(s.gyro))
	gyro.toggled.connect(func(on):
		s.gyro = on
		if G.player != null:
			G.player.call("setup_gyro"))
	_row("陀螺仪视角", gyro)
	var gs := UITheme.slider(0.1, 3.0, 0.05, float(s.gyro_sens))
	gs.value_changed.connect(func(val): s.gyro_sens = val)
	_row("陀螺仪灵敏度", gs)
	_body.add_child(UITheme.label("陀螺仪在手机浏览器中生效，需要设备权限。", 12, UITheme.TEXT_DIM))

# ================= 准心 =================
func _tab_crosshair() -> void:
	var ch: Dictionary = G.settings.crosshair

	var preview := CrosshairPreview.new()
	preview.custom_minimum_size = Vector2(0, 130)
	_body.add_child(preview)

	var styles := ["cross", "cross_dot", "dot"]
	var style_names := ["十字", "十字+点", "圆点"]
	var st := UITheme.option(style_names, styles.find(str(ch.style)))
	st.item_selected.connect(func(i):
		ch.style = styles[i]
		preview.queue_redraw())
	_row("准心样式", st)

	var swatches := HBoxContainer.new()
	swatches.add_theme_constant_override("separation", 6)
	for colr in [
		Color(1.0, 0.28, 0.36), Color(0.0, 1.0, 0.4), Color(0.0, 0.85, 0.95),
		Color(1.0, 0.9, 0.2), Color(1.0, 0.5, 0.1), Color(1.0, 1.0, 1.0),
	]:
		var cch := ch
		var b := UITheme.button("", 10)
		b.custom_minimum_size = Vector2(30, 30)
		var sb := StyleBoxFlat.new()
		sb.bg_color = colr
		sb.set_corner_radius_all(3)
		b.add_theme_stylebox_override("normal", sb)
		b.add_theme_stylebox_override("hover", sb)
		b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		b.pressed.connect(func():
			ch.color = [colr.r, colr.g, colr.b, 1.0]
			preview.queue_redraw())
		swatches.add_child(b)
	_row("准心颜色", swatches)

	var length := UITheme.slider(2, 22, 1, float(ch.length))
	length.value_changed.connect(func(val):
		ch.length = int(val)
		preview.queue_redraw())
	_row("长度", length)
	var thick := UITheme.slider(1, 6, 1, float(ch.thickness))
	thick.value_changed.connect(func(val):
		ch.thickness = int(val)
		preview.queue_redraw())
	_row("粗细", thick)
	var gap := UITheme.slider(0, 16, 1, float(ch.gap))
	gap.value_changed.connect(func(val):
		ch.gap = int(val)
		preview.queue_redraw())
	_row("间隙", gap)
	var dot := UITheme.check(bool(ch.dot))
	dot.toggled.connect(func(on):
		ch.dot = on
		preview.queue_redraw())
	_row("中心点", dot)
	var outline := UITheme.check(bool(ch.outline))
	outline.toggled.connect(func(on):
		ch.outline = on
		preview.queue_redraw())
	_row("黑色描边", outline)
	var hide := UITheme.check(bool(ch.hide_ads))
	hide.toggled.connect(func(on): ch.hide_ads = on)
	_row("开镜时隐藏准心", hide)

# ================= 音频 =================
func _tab_audio() -> void:
	var a: Dictionary = G.settings.audio
	var master := UITheme.slider(0.0, 1.0, 0.05, float(a.master))
	master.value_changed.connect(func(val):
		a.master = val
		AudioServer.set_bus_volume_db(0, linear_to_db(clampf(val, 0.0001, 1.0))))
	_row("主音量", master)
	var music := UITheme.slider(0.0, 1.0, 0.05, float(a.music))
	music.value_changed.connect(func(val):
		a.music = val
		Snd.refresh_volumes())
	_row("音乐", music)
	var sfx := UITheme.slider(0.0, 1.0, 0.05, float(a.sfx))
	sfx.value_changed.connect(func(val):
		a.sfx = val)
	_row("音效", sfx)

func _fps_index(cap: int) -> int:
	match cap:
		30: return 0
		60: return 1
		120: return 2
		144: return 3
		_: return 4

func _close() -> void:
	G.save_settings()
	Snd.play("ui_click")
	closed.emit()
	queue_free()

func _unhandled_input(event: InputEvent) -> void:
	if _rebind_action != "":
		if event is InputEventMouseButton and event.pressed:
			G.rebind(_rebind_action, event)
			_rebind_action = ""
			_rebuild_controls_tab()
		return
	if event.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()
		_close()

class CrosshairPreview:
	extends Control
	func _init() -> void:
		custom_minimum_size = Vector2(0, 130)
	func _draw() -> void:
		var bg := StyleBoxFlat.new()
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.05, 0.06, 0.08, 0.8))
		var center := size / 2.0
		var fake := {"style": str(G.settings.crosshair.style)}
		if fake.style == "cross_dot":
			fake.style = "cross"
		CrosshairDraw.draw_crosshair(self, center, G.settings.crosshair, 0.0)
		draw_rect(Rect2(Vector2.ZERO, size), Color(1, 1, 1, 0.05), false, 1.0)
