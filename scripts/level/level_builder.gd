class_name LevelBuilder
extends RefCounted
## Baut das Hotel als Graybox (Maße laut Spielkonzept 7.2, 1 Einheit = 1 m).
##
##                         Nordflügel (Zimmer 35–38)
##            Garten               ┃                       ┃ (41/44)
##   Ausgang ┃ Lobby ┃ Hauptflur ━━╋━━━━━━━━━━━━━━━━━━━━━━━╋━━━━━━━━━━┃ Kellertür → Treppe → Keller
##            Küche/Bar            ┃                       ┃ (42/43)
##                         Südflügel (Zimmer 31–34)
##
##   Lobby x −14…0 · Hauptflur x 0…58,4 (z ±1,6) mit Zimmern 11–28 auf beiden Seiten
##   Kreuzung A bei x 20 (Flügel bis z ±19, je 2 Zimmer pro Seite), Kreuzung B bei x 40
##   (Flügel bis z ±12,9, je 1 Zimmer pro Seite) · Kellertreppe x 58,4…66,6 hinab auf −3,5 m
##   30 Zimmer – Platz für 20–30 Gäste.
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
const LAYER_CEILING := 16
const LAYER_GLASS := 64
## Außenfenster der Zimmer: Unterkante, Oberkante, Breite
const WINDOW_SILL := 0.9
const WINDOW_TOP := 2.3
const WINDOW_W := 1.4
## Milchglas zwischen Flur und Zimmer (versetzt neben der Tür)
const FROSTED_OFFSET := -1.9
const FROSTED_W := 1.0
const FROSTED_SILL := 1.0
const FROSTED_TOP := 2.2
## Zimmertiefe: Flurwand → Rückwand (jeweils Wandmitte)
const ROOM_DEPTH := 5.0
## Hauptflur: x 0 … MAIN_END, z ±1,6
const MAIN_END := 58.4
## Querflure: Mitte x, Flügelende (|z|) und Lichtschalter-Raum je Flügel
const WINGS := [
	{"x": 20.0, "end": 19.0, "south": "fluegel_sued", "north": "fluegel_nord"},
	{"x": 40.0, "end": 12.9, "south": "flur_ost", "north": "flur_ost"},
]
## Kellertreppe hinter der Kellertür am Ostende: Podest, Rampe, Keller 3,5 m tiefer
const STAIR_TOP := 59.6
const STAIR_BOTTOM := 66.6
const CELLAR_Y := -3.5
const CELLAR_LEN := 8.0
const CELLAR_H := 2.6

## Zimmerreihen. Ursprung = Anfang der Flurwand (Wandmitte); yaw dreht die Reihe so, dass
## lokal +X am Flur entlang und +Z ins Zimmer zeigt. Zimmer: [Nummer, Breite, Art, Außenfenster]
## Arten: player, guest, empty, vacant (unbewohnt, Licht aus), laundry, abandoned, locked.
## Kein Außenfenster, wo hinter der Rückwand ein Zimmer eines Querflügels liegt.
const ROWS := [
	# Hauptflur Süd (West → Ost)
	{"origin": Vector3(0.1, 0, 1.6), "yaw": 0.0, "rooms": [["11", 6.1, "guest", true], ["13", 6.1, "player", true], ["15", 6.1, "guest", false]]},
	{"origin": Vector3(21.6, 0, 1.6), "yaw": 0.0, "rooms": [["17", 5.6, "abandoned", false], ["19", 5.6, "vacant", true], ["21", 5.6, "vacant", false]]},
	{"origin": Vector3(41.6, 0, 1.6), "yaw": 0.0, "rooms": [["23", 5.6, "vacant", false], ["25", 5.6, "vacant", true], ["27", 5.6, "vacant", true]]},
	# Hauptflur Nord (Ost → West)
	{"origin": Vector3(18.4, 0, -1.6), "yaw": 180.0, "rooms": [["16", 6.1, "laundry", false], ["14", 6.1, "empty", true], ["12", 6.1, "guest", true]]},
	{"origin": Vector3(38.4, 0, -1.6), "yaw": 180.0, "rooms": [["22", 5.6, "vacant", false], ["20", 5.6, "vacant", true], ["18", 5.6, "locked", false]]},
	{"origin": Vector3(58.4, 0, -1.6), "yaw": 180.0, "rooms": [["28", 5.6, "vacant", true], ["26", 5.6, "vacant", true], ["24", 5.6, "vacant", false]]},
	# Südflügel (Kreuzung A): Westseite nach Süden, Ostseite nach Norden
	{"origin": Vector3(18.4, 0, 6.8), "yaw": -90.0, "rooms": [["31", 6.1, "vacant", true], ["32", 6.1, "vacant", true]]},
	{"origin": Vector3(21.6, 0, 19.0), "yaw": 90.0, "rooms": [["34", 6.1, "vacant", true], ["33", 6.1, "vacant", true]]},
	# Nordflügel (Kreuzung A)
	{"origin": Vector3(18.4, 0, -19.0), "yaw": -90.0, "rooms": [["38", 6.1, "vacant", true], ["37", 6.1, "vacant", true]]},
	{"origin": Vector3(21.6, 0, -6.8), "yaw": 90.0, "rooms": [["35", 6.1, "vacant", true], ["36", 6.1, "vacant", true]]},
	# Kreuzung B: je ein Zimmer pro Seite
	{"origin": Vector3(38.4, 0, 6.8), "yaw": -90.0, "rooms": [["41", 6.1, "vacant", true]]},
	{"origin": Vector3(41.6, 0, 12.9), "yaw": 90.0, "rooms": [["42", 6.1, "vacant", true]]},
	{"origin": Vector3(38.4, 0, -12.9), "yaw": -90.0, "rooms": [["44", 6.1, "vacant", true]]},
	{"origin": Vector3(41.6, 0, -6.8), "yaw": 90.0, "rooms": [["43", 6.1, "vacant", true]]},
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
var kitchen_spot := Vector3(-10.0, 0, 9.0)
var garden_spots: Array[Vector3] = []
var player_spawn := Vector3.ZERO
var player_door_front := Vector3.ZERO
var record_player_pos := Vector3(-1.5, 0.8, 5.8)
var game_table: GameTable
var bar_spots: Array[Vector3] = [Vector3(-1.4, 0, 8.6), Vector3(-1.4, 0, 11.8), Vector3(-5.0, 0, 8.4)]
var diary: Diary

var _parent: Node3D  ## wohin die Bausteine gerade bauen (root oder eine gedrehte Zimmerreihe)
var _wallpaper: Material
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
	_wallpaper = Mat.psx(Color(1, 1, 1), "wallpaper", 1.0)
	_concrete = Mat.psx(Color(0.8, 0.8, 0.8), "concrete", 0.5)
	_wood = Mat.psx(Color(0.45, 0.28, 0.15))
	_dark_wood = Mat.psx(Color(0.22, 0.13, 0.08))
	_ceiling = Mat.psx(Color(1, 1, 1), "ceiling", 1.0)
	_hedge = Mat.psx(Color(1, 1, 1), "hedge", 1.0)
	_carpet = Mat.psx(Color(1, 1, 1), "carpet", 1.0)
	_wood_floor = Mat.psx(Color(1, 1, 1), "wood", 1.0)
	_corridors()
	for row in ROWS:
		_room_row(row)
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

func _corridors() -> void:
	# Hauptflur (Boden ab x −0,1: lückenlos an den Lobbyboden, sonst reißt das NavMesh ab)
	Geo.solid(root, Vector3(MAIN_END + 0.1, 0.2, 3.2), Vector3((MAIN_END - 0.1) / 2.0, -0.1, 0.0), _carpet)
	Geo.solid(root, Vector3(MAIN_END, 0.2, 3.2), Vector3(MAIN_END / 2.0, H + 0.1, 0.0), _ceiling, LAYER_CEILING)
	for x in [3.0, 9.0, 15.0, 20.0]:
		_lamp(Vector3(x, H - 0.08, 0.0), 1.2, 7.0, false, "flur_west" if x < 18.0 else "flur_mitte")
	for x in [25.0, 31.0, 36.0]:
		_lamp(Vector3(x, H - 0.08, 0.0), 1.2, 7.0, false, "flur_mitte")
	for x in [40.0, 45.0, 51.0]:
		_lamp(Vector3(x, H - 0.08, 0.0), 1.2, 7.0, false, "flur_ost")
	_lamp(Vector3(56.0, H - 0.08, 0.0), 1.2, 7.0, true, "flur_ost")   # defekt → dunkles Flurende
	_wall_lamp(Vector3(6.0, 2.1, -1.5), 0.0, 0.6, 4.5, "flur_west")
	_wall_lamp(Vector3(28.0, 2.1, -1.5), 0.0, 0.6, 4.5, "flur_mitte")
	_wall_lamp(Vector3(48.5, 2.1, -1.5), 0.0, 0.6, 4.5, "flur_ost")
	_switch("flur_west", "Flur West", Vector3(0.45, 1.3, 1.5), PI)
	_switch("flur_mitte", "Flur Mitte", Vector3(22.3, 1.3, -1.5), 0.0)
	_switch("flur_ost", "Flur Ost", Vector3(42.3, 1.3, -1.5), 0.0)
	# Möbel und Bilder zwischen den Türen
	_hide_spot(HideSpot.Type.WARDROBE, Vector3(7.1, 0, -1.2), 0.0)
	_hide_spot(HideSpot.Type.WARDROBE, Vector3(33.7, 0, -1.2), 0.0)
	_hide_spot(HideSpot.Type.WARDROBE, Vector3(5.3, 0, 1.2), 180.0)
	_hide_spot(HideSpot.Type.WARDROBE, Vector3(26.3, 0, 1.2), 180.0)
	Geo.solid(root, Vector3(1.4, 0.45, 0.45), Vector3(13.2, 0.225, -1.25), _dark_wood)
	_painting(Vector3(13.2, 1.8, -1.49), 0.0, Color(0.22, 0.14, 0.12))
	_painting(Vector3(53.7, 1.7, -1.49), 0.0, Color(0.16, 0.2, 0.15))
	_painting(Vector3(11.4, 1.7, 1.49), 180.0, Color(0.12, 0.13, 0.2))
	_painting(Vector3(46.3, 1.7, 1.49), 180.0, Color(0.2, 0.18, 0.1))
	_sign("→ 31–38", Vector3(20.0, 2.9, -1.45), 0.0)
	_sign("→ 41–44", Vector3(40.0, 2.9, -1.45), 0.0)

	# Querflure (ohne das Stück, das zum Hauptflur gehört), am Ende ein Außenfenster
	for wing in WINGS:
		var x: float = wing["x"]
		var end: float = wing["end"]
		var length := end - 1.6
		for s in [1.0, -1.0]:
			var section: String = wing["south"] if s > 0 else wing["north"]
			var mid: float = s * (1.6 + length / 2.0)
			Geo.solid(root, Vector3(3.2, 0.2, length), Vector3(x, -0.1, mid), _carpet)
			Geo.solid(root, Vector3(3.2, 0.2, length), Vector3(x, H + 0.1, mid), _ceiling, LAYER_CEILING)
			_wall_x(s * end, x - 1.7, x + 1.7, [Vector4(x, WINDOW_W, WINDOW_TOP, WINDOW_SILL)])
			var win := HotelWindow.new().setup(WINDOW_W, WINDOW_TOP - WINDOW_SILL, false, true, section)
			win.position = Vector3(x, (WINDOW_SILL + WINDOW_TOP) / 2.0, s * end)
			win.rotation.y = PI if s > 0 else 0.0
			root.add_child(win)
			var z: float = s * 5.0
			while absf(z) < end - 1.0:
				_lamp(Vector3(x, H - 0.08, z), 1.0, 6.5, false, section)
				z += s * 5.5
	# Lichtschalter und Verstecke in den langen Flügeln
	_switch("fluegel_sued", "Südflügel", Vector3(21.48, 1.3, 7.6), -PI / 2.0)
	_switch("fluegel_nord", "Nordflügel", Vector3(18.52, 1.3, -7.6), PI / 2.0)
	_hide_spot(HideSpot.Type.WARDROBE, Vector3(18.85, 0, 12.0), 90.0)
	_hide_spot(HideSpot.Type.WARDROBE, Vector3(18.85, 0, -13.8), 90.0)
	_painting(Vector3(21.49, 1.7, -12.0), -90.0, Color(0.2, 0.1, 0.14))

	# Ostende: die niedrige Kellertür
	_wall_z(MAIN_END, -1.7, 1.7, [Vector4(0.0, 0.9, 1.8, 0.0)])
	var door := Door.new().setup(0.9, 1.8, 90.0)
	door.position = Vector3(MAIN_END, 0, -0.45)
	door.rotation.y = deg_to_rad(-90.0)
	root.add_child(door)
	_sign("KELLER", Vector3(MAIN_END - 0.11, 2.0, 0.0), -90.0)


# --- Zimmer ------------------------------------------------------------------------------

## Eine Reihe Zimmer an einer Flurwand. Baut Flurwand (Türen, Milchglas), Rückwand
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
		front.append(Vector4(cx + FROSTED_OFFSET, FROSTED_W, FROSTED_TOP, FROSTED_SILL))
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
	# Tür, Milchglas, Außenfenster, Nummernschild, Lampen, Lichtschalter
	var door := Door.new().setup(DOOR_W, DOOR_H, -100.0)
	door.position = Vector3(cx - DOOR_W / 2.0, 0, 0)
	_parent.add_child(door)
	info["door"] = door
	var frosted := HotelWindow.new().setup(FROSTED_W, FROSTED_TOP - FROSTED_SILL, true, false, no)
	frosted.position = Vector3(cx + FROSTED_OFFSET, (FROSTED_SILL + FROSTED_TOP) / 2.0, 0)
	_parent.add_child(frosted)
	if window:
		var win := HotelWindow.new().setup(WINDOW_W, WINDOW_TOP - WINDOW_SILL, false, true, no)
		win.position = Vector3(cx, (WINDOW_SILL + WINDOW_TOP) / 2.0, ROOM_DEPTH)
		win.rotation.y = PI
		_parent.add_child(win)
	_sign(no, Vector3(cx, 2.35, -0.11), 180.0)
	var dark := kind == "abandoned" or kind == "laundry"
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

	match kind:
		"player":
			_item(Item.Kind.CANDLE, table_top)
			diary = Diary.new()
			diary.position = table_top + Vector3(0.25, 0, 0.05)
			diary.rotation.y = 0.3
			_parent.add_child(diary)
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
		"abandoned":
			door.set_open.call_deferred(true)
			_item(Item.Kind.PUMPKIN, Vector3(cx + 1.5, 0.02, 1.9))
			_item(Item.Kind.COINS, table_top, "2")
			_item(Item.Kind.LOADED_DICE, table_top + Vector3(0.3, 0, 0.1))
			_note("1987", table_top + Vector3(-0.25, 0, 0.1))
			_resource_web(Vector3(x1 - 0.12, 2.2, 4.7), -135.0)
			_resource_web(Vector3(x0 + 0.12, 2.4, 0.4), 45.0)
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
		"locked":
			door.locked = true
			door.key_id = "zimmer_18"
			door.locked_text = "Zimmer 18 ist abgeschlossen."
			_item(Item.Kind.CARVED_PUMPKIN, Vector3(cx - 1.0, 0.02, 1.6))
			_item(Item.Kind.COINS, table_top, "5")
			_item(Item.Kind.LEAVES, Vector3(cx + 1.0, 0.02, 1.0))
		"empty":
			_item(Item.Kind.CANDLE, table_top)
			_note("2003", Vector3(x0 + 1.95, 0.01, 3.4))   # neben dem Bett, halb darunter
		"vacant":
			# Unbewohnt – ab und zu hat jemand etwas liegen lassen
			if int(no) % 3 == 0:
				_item(Item.Kind.CANDLE, table_top)
			elif int(no) % 5 == 0:
				_item(Item.Kind.COINS, table_top, "1")
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
	_note("2011", Vector3(L - 0.9, 0.61, 2.4))
	_resource_web(Vector3(L - 0.5, 1.7, -2.88), 0.0)
	_resource_web(Vector3(1.0, 1.7, 2.88), 180.0)
	_parent = root


# --- Lobby, Küche, Garten ---------------------------------------------------------------

func _lobby() -> void:
	Geo.solid(root, Vector3(14.0, 0.2, 14.2), Vector3(-7.1, -0.1, 0.0), Mat.psx(Color(1, 1, 1), "tiles", 0.5))
	Geo.solid(root, Vector3(14.6, 0.2, 14.6), Vector3(-7.0, LOBBY_H + 0.1, 0.0), _ceiling, LAYER_CEILING)
	_wall_z(0.0, -7.1, 7.1, [Vector4(0.0, 3.0, 3.0, 0.0)], null, LOBBY_H)                 # Durchgang zum Flur
	_wall_z(-14.0, -7.1, 13.1, [Vector4(0.0, 2.5, 2.5, 0.0)], null, LOBBY_H)              # Ausgang
	_wall_x(-7.0, -14.1, 0.1, [Vector4(-11.0, 1.6, 2.7, 0.9), Vector4(-7.0, 1.8, 2.4, 0.0), Vector4(-3.0, 1.6, 2.7, 0.9)], null, LOBBY_H)
	_wall_x(7.0, -14.1, 0.1, [Vector4(-10.0, DOOR_W, DOOR_H, 0.0), Vector4(-3.0, 2.0, 2.6, 0.0)], null, LOBBY_H)   # Küche, Bar
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
	_sign("GARTEN", Vector3(-7.0, 2.6, -6.89), 0.0)
	_sign("KÜCHE", Vector3(-10.0, 2.35, 6.89), 180.0)
	_sign("BAR", Vector3(-3.0, 2.9, 6.89), 180.0)
	var kitchen_door := Door.new().setup(DOOR_W, DOOR_H, -100.0)
	kitchen_door.position = Vector3(-10.0 - DOOR_W / 2.0, 0, 7.0)
	root.add_child(kitchen_door)

	# Einrichtung
	var red := Mat.psx(Color(0.4, 0.08, 0.08))
	Geo.mesh(root, Geo.box(Vector3(9.0, 0.02, 7.0)), Mat.psx(Color(0.32, 0.07, 0.08)), Vector3(-7.0, 0.01, 0.0))
	Geo.solid(root, Vector3(3.0, 1.1, 0.7), Vector3(-11.5, 0.55, 5.4), _dark_wood)      # Rezeption
	Geo.solid(root, Vector3(0.7, 1.1, 1.4), Vector3(-9.65, 0.55, 4.75), _dark_wood)
	_item(Item.Kind.CARVED_PUMPKIN, Vector3(-12.2, 1.12, 5.4))
	_note("2019", Vector3(-10.8, 1.11, 5.35))
	for z in [-2.6, 2.6]:
		var back: float = 0.45 if z > 0 else -0.45
		Geo.solid(root, Vector3(2.2, 0.45, 0.9), Vector3(-10.5, 0.225, z), red)          # Sofas
		Geo.solid(root, Vector3(2.2, 0.5, 0.2), Vector3(-10.5, 0.7, z + back), red)
		lobby_seats.append(Vector3(-10.5, 0, z - back * 1.6))
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
	var bottle_colors: Array[Color] = [Color(0.2, 0.45, 0.2), Color(0.45, 0.2, 0.1), Color(0.6, 0.55, 0.3), Color(0.25, 0.2, 0.4)]
	for i in 9:
		Geo.mesh(counter, Geo.cylinder(0.035, 0.25, 6), Mat.psx(bottle_colors[i % 4]), Vector3(0.1, 0.72, -1.8 + i * 0.45))
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
		{"name": "Flur West", "center": Vector3(9.2, 0, 0), "radius": 9.5},
		{"name": "Flur Mitte", "center": Vector3(29.0, 0, 0), "radius": 9.5},
		{"name": "Flur Ost", "center": Vector3(49.0, 0, 0), "radius": 9.5},
		{"name": "Südflügel", "center": Vector3(20.0, 0, 11.0), "radius": 8.5},
		{"name": "Nordflügel", "center": Vector3(20.0, 0, -11.0), "radius": 8.5},
		{"name": "Flur Ost", "center": Vector3(40.0, 0, 8.0), "radius": 4.5},
		{"name": "Flur Ost", "center": Vector3(40.0, 0, -8.0), "radius": 4.5},
		{"name": "Kellertreppe", "center": Vector3(62.5, 0, 0), "radius": 3.5},
		{"name": "Keller", "center": Vector3(STAIR_BOTTOM + CELLAR_LEN / 2.0, CELLAR_Y, 0), "radius": 4.5},
	]
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


## Wegpunkte: Flure alle paar Meter, Türen, Treppe, Keller und die Gemeinschaftsräume.
## Das Monster nutzt sie, um aus dem Blickfeld zu verschwinden; Gäste schlendern durch die Flure.
func _waypoints() -> void:
	var x := 1.5
	while x < MAIN_END - 0.5:
		wander_points.append(Vector3(x, 0, 0))
		x += 4.0
	for wing in WINGS:
		for s in [1.0, -1.0]:
			var z := 3.5
			while z < float(wing["end"]) - 0.8:
				wander_points.append(Vector3(float(wing["x"]), 0, s * z))
				z += 4.0
	for p in wander_points:
		patrol.append({"pos": p, "room": ""})
	for no in rooms:
		patrol.append({"pos": rooms[no]["door_front"], "room": no})
	for p in [Vector3(MAIN_END + 0.6, 0, 0), Vector3(63.0, -1.9, 0), Vector3(STAIR_BOTTOM + 1.5, CELLAR_Y, 0),
			Vector3(STAIR_BOTTOM + 5.0, CELLAR_Y, 0.5),
			Vector3(-2.0, 0, 0), Vector3(-7.0, 0, -5.5), Vector3(-7.0, 0, -11.0), Vector3(-11.0, 0, -17.0),
			Vector3(-3.5, 0, -14.5), Vector3(-7.0, 0, -8.5), Vector3(-6.0, 0, 3.5), Vector3(-10.0, 0, 6.0),
			Vector3(-11.0, 0, 10.5), Vector3(-3.0, 0, 6.0), Vector3(-2.0, 0, 9.3)]:
		patrol.append({"pos": p, "room": ""})


# --- Bausteine ------------------------------------------------------------------------------

## Wand entlang X bei z. Öffnungen als Vector4(Mitte x, Breite, Oberkante, Unterkante).
func _wall_x(z: float, x0: float, x1: float, openings: Array, mat: Material = null, height: float = H, thick: float = T) -> void:
	var m: Material = mat if mat else _wallpaper
	var cursor := x0
	for o in openings:
		var op: Vector4 = o
		var a := op.x - op.y / 2.0
		if a > cursor:
			Geo.solid(_parent, Vector3(a - cursor, height, thick), Vector3((cursor + a) / 2.0, height / 2.0, z), m)
		if op.w > 0.0:
			Geo.solid(_parent, Vector3(op.y, op.w, thick), Vector3(op.x, op.w / 2.0, z), m)
		if op.z < height:
			Geo.solid(_parent, Vector3(op.y, height - op.z, thick), Vector3(op.x, op.z + (height - op.z) / 2.0, z), m)
		cursor = op.x + op.y / 2.0
	if x1 > cursor:
		Geo.solid(_parent, Vector3(x1 - cursor, height, thick), Vector3((cursor + x1) / 2.0, height / 2.0, z), m)


## Wand entlang Z bei x. Öffnungen als Vector4(Mitte z, Breite, Oberkante, Unterkante).
func _wall_z(x: float, z0: float, z1: float, openings: Array, mat: Material = null, height: float = H, thick: float = T) -> void:
	var m: Material = mat if mat else _wallpaper
	var cursor := z0
	for o in openings:
		var op: Vector4 = o
		var a := op.x - op.y / 2.0
		if a > cursor:
			Geo.solid(_parent, Vector3(thick, height, a - cursor), Vector3(x, height / 2.0, (cursor + a) / 2.0), m)
		if op.w > 0.0:
			Geo.solid(_parent, Vector3(thick, op.w, op.y), Vector3(x, op.w / 2.0, op.x), m)
		if op.z < height:
			Geo.solid(_parent, Vector3(thick, height - op.z, op.y), Vector3(x, op.z + (height - op.z) / 2.0, op.x), m)
		cursor = op.x + op.y / 2.0
	if z1 > cursor:
		Geo.solid(_parent, Vector3(thick, height, z1 - cursor), Vector3(x, height / 2.0, (cursor + z1) / 2.0), m)


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
