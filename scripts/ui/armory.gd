class_name ArmoryScreen
extends CanvasLayer
## Pixpfs 仓库 - 武器选择与装备

signal closed

var _cat := "rifle"
var _list_box: VBoxContainer
var _detail: VBoxContainer
var _equip_btn: Button
var _selected: String = ""

func _ready() -> void:
	layer = 50
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(root)
	UITheme.dim(root, 0.75)

	var wrap := UITheme.center_wrap(root)
	var main := UITheme.overlay_panel()
	main.custom_minimum_size = Vector2(940, 560)
	wrap.add_child(main)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	main.add_child(v)

	# 标题行
	var title_row := HBoxContainer.new()
	title_row.add_theme_constant_override("separation", 16)
	v.add_child(title_row)
	title_row.add_child(UITheme.label("仓 库", 30, UITheme.TEXT, true))
	title_row.add_child(UITheme.label("ARMORY // 选择主武器带入战局", 13, UITheme.TEXT_DIM))
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_row.add_child(spacer)
	var close_btn := UITheme.button("关 闭", 15)
	close_btn.pressed.connect(func(): _close())
	title_row.add_child(close_btn)

	v.add_child(UITheme.sep())

	# 分类标签
	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 8)
	v.add_child(tabs)
	for c in WeaponDB.CATS:
		var t := UITheme.button(str(c.name), 15, UITheme.ACCENT2 if str(c.id) == _cat else Color(1, 1, 1, 0.3))
		t.pressed.connect(func(): _switch_cat(str(c.id)))
		tabs.add_child(t)

	# 中部：武器列表 + 详情
	var body := HBoxContainer.new()
	body.add_theme_constant_override("separation", 18)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(body)

	var list_scroll := ScrollContainer.new()
	list_scroll.custom_minimum_size = Vector2(330, 0)
	list_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(list_scroll)
	_list_box = VBoxContainer.new()
	_list_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list_box.add_theme_constant_override("separation", 6)
	list_scroll.add_child(_list_box)

	_detail = VBoxContainer.new()
	_detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_detail.add_theme_constant_override("separation", 8)
	body.add_child(_detail)

	_rebuild_list()

func _switch_cat(cat: String) -> void:
	_cat = cat
	Snd.play("ui_click")
	_rebuild_list()

func _rebuild_list() -> void:
	for c in _list_box.get_children():
		c.queue_free()
	for w in WeaponDB.by_cat(_cat):
		var equipped := str(w.id) == G.weapon_id()
		var b := Button.new()
		b.custom_minimum_size = Vector2(0, 46)
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0.18, 0.19, 0.24, 0.95) if equipped else Color(0.1, 0.11, 0.15, 0.9)
		sb.set_corner_radius_all(3)
		sb.set_border_width_all(1)
		sb.border_color = UITheme.ACCENT if equipped else Color(1, 1, 1, 0.08)
		sb.content_margin_left = 12.0
		sb.content_margin_right = 8.0
		b.add_theme_stylebox_override("normal", sb)
		var sbh := sb.duplicate() as StyleBoxFlat
		sbh.bg_color = Color(0.2, 0.21, 0.28)
		b.add_theme_stylebox_override("hover", sbh)
		b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		b.add_theme_stylebox_override("pressed", sb)
		b.add_theme_font_size_override("font_size", 16)
		b.add_theme_color_override("font_color", UITheme.TEXT)
		b.text = ("[已装备] " if equipped else "") + str(w.name)
		var wid := str(w.id)
		b.pressed.connect(func(): _select(wid))
		_list_box.add_child(b)
	_select(G.weapon_id() if _selected == "" else _selected)

func _select(wid: String) -> void:
	_selected = wid
	Snd.play("ui_click", -6)
	var w := WeaponDB.by_id(wid)
	for c in _detail.get_children():
		c.queue_free()
	_detail.add_child(UITheme.label(str(w.name), 26, UITheme.TEXT, true))
	_detail.add_child(UITheme.label("%s · %s" % [str(w.cat_name), str(w.desc)], 13, UITheme.TEXT_DIM))
	var stats := VBoxContainer.new()
	stats.add_theme_constant_override("separation", 4)
	_detail.add_child(stats)
	var dps := float(w.dmg) * float(w.rpm) / 60.0 * (float(w.get("pellets", 1)))
	UITheme.stat_bar(stats, "伤害", float(w.dmg) * float(w.get("pellets", 1)) / 110.0)
	UITheme.stat_bar(stats, "射速", float(w.rpm) / 1000.0, UITheme.ACCENT2)
	UITheme.stat_bar(stats, "精准", 1.0 - float(w.spread) / 8.0, Color(0.4, 0.9, 0.5))
	UITheme.stat_bar(stats, "射程", float(w.range) / 200.0, Color(0.9, 0.75, 0.3))
	UITheme.stat_bar(stats, "机动", float(w.mobility) / 1.3, Color(0.7, 0.5, 1.0))
	var ttk: float = 60.0 / float(w.rpm) * (ceil(100.0 / float(w.dmg)) - 1.0) * 1000.0
	_detail.add_child(UITheme.label("理论击杀时间：%.0f ms  ·  弹匣 %d 发  ·  换弹 %.1fs" % [ttk, int(w.mag), float(w.reload)], 13, UITheme.TEXT_DIM))
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_detail.add_child(spacer)
	_equip_btn = UITheme.button("装 备", 20)
	_equip_btn.custom_minimum_size = Vector2(200, 48)
	_equip_btn.pressed.connect(func(): _equip(wid))
	_detail.add_child(_equip_btn)
	if str(w.id) == G.weapon_id():
		_equip_btn.text = "已装备 ✓"
		_equip_btn.disabled = true

func _equip(wid: String) -> void:
	G.loadout.weapon = wid
	G.save_loadout()
	Snd.play("ui_click")
	_rebuild_list()

func _close() -> void:
	Snd.play("ui_click")
	closed.emit()
	queue_free()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()
		_close()
