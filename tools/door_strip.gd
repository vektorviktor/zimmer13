extends SceneTree
## Messing der Übergangsschiene unter den Türen (DoorStrip, ZIM-132): dasselbe gebürstete Altmessing wie die
## Lichtschalter (tools/switch_plate.gd – Farben, Bürstriefen, Patina), aber als Streifen, der längs nahtlos kachelt.
## Quer (Bildbreite) liegt das abgewickelte Profil der Schiene, längs (Bildhöhe) laufen die Bürstriefen. Mitte vom
## Drüberlaufen blank, zu den Kanten hin Patina, in der Fuge am Boden Schmutz; dazu feine Kratzer quer von den
## Schuhen. Längs kachelbar, weil alles Rauschen auf einem Zylinder liest. Fester Zufallsstartwert – gleiche Karten
## bei jedem Lauf.
##
##   godot --headless --path . -s tools/door_strip.gd
##       schreibt OUT_*; im Spiel über die UVs der Schiene gespannt (DoorStrip.ACROSS, DoorStrip.ALONG)

const OUT_ALBEDO := "res://assets/textures/door_strip.png"
const OUT_NORMAL := "res://assets/textures/door_strip_normal.png"
const OUT_ROUGH := "res://assets/textures/door_strip_rough.png"
## Pixel quer und längs, abgebildete Strecke in mm (= DoorStrip.ACROSS, ALONG) – 3,2 Pixel je mm
const W := 128
const H := 1024
const ACROSS_MM := 40.0
const ALONG_MM := 320.0
## Breite des Schmutzrands an jeder Kante (mm), Breite des blank gelaufenen Bands in der Mitte (Anteil)
const DIRT_MM := 2.5
const WEAR := 0.45
## Bürstriefen (mm Höhe), Kratzer: Anzahl, Länge (mm), Tiefe (mm), Breite (mm)
const BRUSH_DEPTH := 0.004
const SCRATCHES := 45
const SCRATCH_LEN := Vector2(3.0, 14.0)
const SCRATCH_DEPTH := 0.012
const SCRATCH_W := 0.25
## = tools/switch_plate.gd
const BRASS := Color(0.74, 0.57, 0.3)
const PATINA := Color(0.32, 0.23, 0.1)
const DIRT := Color(0.08, 0.055, 0.03)
const SEED := 1320


func _init() -> void:
	var mm := Vector2(ACROSS_MM / W, ALONG_MM / H)   # mm je Pixel
	var radius := ALONG_MM / TAU
	var patina := FastNoiseLite.new()
	patina.seed = SEED
	patina.frequency = 0.05
	patina.fractal_octaves = 4
	var brush := FastNoiseLite.new()
	brush.seed = SEED + 1
	brush.frequency = 1.0
	brush.fractal_octaves = 2
	var n := W * H
	var h := PackedFloat32Array()
	h.resize(n)
	var streak := PackedFloat32Array()
	streak.resize(n)
	var pat := PackedFloat32Array()
	pat.resize(n)
	for y in H:
		var a := TAU * (y + 0.5) / H
		var ring := Vector2(cos(a), sin(a)) * radius
		for x in W:
			var px := (x + 0.5) * mm.x
			var i := y * W + x
			# wie _streak und die Patina der Schalter, die Längsachse auf dem Zylinder (nahtlos)
			var s := clampf(brush.get_noise_3d(px * 6.0, ring.x * 0.06, ring.y * 0.06) * 1.6, -1.0, 1.0)
			streak[i] = s
			pat[i] = patina.get_noise_3d(px * 1.4, ring.x * 0.45, ring.y * 0.45) * 0.5 + 0.5
			h[i] = s * BRUSH_DEPTH
	# Kratzer: kurz, fast quer zur Schiene, längs umlaufend
	var rng := RandomNumberGenerator.new()
	rng.seed = SEED + 2
	var scratch := PackedFloat32Array()
	scratch.resize(n)
	for k in SCRATCHES:
		var c := Vector2(rng.randf_range(4.0, ACROSS_MM - 4.0), rng.randf() * ALONG_MM)
		var dir := Vector2.RIGHT.rotated(rng.randf_range(-0.5, 0.5))
		var half := rng.randf_range(SCRATCH_LEN.x, SCRATCH_LEN.y) / 2.0
		var depth := SCRATCH_DEPTH * rng.randf_range(0.4, 1.0)
		var reach := half + SCRATCH_W * 2.0
		for y in range(floori((c.y - reach) / mm.y), ceili((c.y + reach) / mm.y) + 1):
			for x in range(maxi(0, floori((c.x - reach) / mm.x)), mini(W, ceili((c.x + reach) / mm.x) + 1)):
				var p := Vector2((x + 0.5) * mm.x, (y + 0.5) * mm.y) - c
				var along := p.dot(dir)
				if absf(along) > half:
					continue
				var d := absf(p.dot(dir.orthogonal())) / SCRATCH_W
				if d < 1.0:
					var i := posmod(y, H) * W + x
					var taper := sqrt(1.0 - pow(along / half, 2.0))
					var v := depth * taper * (1.0 - d * d)
					h[i] -= v
					scratch[i] = maxf(scratch[i], taper * (1.0 - d))
	var albedo := Image.create(W, H, false, Image.FORMAT_RGB8)
	var normal := Image.create(W, H, false, Image.FORMAT_RGB8)
	var rough := Image.create(W, H, false, Image.FORMAT_L8)
	for y in H:
		for x in W:
			var i := y * W + x
			var px := (x + 0.5) * mm.x
			var edge := minf(px, ACROSS_MM - px)
			var dirt := smoothstep(DIRT_MM, 0.0, edge)
			var wear := smoothstep(WEAR, 0.0, absf(px / ACROSS_MM - 0.5) * 2.0 - 0.1)
			var tarnish := clampf(0.35 + 0.3 * smoothstep(0.15, 0.95, pat[i]) + 0.3 * smoothstep(9.0, 2.0, edge)
				- 0.3 * wear, 0.0, 1.0)
			var col := BRASS.lerp(PATINA, tarnish) * (1.0 + 0.09 * streak[i])
			col = col.lerp(BRASS * 1.1, scratch[i] * 0.45)   # im Kratzer blankes Metall
			var rv := 0.36 + 0.22 * tarnish + 0.05 * absf(streak[i]) - 0.06 * wear + 0.08 * scratch[i]
			col = col.lerp(DIRT, pow(dirt, 0.8) * 0.85)
			rv = lerpf(rv, 0.85, dirt)
			albedo.set_pixel(x, y, col)
			rough.set_pixel(x, y, Color(rv, rv, rv))
			var xl := maxi(x - 1, 0)
			var xr := mini(x + 1, W - 1)
			var dx := (h[y * W + xr] - h[y * W + xl]) / ((xr - xl) * mm.x)
			var dy := (h[posmod(y + 1, H) * W + x] - h[posmod(y - 1, H) * W + x]) / (2.0 * mm.y)
			var nv := Vector3(-dx, dy, 1.0).normalized()   # Bildzeile wächst nach unten, Grün = oben
			normal.set_pixel(x, y, Color(nv.x * 0.5 + 0.5, nv.y * 0.5 + 0.5, nv.z * 0.5 + 0.5))
	albedo.save_png(OUT_ALBEDO)
	normal.save_png(OUT_NORMAL)
	rough.save_png(OUT_ROUGH)
	print("Schiene %d × %d, %s" % [W, H, OUT_ALBEDO])
	quit()
