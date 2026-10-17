# Baut aus dem Sketchfab-Grammophon den spielfertigen Plattenspieler für die Lobby (Spielkonzept 7.1):
# Gehäuse ~32 cm breit, Vorderseite nach −Z, Ursprung mittig unter dem Gehäuse, nur Farbtextur.
# Die Platte war ein Quadrat mit Alpha-Ecken (der PSX-Shader kennt kein Alpha) – sie wird durch eine
# runde Scheibe mit denselben UVs ersetzt und als eigenes Objekt „record“ (Ursprung = Drehachse)
# exportiert, damit sie sich beim Abspielen drehen kann. Alles andere heißt „body“.
#
# Aufruf (Blender 4.3):
#   blender -b --python tools/build_record_player.py -- <sketchfab.glb> assets/models/record_player.glb
import bpy, bmesh, sys, math
from mathutils import Matrix, Vector

CABINET_WIDTH = 0.32    # Meter
RECORD_RADIUS = 16.8    # in Originaleinheiten, die Platte im Quadrat (±18) ist fast so breit
RECORD_Z = 11.6         # Höhe des Plattenquadrats im Original
SEGMENTS = 20
TEX_SIZE = 512

argv = sys.argv[sys.argv.index("--") + 1:]
SRC, DST = argv[0], argv[1]

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=SRC)
body = [o for o in bpy.context.scene.objects if o.type == 'MESH'][0]
body.data.transform(body.matrix_world)
body.parent = None
body.matrix_world = Matrix.Identity(4)
for o in [o for o in bpy.context.scene.objects if o.type != 'MESH']:
	bpy.data.objects.remove(o)
body.name = body.data.name = "body"

# --- Plattenquadrat suchen: UV-Abbildung merken, Quadrat löschen ------------------------------
bm = bmesh.new()
bm.from_mesh(body.data)
uv_layer = bm.loops.layers.uv.active
quad = [f for f in bm.faces if all(abs(v.co.z - RECORD_Z) < 0.05 for v in f.verts)]
assert quad, "Plattenquadrat nicht gefunden"
# Affine Abbildung (x, y) → uv aus einem Dreieck des Quadrats
(a, b, c) = [(l.vert.co.copy(), l[uv_layer].uv.copy()) for l in quad[0].loops][:3]
m = Matrix(((b[0].x - a[0].x, c[0].x - a[0].x), (b[0].y - a[0].y, c[0].y - a[0].y))).inverted()


def uv_at(x, y):
	s, t = m @ Vector((x - a[0].x, y - a[0].y))
	return a[1] + (b[1] - a[1]) * s + (c[1] - a[1]) * t


bmesh.ops.delete(bm, geom=quad, context='FACES')
bm.to_mesh(body.data)
bm.free()

# --- Runde Platte (Ursprung in der Plattenmitte, die Spindel steht bei x = y = 0) ----------------
rm = bpy.data.meshes.new("record")
bm = bmesh.new()
uv_layer = bm.loops.layers.uv.new()
center = bm.verts.new((0, 0, 0))
ring = [bm.verts.new((math.cos(i * math.tau / SEGMENTS) * RECORD_RADIUS,
		math.sin(i * math.tau / SEGMENTS) * RECORD_RADIUS, 0)) for i in range(SEGMENTS)]
for i in range(SEGMENTS):
	f = bm.faces.new((center, ring[i], ring[(i + 1) % SEGMENTS]))
	for l in f.loops:
		l[uv_layer].uv = uv_at(l.vert.co.x, l.vert.co.y)
bm.to_mesh(rm)
bm.free()
rm.materials.append(body.data.materials[0])
record = bpy.data.objects.new("record", rm)
bpy.context.scene.collection.objects.link(record)

# --- Ausrichten und skalieren: 180° um Z (Vorderseite −Y → +Y = glTF −Z), Unterkante auf 0 ------
zmin = min(v.co.z for v in body.data.vertices)
xs = [v.co.x for v in body.data.vertices if v.co.z < zmin + 1.0]
scale = CABINET_WIDTH / (max(xs) - min(xs))
fix = Matrix.Scale(scale, 4) @ Matrix.Rotation(math.pi, 4, 'Z') @ Matrix.Translation((0, 0, -zmin))
body.data.transform(fix)
record.data.transform(Matrix.Scale(scale, 4))
record.location = fix @ Vector((0, 0, RECORD_Z + 0.05))
vs = [v.co for v in body.data.vertices]
print("Plattenspieler: %.2f × %.2f m, %.2f m hoch, Platte bei %.3f m" % (
	max(v.x for v in vs) - min(v.x for v in vs), max(v.y for v in vs) - min(v.y for v in vs),
	max(v.z for v in vs), record.location.z))
print("Grenzen x %.3f … %.3f, glTF z %.3f … %.3f" % (
	min(v.x for v in vs), max(v.x for v in vs), -max(v.y for v in vs), -min(v.y for v in vs)))

# --- Material: nur Farbtextur, undurchsichtig -------------------------------------------------
for mat in bpy.data.materials:
	if not mat.use_nodes:
		continue
	nodes = mat.node_tree.nodes
	bsdf = [n for n in nodes if n.type == 'BSDF_PRINCIPLED'][0]
	for n in list(nodes):
		if n.type in ('TEX_IMAGE', 'NORMAL_MAP', 'SEPARATE_COLOR', 'SEPRGB') and not any(
				l.to_socket == bsdf.inputs['Base Color'] for o in n.outputs for l in o.links):
			nodes.remove(n)
	for l in list(bsdf.inputs['Alpha'].links):
		mat.node_tree.links.remove(l)
	mat.blend_method = 'OPAQUE'
	bsdf.inputs['Metallic'].default_value = 0.0
	bsdf.inputs['Roughness'].default_value = 1.0
	for n in nodes:
		if n.type == 'TEX_IMAGE':
			n.image.name = "record_player"
			n.image.scale(TEX_SIZE, TEX_SIZE)

bpy.ops.export_scene.gltf(
	filepath=DST, export_format='GLB', export_yup=True, export_apply=False,
	export_skins=False, export_animations=False, export_morph=False, export_cameras=False,
	export_lights=False, export_image_format='JPEG', export_jpeg_quality=85)
