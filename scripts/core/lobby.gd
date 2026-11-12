class_name Lobby
extends Node3D
## Pixpfs 大厅：3D 展台角色 + 左上三选项 + 右上设置/开发人员 + 右下地图选择/开始游戏

var _soldier: Node3D
var _char_label: Label
var _weapon_label: Label
var _map_cards: Dictionary = {}
var _map_desc: Label
var _camera: Camera3D
var _t := 0.0

const MAPS := [
	{"id": "rust", "name": "锈蚀仓库", "en": "RUST DEPOT", "desc": "废弃集装箱货场，中近距离交火，掩体密集。"},
	{"id": "neon", "name": "霓虹天台", "en": "NEON ROOFTOP", "desc": "摩天楼顶的霓虹战场，高低差与侧翼穿插。"},
]

func _ready() -> void:
	_build_world()
	_build_ui()
	Snd.play_music("music_lobby")
	G.env = _get_env()

func _get_env() -> Environment:
	var wc := get_node_or_null("WorldEnv") as WorldEnvironment
	return wc.environment if wc else null

func _build_world() -> void:
	var wc := WorldEnvironment.new()
	wc.name = "WorldEnv"
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.28, 0.3, 0.4)
	env.ambient_light_energy = 1.4
	env.glow_enabled = true
	env.glow_intensity = 0.6
	env.glow_bloom = 0.05
	env.adjustment_enabled = true
	wc.environment = env
	add_child(wc)

	# 地面：发光网格
	var floor_mi := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(40, 40)
	var fmat := StandardMaterial3D.new()
	var ftex := load("res://assets/textures/grid_floor.png") as Texture2D
	if ftex:
		fmat.albedo_texture = ftex
		pm.material = fmat
		fmat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		fmat.uv1_scale = Vector3(8, 8, 1)
	floor_mi.mesh = pm
	add_child(floor_mi)
	var floor_body := StaticBody3D.new()
	floor_mi.add_child(floor_body)
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = Vector3(40, 0.5, 40)
	cs.shape = bs
	cs.position = Vector3(0, -0.25, 0)
	floor_body.add_child(cs)

	# 中央展台
	var dais := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 1.6
	cyl.bottom_radius = 1.9
	cyl.height = 0.24
	dais.mesh = cyl
	var dmat := StandardMaterial3D.new()
	dmat.albedo_color = Color(0.12, 0.13, 0.17)
	dais.material_override = dmat
	dais.position = Vector3(0, 0.12, 0)
	add_child(dais)
	var ring := MeshInstance3D.new()
	var cyl2 := CylinderMesh.new()
	cyl2.top_radius = 1.75
	cyl2.bottom_radius = 1.75
	cyl2.height = 0.05
	var rmat := StandardMaterial3D.new()
	rmat.albedo_color = Color(0.0, 0.85, 0.95)
	rmat.emission_enabled = true
	rmat.emission = Color(0.0, 0.85, 0.95)
	rmat.emission_energy_multiplier = 3.0
	ring.mesh = cyl2
	ring.material_override = rmat
	ring.position = Vector3(0, 0.26, 0)
	add_child(ring)

	# 背景柱
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for i in 10:
		var h := rng.randf_range(4, 14)
		var p := MeshInstance3D.new()
		var bx := BoxMesh.new()
		bx.size = Vector3(rng.randf_range(0.8, 2.4), h, rng.randf_range(0.8, 2.4))
		p.mesh = bx
		var m := StandardMaterial3D.new()
		m.albedo_color = Color(0.09, 0.1, 0.14)
		p.material_override = m
		var ang := TAU * i / 10.0 + 0.3
		p.position = Vector3(cos(ang) * rng.randf_range(14, 20), h / 2 - 0.1, sin(ang) * rng.randf_range(14, 20))
		add_child(p)
		if i % 3 == 0:
			var strip := MeshInstance3D.new()
			var sb := BoxMesh.new()
			sb.size = Vector3(0.08, h * 0.7, 0.08)
			strip.mesh = sb
			var sm2 := StandardMaterial3D.new()
			var col := Color(1.0, 0.28, 0.36) if i % 2 == 0 else Color(0.0, 0.85, 0.95)
			sm2.albedo_color = col
			sm2.emission_enabled = true
			sm2.emission = col
			sm2.emission_energy_multiplier = 4.0
			strip.material_override = sm2
			strip.position = p.position + Vector3(0, 0, 0.7)
			add_child(strip)

	# 展台聚光灯
	var spot := SpotLight3D.new()
	spot.light_color = Color(0.9, 0.92, 1.0)
	spot.light_energy = 5.0
	spot.spot_range = 18.0
	spot.spot_angle = 38.0
	spot.position = Vector3(0, 6, 2.5)
	spot.rotation_degrees = Vector3(-70, 0, 0)
	add_child(spot)

	# 相机
	_camera = Camera3D.new()
	_camera.position = Vector3(0, 1.7, 5.2)
	_camera.current = true
	add_child(_camera)

	# 展示角色
	_spawn_soldier()

func _spawn_soldier() -> void:
	if _soldier and is_instance_valid(_soldier):
		_soldier.queue_free()
	var op := G.op()
	var w := G.weapon()
	_soldier = SoldierFactory.build(op, w)
	_soldier.position = Vector3(0, 0.26, 0)
	add_child(_soldier)
	if _char_label:
		_char_label.text = "%s · %s" % [str(op.name), str(op.role)]
		_weapon_label.text = "主武器：%s" % str(w.name)

var _right_box: VBoxContainer
var _bottom_right: VBoxContainer
var _tip: Label
var _ui_root: Control

func _build_ui() -> void:
	var ui := CanvasLayer.new()
	ui.layer = 10
	add_child(ui)
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	ui.add_child(root)
	_ui_root = root

	# ===== 顶部标题 =====
	var title := UITheme.label("PIXPFS", 34, Color(0.95, 0.96, 0.98), true)
	title.position = Vector2(28, 18)
	root.add_child(title)
	var ver := UITheme.label("v1.0  //  2v2 战术竞技", 12, UITheme.TEXT_DIM)
	title.add_child(ver)
	ver.position = Vector2(2, 44)

	# ===== 左上角：仓库 / 角色 / 训练场 =====
	var left := VBoxContainer.new()
	left.position = Vector2(28, 96)
	left.add_theme_constant_override("separation", 10)
	root.add_child(left)
	left.add_child(_menu_btn("仓 库", "res://assets/textures/ui_crate.png", func(): _open_armory()))
	left.add_child(_menu_btn("角 色", "res://assets/textures/ui_helmet.png", func(): _open_characters()))
	left.add_child(_menu_btn("训练场", "res://assets/textures/ui_target.png", func(): _open_training()))
	_char_label = UITheme.label("", 13, UITheme.TEXT_DIM)
	left.add_child(_char_label)
	_weapon_label = UITheme.label("", 13, UITheme.TEXT_DIM)
	left.add_child(_weapon_label)

	# ===== 右上角：设置 / 开发人员 =====
	_right_box = VBoxContainer.new()
	_right_box.add_theme_constant_override("separation", 10)
	root.add_child(_right_box)
	var set_btn := UITheme.button("设 置", 17, UITheme.ACCENT2)
	set_btn.pressed.connect(func(): _open_settings())
	_right_box.add_child(set_btn)
	var dev_btn := UITheme.button("开发人员", 15, UITheme.ACCENT2)
	dev_btn.pressed.connect(func(): _open_dev())
	_right_box.add_child(dev_btn)

	# ===== 右下角：地图选择 + 开始游戏 =====
	_bottom_right = VBoxContainer.new()
	_bottom_right.add_theme_constant_override("separation", 10)
	root.add_child(_bottom_right)

	var map_row := HBoxContainer.new()
	map_row.add_theme_constant_override("separation", 10)
	map_row.alignment = BoxContainer.ALIGNMENT_END
	_bottom_right.add_child(map_row)
	for m in MAPS:
		map_row.add_child(_map_card(m))

	_map_desc = UITheme.label("", 13, UITheme.TEXT_DIM)
	_map_desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_bottom_right.add_child(_map_desc)
	_update_map_desc()

	var start_btn := UITheme.button("开 始 游 戏", 26)
	start_btn.custom_minimum_size = Vector2(260, 62)
	start_btn.pressed.connect(func(): _start_game())
	_bottom_right.add_child(start_btn)

	# ===== 底部提示 =====
	_tip = UITheme.label("WASD 移动 · 空格 跳跃(二段) · Shift 疾跑 · C 滑铲 · 靠墙奔跑实现泰坦机动", 12, Color(0.35, 0.37, 0.44))
	root.add_child(_tip)

	_apply_layout()
	root.resized.connect(_apply_layout_sync)

func _apply_layout_sync() -> void:
	_apply_layout()

func _apply_layout() -> void:
	await get_tree().process_frame
	var vs := _ui_root.size
	_right_box.position = Vector2(vs.x - _right_box.size.x - 28, 96)
	_bottom_right.position = Vector2(vs.x - _bottom_right.size.x - 28, vs.y - _bottom_right.size.y - 28)
	_tip.position = Vector2(28, vs.y - _tip.size.y - 24)

func _menu_btn(text: String, icon_path: String, cb: Callable) -> Control:
	var b := UITheme.button(text, 18)
	b.custom_minimum_size = Vector2(168, 52)
	var tex := load(icon_path) as Texture2D
	if tex:
		var tr := TextureRect.new()
		tr.texture = tex
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.custom_minimum_size = Vector2(32, 32)
		tr.size = Vector2(32, 32)
		tr.position = Vector2(10, 10)
		b.add_child(tr)
		b.text = "    " + text
	b.pressed.connect(cb)
	return b

func _map_card(m: Dictionary) -> Control:
	var card := Button.new()
	card.custom_minimum_size = Vector2(150, 96)
	var sb := StyleBoxFlat.new()
	var selected := G.current_map == str(m.id)
	sb.bg_color = Color(0.16, 0.17, 0.22, 0.95) if selected else Color(0.09, 0.1, 0.13, 0.9)
	sb.set_corner_radius_all(4)
	sb.set_border_width_all(2)
	sb.border_color = UITheme.ACCENT if selected else Color(1, 1, 1, 0.1)
	sb.content_margin_left = 0.0
	sb.content_margin_right = 0.0
	sb.content_margin_top = 0.0
	sb.content_margin_bottom = 0.0
	card.add_theme_stylebox_override("normal", sb)
	var sbh := sb.duplicate() as StyleBoxFlat
	sbh.border_color = UITheme.ACCENT
	card.add_theme_stylebox_override("hover", sbh)
	card.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	card.add_theme_stylebox_override("pressed", sb)
	var tex := load("res://assets/textures/thumb_%s.png" % str(m.id)) as Texture2D
	var v := VBoxContainer.new()
	v.set_anchors_preset(Control.PRESET_FULL_RECT)
	v.add_theme_constant_override("separation", 2)
	card.add_child(v)
	if tex:
		var tr := TextureRect.new()
		tr.texture = tex
		tr.custom_minimum_size = Vector2(146, 56)
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_SCALE
		v.add_child(tr)
	var name_l := UITheme.label(str(m.name), 15, UITheme.TEXT, true)
	name_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(name_l)
	var en_l := UITheme.label(str(m.en), 10, UITheme.TEXT_DIM)
	en_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(en_l)
	card.pressed.connect(func():
		G.current_map = str(m.id)
		_refresh_map_cards()
		Snd.play("ui_click"))
	_map_cards[str(m.id)] = card
	return card

func _refresh_map_cards() -> void:
	for id in _map_cards.keys():
		var c := _map_cards[id] as Button
		var sb := c.get_theme_stylebox("normal").duplicate() as StyleBoxFlat
		sb.bg_color = Color(0.16, 0.17, 0.22, 0.95) if id == G.current_map else Color(0.09, 0.1, 0.13, 0.9)
		sb.border_color = UITheme.ACCENT if id == G.current_map else Color(1, 1, 1, 0.1)
		c.add_theme_stylebox_override("normal", sb)
	_update_map_desc()

func _update_map_desc() -> void:
	for m in MAPS:
		if str(m.id) == G.current_map:
			_map_desc.text = str(m.desc)

func _open_armory() -> void:
	Snd.play("ui_click")
	var arm := ArmoryScreen.new()
	arm.closed.connect(func():
		_spawn_soldier()
		_refresh_menu_icons())
	add_child(arm)

func _open_characters() -> void:
	Snd.play("ui_click")
	var cs := CharacterScreen.new()
	cs.closed.connect(func():
		_spawn_soldier()
		_refresh_menu_icons())
	add_child(cs)

func _open_training() -> void:
	Snd.play("ui_click")
	get_node("/root/Main").call("start_training")

func _open_settings() -> void:
	Snd.play("ui_click")
	var s := SettingsScreen.new()
	add_child(s)

func _open_dev() -> void:
	Snd.play("ui_click")
	var d := DevScreen.new()
	add_child(d)

func _refresh_menu_icons() -> void:
	pass  # 图标在大厅重建时刷新

func _start_game() -> void:
	Snd.play("ui_click")
	get_node("/root/Main").call("start_match")

func _process(delta: float) -> void:
	_t += delta
	if _soldier and is_instance_valid(_soldier):
		_soldier.rotation.y += delta * 0.35
		_soldier.position.y = 0.26 + sin(_t * 1.2) * 0.02
	if _camera:
		_camera.position.y = 1.7 + sin(_t * 0.5) * 0.04
