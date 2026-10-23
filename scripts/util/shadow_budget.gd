class_name ShadowBudget
extends Node
## Godot hält Licht nur mit Schatten an Wänden auf – eine Lampe ohne Schatten scheint durch alles hindurch. Darum
## werfen alle Lampen dauerhaft Schatten, die meisten aber nur vom Bau (Wände, Böden, Decken, Türen auf der
## Sichtebene LAYER, shadow_caster_mask): Das sind wenige Flächen, und weil sie sich nicht bewegen, rendert Godot
## diese Schatten kaum neu. Nur die FULL Lampen um die Kamera nehmen alles in den Schatten (Möbel, Gäste, die
## eigene Figur) – die Auswahl wird laufend nachgeführt. Wechselt dort eine Lampe, ändern sich nur Möbel- und
## Figurenschatten, nicht das Licht im Raum. Es zählt, wie tief die Kamera in ihrer Reichweite steht (Abstand −
## Reichweite), und wer schon alles nimmt, behält es mit STICKY Vorsprung – sonst schaltete ein halber Meter vor und
## zurück hin und her.

## Sichtebene des Baus (Ebene 15) – zusätzlich zur Ebene 1, sehen und beleuchten bleibt gleich
const LAYER := 1 << 14
const FULL := 12
const FULL_DISTANCE := 18.0
const STICKY := 1.5
const INTERVAL := 0.25
const ALL := 0xFFFFFFFF

var _timer := 0.0


## Alle Meshes in node (mit node selbst) werfen Schatten auch für Lampen, die nur den Bau nehmen.
static func structure(node: Node) -> void:
	if node is GeometryInstance3D:
		(node as GeometryInstance3D).layers |= LAYER
	for child in node.get_children():
		structure(child)


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
		if not light.shadow_enabled:
			light.shadow_enabled = true
		var d := light.global_position.distance_to(origin)
		if light.is_visible_in_tree() and d < FULL_DISTANCE:
			var full := light.shadow_caster_mask == ALL
			candidates.append([d - light.omni_range - (STICKY if full else 0.0), light])
		elif light.shadow_caster_mask != LAYER:
			light.shadow_caster_mask = LAYER
	candidates.sort_custom(func(a: Array, b: Array) -> bool: return a[0] < b[0])
	for i in candidates.size():
		var light: OmniLight3D = candidates[i][1]
		var mask := ALL if i < FULL else LAYER
		if light.shadow_caster_mask != mask:
			light.shadow_caster_mask = mask
