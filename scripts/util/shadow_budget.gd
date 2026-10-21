class_name ShadowBudget
extends Node
## Schatten sind bei vielen Lampen der teuerste Teil des Bildes (jede Punktlampe rendert
## sechs Schattenseiten). Nur MAX_SHADOWS eingeschaltete Lampen um die Kamera werfen Schatten –
## die Auswahl wird laufend nachgeführt. Lampen ohne Schatten scheinen durch Wände: Wechselt eine
## Lampe im Nachbarzimmer die Seite, geht im Flur Licht an oder aus. Deshalb zählt, wie tief die
## Kamera in ihrer Reichweite steht (Abstand − Reichweite), und wer schon Schatten wirft, behält ihn
## mit STICKY Vorsprung – sonst schaltete ein halber Meter vor und zurück hin und her.

const MAX_SHADOWS := 12
const MAX_DISTANCE := 18.0
const STICKY := 1.5
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
		if light == null or light.has_meta("no_shadow"):
			continue
		var d := light.global_position.distance_to(origin)
		if light.is_visible_in_tree() and d < MAX_DISTANCE:
			candidates.append([d - light.omni_range - (STICKY if light.shadow_enabled else 0.0), light])
		elif light.shadow_enabled:
			light.shadow_enabled = false
	candidates.sort_custom(func(a: Array, b: Array) -> bool: return a[0] < b[0])
	for i in candidates.size():
		(candidates[i][1] as OmniLight3D).shadow_enabled = i < MAX_SHADOWS
