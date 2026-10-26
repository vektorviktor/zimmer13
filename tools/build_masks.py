# Baut aus Meshys Masken (Bild-zu-3D, je ein Gesicht mit Farb-, Normal- und Rauheitskarte) das Spielmodell
# assets/models/masks.glb: je Maske ein Netz „mask_<id>“ in echter Größe (HEIGHT), Ursprung mittig auf der Rückseite
# (dort liegt sie am Gesicht bzw. an der Wand), Gesicht nach +Z (Godot). Netz unverändert (Meshy nicht ausdünnen),
# aber alles, was ganz hinter dem Gesicht liegt, fällt weg – Meshy schließt manche Masken hinten mit einer zweiten
# Schale zu (Kürbismann). Karten verkleinert auf TEX_SIZE, Lücken zwischen den UV-Inseln vorher gefüllt
# (meshy_tex.shrink), in Godot unkomprimiert eingebettet (meshy_tex.write_import, die .import liegt im Repo).
# Am Ende stehen die Maße je Maske – als MaskModel.SIZES übernehmen.
#
# Aufruf (Blender 4.3), je Maske id=quelle:
#   blender -b --python tools/build_masks.py -- assets/models/masks.glb pumpkin=assets/source/mask_pumpkin.glb doll=assets/source/mask_doll.glb
import bpy, bmesh, sys, os
from mathutils import Matrix

sys.path.append(os.path.dirname(os.path.abspath(__file__)))
import meshy_tex

## Höhe der Maske in Metern (Breite und Tiefe folgen dem Modell)
HEIGHT = {"pumpkin": 0.26, "doll": 0.24}
TEX_SIZE = 1024
## Punkte, die näher als das beieinanderliegen, gelten beim Suchen der Teile als einer (Meshy trennt an UV-Nähten)
WELD = 1e-4

argv = sys.argv[sys.argv.index("--") + 1:]
DST = argv[0]
SOURCES = [a.split("=", 1) for a in argv[1:]]

bpy.ops.wm.read_factory_settings(use_empty=True)


def parts(bm):
	"""Zusammenhängende Teile als Listen von Flächen – über die Lage der Punkte, nicht über die Kanten."""
	key = lambda co: (round(co.x / WELD), round(co.y / WELD), round(co.z / WELD))
	owner = {}
	parent = list(range(len(bm.faces)))

	def find(i):
		while parent[i] != i:
			parent[i] = parent[parent[i]]
			i = parent[i]
		return i
	for f in bm.faces:
		for v in f.verts:
			k = key(v.co)
			if k in owner:
				parent[find(f.index)] = find(owner[k])
			else:
				owner[k] = f.index
	groups = {}
	for f in bm.faces:
		groups.setdefault(find(f.index), []).append(f)
	return sorted(groups.values(), key=len, reverse=True)


def build(mask_id, src):
	before = set(bpy.data.objects)
	bpy.ops.import_scene.gltf(filepath=src)
	new = [o for o in bpy.data.objects if o not in before]
	obj = [o for o in new if o.type == 'MESH'][0]
	obj.data.transform(obj.matrix_world)
	obj.parent = None
	obj.matrix_world = Matrix.Identity(4)
	for o in new:
		if o != obj:
			bpy.data.objects.remove(o)
	obj.name = obj.data.name = "mask_" + mask_id

	bm = bmesh.new()
	bm.from_mesh(obj.data)
	bm.faces.ensure_lookup_table()
	groups = parts(bm)
	# Meshy-Gesicht blickt nach −Y (Blender) – was ganz hinter dem größten Teil liegt, ist eine Rückschale
	face_back = max(v.co.y for f in groups[0] for v in f.verts)
	behind = [f for g in groups[1:] if min(v.co.y for f in g for v in f.verts) > face_back for f in g]
	if behind:
		bmesh.ops.delete(bm, geom=behind, context='FACES')
	print("%s: %d Teile, %d Flächen hinter dem Gesicht entfernt" % (mask_id, len(groups), len(behind)))

	xs = [v.co.x for v in bm.verts]
	ys = [v.co.y for v in bm.verts]
	zs = [v.co.z for v in bm.verts]
	s = HEIGHT[mask_id] / (max(zs) - min(zs))
	bmesh.ops.transform(bm, verts=bm.verts, matrix=Matrix.Scale(s, 4) @
		Matrix.Translation((-(min(xs) + max(xs)) / 2.0, -max(ys), -(min(zs) + max(zs)) / 2.0)))
	bm.normal_update()
	bm.to_mesh(obj.data)
	bm.free()

	mat = obj.data.materials[0]
	mat.name = "mask_" + mask_id
	for n in mat.node_tree.nodes:
		if n.type == 'TEX_IMAGE' and n.image:
			img = n.image
			kind = "normal" if "normal" in img.name else "rough" if "metallic" in img.name else "color"
			meshy_tex.shrink(img, TEX_SIZE)
			img.name = "mask_%s_%s" % (mask_id, kind)
			img.file_format = 'PNG'
			img.pack()
	size = ((max(xs) - min(xs)) * s, HEIGHT[mask_id], (max(ys) - min(ys)) * s)
	print("%s: %d Dreiecke, %.3f × %.3f × %.3f m (B × H × T)" % ((mask_id,
		sum(len(p.vertices) - 2 for p in obj.data.polygons)) + size))
	return size


sizes = []
for mask_id, src in SOURCES:
	sizes.append('"%s": Vector3(%.3f, %.3f, %.3f)' % ((mask_id,) + build(mask_id, src)))

bpy.ops.object.select_all(action='SELECT')
bpy.ops.export_scene.gltf(filepath=DST, export_format='GLB', export_yup=True, export_tangents=True,
	export_image_format='AUTO', export_animations=False)
meshy_tex.write_import(DST)
print("SIZES := {%s}" % ", ".join(sizes))
