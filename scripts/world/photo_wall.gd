class_name PhotoWall
extends Node3D
## Die Fotos an der Lobbywand (Spielkonzept 5.14, 2.10): je Ernte, alle drei Jahre seit 1987, das Ankunftsfoto der Gäste
## vom 1. Oktober vor dem Haupteingang in Holzrahmen – alte vergilbt, neue farbig, zuletzt der Rahmen „Halloween 2026“.
## Zeichnung im Code (Image, je Jahr fester Zufall), Platzhalter bis zu echten Bildern (ZIM-135): Fassade am Tag, die
## Gäste in Reihen, Koffer vorn. Wer in jener Ernte geholt wurde, ist verwischt, als hätte er sich bewegt – in Ernten
## ohne Schlüssel jedes Gesicht; Überlebende gab es nur 1987 und 2005 (TAKEN). Ein Gesicht ist auf jedem Foto scharf
## und altert nie: hinten rechts der weißhaarige alte Herr mit Gehstock, Gründer und Direktor, nur auf den Fotos zu sehen
## (2.10). Wer genug Fotos ansieht, merkt es (Notizbuch). Auf 1987 außerdem ein Mädchen mit Zöpfen (Marion), ein Mann im
## Kittel (Josef, der Hausmeister), eine junge Frau (Edna) und ein großes Mädchen (Liesel) – die Indiz-Stufe für Marion,
## Edna und Liesel (2.3, 2.7).
##   · 2005 hängt nicht: Wo es hing, ist ein hellerer Fleck mit leerem Nagel (BarePatch). Das Foto liegt mit gesprungenem
##     Glas in der Mittelschublade des Sekretariatsschreibtischs (found_photo, Desk, DirectorOffice.PHOTO_DRAWER): scharf
##     Rudolf Hain mit Koffer, links und rechts verwischt Clara Vogt (13) und Martin Ebert (018), auf der Rückseite die
##     Namen (7.4, Hinweise Vorschlag aus ZIM-12).
##   · 2026: Ab dem Morgen des 2. Oktober (ARRIVAL_DAY, HotelRegister.CROSS_HOUR) hängt das Ankunftsfoto im leeren
##     Rahmen – alle Gäste und die Spielfigur, hinten rechts der alte Herr, der bei der Ankunft nicht dort stand. Wessen
##     Kreuz im Hotelregister steht (HotelRegister.is_crossed, ab 6 Uhr am Morgen nach dem Tod), der ist verwischt;
##     _process sieht alle CHECK_EVERY s nach und zeichnet bei Änderung neu.
## Ort (ZIM-133): Ausstattung „Fotowand“ im Plan, je Punkt eine Position mit zwei Rahmen übereinander; die Jahre
## spaltenweise von links nach rechts, oben jeweils das ältere. Ohne Planeintrag an WALL.
## Nicht gespeichert – das Foto 2026 folgt aus Uhrzeit und Register; was man gesehen hat, steht im Notizbuch.

## Ohne Planeintrag: Westwand der Lobby, Positionen von z0 bis z1, Bilder nach +X
const WALL := {"x": -7.4, "z0": -27.3, "z1": -21.3}
## Die Ernten (Spielkonzept 2.10): 1987 + 13 × 3 = 2026
const YEARS := [1987, 1990, 1993, 1996, 1999, 2002, 2005, 2008, 2011, 2014, 2017, 2020, 2023, 2026]
## Hängt nicht an der Wand – das Foto liegt im Sekretariat (2.10, ZIM-117)
const MISSING := 2005
const CURRENT := 2026
## Oberkanten der Rahmen über dem Boden: obere und untere Reihe einer Position (ZIM-133)
const TOPS := [1.90, 1.40]
const GAP := 0.005                ## Abstand der Rahmenrückseite von der Wand
const PHOTO := Vector2(0.4, 0.3)
const FRAME := 0.04               ## Breite der Leiste (= PhotoFrame.PROFILE außen)
const W := 160
const H := 120
## Ernten mit Überlebenden: so viele wurden geholt (verwischt, Kreuze im Register). In allen anderen ist jedes Gesicht
## verwischt außer dem des alten Herrn (2.10). 2005: Clara Vogt und Martin Ebert.
const TAKEN := {1987: 3, 2005: 2}
## Ab diesem Tag (um HotelRegister.CROSS_HOUR) hängt das Ankunftsfoto 2026 im Rahmen
const ARRIVAL_DAY := 2
const CHECK_EVERY := 5.0
## Kopf des alten Herrn (Pixel) – bleibt beim Verwischen scharf
const OLD_MAN := Vector2(W - 14.0, 45.0)
const OLD_MAN_SEEN := 4           ## so viele Fotos angesehen (mit 1987 und einem neuen) – dann fällt er auf
const TEXTS := {
	1987: "Halloween 1987. Ankunft vor dem Haupteingang. Vorn ein Mädchen mit Zöpfen, vielleicht zwölf, daneben ein großes Mädchen mit Pony und eine junge Frau mit dunklem Haar. Ganz links, halb abgeschnitten, ein Mann im grauen Arbeitskittel, Ruß im Gesicht. Hinten rechts ein alter Herr mit weißem Haar und Gehstock. Drei Gesichter sind verwischt.",
	1990: "Halloween 1990. Wieder vor dem Haupteingang, wieder die Koffer vorn. Kein Gesicht ist zu erkennen – alle verwischt, als hätten sie sich bewegt. Bis auf eines: hinten rechts der alte Herr mit dem Gehstock. Er sieht aus wie 1987.",
	2023: "Halloween 2023, farbig und scharf gedruckt – und doch ist jedes Gesicht verwischt. Nur hinten rechts, mit Gehstock und weißem Haar: der alte Herr, genau wie 1987.",
	2026: "Auf der goldenen Plakette steht schon „2026“. Der Rahmen ist leer.",
}
## Ernte ohne Schlüssel, ohne eigenen Text
const ALL_TAKEN_TEXT := "Halloween %d. Ankunft vor dem Haupteingang, die Gäste in zwei Reihen, Koffer zu ihren Füßen. Kein Gesicht ist zu erkennen – alle verwischt, als hätten sie sich bewegt. Nur einer ist scharf: hinten rechts der alte Herr mit dem Gehstock."
const FOUND_TEXT := "Halloween 2005. Das Glas ist gesprungen. Die Gäste vor dem Haupteingang, und anders als an der Wand sind die meisten Gesichter scharf. Vorn in der Mitte ein Mann mit einem Koffer. Links und rechts von ihm zwei verwischte Gestalten: Die eine hält einen Zimmerschlüssel mit großem Anhänger – „13“ –, die andere trägt eine Taschenlampe mit violettem Aufsatz am Gürtel. Hinten rechts der alte Herr mit dem Gehstock.\n\nAuf der Rückseite, in Bleistift: „Vogt · Ebert · Hain – 1. Oktober 2005“"
const ARRIVAL_TEXT := "Halloween 2026. Das Ankunftsfoto vom 1. Oktober, über Nacht gerahmt. Du stehst selbst vorn in der Mitte. Hinten rechts, wo bei der Ankunft niemand stand: der alte Herr mit dem Gehstock."
const NOTE_1987 := "Auf dem Gruppenfoto von 1987 in der Lobby: ein Mädchen mit Zöpfen, ein großes Mädchen, eine junge Frau – und ganz links ein Mann im Kittel mit Ruß im Gesicht."
const NOTE_OLD_MAN := "Auf jedem Gruppenfoto seit 1987 steht hinten rechts derselbe weißhaarige Herr mit Gehstock. Er ist auf keinem älter geworden."
const NOTE_2005 := "Das Foto von 2005 lag im Sekretariat. Fast alle Gesichter sind scharf, verwischt nur zwei – „Vogt“ und „Ebert“, sagt die Rückseite. Scharf zwischen ihnen „Hain“, mit Koffer."
const NOTE_2026 := "Unser Ankunftsfoto hängt an der Fotowand. Hinten rechts steht der alte Herr – bei der Ankunft stand dort niemand."

var _pictures := {}               ## Jahr → ImageTexture
var _seen := {}                   ## Jahr → angesehen
var _spots: Array[Transform3D] = []   ## Positionen von links nach rechts: Wandfläche am Boden, +Z in den Raum
var _frame_now: PhotoFrame        ## Rahmen 2026
var _hung := false                ## das Ankunftsfoto 2026 hängt
var _blurred_key := ""            ## wer auf dem Foto 2026 verwischt ist (zuletzt gezeichnet)
var _blurred_now := 0
var _check := 0.0

static var _found_tex: ImageTexture


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
		if year == CURRENT:   # leer, bis das Ankunftsfoto hängt (_update_current)
			_pictures[year] = ImageTexture.create_from_image(Image.create(W, H, true, Image.FORMAT_RGB8))
			_frame_now = frame
		else:
			var img := draw_photo(year)
			img.generate_mipmaps()
			_pictures[year] = ImageTexture.create_from_image(img)
		frame.build(_pictures.get(year))
		if year == CURRENT:
			frame.photo_mesh.visible = false


func _process(delta: float) -> void:
	_check -= delta
	if _check > 0.0:
		return
	_check = CHECK_EVERY
	if Game.director and Game.social:
		_update_current(Game.director.elapsed)


## Das Foto 2026 zum Zeitpunkt now: ab dem Morgen des 2. Oktober im Rahmen, verwischt, wessen Kreuz steht.
func _update_current(now: float) -> void:
	if _frame_now == null:
		return
	var hang := now >= Calendar.at(ARRIVAL_DAY, HotelRegister.CROSS_HOUR)
	_frame_now.photo_mesh.visible = hang
	if not hang:
		_hung = false
		return
	var crowd := _crowd()
	var blurred := crowd.filter(func(p: Dictionary) -> bool: return p.get("blurred", false))
	var key := ",".join(PackedStringArray(blurred.map(func(p: Dictionary) -> String: return str(p["seed"]))))
	if _hung and key == _blurred_key:
		return
	_hung = true
	_blurred_key = key
	_blurred_now = blurred.size()
	var img := draw_photo(CURRENT, crowd)
	img.generate_mipmaps()
	(_pictures[CURRENT] as ImageTexture).update(img)


## Wer 2026 auf dem Foto steht: alle Gäste (fest nach ID) und zuletzt die Spielfigur.
func _crowd() -> Array:
	var out: Array = []
	for g: Guest in Game.social.guests:
		out.append({"seed": hash(g.id), "child": g.is_child(), "blurred": Game.register != null and Game.register.is_crossed(g)})
	out.append({"seed": 13, "player": true})
	return out


func picture(year: int) -> Texture2D:
	return _found_tex if year == MISSING else _pictures.get(year)


## Ein Foto angesehen: Text, ins Notizbuch, was auffällt.
func look_at_photo(year: int) -> void:
	_seen[year] = true
	var text := String(TEXTS.get(year, ALL_TAKEN_TEXT % year))
	if year == MISSING:
		text = FOUND_TEXT
	elif year == CURRENT and _hung:
		text = ARRIVAL_TEXT
		if _blurred_now > 0:
			text += " Ein Gesicht ist verwischt." if _blurred_now == 1 else " %d Gesichter sind verwischt." % _blurred_now
	if Game.menus:
		Game.menus.open_photo("Halloween %d" % year, picture(year), text)
	if Game.notebook:
		if year == 1987:
			Game.notebook.add_note("photo_1987", NOTE_1987, "Fotowand")
		elif year == MISSING:
			Game.notebook.add_note("photo_2005", NOTE_2005, "Foto im Sekretariat")
		elif year == CURRENT and _hung:
			Game.notebook.add_note("photo_2026", NOTE_2026, "Fotowand")
		# ID von früher („heir“), damit die Notiz in alten Spielständen nicht doppelt kommt
		if _seen.size() >= OLD_MAN_SEEN and _seen.has(1987) and _seen.keys().any(func(y: int) -> bool: return y >= 2015 and y != CURRENT):
			Game.notebook.add_note("photo_heir", NOTE_OLD_MAN, "Fotowand")


## Das Foto von 2005 als Fundstück (Sekretariat, Desk): Rahmen mit gesprungenem Glas, Ursprung Mitte der Rückseite,
## Bild nach +Z.
static func found_photo() -> PhotoFrame:
	if _found_tex == null:
		var img := draw_photo(MISSING)
		img.generate_mipmaps()
		_found_tex = ImageTexture.create_from_image(img)
	var frame := PhotoFrame.new()
	frame.year = MISSING
	frame.found = true
	frame.build(_found_tex, true)
	return frame


# --- Zeichnen ---------------------------------------------------------------------------------------

## Das Foto einer Ernte: fest aus dem Jahr gewürfelt, nur die Sonderfiguren sind gesetzt; crowd nur 2026 (_crowd).
static func draw_photo(year: int, crowd: Array = []) -> Image:
	var rng := RandomNumberGenerator.new()
	rng.seed = year * 7919
	var img := Image.create(W, H, false, Image.FORMAT_RGB8)
	_facade(img, rng)
	var rows := photo_rows(year, rng, crowd)
	for i in rows.size():   # hintere Reihe zuerst, der alte Herr ganz rechts dahinter
		for p: Dictionary in rows[i]:
			_draw_person(img, p)
		if i == 0:
			_draw_old_man(img)
	var taken: Array = []
	for row: Array in rows:
		taken.append_array(row.filter(func(p: Dictionary) -> bool: return p.get("taken", false)))
	_smear(img, taken)
	_suitcases(img, rng, rows[-1])
	_age(img, year, rng)
	return img


## Die Leute auf dem Foto in Reihen von hinten nach vorn, je {x, y, s, coat, hair, skin, style, taken}. Ohne rng: fest
## aus dem Jahr (für Prüfungen).
static func photo_rows(year: int, rng: RandomNumberGenerator = null, crowd: Array = []) -> Array:
	if rng == null:
		rng = RandomNumberGenerator.new()
		rng.seed = year * 7919
		_facade(Image.create(W, H, false, Image.FORMAT_RGB8), rng)   # gleiche Würfe wie draw_photo
	if year == CURRENT:
		return _crowd_rows(crowd)
	var back: Array = []
	var front: Array = []
	var n_back := rng.randi_range(6, 8)
	for i in n_back:
		back.append(_person(rng, 14.0 + i * (W - 50.0) / n_back, 52.0, 0.85))
	var n_front := rng.randi_range(5, 7)
	for i in n_front:
		front.append(_person(rng, 18.0 + i * (W - 36.0) / n_front, 66.0, 1.05))
	if year == 1987:   # Marion, Liesel, Edna vorn; Josef am linken Rand
		front[1] = _person(rng, front[1]["x"], 74.0, 0.78, Color(0.5, 0.2, 0.2), Color(0.35, 0.22, 0.12), "braids")
		front[2] = _person(rng, front[2]["x"], 68.0, 0.95, Color(0.2, 0.3, 0.45), Color(0.55, 0.4, 0.2), "fringe")
		front[3] = _person(rng, front[3]["x"], 66.0, 1.02, Color(0.45, 0.4, 0.35), Color(0.1, 0.08, 0.06), "edna")
		front.append(_person(rng, 3.0, 58.0, 1.05, Color(0.42, 0.42, 0.4), Color(0.12, 0.1, 0.08), "soot"))
	var people := back + front
	if year == MISSING:   # Hain vorn in der Mitte mit Koffer, links Clara, rechts Martin – geholt
		var mid := n_front / 2
		front[mid]["style"] = "suitcase"
		front[mid - 1]["taken"] = true
		front[mid + 1]["taken"] = true
	elif TAKEN.has(year):
		var candidates := range(people.size()).filter(func(i: int) -> bool: return people[i]["style"] == "")
		candidates.sort_custom(func(a: int, b: int) -> bool: return hash(year * 31 + a) < hash(year * 31 + b))
		for k in mini(int(TAKEN[year]), candidates.size()):
			people[candidates[k]]["taken"] = true
	else:
		for p: Dictionary in people:
			p["taken"] = true
	return [back, front]


## 2026: alle Gäste in vier Reihen, Kinder und die Spielfigur (Mitte) vorn, hinten rechts Platz für den alten Herrn.
static func _crowd_rows(crowd: Array) -> Array:
	var ordered := crowd.filter(func(p: Dictionary) -> bool: return p.get("child", false) and not p.get("player", false))
	ordered.append_array(crowd.filter(func(p: Dictionary) -> bool: return not p.get("child", false) and not p.get("player", false)))
	var rows_n := 4
	var per := maxi(1, ceili((ordered.size() + 1) / float(rows_n)))
	var me := crowd.filter(func(p: Dictionary) -> bool: return p.get("player", false))
	if not me.is_empty():
		ordered.insert(mini(per / 2, ordered.size()), me[0])
	var heads := [80.0, 66.0, 54.0, 43.0]   # von vorn nach hinten
	var sizes := [0.95, 0.82, 0.7, 0.6]
	var rows: Array = []
	for r in rows_n:
		var chunk := ordered.slice(r * per, (r + 1) * per)
		var x0 := 8.0
		var x1 := W - (30.0 if r == rows_n - 1 else 8.0)
		var row: Array = []
		for i in chunk.size():
			var who: Dictionary = chunk[i]
			var rng := RandomNumberGenerator.new()
			rng.seed = int(who["seed"])
			var x := x0 + (i + 0.5) * (x1 - x0) / chunk.size()
			var s: float = sizes[r] * (0.8 if who.get("child", false) else 1.0)
			var p := _person(rng, x, heads[r] + (4.0 if who.get("child", false) else 0.0), s)
			if who.get("player", false):
				p["coat"] = Color(0.16, 0.2, 0.26)
			p["taken"] = who.get("blurred", false)
			row.append(p)
		rows.push_front(row)
	return rows


## Fassade am Nachmittag des 1. Oktober: grauer Herbsthimmel, dunkle Fenster, der Haupteingang, Stufen mit Kürbissen.
static func _facade(img: Image, rng: RandomNumberGenerator) -> void:
	img.fill(Color(0.42, 0.36, 0.3))
	img.fill_rect(Rect2i(0, 0, W, 16), Color(0.62, 0.64, 0.66))   # Herbsthimmel über dem Dach
	for x in range(6, W, 22):   # Fenster
		for y in [22, 42]:
			img.fill_rect(Rect2i(x, y, 10, 12), Color(0.22, 0.24, 0.26) if rng.randf() < 0.6 else Color(0.12, 0.1, 0.1))
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
		hair = [Color(0.1, 0.08, 0.06), Color(0.35, 0.22, 0.1), Color(0.7, 0.6, 0.4), Color(0.6, 0.6, 0.6)][rng.randi_range(0, 3)]
	var skin := Color(0.88, 0.7, 0.58).lerp(Color(0.45, 0.3, 0.2), rng.randf() * 0.6)
	return {"x": x + rng.randf_range(-2, 2), "y": head_y + rng.randf_range(-2, 2), "s": s, "coat": coat, "hair": hair, "skin": skin,
		"style": style, "taken": false}


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
static func _draw_old_man(img: Image) -> void:
	var p := {"x": OLD_MAN.x, "y": OLD_MAN.y, "s": 0.92, "coat": Color(0.08, 0.08, 0.09), "hair": Color(0.92, 0.92, 0.9),
		"skin": Color(0.82, 0.72, 0.65), "style": ""}
	_draw_person(img, p)
	for row in range(58, 96):
		_put(img, W - 4, row, Color(0.25, 0.15, 0.08))   # Gehstock
	_put(img, W - 5, 58, Color(0.6, 0.5, 0.2))


## Verwischt, als hätte er sich bewegt: waagerecht verschmiert und blass – alle auf einmal über eine Maske, der Kopf
## und der Stock des alten Herrn bleiben scharf.
static func _smear(img: Image, people: Array) -> void:
	if people.is_empty():
		return
	var mask := PackedByteArray()
	mask.resize(W * H)
	for p: Dictionary in people:
		var x := int(p["x"])
		var y := int(p["y"])
		var s: float = p["s"]
		for row in range(maxi(0, y - int(7 * s)), H):
			for col in range(maxi(0, x - int(12 * s)), mini(W, x + int(12 * s))):
				mask[row * W + col] = 1
	var copy := img.duplicate() as Image
	var sums := PackedColorArray()   # Summen je Zeile: Mittel über 13 Pixel waagerecht
	sums.resize(W + 1)
	for row in H:
		if mask.slice(row * W, (row + 1) * W).count(1) == 0:
			continue
		for col in W:
			sums[col + 1] = sums[col] + copy.get_pixel(col, row)
		for col in W:
			if mask[row * W + col] == 0 or col >= W - 6 or Vector2(col, row).distance_to(OLD_MAN) < 6.5:
				continue
			var a := maxi(0, col - 6)
			var b := mini(W, col + 7)
			img.set_pixel(col, row, ((sums[b] - sums[a]) / float(b - a)).lerp(Color(0.7, 0.68, 0.64), 0.25))


## Koffer vorn auf den Stufen (Ankunft), scharf auch vor Verwischten; neben dem mit style „suitcase“ (Hain 2005) einer
## mit hellem Namensschild.
static func _suitcases(img: Image, rng: RandomNumberGenerator, front: Array) -> void:
	for k in rng.randi_range(3, 5):
		_suitcase(img, rng.randi_range(6, W - 18), rng.randi_range(102, 110), false)
	for p: Dictionary in front:
		if p["style"] == "suitcase":
			_suitcase(img, int(p["x"]) + 5, 100, true)


static func _suitcase(img: Image, x: int, y: int, tag: bool) -> void:
	img.fill_rect(Rect2i(x, y, 12, 8), Color(0.32, 0.2, 0.12))
	img.fill_rect(Rect2i(x, y + 3, 12, 1), Color(0.22, 0.14, 0.08))
	img.fill_rect(Rect2i(x + 4, y - 2, 4, 1), Color(0.15, 0.1, 0.06))   # Griff
	if tag:
		img.fill_rect(Rect2i(x + 8, y + 1, 3, 2), Color(0.9, 0.86, 0.75))


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
## found: das Foto von 2005 in der Schublade im Sekretariat (PhotoWall.found_photo) – ohne wall, liest über Game.photo_wall.
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
	var found := false
	var photo_mesh: MeshInstance3D   ## das Bild hinter dem Glas (2026 versteckt, bis das Ankunftsfoto hängt)

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
			photo_mesh = Geo.mesh(self, _quad(photo + Vector2.ONE * 0.004), m, Vector3(0, 0, PHOTO_Z))
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
		if found:
			return "Gerahmtes Foto ansehen [E] – das Glas ist gesprungen"
		return "Foto ansehen [E] – Halloween %d" % year

	func interact(_player: Player) -> void:
		var w := wall if wall else Game.photo_wall
		if w:
			w.look_at_photo(year)


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


## Debug (--fotos[=jahr|pruefen]): du stehst vor der Fotowand · jahr: das Foto ist gleich aufgeschlagen (2005: das Foto
## aus dem Sekretariat) · pruefen: _check.
func debug_show(year: String) -> void:
	var a := _spots[0].origin
	var b := _spots[-1].origin
	var out := _spots[0].basis.z
	TeleportUI.place_player((a + b) / 2.0 + out * 2.4 + Vector3.UP * 0.05, -out + Vector3.UP * 0.25)
	if year == "pruefen":
		_check_harvest()
	elif year.is_valid_int() and YEARS.has(year.to_int()):
		get_tree().create_timer(0.5).timeout.connect(look_at_photo.bind(year.to_int()))


## Prüfung der Ernte alle drei Jahre (Spielkonzept 2.10, ZIM-117/ZIM-17): Rahmen und Fleck, wer auf den Fotos verwischt
## ist, das Foto 2005 in der Schublade im Sekretariat, Kreuze im Register nur in Erntejahren, Zettel und Bleistiftseite,
## Walter und Oskar, das Ankunftsfoto 2026 ab dem 2. und mit Gustavs Kreuz verwischt. Meldet „[Fotowand] … ok“ bzw.
## „FEHLER“, zuletzt „[Fotowand] Prüfung fertig“.
func _check_harvest() -> void:
	var check := func(text: String, ok: bool) -> void:
		print("[Fotowand] %s: %s" % [text, "ok" if ok else "FEHLER"])
	var taken := func(year: int) -> Vector2i:   # verwischt, alle
		var n := Vector2i.ZERO
		for row: Array in photo_rows(year):
			for p: Dictionary in row:
				n += Vector2i(1 if p["taken"] else 0, 1)
		return n
	var crosses := func(rows: Array) -> Vector2i:   # Zeilen mit Kreuz, alle
		var n := Vector2i.ZERO
		for row: Dictionary in rows:
			n += Vector2i(1 if not (row["crosses"] as Array).is_empty() else 0, 1)
		return n
	var frames := get_children().filter(func(n: Node) -> bool: return n is PhotoFrame)
	var patches := get_children().filter(func(n: Node) -> bool: return n is BarePatch)
	check.call("13 Rahmen und der Fleck von 2005", frames.size() == YEARS.size() - 1 and patches.size() == 1)
	check.call("1987: drei verwischt", taken.call(1987).x == 3)
	var t2005: Vector2i = taken.call(2005)
	check.call("2005: zwei verwischt", t2005.x == 2 and t2005.y > 6)
	var all_taken := true
	for year: int in YEARS:
		if year != CURRENT and not TAKEN.has(year):
			var t: Vector2i = taken.call(year)
			all_taken = all_taken and t.x == t.y and t.y > 0
	check.call("ohne Schlüssel alle verwischt", all_taken)
	var desk: Desk = null
	for node in get_tree().get_nodes_in_group("desks"):
		if (node as Desk).variant == "sekretariat":
			desk = node
	var found: PhotoFrame = null
	if desk:
		for node in desk._drawers[DirectorOffice.PHOTO_DRAWER].get_children():
			if node is PhotoFrame:
				found = node
	check.call("Foto 2005 in der Schublade im Sekretariat", found != null and found.found and found.year == MISSING
		and DirectorOffice.PHOTO_DRAWER != DirectorOffice.CODE_DRAWER and not desk.code_locked(DirectorOffice.PHOTO_DRAWER))
	var reg := Game.register
	if reg:
		var c1990: Vector2i = crosses.call(reg._old_rows(1990))
		var c1991: Vector2i = crosses.call(reg._old_rows(1991))
		var rows2005: Array = reg._old_rows(2005)
		var c2005: Vector2i = crosses.call(rows2005)
		var hain := func(rows: Array) -> int:   # 0 fehlt, 1 ohne, 2 mit Kreuz
			for row: Dictionary in rows:
				if String(row["t"]).begins_with("Rudolf Hain"):
					return 2 if not (row["crosses"] as Array).is_empty() else 1
			return 0
		check.call("Register 1990 ganz gekreuzt", c1990.x == c1990.y and c1990.y > 0)
		check.call("Register 1991 ohne Kreuz", c1991.x == 0 and c1991.y > 0)
		check.call("Register 2005: zwei Kreuze, Hain ohne", c2005.x == 2 and hain.call(rows2005) == 1)
		check.call("Register 2008: Hain mit Kreuz", hain.call(reg._old_rows(2008)) == 2)
	else:
		print("[Fotowand] FEHLER: kein Hotelregister")
	check.call("Zettel nur aus Erntejahren", WarningNote.NOTES.keys().all(func(k: String) -> bool: return YEARS.has(k.to_int())))
	var pencil := String(CaretakerBook.PAGES[-1])
	check.call("Zimmer 18: Bleistift Oktober 2005, „R. hat ihn.“", pencil.contains("Oktober 2005") and pencil.contains("R. hat ihn."))
	var walter: Guest = null
	var oskar: Guest = null
	for g: Guest in Game.social.living_guests():
		match String(g.profile.get("household", "")):
			HarvestTalk.WALTER: walter = g
			HarvestTalk.OSKAR: oskar = g
	if walter and oskar:
		check.call("Walter beim Wettbewerb", HarvestTalk.greeting(walter, 1) == HarvestTalk.WALTER_CONTEST[1]
			and HarvestTalk.greeting(walter, 1) == "")
		check.call("Oskar vor dem 3. still", HarvestTalk.greeting(oskar, 2) == "")
		check.call("Oskar erinnert sich, eins je Morgen", HarvestTalk.greeting(oskar, 20) == HarvestTalk.OSKAR_MEMORIES[0][2]
			and HarvestTalk.greeting(oskar, 20) == "")
	else:
		print("[Fotowand] FEHLER: Walter oder Oskar fehlt")
	_update_current(Calendar.at(1, 12.0))
	check.call("1. Oktober: Rahmen 2026 leer", not _hung and not _frame_now.photo_mesh.visible)
	Game.contest.debug_board("abgereist")   # Gustav ist geholt, 3. Oktober 7 Uhr
	TeleportUI.place_player((_spots[0].origin + _spots[-1].origin) / 2.0 + _spots[0].basis.z * 2.4 + Vector3.UP * 0.05,
		-_spots[0].basis.z + Vector3.UP * 0.25)
	get_tree().create_timer(1.0).timeout.connect(func() -> void:
		var gustav := Game.social.grinch.gustav if Game.social.grinch else null
		_update_current(Game.director.elapsed)
		check.call("Ankunftsfoto 2026 hängt", _hung and _frame_now.photo_mesh.visible)
		check.call("Gustav verwischt", gustav != null and Game.register.is_crossed(gustav) and _blurred_now >= 1)
		look_at_photo(CURRENT)
		print("[Fotowand] Prüfung fertig"))


# --- Paulas Foto vom Leviathan (Spielkonzept 4.32, ZIM-101) ----------------------------------------

## Platz für ein angeheftetes Foto: in der Lücke zwischen den beiden rechten Spalten, auf halber Höhe zwischen den
## Reihen – so bleibt jede Ernte an ihrem Platz. Ist die Lücke zu schmal, rechts neben der letzten Spalte. Ursprung
## Mitte des Fotos vor der Wand, +Z in den Raum.
func pin_spot() -> Transform3D:
	var last := _spots[-1]
	var right := Vector3.UP.cross(last.basis.z)
	var mid := (TOPS[0] + TOPS[1]) / 2.0 - PHOTO.y / 2.0 - FRAME
	var outer := PHOTO.x + FRAME * 2.0
	var at := last.origin + right * (outer / 2.0 + Snapshot.SIZE.x / 2.0 + 0.06)
	if _spots.size() >= 2:
		var before := _spots[-2]
		if before.origin.distance_to(last.origin) - outer >= Snapshot.SIZE.x + 0.08:
			at = (before.origin + last.origin) / 2.0
	return Transform3D(last.basis, at + Vector3.UP * mid + last.basis.z * GAP)


## Heftet ein Foto an die Wand (pin_spot); ein schon angeheftetes wird ersetzt. look: [E] daran.
func pin_snapshot(picture: Texture2D, prompt: String, look: Callable) -> Snapshot:
	for n in get_children():
		if n is Snapshot:
			n.queue_free()
	var snap := Snapshot.new()
	snap.prompt = prompt
	snap.look = look
	snap.transform = pin_spot()
	snap.rotation.z = -0.06   # schief angeheftet
	add_child(snap)
	snap.build(picture)
	return snap


## Das Foto vom Leviathan – Platzhalter bis zu den echten Bildern (ZIM-135): ein dunkler Flur im Blitzlicht, vorn
## überstrahlt, mitten im Bild eine lange, dünne Gestalt mit Zacken am Rücken und langem Schädel, waagerecht
## verwischt, als spränge sie gerade davon. Kein Blut, kein Opfer im Bild (Altersfreigabe). Fest gewürfelt.
static func draw_leviathan_photo() -> Image:
	var rng := RandomNumberGenerator.new()
	rng.seed = 4032
	var img := Image.create(W, H, false, Image.FORMAT_RGB8)
	var vanish := Vector2(W * 0.56, H * 0.46)
	for row in H:
		for col in W:
			var c := Color(0.05, 0.055, 0.06)                           # Wand im Dunkeln
			var below := float(row) - vanish.y
			if below > absf(col - vanish.x) * 0.55:
				c = Color(0.1, 0.085, 0.07).lerp(Color(0.2, 0.16, 0.12), clampf(below / 50.0, 0.0, 1.0))   # Teppich
			elif absf(col - vanish.x) < 6.0 and absf(row - vanish.y + 4.0) < 9.0:
				c = Color(0.28, 0.2, 0.1)                               # Tür am Ende, schwaches Licht
			var flash := Vector2(col - W * 0.45, (row - H * 0.85) * 1.4).length() / W
			c = c.lerp(Color(0.85, 0.82, 0.74), clampf(0.55 - flash, 0.0, 0.55))   # Blitz, vorn überstrahlt
			img.set_pixel(col, row, c)
	# Gestalt als Maske: Rumpf vornübergebeugt, langer Schädel nach links, dünne Arme, Zacken am Rücken
	var mask: Array[float] = []   # Array, kein Packed-Array: die Lambda muss dasselbe beschreiben
	mask.resize(W * H)
	mask.fill(0.0)
	var blot := func(cx: float, cy: float, rx: float, ry: float) -> void:
		for row in range(int(cy - ry), int(cy + ry) + 1):
			for col in range(int(cx - rx), int(cx + rx) + 1):
				if col >= 0 and row >= 0 and col < W and row < H and pow((col - cx) / rx, 2) + pow((row - cy) / ry, 2) <= 1.0:
					mask[row * W + col] = 1.0
	for i in 30:   # Rumpf, vornübergebeugt, die Brust breiter, unten dünn
		var y := 38.0 + i * 2.2
		blot.call(106.0 + (y - 70.0) * 0.32 + sin(i * 0.5) * 0.8, y, maxf(3.0, 8.5 - absf(i - 8.0) * 0.28), 2.0)
	for i in 8:                        # Hals nach vorn
		blot.call(97.0 - i * 0.9, 38.0 - i * 0.5, 3.0, 2.0)
	blot.call(86.0, 33.0, 13.0, 4.0)   # langer Schädel
	blot.call(75.0, 36.5, 5.0, 1.8)    # offenes Maul, Unterkiefer
	for i in 26:                       # vorderer Arm, nach vorn gestreckt, Finger lang
		blot.call(96.0 - i * 1.1, 47.0 + i * 1.5 + pow(i / 26.0, 2) * 6.0, 1.4, 1.4)
	for i in 24:                       # hinterer Arm hängt
		blot.call(108.0 - i * 0.25, 50.0 + i * 2.2, 1.2, 1.2)
	for i in 9:                        # Zacken am Rücken
		var y := 36.0 + i * 6.0
		var x := 113.0 + (y - 70.0) * 0.32 + maxf(0.0, 4.0 - absf(i - 2.0) * 1.2)
		for k in 7:
			blot.call(x + k * 0.9, y - k * 0.6, maxf(0.6, 1.8 - k * 0.25), 0.8)
	var smear := 34
	for row in H:
		for col in W:
			var a := mask[row * W + col] * 0.8
			for k in range(1, smear):   # Bewegung: nach rechts nachgezogen, mit einem zweiten, schwächeren Bild
				if col - k >= 0:
					var m: float = mask[row * W + col - k]
					a = maxf(a, m * (0.7 * (1.0 - float(k) / smear) + (0.25 if k > 14 and k < 20 else 0.0)))
			if a > 0.0:
				img.set_pixel(col, row, img.get_pixel(col, row).lerp(Color(0.02, 0.02, 0.025), a))
	_disc(img, Vector2(83.0, 31.0), 0.8, Color(0.75, 0.72, 0.6))   # ein Lichtpunkt im Auge, mehr nicht
	for row in H:   # Sofortbildfilm: grünstichig, Körnung, Ecken dunkel
		for col in W:
			var c := img.get_pixel(col, row)
			c = Color(c.r * 0.92, c.g * 1.02 + 0.01, c.b * 0.98 + 0.012) * (1.0 + rng.randf_range(-0.09, 0.09))
			var d := Vector2(col - W / 2.0, row - H / 2.0) / Vector2(W, H)
			img.set_pixel(col, row, (c * (1.0 - d.length_squared() * 1.6)).clamp())
	return img


## Ein Sofortbild mit Reißzwecke an der Wand: weißer Rand, unten breiter, das Bild vorn. [E] ruft look.
## Ursprung Mitte des Fotos an der Wand, Bild nach +Z.
class Snapshot extends StaticBody3D:
	const IMAGE := Vector2(0.12, 0.09)
	const BORDER := 0.008
	const CHIN := 0.024               ## unterer Rand
	const SIZE := Vector2(IMAGE.x + BORDER * 2.0, IMAGE.y + BORDER + CHIN)
	const THICK := 0.0015

	var prompt := ""
	var look: Callable

	func build(picture: Texture2D) -> void:
		collision_layer = 4
		collision_mask = 0
		set_meta("interactable", self)
		var paper := StandardMaterial3D.new()
		paper.albedo_color = Color(0.9, 0.89, 0.85)
		paper.roughness = 0.7
		var shift := (CHIN - BORDER) / 2.0   # Bild sitzt über der Mitte
		Geo.mesh(self, Geo.box(Vector3(SIZE.x, SIZE.y, THICK)), paper, Vector3(0, 0, THICK / 2.0))
		var m := StandardMaterial3D.new()
		m.albedo_texture = picture
		m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
		m.roughness = 0.35   # glänzende Filmschicht
		var q := QuadMesh.new()
		q.size = IMAGE
		Geo.mesh(self, q, m, Vector3(0, shift, THICK + 0.0004))
		var tack := StandardMaterial3D.new()
		tack.albedo_color = Color(0.62, 0.08, 0.06)
		tack.roughness = 0.35
		var head := Geo.mesh(self, Geo.cylinder(0.0055, 0.003, 14), tack, Vector3(0, SIZE.y / 2.0 - 0.006, THICK + 0.0015))
		head.rotation.x = PI / 2.0
		Geo.add_box_shape(self, Vector3(SIZE.x, SIZE.y, 0.02), Vector3(0, 0, 0.01))

	func get_prompt(_player: Player) -> String:
		return prompt

	func interact(_player: Player) -> void:
		if look.is_valid():
			look.call()
