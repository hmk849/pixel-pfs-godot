class_name FX
extends Node3D
## 临时特效：曳光轨迹、枪口火光、命中火花、命中数字

static var _scene_root: Node3D = null

static func setup(root: Node3D) -> void:
	_scene_root = root

static func tracer(from: Vector3, to: Vector3, col := Color(1.0, 0.85, 0.4)) -> void:
	if _scene_root == null:
		return
	var mesh := ImmediateMesh.new()
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	mesh.surface_add_vertex(from)
	mesh.surface_add_vertex(to)
	mesh.surface_end()
	var mat := StandardMaterial3D.new()
	mat.albedo_color = col
	mat.emission_enabled = true
	mat.emission = col
	mat.emission_energy_multiplier = 6.0
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mi.material_override = mat
	_scene_root.add_child(mi)
	var tw := mi.create_tween()
	tw.tween_property(mat, "albedo_color:a", 0.0, 0.07)
	tw.finished.connect(mi.queue_free)

static func muzzle_flash(at: Vector3, parent: Node3D) -> void:
	var light := OmniLight3D.new()
	light.light_color = Color(1.0, 0.75, 0.35)
	light.light_energy = 8.0
	light.omni_range = 6.0
	light.position = at
	parent.add_child(light)
	var tex := load("res://assets/textures/muzzle_flash.png") as Texture2D
	var sprite := Sprite3D.new()
	if tex:
		sprite.texture = tex
		sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		sprite.pixel_size = 0.01
		sprite.position = at
		parent.add_child(sprite)
	var tw := light.create_tween()
	tw.tween_property(light, "light_energy", 0.0, 0.08)
	tw.finished.connect(light.queue_free)
	var tw2 := sprite.create_tween()
	tw2.tween_property(sprite, "modulate", Color(1, 1, 1, 0), 0.08)
	tw2.finished.connect(sprite.queue_free)

static func impact(at: Vector3, normal: Vector3, col := Color(1.0, 0.8, 0.4)) -> void:
	if _scene_root == null:
		return
	var light := OmniLight3D.new()
	light.light_color = col
	light.light_energy = 2.5
	light.omni_range = 2.0
	light.position = at + normal * 0.1
	_scene_root.add_child(light)
	var tw := light.create_tween()
	tw.tween_property(light, "light_energy", 0.0, 0.1)
	tw.finished.connect(light.queue_free)
	# 火花粒子
	var p := CPUParticles3D.new()
	p.amount = 6
	p.one_shot = true
	p.emitting = true
	p.lifetime = 0.25
	p.explosiveness = 1.0
	p.direction = normal
	p.spread = 35.0
	p.initial_velocity_min = 2.0
	p.initial_velocity_max = 5.0
	p.scale_amount_min = 0.4
	p.scale_amount_max = 0.8
	p.position = at + normal * 0.05
	_scene_root.add_child(p)
	get_tree_timer(0.4, p)

static func blood(at: Vector3) -> void:
	if _scene_root == null:
		return
	var p := CPUParticles3D.new()
	p.amount = 10
	p.one_shot = true
	p.emitting = true
	p.lifetime = 0.3
	p.explosiveness = 1.0
	p.direction = Vector3.UP
	p.spread = 180.0
	p.initial_velocity_min = 1.0
	p.initial_velocity_max = 3.0
	p.position = at
	_scene_root.add_child(p)
	get_tree_timer(0.5, p)

static func get_tree_timer(t: float, node: Node) -> void:
	if _scene_root == null:
		return
	var tw := _scene_root.create_tween()
	tw.tween_interval(t)
	tw.finished.connect(node.queue_free)
