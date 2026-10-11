# Baut aus dem Meshy-Modell das spielfertige Monster (Spielkonzept 4):
# reduziert, nach −Z gedreht, auf ~2,1 m skaliert, mit Skelett, aufrecht als Grundpose
# und der ursprünglichen Hocke als Animation „crouch“ (ein einziges Bild).
#
# Aufruf (Blender 4.3):
#   blender -b --python tools/build_monster.py -- <meshy.glb> assets/models/monster.glb [vorschau-ordner]
#
# Koordinaten unten sind im Meshy-Original abgelesen (Blender: Z oben, Kopf bei −Y).
import bpy, sys, math
from mathutils import Vector, Matrix

TARGET_TRIS = 8000
SCALE = 1.15          # aufrecht ~2,1 m (Kopf), gestreckt mehr
TEX_SIZE = 512

argv = sys.argv[sys.argv.index("--") + 1:]
SRC, DST = argv[0], argv[1]
PREVIEW = argv[2] if len(argv) > 2 else ""


def P(x, y, z):
	## Original → Spiel: 180° um Z (Kopf nach +Y = glTF −Z) und skalieren
	return Vector((-x * SCALE, -y * SCALE, z * SCALE))


def Dir(x, y, z):
	return Vector((-x, -y, z)).normalized()


# --- Mesh vorbereiten ------------------------------------------------------------------
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=SRC)
ob = [o for o in bpy.context.scene.objects if o.type == 'MESH'][0]
ob.name = "Monster"
bpy.context.view_layer.objects.active = ob
ob.select_set(True)
# glTF trennt Punkte an UV-Nähten – zusammenführen, sonst reißt das Mesh beim Reduzieren
bpy.ops.object.mode_set(mode='EDIT')
bpy.ops.mesh.select_all(action='SELECT')
bpy.ops.mesh.remove_doubles(threshold=0.0001)
bpy.ops.object.mode_set(mode='OBJECT')
dec = ob.modifiers.new("decimate", 'DECIMATE')
dec.ratio = TARGET_TRIS / sum(len(p.vertices) - 2 for p in ob.data.polygons)
bpy.ops.object.modifier_apply(modifier=dec.name)
ob.data.transform(Matrix.Rotation(math.pi, 4, 'Z') @ Matrix.Scale(SCALE, 4))
orig_zmin = min(v.co.z for v in ob.data.vertices)

# Material: nur Farbtextur (der PSX-Shader nutzt weder Normal- noch Metallic-Karte)
mat = ob.data.materials[0]
mat.use_backface_culling = True
nodes = mat.node_tree.nodes
bsdf = [n for n in nodes if n.type == 'BSDF_PRINCIPLED'][0]
for n in list(nodes):
	if n.type in ('TEX_IMAGE', 'NORMAL_MAP', 'SEPARATE_COLOR', 'SEPRGB') and not any(
			l.to_socket == bsdf.inputs['Base Color'] for o in n.outputs for l in o.links):
		nodes.remove(n)
bsdf.inputs['Metallic'].default_value = 0.0
bsdf.inputs['Roughness'].default_value = 1.0
for n in nodes:
	if n.type == 'TEX_IMAGE':
		n.image.name = "monster_skin"
		n.image.scale(TEX_SIZE, TEX_SIZE)

# --- Skelett (Original-Koordinaten) -----------------------------------------------------
BONES = {}  # name: (kopf, spitze, eltern)


def bone(name, head, tail, parent=None):
	BONES[name] = (P(*head), P(*tail), parent)


bone("hips", (0, 0.30, 0.16), (0, 0.12, 0.28))
bone("spine", (0, 0.12, 0.28), (0, -0.10, 0.32), "hips")
bone("chest", (0, -0.10, 0.32), (0, -0.30, 0.26), "spine")
bone("neck", (0, -0.30, 0.26), (0, -0.44, 0.20), "chest")
bone("head", (0, -0.44, 0.20), (0, -0.80, 0.14), "neck")
bone("jaw", (0, -0.50, 0.10), (0, -0.66, -0.12), "head")
bone("tongue1", (0, -0.56, 0.0), (0, -0.72, -0.06), "jaw")
bone("tongue2", (0, -0.72, -0.06), (0, -0.92, -0.06), "tongue1")
# Das Original ist gedreht – die linke Körperseite des Monsters liegt danach bei −X.
for s, sx in (("L", 1), ("R", -1)):
	bone("shoulder." + s, (sx * 0.06, -0.28, 0.26), (sx * 0.19, -0.36, 0.16), "chest")
	bone("upperarm." + s, (sx * 0.19, -0.36, 0.16), (sx * 0.24, -0.12, -0.11), "shoulder." + s)
	bone("forearm." + s, (sx * 0.24, -0.12, -0.11), (sx * 0.26, -0.48, -0.38), "upperarm." + s)
	bone("hand." + s, (sx * 0.26, -0.48, -0.38), (sx * 0.26, -0.66, -0.44), "forearm." + s)
bone("thigh.L", (0.12, 0.28, 0.10), (0.20, -0.04, -0.09), "hips")
bone("shin.L", (0.20, -0.04, -0.09), (0.22, 0.36, -0.30), "thigh.L")
bone("foot.L", (0.22, 0.36, -0.30), (0.24, 0.20, -0.43), "shin.L")
bone("toe.L", (0.24, 0.20, -0.43), (0.24, 0.02, -0.45), "foot.L")
bone("thigh.R", (-0.12, 0.30, 0.10), (-0.19, 0.36, -0.26), "hips")
bone("shin.R", (-0.19, 0.36, -0.26), (-0.16, 0.86, -0.20), "thigh.R")
bone("foot.R", (-0.16, 0.86, -0.20), (-0.16, 0.84, -0.42), "shin.R")
bone("toe.R", (-0.16, 0.84, -0.42), (-0.16, 0.70, -0.46), "foot.R")
EYES = [P(0.07, -0.70, 0.15), P(-0.07, -0.70, 0.15)]

# Aufrecht: Richtung jedes Knochens (Original-Achsen, werden mitgedreht)
STAND = {
	"hips": (0, -0.1, 1), "spine": (0, -0.25, 1), "chest": (0, -0.45, 1), "neck": (0, -0.8, 0.7),
	"head": (0, -1, 0.05), "jaw": (0, -0.5, -1), "tongue1": (0, -1, -0.5), "tongue2": (0, -1, -0.6),
	"thigh.L": (0.05, -0.35, -1), "shin.L": (0, 0.45, -1), "foot.L": (0, -0.15, -1), "toe.L": (0, -1, -0.1),
	"thigh.R": (-0.05, -0.35, -1), "shin.R": (0, 0.45, -1), "foot.R": (0, -0.15, -1), "toe.R": (0, -1, -0.1),
}
for s, sx in (("L", 1), ("R", -1)):
	STAND["shoulder." + s] = (sx, 0, -0.3)
	STAND["upperarm." + s] = (sx * 0.2, -0.05, -1)
	STAND["forearm." + s] = (sx * 0.05, -0.35, -1)
	STAND["hand." + s] = (0, -0.2, -1)

arm = bpy.data.armatures.new("MonsterRig")
rig = bpy.data.objects.new("MonsterRig", arm)
bpy.context.scene.collection.objects.link(rig)
bpy.context.view_layer.objects.active = rig
bpy.ops.object.mode_set(mode='EDIT')
for name, (h, t, _p) in BONES.items():
	eb = arm.edit_bones.new(name)
	eb.head, eb.tail, eb.roll = h, t, 0.0
for name, (h, _t, p) in BONES.items():
	if p:
		eb = arm.edit_bones[name]
		eb.parent = arm.edit_bones[p]
		eb.use_connect = (h - arm.edit_bones[p].tail).length < 1e-4
bpy.ops.object.mode_set(mode='OBJECT')

bpy.ops.object.select_all(action='DESELECT')
ob.select_set(True)
rig.select_set(True)
bpy.context.view_layer.objects.active = rig
bpy.ops.object.parent_set(type='ARMATURE_AUTO')
unweighted = sum(1 for v in ob.data.vertices if not any(g.weight > 0.01 for g in v.groups))
assert unweighted == 0, f"{unweighted} Punkte ohne Knochen"

ORIG = {b.name: b.matrix_local.copy() for b in arm.bones}
ORDER = [b.name for b in arm.bones]   # Eltern vor Kindern


def pose_dirs(dirs):
	## Jeden Knochen in eine Welt-Richtung drehen (Kopf bleibt am Elternknochen)
	def walk(name):
		pb = rig.pose.bones[name]
		bpy.context.view_layer.update()
		m = pb.matrix.copy()
		q = (pb.tail - pb.head).normalized().rotation_difference(Dir(*dirs[name]))
		new = q.to_matrix().to_4x4() @ m.to_3x3().to_4x4()
		new.translation = m.translation
		pb.matrix = new
		for c in pb.children:
			walk(c.name)
	walk("hips")
	bpy.context.view_layer.update()


bpy.ops.object.mode_set(mode='POSE')
pose_dirs(STAND)
head_delta = rig.pose.bones["head"].matrix @ ORIG["head"].inverted()
eyes = [head_delta @ e for e in EYES]
bpy.ops.object.mode_set(mode='OBJECT')

# Aufrechte Pose wird zur Grundpose: Mesh verformt übernehmen, Pose als Ruhepose setzen
bpy.context.view_layer.objects.active = ob
bpy.ops.object.modifier_apply(modifier=ob.modifiers[0].name)
bpy.context.view_layer.objects.active = rig
bpy.ops.object.mode_set(mode='POSE')
bpy.ops.pose.select_all(action='SELECT')
bpy.ops.pose.armature_apply(selected=False)
bpy.ops.object.mode_set(mode='OBJECT')

# Füße auf den Boden, Ursprung zwischen den Füßen
feet = (arm.bones["toe.L"].head_local + arm.bones["toe.R"].head_local) / 2.0
off = Vector((-feet.x, -feet.y, -min(v.co.z for v in ob.data.vertices)))
ob.data.transform(Matrix.Translation(off))
arm.transform(Matrix.Translation(off))
mod = ob.modifiers.new("Armature", 'ARMATURE')
mod.object = rig
eyes = [e + off for e in eyes]
top = max(v.co.z for v in ob.data.vertices)

# Hocke = ursprüngliche Pose, mit den Füßen wieder auf dem Boden
crouch_shift = Matrix.Translation(off + Vector((0, 0, -(orig_zmin + off.z))))
bpy.context.view_layer.objects.active = rig
bpy.ops.object.mode_set(mode='POSE')
for pb in rig.pose.bones:
	pb.rotation_mode = 'QUATERNION'
for name in ORDER:
	rig.pose.bones[name].matrix = crouch_shift @ ORIG[name]
	bpy.context.view_layer.update()
	diff = rig.pose.bones[name].matrix - crouch_shift @ ORIG[name]
	assert max(abs(x) for row in diff for x in row) < 0.01, "Hocke für %s falsch" % name
action = bpy.data.actions.new("crouch")
rig.animation_data_create().action = action
for pb in rig.pose.bones:
	pb.keyframe_insert("rotation_quaternion", frame=1)
	pb.keyframe_insert("location", frame=1)
bpy.ops.object.mode_set(mode='OBJECT')
bpy.context.view_layer.update()

# Ausgabe in Godot-Achsen (x, z, −y)
g = lambda v: "Vector3(%.3f, %.3f, %.3f)" % (v.x, v.z, -v.y)
print("MONSTER top %.2f m, eyes %s / %s" % (top, g(eyes[0]), g(eyes[1])))

bpy.ops.export_scene.gltf(
	filepath=DST, export_format='GLB', export_yup=True, export_apply=False,
	export_skins=True, export_animations=True, export_animation_mode='ACTIONS',
	export_rest_position_armature=True, export_morph=False, export_cameras=False, export_lights=False,
	export_image_format='JPEG', export_jpeg_quality=85)

if PREVIEW:
	sc = bpy.context.scene
	sc.render.engine = 'BLENDER_WORKBENCH'
	sc.render.resolution_x, sc.render.resolution_y = 700, 900
	sc.display.shading.light = 'STUDIO'
	sc.display.shading.color_type = 'TEXTURE'
	cd = bpy.data.cameras.new("cam")
	cam = bpy.data.objects.new("cam", cd)
	sc.collection.objects.link(cam)
	sc.camera = cam
	cd.type = 'ORTHO'
	cd.ortho_scale = 2.8
	for frame, tag in ((1, "crouch"), (None, "stand")):
		if frame is None:
			rig.animation_data.action = None
			for pb in rig.pose.bones:
				pb.matrix_basis = Matrix()
		sc.frame_set(1)
		for view, loc in (("front", (0, 6, 1.2)), ("side", (6, 0, 1.2))):
			cam.location = loc
			cam.rotation_euler = (Vector((0, 0, 1.2)) - Vector(loc)).to_track_quat('-Z', 'Y').to_euler()
			sc.render.filepath = f"{PREVIEW}/{tag}_{view}.png"
			bpy.ops.render.render(write_still=True)
