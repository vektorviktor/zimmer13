extends SceneTree
## Textur der Spindblöcke in den Umkleiden (LockerBank, ZIM-145): Melamin-Beschichtung der Spanplatten mit feiner
## Perlstruktur, neutral mittelgrau – LockerBank färbt sie anthrazit (Korpus, Regal, Sockel) und weiß (innen). Farbe,
## Normal Map (OpenGL) und Rauheit, nahtlos kachelbar. Fester Zufallsstartwert – gleiche Karten bei jedem Lauf.
##
##   godot --headless --path . -s tools/locker_melamine.gd

## Ausgabe und Kachelgröße in Metern = LockerBank.MELAMINE_TEX, MELAMINE_METERS
const TEX := "res://assets/textures/locker_melamine"
const METERS := 0.2
## = Mat.PHOTO_SIZE
const SIZE := 1024
## Grundton (sRGB, LockerBank tönt), Rauheit, Perlstruktur (Wellenlänge und Höhe in mm), Korn (Höhe in mm)
const BASE := Color(0.5, 0.5, 0.5)
const ROUGH := 0.55
const PEARL_MM := 0.6
const PEARL_DEPTH := 0.012
const GRAIN_DEPTH := 0.004
const SEED := 1451


func _init() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = SEED
	var px_mm := SIZE / (METERS * 1000.0)
	var pearl := _noise(rng, METERS * 1000.0 / PEARL_MM, 2)
	var grain := _noise(rng, SIZE / 3.0, 1)
	var cloud := _noise(rng, 6.0, 3)   # ganz leichte Wolken in der Farbe, wie gepresstes Dekorpapier
	var h := PackedFloat32Array()
	h.resize(SIZE * SIZE)
	var albedo := Image.create(SIZE, SIZE, false, Image.FORMAT_RGB8)
	var rough := Image.create(SIZE, SIZE, false, Image.FORMAT_L8)
	for y in SIZE:
		for x in SIZE:
			var p := pearl.get_pixel(x, y).r - 0.5
			var g := grain.get_pixel(x, y).r - 0.5
			var c := cloud.get_pixel(x, y).r - 0.5
			h[y * SIZE + x] = p * 2.0 * PEARL_DEPTH + g * 2.0 * GRAIN_DEPTH
			var tone := 0.03 * c + 0.02 * g
			albedo.set_pixel(x, y, BASE.lightened(tone) if tone > 0.0 else BASE.darkened(-tone))
			var r := ROUGH + 0.06 * p + 0.03 * g
			rough.set_pixel(x, y, Color(r, r, r))
	albedo.save_png(TEX + ".png")
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
