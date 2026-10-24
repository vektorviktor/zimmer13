class_name ShadowBudget
extends Node
## Godot hält Licht nur mit Schatten an Wänden auf – eine Lampe ohne Schatten scheint durch alles hindurch. Darum
## werfen alle Lampen dauerhaft Schatten, die meisten aber nur vom Bau (Sichtebene LAYER, shadow_caster_mask). Godot
## rendert Punktlicht-Schatten jedes Bild neu (auch wenn sich nichts bewegt), und jedes Mesh kostet je Lampe sechs
## Zeichenaufrufe. Darum liegt auf LAYER nicht der Bau selbst, sondern merge(): Wände, Böden und Decken je Kachel
## (TILE) zu einem unsichtbaren Mesh zusammengefasst, das nur Schatten wirft. Nur Türen (sie gehen auf und zu) liegen
## selbst dort (structure). Die FULL Lampen um die Kamera nehmen alles in den Schatten (Möbel, Gäste, die eigene
## Figur) – die Auswahl wird laufend nachgeführt. Wechselt dort eine Lampe, ändern sich nur Möbel- und Figurenschatten,
## nicht das Licht im Raum. Es zählt, wie tief die Kamera in ihrer Reichweite steht (Abstand − Reichweite), und wer
## schon alles nimmt, behält es mit STICKY Vorsprung – sonst schaltete ein halber Meter vor und zurück hin und her.
## Lichter, die die Kamera nach dem Grundriss nicht erreichen kann (hinter geschlossenen Türen, auf anderen
## Stockwerken – LightRooms), schaltet es für die Darstellung ab: Sie konkurrierten sonst um die 88 Plätze im
## Schattenatlas, und wer keinen bekommt, scheint durch alle Wände. Weil alle erreichbaren Lampen Wand-Schatten
## werfen, sieht man das Abschalten nicht. An/Aus, Energie und MonsterDirector.light_at bleiben unberührt.

## Sichtebene der Schatten vom Bau (Ebene 15)
const LAYER := 1 << 14
## Kantenlänge einer Kachel (m) – größer: weniger Zeichenaufrufe, aber mehr Dreiecke je Schattenseite
const TILE := 10.0
const FULL := 12
const FULL_DISTANCE := 18.0
const STICKY := 1.5
const INTERVAL := 0.25
## Volle Lampen: alles außer dem zusammengefassten Bau – die echten Wände nehmen sie ohnehin
const ALL := 0xFFFFFFFF & ~LAYER
## Lichter, die sich weiter bewegt haben (m), bekommen ihren Bereich neu
const MOVE := 0.25

## Bereiche fürs Licht (LevelBuilder.light_rooms) – ohne sie gelten alle Lichter als erreichbar
var rooms: LightRooms
## Eine Tür geht auf oder zu (Door.set_open): im nächsten Bild neu bestimmen, nicht erst nach INTERVAL – sonst käme
## das Licht durch den Spalt sichtbar zu spät
static var wake := false
var _timer := 0.0


## Alle Meshes in node (mit node selbst) werfen Schatten auch für Lampen, die nur den Bau nehmen – für Bewegliches
## (Türen); Festes kommt über merge().
static func structure(node: Node) -> void:
	if node is GeometryInstance3D:
		(node as GeometryInstance3D).layers |= LAYER
	for child in node.get_children():
		structure(child)


## Die Meshes in parts (und darunter, schon im Baum) je Kachel und Stockwerk zu einem Mesh in Weltkoordinaten
## zusammenfassen, das nur Schatten wirft und nur auf LAYER liegt – unter parent (ohne eigene Lage). Ein Mesh kommt
## ganz in die Kachel seiner Mitte.
static func merge(parts: Array[Node], parent: Node3D) -> void:
	var tiles := {}
	var stack: Array[Node] = parts.duplicate()
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		stack.append_array(node.get_children())
		var mi := node as MeshInstance3D
		if mi == null or mi.mesh == null:
			continue
		var c := mi.global_transform * mi.get_aabb().get_center()
		var key := Vector3i(floori(c.x / TILE), floori(c.y / 4.0), floori(c.z / TILE))
		if not tiles.has(key):
			tiles[key] = []
		(tiles[key] as Array).append(mi)
	var holder := Node3D.new()
	holder.name = "Schattenbau"
	parent.add_child(holder)
	for key in tiles:
		var verts := PackedVector3Array()
		var indices := PackedInt32Array()
		for mi: MeshInstance3D in tiles[key]:
			var xf := mi.global_transform
			for s in mi.mesh.get_surface_count():
				var arrays := mi.mesh.surface_get_arrays(s)
				var base := verts.size()
				var points: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
				for p in points:
					verts.append(xf * p)
				var idx = arrays[Mesh.ARRAY_INDEX]
				if idx == null or (idx as PackedInt32Array).is_empty():
					for i in points.size():
						indices.append(base + i)
				else:
					for i: int in idx:
						indices.append(base + i)
		var arrays := []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = verts
		arrays[Mesh.ARRAY_INDEX] = indices
		var mesh := ArrayMesh.new()
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		var proxy := MeshInstance3D.new()
		proxy.mesh = mesh
		proxy.layers = LAYER
		proxy.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY
		holder.add_child(proxy)


func _process(delta: float) -> void:
	_timer -= delta
	if wake:
		wake = false
		_timer = 0.0
	if _timer > 0.0:
		return
	_timer = INTERVAL
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return
	var origin := cam.global_position
	var reach := rooms.reach(origin) if rooms else PackedByteArray()
	var candidates: Array = []
	for node in get_tree().get_nodes_in_group("lamps"):
		var light := node as OmniLight3D
		if light == null:
			continue
		var shown := _show(light, reach)
		if light.has_meta("no_shadow"):
			continue
		if not shown:
			if light.shadow_caster_mask != LAYER:
				light.shadow_caster_mask = LAYER
			continue
		if not light.shadow_enabled:
			light.shadow_enabled = true
		var d := light.global_position.distance_to(origin)
		if light.is_visible_in_tree() and d < FULL_DISTANCE:
			var full := light.shadow_caster_mask == ALL
			candidates.append([d - light.omni_range - (STICKY if full else 0.0), light])
		elif light.shadow_caster_mask != LAYER:
			light.shadow_caster_mask = LAYER
	for node in get_tree().get_nodes_in_group("light_source"):
		if node is Light3D and not node.is_in_group("lamps"):
			_show(node, reach)
	candidates.sort_custom(func(a: Array, b: Array) -> bool: return a[0] < b[0])
	for i in candidates.size():
		var light: OmniLight3D = candidates[i][1]
		var mask := ALL if i < FULL else LAYER
		if light.shadow_caster_mask != mask:
			light.shadow_caster_mask = mask


## Licht sichtbar lassen, wenn sein Bereich in reach liegt (leer = alle), sonst für die Darstellung abschalten:
## beleuchtet nichts (light_cull_mask 0), kein Schatten – die eigenen Werte bleiben in Meta und kommen zurück.
## Der Bereich wird neu bestimmt, wenn sich das Licht um mehr als MOVE bewegt hat.
func _show(light: Light3D, reach: PackedByteArray) -> bool:
	var shown := true
	if not reach.is_empty():
		var p := light.global_position
		if not light.has_meta("light_room") or (light.get_meta("light_room_at") as Vector3).distance_squared_to(p) > MOVE * MOVE:
			light.set_meta("light_room", rooms.region_at(p, light))
			light.set_meta("light_room_at", p)
		var region: int = light.get_meta("light_room")
		shown = region < 0 or reach[region] != 0
	if shown:
		if light.has_meta("hidden_mask"):
			light.light_cull_mask = light.get_meta("hidden_mask")
			light.shadow_enabled = light.get_meta("hidden_shadow")
			light.remove_meta("hidden_mask")
			light.remove_meta("hidden_shadow")
	elif not light.has_meta("hidden_mask"):
		light.set_meta("hidden_mask", light.light_cull_mask)
		light.set_meta("hidden_shadow", light.shadow_enabled)
		light.light_cull_mask = 0
		light.shadow_enabled = false
	return shown
