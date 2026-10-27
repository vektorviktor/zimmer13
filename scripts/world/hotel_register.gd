class_name HotelRegister
extends StaticBody3D
## Das Hotelregister auf der Rezeption (Spielkonzept 2.3, 2.9; HANDLUNG K1, M6): ein aufgeschlagenes Buch, fest, nicht
## tragbar. [E] liest es vor Ort (Menus.open_register, RegisterView): aufgeschlagen beim laufenden Oktober, zurück bis 1987.
##   · Oktober 2026: je Haushalt eine Zeile mit Zimmer und Namen wie an der Tür (LevelBuilder.door_name, 6.20), dazu
##     „geb. Ahrend“ bei Marion Teske (2.3) und „geb. K…“ bei Edna Wiegand (2.7, voller Geburtsname offen). Wer tot ist,
##     bekommt ein Kreuz hinter dem Namen – erst am Morgen danach ab CROSS_HOUR, wie die Mitteilung am Brett: Gustav am
##     Morgen nach der Siegerehrung, jeder weitere Tod seins. Niemand hat es eingetragen – Personal sieht man nie (2.5).
##   · Davor jeder Oktober seit 1987 mit ein paar Zeilen und Kreuzen: so viele, wie auf dem Gruppenfoto des Jahres
##     verwischt sind (PhotoWall.TAKEN), sonst gewürfelt. Namen und Zimmer aus festem Seed je Jahr; Edna steht 1987 mit
##     ihrem Geburtsnamen in Zimmer 017 (Warnungszettel „E. K.“). Zimmer 13 und 18 bleiben frei (2003 offen, 7.4).
## Nichts davon wird gespeichert: Wer tot ist, steht im Spielstand. Den Todeszeitpunkt merkt sich das Register nur in
## der laufenden Sitzung (on_guest_died) – nach dem Laden gilt jeder Tote als eingetragen. Gustav steht immer ab dem
## Morgen nach der Siegerehrung drin (dann ist er gestorben, das braucht keinen Zeitpunkt). Gelesen: neue Kreuze und die alten Jahre als Notiz ins Notizbuch (3.10). Erreichbar über Game.register.

## Ab dieser Stunde am Morgen nach einem Tod steht sein Kreuz da (wie DoorContest.DEPARTURE_HOUR)
const CROSS_HOUR := 6.0
const FIRST_YEAR := 1987
const YEAR := 2026
## Geburtsnamen im Register hinter dem Namen an der Tür (2.3, 2.7, 6.20)
const BIRTH_NAMES := {"Marion Teske": "Ahrend", "Edna Wiegand": "K…"}
## Feste Zeilen früherer Jahre (Zimmer, Name) – und deren Zimmer würfelt das Jahr nicht noch einmal
const FIXED := {1987: [["017", "Edna K…"]]}
## Zimmer, die ein Jahr nicht würfelt (Warnungszettel „M. B., Zi. 021, 1999“)
const SKIP_ROOMS := {1999: ["021"]}
## Zeilen je früherem Jahr ohne Kreuz
const PLAIN := Vector2i(2, 4)
## Anteil der Zeilen, die ein Haushalt mit mehreren Personen sind (nur der Nachname)
const FAMILY_SHARE := 0.35
## Vornamen früherer Gäste: bis ERA_YEAR nur die älteren, danach beide Listen
const ERA_YEAR := 2005
const FIRST_EARLY := [
	"Erich", "Helga", "Werner", "Ingrid", "Günter", "Renate", "Horst", "Brigitte", "Manfred", "Elke", "Rolf", "Karin",
	"Dieter", "Ursula", "Klaus", "Monika", "Jürgen", "Hannelore", "Heinz", "Erika", "Wolfgang", "Christa", "Hans",
	"Bärbel", "Lothar", "Gertrud", "Herbert", "Waltraud", "Gerhard", "Marianne",
]
const FIRST_LATE := [
	"Thomas", "Sabine", "Michael", "Petra", "Andreas", "Heike", "Stefan", "Kerstin", "Frank", "Anja", "Uwe", "Silke",
	"Sven", "Daniela", "Marco", "Julia", "Dennis", "Nicole", "Jan", "Katrin",
]
const OLD_SURNAMES := [
	"Albrecht", "Baumann", "Dietrich", "Engel", "Fuchs", "Gärtner", "Haas", "Jansen", "Keller", "Lorenz", "Martens",
	"Nowak", "Olbrich", "Pohl", "Quandt", "Reuter", "Sauer", "Thiel", "Ulbrich", "Vogel", "Winkler", "Zimmer", "Brenner",
	"Decker", "Ewald", "Frey", "Grothe", "Hahn", "Jäger", "Kröger", "Lindner", "Mohr", "Nagel", "Paulsen", "Rausch",
	"Seidel", "Timm", "Voss", "Wolff", "Ziegler", "Born", "Dahl", "Eggers", "Fink", "Hesse", "Korte", "Lenz", "Marx",
]
## Notizen beim Lesen (3.10)
const OLD_JOT := "Kreuze neben Namen, in jedem Oktober, zurück bis 1987 – so weit das Buch reicht."
const CROSS_JOT := "Kreuz neben „%s“ (Zi. %s)."

var _builder: LevelBuilder
var _died_at := {}            ## Gast-ID → Spielzeit des Todes (nur diese Sitzung)
var _old_pages: Array = []    ## die Jahre 1987–2025 ändern sich nicht – einmal gesetzt


func setup(builder: LevelBuilder) -> HotelRegister:
	_builder = builder
	return self


func _ready() -> void:
	collision_layer = 4
	collision_mask = 0
	set_meta("interactable", self)
	add_to_group("registers")
	_build_model()


## Großes Kontobuch, aufgeschlagen: dunkelroter Einband, zwei Seiten mit Linien und Zeilen in Tinte, ein Lesebändchen.
func _build_model() -> void:
	var cover := Mat.psx(Color(0.3, 0.07, 0.06))
	var paper := Mat.psx(Color(0.88, 0.84, 0.72))
	var ink := Mat.psx(Color(0.16, 0.13, 0.12))
	var ribbon := Mat.psx(Color(0.55, 0.42, 0.12))
	Geo.mesh(self, Geo.box(Vector3(0.46, 0.014, 0.32)), cover, Vector3(0, 0.007, 0))
	for side: float in [-1.0, 1.0]:
		var page := Geo.mesh(self, Geo.box(Vector3(0.215, 0.016, 0.3)), paper, Vector3(side * 0.112, 0.021, 0))
		page.rotation.z = -side * 0.03
		for i in 9:
			var w := 0.14 - float((i * 7 + int(side + 1.0) * 3) % 5) * 0.015
			Geo.mesh(self, Geo.box(Vector3(w, 0.002, 0.004)), ink,
				Vector3(side * 0.112 - (0.15 - w) * 0.5 + 0.02, 0.031, -0.12 + i * 0.03))
	Geo.mesh(self, Geo.box(Vector3(0.008, 0.002, 0.36)), ribbon, Vector3(0.006, 0.031, 0.02))
	Geo.add_box_shape(self, Vector3(0.48, 0.06, 0.34), Vector3(0, 0.03, 0))


func get_prompt(_player: Player) -> String:
	return "Hotelregister lesen [E]"


func interact(_player: Player) -> void:
	if Game.menus:
		Game.menus.open_register(self)


# --- Kreuze ---------------------------------------------------------------------------------

## Ein Gast ist gestorben (Social.on_guest_died): ab dem nächsten Morgen sein Kreuz.
func on_guest_died(guest: Guest) -> void:
	_died_at[guest.id] = _now()


## Steht sein Kreuz schon im Register?
func is_crossed(guest: Guest) -> bool:
	return guest.dead and _now() >= _cross_time(guest)


func _cross_time(guest: Guest) -> float:
	var grinch := Game.social.grinch if Game.social else null
	if grinch and guest == grinch.gustav:   # er stirbt bei der Siegerehrung (2.6) – auch nach dem Laden bekannt
		return Calendar.at(DoorContest.CEREMONY_DAY + 1, CROSS_HOUR)
	if _died_at.has(guest.id):
		return next_morning(float(_died_at[guest.id]))
	return -INF


## Der nächste Morgen um CROSS_HOUR nach Spielzeit t.
static func next_morning(t: float) -> float:
	var day := Calendar.raw_day_of(t)
	var morning := Calendar.at(day, CROSS_HOUR)
	return morning if t < morning else Calendar.at(day + 1, CROSS_HOUR)


func _now() -> float:
	return Game.director.elapsed if Game.director else 0.0


# --- Seiten ---------------------------------------------------------------------------------

## Alle Seiten in Lesereihenfolge, jede {title, year, rows}; Zeile {room, t, crosses, ink, guests} – crosses: Kreuz
## hinter so vielen Zeichen von t, guests: [Gast-ID, Name, Zimmer] der Kreuze für das Notizbuch. Der laufende Oktober
## beginnt auf einer linken Seite (Index gerade).
func pages() -> Array:
	if _old_pages.is_empty():
		var blocks: Array = []
		for year in range(FIRST_YEAR, YEAR):
			blocks.append({"year": year, "rows": _old_rows(year)})
		_old_pages = RegisterView.paginate(blocks)
		if _old_pages.size() % 2 == 1:
			_old_pages.append({"title": "", "year": 0, "rows": []})
	var result := _old_pages.duplicate()
	result.append_array(RegisterView.paginate([{"year": YEAR, "rows": _current_rows()}]))
	return result


## Erste Seite des laufenden Oktobers (gerade).
func current_page() -> int:
	return _old_pages.size()


## Zeilen des laufenden Oktobers: ein Haushalt je Zeile, nach Zimmernummer.
func _current_rows() -> Array:
	var members := {}   # Zimmer → {Mitglied → Gast}
	var loose := {}     # Zimmer → [Gast] ohne Haushalt
	for g: Guest in Game.social.guests if Game.social else []:
		var no := String(g.home["no"])
		if g.profile.has("household"):
			members.get_or_add(no, {})[int(g.profile["member"])] = g
		else:
			loose.get_or_add(no, []).append(g)
	var rooms: Array = _builder.households.keys() + loose.keys()
	rooms.sort_custom(func(a: String, b: String) -> bool: return _sign(a).naturalnocasecmp_to(_sign(b)) < 0)
	var rows: Array = []
	for no: String in rooms:
		if _builder.households.has(no):
			rows.append(_household_row(no, members.get(no, {})))
		else:
			for g: Guest in loose[no]:
				var row := RegisterView.row(_sign(no), g.display_name)
				if is_crossed(g):
					_cross(row, g, g.display_name)
				rows.append(row)
	return rows


func _household_row(no: String, guests: Dictionary) -> Dictionary:
	var household: Dictionary = _builder.households[no]
	var name := LevelBuilder.door_name(household)
	var row := RegisterView.row(_sign(no), name)
	if BIRTH_NAMES.has(name):
		row["t"] += ", geb. " + String(BIRTH_NAMES[name])
	var people: Array = household["members"]
	if people.size() == 1:
		var g: Guest = guests.get(0)
		if g and is_crossed(g):
			_cross(row, g, row["t"])
		return row
	for i in people.size():   # mehrere Personen: hinter dem Nachnamen der Vorname jedes Toten mit Kreuz
		var g: Guest = guests.get(i)
		if g and is_crossed(g):
			row["t"] += " · " + String(people[i]["name"])
			_cross(row, g, "%s %s" % [people[i]["name"], household["surname"]])
	return row


## Kreuz hinter dem bisherigen Text der Zeile; danach Platz dafür.
func _cross(row: Dictionary, g: Guest, name: String) -> void:
	row["crosses"].append(String(row["t"]).length())
	row["t"] += "   "
	row["guests"].append([g.id, name, row["room"]])


## Ein früheres Jahr: feste Zeilen, dann gewürfelte – so viele Kreuze, wie auf dem Foto des Jahres fehlen.
func _old_rows(year: int) -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = year * 7919
	var crosses := int(PhotoWall.TAKEN.get(year, rng.randi_range(1, 3)))
	var count := crosses + rng.randi_range(PLAIN.x, PLAIN.y)
	var free := _old_rooms()
	var picked: Array = []
	for fixed: Array in FIXED.get(year, []):
		picked.append(RegisterView.row(String(fixed[0]), String(fixed[1])))
		free.erase(String(fixed[0]))
	for skip: String in SKIP_ROOMS.get(year, []):
		free.erase(skip)
	var surnames := OLD_SURNAMES.duplicate()
	var taken_names := {}
	for no: String in _builder.households:   # keine Namen der Gäste von heute
		taken_names[String(_builder.households[no]["surname"])] = true
	surnames = surnames.filter(func(s: String) -> bool: return not taken_names.has(s))
	while picked.size() < count + FIXED.get(year, []).size() and not free.is_empty() and not surnames.is_empty():
		var room: String = free.pop_at(rng.randi_range(0, free.size() - 1))
		var surname: String = surnames.pop_at(rng.randi_range(0, surnames.size() - 1))
		var names: Array = FIRST_EARLY if year < ERA_YEAR else FIRST_EARLY + FIRST_LATE
		var first: String = names[rng.randi_range(0, names.size() - 1)]
		var dead := crosses > 0
		var row: Dictionary
		if rng.randf() < FAMILY_SHARE:
			row = RegisterView.row(room, surname + (" · " + first if dead else ""))
		else:
			row = RegisterView.row(room, "%s %s" % [first, surname])
		if dead:
			crosses -= 1
			row["crosses"].append(String(row["t"]).length())
			row["t"] += "   "
		picked.append(row)
	picked.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return String(a["room"]).naturalnocasecmp_to(String(b["room"])) < 0)
	var age := float(YEAR - year) / float(YEAR - FIRST_YEAR)   # ältere Tinte ist blasser
	for row: Dictionary in picked:
		row["ink"] = RegisterView.INK.lerp(RegisterView.OLD_INK, age)
	return picked


## Zimmernummern (wie am Schild) früherer Gäste: alle Gäste- und leeren Zimmer außer 13 und 18, sortiert.
func _old_rooms() -> Array:
	var out: Array = []
	for no: String in _builder.rooms:
		var info: Dictionary = _builder.rooms[no]
		if String(info["kind"]) in ["guest", "vacant"] and no != LevelBuilder.PLAYER_ROOM and no != LevelBuilder.LOCKED_ROOM:
			out.append(String(info["sign"]))
	out.sort_custom(func(a: String, b: String) -> bool: return a.naturalnocasecmp_to(b) < 0)
	return out


func _sign(no: String) -> String:
	return String(_builder.rooms[no]["sign"]) if _builder.rooms.has(no) else no


# --- Gelesen --------------------------------------------------------------------------------

## Eine Doppelseite liegt offen (Menus): neue Kreuze und die alten Jahre ins Notizbuch.
func on_pages_read(shown: Array) -> void:
	if Game.notebook == null:
		return
	for page: Dictionary in shown:
		var year := int(page["year"])
		if year > 0 and year < YEAR:
			Game.notebook.add_note("register_old", OLD_JOT, "Hotelregister")
		for row: Dictionary in page["rows"]:
			for who: Array in row["guests"]:
				Game.notebook.add_note("register_" + String(who[0]), CROSS_JOT % [who[1], who[2]], "Hotelregister")


# --- Debug ----------------------------------------------------------------------------------

## --register[=tot][,offen|anfang]: vor die Rezeption, Blick aufs Register. tot: Gustav ist geholt, 3. Oktober 7 Uhr
## (wie --brett=abgereist) – sein Kreuz steht da. offen: nach 1 s aufgeschlagen · anfang: bei Oktober 1987.
func debug(dead: bool, open: bool, first: bool = false) -> void:
	if dead:
		Game.contest.debug_board("abgereist")
	var out := global_basis.z
	TeleportUI.place_player(global_position + out * 0.75 - Vector3.UP * global_position.y, -out)
	Game.player.head.rotation.x = deg_to_rad(-38.0)
	if open or first:
		get_tree().create_timer(1.0).timeout.connect(func() -> void: Game.menus.open_register(self, 0 if first else -1))
	if Game.tracing:   # nach weiteren Toten aus --kill
		get_tree().create_timer(2.0).timeout.connect(func() -> void:
			for g: Guest in Game.social.guests:
				if g.dead:
					print("[Register] %s tot, Kreuz %s" % [g.display_name, "steht" if is_crossed(g) else "ab %s %s" % [
						Calendar.date_text(_cross_time(g)), Calendar.time_text(_cross_time(g))]]))
