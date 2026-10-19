# Baut aus Meshys Laubbaum (dicker Stamm mit Wurzeln, Krone aus Blattbüscheln) das Spielmodell
# assets/models/tree.glb: Ursprung auf der Stammachse am Boden, Krone auf RADIUS skaliert (das Spiel
# skaliert weiter auf den Kronenradius aus dem Plan), nur Farbtextur (TEX_SIZE, PNG). Die Unterseite fällt
# weg. Die Blattbüschel sind teils offen – das Spiel zeichnet das Modell deshalb beidseitig.
# Am Ende stehen Höhe und Stammdicke – als LevelBuilder.TREE_RADIUS/TREE_TRUNK übernehmen (Kollision).
#
# Aufruf (Blender 4.3):
#   blender -b --python tools/build_tree.py -- assets/source/tree.glb assets/models/tree.glb
import bpy, bmesh, sys
from mathutils import Matrix

RADIUS = 5.0      # Kronenradius in Metern
TEX_SIZE = 1024
TRUNK = (0.1, 0.2)   # Höhenanteil, in dem nur der Stamm liegt (über den Wurzeln, unter den ersten Ästen)
EDGE = 0.003      # Abstand zum Boden (Originaleinheiten), ab dem eine Fläche zur Unterseite zählt

argv = sys.argv[sys.argv.index("--") + 1:]
SRC, DST = argv[0], argv[1]

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=SRC)
obj = [o for o in bpy.context.scene.objects if o.type == 'MESH'][0]
obj.data.transform(obj.matrix_world)
obj.parent = None
obj.matrix_world = Matrix.Identity(4)
for o in [o for o in bpy.context.scene.objects if o.type != 'MESH']:
	bpy.data.objects.remove(o)
obj.name = obj.data.name = "tree"

bm = bmesh.new()
bm.from_mesh(obj.data)
bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=1e-5)
zs = [v.co.z for v in bm.verts]
z0, z1 = min(zs), max(zs)

# Stammachse: Mitte der Punkte im reinen Stammstück
trunk = [v.co for v in bm.verts if z0 + (z1 - z0) * TRUNK[0] <= v.co.z <= z0 + (z1 - z0) * TRUNK[1]]
cx = (min(c.x for c in trunk) + max(c.x for c in trunk)) / 2.0
cy = (min(c.y for c in trunk) + max(c.y for c in trunk)) / 2.0
trunk_r = max(((c.x - cx) ** 2 + (c.y - cy) ** 2) ** 0.5 for c in trunk)
# Kronenradius: Mittel der halben Ausdehnung in x und y
crown = ((max(v.co.x for v in bm.verts) - min(v.co.x for v in bm.verts))
	+ (max(v.co.y for v in bm.verts) - min(v.co.y for v in bm.verts))) / 4.0

# Unterseite weg (liegt auf dem Boden)
bottom = [f for f in bm.faces if f.normal.z < -0.9 and f.calc_center_median().z < z0 + EDGE]
bmesh.ops.delete(bm, geom=bottom, context='FACES')

s = RADIUS / crown
bmesh.ops.transform(bm, verts=bm.verts, matrix=Matrix.Scale(s, 4) @ Matrix.Translation((-cx, -cy, -z0)))
bm.normal_update()
bm.to_mesh(obj.data)
bm.free()

# Nur die Farbtextur, verkleinert und als PNG eingebettet
src_mat = obj.data.materials[0]
img = None
for n in src_mat.node_tree.nodes:
	if n.type == 'BSDF_PRINCIPLED':
		link = n.inputs["Base Color"].links
		img = link[0].from_node.image if link else None
img.scale(TEX_SIZE, TEX_SIZE)
img.file_format = 'PNG'
img.name = "tree"
img.pack()
mat = bpy.data.materials.new("tree")
mat.use_nodes = True
nodes = mat.node_tree.nodes
tex = nodes.new("ShaderNodeTexImage")
tex.image = img
tex.interpolation = 'Closest'
mat.node_tree.links.new(tex.outputs["Color"], nodes["Principled BSDF"].inputs["Base Color"])
obj.data.materials.clear()
obj.data.materials.append(mat)

bpy.ops.export_scene.gltf(filepath=DST, export_format='GLB', export_yup=True, export_image_format='AUTO',
	export_texcoords=True, export_normals=True, export_materials='EXPORT', export_animations=False)

tris = sum(len(p.vertices) - 2 for p in obj.data.polygons)
print("tree: %d Dreiecke, Krone %.3f Einheiten → Skalierung %.3f, Höhe %.2f m" % (tris, crown, s, (z1 - z0) * s))
print("TREE_RADIUS := %.1f   TREE_TRUNK := %.2f   # Kronenradius, Stammdurchmesser" % (RADIUS, trunk_r * 2.0 * s))
