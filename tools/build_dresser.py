# Baut die Kommode (Dresser, Spielkonzept 3.5) im Look des Kleiderschranks (tools/build_wardrobe.py, ZIM-130):
# Holz der Vertäfelung, Sockel mit Fase und Viertelstab, Eckpfosten mit vier Furchen, Rundstab, Fries mit stehenden
# Mulden, Deckplatte über einer kleinen Hohlkehle mit gerundeter Nase. 1,00 m hoch (Wunsch des Nutzers 31.10.: 15 cm
# höher als bisher). Drei Schubladen zwischen den Pfosten, jede Front mit 45°-Fase hinab zu einer vertieften Füllung,
# je zwei Messingknöpfe wie am Schrank; dahinter der Kasten (Boden, Seiten, Rückwand), in dem Gegenstände liegen.
#
# Furchen und Mulden sind wie beim Schrank in den Atlas gemalt (furniture_kit.paint_details).
#
# Lage (Godot-Achsen, wie Dresser): Boden y = 0, Mitte x = 0, Vorderseite nach +Z (Korpus z = ±DEPTH/2).
# Objekte:
#   „carcass“   Korpus außen und innen, Holz (Mat.hotel_wood mit AO und Normale aus dem Atlas)
#   „drawer“    eine Schublade (Front und Kasten), Ursprung auf Höhe ihres Fachs (Unterkante), Dresser setzt sie dreimal
#   „pulls“     die beiden Knöpfe einer Schublade, Ursprung wie „drawer“
# Gebacken wird mit der Schublade im mittleren Fach, die beiden anderen stehen dabei als Schattenwerfer daneben.
#
# Aufruf aus dem Projektordner (Blender 4.3):
#   blender -b --python tools/build_dresser.py -- assets/models/dresser.glb assets/textures/dresser
#   (schreibt dresser.glb sowie dresser_ao.png und dresser_normal.png)
import bpy, bmesh, sys, os, math, random
import numpy as np

sys.path.append(os.path.dirname(os.path.abspath(__file__)))
from furniture_kit import B, arc, Part, lathe, finish_plain, atlas_uv, setup_cycles, new_image, bake_material, \
	brass_material, bake, godot_normals, save_image, paint_details, Body, flutes, niches, board
from furniture_kit import carcass as carcass_of

argv = sys.argv[sys.argv.index("--") + 1:]
DST = os.path.abspath(argv[0])
TEX = os.path.abspath(argv[1])

# --- Maße (Meter) ------------------------------------------------------------------------------------------------
WIDTH = 0.90              # = Dresser.SIZE (ohne Sockel und Deckplatte)
DEPTH = 0.45
TOP = 1.00
POST = 0.09
OPEN = (0.10, 0.86)       # Fächer zwischen Sockel und Rundstab
FRIEZE = (OPEN[1] + 0.026, 0.935)
DRAWERS = 3               # = Dresser.DRAWERS
PITCH = (OPEN[1] - OPEN[0]) / DRAWERS
FRONT_T = 0.02            # Stärke der Front; sie sitzt FRONT_INSET hinter den Pfosten
FRONT_INSET = 0.008
GAP = 0.0015              # Fuge je Kante
BAND = 0.035              # Rahmen der Front bis zur Fase
CHAMFER = 0.006
TRAY = (0.66, 0.16, 0.38) # Kasten außen: Breite, Höhe, Tiefe (= Dresser.TRAY plus Wände)
TRAY_WALL = 0.012
TRAY_LIFT = 0.012         # Kastenboden über der Unterkante des Fachs
PULL_X = 0.17
FLUTES = 4                # wie am Schrank
FLUTE_W = 0.010
FLUTE_GAP = 0.008
FLUTE_DEPTH = 0.004
FLUTE_END = 0.06
NICHE_W = 0.010
NICHE_H = 0.03
NICHE_DEPTH = 0.003
NICHE_STEPS = 11          # Raster: XO = (NICHE_STEPS + ½) Abstände
NICHE_CORNER = 0.04

ATLAS = 1024
AO_DISTANCE = 0.06
AO_STRENGTH = 0.9
AO_SAMPLES = 128
BRASS_SIZE = 256

bpy.ops.wm.read_factory_settings(use_empty=True)
random.seed(32)

# Profil wie am Schrank, oben flacher: Sockel, Korpus, Rundstab, Fries, kleine Hohlkehle, Plättchen, Deckplatte
PROFILE = [(0.02, 0.0), (0.02, 0.072), (0.017, 0.075), (0.010, 0.075), (0.010, 0.09)] + arc(0.0, 0.09, 0.01, 0, 90, 4) \
	+ [(0.0, OPEN[1])] + arc(0.0, OPEN[1] + 0.013, 0.013, -90, 90, 8) \
	+ [(0.0, FRIEZE[1])] + arc(0.02, FRIEZE[1], 0.02, 180, 90, 4) + [(0.026, 0.955)] \
	+ arc(0.026, 0.967, 0.012, -90, 0, 3) + [(0.038, 0.988)] + arc(0.026, 0.988, 0.012, 0, 90, 3)
assert abs(PROFILE[-1][1] - TOP) < 1e-6
BODY = Body(WIDTH, DEPTH, POST, OPEN, PROFILE, FRIEZE, front_inset=FRONT_INSET, front_t=FRONT_T)


# --- Schublade ---------------------------------------------------------------------------------------------------
## Front (Raster wie die Schranktür: Rahmen, Fase, vertiefte Füllung) und Kasten, y ab Unterkante des Fachs
def build_drawer(name, slot):
	d = Part(name)
	zf = BODY.front_z
	zb = zf - FRONT_T
	X = [-BODY.xo + GAP, -BODY.xo + GAP + BAND, BODY.xo - GAP - BAND, BODY.xo - GAP]
	Y = [GAP, GAP + BAND, PITCH - GAP - BAND, PITCH - GAP]
	for i in range(3):
		for j in range(3):
			if (i, j) == (1, 1):
				continue
			stile = i != 1
			d.face([(X[i], Y[j], zf), (X[i + 1], Y[j], zf), (X[i + 1], Y[j + 1], zf), (X[i], Y[j + 1], zf)], (0, 0, 1),
				("stile", i) if stile else ("rail", j), "y" if stile else "x")
	c = CHAMFER
	ix = [X[1] + c, X[2] - c]
	iy = [Y[1] + c, Y[2] - c]
	zc = zf - c
	for (p0, p1), (q0, q1), n, piece, axis in [
			(((X[1], Y[1]), (X[2], Y[1])), ((ix[0], iy[0]), (ix[1], iy[0])), (0, 1, 1), ("rail", 0), "x"),
			(((X[1], Y[2]), (X[2], Y[2])), ((ix[0], iy[1]), (ix[1], iy[1])), (0, -1, 1), ("rail", 2), "x"),
			(((X[1], Y[1]), (X[1], Y[2])), ((ix[0], iy[0]), (ix[0], iy[1])), (1, 0, 1), ("stile", 0), "y"),
			(((X[2], Y[1]), (X[2], Y[2])), ((ix[1], iy[0]), (ix[1], iy[1])), (-1, 0, 1), ("stile", 2), "y")]:
		d.face([(p0[0], p0[1], zf), (p1[0], p1[1], zf), (q1[0], q1[1], zc), (q0[0], q0[1], zc)], n, piece, axis)
	d.face([(ix[0], iy[0], zc), (ix[1], iy[0], zc), (ix[1], iy[1], zc), (ix[0], iy[1], zc)], (0, 0, 1), ("panel",), "x")
	# Kanten und Rückseite der Front
	d.face([(X[0], Y[0], zf), (X[3], Y[0], zf), (X[3], Y[0], zb), (X[0], Y[0], zb)], (0, -1, 0), ("rail", 0), "x")
	d.face([(X[0], Y[3], zf), (X[3], Y[3], zf), (X[3], Y[3], zb), (X[0], Y[3], zb)], (0, 1, 0), ("rail", 2), "x")
	for x, s in ((X[0], -1), (X[3], 1)):
		d.face([(x, Y[0], zf), (x, Y[3], zf), (x, Y[3], zb), (x, Y[0], zb)], (s, 0, 0), ("stile", s), "y")
	d.face([(X[0], Y[0], zb), (X[3], Y[0], zb), (X[3], Y[3], zb), (X[0], Y[3], zb)], (0, 0, -1), ("front", "back"), "x")
	# Kasten hinter der Front
	tw, th, td = TRAY
	w = TRAY_WALL
	zm = zb - td / 2.0
	board(d, (0, TRAY_LIFT + w / 2.0, zm), (tw, w, td), ("tray", "bottom"), "x")
	board(d, (0, TRAY_LIFT + th / 2.0, zb - td + w / 2.0), (tw - 2 * w, th, w), ("tray", "back"), "x")
	for s in (-1, 1):
		board(d, (s * (tw - w) / 2.0, TRAY_LIFT + th / 2.0, zm), (w, th, td), ("tray", s), "z")
	return d.finish((0, OPEN[0] + PITCH * slot, 0))


def build_pulls(name, slot):
	bm = bmesh.new()
	for x in (-PULL_X, PULL_X):
		lathe(bm, (x, PITCH / 2.0, BODY.front_z), (0, 0, 1), [(0.013, 0.0), (0.013, 0.003), (0.009, 0.005),
			(0.005, 0.008), (0.005, 0.016), (0.010, 0.019), (0.014, 0.024), (0.013, 0.029), (0.008, 0.032), (0, 0.033)],
			segs=12)
	return finish_plain(bm, name, (0, OPEN[0] + PITCH * slot, 0))


carcass = carcass_of(BODY).finish()
drawer = build_drawer("drawer", 1)
pulls = build_pulls("pulls", 1)
wood = [carcass, drawer]
atlas_uv(wood, 0.004, {1: 3.0, 4: 2.5, 9: 0.25})
atlas_uv([pulls], 0.01)
# Schattenwerfer in den beiden anderen Fächern: dasselbe Mesh, nur zum Backen
others = []
for slot in (0, 2):
	for src in (drawer, pulls):
		ob = bpy.data.objects.new(src.name + "_%d" % slot, src.data)
		ob.location = B(0, OPEN[0] + PITCH * slot, 0)
		bpy.context.scene.collection.objects.link(ob)
		others.append(ob)


# --- Backen ------------------------------------------------------------------------------------------------------
sc = setup_cycles()
for ob in wood:
	ob.data.materials.append(bake_material("wood_src"))
pulls.data.materials.append(brass_material())

sc.world.light_settings.distance = AO_DISTANCE
ao = bake(wood, 'AO', new_image("dresser_ao", ATLAS, False, True), AO_SAMPLES)[..., 0]
print("AO: Mittel %.3f, dunkelster Wert %.3f" % (ao.mean(), ao.min()))
ao = 1.0 - AO_STRENGTH * (1.0 - np.clip(ao, 0, 1))
nrm = godot_normals(bake(wood, 'NORMAL', new_image("dresser_nrm", ATLAS, False, True), 1, normal_space='OBJECT'))
paint_details(wood, nrm, ao, {1: flutes(BODY, FLUTES, FLUTE_W, FLUTE_GAP, FLUTE_DEPTH, FLUTE_END),
	4: niches(BODY, NICHE_W, NICHE_H, NICHE_DEPTH, NICHE_STEPS, NICHE_CORNER)})
save_image("dresser_ao_out", ao, TEX + "_ao.png")
save_image("dresser_normal_out", nrm * 0.5 + 0.5, TEX + "_normal.png")

bcol = bake([pulls], 'DIFFUSE', new_image("brass_color", BRASS_SIZE, True), 1, pass_filter={'COLOR'})
sc.world.light_settings.distance = 0.02
bao = bake([pulls], 'AO', new_image("brass_ao", BRASS_SIZE, False), 128)
bcol[..., :3] *= (1.0 - 0.8 * (1.0 - np.clip(bao[..., :1], 0, 1))) ** (1 / 2.2)
brass_img = new_image("dresser_brass_albedo", BRASS_SIZE, True)
brass_img.pixels[:] = bcol.ravel()
brass_img.pack()


# --- Export ------------------------------------------------------------------------------------------------------
for ob in others:
	bpy.data.objects.remove(ob)
mat = bpy.data.materials.new("dresser_brass")
mat.use_nodes = True
nt = mat.node_tree
bsdf = nt.nodes["Principled BSDF"]
t = nt.nodes.new("ShaderNodeTexImage")
t.image = brass_img
nt.links.new(t.outputs["Color"], bsdf.inputs["Base Color"])
bsdf.inputs["Metallic"].default_value = 1.0
bsdf.inputs["Roughness"].default_value = 0.32
for ob in wood:
	ob.data.materials.clear()   # Holz setzt Dresser (Mat.hotel_wood mit AO und Normale)
pulls.data.materials.clear()
pulls.data.materials.append(mat)
everything = wood + [pulls]
for ob in everything:
	if "group" in ob.data.attributes:
		ob.data.attributes.remove(ob.data.attributes["group"])
	tris = sum(len(p.vertices) - 2 for p in ob.data.polygons)
	print("%-8s %5d Dreiecke, UV-Sätze %s" % (ob.name, tris, [l.name for l in ob.data.uv_layers]))

bpy.ops.object.select_all(action='DESELECT')
for ob in everything:
	ob.select_set(True)
bpy.ops.export_scene.gltf(
	filepath=DST, export_format='GLB', export_yup=True, export_apply=False, use_selection=True,
	export_texcoords=True, export_normals=True, export_tangents=False, export_materials='EXPORT',
	export_image_format='JPEG', export_jpeg_quality=92, export_skins=False, export_animations=False,
	export_morph=False, export_cameras=False, export_lights=False)
print("geschrieben:", DST, TEX + "_ao.png", TEX + "_normal.png")
