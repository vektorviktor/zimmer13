class_name HotelMap
extends Control
## Karte aus losen Blättern (Item.Kind.MAP, ein Blatt je Ebene, Spielkonzept 3.2): gedruckte
## Lagepläne der Geschosse, Norden (Welt −Z) oben, gezeichnet aus den Bauplänen des
## LevelBuilder (FLOORS, ROWS) – ändert sich das Hotel, stimmen auch die Blätter. Dazu
## handgezeichnete Skizzen früherer Gäste. Neue Ebene = Eintrag in PAGES + Zeichnung in _draw().
##
## Alle Blätter liegen untereinander in einer Textur (PAGE_SIZE je Blatt), einmal in einem
## SubViewport gerendert; material() liefert je Blatt ein Material mit passendem UV-Ausschnitt.

## id, Titel, Ebene (Spielerhöhe von … bis, für „passendes Blatt oben“), Geschoss in
## LevelBuilder.FLOORS (gedruckter Plan) oder -1 (eigene Zeichnung in _draw())
const PAGES := [
	{"id": "eg", "title": "Erdgeschoss", "y_min": -1.0, "y_max": 2.5, "floor": 0},
	{"id": "og", "title": "1. Obergeschoss", "y_min": 2.5, "y_max": 99.0, "floor": 1},
	{"id": "keller", "title": "Keller", "y_min": -99.0, "y_max": -1.0, "floor": -1},
]
const PX := 9.0                      ## Pixel pro Meter (gedruckte Pläne)
const X_MIN := -15.5
const X_MAX := 96.0
const Z_MIN := -30.0
const Z_MAX := 20.0
const PAGE_SIZE := Vector2i(int((X_MAX - X_MIN) * PX), int((Z_MAX - Z_MIN) * PX))
## Kellerskizze: Ausschnitt ab x 64, größerer Maßstab
const SKETCH_X := 64.0
const SKETCH_PX := PAGE_SIZE.x / 34.0
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

var _origin := Vector2(X_MIN, Z_MIN)   ## Weltpunkt (x, z) oben links im Blatt
var _scale := PX
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
	for i in PAGES.size():
		var top := float(i * PAGE_SIZE.y)
		var id: String = PAGES[i]["id"]
		if id == "keller":
			_draw_cellar_sketch(top, font)
			continue
		_origin = Vector2(X_MIN, Z_MIN)
		_scale = PX
		draw_rect(Rect2(Vector2(0, top), Vector2(PAGE_SIZE)), PAPER)
		draw_rect(Rect2(Vector2(4, top + 4), Vector2(PAGE_SIZE) - Vector2(8, 8)), INK, false, LINE)
		# Kopf in der leeren Ecke oben links, Geschoss und Nordpfeil oben rechts
		draw_string(font, Vector2(16, top + 34), "HOTEL – Lageplan", HORIZONTAL_ALIGNMENT_LEFT, -1, 26, INK)
		draw_string(font, Vector2(16, top + 60), "für unsere Gäste", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, FADED)
		draw_string(font, Vector2(PAGE_SIZE.x - 300, top + 40), page_title(id), HORIZONTAL_ALIGNMENT_RIGHT, 220, 26, INK)
		_north_arrow(Vector2(PAGE_SIZE.x - 40, top + 14), INK, font)
		_draw_floor(LevelBuilder.FLOORS[int(PAGES[i]["floor"])], top, font)


func _north_arrow(n: Vector2, color: Color, font: Font) -> void:
	draw_colored_polygon(PackedVector2Array([n, n + Vector2(-11, 32), n + Vector2(11, 32)]), color)
	draw_string(font, n + Vector2(-8, 56), "N", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, color)


func _draw_floor(spec: Dictionary, top: float, font: Font) -> void:
	var y: float = spec["y"]
	var ground := y == 0.0
	if ground:
		_area(Rect2(-14.1, -19.1, 14.2, 12.0), GARDEN, "Garten", top, font)
		_area(Rect2(-14.0, -7.0, 14.0, 14.0), CORRIDOR, "Lobby", top, font)
		_area(Rect2(-14.0, 7.0, 8.0, 6.0), ROOM, "Küche", top, font)
		_area(Rect2(-6.0, 7.0, 6.0, 6.0), ROOM, "Bar", top, font)
		# Den Keller verschweigt der Hotelplan – nur die Tür am Flurende
		var door := _rect(Rect2(LevelBuilder.MAIN_END, -1.0, 1.2, 2.0), top)
		_dashed_rect(door)
		_text(Rect2(door.position + Vector2(door.size.x + 8, -14), Vector2(110, 20)), "Personal", FADED, font, 16)
		_text(Rect2(door.position + Vector2(door.size.x + 8, 8), Vector2(110, 20)), "kein Zutritt", FADED, font, 16)
	# Flure
	var main_end: float = spec["main_end"]
	_box(Rect2(0.0, -1.6, main_end, 3.2), CORRIDOR, top)
	for wing in spec["wings"]:
		var wx: float = wing["x"]
		var wend: float = wing["end"]
		_box(Rect2(wx - 1.6, -wend, 3.2, 2.0 * wend), CORRIDOR, top)
	var well := _box(Rect2(LevelBuilder.STAIRWELL_X - 1.6, LevelBuilder.STAIRWELL_END, 3.2,
		LevelBuilder.STAIRWELL_Z - LevelBuilder.STAIRWELL_END), CORRIDOR, top)
	for k in 6:   # Stufen
		var sy := well.position.y + well.size.y * (k + 1) / 8.0
		draw_line(Vector2(well.position.x, sy), Vector2(well.end.x, sy), FADED, LINE)
	_text(well, "Treppe", INK, font, 18, -90.0)
	# Zimmer
	for row in LevelBuilder.ROWS:
		var origin: Vector3 = row["origin"]
		if not is_equal_approx(origin.y, y):
			continue
		var basis := Basis(Vector3.UP, deg_to_rad(float(row["yaw"])))
		var x := 0.0
		for entry in row["rooms"]:
			var width: float = entry[1]
			var a := origin + basis * Vector3(x, 0, 0)
			var b := origin + basis * Vector3(x + width, 0, LevelBuilder.ROOM_DEPTH)
			var world := Rect2(Vector2(minf(a.x, b.x), minf(a.z, b.z)), (Vector2(a.x, a.z) - Vector2(b.x, b.z)).abs())
			var r := _box(world, ROOM, top)
			var no := String(entry[0])
			_text(r, no, INK, font, 18)
			if no == "13":
				draw_arc(r.get_center(), minf(r.size.x, r.size.y) * 0.45, 0.3, TAU + 0.1, 24, PEN, 3.0)
			x += width


## Skizze eines früheren Gastes auf einem Notizzettel: Flurende, Kellertür, Treppe, Keller
## (Maße aus dem LevelBuilder, Linien von Hand gezittert).
func _draw_cellar_sketch(top: float, font: Font) -> void:
	_origin = Vector2(SKETCH_X, -PAGE_SIZE.y / SKETCH_PX / 2.0)
	_scale = SKETCH_PX
	_rng.seed = 1994
	draw_rect(Rect2(Vector2(0, top), Vector2(PAGE_SIZE)), NOTE_PAPER)
	for k in 9:   # Linien des Notizblocks
		var ly := top + 40.0 + k * 48.0
		draw_line(Vector2(0, ly), Vector2(PAGE_SIZE.x, ly), Color(0.62, 0.7, 0.8, 0.5), 1.0)
	draw_string(font, Vector2(20, top + 34), "Keller", HORIZONTAL_ALIGNMENT_LEFT, -1, 30, PENCIL)
	draw_string(font, Vector2(130, top + 34), "(abgezeichnet, Okt. 1994)", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, PENCIL)
	_north_arrow(Vector2(PAGE_SIZE.x - 40, top + 14), PENCIL, font)
	var L := LevelBuilder.CELLAR_LEN
	var cx := LevelBuilder.STAIR_BOTTOM
	var corridor := _sketch_rect(Rect2(SKETCH_X - 1.0, -1.6, LevelBuilder.MAIN_END - SKETCH_X + 1.0, 3.2), top)
	_text(corridor, "Flur (Ostende)", PENCIL, font, 20)
	var door := _sketch_rect(Rect2(LevelBuilder.MAIN_END, -0.9, 0.3, 1.8), top)
	_text(Rect2(door.position + Vector2(-60, door.size.y + 6), Vector2(150, 24)), "niedrig – ducken!", PENCIL, font, 16)
	var stair := _sketch_rect(Rect2(LevelBuilder.MAIN_END + 0.3, -1.0, cx - LevelBuilder.MAIN_END - 0.3, 2.0), top)
	for k in 9:   # Stufen
		var sx := stair.position.x + stair.size.x * (k + 1) / 10.0
		_wobbly_line(Vector2(sx, stair.position.y), Vector2(sx, stair.end.y), PENCIL)
	_text(Rect2(stair.position + Vector2(0, -34), Vector2(stair.size.x, 24)), "Treppe runter →", PENCIL, font, 16)
	var cellar := _sketch_rect(Rect2(cx, -3.0, L, 6.0), top)
	_sketch_rect(Rect2(cx + 2.6, -2.9, 1.8, 0.5), top)                      # Regal
	var crate := _sketch_rect(Rect2(cx + L - 1.35, -2.65, 0.7, 0.7), top)   # Kisten
	_sketch_rect(Rect2(cx + L - 1.2, 2.1, 0.6, 0.6), top)
	_sketch_rect(Rect2(cx + L - 1.9, 2.2, 0.6, 0.6), top)
	_text(Rect2(crate.position + Vector2(-50, 4), Vector2(40, 20)), "18?", PENCIL, font, 18)
	_text(Rect2(cellar.position + Vector2(0, cellar.size.y + 10), Vector2(cellar.size.x, 30)), "hier unten schläft es", PEN, font, 22)


## Rechteck in Weltkoordinaten (x, z) → Bildpunkte im aktuellen Blatt
func _rect(world: Rect2, top: float) -> Rect2:
	return Rect2((world.position.x - _origin.x) * _scale, top + (world.position.y - _origin.y) * _scale,
		world.size.x * _scale, world.size.y * _scale)


func _sketch_rect(world: Rect2, top: float) -> Rect2:
	var r := _rect(world, top)
	var corners := [r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)]
	for k in 4:
		_wobbly_line(corners[k], corners[(k + 1) % 4], PENCIL)
	return r


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


func _area(world: Rect2, fill: Color, label: String, top: float, font: Font) -> void:
	_text(_box(world, fill, top), label, INK, font, 22)


func _dashed_rect(r: Rect2) -> void:
	var corners := [r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)]
	for k in 4:
		draw_dashed_line(corners[k], corners[(k + 1) % 4], FADED, LINE, 8.0)


func _text(r: Rect2, text: String, color: Color, font: Font, font_size: int, angle: float = 0.0) -> void:
	var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var c := r.get_center()
	draw_set_transform(c, deg_to_rad(angle))
	draw_string(font, Vector2(-w / 2.0, font_size * 0.35), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)
	draw_set_transform(Vector2.ZERO)
