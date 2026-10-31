extends SceneTree
## Texturen des Mülleimers (TrashCan): gebürstetes Messing für den Deckel und fast schwarzer, seidenmatter Lack für
## den Korpus, je Farbe, Normal Map (OpenGL) und Rauheit, nahtlos kachelbar. Messing in den Farben der Plaketten
## (tools/room_plate.gd), die Bürstung läuft entlang x (= u im Mesh): feine Riefen in mehreren Breiten, entlang lang
## gezogen, dazu einzelne tiefere Riefen; Farbe und Rauheit folgen den Riefen, sonst gleichmäßig (keine Flecken).
## Lack gleichmäßig mit leichter Orangenhaut. Fester Zufallsstartwert – gleiche Karten bei jedem Lauf.
##
##   godot --headless --path . -s tools/trash_can.gd

## Ausgabe und Kachelgröße in Metern = TrashCan.BRASS_TEX, COAT_TEX, BRASS_METERS, COAT_METERS (hier ohne TrashCan,
## das über GrandStair das ganze Spiel lädt)
const BRASS_TEX := "res://assets/textures/trash_brass"
const COAT_TEX := "res://assets/textures/trash_coat"
const BRASS_METERS := 0.25
const COAT_METERS := 0.25
## = Mat.PHOTO_SIZE
const SIZE := 1024
## Messing (sRGB): Farbe, wie stark die Riefen sie aufhellen und abdunkeln, Rauheit und ihr Spiel mit den Riefen
const BRASS := Color(0.93, 0.76, 0.43)
const BRUSH_SHADE := 0.15
const BRUSH_ROUGH := 0.3
const BRUSH_ROUGH_SPREAD := 0.1
## Bürstung: je Lage (Zeilen je Kachel quer, Stützstellen je Kachel entlang, Anteil), Tiefe in mm; einzelne tiefere
## Riefen (Anzahl, Länge in mm, Tiefe in mm)
const BRUSH_LAYERS := [Vector3(1024, 3, 0.6), Vector3(512, 4, 0.8), Vector3(256, 5, 1.0), Vector3(128, 6, 0.8),
	Vector3(32, 4, 0.3)]
const BRUSH_DEPTH := 0.03
const GROOVES := 500
const GROOVE_MM := Vector2(15.0, 120.0)
const GROOVE_DEPTH := 0.02
## Lack: Farbe (sRGB), Rauheit, Orangenhaut (Wellenlänge und Höhe in mm)
const COAT := Color(0.045, 0.045, 0.048)
const COAT_ROUGH := 0.38
const PEEL_MM := 2.5
const PEEL_DEPTH := 0.02
const SEED := 1313


func _init() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = SEED
	_brass(rng)
	_coat(rng)
	quit()


## Messing gebürstet: Riefen aus BRUSH_LAYERS und GROOVES, Höhe in mm
func _brass(rng: RandomNumberGenerator) -> void:
	var px_mm := SIZE / (BRASS_METERS * 1000.0)
	var h := PackedFloat32Array()
	h.resize(SIZE * SIZE)
	var total := 0.0
	for layer: Vector3 in BRUSH_LAYERS:
		_streaks(rng, h, int(layer.x), int(layer.y), layer.z)
		total += layer.z
	for i in h.size():
		h[i] *= BRUSH_DEPTH / total
	for _i in GROOVES:
		var row := rng.randi() % SIZE * SIZE
		var x0 := rng.randi() % SIZE
		var length := rng.randf_range(GROOVE_MM.x, GROOVE_MM.y) * px_mm
		var depth := GROOVE_DEPTH * rng.randf_range(0.4, 1.0)
		for k in ceili(length):
			h[row + (x0 + k) % SIZE] -= depth * sin(PI * k / length)   # Enden laufen aus
	var albedo := Image.create(SIZE, SIZE, false, Image.FORMAT_RGB8)
	var rough := Image.create(SIZE, SIZE, false, Image.FORMAT_L8)
	for y in SIZE:
		for x in SIZE:
			var t := clampf(h[y * SIZE + x] / BRUSH_DEPTH, -1.0, 1.0)   # oben hell und glatt, in der Riefe dunkler, rauer
			albedo.set_pixel(x, y, BRASS.lightened(BRUSH_SHADE * t) if t > 0.0 else BRASS.darkened(-BRUSH_SHADE * t))
			var r := BRUSH_ROUGH - BRUSH_ROUGH_SPREAD * t
			rough.set_pixel(x, y, Color(r, r, r))
	_save(albedo, rough, _normal(h, 1.0 / px_mm), BRASS_TEX)


## Lack: Orangenhaut als feines Rauschen in der Höhe, Farbe gleichmäßig, Rauheit kaum bewegt
func _coat(rng: RandomNumberGenerator) -> void:
	var px_mm := SIZE / (COAT_METERS * 1000.0)
	var peel := _noise(rng, COAT_METERS * 1000.0 / PEEL_MM, 2)
	var h := PackedFloat32Array()
	h.resize(SIZE * SIZE)
	var albedo := Image.create(SIZE, SIZE, false, Image.FORMAT_RGB8)
	albedo.fill(COAT)
	var rough := Image.create(SIZE, SIZE, false, Image.FORMAT_L8)
	for y in SIZE:
		for x in SIZE:
			var p := peel.get_pixel(x, y).r - 0.5
			h[y * SIZE + x] = p * 2.0 * PEEL_DEPTH
			var r := COAT_ROUGH + 0.03 * p
			rough.set_pixel(x, y, Color(r, r, r))
	_save(albedo, rough, _normal(h, 1.0 / px_mm), COAT_TEX)


## Riefen entlang x zu h addieren (Werte −amount … amount): Zufallswerte auf einem Gitter aus rows Zeilen und cells
## Stützstellen je Zeile, weich dazwischen, über den Rand gewickelt
func _streaks(rng: RandomNumberGenerator, h: PackedFloat32Array, rows: int, cells: int, amount: float) -> void:
	var grid := PackedFloat32Array()
	grid.resize(rows * cells)
	for i in grid.size():
		grid[i] = rng.randf_range(-amount, amount)
	for y in SIZE:
		var fy := float(y) * rows / SIZE
		var y0 := floori(fy)
		var ty := smoothstep(0.0, 1.0, fy - y0)
		var a := (y0 % rows) * cells
		var b := ((y0 + 1) % rows) * cells
		for x in SIZE:
			var fx := float(x) * cells / SIZE
			var x0 := floori(fx)
			var tx := smoothstep(0.0, 1.0, fx - x0)
			var x1 := (x0 + 1) % cells
			h[y * SIZE + x] += lerpf(lerpf(grid[a + x0], grid[a + x1], tx), lerpf(grid[b + x0], grid[b + x1], tx), ty)


## Nahtloses Rauschen (0 … 1), cells Strukturen je Kachel
func _noise(rng: RandomNumberGenerator, cells: float, octaves: int) -> Image:
	var n := FastNoiseLite.new()
	n.seed = rng.randi()
	n.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	n.frequency = cells / SIZE
	n.fractal_octaves = octaves
	var img := n.get_seamless_image(SIZE, SIZE, false, false, 0.1, true)
	img.convert(Image.FORMAT_L8)
	return img


## Normal Map aus der Höhe in mm (mm_px = mm je Pixel)
func _normal(h: PackedFloat32Array, mm_px: float) -> Image:
	var img := Image.create(SIZE, SIZE, false, Image.FORMAT_RGB8)
	for y in SIZE:
		for x in SIZE:
			var dx := (h[y * SIZE + (x + 1) % SIZE] - h[y * SIZE + posmod(x - 1, SIZE)]) / (2.0 * mm_px)
			var dy := (h[((y + 1) % SIZE) * SIZE + x] - h[posmod(y - 1, SIZE) * SIZE + x]) / (2.0 * mm_px)
			var n := Vector3(-dx, dy, 1.0).normalized()   # Bildzeile wächst nach unten, Grün = oben
			img.set_pixel(x, y, Color(n.x * 0.5 + 0.5, n.y * 0.5 + 0.5, n.z * 0.5 + 0.5))
	return img


func _save(albedo: Image, rough: Image, normal: Image, base: String) -> void:
	albedo.save_png(base + ".png")
	normal.save_png(base + "_normal.png")
	rough.save_png(base + "_rough.png")
	print(base)
