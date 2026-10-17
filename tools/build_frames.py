# Baut das Profil-Kit für Tür- und Fensterrahmen (Spielkonzept 7.2): Craftsman-Stil nach
# temp/doorframe.jpg – glatte Seitenbekleidung, darüber Leiste, Friesbrett und Abdeckung mit Kehle.
# Kein Ausgangsmodell: Jedes Teil ist ein 2D-Profil, 1 m lang ausgezogen. OpeningFrame setzt die
# Teile in Godot zusammen und streckt sie dabei nur in der Länge.
#
# Lage jedes Teils (Godot-Achsen): Länge entlang +X (0 … 1), Profil in Y (u, „quer“) und
# Z (v, „aus der Wand heraus“, Wandfläche bei v = 0, die Rückseite steckt BACK tief in der Wand). „board“ ist ein Einheitswürfel
# für Zarge und Fensterrahmen, der in allen drei Richtungen skaliert wird.
#
# Aufruf (Blender 4.3):
#   blender -b --python tools/build_frames.py -- assets/models/frames.glb [vorschau.png]
import bpy, bmesh, sys, math
from mathutils import Vector

# Profile als (u, v) in Metern, gegen den Uhrzeigersinn von (0, 0) aus
PROFILES = {
	# Seitenbekleidung: 9 cm breit, 2,2 cm stark, vorne leicht gefast
	"casing": [(0.0, 0.0), (0.09, 0.0), (0.09, 0.018), (0.086, 0.022), (0.004, 0.022), (0.0, 0.018)],
	# untere Leiste der Kopfpartie: steht vor, vordere Kante abgerundet
	"fillet": [(0.0, 0.0), (0.022, 0.0), (0.022, 0.026), (0.018, 0.032), (0.011, 0.034), (0.004, 0.032), (0.0, 0.026)],
	# Friesbrett: glatt wie die Bekleidung, oben und unten gefast
	"frieze": [(0.0, 0.0), (0.12, 0.0), (0.12, 0.018), (0.116, 0.022), (0.004, 0.022), (0.0, 0.018)],
	# Abdeckung: Kehle unter einer vorstehenden Platte, Oberkante gefast
	"cap": [(0.0, 0.0), (0.04, 0.0), (0.04, 0.05), (0.034, 0.056), (0.016, 0.056), (0.016, 0.042),
		(0.011, 0.038), (0.005, 0.031), (0.0, 0.024)],
	# Fensterbank innen: Nase vor der Wand, Oberkante bündig mit der Zarge
	"stool": [(0.0, 0.0), (0.028, 0.0), (0.028, 0.056), (0.022, 0.062), (0.008, 0.062), (0.0, 0.056)],
	"board": [(0.0, 0.0), (1.0, 0.0), (1.0, 1.0), (0.0, 1.0)],
}

# Alle Profile (außer „board“) reichen so weit hinter v = 0 in die Wand: Beim Vertex-Snapping rastet
# jedes Teil für sich ein – ohne Überlappung blitzt die Tapete durch die Fugen.
BACK = 0.015
for _name in PROFILES:
	if _name != "board":
		PROFILES[_name] = [(u, -BACK if v == 0.0 else v) for u, v in PROFILES[_name]]

argv = sys.argv[sys.argv.index("--") + 1:]
DST = argv[0]
PREVIEW = argv[1] if len(argv) > 1 else ""

bpy.ops.wm.read_factory_settings(use_empty=True)


## Godot (x, y, z) → Blender (x, −z, y); der glTF-Export dreht wieder zurück.
def to_blender(x, u, v):
	return (x, -v, u)


def extrude(name, profile):
	me = bpy.data.meshes.new(name)
	bm = bmesh.new()
	# Umlaufsinn so, dass die Normalen nach außen zeigen (Fläche des Profils positiv in (u, v))
	area = sum(profile[i][0] * profile[(i + 1) % len(profile)][1] - profile[(i + 1) % len(profile)][0] * profile[i][1]
		for i in range(len(profile)))
	pts = profile if area > 0 else list(reversed(profile))
	a = [bm.verts.new(to_blender(0.0, u, v)) for u, v in pts]
	b = [bm.verts.new(to_blender(1.0, u, v)) for u, v in pts]
	n = len(pts)
	for i in range(n):
		j = (i + 1) % n
		bm.faces.new((a[i], a[j], b[j], b[i]))
	bm.faces.new(list(reversed(a)))
	bm.faces.new(b)
	bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
	bmesh.ops.triangulate(bm, faces=bm.faces)
	bm.to_mesh(me)
	bm.free()
	for p in me.polygons:
		p.use_smooth = False
	ob = bpy.data.objects.new(name, me)
	bpy.context.scene.collection.objects.link(ob)
	return ob


for name, prof in PROFILES.items():
	ob = extrude(name, prof)
	print("%-7s %2d Ecken, %.3f breit, %.3f vor der Wand" % (name, len(prof), max(p[0] for p in prof), max(p[1] for p in prof)))

bpy.ops.export_scene.gltf(
	filepath=DST, export_format='GLB', export_yup=True, export_apply=False, export_materials='NONE',
	export_skins=False, export_animations=False, export_morph=False, export_cameras=False, export_lights=False)

# --- Vorschau: eine 1,2 × 2,1-m-Tür aus den Teilen, so wie OpeningFrame sie zusammensetzt ---------
if PREVIEW:
	W, H, CW = 1.2, 2.1, 0.09

	def place(src, loc, length, upright=False):
		ob = bpy.data.objects[src].copy()
		bpy.context.scene.collection.objects.link(ob)
		ob.scale = (length, 1.0, 1.0)
		if upright:
			ob.rotation_euler = (0.0, -math.pi / 2.0, 0.0)   # Länge nach oben, Profilbreite nach −X
		ob.location = loc
		return ob

	place("casing", (0.0, 0, 0), H, True)
	place("casing", (W + CW, 0, 0), H, True)
	y = H
	for name, ovh, hgt in (("fillet", 0.012, 0.022), ("frieze", 0.0, 0.12), ("cap", 0.035, 0.04)):
		place(name, (-CW - ovh, 0, y), W + 2 * (CW + ovh))
		y += hgt
	for name in PROFILES:
		bpy.data.objects[name].hide_render = True
	mat = bpy.data.materials.new("trim")
	mat.diffuse_color = (0.26, 0.14, 0.075, 1)
	mat.use_nodes = True
	mat.node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value = (0.26, 0.14, 0.075, 1)
	for ob in bpy.context.scene.objects:
		if ob.type == 'MESH':
			ob.data.materials.clear()
			ob.data.materials.append(mat)
	wall = bpy.data.objects.new("wall", bpy.data.meshes.new("wall"))
	bm = bmesh.new()
	bmesh.ops.create_grid(bm, x_segments=1, y_segments=1, size=2.0)
	bm.to_mesh(wall.data)
	bm.free()
	wall.rotation_euler = (math.pi / 2.0, 0, 0)
	wall.location = (W / 2, 0.001, 1.6)
	bpy.context.scene.collection.objects.link(wall)
	cam = bpy.data.objects.new("cam", bpy.data.cameras.new("cam"))
	bpy.context.scene.collection.objects.link(cam)
	cam.location = (W / 2 + 1.3, -4.6, 1.3)
	cam.rotation_euler = (math.radians(90), 0, math.radians(16))
	bpy.context.scene.camera = cam
	sun = bpy.data.objects.new("sun", bpy.data.lights.new("sun", 'SUN'))
	sun.rotation_euler = (math.radians(50), math.radians(-30), math.radians(-20))
	bpy.context.scene.collection.objects.link(sun)
	sc = bpy.context.scene
	sc.render.engine = 'BLENDER_WORKBENCH'
	sc.display.shading.light = 'STUDIO'
	sc.display.shading.color_type = 'MATERIAL'
	sc.display.shading.show_shadows = True
	sc.render.resolution_x, sc.render.resolution_y = 800, 800
	sc.render.filepath = PREVIEW
	bpy.ops.render.render(write_still=True)
