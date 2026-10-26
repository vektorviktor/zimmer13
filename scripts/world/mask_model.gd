class_name MaskModel
## Die acht verbotenen Masken (Spielkonzept 5.19): Wer eine trägt, ruft die Bedrohung, die sie zeigt. Modelle aus
## assets/models/masks.glb (tools/build_masks.py, Meshy): je Netz „mask_<id>“, Ursprung mittig auf der Rückseite,
## Gesicht nach +Z, echte Größe (SIZES). Material: shaders/psx_model.gdshader mit Farbe, Normal Map und Rauheit aus
## der GLB – wie die Kürbisse. Masken ohne Modell gibt es noch nicht im Spiel, ihr Haken in Zimmer 13 bleibt leer.

const PATH := "res://assets/models/masks.glb"
## Reihenfolge der Haken in Zimmer 13 (MaskHook) – wie die Tabelle im Spielkonzept
const ORDER := ["leviathan", "pumpkin", "ghost", "vampire", "doll", "scarecrow", "crow", "cat"]
const NAMES := {
	"leviathan": "Leviathan-Maske", "pumpkin": "Kürbismann-Maske", "ghost": "Lakengeist-Maske",
	"vampire": "Vampirmaske", "doll": "Puppenmaske", "scarecrow": "Vogelscheuchen-Maske", "crow": "Krähenmaske",
	"cat": "Kesselkatzen-Maske",
}
## Breite × Höhe × Tiefe (m), von tools/build_masks.py ausgegeben
const SIZES := {"pumpkin": Vector3(0.195, 0.26, 0.101), "doll": Vector3(0.184, 0.24, 0.104)}
## Glanz (Rauheit aus der Karte: die Kürbisschale matt, das Porzellan glatt)
const SPECULAR := 0.5

static var _meshes := {}
static var _materials := {}
static var _shader: Shader


static func has_model(id: String) -> bool:
	return SIZES.has(id) and ResourceLoader.exists(PATH)


static func display_name(id: String) -> String:
	return String(NAMES.get(id, "Maske"))


## Die Maske als Netz (Ursprung mittig hinten, Gesicht nach +Z); ohne Modell ein leerer Knoten.
static func build(id: String) -> Node3D:
	if not has_model(id):
		return Node3D.new()
	_load()
	var mi := MeshInstance3D.new()
	mi.mesh = _meshes[id]
	mi.material_override = _materials[id]
	return mi


static func _load() -> void:
	if not _meshes.is_empty():
		return
	_shader = load("res://shaders/psx_model.gdshader")
	var root := (load(PATH) as PackedScene).instantiate()
	for node in root.find_children("mask_*", "MeshInstance3D", true, false):
		var mi := node as MeshInstance3D
		var id := String(mi.name).trim_prefix("mask_")
		var source := mi.mesh.surface_get_material(0) as BaseMaterial3D
		var m := ShaderMaterial.new()
		m.shader = _shader
		m.set_shader_parameter("albedo_tex", source.albedo_texture)
		m.set_shader_parameter("normal_tex", source.normal_texture)
		m.set_shader_parameter("use_normal", source.normal_texture != null)
		m.set_shader_parameter("roughness_tex", source.roughness_texture)
		m.set_shader_parameter("specular", SPECULAR)
		_meshes[id] = mi.mesh
		_materials[id] = m
	root.free()
