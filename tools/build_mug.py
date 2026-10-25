# Baut aus der Sketchfab-Tasse („Coffee Mug (School Project)“ von Ole Gunnar Isager,
# https://sketchfab.com/FrenchBaguette, CC-BY 4.0,
# https://sketchfab.com/3d-models/coffee-mug-school-project-5f5ccee1514c440887c072fae8e0d699) das Spielmodell
# assets/models/mug.glb für Kaffee und Tee (Spielkonzept 3.11, 3.12): HEIGHT hoch, Henkel nach +X (Godot),
# Ursprung mittig auf der Unterseite. Drei Objekte: „mug“ (Porzellan ohne Textur – das Spiel färbt es mit
# Item.CUP_COLOR), „coffee“ (die Oberfläche mit dem Kaffeefoto des Originals) und „tea“ (dieselbe Scheibe mit Tee:
# aus dem Kaffeefoto umgefärbt – bernsteinfarben, ohne Schaumbläschen – und mit einem Teebeutel darin, dessen Faden
# bei STRING_EXIT am Rand ankommt; dort setzt das Spiel Faden und Schildchen an). Das Spiel blendet eine der beiden
# Oberflächen aus.
# Am Ende stehen die Maße – für Item.MUG_* bzw. die Größe des Gegenstands.
#
# Aufruf (Blender 4.3):
#   blender -b --python tools/build_mug.py -- assets/source/coffee_mug.glb assets/models/mug.glb
import bpy, sys, math
import numpy as np
from mathutils import Matrix, Vector

HEIGHT = 0.09       # Meter (normale Kaffeetasse)
TEX_SIZE = 128
## Teebeutel in Godot-Koordinaten der fertigen Tasse (x, z in m): Mitte, Größe, Drehung (Grad)
BAG_AT = (0.008, -0.004)
BAG_SIZE = (0.026, 0.02)
BAG_TURN = 25.0
## Wo der Faden über den Rand geht (Godot x, z – z ist der Radius, wird auf die Innenwand gesetzt)
STRING_EXIT = (-0.012, 1.0)
## Tee: dunkel (Spiegelung, Mitte) bis hell (Rand), Teebeutel, Faden
TEA_DARK = (0.32, 0.12, 0.03)
TEA_LIGHT = (0.78, 0.47, 0.13)
BAG_PAPER = (0.86, 0.78, 0.62)
BAG_LEAVES = (0.36, 0.22, 0.1)
STRING = (0.92, 0.9, 0.84)

argv = sys.argv[sys.argv.index("--") + 1:]
SRC, DST = argv[0], argv[1]

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=SRC)
objs = {o.name: o for o in bpy.context.scene.objects if o.type == 'MESH'}
mug = next(o for n, o in objs.items() if "Mug" in n)
coffee = next(o for n, o in objs.items() if "Coffee" in n)
for o in (mug, coffee):
	o.data.transform(o.matrix_world)
	o.parent = None
	o.matrix_world = Matrix.Identity(4)
for o in [o for o in bpy.context.scene.objects if o not in (mug, coffee)]:
	bpy.data.objects.remove(o)

# Achse = Mitte der Kaffeescheibe; Henkel = die Punkte weit außerhalb der Wand (Wand ≈ Scheibenradius + 10 %)
cv = [v.co for v in coffee.data.vertices]
center = sum(cv, Vector()) / len(cv)
liquid_r = max((Vector((p.x, p.y)) - center.xy).length for p in cv)
handle = [v.co for v in mug.data.vertices if (v.co.xy - center.xy).length > liquid_r * 1.25]
hdir = (sum(handle, Vector()) / len(handle) - center).xy.normalized()
# Henkel nach +X drehen, Unterseite auf z = 0, auf HEIGHT skalieren
rot = Matrix.Rotation(-math.atan2(hdir.y, hdir.x), 4, 'Z')
z0 = min(v.co.z for v in mug.data.vertices)
z1 = max(v.co.z for v in mug.data.vertices)
s = HEIGHT / (z1 - z0)
xform = Matrix.Scale(s, 4) @ rot @ Matrix.Translation((-center.x, -center.y, -z0))
for o in (mug, coffee):
	o.data.transform(xform)
	o.data.update()
mug.name = mug.data.name = "mug"
coffee.name = coffee.data.name = "coffee"

# Ausgedünnt wird nicht – schon bei der Hälfte der Dreiecke wird der Rand zackig
mug.data.shade_smooth()

# --- Texturen ---------------------------------------------------------------------------------
src_img = None
for n in coffee.data.materials[0].node_tree.nodes:
	if n.type == 'BSDF_PRINCIPLED':
		link = n.inputs["Base Color"].links
		src_img = link[0].from_node.image if link else None
W, H = src_img.size
px = np.array(src_img.pixels[:], dtype=np.float32).reshape(H, W, 4)   # Zeile 0 = unten (Blender)


def blur(a, radius, passes=3):
	# Kastenfilter mehrfach ≈ Gauß, auf beiden Achsen
	for _ in range(passes):
		for axis in (0, 1):
			k = np.ones(2 * radius + 1, dtype=np.float32) / (2 * radius + 1)
			a = np.apply_along_axis(lambda m: np.convolve(np.pad(m, radius, mode='edge'), k, mode='valid'), axis, a)
	return a


# Godot (x, z) der Tasse → Pixel: UVs der Scheibe affin aus den Punkten (Blender x, y; Godot z = −y)
me = coffee.data
uv = me.uv_layers.active.data
rows, us, vs = [], [], []
for poly in me.polygons:
	for li in poly.loop_indices:
		co = me.vertices[me.loops[li].vertex_index].co
		rows.append((co.x, -co.y, 1.0))
		us.append(uv[li].uv.x)
		vs.append(uv[li].uv.y)
A = np.array(rows)
cu = np.linalg.lstsq(A, np.array(us), rcond=None)[0]
cv_ = np.linalg.lstsq(A, np.array(vs), rcond=None)[0]
# Pixel → Godot (x, z): Umkehrung der affinen Abbildung
M = np.array([[cu[0], cu[1]], [cv_[0], cv_[1]]])
Minv = np.linalg.inv(M)
yy, xx = np.mgrid[0:H, 0:W].astype(np.float32)
u = (xx + 0.5) / W - cu[2]
v = (yy + 0.5) / H - cv_[2]
gx = Minv[0, 0] * u + Minv[0, 1] * v
gz = Minv[1, 0] * u + Minv[1, 1] * v
r_liquid = liquid_r * s

# Tee: Helligkeit des Kaffeefotos weichgezeichnet (Bläschen weg, Spiegelung und heller Rand bleiben) → Bernstein
lum = px[..., 0] * 0.3 + px[..., 1] * 0.59 + px[..., 2] * 0.11
lum = blur(lum, 6)
lo, hi = np.percentile(lum, 3), np.percentile(lum, 97)
t = np.clip((lum - lo) / (hi - lo), 0.0, 1.0) ** 0.8
tea = np.zeros_like(px)
for c in range(3):
	tea[..., c] = TEA_DARK[c] + (TEA_LIGHT[c] - TEA_DARK[c]) * t
tea[..., 3] = 1.0

# Teebeutel: abgerundetes Rechteck, nass (dunkle Blätter schimmern durch), Rand gefalzt, halb untergetaucht
ang = math.radians(BAG_TURN)
dx, dz = gx - BAG_AT[0], gz - BAG_AT[1]
bx = dx * math.cos(ang) + dz * math.sin(ang)
bz = -dx * math.sin(ang) + dz * math.cos(ang)
hx, hz = BAG_SIZE[0] / 2, BAG_SIZE[1] / 2
corner = min(hx, hz) * 0.35
qx = np.maximum(np.abs(bx) - (hx - corner), 0.0)
qz = np.maximum(np.abs(bz) - (hz - corner), 0.0)
dist = np.sqrt(qx * qx + qz * qz) - corner        # < 0 innen
px_m = 2 * r_liquid / W                           # Meter je Pixel (ungefähr)
inside = np.clip(-dist / px_m, 0.0, 1.0)
rng = np.random.default_rng(7)
grain = blur(rng.random((H, W)).astype(np.float32), 2, 1)
grain = (grain - grain.mean()) / (grain.std() + 1e-6)
leaves = np.clip(0.55 + 0.25 * grain - 0.4 * np.clip((-dist) / (hz * 0.9), 0, 1) ** 0.5, 0.0, 1.0)
seam = np.clip(1.0 - np.abs(-dist - hz * 0.12) / (hz * 0.08), 0.0, 1.0)   # gefalzter Rand
for c in range(3):
	bag = BAG_LEAVES[c] + (BAG_PAPER[c] - BAG_LEAVES[c]) * np.maximum(leaves, seam * 0.9)
	bag = bag * 0.8 + tea[..., c] * 0.2              # nass, vom Tee getönt
	tea[..., c] = tea[..., c] * (1 - inside) + bag * inside
# Schatten des Beutels im Tee (etwas versetzt)
shadow = np.clip(-(np.sqrt(np.maximum(np.abs(bx + 0.0015) - (hx - corner), 0) ** 2 + np.maximum(np.abs(bz - 0.0015) - (hz - corner), 0) ** 2) - corner) / (px_m * 6) + 1.0, 0, 1) * (1 - inside)
for c in range(3):
	tea[..., c] *= 1.0 - 0.35 * shadow

# Faden: vom Beutel (Oberkante) zur Austrittsstelle am Rand
ex = STRING_EXIT[0]
ez = math.sqrt(max(r_liquid ** 2 - ex ** 2, 0.0)) * (1 if STRING_EXIT[1] > 0 else -1)
sx = BAG_AT[0] - math.sin(ang) * hz * 0.8
sz = BAG_AT[1] + math.cos(ang) * hz * 0.8
seg = np.array([ex - sx, ez - sz])
L2 = float(seg @ seg)
tt = np.clip(((gx - sx) * seg[0] + (gz - sz) * seg[1]) / L2, 0.0, 1.0)
d_line = np.hypot(gx - (sx + tt * seg[0]), gz - (sz + tt * seg[1]))
line = np.clip(1.0 - (d_line - px_m * 0.7) / px_m, 0.0, 1.0)
for c in range(3):
	tea[..., c] = tea[..., c] * (1 - line) + STRING[c] * line


def make_image(name, arr):
	img = bpy.data.images.new(name, W, H, alpha=False)
	img.pixels[:] = arr.reshape(-1).tolist()
	img.scale(TEX_SIZE, TEX_SIZE)
	img.file_format = 'PNG'
	img.pack()
	return img


def textured(name, img):
	mat = bpy.data.materials.new(name)
	mat.use_nodes = True
	nodes = mat.node_tree.nodes
	tex = nodes.new("ShaderNodeTexImage")
	tex.image = img
	tex.interpolation = 'Closest'
	mat.node_tree.links.new(tex.outputs["Color"], nodes["Principled BSDF"].inputs["Base Color"])
	return mat


coffee_mat = textured("coffee", make_image("coffee", px))
tea_mat = textured("tea", make_image("tea", tea))
china = bpy.data.materials.new("china")
china.diffuse_color = (0.93, 0.92, 0.88, 1.0)
mug.data.materials.clear()
mug.data.materials.append(china)
coffee.data.materials.clear()
coffee.data.materials.append(coffee_mat)
tea_obj = coffee.copy()
tea_obj.data = coffee.data.copy()
tea_obj.name = tea_obj.data.name = "tea"
bpy.context.scene.collection.objects.link(tea_obj)
tea_obj.data.materials.clear()
tea_obj.data.materials.append(tea_mat)

bpy.ops.export_scene.gltf(filepath=DST, export_format='GLB', export_yup=True, export_image_format='AUTO',
	export_texcoords=True, export_normals=True, export_materials='EXPORT', export_animations=False)

pts = [v.co for v in mug.data.vertices]
body_r = max((p.xy).length for p in pts if p.x < 0)        # Seite ohne Henkel
tris = sum(len(p.vertices) - 2 for o in (mug, coffee) for p in o.data.polygons)
level = coffee.data.vertices[0].co.z
print("mug: %d Dreiecke, %.3f m hoch, Wand-Radius %.3f m, Henkel bis x = %.3f m, Flüssigkeit auf %.3f m (Radius %.3f)"
	% (tris, HEIGHT, body_r, max(p.x for p in pts), level, r_liquid))
# Blender (x, y, z) → Godot (x, z, −y)
print("Faden am Rand: Vector3(%.3f, %.3f, %.3f)" % (ex, level, ez))
