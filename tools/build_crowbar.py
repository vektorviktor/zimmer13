# Baut aus dem Sketchfab-Brecheisen („Crowbar V2“ von SketchyBot, https://sketchfab.com/SketchyB0t_3D_Fabrication,
# Sketchfab Standard, https://sketchfab.com/3d-models/crowbar-v2-dfb5981c576d4fd9b3fa6870d745abe3) das Spielmodell
# assets/models/crowbar.glb (Spielkonzept 6.19): LENGTH lang entlang +X, die Klaue am +X-Ende biegt nach oben (+Y),
# flach in Z. Ursprung mittig in der Länge und Dicke auf der Unterkante. Ein Objekt „crowbar“ mit der Farbtextur.
# Am Ende stehen die Maße – als size in Item (Kind.CROWBAR) übernehmen.
#
# Aufruf (Blender 4.3):
#   blender -b --python tools/build_crowbar.py -- assets/source/crowbar_v2.glb assets/models/crowbar.glb
import bpy, sys, math
from mathutils import Matrix

LENGTH = 0.6      # Meter (ein kräftiges Brecheisen)
TEX_SIZE = 256

argv = sys.argv[sys.argv.index("--") + 1:]
SRC, DST = argv[0], argv[1]

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=SRC)
bar = [o for o in bpy.context.scene.objects if o.type == 'MESH'][0]
# Die Knoten darüber drehen und skalieren nur – das Mesh selbst liegt schon richtig: Länge in X, Biegung in Blender Z
# (glTF/Godot Y), Dicke in Blender Y
bar.parent = None
bar.matrix_world = Matrix.Identity(4)
for o in [o for o in bpy.context.scene.objects if o != bar]:
	bpy.data.objects.remove(o)
bar.name = bar.data.name = "crowbar"

vs = bar.data.vertices
x0, x1 = min(v.co.x for v in vs), max(v.co.x for v in vs)
z1 = max(v.co.z for v in vs)
# Klaue = das Ende, an dem die Biegung am höchsten steigt; gehört nach +X (180° um die Hochachse, nicht spiegeln)
tip = max(vs, key=lambda v: v.co.z).co.x
rot = Matrix.Rotation(math.pi, 4, 'Z') if tip < (x0 + x1) / 2.0 else Matrix.Identity(4)
pts = [rot @ v.co for v in vs]
x0, x1 = min(p.x for p in pts), max(p.x for p in pts)
y0, y1 = min(p.y for p in pts), max(p.y for p in pts)
z0, z1 = min(p.z for p in pts), max(p.z for p in pts)
s = LENGTH / (x1 - x0)
bar.data.transform(Matrix.Scale(s, 4) @ Matrix.Translation((-(x0 + x1) / 2.0, -(y0 + y1) / 2.0, -z0)) @ rot)
bar.data.update()

# Nur die Farbtextur, als PNG eingebettet, ohne Glanz; pixelig gefiltert
src_mat = bar.data.materials[0]
img = None
for n in src_mat.node_tree.nodes:
	if n.type == 'BSDF_PRINCIPLED':
		link = n.inputs["Base Color"].links
		img = link[0].from_node.image if link else None
img.scale(TEX_SIZE, TEX_SIZE)
img.file_format = 'PNG'
img.name = "crowbar"
img.pack()
mat = bpy.data.materials.new("crowbar")
mat.use_nodes = True
nodes = mat.node_tree.nodes
tex = nodes.new("ShaderNodeTexImage")
tex.image = img
tex.interpolation = 'Closest'
mat.node_tree.links.new(tex.outputs["Color"], nodes["Principled BSDF"].inputs["Base Color"])
bar.data.materials.clear()
bar.data.materials.append(mat)

bpy.ops.export_scene.gltf(filepath=DST, export_format='GLB', export_yup=True, export_image_format='AUTO',
	export_texcoords=True, export_normals=True, export_materials='EXPORT', export_animations=False)

tris = sum(len(p.vertices) - 2 for p in bar.data.polygons)
# Blender (x, y, z) → Godot (x, z, −y)
print("crowbar: %d Dreiecke" % tris)
print("size = Vector3(%.3f, %.3f, %.3f)" % (LENGTH, (z1 - z0) * s, (y1 - y0) * s))
