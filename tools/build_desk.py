# Baut aus „Antique Desk“ (Matthew Collings, Sketchfab https://skfb.ly/o8Ptu, CC-BY 4.0) das Spielmodell
# assets/models/desk.glb für den Schreibtisch im Büro der Direktion (ZIM-150): Ursprung mittig auf dem Boden,
# Vorderseite (Schubladengriffe) nach +Z (Godot), Maße wie im Original (1,61 × 0,66 m, 0,82 m hoch).
# Teile: „body“ (Korpus mit den Seitenschubladen und ihren Griffen) und die drei Schubladen unter der Platte als
# eigene Objekte „drawer_l“, „drawer_m“, „drawer_r“ samt Griff – im selben Ursprung wie der Korpus, damit sie sich
# später herausziehen lassen (entlang +Z).
# Texturen: das PBR-Set des Originals, von 4096 auf TEX_SIZE verkleinert, als PNG neben das Modell:
#   <tex>_albedo.png   Farbe
#   <tex>_normal.png   Normal Map (OpenGL, wie Godot)
#   <tex>_orm.png      glTF-Anordnung: Rot 1, Grün Rauheit, Blau Metall (nur die Messinggriffe)
# Die GLB trägt nur Netz, UVs und Tangenten; das Material baut Desk in Godot (Mat.pbr_model).
#
# Aufruf aus dem Projektordner (Blender 4.3; der Texturordner ist der des Sketchfab-Downloads):
#   blender -b --python tools/build_desk.py -- assets/source/antique_desk/model.fbx <download>/textures assets/models/desk.glb assets/textures/desk
import bpy, sys, os
import numpy as np
from mathutils import Matrix

TEX_SIZE = 2048
DRAWERS = {"Draw 1_low": "drawer_l", "Draw 2_low": "drawer_m", "Draw 3_low": "drawer_r"}

argv = sys.argv[sys.argv.index("--") + 1:]
SRC, TEX_DIR, DST, TEX = argv[0], argv[1], argv[2], argv[3]

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.fbx(filepath=SRC)
meshes = [o for o in bpy.context.scene.objects if o.type == 'MESH']
for o in meshes:   # alles in Weltkoordinaten, Eltern lösen (Griffe hängen an Schubladen bzw. am Korpus)
	o.data.transform(o.matrix_world)
for o in meshes:
	o.parent = None
	o.matrix_world = Matrix.Identity(4)
for o in [o for o in bpy.context.scene.objects if o.type != 'MESH']:
	bpy.data.objects.remove(o)

def bounds(objs):
	vs = [v.co for o in objs for v in o.data.vertices]
	return [min(v[i] for v in vs) for i in range(3)], [max(v[i] for v in vs) for i in range(3)]

def join(target, others):
	if not others:
		return
	bpy.ops.object.select_all(action='DESELECT')
	for o in others + [target]:
		o.select_set(True)
	bpy.context.view_layer.objects.active = target
	bpy.ops.object.join()

# Griffe der oberen Schubladen gehören zur Schublade, deren Front sie tragen; die übrigen zum Korpus
by_name = {o.name: o for o in meshes}
drawers = {by_name[n]: name for n, name in DRAWERS.items()}
handles = [o for o in meshes if o.name.startswith("Handle")]
parts = {d: [] for d in drawers}
body_parts = []
for h in handles:
	hl, hh = bounds([h])
	owner = next((d for d in drawers if bounds([d])[0][2] <= hl[2] and hh[2] <= bounds([d])[1][2]
		and bounds([d])[0][0] <= hl[0] and hh[0] <= bounds([d])[1][0]), None)
	(parts[owner] if owner else body_parts).append(h)
body = by_name["Desk_low"]
join(body, body_parts)
body.name = body.data.name = "body"
for d, name in drawers.items():
	join(d, parts[d])
	d.name = d.data.name = name

# Ursprung mittig auf den Boden
everything = [o for o in bpy.context.scene.objects if o.type == 'MESH']
lo, hi = bounds(everything)
shift = Matrix.Translation((-(lo[0] + hi[0]) / 2.0, -(lo[1] + hi[1]) / 2.0, -lo[2]))
for o in everything:
	o.data.transform(shift)
	o.data.materials.clear()

# Texturen verkleinern und schreiben
def load(name):
	img = bpy.data.images.load(os.path.abspath(os.path.join(TEX_DIR, name)))
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

save("desk_albedo", load("Desk_BaseColor.png")[..., :3])
save("desk_normal", load("Desk_Normal.png")[..., :3])
orm = np.ones((TEX_SIZE, TEX_SIZE, 3), dtype=np.float32)
orm[..., 1] = load("Desk_Roughness.png")[..., 0]
orm[..., 2] = load("Desk_Metallic.png")[..., 0]
save("desk_orm", orm)

bpy.ops.export_scene.gltf(filepath=DST, export_format='GLB', export_yup=True, export_texcoords=True,
	export_normals=True, export_tangents=True, export_materials='NONE', export_animations=False)

for o in everything:
	l, h = bounds([o])
	print("%s: %d Dreiecke, x %.3f..%.3f, y %.3f..%.3f, z %.3f..%.3f (Blender)"
		% (o.name, sum(len(p.vertices) - 2 for p in o.data.polygons), l[0], h[0], l[1], h[1], l[2], h[2]))
lo, hi = bounds(everything)
print("Gesamt %.3f breit, %.3f tief, %.3f hoch" % (hi[0] - lo[0], hi[1] - lo[1], hi[2] - lo[2]))
