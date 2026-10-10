class_name FlickerLight
extends OmniLight3D
## Lichtquelle mit Flackern. „flicker“ (0..1) wird vom MonsterDirector gesetzt
## (Ankündigung des Monsters). Zählt für die Helligkeitsberechnung (Gruppe „light_source“).

var base_energy := 1.0
var broken := false        ## Defekte Lampe: meist aus, selten ein Funke.
var soft := false          ## Kerzenlicht: leichtes, ständiges Flackern.
var burn_out := false      ## Abgebrannt (Kerze, Kürbis).
var flicker := 0.0
var lamp_material: ShaderMaterial

var _level := 1.0
var _timer := 0.0


func _ready() -> void:
	add_to_group("light_source")
	light_energy = base_energy


func _process(delta: float) -> void:
	_timer -= delta
	if _timer <= 0.0:
		_timer = randf_range(0.04, 0.14)
		_level = _pick_level()
	light_energy = base_energy * _level
	if lamp_material:
		lamp_material.set_shader_parameter("emission_energy", 2.5 * _level)


func _pick_level() -> float:
	if burn_out:
		return 0.0
	if broken:
		return randf_range(0.3, 0.8) if randf() < 0.025 else 0.0
	var level := randf_range(0.82, 1.0) if soft else 1.0
	if flicker > 0.0:
		if randf() < flicker * 0.35:
			return randf_range(0.0, 0.15)
		level -= randf() * flicker * 0.3
	return level
