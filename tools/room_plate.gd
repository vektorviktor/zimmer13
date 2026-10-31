extends SceneTree
## Ziffernsatz der Zimmerplaketten (RoomPlate): Messing gebürstet wie die Lichtschalter, Ziffern erhaben und poliert
## mit runder Kante, Schlitzschrauben, der Abdruck der abgefallenen Null und das Band mit der Kordel für den Rand
## (gedreht wie am Lichtschalter, nur dünner). Farbe, Normal Map (OpenGL) und Rauheit aus
## einer Höhenkarte in mm; Schmutz sitzt, wo die Höhe unter ihrer Umgebung liegt. Lage der Zellen aus
## RoomPlate.layout(). Bürstung und Anlauf hängen nur von der Höhe in der Zelle ab (und feinem Rauschen) – sonst
## sähe man an der Tür, wo zwei Zellen aneinanderstoßen. Fester Zufallsstartwert – gleiche Karten bei jedem Lauf.
##
##   godot --headless --path . -s tools/room_plate.gd

const RoomPlate := preload("res://scripts/world/room_plate.gd")
const SIZE := RoomPlate.SIZE
## Höhen in mm: Ziffer (senkrechter Fuß, darauf die Rundung), Radius der Rundung, Riefen der Bürstung
const H_WALL := 0.3
const H_DOME := 0.6
const R_EDGE := 1.1
const BRUSH_DEPTH := 0.004
## Schrauben: Kopfradius, Schlitzbreite, Schlitzwinkel links und rechts
const SCREW_R := 2.6
const SLOT_W := 0.6
const SLOT_DEG := [-14.0, 31.0]
## Kordel im Band "K" in mm: Abstand vom Außenrand, Breite, Länge eines Strangs, Schräge der Stränge (in Strängen
## über die halbe Breite), Höhe
const ROPE_OUT := 0.3
const ROPE_D := 2.6
const ROPE_PITCH := 1.6
const ROPE_TWIST := 0.75
const ROPE_HEIGHT := 0.7
## Abdruck: Stiftlöcher (Abstand von der Ziffernmitte nach oben und unten, Radius), Breite des Kleberands in mm
const PIN_DY := 12.0
const PIN_R := 0.45
const GLUE := 0.5
## Farben: Messing gebürstet, angelaufen, Ziffern poliert, Schmutz, Schraubenkopf
const BRASS := Color(0.74, 0.57, 0.3)
const PATINA := Color(0.38, 0.27, 0.12)
const GOLD := Color(0.98, 0.8, 0.46)
const DIRT := Color(0.08, 0.055, 0.03)
const SCREW := Color(0.34, 0.22, 0.11)
const CAVITY_MM := 1.0
const SEED := 1313


func _init() -> void:
	var lay := RoomPlate.layout()
	var cells: Dictionary = lay["cells"]
	var glyphs: Dictionary = lay["glyphs"]
	var face: Vector2 = lay["face"]
	var mm := 1.0 / RoomPlate.PX_MM   # mm je Pixel
	var n := SIZE * SIZE
	# Zelle je Pixel (mit Rand): Index in names, -1 = frei
	var names: Array = cells.keys()
	var cell_of := PackedInt32Array()
	cell_of.resize(n)
	cell_of.fill(-1)
	for c in names.size():
		var r: Rect2 = (cells[names[c]] as Rect2).grow(RoomPlate.PAD)
		for y in range(maxi(0, floori(r.position.y / mm)), mini(SIZE, ceili(r.end.y / mm))):
			for x in range(maxi(0, floori(r.position.x / mm)), mini(SIZE, ceili(r.end.x / mm))):
				cell_of[y * SIZE + x] = c
	# Tinte der Ziffern und Abdrücke: Deckung je Pixel (2 × 2 Abtastpunkte)
	var cover := PackedFloat32Array()
	cover.resize(n)
	var ghost := PackedByteArray()
	ghost.resize(n)
	for key: String in names:
		var d := key.substr(1) if key.begins_with("g") else key
		if not glyphs.has(d):
			continue
		var at: Vector2 = (cells[key] as Rect2).position
		var tris: PackedVector2Array = glyphs[d]
		for t in roundi(tris.size() / 3.0):
			_raster(cover, ghost, key.begins_with("g"), at + tris[t * 3], at + tris[t * 3 + 1], at + tris[t * 3 + 2], mm)
	var inside := _distance(cover)
	var brush := FastNoiseLite.new()
	brush.seed = SEED
	brush.frequency = 1.0
	brush.fractal_octaves = 2
	var fine := FastNoiseLite.new()
	fine.seed = SEED + 1
	fine.frequency = 1.0
	var h := PackedFloat32Array()
	h.resize(n)
	var kind := PackedByteArray()   # 0 Messing, 1 Ziffer, 2 Schraube, 3 Abdruck innen, 4 Kleberand
	kind.resize(n)
	var streak := PackedFloat32Array()
	streak.resize(n)
	var edge := PackedFloat32Array()
	edge.resize(n)
	for y in SIZE:
		for x in SIZE:
			var i := y * SIZE + x
			var p := Vector2((x + 0.5) * mm, (y + 0.5) * mm)
			var key: String = names[cell_of[i]] if cell_of[i] >= 0 else ""
			var r: Rect2 = cells[key] if key != "" else Rect2(0, 0, SIZE * mm, face.y)
			var local := p - r.position
			var s := clampf(brush.get_noise_1d(local.y * 6.0) * 1.1 + fine.get_noise_2d(p.x * 0.5, local.y * 6.0) * 0.6, -1.0, 1.0)
			streak[i] = s
			# Abstand zum Plattenrand: oben, unten, an den Schraubenzellen außen
			var e := minf(local.y, face.y - local.y)
			if key == "L":
				e = minf(e, local.x)
			elif key == "R":
				e = minf(e, r.size.x - local.x)
			elif key == "K":   # um die Kordel dunkelt der Schmutz in den Rillen
				e = 10.0
			edge[i] = e
			var v := BRUSH_DEPTH * s
			if key == "K":
				var d := (local.y - ROPE_OUT - ROPE_D / 2.0) / (ROPE_D / 2.0)   # quer: -1 außen … 1 innen
				if absf(d) < 1.0:
					var u := fposmod(local.x / ROPE_PITCH + asin(d) / (PI / 2.0) * ROPE_TWIST, 1.0)
					var bump := sqrt(maxf(0.0, 1.0 - pow(2.0 * u - 1.0, 2.0)))
					v = ROPE_HEIGHT * sqrt(1.0 - d * d) * (0.3 + 0.7 * bump)
					kind[i] = 5
			if cover[i] > 0.0 and not ghost[i]:
				var t := clampf((inside[i] - 0.5) * mm / R_EDGE, 0.0, 1.0)
				v = lerpf(v, H_WALL + H_DOME * sqrt(1.0 - pow(1.0 - t, 2.0)), cover[i])
				kind[i] = 1
			elif ghost[i]:
				kind[i] = 3 if inside[i] * mm > GLUE else 4
			if key == "L" or key == "R":
				var c := Vector2(RoomPlate.SCREW_X if key == "L" else r.size.x - RoomPlate.SCREW_X, face.y / 2.0)
				var rr := local.distance_to(c)
				if rr < SCREW_R + 0.25:
					kind[i] = 2
					v = -0.15
					if rr < SCREW_R:
						var q := (local - c).rotated(-deg_to_rad(SLOT_DEG[0 if key == "L" else 1]))
						v = 0.05 + 0.5 * sqrt(1.0 - pow(rr / SCREW_R, 2.0))
						if absf(q.y) < SLOT_W / 2.0 and absf(q.x) < SCREW_R * 0.92:
							v = -0.2
			if key.begins_with("g"):   # Stiftlöcher der abgefallenen Ziffer
				for sy in [-1.0, 1.0]:
					if local.distance_to(Vector2(r.size.x / 2.0, face.y / 2.0 + sy * PIN_DY)) < PIN_R:
						v = -0.4
						kind[i] = 4
			h[i] = v
	var r_blur := roundi(CAVITY_MM / mm / 2.0)
	var blur := _blur(_blur(h, r_blur), r_blur)
	var albedo := Image.create(SIZE, SIZE, false, Image.FORMAT_RGB8)
	var normal := Image.create(SIZE, SIZE, false, Image.FORMAT_RGB8)
	var rough := Image.create(SIZE, SIZE, false, Image.FORMAT_L8)
	for y in SIZE:
		for x in SIZE:
			var i := y * SIZE + x
			var cav := clampf((blur[i] - h[i]) / 0.25, 0.0, 1.0)
			var tarnish := 0.38 + 0.35 * smoothstep(5.0, 0.0, edge[i]) + 0.08 * absf(streak[i])
			var col := BRASS.lerp(PATINA, tarnish) * (1.0 + 0.12 * streak[i])
			var rv := 0.38 + 0.12 * tarnish + 0.06 * absf(streak[i])
			match kind[i]:
				1:   # polierte Ziffer, zur Rundung hin heller
					col = col.lerp(GOLD, cover[i])
					rv = lerpf(rv, 0.1, cover[i])
				2:
					col = SCREW * (1.0 + 0.3 * streak[i])
					rv = 0.5
				3:   # geschützt unter der Ziffer: etwas blanker als die Platte – ein Schatten, keine Ziffer
					col = col.lerp(BRASS, 0.3)
					rv -= 0.06
				5:   # Kordel: blanker als die Platte, wo sie oben abgegriffen ist
					col = BRASS.lerp(PATINA, 0.3) * (1.0 + 0.1 * clampf((h[i] - blur[i]) / 0.2, 0.0, 1.0))
					rv = 0.3
				4:   # Kleberand und Stiftlöcher
					col = col.lerp(DIRT, 0.3)
					rv = lerpf(rv, 0.8, 0.5)
			col = col.lerp(DIRT, pow(cav, 0.8) * 0.85)
			rv = lerpf(rv, 0.85, cav)
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
	albedo.save_png(RoomPlate.ALBEDO)
	normal.save_png(RoomPlate.NORMAL)
	rough.save_png(RoomPlate.ROUGH)
	print("%d Zellen, %s" % [names.size(), RoomPlate.ALBEDO])
	quit()


## Dreieck a b c (mm) in die Deckung, 2 × 2 Abtastpunkte je Pixel; is_ghost markiert den Abdruck
static func _raster(cover: PackedFloat32Array, ghost: PackedByteArray, is_ghost: bool, a: Vector2, b: Vector2,
		c: Vector2, mm: float) -> void:
	var lo := Vector2(minf(a.x, minf(b.x, c.x)), minf(a.y, minf(b.y, c.y))) / mm
	var hi := Vector2(maxf(a.x, maxf(b.x, c.x)), maxf(a.y, maxf(b.y, c.y))) / mm
	var area := (b - a).cross(c - a)
	if absf(area) < 1e-9:
		return
	for y in range(maxi(0, floori(lo.y)), mini(SIZE, ceili(hi.y))):
		for x in range(maxi(0, floori(lo.x)), mini(SIZE, ceili(hi.x))):
			var hits := 0
			for s in 4:
				var p := Vector2(x + 0.25 + 0.5 * (s % 2), y + 0.25 + 0.5 * (s >> 1)) * mm
				var w0 := (b - a).cross(p - a) / area
				var w1 := (c - b).cross(p - b) / area
				var w2 := (a - c).cross(p - c) / area
				if w0 >= 0.0 and w1 >= 0.0 and w2 >= 0.0:
					hits += 1
			if hits > 0:
				var i := y * SIZE + x
				cover[i] = minf(1.0, cover[i] + hits * 0.25)
				if is_ghost:
					ghost[i] = 1


## Abstand in Pixeln vom Rand der Tinte nach innen (Deckung ≥ ½), Fasenabstand 1 / √2 in zwei Durchläufen
static func _distance(cover: PackedFloat32Array) -> PackedFloat32Array:
	var d := PackedFloat32Array()
	d.resize(cover.size())
	for i in cover.size():
		d[i] = 1e6 if cover[i] >= 0.5 else 0.0
	var diag := sqrt(2.0)
	for y in SIZE:
		for x in SIZE:
			var i := y * SIZE + x
			if d[i] == 0.0:
				continue
			var v := d[i]
			if x > 0:
				v = minf(v, d[i - 1] + 1.0)
			if y > 0:
				v = minf(v, d[i - SIZE] + 1.0)
				if x > 0:
					v = minf(v, d[i - SIZE - 1] + diag)
				if x < SIZE - 1:
					v = minf(v, d[i - SIZE + 1] + diag)
			d[i] = v
	for y in range(SIZE - 1, -1, -1):
		for x in range(SIZE - 1, -1, -1):
			var i := y * SIZE + x
			if d[i] == 0.0:
				continue
			var v := d[i]
			if x < SIZE - 1:
				v = minf(v, d[i + 1] + 1.0)
			if y < SIZE - 1:
				v = minf(v, d[i + SIZE] + 1.0)
				if x < SIZE - 1:
					v = minf(v, d[i + SIZE + 1] + diag)
				if x > 0:
					v = minf(v, d[i + SIZE - 1] + diag)
			d[i] = v
	return d


## Kastenfilter, je Achse getrennt (gleitende Summe), Radius r Pixel, am Rand gekappt
static func _blur(src: PackedFloat32Array, r: int) -> PackedFloat32Array:
	return _blur_pass(_blur_pass(src, r, 1, SIZE), r, SIZE, 1)


## Eine Richtung: step = Abstand zweier Pixel entlang der Linie, line_step = Abstand zweier Linien
static func _blur_pass(src: PackedFloat32Array, r: int, step: int, line_step: int) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	out.resize(src.size())
	for line in SIZE:
		var base := line * line_step
		var sum := 0.0
		for j in mini(r, SIZE - 1) + 1:
			sum += src[base + j * step]
		for k in SIZE:
			out[base + k * step] = sum / (mini(k + r, SIZE - 1) - maxi(k - r, 0) + 1)
			if k + r + 1 < SIZE:
				sum += src[base + (k + r + 1) * step]
			if k - r >= 0:
				sum -= src[base + (k - r) * step]
	return out
