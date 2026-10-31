class_name PoolShower
extends Node3D
## Duschplatz am Pool (Spielkonzept 7.13, ZIM-144): an der Wand ein Drücker mit runder Wandmanschette, rechts daneben
## eine Ablage, darüber der Duschkopf an einem Wandarm. Alles gebürsteter Edelstahl wie die Badarmaturen (Mat.metal),
## die Düsen sind die Textur der Zimmerdusche. Ursprung auf dem Boden an der Wandfläche, lokale +Z in den Raum, +X ist
## von vorn gesehen rechts. Nur Ausstattung – zu hoch bzw. zu flach, um daran hängen zu bleiben, darum ohne Kollision.

const NOZZLES := "res://assets/models/shower_shower_nozzles.png"

## Drücker: Mitte auf 1 m, Manschette 14 cm Durchmesser, schaut 8 cm aus der Wand
const BUTTON_Y := 1.0
## Ablage rechts neben dem Drücker, Mitte auf Drückerhöhe: 24 × 11 cm, Rand 3 cm hoch
const SHELF_SIZE := Vector3(0.24, 0.03, 0.11)
const SHELF_GAP := 0.05   ## Abstand Manschette – Ablage
const SHELF_EDGE := 0.008   ## Stärke des Rands
## Duschkopf: Mitte 40 cm vor der Wand, Unterkante auf 2,10 m, 25 cm Durchmesser; Wandarm Ø 22 mm
const HEAD_REACH := 0.4
const HEAD_Y := 2.1
const HEAD_R := 0.125
const ARM_Y := 2.26
const ARM_R := 0.011
const ARM_BEND := 0.06   ## Radius des Bogens nach unten
const JOINT_R := 0.016   ## Kugelgelenk über dem Kopf

## Querschnitte als Drehkörper (Radius, Abstand) – beim Drücker von der Wand aus, beim Kopf von der Unterseite aus
const BUTTON_PROFILE := [Vector2(0.07, 0.0), Vector2(0.07, 0.003), Vector2(0.066, 0.01), Vector2(0.062, 0.012),
	Vector2(0.034, 0.012), Vector2(0.033, 0.013), Vector2(0.033, 0.044), Vector2(0.031, 0.046), Vector2(0.028, 0.046),
	Vector2(0.028, 0.054), Vector2(0.029, 0.055), Vector2(0.029, 0.066), Vector2(0.027, 0.072), Vector2(0.022, 0.0765),
	Vector2(0.013, 0.0793), Vector2(0.0, 0.08)]
const RUBBER_PROFILE := [Vector2(0.03, 0.046), Vector2(0.0305, 0.047), Vector2(0.0305, 0.053), Vector2(0.029, 0.0545)]
const ROSETTE_PROFILE := [Vector2(0.035, 0.0), Vector2(0.035, 0.006), Vector2(0.031, 0.01), Vector2(0.0, 0.01)]
const HEAD_PROFILE := [Vector2(HEAD_R - 0.006, 0.0), Vector2(HEAD_R, 0.003), Vector2(HEAD_R, 0.009),
	Vector2(HEAD_R - 0.006, 0.013), Vector2(0.04, 0.017), Vector2(0.016, 0.022), Vector2(0.011, 0.03)]

const RUBBER := Color(0.04, 0.04, 0.045)

static var _nozzles: ShaderMaterial
static var _arm: ArrayMesh
static var _plate: ArrayMesh


## Debug --duschen: vor den ersten Duschplatz (von Westen), Blick zur Wand.
static func debug_show(tree: SceneTree) -> void:
	var first: PoolShower = null
	for s: PoolShower in tree.get_nodes_in_group("pool_showers"):
		if first == null or s.global_position.x < first.global_position.x:
			first = s
	if first == null:
		push_warning("--duschen: kein Duschplatz im Plan")
		return
	var out := first.global_basis.z
	TeleportUI.place_player(first.global_position + out * 1.6, -out)


func _ready() -> void:
	var steel := Mat.metal()
	# Drücker mit Manschette und dunklem Dichtring
	var button := Geo.mesh(self, Geo.lathe(BUTTON_PROFILE, 32), steel, Vector3(0, BUTTON_Y, 0))
	button.rotation.x = PI / 2.0   # Drehachse aus der Wand (+Y → +Z)
	var ring := Geo.mesh(self, Geo.lathe(RUBBER_PROFILE, 32), Mat.psx(RUBBER), Vector3(0, BUTTON_Y, 0))
	ring.rotation.x = PI / 2.0
	_shelf(steel, Vector3(0.07 + SHELF_GAP + SHELF_SIZE.x / 2.0, BUTTON_Y - SHELF_SIZE.y / 2.0, 0))
	# Duschkopf: Rosette an der Wand, Arm mit Bogen nach unten, Kugelgelenk, Kopf mit Düsenplatte
	var rosette := Geo.mesh(self, Geo.lathe(ROSETTE_PROFILE, 24), steel, Vector3(0, ARM_Y, 0))
	rosette.rotation.x = PI / 2.0
	Geo.mesh(self, _arm_mesh(), steel, Vector3.ZERO)
	Geo.mesh(self, Geo.sphere(JOINT_R, JOINT_R * 2.0, 16, 8), steel, Vector3(0, HEAD_Y + 0.03 + JOINT_R * 0.6, HEAD_REACH))
	Geo.mesh(self, Geo.lathe(HEAD_PROFILE, 48), steel, Vector3(0, HEAD_Y, HEAD_REACH))
	Geo.mesh(self, _plate_mesh(), _nozzle_material(), Vector3(0, HEAD_Y, HEAD_REACH))


## Ablage (Bild: flache Schale mit Rand), base = Mitte der Unterkante an der Wand: Rückenplatte, Boden etwas über der
## Unterkante, ringsum der Rand. Die Halterung darunter entfällt.
func _shelf(steel: Material, base: Vector3) -> void:
	var s := SHELF_SIZE
	var e := SHELF_EDGE
	var parts := [
		[Vector3(s.x, 0.05, 0.006), Vector3(0, 0.025, 0.003)],   # Rückenplatte, höher als der Rand
		[Vector3(s.x - 2.0 * e, 0.004, s.z - e), Vector3(0, 0.008, (s.z - e) / 2.0)],   # Boden
		[Vector3(s.x, s.y, e), Vector3(0, s.y / 2.0, s.z - e / 2.0)],   # vorn
		[Vector3(e, s.y, s.z), Vector3(-(s.x - e) / 2.0, s.y / 2.0, s.z / 2.0)],
		[Vector3(e, s.y, s.z), Vector3((s.x - e) / 2.0, s.y / 2.0, s.z / 2.0)],
	]
	for p in parts:
		Geo.mesh(self, Geo.rounded_box(p[0], 0.003, 2), steel, base + p[1])


## Wandarm als Rohr: waagerecht aus der Wand, im Bogen nach unten bis über das Kugelgelenk.
static func _arm_mesh() -> ArrayMesh:
	if _arm == null:
		var path: Array[Vector3] = [Vector3(0, ARM_Y, 0.005)]
		for k in 9:
			var t := PI / 2.0 * k / 8.0
			path.append(Vector3(0, ARM_Y - ARM_BEND + ARM_BEND * cos(t), HEAD_REACH - ARM_BEND + ARM_BEND * sin(t)))
		path.append(Vector3(0, HEAD_Y + 0.03 + JOINT_R * 1.2, HEAD_REACH))
		_arm = _tube(path, ARM_R, 16)
	return _arm


## Rohr entlang path in der YZ-Ebene (der Querschnitt dreht um X), offene Enden.
static func _tube(path: Array[Vector3], radius: float, sides: int) -> ArrayMesh:
	var verts := PackedVector3Array()
	var normals := PackedVector3Array()
	var indices := PackedInt32Array()
	for i in path.size():
		var a := path[maxi(i - 1, 0)]
		var b := path[mini(i + 1, path.size() - 1)]
		var v := (b - a).normalized().cross(Vector3.RIGHT)
		for j in sides + 1:
			var phi := TAU * j / sides
			var n := Vector3.RIGHT * cos(phi) + v * sin(phi)
			verts.append(path[i] + n * radius)
			normals.append(n)
	for i in path.size() - 1:
		for j in sides:
			var q := i * (sides + 1) + j
			_tri(indices, verts, normals, q, q + 1, q + sides + 2)
			_tri(indices, verts, normals, q, q + sides + 2, q + sides + 1)
	return Geo.add_surface(ArrayMesh.new(), verts, normals, indices)


## Düsenplatte: Scheibe unter dem Kopf, Normale nach unten; die Textur der Zimmerdusche einmal über den Durchmesser.
static func _plate_mesh() -> ArrayMesh:
	if _plate == null:
		var r := HEAD_R - 0.005
		var sides := 48
		var verts := PackedVector3Array([Vector3(0, -0.0005, 0)])
		var normals := PackedVector3Array([Vector3.DOWN])
		var uvs := PackedVector2Array([Vector2(0.5, 0.5)])
		var indices := PackedInt32Array()
		for j in sides + 1:
			var d := Vector3(cos(TAU * j / sides), 0, sin(TAU * j / sides))
			verts.append(d * r + Vector3(0, -0.0005, 0))
			normals.append(Vector3.DOWN)
			uvs.append(Vector2(0.5 + d.x / 2.0, 0.5 + d.z / 2.0))
		for j in sides:
			_tri(indices, verts, normals, 0, j + 1, j + 2)
		_plate = Geo.add_surface(ArrayMesh.new(), verts, normals, indices, uvs)
	return _plate


## Dreieck a, b, c mit der Vorderseite in Richtung der Normalen (Godot: im Uhrzeigersinn von vorn).
static func _tri(indices: PackedInt32Array, verts: PackedVector3Array, normals: PackedVector3Array, a: int, b: int, c: int) -> void:
	var n := normals[a] + normals[b] + normals[c]
	if (verts[b] - verts[a]).cross(verts[c] - verts[a]).dot(n) > 0.0:
		indices.append_array([a, c, b])
	else:
		indices.append_array([a, b, c])


static func _nozzle_material() -> ShaderMaterial:
	if _nozzles == null:
		_nozzles = Mat.psx(Color(0.85, 0.86, 0.88), "", 1.0, Color.BLACK, 0.0, false)
		_nozzles.set_shader_parameter("albedo_tex", load(NOZZLES))
	return _nozzles
