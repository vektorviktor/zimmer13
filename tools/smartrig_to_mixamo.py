# Macht aus einer Meshy-Figur mit „SmartRig“ (Knochen Bone_000 … Bone_077) dasselbe, was Meshys
# Auto-Rigging mit Skelettvorlage „Mixamo“ liefert: Knochen mixamorig:Hips … mit Mixamos Namen und
# Hierarchie (65 Knochen wie in guest_*.glb, ohne „headfront“). Danach passen Mixamo-Animationen
# (tools/mixamo_retarget.py, auch für tools/build_guest.py) und Godots Humanoid-BoneMap ohne Handarbeit.
#
# Aufruf (Blender 4.3):
#   blender -b --python tools/smartrig_to_mixamo.py -- <meshy_smartrig.glb> <ausgabe.glb>
#
# Was passiert:
# - Zuordnung in MAP (abgelesen an „Kürbismann“, Meshy 10/2026). Meshy nummeriert die Finger links und
#   rechts verschieden – das Skript prüft die Reihenfolge Daumen → kleiner Finger an den Fingergewichten.
# - Alle übrigen Knochen (Hilfsknochen am Becken und an den Händen, Augen, Kiefer, Kopfspitze, Requisiten
#   wie die Axt) geben ihre Gewichte an den nächsten zugeordneten Vorfahren ab und fallen weg – die Axt
#   hängt danach fest an mixamorig:LeftHand.
# - HeadTop_End neu auf dem höchsten Punkt des Kopfs, Knochenspitzen zeigen zum Kind (Hüfte nach oben).
# - Figur waagerecht auf die Hüfte zentriert, Füße bleiben auf 0, Blick und Ruhepose wie von Meshy.
import bpy, sys
from mathutils import Matrix, Vector

PREFIX = "mixamorig:"
## SmartRig → Mixamo. Finger je 1–4 von der Hand zur Spitze.
MAP = {
	"Bone_000": "Hips", "Bone_004": "Spine", "Bone_003": "Spine1", "Bone_002": "Spine2",
	"Bone_017": "Neck", "Bone_016": "Head",
	"Bone_022": "RightShoulder", "Bone_021": "RightArm", "Bone_020": "RightForeArm", "Bone_019": "RightHand",
	"Bone_027": "LeftShoulder", "Bone_026": "LeftArm", "Bone_025": "LeftForeArm", "Bone_024": "LeftHand",
	"Bone_009": "RightUpLeg", "Bone_008": "RightLeg", "Bone_007": "RightFoot", "Bone_006": "RightToeBase",
	"Bone_005": "RightToe_End",
	"Bone_014": "LeftUpLeg", "Bone_013": "LeftLeg", "Bone_012": "LeftFoot", "Bone_011": "LeftToeBase",
	"Bone_010": "LeftToe_End",
}
FINGERS = ("Thumb", "Index", "Middle", "Ring", "Pinky")
## Erster Fingerknochen je Hand in der Reihenfolge von FINGERS; die Kette zählt zur Spitze hin herunter
FINGER_ROOTS = {"Right": (39, 55, 51, 47, 43), "Left": (75, 67, 59, 63, 71)}
for side, roots in FINGER_ROOTS.items():
	for finger, root in zip(FINGERS, roots):
		for k in range(4):
			MAP["Bone_%03d" % (root - k)] = "%sHand%s%d" % (side, finger, k + 1)

argv = sys.argv[sys.argv.index("--") + 1:]
SRC, DST = argv[0], argv[1]

# --- Laden ---------------------------------------------------------------------------------------
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=SRC)
scene = bpy.context.scene
arm = [o for o in scene.objects if o.type == 'ARMATURE'][0]
body = [o for o in scene.objects if o.type == 'MESH' and o.vertex_groups][0]
for o in [o for o in scene.objects if o not in (arm, body)]:
	bpy.data.objects.remove(o)
assert arm.matrix_world == Matrix() and body.matrix_world == Matrix(), "Armatur/Netz nicht im Ursprung"
missing = [b for b in MAP if b not in arm.data.bones]
assert not missing, "Kein SmartRig wie erwartet, es fehlen: %s" % missing


def chain_centre(names):
	"""Mittelpunkt der Punkte, die überwiegend an diesen Knochen hängen."""
	idx = {body.vertex_groups[n].index for n in names if n in body.vertex_groups}
	acc, cnt = Vector(), 0
	for v in body.data.vertices:
		if sum(g.weight for g in v.groups if g.group in idx) > 0.3:
			acc += v.co
			cnt += 1
	return acc / max(cnt, 1)


# --- Prüfen: Seiten und Fingerreihenfolge ---------------------------------------------------------
# Blick nach −Y (Blender) → links ist +X
bones = arm.data.bones
for a, b in (("Bone_027", "Bone_022"), ("Bone_014", "Bone_009")):
	assert bones[a].head_local.x > bones[b].head_local.x, "Links/rechts vertauscht (%s/%s)" % (a, b)
for side, roots in FINGER_ROOTS.items():
	c = [chain_centre(["Bone_%03d" % (r - k) for k in range(4)]) for r in roots]
	d = [(c[i] - c[0]).length for i in range(1, 5)]
	print("Finger %s: Abstand zum Daumen %s" % (side, " ".join("%.3f" % x for x in d)))
	assert d == sorted(d), "Fingerreihenfolge %s passt nicht – FINGER_ROOTS prüfen" % side


def mapped_ancestor(bone):
	b = bone.parent
	while b is not None and b.name not in MAP:
		b = b.parent
	return b.name


# --- Gewichte der übrigen Knochen an den nächsten zugeordneten Vorfahren -------------------------------
merge = {b.name: mapped_ancestor(b) for b in bones if b.name not in MAP}
moved = {}
src_idx = {body.vertex_groups[n].index: n for n in merge if n in body.vertex_groups}
add = {}
for v in body.data.vertices:
	for g in v.groups:
		if g.group in src_idx and g.weight > 0.0:
			src = src_idx[g.group]
			add.setdefault(merge[src], []).append((v.index, g.weight))
			moved[src] = moved.get(src, 0.0) + g.weight
for dst, entries in add.items():
	vg = body.vertex_groups.get(dst) or body.vertex_groups.new(name=dst)
	for i, w in entries:
		vg.add([i], w, 'ADD')
for n in src_idx.values():
	body.vertex_groups.remove(body.vertex_groups[n])
for n, dst in sorted(merge.items()):
	print("weg: %s → %s (Gewicht %.0f)" % (n, MAP[dst], moved.get(n, 0.0)))

# Höchster Punkt des Kopfs (nach dem Zusammenführen hängen Kopfspitze, Augen, Kiefer am Kopf)
head_idx = body.vertex_groups["Bone_016"].index
top = max((v.co.z for v in body.data.vertices if any(g.group == head_idx and g.weight > 0.5 for g in v.groups)))
hips = bones["Bone_000"].head_local
offset = Vector((hips.x, hips.y, 0.0))

# --- Skelett umbauen ------------------------------------------------------------------------------
bpy.context.view_layer.objects.active = arm
bpy.ops.object.mode_set(mode='EDIT')
eb = arm.data.edit_bones
for b in list(eb):
	if b.name in MAP and b.parent is not None and b.parent.name not in MAP:
		p = b.parent
		while p.name not in MAP:
			p = p.parent
		b.use_connect = False
		b.parent = p
for n in merge:
	eb.remove(eb[n])
for b in eb:
	b.head -= offset
	b.tail -= offset
	b.name = PREFIX + MAP[b.name]
head = eb[PREFIX + "Head"]
end = eb.new(PREFIX + "HeadTop_End")
end.head = Vector((head.head.x, head.head.y, top))
end.tail = end.head + Vector((0, 0, 0.05))
end.parent = head
end.use_deform = False
# Spitzen zum Kind: wo es eins gibt bzw. ALIGN-Ziel wie in build_guest.py
AIM = {"Hips": "Spine1", "Spine2": "Neck", "Head": "HeadTop_End",
	"LeftHand": "LeftHandMiddle1", "RightHand": "RightHandMiddle1"}
for b in eb:
	n = b.name[len(PREFIX):]
	child = eb.get(PREFIX + AIM[n]) if n in AIM else b.children[0] if len(b.children) == 1 else None
	if child is None:
		continue
	tip = child.head if n != "Hips" else b.head.lerp(child.head, 0.5)   # Hüfte und Wirbel beginnen am selben Punkt
	if (tip - b.head).length > 0.005:
		roll = b.roll
		b.tail = tip
		b.roll = roll
bpy.ops.object.mode_set(mode='OBJECT')

for vg in body.vertex_groups:
	if vg.name in MAP:
		vg.name = PREFIX + MAP[vg.name]
body.data.transform(Matrix.Translation(-offset))
arm.name = arm.data.name = "Armature"
body.name = body.data.name = bpy.path.display_name_from_filepath(DST)

names = sorted(b.name for b in arm.data.bones)
stray = [vg.name for vg in body.vertex_groups if vg.name not in arm.data.bones]
assert not stray, "Gewichtsgruppen ohne Knochen: %s" % stray
print("MIXAMO: %d Knochen, Kopf oben bei %.3f m, verschoben um (%.3f, %.3f)" % (len(names), top, -offset.x, -offset.y))

bpy.ops.export_scene.gltf(
	filepath=DST, export_format='GLB', export_yup=True, export_apply=False,
	export_skins=True, export_animations=False, export_morph=False,
	export_cameras=False, export_lights=False, export_image_format='AUTO')
