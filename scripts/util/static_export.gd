class_name StaticExport
## Debug --static-eg[=pfad]: das Erdgeschoss als statische Szene zum Ausprobieren (Licht, Schatten …). Nur, was der
## LevelBuilder als Bau sammelt (structure_parts: Wände mit ihren Öffnungen und Häuten, Böden, Decken – mit
## Kollision und den echten Materialien), dazu alle eingeschalteten Lampen mit ihren Leuchten, Umgebung, Mond und ein
## StaticWalker zum Durchlaufen. Keine Türen, Fenster, Möbel, Kerzen, Schalter, keine Spiellogik. Die Lampen sind
## schlichte OmniLight3D mit der Grundstärke (ohne Flackern), alle mit Schatten.

const PATH := "res://temp/eg_static.scn"
## Fängt auf, wer durch ein Loch fällt (Aufzugschacht, Becken – beides fehlt)
const CATCH_Y := -3.0


static func save(builder: LevelBuilder, main: Node, path: String = PATH) -> Error:
	var scene := Node3D.new()
	scene.name = "ErdgeschossStatisch"
	var bau := _holder(scene, "Bau")
	var seen := {}
	for part in builder.structure_parts:
		# Wände: das Mesh hängt mit seinen Kollisionskästen an einem eigenen Knoten; Böden und Decken sind ein Körper
		var src: Node3D = part.get_parent() if part is MeshInstance3D else part
		if seen.has(src) or not _ground_floor(src, builder.root):
			continue
		seen[src] = true
		var copy := src.duplicate() as Node3D
		copy.transform = src.global_transform
		bau.add_child(copy)
	var lamps := _holder(scene, "Lampen")
	var count := 0
	for node in main.get_tree().get_nodes_in_group("lamps"):
		var src := node as OmniLight3D
		if src == null or src.has_meta("no_shadow") or not src.is_visible_in_tree() or not _ground_floor(src, builder.root):
			continue
		var flicker := src as FlickerLight
		if flicker and (flicker.soft or flicker.broken):
			continue   # Kerzen gehören zur Ausstattung, defekte Birnen bleiben dunkel
		var light := OmniLight3D.new()
		light.name = "Lampe_%d" % count
		light.transform = src.global_transform
		light.light_color = src.light_color
		light.light_energy = flicker.base_energy if flicker else src.light_energy
		light.light_specular = src.light_specular
		light.omni_range = src.omni_range
		light.omni_attenuation = src.omni_attenuation
		light.shadow_enabled = true
		light.shadow_bias = src.shadow_bias
		light.shadow_normal_bias = src.shadow_normal_bias
		light.distance_fade_enabled = src.distance_fade_enabled
		light.distance_fade_begin = src.distance_fade_begin
		light.distance_fade_length = src.distance_fade_length
		light.distance_fade_shadow = src.distance_fade_begin + src.distance_fade_length
		lamps.add_child(light)
		count += 1
		var fixture := src.get_parent()
		if fixture is Lamp:   # Halter, Schirm, Birne – nur die sichtbaren Meshes, ohne Skript und Kollision
			for mi: MeshInstance3D in fixture.find_children("*", "MeshInstance3D", true, false):
				if mi.is_visible_in_tree():
					lamps.add_child(_mesh_copy(mi))
	for child in main.get_children():
		if child is WorldEnvironment or (child is DirectionalLight3D and child.name == "Moon"):
			scene.add_child(child.duplicate())
	var floor_catch := StaticBody3D.new()
	floor_catch.name = "Fangboden"
	floor_catch.position.y = CATCH_Y
	var plane := CollisionShape3D.new()
	plane.shape = WorldBoundaryShape3D.new()
	floor_catch.add_child(plane)
	scene.add_child(floor_catch)
	var walker := StaticWalker.new()
	walker.name = "Laeufer"
	walker.position = builder.player_spawn
	scene.add_child(walker)
	walker.build()
	_own(scene, scene)
	var packed := PackedScene.new()
	var err := packed.pack(scene)
	if err == OK:
		err = ResourceSaver.save(packed, path)
	print("[static-eg] %s: %d Bauteile, %d Lampen → %s" % [error_string(err), seen.size(), count, path])
	scene.free()
	return err


## Liegt node im Erdgeschoss – unter root, aber nicht unter dessen Stockwerksknoten (Obergeschoss…, Untergeschoss)?
static func _ground_floor(node: Node, root: Node) -> bool:
	var n := node
	while n != null and n.get_parent() != root:
		n = n.get_parent()
	return n != null and not n.name.begins_with("Obergeschoss") and n.name != "Untergeschoss"


static func _holder(parent: Node, holder_name: String) -> Node3D:
	var holder := Node3D.new()
	holder.name = holder_name
	parent.add_child(holder)
	return holder


static func _mesh_copy(src: MeshInstance3D) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = src.mesh
	mi.material_override = src.material_override
	for i in src.get_surface_override_material_count():
		mi.set_surface_override_material(i, src.get_surface_override_material(i))
	mi.cast_shadow = src.cast_shadow
	mi.transform = src.global_transform
	return mi


static func _own(node: Node, owner_node: Node) -> void:
	for child in node.get_children():
		child.owner = owner_node
		_own(child, owner_node)
