class_name GameCabinet
extends StaticBody3D
## Spieleschrank in der Bar (Spielkonzept 6.10, Entscheidung 28.10.): ein hoher Holzschrank mit zwei Flügeltüren und
## drei Fächern. Darin liegen die kleinen Barspiele als normale Gegenstände (Item.Kind.BAR_GAME: Kartenspiel,
## Bierdeckel, Quizkarten, leere Flasche) und ein zweiter Würfelbecher – man holt sie heraus und bringt sie an den Würfeltisch. Gespeichert wie eine
## Truhe (Gruppe chests: offen oder zu), die Spiele wie jeder Gegenstand. Lokale +Z = Vorderseite.

const SIZE := Vector3(1.0, 1.85, 0.45)
const WALL := 0.03
const SHELVES: Array[float] = [0.08, 0.62, 1.16]   ## Oberkante der Böden (unten, Mitte, oben)
## Was anfangs in welchem Fach liegt: [Sorte, Fach, x] – „becher“ ist ein zweiter Würfelbecher für Schocken am
## Barspieltisch (der erste steht auf dem Mäxchen-Tisch)
const CONTENTS := [["karten", 1, -0.25], ["quiz", 1, 0.2], ["deckel", 2, -0.22], ["becher", 2, 0.2], ["flasche", 0, 0.05]]

var is_open := false

var _doors: Array[Node3D] = []
var _door_shapes: Array[CollisionShape3D] = []


func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	set_meta("interactable", self)
	add_to_group("chests")
	var wood := Mat.psx(Color(0.32, 0.18, 0.09))
	var dark := Mat.psx(Color(0.2, 0.11, 0.05))
	var h := SIZE.y
	Geo.box_part(self, Vector3(SIZE.x, h, WALL), Vector3(0, h / 2.0, -SIZE.z / 2.0 + WALL / 2.0), dark)   # Rückwand
	for side in [-1.0, 1.0]:
		Geo.box_part(self, Vector3(WALL, h, SIZE.z), Vector3(side * (SIZE.x / 2.0 - WALL / 2.0), h / 2.0, 0), wood)
	Geo.box_part(self, Vector3(SIZE.x + 0.04, 0.05, SIZE.z + 0.03), Vector3(0, h + 0.025, 0.0), wood)   # Deckplatte
	for y in SHELVES:
		Geo.box_part(self, Vector3(SIZE.x - WALL * 2.0, 0.025, SIZE.z - WALL), Vector3(0, y - 0.0125, WALL / 2.0), wood)
	for side in [-1.0, 1.0]:   # zwei Flügeltüren, Scharnier außen
		var pivot := Node3D.new()
		pivot.position = Vector3(side * SIZE.x / 2.0, 0, SIZE.z / 2.0)
		add_child(pivot)
		var w := SIZE.x / 2.0 - 0.005
		Geo.mesh(pivot, Geo.box(Vector3(w, h - 0.04, 0.025)), wood, Vector3(-side * w / 2.0, h / 2.0, 0.0125))
		Geo.mesh(pivot, Geo.box(Vector3(w - 0.12, h - 0.3, 0.01)), dark, Vector3(-side * w / 2.0, h / 2.0, 0.028))   # Füllung
		Geo.mesh(pivot, Geo.box(Vector3(0.02, 0.1, 0.02)), Mat.metal(Color(0.75, 0.6, 0.3)), Vector3(-side * (w - 0.05), h * 0.55, 0.04))
		_doors.append(pivot)
		_door_shapes.append(Geo.add_box_shape(self, Vector3(w, h - 0.04, 0.025), Vector3(side * (SIZE.x / 4.0), h / 2.0, SIZE.z / 2.0 + 0.0125)))


## Platz für ein Spiel im Fach (Weltkoordinaten, auf dem Boden des Fachs).
func spot(shelf: int, x: float) -> Vector3:
	return global_transform * Vector3(x, SHELVES[shelf] + 0.005, 0.02)


## Liegt der Gegenstand im Schrank (zwischen Rückwand, Seiten, Boden und Deckplatte)?
func holds(item: Item) -> bool:
	var local := global_transform.affine_inverse() * item.global_position
	return absf(local.x) < SIZE.x / 2.0 and absf(local.z) < SIZE.z / 2.0 + 0.03 and local.y > 0.0 and local.y < SIZE.y


func get_prompt(player: Player) -> String:
	if player.hands_blocked():
		return "Hände voll"
	return "Spieleschrank schließen [E]" if is_open else "Spieleschrank öffnen [E]"


func interact(player: Player) -> void:
	if player.hands_blocked():
		Game.say("Mit vollen Händen geht das nicht.")
		return
	set_open(not is_open)


## Wie Chest.set_open – die Türen schwingen nach außen auf.
func set_open(open: bool, instant: bool = false) -> void:
	is_open = open
	for shape in _door_shapes:
		shape.set_deferred("disabled", is_open)
	for i in _doors.size():
		var side := -1.0 if i == 0 else 1.0
		var target := side * deg_to_rad(110.0) if is_open else 0.0
		if instant:
			_doors[i].rotation.y = target
		else:
			create_tween().tween_property(_doors[i], "rotation:y", target, 0.45).set_trans(Tween.TRANS_SINE)
	if not instant:
		Game.noise("chest", global_position)
