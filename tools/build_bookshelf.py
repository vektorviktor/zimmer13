# Baut die Bücherregale der Bibliothek (Bookshelf, ZIM-152) im Look der Kommode (tools/build_dresser.py): Holz der
# Vertäfelung, Sockel mit Fase und Viertelstab, Pfosten mit Furchen, Rundstab, Fries mit stehenden Mulden, Kranz aus
# Hohlkehle und Deckplatte. Offene Fächer, LEVELS Ebenen übereinander (4 oder 5), Fachböden im Raster PITCH.
#
# Ein Regal hat im Spiel beliebige Länge: Bookshelf setzt es aus Teilen zusammen, die hier einmal je Höhe gebaut und
# gemeinsam gebacken werden. Alle Teile haben dasselbe Profil vorn, die waagerechten Flächen (Sockel, Rundstab, Fries,
# Kranz, Deckel, Rückwand, Fachböden) tragen die Holz-UV ohne Versatz in Metern entlang x – im Spiel laufen sie über
# INSTANCE_CUSTOM (psx_photo, instance_shift) über die ganze Zeile durch, auch wo ein Fach gestreckt wird.
#
# Lage (Godot-Achsen): Boden y = 0, Vorderseite nach +Z, Korpus z = ±DEPTH/2, x entlang der Zeile. Objekte:
#   „end_l“, „end_r“     Seite am freien Ende: Pfosten mit Furchen, Profil läuft um die Ecke; Ursprung auf der Kante des
#                        Korpus, end_l reicht nach +x (bis POST), end_r nach −x
#   „span1“, „span2“     ein Fach von x = 0 bis SPANS[…] (1 m bzw. 2 m Raster minus Zwischenwand): Profil vorn, Deckel,
#                        Rückwand, Boden, Decke und LEVELS − 1 Fachböden – im Spiel in x auf die echte Breite gestreckt
#   „divider“            Zwischenwand, mittig um x = 0, DIVIDER breit, vorn ein Pfosten mit drei Furchen
#   „miter_l“, „miter_r“ Ende an einer Innenecke: x = 0 ist die Vorderseite des anderen Regals, das Profil endet auf der
#                        Gehrung (45°), Deckel und Rückwand reichen bis an die Wand dahinter (x = ∓DEPTH)
# Gebacken wird eine Zeile (end_l, span1, divider, span2, end_r) und eine Ecke (miter_l, span1, miter_r, dazu die
# Gegenstücke über Eck als Schattenwerfer).
#
# Aufruf aus dem Projektordner (Blender 4.3), je Höhe:
#   blender -b --python tools/build_bookshelf.py -- 4 assets/models/bookshelf_4.glb assets/textures/bookshelf_4
#   blender -b --python tools/build_bookshelf.py -- 5 assets/models/bookshelf_5.glb assets/textures/bookshelf_5
#   (schreibt das Modell sowie <tex>_ao.png und <tex>_normal.png)
import bpy, sys, os, math, random
import numpy as np

sys.path.append(os.path.dirname(os.path.abspath(__file__)))
from mathutils import Vector
from furniture_kit import B, G, arc, Part, setup_cycles, new_image, bake_material, bake, godot_normals, \
	save_image, paint_details, capsules

argv = sys.argv[sys.argv.index("--") + 1:]
LEVELS = int(argv[0])
DST = os.path.abspath(argv[1])
TEX = os.path.abspath(argv[2])

# --- Maße (Meter) = Bookshelf ------------------------------------------------------------------------------------
DEPTH = 0.30              # Korpus ohne Profil
POST = 0.09               # Seite am Ende (massiv, vorn Pfosten wie an der Kommode)
DIVIDER = 0.06            # Zwischenwand (massiv)
SPANS = {"span1": 1.0 - DIVIDER, "span2": 2.0 - DIVIDER}
PLINTH = 0.10
CROWN = 0.161             # Rundstab, Fries und Kranz über dem obersten Fach
# Raster der Fachböden: mit 4 Ebenen ist das Regal 2,10 m hoch (Wunsch des Nutzers 1.11.), mit 5 Ebenen 2,56 m
PITCH = (2.10 - PLINTH - CROWN) / 4
SHELF_T = 0.022
SHELF_SET = 0.015         # Vorderkante der Fachböden hinter der Vorderseite
BACK_WALL = 0.012
OPEN = (PLINTH, PLINTH + LEVELS * PITCH)
FRIEZE = (OPEN[1] + 0.026, OPEN[1] + 0.096)
TOP = FRIEZE[1] + 0.065
assert abs(TOP - OPEN[1] - CROWN) < 1e-9
FLUTE_W = 0.010
FLUTE_GAP = 0.008
FLUTE_DEPTH = 0.004
FLUTE_END = 0.06
DIV_FLUTE_W = 0.008       # drei schmalere Furchen in der Zwischenwand
DIV_FLUTE_GAP = 0.007
NICHE_W = 0.010
NICHE_H = 0.045
NICHE_DEPTH = 0.003
NICHE_PITCH = 0.031       # wie an der Kommode
NICHE_END = 0.02          # Abstand der äußersten Mulde vom Rand eines Teils
NICHE_CORNER = 0.03       # erste Mulde neben einer Ecke

ATLAS = 2048
AO_DISTANCE = 0.06
AO_STRENGTH = 0.9
AO_SAMPLES = 128
## Eigene Abwicklung im Atlas (atlas): Gruppe → (Faktor entlang, Faktor quer) gegenüber der übrigen Holzfläche.
## Leisten (5 vorn, 6 seitlich): entlang der Zeile bzw. Tiefe und Bogenlänge im Profil; Pfosten (1) und Fries (4): eben,
## quer zur Furche bzw. Mulde fein, entlang gröber – sonst geben die langen Streifen das Format des Atlas vor.
STRIPS = {1: (3.0, 0.8), 4: (1.2, 2.5), 5: (0.6, 4.0), 6: (0.6, 4.0)}

ZF, ZB = DEPTH / 2.0, -DEPTH / 2.0
ZI = ZB + BACK_WALL

bpy.ops.wm.read_factory_settings(use_empty=True)
random.seed(152 + LEVELS)

# Profil wie an der Kommode, Fries höher (7 cm): Sockel, Korpus, Rundstab, Fries, Hohlkehle, Plättchen, Deckplatte
F1 = FRIEZE[1]
PROFILE = [(0.02, 0.0), (0.02, 0.072), (0.017, 0.075), (0.010, 0.075), (0.010, 0.09)] + arc(0.0, 0.09, 0.01, 0, 90, 4) \
	+ [(0.0, OPEN[1])] + arc(0.0, OPEN[1] + 0.013, 0.013, -90, 90, 8) \
	+ [(0.0, F1)] + arc(0.02, F1, 0.02, 180, 90, 4) + [(0.026, F1 + 0.02)] \
	+ arc(0.026, F1 + 0.032, 0.012, -90, 0, 3) + [(0.038, F1 + 0.053)] + arc(0.026, F1 + 0.053, 0.012, 0, 90, 3)
PROFILE = [(round(o, 6), round(y, 6)) for o, y in PROFILE]
assert abs(PROFILE[-1][1] - TOP) < 1e-6
O_TOP = PROFILE[-1][0]


def kind_of(y0, y1):
	if y1 <= OPEN[0] + 1e-6:
		return "plinth"
	if y0 >= OPEN[0] - 1e-6 and y1 <= OPEN[1] + 1e-6:
		return "body"
	if y0 >= FRIEZE[0] - 1e-6 and y1 <= FRIEZE[1] + 1e-6:
		return "frieze"
	return "bead" if y1 <= FRIEZE[0] + 1e-6 else "cornice"


## Abschnitte des Profils: (Vorsprung, Höhe) unten und oben, Art, Normale nach außen als (Vorsprung, Höhe)
def segments():
	for (oa, ya), (ob, yb) in zip(PROFILE, PROFILE[1:]):
		t = (ob - oa, yb - ya)
		ln = math.hypot(*t)
		yield oa, ya, ob, yb, kind_of(ya, yb), (t[1] / ln, -t[0] / ln)


## Fläche, deren Holz über die Zeile durchläuft (UV ohne Versatz, Faser entlang x)
def run_face(part, pts, normal, piece, group=0):
	part.offsets.setdefault(piece, (0.0, 0.0))
	part.face(pts, normal, piece, "x", group)


## Bogenlänge entlang des Profils je Punkt (Vorsprung, Höhe) – für die Abwicklung der Leisten (profile_uv)
ARC = [0.0]
for _a, _b in zip(PROFILE, PROFILE[1:]):
	ARC.append(ARC[-1] + math.hypot(_b[0] - _a[0], _b[1] - _a[1]))


def arc_at(o, y):
	i = min(range(len(PROFILE)), key=lambda k: (PROFILE[k][0] - o) ** 2 + (PROFILE[k][1] - y) ** 2)
	assert abs(PROFILE[i][0] - o) + abs(PROFILE[i][1] - y) < 1e-4, (o, y)
	return ARC[i]


# --- Teile -------------------------------------------------------------------------------------------------------
## Vorn das Profil zwischen left(o) und right(o) (x je Vorsprung), im Korpus der Pfosten (post) oder offen; hinten
## die Rückwand zwischen back_l(o) und back_r(o); oben der Deckel als Umriss top.
def shell(part, left, right, back_l, back_r, top, post):
	for oa, ya, ob, yb, kind, (no, ny) in segments():
		if kind == "body":
			if post:
				part.face([(left(0), ya, ZF), (right(0), ya, ZF), (right(0), yb, ZF), (left(0), yb, ZF)], (0, 0, 1),
					("post",), "y", 1)
		else:
			run_face(part, [(left(oa), ya, ZF + oa), (right(oa), ya, ZF + oa), (right(ob), yb, ZF + ob),
				(left(ob), yb, ZF + ob)], (0, ny, no), ("run", kind), 4 if kind == "frieze" else 5)
		if yb - ya > 1e-6:
			run_face(part, [(back_l(oa), ya, ZB), (back_r(oa), ya, ZB), (back_r(ob), yb, ZB), (back_l(ob), yb, ZB)],
				(0, 0, -1), ("run", "back"), 9)
	run_face(part, [(x, TOP, z) for x, z in top], (0, 1, 0), ("run", "top"))


## Profil um die Ecke am freien Ende: Seitenfläche bei x = s · o (s = −1 links, +1 rechts)
def side(part, s):
	for oa, ya, ob, yb, kind, (no, ny) in segments():
		body = kind == "body"
		part.face([(s * oa, ya, ZF + oa), (s * oa, ya, ZB), (s * ob, yb, ZB), (s * ob, yb, ZF + ob)], (s * no, ny, 0),
			("side", kind), "y" if body else "z", 0 if body else (4 if kind == "frieze" else 6))


## Innenseite einer Wand bei x, Normale nach s (ins Fach)
def inner_wall(part, x, s, piece):
	part.face([(x, OPEN[0], ZI), (x, OPEN[0], ZF), (x, OPEN[1], ZF), (x, OPEN[1], ZI)], (s, 0, 0), piece, "y", 8)


def build_end(name, s):
	"""Freies Ende: s = −1 links (end_l, reicht nach +x), +1 rechts (end_r, nach −x)."""
	p = Part(name)
	inner = -s * POST
	if s < 0:
		shell(p, lambda o: -o, lambda o: POST, lambda o: -o, lambda o: POST,
			[(-O_TOP, ZB), (POST, ZB), (POST, ZF + O_TOP), (-O_TOP, ZF + O_TOP)], True)
	else:
		shell(p, lambda o: -POST, lambda o: o, lambda o: -POST, lambda o: o,
			[(-POST, ZB), (O_TOP, ZB), (O_TOP, ZF + O_TOP), (-POST, ZF + O_TOP)], True)
	side(p, s)
	inner_wall(p, inner, -s, ("in", "side"))
	return p.finish()


def build_miter(name, s):
	"""Ende an der Innenecke: s = −1 links (miter_l), +1 rechts (miter_r). x = 0 = Vorderseite des anderen Regals,
	die Gehrung liegt bei x = −s · o; Deckel und Rückwand reichen bis an dessen Rückseite (x = s · DEPTH)."""
	p = Part(name)
	if s < 0:
		shell(p, lambda o: o, lambda o: POST, lambda o: -DEPTH, lambda o: POST,
			[(-DEPTH, ZB), (POST, ZB), (POST, ZF + O_TOP), (O_TOP, ZF + O_TOP)], True)
	else:
		shell(p, lambda o: -POST, lambda o: -o, lambda o: -POST, lambda o: DEPTH,
			[(-POST, ZB), (DEPTH, ZB), (-O_TOP, ZF + O_TOP), (-POST, ZF + O_TOP)], True)
	inner_wall(p, -s * POST, -s, ("in", "side"))
	return p.finish()


def build_divider(name):
	p = Part(name)
	h = DIVIDER / 2.0
	shell(p, lambda o: -h, lambda o: h, lambda o: -h, lambda o: h, [(-h, ZB), (h, ZB), (h, ZF + O_TOP), (-h, ZF + O_TOP)],
		True)
	for s in (-1, 1):
		inner_wall(p, s * h, s, ("in", s))
	return p.finish()


def build_span(name, width):
	p = Part(name)
	shell(p, lambda o: 0.0, lambda o: width, lambda o: 0.0, lambda o: width,
		[(0, ZB), (width, ZB), (width, ZF + O_TOP), (0, ZF + O_TOP)], False)
	y0, y1 = OPEN
	run_face(p, [(0, y0, ZI), (width, y0, ZI), (width, y1, ZI), (0, y1, ZI)], (0, 0, 1), ("run", "in_back"), 8)
	run_face(p, [(0, y0, ZI), (width, y0, ZI), (width, y0, ZF), (0, y0, ZF)], (0, 1, 0), ("run", "floor"), 8)
	run_face(p, [(0, y1, ZI), (width, y1, ZI), (width, y1, ZF), (0, y1, ZF)], (0, -1, 0), ("run", "ceiling"), 8)
	zs = ZF - SHELF_SET
	for k in range(1, LEVELS):
		yt = y0 + k * PITCH
		yb = yt - SHELF_T
		piece = ("run", "shelf", k)
		run_face(p, [(0, yt, ZI), (width, yt, ZI), (width, yt, zs), (0, yt, zs)], (0, 1, 0), piece, 8)
		run_face(p, [(0, yb, ZI), (width, yb, ZI), (width, yb, zs), (0, yb, zs)], (0, -1, 0), piece, 8)
		run_face(p, [(0, yb, zs), (width, yb, zs), (width, yt, zs), (0, yt, zs)], (0, 0, 1), piece)
	return p.finish()


# --- Gemalte Formen ----------------------------------------------------------------------------------------------
## Furchen (Gruppe 1) in einem Pfosten von x0 bis x0 + w
def flutes_at(x0, w, count, fw, gap):
	r = fw / 2.0
	margin = (w - count * fw - (count - 1) * gap) / 2.0
	centers = [margin + r + k * (fw + gap) for k in range(count)]

	def paint(pts, n, px):
		gs, gy, shade, mask = capsules(pts[:, 0] - x0, pts[:, 1], centers, OPEN[0] + FLUTE_END + r,
			OPEN[1] - FLUTE_END - r, r, FLUTE_DEPTH, px)
		normals = np.stack([-gs, -gy, np.ones(len(pts))], axis=1)
		normals /= np.linalg.norm(normals, axis=1, keepdims=True)
		return normals, shade, mask

	return paint


## Mulden im Fries (Gruppe 4): vorn bei x = front, an der Seite bei z = sides
def niches_at(front, sides=()):
	r = NICHE_W / 2.0
	mid = (FRIEZE[0] + FRIEZE[1]) / 2.0
	y0, y1 = mid - NICHE_H / 2.0 + r, mid + NICHE_H / 2.0 - r

	def paint(pts, n, px):
		if abs(n[2]) > 0.5:
			axis, centers = np.array([1.0, 0, 0]), front
		else:
			axis, centers = np.array([0, 0, 1.0]), sides
		if not centers:
			return None, None, np.zeros(len(pts))
		gs, gy, shade, mask = capsules(pts @ axis, pts[:, 1], centers, y0, y1, r, NICHE_DEPTH, px)
		normals = n[None, :] - gs[:, None] * axis[None, :] - gy[:, None] * np.array([0, 1.0, 0])[None, :]
		normals /= np.linalg.norm(normals, axis=1, keepdims=True)
		return normals, shade, mask

	return paint


## Raster von a nach b (Schritt NICHE_PITCH, ab a), solange vor b
def raster(a, b):
	out = []
	step = NICHE_PITCH if b > a else -NICHE_PITCH
	x = a
	while (x <= b + 1e-9) if step > 0 else (x >= b - 1e-9):
		out.append(x)
		x += step
	return out


def centred(width):
	k = int((width / 2.0 - NICHE_END) / NICHE_PITCH)
	return [width / 2.0 + i * NICHE_PITCH for i in range(-k, k + 1)]


SIDE_NICHES = raster(ZF - NICHE_CORNER, ZB + NICHE_CORNER)
PAINTERS = {
	"end_l": {1: flutes_at(0.0, POST, 4, FLUTE_W, FLUTE_GAP),
		4: niches_at(raster(NICHE_CORNER, POST - NICHE_END), SIDE_NICHES)},
	"end_r": {1: flutes_at(-POST, POST, 4, FLUTE_W, FLUTE_GAP),
		4: niches_at(raster(-NICHE_CORNER, -POST + NICHE_END), SIDE_NICHES)},
	"miter_l": {1: flutes_at(0.0, POST, 4, FLUTE_W, FLUTE_GAP), 4: niches_at(raster(NICHE_CORNER, POST - NICHE_END))},
	"miter_r": {1: flutes_at(-POST, POST, 4, FLUTE_W, FLUTE_GAP), 4: niches_at(raster(-NICHE_CORNER, -POST + NICHE_END))},
	"divider": {1: flutes_at(-DIVIDER / 2.0, DIVIDER, 3, DIV_FLUTE_W, DIV_FLUTE_GAP), 4: niches_at([0.0])},
	"span1": {4: niches_at(centred(SPANS["span1"]))},
	"span2": {4: niches_at(centred(SPANS["span2"]))},
}


# --- Bauen und zum Backen aufstellen -----------------------------------------------------------------------------
parts = {
	"end_l": build_end("end_l", -1), "end_r": build_end("end_r", 1),
	"span1": build_span("span1", SPANS["span1"]), "span2": build_span("span2", SPANS["span2"]),
	"divider": build_divider("divider"),
	"miter_l": build_miter("miter_l", -1), "miter_r": build_miter("miter_r", 1),
}
wood = list(parts.values())


## Atlas wie furniture_kit.atlas_uv, aber die Leisten (Sockel, Rundstab, Hohlkehle, Kranz – vorn Gruppe 5, an der Seite
## Gruppe 6) bekommen eine eigene Abwicklung: entlang der Zeile (bzw. Tiefe) PROFILE_U, quer die Bogenlänge im Profil
## × PROFILE_V. Die automatische Abwicklung zerlegte die millimeterschmalen Flächen in Streifen von 1–4 Pixeln, jedes
## Teil anders – gebackene Normale und Verschattung brachen dann an jedem Stoß (Zwischenwand, Seite, Gehrung).
def atlas(obs, margin, scales):
	bpy.ops.object.select_all(action='DESELECT')
	for ob in obs:
		ob.data.uv_layers.new(name="atlas")
		ob.data.uv_layers.active = ob.data.uv_layers["atlas"]
		ob.select_set(True)
	bpy.context.view_layer.objects.active = obs[0]
	bpy.ops.object.mode_set(mode='EDIT')
	bpy.ops.mesh.select_all(action='SELECT')
	bpy.ops.uv.smart_project(angle_limit=math.radians(50), island_margin=margin, area_weight=0.0, scale_to_bounds=False)
	bpy.ops.object.mode_set(mode='OBJECT')
	# Maßstab der automatischen Abwicklung: UV-Länge je Meter (Median über die gewöhnlichen Flächen)
	ratios = []
	for ob in obs:
		me = ob.data
		uvs = me.uv_layers["atlas"].data
		for p in me.polygons:
			idx = list(p.loop_indices)
			a, b = idx[0], idx[1]
			d3 = (me.vertices[me.loops[a].vertex_index].co - me.vertices[me.loops[b].vertex_index].co).length
			if d3 > 0.02:
				ratios.append((Vector(uvs[a].uv) - Vector(uvs[b].uv)).length / d3)
	unit = float(np.median(ratios))
	for ob in obs:
		me = ob.data
		groups = me.attributes["group"].data
		uvs = me.uv_layers["atlas"].data
		for p in me.polygons:
			g = groups[p.index].value
			idx = list(p.loop_indices)
			if g in STRIPS:
				fu, fv = STRIPS[g]
				front = abs(p.normal.y) > 0.5 or g == 5   # Blender −y = Godot +z
				for i in idx:
					q = G(me.vertices[me.loops[i].vertex_index].co)
					along = q.x if front else q.z
					if g in (5, 6):
						across = arc_at(q.z - ZF if g == 5 else abs(q.x), q.y)
					else:
						across = q.y
					uvs[i].uv = (along * fu * unit, across * fv * unit)
			elif g in scales:
				c = sum((Vector(uvs[i].uv) for i in idx), Vector((0, 0))) / len(idx)
				for i in idx:
					uvs[i].uv = c + (Vector(uvs[i].uv) - c) * scales[g]
	bpy.context.scene.tool_settings.use_uv_select_sync = True
	bpy.ops.object.mode_set(mode='EDIT')
	bpy.ops.mesh.select_all(action='SELECT')
	bpy.ops.uv.pack_islands(rotate=True, rotate_method='CARDINAL', margin=margin)
	bpy.ops.object.mode_set(mode='OBJECT')
	for ob in obs:
		ob.data.uv_layers["atlas"].active_render = True


atlas(wood, 0.004, {8: 0.4, 9: 0.15})


def place(ob, x, z, yaw=0.0):
	ob.location = B(x, 0, z)
	ob.rotation_euler = (0, 0, yaw)


def caster(src, x, z, yaw=0.0):
	ob = bpy.data.objects.new(src.name + "_caster", src.data)
	bpy.context.scene.collection.objects.link(ob)
	place(ob, x, z, yaw)
	return ob


C1, C2 = SPANS["span1"], SPANS["span2"]
# Zeile: end_l | span1 | divider | span2 | end_r
place(parts["end_l"], 0.0, 0.0)
place(parts["span1"], POST, 0.0)
place(parts["divider"], POST + C1 + DIVIDER / 2.0, 0.0)
place(parts["span2"], POST + C1 + DIVIDER, 0.0)
place(parts["end_r"], POST + C1 + DIVIDER + C2 + POST, 0.0)
# Ecke, 3 m davor: miter_l | span1 | miter_r, dazu je das Gegenstück über Eck (Schattenwerfer)
ZC = -3.0
XR = POST + C1 + POST
others = [caster(parts["span1"], POST, ZC),
	caster(parts["miter_r"], -DEPTH / 2.0, ZC + ZF, math.pi / 2.0),
	caster(parts["miter_l"], XR + DEPTH / 2.0, ZC + ZF, -math.pi / 2.0)]
place(parts["miter_l"], 0.0, ZC)
place(parts["miter_r"], XR, ZC)


# --- Backen ------------------------------------------------------------------------------------------------------
sc = setup_cycles()
for ob in wood:
	ob.data.materials.append(bake_material("wood_src"))

sc.world.light_settings.distance = AO_DISTANCE
ao = bake(wood, 'AO', new_image("bookshelf_ao", ATLAS, False, True), AO_SAMPLES)[..., 0]
print("AO: Mittel %.3f, dunkelster Wert %.3f" % (ao.mean(), ao.min()))
ao = 1.0 - AO_STRENGTH * (1.0 - np.clip(ao, 0, 1))
nrm = godot_normals(bake(wood, 'NORMAL', new_image("bookshelf_nrm", ATLAS, False, True), 1, normal_space='OBJECT'))
for name, ob in parts.items():
	paint_details([ob], nrm, ao, PAINTERS[name])
save_image("bookshelf_ao_out", ao, TEX + "_ao.png")
save_image("bookshelf_normal_out", nrm * 0.5 + 0.5, TEX + "_normal.png")


# --- Export ------------------------------------------------------------------------------------------------------
for ob in others:
	bpy.data.objects.remove(ob)
for ob in wood:
	place(ob, 0.0, 0.0)
	ob.data.materials.clear()   # Holz setzt Bookshelf (Mat.hotel_wood mit AO, Normale und instance_shift)
	if "group" in ob.data.attributes:
		ob.data.attributes.remove(ob.data.attributes["group"])
	tris = sum(len(p.vertices) - 2 for p in ob.data.polygons)
	print("%-8s %5d Dreiecke, UV-Sätze %s" % (ob.name, tris, [l.name for l in ob.data.uv_layers]))

bpy.ops.object.select_all(action='DESELECT')
for ob in wood:
	ob.select_set(True)
bpy.ops.export_scene.gltf(
	filepath=DST, export_format='GLB', export_yup=True, export_apply=False, use_selection=True,
	export_texcoords=True, export_normals=True, export_tangents=False, export_materials='NONE',
	export_skins=False, export_animations=False, export_morph=False, export_cameras=False, export_lights=False)
print("geschrieben:", DST, TEX + "_ao.png", TEX + "_normal.png")
