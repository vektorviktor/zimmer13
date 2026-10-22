class_name Geo
## Helfer für Platzhalter-Geometrie (wird später durch Blender-Modelle ersetzt).


## Größte Kantenlänge eines Dreiecks. Das Vertex-Snapping verschiebt jede Ecke um bis zu einen
## Bildschirm-Rasterpunkt – bei riesigen Flächen (80-m-Flurboden) schwimmt sonst die ganze Fläche.
const MAX_FACE := 1.0


static func box(size: Vector3) -> BoxMesh:
	var m := BoxMesh.new()
	m.size = size
	m.subdivide_width = maxi(0, ceili(size.x / MAX_FACE) - 1)
	m.subdivide_height = maxi(0, ceili(size.y / MAX_FACE) - 1)
	m.subdivide_depth = maxi(0, ceili(size.z / MAX_FACE) - 1)
	return m


static func cylinder(radius: float, height: float, segments: int = 8) -> CylinderMesh:
	var m := CylinderMesh.new()
	m.top_radius = radius
	m.bottom_radius = radius
	m.height = height
	m.radial_segments = segments
	m.rings = 1
	return m


static func sphere(radius: float, height: float, segments: int = 8, rings: int = 4) -> SphereMesh:
	var m := SphereMesh.new()
	m.radius = radius
	m.height = height
	m.radial_segments = segments
	m.rings = rings
	return m


static func mesh(parent: Node, m: Mesh, mat: Material, pos: Vector3) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = m
	mi.material_override = mat
	mi.position = pos
	parent.add_child(mi)
	return mi


## Partikel-Emitter für Mat.particle: quadratische Billboards (Kantenlänge size) in Weltkoordinaten –
## sie bleiben, wo sie entstanden sind, auch wenn der Emitter weiterzieht. Blenden über fade_in/fade_out
## (Anteile der Lebenszeit) ein und aus; Bewegung (Richtung, Tempo, Schwerkraft …) setzt der Aufrufer.
static func particles(amount: int, lifetime: float, size: float, mat: Material, fade_in: float = 0.1, fade_out: float = 0.3) -> CPUParticles3D:
	var p := CPUParticles3D.new()
	p.amount = amount
	p.lifetime = lifetime
	p.local_coords = false
	var quad := QuadMesh.new()
	quad.size = Vector2(size, size)
	p.mesh = quad
	p.material_override = mat
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	p.angle_min = 0.0   # Zufallswert je Partikel für den Shader (Bild, Farbton, Phase)
	p.angle_max = 360.0
	var ramp := Gradient.new()
	ramp.set_color(0, Color(1, 1, 1, 0))
	ramp.set_color(1, Color(1, 1, 1, 0))
	ramp.add_point(fade_in, Color.WHITE)
	ramp.add_point(1.0 - fade_out, Color.WHITE)
	p.color_ramp = ramp
	return p


static func add_box_shape(body: CollisionObject3D, size: Vector3, pos: Vector3) -> CollisionShape3D:
	var cs := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	cs.shape = shape
	cs.position = pos
	body.add_child(cs)
	return cs


## Quader mit gleich großer Kollisionsform an einem vorhandenen Körper (Bretter von Truhe und Kommode).
static func box_part(body: CollisionObject3D, size: Vector3, pos: Vector3, mat: Material) -> MeshInstance3D:
	var mi := mesh(body, box(size), mat, pos)
	add_box_shape(body, size, pos)
	return mi


## Massiver Quader mit Kollision (Wände, Böden, Möbel).
static func solid(parent: Node, size: Vector3, pos: Vector3, mat: Material, layer: int = 1) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.collision_layer = layer
	body.collision_mask = 0
	body.position = pos
	parent.add_child(body)
	mesh(body, box(size), mat, Vector3.ZERO)
	add_box_shape(body, size, Vector3.ZERO)
	return body


## Kollisionskasten ohne Mesh (die Optik liefert z. B. ein gemeinsames Wand-Mesh).
static func collider(parent: Node, size: Vector3, pos: Vector3, layer: int = 1) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.collision_layer = layer
	body.collision_mask = 0
	body.position = pos
	parent.add_child(body)
	add_box_shape(body, size, Vector3.ZERO)
	return body


## Läufer als flaches Band entlang X (Mitte im Ursprung, Oberseite y = 0) mit eigenen UVs für eine Textur aus
## Abschluss (v 0…cap_v) und Musterkachel (cap_v…1), u quer über die ganze Breite: an beiden Enden ein Abschluss
## (das hintere gespiegelt), dazwischen eine ganze Zahl Kacheln, leicht gestreckt – so sitzt das Muster immer
## symmetrisch. cap und tile = Länge von Abschluss und Kachel in Metern. Jedes Feld hat eigene Ecken (die UVs
## springen an den Nähten), Felder höchstens MAX_FACE groß.
static func runner_mesh(length: float, width: float, cap: float, tile: float, cap_v: float) -> ArrayMesh:
	cap = minf(cap, length / 3.0)
	var body := length - 2.0 * cap
	var n := maxi(1, roundi(body / tile))
	var segments: Array[Vector4] = [Vector4(0.0, cap, 0.0, cap_v)]   # (von, bis, v von, v bis)
	for i in n:
		segments.append(Vector4(cap + body * i / n, cap + body * (i + 1) / n, cap_v, 1.0))
	segments.append(Vector4(length - cap, length, cap_v, 0.0))
	var across := maxi(1, ceili(width / MAX_FACE - 0.0001))
	var verts := PackedVector3Array()
	var normals := PackedVector3Array()
	var uvs := PackedVector2Array()
	var indices := PackedInt32Array()
	for sg in segments:
		var steps := maxi(1, ceili((sg.y - sg.x) / MAX_FACE - 0.0001))
		for i in steps:
			for j in across:
				var first := verts.size()
				for k in [Vector2i(i, j), Vector2i(i + 1, j), Vector2i(i + 1, j + 1), Vector2i(i, j + 1)]:
					var t := float(k.x) / steps
					var u := float(k.y) / across
					verts.append(Vector3(lerpf(sg.x, sg.y, t) - length / 2.0, 0.0, (u - 0.5) * width))
					normals.append(Vector3.UP)
					uvs.append(Vector2(u, lerpf(sg.z, sg.w, t)))
				# +X, dann +Z: von oben gesehen im Uhrzeigersinn
				indices.append_array([first, first + 1, first + 2, first, first + 2, first + 3])
	return add_surface(ArrayMesh.new(), verts, normals, indices, uvs)


## Wand als ein einziges Mesh: entlang X von x0 bis x1, Mitte z = 0, Boden y = 0 (ohne Unterseite).
## Fläche 0 = Wand, Fläche 1 = Laibungen der Öffnungen (eigenes Material möglich, z. B. Rahmenholz).
## Öffnungen als Vector4(Mitte x, Breite, Oberkante, Unterkante). Alle Flächen teilen sich ein Raster aus
## Wandenden, Öffnungskanten und ≤ MAX_FACE-Schritten. Einzelne Kästen (links, Sturz, rechts) stießen mit
## ihren Ecken mitten auf die Kante des Nachbarn – beim Vertex-Snapping klafften dort Fugen, und die
## Tapete war gegeneinander versetzt.
static func wall_mesh(x0: float, x1: float, height: float, thick: float, openings: Array) -> ArrayMesh:
	var xs := [x0, x1]
	var ys := [0.0, height]
	for o in openings:
		var op: Vector4 = o
		xs.append(clampf(op.x - op.y / 2.0, x0, x1))
		xs.append(clampf(op.x + op.y / 2.0, x0, x1))
		if op.w > 0.0:
			ys.append(minf(op.w, height))
		if op.z < height:
			ys.append(op.z)
	xs = _breaks(xs)
	ys = _breaks(ys)
	var zs := [-thick / 2.0, thick / 2.0]
	var inside := func(x: float, y: float) -> bool:
		for o in openings:
			var op: Vector4 = o
			if absf(x - op.x) < op.y / 2.0 and y > op.w and y < op.z:
				return true
		return false
	var solid := func(x: float, y: float) -> bool: return not inside.call(x, y)
	var always := func(_u: float, _v: float) -> bool: return true
	var out := [[], [], []]
	var reveals := [[], [], []]
	# Vorder- und Rückseite, Oberkante, Stirnseiten
	_grid(out, xs, ys, func(u, v): return Vector3(u, v, thick / 2.0), Vector3.BACK, solid)
	_grid(out, xs, ys, func(u, v): return Vector3(u, v, -thick / 2.0), Vector3.FORWARD, solid)
	_grid(out, xs, zs, func(u, v): return Vector3(u, height, v), Vector3.UP,
		func(u, _v): return not inside.call(u, height - 0.001))
	_grid(out, zs, ys, func(u, v): return Vector3(x0, v, u), Vector3.LEFT,
		func(_u, v): return not inside.call(x0 + 0.001, v))
	_grid(out, zs, ys, func(u, v): return Vector3(x1, v, u), Vector3.RIGHT,
		func(_u, v): return not inside.call(x1 - 0.001, v))
	# Laibungen der Öffnungen – auf denselben Rasterlinien wie die Wandflächen
	for o in openings:
		var op: Vector4 = o
		var a := op.x - op.y / 2.0
		var b := op.x + op.y / 2.0
		var side_ys := ys.filter(func(y): return y >= maxf(op.w, 0.0) - 0.0001 and y <= minf(op.z, height) + 0.0001)
		var span_xs := xs.filter(func(x): return x >= a - 0.0001 and x <= b + 0.0001)
		if a > x0:
			_grid(reveals, zs, side_ys, func(u, v): return Vector3(a, v, u), Vector3.RIGHT, always)
		if b < x1:
			_grid(reveals, zs, side_ys, func(u, v): return Vector3(b, v, u), Vector3.LEFT, always)
		if op.z < height:
			_grid(reveals, span_xs, zs, func(u, v): return Vector3(u, op.z, v), Vector3.DOWN, always)
		if op.w > 0.0:
			_grid(reveals, span_xs, zs, func(u, v): return Vector3(u, op.w, v), Vector3.UP, always)
	var m := ArrayMesh.new()
	for part in [out, reveals]:
		if not part[0].is_empty():
			add_surface(m, PackedVector3Array(part[0]), PackedVector3Array(part[1]), PackedInt32Array(part[2]))
	return m


## Hängt eine Dreiecksfläche an m an (leere uvs/colors: ohne) und gibt m zurück.
static func add_surface(m: ArrayMesh, verts: PackedVector3Array, normals: PackedVector3Array, indices: PackedInt32Array,
		uvs := PackedVector2Array(), colors := PackedColorArray()) -> ArrayMesh:
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_INDEX] = indices
	if not uvs.is_empty():
		arrays[Mesh.ARRAY_TEX_UV] = uvs
	if not colors.is_empty():
		arrays[Mesh.ARRAY_COLOR] = colors
	m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return m


## Sortierte, eindeutige Rasterlinien; Abstände über MAX_FACE werden gleichmäßig unterteilt.
static func _breaks(values: Array) -> Array:
	values.sort()
	var result := []
	for v in values:
		if result.is_empty() or v - result[-1] > 0.0001:
			if not result.is_empty():
				var n := ceili((v - result[-1]) / MAX_FACE - 0.0001)
				var from: float = result[-1]
				for k in range(1, n):
					result.append(from + (v - from) * k / n)
			result.append(v)
	return result


## Rasterfläche: Ecke (i, j) liegt bei point(us[i], vs[j]); eine Zelle entsteht nur, wenn keep(Mitte) gilt.
## Benachbarte Zellen teilen sich ihre Ecken. out = [Ecken, Normalen, Indizes].
static func _grid(out: Array, us: Array, vs: Array, point: Callable, normal: Vector3, keep: Callable) -> void:
	var verts: Array = out[0]
	var normals: Array = out[1]
	var indices: Array = out[2]
	var ids := {}
	for i in us.size() - 1:
		for j in vs.size() - 1:
			if not keep.call((us[i] + us[i + 1]) / 2.0, (vs[j] + vs[j + 1]) / 2.0):
				continue
			var c := []
			for k in [Vector2i(i, j), Vector2i(i + 1, j), Vector2i(i + 1, j + 1), Vector2i(i, j + 1)]:
				if not ids.has(k):
					ids[k] = verts.size()
					verts.append(point.call(us[k.x], vs[k.y]))
					normals.append(normal)
				c.append(ids[k])
			# Godot zeichnet Dreiecke, die von vorn im Uhrzeigersinn umlaufen
			var e1: Vector3 = verts[c[1]] - verts[c[0]]
			var e2: Vector3 = verts[c[2]] - verts[c[0]]
			if e1.cross(e2).dot(normal) > 0.0:
				indices.append_array([c[0], c[2], c[1], c[0], c[3], c[2]])
			else:
				indices.append_array([c[0], c[1], c[2], c[0], c[2], c[3]])
