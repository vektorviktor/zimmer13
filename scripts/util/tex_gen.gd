class_name TexGen
## Erzeugt kleine prozedurale Texturen im PS1-Stil.
## Platzhalter, bis echte Texturen aus Blender kommen.

static var _cache := {}


static func get_tex(id: String) -> Texture2D:
	if _cache.has(id):
		return _cache[id]
	var img: Image
	match id:
		"wallpaper":
			img = _wallpaper()
		"carpet":
			img = _carpet()
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
		_:
			img = _concrete()
	var tex := ImageTexture.create_from_image(img)
	_cache[id] = tex
	return tex


static func _rng(seed_value: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	return rng


static func _wallpaper() -> Image:
	var img := Image.create(32, 32, false, Image.FORMAT_RGB8)
	var rng := _rng(1)
	for y in 32:
		for x in 32:
			var c := Color(0.24, 0.29, 0.21)
			if x % 8 == 0:
				c = Color(0.32, 0.34, 0.22)
			var dx := absi((x % 8) - 4)
			var dy := absi((y % 8) - 4)
			if dx + dy == 2:
				c = Color(0.38, 0.32, 0.18)
			img.set_pixel(x, y, c.darkened(rng.randf() * 0.15))
	return img


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
			var c := Color(0.08, 0.17, 0.07).lerp(Color(0.16, 0.28, 0.1), v)
			if v > 0.92:
				c = Color(0.45, 0.25, 0.08)
			img.set_pixel(x, y, c)
	return img
