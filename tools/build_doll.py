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
# - Formschlüssel „sit“: Der Rock liegt beim Sitzen auf den Beinen statt hochzustehen (unten).
import bpy, sys, os, math
from mathutils import Matrix, Vector
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import meshy_tex

TEX_SIZE = 1024
## Meshys Animationsnamen (Anfang, klein) → unsere
MESHY_ANIMS = {"walking": "walk", "running": "run"}
## Rock beim Sitzen (Formschlüssel „sit“, Meter im Modellmaß): Sitzfläche so weit unter dem Hüftgelenk (wie
## JuryDoll.SEAT), Vorderkante des Rocks auf dem Schoß so weit vor der Hüftachse (Oberschenkel ~0,08 dick + Stoff),
## flachgedrückt wird erst so weit unter der Hüfte voll (darüber bleibt der Rock, wie er ist), und nur was so weit
## vom Oberschenkel weg ist (näher ist Bein)
SKIRT_SEAT = 0.08
SKIRT_LAP = 0.12
SKIRT_RAMP = 0.15
SKIRT_THIGH = (0.09, 0.12)

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

# --- Rock beim Sitzen: Formschlüssel „sit“ -----------------------------------------------------
# Der Rock hängt an den Oberschenkeln und dreht beim Sitzen um 90° mit – seine Glocke stünde dann vorn hoch über
# den Knien. „sit“ drückt die Glocke unterhalb der Hüfte zur Sitzfläche hin flach (in Ruhepose: nach hinten, die
# Beine hängen dort ja noch): vorn liegt der Saum dann knapp über den Oberschenkeln, seitlich breitet er sich auf
# der Sitzfläche aus, hinten verschwindet er darunter. JuryDoll.stand_pose blendet ihn mit dem Sitzen ein.
groups = {g.name: g.index for g in body.vertex_groups}
up_legs = (groups["LeftUpLeg"], groups["RightUpLeg"])
hip = (bones["LeftUpLeg"].head_local + bones["RightUpLeg"].head_local) / 2.0
thighs = [(bones[s + "UpLeg"].head_local, bones[s + "Leg"].head_local) for s in ("Left", "Right")]


def thigh_dist(p):
	best = 1.0
	for a, b in thighs:
		t = min(max((p - a).dot(b - a) / (b - a).length_squared, 0.0), 1.0)
		best = min(best, (p - a - (b - a) * t).length)
	return best


def smooth(x, x0, x1):
	t = min(max((x - x0) / (x1 - x0), 0.0), 1.0)
	return t * t * (3.0 - 2.0 * t)


# Lage zur Hüfte: drop = so weit unter dem Hüftgelenk, front = so weit davor (Blender: vorn ist −Y)
skirt = []
for v in body.data.vertices:
	drop = hip.z - v.co.z
	if drop > 0.0 and sum(g.weight for g in v.groups if g.group in up_legs) >= 0.5:
		k = smooth(thigh_dist(v.co), SKIRT_THIGH[0], SKIRT_THIGH[1]) * smooth(drop, 0.0, SKIRT_RAMP)
		if k > 0.0:
			skirt.append((v.index, drop, hip.y - v.co.y, k))
# Vorderkante der Glocke je Höhe (nach unten nie kleiner, sonst welliger Saum)
reach = {}
for _, drop, front, _ in skirt:
	band = int(drop / 0.04)
	reach[band] = max(reach.get(band, 0.0), front)
for band in range(1, max(reach) + 1):
	reach[band] = max(reach.get(band, 0.0), reach.get(band - 1, 0.0))
body.shape_key_add(name="Basis", from_mix=False)
sit = body.shape_key_add(name="sit", from_mix=False)
for i, drop, front, k in skirt:
	edge = max(reach[int(drop / 0.04)], SKIRT_LAP + 0.01)
	squash = 1.0 - k * (1.0 - (SKIRT_LAP + SKIRT_SEAT) / (edge + SKIRT_SEAT))
	sit.data[i].co.y = hip.y - (-SKIRT_SEAT + (front + SKIRT_SEAT) * squash)
print("ROCK: %d Punkte im Formschlüssel „sit“, Vorderkante bis %.2f m vor der Hüfte" % (len(skirt), max(reach.values())))

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
	export_morph=True, export_morph_normal=True, export_cameras=False, export_lights=False,
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
