class_name DartModel
## Ein Dartpfeil aus Grundkörpern (Spielkonzept 6.10): Stahlspitze, Wolframschaft mit Griffrillen, Schaft und zwei
## gekreuzte Flights. Ursprung an der Spitze, der Pfeil liegt entlang +Z (nach hinten) – mit
## Basis.looking_at(flugrichtung) zeigt die Spitze also in Flugrichtung. 15 cm lang.

const LENGTH := 0.15
const TIP := 0.032          ## Spitze: so lang (m) – so tief steckt er höchstens in der Scheibe
const BARREL := Vector2(0.032, 0.082)   ## Schaft aus Wolfram: von, bis (m ab der Spitze)
const STEM := 0.118         ## Ende des Kunststoffschafts
const FLIGHT := Vector2(0.104, 0.15)    ## Flights: von, bis
const FLIGHT_WIDTH := 0.03

static var _flights := {}


## Pfeil mit Flights in dieser Farbe.
static func build(flight_color: Color) -> Node3D:
	var dart := Node3D.new()
	var steel := Mat.metal(Color(0.82, 0.83, 0.86))
	var tungsten := Mat.metal(Color(0.5, 0.51, 0.55))
	_part(dart, _cone(0.0003, 0.0012, TIP), steel, TIP / 2.0)
	_part(dart, _cone(0.0034, 0.0034, BARREL.y - BARREL.x), tungsten, (BARREL.x + BARREL.y) / 2.0)
	for i in 4:   # Griffrillen
		_part(dart, _cone(0.0037, 0.0037, 0.0025), tungsten, BARREL.x + 0.012 + i * 0.008)
	_part(dart, _cone(0.0021, 0.0025, STEM - BARREL.y), Mat.psx(Color(0.08, 0.08, 0.09)), (BARREL.y + STEM) / 2.0)
	var flight := _flight_material(flight_color)
	for k in 2:
		var wing := MeshInstance3D.new()
		wing.mesh = _flight_mesh()
		wing.material_override = flight
		wing.rotation.z = k * PI / 2.0
		dart.add_child(wing)
	return dart


static func _part(dart: Node3D, mesh: Mesh, mat: Material, z: float) -> void:
	var part := Geo.mesh(dart, mesh, mat, Vector3(0, 0, z))
	part.rotation.x = PI / 2.0   # Zylinder entlang +Z statt +Y
	part.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


## Kegelstumpf entlang Y: unten r_tip (zur Spitze, nach dem Drehen vorn), oben r_back.
static func _cone(r_tip: float, r_back: float, length: float) -> CylinderMesh:
	var m := CylinderMesh.new()
	m.bottom_radius = r_tip
	m.top_radius = r_back
	m.height = length
	m.radial_segments = 8
	m.rings = 1
	return m


## Flight in Standardform: schmal am Schaft, hinten breit und schräg abgeschnitten (eine Fläche in der XZ-Ebene).
static func _flight_mesh() -> ArrayMesh:
	var w := FLIGHT_WIDTH / 2.0
	var a := FLIGHT.x
	var b := FLIGHT.y
	var verts := PackedVector3Array([Vector3(0.0015, 0, a), Vector3(w, 0, a + 0.02), Vector3(w * 0.9, 0, b),
		Vector3(-w * 0.9, 0, b), Vector3(-w, 0, a + 0.02), Vector3(-0.0015, 0, a)])
	var indices := PackedInt32Array([0, 1, 2, 0, 2, 3, 0, 3, 5, 5, 3, 4])
	var normals := PackedVector3Array()
	normals.resize(verts.size())
	normals.fill(Vector3.UP)
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_INDEX] = indices
	var m := ArrayMesh.new()
	m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return m


## Bedruckter Kunststoff, beidseitig – je Farbe eins.
static func _flight_material(color: Color) -> StandardMaterial3D:
	var key := color.to_html()
	if not _flights.has(key):
		var m := StandardMaterial3D.new()
		m.albedo_color = color
		m.roughness = 0.45
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
		_flights[key] = m
	return _flights[key]
