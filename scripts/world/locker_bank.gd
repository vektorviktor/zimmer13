class_name LockerBank
extends StaticBody3D
## Spindblock der Pool-Umkleiden (ZIM-145, Foto des Nutzers 31.10.): ein anthraziter Sockel, vorn 40 cm Sitzfläche
## (Seat), hinten darauf sechs Spaltenpaare Spinde (je 40 cm breit, 90 cm hoch, zwei übereinander, 50 cm tief mit Tür)
## und rechts ein offenes Regal mit 3 × 2 Fächern (1,20 m). Korpus fast schwarz, innen weiß, Türen mit Holzdekor
## (Wood_02, Faser senkrecht), ringsum 8 mm Luft; oben rechts an jeder Tür ein schwarzes Schloss. Ursprung am Boden
## in der Mitte, lokal +Z = Vorderseite, das Regal liegt bei +X (von vorn gesehen rechts).
##
## Nummern (number_of): je Block spaltenweise von links oben (1 oben, 2 darunter, 3 oben daneben …), über alle Blöcke
## des Stockwerks fortlaufend (LevelBuilder._locker_banks). Die meisten Spinde sind verschlossen; welche aufgehen,
## steht in OPENABLE – frei oder nur mit Schlüssel (Item.Kind.KEY, key_id KEY_PREFIX + Nummer). Beim ersten Öffnen
## liegt manchmal etwas darin (wie in der Kommode, Spielkonzept 3.5).

## Maße: Länge, Tiefe, Sitzhöhe (Oberkante der Sitzplatte), Sitzplatte, Rücksprung des Sockels
const DEPTH := 0.9
const SEAT_H := 0.5
const SLAB := 0.03
const PLINTH_INSET := 0.025
## Abstand der Rückseite zur Wandfläche (die Fliesen liegen auf ihr)
const WALL_CLEAR := 0.005
## Spinde: Spalten, Breite und Höhe eines Fachs, Korpustiefe ohne Tür, Plattenstärke, Rückwand
const COLS := 6
const COL_W := 0.4
const CELL := Vector2(COL_W, 0.9)
const BODY_D := 0.48
const BOARD := 0.019
const BACK := 0.008
const PER_BANK := COLS * 2
const TOP := SEAT_H + 2.0 * CELL.y
## Türen: Luft ringsum, Stärke, Dekorschicht, Öffnungswinkel, Abstand vom Korpus
const DOOR_GAP := 0.008
const DOOR_T := 0.019
const DECOR := 0.0008
const DOOR_OPEN := 95.0
const DOOR_CLEAR := 0.001
## Regal rechts: Breite, Spalten, Reihen
const SHELF_W := 1.2
const SHELF_COLS := 2
const SHELF_ROWS := 3
## Länge des Blocks (3,60 m, im Plan 36 × 9 px)
const LENGTH := COLS * COL_W + SHELF_W
## Schloss: Gehäuse, Mitte von der Türkante (x) und Oberkante (y), Schließzylinder
const LOCK := Vector3(0.034, 0.056, 0.012)
const LOCK_AT := Vector2(0.032, 0.075)
const CYLINDER := Vector2(0.007, 0.004)
## Melamin aus tools/locker_melamine.gd (neutral grau, hier getönt), Holzdekor Wood_02 (Mat.wood)
const MELAMINE_TEX := "res://assets/textures/locker_melamine"
const MELAMINE_METERS := 0.2
const MELAMINE_GLOSS := 0.3
const CARCASS_TINT := Color(0.26, 0.26, 0.27)
const SHELF_TINT := Color(0.42, 0.42, 0.44)
const PLINTH_TINT := Color(0.5, 0.5, 0.52)
const SLAB_TINT := Color(0.36, 0.36, 0.38)
const INNER_TINT := Color(1.75, 1.75, 1.72)
const LOCK_TINT := Color(0.16, 0.16, 0.17)
const DECOR_TINT := Color(1.25, 1.02, 0.86)
## Dekor: Meter je Kachel längs und quer zur Faser
const DECOR_TILE := Vector2(1.2, 0.5)
const SEED := 1450

## Spinde, die aufgehen: Nummer → "" (frei) oder "key" (nur mit Schlüssel KEY_PREFIX + Nummer). Alle übrigen bleiben zu.
## Wo die Schlüssel liegen, ist noch offen (ZIM-145).
const OPENABLE := {3: "", 10: "", 17: "", 22: "", 29: "", 34: "", 41: "", 46: "",
	7: "key", 20: "key", 32: "key", 44: "key"}
const KEY_PREFIX := "spind_"
## Fund beim ersten Öffnen (Schlüsselspinde nie leer)
const EMPTY_CHANCE := 0.45
const COINS_CHANCE := 0.25
const LOOT := [Item.Kind.CANDLE, Item.Kind.BATTERY, Item.Kind.BATTERY, Item.Kind.SWEETS, Item.Kind.SWEETS,
	Item.Kind.BULB, Item.Kind.LIGHT_STRING, Item.Kind.LOADED_DICE]
const EMPTY_LINES := ["Leer. Es riecht nach Chlor.", "Ein vergessener Haargummi, sonst nichts.",
	"Leer – nur ein paar Wassertropfen am Boden.", "Ein abgerissenes Eintrittsband. Sonst nichts."]

## Nummer des ersten Spinds (oben links) – setzt LevelBuilder vor add_child
var first_number := 1
var is_open: Array[bool] = []
var unlocked: Array[bool] = []
var searched: Array[bool] = []

var _doors: Array[StaticBody3D] = []


## Tür eines Spinds: das, worauf der Spieler zielt (interagierbar), leitet an den Block weiter.
class Handle:
	var bank: LockerBank
	var index := 0

	func _init(p_bank: LockerBank, p_index: int) -> void:
		bank = p_bank
		index = p_index

	func get_prompt(player: Player) -> String:
		return bank.door_prompt(index, player)

	func get_icon(_player: Player) -> String:
		return "door"

	func interact(player: Player) -> void:
		bank.use_door(index, player)


func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	add_to_group("locker_banks")
	_build()


## Nummer des Spinds i im Block (i = Spalte · 2 + Reihe, Reihe 0 = oben)
func number_of(i: int) -> int:
	return first_number + i


## "" = geht frei auf, KEY_PREFIX + Nummer = nur mit diesem Schlüssel, null = bleibt zu
func lock_of(i: int) -> Variant:
	var n := number_of(i)
	if not OPENABLE.has(n):
		return null
	return "" if OPENABLE[n] == "" else "%s%02d" % [KEY_PREFIX, n]


static func key_label(id: String) -> String:
	return "Spindschlüssel %d" % int(id.substr(KEY_PREFIX.length()))


func door_prompt(i: int, player: Player) -> String:
	var title := "Spind %d" % number_of(i)
	var lock: Variant = lock_of(i)
	if lock == null or (lock != "" and not unlocked[i] and not player.has_key(lock)):
		return "%s · Verschlossen" % title
	if player.hands_blocked():
		return "%s · Hände voll" % title
	if lock != "" and not unlocked[i]:
		return "%s · Aufschließen [E]" % title
	return "%s · %s [E]" % [title, "Schließen" if is_open[i] else "Öffnen"]


func use_door(i: int, player: Player) -> void:
	var lock: Variant = lock_of(i)
	var door := _doors[i]
	if lock == null or (lock != "" and not unlocked[i] and not player.has_key(lock)):
		Game.say("Abgeschlossen.", 1.5)
		Game.noise("rattle", door.global_position, player)
		return
	if player.hands_blocked():
		Game.say("Mit vollen Händen geht das nicht.")
		return
	if lock != "" and not unlocked[i]:
		unlocked[i] = true
		Game.say("Aufgeschlossen.", 1.5)
		Game.noise("unlock", door.global_position, player)
	set_open(i, not is_open[i])
	if is_open[i] and not searched[i]:
		searched[i] = true
		_roll_loot(i, lock != "")
	if is_open[i] and Game.spiders:   # manchmal krabbelt eine Spinne heraus (Spielkonzept 4.23)
		Game.spiders.on_drawer_opened(door.global_position)


func set_open(i: int, open: bool, instant: bool = false) -> void:
	if is_open[i] == open:
		return
	is_open[i] = open
	var door := _doors[i]
	var target := deg_to_rad(-DOOR_OPEN) if open else 0.0
	if instant:
		door.rotation.y = target
		return
	create_tween().tween_property(door, "rotation:y", target, 0.45).set_trans(Tween.TRANS_SINE)
	Game.noise("locker", door.global_position)


## --spinde[=offen]: vor den ersten Block (Spinde 1–12) · offen: alle Spinde, die aufgehen, offen (die mit Schlüssel
## aufgeschlossen), ohne Fund
static func debug_show(tree: SceneTree, open: bool) -> void:
	var first: LockerBank = null
	for bank: LockerBank in tree.get_nodes_in_group("locker_banks"):
		if open:
			for i in PER_BANK:
				if bank.lock_of(i) != null:
					bank.unlocked[i] = true
					bank.searched[i] = true
					bank.set_open(i, true, true)
		if first == null or bank.first_number < first.first_number:
			first = bank
	if first == null:
		push_warning("--spinde: kein Spindblock im Plan")
		return
	var forward := first.global_basis.z
	TeleportUI.place_player(first.global_position + forward * (DEPTH / 2.0 + 1.5), -forward)


func save_state() -> Dictionary:
	return {"open": is_open.duplicate(), "unlocked": unlocked.duplicate(), "searched": searched.duplicate()}


func load_state(d: Dictionary) -> void:
	var open: Array = d.get("open", [])
	var keys: Array = d.get("unlocked", [])
	var done: Array = d.get("searched", [])
	for i in mini(PER_BANK, keys.size()):
		unlocked[i] = bool(keys[i])
	for i in mini(PER_BANK, done.size()):
		searched[i] = bool(done[i])
	for i in mini(PER_BANK, open.size()):
		set_open(i, bool(open[i]), true)


func _roll_loot(i: int, keyed: bool) -> void:
	var roll := randf()
	if not keyed and roll < EMPTY_CHANCE:
		Game.say(EMPTY_LINES[randi() % EMPTY_LINES.size()], 2.0)
		return
	var item: Item
	if roll < EMPTY_CHANCE + COINS_CHANCE:
		item = Item.create(Item.Kind.COINS, str(randi_range(1, 5)))
	else:
		item = Item.create(LOOT[randi() % LOOT.size()] as Item.Kind)
	Game.social.builder.world.add_child(item)
	var c := _cell(i)
	item.global_position = global_transform * Vector3(c.position.x + c.size.x / 2.0, c.position.y + 0.04,
		-DEPTH / 2.0 + (BACK + BODY_D) / 2.0)
	item.rotation.y = rotation.y + randf_range(-0.6, 0.6)


# --- Bau -------------------------------------------------------------------------------------------------------

## Fach i (Spalte · 2 + Reihe): Rechteck in x/y von Mitte Teilung zu Mitte Teilung
static func _cell(i: int) -> Rect2:
	var col := i / 2
	var row := i % 2
	var y := SEAT_H + (CELL.y if row == 0 else 0.0)
	return Rect2(-LENGTH / 2.0 + col * CELL.x, y, CELL.x, CELL.y)


static func _mat(tint: Color) -> ShaderMaterial:
	return Mat.photo(MELAMINE_TEX + ".png", MELAMINE_METERS, MELAMINE_TEX + "_normal.png", MELAMINE_TEX + "_rough.png",
		MELAMINE_GLOSS, tint)


## Teile je Material: Kästen in ein SurfaceTool, am Ende ein Mesh mit einer Fläche je Material
class Parts:
	var tools := {}   # Material → SurfaceTool

	func box(mat: Material, size: Vector3, center: Vector3) -> void:
		_st(mat).append_from(Geo.box(size), 0, Transform3D(Basis(), center))

	func mesh(mat: Material, m: Mesh, surface: int, xf: Transform3D) -> void:
		_st(mat).append_from(m, surface, xf)

	func _st(mat: Material) -> SurfaceTool:
		if not tools.has(mat):
			var st := SurfaceTool.new()
			st.begin(Mesh.PRIMITIVE_TRIANGLES)
			tools[mat] = st
		return tools[mat]

	func commit() -> ArrayMesh:
		var m := ArrayMesh.new()
		for mat: Material in tools:
			(tools[mat] as SurfaceTool).commit(m)
			m.surface_set_material(m.get_surface_count() - 1, mat)
		return m


## Sockel mit Sitzplatte (eigener Körper mit Sitzplätzen), Korpus der Spinde mit weißer Auskleidung je Fach, Regal,
## Türen. Feste Türen liegen im Mesh des Blocks; die, die aufgehen, drehen sich als eigenes Mesh um ihr Scharnier
## (links). Kollision: Sockel als Kasten, jede Platte als Kasten (Fächer und Regal hohl), jede Tür als Kasten.
func _build() -> void:
	var carcass := _mat(CARCASS_TINT)
	var shelf := _mat(SHELF_TINT)
	var inner := _mat(INNER_TINT)
	var p := Parts.new()
	var h := LENGTH / 2.0
	var back_z := -DEPTH / 2.0
	var front_z := back_z + BODY_D
	# Sockel und Sitzplatte
	var base := StaticBody3D.new()
	base.collision_mask = 0
	add_child(base)
	var plinth_h := SEAT_H - SLAB
	p.box(_mat(PLINTH_TINT), Vector3(LENGTH, plinth_h, DEPTH - PLINTH_INSET), Vector3(0, plinth_h / 2.0, -PLINTH_INSET / 2.0))
	p.mesh(_mat(SLAB_TINT), Geo.rounded_box(Vector3(LENGTH, SLAB, DEPTH), 0.004, 1), 0,
		Transform3D(Basis(), Vector3(0, SEAT_H - SLAB / 2.0, 0)))
	Geo.add_box_shape(base, Vector3(LENGTH, SEAT_H, DEPTH), Vector3(0, SEAT_H / 2.0, 0))
	var seat_z := (front_z + DOOR_CLEAR + DOOR_T + DEPTH / 2.0) / 2.0
	Seat.attach(base, "bank", SEAT_H, Vector3(0, 0, seat_z), Vector3(0, 0, 1), LENGTH, DEPTH / 2.0 - seat_z + 0.3)
	# Spinde: Seitenwände (außen bündig, innen auf der Teilung), Böden, Rückwand
	var lockers_end := -h + COLS * CELL.x
	var body_d := BODY_D
	var mid_z := back_z + body_d / 2.0
	var height := TOP - SEAT_H
	for i in COLS + 1:
		var x := -h + i * CELL.x
		x += BOARD / 2.0 if i == 0 else (-BOARD / 2.0 if i == COLS else 0.0)
		_board(p, carcass, Vector3(BOARD, height, body_d), Vector3(x, SEAT_H + height / 2.0, mid_z))
	var run := COLS * CELL.x
	for y: float in [SEAT_H + BOARD / 2.0, SEAT_H + CELL.y, TOP - BOARD / 2.0]:
		_board(p, carcass, Vector3(run, BOARD, body_d), Vector3(-h + run / 2.0, y, mid_z))
	_board(p, carcass, Vector3(run, height, BACK), Vector3(-h + run / 2.0, SEAT_H + height / 2.0, back_z + BACK / 2.0))
	for i in PER_BANK:
		_lining(p, inner, i, back_z + BACK, front_z)
	# Regal: 3 × 2 Fächer, so tief wie die Spinde mit Tür
	var shelf_d := body_d + DOOR_CLEAR + DOOR_T
	var shelf_z := back_z + shelf_d / 2.0
	var pitch := (SHELF_W - BOARD) / SHELF_COLS
	for i in SHELF_COLS + 1:
		var x := lockers_end + BOARD / 2.0 + i * pitch
		_board(p, shelf, Vector3(BOARD, height, shelf_d), Vector3(x, SEAT_H + height / 2.0, shelf_z))
	var row_h := (height - BOARD) / SHELF_ROWS
	for i in SHELF_ROWS + 1:
		_board(p, shelf, Vector3(SHELF_W, BOARD, shelf_d), Vector3(lockers_end + SHELF_W / 2.0, SEAT_H + BOARD / 2.0 + i * row_h, shelf_z))
	_board(p, shelf, Vector3(SHELF_W, height, BACK), Vector3(lockers_end + SHELF_W / 2.0, SEAT_H + height / 2.0, back_z + BACK / 2.0))
	# Türen
	var rng := RandomNumberGenerator.new()
	rng.seed = SEED
	var door_size := CELL - Vector2.ONE * 2.0 * DOOR_GAP
	var hinge_z := front_z + DOOR_CLEAR + DOOR_T
	for i in PER_BANK:
		var c := _cell(i)
		var door := StaticBody3D.new()
		door.collision_mask = 0
		door.position = Vector3(c.position.x + DOOR_GAP, c.position.y + DOOR_GAP, hinge_z)
		door.set_meta("interactable", Handle.new(self, i))
		add_child(door)
		Geo.add_box_shape(door, Vector3(door_size.x, door_size.y, DOOR_T), Vector3(door_size.x / 2.0, door_size.y / 2.0, -DOOR_T / 2.0))
		_doors.append(door)
		is_open.append(false)
		unlocked.append(false)
		searched.append(false)
		var offset := Vector2(rng.randf(), rng.randf())
		if lock_of(i) == null:
			_door(p, door_size, offset, door.transform)
		else:
			var own := Parts.new()
			_door(own, door_size, offset, Transform3D())
			Geo.mesh(door, own.commit(), null, Vector3.ZERO)
	Geo.mesh(self, p.commit(), null, Vector3.ZERO)


## Platte als Mesh und Kollisionskasten
func _board(p: Parts, mat: Material, size: Vector3, center: Vector3) -> void:
	p.box(mat, size, center)
	Geo.add_box_shape(self, size, center)


## Weiße Auskleidung des Fachs i: Rückwand, Boden, Decke und Seiten als 1 mm dünne Kästen vor den Platten
static func _lining(p: Parts, mat: Material, i: int, back: float, front: float) -> void:
	const T := 0.001
	var c := _cell(i)
	var x0 := c.position.x + (BOARD if i / 2 == 0 else BOARD / 2.0)
	var x1 := c.end.x - (BOARD if i / 2 == COLS - 1 else BOARD / 2.0)
	var y0 := c.position.y + (BOARD if i % 2 == 1 else BOARD / 2.0)
	var y1 := c.end.y - (BOARD if i % 2 == 0 else BOARD / 2.0)
	var w := x1 - x0
	var hh := y1 - y0
	var d := front - back
	var cx := (x0 + x1) / 2.0
	var cy := (y0 + y1) / 2.0
	var cz := (back + front) / 2.0
	p.box(mat, Vector3(w, hh, T), Vector3(cx, cy, back + T / 2.0))
	p.box(mat, Vector3(w, T, d), Vector3(cx, y0 + T / 2.0, cz))
	p.box(mat, Vector3(w, T, d), Vector3(cx, y1 - T / 2.0, cz))
	p.box(mat, Vector3(T, hh, d), Vector3(x0 + T / 2.0, cy, cz))
	p.box(mat, Vector3(T, hh, d), Vector3(x1 - T / 2.0, cy, cz))


## Tür (Ursprung unten links an der Vorderfläche = Scharnier): schwarzer Kern, vorn und hinten Holzdekor, Schloss
## oben rechts. xf legt sie in den Block (feste Türen) oder lässt sie im Ursprung (eigenes Mesh).
static func _door(p: Parts, size: Vector2, offset: Vector2, xf: Transform3D) -> void:
	var core := Vector3(size.x, size.y, DOOR_T - 2.0 * DECOR)
	p.mesh(_mat(CARCASS_TINT), Geo.box(core), 0, xf * Transform3D(Basis(), Vector3(size.x / 2.0, size.y / 2.0, -DOOR_T / 2.0)))
	var sheet := Geo.grain_box(Vector3(size.x, size.y, DECOR), 1, DECOR_TILE, 0.1, offset)
	for z: float in [-DECOR / 2.0, -DOOR_T + DECOR / 2.0]:
		p.mesh(Mat.wood(false, DECOR_TINT), sheet, 0, xf * Transform3D(Basis(), Vector3(size.x / 2.0, size.y / 2.0, z)))
	var lock := Vector3(size.x - LOCK_AT.x, size.y - LOCK_AT.y, LOCK.z / 2.0)
	p.mesh(_mat(LOCK_TINT), Geo.rounded_box(LOCK, 0.003, 1), 0, xf * Transform3D(Basis(), lock))
	var turn := Basis(Vector3.RIGHT, PI / 2.0)   # Zylinder zeigt nach vorn
	p.mesh(Mat.metal(), Geo.cylinder(CYLINDER.x, CYLINDER.y, 12), 0,
		xf * Transform3D(turn, lock + Vector3(0, LOCK.y * 0.18, LOCK.z / 2.0 + CYLINDER.y / 2.0)))
