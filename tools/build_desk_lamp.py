# Baut aus „Desk Lamp Antique 01“ (CGTrader, SM_DeskLamp_Antique_01.fbx) das Spielmodell assets/models/desk_lamp.glb
# für die Schreibtischlampe (Lamp.Style.DESK): grüne Bankerlampe aus Messing, 0,62 m hoch. Ursprung mittig unter dem
# Fuß, der offene Schirm nach +Z (Godot) – das Original schaut nach Blender +Y, darum um 180° gedreht.
# Die Röhrenbirne im Schirm und die Zugkette mit Knauf fallen weg (Wunsch des Nutzers): Statt der Röhre steckt im Spiel
# die gewöhnliche Glühbirne (bulb.glb) im Schirm und lässt sich herausdrehen, geschaltet wird mit dem Raum.
# Erkannt werden die Teile als lose Netzteile: die Birne liegt ganz im Quader des Schirms (das höchste Teil), die Kette
# und ihr Knauf sind dünner als CORD_THIN.
# Texturen: das PBR-Set des Originals (2048 px), als PNG neben das Modell:
#   <tex>_albedo.png   Farbe wie im Original
#   <tex>_normal.png   Normal Map wie im Original – trotz Unreal-Namen schon OpenGL wie Godot (geprüft: ungekippt ist das
#                      Normalenfeld auf allen Maßstäben deutlich wirbelfreier)
#   <tex>_orm.png      glTF-Anordnung: Rot Verdeckung (AO), Grün Rauheit, Blau Metall – aus RMA umsortiert
# Die GLB trägt nur Netz, UVs und Tangenten; das Material baut Lamp in Godot (Mat.pbr_model).
#
# Aufruf aus dem Projektordner (Blender 4.3; Pfade absolut, der Texturordner ist _Textures aus dem Download):
#   blender -b --python tools/build_desk_lamp.py -- assets/source/desk_lamp/SM_DeskLamp_Antique_01.fbx <download>/_Textures assets/models/desk_lamp.glb assets/textures/desk_lamp
import bpy, bmesh, sys, os
import numpy as np
from mathutils import Matrix

TEX_SIZE = 2048
## Teile, die in x und y schmaler sind (m), gehören zur Zugkette
CORD_THIN = 0.016

argv = sys.argv[sys.argv.index("--") + 1:]
SRC, TEX_DIR, DST, TEX = argv[0], argv[1], argv[2], argv[3]

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.fbx(filepath=SRC)   # Zentimeter, Objekt mit Maßstab 0,01 und 90° um X
meshes = [o for o in bpy.context.scene.objects if o.type == 'MESH']
for o in meshes:
	o.data.transform(o.matrix_world)
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

# Lose Teile: Liste aus (Ecken, Minimum, Maximum)
bm = bmesh.new()
bm.from_mesh(body.data)
bm.verts.ensure_lookup_table()
seen = set()
parts = []
for v in bm.verts:
	if v.index in seen:
		continue
	seen.add(v.index)
	stack, comp = [v], []
	while stack:
		x = stack.pop()
		comp.append(x)
		for e in x.link_edges:
			y = e.other_vert(x)
			if y.index not in seen:
				seen.add(y.index)
				stack.append(y)
	co = np.array([c.co for c in comp])
	parts.append((comp, co.min(0), co.max(0)))

shade = max(parts, key=lambda p: p[2][2])
drop, bulb = [], None
for p in parts:
	size = p[2] - p[1]
	if size[0] < CORD_THIN and size[1] < CORD_THIN:   # die Kette beginnt im Schirm, darum zuerst
		drop.append(p)
	elif p is not shade and np.all(p[1] >= shade[1]) and np.all(p[2] <= shade[2]):
		bulb = p
		drop.append(p)
print("Teile %d, entfernt %d (Birne %s, Kette %d)" % (len(parts), len(drop), bulb is not None, len(drop) - (bulb is not None)))
bmesh.ops.delete(bm, geom=[v for p in drop for v in p[0]], context='VERTS')
bm.to_mesh(body.data)
bm.free()

def bounds(o):
	co = np.array([v.co for v in o.data.vertices])
	return co.min(0), co.max(0)

# Fuß mittig auf den Ursprung, dann 180° um die Hochachse: Schirm nach Blender −Y = glTF/Godot +Z
foot = min(parts, key=lambda p: p[1][2])
cx, cy = (foot[1][0] + foot[2][0]) / 2.0, (foot[1][1] + foot[2][1]) / 2.0
lo, _ = bounds(body)
body.data.transform(Matrix.Rotation(np.pi, 4, 'Z') @ Matrix.Translation((-cx, -cy, -lo[2])))

def godot(b):   # Blender-Punkt des Originals → Godot nach Verschieben und Drehen
	return (-(b[0] - cx), b[2] - lo[2], b[1] - cy)

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

save("desk_lamp_albedo", load("T_DeskLamp_Antique_01_Albedo.png")[..., :3])
save("desk_lamp_normal", load("T_DeskLamp_Antique_01_Normal.png")[..., :3])
rma = load("T_DeskLamp_Antique_01_RMA.png")
save("desk_lamp_orm", np.stack([rma[..., 2], rma[..., 0], rma[..., 1]], axis=-1))

bpy.ops.export_scene.gltf(filepath=DST, export_format='GLB', export_yup=True, export_texcoords=True,
	export_normals=True, export_tangents=True, export_materials='NONE', export_animations=False)

lo2, hi2 = bounds(body)
print("%s: %d Dreiecke, %.3f breit, %.3f tief, %.3f hoch" % (body.name,
	sum(len(p.vertices) - 2 for p in body.data.polygons), *(hi2 - lo2)))
print("Godot: x %.3f..%.3f, z %.3f..%.3f" % (lo2[0], hi2[0], -hi2[1], -lo2[1]))
s0, s1 = godot(shade[1]), godot(shade[2])
print("Schirm (Godot): x %.3f..%.3f, y %.3f..%.3f, z %.3f..%.3f" % (min(s0[0], s1[0]), max(s0[0], s1[0]),
	s0[1], s1[1], min(s0[2], s1[2]), max(s0[2], s1[2])))
if bulb:
	b0, b1 = godot(bulb[1]), godot(bulb[2])
	print("Röhre (Godot): x %.3f..%.3f, y %.3f..%.3f, z %.3f..%.3f" % (min(b0[0], b1[0]), max(b0[0], b1[0]),
		b0[1], b1[1], min(b0[2], b1[2]), max(b0[2], b1[2])))
