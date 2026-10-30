class_name BedModel
## Balkenbett (alle Betten, Einzel- und Doppelbett, 24.10.): Gestell aus acht Balken – vier Pfosten POST × POST an den
## Ecken, dazwischen zwei Längs- und zwei Querbalken BEAM × BEAM mit FREE Luft darunter (unters Bett kriechen), mittig
## auf den Pfosten, die deshalb ringsum (und oben) leicht vorstehen. Die Matratze liegt
## im Rahmen auf einem (unsichtbaren) Lattenrost und ragt bis TOP über die Balken; Kanten und Ecken um MATTRESS_ROUND
## gerundet. Das Kopfteil – zwei Bretter auf zwei schmalen Latten, die im Kopfbalken stecken – ist um HEAD_TILT nach
## hinten geneigt. Holz mit Maserung längs der Faser (Geo.grain_box, Mat.wood – helle Eiche): Pfosten und Latten
## senkrecht, Balken und Bretter der Länge nach, Hirnholz an den Stirnseiten. Bettwäsche (Laken, Kissen) aus
## Fabric_Pattern_08, die Bettdecke rot. Lokal wie HideSpot: Länge x mit dem Kopfende bei head_x, Breite z,
## size (Länge × Breite) = Außenmaß über die Pfosten.

## Pfosten und Balken im Quadrat, Luft unter Längs- und Querbalken
const POST := 0.19
const BEAM := 0.17
const FREE := 0.33
## Oberkante der Pfosten: die Balken sitzen mittig, die Pfosten stehen oben um den halben Unterschied vor (0,51 m –
## so hoch ist auch der Nachttisch)
const POST_TOP := FREE + BEAM + (POST - BEAM) / 2.0
## Matratze: Unterkante (Lattenrost), Oberkante, Rundung; Spalt zum Rahmen je Seite
const MATTRESS_BOTTOM := 0.42
const TOP := 0.6
const MATTRESS_ROUND := 0.04
const MATTRESS_GAP := 0.005
## Kopfteil: Neigung nach hinten (Grad), Brettstärke, Bretter als (Unterkante, Höhe) entlang der Neigung über der
## Oberkante des Kopfbalkens, Bretter so viel schmaler als das Bett
const HEAD_TILT := 15.0
const BOARD := 0.04
const BOARDS: Array[Vector2] = [Vector2(0.18, 0.15), Vector2(0.37, 0.2)]
const BOARD_INSET := 0.1
## Latten des Kopfteils: Breite, Stärke; so tief stecken sie im Kopfbalken, so weit überragen sie das obere Brett;
## Abstand von der Mitte als Anteil der Bettbreite
const HOLDER := Vector2(0.06, 0.03)
const HOLDER_SUNK := 0.1
const HOLDER_OVER := 0.02
const HOLDER_SPREAD := 0.3
## Kissen (Tiefe × Dicke × Breite), im Doppelbett zwei; Bettdecke: Dicke, Umschlag am Kopfende
const PILLOW := Vector3(0.45, 0.13, 0.75)
const BLANKET := 0.06
const BLANKET_FOLD := 0.24
## Maserung: Meter je Kachel längs und quer zur Faser (Fotokachel quadratisch), Hirnholz
const GRAIN := Vector2(1.2, 1.2)
const END_GRAIN := 0.2
## Bettwäsche: Foto, Meter je Kachel, Tönung
const FABRIC_TEX := "res://assets/textures/Fabric_Pattern_08/Fabric_Pattern_08_basecolor.jpg"
const FABRIC_NORMAL := "res://assets/textures/Fabric_Pattern_08/Fabric_Pattern_08_normalogl.jpg"
const FABRIC_METERS := 0.35
const SHEET_COLOR := Color(0.92, 0.9, 0.85)
const BLANKET_COLOR := Color(0.35, 0.08, 0.08)
const FOLD_COLOR := Color(0.41, 0.1, 0.1)

static var _meshes := {}


## Lichte Länge und Breite im Rahmen (so groß ist die Matratze).
static func inner(size: Vector2) -> Vector2:
	return size - Vector2.ONE * (POST + BEAM)


## Baut das Bett unter parent und gibt die Bettdecke zurück (ein Node3D – HideSpot.set_checked zerwühlt sie).
static func build(parent: Node3D, size: Vector2, head_x: float) -> Node3D:
	var hx := size.x / 2.0 - POST / 2.0   # Mitte der Pfosten, Längs- und Querbalken
	var hz := size.y / 2.0 - POST / 2.0
	var frame_top := FREE + BEAM
	var post_top := POST_TOP
	var n := 0
	for x in [-1.0, 1.0]:
		for z in [-1.0, 1.0]:
			beam(parent, Vector3(POST, post_top, POST), Vector3(x * hx, post_top / 2.0, z * hz), 1, n)
			n += 1
	for z in [-1.0, 1.0]:
		beam(parent, Vector3(size.x - 2.0 * POST, BEAM, BEAM), Vector3(0, FREE + BEAM / 2.0, z * hz), 0, n)
		n += 1
	for x in [-1.0, 1.0]:
		beam(parent, Vector3(BEAM, BEAM, size.y - 2.0 * POST), Vector3(x * hx, FREE + BEAM / 2.0, 0), 2, n)
		n += 1
	_headboard(parent, size, head_x, Vector3(head_x * hx, frame_top, 0), n)
	var room := inner(size)
	var mattress := Vector3(room.x - 2.0 * MATTRESS_GAP, TOP - MATTRESS_BOTTOM, room.y - 2.0 * MATTRESS_GAP)
	var linen := Mat.photo(FABRIC_TEX, FABRIC_METERS, FABRIC_NORMAL, "", 0.0, SHEET_COLOR, true)
	Geo.mesh(parent, _rounded(mattress, MATTRESS_ROUND, 0.0), linen, Vector3(0, (TOP + MATTRESS_BOTTOM) / 2.0, 0))
	# Kissen am Kopfende, leicht ans Kopfteil gelehnt – im Doppelbett zwei nebeneinander
	var pillows := 2 if size.y >= HideSpot.DOUBLE_WIDTH else 1
	for i in pillows:
		var z := 0.0 if pillows == 1 else (i - 0.5) * (PILLOW.z + 0.08)
		var x := head_x * (room.x / 2.0 - PILLOW.x / 2.0 - 0.03)
		var pillow := Geo.mesh(parent, _rounded(PILLOW, 0.05, 0.25), linen, Vector3(x, TOP + PILLOW.y / 2.0 - 0.03, z))
		pillow.rotation = Vector3(0, (0.05 if i == 0 else -0.04), head_x * 0.12)
	# Bettdecke vom Fußende bis vor die Kissen, mit Umschlag am Kopfende
	var length := room.x - PILLOW.x - 0.1
	var width := room.y + 0.03
	var blanket := Node3D.new()
	blanket.position = Vector3(-head_x * (room.x - length) / 2.0, TOP, 0)
	parent.add_child(blanket)
	Geo.mesh(blanket, _rounded(Vector3(length, BLANKET, width), 0.025, 0.2), Mat.psx(BLANKET_COLOR), Vector3(0, BLANKET / 2.0 - 0.01, 0))
	Geo.mesh(blanket, _rounded(Vector3(BLANKET_FOLD, 0.045, width + 0.004), 0.02, 0.1), Mat.psx(FOLD_COLOR),
			Vector3(head_x * (length - BLANKET_FOLD) / 2.0, BLANKET + 0.012, 0))
	return blanket


## Höhe der Bettdecke über dem Boden (Oberseite) – dort liegt die Katze.
static func blanket_top() -> float:
	return TOP + BLANKET + 0.01


## Kopfteil: Latten im Kopfbalken (Mitte pivot = Oberkante des Balkens), davor (zur Matratze) die Bretter, alles um
## HEAD_TILT nach hinten (zur Seite head_x) geneigt.
static func _headboard(parent: Node3D, size: Vector2, head_x: float, pivot: Vector3, n: int) -> void:
	var tilt := Node3D.new()
	tilt.position = pivot
	tilt.rotation.z = -head_x * deg_to_rad(HEAD_TILT)
	parent.add_child(tilt)
	var front := -head_x * (HOLDER.y + BOARD) / 2.0
	for b in BOARDS:
		beam(tilt, Vector3(BOARD, b.y, size.y - BOARD_INSET), Vector3(front, b.x + b.y / 2.0, 0), 2, n)
		n += 1
	var top: float = BOARDS[-1].x + BOARDS[-1].y + HOLDER_OVER
	for z in [-1.0, 1.0]:
		beam(tilt, Vector3(HOLDER.y, top + HOLDER_SUNK, HOLDER.x), Vector3(0, (top - HOLDER_SUNK) / 2.0, z * size.y * HOLDER_SPREAD), 1, n)
		n += 1


## Ein Balken (Faser entlang Achse grain), Meshes je Maß und Nummer n geteilt – n verschiebt die Maserung. Auch die
## Bretter des Nachttischs (Nightstand).
static func beam(parent: Node3D, size: Vector3, pos: Vector3, grain: int, n: int) -> void:
	var key := "beam|%s|%d|%d" % [size, grain, n]
	if not _meshes.has(key):
		var offset := Vector2(fposmod(n * 0.37, 1.0), fposmod(n * 0.61, 1.0))
		_meshes[key] = Geo.grain_box(size, grain, GRAIN, END_GRAIN, offset)
	var mi := MeshInstance3D.new()
	mi.mesh = _meshes[key]
	mi.set_surface_override_material(0, Mat.wood(false))
	mi.set_surface_override_material(1, Mat.wood(true))
	mi.position = pos
	parent.add_child(mi)


static func _rounded(size: Vector3, radius: float, puff: float) -> ArrayMesh:
	var key := "round|%s|%.3f|%.2f" % [size, radius, puff]
	if not _meshes.has(key):
		_meshes[key] = Geo.rounded_box(size, radius, 2, puff)
	return _meshes[key]
