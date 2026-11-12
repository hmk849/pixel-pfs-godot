class_name MatchEndScreen
extends CanvasLayer
## 对战结算画面

signal closed
var win := true
var stats := {}

func _ready() -> void:
	layer = 80
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(root)
	UITheme.dim(root, 0.82)

	var wrap := UITheme.center_wrap(root)
	var main := UITheme.overlay_panel(Color(0.07, 0.08, 0.11, 0.95))
	main.custom_minimum_size = Vector2(520, 420)
	wrap.add_child(main)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	main.add_child(v)

	var title := UITheme.label("胜 利" if win else "失 败", 44,
		Color(0.2, 0.9, 0.55) if win else Color(1, 0.35, 0.4), true)
	v.add_child(title)
	v.add_child(UITheme.label("VICTORY" if win else "DEFEAT", 13, UITheme.TEXT_DIM))
	v.add_child(UITheme.sep())

	var score := UITheme.label("蓝方 %d  :  %d 红方" % [int(stats.get("blue", 0)), int(stats.get("red", 0))], 22, UITheme.TEXT, true)
	v.add_child(score)
	v.add_child(UITheme.sep())

	for row in [
		["击杀", "%d" % int(stats.get("kills", 0))],
		["死亡", "%d" % int(stats.get("deaths", 0))],
		["K/D", "%.2f" % (float(stats.get("kills", 0)) / maxf(float(stats.get("deaths", 0)), 1.0))],
		["命中率", "%.1f%%" % float(stats.get("acc", 0.0))],
	]:
		var r := HBoxContainer.new()
		r.add_theme_constant_override("separation", 20)
		var l := UITheme.label(str(row[0]), 16, UITheme.TEXT_DIM)
		l.custom_minimum_size = Vector2(120, 0)
		r.add_child(l)
		r.add_child(UITheme.label(str(row[1]), 18, UITheme.TEXT, true))
		v.add_child(r)

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(spacer)

	var back_btn := UITheme.button("返 回 大 厅", 20)
	back_btn.custom_minimum_size = Vector2(240, 52)
	back_btn.pressed.connect(func():
		closed.emit()
		queue_free())
	v.add_child(back_btn)
