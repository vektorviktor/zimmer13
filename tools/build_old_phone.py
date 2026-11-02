# Baut aus „Old Phone“ (Sketchfab, old_phone_blue_2.glb) ein schwarzes Wählscheibentelefon für die Zimmer
# (Spielkonzept 4.14): Klebezettel, Klebeband am Hörer und die Plakette vorn unten fallen weg. Alle Karten sind neu –
# vom Original bleiben nur Netz, UVs und die Ziffernplättchen der Wählscheibe (gesäubert: Emaille weiß, Ziffer schwarz).
#   Gehäuse, Hörer, Mittelscheibe: schwarz glänzend, die Rauheit wolkig und speckig (dezent), dazu feines Korn
#   Fingerscheibe, Anschlag, Mittelkappe: gebürstetes Messing wie die Lichtschalter (switch_plate*.png), der Schliff
#     läuft im Kreis um die Achse der Wählscheibe
#   Kabel: schwarzer Gummi
#   Normal Map glatt (keine Risse), nur der grob facettierte Hörer bekommt die Rundung einer unterteilten Kopie
#   (Dreiecke bleiben wie im Original); Verdeckung frisch aus der Geometrie gebacken
# Die Muster rechnen im Raum (gebackene Lage je Texel), darum reißen sie an UV-Nähten nicht ab.
#
# Teile (Godot, m; Front nach +Z, Ursprung mittig unter dem Gehäuse): „body“ (mit Wählscheibe und Kabeltülle),
# „handset“ (Ursprung mittig auf der Unterkante der Muscheln, liegt auf der Gabel), „cable“ (Schnur des Originals,
# liegt in Schlaufen auf dem Tisch); Leerknoten „cable_body“ (Tülle hinten links am Gehäuse) und „cable_handset“
# (Kind des Hörers, Tülle an der Sprechmuschel) – dort setzt das Spiel die Schnur an, wenn der Hörer daneben liegt.
# Texturen als PNG neben das Modell: <tex>_albedo.png, <tex>_normal.png, <tex>_orm.png (R Verdeckung, G Rauheit,
# B Metall – wie Mat.pbr_model).
#
# Aufruf aus dem Projektordner (Blender 4.3; Pfade absolut, Renderordner optional für Abnahmebilder):
#   blender -b --python tools/build_old_phone.py -- <src.glb> <dst.glb> <tex-präfix> [<renderordner>]
import bpy, bmesh, sys, os, math
import numpy as np
from mathutils import Vector

argv = sys.argv[sys.argv.index("--") + 1:]
SRC, DST, TEX = argv[0], argv[1], argv[2]
RENDER = argv[3] if len(argv) > 3 else None
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

SIZE = 2048
SCALE = 0.16           # Originaleinheiten → m (Grundplatte 16 × 18 cm, Hörer 24 cm)
AO_DIST = 0.25         # Originaleinheiten

# Lose Teile des Originals (Flächen-Zusammenhang, Reihenfolge der Datei)
REMOVE = set(range(0, 8)) | {8, 15, 16, 102} | set(range(9, 15))   # Plakette, Klebezettel, Klebeband
CORD = {92, 93, 94, 95}
GROMMET_BODY, GROMMET_HANDSET = 72, 71
CABLE = CORD | {GROMMET_BODY, GROMMET_HANDSET}   # Gummi
DIGIT = {17, 18, 27, 28, 70, 78, 79, 82, 84, 90, 96}
INNER = {77}           # Mittelscheibe mit den Buchstaben – wird glatt schwarz
BRASS = set(range(19, 27)) | set(range(29, 40)) | {73, 74, 75, 76, 80, 81, 83, 85, 86, 87, 88, 89, 97, 98, 99, 100, 101}
HANDSET = {91, GROMMET_HANDSET}
WHEEL = 100            # Fingerscheibe, daraus die Achse
## Messingteile mit sauberen UVs; die übrigen (Fingerloch-Wände, Anschlag) haben fast linienförmige UVs am Rand des
## Hörers und bekommen einen Punkt mitten in der Fingerscheibe – sonst blutet ihr Messing beim Filtern auf den Hörer
BRASS_UV = {89, 100, 101}
PARTS = 103
BODY, R_CABLE, R_BRASS, R_DIGIT = 0, 1, 2, 3

SMOOTH_ANGLE = 60      # Grad: weichere Kanten werden glatt schattiert (die Normalen des Originals fallen weg)
## Schwarz (sRGB), Gummi, Emaille, Tinte
BLACK = np.array([0.115, 0.112, 0.110])
RUBBER = np.array([0.075, 0.073, 0.072])
ENAMEL = np.array([0.88, 0.86, 0.80])
INK = np.array([0.04, 0.04, 0.045])
BRASS_METAL = 0.4      # wie LightSwitch.METALLIC
SWITCH_M_PX = 0.086 / 1024   # Schalterplatte: Meter je Pixel
SWITCH_X, SWITCH_Y, SWITCH_W, SWITCH_H = 150, 600, 720, 280   # gebürstetes Feld unter den Schrauben (Pixel, oben = 0)

# --- Laden -------------------------------------------------------------------------------------------------------
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=SRC)
ob = [o for o in bpy.context.scene.objects if o.type == 'MESH'][0]
ob.data.transform(ob.matrix_world)
for o in list(bpy.context.scene.objects):
	if o != ob:
		bpy.data.objects.remove(o)
ob.matrix_world.identity()
ob.name = "phone"
src_img = ob.data.materials[0].node_tree.nodes["Principled BSDF"].inputs["Base Color"].links[0].from_node.image
src_img.colorspace_settings.name = 'Non-Color'
SRC_ALB = np.array(src_img.pixels[:], dtype=np.float32).reshape(SIZE, SIZE, 4)[:, :, :3]   # sRGB, Zeile 0 = v 0
ob.data.materials.clear()

bm = bmesh.new()
bm.from_mesh(ob.data)
bm.faces.ensure_lookup_table()
part = [-1] * len(bm.faces)
pid = 0
for f in bm.faces:
	if part[f.index] >= 0:
		continue
	stack = [f]
	part[f.index] = pid
	while stack:
		x = stack.pop()
		for e in x.edges:
			for g in e.link_faces:
				if part[g.index] < 0:
					part[g.index] = pid
					stack.append(g)
	pid += 1
assert pid == PARTS, "anderes Ausgangsmodell? %d Teile" % pid

anchor = {p: np.mean([v.co[:] for f in bm.faces if part[f.index] == p for v in f.verts], axis=0)
		for p in (GROMMET_BODY, GROMMET_HANDSET)}
wheel = np.array([v.co[:] for f in bm.faces if part[f.index] == WHEEL for v in f.verts])
DIAL_C = wheel.mean(0)
DIAL_N = np.linalg.svd(wheel - DIAL_C)[2][2]

uv_layer = bm.loops.layers.uv.active
best = max((f for f in bm.faces if part[f.index] == WHEEL), key=lambda f: f.calc_area())
brass_uv = sum((l[uv_layer].uv for l in best.loops), Vector((0, 0))) / len(best.loops)
for f in bm.faces:
	if part[f.index] in BRASS and part[f.index] not in BRASS_UV:
		for l in f.loops:
			l[uv_layer].uv = brass_uv

part_layer = bm.faces.layers.int.new("part")
reg_layer = bm.loops.layers.float_color.new("region")
for f in bm.faces:
	p = part[f.index]
	f[part_layer] = p
	r = R_CABLE if p in CABLE else R_BRASS if p in BRASS else R_DIGIT if p in DIGIT else BODY
	for l in f.loops:
		l[reg_layer] = ((r + 0.5) / 8.0, 1.0 if p in HANDSET else 0.0, 0.0, 1.0)
bmesh.ops.delete(bm, geom=[f for f in bm.faces if part[f.index] in REMOVE], context='FACES')
bmesh.ops.delete(bm, geom=[v for v in bm.verts if not v.link_faces], context='VERTS')
bm.to_mesh(ob.data)
bm.free()
bpy.context.view_layer.objects.active = ob
ob.select_set(True)
bpy.ops.mesh.customdata_custom_splitnormals_clear()
bpy.ops.object.shade_smooth_by_angle(angle=math.radians(SMOOTH_ANGLE))

# --- Backen: Lage, Bereich, Abdeckung, Verdeckung ------------------------------------------------------------
sc = bpy.context.scene
sc.render.engine = 'CYCLES'
sc.cycles.device = 'CPU'
sc.world = bpy.data.worlds.new("bake")
sc.world.light_settings.distance = AO_DIST
mat = bpy.data.materials.new("bake")
mat.use_nodes = True
nt = mat.node_tree
nt.nodes.clear()
out = nt.nodes.new("ShaderNodeOutputMaterial")
emit = nt.nodes.new("ShaderNodeEmission")
nt.links.new(emit.outputs[0], out.inputs[0])
geo = nt.nodes.new("ShaderNodeNewGeometry")
pos = nt.nodes.new("ShaderNodeVectorMath")
pos.operation = 'MULTIPLY_ADD'
pos.inputs[1].default_value = (0.25, 0.25, 0.25)
pos.inputs[2].default_value = (0.5, 0.5, 0.5)
nt.links.new(geo.outputs["Position"], pos.inputs[0])
reg = nt.nodes.new("ShaderNodeVertexColor")
reg.layer_name = "region"
tex = nt.nodes.new("ShaderNodeTexImage")
nt.nodes.active = tex
ob.data.materials.append(mat)
bpy.context.view_layer.objects.active = ob
ob.select_set(True)


def bake(kind, source=None, margin=16, samples=1):
	img = bpy.data.images.new("bake_" + kind, SIZE, SIZE, alpha=False, float_buffer=True)
	img.colorspace_settings.name = 'Non-Color'
	tex.image = img
	for l in list(emit.inputs[0].links):
		nt.links.remove(l)
	if source is not None:
		nt.links.new(source, emit.inputs[0])
	else:
		emit.inputs[0].default_value = (1, 1, 1, 1)
	sc.cycles.samples = samples
	bpy.ops.object.bake(type=kind, margin=margin, margin_type='EXTEND', use_clear=True)
	return np.array(img.pixels[:], dtype=np.float32).reshape(SIZE, SIZE, 4)[:, :, :3]


POS = bake('EMIT', pos.outputs[0]) * 4.0 - 2.0
REG_RGB = bake('EMIT', reg.outputs[0])
REG = np.clip((REG_RGB[:, :, 0] * 8.0).astype(int), 0, 7)
VALID = bake('EMIT')[:, :, 0] > 0.5
## Texel des Hörers samt Rand, aber keine, die ein anderes Teil wirklich belegt
HANDSET_TEX = (REG_RGB[:, :, 1] > 0.5) & ~((bake('EMIT', reg.outputs[0], margin=0)[:, :, 1] < 0.5) & (bake('EMIT', margin=0)[:, :, 0] > 0.5))
AO = bake('AO', samples=128)[:, :, 0]

# --- Rauschen (Wertrauschen 3D) ----------------------------------------------------------------------------------
rng = np.random.default_rng(13)
PERM = np.tile(rng.permutation(256), 2)
VALS = rng.random(256)


def vnoise(p):
	i = np.floor(p).astype(np.int64)
	f = p - i
	f = f * f * (3 - 2 * f)
	i &= 255
	res = 0.0
	for dx in (0, 1):
		for dy in (0, 1):
			for dz in (0, 1):
				h = VALS[PERM[PERM[PERM[i[:, 0] + dx] + i[:, 1] + dy] + i[:, 2] + dz] & 255]
				w = (f[:, 0] if dx else 1 - f[:, 0]) * (f[:, 1] if dy else 1 - f[:, 1]) * (f[:, 2] if dz else 1 - f[:, 2])
				res = res + h * w
	return res


def fbm(p, octaves):
	total, amp, norm = 0.0, 1.0, 0.0
	for o in range(octaves):
		total = total + amp * vnoise(p * (2.0 ** o) + o * 17.3)
		norm += amp
		amp *= 0.5
	return total / norm


def smooth(a, b, x):
	t = np.clip((x - a) / (b - a), 0.0, 1.0)
	return t * t * (3 - 2 * t)


# --- Karten ------------------------------------------------------------------------------------------------------
idx = np.nonzero(VALID)
P = POS[idx]
M = P * SCALE                       # Meter
R = REG[idx]
n = len(P)
alb = np.tile(BLACK, (n, 1))
rough = np.empty(n)
metal = np.zeros(n)

# Schwarz: Wolken im Glanz, speckige Flecken, feines Korn
clouds = smooth(0.38, 0.66, fbm(M / 0.035, 4))
smudge = smooth(0.56, 0.78, fbm(M / 0.011 + 40.0, 3))
grain = vnoise(M / 0.00035 + 90.0) - 0.5
rough[:] = 0.15 + 0.12 * clouds + 0.08 * smudge + 0.035 * grain
alb *= (0.96 + 0.06 * fbm(M / 0.02 + 7.0, 2))[:, None]

c = R == R_CABLE
alb[c] = RUBBER
rough[c] = 0.55 + 0.08 * (fbm(M[c] / 0.004, 2) - 0.5)

# Ziffern aus dem Original, gesäubert
d = R == R_DIGIT
src = SRC_ALB[idx][d]
k = smooth(0.15, 0.22, src @ np.array([0.3, 0.59, 0.11]))[:, None]
alb[d] = INK * (1 - k) + ENAMEL * k
rough[d] = 0.28 + 0.04 * grain[d]

# Messing: Schliff der Schalterplatte, im Kreis um die Achse der Wählscheibe
sw = bpy.data.images.load(os.path.join(ROOT, "assets/textures/switch_plate.png"))
swr = bpy.data.images.load(os.path.join(ROOT, "assets/textures/switch_plate_rough.png"))
for im in (sw, swr):
	im.colorspace_settings.name = 'Non-Color'
SW = np.array(sw.pixels[:], dtype=np.float32).reshape(1024, 1024, 4)[::-1, :, :3]   # Zeile 0 = oben
SWR = np.array(swr.pixels[:], dtype=np.float32).reshape(1024, 1024, 4)[::-1, :, 0]
b = R == R_BRASS
rel = P[b] - DIAL_C
rel -= np.outer(rel @ DIAL_N, DIAL_N)
e1 = np.cross(DIAL_N, [0.0, 0.0, 1.0])
e1 /= np.linalg.norm(e1)
e2 = np.cross(DIAL_N, e1)
rad = np.linalg.norm(rel, axis=1) * SCALE
ang = np.abs(np.arctan2(rel @ e2, rel @ e1)) / math.pi
px = SWITCH_X + np.clip(rad / SWITCH_M_PX, 0, SWITCH_W - 1).astype(int)
py = SWITCH_Y + (ang * (SWITCH_H - 1)).astype(int)
alb[b] = SW[py, px]
rough[b] = SWR[py, px]
metal[b] = BRASS_METAL


def save(name, arr, srgb):
	img = bpy.data.images.new(name, SIZE, SIZE, alpha=False)
	img.colorspace_settings.name = 'sRGB' if srgb else 'Non-Color'
	rgba = np.ones((SIZE, SIZE, 4), dtype=np.float32)
	rgba[:, :, :3] = np.clip(arr, 0, 1)
	img.pixels.foreach_set(rgba.ravel())
	img.filepath_raw = "%s_%s.png" % (TEX, name)
	img.file_format = 'PNG'
	img.save()
	return img


albedo = np.tile(BLACK, (SIZE, SIZE, 1)).astype(np.float32)
albedo[idx] = alb
orm = np.zeros((SIZE, SIZE, 3), dtype=np.float32)
orm[:, :, 0] = 1.0
orm[:, :, 1] = 0.3
orm[idx] = np.stack([0.3 + 0.7 * np.clip(AO[idx], 0, 1), rough, metal], axis=1)
images = {k: save(k, a, k == "albedo") for k, a in (("albedo", albedo), ("orm", orm))}

# --- Teilen, verschieben, ausgeben -------------------------------------------------------------------------------
ob.data.materials.clear()
ob.data.attributes.remove(ob.data.attributes["region"])


def split(name, keep):
	o = ob.copy()
	o.data = ob.data.copy()
	o.name = o.data.name = name
	sc.collection.objects.link(o)
	b2 = bmesh.new()
	b2.from_mesh(o.data)
	lay = b2.faces.layers.int["part"]
	bmesh.ops.delete(b2, geom=[f for f in b2.faces if not keep(f[lay])], context='FACES')
	bmesh.ops.delete(b2, geom=[v for v in b2.verts if not v.link_faces], context='VERTS')
	b2.to_mesh(o.data)
	b2.free()
	o.data.attributes.remove(o.data.attributes["part"])
	return o


body = split("body", lambda p: p not in HANDSET and p not in CORD)
handset = split("handset", lambda p: p in HANDSET)
cable = split("cable", lambda p: p in CORD)
bpy.data.objects.remove(ob)

# Der Hörer ist grob facettiert und glänzt: Normalen einer zweimal unterteilten Kopie in die Normal Map backen
smooth_copy = handset.copy()
smooth_copy.data = handset.data.copy()
sc.collection.objects.link(smooth_copy)
smooth_copy.modifiers.new("subsurf", 'SUBSURF').levels = 2
nimg = bpy.data.images.new("bake_normal", SIZE, SIZE, alpha=False, float_buffer=True)
nimg.colorspace_settings.name = 'Non-Color'
tex.image = nimg
handset.data.materials.append(mat)
bpy.ops.object.select_all(action='DESELECT')
smooth_copy.select_set(True)
handset.select_set(True)
bpy.context.view_layer.objects.active = handset
sc.cycles.samples = 1
bpy.ops.object.bake(type='NORMAL', normal_space='TANGENT', margin=16, margin_type='EXTEND', use_clear=True,
	use_selected_to_active=True, cage_extrusion=0.02, max_ray_distance=0.06)
normal = np.zeros((SIZE, SIZE, 3), dtype=np.float32) + [0.5, 0.5, 1.0]
normal[HANDSET_TEX] = np.array(nimg.pixels[:], dtype=np.float32).reshape(SIZE, SIZE, 4)[:, :, :3][HANDSET_TEX]
images["normal"] = save("normal", normal, False)
bpy.data.objects.remove(smooth_copy)
handset.data.materials.clear()
print("Dreiecke", {o.name: sum(len(p.vertices) - 2 for p in o.data.polygons) for o in (body, handset, cable)})


def bounds(o):
	co = np.array([v.co[:] for v in o.data.vertices])
	return co.min(0), co.max(0)


lo, hi = bounds(body)
origin = Vector(((lo[0] + hi[0]) / 2, (lo[1] + hi[1]) / 2, lo[2]))
hlo, hhi = bounds(handset)
h_origin = Vector(((hlo[0] + hhi[0]) / 2, (hlo[1] + hhi[1]) / 2, hlo[2]))
for o, at in ((body, origin), (cable, origin), (handset, h_origin)):
	for v in o.data.vertices:
		v.co = (v.co - at) * SCALE
handset.location = (h_origin - origin) * SCALE
for name, at, parent in (("cable_body", Vector(anchor[GROMMET_BODY]) - origin, None),
		("cable_handset", Vector(anchor[GROMMET_HANDSET]) - h_origin, handset)):
	e = bpy.data.objects.new(name, None)
	e.location = at * SCALE
	e.parent = parent
	sc.collection.objects.link(e)
print("Gehäuse %.3f × %.3f × %.3f m" % tuple((hi - lo) * SCALE))
print("Hörer-Ursprung", tuple(round(c, 4) for c in handset.location))

bpy.ops.object.select_all(action='SELECT')
bpy.ops.export_scene.gltf(filepath=DST, export_format='GLB', export_yup=True, export_texcoords=True,
	export_normals=True, export_tangents=True, export_materials='NONE', export_animations=False, use_selection=True)

# --- Abnahmebilder -----------------------------------------------------------------------------------------------
if RENDER:
	m = bpy.data.materials.new("phone")
	m.use_nodes = True
	t = m.node_tree
	bsdf = t.nodes["Principled BSDF"]
	ia = t.nodes.new("ShaderNodeTexImage")
	ia.image = images["albedo"]
	t.links.new(ia.outputs[0], bsdf.inputs["Base Color"])
	io = t.nodes.new("ShaderNodeTexImage")
	io.image = images["orm"]
	sep = t.nodes.new("ShaderNodeSeparateColor")
	t.links.new(io.outputs[0], sep.inputs[0])
	t.links.new(sep.outputs[1], bsdf.inputs["Roughness"])
	t.links.new(sep.outputs[2], bsdf.inputs["Metallic"])
	inn = t.nodes.new("ShaderNodeTexImage")
	inn.image = images["normal"]
	nmap = t.nodes.new("ShaderNodeNormalMap")
	t.links.new(inn.outputs[0], nmap.inputs["Color"])
	t.links.new(nmap.outputs[0], bsdf.inputs["Normal"])
	for o in (body, handset, cable):
		o.data.materials.append(m)
	w = sc.world
	w.use_nodes = True
	w.node_tree.nodes["Background"].inputs[0].default_value = (0.02, 0.02, 0.022, 1)
	w.node_tree.nodes["Background"].inputs[1].default_value = 1.0
	for name, loc, size, energy in (("key", (-0.15, 0.25, 0.45), 0.5, 8), ("fill", (0.5, -0.1, 0.2), 0.3, 1.5),
			("rim", (0.1, -0.5, 0.35), 0.25, 3)):
		ld = bpy.data.lights.new(name, 'AREA')
		ld.size = size
		ld.energy = energy
		lo_ = bpy.data.objects.new(name, ld)
		lo_.location = loc
		lo_.rotation_euler = (Vector((0, 0, 0.06)) - Vector(loc)).to_track_quat('-Z', 'Y').to_euler()
		sc.collection.objects.link(lo_)
	floor = bpy.data.meshes.new("floor")
	floor.from_pydata([(-2, -2, 0), (2, -2, 0), (2, 2, 0), (-2, 2, 0)], [], [(0, 1, 2, 3)])
	fo = bpy.data.objects.new("floor", floor)
	fm = bpy.data.materials.new("floor")
	fm.use_nodes = True
	fm.node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value = (0.05, 0.05, 0.05, 1)
	floor.materials.append(fm)
	sc.collection.objects.link(fo)
	cam = bpy.data.objects.new("cam", bpy.data.cameras.new("cam"))
	cam.data.lens = 60
	sc.collection.objects.link(cam)
	sc.camera = cam
	sc.cycles.samples = 64
	sc.cycles.use_denoising = True
	sc.render.resolution_x, sc.render.resolution_y = 1400, 1000
	sc.view_settings.view_transform = 'AgX'
	for name, eye, target in (("front", (0.24, -0.42, 0.34), (0, 0, 0.06)), ("left", (-0.45, -0.25, 0.28), (0, 0, 0.06)),
			("dial", (0.03, -0.24, 0.24), (0.0, -0.04, 0.08)), ("back", (0.3, 0.42, 0.3), (0, 0, 0.06))):
		cam.location = eye
		cam.rotation_euler = (Vector(target) - Vector(eye)).to_track_quat('-Z', 'Y').to_euler()
		sc.render.filepath = os.path.join(RENDER, "phone_%s.png" % name)
		bpy.ops.render.render(write_still=True)
