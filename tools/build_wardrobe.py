# Baut den Kleiderschrank (Versteck, HideSpot, ZIM-130) im Holz der Vertäfelung: Sockel mit Fase und Viertelstab,
# Eckpfosten mit vier Furchen, Rundstab, Fries, Kranz aus Hohlkehle und Deckplatte mit gerundeter Nase – nach den
# Vorlagen des Nutzers (31.10.), Kehlen und Stufen reduziert. Zwei Lamellentüren wie beim weißen Vorbild, je ein
# Messingknopf, je zwei schlichte Messingzylinder als Bänder, innen eine Kleiderstange.
#
# Furchen, Lamellen und die stehenden Mulden im Fries (vorn und an den Seiten, Vorlage des Nutzers 31.10.) sind
# nicht modelliert, sondern in den Atlas gemalt (furniture_kit.paint_details: Normale und
# Verschattung aus einer Formel). Für den Blick aus dem Versteck gibt es die Lamellen zusätzlich als echte Leisten
# („slats_l/r“, dieselben Maße wie das Muster): HideSpot blendet sie ein und die gemalte Füllung aus, solange der
# Spieler drinsteckt – durch die Schlitze sieht man hinaus.
#
# Lage (Godot-Achsen, wie HideSpot): Boden y = 0, Mitte x = 0, Vorderseite nach +Z (Korpus z = ±DEPTH/2).
# Objekte:
#   „carcass“           Korpus außen und innen, Holz (Mat.hotel_wood mit AO und Normale aus dem Atlas)
#   „door_l/r“          Türrahmen, Ursprung auf der Drehachse (Bandseite, Vorderfläche der Tür)
#   „louvre_l/r“        Lamellenfüllung (vorn und hinten je ein Viereck mit gemaltem Muster), Ursprung wie die Tür
#   „slats_l/r“         echte Lamellen für die Innensicht, nur UVMap (Holz ohne Atlas), Ursprung wie die Tür
#   „knob_l/r“          Messingknopf, Ursprung wie die Tür
#   „brass“             Bänder und Kleiderstange, fest am Korpus
#
# Aufruf aus dem Projektordner (Blender 4.3):
#   blender -b --python tools/build_wardrobe.py -- assets/models/wardrobe.glb assets/textures/wardrobe
#   (schreibt wardrobe.glb sowie wardrobe_ao.png und wardrobe_normal.png)
import bpy, bmesh, sys, os, math, random
import numpy as np

sys.path.append(os.path.dirname(os.path.abspath(__file__)))
from furniture_kit import B, G, arc, Part, lathe, finish_plain, atlas_uv, setup_cycles, new_image, bake_material, \
	brass_material, bake, godot_normals, save_image, paint_details, Body, flutes, niches
from furniture_kit import carcass as carcass_of

argv = sys.argv[sys.argv.index("--") + 1:]
DST = os.path.abspath(argv[0])
TEX = os.path.abspath(argv[1])

# --- Maße (Meter) ------------------------------------------------------------------------------------------------
WIDTH = 1.10              # Korpus außen (ohne Sockel und Kranz)
DEPTH = 0.56
HW = WIDTH / 2.0
ZF = DEPTH / 2.0          # Vorderfläche der Pfosten
ZB = -DEPTH / 2.0         # Rückwand
POST = 0.10               # Breite der Eckpfosten vorn
XO = HW - POST            # Öffnung der Türen: x = ±XO
OPEN = (0.10, 1.94)       # Öffnung unten (Oberkante Sockel) und oben (Unterkante Rundstab)
TOP = 2.18                # = HideSpot.WARDROBE_TOP
SIDE_WALL = 0.018
BACK_WALL = 0.012
DOOR_T = 0.022            # Türstärke
DOOR_Z = ZF - 0.008       # Vorderfläche der Türen (hinter den Pfosten)
GAP = 0.0015              # Fuge je Türkante
DOOR_Y = (OPEN[0] + 0.005, OPEN[1] - 0.005)
STILE = 0.06
RAIL = (0.09, 0.07)       # unterer, oberer Riegel
CHAMFER = 0.006           # 45°-Fase des Rahmens zur Füllung
# Lamellen: Abstand, Breite, Stärke, Neigung (vordere Kante unten); dieselben Maße im Muster und in slats_l/r
SLAT_PITCH = 0.026
SLAT_W = 0.02
SLAT_T = 0.004
SLAT_TILT = math.radians(45)
# Furchen: vier je Pfosten, Breite, Abstand, Tiefe, Abstand zu Sockel und Rundstab
FLUTES = 4
FLUTE_W = 0.010
FLUTE_GAP = 0.008
FLUTE_DEPTH = 0.004
FLUTE_END = 0.08
# Mulden im Fries (Wunsch des Nutzers 31.10.): stehende Kapseln, Breite, Höhe, Tiefe; Abstand so, dass eine Lücke
# genau über der Türöffnung (x = ±XO) liegt – dort ist die Vorderseite geteilt
FRIEZE = (OPEN[1] + 0.026, 2.10)
NICHE_W = 0.012
NICHE_H = 0.07
NICHE_DEPTH = 0.004
NICHE_STEPS = 14          # Raster: XO = (NICHE_STEPS + ½) Abstände
NICHE_CORNER = 0.05       # Mitte der äußersten Mulde mindestens so weit von der Ecke
# Messing
HINGE_Y = (0.33, 1.71)
HINGE_R = 0.0065
HINGE_H = 0.07
KNOB_X = 0.035            # von der Mittelkante der Tür
KNOB_Y = 1.02
ROD = (1.80, -0.02, 0.011)   # Kleiderstange: Höhe, z, Radius

ATLAS = 2048
AO_DISTANCE = 0.08
AO_STRENGTH = 0.9
AO_SAMPLES = 128
BRASS_SIZE = 512

bpy.ops.wm.read_factory_settings(use_empty=True)
random.seed(31)

# Profil um den Korpus als (Vorsprung, Höhe) von unten nach oben: Sockelblock mit Fase, Stufe, Viertelstab; Korpus;
# Rundstab; Fries; Hohlkehle, Plättchen, Deckplatte mit gerundeter Nase
PROFILE = [(0.02, 0.0), (0.02, 0.072), (0.017, 0.075), (0.010, 0.075), (0.010, 0.09)] + arc(0.0, 0.09, 0.01, 0, 90, 4) \
	+ [(0.0, OPEN[1])] + arc(0.0, OPEN[1] + 0.013, 0.013, -90, 90, 8) \
	+ [(0.0, 2.10)] + arc(0.04, 2.10, 0.04, 180, 90, 6) + [(0.046, 2.14)] \
	+ arc(0.046, 2.152, 0.012, -90, 0, 3) + [(0.058, 2.168)] + arc(0.046, 2.168, 0.012, 0, 90, 3)
assert abs(PROFILE[-1][1] - TOP) < 1e-6


BODY = Body(WIDTH, DEPTH, POST, OPEN, PROFILE, FRIEZE, SIDE_WALL, BACK_WALL, ZF - DOOR_Z, DOOR_T)


# --- Türen -------------------------------------------------------------------------------------------------------
## Tür auf der Seite side (−1 links, +1 rechts): Ursprung auf der Drehachse an der Außenkante (x = side · XO),
## Vorderfläche z = 0; das Blatt reicht nach −side · x. Gibt Rahmen, Füllung und echte Lamellen zurück.
def build_door(side):
	d = -side   # vom Band zur Mitte
	name = "l" if side < 0 else "r"
	width = XO - 2 * GAP
	X = [d * GAP, d * (GAP + STILE), d * (GAP + width - STILE), d * (GAP + width)]
	Y = [DOOR_Y[0], DOOR_Y[0] + RAIL[0], DOOR_Y[1] - RAIL[1], DOOR_Y[1]]
	T = DOOR_T
	f = Part("door_" + name)
	# Vorder- und Rückseite: Raster ohne das Mittelfeld; Pfosten (Spalten 0 und 2) senkrecht, Riegel waagerecht
	for z, nz in ((0.0, 1), (-T, -1)):
		for i in range(3):
			for j in range(3):
				if (i, j) == (1, 1):
					continue
				stile = i != 1
				f.face([(X[i], Y[j], z), (X[i + 1], Y[j], z), (X[i + 1], Y[j + 1], z), (X[i], Y[j + 1], z)], (0, 0, nz),
					("stile", i, nz) if stile else ("rail", j, nz), "y" if stile else "x")
	# Fase, Laibung, Fase: Ring aus Rechtecken vom Feld vorn bis zum Feld hinten
	c = CHAMFER
	ix = [X[1] + d * c, X[2] - d * c]
	iy = [Y[1] + c, Y[2] - c]
	rings = [(X[1], X[2], Y[1], Y[2], 0.0), (ix[0], ix[1], iy[0], iy[1], -c), (ix[0], ix[1], iy[0], iy[1], -(T - c)),
		(X[1], X[2], Y[1], Y[2], -T)]
	for (ax0, ax1, ay0, ay1, az), (bx0, bx1, by0, by1, bz) in zip(rings, rings[1:]):
		nz = 1 if az == 0.0 else (-1 if bz == -T else 0)
		edges = [  # (Ecken a, Ecken b, Normale in der Ebene, Stück, Faser)
			(((ax0, ay0), (ax1, ay0)), ((bx0, by0), (bx1, by0)), (0, 1), ("rail", 0, "in"), "x"),
			(((ax0, ay1), (ax1, ay1)), ((bx0, by1), (bx1, by1)), (0, -1), ("rail", 2, "in"), "x"),
			(((ax0, ay0), (ax0, ay1)), ((bx0, by0), (bx0, by1)), (d, 0), ("stile", 0, "in"), "y"),
			(((ax1, ay0), (ax1, ay1)), ((bx1, by0), (bx1, by1)), (-d, 0), ("stile", 2, "in"), "y")]
		for (p0, p1), (q0, q1), (nx, ny), piece, axis in edges:
			f.face([(p0[0], p0[1], az), (p1[0], p1[1], az), (q1[0], q1[1], bz), (q0[0], q0[1], bz)], (nx, ny, nz),
				piece, axis)
	# Außenkanten
	f.face([(X[0], Y[0], 0), (X[3], Y[0], 0), (X[3], Y[0], -T), (X[0], Y[0], -T)], (0, -1, 0), ("rail", 0, "e"), "x")
	f.face([(X[0], Y[3], 0), (X[3], Y[3], 0), (X[3], Y[3], -T), (X[0], Y[3], -T)], (0, 1, 0), ("rail", 2, "e"), "x")
	f.face([(X[0], Y[0], 0), (X[0], Y[3], 0), (X[0], Y[3], -T), (X[0], Y[0], -T)], (-d, 0, 0), ("stile", 0, "e"), "y")
	f.face([(X[3], Y[0], 0), (X[3], Y[3], 0), (X[3], Y[3], -T), (X[3], Y[0], -T)], (d, 0, 0), ("stile", 2, "e"), "y")
	pivot = (side * XO, 0.0, DOOR_Z)
	frame = f.finish(pivot)
	# Füllung: vorn und hinten ein Viereck mit gemaltem Muster (Gruppe 2 vorn, 3 hinten)
	l = Part("louvre_" + name)
	l.face([(ix[0], iy[0], -c), (ix[1], iy[0], -c), (ix[1], iy[1], -c), (ix[0], iy[1], -c)], (0, 0, 1), ("louvre", 1),
		"x", 2)
	l.face([(ix[0], iy[0], -(T - c)), (ix[1], iy[0], -(T - c)), (ix[1], iy[1], -(T - c)), (ix[0], iy[1], -(T - c))],
		(0, 0, -1), ("louvre", -1), "x", 3)
	louvre = l.finish(pivot)
	# Echte Lamellen (Innensicht): je Lamelle vier Längsseiten, die Enden stecken in der Laibung
	s = Part("slats_" + name)
	dv = (math.sin(SLAT_TILT), -math.cos(SLAT_TILT))     # (y, z) von der vorderen zur hinteren Kante
	nv = (math.cos(SLAT_TILT), math.sin(SLAT_TILT))      # Oberseite
	for k, yc in enumerate(slat_centers(iy)):
		zc = -T / 2.0
		corner = lambda a, b: (yc + dv[0] * a * SLAT_W / 2 + nv[0] * b * SLAT_T / 2, zc + dv[1] * a * SLAT_W / 2 + nv[1] * b * SLAT_T / 2)
		quads = [((-1, 1), (1, 1), nv), ((1, -1), (-1, -1), (-nv[0], -nv[1])), ((-1, -1), (-1, 1), (-dv[0], -dv[1])),
			((1, 1), (1, -1), dv)]
		for a, b, n in quads:
			pa, pb = corner(*a), corner(*b)
			s.face([(ix[0], pa[0], pa[1]), (ix[1], pa[0], pa[1]), (ix[1], pb[0], pb[1]), (ix[0], pb[0], pb[1])],
				(0, n[0], n[1]), ("slat", k), "x")
	slats = s.finish(pivot)
	return frame, louvre, slats, ix, iy


## Mitten der Lamellen in der Füllung von iy[0] bis iy[1], gleichmäßig verteilt
def slat_centers(iy):
	n = int((iy[1] - iy[0]) / SLAT_PITCH)
	y0 = (iy[0] + iy[1]) / 2.0 - (n - 1) * SLAT_PITCH / 2.0
	return [y0 + k * SLAT_PITCH for k in range(n)]


# --- Messing -----------------------------------------------------------------------------------------------------
def build_brass():
	bm = bmesh.new()
	h = HINGE_H / 2
	r = HINGE_R
	for s in (-1, 1):
		for y in HINGE_Y:
			lathe(bm, (s * XO, y, DOOR_Z + 0.0025), (0, 1, 0),
				[(0, -h), (r * 0.8, -h), (r, -h + 0.0015), (r, h - 0.0015), (r * 0.8, h), (0, h)], segs=12)
	y, z, rr = ROD
	xi = HW - SIDE_WALL
	lathe(bm, (-xi, y, z), (1, 0, 0), [(0, 0), (rr, 0), (rr, 2 * xi), (0, 2 * xi)], segs=12)
	return finish_plain(bm, "brass")


def build_knob(side):
	d = -side
	bm = bmesh.new()
	x = d * (XO - 2 * GAP - KNOB_X + GAP)
	lathe(bm, (x, KNOB_Y, 0.0), (0, 0, 1), [(0.013, 0.0), (0.013, 0.003), (0.009, 0.005), (0.005, 0.008),
		(0.005, 0.016), (0.010, 0.019), (0.014, 0.024), (0.013, 0.029), (0.008, 0.032), (0, 0.033)], segs=16)
	return finish_plain(bm, "knob_" + ("l" if side < 0 else "r"), (side * XO, 0.0, DOOR_Z))


carcass = carcass_of(BODY).finish()
door_l, louvre_l, slats_l, ix, iy = build_door(-1)
door_r, louvre_r, slats_r, _, _ = build_door(1)
brass = build_brass()
knob_l = build_knob(-1)
knob_r = build_knob(1)
wood = [carcass, door_l, door_r, louvre_l, louvre_r]
metal = [brass, knob_l, knob_r]

# Furchen dreifach so dicht, Lamellen 1,5-fach, Rückwand (an der Wand) grob
atlas_uv(wood, 0.003, {1: 3.0, 2: 1.5, 3: 1.5, 4: 2.5, 9: 0.25})
atlas_uv(metal, 0.01)


# --- Muster ------------------------------------------------------------------------------------------------------
## Lamellen in der Füllung, vorn (Gruppe 2): von unten je Lamelle die Vorderkante, die nach hinten steigende
## Oberseite (oben von der nächsten Lamelle verschattet), dann der dunkle Schlitz. Hinten (Gruppe 3): Unterseite,
## Hinterkante, Schlitz.
def louvres(front):
	centers = np.array(slat_centers(iy))
	sa, ca = math.sin(SLAT_TILT), math.cos(SLAT_TILT)
	half_w, half_t = SLAT_W / 2 * sa, SLAT_T / 2 * ca

	def paint(pts, n, px):
		y = pts[:, 1]
		k = np.clip(np.round((y - centers[0]) / SLAT_PITCH), 0, len(centers) - 1)
		t = y - (centers[0] + k * SLAT_PITCH)    # relativ zur nächsten Lamellenmitte
		normals = np.zeros((len(pts), 3))
		shade = np.full(len(pts), 0.1)
		z = 1.0 if front else -1.0
		if front:
			edge = (t >= -half_w - half_t) & (t < -half_w + half_t)
			face = (t >= -half_w + half_t) & (t <= half_w + half_t)
			normals[:] = (0, 0, z)
			normals[edge] = (0, -sa, ca)
			normals[face] = (0, ca, sa)
			shade[edge] = 0.85
			shade[face] = 1.0 - 0.45 * np.clip((t[face] + half_w - half_t) / (2 * half_w), 0, 1) ** 2
		else:
			under = (t >= -half_w - half_t) & (t < half_w - half_t)
			edge = (t >= half_w - half_t) & (t <= half_w + half_t)
			normals[:] = (0, 0, z)
			normals[under] = (0, -ca, -sa)
			normals[edge] = (0, sa, -ca)
			shade[under] = 0.55
			shade[edge] = 0.85
		outside = (y < centers[0] - SLAT_PITCH / 2) | (y > centers[-1] + SLAT_PITCH / 2)
		shade[outside] = 0.1
		return normals, shade, np.ones(len(pts))

	return paint


# --- Backen ------------------------------------------------------------------------------------------------------
sc = setup_cycles()
for ob in wood:
	ob.data.materials.append(bake_material("wood_src"))
for ob in metal:
	ob.data.materials.append(brass_material())
for ob in (slats_l, slats_r):
	ob.hide_render = True

sc.world.light_settings.distance = AO_DISTANCE
ao = bake(wood, 'AO', new_image("wardrobe_ao", ATLAS, False, True), AO_SAMPLES)[..., 0]
print("AO: Mittel %.3f, dunkelster Wert %.3f" % (ao.mean(), ao.min()))
ao = 1.0 - AO_STRENGTH * (1.0 - np.clip(ao, 0, 1))
nrm = godot_normals(bake(wood, 'NORMAL', new_image("wardrobe_nrm", ATLAS, False, True), 1, normal_space='OBJECT'))
paint_details(wood, nrm, ao, {1: flutes(BODY, FLUTES, FLUTE_W, FLUTE_GAP, FLUTE_DEPTH, FLUTE_END),
	2: louvres(True), 3: louvres(False), 4: niches(BODY, NICHE_W, NICHE_H, NICHE_DEPTH, NICHE_STEPS, NICHE_CORNER)})
save_image("wardrobe_ao_out", ao, TEX + "_ao.png")
save_image("wardrobe_normal_out", nrm * 0.5 + 0.5, TEX + "_normal.png")

# Messing: Farbe × AO (AO linear, die Farbe liegt im Bild als sRGB – daher AO^(1/2,2))
bcol = bake(metal, 'DIFFUSE', new_image("brass_color", BRASS_SIZE, True), 1, pass_filter={'COLOR'})
sc.world.light_settings.distance = 0.02
bao = bake(metal, 'AO', new_image("brass_ao", BRASS_SIZE, False), 128)
bcol[..., :3] *= (1.0 - 0.8 * (1.0 - np.clip(bao[..., :1], 0, 1))) ** (1 / 2.2)
brass_img = new_image("wardrobe_brass_albedo", BRASS_SIZE, True)
brass_img.pixels[:] = bcol.ravel()
brass_img.pack()


# --- Export ------------------------------------------------------------------------------------------------------
mat = bpy.data.materials.new("wardrobe_brass")
mat.use_nodes = True
nt = mat.node_tree
bsdf = nt.nodes["Principled BSDF"]
t = nt.nodes.new("ShaderNodeTexImage")
t.image = brass_img
uvn = nt.nodes.new("ShaderNodeUVMap")
uvn.uv_map = "atlas"
nt.links.new(uvn.outputs["UV"], t.inputs["Vector"])
nt.links.new(t.outputs["Color"], bsdf.inputs["Base Color"])
bsdf.inputs["Metallic"].default_value = 1.0
bsdf.inputs["Roughness"].default_value = 0.32
for ob in wood + [slats_l, slats_r]:
	ob.data.materials.clear()   # Holz setzt HideSpot (Mat.hotel_wood mit AO und Normale)
for ob in metal:
	ob.data.materials.clear()
	ob.data.materials.append(mat)
	# Messing hat nur den Atlas: als ersten UV-Satz exportieren
	if "UVMap" in ob.data.uv_layers:
		ob.data.uv_layers.remove(ob.data.uv_layers["UVMap"])
everything = wood + [slats_l, slats_r] + metal
for ob in everything:
	if "group" in ob.data.attributes:
		ob.data.attributes.remove(ob.data.attributes["group"])
	tris = sum(len(p.vertices) - 2 for p in ob.data.polygons)
	print("%-10s %5d Dreiecke, UV-Sätze %s" % (ob.name, tris, [l.name for l in ob.data.uv_layers]))

bpy.ops.object.select_all(action='DESELECT')
for ob in everything:
	ob.hide_render = False
	ob.select_set(True)
bpy.ops.export_scene.gltf(
	filepath=DST, export_format='GLB', export_yup=True, export_apply=False, use_selection=True,
	export_texcoords=True, export_normals=True, export_tangents=False, export_materials='EXPORT',
	export_image_format='JPEG', export_jpeg_quality=92, export_skins=False, export_animations=False,
	export_morph=False, export_cameras=False, export_lights=False)
print("geschrieben:", DST, TEX + "_ao.png", TEX + "_normal.png")
