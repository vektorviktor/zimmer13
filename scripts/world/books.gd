class_name Books
extends RefCounted
## Bücher in den Bücherregalen der Bibliothek (Spielkonzept 7.7, ZIM-153, Entscheidung 3.11.): nur Ausstattung, man kann nichts mit ihnen
## tun. Alte Leinen- und Lederbände in gedeckten Farben, die Fächer (Bookshelf.compartments) zu etwa FILL dicht gefüllt:
## Reihen mehrbändiger Werke (gleiche Form und Farbe), einzelne Bände, Lücken, schräg angelehnte Bücher und liegende
## Stapel. Die Formen kommen aus tools/build_books.py (VARIANTS Varianten, ein gemeinsamer Atlas mit Farbe, Normal Map
## und Masken, shaders/book.gdshader), die Farbe je Buch über INSTANCE_CUSTOM. Gezeichnet als MultiMesh je Variante
## und Kachel TILE (alle Regale einer Kachel zusammen – wenige Zeichenaufrufe auch für Schatten). Schatten werfen die
## Bücher erst ab der Grafikstufe SHADOW_LEVEL („Hoch“), darunter dunkelt der Shader sie nach hinten im Fach ab.
## Zufall fest je Regal (Lage im Plan), nichts wird gespeichert.

const MODEL := "res://assets/models/books.glb"
const LAYOUT := "res://assets/models/books.json"
const TEX := "res://assets/textures/books"
const SHADER := preload("res://shaders/book.gdshader")
## Kantenlänge der Kacheln (m), wie ShadowBudget.TILE
const TILE := 10.0
## Anteil der Fachbreite, den Bücher füllen (im Mittel; je Fach FILL_SPREAD mehr oder weniger)
const FILL := 0.85
const FILL_SPREAD := 0.07
## Rücken so weit hinter der Vorderkante des Fachbodens (m): je Reihe, dazu je Buch JITTER
const SETBACK := Vector2(0.004, 0.016)
const JITTER := 0.003
## Hin und wieder ein Buch weit hineingeschoben
const PUSHED := 0.04
const PUSHED_DEPTH := Vector2(0.02, 0.05)
## Mehrbändige Reihe: Wahrscheinlichkeit je Griff und Bände
const SET_CHANCE := 0.35
const SET_SIZE := Vector2i(3, 9)
## Lücke vor einem Griff; danach lehnt sich mit LEAN_CHANCE das nächste Buch schräg an
const GAP_CHANCE := 0.22
const GAP := Vector2(0.025, 0.12)
const LEAN_CHANCE := 0.55
const LEAN_DEG := Vector2(7.0, 24.0)
## Liegender Stapel am Rand eines Fachs (nur in breiten Fächern)
const STACK_CHANCE := 0.28
const STACK_MIN_SPAN := 0.55
const STACK_SIZE := Vector2i(2, 5)
## Streuung je Buch: Stärke und Höhe (Faktor), kleine Drehungen (Grad) für stehende und liegende Bücher
const THICK := Vector2(0.85, 1.2)
const TALL := Vector2(0.96, 1.04)
const WOBBLE_DEG := 0.6
const STACK_YAW_DEG := 4.0
## Abstand zur Fachdecke (m)
const HEAD_ROOM := 0.012
## Grafikstufe (Settings.GRAPHICS), ab der die Bücher Schatten werfen
const SHADOW_LEVEL := 2
## Farben (sRGB) je Bezug, je Buch × BRIGHT
const LEATHER := [Color(0.44, 0.14, 0.11), Color(0.33, 0.20, 0.12), Color(0.52, 0.34, 0.20), Color(0.48, 0.27, 0.14),
	Color(0.19, 0.13, 0.10), Color(0.17, 0.27, 0.19), Color(0.16, 0.19, 0.29), Color(0.36, 0.12, 0.15),
	Color(0.36, 0.33, 0.19)]
const CLOTH := [Color(0.31, 0.36, 0.27), Color(0.27, 0.32, 0.39), Color(0.30, 0.29, 0.27), Color(0.43, 0.16, 0.17),
	Color(0.50, 0.38, 0.22), Color(0.18, 0.22, 0.33), Color(0.48, 0.43, 0.34), Color(0.39, 0.28, 0.19),
	Color(0.16, 0.16, 0.16)]
const BRIGHT := Vector2(0.85, 1.15)

static var _meshes: Array[Mesh] = []
static var _variants: Array = []   # je Variante {name, kind, size: [Stärke, Höhe, Tiefe]}
static var _material: ShaderMaterial


## Alle Regale füllen: je Kachel und Variante ein MultiMeshInstance3D neben den Regalen (gleicher Elternknoten)
static func fill(shelves: Array) -> void:
	_load()
	var groups := {}   # [Elternknoten, Kachel] → je Variante [[Transform3D, Farbe], …]
	for node in shelves:
		var shelf := node as Bookshelf
		var parent := shelf.get_parent()
		var p := shelf.position
		var key := [parent, Vector3i(floori(p.x / TILE), floori(p.y / 3.0), floori(p.z / TILE))]
		if not groups.has(key):
			var lists := []
			for v in _variants.size():
				lists.append([])
			groups[key] = lists
		var rng := RandomNumberGenerator.new()
		rng.seed = hash(Vector3i(roundi(p.x * 10.0), roundi(p.y * 10.0), roundi(p.z * 10.0)))
		var zs := Bookshelf.DEPTH / 2.0 - Bookshelf.SHELF_SET
		var deep := Bookshelf.DEPTH - Bookshelf.SHELF_SET - Bookshelf.BACK_WALL
		for c: Array in shelf.compartments():
			for b: Array in _compartment(rng, c[0], c[0] + c[1], c[2], c[3], zs, deep):
				groups[key][b[0]].append([shelf.transform * b[1], b[2]])
	for key: Array in groups:
		var parent: Node = key[0]
		var lists: Array = groups[key]
		for v in lists.size():
			var list: Array = lists[v]
			if list.is_empty():
				continue
			var mm := MultiMesh.new()
			mm.transform_format = MultiMesh.TRANSFORM_3D
			mm.use_custom_data = true
			mm.mesh = _meshes[v]
			mm.instance_count = list.size()
			for i in list.size():
				mm.set_instance_transform(i, list[i][0])
				mm.set_instance_custom_data(i, list[i][1])
			var mmi := MultiMeshInstance3D.new()
			mmi.name = "Books_%s" % _variants[v]["name"]
			mmi.multimesh = mm
			mmi.material_override = _material
			mmi.add_to_group("books")
			_shadow(mmi)
			parent.add_child(mmi)


## Grafikstufe gewechselt (main._apply_settings): Schatten der Bücher an oder aus
static func apply_graphics(tree: SceneTree) -> void:
	for node in tree.get_nodes_in_group("books"):
		_shadow(node as GeometryInstance3D)


static func _shadow(g: GeometryInstance3D) -> void:
	var on := Settings.graphics >= SHADOW_LEVEL
	g.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if on else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


## Bücher im Fach von x0 bis x1 (Boden y, lichte Höhe clear), Fachboden vorn bei zs, nutzbar deep tief:
## [[Variante, Transform3D lokal im Regal, Farbe (linear)], …]
static func _compartment(rng: RandomNumberGenerator, x0: float, x1: float, y: float, clear: float, zs: float,
		deep: float) -> Array:
	var out := []
	var fits: Array[int] = []
	for v in _variants.size():
		var size: Array = _variants[v]["size"]
		if size[1] * TALL.y <= clear - HEAD_ROOM and size[2] <= deep - SETBACK.y - JITTER:
			fits.append(v)
	if fits.is_empty():
		return out
	var span := x1 - x0
	var gap_budget := span * (1.0 - FILL + rng.randf_range(-FILL_SPREAD, FILL_SPREAD))
	# liegender Stapel links oder rechts
	if span >= STACK_MIN_SPAN and rng.randf() < STACK_CHANCE:
		var right := rng.randf() < 0.5
		var w := _stack(rng, out, fits, x0, x1, right, y, clear, zs)
		if right:
			x1 -= w
		else:
			x0 += w
		gap_budget -= 0.02
	var x := x0 + rng.randf_range(0.0, 0.006)
	var prev_h := clear   # Höhe des linken Nachbarn (am Anfang die Fachseite)
	var lean_next := false
	while true:
		if x > x0 + 0.05 and gap_budget > 0.02 and rng.randf() < GAP_CHANCE:
			var gap := minf(gap_budget, rng.randf_range(GAP.x, GAP.y))
			gap_budget -= gap
			lean_next = rng.randf() < LEAN_CHANCE
			if not lean_next:
				x += gap
				prev_h = clear
		var v: int = fits[rng.randi_range(0, fits.size() - 1)]
		var count := rng.randi_range(SET_SIZE.x, SET_SIZE.y) if rng.randf() < SET_CHANCE else 1
		var tint := _tint(rng, _variants[v]["kind"])
		var scale := Vector3(rng.randf_range(THICK.x, THICK.y), rng.randf_range(TALL.x, TALL.y), 1.0)
		var back := rng.randf_range(SETBACK.x, SETBACK.y)
		var size: Array = _variants[v]["size"]
		var t: float = size[0] * scale.x
		var h: float = size[1] * scale.y
		var placed := 0
		for i in count:
			var z := zs - back - rng.randf_range(0.0, JITTER)
			if rng.randf() < PUSHED:
				z -= rng.randf_range(PUSHED_DEPTH.x, PUSHED_DEPTH.y)
			z = maxf(z, zs - deep + size[2])
			if lean_next:
				lean_next = false
				var deg := rng.randf_range(LEAN_DEG.x, LEAN_DEG.y)
				var lean := _lean(x, deg_to_rad(deg), t, h, prev_h, y, z, scale)
				if lean[1] <= x1:
					out.append([v, lean[0], tint])
					x = lean[1] + rng.randf_range(0.0, 0.004)
					prev_h = h * cos(deg_to_rad(deg))
					placed += 1
					continue
			if x + t > x1:
				break
			var basis := Basis(Vector3.UP, deg_to_rad(rng.randf_range(-1.0, 1.0) * 2.0 * WOBBLE_DEG)) * \
				Basis(Vector3.BACK, deg_to_rad(rng.randf_range(-WOBBLE_DEG, WOBBLE_DEG))) * Basis.from_scale(scale)
			out.append([v, Transform3D(basis, Vector3(x + t / 2.0, y, z)), tint])
			x += t + rng.randf_range(0.0, 0.0015)
			prev_h = h
			placed += 1
		if placed < count or x + 0.015 > x1:
			# Rest am Ende: ein schmales Buch lehnt schräg an der Fachseite, sonst bleibt die Lücke
			var rest := x1 - x
			if rest > 0.06 and rng.randf() < 0.5:
				var lv: int = fits[rng.randi_range(0, fits.size() - 1)]
				var ls: Array = _variants[lv]["size"]
				var deg := rng.randf_range(LEAN_DEG.x, LEAN_DEG.y)
				var lean := _lean(x1, -deg_to_rad(deg), ls[0], ls[1], clear, y, zs - SETBACK.y, Vector3.ONE)
				if lean[1] >= x:
					out.append([lv, lean[0], _tint(rng, _variants[lv]["kind"])])
			break
	return out


## Schräg angelehntes Buch: angle > 0 kippt den Kopf nach −x an einen Nachbarn mit Kante bei xe (Höhe hn), < 0 nach +x.
## Die untere Kante auf der anderen Seite steht auf dem Boden. Rückgabe [Transform3D, Ende auf der freien Seite].
static func _lean(xe: float, angle: float, t: float, h: float, hn: float, y: float, z: float, scale: Vector3) -> Array:
	var a := absf(angle)
	var side := signf(angle)   # +1: Nachbar links
	var c := minf(h, hn / cos(a))   # Berührpunkt entlang der Buchkante
	var px := xe + side * c * sin(a)   # untere Kante auf der Seite des Nachbarn
	var basis := Basis(Vector3.BACK, angle) * Basis.from_scale(scale)
	var origin := Vector3(px, y, z) + Basis(Vector3.BACK, angle) * Vector3(side * t / 2.0, 0, 0)
	return [Transform3D(basis, origin), px + side * t * cos(a)]


## Liegender Stapel (größtes Buch unten) am linken oder rechten Rand; Rückgabe: belegte Breite
static func _stack(rng: RandomNumberGenerator, out: Array, fits: Array[int], x0: float, x1: float, right: bool,
		y: float, clear: float, zs: float) -> float:
	var books := []
	var top := 0.0
	for i in rng.randi_range(STACK_SIZE.x, STACK_SIZE.y):
		var v: int = fits[rng.randi_range(0, fits.size() - 1)]
		var size: Array = _variants[v]["size"]
		var scale := Vector3(rng.randf_range(THICK.x, THICK.y), 1.0, 1.0)
		if top + size[0] * scale.x > clear - HEAD_ROOM - 0.02:
			break
		top += size[0] * scale.x
		books.append([v, scale])
	books.sort_custom(func(a: Array, b: Array) -> bool: return _variants[a[0]]["size"][1] > _variants[b[0]]["size"][1])
	var width := 0.0
	var base := y
	var lying := Basis(Vector3.BACK, -PI / 2.0)   # Höhe entlang +x, Deckel links oben
	for b: Array in books:
		var size: Array = _variants[b[0]]["size"]
		var t: float = size[0] * b[1].x
		var h: float = size[1]
		width = maxf(width, h)
		var basis := Basis(Vector3.UP, deg_to_rad(rng.randf_range(-STACK_YAW_DEG, STACK_YAW_DEG))) * lying * Basis.from_scale(b[1])
		var cx := (x1 - 0.006 - h / 2.0 if right else x0 + 0.006 + h / 2.0) + rng.randf_range(-0.006, 0.006)
		var centre := Vector3(cx, base + t / 2.0, zs - rng.randf_range(SETBACK.x, SETBACK.y) - size[2] / 2.0)
		var origin := centre - basis * Vector3(0, size[1] / 2.0, -size[2] / 2.0)
		out.append([b[0], Transform3D(basis, origin), _tint(rng, _variants[b[0]]["kind"])])
		base += t
	return width + 0.02 if not books.is_empty() else 0.0


static func _tint(rng: RandomNumberGenerator, kind: String) -> Color:
	var list: Array = CLOTH if kind == "leinen" else LEATHER
	var c: Color = list[rng.randi_range(0, list.size() - 1)]
	c = (c * rng.randf_range(BRIGHT.x, BRIGHT.y)).clamp()
	return Color(c.srgb_to_linear(), 1.0)


static func _load() -> void:
	if not _meshes.is_empty():
		return
	_variants = JSON.parse_string(FileAccess.get_file_as_string(LAYOUT))["variants"]
	var scene: Node = (load(MODEL) as PackedScene).instantiate()
	var by_name := {}
	for mi: MeshInstance3D in scene.find_children("*", "MeshInstance3D", true, false):
		by_name[String(mi.name)] = mi.mesh
	scene.free()
	for v in _variants.size():
		_meshes.append(by_name["book_%d" % v])
	_material = ShaderMaterial.new()
	_material.shader = SHADER
	_material.set_shader_parameter("albedo_tex", Mat._mipmapped(TEX + "_albedo.png", false))
	_material.set_shader_parameter("normal_tex", Mat._mipmapped(TEX + "_normal.png", true))
	_material.set_shader_parameter("mask_tex", Mat._mipmapped(TEX + "_mask.png", false))
