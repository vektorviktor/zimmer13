extends SceneTree
## Schreibt den Platzhalter-Pflanzkübel aus `LevelBuilder._gardens()` als Ausgangsmodell nach
## assets/models/planter.glb – zum Weiterbearbeiten in Blender.
##
##   godot --headless --path . -s tools/build_planter.gd
##
## Zwei Objekte mit je einem Material: `pot` (Steinquader, Material `stone`, Textur „concrete“) und
## `hedge` (Kugel, Material `leaves`, Textur „hedge“). UVs wie die Weltprojektion des PSX-Shaders (1 m = eine Kachel, Fläche nach der
## Hauptachse ihrer Normale), Farbton in die Textur gebacken, weil `Mat.model` mit 0,8 Grau färbt.

const OUT := "res://assets/models/planter.glb"
const SIZE := 2.0
const HEIGHT := 0.6                     # = LevelBuilder.PLANTER_H (LevelBuilder braucht Autoloads)
const STONE := Color(0.62, 0.57, 0.5)   # wie LevelBuilder._stone
const MODEL_TINT := 0.8                 # Grundfarbe in Mat.model


func _init() -> void:
	var root := Node3D.new()
	root.name = "planter"
	_add(root, "pot", Geo.box(Vector3(SIZE, HEIGHT, SIZE)),
		Vector3(0, HEIGHT / 2.0, 0), "concrete", STONE, "stone")
	_add(root, "hedge", Geo.sphere(SIZE * 0.4, 1.2, 7, 4), Vector3(0, 1.1, 0), "hedge", Color.WHITE, "leaves")
	var doc := GLTFDocument.new()
	var state := GLTFState.new()
	var err := doc.append_from_scene(root, state)
	if err == OK:
		err = doc.write_to_filesystem(state, ProjectSettings.globalize_path(OUT))
	print("planter.glb: ", error_string(err))
	root.free()
	quit(err)


## Mesh mit Weltprojektions-UVs an pos (Kübelboden = 0) als eigenes Objekt anhängen.
func _add(root: Node3D, node_name: String, src: PrimitiveMesh, pos: Vector3, tex_id: String, tint: Color,
		mat_name: String) -> void:
	var arrays := src.get_mesh_arrays()
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for t in range(0, indices.size(), 3):
		var a := verts[indices[t]] + pos
		var b := verts[indices[t + 1]] + pos
		var c := verts[indices[t + 2]] + pos
		# Projektion je Dreieck (der Shader wählt sie je Pixel) – sonst verzerren gemischte Achsen.
		var n := (b - a).cross(c - a).abs()
		for i in 3:
			var v := verts[indices[t + i]] + pos
			var uv: Vector2
			if n.x > n.y and n.x > n.z:
				uv = Vector2(v.z, v.y)
			elif n.y > n.z:
				uv = Vector2(v.x, v.z)
			else:
				uv = Vector2(v.x, v.y)
			st.set_normal(normals[indices[t + i]])
			st.set_uv(Vector2(uv.x, -uv.y))
			st.add_vertex(v)
	st.index()
	var img := (TexGen.get_tex(tex_id) as ImageTexture).get_image()
	for y in img.get_height():
		for x in img.get_width():
			img.set_pixel(x, y, (img.get_pixel(x, y) * tint / MODEL_TINT).clamp())
	var mat := StandardMaterial3D.new()
	mat.resource_name = mat_name   # nicht wie das Objekt, sonst hängt der Export „2“ an
	mat.albedo_texture = ImageTexture.create_from_image(img)
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	var mi := MeshInstance3D.new()
	mi.name = node_name
	mi.mesh = st.commit()
	mi.mesh.surface_set_material(0, mat)
	root.add_child(mi)
	mi.owner = root
