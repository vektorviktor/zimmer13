class_name CandleFlame
extends MeshInstance3D
## Flamme einer Kerze (CandleModel.flame): zeigt die Bilder der Flackeranimation der Reihe nach, jede Flamme mit
## eigenem Versatz. Unsichtbar steht sie still.

var frames: Array[ArrayMesh] = []
var _time := randf() * 10.0


func _process(delta: float) -> void:
	if frames.is_empty() or not is_visible_in_tree():
		return
	_time += delta
	var i := int(_time * CandleModel.FPS) % frames.size()
	if mesh != frames[i]:
		mesh = frames[i]
