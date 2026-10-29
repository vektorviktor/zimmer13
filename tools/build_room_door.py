# Baut die realistische Zimmertür (Ersatz für die gemalte „door_hotel“ aus build_doors.py, Spielkonzept 9.2): ein
# Blatt mit vier erhabenen Kassetten in dunklem Nussbaum und die Beschläge aus Messing – Türspion, leere Plakette
# für die Zimmernummer, zwei Bänder, Drücker auf Langschild (beidseits, mit Schlüsselloch).
#
# Kein Ausgangsmodell: Das Blatt ist ein Raster aus Friesen (Rahmen, Mittelfries, Riegel), in jedem Feld ein Ring aus
# Profilschleifen wie das Rahmenfeld in build_wainscot.py. Low Poly (Blatt ≈ 600 Dreiecke, Beschläge je < 300).
#
# Texturen gebacken (Cycles): Für das Blatt liegt das Foto Wood067 auf einem UV-Satz in Metern – Faser je Friesstück
# wie beim Schreiner (Rahmen und Mittelfries senkrecht, Riegel waagerecht, Füllungen senkrecht), jedes Stück mit
# eigenem Versatz. Gebacken in einen Atlas: Farbe × Verschattung (AO, in die Farbe multipliziert, damit sie auch im
# Lampenlicht wirkt – Godots AO wirkt nur aufs Umgebungslicht), Normalen (Holzporen) und Rauheit. Die Beschläge
# teilen sich einen zweiten Atlas: Messing mit leichtem Anlauf, in Ritzen dunkler, Linse und Schlüsselloch schwarz.
# Im GLB steckt danach nur der Atlas-UV-Satz; Materialien „door_wood“ und „door_brass“ mit eingebetteten Bildern.
#
# Lage (Godot-Achsen, wie Door): Blatt in der XY-Ebene, Scharnierkante bei x = 0, Blatt nach +X, Unterkante y = 0,
# Mitte der Blattdicke bei z = 0. Die Tür geht nach +Z auf (Zimmerseite, dort die Bänder), der Flur liegt bei −Z
# (Plakette, Linse des Spions). Objekte:
#   „leaf“     LEAF groß, Door streckt es auf die Blattgröße
#   „hinge“    ein Band, Ursprung auf Scharnierkante und Mittelebene in Bandmitte, Rolle auf der Zimmerseite
#   „handle“   Drücker beidseits, Ursprung auf der Drückerachse in der Mittelebene, Drücker nach −X zum Scharnier
#   „peephole“ Spion, Ursprung auf seiner Achse in der Mittelebene
#   „plaque“   leere Plakette auf der Flurseite, Ursprung in ihrer Mitte auf der Mittelebene
# Beschläge werden ungestreckt gesetzt (wie bisher Klinke und Bänder).
#
# Aufruf aus dem Projektordner (Blender 4.3):
#   blender -b --python tools/build_room_door.py -- assets/models/door_room.glb [vorschau-ordner]
import bpy, bmesh, sys, os, math, random
import numpy as np
from mathutils import Vector, Matrix

argv = sys.argv[sys.argv.index("--") + 1:]
DST = os.path.abspath(argv[0])
PREVIEW_DIR = os.path.abspath(argv[1]) if len(argv) > 1 else ""
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
WOOD = os.path.join(ROOT, "assets", "textures", "Wood067", "Wood067_2K-JPG_%s.jpg")

LEAF = (1.18, 2.08)       # = Door.HOTEL_LEAF
THICK = 0.06
# Raster der Friese (Meter): Rahmen 15 cm, Mittelfries 16 cm, Sockel 24 cm, Schlossriegel 22 cm, Kopf 15 cm
XS = [0.0, 0.15, 0.51, 0.67, 1.03, LEAF[0]]
YS = [0.0, 0.24, 0.86, 1.08, 1.93, LEAF[1]]
PANELS = [(1, 1), (3, 1), (1, 3), (3, 3)]
# Füllung: Profil als (Abstand von der Feldkante nach innen, Höhe gegenüber der Blattfläche) – Fase am Fries, Kehle,
# Abplattung hinauf zum erhabenen Spiegel
PANEL = [(0.0, 0.0), (0.003, -0.003), (0.006, -0.012), (0.010, -0.019), (0.016, -0.021), (0.055, -0.009),
	(0.061, -0.007)]
WOOD_METERS = 0.9         # so viele Meter deckt das Foto
WOOD_TINT = (0.52, 0.48, 0.47)   # dunkler und weniger rot als das Foto (gealterter Lack)

HINGE_H = 0.10
HINGE_R = 0.0085
PEEP_Y = 1.50             # Vorschläge für Door (Höhe über dem Boden, Mitte des Mittelfrieses)
PLAQUE_Y = 1.66
PLAQUE = (0.15, 0.065, 0.005)

AO_DISTANCE = 0.06
WOOD_SIZE = 2048
DETAIL_SIZE = 1024        # Normalen und Rauheit (Poren und Lack brauchen weniger als die Farbe)
BRASS_SIZE = 512
SHARP = math.radians(35)
SEGMENTS = 10             # Rundteile der Beschläge

bpy.ops.wm.read_factory_settings(use_empty=True)
random.seed(13)


## Godot (x, y, z) → Blender (x, −z, y); der glTF-Export dreht wieder zurück.
def B(x, y, z):
	return Vector((x, -z, y))


def G(v):
	return Vector((v.x, v.z, -v.y))


def finish(bm, name):
	# N-Ecke (Deckel der Rundteile, Schlüsselloch) in Dreiecke – sonst rechnet der Export keine Tangenten
	bmesh.ops.triangulate(bm, faces=[f for f in bm.faces if len(f.verts) > 4])
	bm.normal_update()
	for f in bm.faces:
		f.smooth = True
	for e in bm.edges:
		if len(e.link_faces) == 2 and e.link_faces[0].normal.angle(e.link_faces[1].normal) > SHARP:
			e.smooth = False
	me = bpy.data.meshes.new(name)
	bm.to_mesh(me)
	bm.free()
	ob = bpy.data.objects.new(name, me)
	bpy.context.scene.collection.objects.link(ob)
	return ob


# --- Blatt -------------------------------------------------------------------------------------------------------
## Faser je Fläche: Stück (für den Versatz) und Richtung (True = senkrecht)
def build_leaf():
	bm = bmesh.new()
	grain = bm.loops.layers.uv.new("grain")
	offsets = {}

	def piece_uv(f, piece, vertical):
		if piece not in offsets:
			offsets[piece] = (random.random(), random.random())
		ou, ov = offsets[piece]
		for loop in f.loops:
			p = G(loop.vert.co)
			u, v = (p.y, p.x + p.z) if vertical else (p.x, p.y + p.z)
			loop[grain].uv = (u / WOOD_METERS + ou, v / WOOD_METERS + ov)

	## Welches Fries trägt die Rasterzelle (i, j)? Rahmen und Mittelfries laufen durch, Riegel liegen dazwischen
	def cell_piece(i, j):
		if i in (0, 4):
			return ("stile", i), True
		if i == 2 and j in (1, 3):
			return ("muntin", j), True
		return ("rail", j), False

	for side in (1, -1):
		zf = side * THICK / 2.0
		grid = [[bm.verts.new(B(x, y, zf)) for y in YS] for x in XS]
		for i in range(len(XS) - 1):
			for j in range(len(YS) - 1):
				if (i, j) in PANELS:
					continue
				vs = [grid[i][j], grid[i + 1][j], grid[i + 1][j + 1], grid[i][j + 1]]
				f = bm.faces.new(vs if side > 0 else list(reversed(vs)))
				piece_uv(f, (side,) + cell_piece(i, j)[0], cell_piece(i, j)[1])
		for i, j in PANELS:
			x0, x1, y0, y1 = XS[i], XS[i + 1], YS[j], YS[j + 1]
			loops = [[grid[i][j], grid[i + 1][j], grid[i + 1][j + 1], grid[i][j + 1]]]
			for d, h in PANEL[1:]:
				z = zf + side * h
				loops.append([bm.verts.new(B(x0 + d, y0 + d, z)), bm.verts.new(B(x1 - d, y0 + d, z)),
					bm.verts.new(B(x1 - d, y1 - d, z)), bm.verts.new(B(x0 + d, y1 - d, z))])
			piece = (side, "panel", i, j)
			for a, b in zip(loops, loops[1:]):
				for k in range(4):
					vs = [a[k], a[(k + 1) % 4], b[(k + 1) % 4], b[k]]
					f = bm.faces.new(vs if side > 0 else list(reversed(vs)))
					piece_uv(f, piece, True)
			f = bm.faces.new(loops[-1] if side > 0 else list(reversed(loops[-1])))
			piece_uv(f, piece, True)
		if side > 0:
			front = grid
		else:
			back = grid
	# Kanten: Umriss vorn und hinten verbinden
	n, m = len(XS) - 1, len(YS) - 1
	ring = [(i, 0) for i in range(n)] + [(n, j) for j in range(m)] + [(i, m) for i in range(n, 0, -1)] \
		+ [(0, j) for j in range(m, 0, -1)]
	for k, (i, j) in enumerate(ring):
		i2, j2 = ring[(k + 1) % len(ring)]
		f = bm.faces.new((front[i][j], back[i][j], back[i2][j2], front[i2][j2]))
		piece_uv(f, ("edge", k), i == i2)
	bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
	return finish(bm, "leaf")


# --- Beschläge ---------------------------------------------------------------------------------------------------
## Rotationskörper um die Achse axis durch center: profile als (radius, Abstand entlang der Achse); radius 0 = Pol
def lathe(bm, center, axis, profile, segs=SEGMENTS, dark=False):
	axis = Vector(axis).normalized()
	ref = Vector((0, 1, 0)) if abs(axis.y) < 0.9 else Vector((1, 0, 0))
	u = axis.cross(ref).normalized()
	w = axis.cross(u)
	rings = []
	for r, t in profile:
		c = Vector(center) + axis * t
		if r == 0:
			rings.append([bm.verts.new(B(*c))])
		else:
			rings.append([bm.verts.new(B(*(c + (u * math.cos(a) + w * math.sin(a)) * r)))
				for a in (2 * math.pi * s / segs for s in range(segs))])
	faces = []
	for a, b in zip(rings, rings[1:]):
		if len(a) == 1 and len(b) == 1:
			continue
		for s in range(segs):
			t = (s + 1) % segs
			if len(a) == 1:
				faces.append(bm.faces.new((a[0], b[s], b[t])))
			elif len(b) == 1:
				faces.append(bm.faces.new((a[s], b[0], a[t])))
			else:
				faces.append(bm.faces.new((a[s], b[s], b[t], a[t])))
	if len(rings[0]) > 1:
		faces.append(bm.faces.new(list(reversed(rings[0]))))
	if len(rings[-1]) > 1:
		faces.append(bm.faces.new(rings[-1]))
	bmesh.ops.recalc_face_normals(bm, faces=faces)
	if dark:   # zweites Material: schwarz (Linse, Schlüsselloch)
		for f in faces:
			f.material_index = 1
	return faces


## Quader mit abgefaster Vorderkante: Mitte c, Größe s (Godot), Fase auf der Seite normal (±Z)
def plate(bm, c, s, bevel, front):
	x, y, z = c
	hx, hy, hz = s[0] / 2, s[1] / 2, s[2] / 2
	back_z = z - front * hz
	face_z = z + front * hz
	rect = lambda d, zz: [bm.verts.new(B(x - hx + d, y - hy + d, zz)), bm.verts.new(B(x + hx - d, y - hy + d, zz)),
		bm.verts.new(B(x + hx - d, y + hy - d, zz)), bm.verts.new(B(x - hx + d, y + hy - d, zz))]
	loops = [rect(0, back_z), rect(0, face_z - front * bevel), rect(bevel, face_z)] if bevel > 0 \
		else [rect(0, back_z), rect(0, face_z)]
	faces = [bm.faces.new(list(reversed(loops[0]))), bm.faces.new(loops[-1])]
	for a, b in zip(loops, loops[1:]):
		for k in range(4):
			faces.append(bm.faces.new((a[k], a[(k + 1) % 4], b[(k + 1) % 4], b[k])))
	bmesh.ops.recalc_face_normals(bm, faces=faces)
	return faces


def build_hinge():
	bm = bmesh.new()
	z = THICK / 2 + 0.004
	h = HINGE_H / 2
	# Rolle mit Fuge zwischen den beiden Gewerben und Knöpfen oben und unten
	lathe(bm, (0, 0, z), (0, 1, 0), [(0, -h - 0.014), (0.004, -h - 0.012), (HINGE_R * 0.75, -h - 0.004),
		(HINGE_R, -h), (HINGE_R, -0.0015), (HINGE_R * 0.9, -0.0008), (HINGE_R * 0.9, 0.0008), (HINGE_R, 0.0015),
		(HINGE_R, h), (HINGE_R * 0.75, h + 0.004), (0.004, h + 0.012), (0, h + 0.014)])
	# Lappen: liegen in der Fuge zwischen Blatt und Zarge an der Scharnierkante
	plate(bm, (-0.002, 0, 0.004), (0.004, HINGE_H - 0.006, z - 0.004 + 0.02 + 0.004), 0.0, 1)
	return finish(bm, "hinge")


def build_peephole():
	bm = bmesh.new()
	t = THICK / 2
	# Flurseite (−Z): flacher Kragen, gewölbte Linse
	lathe(bm, (0, 0, -t), (0, 0, -1), [(0.0068, -0.002), (0.0115, -0.0005), (0.0115, 0.0015), (0.0095, 0.003),
		(0.0068, 0.0034)])
	lathe(bm, (0, 0, -t), (0, 0, -1), [(0.0068, 0.0025), (0.0045, 0.0042), (0, 0.0048)], dark=True)
	# Zimmerseite (+Z): Okular mit Rändel und dunklem Blick
	lathe(bm, (0, 0, t), (0, 0, 1), [(0.016, -0.001), (0.016, 0.002), (0.012, 0.004), (0.011, 0.012),
		(0.0115, 0.013), (0.0115, 0.016), (0.008, 0.0165)])
	lathe(bm, (0, 0, t), (0, 0, 1), [(0.008, 0.0162), (0.006, 0.0158), (0, 0.0155)], dark=True)
	return finish(bm, "peephole")


def build_plaque():
	bm = bmesh.new()
	w, h, d = PLAQUE
	plate(bm, (0, 0, -THICK / 2 - d / 2 + 0.0005), (w, h, d), 0.0025, -1)
	for sx in (-1, 1):   # Schrauben mit Linsenkopf
		lathe(bm, (sx * (w / 2 - 0.011), 0, -THICK / 2 - d + 0.0004), (0, 0, -1),
			[(0.0032, 0.0), (0.0029, 0.0009), (0.0018, 0.0016), (0, 0.0019)], segs=8)
	return finish(bm, "plaque")


def build_handle():
	bm = bmesh.new()
	for side in (1, -1):
		t = THICK / 2
		# Langschild: Drücker oben, Schlüsselloch 8,5 cm darunter
		plate(bm, (0, -0.04, side * (t + 0.004 - 0.0005)), (0.048, 0.25, 0.008), 0.003, side)
		face = t + 0.0075
		# Rosette, Hals und Drücker (nach −X), Ende verdickt
		lathe(bm, (0, 0, side * face), (0, 0, side), [(0.017, -0.001), (0.017, 0.004), (0.012, 0.008),
			(0.0095, 0.012), (0.0095, 0.055)])
		lathe(bm, (0.0095, 0, side * (face + 0.048)), (-1, 0, 0), [(0.0098, 0.0), (0.0092, 0.03),
			(0.0092, 0.09), (0.0105, 0.115), (0.0105, 0.128), (0.0075, 0.136), (0, 0.139)])
		# Schlüsselloch: dunkles Plättchen knapp vor dem Schild (Kreis über Schlitz)
		y = -0.085
		zz = side * (face + 0.0004)
		ring = [bm.verts.new(B(0.0045 * math.cos(a), y + 0.004 + 0.0045 * math.sin(a), zz))
			for a in (math.pi * (-0.25 + 1.5 * s / 9) for s in range(10))]
		slot = [bm.verts.new(B(-0.0035, y - 0.012, zz)), bm.verts.new(B(0.0035, y - 0.012, zz))]
		f = bm.faces.new(ring + slot)
		f.normal_update()
		if f.normal.dot(B(0, 0, side)) < 0:
			f.normal_flip()
		f.material_index = 1
	return finish(bm, "handle")


leaf = build_leaf()
hinge = build_hinge()
peephole = build_peephole()
handle = build_handle()
plaque = build_plaque()
hardware = [hinge, handle, peephole, plaque]
# Lage auf dem Blatt – zum Backen (Verschattung durchs Blatt) und für die Vorschau; exportiert wird im Ursprung
PLACES = {"hinge": (0, 0.12 * LEAF[1], 0), "handle": (LEAF[0] - 0.1, 1.04, 0), "peephole": (LEAF[0] / 2, PEEP_Y, 0),
	"plaque": (LEAF[0] / 2, PLAQUE_Y, 0)}


# --- Atlas-UVs -------------------------------------------------------------------------------------------------
def atlas_uv(obs, margin):
	bpy.ops.object.select_all(action='DESELECT')
	for ob in obs:
		if "atlas" not in ob.data.uv_layers:
			ob.data.uv_layers.new(name="atlas")
		ob.data.uv_layers.active = ob.data.uv_layers["atlas"]
		ob.select_set(True)
	bpy.context.view_layer.objects.active = obs[0]
	bpy.ops.object.mode_set(mode='EDIT')
	bpy.ops.mesh.select_all(action='SELECT')
	bpy.ops.uv.smart_project(angle_limit=math.radians(50), island_margin=margin, area_weight=0.0, scale_to_bounds=False)
	bpy.ops.uv.pack_islands(rotate=True, margin=margin)
	bpy.ops.object.mode_set(mode='OBJECT')
	for ob in obs:
		ob.data.uv_layers["atlas"].active_render = True


atlas_uv([leaf], 0.003)
atlas_uv(hardware, 0.01)


# --- Quellmaterialien zum Backen ----------------------------------------------------------------------------------
def new_image(name, size, color_data):
	img = bpy.data.images.new(name, size, size, alpha=False, float_buffer=False)
	img.colorspace_settings.name = 'sRGB' if color_data else 'Non-Color'
	return img


def target_node(nt, img):
	node = nt.nodes.new("ShaderNodeTexImage")
	node.image = img
	uv = nt.nodes.new("ShaderNodeUVMap")
	uv.uv_map = "atlas"
	nt.links.new(uv.outputs["UV"], node.inputs["Vector"])
	node.name = "bake_target"
	nt.nodes.active = node
	return node


def wood_material():
	mat = bpy.data.materials.new("wood_src")
	mat.use_nodes = True
	nt = mat.node_tree
	bsdf = nt.nodes["Principled BSDF"]
	uv = nt.nodes.new("ShaderNodeUVMap")
	uv.uv_map = "grain"
	tex = {}
	for key, cs in (("Color", 'sRGB'), ("NormalGL", 'Non-Color'), ("Roughness", 'Non-Color')):
		n = nt.nodes.new("ShaderNodeTexImage")
		n.image = bpy.data.images.load(WOOD % key)
		n.image.colorspace_settings.name = cs
		nt.links.new(uv.outputs["UV"], n.inputs["Vector"])
		tex[key] = n
	mix = nt.nodes.new("ShaderNodeMix")
	mix.data_type = 'RGBA'
	mix.blend_type = 'MULTIPLY'
	mix.inputs["Factor"].default_value = 1.0
	mix.inputs[7].default_value = WOOD_TINT + (1,)
	nt.links.new(tex["Color"].outputs["Color"], mix.inputs[6])
	nt.links.new(mix.outputs[2], bsdf.inputs["Base Color"])
	nm = nt.nodes.new("ShaderNodeNormalMap")
	nm.uv_map = "grain"
	nm.inputs["Strength"].default_value = 0.6
	nt.links.new(tex["NormalGL"].outputs["Color"], nm.inputs["Color"])
	nt.links.new(nm.outputs["Normal"], bsdf.inputs["Normal"])
	# Lack: Rauheit des Fotos zusammengedrückt auf 0,35 … 0,6
	ramp = nt.nodes.new("ShaderNodeMapRange")
	ramp.inputs["To Min"].default_value = 0.35
	ramp.inputs["To Max"].default_value = 0.6
	nt.links.new(tex["Roughness"].outputs["Color"], ramp.inputs["Value"])
	nt.links.new(ramp.outputs["Result"], bsdf.inputs["Roughness"])
	return mat


def brass_material(dark):
	mat = bpy.data.materials.new("brass_src_dark" if dark else "brass_src")
	mat.use_nodes = True
	nt = mat.node_tree
	bsdf = nt.nodes["Principled BSDF"]   # nicht metallisch: sonst bäckt Cycles keine Grundfarbe
	if dark:
		bsdf.inputs["Base Color"].default_value = (0.012, 0.012, 0.014, 1)
		return mat
	# Messing mit fleckigem Anlauf (Rauschen in Objektkoordinaten)
	coord = nt.nodes.new("ShaderNodeTexCoord")
	noise = nt.nodes.new("ShaderNodeTexNoise")
	noise.inputs["Scale"].default_value = 35.0
	noise.inputs["Detail"].default_value = 3.0
	nt.links.new(coord.outputs["Object"], noise.inputs["Vector"])
	ramp = nt.nodes.new("ShaderNodeValToRGB")
	ramp.color_ramp.elements[0].position = 0.3
	ramp.color_ramp.elements[0].color = (0.6, 0.43, 0.18, 1)
	ramp.color_ramp.elements[1].position = 0.7
	ramp.color_ramp.elements[1].color = (0.8, 0.6, 0.29, 1)
	nt.links.new(noise.outputs["Fac"], ramp.inputs["Fac"])
	nt.links.new(ramp.outputs["Color"], bsdf.inputs["Base Color"])
	return mat


sc = bpy.context.scene
sc.render.engine = 'CYCLES'
sc.cycles.device = 'CPU'
sc.world = bpy.data.worlds.new("bake")
sc.world.light_settings.distance = AO_DISTANCE
sc.render.bake.margin = 8
sc.render.bake.use_clear = True


def bake(obs, kind, img, samples, **kw):
	for ob in obs:
		for slot in ob.material_slots:
			nt = slot.material.node_tree
			n = nt.nodes["bake_target"]
			n.image = img
			nt.nodes.active = n
	sc.cycles.samples = samples
	bpy.ops.object.select_all(action='DESELECT')
	for ob in obs:
		ob.select_set(True)
	bpy.context.view_layer.objects.active = obs[0]
	bpy.ops.object.bake(type=kind, **kw)
	return np.array(img.pixels[:], dtype=np.float32).reshape(img.size[1], img.size[0], 4)


def prepare(obs, mats):
	for ob in obs:
		ob.data.materials.clear()
		for m in mats:
			ob.data.materials.append(m)
	for m in mats:
		target_node(m.node_tree, None)


def to_image(name, px, color_data):
	img = new_image(name, px.shape[1], color_data)
	img.pixels[:] = px.ravel()
	img.pack()
	return img


## Farbe × AO: AO linear, die Farbe liegt im Bild als sRGB – also mit AO^(1/2,2) multiplizieren
def shade(color, ao, strength):
	a = 1.0 - strength * (1.0 - np.clip(ao[..., :1], 0, 1))
	out = color.copy()
	out[..., :3] *= a ** (1 / 2.2)
	return out


wood = wood_material()
prepare([leaf], [wood])
brass_mats = [brass_material(False), brass_material(True)]
prepare(hardware, brass_mats)

# Blatt allein (Beschläge stehen im Ursprung und würden Flecken werfen), dann die Beschläge auf dem Blatt
for ob in hardware:
	ob.hide_render = True
work = {k: new_image("work_" + k, WOOD_SIZE if k in ("color", "ao") else DETAIL_SIZE, k == "color")
	for k in ("color", "ao", "normal", "rough")}
col = bake([leaf], 'DIFFUSE', work["color"], 1, pass_filter={'COLOR'})
ao = bake([leaf], 'AO', work["ao"], 256)
nrm = bake([leaf], 'NORMAL', work["normal"], 1, normal_space='TANGENT')
rgh = bake([leaf], 'ROUGHNESS', work["rough"], 1)
print("Blatt-AO: Mittel %.3f, dunkelster Wert %.3f" % (ao[..., 0].mean(), ao[..., 0].min()))
orm = np.ones_like(rgh)
orm[..., 1] = rgh[..., 0]
orm[..., 2] = 0.0
wood_albedo = to_image("door_wood_albedo", shade(col, ao, 0.9), True)
wood_normal = to_image("door_wood_normal", nrm, False)
wood_orm = to_image("door_wood_orm", orm, False)

for ob in hardware:
	ob.hide_render = False
	ob.location = B(*PLACES[ob.name])
bwork = {k: new_image("bwork_" + k, BRASS_SIZE, k == "color") for k in ("color", "ao")}
bcol = bake(hardware, 'DIFFUSE', bwork["color"], 1, pass_filter={'COLOR'})
sc.world.light_settings.distance = 0.02
bao = bake(hardware, 'AO', bwork["ao"], 256)
brass_albedo = to_image("door_brass_albedo", shade(bcol, bao, 0.8), True)
for ob in hardware:
	ob.location = (0, 0, 0)


# --- Exportmaterialien -------------------------------------------------------------------------------------------
def export_material(name, albedo, normal=None, orm=None, metallic=0.0, roughness=0.5):
	mat = bpy.data.materials.new(name)
	mat.use_nodes = True
	nt = mat.node_tree
	bsdf = nt.nodes["Principled BSDF"]
	t = nt.nodes.new("ShaderNodeTexImage")
	t.image = albedo
	nt.links.new(t.outputs["Color"], bsdf.inputs["Base Color"])
	bsdf.inputs["Metallic"].default_value = metallic
	bsdf.inputs["Roughness"].default_value = roughness
	if normal:
		n = nt.nodes.new("ShaderNodeTexImage")
		n.image = normal
		nm = nt.nodes.new("ShaderNodeNormalMap")
		nt.links.new(n.outputs["Color"], nm.inputs["Color"])
		nt.links.new(nm.outputs["Normal"], bsdf.inputs["Normal"])
	if orm:
		o = nt.nodes.new("ShaderNodeTexImage")
		o.image = orm
		sep = nt.nodes.new("ShaderNodeSeparateColor")
		nt.links.new(o.outputs["Color"], sep.inputs["Color"])
		nt.links.new(sep.outputs["Green"], bsdf.inputs["Roughness"])
		nt.links.new(sep.outputs["Blue"], bsdf.inputs["Metallic"])
	return mat


door_wood = export_material("door_wood", wood_albedo, wood_normal, wood_orm)
door_brass = export_material("door_brass", brass_albedo, metallic=1.0, roughness=0.32)
leaf.data.materials.clear()
leaf.data.materials.append(door_wood)
for ob in hardware:
	ob.data.materials.clear()
	ob.data.materials.append(door_brass)
	for p in ob.data.polygons:
		p.material_index = 0
for ob in [leaf] + hardware:
	for name in [l.name for l in ob.data.uv_layers if l.name != "atlas"]:
		ob.data.uv_layers.remove(ob.data.uv_layers[name])
	tris = sum(len(p.vertices) - 2 for p in ob.data.polygons)
	print("%-9s %4d Dreiecke" % (ob.name, tris))

bpy.ops.object.select_all(action='DESELECT')
for ob in [leaf] + hardware:
	ob.select_set(True)
bpy.ops.export_scene.gltf(
	filepath=DST, export_format='GLB', export_yup=True, export_apply=False, use_selection=True,
	export_texcoords=True, export_normals=True, export_tangents=True, export_materials='EXPORT',
	export_image_format='JPEG', export_jpeg_quality=92, export_skins=False, export_animations=False,
	export_morph=False, export_cameras=False, export_lights=False)
print("geschrieben:", DST)


# --- Vorschau: Tür halb offen in einer Wand, beide Seiten ------------------------------------------------------
if PREVIEW_DIR:
	os.makedirs(PREVIEW_DIR, exist_ok=True)
	door = bpy.data.objects.new("door", None)
	sc.collection.objects.link(door)
	parts = [leaf]
	for ob in hardware:
		ob.location = B(*PLACES[ob.name])
		parts.append(ob)
	h2 = hinge.copy()
	h2.location = B(0, 0.88 * LEAF[1], 0)
	sc.collection.objects.link(h2)
	parts.append(h2)
	for ob in parts:
		ob.parent = door
	door.location = B(0.01, 0.01, 0)
	door.rotation_euler = (0, 0, math.radians(-35))   # geht nach +Z (Blender −Y) auf

	def box(name, c, s, color):
		bm = bmesh.new()
		bmesh.ops.create_cube(bm, size=1.0)
		ob = finish(bm, name)
		ob.location = B(*c)
		ob.scale = (s[0], s[2], s[1])
		m = bpy.data.materials.new(name)
		m.use_nodes = True
		m.node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value = color
		m.node_tree.nodes["Principled BSDF"].inputs["Roughness"].default_value = 0.8
		ob.data.materials.append(m)

	wall = (0.42, 0.36, 0.3, 1)
	box("wall_l", (-0.6, 1.4, 0), (1.2, 2.8, 0.2), wall)
	box("wall_r", (1.2 + 0.6, 1.4, 0), (1.2, 2.8, 0.2), wall)
	box("wall_t", (0.6, 2.45, 0), (1.2, 0.7, 0.2), wall)
	box("floor", (0.6, -0.05, 0), (5, 0.1, 5), (0.25, 0.2, 0.17, 1))
	sc.world.use_nodes = True
	sc.world.node_tree.nodes["Background"].inputs["Strength"].default_value = 0.15
	sc.world.light_settings.distance = 10.0
	cam = bpy.data.objects.new("cam", bpy.data.cameras.new("cam"))
	cam.data.lens = 40
	sc.collection.objects.link(cam)
	sc.camera = cam
	lamp = bpy.data.objects.new("lamp", bpy.data.lights.new("lamp", 'AREA'))
	lamp.data.energy = 220
	lamp.data.size = 0.6
	sc.collection.objects.link(lamp)
	sc.cycles.samples = 96
	sc.cycles.use_denoising = True
	sc.render.resolution_x, sc.render.resolution_y = 900, 1100

	def shot(name, cam_pos, target, lamp_pos):
		cam.location = B(*cam_pos)
		d = B(*target) - cam.location
		cam.rotation_euler = d.to_track_quat('-Z', 'Y').to_euler()
		lamp.location = B(*lamp_pos)
		d = B(*target) - lamp.location
		lamp.rotation_euler = d.to_track_quat('-Z', 'Y').to_euler()
		sc.render.filepath = os.path.join(PREVIEW_DIR, name)
		bpy.ops.render.render(write_still=True)

	# Zimmerseite (+Z, Bänder) und Flurseite (−Z, Plakette, Spion)
	shot("door_room_zimmer.png", (2.2, 1.5, 2.6), (0.5, 1.1, 0.3), (1.6, 2.5, 1.6))
	shot("door_room_flur.png", (1.6, 1.5, -2.4), (0.5, 1.15, 0), (0.4, 2.6, -1.4))
	shot("door_room_nah.png", (0.9, 1.62, -0.75), (0.55, 1.5, 0.1), (0.2, 2.4, -1.0))
