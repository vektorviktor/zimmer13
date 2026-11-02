extends SceneTree
## Ziffernsatz der Jahres-Plaketten an den Fotorahmen (YearPlaque, ZIM-134): poliertes Gold mit feinen Polierriefen und
## Kratzern, die Ziffern als V-Gravur, dunkel ausgelegt und an den Kanten etwas abgegriffen. Farbe, Normal Map (OpenGL)
## und Rauheit aus einer Höhenkarte in mm; Schmutz sitzt, wo die Höhe unter ihrer Umgebung liegt. Lage der Zellen aus
## YearPlaque.layout(), Rastern, Abstand und Weichzeichnen aus tools/room_plate.gd. Riefen und Anlauf hängen nur von
## der Höhe in der Zelle ab – sonst sähe man, wo zwei Zellen aneinanderstoßen. Fester Zufallsstartwert.
##
##   godot --headless --path . -s tools/year_plaque.gd

const YearPlaque := preload("res://scripts/world/year_plaque.gd")
const Plate := preload("res://tools/room_plate.gd")
const SIZE := YearPlaque.SIZE
## Gravur in mm: Tiefe, Breite der schrägen Wand (V-Stichel)
const DEPTH := 0.12
const WALL := 0.12
const POLISH_DEPTH := 0.0015
## Farben: Gold poliert, angelaufen, Füllung der Gravur, Schmutz
const GOLD := Color(0.93, 0.74, 0.4)
const TARNISH := Color(0.55, 0.4, 0.2)
const FILL := Color(0.05, 0.035, 0.025)
const DIRT := Color(0.1, 0.07, 0.04)
const CAVITY_MM := 0.4
const SEED := 2005


func _init() -> void:
	assert(SIZE == Plate.SIZE, "year_plaque: Satzgröße muss der von room_plate.gd entsprechen (Hilfsfunktionen)")
	var lay := YearPlaque.layout()
	var cells: Dictionary = lay["cells"]
	var glyphs: Dictionary = lay["glyphs"]
	var face: Vector2 = lay["face"]
	var mm := 1.0 / YearPlaque.PX_MM
	var n := SIZE * SIZE
	var names: Array = cells.keys()
	var cell_of := PackedInt32Array()
	cell_of.resize(n)
	cell_of.fill(-1)
	for c in names.size():
		var r: Rect2 = (cells[names[c]] as Rect2).grow(YearPlaque.PAD)
		for y in range(maxi(0, floori(r.position.y / mm)), mini(SIZE, ceili(r.end.y / mm))):
			for x in range(maxi(0, floori(r.position.x / mm)), mini(SIZE, ceili(r.end.x / mm))):
				cell_of[y * SIZE + x] = c
	var cover := PackedFloat32Array()
	cover.resize(n)
	var unused := PackedByteArray()
	unused.resize(n)
	for key: String in names:
		if not glyphs.has(key):
			continue
		var at: Vector2 = (cells[key] as Rect2).position
		var tris: PackedVector2Array = glyphs[key]
		for t in roundi(tris.size() / 3.0):
			Plate._raster(cover, unused, false, at + tris[t * 3], at + tris[t * 3 + 1], at + tris[t * 3 + 2], mm)
	var inside := Plate._distance(cover)
	var polish := FastNoiseLite.new()
	polish.seed = SEED
	polish.frequency = 1.0
	polish.fractal_octaves = 3
	var smudge := FastNoiseLite.new()
	smudge.seed = SEED + 1
	smudge.frequency = 0.25
	smudge.fractal_octaves = 3
	var h := PackedFloat32Array()
	h.resize(n)
	var streak := PackedFloat32Array()
	streak.resize(n)
	var edge := PackedFloat32Array()
	edge.resize(n)
	var grime := PackedFloat32Array()
	grime.resize(n)
	for y in SIZE:
		for x in SIZE:
			var i := y * SIZE + x
			var p := Vector2((x + 0.5) * mm, (y + 0.5) * mm)
			var r: Rect2 = cells[names[cell_of[i]]] if cell_of[i] >= 0 else Rect2(0, 0, SIZE * mm, face.y)
			var local := p - r.position
			var s := clampf(polish.get_noise_1d(local.y * 9.0) * 1.2, -1.0, 1.0)
			streak[i] = s
			edge[i] = minf(local.y, face.y - local.y)
			# Fingerabdrücke und Putzschlieren: nur quer zur Zelle, sonst Nähte an den Zellgrenzen
			grime[i] = clampf(smudge.get_noise_2d(local.y * 3.0, local.y * 1.3) * 0.5 + 0.5, 0.0, 1.0)
			var v := POLISH_DEPTH * s
			if cover[i] > 0.0:
				var t := clampf(inside[i] * mm / WALL, 0.0, 1.0)
				v = lerpf(v, -DEPTH * t, cover[i])
			h[i] = v
	var r_blur := roundi(CAVITY_MM / mm / 2.0)
	var blur := Plate._blur(Plate._blur(h, r_blur), r_blur)
	var albedo := Image.create(SIZE, SIZE, false, Image.FORMAT_RGB8)
	var normal := Image.create(SIZE, SIZE, false, Image.FORMAT_RGB8)
	var rough := Image.create(SIZE, SIZE, false, Image.FORMAT_L8)
	for y in SIZE:
		for x in SIZE:
			var i := y * SIZE + x
			var cav := clampf((blur[i] - h[i]) / 0.06, 0.0, 1.0)
			var tarnish := 0.12 + 0.3 * smoothstep(1.2, 0.0, edge[i]) + 0.12 * grime[i]
			var col := GOLD.lerp(TARNISH, tarnish) * (1.0 + 0.05 * streak[i])
			var rv := 0.16 + 0.12 * tarnish + 0.03 * absf(streak[i]) + 0.08 * grime[i]
			# Füllung: liegt im Boden der Gravur, an der Wand blitzt das Gold durch
			var filled := clampf((inside[i] * mm - WALL * 0.6) / (WALL * 0.5), 0.0, 1.0) * cover[i]
			col = col.lerp(DIRT, pow(cav, 0.8) * 0.7)
			col = col.lerp(FILL, filled)
			rv = lerpf(lerpf(rv, 0.7, cav * 0.6), 0.55, filled)
			albedo.set_pixel(x, y, col)
			rough.set_pixel(x, y, Color(rv, rv, rv))
			var xl := maxi(x - 1, 0)
			var xr := mini(x + 1, SIZE - 1)
			var yu := maxi(y - 1, 0)
			var yd := mini(y + 1, SIZE - 1)
			var dx := (h[y * SIZE + xr] - h[y * SIZE + xl]) / ((xr - xl) * mm)
			var dy := (h[yd * SIZE + x] - h[yu * SIZE + x]) / ((yd - yu) * mm)
			var nv := Vector3(-dx, dy, 1.0).normalized()   # Bildzeile wächst nach unten, Grün = oben
			normal.set_pixel(x, y, Color(nv.x * 0.5 + 0.5, nv.y * 0.5 + 0.5, nv.z * 0.5 + 0.5))
	albedo.save_png(YearPlaque.ALBEDO)
	normal.save_png(YearPlaque.NORMAL)
	rough.save_png(YearPlaque.ROUGH)
	print("%d Zellen, %s" % [names.size(), YearPlaque.ALBEDO])
	quit()
