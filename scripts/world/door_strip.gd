class_name DoorStrip
## Übergangsschiene unter einer Tür (ZIM-132, Entscheidung 3.11., Spielkonzept 9.2): schmales Profil aus gebürstetem
## Altmessing wie die Lichtschalter (eigene, längs kachelnde Karten aus tools/door_strip.gd), genau in der Ebene des
## Türblatts, wo die Böden beider Räume aneinanderstoßen (LevelBuilder._door_floors). Flach gewölbt, höchstens
## TOP hoch über dem Boden, mit kleiner Stufe an den Kanten; die Kanten liegen OVERLAP über den Böden, eine Lippe
## reicht in die Fuge hinein – so sieht man nirgends hindurch, und keine Fläche liegt auf der des Bodens.
## Ohne Kollision (NavMesh, Schritte und Salzlinie bleiben, wie sie waren). Ursprung in der Mitte der Schiene auf
## dem Boden, lokale X längs, Z quer.

## Höhe über dem Boden in der Mitte, an der Kante, Tiefe der Lippe in der Fuge (m)
const TOP := 0.004
const EDGE := 0.0008
const LIP := 0.002
## Breite (ganz, flaches Stück oben), so viel greift jede Kante über den Boden
const WIDTH := 0.036
const FLAT := 0.02
## Abstand der Enden zur Zarge (deren Futter, DoorCasing.JAMB)
const END_GAP := 0.008
## Karten: abgebildete Strecke quer und längs (= tools/door_strip.gd ACROSS_MM, ALONG_MM), Metallanteil wie die Schalter
const ACROSS := 0.04
const ALONG := 0.32
const TEX := "res://assets/textures/door_strip.png"
const TEX_NORMAL := "res://assets/textures/door_strip_normal.png"
const TEX_ROUGH := "res://assets/textures/door_strip_rough.png"
const METALLIC := LightSwitch.METALLIC
## Stützpunkte der Wölbung zwischen Kante und Mitte (je Seite); so viele Versätze der Karten längs (je Tür einer)
const STEPS := 4
const VARIANTS := 4

static var _mat: ShaderMaterial
static var _meshes := {}


## Schiene der Länge length (zwischen den Zargen) in parent, Mitte bei pos, quer zu yaw; seed wählt den Versatz der
## Karten längs, damit nicht jede Tür gleich aussieht.
static func add(parent: Node3D, length: float, pos: Vector3, yaw: float, seed: int) -> MeshInstance3D:
	var key := Vector2(snappedf(length, 0.001), posmod(seed, VARIANTS))
	if not _meshes.has(key):
		_meshes[key] = _build(key.x, key.y / VARIANTS)
	var mi := Geo.mesh(parent, _meshes[key], material(), pos)
	mi.rotation.y = yaw
	return mi


static func material() -> ShaderMaterial:
	if _mat == null:
		_mat = Mat.photo(TEX, 1.0, TEX_NORMAL, TEX_ROUGH, 0.5, Color(1, 1, 1), false, true)
		_mat.set_shader_parameter("metallic", METALLIC)
	return _mat


## Profil quer (z, y) von −z nach +z: Lippe in der Fuge, Kante, Wölbung bis zur Mitte und wieder hinab.
static func _profile() -> Array[Vector2]:
	var half := WIDTH / 2.0
	var pts: Array[Vector2] = [Vector2(-half, -LIP), Vector2(-half, EDGE)]
	for k in range(1, STEPS + 1):   # Schulter: Viertelellipse, an der Kante steil, oben flach
		var t := float(k) / STEPS * PI / 2.0
		pts.append(Vector2(-half + (half - FLAT / 2.0) * (1.0 - cos(t)), EDGE + (TOP * 0.92 - EDGE) * sin(t)))
	pts.append(Vector2(0.0, TOP))
	for k in range(pts.size() - 2, -1, -1):
		pts.append(Vector2(-pts[k].x, pts[k].y))
	return pts


## Profil längs gezogen; v0 verschiebt die Karten längs (Anteil einer Kachel).
static func _build(length: float, v0: float) -> ArrayMesh:
	var pts := _profile()
	var last := pts.size() - 1
	var x0 := -length / 2.0
	var x1 := length / 2.0
	# Bogenlänge quer → u; die Lippen liegen außerhalb der Karte und nehmen ihren Rand (Schmutz in der Fuge)
	var arc: Array[float] = [0.0]
	for k in range(1, pts.size()):
		arc.append(arc[-1] + pts[k].distance_to(pts[k - 1]))
	var u0 := (arc[-1] - ACROSS) / 2.0
	var verts := PackedVector3Array()
	var normals := PackedVector3Array()
	var uvs := PackedVector2Array()
	var idx := PackedInt32Array()
	for k in last:
		var a := pts[k]
		var b := pts[k + 1]
		var face := Vector2(-(b.y - a.y), b.x - a.x).normalized()   # nach außen (oben bzw. zur Seite)
		# die Lippen senkrecht mit scharfer Kante, die Wölbung glatt
		var lip := k == 0 or k == last - 1
		var na := face if lip or k == 1 else _smooth(pts, k)
		var nb := face if lip or k + 1 == last - 1 else _smooth(pts, k + 1)
		var first := verts.size()
		for c in [[a, na, arc[k], x0], [b, nb, arc[k + 1], x0], [b, nb, arc[k + 1], x1], [a, na, arc[k], x1]]:
			var p: Vector2 = c[0]
			var nn: Vector2 = c[1]
			verts.append(Vector3(c[3], p.y, p.x))
			normals.append(Vector3(0.0, nn.y, nn.x))
			uvs.append(Vector2(clampf((float(c[2]) - u0) / ACROSS, 0.0, 1.0), (float(c[3]) - x0) / ALONG + v0))
		_tri(idx, verts, first, first + 1, first + 2, Vector3(0.0, face.y, face.x))
		_tri(idx, verts, first, first + 2, first + 3, Vector3(0.0, face.y, face.x))
	# Stirnseiten: Fächer über das Profil (an der Zarge kaum zu sehen)
	for side: float in [-1.0, 1.0]:
		var first := verts.size()
		for p in pts:
			verts.append(Vector3(side * length / 2.0, p.y, p.x))
			normals.append(Vector3(side, 0.0, 0.0))
			uvs.append(Vector2(0.5 + p.x / ACROSS, 0.5 + p.y / ALONG))
		for k in range(1, last):
			_tri(idx, verts, first, first + k, first + k + 1, Vector3(side, 0.0, 0.0))
	return Geo.add_surface(ArrayMesh.new(), verts, normals, idx, uvs)


## Dreieck im Uhrzeigersinn von der Seite n aus gesehen (wie Geo._quad).
static func _tri(idx: PackedInt32Array, verts: PackedVector3Array, a: int, b: int, c: int, n: Vector3) -> void:
	if (verts[b] - verts[a]).cross(verts[c] - verts[a]).dot(n) > 0.0:
		idx.append_array([a, c, b])
	else:
		idx.append_array([a, b, c])


## Gemittelte Normale am Stützpunkt k (Wölbung glatt schattiert).
static func _smooth(pts: Array[Vector2], k: int) -> Vector2:
	var n := Vector2.ZERO
	for j in [k - 1, k]:
		var a := pts[j]
		var b := pts[j + 1]
		n += Vector2(-(b.y - a.y), b.x - a.x).normalized()
	return n.normalized()
