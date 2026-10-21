# Baut den Handlauf der Einstiegstreppen im Pool (LevelBuilder._pool): ein Edelstahlrohr vom Umgang hoch, waagerecht
# übers Becken, die Treppe hinab und senkrecht auf die Stufe – die drei Knicke als echte Bögen. Kein Ausgangsmodell:
# Mittellinie als Polygonzug, an den Ecken mit Bögen ausgerundet, darum ein Rohr mit runden Querschnitt.
#
# Lage (Godot-Achsen): Ursprung am Fuß des Pfostens auf dem Umgang, die Treppe hinab entlang −Z, das Rohr in der
# Ebene x = 0. Maße wie bisher in _pool: Pfosten 0,9 m hoch, 0,45 m waagerecht, dann bis 0,9 m über die unterste Stufe
# und senkrecht hinab auf den Beckenboden. Tiefe und Lauflänge müssen zu _pool passen (Standard 1,4 m und 2,1 m).
#
# Aufruf (Blender 4.3):
#   blender -b --python tools/build_handrail.py -- assets/models/pool_handrail.glb [tiefe lauf] [vorschau.png]
import bpy, bmesh, sys, math
from mathutils import Vector

argv = sys.argv[sys.argv.index("--") + 1:]
DST = argv[0]
DEPTH = float(argv[1]) if len(argv) > 2 else 1.4
RUN = float(argv[2]) if len(argv) > 2 else 2.1
PREVIEW = argv[-1] if argv[-1].endswith(".png") else ""

RAIL_H = 0.9        # Höhe über Umgang bzw. unterster Stufe
TOP = 0.45          # waagerechtes Stück über dem Beckenrand
RADIUS = 0.025      # Rohr (wie die bisherigen _rod-Stangen)
SIDES = 10          # Ecken des Querschnitts
BEND = 0.15         # Biegeradius der Mittellinie
ARC_STEPS = 10      # Segmente je Bogen

# Mittellinie in Godot-Koordinaten (y nach oben, die Treppe hinab = −z)
low_z = -(RUN + 0.15)
CORNERS = [Vector((0, 0, 0)), Vector((0, RAIL_H, 0)), Vector((0, RAIL_H, -TOP)),
	Vector((0, RAIL_H - DEPTH, low_z)), Vector((0, -DEPTH, low_z))]


def fillet(pts):
	"""Polygonzug mit Bögen vom Radius BEND an jeder inneren Ecke."""
	out = [pts[0]]
	for i in range(1, len(pts) - 1):
		a, c, b = pts[i - 1], pts[i], pts[i + 1]
		d0 = (c - a).normalized()
		d1 = (b - c).normalized()
		turn = d0.angle(d1)
		if turn < 1e-4:
			out.append(c)
			continue
		t = BEND * math.tan(turn / 2.0)   # Abstand der Bogenenden von der Ecke
		assert t < (c - a).length and t < (b - c).length, "Bogen passt nicht an Ecke %d" % i
		p0 = c - d0 * t
		p1 = c + d1 * t
		# Mittelpunkt: von p0 senkrecht zu d0 in Richtung der Kurve
		inward = (d1 - d0).normalized()
		n0 = (inward - d0 * inward.dot(d0)).normalized()
		center = p0 + n0 * BEND
		v0 = p0 - center
		v1 = p1 - center
		for k in range(ARC_STEPS + 1):
			out.append(center + _slerp(v0, v1, k / ARC_STEPS))
	out.append(pts[-1])
	return out


def _slerp(a, b, f):
	"""Kreisbogen zwischen zwei gleich langen Vektoren (Vector.slerp normiert das Ergebnis)."""
	ang = a.angle(b)
	return (a * math.sin((1 - f) * ang) + b * math.sin(f * ang)) / math.sin(ang)


def to_blender(v):
	"""Godot (x, y, z) → Blender (x, −z, y); der glTF-Export dreht wieder zurück."""
	return Vector((v.x, -v.z, v.y))


path = fillet(CORNERS)
bpy.ops.wm.read_factory_settings(use_empty=True)
me = bpy.data.meshes.new("handrail")
bm = bmesh.new()
side = Vector((1, 0, 0))   # die Mittellinie liegt in der Ebene x = 0
rings = []
for i, p in enumerate(path):
	# Tangente: Mittel der angrenzenden Segmente (an den Enden das eine)
	t = Vector((0, 0, 0))
	if i > 0:
		t += (p - path[i - 1]).normalized()
	if i < len(path) - 1:
		t += (path[i + 1] - p).normalized()
	t.normalize()
	up = t.cross(side).normalized()
	ring = []
	for k in range(SIDES):
		a = 2.0 * math.pi * k / SIDES
		ring.append(bm.verts.new(to_blender(p + (side * math.cos(a) + up * math.sin(a)) * RADIUS)))
	rings.append(ring)
for r0, r1 in zip(rings, rings[1:]):
	for k in range(SIDES):
		j = (k + 1) % SIDES
		bm.faces.new((r0[k], r0[j], r1[j], r1[k]))
bm.faces.new(list(reversed(rings[0])))
bm.faces.new(rings[-1])
bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
bm.to_mesh(me)
bm.free()
for poly in me.polygons:
	poly.use_smooth = len(poly.vertices) == 4   # Rohr glatt, Endkappen flach
ob = bpy.data.objects.new("handrail", me)
bpy.context.scene.collection.objects.link(ob)
length = sum((b - a).length for a, b in zip(path, path[1:]))
print("Handlauf: %d Ringe, %d Dreiecke, Mittellinie %.2f m (Tiefe %.2f, Lauf %.2f)" % (
	len(rings), sum(len(p.vertices) - 2 for p in me.polygons), length, DEPTH, RUN))

bpy.ops.export_scene.gltf(
	filepath=DST, export_format='GLB', export_yup=True, export_apply=False, export_materials='NONE',
	export_skins=False, export_animations=False, export_morph=False, export_cameras=False, export_lights=False)

if PREVIEW:
	cam = bpy.data.objects.new("cam", bpy.data.cameras.new("cam"))
	bpy.context.scene.collection.objects.link(cam)
	cam.location = (3.2, 1.2, 0.0)
	cam.rotation_euler = (math.radians(90), 0, math.radians(90))
	cam.data.type = 'ORTHO'
	cam.data.ortho_scale = 3.2
	bpy.context.scene.camera = cam
	sc = bpy.context.scene
	sc.render.engine = 'BLENDER_WORKBENCH'
	sc.display.shading.light = 'STUDIO'
	sc.render.resolution_x, sc.render.resolution_y = 800, 800
	sc.render.filepath = PREVIEW
	bpy.ops.render.render(write_still=True)
