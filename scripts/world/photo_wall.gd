class_name PhotoWall
extends Node3D
## Die Gruppenfotos an der Lobbywand (Spielkonzept 5.14): Jede Ernte seit 1987, alle drei Jahre (2.10), ein Halloween-Foto
## der Gäste vor dem Haupteingang in Holzrahmen – alte vergilbt, neue farbig, zuletzt ein leerer Rahmen „Halloween 2026“.
## Wo das Foto von 2005 hing, ist nur ein hellerer Fleck auf der Tapete mit leerem Nagel (BarePatch).
## Zeichnung im Code (Image, je Jahr fester Zufall): Fassade, zwei Reihen Gäste; wer in jenem Oktober geholt wurde, ist
## verwischt, als hätte er sich bewegt. Ein Gesicht ist auf jedem Foto und altert nie: hinten rechts der weißhaarige alte
## Herr mit Gehstock – der Erbe der Familie, als uralter Dauergast getarnt (2.3). Wer genug Fotos ansieht, merkt es
## (Notizbuch). Auf 1987 außerdem ein Mädchen mit Zöpfen (Marion), ein Mann im Kittel (Josef, der Hausmeister), eine junge Frau
## (Edna) und ein großes Mädchen (Liesel) – die Indiz-Stufe für Marion, Edna und Liesel (2.3, 2.7).
## Ort (ZIM-133): Ausstattung „Fotowand“ im Plan, je Punkt eine Position mit zwei Rahmen übereinander; die Jahre
## spaltenweise von links nach rechts, oben jeweils das ältere. Ohne Planeintrag an WALL.
## Nicht gespeichert; was man gesehen hat, steht im Notizbuch.

## Ohne Planeintrag: Westwand der Lobby, Positionen von z0 bis z1, Bilder nach +X
const WALL := {"x": -7.4, "z0": -27.3, "z1": -21.3}
## Die Ernten (Spielkonzept 2.10): 1987 + 13 × 3 = 2026
const YEARS := [1987, 1990, 1993, 1996, 1999, 2002, 2005, 2008, 2011, 2014, 2017, 2020, 2023, 2026]
## Hängt nicht an der Wand – das Foto liegt im Sekretariat (2.10, ZIM-117)
const MISSING := 2005
## Oberkanten der Rahmen über dem Boden: obere und untere Reihe einer Position (ZIM-133)
const TOPS := [1.90, 1.40]
const GAP := 0.005                ## Abstand der Rahmenrückseite von der Wand
const PHOTO := Vector2(0.4, 0.3)
const FRAME := 0.04               ## Breite der Leiste (= PhotoFrame.PROFILE außen)
const W := 160
const H := 120
## So viele waren in jenem Oktober verschwunden (verwischt auf dem Bild)
## Platzhalter bis zu den Motiven nach 2.10 (ZIM-117)
const TAKEN := {1987: 3, 1990: 2, 1993: 3, 1996: 1, 1999: 2, 2002: 2, 2005: 2, 2008: 3, 2011: 2, 2014: 1, 2017: 3, 2020: 2,
	2023: 2}
const HEIR_SEEN := 4              ## so viele Fotos angesehen (mit 1987 und einem neuen) – dann fällt er auf
const TEXTS := {
	1987: "Halloween 1987. Vorn ein Mädchen mit Zöpfen, vielleicht zwölf, daneben ein großes Mädchen mit Pony und eine junge Frau mit dunklem Haar. Ganz links, halb abgeschnitten, ein Mann im grauen Arbeitskittel, Ruß im Gesicht. Hinten rechts ein alter Herr mit weißem Haar und Gehstock. Drei Gesichter sind verwischt.",
	1990: "Halloween 1990. Weniger Gäste als 1987, niemand lächelt. Hinten rechts der alte Herr mit dem Gehstock.",
	2023: "Halloween 2023, farbig und scharf. Zwei Gesichter sind trotzdem verwischt. Hinten rechts, mit Gehstock und weißem Haar: der alte Herr – genau wie 1987.",
	2026: "Auf der goldenen Plakette steht schon „2026“. Der Rahmen ist leer.",
}
const NOTE_1987 := "Auf dem Gruppenfoto von 1987 in der Lobby: ein Mädchen mit Zöpfen, ein großes Mädchen, eine junge Frau – und ganz links ein Mann im Kittel mit Ruß im Gesicht."
const NOTE_HEIR := "Auf jedem Gruppenfoto seit 1987 steht hinten rechts derselbe weißhaarige Herr mit Gehstock. Er ist auf keinem älter geworden."

var _pictures := {}               ## Jahr → ImageTexture
var _seen := {}                   ## Jahr → angesehen
var _spots: Array[Transform3D] = []   ## Positionen von links nach rechts: Wandfläche am Boden, +Z in den Raum


## Positionen aus dem Plan (LevelBuilder.planned, ZIM-133), von links nach rechts gesehen; ohne Planeintrag WALL.
func setup(builder: LevelBuilder) -> PhotoWall:
	var columns := ceili(YEARS.size() / 2.0)
	for p: Dictionary in builder.planned.get("photo_wall", []):
		var out: Vector2 = p["out"]
		_spots.append(Transform3D(Basis(Vector3.UP, atan2(out.x, out.y)), p["at"]))
	if _spots.is_empty():
		var step: float = (float(WALL["z1"]) - float(WALL["z0"])) / (columns - 1)
		for col in columns:
			_spots.append(Transform3D(Basis(Vector3.UP, PI / 2.0), Vector3(float(WALL["x"]), 0, float(WALL["z0"]) + col * step)))
	elif _spots.size() != columns:
		push_warning("Gebäudeplan: Fotowand hat %d Positionen, gebraucht werden %d" % [_spots.size(), columns])
	var right := func(t: Transform3D) -> float: return t.origin.dot(Vector3.UP.cross(t.basis.z))   # Blick zur Wand
	_spots.sort_custom(func(a: Transform3D, b: Transform3D) -> bool: return right.call(a) < right.call(b))
	return self


func _ready() -> void:
	for i in mini(YEARS.size(), _spots.size() * 2):
		var year: int = YEARS[i]
		var t := _spots[i / 2].translated_local(Vector3(0, TOPS[i % 2] - PHOTO.y / 2.0 - FRAME, GAP))
		if year == MISSING:
			var patch := BarePatch.new()
			patch.transform = t
			add_child(patch)
			continue
		var frame := PhotoFrame.new()
		frame.year = year
		frame.wall = self
		frame.transform = t
		frame.rotation.z = sin(year * 1.7) * 0.025   # nie ganz gerade
		add_child(frame)
		if year != 2026:
			var img := draw_photo(year)
			img.generate_mipmaps()
			_pictures[year] = ImageTexture.create_from_image(img)
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
	if year == 1987:   # Marion, Liesel, Edna vorn; Josef am linken Rand
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


## Ein Rahmen mit Foto (oder leer), [E] sieht es aus der Nähe an (ZIM-134): profilierte Holzleiste ringsum auf Gehrung
## (Wulst am Falz, Kehle, flache Bahn, gerundete Außenkante) im Holz der Vertäfelung, die Faser läuft längs jeder
## Leiste. Hinter Glas mit Staub und Schlieren (cracked: mit Sprung, für das Foto von 2005, ZIM-117), auf der flachen
## Bahn der unteren Leiste die goldene Plakette mit der Jahreszahl (YearPlaque). Ursprung Mitte Wand, Bild nach +Z.
class PhotoFrame extends StaticBody3D:
	## Profil der Leiste von der Bildkante nach außen: (u quer zur Leiste, z aus der Wand) in Metern
	const PROFILE: Array[Vector2] = [Vector2(0.0, 0.004), Vector2(0.0, 0.011), Vector2(0.0015, 0.0135),
		Vector2(0.004, 0.0145), Vector2(0.0065, 0.0135), Vector2(0.008, 0.012), Vector2(0.010, 0.0118),
		Vector2(0.0125, 0.0128), Vector2(0.0148, 0.015), Vector2(0.016, 0.018), Vector2(0.0165, 0.020),
		Vector2(0.034, 0.020), Vector2(0.0365, 0.0193), Vector2(0.0385, 0.0172), Vector2(0.040, 0.014),
		Vector2(0.040, 0.0)]
	## Knicke ab diesem Winkel bleiben hart, flachere werden rund schattiert
	const CREASE_DEG := 40.0
	## Plakette: Mitte der flachen Bahn (u), Höhe der Bahn
	const PLAQUE_U := 0.02525
	const PLAQUE_Z := 0.020
	const PLAQUE_RANGE := 12.0
	## Ebenen hinter dem Falz: Rückwand, Foto, Glas (z)
	const BACK_Z := 0.001
	const PHOTO_Z := 0.003
	const GLASS_Z := 0.0045

	static var _frame_mesh: ArrayMesh
	static var _glass := {}
	static var _plaque_mat: ShaderMaterial

	var year := 0
	var wall: PhotoWall

	func build(picture: Texture2D, cracked := false) -> void:
		collision_layer = 4
		collision_mask = 0
		set_meta("interactable", self)
		var photo := PhotoWall.PHOTO
		var outer := photo + Vector2.ONE * PhotoWall.FRAME * 2.0
		Geo.mesh(self, frame_mesh(), Mat.hotel_wood(), Vector3.ZERO)
		var back := StandardMaterial3D.new()
		back.albedo_color = Color(0.12, 0.1, 0.09)
		back.roughness = 0.9
		Geo.mesh(self, _quad(photo + Vector2.ONE * 0.006), back, Vector3(0, 0, BACK_Z))
		if picture:
			var m := StandardMaterial3D.new()
			m.albedo_texture = picture
			m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
			m.roughness = 0.55   # Fotopapier, seidenmatt
			Geo.mesh(self, _quad(photo + Vector2.ONE * 0.004), m, Vector3(0, 0, PHOTO_Z))
		var glass := Geo.mesh(self, _quad(photo + Vector2.ONE * 0.006), glass_material(cracked), Vector3(0, 0, GLASS_Z))
		glass.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var plaque := Geo.mesh(self, YearPlaque.mesh(str(year)), plaque_material(),
			Vector3(0, -(photo.y / 2.0 + PLAQUE_U), PLAQUE_Z))
		plaque.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		plaque.visibility_range_end = PLAQUE_RANGE
		Geo.add_box_shape(self, Vector3(outer.x, outer.y, 0.022), Vector3(0, 0, 0.011))

	## Die vier Leisten, je Profilpunkt eine Linie von Gehrung zu Gehrung; UVs in Metern (u längs der Leiste, v über das
	## Profil, je Leiste versetzt), für Mat.hotel_wood (mesh_uv)
	static func frame_mesh() -> ArrayMesh:
		if _frame_mesh:
			return _frame_mesh
		var h := PhotoWall.PHOTO / 2.0
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		# Leiste: Richtung nach außen, Richtung längs (XY), Versatz der Maserung
		var rails := [[Vector2(0, 1), Vector2(1, 0), 0.0], [Vector2(0, -1), Vector2(-1, 0), 0.31],
			[Vector2(1, 0), Vector2(0, -1), 0.67], [Vector2(-1, 0), Vector2(0, 1), 1.13]]
		var n := PROFILE.size()
		var seg_n: Array[Vector2] = []
		var arc: Array[float] = [0.0]
		for i in n - 1:
			var d := PROFILE[i + 1] - PROFILE[i]
			seg_n.append(Vector2(-d.y, d.x).normalized())
			arc.append(arc[i] + d.length())
		for rail: Array in rails:
			var out: Vector2 = rail[0]
			var along: Vector2 = rail[1]
			var shift: float = rail[2]
			var half: float = absf(out.dot(h))         # Abstand der Bildkante von der Mitte quer zur Leiste
			var half_len: float = absf(along.dot(h))   # halbe Länge der Bildkante
			for i in n - 1:
				var verts: Array[Vector3] = []
				var norms: Array[Vector3] = []
				var uvs: Array[Vector2] = []
				for k in 2:
					var j := i + k
					var p := PROFILE[j]
					var pn := seg_n[i]
					var other := i - 1 if k == 0 else i + 1
					if other >= 0 and other < seg_n.size() and absf(rad_to_deg(seg_n[i].angle_to(seg_n[other]))) < CREASE_DEG:
						pn = (seg_n[i] + seg_n[other]).normalized()
					var nrm := Vector3(out.x * pn.x, out.y * pn.x, pn.y).normalized()
					for e in [-1.0, 1.0]:   # Gehrung: die Linie reicht bis zur Ecke des Rechtecks mit Abstand u
						var xy: Vector2 = out * (half + p.x) + along * e * (half_len + p.x)
						verts.append(Vector3(xy.x, xy.y, p.y))
						norms.append(nrm)
						uvs.append(Vector2(e * (half_len + p.x) + shift * 3.0, arc[j] + shift))
				# verts: i links, i rechts, i+1 links, i+1 rechts
				var face := (verts[2] - verts[0]).cross(verts[1] - verts[0])
				var order := [0, 1, 3, 0, 3, 2] if face.dot(norms[0] + norms[2]) >= 0.0 else [0, 3, 1, 0, 2, 3]
				for q: int in order:
					st.set_normal(norms[q])
					st.set_uv(uvs[q])
					st.add_vertex(verts[q])
		st.generate_tangents()
		_frame_mesh = st.commit()
		return _frame_mesh

	## Glas: fast klar, Staub und Schlieren als Alpha und Rauheit, unten und in den Ecken mehr Staub; cracked mit
	## Sprung (Einschlag rechts oben, Risse strahlenförmig, zwei Bögen)
	static func glass_material(cracked: bool) -> StandardMaterial3D:
		if _glass.has(cracked):
			return _glass[cracked]
		var size := 512 if cracked else 256
		var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
		var rough := Image.create(size, size, false, Image.FORMAT_L8)
		var wipe := FastNoiseLite.new()
		wipe.seed = 1987
		wipe.frequency = 0.02 * 256.0 / size
		wipe.fractal_octaves = 3
		var grain := FastNoiseLite.new()
		grain.seed = 2026
		grain.frequency = 0.4 * 256.0 / size
		for y in size:
			for x in size:
				var uv := Vector2(x, y) / size
				var edge := minf(minf(uv.x, 1.0 - uv.x), minf(uv.y, 1.0 - uv.y))
				var dust := 0.3 * smoothstep(0.08, 0.0, edge) + 0.2 * smoothstep(0.7, 1.0, uv.y)
				dust += 0.3 * clampf(grain.get_noise_2d(x, y), 0.0, 1.0)
				# Wischspuren: gestreckt schräg über die Scheibe
				var smear := clampf(wipe.get_noise_2d(x * 0.35 + y * 0.9, y * 0.35 - x * 0.2) * 0.5 + 0.5, 0.0, 1.0)
				smear = smoothstep(0.55, 0.85, smear)
				img.set_pixel(x, y, Color(0.82, 0.8, 0.76, clampf(0.01 + 0.06 * dust + 0.015 * smear, 0.0, 1.0)))
				var r := 0.04 + 0.3 * smear + 0.35 * dust
				rough.set_pixel(x, y, Color(r, r, r))
		if cracked:
			_draw_cracks(img, rough, size)
		img.generate_mipmaps()
		rough.generate_mipmaps()
		var m := StandardMaterial3D.new()
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.albedo_texture = ImageTexture.create_from_image(img)
		m.roughness_texture = ImageTexture.create_from_image(rough)
		m.roughness_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_RED
		m.roughness = 1.0
		m.metallic_specular = 0.6
		m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
		_glass[cracked] = m
		return m

	static func _draw_cracks(img: Image, rough: Image, size: int) -> void:
		var rng := RandomNumberGenerator.new()
		rng.seed = 2005
		var hit := Vector2(0.72, 0.3) * size
		for k in 9:
			var dir := Vector2.RIGHT.rotated(TAU * (k + rng.randf_range(-0.3, 0.3)) / 9.0)
			var p := hit
			var length := rng.randf_range(0.25, 0.8) * size
			var walked := 0.0
			while walked < length:
				dir = dir.rotated(rng.randf_range(-0.25, 0.25))
				var step := rng.randf_range(4.0, 10.0)
				_crack_line(img, rough, p, p + dir * step, 1.0 - walked / length)
				p += dir * step
				walked += step
		for ring in [0.06, 0.13]:   # Bögen um den Einschlag
			var r: float = ring * size
			var a0 := rng.randf_range(0.0, TAU)
			var a1 := a0 + rng.randf_range(2.0, 4.5)
			var a := a0
			while a < a1:
				var b := a + 0.12
				_crack_line(img, rough, hit + Vector2.RIGHT.rotated(a) * r,
					hit + Vector2.RIGHT.rotated(b) * r * rng.randf_range(0.95, 1.05), 0.8)
				a = b

	## Riss von a nach b (Pixel), Stärke 0 … 1: heller Strich, dort rau
	static func _crack_line(img: Image, rough: Image, a: Vector2, b: Vector2, strength: float) -> void:
		var steps := ceili(a.distance_to(b) * 2.0)
		for s in steps + 1:
			var p := a.lerp(b, float(s) / maxf(steps, 1))
			var x := int(p.x)
			var y := int(p.y)
			if x < 0 or y < 0 or x >= img.get_width() or y >= img.get_height():
				continue
			img.set_pixel(x, y, Color(0.92, 0.92, 0.9, maxf(img.get_pixel(x, y).a, 0.25 + 0.45 * strength)))
			rough.set_pixel(x, y, Color(0.6, 0.6, 0.6))

	## Gold aller Plaketten (Spielkonzept 9.2): Satz aus tools/year_plaque.gd über die UVs gespannt
	static func plaque_material() -> ShaderMaterial:
		if _plaque_mat == null:
			_plaque_mat = Mat.photo(YearPlaque.ALBEDO, 1.0, YearPlaque.NORMAL, YearPlaque.ROUGH, 0.5, Color(1, 1, 1),
				false, true).duplicate()
			_plaque_mat.set_shader_parameter("metallic", YearPlaque.METALLIC)
		return _plaque_mat

	static func _quad(size: Vector2) -> QuadMesh:
		var q := QuadMesh.new()
		q.size = size
		return q

	func get_prompt(_player: Player) -> String:
		return "Foto ansehen [E] – Halloween %d" % year

	func interact(_player: Player) -> void:
		wall.look_at_photo(year)


## Wo das Foto von 2005 hing (Spielkonzept 2.10): die Tapete darunter ist heller geblieben (Decal, weicher Rand),
## oben in der Mitte steckt der leere Nagel. Ursprung Mitte des fehlenden Rahmens an der Wand, +Z in den Raum.
class BarePatch extends StaticBody3D:
	const NAIL_Y := 0.12              ## Nagel über der Mitte
	const TEX := Vector2i(512, 384)
	## So viel heller als die vergilbte Tapete ringsum – die Mischung ist linear, wenig Deckkraft reicht
	const BRIGHTER := Color(1.0, 0.95, 0.88, 0.05)

	static var _tex: ImageTexture
	static var _nail_mat: StandardMaterial3D

	func _ready() -> void:
		collision_layer = 4
		collision_mask = 0
		set_meta("interactable", self)
		var size := PhotoWall.PHOTO + Vector2.ONE * PhotoWall.FRAME * 2.0
		var d := Decal.new()
		d.size = Vector3(size.x, 0.1, size.y)
		d.position = Vector3(0, 0, -PhotoWall.GAP)
		d.rotation.x = PI / 2.0   # projiziert entlang -Y, also auf die Wand
		d.texture_albedo = _texture()
		d.modulate = BRIGHTER
		d.upper_fade = 0.1
		d.lower_fade = 0.1
		add_child(d)
		var shank := Geo.mesh(self, Geo.cylinder(0.0014, 0.02, 8), _nail_material(), Vector3(0, NAIL_Y, 0.002))
		shank.rotation.x = PI / 2.0 - 0.35   # schräg nach unten eingeschlagen
		var head := Geo.mesh(self, Geo.cylinder(0.0035, 0.0012, 12), _nail_material(), Vector3(0, NAIL_Y + 0.0034, 0.0114))
		head.rotation.x = PI / 2.0 - 0.35
		Geo.add_box_shape(self, Vector3(size.x, size.y, 0.02), Vector3(0, 0, 0.0))

	func get_prompt(_player: Player) -> String:
		return "Heller Fleck auf der Tapete – hier hing ein Bild, der Nagel steckt noch"

	func interact(_player: Player) -> void:
		pass

	## Weiß mit weichem, leicht unregelmäßigem Rand – wie der Rahmen die Tapete vor Licht und Rauch geschützt hat
	static func _texture() -> ImageTexture:
		if _tex:
			return _tex
		var img := Image.create(TEX.x, TEX.y, false, Image.FORMAT_RGBA8)
		var noise := FastNoiseLite.new()
		noise.seed = 2005
		noise.frequency = 0.02
		var soft := 10.0   # Pixel weicher Rand
		for y in TEX.y:
			for x in TEX.x:
				var edge := minf(minf(x + 0.5, TEX.x - x - 0.5), minf(y + 0.5, TEX.y - y - 0.5))
				var a := clampf((edge - 2.0 + noise.get_noise_2d(x, y) * 3.0) / soft, 0.0, 1.0)
				a *= 0.9 + 0.1 * noise.get_noise_2d(x * 3.0 + 400.0, y * 3.0)   # nicht ganz gleichmäßig
				img.set_pixel(x, y, Color(1, 1, 1, a))
		img.generate_mipmaps()
		_tex = ImageTexture.create_from_image(img)
		return _tex

	static func _nail_material() -> StandardMaterial3D:
		if not _nail_mat:
			_nail_mat = StandardMaterial3D.new()
			_nail_mat.albedo_color = Color(0.32, 0.3, 0.28)
			_nail_mat.metallic = 0.85
			_nail_mat.roughness = 0.5
		return _nail_mat


## Debug (--fotos[=jahr]): du stehst vor der Fotowand · jahr: das Foto ist gleich aufgeschlagen.
func debug_show(year: String) -> void:
	var a := _spots[0].origin
	var b := _spots[-1].origin
	var out := _spots[0].basis.z
	TeleportUI.place_player((a + b) / 2.0 + out * 2.4 + Vector3.UP * 0.05, -out + Vector3.UP * 0.25)
	if year.is_valid_int() and YEARS.has(year.to_int()) and year.to_int() != MISSING:
		get_tree().create_timer(0.5).timeout.connect(look_at_photo.bind(year.to_int()))
