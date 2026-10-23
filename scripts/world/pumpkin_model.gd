class_name PumpkinModel
## Meshy-Kürbisse (Spielkonzept 5.8) aus assets/models/pumpkins.glb (tools/build_pumpkins.py): ein glatter
## Halloween-Kürbis und fünf Fratzen, Ursprung mittig unten, Gesicht nach +Z. Bekommen die Sorten in VARIETIES –
## im Item (Item._pumpkin_model) und reif an der Pflanze; die übrigen Sorten baut Item._pumpkin aus Grundkörpern.
## Material: shaders/psx_model.gdshader mit Farbe, Normal Map, Rauheit und Glutmaske aus der GLB.

const PATH := "res://assets/models/pumpkins.glb"
## Anzahl der Fratzen (Item.face 1 … FACES, gespeichert im Zusatz „f=n“)
const FACES := 5
## Runde orange Sorten – das Modell wird auf ihre Breite (PumpkinKinds „size“.x) gebracht, gleichmäßig
const VARIETIES := ["halloween", "giant"]
## Glanz der Schale (Rauheit aus der Karte: Schale wachsig, Stiel stumpf)
const SPECULAR := 0.5
## Fruchtfleisch mit Kerze: Anteil der Leuchtkraft, die Item.light_up setzt (3,0 – wie bei den Augen der alten Kürbisse)
const GLOW_SCALE := 0.6

static var _meshes := {}
static var _source: BaseMaterial3D
static var _shader: Shader
static var _shared: ShaderMaterial
## Breite des Netzes (m), gemessen am glatten Kürbis
static var width := 0.4


static func has_model(variety: String) -> bool:
	return variety in VARIETIES


## Netz: 0 = glatt, 1 … FACES = Fratze
static func mesh_of(face: int) -> Mesh:
	_load()
	return _meshes["pumpkin_plain" if face <= 0 else "jack_o_lantern_%d" % clampi(face, 1, FACES)]


## Maßstab für eine Sorte (gleichmäßig nach der Breite)
static func scale_for(variety: String) -> float:
	_load()
	return (PumpkinKinds.data(variety)["size"] as Vector3).x / width


## Eigenes Material (welk wird es dunkler, mit Kerze glüht das Fruchtfleisch in glow)
static func material(glow: Color = Color.BLACK) -> ShaderMaterial:
	_load()
	var m := ShaderMaterial.new()
	m.shader = _shader
	m.set_shader_parameter("albedo_tex", _source.albedo_texture)
	m.set_shader_parameter("normal_tex", _source.normal_texture)
	m.set_shader_parameter("use_normal", _source.normal_texture != null)
	m.set_shader_parameter("roughness_tex", _source.roughness_texture)
	m.set_shader_parameter("specular", SPECULAR)
	m.set_shader_parameter("glow_tex", _source.emission_texture)
	m.set_shader_parameter("emission", glow * GLOW_SCALE)
	m.set_meta("pumpkin_model", true)
	return m


## Gemeinsames Material ohne Glut (reife Frucht an der Pflanze)
static func shared_material() -> ShaderMaterial:
	if _shared == null:
		_shared = material()
	return _shared


static func _load() -> void:
	if not _meshes.is_empty():
		return
	var root := (load(PATH) as PackedScene).instantiate()
	for node in root.find_children("*", "MeshInstance3D", true, false):
		var mi := node as MeshInstance3D
		_meshes[String(mi.name)] = mi.mesh
	var plain := _meshes["pumpkin_plain"] as Mesh
	_source = plain.surface_get_material(0) as BaseMaterial3D
	width = plain.get_aabb().size.x
	root.free()
	_shader = load("res://shaders/psx_model.gdshader")
