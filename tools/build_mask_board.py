# Baut das Maskenboard in Zimmer 13 (MaskBoard, ZIM-128, Spielkonzept 5.19, Entscheidung 3.11.): eine Tafel aus dem
# dunklen Holz der Vertäfelung (Mat.hotel_wood) mit umlaufender Rahmenleiste auf Gehrung, darauf 4 × 2 gedrechselte
# Holzstifte, leicht nach oben geneigt (TILT). Keine Namensschilder, keine Messinghaken – welche Maske fehlt, sieht man
# nicht, nur wie viele Stifte leer sind.
#
# Rahmenleiste: Profil ringsum (PROFILE: außen an der Wand hoch, Fase, flache Front, Fase hinab zur Füllung), die vier
# Stücke treffen sich auf 45°. Die Füllung ist eine Fläche mit senkrechter Faser. Stift: Drehprofil (STIFT) mit Teller
# am Board, schlankem Schaft und Knauf, SEGS Seiten, der Teller steckt ein Stück im Board.
#
# Gebacken wird nur die Verschattung (AO) in einen gemeinsamen Atlas für Board und Stift, mit allen acht Stiften als
# Schattenwerfer; die Normale kommt aus dem Mesh (wie beim Stuhl, tools/build_chair.py).
#
# Lage (Godot-Achsen, wie MaskBoard): Wand bei z = 0, Board nach +Z, Mitte x = 0, Unterkante y = 0.
# Objekte:
#   „board“  Füllung und Rahmen, Holz (Mat.hotel_wood mit AO aus dem Atlas)
#   „peg“    ein Stift, Ursprung auf der Füllung (Mitte des Stifts), Achse nach +Z und um TILT nach oben – MaskHook
#            setzt ihn achtmal
# Am Ende stehen die Maße für MaskBoard (SIZE, Plätze der Stifte).
#
# Aufruf aus dem Projektordner (Blender 4.3):
#   blender -b --python tools/build_mask_board.py -- assets/models/mask_board.glb assets/textures/mask_board
#   (schreibt mask_board.glb sowie mask_board_ao.png)
import bpy, sys, os, math, random
import numpy as np
from mathutils import Vector

sys.path.append(os.path.dirname(os.path.abspath(__file__)))
from furniture_kit import G, B, Part, atlas_uv, setup_cycles, new_image, bake_material, bake, save_image

argv = sys.argv[sys.argv.index("--") + 1:]
DST = os.path.abspath(argv[0])
TEX = os.path.abspath(argv[1])

# --- Maße (Meter) ------------------------------------------------------------------------------------------------
WIDTH = 1.32              # = MaskBoard.SIZE.x
HEIGHT = 0.96             # = MaskBoard.SIZE.y
PANEL = 0.018             # Vorderseite der Füllung über der Wand
# Rahmenleiste: (Abstand von der Außenkante nach innen, Höhe über der Wand), von außen an der Wand bis auf die Füllung
PROFILE = [(0.0, 0.0), (0.0, 0.022), (0.007, 0.030), (0.040, 0.030), (0.049, 0.024), (0.055, PANEL)]
FRAME_W = PROFILE[-1][0]
COLUMNS = 4
ROWS = 2
PITCH_X = 0.30            # Abstand der Stifte nebeneinander (= MaskHook.SPACING)
ROW_Y = [0.82, 0.40]      # Höhe der Stifte über der Unterkante, obere Reihe zuerst (Masken bis 0,26 m hoch hängen darunter)
TILT = math.radians(12)   # Stifte so weit nach oben geneigt
# Stift: (Radius, Abstand entlang der Achse von der Füllung) – Teller, Hals, Schaft, Knauf
STIFT = [(0.0165, -0.006), (0.0165, 0.004), (0.0135, 0.008), (0.0090, 0.011), (0.0078, 0.016), (0.0072, 0.040),
	(0.0078, 0.056), (0.0105, 0.063), (0.0122, 0.070), (0.0118, 0.076), (0.0090, 0.081), (0.0045, 0.0845), (0.0, 0.0855)]
SEGS = 12

ATLAS = 1024
ISLAND_MARGIN = 0.012     # 12 px – kleinere Mipmap-Stufen mischen sonst die Nachbarinsel herein
BOARD_AREA = 0.72         # Board unten links im Atlas (Anteil je Achse), darüber der Stift als ein Streifen
PEG_AREA = ((0.02, 0.76), (0.98, 0.98))   # Streifen des Stifts: u entlang des Profils, v einmal herum
BAKE_MARGIN = 16
AO_DISTANCE = 0.08
AO_STRENGTH = 0.85
AO_SAMPLES = 128

bpy.ops.wm.read_factory_settings(use_empty=True)
random.seed(128)

X = Vector((1, 0, 0))
Y = Vector((0, 1, 0))
Z = Vector((0, 0, 1))


# --- Board -------------------------------------------------------------------------------------------------------
board = Part("board")
# Rahmen: je Seite (Außenkante, Richtung nach innen, Richtung entlang, halbe Länge, Mitte der Kante, Faser)
HW = WIDTH / 2.0
sides = [
	("bottom", Vector((0, 0, 0)), Y, X, HW, "x"),
	("top", Vector((0, HEIGHT, 0)), -Y, X, HW, "x"),
	("left", Vector((-HW, HEIGHT / 2.0, 0)), X, Y, HEIGHT / 2.0, "y"),
	("right", Vector((HW, HEIGHT / 2.0, 0)), -X, Y, HEIGHT / 2.0, "y"),
]
for name, edge, inward, along, half, axis in sides:
	for (d0, z0), (d1, z1) in zip(PROFILE, PROFILE[1:]):
		# Gehrung: im Abstand d reicht das Stück bis half − d
		p = lambda d, z, s: edge + inward * d + along * (s * (half - d)) + Z * z
		q = [p(d0, z0, -1), p(d0, z0, 1), p(d1, z1, 1), p(d1, z1, -1)]
		n = inward * (-(z1 - z0)) + Z * (d1 - d0)   # Profilrichtung um 90° gedreht, zeigt aus dem Holz
		board.face([tuple(v) for v in q], tuple(n), ("frame", name), axis)
# Füllung: reicht unter die Fase des Rahmens, senkrechte Faser
inset = PROFILE[-2][0]
board.face([(-HW + inset, inset, PANEL), (HW - inset, inset, PANEL), (HW - inset, HEIGHT - inset, PANEL),
	(-HW + inset, HEIGHT - inset, PANEL)], (0, 0, 1), ("panel",), "y")
board_ob = board.finish()


# --- Stift -------------------------------------------------------------------------------------------------------
AXIS = Vector((0, math.sin(TILT), math.cos(TILT)))
UP = Vector((0, math.cos(TILT), -math.sin(TILT)))   # quer zur Achse, nach oben
peg = Part("peg", grain_shift=0.5)
rings = []
for r, t in STIFT:
	c = AXIS * t
	if r == 0.0:
		rings.append([c])
	else:
		rings.append([c + (X * math.cos(a) + UP * math.sin(a)) * r for a in (2 * math.pi * s / SEGS for s in range(SEGS))])
for (ra, (r0, t0)), (rb, (r1, t1)) in zip(zip(rings, STIFT), zip(rings[1:], STIFT[1:])):
	for s in range(SEGS):
		u = (s + 1) % SEGS
		if len(rb) == 1:
			pts = [ra[s], ra[u], rb[0]]
		else:
			pts = [ra[s], ra[u], rb[u], rb[s]]
		mid = sum(pts, Vector()) / len(pts)
		axial = AXIS * ((t0 + t1) / 2.0)
		out = (mid - axial) + AXIS * (r0 - r1)   # nach außen, an Schrägen zur Seite des kleineren Radius gekippt
		peg.face([tuple(v) for v in pts], tuple(out), ("peg",), "z")
peg_ob = peg.finish()

SLOTS = []
for row, y in enumerate(ROW_Y):
	for col in range(COLUMNS):
		SLOTS.append(((col - (COLUMNS - 1) / 2.0) * PITCH_X, y))


# --- Atlas und Backen --------------------------------------------------------------------------------------------
## Atlas-UV des Stifts von Hand: ein Streifen, u = Weg entlang des Profils, v = Winkel um die Achse. Die automatische
## Abwicklung zerlegte den Drehkörper in viele kleine Inseln mit Nähten in der Verschattung.
def peg_atlas(ob):
	me = ob.data
	layer = me.uv_layers.new(name="atlas")
	arc = [0.0]
	for (r0, t0), (r1, t1) in zip(STIFT, STIFT[1:]):
		arc.append(arc[-1] + math.hypot(r1 - r0, t1 - t0))
	(u0, v0), (u1, v1) = PEG_AREA
	angle = lambda p: math.atan2(p.dot(UP), p.dot(X))
	for poly in me.polygons:
		pts = [G(me.vertices[me.loops[i].vertex_index].co) for i in poly.loop_indices]
		mid = sum(pts, Vector()) / len(pts)
		ref = angle(mid - AXIS * mid.dot(AXIS))
		for i, p in zip(poly.loop_indices, pts):
			t = p.dot(AXIS)
			radial = p - AXIS * t
			k = min(range(len(STIFT)), key=lambda j: (STIFT[j][0] - radial.length) ** 2 + (STIFT[j][1] - t) ** 2)
			a = ref if radial.length < 1e-5 else angle(radial)
			while a < ref - math.pi:
				a += 2.0 * math.pi
			while a > ref + math.pi:
				a -= 2.0 * math.pi
			# Flächen an der Naht (±180°) reichen einen halben Abschnitt darüber hinaus – der Streifen hat dafür Platz
			a = (a + math.pi * (1.0 + 1.0 / SEGS)) / (2.0 * math.pi * (1.0 + 1.0 / SEGS))
			layer.data[i].uv = (u0 + (u1 - u0) * arc[k] / arc[-1], v0 + (v1 - v0) * a)
	layer.active_render = True


obs = [board_ob, peg_ob]
atlas_uv([board_ob], ISLAND_MARGIN)
for d in board_ob.data.uv_layers["atlas"].data:
	d.uv = Vector(d.uv) * BOARD_AREA
peg_atlas(peg_ob)
sc = setup_cycles()
sc.render.bake.margin = BAKE_MARGIN
for ob in obs:
	ob.data.materials.append(bake_material("mask_board_src"))
# Stift zum Backen auf einem Platz der unteren Reihe, die übrigen sieben als Schattenwerfer
peg_ob.location = B(SLOTS[5][0], SLOTS[5][1], PANEL)
others = []
for i, (x, y) in enumerate(SLOTS):
	if i == 5:
		continue
	ob = bpy.data.objects.new("peg_%d" % i, peg_ob.data)
	ob.location = B(x, y, PANEL)
	bpy.context.scene.collection.objects.link(ob)
	others.append(ob)
sc.world.light_settings.distance = AO_DISTANCE
ao = bake(obs, 'AO', new_image("mask_board_ao", ATLAS, False, True), AO_SAMPLES)[..., 0]
print("AO: Mittel %.3f, dunkelster Wert %.3f" % (ao.mean(), ao.min()))
ao = 1.0 - AO_STRENGTH * (1.0 - np.clip(ao, 0, 1))
save_image("mask_board_ao_out", ao, TEX + "_ao.png")


# --- Export ------------------------------------------------------------------------------------------------------
for ob in others:
	bpy.data.objects.remove(ob)
peg_ob.location = (0, 0, 0)
tris = {}
for ob in obs:
	ob.data.materials.clear()   # Holz setzt MaskBoard
	if "group" in ob.data.attributes:
		ob.data.attributes.remove(ob.data.attributes["group"])
	tris[ob.name] = sum(len(p.vertices) - 2 for p in ob.data.polygons)
	print("%-6s %5d Dreiecke, UV-Sätze %s" % (ob.name, tris[ob.name], [l.name for l in ob.data.uv_layers]))
print("Board mit acht Stiften: %d Dreiecke" % (tris["board"] + 8 * tris["peg"]))
bpy.ops.object.select_all(action='DESELECT')
for ob in obs:
	ob.select_set(True)
bpy.ops.export_scene.gltf(
	filepath=DST, export_format='GLB', export_yup=True, export_apply=False, use_selection=True,
	export_texcoords=True, export_normals=True, export_tangents=False, export_materials='NONE',
	export_skins=False, export_animations=False, export_morph=False, export_cameras=False, export_lights=False)
zs = [G(v.co).z for v in board_ob.data.vertices]
pz = [G(v.co) for v in peg_ob.data.vertices]
print("Maße: Breite %.3f, Höhe %.3f, Tiefe %.3f, Füllung %.3f; Stift bis z %.3f, y %.3f; Plätze %s"
	% (WIDTH, HEIGHT, max(zs), PANEL, max(p.z for p in pz), max(p.y for p in pz), SLOTS))
print("geschrieben:", DST, TEX + "_ao.png")
