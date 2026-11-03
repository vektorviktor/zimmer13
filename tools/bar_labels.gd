extends SceneTree
## Etiketten der Flaschen an der Bar (BarDrinks, Spielkonzept 3.7, ZIM-35): ein Atlas mit drei Zeilen – Rotwein (oben),
## Bier, Schnaps (Korn) – je ROW_W × ROW_H Pixel (Seitenverhältnis wie das Etikett auf der Flasche, BarDrinks.LABEL).
## Bedrucktes Papier: Fasern, leichte Vergilbung und angegriffene Ränder in der Farbe; Schrift in Cinzel Bold (die
## Schrift des Spiels, assets/fonts, OFL) über FreeType gerastert; Rahmen, Medaillon und Ähre in geprägter Goldfolie
## (Metall im Blau der ORM-Karte, erhaben in der Normal Map). Karten wie Mat.pbr_model: <TEX>_albedo.png, _normal.png
## (OpenGL), _orm.png (R Verdeckung, G Rauheit, B Metall). Fester Zufallsstartwert – gleiche Karten bei jedem Lauf.
##
##   godot --headless --path . -s tools/bar_labels.gd

const TEX := "res://assets/textures/bar_labels"
const FONT := "res://assets/fonts/cinzel_bold.ttf"
const ROW_W := 1024
const ROW_H := 640
const ROWS := ["wein", "bier", "schnaps"]
## Etikett in mm (Breite ringsum, Höhe) – für Prägung, Schriftgröße und Papierkorn
const LABEL_MM := Vector2(140.0, 88.0)
## Großbuchstaben von Cinzel: so hoch im Verhältnis zur Schriftgröße
const CAP := 0.7
const SEED := 3511

const PAPER := Color(0.88, 0.84, 0.74)
const PAPER_WHITE := Color(0.93, 0.92, 0.88)
const BURGUNDY := Color(0.36, 0.05, 0.08)
const BEER_RED := Color(0.62, 0.09, 0.06)
const PINE := Color(0.1, 0.3, 0.17)
const INK := Color(0.08, 0.07, 0.07)
const GOLD := Color(0.83, 0.66, 0.32)

## Schrift je Sorte: Text, Mitte (Anteil der Zeile), Höhe der Großbuchstaben (mm), Laufweite (Anteil der Schriftgröße),
## Farbe – null = Goldfolie
const TEXTS := {
	"wein": [
		["WEINGUT ASCHENBACH", Vector2(0.5, 0.115), 3.6, 0.12, null],
		["SPÄTBURGUNDER", Vector2(0.5, 0.69), 7.5, 0.04, BURGUNDY],
		["ROTWEIN · TROCKEN", Vector2(0.5, 0.8), 2.8, 0.1, INK],
		["1987", Vector2(0.5, 0.88), 3.2, 0.15, null],
	],
	"bier": [
		["KRÄHENBRÄU", Vector2(0.5, 0.505), 9.0, 0.05, PAPER_WHITE],
		["BRAUEREI SEIT 1874", Vector2(0.5, 0.31), 2.6, 0.12, INK],
		["PILSENER · 0,33 L", Vector2(0.5, 0.76), 3.0, 0.1, INK],
		["UNTERGÄRIG GEBRAUT", Vector2(0.5, 0.84), 2.2, 0.1, INK],
	],
	"schnaps": [
		["KORN", Vector2(0.5, 0.6), 13.0, 0.12, INK],
		["BRENNEREI MOORHOF", Vector2(0.5, 0.43), 2.8, 0.12, PINE],
		["DOPPELKORN · 38 % VOL", Vector2(0.5, 0.82), 2.8, 0.08, INK],
	],
}

var _fiber: FastNoiseLite
var _stain: FastNoiseLite
var _font: FontFile


func _init() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = SEED
	_fiber = FastNoiseLite.new()
	_fiber.seed = rng.randi()
	_fiber.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_fiber.frequency = 0.09
	_fiber.fractal_octaves = 3
	_stain = FastNoiseLite.new()
	_stain.seed = rng.randi()
	_stain.frequency = 0.004
	_stain.fractal_octaves = 4
	_font = FontFile.new()
	_font.load_dynamic_font(ProjectSettings.globalize_path(FONT))
	var h_total := ROW_H * ROWS.size()
	var albedo := Image.create(ROW_W, h_total, false, Image.FORMAT_RGB8)
	var orm := Image.create(ROW_W, h_total, false, Image.FORMAT_RGB8)
	var height := PackedFloat32Array()
	height.resize(ROW_W * h_total)
	for r in ROWS.size():
		var texts: Array = []
		for t in TEXTS[ROWS[r]]:
			texts.append([_text_mask(t[0], t[1], t[2], t[3]), t[4]])
		for y in ROW_H:
			for x in ROW_W:
				var px := Vector2i(x, r * ROW_H + y)
				var s := _shade(ROWS[r], Vector2((x + 0.5) / ROW_W, (y + 0.5) / ROW_H), px)
				var fiber := float(s["fiber"])
				for t in texts:
					var a: float = (t[0] as PackedFloat32Array)[y * ROW_W + x]
					if t[1] == null:
						_foil(s, a, fiber)
					else:
						_ink(s, t[1], a)
				albedo.set_pixelv(px, s["color"])
				orm.set_pixelv(px, Color(1.0, s["rough"], s["metal"]))
				height[px.y * ROW_W + px.x] = s["height"]
	albedo.save_png(TEX + "_albedo.png")
	orm.save_png(TEX + "_orm.png")
	_normal(height, h_total, LABEL_MM.x / ROW_W).save_png(TEX + "_normal.png")
	print(TEX)
	quit()


## Papier, Bänder, Rahmen und Bildmarken eines Texels: Farbe, Höhe (mm), Rauheit, Metall. uv: 0..1 in der Zeile (v nach
## unten), px: Pixel im Atlas.
func _shade(sort: String, uv: Vector2, px: Vector2i) -> Dictionary:
	var fiber := _fiber.get_noise_2dv(Vector2(px)) * 0.5 + 0.5
	var stain := _stain.get_noise_2dv(Vector2(px)) * 0.5 + 0.5
	var base := PAPER_WHITE if sort == "schnaps" else PAPER
	var color := base.darkened(0.05 * fiber + 0.08 * maxf(0.0, stain - 0.55))
	var edge := minf(minf(uv.x, 1.0 - uv.x) * LABEL_MM.x, minf(uv.y, 1.0 - uv.y) * LABEL_MM.y)   # mm bis zum Rand
	color = color.darkened(0.12 * clampf(1.0 - edge / 6.0, 0.0, 1.0))   # Ränder etwas angegriffen
	var out := {"color": color, "height": fiber * 0.015, "rough": 0.78 + 0.1 * fiber, "metal": 0.0, "fiber": fiber}
	var mm := Vector2(uv.x * LABEL_MM.x, uv.y * LABEL_MM.y)
	match sort:
		"wein":
			_ink(out, BURGUNDY, _band(uv.y, 0.0, 0.16))
			_foil(out, _band(uv.y, 0.175, 0.19), fiber)
			_foil(out, _frame(edge, 4.0, 0.9), fiber)
			_foil(out, _frame(edge, 6.0, 0.4), fiber)
			var c := Vector2(LABEL_MM.x * 0.5, LABEL_MM.y * 0.42)
			var ring := absf(_ellipse(mm, c, Vector2(15.0, 13.0)) - 1.0) * 14.0
			_foil(out, clampf(1.6 - ring, 0.0, 1.0), fiber)
			for g in [Vector2(-4, -4), Vector2(0, -4), Vector2(4, -4), Vector2(-2, 0), Vector2(2, 0), Vector2(0, 4)]:
				_ink(out, BURGUNDY, _disc(mm, c + g * 1.15, 2.2))   # Traube im Medaillon
			_foil(out, _disc(mm, c + Vector2(1.5, -9.5), 1.2), fiber)   # Stiel
		"bier":
			_foil(out, _frame(edge, 3.0, 0.8), fiber)
			_ink(out, BEER_RED, _band(uv.y, 0.36, 0.64))
			_foil(out, _band(uv.y, 0.34, 0.355) + _band(uv.y, 0.645, 0.66), fiber)
			var crest := Vector2(LABEL_MM.x * 0.5, LABEL_MM.y * 0.17)
			_foil(out, clampf(1.6 - absf(_ellipse(mm, crest, Vector2(9.0, 6.5)) - 1.0) * 10.0, 0.0, 1.0), fiber)
			_ink(out, BEER_RED, _disc(mm, crest, 3.0))
		"schnaps":
			_ink(out, PINE, _frame(edge, 2.5, 3.0))
			_ink(out, PINE, _frame(edge, 7.0, 0.6))
			var ear := Vector2(LABEL_MM.x * 0.5, LABEL_MM.y * 0.22)
			for i in 5:
				for side in [-1.0, 1.0]:
					var at := ear + Vector2(side * 2.2, -7.0 + i * 3.2)
					var e := _ellipse(mm, at, Vector2(1.4, 2.2))
					_foil(out, clampf((1.0 - e) * 6.0 + 0.5, 0.0, 1.0), fiber)   # Körner der Ähre
			_foil(out, float(absf(mm.x - ear.x) < 0.45 and mm.y > ear.y - 8.0 and mm.y < ear.y + 10.0), fiber)   # Halm
			_ink(out, PINE, _band(uv.y, 0.73, 0.745) * float(uv.x > 0.3 and uv.x < 0.7))
	return out


## Druckfarbe deckt das Papier (amount 0..1), Fasern scheinen leicht durch, matt wie das Papier
func _ink(out: Dictionary, ink: Color, amount: float) -> void:
	if amount <= 0.0:
		return
	out["color"] = (out["color"] as Color).lerp(ink.darkened(0.04 * float(out["fiber"])), clampf(amount, 0.0, 1.0) * 0.96)
	out["height"] = float(out["height"]) + 0.005 * amount


## Geprägte Goldfolie: metallisch, glatter, erhaben; in den Fasern leicht gebrochen
func _foil(out: Dictionary, amount: float, fiber: float) -> void:
	var a := clampf(amount, 0.0, 1.0)
	if a <= 0.0:
		return
	out["color"] = (out["color"] as Color).lerp(GOLD.darkened(0.15 * fiber), a)
	out["metal"] = lerpf(float(out["metal"]), 0.9, a)
	out["rough"] = lerpf(float(out["rough"]), 0.28 + 0.12 * fiber, a)
	out["height"] = float(out["height"]) + 0.06 * a


## Waagrechtes Band zwischen v0 und v1 (weiche Kante ~1 px)
func _band(v: float, v0: float, v1: float) -> float:
	var px := 1.0 / ROW_H
	return clampf(minf(v - v0, v1 - v) / px + 0.5, 0.0, 1.0)


## Rahmenlinie inset mm vom Rand, width mm breit
func _frame(edge: float, inset: float, width: float) -> float:
	var px := LABEL_MM.x / ROW_W
	return clampf((width * 0.5 - absf(edge - inset - width * 0.5)) / px + 0.5, 0.0, 1.0)


## Ellipsenmaß: < 1 innen, 1 auf dem Rand
func _ellipse(mm: Vector2, c: Vector2, r: Vector2) -> float:
	return ((mm - c) / r).length()


func _disc(mm: Vector2, c: Vector2, r: float) -> float:
	var px := LABEL_MM.x / ROW_W
	return clampf((r - mm.distance_to(c)) / px + 0.5, 0.0, 1.0)


## Deckung einer Schriftzeile (0..1 je Pixel der Zeile): mittig um at (Anteil), Großbuchstaben cap_mm hoch, Laufweite
## tracking (Anteil der Schriftgröße zusätzlich je Zeichen).
func _text_mask(text: String, at: Vector2, cap_mm: float, tracking: float) -> PackedFloat32Array:
	var mask := PackedFloat32Array()
	mask.resize(ROW_W * ROW_H)
	var px_mm := ROW_W / LABEL_MM.x
	var size := int(round(cap_mm * px_mm / CAP))
	var key := Vector2i(size, 0)
	var glyphs: Array[int] = []
	var width := 0.0
	for i in text.length():
		var g := _font.get_glyph_index(size, text.unicode_at(i), 0)
		_font.render_glyph(0, key, g)
		glyphs.append(g)
		width += _font.get_glyph_advance(0, size, g).x + (size * tracking if i < text.length() - 1 else 0.0)
	var pen := Vector2(at.x * ROW_W - width / 2.0, at.y * ROW_H + cap_mm * px_mm / 2.0)   # Grundlinie
	for g in glyphs:
		var tex_i := _font.get_glyph_texture_idx(0, key, g)
		if tex_i >= 0:
			var img := _font.get_texture_image(0, key, tex_i)
			var uv := _font.get_glyph_uv_rect(0, key, g)
			var off := _font.get_glyph_offset(0, key, g)
			var la := img.get_format() in [Image.FORMAT_LA8, Image.FORMAT_RGBA8]
			for y in int(uv.size.y):
				for x in int(uv.size.x):
					var c := img.get_pixel(int(uv.position.x) + x, int(uv.position.y) + y)
					var dst := Vector2i(int(round(pen.x + off.x)) + x, int(round(pen.y + off.y)) + y)
					if dst.x >= 0 and dst.x < ROW_W and dst.y >= 0 and dst.y < ROW_H:
						var i := dst.y * ROW_W + dst.x
						mask[i] = maxf(mask[i], c.a if la else c.r)
		pen.x += _font.get_glyph_advance(0, size, g).x + size * tracking
	return mask


## Normal Map (OpenGL) aus der Höhe in mm (mm_px = mm je Pixel); an den Rändern nicht gekachelt
func _normal(h: PackedFloat32Array, rows: int, mm_px: float) -> Image:
	var img := Image.create(ROW_W, rows, false, Image.FORMAT_RGB8)
	for y in rows:
		for x in ROW_W:
			var dx := (h[y * ROW_W + mini(x + 1, ROW_W - 1)] - h[y * ROW_W + maxi(x - 1, 0)]) / (2.0 * mm_px)
			var dy := (h[mini(y + 1, rows - 1) * ROW_W + x] - h[maxi(y - 1, 0) * ROW_W + x]) / (2.0 * mm_px)
			var n := Vector3(-dx, dy, 1.0).normalized()   # Bildzeile wächst nach unten, Grün = oben
			img.set_pixel(x, y, Color(n.x * 0.5 + 0.5, n.y * 0.5 + 0.5, n.z * 0.5 + 0.5))
	return img
