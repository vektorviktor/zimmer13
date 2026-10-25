# Baut aus Meshys Puppe (Auto-Rigging mit Skelettvorlage „Mixamo“, GLB mit allen Animationen, Gewichte schon mit
# tools/doll_weights.py getrennt) das Spielmodell assets/models/doll.glb für JuryDoll (Spielkonzept 5.5).
#
# Aufruf (Blender 4.3):
#   python tools/doll_weights.py assets/source/doll_meshy.glb assets/source/doll.glb
#   blender -b --python tools/build_doll.py -- assets/source/doll.glb assets/models/doll.glb [vorschau-ordner]
#
# Was passiert:
# - Knochen ohne „mixamorig:“ (der Doppelpunkt ist in Godot der Pfadtrenner), „headfront“ ohne Gewichte fliegt raus.
#   Meshy liefert sie in Metern (1,7 m, A-Pose) – die Spielgröße stellt JuryDoll.SIZE ein, das Sitzen und Aufstehen
#   dreht JuryDoll an den Knochen (stand_pose). Blick nach +Z (glTF) wie bei Meshy, Füße auf 0.
# - Animationen von Meshy: „walk“, „run“ (vorerst ungenutzt, die Puppe läuft nie).
# - Nur die Farbtextur (Lücken gefüllt, 1024²), in Godot unkomprimiert.
import bpy, sys, os, math
from mathutils import Matrix, Vector
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import meshy_tex

TEX_SIZE = 1024
## Meshys Animationsnamen (Anfang, klein) → unsere
MESHY_ANIMS = {"walking": "walk", "running": "run"}

argv = sys.argv[sys.argv.index("--") + 1:]
SRC, DST = argv[0], argv[1]
PREVIEW = argv[2] if len(argv) > 2 else ""
NAME = os.path.splitext(os.path.basename(DST))[0]

# --- Laden, aufräumen --------------------------------------------------------------------------
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=SRC)
scene = bpy.context.scene
for o in list(scene.objects):
	if o.type == 'MESH' and not o.vertex_groups:
		bpy.data.objects.remove(o)   # Meshys Hilfskugel (falls dabei)
arm = [o for o in scene.objects if o.type == 'ARMATURE'][0]
body = [o for o in scene.objects if o.type == 'MESH'][0]
arm.name = arm.data.name = "Doll"
body.name = body.data.name = NAME
assert body.matrix_local == Matrix() and body.matrix_parent_inverse == Matrix(), "Netz nicht am Ursprung der Armatur"
assert (arm.matrix_world.to_scale() - Vector((1, 1, 1))).length < 1e-4, "Armatur skaliert (Zentimeter?)"

bpy.context.view_layer.objects.active = arm
bpy.ops.object.mode_set(mode='EDIT')
for eb in list(arm.data.edit_bones):
	if not eb.name.startswith("mixamorig:") and eb.name not in body.vertex_groups:
		arm.data.edit_bones.remove(eb)   # „headfront“ ohne Gewichte
bpy.ops.object.mode_set(mode='OBJECT')
for b in arm.data.bones:
	b.name = b.name.replace("mixamorig:", "")   # benennt Gruppen und Animationskurven mit um
for vg in body.vertex_groups:
	vg.name = vg.name.replace("mixamorig:", "")

actions = {}
for a in bpy.data.actions:
	for prefix, key in MESHY_ANIMS.items():
		if a.name.lower().startswith(prefix):
			a.name = key
			actions[key] = a
assert len(actions) == len(MESHY_ANIMS), "Meshy-Animationen fehlen: %s" % [a.name for a in bpy.data.actions]
for track in list(arm.animation_data.nla_tracks):
	arm.animation_data.nla_tracks.remove(track)
arm.animation_data.action = None
for pb in arm.pose.bones:
	pb.matrix_basis = Matrix()
bones = arm.data.bones
bpy.context.view_layer.update()
# glTF +Z = Blender −Y: Zehen müssen nach −Y zeigen
assert (bones["LeftToeBase"].tail_local - bones["LeftFoot"].head_local).y < 0, "Blickrichtung nicht +Z"

# --- Material: nur Farbtextur ------------------------------------------------------------------
mat = body.data.materials[0]
nodes = mat.node_tree.nodes
bsdf = [n for n in nodes if n.type == 'BSDF_PRINCIPLED'][0]
base = [l.from_node for l in bsdf.inputs["Base Color"].links][0]
for n in list(nodes):
	if n.type in ('TEX_IMAGE', 'NORMAL_MAP', 'SEPARATE_COLOR', 'SEPRGB') and n != base:
		nodes.remove(n)   # Normalen-, Rauheits- und Metallkarte braucht der PS1-Look nicht
bsdf.inputs["Metallic"].default_value = 0.0
bsdf.inputs["Roughness"].default_value = 1.0
meshy_tex.shrink(base.image, TEX_SIZE)
base.image.name = NAME

# --- Animationen, Export -----------------------------------------------------------------------
for k, a in actions.items():   # jede Animation als eigene NLA-Spur, damit der Exporter alle mitnimmt
	track = arm.animation_data.nla_tracks.new()
	track.name = k
	track.strips.new(k, int(a.frame_range[0]), a)
mesh = body.data
zs = [v.co.z for v in mesh.vertices]
print("DOLL: %d Dreiecke, %.2f m hoch (Füße %.3f), Hüfte %.2f m, Animationen %s"
	% (sum(len(p.vertices) - 2 for p in mesh.polygons), max(zs), min(zs), bones["Hips"].head_local.z, sorted(actions)))

bpy.ops.export_scene.gltf(
	filepath=DST, export_format='GLB', export_yup=True, export_apply=False,
	export_skins=True, export_animations=True, export_animation_mode='NLA_TRACKS',
	export_morph=False, export_cameras=False, export_lights=False,
	export_image_format='AUTO')   # PNG: JPEG färbt die Inselränder (Farbunterabtastung)
meshy_tex.write_import(DST)   # Textur in Godot unkomprimiert (sonst helle Streifen an den Nähten)

# --- Vorschau ------------------------------------------------------------------------------------
if PREVIEW:
	os.makedirs(PREVIEW, exist_ok=True)
	for tr in arm.animation_data.nla_tracks:
		tr.mute = True
	for pb in arm.pose.bones:   # der Exporter lässt die zuletzt abgetastete Pose stehen
		pb.matrix_basis = Matrix()
	height = max(zs)
	scene.render.engine = 'BLENDER_WORKBENCH'
	scene.display.shading.light = 'FLAT'
	scene.display.shading.color_type = 'TEXTURE'
	scene.render.resolution_x, scene.render.resolution_y = 420, 560
	cd = bpy.data.cameras.new("cam")
	cd.type = 'ORTHO'
	cd.ortho_scale = height * 1.15
	cam = bpy.data.objects.new("cam", cd)
	scene.collection.objects.link(cam)
	scene.camera = cam
	for name, yaw in (("front", 0.0), ("side", math.pi / 2), ("back", math.pi)):
		d = Vector((math.sin(yaw), -math.cos(yaw), 0.0))   # yaw 0 = von vorn (−Y)
		cam.location = Vector((0, 0, height / 2.0)) + d * 5.0
		cam.rotation_euler = (-d).to_track_quat('-Z', 'Y').to_euler()
		scene.render.filepath = os.path.join(PREVIEW, "rest_%s.png" % name)
		bpy.ops.render.render(write_still=True)
