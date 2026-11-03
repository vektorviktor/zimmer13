class_name Lawn
extends RefCounted
## Rasen im Garten mit leichten Wellen (ZIM-173, Spielkonzept 7.10): Über dem flachen Boden aus dem Plan liegt ein
## Netz, das ein Rauschen um bis zu AMPLITUDE anhebt – nur nach oben, mit langen Wellen. Zu allem, was kein Rasen ist
## (Kies, Terrassen, Wände, Beete, Kübel, Bäume, Ausstattung des Plans), fällt die Welle über FALLOFF auf null; dort
## liegt das Netz LIFT über dem flachen Boden und stößt ohne Stufe an. Das Netz hat eine eigene Kollision (Gegenstände,
## Füße, NavMesh liegen auf den Wellen), der flache Boden bleibt darunter. Grasbüschel stehen auf height(p).

const CELL := 0.25            ## Raster für den Abstand zum Rand (m)
const FALLOFF := 1.2          ## so weit vom Rand wächst die Welle von null auf voll
const AMPLITUDE := 0.08       ## höchste Erhebung (m)
const WAVE := 6.0             ## Wellenlänge der Hügel (m)
const LIFT := 0.004           ## Abstand des Netzes zum flachen Boden darunter (kein Flimmern)
const STEP := 0.5             ## Rasterweite des Netzes
const CHUNK := 16.0           ## Kantenlänge einer Kachel des Netzes (je ein Mesh und eine Kollision)
const CLEAR := 0.6            ## um Bäume, Gegenstände, Ausstattung und Laternen bleibt der Rasen flach
const CLEAR_BED := 0.3        ## um Beete und Kübel
const SEED := 7173
## Gras über der Kante (Grass): so weit vom Kies dürfen Büschel stehen, je nach Rauschen entlang der Kante
## von … bis (m) – nah am Weg hängen die Halme über Randstein und Kies; Takt des Rauschens (1/m)
const EDGE_REACH := Vector2(0.0, 0.25)
const EDGE_FREQ := 0.9

var _origin := Vector2.ZERO
var _size := Vector2i.ZERO
var _dist := PackedFloat32Array()   # Abstand der Zellmitte zum nächsten Nicht-Rasen (m)
var _noise := FastNoiseLite.new()
var _edge_noise := FastNoiseLite.new()
var gravel: Array[Rect2] = []       ## Kiesflächen des EG (Randsteine, Gras über der Kante)
var peak := 0.0                     ## höchster Punkt des Netzes (für --trace)


func _init(builder: LevelBuilder) -> void:
	_noise.seed = SEED
	_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_noise.frequency = 1.0 / WAVE
	_noise.fractal_octaves = 2
	_noise.fractal_gain = 0.35
	_edge_noise.seed = SEED + 1
	_edge_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_edge_noise.frequency = EDGE_FREQ
	_edge_noise.fractal_type = FastNoiseLite.FRACTAL_NONE
	for key in ["regions", "floor_patches"]:
		for r in builder._map[key]:
			if r["kind"] == "gravel":
				for rc in r["rects"]:
					gravel.append(builder._rect(rc))
	_build_distance(builder)


## Rechtecke der Rasenflächen im EG (Fläche „Garten“ und der Boden unter den Bäumen).
static func rects(builder: LevelBuilder) -> Array[Rect2]:
	var out: Array[Rect2] = []
	for key in ["regions", "floor_patches"]:
		for r in builder._map[key]:
			if r["kind"] == "garden":
				for rc in r["rects"]:
					out.append(builder._rect(rc))
	return out


## Höhe der Rasenoberfläche an p (x, z); außerhalb des Rasens LIFT.
func height(p: Vector2) -> float:
	var t := smoothstep(0.0, FALLOFF, _distance(p))
	if t <= 0.0:
		return LIFT
	return LIFT + AMPLITUDE * t * clampf(_noise.get_noise_2dv(p) * 0.5 + 0.5, 0.0, 1.0)


## Abstand, den Grasbüschel an p zum Kies halten (EDGE_REACH, Rauschen entlang der Kante).
func edge_reach(p: Vector2) -> float:
	return lerpf(EDGE_REACH.x, EDGE_REACH.y, clampf(_edge_noise.get_noise_2dv(p) * 0.5 + 0.5, 0.0, 1.0))


## Abstand von p zur nächsten Kiesfläche (m).
func gravel_distance(p: Vector2) -> float:
	var best := INF
	for r in gravel:
		var q := p.clamp(r.position, r.end)
		best = minf(best, p.distance_to(q))
	return best


## Netz und Kollision über den Rasenrechtecken bauen (unter parent, Material mat).
func build(parent: Node3D, mat: Material, lawn_rects: Array[Rect2]) -> void:
	var chunks := {}   # Vector2i → PackedVector3Array (Dreiecke)
	for r in lawn_rects:
		var xs := _cuts(r.position.x, r.end.x)
		var zs := _cuts(r.position.y, r.end.y)
		var hs := PackedFloat32Array()
		for z in zs:
			for x in xs:
				hs.append(height(Vector2(x, z)))
				peak = maxf(peak, hs[hs.size() - 1])
		var key := Vector2i(floori(r.get_center().x / CHUNK), floori(r.get_center().y / CHUNK))
		if not chunks.has(key):
			chunks[key] = PackedVector3Array()
		var tris: PackedVector3Array = chunks[key]
		var w := xs.size()
		for j in zs.size() - 1:
			for i in w - 1:
				var a := Vector3(xs[i], hs[j * w + i], zs[j])
				var b := Vector3(xs[i + 1], hs[j * w + i + 1], zs[j])
				var c := Vector3(xs[i + 1], hs[(j + 1) * w + i + 1], zs[j + 1])
				var d := Vector3(xs[i], hs[(j + 1) * w + i], zs[j + 1])
				tris.append_array([a, b, c, a, c, d])
		chunks[key] = tris
	var holder := Node3D.new()
	holder.name = "Rasen"
	parent.add_child(holder)
	for key: Vector2i in chunks:
		var tris: PackedVector3Array = chunks[key]
		var normals := PackedVector3Array()
		for v in tris:
			normals.append(_normal(Vector2(v.x, v.z)))
		var arrays := []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = tris
		arrays[Mesh.ARRAY_NORMAL] = normals
		var mesh := ArrayMesh.new()
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		var body := StaticBody3D.new()
		holder.add_child(body)
		var shape := ConcavePolygonShape3D.new()
		shape.set_faces(tris)
		var col := CollisionShape3D.new()
		col.shape = shape
		body.add_child(col)
		var mi := MeshInstance3D.new()
		mi.mesh = mesh
		mi.material_override = mat
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		body.add_child(mi)


## Schnittstellen eines Rasenrechtecks entlang einer Achse: beide Ränder und dazwischen das Weltraster STEP
## (gleiches Raster in allen Rechtecken – Nachbarn teilen ihre Ecken fast überall).
static func _cuts(a: float, b: float) -> PackedFloat32Array:
	var out := PackedFloat32Array([a])
	var x := (floorf(a / STEP) + 1.0) * STEP
	while x < b - 0.05:
		if x > a + 0.05:
			out.append(x)
		x += STEP
	out.append(b)
	return out


func _normal(p: Vector2) -> Vector3:
	var e := 0.1
	var dx := height(p + Vector2(e, 0)) - height(p - Vector2(e, 0))
	var dz := height(p + Vector2(0, e)) - height(p - Vector2(0, e))
	return Vector3(-dx, 2.0 * e, -dz).normalized()


## Abstand zum Rand, bilinear aus dem Raster.
func _distance(p: Vector2) -> float:
	var u := (p.x - _origin.x) / CELL - 0.5
	var v := (p.y - _origin.y) / CELL - 0.5
	var x0 := floori(u)
	var y0 := floori(v)
	if x0 < 0 or y0 < 0 or x0 + 1 >= _size.x or y0 + 1 >= _size.y:
		return 0.0
	var fx := u - x0
	var fy := v - y0
	var i := y0 * _size.x + x0
	var top := lerpf(_dist[i], _dist[i + 1], fx)
	var bottom := lerpf(_dist[i + _size.x], _dist[i + _size.x + 1], fx)
	return lerpf(top, bottom, fy)


## Raster über allen Rasenflächen: Zelle ist Rasen, wenn ihre Mitte im Plan „Garten“ ist und frei von Beeten, Kübeln,
## Bäumen und Ausstattung; dann Abstand jeder Zelle zur nächsten Nicht-Rasen-Zelle (zwei Durchläufe, Schachbrettmaß).
func _build_distance(builder: LevelBuilder) -> void:
	var lawn_rects := rects(builder)
	if lawn_rects.is_empty():
		return
	var box := lawn_rects[0]
	for r in lawn_rects:
		box = box.merge(r)
	box = box.grow(2.0 * CELL)
	_origin = box.position
	_size = Vector2i(ceili(box.size.x / CELL), ceili(box.size.y / CELL))
	var blocked: Array[Rect2] = []
	for rc in builder._map["planters"]:
		blocked.append(builder._rect(rc).grow(CLEAR_BED))
	for bed in builder.garden_beds:
		blocked.append(bed.grow(CLEAR_BED))
	var circles: Array[Vector2] = []
	for t in builder._map["trees"]:
		circles.append(Vector2(t["center"][0], t["center"][1]))
	for key in ["items", "fittings"]:
		for o in builder._map[key]:
			circles.append(Vector2(o["pos"][0], o["pos"][1]))
	for l in builder._map["lights"]:
		if l["kind"] == "lantern":
			circles.append(Vector2(l["pos"][0], l["pos"][1]))
	var big := 1.0e6
	var n := _size.x * _size.y
	var d := PackedFloat32Array()
	d.resize(n)
	d.fill(0.0)
	for y in _size.y:
		for x in _size.x:
			var p := _origin + Vector2(x + 0.5, y + 0.5) * CELL
			if builder.is_lawn(p):
				d[y * _size.x + x] = big
	for r in blocked:
		_clear_rect(d, r)
	for c in circles:
		_clear_rect(d, Rect2(c - Vector2(CLEAR, CLEAR), Vector2(2.0 * CLEAR, 2.0 * CLEAR)), c)
	var w := _size.x
	var diag := sqrt(2.0)
	for y in range(1, _size.y - 1):
		for x in range(1, w - 1):
			var i := y * w + x
			if d[i] > 0.0:
				d[i] = minf(d[i], minf(minf(d[i - 1] + 1.0, d[i - w] + 1.0), minf(d[i - w - 1] + diag, d[i - w + 1] + diag)))
	for y in range(_size.y - 2, 0, -1):
		for x in range(w - 2, 0, -1):
			var i := y * w + x
			if d[i] > 0.0:
				d[i] = minf(d[i], minf(minf(d[i + 1] + 1.0, d[i + w] + 1.0), minf(d[i + w + 1] + diag, d[i + w - 1] + diag)))
	for i in n:
		d[i] = maxf(0.0, (d[i] - 0.5) * CELL)
	_dist = d


## Zellen in r auf null setzen (nicht Rasen); mit Mitte c nur die im Kreis mit Radius CLEAR.
func _clear_rect(d: PackedFloat32Array, r: Rect2, c := Vector2.INF) -> void:
	var x0 := maxi(0, floori((r.position.x - _origin.x) / CELL))
	var y0 := maxi(0, floori((r.position.y - _origin.y) / CELL))
	var x1 := mini(_size.x - 1, floori((r.end.x - _origin.x) / CELL))
	var y1 := mini(_size.y - 1, floori((r.end.y - _origin.y) / CELL))
	for y in range(y0, y1 + 1):
		for x in range(x0, x1 + 1):
			if c != Vector2.INF and (_origin + Vector2(x + 0.5, y + 0.5) * CELL).distance_to(c) > CLEAR:
				continue
			d[y * _size.x + x] = 0.0
