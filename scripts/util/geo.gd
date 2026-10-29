class_name Geo
## Helfer für Platzhalter-Geometrie (wird später durch Blender-Modelle ersetzt).


## Größte Kantenlänge eines Dreiecks. Das Vertex-Snapping verschiebt jede Ecke um bis zu einen
## Bildschirm-Rasterpunkt – bei riesigen Flächen (80-m-Flurboden) schwimmt sonst die ganze Fläche.
const MAX_FACE := 1.0

## Mesh-Cache: gleiche Maße (auf 0,1 mm) → dasselbe Mesh. Jedes eigene Mesh legt auf der Grafikkarte eigene
## Puffer an; zehntausende davon bringen manche Vulkan-Treiber (Onboard-Grafik) mit „VkResult error -10“ zum
## Abbruch (TECHNIK.md 1 „Grafik“). Gilt für box, cylinder, sphere, wall_mesh, grain_box, rounded_box und
## runner_mesh – deren Meshes darum nie verändern; wer das will, nimmt .duplicate(). Zählen: Debug --meshes.
static var _cache := {}


static func _cached(key: String, make: Callable) -> Mesh:
	var m: Mesh = _cache.get(key)
	if m == null:
		m = make.call()
		_cache[key] = m
	return m


static func box(size: Vector3) -> BoxMesh:
	return _cached("b%.4f,%.4f,%.4f" % [size.x, size.y, size.z], func() -> BoxMesh:
		var m := BoxMesh.new()
		m.size = size
		m.subdivide_width = maxi(0, ceili(size.x / MAX_FACE) - 1)
		m.subdivide_height = maxi(0, ceili(size.y / MAX_FACE) - 1)
		m.subdivide_depth = maxi(0, ceili(size.z / MAX_FACE) - 1)
		return m)


static func cylinder(radius: float, height: float, segments: int = 8) -> CylinderMesh:
	return _cached("c%.4f,%.4f,%d" % [radius, height, segments], func() -> CylinderMesh:
		var m := CylinderMesh.new()
		m.top_radius = radius
		m.bottom_radius = radius
		m.height = height
		m.radial_segments = segments
		m.rings = 1
		return m)


static func sphere(radius: float, height: float, segments: int = 8, rings: int = 4) -> SphereMesh:
	return _cached("s%.4f,%.4f,%d,%d" % [radius, height, segments, rings], func() -> SphereMesh:
		var m := SphereMesh.new()
		m.radius = radius
		m.height = height
		m.radial_segments = segments
		m.rings = rings
		return m)


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
	return _cached("r%.4f,%.4f,%.4f,%.4f,%.4f" % [length, width, cap, tile, cap_v],
		_runner_mesh.bind(length, width, cap, tile, cap_v))


static func _runner_mesh(length: float, width: float, cap: float, tile: float, cap_v: float) -> ArrayMesh:
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
	var key := "w%.4f,%.4f,%.4f,%.4f" % [x0, x1, height, thick]
	for o in openings:   # Wände übereinander (Stockwerke gleichen Grundrisses) teilen sich das Mesh
		var op: Vector4 = o
		key += "|%.4f,%.4f,%.4f,%.4f" % [op.x, op.y, op.z, op.w]
	return _cached(key, _wall_mesh.bind(x0, x1, height, thick, openings))


static func _wall_mesh(x0: float, x1: float, height: float, thick: float, openings: Array) -> ArrayMesh:
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


## Holzbalken als Quader (Mitte im Ursprung) mit UVs, die der Faser folgen: Die Achse grain (0 = x, 1 = y, 2 = z) läuft
## auf den vier Längsseiten entlang u (tex.x Meter je Kachel längs, tex.y quer), die beiden Stirnseiten zeigen Hirnholz
## (end_meters je Kachel). Fläche 0 = Längsholz, Fläche 1 = Hirnholz (Mat.wood). offset verschiebt die Maserung, damit
## nicht jeder Balken gleich aussieht. Flächen höchstens MAX_FACE lang.
static func grain_box(size: Vector3, grain: int, tex: Vector2, end_meters: float, offset := Vector2.ZERO) -> ArrayMesh:
	return _cached("g%.4f,%.4f,%.4f,%d,%.4f,%.4f,%.4f,%.4f,%.4f" % [size.x, size.y, size.z, grain, tex.x, tex.y,
		end_meters, offset.x, offset.y], _grain_box.bind(size, grain, tex, end_meters, offset))


static func _grain_box(size: Vector3, grain: int, tex: Vector2, end_meters: float, offset: Vector2) -> ArrayMesh:
	var h := size / 2.0
	var parts := [[[], [], [], []], [[], [], [], []]]   # Längsholz, Hirnholz: [Ecken, Normalen, UVs, Indizes]
	for a in 3:
		for s in [-1.0, 1.0]:
			var n := Vector3.ZERO
			n[a] = s
			var end := a == grain
			var b := (a + 1) % 3 if end else grain   # u-Achse
			var c := 3 - a - b                       # v-Achse
			var out: Array = parts[1 if end else 0]
			var nu := maxi(1, ceili(size[b] / MAX_FACE - 0.0001))
			var nv := maxi(1, ceili(size[c] / MAX_FACE - 0.0001))
			var first: int = out[0].size()
			for i in nu + 1:
				for j in nv + 1:
					var p := Vector3.ZERO
					p[a] = s * h[a]
					p[b] = lerpf(-h[b], h[b], float(i) / nu)
					p[c] = lerpf(-h[c], h[c], float(j) / nv)
					out[0].append(p)
					out[1].append(n)
					var scale := Vector2(end_meters, end_meters) if end else tex
					out[2].append(Vector2((p[b] + h[b]) / scale.x, (p[c] + h[c]) / scale.y) + offset)
			for i in nu:
				for j in nv:
					var q := first + i * (nv + 1) + j
					_quad(out[3], out[0], [q, q + nv + 1, q + nv + 2, q + 1], n)
	var m := ArrayMesh.new()
	for part in parts:
		add_surface(m, PackedVector3Array(part[0]), PackedVector3Array(part[1]), PackedInt32Array(part[3]), PackedVector2Array(part[2]))
	return m


## Kasten mit runden Kanten und Ecken (Radius radius, je Viertelkreis 2 × segments Schritte), Mitte im Ursprung, glatt
## schattiert – Matratze, Kissen, Bettdecke. puff > 0 bläht ihn zur Mitte hin auf (Kissen): Die Höhe wächst dort um
## diesen Anteil, an den Rändern nicht. Ein gewürfelter Kasten, dessen Ecken auf den gerundeten Kern gezogen werden.
static func rounded_box(size: Vector3, radius: float, segments: int = 2, puff: float = 0.0) -> ArrayMesh:
	return _cached("o%.4f,%.4f,%.4f,%.4f,%d,%.4f" % [size.x, size.y, size.z, radius, segments, puff],
		_rounded_box.bind(size, radius, segments, puff))


static func _rounded_box(size: Vector3, radius: float, segments: int, puff: float) -> ArrayMesh:
	var h := size / 2.0
	radius = minf(radius, minf(h.x, minf(h.y, h.z)))
	var core := h - Vector3.ONE * radius
	var lines := []   # Rasterlinien je Achse: Rundung, gerade Strecke (≤ MAX_FACE), Rundung
	for a in 3:
		var l := []
		for k in segments:
			l.append(-h[a] + radius * k / segments)
		var steps := maxi(1, ceili(2.0 * core[a] / MAX_FACE - 0.0001)) if core[a] > 0.001 else 0
		for k in steps + 1:
			l.append(lerpf(-core[a], core[a], float(k) / steps) if steps > 0 else 0.0)
		for k in range(1, segments + 1):
			l.append(core[a] + radius * k / segments)
		lines.append(l)
	var verts := []
	var normals := []
	var indices := []
	for a in 3:
		for s in [-1.0, 1.0]:
			var face_n := Vector3.ZERO
			face_n[a] = s
			var b := (a + 1) % 3
			var c := (a + 2) % 3
			var us: Array = lines[b]
			var vs: Array = lines[c]
			var first := verts.size()
			for i in us.size():
				for j in vs.size():
					var p := Vector3.ZERO
					p[a] = s * h[a]
					p[b] = us[i]
					p[c] = vs[j]
					var inner := p.clamp(-core, core)
					var n := (p - inner).normalized() if not (p - inner).is_zero_approx() else face_n
					var v := inner + n * radius
					if puff > 0.0:
						v.y *= 1.0 + puff * maxf(0.0, 1.0 - pow(v.x / h.x, 2.0)) * maxf(0.0, 1.0 - pow(v.z / h.z, 2.0))
					verts.append(v)
					normals.append(n)
			for i in us.size() - 1:
				for j in vs.size() - 1:
					var q := first + i * vs.size() + j
					_quad(indices, verts, [q, q + vs.size(), q + vs.size() + 1, q + 1], face_n)
	return add_surface(ArrayMesh.new(), PackedVector3Array(verts), PackedVector3Array(normals), PackedInt32Array(indices))


## Viereck c (Indizes in verts) als zwei Dreiecke an indices, im Uhrzeigersinn von der Seite normal aus gesehen.
static func _quad(indices: Array, verts: Array, c: Array, normal: Vector3) -> void:
	var e1: Vector3 = verts[c[1]] - verts[c[0]]
	var e2: Vector3 = verts[c[2]] - verts[c[0]]
	if e1.cross(e2).dot(normal) > 0.0:
		indices.append_array([c[0], c[2], c[1], c[0], c[3], c[2]])
	else:
		indices.append_array([c[0], c[1], c[2], c[0], c[2], c[3]])


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
