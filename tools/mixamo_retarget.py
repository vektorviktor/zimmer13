# Mixamo-Animationen auf eine Figur mit Mixamo-Skelett in eigener Ruhepose umrechnen – gemeinsam für
# tools/build_guest.py und tools/build_pumpkin.py (Import: sys.path um tools/ erweitern).
# Mixamo steht in T-Pose, unser Gast mit hängenden Armen – Knochen umbenennen reicht nicht. Erst wird
# der Gast in Gedanken in die T-Pose der Quelle gedreht (Knochenrichtungen gleich), dann bekommt jeder
# Knochen dieselbe Drehung gegenüber dieser Pose wie in der Quelle gegenüber ihrer Ruhepose.
import bpy, os, math
from mathutils import Matrix, Vector

DRIFT_WINDOW = 2.0   # s: über so lange gemittelt wird das Wandern der Hüfte abgezogen (Wackeln bleibt)
## Mixamo-Rohdateien (FBX, „Without Skin“, 30 fps) – nicht im Repo
ANIM_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "assets", "source", "anim")
## Zielknochen für die Knochenrichtung, wo es mehrere Kinder gibt; zweites Paar = Querachse (Handfläche, Becken)
ALIGN = {
	"Hips": ("Spine", ("LeftUpLeg", "RightUpLeg")), "Spine2": ("Neck", None),
	"LeftHand": ("LeftHandMiddle1", ("LeftHandIndex1", "LeftHandPinky1")),
	"RightHand": ("RightHandMiddle1", ("RightHandIndex1", "RightHandPinky1")),
}


def frame_of(main, side):
	"""Orthonormale Basis aus Hauptrichtung (Y) und Querrichtung (X)."""
	y = main.normalized()
	if side is None or abs(side.normalized().dot(y)) > 0.99:
		return None
	x = (side - y * side.dot(y)).normalized()
	return Matrix((x, y, x.cross(y))).transposed()


def retarget(arm, path, name):
	"""Eine Mixamo-FBX als Aktion „name“ für die Armatur arm (Mixamo-Namen ohne „mixamorig:“, Zehen nach +Y)."""
	scene = bpy.context.scene
	fps = scene.render.fps / scene.render.fps_base
	before = set(bpy.data.objects)
	keep_fps = (scene.render.fps, scene.render.fps_base)
	bpy.ops.import_scene.fbx(filepath=path)
	src_fps = scene.render.fps / scene.render.fps_base   # der Import stellt die Szene auf die Datei um
	scene.render.fps, scene.render.fps_base = keep_fps
	new = [o for o in bpy.data.objects if o not in before]
	src = [o for o in new if o.type == 'ARMATURE'][0]
	src_action = src.animation_data.action
	sb = {b.name.replace("mixamorig:", ""): b for b in src.data.bones}
	sp = {b.name.replace("mixamorig:", ""): b for b in src.pose.bones}
	# Blickrichtung wie beim Gast: Zehen nach +Y
	bpy.context.view_layer.update()
	sw = src.matrix_world
	if (sw @ sb["LeftToe_End"].head_local - sw @ sb["LeftFoot"].head_local).y < 0:
		src.rotation_mode = 'XYZ'
		src.rotation_euler.z += math.pi
	src.animation_data.action = None
	for pb in src.pose.bones:
		pb.matrix_basis = Matrix()
	bpy.context.view_layer.update()
	sw, tw = src.matrix_world.copy(), arm.matrix_world.copy()

	def head(w, bone):
		return w @ bone.head_local

	s_rest = {k: (sw @ b.matrix_local).to_3x3().normalized() for k, b in sb.items()}
	t_rest = {b.name: (tw @ b.matrix_local).to_3x3().normalized() for b in arm.data.bones}
	mapped = [b.name for b in arm.data.bones if b.name in sb]
	order = []

	def visit(bone):
		order.append(bone)
		for c in bone.children:
			visit(c)

	for b in arm.data.bones:
		if b.parent is None:
			visit(b)

	# Gast in der T-Pose der Quelle (Weltdrehung je Knochen)
	tpose = {}
	for b in order:
		n = b.name
		inherited = t_rest[n] if b.parent is None else \
			tpose[b.parent.name] @ t_rest[b.parent.name].inverted() @ t_rest[n]
		tpose[n] = inherited
		if n not in sb:
			continue
		kids = [c.name for c in b.children if c.name in sb]
		child, side = ALIGN.get(n, (kids[0] if len(kids) == 1 else None, None))
		if child is None or child not in sb:
			continue
		to_local = t_rest[n].inverted()
		cur_dir = inherited @ (to_local @ (head(tw, arm.data.bones[child]) - head(tw, b)))
		want_dir = head(sw, sb[child]) - head(sw, sb[n])
		cur_side = want_side = None
		if side:
			cur_side = inherited @ (to_local @ (head(tw, arm.data.bones[side[1]]) - head(tw, arm.data.bones[side[0]])))
			want_side = head(sw, sb[side[1]]) - head(sw, sb[side[0]])
		fc, fw = frame_of(cur_dir, cur_side), frame_of(want_dir, want_side)
		turn = fw @ fc.transposed() if fc is not None and fw is not None else cur_dir.rotation_difference(want_dir).to_matrix()
		tpose[n] = turn @ inherited

	# Hüfte: Höhe über dem Fuß im Verhältnis, Seitwärtswandern herausgerechnet
	t_hips, s_hips = head(tw, arm.data.bones["Hips"]), head(sw, sb["Hips"])
	k = (t_hips.z - head(tw, arm.data.bones["LeftFoot"]).z) / (s_hips.z - head(sw, sb["LeftFoot"]).z)

	src.animation_data.action = src_action
	f0, f1 = int(src_action.frame_range[0]), int(src_action.frame_range[1])
	frames = list(range(f0, f1 + 1))
	s_rot, s_pos = [], []
	for f in frames:
		scene.frame_set(f)
		s_rot.append({n: (sw @ sp[n].matrix).to_3x3().normalized() for n in mapped})
		s_pos.append(sw @ sp["Hips"].head)
	half = max(1, int(DRIFT_WINDOW * src_fps / 2))
	count = len(frames) - 1   # letztes Bild = erstes (Schleife)
	drift = []
	for i in range(len(frames)):
		acc = Vector()
		for j in range(i - half, i + half + 1):
			acc += s_pos[j % count]
		drift.append(acc / (2 * half + 1))

	act = bpy.data.actions.new(name)
	curves = {}
	for n in mapped:
		dp = 'pose.bones["%s"].rotation_quaternion' % n
		curves[n] = [act.fcurves.new(dp, index=i, action_group=n) for i in range(4)]
	loc_curves = [act.fcurves.new('pose.bones["Hips"].location', index=i, action_group="Hips") for i in range(3)]
	keys = {n: [] for n in mapped}
	loc_keys = []
	inv_tw = tw.inverted()
	for i, f in enumerate(frames):
		tf = (f - f0) * fps / src_fps   # Bild im Takt der Szene
		world = {}
		for b in order:
			n = b.name
			p = b.parent.name if b.parent else None
			if n in sb:
				world[n] = s_rot[i][n] @ s_rest[n].inverted() @ tpose[n]
			else:
				world[n] = world[p] @ t_rest[p].inverted() @ t_rest[n] if p else t_rest[n]
			if n not in keys:
				continue
			basis = t_rest[n].inverted() @ (t_rest[p] @ world[p].inverted() if p else Matrix.Identity(3)) @ world[n]
			q = basis.to_quaternion()
			if keys[n] and q.dot(keys[n][-1][1]) < 0:
				q.negate()
			keys[n].append((tf, q))
		off = s_pos[i] - s_hips
		off.x -= drift[i].x - s_hips.x
		off.y -= drift[i].y - s_hips.y
		want = inv_tw @ (t_hips + off * k)
		rest = arm.data.bones["Hips"].matrix_local
		loc_keys.append((tf, rest.to_3x3().inverted() @ (want - rest.translation)))
	for n, ks in keys.items():
		for i in range(4):
			fc = curves[n][i]
			fc.keyframe_points.add(len(ks))
			fc.keyframe_points.foreach_set("co", [c for f, q in ks for c in (f, q[i])])
			fc.update()
	for i in range(3):
		fc = loc_curves[i]
		fc.keyframe_points.add(len(loc_keys))
		fc.keyframe_points.foreach_set("co", [c for f, v in loc_keys for c in (f, v[i])])
		fc.update()
	for o in new:
		bpy.data.objects.remove(o)
	bpy.data.actions.remove(src_action)
	return act


def retarget_all(arm, anim_dir=ANIM_DIR):
	"""Jede <name>.fbx aus anim_dir als Aktion <name> – {name: Aktion}."""
	fps = bpy.context.scene.render.fps / bpy.context.scene.render.fps_base
	actions = {}
	for fn in sorted(os.listdir(anim_dir)) if os.path.isdir(anim_dir) else []:
		if fn.lower().endswith(".fbx"):
			key = os.path.splitext(fn)[0]
			actions[key] = retarget(arm, os.path.join(anim_dir, fn), key)
			print("Mixamo:", key, "%.2f s" % ((actions[key].frame_range[1] - actions[key].frame_range[0]) / fps))
	return actions
