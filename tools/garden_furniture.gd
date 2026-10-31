extends SceneTree
## Texturen der Gartenmöbel (GardenFurniture, ZIM-51): anthrazit pulverbeschichtetes Aluminium für die Gestelle und
## graues Textilgewebe (Textilene) für Sitz und Lehne der Stühle, je Farbe, Normal Map (OpenGL) und Rauheit, nahtlos
## kachelbar. Pulverlack gleichmäßig mit Orangenhaut und feinem Korn, seidenmatt. Gewebe in Leinwandbindung: Kett-
## fäden entlang v, Schussfäden entlang u, abwechselnd oben; dazwischen kleine Löcher, durch die es dunkel ist. Jeder
## Faden etwas heller oder dunkler (meliert). Fester Zufallsstartwert – gleiche Karten bei jedem Lauf.
##
##   godot --headless --path . -s tools/garden_furniture.gd

## Ausgabe und Kachelgröße in Metern = GardenFurniture.COAT_TEX, FABRIC_TEX, COAT_METERS, FABRIC_METERS (hier ohne
## GardenFurniture, das über Geo das ganze Spiel lädt)
const COAT_TEX := "res://assets/textures/garden_coat"
const FABRIC_TEX := "res://assets/textures/garden_fabric"
const COAT_METERS := 0.25
const FABRIC_METERS := 0.1
## = Mat.PHOTO_SIZE
const SIZE := 1024
## Pulverlack (sRGB): Farbe, Rauheit, Orangenhaut (Wellenlänge und Höhe in mm), Korn (Höhe in mm)
const COAT := Color(0.2, 0.21, 0.22)
const COAT_ROUGH := 0.58
const PEEL_MM := 1.8
const PEEL_DEPTH := 0.025
const GRAIN_DEPTH := 0.006
## Gewebe: Fäden je Kachel (je Richtung, teilt SIZE), Fadenbreite als Anteil der Teilung, Garnfarbe (sRGB), Spiel je
## Faden, Loch (Farbe), Fadenhöhe in mm, Rauheit Faden und Loch
const THREADS := 64
const THREAD_FILL := 0.74
const YARN := Color(0.45, 0.46, 0.46)
const YARN_SPREAD := 0.08
const HOLE := Color(0.06, 0.06, 0.06)
const THREAD_DEPTH := 0.25
const FABRIC_ROUGH := 0.72
const HOLE_ROUGH := 0.95
const SEED := 5151


func _init() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = SEED
	_coat(rng)
	_fabric(rng)
	quit()


## Pulverlack: Orangenhaut als weiches Rauschen, darüber feines Korn; Farbe und Rauheit folgen leicht der Höhe
func _coat(rng: RandomNumberGenerator) -> void:
	var px_mm := SIZE / (COAT_METERS * 1000.0)
	var peel := _noise(rng, COAT_METERS * 1000.0 / PEEL_MM, 2)
	var grain := _noise(rng, SIZE / 3.0, 1)
	var h := PackedFloat32Array()
	h.resize(SIZE * SIZE)
	var albedo := Image.create(SIZE, SIZE, false, Image.FORMAT_RGB8)
	var rough := Image.create(SIZE, SIZE, false, Image.FORMAT_L8)
	for y in SIZE:
		for x in SIZE:
			var p := peel.get_pixel(x, y).r - 0.5
			var g := grain.get_pixel(x, y).r - 0.5
			h[y * SIZE + x] = p * 2.0 * PEEL_DEPTH + g * 2.0 * GRAIN_DEPTH
			albedo.set_pixel(x, y, COAT.lightened(0.04 * g) if g > 0.0 else COAT.darkened(-0.04 * g))
			var r := COAT_ROUGH + 0.05 * p + 0.04 * g
			rough.set_pixel(x, y, Color(r, r, r))
	_save(albedo, rough, _normal(h, 1.0 / px_mm), COAT_TEX)


## Gewebe: je Zelle (i, j) liegt der Kettfaden i oben, wenn i + j gerade ist, sonst der Schussfaden j. Ein Faden ist im
## Querschnitt rund (Höhe sin), wo er unter den anderen taucht, sinkt er ab. Ohne Faden: Loch.
func _fabric(rng: RandomNumberGenerator) -> void:
	var pitch := SIZE / THREADS
	var px_mm := SIZE / (FABRIC_METERS * 1000.0)
	var warp := PackedFloat32Array()
	var weft := PackedFloat32Array()
	for i in THREADS:
		warp.append(rng.randf_range(-YARN_SPREAD, YARN_SPREAD))
		weft.append(rng.randf_range(-YARN_SPREAD, YARN_SPREAD))
	var h := PackedFloat32Array()
	h.resize(SIZE * SIZE)
	var albedo := Image.create(SIZE, SIZE, false, Image.FORMAT_RGB8)
	var rough := Image.create(SIZE, SIZE, false, Image.FORMAT_L8)
	var half := THREAD_FILL / 2.0
	for y in SIZE:
		var j := y / pitch
		var fy := (float(y % pitch) + 0.5) / pitch - 0.5   # quer zum Schussfaden
		for x in SIZE:
			var i := x / pitch
			var fx := (float(x % pitch) + 0.5) / pitch - 0.5   # quer zum Kettfaden
			var in_warp := absf(fx) < half
			var in_weft := absf(fy) < half
			var warp_up := (i + j) % 2 == 0
			var height := 0.0
			var color := HOLE
			var r := HOLE_ROUGH
			# Querschnitt rund, entlang leicht gewellt (taucht in der Nachbarzelle unter)
			var warp_h := cos(fx / half * PI / 2.0) * (0.75 + 0.25 * cos(fy * PI * 2.0) * (1.0 if warp_up else -1.0))
			var weft_h := cos(fy / half * PI / 2.0) * (0.75 + 0.25 * cos(fx * PI * 2.0) * (-1.0 if warp_up else 1.0))
			var tone := 0.0
			if in_warp and (warp_up or not in_weft):
				height = warp_h
				tone = warp[i]
			elif in_weft:
				height = weft_h
				tone = weft[j]
			if in_warp or in_weft:
				var shade := 0.82 + 0.18 * height   # an den Flanken etwas dunkler
				color = (YARN.lightened(tone) if tone > 0.0 else YARN.darkened(-tone)) * shade
				color.a = 1.0
				r = FABRIC_ROUGH - 0.08 * height
			h[y * SIZE + x] = height * THREAD_DEPTH
			albedo.set_pixel(x, y, color)
			rough.set_pixel(x, y, Color(r, r, r))
	_save(albedo, rough, _normal(h, 1.0 / px_mm), FABRIC_TEX)


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
