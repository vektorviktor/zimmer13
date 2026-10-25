# Baut die Kerzen (Spielkonzept 5.4, 7.3) aus drei Sketchfab-Modellen:
#   assets/models/candle.glb – „candle_red“ und „candle_white“: die Kerze aus „Candlestick“ von FlukierJupiter
#     (https://sketchfab.com/FlukierJupiter, CC-BY 4.0, https://sketchfab.com/3d-models/candlestick-d1a0b96e5b3e44a9ba548ba9a8864c0d)
#     ohne den Ständer, CANDLE_HEIGHT hoch (Wachs ohne Docht), Ursprung mittig unten; rot wie im Original und weiß
#     umgefärbt (dasselbe Netz, zwei Texturen). „plate“: der Teller aus „Lowpoly Candle“ von matoteus
#     (https://sketchfab.com/matoteus, CC-BY 4.0, https://sketchfab.com/3d-models/lowpoly-candle-c5b1ca5b8492426199932f6b1a64a4d9)
#     ohne Säule und Tülle in der Mitte – das Loch im Boden schließt eine flache Scheibe, deren Textur der Boden
#     gespiegelt fortsetzt; die Gravur aus der Normal Map steckt als Licht und Schatten in der Farbtextur
#     (psx_surface kennt keine Normal Map). PLATE_RADIUS außen, Ursprung mittig unten.
#   assets/models/candle_flame.glb – „flame“: die Flamme der höchsten Kerze aus „Candles set“ von shuvalov.di
#     (https://sketchfab.com/shuvalov.di, CC-BY-SA 4.0, https://sketchfab.com/3d-models/candles-set-f09212756bc94764a8bcfcd3c7e38f8e)
#     in Originalgröße, Ursprung mittig am Fuß der Flamme. Die Bewegung ist ein Vertex-Cache: 100 Formschlüssel,
#     je Bild einer. Das Original zeigt den ersten zweimal und den letzten nie – die Animation „flicker“ zeigt
#     alle der Reihe nach und endet wieder beim ersten (nahtlose Schleife, FPS Bilder je Sekunde). Ohne Textur:
#     Farbe und Leuchten macht shaders/candle_flame.gdshader.
# Am Ende stehen die Maße – für CandleModel.
#
# Aufruf (Blender 4.3):
#   blender -b --python tools/build_candle.py -- assets/source assets/models
#   (liest lowpoly_candle.glb, candlestick.glb und candles_set.glb)
import bpy, bmesh, sys, os, math
import numpy as np
from mathutils import Matrix, Vector

CANDLE_HEIGHT = 0.16    # Meter, Wachs ohne Docht
PLATE_RADIUS = 0.06     # Meter, außen
TEX_SIZE = 256
FPS = 24
## Weißes Wachs (sRGB); die Flecken des roten Wachses bleiben schwächer (WHITE_DETAIL) erhalten
WHITE_WAX = (0.93, 0.89, 0.79)
WHITE_DETAIL = 0.6
## Teller (Einheiten des Originals, Teller 1,54 breit): was näher als CUT_R an der Achse und höher als CUT_Z liegt,
## gehört zu Säule und Tülle und fällt weg; die Scheibe dafür bekommt CAP_RINGS Ringe
CUT_R = 0.45
CUT_Z = -0.935
CAP_RINGS = 3
## Gravur in die Farbe: Licht von oben links in Texturrichtung (RELIEF), Kanten dunkler (CAVITY)
RELIEF = 0.45
CAVITY = 0.5
LIGHT_UV = (-0.6, 0.8)

argv = sys.argv[sys.argv.index("--") + 1:]
SRC_DIR, DST_DIR = argv[0], argv[1]

bpy.ops.wm.read_factory_settings(use_empty=True)
scene = bpy.context.scene


def import_glb(name):
	"""Importiert eine GLB und gibt ihre Objekte zurück."""
	before = set(scene.objects)
	bpy.ops.import_scene.gltf(filepath=os.path.join(SRC_DIR, name))
	return [o for o in scene.objects if o not in before]


def keep_only(objs, keep):
	"""Weltmatrix ins Netz der behaltenen Objekte, alles andere aus dem Import löschen."""
	for o in keep:
		o.data.transform(o.matrix_world, shape_keys=o.data.shape_keys is not None)
		o.parent = None
		o.matrix_world = Matrix.Identity(4)
	for o in objs:
		if o not in keep:
			bpy.data.objects.remove(o)


def base_image(o, socket="Base Color"):
	for n in o.data.materials[0].node_tree.nodes:
		if n.type == 'BSDF_PRINCIPLED':
			link = n.inputs[socket].links
			if link:
				node = link[0].from_node
				# Normal Map: Bild hängt hinter dem Normal-Map-Knoten
				return node.image if node.type == 'TEX_IMAGE' else node.inputs["Color"].links[0].from_node.image
	return None


def pixels(img):
	W, H = img.size
	return np.array(img.pixels[:], dtype=np.float32).reshape(H, W, 4)   # Zeile 0 = unten wie UV v = 0


def crop_to_uvs(me, arrays, margin=4):
	"""Schneidet den UV-Bereich des Netzes aus den Bildern (gleich groß) und legt die UVs auf das Stück um."""
	uv = me.uv_layers.active.data
	us = np.array([d.uv.x for d in uv])
	vs = np.array([d.uv.y for d in uv])
	H, W = arrays[0].shape[:2]
	x0 = max(int(math.floor(us.min() * W)) - margin, 0)
	x1 = min(int(math.ceil(us.max() * W)) + margin, W)
	y0 = max(int(math.floor(vs.min() * H)) - margin, 0)
	y1 = min(int(math.ceil(vs.max() * H)) + margin, H)
	for d in uv:
		d.uv = ((d.uv.x * W - x0) / (x1 - x0), (d.uv.y * H - y0) / (y1 - y0))
	print("%s: UV %.3f..%.3f × %.3f..%.3f → Ausschnitt %d × %d px" % (me.name, us.min(), us.max(), vs.min(), vs.max(), x1 - x0, y1 - y0))
	return [a[y0:y1, x0:x1].copy() for a in arrays]


def make_image(name, arr):
	h, w = arr.shape[:2]
	img = bpy.data.images.new(name, w, h, alpha=False)
	img.pixels.foreach_set(np.ascontiguousarray(arr, dtype=np.float32).ravel())
	img.scale(TEX_SIZE, TEX_SIZE)
	img.file_format = 'PNG'
	img.pack()
	return img


def textured(name, img):
	mat = bpy.data.materials.new(name)
	mat.use_nodes = True
	nodes = mat.node_tree.nodes
	tex = nodes.new("ShaderNodeTexImage")
	tex.image = img
	tex.interpolation = 'Closest'
	mat.node_tree.links.new(tex.outputs["Color"], nodes["Principled BSDF"].inputs["Base Color"])
	return mat


def components(bm):
	"""Zusammenhängende Teile (Listen von Punkten)."""
	seen = set()
	parts = []
	for v in bm.verts:
		if v in seen:
			continue
		stack, comp = [v], []
		seen.add(v)
		while stack:
			x = stack.pop()
			comp.append(x)
			for e in x.link_edges:
				y = e.other_vert(x)
				if y not in seen:
					seen.add(y)
					stack.append(y)
		parts.append(comp)
	return parts


def affine_uv(bm, faces):
	"""UV als affine Funktion von (x, y) über diese Flächen (Draufsicht-Projektion) – Koeffizienten und Restfehler."""
	uv_layer = bm.loops.layers.uv.active
	rows, us, vs = [], [], []
	for f in faces:
		for l in f.loops:
			rows.append((l.vert.co.x, l.vert.co.y, 1.0))
			us.append(l[uv_layer].uv.x)
			vs.append(l[uv_layer].uv.y)
	A = np.array(rows)
	cu = np.linalg.lstsq(A, np.array(us), rcond=None)[0]
	cv = np.linalg.lstsq(A, np.array(vs), rcond=None)[0]
	err = max(np.abs(A @ cu - us).max(), np.abs(A @ cv - vs).max())
	return cu, cv, err


def smooth(o, angle=40.0):
	"""Eigene Normalen des Imports weg, glatt bis zu angle Grad (scharfe Kanten darüber)."""
	with bpy.context.temp_override(object=o, active_object=o, selected_objects=[o]):
		bpy.ops.mesh.customdata_custom_splitnormals_clear()
	o.data.shade_smooth()
	o.data.set_sharp_from_angle(angle=math.radians(angle))


# --- Kerze ------------------------------------------------------------------------------------
objs = import_glb("candlestick.glb")
candle = next(o for o in objs if o.type == 'MESH')
atlas = pixels(base_image(candle))
keep_only(objs, [candle])
bm = bmesh.new()
bm.from_mesh(candle.data)
# Punkte an UV-Nähten verschmelzen (UVs hängen an den Ecken der Flächen und bleiben), dann in Teile zerlegen:
# Ständer (weit über die Kerze hinaus), Kerze, Docht
bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=1e-4)
parts = components(bm)
radius = lambda comp: max(math.hypot(v.co.x, v.co.y) for v in comp)
holder = [comp for comp in parts if radius(comp) > 3.0]
bmesh.ops.delete(bm, geom=[v for comp in holder for v in comp], context='VERTS')
parts = components(bm)
body = max(parts, key=len)
wick = [v for comp in parts if comp is not body for v in comp]
print("Kerze: %d Teile, Ständer weg (%d Punkte), Wachs %d Punkte, Docht %d Punkte"
	% (len(parts) + len(holder), sum(len(c) for c in holder), len(body), len(wick)))
bm.normal_update()
open_edges = [e for e in bm.edges if e.is_boundary and e.verts[0] in body]
if open_edges:
	# Unten offen (steckte im Ständer): Boden schließen, Textur wie der Deckel (Draufsicht-affin)
	uv_layer = bm.loops.layers.uv.active
	top = [f for f in bm.faces if f.normal.z > 0.9 and f.verts[0] in body]
	cu, cv, err = affine_uv(bm, top)
	new = bmesh.ops.holes_fill(bm, edges=open_edges, sides=0)["faces"]
	for f in new:
		f.normal_update()
		if f.normal.z > 0:
			f.normal_flip()
		for l in f.loops:
			p = (l.vert.co.x, l.vert.co.y, 1.0)
			l[uv_layer].uv = (float(np.dot(cu, p)), float(np.dot(cv, p)))
	print("Kerze: Boden geschlossen (%d Kanten, Deckel-UV-Fehler %.4f)" % (len(open_edges), err))
zs = [v.co.z for v in body]
z0, z_top = min(zs), max(zs)
cx = (min(v.co.x for v in body) + max(v.co.x for v in body)) / 2.0
cy = (min(v.co.y for v in body) + max(v.co.y for v in body)) / 2.0
wick_top = max(v.co.z for v in wick) if wick else z_top
bm.to_mesh(candle.data)
bm.free()
s = CANDLE_HEIGHT / (z_top - z0)
candle.data.transform(Matrix.Scale(s, 4) @ Matrix.Translation((-cx, -cy, -z0)))
smooth(candle)
red_px, = crop_to_uvs(candle.data, [atlas])
# Weiß: wo das Wachs rot ist (der Docht bleibt schwarz), Helligkeit aus dem Rotkanal – die Flecken etwas schwächer
r, g, b = red_px[..., 0], red_px[..., 1], red_px[..., 2]
wax = np.clip((r - np.maximum(g, b) - 0.05) / 0.1, 0.0, 1.0)
mean = float((r * wax).sum() / max(wax.sum(), 1.0))
rel = 1.0 + (np.clip(r / mean, 0.6, 1.3) - 1.0) * WHITE_DETAIL
white_px = red_px.copy()
for c in range(3):
	white_px[..., c] = red_px[..., c] * (1.0 - wax) + np.clip(WHITE_WAX[c] * rel, 0.0, 1.0) * wax
candle.name = candle.data.name = "candle_red"
candle.data.materials.clear()
candle.data.materials.append(textured("candle_red", make_image("candle_red", red_px)))
white = candle.copy()
white.data = candle.data.copy()
white.name = white.data.name = "candle_white"
scene.collection.objects.link(white)
white.data.materials.clear()
white.data.materials.append(textured("candle_white", make_image("candle_white", white_px)))
candle_r = max(math.hypot(v.co.x, v.co.y) for v in candle.data.vertices if v.co.z < CANDLE_HEIGHT * 0.9)
candle_tris = sum(len(p.vertices) - 2 for p in candle.data.polygons)

# --- Teller -----------------------------------------------------------------------------------
objs = import_glb("lowpoly_candle.glb")
plate = next(o for o in objs if o.type == 'MESH' and o.parent and o.parent.name == "pCylinder1")
atlas = pixels(base_image(plate))
normals = pixels(base_image(plate, "Normal"))
keep_only(objs, [plate])
bm = bmesh.new()
bm.from_mesh(plate.data)
bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=1e-5)
bm.normal_update()
uv_layer = bm.loops.layers.uv.active
# Boden um das Loch (nach oben gewandt, unter CUT_Z): aus seinen Dreiecken die UVs für die Scheibe
bm.faces.ensure_lookup_table()
floor = [tri for tri in bm.calc_loop_triangles() if tri[0].face.normal.z > 0.9
	and all(l.vert.co.z < CUT_Z and 0.2 < math.hypot(l.vert.co.x, l.vert.co.y) < 0.62 for l in tri)]
floor = [([l.vert.co.xy.copy() for l in tri], [l[uv_layer].uv.copy() for l in tri]) for tri in floor]
cut = [v for v in bm.verts if math.hypot(v.co.x, v.co.y) < CUT_R and v.co.z > CUT_Z]
bmesh.ops.delete(bm, geom=cut, context='VERTS')
ring = [v for v in bm.verts if any(e.is_boundary for e in v.link_edges)]
ring.sort(key=lambda v: math.atan2(v.co.y, v.co.x))
r0 = sum(math.hypot(v.co.x, v.co.y) for v in ring) / len(ring)
zc = sum(v.co.z for v in ring) / len(ring)
print("Teller: %d Punkte weg, Loch mit %d Punkten (Radius %.3f..%.3f, Höhe %.3f..%.3f), %d Bodendreiecke"
	% (len(cut), len(ring), min(math.hypot(v.co.x, v.co.y) for v in ring), max(math.hypot(v.co.x, v.co.y) for v in ring),
	min(v.co.z for v in ring), max(v.co.z for v in ring), len(floor)))


def floor_uv(p):
	# UV des Bodens an der Stelle p (Draufsicht): baryzentrisch im Dreieck darunter, sonst im nächsten
	best, best_d = None, 1e9
	for (a, b, c), uvs in floor:
		den = (b.y - c.y) * (a.x - c.x) + (c.x - b.x) * (a.y - c.y)
		if abs(den) < 1e-12:
			continue
		w0 = ((b.y - c.y) * (p.x - c.x) + (c.x - b.x) * (p.y - c.y)) / den
		w1 = ((c.y - a.y) * (p.x - c.x) + (a.x - c.x) * (p.y - c.y)) / den
		w2 = 1.0 - w0 - w1
		d = -min(w0, w1, w2)
		if d < best_d:
			best, best_d = (w0, w1, w2, uvs), d
	w0, w1, w2, uvs = best
	return tuple(uvs[0] * w0 + uvs[1] * w1 + uvs[2] * w2)


def cap_uv(x, y):
	# Spiegelung am Lochrand: Punkt im Abstand d innerhalb bekommt die Textur von d außerhalb
	r = math.hypot(x, y)
	a = math.atan2(y, x)
	return floor_uv(Vector(((2.0 * r0 - r) * math.cos(a), (2.0 * r0 - r) * math.sin(a))))


rings = [ring]
for k in range(1, CAP_RINGS):
	f = (CAP_RINGS - k) / CAP_RINGS
	rings.append([bm.verts.new((v.co.x * f, v.co.y * f, zc)) for v in ring])
center = bm.verts.new((0.0, 0.0, zc))
n = len(ring)
cap = []
for outer, inner in zip(rings, rings[1:]):
	for i in range(n):
		j = (i + 1) % n
		cap.append(bm.faces.new((outer[i], outer[j], inner[j], inner[i])))
for i in range(n):
	cap.append(bm.faces.new((rings[-1][i], rings[-1][(i + 1) % n], center)))
for f in cap:
	f.normal_update()
	if f.normal.z < 0:
		f.normal_flip()
	others = [l.vert for l in f.loops if l.vert is not center]
	for l in f.loops:
		if l.vert is center:
			mx = sum(v.co.x for v in others)
			my = sum(v.co.y for v in others)
			a = math.atan2(my, mx)
			l[uv_layer].uv = cap_uv(1e-4 * math.cos(a), 1e-4 * math.sin(a))
		else:
			l[uv_layer].uv = cap_uv(l.vert.co.x, l.vert.co.y)
bm.to_mesh(plate.data)
bm.free()
vs = plate.data.vertices
pr = max(math.hypot(v.co.x, v.co.y) for v in vs)
pz0 = min(v.co.z for v in vs)
s = PLATE_RADIUS / pr
plate.data.transform(Matrix.Scale(s, 4) @ Matrix.Translation((0.0, 0.0, -pz0)))
smooth(plate, 50.0)
plate_floor = (zc - pz0) * s
plate_top = max(v.co.z for v in plate.data.vertices)
col, nrm = crop_to_uvs(plate.data, [atlas, normals])
nx = nrm[..., 0] * 2.0 - 1.0
ny = nrm[..., 1] * 2.0 - 1.0
shade = np.clip(1.0 + RELIEF * (nx * LIGHT_UV[0] + ny * LIGHT_UV[1]) - CAVITY * np.sqrt(nx * nx + ny * ny), 0.35, 1.5)
for c in range(3):
	col[..., c] = np.clip(col[..., c] * shade, 0.0, 1.0)
plate.name = plate.data.name = "plate"
plate.data.materials.clear()
plate.data.materials.append(textured("plate", make_image("plate", col)))
plate_tris = sum(len(p.vertices) - 2 for p in plate.data.polygons)

bpy.ops.object.select_all(action='DESELECT')
for o in (candle, white, plate):
	o.select_set(True)
bpy.ops.export_scene.gltf(filepath=os.path.join(DST_DIR, "candle.glb"), export_format='GLB', use_selection=True,
	export_yup=True, export_image_format='AUTO', export_texcoords=True, export_normals=True, export_materials='EXPORT',
	export_animations=False)

# --- Flamme -----------------------------------------------------------------------------------
objs = import_glb("candles_set.glb")
flame = next(o for o in objs if o.type == 'MESH' and o.parent and o.parent.name.startswith("Flame_1"))
keep_only(objs, [flame])
for a in list(bpy.data.actions):
	bpy.data.actions.remove(a)
co = [v.co for v in flame.data.vertices]
fx = (min(p.x for p in co) + max(p.x for p in co)) / 2.0
fy = (min(p.y for p in co) + max(p.y for p in co)) / 2.0
fz = min(p.z for p in co)
flame.data.transform(Matrix.Translation((-fx, -fy, -fz)), shape_keys=True)
flame.data.shade_smooth()
flame.name = flame.data.name = "flame"
flame.data.materials.clear()
flame.data.materials.append(bpy.data.materials.new("flame"))
keys = flame.data.shape_keys
targets = [k for k in keys.key_blocks if k != keys.reference_key]
count = len(targets)
# Bild i + 1 zeigt Formschlüssel i, Bild count + 1 wieder den ersten (gleich dem Anfang → nahtlos)
action = bpy.data.actions.new("flicker")
keys.animation_data_create()
keys.animation_data.action = action
for i, k in enumerate(targets):
	fc = action.fcurves.new('key_blocks["%s"].value' % k.name)
	frames = {i: 0.0, i + 1: 1.0, i + 2: 0.0}
	if i == 0:
		frames.update({0: 0.0, count: 0.0, count + 1: 1.0})
	for f, val in sorted(frames.items()):
		if 1 <= f <= count + 1:
			kp = fc.keyframe_points.insert(f, val)
			kp.interpolation = 'LINEAR'
scene.frame_start = 1
scene.frame_end = count + 1
scene.render.fps = FPS
bpy.ops.object.select_all(action='DESELECT')
flame.select_set(True)
bpy.ops.export_scene.gltf(filepath=os.path.join(DST_DIR, "candle_flame.glb"), export_format='GLB', use_selection=True,
	export_yup=True, export_texcoords=True, export_normals=True, export_materials='EXPORT', export_morph=True,
	export_morph_normal=True, export_animations=True, export_force_sampling=True, export_frame_step=1)
fco = [v.co for v in flame.data.vertices]

# Blender (x, y, z) → Godot (x, z, −y)
print("candle: %d Dreiecke, %.3f m hoch, Radius %.4f m, Docht bis %.4f m" % (candle_tris, CANDLE_HEIGHT, candle_r, (wick_top - z0) * CANDLE_HEIGHT / (z_top - z0)))
print("plate: %d Dreiecke, Radius %.3f m, %.4f m hoch, Boden bei %.4f m, Loch-Scheibe Radius %.4f m"
	% (plate_tris, PLATE_RADIUS, plate_top, plate_floor, r0 * s))
print("flame: %d Dreiecke, %.4f m hoch, %.4f m breit, %d Formschlüssel, %.3f s Schleife"
	% (sum(len(p.vertices) - 2 for p in flame.data.polygons), max(p.z for p in fco), max(p.x for p in fco) - min(p.x for p in fco), count, count / FPS))
