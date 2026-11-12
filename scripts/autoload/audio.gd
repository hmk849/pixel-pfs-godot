extends Node
## Pixpfs 音频管理器（autoload: Snd）- 池化播放器 + 音乐循环

const SFX_DIR := "res://assets/sounds/"

var streams := {}
var music_player: AudioStreamPlayer
var sfx_pool: Array = []
var music_name := ""

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var dir := DirAccess.open(SFX_DIR)
	if dir:
		dir.list_dir_begin()
		var fname := dir.get_next()
		while fname != "":
			if fname.ends_with(".wav") or fname.ends_with(".ogg"):
				var path := SFX_DIR + fname
				var s := load(path)
				if s is AudioStreamWAV:
					s.loop_mode = AudioStreamWAV.LOOP_DISABLED
				streams[fname.get_basename()] = s
			fname = dir.get_next()
		dir.list_dir_end()
	music_player = AudioStreamPlayer.new()
	music_player.bus = "Master"
	add_child(music_player)
	for i in 14:
		var p := AudioStreamPlayer.new()
		add_child(p)
		sfx_pool.append(p)

func play(name: String, vol_db := 0.0, pitch := 1.0) -> void:
	if not streams.has(name):
		return
	for p in sfx_pool:
		if not p.playing:
			p.stream = streams[name]
			p.volume_db = vol_db + linear_to_db(clampf(float(G.settings.audio.sfx), 0.0, 1.0))
			p.pitch_scale = pitch
			p.play()
			return
	# 全忙则复用第一个
	sfx_pool[0].stream = streams[name]
	sfx_pool[0].volume_db = vol_db + linear_to_db(clampf(float(G.settings.audio.sfx), 0.0, 1.0))
	sfx_pool[0].pitch_scale = pitch
	sfx_pool[0].play()

func play_music(name: String) -> void:
	if music_name == name and music_player.playing:
		return
	if not streams.has(name):
		return
	music_name = name
	var s: AudioStream = streams[name]
	if s is AudioStreamWAV:
		s.loop_mode = AudioStreamWAV.LOOP_FORWARD
		s.loop_end = int(s.data.size() / 2.0)
	music_player.stream = s
	music_player.volume_db = linear_to_db(clampf(float(G.settings.audio.music), 0.0, 1.0))
	music_player.play()

func stop_music() -> void:
	music_player.stop()
	music_name = ""

func refresh_volumes() -> void:
	music_player.volume_db = linear_to_db(clampf(float(G.settings.audio.music), 0.0, 1.0))
