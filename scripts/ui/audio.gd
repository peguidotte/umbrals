class_name UmbralAudio
extends Node
var voices: Array[AudioStreamPlayer] = []
var ui_voice: AudioStreamPlayer
var music: AudioStreamPlayer
var pulse: AudioStreamPlayer
var voice_index: int = 0
var music_gain: float = 0.55
var duck_tween: Tween
var shutting_down: bool = false

func _exit_tree() -> void:
	shutdown()

func shutdown() -> void:
	shutting_down = true
	if is_instance_valid(duck_tween): duck_tween.kill()
	# Release loop playback before the audio server shuts down, including headless runs.
	for player in voices + [ui_voice, music, pulse]:
		if is_instance_valid(player):
			player.stop()
			player.stream = null

func _ready() -> void:
	for name in ["Music", "SFX", "UI"]:
		if AudioServer.get_bus_index(name) < 0:
			AudioServer.add_bus()
			var index: int = AudioServer.bus_count - 1
			AudioServer.set_bus_name(index, name)
			AudioServer.set_bus_send(index, "Master")
	AudioServer.set_bus_volume_db(0, -2)
	for i in range(4):
		var player = AudioStreamPlayer.new()
		player.bus = "SFX"
		player.volume_db = -4
		add_child(player)
		voices.append(player)
	ui_voice = AudioStreamPlayer.new()
	ui_voice.bus = "UI"
	ui_voice.volume_db = -8
	add_child(ui_voice)
	music = _loop("ambience", -13)
	pulse = _loop("boss_pulse", -40)

func _loop(name: String, volume: float) -> AudioStreamPlayer:
	var player = AudioStreamPlayer.new()
	player.bus = "Music"
	player.volume_db = volume
	var stream: AudioStreamWAV = load("res://assets/%s.wav" % name)
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_end = int(stream.data.size() / 2)
	player.stream = stream
	add_child(player)
	player.play()
	return player

func apply(values: Dictionary) -> void:
	if is_instance_valid(duck_tween): duck_tween.kill()
	music_gain = float(values.music)
	_gain("Music", music_gain)
	_gain("SFX", float(values.sfx))
	_gain("UI", float(values.sfx))

func _gain(bus: String, value: float) -> void:
	var index: int = AudioServer.get_bus_index(bus)
	AudioServer.set_bus_mute(index, value == 0)
	AudioServer.set_bus_volume_db(index, linear_to_db(maxf(0.0001, value)))

func play(name: String, small: bool = false) -> void:
	if shutting_down: return
	var player: AudioStreamPlayer = ui_voice if small else voices[voice_index % voices.size()]
	voice_index += 1
	player.pitch_scale = [0.98, 1.0, 1.025, 1.01][voice_index % 4]
	player.stream = load("res://assets/%s.wav" % name)
	player.play()

func set_boss(active: bool) -> void:
	create_tween().tween_property(pulse, "volume_db", -19.0 if active else -40.0, 0.55)

func duck() -> void:
	var index: int = AudioServer.get_bus_index("Music")
	var base: float = linear_to_db(maxf(0.0001, music_gain))
	if is_instance_valid(duck_tween): duck_tween.kill()
	duck_tween = create_tween()
	duck_tween.tween_method(func(value: float): AudioServer.set_bus_volume_db(index, value), base, base - 4, 0.06)
	duck_tween.tween_method(func(value: float): AudioServer.set_bus_volume_db(index, value), base - 4, base, 0.28)
