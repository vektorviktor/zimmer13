class_name MaskBoard
extends StaticBody3D
## Maskenboard in Zimmer 13 (Spielkonzept 5.19, ZIM-128, Entscheidung 3.11.): Tafel aus dem dunklen Holz der
## Vertäfelung mit Rahmenleiste auf Gehrung, darauf 4 × 2 gedrechselte Holzstifte, leicht nach oben geneigt – je
## Maske ein Stift (MaskHook), obere Reihe links beginnend in der Reihenfolge von MaskModel.ORDER. Keine
## Namensschilder: Leere Stifte zeigen, wie viele Masken fehlen, nicht welche. Modell und Verschattung aus
## tools/build_mask_board.py, Holz mit Mat.hotel_wood. Ursprung an der Wand mittig unter der Unterkante, Vorderseite
## nach +Z. Gebaut von LevelBuilder._mask_hooks. Maße = Bauskript.

const MODEL := "res://assets/models/mask_board.glb"
const AO := "res://assets/textures/mask_board_ao.png"
## Breite, Höhe, Tiefe (Vorderseite der Rahmenleiste)
const SIZE := Vector3(1.32, 0.96, 0.03)
## Vorderseite der Füllung über der Wand – darauf sitzen die Stifte
const PANEL := 0.018
## Unterkante über dem Boden (m): obere Stifte auf 1,82 m, untere auf 1,40 m, die Masken hängen darunter
const BOTTOM := 1.0
## Plätze der Stifte (x, Höhe über der Unterkante), obere Reihe zuerst
const SLOTS: Array[Vector2] = [Vector2(-0.45, 0.82), Vector2(-0.15, 0.82), Vector2(0.15, 0.82), Vector2(0.45, 0.82),
	Vector2(-0.45, 0.40), Vector2(-0.15, 0.40), Vector2(0.15, 0.40), Vector2(0.45, 0.40)]

static var _meshes := {}


func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	var mi := MeshInstance3D.new()
	mi.mesh = mesh("board")
	mi.material_override = material()
	add_child(mi)
	Geo.add_box_shape(self, SIZE, SIZE / 2.0 * Vector3(0, 1, 1))
	for i in mini(MaskModel.ORDER.size(), SLOTS.size()):
		var hook := MaskHook.new().setup(MaskModel.ORDER[i])
		hook.position = Vector3(SLOTS[i].x, SLOTS[i].y, PANEL)
		add_child(hook)


## Teil des Modells: „board“ oder „peg“ (ein Stift, Ursprung auf der Füllung)
static func mesh(part: String) -> Mesh:
	if _meshes.is_empty():
		var scene: Node = (load(MODEL) as PackedScene).instantiate()
		for node: MeshInstance3D in scene.find_children("*", "MeshInstance3D", true, false):
			_meshes[String(node.name)] = node.mesh
		scene.free()
	return _meshes[part]


## Holz der Vertäfelung mit der gebackenen Verschattung über UV2 – für Board und Stifte
static func material() -> Material:
	return Mat.hotel_wood(AO)
