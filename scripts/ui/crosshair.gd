class_name CrosshairDraw
extends RefCounted
## 准心绘制（HUD 与设置预览共用）

static func col(s: Dictionary) -> Color:
	var c: Array = s.get("color", [1.0, 0.28, 0.36, 1.0])
	if c.size() >= 4:
		return Color(float(c[0]), float(c[1]), float(c[2]), float(c[3]))
	return Color(1, 0.28, 0.36, 1)

static func draw_crosshair(c: Control, center: Vector2, s: Dictionary, spread_px := 0.0) -> void:
	var color := col(s)
	var length := float(s.get("length", 9))
	var thick := int(s.get("thickness", 2))
	var gap := float(s.get("gap", 5))
	var style := str(s.get("style", "cross"))
	var outline := bool(s.get("outline", true))
	gap += spread_px
	if style == "dot" and not bool(s.get("dot", false)):
		style = "cross"
	if style != "dot":
		var rects: Array = []
		# 上/下/左/右 四条臂
		rects.append(Rect2(center.x - thick / 2.0, center.y - gap - length, thick, length))
		rects.append(Rect2(center.x - thick / 2.0, center.y + gap, thick, length))
		rects.append(Rect2(center.x - gap - length, center.y - thick / 2.0, length, thick))
		rects.append(Rect2(center.x + gap, center.y - thick / 2.0, length, thick))
		for r in rects:
			if outline:
				c.draw_rect(r.grow(1.0), Color(0, 0, 0, 0.8))
			c.draw_rect(r, color)
	if style == "dot" or bool(s.get("dot", false)):
		var d := Rect2(center.x - thick, center.y - thick, thick * 2.0, thick * 2.0)
		if outline:
			c.draw_rect(d.grow(1.0), Color(0, 0, 0, 0.8))
		c.draw_rect(d, color)
