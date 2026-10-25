class_name PhotoWall
extends Node3D
## Die Gruppenfotos an der Lobbywand (Spielkonzept 5.14): Jedes Jahr seit 1987 ein Halloween-Foto der Gäste vor dem
## Haupteingang, in Holzrahmen nebeneinander – alte vergilbt, neue farbig. Daneben ein leerer Rahmen „Halloween 2026“.
## Zeichnung im Code (Image, je Jahr fester Zufall): Fassade, zwei Reihen Gäste; wer in jenem Oktober geholt wurde, ist
## verwischt, als hätte er sich bewegt. Ein Gesicht ist auf jedem Foto und altert nie: hinten rechts der weißhaarige alte
## Herr mit Gehstock – der Erbe der Familie, als uralter Dauergast getarnt (2.3). Wer genug Fotos ansieht, merkt es
## (Notizbuch). Auf 1987 außerdem ein Mädchen mit Zöpfen (Marion), ein Mann im Kittel (der Heizer), eine junge Frau
## (Edna) und ein großes Mädchen (Liesel) – die Indiz-Stufe für Marion, Edna und Liesel (2.3, 2.7).
## Ort: Ausstattung „Fotowand“ im Plan, bis dahin WALL (Westwand der Lobby, nördlich der Wandlampe).
## Nicht gespeichert; was man gesehen hat, steht im Notizbuch.

## Bis der Plan einen Platz hat: Westwand der Lobby, von z0 bis z1, Bilder nach +X
const WALL := {"x": -7.4, "z0": -27.3, "z1": -21.3}
const YEARS := [1987, 1988, 1990, 1993, 1996, 1999, 2003, 2007, 2011, 2015, 2019, 2023, 2025, 2026]
const ROWS_Y := [2.02, 1.48]
const PHOTO := Vector2(0.4, 0.3)
const FRAME := 0.035
const W := 160
const H := 120
## So viele waren in jenem Oktober verschwunden (verwischt auf dem Bild)
const TAKEN := {1987: 3, 1988: 2, 1990: 2, 1993: 3, 1996: 1, 1999: 2, 2003: 2, 2007: 3, 2011: 2, 2015: 1, 2019: 3, 2023: 2,
	2025: 2}
const HEIR_SEEN := 4              ## so viele Fotos angesehen (mit 1987 und einem neuen) – dann fällt er auf
const TEXTS := {
	1987: "Halloween 1987. Vorn ein Mädchen mit Zöpfen, vielleicht zwölf, daneben ein großes Mädchen mit Pony und eine junge Frau mit dunklem Haar. Ganz links, halb abgeschnitten, ein Mann im grauen Arbeitskittel, Ruß im Gesicht. Hinten rechts ein alter Herr mit weißem Haar und Gehstock. Drei Gesichter sind verwischt.",
	1988: "Halloween 1988. Weniger Gäste als im Jahr davor, niemand lächelt. Hinten rechts der alte Herr mit dem Gehstock.",
	2025: "Halloween 2025, farbig und scharf. Zwei Gesichter sind trotzdem verwischt. Hinten rechts, mit Gehstock und weißem Haar: der alte Herr – genau wie 1987.",
	2026: "„Halloween 2026“ steht auf dem Messingschild. Der Rahmen ist leer.",
}
const NOTE_1987 := "Auf dem Gruppenfoto von 1987 in der Lobby: ein Mädchen mit Zöpfen, ein großes Mädchen, eine junge Frau – und ganz links ein Mann im Kittel mit Ruß im Gesicht."
const NOTE_HEIR := "Auf jedem Gruppenfoto seit 1987 steht hinten rechts derselbe weißhaarige Herr mit Gehstock. Er ist auf keinem älter geworden."

var _pictures := {}               ## Jahr → ImageTexture
var _seen := {}                   ## Jahr → angesehen


func _ready() -> void:
	var per_row := ceili(YEARS.size() / 2.0)
	var step: float = (float(WALL["z1"]) - float(WALL["z0"])) / (per_row - 1)
	for i in YEARS.size():
		var year: int = YEARS[i]
		var row := i / per_row
		var col := i % per_row
		var frame := PhotoFrame.new()
		frame.year = year
		frame.wall = self
		frame.position = Vector3(float(WALL["x"]) + 0.02, ROWS_Y[row], float(WALL["z0"]) + col * step)
		frame.rotation.y = PI / 2.0   # +Z in die Lobby
		frame.rotation.z = sin(year * 1.7) * 0.025   # nie ganz gerade
		add_child(frame)
		if year != 2026:
			_pictures[year] = ImageTexture.create_from_image(draw_photo(year))
		frame.build(_pictures.get(year))


func picture(year: int) -> Texture2D:
	return _pictures.get(year)


## Ein Foto angesehen: Text, ins Notizbuch, was auffällt.
func look_at_photo(year: int) -> void:
	_seen[year] = true
	var text := String(TEXTS.get(year, ""))
	if text == "":
		var blurred: int = TAKEN.get(year, 0)
		text = "Halloween %d. Die Gäste in zwei Reihen vor dem Haupteingang. %s Hinten rechts der alte Herr mit dem Gehstock." % [
			year, "Ein Gesicht ist verwischt." if blurred == 1 else "%d Gesichter sind verwischt." % blurred]
	if Game.menus:
		Game.menus.open_photo("Halloween %d" % year, _pictures.get(year), text)
	if Game.notebook:
		if year == 1987:
			Game.notebook.add_note("photo_1987", NOTE_1987, "Fotowand")
		if _seen.size() >= HEIR_SEEN and _seen.has(1987) and _seen.keys().any(func(y: int) -> bool: return y >= 2015 and y != 2026):
			Game.notebook.add_note("photo_heir", NOTE_HEIR, "Fotowand")


# --- Zeichnen ---------------------------------------------------------------------------------------

## Das Foto eines Jahres: fest aus dem Jahr gewürfelt, nur die Sonderfiguren sind gesetzt.
static func draw_photo(year: int) -> Image:
	var rng := RandomNumberGenerator.new()
	rng.seed = year * 7919
	var img := Image.create(W, H, false, Image.FORMAT_RGB8)
	_facade(img, rng)
	var people: Array[Dictionary] = []
	var back := rng.randi_range(6, 8)
	for i in back:
		people.append(_person(rng, 14.0 + i * (W - 50.0) / back, 52.0, 0.85))
	var front := rng.randi_range(5, 7)
	for i in front:
		people.append(_person(rng, 18.0 + i * (W - 36.0) / front, 66.0, 1.05))
	if year == 1987:   # Marion, Liesel, Edna vorn; der Heizer am linken Rand
		people[back + 1] = _person(rng, people[back + 1]["x"], 74.0, 0.78, Color(0.5, 0.2, 0.2), Color(0.35, 0.22, 0.12), "braids")
		people[back + 2] = _person(rng, people[back + 2]["x"], 68.0, 0.95, Color(0.2, 0.3, 0.45), Color(0.55, 0.4, 0.2), "fringe")
		people[back + 3] = _person(rng, people[back + 3]["x"], 66.0, 1.02, Color(0.45, 0.4, 0.35), Color(0.1, 0.08, 0.06))
		people.append(_person(rng, 3.0, 58.0, 1.05, Color(0.42, 0.42, 0.4), Color(0.12, 0.1, 0.08), "soot"))
	var taken: int = TAKEN.get(year, 0)
	var candidates := range(people.size())
	candidates.sort_custom(func(a: int, b: int) -> bool: return hash(year * 31 + a) < hash(year * 31 + b))
	for i in people.size():
		if i < back:   # hintere Reihe zuerst, der alte Herr ganz rechts dahinter
			_draw_person(img, people[i])
	_draw_heir(img)
	for i in range(back, people.size()):
		_draw_person(img, people[i])
	for k in taken:
		var who: Dictionary = people[candidates[k]]
		if who.get("style", "") == "":
			_smear(img, who)
	_age(img, year, rng)
	return img


static func _facade(img: Image, rng: RandomNumberGenerator) -> void:
	img.fill(Color(0.42, 0.36, 0.3))
	img.fill_rect(Rect2i(0, 0, W, 16), Color(0.16, 0.15, 0.18))   # Nachthimmel über dem Dach
	for x in range(6, W, 22):   # Fenster
		for y in [22, 42]:
			img.fill_rect(Rect2i(x, y, 10, 12), Color(0.85, 0.7, 0.35) if rng.randf() < 0.6 else Color(0.12, 0.1, 0.1))
	img.fill_rect(Rect2i(W / 2 - 14, 34, 28, 40), Color(0.2, 0.13, 0.08))   # Haupteingang
	img.fill_rect(Rect2i(W / 2 - 16, 30, 32, 4), Color(0.6, 0.5, 0.3))
	img.fill_rect(Rect2i(0, 86, W, H - 86), Color(0.3, 0.27, 0.24))   # Treppe, Boden
	for y in range(86, H, 6):
		img.fill_rect(Rect2i(0, y, W, 1), Color(0.24, 0.21, 0.19))
	for x in [W / 2 - 22, W / 2 + 18]:   # Kürbisse auf den Stufen
		_disc(img, Vector2(x, 84), 4.0, Color(0.9, 0.45, 0.08))


static func _person(rng: RandomNumberGenerator, x: float, head_y: float, s: float, coat := Color(-1, 0, 0),
		hair := Color(-1, 0, 0), style := "") -> Dictionary:
	if coat.r < 0.0:
		coat = Color.from_hsv(rng.randf(), rng.randf_range(0.2, 0.6), rng.randf_range(0.25, 0.7))
	if hair.r < 0.0:
		hair = [Color(0.1, 0.08, 0.06), Color(0.35, 0.22, 0.1), Color(0.7, 0.6, 0.4), Color(0.6, 0.6, 0.6)].pick_random()
	var skin := Color(0.88, 0.7, 0.58).lerp(Color(0.45, 0.3, 0.2), rng.randf() * 0.6)
	return {"x": x + rng.randf_range(-2, 2), "y": head_y + rng.randf_range(-2, 2), "s": s, "coat": coat, "hair": hair, "skin": skin,
		"style": style}


static func _draw_person(img: Image, p: Dictionary) -> void:
	var x: float = p["x"]
	var y: float = p["y"]
	var s: float = p["s"]
	var coat: Color = p["coat"]
	var r := 5.0 * s
	for row in range(int(y + r), H):   # Körper: Schultern, nach unten etwas breiter
		var half := 8.0 * s + (row - y - r) * 0.08
		for col in range(int(x - half), int(x + half) + 1):
			_put(img, col, row, coat * (0.85 + 0.15 * float((col + row) % 3 == 0)))
	var face: Color = p["skin"]
	if p["style"] == "soot":
		face = face.darkened(0.45)
	_disc(img, Vector2(x, y), r, face)
	var hair: Color = p["hair"]
	for col in range(int(x - r), int(x + r) + 1):   # Haar oben
		for row in range(int(y - r), int(y - r * 0.3)):
			if Vector2(col - x, row - y).length() <= r:
				_put(img, col, row, hair)
	match p["style"]:
		"braids":
			for side in [-1.0, 1.0]:
				for k in 6:
					_put(img, int(x + side * (r + 0.5)), int(y + k), hair)
		"fringe":
			for col in range(int(x - r), int(x + r) + 1):
				_put(img, col, int(y - r * 0.2), hair)
	_put(img, int(x - r * 0.35), int(y), Color(0.05, 0.04, 0.04))   # Augen
	_put(img, int(x + r * 0.35), int(y), Color(0.05, 0.04, 0.04))


## Der alte Herr hinten rechts: groß, dunkler Anzug, weißes Haar, Gehstock – auf jedem Foto Pixel für Pixel gleich.
static func _draw_heir(img: Image) -> void:
	var p := {"x": W - 14.0, "y": 45.0, "s": 0.92, "coat": Color(0.08, 0.08, 0.09), "hair": Color(0.92, 0.92, 0.9),
		"skin": Color(0.82, 0.72, 0.65), "style": ""}
	_draw_person(img, p)
	for row in range(58, 96):
		_put(img, W - 4, row, Color(0.25, 0.15, 0.08))   # Gehstock
	_put(img, W - 5, 58, Color(0.6, 0.5, 0.2))


## Verwischt, als hätte er sich bewegt: waagerecht verschmiert und blass.
static func _smear(img: Image, p: Dictionary) -> void:
	var x := int(p["x"])
	var y := int(p["y"])
	var s: float = p["s"]
	var rect := Rect2i(x - int(12 * s), y - int(7 * s), int(24 * s), H - y + int(7 * s))
	var copy := img.duplicate() as Image
	for row in range(rect.position.y, mini(H, rect.end.y)):
		for col in range(maxi(0, rect.position.x), mini(W, rect.end.x)):
			var sum := Color(0, 0, 0)
			var n := 0
			for k in range(-6, 7, 2):
				var c := clampi(col + k, 0, W - 1)
				sum += copy.get_pixel(c, row)
				n += 1
			img.set_pixel(col, row, (sum / n).lerp(Color(0.7, 0.68, 0.64), 0.25))


## Alter: vergilbt und flau (je älter, desto mehr), Körnung, Rand, bei alten Kratzer.
static func _age(img: Image, year: int, rng: RandomNumberGenerator) -> void:
	var old := clampf((2026.0 - year) / 39.0, 0.0, 1.0)
	var sepia := clampf(old * 1.3 - 0.3, 0.0, 1.0)
	for row in H:
		for col in W:
			var c := img.get_pixel(col, row)
			var lum := c.r * 0.3 + c.g * 0.55 + c.b * 0.15
			var aged := Color(lum * 1.1 + 0.08, lum * 0.92 + 0.05, lum * 0.68 + 0.02)
			c = c.lerp(aged, sepia)
			c = c.lerp(Color(0.75, 0.7, 0.6), old * 0.25)   # flau
			c *= 1.0 + rng.randf_range(-0.06, 0.06) * (0.4 + old)
			var d := Vector2(col - W / 2.0, row - H / 2.0) / Vector2(W, H)
			c *= 1.0 - d.length_squared() * (1.2 + old)
			img.set_pixel(col, row, c.clamp())
	for k in int(old * 6.0):   # Kratzer
		var x := rng.randi_range(0, W - 1)
		for row in range(rng.randi_range(0, H / 2), rng.randi_range(H / 2, H)):
			_put(img, x, row, Color(0.85, 0.82, 0.75))


static func _disc(img: Image, c: Vector2, r: float, color: Color) -> void:
	for row in range(int(c.y - r), int(c.y + r) + 1):
		for col in range(int(c.x - r), int(c.x + r) + 1):
			if Vector2(col, row).distance_to(c) <= r:
				_put(img, col, row, color)


static func _put(img: Image, x: int, y: int, color: Color) -> void:
	if x >= 0 and y >= 0 and x < W and y < H:
		img.set_pixel(x, y, color)


## Ein Rahmen mit Foto (oder leer) und Messingschild, [E] sieht es aus der Nähe an.
class PhotoFrame extends StaticBody3D:
	var year := 0
	var wall: PhotoWall

	func build(picture: Texture2D) -> void:
		collision_layer = 4
		collision_mask = 0
		set_meta("interactable", self)
		var wood := Mat.psx(Color(0.22, 0.13, 0.07))
		var outer := PhotoWall.PHOTO + Vector2.ONE * PhotoWall.FRAME * 2.0
		var photo := PhotoWall.PHOTO
		var frame := PhotoWall.FRAME
		for side in [-1.0, 1.0]:   # Leisten
			Geo.mesh(self, Geo.box(Vector3(outer.x, frame, 0.025)), wood, Vector3(0, side * (photo.y + frame) / 2.0, 0.012))
			Geo.mesh(self, Geo.box(Vector3(frame, photo.y, 0.025)), wood, Vector3(side * (photo.x + frame) / 2.0, 0, 0.012))
		var quad := QuadMesh.new()
		quad.size = photo
		var mat: Material
		if picture:
			var m := ShaderMaterial.new()
			m.shader = load("res://shaders/psx_surface.gdshader")
			m.set_shader_parameter("albedo", Color(1, 1, 1))
			m.set_shader_parameter("albedo_tex", picture)
			mat = m
		else:
			mat = Mat.psx(Color(0.12, 0.1, 0.09))   # leerer Rahmen: dunkle Rückwand
		Geo.mesh(self, quad, mat, Vector3(0, 0, 0.004))
		Geo.mesh(self, Geo.box(Vector3(0.12, 0.025, 0.004)), Mat.metal(Color(0.8, 0.65, 0.35)), Vector3(0, -outer.y / 2.0 - 0.03, 0.004))
		Geo.add_box_shape(self, Vector3(outer.x, outer.y + 0.06, 0.04), Vector3(0, -0.02, 0.02))

	func get_prompt(_player: Player) -> String:
		return "Foto ansehen [E] – Halloween %d" % year

	func interact(_player: Player) -> void:
		wall.look_at_photo(year)


## Debug (--fotos[=jahr]): du stehst vor der Fotowand · jahr: das Foto ist gleich aufgeschlagen.
func debug_show(year: String) -> void:
	var mid := Vector3(float(WALL["x"]) + 1.6, 0.05, (float(WALL["z0"]) + float(WALL["z1"])) / 2.0)
	TeleportUI.place_player(mid, Vector3(-1, 0.25, 0))
	if year.is_valid_int() and YEARS.has(year.to_int()):
		get_tree().create_timer(0.5).timeout.connect(look_at_photo.bind(year.to_int()))
