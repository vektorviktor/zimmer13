class_name LevelBuilder
extends RefCounted
## Baut das Hotel als Graybox (Maße laut Spielkonzept 7.2, 1 Einheit = 1 m).
##
##   Erdgeschoss (y 0)
##     Garten · Lobby (x −14…0) · Küche/Bar
##     Hauptflur x 0…78,4 (z ±1,6) mit Zimmern 11–28 und 51–56 auf beiden Seiten
##     Kreuzung A (x 20): Flügel bis z ±19, Zimmer 31–38 – am Nordende das Treppenhaus
##     Kreuzung B (x 40): Flügel bis z ±19, Zimmer 41–48
##     Kreuzung C (x 60): kurze Flügel bis z ±12,9, Zimmer 61–64
##     Ostende: niedrige Kellertür → Kellertreppe → Keller (y −3,5)
##   Obergeschoss (y 4) – über das Treppenhaus am Ende des Nordflügels
##     Hauptflur x 0…58,4, Kreuzung A (Zimmer 231–238) und B (241–244), Zimmer 211–228
##   74 Zimmer – Platz für rund 30 Gäste und mehr.
##
## Kollisionsebenen: 1 statisch/NavMesh · 2 Türen · 3 Gegenstände · 4 Spieler · 5 Decke
##                   · 6 Monster · 7 Glas · 8 Gäste · 9 Milchglas · 10 zugezogene Vorhänge
##
## Licht (Spielkonzept 7.3): Jede Lampe gehört zu einem Raum; ein Lichtschalter pro Raum.

const H := 3.5
const LOBBY_H := 5.0
const T := 0.2
const DOOR_W := 1.2
const DOOR_H := 2.1
const COUCH_MODEL := "res://assets/models/couch.glb"
## Rohmodell ist 4,34 Einheiten lang → ~2,4 m lang, Sitzhöhe ~0,45 m, Lehne ~0,92 m.
const COUCH_SCALE := 0.55
## 28 einzelne Flaschen „bottle_NN“ in Metern, Ursprung mittig unten (tools/build_bottles.py)
const BOTTLES_MODEL := "res://assets/models/bottles.glb"
const LAYER_CEILING := 16
const LAYER_GLASS := 64
## Außenfenster der Zimmer und Flurenden: Unterkante (bündig mit der Vertäfelung), Oberkante, Breite –
## hohe, breite Hotelfenster (2026-10-17: vorher 0,9 / 2,3 / 1,4)
const WINDOW_SILL := 0.75
const WINDOW_TOP := 3.05
const WINDOW_W := 1.9
## Zimmertiefe: Flurwand → Rückwand (jeweils Wandmitte)
const ROOM_DEPTH := 5.0
## Höhe des Obergeschosses (Oberkante Boden)
const UP_Y := 4.0
## Hauptflur im Erdgeschoss: x 0 … MAIN_END, z ±1,6
const MAIN_END := 78.4
## Kellertreppe hinter der Kellertür am Ostende: Podest, Rampe, Keller 3,5 m tiefer
const STAIR_TOP := MAIN_END + 1.2
const STAIR_BOTTOM := MAIN_END + 8.2
const CELLAR_Y := -3.5
const CELLAR_LEN := 8.0
const CELLAR_H := 2.6
## Treppenhaus zwischen den Geschossen am Nordende von Kreuzung A: zwei Läufe mit Wendepodest
const STAIRWELL_X := 20.0
const STAIRWELL_Z := -19.0          ## Flügelende = Eingang
const STAIRWELL_LANDING := -25.9    ## Beginn des Podests
const STAIRWELL_END := -28.4        ## Rückwand
## Hier liegt der Kompass: ein verfallenes Zimmer im Obergeschoss
const COMPASS_ROOM := "226"

## Die Flurnetze der Geschosse. sections: [Raum-ID, Name, x von, x bis] für Lichtschalter
## und Lampen des Hauptflurs. wings: Querflure (Mitte x, Ende |z|, Raum-IDs; stair = dort
## liegt das Treppenhaus, statt eines Fensters). east/west: was am Ende des Hauptflurs ist.
const FLOORS := [
	{
		"y": 0.0, "main_end": MAIN_END, "west": "lobby", "east": "cellar",
		"sections": [["flur_west", "Flur West", 0.0, 18.4], ["flur_mitte", "Flur Mitte", 18.4, 38.4],
			["flur_ost", "Flur Ost", 38.4, 58.4], ["flur_ostende", "Flur Ostende", 58.4, 80.0]],
		"switches": [Vector3(0.45, 1.3, 1.5), Vector3(22.3, 1.3, -1.5), Vector3(42.3, 1.3, -1.5), Vector3(62.3, 1.3, -1.5)],
		"wings": [
			{"x": 20.0, "end": 19.0, "south": ["fluegel_sued", "Südflügel"], "north": ["fluegel_nord", "Nordflügel"], "stair": true, "sign": "→ 31–38"},
			{"x": 40.0, "end": 19.0, "south": ["ostfluegel_sued", "Ostflügel Süd"], "north": ["ostfluegel_nord", "Ostflügel Nord"], "sign": "→ 41–48"},
			{"x": 60.0, "end": 12.9, "south": ["flur_ostende", ""], "north": ["flur_ostende", ""], "sign": "→ 61–64"},
		],
	},
	{
		"y": UP_Y, "main_end": 58.4, "west": "wall", "east": "window",
		"sections": [["og_west", "OG Flur West", 0.0, 18.4], ["og_mitte", "OG Flur Mitte", 18.4, 38.4],
			["og_ost", "OG Flur Ost", 38.4, 60.0]],
		"switches": [Vector3(0.45, 1.3, 1.5), Vector3(22.3, 1.3, -1.5), Vector3(42.3, 1.3, -1.5)],
		"wings": [
			{"x": 20.0, "end": 19.0, "south": ["og_fluegel_sued", "OG Südflügel"], "north": ["og_fluegel_nord", "OG Nordflügel"], "stair": true, "sign": "→ 231–238"},
			{"x": 40.0, "end": 12.9, "south": ["og_ost", ""], "north": ["og_ost", ""], "sign": "→ 241–244"},
		],
	},
]

## Zimmerreihen. Ursprung = Anfang der Flurwand (Wandmitte, y = Geschoss); yaw dreht die Reihe
## so, dass lokal +X am Flur entlang und +Z ins Zimmer zeigt. Zimmer: [Nummer, Breite, Art, Außenfenster]
## Arten: player, guest, empty, vacant (unbewohnt, Licht aus), laundry, abandoned, derelict, locked.
## Kein Außenfenster, wo hinter der Rückwand ein Zimmer eines Querflügels liegt.
const ROWS := [
	# --- Erdgeschoss: Hauptflur Süd (West → Ost)
	{"origin": Vector3(0.1, 0, 1.6), "yaw": 0.0, "rooms": [["11", 6.1, "guest", true], ["13", 6.1, "player", true], ["15", 6.1, "guest", false]]},
	{"origin": Vector3(21.6, 0, 1.6), "yaw": 0.0, "rooms": [["17", 5.6, "abandoned", false], ["19", 5.6, "vacant", true], ["21", 5.6, "vacant", false]]},
	{"origin": Vector3(41.6, 0, 1.6), "yaw": 0.0, "rooms": [["23", 5.6, "vacant", false], ["25", 5.6, "vacant", true], ["27", 5.6, "vacant", false]]},
	{"origin": Vector3(61.6, 0, 1.6), "yaw": 0.0, "rooms": [["51", 5.6, "vacant", false], ["53", 5.6, "vacant", true], ["55", 5.6, "vacant", true]]},
	# Hauptflur Nord (Ost → West)
	{"origin": Vector3(18.4, 0, -1.6), "yaw": 180.0, "rooms": [["16", 6.1, "laundry", false], ["14", 6.1, "empty", true], ["12", 6.1, "guest", true]]},
	{"origin": Vector3(38.4, 0, -1.6), "yaw": 180.0, "rooms": [["22", 5.6, "vacant", false], ["20", 5.6, "vacant", true], ["18", 5.6, "locked", false]]},
	{"origin": Vector3(58.4, 0, -1.6), "yaw": 180.0, "rooms": [["28", 5.6, "vacant", false], ["26", 5.6, "vacant", true], ["24", 5.6, "vacant", false]]},
	{"origin": Vector3(78.4, 0, -1.6), "yaw": 180.0, "rooms": [["56", 5.6, "vacant", true], ["54", 5.6, "vacant", true], ["52", 5.6, "vacant", false]]},
	# Kreuzung A: Südflügel (Westseite nach Süden, Ostseite nach Norden), Nordflügel
	{"origin": Vector3(18.4, 0, 6.8), "yaw": -90.0, "rooms": [["31", 6.1, "vacant", true], ["32", 6.1, "vacant", true]]},
	{"origin": Vector3(21.6, 0, 19.0), "yaw": 90.0, "rooms": [["34", 6.1, "vacant", true], ["33", 6.1, "vacant", true]]},
	{"origin": Vector3(18.4, 0, -19.0), "yaw": -90.0, "rooms": [["38", 6.1, "vacant", true], ["37", 6.1, "vacant", true]]},
	{"origin": Vector3(21.6, 0, -6.8), "yaw": 90.0, "rooms": [["35", 6.1, "vacant", true], ["36", 6.1, "vacant", true]]},
	# Kreuzung B: lange Flügel
	{"origin": Vector3(38.4, 0, 6.8), "yaw": -90.0, "rooms": [["41", 6.1, "vacant", true], ["42", 6.1, "vacant", true]]},
	{"origin": Vector3(41.6, 0, 19.0), "yaw": 90.0, "rooms": [["44", 6.1, "vacant", true], ["43", 6.1, "vacant", true]]},
	{"origin": Vector3(38.4, 0, -19.0), "yaw": -90.0, "rooms": [["48", 6.1, "vacant", true], ["47", 6.1, "vacant", true]]},
	{"origin": Vector3(41.6, 0, -6.8), "yaw": 90.0, "rooms": [["45", 6.1, "vacant", true], ["46", 6.1, "vacant", true]]},
	# Kreuzung C: je ein Zimmer pro Seite
	{"origin": Vector3(58.4, 0, 6.8), "yaw": -90.0, "rooms": [["61", 6.1, "vacant", true]]},
	{"origin": Vector3(61.6, 0, 12.9), "yaw": 90.0, "rooms": [["62", 6.1, "vacant", true]]},
	{"origin": Vector3(58.4, 0, -12.9), "yaw": -90.0, "rooms": [["64", 6.1, "vacant", true]]},
	{"origin": Vector3(61.6, 0, -6.8), "yaw": 90.0, "rooms": [["63", 6.1, "vacant", true]]},
	# --- Obergeschoss
	{"origin": Vector3(0.1, UP_Y, 1.6), "yaw": 0.0, "rooms": [["211", 6.1, "vacant", true], ["213", 6.1, "vacant", true], ["215", 6.1, "vacant", false]]},
	{"origin": Vector3(21.6, UP_Y, 1.6), "yaw": 0.0, "rooms": [["217", 5.6, "vacant", false], ["219", 5.6, "vacant", true], ["221", 5.6, "vacant", false]]},
	{"origin": Vector3(41.6, UP_Y, 1.6), "yaw": 0.0, "rooms": [["223", 5.6, "vacant", false], ["225", 5.6, "vacant", true], ["227", 5.6, "vacant", true]]},
	{"origin": Vector3(18.4, UP_Y, -1.6), "yaw": 180.0, "rooms": [["216", 6.1, "vacant", false], ["214", 6.1, "vacant", true], ["212", 6.1, "vacant", true]]},
	{"origin": Vector3(38.4, UP_Y, -1.6), "yaw": 180.0, "rooms": [["222", 5.6, "vacant", false], ["220", 5.6, "vacant", true], ["218", 5.6, "vacant", false]]},
	{"origin": Vector3(58.4, UP_Y, -1.6), "yaw": 180.0, "rooms": [["228", 5.6, "vacant", true], ["226", 5.6, "derelict", true], ["224", 5.6, "vacant", false]]},
	{"origin": Vector3(18.4, UP_Y, 6.8), "yaw": -90.0, "rooms": [["231", 6.1, "vacant", true], ["232", 6.1, "vacant", true]]},
	{"origin": Vector3(21.6, UP_Y, 19.0), "yaw": 90.0, "rooms": [["234", 6.1, "vacant", true], ["233", 6.1, "vacant", true]]},
	{"origin": Vector3(18.4, UP_Y, -19.0), "yaw": -90.0, "rooms": [["238", 6.1, "vacant", true], ["237", 6.1, "derelict", true]]},
	{"origin": Vector3(21.6, UP_Y, -6.8), "yaw": 90.0, "rooms": [["235", 6.1, "vacant", true], ["236", 6.1, "vacant", true]]},
	{"origin": Vector3(38.4, UP_Y, 6.8), "yaw": -90.0, "rooms": [["241", 6.1, "vacant", true]]},
	{"origin": Vector3(41.6, UP_Y, 12.9), "yaw": 90.0, "rooms": [["242", 6.1, "vacant", true]]},
	{"origin": Vector3(38.4, UP_Y, -12.9), "yaw": -90.0, "rooms": [["244", 6.1, "vacant", true]]},
	{"origin": Vector3(41.6, UP_Y, -6.8), "yaw": 90.0, "rooms": [["243", 6.1, "vacant", true]]},
]

var root: Node3D     ## NavigationRegion3D – statische Geometrie, wird fürs NavMesh geparst
var world: Node3D    ## Hauptszene – dynamische Gegenstände
var zones: Array[Dictionary] = []
var spawn_points: Array[Vector3] = []
## Wegpunkte im ganzen Hotel (Verschwinden aus dem Blickfeld): {pos, room}
var patrol: Array[Dictionary] = []
## Punkte in den Fluren, an denen Gäste herumschlendern
var wander_points: Array[Vector3] = []
## Zimmernummer → {no, kind, center, door_front, door_inside, along, into, door, spots}
var rooms := {}
var lobby_center := Vector3(-6.0, 0, 0)
var party_spots: Array[Vector3] = []
var lobby_seats: Array[Vector3] = []
## Liegeplätze der Hotelkatzen auf Möbeln (6.11): {"floor": davor auf dem Boden, "top": obendrauf}
var cat_perches: Array[Dictionary] = []
var kitchen_spot := Vector3(-10.0, 0, 9.0)
var garden_spots: Array[Vector3] = []
var player_spawn := Vector3.ZERO
var player_door_front := Vector3.ZERO
var record_player_pos := Vector3(-1.5, 0.8, 5.8)
var game_table: GameTable
var bar_spots: Array[Vector3] = [Vector3(-1.4, 0, 8.6), Vector3(-1.4, 0, 11.8), Vector3(-5.0, 0, 8.4)]
var diary: Diary

var _parent: Node3D  ## wohin die Bausteine gerade bauen (root, ein Geschoss oder eine gedrehte Zimmerreihe)
var _wallpaper: Material
var _lobby_wallpaper: Material
var _concrete: Material
var _wood: Material
var _dark_wood: Material
var _ceiling: Material
var _hedge: Material
var _carpet: Material
var _wood_floor: Material


func _init(p_root: Node3D, p_world: Node3D) -> void:
	root = p_root
	world = p_world
	_parent = root


func build() -> void:
	_wallpaper = Mat.wallpaper(H, UP_Y)
	_lobby_wallpaper = Mat.wallpaper(LOBBY_H, LOBBY_H + 1.0, "red")
	_concrete = Mat.psx(Color(0.8, 0.8, 0.8), "concrete", 0.5)
	_wood = Mat.psx(Color(0.45, 0.28, 0.15))
	_dark_wood = Mat.psx(Color(0.22, 0.13, 0.08))
	_ceiling = Mat.psx(Color(1, 1, 1), "ceiling", 1.0)
	_hedge = Mat.psx(Color(1, 1, 1), "hedge", 1.0)
	_carpet = Mat.psx(Color(1, 1, 1), "carpet", 1.0)
	_wood_floor = Mat.psx(Color(1, 1, 1), "wood", 1.0)
	for spec in FLOORS:
		_corridors(spec)
	for row in ROWS:
		_room_row(row)
	_stairwell()
	_cellar()
	_lobby()
	_kitchen()
	_bar()
	_garden()
	var home: Dictionary = rooms["13"]
	player_spawn = (home["center"] as Vector3) + Vector3(0, 0.05, 0) + (home["into"] as Vector3) * 0.1
	player_door_front = home["door_front"]
	_zones()
	_waypoints()


# --- Flure ------------------------------------------------------------------------------

## Das Flurnetz eines Geschosses: Hauptflur, Querflure, Lampen, Schalter, Möbel – gebaut
## in einem eigenen Rahmen auf Geschosshöhe.
func _corridors(spec: Dictionary) -> void:
	var level := Node3D.new()
	level.name = "Geschoss_%d" % int(spec["y"])
	level.position.y = float(spec["y"])
	root.add_child(level)
	_parent = level
	var main_end: float = spec["main_end"]
	var sections: Array = spec["sections"]
	# Hauptflur (Boden ab x −0,1: lückenlos an den Lobbyboden, sonst reißt das NavMesh ab)
	Geo.solid(level, Vector3(main_end + 0.1, 0.2, 3.2), Vector3((main_end - 0.1) / 2.0, -0.1, 0.0), _carpet)
	Geo.solid(level, Vector3(main_end, 0.2, 3.2), Vector3(main_end / 2.0, H + 0.1, 0.0), _ceiling, LAYER_CEILING)
	for x in [3.0, 9.0, 15.0, 20.0, 25.0, 31.0, 36.0, 40.0, 45.0, 51.0, 56.0, 60.0, 65.0, 71.0, 76.0]:
		if x > main_end - 1.0:
			break
		var broken: bool = spec["east"] == "cellar" and x > main_end - 4.0   # dunkles Flurende vor dem Keller
		_lamp(Vector3(x, H - 0.08, 0.0), 1.2, 7.0, broken, _section_at(sections, x))
	for i in sections.size():
		var section: Array = sections[i]
		_switch(section[0], section[1], spec["switches"][i], PI if (spec["switches"][i] as Vector3).z > 0.0 else 0.0)
	# Möbel, Bilder und Wandleuchten zwischen den Türen (Abschnitte West bis Ost sind gleich gebaut)
	_wall_lamp(Vector3(6.0, 2.1, -1.5), 0.0, 0.6, 4.5, sections[0][0])
	_wall_lamp(Vector3(28.0, 2.1, -1.5), 0.0, 0.6, 4.5, sections[1][0])
	_wall_lamp(Vector3(48.5, 2.1, -1.5), 0.0, 0.6, 4.5, sections[2][0])
	_hide_spot(HideSpot.Type.WARDROBE, Vector3(7.1, 0, -1.2), 0.0)
	_hide_spot(HideSpot.Type.WARDROBE, Vector3(33.7, 0, -1.2), 0.0)
	_hide_spot(HideSpot.Type.WARDROBE, Vector3(5.3, 0, 1.2), 180.0)
	_hide_spot(HideSpot.Type.WARDROBE, Vector3(26.3, 0, 1.2), 180.0)
	Geo.solid(level, Vector3(1.4, 0.45, 0.45), Vector3(13.2, 0.225, -1.25), _dark_wood)
	_painting(Vector3(13.2, 1.8, -1.49), 0.0, Color(0.22, 0.14, 0.12))
	_painting(Vector3(53.7, 1.7, -1.49), 0.0, Color(0.16, 0.2, 0.15))
	_painting(Vector3(11.4, 1.7, 1.49), 180.0, Color(0.12, 0.13, 0.2))
	_painting(Vector3(46.3, 1.7, 1.49), 180.0, Color(0.2, 0.18, 0.1))
	# Kommoden mit Schubladen (Spielkonzept 3.5) unter Bildern und Wandleuchten
	for d in [[11.4, 1.0], [46.3, 1.0], [28.0, -1.0], [53.7, -1.0]]:
		var dresser := Dresser.new()
		dresser.position = Vector3(d[0], 0, d[1] * (1.6 - 0.1 - Dresser.SIZE.z / 2.0 - 0.01))
		dresser.rotation.y = PI if d[1] > 0 else 0.0
		level.add_child(dresser)
	if main_end > 70.0:
		_wall_lamp(Vector3(68.1, 2.1, -1.5), 0.0, 0.6, 4.5, sections[3][0])
		_hide_spot(HideSpot.Type.WARDROBE, Vector3(66.3, 0, 1.2), 180.0)

	# Querflure (ohne das Stück, das zum Hauptflur gehört), am Ende ein Außenfenster
	for wing in spec["wings"]:
		var wx: float = wing["x"]
		var end: float = wing["end"]
		var length := end - 1.6
		_sign(wing["sign"], Vector3(wx, 2.9, -1.45), 0.0)
		for s in [1.0, -1.0]:
			var room_info: Array = wing["south"] if s > 0 else wing["north"]
			var section: String = room_info[0]
			var mid: float = s * (1.6 + length / 2.0)
			Geo.solid(level, Vector3(3.2, 0.2, length), Vector3(wx, -0.1, mid), _carpet)
			Geo.solid(level, Vector3(3.2, 0.2, length), Vector3(wx, H + 0.1, mid), _ceiling, LAYER_CEILING)
			if wing.get("stair", false) and s < 0:
				# Treppenhaus: unten der aufsteigende Lauf (Westhälfte), oben der ankommende (Osthälfte)
				var lane := wx - 0.75 if float(spec["y"]) == 0.0 else wx + 0.75
				_wall_x(s * end, wx - 1.7, wx + 1.7, [Vector4(lane, 1.4, 3.0, 0.0)])
				_frame_x(s * end, lane, 1.4, 3.0)
				_sign("TREPPE", Vector3(lane, 3.3, s * end + 0.11), 0.0)
			else:
				_wall_x(s * end, wx - 1.7, wx + 1.7, [Vector4(wx, WINDOW_W, WINDOW_TOP, WINDOW_SILL)])
				var win := HotelWindow.new().setup(WINDOW_W, WINDOW_TOP - WINDOW_SILL, false, true, section)
				win.position = Vector3(wx, (WINDOW_SILL + WINDOW_TOP) / 2.0, s * end)
				win.rotation.y = PI if s > 0 else 0.0
				level.add_child(win)
			var z: float = s * 5.0
			while absf(z) < end - 1.0:
				_lamp(Vector3(wx, H - 0.08, z), 1.0, 6.5, false, section)
				z += s * 5.5
			# Lange Flügel: eigener Lichtschalter und ein Schrank zum Verstecken
			if room_info[1] != "":
				_switch(section, room_info[1], Vector3(wx + 1.48 * s, 1.3, s * 7.6), -PI / 2.0 if s > 0 else PI / 2.0)
				_hide_spot(HideSpot.Type.WARDROBE, Vector3(wx - 1.15, 0, 12.0 if s > 0 else -13.8), 90.0)
	_painting(Vector3(21.49, 1.7, -12.0), -90.0, Color(0.2, 0.1, 0.14))

	# Enden des Hauptflurs
	match String(spec["west"]):
		"wall":
			_wall_z(0.0, -1.7, 1.7, [])
	match String(spec["east"]):
		"cellar":
			# die niedrige Kellertür
			_wall_z(main_end, -1.7, 1.7, [Vector4(0.0, 0.9, 1.8, 0.0)])
			var door := Door.new().setup(0.9, 1.8, 90.0)
			door.position = Vector3(main_end, 0, -0.45)
			door.rotation.y = deg_to_rad(-90.0)
			level.add_child(door)
			_sign("KELLER", Vector3(main_end - 0.11, 2.1, 0.0), -90.0)
		"window":
			_wall_z(main_end, -1.7, 1.7, [Vector4(0.0, WINDOW_W, WINDOW_TOP, WINDOW_SILL)])
			var win := HotelWindow.new().setup(WINDOW_W, WINDOW_TOP - WINDOW_SILL, false, true, sections[sections.size() - 1][0])
			win.position = Vector3(main_end, (WINDOW_SILL + WINDOW_TOP) / 2.0, 0.0)
			win.rotation.y = -PI / 2.0
			level.add_child(win)
	_parent = root


func _section_at(sections: Array, x: float) -> String:
	for section in sections:
		if x >= float(section[2]) and x < float(section[3]):
			return section[0]
	return sections[sections.size() - 1][0]


## Treppenhaus zwischen Erd- und Obergeschoss am Nordende von Kreuzung A: Lauf 1 (Westhälfte)
## hinauf zum Wendepodest, Lauf 2 (Osthälfte) zurück nach Süden ins Obergeschoss.
func _stairwell() -> void:
	var x := STAIRWELL_X
	var z0 := STAIRWELL_Z
	var z1 := STAIRWELL_LANDING
	var z2 := STAIRWELL_END
	var top := UP_Y + H
	var mid_y := UP_Y / 2.0
	var length := z0 - z2
	# Außenwände, Mittelwand zwischen den Läufen, Decke, Podest
	for side in [-1.0, 1.0]:
		Geo.solid(root, Vector3(T, top + 0.1, length + 0.1), Vector3(x + side * 1.6, top / 2.0, (z0 + z2) / 2.0), _wallpaper)
	Geo.solid(root, Vector3(3.4, top + 0.1, T), Vector3(x, top / 2.0, z2), _wallpaper)
	Geo.solid(root, Vector3(T, top + 0.1, z0 - z1), Vector3(x, top / 2.0, (z0 + z1) / 2.0), _wallpaper)
	Geo.solid(root, Vector3(3.4, 0.2, length + 0.2), Vector3(x, top + 0.1, (z0 + z2) / 2.0), _ceiling, LAYER_CEILING)
	Geo.solid(root, Vector3(3.0, 0.2, z1 - z2 - 0.1), Vector3(x, mid_y - 0.1, (z1 + z2) / 2.0), _wood_floor)
	# Zwei Läufe: Rampe (Kollision, NavMesh) und Stufen (Optik)
	# Die Läufe beginnen und enden bündig an der Flurkante – sonst entsteht eine Stolperkante
	_flight(x - 0.8, z0, z1, 0.0, mid_y)
	_flight(x + 0.8, z1, z0, mid_y, UP_Y)
	_lamp(Vector3(x, mid_y + 3.2, (z1 + z2) / 2.0), 0.8, 7.0, false, "treppenhaus")
	_wall_lamp(Vector3(x - 1.49, 1.9, (z0 + z1) / 2.0), PI / 2.0, 0.4, 4.0, "treppenhaus")
	_wall_lamp(Vector3(x + 1.49, UP_Y + 1.9, (z0 + z1) / 2.0), -PI / 2.0, 0.4, 4.0, "treppenhaus")
	_switch("treppenhaus", "Treppenhaus", Vector3(x - 1.48, 1.3, z0 - 0.5), PI / 2.0)


## Ein gerader Treppenlauf entlang z von (z_from, y_from) nach (z_to, y_to), 1,4 m breit.
func _flight(x: float, z_from: float, z_to: float, y_from: float, y_to: float) -> void:
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
	Geo.add_box_shape(ramp, Vector3(1.4, 0.2, Vector2(run, rise).length()), Vector3.ZERO)
	var steps := roundi(rise / 0.25)
	var step_rise := rise / steps
	for i in steps:
		var top := y_from + step_rise * (i + 0.5)
		var z := z_from + dir * run * (i + 0.5) / steps
		Geo.mesh(root, Geo.box(Vector3(1.4, top - y_from + 0.05, run / steps)), _concrete, Vector3(x, (top + y_from - 0.05) / 2.0, z))


# --- Zimmer ------------------------------------------------------------------------------

## Eine Reihe Zimmer an einer Flurwand. Baut Flurwand (Türen), Rückwand
## (Außenfenster), Trennwände, Boden und Decke – alles im gedrehten Rahmen der Reihe.
func _room_row(row: Dictionary) -> void:
	var holder := Node3D.new()
	holder.name = "Zimmer_%s" % row["rooms"][0][0]
	holder.position = row["origin"]
	holder.rotation.y = deg_to_rad(float(row["yaw"]))
	root.add_child(holder)
	_parent = holder
	var front: Array = []
	var back: Array = []
	var x := 0.0
	_wall_z(0.0, -0.1, ROOM_DEPTH + 0.1, [])
	for entry in row["rooms"]:
		var width: float = entry[1]
		var cx := x + width / 2.0
		front.append(Vector4(cx, DOOR_W, DOOR_H, 0.0))
		if entry[3]:
			back.append(Vector4(cx, WINDOW_W, WINDOW_TOP, WINDOW_SILL))
		_room(String(entry[0]), x, x + width, String(entry[2]), bool(entry[3]))
		x += width
		_wall_z(x, -0.1, ROOM_DEPTH + 0.1, [])
	_wall_x(0.0, -0.1, x + 0.1, front)
	_wall_x(ROOM_DEPTH, -0.1, x + 0.1, back)
	Geo.solid(holder, Vector3(x, 0.2, ROOM_DEPTH), Vector3(x / 2.0, -0.1, ROOM_DEPTH / 2.0), _wood_floor)
	Geo.solid(holder, Vector3(x + 0.2, 0.2, ROOM_DEPTH + 0.2), Vector3(x / 2.0, H + 0.1, ROOM_DEPTH / 2.0), _ceiling, LAYER_CEILING)
	_parent = root


## Ein Zimmer im Rahmen der Reihe: x0…x1 entlang der Flurwand (z = 0), Rückwand bei ROOM_DEPTH.
func _room(no: String, x0: float, x1: float, kind: String, window: bool) -> void:
	var cx := (x0 + x1) / 2.0
	var basis := _parent.global_transform.basis
	var info := {
		"no": no, "kind": kind,
		"center": _global(Vector3(cx, 0, 2.5)),
		"door_front": _global(Vector3(cx, 0, -0.9)),
		"door_inside": _global(Vector3(cx, 0, 1.0)),
		"along": basis.x.normalized(),   # an der Flurwand entlang
		"into": basis.z.normalized(),    # vom Flur ins Zimmer
		"spots": [],
	}
	# Tür, Außenfenster, Nummernschild, Lampen, Lichtschalter (das Milchglas zum Flur ist seit 2026-10-17 weg)
	var door := Door.new().setup(DOOR_W, DOOR_H, -100.0)
	door.position = Vector3(cx - DOOR_W / 2.0, 0, 0)
	_parent.add_child(door)
	info["door"] = door
	if window:
		var win := HotelWindow.new().setup(WINDOW_W, WINDOW_TOP - WINDOW_SILL, false, true, no)
		win.position = Vector3(cx, (WINDOW_SILL + WINDOW_TOP) / 2.0, ROOM_DEPTH)
		win.rotation.y = PI
		_parent.add_child(win)
	_sign(no, Vector3(cx, 2.45, -0.11), 180.0)
	var dark := kind in ["abandoned", "laundry", "derelict"]
	_lamp(Vector3(cx, H - 0.08, 2.6), 1.0 if kind != "locked" else 0.6, 6.0, dark, no)
	_wall_lamp(Vector3(cx + 2.0, 2.0, 0.12), 0.0, 0.45, 4.0, no, dark)
	var sw := _switch(no, "Zimmer " + no, Vector3(cx + 0.95, 1.3, 0.12), 0.0)
	if kind == "vacant":
		sw.set_on.call_deferred(false, true)   # unbewohnt: dunkel

	# Möbel: Bett an der linken Wand, Schrank an der rechten, Tisch vorn links
	var bed_pos := Vector3(x0 + 0.85, 0, 3.85)
	var wardrobe_pos := Vector3(x1 - 0.4, 0, 3.8)
	var table_pos := Vector3(x0 + 1.0, 0.375, 0.9)
	if kind != "laundry":
		info["spots"].append(_hide_spot(HideSpot.Type.BED, bed_pos, 90.0))
		Geo.solid(_parent, Vector3(1.0, 0.75, 0.7), table_pos, _wood)
	if kind in ["guest", "player", "empty", "vacant"]:
		info["spots"].append(_hide_spot(HideSpot.Type.WARDROBE, wardrobe_pos, -90.0))
	var table_top := Vector3(table_pos.x, 0.76, table_pos.z)
	if kind != "laundry":
		# Wählscheibentelefon vorn links auf dem Tisch (Spielkonzept 4.14)
		var phone := HotelPhone.new().setup(no)
		phone.position = table_top + Vector3(-0.3, 0, -0.17)
		_parent.add_child(phone)

	match kind:
		"player":
			_item(Item.Kind.CANDLE, table_top)
			diary = Diary.new()
			diary.position = table_top + Vector3(0.25, 0, 0.05)
			diary.rotation.y = 0.3
			_parent.add_child(diary)
			_item(Item.Kind.MAP, table_top + Vector3(-0.25, 0, 0.17), "eg").rotation.y = -0.2
			var calendar := Calendar.new()
			calendar.position = Vector3(x1 - 0.11, 1.7, 2.1)
			calendar.rotation.y = -PI / 2.0
			_parent.add_child(calendar)
			_item(Item.Kind.PUMPKIN, Vector3(cx + 1.2, 0.02, 4.3))
			var chest := Chest.new()
			chest.position = Vector3(x1 - 0.45, 0, 1.0)
			chest.rotation.y = deg_to_rad(-90.0)
			_parent.add_child(chest)
			_item(Item.Kind.COINS, Vector3(x1 - 0.45, 0.07, 0.75), "3")
			_item(Item.Kind.LEAVES, Vector3(x1 - 0.45, 0.07, 1.2))
			_uv_writing("DU WARST SCHON\nEINMAL HIER", Vector3(x0 + 0.11, 1.45, 3.85), 90.0)
		"abandoned":
			door.set_open.call_deferred(true)
			_item(Item.Kind.PUMPKIN, Vector3(cx + 1.5, 0.02, 1.9))
			_item(Item.Kind.COINS, table_top, "2")
			_item(Item.Kind.LOADED_DICE, table_top + Vector3(0.3, 0, 0.1))
			_note("1987", table_top + Vector3(-0.25, 0, 0.1))
			_item(Item.Kind.MAP, Vector3(cx + 0.4, 0.02, 3.3), "keller").rotation.y = 2.6   # Kellerskizze auf dem Boden
			_resource_web(Vector3(x1 - 0.12, 2.2, 4.7), -135.0)
			_resource_web(Vector3(x0 + 0.12, 2.4, 0.4), 45.0)
			_uv_writing("ICH HABE ES GEBLENDET.\nJETZT KENNT ES MEINE TÜR.\n– E. K.", Vector3(x1 - 0.11, 1.5, 2.6), -90.0)
		"laundry":
			# Waschmaschinen, Regal, Wäschekiste
			for i in 3:
				var wm := Geo.solid(_parent, Vector3(0.65, 0.85, 0.65), Vector3(x0 + 0.45, 0.425, 1.4 + i * 0.8), Mat.psx(Color(0.75, 0.75, 0.72)))
				var porthole := Geo.mesh(wm, Geo.cylinder(0.2, 0.02, 10), Mat.psx(Color(0.15, 0.17, 0.2)), Vector3(0.33, 0.1, 0))
				porthole.rotation.z = PI / 2.0
			Geo.solid(_parent, Vector3(3.0, 2.0, 0.5), Vector3(cx + 0.5, 1.0, 4.6), _wood)
			Geo.solid(_parent, Vector3(0.9, 0.5, 0.9), Vector3(x1 - 0.8, 0.25, 4.0), Mat.psx(Color(0.6, 0.58, 0.5)))
			_resource_web(Vector3(x1 - 0.12, 2.3, 0.6), -45.0)
			_resource_web(Vector3(x0 + 0.12, 2.6, 4.7), 135.0)
			_item(Item.Kind.CANDLE, Vector3(cx + 0.5, 2.02, 4.6))
			_note("1994", Vector3(x1 - 0.8, 0.51, 4.0))
			_item(Item.Kind.BATTERY, Vector3(x1 - 0.55, 0.51, 3.75))
		"locked":
			door.locked = true
			door.key_id = "zimmer_18"
			door.locked_text = "Zimmer 18 ist abgeschlossen."
			_item(Item.Kind.CARVED_PUMPKIN, Vector3(cx - 1.0, 0.02, 1.6))
			_item(Item.Kind.COINS, table_top, "5")
			_item(Item.Kind.LEAVES, Vector3(cx + 1.0, 0.02, 1.0))
			_item(Item.Kind.UV_FILTER, table_top + Vector3(0.25, 0, 0.12))   # späterer Fund (4.16)
			_uv_writing("NUR EINER\nKOMMT HINAUS", Vector3(x1 - 0.11, 1.5, 2.8), -90.0)
		"empty":
			_item(Item.Kind.CANDLE, table_top)
			_note("2003", Vector3(x0 + 1.95, 0.01, 3.4))   # neben dem Bett, halb darunter
		"derelict":
			# Verfallen: Tür offen, Spinnweben, ein paar Dinge liegen noch herum
			door.set_open.call_deferred(true)
			_resource_web(Vector3(x1 - 0.12, 2.2, 4.7), -135.0)
			_resource_web(Vector3(x0 + 0.12, 2.4, 0.4), 45.0)
			_item(Item.Kind.PUMPKIN, Vector3(cx + 1.5, 0.02, 1.9))
			_item(Item.Kind.COINS, table_top, "1")
			if no == COMPASS_ROOM:
				_item(Item.Kind.COMPASS, table_top + Vector3(0.25, 0, 0.1))
		"vacant":
			# Unbewohnt – ab und zu hat jemand etwas liegen lassen
			if int(no) % 3 == 0:
				_item(Item.Kind.CANDLE, table_top)
			elif int(no) % 5 == 0:
				_item(Item.Kind.COINS, table_top, "1")
			elif int(no) % 7 == 0:
				_item(Item.Kind.BATTERY, table_top)
	rooms[no] = info


# --- Keller ------------------------------------------------------------------------------

## Hinter der Kellertür: Podest, Treppe hinab, Kellerraum 3,5 m unter dem Flur.
func _cellar() -> void:
	var drop := -CELLAR_Y
	var run := STAIR_BOTTOM - STAIR_TOP
	var stair_mid := (MAIN_END + STAIR_BOTTOM) / 2.0
	var stair_len := STAIR_BOTTOM - MAIN_END
	# Podest und Treppenhaus (Wände reichen vom Kellerboden bis über den Flur)
	Geo.solid(root, Vector3(STAIR_TOP - MAIN_END, 0.2, 1.8), Vector3((MAIN_END + STAIR_TOP) / 2.0, -0.1, 0.0), _concrete)
	for s in [1.0, -1.0]:
		Geo.solid(root, Vector3(stair_len, H + drop, T), Vector3(stair_mid, (H + CELLAR_Y) / 2.0, s * 1.0), _concrete)
	Geo.solid(root, Vector3(stair_len + 0.2, 0.2, 2.2), Vector3(stair_mid, H + 0.1, 0.0), _ceiling, LAYER_CEILING)
	# Über dem Kellereingang schließt eine Wand das Treppenhaus ab
	Geo.solid(root, Vector3(T, H - CELLAR_Y - CELLAR_H, 2.2), Vector3(STAIR_BOTTOM + 0.1, (H + CELLAR_Y + CELLAR_H) / 2.0, 0.0), _concrete)
	# Rampe (Kollision, auch fürs NavMesh) und Stufen (nur Optik)
	var ramp := StaticBody3D.new()
	ramp.collision_layer = 1
	ramp.collision_mask = 0
	var angle := atan2(drop, run)
	ramp.position = Vector3((STAIR_TOP + STAIR_BOTTOM) / 2.0, CELLAR_Y / 2.0, 0.0) - Vector3(sin(angle), cos(angle), 0) * 0.1
	ramp.rotation.z = -angle
	root.add_child(ramp)
	Geo.add_box_shape(ramp, Vector3(Vector2(run, drop).length(), 0.2, 1.8), Vector3.ZERO)
	var steps := 14
	var rise := drop / steps
	for i in steps:
		var x := STAIR_TOP + run * (i + 0.5) / steps
		Geo.mesh(root, Geo.box(Vector3(run / steps, rise, 1.8)), _concrete, Vector3(x, -rise * i - rise / 2.0, 0.0))
	_wall_lamp(Vector3(stair_mid, 0.6, 0.89), PI, 0.6, 6.0, "keller")
	_switch("keller", "Keller", Vector3(MAIN_END + 0.6, 1.3, -0.88), 0.0)

	# Kellerraum (eigener Rahmen in Kellerhöhe)
	var cellar := Node3D.new()
	cellar.name = "Keller"
	cellar.position = Vector3(STAIR_BOTTOM, CELLAR_Y, 0.0)
	root.add_child(cellar)
	_parent = cellar
	var L := CELLAR_LEN
	Geo.solid(cellar, Vector3(L + 0.2, 0.2, 6.2), Vector3(L / 2.0, -0.1, 0.0), _concrete)
	Geo.solid(cellar, Vector3(L + 0.4, 0.2, 6.4), Vector3(L / 2.0, CELLAR_H + 0.1, 0.0), _concrete, LAYER_CEILING)
	_wall_z(0.0, -3.1, 3.1, [Vector4(0.0, 1.8, CELLAR_H, 0.0)], _concrete, CELLAR_H)
	_wall_z(L, -3.1, 3.1, [], _concrete, CELLAR_H)
	_wall_x(-3.0, 0.0, L, [], _concrete, CELLAR_H)
	_wall_x(3.0, 0.0, L, [], _concrete, CELLAR_H)
	_lamp(Vector3(L / 2.0, CELLAR_H - 0.08, 0.0), 0.9, 4.5, true, "keller")   # kaputte Birne, blitzt nur auf
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


# --- Lobby, Küche, Garten ---------------------------------------------------------------

func _lobby() -> void:
	Geo.solid(root, Vector3(14.0, 0.2, 14.2), Vector3(-7.1, -0.1, 0.0), Mat.psx(Color(1, 1, 1), "tiles", 0.5))
	Geo.solid(root, Vector3(14.6, 0.2, 14.6), Vector3(-7.0, LOBBY_H + 0.1, 0.0), _ceiling, LAYER_CEILING)
	_wall_z(0.0, -7.1, 7.1, [Vector4(0.0, 3.0, 3.0, 0.0)], _lobby_wallpaper, LOBBY_H)                 # Durchgang zum Flur
	_wall_z(-14.0, -7.1, 13.1, [Vector4(0.0, 2.5, 2.5, 0.0)], _lobby_wallpaper, LOBBY_H)              # Ausgang
	_wall_x(-7.0, -14.1, 0.1, [Vector4(-11.0, 1.6, 2.7, 0.9), Vector4(-7.0, 1.8, 2.4, 0.0), Vector4(-3.0, 1.6, 2.7, 0.9)], _lobby_wallpaper, LOBBY_H)
	_wall_x(7.0, -14.1, 0.1, [Vector4(-10.0, DOOR_W, DOOR_H, 0.0), Vector4(-3.0, 2.0, 2.6, 0.0)], Mat.wallpaper_split(_lobby_wallpaper, _wallpaper, Vector3(0, 0, 1)), LOBBY_H)   # Küche, Bar (dort teal)
	_frame_z(0.0, 0.0, 3.0, 3.0)
	_frame_x(7.0, -3.0, 2.0, 2.6)
	for x in [-11.0, -3.0]:
		var win := HotelWindow.new().setup(1.6, 1.8, false, true, "lobby")
		win.position = Vector3(x, 1.8, -7.0)
		root.add_child(win)

	# Ausgang: riesige, verriegelte Doppeltür
	var exit := Door.new().setup(2.5, 2.5, -90.0, true)
	exit.position = Vector3(-14.0, 0, -1.25)
	exit.rotation.y = deg_to_rad(-90.0)
	exit.locked = true
	exit.key_id = "ausgang"
	exit.monster_can_open = false
	exit.locked_text = "Der Ausgang ist verriegelt. Es muss einen anderen Weg hinaus geben …"
	root.add_child(exit)
	_sign("AUSGANG", Vector3(-13.89, 2.85, 0.0), 90.0)

	# Glastür zum Garten
	var glass := Door.new().setup(1.8, 2.4, 90.0, true, true)
	glass.position = Vector3(-7.9, 0, -7.0)
	root.add_child(glass)
	_sign("GARTEN", Vector3(-7.0, 2.72, -6.89), 0.0)
	_sign("KÜCHE", Vector3(-10.0, 2.45, 6.89), 180.0)
	_sign("BAR", Vector3(-3.0, 2.9, 6.89), 180.0)
	var kitchen_door := Door.new().setup(DOOR_W, DOOR_H, -100.0)
	kitchen_door.position = Vector3(-10.0 - DOOR_W / 2.0, 0, 7.0)
	root.add_child(kitchen_door)

	# Einrichtung
	Geo.mesh(root, Geo.box(Vector3(9.0, 0.02, 7.0)), Mat.layer(Color(0.32, 0.07, 0.08)), Vector3(-7.0, 0.01, 0.0))
	Geo.solid(root, Vector3(3.0, 1.1, 0.7), Vector3(-11.5, 0.55, 5.4), _dark_wood)      # Rezeption
	Geo.solid(root, Vector3(0.7, 1.1, 1.4), Vector3(-9.65, 0.55, 4.75), _dark_wood)
	_item(Item.Kind.CARVED_PUMPKIN, Vector3(-12.2, 1.12, 5.4))
	_note("2019", Vector3(-10.8, 1.11, 5.35))
	_item(Item.Kind.FLASHLIGHT, Vector3(-12.75, 1.11, 5.3)).rotation.y = 2.4   # halb leer (4.16)
	_item(Item.Kind.MAP, Vector3(-9.65, 1.11, 4.6), "og").rotation.y = PI / 2.0   # Kartenblatt Obergeschoss
	var main_phone := HotelPhone.new().setup("lobby")   # Haupttelefon mit Gästeverzeichnis
	main_phone.position = Vector3(-11.4, 1.1, 5.3)
	main_phone.rotation.y = PI
	root.add_child(main_phone)
	for z in [-2.6, 2.6]:
		var back: float = 0.45 if z > 0 else -0.45
		_couch(Vector3(-10.5, 0, z), PI / 2.0 if z > 0 else -PI / 2.0)   # Sofas
		lobby_seats.append(Vector3(-10.5, 0, z - back * 1.6))
		for x in [-11.0, -10.0]:   # Sitzfläche ~0,45 m hoch, Polster etwas vor der Mitte
			cat_perches.append({"floor": Vector3(x, 0, z - back * 1.5), "top": Vector3(x, 0.46, z - signf(z) * 0.07)})
	# Auf der Rezeption, am freien Ende neben dem Telefon (Spielkonzept 6.11)
	cat_perches.append({"floor": Vector3(-10.3, 0, 4.4), "top": Vector3(-10.3, 1.12, 5.4), "yaw": PI / 2.0})
	Geo.solid(root, Vector3(1.2, 0.4, 0.7), Vector3(-10.5, 0.2, 0.0), _wood)             # Couchtisch
	for z in [-5.2, 5.2]:
		Geo.solid(root, Vector3(0.5, LOBBY_H, 0.5), Vector3(-4.5, LOBBY_H / 2.0, z), Mat.psx(Color(0.6, 0.57, 0.5)))
	Geo.solid(root, Vector3(0.8, 0.8, 0.6), Vector3(-1.5, 0.4, 5.8), _wood)              # Tisch für den Plattenspieler
	_painting(Vector3(-13.89, 2.2, -4.5), 90.0, Color(0.18, 0.1, 0.12))
	_painting(Vector3(-13.89, 2.2, 4.0), 90.0, Color(0.1, 0.14, 0.18))
	for p in [Vector3(-7.0, LOBBY_H - 0.08, 0.0), Vector3(-11.0, LOBBY_H - 0.08, 0.0), Vector3(-3.0, LOBBY_H - 0.08, -3.5), Vector3(-3.0, LOBBY_H - 0.08, 3.5)]:
		_lamp(p, 1.5, 9.0, false, "lobby")
	for z in [-3.5, 3.5]:
		_wall_lamp(Vector3(-13.9, 2.4, z), PI / 2.0, 0.6, 5.0, "lobby")
	_switch("lobby", "Lobby", Vector3(-0.12, 1.3, 2.2), -PI / 2.0)
	for i in 6:
		var a := TAU * i / 6.0
		party_spots.append(Vector3(-4.0 + cos(a) * 1.6, 0, sin(a) * 1.6))


func _kitchen() -> void:
	Geo.solid(root, Vector3(8.2, 0.2, 6.1), Vector3(-10.0, -0.1, 10.05), Mat.psx(Color(0.9, 0.95, 1.0), "tiles", 1.0))
	Geo.solid(root, Vector3(8.6, 0.2, 6.6), Vector3(-10.0, H + 0.1, 10.1), _ceiling, LAYER_CEILING)
	_wall_z(-6.0, 7.0, 13.1, [])
	_wall_x(13.0, -14.1, -5.9, [])
	Geo.solid(root, Vector3(6.0, 0.9, 0.6), Vector3(-10.6, 0.45, 12.6), Mat.psx(Color(0.55, 0.5, 0.42)))   # Arbeitsplatte
	Geo.solid(root, Vector3(0.8, 0.95, 0.62), Vector3(-7.1, 0.475, 12.6), Mat.psx(Color(0.2, 0.2, 0.22)))   # Herd
	Geo.solid(root, Vector3(1.6, 0.78, 0.9), Vector3(-10.0, 0.39, 9.6), _wood)                              # Tisch
	_lamp(Vector3(-10.0, H - 0.08, 10.0), 1.0, 6.0, false, "kueche")
	_switch("kueche", "Küche", Vector3(-9.0, 1.3, 7.12), 0.0)
	_item(Item.Kind.KNIFE, Vector3(-12.5, 0.91, 12.6))
	var candles := ResourceSpot.new().setup(Item.Kind.CANDLE, "Kerze aus dem Vorrat", 3, 150.0)
	candles.position = Vector3(-9.0, 0.9, 12.6)
	root.add_child(candles)


## Hotelbar (Spielkonzept 6.10): Theke, Flaschen, Würfeltisch mit Becher.
func _bar() -> void:
	Geo.solid(root, Vector3(6.0, 0.2, 6.0), Vector3(-2.9, -0.1, 10.1), Mat.psx(Color(0.8, 0.7, 0.65), "wood", 1.0))
	Geo.solid(root, Vector3(6.4, 0.2, 6.4), Vector3(-3.0, H + 0.1, 10.1), _ceiling, LAYER_CEILING)
	_wall_z(0.0, 7.1, 13.1, [])
	_wall_x(13.0, -5.9, 0.1, [])
	var counter := Geo.solid(root, Vector3(0.6, 1.1, 4.2), Vector3(-0.45, 0.55, 10.1), _dark_wood)
	Geo.mesh(counter, Geo.box(Vector3(0.7, 0.05, 4.3)), _wood, Vector3(0, 0.57, 0))
	var pack := (load(BOTTLES_MODEL) as PackedScene).instantiate()
	var bottles := pack.find_children("bottle_*", "MeshInstance3D", true, false)
	for i in 12:   # jede Flasche nur einmal (5 und 28 sind teilerfremd)
		var src: MeshInstance3D = bottles[i * 5 % bottles.size()]
		var bottle := Geo.mesh(counter, src.mesh, Mat.model(BOTTLES_MODEL, src), Vector3(0.12, 0.595, -1.85 + i * 0.336))
		bottle.rotation.y = i * 1.3
	pack.free()
	for z in [8.6, 10.1, 11.6]:
		var stool := Geo.mesh(root, Geo.cylinder(0.18, 0.05, 8), Mat.psx(Color(0.4, 0.1, 0.1)), Vector3(-1.2, 0.7, z))
		Geo.mesh(stool, Geo.cylinder(0.04, 0.7, 5), _dark_wood, Vector3(0, -0.35, 0))
	_painting(Vector3(-5.89, 1.9, 10.0), 90.0, Color(0.25, 0.1, 0.1))
	_lamp(Vector3(-3.0, H - 0.08, 8.8), 0.9, 5.5, false, "bar")
	_lamp(Vector3(-3.0, H - 0.08, 11.8), 0.7, 5.0, false, "bar")
	_wall_lamp(Vector3(-5.88, 2.1, 11.6), PI / 2.0, 0.35, 3.5, "bar")
	_switch("bar", "Bar", Vector3(-1.6, 1.3, 7.12), 0.0)
	game_table = GameTable.new()
	game_table.position = Vector3(-3.5, 0, 10.5)
	root.add_child(game_table)
	_item(Item.Kind.DICE_CUP, Vector3(-3.5, 0.77, 10.5))


func _garden() -> void:
	Geo.solid(root, Vector3(14.2, 0.2, 12.0), Vector3(-7.0, -0.1, -13.1), Mat.psx(Color(1, 1, 1), "grass", 1.0))
	_wall_x(-19.0, -14.3, 0.3, [], _hedge, 2.6, 0.5)
	_wall_z(-14.0, -19.0, -7.1, [], _hedge, 2.6, 0.5)
	_wall_z(0.0, -19.0, -7.1, [], _hedge, 2.6, 0.5)
	# Kürbisbeete
	var dirt := Mat.psx(Color(0.22, 0.14, 0.08))
	for z in [-13.0, -15.5]:
		Geo.mesh(root, Geo.box(Vector3(4.6, 0.06, 1.3)), dirt, Vector3(-6.5, 0.03, z))
		for i in 3:
			var plant := PumpkinPlant.new().setup(3 if (i + int(z)) % 2 == 0 else i)
			plant.position = Vector3(-8.0 + i * 1.5, 0.05, z)
			root.add_child(plant)
		garden_spots.append(Vector3(-6.5, 0, z + 1.0))
	# Bäume mit Laubhaufen
	for p in [Vector3(-11.5, 0, -10.0), Vector3(-2.5, 0, -16.5)]:
		_tree(p)
		var pile := ResourceSpot.new().setup(Item.Kind.LEAVES, "Herbstlaub", 4, 60.0)
		pile.position = p + Vector3(1.2, 0, 0.8)
		root.add_child(pile)
	Geo.solid(root, Vector3(1.6, 0.45, 0.5), Vector3(-2.0, 0.225, -9.0), _dark_wood)   # Bank
	_lantern(Vector3(-7.0, 0, -9.6), false, 1.0)
	_lantern(Vector3(-12.5, 0, -17.6), true, 1.0)
	_lantern(Vector3(-1.2, 0, -12.5), false, 0.6)


func _tree(pos: Vector3) -> void:
	var trunk := Geo.solid(root, Vector3(0.4, 3.2, 0.4), pos + Vector3(0, 1.6, 0), Mat.psx(Color(0.22, 0.15, 0.1)))
	var colors: Array[Color] = [Color(0.6, 0.25, 0.05), Color(0.7, 0.4, 0.08), Color(0.45, 0.12, 0.05)]
	var offsets: Array[Vector3] = [Vector3(0, 1.6, 0), Vector3(0.7, 1.2, 0.3), Vector3(-0.6, 1.3, -0.4)]
	for i in 3:
		Geo.mesh(trunk, Geo.sphere(1.3 - i * 0.2, 1.8 - i * 0.2, 7, 4), Mat.psx(colors[i]), offsets[i])


func _lantern(pos: Vector3, broken: bool, energy: float) -> void:
	Geo.solid(root, Vector3(0.12, 2.4, 0.12), pos + Vector3(0, 1.2, 0), Mat.psx(Color(0.1, 0.1, 0.1)))
	var mat := Mat.psx(Color(1, 0.95, 0.8), "", 1.0, Color(1.0, 0.8, 0.5), 2.5, false)
	Geo.mesh(root, Geo.box(Vector3(0.25, 0.3, 0.25)), mat, pos + Vector3(0, 2.55, 0))
	var light := FlickerLight.new()
	light.position = pos + Vector3(0, 2.3, 0)
	light.base_energy = energy
	light.omni_range = 6.0
	light.light_color = Color(1.0, 0.75, 0.45)
	light.shadow_enabled = true
	light.broken = broken
	light.lamp_material = mat
	light.add_to_group("lamps")
	root.add_child(light)



# --- Zonen & Wegpunkte ------------------------------------------------------------------

func _zones() -> void:
	zones = [
		{"name": "Lobby", "center": Vector3(-7.0, 0, 0), "radius": 7.0},
		{"name": "Küche", "center": Vector3(-10.0, 0, 10.0), "radius": 4.0},
		{"name": "Bar", "center": Vector3(-3.0, 0, 10.0), "radius": 3.2},
		{"name": "Garten", "center": Vector3(-7.0, 0, -13.0), "radius": 6.0},
		{"name": "Kellertreppe", "center": Vector3(MAIN_END + 4.1, CELLAR_Y / 2.0, 0), "radius": 3.5},
		{"name": "Keller", "center": Vector3(STAIR_BOTTOM + CELLAR_LEN / 2.0, CELLAR_Y, 0), "radius": 4.5},
		{"name": "Treppenhaus", "center": Vector3(STAIRWELL_X, UP_Y / 2.0, (STAIRWELL_Z + STAIRWELL_END) / 2.0), "radius": 5.0},
	]
	# Flure je Geschoss: Abschnitte des Hauptflurs und lange Flügel
	for spec in FLOORS:
		var y: float = spec["y"]
		for section in spec["sections"]:
			var x0: float = section[2]
			var x1: float = minf(section[3], spec["main_end"])
			zones.append({"name": section[1], "center": Vector3((x0 + x1) / 2.0, y, 0), "radius": (x1 - x0) / 2.0 + 0.5})
		for wing in spec["wings"]:
			for s in [1.0, -1.0]:
				var room_info: Array = wing["south"] if s > 0 else wing["north"]
				var label: String = room_info[1]
				if label == "":
					label = _section_label(spec, room_info[0])
				var end: float = wing["end"]
				zones.append({"name": label, "center": Vector3(wing["x"], y, s * (1.6 + end) / 2.0), "radius": (end - 1.6) / 2.0 + 0.5})
	for no in rooms:
		var info: Dictionary = rooms[no]
		zones.append({"name": "Zimmer " + String(no), "center": info["center"], "radius": 3.2})
	for zone in zones:
		zone["curiosity"] = 50.0
	spawn_points = [
		Vector3(STAIR_BOTTOM + CELLAR_LEN / 2.0, CELLAR_Y + 0.05, 0.3),   # Keller – das Versteck des Monsters
		(rooms["17"]["center"] as Vector3) + Vector3(0, 0.05, 0),          # verlassenes Zimmer
		(rooms["16"]["center"] as Vector3) + Vector3(0, 0.05, 0),          # Wäscherei
		Vector3(-12.5, 0.05, -15.0),                                       # Garten
	]


func _section_label(spec: Dictionary, id: String) -> String:
	for section in spec["sections"]:
		if section[0] == id:
			return section[1]
	return id


## Wegpunkte: Flure alle paar Meter (beide Geschosse), Türen, Treppen, Keller und die
## Gemeinschaftsräume. Das Monster nutzt sie, um aus dem Blickfeld zu verschwinden; Gäste
## schlendern durch die Flure.
func _waypoints() -> void:
	for spec in FLOORS:
		var y: float = spec["y"]
		var x := 1.5
		while x < float(spec["main_end"]) - 0.5:
			wander_points.append(Vector3(x, y, 0))
			x += 4.0
		for wing in spec["wings"]:
			for s in [1.0, -1.0]:
				var z := 3.5
				while z < float(wing["end"]) - 0.8:
					wander_points.append(Vector3(float(wing["x"]), y, s * z))
					z += 4.0
	for p in wander_points:
		patrol.append({"pos": p, "room": ""})
	for no in rooms:
		patrol.append({"pos": rooms[no]["door_front"], "room": no})
	for p in [Vector3(MAIN_END + 0.6, 0, 0), Vector3(MAIN_END + 4.6, -1.9, 0), Vector3(STAIR_BOTTOM + 1.5, CELLAR_Y, 0),
			Vector3(STAIR_BOTTOM + 5.0, CELLAR_Y, 0.5),
			Vector3(STAIRWELL_X, UP_Y / 2.0, (STAIRWELL_LANDING + STAIRWELL_END) / 2.0),
			Vector3(-2.0, 0, 0), Vector3(-7.0, 0, -5.5), Vector3(-7.0, 0, -11.0), Vector3(-11.0, 0, -17.0),
			Vector3(-3.5, 0, -14.5), Vector3(-7.0, 0, -8.5), Vector3(-6.0, 0, 3.5), Vector3(-10.0, 0, 6.0),
			Vector3(-11.0, 0, 10.5), Vector3(-3.0, 0, 6.0), Vector3(-2.0, 0, 9.3)]:
		patrol.append({"pos": p, "room": ""})


# --- Bausteine ------------------------------------------------------------------------------

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
## (nur der Kellerdurchgang im Beton hat keinen Rahmen).
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


## Rahmen um einen Durchgang ohne Tür: Wand entlang X bei z bzw. entlang Z bei x (Mitte c, Breite w, Höhe h).
func _frame_x(z: float, c: float, w: float, h: float) -> void:
	var f := OpeningFrame.new().setup(c - w / 2.0, 0.0, w, h, T)
	f.position.z = z
	_parent.add_child(f)


func _frame_z(x: float, c: float, w: float, h: float) -> void:
	var f := OpeningFrame.new().setup(c - w / 2.0, 0.0, w, h, T)
	f.position.x = x
	f.rotation.y = -PI / 2.0   # lokale +X zeigt dann entlang +Z
	_parent.add_child(f)


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


## Deckenlampe mit Glühbirne, gehört zum Raum room_id.
func _lamp(pos: Vector3, energy: float, light_range: float, broken: bool, room_id: String) -> Lamp:
	var lamp := Lamp.new().setup(Lamp.Style.CEILING, room_id, energy, light_range, broken)
	lamp.position = pos
	_parent.add_child(lamp)
	return lamp


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
