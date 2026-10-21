class_name FlickerLight
extends OmniLight3D
## Lichtquelle mit Flackern. „flicker“ (0..1, Nähe des Monsters) und „wave“ (0..1, Flackerwelle
## beim Aufbruch, Spielkonzept 4.17) setzt der MonsterDirector. Nur „flicker“ lässt Birnen
## durchbrennen. Zählt für die Helligkeitsberechnung (Gruppe „light_source“).

var base_energy := 1.0
var broken := false        ## Defekte Lampe: meist aus, selten ein Funke.
var soft := false          ## Kerzenlicht: leichtes, ständiges Flackern.
## Halogenröhre (Spielkonzept 7.9): flackert alle 10–30 s von selbst 1–3-mal kurz.
var stutter := false
var burn_out := false      ## Abgebrannt (Kerze, Kürbis).
var switched_off := false  ## Lichtschalter aus, Birne fehlt oder ist durchgebrannt.
var flicker := 0.0
var wave := 0.0
var lamp_material: ShaderMaterial

var _level := 1.0
var _timer := 0.0
var _stutter_wait := 0.0   ## Sekunden bis zum nächsten Flackern der Röhre
var _stutter_left := 0     ## Aussetzer, die in diesem Flackern noch kommen
var _stutter_t := 0.0      ## Rest des Aussetzers bzw. der Pause danach
var _stutter_off := false


func _ready() -> void:
	add_to_group("light_source")
	light_energy = base_energy
	_stutter_wait = randf_range(1.0, 30.0)


func _process(delta: float) -> void:
	_timer -= delta
	if _timer <= 0.0:
		_timer = randf_range(0.04, 0.14)
		_level = _pick_level()
	if stutter:
		_update_stutter(delta)
	var level := _level * (0.05 if _stutter_off else 1.0)
	light_energy = base_energy * level
	if lamp_material:
		lamp_material.set_shader_parameter("emission_energy", 2.5 * level)


## Eigenes Flackern der Halogenröhre: nach der Wartezeit 1–3 Aussetzer von 40–120 ms, dazwischen kurz an.
func _update_stutter(delta: float) -> void:
	if _stutter_left == 0:
		_stutter_wait -= delta
		if _stutter_wait > 0.0:
			return
		_stutter_left = randi_range(1, 3)
		_stutter_off = true
		_stutter_t = randf_range(0.04, 0.12)
		return
	_stutter_t -= delta
	if _stutter_t > 0.0:
		return
	if _stutter_off:
		_stutter_off = false
		_stutter_left -= 1
		_stutter_t = randf_range(0.05, 0.2)
		if _stutter_left == 0:
			_stutter_wait = randf_range(10.0, 30.0)
	else:
		_stutter_off = true
		_stutter_t = randf_range(0.04, 0.12)


func _pick_level() -> float:
	if burn_out or switched_off:
		return 0.0
	if broken:
		return randf_range(0.3, 0.8) if randf() < 0.025 else 0.0
	var level := randf_range(0.82, 1.0) if soft else 1.0
	var f := maxf(flicker, wave) * Settings.flicker_intensity
	if f > 0.0:
		if randf() < f * 0.35:
			return randf_range(0.0, 0.15)
		level -= randf() * f * 0.3
	return level
