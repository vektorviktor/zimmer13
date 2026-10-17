# Baut aus Meshys Lakengeist (ohne Skelett) den spielfertigen Geist (Spielkonzept 4.18):
# Skelett mit Armen und Fingern, eigene Gewichte, Blick nach −Z, Ursprung mittig unten,
# nur Farbtextur (verkleinert). Keine Animationen – Schweben, Handkreisen und Würgen macht der Code.
#
# Aufruf (Blender 4.3):
#   blender -b --python tools/build_ghost.py -- <meshy.glb> assets/models/ghost.glb [vorschau-ordner]
#
# Knochen: root → hem (unterer Saum) · spine → head · je Seite upper_arm → forearm → hand →
# thumb/index/middle/ring/pinky + 1…3 (Suffix .L/.R, L = Geist-links).
#
# Finger findet das Skript selbst: Haut ist in der Textur rötlich, das Laken grau. Je Hand ist die Haut ein
# zusammenhängendes Stück; das Handgelenk ist ihr Rand zum Ärmel. Fingerspitzen = die fünf am weitesten (über
# die Oberfläche gemessen) vom Handgelenk entfernten Spitzen. Jeder Finger folgt dem kürzesten Weg von der Spitze
# zurück. Die Finger liegen nebeneinander; der Daumen ist der äußere zur Körpermitte hin (die Hände greifen
# mit dem Handrücken nach oben), die übrigen folgen nach außen. Knöchel liegen anteilig auf dem Weg (KNUCKLE_AT). Die Beugeachse (lokal X) jedes Fingers
# steht so, dass positive Drehung die Finger zur Handfläche krümmt.
# Gewichte: Hautpunkte gehören zum Finger mit dem nächsten Weg (über die Oberfläche), dort zum nächsten
# Glied; Handfläche zur Hand. Laken nach Abstand zu den Armen bzw. nach Höhe (Saum, Rumpf, Kopf).
import bpy, bmesh, sys, os, math, heapq
from mathutils import Vector, Matrix
from mathutils.geometry import intersect_point_line

TEX_SIZE = 512
MERGE_DIST = 0.0005
## Haut: rötlicher als das graue Laken (r − (g + b) / 2)
SKIN_SAT = -0.035
## Fingerspitzen: mindestens so weit auseinander (m), so viele je Hand
TIP_SPACING = 0.035
FINGERS = ["thumb", "index", "middle", "ring", "pinky"]
## Knöchel: so weit (Anteil des Wegs Spitze → Handgelenk) von der Spitze entfernt; der Daumen beginnt am Gelenk
KNUCKLE_AT = 0.6
THUMB_KNUCKLE_AT = 0.85
## Anteile der drei Fingerglieder (Knöchel → Spitze)
PHALANX = (0.45, 0.30, 0.25)
## Weicher Übergang an jedem Fingergelenk (± m)
JOINT_BLEND = 0.012
## Laken an den Armen: voller Einfluss bis ARM_INNER, keiner mehr ab ARM_OUTER (m)
ARM_INNER = 0.13
ARM_OUTER = 0.26

argv = sys.argv[sys.argv.index("--") + 1:]
SRC, DST = argv[0], argv[1]
PREVIEW = argv[2] if len(argv) > 2 else ""

# --- Laden, Punkte verschmelzen, ausrichten ----------------------------------------------------
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=SRC)
body = [o for o in bpy.context.scene.objects if o.type == 'MESH'][0]
body.name = body.data.name = "ghost"
scene = bpy.context.scene

bm = bmesh.new()
bm.from_mesh(body.data)
bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=MERGE_DIST)
# Meshy schaut nach −Y; Godot erwartet glTF −Z = Blender +Y → 180° um Z. Dann Ursprung mittig unten.
bmesh.ops.rotate(bm, verts=bm.verts, cent=Vector(), matrix=Matrix.Rotation(math.pi, 3, 'Z'))
lo = Vector([min(v.co[i] for v in bm.verts) for i in range(3)])
hi = Vector([max(v.co[i] for v in bm.verts) for i in range(3)])
bmesh.ops.translate(bm, verts=bm.verts, vec=-Vector(((lo.x + hi.x) / 2, (lo.y + hi.y) / 2, lo.z)))
bm.to_mesh(body.data)
bm.free()
height = hi.z - lo.z
print("Geist: %d Punkte, %d Dreiecke, %.2f m hoch" % (len(body.data.vertices), len(body.data.polygons), height))

# --- Haut erkennen ----------------------------------------------------------------------------
img = [n for n in body.active_material.node_tree.nodes if n.type == 'TEX_IMAGE' and
       any(l.to_socket.name == 'Base Color' for o in n.outputs for l in o.links)][0].image
probe = img.copy()
probe.scale(512, 512)
PW = 512
pix = probe.pixels[:]


def tex(uv):
	x = min(PW - 1, max(0, int(uv.x % 1.0 * PW)))
	y = min(PW - 1, max(0, int(uv.y % 1.0 * PW)))
	i = (y * PW + x) * 4
	return pix[i], pix[i + 1], pix[i + 2]


me = body.data
uvs = me.uv_layers.active.data
sat_sum = [0.0] * len(me.vertices)
sat_n = [0] * len(me.vertices)
for loop in me.loops:
	r, g, b = tex(uvs[loop.index].uv)
	sat_sum[loop.vertex_index] += r - (g + b) / 2
	sat_n[loop.vertex_index] += 1
skin = [sat_sum[i] / max(1, sat_n[i]) > SKIN_SAT for i in range(len(me.vertices))]
co = [v.co.copy() for v in me.vertices]
nbr = [[] for _ in co]
for e in me.edges:
	a, b = e.vertices
	d = (co[a] - co[b]).length
	nbr[a].append((b, d))
	nbr[b].append((a, d))

# Hautinseln: die zwei größten vorn (+Y) sind die Hände
seen = [False] * len(co)
islands = []
for i in range(len(co)):
	if not skin[i] or seen[i]:
		continue
	stack, part = [i], []
	seen[i] = True
	while stack:
		a = stack.pop()
		part.append(a)
		for b, _ in nbr[a]:
			if skin[b] and not seen[b]:
				seen[b] = True
				stack.append(b)
	islands.append(part)
islands.sort(key=len, reverse=True)
front = [p for p in islands if sum(co[i].y for i in p) / len(p) > 0.15][:2]
assert len(front) == 2, "Hände nicht gefunden: %s" % [len(p) for p in islands[:6]]
# Geist-links = Blender −X, wenn er nach +Y schaut
hands = {}
for part in front:
	side = "L" if sum(co[i].x for i in part) < 0 else "R"
	hands[side] = set(part)
print("Hände: L %d, R %d Hautpunkte" % (len(hands["L"]), len(hands["R"])))


def dijkstra(sources, allowed):
	dist = {s: 0.0 for s in sources}
	prev = {}
	heap = [(0.0, s) for s in sources]
	while heap:
		d, a = heapq.heappop(heap)
		if d > dist.get(a, 1e9):
			continue
		for b, w in nbr[a]:
			if b in allowed and d + w < dist.get(b, 1e9):
				dist[b] = d + w
				prev[b] = a
				heapq.heappush(heap, (d + w, b))
	return dist, prev


def centroid(idx):
	return sum((co[i] for i in idx), Vector()) / len(idx)


rig = {}   # Knochenname → (kopf, schwanz, eltern)
finger_paths = {}
roll_to = {}   # Seite → Richtung zur Handfläche (lokal Z der Hand- und Fingerknochen)
for side, part in hands.items():
	wrist_ring = [i for i in part if any(not skin[b] for b, _ in nbr[i])]
	wrist = centroid(wrist_ring)
	dist, prev = dijkstra(wrist_ring, part)
	# Spitzen: lokale Maxima der Entfernung, weit genug auseinander
	order = sorted(part, key=lambda i: -dist.get(i, 0.0))
	tips = []
	for i in order:
		ring = [b for b, _ in nbr[i]] + [c for b, _ in nbr[i] for c, _ in nbr[b]]
		if any(dist.get(b, 0.0) > dist[i] + 1e-6 for b in ring):
			continue
		if all((co[i] - co[t]).length > TIP_SPACING for t in tips):
			tips.append(i)
		if len(tips) == 5:
			break
	assert len(tips) == 5, "%s: nur %d Fingerspitzen" % (side, len(tips))
	paths = []
	for t in tips:
		path = [t]
		while path[-1] in prev:
			path.append(prev[path[-1]])
		paths.append(path)   # Spitze → Handgelenk
	# Reihenfolge quer zur Hand (x der Wegmitte), vom Daumen (zur Körpermitte) nach außen
	mid_x = [co[p[len(p) // 2]].x for p in paths]
	inward = sorted(range(5), key=lambda k: -mid_x[k] if side == "L" else mid_x[k])
	thumb, rest = inward[0], inward[1:]
	names = {k: FINGERS[n] for n, k in enumerate(inward)}
	# Knöchel anteilig auf dem Weg
	knuckles = [0] * 5
	for k, path in enumerate(paths):
		f = THUMB_KNUCKLE_AT if k == thumb else KNUCKLE_AT
		total = dist[path[0]]
		cut = len(path) - 1
		for n, i in enumerate(path):
			if total - dist[i] >= f * total:
				cut = n
				break
		knuckles[k] = cut
	kn = [co[paths[k][knuckles[k]]] for k in range(5)]
	palm = sum((kn[k] for k in rest), Vector()) / 4
	# Handflächenseite: Normale der Ebene Handgelenk/Knöchel, zu den (gekrümmten) Spitzen hin
	palm_side = (kn[rest[0]] - wrist).cross(kn[rest[-1]] - wrist).normalized()
	tips_mean = sum((co[t] for t in tips), Vector()) / 5
	if (tips_mean - palm).dot(palm_side) < 0.0:
		palm_side = -palm_side
	roll_to[side] = palm_side
	s = "." + side
	sx = -1.0 if side == "L" else 1.0
	shoulder = Vector((sx * 0.17, wrist.y * 0.05, height * 0.72))
	elbow = shoulder.lerp(wrist, 0.5) + Vector((sx * 0.03, 0.0, -0.06))
	rig["upper_arm" + s] = (shoulder, elbow, "spine")
	rig["forearm" + s] = (elbow, wrist, "upper_arm" + s)
	rig["hand" + s] = (wrist, palm, "forearm" + s)
	for k, path in enumerate(paths):
		finger = path[:knuckles[k] + 1][::-1]   # Knöchel → Spitze
		pts = [co[i] for i in finger]
		lengths = [0.0]
		for a, b in zip(pts, pts[1:]):
			lengths.append(lengths[-1] + (b - a).length)
		total = lengths[-1]

		def at(f):
			target = f * total
			for n in range(1, len(pts)):
				if lengths[n] >= target:
					t = (target - lengths[n - 1]) / max(1e-6, lengths[n] - lengths[n - 1])
					return pts[n - 1].lerp(pts[n], t)
			return pts[-1]
		marks = [0.0, PHALANX[0], PHALANX[0] + PHALANX[1], 1.0]
		parent = "hand" + s
		for g in range(3):
			bone = "%s%d%s" % (names[k], g + 1, s)
			rig[bone] = (at(marks[g]), at(marks[g + 1]), parent)
			parent = bone
		finger_paths[(side, names[k])] = finger
	print("%s: Handgelenk %s, Finger %s" % (side, tuple(round(c, 3) for c in wrist),
		", ".join("%s %.1f cm" % (names[k], (co[paths[k][0]] - co[paths[k][knuckles[k]]]).length * 100) for k in range(5))))

rig["root"] = (Vector((0, 0, 0)), Vector((0, 0, height * 0.1)), None)
rig["hem"] = (Vector((0, 0, height * 0.45)), Vector((0, 0, 0.0)), "root")
rig["spine"] = (Vector((0, 0, height * 0.45)), Vector((0, 0, height * 0.78)), "root")
rig["head"] = (Vector((0, 0, height * 0.78)), Vector((0, 0, height)), "spine")

# --- Armatur ----------------------------------------------------------------------------------
arm_data = bpy.data.armatures.new("Ghost")
arm = bpy.data.objects.new("Ghost", arm_data)
scene.collection.objects.link(arm)
bpy.context.view_layer.objects.active = arm
bpy.ops.object.mode_set(mode='EDIT')
edit = {}
for name, (h, t, _) in rig.items():
	eb = arm_data.edit_bones.new(name)
	eb.head, eb.tail = h, t
	if (t - h).length < 0.002:
		eb.tail = h + Vector((0, 0.003, 0))
	edit[name] = eb
for name, (_, _, parent) in rig.items():
	if parent:
		edit[name].parent = edit[parent]
		edit[name].use_connect = False
	side = name[-1] if name[-2:] in (".L", ".R") else ""
	if side and not name.startswith(("upper_arm", "forearm")):
		edit[name].align_roll(roll_to[side])
bpy.ops.object.mode_set(mode='OBJECT')

# --- Gewichte ---------------------------------------------------------------------------------
groups = {name: body.vertex_groups.new(name=name) for name in rig}


def seg(p, h, t):
	_, f = intersect_point_line(p, h, t)
	return (p - h.lerp(t, min(max(f, 0.0), 1.0))).length


def smooth(a, b, x):
	t = min(max((x - a) / (b - a), 0.0), 1.0)
	return t * t * (3 - 2 * t)


weights = [dict() for _ in co]
# Haut: Finger nach nächstem Fingerweg (über die Oberfläche), sonst Hand
for side, part in hands.items():
	s = "." + side
	sources, label = [], {}
	for (fs, fname), path in finger_paths.items():
		if fs != side:
			continue
		for i in path[1:]:   # ohne Knöchelpunkt – der gehört zur Hand
			sources.append(i)
			label[i] = fname
	dist, prev = dijkstra(sources, part)
	for i in part:
		root_i = i
		while root_i in prev:
			root_i = prev[root_i]
		fname = label.get(root_i)
		p = co[i]
		hand_h, hand_t, _ = rig["hand" + s]
		if fname is None or dist.get(i, 1e9) > 0.02:
			weights[i] = {"hand" + s: 1.0}
			continue
		# Lage entlang des Fingers (Bogenlänge ab Knöchel), Gelenke weich gemischt
		bones = ["%s%d%s" % (fname, g, s) for g in (1, 2, 3)]
		start, along, best = 0.0, 0.0, 1e9
		joints = []
		for b in bones:
			h, t, _ = rig[b]
			_, f = intersect_point_line(p, h, t)
			f = min(max(f, 0.0), 1.0)
			d = (p - h.lerp(t, f)).length
			if d < best:
				best, along = d, start + f * (t - h).length
			start += (t - h).length
			joints.append(start)
		j1, j2 = joints[0], joints[1]
		a = smooth(j1 - JOINT_BLEND, j1 + JOINT_BLEND, along)
		c = smooth(j2 - JOINT_BLEND, j2 + JOINT_BLEND, along)
		k = smooth(0.0, JOINT_BLEND, along)   # Fingeransatz mischt mit der Hand
		weights[i] = {"hand" + s: 1.0 - k, bones[0]: k * (1.0 - a), bones[1]: k * a * (1.0 - c), bones[2]: k * a * c}

# Laken: Arme nach Abstand, Rest nach Höhe
for i, p in enumerate(co):
	if skin[i] and any(i in part for part in hands.values()):
		continue
	w = {}
	best = 0.0
	for side in ("L", "R"):
		s = "." + side
		for bone in ("upper_arm" + s, "forearm" + s):
			h, t, _ = rig[bone]
			a = 1.0 - smooth(ARM_INNER, ARM_OUTER, seg(p, h, t))
			if a > 0.0:
				w[bone] = w.get(bone, 0.0) + a
				best = max(best, a)
	rest = 1.0 - best
	if rest > 0.0:
		z = p.z / height
		hem = 1.0 - smooth(0.35, 0.55, z)
		head = smooth(0.74, 0.84, z)
		spine = max(0.0, 1.0 - hem - head)
		for bone, x in (("hem", hem), ("spine", spine), ("head", head)):
			if x > 0.0:
				w[bone] = w.get(bone, 0.0) + x * rest
	total = sum(w.values())
	weights[i] = {b: x / total for b, x in w.items()}

for i, w in enumerate(weights):
	for bone, x in w.items():
		if x > 0.001:
			groups[bone].add([i], x, 'REPLACE')
body.parent = arm
mod = body.modifiers.new("skin", 'ARMATURE')
mod.object = arm
print("Knochen: %d" % len(rig))

# --- Material: nur Farbtextur ---------------------------------------------------------------
for mat in bpy.data.materials:
	if not mat.use_nodes:
		continue
	nodes = mat.node_tree.nodes
	bsdf = [n for n in nodes if n.type == 'BSDF_PRINCIPLED'][0]
	for n in list(nodes):
		if n.type in ('TEX_IMAGE', 'NORMAL_MAP', 'SEPARATE_COLOR') and not any(
				l.to_socket == bsdf.inputs['Base Color'] for o in n.outputs for l in o.links):
			nodes.remove(n)
	bsdf.inputs['Metallic'].default_value = 0.0
	bsdf.inputs['Roughness'].default_value = 1.0
	bsdf.inputs['Emission Strength'].default_value = 0.0
	for n in nodes:
		if n.type == 'TEX_IMAGE':
			n.image.name = "ghost_sheet"
			n.image.scale(TEX_SIZE, TEX_SIZE)
for image in list(bpy.data.images):
	if image.users == 0:
		bpy.data.images.remove(image)

bpy.ops.export_scene.gltf(
	filepath=DST, export_format='GLB', export_yup=True, export_apply=False,
	export_skins=True, export_animations=False, export_morph=False,
	export_cameras=False, export_lights=False,
	export_image_format='JPEG', export_jpeg_quality=85)

# --- Vorschau: Ruhepose, Finger gekrümmt (Würgen), Arme gehoben ------------------------------------
if PREVIEW:
	os.makedirs(PREVIEW, exist_ok=True)
	scene.render.engine = 'BLENDER_WORKBENCH'
	scene.display.shading.light = 'STUDIO'
	scene.display.shading.color_type = 'TEXTURE'
	scene.render.resolution_x, scene.render.resolution_y = 700, 500
	cam = bpy.data.objects.new("cam", bpy.data.cameras.new("cam"))
	cam.data.clip_start = 0.01
	scene.collection.objects.link(cam)
	scene.camera = cam

	def shot(name, target, offset, lens=50):
		cam.data.lens = lens
		cam.location = target + offset
		cam.rotation_euler = (target - cam.location).to_track_quat('-Z', 'Y').to_euler()
		scene.render.filepath = os.path.join(PREVIEW, name)
		bpy.ops.render.render(write_still=True)

	hand_c = (rig["hand.L"][1] + rig["hand.R"][1]) / 2
	shot("ghost_rest.png", Vector((0, 0, height * 0.55)), Vector((0.8, 3.0, 0.3)))
	shot("ghost_hands_rest.png", hand_c, Vector((0.25, 0.55, 0.35)))
	pb = arm.pose.bones
	for b in pb:
		b.rotation_mode = 'XYZ'
	for side in ("L", "R"):
		for f in FINGERS:
			for g in (1, 2, 3):
				pb["%s%d.%s" % (f, g, side)].rotation_euler.x = math.radians(20 if f != "thumb" else 12)
	shot("ghost_hands_curl.png", hand_c, Vector((0.25, 0.55, 0.35)))
	for side in ("L", "R"):
		pb["upper_arm." + side].rotation_euler.x = math.radians(40)
		pb["forearm." + side].rotation_euler.x = math.radians(25)
	pb["head"].rotation_euler.y = math.radians(15)
	pb["hem"].rotation_euler.x = math.radians(12)
	shot("ghost_pose.png", Vector((0, 0, height * 0.55)), Vector((1.8, 2.4, 0.4)))
