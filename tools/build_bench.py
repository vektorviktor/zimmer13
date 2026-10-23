# Baut aus der Sketchfab-Parkbank („Park Bench“ von Decoratopia, https://sketchfab.com/hyperproduct, CC-BY 4.0,
# https://sketchfab.com/3d-models/park-bench-124b1f8ea43c4d1d8e71085e69bb293a) das Spielmodell
# assets/models/bench.glb für die Bänke im Außenbereich: LENGTH lang, Sitzseite nach +Z (Godot), Lehne bei −Z,
# Ursprung mittig unter der Bank. Ein Objekt mit zwei Flächen „metal“ (gusseiserne Seitenteile) und „wood“
# (Latten), nur Farbtexturen (TEX_SIZE, PNG) – die Glanzkarte des Metalls fällt weg.
# Am Ende stehen Tiefe, Höhe, Sitzhöhe und Lehnenmaße – für die Kollision in LevelBuilder._bench().
#
# Aufruf (Blender 4.3):
#   blender -b --python tools/build_bench.py -- assets/source/park_bench.glb assets/models/bench.glb
import bpy, sys
from mathutils import Matrix

LENGTH = 1.6        # Meter, so lang wie die Bank im Plan
TEX_SIZE = 512

argv = sys.argv[sys.argv.index("--") + 1:]
SRC, DST = argv[0], argv[1]

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=SRC)
meshes = [o for o in bpy.context.scene.objects if o.type == 'MESH']
for o in meshes:
	o.data.transform(o.matrix_world)
	o.parent = None
	o.matrix_world = Matrix.Identity(4)
for o in [o for o in bpy.context.scene.objects if o.type != 'MESH']:
	bpy.data.objects.remove(o)

# Im Original liegt die Bank entlang Y, die Lehne bei −X: um −90° drehen → Länge entlang X, Sitzseite nach −Y
# (Blender −Y = Godot +Z)
rot = Matrix.Rotation(-1.5707963, 4, 'Z')
pts = [rot @ v.co for o in meshes for v in o.data.vertices]
x0, x1 = min(p.x for p in pts), max(p.x for p in pts)
y0, y1 = min(p.y for p in pts), max(p.y for p in pts)
z0 = min(p.z for p in pts)
s = LENGTH / (x1 - x0)
xform = Matrix.Scale(s, 4) @ Matrix.Translation((-(x0 + x1) / 2.0, -(y0 + y1) / 2.0, -z0)) @ rot
for o in meshes:
	o.data.transform(xform)
	o.data.update()

# Nur die Farbtexturen, verkleinert und als PNG eingebettet
for o in meshes:
	src = o.data.materials[0]
	name = src.name.lower()
	img = None
	for n in src.node_tree.nodes:
		if n.type == 'BSDF_PRINCIPLED':
			link = n.inputs["Base Color"].links
			img = link[0].from_node.image if link else None
	img.scale(TEX_SIZE, TEX_SIZE)
	img.file_format = 'PNG'
	img.name = "bench_" + name
	img.pack()
	mat = bpy.data.materials.new(name)
	mat.use_nodes = True
	nodes = mat.node_tree.nodes
	tex = nodes.new("ShaderNodeTexImage")
	tex.image = img
	tex.interpolation = 'Closest'
	mat.node_tree.links.new(tex.outputs["Color"], nodes["Principled BSDF"].inputs["Base Color"])
	o.data.materials.clear()
	o.data.materials.append(mat)

wood = next(o for o in meshes if o.data.materials[0].name == "wood")
bpy.ops.object.select_all(action='DESELECT')
for o in meshes:
	o.select_set(True)
bpy.context.view_layer.objects.active = wood
bpy.ops.object.join()
bench = bpy.context.view_layer.objects.active
bench.name = bench.data.name = "bench"

bpy.ops.export_scene.gltf(filepath=DST, export_format='GLB', export_yup=True, export_image_format='AUTO',
	export_texcoords=True, export_normals=True, export_materials='EXPORT', export_animations=False)

# Maße für die Kollision: Sitz = waagrechte Latten (unterste Holzpunkte), Lehne = Holz darüber
tris = sum(len(p.vertices) - 2 for p in bench.data.polygons)
vs = [v.co for v in bench.data.vertices]
wood_idx = bench.data.materials.find("wood")
wv = {i for p in bench.data.polygons if p.material_index == wood_idx for i in p.vertices}
wp = [bench.data.vertices[i].co for i in wv]
seat_bottom = min(p.z for p in wp)
seat = [p for p in wp if p.z < seat_bottom + 0.06]
back = [p for p in wp if p.z > max(p.z for p in seat) + 0.02]
print("bench: %d Dreiecke, %.2f × %.2f m (Länge × Tiefe), %.2f m hoch, Faktor %.4f"
	% (tris, LENGTH, max(v.y for v in vs) - min(v.y for v in vs), max(v.z for v in vs), s))
print("  Sitz: Oberkante %.3f m, Tiefe %.3f..%.3f (Blender-Y, −Y = vorn)" % (max(p.z for p in seat), min(p.y for p in seat), max(p.y for p in seat)))
print("  Lehne: %.3f..%.3f m hoch, Blender-Y %.3f..%.3f" % (min(p.z for p in back), max(p.z for p in back), min(p.y for p in back), max(p.y for p in back)))
