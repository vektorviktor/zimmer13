# Baut aus dem Kürbismann (Meshy, Kürbiskopf mit Axt; Skelett vorher mit tools/smartrig_to_mixamo.py auf
# Mixamo umgebaut) das Spielmodell assets/models/pumpkin_man.glb – vorerst nur als Testfigur (Debug --pumpkin).
#
# Aufruf (Blender 4.3):
#   blender -b --python tools/build_pumpkin.py -- assets/source/pumpkin_man.glb assets/models/pumpkin_man.glb [vorschau-ordner]
#
# Was passiert:
# - Knochen ohne „mixamorig:“ (der Doppelpunkt ist in Godot der Pfadtrenner), Blick nach −Z, Füße auf 0,
#   Größe bleibt (1,70 m). Die Axt hängt fest an LeftHand.
# - Nur die Farbtextur, TEX_SIZE (Normalen- und Rauheitskarte braucht der PS1-Look nicht).
# - Jede Mixamo-FBX aus assets/source/anim/ als Animation <name> (tools/mixamo_retarget.py, wie bei den Gästen).
import bpy, sys, os, math
from mathutils import Matrix, Vector
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import mixamo_retarget

TEX_SIZE = 1024

argv = sys.argv[sys.argv.index("--") + 1:]
SRC, DST = argv[0], argv[1]
PREVIEW = argv[2] if len(argv) > 2 else ""
NAME = os.path.splitext(os.path.basename(DST))[0]

# --- Laden, umbenennen, umdrehen --------------------------------------------------------------
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=SRC)
scene = bpy.context.scene
arm = [o for o in scene.objects if o.type == 'ARMATURE'][0]
body = [o for o in scene.objects if o.type == 'MESH'][0]
arm.name = arm.data.name = "PumpkinMan"
body.name = body.data.name = NAME
for b in arm.data.bones:
	b.name = b.name.replace("mixamorig:", "")   # benennt die Gewichtsgruppen mit um
for vg in body.vertex_groups:
	vg.name = vg.name.replace("mixamorig:", "")

# Meshy schaut nach −Y (Blender), das Spiel nach +Y (= glTF −Z)
turn = Matrix.Rotation(math.pi, 4, 'Z')
bpy.context.view_layer.objects.active = arm
bpy.ops.object.mode_set(mode='EDIT')
for eb in arm.data.edit_bones:
	eb.transform(turn)
bpy.ops.object.mode_set(mode='OBJECT')
body.data.transform(turn)
body.data.update()
bones = arm.data.bones
assert bones["LeftToe_End"].head_local.y > bones["LeftFoot"].head_local.y, "Blickrichtung falsch"

# --- Material: nur Farbtextur ------------------------------------------------------------------
mat = body.data.materials[0]
bsdf = [n for n in mat.node_tree.nodes if n.type == 'BSDF_PRINCIPLED'][0]
for socket in ("Normal", "Metallic", "Roughness"):
	for link in list(bsdf.inputs[socket].links):
		mat.node_tree.links.remove(link)
bsdf.inputs["Metallic"].default_value = 0.0
bsdf.inputs["Roughness"].default_value = 1.0
for n in [n for n in mat.node_tree.nodes if n.type in ('TEX_IMAGE', 'NORMAL_MAP', 'SEPARATE_COLOR') and not n.outputs[0].links]:
	mat.node_tree.nodes.remove(n)
img = [l.from_node for l in bsdf.inputs["Base Color"].links][0].image
img.scale(TEX_SIZE, TEX_SIZE)
tris = sum(len(p.vertices) - 2 for p in body.data.polygons)

# --- Mixamo-Animationen -------------------------------------------------------------------------
actions = mixamo_retarget.retarget_all(arm)
for pb in arm.pose.bones:
	pb.matrix_basis = Matrix()
scene.frame_set(0)
arm.animation_data_create()
for k, a in actions.items():
	track = arm.animation_data.nla_tracks.new()
	track.name = k
	track.strips.new(k, int(a.frame_range[0]), a)
top = max(v.co.z for v in body.data.vertices)
print("PUMPKIN: %d Dreiecke, %.2f m hoch, Animationen %s" % (tris, top, sorted(actions)))

bpy.ops.export_scene.gltf(
	filepath=DST, export_format='GLB', export_yup=True, export_apply=False,
	export_skins=True, export_animations=True, export_animation_mode='NLA_TRACKS',
	export_morph=False, export_cameras=False, export_lights=False, export_image_format='AUTO')

# --- Vorschau ------------------------------------------------------------------------------------
if PREVIEW:
	os.makedirs(PREVIEW, exist_ok=True)
	for t in arm.animation_data.nla_tracks:
		t.mute = True
	for pb in arm.pose.bones:   # der Exporter lässt die zuletzt abgetastete Pose stehen
		pb.matrix_basis = Matrix()
	scene.render.engine = 'BLENDER_WORKBENCH'
	scene.display.shading.light = 'FLAT'
	scene.display.shading.color_type = 'TEXTURE'
	scene.render.resolution_x, scene.render.resolution_y = 420, 560
	cd = bpy.data.cameras.new("cam")
	cd.type = 'ORTHO'
	cd.ortho_scale = 2.1
	cam = bpy.data.objects.new("cam", cd)
	scene.collection.objects.link(cam)
	scene.camera = cam

	def shot(name, yaw=0.0):
		d = Vector((math.sin(yaw), math.cos(yaw), 0.0))   # yaw 0 = von vorn (+Y)
		cam.location = Vector((0, 0, 0.95)) + d * 5.0
		cam.rotation_euler = (-d).to_track_quat('-Z', 'Y').to_euler()
		scene.render.filepath = os.path.join(PREVIEW, name + ".png")
		bpy.ops.render.render(write_still=True)

	shot("rest_front")
	shot("rest_side", math.pi / 2)
	for k, a in actions.items():
		arm.animation_data.action = a
		f0, f1 = a.frame_range
		for i, t in enumerate((0.0, 0.25, 0.5)):
			scene.frame_set(int(f0 + (f1 - f0) * t))
			shot("%s_%d" % (k, i), 0.5)
	arm.animation_data.action = None
