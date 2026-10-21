# Baut die Rezeption neu als U mit runden vorderen Ecken – nach dem Vorbild von reception_desk_low_poly (Sketchfab),
# dessen Holz und schwarzer Sockel übernommen werden (Platzhalter, neue Materialien kommen). Im Rohmodell sind die
# Ecken eckig und das Netz zu zerstückelt zum Umbiegen, deshalb entsteht alles neu:
#   · Korpus: dünne Holzwange (THICK) entlang des U, außen RADIUS, innen konzentrisch RADIUS - THICK
#   · Endkappen hinten an den Armen, darunter ein zurückgesetzter Sockel (PLINTH hoch, INSET zurück)
#   · Ablage innen auf SHELF_Z, vorn ebenfalls rund
#   · Steinplatte im Terrazzo der Lobbysäulen (LevelBuilder.PILLAR_TEX): steht OVERHANG über, Außenkante konzentrisch
#     zum Korpus mit kleiner Fase, Innenkante (ARM breit, FRONT tief) mit eigenem Radius INNER_RADIUS – konzentrisch
#     ginge nicht, die Platte ist breiter als der Radius
#   · zwei goldene Rohre (RAIL_RADIUS) außen um Seiten und Front, RAIL_GAP lichter Abstand unter der Platte und über
#     dem Boden, RAIL_STANDOFF vor dem Holz auf Haltern
#
# Lage (Godot-Achsen): Kundenseite nach +Z, Ursprung mittig im Grundriss auf dem Boden, WIDTH × DEPTH × HEIGHT Meter.
# Materialien „wood“, „stone“, „plinth“, „gold“. UVs in Metern × Kacheldichte (Holzmaserung senkrecht auf den Wangen,
# längs auf der Ablage; Stein 1 m je Kachel wie PILLAR_METERS).
#
# Aufruf aus dem Projektordner (Blender 4.3):
#   blender -b --python tools/build_reception.py -- assets/source/reception_desk.glb assets/models/reception.glb
import bpy, bmesh, sys, math, os
from mathutils import Matrix, Vector

WIDTH = 5.0          # Meter, Steinplatte außen (wie die Rezeption im Spiel)
HEIGHT = 1.1         # Meter, Oberkante Stein (RECEPTION_H)
DEPTH = 1.5          # Meter, Steinplatte außen (Vorbild im Grundriss gleichmäßig auf WIDTH skaliert, Plan angepasst)
RADIUS = 0.4         # Außenradius des Korpus an den vorderen Ecken
TOP = 0.05           # Plattenstärke
CHAMFER = 0.008      # Fase an der oberen Außenkante der Platte
OVERHANG = 0.03      # Platte steht so weit über den Korpus (außen und hinten)
ARM = 0.5            # Platte der Arme, Breite (wie im Plan)
FRONT = 0.40         # Platte vorn, Tiefe
INNER_RADIUS = 0.2   # Innenecke der Platte
THICK = 0.05         # Holzwangen und Endkappen
PLINTH = 0.075       # Sockelhöhe
INSET = 0.03         # Sockel hinter der Holzflucht
SHELF_Z = 0.79       # Oberkante der Ablage
SHELF_T = 0.04
SHELF_DEPTH = 1.15   # ab der Holzfront
SEGMENTS = 8         # je Viertelkreis
RAIL_RADIUS = 0.04   # Goldrohre, 8 cm Durchmesser
RAIL_GAP = 0.10      # lichter Abstand unter der Platte bzw. über dem Boden
RAIL_STANDOFF = 0.02 # Luft zwischen Rohr und Holz
RAIL_SIDES = 16      # Ecken im Rohrquerschnitt
BRACKET_RADIUS = 0.012
GOLD = (1.0, 0.72, 0.32)
STONE_TEX = "assets/textures/TerrazzoDark_01/TerrazzoDark_01_basecolor.jpg"
STONE_ROUGHNESS = "assets/textures/TerrazzoDark_01/TerrazzoDark_01_roughness.jpg"

WOOD_UV = 1.0 / 4.18     # Kacheln je Meter wie im Vorbild
STONE_UV = 1.0           # PILLAR_METERS
PLINTH_UV = 1.2

argv = sys.argv[sys.argv.index("--") + 1:]
SRC, DST = argv[0], argv[1]

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=SRC)
mats = {}
for o in list(bpy.context.scene.objects):
	if o.type == 'MESH':
		for m in o.data.materials:
			mats[m.name] = m
	bpy.data.objects.remove(o)
# Texturen ohne Verschiebung/Drehung/Skalierung – die Dichte steckt in den UVs
for name, new in (("M_Legno", "wood"), ("M_PlasticaNera", "plinth")):
	m = mats[name]
	m.name = new
	for n in m.node_tree.nodes:
		if n.type == 'MAPPING':
			n.inputs["Location"].default_value = (0, 0, 0)
			n.inputs["Rotation"].default_value = (0, 0, 0)
			n.inputs["Scale"].default_value = (1, 1, 1)


def stone_material():
	m = bpy.data.materials.new("stone")
	m.use_nodes = True
	nt = m.node_tree
	bsdf = nt.nodes["Principled BSDF"]
	color = nt.nodes.new("ShaderNodeTexImage")
	color.image = bpy.data.images.load(os.path.abspath(STONE_TEX))
	rough = nt.nodes.new("ShaderNodeTexImage")
	rough.image = bpy.data.images.load(os.path.abspath(STONE_ROUGHNESS))
	rough.image.colorspace_settings.name = "Non-Color"
	split = nt.nodes.new("ShaderNodeSeparateColor")
	nt.links.new(color.outputs["Color"], bsdf.inputs["Base Color"])
	nt.links.new(rough.outputs["Color"], split.inputs["Color"])
	nt.links.new(split.outputs["Green"], bsdf.inputs["Roughness"])


def gold_material():
	m = bpy.data.materials.new("gold")
	m.use_nodes = True
	bsdf = m.node_tree.nodes["Principled BSDF"]
	bsdf.inputs["Base Color"].default_value = (*GOLD, 1.0)
	bsdf.inputs["Metallic"].default_value = 1.0
	bsdf.inputs["Roughness"].default_value = 0.3


stone_material()
gold_material()
MAT_INDEX = {"wood": 0, "stone": 1, "plinth": 2, "gold": 3}
DENSITY = {"wood": WOOD_UV, "stone": STONE_UV, "plinth": PLINTH_UV, "gold": 1.0}

# Blender: vorn = -Y (wird im glTF zu +Z), oben = +Z
FRONT_Y = -DEPTH / 2.0
BACK_Y = DEPTH / 2.0


def u_path(xl, yf, cx, cy, r, back):
	"""U-Linie: links von hinten nach vorn, Viertelkreis um (cx, cy), vorn quer, rechts gespiegelt wieder nach hinten."""
	pts = [Vector((xl, back))]
	for k in range(SEGMENTS + 1):
		a = math.pi + k * (math.pi / 2.0) / SEGMENTS
		pts.append(Vector((cx + r * math.cos(a), cy + r * math.sin(a))))
	for k in range(SEGMENTS + 1):
		a = 1.5 * math.pi + k * (math.pi / 2.0) / SEGMENTS
		pts.append(Vector((-cx + r * math.cos(a), cy + r * math.sin(a))))
	pts.append(Vector((-xl, back)))
	return pts


def outer(d, back):
	"""Außenkontur der Steinplatte, um d nach innen versetzt (negativ = nach außen; bleibt konzentrisch)."""
	ro = RADIUS + OVERHANG
	return u_path(-WIDTH / 2.0 + d, FRONT_Y + d, -WIDTH / 2.0 + ro, FRONT_Y + ro, ro - d, back)


def inner_top():
	"""Innenkante der Steinplatte."""
	return u_path(-WIDTH / 2.0 + ARM, FRONT_Y + FRONT, -WIDTH / 2.0 + ARM + INNER_RADIUS, FRONT_Y + FRONT + INNER_RADIUS,
			INNER_RADIUS, BACK_Y)


def arclen(pts):
	s = [0.0]
	for i in range(1, len(pts)):
		s.append(s[-1] + (pts[i] - pts[i - 1]).length)
	return s


bm = bmesh.new()
uv_layer = bm.loops.layers.uv.new("UVMap")


def planar_uv(face, mat):
	"""Kastenprojektion nach der Hauptrichtung der Normalen."""
	k = DENSITY[mat]
	n = face.normal
	for loop in face.loops:
		p = loop.vert.co
		if abs(n.z) >= max(abs(n.x), abs(n.y)):
			loop[uv_layer].uv = (p.y * k, p.x * k) if mat == "wood" else (p.x * k, p.y * k)
		elif abs(n.y) >= abs(n.x):
			loop[uv_layer].uv = (p.x * k, p.z * k)
		else:
			loop[uv_layer].uv = (p.y * k, p.z * k)


def add_face(verts, mat, uvs=None):
	f = bm.faces.new(verts)
	f.material_index = MAT_INDEX[mat]
	f.normal_update()
	if uvs is None:
		planar_uv(f, mat)
	else:
		for loop, uv in zip(f.loops, uvs):
			loop[uv_layer].uv = uv
	return f


def sweep(rings, mat):
	"""Geschlossener Querschnitt entlang der U-Linie. rings: [(Punkte, z), …] einmal rund um den Querschnitt; jede
	Punktliste hat gleich viele Punkte. Wände (senkrecht) bekommen Bogenlänge × Höhe, flache Teile Draufsicht-UVs."""
	k = DENSITY[mat]
	vs = [[bm.verts.new((p.x, p.y, z)) for p in pts] for pts, z in rings]
	lens = [arclen(pts) for pts, _ in rings]
	for i in range(len(rings)):
		j = (i + 1) % len(rings)
		wall = abs(rings[i][1] - rings[j][1]) > (rings[i][0][0] - rings[j][0][0]).length
		for s in range(len(vs[i]) - 1):
			quad = [vs[i][s], vs[i][s + 1], vs[j][s + 1], vs[j][s]]
			uvs = None
			if wall:
				uvs = [(lens[i][s] * k, rings[i][1] * k), (lens[i][s + 1] * k, rings[i][1] * k),
						(lens[j][s + 1] * k, rings[j][1] * k), (lens[j][s] * k, rings[j][1] * k)]
			add_face(quad, mat, uvs)
	add_face([v[0] for v in vs], mat)
	add_face([v[-1] for v in reversed(vs)], mat)


def box(x0, y0, z0, x1, y1, z1, mat):
	c = [bm.verts.new((x, y, z)) for x in (x0, x1) for y in (y0, y1) for z in (z0, z1)]
	for q in ((0, 1, 3, 2), (4, 6, 7, 5), (0, 4, 5, 1), (2, 3, 7, 6), (0, 2, 6, 4), (1, 5, 7, 3)):
		add_face([c[i] for i in q], mat)


wood_back = BACK_Y - OVERHANG
top_z = HEIGHT - TOP

# Steinplatte mit Fase oben außen
sweep([(inner_top(), top_z), (outer(0, BACK_Y), top_z), (outer(0, BACK_Y), HEIGHT - CHAMFER),
		(outer(CHAMFER, BACK_Y), HEIGHT), (inner_top(), HEIGHT)], "stone")

# Holzwange (U), außen RADIUS, innen RADIUS - THICK
w_out, w_in = outer(OVERHANG, wood_back), outer(OVERHANG + THICK, wood_back)
sweep([(w_in, PLINTH), (w_out, PLINTH), (w_out, top_z), (w_in, top_z)], "wood")

# Endkappen hinten an den Armen: von der Wange bis knapp unter die Innenkante der Platte
cap_inner = -WIDTH / 2.0 + ARM - 0.05
for side in (-1, 1):
	x0, x1 = sorted((side * (-WIDTH / 2.0 + OVERHANG + THICK), side * cap_inner))
	box(x0, wood_back - THICK, PLINTH, x1, wood_back, top_z, "wood")

# Sockel, zurückgesetzt, mit eigenen Endkappen
p_back = wood_back - INSET
p_out, p_in = outer(OVERHANG + INSET, p_back), outer(OVERHANG + INSET + THICK, p_back)
sweep([(p_in, 0.0), (p_out, 0.0), (p_out, PLINTH), (p_in, PLINTH)], "plinth")
for side in (-1, 1):
	x0, x1 = sorted((side * (-WIDTH / 2.0 + OVERHANG + INSET + THICK), side * (cap_inner - INSET)))
	box(x0, p_back - THICK, 0.0, x1, p_back, PLINTH, "plinth")

# Ablage: reicht 1 cm in die Wange, vorn rund wie deren Innenseite
shelf_back = FRONT_Y + OVERHANG + SHELF_DEPTH
shelf = outer(OVERHANG + THICK - 0.01, shelf_back)
lo = [bm.verts.new((p.x, p.y, SHELF_Z - SHELF_T)) for p in shelf]
hi = [bm.verts.new((p.x, p.y, SHELF_Z)) for p in shelf]
add_face(hi, "wood")
add_face(list(reversed(lo)), "wood")
for s in range(len(shelf)):
	t = (s + 1) % len(shelf)
	add_face([lo[s], lo[t], hi[t], hi[s]], "wood")

# Goldrohre: Kreisquerschnitt entlang der Holzflucht, hinten bündig mit dem Korpus, flach geschlossen
rail_d = OVERHANG - RAIL_STANDOFF - RAIL_RADIUS   # Rohrmitte als Versatz der Außenkontur
ro = RADIUS + OVERHANG
cx, cy = WIDTH / 2.0 - ro, FRONT_Y + ro           # Mitte des rechten Bogens
spots = []                                        # Halter: (Punkt auf dem Holz, Richtung nach außen)
for side in (-1, 1):
	for y in (wood_back - 0.15, cy + (wood_back - cy) * 0.4):
		spots.append((Vector((side * (WIDTH / 2.0 - OVERHANG), y)), Vector((side, 0))))
	n = Vector((side, -1)).normalized()
	spots.append((Vector((side * cx, cy)) + n * RADIUS, n))
for x in (-cx * 0.5, 0.0, cx * 0.5):
	spots.append((Vector((x, FRONT_Y + OVERHANG)), Vector((0, -1))))
bracket = RAIL_STANDOFF + RAIL_RADIUS + 0.01      # 1 cm im Holz bis zur Rohrmitte
for zc in (RAIL_GAP + RAIL_RADIUS, top_z - RAIL_GAP - RAIL_RADIUS):
	rings = []
	for k in range(RAIL_SIDES):
		a = 2.0 * math.pi * k / RAIL_SIDES
		rings.append((outer(rail_d - RAIL_RADIUS * math.cos(a), wood_back), zc + RAIL_RADIUS * math.sin(a)))
	sweep(rings, "gold")
	for at, n in spots:
		mid = at + n * (bracket / 2.0 - 0.01)
		rot = Vector((0, 0, 1)).rotation_difference(Vector((n.x, n.y, 0))).to_matrix().to_4x4()
		res = bmesh.ops.create_cone(bm, cap_ends=True, segments=8, radius1=BRACKET_RADIUS, radius2=BRACKET_RADIUS,
				depth=bracket, matrix=Matrix.Translation((mid.x, mid.y, zc)) @ rot)
		for f in {f for v in res["verts"] for f in v.link_faces}:
			f.material_index = MAT_INDEX["gold"]

# Teile sind je für sich geschlossen; glatt nur über flache Knicke (Bögen, Rohre)
bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
for f in bm.faces:
	f.smooth = True
for e in bm.edges:
	e.smooth = not (len(e.link_faces) == 2 and e.calc_face_angle(0.0) > math.radians(30))

me = bpy.data.meshes.new("reception")
bm.to_mesh(me)
bm.free()
for name in ("wood", "stone", "plinth", "gold"):
	me.materials.append(bpy.data.materials[name])
obj = bpy.data.objects.new("reception", me)
bpy.context.scene.collection.objects.link(obj)
bpy.ops.export_scene.gltf(filepath=DST, export_format='GLB', export_yup=True)
print("Rezeption: %d Ecken, %d Flächen → %s" % (len(me.vertices), len(me.polygons), DST))
