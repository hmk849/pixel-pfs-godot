class_name Weapon
extends Node3D
## 第一人称武器视图模型 + 弹药状态 + 动画（检视/换弹/开镜/疾跑姿态）

var data: Dictionary
var gun_model := Node3D.new()
var anim: Node3D = null
var mag_current := 0
var reserve := 0
var fire_cd := 0.0
var reloading := false
var inspecting := false
var ads_amount := 0.0

var _kick := 0.0
var _bob_t := 0.0
var _hip_pos := Vector3(0.26, -0.23, -0.5)
var _ads_pos := Vector3(0.0, -0.132, -0.42)
var _cur_pos := Vector3(0.26, -0.23, -0.5)
var _cur_rot := Vector3.ZERO

func setup(w: Dictionary) -> void:
	data = w
	mag_current = int(w.mag)
	reserve = int(w.reserve)
	for c in get_children():
		c.queue_free()
	gun_model = Node3D.new()
	add_child(gun_model)
	anim = SoldierFactory.build_gun(w)
	gun_model.add_child(anim)

func ammo_text() -> String:
	return "%d / %d" % [mag_current, reserve]

func has_ammo() -> bool:
	return mag_current > 0

func can_fire() -> bool:
	return fire_cd <= 0.0 and not reloading and not inspecting and mag_current > 0

func consume_fire() -> void:
	mag_current -= 1
	fire_cd = 60.0 / float(data.rpm)
	_kick = 1.0

func start_reload() -> bool:
	if reloading or reserve <= 0 or mag_current >= int(data.mag):
		return false
	reloading = true
	Snd.play("reload", -4)
	var tw := create_tween()
	tw.tween_property(anim, "position:y", -0.25, float(data.reload) * 0.35)
	tw.parallel().tween_property(anim, "rotation:x", -30.0, float(data.reload) * 0.4)
	tw.tween_interval(float(data.reload) * 0.25)
	tw.tween_property(anim, "position:y", 0.0, float(data.reload) * 0.25)
	tw.parallel().tween_property(anim, "rotation:x", 0.0, float(data.reload) * 0.25)
	await tw.finished
	if not is_inside_tree():
		return true
	var need := int(data.mag) - mag_current
	var take := mini(need, reserve)
	mag_current += take
	reserve -= take
	reloading = false
	return true

func start_inspect() -> void:
	if inspecting or reloading:
		return
	inspecting = true
	var tw := create_tween()
	tw.tween_property(anim, "rotation:y", 360.0, 1.0).set_trans(Tween.TRANS_SINE)
	tw.parallel().tween_property(anim, "rotation:z", 12.0, 0.5)
	tw.parallel().tween_property(anim, "rotation:x", -8.0, 0.5)
	tw.tween_property(anim, "rotation:z", -12.0, 0.5)
	tw.tween_property(anim, "rotation:z", 0.0, 0.4)
	tw.tween_property(anim, "rotation:x", 0.0, 0.4)
	tw.tween_property(anim, "rotation:y", 360.0, 1.0).set_trans(Tween.TRANS_SINE)
	tw.tween_interval(0.01)
	await tw.finished
	if is_inside_tree():
		anim.rotation = Vector3.ZERO
		anim.position = Vector3.ZERO
	inspecting = false

func cancel_inspect() -> void:
	if inspecting:
		inspecting = false
		if anim:
			anim.rotation = Vector3.ZERO
			anim.position = Vector3.ZERO

func barrel_len() -> float:
	match str(data.cat):
		"sniper": return 1.05
		"rifle": return 0.75
		"shotgun": return 0.7
		"smg": return 0.5
		_: return 0.35

func muzzle_global() -> Vector3:
	return global_transform * (_cur_pos + Vector3(0, 0, -barrel_len()))

## 每帧更新视图模型姿态
func update_pose(delta: float, move_speed: float, sprinting: bool, sliding: bool) -> void:
	fire_cd = maxf(fire_cd - delta, 0.0)
	_kick = lerpf(_kick, 0.0, delta * 10.0)
	_bob_t += delta * clampf(move_speed, 0.0, 10.0)

	var target := _hip_pos.lerp(_ads_pos, ads_amount)
	var target_rot := Vector3.ZERO
	if sprinting and ads_amount < 0.3:
		target = Vector3(0.18, -0.28, -0.45)
		target_rot = Vector3(6, 24, 4)
	# 走路摆动
	var bob_amp := clampf(move_speed / 8.0, 0.0, 1.0) * (0.012 if ads_amount < 0.5 else 0.003)
	target += Vector3(
		sin(_bob_t * 1.6) * bob_amp,
		absf(sin(_bob_t * 3.2)) * bob_amp,
		_kick * 0.07)
	target_rot.x -= _kick * 5.0

	var lerp_speed := 12.0 + ads_amount * 8.0
	_cur_pos = _cur_pos.lerp(target, clampf(delta * lerp_speed, 0.0, 1.0))
	_cur_rot = _cur_rot.lerp(target_rot, clampf(delta * lerp_speed, 0.0, 1.0))
	gun_model.position = _cur_pos
	gun_model.rotation = Vector3(deg_to_rad(_cur_rot.x), deg_to_rad(_cur_rot.y), deg_to_rad(_cur_rot.z))
