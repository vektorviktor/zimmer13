# Baut aus „old_leather_armchair“ (VoGAn, Sketchfab https://skfb.ly/6Tq9y, CC-BY 4.0) das Spielmodell
# assets/models/armchair.glb für den Sessel am Schreibtisch im Büro der Direktion (ZIM-150): Ursprung mittig auf dem
# Boden, Sitz nach +Z (Godot), Maße wie im Original (0,90 breit, 1,10 tief mit der zurückgeneigten Lehne, 0,95 hoch).
# Das OBJ (im Download in source/Textures.rar, hier assets/source/old_leather_armchair/model.obj) ist in Zentimetern
# (Kopfzeile sagt fälschlich Meter).
# Ein Netz „body“; die Beine sind Teil davon, ihre Flächen (ganz unter LEG_TOP) bleiben aber beim Färben ausgespart.
# Texturen: das PBR-Set des Originals (2048 px), als PNG neben das Modell:
#   <tex>_albedo.png   Farbe – das fast schwarze Leder rot gefärbt (recolor), Beine, Nieten und Unterseite wie im Original
#   <tex>_normal.png   Normal Map (OpenGL, wie Godot)
#   <tex>_orm.png      glTF-Anordnung: Rot Verdeckung (AO), Grün Rauheit, Blau Metall (keins)
# Die GLB trägt nur Netz, UVs und Tangenten; das Material baut Armchair in Godot (Mat.pbr_model).
#
# Aufruf aus dem Projektordner (Blender 4.3; Pfade absolut, der Texturordner ist der des Sketchfab-Downloads):
#   blender -b --python tools/build_armchair.py -- assets/source/old_leather_armchair/model.obj <download>/textures assets/models/armchair.glb assets/textures/armchair
import bpy, sys, os
import numpy as np
from mathutils import Matrix

TEX_SIZE = 2048
## Flächen ganz unterhalb dieser Höhe (m) sind Holzbeine
LEG_TOP = 0.225
## Leder: Farbe bei mittlerer Helligkeit des Originals (sRGB), Helligkeit je Pixel skaliert sie (Kratzer, Falten),
## gestaucht mit LEATHER_GAMMA, damit helle Abriebstellen nicht grell werden
LEATHER_RED = np.array([0.42, 0.065, 0.055], dtype=np.float32)
LEATHER_MID = 0.14
LEATHER_GAMMA = 0.75
## Ab dieser Helligkeit (sRGB) blendet die Färbung aus: Messingnieten und die helle Unterseite bleiben
KEEP_FROM, KEEP_FULL = 0.50, 0.65

argv = sys.argv[sys.argv.index("--") + 1:]
SRC, TEX_DIR, DST, TEX = argv[0], argv[1], argv[2], argv[3]

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.wm.obj_import(filepath=SRC)   # Y oben → Blender Z oben, OBJ +Z (Sitz) → Blender −Y → glTF/Godot +Z
meshes = [o for o in bpy.context.scene.objects if o.type == 'MESH']
for o in meshes:
	o.data.transform(Matrix.Scale(0.01, 4) @ o.matrix_world)
	o.matrix_world = Matrix.Identity(4)
if len(meshes) > 1:
	bpy.ops.object.select_all(action='DESELECT')
	for o in meshes:
		o.select_set(True)
	bpy.context.view_layer.objects.active = meshes[0]
	bpy.ops.object.join()
body = meshes[0]
body.name = body.data.name = "body"
body.data.materials.clear()

def bounds(o):
	vs = [v.co for v in o.data.vertices]
	return [min(v[i] for v in vs) for i in range(3)], [max(v[i] for v in vs) for i in range(3)]

lo, hi = bounds(body)
body.data.transform(Matrix.Translation((-(lo[0] + hi[0]) / 2.0, -(lo[1] + hi[1]) / 2.0, -lo[2])))

# Maske der Beine im UV-Raum: Dreiecke der Beinflächen ausmalen, 2 px Rand gegen Nähte
def leg_mask():
	mask = np.zeros((TEX_SIZE, TEX_SIZE), dtype=bool)
	uv = body.data.uv_layers.active.data
	verts = body.data.vertices
	for p in body.data.polygons:
		if max(verts[i].co.z for i in p.vertices) >= LEG_TOP:
			continue
		pts = [np.array(uv[li].uv) * TEX_SIZE for li in p.loop_indices]
		for k in range(1, len(pts) - 1):
			a, b, c = pts[0], pts[k], pts[k + 1]
			x0, y0 = np.floor(np.minimum(np.minimum(a, b), c)).astype(int) - 2
			x1, y1 = np.ceil(np.maximum(np.maximum(a, b), c)).astype(int) + 2
			x0, y0, x1, y1 = max(x0, 0), max(y0, 0), min(x1, TEX_SIZE - 1), min(y1, TEX_SIZE - 1)
			if x1 < x0 or y1 < y0:
				continue
			xs, ys = np.meshgrid(np.arange(x0, x1 + 1) + 0.5, np.arange(y0, y1 + 1) + 0.5)
			d = (b[1] - c[1]) * (a[0] - c[0]) + (c[0] - b[0]) * (a[1] - c[1])
			if abs(d) < 1e-9:
				continue
			l1 = ((b[1] - c[1]) * (xs - c[0]) + (c[0] - b[0]) * (ys - c[1])) / d
			l2 = ((c[1] - a[1]) * (xs - c[0]) + (a[0] - c[0]) * (ys - c[1])) / d
			l3 = 1.0 - l1 - l2
			pad = 2.0 / max(1.0, np.sqrt(abs(d)))   # ~2 px in baryzentrischen Einheiten
			inside = (l1 >= -pad) & (l2 >= -pad) & (l3 >= -pad)
			mask[y0:y1 + 1, x0:x1 + 1] |= inside
	return mask   # Zeile 0 = v 0 (Blender-Pixelreihenfolge: unten zuerst)

def load(name):
	img = bpy.data.images.load(os.path.abspath(os.path.join(TEX_DIR, name)))
	if img.size[0] != TEX_SIZE:
		img.scale(TEX_SIZE, TEX_SIZE)
	return np.array(img.pixels[:], dtype=np.float32).reshape(TEX_SIZE, TEX_SIZE, img.channels)

# Byte-Bilder: pixels sind die gespeicherten Werte (Farbe bleibt sRGB), also unverändert zurückschreiben
def save(name, rgb):
	img = bpy.data.images.new(name, TEX_SIZE, TEX_SIZE, alpha=False, float_buffer=False)
	rgba = np.ones((TEX_SIZE, TEX_SIZE, 4), dtype=np.float32)
	rgba[..., :3] = rgb
	img.pixels[:] = rgba.ravel()
	img.filepath_raw = os.path.abspath("%s_%s.png" % (TEX, name.split("_")[-1]))
	img.file_format = 'PNG'
	img.save()

# Leder rot: Helligkeit des Originals behalten, Farbton und Sättigung neu; Beine und Helles bleiben
def recolor(rgb, legs):
	luma = rgb @ np.array([0.2126, 0.7152, 0.0722], dtype=np.float32)
	red = np.clip(LEATHER_RED[None, None, :] * ((luma / LEATHER_MID) ** LEATHER_GAMMA)[..., None], 0.0, 1.0)
	t = np.clip((luma - KEEP_FROM) / (KEEP_FULL - KEEP_FROM), 0.0, 1.0)
	w = (1.0 - t * t * (3.0 - 2.0 * t)) * (~legs)
	return rgb + (red - rgb) * w[..., None]

save("armchair_albedo", recolor(load("old_leather_armchair_diff.png")[..., :3], leg_mask()))
save("armchair_normal", load("old_leather_armchair_nm.png")[..., :3])
orm = np.zeros((TEX_SIZE, TEX_SIZE, 3), dtype=np.float32)
orm[..., 0] = load("old_leather_armchair_ao.png")[..., 0]
orm[..., 1] = load("old_leather_armchair_rougtnes.png")[..., 0]
save("armchair_orm", orm)

bpy.ops.export_scene.gltf(filepath=DST, export_format='GLB', export_yup=True, export_texcoords=True,
	export_normals=True, export_tangents=True, export_materials='NONE', export_animations=False)

lo, hi = bounds(body)
print("%s: %d Dreiecke, %.3f breit, %.3f tief, %.3f hoch, Mitte der Tiefe bei %.3f (Blender −Y = vorn)"
	% (body.name, sum(len(p.vertices) - 2 for p in body.data.polygons), hi[0] - lo[0], hi[1] - lo[1], hi[2] - lo[2],
	(lo[1] + hi[1]) / 2.0))
