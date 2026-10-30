# Baut aus dem Kürbismann (Meshy, Auto-Rigging mit Skelettvorlage „Mixamo“, GLB mit allen Animationen) und
# seiner Axt (eigenes Meshy-Modell) das Spielmodell assets/models/pumpkin_man.glb – vorerst nur als Testfigur
# (Debug --pumpkin).
#
# Aufruf (Blender 4.3):
#   blender -b --python tools/build_pumpkin.py -- assets/source/pumpkin_man.glb assets/source/pumpkin_axe.glb assets/models/pumpkin_man.glb [vorschau-ordner]
#
# Was passiert:
# - Knochen ohne „mixamorig:“ (der Doppelpunkt ist in Godot der Pfadtrenner), Meshys Hilfsknochen und
#   die Hilfskugel fliegen raus. Meshy liefert in Zentimetern (Armatur × 0,01) – das Skript rechnet Knochen,
#   Netz und Hüftwege in Meter um und bringt ihn auf HEIGHT (Meshy: 1,63 m). Blick nach −Z, Füße auf 0.
# - Animationen von Meshy: „walk“, „run“, „spin_jump“; dazu jede Mixamo-FBX aus assets/source/anim/ wie bei
#   den Gästen (tools/mixamo_retarget.py) und aus assets/source/anim/pumpkin/ nur für ihn (Axtschlag „attack“ –
#   Beil in der rechten Hand wie bei Mixamos Schlägen – linkshändige dort mit „Mirror“ herunterladen).
# - Die Axt ist ein eigenes, starres Objekt am Knochen <AXE_SIDE>Hand (kein Teil des Körpernetzes): Godot macht daraus
#   ein BoneAttachment3D mit eigenem MeshInstance3D – sie folgt jeder Animation und lässt sich im Spiel einzeln
#   ausblenden oder abnehmen. Ursprung der Axt = Griffpunkt, Stiel entlang +Z (Kopf oben), Schneide −X.
# - Meshys kleines Skelett hat keine Fingerknochen: Die Finger der Axthand werden im Netz um den Stiel
#   gebogen (Faust), die Ruhepose behält das – jede Animation hält die Axt damit in der geschlossenen Hand.
# - Nur die Farbtexturen (Lücken zwischen den UV-Inseln vor dem Verkleinern gefüllt), in Godot unkomprimiert.
import bpy, sys, os, math
import numpy as np
from mathutils import Matrix, Vector, Quaternion
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import mixamo_retarget
import meshy_tex

TEX_SIZE = 1024
AXE_TEX_SIZE = 256
HEIGHT = 2.0              # m, so groß ist er im Spiel (Scheitel des Kürbisses)
AXE_LENGTH = 0.45         # m, Stielende bis Kopf: einhändiges Beil (Meshy liefert ~0,95 m)
GRIP_AT = 0.11            # Griffpunkt: Anteil der Axtlänge vom Stielende (Mitte der Wicklung)
GRIP_TILT = 15.0          # Grad: Stiel schräg durch die Faust, Kopf zur Fingerseite geneigt (wie in echt)
KNUCKLE = 0.47            # Fingeransatz: Anteil der Handlänge (Handgelenk → Fingerspitze) senkrecht zum Stiel
CURL_MAX = 1.6 * math.pi  # weiter krümmen sich die Finger nicht (Spitzen zeigen dann zurück in die Hand)
## Axthand: rechts, weil Mixamos Schläge rechtshändig sind (Meshys Gehen und Rennen sind seitengleich)
AXE_SIDE = "Right"
AXE_ARM = (AXE_SIDE + "Arm", AXE_SIDE + "ForeArm", AXE_SIDE + "Hand")
AXE_SWING = 0.35          # so viel vom Armschwung beim Gehen und Rennen bleibt (die Axt ist schwer)
## Mixamo-FBX nur für den Kürbismann (die Gäste bekommen sie nicht): <name>.fbx → Animation <name>
OWN_ANIM_DIR = os.path.join(mixamo_retarget.ANIM_DIR, "pumpkin")
## Meshys Animationsnamen (Anfang, klein) → unsere
MESHY_ANIMS = {"walking": "walk", "running": "run", "_360_power_spin_jump": "spin_jump"}

argv = sys.argv[sys.argv.index("--") + 1:]
SRC, AXE, DST = argv[0], argv[1], argv[2]
PREVIEW = argv[3] if len(argv) > 3 else ""
NAME = os.path.splitext(os.path.basename(DST))[0]

# --- Laden, aufräumen --------------------------------------------------------------------------
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=SRC)
scene = bpy.context.scene
for o in list(scene.objects):
	if o.type == 'MESH' and not o.vertex_groups:
		bpy.data.objects.remove(o)   # Meshys Hilfskugel
arm = [o for o in scene.objects if o.type == 'ARMATURE'][0]
body = [o for o in scene.objects if o.type == 'MESH'][0]
arm.name = arm.data.name = "PumpkinMan"
body.name = body.data.name = NAME
assert body.matrix_local == Matrix() and body.matrix_parent_inverse == Matrix(), "Netz nicht am Ursprung der Armatur"

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

# --- Meter, Blick nach −Z (glTF) = Blender +Y, Füße auf 0 -------------------------------------------
# Knochen und Netz direkt umrechnen statt die Armatur zu drehen und zu skalieren: Dann hängt die Axt ohne
# Ausgleichsmaßstab an der Hand, und Godot bekommt ein Skelett in Metern.
unit = arm.scale.x
assert arm.matrix_world == Matrix.Scale(unit, 4), "Armatur unerwartet gedreht oder verschoben"
bones = arm.data.bones
turn = Matrix.Rotation(math.pi, 4, 'Z') if (bones["LeftToeBase"].head_local - bones["LeftFoot"].head_local).y < 0 else Matrix()
fix = turn @ Matrix.Scale(unit, 4)
zs = [(fix @ v.co).z for v in body.data.vertices]
unit *= HEIGHT / (max(zs) - min(zs))   # Meter und Spielgröße in einem
fix = turn @ Matrix.Scale(unit, 4)
zmin = min((fix @ v.co).z for v in body.data.vertices)
fix = Matrix.Translation((0, 0, -zmin)) @ fix
bpy.ops.object.mode_set(mode='EDIT')
for eb in arm.data.edit_bones:
	eb.transform(fix)
bpy.ops.object.mode_set(mode='OBJECT')
body.data.transform(fix)
body.data.update()
arm.scale = (1.0, 1.0, 1.0)
for a in actions.values():   # Hüftwege sind in Armatureinheiten gespeichert – mit umrechnen
	for fc in a.fcurves:
		if fc.data_path.endswith(".location"):
			for kp in fc.keyframe_points:
				kp.co.y *= unit
				kp.handle_left.y *= unit
				kp.handle_right.y *= unit
bpy.context.view_layer.update()
assert bones["LeftToeBase"].head_local.y > bones["LeftFoot"].head_local.y, "Blickrichtung falsch"

# --- Material: nur Farbtextur ------------------------------------------------------------------


def color_only(obj, size):
	"""Normalen-, Rauheits- und Metallkarte raus (nutzt das Spiel nicht), Farbtextur auf size."""
	mat = obj.data.materials[0]
	nodes = mat.node_tree.nodes
	bsdf = [n for n in nodes if n.type == 'BSDF_PRINCIPLED'][0]
	base = [l.from_node for l in bsdf.inputs["Base Color"].links][0]
	for n in list(nodes):
		if n.type in ('TEX_IMAGE', 'NORMAL_MAP', 'SEPARATE_COLOR', 'SEPRGB') and n != base:
			nodes.remove(n)
	bsdf.inputs["Metallic"].default_value = 0.0
	bsdf.inputs["Roughness"].default_value = 1.0
	meshy_tex.shrink(base.image, size)
	base.image.name = obj.name


color_only(body, TEX_SIZE)

# --- Axt: laden, Griffpunkt in den Ursprung, auf Länge ---------------------------------------------
before = set(scene.objects)
bpy.ops.import_scene.gltf(filepath=AXE)
axe = [o for o in scene.objects if o not in before and o.type == 'MESH'][0]
for o in [o for o in scene.objects if o not in before and o != axe]:
	bpy.data.objects.remove(o)
axe.name = axe.data.name = "axe"
axe.data.transform(axe.matrix_world)
axe.matrix_world = Matrix()
color_only(axe, AXE_TEX_SIZE)
pts = np.array([v.co for v in axe.data.vertices])
z0, z1 = pts[:, 2].min(), pts[:, 2].max()
size = z1 - z0
grip_z = z0 + GRIP_AT * size
band = pts[np.abs(pts[:, 2] - grip_z) < 0.02 * size]
cx, cy = band[:, 0].mean(), band[:, 1].mean()
k = AXE_LENGTH / size
handle_r = float(np.hypot(band[:, 0] - cx, band[:, 1] - cy).mean()) * k
head = pts[pts[:, 2] > z1 - 0.3 * size]
blade = -1.0 if head[:, 0].mean() < cx else 1.0   # Schneide auf der Seite mit mehr Kopf
axe.data.transform(Matrix.Scale(k, 4) @ Matrix.Translation((-cx, -cy, -grip_z)))
if blade > 0:   # Schneide nach −X
	axe.data.transform(Matrix.Rotation(math.pi, 4, 'Z'))
axe.data.update()
print("AXT: %.2f m, Stiel-Ø %.1f cm am Griff, %d Dreiecke"
	% (AXE_LENGTH, 200 * handle_r, sum(len(p.vertices) - 2 for p in axe.data.polygons)))

# --- Axthand: Rahmen, Finger um den Stiel biegen ----------------------------------------------
mesh = body.data
hand_bone = bones[AXE_SIDE + "Hand"]
H = np.array(hand_bone.head_local)   # Handgelenk
gi = body.vertex_groups[AXE_SIDE + "Hand"].index
chiral = 1.0 if AXE_SIDE == "Left" else -1.0   # Daumen, Finger und Handfläche: linke Hand rechtshändig, rechte gespiegelt


def weight(v):
	return next((g.weight for g in v.groups if g.group == gi), 0.0)


ids = np.array([v.index for v in mesh.vertices if weight(v) >= 0.5])
P = np.array([mesh.vertices[i].co for i in ids])
f = P.mean(axis=0) - H
f /= np.linalg.norm(f)                      # Fingerrichtung
Q = P - P.mean(axis=0)
Q -= np.outer(Q @ f, f)
_, vecs = np.linalg.eigh(Q.T @ Q)
u = vecs[:, 2]                              # quer über die Handfläche
s = (P - H) @ f
L = s.max()
# Daumenseite: Der Daumen setzt nah am Handgelenk an und steht dort weiter seitlich ab als der kleine Finger
near = (P[(s > 0.15 * L) & (s < 0.6 * L)] - P.mean(axis=0)) @ u
t = u if near.max() > -near.min() else -u   # Richtung Daumen
n = chiral * np.cross(f, t)                 # Handfläche
fwd = np.array((0.0, 1.0, 0.0))
print("HAND: %.1f cm lang, Daumen %s vorn (%.2f), Handfläche zum Körper %.2f"
	% (100 * L, "nach" if t @ fwd > 0 else "NICHT", t @ fwd, n @ np.array((-math.copysign(1.0, H[0]), 0.0, 0.0))))

tilt = math.radians(GRIP_TILT)
g = t * math.cos(tilt) + f * math.sin(tilt)   # Stiel: Richtung Kopf
fp = f - g * (f @ g)
fp /= np.linalg.norm(fp)                       # Fingerrichtung senkrecht zum Stiel (= Schlagrichtung)
n = chiral * np.cross(fp, g)                   # Handfläche
sp = (P - H) @ fp
knuckle = KNUCKLE * sp.max()
curl = sp > knuckle
h = (P - H) @ n
h0 = float(np.median(h[curl]))                 # Mittellinie der Finger
thick = float(np.clip(np.percentile(h[curl], 95) - np.percentile(h[curl], 5), 0.01, 0.04))
R = handle_r + thick / 2.0                     # Biegeradius der Fingermitte: Innenseite liegt am Stiel
lat = float(np.median(((P - H) @ g)[curl]))
grip = H + fp * knuckle + n * (h0 + R) + g * lat   # Stielachse liegt hier in der Faust

# Finger biegen: Abstand hinter dem Fingeransatz wird zum Bogen um die Stielachse (Abstand zur Mitte bleibt)
normals = [Vector(c.vector) for c in mesh.corner_normals]
turned = {}
for i, p in zip(ids, P):
	d = (p - H) @ fp - knuckle
	if d <= 0.0:
		continue
	hp = (p - H) @ n - h0
	a = min(d / R, CURL_MAX)
	rest = d - a * R                            # über CURL_MAX hinaus geht es gerade weiter
	tangent = n * math.sin(a) + fp * math.cos(a)
	q = H + g * ((p - H) @ g) + fp * knuckle + n * (h0 + R) \
		+ (R - hp) * (-n * math.cos(a) + fp * math.sin(a)) + tangent * rest
	mesh.vertices[i].co = Vector(q)
	turned[i] = Matrix.Rotation(a, 3, Vector(-g))
for poly in mesh.polygons:
	for li in poly.loop_indices:
		vi = mesh.loops[li].vertex_index
		if vi in turned:
			normals[li] = turned[vi] @ normals[li]
mesh.normals_split_custom_set(normals)
mesh.update()
print("FAUST: %d Punkte gebogen, Biegeradius %.1f cm, Fingerdicke %.1f cm" % (len(turned), 100 * R, 100 * thick))

# Axt an die Hand: Stiel (+Z) entlang g, Schneide (−X) in Schlagrichtung
x_axis = Vector(-fp)
z_axis = Vector(g)
rot = Matrix((x_axis, z_axis.cross(x_axis), z_axis)).transposed()
axe.parent = arm
axe.parent_type = 'BONE'
axe.parent_bone = AXE_SIDE + "Hand"
bpy.context.view_layer.update()
axe.matrix_world = Matrix.Translation(Vector(grip)) @ rot.to_4x4()
bpy.context.view_layer.update()
assert (axe.matrix_world.translation - Vector(grip)).length < 1e-4, "Axt sitzt nicht im Griff"

# --- Animationen --------------------------------------------------------------------------------
fps = scene.render.fps / scene.render.fps_base


def calm_axe_arm(action):
	"""Linken Arm ruhiger: Meshy schwingt und dreht ihn beim Gehen weit, die starre Axt kreiste dann fast einmal
	herum. Jede Drehung wird zur mittleren Haltung hin gezogen (AXE_SWING bleibt vom Schwung)."""
	for b in AXE_ARM:
		dp = 'pose.bones["%s"].rotation_quaternion' % b
		fcs = sorted((fc for fc in action.fcurves if fc.data_path == dp), key=lambda fc: fc.array_index)
		n_keys = len(fcs[0].keyframe_points)
		assert len(fcs) == 4 and all(len(fc.keyframe_points) == n_keys for fc in fcs), "Schlüssel nicht im Gleichschritt"
		qs = [Quaternion([fc.keyframe_points[i].co.y for fc in fcs]) for i in range(n_keys)]
		arr = np.array([tuple(q) for q in qs])
		arr *= np.sign(arr @ arr[0])[:, None]   # q und −q sind dieselbe Drehung
		mean = arr.mean(axis=0)
		mean = Quaternion(tuple(mean / np.linalg.norm(mean)))
		for i, q in enumerate(qs):
			c = mean.slerp(q, AXE_SWING)
			for fc in fcs:
				kp = fc.keyframe_points[i]
				kp.co.y = c[fc.array_index]
		for fc in fcs:
			fc.update()


for k in ("walk", "run"):
	calm_axe_arm(actions[k])


def in_place(action):
	"""Hüfte waagerecht auf der Stelle lassen (Meshys Drehsprung wandert, in Schleife spränge die Figur zurück) –
	gibt den Weg (m, Armaturraum) zurück, den das Spiel selbst gehen kann."""
	fcs = sorted((fc for fc in action.fcurves if fc.data_path == 'pose.bones["Hips"].location'), key=lambda fc: fc.array_index)
	rot = bones["Hips"].matrix_local.to_3x3()
	n_keys = len(fcs[0].keyframe_points)
	assert len(fcs) == 3 and all(len(fc.keyframe_points) == n_keys for fc in fcs), "Schlüssel nicht im Gleichschritt"
	locs = [rot @ Vector([fc.keyframe_points[i].co.y for fc in fcs]) for i in range(n_keys)]
	for i, v in enumerate(locs):
		v = Vector((locs[0].x, locs[0].y, v.z))
		for fc, c in zip(fcs, rot.inverted() @ v):
			fc.keyframe_points[i].co.y = c
	for fc in fcs:
		fc.update()
	return (locs[-1] - locs[0]).to_2d(), max((v - locs[0]).to_2d().length for v in locs)


travel, reach = in_place(actions["spin_jump"])
print("SPRUNG: auf die Stelle gesetzt, wanderte %.2f m (%.2f m seitlich, %.2f m vor), höchstens %.2f m weit"
	% (travel.length, travel.x, travel.y, reach))


def stride_speed(action):
	"""Fußweg in der Standphase je Sekunde (Meshys Gehen und Rennen laufen auf der Stelle)."""
	arm.animation_data.action = action
	f0, f1 = int(action.frame_range[0]), int(action.frame_range[1])
	ys = []
	for fr in range(f0, f1 + 1):
		scene.frame_set(fr)
		ys.append((arm.matrix_world @ arm.pose.bones["LeftFoot"].head).y)
	arm.animation_data.action = None
	return 2.0 * (max(ys) - min(ys)) / ((f1 - f0) / fps), (f1 - f0) / fps


arm.animation_data_create()
speeds = {k: stride_speed(actions[k]) for k in ("walk", "run")}
actions.update(mixamo_retarget.retarget_all(arm))
actions.update(mixamo_retarget.retarget_all(arm, OWN_ANIM_DIR))   # nur für ihn, z. B. der Axtschlag „attack“
for pb in arm.pose.bones:
	pb.matrix_basis = Matrix()
scene.frame_set(0)
for k, a in actions.items():   # jede Animation als eigene NLA-Spur, damit der Exporter alle mitnimmt
	track = arm.animation_data.nla_tracks.new()
	track.name = k
	track.strips.new(k, int(a.frame_range[0]), a)
top = max(v.co.z for v in mesh.vertices)
print("PUMPKIN: %d Dreiecke, %.2f m hoch, Laufweite %s, Animationen %s"
	% (sum(len(p.vertices) - 2 for p in mesh.polygons), top,
	{k: "%.2f m/s (%.2f s)" % v for k, v in speeds.items()}, sorted(actions)))

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
	scene.render.engine = 'BLENDER_WORKBENCH'
	scene.display.shading.light = 'FLAT'
	scene.display.shading.color_type = 'TEXTURE'
	scene.render.resolution_x, scene.render.resolution_y = 420, 560
	cd = bpy.data.cameras.new("cam")
	cd.type = 'ORTHO'
	cam = bpy.data.objects.new("cam", cd)
	scene.collection.objects.link(cam)
	scene.camera = cam

	def shot(name, yaw=0.0, center=(0, 0, HEIGHT / 2.0), scale=HEIGHT * 1.15, pitch=0.0):
		cd.ortho_scale = scale
		d = Vector((math.sin(yaw) * math.cos(pitch), math.cos(yaw) * math.cos(pitch), math.sin(pitch)))   # yaw 0 = von vorn (+Y)
		cam.location = Vector(center) + d * 5.0
		cam.rotation_euler = (-d).to_track_quat('-Z', 'Y').to_euler()
		scene.render.filepath = os.path.join(PREVIEW, name + ".png")
		bpy.ops.render.render(write_still=True)

	shot("rest_front")
	side = math.pi / 2 if AXE_SIDE == "Right" else -math.pi / 2   # von der Beilseite
	shot("rest_side", side)
	shot("rest_back", math.pi)
	hc = tuple(grip)
	shot("hand_front", 0.0, hc, 0.45)
	shot("hand_side", side, hc, 0.45)
	shot("hand_inside", -side, hc, 0.45)
	shot("hand_below", 0.0, hc, 0.45, -1.2)
	for k, a in actions.items():
		arm.animation_data.action = a
		f0, f1 = a.frame_range
		for i in range(8):
			scene.frame_set(int(f0 + (f1 - f0) * i / 8))
			shot("%s_%d" % (k, i), side - math.copysign(0.3, side))
	arm.animation_data.action = None
