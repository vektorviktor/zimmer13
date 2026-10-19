# Baut aus Meshys Pflanzkübel (Granitbecken mit Erde, Steinen und großblättrigen Pflanzen) das Spielmodell
# assets/models/planter.glb: Becken genau 2 × 2 m (Meshy trifft das Quadrat nicht, x und y werden einzeln
# skaliert, die Höhe mit dem Mittel), Ursprung mittig unter dem Becken, Beckenwände an den Achsen, nur
# Farbtextur (TEX_SIZE, PNG). Die Unterseite fällt weg. Die Blätter sind einseitig – das Spiel zeichnet das
# Modell deshalb beidseitig (Mat.model(…, two_sided)).
# Am Ende steht die Höhe der Beckenkante – als LevelBuilder.PLANTER_H übernehmen (Kollision).
#
# Aufruf (Blender 4.3):
#   blender -b --python tools/build_planter.py -- assets/source/planter.glb assets/models/planter.glb
import bpy, bmesh, sys
from mathutils import Matrix

BASIN = 2.0       # Kantenlänge des Beckens in Metern
TEX_SIZE = 1024
LOW = 0.2         # Anteil der Gesamthöhe, unter dem nur das Becken liegt (Blätter beginnen darüber)
EDGE = 0.003      # Abstand zur Außenkante (Originaleinheiten), ab dem ein Punkt zur Beckenwand zählt

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
obj.name = obj.data.name = "planter"

bm = bmesh.new()
bm.from_mesh(obj.data)
bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=1e-5)
zs = [v.co.z for v in bm.verts]
z0, z1 = min(zs), max(zs)
low = [v.co for v in bm.verts if v.co.z < z0 + (z1 - z0) * LOW]
x0, x1 = min(c.x for c in low), max(c.x for c in low)
y0, y1 = min(c.y for c in low), max(c.y for c in low)

# Beckenkante: Oberkante der Außenwände (senkrechte, achsparallele Flächen auf dem Rand der Grundfläche –
# überhängende Blätter liegen nie ganz darauf)
def on_wall(c):
	return min(abs(c.x - x0), abs(x1 - c.x), abs(c.y - y0), abs(y1 - c.y)) < EDGE
walls = [f for f in bm.faces if max(abs(f.normal.x), abs(f.normal.y)) > 0.98 and all(on_wall(v.co) for v in f.verts)]
rim = max(v.co.z for f in walls for v in f.verts)

# Unterseite weg (liegt auf dem Boden)
bottom = [f for f in bm.faces if f.normal.z < -0.9 and f.calc_center_median().z < z0 + EDGE]
bmesh.ops.delete(bm, geom=bottom, context='FACES')

sx, sy = BASIN / (x1 - x0), BASIN / (y1 - y0)
sz = (sx + sy) / 2.0
bmesh.ops.transform(bm, verts=bm.verts, matrix=Matrix.Diagonal((sx, sy, sz, 1.0)) @
	Matrix.Translation((-(x0 + x1) / 2.0, -(y0 + y1) / 2.0, -z0)))
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
img.name = "planter"
img.pack()
mat = bpy.data.materials.new("planter")
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
print("planter: %d Dreiecke, Becken %.3f × %.3f Einheiten → Skalierung %.3f/%.3f/%.3f, Höhe %.2f m"
	% (tris, x1 - x0, y1 - y0, sx, sy, sz, (z1 - z0) * sz))
print("PLANTER_H := %.2f   # Beckenkante" % ((rim - z0) * sz))
