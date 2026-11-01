class_name Armchair
extends StaticBody3D
## Ledersessel am Schreibtisch im Büro der Direktion (ZIM-150): „old_leather_armchair“ von VoGAn (Sketchfab,
## CC-BY 4.0), gebaut von tools/build_armchair.py – das fast schwarze Leder dort rot gefärbt, Holzbeine und
## Messingnieten wie im Original. Material aus dem vollen PBR-Set (Mat.pbr_model, mit Verdeckung). Ursprung mittig
## auf dem Boden, Sitz nach +Z; Größe fest wie im Original. Ein Sitzplatz (Seat, Art „sessel“, Spielkonzept 3.1).

const MODEL := "res://assets/models/armchair.glb"
const TEX := "res://assets/textures/armchair"
## Breite, Höhe, Tiefe – die Lehne neigt sich weit nach hinten
const SIZE := Vector3(0.904, 0.954, 1.104)
## Oberkante des Sitzpolsters; Armlehnen oben und ihr innerer Abstand zur Mitte
const SEAT_H := 0.43
const ARM_H := 0.76
const ARM_INNER := 0.265
## Sitzpolster in der Tiefe (lokal z): von der Lehne bis zur Vorderkante
const SEAT_BACK_Z := -0.10
const SEAT_FRONT_Z := 0.552
## Unterbau bis zur Sitzfläche reicht hinten bis hier (die hinteren Beine stehen schräg)
const BASE_BACK_Z := -0.25


func _ready() -> void:
	collision_mask = 0
	var model: Node3D = (load(MODEL) as PackedScene).instantiate()
	add_child(model)
	var mat := Mat.pbr_model(TEX, 0.0)
	for m: MeshInstance3D in model.find_children("*", "MeshInstance3D", true, false):
		m.material_override = mat
	var base_d := SEAT_FRONT_Z - BASE_BACK_Z
	Geo.add_box_shape(self, Vector3(SIZE.x, SEAT_H, base_d), Vector3(0, SEAT_H / 2.0, BASE_BACK_Z + base_d / 2.0))
	var back_d := SEAT_BACK_Z + SIZE.z / 2.0
	Geo.add_box_shape(self, Vector3(SIZE.x, SIZE.y - SEAT_H, back_d), Vector3(0, (SIZE.y + SEAT_H) / 2.0, -SIZE.z / 2.0 + back_d / 2.0))
	var arm_w := SIZE.x / 2.0 - ARM_INNER
	var arm_d := SEAT_FRONT_Z - SEAT_BACK_Z
	for side in [-1.0, 1.0]:
		Geo.add_box_shape(self, Vector3(arm_w, ARM_H - SEAT_H, arm_d),
			Vector3(side * (ARM_INNER + arm_w / 2.0), (ARM_H + SEAT_H) / 2.0, SEAT_BACK_Z + arm_d / 2.0))
	var spot_z := SEAT_BACK_Z + 0.25
	Seat.attach(self, "sessel", SEAT_H, Vector3(0, 0, spot_z), Vector3(0, 0, 1), ARM_INNER * 2.0, SEAT_FRONT_Z - spot_z + 0.3)
