# Baut die offene Wanduhr über dem Haupteingang (LevelBuilder._clock, WallClock): Rahmen mit römischen Ziffern,
# Speichenkreuz und Nabe als „frame“, die beiden Zeiger als eigene Objekte „hour_hand“ und „minute_hand“, damit sie
# sich drehen können. Im Rohmodell sind die Zeiger mit dem Rahmen in einem Netz – sie werden als lose Teile
# gefunden: flach (dünner als HAND_DEPTH), über die Uhrmitte reichend und länger als HAND_MIN; der längere ist der
# Minutenzeiger. Beide werden auf 12 Uhr gedreht (Ruhelage = 0:00), WallClock dreht sie um lokal Z.
# Dazu kommt „dial“, eine runde Scheibe hinter allem (DIAL_INSET vor der Rückseite), die bis in die Mitte des äußeren
# Rings reicht – ihr Rand verschwindet dahinter, innen füllt sie die offene Uhr (WallClock färbt sie weiß).
#
# Lage (Godot-Achsen): Zifferblatt nach +Z, 12 Uhr nach +Y, Ursprung in der Uhrmitte auf der Rückseite (liegt an der
# Wand), Durchmesser DIAMETER Meter. Keine Texturen, Materialien „clock“ und „dial“ (das Spiel färbt sie).
#
# Aufruf (Blender 4.3):
#   blender -b --python tools/build_clock.py -- assets/source/clock.glb assets/models/clock.glb
import bpy, bmesh, sys, math
from mathutils import Matrix, Vector

DIAMETER = 2.0      # Meter
HAND_DEPTH = 1.0    # Originaleinheiten: Zeiger sind ~0,3 dick, Speichen und Nabe dicker
HAND_MIN = 15.0     # Originaleinheiten: kürzer sind Ziffernteile und der Stift
DIAL_INSET = 0.1    # Originaleinheiten vor der Rückseite (der äußere Ring ist 3 tief, Speichen beginnen 1,5 davor)
DIAL_SEGMENTS = 64

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
bpy.ops.object.select_all(action='DESELECT')
for o in meshes:
	o.select_set(True)
bpy.context.view_layer.objects.active = meshes[0]
bpy.ops.object.join()
frame = bpy.context.view_layer.objects.active
frame.name = frame.data.name = "frame"

# --- Achsen: die dünne Richtung ist die Tiefe (Blender −Y = glTF +Z ist vorn) ---------------------
vs = [v.co for v in frame.data.vertices]
lo = Vector([min(v[i] for v in vs) for i in range(3)])
hi = Vector([max(v[i] for v in vs) for i in range(3)])
size = hi - lo
depth_axis = min(range(3), key=lambda i: size[i])
assert depth_axis == 1, "Zifferblatt liegt nicht in der XZ-Ebene (Tiefe %d)" % depth_axis
center = (lo + hi) / 2.0
scale = DIAMETER / max(size.x, size.z)

# --- Lose Teile finden (Punkte gleicher Lage verschweißt) ---------------------------------------
bm = bmesh.new()
bm.from_mesh(frame.data)
bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=1e-4)
bm.faces.ensure_lookup_table()
seen, islands = set(), []
for f in bm.faces:
	if f.index in seen:
		continue
	stack, faces = [f], []
	seen.add(f.index)
	while stack:
		g = stack.pop()
		faces.append(g)
		for e in g.edges:
			for h in e.link_faces:
				if h.index not in seen:
					seen.add(h.index)
					stack.append(h)
	islands.append(faces)


def extent(faces):
	pts = {v for f in faces for v in f.verts}
	ys = [v.co.y for v in pts]
	plane = [Vector((v.co.x - center.x, v.co.z - center.z)) for v in pts]
	xs, zs = [p.x for p in plane], [p.y for p in plane]
	far = max(plane, key=lambda p: p.length)
	covers = min(xs) < 0 < max(xs) and min(zs) < 0 < max(zs)
	return max(ys) - min(ys), far, covers


hands = []
for faces in islands:
	d, far, covers = extent(faces)
	if d < HAND_DEPTH and covers and far.length > HAND_MIN:
		hands.append((far.length, far, faces))
assert len(hands) == 2, "%d Zeiger gefunden statt 2" % len(hands)
hands.sort(key=lambda h: h[0])

# Äußerer Ring = das Teil, das am weitesten hinausreicht; die Scheibe endet in seiner Mitte
ring = max(islands, key=lambda faces: extent(faces)[1].length)
radii = [Vector((v.co.x - center.x, v.co.z - center.z)).length for f in ring for v in f.verts]
dial_radius = (min(radii) + max(radii)) / 2.0

# --- Zeiger als eigene Objekte, auf 12 Uhr gedreht ----------------------------------------------
objects = []
for name, (length, far, faces) in zip(("hour_hand", "minute_hand"), hands):
	hb = bmesh.new()
	vmap = {}
	for f in faces:
		for v in f.verts:
			if v not in vmap:
				vmap[v] = hb.verts.new(v.co)
		hb.faces.new([vmap[v] for v in f.verts])
	me = bpy.data.meshes.new(name)
	hb.to_mesh(me)
	hb.free()
	me.materials.append(frame.data.materials[0])
	ob = bpy.data.objects.new(name, me)
	bpy.context.scene.collection.objects.link(ob)
	# Blender-Ebene x/z: 12 Uhr = +Z. Winkel des Zeigers gegen 12 Uhr im Uhrzeigersinn (von vorn, −Y, gesehen)
	angle = math.atan2(far.x, far.y)
	ob.data.transform(Matrix.Translation(center) @ Matrix.Rotation(-angle, 4, 'Y') @ Matrix.Translation(-center))
	objects.append((ob, length, math.degrees(angle)))
# --- Zifferblatt: Scheibe in der Ebene x/z, Vorderseite nach −Y ----------------------------------
db = bmesh.new()
bmesh.ops.create_circle(db, cap_ends=True, segments=DIAL_SEGMENTS, radius=dial_radius)
bmesh.ops.transform(db, verts=db.verts, matrix=Matrix.Translation((center.x, hi.y - DIAL_INSET, center.z))
	@ Matrix.Rotation(math.pi / 2.0, 4, 'X'))
dm = bpy.data.meshes.new("dial")
db.to_mesh(dm)
db.free()
dm.materials.append(bpy.data.materials.new("dial"))
dial = bpy.data.objects.new("dial", dm)
bpy.context.scene.collection.objects.link(dial)
frame.data.materials[0].name = "clock"

bmesh.ops.delete(bm, geom=[f for _, _, faces in hands for f in faces], context='FACES')
bmesh.ops.delete(bm, geom=[v for v in bm.verts if not v.link_faces], context='VERTS')
bm.to_mesh(frame.data)
bm.free()

# --- In Meter, Ursprung Mitte Rückseite (Blender +Y = hinten, glTF −Z) ---------------------------
fix = Matrix.Scale(scale, 4) @ Matrix.Translation(-Vector((center.x, hi.y, center.z)))
frame.data.transform(fix)
dial.data.transform(fix)
for ob, length, angle in objects:
	ob.data.transform(fix)
	print("%s: %.2f m lang, stand im Original bei %.0f° (von 12 Uhr im Uhrzeigersinn)" % (ob.name, length * scale, angle))
print("Zifferblatt: %.2f m Durchmesser (Ring innen %.2f, außen %.2f m)" % (
	2 * dial_radius * scale, 2 * min(radii) * scale, 2 * max(radii) * scale))
print("Uhr: %.2f m Durchmesser, %.3f m tief, %d Dreiecke Rahmen" % (
	max(size.x, size.z) * scale, size.y * scale, sum(len(p.vertices) - 2 for p in frame.data.polygons)))

bpy.ops.export_scene.gltf(
	filepath=DST, export_format='GLB', export_yup=True, export_apply=False,
	export_skins=False, export_animations=False, export_morph=False, export_cameras=False,
	export_lights=False, export_materials='PLACEHOLDER')
