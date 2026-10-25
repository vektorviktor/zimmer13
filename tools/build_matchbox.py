# Baut aus dem Sketchfab-Modell „Matchbox-Freepoly.org“ (Freepoly.org, https://skfb.ly/osYOB, CC-BY 4.0) das
# Spielmodell assets/models/matchbox.glb (Spielkonzept 5.12): flach liegend, die Länge entlang X, die Breite entlang Z,
# das Katzen-Etikett oben (und unten). Ursprung mittig auf der Unterseite. Ein Objekt „matchbox“ mit der Farbtextur
# (Normal- und Glanzkarte entfallen). Am Ende stehen die Maße – als size in Item (Kind.MATCHBOX) übernehmen.
#
# Aufruf (Blender 4.3):
#   blender -b --python tools/build_matchbox.py -- assets/source/matchbox_freepoly.glb assets/models/matchbox.glb
import bpy, sys, math
from mathutils import Matrix

LENGTH = 0.066    # Meter (66 × 52 × 20 mm wie im Original)
TEX_SIZE = 256

argv = sys.argv[sys.argv.index("--") + 1:]
SRC, DST = argv[0], argv[1]

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=SRC)
box = [o for o in bpy.context.scene.objects if o.type == 'MESH'][0]
# Die Knoten darüber drehen und skalieren nur; das Mesh liegt in Millimetern, die Dicke in Blender Y
box.parent = None
box.matrix_world = Matrix.Identity(4)
for o in [o for o in bpy.context.scene.objects if o != box]:
	bpy.data.objects.remove(o)
box.name = box.data.name = "matchbox"

# Dicke (Y) nach oben (Blender Z)
rot = Matrix.Rotation(math.pi / 2.0, 4, 'X')
pts = [rot @ v.co for v in box.data.vertices]
x0, x1 = min(p.x for p in pts), max(p.x for p in pts)
y0, y1 = min(p.y for p in pts), max(p.y for p in pts)
z0, z1 = min(p.z for p in pts), max(p.z for p in pts)
s = LENGTH / (x1 - x0)
box.data.transform(Matrix.Scale(s, 4) @ Matrix.Translation((-(x0 + x1) / 2.0, -(y0 + y1) / 2.0, -z0)) @ rot)
box.data.update()

# Nur die Farbtextur, als PNG eingebettet, ohne Glanz; pixelig gefiltert
src_mat = box.data.materials[0]
img = None
for n in src_mat.node_tree.nodes:
	if n.type == 'BSDF_PRINCIPLED':
		link = n.inputs["Base Color"].links
		img = link[0].from_node.image if link else None
img.scale(TEX_SIZE, TEX_SIZE)
img.file_format = 'PNG'
img.name = "matchbox"
img.pack()
mat = bpy.data.materials.new("matchbox")
mat.use_nodes = True
nodes = mat.node_tree.nodes
tex = nodes.new("ShaderNodeTexImage")
tex.image = img
tex.interpolation = 'Closest'
mat.node_tree.links.new(tex.outputs["Color"], nodes["Principled BSDF"].inputs["Base Color"])
box.data.materials.clear()
box.data.materials.append(mat)

bpy.ops.export_scene.gltf(filepath=DST, export_format='GLB', export_yup=True, export_image_format='AUTO',
	export_texcoords=True, export_normals=True, export_materials='EXPORT', export_animations=False)

tris = sum(len(p.vertices) - 2 for p in box.data.polygons)
# Blender (x, y, z) → Godot (x, z, −y)
print("matchbox: %d Dreiecke" % tris)
print("size = Vector3(%.3f, %.3f, %.3f)" % (LENGTH, (z1 - z0) * s, (y1 - y0) * s))
