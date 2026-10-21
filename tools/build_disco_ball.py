# Baut aus der Sketchfab-Discokugel (1.920 Spiegelplättchen, 64 Spalten × 30 Reihen, auf einem grauen
# Grundkörper mit hochgezogenen Plättchenkanten – zusammen 31.744 Dreiecke) eine Low-Poly-Kugel:
# glatte UV-Kugel (SEGMENTS × RINGS, ~2.200 Dreiecke), Plättchen und Fugen als Texturen gebacken –
# Normal Map (jedes Plättchen behält seine eigene, flache Ausrichtung), Farbe (Fuge grau, Spiegel weiß) und
# Metallic/Roughness (Spiegel metallisch und glatt, Fuge matt). Die Plättchen allein bräuchten als
# Geometrie schon 3.840 Dreiecke. Ursprung in der Kugelmitte, Durchmesser wie das Original.
# Original: „Disco Ball“ von araghon007 (Sketchfab, CC-BY 4.0). Im Spiel zeichnet es shaders/psx_mirror.gdshader
# (DiscoBall) – Normal Map und Spiegelmaske (Blau der Metallic-Textur) liest es aus dem importierten Material.
#
# Aufruf (Blender 4.3):
#   blender -b --python tools/build_disco_ball.py -- assets/source/disco_ball.glb assets/models/disco_ball.glb
import bpy, bmesh, sys, math
import numpy as np
from mathutils import Matrix

SEGMENTS = 48     # Längengrade der Low-Poly-Kugel
RINGS = 24        # Breitengrade
TEX_W, TEX_H = 1024, 512    # 64 Spalten → 16 Pixel je Plättchen, die Fugen 1–2 Pixel (2048 lohnt bei 480×270 nicht)
CAGE = 0.02       # so weit (m) schießen die Bake-Strahlen von außerhalb der Kugel ein

argv = sys.argv[sys.argv.index("--") + 1:]
SRC, DST = argv[0], argv[1]

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=SRC)
high = [o for o in bpy.context.scene.objects if o.type == 'MESH']
for o in high:
	o.data.transform(o.matrix_world)
	o.parent = None
	o.matrix_world = Matrix.Identity(4)
for o in [o for o in bpy.context.scene.objects if o.type != 'MESH']:
	bpy.data.objects.remove(o)
src_tris = sum(len(p.vertices) - 2 for o in high for p in o.data.polygons)
radius = max(v.co.length for o in high for v in o.data.vertices)

# Spiegel = metallisches Material (Plättchen), sonst Fuge. Fürs Maskenbacken leuchten nur die Spiegel.
for o in high:
	for m in o.data.materials:
		bsdf = m.node_tree.nodes["Principled BSDF"]
		mirror = bsdf.inputs["Metallic"].default_value > 0.5
		bsdf.inputs["Emission Color"].default_value = (1, 1, 1, 1) if mirror else (0, 0, 0, 1)
		bsdf.inputs["Emission Strength"].default_value = 1.0
		if not mirror:
			grout = tuple(bsdf.inputs["Base Color"].default_value)
mirrors = [o for o in high if o.data.materials[0].node_tree.nodes["Principled BSDF"].inputs["Metallic"].default_value > 0.5]

# Low-Poly-Kugel: Ringe × Segmente, Naht bei ±180° (liegt in einer Fuge), Pole als Dreiecksfächer
bm = bmesh.new()
uv = bm.loops.layers.uv.new("UVMap")
grid = []
for r in range(1, RINGS):
	lat = math.pi * (r / RINGS - 0.5)
	row = []
	for s in range(SEGMENTS + 1):
		lon = 2.0 * math.pi * s / SEGMENTS - math.pi
		v = bm.verts.new((radius * math.cos(lat) * math.cos(lon), radius * math.cos(lat) * math.sin(lon), radius * math.sin(lat)))
		row.append(v)
	grid.append(row)
def face(verts, uvs):
	f = bm.faces.new(verts)
	for l, c in zip(f.loops, uvs):
		l[uv].uv = c
	f.smooth = True
for r in range(RINGS - 2):
	for s in range(SEGMENTS):
		u0, u1 = s / SEGMENTS, (s + 1) / SEGMENTS
		v0, v1 = (r + 1) / RINGS, (r + 2) / RINGS
		# Diagonale fest von unten links nach oben rechts – tangent_frames() rechnet mit genau dieser Teilung
		face([grid[r][s], grid[r][s + 1], grid[r + 1][s + 1]], [(u0, v0), (u1, v0), (u1, v1)])
		face([grid[r][s], grid[r + 1][s + 1], grid[r + 1][s]], [(u0, v0), (u1, v1), (u0, v1)])
for s in range(SEGMENTS):
	u0, u1, um = s / SEGMENTS, (s + 1) / SEGMENTS, (s + 0.5) / SEGMENTS
	south = bm.verts.new((0, 0, -radius))
	north = bm.verts.new((0, 0, radius))
	face([south, grid[0][s + 1], grid[0][s]], [(um, 0.0), (u1, 1 / RINGS), (u0, 1 / RINGS)])
	face([north, grid[-1][s], grid[-1][s + 1]], [(um, 1.0), (u0, 1 - 1 / RINGS), (u1, 1 - 1 / RINGS)])
bmesh.ops.remove_doubles(bm, verts=[v for v in bm.verts if abs(abs(v.co.z) - radius) < 1e-6], dist=1e-6)
me = bpy.data.meshes.new("disco_ball")
bm.to_mesh(me)
bm.free()
me.normals_split_custom_set_from_vertices([v.co.normalized() for v in me.vertices])   # genau radial
low = bpy.data.objects.new("disco_ball", me)
bpy.context.scene.collection.objects.link(low)

def image(name, color_space):
	img = bpy.data.images.new(name, TEX_W, TEX_H, alpha=False, float_buffer=False)
	img.colorspace_settings.name = color_space
	return img

bake_mat = bpy.data.materials.new("bake")
bake_mat.use_nodes = True
bake_node = bake_mat.node_tree.nodes.new("ShaderNodeTexImage")
bake_mat.node_tree.nodes.active = bake_node
low.data.materials.append(bake_mat)

scene = bpy.context.scene
scene.render.engine = 'CYCLES'
scene.cycles.device = 'CPU'
scene.cycles.samples = 16
scene.render.bake.use_selected_to_active = True
scene.render.bake.cage_extrusion = CAGE
scene.render.bake.max_ray_distance = 2 * CAGE
scene.render.bake.margin = 4
bpy.ops.object.select_all(action='DESELECT')
for o in high:
	o.select_set(True)
low.select_set(True)
bpy.context.view_layer.objects.active = low

def bake(kind, img):
	bake_node.image = img
	bpy.ops.object.bake(type=kind)
	return np.array(img.pixels[:]).reshape(TEX_H, TEX_W, 4)

mask = bake('EMIT', image("mask", 'Non-Color'))[:, :, 0:1]
scene.world = bpy.data.worlds.new("bake")
scene.world.light_settings.distance = 0.05
scene.cycles.samples = 256   # Verschattung rauscht sonst
ao = bake('AO', image("ao", 'Non-Color'))[:, :, 0:1]
scene.cycles.samples = 16

# Jedes Plättchen ist ein ebener Spiegel: Die gebackene Normale rauscht leicht, und schon Bruchteile eines
# Grads lassen die Spiegelbilder zittern. Auf den Plättchen steht deshalb die exakte Flächennormale aus dem
# Original. Die Plättchen liegen genau in Zellen von 5,625° (64 Spalten ab −180°, 32 Reihen ab dem Südpol,
# die äußersten sind Fuge).
COLS, ROWS = 64, 32
acc = np.zeros((ROWS, COLS, 3))
for o in mirrors:
	for p in o.data.polygons:
		c = p.center
		col = int((math.atan2(c.y, c.x) + math.pi) / (2 * math.pi) * COLS) % COLS
		row = int((math.asin(c.z / c.length) + math.pi / 2) / math.pi * ROWS)
		acc[row, col] += np.array(p.normal) * p.area
acc /= np.maximum(np.linalg.norm(acc, axis=-1, keepdims=True), 1e-9)
tile = acc[np.arange(TEX_H) * ROWS // TEX_H][:, np.arange(TEX_W) * COLS // TEX_W]
on = (mask > 0.5) & (np.linalg.norm(tile, axis=-1, keepdims=True) > 0.5)
# Fugen glatt (radial) – die gebackenen Normalen der Plättchenwände rauschen dort nur
lon = (np.arange(TEX_W) + 0.5) / TEX_W * 2 * math.pi - math.pi
lat = (np.arange(TEX_H) + 0.5) / TEX_H * math.pi - math.pi / 2
lon, lat = np.meshgrid(lon, lat)
radial = np.stack([np.cos(lat) * np.cos(lon), np.cos(lat) * np.sin(lon), np.sin(lat)], -1)
# Die Plättchennormale reicht ein Pixel in die Fuge: Beim Filtern mischt sich die Fugennormale sonst an der
# Kante unter die noch metallischen Randpixel, und die spiegeln dann Lichter als helle Striche
grow = on | np.roll(on, 1, 0) | np.roll(on, -1, 0) | np.roll(on, 1, 1) | np.roll(on, -1, 1)
grow &= np.linalg.norm(tile, axis=-1, keepdims=True) > 0.5
vec = np.where(grow, tile, radial)

# In den Tangentenraum rechnet Blender selbst um (MikkTSpace wie Godot): eine Kopie der Low-Poly-Kugel
# trägt die Normalen als Object-Space-Map (Fließkomma, ungerundet), gebacken wird auf die Low-Poly-Kugel.
objn = bpy.data.images.new("normal_object_fixed", TEX_W, TEX_H, alpha=False, float_buffer=True)
objn.colorspace_settings.name = 'Non-Color'
objn.pixels[:] = np.dstack([vec * 0.5 + 0.5, np.ones_like(mask)]).ravel()
src = low.copy()
src.data = low.data.copy()
bpy.context.scene.collection.objects.link(src)
src_mat = bpy.data.materials.new("normal_object")
src_mat.use_nodes = True
t = src_mat.node_tree.nodes.new("ShaderNodeTexImage")
t.image = objn
t.interpolation = 'Closest'
nm = src_mat.node_tree.nodes.new("ShaderNodeNormalMap")
nm.space = 'OBJECT'
src_mat.node_tree.links.new(t.outputs["Color"], nm.inputs["Color"])
src_mat.node_tree.links.new(nm.outputs["Normal"], src_mat.node_tree.nodes["Principled BSDF"].inputs["Normal"])
src.data.materials.clear()
src.data.materials.append(src_mat)
for o in high:
	o.select_set(False)
src.select_set(True)
scene.render.bake.normal_space = 'TANGENT'
normal = image("disco_ball_normal", 'Non-Color')
bake('NORMAL', normal)
bpy.data.objects.remove(src)

# Farbe (Fugen mit gebackener Verschattung, die Spalten sind tiefer als breit) und Metallic/Roughness
# (glTF: G = Roughness, B = Metallic) aus der Maske – hart: halb metallische Randpixel spiegelten mit der
# steilen Normale der Plättchenwände sonst Lichter als helle Kanten
mask = on.astype(float)
color = image("disco_ball_color", 'sRGB')
lin = np.array(grout[:3]) * ao * (1 - mask) + mask
srgb = np.where(lin <= 0.0031308, lin * 12.92, 1.055 * np.power(lin, 1 / 2.4) - 0.055)
color.pixels[:] = np.dstack([srgb, np.ones_like(mask)]).ravel()
orm = image("disco_ball_mr", 'Non-Color')
orm.pixels[:] = np.dstack([np.ones_like(mask), 1 - mask, mask, np.ones_like(mask)]).ravel()

for o in high:
	bpy.data.objects.remove(o)
for img in (normal, color, orm):
	img.file_format = 'PNG'
	img.pack()

mat = bpy.data.materials.new("disco_ball")
mat.use_nodes = True
nodes, links = mat.node_tree.nodes, mat.node_tree.links
bsdf = nodes["Principled BSDF"]
t_col = nodes.new("ShaderNodeTexImage"); t_col.image = color
t_mr = nodes.new("ShaderNodeTexImage"); t_mr.image = orm
t_n = nodes.new("ShaderNodeTexImage"); t_n.image = normal
sep = nodes.new("ShaderNodeSeparateColor")
nmap = nodes.new("ShaderNodeNormalMap")
links.new(t_col.outputs["Color"], bsdf.inputs["Base Color"])
links.new(t_mr.outputs["Color"], sep.inputs["Color"])
links.new(sep.outputs["Green"], bsdf.inputs["Roughness"])
links.new(sep.outputs["Blue"], bsdf.inputs["Metallic"])
links.new(t_n.outputs["Color"], nmap.inputs["Color"])
links.new(nmap.outputs["Normal"], bsdf.inputs["Normal"])
low.data.materials.clear()
low.data.materials.append(mat)

bpy.ops.object.select_all(action='DESELECT')
low.select_set(True)
bpy.ops.export_scene.gltf(filepath=DST, export_format='GLB', export_yup=True, export_image_format='AUTO',
	use_selection=True, export_texcoords=True, export_normals=True, export_tangents=True,
	export_materials='EXPORT', export_animations=False)

tris = sum(len(p.vertices) - 2 for p in low.data.polygons)
print("disco_ball: %d → %d Dreiecke, Durchmesser %.3f m, Texturen %d × %d" % (src_tris, tris, 2 * radius, TEX_W, TEX_H))
