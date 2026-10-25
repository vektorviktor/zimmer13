class_name CandleFlame
extends MeshInstance3D
## Flamme einer Kerze (CandleModel.flame): zeigt die Bilder der Flackeranimation der Reihe nach, jede Flamme mit
## eigenem Versatz. Sie steht immer senkrecht – auch an einer gekippten Kerze in der Hand oder einer, die liegt.
## Unsichtbar steht sie still. Das Wachs darunter (wax, shaders/candle_wax.gdshader) glüht, solange sie sichtbar ist.

var frames: Array[ArrayMesh] = []
var wax: GeometryInstance3D
var _time := randf() * 10.0


func _notification(what: int) -> void:
	if what == NOTIFICATION_VISIBILITY_CHANGED or what == NOTIFICATION_ENTER_TREE:
		if is_instance_valid(wax):
			wax.set_instance_shader_parameter("glow", 1.0 if is_visible_in_tree() else 0.0)


func _process(delta: float) -> void:
	if not is_visible_in_tree():
		return
	global_basis = Basis.from_scale(global_basis.get_scale())
	if frames.is_empty():
		return
	_time += delta
	var i := int(_time * CandleModel.FPS) % frames.size()
	if mesh != frames[i]:
		mesh = frames[i]
