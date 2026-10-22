# Baut die beiden gemalten Türen als Modelle (Door.Look): die Zimmertür „door_hotel“ (vier Kassetten mit Rundbogen,
# Messingklinke, drei Bänder) und die Kniestocktür zum Dachboden „door_attic“ (vier Bretter mit runden Enden zwischen
# zwei Riegeln, zwei Langbänder, Kastenschloss, Spielkonzept 4.21). Vorlage sind die Pixelbilder in assets/source/
# (door_hotel.png 64 × 112, door_attic.png 80 × 144 mit Zarge – die baut im Spiel OpeningFrame).
#
# Alles entsteht aus Quadern und Prismen im Pixelraster des Bilds; Vorder- und Rückseite tragen das Bild in
# Draufsicht (Pixel = Texel), die Seitenflächen die Farbe des Randpixels. Die Textur ist doppelt so breit wie das Bild:
# links das Bild mit übermalten Beschlägen (die stehen als eigene Teile davor), rechts das Original – darauf zeigen
# die UVs der Beschläge, so tragen sie genau ihre gemalten Pixel.
#
# Lage (Godot-Achsen): Blatt in der XY-Ebene, Scharnierkante bei x = 0, Blatt nach +X, Unterkante y = 0, Mitte der
# Blattdicke bei z = 0; die Tür geht nach +Z auf (dort sitzen Bänder und Kastenschloss, wie gemalt). Objekte:
#   door_hotel.glb  „leaf“ (size, Door streckt es auf die Blattgröße), „handle“ (Klinke beidseits,
#                   Ursprung auf der Drückerachse in Blattmitte, Drücker nach −X zum Scharnier), „hinge“ (ein Band,
#                   Ursprung in seiner Mitte) – Klinke und Bänder setzt Door ungestreckt
#   door_attic.glb  „leaf“ mit Langbändern und Schloss (die Kniestocktür hat immer ungefähr diese Größe)
# Ein Material je Datei mit der Textur, eingebettet und in Godot unkomprimiert (sonst mischen 4×4-Blöcke die Pixel).
#
# Aufruf aus dem Projektordner (Blender 4.3):
#   blender -b --python tools/build_doors.py -- assets/source assets/models [vorschau-ordner]
import bpy, bmesh, sys, os, math
import numpy as np
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import meshy_tex

argv = sys.argv[sys.argv.index("--") + 1:]
SRC_DIR, DST_DIR = argv[0], argv[1]
PREVIEW_DIR = os.path.abspath(argv[2]) if len(argv) > 2 else ""

ARC_SEGMENTS = 6   # je Rundung (Brettenden der Dachbodentür)

DOORS = {
	"door_hotel": {
		"leaf_px": (0, 0, 64, 112),       # Blatt im Bild (x0, y0, x1, y1), y nach unten
		"size": (1.18, 2.08),             # Meter (Tür 1,2 × 2,1 abzüglich Luft) – Door.HOTEL_LEAF
		"thick": 0.06,
		# Beschläge übermalen: Rechteck ← Pixel um (dx, dy) versetzt
		"clean": [((0, 7, 2, 21), (2, 0)), ((0, 36, 2, 50), (2, 0)), ((0, 92, 2, 106), (2, 0)),
			((48, 51, 62, 61), (-14, 0))],
	},
	"door_attic": {
		"leaf_px": (8, 8, 72, 135),
		"size": (0.78, 1.55),             # Door.ATTIC_LEAF
		"thick": 0.06,
		"clean": [((8, 35, 41, 45), (32, 0)), ((8, 99, 41, 109), (32, 0)), ((57, 60, 72, 86), (-16, 0))],
	},
}

bpy.ops.wm.read_factory_settings(use_empty=True)


def load_pixels(path):
	img = bpy.data.images.load(os.path.abspath(path))
	w, h = img.size
	px = np.array(img.pixels[:], dtype=np.float32).reshape(h, w, 4)[::-1].copy()   # Zeile 0 = oben
	bpy.data.images.remove(img)
	return px


def make_texture(name, px, clean):
	h, w = px.shape[:2]
	left = px.copy()
	for (x0, y0, x1, y1), (dx, dy) in clean:
		left[y0:y1, x0:x1] = px[y0 + dy:y1 + dy, x0 + dx:x1 + dx]
	both = np.concatenate([left, px], axis=1)
	img = bpy.data.images.new(name, 2 * w, h, alpha=True)
	img.pixels[:] = both[::-1].reshape(-1)
	img.file_format = 'PNG'
	img.pack()
	return img


class Mesh:
	"""Sammelt Vierecke/Vielecke in Godot-Koordinaten mit UVs in Bildpixeln (y nach unten)."""

	def __init__(self, tex_w, tex_h):
		self.faces = []   # [(Punkte, UVs)]
		self.tw, self.th = tex_w, tex_h

	def face(self, pts, uvs, normal):
		# Umlaufsinn so, dass die Fläche nach normal zeigt
		a, b, c = pts[0], pts[1], pts[2]
		n = np.cross(np.subtract(b, a), np.subtract(c, a))
		if np.dot(n, normal) < 0:
			pts, uvs = pts[::-1], uvs[::-1]
		self.faces.append((pts, uvs))

	def build(self, name, mat):
		me = bpy.data.meshes.new(name)
		bm = bmesh.new()
		uv = bm.loops.layers.uv.new("UVMap")
		for pts, uvs in self.faces:
			verts = [bm.verts.new((x, -z, y)) for x, y, z in pts]   # Godot → Blender
			f = bm.faces.new(verts)
			for loop, (u, v) in zip(f.loops, uvs):
				loop[uv].uv = (u / self.tw, 1.0 - v / self.th)
		bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=1e-5)
		bmesh.ops.triangulate(bm, faces=bm.faces)
		bm.to_mesh(me)
		bm.free()
		for p in me.polygons:
			p.use_smooth = False
		me.materials.append(mat)
		ob = bpy.data.objects.new(name, me)
		bpy.context.scene.collection.objects.link(ob)
		return ob


class Leaf:
	"""Rechnet Bildpixel in Meter um: Blatt leaf_px auf size, Scharnierkante x = 0, Unterkante y = 0."""

	def __init__(self, spec):
		self.x0, self.y0, self.x1, self.y1 = spec["leaf_px"]
		self.w, self.h = spec["size"]

	def x(self, px):
		return (px - self.x0) / (self.x1 - self.x0) * self.w

	def y(self, py):
		return (self.y1 - py) / (self.y1 - self.y0) * self.h


def prism(m, leaf, poly, z0, z1, uv_dx=0.0, sides=True):
	"""Senkrechtes Prisma aus dem Pixel-Vieleck poly (beliebiger Umlauf) zwischen z0 und z1. Vorder- und Rückseite
	in Draufsicht, Seiten in der Farbe des Pixels gleich innerhalb der Kante. uv_dx: Versatz in der Textur (Original)."""
	cx = sum(p[0] for p in poly) / len(poly)
	cy = sum(p[1] for p in poly) / len(poly)
	front = [(leaf.x(px), leaf.y(py), z1) for px, py in poly]
	back = [(leaf.x(px), leaf.y(py), z0) for px, py in poly]
	uvs = [(px + uv_dx, py) for px, py in poly]
	m.face(front, uvs, (0, 0, 1))
	m.face(back, uvs, (0, 0, -1))
	if not sides:
		return
	n = len(poly)
	for i in range(n):
		(ax, ay), (bx, by) = poly[i], poly[(i + 1) % n]
		mx, my = (ax + bx) / 2.0, (ay + by) / 2.0
		# Pixel gleich innerhalb der Kante, zur Mitte hin
		d = math.hypot(cx - mx, cy - my) or 1.0
		u, v = mx + (cx - mx) / d * 0.5 + uv_dx, my + (cy - my) / d * 0.5
		pts = [(leaf.x(ax), leaf.y(ay), z0), (leaf.x(bx), leaf.y(by), z0),
			(leaf.x(bx), leaf.y(by), z1), (leaf.x(ax), leaf.y(ay), z1)]
		out = (leaf.x(mx) - leaf.x(cx), leaf.y(my) - leaf.y(cy), 0.0)
		m.face(pts, [(u, v)] * 4, out)


def rect(x0, y0, x1, y1):
	return [(x0, y0), (x1, y0), (x1, y1), (x0, y1)]


def rounded_board(x0, x1, y0, y1, arc):
	"""Brett mit halbelliptischen Enden (arc Pixel hoch), y nach unten."""
	r = (x1 - x0) / 2.0
	cx = (x0 + x1) / 2.0
	pts = []
	for i in range(ARC_SEGMENTS + 1):   # oben von rechts nach links
		a = math.pi * i / ARC_SEGMENTS
		pts.append((cx + r * math.cos(a), y0 + arc - arc * math.sin(a)))
	for i in range(ARC_SEGMENTS + 1):   # unten von links nach rechts
		a = math.pi + math.pi * i / ARC_SEGMENTS
		pts.append((cx + r * math.cos(a), y1 - arc - arc * math.sin(a)))
	return pts


def box_m(m, x0, y0, z0, x1, y1, z1, uv_rect):
	"""Quader in Metern, alle Seiten auf das Pixel-Rechteck uv_rect (x0, y0, x1, y1) der Textur."""
	ux0, uy0, ux1, uy1 = uv_rect
	quad_uv = [(ux0, uy1), (ux1, uy1), (ux1, uy0), (ux0, uy0)]
	c = ((x0 + x1) / 2, (y0 + y1) / 2, (z0 + z1) / 2)
	corners = {
		(0, 0, 1): [(x0, y0, z1), (x1, y0, z1), (x1, y1, z1), (x0, y1, z1)],
		(0, 0, -1): [(x1, y0, z0), (x0, y0, z0), (x0, y1, z0), (x1, y1, z0)],
		(1, 0, 0): [(x1, y0, z1), (x1, y0, z0), (x1, y1, z0), (x1, y1, z1)],
		(-1, 0, 0): [(x0, y0, z0), (x0, y0, z1), (x0, y1, z1), (x0, y1, z0)],
		(0, 1, 0): [(x0, y1, z1), (x1, y1, z1), (x1, y1, z0), (x0, y1, z0)],
		(0, -1, 0): [(x0, y0, z0), (x1, y0, z0), (x1, y0, z1), (x0, y0, z1)],
	}
	for normal, pts in corners.items():
		m.face(pts, quad_uv, normal)


def cylinder_m(m, axis, center, radius, length, uv_rect, segments=8):
	"""Zylinder entlang axis ('y' oder 'z') in Metern, Mantel und Deckel auf das Pixel-Rechteck uv_rect."""
	ux0, uy0, ux1, uy1 = uv_rect
	ring = []
	for i in range(segments):
		a = 2 * math.pi * i / segments
		ring.append((math.cos(a) * radius, math.sin(a) * radius))

	def p(r, t):
		if axis == 'y':
			return (center[0] + r[0], center[1] + t, center[2] + r[1])
		return (center[0] + r[0], center[1] + r[1], center[2] + t)

	ax = (0, 1, 0) if axis == 'y' else (0, 0, 1)
	for i in range(segments):
		a, b = ring[i], ring[(i + 1) % segments]
		u0 = ux0 + (ux1 - ux0) * i / segments
		u1 = ux0 + (ux1 - ux0) * (i + 1) / segments
		mid = ((a[0] + b[0]) / 2, (a[1] + b[1]) / 2)
		out = (mid[0], 0, mid[1]) if axis == 'y' else (mid[0], mid[1], 0)
		m.face([p(a, -length / 2), p(b, -length / 2), p(b, length / 2), p(a, length / 2)],
			[(u0, uy1), (u1, uy1), (u1, uy0), (u0, uy0)], out)
	cap_uv = [(ux0 + (ux1 - ux0) * (0.5 + 0.5 * r[0] / radius), uy0 + (uy1 - uy0) * (0.5 - 0.5 * r[1] / radius))
		for r in ring]
	m.face([p(r, length / 2) for r in ring], cap_uv, ax)
	m.face([p(r, -length / 2) for r in ring], cap_uv, tuple(-c for c in ax))


def material(name, img):
	mat = bpy.data.materials.new(name)
	mat.use_nodes = True
	nodes = mat.node_tree.nodes
	tex = nodes.new("ShaderNodeTexImage")
	tex.image = img
	tex.interpolation = 'Closest'
	bsdf = nodes["Principled BSDF"]
	bsdf.inputs["Roughness"].default_value = 0.9
	mat.node_tree.links.new(tex.outputs["Color"], bsdf.inputs["Base Color"])
	return mat


# --- Zimmertür --------------------------------------------------------------------------------------
RECESS = 0.012   # Kassetten liegen so tief hinter der Blattfläche (je Seite)


def build_hotel(spec, mat, tw, th):
	leaf = Leaf(spec)
	half = spec["thick"] / 2.0
	m = Mesh(tw, th)
	# Raster: Rahmenhölzer und vier Kassetten (Spalten/Zeilen 1 und 3), Kassetten mit Umriss und Bogen gemalt
	xs, ys = [0, 7, 30, 34, 57, 64], [0, 7, 49, 63, 105, 112]
	panel = lambda i, j: i in (1, 3) and j in (1, 3)
	for side in (1, -1):
		for i in range(5):
			for j in range(5):
				z = side * (half - RECESS if panel(i, j) else half)
				px0, px1, py0, py1 = xs[i], xs[i + 1], ys[j], ys[j + 1]
				m.face([(leaf.x(px0), leaf.y(py0), z), (leaf.x(px1), leaf.y(py0), z),
					(leaf.x(px1), leaf.y(py1), z), (leaf.x(px0), leaf.y(py1), z)],
					[(px0, py0), (px1, py0), (px1, py1), (px0, py1)], (0, 0, side))
				if not panel(i, j):
					continue
				# Laibung der Kassette: vier Wände von der Blattfläche hinunter, Farbe des Umrisspixels
				# (n: zur Kassette hin, in Bildpixeln)
				zf, zp = side * half, z
				for (ax, ay), (bx, by), n in (((px0, py0), (px1, py0), (0, 1)), ((px1, py0), (px1, py1), (-1, 0)),
						((px1, py1), (px0, py1), (0, -1)), ((px0, py1), (px0, py0), (1, 0))):
					u, v = (ax + bx) / 2.0 + n[0] * 0.5, (ay + by) / 2.0 + n[1] * 0.5
					m.face([(leaf.x(ax), leaf.y(ay), zf), (leaf.x(bx), leaf.y(by), zf),
						(leaf.x(bx), leaf.y(by), zp), (leaf.x(ax), leaf.y(ay), zp)],
						[(u, v)] * 4, (n[0], -n[1], 0))
	# Kanten des Blatts
	for (ax, ay), (bx, by), n in (((0, 0), (64, 0), (0, 1)), ((64, 0), (64, 112), (1, 0)),
			((64, 112), (0, 112), (0, -1)), ((0, 112), (0, 0), (-1, 0))):
		u, v = (ax + bx) / 2.0 - n[0] * 2.5, (ay + by) / 2.0 + n[1] * 0.5
		m.face([(leaf.x(ax), leaf.y(ay), -half), (leaf.x(bx), leaf.y(by), -half),
			(leaf.x(bx), leaf.y(by), half), (leaf.x(ax), leaf.y(ay), half)], [(u, v)] * 4, (n[0], n[1], 0))
	objs = [m.build("leaf", mat)]

	# Klinke: Rosette, Hals und Drücker auf beiden Seiten, Drücker zum Scharnier (−X); UVs aufs gemalte Original
	o = 64   # Versatz zum Original in der Textur
	h = Mesh(tw, th)
	for side in (1, -1):
		z = side * half
		box_m(h, -0.035, -0.055, min(z, z + side * 0.012), 0.035, 0.1, max(z, z + side * 0.012), (56 + o, 51, 62 + o, 61))
		zn0, zn1 = z + side * 0.012, z + side * 0.05
		box_m(h, -0.012, -0.012, min(zn0, zn1), 0.012, 0.012, max(zn0, zn1), (59 + o, 54, 61 + o, 57))
		zl0, zl1 = zn1, z + side * 0.072
		box_m(h, -0.14, -0.011, min(zl0, zl1), 0.012, 0.011, max(zl0, zl1), (48 + o, 56, 59 + o, 58))
	objs.append(h.build("handle", mat))

	# Band: Rolle mit Kappen, auf der Aufgehseite an der Scharnierkante
	b = Mesh(tw, th)
	cylinder_m(b, 'y', (0.0, 0.0, half + 0.004), 0.012, 0.14, (0 + o, 7, 2 + o, 21))
	cylinder_m(b, 'y', (0.0, 0.0, half + 0.004), 0.008, 0.16, (0 + o, 19, 2 + o, 21), 6)
	box_m(b, 0.0, -0.06, half - 0.001, 0.03, 0.06, half + 0.003, (0 + o, 7, 2 + o, 21))
	objs.append(b.build("hinge", mat))
	return objs


# --- Dachbodentür -----------------------------------------------------------------------------------
def build_attic(spec, mat, tw, th):
	leaf = Leaf(spec)
	half = spec["thick"] / 2.0
	core, board = 0.012, 0.024   # halbe Dicke: dunkles Feld hinter den Brettern, Bretter
	m = Mesh(tw, th)
	prism(m, leaf, rect(8, 23, 72, 119), -core, core)                  # Feld zwischen den Riegeln
	prism(m, leaf, rect(8, 8, 72, 23), -half, half)                    # oberer Riegel
	prism(m, leaf, rect(8, 119, 72, 135), -half, half)                 # unterer Riegel
	for x0 in (9, 25, 41, 57):
		prism(m, leaf, rounded_board(x0, x0 + 14, 24, 119, 10), -board, board)
	# Langbänder auf der Aufgehseite: Band, Kloben an der Kante, Schelle; UVs aufs gemalte Original
	o = 80
	for top in (35, 99):
		bar = top + 4
		prism(m, leaf, rect(8, bar, 41, bar + 2), board, board + 0.006, o)
		prism(m, leaf, rect(8, top, 10, top + 10), board, board + 0.012, o)
		prism(m, leaf, rect(22, top + 2, 24, top + 8), board, board + 0.01, o)
	# Kastenschloss mit Knauf auf der Aufgehseite, auf der anderen nur der Knauf
	prism(m, leaf, rect(57, 60, 71, 86), board, board + 0.03, o)
	kx, ky = leaf.x(63.5), leaf.y(69.0)
	cylinder_m(m, 'z', (kx, ky, board + 0.03 + 0.015), 0.03, 0.03, (59 + o, 64, 69 + o, 74))
	cylinder_m(m, 'z', (kx, ky, -board - 0.022), 0.03, 0.044, (59 + o, 64, 69 + o, 74))
	return [m.build("leaf", mat)]


for name, spec in DOORS.items():
	for ob in list(bpy.context.scene.objects):
		bpy.data.objects.remove(ob)
	for me in list(bpy.data.meshes):   # sonst hieße das zweite Blatt „leaf.001“
		bpy.data.meshes.remove(me)
	px = load_pixels(os.path.join(SRC_DIR, name + ".png"))
	img = make_texture(name, px, spec["clean"])
	tw, th = img.size
	mat = material(name, img)
	objs = (build_hotel if name == "door_hotel" else build_attic)(spec, mat, tw, th)
	dst = os.path.join(DST_DIR, name + ".glb")
	bpy.ops.object.select_all(action='DESELECT')
	for ob in objs:
		ob.select_set(True)
	bpy.ops.export_scene.gltf(filepath=dst, export_format='GLB', export_yup=True, export_image_format='AUTO',
		export_texcoords=True, export_normals=True, export_materials='EXPORT', export_animations=False,
		use_selection=True)
	meshy_tex.write_import(dst)
	tris = {ob.name: len(ob.data.polygons) for ob in objs}
	print("%s: Textur %d × %d, Dreiecke %s" % (name, tw, th, tris))

	if PREVIEW_DIR:
		# Vorschau: Vorder- und Rückseite nebeneinander, Workbench mit Texturfarben
		back = []
		for ob in objs:
			c = ob.copy()
			bpy.context.scene.collection.objects.link(c)
			c.rotation_euler = (0, 0, math.pi)
			c.location = (spec["size"][0] * 2.3, 0, 0)
			back.append(c)
		w, h = spec["size"]
		cam = bpy.data.objects.new("cam", bpy.data.cameras.new("cam"))
		bpy.context.scene.collection.objects.link(cam)
		cam.data.type = 'ORTHO'
		cam.data.ortho_scale = max(w * 3.6, h * 1.15)
		cam.location = (w * 1.15 + 0.5, -4.0, h / 2.0 + 0.4)
		cam.rotation_euler = (math.radians(84), 0, math.radians(8))
		sc = bpy.context.scene
		sc.camera = cam
		sc.render.engine = 'BLENDER_WORKBENCH'
		sc.display.shading.light = 'STUDIO'
		sc.display.shading.color_type = 'TEXTURE'
		sc.display.shading.show_shadows = False
		sc.render.resolution_x, sc.render.resolution_y = 900, 700
		sc.render.filepath = os.path.join(PREVIEW_DIR, name + "_preview.png")
		bpy.ops.render.render(write_still=True)
		for c in back + [cam]:
			bpy.data.objects.remove(c)
