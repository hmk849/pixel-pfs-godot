class_name Match
extends Node3D
## Pixpfs 2v2 对战管理器：你 + 队友 vs 两名红方 Bot

var map_id := "rust"
var player: Player
var hud: GameHUD
var bots: Array = []
var time_left := 300.0
var score_limit := 20
var red_kills := 0
var blue_kills := 0
var match_over := false
var _respawn_t := 0.0
var _score_t := 0.5
var _pause_menu: CanvasLayer = null
var map_data := {}

const BOT_NAMES_RED := ["红方-阿尔法", "红方-贝塔"]
const BOT_NAME_BLUE := "蓝方-队友"

func _ready() -> void:
	FX.setup(self)
	map_data = MapBuilder.build(self, map_id)
	Snd.play_music("music_match")
	_spawn_everything()
	Snd.play("match_start")

func _spawn_everything() -> void:
	player = Player.new()
	player.display_name = "你"
	player.team = "blue"
	add_child(player)
	var spawns: Array = map_data.spawns_blue
	player.global_position = spawns[0] as Vector3

	hud = GameHUD.new()
	hud.mode = "match"
	add_child(hud)
	hud.update_ammo()
	hud.update_health(1.0)
	hud.set_timer(time_left)

	# 蓝方队友
	_spawn_bot("blue", BOT_NAME_BLUE, 1.0)
	# 红方敌人
	for n in BOT_NAMES_RED:
		_spawn_bot("red", n, 1.0)

func _spawn_bot(team: String, bot_name: String, diff: float) -> void:
	var b := Bot.new()
	b.team = team
	b.display_name = bot_name
	var op := OperatorDB.by_id(["owl", "viper", "ghost", "bear", "kestrel"][bots.size() % 5])
	var wpn := WeaponDB.by_id(["vk77", "mx9", "px4"][bots.size() % 3])
	var wps: Array = map_data.waypoints.duplicate()
	if team == "blue":
		wps.append_array(map_data.spawns_blue as Array)
	else:
		wps.append_array(map_data.spawns_red as Array)
	b.setup(team, bot_name, op, wpn, wps, diff)
	add_child(b)
	var sp: Array = map_data.spawns_red if team == "red" else map_data.spawns_blue
	b.global_position = (sp[bots.size() % sp.size()] as Vector3)
	bots.append(b)

func open_pause_menu() -> void:
	if match_over:
		return
	if _pause_menu != null and is_instance_valid(_pause_menu):
		return
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_pause_menu = PauseMenu.new()
	_pause_menu.set_meta("scene", "match")
	add_child(_pause_menu)
	_pause_menu.closed.connect(func():
		if is_instance_valid(_pause_menu):
			_pause_menu.queue_free()
		_pause_menu = null
		if not match_over:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()
		open_pause_menu()

func _process(delta: float) -> void:
	if match_over:
		return
	# 计时
	time_left -= delta
	if time_left <= 0.0:
		time_left = 0.0
		_end_match(blue_kills >= red_kills)
	hud.set_timer(time_left)

	# 玩家重生
	if not player.alive:
		_respawn_t -= delta
		hud.update_respawn_countdown(_respawn_t)
		if _respawn_t <= 0.0:
			var sp: Array = map_data.spawns_blue
			player.respawn(sp[randi() % sp.size()] as Vector3)

	# 面板（节流）
	_score_t -= delta
	if _score_t <= 0.0:
		_score_t = 0.5
		_update_scores()

func _update_scores() -> void:
	var red: Array = []
	var blue: Array = [{"name": player.display_name, "kills": player.kills, "deaths": player.deaths}]
	for b in bots:
		var entry := {"name": b.display_name, "kills": b.kills, "deaths": b.deaths}
		if b.team == "red":
			red.append(entry)
		else:
			blue.append(entry)
	hud.set_scores(red, blue, red_kills, blue_kills)

func on_bot_killed(bot: Bot, killer_name: String, team: String) -> void:
	if match_over:
		return
	if team == "red":
		blue_kills += 1
		hud.kill_feed(killer_name, bot.display_name, Color(0.45, 0.7, 1.0), Color(1, 0.45, 0.45))
	else:
		red_kills += 1
		hud.kill_feed(killer_name, bot.display_name, Color(1, 0.45, 0.45), Color(0.45, 0.7, 1.0))
	if killer_name == player.display_name:
		hud.show_killed_banner(bot.display_name)
		Snd.play("kill")
	if blue_kills >= score_limit:
		_end_match(true)
	elif red_kills >= score_limit:
		_end_match(false)

func _end_match(win: bool) -> void:
	match_over = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	Snd.play("victory" if win else "defeat")
	Snd.stop_music()
	var screen := MatchEndScreen.new()
	screen.win = win
	screen.stats = _collect_stats()
	add_child(screen)
	screen.closed.connect(func(): get_node("/root/Main").call("goto_lobby"))

func _collect_stats() -> Dictionary:
	var acc := 0.0
	if player.shots_fired > 0:
		acc = float(player.shots_hit) / float(player.shots_fired) * 100.0
	return {
		"kills": player.kills, "deaths": player.deaths,
		"acc": acc, "red": red_kills, "blue": blue_kills,
	}

func _exit_tree() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
