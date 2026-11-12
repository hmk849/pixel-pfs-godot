class_name WeaponDB
extends RefCounted
## Pixpfs 武器数据库 - 所有武器数据驱动

const WEAPONS := [
	# ===== 步枪 =====
	{
		"id": "px4", "name": "PX-4 猎鹰", "cat": "rifle", "cat_name": "步枪",
		"dmg": 30, "rpm": 640, "mag": 30, "reserve": 120, "reload": 2.1,
		"spread": 1.6, "ads_spread": 0.22, "range": 38.0, "falloff": 0.55,
		"auto": true, "ads_fov": 55.0, "ads_time": 0.24, "hs_mult": 1.6,
		"recoil": 0.55, "sound": "shot_rifle", "mobility": 1.0,
		"desc": "均衡可靠的突击步枪，中距离之王。",
	},
	{
		"id": "vk77", "name": "VK-77 科莫多", "cat": "rifle", "cat_name": "步枪",
		"dmg": 41, "rpm": 420, "mag": 25, "reserve": 100, "reload": 2.5,
		"spread": 2.0, "ads_spread": 0.3, "range": 45.0, "falloff": 0.6,
		"auto": true, "ads_fov": 52.0, "ads_time": 0.3, "hs_mult": 1.7,
		"recoil": 0.95, "sound": "shot_rifle", "mobility": 0.92,
		"desc": "重型战斗步枪，高伤害，后坐力较大。",
	},
	{
		"id": "ar9", "name": "AR-9 疾风", "cat": "rifle", "cat_name": "步枪",
		"dmg": 26, "rpm": 780, "mag": 35, "reserve": 140, "reload": 2.3,
		"spread": 1.8, "ads_spread": 0.28, "range": 32.0, "falloff": 0.5,
		"auto": true, "ads_fov": 58.0, "ads_time": 0.2, "hs_mult": 1.5,
		"recoil": 0.42, "sound": "shot_rifle", "mobility": 1.05,
		"desc": "高射速突击步枪，近距离压制利器。",
	},
	# ===== 冲锋枪 =====
	{
		"id": "mx9", "name": "MX-9 黄蜂", "cat": "smg", "cat_name": "冲锋枪",
		"dmg": 22, "rpm": 950, "mag": 32, "reserve": 160, "reload": 1.9,
		"spread": 2.4, "ads_spread": 0.5, "range": 24.0, "falloff": 0.45,
		"auto": true, "ads_fov": 62.0, "ads_time": 0.17, "hs_mult": 1.45,
		"recoil": 0.34, "sound": "shot_smg", "mobility": 1.12,
		"desc": "极速射速的冲锋枪，贴脸绞肉机。",
	},
	{
		"id": "spectre", "name": "迅影", "cat": "smg", "cat_name": "冲锋枪",
		"dmg": 26, "rpm": 800, "mag": 28, "reserve": 140, "reload": 2.0,
		"spread": 2.0, "ads_spread": 0.4, "range": 27.0, "falloff": 0.5,
		"auto": true, "ads_fov": 60.0, "ads_time": 0.18, "hs_mult": 1.5,
		"recoil": 0.4, "sound": "shot_smg", "mobility": 1.08,
		"desc": "精准型冲锋枪，机动与火力的平衡。",
	},
	# ===== 狙击枪 =====
	{
		"id": "lr50", "name": "LR-50 长风", "cat": "sniper", "cat_name": "狙击枪",
		"dmg": 98, "rpm": 42, "mag": 5, "reserve": 25, "reload": 3.2,
		"spread": 4.0, "ads_spread": 0.02, "range": 200.0, "falloff": 1.0,
		"auto": false, "ads_fov": 26.0, "ads_time": 0.42, "hs_mult": 2.5,
		"recoil": 2.2, "sound": "shot_sniper", "mobility": 0.8, "scope": true,
		"desc": "栓动重型狙击枪，胸线一枪致命。",
	},
	{
		"id": "sr90", "name": "SR-90 猎鹰眼", "cat": "sniper", "cat_name": "狙击枪",
		"dmg": 68, "rpm": 75, "mag": 8, "reserve": 32, "reload": 2.8,
		"spread": 3.0, "ads_spread": 0.08, "range": 120.0, "falloff": 0.9,
		"auto": false, "ads_fov": 32.0, "ads_time": 0.34, "hs_mult": 2.2,
		"recoil": 1.5, "sound": "shot_sniper", "mobility": 0.85, "scope": true,
		"desc": "半自动狙击枪，两枪带走，容错更高。",
	},
	# ===== 霰弹枪 =====
	{
		"id": "sg8", "name": "SG-8 破碎者", "cat": "shotgun", "cat_name": "霰弹枪",
		"dmg": 13, "pellets": 8, "rpm": 68, "mag": 6, "reserve": 30, "reload": 3.0,
		"spread": 5.5, "ads_spread": 4.0, "range": 12.0, "falloff": 0.25,
		"auto": false, "ads_fov": 66.0, "ads_time": 0.26, "hs_mult": 1.3,
		"recoil": 1.8, "sound": "shot_shotgun", "mobility": 0.95,
		"desc": "泵动式霰弹枪，八弹丸，近身即死。",
	},
	{
		"id": "m12", "name": "M12 双管猎手", "cat": "shotgun", "cat_name": "霰弹枪",
		"dmg": 11, "pellets": 9, "rpm": 190, "mag": 2, "reserve": 24, "reload": 1.7,
		"spread": 7.0, "ads_spread": 5.5, "range": 10.0, "falloff": 0.2,
		"auto": false, "ads_fov": 68.0, "ads_time": 0.2, "hs_mult": 1.2,
		"recoil": 1.4, "sound": "shot_shotgun", "mobility": 1.06,
		"desc": "双管霰弹枪，两连喷，换弹极快。",
	},
	# ===== 手枪（副武器） =====
	{
		"id": "p11", "name": "P-11 隼爪", "cat": "pistol", "cat_name": "手枪",
		"dmg": 25, "rpm": 380, "mag": 12, "reserve": 60, "reload": 1.5,
		"spread": 2.0, "ads_spread": 0.35, "range": 22.0, "falloff": 0.5,
		"auto": false, "ads_fov": 60.0, "ads_time": 0.15, "hs_mult": 1.6,
		"recoil": 0.5, "sound": "shot_pistol", "mobility": 1.2,
		"desc": "默认副武器，半自动手枪。",
	},
]

const CATS := [
	{"id": "rifle", "name": "步枪", "icon": "🔫"},
	{"id": "smg", "name": "冲锋枪", "icon": "🔫"},
	{"id": "sniper", "name": "狙击枪", "icon": "🎯"},
	{"id": "shotgun", "name": "霰弹枪", "icon": "💥"},
	{"id": "pistol", "name": "手枪", "icon": "🔫"},
]

static func get_all() -> Array:
	return WEAPONS

static func by_id(id: String) -> Dictionary:
	for w in WEAPONS:
		if w.id == id:
			return w
	return WEAPONS[0]

static func by_cat(cat: String) -> Array:
	var res: Array = []
	for w in WEAPONS:
		if w.cat == cat:
			res.append(w)
	return res

static func fire_interval_ms(w: Dictionary) -> float:
	return 60.0 / float(w.rpm)
