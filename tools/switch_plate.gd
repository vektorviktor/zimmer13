extends SceneTree
## Messingplatte der Lichtschalter (LightSwitch): Altmessing, gebürstet, mit dunkler Patina, Kordelrand, Rille ums
## Feld und zwei Schlitzschrauben. Farbe, Normal Map (OpenGL) und Rauheit entstehen aus einer Höhenkarte in mm;
## Schmutz sitzt, wo die Höhe unter ihrer Umgebung liegt, abgegriffen blank ist, was darüber liegt. Fester
## Zufallsstartwert – gleiche Karten bei jedem Lauf.
##
##   godot --headless --path . -s tools/switch_plate.gd
##       schreibt OUT_*; im Spiel über die UVs der Platte gespannt (LightSwitch.PLATE)

const OUT_ALBEDO := "res://assets/textures/switch_plate.png"
const OUT_NORMAL := "res://assets/textures/switch_plate_normal.png"
const OUT_ROUGH := "res://assets/textures/switch_plate_rough.png"
## = Mat.PHOTO_SIZE
const SIZE := 1024
## Kantenlänge der Platte in mm (= LightSwitch.PLATE)
const PLATE_MM := 86.0
## Abstand vom Rand in mm: Fase außen bis, schmaler Rand bis, Kordel bis, Rille bis (dann das Feld)
const EDGE := 0.8
const BEVEL := 2.0
const ROPE := 7.6
const GROOVE := 9.2
## Kordel: Länge eines Strangs entlang des Rands in mm (passend gerundet), Schräge der Stränge (in Strängen über die
## halbe Breite; zum Rand hin laufen sie längs wie eine Schraubenlinie von oben), Höhe in mm, Eckradius der Mittellinie
const ROPE_PITCH := 3.0
const ROPE_TWIST := 0.75
const ROPE_HEIGHT := 1.3
const ROPE_CORNER := 4.0
## Höhen in mm: Grund unter der Kordel, Rille, Feld
const H_BASE := 0.8
const H_GROOVE := 0.4
const H_FIELD := 1.2
## Bürstung: Tiefe der Riefen in mm
const BRUSH_DEPTH := 0.004
## Schrauben: Mitte (x in mm von der Plattenmitte), Kopfradius, Schlitzbreite, Schlitzwinkel in Grad je Schraube
const SCREW_X := 24.0
const SCREW_R := 2.8
const SLOT_W := 0.6
const SLOT_DEG := [-12.0, 7.0]
## Farben: Messing blank, Messing unter Patina, Schmutz in den Vertiefungen, Schraubenkopf (dunkel angelaufen)
const BRASS := Color(0.74, 0.57, 0.3)
const PATINA := Color(0.32, 0.23, 0.1)
const DIRT := Color(0.08, 0.055, 0.03)
const SCREW := Color(0.25, 0.15, 0.09)
## Umgebung in mm, gegen die Vertiefungen und Kanten gemessen werden
const CAVITY_MM := 1.0
const SEED := 1313


func _init() -> void:
	var mm := PLATE_MM / SIZE   # mm je Pixel
	var half := PLATE_MM / 2.0
	var patina := FastNoiseLite.new()
	patina.seed = SEED
	patina.frequency = 0.05
	patina.fractal_octaves = 4
	var brush := FastNoiseLite.new()
	brush.seed = SEED + 1
	brush.frequency = 1.0
	brush.fractal_octaves = 2
	# Mittellinie der Kordel: Quadrat mit runden Ecken, a = halbe gerade Strecke, Umfang → ganze Zahl Stränge
	var rope_w := (ROPE - BEVEL) / 2.0
	var a := half - (ROPE + BEVEL) / 2.0 - ROPE_CORNER
	var arc := PI / 2.0 * ROPE_CORNER
	var strands := roundi((8.0 * a + 4.0 * arc) / ROPE_PITCH)
	var pitch := (8.0 * a + 4.0 * arc) / strands
	var n := SIZE * SIZE
	var h := PackedFloat32Array()
	h.resize(n)
	var screw := PackedByteArray()
	screw.resize(n)
	var pat := PackedFloat32Array()
	pat.resize(n)
	var streak := PackedFloat32Array()
	streak.resize(n)
	for y in SIZE:
		for x in SIZE:
			var i := y * SIZE + x
			var p := Vector2((x + 0.5) * mm - half, (y + 0.5) * mm - half)
			var e := -_box_sdf(p, half, 1.0)   # vom Außenrand nach innen
			var d := _box_sdf(p, a + ROPE_CORNER, ROPE_CORNER) / rope_w   # quer zur Kordel, -1 innen … 1 außen
			var field := _box_sdf(p, half - GROOVE, 2.0)
			var s := _streak(brush, p)
			streak[i] = s
			pat[i] = patina.get_noise_2d(p.x * 1.4, p.y * 0.45) * 0.5 + 0.5   # Schleier in Bürstrichtung gezogen
			var v := H_BASE * _round_edge(clampf(e / EDGE, 0.0, 1.0))
			if absf(d) < 1.0:
				var u := fposmod(_perimeter(p, a, arc) / pitch + asin(d) / (PI / 2.0) * ROPE_TWIST, 1.0)
				var bump := sqrt(maxf(0.0, 1.0 - pow(2.0 * u - 1.0, 2.0)))
				v = H_BASE + ROPE_HEIGHT * sqrt(1.0 - d * d) * (0.25 + 0.75 * bump)
			elif d <= -1.0:
				v = lerpf(H_BASE, H_GROOVE, smoothstep(0.0, 0.3, (-1.0 - d) * rope_w))
				v = lerpf(v, H_FIELD + s * BRUSH_DEPTH, _round_edge(clampf(-field / 0.5, 0.0, 1.0)))
			for k in 2:
				var c := Vector2(SCREW_X * (1.0 if k == 1 else -1.0), 0.0)
				var r := p.distance_to(c)
				if r < SCREW_R + 0.3:
					screw[i] = 1
					v = H_FIELD - 0.2
					if r < SCREW_R:
						var local := (p - c).rotated(-deg_to_rad(SLOT_DEG[k]))
						v = H_FIELD + 0.1 + 0.55 * sqrt(1.0 - pow(r / SCREW_R, 2.0))
						if absf(local.y) < SLOT_W / 2.0:
							v = H_FIELD - 0.1
			h[i] = v
	var blur := _blur(_blur(h, roundi(CAVITY_MM / mm / 2.0)), roundi(CAVITY_MM / mm / 2.0))
	var albedo := Image.create(SIZE, SIZE, false, Image.FORMAT_RGB8)
	var normal := Image.create(SIZE, SIZE, false, Image.FORMAT_RGB8)
	var rough := Image.create(SIZE, SIZE, false, Image.FORMAT_L8)
	for y in SIZE:
		for x in SIZE:
			var i := y * SIZE + x
			var p := Vector2((x + 0.5) * mm - half, (y + 0.5) * mm - half)
			var cav := clampf((blur[i] - h[i]) / 0.3, 0.0, 1.0)
			var ridge := clampf((h[i] - blur[i]) / 0.3, 0.0, 1.0)
			# Patina in Flecken, zum Rand des Felds hin dichter
			var edge := smoothstep(5.0, 0.0, -_box_sdf(p, half - GROOVE, 2.0))
			var tarnish := clampf(0.3 + 0.3 * smoothstep(0.15, 0.95, pat[i]) + 0.25 * edge, 0.0, 1.0)
			var col: Color
			var rv: float
			if screw[i]:
				col = SCREW * (0.8 + 0.4 * pat[i])
				col = col.lerp(SCREW * 1.6, ridge * 0.5)
				rv = 0.55
			else:
				col = BRASS.lerp(PATINA, tarnish) * (1.0 + 0.09 * streak[i])
				col = col.lerp(BRASS * 1.08, ridge * 0.7)
				rv = 0.36 + 0.22 * tarnish + 0.05 * absf(streak[i]) - 0.1 * ridge
			col = col.lerp(DIRT, pow(cav, 0.8) * 0.9)
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
	albedo.save_png(OUT_ALBEDO)
	normal.save_png(OUT_NORMAL)
	rough.save_png(OUT_ROUGH)
	print("%d Stränge, %s" % [strands, OUT_ALBEDO])
	quit()


## Bürstriefen senkrecht: -1 … 1, quer dicht, längs lang gezogen
static func _streak(noise: FastNoiseLite, p: Vector2) -> float:
	return clampf(noise.get_noise_2d(p.x * 6.0, p.y * 0.06) * 1.6, -1.0, 1.0)


## Abstand zum Quadrat mit halber Kantenlänge half und Eckradius r (innen negativ)
static func _box_sdf(p: Vector2, half: float, r: float) -> float:
	var q := p.abs() - Vector2(half - r, half - r)
	return Vector2(maxf(q.x, 0.0), maxf(q.y, 0.0)).length() + minf(maxf(q.x, q.y), 0.0) - r


## 0 … 1 mit runder Kante oben (Viertelkreis statt Knick)
static func _round_edge(t: float) -> float:
	return sqrt(1.0 - pow(1.0 - t, 2.0))


## Weg entlang der Mittellinie der Kordel (gerade Strecken 2a, Ecken arc lang), gegen den Uhrzeigersinn im Bild
static func _perimeter(p: Vector2, a: float, arc: float) -> float:
	var c := p.clamp(Vector2(-a, -a), Vector2(a, a))
	var corner := absf(c.x) >= a and absf(c.y) >= a
	if corner:
		var ang := fposmod((p - c).angle(), TAU)
		var q := floori(ang / (PI / 2.0))   # 0: rechts unten, 1: links unten, 2: links oben, 3: rechts oben
		return 2.0 * a * (q + 1) + arc * q + (ang - q * PI / 2.0) / (PI / 2.0) * arc
	if absf(p.x) - a >= absf(p.y) - a:
		if p.x > 0.0:
			return p.y + a
		return 4.0 * a + 2.0 * arc + (a - p.y)
	if p.y > 0.0:
		return 2.0 * a + arc + (a - p.x)
	return 6.0 * a + 3.0 * arc + (p.x + a)


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
