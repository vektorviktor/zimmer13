class_name Cornice
## Zierleiste oben an den Wänden (ZIM-131, Entscheidung 3.11., Spielkonzept 7.2, 9.2): gestuftes Kranzgesims aus
## elfenbein gestrichenem Stuck – Plättchen, Rundstab, Hohlkehle, Viertelstab, Deckplatte –, HEIGHT hoch und DEPTH
## vor der Wand, in Lobby und Speisesaal um GRAND größer. Unten das Holz der Vertäfelung, oben hell wie im Grandhotel.
## LevelBuilder._cornice meldet wie bei der Vertäfelung je Wandseite die freien Stücke (zwischen anstoßenden Wänden und
## Holzpfeilern; Türen und Fenster reichen nicht so hoch) und die Außenecken der Wandköpfe (add_corner).
## Gehrung: An Innenecken laufen beide Stücke bis an die Wand – zwei gleiche Profile, die sich rechtwinklig
## durchdringen, schneiden sich genau auf der Gehrung (das Profil hat je Höhe einen Abstand vor der Wand). An Außenecken
## verlängert sich jeder Punkt des Profils um seinen eigenen Abstand vor der Wand. Sonst enden die Stücke gerade mit
## Stirnseite. Das Profil beginnt INSET in der Wand und endet INSET in der Decke – keine Fläche liegt auf einer anderen.
## Ein Mesh je Zelle von CELL Metern (Sichtprüfung), ohne Schatten und Kollision, nicht im Spielstand. Karten aus
## tools/cornice_stucco.gd: längs ALONG Meter je Kachel, quer das abgewickelte Profil (v = Anteil der Bogenlänge).

## Höhe an der Wand und Ausladung an der Decke (m); so viel größer in Lobby und Speisesaal
const HEIGHT := 0.12
const DEPTH := 0.1
const GRAND := 1.6
## So tief steckt das Profil in Wand und Decke
const INSET := 0.003
## Kanten flacher als dieser Winkel (Grad) werden weich schattiert (Rundstab, Kehle, Viertelstab)
const CREASE := 35.0
## Abschnitte bis zu dieser Länge (m, bei Größe 1) – die Unterseiten der Plättchen – nehmen die Normale ihrer Nachbarn:
## Ohne Kantenglättung flimmerten sie sonst aus ein paar Metern als gestrichelte dunkle Linien
const SOFT_STEP := 0.0055
const CELL := 16.0
## Kürzere Stücke fallen weg
const MIN_PIECE := 0.005
## Karten: so viele Meter längs je Kachel (= tools/cornice_stucco.gd ALONG_M)
const ALONG := 1.0
const TEX := "res://assets/textures/cornice.png"
const TEX_NORMAL := "res://assets/textures/cornice_normal.png"
const TEX_ROUGH := "res://assets/textures/cornice_rough.png"

static var _mat: ShaderMaterial

var _top: float
var _cells := {}   # Vector2i(Zelle x, Zelle z) → {"v", "n", "uv", "i"}
var _cap := false


## top = Höhe der Decke über dem Boden des Stockwerks. cap: oben eine Abdeckung über die ganze Ausladung (draußen am
## Dach, wo keine Decke das Profil schließt).
func _init(top: float, cap := false) -> void:
	_top = top
	_cap = cap


## Umriss des Gesimses bei Größe 1 als (Abstand vor der Wand, Höhe zur Decke) von der Unterkante in der Wand bis in die
## Decke; die Höhe ist negativ (unter der Decke). Auch für die Karten (tools/cornice_stucco.gd).
static func profile() -> Array[Vector2]:
	var p: Array[Vector2] = [Vector2(-INSET, -HEIGHT), Vector2(0.006, -HEIGHT), Vector2(0.006, -0.113)]
	for i in range(1, 9):   # Rundstab, Halbkreis 6,5 mm
		var a := PI * i / 8.0
		p.append(Vector2(0.006 + 0.0065 * sin(a), -0.1065 - 0.0065 * cos(a)))
	p.append_array([Vector2(0.01, -0.1), Vector2(0.01, -0.095)])
	for i in range(1, 13):   # Hohlkehle, 5,2 cm hinaus, 5,5 cm hoch
		var a := PI / 2.0 * i / 12.0
		p.append(Vector2(0.062 - 0.052 * cos(a), -0.095 + 0.055 * sin(a)))
	p.append_array([Vector2(0.068, -0.04), Vector2(0.068, -0.036)])
	for i in range(1, 9):   # Viertelstab, 2,2 cm hinaus, 2 cm hoch
		var a := PI / 2.0 * i / 8.0
		p.append(Vector2(0.068 + 0.022 * sin(a), -0.036 + 0.02 * (1.0 - cos(a))))
	# Deckplatte, Plättchen an der Decke
	p.append_array([Vector2(0.096, -0.016), Vector2(0.096, -0.005), Vector2(DEPTH, -0.005), Vector2(DEPTH, INSET)])
	return p


## Bogenlänge entlang profile() bis zu jedem Punkt (Größe 1).
static func arcs() -> Array[float]:
	var p := profile()
	var arc: Array[float] = [0.0]
	for k in range(1, p.size()):
		arc.append(arc[-1] + p[k].distance_to(p[k - 1]))
	return arc


static func material() -> ShaderMaterial:
	if _mat == null:
		_mat = Mat.photo(TEX, 1.0, TEX_NORMAL, TEX_ROUGH, 0.5, Color(1, 1, 1), false, true)
	return _mat


## Stück auf einer Wandfläche wie Wainscot.add_run: Punkt der Fläche bei Länge 0 (origin, auf Bodenhöhe), Richtung der
## Wand along, Normale out; von a bis b, Größe size (1 oder GRAND). mitre_a/mitre_b: Außenecke an diesem Ende.
func add_run(origin: Vector3, along: Vector3, out: Vector3, a: float, b: float, size: float, mitre_a := false,
		mitre_b := false) -> void:
	if b - a < MIN_PIECE:
		return
	# an den Zellgrenzen teilen (dort ohne Stirnseite)
	var axis := 0 if absf(along.x) > 0.5 else 2
	var w0 := (origin + along * a)[axis]
	var dir := along[axis]
	var cuts: Array[float] = []
	var w1 := w0 + dir * (b - a)
	for k in range(ceili(minf(w0, w1) / CELL), floori(maxf(w0, w1) / CELL) + 1):
		var t := a + (k * CELL - w0) / dir
		if t > a + MIN_PIECE and t < b - MIN_PIECE:
			cuts.append(t)
	cuts.sort()
	cuts.push_front(a)
	cuts.append(b)
	for i in cuts.size() - 1:
		var first := i == 0
		var last := i == cuts.size() - 2
		_piece(origin, along, out, cuts[i], cuts[i + 1], size, 1 if first and mitre_a else (2 if first else 0),
			1 if last and mitre_b else (2 if last else 0))


## Eckstück um die Außenecke corner (auf Bodenhöhe) wie Wainscot.add_corner: Fläche A mit Normale na läuft la weit von
## der Ecke weg, Fläche B mit Normale nb lb weit; Größe sa bzw. sb (0 = dort keine Leiste). Tragen beide eine, treffen
## sie sich auf Gehrung (in der Größe von A), sonst endet die eine gerade an der Ecke.
func add_corner(corner: Vector3, na: Vector3, nb: Vector3, la: float, lb: float, sa: float, sb: float) -> void:
	if sa > 0.0:
		add_run(corner, -nb, na, 0.0, la, sa, sb > 0.0)
	if sb > 0.0:
		add_run(corner, -na, nb, 0.0, lb, sa if sa > 0.0 else sb, sa > 0.0)


## Konsole unter dem Gesims bei t entlang der Wand (wie add_run), width breit (m, nicht skaliert): Seitenansicht
## bracket_outline() × size, gerade herausgezogen. Fürs Kranzgesims am Dach (LevelBuilder._roof_cornice).
func add_bracket(origin: Vector3, along: Vector3, out: Vector3, t: float, size: float, width: float) -> void:
	var c := _cell(origin + along * t)
	var verts: Array = c["v"]
	var normals: Array = c["n"]
	var uvs: Array = c["uv"]
	var idx: Array = c["i"]
	var outline := bracket_outline()
	for k in outline.size():
		outline[k] *= size
	var at := func(p: Vector2, s: float) -> Vector3:
		return origin + along * s + out * p.x + Vector3.UP * (_top + p.y)
	var tris := Geometry2D.triangulate_polygon(outline)
	for side: float in [-1.0, 1.0]:   # Wangen
		var first := verts.size()
		var s := t + side * width / 2.0
		for p in outline:
			verts.append(at.call(p, s))
			normals.append(along * side)
			uvs.append(Vector2(p.x, p.y) / ALONG)
		for k in range(0, tris.size(), 3):
			_tri(idx, verts, [first + tris[k], first + tris[k + 1], first + tris[k + 2]], along * side)
	for k in outline.size():   # Rücken, ringsum
		var p0 := outline[k]
		var p1 := outline[(k + 1) % outline.size()]
		var d := p1 - p0
		var n2 := Vector2(d.y, -d.x).normalized()
		if Geometry2D.is_point_in_polygon((p0 + p1) / 2.0 + n2 * 0.001, outline):
			n2 = -n2
		var n := out * n2.x + Vector3.UP * n2.y
		var first := verts.size()
		for p: Vector2 in [p0, p1]:
			for s: float in [t - width / 2.0, t + width / 2.0]:
				verts.append(at.call(p, s))
				normals.append(n)
				uvs.append(Vector2(s, p.y) / ALONG)
		_quad(idx, verts, [first, first + 1, first + 3, first + 2], n)


## Seitenansicht einer Konsole bei Größe 1 als (vor der Wand, Höhe zur Oberkante), gegen den Uhrzeigersinn: unten ein
## Zapfen an der Wand, eine Volute nach außen unter die Deckplatte. Steckt oben im Gesims.
static func bracket_outline() -> PackedVector2Array:
	var p := PackedVector2Array([Vector2(-INSET, -0.2), Vector2(0.012, -0.2)])
	for i in range(1, 7):   # unten eingerollt
		var a := PI * i / 6.0
		p.append(Vector2(0.018 + 0.008 * sin(a), -0.192 - 0.008 * cos(a)))
	for i in range(1, 9):   # Hals, hohl geschwungen bis unter die Deckplatte
		var u := float(i) / 8.0
		p.append(Vector2(0.026 + 0.064 * u * u, -0.184 + 0.15 * u))
	p.append_array([Vector2(0.094, -0.026), Vector2(0.094, -0.014), Vector2(-INSET, -0.014)])
	return p


## Baut je Zelle ein Mesh unter parent mit diesem Namen (die Prüfung der Zierleiste sucht „Zierleiste“); shadows:
## Schatten werfen (draußen im Mondlicht, am Dach).
func finish(parent: Node3D, shadows := false, label := "Zierleiste") -> void:
	for key: Vector2i in _cells:
		var c: Dictionary = _cells[key]
		var m := Geo.add_surface(ArrayMesh.new(), PackedVector3Array(c["v"]), PackedVector3Array(c["n"]),
			PackedInt32Array(c["i"]), PackedVector2Array(c["uv"]))
		var mi := Geo.mesh(parent, m, material(), Vector3.ZERO)
		mi.name = label
		if not shadows:
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_cells.clear()


## Mesh-Daten der Zelle um p.
func _cell(p: Vector3) -> Dictionary:
	var key := Vector2i(floori(p.x / CELL), floori(p.z / CELL))
	if not _cells.has(key):
		_cells[key] = {"v": [], "n": [], "uv": [], "i": []}
	return _cells[key]


## Gezogenes Stück von a bis b; Enden end_a/end_b: 0 offen (Zellgrenze), 1 Gehrung, 2 Stirnseite.
func _piece(origin: Vector3, along: Vector3, out: Vector3, a: float, b: float, size: float, end_a: int,
		end_b: int) -> void:
	var c := _cell(origin + along * (a + b) / 2.0)
	var verts: Array = c["v"]
	var normals: Array = c["n"]
	var uvs: Array = c["uv"]
	var idx: Array = c["i"]
	var pts := profile()
	var arc := arcs()
	var total := arc[-1]
	for k in pts.size():
		pts[k] *= size
	var seg_n: Array[Vector2] = []   # Normale je Abschnitt (vor der Wand, oben), zum Raum hin
	for k in pts.size() - 1:
		var t := pts[k + 1] - pts[k]
		seg_n.append(Vector2(t.y, -t.x).normalized())
	var shade := seg_n.duplicate()   # Normale zum Schattieren: kurze Stufen wie ihre Nachbarn
	for k in range(1, seg_n.size() - 1):
		if pts[k + 1].distance_to(pts[k]) <= SOFT_STEP * size:
			shade[k] = (seg_n[k - 1] + seg_n[k + 1]).normalized()
	var limit := cos(deg_to_rad(CREASE))
	var at := func(p: Vector2, t: float) -> Vector3:
		return origin + along * t + out * p.x + Vector3.UP * (_top + p.y)
	for k in seg_n.size():
		var first := verts.size()
		for e: Array in [[k, k - 1], [k + 1, k + 1]]:
			var j: int = e[0]
			var other: int = e[1]
			var n: Vector2 = shade[k]
			if other >= 0 and other < seg_n.size() and (shade[other] as Vector2).dot(n) > limit:
				n = (n + shade[other]).normalized()
			var p := pts[j]
			var ta := a - p.x if end_a == 1 else a
			var tb := b + p.x if end_b == 1 else b
			for t: float in [ta, tb]:
				verts.append(at.call(p, t))
				normals.append(out * n.x + Vector3.UP * n.y)
				uvs.append(Vector2(t / ALONG, arc[j] / total))
		_quad(idx, verts, [first, first + 1, first + 3, first + 2], out * seg_n[k].x + Vector3.UP * seg_n[k].y)
	if _cap:   # Abdeckung oben, von der Vorderkante bis in die Wand
		var first := verts.size()
		for p: Vector2 in [pts[-1], Vector2(-INSET, INSET) * size]:
			for t: float in [a - p.x if end_a == 1 else a, b + p.x if end_b == 1 else b]:
				verts.append(at.call(p, t))
				normals.append(Vector3.UP)
				uvs.append(Vector2(t / ALONG, p.x))
		_quad(idx, verts, [first, first + 1, first + 3, first + 2], Vector3.UP)
	# Stirnseiten: das Profil, geschlossen über die Ecke von Wand und Decke
	var outline := PackedVector2Array(pts)
	outline.append(Vector2(-INSET, INSET) * size)
	var tris := Geometry2D.triangulate_polygon(outline)
	for end: Array in [[end_a, a, -1.0], [end_b, b, 1.0]]:
		if int(end[0]) != 2 or tris.is_empty():
			continue
		var first := verts.size()
		var face: Vector3 = along * float(end[2])
		for p in outline:
			verts.append(at.call(p, float(end[1])))
			normals.append(face)
			uvs.append(Vector2(p.x / ALONG, (p.y / size + HEIGHT) / (HEIGHT + INSET)))
		for k in range(0, tris.size(), 3):
			_tri(idx, verts, [first + tris[k], first + tris[k + 1], first + tris[k + 2]], face)


## Viereck c (Indizes in verts) als zwei Dreiecke, im Uhrzeigersinn von der Seite normal aus gesehen (wie Geo._quad).
static func _quad(idx: Array, verts: Array, c: Array, normal: Vector3) -> void:
	_tri(idx, verts, [c[0], c[1], c[2]], normal)
	_tri(idx, verts, [c[0], c[2], c[3]], normal)


static func _tri(idx: Array, verts: Array, c: Array, normal: Vector3) -> void:
	var e1: Vector3 = verts[c[1]] - verts[c[0]]
	var e2: Vector3 = verts[c[2]] - verts[c[0]]
	if e1.cross(e2).dot(normal) > 0.0:
		idx.append_array([c[0], c[2], c[1]])
	else:
		idx.append_array([c[0], c[1], c[2]])
