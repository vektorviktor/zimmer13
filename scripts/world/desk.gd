class_name Desk
extends StaticBody3D
## Schreibtisch im Büro der Direktion (ZIM-150): „Antique Desk“ von Matthew Collings (Sketchfab, CC-BY 4.0), gebaut
## von tools/build_desk.py – Korpus mit zwei Seitenschränken voller Schubladen, darüber drei Schubladen unter der
## Platte als eigene Teile (drawer_l/m/r, zum späteren Herausziehen entlang +Z). Material aus dem vollen PBR-Set
## (Mat.pbr_model). Ursprung mittig auf dem Boden, Vorderseite (Griffe) nach +Z; Größe fest wie im Original.

const MODEL := "res://assets/models/desk.glb"
const TEX := "res://assets/textures/desk"
const SIZE := Vector3(1.611, 0.82, 0.662)
## Seitenschränke außen bis unter die Platte, dazwischen frei für die Knie
const PEDESTAL_W := 0.4
const KNEE_H := 0.66
## Messinggriffe: wie die Messingteile im Haus nur teils metallisch
const BRASS_METALLIC := 0.55


func _ready() -> void:
	add_to_group("desks")
	collision_mask = 0
	var model: Node3D = (load(MODEL) as PackedScene).instantiate()
	add_child(model)
	var mat := Mat.pbr_model(TEX, BRASS_METALLIC)
	for m: MeshInstance3D in model.find_children("*", "MeshInstance3D", true, false):
		m.material_override = mat
	for side in [-1.0, 1.0]:
		Geo.add_box_shape(self, Vector3(PEDESTAL_W, KNEE_H, SIZE.z),
			Vector3(side * (SIZE.x - PEDESTAL_W) / 2.0, KNEE_H / 2.0, 0))
	Geo.add_box_shape(self, Vector3(SIZE.x, SIZE.y - KNEE_H, SIZE.z), Vector3(0, (SIZE.y + KNEE_H) / 2.0, 0))
