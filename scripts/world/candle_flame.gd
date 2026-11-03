class_name CandleFlame
extends MeshInstance3D
## Flamme einer Kerze (CandleModel.flame): zeigt die Bilder der Flackeranimation der Reihe nach, jede Flamme mit
## eigenem Versatz. Sie steht immer senkrecht – auch an einer gekippten Kerze in der Hand oder einer, die liegt.
## Unsichtbar steht sie still. Das Wachs darunter (wax, shaders/candle_wax.gdshader) glüht, solange sie sichtbar ist.
## Draußen neigt sie sich mit dem Wind (Spielkonzept 7.8, Entscheidung 3.11.): bis LEAN_MAX bei vollem Wind, in Böen
## flattert sie um bis zu LEAN_FLUTTER hin und her. Drinnen steht sie still – auch an einem offenen Fenster.

const LEAN_MAX := 0.7         ## rad (~40°) bei Wind 1
const LEAN_FLUTTER := 0.3     ## rad, Flattern bei voller Böe
const OUTDOOR_CHECK := 1.0    ## so oft (s) wird nachgesehen, ob die Flamme draußen ist

## Um diese Achse neigt sich die Flamme – mit dem Wind, der wie der Regen nach Weather.FALL weht
static var _wind_axis := Vector3.UP.cross(Vector3(Weather.FALL.x, 0.0, Weather.FALL.z)).normalized()

var frames: Array[ArrayMesh] = []
var wax: GeometryInstance3D
var _time := randf() * 10.0
## 0..1: duckt sich – flacher und breiter (Deko hat das Monster abgewiesen, Item.flinch, Spielkonzept 5.10)
var duck := 0.0
var _scale := Vector3.ZERO   ## Größe ungeduckt (beim ersten Bild gemerkt)
var _outdoor := false
var _outdoor_timer := 0.0
var _lean := 0.0             ## rad, gerade


func _notification(what: int) -> void:
	if what == NOTIFICATION_VISIBILITY_CHANGED or what == NOTIFICATION_ENTER_TREE:
		if is_instance_valid(wax):
			wax.set_instance_shader_parameter("glow", 1.0 if is_visible_in_tree() else 0.0)


func _process(delta: float) -> void:
	if not is_visible_in_tree():
		return
	if _scale == Vector3.ZERO:
		_scale = global_basis.get_scale()
	_time += delta
	_update_lean(delta)
	var b := Basis.from_scale(_scale * Vector3(1.0 + 0.35 * duck, 1.0 - 0.6 * duck, 1.0 + 0.35 * duck))
	global_basis = Basis(_wind_axis, _lean) * b if absf(_lean) > 0.001 else b
	if frames.is_empty():
		return
	var i := int(_time * CandleModel.FPS) % frames.size()
	if mesh != frames[i]:
		mesh = frames[i]


func _update_lean(delta: float) -> void:
	_outdoor_timer -= delta
	if _outdoor_timer <= 0.0:
		_outdoor_timer = OUTDOOR_CHECK
		_outdoor = Game.weather != null and RainVeil.is_outdoor(global_position)
	var target := 0.0
	if _outdoor:
		var w := Game.weather
		target = w.wind * LEAN_MAX + w.gust() * LEAN_FLUTTER * sin(_time * 13.0) * (0.6 + 0.4 * sin(_time * 3.7))
	_lean = lerpf(_lean, target, minf(1.0, 8.0 * delta))
