# Baut aus Sketchfabs „Realistic Trees Collection“ (Jungle Jim, CC-BY 4.0) die drei großen Laubbäume als
# Spielmodelle assets/models/tree_1.glb … tree_3.glb: je Baum Äste und Blätter in einem Mesh mit zwei Materialien
# („bark“ und „leaves“), Ursprung auf der Stammachse am Boden, in Metern (SCALE), nur Farbtexturen (Normal Maps
# und zweite UV-Ebene fallen weg), verkleinert und als PNG eingebettet. Die Blätter sind Karten mit Alpha – das
# Spiel stanzt sie aus und zeichnet sie beidseitig (Mat.model(…, cutout = true)).
# Am Ende steht je Baum eine Zeile für LevelBuilder.TREE_MODELS (Kronenradius, Höhe, Krone von/bis, Stamm).
#
# Aufruf (Blender 4.3):
#   blender -b --python tools/build_trees.py -- assets/source/realistic_trees_collection.glb assets/models
import bpy, bmesh, sys
from mathutils import Matrix

TREES = ["EZTree0.Large", "EZTree1.Large001", "EZTree1.Large009"]   # tree_1, tree_2, tree_3
SCALE = 0.1        # Blender-Einheiten nach dem Import → Meter (ein Rohwert der Datei = 1 mm)
BARK_TEX = 512
LEAF_TEX = 512
FOOT = (0.0, 0.03)   # Höhenanteil, an dem die Stammachse gesucht wird (Stammfuß)
TRUNK_AT = 1.0       # Höhe (m), in der der Stammdurchmesser für die Kollision gemessen wird
CROWN_SKIP = 0.1

argv = sys.argv[sys.argv.index("--") + 1:]
SRC, DST_DIR = argv[0], argv[1]
results = []


def color_image(mat):
	for n in mat.node_tree.nodes:
		if n.type == 'BSDF_PRINCIPLED':
			link = n.inputs["Base Color"].links
			return link[0].from_node.image if link else None
	return None


def new_material(name, img, size, cutout):
	img.scale(size, size)
	img.file_format = 'PNG'
	img.name = name
	img.pack()
	# Die Originalmaterialien heißen auch „leaves“ – sonst würde das neue „leaves.003“, und das Spiel erkennt die
	# Blattkarten am Namen
	for old in [m for m in bpy.data.materials if m.name == name]:
		old.name = name + "_src"
	mat = bpy.data.materials.new(name)
	mat.use_nodes = True
	nodes = mat.node_tree.nodes
	tex = nodes.new("ShaderNodeTexImage")
	tex.image = img
	tex.interpolation = 'Closest'
	bsdf = nodes["Principled BSDF"]
	mat.node_tree.links.new(tex.outputs["Color"], bsdf.inputs["Base Color"])
	if cutout:
		mat.node_tree.links.new(tex.outputs["Alpha"], bsdf.inputs["Alpha"])
		mat.blend_method = 'CLIP'
	return mat


for index, tree in enumerate(TREES):
	bpy.ops.wm.read_factory_settings(use_empty=True)
	bpy.ops.import_scene.gltf(filepath=SRC)
	prefix = "Tree %s_" % tree
	parts = [o for o in bpy.context.scene.objects if o.type == 'MESH' and o.name.startswith(prefix)]
	for o in parts:
		o.data = o.data.copy()
		o.data.transform(o.matrix_world)
	for o in [o for o in bpy.context.scene.objects if o not in parts]:
		bpy.data.objects.remove(o)
	for o in parts:
		o.parent = None
		o.matrix_world = Matrix.Identity(4)
		# nur die UV-Ebene, die die Textur nutzt
		for uv in [uv for uv in o.data.uv_layers if not uv.active_render]:
			o.data.uv_layers.remove(uv)

	# Ein Material je Teil: Äste → bark, Blätter → leaves (Large001 hat zwei Blatt-Meshes mit derselben Textur)
	bark_src = next(o for o in parts if "_branches" in o.name).data.materials[0]
	leaf_src = next(o for o in parts if "_leaves" in o.name).data.materials[0]
	bark = new_material("bark", color_image(bark_src), BARK_TEX, False)
	leaves = new_material("leaves", color_image(leaf_src), LEAF_TEX, True)
	for o in parts:
		o.data.materials.clear()
		o.data.materials.append(leaves if "_leaves" in o.name else bark)

	bpy.context.view_layer.objects.active = parts[0]
	for o in parts:
		o.select_set(True)
	bpy.ops.object.join()
	obj = bpy.context.view_layer.objects.active
	obj.name = obj.data.name = "tree_%d" % (index + 1)

	bm = bmesh.new()
	bm.from_mesh(obj.data)
	bm.transform(Matrix.Scale(SCALE, 4))
	leaf_slot = list(obj.data.materials).index(leaves)
	wood = set(v for f in bm.faces if f.material_index != leaf_slot for v in f.verts)
	foliage = set(v for f in bm.faces if f.material_index == leaf_slot for v in f.verts)
	z0 = min(v.co.z for v in bm.verts)
	z1 = max(v.co.z for v in bm.verts)
	h = z1 - z0

	# Stammachse: Mitte der Astpunkte am Stammfuß
	foot = [v.co for v in wood if z0 + h * FOOT[0] <= v.co.z <= z0 + h * FOOT[1]]
	cx = (min(c.x for c in foot) + max(c.x for c in foot)) / 2.0
	cy = (min(c.y for c in foot) + max(c.y for c in foot)) / 2.0
	bm.transform(Matrix.Translation((-cx, -cy, -z0)))
	# Stammdicke in TRUNK_AT: nur Punkte nahe der Achse (Äste, die dort schon abgehen, zählen nicht)
	ring = [v.co for v in wood if abs(v.co.z - TRUNK_AT) < 0.15 and (v.co.x ** 2 + v.co.y ** 2) ** 0.5 < 1.0]
	trunk = 2.0 * max((c.x ** 2 + c.y ** 2) ** 0.5 for c in ring)
	# Krone: Mittel der halben Ausdehnung der Blätter in x und y; Höhenbereich ohne die untersten CROWN_SKIP
	# der Blattpunkte (einzelne tief hängende Zweige)
	crown = ((max(v.co.x for v in foliage) - min(v.co.x for v in foliage))
		+ (max(v.co.y for v in foliage) - min(v.co.y for v in foliage))) / 4.0
	zs = sorted(v.co.z for v in foliage)
	crown_z = (zs[int(len(zs) * CROWN_SKIP)] / h, zs[-1] / h)
	bm.normal_update()
	bm.to_mesh(obj.data)
	bm.free()

	dst = "%s/tree_%d.glb" % (DST_DIR, index + 1)
	bpy.ops.export_scene.gltf(filepath=dst, export_format='GLB', export_yup=True, export_image_format='AUTO',
		export_texcoords=True, export_normals=True, export_materials='EXPORT', export_animations=False)
	tris = sum(len(p.vertices) - 2 for p in obj.data.polygons)
	results.append((dst, tris, crown, h, crown_z, trunk))

for dst, tris, crown, h, crown_z, trunk in results:
	print("%s: %d Dreiecke" % (dst, tris))
	print('	{"path": "res://%s", "radius": %.1f, "height": %.1f, "crown": Vector2(%.2f, %.2f), "trunk": %.2f},'
		% (dst[dst.index("assets/"):], crown, h, crown_z[0], crown_z[1], trunk))
