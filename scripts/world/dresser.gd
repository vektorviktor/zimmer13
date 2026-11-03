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
## Streichholzschachtel in Zimmer 022, Spielkonzept 5.12); 0 = oberste (_top_index)
var fixed := {}
## false: nur feste Funde, sonst leer (Schreibtisch, ZIM-154); Sprüche für eine leere Schublade
var loot := true
var empty_lines: Array = EMPTY_LINES
## Außenmaß, Innenmaß einer Schublade, Auszug – die Kommode nimmt SIZE, TRAY und SLIDE; add_drawer kann je
## Schublade andere setzen
var size := SIZE
var tray := TRAY
var slide := SLIDE
var is_open: Array[bool] = []
var searched: Array[bool] = []

var _drawers: Array[StaticBody3D] = []
var _trays: Array[Vector3] = []
var _slides: Array[float] = []
var _tray_fronts: Array[float] = []   # z der Vorderkante des Kastens (Rückseite der Front)


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


## Neue Schublade, Unterkante auf Höhe y, Mitte bei x (Kommode: von unten nach oben anlegen): ein leerer Körper mit
## Griff, die Teile setzt der Aufrufer. Ohne weitere Angaben liegt die Front bündig mit der Vorderseite, 0,025 m
## stark, der Kasten (tray) dahinter; sonst Innenmaß p_tray, Auszug p_slide und Vorderkante des Kastens tray_front.
func add_drawer(y: float, x: float = 0.0, p_tray: Vector3 = Vector3.ZERO, p_slide: float = 0.0,
		tray_front: float = NAN) -> StaticBody3D:
	var drawer := StaticBody3D.new()
	drawer.collision_layer = 1
	drawer.collision_mask = 0
	drawer.position = Vector3(x, y, 0)
	drawer.set_meta("interactable", Handle.new(self, _drawers.size()))
	add_child(drawer)
	_drawers.append(drawer)
	_trays.append(p_tray if p_tray != Vector3.ZERO else tray)
	_slides.append(p_slide if p_slide > 0.0 else slide)
	_tray_fronts.append(size.z / 2.0 - 0.025 if is_nan(tray_front) else tray_front)
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
	var delta := _slides[i] if open else -_slides[i]
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


## Index von oben gezählt – die Kommode legt ihre Schubladen von unten an
func _top_index(i: int) -> int:
	return _drawers.size() - 1 - i


func _roll_loot(i: int) -> void:
	var item := _roll(i)
	if item == null:
		Game.say(empty_lines[randi() % empty_lines.size()], 2.0)
		return
	_drop_in(i, item)


## Fund beim ersten Öffnen der Schublade i (fest oder gewürfelt) – null = leer.
func _roll(i: int) -> Item:
	var drawer_index := _top_index(i)
	if fixed.has(drawer_index):
		return Item.create(fixed[drawer_index] as Item.Kind)
	var roll := randf()
	if not loot or roll < EMPTY_CHANCE:
		return null
	if roll < EMPTY_CHANCE + COINS_CHANCE:
		return Item.create(Item.Kind.COINS, str(randi_range(1, 4)))
	return Item.create(LOOT[randi() % LOOT.size()] as Item.Kind)


# --- Gäste (Spielkonzept 3.5, Entscheidung 2026-11-03, ZIM-39) ----------------------------

## Durchsuchen Gäste diese Kommode? Nur Kommoden mit Zufallsfund – nicht die mit festem Fund (Streichhölzer in
## Zimmer 022), keine Nachttische und Schreibtische.
func guests_search() -> bool:
	return loot and fixed.is_empty() and not self is Nightstand


## Was ein Gast aus einer Schublade mitnimmt: Deko und Münzen – nie, was dem Spieler gehört (sein Versteck, 3.2), und
## nicht, was er selbst darin versteckt hat (stash).
static func guest_takes(item: Item, g: Guest) -> bool:
	return not item.is_held and item.owner_id != "player" and item.owner_id != g.id and not item.has_meta("memorial") \
		and (item.deco_strength > 0.0 or item.kind == Item.Kind.COINS)


## Liegt p (Welt) in einem Schubladenfach? Grob über den Korpus, ohne _items_in (für die Suche der Gäste).
func holds_point(p: Vector3) -> bool:
	var l := to_local(p)
	return absf(l.x) < size.x / 2.0 and l.y > PLINTH * 0.5 and l.y < OPEN_TOP and absf(l.z) < size.z / 2.0 + slide


## Ein Gast durchsucht alle Schubladen: zieht sie auf (Lärm wie beim Spieler) und lässt sie offen – eine offene
## Schublade verrät, dass jemand gesucht hat. Zurück kommt, was er mitnimmt (guest_takes), schon aus der Welt genommen:
## was darin lag und der Fund einer noch nie geöffneten Schublade. Was er nicht will (Batterie, Messer …), legt er
## zurück. Es gibt keinen Nachschub (5.10) – die Kommode leert sich.
func search_by_guest(g: Guest) -> Array[Item]:
	var taken: Array[Item] = []
	var back: Array = []   # [Schublade, Gegenstand] – kommt hinein, sobald sie offen ist
	for i in _drawers.size():
		for item in _items_in(_drawers[i]):
			if guest_takes(item, g):
				item.get_parent().remove_child(item)   # vor dem Aufziehen, sonst fährt er mit
				taken.append(item)
		if not searched[i]:
			searched[i] = true
			var found := _roll(i)
			if found and guest_takes(found, g):
				taken.append(found)
			elif found:
				back.append([i, found])
		set_open(i, true)
	_after_open(back)
	return taken


## Ein ängstlicher Gast versteckt ein Stück aus seinem Koffer (item, nicht im Baum): in die Schublade, in der am
## wenigsten liegt – aufziehen, hineinlegen, zuschieben. War sie noch nie offen, liegt ihr Fund mit darin.
func stash(item: Item) -> void:
	var best := 0
	var fewest := 1 << 30
	for i in _drawers.size():
		var n := _items_in(_drawers[i]).size()
		if n < fewest:
			best = i
			fewest = n
	var put: Array = [[best, item]]
	if not searched[best]:
		searched[best] = true
		var found := _roll(best)
		if found:
			put.append([best, found])
	set_open(best, true)
	_after_open(put)
	get_tree().create_timer(1.2, false).timeout.connect(func() -> void: set_open(best, false))


## Gegenstände ([Schublade, Gegenstand]) hineinlegen, wenn die Schubladen ganz aufgezogen sind (wie use_drawer).
func _after_open(put: Array) -> void:
	if put.is_empty():
		return
	get_tree().create_timer(0.35, false).timeout.connect(func() -> void:
		for pair: Array in put:
			set_open(int(pair[0]), true, true)   # hat sie jemand gleich wieder zugeschoben: wieder auf, nichts geht verloren
			_drop_in(int(pair[0]), pair[1]))


## Gegenstand in die aufgezogene Schublade i legen.
func _drop_in(i: int, item: Item) -> void:
	Game.social.builder.world.add_child(item)
	# Mitte der aufgezogenen Schublade, knapp über dem Boden – fällt hinein
	var drawer := _drawers[i]
	var tray_center := Vector3(0, 0.03, _tray_fronts[i] - _trays[i].z / 2.0 + _slides[i])
	item.global_position = global_transform * (Vector3(drawer.position.x, drawer.position.y, 0) + tray_center)
	item.rotation.y = rotation.y + randf_range(-0.6, 0.6)


func _items_in(drawer: StaticBody3D) -> Array[Item]:
	var i := _drawers.find(drawer)
	var t := _trays[i]
	var front := _tray_fronts[i]
	var found: Array[Item] = []
	for node in get_tree().get_nodes_in_group("items"):
		var item := node as Item
		if item.is_held:
			continue
		var p := drawer.global_transform.affine_inverse() * item.global_position
		if absf(p.x) < t.x / 2.0 and p.y > -0.02 and p.y < t.y + 0.1 \
				and p.z < front + 0.025 and p.z > front - t.z:
			found.append(item)
	return found
