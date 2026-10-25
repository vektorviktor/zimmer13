# Trennt an Meshys Puppenmodell (Auto-Rigging mit Skelettvorlage „Mixamo“, Spielkonzept 5.5) Beine und
# Ärmel sauber vom Rest. Ändert nur JOINTS_0/WEIGHTS_0 der GLB – Netz, Texturen, Animationen und Namen
# bleiben byte-gleich (kein Umweg über Blenders Import/Export).
#
# Aufruf (ohne Blender):
#   python tools/doll_weights.py <meshy.glb> <ausgabe.glb>
#
# Meshy verschmiert die Gewichte überall, wo Körperteile in der Ruhepose dicht beieinanderliegen:
# - Unterschenkel und Schuhe hängen bis zur Hälfte am anderen Bein – beim Gehen zieht ein Fuß die
#   Innenseite des anderen mit. Jedes Stück Bein unter dem Knie gehört jetzt einer Seite (über die
#   Netzverbindung, die Seite stimmt das ganze Stück ab); Gewicht am anderen Bein wandert zum
#   gleichnamigen Knochen dieser Seite. Über dem Knie läuft das über LEG_RAMP aus – dort deckt das Kleid,
#   und der Rock selbst bleibt zwischen beiden Beinen (er ist weiter weg als LEG_RADIUS).
# - Die Arme hängen am Rock: Der linke Ärmel hing am Ellbogen bis zur Hälfte am Oberschenkel (beim Heben
#   blieb ein Lappen hängen), Taille und Rock am Arm (ein Zipfel stand ab). Unterhalb der Achsel verliert
#   der Ärmel (nah an Ober-/Unterarm oder Hand) Rumpf- und Beingewichte, die Taille und der Rock ab
#   Ellbogenhöhe Arm- und Schultergewichte – jeweils anteilig an die übrigen Knochen des Punkts. Den
#   Streifen dazwischen, wo Meshy Ärmel und Mieder verschmolzen hat, und die Haare lässt es, wie sie sind.
#
# Geprüft an Gehen, Rennen und Testposen (Arme hoch/vor/zurück, Knie heben, Spreizen, Ausschreiten) über
# die stärkste Dehnung je Kante: Unterschenkel ~95 % weniger Überdehnung, Oberschenkel ~60 %, Arme 20–30 %.
import json, struct, sys
from collections import defaultdict

## Ein Netzstück gehört zum Bein, wenn es so nah an die Beinkette kommt oder unter den Knöchel reicht. Das
## Kleid bleibt überall weiter weg; ein einzelner Punkt taugt nicht als Maß, weil der Oberschenkel über
## dem Knie bis ~0,16 m dick wird (sonst Knick zwischen getrennten und gemischten Punkten)
LEG_RADIUS = 0.10
## Über dem Knie läuft die Trennung auf dieser Höhe aus (Meter, vom Kleid verdeckt). 0,12 knickt den
## Oberschenkel noch, ab ~0,36 reicht es bis in Teile, die am Rock hängen
LEG_RAMP = 0.2
## Ärmel: näher als SLEEVE_IN an Ober-/Unterarm oder Hand ist Arm, weiter als SLEEVE_OUT Körper. Dazwischen
## ist der Ärmel innen am Ellbogen mit der Taille verschmolzen – dort bleibt Meshys Übergang, sonst
## spannte sich beim Armschwingen eine Haut zwischen sauberem Ärmel und sauberer Taille
SLEEVE_IN = 0.085
SLEEVE_OUT = 0.11
## Anteil am Oberarm (0 Schulter, 1 Ellbogen): bis T0 bleibt der Ärmel, wie er ist (Achsel, Schulternaht),
## ab T1 hängt er nur noch am Arm
ARMPIT_T0 = 0.35
ARMPIT_T1 = 0.6
## Das Mieder liegt innen am Oberarm an – löste man es dort vom Arm, spannte sich beim Heben ein Segel vom
## Ellbogen zur Taille. Vom Arm gelöst wird der Körper erst ab Ellbogenhöhe (Taille, Rock), eingeblendet
## von WAIST_T0 bis WAIST_T1 auf dem Oberarm
WAIST_T0 = 0.85
WAIST_T1 = 1.1
## So viel Gewicht an Kopf/Hals macht einen Punkt zum Haar – den fasst die Trennung nicht an
HAIR_HEAD = 0.3
## Stimmen in einem zusammenhängenden Beinstück mehr Punkte als dieser Anteil für die andere Seite,
## entscheidet jeder Punkt für sich (nächstgelegene Beinkette)
LEG_MIX = 0.1
PREFIX = "mixamorig:"
SIDES = (("Left", 1.0), ("Right", -1.0))
LEG_BONES = ("UpLeg", "Leg", "Foot", "ToeBase", "Toe_End")
HEAD_BONES = ("Neck", "Head", "HeadTop_End", "headfront")
TORSO_BONES = ("Hips", "Spine", "Spine1", "Spine2")
EPS = 1e-4

SRC, DST = sys.argv[1], sys.argv[2]

# --- GLB lesen ----------------------------------------------------------------------------------
data = bytearray(open(SRC, "rb").read())
json_len = struct.unpack_from("<I", data, 12)[0]
gltf = json.loads(data[20:20 + json_len])
bin_start = 20 + json_len + 8   # dahinter: Länge und Typ des BIN-Blocks
SIZES = {5120: 1, 5121: 1, 5122: 2, 5123: 2, 5125: 4, 5126: 4}
FORMATS = {5120: "b", 5121: "B", 5122: "h", 5123: "H", 5125: "I", 5126: "f"}
COUNTS = {"SCALAR": 1, "VEC2": 2, "VEC3": 3, "VEC4": 4, "MAT4": 16}


def accessor_layout(index):
	acc = gltf["accessors"][index]
	view = gltf["bufferViews"][acc["bufferView"]]
	n = COUNTS[acc["type"]]
	size = SIZES[acc["componentType"]]
	stride = view.get("byteStride", n * size)
	start = bin_start + view.get("byteOffset", 0) + acc.get("byteOffset", 0)
	return acc, start, stride, "<%d%s" % (n, FORMATS[acc["componentType"]])


def read(index):
	acc, start, stride, fmt = accessor_layout(index)
	return [struct.unpack_from(fmt, data, start + i * stride) for i in range(acc["count"])]


def write(index, i, values):
	_, start, stride, fmt = accessor_layout(index)
	struct.pack_into(fmt, data, start + i * stride, *values)


mesh = gltf["meshes"][0]
assert len(mesh["primitives"]) == 1, "Puppe aus mehreren Teilnetzen – Skript erwartet eins"
prim = mesh["primitives"][0]
attrs = prim["attributes"]
assert "JOINTS_1" not in attrs, "mehr als vier Einflüsse je Punkt – Skript erwartet vier"
pos = read(attrs["POSITION"])
joints = read(attrs["JOINTS_0"])
weights = read(attrs["WEIGHTS_0"])
tris = [i[0] for i in read(prim["indices"])]
skin = gltf["skins"][0]
bone_index = {gltf["nodes"][n]["name"].replace(PREFIX, ""): k for k, n in enumerate(skin["joints"])}
bone_name = {k: name for name, k in bone_index.items()}


def bind_position(m):
	# Gelenk in Netzkoordinaten: Verschiebung der Inversen der inverse bind matrix (spaltenweise, affin)
	a = [[m[c * 4 + r] for c in range(3)] for r in range(3)]
	t = [m[12], m[13], m[14]]
	det = (a[0][0] * (a[1][1] * a[2][2] - a[1][2] * a[2][1]) - a[0][1] * (a[1][0] * a[2][2] - a[1][2] * a[2][0])
		+ a[0][2] * (a[1][0] * a[2][1] - a[1][1] * a[2][0]))
	inv = [[(a[(c + 1) % 3][(r + 1) % 3] * a[(c + 2) % 3][(r + 2) % 3]
		- a[(c + 1) % 3][(r + 2) % 3] * a[(c + 2) % 3][(r + 1) % 3]) / det for c in range(3)] for r in range(3)]
	return tuple(-sum(inv[r][c] * t[c] for c in range(3)) for r in range(3))


ibm = read(skin["inverseBindMatrices"])
bone_pos = {name: bind_position(ibm[k]) for name, k in bone_index.items()}


def seg(p, a, b):
	# Abstand Punkt–Strecke und Lage t auf der Strecke (ungeklemmt: 0 bei a, 1 bei b)
	a, b = bone_pos[a], bone_pos[b]
	d = [b[i] - a[i] for i in range(3)]
	ll = sum(x * x for x in d)
	t = sum((p[i] - a[i]) * d[i] for i in range(3)) / ll
	tc = min(max(t, 0.0), 1.0)
	return sum((p[i] - a[i] - d[i] * tc) ** 2 for i in range(3)) ** 0.5, t


def ramp(t, t0, t1):
	return min(max((t - t0) / (t1 - t0), 0.0), 1.0)


vw = [{j: w for j, w in zip(joints[v], weights[v]) if w > 0.0} for v in range(len(pos))]
changed = set()


def move(v, sources, targets, amount, fallback):
	# Anteil amount des Gewichts an sources wandert anteilig auf das, was der Punkt an targets schon
	# hat – hat er dort nichts, ganz auf fallback
	w = vw[v]
	moved = 0.0
	for j in sources:
		if j in w:
			x = w[j] * amount
			w[j] -= x
			moved += x
	if moved <= EPS:
		return 0.0
	base = {j: w[j] for j in targets if w.get(j, 0.0) > EPS}
	total = sum(base.values())
	if total <= EPS:
		base, total = {fallback: 1.0}, 1.0
	for j, x in base.items():
		w[j] = w.get(j, 0.0) + moved * x / total
	changed.add(v)
	return moved


# --- Beine: unter dem Knie nur eine Seite ------------------------------------------------------
leg_chain = {s: [(s + a, s + b) for a, b in zip(LEG_BONES, LEG_BONES[1:])] for s, _ in SIDES}
leg_joints = {s: {bone_index[s + b] for b in LEG_BONES} for s, _ in SIDES}
twin = {}
for b in LEG_BONES:
	twin[bone_index["Left" + b]] = bone_index["Right" + b]
	twin[bone_index["Right" + b]] = bone_index["Left" + b]
knee_y = (bone_pos["LeftLeg"][1] + bone_pos["RightLeg"][1]) / 2.0
ankle_y = min(bone_pos["LeftFoot"][1], bone_pos["RightFoot"][1])
leg = {}   # Punkt → Abstand linke minus rechte Beinkette
reach = {}   # Punkt → Abstand zur näheren Beinkette
near = set()
for v, p in enumerate(pos):
	if p[1] >= knee_y + LEG_RAMP or not any(j in twin for j in vw[v]):
		continue
	dl = min(seg(p, a, b)[0] for a, b in leg_chain["Left"])
	dr = min(seg(p, a, b)[0] for a, b in leg_chain["Right"])
	leg[v] = dl - dr
	reach[v] = min(dl, dr)
	if p[1] < ankle_y or reach[v] < LEG_RADIUS:
		near.add(v)
parent = {v: v for v in leg}


def find(v):
	while parent[v] != v:
		parent[v] = parent[parent[v]]
		v = parent[v]
	return v


for k in range(0, len(tris), 3):
	tri = [v for v in tris[k:k + 3] if v in leg]
	for a, b in zip(tri, tri[1:]):
		parent[find(a)] = find(b)
parts = defaultdict(list)
for v in leg:
	parts[find(v)].append(v)
parts = {k: vs for k, vs in parts.items() if any(v in near for v in vs)}   # ohne Kleid
side = {}
mixed = 0
for vs in parts.values():
	left = sum(1 for v in vs if leg[v] < 0.0)
	vote = "Left" if left * 2 >= len(vs) else "Right"
	if min(left, len(vs) - left) > LEG_MIX * len(vs):
		mixed += 1
		for v in vs:
			side[v] = "Left" if leg[v] < 0.0 else "Right"
	else:
		for v in vs:
			side[v] = vote
leg_moved = 0.0
for v, s in side.items():
	y = pos[v][1]
	amount = 1.0 if y <= knee_y else 1.0 - (y - knee_y) / LEG_RAMP
	other = "Right" if s == "Left" else "Left"
	for j in [j for j in vw[v] if j in leg_joints[other]]:
		x = vw[v][j] * amount
		vw[v][j] -= x
		vw[v][twin[j]] = vw[v].get(twin[j], 0.0) + x
		leg_moved += x
		changed.add(v)
print("Beine: %d Punkte in %d Stücken (%d gemischt), bis %.2f m von der Beinkette, %.1f Gewicht umgehängt"
	% (len(side), len(parts), mixed, max(reach[v] for v in side), leg_moved))

# --- Ärmel: unterhalb der Achsel Arm oder Körper ------------------------------------------------
head_joints = {bone_index[b] for b in HEAD_BONES}
for s, sx in SIDES:
	chain = {k for name, k in bone_index.items() if name.startswith(s) and (
		name in (s + "Shoulder", s + "Arm", s + "ForeArm") or name.startswith(s + "Hand"))}
	segments = ((s + "Arm", s + "ForeArm"), (s + "ForeArm", s + "Hand"), (s + "Hand", s + "HandMiddle4"))
	body_segments = tuple(zip(TORSO_BONES, TORSO_BONES[1:] + ("Neck",))) + ((s + "UpLeg", s + "Leg"),)
	arm_moved = body_moved = 0.0
	arm_count = body_count = 0
	for v, p in enumerate(pos):
		w = vw[v]
		if p[0] * sx <= 0.0 or sum(w.get(j, 0.0) for j in head_joints) > HAIR_HEAD:
			continue
		d, t, near = min(seg(p, a, b) + (a,) for a, b in segments)
		if d < SLEEVE_IN:
			amount = 1.0 if near != s + "Arm" else ramp(t, ARMPIT_T0, ARMPIT_T1)
			x = move(v, [j for j in w if j not in chain], chain, amount, bone_index[near])
			arm_moved += x
			arm_count += x > 0.0
		elif d > SLEEVE_OUT:
			amount = 1.0 if near != s + "Arm" else ramp(t, WAIST_T0, WAIST_T1)
			body = min(body_segments, key=lambda ab: seg(p, *ab)[0])[0]
			x = move(v, [j for j in w if j in chain], [j for j in w if j not in chain], amount, bone_index[body])
			body_moved += x
			body_count += x > 0.0
	print("%s: Ärmel %d Punkte (%.1f Gewicht vom Körper gelöst), Körper %d Punkte (%.1f vom Arm gelöst)"
		% (s, arm_count, arm_moved, body_count, body_moved))

# --- Zurückschreiben: höchstens vier Einflüsse, Summe 1 -----------------------------------------
for v in changed:
	top = sorted(((x, j) for j, x in vw[v].items() if x > EPS), reverse=True)[:4]
	total = sum(x for x, _ in top)
	top += [(0.0, 0)] * (4 - len(top))
	write(attrs["JOINTS_0"], v, [j for _, j in top])
	write(attrs["WEIGHTS_0"], v, [x / total for x, _ in top])
with open(DST, "wb") as f:
	f.write(data)
print("%d von %d Punkten geändert: %s" % (len(changed), len(pos), DST))
