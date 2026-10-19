# Baut aus der Sketchfab-Taschenlampe („Flashlight“ von Onur, https://sketchfab.com/onurpearl, CC-BY 4.0,
# https://sketchfab.com/3d-models/flashlight-d73e5a7dc8464bf0a065e677f3c4d55c) das Spielmodell
# assets/models/flashlight.glb (Spielkonzept 4.16): LENGTH lang, Leuchtrichtung +Z (Godot), Schalter oben,
# Ursprung mittig in der Länge auf der Unterkante des Kopfs. Zwei Objekte: „body“ (Gehäuse + Schalter, nur
# Farbtextur) und „lens“ (das Glas – das Spiel gibt ihm das leuchtende Material von Flashlight).
# Am Ende steht die Glasmitte – als Flashlight.LENS übernehmen (dort sitzt der Lichtkegel).
#
# Aufruf (Blender 4.3):
#   blender -b --python tools/build_flashlight.py -- assets/source/flashlight.glb assets/models/flashlight.glb
import bpy, sys, math
from mathutils import Matrix, Vector

LENGTH = 0.25     # Meter (wie eine große Stablampe)
TEX_SIZE = 256

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

# Im Original: Kopf nach −X, Schalter nach −Y. Das Glas ist die flache Scheibe (keine Ausdehnung in X).
lens = min(meshes, key=lambda o: max(v.co.x for v in o.data.vertices) - min(v.co.x for v in o.data.vertices))
parts = [o for o in meshes if o != lens]
bpy.ops.object.select_all(action='DESELECT')
for o in parts:
	o.select_set(True)
bpy.context.view_layer.objects.active = parts[0]
bpy.ops.object.join()
body = parts[0]
body.name = body.data.name = "body"
lens.name = lens.data.name = "lens"

# Schalter nach oben (+Z), Kopf nach −Y (Blender −Y = glTF/Godot +Z)
rot = Matrix.Rotation(math.radians(90), 4, 'Z') @ Matrix.Rotation(math.radians(-90), 4, 'X')
pts = [rot @ v.co for o in (body, lens) for v in o.data.vertices]
y0, y1 = min(p.y for p in pts), max(p.y for p in pts)
z0 = min(p.z for p in pts)
s = LENGTH / (y1 - y0)
xform = Matrix.Scale(s, 4) @ Matrix.Translation((0, -(y0 + y1) / 2.0, -z0)) @ rot
for o in (body, lens):
	o.data.transform(xform)
	o.data.update()

# Nur die Farbtextur, verkleinert und als PNG eingebettet
src_mat = body.data.materials[0]
img = None
for n in src_mat.node_tree.nodes:
	if n.type == 'BSDF_PRINCIPLED':
		link = n.inputs["Base Color"].links
		img = link[0].from_node.image if link else None
img.scale(TEX_SIZE, TEX_SIZE)
img.file_format = 'PNG'
img.name = "flashlight"
img.pack()
mat = bpy.data.materials.new("flashlight")
mat.use_nodes = True
nodes = mat.node_tree.nodes
tex = nodes.new("ShaderNodeTexImage")
tex.image = img
tex.interpolation = 'Closest'
mat.node_tree.links.new(tex.outputs["Color"], nodes["Principled BSDF"].inputs["Base Color"])
for o in (body, lens):
	o.data.materials.clear()
	o.data.materials.append(mat)

bpy.ops.export_scene.gltf(filepath=DST, export_format='GLB', export_yup=True, export_image_format='AUTO',
	export_texcoords=True, export_normals=True, export_materials='EXPORT', export_animations=False)

tris = sum(len(p.vertices) - 2 for o in (body, lens) for p in o.data.polygons)
c = sum((v.co for v in lens.data.vertices), Vector()) / len(lens.data.vertices)
r = max((v.co - c).length for v in lens.data.vertices)
print("flashlight: %d Dreiecke, %.3f m lang, Kopf %.3f m, Glas-Radius %.3f m" % (tris, LENGTH, (max(p.x for p in pts) - min(p.x for p in pts)) * s, r))
# Blender (x, y, z) → Godot (x, z, −y)
print("LENS := Vector3(%.3f, %.3f, %.3f)   # Glasmitte" % (c.x, c.z, -c.y))
