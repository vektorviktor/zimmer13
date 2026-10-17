class_name SynthAudio
extends AudioStreamPlayer
## Prozedurale Platzhalter-Akustik, bis echte Sounds existieren:
## Brummen, Rauschen, Herzschlag und kurze Einzeleffekte.

const RATE := 22050.0
const MUSIC_BEAT := 60.0 / 132.0
## Walzer in a-Moll: Am – F – G – E
const MUSIC_CHORDS := [[220.0, 261.6, 329.6], [174.6, 220.0, 261.6], [196.0, 246.9, 293.7], [164.8, 207.7, 246.9]]
const DURATIONS := {
	"scream": 1.6, "sting": 1.6, "growl": 1.8, "gasp": 0.5,
	"bang": 0.4, "blip": 0.08, "creak": 0.6, "thud": 0.25, "knock": 0.6, "ring": 1.0,
	"rustle": 0.3, "jingle": 0.45, "meow": 0.55, "purr": 1.4, "cry": 1.5,
}

var hum := 0.0
var static_noise := 0.0
var heart := 0.0
var heart_bpm := 70.0
var buzz := 0.0    ## Sirren und Knistern im Stromnetz (Flackerwelle, Spielkonzept 4.17)
var music := 0.0   ## Lautstärke der Feiermusik (Plattenspieler)

var _playback: AudioStreamGeneratorPlayback
var _time := 0.0
var _lp_fast := 0.0
var _lp_slow := 0.0
var _shots: Array[Dictionary] = []
var _music_volume := 1.0
var _effects_volume := 1.0
var _damp := 1.0   ## im Pausenmenü gedämpft


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var generator := AudioStreamGenerator.new()
	generator.mix_rate = RATE
	generator.buffer_length = 0.15
	stream = generator
	play()
	_playback = get_stream_playback() as AudioStreamGeneratorPlayback


func play_shot(kind: String, volume: float = 1.0) -> void:
	if _shots.size() > 16:
		return
	_shots.append({"kind": kind, "t": 0.0, "dur": float(DURATIONS.get(kind, 0.5)), "vol": volume, "phase": 0.0})


func _process(_delta: float) -> void:
	if _playback == null:
		return
	_music_volume = Settings.music_volume
	_effects_volume = Settings.effects_volume
	_damp = move_toward(_damp, 0.25 if get_tree().paused else 1.0, 0.05)
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
		"purr":
			# Schnurren: tiefes Brummen, 26-mal pro Sekunde an- und abschwellend
			var pulse := 0.5 + 0.5 * sin(TAU * 26.0 * t)
			return (_lp_slow * 2.5 + sin(TAU * 52.0 * t) * 0.3) * pulse * sin(PI * k) * 0.5
		"cry":
			# Weinen: langes, klagendes Jammern mit Zittern, am Ende abfallend
			var cf := 430.0 + 260.0 * sin(PI * k) + 30.0 * sin(TAU * 5.5 * t)
			var cph: float = shot["phase"] + cf * dt
			shot["phase"] = cph
			var wail := (fmod(cph, 1.0) * 2.0 - 1.0) * 0.3 + sin(TAU * cph) * 0.4 + white * 0.08
			return wail * sqrt(sin(PI * k)) * 0.3
	return 0.0
