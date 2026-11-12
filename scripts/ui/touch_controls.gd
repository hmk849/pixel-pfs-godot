class_name TouchControls
extends CanvasLayer
## Pixpfs 触屏控制：虚拟摇杆 + 滑屏视角 + 陀螺仪 + 可编辑按钮布局

var _root: Control
var _joy_origin := Vector2.ZERO
var _joy_id := -1
var _look_id := -1
var _look_last := Vector2.ZERO
var _joy_active := false
var _buttons: Dictionary = {}      # action -> Button
var _gyro_last := Vector2.ZERO
var _gyro_t := 0.0
var _enabled := false

const BUTTON_DEFS := [
	{"action": "fire", "label": "开火", "pos": [0.86, 0.72], "size": 1.3},
	{"action": "ads", "label": "开镜", "pos": [0.72, 0.78], "size": 1.0},
	{"action": "jump", "label": "跳", "pos": [0.90, 0.56], "size": 1.0},
	{"action": "crouch", "label": "蹲/铲", "pos": [0.76, 0.90], "size": 0.9},
	{"action": "reload", "label": "换弹", "pos": [0.63, 0.62], "size": 0.85},
	{"action": "inspect", "label": "检视", "pos": [0.63, 0.90], "size": 0.8},
	{"action": "switch_weapon", "label": "切枪", "pos": [0.55, 0.74], "size": 0.8},
]

func _ready() -> void:
	layer = 30
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	_root.gui_input.connect(_on_root_input)
	add_child(_root)
	_build_buttons()
	visible = false

func enable() -> void:
	_enabled = true
	visible = true
	if bool(G.settings.sens.gyro):
		setup_gyro()

func disable() -> void:
	_enabled = false
	visible = false

func _build_buttons() -> void:
	var scale_f := float(G.settings.controls.touch_size)
	for d in BUTTON_DEFS:
		var b := Button.new()
		var dia := 84.0 * float(d.size) * scale_f
		b.custom_minimum_size = Vector2(dia, dia)
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0.1, 0.11, 0.15, float(G.settings.controls.touch_opacity))
		sb.set_corner_radius_all(50)
		sb.set_border_width_all(2)
		sb.border_color = Color(UITheme.ACCENT.r, UITheme.ACCENT.g, UITheme.ACCENT.b, 0.5)
		b.add_theme_stylebox_override("normal", sb)
		var sbp := sb.duplicate() as StyleBoxFlat
		sbp.bg_color = Color(UITheme.ACCENT.r, UITheme.ACCENT.g, UITheme.ACCENT.b, float(G.settings.controls.touch_opacity) + 0.2)
		b.add_theme_stylebox_override("pressed", sbp)
		b.add_theme_stylebox_override("hover", sb)
		b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		b.add_theme_font_size_override("font_size", 13)
		b.add_theme_color_override("font_color", UITheme.TEXT)
		b.text = str(d.label)
		var action := str(d.action)
		b.button_down.connect(func(): G.touch_press(action))
		b.button_up.connect(func(): G.touch_release(action))
		_root.add_child(b)
		_buttons[action] = b
	# 暂停按钮
	var pause := Button.new()
	pause.text = "⏸"
	pause.custom_minimum_size = Vector2(46, 46)
	var psb := StyleBoxFlat.new()
	psb.bg_color = Color(0.1, 0.11, 0.15, float(G.settings.controls.touch_opacity))
	psb.set_corner_radius_all(8)
	pause.add_theme_stylebox_override("normal", psb)
	pause.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	pause.pressed.connect(func(): _open_pause())
	_root.add_child(pause)
	_buttons["_pause"] = pause
	_root.resized.connect(_relayout)
	_call_deferred_relayout()

func _call_deferred_relayout() -> void:
	await get_tree().process_frame
	_relayout()

func _relayout() -> void:
	var scale_f := float(G.settings.controls.touch_size)
	for d in BUTTON_DEFS:
		var b := _buttons.get(str(d.action)) as Button
		if b == null:
			continue
		var dia := 84.0 * float(d.size) * scale_f
		var pos_arr: Array = G.settings.controls.touch_layout.get(str(d.action), d.pos)
		b.position = Vector2(
			float(pos_arr[0]) * _root.size.x - dia / 2.0,
			float(pos_arr[1]) * _root.size.y - dia / 2.0)
	var pb := _buttons.get("_pause") as Button
	if pb:
		pb.position = Vector2(_root.size.x - 56, 60)

func _open_pause() -> void:
	var p := get_parent()
	while p != null:
		if p.has_method("open_pause_menu"):
			p.call("open_pause_menu")
			return
		p = p.get_parent()

func _on_root_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			if event.position.x < _root.size.x * 0.38 and _joy_id == -1:
				_joy_id = event.index
				_joy_origin = event.position
				_joy_active = true
			elif _look_id == -1:
				_look_id = event.index
				_look_last = event.position
		else:
			if event.index == _joy_id:
				_joy_id = -1
				_joy_active = false
				G.touch_move = Vector2.ZERO
			elif event.index == _look_id:
				_look_id = -1
	elif event is InputEventScreenDrag:
		var drag := event as InputEventScreenDrag
		if drag.index == _joy_id:
			var offset := (drag.position - _joy_origin) / 70.0
			G.touch_move = Vector2(clampf(offset.x, -1, 1), clampf(offset.y, -1, 1))
		elif drag.index == _look_id:
			G.add_look(drag.relative)

func _process(delta: float) -> void:
	if not _enabled:
		return
	# 布局编辑模式：拖动按钮
	if bool(G.settings.controls.get("touch_layout_edit", false)):
		_handle_layout_edit()
	# 陀螺仪
	_gyro_t += delta
	if bool(G.settings.sens.gyro) and _gyro_t > 0.05:
		_gyro_t = 0.0
		_poll_gyro()
	_root.queue_redraw()

func _handle_layout_edit() -> void:
	# 通过按钮拖动重定位（按下后拖动）
	for action in _buttons.keys():
		var b := _buttons[action] as Button
		if b.button_pressed and action != "_pause":
			var m := _root.get_local_mouse_position()
			b.position = m - b.size / 2.0
			G.settings.controls.touch_layout[action] = [m.x / _root.size.x, m.y / _root.size.y]
			G.save_settings()

func setup_gyro() -> void:
	if not OS.has_feature("web"):
		return
	var js := "window.__gyro=[0,0,0];window.addEventListener('deviceorientation',function(e){window.__gyro=[e.alpha||0,e.beta||0,e.gamma||0]});'ok'"
	JavaScriptBridge.eval(js)

func _poll_gyro() -> void:
	if not OS.has_feature("web"):
		return
	var res: Variant = JavaScriptBridge.eval("window.__gyro[0]+','+window.__gyro[1]")
	if res is String:
		var parts: PackedStringArray = (res as String).split(",")
		if parts.size() >= 2:
			var cur := Vector2(float(parts[0]), float(parts[1]))
			if _gyro_last != Vector2.ZERO:
				var d := cur - _gyro_last
				d.x = wrapf(d.x, -180, 180)
				var sens := float(G.settings.sens.gyro_sens) * 0.8
				G.add_look(Vector2(d.x * sens, -d.y * sens))
			_gyro_last = cur

func _draw() -> void:
	pass
