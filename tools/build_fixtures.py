# Baut aus den Rohmodellen des Nutzers (Bad und Bar, in assets/source/) die Spielmodelle in assets/models/:
#   washbasin.glb  – Waschplatz aus drei Objekten, Ursprung jeweils an der Wand: „table“ (Waschtisch, Ursprung
#                    auf der Oberkante), „basin“ (Aufsatzbecken mit Abfluss und Wandarmatur, Ursprung auf der
#                    Tischoberkante) und „mirror_frame“ (Spiegelrahmen, Ursprung unter seiner Mitte). Das
#                    Spiegelglas fällt weg – das Spiel setzt dort einen Mirror mit echtem Spiegelbild hin.
#   shower.glb     – Duschecke in Plangröße SHOWER_SIZE: Sockel, Wanne, Glaswand rechts, Glastür vorn, Pfosten,
#                    Scharniere, Abfluss und die Duschsäule an der Rückwand; Wände bei −X und hinten (−Z in Godot)
#                    fallen weg (die Zimmerwände stehen dort). Ursprung mittig unten, Tür nach +Z.
#   toilet.glb     – Wand-WC mit Drückerplatte und Papierhalter (rechts, +X). Ursprung an der Wand unter der
#                    Mitte der Schüssel, Sitzfläche nach +Z.
#   bar_counter.glb, back_bar.glb, bar_stool.glb – Theke (L-Form, Rückschenkel bei −X), Barregal, Hocker; nur
#                    umbenannt, Texturen verkleinert.
# Fliesen: Die Flächen „tiles“ (Waschtisch, Duschsockel) bekommen im Spiel die Badfliesen in Weltkoordinaten
# (LevelBuilder._bath_tiles) – alle ihre Maße sind Vielfache von 5 cm (Raster der früheren Badfliesen).
# Flächen: tiles, ceramic, steel, chrome, glass, brass, wood, wood_top, cushion, nozzles, paper, holder.
#
# Aufruf (Blender 4.3):
#   blender -b --python tools/build_fixtures.py -- assets/source assets/models
import bpy, sys, os, math
from mathutils import Matrix, Vector

SHOWER_SIZE = 1.1      # Meter, Duschfläche im Plan (Original 1,2 m)
SHOWER_LIFT = 0.04     # Wanne ganz auf den Sockel (Original 4 cm darin) → Sockel zeigt genau 2 Fliesenreihen
TOILET_SCALE = 0.85    # Schüssel im Original 0,63 × 0,42 m – zu groß
TOILET_SEAT = 0.42     # Sitzhöhe (LevelBuilder.BOX_HEIGHTS["toilet"]; im Original 0,60 m)
PLATE_GAP = 0.004      # Drückerplatte knapp vor die Wand: Die Fliesen liegen im Spiel auf der Wandfläche selbst
MIRROR_DEPTH = 0.04    # Rahmen tiefer (Original 2 cm): Das Spiegelbild liegt 3 cm vor der Wand (MIRROR_GAP)
WOOD_TEX = 512
SMALL_TEX = 256

argv = sys.argv[sys.argv.index("--") + 1:]
SRC, DST = argv[0], argv[1]


def reset():
	bpy.ops.wm.read_factory_settings(use_empty=True)


## Importiert eine GLB, wendet alle Transformationen an und gibt die Meshes zurück (ohne Leerobjekte).
def load(name):
	before = set(bpy.context.scene.objects)
	bpy.ops.import_scene.gltf(filepath=os.path.join(SRC, name))
	new = [o for o in bpy.context.scene.objects if o not in before]
	meshes = [o for o in new if o.type == 'MESH']
	for o in meshes:
		if o.data.users > 1:
			o.data = o.data.copy()
		o.data.transform(o.matrix_world)
	for o in meshes:
		o.parent = None
		o.matrix_world = Matrix.Identity(4)
	for o in new:
		if o.type != 'MESH':
			bpy.data.objects.remove(o)
	return meshes


def xform(objs, m):
	for o in objs:
		o.data.transform(m)
		o.data.update()


def points(objs):
	return [v.co.copy() for o in objs for v in o.data.vertices]


def bounds(objs):
	ps = points(objs)
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


## Ersetzt die Materialien nach names (alter Name → neuer). Farbtexturen werden auf tex_size verkleinert und als PNG
## eingebettet; Materialien ohne Textur behalten nur ihre Grundfarbe (das Spiel nimmt sie nach dem Namen).
def remap(objs, names, tex_size, prefix):
	made = {}
	for o in objs:
		for slot in o.material_slots:
			old = slot.material
			new_name = names[old.name.split(".")[0]]   # mehrfach importiert: „Steel_Brushed.001“
			if new_name not in made:
				bsdf = next(n for n in old.node_tree.nodes if n.type == 'BSDF_PRINCIPLED')
				m = bpy.data.materials.new(new_name)
				m.use_nodes = True
				p = m.node_tree.nodes["Principled BSDF"]
				img = _image_of(bsdf.inputs["Base Color"])
				if img:
					w, h = img.size
					if max(w, h) > tex_size:
						img.scale(tex_size if w >= h else max(1, tex_size * w // h), tex_size if h >= w else max(1, tex_size * h // w))
					img.file_format = 'PNG'
					img.name = prefix + new_name
					img.pack()
					tex = m.node_tree.nodes.new("ShaderNodeTexImage")
					tex.image = img
					tex.interpolation = 'Closest'
					m.node_tree.links.new(tex.outputs["Color"], p.inputs["Base Color"])
				else:
					p.inputs["Base Color"].default_value = bsdf.inputs["Base Color"].default_value
				made[new_name] = m
			slot.material = made[new_name]


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


def named(objs, *names):
	return [o for o in objs if o.name.split(".")[0] in names]


# Blender: Z oben, −Y = vorn (Godot +Z). Alle Maße unten in Godot-Achsen (x, y oben, z vorn).

def washbasin():
	reset()
	objs = load("wash_table.glb") + load("washbasin.glb") + load("wall_faucet.glb") + load("mirror.glb")
	xform(objs, Matrix.Translation((0, -0.2, 0)))   # Wand bei Blender-Y 0,2 → 0
	glass = named(objs, "Mirror_Glass")[0]
	g0, g1 = bounds([glass])
	frame = named(objs, "Mirror_Frame")[0]
	f0, f1 = bounds([frame])
	objs = [o for o in objs if o is not glass]
	bpy.data.objects.remove(glass)
	xform([frame], Matrix.Translation((0, 0, -f0.z)) @ Matrix.Diagonal((1, MIRROR_DEPTH / (f1.y - f0.y), 1, 1)))
	remap(objs, {"Plaster": "tiles", "Porcelain_White": "ceramic", "Steel_Brushed": "steel"}, SMALL_TEX, "washbasin_")
	table = named(objs, "WashTable")
	t0, t1 = bounds(table)
	basin = named(objs, "Washbasin")
	b0, b1 = bounds(basin)
	faucet = named(objs, "Faucet_Mixer", "Faucet_Spout")
	a0, a1 = bounds(faucet)
	join(table, "table")
	body = join(basin + named(objs, "Washbasin_Drain") + faucet, "basin")
	frame.name = frame.data.name = "mirror_frame"
	export("washbasin.glb")
	print("washbasin: Becken %d Dreiecke, Tisch %.2f × %.2f m, %.2f m stark (Oberkante = Ursprung), Becken %.2f × %.2f × %.3f m"
		% (tris([body]), t1.x - t0.x, t1.y - t0.y, t1.z - t0.z, b1.x - b0.x, b1.y - b0.y, b1.z - b0.z))
	print("  Armatur %.3f..%.3f m über dem Tisch, %.3f m vor der Wand" % (a0.z, a1.z, -a0.y))
	print("  Spiegelrahmen %d Dreiecke, %.2f × %.2f m, %.2f m tief; Glas %.2f × %.2f m, Mitte %.3f m über der Rahmenunterkante"
		% (tris([frame]), f1.x - f0.x, f1.z - f0.z, MIRROR_DEPTH, g1.x - g0.x, g1.z - g0.z, (g0.z + g1.z) / 2.0 - f0.z))


def shower():
	reset()
	objs = load("shower.glb")
	for o in named(objs, "Shower_Walls"):
		bpy.data.objects.remove(o)
	objs = [o for o in bpy.context.scene.objects if o.type == 'MESH']
	s = SHOWER_SIZE / 1.2
	xform(objs, Matrix.Diagonal((s, s, 1, 1)))
	xform([o for o in objs if not o.name.startswith("Shower_Plinth")], Matrix.Translation((0, 0, SHOWER_LIFT)))
	system = load("shower_system.glb")
	xform(system, Matrix.Translation((0, SHOWER_SIZE / 2.0 - bounds(system)[1].y, 0)))   # an die Rückwand
	objs += system
	remap(objs, {"Plaster": "tiles", "Porcelain_White": "ceramic", "Steel_Brushed": "steel", "Glass": "glass",
		"Steel_Brushed_Thermostat": "steel", "Nozzle_Plate": "nozzles"}, 128, "shower_")
	p0, p1 = bounds(named(objs, "Shower_Plinth"))
	w0, w1 = bounds(named(objs, "Shower_Tray"))
	side = named(objs, "Shower_Glass_Fixed")
	d0, d1 = bounds(named(objs, "Shower_Door"))
	gx = max(v.x for v in points(side))
	s0, s1 = bounds(system)
	shower_obj = join(objs, "shower")
	b0, b1 = bounds([shower_obj])
	export("shower.glb")
	print("shower: %d Dreiecke, Sockel %.3f × %.3f × %.3f m, Wanne bis %.3f m, Glas bis %.3f m"
		% (tris([shower_obj]), p1.x - p0.x, p1.y - p0.y, p1.z - p0.z, w1.z, b1.z))
	print("  Glaswand rechts bei x = %.3f, Tür vorn bei z = %.3f (Godot), Duschsäule %.3f m tief, %.3f..%.3f m hoch"
		% (gx, -d0.y, s1.y - s0.y, s0.z, s1.z))


def toilet():
	reset()
	objs = load("toilet.glb")
	mats = {o.name: o.material_slots[0].material.name for o in objs}
	bowl = [o for o in objs if mats[o.name] == "Cream_Ceramic"]
	wall_x = bounds(objs)[0].x
	c0, c1 = bounds(bowl)
	mid_y = (c0.y + c1.y) / 2.0
	xform(bowl, Matrix.Translation((wall_x, mid_y, 0)) @ Matrix.Scale(TOILET_SCALE, 4) @ Matrix.Translation((-wall_x, -mid_y, 0)))
	xform(bowl, Matrix.Translation((0, 0, TOILET_SEAT - bounds(bowl)[1].z)))
	# Wand bei x = 0, Schüssel mittig, dann Vorderseite (+X) nach −Y
	xform(objs, Matrix.Rotation(-math.pi / 2.0, 4, 'Z') @ Matrix.Translation((-wall_x, -mid_y, 0)))
	plate = [o for o in objs if o not in bowl and bounds([o])[0].z > 0.9]
	holder = [o for o in objs if o not in bowl and o not in plate]
	xform(plate, Matrix.Translation((0, -PLATE_GAP, 0)))
	remap(objs, {"Cream_Ceramic": "ceramic", "chrome_blurry": "chrome", "ROLOPH": "paper", "Material_11": "holder"},
		SMALL_TEX, "toilet_")
	b0, b1 = bounds(bowl)
	pl0, pl1 = bounds(plate)
	h0, h1 = bounds(holder)
	obj = join(objs, "toilet")
	export("toilet.glb")
	print("toilet: %d Dreiecke, Schüssel %.3f breit, %.3f tief, %.3f..%.3f m hoch (Sitz oben)"
		% (tris([obj]), b1.x - b0.x, -b0.y, b0.z, b1.z))
	print("  Drückerplatte x %.3f..%.3f, %.3f..%.3f m hoch; Papierhalter x %.3f..%.3f, %.3f..%.3f m hoch, %.3f vor der Wand"
		% (pl0.x, pl1.x, pl0.z, pl1.z, h0.x, h1.x, h0.z, h1.z, -h0.y))


def bar(src, dst, names, prefix):
	reset()
	objs = load(src)
	remap(objs, names, WOOD_TEX, prefix)
	parts = {o.name.split(".")[0]: bounds([o]) for o in objs}
	obj = join(objs, os.path.splitext(dst)[0])
	b0, b1 = bounds([obj])
	export(dst)
	print("%s: %d Dreiecke, x %.3f..%.3f, z %.3f..%.3f (Godot), %.3f m hoch"
		% (dst, tris([obj]), b0.x, b1.x, -b1.y, -b0.y, b1.z))
	return parts


def bars():
	wood = {"Wood_Body": "wood", "Wood_Top": "wood_top", "Brass": "brass", "Glass": "glass", "Cushion_Red": "cushion"}
	p = bar("bar_counter.glb", "bar_counter.glb", wood, "bar_")
	for k in ("Bar_Body", "Bar_Top"):
		lo, hi = p[k]
		print("  %s: x %.3f..%.3f, z %.3f..%.3f, %.3f..%.3f m hoch" % (k, lo.x, hi.x, -hi.y, -lo.y, lo.z, hi.z))
	p = bar("back_bar.glb", "back_bar.glb", wood, "bar_")
	for k in ("BackBar_Body", "BackBar_Top", "BackBar_GlassShelves", "BackBar_Upper"):
		lo, hi = p[k]
		print("  %s: x %.3f..%.3f, z %.3f..%.3f, %.3f..%.3f m hoch" % (k, lo.x, hi.x, -hi.y, -lo.y, lo.z, hi.z))
	p = bar("bar_stool.glb", "bar_stool.glb", wood, "bar_")
	print("  Sitz bis %.3f m" % p["Stool_Cushion"][1].z)


washbasin()
shower()
toilet()
bars()
