extends Node
## Basit 8-bit ses: AudioStreamGenerator ile çalışma anında sentezlenen
## kare/üçgen/gürültü dalgaları. Ses dosyası gerekmez (placeholder).
## assets/audio/ altında aynı isimli .wav/.ogg varsa onları çalar (bkz. ASSETS.md).

const RATE := 22050.0
const SFX_DIR := "res://assets/audio/"

## SFX tanımları: f0 -> f1 Hz arasında kayan ton, süre (s), dalga, ses.
const SFX := {
	"jump":     {"f0": 330.0, "f1": 880.0, "dur": 0.14, "wave": "square", "vol": 0.22, "duty": 0.25},
	"jump_ai":  {"f0": 260.0, "f1": 620.0, "dur": 0.10, "wave": "square", "vol": 0.08, "duty": 0.25},
	"duck":     {"f0": 220.0, "f1": 140.0, "dur": 0.06, "wave": "square", "vol": 0.12, "duty": 0.5},
	"hit":      {"f0": 300.0, "f1": 60.0, "dur": 0.35, "wave": "noise", "vol": 0.28, "duty": 0.5},
	"hee":      {"f0": 700.0, "f1": 380.0, "dur": 0.30, "wave": "square", "vol": 0.16, "duty": 0.125},
	"select":   {"f0": 523.0, "f1": 1046.0, "dur": 0.12, "wave": "square", "vol": 0.18, "duty": 0.5},
	"message":  {"f0": 880.0, "f1": 1320.0, "dur": 0.18, "wave": "triangle", "vol": 0.30, "duty": 0.5},
	"theme":    {"f0": 440.0, "f1": 1760.0, "dur": 0.40, "wave": "triangle", "vol": 0.25, "duty": 0.5},
	"gameover": {"f0": 440.0, "f1": 110.0, "dur": 0.9, "wave": "square", "vol": 0.22, "duty": 0.5},
	"final":    {"f0": 523.0, "f1": 2093.0, "dur": 0.8, "wave": "square", "vol": 0.2, "duty": 0.25},
}

const DEFAULT_MUSIC := {
	"bpm": 138, "root": 60, "scale": [0, 2, 4, 7, 9],
	"lead": [0, -1, 2, -1, 4, 2, -1, 0, 1, -1, 3, -1, 4, 3, 2, -1],
	"bass": [0, -1, 0, -1, 3, -1, 3, -1, 4, -1, 4, -1, 2, -1, 2, -1],
	"lead_wave": "square", "duty": 0.25,
}

var music_enabled := true
var sfx_enabled := true
var music_volume := 0.11

var _player := AudioStreamPlayer.new()
var _playback: AudioStreamGeneratorPlayback
var _voices: Array = []              # aktif sfx sesleri
var _file_players: Array = []
var _file_cache: Dictionary = {}
var _music_player := AudioStreamPlayer.new()

# müzik sıralayıcı
var _music: Dictionary = {}
var _music_on := false
var _step := 0
var _step_left := 0
var _lead_f := 0.0
var _lead_ph := 0.0
var _lead_env := 0.0
var _bass_f := 0.0
var _bass_ph := 0.0
var _bass_env := 0.0
var _noise := 1
var _buf := PackedVector2Array()


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var gen := AudioStreamGenerator.new()
	gen.mix_rate = RATE
	gen.buffer_length = 0.12
	_player.stream = gen
	add_child(_player)
	add_child(_music_player)
	for i in 4:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_file_players.append(p)
	_player.play()
	_playback = _player.get_stream_playback()
	set_music(DEFAULT_MUSIC)


## Tema müziği. data: themes.json'daki "music" bloğu. "file" varsa o çalınır.
func set_music(data: Dictionary) -> void:
	var file := str(data.get("file", ""))
	var stream: AudioStream = null
	if file != "" and ResourceLoader.exists(file):
		stream = load(file)
	if stream:
		_music_on = false
		if _music_player.stream != stream:
			_music_player.stream = stream
			_music_player.volume_db = -6.0
			_music_player.play()
		return
	_music_player.stop()
	_music = DEFAULT_MUSIC.duplicate()
	_music.merge(data, true)
	_step = 0
	_step_left = 0


func start_music() -> void:
	_music_on = music_enabled and _music_player.stream == null
	if _music_player.stream and music_enabled and not _music_player.playing:
		_music_player.play()


func stop_music() -> void:
	_music_on = false
	_music_player.stop()


func sfx(name: String) -> void:
	if not sfx_enabled:
		return
	var stream := _file_stream(name)
	if stream:
		for p in _file_players:
			if not p.playing:
				p.stream = stream
				p.play()
				return
		return
	if not SFX.has(name):
		return
	var v: Dictionary = SFX[name].duplicate()
	v.t = 0.0
	v.ph = 0.0
	_voices.append(v)
	if _voices.size() > 6:
		_voices.pop_front()


func _file_stream(name: String) -> AudioStream:
	if not _file_cache.has(name):
		var s: AudioStream = null
		for ext in [".wav", ".ogg"]:
			if ResourceLoader.exists(SFX_DIR + "sfx_" + name + ext):
				s = load(SFX_DIR + "sfx_" + name + ext)
				break
		_file_cache[name] = s
	return _file_cache[name]


func _process(_delta: float) -> void:
	if _playback == null:
		return
	var n := _playback.get_frames_available()
	if n <= 0:
		return
	_buf.resize(n)
	var dt := 1.0 / RATE
	var bpm := float(_music.get("bpm", 138))
	var step_len := int(RATE * 60.0 / bpm / 4.0)   # 16'lık nota
	var lead_duty := float(_music.get("duty", 0.25))
	var lead_wave := str(_music.get("lead_wave", "square"))
	for i in n:
		var s := 0.0
		if _music_on:
			if _step_left <= 0:
				_next_step()
				_step_left = step_len
			_step_left -= 1
			_lead_env *= 0.99985
			_bass_env *= 0.99993
			_lead_ph = fmod(_lead_ph + _lead_f * dt, 1.0)
			_bass_ph = fmod(_bass_ph + _bass_f * dt, 1.0)
			s += _osc(lead_wave, _lead_ph, lead_duty) * _lead_env * music_volume
			s += _osc("triangle", _bass_ph, 0.5) * _bass_env * music_volume * 1.3
		var k := _voices.size() - 1
		while k >= 0:
			var v: Dictionary = _voices[k]
			var p: float = v.t / v.dur
			if p >= 1.0:
				_voices.remove_at(k)
			else:
				var f: float = lerpf(v.f0, v.f1, p)
				v.ph = fmod(v.ph + f * dt, 1.0)
				s += _osc(v.wave, v.ph, v.duty) * v.vol * (1.0 - p)
				v.t += dt
			k -= 1
		s = clampf(s, -1.0, 1.0)
		_buf[i] = Vector2(s, s)
	_playback.push_buffer(_buf)


func _next_step() -> void:
	var lead: Array = _music.lead
	var bass: Array = _music.bass
	var sc: Array = _music.scale
	var root := int(_music.root)
	var li := int(lead[_step % lead.size()])
	if li >= 0:
		_lead_f = _midi(root + 12 + _degree(sc, li))
		_lead_env = 1.0
	var bi := int(bass[_step % bass.size()])
	if bi >= 0:
		_bass_f = _midi(root - 12 + _degree(sc, bi))
		_bass_env = 1.0
	_step += 1


func _degree(sc: Array, i: int) -> int:
	return int(sc[i % sc.size()]) + 12 * int(i / sc.size())


func _midi(note: int) -> float:
	return 440.0 * pow(2.0, (note - 69) / 12.0)


func _osc(wave: String, ph: float, duty: float) -> float:
	match wave:
		"square":
			return 1.0 if ph < duty else -1.0
		"triangle":
			return 4.0 * absf(ph - 0.5) - 1.0
		"saw":
			return 2.0 * ph - 1.0
		"noise":
			# 15 bit LFSR, NES gürültü kanalı gibi.
			var bit := (_noise ^ (_noise >> 1)) & 1
			_noise = (_noise >> 1) | (bit << 14)
			return 1.0 if (_noise & 1) == 1 else -1.0
	return 0.0
