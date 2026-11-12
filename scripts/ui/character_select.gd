class_name CharacterScreen
extends CanvasLayer
## Pixpfs 干员选择 - 五位像素特种兵

signal closed

func _ready() -> void:
	layer = 50
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(root)
	UITheme.dim(root, 0.75)

	var wrap := UITheme.center_wrap(root)
	var main := UITheme.overlay_panel()
	main.custom_minimum_size = Vector2(980, 560)
	wrap.add_child(main)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	main.add_child(v)

	var title_row := HBoxContainer.new()
	title_row.add_theme_constant_override("separation", 16)
	v.add_child(title_row)
	title_row.add_child(UITheme.label("角 色", 30, UITheme.TEXT, true))
	title_row.add_child(UITheme.label("OPERATORS // 选择你的特种兵", 13, UITheme.TEXT_DIM))
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_row.add_child(spacer)
	var close_btn := UITheme.button("关 闭", 15)
	close_btn.pressed.connect(func(): _close())
	title_row.add_child(close_btn)

	v.add_child(UITheme.sep())

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(row)

	for op in OperatorDB.get_all():
		row.add_child(_op_card(op))

func _op_card(op: Dictionary) -> Control:
	var selected := str(op.id) == G.op_id()
	var card := VBoxContainer.new()
	card.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var p := UITheme.panel(Color(0.16, 0.17, 0.22, 0.95) if selected else Color(0.09, 0.1, 0.14, 0.92), 6, true,
		UITheme.ACCENT if selected else Color(1, 1, 1, 0.08))
	card.add_child(p)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	p.add_child(v)

	var tex := load("res://assets/textures/portrait_%s.png" % str(op.id)) as Texture2D
	if tex:
		var tr := TextureRect.new()
		tr.texture = tex
		tr.custom_minimum_size = Vector2(150, 150)
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_SCALE
		v.add_child(tr)

	var name_row := HBoxContainer.new()
	name_row.add_theme_constant_override("separation", 8)
	v.add_child(name_row)
	name_row.add_child(UITheme.label(str(op.name), 20, UITheme.TEXT, true))
	var role_l := UITheme.label(str(op.en) + " · " + str(op.role), 11, op.visor)
	name_row.add_child(role_l)

	var visor := ColorRect.new()
	visor.color = Color(op.visor.r, op.visor.g, op.visor.b, 0.35)
	visor.custom_minimum_size = Vector2(0, 2)
	v.add_child(visor)

	var perk := UITheme.label("被动：" + str(op.perk), 13, Color(0.6, 0.9, 0.7))
	v.add_child(perk)
	var desc := UITheme.label(str(op.desc), 12, UITheme.TEXT_DIM)
	desc.custom_minimum_size = Vector2(150, 48)
	v.add_child(desc)

	var btn := UITheme.button("当前使用 ✓" if selected else "选 择", 16,
		UITheme.ACCENT if selected else Color(1, 1, 1, 0.35))
	btn.disabled = selected
	var op_id := str(op.id)
	btn.pressed.connect(func(): _pick(op_id))
	v.add_child(btn)
	return card

func _pick(op_id: String) -> void:
	G.loadout.operator = op_id
	G.save_loadout()
	Snd.play("ui_click")
	_close()

func _close() -> void:
	Snd.play("ui_click")
	closed.emit()
	queue_free()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()
		_close()
