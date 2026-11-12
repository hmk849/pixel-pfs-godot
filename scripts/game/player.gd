class_name Player
extends CharacterBody3D
## Pixpfs 玩家控制器：泰坦陨落级机动 + CoD 滑铲 + 三角洲行动射击手感

const SPEED_WALK := 5.4
const SPEED_SPRINT := 8.2
const SPEED_CROUCH := 2.9
const ACCEL_GROUND := 14.0
const ACCEL_AIR := 3.2
const GRAVITY := 19.0
const JUMP_VEL := 6.9
const DOUBLE_JUMP_VEL := 6.4
const WALLRUN_MAX := 1.7
const SLIDE_TIME := 0.85
const BASE_SENS := 0.0021

var team := "blue"
var display_name := "你"
var hp := 100.0
var max_hp := 100.0
var alive := true
var kills := 0
var deaths := 0
var shots_fired := 0
var shots_hit := 0

var head: Node3D
var camera: Camera3D
var weapons: Dictionary = {}
var current_weapon_id := ""

# 运动状态
var _jump_count := 0
var _coyote := 0.0
var _jump_buffer := 0.0
var _wallrun_t := 0.0
var _wallrun_cd := 0.0
var _wall_normal := Vector3.ZERO
var _wallrunning := false
var _sliding := false
var _slide_t := 0.0
var _slide_dir := Vector3.ZERO
var _slide_speed := 0.0
var _crouching := false
var _sprinting := false
var _cam_roll := 0.0
var _recoil_pitch := 0.0
var _recoil_yaw := 0.0
var _bloom := 0.0
var _look_acc := Vector2.ZERO
var _footstep_t := 0.0
var _regen_t := 0.0
var _step_since_ground := false
var _touch_sprint := false

func _ready() -> void:
	max_hp = 100.0
	var op := G.op()
	match str(op.get("perk_type", "")):
		"hp": max_hp = float(op.perk_val)
	hp = max_hp

	var cs := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.36
	capsule.height = 1.8
	cs.shape = capsule
	add_child(cs)

	head = Node3D.new()
	head.position = Vector3(0, 1.62, 0)
	add_child(head)

	camera = Camera3D.new()
	camera.fov = float(G.settings.video.fov)
	camera.near = 0.03
	camera.current = true
	head.add_child(camera)
	camera.make_current()

	# 武器：主武器 + 副武器
	for wid in [G.weapon_id(), "p11"]:
		var w := Weapon.new()
		camera.add_child(w)
		w.setup(WeaponDB.by_id(wid))
		w.visible = false
		weapons[wid] = w
	equip(G.weapon_id())

	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	G.player = self

func _rebuild_weapons() -> void:
	var old_ids := weapons.keys().duplicate()
	for id in old_ids:
		(weapons[id] as Weapon).queue_free()
		weapons.erase(id)
	for wid in [G.weapon_id(), "p11"]:
		var w := Weapon.new()
		camera.add_child(w)
		w.setup(WeaponDB.by_id(wid))
		w.visible = false
		weapons[wid] = w
	equip(G.weapon_id())

func equip(wid: String) -> void:
	for id in weapons.keys():
		(weapons[id] as Weapon).visible = false
	current_weapon_id = wid
	(weapons[wid] as Weapon).visible = true
	if G.hud:
		G.hud.update_ammo()

func current_weapon() -> Weapon:
	return weapons[current_weapon_id] as Weapon

func refresh_fov() -> void:
	if camera:
		camera.fov = float(G.settings.video.fov)

# ================= 视角 =================
func _unhandled_input(event: InputEvent) -> void:
	if not alive:
		return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_look_acc += event.relative

func _apply_look(delta: float) -> void:
	var look := _look_acc + _touch_look_frame(delta)
	_look_acc = Vector2.ZERO
	var s: Dictionary = G.settings.sens
	var w := current_weapon()
	var ads_mult := 1.0
	if w and w.ads_amount > 0.05:
		ads_mult = lerpf(1.0, float(s.ads_mult), w.ads_amount)
	var fov_scale := camera.fov / float(G.settings.video.fov)
	var sens := BASE_SENS * float(s.mouse) * ads_mult * fov_scale
	var yaw := -look.x * sens
	var pitch := -look.y * sens
	if bool(s.invert_y):
		pitch = -pitch
	rotate_y(yaw)
	head.rotation.x = clampf(head.rotation.x + pitch, deg_to_rad(-89), deg_to_rad(89))

func _touch_look_frame(_delta: float) -> Vector2:
	var v := G.consume_look()
	var s: Dictionary = G.settings.sens
	var accel := 1.0
	var dist := v.length()
	if bool(s.dist_accel):
		accel += float(s.dist_accel_str) * clampf(dist / 40.0, 0.0, 1.5)
	if bool(s.speed_accel):
		accel += float(s.speed_accel_str) * clampf(absf(v.x) / 8.0, 0.0, 1.5)
	return v * 0.0032 * float(s.touch) * accel * (float(G.settings.video.fov) / 90.0)

# ================= 主循环 =================
func _physics_process(delta: float) -> void:
	if not alive:
		return
	_apply_look(delta)
	_update_movement(delta)
	_update_weapon(delta)
	_update_health(delta)

func _update_movement(delta: float) -> void:
	var w := current_weapon()
	var sprint_mult := 1.0
	var op := G.op()
	if str(op.get("perk_type", "")) == "speed":
		sprint_mult = float(op.perk_val)

	_coyote = maxf(_coyote - delta, 0.0)
	_jump_buffer = maxf(_jump_buffer - delta, 0.0)
	_wallrun_cd = maxf(_wallrun_cd - delta, 0.0)
	if G.act_just("jump"):
		_jump_buffer = 0.15
	if G.act_just("crouch"):
		_try_start_slide()
	if not G.act("crouch") and _sliding and is_on_floor():
		_end_slide()

	var input_dir := Vector3.ZERO
	if G.act("move_forward"): input_dir.z -= 1
	if G.act("move_back"): input_dir.z += 1
	if G.act("move_left"): input_dir.x -= 1
	if G.act("move_right"): input_dir.x += 1
	input_dir = input_dir.normalized()
	_touch_sprint = false
	if G.touch_move.length() > 0.05:
		input_dir = Vector3(G.touch_move.x, 0, G.touch_move.y)
		if G.touch_move.length() > 0.92:
			_touch_sprint = true
	var is_sprint_input := G.act("sprint") or _touch_sprint
	input_dir = input_dir.rotated(Vector3.UP, rotation.y)
	_sprinting = is_sprint_input and (input_dir.z < -0.1 or _touch_sprint) and not _crouching
	var target_speed := SPEED_WALK * sprint_mult
	if _sprinting:
		target_speed = SPEED_SPRINT * sprint_mult
	if _crouching:
		target_speed = SPEED_CROUCH
	if w and w.ads_amount > 0.5:
		target_speed *= 0.55

	if _sliding:
		_update_slide(delta, input_dir)
	elif _wallrunning:
		_update_wallrun(delta, input_dir)
	else:
		_update_ground_air(delta, input_dir, target_speed)

	# 跳跃（含二段跳 / 蹬墙跳 / 滑铲跳）
	if _jump_buffer > 0.0:
		if _wallrunning:
			_jump_buffer = 0.0
			_wall_jump()
		elif is_on_floor() or _coyote > 0.0:
			_jump_buffer = 0.0
			_jump_count = 1
			velocity.y = JUMP_VEL
			Snd.play("jump", -8)
		elif _jump_count == 1:
			_jump_buffer = 0.0
			_jump_count = 2
			velocity.y = DOUBLE_JUMP_VEL
			Snd.play("jump", -10)

	if not _wallrunning:
		velocity.y -= GRAVITY * delta

	move_and_slide()
	if is_on_floor():
		if not _step_since_ground:
			Snd.play("land", -10)
			_step_since_ground = true
		_coyote = 0.15
		_jump_count = 0
		_cam_roll = lerpf(_cam_roll, 0.0, delta * 8.0)
	else:
		_step_since_ground = false

	# 相机效果
	var roll_target := 0.0
	if _wallrunning:
		roll_target = 12.0 if _wall_side() < 0 else -12.0
	elif _sliding:
		roll_target = -7.0
	_cam_roll = lerpf(_cam_roll, roll_target, delta * 10.0)
	camera.rotation.z = deg_to_rad(_cam_roll)
	var crouch_lerp := 1.0
	if _crouching or _sliding:
		crouch_lerp = 0.72
	head.position.y = lerpf(head.position.y, 1.62 * crouch_lerp, delta * 12.0)

	# 脚步声
	var hspeed := Vector3(velocity.x, 0, velocity.z).length()
	if is_on_floor() and hspeed > 2.0:
		_footstep_t -= delta * hspeed
		if _footstep_t <= 0.0:
			_footstep_t = 4.2
			Snd.play("footstep", -14)

func _update_ground_air(delta: float, input_dir: Vector3, target_speed: float) -> void:
	if _wallrunning:
		_wallrunning = false
	if _crouching and is_on_floor() and not _sliding:
		pass
	var accel := ACCEL_GROUND if is_on_floor() else ACCEL_AIR
	var target := input_dir * target_speed
	# 疾跑时加速更慢（惯性）
	var control := 1.0 if is_on_floor() else 0.35
	if _sprinting:
		control *= 0.8
	velocity.x = lerpf(velocity.x, target.x, clampf(delta * accel * control, 0, 1))
	velocity.z = lerpf(velocity.z, target.z, clampf(delta * accel * control, 0, 1))

	# 疾跑 + 空中贴近墙壁 → 蹬墙跑
	if not is_on_floor() and _wallrun_cd <= 0.0 and velocity.y < 3.0:
		_try_wallrun()

# ================= 滑铲 =================
func _try_start_slide() -> void:
	var hvel := Vector3(velocity.x, 0, velocity.z)
	if _sliding or not is_on_floor():
		return
	if _sprinting and hvel.length() > 5.0:
		_sliding = true
		_slide_t = SLIDE_TIME
		_slide_dir = hvel.normalized()
		if _slide_dir.length() < 0.1:
			_slide_dir = -global_transform.basis.z
		var op := G.op()
		var slide_mult := 1.0
		if str(op.get("perk_type", "")) == "slide":
			slide_mult = float(op.perk_val)
		_slide_speed = maxf(hvel.length() * 1.12, 9.6) * slide_mult
		_crouching = true
		Snd.play("slide", -6)
	else:
		_crouching = true

func _update_slide(delta: float, input_dir: Vector3) -> void:
	_slide_t -= delta
	if _slide_t <= 0.0 or not is_on_floor():
		_end_slide()
		return
	_slide_speed = lerpf(_slide_speed, 4.0, delta * 1.4)
	# 滑铲中可小幅转向
	_slide_dir = _slide_dir.slerp(
		Vector3(-global_transform.basis.z.x, 0, -global_transform.basis.z.z).normalized(),
		delta * 0.5).normalized()
	velocity.x = _slide_dir.x * _slide_speed
	velocity.z = _slide_dir.z * _slide_speed
	velocity.y = 0.0

func _end_slide() -> void:
	_sliding = false
	_crouching = G.act("crouch")

# ================= 蹬墙跑 =================
func _wall_side() -> float:
	# -1 左墙, 1 右墙, 0 无
	if _wall_normal == Vector3.ZERO:
		return 0.0
	var right := global_transform.basis.x
	if right.dot(-_wall_normal) > 0.3:
		return 1.0
	return -1.0

func _try_wallrun() -> void:
	var space := get_world_3d().direct_space_state
	var origin := global_position + Vector3.UP * 1.2
	var hvel := Vector3(velocity.x, 0, velocity.z)
	if hvel.length() < 4.5:
		return
	for side in [Vector3.RIGHT, Vector3.LEFT]:
		var dir := global_transform.basis.x * float(side.x)
		var q := PhysicsRayQueryParameters3D.create(origin, origin + dir * 0.85)
		q.exclude = [self]
		var hit := space.intersect_ray(q)
		if not hit.is_empty() and absf(float(hit.normal.y)) < 0.3:
			_wall_normal = hit.normal
			_wallrunning = true
			_wallrun_t = 0.0
			Snd.play("wallrun", -10)
			return

func _update_wallrun(delta: float, _input_dir: Vector3) -> void:
	_wallrun_t += delta
	# 沿墙面切线奔跑
	var tangent := Vector3.UP.cross(_wall_normal).normalized()
	if tangent.dot(Vector3(velocity.x, 0, velocity.z)) < 0:
		tangent = -tangent
	var speed := clampf(Vector3(velocity.x, 0, velocity.z).length(), 6.0, 11.0)
	velocity.x = tangent.x * speed
	velocity.z = tangent.z * speed
	velocity.y = lerpf(velocity.y, -0.6, delta * 3.0)
	if _wallrun_t > WALLRUN_MAX:
		_stop_wallrun()

func _stop_wallrun() -> void:
	_wallrunning = false
	_wallrun_cd = 0.35
	_jump_count = 0  # 落墙后重置二段跳

func _wall_jump() -> void:
	var boost := _wall_normal * 5.6 + Vector3.UP * 6.6
	var fwd := -global_transform.basis.z
	velocity += boost + fwd * 1.5
	velocity.y = maxf(velocity.y, 6.2)
	_stop_wallrun()
	Snd.play("jump", -8)

# ================= 武器 =================
func _update_weapon(delta: float) -> void:
	var w := current_weapon()
	if w == null:
		return

	# 开镜
	var want_ads := G.act("ads") and alive and not _sliding
	var ads_speed := 1.0 / float(w.data.ads_time)
	var op := G.op()
	if str(op.get("perk_type", "")) == "ads":
		ads_speed *= float(op.perk_val)
	w.ads_amount = clampf(w.ads_amount + (delta * ads_speed if want_ads else -delta * ads_speed * 1.3), 0.0, 1.0)
	var target_fov := lerpf(float(G.settings.video.fov), float(w.data.ads_fov), w.ads_amount)
	camera.fov = lerpf(camera.fov, target_fov, clampf(delta * 14.0, 0, 1))

	# 换弹 / 检视 / 切枪
	if G.act_just("reload"):
		w.start_reload()
	if G.act_just("inspect") and not want_ads:
		w.start_inspect()
	if G.act_just("switch_weapon"):
		var ids := weapons.keys()
		for id in ids:
			if str(id) != current_weapon_id:
				w.cancel_inspect()
				equip(str(id))
				break

	# 开火
	var is_semi := not bool(w.data.auto)
	var want_fire := G.act_just("fire") if is_semi else G.act("fire")
	if want_fire and not w.reloading:
		if w.can_fire():
			_fire(w)
		elif not w.has_ammo() and G.act_just("fire"):
			Snd.play("empty_click", -8)
			if G.act_just("reload"):
				pass

	w.update_pose(delta, Vector3(velocity.x, 0, velocity.z).length(), _sprinting, _sliding)
	_bloom = lerpf(_bloom, 0.0, delta * 6.0)
	# 后坐力恢复
	head.rotation.x -= _recoil_pitch
	_recoil_pitch = lerpf(_recoil_pitch, 0.0, delta * 8.0)
	head.rotation.x += _recoil_pitch
	rotate_y(-_recoil_yaw)
	_recoil_yaw = lerpf(_recoil_yaw, 0.0, delta * 8.0)
	rotate_y(_recoil_yaw)

func _fire(w: Weapon) -> void:
	w.consume_fire()
	shots_fired += 1
	Snd.play(str(w.data.sound), -3, randf_range(0.96, 1.04))
	var muzzle := w.muzzle_global()
	FX.muzzle_flash(camera.to_local(muzzle), camera)
	var from := camera.global_position
	var fwd := -camera.global_transform.basis.z
	var right := camera.global_transform.basis.x
	var up := camera.global_transform.basis.y

	# 散布：腰射/开镜/移动/连续射击
	var spread_deg := lerpf(float(w.data.spread), float(w.data.ads_spread), w.ads_amount)
	spread_deg += _bloom * 1.2
	spread_deg += clampf(Vector3(velocity.x, 0, velocity.z).length() * 0.08, 0.0, 2.5)
	if not is_on_floor():
		spread_deg += 1.5
	_bloom = minf(_bloom + 0.35, 3.0)

	var pellets := int(w.data.get("pellets", 1))
	var space := get_world_3d().direct_space_state
	for i in pellets:
		var ang := deg_to_rad(spread_deg)
		var dir := (fwd
			+ right * randf_range(-ang, ang)
			+ up * randf_range(-ang, ang)).normalized()
		var to := from + dir * 300.0
		var q := PhysicsRayQueryParameters3D.create(from, to)
		q.exclude = [self]
		var hit := space.intersect_ray(q)
		var end_point := to if hit.is_empty() else (hit.position as Vector3)
		FX.tracer(muzzle, end_point)
		if hit.is_empty():
			continue
		var col: Object = hit.collider
		var dist := from.distance_to(hit.position)
		var dmg := _compute_damage(w, dist)
		var is_head := false
		if col is Bot:
			is_head = (hit.position as Vector3).y > (col as Bot).global_position.y + 1.42
		if col is Target:
			(col as Target).hit(dmg, display_name)
			continue
		elif col is Bot:
			(col as Bot).take_damage(dmg, is_head, self)
			shots_hit += 1
		else:
			FX.impact(hit.position, hit.normal)
	# 后坐力
	var rec := float(w.data.recoil)
	_recoil_pitch += deg_to_rad(rec * 0.55)
	_recoil_yaw = deg_to_rad(randf_range(-rec, rec) * 0.18)
	if G.hud:
		G.hud.on_player_shot()

func _compute_damage(w: Weapon, dist: float) -> float:
	var dmg := float(w.data.dmg)
	var range := float(w.data.range)
	if dist > range:
		dmg *= lerpf(1.0, float(w.data.falloff), clampf((dist - range) / 30.0, 0.0, 1.0))
	return dmg

# ================= 生命 =================
func _update_health(delta: float) -> void:
	if hp < max_hp:
		_regen_t += delta
		if _regen_t > 4.0:
			var rate := 9.0
			var op := G.op()
			if str(op.get("perk_type", "")) == "regen":
				rate *= float(op.perk_val)
			hp = minf(hp + rate * delta, max_hp)
			if G.hud:
				G.hud.update_health(hp / max_hp)
	else:
		_regen_t = 0.0

func take_damage(dmg: float, from_pos: Vector3, killer_name: String) -> void:
	if not alive:
		return
	hp -= dmg
	_regen_t = 0.0
	Snd.play("damage", -6)
	if G.hud:
		G.hud.damage_from(from_pos)
		G.hud.update_health(hp / max_hp)
	if hp <= 0.0:
		die(killer_name)

func die(killer_name: String) -> void:
	alive = false
	deaths += 1
	velocity = Vector3.ZERO
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if G.hud:
		G.hud.show_death(killer_name)

func respawn(pos: Vector3) -> void:
	alive = true
	hp = max_hp
	global_position = pos
	_jump_count = 0
	_sliding = false
	_wallrunning = false
	for id in weapons.keys():
		var w := weapons[id] as Weapon
		w.setup(WeaponDB.by_id(str(id)))
	equip(current_weapon_id)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if G.hud:
		G.hud.hide_death()
		G.hud.update_health(1.0)
		G.hud.update_ammo()

func setup_gyro() -> void:
	if G.hud:
		G.hud.call("touch_setup_gyro")
