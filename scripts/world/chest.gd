class_name Chest
extends StaticBody3D
## Truhe – ein physischer Behälter. Gegenstände liegen sichtbar darin (kein Inventar).
## Lokale +Z = Vorderseite, Scharnier hinten oben.

const SIZE := Vector3(0.9, 0.5, 0.55)
const WALL := 0.05

var is_open := false

var _lid_pivot: Node3D
var _lid_shape: CollisionShape3D


func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	set_meta("interactable", self)
	add_to_group("chests")
	var wood := Mat.psx(Color(0.4, 0.24, 0.12))
	var band := Mat.psx(Color(0.22, 0.2, 0.18))
	_part(Vector3(SIZE.x, WALL, SIZE.z), Vector3(0, WALL / 2.0, 0), wood)
	_part(Vector3(SIZE.x, SIZE.y, WALL), Vector3(0, SIZE.y / 2.0, SIZE.z / 2.0 - WALL / 2.0), wood)
	_part(Vector3(SIZE.x, SIZE.y, WALL), Vector3(0, SIZE.y / 2.0, -SIZE.z / 2.0 + WALL / 2.0), wood)
	_part(Vector3(WALL, SIZE.y, SIZE.z), Vector3(SIZE.x / 2.0 - WALL / 2.0, SIZE.y / 2.0, 0), wood)
	_part(Vector3(WALL, SIZE.y, SIZE.z), Vector3(-SIZE.x / 2.0 + WALL / 2.0, SIZE.y / 2.0, 0), wood)
	_lid_pivot = Node3D.new()
	_lid_pivot.position = Vector3(0, SIZE.y, -SIZE.z / 2.0)
	add_child(_lid_pivot)
	Geo.mesh(_lid_pivot, Geo.box(Vector3(SIZE.x + 0.02, 0.06, SIZE.z + 0.02)), wood, Vector3(0, 0.03, SIZE.z / 2.0))
	for x in [-0.3, 0.3]:
		Geo.mesh(_lid_pivot, Geo.box(Vector3(0.07, 0.07, SIZE.z + 0.03)), band, Vector3(x, 0.03, SIZE.z / 2.0))
	_lid_shape = Geo.add_box_shape(self, Vector3(SIZE.x, 0.06, SIZE.z), Vector3(0, SIZE.y + 0.03, 0))


func get_prompt(player: Player) -> String:
	if player.hands_blocked():
		return "Hände voll"
	return "Truhe schließen [E]" if is_open else "Truhe öffnen [E]"


func interact(player: Player) -> void:
	if player.hands_blocked():
		Game.say("Mit vollen Händen geht das nicht.")
		return
	set_open(not is_open)


func set_open(open: bool, instant: bool = false) -> void:
	is_open = open
	_lid_shape.set_deferred("disabled", is_open)
	var target := deg_to_rad(-105.0) if is_open else 0.0
	if instant:
		_lid_pivot.rotation.x = target
		return
	create_tween().tween_property(_lid_pivot, "rotation:x", target, 0.4).set_trans(Tween.TRANS_SINE)
	Game.noise("chest", global_position)


func _part(size: Vector3, pos: Vector3, mat: Material) -> void:
	Geo.mesh(self, Geo.box(size), mat, pos)
	Geo.add_box_shape(self, size, pos)
