# Baut aus den Rohmodellen des Nutzers (Heizkeller, in assets/source/) die Spielmodelle in assets/models/:
#   boiler.glb – Kohlekessel, Ursprung mittig unten, Feuerklappe nach +Z (Godot). Zwei Objekte: „boiler“ (alles
#                außer der Klappe) und „fire_door“ (die Feuerklappe, Ursprung im Scharnier, geschlossen – das Spiel
#                dreht sie auf). Flächen: paint, rust (Farbtexturen), soot (Ruß im Feuerraum, nur Farbe).
#   pipes.glb  – Rohrbaukasten, alle Teile übereinander im Ursprung, Rohrachse = +X, Durchmesser 0,2 m:
#                straight_050/_100/_200 (von x = 0 bis zur Länge), elbow (Arme nach −X und +Y, je 0,25 m), tee
#                (−X, +X, +Y), cross (±X, ±Y), flange (Flansch mittig auf der Fuge, 5 cm), end_cap und end_open
#                (Rohrende bei x = 0, der Kragen sitzt auf den letzten 5 cm). Flächen: copper (Farbtextur), bolt
#                (Schrauben, nur Farbe – im Original ohne UVs), inside (Rohrinneres, nur Farbe).
# Die Rohmodelle bringen je Teil dieselben drei 2048er-Texturen mit (je 5 MB) – hier bleibt eine verkleinerte
# Farbtextur für alle Teile; Normal- und ORM-Karte fallen weg (das Spiel nimmt nur die Farbe, Mat.model).
#
# Aufruf (Blender 4.3):
#   blender -b --python tools/build_boiler.py -- assets/source assets/models
import bpy, sys, os
from mathutils import Matrix, Vector

TEX = 512
PIECES = {   # Rohdatei → Name im Baukasten
	"pipe_straight_050.glb": "straight_050",
	"pipe_straight_100.glb": "straight_100",
	"pipe_straight_200.glb": "straight_200",
	"pipe_elbow90.glb": "elbow",
	"pipe_tee.glb": "tee",
	"pipe_cross.glb": "cross",
	"pipe_flange.glb": "flange",
	"pipe_endcap.glb": "end_cap",
	"pipe_endopen.glb": "end_open",
}

argv = sys.argv[sys.argv.index("--") + 1:]
SRC, DST = argv[0], argv[1]


def reset():
	bpy.ops.wm.read_factory_settings(use_empty=True)


## Importiert eine GLB und gibt die Meshes mit ihrer Weltmatrix zurück (Leerobjekte fallen weg, Eltern gelöst).
def load(name):
	before = set(bpy.context.scene.objects)
	bpy.ops.import_scene.gltf(filepath=os.path.join(SRC, name))
	new = [o for o in bpy.context.scene.objects if o not in before]
	meshes = [(o, o.matrix_world.copy()) for o in new if o.type == 'MESH']
	for o, _ in meshes:
		if o.data.users > 1:
			o.data = o.data.copy()
		o.parent = None
		o.matrix_world = Matrix.Identity(4)
	for o in new:
		if o.type != 'MESH':
			bpy.data.objects.remove(o)
	return meshes


def bounds(objs):
	ps = [o.matrix_world @ v.co for o in objs for v in o.data.vertices]
	return (Vector([min(p[i] for p in ps) for i in range(3)]), Vector([max(p[i] for p in ps) for i in range(3)]))


def tris(objs):
	return sum(len(p.vertices) - 2 for o in objs for p in o.data.polygons)


def _image_of(socket):
	for link in socket.links:
		node = link.from_node
		if node.type == 'TEX_IMAGE':
			return node.image
		for inp in node.inputs:
			img = _image_of(inp)
			if img:
				return img
	return None


def _average(img):
	px = list(img.pixels)
	n = len(px) // 4
	return [sum(px[i::4]) / n for i in range(3)] + [1.0]


_made = {}


## Ersetzt die Materialien nach names (alter Name → neuer). Farbtexturen werden auf TEX verkleinert und als PNG
## eingebettet; Namen in flat bekommen nur eine Farbe (die mittlere ihrer Textur, sonst ihre Grundfarbe).
def remap(objs, names, flat, prefix):
	for o in objs:
		for slot in o.material_slots:
			old = slot.material
			new_name = names[old.name.split(".")[0]]
			if new_name not in _made:
				bsdf = next(n for n in old.node_tree.nodes if n.type == 'BSDF_PRINCIPLED')
				m = bpy.data.materials.new(new_name)
				m.use_nodes = True
				p = m.node_tree.nodes["Principled BSDF"]
				img = _image_of(bsdf.inputs["Base Color"])
				if img and new_name in flat:
					p.inputs["Base Color"].default_value = _average(img)
				elif img:
					w, h = img.size
					if max(w, h) > TEX:   # sonst bleibt das eingebettete Bild unangetastet (neu packen leert es)
						img.scale(TEX if w >= h else max(1, TEX * w // h), TEX if h >= w else max(1, TEX * h // w))
						img.file_format = 'PNG'
						img.pack()
					img.name = prefix + new_name
					tex = m.node_tree.nodes.new("ShaderNodeTexImage")
					tex.image = img
					tex.interpolation = 'Closest'
					m.node_tree.links.new(tex.outputs["Color"], p.inputs["Base Color"])
				else:
					p.inputs["Base Color"].default_value = bsdf.inputs["Base Color"].default_value
				_made[new_name] = m
			slot.material = _made[new_name]


def join(objs, name):
	bpy.ops.object.select_all(action='DESELECT')
	for o in objs:
		o.select_set(True)
	bpy.context.view_layer.objects.active = objs[0]
	bpy.ops.object.join()
	o = bpy.context.view_layer.objects.active
	o.name = o.data.name = name
	return o


def export(name):
	bpy.ops.export_scene.gltf(filepath=os.path.join(DST, name), export_format='GLB', export_yup=True,
		export_image_format='AUTO', export_texcoords=True, export_normals=True, export_materials='EXPORT',
		export_animations=False)


# Blender: Z oben, −Y = vorn (Godot +Z).

def boiler():
	reset()
	_made.clear()
	meshes = load("boiler.glb")
	door, hinge = next((o, mw) for o, mw in meshes if o.name.startswith("Boiler_FireDoor"))
	rest = [o for o, _ in meshes if o != door]
	for o, mw in meshes:
		if o != door:
			o.data.transform(mw)
	# Klappe in ihren eigenen Koordinaten (geschlossen), Objekt ins Scharnier
	door.location = hinge.to_translation()
	remap(rest + [door], {"Boiler_Paint": "paint", "Boiler_Rust": "rust", "Boiler_Soot": "soot"}, {"soot"}, "boiler_")
	body = join(rest, "boiler")
	door.name = door.data.name = "fire_door"
	b0, b1 = bounds([body])
	d0, d1 = bounds([door])
	angle = hinge.to_euler().z
	export("boiler.glb")
	print("boiler: %d + %d Dreiecke, x %.3f..%.3f, z %.3f..%.3f (Godot), %.3f m hoch" % (tris([body]), tris([door]),
		b0.x, b1.x, -b1.y, -b0.y, b1.z))
	print("  Klappe: Scharnier x %.3f, y %.3f, z %.3f (Godot), geschlossen x %.3f..%.3f, %.3f..%.3f m hoch; im Original %.0f° offen"
		% (hinge.to_translation().x, hinge.to_translation().z, -hinge.to_translation().y, d0.x, d1.x, d0.z, d1.z,
		angle * 57.2958))


def pipes():
	reset()
	_made.clear()
	parts = []
	for src, name in PIECES.items():
		meshes = load(src)
		for o, mw in meshes:
			o.data.transform(mw)
		objs = [o for o, _ in meshes]
		remap(objs, {"Pipe_CopperRust": "copper", "Pipe_Bolt_Rust": "bolt", "Pipe_Inside": "inside"}, {"bolt"}, "pipe_")
		parts.append(join(objs, name))
	for img in [i for i in bpy.data.images if i.users == 0]:
		bpy.data.images.remove(img)
	export("pipes.glb")
	for o in parts:
		lo, hi = bounds([o])
		print("  %-13s %4d Dreiecke, x %.3f..%.3f, y %.3f..%.3f, z %.3f..%.3f (Godot)" % (o.name, tris([o]),
			lo.x, hi.x, lo.z, hi.z, -hi.y, -lo.y))


boiler()
pipes()
