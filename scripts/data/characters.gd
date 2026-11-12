class_name OperatorDB
extends RefCounted
## Pixpfs 干员（特种兵）数据库 - 五位干员

const OPERATORS := [
	{
		"id": "ghost", "name": "幽灵", "en": "GHOST", "role": "突击手",
		"perk": "移动速度 +6%", "perk_type": "speed", "perk_val": 1.06,
		"color": Color(0.55, 0.75, 0.62), "visor": Color(0.12, 0.86, 0.94),
		"desc": "前三角洲队员，静默渗透专家。",
	},
	{
		"id": "viper", "name": "毒蛇", "en": "VIPER", "role": "侦察兵",
		"perk": "滑铲速度 +12%", "perk_type": "slide", "perk_val": 1.12,
		"color": Color(0.45, 0.7, 0.35), "visor": Color(0.47, 1.0, 0.31),
		"desc": "丛林侦察兵，擅长高速位移作战。",
	},
	{
		"id": "owl", "name": "夜枭", "en": "OWL", "role": "狙击手",
		"perk": "开镜速度 +18%", "perk_type": "ads", "perk_val": 1.18,
		"color": Color(0.45, 0.5, 0.72), "visor": Color(0.78, 0.47, 1.0),
		"desc": "夜间行动专家，千米之外取敌首级。",
	},
	{
		"id": "bear", "name": "狂熊", "en": "BEAR", "role": "重装",
		"perk": "生命上限 120", "perk_type": "hp", "perk_val": 120.0,
		"color": Color(0.62, 0.5, 0.36), "visor": Color(1.0, 0.67, 0.16),
		"desc": "极地重装兵，硬得像一堵墙。",
	},
	{
		"id": "kestrel", "name": "红隼", "en": "KESTREL", "role": "医疗",
		"perk": "生命恢复 +25%", "perk_type": "regen", "perk_val": 1.25,
		"color": Color(0.7, 0.4, 0.42), "visor": Color(1.0, 0.35, 0.39),
		"desc": "战地医师，永远在线的支援。",
	},
]

static func get_all() -> Array:
	return OPERATORS

static func by_id(id: String) -> Dictionary:
	for o in OPERATORS:
		if o.id == id:
			return o
	return OPERATORS[0]
