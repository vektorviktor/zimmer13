class_name LevelBuilder
extends RefCounted
## Baut das Hotel aus dem Gebäudeplan (Spielkonzept 7.5): `assets/maps/eg.json`, erzeugt von
## `tools/build_map.py` aus `map.aseprite`. 1 Einheit = 1 m, x nach Osten, z nach Süden (Norden = −Z),
## Ursprung = Mitte des Haupteingangs auf der Südwand.
##
##   Erdgeschoss (y 0): Lobby mit Luftraum und Galerie (Treppe hinauf, Obergeschoss noch gesperrt),
##   Bar + Spiele, Partyraum, Toiletten · Ostflügel 0101–0181 · Westflügel 0201–0272 (Bauphase:
##   Zimmer verschlossen, Flure begehbar) · Küchenblock im Westflügel · Mittelgarten und vier Innenhöfe ·
##   Pool im Norden · Treppenhaus Ost hinab in den Keller (y −3,5), Treppenhaus West gesperrt.
##
## Kollisionsebenen: 1 statisch/NavMesh · 2 Türen · 3 Gegenstände · 4 Spieler · 5 Decke
##                   · 6 Monster · 7 Glas · 8 Gäste · 9 Milchglas · 10 zugezogene Vorhänge
##
## Einrichtung (Spielkonzept 7.5): Möbel, Ausstattung, Gegenstände und Lichter stehen im Plan (Objektebenen).
## Was der Plan nicht kennt – Höhen, Helligkeit je Raumart, Zettel-Nummern, Münzbeträge, UV-Texte, Zimmerarten –
## steht hier und wird über die Fläche zugeordnet, auf der ein Objekt liegt.
##
## Licht (Spielkonzept 7.3): Jede Lampe gehört zu einem Raum; ein Lichtschalter pro Raum bzw. Flurabschnitt.

const MAP_PATH := "res://assets/maps/eg.json"
const H := 3.5
const T := 0.2
## Höhe des Obergeschosses (Oberkante Boden)
const UP_Y := 4.0
## Gedimmtes Licht (Spielkonzept 7.3): keine Deckenlampen, Wandleuchten schwächer als Kerzen
const WALL_LAMP_ENERGY := 0.5
const CANDLE_ENERGY := 0.85
## Zimmer etwas heller als die Flure
const ROOM_LAMP_ENERGY := 0.65
## Deckenleuchten (wieder seit 2026-10-19, nur wo der Plan sie setzt): gedimmt, aber mit Reichweite bis zum Boden.
## Über dem Luftraum hängen sie als Pendel an einer Schnur bis PENDANT_Y herab (Oberkante Schirm).
const CEILING_LAMP_ENERGY := 0.65
const CEILING_LAMP_RANGE := 9.0
const PENDANT_Y := 4.8
const DOOR_W := 1.2
const DOOR_H := 2.1
## Doppeltüren, Glastüren, Terrassentüren
const WIDE_DOOR_H := 2.4
const ENTRANCE_H := 2.8
const COUCH_MODEL := "res://assets/models/couch.glb"
## Rohmodell ist 4,34 Einheiten lang → ~2,4 m lang, Sitzhöhe ~0,45 m, Lehne ~0,92 m.
const COUCH_SCALE := 0.55
## 28 einzelne Flaschen „bottle_NN“ in Metern, Ursprung mittig unten (tools/build_bottles.py)
const BOTTLES_MODEL := "res://assets/models/bottles.glb"
## Pflanzkübel samt Bepflanzung in Metern, Ursprung mittig unten, Grundfläche 2 × 2 m wie im Plan
## (tools/build_planter.py aus Meshys Modell). Fehlt die Datei, baut `_gardens()` den Platzhalter aus
## Steinquader und Heckenkugel.
const PLANTER_MODEL := "res://assets/models/planter.glb"
## Höhe des Kollisionsquaders (und des Platzhalter-Kübels) = Beckenkante, ausgegeben von tools/build_planter.py
const PLANTER_H := 0.46
## Laubbaum in Metern, Ursprung auf der Stammachse am Boden (tools/build_tree.py aus Meshys Modell).
## `_tree()` skaliert ihn auf den Kronenradius aus dem Plan; fehlt die Datei, bleibt der Platzhalter.
const TREE_MODEL := "res://assets/models/tree.glb"
## Kronenradius und Stammdurchmesser des Modells (ausgegeben von tools/build_tree.py), Höhe der Stammkollision
const TREE_RADIUS := 5.0
const TREE_TRUNK := 1.53
const TREE_TRUNK_H := 3.0
const LAYER_CEILING := 16
const LAYER_GLASS := 64
## Fenster: Unterkante (bündig mit der Vertäfelung), Oberkante – die Breite kommt aus dem Plan
const WINDOW_SILL := 0.75
const WINDOW_TOP := 3.05
## Keller unter dem östlichen Treppenhaus
const CELLAR_Y := -3.5
const CELLAR_LEN := 8.0
const CELLAR_H := 2.6
## Rasterweite der Flächen-Nachschlagetabelle (Wandmaterial, Raum-IDs)
const GRID := 0.25

## Zimmer mit besonderer Rolle (Spielkonzept 7.5: die alten Nummern sind die Endziffern). Alle übrigen
## Zimmer im Ostflügel sind unbewohnt („vacant“), die im Westflügel noch verschlossen (Bauphase).
## Arten: player, guest, empty, vacant (unbewohnt, Licht aus), laundry, abandoned, derelict, locked.
const PLAYER_ROOM := "0113"
const COMPASS_ROOM := "0126"
const LOCKED_ROOM := "0118"
const ROOM_KINDS := {
	"0111": "guest", "0112": "guest", "0113": "player", "0114": "empty", "0115": "guest",
	"0116": "laundry", "0117": "abandoned", "0118": "locked", "0126": "derelict", "0137": "derelict",
}
## Flügel, deren Zimmer schon bewohnbar sind
const OPEN_WINGS := ["ost"]

## Inhalt, der nicht im Plan steht, je Raum-ID (Zimmernummer oder Bereich): Münzbetrag (ohne Eintrag 1),
## Kartenblatt, Zettel-Nummer (Spielkonzept 4.12) und UV-Schrift (4.16) der Objekte in diesem Raum.
const CONTENT := {
	"0113": {"coins": "3", "map": "eg", "uv": "DU WARST SCHON\nEINMAL HIER"},
	"0114": {"note": "2003"},
	"0116": {"note": "1994"},
	"0117": {"coins": "2", "map": "keller", "note": "1987",
		"uv": "ICH HABE ES GEBLENDET.\nJETZT KENNT ES MEINE TÜR.\n– E. K."},
	"0118": {"coins": "5", "uv": "NUR EINER\nKOMMT HINAUS"},
	"lobby": {"note": "2019"},
}
## Möbel ohne eigenes Bauteil (Kästen in der Grundfläche aus dem Plan): Art → Höhe
const BOX_HEIGHTS := {
	"table": 0.75, "coffee_table": 0.4, "dining_table": 0.78, "bench": 0.45, "bar_counter": 1.1, "shelf": 2.0,
	"kitchen_counter": 0.9, "stove": 0.95, "washbasin": 0.85, "washing_machine": 0.85, "laundry_box": 0.5, "pillar": H,
}
const RECEPTION_H := 1.1
## Wandsachen: Abstand zur Wandfläche (bündig, ohne Flimmern) und Höhen über dem Boden
const WALL_GAP := 0.01
const SWITCH_Y := 1.3
const CALENDAR_Y := 1.7
const UV_Y := 1.5
const COBWEB_Y := 2.4
## Schilder (Zimmernummern, AUSGANG, BAR …): Messingbuchstaben in Cinzel Bold (OFL, assets/fonts/OFL.txt;
## ohne überlappende Konturen aus tools/build_font.py) auf einer Holzplatte mit Messingrand.
## Schriftgröße (Geviert) in Metern – Wegweiser, Zimmernummern –, Versalhöhe ~0,7 davon; CURVE_STEP in
## Schriftpixeln – grob, damit die Rundungen kantig bleiben (PS1-Look)
const SIGN_FONT := "res://assets/fonts/cinzel_bold.ttf"
const SIGN_EM := 0.22
const SIGN_EM_ROOM := 0.17
const SIGN_FONT_SIZE := 16
const SIGN_CURVE_STEP := 2.0
## Wie weit die Buchstaben vor der Platte stehen, Stärke der Platte, Rand um den Text, Messingrand
const SIGN_DEPTH := 0.01
const SIGN_PLATE := 0.016
const SIGN_MARGIN := Vector2(0.05, 0.035)
const SIGN_RIM := 0.008
## Messing je Schild: blank, matt, angelaufen
const SIGN_BRASS: Array[Color] = [Color(0.8, 0.64, 0.28), Color(0.68, 0.54, 0.25), Color(0.52, 0.45, 0.27)]
## Ersatzbirnen liegen im Lagerregal, nicht obendrauf
const BULB_SUPPLY_Y := 1.4
## Reifegrade der Kürbispflanzen in Planreihenfolge (von Norden nach Süden, je Beet von Westen nach Osten)
const PLANT_STAGES := [0, 3, 2, 3, 1, 3]
const PAINTING_COLORS: Array[Color] = [Color(0.22, 0.14, 0.12), Color(0.16, 0.2, 0.15), Color(0.12, 0.13, 0.2),
	Color(0.2, 0.18, 0.1), Color(0.18, 0.1, 0.12), Color(0.1, 0.14, 0.18), Color(0.25, 0.1, 0.1)]
## Umkleiden und Duschen am Pool teilen sich einen Lichtschalter
const CHANGING_ROOMS := ["vorraum", "dusche_west", "dusche_ost", "umkleide_west", "umkleide_ost"]

var root: Node3D     ## NavigationRegion3D – statische Geometrie, wird fürs NavMesh geparst
var world: Node3D    ## Hauptszene – dynamische Gegenstände
var zones: Array[Dictionary] = []
var spawn_points: Array[Vector3] = []
## Wegpunkte im ganzen Hotel (Verschwinden aus dem Blickfeld): {pos, room}
var patrol: Array[Dictionary] = []
## Punkte in den Fluren, an denen Gäste herumschlendern
var wander_points: Array[Vector3] = []
## Zimmernummer → {no, sign, kind, center, door_front, door_inside, along, into, door, spots}
var rooms := {}
var lobby_center := Vector3.ZERO
var party_spots: Array[Vector3] = []
var lobby_seats: Array[Vector3] = []
## Liegeplätze der Hotelkatzen auf Möbeln (6.11): {"floor": davor auf dem Boden, "top": obendrauf}
var cat_perches: Array[Dictionary] = []
var kitchen_spot := Vector3.ZERO
var garden_spots: Array[Vector3] = []
var player_spawn := Vector3.ZERO
var player_door_front := Vector3.ZERO
var record_player_pos := Vector3.ZERO
## Dunkle Ecke des Partyraums (dort steht es beim ersten Angriff, MonsterDirector)
var party_corner := Vector3.ZERO
var game_table: GameTable
var chess_table: ChessTable
var bar_spots: Array[Vector3] = []
var diary: Diary
## Treppenhaus zwischen den Geschossen (Ausbreitung der Flacker-Welle, MonsterDirector.wave_delay)
var stairwell_point := Vector3.ZERO

var _map: Dictionary
var _parent: Node3D  ## wohin die Bausteine gerade bauen (root oder ein gedrehter Rahmen)
## Flächen-Nachschlagetabelle: Index in _places + 1 je Rasterzelle, 0 = keine Fläche (draußen oder Wand)
var _grid := PackedInt32Array()
var _grid_origin := Vector2.ZERO
var _grid_size := Vector2i.ZERO
var _places: Array[Dictionary] = []   ## {id, kind, region}
var _lobby := Rect2()                 ## Innenmaß der Lobby (x, z)
var _named := {}                      ## Flächen-ID → Rect2 (Umriss)
## Wandstücke des Plans, an die Wandsachen gehängt werden: {horizontal, at (Mittellinie), from, to, half (halbe Dicke)}
var _wall_index: Array[Dictionary] = []
## Gebaute Möbel und die Rezeption: {kind, rect: Rect2, top (Oberkante), front: Vector2, node}
var _furnishings: Array[Dictionary] = []
var _doors: Array[Dictionary] = []    ## {pos: Vector3 (Mitte unten), door: Door, kind, into}
var _open_rooms := {}                 ## Nummern der bewohnbaren Zimmer (OPEN_WINGS)

var _wallpaper: Material
var _room_wallpaper: Material
var _lobby_wallpaper: Material
var _facade: Material
var _wall_tiles: Material
var _concrete: Material
var _wood: Material
var _dark_wood: Material
var _ceiling: Material
var _room_ceiling: Material
var _hedge: Material
var _carpet: Material
var _wood_floor: Material
var _floor_tiles: Material
var _grass: Material
var _stone: Material
var _sign_font: Font


func _init(p_root: Node3D, p_world: Node3D) -> void:
	root = p_root
	world = p_world
	_parent = root


func build() -> void:
	_materials()
	_map = JSON.parse_string(FileAccess.get_file_as_string(MAP_PATH))
	assert(_map != null, "Gebäudeplan %s fehlt – tools/build_map.py ausführen" % MAP_PATH)
	_index_places()
	for w in _map["walls"]:
		_build_wall(w)
	_floors_and_ceilings()
	for info in _map["rooms"]:
		_room(info)
	_furniture()
	_fittings()
	_items()
	_lights()
	_lobby_hall()
	_gallery()
	_common_rooms()
	_pool()
	_gardens()
	_stairwells()
	_cellar()
	var home: Dictionary = rooms[PLAYER_ROOM]
	player_spawn = (home["center"] as Vector3) + Vector3(0, 0.05, 0) + (home["into"] as Vector3) * 0.1
	player_door_front = home["door_front"]
	_zones()
	_waypoints()


func _materials() -> void:
	_wallpaper = Mat.wallpaper(H, UP_Y)
	_room_wallpaper = Mat.wallpaper(H, UP_Y, "beige")   # nur in den Zimmern
	_lobby_wallpaper = Mat.wallpaper(H, UP_Y, "red")
	_facade = Mat.psx(Color(0.62, 0.56, 0.5), "concrete", 0.5)
	_wall_tiles = Mat.psx(Color(0.82, 0.88, 0.9), "tiles", 1.0)
	_concrete = Mat.psx(Color(0.8, 0.8, 0.8), "concrete", 0.5)
	_wood = Mat.psx(Color(0.45, 0.28, 0.15))
	_dark_wood = Mat.psx(Color(0.22, 0.13, 0.08))
	_ceiling = Mat.psx(Color(0.55, 0.55, 0.55), "wood", 1.0)   # Holzdecke wie der Zimmerboden, abgedunkelt (7.3)
	_room_ceiling = Mat.psx(Color(0.85, 0.85, 0.85), "wood", 1.0)   # in den Zimmern heller
	_hedge = Mat.psx(Color(1, 1, 1), "hedge", 1.0)
	_carpet = Mat.psx(Color(1, 1, 1), "carpet", 1.0)
	_wood_floor = Mat.psx(Color(1, 1, 1), "wood", 1.0)
	_floor_tiles = Mat.psx(Color(1, 1, 1), "tiles", 0.5)
	_grass = Mat.psx(Color(1, 1, 1), "grass", 1.0)
	_stone = Mat.psx(Color(0.62, 0.57, 0.5), "concrete", 1.0)
	_sign_font = load(SIGN_FONT)


# --- Plan: Flächen nachschlagen --------------------------------------------------------------------

## Füllt das Raster mit den Flächen des Plans (Regionen, Bodenflicken, Treppen, Terrassenkanten).
func _index_places() -> void:
	var lo := Vector2(INF, INF)
	var hi := Vector2(-INF, -INF)
	var add := func(id: String, kind: String, rects: Array, region: Dictionary) -> void:
		_places.append({"id": id, "kind": kind, "rects": rects, "region": region})
	for r in _map["regions"]:
		add.call(String(r["id"]), String(r["kind"]), r["rects"], r)
	for p in _map["floor_patches"]:
		add.call("", String(p["kind"]), p["rects"], {})
	for s in _map["stairs"]:
		add.call(String(s["id"]), "stairs", [s["rect"]], {})
	for rs in _map["terrace_edges"]:
		add.call("", "terrace", rs, {})
	for place in _places:
		for rc in place["rects"]:
			lo = Vector2(minf(lo.x, rc[0]), minf(lo.y, rc[1]))
			hi = Vector2(maxf(hi.x, rc[2]), maxf(hi.y, rc[3]))
	_grid_origin = lo - Vector2.ONE
	_grid_size = Vector2i(ceili((hi.x - lo.x + 2.0) / GRID), ceili((hi.y - lo.y + 2.0) / GRID))
	_grid.resize(_grid_size.x * _grid_size.y)
	_grid.fill(0)
	for i in _places.size():
		for rc in _places[i]["rects"]:
			var c0 := Vector2i(ceili((rc[0] - _grid_origin.x) / GRID - 0.5), ceili((rc[1] - _grid_origin.y) / GRID - 0.5))
			var c1 := Vector2i(floori((rc[2] - _grid_origin.x) / GRID - 0.5), floori((rc[3] - _grid_origin.y) / GRID - 0.5))
			for cy in range(c0.y, c1.y + 1):
				for cx in range(c0.x, c1.x + 1):
					_grid[cy * _grid_size.x + cx] = i + 1
	for r in _map["regions"]:
		if r.has("name"):
			_named[String(r["id"])] = _bounds(r["rects"])
	for a in _map["areas"]:
		if a["id"] == "lobby":
			var rc: Array = a["rect"]
			_lobby = Rect2(rc[0], rc[1], rc[2] - rc[0], rc[3] - rc[1])
	for info in _map["rooms"]:
		if String(info["wing"]) in OPEN_WINGS:
			_open_rooms[String(info["no"])] = true


func _bounds(rects: Array) -> Rect2:
	var r := Rect2(rects[0][0], rects[0][1], rects[0][2] - rects[0][0], rects[0][3] - rects[0][1])
	for rc in rects:
		r = r.merge(Rect2(rc[0], rc[1], rc[2] - rc[0], rc[3] - rc[1]))
	return r


func _place_at(p: Vector2) -> Dictionary:
	var c := Vector2i(floori((p.x - _grid_origin.x) / GRID), floori((p.y - _grid_origin.y) / GRID))
	if c.x < 0 or c.y < 0 or c.x >= _grid_size.x or c.y >= _grid_size.y:
		return {}
	var i := _grid[c.y * _grid_size.x + c.x]
	return _places[i - 1] if i > 0 else {}


## Art des Ortes für Wandmaterial und Türrichtung: room, sealed, corridor, lobby, bar, party, service,
## storage, toilet, pool, elevator, stairs, outside (Garten, Terrasse, außerhalb).
func _kind_at(p: Vector2) -> String:
	var place := _place_at(p)
	if place.is_empty():
		return "outside"
	var kind: String = place["kind"]
	match kind:
		"room":
			return "room" if _room_open(String(place["id"])) else "sealed"
		"corridor":
			return "lobby" if _lobby.has_point(p) else "corridor"
		"garden", "terrace":
			return "outside"
		"pool_water", "pool_deck":
			return "pool"
	return kind


## Raum-ID für Lampen, Fenster und Schalter am Ort p: Zimmernummer, Bereich, benannte Fläche oder Flurabschnitt.
func _room_id_at(p: Vector2) -> String:
	var place := _place_at(p)
	if place.is_empty():
		return ""
	if place["kind"] == "corridor":
		return "lobby" if _lobby.has_point(p) else _section_at(p)
	return String(place["id"])


func _room_open(no: String) -> bool:
	return _open_rooms.has(no)


## Nächster Flurabschnitt (Mittellinie aus dem Plan).
func _section_at(p: Vector2) -> String:
	var best := ""
	var best_d := INF
	for c in _map["corridors"]:
		var d := _dist_segment(p, _v2(c["a"]), _v2(c["b"]))
		if d < best_d:
			best_d = d
			best = String(c["id"])
	return best


func _dist_segment(p: Vector2, a: Vector2, b: Vector2) -> float:
	var ab := b - a
	var t := clampf((p - a).dot(ab) / maxf(ab.length_squared(), 0.0001), 0.0, 1.0)
	return p.distance_to(a + ab * t)


func _v2(a: Array) -> Vector2:
	return Vector2(float(a[0]), float(a[1]))


func _v3(a: Array, y: float = 0.0) -> Vector3:
	return Vector3(float(a[0]), y, float(a[1]))


# --- Wände, Türen, Fenster ----------------------------------------------------------------------------

## Eine Wand des Plans. Sie wird dort geteilt, wo sich die Räume auf einer Seite ändern (anderes Material);
## Seiten ohne Tapete (draußen, Fliesen, Beton) bekommen eine dünne Haut mit eigenem Material.
func _build_wall(w: Dictionary) -> void:
	var a := _v2(w["a"])
	var b := _v2(w["b"])
	var horizontal := is_equal_approx(a.y, b.y)
	var along := Vector2(1, 0) if horizontal else Vector2(0, 1)
	var side := Vector2(0, 1) if horizontal else Vector2(1, 0)   # „Plus“-Seite: Süden bzw. Osten
	var s0 := a.x if horizontal else a.y
	var s1 := b.x if horizontal else b.y
	var fixed := a.y if horizontal else a.x
	var openings: Array = w.get("openings", [])
	var glass := bool(w.get("glass", false))

	# Seiten abtasten (alle 25 cm, 30 cm neben der Wandmitte), kurze Läufe (Querwände) glätten
	var steps := maxi(1, roundi((s1 - s0) / GRID))
	var minus: Array[String] = []
	var plus: Array[String] = []
	for i in steps:
		var p := a + along * (i + 0.5) * (s1 - s0) / steps
		minus.append(_kind_at(p - side * 0.3))
		plus.append(_kind_at(p + side * 0.3))
	_smooth(minus)
	_smooth(plus)
	var cuts: Array[float] = [s0]
	for i in range(1, steps):
		if minus[i] != minus[i - 1] or plus[i] != plus[i - 1]:
			var s := s0 + i * (s1 - s0) / steps
			if not _in_opening(openings, s - s0):
				cuts.append(s)
	cuts.append(s1)

	var ops3: Array = []
	for o in openings:
		ops3.append(_opening_vec(o, s0))
	for k in cuts.size() - 1:
		var p0 := cuts[k]
		var p1 := cuts[k + 1]
		var i := clampi(roundi(((p0 + p1) / 2.0 - s0) / (s1 - s0) * steps - 0.5), 0, steps - 1)
		var mine: Array = []
		for op: Vector4 in ops3:
			if op.x > p0 and op.x < p1:
				mine.append(op)
		if glass:
			_glass_wall(horizontal, fixed, p0, p1)
		else:
			_wall_piece(horizontal, fixed, p0, p1, mine, minus[i], plus[i])
		_wall_index.append({"horizontal": horizontal, "at": fixed, "from": p0, "to": p1,
			"half": float(w.get("thickness", T)) / 2.0})
	for o in openings:
		_opening_object(o, a, along, side, horizontal)


## Kurze Läufe (unter 0,6 m – Querwände, Ecken) bekommen die Art des Nachbarn.
func _smooth(kinds: Array[String]) -> void:
	var i := 0
	while i < kinds.size():
		var j := i
		while j < kinds.size() and kinds[j] == kinds[i]:
			j += 1
		if (j - i) * GRID < 0.6:
			var fill: String = kinds[i - 1] if i > 0 else (kinds[j] if j < kinds.size() else kinds[i])
			for k in range(i, j):
				kinds[k] = fill
		i = j


func _in_opening(openings: Array, at: float) -> bool:
	for o in openings:
		if at > float(o["at"]) - 0.05 and at < float(o["at"]) + float(o["width"]) + 0.05:
			return true
	return false


## Öffnung als Vector4(Mitte entlang der Wand, Breite, Oberkante, Unterkante).
func _opening_vec(o: Dictionary, s0: float) -> Vector4:
	var width := float(o["width"])
	var center := s0 + float(o["at"]) + width / 2.0
	match String(o["kind"]):
		"window":
			return Vector4(center, width, WINDOW_TOP, WINDOW_SILL)
		"main_entrance":
			return Vector4(center, width, ENTRANCE_H, 0.0)
		"door", "service_door":
			return Vector4(center, width, DOOR_H if width < 1.5 else WIDE_DOOR_H, 0.0)
	return Vector4(center, width, WIDE_DOOR_H, 0.0)


func _wall_material(kind: String) -> Material:
	match kind:
		"room", "sealed":
			return _room_wallpaper
		"lobby":
			return _lobby_wallpaper
		"corridor", "bar", "party", "service", "stairs", "elevator":
			return _wallpaper
	return null


func _skin_material(kind: String) -> Material:
	match kind:
		"outside":
			return _facade
		"toilet", "pool":
			return _wall_tiles
		"storage":
			return _concrete
	return null


func _wall_piece(horizontal: bool, fixed: float, p0: float, p1: float, openings: Array, minus: String, plus: String) -> void:
	var m_minus := _wall_material(minus)
	var m_plus := _wall_material(plus)
	var normal_plus := Vector3(0, 0, 1) if horizontal else Vector3(1, 0, 0)
	var mat: Material
	if m_minus and m_plus and m_minus != m_plus:
		mat = Mat.wallpaper_split(m_minus, m_plus, normal_plus)
	else:
		mat = m_minus if m_minus else (m_plus if m_plus else _wallpaper)
	if horizontal:
		_wall_x(fixed, p0, p1, openings, mat)
	else:
		_wall_z(fixed, p0, p1, openings, mat)
	# Häute für Seiten ohne Tapete, knapp vor der Wandfläche
	for s: float in [-1.0, 1.0]:
		var skin := _skin_material(minus if s < 0 else plus)
		if skin == null:
			continue
		var offset := s * (T / 2.0 + 0.012)
		var holder := Node3D.new()
		if horizontal:
			holder.position = Vector3(0, 0, fixed + offset)
		else:
			holder.position = Vector3(fixed + offset, 0, 0)
			holder.rotation.y = -PI / 2.0
		_parent.add_child(holder)
		Geo.mesh(holder, Geo.wall_mesh(p0, p1, H, 0.02, openings), skin, Vector3.ZERO)


## Glaswand (Pool): Scheibe auf der Glas-Ebene, Rahmen und Pfosten alle ~1,8 m.
func _glass_wall(horizontal: bool, fixed: float, p0: float, p1: float) -> void:
	var holder := Node3D.new()
	if horizontal:
		holder.position = Vector3((p0 + p1) / 2.0, 0, fixed)
	else:
		holder.position = Vector3(fixed, 0, (p0 + p1) / 2.0)
		holder.rotation.y = -PI / 2.0
	root.add_child(holder)
	var length := p1 - p0
	var pane := StaticBody3D.new()
	pane.collision_layer = LAYER_GLASS
	pane.collision_mask = 0
	holder.add_child(pane)
	Geo.add_box_shape(pane, Vector3(length, H, T), Vector3(0, H / 2.0, 0))
	var quad := QuadMesh.new()
	quad.size = Vector2(length, H - 0.4)
	var g := Geo.mesh(pane, quad, Mat.glass(), Vector3(0, H / 2.0 + 0.1, 0))
	g.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var frame := Mat.psx(Color(0.2, 0.22, 0.24))
	Geo.solid(holder, Vector3(length, 0.3, T), Vector3(0, 0.15, 0), frame)        # Sockel (auch fürs NavMesh)
	Geo.mesh(holder, Geo.box(Vector3(length, 0.12, T)), frame, Vector3(0, H - 0.06, 0))
	var posts := maxi(1, roundi(length / 1.8))
	for i in posts + 1:
		Geo.mesh(holder, Geo.box(Vector3(0.08, H, 0.12)), frame, Vector3(-length / 2.0 + length * i / posts, H / 2.0, 0))


## Tür oder Fenster für eine Öffnung des Plans.
func _opening_object(o: Dictionary, a: Vector2, along: Vector2, side: Vector2, horizontal: bool) -> void:
	var kind := String(o["kind"])
	var width := float(o["width"])
	var c := a + along * (float(o["at"]) + width / 2.0)
	var k_minus := _kind_at(c - side * 0.5)
	var k_plus := _kind_at(c + side * 0.5)
	# „Innen“ = die Seite, in die Türen aufgehen bzw. in die das Fenster schaut
	var inner := _inner_side(k_minus, k_plus, kind)
	var into := side * inner
	var into3 := Vector3(into.x, 0, into.y)
	var yaw := atan2(into3.x, into3.z)
	var right := Vector3(cos(yaw), 0, -sin(yaw))
	var center := Vector3(c.x, 0, c.y)
	var inside_kind := k_plus if inner > 0 else k_minus
	var room_id := _room_id_at(c + into * 0.5)
	if kind == "window":
		var exterior := (k_plus if inner < 0 else k_minus) == "outside"
		var win := HotelWindow.new().setup(width, WINDOW_TOP - WINDOW_SILL, false, exterior, room_id)
		win.position = center + Vector3(0, (WINDOW_SILL + WINDOW_TOP) / 2.0, 0)
		win.rotation.y = yaw
		win.sealed = inside_kind == "sealed"
		root.add_child(win)
		return
	var wide := width >= 1.5
	var height := _opening_vec(o, 0.0).z
	var glass := kind in ["garden_door", "glass_double_door"]
	var door := Door.new().setup(width, height, -90.0 if wide else -100.0, wide, glass)
	door.position = center - right * width / 2.0
	door.rotation.y = yaw
	root.add_child(door)
	_doors.append({"pos": center, "door": door, "kind": kind, "into": into3})
	match kind:
		"main_entrance":
			door.locked = true
			door.key_id = "ausgang"
			door.monster_can_open = false
			door.locked_text = "Der Ausgang ist verriegelt. Es muss einen anderen Weg hinaus geben …"
			_sign("AUSGANG", center + Vector3(0, ENTRANCE_H + 0.35, 0) + into3 * 0.11, rad_to_deg(yaw))
		"elevator_door":
			door.locked = true
			door.key_id = "aufzug"
			door.monster_can_open = false
			door.locked_text = "Außer Betrieb."
			_sign("AUSSER BETRIEB", center + Vector3(0, WIDE_DOOR_H + 0.3, 0) - into3 * 0.11, rad_to_deg(yaw) + 180.0)
	if k_minus == "sealed" or k_plus == "sealed":
		_seal(door, "Abgeschlossen.")


func _inner_side(k_minus: String, k_plus: String, kind: String) -> float:
	# Türen gehen in Zimmer und Räume auf, nicht in Flure; Fenster schauen von innen nach draußen
	var rank := func(k: String) -> int:
		match k:
			"outside":
				return 0 if kind == "window" else 1
			"corridor", "lobby":
				return 2
		return 3
	return 1.0 if rank.call(k_plus) >= rank.call(k_minus) else -1.0


## Tür, die (in dieser Bauphase) niemand öffnen kann – auch das Monster nicht.
func _seal(door: Door, text: String) -> void:
	door.locked = true
	door.key_id = "gesperrt"
	door.monster_can_open = false
	door.locked_text = text


func _door_near(p: Vector3, max_dist: float = 0.6) -> Door:
	var best: Door = null
	var best_d := max_dist
	for d in _doors:
		var dist := (d["pos"] as Vector3).distance_to(Vector3(p.x, 0, p.z))
		if dist < best_d:
			best_d = dist
			best = d["door"]
	return best


# --- Böden und Decken -------------------------------------------------------------------------------

func _floors_and_ceilings() -> void:
	var holes: Array[Rect2] = []
	for rc in _map["open_above"]:
		holes.append(Rect2(rc[0], rc[1], rc[2] - rc[0], rc[3] - rc[1]))
	holes.append(_lobby)   # die Lobby-Decke ist der Boden der Galerie (_gallery)
	for r in _map["regions"]:
		var kind := String(r["kind"])
		if kind == "elevator" or kind == "pool_water" or (kind == "room" and not _room_open(String(r["id"]))):
			continue   # Aufzüge außer Betrieb, Becken eigens, verschlossene Zimmer ohne Inneres
		for rc in r["rects"]:
			_floor_rect(rc, _floor_material(kind, rc))
			if not bool(r["outdoor"]):
				for piece in _subtract(Rect2(rc[0], rc[1], rc[2] - rc[0], rc[3] - rc[1]), holes):
					Geo.solid(root, Vector3(piece.size.x, 0.2, piece.size.y), Vector3(piece.get_center().x, H + 0.1, piece.get_center().y),
						_room_ceiling if kind == "room" else _ceiling, LAYER_CEILING)
	for p in _map["floor_patches"]:
		for rc in p["rects"]:
			_floor_rect(rc, _floor_material(String(p["kind"]), rc))
			if not bool(p["outdoor"]):
				for piece in _subtract(Rect2(rc[0], rc[1], rc[2] - rc[0], rc[3] - rc[1]), holes):
					Geo.solid(root, Vector3(piece.size.x, 0.2, piece.size.y), Vector3(piece.get_center().x, H + 0.1, piece.get_center().y), _ceiling, LAYER_CEILING)
	for rs in _map["terrace_edges"]:
		for rc in rs:
			_floor_rect(rc, _stone)
	# Schwellen: unter jeder Tür liegt die Wand – ohne Boden dort risse das NavMesh ab
	for d in _doors:
		var door: Door = d["door"]
		if door.monster_can_open:
			var into: Vector3 = d["into"]
			var size := Vector3(door.width, 0.2, T) if absf(into.z) > 0.5 else Vector3(T, 0.2, door.width)
			Geo.solid(root, size, (d["pos"] as Vector3) + Vector3(0, -0.1, 0), _wood)


func _floor_rect(rc: Array, mat: Material) -> void:
	var size := Vector3(float(rc[2]) - float(rc[0]), 0.2, float(rc[3]) - float(rc[1]))
	Geo.solid(root, size, Vector3((float(rc[0]) + float(rc[2])) / 2.0, -0.1, (float(rc[1]) + float(rc[3])) / 2.0), mat)


func _floor_material(kind: String, rc: Array) -> Material:
	match kind:
		"room", "bar", "party":
			return _wood_floor
		"corridor":
			var mid := Vector2((float(rc[0]) + float(rc[2])) / 2.0, (float(rc[1]) + float(rc[3])) / 2.0)
			return _floor_tiles if _lobby.has_point(mid) else _carpet
		"garden":
			return _grass
		"terrace":
			return _stone
		"storage":
			return _concrete
	return _floor_tiles


## Rechteck minus Löcher → Rechtecke.
func _subtract(r: Rect2, holes: Array[Rect2]) -> Array[Rect2]:
	var pieces: Array[Rect2] = [r]
	for h in holes:
		var next: Array[Rect2] = []
		for p in pieces:
			var i := p.intersection(h)
			if i.size.x <= 0.001 or i.size.y <= 0.001:
				next.append(p)
				continue
			if i.position.y > p.position.y:
				next.append(Rect2(p.position.x, p.position.y, p.size.x, i.position.y - p.position.y))
			if i.end.y < p.end.y:
				next.append(Rect2(p.position.x, i.end.y, p.size.x, p.end.y - i.end.y))
			if i.position.x > p.position.x:
				next.append(Rect2(p.position.x, i.position.y, i.position.x - p.position.x, i.size.y))
			if i.end.x < p.end.x:
				next.append(Rect2(i.end.x, i.position.y, p.end.x - i.end.x, i.size.y))
		pieces = next
	return pieces


# --- Zimmer ------------------------------------------------------------------------------------------

## Ein Zimmer des Plans. Gebaut wird im Rahmen der Tür: Ursprung = Türmitte auf der Wandmitte,
## +X an der Flurwand entlang, +Z ins Zimmer. x0…x1 = Innenmaß an der Türwand, depth = bis zur Rückwand.
func _room(plan: Dictionary) -> void:
	var no := String(plan["no"])
	var door_pos := _v3(plan["door"]["pos"])
	var normal: Array = plan["door"]["normal"]
	var into := Vector3(-float(normal[0]), 0, -float(normal[1]))
	var door := _door_near(door_pos)
	if not String(plan["wing"]) in OPEN_WINGS:
		return   # Bauphase: Tür verschlossen (_opening_object), kein Inneres
	assert(door != null, "Zimmer %s: keine Tür an der Stelle aus dem Plan" % no)
	var kind: String = ROOM_KINDS.get(no, "vacant")
	var holder := Node3D.new()
	holder.name = "Zimmer_%s" % no
	holder.position = door_pos
	holder.rotation.y = atan2(into.x, into.z)
	root.add_child(holder)
	_parent = holder
	# Innenmaß aus dem Rechteck an der Tür (Eckzimmer sind L-förmig)
	var rect: Array = plan["rects"][0]
	for rc in plan["rects"]:
		var probe := door_pos + into * 1.0
		if probe.x >= float(rc[0]) and probe.x <= float(rc[2]) and probe.z >= float(rc[1]) and probe.z <= float(rc[3]):
			rect = rc
	var x0 := INF
	var x1 := -INF
	var depth := 0.0
	for corner: Vector3 in [Vector3(rect[0], 0, rect[1]), Vector3(rect[2], 0, rect[1]), Vector3(rect[0], 0, rect[3]), Vector3(rect[2], 0, rect[3])]:
		var local: Vector3 = holder.global_transform.affine_inverse() * corner
		x0 = minf(x0, local.x)
		x1 = maxf(x1, local.x)
		depth = maxf(depth, local.z)
	var cx := (x0 + x1) / 2.0
	var label := String(plan["sign"])
	var info := {
		"no": no, "sign": label, "kind": kind,
		"center": _global(Vector3(cx, 0, depth / 2.0)),
		"door_front": _global(Vector3(0, 0, -0.9)),
		"door_inside": _global(Vector3(0, 0, 1.0)),
		"along": holder.global_transform.basis.x.normalized(),   # an der Flurwand entlang
		"into": into,                                             # vom Flur ins Zimmer
		"door": door,
		"spots": [],
	}
	_sign(label, Vector3(0, 2.45, -0.11), 180.0, SIGN_EM_ROOM)
	# Das Innere steht im Plan (_furniture, _fittings, _items, _lights); hier nur, was die Zimmerart ausmacht
	match kind:
		"abandoned", "derelict":
			door.set_open.call_deferred(true)   # verlassen bzw. verfallen: die Tür steht offen
		"locked":
			door.locked = true
			door.key_id = "zimmer_18"
			door.locked_text = "Zimmer %s ist abgeschlossen." % label
	rooms[no] = info
	_parent = root


# --- Einrichtung aus dem Plan ---------------------------------------------------------------------------

## Platz an der Wand für eine Wandsache des Plans (Leuchte, Schalter, Bild …).
class WallSpot:
	var pos: Vector2      ## auf der Wandfläche, plus Abstand
	var out: Vector2      ## von der Wand weg in den Raum
	var inside: Vector2   ## ein Stück im Raum – dort werden Raum-ID und Flächenart nachgeschlagen
	var side: String      ## Wandseite aus dem Plan (`wall`)

	func yaw() -> float:
		return atan2(out.x, out.y)

	func at(y: float) -> Vector3:
		return Vector3(pos.x, y, pos.y)


## Möbel (Ebene „Möbel“): Rechteck = Grundfläche, `facing` = Vorderseite. Verstecke, Kommoden, Truhe, Spieltische
## und Sofas sind eigene Bauteile in der Mitte des Rechtecks, alles andere Kästen in Plangröße (BOX_HEIGHTS).
## Dazu die Rezeption aus dem Grundriss. Verschlossene Zimmer bleiben leer.
func _furniture() -> void:
	for rc in _map["reception"]:
		var r := Rect2(rc[0], rc[1], rc[2] - rc[0], rc[3] - rc[1])
		var desk := Geo.solid(root, Vector3(r.size.x, RECEPTION_H, r.size.y), Vector3(r.get_center().x, RECEPTION_H / 2.0, r.get_center().y), _dark_wood)
		_furnishings.append({"kind": "reception", "rect": r, "top": RECEPTION_H, "front": Vector2.ZERO, "node": desk})
	for f in _map["furniture"]:
		var rc: Array = f["rect"]
		var rect := Rect2(rc[0], rc[1], rc[2] - rc[0], rc[3] - rc[1])
		var c := rect.get_center()
		if _kind_at(c) == "sealed":
			continue
		var kind := String(f["kind"])
		var front := _facing(String(f.get("facing", "")), c)
		var yaw := atan2(front.x, front.y)
		var pos := Vector3(c.x, 0, c.y)
		var node: Node3D
		var top := 0.0
		match kind:
			"bed", "wardrobe":
				var spot := _hide_spot(HideSpot.Type.BED if kind == "bed" else HideSpot.Type.WARDROBE, pos, yaw)
				var room: Dictionary = rooms.get(_room_id_at(c), {})
				if not room.is_empty():
					spot.own_bed = kind == "bed" and room["kind"] == "player"
					(room["spots"] as Array).append(spot)
				node = spot
				top = 0.6 if kind == "bed" else 2.18
			"dresser":
				node = Dresser.new()   # Schubladen (Spielkonzept 3.5)
				top = Dresser.SIZE.y
			"chest":
				node = Chest.new()
				top = Chest.SIZE.y
			"chess_table":
				chess_table = ChessTable.new()
				node = chess_table
				top = 0.76
			"game_table":
				game_table = GameTable.new()
				node = game_table
				top = 0.76
			"couch":
				node = _couch(pos, yaw - PI / 2.0)   # das Modell sitzt nach +X
				top = 0.45
			_:
				if not BOX_HEIGHTS.has(kind):
					push_warning("Gebäudeplan: unbekannte Möbelart „%s“ bei %s" % [kind, c])
					continue
				top = BOX_HEIGHTS[kind]
				node = _box_furniture(kind, rect, top, front)
				if kind == "bar_counter":
					top += 0.045   # Thekenplatte
		if node.get_parent() == null:
			node.position = pos
			node.rotation.y = yaw
			root.add_child(node)
		_furnishings.append({"kind": kind, "rect": rect, "top": top, "front": front, "node": node})


## Möbel als Kasten in der Grundfläche des Plans; Theke mit Platte, Waschmaschine mit Bullauge vorn.
func _box_furniture(kind: String, rect: Rect2, height: float, front: Vector2) -> StaticBody3D:
	var mat := _wood
	match kind:
		"bench", "bar_counter":
			mat = _dark_wood
		"kitchen_counter":
			mat = Mat.psx(Color(0.55, 0.5, 0.42))
		"stove":
			mat = Mat.psx(Color(0.2, 0.2, 0.22))
		"washbasin":
			mat = Mat.psx(Color(0.85, 0.85, 0.82))
		"washing_machine":
			mat = Mat.psx(Color(0.75, 0.75, 0.72))
		"laundry_box":
			mat = Mat.psx(Color(0.6, 0.58, 0.5))
		"pillar":
			mat = Mat.psx(Color(0.6, 0.57, 0.5))
	var c := rect.get_center()
	var body := Geo.solid(root, Vector3(rect.size.x, height, rect.size.y), Vector3(c.x, height / 2.0, c.y), mat)
	match kind:
		"bar_counter":
			Geo.mesh(body, Geo.box(Vector3(rect.size.x + 0.1, 0.05, rect.size.y + 0.1)), _wood, Vector3(0, height / 2.0 + 0.02, 0))
		"washing_machine":
			var half := rect.size / 2.0
			var porthole := Geo.mesh(body, Geo.cylinder(0.2, 0.02, 10), Mat.psx(Color(0.15, 0.17, 0.2)),
				Vector3(front.x * (half.x + 0.005), 0.1, front.y * (half.y + 0.005)))
			if absf(front.x) > 0.5:
				porthole.rotation.z = PI / 2.0
			else:
				porthole.rotation.x = PI / 2.0
	return body


## Ausstattung (Ebene „Ausstattung“). Wandsachen hängen an der Wandseite aus dem Plan; Telefone, Zettel, Tagebuch
## und Vorräte stehen auf dem Möbel darunter. Zettel-Nummern und UV-Texte kommen aus CONTENT.
func _fittings() -> void:
	var paintings := 0
	var plants := 0
	for o in _map["fittings"]:
		var p := _v2(o["pos"])
		if _kind_at(p) == "sealed":
			continue
		var kind := String(o["kind"])
		var top := _top_at(p)
		var content: Dictionary = CONTENT.get(_room_id_at(p), {})
		match kind:
			"switch":
				var at := _wall_spot(o, WALL_GAP)
				var id := _light_room_at(at.inside)
				var sw := _switch(id, _switch_label(id), at.at(SWITCH_Y), at.yaw())
				if rooms.has(id) and rooms[id]["kind"] == "vacant":
					sw.set_on.call_deferred(false, true)   # unbewohnt: dunkel
			"painting":
				var at := _wall_spot(o, WALL_GAP)
				var area := _kind_at(at.inside)
				var y := 2.2 if area == "lobby" else (1.9 if area == "bar" else 1.75)   # im Flur über den Kommoden
				_painting(at.at(y), at.yaw(), PAINTING_COLORS[paintings % PAINTING_COLORS.size()])
				paintings += 1
			"cobweb":
				# In einer Ecke (zweite Wand quer dazu nah) hängt die Spinnwebe schräg über Eck
				var at := _wall_spot(o, 0.02)
				for side in _perpendicular(at.side):
					if not _on_wall(p, side, 0.5).is_empty():
						at = _wall_spot(o, 0.12)
						at.out = (at.out - _dir(side)).normalized()
				_resource_web(at.at(COBWEB_Y), at.yaw())
			"uv_writing":
				var at := _wall_spot(o, WALL_GAP)
				var text := String(CONTENT.get(_room_id_at(at.inside), {}).get("uv", ""))
				if text == "":
					push_warning("Gebäudeplan: UV-Schrift bei %s ohne Text in CONTENT" % p)
					continue
				_uv_writing(text, at.at(UV_Y), at.yaw())
			"calendar":
				var at := _wall_spot(o, WALL_GAP)
				var calendar := Calendar.new()
				calendar.position = at.at(CALENDAR_Y)
				calendar.rotation.y = at.yaw()
				root.add_child(calendar)
			"phone":
				var phone := HotelPhone.new().setup(_room_id_at(p))   # Wählscheibentelefon (Spielkonzept 4.14)
				phone.position = Vector3(p.x, top, p.y)
				phone.rotation.y = _upright_yaw(p)
				root.add_child(phone)
			"note":
				if not content.has("note"):
					push_warning("Gebäudeplan: Zettel bei %s ohne Nummer in CONTENT" % p)
					continue
				var note := _note(String(content["note"]), Vector3(p.x, top + 0.01, p.y))
				note.rotation.y = _upright_yaw(p)
			"diary":
				diary = Diary.new()
				diary.position = Vector3(p.x, top + 0.01, p.y)
				diary.rotation.y = _upright_yaw(p) + 0.3   # leicht schräg hingelegt
				root.add_child(diary)
			"candle_supply":
				_supply(ResourceSpot.new().setup(Item.Kind.CANDLE, "Kerze aus dem Vorrat", 3, 150.0), Vector3(p.x, top, p.y))
			"bulb_supply":
				_supply(ResourceSpot.new().setup(Item.Kind.BULB, "Ersatzbirne aus dem Lager", 2, 300.0), Vector3(p.x, BULB_SUPPLY_Y, p.y))
			"leaf_pile":
				_supply(ResourceSpot.new().setup(Item.Kind.LEAVES, "Herbstlaub", 4, 60.0), Vector3(p.x, top, p.y))
			"pumpkin_plant":
				var plant := PumpkinPlant.new().setup(PLANT_STAGES[plants % PLANT_STAGES.size()])
				plant.position = Vector3(p.x, 0.05, p.y)   # auf dem Beet (_garden_beds)
				root.add_child(plant)
				plants += 1
			_:
				push_warning("Gebäudeplan: unbekannte Ausstattung „%s“ bei %s" % [kind, p])


func _supply(spot: ResourceSpot, pos: Vector3) -> void:
	spot.position = pos
	root.add_child(spot)


## Gegenstände (Ebene „Gegenstände“, Art = Item.Kind): auf dem Möbel darunter oder am Boden. Münzbetrag und
## Kartenblatt aus CONTENT.
func _items() -> void:
	for o in _map["items"]:
		var p := _v2(o["pos"])
		if _kind_at(p) == "sealed":
			continue
		var kind_id: int = Item.Kind.get(String(o["kind"]), -1)
		if kind_id < 0:
			push_warning("Gebäudeplan: unbekannter Gegenstand „%s“ bei %s" % [o["kind"], p])
			continue
		var kind := kind_id as Item.Kind
		var content: Dictionary = CONTENT.get(_room_id_at(p), {})
		var extra := ""
		match kind:
			Item.Kind.COINS:
				extra = String(content.get("coins", "1"))
			Item.Kind.MAP:
				extra = String(content.get("map", "eg"))
			Item.Kind.KEY:
				extra = String(content.get("key", ""))
		_item(kind, Vector3(p.x, _top_at(p) + 0.02, p.y), extra)


## Lichter (Ebene „Lichter“): Wandleuchten an der Wand (Höhe und Helligkeit je Fläche, _lamp_style),
## Deckenleuchten an der Decke darüber, Kerzen auf dem Möbel darunter, Laternen im Garten. Defekt laut Plan.
func _lights() -> void:
	for o in _map["lights"]:
		var p := _v2(o["pos"])
		if _kind_at(p) == "sealed":
			continue
		var broken := bool(o.get("broken", false))
		match String(o["kind"]):
			"wall_lamp":
				var at := _wall_spot(o, WALL_GAP)
				var id := _light_room_at(at.inside)
				var style := _lamp_style(_kind_at(at.inside), id, at.side)
				_wall_lamp(at.at(style["y"]), at.yaw(), style["energy"], style["range"], id, broken)
			"ceiling_lamp":
				_ceiling_lamp(p, _light_room_at(p), broken)
			"candle":
				_candle(Vector3(p.x, _top_at(p), p.y))
			"lantern":
				_lantern(Vector3(p.x, 0, p.y), broken, 1.0 if absf(p.x) < 15.0 else 0.8)   # in den Innenhöfen schwächer
			_:
				push_warning("Gebäudeplan: unbekanntes Licht „%s“ bei %s" % [o["kind"], p])


## Höhe, Helligkeit und Reichweite einer Wandleuchte je Flächenart (Spielkonzept 7.3): {y, energy, range}.
func _lamp_style(area: String, id: String, side: String) -> Dictionary:
	if id == "umkleiden":
		return {"y": 2.1, "energy": WALL_LAMP_ENERGY * 0.8, "range": 5.0}
	match area:
		"room":
			return {"y": 2.0, "energy": ROOM_LAMP_ENERGY, "range": 6.5}
		"lobby":   # große, hohe Halle: kräftiger, mehr Reichweite; über dem Eingang höher
			return {"y": 2.6 if side == "south" else 2.4, "energy": WALL_LAMP_ENERGY * 1.3, "range": 8.0}
		"pool":
			return {"y": 2.4, "energy": WALL_LAMP_ENERGY, "range": 7.0}
		"storage":
			return {"y": 2.1, "energy": WALL_LAMP_ENERGY * 0.8, "range": 5.0}
		"toilet":
			return {"y": 2.1, "energy": WALL_LAMP_ENERGY, "range": 5.0}
		"stairs":   # an der Nordwand hängt sie über dem Podest auf halbem Weg in den Keller
			return {"y": CELLAR_Y / 2.0 + 1.8 if side == "north" else 2.0, "energy": WALL_LAMP_ENERGY, "range": 6.0}
	return {"y": 2.1, "energy": WALL_LAMP_ENERGY, "range": 6.0}


## Raum-ID für Lampen und Schalter: wie _room_id_at, nur teilen sich Umkleiden und Duschen einen Schalter.
func _light_room_at(p: Vector2) -> String:
	var id := _room_id_at(p)
	if id in CHANGING_ROOMS:
		return "umkleiden"
	if id == "treppenhaus_ost":
		return "treppenhaus"
	return id


func _switch_label(id: String) -> String:
	if rooms.has(id):
		return "Zimmer " + String(rooms[id]["sign"])
	match id:
		"lobby":
			return "Lobby"
		"umkleiden":
			return "Umkleiden"
		"treppenhaus":
			return "Treppenhaus"
		"toilette_west", "toilette_ost":
			return "Toilette"
	for c in _map["corridors"]:
		if c["id"] == id:
			return String(c["name"])
	return _region_name(id)


## Wandsache o des Plans an ihre Wand setzen: Wandseite `wall`, Abstand gap vor der Wandfläche.
func _wall_spot(o: Dictionary, gap: float) -> WallSpot:
	var spot := WallSpot.new()
	var p := _v2(o["pos"])
	spot.side = String(o.get("wall", ""))
	if spot.side == "":
		push_warning("Gebäudeplan: %s bei %s liegt an keiner Wand" % [o["kind"], p])
		spot.side = "north"
	spot.out = -_dir(spot.side)
	var face := _on_wall(p, spot.side, 0.6)
	var on_face: Vector2 = face.get("pos", p - spot.out * 0.15)   # ohne Wandstück: der Punkt liegt an der Wand
	spot.pos = on_face + spot.out * gap
	spot.inside = p + spot.out * 0.3
	return spot


## Nächste Wandfläche von p aus in Richtung side (höchstens max_dist entfernt): {pos} oder {}.
func _on_wall(p: Vector2, side: String, max_dist: float) -> Dictionary:
	var dir := _dir(side)
	var horizontal := absf(dir.y) > 0.5   # Wand quer zu z → verläuft entlang x
	var s := p.x if horizontal else p.y
	var across := p.y if horizontal else p.x
	var toward := dir.y if horizontal else dir.x
	var best := {}
	var best_d := max_dist
	for w in _wall_index:
		if w["horizontal"] != horizontal or s < float(w["from"]) - 0.05 or s > float(w["to"]) + 0.05:
			continue
		var face := float(w["at"]) - toward * float(w["half"])
		var d := (face - across) * toward
		if d < -0.05 or d > best_d:
			continue
		best_d = d
		best = {"pos": Vector2(p.x, face) if horizontal else Vector2(face, p.y)}
	return best


## Himmelsrichtung → Richtung (x, z).
func _dir(side: String) -> Vector2:
	match side:
		"north":
			return Vector2(0, -1)
		"south":
			return Vector2(0, 1)
		"west":
			return Vector2(-1, 0)
	return Vector2(1, 0)


func _perpendicular(side: String) -> Array[String]:
	if side == "north" or side == "south":
		return ["west", "east"]
	return ["north", "south"]


## Vorderseite: Himmelsrichtung aus dem Plan, sonst zur Mitte der Fläche hin (auf eine Achse gerundet).
func _facing(side: String, p: Vector2) -> Vector2:
	if side != "":
		return _dir(side)
	var to := _area_center(p) - p
	if absf(to.x) > absf(to.y):
		return Vector2(signf(to.x), 0)
	return Vector2(0, -1 if to.y < 0 else 1)


## Blickrichtung für Telefon, Zettel und Tagebuch: in Zimmern vom Flur weg, sonst zur Mitte der Fläche.
func _upright_yaw(p: Vector2) -> float:
	var dir := _facing("", p)
	var room: Dictionary = rooms.get(_room_id_at(p), {})
	if not room.is_empty():
		var into: Vector3 = room["into"]
		dir = Vector2(into.x, into.z)
	return atan2(dir.x, dir.y)


func _area_center(p: Vector2) -> Vector2:
	var id := _room_id_at(p)
	if rooms.has(id):
		var c: Vector3 = rooms[id]["center"]
		return Vector2(c.x, c.z)
	if id == "lobby":
		return _lobby.get_center()
	if _named.has(id):
		return (_named[id] as Rect2).get_center()
	return p


## Oberkante des Möbels unter p (0 = Boden): darauf stehen Kerzen, Telefone und Gegenstände des Plans.
func _top_at(p: Vector2) -> float:
	var top := 0.0
	for f in _furnishings:
		if (f["rect"] as Rect2).grow(0.05).has_point(p):
			top = maxf(top, float(f["top"]))
	return top


## Erstes Möbel dieser Art in der benannten Fläche ({} = keins).
func _furnishing(kind: String, area: String) -> Dictionary:
	for f in _furnishings:
		if f["kind"] == kind and (_named[area] as Rect2).has_point((f["rect"] as Rect2).get_center()):
			return f
	return {}


# --- Lobby und Galerie ---------------------------------------------------------------------------------

## Lobby: Teppich vor der Rezeption, Liegeplatz der Katzen auf der Rezeption, Sitzplätze vor den Sofas,
## Schilder. Die Einrichtung steht im Plan.
func _lobby_hall() -> void:
	lobby_center = Vector3(_lobby.get_center().x, 0, _lobby.get_center().y)
	var west := _lobby.position.x
	var east := _lobby.end.x
	Geo.mesh(root, Geo.box(Vector3(6.0, 0.02, 8.0)), Mat.layer(Color(0.32, 0.07, 0.08)), Vector3(0, 0.01, -5.0))
	var front: Array = _map["reception"][0]
	for rc in _map["reception"]:
		if float(rc[2]) - float(rc[0]) > float(front[2]) - float(front[0]):
			front = rc
	var fz := (float(front[1]) + float(front[3])) / 2.0
	cat_perches.append({"floor": Vector3(2.9, 0, fz - 0.8), "top": Vector3(2.3, RECEPTION_H + 0.02, fz - 0.8), "yaw": PI / 2.0})
	# Vor jedem Sofa zwei Sitzplätze für Gäste, obendrauf zwei Liegeplätze für die Katzen
	for f in _furnishings:
		var c: Vector2 = (f["rect"] as Rect2).get_center()
		if f["kind"] != "couch" or not _lobby.has_point(c):
			continue
		var out: Vector2 = f["front"]
		for s: float in [-0.5, 0.5]:
			var seat := c + out * 0.7 + Vector2(-out.y, out.x) * s
			var top := c + out * 0.07 + Vector2(-out.y, out.x) * s
			lobby_seats.append(Vector3(seat.x, 0, seat.y))
			cat_perches.append({"floor": Vector3(seat.x, 0, seat.y), "top": Vector3(top.x, 0.46, top.y)})
	_sign("BAR", Vector3(west + 0.11, 2.75, -13.0), 90.0)
	_sign("PARTY", Vector3(east - 0.11, 2.75, -13.0), -90.0)
	_sign("GARTEN", Vector3(-5.5, 2.75, _lobby.position.y + 0.11), 0.0)
	_sign("POOL", Vector3(5.5, 2.75, _lobby.position.y + 0.11), 0.0)


func _void() -> Rect2:
	var rc: Array = _map["open_above"][0]
	return Rect2(rc[0], rc[1], rc[2] - rc[0], rc[3] - rc[1])


## Galerie im Obergeschoss rund um den Luftraum (Spielkonzept 7.5): Boden mit Geländer, Treppe hinauf,
## Wände bis zur Decke über dem Luftraum. Die Türen ins Obergeschoss sind noch gesperrt.
func _gallery() -> void:
	var void_rect := _void()
	var hall := Rect2(_lobby.position, _lobby.size)
	# Boden der Galerie = Decke der Lobby unter ihr (0,5 m dick, sonst klafft eine Fuge an der Kante)
	for piece in _subtract(hall, [void_rect]):
		Geo.solid(root, Vector3(piece.size.x, 0.5, piece.size.y), Vector3(piece.get_center().x, H + 0.25, piece.get_center().y), _ceiling, LAYER_CEILING)
		Geo.solid(root, Vector3(piece.size.x, 0.02, piece.size.y), Vector3(piece.get_center().x, UP_Y + 0.01, piece.get_center().y), _carpet)
	# Wände im Obergeschoss (über den Lobbywänden) und Decke über allem
	var top := UP_Y + H
	var x0 := hall.position.x - T / 2.0
	var x1 := hall.end.x + T / 2.0
	var z0 := hall.position.y - T / 2.0
	var z1 := hall.end.y + T / 2.0
	var upper := Node3D.new()
	upper.position.y = H
	root.add_child(upper)
	_parent = upper
	var door_bottom := UP_Y - H
	_wall_z(x0, z0, z1, [Vector4(-8.0, DOOR_W, door_bottom + DOOR_H, door_bottom)], _lobby_wallpaper, top - H)
	_wall_z(x1, z0, z1, [Vector4(-8.0, DOOR_W, door_bottom + DOOR_H, door_bottom)], _lobby_wallpaper, top - H)
	_wall_x(z0, x0 - T / 2.0, x1 + T / 2.0, [], _lobby_wallpaper, top - H)
	_wall_x(z1, x0 - T / 2.0, x1 + T / 2.0, [], _lobby_wallpaper, top - H)
	_parent = root
	Geo.solid(root, Vector3(hall.size.x + 0.4, 0.2, hall.size.y + 0.4), Vector3(hall.get_center().x, top + 0.1, hall.get_center().y), _ceiling, LAYER_CEILING)
	for x: float in [x0, x1]:
		var door := Door.new().setup(DOOR_W, DOOR_H, -100.0)
		var inward := 1.0 if x < 0 else -1.0   # +Z der Tür zeigt in die Galerie
		door.rotation.y = PI / 2.0 * inward
		door.position = Vector3(x, UP_Y, -8.0 + DOOR_W / 2.0 * inward)
		root.add_child(door)
		_seal(door, "Abgesperrt. Das Obergeschoss ist noch nicht zugänglich.")
	# Geländer an den offenen Kanten (die Treppe kommt im Nordwesten an)
	var stair: Dictionary = _lobby_stair()
	var stair_rect: Array = stair["rect"]
	_railing(Vector3(void_rect.position.x, UP_Y, void_rect.position.y), Vector3(void_rect.position.x, UP_Y, void_rect.end.y))
	_railing(Vector3(void_rect.end.x, UP_Y, void_rect.position.y), Vector3(void_rect.end.x, UP_Y, void_rect.end.y))
	_railing(Vector3(float(stair_rect[2]), UP_Y, void_rect.position.y), Vector3(void_rect.end.x, UP_Y, void_rect.position.y))
	# Treppe: vom Lobbyboden hinauf zur Galerie, oberes Ende laut Plan
	var up := String(stair.get("up", "north"))
	var sx := (float(stair_rect[0]) + float(stair_rect[2])) / 2.0
	var width := float(stair_rect[2]) - float(stair_rect[0])
	var z_low := float(stair_rect[3]) if up == "north" else float(stair_rect[1])
	var z_high := float(stair_rect[1]) if up == "north" else float(stair_rect[3])
	_flight(sx, z_low, z_high, 0.0, UP_Y, width)
	for x: float in [x0 + 0.12, x1 - 0.12]:
		_wall_lamp(Vector3(x, UP_Y + 2.0, -14.0), PI / 2.0 if x < 0 else -PI / 2.0, WALL_LAMP_ENERGY, 7.0, "galerie")
	_switch("galerie", "Galerie", Vector3(sx + width / 2.0 + 0.6, UP_Y + 1.3, hall.position.y + 0.12), 0.0)


func _lobby_stair() -> Dictionary:
	for s in _map["stairs"]:
		if s["kind"] == "stair":
			return s
	return {}


## Geländer von a nach b (Kollision 1 m hoch, Handlauf und Stäbe).
func _railing(a: Vector3, b: Vector3) -> void:
	var length := a.distance_to(b)
	if length < 0.1:
		return
	var holder := Node3D.new()
	holder.position = (a + b) / 2.0
	holder.rotation.y = atan2(b.x - a.x, b.z - a.z) - PI / 2.0
	root.add_child(holder)
	Geo.collider(holder, Vector3(length, 1.0, 0.1), Vector3(0, 0.5, 0))
	Geo.mesh(holder, Geo.box(Vector3(length, 0.06, 0.1)), _dark_wood, Vector3(0, 1.0, 0))
	var n := maxi(2, roundi(length / 0.5))
	for i in n + 1:
		Geo.mesh(holder, Geo.box(Vector3(0.04, 1.0, 0.04)), _dark_wood, Vector3(-length / 2.0 + length * i / n, 0.5, 0))


# --- Gemeinschaftsräume, Pool ---------------------------------------------------------------------------

## Was Bar, Partyraum und Küche über den Plan hinaus brauchen: Flaschen auf dem Barregal, Hocker vor der Theke
## (Spielkonzept 6.10), Tanzfläche und Plattenspieler-Tisch, Treffpunkte für Gäste und Monster.
func _common_rooms() -> void:
	var shelf := _furnishing("shelf", "bar")
	if not shelf.is_empty():
		var r: Rect2 = shelf["rect"]
		var along := Vector2(1, 0) if r.size.x >= r.size.y else Vector2(0, 1)
		var length := maxf(r.size.x, r.size.y)
		var pack := (load(BOTTLES_MODEL) as PackedScene).instantiate()
		var bottles := pack.find_children("bottle_*", "MeshInstance3D", true, false)
		for i in 14:   # jede Flasche nur einmal (5 und 28 sind teilerfremd)
			var src: MeshInstance3D = bottles[i * 5 % bottles.size()]
			var p := r.get_center() + along * (-length / 2.0 + 0.3 + i * (length - 0.6) / 13.0)
			var bottle := Geo.mesh(root, src.mesh, Mat.model(BOTTLES_MODEL, src), Vector3(p.x, float(shelf["top"]), p.y))
			bottle.rotation.y = i * 1.3
		pack.free()
	var counter := _furnishing("bar_counter", "bar")
	if not counter.is_empty():
		var r: Rect2 = counter["rect"]
		var out: Vector2 = counter["front"]
		var along := Vector2(1, 0) if r.size.x >= r.size.y else Vector2(0, 1)
		var span := maxf(r.size.x, r.size.y) - 2.2
		for i in 4:
			var p := r.get_center() + along * (-span / 2.0 + i * span / 3.0)
			var stool := Geo.mesh(root, Geo.cylinder(0.18, 0.05, 8), Mat.psx(Color(0.4, 0.1, 0.1)), Vector3(p.x + out.x * 0.8, 0.7, p.y + out.y * 0.8))
			Geo.mesh(stool, Geo.cylinder(0.04, 0.7, 5), _dark_wood, Vector3(0, -0.35, 0))
			bar_spots.append(Vector3(p.x + out.x * 1.2, 0, p.y + out.y * 1.2))
	# Partyraum: Plattenspieler auf dem Tisch, dunkle Ecke (dort steht es beim ersten Angriff), Tanzfläche
	var r: Rect2 = _named["partyraum"]
	var c := r.get_center()
	var table := _furnishing("table", "partyraum")
	if not table.is_empty():
		var t: Vector2 = (table["rect"] as Rect2).get_center()
		record_player_pos = Vector3(t.x, float(table["top"]), t.y)
	party_corner = Vector3(r.position.x + 0.9, 0, r.position.y + 0.9)
	Geo.mesh(root, Geo.box(Vector3(6.0, 0.02, 6.0)), Mat.layer(Color(0.12, 0.1, 0.16)), Vector3(c.x, 0.01, c.y))
	for i in 6:
		var a := TAU * i / 6.0
		party_spots.append(Vector3(c.x + cos(a) * 1.6, 0, c.y + sin(a) * 1.6))
	var k: Rect2 = _named["kueche"]
	kitchen_spot = Vector3(k.get_center().x, 0, k.get_center().y)


func _region_name(id: String) -> String:
	for r in _map["regions"]:
		if r["id"] == id:
			return String(r.get("name", id))
	return id


## Hallenbad: Becken 1,4 m tief mit Wasseroberfläche. An beiden Schmalseiten führt eine Einstiegstreppe
## mit Handlauf hinaus – hochspringen reicht nicht (Sprung ≈ 0,7 m).
func _pool() -> void:
	var w: Rect2 = _named["becken"]
	var depth := 1.4
	Geo.solid(root, Vector3(w.size.x, 0.2, w.size.y), Vector3(w.get_center().x, -depth - 0.1, w.get_center().y), _wall_tiles)
	# Beckenränder innerhalb der Wasserfläche (der Umgang endet an ihrer Kante)
	for s: float in [-1.0, 1.0]:
		Geo.solid(root, Vector3(w.size.x, depth, 0.2), Vector3(w.get_center().x, -depth / 2.0, w.get_center().y + s * (w.size.y / 2.0 - 0.1)), _wall_tiles)
		Geo.solid(root, Vector3(0.2, depth, w.size.y - 0.4), Vector3(w.get_center().x + s * (w.size.x / 2.0 - 0.1), -depth / 2.0, w.get_center().y), _wall_tiles)
	# Einstiegstreppen: von der Südkante entlang der West- bzw. Ostwand hinab, Handlauf an der offenen Seite
	var stair_w := 1.2
	var run := 2.0
	var z_top := w.end.y - 0.2
	var chrome := Mat.psx(Color(0.62, 0.66, 0.7))
	for s: float in [-1.0, 1.0]:
		var x := w.get_center().x + s * (w.size.x / 2.0 - 0.2 - stair_w / 2.0)
		_flight(x, z_top, z_top - run, 0.0, -depth, stair_w, _wall_tiles)
		var xr := x - s * (stair_w / 2.0 - 0.08)
		var top := Vector3(xr, 0.9, z_top + 0.35)
		var bend := Vector3(xr, 0.9, z_top - 0.1)
		var low := Vector3(xr, -depth + 0.9, z_top - run + 0.2)
		_rod(Vector3(top.x, 0.0, top.z), top, chrome)
		_rod(top, bend, chrome)
		_rod(bend, low, chrome)
		_rod(low, Vector3(low.x, -depth, low.z), chrome)
	# Wasser: halbtransparent, Wellen rein optisch (PoolWater)
	root.add_child(PoolWater.new(w, -0.3, 0.2, _named["pool"]))


## Dünne Stange von a nach b (Handlauf, Geländerpfosten), ohne Kollision.
func _rod(a: Vector3, b: Vector3, mat: Material, radius: float = 0.025) -> void:
	var mi := Geo.mesh(root, Geo.cylinder(radius, a.distance_to(b), 6), mat, (a + b) / 2.0)
	var up := (b - a).normalized()
	var side := up.cross(Vector3.FORWARD if absf(up.z) < 0.9 else Vector3.RIGHT).normalized()
	mi.basis = Basis(side, up, side.cross(up))


# --- Gärten -----------------------------------------------------------------------------------------

func _gardens() -> void:
	_garden_beds()
	for t in _map["trees"]:
		_tree(_v3(t["center"]), float(t["radius"]))
	var has_model := ResourceLoader.exists(PLANTER_MODEL)
	for rc in _map["planters"]:
		var size := Vector2(float(rc[2]) - float(rc[0]), float(rc[3]) - float(rc[1]))
		var c := Vector3((float(rc[0]) + float(rc[2])) / 2.0, 0, (float(rc[1]) + float(rc[3])) / 2.0)
		if has_model:
			_planter(c, size)
		else:
			Geo.solid(root, Vector3(size.x, PLANTER_H, size.y), c + Vector3(0, PLANTER_H / 2.0, 0), _stone)
			Geo.mesh(root, Geo.sphere(size.x * 0.4, 1.2, 7, 4), _hedge, c + Vector3(0, PLANTER_H + 0.5, 0))
	for rs in _map["terrace_edges"]:
		for rc in rs:
			Geo.mesh(root, Geo.box(Vector3(float(rc[2]) - float(rc[0]), 0.25, float(rc[3]) - float(rc[1]))), _hedge,
				Vector3((float(rc[0]) + float(rc[2])) / 2.0, 0.125, (float(rc[1]) + float(rc[3])) / 2.0))


## Pflanzkübel aus `PLANTER_MODEL` auf der Bodenmitte c; Kollision (auch für das NavMesh) nur als Quader
## über die Grundfläche aus dem Plan, die Bepflanzung darüber bleibt durchlässig wie beim Platzhalter.
func _planter(c: Vector3, size: Vector2) -> void:
	var body := Geo.collider(root, Vector3(size.x, PLANTER_H, size.y), c + Vector3(0, PLANTER_H / 2.0, 0))
	var model: Node3D = (load(PLANTER_MODEL) as PackedScene).instantiate()
	model.position.y = -PLANTER_H / 2.0
	body.add_child(model)
	for m: MeshInstance3D in model.find_children("*", "MeshInstance3D", true, false):
		for s in m.mesh.get_surface_count():
			m.set_surface_override_material(s, Mat.model(PLANTER_MODEL, m, s, true))   # einseitige Blätter


## Kürbisbeete unter den Pflanzen des Plans (je Reihe ein Beet) und davor die Plätze, an denen Gäste im Garten
## stehen – das Beet nächst der Lobby zuerst.
func _garden_beds() -> void:
	var rows := {}   # z → x der Pflanzen
	for o in _map["fittings"]:
		if o["kind"] == "pumpkin_plant":
			var z := snappedf(float(o["pos"][1]), 0.5)
			if not rows.has(z):
				rows[z] = []
			(rows[z] as Array).append(float(o["pos"][0]))
	var order := rows.keys()
	order.sort_custom(func(a: float, b: float) -> bool: return absf(a - _lobby.position.y) < absf(b - _lobby.position.y))
	var dirt := Mat.psx(Color(0.22, 0.14, 0.08))
	for z: float in order:
		var xs: Array = rows[z]
		var x0: float = xs.min()
		var x1: float = xs.max()
		Geo.mesh(root, Geo.box(Vector3(x1 - x0 + 1.6, 0.06, 1.3)), dirt, Vector3((x0 + x1) / 2.0, 0.03, z))
		garden_spots.append(Vector3((x0 + x1) / 2.0, 0, z + 1.0))


## Baum mit Krone in der Größe des Plans (radius = Kronenradius). Kollision nur am Stamm, unter der Krone
## kann man durchgehen.
func _tree(pos: Vector3, radius: float) -> void:
	if ResourceLoader.exists(TREE_MODEL):
		var s := radius / TREE_RADIUS
		var body := Geo.collider(root, Vector3(TREE_TRUNK * s, TREE_TRUNK_H, TREE_TRUNK * s), pos + Vector3(0, TREE_TRUNK_H / 2.0, 0))
		var model: Node3D = (load(TREE_MODEL) as PackedScene).instantiate()
		model.position.y = -TREE_TRUNK_H / 2.0
		model.scale = Vector3.ONE * s
		body.add_child(model)
		for m: MeshInstance3D in model.find_children("*", "MeshInstance3D", true, false):
			for i in m.mesh.get_surface_count():
				m.set_surface_override_material(i, Mat.model(TREE_MODEL, m, i, true))   # offene Blattbüschel
		return
	var height := clampf(radius * 1.1, 3.2, 6.0)
	var trunk := Geo.solid(root, Vector3(0.5, height, 0.5), pos + Vector3(0, height / 2.0, 0), Mat.psx(Color(0.22, 0.15, 0.1)))
	var colors: Array[Color] = [Color(0.6, 0.25, 0.05), Color(0.7, 0.4, 0.08), Color(0.45, 0.12, 0.05)]
	var offsets: Array[Vector3] = [Vector3(0, height / 2.0, 0), Vector3(radius * 0.35, height / 2.0 - 0.6, radius * 0.2), Vector3(-radius * 0.3, height / 2.0 - 0.4, -radius * 0.25)]
	for i in 3:
		Geo.mesh(trunk, Geo.sphere(radius * (0.7 - i * 0.12), radius * (0.9 - i * 0.12), 8, 4), Mat.psx(colors[i]), offsets[i])


func _lantern(pos: Vector3, broken: bool, energy: float) -> void:
	Geo.solid(root, Vector3(0.12, 2.4, 0.12), pos + Vector3(0, 1.2, 0), Mat.psx(Color(0.1, 0.1, 0.1)))
	var mat := Mat.psx(Color(1, 0.95, 0.8), "", 1.0, Color(1.0, 0.8, 0.5), 2.5, false)
	Geo.mesh(root, Geo.box(Vector3(0.25, 0.3, 0.25)), mat, pos + Vector3(0, 2.55, 0))
	var light := FlickerLight.new()
	light.position = pos + Vector3(0, 2.3, 0)
	light.base_energy = energy * Lamp.BRIGHTNESS
	light.omni_range = 6.0 * Lamp.REACH
	light.light_color = Color(1.0, 0.75, 0.45)
	light.shadow_enabled = true
	light.broken = broken
	light.lamp_material = mat
	light.add_to_group("lamps")
	root.add_child(light)


# --- Treppenhäuser und Keller -----------------------------------------------------------------------

## Treppenhaus Ost: Schacht vom Keller bis unters Obergeschoss, je zwei Läufe mit Wendepodest im Norden.
## Die westliche Hälfte steigt zum Obergeschoss, die östliche führt hinab; unten geht es in den Keller,
## oben endet es (noch) an einer gesperrten Tür. Das Treppenhaus West ist in dieser Bauphase verschlossen.
func _stairwells() -> void:
	for s in _map["stairs"]:
		if s["kind"] != "stairwell":
			continue
		var door := _door_near(_v3(s["door"]["pos"]), 0.8)
		if s["id"] != "treppenhaus_ost":
			if door:
				_seal(door, "Das Treppenhaus ist abgesperrt.")
			continue
		var rc: Array = s["rect"]
		var x0 := float(rc[0])
		var x1 := float(rc[2])
		var zn := float(rc[1])   # Nordende (Podeste)
		var zs := float(rc[3])   # Südende (Tür)
		var mid := (x0 + x1) / 2.0
		var lane_w := (x1 - x0 - T) / 2.0
		var west := x0 + lane_w / 2.0
		var east := x1 - lane_w / 2.0
		var z_door := zs - 1.4   # Ende der Türzone
		var z_land := zn + 1.5   # Beginn des Podests
		var bottom := CELLAR_Y
		var top := UP_Y + H
		stairwell_point = Vector3(mid, 0, (zn + zs) / 2.0)
		# Böden: Türzone in jedem Geschoss, Schachtboden ganz unten, Podeste
		Geo.solid(root, Vector3(x1 - x0, 0.2, zs - z_door), Vector3(mid, -0.1, (zs + z_door) / 2.0), _wood_floor)
		Geo.solid(root, Vector3(x1 - x0, 0.2, zs - zn), Vector3(mid, bottom - 0.1, (zs + zn) / 2.0), _concrete)
		Geo.solid(root, Vector3(x1 - x0, 0.2, zs - z_door), Vector3(mid, UP_Y - 0.1, (zs + z_door) / 2.0), _wood_floor)
		Geo.solid(root, Vector3(x1 - x0, 0.2, z_land - zn), Vector3(mid, UP_Y / 2.0 - 0.1, (zn + z_land) / 2.0), _wood_floor)
		Geo.solid(root, Vector3(x1 - x0, 0.2, z_land - zn), Vector3(mid, bottom / 2.0 - 0.1, (zn + z_land) / 2.0), _concrete)
		Geo.solid(root, Vector3(x1 - x0 + 0.4, 0.2, zs - zn + 0.4), Vector3(mid, top + 0.1, (zs + zn) / 2.0), _ceiling, LAYER_CEILING)
		# Läufe: hinauf im Westen und zurück im Osten; hinab im Osten und zurück im Westen
		_flight(west, z_door, z_land, 0.0, UP_Y / 2.0, lane_w)
		_flight(east, z_land, z_door, UP_Y / 2.0, UP_Y, lane_w)
		_flight(east, z_door, z_land, 0.0, bottom / 2.0, lane_w)
		_flight(west, z_land, z_door, bottom / 2.0, bottom, lane_w)
		# Mittelwand zwischen den Läufen, Schachtwände unter und über dem Erdgeschoss
		Geo.solid(root, Vector3(T, top - bottom, z_door - z_land), Vector3(mid, (top + bottom) / 2.0, (z_door + z_land) / 2.0), _wallpaper)
		var cellar_door := Vector4(mid, 0.9, 1.8, 0.0)
		var og_door := Vector4(east, DOOR_W, UP_Y - H + DOOR_H, UP_Y - H)
		for level: Array in [[bottom, -bottom, [cellar_door]], [H, top - H, [og_door]]]:
			var holder := Node3D.new()
			holder.position.y = level[0]
			root.add_child(holder)
			_parent = holder
			_wall_x(zs + T / 2.0, x0 - T, x1 + T, level[2], _wallpaper if level[0] > 0 else _concrete, level[1])
			_wall_x(zn - T / 2.0, x0 - T, x1 + T, [], _wallpaper if level[0] > 0 else _concrete, level[1])
			_wall_z(x0 - T / 2.0, zn, zs, [], _wallpaper if level[0] > 0 else _concrete, level[1])
			_wall_z(x1 + T / 2.0, zn, zs, [], _wallpaper if level[0] > 0 else _concrete, level[1])
			_parent = root
		# Die niedrige Kellertür unten und die gesperrte Tür ins Obergeschoss oben
		var low := Door.new().setup(0.9, 1.8, -100.0)
		low.position = Vector3(mid - 0.45, bottom, zs + T / 2.0)
		root.add_child(low)
		Geo.solid(root, Vector3(1.0, 0.2, T + 0.02), Vector3(mid, bottom - 0.1, zs + T / 2.0), _concrete)   # Schwelle
		_sign("KELLER", Vector3(mid, bottom + 2.1, zs + T / 2.0 - 0.11), 180.0)
		var og := Door.new().setup(DOOR_W, DOOR_H, -100.0)
		og.position = Vector3(east + DOOR_W / 2.0, UP_Y, zs + T / 2.0)
		og.rotation.y = PI
		root.add_child(og)
		_seal(og, "Abgesperrt. Das Obergeschoss ist noch nicht zugänglich.")
		_sign("TREPPENHAUS", Vector3((x0 + x1) / 2.0, 2.9, zs + T / 2.0 + 0.11), 0.0)
		# Leuchten und Schalter im Erdgeschoss stehen im Plan; die über dem Erdgeschoss noch nicht (kein OG-Plan)
		_wall_lamp(Vector3(mid, UP_Y / 2.0 + 1.9, zn + WALL_GAP), 0.0, WALL_LAMP_ENERGY, 6.0, "treppenhaus")
		_wall_lamp(Vector3(x1 - WALL_GAP, UP_Y + 1.9, z_door - 0.4), -PI / 2.0, WALL_LAMP_ENERGY, 6.0, "treppenhaus")


## Ein gerader Treppenlauf entlang z von (z_from, y_from) nach (z_to, y_to).
func _flight(x: float, z_from: float, z_to: float, y_from: float, y_to: float, width: float = 1.4, mat: Material = null) -> void:
	if y_to < y_from:
		_flight(x, z_to, z_from, y_to, y_from, width, mat)   # abwärts = derselbe Lauf von unten gesehen
		return
	var run := absf(z_to - z_from)
	var rise := y_to - y_from
	var angle := atan2(rise, run)
	var dir := signf(z_to - z_from)   # Laufrichtung in z
	var ramp := StaticBody3D.new()
	ramp.collision_layer = 1
	ramp.collision_mask = 0
	ramp.rotation.x = angle * -dir
	ramp.position = Vector3(x, (y_from + y_to) / 2.0, (z_from + z_to) / 2.0)
	ramp.position -= ramp.transform.basis.y * 0.1
	root.add_child(ramp)
	Geo.add_box_shape(ramp, Vector3(width, 0.2, Vector2(run, rise).length()), Vector3.ZERO)
	var steps := roundi(rise / 0.25)
	var step_rise := rise / steps
	for i in steps:
		var y_top := y_from + step_rise * (i + 0.5)
		var z := z_from + dir * run * (i + 0.5) / steps
		Geo.mesh(root, Geo.box(Vector3(width, y_top - y_from + 0.05, run / steps)), mat if mat else _concrete, Vector3(x, (y_top + y_from - 0.05) / 2.0, z))


## Keller unter der Erde südlich des Treppenhauses Ost: Versteck des Monsters.
func _cellar() -> void:
	var s: Dictionary = {}
	for st in _map["stairs"]:
		if st["id"] == "treppenhaus_ost":
			s = st
	var rc: Array = s["rect"]
	var mid := (float(rc[0]) + float(rc[2])) / 2.0
	var zs := float(rc[3]) + T
	var cellar := Node3D.new()
	cellar.name = "Keller"
	cellar.position = Vector3(mid, CELLAR_Y, zs)
	cellar.rotation.y = -PI / 2.0   # lokale +X zeigt nach Süden
	root.add_child(cellar)
	_parent = cellar
	var L := CELLAR_LEN
	Geo.solid(cellar, Vector3(L + 0.2, 0.2, 6.2), Vector3(L / 2.0, -0.1, 0.0), _concrete)
	Geo.solid(cellar, Vector3(L + 0.4, 0.2, 6.4), Vector3(L / 2.0, CELLAR_H + 0.1, 0.0), _concrete, LAYER_CEILING)
	# Eingangswand nur neben dem Schacht (dessen Wand mit der Kellertür liegt dazwischen)
	var shaft_half := (float(rc[2]) - float(rc[0])) / 2.0 + T
	_wall_z(0.0, -3.1, -shaft_half, [], _concrete, CELLAR_H)
	_wall_z(0.0, shaft_half, 3.1, [], _concrete, CELLAR_H)
	_wall_z(L, -3.1, 3.1, [], _concrete, CELLAR_H)
	_wall_x(-3.0, 0.0, L, [], _concrete, CELLAR_H)
	_wall_x(3.0, 0.0, L, [], _concrete, CELLAR_H)
	_wall_lamp(Vector3(L / 2.0, 1.9, -2.89), 0.0, 0.6, 4.5, "keller", true)   # kaputte Birne, blitzt nur auf
	_switch("keller", "Keller", Vector3(0.6, 1.3, 2.88), PI)
	Geo.solid(cellar, Vector3(0.7, 0.7, 0.7), Vector3(L - 1.0, 0.35, -2.3), _dark_wood)
	Geo.solid(cellar, Vector3(0.6, 0.6, 0.6), Vector3(L - 0.9, 0.3, 2.4), _dark_wood)
	Geo.solid(cellar, Vector3(0.6, 0.45, 0.6), Vector3(L - 1.6, 0.225, 2.5), _dark_wood)
	Geo.solid(cellar, Vector3(1.8, 1.6, 0.5), Vector3(3.5, 0.8, -2.65), _wood)   # altes Regal
	_item(Item.Kind.KEY, Vector3(L - 1.0, 0.72, -2.3), "zimmer_18")
	_item(Item.Kind.COINS, Vector3(1.2, 0.02, 2.0), "2")
	_item(Item.Kind.BATTERY, Vector3(3.1, 1.61, -2.6))   # auf dem alten Regal
	_note("2011", Vector3(L - 0.9, 0.61, 2.4))
	_uv_writing("31.10.1987\nSIE HABEN IHN\nEINGESCHLOSSEN", Vector3(L - 0.11, 1.5, 0.0), -PI / 2.0)
	_resource_web(Vector3(L - 0.5, 1.7, -2.88), 0.0)
	_resource_web(Vector3(1.0, 1.7, 2.88), PI)
	_parent = root


# --- Zonen & Wegpunkte ------------------------------------------------------------------------------

func _zones() -> void:
	zones = [
		{"name": "Lobby", "center": lobby_center, "radius": 10.0},
		{"name": "Galerie", "center": lobby_center + Vector3(0, UP_Y, 0), "radius": 10.0},
		{"name": "Treppenhaus", "center": stairwell_point, "radius": 4.0},
		{"name": "Keller", "center": cellar_center(), "radius": 4.5},
	]
	for id in _named:
		var r: Rect2 = _named[id]
		zones.append({"name": _region_name(id), "center": Vector3(r.get_center().x, 0, r.get_center().y), "radius": minf(r.size.x, r.size.y) / 2.0 + 0.5})
	for r in _map["regions"]:
		if r["kind"] == "garden":
			var b := _bounds(r["rects"])
			zones.append({"name": _garden_name(b.get_center()), "center": Vector3(b.get_center().x, 0, b.get_center().y), "radius": minf(b.size.x, b.size.y) / 2.0})
	# Flurabschnitte: lange Flure als Kette von Kreisen
	for c in _map["corridors"]:
		var a := _v2(c["a"])
		var b := _v2(c["b"])
		var n := maxi(1, ceili(a.distance_to(b) / 12.0))
		for i in n:
			var p := a.lerp(b, (i + 0.5) / n)
			zones.append({"name": String(c["name"]), "center": Vector3(p.x, 0, p.y), "radius": a.distance_to(b) / n / 2.0 + 1.0})
	for no in rooms:
		var info: Dictionary = rooms[no]
		zones.append({"name": "Zimmer " + String(info["sign"]), "center": info["center"], "radius": 3.2})
	for zone in zones:
		zone["curiosity"] = 50.0
	spawn_points = [
		cellar_center() + Vector3(0, 0.05, 0),                             # Keller – das Versteck des Monsters
		(rooms["0117"]["center"] as Vector3) + Vector3(0, 0.05, 0),        # verlassenes Zimmer
		(rooms["0116"]["center"] as Vector3) + Vector3(0, 0.05, 0),        # Wäscherei
		garden_spots[0] + Vector3(0, 0.05, -12.0),                         # Garten
	]


func cellar_center() -> Vector3:
	for s in _map["stairs"]:
		if s["id"] == "treppenhaus_ost":
			var rc: Array = s["rect"]
			return Vector3((float(rc[0]) + float(rc[2])) / 2.0, CELLAR_Y, float(rc[3]) + T + CELLAR_LEN / 2.0)
	return Vector3.ZERO


func _garden_name(c: Vector2) -> String:
	if absf(c.x) < 15.0:
		return "Garten"
	return "Innenhof " + ("Nord" if c.y < -60.0 else "Süd") + ("ost" if c.x > 0.0 else "west")


## Wegpunkte: Flure alle 4 m, Zimmertüren, Lobby, Treppenhaus, Keller und die Gemeinschaftsräume.
## Das Monster nutzt sie, um aus dem Blickfeld zu verschwinden; Gäste schlendern durch die Flure.
func _waypoints() -> void:
	for c in _map["corridors"]:
		var a := _v2(c["a"])
		var b := _v2(c["b"])
		var n := maxi(1, floori(a.distance_to(b) / 4.0))
		for i in n + 1:
			var p := a.lerp(b, float(i) / n)
			if not _lobby.has_point(p):
				wander_points.append(Vector3(p.x, 0, p.y))
	for p in wander_points:
		patrol.append({"pos": p, "room": ""})
	for no in rooms:
		patrol.append({"pos": rooms[no]["door_front"], "room": no})
	var extra: Array[Vector3] = [lobby_center, lobby_center + Vector3(-4.0, 0, 6.0), lobby_center + Vector3(4.0, 0, -8.0),
		stairwell_point, stairwell_point + Vector3(0, UP_Y / 2.0, -2.2), cellar_center(), cellar_center() + Vector3(0, 0, 2.5),
		kitchen_spot, garden_spots[0], garden_spots[0] + Vector3(0, 0, -20.0)]
	for id: String in ["bar", "partyraum", "speisesaal", "pool"]:
		var r: Rect2 = _named[id]
		extra.append(Vector3(r.get_center().x, 0, r.get_center().y))
	for t in _map["trees"]:
		extra.append(_v3(t["center"]) + Vector3(0, 0, 7.0))
	for p in extra:
		patrol.append({"pos": p, "room": ""})


# --- Abfragen für andere Systeme --------------------------------------------------------------------

## Steht p in der Lobby (Erdgeschoss)?
func in_lobby(p: Vector3) -> bool:
	return p.y < 1.5 and _lobby.has_point(Vector2(p.x, p.z))


## Steht p in der benannten Fläche (z. B. "partyraum", "bar")?
func in_area(p: Vector3, id: String) -> bool:
	return p.y < 1.5 and p.y > -1.5 and _named.has(id) and (_named[id] as Rect2).has_point(Vector2(p.x, p.z))


## Ist p draußen (Garten, Innenhof, Terrasse)?
func is_outdoor(p: Vector3) -> bool:
	if p.y > 1.5 or p.y < -1.0:
		return false
	var place := _place_at(Vector2(p.x, p.z))
	return not place.is_empty() and String(place["kind"]) in ["garden", "terrace"]


# --- Bausteine ------------------------------------------------------------------------------------

## Wand entlang X bei z. Öffnungen als Vector4(Mitte x, Breite, Oberkante, Unterkante).
func _wall_x(z: float, x0: float, x1: float, openings: Array, mat: Material = null, height: float = H, thick: float = T) -> void:
	var holder := Node3D.new()
	holder.position = Vector3(0, 0, z)
	_parent.add_child(holder)
	_wall(holder, x0, x1, openings, mat, height, thick)


## Wand entlang Z bei x. Öffnungen als Vector4(Mitte z, Breite, Oberkante, Unterkante).
func _wall_z(x: float, z0: float, z1: float, openings: Array, mat: Material = null, height: float = H, thick: float = T) -> void:
	var holder := Node3D.new()
	holder.position = Vector3(x, 0, 0)
	holder.rotation.y = -PI / 2.0   # lokale +X zeigt entlang +Z
	_parent.add_child(holder)
	_wall(holder, z0, z1, openings, mat, height, thick)


## Wand im lokalen Rahmen von holder (entlang X von a0 bis a1): Kollision als Kästen wie gehabt
## (links, unter und über jeder Öffnung, rechts), die Optik als ein Mesh mit gemeinsamen Ecken (Geo.wall_mesh).
## Laibungen in Rahmenholz: Rutscht die Zarge beim Vertex-Snapping weg, blitzt Holz statt Tapete durch
## (nur der Beton im Keller hat keinen Rahmen).
func _wall(holder: Node3D, a0: float, a1: float, openings: Array, mat: Material, height: float, thick: float) -> void:
	var cursor := a0
	for o in openings:
		var op: Vector4 = o
		var a := op.x - op.y / 2.0
		if a > cursor:
			Geo.collider(holder, Vector3(a - cursor, height, thick), Vector3((cursor + a) / 2.0, height / 2.0, 0))
		if op.w > 0.0:
			Geo.collider(holder, Vector3(op.y, op.w, thick), Vector3(op.x, op.w / 2.0, 0))
		if op.z < height:
			Geo.collider(holder, Vector3(op.y, height - op.z, thick), Vector3(op.x, op.z + (height - op.z) / 2.0, 0))
		cursor = op.x + op.y / 2.0
	if a1 > cursor:
		Geo.collider(holder, Vector3(a1 - cursor, height, thick), Vector3((cursor + a1) / 2.0, height / 2.0, 0))
	var wall := Geo.mesh(holder, Geo.wall_mesh(a0, a1, height, thick, openings), null, Vector3.ZERO)
	var m: Material = mat if mat else _wallpaper
	wall.set_surface_override_material(0, m)
	if wall.mesh.get_surface_count() > 1:
		wall.set_surface_override_material(1, m if m == _concrete else OpeningFrame.trim_material())


## Schild an der Wand (pos = 1 cm vor der Wandfläche, Schrift zeigt nach +Z): Buchstaben als echte Geometrie
## (TextMesh) im PS1-Material, damit Lampen und Taschenlampe sie treffen wie alles andere (Spielkonzept 7.3).
## Wie schief es hängt und wie angelaufen das Messing ist, folgt fest aus dem Text, nicht aus dem Zufall.
func _sign(text: String, pos: Vector3, yaw: float, em: float = SIGN_EM) -> void:
	var holder := Node3D.new()
	holder.rotation = Vector3(0, deg_to_rad(yaw), 0)
	holder.position = pos - holder.basis.z * WALL_GAP
	var h := text.hash()
	holder.rotate_object_local(Vector3.BACK, deg_to_rad(float(posmod(h, 7) - 3) * 0.5))   # bis 1,5° schief
	_parent.add_child(holder)
	var letters := TextMesh.new()
	letters.text = text
	letters.font = _sign_font
	letters.font_size = SIGN_FONT_SIZE
	letters.pixel_size = em / SIGN_FONT_SIZE
	letters.curve_step = SIGN_CURVE_STEP
	letters.depth = SIGN_DEPTH
	var box := letters.get_aabb()
	var center := box.get_center()
	var plate := Vector2(box.size.x, box.size.y) + SIGN_MARGIN * 2.0
	var brass := Mat.psx(SIGN_BRASS[posmod(h >> 3, SIGN_BRASS.size())])
	var rim := Vector3(plate.x + SIGN_RIM * 2.0, plate.y + SIGN_RIM * 2.0, SIGN_PLATE * 0.6)
	Geo.mesh(holder, Geo.box(rim), brass, Vector3(0, 0, rim.z / 2.0))
	Geo.mesh(holder, Geo.box(Vector3(plate.x, plate.y, SIGN_PLATE)), _dark_wood, Vector3(0, 0, SIGN_PLATE / 2.0))
	# Hinterkante der Buchstaben 2 mm in der Platte, sonst flimmert beim Vertex-Snapping ein Spalt
	Geo.mesh(holder, letters, brass, Vector3(-center.x, -center.y, SIGN_PLATE - 0.002 - box.position.z))


## Feste Kerze als Deko-Licht (kein Gegenstand): brennt immer, flackert leicht und in Monsternähe.
## Kerzen und Kürbisse sind die hellsten Lichter im Haus (Spielkonzept 7.3).
func _candle(pos: Vector3) -> void:
	var holder := Node3D.new()
	holder.position = pos
	_parent.add_child(holder)
	Geo.mesh(holder, Geo.cylinder(0.05, 0.015, 8), Mat.psx(Color(0.6, 0.47, 0.22)), Vector3(0, 0.0075, 0))   # Messingteller
	Geo.mesh(holder, Geo.cylinder(0.03, 0.18, 6), Mat.psx(Color(0.92, 0.88, 0.75)), Vector3(0, 0.105, 0))
	var flame := Mat.psx(Color(1, 0.8, 0.3), "", 1.0, Color(1, 0.7, 0.2), 4.0, false)
	Geo.mesh(holder, Geo.sphere(0.016, 0.04, 5, 2), flame, Vector3(0, 0.215, 0))
	var light := FlickerLight.new()
	light.position = Vector3(0, 0.26, 0)
	light.light_color = Color(1.0, 0.68, 0.32)
	light.base_energy = CANDLE_ENERGY
	light.omni_range = 4.5
	light.soft = true
	light.shadow_enabled = false
	light.distance_fade_enabled = true
	light.distance_fade_begin = 20.0
	light.distance_fade_length = 5.0
	light.add_to_group("lamps")
	holder.add_child(light)


## Wandleuchte; yaw dreht die lokale +Z-Achse (von der Wand weg) in den Raum.
func _wall_lamp(pos: Vector3, yaw: float, energy: float, light_range: float, room_id: String, broken: bool = false) -> Lamp:
	var lamp := Lamp.new().setup(Lamp.Style.WALL, room_id, energy, light_range, broken)
	lamp.position = pos
	lamp.rotation.y = yaw
	_parent.add_child(lamp)
	return lamp


## Deckenleuchte bei p (Spielkonzept 7.3): bündig unter der Decke, über dem Luftraum (open_above) als Pendel
## an einer Schnur von der oberen Decke herab.
func _ceiling_lamp(p: Vector2, room_id: String, broken: bool) -> Lamp:
	var y := H - 0.03
	for rc in _map["open_above"]:
		if Rect2(rc[0], rc[1], rc[2] - rc[0], rc[3] - rc[1]).has_point(p):
			var top := UP_Y + H
			y = PENDANT_Y
			Geo.mesh(_parent, Geo.cylinder(0.01, top - y, 4), Mat.psx(Color(0.2, 0.18, 0.16)), Vector3(p.x, (top + y) / 2.0, p.y))
	var lamp := Lamp.new().setup(Lamp.Style.CEILING, room_id, CEILING_LAMP_ENERGY, CEILING_LAMP_RANGE, broken)
	lamp.position = Vector3(p.x, y, p.y)
	_parent.add_child(lamp)
	return lamp


## Schrift, die nur unter UV-Licht leuchtet (Spielkonzept 4.16); yaw (Bogenmaß) dreht die Schrift
## (lokale +Z) von der Wand weg in den Raum.
func _uv_writing(text: String, pos: Vector3, yaw: float) -> void:
	var mark := UvMark.new().setup_text(text)
	mark.position = pos
	mark.rotation.y = yaw
	_parent.add_child(mark)


## Warnungszettel eines früheren Gastes (erscheint erst nach dem ersten Angriff).
func _note(id: String, pos: Vector3) -> WarningNote:
	var note := WarningNote.new().setup(id)
	note.position = pos
	_parent.add_child(note)
	return note


func _switch(room_id: String, label: String, pos: Vector3, yaw: float) -> LightSwitch:
	var sw := LightSwitch.new().setup(room_id, label)
	sw.position = pos
	sw.rotation.y = yaw
	_parent.add_child(sw)
	return sw


func _hide_spot(type: HideSpot.Type, pos: Vector3, yaw: float) -> HideSpot:
	var spot := HideSpot.new().setup(type)
	spot.position = pos
	spot.rotation.y = yaw
	_parent.add_child(spot)
	return spot


func _painting(pos: Vector3, yaw: float, color: Color) -> void:
	var holder := Node3D.new()
	holder.position = pos
	holder.rotation.y = yaw
	_parent.add_child(holder)
	Geo.mesh(holder, Geo.box(Vector3(0.8, 0.6, 0.04)), _dark_wood, Vector3(0, 0, 0.02))
	Geo.mesh(holder, Geo.box(Vector3(0.66, 0.46, 0.045)), Mat.psx(color), Vector3(0, 0, 0.025))


## Ledercouch (`assets/models/couch.glb`, Rohmodell in Blender-Einheiten → `COUCH_SCALE`).
## Lokal liegt die Lehne bei −X, die Sitzfläche zeigt nach +X; yaw dreht um Y.
func _couch(pos: Vector3, yaw: float) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.collision_mask = 0
	body.position = pos
	body.rotation.y = yaw
	_parent.add_child(body)
	var model: Node3D = (load(COUCH_MODEL) as PackedScene).instantiate()
	model.scale = Vector3.ONE * COUCH_SCALE
	model.position.y = 0.066 * COUCH_SCALE   # Unterkante des Modells liegt bei y = −0,066
	body.add_child(model)
	for m: MeshInstance3D in model.find_children("*", "MeshInstance3D", true, false):
		m.material_override = Mat.model(COUCH_MODEL, m)
	# Kollision (auch für das NavMesh): Sitzblock und Lehne, Maße aus dem skalierten Modell.
	Geo.add_box_shape(body, Vector3(0.64, 0.45, 2.39), Vector3(0, 0.225, 0))
	Geo.add_box_shape(body, Vector3(0.18, 0.47, 2.25), Vector3(-0.23, 0.685, 0))
	return body


## Spinnweben, die man abnehmen kann (lokale +Z zeigt in den Raum, yaw im Bogenmaß).
func _resource_web(pos: Vector3, yaw: float) -> void:
	var spot := ResourceSpot.new().setup(Item.Kind.COBWEB, "Spinnenweben", 1, 240.0)
	spot.position = pos
	spot.rotation.y = yaw
	_parent.add_child(spot)


## Gegenstände liegen in der Hauptszene – pos im Rahmen des aktuellen Bauteils.
func _item(kind: Item.Kind, pos: Vector3, extra: String = "") -> Item:
	var item := Item.create(kind, extra)
	item.position = _global(pos)
	world.add_child(item)
	return item


func _global(local: Vector3) -> Vector3:
	return _parent.global_transform * local
