# Baut die Wandleuchte assets/models/wall_lamp.glb (Lamp._build_wall) in Spielgröße: runde Wandplatte in Anthrazit,
# davor ein 12-seitiger Zylinder als Abstandhalter, an seinem Ende ein geschlossener Ring waagerecht um die Glaskugel.
# Der Ring hält das Licht zur Seite ab, oben und unten fällt es als Fächer an die Wand (der Projektor des Lichts,
# Lamp._wall_fan, folgt RING_H und RING_OUT). Zwei Objekte unter „WallLamp“: „WallLamp_Body“ (Platte, Zylinder,
# Ring) und „WallLamp_Ball“ (die Kugel – das Spiel gibt ihr das leuchtende Material der Birne). Ursprung an der
# Wand, Kugel nach +Z (Godot). Am Ende steht die Mitte der Kugel – für Lamp.WALL_BALL.
#
# Aufruf (Blender 4.3):
#   blender -b --python tools/build_wall_lamp.py -- assets/models/wall_lamp.glb
import bpy, bmesh, sys, math
from mathutils import Matrix

PLATE_R = 0.084     # Wandplatte (m)
PLATE_T = 0.018
PLATE_BEVEL = 0.002
PLATE_SEGMENTS = 48
SPACER_R = 0.02     # Abstandhalter zwischen Platte und Ring, so lang sichtbar
SPACER_LEN = 0.05
SPACER_SIDES = 12
BALL_R = 0.067
BALL_SEGMENTS = 32
BALL_RINGS = 16
RING_IN = BALL_R + 0.002   # knapp um die Kugel – dazwischen ein Spalt, kein Durchscheinen
RING_OUT = 0.077
RING_H = 0.07
RING_SEGMENTS = 48
SPLIT_ANGLE = 25.0  # Grad: der Zylinder bleibt kantig (30° je Seite), Ring und Kugel rund
# Abstand der Kugelmitte von der Wand: Platte, Zylinder, Ring
CENTER = PLATE_T + SPACER_LEN + RING_OUT

argv = sys.argv[sys.argv.index("--") + 1:]
DST = argv[0]

bpy.ops.wm.read_factory_settings(use_empty=True)

# Blender: +Z oben, −Y aus der Wand (wird beim Export zu Godot +Y bzw. +Z)
TO_Y = Matrix.Rotation(math.radians(90), 4, 'X')   # Achse Z → −Y


def cylinder(bm, r, depth, segs, y_front):
	"""Zylinder entlang −Y, Vorderseite bei y_front (negativ = vor der Wand)."""
	geom = bmesh.ops.create_cone(bm, cap_ends=True, segments=segs, radius1=r, radius2=r, depth=depth)
	verts = geom["verts"]
	bmesh.ops.transform(bm, matrix=Matrix.Translation((0, y_front + depth / 2.0, 0)) @ TO_Y, verts=verts)
	return verts


def tube(bm, r_in, r_out, h, segs, y):
	"""Geschlossener Ring mit senkrechter Achse um (0, y, 0)."""
	rows = []
	for r, z in ((r_out, -h / 2), (r_out, h / 2), (r_in, h / 2), (r_in, -h / 2)):
		rows.append([bm.verts.new((r * math.cos(2 * math.pi * i / segs), y + r * math.sin(2 * math.pi * i / segs), z))
				for i in range(segs)])
	for k in range(4):
		a, b = rows[k], rows[(k + 1) % 4]
		for i in range(segs):
			j = (i + 1) % segs
			bm.faces.new((a[i], a[j], b[j], b[i]))


def finish(bm, name, smooth_all=False):
	bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
	for f in bm.faces:
		f.smooth = True
	mesh = bpy.data.meshes.new(name)
	bm.to_mesh(mesh)
	bm.free()
	ob = bpy.data.objects.new(name, mesh)
	bpy.context.scene.collection.objects.link(ob)
	if not smooth_all:
		mod = ob.modifiers.new("split", 'EDGE_SPLIT')
		mod.split_angle = math.radians(SPLIT_ANGLE)
		mod.use_edge_sharp = False
	return ob


def material(name, color, metallic, rough):
	m = bpy.data.materials.new(name)
	m.use_nodes = True
	bsdf = m.node_tree.nodes["Principled BSDF"]
	bsdf.inputs["Base Color"].default_value = color
	bsdf.inputs["Metallic"].default_value = metallic
	bsdf.inputs["Roughness"].default_value = rough
	return m


# Körper: Platte (vorne leicht gefast), Zylinder (steckt 3 mm in Platte und Ring), Ring
bm = bmesh.new()
plate = cylinder(bm, PLATE_R, PLATE_T, PLATE_SEGMENTS, -PLATE_T)
rim = [e for e in bm.edges if all(abs(v.co.y + PLATE_T) < 1e-6 for v in e.verts)
		and all(v.co.xz.length > PLATE_R - 1e-4 for v in e.verts)]
bmesh.ops.bevel(bm, geom=rim, offset=PLATE_BEVEL, segments=1, affect='EDGES')
ring_back = CENTER - math.sqrt(RING_OUT ** 2 - SPACER_R ** 2)   # wo die Außenseite des Rings den Zylinder trifft
cylinder(bm, SPACER_R, ring_back - PLATE_T + 0.006, SPACER_SIDES, -(ring_back + 0.003))
tube(bm, RING_IN, RING_OUT, RING_H, RING_SEGMENTS, -CENTER)
body = finish(bm, "WallLamp_Body")
body.data.materials.append(material("Lamp_Anthracite", (0.22, 0.22, 0.23, 1), 0.8, 0.45))

bm = bmesh.new()
bmesh.ops.create_uvsphere(bm, u_segments=BALL_SEGMENTS, v_segments=BALL_RINGS, radius=BALL_R)
bmesh.ops.translate(bm, vec=(0, -CENTER, 0), verts=bm.verts)
ball = finish(bm, "WallLamp_Ball", smooth_all=True)
ball.data.materials.append(material("Glass", (0.86, 0.96, 0.93, 1), 0.0, 0.04))

root = bpy.data.objects.new("WallLamp", None)
bpy.context.scene.collection.objects.link(root)
body.parent = root
ball.parent = root

bpy.ops.export_scene.gltf(filepath=DST, export_format='GLB', export_yup=True, export_apply=True,
		export_materials='EXPORT')
print("WALL_BALL = Vector3(0, 0, %.4f)" % CENTER)
print("Ring: halbe Höhe %.4f, außen %.4f" % (RING_H / 2, RING_OUT))
