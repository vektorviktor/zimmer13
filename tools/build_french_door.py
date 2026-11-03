# Baut die Fenstertür nach draußen (ZIM-126, Entscheidung 3.11.: selbst gebaut, Door.Look, Spielkonzept 9.2) – ein
# Modell in drei Varianten, alle als Flügel einer Doppeltür:
#   „garden“    Garten-, Terrassen- und Balkontüren: Rahmen mit Sockel, darin 2 × 5 Glasfelder zwischen Sprossen
#   „glazed“    Doppel-Glastür im Haus (Lobby, Bar …): wie „garden“, ohne Wetterschenkel
#   „entrance“  Haupteingang: unten eine Kassette wie an der Zimmertür, darüber Kämpfer und 3 × 4 Glasfelder
# Glas wegen des Lakengeists (Spielkonzept 4.18), Holz wie Zimmertür, Vertäfelung und Türrahmen (Mat.hotel_wood).
#
# Kein Ausgangsmodell: Die Blattfläche ist ein Raster aus Friesen, Sprossen und Feldern wie in build_room_door.py.
# Glasfelder haben auf beiden Seiten eine 45°-Fase zur Laibung, die Laibung geht durch bis zur Scheibe in der
# Mittelebene; Sprossen laufen in voller Blattdicke, an den Kreuzungen treffen sich die Fasen auf Gehrung (wie beim
# Schreiner). Die Kassette des Haupteingangs hat das Profil der Zimmertür. Außen (−Z, gegenüber der Aufgehseite) sitzt
# unten ein Wetterschenkel (nicht an der Glastür im Haus). Low Poly (Blatt ≈ 500–700 Dreiecke).
#
# Wie die Zimmertür: Das Blatt trägt kein Material, sondern zwei UV-Sätze – UVMap in Metern für das Holzfoto (Faser je
# Stück: Seitenfriese und senkrechte Sprossen senkrecht, Riegel, Querstreben und Wetterschenkel waagerecht, die
# Kassette senkrecht, jedes Stück mit eigenem Versatz) und „atlas“ für die in Cycles gebackene Verschattung (ein Bild
# für beide Varianten, im Spiel mit der Grundfarbe multipliziert). Die Scheiben sind eigene Objekte ohne Material
# (Door setzt Mat.glass wie an den Fenstern).
#
# Lage (Godot-Achsen, wie Door): Blatt in der XY-Ebene, Scharnierkante bei x = 0, Blatt nach +X, Unterkante y = 0,
# Mitte der Blattdicke bei z = 0, die Tür geht nach +Z auf (innen). Objekte je Variante:
#   „leaf_<v>“   Blatt, LEAF groß – Door streckt es auf die Blattgröße
#   „glass_<v>“  die Scheiben in der Mittelebene
# Drücker und Bänder setzt Door aus dem Modell der Zimmertür.
#
# Aufruf aus dem Projektordner (Blender 4.3):
#   blender -b --python tools/build_french_door.py -- assets/models/door_french.glb assets/textures/door_french_ao.png
import bpy, bmesh, sys, os, math, random
import numpy as np
from mathutils import Vector

argv = sys.argv[sys.argv.index("--") + 1:]
DST = os.path.abspath(argv[0])
AO_DST = os.path.abspath(argv[1])

THICK = 0.06
BAR = 0.044               # Sprossen
GLASS_BEVEL = 0.012       # Fase zu den Scheiben (45°)
PANEL = [(0.0, 0.0), (0.021, -0.021)]   # Kassette: Profil wie an der Zimmertür
GRAIN_SHIFT = 2.0
# Wetterschenkel außen: Querschnitt (y, z) ab der Blattfläche bei z = −THICK/2, Unterseite mit Tropfkante
WEATHER = [(0.022, 0.0), (0.022, -0.036), (0.03, -0.04), (0.05, -0.04), (0.115, 0.0)]
WEATHER_INSET = 0.004     # an den Blattkanten so weit zurück

AO_DISTANCE = 0.06
AO_SIZE = 2048
AO_STRENGTH = 0.9
SHARP = math.radians(35)


def lines(start, cells, end):
	"""Rasterlinien: cells = [(Typ, Länge)] ab start; gibt (Linien, Typen) zurück."""
	xs, kinds = [start], []
	for kind, length in cells:
		xs.append(xs[-1] + length)
		kinds.append(kind)
	assert abs(xs[-1] - end) < 1e-6, (xs[-1], end)
	return xs, kinds


def glazed(count, span):
	"""count Glasfelder mit Sprossen dazwischen über span: [G, B, G, …]"""
	g = (span - (count - 1) * BAR) / count
	out = []
	for k in range(count):
		out += [("G", g)] + ([("B", BAR)] if k < count - 1 else [])
	return out


# Typen: Spalten S Seitenfries, G Glasfeld, M senkrechte Sprosse; Zeilen R Riegel, G Glasfeld, B Querstrebe, P Kassette
VARIANTS = {}
_w, _h = 1.08, 2.38       # 2,2-m-Gartentür: halbe Breite und 2,4 m Höhe abzüglich Luft (Door.GARDEN_LEAF)
VARIANTS["garden"] = {
	"leaf": (_w, _h),
	"cols": lines(0.0, [("S", 0.11)] + [(k if k == "G" else "M", l) for k, l in glazed(2, _w - 0.22)] + [("S", 0.11)], _w),
	"rows": lines(0.0, [("R", 0.22)] + glazed(5, _h - 0.33) + [("R", 0.11)], _h),
}
VARIANTS["glazed"] = dict(VARIANTS["garden"], weather=False)   # gleiche Größe (Door.GARDEN_LEAF)
_w, _h = 1.48, 2.78       # 3-m-Haupteingang, 2,8 m hoch (Door.ENTRANCE_LEAF)
VARIANTS["entrance"] = {
	"leaf": (_w, _h),
	"cols": lines(0.0, [("S", 0.14)] + [(k if k == "G" else "M", l) for k, l in glazed(3, _w - 0.28)] + [("S", 0.14)], _w),
	"rows": lines(0.0, [("R", 0.26), ("P", 0.66), ("R", 0.20)] + glazed(4, _h - 1.12 - 0.14) + [("R", 0.14)], _h),
}

bpy.ops.wm.read_factory_settings(use_empty=True)
random.seed(126)


## Godot (x, y, z) → Blender (x, −z, y); der glTF-Export dreht wieder zurück.
def B(x, y, z):
	return Vector((x, -z, y))


def G(v):
	return Vector((v.x, v.z, -v.y))


def finish(bm, name):
	bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=1e-6)
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


def build_leaf(v, spec):
	xs, ck = spec["cols"]
	ys, rk = spec["rows"]
	lw = spec["leaf"][0]
	bm = bmesh.new()
	grain = bm.loops.layers.uv.new("UVMap")   # Meter, für das Holzfoto
	offsets = {}

	def uv(f, piece, vertical):
		if piece not in offsets:
			offsets[piece] = (random.random() * GRAIN_SHIFT, random.random() * GRAIN_SHIFT)
		ou, ov = offsets[piece]
		for loop in f.loops:
			p = G(loop.vert.co)
			u, w = (p.y, p.x + p.z) if vertical else (p.x, p.y + p.z)
			loop[grain].uv = (u + ou, w + ov)

	def face(vs, side, piece, vertical):
		f = bm.faces.new(vs if side > 0 else list(reversed(vs)))
		uv(f, piece, vertical)

	## Stück der Rasterzelle (i, j): Seitenfriese laufen durch, senkrechte Sprossen durch die Querstreben
	def piece(i, j):
		if ck[i] == "S":
			return ("stile", i), True
		if ck[i] == "M" and rk[j] in "GB":
			return ("muntin", i), True
		if rk[j] == "B":
			return ("bar", j, i), False
		return ("rail", j), False

	# Felder: jedes Glasfeld für sich, die Kassette über alle Spalten zwischen den Seitenfriesen
	regions = []
	for j, r in enumerate(rk):
		if r == "G":
			regions += [("glass", i, i + 1, j, j + 1) for i, c in enumerate(ck) if c == "G"]
		elif r == "P":
			inner = [i for i, c in enumerate(ck) if c != "S"]
			regions.append(("panel", inner[0], inner[-1] + 1, j, j + 1))
	covered = {(i, j) for _, i0, i1, j0, j1 in regions for i in range(i0, i1) for j in range(j0, j1)}

	panes = []
	grids = {}
	for side in (1, -1):
		zf = side * THICK / 2.0
		grid = [[bm.verts.new(B(x, y, zf)) for y in ys] for x in xs]
		grids[side] = grid
		for i in range(len(xs) - 1):
			for j in range(len(ys) - 1):
				if (i, j) not in covered:
					face([grid[i][j], grid[i + 1][j], grid[i + 1][j + 1], grid[i][j + 1]], side, *piece(i, j))
		for kind, i0, i1, j0, j1 in regions:
			x0, x1, y0, y1 = xs[i0], xs[i1], ys[j0], ys[j1]
			# Umriss des Felds auf der Blattfläche: alle Rasterpunkte je Seite (unten, rechts, oben, links)
			edges = [[grid[i][j0] for i in range(i0, i1 + 1)], [grid[i1][j] for j in range(j0, j1 + 1)],
				[grid[i][j1] for i in range(i1, i0 - 1, -1)], [grid[i0][j] for j in range(j1, j0 - 1, -1)]]
			mid_i, mid_j = (i0 + i1 - 1) // 2, (j0 + j1 - 1) // 2
			# Stück, zu dem die Fase gehört: die Nachbarzelle über die Kante
			owner = [piece(mid_i, j0 - 1), piece(i1, mid_j), piece(mid_i, j1), piece(i0 - 1, mid_j)]
			prof = [(GLASS_BEVEL, -GLASS_BEVEL)] if kind == "glass" else PANEL[1:]
			outer = edges
			for d, h in prof:
				z = zf + side * h
				ring = [bm.verts.new(B(x0 + d, y0 + d, z)), bm.verts.new(B(x1 - d, y0 + d, z)),
					bm.verts.new(B(x1 - d, y1 - d, z)), bm.verts.new(B(x0 + d, y1 - d, z))]
				for k in range(4):
					a = outer[k] if isinstance(outer[k], list) else [outer[k], outer[(k + 1) % 4]]
					face(a + [ring[(k + 1) % 4], ring[k]], side, *owner[k])
				outer = ring
			if kind == "panel":
				face(outer, side, ("panel", side, i0, j0), True)
			else:
				panes.append((side, kind, i0, j0, outer, owner))
	# Laibung der Glasfelder: von der Fase vorn zur Fase hinten
	inner = {}
	for side, kind, i0, j0, ring, owner in panes:
		inner.setdefault((i0, j0), {})[side] = (ring, owner)
	glass = []
	for (i0, j0), both in inner.items():
		f_ring, owner = both[1]
		b_ring = both[-1][0]
		for k in range(4):
			face([f_ring[k], f_ring[(k + 1) % 4], b_ring[(k + 1) % 4], b_ring[k]], 1, *owner[k])
		glass.append([G(f_ring[k].co) for k in range(4)])
	# Kanten des Blatts: Umriss vorn und hinten verbinden
	front, back = grids[1], grids[-1]
	n, m = len(xs) - 1, len(ys) - 1
	ring = [(i, 0) for i in range(n)] + [(n, j) for j in range(m)] + [(i, m) for i in range(n, 0, -1)] \
		+ [(0, j) for j in range(m, 0, -1)]
	for k, (i, j) in enumerate(ring):
		i2, j2 = ring[(k + 1) % len(ring)]
		f = bm.faces.new((front[i][j], back[i][j], back[i2][j2], front[i2][j2]))
		uv(f, ("edge", k), i == i2)
	bmesh.ops.recalc_face_normals(bm, faces=bm.faces)   # Blatt ist geschlossen
	if not spec.get("weather", True):
		return finish(bm, "leaf_" + v), glass_panes(v, glass)
	# Wetterschenkel außen (−Z): Querschnitt entlang x gezogen, ohne Rückseite (liegt auf dem Blatt); offen, daher
	# jede Fläche ausdrücklich nach außen gedreht
	zb = -THICK / 2.0
	x0, x1 = WEATHER_INSET, lw - WEATHER_INSET
	sec = [(y, zb + z) for y, z in WEATHER]
	cy = sum(y for y, _ in sec) / len(sec)
	cz = sum(z for _, z in sec) / len(sec)
	left = [bm.verts.new(B(x0, y, z)) for y, z in sec]
	right = [bm.verts.new(B(x1, y, z)) for y, z in sec]

	def outward(f, n):
		f.normal_update()
		if f.normal.dot(B(*n)) < 0:
			f.normal_flip()

	for k in range(len(sec) - 1):
		f = bm.faces.new((left[k], right[k], right[k + 1], left[k + 1]))
		uv(f, ("weather",), False)
		my, mz = (sec[k][0] + sec[k + 1][0]) / 2.0, (sec[k][1] + sec[k + 1][1]) / 2.0
		outward(f, (0.0, my - cy, mz - cz))
	for sx, vs in ((-1.0, left), (1.0, right)):
		f = bm.faces.new(vs)
		uv(f, ("weather",), False)
		outward(f, (sx, 0.0, 0.0))
	return finish(bm, "leaf_" + v), glass_panes(v, glass)


def glass_panes(v, glass):
	"""Scheiben in der Mittelebene, so groß wie die Laibung"""
	gb = bmesh.new()
	guv = gb.loops.layers.uv.new("UVMap")   # Meter (der Import braucht UVs für die Tangenten)
	for pts in glass:
		f = gb.faces.new([gb.verts.new(B(p.x, p.y, 0.0)) for p in pts])
		for loop, p in zip(f.loops, pts):
			loop[guv].uv = (p.x, p.y)
	bmesh.ops.recalc_face_normals(gb, faces=gb.faces)
	for f in gb.faces:   # Vorderseite nach +Z (Blender −Y)
		if f.normal.y > 0:
			f.normal_flip()
	return finish(gb, "glass_" + v)


objs = {v: build_leaf(v, spec) for v, spec in VARIANTS.items()}
leaves = [objs[v][0] for v in VARIANTS]
panes = [objs[v][1] for v in VARIANTS]


# --- Atlas-UVs und Verschattung ----------------------------------------------------------------------------------
def atlas_uv(obs, margin):
	bpy.ops.object.select_all(action='DESELECT')
	for ob in obs:
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


atlas_uv(leaves, 0.002)

sc = bpy.context.scene
sc.render.engine = 'CYCLES'
sc.cycles.device = 'CPU'
sc.world = bpy.data.worlds.new("bake")
sc.world.light_settings.distance = AO_DISTANCE
sc.render.bake.margin = 8
sc.render.bake.use_clear = True

img = bpy.data.images.new("door_french_ao", AO_SIZE, AO_SIZE, alpha=False, float_buffer=False)
img.colorspace_settings.name = 'Non-Color'
mat = bpy.data.materials.new("bake")
mat.use_nodes = True
nt = mat.node_tree
node = nt.nodes.new("ShaderNodeTexImage")
node.image = img
uvn = nt.nodes.new("ShaderNodeUVMap")
uvn.uv_map = "atlas"
nt.links.new(uvn.outputs["UV"], node.inputs["Vector"])
nt.nodes.active = node
for k, ob in enumerate(leaves):
	ob.data.materials.append(mat)
	ob.location = (k * 3.0, 0, 0)   # nebeneinander, sonst verschatten sich die Varianten gegenseitig
for ob in panes:
	ob.hide_render = True
sc.cycles.samples = 256
bpy.ops.object.select_all(action='DESELECT')
for ob in leaves:
	ob.select_set(True)
bpy.context.view_layer.objects.active = leaves[0]
bpy.ops.object.bake(type='AO')
ao = np.array(img.pixels[:], dtype=np.float32).reshape(AO_SIZE, AO_SIZE, 4)
print("Blatt-AO: Mittel %.3f, dunkelster Wert %.3f" % (ao[..., 0].mean(), ao[..., 0].min()))
ao[..., :3] = 1.0 - AO_STRENGTH * (1.0 - np.clip(ao[..., :3], 0, 1))
img.pixels[:] = ao.ravel()
img.filepath_raw = AO_DST
img.file_format = 'PNG'
img.save()

# --- Export ------------------------------------------------------------------------------------------------------
for ob in leaves:
	ob.location = (0, 0, 0)
	ob.data.materials.clear()   # Holz setzt Door (Mat.hotel_wood mit dem AO-Bild)
for ob in leaves + panes:
	tris = sum(len(p.vertices) - 2 for p in ob.data.polygons)
	print("%-15s %4d Dreiecke, UV-Sätze %s" % (ob.name, tris, [l.name for l in ob.data.uv_layers]))
bpy.ops.object.select_all(action='DESELECT')
for ob in leaves + panes:
	ob.hide_render = False
	ob.select_set(True)
bpy.ops.export_scene.gltf(
	filepath=DST, export_format='GLB', export_yup=True, export_apply=False, use_selection=True,
	export_texcoords=True, export_normals=True, export_tangents=False, export_materials='NONE',
	export_skins=False, export_animations=False, export_morph=False, export_cameras=False, export_lights=False)
print("geschrieben:", DST, AO_DST)
