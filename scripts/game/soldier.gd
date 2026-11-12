class_name SoldierFactory
extends RefCounted
## 像素特种兵模型工厂 - 大厅展示与 Bot 共用

static func mat_camo(op_id: String) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	var tex := load("res://assets/textures/camo_%s.png" % op_id) as Texture2D
	if tex:
		m.albedo_texture = tex
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	m.roughness = 0.9
	return m

static func mat_color(col: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = col
	m.roughness = 0.9
	return m

static func mat_metal() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	var tex := load("res://assets/textures/gun_metal.png") as Texture2D
	if tex:
		m.albedo_texture = tex
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	m.metallic = 0.6
	m.roughness = 0.45
	return m

static func box(size: Vector3, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = mat
	return mi

static func add_part(parent: Node3D, size: Vector3, pos: Vector3, mat: Material, name := "") -> MeshInstance3D:
	var mi := box(size, mat)
	mi.position = pos
	if name != "":
		mi.name = name
	parent.add_child(mi)
	return mi

## 构建完整士兵模型（身高约1.8m）
static func build(op: Dictionary, weapon: Dictionary, team_tint := Color(1, 1, 1)) -> Node3D:
	var rig := Node3D.new()
	rig.name = "Soldier"
	var camo := mat_camo(str(op.id))
	if team_tint != Color(1, 1, 1):
		camo.albedo_color = team_tint

	# 躯干 + 战术背心
	var torso := add_part(rig, Vector3(0.52, 0.62, 0.3), Vector3(0, 1.06, 0), camo, "Torso")
	add_part(torso, Vector3(0.56, 0.4, 0.34), Vector3(0, -0.02, 0), mat_color(Color(0.18, 0.19, 0.22)), "Vest")
	# 胸前弹匣包
	add_part(torso, Vector3(0.3, 0.12, 0.06), Vector3(0, 0.1, 0.19), mat_color(Color(0.13, 0.14, 0.16)))
	# 头 + 头盔 + 护目镜
	var head := add_part(rig, Vector3(0.32, 0.32, 0.32), Vector3(0, 1.56, 0), camo, "Head")
	add_part(head, Vector3(0.36, 0.16, 0.36), Vector3(0, 0.12, 0), mat_color(Color(0.2, 0.21, 0.24)))
	var visor_mat := StandardMaterial3D.new()
	visor_mat.albedo_color = op.visor
	visor_mat.emission_enabled = true
	visor_mat.emission = op.visor
	visor_mat.emission_energy_multiplier = 2.0
	add_part(head, Vector3(0.28, 0.07, 0.03), Vector3(0, 0.02, 0.17), visor_mat, "Visor")
	# 手臂
	var arm_l := add_part(rig, Vector3(0.14, 0.5, 0.16), Vector3(-0.36, 1.1, 0.05), camo, "ArmL")
	var arm_r := add_part(rig, Vector3(0.14, 0.5, 0.16), Vector3(0.36, 1.1, 0.05), camo, "ArmR")
	arm_l.rotation_degrees = Vector3(-70, 0, 8)
	arm_r.rotation_degrees = Vector3(-70, 0, -8)
	# 腿
	add_part(rig, Vector3(0.17, 0.75, 0.19), Vector3(-0.14, 0.375, 0), camo, "LegL")
	add_part(rig, Vector3(0.17, 0.75, 0.19), Vector3(0.14, 0.375, 0), camo, "LegR")
	# 武器（双手前持）
	var gun := build_gun(weapon)
	gun.name = "Gun"
	gun.position = Vector3(0.14, 1.12, 0.42)
	rig.add_child(gun)
	return rig

## 按武器类别构建枪模
static func build_gun(w: Dictionary) -> Node3D:
	var gun := Node3D.new()
	var metal := mat_metal()
	var cat := str(w.cat)
	var accent: Color
	match cat:
		"rifle": accent = Color(0.9, 0.5, 0.15)
		"smg": accent = Color(0.95, 0.8, 0.2)
		"sniper": accent = Color(0.4, 0.7, 1.0)
		"shotgun": accent = Color(0.9, 0.3, 0.3)
		_: accent = Color(0.7, 0.7, 0.75)
	var acc := mat_color(accent)
	match cat:
		"rifle":
			add_part(gun, Vector3(0.07, 0.1, 0.7), Vector3(0, 0, 0.1), metal)
			add_part(gun, Vector3(0.05, 0.05, 0.5), Vector3(0, 0.02, 0.62), metal)
			add_part(gun, Vector3(0.06, 0.22, 0.1), Vector3(0, -0.14, 0.05), acc)
			add_part(gun, Vector3(0.06, 0.12, 0.24), Vector3(0, -0.02, -0.32), metal)
			add_part(gun, Vector3(0.03, 0.05, 0.06), Vector3(0, 0.09, 0.3), acc)
		"smg":
			add_part(gun, Vector3(0.07, 0.1, 0.45), Vector3(0, 0, 0.05), metal)
			add_part(gun, Vector3(0.045, 0.045, 0.3), Vector3(0, 0.02, 0.4), metal)
			add_part(gun, Vector3(0.055, 0.2, 0.08), Vector3(0, -0.13, 0.0), acc)
			add_part(gun, Vector3(0.05, 0.1, 0.16), Vector3(0, -0.02, -0.24), metal)
		"sniper":
			add_part(gun, Vector3(0.07, 0.11, 0.95), Vector3(0, 0, 0.15), metal)
			add_part(gun, Vector3(0.04, 0.04, 0.6), Vector3(0, 0.03, 0.85), metal)
			var scope := CylinderMesh.new()
			scope.top_radius = 0.045
			scope.bottom_radius = 0.045
			scope.height = 0.34
			var sm := MeshInstance3D.new()
			sm.mesh = scope
			sm.material_override = metal
			sm.rotation_degrees = Vector3(90, 0, 0)
			sm.position = Vector3(0, 0.11, 0.18)
			gun.add_child(sm)
			add_part(gun, Vector3(0.06, 0.18, 0.09), Vector3(0, -0.12, -0.1), acc)
		"shotgun":
			add_part(gun, Vector3(0.09, 0.11, 0.62), Vector3(0, 0, 0.1), metal)
			add_part(gun, Vector3(0.07, 0.07, 0.5), Vector3(0, -0.04, 0.55), metal)
			add_part(gun, Vector3(0.07, 0.13, 0.2), Vector3(0, -0.06, -0.3), acc)
		_:  # pistol
			add_part(gun, Vector3(0.05, 0.09, 0.24), Vector3(0, 0, 0.08), metal)
			add_part(gun, Vector3(0.045, 0.13, 0.07), Vector3(0, -0.1, -0.03), acc)
	return gun
