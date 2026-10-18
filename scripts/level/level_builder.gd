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
## Licht (Spielkonzept 7.3): Jede Lampe gehört zu einem Raum; ein Lichtschalter pro Raum bzw. Flurabschnitt.

const MAP_PATH := "res://assets/maps/eg.json"
const H := 3.5
const T := 0.2
## Höhe des Obergeschosses (Oberkante Boden)
const UP_Y := 4.0
## Gedimmtes Licht (Spielkonzept 7.3): keine Deckenlampen, Wandleuchten schwächer als Kerzen
const WALL_LAMP_ENERGY := 0.5
const CANDLE_ENERGY := 0.85
## Zimmer etwas heller als die Flure: zwei Wandleuchten (Tür- und Fensterwand)
const ROOM_LAMP_ENERGY := 0.65
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
## Wände für die Suche nach freien Stellen (Lampen, Kommoden): {horizontal, at, from, to, gaps, used}
var _wall_index: Array[Dictionary] = []
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
	_corridors()
	_lobby_hall()
	_gallery()
	_bar()
	_party_room()
	_kitchen()
	_service_rooms()
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
		_wall_index.append({"horizontal": horizontal, "at": fixed, "from": p0, "to": p1, "minus": minus[i],
			"plus": plus[i], "gaps": mine.map(func(op: Vector4) -> Vector2: return Vector2(op.x - op.y / 2.0, op.x + op.y / 2.0)),
			"used": []})
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
	_sign(label, Vector3(0, 2.45, -0.11), 180.0)
	var dark := kind in ["abandoned", "laundry", "derelict"]
	# Freie Wandstücke links und rechts der Tür (an der Türwand)
	var left_free := -x0 - DOOR_W / 2.0
	var right_free := x1 - DOOR_W / 2.0
	var near := 1.0 if right_free >= 0.5 else -1.0   # Schalter neben der Tür
	_wall_lamp(Vector3(-2.0 if left_free > right_free else 2.0, 2.0, 0.12), 0.0, ROOM_LAMP_ENERGY, 6.5, no, dark)
	_wall_lamp(Vector3(cx - 2.0, 2.0, depth - 0.12), PI, ROOM_LAMP_ENERGY, 6.5, no, dark)
	var sw := _switch(no, "Zimmer " + label, Vector3(near * 0.95, 1.3, 0.12), 0.0)
	if kind == "vacant":
		sw.set_on.call_deferred(false, true)   # unbewohnt: dunkel

	# Möbel: Bett an der linken Wand hinten, Schrank rechts hinten, Tisch vorn auf der freieren Seite
	var bed_pos := Vector3(x0 + 0.85, 0, depth - 1.15)
	var wardrobe_pos := Vector3(x1 - 0.4, 0, depth - 1.2)
	var table_x := x0 + 1.0 if left_free >= right_free else x1 - 1.0
	var table_pos := Vector3(table_x, 0.375, 0.9)
	var free_side := -1.0 if left_free >= right_free else 1.0   # Seite des Tisches
	if kind != "laundry":
		var bed := _hide_spot(HideSpot.Type.BED, bed_pos, 90.0)
		bed.own_bed = kind == "player"
		info["spots"].append(bed)
		Geo.solid(_parent, Vector3(1.0, 0.75, 0.7), table_pos, _wood)
	if kind in ["guest", "player", "empty", "vacant"]:
		info["spots"].append(_hide_spot(HideSpot.Type.WARDROBE, wardrobe_pos, -90.0))
	var table_top := Vector3(table_pos.x, 0.76, table_pos.z)
	if kind != "laundry":
		# Wählscheibentelefon vorn auf dem Tisch (Spielkonzept 4.14)
		var phone := HotelPhone.new().setup(no)
		phone.position = table_top + Vector3(-0.3, 0, -0.17)
		_parent.add_child(phone)
		if not dark and kind != "vacant":
			_candle(table_top + Vector3(0.32, 0, 0.18))   # Kerze hinten rechts auf dem Tisch
	# Ein freier Platz vorn neben dem Tisch, Richtung Tür (Truhe, Kürbis …)
	var beside := Vector3(table_x - free_side * 1.15, 0, 0.45)

	match kind:
		"player":
			_item(Item.Kind.CANDLE, table_top)
			diary = Diary.new()
			diary.position = table_top + Vector3(0.25, 0, 0.05)
			diary.rotation.y = 0.3
			_parent.add_child(diary)
			_item(Item.Kind.MAP, table_top + Vector3(-0.25, 0, 0.17), "eg").rotation.y = -0.2
			var calendar := Calendar.new()
			calendar.position = Vector3(x1 - 0.11, 1.7, depth / 2.0 - 0.3)
			calendar.rotation.y = -PI / 2.0
			_parent.add_child(calendar)
			_item(Item.Kind.PUMPKIN, Vector3(cx + 1.2, 0.02, depth - 0.7))
			var chest := Chest.new()
			chest.position = beside
			_parent.add_child(chest)
			_item(Item.Kind.COINS, beside + Vector3(-0.25, 0.52, 0), "3")
			_item(Item.Kind.LEAVES, beside + Vector3(0.2, 0.52, 0))
			_uv_writing("DU WARST SCHON\nEINMAL HIER", Vector3(x0 + 0.11, 1.45, depth - 1.15), 90.0)
		"abandoned":
			door.set_open.call_deferred(true)
			_item(Item.Kind.PUMPKIN, Vector3(cx + 1.5, 0.02, depth / 2.0 - 0.6))
			_item(Item.Kind.COINS, table_top, "2")
			_item(Item.Kind.LOADED_DICE, table_top + Vector3(0.3, 0, 0.1))
			_note("1987", table_top + Vector3(-0.25, 0, 0.1))
			_item(Item.Kind.MAP, Vector3(cx + 0.4, 0.02, depth - 2.0), "keller").rotation.y = 2.6   # Kellerskizze auf dem Boden
			_resource_web(Vector3(x1 - 0.12, 2.2, depth - 0.3), -135.0)
			_resource_web(Vector3(x0 + 0.12, 2.4, 0.4), 45.0)
			_uv_writing("ICH HABE ES GEBLENDET.\nJETZT KENNT ES MEINE TÜR.\n– E. K.", Vector3(x1 - 0.11, 1.5, depth / 2.0), -90.0)
		"laundry":
			# Waschmaschinen, Regal, Wäschekiste
			for i in 3:
				var wm := Geo.solid(_parent, Vector3(0.65, 0.85, 0.65), Vector3(x0 + 0.45, 0.425, 1.4 + i * 0.8), Mat.psx(Color(0.75, 0.75, 0.72)))
				var porthole := Geo.mesh(wm, Geo.cylinder(0.2, 0.02, 10), Mat.psx(Color(0.15, 0.17, 0.2)), Vector3(0.33, 0.1, 0))
				porthole.rotation.z = PI / 2.0
			Geo.solid(_parent, Vector3(3.0, 2.0, 0.5), Vector3(cx + 0.5, 1.0, depth - 0.4), _wood)
			Geo.solid(_parent, Vector3(0.9, 0.5, 0.9), Vector3(x1 - 0.8, 0.25, depth - 1.0), Mat.psx(Color(0.6, 0.58, 0.5)))
			_resource_web(Vector3(x1 - 0.12, 2.3, 0.6), -45.0)
			_resource_web(Vector3(x0 + 0.12, 2.6, depth - 0.3), 135.0)
			_item(Item.Kind.CANDLE, Vector3(cx + 0.5, 2.02, depth - 0.4))
			_note("1994", Vector3(x1 - 0.8, 0.51, depth - 1.0))
			_item(Item.Kind.BATTERY, Vector3(x1 - 0.55, 0.51, depth - 1.25))
		"locked":
			door.locked = true
			door.key_id = "zimmer_18"
			door.locked_text = "Zimmer %s ist abgeschlossen." % label
			_item(Item.Kind.CARVED_PUMPKIN, Vector3(cx - 1.0, 0.02, 1.6))
			_item(Item.Kind.COINS, table_top, "5")
			_item(Item.Kind.LEAVES, Vector3(cx + 1.0, 0.02, 1.0))
			_item(Item.Kind.UV_FILTER, table_top + Vector3(0.25, 0, 0.12))   # späterer Fund (4.16)
			_uv_writing("NUR EINER\nKOMMT HINAUS", Vector3(x1 - 0.11, 1.5, depth / 2.0 + 0.3), -90.0)
		"empty":
			_item(Item.Kind.CANDLE, table_top)
			_note("2003", Vector3(x0 + 1.95, 0.01, depth - 1.6))   # neben dem Bett, halb darunter
		"derelict":
			# Verfallen: Tür offen, Spinnweben, ein paar Dinge liegen noch herum
			door.set_open.call_deferred(true)
			_resource_web(Vector3(x1 - 0.12, 2.2, depth - 0.3), -135.0)
			_resource_web(Vector3(x0 + 0.12, 2.4, 0.4), 45.0)
			_item(Item.Kind.PUMPKIN, Vector3(cx + 1.5, 0.02, depth / 2.0 - 0.6))
			_item(Item.Kind.COINS, table_top, "1")
			if no == COMPASS_ROOM:
				_item(Item.Kind.COMPASS, table_top + Vector3(0.25, 0, 0.1))
		"vacant":
			# Unbewohnt – ab und zu hat jemand etwas liegen lassen
			var n := int(no) % 100
			if n % 3 == 0:
				_item(Item.Kind.CANDLE, table_top)
			elif n % 5 == 0:
				_item(Item.Kind.COINS, table_top, "1")
			elif n % 7 == 0:
				_item(Item.Kind.BATTERY, table_top)
	rooms[no] = info
	_parent = root


# --- Flure --------------------------------------------------------------------------------------------

## Je Flurabschnitt: Lichtschalter am Anfang, Wandleuchten, Kommoden mit Kerze und Bild, Schränke zum Verstecken.
func _corridors() -> void:
	for c in _map["corridors"]:
		var a := _v2(c["a"])
		var b := _v2(c["b"])
		var id := String(c["id"])
		var length := a.distance_to(b)
		var dir := (b - a) / length
		var s := 3.0
		var i := 0
		var switched := false
		while s < length - 2.0:
			var p := a + dir * s
			if _lobby.grow(1.0).has_point(p):
				s += 2.0
				continue
			var side := 1.0 if i % 2 == 0 else -1.0
			if not switched:
				var at := _corridor_wall_spot(p, dir, side, 0.3)
				if not at.is_empty():
					_switch(id, String(c["name"]), (at["pos"] as Vector3) + Vector3(0, 1.3, 0), at["yaw"])
					switched = true
			if i % 3 == 0:
				var at := _corridor_wall_spot(p + dir * 1.5, dir, side, 0.5)
				if not at.is_empty():
					_wall_lamp((at["pos"] as Vector3) + Vector3(0, 2.1, 0), at["yaw"], WALL_LAMP_ENERGY, 6.0, id)
			if i % 4 == 1:
				var at := _corridor_wall_spot(p, dir, -side, Dresser.SIZE.x + 0.2)
				if not at.is_empty():
					_corridor_dresser(at["pos"], at["yaw"], i)
			elif i % 4 == 3:
				var at := _corridor_wall_spot(p, dir, side, 1.3)
				if not at.is_empty():
					var out := Vector3(sin(at["yaw"]), 0, cos(at["yaw"]))
					_hide_spot(HideSpot.Type.WARDROBE, (at["pos"] as Vector3) + out * 0.32, rad_to_deg(at["yaw"]))
			s += 6.0
			i += 1


## Kommode mit Schubladen (Spielkonzept 3.5), Kerze darauf, Bild darüber.
func _corridor_dresser(pos: Vector3, yaw: float, i: int) -> void:
	var out := Vector3(sin(yaw), 0, cos(yaw))
	var right := Vector3(cos(yaw), 0, -sin(yaw))
	var dresser := Dresser.new()
	dresser.position = pos + out * (Dresser.SIZE.z / 2.0 + 0.01)
	dresser.rotation.y = yaw
	root.add_child(dresser)
	_candle(pos + out * 0.15 + right * 0.25 + Vector3(0, Dresser.SIZE.y, 0))   # die hellsten Lichter im Flur
	var colors: Array[Color] = [Color(0.22, 0.14, 0.12), Color(0.16, 0.2, 0.15), Color(0.12, 0.13, 0.2), Color(0.2, 0.18, 0.1)]
	_painting(pos + out * 0.01 + Vector3(0, 1.75, 0), rad_to_deg(yaw), colors[i % colors.size()])


## Sucht an der Flurwand (Seite side, quer zur Laufrichtung dir) nahe p ein freies Stück der Länge size
## (ohne Öffnung, noch unbesetzt). Ergebnis {pos: Wandpunkt am Boden, yaw: ins Flurinnere} oder leer.
func _corridor_wall_spot(p: Vector2, dir: Vector2, side: float, size: float) -> Dictionary:
	var horizontal := absf(dir.x) > 0.5   # Flur entlang x → Wände entlang x
	var across := Vector2(-dir.y, dir.x) * side
	for shift: float in [0.0, 1.0, -1.0, 2.0, -2.0, 3.0, -3.0]:
		var q := p + dir * shift
		var s := q.x if horizontal else q.y
		for w in _wall_index:
			if w["horizontal"] != horizontal:
				continue
			var offset: float = (float(w["at"]) - (q.y if horizontal else q.x)) * (across.y if horizontal else across.x)
			if offset < 1.4 or offset > 2.6:
				continue
			if s - size / 2.0 < float(w["from"]) + 0.3 or s + size / 2.0 > float(w["to"]) - 0.3:
				continue
			var facing := String(w["minus"]) if (across.y if horizontal else across.x) > 0 else String(w["plus"])
			if facing != "corridor":
				continue
			var blocked := false
			for g: Vector2 in w["gaps"] + w["used"]:
				if s + size / 2.0 + 0.25 > g.x and s - size / 2.0 - 0.25 < g.y:
					blocked = true
					break
			if blocked:
				continue
			(w["used"] as Array).append(Vector2(s - size / 2.0, s + size / 2.0))
			var face: float = float(w["at"]) - (across.y if horizontal else across.x) * (T / 2.0)
			var pos := Vector3(s, 0, face) if horizontal else Vector3(face, 0, s)
			var inward := -across
			return {"pos": pos, "yaw": atan2(inward.x, inward.y)}
	return {}


# --- Lobby und Galerie ---------------------------------------------------------------------------------

func _lobby_hall() -> void:
	lobby_center = Vector3(_lobby.get_center().x, 0, _lobby.get_center().y)
	var west := _lobby.position.x
	var east := _lobby.end.x
	# Teppich vor der Rezeption, Säulen unter der Galeriekante
	Geo.mesh(root, Geo.box(Vector3(6.0, 0.02, 8.0)), Mat.layer(Color(0.32, 0.07, 0.08)), Vector3(0, 0.01, -5.0))
	var void_rect := _void()
	for x: float in [void_rect.position.x - 0.25, void_rect.end.x + 0.25]:
		for z: float in [-10.0, void_rect.position.y - 0.25]:
			Geo.solid(root, Vector3(0.5, H, 0.5), Vector3(x, H / 2.0, z), Mat.psx(Color(0.6, 0.57, 0.5)))
	# Rezeption aus dem Plan
	var desk_top := 1.1
	for rc in _map["reception"]:
		Geo.solid(root, Vector3(rc[2] - rc[0], desk_top, rc[3] - rc[1]), Vector3((rc[0] + rc[2]) / 2.0, desk_top / 2.0, (rc[1] + rc[3]) / 2.0), _dark_wood)
	var front: Array = _map["reception"][0]
	for rc in _map["reception"]:
		if float(rc[2]) - float(rc[0]) > float(front[2]) - float(front[0]):
			front = rc
	var fz := (float(front[1]) + float(front[3])) / 2.0
	_item(Item.Kind.CARVED_PUMPKIN, Vector3(-1.8, desk_top + 0.02, fz))
	_note("2019", Vector3(-0.9, desk_top + 0.01, fz))
	_item(Item.Kind.FLASHLIGHT, Vector3(1.7, desk_top + 0.01, fz)).rotation.y = 2.4   # halb leer (4.16)
	var main_phone := HotelPhone.new().setup("lobby")   # Haupttelefon mit Gästeverzeichnis
	main_phone.position = Vector3(0.4, desk_top, fz)
	main_phone.rotation.y = PI
	root.add_child(main_phone)
	_candle(Vector3(-1.2, desk_top, fz))
	cat_perches.append({"floor": Vector3(2.9, 0, fz - 0.8), "top": Vector3(2.3, desk_top + 0.02, fz - 0.8), "yaw": PI / 2.0})
	# Sitzecke unter der Galerie (West), Schachtisch gegenüber (Ost)
	var lz := -18.0
	_couch(Vector3(west + 0.65, 0, lz), 0.0)
	_couch(Vector3(west + 3.05, 0, lz), PI)
	Geo.solid(root, Vector3(0.7, 0.4, 1.2), Vector3(west + 1.85, 0.2, lz), _wood)   # Couchtisch
	_candle(Vector3(west + 1.85, 0.4, lz + 0.2))
	for zz: float in [lz - 0.5, lz + 0.5]:
		lobby_seats.append(Vector3(west + 1.35, 0, zz))
		lobby_seats.append(Vector3(west + 2.35, 0, zz))
		cat_perches.append({"floor": Vector3(west + 1.35, 0, zz), "top": Vector3(west + 0.72, 0.46, zz)})
	chess_table = ChessTable.new()
	chess_table.position = Vector3(east - 1.9, 0, lz)
	chess_table.rotation.y = PI / 2.0
	root.add_child(chess_table)
	_item(Item.Kind.CHESS_BOARD, Vector3(east - 1.9, 0.77, lz))
	_painting(Vector3(west + 0.01, 2.2, -24.0), 90.0, Color(0.18, 0.1, 0.12))
	_painting(Vector3(east - 0.01, 2.2, -24.0), -90.0, Color(0.1, 0.14, 0.18))
	# Leuchten: die Halle ist groß und hoch – etwas kräftiger, mehr Reichweite
	for z: float in [-20.0, -3.0]:
		_wall_lamp(Vector3(west + 0.12, 2.4, z), PI / 2.0, WALL_LAMP_ENERGY * 1.3, 8.0, "lobby")
		_wall_lamp(Vector3(east - 0.12, 2.4, z), -PI / 2.0, WALL_LAMP_ENERGY * 1.3, 8.0, "lobby")
	for x: float in [-2.6, 2.6]:
		_wall_lamp(Vector3(x, 2.6, _lobby.end.y - 0.12), PI, WALL_LAMP_ENERGY * 1.3, 8.0, "lobby")
	_switch("lobby", "Lobby", Vector3(east - 0.12, 1.3, -8.0 - 2.4), -PI / 2.0)
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


# --- Bar, Partyraum, Küche, Nebenräume, Pool -----------------------------------------------------------

## Hotelbar (Spielkonzept 6.10): Theke an der Nordwand, Flaschen, Hocker, Würfeltisch mit Becher.
func _bar() -> void:
	var r: Rect2 = _named["bar"]
	var cx := r.get_center().x
	var counter := Geo.solid(root, Vector3(7.0, 1.1, 0.6), Vector3(cx, 0.55, r.position.y + 1.0), _dark_wood)
	Geo.mesh(counter, Geo.box(Vector3(7.1, 0.05, 0.7)), _wood, Vector3(0, 0.57, 0))
	Geo.solid(root, Vector3(7.0, 2.0, 0.4), Vector3(cx, 1.0, r.position.y + 0.2), _wood)   # Regal an der Wand
	var pack := (load(BOTTLES_MODEL) as PackedScene).instantiate()
	var bottles := pack.find_children("bottle_*", "MeshInstance3D", true, false)
	for i in 14:   # jede Flasche nur einmal (5 und 28 sind teilerfremd)
		var src: MeshInstance3D = bottles[i * 5 % bottles.size()]
		var bottle := Geo.mesh(root, src.mesh, Mat.model(BOTTLES_MODEL, src), Vector3(cx - 3.2 + i * 0.49, 2.0, r.position.y + 0.25))
		bottle.rotation.y = i * 1.3
	pack.free()
	for i in 4:
		var x := cx - 2.4 + i * 1.6
		var stool := Geo.mesh(root, Geo.cylinder(0.18, 0.05, 8), Mat.psx(Color(0.4, 0.1, 0.1)), Vector3(x, 0.7, r.position.y + 1.8))
		Geo.mesh(stool, Geo.cylinder(0.04, 0.7, 5), _dark_wood, Vector3(0, -0.35, 0))
		bar_spots.append(Vector3(x, 0, r.position.y + 2.2))
	_candle(Vector3(cx + 2.8, 1.145, r.position.y + 1.1))   # auf der Theke
	_painting(Vector3(r.position.x + 0.01, 1.9, r.get_center().y), 90.0, Color(0.25, 0.1, 0.1))
	_wall_lamp(Vector3(r.position.x + 0.12, 2.1, r.position.y + 4.0), PI / 2.0, WALL_LAMP_ENERGY, 6.0, "bar")
	_wall_lamp(Vector3(r.end.x - 0.12, 2.1, r.position.y + 4.0), -PI / 2.0, WALL_LAMP_ENERGY, 6.0, "bar")
	_wall_lamp(Vector3(cx, 2.1, r.end.y - 0.12), PI, WALL_LAMP_ENERGY, 6.0, "bar")
	_switch("bar", "Bar", Vector3(r.end.x - 0.12, 1.3, r.end.y - 1.0), -PI / 2.0)
	game_table = GameTable.new()
	game_table.position = Vector3(cx, 0, r.get_center().y + 2.0)
	root.add_child(game_table)
	_item(Item.Kind.DICE_CUP, Vector3(cx, 0.77, r.get_center().y + 2.0))


## Partyraum: Plattenspieler, Tanzfläche (Feier-Punkte).
func _party_room() -> void:
	var r: Rect2 = _named["partyraum"]
	var c := r.get_center()
	Geo.solid(root, Vector3(0.8, 0.8, 0.6), Vector3(r.end.x - 1.2, 0.4, r.position.y + 0.8), _wood)   # Tisch für den Plattenspieler
	record_player_pos = Vector3(r.end.x - 1.2, 0.8, r.position.y + 0.8)
	party_corner = Vector3(r.position.x + 0.9, 0, r.position.y + 0.9)
	Geo.mesh(root, Geo.box(Vector3(6.0, 0.02, 6.0)), Mat.layer(Color(0.12, 0.1, 0.16)), Vector3(c.x, 0.01, c.y))
	for i in 6:
		var a := TAU * i / 6.0
		party_spots.append(Vector3(c.x + cos(a) * 1.6, 0, c.y + sin(a) * 1.6))
	for z: float in [r.position.y + 4.0, r.end.y - 4.0]:
		_wall_lamp(Vector3(r.end.x - 0.12, 2.1, z), -PI / 2.0, WALL_LAMP_ENERGY, 6.0, "partyraum")
	_wall_lamp(Vector3(c.x, 2.1, r.position.y + 0.12), 0.0, WALL_LAMP_ENERGY, 6.0, "partyraum")
	_switch("partyraum", "Partyraum", Vector3(r.position.x + 0.12, 1.3, r.end.y - 1.0), PI / 2.0)
	for i in 3:
		_candle(Vector3(r.position.x + 0.5, 0.0, r.position.y + 3.0 + i * 4.0))


func _kitchen() -> void:
	var r: Rect2 = _named["kueche"]
	var cx := r.get_center().x
	var back := r.position.y + 0.32   # an der Nordwand
	Geo.solid(root, Vector3(7.0, 0.9, 0.6), Vector3(cx - 0.5, 0.45, back), Mat.psx(Color(0.55, 0.5, 0.42)))   # Arbeitsplatte
	Geo.solid(root, Vector3(0.8, 0.95, 0.62), Vector3(cx + 3.6, 0.475, back), Mat.psx(Color(0.2, 0.2, 0.22)))   # Herd
	Geo.solid(root, Vector3(1.6, 0.78, 0.9), Vector3(cx, 0.39, r.get_center().y - 2.0), _wood)                    # Tisch
	_item(Item.Kind.KNIFE, Vector3(cx - 3.2, 0.91, back))
	var candles := ResourceSpot.new().setup(Item.Kind.CANDLE, "Kerze aus dem Vorrat", 3, 150.0)
	candles.position = Vector3(cx - 1.5, 0.9, back)
	root.add_child(candles)
	kitchen_spot = Vector3(cx, 0, r.get_center().y)
	_wall_lamp(Vector3(cx - 2.0, 2.1, r.position.y + 0.12), 0.0, WALL_LAMP_ENERGY, 6.0, "kueche")
	_wall_lamp(Vector3(cx + 2.0, 2.1, r.end.y - 0.12), PI, WALL_LAMP_ENERGY, 6.0, "kueche")
	_switch("kueche", "Küche", Vector3(r.end.x - 0.12, 1.3, r.get_center().y + 2.0), -PI / 2.0)
	# Speisesaal: lange Tafeln
	var d: Rect2 = _named["speisesaal"]
	for row in 3:
		var z := d.position.y + 4.5 + row * 4.5
		for half: float in [-1.0, 1.0]:
			Geo.solid(root, Vector3(9.0, 0.78, 1.1), Vector3(d.get_center().x + half * 6.0, 0.39, z), _wood)
		_candle(Vector3(d.get_center().x - 6.0 + row * 6.0, 0.78, z))
	for x: float in [d.position.x + 6.0, d.end.x - 6.0]:
		_wall_lamp(Vector3(x, 2.1, d.position.y + 0.12), 0.0, WALL_LAMP_ENERGY, 6.0, "speisesaal")
		_wall_lamp(Vector3(x, 2.1, d.end.y - 0.12), PI, WALL_LAMP_ENERGY, 6.0, "speisesaal")
	_switch("speisesaal", "Speisesaal", Vector3(d.end.x - 4.5, 1.3, d.end.y - 0.12), PI)


## Lager, Kühlräume, Toiletten, Duschen, Umkleiden: je eine Leuchte und ein Schalter, ein paar Einbauten.
func _service_rooms() -> void:
	for id: String in ["lager", "kuehlraum", "tiefkuehlraum"]:
		var r: Rect2 = _named[id]
		Geo.solid(root, Vector3(0.5, 2.0, r.size.y - 1.0), Vector3(r.position.x + 0.3, 1.0, r.get_center().y), _wood)   # Regal
		_wall_lamp(Vector3(r.get_center().x, 2.1, r.position.y + 0.12), 0.0, WALL_LAMP_ENERGY * 0.8, 5.0, id, id != "lager")
		_switch(id, _region_name(id), Vector3(r.end.x - 0.12, 1.3, r.get_center().y + 1.6), -PI / 2.0)
	var spare := ResourceSpot.new().setup(Item.Kind.BULB, "Ersatzbirne aus dem Lager", 2, 300.0)
	spare.position = Vector3(_named["lager"].position.x + 0.3, 1.4, _named["lager"].get_center().y)
	root.add_child(spare)
	for id: String in ["toilette_west", "toilette_ost"]:
		var r: Rect2 = _named[id]
		Geo.solid(root, Vector3(1.6, 0.85, 0.5), Vector3(r.get_center().x, 0.425, r.end.y - 0.35), Mat.psx(Color(0.85, 0.85, 0.82)))   # Waschtisch
		_wall_lamp(Vector3(r.get_center().x, 2.1, r.end.y - 0.12), PI, WALL_LAMP_ENERGY, 5.0, id)
		_switch(id, "Toilette", Vector3(r.get_center().x + 1.6, 1.3, r.position.y + 0.12), 0.0)
	for id: String in ["vorraum", "dusche_west", "dusche_ost", "umkleide_west", "umkleide_ost"]:
		var r: Rect2 = _named[id]
		_wall_lamp(Vector3(r.end.x - 0.12, 2.1, r.get_center().y), -PI / 2.0, WALL_LAMP_ENERGY * 0.8, 5.0, "umkleiden")
	_switch("umkleiden", "Umkleiden", Vector3(_named["vorraum"].end.x - 0.12, 1.3, _named["vorraum"].get_center().y), -PI / 2.0)


func _region_name(id: String) -> String:
	for r in _map["regions"]:
		if r["id"] == id:
			return String(r.get("name", id))
	return id


## Hallenbad: Becken 1,4 m tief mit Wasseroberfläche, Leuchten an der Nordwand.
func _pool() -> void:
	var w: Rect2 = _named["becken"]
	var depth := 1.4
	Geo.solid(root, Vector3(w.size.x, 0.2, w.size.y), Vector3(w.get_center().x, -depth - 0.1, w.get_center().y), _wall_tiles)
	# Beckenränder innerhalb der Wasserfläche (der Umgang endet an ihrer Kante)
	for s: float in [-1.0, 1.0]:
		Geo.solid(root, Vector3(w.size.x, depth, 0.2), Vector3(w.get_center().x, -depth / 2.0, w.get_center().y + s * (w.size.y / 2.0 - 0.1)), _wall_tiles)
		Geo.solid(root, Vector3(0.2, depth, w.size.y - 0.4), Vector3(w.get_center().x + s * (w.size.x / 2.0 - 0.1), -depth / 2.0, w.get_center().y), _wall_tiles)
	var water := Mat.psx(Color(0.15, 0.35, 0.45), "", 1.0, Color(0.05, 0.2, 0.25), 0.4, false)
	Geo.mesh(root, Geo.box(Vector3(w.size.x, 0.02, w.size.y)), water, Vector3(w.get_center().x, -0.3, w.get_center().y))
	var r: Rect2 = _named["pool"]
	for x: float in [r.position.x + 5.0, r.get_center().x, r.end.x - 5.0]:
		_wall_lamp(Vector3(x, 2.4, r.position.y + 0.12), 0.0, WALL_LAMP_ENERGY, 7.0, "pool")
	_switch("pool", "Pool", Vector3(r.end.x - 3.0, 1.3, r.end.y - 0.12), PI)


# --- Gärten -----------------------------------------------------------------------------------------

func _gardens() -> void:
	for r in _map["regions"]:
		if r["kind"] != "garden":
			continue
		var b := _bounds(r["rects"])
		if absf(b.get_center().x) < 15.0:
			_central_garden(b)
	for t in _map["trees"]:
		var p := _v3(t["center"])
		_tree(p, float(t["radius"]))
		var pile := ResourceSpot.new().setup(Item.Kind.LEAVES, "Herbstlaub", 4, 60.0)
		pile.position = p + Vector3(1.8, 0, 1.2)
		root.add_child(pile)
		_lantern(p + Vector3(-3.5, 0, 3.5), false, 0.8)
	for rc in _map["planters"]:
		var size := Vector2(float(rc[2]) - float(rc[0]), float(rc[3]) - float(rc[1]))
		var c := Vector3((float(rc[0]) + float(rc[2])) / 2.0, 0, (float(rc[1]) + float(rc[3])) / 2.0)
		Geo.solid(root, Vector3(size.x, 0.6, size.y), c + Vector3(0, 0.3, 0), _stone)
		Geo.mesh(root, Geo.sphere(size.x * 0.4, 1.2, 7, 4), _hedge, c + Vector3(0, 1.1, 0))
	for rs in _map["terrace_edges"]:
		for rc in rs:
			Geo.mesh(root, Geo.box(Vector3(float(rc[2]) - float(rc[0]), 0.25, float(rc[3]) - float(rc[1]))), _hedge,
				Vector3((float(rc[0]) + float(rc[2])) / 2.0, 0.125, (float(rc[1]) + float(rc[3])) / 2.0))


## Der große Garten zwischen den Flügeln: Kürbisbeete nahe der Lobby, Laternen, Bank.
func _central_garden(b: Rect2) -> void:
	var cx := -2.0
	var dirt := Mat.psx(Color(0.22, 0.14, 0.08))
	for z: float in [_lobby.position.y - 7.0, _lobby.position.y - 9.5]:
		Geo.mesh(root, Geo.box(Vector3(4.6, 0.06, 1.3)), dirt, Vector3(cx, 0.03, z))
		for i in 3:
			var plant := PumpkinPlant.new().setup(3 if (i + int(z)) % 2 == 0 else i)
			plant.position = Vector3(cx - 1.5 + i * 1.5, 0.05, z)
			root.add_child(plant)
		garden_spots.append(Vector3(cx, 0, z + 1.0))
	Geo.solid(root, Vector3(1.6, 0.45, 0.5), Vector3(cx + 4.5, 0.225, _lobby.position.y - 8.0), _dark_wood)   # Bank
	var z := _lobby.position.y - 4.0
	var i := 0
	while z > b.position.y + 4.0:
		_lantern(Vector3(cx + (2.5 if i % 2 == 0 else -2.5), 0, z), i % 4 == 3, 1.0)
		z -= 14.0
		i += 1


## Baum mit Krone in der Größe des Plans (radius = Kronenradius).
func _tree(pos: Vector3, radius: float) -> void:
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
		_wall_lamp(Vector3(x0 + 0.12, 2.0, z_door - 0.4), PI / 2.0, WALL_LAMP_ENERGY, 6.0, "treppenhaus")
		_wall_lamp(Vector3(mid, UP_Y / 2.0 + 1.9, zn + 0.12), 0.0, WALL_LAMP_ENERGY, 6.0, "treppenhaus")
		_wall_lamp(Vector3(mid, bottom / 2.0 + 1.8, zn + 0.12), 0.0, WALL_LAMP_ENERGY, 6.0, "treppenhaus")
		_wall_lamp(Vector3(x1 - 0.12, UP_Y + 1.9, z_door - 0.4), -PI / 2.0, WALL_LAMP_ENERGY, 6.0, "treppenhaus")
		_switch("treppenhaus", "Treppenhaus", Vector3(x1 - 0.12, 1.3, zs - 0.5), -PI / 2.0)


## Ein gerader Treppenlauf entlang z von (z_from, y_from) nach (z_to, y_to).
func _flight(x: float, z_from: float, z_to: float, y_from: float, y_to: float, width: float = 1.4) -> void:
	if y_to < y_from:
		_flight(x, z_to, z_from, y_to, y_from, width)   # abwärts = derselbe Lauf von unten gesehen
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
		Geo.mesh(root, Geo.box(Vector3(width, y_top - y_from + 0.05, run / steps)), _concrete, Vector3(x, (y_top + y_from - 0.05) / 2.0, z))


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
	_uv_writing("31.10.1987\nSIE HABEN IHN\nEINGESCHLOSSEN", Vector3(L - 0.11, 1.5, 0.0), -90.0)
	_resource_web(Vector3(L - 0.5, 1.7, -2.88), 0.0)
	_resource_web(Vector3(1.0, 1.7, 2.88), 180.0)
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


func _sign(text: String, pos: Vector3, yaw: float) -> void:
	var label := Label3D.new()
	label.text = text
	label.pixel_size = 0.008
	label.font_size = 24
	label.modulate = Color(0.85, 0.7, 0.35)
	label.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	label.position = pos
	label.rotation.y = deg_to_rad(yaw)
	_parent.add_child(label)


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


## Schrift, die nur unter UV-Licht leuchtet (Spielkonzept 4.16); yaw dreht die Schrift
## (lokale +Z) von der Wand weg in den Raum.
func _uv_writing(text: String, pos: Vector3, yaw: float) -> void:
	var mark := UvMark.new().setup_text(text)
	mark.position = pos
	mark.rotation.y = deg_to_rad(yaw)
	_parent.add_child(mark)


## Warnungszettel eines früheren Gastes (erscheint erst nach dem ersten Angriff).
func _note(id: String, pos: Vector3) -> void:
	var note := WarningNote.new().setup(id)
	note.position = pos
	_parent.add_child(note)


func _switch(room_id: String, label: String, pos: Vector3, yaw: float) -> LightSwitch:
	var sw := LightSwitch.new().setup(room_id, label)
	sw.position = pos
	sw.rotation.y = yaw
	_parent.add_child(sw)
	return sw


func _hide_spot(type: HideSpot.Type, pos: Vector3, yaw: float) -> HideSpot:
	var spot := HideSpot.new().setup(type)
	spot.position = pos
	spot.rotation.y = deg_to_rad(yaw)
	_parent.add_child(spot)
	return spot


func _painting(pos: Vector3, yaw: float, color: Color) -> void:
	var holder := Node3D.new()
	holder.position = pos
	holder.rotation.y = deg_to_rad(yaw)
	_parent.add_child(holder)
	Geo.mesh(holder, Geo.box(Vector3(0.8, 0.6, 0.04)), _dark_wood, Vector3(0, 0, 0.02))
	Geo.mesh(holder, Geo.box(Vector3(0.66, 0.46, 0.045)), Mat.psx(color), Vector3(0, 0, 0.025))


## Ledercouch (`assets/models/couch.glb`, Rohmodell in Blender-Einheiten → `COUCH_SCALE`).
## Lokal liegt die Lehne bei −X, die Sitzfläche zeigt nach +X; yaw dreht um Y.
func _couch(pos: Vector3, yaw: float) -> void:
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


## Spinnweben in einer Ecke, die man abnehmen kann (lokale +Z zeigt in den Raum).
func _resource_web(pos: Vector3, yaw: float) -> void:
	var spot := ResourceSpot.new().setup(Item.Kind.COBWEB, "Spinnenweben", 1, 240.0)
	spot.position = pos
	spot.rotation.y = deg_to_rad(yaw)
	_parent.add_child(spot)


## Gegenstände liegen in der Hauptszene – pos im Rahmen des aktuellen Bauteils.
func _item(kind: Item.Kind, pos: Vector3, extra: String = "") -> Item:
	var item := Item.create(kind, extra)
	item.position = _global(pos)
	world.add_child(item)
	return item


func _global(local: Vector3) -> Vector3:
	return _parent.global_transform * local
