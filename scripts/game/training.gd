class_name Training
extends Node3D
## Pixpfs 训练场：靶道 + 机动训练 + Bot 竞技区 + 武器试验台

var player: Player
var hud: GameHUD
var bots: Array = []
var map_data := {}
var _pause_menu: CanvasLayer = null
var _armory_open := false

const BOT_COUNT := 3

func _ready() -> void:
	FX.setup(self)
	map_data = MapBuilder.build(self, "training")
	Snd.play_music("music_lobby")

	player = Player.new()
	player.display_name = "你"
	player.team = "blue"
	add_child(player)
	var sp: Array = map_data.spawns_blue
	player.global_position = sp[0] as Vector3

	hud = GameHUD.new()
	hud.mode = "training"
	add_child(hud)
	hud.update_ammo()
	hud.update_health(1.0)
	hud.set_interact_hint("")

	_spawn_bots(BOT_COUNT)

func _spawn_bots(count: int) -> void:
	for b in bots:
		b.queue_free()
	bots.clear()
	var wps: Array = map_data.waypoints
	for i in count:
		var b := Bot.new()
		var op := OperatorDB.by_id(["viper", "ghost", "bear", "kestrel", "owl"][i % 5])
		var wpn := WeaponDB.by_id(["mx9", "vk77", "spectre", "ar9"][i % 4])
		b.setup("red", "训练Bot-%d" % (i + 1), op, wpn, wps, 0.9)
		add_child(b)
		var wp := wps[randi() % wps.size()] as Vector3
		b.global_position = wp + Vector3(0, 0.5, 0)
		bots.append(b)

func open_pause_menu() -> void:
	if _pause_menu != null and is_instance_valid(_pause_menu):
		return
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_pause_menu = PauseMenu.new()
	_pause_menu.set_meta("scene", "training")
	add_child(_pause_menu)
	_pause_menu.closed.connect(func():
		if is_instance_valid(_pause_menu):
			_pause_menu.queue_free()
		_pause_menu = null
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()
		open_pause_menu()

func _process(_delta: float) -> void:
	# 武器试验台互动
	if player and is_instance_valid(player) and player.alive:
		var bench_pos: Vector3 = map_data.interact_points.get("armory", Vector3.ZERO)
		if player.global_position.distance_to(bench_pos) < 3.5:
			hud.set_interact_hint("按 [E] 打开武器试验台")
			if G.act_just("interact") and not _armory_open:
				_open_armory()
		else:
			hud.set_interact_hint("")

func _open_armory() -> void:
	_armory_open = true
	var arm := ArmoryScreen.new()
	add_child(arm)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	arm.closed.connect(func():
		_armory_open = false
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		_apply_loadout())

## 应用新装备到玩家（重建武器）
func _apply_loadout() -> void:
	if player and is_instance_valid(player):
		player.call("_rebuild_weapons")

func _exit_tree() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
