class_name HotelMap
extends Control
## Hotelplan auf der Karte (Item.Kind.MAP), Norden (Welt −Z) oben. Beidseitig bedruckt:
## vorn das Erdgeschoss, hinten das Obergeschoss – die Textur hat beide Seiten übereinander
## (FLOOR_SIZE je Seite), die Karte zeigt per UV-Versatz die passende. Gezeichnet aus den
## Bauplänen des LevelBuilder (FLOORS, ROWS) – ändert sich das Hotel, stimmt auch die Karte.
## Wird einmal in einem SubViewport gerendert und danach als Bild behalten (geteilt).

const PX := 9.0                      ## Pixel pro Meter
const X_MIN := -15.5
const X_MAX := 96.0
const Z_MIN := -30.0
const Z_MAX := 20.0
const FLOOR_SIZE := Vector2i(int((X_MAX - X_MIN) * PX), int((Z_MAX - Z_MIN) * PX))
const SIZE := Vector2i(FLOOR_SIZE.x, FLOOR_SIZE.y * 2)
const LINE := 2.0

const PAPER := Color(0.86, 0.8, 0.66)
const INK := Color(0.22, 0.17, 0.13)
const FADED := Color(0.45, 0.38, 0.3)
const CORRIDOR := Color(0.74, 0.66, 0.5)
const ROOM := Color(0.92, 0.87, 0.75)
const GARDEN := Color(0.62, 0.68, 0.5)
const PEN := Color(0.62, 0.1, 0.08)   ## jemand hat Zimmer 13 eingekreist

static var _texture: Texture2D
static var _waiting: Array[Item] = []


## Die Textur des Plans; beim ersten Aufruf wird sie gerendert und danach dem Gegenstand
## über set_map_texture() gereicht.
static func request(item: Item) -> void:
	if _texture:
		item.set_map_texture(_texture)
		return
	_waiting.append(item)
	if _waiting.size() > 1:
		return
	var tree := Engine.get_main_loop() as SceneTree
	var vp := SubViewport.new()
	vp.size = SIZE
	vp.disable_3d = true
	vp.transparent_bg = false
	vp.render_target_update_mode = SubViewport.UPDATE_ONCE
	vp.add_child(HotelMap.new())
	tree.root.add_child.call_deferred(vp)
	_finish.call_deferred(vp)


static func _finish(vp: SubViewport) -> void:
	await RenderingServer.frame_post_draw
	var img := vp.get_texture().get_image()
	vp.queue_free()
	if img == null:   # ohne Grafik (--headless)
		_waiting.clear()
		return
	img.generate_mipmaps()
	_texture = ImageTexture.create_from_image(img)
	for item in _waiting:
		if is_instance_valid(item):
			item.set_map_texture(_texture)
	_waiting.clear()


func _ready() -> void:
	size = Vector2(SIZE)


func _draw() -> void:
	var font := ThemeDB.fallback_font
	draw_rect(Rect2(Vector2.ZERO, size), PAPER)
	for i in LevelBuilder.FLOORS.size():
		var top := float(i * FLOOR_SIZE.y)
		draw_rect(Rect2(Vector2(4, top + 4), Vector2(FLOOR_SIZE) - Vector2(8, 8)), INK, false, LINE)
		# Kopf in der leeren Ecke oben links, Geschoss und Nordpfeil oben rechts
		draw_string(font, Vector2(16, top + 34), "HOTEL – Lageplan", HORIZONTAL_ALIGNMENT_LEFT, -1, 26, INK)
		draw_string(font, Vector2(16, top + 60), "für unsere Gäste", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, FADED)
		var floor_name := "Erdgeschoss" if i == 0 else "1. Obergeschoss"
		draw_string(font, Vector2(FLOOR_SIZE.x - 300, top + 40), floor_name, HORIZONTAL_ALIGNMENT_RIGHT, 220, 26, INK)
		var n := Vector2(FLOOR_SIZE.x - 40, top + 14)
		draw_colored_polygon(PackedVector2Array([n, n + Vector2(-11, 32), n + Vector2(11, 32)]), INK)
		draw_string(font, n + Vector2(-8, 56), "N", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, INK)
		_draw_floor(LevelBuilder.FLOORS[i], top, font)


func _draw_floor(spec: Dictionary, top: float, font: Font) -> void:
	var y: float = spec["y"]
	var ground := y == 0.0
	if ground:
		_area(Rect2(-14.1, -19.1, 14.2, 12.0), GARDEN, "Garten", top, font)
		_area(Rect2(-14.0, -7.0, 14.0, 14.0), CORRIDOR, "Lobby", top, font)
		_area(Rect2(-14.0, 7.0, 8.0, 6.0), ROOM, "Küche", top, font)
		_area(Rect2(-6.0, 7.0, 6.0, 6.0), ROOM, "Bar", top, font)
		# Kellertreppe und Keller: nur gestrichelt, darunter
		var stair := _rect(Rect2(LevelBuilder.MAIN_END, -1.0, LevelBuilder.STAIR_BOTTOM - LevelBuilder.MAIN_END, 2.0), top)
		var cellar := _rect(Rect2(LevelBuilder.STAIR_BOTTOM, -3.0, LevelBuilder.CELLAR_LEN, 6.0), top)
		for r in [stair, cellar]:
			_dashed_rect(r)
		_text(cellar, "Keller", FADED, font, 20)
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


## Rechteck in Weltkoordinaten (x, z) → Bildpunkte
func _rect(world: Rect2, top: float) -> Rect2:
	return Rect2((world.position.x - X_MIN) * PX, top + (world.position.y - Z_MIN) * PX, world.size.x * PX, world.size.y * PX)


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
