# Baut aus der Sketchfab-Glühbirne („Lightbulb (Low-Poly)“ von Mirai, https://sketchfab.com/MrMirai, CC-BY 4.0,
# https://sketchfab.com/3d-models/lightbulb-low-poly-2566774276944542a01ff47a67a6eb51) das Spielmodell
# assets/models/bulb.glb (Spielkonzept 7.3): LENGTH lang, Glas nach +Y (Godot), Ursprung auf der Achse am
# unteren Ende des Gewindes. Zwei Objekte: „socket“ (Schraubsockel, nur Farbtextur) und „glass“ (der Kolben –
# das Spiel gibt ihm das leuchtende Material der Lampe bzw. die Glasfarbe des Gegenstands). Glühwendel und
# Halter stecken im Kolben, der im Spiel undurchsichtig ist – sie fallen weg. Beide Teile werden ausgedünnt
# (über 270 Lampen im Hotel).
# Am Ende stehen Durchmesser und Sockelhöhe – für Lamp.BULB_SOCKET bzw. die Größe des Gegenstands.
#
# Aufruf (Blender 4.3):
#   blender -b --python tools/build_bulb.py -- assets/source/lightbulb.glb assets/models/bulb.glb
import bpy, bmesh, sys
from mathutils import Matrix, Vector

LENGTH = 0.11       # Meter (E27-Birne, A60)
TEX_SIZE = 128
GLASS_RATIO = 0.12  # Anteil der Dreiecke, der bleibt
SOCKET_RATIO = 0.1

argv = sys.argv[sys.argv.index("--") + 1:]
SRC, DST = argv[0], argv[1]

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=SRC)
objs = {o.name: o for o in bpy.context.scene.objects if o.type == 'MESH'}
glass = next(o for n, o in objs.items() if n.startswith("lamp_cap"))
socket = next(o for n, o in objs.items() if n.startswith("Circle_base"))

for o in (glass, socket):
	o.data.transform(o.matrix_world)
	o.parent = None
	o.matrix_world = Matrix.Identity(4)
for o in [o for o in bpy.context.scene.objects if o not in (glass, socket)]:
	bpy.data.objects.remove(o)

# Achse der Birne (im Original schräg gestellt): beide Teile sind drehsymmetrisch, ihre Mitten liegen darauf
def mid(o):
	return sum((v.co for v in o.data.vertices), Vector()) / len(o.data.vertices)
center = mid(glass)
axis = (center - mid(socket)).normalized()
# Glas nach +Z (Blender +Z = Godot +Y), Achse durch den Ursprung, Gewindeende auf z = 0
rot = axis.rotation_difference(Vector((0, 0, 1))).to_matrix().to_4x4()
pts = [rot @ (v.co - center) for o in (glass, socket) for v in o.data.vertices]
z0, z1 = min(p.z for p in pts), max(p.z for p in pts)
s = LENGTH / (z1 - z0)
xform = Matrix.Scale(s, 4) @ Matrix.Translation((0, 0, -z0)) @ rot @ Matrix.Translation(-center)
for o in (glass, socket):
	o.data.transform(xform)
	o.data.update()
glass.name = glass.data.name = "glass"
socket.name = socket.data.name = "socket"

# Ausdünnen – vorher die an UV-Nähten aufgetrennten Punkte verschmelzen, sonst reißt es Löcher
for o, ratio in ((glass, GLASS_RATIO), (socket, SOCKET_RATIO)):
	bm = bmesh.new()
	bm.from_mesh(o.data)
	bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=LENGTH * 1e-4)
	bm.to_mesh(o.data)
	bm.free()
	bpy.context.view_layer.objects.active = o
	mod = o.modifiers.new("decimate", 'DECIMATE')
	mod.ratio = ratio
	bpy.ops.object.modifier_apply(modifier=mod.name)

# Nur die Farbtextur des Sockels, verkleinert und als PNG eingebettet
img = None
for n in socket.data.materials[0].node_tree.nodes:
	if n.type == 'BSDF_PRINCIPLED':
		link = n.inputs["Base Color"].links
		img = link[0].from_node.image if link else None
img.scale(TEX_SIZE, TEX_SIZE)
img.file_format = 'PNG'
img.name = "bulb"
img.pack()
mat = bpy.data.materials.new("bulb")
mat.use_nodes = True
nodes = mat.node_tree.nodes
tex = nodes.new("ShaderNodeTexImage")
tex.image = img
tex.interpolation = 'Closest'
mat.node_tree.links.new(tex.outputs["Color"], nodes["Principled BSDF"].inputs["Base Color"])
socket.data.materials.clear()
socket.data.materials.append(mat)
glass.data.materials.clear()
glass.data.materials.append(bpy.data.materials.new("glass"))   # ohne Textur, das Spiel ersetzt es

bpy.ops.export_scene.gltf(filepath=DST, export_format='GLB', export_yup=True, export_image_format='AUTO',
	export_texcoords=True, export_normals=True, export_materials='EXPORT', export_animations=False)

tris = {o.name: sum(len(p.vertices) - 2 for p in o.data.polygons) for o in (glass, socket)}
gv = [v.co for v in glass.data.vertices]
sv = [v.co for v in socket.data.vertices]
print("bulb: %d + %d Dreiecke (glass + socket), %.3f m lang" % (tris["glass"], tris["socket"], LENGTH))
print("  Kolben-Durchmesser %.3f m, Glas ab %.3f m" % (2 * max(Vector((p.x, p.y)).length for p in gv), min(p.z for p in gv)))
print("  Sockel-Durchmesser %.3f m, Sockel bis %.3f m" % (2 * max(Vector((p.x, p.y)).length for p in sv), max(p.z for p in sv)))
