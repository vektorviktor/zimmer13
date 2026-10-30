class_name Grass
extends Node3D
## Grasbüschel auf den Rasenflächen des Gartens und der Innenhöfe, entschieden 2026-10-22. Je Büschel drei gekreuzte Halmkarten
## (shaders/grass.gdshader), eher verwildert und bis 30 cm hoch – so niedrig, dass nichts darin verschwindet.
## Verteilt in Kacheln (je ein MultiMesh), die nur bis VISIBLE m um die Kamera gezeichnet werden. Frei bleiben Wege,
## Terrassen, Kürbisbeete, Kübel, Baumwurzeln und die Gegenstände, Pflanzen und Laternen des Plans; Füße (Spieler,
## Gäste, Monster, Kürbismann) und Gegenstände am Boden drücken die Halme beiseite. Kein Schatten, keine Kollision,
## nicht im NavMesh (aus main.gd nach dem Backen), nicht gespeichert; immer gleich verteilt (fester Zufall).

const DENSITY := 9.0                     ## Büschel je m²
const HEIGHT := Vector2(0.14, 0.3)       ## Höhe eines Büschels (m)
const SPREAD := Vector2(0.8, 1.25)       ## Breite (Anteil von CARD_WIDTH)
const CARD_WIDTH := 0.4                  ## Breite einer Halmkarte (m)
const CHUNK := 8.0                       ## Kantenlänge einer Kachel (m)
const VISIBLE := 28.0                    ## so weit wird gezeichnet (Nebel und Nacht schlucken den Rest)
const VISIBLE_FADE := 4.0
const EDGE := 0.25                       ## Abstand zu Flächen, die kein Rasen sind (Wege, Terrassen, Wände)
const CLEAR_TREE := 0.6                  ## um Baumstämme (bis gut 0,5 m dick, ohne Wurzeln)
const CLEAR_ITEM := 0.6                  ## um Gegenstände und Ausstattung des Plans
const CLEAR_LIGHT := 0.45                ## um Laternen
const CLEAR_BED := 0.3                   ## um Beete und Kübel
const COLORS: Array[Color] = [Color(1, 1, 1), Color(0.85, 0.9, 0.8), Color(1.1, 1.0, 0.85), Color(0.75, 0.8, 0.7)]
## Wer die Halme beiseitedrückt: Radius für Füße und für Gegenstände, nur so weit um den Spieler, so viele
const PUSH_FOOT := 0.55
const PUSH_ITEM := 0.4
const PUSH_RANGE := 20.0
const MAX_PUSHERS := 24                  ## = MAX_PUSHERS im Shader
const ITEM_SCAN := 0.25                  ## Gegenstände am Boden so oft neu suchen (s)
const SEED := 1031
## Wind (Weather.wind, 7.8): Ausschlag der Halme bei Flaute … Sturm (m), Takt des Wiegens (× Spielzeit)
const WIND_BEND := Vector2(0.02, 0.14)
const WIND_PACE := Vector2(0.6, 1.8)
## Halmkarte: Kantenlänge in Pixeln, Anzahl Halme, Farben
const BLADE_TEX := 128
const BLADES := 18
const BLADE_COLORS: Array[Color] = [Color(0.2, 0.3, 0.11), Color(0.16, 0.24, 0.09), Color(0.26, 0.32, 0.13),
	Color(0.34, 0.3, 0.15), Color(0.4, 0.34, 0.18)]

var _mat: ShaderMaterial
var _time := 0.0
var _scan := 0.0
var _items: Array[Vector4] = []
var count := 0                           ## Büschel insgesamt (für --trace)


func setup(builder: LevelBuilder) -> void:
	_mat = ShaderMaterial.new()
	_mat.shader = load("res://shaders/grass.gdshader")
	_mat.set_shader_parameter("albedo_tex", _blade_texture())
	var mesh := _tuft_mesh()
	var rng := RandomNumberGenerator.new()
	rng.seed = SEED
	var holes := _holes(builder)
	var chunks := {}   # Vector2i → Array[Transform3D]
	for r in _lawn_rects(builder):
		for i in int(r.get_area() * DENSITY):
			var p := Vector2(rng.randf_range(r.position.x, r.end.x), rng.randf_range(r.position.y, r.end.y))
			var h := rng.randf_range(HEIGHT.x, HEIGHT.y)
			var w := rng.randf_range(SPREAD.x, SPREAD.y)
			var yaw := rng.randf() * TAU
			var color: Color = COLORS[rng.randi() % COLORS.size()]
			if not _free(builder, p, holes):
				continue
			var key := Vector2i(floori(p.x / CHUNK), floori(p.y / CHUNK))
			if not chunks.has(key):
				chunks[key] = []
			(chunks[key] as Array).append([Transform3D(Basis(Vector3.UP, yaw).scaled(Vector3(w, h, w)), Vector3(p.x, 0, p.y)), color])
	for key: Vector2i in chunks:
		var list: Array = chunks[key]
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.use_colors = true
		mm.mesh = mesh
		mm.instance_count = list.size()
		for i in list.size():
			mm.set_instance_transform(i, list[i][0])
			mm.set_instance_color(i, list[i][1])
		var mi := MultiMeshInstance3D.new()
		mi.multimesh = mm
		mi.material_override = _mat
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mi.visibility_range_end = VISIBLE
		mi.visibility_range_end_margin = VISIBLE_FADE
		mi.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
		add_child(mi)
		count += list.size()
	if Game.tracing:
		print("[Gras] %d Büschel in %d Kacheln" % [count, chunks.size()])


func _process(delta: float) -> void:
	if Game.player == null:
		return
	var wind := Game.weather.wind if Game.weather else 0.25
	_time += delta * lerpf(WIND_PACE.x, WIND_PACE.y, wind)
	_mat.set_shader_parameter("wind_time", _time)
	_mat.set_shader_parameter("wind_strength", lerpf(WIND_BEND.x, WIND_BEND.y, wind))
	_scan -= delta
	if _scan <= 0.0:
		_scan = ITEM_SCAN
		_scan_items()
	var center := Game.player.global_position
	var pushers: Array[Vector4] = [_pusher(center, PUSH_FOOT)]
	var walkers: Array = Game.social.living_guests() if Game.social else []
	for node: Node3D in [Game.monster, Game.pumpkin]:
		if node and node.is_inside_tree() and node.visible:
			walkers.append(node)
	for w: Node3D in walkers:
		if pushers.size() < MAX_PUSHERS and w.global_position.distance_to(center) < PUSH_RANGE:
			pushers.append(_pusher(w.global_position, PUSH_FOOT))
	for v in _items:
		if pushers.size() >= MAX_PUSHERS:
			break
		pushers.append(v)
	var count_now := pushers.size()
	while pushers.size() < MAX_PUSHERS:
		pushers.append(Vector4.ZERO)
	_mat.set_shader_parameter("pushers", pushers)
	_mat.set_shader_parameter("pusher_count", count_now)


static func _pusher(p: Vector3, radius: float) -> Vector4:
	return Vector4(p.x, p.y, p.z, radius)


## Gegenstände, die nahe dem Spieler unten im Rasen liegen (nicht gehalten, nicht in der Tasche).
func _scan_items() -> void:
	_items.clear()
	var center := Game.player.global_position
	for node in get_tree().get_nodes_in_group("items"):
		var item := node as Item
		if item == null or item.is_held or item.in_bag:
			continue
		var p := item.global_position
		if absf(p.y) < 0.6 and p.distance_to(center) < PUSH_RANGE:
			_items.append(_pusher(p, PUSH_ITEM))


## Rechtecke der Rasenflächen im EG (Fläche „Garten“ und der Boden unter den Bäumen).
static func _lawn_rects(builder: LevelBuilder) -> Array[Rect2]:
	var out: Array[Rect2] = []
	for r in builder._map["regions"]:
		if r["kind"] == "garden":
			for rc in r["rects"]:
				out.append(builder._rect(rc))
	for p in builder._map["floor_patches"]:
		if p["kind"] == "garden":
			for rc in p["rects"]:
				out.append(builder._rect(rc))
	return out


## Kreise (x, z, Radius) und Rechtecke, in denen nichts wächst.
static func _holes(builder: LevelBuilder) -> Dictionary:
	var circles: Array[Vector3] = []
	var rects: Array[Rect2] = []
	for t in builder._map["trees"]:
		circles.append(Vector3(t["center"][0], t["center"][1], CLEAR_TREE))
	for key in ["items", "fittings"]:
		for o in builder._map[key]:
			circles.append(Vector3(o["pos"][0], o["pos"][1], CLEAR_ITEM))
	for l in builder._map["lights"]:
		if l["kind"] == "lantern":
			circles.append(Vector3(l["pos"][0], l["pos"][1], CLEAR_LIGHT))
	for rc in builder._map["planters"]:
		rects.append(builder._rect(rc).grow(CLEAR_BED))
	for bed in builder.garden_beds:
		rects.append(bed.grow(CLEAR_BED))
	return {"circles": circles, "rects": rects}


static func _free(builder: LevelBuilder, p: Vector2, holes: Dictionary) -> bool:
	for d: Vector2 in [Vector2.ZERO, Vector2(EDGE, 0), Vector2(-EDGE, 0), Vector2(0, EDGE), Vector2(0, -EDGE)]:
		if not builder.is_lawn(p + d):
			return false
	for c: Vector3 in holes["circles"]:
		if p.distance_squared_to(Vector2(c.x, c.y)) < c.z * c.z:
			return false
	for r: Rect2 in holes["rects"]:
		if r.has_point(p):
			return false
	return true


## Ein Büschel: drei Karten (CARD_WIDTH × 1 m) um je 60° gedreht, Ursprung am Grund; UV.y = 0 an der Spitze.
static func _tuft_mesh() -> ArrayMesh:
	var verts := PackedVector3Array()
	var uvs := PackedVector2Array()
	var normals := PackedVector3Array()
	var indices := PackedInt32Array()
	for k in 3:
		var a := k * PI / 3.0
		var half := Vector3(cos(a), 0, sin(a)) * CARD_WIDTH / 2.0
		var base := verts.size()
		verts.append_array([-half, half, half + Vector3.UP, -half + Vector3.UP])
		uvs.append_array([Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0)])
		for i in 4:
			normals.append(Vector3.UP)
		indices.append_array([base, base + 1, base + 2, base, base + 2, base + 3])
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh


## Halmkarte BLADE_TEX² mit Alpha: Halme vom Grund nach oben spitz zulaufend, leicht gebogen, in Grün, Oliv und
## herbstlichem Stroh (passend zum Rasen aus TexGen), mit Mipmaps.
static func _blade_texture() -> ImageTexture:
	var n := BLADE_TEX
	var img := Image.create(n, n, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.18, 0.25, 0.1, 0.0))   # Farbe auch im Durchsichtigen, sonst säumen die Mipmaps dunkel
	var rng := RandomNumberGenerator.new()
	rng.seed = SEED
	for b in BLADES:
		var x0 := rng.randf_range(n * 0.12, n * 0.88)
		var height := rng.randf_range(0.45, 1.0) * (n - 1)
		var lean := rng.randf_range(-0.3, 0.3) * n
		var width := rng.randf_range(2.5, 5.0)
		var color: Color = BLADE_COLORS[rng.randi() % BLADE_COLORS.size()]
		for row in int(height):
			var t := row / height
			var cx := x0 + lean * t * t
			var hw := width / 2.0 * (1.0 - t) + 0.4
			for x in range(floori(cx - hw), ceili(cx + hw) + 1):
				if x < 0 or x >= n:
					continue
				var cover := clampf(hw + 0.5 - absf(x + 0.5 - cx), 0.0, 1.0)
				if cover <= 0.0:
					continue
				var y := n - 1 - row
				var c := color.lightened(0.15 * t)
				var old := img.get_pixel(x, y)
				c.a = maxf(old.a, cover)
				img.set_pixel(x, y, c)
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)
