class_name PauseMenu
extends CanvasLayer
## 暂停菜单（对战 / 训练场共用）

signal closed

func _ready() -> void:
	layer = 70
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(root)
	UITheme.dim(root, 0.7)

	var wrap := UITheme.center_wrap(root)
	var main := UITheme.overlay_panel()
	main.custom_minimum_size = Vector2(380, 400)
	wrap.add_child(main)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	main.add_child(v)
	v.add_child(UITheme.label("已 暂 停", 30, UITheme.TEXT, true))
	v.add_child(UITheme.label("PAUSED", 12, UITheme.TEXT_DIM))
	v.add_child(UITheme.sep())

	var resume := UITheme.button("继 续 游 戏", 18)
	resume.pressed.connect(func(): _close())
	v.add_child(resume)

	var settings := UITheme.button("设 置", 16, UITheme.ACCENT2)
	settings.pressed.connect(func():
		var s := SettingsScreen.new()
		s.closed.connect(func(): root.visible = true)
		add_child(s)
		root.visible = false)
	v.add_child(settings)

	var scene := str(get_meta("scene", "match"))
	if scene == "training":
		var reset := UITheme.button("重置训练场", 16, UITheme.ACCENT2)
		reset.pressed.connect(func():
			_close()
			var p := get_parent()
			if p is Training:
				(p as Training)._spawn_bots(Training.BOT_COUNT))
		v.add_child(reset)

	var back := UITheme.button("返 回 大 厅", 16, Color(1, 0.5, 0.4))
	back.pressed.connect(func():
		_close()
		get_node("/root/Main").call("goto_lobby"))
	v.add_child(back)

	var tip := UITheme.label("ESC / ⏸ 继续游戏", 12, UITheme.TEXT_DIM)
	v.add_child(tip)

func _close() -> void:
	closed.emit()
	queue_free()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()
		_close()
