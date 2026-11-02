class_name Chair
extends StaticBody3D
## Stuhl des Speisesaals (ZIM-156, Skizze des Nutzers 2.11.), Planfarbe „Möbel: Stuhl“: so schlicht wie möglich
## (286 Dreiecke), im Holz der Vertäfelung wie Kommode und Tafel, alle Hölzer kantig. Vier gerade Beine, eine gerade
## Zarge, die hinteren Beine laufen über dem Sitz gerade schräg nach hinten weiter; Kopfbrett mit gerader Oberkante und
## Querleiste, beide in der Mitte nach hinten gewölbt. Darauf ein rechteckiges Sitzkissen bis vor die Lehne, oben zu
## den Kanten gerundet, unten flach. Modell und Verschattung aus tools/build_chair.py, Holz mit Mat.hotel_wood, Stoff
## Fabric_Pattern_08 getönt (wie die Bettwäsche, BedModel). Ursprung mittig auf dem Boden, Sitzseite nach +Z. Ein
## Sitzplatz (Seat, Art „stuhl“, Spielkonzept 3.1). Maße = Bauskript.

const MODEL := "res://assets/models/chair.glb"
const AO := "res://assets/textures/chair_ao.png"
const FABRIC_TEX := "res://assets/textures/Fabric_Pattern_08/Fabric_Pattern_08_basecolor.jpg"
const FABRIC_NORMAL := "res://assets/textures/Fabric_Pattern_08/Fabric_Pattern_08_normalogl.jpg"
const FABRIC_METERS := 0.25
## Polsterstoff: altes Weinrot
const FABRIC_COLOR := Color(0.72, 0.17, 0.19)
## Breite, Höhe (Oberkante Pfosten), Tiefe am Sitz (Vorderkante Vorderbein bis Hinterkante Hinterbein)
const SIZE := Vector3(0.46, 0.95, 0.47)
## Oberkante des Kissens; Unterseite des Kissens (Zarge)
const SEAT_H := 0.46
const FRAME := 0.42
## Lehne: Vorderseite der Pfosten am Sitz, oben so weit nach hinten (Schräge und Wölbung der Querstücke)
const BACK_FRONT_Z := -0.195
const BACK_REAR_Z := -0.314

static var _meshes := {}
static var _materials := {}


func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	add_to_group("chairs")
	var meshes := _model()
	for part: String in ["frame", "cushion"]:
		var mi := MeshInstance3D.new()
		mi.mesh = meshes[part]
		mi.material_override = _material(part)
		add_child(mi)
	Geo.add_box_shape(self, Vector3(SIZE.x, SEAT_H, SIZE.z), Vector3(0, SEAT_H / 2.0, 0))
	var back_d := BACK_FRONT_Z - BACK_REAR_Z
	Geo.add_box_shape(self, Vector3(SIZE.x, SIZE.y - SEAT_H, back_d),
		Vector3(0, (SIZE.y + SEAT_H) / 2.0, (BACK_FRONT_Z + BACK_REAR_Z) / 2.0))
	Seat.attach(self, "stuhl", SEAT_H, Vector3(0, 0, 0.02), Vector3.BACK, SIZE.x, SIZE.z / 2.0 + 0.3)


## Teile des Modells: Name → Mesh
static func _model() -> Dictionary:
	if _meshes.is_empty():
		var scene: Node = (load(MODEL) as PackedScene).instantiate()
		for mi: MeshInstance3D in scene.find_children("*", "MeshInstance3D", true, false):
			_meshes[String(mi.name)] = mi.mesh
		scene.free()
	return _meshes


## Holz bzw. Stoff, beide mit der gebackenen Verschattung über UV2
static func _material(part: String) -> Material:
	if not _materials.has(part):
		if part == "frame":
			_materials[part] = Mat.hotel_wood(AO)
		else:
			var m := Mat.photo(FABRIC_TEX, FABRIC_METERS, FABRIC_NORMAL, "", 0.0, FABRIC_COLOR, false, true).duplicate() as ShaderMaterial
			m.set_shader_parameter("ao_tex", load(AO))
			m.set_shader_parameter("use_ao", true)
			_materials[part] = m
	return _materials[part]
