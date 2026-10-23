# Baut aus „Old wooden table and chair“ (MaX3Dd, https://sketchfab.com/MaX3Dd, CC-BY 4.0,
# https://sketchfab.com/3d-models/old-wooden-table-and-chair-da18a40480ec42d6920a2a828d10018c) das Spielmodell
# assets/models/room_table.glb für die Tischgruppen in den Zimmern: zwei Objekte „table“ und „chair“, in Metern,
# Ursprung jeweils mittig unten. Der Tisch wird quadratisch – nur das Mittelstück zwischen den Beinen wird entlang
# der Länge gestaucht, Beine und Ecken bleiben unverzerrt – SIDE breit und TABLE_H hoch. Vom Original nimmt das
# Skript nur den gerade stehenden Stuhl, skaliert auf SEAT_H Sitzhöhe (im Original ist der Tisch für den Stuhl zu
# niedrig), Sitzseite nach +Z (Godot). Nur Farbtexturen (TEX_SIZE, PNG); Normal- und Rauheitskarten fallen weg.
# Am Ende stehen die Maße des Stuhls – für LevelBuilder.ROOM_CHAIR (Kollision und Abstand zum Tisch).
#
# Aufruf (Blender 4.3):
#   blender -b --python tools/build_room_table.py -- assets/source/old_wooden_table_and_chair.glb assets/models/room_table.glb
import bpy, sys
from mathutils import Matrix

SIDE = 1.0          # Meter, Tischplatte wie im Plan
TABLE_H = 0.75
SEAT_H = 0.46
TEX_SIZE = 512
LEG_INNER = 0.47    # Originaleinheiten: bis hierhin (|x|) reicht das Mittelstück ohne Beine

argv = sys.argv[sys.argv.index("--") + 1:]
SRC, DST = argv[0], argv[1]

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=SRC)
meshes = {o.name: o for o in bpy.context.scene.objects if o.type == 'MESH'}
table = next(o for n, o in meshes.items() if n.startswith("old_table"))
chair = meshes["chair_chair_0"]   # der gerade stehende; „chair001“ steht schräg
for o in (table, chair):
	o.data.transform(o.matrix_world)
	o.parent = None
	o.matrix_world = Matrix.Identity(4)
for o in [o for o in bpy.context.scene.objects if o not in (table, chair)]:
	bpy.data.objects.remove(o)

def bounds(o):
	vs = [v.co for v in o.data.vertices]
	return [min(v[i] for v in vs) for i in range(3)], [max(v[i] for v in vs) for i in range(3)]

# Tisch: Länge (x) auf die Tiefe (y) bringen, nur zwischen den Beinen stauchen
lo, hi = bounds(table)
cx, cy = (lo[0] + hi[0]) / 2.0, (lo[1] + hi[1]) / 2.0
cut = ((hi[0] - lo[0]) - (hi[1] - lo[1])) / 2.0
f = (LEG_INNER - cut) / LEG_INNER
for v in table.data.vertices:
	x = v.co.x - cx
	v.co.x = x * f if abs(x) <= LEG_INNER else x - cut * (1 if x > 0 else -1)
	v.co.y -= cy
lo, hi = bounds(table)
sxy = SIDE / (hi[1] - lo[1])
table.data.transform(Matrix.Diagonal((sxy, sxy, TABLE_H / (hi[2] - lo[2]), 1.0)) @ Matrix.Translation((0, 0, -lo[2])))

# Stuhl: Sitzoberkante = höchste nach oben zeigende Fläche im unteren Teil; Sitzseite zeigt schon nach −Y
lo, hi = bounds(chair)
seat = max(p.center.z for p in chair.data.polygons if p.normal.z > 0.9 and p.center.z < lo[2] + (hi[2] - lo[2]) * 0.6)
s = SEAT_H / (seat - lo[2])
chair.data.transform(Matrix.Scale(s, 4) @ Matrix.Translation((-(lo[0] + hi[0]) / 2.0, -(lo[1] + hi[1]) / 2.0, -lo[2])))

# Nur die Farbtexturen, verkleinert und als PNG eingebettet
for o, name in ((table, "table"), (chair, "chair")):
	o.data.update()
	img = None
	for n in o.data.materials[0].node_tree.nodes:
		if n.type == 'BSDF_PRINCIPLED':
			link = n.inputs["Base Color"].links
			img = link[0].from_node.image if link else None
	img.scale(TEX_SIZE, TEX_SIZE)
	img.file_format = 'PNG'
	img.name = "room_" + name
	img.pack()
	mat = bpy.data.materials.new(name)
	mat.use_nodes = True
	nodes = mat.node_tree.nodes
	tex = nodes.new("ShaderNodeTexImage")
	tex.image = img
	tex.interpolation = 'Closest'
	mat.node_tree.links.new(tex.outputs["Color"], nodes["Principled BSDF"].inputs["Base Color"])
	o.data.materials.clear()
	o.data.materials.append(mat)
	o.name = o.data.name = name

bpy.ops.export_scene.gltf(filepath=DST, export_format='GLB', export_yup=True, export_image_format='AUTO',
	export_texcoords=True, export_normals=True, export_materials='EXPORT', export_animations=False)

lo, hi = bounds(table)
print("table: %d Dreiecke, %.3f × %.3f × %.3f m (Mittelstück auf %.2f gestaucht)"
	% (sum(len(p.vertices) - 2 for p in table.data.polygons), hi[0] - lo[0], hi[1] - lo[1], hi[2], f))
lo, hi = bounds(chair)
back = [v.co for v in chair.data.vertices if v.co.z > SEAT_H + 0.05]
print("chair: %d Dreiecke, %.3f breit, %.3f tief, %.3f hoch, Faktor %.3f"
	% (sum(len(p.vertices) - 2 for p in chair.data.polygons), hi[0] - lo[0], hi[1] - lo[1], hi[2], s))
print("  Lehne Blender-Y %.3f..%.3f (+Y = hinten)" % (min(v.y for v in back), max(v.y for v in back)))
