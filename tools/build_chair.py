# Baut den Stuhl des Speisesaals (Chair, ZIM-156) nach der Skizze des Nutzers vom 2.11., auf seinen Wunsch vom selben
# Tag so schlicht wie möglich (deutlich unter 600 Dreiecke): im Holz der Vertäfelung wie Kommode und Tafel
# (Mat.hotel_wood), alle Hölzer kantig ohne Fasen. Vier gerade Beine, eine gerade Zarge unter dem Sitz; die hinteren
# Beine laufen über dem Sitz gerade und schräg nach hinten weiter (RAKE, ohne Bogen). Dazwischen ein Kopfbrett mit
# gerader Oberkante und eine Querleiste, beide in der Mitte BOW nach hinten gewölbt. Darauf ein rechteckiges
# Sitzkissen bis vor die Pfosten: unten flach, oben über ROUND zu den Kanten gerundet, zur Mitte leicht gewölbt.
#
# Gebacken wird nur die Verschattung (AO) in einen gemeinsamen Atlas für Holz und Kissen; die Normale kommt aus dem
# Mesh.
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
import bpy, sys, os, math, random
import numpy as np
from mathutils import Vector

sys.path.append(os.path.dirname(os.path.abspath(__file__)))
from furniture_kit import G, Part, atlas_uv, setup_cycles, new_image, bake_material, bake, save_image

argv = sys.argv[sys.argv.index("--") + 1:]
DST = os.path.abspath(argv[0])
TEX = os.path.abspath(argv[1])

# --- Maße (Meter) ------------------------------------------------------------------------------------------------
WIDTH = 0.46              # außen über die Beine = Chair.SIZE.x
DEPTH = 0.47              # Vorderkante Vorderbein bis Hinterkante Hinterbein (am Sitz)
LEG = 0.04                # Beine und Pfosten, quadratisch
FRAME = 0.42              # Oberkante Zarge und Vorderbeine = Unterseite des Kissens
APRON_H = 0.085
APRON_T = 0.02
APRON_SET = 0.006         # Zarge hinter den Außenseiten der Beine
TOP = 0.95                # Oberkante der Pfosten
RAKE = 0.07               # so weit liegen die Pfosten oben hinter den Beinen (gerade Schräge)
BOW = 0.02                # Kopfbrett und Querleiste in der Mitte so weit nach hinten gewölbt
BOW_STEPS = 8             # Abschnitte der Wölbung zwischen den Pfosten
CREST_TOP = 0.935         # Kopfbrett: Oberkante (gerade), Höhe, Stärke
CREST_H = 0.085
CREST_T = 0.022
RAIL_MID = 0.70           # Querleiste: Mitte, Höhe, Stärke
RAIL_H = 0.045
RAIL_T = 0.02
# Kissen: Abstand zu den Außenseiten und vor den Pfosten, senkrechte Seite, Höhe nach der Rundung, Breite der Rundung
# (ROUND_STEPS Abschnitte – bei 3 bleibt jeder Knick unter furniture_kit.SHARP, die Kante schattiert weich), Wölbung
# zur Mitte
CUSHION_INSET = 0.002
POST_CLEAR = 0.004
SIDE = 0.012
CROWN = 0.036
ROUND = 0.035
ROUND_STEPS = 3
DOME = 0.008

ATLAS = 512
ISLAND_MARGIN = 0.024     # 12 px – kleinere Mipmap-Stufen mischen sonst die Nachbarinsel herein (wie beim Schreibtisch)
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
X = Vector((1, 0, 0))
Y = Vector((0, 1, 0))
Z = Vector((0, 0, 1))
# Pfosten über dem Sitz: Richtung nach oben und quer dazu nach vorn
ALONG = Vector((0, TOP - FRAME, -RAKE)).normalized()
DEEP = Vector((0, -ALONG.z, ALONG.y))


## Mitte des Pfostens auf Höhe y (über dem Sitz gerade nach hinten geneigt)
def post_z(y):
	return Z_REAR - RAKE * max(0.0, y - FRAME) / (TOP - FRAME)


# --- Stränge -----------------------------------------------------------------------------------------------------
## Rechteck um c in der Ebene ex/ey (halbe Breite hw entlang ex, halbe Höhe hh entlang ey)
def ring(c, ex, ey, hw, hh):
	return [c + ex * hw + ey * hh, c - ex * hw + ey * hh, c - ex * hw - ey * hh, c + ex * hw - ey * hh]


## Kantiger Strang durch stations = [(Mitte, ex, ey, hw, hh)], Faser entlang axis; Deckel nur, wo caps es sagt
## (Enden in einem anderen Holz oder auf dem Boden bleiben offen)
def sweep(part, stations, piece, axis, caps=(True, True)):
	rings = [ring(*s) for s in stations]
	centers = [s[0] for s in stations]
	t = lambda p: tuple(p)
	for (a, ca), (b, cb) in zip(zip(rings, centers), zip(rings[1:], centers[1:])):
		mid = (ca + cb) / 2.0
		for i in range(4):
			j = (i + 1) % 4
			q = [a[i], a[j], b[j], b[i]]
			part.face([t(p) for p in q], t(sum(q, Vector()) / 4.0 - mid), piece, axis)
	if caps[0]:
		part.face([t(p) for p in rings[0]], t(centers[0] - centers[1]), piece, axis)
	if caps[1]:
		part.face([t(p) for p in rings[-1]], t(centers[-1] - centers[-2]), piece, axis)


def front_leg(part, s):
	c = lambda y: Vector((s * X_POST, y, Z_FRONT))
	sweep(part, [(c(0), X, Z, LEG / 2.0, LEG / 2.0), (c(FRAME), X, Z, LEG / 2.0, LEG / 2.0)], ("leg", "front", s), "y",
		(False, True))


## Hinteres Bein: senkrecht bis zum Sitz, darüber gerade schräg nach hinten, oben flach abgeschnitten
def rear_leg(part, s):
	c = lambda y: Vector((s * X_POST, y, post_z(y)))
	sweep(part, [(c(0), X, Z, LEG / 2.0, LEG / 2.0), (c(FRAME), X, Z, LEG / 2.0, LEG / 2.0),
		(c(TOP), X, DEEP, LEG / 2.0, LEG / 2.0)], ("leg", "rear", s), "y", (False, True))


## Zarge von Beinmitte a nach b (Mitten auf halber Höhe der Zarge), quer = Richtung der Stärke; die Enden stecken in
## den Beinen
def apron(part, a, b, across, piece, axis):
	sweep(part, [(a, across, Y, APRON_T / 2.0, APRON_H / 2.0), (b, across, Y, APRON_T / 2.0, APRON_H / 2.0)], piece,
		axis, (False, False))


## Querstück der Lehne zwischen den Pfostenmitten, Mitte auf Höhe y, in der Ebene der Pfosten geneigt, zur Mitte BOW
## nach hinten gewölbt (Bogen in BOW_STEPS geraden Abschnitten); die Enden stecken in den Pfosten
def back_rail(part, y, h, t, piece):
	xs = [-X_POST] + [-X_IN + 2.0 * X_IN * k / BOW_STEPS for k in range(BOW_STEPS + 1)] + [X_POST]
	st = []
	for x in xs:
		q = max(0.0, 1.0 - (x / X_IN) ** 2)
		st.append((Vector((x, y, post_z(y))) - DEEP * (BOW * q), DEEP, ALONG, t / 2.0, h / 2.0))
	sweep(part, st, piece, "x", (False, False))


frame = Part("frame")
for s in (-1, 1):
	front_leg(frame, s)
	rear_leg(frame, s)
ya = FRAME - APRON_H / 2.0
zf = DEPTH / 2.0 - APRON_SET - APRON_T / 2.0
zb = -DEPTH / 2.0 + APRON_SET + APRON_T / 2.0
xs = WIDTH / 2.0 - APRON_SET - APRON_T / 2.0
apron(frame, Vector((-X_POST, ya, zf)), Vector((X_POST, ya, zf)), Z, ("apron", "front"), "x")
apron(frame, Vector((-X_POST, ya, zb)), Vector((X_POST, ya, zb)), Z, ("apron", "back"), "x")
for s in (-1, 1):
	apron(frame, Vector((s * xs, ya, Z_REAR)), Vector((s * xs, ya, Z_FRONT)), X, ("apron", s), "z")
back_rail(frame, CREST_TOP - CREST_H / 2.0, CREST_H, CREST_T, ("crest",))
back_rail(frame, RAIL_MID, RAIL_H, RAIL_T, ("rail",))
frame_ob = frame.finish()


# --- Kissen ------------------------------------------------------------------------------------------------------
## Rechteck von vorn bis vor die Pfosten. Ringe von unten nach oben: senkrechte Seite, dann die Rundung nach innen;
## oben ein Fächer zur gewölbten Mitte. Ecken im Grundriss eckig.
HX = WIDTH / 2.0 - CUSHION_INSET
ZF = DEPTH / 2.0 - CUSHION_INSET
ZB = -DEPTH / 2.0 + LEG + POST_CLEAR
ZM = (ZF + ZB) / 2.0
cushion = Part("cushion", grain_shift=0.5)
profile = [(0.0, 0.0), (0.0, SIDE)]
for k in range(1, ROUND_STEPS + 1):
	a = math.radians(90.0 * k / ROUND_STEPS)
	profile.append((ROUND * (1.0 - math.cos(a)), SIDE + (CROWN - SIDE) * math.sin(a)))
rings = []
for inset, h in profile:
	rings.append([(-HX + inset, FRAME + h, ZF - inset), (HX - inset, FRAME + h, ZF - inset),
		(HX - inset, FRAME + h, ZB + inset), (-HX + inset, FRAME + h, ZB + inset)])
for a, b in zip(rings, rings[1:]):
	for i in range(4):
		j = (i + 1) % 4
		q = [a[i], a[j], b[j], b[i]]
		mid = Vector(sum((Vector(p) for p in q), Vector()) / 4.0)
		out = mid - Vector((0, mid.y, ZM))
		cushion.face(q, tuple(out), ("side", i), "x" if i % 2 == 0 else "z")
dome = (0.0, FRAME + CROWN + DOME, ZM)
for i in range(4):
	j = (i + 1) % 4
	cushion.face([rings[-1][i], rings[-1][j], dome], (0, 1, 0), ("top",), "x")
cushion.face(rings[0], (0, -1, 0), ("bottom",), "x")
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
total = 0
for ob in obs:
	ob.data.materials.clear()   # Holz und Stoff setzt Chair
	if "group" in ob.data.attributes:
		ob.data.attributes.remove(ob.data.attributes["group"])
	tris = sum(len(p.vertices) - 2 for p in ob.data.polygons)
	total += tris
	print("%-8s %5d Dreiecke, UV-Sätze %s" % (ob.name, tris, [l.name for l in ob.data.uv_layers]))
print("zusammen %d Dreiecke" % total)
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
