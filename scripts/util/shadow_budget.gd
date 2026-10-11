class_name ShadowBudget
extends Node
## Schatten sind bei vielen Lampen der teuerste Teil des Bildes (jede Punktlampe rendert
## sechs Schattenseiten). Nur die nächsten MAX_SHADOWS eingeschalteten Lampen um die
## Kamera werfen Schatten – die Auswahl wird laufend nachgeführt.

const MAX_SHADOWS := 6
const MAX_DISTANCE := 18.0
const INTERVAL := 0.25

var _timer := 0.0


func _process(delta: float) -> void:
	_timer -= delta
	if _timer > 0.0:
		return
	_timer = INTERVAL
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return
	var origin := cam.global_position
	var candidates: Array = []
	for node in get_tree().get_nodes_in_group("lamps"):
		var light := node as OmniLight3D
		if light == null:
			continue
		var d := light.global_position.distance_to(origin)
		if light.is_visible_in_tree() and d < MAX_DISTANCE:
			candidates.append([d, light])
		elif light.shadow_enabled:
			light.shadow_enabled = false
	candidates.sort_custom(func(a: Array, b: Array) -> bool: return a[0] < b[0])
	for i in candidates.size():
		(candidates[i][1] as OmniLight3D).shadow_enabled = i < MAX_SHADOWS
