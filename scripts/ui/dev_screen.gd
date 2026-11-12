class_name DevScreen
extends CanvasLayer
## 开发人员名单

func _ready() -> void:
	layer = 60
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(root)
	UITheme.dim(root, 0.8)

	var wrap := UITheme.center_wrap(root)
	var main := UITheme.overlay_panel()
	main.custom_minimum_size = Vector2(520, 460)
	wrap.add_child(main)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 14)
	main.add_child(v)

	v.add_child(UITheme.label("开发人员", 30, UITheme.TEXT, true))
	v.add_child(UITheme.label("DEVELOPMENT CREDITS", 12, UITheme.TEXT_DIM))
	v.add_child(UITheme.sep())

	for dev in [
		{"name": "Claude", "role": "Anthropic · 游戏设计与代码"},
		{"name": "ChatGPT", "role": "OpenAI · 系统与关卡设计"},
	]:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 14)
		v.add_child(row)
		var badge := UITheme.panel(Color(0.16, 0.17, 0.22, 0.95), 4, true, Color(1, 1, 1, 0.1))
		row.add_child(badge)
		var bv := VBoxContainer.new()
		badge.add_child(bv)
		bv.add_child(UITheme.label(str(dev.name), 24, UITheme.TEXT, true))
		bv.add_child(UITheme.label(str(dev.role), 12, UITheme.TEXT_DIM))
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(spacer)
	v.add_child(UITheme.label("引擎：Godot 4.4  ·  项目：Pixpfs", 12, Color(0.3, 0.32, 0.4)))

	var close_btn := UITheme.button("返 回", 16)
	close_btn.pressed.connect(func(): queue_free())
	v.add_child(close_btn)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()
		queue_free()
