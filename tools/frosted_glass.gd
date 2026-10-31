extends SceneTree
## Oberfläche des Milchglases (Mat.frosted_glass, Milchglastüren am Pool, ZIM-143): satiniertes Glas – feine, dichte
## Ätzkörnung, darüber ganz flache Wellen wie vom Walzen. Normal Map (OpenGL) und Rauheit, nahtlos kachelbar; die
## Farbe setzt Mat.frosted_glass. Fester Zufallsstartwert – gleiche Karten bei jedem Lauf.
##
##   godot --headless --path . -s tools/frosted_glass.gd

## Ausgabe und Kachelgröße in Metern = Mat.FROSTED_TEX, FROSTED_METERS
const TEX := "res://assets/textures/frosted_glass"
const METERS := 0.12
## = Mat.PHOTO_SIZE
const SIZE := 1024
## Rauheit, Körnung (Wellenlänge und Höhe in mm), Walzwellen (Wellenlänge und Höhe in mm)
const ROUGH := 0.42
const GRAIN_MM := 0.35
const GRAIN_DEPTH := 0.02
const WAVE_MM := 30.0
const WAVE_DEPTH := 0.25
const SEED := 1431


func _init() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = SEED
	var px_mm := SIZE / (METERS * 1000.0)
	var grain := _noise(rng, METERS * 1000.0 / GRAIN_MM, 2)
	var wave := _noise(rng, METERS * 1000.0 / WAVE_MM, 2)
	var patch := _noise(rng, 5.0, 3)   # ungleichmäßig geätzt: Flecken etwas glatter oder stumpfer
	var h := PackedFloat32Array()
	h.resize(SIZE * SIZE)
	var rough := Image.create(SIZE, SIZE, false, Image.FORMAT_L8)
	for y in SIZE:
		for x in SIZE:
			var g := grain.get_pixel(x, y).r - 0.5
			var w := wave.get_pixel(x, y).r - 0.5
			var p := patch.get_pixel(x, y).r - 0.5
			h[y * SIZE + x] = g * 2.0 * GRAIN_DEPTH + w * 2.0 * WAVE_DEPTH
			var r := ROUGH + 0.08 * p + 0.05 * g
			rough.set_pixel(x, y, Color(r, r, r))
	_normal(h, 1.0 / px_mm).save_png(TEX + "_normal.png")
	rough.save_png(TEX + "_rough.png")
	print(TEX)
	quit()


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
