class_name Wainscot
## Wandvertäfelung (Spielkonzept 7.2): Sockelleiste, Brett mit Rahmenfeldern und Brüstungsleiste auf HEIGHT, aus dem
## Bausatz von tools/build_wainscot.py im festen Raster MODULE gesetzt. LevelBuilder._wainscot meldet je Wandseite die
## freien Stücke (zwischen Ecken, anstoßenden Wänden, Türen, Holzpfeilern) und die Stücke unter Fenstern; je Stück so
## viele ganze Felder wie passen, mittig, der Rest als gestrecktes Passstück („plain“) an beiden Enden – kleine Reste
## (bis STRETCH_MAX je Ende) strecken stattdessen die Felder. Unter Fenstern „low“ ohne Leiste (dort sitzen Bank und
## Schürze des Rahmens). Alle Teile als MultiMesh je Zelle von CELL Metern (Sichtprüfung je Zelle), INSTANCE_CUSTOM:
## xy verschiebt die Holztextur (jedes Feld ein anderer Ausschnitt), z = Streckung (die Faser bleibt unverzerrt).
## Kein Schatten (die Verschattung ist gebacken), nicht im Spielstand. Kollision: ein dünner Kasten je Stück bis FRONT vor
## der Wand (ein Körper je Stockwerk, Meta „wainscot“) – Flecken, Eier und Deko landen so auf dem Brett statt dahinter;
## das Rinnsal eines Wandflecks läuft unten vor RAIL_FRONT (TraceMark._spread_wall).

const MODEL := "res://assets/models/wainscot.glb"
## = MODULE_W und TOP in tools/build_wainscot.py
const MODULE := 0.8
const HEIGHT := 0.9
const CELL := 16.0
const STRETCH_MAX := 0.03
## Kürzere Reste fallen weg (Spalt hinter einer Zarge)
const MIN_PIECE := 0.02
## So weit verschiebt sich die Holztextur je Instanz höchstens (Meter × Kacheln, beliebig)
const SHIFT := 7.0
## Kollision: so weit vor der Wand (Brett 8 mm + 4 mm), so tief in ihr (= BACK im Bauskript); Höhe unter Fenstern
const FRONT := 0.012
const BACK := 0.015
const LOW_HEIGHT := 0.86
## Vor der Brüstungsleiste (22 mm) – so weit vor der Wand läuft ein Rinnsal über die Vertäfelung
const RAIL_FRONT := 0.0235

static var _meshes := {}   # Teil → Mesh

var _instances := {}   # Vector3i(Zelle x, Zelle z, Teil) → Array: [Transform3D, Color]
var _boxes: Array = []   # [Mitte, Größe] der Kollisionskästen


## Stück auf einer Wandfläche: Punkt der Fläche bei Länge 0 (origin, auf Bodenhöhe), Richtung der Wand along, Normale
## out; von a bis b entlang along. low = unter einem Fenster.
func add_run(origin: Vector3, along: Vector3, out: Vector3, a: float, b: float, low: bool) -> void:
	var length := b - a
	if length < MIN_PIECE:
		return
	var h := LOW_HEIGHT if low else HEIGHT
	var depth := FRONT + BACK
	var size := Vector3(length, h, depth) if absf(along.x) > 0.5 else Vector3(depth, h, length)
	_boxes.append([origin + along * (a + b) / 2.0 + out * (FRONT - BACK) / 2.0 + Vector3.UP * h / 2.0, size])
	if low:
		_put("low", origin, along, out, a, length)
		return
	var n := floori((length + 0.0005) / MODULE)
	if n == 0:
		_put("plain", origin, along, out, a, length)
		return
	var rest := (length - n * MODULE) / 2.0
	if rest <= STRETCH_MAX:
		var w := length / n
		for i in n:
			_put("panel", origin, along, out, a + i * w, w)
		return
	_put("plain", origin, along, out, a, rest)
	for i in n:
		_put("panel", origin, along, out, a + rest + i * MODULE, MODULE)
	_put("plain", origin, along, out, b - rest, rest)


## Baut die MultiMeshes und den Kollisionskörper unter parent.
func finish(parent: Node3D) -> void:
	_load_kit()
	if not _boxes.is_empty():
		var body := StaticBody3D.new()
		body.name = "Vertaefelung"
		body.collision_mask = 0
		body.set_meta("wainscot", true)
		parent.add_child(body)
		for box: Array in _boxes:
			Geo.add_box_shape(body, box[1], box[0])
		_boxes.clear()
	var material := Mat.wainscot()
	for key: Vector3i in _instances:
		var list: Array = _instances[key]
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.use_custom_data = true
		mm.mesh = _meshes[["panel", "plain", "low"][key.z]]
		mm.instance_count = list.size()
		for i in list.size():
			mm.set_instance_transform(i, list[i][0])
			mm.set_instance_custom_data(i, list[i][1])
		var mmi := MultiMeshInstance3D.new()
		mmi.name = "Vertaefelung"
		mmi.multimesh = mm
		mmi.material_override = material
		mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		parent.add_child(mmi)
	_instances.clear()


## Ein Teil von t bis t + width. Die Modul-x zeigt entlang along – oder, wo das gespiegelt wäre (Fläche nach −Z bzw.
## +X), rückwärts vom Ende her: MultiMesh-Instanzen mit negativer Determinante würden von innen gezeichnet.
func _put(part: String, origin: Vector3, along: Vector3, out: Vector3, t: float, width: float) -> void:
	var stretch := width / MODULE
	var x := along
	var start := origin + along * t
	if along.cross(Vector3.UP).dot(out) < 0.0:
		x = -along
		start = origin + along * (t + width)
	var xf := Transform3D(Basis(x * stretch, Vector3.UP, out), start)
	var h := hash(Vector3i(roundi(start.x * 100.0), roundi(start.y * 100.0), roundi(start.z * 100.0)))
	var shift := Color(float(h & 1023) / 1023.0 * SHIFT, float((h >> 10) & 1023) / 1023.0 * SHIFT, stretch, 0.0)
	var mid := start + x * width * 0.5
	var key := Vector3i(floori(mid.x / CELL), floori(mid.z / CELL), ["panel", "plain", "low"].find(part))
	if not _instances.has(key):
		_instances[key] = []
	_instances[key].append([xf, shift])


static func _load_kit() -> void:
	if not _meshes.is_empty():
		return
	var scene: Node = (load(MODEL) as PackedScene).instantiate()
	for mi: MeshInstance3D in scene.find_children("*", "MeshInstance3D", true, false):
		_meshes[String(mi.name)] = mi.mesh
	scene.free()
