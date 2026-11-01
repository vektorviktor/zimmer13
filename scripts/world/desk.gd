class_name Desk
extends Dresser
## Schreibtisch (ZIM-154), selbst gebaut von tools/build_desk.py im Look von Kommode und Bücherregal (Holz der
## Vertäfelung, gebackene Verschattung und Normale). Zwei Fassungen:
##   „direktion“    Büro der Direktion, 2,10 × 1,05 m: zwei Unterschränke mit je drei Schubladen, Mittelschublade über
##                  dem Knieraum, grüne Lederauflage mit Goldprägung; davor der rote Ledersessel (Armchair)
##   „sekretariat“  Sekretariat, 1,40 × 0,75 m: ein Unterschrank rechts, Wange links, Mittelschublade, Platte aus Holz
## Die Schubladen verhalten sich wie die der Kommode (fahren mit Inhalt auf und zu, Spinnen, gespeichert in der Gruppe
## dressers), finden aber nur Festes (fixed), sonst sind sie leer. Gezählt von oben: erst die Mittelschublade, dann
## je Unterschrank von oben nach unten, links zuerst. Schlüsselschilder sind nur Zier – Abschließen ist ZIM-6.
## Lage der Schubladen und Kollision kommen aus <Modell>.json (Bauskript). Ursprung mittig auf dem Boden, +Z = vorn.

const DESK_MODEL := "res://assets/models/desk_%s.glb"
const DESK_LAYOUT := "res://assets/models/desk_%s.json"
const DESK_TEX := "res://assets/textures/desk_%s"
## Abstand Vorderkante Tisch – Vorderkante Sessel: die Armlehnen passen nicht unter die Platte, die Mittelschublade
## soll vor dem Sessel aufgehen
const CHAIR_GAP := 0.3
## Gold der Prägung: wie die Messingteile im Haus nur teils metallisch
const GOLD_METALLIC := 0.8
const DESK_EMPTY := ["Leer.", "Ein paar Büroklammern, sonst nichts.", "Unbeschriebene Briefbögen mit dem Hotelwappen.",
	"Ein eingetrockneter Füller. Sonst leer.", "Leere Aktendeckel."]

var variant := "direktion"

static var _layouts := {}
static var _desk_parts := {}
static var _leather := {}


func _init(p_variant: String = "direktion") -> void:
	variant = p_variant


## Lage aus dem Bauskript: size, front_z, front_t, tray_lift, wall, drawers, boxes
static func layout(v: String) -> Dictionary:
	if not _layouts.has(v):
		_layouts[v] = JSON.parse_string(FileAccess.get_file_as_string(DESK_LAYOUT % v))
	return _layouts[v]


## Außenmaß der Platte (Breite, Höhe, Tiefe)
static func dims(v: String) -> Vector3:
	var s: Array = layout(v)["size"]
	return Vector3(s[0], s[1], s[2])


func _build() -> void:
	add_to_group("desks")
	loot = false
	empty_lines = DESK_EMPTY
	var lay := layout(variant)
	size = dims(variant)
	var parts := _parts_of(variant)
	var wood := Mat.hotel_wood((DESK_TEX % variant) + "_ao.png", (DESK_TEX % variant) + "_normal.png")
	_part(self, parts["carcass"], wood)
	if parts.has("leather"):
		_part(self, parts["leather"], _leather_of(variant))
	for b: Array in lay["boxes"]:
		Geo.add_box_shape(self, Vector3(b[0], b[1], b[2]), Vector3(b[3], b[4], b[5]))
	var front_z := float(lay["front_z"])
	var front_t := float(lay["front_t"])
	var lift := float(lay["tray_lift"])
	var wall := float(lay["wall"])
	var back := front_z - front_t   # Rückseite der Front = Vorderkante des Kastens
	for d: Dictionary in lay["drawers"]:
		var inner := _vec(d["inner"])
		var out := _vec(d["tray_out"])
		var fr: Array = d["front"]
		var drawer := add_drawer(float(d["y"]), float(d["x"]), inner, float(d["slide"]), back)
		_part(drawer, parts[d["mesh"]], wood)
		_part(drawer, parts[d["pulls"]], null)
		Geo.add_box_shape(drawer, Vector3(fr[0], fr[1], front_t), Vector3(0, float(d["h"]) / 2.0, front_z - front_t / 2.0))
		var zm := back - out.z / 2.0
		Geo.add_box_shape(drawer, Vector3(out.x, wall, out.z), Vector3(0, lift + wall / 2.0, zm))
		Geo.add_box_shape(drawer, Vector3(out.x, out.y, wall), Vector3(0, lift + out.y / 2.0, back - out.z + wall / 2.0))
		for side in [-1.0, 1.0]:
			Geo.add_box_shape(drawer, Vector3(wall, out.y, out.z), Vector3(side * (out.x - wall) / 2.0, lift + out.y / 2.0, zm))
	if variant == "direktion":
		var chair := Armchair.new()
		chair.position = Vector3(0, 0, size.z / 2.0 + CHAIR_GAP + Armchair.SEAT_FRONT_Z)
		chair.rotation.y = PI
		add_child(chair)


## Die Schubladen stehen in der Lage schon von oben gezählt
func _top_index(i: int) -> int:
	return i


static func _vec(a: Array) -> Vector3:
	return Vector3(a[0], a[1], a[2])


## Teile des Modells einer Fassung: Name → Mesh
static func _parts_of(v: String) -> Dictionary:
	if not _desk_parts.has(v):
		var parts := {}
		var scene: Node = (load(DESK_MODEL % v) as PackedScene).instantiate()
		for mi: MeshInstance3D in scene.find_children("*", "MeshInstance3D", true, false):
			parts[String(mi.name)] = mi.mesh
		scene.free()
		_desk_parts[v] = parts
	return _desk_parts[v]


## Lederauflage: Farbe, Prägung und Abrieb über die ganze Fläche (Mat.pbr_model), die Narbung als Kachel über den
## zweiten UV-Satz (Detail, multipliziert), die Maske hält sie von der Prägung fern
static func _leather_of(v: String) -> StandardMaterial3D:
	if not _leather.has(v):
		var base := (DESK_TEX % v) + "_leather"
		var m := Mat.pbr_model(base, GOLD_METALLIC).duplicate() as StandardMaterial3D
		m.detail_enabled = true
		m.detail_uv_layer = BaseMaterial3D.DETAIL_UV_2
		m.detail_blend_mode = BaseMaterial3D.BLEND_MODE_MUL
		m.detail_mask = load(base + "_mask.png")
		m.detail_albedo = Mat._mipmapped(base + "_grain_albedo.png", false)
		m.detail_normal = Mat._mipmapped(base + "_grain_normal.png", true)
		_leather[v] = m
	return _leather[v]
