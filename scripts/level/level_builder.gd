class_name LevelBuilder
extends RefCounted
## Baut das Hotel als Graybox (Maße laut Spielkonzept 7.2, 1 Einheit = 1 m).
##
##            Garten (x −14…0, z −19…−7) – Glastür in der Lobby-Nordwand
##   Ausgang ┃ Lobby (x −14…0, z −7…7, Decke 5 m) ┃ Flur (x 0…30, z ±1,6) ┃ Keller (x 30…34)
##            Küche (x −14…−6, z 7…13)              Zimmer 12–18 (Nord) / 11–17 (Süd)
##
## Kollisionsebenen: 1 statisch/NavMesh · 2 Türen · 3 Gegenstände · 4 Spieler · 5 Decke
##                   · 6 Monster · 7 Glas · 8 Gäste

const H := 3.5
const LOBBY_H := 5.0
const T := 0.2
const DOOR_W := 1.2
const DOOR_H := 2.1
const LAYER_CEILING := 16
const LAYER_GLASS := 64

## Zimmer am Flur. side +1 = Süd, −1 = Nord. kind bestimmt die Einrichtung.
const ROOM_LAYOUT := [
	{"no": "11", "x0": 4.0, "x1": 10.0, "side": 1, "kind": "guest"},
	{"no": "13", "x0": 10.0, "x1": 16.0, "side": 1, "kind": "player"},
	{"no": "15", "x0": 16.0, "x1": 22.0, "side": 1, "kind": "guest"},
	{"no": "17", "x0": 22.0, "x1": 28.0, "side": 1, "kind": "abandoned"},
	{"no": "12", "x0": 2.0, "x1": 8.0, "side": -1, "kind": "guest"},
	{"no": "14", "x0": 8.0, "x1": 14.0, "side": -1, "kind": "empty"},
	{"no": "16", "x0": 14.0, "x1": 20.0, "side": -1, "kind": "laundry"},
	{"no": "18", "x0": 20.0, "x1": 26.0, "side": -1, "kind": "locked"},
]

var root: Node3D     ## NavigationRegion3D – statische Geometrie, wird fürs NavMesh geparst
var world: Node3D    ## Hauptszene – dynamische Gegenstände
var zones: Array[Dictionary] = []
var spawn_points: Array[Vector3] = []
## Feste Patrouillenroute des Monsters: {pos, room} – room = Zimmernummer oder ""
var patrol: Array[Dictionary] = []
## Zimmernummer → {no, kind, side, center, door_front, door_inside, door, spots}
var rooms := {}
var lobby_center := Vector3(-6.0, 0, 0)
var party_spots: Array[Vector3] = []
var lobby_seats: Array[Vector3] = []
var kitchen_spot := Vector3(-10.0, 0, 9.0)
var garden_spots: Array[Vector3] = []
var player_spawn := Vector3(13.0, 0.05, 4.2)
var player_door_front := Vector3(13.0, 0.0, 0.7)
var record_player_pos := Vector3(-1.5, 0.8, 5.8)
var game_table: GameTable
var bar_spots: Array[Vector3] = [Vector3(-1.4, 0, 8.6), Vector3(-1.4, 0, 11.8), Vector3(-5.0, 0, 8.4)]

var _wallpaper: Material
var _concrete: Material
var _wood: Material
var _dark_wood: Material
var _ceiling: Material
var _hedge: Material


func _init(p_root: Node3D, p_world: Node3D) -> void:
	root = p_root
	world = p_world


func build() -> void:
	_wallpaper = Mat.psx(Color(1, 1, 1), "wallpaper", 1.0)
	_concrete = Mat.psx(Color(0.8, 0.8, 0.8), "concrete", 0.5)
	_wood = Mat.psx(Color(0.45, 0.28, 0.15))
	_dark_wood = Mat.psx(Color(0.22, 0.13, 0.08))
	_ceiling = Mat.psx(Color(1, 1, 1), "ceiling", 1.0)
	_hedge = Mat.psx(Color(1, 1, 1), "hedge", 1.0)
	_corridor()
	for data in ROOM_LAYOUT:
		_room(data)
	_room_walls()
	_cellar()
	_lobby()
	_kitchen()
	_bar()
	_garden()
	_zones()
	_patrol_route()


# --- Flur & Zimmer ------------------------------------------------------------------

func _corridor() -> void:
	Geo.solid(root, Vector3(30.1, 0.2, 3.2), Vector3(14.95, -0.1, 0.0), Mat.psx(Color(1, 1, 1), "carpet", 1.0))
	Geo.solid(root, Vector3(34.6, 0.2, 14.0), Vector3(17.2, H + 0.1, 0.0), _ceiling, LAYER_CEILING)
	var north_doors: Array = []
	var south_doors: Array = []
	for data in ROOM_LAYOUT:
		var cx: float = (float(data["x0"]) + float(data["x1"])) / 2.0
		var opening := Vector4(cx, DOOR_W, DOOR_H, 0.0)
		if int(data["side"]) > 0:
			south_doors.append(opening)
		else:
			north_doors.append(opening)
	_wall_x(-1.6, 0.1, 30.1, north_doors)
	_wall_x(1.6, 0.1, 30.1, south_doors)
	for x in [3.0, 9.0, 15.0, 21.0]:
		_lamp(Vector3(x, H - 0.08, 0.0), 1.2, 7.0, false)
	_lamp(Vector3(27.0, H - 0.08, 0.0), 1.2, 7.0, true)   # defekt → dunkles Flurende
	# Möbel im Flur – zwischen den Türen
	_hide_spot(HideSpot.Type.WARDROBE, Vector3(8.0, 0, -1.2), 0.0)
	_hide_spot(HideSpot.Type.WARDROBE, Vector3(20.0, 0, -1.2), 0.0)
	_hide_spot(HideSpot.Type.WARDROBE, Vector3(2.5, 0, 1.2), 180.0)
	_hide_spot(HideSpot.Type.WARDROBE, Vector3(22.0, 0, 1.2), 180.0)
	Geo.solid(root, Vector3(1.4, 0.45, 0.45), Vector3(14.0, 0.225, -1.25), _dark_wood)
	_painting(Vector3(14.0, 1.8, -1.49), 0.0, Color(0.22, 0.14, 0.12))
	_painting(Vector3(28.0, 1.7, -1.49), 0.0, Color(0.16, 0.2, 0.15))
	_painting(Vector3(10.0, 1.7, 1.49), 180.0, Color(0.12, 0.13, 0.2))
	_painting(Vector3(16.0, 1.7, 1.49), 180.0, Color(0.2, 0.18, 0.1))


func _room(data: Dictionary) -> void:
	var no: String = data["no"]
	var x0: float = data["x0"]
	var x1: float = data["x1"]
	var s: float = float(data["side"])
	var kind: String = data["kind"]
	var cx := (x0 + x1) / 2.0
	var info := {
		"no": no, "kind": kind, "side": s,
		"center": Vector3(cx, 0, s * 4.1),
		"door_front": Vector3(cx, 0, s * 0.7),
		"door_inside": Vector3(cx, 0, s * 2.6),
		"spots": [],
	}
	# Tür, Nummernschild, Lampe
	var door := Door.new().setup(DOOR_W, DOOR_H, -100.0 * s)
	door.position = Vector3(cx - DOOR_W / 2.0, 0, s * 1.6)
	root.add_child(door)
	info["door"] = door
	_sign(no, Vector3(cx, 2.35, s * 1.49), 180.0 if s > 0 else 0.0)
	var dark := kind == "abandoned" or kind == "laundry"
	_lamp(Vector3(cx, H - 0.08, s * 4.2), 1.0 if kind != "locked" else 0.6, 6.0, dark)

	# Möbel: Süd → Bett an der Westwand, Schrank an der Ostwand; Nord gespiegelt
	var bed_pos := Vector3(x0 + 0.85, 0, 5.45) if s > 0 else Vector3(x1 - 0.85, 0, -5.45)
	var bed_yaw := 90.0 if s > 0 else -90.0
	var wardrobe_pos := Vector3(x1 - 0.4, 0, 5.4) if s > 0 else Vector3(x0 + 0.4, 0, -5.4)
	var wardrobe_yaw := -90.0 if s > 0 else 90.0
	var table_pos := Vector3(x0 + 1.0, 0.375, 2.5) if s > 0 else Vector3(x1 - 1.0, 0.375, -2.5)
	if kind != "laundry":
		info["spots"].append(_hide_spot(HideSpot.Type.BED, bed_pos, bed_yaw))
		Geo.solid(root, Vector3(1.0, 0.75, 0.7), table_pos, _wood)
	if kind == "guest" or kind == "player" or kind == "empty":
		info["spots"].append(_hide_spot(HideSpot.Type.WARDROBE, wardrobe_pos, wardrobe_yaw))
	var table_top := Vector3(table_pos.x, 0.76, table_pos.z)

	match kind:
		"player":
			_item(Item.Kind.CANDLE, table_top)
			_item(Item.Kind.PUMPKIN, Vector3(cx + 1.2, 0.02, 5.9))
			var chest := Chest.new()
			chest.position = Vector3(x1 - 0.45, 0, 2.6)
			chest.rotation.y = deg_to_rad(-90.0)
			root.add_child(chest)
			_item(Item.Kind.COINS, Vector3(x1 - 0.45, 0.07, 2.35), "3")
			_item(Item.Kind.LEAVES, Vector3(x1 - 0.45, 0.07, 2.8))
		"abandoned":
			door.set_open.call_deferred(true)
			_item(Item.Kind.PUMPKIN, Vector3(cx + 1.5, 0.02, 3.5))
			_item(Item.Kind.COINS, table_top, "2")
			_item(Item.Kind.LOADED_DICE, table_top + Vector3(0.3, 0, 0.1))
			_resource_web(Vector3(x1 - 0.12, 2.2, 6.3), -135.0)
			_resource_web(Vector3(x0 + 0.12, 2.4, 2.0), 45.0)
		"laundry":
			# Waschmaschinen, Regale, Wäschesäcke
			for i in 3:
				var wm := Geo.solid(root, Vector3(0.65, 0.85, 0.65), Vector3(x0 + 0.45, 0.425, -3.0 - i * 0.8), Mat.psx(Color(0.75, 0.75, 0.72)))
				var porthole := Geo.mesh(wm, Geo.cylinder(0.2, 0.02, 10), Mat.psx(Color(0.15, 0.17, 0.2)), Vector3(0.33, 0.1, 0))
				porthole.rotation.z = PI / 2.0
			Geo.solid(root, Vector3(3.0, 2.0, 0.5), Vector3(cx + 0.5, 1.0, -6.2), _wood)
			Geo.solid(root, Vector3(0.9, 0.5, 0.9), Vector3(x1 - 0.8, 0.25, -5.6), Mat.psx(Color(0.6, 0.58, 0.5)))
			_resource_web(Vector3(x1 - 0.12, 2.3, -2.2), -45.0)
			_resource_web(Vector3(x0 + 0.12, 2.6, -6.3), 135.0)
			_item(Item.Kind.CANDLE, Vector3(cx + 0.5, 2.02, -6.2))
		"locked":
			door.locked = true
			door.key_id = "zimmer_18"
			door.locked_text = "Zimmer 18 ist abgeschlossen."
			_item(Item.Kind.CARVED_PUMPKIN, Vector3(cx - 1.0, 0.02, -3.2))
			_item(Item.Kind.COINS, table_top, "5")
			_item(Item.Kind.LEAVES, Vector3(cx + 1.0, 0.02, -2.6))
		"empty":
			_item(Item.Kind.CANDLE, table_top)
	rooms[no] = info


## Seitenwände und Rückwände der Zimmerreihen (jede Trennwand nur einmal).
func _room_walls() -> void:
	for s in [1.0, -1.0]:
		var bounds := {}
		var x_min := INF
		var x_max := -INF
		for data in ROOM_LAYOUT:
			if float(data["side"]) != s:
				continue
			bounds[float(data["x0"])] = true
			bounds[float(data["x1"])] = true
			x_min = minf(x_min, data["x0"])
			x_max = maxf(x_max, data["x1"])
		var z0: float = 1.6 if s > 0 else -6.7
		var z1: float = 6.7 if s > 0 else -1.6
		for x in bounds.keys():
			_wall_z(x, z0, z1, [])
		_wall_x(s * 6.6, x_min - 0.1, x_max + 0.1, [])
		var wood_floor := Mat.psx(Color(1, 1, 1), "wood", 1.0)
		Geo.solid(root, Vector3(x_max - x_min + 0.2, 0.2, 5.1), Vector3((x_min + x_max) / 2.0, -0.1, s * 4.15), wood_floor)


func _cellar() -> void:
	Geo.solid(root, Vector3(4.2, 0.2, 4.4), Vector3(32.1, -0.1, 0.0), _concrete)
	Geo.solid(root, Vector3(4.0, 0.2, 4.2), Vector3(32.15, 2.3, 0.0), _concrete, LAYER_CEILING)
	_wall_z(30.0, -2.2, 2.2, [Vector4(0.0, 0.9, 1.8, 0.0)])
	_wall_x(-2.2, 30.0, 34.3, [], _concrete)
	_wall_x(2.2, 30.0, 34.3, [], _concrete)
	_wall_z(34.2, -2.2, 2.2, [], _concrete)
	var door := Door.new().setup(0.9, 1.8, 90.0)
	door.position = Vector3(30.0, 0, -0.45)
	door.rotation.y = deg_to_rad(-90.0)
	root.add_child(door)
	_sign("KELLER", Vector3(29.89, 2.0, 0.0), -90.0)
	_lamp(Vector3(32.1, 2.12, 0.0), 0.9, 4.5, true)   # kaputte Birne, blitzt nur auf
	Geo.solid(root, Vector3(0.7, 0.7, 0.7), Vector3(33.5, 0.35, -1.4), _dark_wood)
	Geo.solid(root, Vector3(0.6, 0.6, 0.6), Vector3(33.6, 0.3, 1.45), _dark_wood)
	Geo.solid(root, Vector3(0.6, 0.45, 0.6), Vector3(32.9, 0.225, 1.55), _dark_wood)
	_item(Item.Kind.KEY, Vector3(33.5, 0.72, -1.4), "zimmer_18")
	_item(Item.Kind.COINS, Vector3(31.4, 0.02, 1.2), "2")
	_resource_web(Vector3(33.9, 1.7, -2.08), 0.0)
	_resource_web(Vector3(30.5, 1.7, 2.08), 180.0)


# --- Lobby, Küche, Garten ---------------------------------------------------------------

func _lobby() -> void:
	Geo.solid(root, Vector3(14.0, 0.2, 14.2), Vector3(-7.1, -0.1, 0.0), Mat.psx(Color(1, 1, 1), "tiles", 0.5))
	Geo.solid(root, Vector3(14.6, 0.2, 14.6), Vector3(-7.0, LOBBY_H + 0.1, 0.0), _ceiling, LAYER_CEILING)
	_wall_z(0.0, -7.1, 7.1, [Vector4(0.0, 3.0, 3.0, 0.0)], null, LOBBY_H)                 # Durchgang zum Flur
	_wall_z(-14.0, -7.1, 13.1, [Vector4(0.0, 2.5, 2.5, 0.0)], null, LOBBY_H)              # Ausgang
	_wall_x(-7.0, -14.1, 0.1, [Vector4(-11.0, 1.6, 2.7, 0.9), Vector4(-7.0, 1.8, 2.4, 0.0), Vector4(-3.0, 1.6, 2.7, 0.9)], null, LOBBY_H)
	_wall_x(7.0, -14.1, 0.1, [Vector4(-10.0, DOOR_W, DOOR_H, 0.0), Vector4(-3.0, 2.0, 2.6, 0.0)], null, LOBBY_H)   # Küche, Bar
	for x in [-11.0, -3.0]:
		Geo.solid(root, Vector3(1.6, 1.8, 0.04), Vector3(x, 1.8, -7.0), Mat.glass(), LAYER_GLASS)

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
		_lamp(p, 1.5, 9.0, false)
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
	_lamp(Vector3(-10.0, H - 0.08, 10.0), 1.0, 6.0, false)
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
	_lamp(Vector3(-3.0, H - 0.08, 8.8), 0.9, 5.5, false)
	_lamp(Vector3(-3.0, H - 0.08, 11.8), 0.7, 5.0, false)
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


# --- Zonen & Route ------------------------------------------------------------------------

func _zones() -> void:
	zones = [
		{"name": "Lobby", "center": Vector3(-7.0, 0, 0), "radius": 7.0},
		{"name": "Küche", "center": Vector3(-10.0, 0, 10.0), "radius": 4.0},
		{"name": "Bar", "center": Vector3(-3.0, 0, 10.0), "radius": 3.2},
		{"name": "Garten", "center": Vector3(-7.0, 0, -13.0), "radius": 6.0},
		{"name": "Flur West", "center": Vector3(4.5, 0, 0), "radius": 4.5},
		{"name": "Flur Mitte", "center": Vector3(14.0, 0, 0), "radius": 5.0},
		{"name": "Flur Ost", "center": Vector3(25.0, 0, 0), "radius": 5.5},
		{"name": "Keller", "center": Vector3(32.2, 0, 0), "radius": 2.5},
	]
	for no in rooms:
		var info: Dictionary = rooms[no]
		zones.append({"name": "Zimmer " + String(no), "center": info["center"], "radius": 3.2})
	for zone in zones:
		zone["curiosity"] = 50.0
	spawn_points = [
		Vector3(32.8, 0.05, 0.2),      # Keller – das Versteck des Monsters
		Vector3(25.0, 0.05, 3.6),      # Zimmer 17 (verlassen)
		Vector3(17.0, 0.05, -4.5),     # Wäscherei
		Vector3(-12.5, 0.05, -15.0),   # Garten
	]


## Feste Route (Spielkonzept: Patrouille). Das Monster startet im Keller, läuft die
## Route einmal ab und kehrt zurück. An Türen (room ≠ "") kann es ins Zimmer abbiegen.
func _patrol_route() -> void:
	var route: Array = [
		[Vector3(32.4, 0, 0.0), ""],
		[Vector3(27.0, 0, 0.0), ""],
		[Vector3(25.0, 0, 0.7), "17"],
		[Vector3(23.0, 0, -0.7), "18"],
		[Vector3(19.0, 0, 0.7), "15"],
		[Vector3(17.0, 0, -0.7), "16"],
		[Vector3(13.0, 0, 0.7), "13"],
		[Vector3(11.0, 0, -0.7), "14"],
		[Vector3(7.0, 0, 0.7), "11"],
		[Vector3(5.0, 0, -0.7), "12"],
		[Vector3(-2.0, 0, 0.0), ""],
		[Vector3(-7.0, 0, -5.5), ""],
		[Vector3(-7.0, 0, -11.0), ""],
		[Vector3(-11.0, 0, -17.0), ""],
		[Vector3(-3.5, 0, -14.5), ""],
		[Vector3(-7.0, 0, -8.5), ""],
		[Vector3(-6.0, 0, 3.5), ""],
		[Vector3(-10.0, 0, 6.0), ""],
		[Vector3(-11.0, 0, 10.5), ""],
		[Vector3(-10.0, 0, 6.0), ""],
		[Vector3(-3.0, 0, 6.0), ""],
		[Vector3(-2.0, 0, 9.3), ""],
		[Vector3(-3.0, 0, 6.0), ""],
		[Vector3(-1.5, 0, 0.0), ""],
		[Vector3(15.0, 0, 0.0), ""],
		[Vector3(28.5, 0, 0.0), ""],
	]
	for entry in route:
		patrol.append({"pos": entry[0], "room": entry[1]})


# --- Bausteine ------------------------------------------------------------------------------

## Wand entlang X bei z. Öffnungen als Vector4(Mitte x, Breite, Oberkante, Unterkante).
func _wall_x(z: float, x0: float, x1: float, openings: Array, mat: Material = null, height: float = H, thick: float = T) -> void:
	var m: Material = mat if mat else _wallpaper
	var cursor := x0
	for o in openings:
		var op: Vector4 = o
		var a := op.x - op.y / 2.0
		if a > cursor:
			Geo.solid(root, Vector3(a - cursor, height, thick), Vector3((cursor + a) / 2.0, height / 2.0, z), m)
		if op.w > 0.0:
			Geo.solid(root, Vector3(op.y, op.w, thick), Vector3(op.x, op.w / 2.0, z), m)
		if op.z < height:
			Geo.solid(root, Vector3(op.y, height - op.z, thick), Vector3(op.x, op.z + (height - op.z) / 2.0, z), m)
		cursor = op.x + op.y / 2.0
	if x1 > cursor:
		Geo.solid(root, Vector3(x1 - cursor, height, thick), Vector3((cursor + x1) / 2.0, height / 2.0, z), m)


## Wand entlang Z bei x. Öffnungen als Vector4(Mitte z, Breite, Oberkante, Unterkante).
func _wall_z(x: float, z0: float, z1: float, openings: Array, mat: Material = null, height: float = H, thick: float = T) -> void:
	var m: Material = mat if mat else _wallpaper
	var cursor := z0
	for o in openings:
		var op: Vector4 = o
		var a := op.x - op.y / 2.0
		if a > cursor:
			Geo.solid(root, Vector3(thick, height, a - cursor), Vector3(x, height / 2.0, (cursor + a) / 2.0), m)
		if op.w > 0.0:
			Geo.solid(root, Vector3(thick, op.w, op.y), Vector3(x, op.w / 2.0, op.x), m)
		if op.z < height:
			Geo.solid(root, Vector3(thick, height - op.z, op.y), Vector3(x, op.z + (height - op.z) / 2.0, op.x), m)
		cursor = op.x + op.y / 2.0
	if z1 > cursor:
		Geo.solid(root, Vector3(thick, height, z1 - cursor), Vector3(x, height / 2.0, (cursor + z1) / 2.0), m)


func _sign(text: String, pos: Vector3, yaw: float) -> void:
	var label := Label3D.new()
	label.text = text
	label.pixel_size = 0.008
	label.font_size = 24
	label.modulate = Color(0.85, 0.7, 0.35)
	label.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	label.position = pos
	label.rotation.y = deg_to_rad(yaw)
	root.add_child(label)


func _lamp(pos: Vector3, energy: float, light_range: float, broken: bool) -> void:
	var mat := Mat.psx(Color(1, 0.95, 0.8), "", 1.0, Color(1.0, 0.85, 0.6), 2.5, false)
	Geo.mesh(root, Geo.box(Vector3(0.45, 0.06, 0.45)), mat, pos)
	var light := FlickerLight.new()
	light.position = pos + Vector3(0, -0.25, 0)
	light.base_energy = energy
	light.omni_range = light_range
	light.light_color = Color(1.0, 0.8, 0.55)
	light.shadow_enabled = true
	light.broken = broken
	light.lamp_material = mat
	light.add_to_group("lamps")
	root.add_child(light)


func _hide_spot(type: HideSpot.Type, pos: Vector3, yaw: float) -> HideSpot:
	var spot := HideSpot.new().setup(type)
	spot.position = pos
	spot.rotation.y = deg_to_rad(yaw)
	root.add_child(spot)
	return spot


func _painting(pos: Vector3, yaw: float, color: Color) -> void:
	var holder := Node3D.new()
	holder.position = pos
	holder.rotation.y = deg_to_rad(yaw)
	root.add_child(holder)
	Geo.mesh(holder, Geo.box(Vector3(0.8, 0.6, 0.04)), _dark_wood, Vector3(0, 0, 0.02))
	Geo.mesh(holder, Geo.box(Vector3(0.66, 0.46, 0.045)), Mat.psx(color), Vector3(0, 0, 0.025))


## Spinnweben in einer Ecke, die man abnehmen kann (lokale +Z zeigt in den Raum).
func _resource_web(pos: Vector3, yaw: float) -> void:
	var spot := ResourceSpot.new().setup(Item.Kind.COBWEB, "Spinnenweben", 1, 240.0)
	spot.position = pos
	spot.rotation.y = deg_to_rad(yaw)
	root.add_child(spot)


func _item(kind: Item.Kind, pos: Vector3, extra: String = "") -> Item:
	var item := Item.create(kind, extra)
	item.position = pos
	world.add_child(item)
	return item
