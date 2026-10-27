class_name CandleFlame
extends MeshInstance3D
## Flamme einer Kerze (CandleModel.flame): zeigt die Bilder der Flackeranimation der Reihe nach, jede Flamme mit
## eigenem Versatz. Sie steht immer senkrecht – auch an einer gekippten Kerze in der Hand oder einer, die liegt.
## Unsichtbar steht sie still. Das Wachs darunter (wax, shaders/candle_wax.gdshader) glüht, solange sie sichtbar ist.

var frames: Array[ArrayMesh] = []
var wax: GeometryInstance3D
var _time := randf() * 10.0
## 0..1: duckt sich – flacher und breiter (Deko hat das Monster abgewiesen, Item.flinch, Spielkonzept 5.10)
var duck := 0.0
var _scale := Vector3.ZERO   ## Größe ungeduckt (beim ersten Bild gemerkt)


func _notification(what: int) -> void:
	if what == NOTIFICATION_VISIBILITY_CHANGED or what == NOTIFICATION_ENTER_TREE:
		if is_instance_valid(wax):
			wax.set_instance_shader_parameter("glow", 1.0 if is_visible_in_tree() else 0.0)


func _process(delta: float) -> void:
	if not is_visible_in_tree():
		return
	if _scale == Vector3.ZERO:
		_scale = global_basis.get_scale()
	global_basis = Basis.from_scale(_scale * Vector3(1.0 + 0.35 * duck, 1.0 - 0.6 * duck, 1.0 + 0.35 * duck))
	if frames.is_empty():
		return
	_time += delta
	var i := int(_time * CandleModel.FPS) % frames.size()
	if mesh != frames[i]:
		mesh = frames[i]
