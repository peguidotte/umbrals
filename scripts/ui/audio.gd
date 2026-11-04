class_name UmbralAudio
extends Node
const Assets = preload("res://scripts/assets/catalog.gd")
var voices: Array[AudioStreamPlayer] = []
var ui_voice: AudioStreamPlayer
var music: AudioStreamPlayer
var pulse: AudioStreamPlayer
var voice_index: int = 0
var music_gain: float = 0.55
var duck_tween: Tween
var shutting_down: bool = false
var title_water: AudioStreamPlayer
var crystal_voice: AudioStreamPlayer
var magic_voice: AudioStreamPlayer
var crystal_tick: AudioStreamWAV
var crystal_confirm: AudioStreamWAV
var magic_chord: AudioStreamWAV
var title_active: bool = false
var title_tween: Tween
var last_navigation_ms: int = -1000
var navigation_count: int = 0
var awakening_count: int = 0

func _exit_tree() -> void:
	shutdown()

func shutdown() -> void:
	shutting_down = true
	if is_instance_valid(duck_tween): duck_tween.kill()
	if is_instance_valid(title_tween): title_tween.kill()
	# Release loop playback before the audio server shuts down, including headless runs.
	for player in voices + [ui_voice, music, pulse, title_water, crystal_voice, magic_voice]:
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
		player.playback_type = AudioServer.PLAYBACK_TYPE_STREAM
		player.bus = "SFX"
		player.volume_db = -4
		add_child(player)
		voices.append(player)
	ui_voice = AudioStreamPlayer.new()
	ui_voice.playback_type = AudioServer.PLAYBACK_TYPE_STREAM
	ui_voice.bus = "UI"
	ui_voice.volume_db = -8
	add_child(ui_voice)
	music = _loop("ambience", -13)
	pulse = _loop("boss_pulse", -40)
	# Menu cues use separate bounded voices, so navigation cannot cut off a card reaction.
	crystal_tick = _crystal(0.18, 880.0, false)
	crystal_confirm = _crystal(0.3, 660.0, false)
	magic_chord = _crystal(0.85, 330.0, true)
	crystal_voice = AudioStreamPlayer.new()
	crystal_voice.playback_type = AudioServer.PLAYBACK_TYPE_STREAM
	crystal_voice.bus = "UI"
	crystal_voice.volume_db = -17
	add_child(crystal_voice)
	magic_voice = AudioStreamPlayer.new()
	magic_voice.playback_type = AudioServer.PLAYBACK_TYPE_STREAM
	magic_voice.bus = "UI"
	magic_voice.volume_db = -12
	add_child(magic_voice)
	title_water = AudioStreamPlayer.new()
	title_water.playback_type = AudioServer.PLAYBACK_TYPE_STREAM
	title_water.bus = "Music"
	title_water.volume_db = -80
	title_water.stream = _forest_water()
	add_child(title_water)
	title_water.play()

func _crystal(duration: float, frequency: float, warm: bool) -> AudioStreamWAV:
	var pcm = PackedByteArray()
	var rate: int = 22050
	pcm.resize(int(duration * rate) * 2)
	for i in range(pcm.size() / 2):
		var t: float = float(i) / rate
		var envelope: float = minf(1.0, t / 0.012) * exp(-t * (5.5 if warm else 21.0)) * minf(1.0, (duration - t) / 0.025)
		var sample: float = sin(TAU * frequency * t) * 0.35 + sin(TAU * frequency * 2.003 * t) * 0.16 + sin(TAU * frequency * 3.01 * t) * 0.07
		if warm: sample += sin(TAU * frequency * 1.5 * t) * 0.18 + sin(TAU * frequency * 1.25 * t) * 0.12
		pcm.encode_s16(i * 2, int(sample * envelope * 22000))
	return _wav(pcm, rate)

func _forest_water() -> AudioStreamWAV:
	# Deterministic synthesis with a seam crossfade; no gameplay RNG or external samples.
	var rate: int = 11025
	var count: int = rate * 8
	var values = PackedFloat32Array()
	values.resize(count)
	var smooth_noise: float = 0.0
	var seed_value: int = 7183
	for i in range(count):
		seed_value = (seed_value * 16807) % 2147483647
		var noise: float = float(seed_value) / 1073741823.5 - 1.0
		smooth_noise = smooth_noise * 0.94 + noise * 0.06
		var t: float = float(i) / rate
		var water: float = smooth_noise * (0.55 + sin(TAU * t / 8) * 0.08) + noise * 0.024
		var insect: float = sin(TAU * 2170 * t + sin(TAU * t * 0.5) * 0.8) * pow(maxf(0.0, sin(TAU * t * 0.5)), 12) * 0.004
		values[i] = water + insect
	var crossfade: int = rate / 4
	for i in range(crossfade):
		var weight: float = float(i) / crossfade
		values[count - crossfade + i] = lerpf(values[count - crossfade + i], values[i], weight)
	var pcm = PackedByteArray()
	pcm.resize((count - crossfade) * 2)
	for i in range(count - crossfade): pcm.encode_s16(i * 2, int(clampf(values[i + crossfade], -1, 1) * 25000))
	var stream: AudioStreamWAV = _wav(pcm, rate)
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_end = pcm.size() / 2
	return stream

func _wav(pcm: PackedByteArray, rate: int) -> AudioStreamWAV:
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = rate
	stream.data = pcm
	return stream

func navigate() -> void:
	if shutting_down or Time.get_ticks_msec() - last_navigation_ms < 90: return
	last_navigation_ms = Time.get_ticks_msec()
	navigation_count += 1
	crystal_voice.stream = crystal_tick
	crystal_voice.play()

func confirm() -> void:
	if shutting_down: return
	crystal_voice.stream = crystal_confirm
	crystal_voice.play()

func awaken() -> void:
	if shutting_down: return
	awakening_count += 1
	magic_voice.stream = magic_chord
	magic_voice.play()

func set_title(active: bool) -> void:
	if title_active == active or shutting_down: return
	title_active = active
	if is_instance_valid(title_tween): title_tween.kill()
	title_tween = create_tween().set_parallel(true)
	title_tween.tween_property(title_water, "volume_db", -12.0 if active else -80.0, 0.35)
	title_tween.tween_property(music, "volume_db", -19.0 if active else -13.0, 0.35)

func _loop(name: String, volume: float) -> AudioStreamPlayer:
	var player = AudioStreamPlayer.new()
	# Keep original WAV synthesis and performance cues in the same mixer on Web.
	player.playback_type = AudioServer.PLAYBACK_TYPE_STREAM
	player.bus = "Music"
	player.volume_db = volume
	var stream: AudioStreamWAV = Assets.resource("audio/" + name.replace("_", "-"))
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
	player.stream = Assets.resource("audio/" + name.replace("_", "-"))
	player.play()

func performance(index: int) -> AudioStreamPlayer:
	if shutting_down or voices.is_empty(): return null
	var path: String = Assets.dependency_file("attacks/battle-performances", "audio/battle-performances", "performance-%02d" % (clampi(index, 0, 14) + 1))
	var player: AudioStreamPlayer = voices[voice_index % voices.size()]
	voice_index += 1
	player.stream_paused = false
	player.pitch_scale = 1.0
	player.stream = load(path)
	player.play()
	return player

func set_boss(active: bool) -> void:
	create_tween().tween_property(pulse, "volume_db", -19.0 if active else -40.0, 0.55)

func duck() -> void:
	var index: int = AudioServer.get_bus_index("Music")
	var base: float = linear_to_db(maxf(0.0001, music_gain))
	if is_instance_valid(duck_tween): duck_tween.kill()
	duck_tween = create_tween()
	duck_tween.tween_method(func(value: float): AudioServer.set_bus_volume_db(index, value), base, base - 4, 0.06)
	duck_tween.tween_method(func(value: float): AudioServer.set_bus_volume_db(index, value), base - 4, base, 0.28)
