# Baut den Stuhl des Speisesaals (Chair, ZIM-156) nach der Skizze des Nutzers vom 2.11.: einfach, im Holz der
# Vertäfelung wie Kommode und Schreibtisch (Mat.hotel_wood). Vier gerade Beine, innen nach unten verjüngt; eine Zarge
# unter dem Sitz, vorn und seitlich mit flachem Bogen an der Unterkante; die hinteren Beine laufen als Pfosten der
# Lehne weiter und biegen sich darüber in einem leichten Bogen nach hinten (RAKE, Wunsch des Nutzers entgegen der
# Skizze), oben mit Fase. Dazwischen ein Kopfbrett mit Bogen an der Oberkante und eine Querleiste; beide sind in der
# Mitte BOW nach hinten gewölbt. Darauf ein Sitzkissen: unten flach und eckig, oben über ROUND gerundet und zur Mitte
# leicht gewölbt, hinten um die Pfosten ausgespart.
#
# Alle Hölzer sind Stränge mit gerundetem Rechteck als Querschnitt (sweep), die Kanten EDGE weich. Gebacken wird nur
# die Verschattung (AO) in einen gemeinsamen Atlas für Holz und Kissen; die Normale kommt aus dem Mesh.
#
# Lage (Godot-Achsen, wie Chair): Boden y = 0, Mitte x = 0, Sitzseite nach +Z.
# Objekte:
#   „frame“    Gestell, Holz (Mat.hotel_wood mit AO aus dem Atlas)
#   „cushion“  Sitzkissen, Stoff (Fabric_Pattern_08, getönt, mit AO aus dem Atlas)
# Am Ende stehen die Maße für Chair (Kollision, Sitzhöhe).
#
# Aufruf aus dem Projektordner (Blender 4.3):
#   blender -b --python tools/build_chair.py -- assets/models/chair.glb assets/textures/chair
#   (schreibt chair.glb sowie chair_ao.png)
import bpy, bmesh, sys, os, math, random
import numpy as np
from mathutils import Vector

sys.path.append(os.path.dirname(os.path.abspath(__file__)))
from furniture_kit import B, G, Part, atlas_uv, setup_cycles, new_image, bake_material, bake, save_image

argv = sys.argv[sys.argv.index("--") + 1:]
DST = os.path.abspath(argv[0])
TEX = os.path.abspath(argv[1])

# --- Maße (Meter) ------------------------------------------------------------------------------------------------
WIDTH = 0.46              # außen über die Beine = Chair.SIZE.x
DEPTH = 0.47              # Vorderkante Vorderbein bis Hinterkante Hinterbein (am Sitz)
LEG = 0.04                # Beine und Pfosten am Sitz
FOOT = 0.03               # Bein am Boden – innen verjüngt, außen bündig
FRAME = 0.42              # Oberkante Zarge und Vorderbeine = Unterseite des Kissens
APRON_H = 0.085
APRON_T = 0.02
APRON_SET = 0.006         # Zarge hinter den Außenseiten der Beine
APRON_ARCH = (0.014, 0.008)   # Bogen der Unterkante: vorn, seitlich
TOP = 0.95                # Oberkante der Pfosten
POST_TOP = 0.032          # Tiefe der Pfosten oben (am Sitz LEG)
RAKE = 0.07               # so weit liegen die Pfosten oben hinter den Beinen, nach oben zunehmend (Bogen)
BOW = 0.02                # Kopfbrett und Querleiste in der Mitte so weit nach hinten gewölbt
CREST_TOP = 0.935         # Kopfbrett: Oberkante an den Pfosten, Bogen darüber in der Mitte, Höhe an den Enden
CREST_ARCH = 0.015
CREST_H = 0.085
CREST_T = 0.022
RAIL_MID = 0.70           # Querleiste: Mitte, Höhe, Stärke
RAIL_H = 0.045
RAIL_T = 0.02
EDGE = 0.003              # Rundung der Kanten
CHAMFER = 0.004           # Fase oben an den Pfosten
# Kissen: Abstand zu den Außenseiten, Luft um die Pfosten, senkrechte Seite, Höhe nach der Rundung, Breite der
# Rundung, Wölbung zur Mitte (über DOME_RUN erreicht)
CUSHION_INSET = 0.002
NOTCH_CLEAR = 0.003
SIDE = 0.012
CROWN = 0.036
ROUND = 0.035
DOME = 0.008
DOME_RUN = 0.1
EDGE_STEPS = [0.0, 0.002, 0.005, 0.009, 0.014, 0.02, 0.028, 0.038]
FILL_STEP = 0.05

ATLAS = 1024
ISLAND_MARGIN = 0.012     # 12 px – kleinere Mipmap-Stufen mischen sonst die Nachbarinsel herein (wie beim Schreibtisch)
BAKE_MARGIN = 16
AO_DISTANCE = 0.06
AO_STRENGTH = 0.85
AO_SAMPLES = 128

bpy.ops.wm.read_factory_settings(use_empty=True)
random.seed(156)

X_POST = WIDTH / 2.0 - LEG / 2.0
Z_FRONT = DEPTH / 2.0 - LEG / 2.0
Z_REAR = -DEPTH / 2.0 + LEG / 2.0
X_IN = WIDTH / 2.0 - LEG      # Innenseite der Beine
SPAN = TOP - FRAME


## Mitte der Pfosten in der Tiefe auf Höhe y und ihre Steigung dz/dy (über dem Sitz ein Bogen nach hinten)
def post_z(y):
	t = min(max((y - FRAME) / SPAN, 0.0), 1.0)
	return Z_REAR - RAKE * t * t, -2.0 * RAKE * t / SPAN


## Achsen quer zum Pfosten auf Höhe y: entlang (Tangente) und Tiefe
def post_frame(y):
	_, dz = post_z(y)
	along = Vector((0, 1, dz)).normalized()
	return along, Vector((0, -along.z, along.y))


# --- Stränge -----------------------------------------------------------------------------------------------------
## Gerundetes Rechteck um c in der Ebene ex/ey (halbe Breite hw entlang ex, halbe Höhe hh entlang ey), je Ecke steps
## Abschnitte – bei 3 bleiben alle Knicke unter furniture_kit.SHARP, die Kante schattiert weich.
def ring(c, ex, ey, hw, hh, r, steps=3):
	r = min(r, hw * 0.9, hh * 0.9)
	pts = []
	for sx, sy, a0 in ((1, 1, 0), (-1, 1, 90), (-1, -1, 180), (1, -1, 270)):
		cc = c + ex * (sx * (hw - r)) + ey * (sy * (hh - r))
		for k in range(steps + 1):
			a = math.radians(a0 + 90.0 * k / steps)
			pts.append(cc + (ex * math.cos(a) + ey * math.sin(a)) * r)
	return pts


## Strang durch stations = [(Mitte, ex, ey, hw, hh, r)], Faser entlang axis, mit Deckeln an beiden Enden
def sweep(part, stations, piece, axis):
	rings = [ring(*s) for s in stations]
	centers = [s[0] for s in stations]
	t = lambda p: tuple(p)
	for (a, ca), (b, cb) in zip(zip(rings, centers), zip(rings[1:], centers[1:])):
		mid = (ca + cb) / 2.0
		n = len(a)
		for i in range(n):
			j = (i + 1) % n
			q = [a[i], a[j], b[j], b[i]]
			out = sum(q, Vector()) / 4.0 - mid
			part.face([t(p) for p in q], t(out), piece, axis)
	part.face([t(p) for p in rings[0]], t(centers[0] - centers[1]), piece, axis)
	part.face([t(p) for p in rings[-1]], t(centers[-1] - centers[-2]), piece, axis)


X = Vector((1, 0, 0))
Y = Vector((0, 1, 0))
Z = Vector((0, 0, 1))


def front_leg(part, s):
	shrink = (LEG - FOOT) / 2.0   # innen verjüngt: Mitte wandert nach außen
	low = FRAME - APRON_H
	st = [(Vector((s * (X_POST + shrink), 0, Z_FRONT + shrink)), X, Z, FOOT / 2.0, FOOT / 2.0, EDGE)]
	for y in (low, FRAME):
		st.append((Vector((s * X_POST, y, Z_FRONT)), X, Z, LEG / 2.0, LEG / 2.0, EDGE))
	# Strang läuft entlang y: ex/ey quer dazu
	sweep(part, [(c, ex, ey, hw, hh, r) for c, ex, ey, hw, hh, r in st], ("leg", "front", s), "y")


def rear_leg(part, s):
	shrink = (LEG - FOOT) / 2.0
	low = FRAME - APRON_H
	st = [(Vector((s * (X_POST + shrink), 0, Z_REAR - shrink)), X, Z, FOOT / 2.0, FOOT / 2.0, EDGE),
		(Vector((s * X_POST, low, Z_REAR)), X, Z, LEG / 2.0, LEG / 2.0, EDGE)]
	steps = 14
	for k in range(steps + 1):
		y = FRAME + (TOP - CHAMFER - FRAME) * k / steps
		z, _ = post_z(y)
		_, deep = post_frame(y)
		d = LEG + (POST_TOP - LEG) * (y - FRAME) / SPAN
		st.append((Vector((s * X_POST, y, z)), X, deep, LEG / 2.0, d / 2.0, EDGE))
	# Fase oben, dann flacher Deckel
	z, _ = post_z(TOP)
	along, deep = post_frame(TOP)
	c = Vector((s * X_POST, TOP, z))
	st.append((c, X, deep, LEG / 2.0 - CHAMFER, POST_TOP / 2.0 - CHAMFER, 0.001))
	sweep(part, st, ("leg", "rear", s), "y")


## Zarge entlang einer Seite: von Beinmitte a nach b (Mitten auf der Höhe der Zarge), quer = Richtung der Stärke,
## arch = Bogen der Unterkante zwischen den Innenseiten der Beine (inner = halbe lichte Weite)
def apron(part, a, b, across, inner, arch, piece, axis):
	along = (b - a).normalized()
	mid = (a + b) / 2.0
	half = (b - a).length / 2.0
	xs = [-half, -inner] + [-inner + 2.0 * inner * k / 12 for k in range(1, 12)] + [inner, half]
	st = []
	for u in xs:
		q = max(0.0, 1.0 - (u / inner) ** 2) if abs(u) < inner else 0.0
		bottom = FRAME - APRON_H + arch * q
		c = mid + along * u
		c = Vector((c.x, (FRAME + bottom) / 2.0, c.z))
		st.append((c, across, Y, APRON_T / 2.0, (FRAME - bottom) / 2.0, EDGE))
	sweep(part, st, piece, axis)


## Querstück der Lehne zwischen den Pfostenmitten: Unterkante bottom (an den Enden), Höhe h an den Enden, oben arch
## dazu, Stärke t; in der Ebene des Pfostens auf Höhe der Mitte geneigt, zur Mitte BOW nach hinten gewölbt
def back_rail(part, bottom, h, arch, t, piece):
	y_ref = bottom + h / 2.0
	z_ref, _ = post_z(y_ref)
	along, deep = post_frame(y_ref)
	xs = [-X_POST, -X_IN] + [-X_IN + 2.0 * X_IN * k / 16 for k in range(1, 16)] + [X_IN, X_POST]
	st = []
	for x in xs:
		q = max(0.0, 1.0 - (x / X_IN) ** 2) if abs(x) < X_IN else 0.0
		top = h + arch * q
		c = Vector((x, y_ref, z_ref)) + along * (top / 2.0 - h / 2.0) - deep * (BOW * q)
		st.append((c, deep, along, t / 2.0, top / 2.0, EDGE))
	sweep(part, st, piece, "x")


frame = Part("frame")
for s in (-1, 1):
	front_leg(frame, s)
	rear_leg(frame, s)
ya = FRAME - APRON_H / 2.0
zf = DEPTH / 2.0 - APRON_SET - APRON_T / 2.0
zb = -DEPTH / 2.0 + APRON_SET + APRON_T / 2.0
xs = WIDTH / 2.0 - APRON_SET - APRON_T / 2.0
apron(frame, Vector((-X_POST, ya, zf)), Vector((X_POST, ya, zf)), Z, X_IN, APRON_ARCH[0], ("apron", "front"), "x")
apron(frame, Vector((-X_POST, ya, zb)), Vector((X_POST, ya, zb)), Z, X_IN, 0.0, ("apron", "back"), "x")
inner_z = (Z_FRONT - Z_REAR) / 2.0 - LEG / 2.0
for s in (-1, 1):
	apron(frame, Vector((s * xs, ya, Z_REAR)), Vector((s * xs, ya, Z_FRONT)), X, inner_z, APRON_ARCH[1],
		("apron", s), "z")
back_rail(frame, CREST_TOP - CREST_H, CREST_H, CREST_ARCH, CREST_T, ("crest",))
back_rail(frame, RAIL_MID - RAIL_H / 2.0, RAIL_H, 0.0, RAIL_T, ("rail",))
frame_ob = frame.finish()


# --- Kissen ------------------------------------------------------------------------------------------------------
HX = WIDTH / 2.0 - CUSHION_INSET
ZF = DEPTH / 2.0 - CUSHION_INSET
ZB = -DEPTH / 2.0 + CUSHION_INSET
XN = WIDTH / 2.0 - LEG - NOTCH_CLEAR      # Aussparung um die Pfosten
ZN = -DEPTH / 2.0 + LEG + NOTCH_CLEAR
OUTLINE = [(-HX, ZF), (HX, ZF), (HX, ZN), (XN, ZN), (XN, ZB), (-XN, ZB), (-XN, ZN), (-HX, ZN)]


def inside(x, z):
	return -HX - 1e-9 <= x <= HX + 1e-9 and ZB - 1e-9 <= z <= ZF + 1e-9 and not (abs(x) > XN + 1e-9 and z < ZN - 1e-9)


## Abstand zum Rand, über alle Kanten weich gemittelt (p-Norm) – an den Ecken rund statt eines Grats
def edge_distance(x, z):
	acc = 0.0
	p = np.array((x, z))
	for (ax, az), (bx, bz) in zip(OUTLINE, OUTLINE[1:] + OUTLINE[:1]):
		a, b = np.array((ax, az)), np.array((bx, bz))
		t = np.clip(np.dot(p - a, b - a) / np.dot(b - a, b - a), 0, 1)
		d = np.linalg.norm(p - (a + (b - a) * t))
		if d < 1e-7:
			return 0.0
		acc += d ** -4
	return acc ** -0.25


def height(x, z):
	d = edge_distance(x, z)
	if d < ROUND:
		k = 1.0 - d / ROUND
		return FRAME + SIDE + (CROWN - SIDE) * math.sqrt(max(0.0, 1.0 - k * k))
	t = min(1.0, (d - ROUND) / DOME_RUN)
	return FRAME + CROWN + DOME * t * t * (3 - 2 * t)


## Rasterlinien: dicht an den Rändern (EDGE_STEPS nach innen), dazwischen FILL_STEP
def lines(lo, hi, edges):
	out = set()
	for e, inward in edges:
		for d in EDGE_STEPS:
			v = e + inward * d
			if lo - 1e-9 <= v <= hi + 1e-9:
				out.add(round(v, 6))
	dense = sorted(out)
	n = max(1, int(round((hi - lo) / FILL_STEP)))
	for k in range(1, n):
		v = lo + (hi - lo) * k / n
		if min(abs(v - w) for w in dense) > FILL_STEP * 0.4:
			out.add(round(v, 6))
	return sorted(out)


gx = lines(-HX, HX, [(-HX, 1), (HX, -1), (-XN, -1), (XN, 1), (-XN, 1), (XN, -1)])
gz = lines(ZB, ZF, [(ZB, 1), (ZF, -1), (ZN, -1), (ZN, 1)])
cushion = Part("cushion", grain_shift=0.5)
top = {}
for i, x in enumerate(gx):
	for j, z in enumerate(gz):
		if inside(x, z):
			top[i, j] = (x, height(x, z), z)
cells = set()
for i in range(len(gx) - 1):
	for j in range(len(gz) - 1):
		if inside((gx[i] + gx[i + 1]) / 2.0, (gz[j] + gz[j + 1]) / 2.0):
			cells.add((i, j))
for i, j in cells:
	q = [top[i, j], top[i + 1, j], top[i + 1, j + 1], top[i, j + 1]]
	cushion.face(q, (0, 1, 0), ("top",), "x")
	# Seiten: Kanten der Zelle, hinter denen keine Zelle liegt
	for (a, b), (di, dj) in ((((i, j), (i + 1, j)), (0, -1)), (((i + 1, j), (i + 1, j + 1)), (1, 0)),
			(((i + 1, j + 1), (i, j + 1)), (0, 1)), (((i, j + 1), (i, j)), (-1, 0))):
		if (i + di, j + dj) in cells:
			continue
		pa, pb = top[a], top[b]
		cushion.face([(pa[0], FRAME, pa[2]), (pb[0], FRAME, pb[2]), pb, pa], (di, 0, dj), ("side", di, dj),
			"x" if dj != 0 else "z")
# Boden: eine Fläche über den unteren Rand (nach dem Verschmelzen), flach
bm = cushion.bm
bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=1e-6)
rim = [e for e in bm.edges if e.is_boundary]
made = bmesh.ops.holes_fill(bm, edges=rim, sides=0)["faces"]
for f in made:
	f.normal_update()
	if f.normal.dot(B(0, -1, 0)) < 0:
		f.normal_flip()
	for loop in f.loops:
		p = G(loop.vert.co)
		loop[cushion.uv].uv = (p.x, p.z)
cushion_ob = cushion.finish()


# --- Atlas und Backen --------------------------------------------------------------------------------------------
obs = [frame_ob, cushion_ob]
atlas_uv(obs, ISLAND_MARGIN)
sc = setup_cycles()
sc.render.bake.margin = BAKE_MARGIN
for ob in obs:
	ob.data.materials.append(bake_material("chair_src"))
sc.world.light_settings.distance = AO_DISTANCE
ao = bake(obs, 'AO', new_image("chair_ao", ATLAS, False, True), AO_SAMPLES)[..., 0]
print("AO: Mittel %.3f, dunkelster Wert %.3f" % (ao.mean(), ao.min()))
ao = 1.0 - AO_STRENGTH * (1.0 - np.clip(ao, 0, 1))
save_image("chair_ao_out", ao, TEX + "_ao.png")


# --- Export ------------------------------------------------------------------------------------------------------
for ob in obs:
	ob.data.materials.clear()   # Holz und Stoff setzt Chair
	if "group" in ob.data.attributes:
		ob.data.attributes.remove(ob.data.attributes["group"])
	tris = sum(len(p.vertices) - 2 for p in ob.data.polygons)
	print("%-8s %5d Dreiecke, UV-Sätze %s" % (ob.name, tris, [l.name for l in ob.data.uv_layers]))
bpy.ops.object.select_all(action='DESELECT')
for ob in obs:
	ob.select_set(True)
bpy.ops.export_scene.gltf(
	filepath=DST, export_format='GLB', export_yup=True, export_apply=False, use_selection=True,
	export_texcoords=True, export_normals=True, export_tangents=False, export_materials='NONE',
	export_skins=False, export_animations=False, export_morph=False, export_cameras=False, export_lights=False)
zs = [G(v.co).z for v in frame_ob.data.vertices]
seat = max(G(v.co).y for v in cushion_ob.data.vertices)
print("Maße: Breite %.3f, Tiefe %.3f (z %.3f bis %.3f), Höhe %.3f, Kissen oben %.3f, Lehne ab z %.3f"
	% (WIDTH, max(zs) - min(zs), min(zs), max(zs), max(G(v.co).y for v in frame_ob.data.vertices), seat,
	-DEPTH / 2.0 + LEG))
print("geschrieben:", DST, TEX + "_ao.png")
