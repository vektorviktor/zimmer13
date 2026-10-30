# Baut die realistische Zimmertür (Ersatz für die gemalte „door_hotel“ aus build_doors.py, Spielkonzept 9.2): ein
# Blatt mit vier Kassetten (45°-Fase, flache Füllung) und die Beschläge aus Messing – Türspion, leere Plakette für die
# Zimmernummer, zwei Bänder, Drücker auf Langschild (beidseits, mit Schlüsselloch).
#
# Kein Ausgangsmodell: Das Blatt ist ein Raster aus Friesen (Rahmen, Mittelfries, Riegel), in jedem Feld ein Ring aus
# Profilschleifen wie das Rahmenfeld in build_wainscot.py. Low Poly (Blatt ≈ 200 Dreiecke, Beschläge je < 500).
#
# Holz wie Vertäfelung und Türrahmen (Mat.hotel_wood, Wunsch des Nutzers 30.10.: überall dieselbe Optik): Das Blatt
# trägt kein Material, sondern zwei UV-Sätze – UVMap in Metern für das Holzfoto über psx_photo (Faser je Friesstück
# wie beim Schreiner: Rahmen und Mittelfries senkrecht, Riegel waagerecht, Füllungen senkrecht, jedes Stück mit eigenem
# Versatz) und „AO“, ein Atlas für die in Cycles gebackene Verschattung, gespeichert als eigenes Bild (im Spiel mit
# der Grundfarbe multipliziert, wirkt so auch im Lampenlicht). Die Beschläge teilen sich einen Atlas mit gebackener
# Farbe: Messing mit leichtem Anlauf, in Ritzen dunkler, Linse und Schlüsselloch schwarz (Material „door_brass“).
#
# Lage (Godot-Achsen, wie Door): Blatt in der XY-Ebene, Scharnierkante bei x = 0, Blatt nach +X, Unterkante y = 0,
# Mitte der Blattdicke bei z = 0. Die Tür geht nach +Z auf (Zimmerseite, dort die Bänder), der Flur liegt bei −Z
# (Plakette, Linse des Spions). Objekte:
#   „leaf“     LEAF groß, Door streckt es auf die Blattgröße
#   „hinge“    ein Band, Ursprung auf Scharnierkante und Mittelebene in Bandmitte, Zylinder auf der Zimmerseite
#   „handle“   Drücker beidseits, Ursprung auf der Drückerachse in der Mittelebene, Drücker nach −X zum Scharnier
#   „peephole“ Spion, Ursprung auf seiner Achse in der Mittelebene
#   „plaque“   leere Plakette auf der Flurseite, Ursprung in ihrer Mitte auf der Mittelebene
# Beschläge werden ungestreckt gesetzt (wie bisher Klinke und Bänder).
#
# Aufruf aus dem Projektordner (Blender 4.3):
#   blender -b --python tools/build_room_door.py -- assets/models/door_room.glb assets/textures/door_room_ao.png
import bpy, bmesh, sys, os, math, random
import numpy as np
from mathutils import Vector, Matrix

argv = sys.argv[sys.argv.index("--") + 1:]
DST = os.path.abspath(argv[0])
AO_DST = os.path.abspath(argv[1])

LEAF = (1.18, 2.08)       # = Door.HOTEL_LEAF
THICK = 0.06
# Raster der Friese (Meter): Rahmen 15 cm, Mittelfries 16 cm, Sockel 24 cm, Schlossriegel 22 cm, Kopf 15 cm
XS = [0.0, 0.15, 0.51, 0.67, 1.03, LEAF[0]]
YS = [0.0, 0.24, 0.86, 1.08, 1.93, LEAF[1]]
PANELS = [(1, 1), (3, 1), (1, 3), (3, 3)]
# Füllung: Profil als (Abstand von der Feldkante nach innen, Höhe gegenüber der Blattfläche) – eine Fase unter 45°
# hinab zur flachen Füllung (Wunsch des Nutzers 29.10.: schlicht, ohne Spiegel)
PANEL = [(0.0, 0.0), (0.021, -0.021)]
GRAIN_SHIFT = 2.0         # Versatz der Friesstücke im Holzbild, höchstens so viele Meter

HINGE_H = 0.10
HINGE_R = 0.009
PEEP_SCALE = 2.5          # Spion gegenüber einem echten (Ø 2,3 cm) vergrößert – im Spiel sonst kaum zu sehen
PEEP_Y = 1.50             # Vorschläge für Door (Höhe über dem Boden, Mitte des Mittelfrieses)
PLAQUE_Y = 1.66
PLAQUE = (0.15, 0.065, 0.005)

AO_DISTANCE = 0.06
AO_SIZE = 1024
AO_STRENGTH = 0.9
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
	grain = bm.loops.layers.uv.new("UVMap")   # Meter, für das Holzfoto
	offsets = {}

	def piece_uv(f, piece, vertical):
		if piece not in offsets:
			offsets[piece] = (random.random() * GRAIN_SHIFT, random.random() * GRAIN_SHIFT)
		ou, ov = offsets[piece]
		for loop in f.loops:
			p = G(loop.vert.co)
			u, v = (p.y, p.x + p.z) if vertical else (p.x, p.y + p.z)
			loop[grain].uv = (u + ou, v + ov)

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


## Band: schlichter Messingzylinder an der Scharnierkante, auf der Zimmerseite (Wunsch des Nutzers 29.10.)
def build_hinge():
	bm = bmesh.new()
	h = HINGE_H / 2
	lathe(bm, (0, 0, THICK / 2 + 0.004), (0, 1, 0), [(HINGE_R, -h), (HINGE_R, h)])
	return finish(bm, "hinge")


def build_peephole():
	bm = bmesh.new()
	t = THICK / 2
	s = PEEP_SCALE
	sc = lambda prof: [(r * s, d * s) for r, d in prof]
	# Flurseite (−Z): flacher Kragen, gewölbte Linse
	lathe(bm, (0, 0, -t), (0, 0, -1), sc([(0.0068, -0.002), (0.0115, -0.0005), (0.0115, 0.0015), (0.0095, 0.003),
		(0.0068, 0.0034)]))
	lathe(bm, (0, 0, -t), (0, 0, -1), sc([(0.0068, 0.0025), (0.0045, 0.0042), (0, 0.0048)]), dark=True)
	# Zimmerseite (+Z): Okular mit Rändel und dunklem Blick
	lathe(bm, (0, 0, t), (0, 0, 1), sc([(0.016, -0.001), (0.016, 0.002), (0.012, 0.004), (0.011, 0.012),
		(0.0115, 0.013), (0.0115, 0.016), (0.008, 0.0165)]))
	lathe(bm, (0, 0, t), (0, 0, 1), sc([(0.008, 0.0162), (0.006, 0.0158), (0, 0.0155)]), dark=True)
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




# --- Backen ------------------------------------------------------------------------------------------------------
def new_image(name, size, color_data):
	img = bpy.data.images.new(name, size, size, alpha=False, float_buffer=False)
	img.colorspace_settings.name = 'sRGB' if color_data else 'Non-Color'
	return img


## Material zum Backen: Zielbild auf dem Atlas-UV-Satz; color = Grundfarbe für den Farbbake (nicht metallisch, sonst
## bäckt Cycles keine Grundfarbe)
def bake_material(name, color=None):
	mat = bpy.data.materials.new(name)
	mat.use_nodes = True
	nt = mat.node_tree
	if color is not None:
		nt.nodes["Principled BSDF"].inputs["Base Color"].default_value = color
	node = nt.nodes.new("ShaderNodeTexImage")
	uv = nt.nodes.new("ShaderNodeUVMap")
	uv.uv_map = "atlas"
	nt.links.new(uv.outputs["UV"], node.inputs["Vector"])
	node.name = "bake_target"
	nt.nodes.active = node
	return mat


## Messing mit fleckigem Anlauf (Rauschen in Objektkoordinaten)
def brass_material():
	mat = bake_material("brass_src")
	nt = mat.node_tree
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
	nt.links.new(ramp.outputs["Color"], nt.nodes["Principled BSDF"].inputs["Base Color"])
	return mat


sc = bpy.context.scene
sc.render.engine = 'CYCLES'
sc.cycles.device = 'CPU'
sc.world = bpy.data.worlds.new("bake")
sc.render.bake.margin = 8
sc.render.bake.use_clear = True


def bake(obs, kind, img, samples, **kw):
	for ob in obs:
		ob.data.uv_layers.active = ob.data.uv_layers["atlas"]
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


leaf.data.materials.append(bake_material("leaf_src"))
for ob in hardware:
	for m in (brass_material(), bake_material("dark_src", (0.012, 0.012, 0.014, 1))):
		ob.data.materials.append(m)

# Blatt allein (die Beschläge stehen im Ursprung und würden Flecken werfen)
for ob in hardware:
	ob.hide_render = True
sc.world.light_settings.distance = AO_DISTANCE
img = new_image("door_room_ao", AO_SIZE, False)
ao = bake([leaf], 'AO', img, 256)
print("Blatt-AO: Mittel %.3f, dunkelster Wert %.3f" % (ao[..., 0].mean(), ao[..., 0].min()))
ao[..., :3] = 1.0 - AO_STRENGTH * (1.0 - np.clip(ao[..., :3], 0, 1))
img.pixels[:] = ao.ravel()
img.filepath_raw = AO_DST
img.file_format = 'PNG'
img.save()

# Beschläge auf dem Blatt: Farbe × AO (AO linear, die Farbe liegt im Bild als sRGB – daher AO^(1/2,2))
for ob in hardware:
	ob.hide_render = False
	ob.location = B(*PLACES[ob.name])
bcol = bake(hardware, 'DIFFUSE', new_image("brass_color", BRASS_SIZE, True), 1, pass_filter={'COLOR'})
sc.world.light_settings.distance = 0.02
bao = bake(hardware, 'AO', new_image("brass_ao", BRASS_SIZE, False), 256)
bcol[..., :3] *= (1.0 - 0.8 * (1.0 - np.clip(bao[..., :1], 0, 1))) ** (1 / 2.2)
brass_img = new_image("door_brass_albedo", BRASS_SIZE, True)
brass_img.pixels[:] = bcol.ravel()
brass_img.pack()
for ob in hardware:
	ob.location = (0, 0, 0)


# --- Export ------------------------------------------------------------------------------------------------------
door_brass = bpy.data.materials.new("door_brass")
door_brass.use_nodes = True
nt = door_brass.node_tree
bsdf = nt.nodes["Principled BSDF"]
t = nt.nodes.new("ShaderNodeTexImage")
t.image = brass_img
nt.links.new(t.outputs["Color"], bsdf.inputs["Base Color"])
bsdf.inputs["Metallic"].default_value = 1.0
bsdf.inputs["Roughness"].default_value = 0.32
leaf.data.materials.clear()   # Holz setzt Door (Mat.hotel_wood mit dem AO-Bild)
for ob in hardware:
	ob.data.materials.clear()
	ob.data.materials.append(door_brass)
	for p in ob.data.polygons:
		p.material_index = 0
for ob in [leaf] + hardware:
	tris = sum(len(p.vertices) - 2 for p in ob.data.polygons)
	print("%-9s %4d Dreiecke, UV-Sätze %s" % (ob.name, tris, [l.name for l in ob.data.uv_layers]))

bpy.ops.object.select_all(action='DESELECT')
for ob in [leaf] + hardware:
	ob.select_set(True)
bpy.ops.export_scene.gltf(
	filepath=DST, export_format='GLB', export_yup=True, export_apply=False, use_selection=True,
	export_texcoords=True, export_normals=True, export_tangents=False, export_materials='EXPORT',
	export_image_format='JPEG', export_jpeg_quality=92, export_skins=False, export_animations=False,
	export_morph=False, export_cameras=False, export_lights=False)
print("geschrieben:", DST, AO_DST)
