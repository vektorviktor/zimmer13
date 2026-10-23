extends SceneTree
## Färbt das Farbbild eines Fliesensets um (Badfliesen 23.10.: beige Variante der Poolfliesen Tiles_06). Helligkeit
## und die Unterschiede von Fliese zu Fliese bleiben, der Farbton wird zum Zielton; aus dem alten Farbton (grünlich ↔
## bläulich) wird ein leichtes Wärmer/Kühler, damit nicht alle Fliesen gleich aussehen. Fugen (kaum gesättigt)
## bleiben neutral hellgrau – Fuge ist, was nahe einer Rasterlinie (TILES × TILES Fliesen im Bild) und kaum gesättigt
## ist. Normal Map und Rauheit des Sets passen weiter.
##
##   godot --headless --path . -s tools/tint_tiles.gd -- assets/textures/pool/Tiles_06_basecolor.jpg assets/textures/pool/Tiles_06_beige_basecolor.jpg

## Beige bei mittlerer Helligkeit; mittlere Helligkeit der Fliesen danach und wie viel ihrer Helligkeitsunterschiede
## bleibt; wie stark grün/blau zu wärmer/kühler wird; Helligkeit der Fugen
const TARGET := Color(0.86, 0.77, 0.62)
const LIGHTNESS := 0.78
const CONTRAST := 0.6
const WARMTH := 0.35
const GROUT := 0.82
const JPG_QUALITY := 0.92
## Fliesen je Bildkante; so viele Pixel um eine Rasterlinie können Fuge sein
const TILES := 6
const GROUT_BAND := 8


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var img := Image.load_from_file(ProjectSettings.globalize_path("res://" + args[0]))
	img.convert(Image.FORMAT_RGB8)
	var w := img.get_width()
	var h := img.get_height()
	# Mittlere Helligkeit von Fliesen und Fugen
	var sums := [0.0, 0.0]
	var counts := [0, 0]
	for y in h:
		for x in w:
			var c := img.get_pixel(x, y)
			var t := _tile(c, x, y, w)
			if t > 0.9:
				sums[0] += c.get_luminance()
				counts[0] += 1
			elif t < 0.1:
				sums[1] += c.get_luminance()
				counts[1] += 1
	var tile_mean: float = sums[0] / maxi(counts[0], 1)
	var grout_mean: float = sums[1] / maxi(counts[1], 1)
	var target_mean := (TARGET.r + TARGET.g + TARGET.b) / 3.0
	for y in h:
		for x in w:
			var c := img.get_pixel(x, y)
			var lum := c.get_luminance()
			var green := c.g - c.b   # > 0 grünlich, < 0 bläulich
			var shade := (1.0 + (lum / tile_mean - 1.0) * CONTRAST) * LIGHTNESS / target_mean
			var tile := Color(TARGET.r + WARMTH * green, TARGET.g + WARMTH * green * 0.3, TARGET.b - WARMTH * green) * shade
			var g := lum / grout_mean * GROUT
			var grout := Color(g, g * 0.99, g * 0.96)
			var out := grout.lerp(tile, _tile(c, x, y, w))
			img.set_pixel(x, y, Color(clampf(out.r, 0, 1), clampf(out.g, 0, 1), clampf(out.b, 0, 1)))
	img.save_jpg(ProjectSettings.globalize_path("res://" + args[1]), JPG_QUALITY)
	print("%s: Fliesen %.2f → %.2f, Fugen %.2f → %.2f" % [args[1], tile_mean, LIGHTNESS, grout_mean, GROUT])
	quit()


## 0 = Fuge, 1 = Fliese: nahe einer Rasterlinie nach der Sättigung, sonst immer Fliese
static func _tile(c: Color, x: int, y: int, size: int) -> float:
	var pitch := float(size) / TILES
	var near := func(v: int) -> bool: return absf(v - roundf(v / pitch) * pitch) < GROUT_BAND
	if not (near.call(x) or near.call(y)):
		return 1.0
	return clampf((c.s - 0.06) / 0.1, 0.0, 1.0)
