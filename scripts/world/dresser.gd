class_name Dresser
extends StaticBody3D
## Kommode im Flur mit drei Schubladen (Spielkonzept 3.5). Wer eine Schublade zum ersten Mal
## aufzieht, findet manchmal Münzen oder einen Gegenstand darin – oder nur Staub.
## Was in einer Schublade liegt, fährt mit ihr auf und zu. Lokale +Z = Vorderseite. Der Nachttisch (Nightstand) baut
## sich in _build() anders und setzt size, tray und slide selbst.

## Modell aus tools/build_dresser.py (Look des Kleiderschranks, ZIM-130; seit 31.10. 1,00 m hoch): Korpus, eine
## Schublade (Front und Kasten) und ihre Knöpfe, dazu gebackene Verschattung und Normale. Maße = Bauskript.
const MODEL := "res://assets/models/dresser.glb"
const AO := "res://assets/textures/dresser_ao.png"
const NORMAL := "res://assets/textures/dresser_normal.png"
## Korpus ohne Sockel und Deckplatte; Höhe = Oberkante der Deckplatte
const SIZE := Vector3(0.9, 1.0, 0.45)
const DRAWERS := 3
## Fächer zwischen Sockel und Rundstab (OPEN im Bauskript)
const PLINTH := 0.10
const OPEN_TOP := 0.86
const PITCH := (OPEN_TOP - PLINTH) / DRAWERS
## Halbe Breite der Fächer (zwischen den Eckpfosten), Breite der Pfosten
const OPEN_X := 0.36
const POST := SIZE.x / 2.0 - OPEN_X
const SLIDE := 0.3
## Innenmaß einer Schublade (Boden bis Oberkante der Seitenwände) – TRAY im Bauskript ohne die 12-mm-Wände
const TRAY := Vector3(0.636, 0.148, 0.368)
## Front der Schublade: Vorderfläche (z), Stärke; Kasten außen und Lage seines Bodens (wie im Bauskript)
const FRONT_Z := SIZE.z / 2.0 - 0.008
const FRONT_T := 0.02
const TRAY_OUT := Vector3(0.66, 0.16, 0.38)
const TRAY_LIFT := 0.012
const WALL := 0.012

static var _parts := {}   # Teile des Modells (_model)
## Fund beim ersten Öffnen: Wahrscheinlichkeit für leer / Münzen, sonst ein Gegenstand
const EMPTY_CHANCE := 0.4
const COINS_CHANCE := 0.3
const LOOT := [Item.Kind.CANDLE, Item.Kind.BULB, Item.Kind.BATTERY, Item.Kind.BATTERY, Item.Kind.KNIFE, Item.Kind.LOADED_DICE,
	Item.Kind.SWEETS, Item.Kind.SWEETS, Item.Kind.LIGHT_STRING, Item.Kind.SPIDER, Item.Kind.BAT_GARLAND]
const EMPTY_LINES := ["Nur Staub.", "Ein alter Knopf, sonst nichts.", "Leer – bis auf eine tote Motte.", "Vergilbtes Briefpapier. Leer."]

## Fester Fund je Schublade (Index → Item.Kind), statt gewürfelt – aus LevelBuilder.CONTENT „drawer“ (die
## Streichholzschachtel in Zimmer 022, Spielkonzept 5.12); 0 = oberste
var fixed := {}
## Außenmaß, Innenmaß einer Schublade, Auszug – die Kommode nimmt SIZE, TRAY und SLIDE
var size := SIZE
var tray := TRAY
var slide := SLIDE
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

	func get_icon(_player: Player) -> String:
		return "drawer"

	func interact(player: Player) -> void:
		dresser.use_drawer(index, player)


func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	add_to_group("dressers")
	_build()


## Korpus und Schubladen (add_drawer) bauen: Meshes aus MODEL, Kollision als Kästen. Hohler Korpus – sonst drückt die
## Physik die Gegenstände aus geschlossenen Schubladen heraus; seitlich in Breite der Pfosten (die Kästen laufen
## innen daran vorbei).
func _build() -> void:
	var parts := _model()
	var wood := Mat.hotel_wood(AO, NORMAL)
	_part(self, parts["carcass"], wood)
	var open_h := OPEN_TOP - PLINTH
	Geo.add_box_shape(self, Vector3(SIZE.x + 0.04, PLINTH, SIZE.z + 0.02), Vector3(0, PLINTH / 2.0, 0.01))
	Geo.add_box_shape(self, Vector3(SIZE.x + 0.076, SIZE.y - OPEN_TOP, SIZE.z + 0.038),
		Vector3(0, (SIZE.y + OPEN_TOP) / 2.0, 0.019))
	Geo.add_box_shape(self, Vector3(SIZE.x, open_h, WALL), Vector3(0, PLINTH + open_h / 2.0, -SIZE.z / 2.0 + WALL / 2.0))
	for side in [-1.0, 1.0]:
		Geo.add_box_shape(self, Vector3(POST, open_h, SIZE.z), Vector3(side * (SIZE.x - POST) / 2.0, PLINTH + open_h / 2.0, 0))
	var back := FRONT_Z - FRONT_T   # Rückseite der Front = Vorderkante des Kastens
	for i in DRAWERS:
		var drawer := add_drawer(PLINTH + PITCH * i)
		_part(drawer, parts["drawer"], wood)
		_part(drawer, parts["pulls"], null)
		Geo.add_box_shape(drawer, Vector3(2.0 * OPEN_X - 0.003, PITCH - 0.003, FRONT_T),
			Vector3(0, PITCH / 2.0, FRONT_Z - FRONT_T / 2.0))
		var zm := back - TRAY_OUT.z / 2.0
		Geo.add_box_shape(drawer, Vector3(TRAY_OUT.x, WALL, TRAY_OUT.z), Vector3(0, TRAY_LIFT + WALL / 2.0, zm))
		Geo.add_box_shape(drawer, Vector3(TRAY_OUT.x, TRAY_OUT.y, WALL),
			Vector3(0, TRAY_LIFT + TRAY_OUT.y / 2.0, back - TRAY_OUT.z + WALL / 2.0))
		for side in [-1.0, 1.0]:
			Geo.add_box_shape(drawer, Vector3(WALL, TRAY_OUT.y, TRAY_OUT.z),
				Vector3(side * (TRAY_OUT.x - WALL) / 2.0, TRAY_LIFT + TRAY_OUT.y / 2.0, zm))



## Teile des Modells: Name → Mesh
static func _model() -> Dictionary:
	if _parts.is_empty():
		var scene: Node = (load(MODEL) as PackedScene).instantiate()
		for mi: MeshInstance3D in scene.find_children("*", "MeshInstance3D", true, false):
			_parts[String(mi.name)] = mi.mesh
		scene.free()
	return _parts


## Teil unter parent im Ursprung (die Schublade liegt schon relativ zu ihrem Fach), mat = null → Material des Meshs
static func _part(parent: Node3D, mesh: Mesh, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	parent.add_child(mi)
	return mi


## Neue Schublade, Unterkante auf Höhe y (von unten nach oben anlegen): ein leerer Körper mit Griff, die Teile setzt
## der Aufrufer. Die Front liegt bündig mit der Vorderseite, 0,025 m stark, der Kasten (tray) dahinter.
func add_drawer(y: float) -> StaticBody3D:
	var drawer := StaticBody3D.new()
	drawer.collision_layer = 1
	drawer.collision_mask = 0
	drawer.position = Vector3(0, y, 0)
	drawer.set_meta("interactable", Handle.new(self, _drawers.size()))
	add_child(drawer)
	_drawers.append(drawer)
	is_open.append(false)
	searched.append(false)
	return drawer


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
	if is_open[i] and Game.spiders:   # manchmal springt eine Spinne heraus (Spielkonzept 4.23)
		Game.spiders.on_drawer_opened(_drawers[i].global_position)


func set_open(i: int, open: bool, instant: bool = false) -> void:
	if is_open[i] == open:
		return
	is_open[i] = open
	var drawer := _drawers[i]
	var delta := slide if open else -slide
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
	for i in mini(_drawers.size(), open.size()):
		set_open(i, bool(open[i]), true)
	for i in mini(_drawers.size(), done.size()):
		searched[i] = bool(done[i])


func _roll_loot(i: int) -> void:
	var drawer_index := _drawers.size() - 1 - i   # gezählt von oben
	if fixed.has(drawer_index):
		_drop_in(i, Item.create(fixed[drawer_index] as Item.Kind))
		return
	var roll := randf()
	if roll < EMPTY_CHANCE:
		Game.say(EMPTY_LINES[randi() % EMPTY_LINES.size()], 2.0)
		return
	var item: Item
	if roll < EMPTY_CHANCE + COINS_CHANCE:
		item = Item.create(Item.Kind.COINS, str(randi_range(1, 4)))
	else:
		item = Item.create(LOOT[randi() % LOOT.size()] as Item.Kind)
	_drop_in(i, item)


## Gegenstand in die aufgezogene Schublade i legen.
func _drop_in(i: int, item: Item) -> void:
	Game.social.builder.world.add_child(item)
	# Mitte der aufgezogenen Schublade, knapp über dem Boden – fällt hinein
	var drawer := _drawers[i]
	var tray_center := Vector3(0, 0.03, size.z / 2.0 - 0.025 - tray.z / 2.0 + slide)
	item.global_position = global_transform * (Vector3(0, drawer.position.y, 0) + tray_center)
	item.rotation.y = rotation.y + randf_range(-0.6, 0.6)


func _items_in(drawer: StaticBody3D) -> Array[Item]:
	var found: Array[Item] = []
	for node in get_tree().get_nodes_in_group("items"):
		var item := node as Item
		if item.is_held:
			continue
		var p := drawer.global_transform.affine_inverse() * item.global_position
		if absf(p.x) < tray.x / 2.0 and p.y > -0.02 and p.y < tray.y + 0.1 \
				and p.z < size.z / 2.0 and p.z > size.z / 2.0 - 0.025 - tray.z:
			found.append(item)
	return found
