extends SceneTree
## Porenkarte (Normal Map, OpenGL) für den Stein der Lobbysäulen: unregelmäßige flache Vertiefungen, etwa eine je
## 2 cm², nahtlos kachelbar. Fester Zufallsstartwert – gleiche Karte bei jedem Lauf.
##
##   godot --headless --path . -s tools/pore_map.gd
##       schreibt OUT; im Spiel über die Kachelung TILE_M (LevelBuilder.PILLAR_PORES_METERS) gespannt

const OUT := "res://assets/textures/TerrazzoDark_01/TerrazzoDark_01_pores_normal.png"
## = Mat.PHOTO_SIZE
const SIZE := 1024
## Kantenlänge einer Kachel in Metern (0,25 mm je Pixel)
const TILE_M := 0.25
## Poren je cm²
const DENSITY := 0.5
## Radius in mm (viele kleine, wenige große), Verhältnis lange/kurze Achse, Ausfransen des Rands
const RADIUS_MM := Vector2(0.3, 1.0)
const ASPECT := Vector2(1.0, 1.7)
const RAGGED := 0.18
## Tiefe im Verhältnis zum Radius
const DEPTH := 0.45
const SEED := 1313


func _init() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = SEED
	var px_mm := SIZE / (TILE_M * 1000.0)
	var count := roundi(TILE_M * TILE_M * 1e4 * DENSITY)
	var h := PackedFloat32Array()
	h.resize(SIZE * SIZE)
	for _i in count:
		var c := Vector2(rng.randf() * SIZE, rng.randf() * SIZE)
		var r := lerpf(RADIUS_MM.x, RADIUS_MM.y, pow(rng.randf(), 2.0)) * px_mm
		var aspect := rng.randf_range(ASPECT.x, ASPECT.y)
		var rot := rng.randf() * TAU
		var waves := []   # Rand: Radius über den Winkel mit drei Wellen verbeult
		for k in [2, 3, 5]:
			waves.append(Vector3(k, rng.randf() * TAU, rng.randf() * RAGGED))
		var depth := DEPTH * r
		var reach := ceili(r * aspect * (1.0 + RAGGED * 3.0)) + 1
		for y in range(floori(c.y) - reach, floori(c.y) + reach + 1):
			for x in range(floori(c.x) - reach, floori(c.x) + reach + 1):
				var d := (Vector2(x + 0.5, y + 0.5) - c).rotated(-rot)
				d.x /= aspect
				var edge := r
				var ang := d.angle()
				for w: Vector3 in waves:
					edge *= 1.0 + w.z * sin(w.x * ang + w.y)
				var f := 1.0 - d.length_squared() / (edge * edge)
				if f <= 0.0:
					continue
				var i := posmod(y, SIZE) * SIZE + posmod(x, SIZE)
				h[i] = minf(h[i], -depth * pow(f, 0.7))
	var img := Image.create(SIZE, SIZE, false, Image.FORMAT_RGB8)
	for y in SIZE:
		for x in SIZE:
			var dx := (h[y * SIZE + (x + 1) % SIZE] - h[y * SIZE + posmod(x - 1, SIZE)]) / 2.0
			var dy := (h[((y + 1) % SIZE) * SIZE + x] - h[posmod(y - 1, SIZE) * SIZE + x]) / 2.0
			var n := Vector3(-dx, dy, 1.0).normalized()   # Bildzeile wächst nach unten, Grün = oben
			img.set_pixel(x, y, Color(n.x * 0.5 + 0.5, n.y * 0.5 + 0.5, n.z * 0.5 + 0.5))
	img.save_png(OUT)
	print("%d Poren, %s" % [count, OUT])
	quit()
