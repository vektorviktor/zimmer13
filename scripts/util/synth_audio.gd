class_name SynthAudio
extends AudioStreamPlayer
## Prozedurale Platzhalter-Akustik, bis echte Sounds existieren:
## Brummen, Rauschen, Herzschlag, Keuchen und kurze Einzeleffekte. Arten mit echtem Klang stehen in
## `SAMPLES` und laufen über eigene Player statt über den Generator.

## Art → Klangdatei (mono, Spitze −6 dB) und Pegel in dB, abgespielt statt der synthetischen Fassung.
## "solo": eigene Stimme, die kein anderer Klang abbricht (lange Klänge).
const SAMPLES := {
	"door": {"file": "res://assets/sound/door_open.wav", "db": 0.0},   ## Hoteltüren (`Door.set_open`)
	"bell": {"file": "res://assets/sound/church_bell.wav", "db": 0.0, "solo": true},   ## Totenglocke (`Social.on_guest_died`)
	"shriek": {"file": "res://assets/sound/screams/monster.wav", "db": 0.0, "solo": true},   ## Spielertod (Jumpscare)
	"cry": {"file": "res://assets/sound/screams/cat.wav", "db": -2.0},   ## Hotelkatze auf der Flucht (`cat_cry`)
}
## Menschliche Laute: Klang → Aufnahmen je Stimme ("m", "f", "child", `Guest.voice()`), Pegel in dB, Tonhöhe
## (`pitch`, × die eigene des Gastes) und Abbruch (`cut`: spielt nur einen zufälligen Anteil dazwischen, sonst
## `length` des Gastes). Jeder bekommt immer dieselbe Aufnahme seiner Stimme und klingt aus seiner Richtung
## (3D, gedämpft wie Lärm). Ohne passende Stimme spielt `synth` ("" = nichts).
const SCREAMS := {
	"m": ["male_1", "male_2", "male_3", "male_4", "male_5", "male_6"],
	"f": ["female_1", "female_2", "female_3"],
	"child": ["child_1", "child_2", "child_3"],
}
const VOICES := {
	"scream": {"files": SCREAMS, "db": 0.0, "synth": "scream"},   ## Schreck – klingt aus
	"death_scream": {"files": SCREAMS, "db": 2.0, "pitch": 0.94, "cut": Vector2(0.45, 0.75), "synth": "scream"},   ## jäh abgerissen
	"grunt": {"files": {"m": ["grunt_male_1", "grunt_male_2"]}, "db": -3.0, "cut": Vector2.ONE, "synth": ""},   ## letzter Laut (Axt, Würgen)
	## schweres Atmen nach dem Würgen (Spielkonzept 6.17) – ein Atemzug, tiefer und gepresst, in seiner Stimmlage
	"wheeze": {"files": {"m": ["breath"], "f": ["breath"], "child": ["breath"]}, "dir": "res://assets/sound/%s.wav", "db": -4.0,
		"pitch": 0.8, "cut": Vector2.ONE, "synth": ""},
}
const VOICE_DIR := "res://assets/sound/screams/%s.wav"
const VOICE_PLAYERS := 4          ## so viele Stimmen gleichzeitig (wer schon schreit, nimmt seine eigene)
const VOICE_JITTER := 0.05        ## jedes Mal etwas anders hoch und lang
const VOICE_FADE := 0.04          ## so schnell bricht ein Schrei ab (s)
const SAMPLE_VOICES := 4          ## so viele Klänge gleichzeitig
const SAMPLE_PITCH_JITTER := 0.05 ## jedes Mal etwas anders
const BREATH := "res://assets/sound/breath.wav"   ## ein Atemzug, ein und aus (Keuchen, `pant`)
const BREATH_DB := -4.0
const RATE := 22050.0
const MUSIC_BEAT := 60.0 / 132.0
## Walzer in a-Moll: Am – F – G – E
const MUSIC_CHORDS := [[220.0, 261.6, 329.6], [174.6, 220.0, 261.6], [196.0, 246.9, 293.7], [164.8, 207.7, 246.9]]
const DURATIONS := {
	"scream": 1.6, "sting": 1.6, "growl": 1.8, "gasp": 0.5,
	"bang": 0.4, "blip": 0.08, "creak": 0.6, "thud": 0.25, "knock": 0.6, "ring": 1.0,
	"rustle": 0.3, "jingle": 0.45, "meow": 0.55, "purr": 1.4, "thunder": 5.0, "hiss": 0.5,
}

var hum := 0.0
var static_noise := 0.0
var heart := 0.0
var heart_bpm := 70.0
var buzz := 0.0    ## Sirren und Knistern im Stromnetz (Flackerwelle, Spielkonzept 4.17)
var music := 0.0   ## Lautstärke der Feiermusik (Plattenspieler)
var pant := 0.0    ## Keuchen des Spielers nach dem Rennen (Ausdauer, Spielkonzept 3.1)
var pant_rate := 0.4   ## Atemzüge pro Sekunde
var rain := 0.0    ## Regenrauschen (Wetter, Spielkonzept 7.8)
var rain_muffle := 0.0   ## 1 = drinnen: dumpfer

var _playback: AudioStreamGeneratorPlayback
var _time := 0.0
var _lp_fast := 0.0
var _lp_slow := 0.0
var _pant_phase := 1.0   ## 1 = der nächste Atemzug beginnt sofort
var _pant_depth := 1.0   ## jeder Atemzug etwas anders tief
var _breath: AudioStreamPlayer
var _shots: Array[Dictionary] = []
var _music_volume := 1.0
var _effects_volume := 1.0
var _damp := 1.0   ## im Pausenmenü gedämpft
var _voices: Array[AudioStreamPlayer] = []
var _next_voice := 0
var _sample_streams := {}
var _solo_voices := {}   ## Klangdatei → eigene Stimme ("solo" in `SAMPLES`)
var _speakers: Array[AudioStreamPlayer3D] = []   ## menschliche Laute (`VOICES`), im Raum
var _next_speaker := 0


func _ready() -> void:
	for i in SAMPLE_VOICES:
		var voice := AudioStreamPlayer.new()
		add_child(voice)
		_voices.append(voice)
	for i in VOICE_PLAYERS:
		# Ohne Abschwächung über die Entfernung – die Lautstärke rechnet Game.sound_at (Wände, Hörweite),
		# der Lautsprecher gibt nur die Richtung
		var speaker := AudioStreamPlayer3D.new()
		speaker.attenuation_model = AudioStreamPlayer3D.ATTENUATION_DISABLED
		add_child(speaker)
		_speakers.append(speaker)
	_breath = AudioStreamPlayer.new()
	_breath.stream = load(BREATH)
	add_child(_breath)
	process_mode = Node.PROCESS_MODE_ALWAYS
	var generator := AudioStreamGenerator.new()
	generator.mix_rate = RATE
	generator.buffer_length = 0.15
	stream = generator
	play()
	_playback = get_stream_playback() as AudioStreamGeneratorPlayback


## Spielt einen Klang; `pos`/`who` braucht nur eine Stimme (`VOICES`). false = nichts zu hören (keine passende
## Stimme und kein Ersatz).
func play_shot(kind: String, volume: float = 1.0, pos := Vector3.INF, who: Node = null) -> bool:
	if VOICES.has(kind):
		if who and who.has_method("voice") and pos.is_finite() and _play_voice(VOICES[kind], volume, pos, who):
			return true
		kind = VOICES[kind]["synth"]
		if kind == "":
			return false
	if SAMPLES.has(kind):
		_play_sample(SAMPLES[kind], volume)
		return true
	if _shots.size() > 16:
		return true
	_shots.append({"kind": kind, "t": 0.0, "dur": float(DURATIONS.get(kind, 0.5)), "vol": volume, "phase": 0.0})
	return true


## Was `who` gerade ruft, bricht ab (schnell ausgeblendet) – etwa ein Schrei, wenn die Axt trifft.
func cut_voice(who: Node) -> void:
	for speaker in _speakers:
		if speaker.playing and speaker.get_meta("who", 0) == who.get_instance_id():
			_fade_out(speaker)


## Menschlicher Laut aus `VOICES` am Ort `pos` in der Stimme von `who` (`Guest.voice()`). Wer schon ruft, nimmt
## seinen eigenen Lautsprecher (der alte Laut bricht ab), sonst reihum. false = keine Aufnahme für diese Stimme.
func _play_voice(entry: Dictionary, volume: float, pos: Vector3, who: Node) -> bool:
	var v: Dictionary = who.voice()
	var files: Array = entry["files"].get(v["voice"], [])
	if files.is_empty():
		return false
	var gain := volume * Settings.effects_volume * _damp
	if gain <= 0.0:
		return true
	var file: String = String(entry.get("dir", VOICE_DIR)) % files[int(v["pick"]) % files.size()]
	if not _sample_streams.has(file):
		_sample_streams[file] = load(file)
	var speaker: AudioStreamPlayer3D = null
	for s in _speakers:
		if s.playing and s.get_meta("who", 0) == who.get_instance_id():
			speaker = s
	if speaker == null:
		speaker = _speakers[_next_speaker]
		_next_speaker = (_next_speaker + 1) % _speakers.size()
	var stream: AudioStream = _sample_streams[file]
	var pitch: float = float(v["pitch"]) * float(entry.get("pitch", 1.0)) * randf_range(1.0 - VOICE_JITTER, 1.0 + VOICE_JITTER)
	var cut: Vector2 = entry.get("cut", Vector2.ONE * float(v["length"]))
	var token := int(speaker.get_meta("token", 0)) + 1
	speaker.set_meta("token", token)
	speaker.set_meta("who", who.get_instance_id())
	if speaker.has_meta("fade"):
		(speaker.get_meta("fade") as Tween).kill()
		speaker.remove_meta("fade")
	speaker.stream = stream
	speaker.global_position = pos + Vector3.UP * 1.5
	speaker.volume_db = float(entry["db"]) + linear_to_db(gain)
	speaker.pitch_scale = pitch
	speaker.play()
	var share := randf_range(cut.x, cut.y)
	if share < 0.98:
		get_tree().create_timer(stream.get_length() * share / pitch, true).timeout.connect(func() -> void:
			if speaker.playing and int(speaker.get_meta("token", 0)) == token:
				_fade_out(speaker))
	return true


func _fade_out(speaker: AudioStreamPlayer3D) -> void:
	var tween := speaker.create_tween()
	tween.tween_property(speaker, "volume_db", -60.0, VOICE_FADE)
	tween.tween_callback(speaker.stop)
	speaker.set_meta("fade", tween)


## Echter Klang, reihum auf einer der `SAMPLE_VOICES` Stimmen (die älteste bricht ab) – oder auf einer
## eigenen, wenn er "solo" ist
func _play_sample(sample: Dictionary, volume: float) -> void:
	var gain := volume * Settings.effects_volume * _damp
	if gain <= 0.0:
		return
	var file: String = sample["file"]
	if not _sample_streams.has(file):
		_sample_streams[file] = load(file)
	var voice: AudioStreamPlayer
	if sample.get("solo", false):
		if not _solo_voices.has(file):
			_solo_voices[file] = AudioStreamPlayer.new()
			add_child(_solo_voices[file])
		voice = _solo_voices[file]
	else:
		voice = _voices[_next_voice]
		_next_voice = (_next_voice + 1) % _voices.size()
	voice.stream = _sample_streams[file]
	voice.volume_db = float(sample["db"]) + linear_to_db(gain)
	voice.pitch_scale = randf_range(1.0 - SAMPLE_PITCH_JITTER, 1.0 + SAMPLE_PITCH_JITTER)
	voice.play()


func _process(delta: float) -> void:
	if _playback == null:
		return
	_music_volume = Settings.music_volume
	_effects_volume = Settings.effects_volume
	_damp = move_toward(_damp, 0.25 if get_tree().paused else 1.0, 0.05)
	_update_pant(delta)
	var frames := _playback.get_frames_available()
	var dt := 1.0 / RATE
	for i in frames:
		var s := _sample(dt)
		_playback.push_frame(Vector2(s, s))


func _sample(dt: float) -> float:
	_time += dt
	var white := randf() * 2.0 - 1.0
	_lp_fast += (white - _lp_fast) * 0.3
	_lp_slow += (white - _lp_slow) * 0.02
	var s := 0.0
	if hum > 0.001:
		s += (sin(TAU * 46.0 * _time) * 0.5 + sin(TAU * 93.0 * _time) * 0.2 + _lp_slow * 2.0) * hum
	if static_noise > 0.001:
		s += _lp_fast * static_noise
	if buzz > 0.001:
		var crackle := white * 1.6 if randf() < 0.004 else 0.0
		s += (sin(TAU * 100.0 * _time) * 0.22 + sin(TAU * 200.0 * _time) * 0.1 + crackle) * buzz
	var m := 0.0
	if music > 0.001:
		m = _music_sample() * music
	if heart > 0.001:
		var beat := fmod(_time, 60.0 / heart_bpm)
		s += (_thump(beat) + _thump(beat - 0.22) * 0.6) * heart
	if rain > 0.001:
		s += (white * 0.16 * (1.0 - rain_muffle) + _lp_fast * 0.3 + _lp_slow * 0.8 * rain_muffle) * rain
	var i := _shots.size() - 1
	while i >= 0:
		var shot := _shots[i]
		var t: float = shot["t"] + dt
		shot["t"] = t
		if t >= float(shot["dur"]):
			_shots.remove_at(i)
		else:
			s += _shot_sample(shot, t, dt, white) * float(shot["vol"])
		i -= 1
	s = (s * _effects_volume + m * _music_volume) * _damp
	return s / (1.0 + absf(s))


func _music_sample() -> float:
	var beat := int(_time / MUSIC_BEAT)
	var chord: Array = MUSIC_CHORDS[(beat / 3) % 4]
	var step := beat % 3
	var bt := fmod(_time, MUSIC_BEAT)
	var f: float = chord[step] * 2.0
	var lead := (1.0 if sin(TAU * f * _time) > 0.0 else -1.0) * 0.1 * exp(-bt * 5.0)
	var bass := sin(TAU * float(chord[0]) * 0.5 * _time) * (0.3 if step == 0 else 0.12) * exp(-bt * 2.5)
	return lead + bass


## Keuchen: alle `1 / pant_rate` s ein Atemzug aus `BREATH`, jeder etwas anders tief und hoch. Die Lautstärke
## folgt `pant` auch mitten im Atemzug – beim Luftanhalten bricht er ab.
func _update_pant(delta: float) -> void:
	if pant <= 0.02:
		_pant_phase = 1.0
		if _breath.playing:
			_breath.stop()
		return
	_pant_phase += delta * pant_rate
	if _pant_phase >= 1.0:
		_pant_phase = fmod(_pant_phase, 1.0)
		_pant_depth = randf_range(0.75, 1.15)
		_breath.pitch_scale = randf_range(1.0 - SAMPLE_PITCH_JITTER, 1.0 + SAMPLE_PITCH_JITTER)
		_breath.play()
	_breath.volume_db = BREATH_DB + linear_to_db(maxf(pant * _pant_depth * _effects_volume * _damp, 0.0001))


func _thump(t: float) -> float:
	if t < 0.0 or t > 0.16:
		return 0.0
	return sin(TAU * 52.0 * t) * exp(-t * 28.0)


func _shot_sample(shot: Dictionary, t: float, dt: float, white: float) -> float:
	var k := t / float(shot["dur"])
	var env := 1.0 - k
	match String(shot["kind"]):
		"scream":
			var f := lerpf(1300.0, 240.0, k)
			var ph: float = shot["phase"] + f * dt
			shot["phase"] = ph
			var saw := fmod(ph, 1.0) * 2.0 - 1.0
			return (white * 0.6 + saw * 0.5 + sin(TAU * ph * 1.51) * 0.3) * sqrt(env) * 1.4
		"sting":
			return (sin(TAU * 1180.0 * t) + sin(TAU * 1247.0 * t) + sin(TAU * 589.0 * t) * 0.6) * 0.22 * exp(-t * 2.5)
		"growl":
			var win := sin(PI * k)
			return (_lp_fast * (0.6 + 0.4 * sin(TAU * 27.0 * t)) * 1.3 + sin(TAU * 55.0 * t) * 0.25) * win
		"gasp":
			return white * sin(PI * k) * 0.3
		"bang":
			return white * exp(-t * 12.0) * 0.9 + sin(TAU * 65.0 * t) * exp(-t * 8.0) * 0.8
		"blip":
			return sin(TAU * 880.0 * t) * env * 0.15
		"creak":
			var f2 := 160.0 + 50.0 * sin(TAU * 6.0 * t)
			var ph2: float = shot["phase"] + f2 * dt
			shot["phase"] = ph2
			return (fmod(ph2, 1.0) * 2.0 - 1.0) * sin(PI * k) * 0.12
		"thud":
			return sin(TAU * 75.0 * t) * exp(-t * 16.0) * 0.8
		"knock":
			# drei kurze, dumpfe Schläge gegen Holz
			var kt := fmod(t, 0.2)
			if t > 0.58:
				return 0.0
			return (sin(TAU * 140.0 * kt) * 0.7 + white * 0.4) * exp(-kt * 38.0)
		"ring":
			# alte Telefonglocke: zwei kurze Schnarr-Stöße, der Klöppel schlägt 25-mal pro Sekunde
			if fmod(t, 0.5) > 0.4:
				return 0.0
			var strike := exp(-fmod(t, 0.04) * 60.0)
			return (sin(TAU * 1020.0 * t) + sin(TAU * 1290.0 * t) * 0.7) * strike * 0.22
		"rustle":
			# Papier: Rauschen in kurzen, unregelmäßigen Knistern
			return white * (0.5 + 0.5 * sin(TAU * 23.0 * t) * sin(TAU * 37.0 * t)) * sin(PI * k) * 0.25
		"jingle":
			# Schlüsselbund: vier helle, kurz verklingende Metallschläge
			var jt := fmod(t, 0.09)
			if t > 0.36:
				return 0.0
			var jf: float = 2400.0 + 700.0 * floor(t / 0.09)
			return (sin(TAU * jf * jt) + sin(TAU * jf * 1.48 * jt) * 0.6) * exp(-jt * 45.0) * 0.12
		"meow":
			# Katze: „mi-au“ – Tonhöhe steigt und fällt, nasal (Sägezahn mit Oberton)
			var mf := 520.0 + 380.0 * sin(PI * minf(k * 1.3, 1.0)) - 150.0 * k
			var mph: float = shot["phase"] + mf * dt
			shot["phase"] = mph
			var nasal := (fmod(mph, 1.0) * 2.0 - 1.0) * 0.35 + sin(TAU * mph * 2.0) * 0.3
			return nasal * sin(PI * k) * (0.8 + 0.2 * sin(TAU * 7.0 * t)) * 0.25
		"hiss":
			# Getränkedose: kurzes Knacken der Lasche, dann zischt die Kohlensäure heraus
			var click := sin(TAU * 1900.0 * t) * exp(-t * 400.0) * 0.4
			return click + white * minf(1.0, t * 60.0) * exp(-t * 7.0) * 0.28
		"purr":
			# Schnurren: tiefes Brummen, 26-mal pro Sekunde an- und abschwellend
			var pulse := 0.5 + 0.5 * sin(TAU * 26.0 * t)
			return (_lp_slow * 2.5 + sin(TAU * 52.0 * t) * 0.3) * pulse * sin(PI * k) * 0.5
		"thunder":
			# Donner (Wetter, 7.8): kurzes Krachen, dann langes, schwankendes Grollen
			var crack := white * exp(-t * 14.0) * 0.5
			var roll := _lp_slow * 9.0 * (0.6 + 0.4 * sin(TAU * 1.7 * t + 2.0 * sin(TAU * 0.4 * t)))
			return (crack + roll) * minf(1.0, t * 30.0) * exp(-t * 0.75)
	return 0.0
