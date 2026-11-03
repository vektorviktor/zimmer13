class_name SteelLocker
extends StaticBody3D
## Stahlspinde (Spielkonzept 7.18, ZIM-174, Fotos des Nutzers 3.11.): einzeln (50 × 50 cm, im Plan 5 × 5 px) oder als Reihe – ein längeres
## Rechteck sind count Spinde nebeneinander mit gemeinsamen Zwischenwänden (300 × 50 = 6). Für Lager, Hausmeisterraum
## (Spind des Hausmeisters, Spielkonzept 7.4) und Heizraum (Josefs Spind). Ohne Füße, 1,80 m hoch, Korpus angelaufenes
## verzinktes Blech, Türen blau lackiert (leicht rau, nur stellenweise glänzend), Lüftungsschlitze oben nur über die
## Textur (tools/steel_locker_tex.gd). Innen eine Hutablage. Ursprung am Boden in der Mitte, lokal +Z = Vorderseite,
## Spind 0 liegt von vorn gesehen links (−X), die Türen schlagen links an.
##
## Mit Vorhängeschloss (locked, Planfarbe „Spind mit Schloss“): ein Zahlenschloss hängt an der Öse jeder Tür; es geht
## mit dem Code auf (CodeLockUI, vier Räder), danach geht die Tür frei. Die Codes stehen fest je Spind (code_of) – wo
## man sie findet, ist noch offen (ZIM-174). Ein Gegenstand des Plans im Rechteck liegt auf der Hutablage des Spinds,
## über dem er gemalt ist (LevelBuilder._items, put_inside); die übrigen haben beim ersten Öffnen manchmal einen Fund.

## Maße: Breite je Spind, Tiefe, Höhe, Blechstärke, Rahmen (je Spind seitlich, oben, Sockelblende unten), Tiefe des Rahmens
const MODULE := 0.5
const DEPTH := 0.5
const HEIGHT := 1.8
const SHEET := 0.0012
const FRAME_SIDE := 0.0125
const FRAME_TOP := 0.03
const FRAME_BOTTOM := 0.06
const FRAME_D := 0.018
## Abstand der Rückseite zur Wandfläche
const WALL_CLEAR := 0.01
## Tür: Luft ringsum, Stärke, Rücksprung hinter die Rahmenvorderkante, Radius der Kanten, Öffnungswinkel
const DOOR_GAP := 0.003
const DOOR_T := 0.02
const DOOR_INSET := 0.002
const DOOR_ROUND := 0.003
const DOOR_OPEN := 100.0
## Hutablage: Oberkante über dem Boden, Kante vorn
const SHELF_Y := 1.47
const SHELF_LIP := 0.02
## Beschlag an der Tür (von der rechten Türkante, über dem Boden): Rosette, Öse nach vorn
const HASP_AT := Vector2(0.035, 1.05)
const ROSETTE := Vector2(0.019, 0.005)
const STAPLE := Vector3(0.006, 0.006, 0.026)
## Zahlenschloss: Bügel (Drahtradius, halbe Weite, Schenkel), Gehäuse (Radius, Stärke), Zahlenscheibe, Knopf
const SHACKLE := Vector3(0.0025, 0.009, 0.02)
const PADLOCK := Vector2(0.025, 0.014)
const DIAL := Vector2(0.02, 0.004)
const KNOB := Vector2(0.007, 0.005)
## Texturen aus tools/steel_locker_tex.gd: Lack (in Modellkoordinaten – die Tür dreht sich), Zink (in Weltkoordinaten),
## Schlitze über UV2 der Türfront (Verschattung, Normale im Objektraum)
const PAINT_TEX := "res://assets/textures/steel_paint"
const PAINT_METERS := 0.5
const PAINT_SPECULAR := 0.5
const GALV_TEX := "res://assets/textures/galvanized"
const GALV_METERS := 0.6
const GALV_SPECULAR := 0.5
const GALV_METALLIC := 0.3
const LOUVRE_TEX := "res://assets/textures/steel_locker_louvre"
const GALV_TINT := Color(1, 1, 1)
const PAINT_TINT := Color(1, 1, 1)
const DIAL_TINT := Color(0.1, 0.1, 0.11)
const SEED := 1741
## Zahlenschloss-Fenster (CodeLockUI)
const LOCK_TITLE := "Zahlenschloss"
const LOCK_HINT := "Ein Vorhängeschloss mit Zahlenscheibe, die Ziffern abgegriffen. [Enter] probieren · [Esc] lassen"
## Fund beim ersten Öffnen eines Spinds ohne Gegenstand aus dem Plan
const EMPTY_CHANCE := 0.6
const COINS_CHANCE := 0.15
const LOOT := [Item.Kind.CANDLE, Item.Kind.BATTERY, Item.Kind.BATTERY, Item.Kind.BULB, Item.Kind.BULB,
	Item.Kind.SWEETS, Item.Kind.LIGHT_STRING]
const EMPTY_LINES := ["Leer. Es riecht nach Rost und altem Öl.", "Ein leerer Kleiderbügel, sonst nichts.",
	"Leer – nur Staub auf der Ablage.", "Ein Paar ausgetretene Arbeitshandschuhe. Nichts Brauchbares."]

## Anzahl der Spinde und Vorhängeschloss (setzt LevelBuilder vor add_child)
var count := 1
var locked := false
var is_open: Array[bool] = []
var unlocked: Array[bool] = []
var searched: Array[bool] = []

var _doors: Array[StaticBody3D] = []
var _padlocks: Array[Node3D] = []
var _lock_ui: CodeLockUI

static var _paint_mat: ShaderMaterial
static var _front_mat: ShaderMaterial
static var _galv_mat: ShaderMaterial


## Tür eines Spinds: das, worauf der Spieler zielt (interagierbar), leitet an die Reihe weiter.
class Handle:
	var locker: SteelLocker
	var index := 0

	func _init(p_locker: SteelLocker, p_index: int) -> void:
		locker = p_locker
		index = p_index

	func get_prompt(player: Player) -> String:
		return locker.door_prompt(index, player)

	func get_icon(_player: Player) -> String:
		return "door"

	func interact(player: Player) -> void:
		locker.use_door(index, player)


func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	add_to_group("steel_lockers")
	_build()


## Länge der Reihe
func length() -> float:
	return count * MODULE


## Spind, über dem der Punkt local (lokal, x quer) liegt – von vorn gesehen von links gezählt
func index_at(local_x: float) -> int:
	return clampi(floori((local_x + length() / 2.0) / MODULE), 0, count - 1)


## Platz für einen Gegenstand auf der Hutablage von Spind i (lokal)
func shelf_spot(i: int) -> Vector3:
	return Vector3(-length() / 2.0 + (i + 0.5) * MODULE, SHELF_Y + 0.02, -DEPTH / 2.0 + DEPTH * 0.45)


## Gegenstand aus dem Plan liegt in Spind i: kein Zufallsfund mehr beim Öffnen
func put_inside(i: int) -> void:
	searched[i] = true


## Fester Code des Zahlenschlosses an Spind i: aus der Lage im Hotel, bei jedem Start gleich
func code_of(i: int) -> String:
	var at := global_transform * Vector3(-length() / 2.0 + (i + 0.5) * MODULE, 0, 0)
	return "%04d" % (absi(hash([SEED, roundi(at.x * 100.0), roundi(at.y * 100.0), roundi(at.z * 100.0)])) % 10000)


func padlocked(i: int) -> bool:
	return locked and not unlocked[i]


func door_prompt(i: int, player: Player) -> String:
	if player.hands_blocked():
		return "Spind · Hände voll"
	if padlocked(i):
		return "Spind · Zahlenschloss [E]"
	return "Spind · %s [E]" % ("Schließen" if is_open[i] else "Öffnen")


func use_door(i: int, player: Player) -> void:
	if player.hands_blocked():
		Game.say("Mit vollen Händen geht das nicht.")
		return
	if padlocked(i):
		_lock_ui.open(LOCK_TITLE, LOCK_HINT, func(code: String) -> bool: return try_code(i, player, code))
		return
	set_open(i, not is_open[i])
	if is_open[i] and not searched[i]:
		searched[i] = true
		_roll_loot(i)
	if is_open[i] and Game.spiders:   # manchmal krabbelt eine Spinne heraus (Spielkonzept 4.23)
		Game.spiders.on_drawer_opened(_doors[i].global_position)


## Code probieren (auch Debug). true = offen: das Schloss kommt ab, die Tür geht auf.
func try_code(i: int, player: Player, code: String) -> bool:
	var door := _doors[i]
	if code != code_of(i):
		Game.say("Das Schloss rührt sich nicht.", 2.0)
		Game.noise("rattle", door.global_position, player)
		return false
	Game.say("Klick – das Schloss springt auf.", 2.5)
	Game.noise("unlock", door.global_position, player)
	unlock(i)
	use_door(i, player)
	return true


func unlock(i: int) -> void:
	unlocked[i] = true
	if _padlocks[i]:
		_padlocks[i].visible = false


func set_open(i: int, open: bool, instant: bool = false) -> void:
	if is_open[i] == open:
		return
	is_open[i] = open
	var door := _doors[i]
	var target := deg_to_rad(-DOOR_OPEN) if open else 0.0
	if instant:
		door.rotation.y = target
		return
	create_tween().tween_property(door, "rotation:y", target, 0.5).set_trans(Tween.TRANS_SINE)
	Game.noise("locker", door.global_position)


## --stahlspinde[=offen|pruefen]: vor die erste Reihe (die mit Schloss bevorzugt), Codes ins Protokoll. Fehlen im Plan
## eine Reihe aus vier und ein Spind mit Schloss, stellt es eine Probereihe ins Lager (EG, DEBUG_ROW). offen: alle aufgeschlossen und offen, ohne Fund ·
## pruefen: Spind bei 180 cm, falscher und richtiger Code
static func debug_show(tree: SceneTree, mode: String) -> void:
	var lockers := tree.get_nodes_in_group("steel_lockers")
	if not lockers.any(func(l: SteelLocker) -> bool: return l.locked) or not lockers.any(func(l: SteelLocker) -> bool: return l.count >= 4):
		_debug_row()
	var first: SteelLocker = null
	for locker: SteelLocker in tree.get_nodes_in_group("steel_lockers"):
		for i in locker.count:
			if locker.locked:
				print("[Stahlspind] bei %s, Spind %d: Code %s" % [locker.global_position.snappedf(0.1), i + 1, locker.code_of(i)])
			if mode == "offen":
				locker.unlock(i)
				locker.searched[i] = true
				locker.set_open(i, true, true)
		if first == null or (locker.locked and not first.locked):
			first = locker
	var forward := first.global_basis.z
	TeleportUI.place_player(first.global_position + forward * (DEPTH / 2.0 + 1.6), -forward)
	if mode == "pruefen":
		_debug_check(tree)


## Probereihe ohne Plan: an der Nordwand des Lagers östlich der Tür vier Spinde ohne Schloss, eine Taschenlampe im
## vierten (180 cm von links, wie ein Gegenstand des Plans), an der Ostwand nördlich der Tür zwei mit Schloss
const DEBUG_ROW := [{"count": 4, "locked": false, "at": Vector2(-70.85, -43.64), "yaw": 0.0},
	{"count": 2, "locked": true, "at": Vector2(-69.86, -42.45), "yaw": -PI / 2.0}]


static func _debug_row() -> void:
	var builder: LevelBuilder = Game.social.builder
	print("[Stahlspind] Probereihe im Lager")
	for row: Dictionary in DEBUG_ROW:
		var locker := SteelLocker.new()
		locker.count = row["count"]
		locker.locked = row["locked"]
		var at: Vector2 = row["at"]
		locker.position = Vector3(at.x, 0, at.y)
		locker.rotation.y = row["yaw"]
		builder.root.add_child(locker)
		if locker.count == 4:
			var i := locker.index_at(-locker.length() / 2.0 + 1.8)
			locker.put_inside(i)
			var item := Item.create(Item.Kind.FLASHLIGHT)
			builder.world.add_child(item)
			item.global_position = locker.global_transform * locker.shelf_spot(i)


static func _debug_check(tree: SceneTree) -> void:
	var check := func(what: String, ok: bool) -> void:
		print("[Stahlspind] %s: %s" % [what, "ok" if ok else "FEHLER"])
	var player := Game.player
	for locker: SteelLocker in tree.get_nodes_in_group("steel_lockers"):
		if locker.count >= 4:
			check.call("180 cm liegt in Spind 4", locker.index_at(-locker.length() / 2.0 + 1.8) == 3)
		if not locker.locked:
			continue
		var code := locker.code_of(0)
		var wrong := "0000" if code != "0000" else "1111"
		check.call("falscher Code bleibt zu", not locker.try_code(0, player, wrong) and locker.padlocked(0) and not locker.is_open[0])
		check.call("richtiger Code öffnet", locker.try_code(0, player, code) and not locker.padlocked(0) and locker.is_open[0])
		check.call("Schloss ab", not locker._padlocks[0].visible)
		var state := locker.save_state()
		check.call("gespeichert", bool(state["unlocked"][0]) and bool(state["open"][0]))
		break
	print("[Stahlspind] Prüfung fertig")


func save_state() -> Dictionary:
	return {"open": is_open.duplicate(), "unlocked": unlocked.duplicate(), "searched": searched.duplicate()}


func load_state(d: Dictionary) -> void:
	var open: Array = d.get("open", [])
	var keys: Array = d.get("unlocked", [])
	var done: Array = d.get("searched", [])
	for i in mini(count, keys.size()):
		if bool(keys[i]):
			unlock(i)
	for i in mini(count, done.size()):
		searched[i] = bool(done[i])
	for i in mini(count, open.size()):
		set_open(i, bool(open[i]), true)


func _roll_loot(i: int) -> void:
	var roll := randf()
	if roll < EMPTY_CHANCE:
		Game.say(EMPTY_LINES[randi() % EMPTY_LINES.size()], 2.0)
		return
	var item: Item
	if roll < EMPTY_CHANCE + COINS_CHANCE:
		item = Item.create(Item.Kind.COINS, str(randi_range(1, 4)))
	else:
		item = Item.create(LOOT[randi() % LOOT.size()] as Item.Kind)
	Game.social.builder.world.add_child(item)
	item.global_position = global_transform * shelf_spot(i)
	item.rotation.y = rotation.y + randf_range(-0.6, 0.6)


# --- Bau -------------------------------------------------------------------------------------------------------

## Lack der Türen (in Modellkoordinaten), Türfront mit den Schlitzen (UV2), Zink des Korpus (in Weltkoordinaten)
static func _materials() -> void:
	if _paint_mat != null:
		return
	_paint_mat = Mat.photo(PAINT_TEX + ".png", PAINT_METERS, PAINT_TEX + "_normal.png", PAINT_TEX + "_rough.png",
		PAINT_SPECULAR, PAINT_TINT, true)
	_front_mat = _paint_mat.duplicate()
	_front_mat.set_shader_parameter("ao_tex", _mipmapped(LOUVRE_TEX + "_ao.png", false))
	_front_mat.set_shader_parameter("use_ao", true)
	_front_mat.set_shader_parameter("detail_tex", _mipmapped(LOUVRE_TEX + "_d.png", true))
	_front_mat.set_shader_parameter("use_detail", true)
	_galv_mat = Mat.photo(GALV_TEX + ".png", GALV_METERS, GALV_TEX + "_normal.png", GALV_TEX + "_rough.png",
		GALV_SPECULAR, GALV_TINT)
	_galv_mat.set_shader_parameter("metallic", GALV_METALLIC)


static func _mipmapped(path: String, normal: bool) -> ImageTexture:
	var img := (load(path) as Texture2D).get_image()
	img.decompress()
	img.generate_mipmaps(normal)
	return ImageTexture.create_from_image(img)


## Türfläche ohne Luft
static func door_size() -> Vector2:
	return Vector2(MODULE - 2.0 * (FRAME_SIDE + DOOR_GAP), HEIGHT - FRAME_TOP - FRAME_BOTTOM - 2.0 * DOOR_GAP)


## Korpus als ein Mesh (Zink) mit Kollision je Blech: Seiten- und Zwischenwände, Rückwand, Boden, Decke, Hutablagen,
## Rahmen vorn (Seiten, oben, Sockelblende). Türen je ein eigener Körper, der sich um sein Scharnier dreht.
func _build() -> void:
	_materials()
	var p := LockerBank.Parts.new()
	var h := length() / 2.0
	var back_z := -DEPTH / 2.0
	var front_z := DEPTH / 2.0
	var inner_d := DEPTH - FRAME_D
	var mid_z := back_z + DEPTH / 2.0
	# Seiten und Zwischenwände
	for i in count + 1:
		var x := -h + i * MODULE
		x += SHEET / 2.0 if i == 0 else (-SHEET / 2.0 if i == count else 0.0)
		_sheet(p, Vector3(SHEET, HEIGHT, DEPTH), Vector3(x, HEIGHT / 2.0, mid_z))
	# Rückwand, Decke, Boden (auf Höhe der Sockelblende), Hutablagen
	var run := length()
	_sheet(p, Vector3(run, HEIGHT, SHEET), Vector3(0, HEIGHT / 2.0, back_z + SHEET / 2.0))
	_sheet(p, Vector3(run, SHEET, DEPTH), Vector3(0, HEIGHT - SHEET / 2.0, mid_z))
	_sheet(p, Vector3(run, SHEET, inner_d), Vector3(0, FRAME_BOTTOM - SHEET / 2.0, back_z + inner_d / 2.0))
	for i in count:
		var cx := -h + (i + 0.5) * MODULE
		var w := MODULE - 2.0 * SHEET
		var shelf_d := inner_d - 0.04   # vorn Luft für die Tür
		_sheet(p, Vector3(w, SHEET, shelf_d), Vector3(cx, SHELF_Y - SHEET / 2.0, back_z + SHEET + shelf_d / 2.0))
		p.box(_galv_mat, Vector3(w, SHELF_LIP, SHEET), Vector3(cx, SHELF_Y - SHELF_LIP / 2.0, back_z + SHEET + shelf_d))
	# Rahmen vorn: je Spind die Seiten (an Zwischenwänden zusammen doppelt breit), oben, Sockelblende bis zum Boden
	var frame_z := front_z - FRAME_D / 2.0
	for i in count + 1:
		var w := FRAME_SIDE * (1.0 if i == 0 or i == count else 2.0) + (SHEET if i == 0 or i == count else 0.0)
		var x := -h + i * MODULE + (w / 2.0 if i == 0 else (-w / 2.0 if i == count else 0.0))
		_frame(p, Vector3(w, HEIGHT, FRAME_D), Vector3(x, HEIGHT / 2.0, frame_z))
	_frame(p, Vector3(run, FRAME_TOP, FRAME_D), Vector3(0, HEIGHT - FRAME_TOP / 2.0, frame_z))
	_frame(p, Vector3(run, FRAME_BOTTOM, FRAME_D), Vector3(0, FRAME_BOTTOM / 2.0, frame_z))
	Geo.mesh(self, p.commit(), null, Vector3.ZERO)
	if locked:
		_lock_ui = CodeLockUI.new()
		_lock_ui.name = "Zahlenschloss"
		add_child(_lock_ui)
	# Türen
	var rng := RandomNumberGenerator.new()
	rng.seed = SEED
	var size := door_size()
	var hinge_z := front_z - DOOR_INSET
	for i in count:
		var door := StaticBody3D.new()
		door.collision_mask = 0
		door.position = Vector3(-h + i * MODULE + FRAME_SIDE + DOOR_GAP, FRAME_BOTTOM + DOOR_GAP, hinge_z)
		door.set_meta("interactable", Handle.new(self, i))
		add_child(door)
		Geo.add_box_shape(door, Vector3(size.x, size.y, DOOR_T), Vector3(size.x / 2.0, size.y / 2.0, -DOOR_T / 2.0))
		# Lack je Tür woanders aus der Kachel: das Mesh liegt verschoben, die Instanz zurück
		var shift := Vector3(rng.randf() * PAINT_METERS, rng.randf() * PAINT_METERS, 0)
		var m := Geo.mesh(door, _door_mesh(size, shift), null, -shift)
		m.name = "Door"
		_hardware(door, size)
		_padlocks.append(_padlock(door, size) if locked else null)
		_doors.append(door)
		is_open.append(false)
		unlocked.append(false)
		searched.append(false)


## Blech als Mesh und Kollisionskasten
func _sheet(p: LockerBank.Parts, size: Vector3, center: Vector3) -> void:
	p.box(_galv_mat, size, center)
	Geo.add_box_shape(self, size, center)


## Rahmenstück: Kasten mit etwas gerundeten Kanten (gekantetes Blech), Kollision
func _frame(p: LockerBank.Parts, size: Vector3, center: Vector3) -> void:
	p.mesh(_galv_mat, Geo.rounded_box(size, 0.0015, 1), 0, Transform3D(Basis(), center))
	Geo.add_box_shape(self, size, center)


## Tür (Ursprung unten links an der Vorderfläche = Scharnier, Dicke nach −Z), um shift verschoben: gekanteter Kasten
## im Lack, davor die Front mit UV2 über die ganze Fläche (Schlitze)
static func _door_mesh(size: Vector2, shift: Vector3) -> ArrayMesh:
	var p := LockerBank.Parts.new()
	p.mesh(_paint_mat, Geo.rounded_box(Vector3(size.x, size.y, DOOR_T), DOOR_ROUND, 2), 0,
		Transform3D(Basis(), shift + Vector3(size.x / 2.0, size.y / 2.0, -DOOR_T / 2.0)))
	var m := p.commit()
	# Front: ein Viereck knapp vor der flachen Fläche (die Rundung bleibt frei), UV2 0 … 1 von oben links
	var r := DOOR_ROUND
	var z := 0.0002
	var verts := PackedVector3Array([Vector3(r, size.y - r, z), Vector3(size.x - r, size.y - r, z),
		Vector3(size.x - r, r, z), Vector3(r, r, z)])
	var uv2 := PackedVector2Array()
	for v in verts:
		uv2.append(Vector2(v.x / size.x, 1.0 - v.y / size.y))
	for i in verts.size():
		verts[i] += shift
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = PackedVector3Array([Vector3.BACK, Vector3.BACK, Vector3.BACK, Vector3.BACK])
	arrays[Mesh.ARRAY_TEX_UV2] = uv2
	arrays[Mesh.ARRAY_INDEX] = PackedInt32Array([0, 1, 2, 0, 2, 3])
	m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	m.surface_set_material(m.get_surface_count() - 1, _front_mat)
	return m


## Beschlag: Rosette rechts an der Tür, davor die Öse für das Vorhängeschloss
static func _hardware(door: Node3D, size: Vector2) -> void:
	var at := Vector3(size.x - HASP_AT.x, HASP_AT.y - FRAME_BOTTOM - DOOR_GAP, 0)
	var turn := Basis(Vector3.RIGHT, PI / 2.0)   # Zylinder zeigt nach vorn
	var p := LockerBank.Parts.new()
	p.mesh(Mat.metal(), Geo.cylinder(ROSETTE.x, ROSETTE.y, 20), 0, Transform3D(turn, at + Vector3(0, 0, ROSETTE.y / 2.0)))
	p.mesh(Mat.metal(), Geo.rounded_box(STAPLE, 0.0015, 1), 0,
		Transform3D(Basis(), at + Vector3(0, 0, ROSETTE.y + STAPLE.z / 2.0)))
	Geo.mesh(door, p.commit(), null, Vector3.ZERO)


## Zahlenschloss an der Öse: Bügel über die Öse, rundes Gehäuse, Zahlenscheibe und Knopf nach vorn (Bild 3)
static func _padlock(door: Node3D, size: Vector2) -> Node3D:
	var lock := Node3D.new()
	lock.name = "Padlock"
	lock.position = Vector3(size.x - HASP_AT.x, HASP_AT.y - FRAME_BOTTOM - DOOR_GAP, ROSETTE.y + STAPLE.z * 0.55)
	door.add_child(lock)
	var p := LockerBank.Parts.new()
	var wire := SHACKLE.x
	var half := SHACKLE.y
	var arc_y := STAPLE.y / 2.0 + wire + 0.001 - half   # der Bogen liegt oben auf der Öse
	const SEGMENTS := 9
	for k in SEGMENTS:   # Bogen aus kurzen Stücken
		var a0 := PI * k / SEGMENTS
		var a1 := PI * (k + 1) / SEGMENTS
		var p0 := Vector3(cos(a0) * half, arc_y + sin(a0) * half, 0)
		var p1 := Vector3(cos(a1) * half, arc_y + sin(a1) * half, 0)
		var dir := (p1 - p0)
		var b := Basis(dir.normalized().cross(Vector3.BACK), dir.normalized(), Vector3.BACK)
		p.mesh(Mat.metal(), Geo.cylinder(wire, dir.length() + wire, 8), 0, Transform3D(b, (p0 + p1) / 2.0))
	var leg := SHACKLE.z
	for side: float in [-1.0, 1.0]:
		p.mesh(Mat.metal(), Geo.cylinder(wire, leg, 8), 0, Transform3D(Basis(), Vector3(side * half, arc_y - leg / 2.0, 0)))
	var body_y := arc_y - leg - PADLOCK.x + 0.006
	var turn := Basis(Vector3.RIGHT, PI / 2.0)
	p.mesh(Mat.metal(), Geo.cylinder(PADLOCK.x, PADLOCK.y, 24), 0, Transform3D(turn, Vector3(0, body_y, 0)))
	p.mesh(Mat.metal(DIAL_TINT), Geo.cylinder(DIAL.x, DIAL.y, 24), 0,
		Transform3D(turn, Vector3(0, body_y, PADLOCK.y / 2.0 + DIAL.y / 2.0)))
	p.mesh(Mat.metal(), Geo.cylinder(KNOB.x, KNOB.y, 16), 0,
		Transform3D(turn, Vector3(0, body_y, PADLOCK.y / 2.0 + DIAL.y + KNOB.y / 2.0)))
	Geo.mesh(lock, p.commit(), null, Vector3.ZERO)
	return lock
