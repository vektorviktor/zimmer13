class_name TexGen
## Erzeugt kleine prozedurale Texturen im PS1-Stil.
## Platzhalter, bis echte Texturen aus Blender kommen.

static var _cache := {}


static func get_tex(id: String) -> Texture2D:
	if _cache.has(id):
		return _cache[id]
	var img: Image
	match id:
		"carpet":
			img = _carpet()
		"runner":
			img = _runner()
		"wood":
			img = _wood()
		"ceiling":
			img = _ceiling()
		"cobweb":
			img = _cobweb()
		"tiles":
			img = _tiles()
		"grass":
			img = _grass()
		"hedge":
			img = _hedge()
		"leaves":
			img = _leaves()
		_:
			img = _concrete()
	var tex := ImageTexture.create_from_image(img)
	_cache[id] = tex
	return tex


static func _rng(seed_value: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	return rng


static func _carpet() -> Image:
	var img := Image.create(32, 32, false, Image.FORMAT_RGB8)
	var rng := _rng(2)
	for y in 32:
		for x in 32:
			var c := Color(0.36, 0.06, 0.07)
			var dx := absi((x % 16) - 8)
			var dy := absi((y % 16) - 8)
			if dx + dy == 6 or dx + dy == 7:
				c = Color(0.55, 0.38, 0.12)
			elif dx + dy < 2:
				c = Color(0.18, 0.04, 0.05)
			img.set_pixel(x, y, c.darkened(rng.randf() * 0.2))
	return img


## Läufer (Ebene „Teppiche“ im Plan, Spielkonzept 7.5) für `Geo.runner_mesh`: RUNNER_WIDTH px quer über die
## ganze Breite, darunter der Abschluss (Zeile 0 = Ende des Läufers), dann die Musterkachel mit Medaillon, die
## sich wiederholt. Bordüre an den Seiten und am Abschluss; ein Punkt auf der Naht verbindet die Kacheln.
const RUNNER_WIDTH := 32
const RUNNER_CAP_ROWS := 16
const RUNNER_TILE_ROWS := 32

static func _runner() -> Image:
	var img := Image.create(RUNNER_WIDTH, RUNNER_CAP_ROWS + RUNNER_TILE_ROWS, false, Image.FORMAT_RGB8)
	var rng := _rng(9)
	var edge := Color(0.1, 0.04, 0.03)
	var gold := Color(0.58, 0.42, 0.14)
	var line := Color(0.42, 0.07, 0.08)
	var field := Color(0.1, 0.11, 0.2)
	for y in img.get_height():
		var cap := y < RUNNER_CAP_ROWS
		var ty := y - RUNNER_CAP_ROWS
		for x in RUNNER_WIDTH:
			var d := mini(x, RUNNER_WIDTH - 1 - x)
			if cap:
				d = mini(d, y)
			var dx := absf(x - (RUNNER_WIDTH - 1) / 2.0)
			var c := field
			if d < 2:
				c = edge
			elif d < 5:
				c = gold
			elif d == 5:
				c = line
			elif cap:
				if y >= RUNNER_CAP_ROWS - 2 and dx < 1.5:
					c = gold
			else:
				var dy := absf(ty - (RUNNER_TILE_ROWS - 1) / 2.0)
				var m := dx + dy
				if dy >= RUNNER_TILE_ROWS / 2.0 - 2.0 and dx < 1.5:
					c = gold   # Punkt auf der Naht
				elif m >= 8.0 and m < 10.0:
					c = gold
				elif m >= 5.0 and m < 6.0:
					c = line
				elif m < 3.0:
					c = line.lightened(0.15)
			img.set_pixel(x, y, c.darkened(rng.randf() * 0.18))
	return img


static func _wood() -> Image:
	var img := Image.create(32, 32, false, Image.FORMAT_RGB8)
	var rng := _rng(3)
	var plank_tones: Array[float] = []
	for i in 4:
		plank_tones.append(rng.randf_range(-0.06, 0.06))
	for y in 32:
		var plank := y / 8
		for x in 32:
			var base := Color(0.36, 0.22, 0.12)
			var c := base.lightened(plank_tones[plank]) if plank_tones[plank] > 0.0 else base.darkened(-plank_tones[plank])
			if y % 8 == 0 or (x + plank * 11) % 32 == 0:
				c = Color(0.12, 0.07, 0.04)
			elif (x + y * 3) % 7 == 0:
				c = c.darkened(0.1)
			img.set_pixel(x, y, c.darkened(rng.randf() * 0.08))
	return img


static func _ceiling() -> Image:
	var img := Image.create(32, 32, false, Image.FORMAT_RGB8)
	var rng := _rng(4)
	for y in 32:
		for x in 32:
			var c := Color(0.55, 0.52, 0.46)
			if x % 16 == 0 or y % 16 == 0:
				c = Color(0.3, 0.28, 0.25)
			img.set_pixel(x, y, c.darkened(rng.randf() * 0.18))
	return img


static func _concrete() -> Image:
	var img := Image.create(32, 32, false, Image.FORMAT_RGB8)
	var rng := _rng(5)
	for y in 32:
		for x in 32:
			var v := 0.32 + rng.randf() * 0.1
			img.set_pixel(x, y, Color(v, v * 0.97, v * 0.92))
	return img


static func _cobweb() -> Image:
	var size := 64
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var center := Vector2(size / 2.0, size / 2.0)
	var web := Color(0.85, 0.85, 0.82, 1.0)
	# Speichen
	for i in 8:
		var angle := TAU * i / 8.0
		var dir := Vector2(cos(angle), sin(angle))
		for r in range(0, size / 2):
			var p := center + dir * r
			img.set_pixel(clampi(int(p.x), 0, size - 1), clampi(int(p.y), 0, size - 1), web)
	# Ringe
	for ring in [6, 12, 19, 26]:
		var steps := 64
		for s in steps:
			var angle := TAU * s / float(steps)
			var p := center + Vector2(cos(angle), sin(angle)) * float(ring)
			img.set_pixel(clampi(int(p.x), 0, size - 1), clampi(int(p.y), 0, size - 1), web)
	return img


static func _tiles() -> Image:
	var img := Image.create(32, 32, false, Image.FORMAT_RGB8)
	var rng := _rng(6)
	for y in 32:
		for x in 32:
			var light := ((x / 16) + (y / 16)) % 2 == 0
			var c := Color(0.62, 0.6, 0.55) if light else Color(0.12, 0.12, 0.13)
			if x % 16 == 0 or y % 16 == 0:
				c = Color(0.3, 0.29, 0.27)
			img.set_pixel(x, y, c.darkened(rng.randf() * 0.12))
	return img


static func _grass() -> Image:
	var img := Image.create(32, 32, false, Image.FORMAT_RGB8)
	var rng := _rng(7)
	for y in 32:
		for x in 32:
			var c := Color(0.16, 0.22, 0.09)
			var r := rng.randf()
			if r < 0.15:
				c = Color(0.28, 0.2, 0.1)
			elif r < 0.3:
				c = Color(0.22, 0.3, 0.12)
			img.set_pixel(x, y, c.darkened(rng.randf() * 0.2))
	return img


static func _hedge() -> Image:
	var img := Image.create(32, 32, false, Image.FORMAT_RGB8)
	var rng := _rng(8)
	for y in 32:
		for x in 32:
			var v := rng.randf()
			var c := Color(0.06, 0.13, 0.05).lerp(Color(0.16, 0.28, 0.1), v * v)
			if v > 0.97:
				c = Color(0.22, 0.17, 0.07)
			img.set_pixel(x, y, c)
	return img


## Blattbüschel für die Blattkarten der Hecken (mit Alpha): unten dicht – dort steckt die Karte in der Hecke –,
## nach oben einzelne Blätter; dazwischen ein paar herbstgelbe. Farben wie „hedge“.
static func _leaves() -> Image:
	var img := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var rng := _rng(9)
	for i in 70:
		var rise := pow(rng.randf(), 1.8)
		var c := Vector2(16.0 + rng.randf_range(-1.0, 1.0) * lerpf(13.0, 5.0, rise), 30.0 - rise * 26.0)
		var col := Color(0.08, 0.17, 0.07).lerp(Color(0.18, 0.31, 0.11), rng.randf())
		if rng.randf() < 0.06:
			col = Color(0.48, 0.4, 0.1)
		_leaf(img, c, rng.randf() * TAU, rng.randf_range(2.0, 3.0), 1.3, col)
	return img


## Ein Blatt als Ellipse (Halbachsen a entlang angle, b quer), zur Spitze hin heller
static func _leaf(img: Image, c: Vector2, angle: float, a: float, b: float, col: Color) -> void:
	var dir := Vector2.from_angle(angle)
	for y in range(floori(c.y - a), ceili(c.y + a) + 1):
		for x in range(floori(c.x - a), ceili(c.x + a) + 1):
			if x < 0 or y < 0 or x >= img.get_width() or y >= img.get_height():
				continue
			var d := Vector2(x + 0.5, y + 0.5) - c
			var u := d.dot(dir) / a
			var v := d.dot(dir.orthogonal()) / b
			if u * u + v * v <= 1.0:
				img.set_pixel(x, y, Color(col.lightened(0.15 * u).darkened(0.1), 1.0))
