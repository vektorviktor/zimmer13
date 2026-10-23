class_name HotelMap
extends Control
## Karte aus losen Blättern (Item.Kind.MAP, ein Blatt je Ebene, Spielkonzept 3.2): gedruckte
## Lagepläne der Geschosse, Norden (Welt −Z) oben, gezeichnet aus dem Gebäudeplan
## (assets/maps/eg.json und og1.json, Spielkonzept 7.5) – ändert sich das Hotel, stimmen auch die Blätter. Dazu
## handgezeichnete Skizzen früherer Gäste (das Untergeschoss aus ug.json). Neue Ebene = Eintrag in PAGES + Zeichnung in _draw().
##
## Alle Blätter liegen untereinander in einer Textur (PAGE_SIZE je Blatt), einmal in einem
## SubViewport gerendert; material() liefert je Blatt ein Material mit passendem UV-Ausschnitt.

## id, Titel, Ebene (Spielerhöhe von … bis, für „passendes Blatt oben“)
const PAGES := [
	{"id": "eg", "title": "Erdgeschoss", "y_min": -1.0, "y_max": 2.5},
	{"id": "og", "title": "1. Obergeschoss", "y_min": 2.5, "y_max": 99.0},
	{"id": "keller", "title": "Keller", "y_min": -99.0, "y_max": -1.0},
]
const PX := 9.0                      ## Pixel pro Meter (gedruckte Pläne)
const X_MIN := -78.0
const X_MAX := 78.0
const Z_MIN := -122.0
const Z_MAX := 4.0
const PAGE_SIZE := Vector2i(int((X_MAX - X_MIN) * PX), int((Z_MAX - Z_MIN) * PX))
const ORIGIN := Vector2(X_MIN, Z_MIN)   ## Weltpunkt (x, z) oben links in jedem Blatt
const LINE := 2.0

const PAPER := Color(0.86, 0.8, 0.66)
const NOTE_PAPER := Color(0.82, 0.8, 0.74)
const INK := Color(0.22, 0.17, 0.13)
const FADED := Color(0.45, 0.38, 0.3)
const PENCIL := Color(0.3, 0.3, 0.34)
const CORRIDOR := Color(0.74, 0.66, 0.5)
const ROOM := Color(0.92, 0.87, 0.75)
const GARDEN := Color(0.62, 0.68, 0.5)
const PEN := Color(0.62, 0.1, 0.08)   ## jemand hat Zimmer 13 eingekreist

static var _texture: Texture2D
static var _materials := {}
static var _rendering := false

var _rng := RandomNumberGenerator.new()


static func page_index(id: String) -> int:
	for i in PAGES.size():
		if PAGES[i]["id"] == id:
			return i
	return 0


static func page_title(id: String) -> String:
	return String(PAGES[page_index(id)]["title"])


## Das Blatt, das zur Höhe des Spielers passt
static func page_at(y: float) -> String:
	for page in PAGES:
		if y >= float(page["y_min"]) and y < float(page["y_max"]):
			return page["id"]
	return "eg"


## Material eines Blatts (geteilt). Die Textur wird beim ersten Aufruf gerendert und
## nachgereicht – bis dahin ist das Blatt leer.
static func material(id: String) -> StandardMaterial3D:
	if _materials.has(id):
		return _materials[id]
	var m := paper_material(PAPER)
	m.uv1_scale = Vector3(1.0, 1.0 / PAGES.size(), 1.0)
	m.uv1_offset = Vector3(0.0, float(page_index(id)) / PAGES.size(), 0.0)
	_materials[id] = m
	if _texture:
		_apply(m)
	elif not _rendering:
		_render()
	return m


## Papier, leicht selbstleuchtend: im Dunkeln noch schwach zu erkennen
static func paper_material(color: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	m.roughness = 1.0
	m.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	m.emission_enabled = true
	m.emission = color
	m.emission_energy_multiplier = 0.12
	return m


static func _apply(m: StandardMaterial3D) -> void:
	m.albedo_color = Color.WHITE
	m.emission = Color.WHITE
	m.albedo_texture = _texture
	m.emission_texture = _texture


static func _render() -> void:
	_rendering = true
	var vp := SubViewport.new()
	vp.size = _texture_size()
	vp.disable_3d = true
	vp.transparent_bg = false
	vp.render_target_update_mode = SubViewport.UPDATE_ONCE
	vp.add_child(HotelMap.new())
	(Engine.get_main_loop() as SceneTree).root.add_child.call_deferred(vp)
	_finish.call_deferred(vp)


static func _finish(vp: SubViewport) -> void:
	await RenderingServer.frame_post_draw
	var img := vp.get_texture().get_image()
	vp.queue_free()
	if img == null:   # ohne Grafik (--headless)
		return
	img.generate_mipmaps()
	_texture = ImageTexture.create_from_image(img)
	for id in _materials:
		_apply(_materials[id])


func _ready() -> void:
	size = Vector2(_texture_size())


static func _texture_size() -> Vector2i:
	return Vector2i(PAGE_SIZE.x, PAGE_SIZE.y * PAGES.size())


func _draw() -> void:
	var font := ThemeDB.fallback_font
	var plan: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(LevelBuilder.MAP_PATH))
	var upper: Dictionary = {}
	if FileAccess.file_exists(LevelBuilder.UPPER_MAP_PATHS[0]):
		upper = JSON.parse_string(FileAccess.get_file_as_string(LevelBuilder.UPPER_MAP_PATHS[0]))
	var lower: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(LevelBuilder.LOWER_MAP_PATH))
	for i in PAGES.size():
		var top := float(i * PAGE_SIZE.y)
		var id: String = PAGES[i]["id"]
		if id == "keller":
			_draw_cellar_sketch(lower, top, font)
			continue
		draw_rect(Rect2(Vector2(0, top), Vector2(PAGE_SIZE)), PAPER)
		draw_rect(Rect2(Vector2(4, top + 4), Vector2(PAGE_SIZE) - Vector2(8, 8)), INK, false, LINE)
		# Kopf oben links, Geschoss und Nordpfeil oben rechts
		draw_string(font, Vector2(16, top + 34), "HOTEL – Lageplan", HORIZONTAL_ALIGNMENT_LEFT, -1, 26, INK)
		draw_string(font, Vector2(16, top + 60), "für unsere Gäste", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, FADED)
		draw_string(font, Vector2(PAGE_SIZE.x - 300, top + 40), page_title(id), HORIZONTAL_ALIGNMENT_RIGHT, 220, 26, INK)
		_north_arrow(Vector2(PAGE_SIZE.x - 40, top + 14), INK, font)
		if id == "eg":
			_draw_floor(plan, top, font)
		elif upper.is_empty():
			_draw_upper_floor(plan, top, font)
		else:
			_draw_floor(upper, top, font)


func _north_arrow(n: Vector2, color: Color, font: Font) -> void:
	draw_colored_polygon(PackedVector2Array([n, n + Vector2(-11, 32), n + Vector2(11, 32)]), color)
	draw_string(font, n + Vector2(-8, 56), "N", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, color)


## Ein Geschoss aus dem Gebäudeplan: Flächen, Wände mit Türen, Zimmernummern, Lufträume gestrichelt. Den
## Keller verschweigt der Hotelplan – die Treppenhäuser sind nur Treppen.
func _draw_floor(plan: Dictionary, top: float, font: Font) -> void:
	for r in plan["regions"]:
		var fill := ROOM.darkened(0.08)
		match String(r["kind"]):
			"room":
				fill = ROOM
			"corridor":
				fill = CORRIDOR
			"garden":
				fill = GARDEN
			"terrace", "balcony", "gravel":
				fill = GARDEN.lightened(0.15)
		for rc in r["rects"]:
			draw_rect(_rect(_world_rect(rc), top), fill)
	for rc in plan["voids"]:
		_dashed_rect(_rect(_world_rect(rc), top))
	for rs in plan["terrace_edges"] + plan.get("balcony_edges", []):
		for rc in rs:
			draw_rect(_rect(_world_rect(rc), top), GARDEN.darkened(0.2))
	for p in plan["floor_patches"]:
		for rc in p["rects"]:
			draw_rect(_rect(_world_rect(rc), top), CORRIDOR if p["kind"] == "corridor" else GARDEN)
	for w in plan["walls"]:
		var a := _point(w["a"], top)
		var b := _point(w["b"], top)
		draw_line(a, b, INK, LINE)
		var length := a.distance_to(b)
		for o in w.get("openings", []):
			var f0 := float(o["at"]) * PX / length
			var f1 := (float(o["at"]) + float(o["width"])) * PX / length
			draw_line(a.lerp(b, f0), a.lerp(b, f1), CORRIDOR if o["kind"] == "window" else PAPER, LINE + 1.0)
	for s in plan["stairs"]:
		var well := _rect(_world_rect(s["rect"]), top)
		draw_rect(well, CORRIDOR)
		draw_rect(well, INK, false, LINE)
		for k in 6:   # Stufen
			var sy := well.position.y + well.size.y * (k + 1) / 8.0
			draw_line(Vector2(well.position.x, sy), Vector2(well.end.x, sy), FADED, LINE)
	for r in plan["regions"]:
		var kind := String(r["kind"])
		if (r.has("name") and not kind in ["elevator", "corridor", "pool_water"]) or kind in ["cat_room", "library"]:
			var box := _rect(_world_rect(_outer(r["rects"])), top)
			var label := String(r.get("name", LevelBuilder.KIND_NAMES.get(kind, "")))
			for font_size in [16, 11]:   # Name nur, wenn er in den Raum passt
				if font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x < box.size.x - 6.0:
					_text(box, label, INK, font, font_size)
					break
	for rm in plan["rooms"]:
		var r := _rect(_world_rect(_outer(rm["rects"])), top)
		var no := String(rm["no"])
		_text(r, no, INK, font, 12)
		if no == LevelBuilder.PLAYER_ROOM:
			draw_arc(r.get_center(), minf(r.size.x, r.size.y) * 0.45, 0.3, TAU + 0.1, 24, PEN, 3.0)
	for a in plan["areas"]:
		_text(_rect(_world_rect(a["rect"]), top), String(a["name"]), INK, font, 18)


## Obergeschoss ohne eigenen Plan: nur die Galerie über der Lobby.
func _draw_upper_floor(plan: Dictionary, top: float, font: Font) -> void:
	for a in plan["areas"]:
		if a["id"] == "lobby":
			var hall := _box(_world_rect(a["rect"]), CORRIDOR, top)
			for rc in plan["open_above"]:
				_dashed_rect(_rect(_world_rect(rc), top))
			_text(Rect2(hall.position + Vector2(0, -30), Vector2(hall.size.x, 24)), "Galerie", INK, font, 18)
	draw_string(font, Vector2(16, top + PAGE_SIZE.y - 30), "Wegen Renovierung geschlossen.", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, FADED)


func _world_rect(rc: Array) -> Rect2:
	return Rect2(float(rc[0]), float(rc[1]), float(rc[2]) - float(rc[0]), float(rc[3]) - float(rc[1]))


func _outer(rects: Array) -> Array:
	var out: Array = (rects[0] as Array).duplicate()
	for rc in rects:
		out = [minf(out[0], rc[0]), minf(out[1], rc[1]), maxf(out[2], rc[2]), maxf(out[3], rc[3])]
	return out


func _point(p: Array, top: float) -> Vector2:
	return Vector2((float(p[0]) - ORIGIN.x) * PX, top + (float(p[1]) - ORIGIN.y) * PX)


## Skizze eines früheren Gastes auf einem Notizzettel: das Untergeschoss (Spielkonzept 7.9) aus dem Gebäudeplan im
## Maßstab der gedruckten Pläne, Linien von Hand gezittert. Offene Türen sind Lücken, die verschlossenen hat er
## zugezeichnet; der Heizkeller ist rot eingekreist.
func _draw_cellar_sketch(plan: Dictionary, top: float, font: Font) -> void:
	_rng.seed = 1994
	draw_rect(Rect2(Vector2(0, top), Vector2(PAGE_SIZE)), NOTE_PAPER)
	for k in int((PAGE_SIZE.y - 40) / 48.0) + 1:   # Linien des Notizblocks
		var ly := top + 40.0 + k * 48.0
		draw_line(Vector2(0, ly), Vector2(PAGE_SIZE.x, ly), Color(0.62, 0.7, 0.8, 0.5), 1.0)
	draw_string(font, Vector2(20, top + 34), "Keller", HORIZONTAL_ALIGNMENT_LEFT, -1, 30, PENCIL)
	draw_string(font, Vector2(130, top + 34), "(abgezeichnet, Okt. 1994)", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, PENCIL)
	_north_arrow(Vector2(PAGE_SIZE.x - 40, top + 14), PENCIL, font)
	for w in plan["walls"]:
		var a := _point(w["a"], top)
		var b := _point(w["b"], top)
		var length := a.distance_to(b)
		var openings: Array = w.get("openings", []).filter(func(o: Dictionary) -> bool:
			return not o["kind"] in ["main_entrance", "elevator_door"])
		openings.sort_custom(func(o1: Dictionary, o2: Dictionary) -> bool: return float(o1["at"]) < float(o2["at"]))
		var f := 0.0
		for o in openings:
			var f0 := float(o["at"]) * PX / length
			if f0 > f:
				_wobbly_line(a.lerp(b, f), a.lerp(b, f0), PENCIL)
			f = (float(o["at"]) + float(o["width"])) * PX / length
		if f < 1.0:
			_wobbly_line(a.lerp(b, f), b, PENCIL)
	for s in plan["stairs"]:
		var stair := _rect(_world_rect(s["steps"] if s.has("steps") else s["rect"]), top)
		for k in 7:   # Stufen
			var sy := stair.position.y + stair.size.y * (k + 1) / 8.0
			_wobbly_line(Vector2(stair.position.x, sy), Vector2(stair.end.x, sy), PENCIL)
		if s["id"] == "treppenhaus_ost":
			var well := _rect(_world_rect(s["rect"]), top)
			_text(Rect2(well.position + Vector2(-190, 10), Vector2(180, 24)), "Treppenhaus Ost", PENCIL, font, 18)
			_text(Rect2(well.position + Vector2(-190, 36), Vector2(180, 24)), "ganz runter", PENCIL, font, 16)
	for r in plan["regions"]:
		var kind := String(r["kind"])
		var box := _rect(_world_rect(_outer(r["rects"])), top)
		match kind:
			"plant_room":
				_text(box, "Technik", PENCIL, font, 18)
			"laundry_room":
				_text(box, "Wäsche", PENCIL, font, 18)
	var hall := Rect2()
	for r in plan["regions"]:
		if r["kind"] == "boiler_room":
			for rc in r["rects"]:
				var piece := _world_rect(rc)
				if piece.get_area() > hall.get_area():
					hall = piece
	if hall.has_area():
		var box := _rect(hall, top)
		_text(Rect2(box.position + Vector2(0, box.size.y * 0.3), Vector2(box.size.x, 30)), "Heizkeller", PENCIL, font, 22)
		_text(Rect2(box.position + Vector2(0, box.size.y * 0.55), Vector2(box.size.x, 30)), "hier unten schläft es", PEN, font, 22)
		draw_set_transform(box.get_center(), -0.05, Vector2(1.0, box.size.y / box.size.x))   # eingekreist (Ellipse)
		draw_arc(Vector2.ZERO, box.size.x * 0.56, 0.2, TAU + 0.15, 40, PEN, 3.0)
		draw_set_transform(Vector2.ZERO)
		var crate := _rect(Rect2(hall.end.x - 1.15, hall.end.y - 1.15, 0.7, 0.7), top)   # die Kiste mit dem Schlüssel
		_text(Rect2(crate.position + Vector2(-50, -24), Vector2(40, 20)), "18?", PENCIL, font, 18)


## Rechteck in Weltkoordinaten (x, z) → Bildpunkte im aktuellen Blatt
func _rect(world: Rect2, top: float) -> Rect2:
	return Rect2((world.position.x - ORIGIN.x) * PX, top + (world.position.y - ORIGIN.y) * PX,
		world.size.x * PX, world.size.y * PX)


## Freihand-Linie: leicht zitternd, Enden etwas überstehend
func _wobbly_line(a: Vector2, b: Vector2, color: Color) -> void:
	var dir := (b - a).normalized()
	a -= dir * _rng.randf_range(0.0, 6.0)
	b += dir * _rng.randf_range(0.0, 6.0)
	var normal := Vector2(-dir.y, dir.x)
	var points := PackedVector2Array()
	var steps := maxi(2, int(a.distance_to(b) / 25.0))
	for k in steps + 1:
		points.append(a.lerp(b, float(k) / steps) + normal * _rng.randf_range(-1.5, 1.5))
	draw_polyline(points, color, LINE)


func _box(world: Rect2, fill: Color, top: float) -> Rect2:
	var r := _rect(world, top)
	draw_rect(r, fill)
	draw_rect(r, INK, false, LINE)
	return r


func _dashed_rect(r: Rect2) -> void:
	var corners := [r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)]
	for k in 4:
		draw_dashed_line(corners[k], corners[(k + 1) % 4], FADED, LINE, 8.0)


func _text(r: Rect2, text: String, color: Color, font: Font, font_size: int) -> void:
	var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	draw_string(font, r.get_center() + Vector2(-w / 2.0, font_size * 0.35), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)
