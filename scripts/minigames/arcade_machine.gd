class_name ArcadeMachine
extends StaticBody3D
## Videospielautomat in der Bar (Spielkonzept 6.10, Entscheidung 28.10.): ein aufrechtes Spielgerät mit Leuchtschild,
## schrägem Bildschirm, Joystick und zwei Knöpfen. Zwei Spiele, beide eigene Entwürfe statt Tetris und Pac-Man:
## - „deadra“: Fünferformen aus Gespenstern, Kürbissen und Totenschädeln fallen in ein Feld 12 × 18.
## - „ghost_hotel“: ein Männchen sammelt Kürbisse in Hotelfluren, Lakengespenster jagen es; mit einer Laterne
##   blinken sie rot und fliehen.
## Bisher läuft nur die Vorführung (Attract-Modus) auf dem Bildschirm – spielbar sind sie noch nicht (Geld,
## Bestenliste und Lautstärke sind offen). Der Bildschirm ist ein kleines Pixelbild (SCREEN_PX), das nur neu gemalt
## wird, wenn der Spieler in der Nähe ist. Kein gespeicherter Zustand. Ursprung am Boden, lokale +Z = Front.

const SIZE := Vector3(0.7, 1.82, 0.8)
const SCREEN_PX := Vector2i(120, 160)      ## Hochformat wie bei alten Automaten
const SCREEN_SIZE := Vector2(0.39, 0.52)
const SCREEN_AT := Vector3(0.0, 1.3, 0.07)     ## Mitte, z vor der Front des Rumpfs
const SCREEN_TILT := -0.18                 ## nach hinten gekippt
const TICK := 0.18                         ## Sekunden je Bild der Vorführung
const AWAKE_RANGE := 14.0                  ## weiter weg steht das Bild still
## Je Spiel: Titel auf dem Leuchtschild, Farbe des Gehäuses, Farbe des Schilds und des Scheins
const LOOKS := {
	"deadra": {"title": "DEADRA", "body": Color(0.13, 0.05, 0.16), "glow": Color(0.75, 0.95, 0.55)},
	"ghost_hotel": {"title": "GHOST HOTEL", "body": Color(0.05, 0.07, 0.2), "glow": Color(1.0, 0.6, 0.2)},
}

## Deadra: Feld, Kästchengröße in Pixeln, die zwölf Fünferformen (Spielkonzept 6.10)
const FIELD := Vector2i(12, 18)
const CELL := 6
const FIELD_AT := Vector2i(6, 36)
const PENTOMINOES := [
	[Vector2i(1, 0), Vector2i(2, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(1, 2)],   # F
	[Vector2i(0, 0), Vector2i(0, 1), Vector2i(0, 2), Vector2i(0, 3), Vector2i(0, 4)],   # I
	[Vector2i(0, 0), Vector2i(0, 1), Vector2i(0, 2), Vector2i(0, 3), Vector2i(1, 3)],   # L
	[Vector2i(1, 0), Vector2i(1, 1), Vector2i(0, 2), Vector2i(1, 2), Vector2i(0, 3)],   # N
	[Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(0, 2)],   # P
	[Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(1, 1), Vector2i(1, 2)],   # T
	[Vector2i(0, 0), Vector2i(2, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1)],   # U
	[Vector2i(0, 0), Vector2i(0, 1), Vector2i(0, 2), Vector2i(1, 2), Vector2i(2, 2)],   # V
	[Vector2i(0, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(1, 2), Vector2i(2, 2)],   # W
	[Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1), Vector2i(1, 2)],   # X
	[Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(1, 2), Vector2i(1, 3)],   # Y
	[Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, 1), Vector2i(1, 2), Vector2i(2, 2)],   # Z
]
## Kästchenbilder 6 × 6 (# = Grundfarbe, o = dunkel, g = Stiel)
const TILES := {
	"ghost": [".####.", "#o##o#", "######", "######", "######", "#.##.#"],
	"pumpkin": ["..g...", ".####.", "#o##o#", "######", "#oooo#", ".####."],
	"skull": [".####.", "######", "#oo#oo", "######", ".#o#o.", ".####."],
}
const TILE_COLORS := {"ghost": Color(0.92, 0.94, 1.0), "pumpkin": Color(1.0, 0.5, 0.08), "skull": Color(0.86, 0.82, 0.68)}
const TILE_KINDS: Array[String] = ["ghost", "pumpkin", "skull"]

## Ghost Hotel: Hotelflure (# Wand, . Kürbis, L Laterne, S Startraum der Gespenster), 8 Pixel je Feld
const MAZE := [
	"###############",
	"#.....#.#.....#",
	"#.###.#.#.###.#",
	"#L...........L#",
	"#.###.#.#.###.#",
	"#.#...#.#...#.#",
	"#.#.###.###.#.#",
	"#.....#S#.....#",
	"#.#.#.###.#.#.#",
	"#...#.....#...#",
	"#.###.###.###.#",
	"#.............#",
	"#.###.#.#.###.#",
	"#.....#.#.....#",
	"#.###.#.#.###.#",
	"#L...........L#",
	"#.###.#.#.###.#",
	"#.....#.#.....#",
	"###############",
]
const MAZE_CELL := 8
const MAZE_AT := Vector2i(0, 8)
const MAN := ["...##...", "...##...", "..####..", ".#.##.#.", "...##...", "..#..#..", "..#..#.."]
const SHEET := ["..####..", ".######.", "##o##o##", "########", "########", "########", "#.##.##.", "........"]
const SCARED_TICKS := 24                   ## so lange blinken die Gespenster nach einer Laterne rot
const GHOST_GAPS: Array[int] = [5, 9, 13]  ## so viele Felder laufen die Gespenster hinter dem Männchen

var game := "deadra"

var _image: Image
var _texture: ImageTexture
var _coin_label: Label3D
var _tick := 0.0
var _frame := 0
var _rng := RandomNumberGenerator.new()
## Deadra: liegende Kästchen (Vector2i → Art), fallendes Teil
var _stack := {}
var _piece := 0
var _piece_kind := 0
var _piece_at := Vector2i.ZERO
var _next_piece := 0
## Ghost Hotel: Rundweg, Stelle des Männchens darauf, gefressene Kürbisse, Angst-Zähler
var _loop: Array[Vector2i] = []
var _step := 0
var _eaten := {}
var _scared := 0


func setup(which: String) -> ArcadeMachine:
	game = which if LOOKS.has(which) else "deadra"
	return self


func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	_rng.seed = hash(game)
	var look: Dictionary = LOOKS[game]
	var body := Mat.psx(look["body"])
	var black := Mat.psx(Color(0.03, 0.03, 0.035))
	var panel := Mat.psx(Color(0.08, 0.08, 0.09))
	var back_depth := 0.55
	var back_z := -SIZE.z / 2.0 + back_depth / 2.0
	Geo.box_part(self, Vector3(SIZE.x, SIZE.y, back_depth), Vector3(0, SIZE.y / 2.0, back_z), body)   # Rumpf
	var front_depth := SIZE.z - back_depth
	Geo.box_part(self, Vector3(SIZE.x, 0.88, front_depth), Vector3(0, 0.44, SIZE.z / 2.0 - front_depth / 2.0), body)   # Unterbau
	var face_z := back_z + back_depth / 2.0
	# Bedienfeld: schräg nach vorn, Joystick links, zwei Knöpfe rechts
	var desk := Node3D.new()
	desk.position = Vector3(0, 0.92, face_z + 0.12)
	desk.rotation.x = 0.22
	add_child(desk)
	Geo.mesh(desk, Geo.box(Vector3(SIZE.x + 0.02, 0.05, 0.3)), panel, Vector3.ZERO)
	var stick := Geo.mesh(desk, Geo.cylinder(0.008, 0.09, 6), Mat.metal(), Vector3(-0.15, 0.07, 0.02))
	Geo.mesh(stick, Geo.sphere(0.022, 0.044, 8, 4), Mat.psx(Color(0.75, 0.08, 0.06)), Vector3(0, 0.05, 0))
	for i in 2:
		Geo.mesh(desk, Geo.cylinder(0.02, 0.02, 10), Mat.psx(Color(0.9, 0.8, 0.2) if i == 0 else Color(0.2, 0.5, 0.9)),
			Vector3(0.08 + i * 0.08, 0.03, 0.02))
	# Münztür am Unterbau
	var coin_z := SIZE.z / 2.0 + 0.004
	Geo.mesh(self, Geo.box(Vector3(0.26, 0.3, 0.008)), black, Vector3(0, 0.5, coin_z))
	for i in 2:
		Geo.mesh(self, Geo.box(Vector3(0.025, 0.05, 0.01)), Mat.psx(Color(0.2, 0.08, 0.02), "", 1.0, Color(1.0, 0.45, 0.1), 1.2),
			Vector3(-0.05 + i * 0.1, 0.56, coin_z + 0.004))
	# Bildschirm in schwarzem Rahmen, nach hinten gekippt
	var screen := Node3D.new()
	screen.position = SCREEN_AT + Vector3(0, 0, face_z)
	screen.rotation.x = SCREEN_TILT
	add_child(screen)
	Geo.mesh(screen, Geo.box(Vector3(SIZE.x - 0.06, SCREEN_SIZE.y + 0.08, 0.02)), black, Vector3(0, 0, -0.012))
	_image = Image.create(SCREEN_PX.x, SCREEN_PX.y, false, Image.FORMAT_RGBA8)
	_texture = ImageTexture.create_from_image(_image)
	var glass := StandardMaterial3D.new()
	glass.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	glass.albedo_texture = _texture
	glass.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	var quad := QuadMesh.new()
	quad.size = SCREEN_SIZE
	var shown := MeshInstance3D.new()
	shown.mesh = quad
	shown.material_override = glass
	shown.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	screen.add_child(shown)
	_coin_label = Label3D.new()
	_coin_label.text = "MÜNZE EINWERFEN"
	_coin_label.font_size = 32
	_coin_label.pixel_size = 0.0007
	_coin_label.outline_size = 8
	_coin_label.outline_modulate = Color(0, 0, 0)
	_coin_label.modulate = Color(1.0, 0.95, 0.6)
	_coin_label.position = Vector3(0, -SCREEN_SIZE.y / 2.0 + 0.03, 0.01)
	screen.add_child(_coin_label)
	# Leuchtschild oben
	var sign_z := face_z + 0.02
	Geo.mesh(self, Geo.box(Vector3(SIZE.x, 0.2, 0.04)), Mat.psx(Color(0.1, 0.1, 0.1), "", 1.0, look["glow"], 0.35),
		Vector3(0, SIZE.y - 0.11, sign_z))
	var title := Label3D.new()
	title.text = look["title"]
	title.font_size = 48
	title.pixel_size = 0.0021 if game == "deadra" else 0.0016
	title.modulate = (look["glow"] as Color).lightened(0.3)
	title.outline_size = 10
	title.outline_modulate = Color(0.02, 0.02, 0.02)
	title.position = Vector3(0, SIZE.y - 0.11, sign_z + 0.022)
	add_child(title)
	var light := OmniLight3D.new()
	light.light_color = look["glow"]
	light.light_energy = 0.25
	light.omni_range = 2.0
	light.position = Vector3(0, 1.3, face_z + 0.45)
	light.add_to_group("light_source")
	add_child(light)
	if game == "deadra":
		_deadra_start()
	else:
		_hotel_start()
	_draw()


func _process(delta: float) -> void:
	_tick += delta
	if _tick < TICK:
		return
	_tick = 0.0
	if Game.player and Game.player.global_position.distance_to(global_position) > AWAKE_RANGE:
		return
	_frame += 1
	_coin_label.visible = _frame % 6 < 4
	if game == "deadra":
		_deadra_step()
	else:
		_hotel_step()
	_draw()


func _draw() -> void:
	_image.fill(Color(0.01, 0.01, 0.02))
	if game == "deadra":
		_deadra_draw()
	else:
		_hotel_draw()
	_texture.update(_image)


# --- Deadra -------------------------------------------------------------------------------------------------

## Vorführung: unten liegt ein zerklüfteter Haufen, oben fällt ein Teil nach dem anderen hinein.
func _deadra_start() -> void:
	_stack.clear()
	for y in range(FIELD.y - 6, FIELD.y):
		for x in FIELD.x:
			if _rng.randf() < 0.35 + (y - (FIELD.y - 6)) * 0.1:
				_stack[Vector2i(x, y)] = _rng.randi() % TILE_KINDS.size()
	_next_piece = _rng.randi() % PENTOMINOES.size()
	_deadra_spawn()


func _deadra_spawn() -> void:
	_piece = _next_piece
	_piece_kind = _rng.randi() % TILE_KINDS.size()
	_next_piece = _rng.randi() % PENTOMINOES.size()
	_piece_at = Vector2i(_rng.randi_range(0, FIELD.x - 3), 0)


func _deadra_fits(at: Vector2i) -> bool:
	for c: Vector2i in PENTOMINOES[_piece]:
		var p := at + c
		if p.x < 0 or p.x >= FIELD.x or p.y >= FIELD.y or _stack.has(p):
			return false
	return true


func _deadra_step() -> void:
	if _deadra_fits(_piece_at + Vector2i(0, 1)):
		_piece_at.y += 1
		return
	for c: Vector2i in PENTOMINOES[_piece]:
		_stack[_piece_at + c] = _piece_kind
	for y in FIELD.y:   # volle Reihen versinken
		var full := true
		for x in FIELD.x:
			full = full and _stack.has(Vector2i(x, y))
		if full:
			var moved := {}
			for p: Vector2i in _stack:
				if p.y < y:
					moved[p + Vector2i(0, 1)] = _stack[p]
				elif p.y > y:
					moved[p] = _stack[p]
			_stack = moved
	var top := FIELD.y
	for p: Vector2i in _stack:
		top = mini(top, p.y)
	if top < 6:
		_deadra_start()   # zu hoch gestapelt – die Vorführung beginnt von vorn
	else:
		_deadra_spawn()


func _deadra_draw() -> void:
	var frame := Color(0.35, 0.3, 0.4)
	_image.fill_rect(Rect2i(FIELD_AT - Vector2i(2, 2), FIELD * CELL + Vector2i(4, 4)), frame)
	_image.fill_rect(Rect2i(FIELD_AT, FIELD * CELL), Color(0.04, 0.05, 0.04))
	for p: Vector2i in _stack:
		_tile(FIELD_AT + p * CELL, TILE_KINDS[_stack[p]])
	for c: Vector2i in PENTOMINOES[_piece]:
		_tile(FIELD_AT + (_piece_at + c) * CELL, TILE_KINDS[_piece_kind])
	# Vorschau rechts oben: das nächste Teil klein (3 Pixel je Kästchen)
	var preview := Vector2i(FIELD_AT.x + FIELD.x * CELL + 8, FIELD_AT.y)
	_image.fill_rect(Rect2i(preview - Vector2i(2, 2), Vector2i(22, 22)), frame)
	_image.fill_rect(Rect2i(preview, Vector2i(18, 18)), Color(0.04, 0.05, 0.04))
	for c: Vector2i in PENTOMINOES[_next_piece]:
		_image.fill_rect(Rect2i(preview + Vector2i(2, 2) + c * 3, Vector2i(3, 3)), Color(0.75, 0.95, 0.55))
	# Punkte als Balken unter der Vorschau, damit es nach Spiel aussieht
	for i in 4:
		_image.fill_rect(Rect2i(preview.x, preview.y + 30 + i * 6, 6 + (i * 5 + _frame / 8) % 13, 3), Color(0.75, 0.95, 0.55, 0.8))


func _tile(at: Vector2i, kind: String) -> void:
	var rows: Array = TILES[kind]
	var base: Color = TILE_COLORS[kind]
	for y in rows.size():
		var row: String = rows[y]
		for x in row.length():
			match row[x]:
				"#":
					_image.set_pixel(at.x + x, at.y + y, base)
				"o":
					_image.set_pixel(at.x + x, at.y + y, base.darkened(0.75))
				"g":
					_image.set_pixel(at.x + x, at.y + y, Color(0.2, 0.6, 0.15))


# --- Ghost Hotel ---------------------------------------------------------------------------------------------

## Vorführung: Das Männchen läuft die äußere Runde der Hotelflure ab, die Gespenster hinterher.
func _hotel_start() -> void:
	_loop.clear()
	var corners := [Vector2i(1, 3), Vector2i(13, 3), Vector2i(13, 15), Vector2i(1, 15)]
	for i in corners.size():
		var a: Vector2i = corners[i]
		var b: Vector2i = corners[(i + 1) % corners.size()]
		var d := (b - a).sign()
		var p := a
		while p != b:
			_loop.append(p)
			p += d
	_step = 0
	_eaten.clear()
	_scared = 0


func _hotel_step() -> void:
	_step = (_step + 1) % _loop.size()
	var at := _loop[_step]
	if MAZE[at.y][at.x] == "L" and not _eaten.has(at):
		_scared = SCARED_TICKS
	_eaten[at] = true
	_scared = maxi(0, _scared - 1)
	if _step == 0:
		_eaten.clear()   # nach einer Runde liegen wieder überall Kürbisse


func _hotel_draw() -> void:
	var wall := Color(0.36, 0.16, 0.1)        # dunkles Holz der Flurwände
	var carpet := Color(0.12, 0.03, 0.05)     # Flurteppich
	for y in MAZE.size():
		var row: String = MAZE[y]
		for x in row.length():
			var at := MAZE_AT + Vector2i(x, y) * MAZE_CELL
			var cell := Vector2i(x, y)
			match row[x]:
				"#":
					_image.fill_rect(Rect2i(at, Vector2i(MAZE_CELL, MAZE_CELL)), wall)
					_image.fill_rect(Rect2i(at + Vector2i(1, 1), Vector2i(MAZE_CELL - 2, MAZE_CELL - 2)), wall.darkened(0.35))
				"S":
					_image.fill_rect(Rect2i(at, Vector2i(MAZE_CELL, MAZE_CELL)), Color(0.15, 0.15, 0.3))
				_:
					_image.fill_rect(Rect2i(at, Vector2i(MAZE_CELL, MAZE_CELL)), carpet)
					if _eaten.has(cell):
						continue
					if row[x] == "L":   # Laterne
						_image.fill_rect(Rect2i(at + Vector2i(2, 1), Vector2i(4, 1)), Color(0.2, 0.2, 0.2))
						_image.fill_rect(Rect2i(at + Vector2i(2, 2), Vector2i(4, 4)), Color(1.0, 0.85, 0.3) if _frame % 2 == 0 else Color(1.0, 0.7, 0.2))
					else:   # kleiner Kürbis
						_image.fill_rect(Rect2i(at + Vector2i(3, 3), Vector2i(2, 2)), Color(1.0, 0.5, 0.08))
						_image.set_pixel(at.x + 4, at.y + 2, Color(0.2, 0.6, 0.15))
	for gap in GHOST_GAPS:
		var cell := _loop[posmod(_step - gap, _loop.size())]
		var color := Color(0.92, 0.94, 1.0)
		if _scared > 0:
			color = Color(1.0, 0.15, 0.1) if _frame % 2 == 0 else Color(0.5, 0.05, 0.05)
		_sprite(MAZE_AT + cell * MAZE_CELL, SHEET, color)
	_sprite(MAZE_AT + _loop[_step] * MAZE_CELL, MAN, Color(0.4, 0.85, 0.35))
	# Kopfzeile: Kürbisse dieser Runde als Punkte
	for i in mini(_eaten.size(), 28):
		_image.fill_rect(Rect2i(4 + i * 4, 2, 2, 2), Color(1.0, 0.5, 0.08))


func _sprite(at: Vector2i, rows: Array, color: Color) -> void:
	for y in rows.size():
		var row: String = rows[y]
		for x in row.length():
			if row[x] == "#":
				_image.set_pixel(at.x + x, at.y + y, color)
			elif row[x] == "o":
				_image.set_pixel(at.x + x, at.y + y, Color(0.05, 0.05, 0.1))
