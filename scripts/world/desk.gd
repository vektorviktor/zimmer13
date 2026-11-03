class_name Desk
extends Dresser
## Schreibtisch (ZIM-154), selbst gebaut von tools/build_desk.py im Look von Kommode und Bücherregal (Holz der
## Vertäfelung, gebackene Verschattung und Normale). Zwei Fassungen:
##   „direktion“    Büro der Direktion, 2,10 × 1,05 m: zwei Unterschränke mit je drei Schubladen, Mittelschublade über
##                  dem Knieraum, grüne Lederauflage mit Goldprägung; davor der rote Ledersessel (Armchair)
##   „sekretariat“  Sekretariat, 1,40 × 0,75 m: ein Unterschrank rechts, Wange links, Mittelschublade, Platte aus Holz
## Die Schubladen verhalten sich wie die der Kommode (fahren mit Inhalt auf und zu, Spinnen, gespeichert in der Gruppe
## dressers), finden aber nur Festes (fixed), sonst sind sie leer. Gezählt von oben: erst die Mittelschublade, dann
## je Unterschrank von oben nach unten, links zuerst. Schlüsselschilder sind nur Zier. Im Sekretariat hat die zweite
## Schublade (DirectorOffice.CODE_DRAWER) ein Zahlenschloss mit vier Rädern unter dem Schild: zu, bis der Code stimmt
## (DirectorOffice.open_lock), darin der Generalschlüssel (Spielkonzept 2.10, 6.19; ZIM-6). Aufgegangen ist sie, sobald
## sie einmal aufgezogen wurde (searched) – kein eigenes Feld im Spielstand. In der Mittelschublade
## (DirectorOffice.PHOTO_DRAWER) liegt fest das Foto von 2005 mit gesprungenem Glas (PhotoWall.found_photo, 2.10, ZIM-117).
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

## Zahlenschloss (nur Sekretariat): Räder 4 × Breite, Abstand; Platte; Abstand der Mitte unter der Mitte der Front
const LOCK_WHEEL := Vector2(0.009, 0.0075)   # Radius, Breite
const LOCK_PITCH := 0.011
const LOCK_PLATE := Vector3(0.056, 0.024, 0.004)
const LOCK_DROP := 0.036

var variant := "direktion"
## Schublade mit Zahlenschloss (von oben gezählt), -1 = keine
var code_drawer := -1
var _code_open := false   # in dieser Sitzung aufgeschlossen (bis zum ersten Aufziehen; danach zählt searched)

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
	if variant == "sekretariat" and lay["drawers"].size() > DirectorOffice.CODE_DRAWER:
		code_drawer = DirectorOffice.CODE_DRAWER
		var d: Dictionary = lay["drawers"][code_drawer]
		_code_lock(_drawers[code_drawer], Vector3(0, float(d["h"]) / 2.0 - LOCK_DROP, front_z))
		_found_photo(_drawers[DirectorOffice.PHOTO_DRAWER], lay["drawers"][DirectorOffice.PHOTO_DRAWER], back, lift + wall)
	if variant == "direktion":
		var chair := Armchair.new()
		chair.position = Vector3(0, 0, size.z / 2.0 + CHAIR_GAP + Armchair.SEAT_FRONT_Z)
		chair.rotation.y = PI
		add_child(chair)


## Die Schubladen stehen in der Lage schon von oben gezählt
func _top_index(i: int) -> int:
	return i


## Zahlenschloss auf der Front (at = Mitte der Vorderfläche, lokal zur Schublade): Messingplatte, darin vier Räder mit
## dunklen Ziffernringen, die halb herausstehen.
func _code_lock(drawer: Node3D, at: Vector3) -> void:
	var brass := Mat.metal(GrandStair.BRASS)
	Geo.mesh(drawer, Geo.box(LOCK_PLATE), brass, at + Vector3(0, 0, LOCK_PLATE.z / 2.0))
	var wheel_mat := Mat.metal(Color(0.32, 0.27, 0.18))
	for k in 4:
		var x := (k - 1.5) * LOCK_PITCH
		var wheel := Geo.mesh(drawer, Geo.cylinder(LOCK_WHEEL.x, LOCK_WHEEL.y, 12), wheel_mat,
			at + Vector3(x, 0, LOCK_PLATE.z))
		wheel.rotation.z = PI / 2.0   # Achse quer zur Schublade, man dreht von oben


## Das Foto von 2005 flach in die Schublade (Sekretariat): Bild nach oben, Oberkante nach hinten, auf dem Boden des
## Kastens (floor) mittig vor der Rückwand – es fährt als Kind der Schublade mit.
func _found_photo(drawer: Node3D, d: Dictionary, back: float, floor_y: float) -> void:
	var frame := PhotoWall.found_photo()
	var out := _vec(d["tray_out"])
	frame.position = Vector3(0.04, floor_y + 0.001, back - out.z / 2.0)
	frame.rotation = Vector3(-PI / 2.0, 0.0, 0.015)   # leicht schief, mehr lässt die Tiefe nicht zu
	drawer.add_child(frame)


## Ist die Schublade i noch mit dem Zahlenschloss zu?
func code_locked(i: int) -> bool:
	return i == code_drawer and not _code_open and not searched[i]


## Code stimmt (DirectorOffice.try_code): Schloss offen, die Schublade fährt auf.
func unlock_code(i: int, player: Player) -> void:
	_code_open = true
	if not is_open[i]:
		super.use_drawer(i, player)


func drawer_prompt(i: int, player: Player) -> String:
	if code_locked(i):
		return "Hände voll" if player.hands_blocked() else "Zahlenschloss [E]"
	return super.drawer_prompt(i, player)


func use_drawer(i: int, player: Player) -> void:
	if not code_locked(i):
		super.use_drawer(i, player)
	elif player.hands_blocked():
		Game.say("Mit vollen Händen geht das nicht.")
	elif Game.director_office:
		Game.director_office.open_lock(self, i, player)


## Das Foto liegt schon darin – kein „Leer.“ beim ersten Aufziehen.
func _roll_loot(i: int) -> void:
	if variant == "sekretariat" and i == DirectorOffice.PHOTO_DRAWER:
		return
	super._roll_loot(i)


## Fund: In der Schublade mit Zahlenschloss liegt der Generalschlüssel (6.19), sonst wie die Kommode (nur Festes).
func _roll(i: int) -> Item:
	if i == code_drawer:
		return Item.create(Item.Kind.KEY, RoomAccess.GENERAL_KEY)
	return super._roll(i)


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
