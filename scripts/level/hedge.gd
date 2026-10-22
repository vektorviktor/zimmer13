class_name Hedge
## Formschnitthecken an den Terrassenkanten im Garten (Spielkonzept 7): im Plan nur 20-cm-Linien, gebaut
## WIDTH dick und HEIGHT hoch, mittig auf der Linie. Je Linie ein Querschnitt mit abgerundeter Oberkante (oben
## etwas schmaler), entlang der Linie gezogen und mit Rauschen verbeult; dazu Blattkarten vor allem an der
## Oberkante, die den geraden Umriss aufbrechen. Kollision nur als Quader. Ecken stoßen auf Gehrung, ein
## Querstück endet unsichtbar in der Hecke, auf die es stößt, ein Ende an einer Hauswand in deren Mitte.
## Die Beulen verschieben jede Ecke nach ihrer Lage in der Welt – wo sich zwei Stücke treffen, liegen ihre
## Ecken auf derselben Stelle, es bleibt keine Fuge.

const HEIGHT := 1.6
const WIDTH := 0.5
## Oben um diesen Anteil der Breite schmaler als unten – geschnittene Hecken laufen nach oben leicht zu
const TAPER := 0.08
## Radius der abgerundeten Oberkante und Zahl ihrer Abschnitte
const ROUND := 0.12
const ROUND_STEPS := 4
## Rasterweite des Netzes entlang der Linie und die Seiten hinauf
const STEP := 0.2
## Beulen: größte Verschiebung in Metern und Frequenz des Rauschens (1/m)
const BUMP := 0.06
const BUMP_FREQ := 1.5
## Oben wandert die Kante stärker auf und ab (Faktor für die Höhe) – der Umriss gegen den Himmel
const BUMP_TOP := 1.6
## Unten im Schatten dunkler (Anteil der Helligkeit am Boden), bis zu dieser Höhe aufgehellt
const SHADE_GROUND := 0.55
const SHADE_UP := 1.2
## Textur des Heckenkörpers: Wiederholungen je Meter (TexGen „hedge“)
const TEX_SCALE := 2.0
## Blattkarten je Meter Linie an der Oberkante und an den Seiten (beide zusammen), Kantenlänge von … bis;
## so tief stecken sie in der Fläche (der Rest ragt heraus)
const CARDS_TOP := 24.0
const CARDS_SIDE := 10.0
const CARD_SIZE := Vector2(0.18, 0.3)
const CARD_SINK := 0.04
## Breite der Linien im Plan; so nah muss ein Linienende an einer anderen Linie liegen, um sie zu berühren
const LINE := 0.2
const TOUCH := 0.11
## So weit darf ein Linienende von der Mittellinie einer Hauswand entfernt sein, die es abschließt
const WALL_SNAP := 0.15


## Gerade Hecke aus dem Plan: Achse (0 = entlang x, 1 = entlang z), Lage der Mittellinie quer dazu,
## Enden entlang der Achse wie im Plan, Gruppe (Linienzug im Plan) und die beiden Abschlüsse.
class Line:
	var axis: int
	var c: float
	var a0: float
	var a1: float
	var group: int
	var ends: Array[End] = []


## Abschluss einer Linie bei at (entlang der Achse): „cap“ = Stirnfläche, „open“ = steckt in der Hecke,
## auf die sie stößt, „miter“ = Gehrung zur Hecke, die hier um die Ecke weiterläuft (sigma: in welche
## Richtung quer zur Linie sie weiterläuft, ±1).
class End:
	var at: float
	var kind: String
	var sigma: float

	func _init(at_: float, kind_: String, sigma_: float = 0.0) -> void:
		at = at_
		kind = kind_
		sigma = sigma_

	## Lage des Abschlusses für einen Punkt im Abstand s quer zur Mittellinie; out = −1 Anfang, +1 Ende
	func along(out: float, s: float) -> float:
		return at - out * sigma * s if kind == "miter" else at


## Ecken, Normalen, Farben, Indizes und UVs eines Meshs im Aufbau
class Parts:
	var verts := PackedVector3Array()
	var normals := PackedVector3Array()
	var colors := PackedColorArray()
	var indices := PackedInt32Array()
	var uvs := PackedVector2Array()

	func mesh() -> ArrayMesh:
		return Geo.add_surface(ArrayMesh.new(), verts, normals, indices, uvs, colors)


## Baut alle Hecken unter parent: groups = Linienzüge aus dem Plan (je eine Liste von Rechtecken
## [x0, z0, x1, z1]), walls = Wände aus dem Plan (Enden an Hauswänden reichen bis in deren Mitte).
static func build(parent: Node3D, groups: Array, walls: Array) -> void:
	var lines := _lines(groups)
	for line in lines:
		line.ends.append(_end(line, -1, lines, walls))
		line.ends.append(_end(line, 1, lines, walls))
	var noise := FastNoiseLite.new()
	noise.seed = 13
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.frequency = BUMP_FREQ
	noise.fractal_octaves = 2
	var profile := _profile()
	var body_mat := Mat.psx(Color(1, 1, 1), "hedge", TEX_SCALE, Color.BLACK, 0.0, false)
	body_mat.set_shader_parameter("use_vertex_color", true)
	var leaf_mat := Mat.leaves("leaves")
	for g in groups.size():
		var body := Parts.new()
		var cards := Parts.new()
		for line in lines:
			if line.group != g:
				continue
			_body(body, line, profile, noise)
			_cards(cards, line, profile, noise)
			var from := line.ends[0].along(-1.0, 0.0)
			var to := line.ends[1].along(1.0, 0.0)
			var mid := _world(line, (from + to) / 2.0, 0.0, HEIGHT / 2.0)
			var size := Vector3(to - from, HEIGHT, WIDTH) if line.axis == 0 else Vector3(WIDTH, HEIGHT, to - from)
			Geo.collider(parent, size, mid)
		if not body.verts.is_empty():
			Geo.mesh(parent, body.mesh(), body_mat, Vector3.ZERO).name = "Hecke"
		if not cards.verts.is_empty():   # sehr kurze Linien bekommen keine Karte (leere Fläche wäre ein Fehler)
			Geo.mesh(parent, cards.mesh(), leaf_mat, Vector3.ZERO).name = "Heckenblaetter"


## Rechtecke des Plans als Linien; Stücke auf derselben Mittellinie, die sich berühren, werden eine Linie
## (der Plan teilt eine Linie dort, wo ein Querstück anstößt).
static func _lines(groups: Array) -> Array[Line]:
	var lines: Array[Line] = []
	for g in groups.size():
		for rc in groups[g]:
			var x0 := float(rc[0])
			var z0 := float(rc[1])
			var x1 := float(rc[2])
			var z1 := float(rc[3])
			var line := Line.new()
			line.axis = 0 if x1 - x0 >= z1 - z0 else 1
			line.c = (z0 + z1) / 2.0 if line.axis == 0 else (x0 + x1) / 2.0
			line.a0 = x0 if line.axis == 0 else z0
			line.a1 = x1 if line.axis == 0 else z1
			line.group = g
			lines.append(line)
	var merged := true
	while merged:
		merged = false
		for i in lines.size():
			for j in range(i + 1, lines.size()):
				var a := lines[i]
				var b := lines[j]
				if a.axis == b.axis and absf(a.c - b.c) < 0.01 and b.a0 <= a.a1 + 2.0 * TOUCH and a.a0 <= b.a1 + 2.0 * TOUCH:
					a.a0 = minf(a.a0, b.a0)
					a.a1 = maxf(a.a1, b.a1)
					lines.remove_at(j)
					merged = true
					break
			if merged:
				break
	return lines


## Abschluss am Anfang (out = −1) oder Ende (+1) einer Linie: stößt sie auf eine Hecke quer dazu, die hier
## ebenfalls endet → Gehrung, sonst endet sie in deren Mitte. Frei endend reicht sie bis in die Mitte einer
## Hauswand, falls eine dicht davor liegt.
static func _end(line: Line, out: int, lines: Array[Line], walls: Array) -> End:
	var at := line.a1 if out > 0 else line.a0
	var p := _plan(line, at)
	var tee: End = null
	for other in lines:
		if other.axis == line.axis:
			continue
		var r := Rect2(_plan(other, other.a0) - Vector2(LINE, LINE) / 2.0, Vector2.ZERO)
		r = r.expand(_plan(other, other.a1) + Vector2(LINE, LINE) / 2.0).grow(TOUCH)
		if not r.has_point(p):
			continue
		if absf(line.c - other.a0) < WIDTH / 2.0:
			return End.new(other.c, "miter", 1.0)
		if absf(line.c - other.a1) < WIDTH / 2.0:
			return End.new(other.c, "miter", -1.0)
		tee = End.new(other.c, "open")
	if tee != null:
		return tee
	var best := WALL_SNAP
	var wall_at := at
	for w in walls:
		var a := Vector2(float(w["a"][0]), float(w["a"][1]))
		var b := Vector2(float(w["b"][0]), float(w["b"][1]))
		var k := line.axis   # Wand quer zur Linie: gleiche Lage entlang der Linie an beiden Enden
		if absf(a[k] - b[k]) > 0.01 or absf(a[k] - at) > best:
			continue
		if line.c < minf(a[1 - k], b[1 - k]) or line.c > maxf(a[1 - k], b[1 - k]):
			continue
		best = absf(a[k] - at)
		wall_at = a[k]
	return End.new(wall_at, "cap")


## Querschnitt: Punkte (quer, Höhe) von unten links die Seite hinauf, über die runde Oberkante und auf der
## anderen Seite hinab – spiegelgleich, damit Gehrungen Ecke auf Ecke treffen.
static func _profile() -> PackedVector2Array:
	var top := HEIGHT - ROUND
	var hw := _half(top)
	var left := PackedVector2Array()
	var rows := ceili(top / STEP)
	for k in rows + 1:
		var y := top * k / rows
		left.append(Vector2(-_half(y), y))
	for k in range(1, ROUND_STEPS + 1):
		var angle := PI - PI / 2.0 * k / ROUND_STEPS
		left.append(Vector2(-hw + ROUND, top) + Vector2(cos(angle), sin(angle)) * ROUND)
	var flat := maxi(1, ceili((hw - ROUND) / STEP))
	for k in range(1, flat + 1):
		left.append(Vector2(lerpf(-hw + ROUND, 0.0, float(k) / flat), HEIGHT))
	var all := left.duplicate()
	for i in range(left.size() - 2, -1, -1):
		all.append(Vector2(-left[i].x, left[i].y))
	return all


## Halbe Breite in der Höhe y (über der Rundung wie an ihrem Beginn)
static func _half(y: float) -> float:
	return WIDTH / 2.0 * (1.0 - TAPER * minf(y, HEIGHT - ROUND) / HEIGHT)


## Normale des Querschnitts nach außen am Punkt i (quer, Höhe)
static func _profile_normal(profile: PackedVector2Array, i: int) -> Vector2:
	var t := profile[mini(i + 1, profile.size() - 1)] - profile[maxi(i - 1, 0)]
	return Vector2(-t.y, t.x).normalized()


## Punkt im Plan (x, z) auf der Mittellinie bei along
static func _plan(line: Line, along: float) -> Vector2:
	return Vector2(along, line.c) if line.axis == 0 else Vector2(line.c, along)


## Punkt in der Welt: along entlang der Linie, s quer zur Mittellinie, y Höhe
static func _world(line: Line, along: float, s: float, y: float) -> Vector3:
	return Vector3(along, y, line.c + s) if line.axis == 0 else Vector3(line.c + s, y, along)


## Richtung in der Welt aus (quer, Höhe) des Querschnitts
static func _world_dir(line: Line, d: Vector2) -> Vector3:
	return Vector3(0.0, d.y, d.x) if line.axis == 0 else Vector3(d.x, d.y, 0.0)


## Verschiebung der Ecke an p – nur nach ihrer Lage, damit gleiche Ecken zweier Stücke gleich wandern;
## am Boden nur waagrecht, oben stärker in der Höhe
static func _bump(noise: FastNoiseLite, p: Vector3) -> Vector3:
	var d := Vector3(noise.get_noise_3dv(p), noise.get_noise_3dv(p + Vector3(91.7, 13.1, 0.0)),
		noise.get_noise_3dv(p + Vector3(0.0, 41.9, 77.3)))
	d.y *= lerpf(1.0, BUMP_TOP, smoothstep(HEIGHT - 0.4, HEIGHT, p.y)) if p.y > 0.01 else 0.0
	return d * BUMP


## Helligkeit in der Höhe y (unten im Schatten der Hecke dunkler), leicht gesprenkelt
static func _shade(y: float, speckle: float) -> Color:
	var v := lerpf(SHADE_GROUND, 1.0, smoothstep(0.0, SHADE_UP, y)) * (0.85 + 0.15 * speckle)
	return Color(v, v, v)


## Heckenkörper einer Linie an out anhängen
static func _body(out: Parts, line: Line, profile: PackedVector2Array, noise: FastNoiseLite) -> void:
	var base := out.verts.size()
	var e0 := line.ends[0]
	var e1 := line.ends[1]
	var rows := maxi(1, ceili((e1.along(1.0, 0.0) - e0.along(-1.0, 0.0)) / STEP))
	var n := rows + 1
	var grid := PackedVector3Array()
	for i in profile.size():
		var s := profile[i].x
		var y := profile[i].y
		var from := e0.along(-1.0, s)
		var to := e1.along(1.0, s)
		for k in n:
			var p := _world(line, lerpf(from, to, float(k) / rows), s, y)
			var d := _bump(noise, p)
			grid.append(p + d)
			out.colors.append(_shade(y, d.x / BUMP))
	out.verts.append_array(grid)
	var m := profile.size()
	for i in m:
		var outward := _world_dir(line, _profile_normal(profile, i))
		for k in n:
			var du := grid[i * n + mini(k + 1, rows)] - grid[i * n + maxi(k - 1, 0)]
			var dv := grid[mini(i + 1, m - 1) * n + k] - grid[maxi(i - 1, 0) * n + k]
			var nn := du.cross(dv).normalized()
			out.normals.append(nn if nn.dot(outward) >= 0.0 else -nn)
	# Umlaufsinn einmal je Linie: Godot zeichnet Dreiecke, die von vorn im Uhrzeigersinn umlaufen
	var e_along := grid[1] - grid[0]
	var e_up := grid[n] - grid[0]
	var flip := e_along.cross(e_up).dot(_world_dir(line, _profile_normal(profile, 0))) > 0.0
	for i in m - 1:
		for k in rows:
			var c0 := base + i * n + k
			var c1 := c0 + 1
			var c2 := c1 + n
			var c3 := c0 + n
			if flip:
				out.indices.append_array([c0, c2, c1, c0, c3, c2])
			else:
				out.indices.append_array([c0, c1, c2, c0, c2, c3])
	# Stirnflächen: Fächer um die Mitte des Querschnitts
	for side in 2:
		var end := line.ends[side]
		if end.kind != "cap":
			continue
		var k := 0 if side == 0 else rows
		var normal := (Vector3.RIGHT if line.axis == 0 else Vector3.BACK) * (-1.0 if side == 0 else 1.0)
		var center := _world(line, end.at, 0.0, HEIGHT / 2.0)
		center += _bump(noise, center)
		var first := out.verts.size()
		out.verts.append(center)
		out.normals.append(normal)
		out.colors.append(_shade(HEIGHT / 2.0, 0.0))
		for i in m:
			out.verts.append(grid[i * n + k])
			out.normals.append(normal)
			out.colors.append(out.colors[base + i * n + k])
		for i in m:
			var a := first + 1 + i
			var b := first + 1 + (i + 1) % m
			if (out.verts[a] - center).cross(out.verts[b] - center).dot(normal) > 0.0:
				out.indices.append_array([first, b, a])
			else:
				out.indices.append_array([first, a, b])


## Blattkarten einer Linie an out anhängen: kleine Büschel, die zur Hälfte aus der Fläche ragen, meist an der
## Oberkante. Die Normalen kommen von der Fläche darunter.
static func _cards(out: Parts, line: Line, profile: PackedVector2Array, noise: FastNoiseLite) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(Vector3(line.axis, line.c, line.a0))
	var length := line.ends[1].along(1.0, 0.0) - line.ends[0].along(-1.0, 0.0)
	var top_points: Array[int] = []   # Abschnitte des Querschnitts an der Oberkante
	for i in profile.size() - 1:
		if profile[i].y >= HEIGHT - ROUND - 0.01 and profile[i + 1].y >= HEIGHT - ROUND - 0.01:
			top_points.append(i)
	var n_top := roundi(CARDS_TOP * length)
	for j in n_top + roundi(CARDS_SIDE * length):
		var s: float
		var y: float
		var normal2: Vector2
		if j < n_top:
			var i: int = top_points[rng.randi() % top_points.size()]
			var t := rng.randf()
			s = lerpf(profile[i].x, profile[i + 1].x, t)
			y = lerpf(profile[i].y, profile[i + 1].y, t)
			normal2 = _profile_normal(profile, i).lerp(_profile_normal(profile, i + 1), t).normalized()
		else:
			var side := -1.0 if rng.randf() < 0.5 else 1.0
			y = rng.randf_range(0.1, HEIGHT - ROUND)
			s = side * _half(y)
			normal2 = Vector2(side, 0.0)
		var lo := _card_limit(line.ends[0], -1.0, s)
		var hi := _card_limit(line.ends[1], 1.0, s)
		if hi <= lo:
			continue
		var p := _world(line, rng.randf_range(lo, hi), s, y)
		var d := _bump(noise, p)
		var normal := _world_dir(line, normal2)
		var jitter := Vector3(rng.randf_range(-1, 1), rng.randf_range(-1, 1), rng.randf_range(-1, 1))
		var up := (normal + jitter * 0.5 + (Vector3.UP * 0.4 if j < n_top else Vector3.ZERO)).normalized()
		var across := up.cross(Vector3(rng.randf_range(-1, 1), rng.randf_range(-1, 1), rng.randf_range(-1, 1)))
		if across.length() < 0.01:
			across = up.cross(Vector3.UP if absf(up.y) < 0.9 else Vector3.RIGHT)
		across = across.normalized()
		var size := rng.randf_range(CARD_SIZE.x, CARD_SIZE.y)
		var center := p + d - normal * CARD_SINK
		var low := center - up * size * 0.4
		var high := center + up * size * 0.6
		var first := out.verts.size()
		var color := _shade(y, d.x / BUMP) * rng.randf_range(0.85, 1.1)
		var corners := [low - across * size / 2.0, low + across * size / 2.0, high + across * size / 2.0, high - across * size / 2.0]
		var uvs := [Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0)]
		for c in 4:
			out.verts.append(corners[c])
			out.normals.append(normal)
			out.colors.append(color)
			out.uvs.append(uvs[c])
		out.indices.append_array([first, first + 1, first + 2, first, first + 2, first + 3])


## Wie weit Blattkarten zum Abschluss hin reichen: nicht in die Hecke hinein, in der eine Linie endet
static func _card_limit(end: End, out: float, s: float) -> float:
	return end.at - out * WIDTH / 2.0 if end.kind == "open" else end.along(out, s)

