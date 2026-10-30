# Baut den Bausatz der Wandvertäfelung (Spielkonzept 7.2, Entscheidung 29.10.): Module von MODULE_W Breite (das
# Halbfeld halb so breit), die Wainscot je Wandstück im festen Raster setzt –
#   „panel“  Sockelleiste, Brett, Brüstungsleiste (Oberkante TOP) und ein Rahmenfeld aus Profilleisten
#   „half“   dasselbe halb so breit – Halbfeld, wo ein Wandstück um ein halbes Raster übersteht
#   „plain“  dasselbe ohne Rahmenfeld – Passstück an den Enden eines Wandstücks, wird in der Länge gestreckt
#   „low“    wie „plain“ ohne Brüstungsleiste – unter Fenstern, deren Bank und Schürze an ihrer Stelle sitzen
# Kein Ausgangsmodell: Leisten sind 2D-Profile, entlang X ausgezogen, das Rahmenfeld ein Ring aus Profilschleifen
# (Gehrung von selbst).
#
# Zwei UV-Sätze: UVMap in Metern mit der Faser entlang u (das Foto Wood067 hat die Faser waagerecht; senkrechte
# Rahmenleisten mit senkrechter Faser) für psx_photo mit mesh_uv. Die Füllung im Rahmenfeld ist ein eigenes Brett
# (das Brett ist dafür unter der Profilleiste geschnitten): Faser waagerecht (senkrecht wirkte wie ein Fehler, 30.10.),
# v um FILL_V versetzt – daran erkennt der Shader sie und gibt ihr je Feld einen eigenen Ausschnitt, während Leisten
# und Brett über das ganze Wandstück durchlaufen. „AO“ ein Atlas für die in Cycles gebackene
# Verschattung (Wand dahinter, Boden darunter, Nachbarmodule links und rechts), gespeichert als eigenes Bild – im
# Spiel multipliziert mit der Grundfarbe, damit sie auch im Lampenlicht wirkt (Godots AO wirkt nur aufs
# Umgebungslicht). Stirnseiten (Enden der Leisten) zeigen im Atlas auf eine weiße Ecke: Beim Backen lägen sie
# am Nachbarmodul und würden schwarz.
#
# Lage (Godot-Achsen): Wandfläche bei z = 0, Vertäfelung nach +Z, Boden bei y = 0, Modul von x = 0 bis MODULE_W.
# Alle Teile stecken BACK tief in der Wand (Vertex-Snapping, wie bei build_frames.py).
#
# Aufruf aus dem Projektordner (Blender 4.3):
#   blender -b --python tools/build_wainscot.py -- assets/models/wainscot.glb assets/textures/wainscot_ao.png
import bpy, bmesh, sys, os, math
import numpy as np
from mathutils import Vector

argv = sys.argv[sys.argv.index("--") + 1:]
# Blender löst relative Pfade beim Speichern von Bildern gegen das Laufwerk auf, nicht gegen den Arbeitsordner
DST, AO_DST = os.path.abspath(argv[0]), os.path.abspath(argv[1])

MODULE_W = 0.8    # = LevelBuilder.WAINSCOT_MODULE
TOP = 0.9         # = LevelBuilder.WAINSCOT_H
BACK = 0.015
BOARD_Z = 0.008   # Vorderseite des Bretts

# Profile der Leisten als (y, z) in Metern
SKIRTING = [(0.0, -BACK), (0.0, 0.016), (0.096, 0.016), (0.104, 0.0145), (0.111, 0.011), (0.116, 0.007),
	(0.12, 0.003), (0.12, -BACK)]
BOARD = [(0.11, -BACK), (0.11, BOARD_Z), (0.86, BOARD_Z), (0.86, -BACK)]
RAIL = [(0.845, -BACK), (0.845, 0.010), (0.849, 0.015), (0.856, 0.019), (0.866, 0.021), (0.878, 0.022),
	(0.889, 0.021), (0.896, 0.017), (TOP, 0.011), (TOP, -BACK)]
# Rahmenfeld: Außenkante als Abstand von den Modulrändern (links/rechts) und Höhe (y0, y1), Profil als (Abstand von der Außenkante nach innen, Höhe über dem Brett)
FRAME_SIDE = 0.09
FRAME_Y = (0.195, 0.77)
MOULDING = [(0.0, -0.002), (0.0, 0.004), (0.003, 0.008), (0.008, 0.011), (0.014, 0.012), (0.02, 0.0105),
	(0.025, 0.007), (0.028, 0.003), (0.03, 0.0), (0.03, -0.002)]

# Schnitt der Füllung so weit innerhalb der Außenkante des Rahmenfelds (unter der Profilleiste verborgen); ihr
# v-Versatz in der UVMap (= Wainscot-Shader psx_photo, Füllung ab v > FILL_V / 2)
FILL_INSET = 0.01
FILL_V = 50.0

AO_DISTANCE = 0.08
AO_SIZE = 1024
CAP_CORNER = 0.975   # UV-Bereich ab hier ist weiß (Stirnseiten)
SHARP = math.radians(35)

bpy.ops.wm.read_factory_settings(use_empty=True)


## Godot (x, y, z) → Blender (x, −z, y); der glTF-Export dreht wieder zurück.
def B(x, y, z):
	return Vector((x, -z, y))


def G(v):
	return Vector((v.x, v.z, -v.y))


def extrude(bm, profile, x0, x1, caps):
	area = sum(profile[i][0] * profile[(i + 1) % len(profile)][1] - profile[(i + 1) % len(profile)][0] * profile[i][1]
		for i in range(len(profile)))
	pts = profile if area < 0 else list(reversed(profile))
	a = [bm.verts.new(B(x0, y, z)) for y, z in pts]
	b = [bm.verts.new(B(x1, y, z)) for y, z in pts]
	faces = []
	n = len(pts)
	for i in range(n):
		j = (i + 1) % n
		faces.append(bm.faces.new((a[i], a[j], b[j], b[i])))
	c0 = bm.faces.new(list(reversed(a)))
	c1 = bm.faces.new(b)
	caps.extend([c0, c1])
	faces += [c0, c1]
	bmesh.ops.recalc_face_normals(bm, faces=faces)
	return faces


## Ring aus Profilschleifen um das Rechteck rect; liefert die Flächen mit ihrer Seite (0 unten, 1 rechts, 2 oben, 3 links).
def ring(bm, rect, profile):
	x0, y0, x1, y1 = rect
	loops = []
	for d, h in profile:
		z = BOARD_Z + h
		loops.append([bm.verts.new(B(x0 + d, y0 + d, z)), bm.verts.new(B(x1 - d, y0 + d, z)),
			bm.verts.new(B(x1 - d, y1 - d, z)), bm.verts.new(B(x0 + d, y1 - d, z))])
	outward = [Vector((0, -1, 0)), Vector((1, 0, 0)), Vector((0, 1, 0)), Vector((-1, 0, 0))]   # Godot
	out = []
	for i in range(len(loops) - 1):
		da = profile[i + 1][0] - profile[i][0]
		dh = profile[i + 1][1] - profile[i][1]
		for k in range(4):
			f = bm.faces.new((loops[i][k], loops[i][(k + 1) % 4], loops[i + 1][(k + 1) % 4], loops[i + 1][k]))
			f.normal_update()
			o = outward[(k + 0) % 4]
			# Profil von außen nach innen: Tangente (−da nach außen, dh nach oben) → Normale dh·außen + da·oben
			want = B(*(o * dh + Vector((0, 0, da))))
			if f.normal.dot(want) < 0:
				f.normal_flip()
			out.append((f, k))
	return out


## Schneidet das Brett (Flächen board) an der Füllung rect auf und liefert deren Vorderflächen.
def cut_fill(bm, board, rect):
	x0, y0, x1, y1 = rect
	geom = list(board) + list({e for f in board for e in f.edges}) + list({v for f in board for v in f.verts})
	for co, no in (((x0, 0, 0), (1, 0, 0)), ((x1, 0, 0), (1, 0, 0)), ((0, 0, y0), (0, 0, 1)), ((0, 0, y1), (0, 0, 1))):
		geom = bmesh.ops.bisect_plane(bm, geom=geom, dist=1e-6, plane_co=co, plane_no=no)["geom"]
	fill = set()
	for f in geom:
		if not isinstance(f, bmesh.types.BMFace):
			continue
		f.normal_update()
		c = G(f.calc_center_median())
		if G(f.normal).z > 0.99 and x0 < c.x < x1 and y0 < c.y < y1:
			fill.add(f)
	return fill


def build(name, with_frame, with_rail=True, width=MODULE_W):
	me = bpy.data.meshes.new(name)
	bm = bmesh.new()
	caps = []
	board = []
	for prof in (SKIRTING, BOARD, RAIL) if with_rail else (SKIRTING, BOARD):
		faces = extrude(bm, prof, 0.0, width, caps)
		if prof is BOARD:
			board = faces
	frame = []
	fill = set()
	if with_frame:
		rect = (FRAME_SIDE, FRAME_Y[0], width - FRAME_SIDE, FRAME_Y[1])
		frame = ring(bm, rect, MOULDING)
		fill = cut_fill(bm, board, (rect[0] + FILL_INSET, rect[1] + FILL_INSET, rect[2] - FILL_INSET, rect[3] - FILL_INSET))
	bm.normal_update()
	# Kanten über SHARP scharf, sonst glatt (runde Profile)
	for f in bm.faces:
		f.smooth = True
	for e in bm.edges:
		if len(e.link_faces) == 2 and e.link_faces[0].normal.angle(e.link_faces[1].normal) > SHARP:
			e.smooth = False
	uv = bm.loops.layers.uv.new("UVMap")
	bm.loops.layers.uv.new("AO")
	vertical = {f for f, k in frame if k in (1, 3)}
	cap_set = set(caps)
	for f in bm.faces:
		n = G(f.normal)
		for loop in f.loops:
			p = G(loop.vert.co)
			if f in cap_set:
				loop[uv].uv = (p.z, p.y)
			elif f in fill:
				loop[uv].uv = (p.x, p.y + FILL_V)   # Füllung: Faser waagerecht wie die Leisten, eigener Ausschnitt
			elif f in vertical:
				loop[uv].uv = (p.y, p.x + p.z)   # Faser senkrecht
			elif abs(n.y) > max(abs(n.z), abs(n.x)):
				loop[uv].uv = (p.x, p.z)
			else:
				loop[uv].uv = (p.x, p.y + p.z)
	bm.to_mesh(me)
	bm.free()
	ob = bpy.data.objects.new(name, me)
	bpy.context.scene.collection.objects.link(ob)
	return ob


panel = build("panel", True)
half = build("half", True, width=MODULE_W / 2)
plain = build("plain", False)
low = build("low", False, False)
PARTS = ((panel, MODULE_W), (half, MODULE_W / 2), (plain, MODULE_W), (low, MODULE_W))


## Stirnseiten erkennen: Normale entlang ±X
def cap_polys(ob):
	return [p.index for p in ob.data.polygons if abs(p.normal.x) > 0.99]


## AO-Atlas: Smart UV Project je Teil in seine Hälfte, Stirnseiten in die weiße Ecke.
def layout_ao(ob, v0, v1):
	bpy.ops.object.select_all(action='DESELECT')
	ob.select_set(True)
	bpy.context.view_layer.objects.active = ob
	ob.data.uv_layers.active = ob.data.uv_layers["AO"]
	bpy.ops.object.mode_set(mode='EDIT')
	bpy.ops.mesh.select_all(action='SELECT')
	bpy.ops.uv.smart_project(angle_limit=math.radians(40), island_margin=0.004, area_weight=0.0)
	bpy.ops.object.mode_set(mode='OBJECT')
	layer = ob.data.uv_layers["AO"].data
	caps = set(cap_polys(ob))
	for p in ob.data.polygons:
		for li in p.loop_indices:
			u, v = layer[li].uv
			if p.index in caps:
				layer[li].uv = (0.99, 0.99)
			else:
				layer[li].uv = (u * (CAP_CORNER - 0.01), v0 + v * (v1 - v0))
	ob.data.uv_layers.active = ob.data.uv_layers["UVMap"]


layout_ao(panel, 0.0, 0.40)
layout_ao(half, 0.42, 0.60)
layout_ao(plain, 0.62, 0.79)
layout_ao(low, 0.81, CAP_CORNER - 0.01)

# --- Backen: jedes Teil vor eigener Wand und eigenem Boden, mit Nachbarn links und rechts ---------------
img = bpy.data.images.new("wainscot_ao", AO_SIZE, AO_SIZE, alpha=False, float_buffer=False)
img.colorspace_settings.name = 'Non-Color'
mat = bpy.data.materials.new("bake")
mat.use_nodes = True
node = mat.node_tree.nodes.new("ShaderNodeTexImage")
node.image = img
mat.node_tree.nodes.active = node
for ob, _w in PARTS:
	ob.data.materials.append(mat)


def plane(name, center, size, rot):
	ob = bpy.data.objects.new(name, bpy.data.meshes.new(name))
	bm = bmesh.new()
	bmesh.ops.create_grid(bm, x_segments=1, y_segments=1, size=size)
	bm.to_mesh(ob.data)
	bm.free()
	ob.rotation_euler = rot
	ob.location = center
	bpy.context.scene.collection.objects.link(ob)
	return ob


helpers = []
for i, (ob, w) in enumerate(PARTS):
	ox = i * 20.0
	ob.location = (ox, 0, 0)
	for dx in (-w, w):
		c = ob.copy()
		c.location = (ox + dx, 0, 0)
		bpy.context.scene.collection.objects.link(c)
		helpers.append(c)
	helpers.append(plane("wall", B(ox + w / 2, 1.0, 0.0), 3.0, (math.pi / 2, 0, 0)))   # Wand bei Godot z = 0
	helpers.append(plane("floor", B(ox + w / 2, 0.0, 1.0), 3.0, (0, 0, 0)))            # Boden bei y = 0

sc = bpy.context.scene
sc.render.engine = 'CYCLES'
sc.cycles.device = 'CPU'
sc.cycles.samples = 512
sc.world = bpy.data.worlds.new("bake")
sc.world.light_settings.distance = AO_DISTANCE
sc.render.bake.margin = 6
sc.render.bake.use_clear = True
bpy.ops.object.select_all(action='DESELECT')
for ob, _w in PARTS:
	ob.select_set(True)
	ob.data.uv_layers.active = ob.data.uv_layers["AO"]   # gebacken wird in den aktiven UV-Satz
bpy.context.view_layer.objects.active = panel
bpy.ops.object.bake(type='AO')
for ob, _w in PARTS:
	ob.data.uv_layers.active = ob.data.uv_layers["UVMap"]

px = np.array(img.pixels[:]).reshape(AO_SIZE, AO_SIZE, 4)
c = int(CAP_CORNER * AO_SIZE)
px[c:, c:, 0:3] = 1.0
img.pixels[:] = px.ravel()
img.filepath_raw = AO_DST
img.file_format = 'PNG'
img.save()
print("AO: Mittel %.3f, dunkelster Wert %.3f" % (px[:c, :c, 0].mean(), px[:c, :c, 0].min()))

for h in helpers:
	bpy.data.objects.remove(h, do_unlink=True)
for ob, _w in PARTS:
	ob.location = (0, 0, 0)
	ob.data.materials.clear()
	print("%-6s %4d Flächen, %4d Ecken" % (ob.name, len(ob.data.polygons), len(ob.data.vertices)))

bpy.ops.object.select_all(action='DESELECT')
for ob, _w in PARTS:
	ob.select_set(True)
bpy.ops.export_scene.gltf(
	filepath=DST, export_format='GLB', export_yup=True, export_apply=False, export_materials='NONE', use_selection=True,
	export_texcoords=True, export_normals=True, export_skins=False, export_animations=False, export_morph=False,
	export_cameras=False, export_lights=False)
