# Baut aus Meshys Kürbisgruppe (assets/source/pumpkins.glb: ein Netz mit sechs Kürbissen, UV-Atlas, ohne Material)
# das Spielmodell assets/models/pumpkins.glb (Spielkonzept 5.8): ein glatter Halloween-Kürbis und fünf Fratzen.
#
# Aufruf (Blender 4.3):
#   blender -b --python tools/build_pumpkins.py -- assets/source/pumpkins.glb assets/models/pumpkins.glb
#
# Was passiert:
# - Die sechs Kürbisse werden eigene Objekte: „pumpkin_plain“ und „jack_o_lantern_1“ … „_5“, Ursprung mittig unten.
#   Meshys großer glatter Kürbis wird auf die Breite der geschnitzten verkleinert (~0,40 m).
# - Meshy trennt die Punkte an jeder UV-Naht, jede Insel hat eigene Normalen (Lichtkanten im Zickzack): verschweißt
#   und nach Winkel geglättet (SMOOTH_ANGLE), Schnittkanten bleiben hart.
# - Jede Fratze wird so gedreht, dass ihr Gesicht nach −Y zeigt (Godot +Z, Vorderseite der Items). Die Richtung
#   findet ein Strahltest aus der Mitte: Die geschnitzten Kürbisse sind hohl, durch die Öffnungen geht der Strahl ins Freie.
# - Prozedural texturiert und in einen gemeinsamen Atlas gebacken (Cycles, auf einer verbundenen Kopie – einzeln würde
#   der Randausgleich jedes Kürbisses die UV-Inseln der anderen überschreiben): Farbe (Schale orange, Stiel
#   bräunlich-grün, Fruchtfleisch an Schnittkanten und Innenwand), Rauheit (glTF-Grünkanal), Normal Map (Poren,
#   Stielfasern, körniges Fleisch) und als Emission die Glutmaske – so viel leuchtet das Fruchtfleisch mit Kerze.
# - In Godot unkomprimiert eingebettet (meshy_tex.write_import, die .import liegt im Repo).
import bpy, bmesh, sys, os, math
import numpy as np
from mathutils import Vector, Matrix
from mathutils.bvhtree import BVHTree
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import meshy_tex

TEX_BAKE = 2048           # so groß wird gebacken
TEX_SIZE = 1024           # so groß landet es in der GLB
SPACING = 0.6             # m, Abstand der Kürbisse in der Datei (das Spiel nimmt nur die Netze)
SMOOTH_ANGLE = 50         # Grad: steiler geknickte Kanten bleiben hart (Schnittkanten)
argv = sys.argv[sys.argv.index("--") + 1:]
SRC, DST = argv[0], argv[1]


def srgb(r, g, b):
	f = lambda c: c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4
	return (f(r), f(g), f(b), 1.0)


def smoothstep(e0, e1, x):
	t = np.clip((x - e0) / (e1 - e0), 0.0, 1.0)
	return t * t * (3 - 2 * t)


# --- Laden, in Blender-Achsen (Z oben) festschreiben ---------------------------------------------------------------
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=SRC)
src = [o for o in bpy.data.objects if o.type == "MESH"][0]
bpy.context.view_layer.objects.active = src
src.select_set(True)
bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
me = src.data
co = np.array([v.co[:] for v in me.vertices])

# --- Zusammenhängende Teile (UV-Nähte trennen die Punkte, also über gleiche Lage verschweißen) ------------------------
_, inv = np.unique(np.round(co, 4), axis=0, return_inverse=True)
par = np.arange(len(co))
def find(a):
	while par[a] != a:
		par[a] = par[par[a]]
		a = par[a]
	return a
first = {}
for i, k in enumerate(inv.ravel()):
	if k in first:
		par[find(i)] = find(first[k])
	else:
		first[k] = i
for e in me.edges:
	a, b = find(e.vertices[0]), find(e.vertices[1])
	if a != b:
		par[a] = b
roots = np.array([find(i) for i in range(len(co))])
comps = [np.where(roots == r)[0] for r in np.unique(roots)]
assert len(comps) == 6, len(comps)
def width(c):
	return (np.ptp(c[:, 0]) + np.ptp(c[:, 1])) / 2
comps.sort(key=lambda idx: -width(co[idx]))        # der große zuerst
small_w = np.mean([width(co[c]) for c in comps[1:]])
print("Breite groß %.3f, klein %.3f" % (width(co[comps[0]]), small_w))

# --- Einzelne Objekte, Ursprung mittig unten ---------------------------------------------------------------------
objs = []
for n, idx in enumerate(comps):
	ob = src.copy()
	ob.data = me.copy()
	bpy.context.collection.objects.link(ob)
	keep = np.zeros(len(co), bool)
	keep[idx] = True
	bm = bmesh.new()
	bm.from_mesh(ob.data)
	bm.verts.ensure_lookup_table()
	bmesh.ops.delete(bm, geom=[v for v in bm.verts if not keep[v.index]], context="VERTS")
	# Meshy trennt die Punkte an jeder UV-Naht, jede Insel hat eigene Normalen (Lichtkanten im Zickzack):
	# verschweißen (UVs hängen an den Ecken, bleiben) und weich nach Winkel – Schnittkanten bleiben scharf
	bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=1e-5)
	bm.to_mesh(ob.data)
	bm.free()
	ob.name = ob.data.name = "pumpkin_plain" if n == 0 else "jack_o_lantern_%d" % n
	objs.append(ob)
	bpy.ops.object.select_all(action="DESELECT")
	ob.select_set(True)
	bpy.context.view_layer.objects.active = ob
	bpy.ops.object.shade_smooth_by_angle(angle=math.radians(SMOOTH_ANGLE), keep_sharp_edges=False)
bpy.data.objects.remove(src)

face_angle_last = [0.0]


def face_angle(md):
	"""Richtung des Gesichts (Winkel in der Ebene, Bogenmaß): Strahlen aus der Mitte, die durch eine Öffnung ins Freie gehen."""
	bvh = BVHTree.FromPolygons([v.co for v in md.vertices], [p.vertices for p in md.polygons])
	h = max(v.co.z for v in md.vertices)
	center = Vector((0, 0, 0.45 * h))
	acc = Vector((0, 0))
	for az in range(0, 360, 2):
		for el in (-15, 0, 15, 30):
			a, e = math.radians(az), math.radians(el)
			d = Vector((math.cos(e) * math.cos(a), math.cos(e) * math.sin(a), math.sin(e)))
			if bvh.ray_cast(center, d, 10.0)[0] is None:
				acc += Vector((math.cos(a), math.sin(a)))
	assert acc.length > 0, "keine Öffnung gefunden"
	face_angle_last[0] = math.atan2(acc.y, acc.x)
	return face_angle_last[0]


for n, ob in enumerate(objs):
	c = np.array([v.co[:] for v in ob.data.vertices])
	mn, mx = c.min(0), c.max(0)
	base = Vector(((mn[0] + mx[0]) / 2, (mn[1] + mx[1]) / 2, mn[2]))
	s = small_w / width(c) if n == 0 else 1.0     # großer Kürbis auf die Breite der geschnitzten
	for v in ob.data.vertices:
		v.co = (v.co - base) * s
	ob.data.update()
	if n > 0:
		ob.data.transform(Matrix.Rotation(-math.pi / 2 - face_angle(ob.data), 4, "Z"))
		print(ob.name, "Gesicht war bei %.0f°" % math.degrees(face_angle_last[0]))
	ob.location = ((n - 2.5) * SPACING, 0, 0)
	ob.data.update()

# --- Merkmale je Punkt: Lage, Stiel, Fruchtfleisch -------------------------------------------------------------------
for n, ob in enumerate(objs):
	md = ob.data
	c = np.array([v.co[:] for v in md.vertices])
	nrm = np.array([v.normal[:] for v in md.vertices])
	R = width(c) / 2
	lp = c / R
	d = np.hypot(lp[:, 0], lp[:, 1])
	zs = lp[d > 0.5, 2].max()                     # Schulter: höchste Stelle des Körpers
	sl = lp[(lp[:, 2] > zs + 0.07) & (lp[:, 2] < zs + 0.16)]
	fc = sl[:, :2].mean(0)
	rf = np.percentile(np.hypot(*(sl[:, :2] - fc).T), 95)
	sd = np.hypot(*(lp[:, :2] - fc).T) / rf
	stem = np.maximum(smoothstep(zs + 0.02, zs + 0.06, lp[:, 2]),
		smoothstep(1.45, 1.1, sd) * smoothstep(zs - 0.3, zs - 0.18, lp[:, 2]))
	top = lp[:, 2].max()
	# Fruchtfleisch (nur geschnitzte): Innenwand zeigt zur Mitte, Schnittkanten liegen unter der Außenhaut
	carve = np.zeros(len(c))
	if n > 0:
		cen = np.array([0, 0, 0.45 * zs])
		v = lp - cen
		r = np.linalg.norm(v, axis=1)
		u = v / r[:, None]
		body = stem < 0.5
		cosang = u @ u[body].T
		env = np.where(cosang > math.cos(math.radians(14)), r[body][None, :], 0).max(1)
		depth = np.maximum(env - r, 0)
		nu = (nrm * u).sum(1)
		carve = np.maximum(smoothstep(0.08, 0.16, depth), smoothstep(0.05, -0.35, nu)) * (1 - stem)
	print(ob.name, "R %.3f zs %.2f top %.2f stem-r %.2f stem %d carve %d" % (R, zs, top, rf, (stem > 0.5).sum(), (carve > 0.5).sum()))
	for name, vals in (("stem", stem), ("carve", carve), ("sd", np.minimum(sd, 6.0)),
			("stemh", np.clip((lp[:, 2] - (zs - 0.25)) / (top - zs + 0.25), 0, 1))):
		a = md.attributes.new(name, "FLOAT", "POINT")
		a.data.foreach_set("value", vals.astype(np.float32))
	a = md.attributes.new("lp", "FLOAT_VECTOR", "POINT")
	a.data.foreach_set("vector", lp.astype(np.float32).ravel())

# --- Backmaterial --------------------------------------------------------------------------------------------------
mat = bpy.data.materials.new("pumpkin")
mat.use_nodes = True
nt = mat.node_tree
N, L = nt.nodes, nt.links
N.clear()


def node(t, **kw):
	nd = N.new(t)
	for k, v in kw.items():
		setattr(nd, k, v)
	return nd


def attr(name, out="Fac"):
	return node("ShaderNodeAttribute", attribute_name=name).outputs[out]


def put(sock, x):
	if isinstance(x, (int, float, tuple)):
		sock.default_value = x
	else:
		L.new(x, sock)


def math_(op, a, b=None):
	m = node("ShaderNodeMath", operation=op)
	put(m.inputs[0], a)
	if b is not None:
		put(m.inputs[1], b)
	return m.outputs[0]


def mix(fac, a, b):
	m = node("ShaderNodeMix", data_type="RGBA", clamp_factor=True)
	put(m.inputs[0], fac)
	put(m.inputs[6], a)
	put(m.inputs[7], b)
	return m.outputs[2]


def mixf(fac, a, b):
	m = node("ShaderNodeMix", data_type="FLOAT", clamp_factor=True)
	put(m.inputs[0], fac)
	put(m.inputs[2], a)
	put(m.inputs[3], b)
	return m.outputs[0]


def vmul(vec, sx, sy, sz):
	m = node("ShaderNodeVectorMath", operation="MULTIPLY")
	L.new(vec, m.inputs[0])
	m.inputs[1].default_value = (sx, sy, sz)
	return m.outputs[0]


def noise(vec, scale, detail=4.0, rough=0.55):
	t = node("ShaderNodeTexNoise")
	L.new(vec, t.inputs["Vector"])
	t.inputs["Scale"].default_value = scale
	t.inputs["Detail"].default_value = detail
	t.inputs["Roughness"].default_value = rough
	return t.outputs["Fac"]


def ramp(fac, lo, hi):
	m = node("ShaderNodeMapRange", clamp=True)
	L.new(fac, m.inputs["Value"])
	m.inputs["From Min"].default_value = lo
	m.inputs["From Max"].default_value = hi
	return m.outputs["Result"]


lp = attr("lp", "Vector")
stem, carve, sd, stemh = attr("stem"), attr("carve"), attr("sd"), attr("stemh")
lz = node("ShaderNodeSeparateXYZ")
L.new(lp, lz.inputs[0])
lz = lz.outputs["Z"]
ao_n = node("ShaderNodeAmbientOcclusion", only_local=True, samples=32)
ao_n.inputs["Distance"].default_value = 0.06
ao = ao_n.outputs["AO"]

# Schale: Orange, längs gestreift, fleckig, in den Rillen dunkler
streak = ramp(noise(vmul(lp, 7.0, 7.0, 0.6), 1.0, 3.0), 0.42, 0.68)
mottle = ramp(noise(lp, 9.0, 6.0, 0.6), 0.35, 0.7)
skin = mix(streak, srgb(0.86, 0.36, 0.03), srgb(0.97, 0.52, 0.08))
skin = mix(math_("MULTIPLY", mottle, 0.45), skin, srgb(0.99, 0.62, 0.16))
skin = mix(ramp(ao, 0.95, 0.55), skin, srgb(0.55, 0.17, 0.02))                   # Rillen
halo = math_("MULTIPLY", ramp(sd, 2.6, 1.2), ramp(noise(lp, 14.0), 0.3, 0.6))
skin = mix(math_("MULTIPLY", halo, 0.7), skin, srgb(0.58, 0.46, 0.08))           # grünlich um den Stielansatz
skin = mix(math_("MULTIPLY", ramp(lz, 0.18, 0.0), 0.5), skin, srgb(0.48, 0.30, 0.08))   # Unterseite erdig

# Stiel: unten grünlich, oben bräunlich-trocken, längs gefasert
fib = noise(vmul(lp, 30.0, 30.0, 2.5), 1.0, 5.0, 0.6)
stemc = mix(stemh, srgb(0.36, 0.40, 0.13), srgb(0.42, 0.31, 0.15))
stemc = mix(ramp(fib, 0.35, 0.7), srgb(0.20, 0.20, 0.07), stemc)
stemc = mix(ramp(stemh, 0.9, 1.0), stemc, srgb(0.56, 0.44, 0.26))                # trockene Schnittfläche oben
stemc = mix(ramp(ao, 0.9, 0.5), stemc, srgb(0.13, 0.11, 0.04))

# Fruchtfleisch: Schnittkante hellgelb, innen kräftiger, in der Tiefe dunkel
flesh = mix(ramp(noise(lp, 40.0), 0.3, 0.7), srgb(0.95, 0.66, 0.22), srgb(1.0, 0.80, 0.42))
flesh = mix(ramp(carve, 0.55, 1.0), srgb(1.0, 0.83, 0.48), flesh)
flesh = mix(ramp(ao, 0.9, 0.3), flesh, srgb(0.30, 0.12, 0.03))

col = mix(stem, mix(carve, skin, flesh), stemc)

# Rauheit: Schale wachsig glänzend, Stiel stumpf, Fruchtfleisch feucht
rough = mixf(stem, mixf(carve, math_("ADD", 0.36, math_("MULTIPLY", noise(lp, 12.0), 0.18)), 0.62), 0.85)

# Höhen für die Normal-Map: feine Poren, Fasern am Stiel, körniges Fleisch
h_skin = math_("ADD", math_("MULTIPLY", noise(lp, 30.0, 2.0, 0.4), 0.12), math_("MULTIPLY", streak, 0.2))
height = mixf(stem, mixf(carve, h_skin, math_("MULTIPLY", noise(lp, 45.0, 2.0, 0.4), 0.35)), math_("MULTIPLY", fib, 1.2))
bump = node("ShaderNodeBump")
bump.inputs["Strength"].default_value = 1.0
bump.inputs["Distance"].default_value = 0.0025
L.new(height, bump.inputs["Height"])

emit = node("ShaderNodeEmission")
bsdf = node("ShaderNodeBsdfPrincipled")
L.new(bump.outputs["Normal"], bsdf.inputs["Normal"])
out = node("ShaderNodeOutputMaterial")
for ob in objs:
	ob.data.materials.clear()
	ob.data.materials.append(mat)
# Gebacken wird auf eine verbundene Kopie: einzeln würde der Randausgleich jedes Kürbisses die UV-Inseln der anderen überschreiben
bpy.ops.object.select_all(action="DESELECT")
proxy = []
for ob in objs:
	cp = ob.copy()
	cp.data = ob.data.copy()
	bpy.context.collection.objects.link(cp)
	cp.select_set(True)
	proxy.append(cp)
bpy.context.view_layer.objects.active = proxy[0]
bpy.ops.object.join()
proxy = proxy[0]

# --- Backen --------------------------------------------------------------------------------------------------------
sc = bpy.context.scene
sc.render.engine = "CYCLES"
sc.cycles.device = "CPU"
sc.cycles.samples = 64
sc.render.bake.margin = 16
sc.render.bake.use_clear = True


def new_img(name, color):
	im = bpy.data.images.new(name, TEX_BAKE, TEX_BAKE, alpha=False)
	im.colorspace_settings.name = "sRGB" if color else "Non-Color"
	return im


tex = node("ShaderNodeTexImage")


def bake(img, socket, kind):
	tex.image = img
	N.active = tex
	if socket is not None:
		L.new(socket, emit.inputs["Color"])
		L.new(emit.outputs[0], out.inputs["Surface"])
	else:
		L.new(bsdf.outputs[0], out.inputs["Surface"])
	bpy.ops.object.select_all(action="DESELECT")
	proxy.select_set(True)
	bpy.context.view_layer.objects.active = proxy
	bpy.ops.object.bake(type=kind, normal_space="TANGENT")
	print("gebacken", img.name)


img_col = new_img("pumpkin_color", True)
img_rgh = new_img("pumpkin_rough", False)
img_nrm = new_img("pumpkin_normal", False)
img_glow = new_img("pumpkin_glow", True)
bake(img_col, col, "EMIT")
rgh_rgb = node("ShaderNodeCombineColor")
L.new(rough, rgh_rgb.inputs["Green"])                           # glTF: Rauheit im Grünkanal
bake(img_rgh, rgh_rgb.outputs[0], "EMIT")
bake(img_nrm, None, "NORMAL")
glow_rgb = node("ShaderNodeCombineColor")
for ch in ("Red", "Green", "Blue"):
	L.new(carve, glow_rgb.inputs[ch])                        # Glutmaske: Fruchtfleisch leuchtet mit Kerze
bake(img_glow, glow_rgb.outputs[0], "EMIT")

for im in (img_col, img_rgh, img_nrm, img_glow):
	if TEX_SIZE != TEX_BAKE:
		im.scale(TEX_SIZE, TEX_SIZE)
	im.pack()

bpy.data.objects.remove(proxy)

# --- Exportmaterial: nur noch die drei Bilder ------------------------------------------------------------------------
N.clear()
bsdf = node("ShaderNodeBsdfPrincipled")
out = node("ShaderNodeOutputMaterial")
L.new(bsdf.outputs[0], out.inputs["Surface"])
t_col = node("ShaderNodeTexImage", image=img_col)
L.new(t_col.outputs["Color"], bsdf.inputs["Base Color"])
t_rgh = node("ShaderNodeTexImage", image=img_rgh)
sp = node("ShaderNodeSeparateColor")
L.new(t_rgh.outputs["Color"], sp.inputs[0])
L.new(sp.outputs["Green"], bsdf.inputs["Roughness"])
bsdf.inputs["Metallic"].default_value = 0.0
t_nrm = node("ShaderNodeTexImage", image=img_nrm)
nm = node("ShaderNodeNormalMap")
L.new(t_nrm.outputs["Color"], nm.inputs["Color"])
L.new(nm.outputs["Normal"], bsdf.inputs["Normal"])
t_glow = node("ShaderNodeTexImage", image=img_glow)
L.new(t_glow.outputs["Color"], bsdf.inputs["Emission Color"])
bsdf.inputs["Emission Strength"].default_value = 1.0
for ob in objs:
	for a in ("stem", "carve", "sd", "stemh", "lp"):
		ob.data.attributes.remove(ob.data.attributes[a])

bpy.ops.object.select_all(action="SELECT")
bpy.ops.export_scene.gltf(filepath=DST, export_format="GLB", export_yup=True, export_tangents=True,
	export_image_format="AUTO", export_attributes=False)
print("geschrieben", DST)
meshy_tex.write_import(DST)
