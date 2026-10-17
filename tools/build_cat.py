# Baut aus Meshys Katzen-Paket (Auto-Rigging-Preset „Hund“) die spielfertige Hotelkatze (Spielkonzept 6.11):
# Gewichte der Beine korrigiert, ~0,34 m hoch (bis zu den Ohren), Blick nach −Z, Pfoten auf y = 0,
# nur Farbtextur (verkleinert), Laufanimation als „walk“.
#
# Aufruf (Blender 4.3):
#   blender -b --python tools/build_cat.py -- <meshy.zip> assets/models/cat.glb [vorschau-ordner]
#
# Meshys Auto-Rigging hat Teile eines Beins an die Knochen des anderen Beins gehängt (die Vorderläufe
# stehen im Modell dicht beieinander) – beim Laufen zieht dann ein Bein das Fell des anderen mit.
# Korrektur: Jeder Punkt gehört zur Seite des nächstgelegenen Beinknochens; Gewichte an Knochen der
# anderen Seite wandern zum gleichnamigen Knochen dieser Seite.
#
# Größe und Drehung stehen nur am Wurzelobjekt der Armatur. Angewendet (transform_apply) würden die
# Translations-Schlüssel der Animation nicht mitskaliert – die Katze spränge dann beim Laufen.
import bpy, sys, os, math, zipfile, tempfile
from mathutils import Matrix, Vector
from mathutils.geometry import intersect_point_line

TARGET_HEIGHT = 0.34    # Meter, Pfoten bis Ohrspitzen
TEX_SIZE = 512
## Ist ein Punkt beiden Beinen fast gleich nah, bleibt er, wie er ist (Anteil am kleineren Abstand)
SIDE_MARGIN = 0.15
ZIP_MEMBER = "_Animation_Walking_withSkin.glb"   # enthält Netz, Rig und Laufen (die Ruhepose ist das Rig)

argv = sys.argv[sys.argv.index("--") + 1:]
SRC, DST = argv[0], argv[1]
PREVIEW = argv[2] if len(argv) > 2 else ""

# --- Laden -------------------------------------------------------------------------------------
tmp = tempfile.mkdtemp()
with zipfile.ZipFile(SRC) as z:
	member = [n for n in z.namelist() if n.endswith(ZIP_MEMBER)][0]
	glb = z.extract(member, tmp)
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=glb)
arm = [o for o in bpy.context.scene.objects if o.type == 'ARMATURE'][0]
body = [o for o in bpy.context.scene.objects if o.type == 'MESH'][0]
arm.name = "Cat"
body.name = body.data.name = "cat"
scene = bpy.context.scene

# --- Beingewichte nach Seite trennen ---------------------------------------------------------
to_arm = arm.matrix_world.inverted() @ body.matrix_world
groups = {g.name: g for g in body.vertex_groups}


def seg_dist(p, bone):
	_, t = intersect_point_line(p, bone.head_local, bone.tail_local)
	q = bone.head_local.lerp(bone.tail_local, min(max(t, 0.0), 1.0))
	return (p - q).length


chains = {}
for part in ("frontleg", "backleg"):
	for side, prefix in (("L", ""), ("R", "R_")):
		chains[(part, side)] = [arm.data.bones[prefix + part + s] for s in ("0", "1", "2")]
moves = []
for v in body.data.vertices:
	p = to_arm @ v.co
	for g in v.groups:
		name = body.vertex_groups[g.group].name
		if "leg" not in name or g.weight <= 0.0:
			continue
		part = "frontleg" if "front" in name else "backleg"
		dl = min(seg_dist(p, b) for b in chains[(part, "L")])
		dr = min(seg_dist(p, b) for b in chains[(part, "R")])
		if abs(dl - dr) < SIDE_MARGIN * min(dl, dr):
			continue
		near = "L" if dl < dr else "R"
		if ("R" if name.startswith("R_") else "L") != near:
			moves.append((v.index, name, g.weight))
for index, name, weight in moves:
	twin = name[2:] if name.startswith("R_") else "R_" + name
	groups[twin].add([index], weight, 'ADD')
	groups[name].remove([index])
print("Beingewichte umgehängt: %d" % len(moves))
bpy.context.view_layer.objects.active = body
bpy.ops.object.vertex_group_normalize_all(lock_active=False)

# --- Größe, Blickrichtung, Boden ------------------------------------------------------------
action = arm.animation_data.action
action.name = "walk"
for track in arm.animation_data.nla_tracks:   # der Exporter benennt die Animation nach der NLA-Spur
	track.name = "walk"
	for strip in track.strips:
		strip.name = "walk"
arm.animation_data.action = None   # Ruhepose messen


def evaluated_bounds():
	bpy.context.view_layer.update()
	ev = body.evaluated_get(bpy.context.evaluated_depsgraph_get())
	pts = [ev.matrix_world @ v.co for v in ev.to_mesh().vertices]
	lo = Vector([min(p[i] for p in pts) for i in range(3)])
	hi = Vector([max(p[i] for p in pts) for i in range(3)])
	ev.to_mesh_clear()
	return lo, hi


lo, hi = evaluated_bounds()
arm.scale *= TARGET_HEIGHT / (hi.z - lo.z)
# Kopf soll nach glTF −Z = Blender +Y schauen
bpy.context.view_layer.update()
head = arm.matrix_world @ arm.data.bones["head"].tail_local
hips = arm.matrix_world @ arm.data.bones["Hips"].head_local
if head.y < hips.y:
	arm.rotation_mode = 'XYZ'
	arm.rotation_euler.z += math.pi
lo, hi = evaluated_bounds()
arm.location -= Vector(((lo.x + hi.x) / 2.0, (lo.y + hi.y) / 2.0, lo.z))
lo, hi = evaluated_bounds()
print("Katze: %.2f m lang (mit Schwanz), %.2f m breit, %.2f m hoch" % (hi.y - lo.y, hi.x - lo.x, hi.z - lo.z))
arm.animation_data.action = action

# --- Material: nur Farbtextur ---------------------------------------------------------------
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
	# Meshy liefert eine Leuchtkarte mit – ohne sie bliebe die Emission weiß und die Katze glühte
	bsdf.inputs['Emission Color'].default_value = (0.0, 0.0, 0.0, 1.0)
	bsdf.inputs['Emission Strength'].default_value = 0.0
	for n in nodes:
		if n.type == 'TEX_IMAGE':
			n.image.name = "cat_fur"
			n.image.scale(TEX_SIZE, TEX_SIZE)

bpy.ops.export_scene.gltf(
	filepath=DST, export_format='GLB', export_yup=True, export_apply=False,
	export_skins=True, export_animations=True, export_animation_mode='ACTIONS',
	export_morph=False, export_cameras=False, export_lights=False,
	export_image_format='JPEG', export_jpeg_quality=85)

# --- Vorschau: Ruhepose und vier Bilder des Laufzyklus ---------------------------------------
if PREVIEW:
	os.makedirs(PREVIEW, exist_ok=True)
	scene.render.engine = 'BLENDER_WORKBENCH'
	scene.display.shading.light = 'STUDIO'
	scene.display.shading.color_type = 'TEXTURE'
	scene.render.resolution_x, scene.render.resolution_y = 500, 400
	cam_data = bpy.data.cameras.new("cam")
	cam_data.clip_start = 0.01
	cam = bpy.data.objects.new("cam", cam_data)
	scene.collection.objects.link(cam)
	scene.camera = cam
	center = (lo + hi) / 2.0
	cam.location = center + Vector((0.9, 1.0, 0.35)).normalized() * 1.1
	cam.rotation_euler = (center - cam.location).to_track_quat('-Z', 'Y').to_euler()
	start, end = action.frame_range
	for k, t in enumerate((0.0, 0.25, 0.5, 0.75)):
		scene.frame_set(int(start + (end - start) * t))
		scene.render.filepath = os.path.join(PREVIEW, "cat_walk_%d.png" % k)
		bpy.ops.render.render(write_still=True)
