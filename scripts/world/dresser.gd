class_name Dresser
extends StaticBody3D
## Kommode im Flur mit drei Schubladen (Spielkonzept 3.5). Wer eine Schublade zum ersten Mal
## aufzieht, findet manchmal Münzen oder einen Gegenstand darin – oder nur Staub.
## Was in einer Schublade liegt, fährt mit ihr auf und zu. Lokale +Z = Vorderseite.

const SIZE := Vector3(0.9, 0.85, 0.45)
const DRAWERS := 3
const PLINTH := 0.08
const TOP := 0.03
const PITCH := (SIZE.y - PLINTH - TOP) / DRAWERS
const SLIDE := 0.3
## Innenmaß einer Schublade (Boden bis Oberkante der Seitenwände)
const TRAY := Vector3(SIZE.x - 0.12, 0.15, SIZE.z - 0.07)
## Fund beim ersten Öffnen: Wahrscheinlichkeit für leer / Münzen, sonst ein Gegenstand
const EMPTY_CHANCE := 0.4
const COINS_CHANCE := 0.3
const LOOT := [Item.Kind.CANDLE, Item.Kind.BULB, Item.Kind.BATTERY, Item.Kind.BATTERY, Item.Kind.KNIFE, Item.Kind.LOADED_DICE]
const EMPTY_LINES := ["Nur Staub.", "Ein alter Knopf, sonst nichts.", "Leer – bis auf eine tote Motte.", "Vergilbtes Briefpapier. Leer."]

var is_open: Array[bool] = []
var searched: Array[bool] = []

var _drawers: Array[StaticBody3D] = []


## Griff einer Schublade: das, worauf der Spieler zielt (interagierbar), leitet an die Kommode weiter.
class Handle:
	var dresser: Dresser
	var index := 0

	func _init(p_dresser: Dresser, p_index: int) -> void:
		dresser = p_dresser
		index = p_index

	func get_prompt(player: Player) -> String:
		return dresser.drawer_prompt(index, player)

	func interact(player: Player) -> void:
		dresser.use_drawer(index, player)


func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	add_to_group("dressers")
	var wood := Mat.psx(Color(0.3, 0.17, 0.09))
	var front := Mat.psx(Color(0.38, 0.22, 0.12))
	var brass := Mat.psx(Color(0.62, 0.48, 0.22))
	# Hohler Korpus – sonst drückt die Physik die Gegenstände aus geschlossenen Schubladen heraus
	_part(self, Vector3(SIZE.x, PLINTH, SIZE.z), Vector3(0, PLINTH / 2.0, 0), wood)
	_part(self, Vector3(SIZE.x + 0.04, TOP, SIZE.z + 0.03), Vector3(0, SIZE.y - TOP / 2.0, 0.005), wood)
	_part(self, Vector3(SIZE.x, SIZE.y, 0.02), Vector3(0, SIZE.y / 2.0, -SIZE.z / 2.0 + 0.01), wood)
	for side in [-1.0, 1.0]:
		_part(self, Vector3(0.03, SIZE.y, SIZE.z), Vector3(side * (SIZE.x / 2.0 - 0.015), SIZE.y / 2.0, 0), wood)
	for i in DRAWERS:
		var drawer := StaticBody3D.new()
		drawer.collision_layer = 1
		drawer.collision_mask = 0
		drawer.position = Vector3(0, PLINTH + PITCH * i + 0.01, 0)
		drawer.set_meta("interactable", Handle.new(self, i))
		add_child(drawer)
		var z_front := SIZE.z / 2.0 - 0.0125
		_part(drawer, Vector3(SIZE.x - 0.08, PITCH - 0.02, 0.025), Vector3(0, (PITCH - 0.02) / 2.0, z_front), front)
		Geo.mesh(drawer, Geo.box(Vector3(0.1, 0.025, 0.03)), brass, Vector3(0, (PITCH - 0.02) / 2.0, z_front + 0.02))
		var tray_z := z_front - 0.0125 - TRAY.z / 2.0
		_part(drawer, Vector3(TRAY.x, 0.015, TRAY.z), Vector3(0, 0.0075, tray_z), wood)
		_part(drawer, Vector3(TRAY.x, TRAY.y, 0.015), Vector3(0, TRAY.y / 2.0, tray_z - TRAY.z / 2.0), wood)
		for side in [-1.0, 1.0]:
			_part(drawer, Vector3(0.015, TRAY.y, TRAY.z), Vector3(side * TRAY.x / 2.0, TRAY.y / 2.0, tray_z), wood)
		_drawers.append(drawer)
		is_open.append(false)
		searched.append(false)


func drawer_prompt(i: int, player: Player) -> String:
	if player.hands_blocked():
		return "Hände voll"
	return "Schublade schließen [E]" if is_open[i] else "Schublade aufziehen [E]"


func use_drawer(i: int, player: Player) -> void:
	if player.hands_blocked():
		Game.say("Mit vollen Händen geht das nicht.")
		return
	set_open(i, not is_open[i])
	if is_open[i] and not searched[i]:
		searched[i] = true
		await get_tree().create_timer(0.3, false).timeout   # erst ganz aufgezogen, dann hineinlegen
		if not is_open[i]:
			searched[i] = false   # gleich wieder zugeschoben – beim nächsten Mal
			return
		_roll_loot(i)


func set_open(i: int, open: bool, instant: bool = false) -> void:
	if is_open[i] == open:
		return
	is_open[i] = open
	var drawer := _drawers[i]
	var delta := SLIDE if open else -SLIDE
	var target := drawer.position.z + delta
	if instant:
		drawer.position.z = target
		return
	# Was in der Schublade liegt, fährt mit (eingefroren, damit die Physik nicht dagegenhält)
	var riders := _items_in(drawer)
	var offset := global_transform.basis.z * delta
	var tween := create_tween().set_parallel().set_trans(Tween.TRANS_SINE)
	tween.tween_property(drawer, "position:z", target, 0.3)
	for item in riders:
		item.freeze = true
		tween.tween_property(item, "global_position", item.global_position + offset, 0.3)
	tween.chain().tween_callback(func() -> void:
		for item in riders:
			if is_instance_valid(item) and not item.is_held:
				item.freeze = false
				item.sleeping = false)
	Game.noise("drawer", drawer.global_position)


func save_state() -> Dictionary:
	return {"open": is_open.duplicate(), "searched": searched.duplicate()}


func load_state(d: Dictionary) -> void:
	var open: Array = d.get("open", [])
	var done: Array = d.get("searched", [])
	for i in mini(DRAWERS, open.size()):
		set_open(i, bool(open[i]), true)
	for i in mini(DRAWERS, done.size()):
		searched[i] = bool(done[i])


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
		if item.lit:
			item._extinguish()   # eine Kerze liegt aus, nicht brennend in der Schublade
	Game.social.builder.world.add_child(item)
	# Mitte der aufgezogenen Schublade, knapp über dem Boden – fällt hinein
	var drawer := _drawers[i]
	var tray_center := Vector3(0, 0.03, SIZE.z / 2.0 - 0.025 - TRAY.z / 2.0 + SLIDE)
	item.global_position = global_transform * (Vector3(0, drawer.position.y, 0) + tray_center)
	item.rotation.y = rotation.y + randf_range(-0.6, 0.6)


func _items_in(drawer: StaticBody3D) -> Array[Item]:
	var found: Array[Item] = []
	for node in get_tree().get_nodes_in_group("items"):
		var item := node as Item
		if item.is_held:
			continue
		var p := drawer.global_transform.affine_inverse() * item.global_position
		if absf(p.x) < TRAY.x / 2.0 and p.y > -0.02 and p.y < TRAY.y + 0.1 \
				and p.z < SIZE.z / 2.0 and p.z > SIZE.z / 2.0 - 0.025 - TRAY.z:
			found.append(item)
	return found


func _part(body: Node3D, size: Vector3, pos: Vector3, mat: Material) -> void:
	Geo.mesh(body, Geo.box(size), mat, pos)
	Geo.add_box_shape(body as CollisionObject3D, size, pos)
