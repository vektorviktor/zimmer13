extends SceneTree
## Stuck der Zierleiste (Cornice, ZIM-131): elfenbein gestrichen und gealtert. Quer (Bildhöhe) das abgewickelte Profil
## aus Cornice.profile() – Zeile = Anteil der Bogenlänge, oben die Unterkante an der Wand, unten die Decke –, längs
## (Bildbreite) ALONG_M Meter, nahtlos (alles Rauschen liest auf einem Zylinder). Darin: Farbe mit leichter Wolkigkeit,
## stellenweise vergilbt; Pinselstriche längs; Verschattung und Staub in Kehlen und Stufen, aus dem Profil gerechnet
## (offener Winkel je Punkt, wie eine gebackene Verschattung); Craquelé der alten Farbe (Netz aus Haarrissen, dunkel und
## rau) in Flecken; wenige abgeplatzte Stellen mit grauem Gips und Farbkante. Fester Zufallsstartwert – gleiche Karten bei
## jedem Lauf.
##
##   godot --headless --path . -s tools/cornice_stucco.gd
##       schreibt OUT_*; im Spiel über die UVs der Leiste gespannt (Cornice.ALONG, Bogenlänge)

const CorniceKit := preload("res://scripts/level/cornice.gd")

const OUT_ALBEDO := "res://assets/textures/cornice.png"
const OUT_NORMAL := "res://assets/textures/cornice_normal.png"
const OUT_ROUGH := "res://assets/textures/cornice_rough.png"
## Pixel längs und quer; längs abgebildete Strecke (m, = Cornice.ALONG) – 1 mm je Pixel, quer ~0,4 mm
const W := 1024
const H := 512
const ALONG_M := 1.0
## Farben (sRGB): Elfenbein, vergilbt, Staub in den Kehlen, Gips unter abgeplatzter Farbe
const IVORY := Color(0.91, 0.87, 0.77)
const YELLOWED := Color(0.84, 0.78, 0.63)
const GRIME := Color(0.4, 0.36, 0.3)
const PLASTER := Color(0.79, 0.76, 0.7)
## Verschattung: Strahlen je Punkt, Reichweite (m), so stark dunkelt sie die Farbe; geglättet über AO_BLUR (mm) quer
## und nie dunkler als AO_MIN offen – die Stufen sind nur Millimeter breit und flimmerten sonst als dunkle Linien
const AO_RAYS := 96
const AO_REACH := 0.2
const AO_DARK := 0.45
const AO_BLUR := 2.5
const AO_MIN := 0.35
## Höhen (mm): Pinselstriche, Tiefe der Haarrisse, Dicke der Farbe an abgeplatzten Stellen
const BRUSH_DEPTH := 0.035
const CRACK_DEPTH := 0.04
const PAINT_DEPTH := 0.25
## Haarrisse: Zellgröße (mm), Breite (Anteil), Flecken mit Craquelé (Schwelle des Rauschens, Übergang), Dunkelung
const CRACK_CELL := 4.5
const CRACK_W := 0.05
const CRACK_AREA := Vector2(0.6, 0.1)
const CRACK_DARK := 0.22
## Abgeplatzte Stellen: Anzahl, Größe (mm)
const CHIPS := 9
const CHIP_SIZE := Vector2(1.5, 5.0)
const SEED := 1310


func _init() -> void:
	var pts := CorniceKit.profile()
	var arc := CorniceKit.arcs()
	var total: float = arc[-1]
	var mm := Vector2(ALONG_M * 1000.0 / W, total * 1000.0 / H)   # mm je Pixel längs, quer
	var radius := ALONG_M * 1000.0 / TAU   # mm
	# je Zeile: offener Winkel und Neigung der Fläche (Normale nach oben)
	var open := PackedFloat32Array()
	var up := PackedFloat32Array()
	open.resize(H)
	up.resize(H)
	for y in H:
		var s := (y + 0.5) / H * total
		var k := 0
		while k < pts.size() - 2 and arc[k + 1] < s:
			k += 1
		var t := (s - arc[k]) / maxf(arc[k + 1] - arc[k], 1e-6)
		var p: Vector2 = pts[k].lerp(pts[k + 1], t)
		var d: Vector2 = pts[k + 1] - pts[k]
		var n := Vector2(d.y, -d.x).normalized()
		open[y] = _openness(pts, p + n * 0.0002, n)
		up[y] = maxf(n.y, 0.0)
	var reach := ceili(AO_BLUR / mm.y)
	var raw := open.duplicate()
	for y in H:
		var sum := 0.0
		for j in range(-reach, reach + 1):
			sum += raw[clampi(y + j, 0, H - 1)]
		open[y] = maxf(sum / (2 * reach + 1), AO_MIN)
	var cloud := FastNoiseLite.new()
	cloud.seed = SEED
	cloud.frequency = 0.012
	cloud.fractal_octaves = 4
	var brush := FastNoiseLite.new()
	brush.seed = SEED + 1
	brush.frequency = 1.0
	brush.fractal_octaves = 3
	var cells := FastNoiseLite.new()
	cells.seed = SEED + 2
	cells.noise_type = FastNoiseLite.TYPE_CELLULAR
	cells.cellular_return_type = FastNoiseLite.RETURN_DISTANCE2_SUB
	cells.cellular_jitter = 0.9
	cells.frequency = 1.0 / CRACK_CELL
	cells.fractal_type = FastNoiseLite.FRACTAL_NONE
	var patch := FastNoiseLite.new()
	patch.seed = SEED + 3
	patch.frequency = 0.02
	patch.fractal_octaves = 2
	var n := W * H
	var h := PackedFloat32Array()
	h.resize(n)
	var col := PackedColorArray()
	col.resize(n)
	var rough := PackedFloat32Array()
	rough.resize(n)
	var crack_min := 1.0
	var crack_max := -1.0
	for y in H:
		var py := (y + 0.5) * mm.y
		var cavity := 1.0 - open[y]
		for x in W:
			var a := TAU * (x + 0.5) / W
			var ring := Vector2(cos(a), sin(a)) * radius
			var i := y * W + x
			# Pinselstriche: längs gestreckt (quer dicht), auf dem Zylinder
			var stroke := brush.get_noise_3d(ring.x * 0.08, ring.y * 0.08, py * 1.2)
			var c := cells.get_noise_3d(ring.x, ring.y, py)
			crack_min = minf(crack_min, c)
			crack_max = maxf(crack_max, c)
			var edge := (c + 1.0) * 0.5   # 0 an der Zellgrenze
			var area := smoothstep(CRACK_AREA.x, CRACK_AREA.x + CRACK_AREA.y, patch.get_noise_3d(ring.x, ring.y, py) * 0.5 + 0.5)
			var crack := smoothstep(CRACK_W, 0.0, edge) * area
			var tone := cloud.get_noise_3d(ring.x, ring.y, py * 2.0) * 0.5 + 0.5
			var base := IVORY.lerp(YELLOWED, smoothstep(0.35, 0.85, tone) * 0.45)
			base = base * (1.0 + 0.025 * stroke)
			base = base.lerp(GRIME, clampf(cavity * AO_DARK + up[y] * 0.12, 0.0, 0.8))
			base = base.lerp(GRIME * 0.8, crack * CRACK_DARK)
			col[i] = base
			h[i] = stroke * BRUSH_DEPTH - crack * CRACK_DEPTH
			rough[i] = clampf(0.58 + 0.06 * (tone - 0.5) + 0.04 * stroke + cavity * 0.3 + crack * 0.2, 0.0, 1.0)
	# abgeplatzte Farbe: Gips darunter, Kante der Farbschicht
	var rng := RandomNumberGenerator.new()
	rng.seed = SEED + 4
	for k in CHIPS:
		var c := Vector2(rng.randf() * W * mm.x, rng.randf_range(0.15, 0.95) * H * mm.y)
		var r := Vector2(rng.randf_range(CHIP_SIZE.x, CHIP_SIZE.y), rng.randf_range(CHIP_SIZE.x, CHIP_SIZE.y) * 0.7)
		var rot := rng.randf() * TAU
		for y in range(maxi(0, floori((c.y - r.x * 1.5) / mm.y)), mini(H, ceili((c.y + r.x * 1.5) / mm.y))):
			for x in range(floori((c.x - r.x * 1.5) / mm.x), ceili((c.x + r.x * 1.5) / mm.x)):
				var q := (Vector2((x + 0.5) * mm.x, (y + 0.5) * mm.y) - c).rotated(-rot)
				var wobble := 1.0 + 0.25 * sin(atan2(q.y, q.x) * 5.0 + k)
				var dist := Vector2(q.x / r.x, q.y / r.y).length() / wobble
				if dist >= 1.15:
					continue
				var i := y * W + posmod(x, W)
				var inside := smoothstep(1.0, 0.85, dist)
				col[i] = col[i].lerp(PLASTER * (0.95 + 0.05 * rng.randf()), inside)
				h[i] -= PAINT_DEPTH * inside
				rough[i] = lerpf(rough[i], 0.88, inside)
	var albedo := Image.create(W, H, false, Image.FORMAT_RGB8)
	var normal := Image.create(W, H, false, Image.FORMAT_RGB8)
	var rough_img := Image.create(W, H, false, Image.FORMAT_L8)
	for y in H:
		for x in W:
			var i := y * W + x
			albedo.set_pixel(x, y, col[i])
			rough_img.set_pixel(x, y, Color(rough[i], rough[i], rough[i]))
			var dx := (h[y * W + posmod(x + 1, W)] - h[y * W + posmod(x - 1, W)]) / (2.0 * mm.x)
			var yu := maxi(y - 1, 0)
			var yd := mini(y + 1, H - 1)
			var dy := (h[yd * W + x] - h[yu * W + x]) / ((yd - yu) * mm.y)
			var nv := Vector3(-dx, dy, 1.0).normalized()   # Bildzeile wächst nach unten, Grün = oben
			normal.set_pixel(x, y, Color(nv.x * 0.5 + 0.5, nv.y * 0.5 + 0.5, nv.z * 0.5 + 0.5))
	albedo.save_png(OUT_ALBEDO)
	normal.save_png(OUT_NORMAL)
	rough_img.save_png(OUT_ROUGH)
	var shade := Array(open).map(func(o: float) -> String: return "%.2f" % o)
	print("Zierleiste %d × %d (%.2f × %.2f mm je Pixel), Risse %.2f … %.2f, offen je 32 Zeilen: %s" % [W, H, mm.x, mm.y,
		crack_min, crack_max, ", ".join(shade.slice(0, H, 32))])
	quit()


## Anteil des offenen Halbraums über dem Punkt p mit Normale n (kosinusgewichtet, im Querschnitt): verdeckt, was die
## Strahlen innerhalb AO_REACH am Profil, an der Wand darunter (x < 0) oder an der Decke (y > 0) trifft.
static func _openness(pts: Array[Vector2], p: Vector2, n: Vector2) -> float:
	var sum := 0.0
	var free := 0.0
	for r in AO_RAYS:
		var ang := (float(r) + 0.5) / AO_RAYS * PI - PI / 2.0
		var dir := n.rotated(ang)
		var w := cos(ang)
		sum += w
		var end := p + dir * AO_REACH
		var hit := end.x < 0.0 or end.y > 0.0
		for k in pts.size() - 1:
			if hit:
				break
			hit = Geometry2D.segment_intersects_segment(p, end, pts[k], pts[k + 1]) != null
		if not hit:
			free += w
	return free / sum
