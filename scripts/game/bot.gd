class_name Bot
extends CharacterBody3D
## Pixpfs Bot：巡逻 / 交战 / 侧移 + 射击，红蓝双方共用

var team := "red"
var display_name := "Bot"
var hp := 100.0
var alive := true
var kills := 0
var deaths := 0
var difficulty := 1.0   # 0.5 简单 / 1 普通 / 1.5 困难

var _waypoints: Array = []
var _wp_index := 0
var _target: Node3D = null
var _fire_t := 0.0
var _burst := 0
var _strafe_dir := 1.0
var _strafe_t := 0.0
var _dead_t := 0.0
var _rig: Node3D
var _label: Label3D
var _speed := 4.6

func setup(p_team: String, p_name: String, op: Dictionary, weapon: Dictionary, waypoints: Array, diff := 1.0) -> void:
	team = p_team
	display_name = p_name
	difficulty = diff
	_waypoints = waypoints
	_speed = 4.2 + randf() * 0.8

	var cs := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.36
	cap.height = 1.8
	cs.shape = cap
	add_child(cs)

	var tint := Color(1, 0.35, 0.35) if team == "red" else Color(0.35, 0.6, 1.0)
	_rig = SoldierFactory.build(op, weapon, tint)
	add_child(_rig)

	_label = Label3D.new()
	_label.text = p_name
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.font_size = 48
	_label.modulate = Color(1, 0.45, 0.45) if team == "red" else Color(0.45, 0.7, 1.0)
	_label.position = Vector3(0, 2.25, 0)
	_label.no_depth_test = true
	add_child(_label)

	# 碰撞
	var body := Node3D.new()
	add_child(body)

func _physics_process(delta: float) -> void:
	if not alive:
		_dead_t -= delta
		visible = false
		if _dead_t <= 0.0 and not _waypoints.is_empty():
			_respawn()
		return
	visible = true
	_ai(delta)
	move_and_slide()
	_animate(delta)

func _respawn() -> void:
	alive = true
	hp = 100.0
	var wp: Variant = _random_wp()
	if wp is Vector3:
		global_position = wp + Vector3(randf_range(-1, 1), 0.5, randf_range(-1, 1))
	visible = true

func _random_wp() -> Variant:
	if _waypoints.is_empty():
		return null
	return _waypoints[randi() % _waypoints.size()]

func _ai(delta: float) -> void:
	# 找目标：敌方最近可见单位
	if _target != null and (not is_instance_valid(_target) or not _target_alive(_target)):
		_target = null
	if _target == null or not _target_visible():
		_acquire_target()

	if _target != null and _target_visible():
		_engage(delta)
	else:
		_patrol(delta)

func _target_alive(t: Node3D) -> bool:
	if t is Bot:
		return (t as Bot).alive
	if t is Player:
		return (t as Player).alive
	return true

func _acquire_target() -> void:
	var candidates: Array = []
	var match_node := get_parent()
	if match_node == null:
		return
	for c in match_node.get_children():
		if c is Player and c.alive and c.team != team:
			candidates.append(c)
		elif c is Bot and c.alive and c.team != team:
			candidates.append(c)
	if candidates.is_empty():
		return
	var best: Node3D = null
	var best_d := 1e9
	for c in candidates:
		var d := global_position.distance_to(c.global_position)
		if d < best_d and _can_see(c):
			best = c
			best_d = d
	_target = best

func _target_visible() -> bool:
	return _target != null and is_instance_valid(_target) and _can_see(_target)

func _can_see(t: Node3D) -> bool:
	var from := global_position + Vector3.UP * 1.5
	var to := t.global_position + Vector3.UP * 1.4
	var space := get_world_3d().direct_space_state
	var q := PhysicsRayQueryParameters3D.create(from, to)
	q.exclude = [self]
	var hit := space.intersect_ray(q)
	return hit.is_empty() or hit.collider == t

func _patrol(delta: float) -> void:
	if _waypoints.is_empty():
		return
	var wp := _waypoints[_wp_index] as Vector3
	var dir := (wp - global_position)
	dir.y = 0
	if dir.length() < 1.5:
		_wp_index = (_wp_index + 1) % _waypoints.size()
		return
	dir = dir.normalized()
	velocity.x = dir.x * _speed
	velocity.z = dir.z * _speed
	velocity.y -= 18.0 * delta
	_face_dir(dir, delta)

func _engage(delta: float) -> void:
	var t := _target
	var to_target := (t.global_position - global_position)
	var dist := to_target.length()
	var dir := to_target.normalized()
	# 侧移
	_strafe_t -= delta
	if _strafe_t <= 0.0:
		_strafe_t = randf_range(0.6, 1.4)
		_strafe_dir = -_strafe_dir
	var side := Vector3.UP.cross(dir).normalized() * _strafe_dir
	var move := side * _speed * 0.7
	if dist > 20.0:
		move += dir * _speed * 0.6
	elif dist < 6.0:
		move -= dir * _speed * 0.5
	velocity.x = move.x
	velocity.z = move.z
	velocity.y -= 18.0 * delta
	_face_dir(Vector3(dir.x, 0, dir.z), delta)
	_shoot(t, delta, dist)

func _face_dir(dir: Vector3, delta: float) -> void:
	if dir.length() < 0.01:
		return
	var target_yaw := atan2(dir.x, dir.z) + PI
	rotation.y += angle_diff(rotation.y, target_yaw) * minf(delta * 6.0, 1.0)

func angle_diff(a: float, b: float) -> float:
	return wrapf(b - a, -PI, PI)

func _shoot(t: Node3D, delta: float, dist: float) -> void:
	_fire_t -= delta
	if _fire_t > 0.0:
		return
	var interval := 0.14 / difficulty
	if _burst <= 0:
		_burst = int(randi() % 5 + 3)
		_fire_t = randf_range(0.5, 1.1) / difficulty
		return
	_burst -= 1
	_fire_t = interval
	# 命中判定：基于难度和距离
	var hit_chance := clampf(0.75 * difficulty - dist * 0.012, 0.12, 0.85)
	Snd.play("shot_rifle", -8, randf_range(0.95, 1.05))
	var from := global_position + Vector3.UP * 1.5
	FX.tracer(from, t.global_position + Vector3.UP * randf_range(0.6, 1.6))
	if randf() < hit_chance:
		var dmg := randf_range(8.0, 16.0)
		if t is Player:
			(t as Player).take_damage(dmg, global_position, display_name)
		elif t is Bot:
			(t as Bot).take_damage(dmg, false, self)

func take_damage(dmg: float, is_head: bool, attacker: Node) -> void:
	if not alive:
		return
	if is_head:
		dmg *= 1.6
	hp -= dmg
	FX.blood(global_position + Vector3.UP * randf_range(0.8, 1.5))
	if hp <= 0.0:
		_die(attacker)

func _die(attacker: Node) -> void:
	alive = false
	deaths += 1
	_dead_t = 4.0
	visible = false
	var killer_name := "Bot"
	if attacker is Player:
		killer_name = (attacker as Player).display_name
		(attacker as Player).kills += 1
	elif attacker is Bot:
		killer_name = (attacker as Bot).display_name
		(attacker as Bot).kills += 1
	var match_node := get_parent()
	if match_node is Match:
		(match_node as Match).on_bot_killed(self, killer_name, team)

func _animate(delta: float) -> void:
	# 简易跑步动画
	var hspeed := Vector3(velocity.x, 0, velocity.z).length()
	if _rig:
		var t := Time.get_ticks_msec() / 1000.0
		var swing := sin(t * 10.0) * clampf(hspeed / 8.0, 0.0, 1.0) * 0.5
		var leg_l := _rig.get_node_or_null("LegL")
		var leg_r := _rig.get_node_or_null("LegR")
		if leg_l:
			leg_l.rotation.x = swing
		if leg_r:
			leg_r.rotation.x = -swing
		if _label:
			_label.text = "%s" % display_name
