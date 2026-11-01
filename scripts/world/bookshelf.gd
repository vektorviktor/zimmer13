class_name Bookshelf
extends StaticBody3D
## Bücherregal der Bibliothek (ZIM-152) im Look der Kommode: Sockel, Pfosten mit Furchen, Rundstab, Fries mit Mulden,
## Kranz, dazwischen offene Fächer mit `levels` Ebenen übereinander. Eine Zeile beliebiger Länge: Zwischenwände im
## Raster `pitch` (1 oder 2 m), die Fächer gleichmäßig gestreckt, bis die Länge aufgeht. Ein Ende ist frei (das Profil
## läuft um die Ecke) oder stößt an einer Innenecke auf ein anderes Regal (Gehrung, `corner_left`/`corner_right`).
## Ursprung mittig im Korpus auf dem Boden, lokal +Z = Vorderseite, x entlang der Zeile.
##
## Teile aus tools/build_bookshelf.py, je Höhe ein Modell mit gebackener Verschattung und Normale. Gesetzt als
## MultiMesh je Teil: die Holz-UV der waagerechten Flächen läuft über INSTANCE_CUSTOM (psx_photo, instance_shift wie
## die Vertäfelung) über die ganze Zeile durch, auch durch gestreckte Fächer. Maße = Bauskript.

const MODEL := "res://assets/models/bookshelf_%d.glb"
const AO := "res://assets/textures/bookshelf_%d_ao.png"
const NORMAL := "res://assets/textures/bookshelf_%d_normal.png"
## Korpus ohne Profil; Seite am Ende und Zwischenwand (massiv)
const DEPTH := 0.30
const POST := 0.09
const DIVIDER := 0.06
## Teilung (m) → Fach im Modell; dessen Breite = Teilung minus Zwischenwand
const SPANS := {1: "span1", 2: "span2"}
const PLINTH := 0.10
const SHELF_T := 0.022
const SHELF_SET := 0.015
const BACK_WALL := 0.012
## Rundstab, Fries und Kranz über dem obersten Fach
const CROWN := 0.161
## Raster der Fachböden: mit 4 Ebenen 2,10 m hoch (Wunsch des Nutzers 1.11.), mit 5 Ebenen 2,56 m
const PITCH := (2.10 - PLINTH - CROWN) / 4.0
## weitester Vorsprung des Profils (Kranz) und des Sockels
const OVERHANG := 0.038
const PLINTH_OVER := 0.02
## Abstand des Rückens von der Hinterkante des Rechtecks im Plan (die Vertäfelung steht vor der Wand)
const BACK_GAP := 0.03
## schmalstes Fach – kürzere Zeilen baut LevelBuilder nicht
const MIN_SPAN := 0.25

static var _parts := {}       # Ebenen → {Teil → Mesh}
static var _materials := {}   # Ebenen → Material

var levels := 4
var pitch := 1
## Korpus von Kante zu Kante (ohne Profil); an einer Innenecke bis zur Vorderseite des anderen Regals
var length := 1.0
var corner_left := false
var corner_right := false
## Versatz der Maserung (u, v) für die ganze Zeile
var grain := Vector2.ZERO


static func make(p_levels: int, p_pitch: int, p_length: float, left: bool = false, right: bool = false) -> Bookshelf:
	var shelf := Bookshelf.new()
	shelf.levels = p_levels
	shelf.pitch = p_pitch
	shelf.length = p_length
	shelf.corner_left = left
	shelf.corner_right = right
	return shelf


## Oberkante der Deckplatte
static func height(p_levels: int) -> float:
	return PLINTH + p_levels * PITCH + CROWN


## Kürzeste Zeile: zwei Enden und ein Fach
static func min_length() -> float:
	return 2.0 * POST + MIN_SPAN


func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	add_to_group("bookshelves")
	var x0 := -length / 2.0
	var x1 := length / 2.0
	var inner := length - 2.0 * POST
	var n := maxi(1, roundi((inner + DIVIDER) / pitch))
	var span := (inner - (n - 1) * DIVIDER) / n
	var stretch := span / (pitch - DIVIDER)
	var put := {}   # Teil → [[x, Streckung], …]
	_add(put, "miter_l" if corner_left else "end_l", x0, 1.0)
	var x := x0 + POST
	var spans: Array[float] = []
	for i in n:
		if i > 0:
			_add(put, "divider", x + DIVIDER / 2.0, 1.0)
			x += DIVIDER
		_add(put, SPANS[pitch], x, stretch)
		spans.append(x)
		x += span
	_add(put, "miter_r" if corner_right else "end_r", x1, 1.0)
	var parts := _model(levels)
	var mat := _material(levels)
	for part: String in put:
		var list: Array = put[part]
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.use_custom_data = true
		mm.mesh = parts[part]
		mm.instance_count = list.size()
		for i in list.size():
			var at: float = list[i][0]
			var st: float = list[i][1]
			mm.set_instance_transform(i, Transform3D(Basis.from_scale(Vector3(st, 1, 1)), Vector3(at, 0, 0)))
			mm.set_instance_custom_data(i, Color(at + grain.x, grain.y, st, 0.0))
		var mmi := MultiMeshInstance3D.new()
		mmi.name = part
		mmi.multimesh = mm
		mmi.material_override = mat
		add_child(mmi)
	_collision(x0, x1, spans, span)


func _add(put: Dictionary, part: String, x: float, stretch: float) -> void:
	if not put.has(part):
		put[part] = []
	put[part].append([x, stretch])


## Kästen: Sockel und Kranz über die ganze Zeile (an einer Innenecke bis an die Wand), Rückwand, Seiten,
## Zwischenwände, Fachböden. Die Fächer bleiben hohl, damit Gegenstände darin liegen können.
func _collision(x0: float, x1: float, spans: Array[float], span: float) -> void:
	var open_top := PLINTH + levels * PITCH
	var open_h := open_top - PLINTH
	var top := height(levels)
	for layer in [[0.0, PLINTH, PLINTH_OVER], [open_top, top, OVERHANG]]:
		var lo: float = x0 - (DEPTH if corner_left else layer[2])
		var hi: float = x1 + (DEPTH if corner_right else layer[2])
		var deep: float = DEPTH + layer[2]
		Geo.add_box_shape(self, Vector3(hi - lo, layer[1] - layer[0], deep),
			Vector3((lo + hi) / 2.0, (layer[0] + layer[1]) / 2.0, deep / 2.0 - DEPTH / 2.0))
	Geo.add_box_shape(self, Vector3(x1 - x0, open_h, BACK_WALL), Vector3(0, PLINTH + open_h / 2.0, -DEPTH / 2.0 + BACK_WALL / 2.0))
	for x in [x0 + POST / 2.0, x1 - POST / 2.0]:
		Geo.add_box_shape(self, Vector3(POST, open_h, DEPTH), Vector3(x, PLINTH + open_h / 2.0, 0))
	var zi := -DEPTH / 2.0 + BACK_WALL
	var zs := DEPTH / 2.0 - SHELF_SET
	for i in spans.size():
		if i > 0:
			Geo.add_box_shape(self, Vector3(DIVIDER, open_h, DEPTH), Vector3(spans[i] - DIVIDER / 2.0, PLINTH + open_h / 2.0, 0))
		for k in range(1, levels):
			Geo.add_box_shape(self, Vector3(span, SHELF_T, zs - zi),
				Vector3(spans[i] + span / 2.0, PLINTH + k * PITCH - SHELF_T / 2.0, (zi + zs) / 2.0))


## Teile des Modells einer Höhe: Name → Mesh
static func _model(p_levels: int) -> Dictionary:
	if not _parts.has(p_levels):
		var parts := {}
		var scene: Node = (load(MODEL % p_levels) as PackedScene).instantiate()
		for mi: MeshInstance3D in scene.find_children("*", "MeshInstance3D", true, false):
			parts[String(mi.name)] = mi.mesh
		scene.free()
		_parts[p_levels] = parts
	return _parts[p_levels]


## Holz der Möbel (Mat.hotel_wood) mit gebackener Verschattung und Normale, Maserung je Instanz versetzt
static func _material(p_levels: int) -> ShaderMaterial:
	if not _materials.has(p_levels):
		var m := Mat.hotel_wood(AO % p_levels, NORMAL % p_levels).duplicate() as ShaderMaterial
		m.set_shader_parameter("instance_shift", true)
		_materials[p_levels] = m
	return _materials[p_levels]
