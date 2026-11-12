extends Node
## Pixpfs 主入口 - 场景流：开场动画 → 大厅 → 训练场/对战

var lobby: Node3D = null
var game_scene: Node = null
var intro: CanvasLayer = null

func _ready() -> void:
	G.state = "boot"
	get_window().title = "Pixpfs"
	_show_intro()

func _show_intro() -> void:
	if G.smoke:
		goto_lobby()
		_run_smoke_tour()
		return
	intro = IntroScreen.new()
	add_child(intro)
	intro.finished.connect(goto_lobby)

func _capture(name_txt: String) -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	var img := get_viewport().get_texture().get_image()
	var path := "%s/%s.png" % [G.shot_dir, name_txt]
	img.save_png(path)
	print("[SMOKE] captured ", path)

func _wait(t: float) -> void:
	await get_tree().create_timer(t, true, false, true).timeout

func _run_smoke_tour() -> void:
	print("[SMOKE] lobby")
	await _wait(0.6)
	if G.smoke and G.shot_dir != "":
		await _capture("lobby")
	if lobby:
		var arm := ArmoryScreen.new()
		add_child(arm)
		await _wait(0.3)
		arm.queue_free()
		await _wait(0.1)
		var cs := CharacterScreen.new()
		add_child(cs)
		await _wait(0.3)
		cs.queue_free()
		await _wait(0.1)
		var st := SettingsScreen.new()
		add_child(st)
		await _wait(0.3)
		st.queue_free()
		await _wait(0.1)
		var dev := DevScreen.new()
		add_child(dev)
		await _wait(0.2)
		dev.queue_free()
		await _wait(0.1)
	print("[SMOKE] training")
	start_training()
	await _wait(1.2)
	if G.smoke and G.shot_dir != "":
		await _capture("training")
	Input.action_press("fire")
	await _wait(0.5)
	Input.action_release("fire")
	Input.action_press("jump")
	await _wait(0.15)
	Input.action_release("jump")
	await _wait(0.5)
	print("[SMOKE] match")
	start_match()
	await _wait(1.5)
	if G.smoke and G.shot_dir != "":
		await _capture("match")
	Input.action_press("sprint")
	Input.action_press("move_forward")
	await _wait(0.6)
	Input.action_press("jump")
	await _wait(0.15)
	Input.action_release("jump")
	Input.action_press("crouch")
	await _wait(0.5)
	Input.action_release("crouch")
	Input.action_press("fire")
	await _wait(0.8)
	Input.action_release("fire")
	Input.action_press("reload")
	await _wait(0.1)
	Input.action_release("reload")
	Input.action_press("inspect")
	await _wait(0.3)
	Input.action_release("inspect")
	await _wait(1.5)
	print("[SMOKE] back to lobby")
	Input.action_release("sprint")
	Input.action_release("move_forward")
	goto_lobby()
	await _wait(0.5)
	print("[SMOKE] ALL OK")
	get_tree().quit(0)

func goto_lobby() -> void:
	if intro != null and is_instance_valid(intro):
		intro.queue_free()
		intro = null
	_clear_game()
	_clear_lobby()
	lobby = Lobby.new()
	add_child(lobby)
	G.state = "lobby"
	G.player = null
	G.hud = null

func start_training() -> void:
	_clear_lobby()
	_clear_game()
	var t := Training.new()
	add_child(t)
	game_scene = t
	G.state = "training"

func start_match() -> void:
	_clear_lobby()
	_clear_game()
	var m := Match.new()
	m.map_id = G.current_map
	add_child(m)
	game_scene = m
	G.state = "match"

func back_to_lobby() -> void:
	goto_lobby()

func _clear_lobby() -> void:
	if lobby != null and is_instance_valid(lobby):
		lobby.queue_free()
	lobby = null

func _clear_game() -> void:
	if game_scene != null and is_instance_valid(game_scene):
		game_scene.queue_free()
	game_scene = null
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
