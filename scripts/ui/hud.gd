class_name GameHUD
extends CanvasLayer
## Pixpfs 对战 HUD：Valorant 风格炫酷简约

var mode := "match"  # match / training
var _root: Control
var _cross: Control
var _health_fill: ColorRect
var _health_label: Label
var _ammo_label: Label
var _weapon_label: Label
var _kill_count: Label
var _timer_label: Label
var _feed_box: VBoxContainer
var _red_panel: VBoxContainer
var _blue_panel: VBoxContainer
var _banner: Label
var _death_overlay: Control
var _death_label: Label
var _death_timer: Label
var _hitmarker_t := 0.0
var _hitmarker_head := false
var _spread_px := 0.0
var _damage_marks: Array = []  # {angle, t}
var _interact_hint: Label
var _scope_overlay: Control
var _vignette: ColorRect
var _heart_t := 0.0
var touch: TouchControls = null
var _hp_panel: Control
var _ammo_panel: Control
var _death_dv: VBoxContainer

func _ready() -> void:
	layer = 20
	G.hud = self
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)
	var s: Dictionary = G.settings.controls
	_root.scale = Vector2(float(s.hud_scale), float(s.hud_scale))
	_root.modulate = Color(1, 1, 1, clampf(float(s.hud_opacity), 0.15, 1.0))

	_build()
	touch = TouchControls.new()
	add_child(touch)
	if G.is_touch_device():
		touch.enable()

# ================= 构建 =================
func _build() -> void:
	# 准心
	_cross = CrosshairControl.new()
	_cross.set_anchors_preset(Control.PRESET_FULL_RECT)
	_cross.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_cross)

	# 狙击镜遮罩
	_scope_overlay = ScopeOverlay.new()
	_scope_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_scope_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_scope_overlay.visible = false
	_root.add_child(_scope_overlay)

	# 低血量暗角
	_vignette = ColorRect.new()
	_vignette.color = Color(0.5, 0.05, 0.05, 0.0)
	_vignette.set_anchors_preset(Control.PRESET_FULL_RECT)
	_vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_vignette)

	# ---- 左上：击杀数 / 红方面板 ----
	_kill_count = UITheme.label("", 20, UITheme.TEXT, true)
	_kill_count.position = Vector2(24, 18)
	_root.add_child(_kill_count)
	if mode == "match":
		_red_panel = _team_panel(Color(1, 0.35, 0.35), Vector2(24, 52))

	# ---- 右上：计时 / 蓝方面板 / 击杀播报 ----
	_timer_label = UITheme.label("", 20, UITheme.TEXT, true)
	_timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_root.add_child(_timer_label)

	_feed_box = VBoxContainer.new()
	_feed_box.add_theme_constant_override("separation", 2)
	_root.add_child(_feed_box)

	if mode == "match":
		_blue_panel = _team_panel(Color(0.35, 0.6, 1.0), Vector2(24, 130))

	# ---- 底部：血量条（左） 弹药（右）----
	var hp_panel := UITheme.panel(Color(0.05, 0.06, 0.09, 0.7), 3)
	_hp_panel = hp_panel
	_root.add_child(hp_panel)
	var hp_v := VBoxContainer.new()
	hp_panel.add_child(hp_v)
	_health_label = UITheme.label("100", 22, UITheme.TEXT, true)
	hp_v.add_child(_health_label)
	var bar_bg := ColorRect.new()
	bar_bg.color = Color(1, 1, 1, 0.12)
	bar_bg.custom_minimum_size = Vector2(220, 6)
	hp_v.add_child(bar_bg)
	_health_fill = ColorRect.new()
	_health_fill.color = UITheme.ACCENT
	bar_bg.add_child(_health_fill)

	var ammo_panel := UITheme.panel(Color(0.05, 0.06, 0.09, 0.7), 3)
	_ammo_panel = ammo_panel
	_root.add_child(ammo_panel)
	var ammo_v := VBoxContainer.new()
	ammo_panel.add_child(ammo_v)
	_weapon_label = UITheme.label("", 13, UITheme.TEXT_DIM)
	_weapon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	ammo_v.add_child(_weapon_label)
	_ammo_label = UITheme.label("30 / 120", 26, UITheme.TEXT, true)
	_ammo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	ammo_v.add_child(_ammo_label)

	# ---- 互动提示 ----
	_interact_hint = UITheme.label("", 16, Color(1, 0.85, 0.4))
	_interact_hint.set_anchors_preset(Control.PRESET_CENTER)
	_interact_hint.position = Vector2(-60, 120)
	_root.add_child(_interact_hint)

	# ---- 击杀横幅 ----
	_banner = UITheme.label("", 24, UITheme.ACCENT2, true)
	_banner.set_anchors_preset(Control.PRESET_CENTER)
	_banner.position = Vector2(-100, -170)
	_banner.visible = false
	_root.add_child(_banner)

	# ---- 死亡遮罩 ----
	_death_overlay = Control.new()
	_death_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_death_overlay.visible = false
	_root.add_child(_death_overlay)
	var dim := ColorRect.new()
	dim.color = Color(0.3, 0.02, 0.04, 0.55)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_death_overlay.add_child(dim)
	var dv := VBoxContainer.new()
	_death_overlay.add_child(dv)
	_death_dv = dv
	_death_label = UITheme.label("", 30, UITheme.TEXT, true)
	dv.add_child(_death_label)
	_death_timer = UITheme.label("", 18, UITheme.TEXT_DIM)
	dv.add_child(_death_timer)

func _team_panel(col: Color, pos: Vector2) -> VBoxContainer:
	var p := UITheme.panel(Color(0.05, 0.06, 0.09, 0.6), 3)
	p.position = pos
	p.set_meta("title_col", col)
	_root.add_child(p)
	var v := VBoxContainer.new()
	p.add_child(v)
	var title := UITheme.label("红方 RED" if col.r > col.b else "蓝方 BLUE", 12, col, true)
	v.add_child(title)
	return v

# ================= 布局 =================
func _layout() -> void:
	var vs := _root.size
	if vs.x < 10:
		return
	_timer_label.position = Vector2(vs.x - _timer_label.size.x - 24, 18)
	_feed_box.position = Vector2(vs.x - _feed_box.size.x - 24, 56)
	_hp_panel.position = Vector2(24, vs.y - _hp_panel.size.y - 24)
	_ammo_panel.position = Vector2(vs.x - _ammo_panel.size.x - 24, vs.y - _ammo_panel.size.y - 24)
	_interact_hint.position = Vector2(vs.x / 2.0 - _interact_hint.size.x / 2.0, vs.y * 0.62)
	_banner.position = Vector2(vs.x / 2.0 - _banner.size.x / 2.0, vs.y * 0.3)
	_death_dv.position = Vector2(vs.x / 2.0 - _death_dv.size.x / 2.0, vs.y / 2.0 - _death_dv.size.y / 2.0)

# ================= 更新 =================
func _process(delta: float) -> void:
	_layout()
	# 准心动态扩散
	_spread_px = lerpf(_spread_px, 0.0, delta * 5.0)
	_hitmarker_t = maxf(_hitmarker_t - delta * 4.0, 0.0)
	_cross.queue_redraw()
	# 受击指示衰减
	for m in _damage_marks.duplicate():
		m.t -= delta
		if m.t <= 0.0:
			_damage_marks.erase(m)
	_cross.queue_redraw()
	# 低血量
	var hp_frac := 1.0
	if G.player and is_instance_valid(G.player):
		hp_frac = (G.player as Player).hp / (G.player as Player).max_hp
	if hp_frac < 0.35:
		_vignette.color = Color(0.5, 0.05, 0.05, (0.35 - hp_frac) * 1.6)
		_heart_t -= delta
		if _heart_t <= 0.0:
			_heart_t = 1.1
			Snd.play("heartbeat", -12)
	else:
		_vignette.color = Color(0.5, 0.05, 0.05, 0.0)
	# 狙击镜
	var w: Weapon = null
	if G.player and is_instance_valid(G.player):
		w = (G.player as Player).current_weapon()
	if w and bool(w.data.get("scope", false)) and w.ads_amount > 0.85:
		_scope_overlay.visible = true
		_scope_overlay.modulate = Color(1, 1, 1, (w.ads_amount - 0.85) / 0.15)
	else:
		_scope_overlay.visible = false

# ================= 事件接口 =================
func update_health(frac: float) -> void:
	_health_label.text = str(int(round(frac * (G.player as Player).max_hp)))
	_health_fill.size = Vector2(220 * clampf(frac, 0.0, 1.0), 6)
	_health_fill.color = UITheme.ACCENT if frac > 0.4 else Color(1.0, 0.55, 0.2)

func update_ammo() -> void:
	if G.player and is_instance_valid(G.player):
		var w := (G.player as Player).current_weapon()
		if w:
			_ammo_label.text = w.ammo_text()
			_weapon_label.text = str(w.data.name)

func on_player_shot() -> void:
	_spread_px = 7.0
	update_ammo()

func hitmarker(head: bool) -> void:
	_hitmarker_t = 1.0
	_hitmarker_head = head
	Snd.play("headshot" if head else "hitmarker", -6)

func kill_feed(killer: String, victim: String, k_col := Color.WHITE, v_col := Color.WHITE) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	var kl := UITheme.label(killer, 14, k_col, true)
	row.add_child(kl)
	row.add_child(UITheme.label("▸", 14, Color(1, 1, 1, 0.5)))
	var vl := UITheme.label(victim, 14, v_col)
	row.add_child(vl)
	_feed_box.add_child(row)
	var tw := create_tween()
	tw.tween_interval(4.0)
	tw.tween_property(row, "modulate", Color(1, 1, 1, 0), 0.5)
	tw.tween_callback(row.queue_free)

func set_scores(red: Array, blue: Array, red_k: int, blue_k: int) -> void:
	# 更新队伍面板与击杀数
	if G.player and is_instance_valid(G.player):
		_kill_count.text = "击杀 %d" % (G.player as Player).kills
	_update_panel(_red_panel, red, red_k)
	_update_panel(_blue_panel, blue, blue_k)

func _update_panel(panel: VBoxContainer, players: Array, team_kills: int) -> void:
	if panel == null:
		return
	for c in panel.get_children():
		c.queue_free()
	var title: Color = panel.get_meta("title_col", Color.WHITE)
	panel.add_child(UITheme.label("队伍击杀 %d" % team_kills, 12, title, true))
	for p in players:
		var row := UITheme.label("  %s   %d 杀 / %d 亡" % [str(p.name), int(p.kills), int(p.deaths)], 12)
		panel.add_child(row)

func set_timer(t: float) -> void:
	var m := int(t) / 60
	var sec := int(t) % 60
	_timer_label.text = "%02d:%02d" % [m, sec]

func damage_from(from_pos: Vector3) -> void:
	if G.player == null:
		return
	var p := G.player as Player
	var to := from_pos - p.global_position
	var angle := atan2(to.x, to.z) - p.rotation.y
	_damage_marks.append({"angle": angle, "t": 1.2})

func show_killed_banner(name_txt: String) -> void:
	_banner.text = "你 击 杀 了  %s" % name_txt
	_banner.visible = true
	var tw := create_tween()
	tw.tween_interval(1.6)
	tw.tween_property(_banner, "modulate", Color(1, 1, 1, 0), 0.4)
	tw.tween_callback(func():
		_banner.visible = false
		_banner.modulate = Color(1, 1, 1, 1))

func show_death(killer: String) -> void:
	_death_label.text = "你被 %s 击杀了" % killer
	_death_overlay.visible = true
	_death_timer.text = "3.0 秒后重生"
	update_respawn_countdown(3.0)

func update_respawn_countdown(t: float) -> void:
	if _death_overlay.visible:
		_death_timer.text = "%.1f 秒后重生" % t

func hide_death() -> void:
	_death_overlay.visible = false

func set_interact_hint(txt: String) -> void:
	_interact_hint.text = txt

func refresh_hud_scale() -> void:
	var s: Dictionary = G.settings.controls
	_root.scale = Vector2(float(s.hud_scale), float(s.hud_scale))
	_root.modulate = Color(1, 1, 1, clampf(float(s.hud_opacity), 0.15, 1.0))

func touch_setup_gyro() -> void:
	if touch:
		touch.setup_gyro()

# ================= 子控件 =================
class CrosshairControl:
	extends Control
	func _draw() -> void:
		var hud := get_parent_hud()
		if hud == null:
			return
		var w: Weapon = null
		var ads := 0.0
		if G.player and is_instance_valid(G.player):
			w = (G.player as Player).current_weapon()
			ads = w.ads_amount if w else 0.0
		var ch: Dictionary = G.settings.crosshair
		if bool(ch.hide_ads) and ads > 0.5:
			if not (w and bool(w.data.get("scope", false))):
				return
		if w and bool(w.data.get("scope", false)) and ads > 0.5:
			return
		var center := size / 2.0
		CrosshairDraw.draw_crosshair(self, center, ch, hud._spread_px)

	func get_parent_hud() -> GameHUD:
		var p := get_parent()
		while p != null:
			if p is GameHUD:
				return p as GameHUD
			p = p.get_parent()
		return null

class ScopeOverlay:
	extends Control
	func _draw() -> void:
		var center := size / 2.0
		var r := minf(size.x, size.y) * 0.42
		var black := Color(0, 0, 0, 0.97)
		# 上下左右四块黑
		draw_rect(Rect2(0, 0, size.x, center.y - r), black)
		draw_rect(Rect2(0, center.y + r, size.x, size.y - center.y - r), black)
		draw_rect(Rect2(0, center.y - r, center.x - r, r * 2), black)
		draw_rect(Rect2(center.x + r, center.y - r, size.x - center.x - r, r * 2), black)
		# 圆环
		draw_arc(center, r, 0, TAU, 64, Color(0, 0, 0, 1.0), 6.0)
		# 十字线
		draw_line(Vector2(center.x - r, center.y), Vector2(center.x + r, center.y), Color(0, 0, 0, 0.8), 2.0)
		draw_line(Vector2(center.x, center.y - r), Vector2(center.x, center.y + r), Color(0, 0, 0, 0.8), 2.0)
		# 刻度
		for i in range(-4, 5):
			draw_line(Vector2(center.x - 6, center.y + i * r / 5.0), Vector2(center.x + 6, center.y + i * r / 5.0), Color(0, 0, 0, 0.6), 1.0)
