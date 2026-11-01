# Baut aus dem Sketchfab-Automaten („Arcade Machine“ von Tomas_Tew, https://sketchfab.com/Tomas_Tew, CC-BY 4.0,
# https://sketchfab.com/3d-models/arcade-machine-2d57b061781c480593841ca282f62a5f) das Spielmodell
# assets/models/arcade_machine.glb für die Videospielautomaten der Bar (ArcadeMachine, Spielkonzept 6.10):
# HEIGHT hoch, Front nach +Z (Godot), Ursprung mittig unter dem Rumpf. Nur das Netz – die Pac-Man-Bilder des
# Originals kommen nicht mit; die Gehäusebilder je Spiel malt tools/arcade_art.py in die UVs des Rumpfs.
# Teile: „cabinet“ (Rumpf mit Bildschirmrahmen, Schild und Bedienfeld), „screen“ (gewölbte Bildröhre, UVs wie im
# Original), „stick“ (Joystick: Fläche „stick_ball“ mit der Joystick-Textur, „stick_ring“ der Fuß),
# „button_a“/„button_b“ (das Original hat den zweiten Knopf doppelt – einer fällt weg).
# Am Ende stehen die Maße für ArcadeMachine (Rumpf, Bildschirm, Schild).
#
# Aufruf (Blender 4.3):
#   blender -b --python tools/build_arcade.py -- assets/source/arcade_machine/scene.gltf assets/models/arcade_machine.glb
import bpy, sys
from mathutils import Matrix, Vector

HEIGHT = 1.82       # Meter, so hoch wie der bisherige Kastenautomat

argv = sys.argv[sys.argv.index("--") + 1:]
SRC, DST = argv[0], argv[1]

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=SRC)
meshes = [o for o in bpy.context.scene.objects if o.type == 'MESH']
for o in meshes:
	o.data.transform(o.matrix_world)
	o.parent = None
	o.matrix_world = Matrix.Identity(4)
for o in [o for o in bpy.context.scene.objects if o.type != 'MESH']:
	bpy.data.objects.remove(o)
by_name = {o.name: o for o in meshes}
bpy.data.objects.remove(by_name.pop("pCylinder6_blinn6_0"))   # zweiter Knopf doppelt

# Im Original zeigt die Front nach +X: um −90° drehen → Front nach −Y (Blender −Y = Godot +Z)
rot = Matrix.Rotation(-1.5707963, 4, 'Z')
body = by_name["pCube1_blinn1_0"]
pts = [rot @ v.co for v in body.data.vertices]
x0, x1 = min(p.x for p in pts), max(p.x for p in pts)
y0, y1 = min(p.y for p in pts), max(p.y for p in pts)
z0, z1 = min(p.z for p in pts), max(p.z for p in pts)
s = HEIGHT / (z1 - z0)
xform = Matrix.Scale(s, 4) @ Matrix.Translation((-(x0 + x1) / 2.0, -(y0 + y1) / 2.0, -z0)) @ rot
for o in by_name.values():
	o.data.transform(xform)
	o.data.update()


def material(name):
	m = bpy.data.materials.new(name)
	m.use_nodes = True
	return m


def rename(o, name, mats):
	o.name = o.data.name = name
	o.data.materials.clear()
	for m in mats:
		o.data.materials.append(material(m))
	while len(o.data.uv_layers) > 1:
		o.data.uv_layers.remove(o.data.uv_layers[-1])


rename(body, "cabinet", ["cabinet"])
rename(by_name["pCylinder5_blinn2_0"], "screen", ["screen"])
rename(by_name["pCylinder3_blinn6_0"], "button_a", ["button"])
rename(by_name["pCylinder4_blinn6_0"], "button_b", ["button"])
# Joystick: Kugel mit Stange (Textur) und Fuß zu einem Netz mit zwei Flächen
ball, ring = by_name["pCylinder1_blinn3_0"], by_name["pCylinder1_blinn5_0"]
rename(ball, "stick", ["stick_ball"])
rename(ring, "stick_ring", ["stick_ring"])
for p in ring.data.polygons:
	p.material_index = 0
bpy.ops.object.select_all(action='DESELECT')
ball.select_set(True)
ring.select_set(True)
bpy.context.view_layer.objects.active = ball
bpy.ops.object.join()
stick = bpy.context.view_layer.objects.active
stick.name = stick.data.name = "stick"

bpy.ops.export_scene.gltf(filepath=DST, export_format='GLB', export_yup=True, export_texcoords=True,
	export_normals=True, export_tangents=True, export_materials='EXPORT', export_animations=False)

# Maße für ArcadeMachine (Godot: x = Blender x, y = Blender z, z = −Blender y)
def box(o, mat_filter=None):
	vs = [v.co for v in o.data.vertices]
	return [min(v[i] for v in vs) for i in range(3)], [max(v[i] for v in vs) for i in range(3)]

lo, hi = box(body)
print("arcade: %d Dreiecke, Faktor %.4f" % (sum(len(p.vertices) - 2 for o in bpy.data.objects for p in o.data.polygons), s))
print("  Rumpf: %.3f breit, %.3f tief (Godot z %.3f..%.3f), %.3f hoch" % (hi[0] - lo[0], hi[1] - lo[1], -hi[1], -lo[1], hi[2]))
scr = bpy.data.objects["screen"]
c = sum((v.co for v in scr.data.vertices), Vector()) / len(scr.data.vertices)
n = sum((p.normal for p in scr.data.polygons), Vector()).normalized()
slo, shi = box(scr)
print("  Bildschirm: Mitte Godot (%.3f, %.3f, %.3f), Normale (%.3f, %.3f, %.3f), %.3f breit, %.3f..%.3f hoch"
	% (c.x, c.z, -c.y, n.x, n.z, -n.y, shi[0] - slo[0], slo[2], shi[2]))
mid = sorted((v.co for v in scr.data.vertices if abs(v.co.x) < 0.01), key=lambda v: v.z)
print("  Bildschirm-Mittellinie: unten Godot (y %.3f, z %.3f), oben (y %.3f, z %.3f)" % (mid[0].z, -mid[0].y, mid[-1].z, -mid[-1].y))
# Rumpfmaße je Höhe: vorderste Kante (Godot z) – für die Kollision
for zh in [0.1, 0.5, 0.9, 0.95, 1.0, 1.2, 1.5, 1.6, 1.75]:
	band = [v.co for v in body.data.vertices if abs(v.co.z - zh) < 0.04]
	if band:
		print("  bei %.2f m: Godot z %.3f..%.3f" % (zh, -max(v.y for v in band), -min(v.y for v in band)))
