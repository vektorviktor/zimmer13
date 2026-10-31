class_name Deck
## Holzdeck auf Terrassen und Balkonen (ZIM-127, Foto des Nutzers 31.10.): helle Lärchenbretter mit Ästen, 14,5 cm
## breit, 8 mm Fuge, darunter dunkel. Die Bretter sind echte Geometrie (Oberseite, gefaste Längskanten, Seiten,
## Hirnholz an den Enden), damit die Fugen auch flach von der Seite Tiefe haben. Über die ganze Fläche in Reihen –
## auch über die Nahtstellen der Plan-Rechtecke (L-Formen); wo die Fläche eine Reihe nur teils deckt, ist das Brett
## schmaler aufgetrennt. Längere Läufe haben versetzte Stöße. Zu Wand und Hecke bzw. Geländer bleibt eine Fuge
## (der Aufrufer sagt, wie breit). Oberkante auf Fußbodenhöhe (y = 0); Kollision und dunklen Unterbau baut der
## LevelBuilder. Ein Mesh je Fläche mit zwei Flächen (Längsholz, Hirnholz).

## Brett: Breite, Fuge zwischen den Reihen, Stärke, Fase an den Längskanten, Stoßfuge, Längen (kürzestes Stück,
## längstes Brett)
const BOARD := 0.145
const GAP := 0.008
const THICK := 0.028
const CHAMFER := 0.003
const JOINT := 0.004
const MIN_PIECE := 0.6
const MAX_BOARD := 4.0
## Maserung (Wood_02, Faser im Bild waagerecht): so viele Meter je Kachel längs und quer; Farbe wie im Foto (helle
## Lärche, leicht vergraut); so glatt, wenn ganz nass (Weather)
const GRAIN := Vector2(1.2, 0.25)
const END_METERS := 0.1
const TINT := Color(1.45, 1.4, 1.5)
const WET_GLOSS := 0.75
## Brett schmaler als das wird weggelassen
const MIN_WIDTH := 0.03

static var _wood: ShaderMaterial
static var _end: ShaderMaterial


## Deck über rects (Plan-Rechtecke einer Fläche, x/z in Metern). along_x: Bretter laufen entlang x, sonst entlang z.
## gap_at(p: Vector2, out: Vector2) -> float: so weit bleibt das Brett von der Kante bei p (Außenrichtung out) weg.
static func build(parent: Node3D, rects: Array[Rect2], along_x: bool, gap_at: Callable, seed: int) -> MeshInstance3D:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	# in (u, v): u = Laufrichtung, v = quer
	var uv_rects: Array[Rect2] = []
	for r in rects:
		uv_rects.append(r if along_x else Rect2(r.position.y, r.position.x, r.size.y, r.size.x))
	var to_plan := func(u: float, v: float) -> Vector2: return Vector2(u, v) if along_x else Vector2(v, u)
	var dir_plan := func(du: float, dv: float) -> Vector2: return Vector2(du, dv) if along_x else Vector2(dv, du)
	var inside := func(u: float, v: float) -> bool:
		return uv_rects.any(func(r: Rect2) -> bool: return r.grow(0.001).has_point(Vector2(u, v)))
	var bounds := uv_rects[0]
	for r in uv_rects:
		bounds = bounds.merge(r)
	var wood := GrandStair.Shape.new()
	var ends := GrandStair.Shape.new()
	var a := bounds.position.y
	while a < bounds.end.y - MIN_WIDTH:
		var b := minf(a + BOARD, bounds.end.y)
		for piece in _row_pieces(uv_rects, a, b):
			var u0: float = piece.x
			var u1: float = piece.y
			var v0: float = piece.z
			var v1: float = piece.w
			var um := (u0 + u1) / 2.0
			var vm := (v0 + v1) / 2.0
			u0 += gap_at.call(to_plan.call(u0, vm), dir_plan.call(-1, 0))
			u1 -= gap_at.call(to_plan.call(u1, vm), dir_plan.call(1, 0))
			if not inside.call(um, v0 - 0.05):
				v0 += gap_at.call(to_plan.call(um, v0), dir_plan.call(0, -1))
			if not inside.call(um, v1 + 0.05):
				v1 -= gap_at.call(to_plan.call(um, v1), dir_plan.call(0, 1))
			if v1 - v0 < MIN_WIDTH or u1 - u0 < MIN_PIECE / 2.0:
				continue
			for cut in _cuts(u0, u1, rng):
				_board(wood, ends, cut.x, cut.y, v0, v1, Vector2(rng.randf(), rng.randf()), along_x)
		a += BOARD + GAP
	var mesh := ArrayMesh.new()
	wood.st.commit(mesh)
	ends.st.commit(mesh)
	mesh.surface_set_material(0, _wood_material())
	mesh.surface_set_material(1, _end_material())
	return Geo.mesh(parent, mesh, null, Vector3.ZERO)


## Stücke einer Brettreihe [a, b] als (u0, u1, v0, v1): Die Reihe wird an den v-Kanten der Rechtecke in Streifen
## geteilt; je u-Abschnitt reicht das Brett über die Streifen, die dort Fläche sind. Gleiche Breite hintereinander
## ist ein Stück.
static func _row_pieces(rects: Array[Rect2], a: float, b: float) -> Array[Vector4]:
	var cuts: Array[float] = [a, b]
	for r in rects:
		for v in [r.position.y, r.end.y]:
			if v > a + 0.001 and v < b - 0.001:
				cuts.append(v)
	cuts.sort()
	var strips := []   # [v0, v1, Intervalle in u]
	var us: Array[float] = []
	for i in cuts.size() - 1:
		var spans: Array[Vector2] = []
		for r in rects:
			if r.position.y <= cuts[i] + 0.001 and r.end.y >= cuts[i + 1] - 0.001:
				spans.append(Vector2(r.position.x, r.end.x))
				us.append_array([r.position.x, r.end.x])
		strips.append([cuts[i], cuts[i + 1], spans])
	us.sort()
	var out: Array[Vector4] = []
	for i in us.size() - 1:
		if us[i + 1] - us[i] < 0.001:
			continue
		var m := (us[i] + us[i + 1]) / 2.0
		var v0 := INF
		var v1 := -INF
		for s: Array in strips:
			if (s[2] as Array).any(func(span: Vector2) -> bool: return m > span.x and m < span.y):
				v0 = minf(v0, s[0])
				v1 = maxf(v1, s[1])
		if v0 == INF:
			continue
		if not out.is_empty() and is_equal_approx(out[-1].y, us[i]) and is_equal_approx(out[-1].z, v0) \
				and is_equal_approx(out[-1].w, v1):
			out[-1].y = us[i + 1]
		else:
			out.append(Vector4(us[i], us[i + 1], v0, v1))
	return out


## Bretter eines Stücks [u0, u1]: bis MAX_BOARD am Stück, sonst Stöße an zufälliger Stelle (je Reihe anders), kein
## Rest unter MIN_PIECE
static func _cuts(u0: float, u1: float, rng: RandomNumberGenerator) -> Array[Vector2]:
	var out: Array[Vector2] = []
	var start := u0
	var first := true
	while u1 - start > MAX_BOARD:
		var length := rng.randf_range(MIN_PIECE, MAX_BOARD) if first else rng.randf_range(MAX_BOARD * 0.6, MAX_BOARD)
		length = minf(length, u1 - start - MIN_PIECE)
		first = false
		out.append(Vector2(start, start + length))
		start += length + JOINT
	out.append(Vector2(start, u1))
	return out


## Ein Brett von u0 bis u1, quer v0 bis v1 (Oberkante y = 0): Oberseite, Fasen, Seiten, Hirnholz an beiden Enden;
## unten offen. UVs in Kacheln der Maserung, je Brett ein anderer Ausschnitt (shift).
static func _board(wood: GrandStair.Shape, ends: GrandStair.Shape, u0: float, u1: float, v0: float, v1: float,
		shift: Vector2, along_x: bool) -> void:
	var c := minf(CHAMFER, (v1 - v0) / 4.0)
	var p := func(u: float, v: float, y: float) -> Vector3: return Vector3(u, y, v) if along_x else Vector3(v, y, u)
	var d := func(du: float, dv: float, dy: float) -> Vector3: return Vector3(du, dy, dv) if along_x else Vector3(dv, dy, du)
	# Querschnitt von links unten über die Oberseite nach rechts unten: (v, y)
	var section := [Vector2(v0, -THICK), Vector2(v0, -c), Vector2(v0 + c, 0.0), Vector2(v1 - c, 0.0), Vector2(v1, -c),
		Vector2(v1, -THICK)]
	var across := 0.0
	var steps := maxi(1, ceili((u1 - u0) / Geo.MAX_FACE))
	for i in section.size() - 1:
		var s0: Vector2 = section[i]
		var s1: Vector2 = section[i + 1]
		var edge := s1 - s0
		var n: Vector3 = d.call(0.0, -edge.y, edge.x).normalized()   # der Querschnitt läuft im Uhrzeigersinn: außen
		var w0 := across
		across += edge.length()
		for k in steps:
			var ua := lerpf(u0, u1, float(k) / steps)
			var ub := lerpf(u0, u1, float(k + 1) / steps)
			var uv := [Vector2(ua - u0, w0), Vector2(ub - u0, w0), Vector2(ub - u0, across), Vector2(ua - u0, across)]
			for j in 4:
				uv[j] = Vector2(uv[j].x / GRAIN.x, uv[j].y / GRAIN.y) + shift
			wood.quad(p.call(ua, s0.x, s0.y), p.call(ub, s0.x, s0.y), p.call(ub, s1.x, s1.y), p.call(ua, s1.x, s1.y), n, uv)
	for e in [[u0, -1.0], [u1, 1.0]]:
		var n: Vector3 = d.call(e[1], 0.0, 0.0)
		var pts := []
		var uvs := []
		for s: Vector2 in section:
			pts.append(p.call(e[0], s.x, s.y))
			uvs.append(Vector2(s.x - v0, -s.y) / END_METERS + shift)
		for j in range(1, pts.size() - 1):
			ends.tri(pts[0], pts[j], pts[j + 1], n, n, n, uvs[0], uvs[j], uvs[j + 1])


static func _wood_material() -> ShaderMaterial:
	if _wood == null:
		_wood = Mat.photo(Mat.WOOD_TEX, 1.0, Mat.WOOD_NORMAL, "", 0.3, TINT, false, true)
		Mat.wettable(_wood, WET_GLOSS)
		_wood.set_meta("floor", "wood")
	return _wood


static func _end_material() -> ShaderMaterial:
	if _end == null:
		_end = Mat.psx(Color(TINT.r * 0.8, TINT.g * 0.8, TINT.b * 0.8), "", 1.0, Color.BLACK, 0.0, false)
		_end.set_shader_parameter("albedo_tex", TexGen.get_tex("wood_end"))
		Mat.wettable(_end, WET_GLOSS)
	return _end
