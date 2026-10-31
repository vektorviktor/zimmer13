class_name ChangingBench
extends StaticBody3D
## Sitzbank in der Mitte der Pool-Umkleiden (ZIM-145, Foto des Nutzers 31.10., einfacher als dort: ohne Bodenkappen
## und Fußstreben): so lang wie im Plan (gedacht 3 m), 60 cm breit, 50 cm hoch, Gestell aus anthrazit lackiertem
## Vierkantrohr und Holzlatten wie beim Gartentisch (GardenFurniture.Parts). Fußrahmen an beiden Enden und an jedem Meter
## (3 m → vier; zwei Beine, Querrohr unter den Latten), zwei Längsrohre verbinden sie. Fünf Latten längs. Sitzen geht von beiden Seiten.
## Ursprung am Boden in der Mitte, Länge entlang x.

const WIDTH := 0.6
const HEIGHT := 0.5
## Rohr der Beine und Rahmen, Beine von der Längskante eingerückt, Latten (Anzahl, Stärke, Fuge)
const TUBE := 0.04
const LEG_INSET := 0.08
const SLATS := 5
const SLAT_T := 0.025
const SLAT_GAP := 0.025

static var _meshes := {}   # Länge in cm → Mesh


## Bank der Länge length (auf 10 cm gerundet)
static func make(length: float) -> ChangingBench:
	length = maxf(1.0, snappedf(length, 0.1))
	var b := ChangingBench.new()
	b.collision_mask = 0
	var key := roundi(length * 100.0)
	if not _meshes.has(key):
		_meshes[key] = _build(length)
	Geo.mesh(b, _meshes[key], null, Vector3.ZERO)
	Geo.add_box_shape(b, Vector3(length, HEIGHT, WIDTH), Vector3(0, HEIGHT / 2.0, 0))
	# eine Sitzreihe je Seite, beide in einem Seat (der freie Platz nächst dem Blick gewinnt)
	var seat := Seat.attach(b, "bank", HEIGHT, Vector3(0, 0, WIDTH / 4.0), Vector3(0, 0, 1), length, WIDTH / 4.0 + 0.3)
	for spot: Marker3D in seat.spots.duplicate():
		var m := Marker3D.new()
		m.position = Vector3(spot.position.x, spot.position.y, -spot.position.z)
		m.basis = Basis.looking_at(Vector3(0, 0, -1))
		seat.add_child(m)
		seat.spots.append(m)
	return b


## Fußrahmen an beiden Enden (bündig unter den Lattenenden) und gleichmäßig dazwischen, etwa je Meter; Längsrohre
## innen an den Beinen über die ganze Länge, Latten darauf
static func _build(length: float) -> ArrayMesh:
	var p := GardenFurniture.Parts.new()
	var frame_top := HEIGHT - SLAT_T
	var leg_z := WIDTH / 2.0 - LEG_INSET
	var frames := maxi(2, roundi(length) + 1)
	var half := length / 2.0 - TUBE / 2.0
	for i in frames:
		var x := lerpf(-half, half, float(i) / (frames - 1))
		for s: float in [-1.0, 1.0]:
			p.tube(Vector3(x, 0, s * leg_z), Vector3(x, frame_top - TUBE, s * leg_z), Vector2(TUBE, TUBE))
		var y := frame_top - TUBE / 2.0
		p.tube(Vector3(x, y, -WIDTH / 2.0 + 0.02), Vector3(x, y, WIDTH / 2.0 - 0.02), Vector2(TUBE, TUBE))
	for s: float in [-1.0, 1.0]:
		var z := s * (leg_z - TUBE)
		var y := frame_top - TUBE * 1.5
		p.tube(Vector3(-half, y, z), Vector3(half, y, z), Vector2(TUBE, TUBE))
	var width := (WIDTH - SLAT_GAP * (SLATS - 1)) / SLATS
	for i in SLATS:
		var z := -WIDTH / 2.0 + width / 2.0 + i * (width + SLAT_GAP)
		p.board(Vector3(0, frame_top + SLAT_T / 2.0, z), Vector3(length, SLAT_T, width))
	return p.commit()
