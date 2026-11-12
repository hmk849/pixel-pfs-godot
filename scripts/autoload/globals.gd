extends Node
## Pixpfs 全局管理器（autoload: G）- 设置、输入、触屏状态、游戏状态

const SETTINGS_PATH := "user://settings.json"
const LOADOUT_PATH := "user://loadout.json"

var settings := {
	"video": {
		"fps_cap": 0, "color_mode": "normal", "aspect": "16:9", "res_scale": 1.0,
		"fullscreen": false, "msaa": 0, "shadows": true, "brightness": 1.0, "fov": 95.0,
	},
	"controls": {
		"binds": {}, "hud_scale": 1.0, "hud_opacity": 1.0,
		"touch_enabled": "auto", "touch_size": 1.0, "touch_opacity": 0.65, "touch_layout": {},
	},
	"sens": {
		"mouse": 1.0, "ads_mult": 0.65, "touch": 1.0,
		"dist_accel": true, "dist_accel_str": 0.6,
		"speed_accel": true, "speed_accel_str": 0.8,
		"gyro": false, "gyro_sens": 1.0, "invert_y": false,
	},
	"crosshair": {
		"style": "cross", "color": [1.0, 0.28, 0.36, 1.0], "length": 9, "thickness": 2,
		"gap": 5, "dot": false, "outline": true, "hide_ads": true, "dynamic": true,
	},
	"audio": {"master": 1.0, "music": 0.55, "sfx": 1.0},
}

var loadout := {"weapon": "px4", "operator": "ghost"}

var state := "boot"        # boot / lobby / training / match
var current_map := "rust"
var smoke := false
var shot_dir := ""

# --- 运行时引用 ---
var player: Node = null
var hud: CanvasLayer = null
var env: Environment = null

# --- 触屏输入状态 ---
var touch := {}            # action -> 按住
var touch_just := {}       # action -> 本帧刚按下
var touch_look := Vector2.ZERO
var touch_start := Vector2.ZERO
var touch_active := false
var touch_gyro := Vector2.ZERO
var touch_move := Vector2.ZERO

# --- 键位表 ---
const KEY_ACTIONS := [
	{"id": "move_forward", "name": "前进"},
	{"id": "move_back", "name": "后退"},
	{"id": "move_left", "name": "左移"},
	{"id": "move_right", "name": "右移"},
	{"id": "jump", "name": "跳跃"},
	{"id": "sprint", "name": "疾跑"},
	{"id": "crouch", "name": "蹲下 / 滑铲"},
	{"id": "reload", "name": "换弹"},
	{"id": "inspect", "name": "检视武器"},
	{"id": "switch_weapon", "name": "切换武器"},
	{"id": "interact", "name": "互动"},
	{"id": "pause", "name": "暂停菜单"},
	{"id": "fire", "name": "开火"},
	{"id": "ads", "name": "开镜"},
]

func _ready() -> void:
	smoke = OS.get_environment("PIXPFS_SMOKE") == "1"
	shot_dir = OS.get_environment("PIXPFS_SHOT")
	process_mode = Node.PROCESS_MODE_ALWAYS
	_load_settings()
	_load_loadout()
	_setup_input()
	apply_video()

# ================= 输入 =================
func _setup_input() -> void:
	var defaults := {
		"move_forward": [KEY_W, KEY_UP], "move_back": [KEY_S, KEY_DOWN],
		"move_left": [KEY_A, KEY_LEFT], "move_right": [KEY_D, KEY_RIGHT],
		"jump": [KEY_SPACE], "sprint": [KEY_SHIFT], "crouch": [KEY_C],
		"reload": [KEY_R], "inspect": [KEY_F], "switch_weapon": [KEY_Q],
		"interact": [KEY_E], "pause": [KEY_ESCAPE],
	}
	var mouse_defaults := {"fire": MOUSE_BUTTON_LEFT, "ads": MOUSE_BUTTON_RIGHT}
	for a in defaults.keys():
		_ensure_action(a)
		InputMap.action_erase_events(a)
		var evs: Array = []
		var has_custom := false
		if settings.controls.binds.has(a):
			var e := _bind_to_event(settings.controls.binds[a])
			if e != null:
				evs.push_back(e)
				has_custom = true
		if not has_custom:
			for k in defaults[a]:
				evs.push_back(_key_event(k))
		for e in evs:
			InputMap.action_add_event(a, e)
	for a in mouse_defaults.keys():
		_ensure_action(a)
		InputMap.action_erase_events(a)
		var ev: InputEvent
		if settings.controls.binds.has(a):
			ev = _bind_to_event(settings.controls.binds[a])
		if ev == null:
			ev = InputEventMouseButton.new()
			ev.button_index = mouse_defaults[a]
		InputMap.action_add_event(a, ev)

func _ensure_action(a: String) -> void:
	if not InputMap.has_action(a):
		InputMap.add_action(a)

func _key_event(k: int) -> InputEvent:
	var e := InputEventKey.new()
	e.physical_keycode = k as Key
	return e

func _bind_to_event(b: Dictionary) -> InputEvent:
	if b.get("type", "") == "mouse":
		var m := InputEventMouseButton.new()
		m.button_index = int(b.get("code", 1)) as MouseButton
		return m
	var e := InputEventKey.new()
	e.physical_keycode = int(b.get("code", 0)) as Key
	return e

func event_to_bind(e: InputEvent) -> Dictionary:
	if e is InputEventKey and e.physical_keycode != 0:
		return {"type": "key", "code": int(e.physical_keycode)}
	if e is InputEventMouseButton:
		return {"type": "mouse", "code": int(e.button_index)}
	return {}

func rebind(action: String, e: InputEvent) -> void:
	var b := event_to_bind(e)
	if b.is_empty():
		return
	# 避免重复绑定
	for a in settings.controls.binds.keys():
		if a != action and str(settings.controls.binds[a]) == str(b):
			settings.controls.binds.erase(a)
	settings.controls.binds[action] = b
	_setup_input()
	save_settings()

func reset_binds() -> void:
	settings.controls.binds = {}
	_setup_input()
	save_settings()

# --- 统一输入查询（键鼠 + 触屏） ---
func act(a: String) -> bool:
	if Input.is_action_pressed(a):
		return true
	return touch.get(a, false)

func act_just(a: String) -> bool:
	if Input.is_action_just_pressed(a):
		return true
	return touch_just.get(a, false)

func touch_press(a: String) -> void:
	touch[a] = true
	touch_just[a] = true

func touch_release(a: String) -> void:
	touch[a] = false

func add_look(delta: Vector2) -> void:
	touch_look += delta

func consume_look() -> Vector2:
	var v := touch_look
	touch_look = Vector2.ZERO
	return v

func _process(_d: float) -> void:
	touch_just.clear()

# ================= 设置持久化 =================
func save_settings() -> void:
	var f := FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(settings))

func _load_settings() -> void:
	if not FileAccess.file_exists(SETTINGS_PATH):
		return
	var f := FileAccess.open(SETTINGS_PATH, FileAccess.READ)
	if f == null:
		return
	var parsed = JSON.parse_string(f.get_as_text())
	if parsed is Dictionary:
		_deep_merge(settings, parsed)

func _deep_merge(into: Dictionary, from: Dictionary) -> void:
	for k in from.keys():
		var v = from[k]
		if into.has(k) and into[k] is Dictionary and v is Dictionary:
			_deep_merge(into[k], v)
		elif v != null:
			into[k] = v

func save_loadout() -> void:
	var f := FileAccess.open(LOADOUT_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(loadout))

func _load_loadout() -> void:
	if not FileAccess.file_exists(LOADOUT_PATH):
		return
	var f := FileAccess.open(LOADOUT_PATH, FileAccess.READ)
	if f == null:
		return
	var parsed = JSON.parse_string(f.get_as_text())
	if parsed is Dictionary:
		for k in parsed.keys():
			loadout[k] = parsed[k]

# ================= 视频设置应用 =================
func apply_video() -> void:
	var v: Dictionary = settings.video
	Engine.max_fps = int(v.fps_cap)
	var win := get_window()
	if bool(v.fullscreen):
		win.mode = Window.MODE_FULLSCREEN
	else:
		win.mode = Window.MODE_WINDOWED
	apply_color_mode()
	apply_aspect()
	apply_env()

func apply_color_mode() -> void:
	if env == null:
		return
	env.adjustment_enabled = true
	match str(settings.video.color_mode):
		"vivid":
			env.adjustment_saturation = 1.35
			env.adjustment_contrast = 1.06
			env.adjustment_brightness = 1.02
		"soft":
			env.adjustment_saturation = 0.72
			env.adjustment_contrast = 0.94
			env.adjustment_brightness = 1.06
		"realistic":
			env.adjustment_saturation = 0.85
			env.adjustment_contrast = 1.12
			env.adjustment_brightness = 0.97
		_:
			env.adjustment_saturation = 1.0
			env.adjustment_contrast = 1.0
			env.adjustment_brightness = float(settings.video.brightness)

func apply_env() -> void:
	if env == null:
		return
	if str(settings.video.color_mode) == "normal":
		env.adjustment_brightness = float(settings.video.brightness)
	if not bool(settings.video.shadows):
		pass  # 由场景灯光处理

# 4:3 画幅遮幅黑边
var _bar_layer: CanvasLayer = null
var _bars: Array = []

func apply_aspect() -> void:
	if _bar_layer == null:
		_bar_layer = CanvasLayer.new()
		_bar_layer.layer = 64
		add_child(_bar_layer)
		for i in 2:
			var r := ColorRect.new()
			r.color = Color.BLACK
			_bar_layer.add_child(r)
			_bars.append(r)
		get_viewport().size_changed.connect(_resize_bars)
	_bar_layer.visible = str(settings.video.aspect) == "4:3"
	_resize_bars()

func _resize_bars() -> void:
	var vs := get_viewport().get_visible_rect().size
	var target := vs.x * 3.0 / 4.0
	var bar := (vs.x - target) / 2.0
	_bars[0].position = Vector2.ZERO
	_bars[0].size = Vector2(bar, vs.y)
	_bars[1].position = Vector2(vs.x - bar, 0)
	_bars[1].size = Vector2(bar, vs.y)

# ================= 便捷 =================
func weapon() -> Dictionary:
	return WeaponDB.by_id(str(loadout.weapon))

func weapon_id() -> String:
	return str(loadout.weapon)

func op() -> Dictionary:
	return OperatorDB.by_id(str(loadout.operator))

func op_id() -> String:
	return str(loadout.operator)

func is_touch_device() -> bool:
	var mode := str(settings.controls.touch_enabled)
	if mode == "on":
		return true
	if mode == "off":
		return false
	return OS.has_feature("web") and (DisplayServer.is_touchscreen_available() or OS.get_name() == "Android" or OS.get_name() == "iOS")
