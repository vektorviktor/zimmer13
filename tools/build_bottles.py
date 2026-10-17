# Baut aus dem Sketchfab-Flaschenpaket (28 Flaschen nebeneinander, in Zentimetern) spielfertige
# Einzelflaschen für die Hotelbar (Spielkonzept 6.10): jede Flasche ein eigenes Objekt „bottle_NN“,
# Ursprung mittig auf der Unterseite, in Metern, nur Farbtextur (verkleinert).
#
# Aufruf (Blender 4.3):
#   blender -b --python tools/build_bottles.py -- <paket.glb> assets/models/bottles.glb
import bpy, sys
from mathutils import Matrix, Vector

TYPICAL_HEIGHT = 0.30   # Höhe der häufigsten Flaschenform (Wein, Whisky) in Metern
TEX_SIZE = 512

argv = sys.argv[sys.argv.index("--") + 1:]
SRC, DST = argv[0], argv[1]

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=SRC)
meshes = sorted([o for o in bpy.context.scene.objects if o.type == 'MESH'], key=lambda o: o.name)

# Weltlage in die Meshdaten übernehmen, Hilfsknoten aus dem FBX-Export löschen
for o in meshes:
	o.data.transform(o.matrix_world)
	o.parent = None
	o.matrix_world = Matrix.Identity(4)
for o in [o for o in bpy.context.scene.objects if o.type != 'MESH']:
	bpy.data.objects.remove(o)

# Maßstab: die mittlere Flaschenhöhe des Pakets entspricht TYPICAL_HEIGHT
heights = sorted(max(v.co.z for v in o.data.vertices) - min(v.co.z for v in o.data.vertices) for o in meshes)
scale = TYPICAL_HEIGHT / heights[len(heights) // 2]

for i, o in enumerate(meshes):
	vs = [v.co for v in o.data.vertices]
	lo = Vector((min(v.x for v in vs), min(v.y for v in vs), min(v.z for v in vs)))
	hi = Vector((max(v.x for v in vs), max(v.y for v in vs), max(v.z for v in vs)))
	base = Vector(((lo.x + hi.x) / 2, (lo.y + hi.y) / 2, lo.z))
	o.data.transform(Matrix.Scale(scale, 4) @ Matrix.Translation(-base))
	o.name = o.data.name = "bottle_%02d" % i
	print("%s  %.2f m hoch, Ø %.2f m" % (o.name, (hi.z - lo.z) * scale, max(hi.x - lo.x, hi.y - lo.y) * scale))

# Material: nur Farbtextur (der PSX-Shader nutzt weder Normal- noch Metallic-Karte)
for mat in bpy.data.materials:
	if not mat.use_nodes:
		continue
	nodes = mat.node_tree.nodes
	bsdf = [n for n in nodes if n.type == 'BSDF_PRINCIPLED'][0]
	for n in list(nodes):
		if n.type in ('TEX_IMAGE', 'NORMAL_MAP') and not any(
				l.to_socket == bsdf.inputs['Base Color'] for o in n.outputs for l in o.links):
			nodes.remove(n)
	bsdf.inputs['Metallic'].default_value = 0.0
	bsdf.inputs['Roughness'].default_value = 1.0
	for n in nodes:
		if n.type == 'TEX_IMAGE':
			n.image.name = "bottles"
			n.image.scale(TEX_SIZE, TEX_SIZE)

bpy.ops.export_scene.gltf(
	filepath=DST, export_format='GLB', export_yup=True, export_apply=False,
	export_skins=False, export_animations=False, export_morph=False, export_cameras=False,
	export_lights=False, export_image_format='JPEG', export_jpeg_quality=85)
