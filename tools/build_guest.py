# Baut aus einem Meshy-Gast (Auto-Rigging mit Skelettvorlage „Mixamo“, GLB mit allen Animationen)
# einen spielfertigen Grundkörper für die Hotelgäste (Spielkonzept 6.0, „Gastmodelle“).
#
# Aufruf (Blender 4.3):
#   blender -b --python tools/build_guest.py -- <meshy.glb> assets/models/guest_<name>.glb [vorschau-ordner]
#
# Was passiert:
# - Knochen ohne „mixamorig:“ (der Doppelpunkt ist in Godot der Pfadtrenner), Meshys Hilfsknochen
#   und die Hilfskugel fliegen raus, Animationen heißen „walk“ und „run“.
# - Netz bleibt, wie Meshy es liefert (höchstens MAX_TRIS – sonst in Meshy kleiner erzeugen). Reduzieren
#   geht nicht: Meshys Textur besteht aus Hunderten kleiner UV-Inseln, und zusammengelegte Dreiecke
#   spannen dann über mehrere Inseln (graue und bunte Schlieren).
# - Farbtextur TEX_SIZE (Lücken zwischen den UV-Inseln vorher mit Nachbarfarben gefüllt, sonst färben
#   sich beim Verkleinern die Nähte schwarz).
# - Färbemaske als Punktfarbe je Fläche (exakt, keine Texturkompression): Kanal R = Oberteil,
#   G = Hose, B = Haare (0 oder 1). Die mittlere Helligkeit je Bereich gibt das Skript aus – sie
#   gehört nach GuestBody.BODIES („ref“). Der Shader rechnet Gastfarbe × Helligkeit / Mittelwert,
#   so behält die Kleidung Falten und Maschen. Welcher Bereich:
#   Kopf/Hals-Knochen → Haare, Füße → nichts, sonst hell = Oberteil, dunkel = Hose (zwei Gruppen
#   über die Grauwerte). Nur graue Stellen zählen; Haut, Schuhe und Augenweiß bleiben.
# - Formschlüssel „build“ (Körperbau): Bauch, Hüfte, Oberarme, Schenkel und Hals entlang der
#   Oberfläche nach außen. 1 = kräftig, negativ = schlank.
# - Blick nach −Z, Füße auf y = 0. Größe bleibt (Meter) – skaliert wird im Spiel je Gast.
import bpy, sys, os, math
import numpy as np
from mathutils import Matrix, Vector

MAX_TRIS = 15000
TEX_SIZE = 1024           # kleiner verschwimmen die Gesichter (die Inseln sind winzig)
WORK_SIZE = 1024          # Arbeitsgröße der Textur für Maske und Lückenfüllen
GREY_SAT = 0.09           # max. Sättigung (max − min) einer „grauen“ Stelle
GREY_LUM = (0.12, 0.86)   # Helligkeitsbereich grauer Stoffe/Haare (darüber: Augenweiß)
## Körperbau: Verschiebung (m) entlang der Normalen je Knochen bei Wert 1
BUILD_PUSH = {
	"Hips": 0.035, "Spine": 0.045, "Spine1": 0.035, "Spine2": 0.018, "Neck": 0.010,
	"LeftArm": 0.012, "RightArm": 0.012, "LeftForeArm": 0.006, "RightForeArm": 0.006,
	"LeftUpLeg": 0.020, "RightUpLeg": 0.020, "LeftLeg": 0.006, "RightLeg": 0.006,
}
BELLY_FORWARD = 0.03      # Bauch zusätzlich nach vorn (m), nur Vorderseite
KEEP_EXTRA_BONES = False  # Meshys „headfront“ hat keine Gewichte

argv = sys.argv[sys.argv.index("--") + 1:]
SRC, DST = argv[0], argv[1]
PREVIEW = argv[2] if len(argv) > 2 else ""
NAME = os.path.splitext(os.path.basename(DST))[0]

# --- Laden, aufräumen ------------------------------------------------------------------------
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=SRC)
scene = bpy.context.scene
for o in list(scene.objects):
	if o.type == 'MESH' and not o.vertex_groups:
		bpy.data.objects.remove(o)   # Meshys Hilfskugel
arm = [o for o in scene.objects if o.type == 'ARMATURE'][0]
body = [o for o in scene.objects if o.type == 'MESH'][0]
arm.name = "Guest"
body.name = body.data.name = NAME

bpy.context.view_layer.objects.active = arm
bpy.ops.object.mode_set(mode='EDIT')
for eb in list(arm.data.edit_bones):
	if not eb.name.startswith("mixamorig:") and not KEEP_EXTRA_BONES and eb.name not in body.vertex_groups:
		arm.data.edit_bones.remove(eb)
bpy.ops.object.mode_set(mode='OBJECT')
for b in arm.data.bones:
	b.name = b.name.replace("mixamorig:", "")   # benennt Gruppen und Animationskurven mit um
for vg in body.vertex_groups:
	vg.name = vg.name.replace("mixamorig:", "")

actions = {}
for a in bpy.data.actions:
	key = "run" if a.name.lower().startswith("run") else "walk" if a.name.lower().startswith("walk") else None
	if key:
		a.name = key
		actions[key] = a
for track in list(arm.animation_data.nla_tracks):
	arm.animation_data.nla_tracks.remove(track)
arm.animation_data.action = None
for pb in arm.pose.bones:
	pb.matrix_basis = Matrix()
print("Animationen:", {k: tuple(a.frame_range) for k, a in actions.items()})

# --- Textur: Lücken füllen, Arbeitskopie --------------------------------------------------
mat = body.data.materials[0]
nodes = mat.node_tree.nodes
bsdf = [n for n in nodes if n.type == 'BSDF_PRINCIPLED'][0]
base_node = [l.from_node for l in bsdf.inputs['Base Color'].links][0]
img = base_node.image


def fill_gaps(rgb, filled, steps):
	"""Leere Texel (zwischen den UV-Inseln) bekommen die Farbe ihrer gefüllten Nachbarn – Schritt für Schritt."""
	for _ in range(steps):
		if filled.all():
			break
		acc = np.zeros_like(rgb)
		cnt = np.zeros(filled.shape, dtype=np.float32)
		for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1)):
			f = np.roll(filled, (dy, dx), axis=(0, 1))
			acc += np.roll(rgb, (dy, dx), axis=(0, 1)) * f[:, :, None]
			cnt += f
		grow = (~filled) & (cnt > 0)
		rgb[grow] = acc[grow] / cnt[grow][:, None]
		filled |= grow


# Erst in voller Größe füllen, dann verkleinern – sonst mischt das Verkleinern Schwarz in die Inselränder
size = img.size[0]
px = np.array(img.pixels[:], dtype=np.float32).reshape(size, size, 4)
rgb = px[:, :, :3].copy()
fill_gaps(rgb, rgb.max(axis=2) > 0.012, 4 * size // WORK_SIZE)
px[:, :, :3] = rgb
px[:, :, 3] = 1.0
img.pixels[:] = px.ravel()
del px, rgb
img.scale(WORK_SIZE, WORK_SIZE)
px = np.array(img.pixels[:], dtype=np.float32).reshape(WORK_SIZE, WORK_SIZE, 4)
rgb = px[:, :, :3].copy()
fill_gaps(rgb, rgb.max(axis=2) > 0.012, 24)
px[:, :, :3] = rgb
img.pixels[:] = px.ravel()
lum_map = rgb @ np.array([0.299, 0.587, 0.114], dtype=np.float32)
sat_map = rgb.max(axis=2) - rgb.min(axis=2)
# Helligkeit wie im Shader: lineare Farbe, Rec. 709
lin = np.where(rgb <= 0.04045, rgb / 12.92, ((rgb + 0.055) / 1.055) ** 2.4)
lin_lum_map = lin @ np.array([0.2126, 0.7152, 0.0722], dtype=np.float32)

# --- Netz prüfen -------------------------------------------------------------------------
mesh = body.data
tris = sum(len(p.vertices) - 2 for p in mesh.polygons)
print("Dreiecke: %d" % tris)
if tris > MAX_TRIS:
	raise SystemExit("Zu viele Dreiecke (%d > %d) – in Meshy mit kleinerer Polygonzahl erzeugen" % (tris, MAX_TRIS))

# --- Färbemaske ------------------------------------------------------------------------------
gname = {vg.index: vg.name for vg in body.vertex_groups}


def zone_of(poly):
	w = {}
	for vi in poly.vertices:
		for g in mesh.vertices[vi].groups:
			n = gname[g.group]
			z = "head" if n in ("Head", "Neck", "HeadTop_End") else "foot" if ("Foot" in n or "Toe" in n) \
				else "hand" if "Hand" in n else "body"
			w[z] = w.get(z, 0.0) + g.weight
	return max(w, key=w.get) if w else "body"


uv = mesh.uv_layers.active.data
samples = []   # je Fläche: (zone, [graue Helligkeiten], Fläche, [dieselben linear])
for poly in mesh.polygons:
	uvs = [Vector(uv[li].uv) for li in poly.loop_indices]
	c = sum(uvs, Vector((0, 0))) / len(uvs)
	greys = []
	greys_lin = []
	for p in [c] + [c.lerp(u, 0.7) for u in uvs]:
		x = min(WORK_SIZE - 1, max(0, int(p.x * WORK_SIZE)))
		y = min(WORK_SIZE - 1, max(0, int(p.y * WORK_SIZE)))
		if sat_map[y, x] < GREY_SAT and GREY_LUM[0] < lum_map[y, x] < GREY_LUM[1]:
			greys.append(float(lum_map[y, x]))
			greys_lin.append(float(lin_lum_map[y, x]))
	samples.append((zone_of(poly), greys, poly.area, greys_lin))

# Oberteil/Hose: zwei Gruppen über die Helligkeit (k-Means, 1-D)
body_lums = np.array([np.mean(g) for z, g, a, gl in samples if z == "body" and g])
lo_c, hi_c = np.percentile(body_lums, 20), np.percentile(body_lums, 80)
for _ in range(20):
	split = (lo_c + hi_c) / 2.0
	lo_c, hi_c = body_lums[body_lums < split].mean(), body_lums[body_lums >= split].mean()
split = (lo_c + hi_c) / 2.0
region = []
for z, g, a, gl in samples:
	if not g or z in ("foot", "hand"):
		region.append(-1)
	elif z == "head":
		region.append(2)
	else:
		region.append(0 if np.mean(g) >= split else 1)
ref = []
for r in range(3):
	ls = [(np.mean(gl), a) for (z, g, a, gl), rr in zip(samples, region) if rr == r]
	ref.append(sum(l * a for l, a in ls) / max(1e-6, sum(a for l, a in ls)) if ls else 0.5)
print("Maske: Oberteil %d, Hose %d, Haare %d Flächen; Mittelwerte (linear) %.3f / %.3f / %.3f; Grenze %.2f"
	% (region.count(0), region.count(1), region.count(2), ref[0], ref[1], ref[2], split))
col = mesh.color_attributes.new("tint", 'FLOAT_COLOR', 'CORNER')
for poly, r in zip(mesh.polygons, region):
	c = [0.0, 0.0, 0.0, 1.0]
	if r >= 0:
		c[r] = 1.0
	for li in poly.loop_indices:
		col.data[li].color = c
mesh.color_attributes.active_color = col

# Textur auf Spielgröße
img.scale(TEX_SIZE, TEX_SIZE)
img.name = NAME
for n in list(nodes):
	if n.type in ('TEX_IMAGE', 'NORMAL_MAP', 'SEPARATE_COLOR', 'SEPRGB') and n != base_node:
		nodes.remove(n)
bsdf.inputs['Metallic'].default_value = 0.0
bsdf.inputs['Roughness'].default_value = 1.0
mat.use_backface_culling = True

# --- Blick nach −Z (glTF) = Blender +Y, Füße auf 0 ---------------------------------------------
bpy.context.view_layer.update()
# Die Zehen zeigen sicher nach vorn
toe = arm.data.bones["LeftToe_End"].head_local
foot = arm.data.bones["LeftFoot"].head_local
if (toe - foot).y < 0:
	arm.rotation_mode = 'XYZ'
	arm.rotation_euler.z += math.pi
bpy.context.view_layer.update()
zmin = min((body.matrix_world @ v.co).z for v in mesh.vertices)
arm.location.z -= zmin
bpy.context.view_layer.update()
pts = [body.matrix_world @ v.co for v in mesh.vertices]
height = max(p.z for p in pts) - min(p.z for p in pts)

# Schulterbreite: Abstand der Schultergelenke plus Deltamuskeln (geschätzt, ~5 cm je Seite)
width = (arm.data.bones["LeftArm"].head_local - arm.data.bones["RightArm"].head_local).length + 0.10

# --- Formschlüssel „build“ ------------------------------------------------------------------
body.shape_key_add(name="Basis", from_mix=False)
sk = body.shape_key_add(name="build", from_mix=False)
fwd = (arm.matrix_world.to_3x3().inverted() @ Vector((0, 1, 0))).normalized()   # vorn im Netzraum
belly_ids = {vg.index for vg in body.vertex_groups if vg.name in ("Spine", "Spine1", "Hips")}
# glTF trennt Punkte an UV-Nähten – deren Normalen mitteln, sonst reißen die Nähte beim Aufblähen auf
normal_at = {}
for v in mesh.vertices:
	key = tuple(round(c, 5) for c in v.co)
	normal_at[key] = normal_at.get(key, Vector()) + v.normal
for v in mesh.vertices:
	push = 0.0
	belly = 0.0
	for g in v.groups:
		push += BUILD_PUSH.get(gname[g.group], 0.0) * g.weight
		if g.group in belly_ids:
			belly += g.weight
	if push <= 0.0:
		continue
	n = normal_at[tuple(round(c, 5) for c in v.co)].normalized()
	front = max(0.0, n.dot(fwd))
	sk.data[v.index].co = v.co + n * push + fwd * BELLY_FORWARD * belly * front * front
# Laufweite: Fußweg in der Standphase je Sekunde (Animationen laufen auf der Stelle)
fps = scene.render.fps / scene.render.fps_base


def stride_speed(action):
	arm.animation_data.action = action
	f0, f1 = int(action.frame_range[0]), int(action.frame_range[1])
	ys = []
	for f in range(f0, f1 + 1):
		scene.frame_set(f)
		ys.append((arm.matrix_world @ arm.pose.bones["LeftFoot"].head).y)
	arm.animation_data.action = None
	return 2.0 * (max(ys) - min(ys)) / ((f1 - f0) / fps), (f1 - f0) / fps


speeds = {k: stride_speed(a) for k, a in actions.items()}
for pb in arm.pose.bones:
	pb.matrix_basis = Matrix()
scene.frame_set(0)
print("GUEST %s: %.3f m hoch, Schulterbreite %.3f m, Laufweite %s"
	% (NAME, height, width, {k: "%.2f m/s (%.2f s)" % v for k, v in speeds.items()}))
print("GUEST-Eintrag für GuestBody.BODIES: \"height\": %.3f, \"width\": %.3f, \"walk\": %.2f, \"run\": %.2f, \"ref\": Vector3(%.3f, %.3f, %.3f)"
	% (height, width, speeds.get("walk", (1.4,))[0], speeds.get("run", (3.0,))[0], ref[0], ref[1], ref[2]))

# Jede Animation als eigene NLA-Spur, damit der Exporter beide mitnimmt
for k, a in actions.items():
	track = arm.animation_data.nla_tracks.new()
	track.name = k
	track.strips.new(k, int(a.frame_range[0]), a)

bpy.ops.export_scene.gltf(
	filepath=DST, export_format='GLB', export_yup=True, export_apply=False,
	export_skins=True, export_animations=True, export_animation_mode='NLA_TRACKS',
	export_morph=True, export_morph_normal=False, export_cameras=False, export_lights=False,
	export_vertex_color='ACTIVE', export_all_vertex_colors=False,
	export_image_format='AUTO')   # PNG: JPEG färbt die Inselränder (Farbunterabtastung)

# --- Vorschau --------------------------------------------------------------------------------
if PREVIEW:
	os.makedirs(PREVIEW, exist_ok=True)
	for t in list(arm.animation_data.nla_tracks):
		t.mute = True
	for pb in arm.pose.bones:   # der Exporter lässt die zuletzt abgetastete Pose stehen
		pb.matrix_basis = Matrix()
	scene.render.engine = 'BLENDER_WORKBENCH'
	scene.display.shading.light = 'FLAT'
	scene.render.resolution_x, scene.render.resolution_y = 420, 560
	cd = bpy.data.cameras.new("cam")
	cd.type = 'ORTHO'
	cd.ortho_scale = 2.1
	cam = bpy.data.objects.new("cam", cd)
	scene.collection.objects.link(cam)
	scene.camera = cam

	def shot(name, yaw=0.0, color='TEXTURE'):
		scene.display.shading.color_type = color
		d = Vector((math.sin(yaw), math.cos(yaw), 0.0))   # yaw 0 = von vorn (+Y)
		cam.location = Vector((0, 0, 0.95)) + d * 5.0
		cam.rotation_euler = (-d).to_track_quat('-Z', 'Y').to_euler()
		scene.render.filepath = os.path.join(PREVIEW, name + ".png")
		bpy.ops.render.render(write_still=True)

	shot("rest_front")
	shot("rest_back", math.pi)
	shot("mask_front", 0.0, 'VERTEX')
	shot("mask_side", math.pi / 2, 'VERTEX')
	shot("rest_side", math.pi / 2)
	sk.value = 1.0
	shot("build_front")
	shot("build_side", math.pi / 2)
	sk.value = -0.6
	shot("slim_side", math.pi / 2)
	sk.value = 0.0
	for k, a in actions.items():
		arm.animation_data.action = a
		f0, f1 = a.frame_range
		for i, t in enumerate((0.0, 0.25, 0.5)):
			scene.frame_set(int(f0 + (f1 - f0) * t))
			shot("%s_%d" % (k, i), math.pi / 2 + 0.5)
			shot("%s_%d_back" % (k, i), math.pi - 0.3)
	arm.animation_data.action = None
