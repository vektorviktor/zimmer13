# Baut die Teile der Tafeln im Speisesaal (DiningTable, ZIM-157) im Look der Bücherregale (tools/build_bookshelf.py):
# Holz der Vertäfelung, Beine 15 × 15 cm mit je drei Furchen auf jeder Seite, Zargen 1 cm hinter der Außenfläche der
# Beine mit stehenden Mulden wie im Fries der Regale. Die Platte baut DiningTable selbst (glatt, beliebig groß).
#
# Eine Tafel hat im Spiel beliebige Größe: DiningTable setzt Beine und Zargen aus Teilen zusammen, die hier einmal
# gebaut und gemeinsam gebacken werden. Eine Zarge besteht aus Stücken von je einer Mulde (PITCH lang), die im Spiel
# aneinandergereiht und um wenige Prozent gestreckt werden, bis die Länge zwischen zwei Beinen aufgeht; die Holz-UV
# läuft über INSTANCE_CUSTOM (psx_photo, instance_shift) durch.
#
# Lage (Godot-Achsen), Boden y = 0:
#   „leg_corner“, „leg_mid“  Bein mittig um x = z = 0, bis unter die Platte (LEG_TOP); gebacken an einer Ecke (Zargen
#                            nach +x und −z) bzw. in der Mitte einer langen Seite (Zargen nach −x und +x)
#   „apron“, „apron_l“,      ein Stück Zarge von x = 0 bis PITCH, Außenfläche bei z = 0 (nach +Z), Mulde in der Mitte;
#   „apron_r“                apron_l stößt bei x = 0 an ein Bein, apron_r bei x = PITCH (eigene Verschattung)
#
# Aufruf aus dem Projektordner (Blender 4.3):
#   blender -b --python tools/build_dining_table.py -- assets/models/dining_table.glb assets/textures/dining_table
#   (schreibt das Modell sowie <tex>_ao.png und <tex>_normal.png)
import bpy, bmesh, sys, os, math, random
import numpy as np

sys.path.append(os.path.dirname(os.path.abspath(__file__)))
from furniture_kit import B, G, Part, setup_cycles, new_image, bake_material, bake, godot_normals, save_image, \
	paint_details, capsules, atlas_uv

argv = sys.argv[sys.argv.index("--") + 1:]
DST = os.path.abspath(argv[0])
TEX = os.path.abspath(argv[1])

# --- Maße (Meter) = DiningTable ----------------------------------------------------------------------------------
HEIGHT = 0.85             # Oberkante der Platte
TOP_T = 0.04              # Platte
LEG_TOP = HEIGHT - TOP_T
LEG = 0.15                # Bein im Quadrat
LEG_CHAMFER = 0.004       # Fase an den Kanten des Beins
APRON_SET = 0.01          # Zarge hinter der Außenfläche der Beine
APRON_T = 0.025
APRON_H = 0.10
APRON_Y0 = LEG_TOP - APRON_H
APRON_CHAMFER = 0.005     # Fase an der unteren Außenkante der Zarge
FLUTE_W = 0.016           # drei Furchen je Seite des Beins
FLUTE_GAP = 0.016
FLUTE_DEPTH = 0.005
FLUTE_Y = (0.08, APRON_Y0 - 0.04)   # von, bis (Enden der Furchen)
# Mulden wie im Fries der Bücherregale (NICHE_W, NICHE_H, NICHE_DEPTH, NICHE_PITCH)
PILL_W = 0.010
PILL_H = 0.045
PILL_DEPTH = 0.003
PITCH = 0.031

ATLAS = 2048
AO_DISTANCE = 0.08
AO_STRENGTH = 0.9
AO_SAMPLES = 128

bpy.ops.wm.read_factory_settings(use_empty=True)
random.seed(157)
H = LEG / 2.0
C = LEG_CHAMFER


## Fläche, deren Holz über die Zarge bzw. das Bein durchläuft (UV ohne Versatz, den setzt DiningTable je Instanz)
def run_face(part, pts, normal, piece, axis, group=0):
	part.offsets.setdefault(piece, (0.0, 0.0))
	part.face(pts, normal, piece, axis, group)


# --- Teile -------------------------------------------------------------------------------------------------------
## Bein: vier Seiten (Gruppe 1, Furchen) und vier Fasen, unten ein Deckel; oben liegt die Platte auf
def build_leg(name):
	p = Part(name)
	y0, y1 = 0.0, LEG_TOP
	for k in range(4):
		a = math.pi / 2.0 * k
		n = (math.sin(a), 0.0, math.cos(a))
		t = (math.cos(a), 0.0, -math.sin(a))   # quer über die Seite (von links nach rechts gesehen)
		# Seite zwischen den Fasen
		def at(s, y, out=H):
			return (n[0] * out + t[0] * s, y, n[2] * out + t[2] * s)
		run_face(p, [at(-H + C, y0), at(H - C, y0), at(H - C, y1), at(-H + C, y1)], n, ("leg",), "y", 1)
		# Fase zur nächsten Seite (rechts)
		a2 = a + math.pi / 2.0
		n2 = (math.sin(a2), 0.0, math.cos(a2))
		t2 = (math.cos(a2), 0.0, -math.sin(a2))
		e = (n[0] * H + t[0] * (H - C), n[2] * H + t[2] * (H - C))
		f = (n2[0] * H + t2[0] * (-H + C), n2[2] * H + t2[2] * (-H + C))
		mid = ((n[0] + n2[0]) / math.sqrt(2.0), 0.0, (n[2] + n2[2]) / math.sqrt(2.0))
		run_face(p, [(e[0], y0, e[1]), (f[0], y0, f[1]), (f[0], y1, f[1]), (e[0], y1, e[1])], mid, ("leg",), "y")
	ring = []
	for k in range(4):
		a = math.pi / 2.0 * k
		n = (math.sin(a), math.cos(a))
		t = (math.cos(a), -math.sin(a))
		for s in (-H + C, H - C):
			ring.append((n[0] * H + t[0] * s, 0.0, n[1] * H + t[1] * s))
	vs = [p.bm.verts.new(B(*q)) for q in ring]
	f = p.bm.faces.new(vs)
	f.normal_update()
	if f.normal.dot(B(0, -1, 0)) < 0:
		f.normal_flip()
	return p.finish()


## Stück Zarge von x = 0 bis PITCH: Außenfläche (Gruppe 4, Mulde), Fase unten außen, Unterseite, Innenseite
def build_apron(name):
	p = Part(name)
	x0, x1 = 0.0, PITCH
	y0, y1 = APRON_Y0, LEG_TOP
	zo, zi = 0.0, -APRON_T
	run_face(p, [(x0, y0 + APRON_CHAMFER, zo), (x1, y0 + APRON_CHAMFER, zo), (x1, y1, zo), (x0, y1, zo)], (0, 0, 1),
		("apron", "out"), "x", 4)
	q = 1.0 / math.sqrt(2.0)
	run_face(p, [(x0, y0, zo - APRON_CHAMFER), (x1, y0, zo - APRON_CHAMFER), (x1, y0 + APRON_CHAMFER, zo),
		(x0, y0 + APRON_CHAMFER, zo)], (0, -q, q), ("apron", "out"), "x")
	run_face(p, [(x0, y0, zi), (x1, y0, zi), (x1, y0, zo - APRON_CHAMFER), (x0, y0, zo - APRON_CHAMFER)], (0, -1, 0),
		("apron", "under"), "x")
	run_face(p, [(x0, y0, zi), (x1, y0, zi), (x1, y1, zi), (x0, y1, zi)], (0, 0, -1), ("apron", "in"), "x")
	return p.finish()


# --- Gemalte Formen ----------------------------------------------------------------------------------------------
## Furchen in den vier Seiten des Beins (Gruppe 1): quer über die Seite gemessen, mittig
FLUTES = [k * (FLUTE_W + FLUTE_GAP) for k in (-1, 0, 1)]


def paint_flutes(pts, n, px):
	up = np.array([0, 1.0, 0])
	t = np.cross(up, n)
	r = FLUTE_W / 2.0
	gs, gy, shade, mask = capsules(pts @ t, pts[:, 1], FLUTES, FLUTE_Y[0] + r, FLUTE_Y[1] - r, r, FLUTE_DEPTH, px)
	normals = n[None, :] - gs[:, None] * t[None, :] - gy[:, None] * up[None, :]
	normals /= np.linalg.norm(normals, axis=1, keepdims=True)
	return normals, shade, mask


## Mulde in der Mitte des Zargenstücks (Gruppe 4)
def paint_pill(pts, n, px):
	r = PILL_W / 2.0
	mid = (APRON_Y0 + APRON_CHAMFER + LEG_TOP) / 2.0
	gs, gy, shade, mask = capsules(pts[:, 0], pts[:, 1], [PITCH / 2.0], mid - PILL_H / 2.0 + r, mid + PILL_H / 2.0 - r,
		r, PILL_DEPTH, px)
	normals = n[None, :] - gs[:, None] * np.array([1.0, 0, 0])[None, :] - gy[:, None] * np.array([0, 1.0, 0])[None, :]
	normals /= np.linalg.norm(normals, axis=1, keepdims=True)
	return normals, shade, mask


PAINTERS = {"leg_corner": {1: paint_flutes}, "leg_mid": {1: paint_flutes},
	"apron": {4: paint_pill}, "apron_l": {4: paint_pill}, "apron_r": {4: paint_pill}}


# --- Bauen und zum Backen aufstellen -----------------------------------------------------------------------------
parts = {"leg_corner": build_leg("leg_corner"), "leg_mid": build_leg("leg_mid"),
	"apron": build_apron("apron"), "apron_l": build_apron("apron_l"), "apron_r": build_apron("apron_r")}
wood = list(parts.values())
atlas_uv(wood, 0.006, {4: 1.0, 1: 1.0})


def place(ob, x, z, yaw=0.0):
	ob.location = B(x, 0, z)
	ob.rotation_euler = (0, 0, yaw)


def caster(src, x, z, yaw=0.0, sx=1.0):
	ob = bpy.data.objects.new(src.name + "_caster", src.data)
	bpy.context.scene.collection.objects.link(ob)
	place(ob, x, z, yaw)
	ob.scale = (sx, 1, 1)
	return ob


def slab(name, x0, x1, z0, z1, y0, y1):
	bm = bmesh.new()
	bmesh.ops.create_cube(bm, size=1.0)
	for v in bm.verts:
		v.co = B(x0 + (v.co.x + 0.5) * (x1 - x0), y0 + (v.co.z + 0.5) * (y1 - y0), z1 - (v.co.y + 0.5) * (z1 - z0))
	me = bpy.data.meshes.new(name)
	bm.to_mesh(me)
	bm.free()
	ob = bpy.data.objects.new(name, me)
	bpy.context.scene.collection.objects.link(ob)
	return ob


# Zargenreihe nach +x (Außenfläche bei z = Bein außen − APRON_SET), Yaw der Zarge so, dass ihre Außenfläche nach n zeigt
ZO = H - APRON_SET
YAW = {(0, 1): 0.0, (1, 0): math.pi / 2.0, (0, -1): math.pi, (-1, 0): -math.pi / 2.0}
others = []
# Ecke bei (0, 0): Zargen vorn nach +x (apron_l, dann Stücke) und links nach −z (Außenfläche nach −x)
place(parts["leg_corner"], 0.0, 0.0)
place(parts["apron_l"], H, ZO)
for i in range(1, 10):
	others.append(caster(parts["apron"], H + i * PITCH, ZO))
for i in range(10):   # gedreht läuft das Stück nach +z
	others.append(caster(parts["apron"], -ZO, -H - (i + 1) * PITCH, YAW[(-1, 0)]))
others.append(slab("top_a", -H - 0.04, H + 0.4, -H - 0.4, H + 0.04, LEG_TOP, HEIGHT))
# Mitte einer langen Seite bei x = 2: Zargen links (apron_r endet am Bein) und rechts
XM = 2.0
place(parts["leg_mid"], XM, 0.0)
place(parts["apron_r"], XM - H - PITCH, ZO)
for i in range(1, 10):
	others.append(caster(parts["apron"], XM - H - (i + 1) * PITCH, ZO))
for i in range(10):
	others.append(caster(parts["apron"], XM + H + i * PITCH, ZO))
others.append(slab("top_b", XM - 0.5, XM + 0.5, -0.4, H + 0.04, LEG_TOP, HEIGHT))
# freies Stück bei x = 4, Nachbarn links und rechts
XF = 4.0
place(parts["apron"], XF, ZO)
for i in range(1, 6):
	others.append(caster(parts["apron"], XF - i * PITCH, ZO))
	others.append(caster(parts["apron"], XF + i * PITCH, ZO))
others.append(slab("top_c", XF - 0.4, XF + 0.4, -0.4, H + 0.04, LEG_TOP, HEIGHT))
others.append(slab("floor", -2.0, 6.0, -2.0, 2.0, -0.05, 0.0))


# --- Backen ------------------------------------------------------------------------------------------------------
sc = setup_cycles()
for ob in wood:
	ob.data.materials.append(bake_material("wood_src"))

sc.world.light_settings.distance = AO_DISTANCE
ao = bake(wood, 'AO', new_image("dining_ao", ATLAS, False, True), AO_SAMPLES)[..., 0]
print("AO: Mittel %.3f, dunkelster Wert %.3f" % (ao.mean(), ao.min()))
ao = 1.0 - AO_STRENGTH * (1.0 - np.clip(ao, 0, 1))
# die Normale ohne Drehung des Objekts (Objektraum) – die Teile stehen zum Backen teils gedreht
nrm = godot_normals(bake(wood, 'NORMAL', new_image("dining_nrm", ATLAS, False, True), 1, normal_space='OBJECT'))
for name, ob in parts.items():
	paint_details([ob], nrm, ao, PAINTERS[name])
save_image("dining_ao_out", ao, TEX + "_ao.png")
save_image("dining_normal_out", nrm * 0.5 + 0.5, TEX + "_normal.png")


# --- Export ------------------------------------------------------------------------------------------------------
for ob in others:
	bpy.data.objects.remove(ob)
for ob in wood:
	place(ob, 0.0, 0.0)
	ob.data.materials.clear()   # Holz setzt DiningTable (Mat.hotel_wood mit AO, Normale und instance_shift)
	if "group" in ob.data.attributes:
		ob.data.attributes.remove(ob.data.attributes["group"])
	tris = sum(len(p.vertices) - 2 for p in ob.data.polygons)
	print("%-10s %5d Dreiecke, UV-Sätze %s" % (ob.name, tris, [l.name for l in ob.data.uv_layers]))

bpy.ops.object.select_all(action='DESELECT')
for ob in wood:
	ob.select_set(True)
bpy.ops.export_scene.gltf(
	filepath=DST, export_format='GLB', export_yup=True, export_apply=False, use_selection=True,
	export_texcoords=True, export_normals=True, export_tangents=False, export_materials='NONE',
	export_skins=False, export_animations=False, export_morph=False, export_cameras=False, export_lights=False)
print("geschrieben:", DST, TEX + "_ao.png", TEX + "_normal.png")
