class_name CandleModel
## Kerzen aus assets/models/candle.glb und candle_flame.glb (tools/build_candle.py, Spielkonzept 5.4, 7.3): Kerze rot
## oder weiß (dasselbe Netz, zwei Texturen), flacher Teller, animierte Flamme. Ursprung jeweils mittig unten. Gebraucht
## vom Gegenstand (Item, Kind.CANDLE), der festen Deko-Kerze (LevelBuilder._candle) und dem Kerzenvorrat
## (ResourceSpot). Fehlen die Dateien, bleiben Grundkörper. Das Wachs hat einen eigenen Shader (shaders/candle_wax.gdshader:
## durchscheinend, glüht unter der Flamme), die Flamme shaders/candle_flame.gdshader.

const PATH := "res://assets/models/candle.glb"
const FLAME_PATH := "res://assets/models/candle_flame.glb"
## Maße aus build_candle.py (Wachs ohne Docht, Radius, Spitze des Dochts; Teller außen, Höhe seines Bodens)
const HEIGHT := 0.16
const RADIUS := 0.0164
const WICK_TOP := 0.171
const PLATE_RADIUS := 0.06
const PLATE_FLOOR := 0.0046
## Flamme: Fuß so tief unter der Dochtspitze (sie umhüllt den Docht), Höhe des Netzes, Bilder je Sekunde
const FLAME_SINK := 0.006
const FLAME_HEIGHT := 0.044
## So viel breiter als das Netz (das Original ist für die Kerze schmal, die Flamme im Vorbild breiter)
const FLAME_WIDEN := 1.2
const FPS := 24.0
## Lichthof um die Flamme (Billboard, Kantenlänge in m) – der Schein, den das Auge bzw. eine Kamera um eine Flamme sieht
const HALO_SIZE := 0.16

static var _meshes := {}
static var _mats := {}
static var _frames: Array[ArrayMesh] = []
static var _flame_mat: ShaderMaterial
static var _halo_mat: ShaderMaterial
static var _wax_shader: Shader


## Kerze unter parent (Ursprung mittig unten, auf dem Teller, wenn plate). Gibt die Höhe der Dochtspitze zurück. Das
## Wachs steht als Meta „candle_wax“ am parent – flame() lässt es glühen, solange die Flamme brennt.
static func build(parent: Node3D, red: bool = false, plate: bool = false, at: Vector3 = Vector3.ZERO) -> float:
	_load()
	var y := at.y
	if plate:
		if _meshes.has("plate"):
			Geo.mesh(parent, _meshes["plate"], _mats["plate"], at)
			y += PLATE_FLOOR
		else:
			Geo.mesh(parent, Geo.cylinder(0.05, 0.015, 8), Mat.psx(Color(0.6, 0.47, 0.22)), at + Vector3(0, 0.0075, 0))
			y += 0.015
	var key := "candle_red" if red else "candle_white"
	if _meshes.has(key):
		parent.set_meta("candle_wax", Geo.mesh(parent, _meshes[key], _mats[key], Vector3(at.x, y, at.z)))
	else:
		var wax := Color(0.7, 0.1, 0.08) if red else Color(0.92, 0.88, 0.75)
		Geo.mesh(parent, Geo.cylinder(0.03, HEIGHT, 6), Mat.psx(wax), Vector3(at.x, y + HEIGHT / 2.0, at.z))
	return y + WICK_TOP


## Brennende Flamme mit Schein, Fuß auf der Dochtspitze bei wick (Höhe aus build). Sichtbarkeit = brennt.
static func flame(parent: Node3D, wick: Vector3) -> Node3D:
	_load()
	var node := CandleFlame.new()
	node.position = wick - Vector3(0, FLAME_SINK, 0)
	node.wax = parent.get_meta("candle_wax", null)
	node.scale = Vector3(FLAME_WIDEN, 1.0, FLAME_WIDEN)
	parent.add_child(node)
	if _frames.is_empty():
		var mat := Mat.psx(Color(1, 0.8, 0.3), "", 1.0, Color(1, 0.7, 0.2), 4.0)
		Geo.mesh(node, Geo.sphere(0.016, 0.04, 5, 2), mat, Vector3(0, 0.02, 0))
		return node
	node.frames = _frames
	node.mesh = _frames[0]
	node.material_override = _flame_mat
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var quad := QuadMesh.new()
	quad.size = Vector2.ONE
	var halo := Geo.mesh(node, quad, _halo_mat, Vector3(0, FLAME_HEIGHT * 0.45, 0))
	halo.scale = Vector3.ONE * HALO_SIZE
	halo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return node


static func _load() -> void:
	if not _meshes.is_empty() or not ResourceLoader.exists(PATH):
		return
	var root := (load(PATH) as PackedScene).instantiate()
	for node in root.find_children("*", "MeshInstance3D", true, false):
		var mi := node as MeshInstance3D
		_meshes[String(mi.name)] = mi.mesh
		_mats[String(mi.name)] = _wax(mi) if String(mi.name).begins_with("candle_") else Mat.model(PATH, mi)
	root.free()
	if not ResourceLoader.exists(FLAME_PATH):
		return
	var shader := load("res://shaders/candle_flame.gdshader") as Shader
	_flame_mat = ShaderMaterial.new()
	_flame_mat.shader = shader
	_flame_mat.set_shader_parameter("height", FLAME_HEIGHT)
	_halo_mat = ShaderMaterial.new()
	_halo_mat.shader = shader
	_halo_mat.set_shader_parameter("halo", true)
	_halo_mat.render_priority = -1
	# Die Formschlüssel (absolute Lagen) als fertige Netze – je Bild eins, ohne Blend-Shape-Rechnung pro Kerze
	var froot := (load(FLAME_PATH) as PackedScene).instantiate()
	var src := (froot.find_children("*", "MeshInstance3D", true, false)[0] as MeshInstance3D).mesh as ArrayMesh
	var arrays := src.surface_get_arrays(0)
	for shape: Array in src.surface_get_blend_shape_arrays(0):
		var a := arrays.duplicate()
		a[Mesh.ARRAY_VERTEX] = shape[Mesh.ARRAY_VERTEX]
		a[Mesh.ARRAY_NORMAL] = shape[Mesh.ARRAY_NORMAL]
		var m := ArrayMesh.new()
		m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, a)
		_frames.append(m)
	froot.free()


## Wachs (rot oder weiß): Farbtextur aus der GLB, Höhe für das Glühen unter der Flamme
static func _wax(src: MeshInstance3D) -> ShaderMaterial:
	if _wax_shader == null:
		_wax_shader = load("res://shaders/candle_wax.gdshader")
	var m := ShaderMaterial.new()
	m.shader = _wax_shader
	m.set_shader_parameter("albedo_tex", (src.get_active_material(0) as BaseMaterial3D).albedo_texture)
	m.set_shader_parameter("height", HEIGHT)
	return m
