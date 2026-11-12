class_name MapBuilder
extends RefCounted
## Pixpfs 地图构建器：锈蚀仓库 / 霓虹天台（2v2）+ 训练场

static var _mats := {}

static func mat(tex_name: String, uv := 1.0, emission := Color.BLACK, em_energy := 0.0) -> StandardMaterial3D:
	var key := "%s_%f_%s" % [tex_name, uv, str(emission)]
	if _mats.has(key):
		return _mats[key]
	var m := StandardMaterial3D.new()
	var tex := load("res://assets/textures/%s.png" % tex_name) as Texture2D
	if tex:
		m.albedo_texture = tex
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	if uv != 1.0:
		m.uv1_scale = Vector3(uv, uv, 1)
	if emission != Color.BLACK:
		m.emission_enabled = true
		m.emission = emission
		m.emission_energy_multiplier = em_energy
	_mats[key] = m
	return m

static func box(parent: Node3D, pos: Vector3, size: Vector3, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = mat
	mi.position = pos
	parent.add_child(mi)
	var body := StaticBody3D.new()
	mi.add_child(body)
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = size
	cs.shape = bs
	body.add_child(cs)
	return mi

static func env_for(parent: Node3D, map_id: String) -> void:
	var wc := WorldEnvironment.new()
	wc.name = "WorldEnv"
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.glow_enabled = true
	env.glow_intensity = 0.8
	env.glow_bloom = 0.06
	match map_id:
		"neon":
			env.background_color = Color(0.03, 0.02, 0.09)
			env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
			env.ambient_light_color = Color(0.35, 0.25, 0.55)
			env.ambient_light_energy = 1.2
			env.fog_enabled = true
			env.fog_light_color = Color(0.1, 0.06, 0.2)
			env.fog_density = 0.004
		"training":
			env.background_color = Color(0.05, 0.06, 0.09)
			env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
			env.ambient_light_color = Color(0.5, 0.55, 0.65)
			env.ambient_light_energy = 1.3
		_:
			env.background_color = Color(0.12, 0.09, 0.08)
			env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
			env.ambient_light_color = Color(0.6, 0.5, 0.42)
			env.ambient_light_energy = 1.4
	env.adjustment_enabled = true
	wc.environment = env
	parent.add_child(wc)
	G.env = env
	G.apply_color_mode()

static func light_for(parent: Node3D, map_id: String, shadows: bool) -> void:
	var sun := DirectionalLight3D.new()
	sun.shadow_enabled = shadows
	match map_id:
		"neon":
			sun.light_color = Color(0.6, 0.45, 0.9)
			sun.light_energy = 0.8
			sun.rotation_degrees = Vector3(-40, 30, 0)
		"training":
			sun.light_color = Color(0.95, 0.95, 1.0)
			sun.light_energy = 1.2
			sun.rotation_degrees = Vector3(-55, -20, 0)
		_:
			sun.light_color = Color(1.0, 0.82, 0.62)
			sun.light_energy = 1.3
			sun.rotation_degrees = Vector3(-50, -35, 0)
	parent.add_child(sun)

## 构建地图，返回 {spawns_red, spawns_blue, waypoints, interact_points}
static func build(parent: Node3D, map_id: String) -> Dictionary:
	var res := {"spawns_red": [], "spawns_blue": [], "waypoints": [], "interact_points": {}}
	env_for(parent, map_id)
	light_for(parent, map_id, bool(G.settings.video.shadows))
	match map_id:
		"neon": _build_neon(parent, res)
		"training": _build_training(parent, res)
		_: _build_rust(parent, res)
	return res

# ================= 锈蚀仓库 =================
static func _build_rust(parent: Node3D, res: Dictionary) -> void:
	var floor_m := mat("concrete", 8.0)
	var floor_mi := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(44, 32)
	pm.material = floor_m
	floor_mi.mesh = pm
	parent.add_child(floor_mi)
	var body := StaticBody3D.new()
	floor_mi.add_child(body)
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = Vector3(44, 0.5, 32)
	cs.shape = bs
	cs.position = Vector3(0, -0.25, 0)
	body.add_child(cs)

	var wall_m := mat("metal", 3.0)
	var cont_m := mat("container", 1.5)
	var cont_m2: StandardMaterial3D = mat("container", 1.5).duplicate() as StandardMaterial3D
	cont_m2.albedo_color = Color(0.7, 0.75, 0.85)
	var crate_m := mat("crate")
	var rust_m := mat("container", 2.0)
	rust_m.albedo_color = Color(0.55, 0.4, 0.3)

	# 四面围墙
	box(parent, Vector3(0, 3, -16.5), Vector3(44, 6, 1), wall_m)
	box(parent, Vector3(0, 3, 16.5), Vector3(44, 6, 1), wall_m)
	box(parent, Vector3(-22.5, 3, 0), Vector3(1, 6, 32), wall_m)
	box(parent, Vector3(22.5, 3, 0), Vector3(1, 6, 32), wall_m)

	# 集装箱群（中路掩体）
	var container_layout := [
		[Vector3(-8, 1.3, -4), Vector3(2.5, 2.6, 7), 0],
		[Vector3(8, 1.3, 4), Vector3(2.5, 2.6, 7), 0],
		[Vector3(0, 1.3, -9), Vector3(7, 2.6, 2.5), 0],
		[Vector3(0, 1.3, 9), Vector3(7, 2.6, 2.5), 0],
		[Vector3(-14, 1.3, 6), Vector3(2.5, 2.6, 8), 0],
		[Vector3(14, 1.3, -6), Vector3(2.5, 2.6, 8), 0],
	]
	for c in container_layout:
		box(parent, c[0], c[1], cont_m if randf() > 0.5 else cont_m2)
	# 叠高箱（可蹬墙跑）
	box(parent, Vector3(-8, 3.9, -4), Vector3(2.5, 2.6, 4), cont_m2)
	box(parent, Vector3(8, 3.9, 4), Vector3(2.5, 2.6, 4), cont_m)
	# 木箱散布
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	for i in 14:
		var x := rng.randf_range(-19, 19)
		var z := rng.randf_range(-13, 13)
		if absf(x) < 3 and absf(z) < 3:
			continue
		box(parent, Vector3(x, 0.45, z), Vector3(0.9, 0.9, 0.9), crate_m)
	# 中路高台 + 坡道
	var plat_m := mat("metal_dark", 2.0)
	box(parent, Vector3(0, 2.5, 0), Vector3(6, 0.4, 6), plat_m)
	box(parent, Vector3(-4.5, 1.2, 0), Vector3(3, 0.35, 5), plat_m)  # 左坡道
	var ramp := box(parent, Vector3(4.5, 1.2, 0), Vector3(3, 0.35, 5), plat_m)
	ramp.rotation_degrees.z = 0
	# 侧翼掩体墙
	box(parent, Vector3(-16, 1, -10), Vector3(6, 2, 0.6), rust_m)
	box(parent, Vector3(16, 1, 10), Vector3(6, 2, 0.6), rust_m)
	box(parent, Vector3(-16, 1, 10), Vector3(0.6, 2, 5), rust_m)
	box(parent, Vector3(16, 1, -10), Vector3(0.6, 2, 5), rust_m)

	res.spawns_red = [
		Vector3(-19, 0.6, -12), Vector3(-19, 0.6, 12),
		Vector3(-13, 0.6, 0), Vector3(-19, 0.6, 0),
	]
	res.spawns_blue = [
		Vector3(19, 0.6, 12), Vector3(19, 0.6, -12),
		Vector3(13, 0.6, 0), Vector3(19, 0.6, 0),
	]
	res.waypoints = [
		Vector3(-14, 0.5, -8), Vector3(-14, 0.5, 8), Vector3(14, 0.5, -8), Vector3(14, 0.5, 8),
		Vector3(0, 0.5, -11), Vector3(0, 0.5, 11), Vector3(-5, 0.5, 0), Vector3(5, 0.5, 0),
		Vector3(0, 2.9, 0), Vector3(-18, 0.5, -4), Vector3(18, 0.5, 4), Vector3(10, 0.5, -9),
	]

# ================= 霓虹天台 =================
static func _build_neon(parent: Node3D, res: Dictionary) -> void:
	var floor_m := mat("concrete_dark", 8.0)
	var floor_mi := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(36, 26)
	pm.material = floor_m
	floor_mi.mesh = pm
	parent.add_child(floor_mi)
	var body := StaticBody3D.new()
	floor_mi.add_child(body)
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = Vector3(36, 0.5, 26)
	cs.shape = bs
	cs.position = Vector3(0, -0.25, 0)
	body.add_child(cs)

	var wall_m := mat("metal_dark", 2.5)
	var ac_m := mat("metal", 1.0)
	var neon_c := mat("neon_cyan", 1.0, Color(0, 0.9, 1.0), 4.0)
	var neon_p := mat("neon_pink", 1.0, Color(1, 0.24, 0.63), 4.0)
	var crate_m := mat("crate")

	# 天台围栏
	box(parent, Vector3(0, 0.6, -13.2), Vector3(36, 1.2, 0.5), wall_m)
	box(parent, Vector3(0, 0.6, 13.2), Vector3(36, 1.2, 0.5), wall_m)
	box(parent, Vector3(-18.2, 0.6, 0), Vector3(0.5, 1.2, 26), wall_m)
	box(parent, Vector3(18.2, 0.6, 0), Vector3(0.5, 1.2, 26), wall_m)
	# 霓虹灯带
	box(parent, Vector3(0, 1.5, -13.2), Vector3(36, 0.15, 0.15), neon_c)
	box(parent, Vector3(0, 1.5, 13.2), Vector3(36, 0.15, 0.15), neon_p)
	box(parent, Vector3(-18.2, 1.5, 0), Vector3(0.15, 0.15, 26), neon_p)
	box(parent, Vector3(18.2, 1.5, 0), Vector3(0.15, 0.15, 26), neon_c)

	# 空调机组掩体
	for ac in [
		[Vector3(-10, 0.9, -7), Vector3(3, 1.8, 2.4)],
		[Vector3(10, 0.9, 7), Vector3(3, 1.8, 2.4)],
		[Vector3(10, 0.9, -7), Vector3(2.4, 1.8, 3)],
		[Vector3(-10, 0.9, 7), Vector3(2.4, 1.8, 3)],
		[Vector3(0, 0.9, -9), Vector3(5, 1.8, 2)],
		[Vector3(0, 0.9, 9), Vector3(5, 1.8, 2)],
	]:
		box(parent, ac[0], ac[1], ac_m)
	# 中央通风塔（可蹬墙跑）
	box(parent, Vector3(0, 2.2, 0), Vector3(2.2, 4.4, 2.2), wall_m)
	box(parent, Vector3(0, 4.5, 0), Vector3(2.6, 0.2, 2.6), neon_c)
	# 木箱
	var rng := RandomNumberGenerator.new()
	rng.seed = 22
	for i in 10:
		var x := rng.randf_range(-15, 15)
		var z := rng.randf_range(-10, 10)
		if absf(x) < 3 and absf(z) < 3:
			continue
		box(parent, Vector3(x, 0.45, z), Vector3(0.9, 0.9, 0.9), crate_m)
	# 侧翼高台
	box(parent, Vector3(-15, 1.4, -5), Vector3(4, 0.4, 4), wall_m)
	box(parent, Vector3(15, 1.4, 5), Vector3(4, 0.4, 4), wall_m)
	# 电梯间（角落建筑）
	box(parent, Vector3(-15, 2, 9), Vector3(4, 4, 4), wall_m)
	box(parent, Vector3(15, 2, -9), Vector3(4, 4, 4), wall_m)
	box(parent, Vector3(-15, 4.2, 9), Vector3(4.2, 0.2, 4.2), neon_p)
	box(parent, Vector3(15, 4.2, -9), Vector3(4.2, 0.2, 4.2), neon_c)

	# 顶灯
	for p in [Vector3(-8, 7, 0), Vector3(8, 7, 0)]:
		var l := OmniLight3D.new()
		l.light_color = Color(0.5, 0.8, 1.0)
		l.light_energy = 2.5
		l.omni_range = 16.0
		l.position = p
		parent.add_child(l)

	res.spawns_red = [
		Vector3(-16, 0.5, -10), Vector3(-16, 0.5, 10),
		Vector3(-10, 0.5, 0), Vector3(-16, 0.5, 0),
	]
	res.spawns_blue = [
		Vector3(16, 0.5, 10), Vector3(16, 0.5, -10),
		Vector3(10, 0.5, 0), Vector3(16, 0.5, 0),
	]
	res.waypoints = [
		Vector3(-12, 0.5, -6), Vector3(-12, 0.5, 6), Vector3(12, 0.5, -6), Vector3(12, 0.5, 6),
		Vector3(0, 0.5, -6), Vector3(0, 0.5, 6), Vector3(-6, 0.5, 0), Vector3(6, 0.5, 0),
		Vector3(-15, 1.7, -5), Vector3(15, 1.7, 5), Vector3(-15, 0.5, 9), Vector3(15, 0.5, -9),
	]

# ================= 训练场 =================
static func _build_training(parent: Node3D, res: Dictionary) -> void:
	var floor_m := mat("floor_1", 12.0)
	var floor_mi := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(70, 46)
	pm.material = floor_m
	floor_mi.mesh = pm
	parent.add_child(floor_mi)
	var body := StaticBody3D.new()
	floor_mi.add_child(body)
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = Vector3(70, 0.5, 46)
	cs.shape = bs
	cs.position = Vector3(0, -0.25, 0)
	body.add_child(cs)

	var wall_m := mat("metal", 3.0)
	var crate_m := mat("crate")
	var hazard_m := mat("hazard", 2.0)

	# 外墙
	box(parent, Vector3(0, 2, -23.5), Vector3(70, 4, 1), wall_m)
	box(parent, Vector3(0, 2, 23.5), Vector3(70, 4, 1), wall_m)
	box(parent, Vector3(-35.5, 2, 0), Vector3(1, 4, 46), wall_m)
	box(parent, Vector3(35.5, 2, 0), Vector3(1, 4, 46), wall_m)

	# ===== 靶道 =====
	var lane_z := -16.0
	for i in 6:
		var dist := 8.0 + i * 5.0
		var t := Target.new()
		t.setup()
		t.position = Vector3(0, 1.4, lane_z - dist)
		parent.add_child(t)
		box(parent, t.position + Vector3(0, -0.9, 0), Vector3(0.3, 1.0, 0.3), wall_m)
	# 侧向移动靶道
	for i in 4:
		var t2 := Target.new()
		t2.setup()
		t2.position = Vector3(-12 + i * 8, 1.4, lane_z - 15)
		parent.add_child(t2)

	# ===== 机动训练区 =====
	# 蹬墙跑走廊：两堵平行墙
	var wr_m := mat("metal", 2.0)
	box(parent, Vector3(-24, 2, 0), Vector3(0.8, 4, 24), wr_m)
	box(parent, Vector3(-18, 2, 0), Vector3(0.8, 4, 24), wr_m)
	# 蹬墙跳平台
	for p in [Vector3(-21, 1.2, -14), Vector3(-21, 2.4, -6), Vector3(-21, 3.6, 2), Vector3(-21, 4.8, 10)]:
		box(parent, p, Vector3(3, 0.3, 3), hazard_m)
	# 滑铲赛道：低障碍（滑铲通过）
	for i in 5:
		box(parent, Vector3(10, 0.8, -14 + i * 6), Vector3(6, 1.6, 0.5), hazard_m)
	# 跳台
	for i in 4:
		box(parent, Vector3(24, 0.6 + i * 0.9, -12 + i * 7), Vector3(3.5, 0.4, 3.5), crate_m)
	# 高塔（跳跳乐）
	box(parent, Vector3(24, 3, 16), Vector3(5, 6, 5), wall_m)

	# ===== Bot 竞技区 =====
	var fence_m := mat("metal_dark", 1.5)
	box(parent, Vector3(0, 1, 18), Vector3(40, 2, 0.5), fence_m)
	res.waypoints = [
		Vector3(-8, 0.5, 8), Vector3(8, 0.5, 8), Vector3(0, 0.5, 4), Vector3(-14, 0.5, 14),
		Vector3(14, 0.5, 14), Vector3(0, 0.5, 20), Vector3(-16, 0.5, 2), Vector3(16, 0.5, 2),
	]

	# ===== 武器试验台 =====
	var bench := box(parent, Vector3(-30, 0.6, -18), Vector3(3, 1.2, 2), crate_m)
	bench.name = "WeaponBench"
	res.interact_points["armory"] = Vector3(-30, 1.5, -16)
	var sign := Label3D.new()
	sign.text = "武器试验台 [E]"
	sign.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sign.font_size = 40
	sign.position = Vector3(-30, 2.6, -18)
	sign.modulate = Color(1, 0.8, 0.3)
	parent.add_child(sign)

	res.spawns_blue = [Vector3(0, 0.5, 0)]
	res.spawns_red = []
