class_name IntroScreen
extends CanvasLayer
## Pixpfs 开场动画：工作室标 → 标题 → 大厅

signal finished

var _t := 0.0
var _done := false
var _logo: TextureRect
var _studio: TextureRect
var _sub: Label
var _hint: Label
var _flash: ColorRect
var _root: Control

func _ready() -> void:
	layer = 100
	G.env = null
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(root)
	_root = root

	var bg := ColorRect.new()
	bg.color = Color(0.02, 0.02, 0.04)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(bg)

	_flash = ColorRect.new()
	_flash.color = Color(1, 1, 1, 0)
	_flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(_flash)

	_studio = _tex("res://assets/textures/studio.png")
	_studio.modulate = Color(1, 1, 1, 0)
	root.add_child(_studio)
	_studio.set_anchors_preset(Control.PRESET_CENTER)

	_logo = _tex("res://assets/textures/logo.png")
	_logo.modulate = Color(1, 1, 1, 0)
	root.add_child(_logo)
	_logo.set_anchors_preset(Control.PRESET_CENTER)

	_sub = UITheme.label("TITAN-CLASS MOBILITY  //  2v2 TACTICAL WARFARE", 15, Color(0.62, 0.66, 0.74))
	_sub.set_anchors_preset(Control.PRESET_CENTER)
	_sub.position.y += 60
	_sub.modulate = Color(1, 1, 1, 0)
	root.add_child(_sub)

	_hint = UITheme.label("按任意键跳过", 14, Color(0.4, 0.42, 0.5))
	_hint.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_hint.position.y -= 40
	root.add_child(_hint)

	Snd.play("ui_click", -8)

func _tex(path: String) -> TextureRect:
	var t := TextureRect.new()
	var tex := load(path) as Texture2D
	if tex:
		t.texture = tex
		t.custom_minimum_size = tex.get_size() * 0.55
		t.size = t.custom_minimum_size
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	return t

func _process(delta: float) -> void:
	if _done:
		return
	_t += delta
	var phase1 := clampf(_t / 1.8, 0.0, 1.0)          # 工作室标淡入
	var phase1b := clampf((_t - 2.6) / 0.8, 0.0, 1.0) # 工作室标淡出
	var phase2 := clampf((_t - 3.6) / 1.2, 0.0, 1.0)  # 标题淡入
	var phase3 := clampf((_t - 4.6) / 1.2, 0.0, 1.0)  # 副标题
	_studio.modulate = Color(1, 1, 1, phase1 * (1.0 - phase1b))
	_logo.modulate = Color(1, 1, 1, phase2)
	_sub.modulate = Color(1, 1, 1, phase3)
	_hint.modulate = Color(1, 1, 1, 0.4 + 0.3 * sin(_t * 4.0))
	# 标题撞击闪白
	if _t > 3.55 and _t < 3.7:
		_flash.color = Color(1, 1, 1, 0.5 * (1.0 - (_t - 3.55) / 0.15))
	else:
		_flash.color = Color(1, 1, 1, 0)
	if _t > 6.5:
		finish()

func _unhandled_input(event: InputEvent) -> void:
	if _done:
		return
	if event is InputEventKey or event is InputEventMouseButton or event is InputEventScreenTouch:
		if event.pressed:
			finish()

func finish() -> void:
	if _done:
		return
	_done = true
	var tw := create_tween()
	tw.tween_property(_root, "modulate", Color(1, 1, 1, 0), 0.35)
	await tw.finished
	finished.emit()
