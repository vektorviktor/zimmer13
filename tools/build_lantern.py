# Baut die Gartenlaterne (LevelBuilder._lantern) nach der Bleistiftskizze des Nutzers: oben ein eckiger Lampenkopf
# (Glaskasten nach oben weiter, Rahmen mit Eckstreben, ausladendes Gesims, Walmdach, Deckplatte, Spitze), darunter
# alles achteckig – Kragen, langer Mast, Wulst und ein Fuß, der sich in sanfter Kehle zur flachen Bodenplatte
# weitet. Kein Ausgangsmodell: der achteckige Teil ist ein gedrehtes Profil, der Kopf aus Pyramidenstümpfen.
#
# Lage (Godot-Achsen): Ursprung mittig unter der Bodenplatte, HEIGHT hoch, Kopf achsparallel. Drei Objekte ohne
# Material – das Spiel setzt sie: „post“ (Fuß und Mast), „head“ (Rahmen, Gesims, Dach) und „glass“ (die Scheiben,
# bekommt das leuchtende Material der Lampe). Am Ende stehen Glasmitte und Plattenmaß – für LANTERN_LIGHT_Y bzw.
# die Kollision in LevelBuilder._lantern.
#
# Aufruf (Blender 4.3):
#   blender -b --python tools/build_lantern.py -- assets/models/lantern.glb [vorschau.png]
import bpy, bmesh, sys, math
from mathutils import Vector

argv = sys.argv[sys.argv.index("--") + 1:]
DST = argv[0]
PREVIEW = argv[1] if len(argv) > 1 else ""

HEIGHT = 3.0        # bis zur Spitze
SMOOTH = 30.0       # Grad: flachere Knicke werden glatt schattiert (Kehle des Fußes), steilere bleiben Kanten

# Achteckiger Teil: (Höhe, Abstand der Seitenflächen zur Achse), von unten nach oben
PLATE_R, PLATE_H = 0.28, 0.045
FOOT_TOP, NECK_R = 0.30, 0.06
FOOT_STEPS = 10
POLE_R = 0.04
COLLAR = (2.32, 2.37, 0.055)       # unten, oben, Abstand
HEAD_Y = 2.40                       # Unterkante des Kopfs

# Eckiger Kopf: halbe Breiten
BOTTOM_PLATE = (0.08, 0.025)        # halbe Breite, Dicke
GLASS = (0.075, 0.105, 0.31)        # unten, oben, Höhe
BAR = 0.0055                        # halbe Stärke der Eckstreben und Rahmenleisten
RAIL_H = 0.02
CORNICE = (0.1175, 0.025, 0.0175)   # Ausladung, Höhe der Schräge, Höhe der senkrechten Kante
ROOF = (0.11, 0.05, 0.13)           # unten, oben, Höhe
CAP = (0.0575, 0.0175, 0.0225, 0.015) # Deckplatte: halbe Breite, Dicke; Haube: halbe Breite oben, Höhe
TIP = 0.009                         # halbe Breite der Spitze


def lathe(bm, profile, sides):
	"""Gedrehtes Profil [(z, Abstand)] mit sides Ecken, Flächen (nicht Ecken) im Abstand; offen an den Enden,
	Endpunkte mit Abstand 0 werden zur Spitze."""
	k = 1.0 / math.cos(math.pi / sides)
	rings = []
	for z, r in profile:
		ring = []
		for i in range(sides):
			a = 2.0 * math.pi * (i + 0.5) / sides
			ring.append(bm.verts.new((math.cos(a) * r * k, math.sin(a) * r * k, z)))
		rings.append(ring)
	for r0, r1 in zip(rings, rings[1:]):
		for i in range(sides):
			j = (i + 1) % sides
			bm.faces.new((r0[i], r0[j], r1[j], r1[i]))
	return rings


def cap(bm, ring, up):
	bm.faces.new(ring if up else list(reversed(ring)))


def frustum(bm, z0, z1, h0, h1, top=True, bottom=True):
	"""Quadratischer Pyramidenstumpf (halbe Breiten h0 unten, h1 oben), Seiten achsparallel."""
	rings = lathe(bm, [(z0, h0), (z1, h1)], 4)
	if bottom:
		cap(bm, rings[0], False)
	if top:
		cap(bm, rings[-1], True)


def bar(bm, a, b, half):
	"""Vierkantstab von a nach b (Mittellinie), Querschnitt 2·half, eine Seite waagerecht."""
	d = (b - a).normalized()
	side = d.cross(Vector((0, 0, 1)))
	if side.length < 1e-4:
		side = Vector((1, 0, 0))
	side.normalize()
	up = side.cross(d).normalized()
	quads = []
	for p in (a, b):
		quads.append([bm.verts.new(p + (side * sx + up * sy) * half) for sx, sy in ((-1, -1), (1, -1), (1, 1), (-1, 1))])
	for i in range(4):
		j = (i + 1) % 4
		bm.faces.new((quads[0][i], quads[0][j], quads[1][j], quads[1][i]))
	bm.faces.new(list(reversed(quads[0])))
	bm.faces.new(quads[1])


def finish(name, bm):
	bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
	sharp = [e for e in bm.edges if e.calc_face_angle(0.0) > math.radians(SMOOTH)]
	bmesh.ops.split_edges(bm, edges=sharp)
	me = bpy.data.meshes.new(name)
	bm.to_mesh(me)
	bm.free()
	for poly in me.polygons:
		poly.use_smooth = True
	ob = bpy.data.objects.new(name, me)
	bpy.context.scene.collection.objects.link(ob)
	return ob


bpy.ops.wm.read_factory_settings(use_empty=True)

# --- Fuß und Mast (achteckig) ---
bm = bmesh.new()
prof = [(0.0, PLATE_R), (PLATE_H, PLATE_R)]
# Kehle: unten fast waagerecht aus der Platte, oben steil in den Hals
top_r = PLATE_R - 0.045
for s in range(FOOT_STEPS + 1):
	t = s / FOOT_STEPS
	prof.append((PLATE_H + (FOOT_TOP - PLATE_H) * t, NECK_R + (top_r - NECK_R) * (1.0 - t) ** 2.2))
# Wulst, Mast, Kragen, Hals
prof += [(FOOT_TOP + 0.005, 0.072), (FOOT_TOP + 0.03, 0.078), (FOOT_TOP + 0.055, 0.072), (FOOT_TOP + 0.06, POLE_R)]
prof += [(COLLAR[0], POLE_R), (COLLAR[0], COLLAR[2]), (COLLAR[1], COLLAR[2]), (COLLAR[1], 0.035), (HEAD_Y, 0.035)]
rings = lathe(bm, prof, 8)
cap(bm, rings[0], False)
cap(bm, rings[-1], True)
post = finish("post", bm)

# --- Kopf (eckig) ---
bm = bmesh.new()
z = HEAD_Y
frustum(bm, z, z + BOTTOM_PLATE[1], BOTTOM_PLATE[0], BOTTOM_PLATE[0])
z += BOTTOM_PLATE[1]
g0, g1, gh = GLASS
gz0, gz1 = z, z + gh
# Rahmenleisten unten und oben, Eckstreben auf den Kanten des Glaskastens
for zz, hh in ((gz0, g0), (gz1 - RAIL_H, g1 - (g1 - g0) * RAIL_H / gh)):
	frustum(bm, zz, zz + RAIL_H, hh + BAR, hh + BAR + (g1 - g0) * RAIL_H / gh)
for sx, sy in ((1, 1), (-1, 1), (-1, -1), (1, -1)):
	bar(bm, Vector((sx * g0, sy * g0, gz0)), Vector((sx * g1, sy * g1, gz1)), BAR)
# Gesims: Schräge nach außen, dann senkrechte Kante
z = gz1
frustum(bm, z, z + CORNICE[1], g1 + BAR, CORNICE[0], top=False)
frustum(bm, z + CORNICE[1], z + CORNICE[1] + CORNICE[2], CORNICE[0], CORNICE[0], bottom=False)
z += CORNICE[1] + CORNICE[2]
frustum(bm, z, z + ROOF[2], ROOF[0], ROOF[1])
z += ROOF[2]
frustum(bm, z, z + CAP[1], CAP[0], CAP[0])
z += CAP[1]
frustum(bm, z, z + CAP[3], CAP[0] - 0.005, CAP[2])
z += CAP[3]
tip_h = HEIGHT - z
frustum(bm, z, z + tip_h * 0.35, TIP, TIP)
frustum(bm, z + tip_h * 0.35, HEIGHT, TIP, 0.0005, top=False)
head = finish("head", bm)

# --- Glas: Kasten knapp innerhalb der Streben ---
bm = bmesh.new()
inset = BAR * 0.4
frustum(bm, gz0, gz1, g0 - inset, g1 - inset)
glass = finish("glass", bm)

bpy.ops.export_scene.gltf(
	filepath=DST, export_format='GLB', export_yup=True, export_apply=False, export_materials='NONE',
	export_skins=False, export_animations=False, export_morph=False, export_cameras=False, export_lights=False)

tris = sum(len(p.vertices) - 2 for o in (post, head, glass) for p in o.data.polygons)
top = max(v.co.z for o in (post, head, glass) for v in o.data.vertices)
print("Laterne: %d Dreiecke, %.3f m hoch, Glasmitte %.3f m (Glas %.3f..%.3f), Platte %.2f m breit, Mast %.2f m"
	% (tris, top, (gz0 + gz1) / 2.0, gz0, gz1, 2 * PLATE_R, 2 * POLE_R))

if PREVIEW:
	cam = bpy.data.objects.new("cam", bpy.data.cameras.new("cam"))
	bpy.context.scene.collection.objects.link(cam)
	cam.rotation_euler = (math.radians(86), 0, math.radians(38.66))
	cam.data.type = 'ORTHO'
	cam.data.ortho_scale = 3.3
	bpy.context.scene.camera = cam
	cam.location = Vector((0, 0, 1.5)) + Vector((math.sin(math.radians(38.66)), -math.cos(math.radians(38.66)), 0.07)) * 8
	sc = bpy.context.scene
	sc.render.engine = 'BLENDER_WORKBENCH'
	sc.display.shading.light = 'STUDIO'
	sc.display.shading.show_cavity = False
	sc.render.resolution_x, sc.render.resolution_y = 500, 900
	sc.render.filepath = PREVIEW
	bpy.ops.render.render(write_still=True)
