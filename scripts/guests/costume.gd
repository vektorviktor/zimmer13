class_name Costume
extends Node3D
## Halloween-Kostüme der Gäste (Spielkonzept 5.9): ab FROM_DAY verkleiden sich die meisten – Bettlaken,
## Hexenhut, Kürbiskopf oder Vampirumhang. Das Bettlaken ist der Kern: eine Lakengestalt im dunklen Flur –
## Gast oder Lakengeist? Unterscheiden kann man sie nur beim genauen Hinsehen: Unter dem Saum schauen die Schuhe
## heraus, sie geht statt zu schweben, ohne Flocken und ohne Geisterklang.
## Welches Kostüm ein Gast trägt, liegt fest an seiner ID (pick) – gespeichert wird nichts.
## Laken und Umhang hängen am Körper (Kind von Guest._visual), Hut und Kürbis folgen jedes Bild dem Kopf (follow).
## Unter dem Laken zeigt der Gast keinen Namen – wer steckt darunter? – und sein Kopf wird kleiner, damit er
## nicht durch den Stoff sticht (GuestBody.head_shrink, bei Klötzchenfiguren ausgeblendet).

const FROM_DAY := 25
const KINDS := ["sheet", "witch", "pumpkin", "cape"]
## Wahrscheinlichkeiten je Kostüm, der Rest bleibt unverkleidet – Kinder lieben das Laken
const WEIGHTS := {"sheet": 0.25, "witch": 0.15, "pumpkin": 0.15, "cape": 0.15}
const CHILD_WEIGHTS := {"sheet": 0.4, "witch": 0.15, "pumpkin": 0.2, "cape": 0.1}
const SHEET_COLOR := Color(0.86, 0.86, 0.88)   ## wie der Lakengeist (SheetGhost)
const SHEET_SEGMENTS := 12
const HEM := 0.16                              ## so hoch über dem Boden endet das Laken – die Schuhe bleiben sichtbar

## Debug (--costumes[=art]): alle Gäste sofort verkleidet – "all" (jeder sein Kostüm, auch wer sonst keins trägt)
## oder eine Art aus KINDS für alle
static var force := ""

var kind := ""
var _head: Node3D        ## Hut oder Kürbis, folgt dem Kopf (top_level)
var _head_lift := 0.0    ## so weit über dem Kopfknochen sitzt der Scheitel


## Kostüm dieses Gastes ("" = keins) – fest nach ID, ab FROM_DAY (oder per Debug sofort).
static func pick(guest: Guest) -> String:
	if force in KINDS:
		return force
	if force == "" and Calendar.today() < FROM_DAY:
		return ""
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(guest.id + ":kostüm")
	var roll := rng.randf()
	var weights: Dictionary = CHILD_WEIGHTS if guest.is_child() else WEIGHTS
	for k in KINDS:
		roll -= float(weights[k])
		if roll < 0.0:
			return k
	return KINDS[rng.randi() % KINDS.size()] if force == "all" else ""


## height: Scheitelhöhe des Gastes (m); head_lift: Scheitel über dem Kopfpunkt, den follow() bekommt; size: 1 bei
## Erwachsenen, kleiner bei Kindern.
func setup(p_kind: String, height: float, head_lift: float, size: float) -> void:
	kind = p_kind
	_head_lift = head_lift
	match kind:
		"sheet":
			_build_sheet(height, size)
		"cape":
			_build_cape(height, size)
		"witch":
			_head = _witch_hat(size)
		"pumpkin":
			_head = _pumpkin_head(size)
	if _head:
		_head.top_level = true
		add_child(_head)


## Jedes Bild: Hut bzw. Kürbis auf den Kopf setzen – aufrecht in Blickrichtung des Körpers, damit er beim Tanzen
## nicht wegkippt. head: Kopfknochen (Weltkoordinaten), facing: Drehung des Gastes.
func follow(head: Vector3, facing: Basis) -> void:
	if _head:
		_head.global_transform = Transform3D(facing.orthonormalized(), head + Vector3.UP * _head_lift)


# --- Bettlaken --------------------------------------------------------------------

## Laken als Drehkörper: Kopfkuppel, gleich darunter über die Schultern, dann weit fallend bis knapp über den Boden, Saum gewellt.
## Augen- und Mundlöcher wie beim Lakengeist. Blick des Gastes: −Z.
func _build_sheet(height: float, size: float) -> void:
	var w := size
	var profile: Array[Vector2] = [   # (Höhe unter dem Scheitel, Radius)
		Vector2(0.0, 0.0), Vector2(0.04, 0.09 * w), Vector2(0.10, 0.15 * w), Vector2(0.19, 0.17 * w),
		Vector2(0.26, 0.25 * w), Vector2(0.34, 0.29 * w), Vector2(0.5, 0.3 * w)]
	var rings: Array[Vector2] = []
	for p in profile:
		rings.append(Vector2(height - p.x * size, p.y))
	rings.append(Vector2(lerpf(HEM, height - 0.5 * size, 0.45), 0.32 * w))
	rings.append(Vector2(HEM, 0.33 * w))
	# Punkte je Ring (oberster Ring = Spitze); Godot: Vorderseite im Uhrzeigersinn
	var points: Array = []
	for i in rings.size():
		var ring: Array[Vector3] = []
		for s in SHEET_SEGMENTS:
			var a := TAU * s / SHEET_SEGMENTS
			ring.append(_hem_point(rings[i], a) if i == rings.size() - 1 else Vector3(sin(a) * rings[i].y, rings[i].x, cos(a) * rings[i].y))
		points.append(ring)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in rings.size() - 1:
		for s in SHEET_SEGMENTS:
			var n := (s + 1) % SHEET_SEGMENTS
			var p00: Vector3 = points[i][s]
			var p01: Vector3 = points[i][n]
			var p10: Vector3 = points[i + 1][s]
			var p11: Vector3 = points[i + 1][n]
			if i > 0:   # die Spitze ist ein Punkt – dort nur ein Dreieck
				st.add_vertex(p00)
				st.add_vertex(p01)
				st.add_vertex(p11)
			st.add_vertex(p00)
			st.add_vertex(p11)
			st.add_vertex(p10)
	st.generate_normals()
	var sheet := MeshInstance3D.new()
	sheet.mesh = st.commit()
	sheet.material_override = Mat.psx(SHEET_COLOR)
	add_child(sheet)
	# Augen und Mund: dunkle, flache Ovale vorn auf der Kuppel
	var hole := Mat.psx(Color(0.03, 0.03, 0.03))
	for side in [-1.0, 1.0]:
		var eye := Geo.mesh(self, Geo.sphere(0.024 * size, 0.034 * size, 6, 3), hole,
			Vector3(side * 0.05 * size, height - 0.13 * size, -0.153 * w))
		eye.scale.z = 0.35
	var mouth := Geo.mesh(self, Geo.sphere(0.022 * size, 0.04 * size, 6, 3), hole,
		Vector3(0, height - 0.215 * size, -0.197 * w))
	mouth.scale.z = 0.35


## Saum: gewellt, nicht ganz rund – so fällt Stoff
func _hem_point(ring: Vector2, angle: float) -> Vector3:
	var r := ring.y + 0.02 * cos(angle * 5.0)
	return Vector3(sin(angle) * r, ring.x + 0.035 * sin(angle * 3.0 + 0.7), cos(angle) * r)


# --- Umhang, Hut, Kürbis -----------------------------------------------------------

## Vampirumhang: dunkler Stoff vom Rücken bis zu den Waden, hoher roter Kragen hinter dem Kopf. Rücken: +Z.
func _build_cape(height: float, size: float) -> void:
	var cloth := Mat.psx(Color(0.07, 0.05, 0.08))
	var top := height - 0.4 * size
	var bottom := 0.45 * size
	var cape := Geo.mesh(self, Geo.box(Vector3(0.52 * size, top - bottom, 0.025)), cloth,
		Vector3(0, (top + bottom) / 2.0, 0.15 * size))
	cape.rotation.x = -0.08   # unten etwas weiter vom Körper weg
	var collar := Geo.mesh(self, Geo.box(Vector3(0.4 * size, 0.22 * size, 0.02)), Mat.psx(Color(0.45, 0.04, 0.06)),
		Vector3(0, height - 0.3 * size, 0.13 * size))
	collar.rotation.x = 0.45   # oben nach hinten gekippt


## Hexenhut: breite Krempe, spitzer, leicht geknickter Kegel, violettes Band.
func _witch_hat(size: float) -> Node3D:
	var hat := Node3D.new()
	hat.scale = Vector3.ONE * size
	var felt := Mat.psx(Color(0.09, 0.07, 0.11))
	Geo.mesh(hat, Geo.cylinder(0.24, 0.015, 12), felt, Vector3(0, -0.03, 0))
	var cone := CylinderMesh.new()
	cone.top_radius = 0.0
	cone.bottom_radius = 0.11
	cone.height = 0.34
	cone.radial_segments = 10
	cone.rings = 2
	var tip := Geo.mesh(hat, cone, felt, Vector3(0, 0.14, 0))
	tip.rotation.x = 0.18
	Geo.mesh(hat, Geo.cylinder(0.113, 0.04, 10), Mat.psx(Color(0.4, 0.12, 0.5)), Vector3(0, 0.0, 0))
	return hat


## Kürbiskopf: über den ganzen Kopf gestülpt, Augen und Mund glühen wie bei einer Kürbislaterne.
func _pumpkin_head(size: float) -> Node3D:
	var head := Node3D.new()
	head.scale = Vector3.ONE * size
	Geo.mesh(head, Geo.sphere(0.19, 0.3, 10, 5), Mat.psx(Color(0.86, 0.42, 0.08)), Vector3(0, -0.1, 0))
	Geo.mesh(head, Geo.cylinder(0.025, 0.07, 6), Mat.psx(Color(0.3, 0.24, 0.1)), Vector3(0, 0.07, 0))
	var glow := Mat.psx(Color(1.0, 0.75, 0.3), "", 1.0, Color(1.0, 0.6, 0.15), 1.6)
	for side in [-1.0, 1.0]:
		var eye := Geo.mesh(head, Geo.box(Vector3(0.05, 0.05, 0.02)), glow, Vector3(side * 0.065, -0.06, -0.178))
		eye.rotation.z = PI / 4.0
	Geo.mesh(head, Geo.box(Vector3(0.14, 0.03, 0.02)), glow, Vector3(0, -0.15, -0.168))
	return head
