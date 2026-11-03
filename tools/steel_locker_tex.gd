extends SceneTree
## Texturen der Stahlspinde (SteelLocker, ZIM-174, Fotos des Nutzers 3.11.), fester Zufallsstartwert – gleiche Karten
## bei jedem Lauf:
##   · steel_paint*: blauer Lack auf Blech, nahtlos – feine Orangenhaut, angelaufene matte Wolken, wenige Kratzer;
##     leicht rau, nur stellenweise glänzend. Farbe, Normal Map (OpenGL), Rauheit.
##   · galvanized*: angelaufenes verzinktes Blech, nahtlos – Zinkblumen (Kristalle mit eigener Helligkeit und Neigung),
##     Walzspuren, stumpfe Flecken. Farbe, Normal Map, Rauheit.
##   · steel_locker_louvre_ao / _d: Lüftungsschlitze oben auf der Tür, einmal über die ganze Türfläche (UV2): Verschattung
##     (Grauwert) und Normale im Objektraum (+Z = vorn, Bild-„oben“ = +Y) – die Schlitze sind nicht modelliert.
##
##   godot --headless --path . -s tools/steel_locker_tex.gd

## = SteelLocker.PAINT_TEX / PAINT_METERS, GALV_TEX / GALV_METERS, LOUVRE_TEX
const PAINT_TEX := "res://assets/textures/steel_paint"
const PAINT_METERS := 0.5
const GALV_TEX := "res://assets/textures/galvanized"
const GALV_METERS := 0.6
const LOUVRE_TEX := "res://assets/textures/steel_locker_louvre"
## = Mat.PHOTO_SIZE
const SIZE := 1024
## Lack: Grundton (sRGB), Rauheit glänzend/angelaufen, Orangenhaut (Wellenlänge und Höhe in mm)
const PAINT := Color(0.2, 0.35, 0.6)
const PAINT_GLOSS := 0.34
const PAINT_DULL := 0.78
const PEEL_MM := 3.0
const PEEL_DEPTH := 0.015
## Zink: Kristallgröße in mm, Helligkeit der Kristalle, Rauheit, Neigung der Kristalle (Höhe in mm je mm)
const SPANGLE_MM := 11.0
const ZINC := Vector2(0.54, 0.63)
const ZINC_ROUGH := Vector2(0.32, 0.55)
const ZINC_DULL := 0.82
const SPANGLE_TILT := 0.06
## Schlitze: Bildgröße (Breite × Höhe, Tür ≈ 0,47 × 1,70 m = SteelLocker.door_size()), Türmaße in mm, Anzahl, Abstand,
## Breite eines Schlitzes, Abstand des ersten von der Oberkante, Höhe der Wölbung und des offenen Spalts, Wölbung vorn
const LOUVRE_PX := Vector2i(512, 2048)
const DOOR_MM := Vector2(469.0, 1704.0)
const LOUVRES := 7
const LOUVRE_PITCH := 22.0
const LOUVRE_W := 230.0
const LOUVRE_TOP := 90.0
const HOOD := 11.0
const SLIT := 3.5
const BULGE := 2.6
const SEED := 1740


func _init() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = SEED
	_paint(rng)
	_galvanized(rng)
	_louvres()
	quit()


## Blauer Lack: Orangenhaut und Korn in der Höhe; große Wolken, wo der Lack angelaufen und stumpf ist (heller,
## grauer, rau), dazwischen Glanz; ein paar feine Kratzer bis aufs Blech
func _paint(rng: RandomNumberGenerator) -> void:
	var mm_px := PAINT_METERS * 1000.0 / SIZE
	var peel := _noise(rng, PAINT_METERS * 1000.0 / PEEL_MM, 2)
	var grain := _noise(rng, SIZE / 3.0, 1)
	var dull := _noise(rng, 4.0, 4)
	var spots := _noise(rng, 14.0, 3)
	var scratches := _scratches(rng, 26, 40.0 / mm_px, 160.0 / mm_px)
	var h := PackedFloat32Array()
	h.resize(SIZE * SIZE)
	var albedo := Image.create(SIZE, SIZE, false, Image.FORMAT_RGB8)
	var rough := Image.create(SIZE, SIZE, false, Image.FORMAT_L8)
	for y in SIZE:
		for x in SIZE:
			var p := peel.get_pixel(x, y).r - 0.5
			var g := grain.get_pixel(x, y).r - 0.5
			var d := smoothstep(0.42, 0.68, dull.get_pixel(x, y).r) * 0.85 + smoothstep(0.55, 0.75, spots.get_pixel(x, y).r) * 0.4
			d = clampf(d, 0.0, 1.0)
			var s := scratches[y * SIZE + x]
			h[y * SIZE + x] = p * 2.0 * PEEL_DEPTH * (1.0 - 0.5 * d) + g * 0.006 - s * 0.01
			var c := PAINT.lerp(Color(0.3, 0.38, 0.52), d * 0.12)   # angelaufen: etwas kreidiger, grauer – vor allem stumpf
			c = c.lightened(0.04 * g) if g > 0.0 else c.darkened(-0.04 * g)
			c = c.lerp(Color(0.55, 0.56, 0.58), s * 0.7)   # Kratzer bis aufs Blech
			albedo.set_pixel(x, y, c)
			var r := lerpf(PAINT_GLOSS, PAINT_DULL, d) + 0.05 * p + 0.04 * g + 0.15 * s
			rough.set_pixel(x, y, Color(r, r, r))
	_save(albedo, _normal(h, mm_px), rough, PAINT_TEX)


## Verzinktes Blech: Zinkblumen als nahtlose Voronoi-Zellen, je Zelle Helligkeit, Rauheit und eine kleine Neigung;
## Walzspuren quer; stumpfe, dunklere Flecken (angelaufen) und weißliche Ränder darum
func _galvanized(rng: RandomNumberGenerator) -> void:
	var mm_px := GALV_METERS * 1000.0 / SIZE
	var cell_px := SPANGLE_MM / mm_px
	var grid := int(round(SIZE / cell_px))
	var step := float(SIZE) / grid
	var points: Array[Vector2] = []
	var tone: Array[float] = []
	var tilt: Array[Vector2] = []
	for i in grid * grid:
		points.append(Vector2(i % grid + rng.randf(), i / grid + rng.randf()) * step)
		tone.append(rng.randf())
		tilt.append(Vector2.from_angle(rng.randf() * TAU) * rng.randf())
	var dull := _noise(rng, 3.0, 4)
	var stains := _noise(rng, 9.0, 3)
	var grain := _noise(rng, SIZE / 2.5, 1)
	var rolling := FastNoiseLite.new()
	rolling.seed = rng.randi()
	rolling.frequency = 1.0
	var h := PackedFloat32Array()
	h.resize(SIZE * SIZE)
	var slope := PackedVector2Array()   # Neigung der Zinkblume – direkt in die Normale, sonst Sprünge an den Grenzen
	slope.resize(SIZE * SIZE)
	var albedo := Image.create(SIZE, SIZE, false, Image.FORMAT_RGB8)
	var rough := Image.create(SIZE, SIZE, false, Image.FORMAT_L8)
	for y in SIZE:
		for x in SIZE:
			# nächste Zelle (mit Umlauf über den Rand)
			var gx := int(x / step)
			var gy := int(y / step)
			var best := INF
			var second := INF
			var id := 0
			for oy in range(-1, 2):
				for ox in range(-1, 2):
					var cx := posmod(gx + ox, grid)
					var cy := posmod(gy + oy, grid)
					var pt := points[cy * grid + cx] + Vector2((gx + ox - cx) * step, (gy + oy - cy) * step)
					var dist := pt.distance_squared_to(Vector2(x, y))
					if dist < best:
						second = best
						best = dist
						id = cy * grid + cx
					elif dist < second:
						second = dist
			var edge := clampf((sqrt(second) - sqrt(best)) / 1.5, 0.0, 1.0)   # 0 an der Korngrenze
			var t: float = tone[id]
			var tl: Vector2 = tilt[id]
			var d := clampf(smoothstep(0.45, 0.7, dull.get_pixel(x, y).r) + smoothstep(0.6, 0.78, stains.get_pixel(x, y).r) * 0.6, 0.0, 1.0)
			var g := grain.get_pixel(x, y).r - 0.5
			var roll := rolling.get_noise_2d(x * 0.02, y * 1.4) * 0.5   # Walzspuren quer, kaum sichtbar
			slope[y * SIZE + x] = tl * SPANGLE_TILT * (1.0 - d * 0.7)
			h[y * SIZE + x] = -(1.0 - edge) * 0.004 + g * 0.003 + roll * 0.002
			var v := lerpf(ZINC.x, ZINC.y, t) * (1.0 - d * 0.18) + 0.03 * g + 0.02 * roll - (1.0 - edge) * 0.03
			var c := Color(v * 0.98, v, v * 1.02).lerp(Color(0.62, 0.62, 0.6), d * 0.3)
			albedo.set_pixel(x, y, c)
			var r := lerpf(lerpf(ZINC_ROUGH.x, ZINC_ROUGH.y, 1.0 - t), ZINC_DULL, d) + 0.04 * g + (1.0 - edge) * 0.08
			rough.set_pixel(x, y, Color(r, r, r))
	_save(albedo, _normal(h, mm_px, slope), rough, GALV_TEX)


## Lüftungsschlitze: LOUVRES Reihen gepresster Kiemen oben in der Türmitte. Jede Kieme wölbt sich über HOOD mm nach
## vorn (oben flach ansteigend), darunter der offene Spalt SLIT, an den Enden rund auslaufend.
func _louvres() -> void:
	var w := LOUVRE_PX.x
	var hh := LOUVRE_PX.y
	var mm := Vector2(DOOR_MM.x / w, DOOR_MM.y / hh)   # mm je Pixel
	var height := PackedFloat32Array()
	height.resize(w * hh)
	var shade := PackedFloat32Array()
	shade.resize(w * hh)
	shade.fill(1.0)
	var x0 := (DOOR_MM.x - LOUVRE_W) / 2.0
	for y in hh:
		var ym := (y + 0.5) * mm.y   # mm von der Oberkante
		var k := floori((ym - LOUVRE_TOP) / LOUVRE_PITCH)
		if k < 0 or k >= LOUVRES:
			continue
		var t := ym - LOUVRE_TOP - k * LOUVRE_PITCH   # mm in der Kieme, 0 = oben
		for x in w:
			var xm := (x + 0.5) * mm.x - x0
			if xm < -2.0 or xm > LOUVRE_W + 2.0:
				continue
			# Enden: die Wölbung läuft über 9 mm rund aus
			var end := clampf(minf(xm, LOUVRE_W - xm) / 9.0, 0.0, 1.0)
			end = sqrt(1.0 - (1.0 - end) * (1.0 - end))
			var i := y * w + x
			if t < HOOD:
				var a := t / HOOD
				height[i] = BULGE * end * a * (1.6 - 0.6 * a)   # steigt flach an, vorn am höchsten
				shade[i] = 1.0 - 0.12 * a * end   # unterseits leicht dunkler
			elif t < HOOD + SLIT:
				height[i] = BULGE * end * (1.0 - smoothstep(0.0, 1.2, t - HOOD))
				shade[i] = lerpf(1.0, 0.12, end)   # in den Spalt hinein: dunkel
			elif t < HOOD + SLIT + 2.5:
				shade[i] = lerpf(1.0, 0.75 + 0.1 * (t - HOOD - SLIT), end)   # Schatten unter der Kante
	var normal := Image.create(w, hh, false, Image.FORMAT_RGB8)
	var ao := Image.create(w, hh, false, Image.FORMAT_L8)
	for y in hh:
		for x in w:
			var i := y * w + x
			var dx := (height[y * w + mini(x + 1, w - 1)] - height[y * w + maxi(x - 1, 0)]) / (2.0 * mm.x)
			var dy := (height[mini(y + 1, hh - 1) * w + x] - height[maxi(y - 1, 0) * w + x]) / (2.0 * mm.y)
			var n := Vector3(-dx, dy, 1.0).normalized()   # Bildzeile wächst nach unten, +Y = oben
			normal.set_pixel(x, y, Color(n.x * 0.5 + 0.5, n.y * 0.5 + 0.5, n.z * 0.5 + 0.5))
			ao.set_pixel(x, y, Color(shade[i], shade[i], shade[i]))
	normal.save_png(LOUVRE_TEX + "_d.png")
	ao.save_png(LOUVRE_TEX + "_ao.png")
	print(LOUVRE_TEX)


## Feine Kratzer: count gerade Striche (Länge in Pixeln), je ein, zwei Pixel breit, nahtlos; 0 … 1
func _scratches(rng: RandomNumberGenerator, count: int, short: float, long: float) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	out.resize(SIZE * SIZE)
	for i in count:
		var from := Vector2(rng.randf(), rng.randf()) * SIZE
		var dir := Vector2.from_angle(rng.randf_range(-0.5, 0.5) + (PI / 2.0 if rng.randf() < 0.3 else 0.0))
		var length := rng.randf_range(short, long)
		var depth := rng.randf_range(0.4, 1.0)
		var steps := int(length * 2.0)
		for s in steps:
			var p := from + dir * (s * 0.5)
			var fade := sin(PI * s / steps)   # Anfang und Ende dünn
			out[posmod(int(p.y), SIZE) * SIZE + posmod(int(p.x), SIZE)] = maxf(out[posmod(int(p.y), SIZE) * SIZE + posmod(int(p.x), SIZE)], depth * fade)
	return out


func _save(albedo: Image, normal: Image, rough: Image, path: String) -> void:
	albedo.save_png(path + ".png")
	normal.save_png(path + "_normal.png")
	rough.save_png(path + "_rough.png")
	print(path)


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


## Normal Map aus der Höhe in mm (mm_px = mm je Pixel), nahtlos; slope: zusätzliche Neigung je Pixel (mm je mm)
func _normal(h: PackedFloat32Array, mm_px: float, slope := PackedVector2Array()) -> Image:
	var img := Image.create(SIZE, SIZE, false, Image.FORMAT_RGB8)
	for y in SIZE:
		for x in SIZE:
			var dx := (h[y * SIZE + (x + 1) % SIZE] - h[y * SIZE + posmod(x - 1, SIZE)]) / (2.0 * mm_px)
			var dy := (h[((y + 1) % SIZE) * SIZE + x] - h[posmod(y - 1, SIZE) * SIZE + x]) / (2.0 * mm_px)
			if not slope.is_empty():
				dx += slope[y * SIZE + x].x
				dy += slope[y * SIZE + x].y
			var n := Vector3(-dx, dy, 1.0).normalized()   # Bildzeile wächst nach unten, Grün = oben
			img.set_pixel(x, y, Color(n.x * 0.5 + 0.5, n.y * 0.5 + 0.5, n.z * 0.5 + 0.5))
	return img
