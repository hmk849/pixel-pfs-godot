class_name Target
extends StaticBody3D
## 训练场靶子

var _alive := true
var _respawn_t := 0.0
var _reset_rot := Vector3.ZERO

func setup() -> void:
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = Vector3(0.9, 1.1, 0.12)
	cs.shape = bs
	add_child(cs)
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.9, 1.1, 0.12)
	mi.mesh = bm
	var m := StandardMaterial3D.new()
	var tex := load("res://assets/textures/target.png") as Texture2D
	if tex:
		m.albedo_texture = tex
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	mi.material_override = m
	add_child(mi)

func _ready() -> void:
	_reset_rot = rotation

func _process(delta: float) -> void:
	if not _alive:
		_respawn_t -= delta
		# 靶子倒下动画
		rotation.x = lerpf(rotation.x, deg_to_rad(-85), delta * 6.0)
		if _respawn_t <= 0.0:
			_alive = true
	else:
		rotation.x = lerpf(rotation.x, _reset_rot.x, delta * 6.0)

func hit(_dmg: float, _by: String) -> void:
	if not _alive:
		return
	_alive = false
	_respawn_t = 2.0
	Snd.play("hitmarker", -6)
	if G.hud:
		G.hud.hitmarker(false)
