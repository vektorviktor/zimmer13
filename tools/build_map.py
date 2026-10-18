# Liest den Gebäudeplan map.aseprite (Spielkonzept 7.5) und schreibt daraus die Layout-Datei, aus der der
# LevelBuilder das Erdgeschoss baut: Wände mit Öffnungen, Flächen (Zimmer, Flure, Gärten …), Zimmer mit
# Nummer, Tür und Fenstern, dazu Pflanzkübel, Bäume, Treppen, Aufzüge, Rezeption und Pool.
#
# Plan-Regeln (mit dem Zeichner abgestimmt):
#   - Maßstab 1 m = 10 px. Wände sind 2 px dicke schwarze Linien (20 cm).
#   - Gezählt wird das Bild aller sichtbaren Ebenen („alles flach“); ausgeblendete Ebenen fallen weg.
#   - Öffnungen sind farbige Striche auf der Wandlinie, Flächen sind Füllfarben (Legende in LEGEND/OPENINGS).
#   - Beschriftungen (schwarzer/roter Text) werden über ihre Größe erkannt und ignoriert; Namen von Räumen
#     ohne eigene Farbe stehen deshalb in NAMES (Punkt im Raum → ID und Anzeigename).
#
# Koordinaten der Ausgabe: Meter, x nach Osten, z nach Süden (Norden = −Z wie in Godot), Ursprung = Mitte
# des Haupteingangs auf der Mittellinie der Südwand. Rechtecke als [x0, z0, x1, z1].
#
# Aufruf (Python 3, keine Zusatzpakete):
#   python tools/build_map.py [map.aseprite] [assets/maps/floor0.json] [vorschau.svg]
import json, math, struct, sys, zlib
from collections import deque

SRC = sys.argv[1] if len(sys.argv) > 1 else "map.aseprite"
DST = sys.argv[2] if len(sys.argv) > 2 else "assets/maps/floor0.json"
PREVIEW = sys.argv[3] if len(sys.argv) > 3 else ""

PX = 0.1                    ## Meter pro Pixel
ORIGIN = (1155, 1810)       ## Pixel des Ursprungs (Mitte Haupteingang, Mittellinie Südwand)
MIN_WALL_RUN = 6            ## kürzeste erkannte Wand in Pixeln (kürzere Läufe sind Querschnitte)
MIN_WALL_NET = 300          ## kleinere schwarze Flecken sind Schrift, keine Wände

WALL = "000000"
## Füllfarben → Flächenart. „outdoor“ = ohne Decke.
LEGEND = {
	"ff8855": ("room", False),
	"d4e4f1": ("corridor", False),        # Flure und Lobby
	"bef6b0": ("garden", True),           # Gärten und Innenhöfe (draußen)
	"bfdfb7": ("terrace", True),          # Terrassen vor den Gartenzimmern
	"256415": ("terrace_edge", True),     # Einfassung der Terrassen
	"249e07": ("tree", True),
	"6da95d": ("planter", False),         # Pflanzen in ca. 60 cm hoher Steineinfassung
	"ffffff": ("service", False),         # Küche, Speisesaal, Duschen, Umkleiden (Name über NAMES)
	"c5c5c5": ("storage", False),         # Tiefkühlraum, Lager, Kühlraum
	"99b054": ("bar", False),
	"ce91d3": ("party", False),
	"00afff": ("toilet", False),
	"008dff": ("pool_water", False),
	"b2c6d5": ("pool_deck", False),
	"91d3be": ("elevator", False),
	"d8d8d8": ("stairwell", False),
	"848484": ("stairwell", False),       # Stufenstriche im Treppenhaus
	"df7126": ("reception", False),
}
## Strichfarben auf der Wandlinie → Öffnungsart
OPENINGS = {
	"99e550": "door",                # Tür zum Flur
	"35ff00": "garden_door",         # Tür vom Zimmer zur Terrasse
	"50a3e5": "window",
	"fbf236": "glass_double_door",
	"dfdfdf": "service_door",
	"00ffaf": "elevator_door",
	"ff0000": "main_entrance",       # verschlossen
}
GLASS = "ddf0ff"                     ## gestrichelte Glaswand (Pool)
GALLERY = "9badb7"                   ## Lobby: Kante des Obergeschosses (Luftraum) und Treppe nach oben

## Räume ohne eigene Farbe oder mit mehreren gleichfarbigen: Punkt (px) → (ID, Anzeigename)
NAMES = [
	((430, 1340), "tiefkuehlraum", "Tiefkühlraum"), ((430, 1400), "lager", "Lager"),
	((430, 1460), "kuehlraum", "Kühlraum"), ((550, 1400), "kueche", "Küche"),
	((750, 1400), "speisesaal", "Speisesaal"), ((1010, 1620), "bar", "Bar"),
	((1300, 1620), "party", "Partyraum"), ((945, 1780), "toilette_west", "Toilette"),
	((1035, 1780), "toilette_ost", "Toilette"), ((1230, 705), "pool", "Pool"),
	((1340, 760), "becken", "Becken"), ((1530, 710), "pool_vorraum", "Vorraum"),
	((1500, 750), "dusche_west", "Dusche"), ((1560, 750), "dusche_ost", "Dusche"),
	((1500, 800), "umkleide_west", "Umkleide"), ((1560, 800), "umkleide_ost", "Umkleide"),
	((1137, 1550), "aufzug_1", "Aufzug 1"), ((1172, 1550), "aufzug_2", "Aufzug 2"),
	((1155, 1700), "flure", "Flure und Lobby"),
]

## Zimmernummern (Spielkonzept 7.5): je Flügel ein Laufweg ab der Lobby um den Rundflur (Mittellinien in px),
## danach der Querflur. Rechte Hand ungerade, linke gerade. Ost = 01xx, West = 02xx; die erste Ziffer ist das
## Stockwerk (Erdgeschoss 0). Zimmer 0113 ist das Spielerzimmer: Schild abgebrochen, zu lesen ist nur „13“.
WINGS = {
	"ost": dict(base=100, path=[(1150, 1730), (1830, 1730), (1830, 850), (1390, 850), (1390, 1730)],
		cross=(1290, 1390, 1)),
	"west": dict(base=200, path=[(1080, 1730), (480, 1730), (480, 850), (920, 850), (920, 1730)],
		cross=(1290, 920, -1)),
}
WING_SPLIT_X = 1155   ## Zimmer westlich davon gehören zum Westflügel
BROKEN_SIGNS = {"0113": "13"}


# --- Aseprite lesen --------------------------------------------------------------------------------

def read_aseprite(path):
	"""Gibt (Breite, Höhe, RGBA-Bytearray) des ersten Frames zurück, alle sichtbaren Ebenen übereinander."""
	data = open(path, "rb").read()
	_, magic, frames, w, h, depth = struct.unpack_from("<IHHHHH", data, 0)
	assert magic == 0xA5E0, "keine Aseprite-Datei"
	assert depth == 32, "nur RGBA-Dateien werden unterstützt"
	pos = 128
	fsize, _, old_chunks, _, _, new_chunks = struct.unpack_from("<IHHH2sI", data, pos)
	layers, cels = [], []
	p = pos + 16
	for _ in range(new_chunks or old_chunks):
		csize, ctype = struct.unpack_from("<IH", data, p)
		cd = p + 6
		if ctype == 0x2004:
			flags = struct.unpack_from("<H", data, cd)[0]
			layers.append(flags & 1)
		elif ctype == 0x2005:
			li, x, y, _, ctyp = struct.unpack_from("<HhhBH", data, cd)
			if ctyp in (0, 2):
				cw, ch = struct.unpack_from("<HH", data, cd + 16)
				raw = data[cd + 20:p + csize]
				cels.append((li, x, y, cw, ch, raw if ctyp == 0 else zlib.decompress(raw)))
		p += csize
	img = bytearray(w * h * 4)
	for li, x, y, cw, ch, px in sorted(cels):
		if not layers[li]:
			continue
		for yy in range(ch):
			Y = y + yy
			if not 0 <= Y < h:
				continue
			for xx in range(cw):
				X = x + xx
				s = (yy * cw + xx) * 4
				if 0 <= X < w and px[s + 3] > 127:
					o = (Y * w + X) * 4
					img[o:o + 4] = px[s:s + 4]
	return w, h, img


W, H, IMG = read_aseprite(SRC)
COL = [IMG[i * 4:i * 4 + 3].hex() if IMG[i * 4 + 3] else "" for i in range(W * H)]

def col(x, y):
	return COL[y * W + x] if 0 <= x < W and 0 <= y < H else ""

def m(px, py):
	"""Pixelkante → Meter (gerundet auf cm)."""
	return [round((px - ORIGIN[0]) * PX, 2), round((py - ORIGIN[1]) * PX, 2)]

def components(pred, conn8=False):
	"""Zusammenhängende Pixelgruppen, für die pred(farbe) gilt."""
	seen = bytearray(W * H)
	out = []
	steps = ((1, 0), (-1, 0), (0, 1), (0, -1)) + (((1, 1), (1, -1), (-1, 1), (-1, -1)) if conn8 else ())
	for i in range(W * H):
		if seen[i] or not pred(COL[i]):
			continue
		seen[i] = 1
		q = deque([i])
		pts = []
		while q:
			j = q.popleft()
			pts.append(j)
			x, y = j % W, j // W
			for dx, dy in steps:
				X, Y = x + dx, y + dy
				if 0 <= X < W and 0 <= Y < H:
					k = Y * W + X
					if not seen[k] and pred(COL[k]):
						seen[k] = 1
						q.append(k)
		out.append(pts)
	return out

def bbox(pts):
	xs = [j % W for j in pts]
	ys = [j // W for j in pts]
	return min(xs), min(ys), max(xs) + 1, max(ys) + 1

def rects(pts):
	"""Zerlegt eine Pixelmenge in wenige Rechtecke (Zeilenstücke, senkrecht zusammengefasst), in Metern."""
	rows = {}
	for j in pts:
		rows.setdefault(j // W, []).append(j % W)
	spans = {}
	for y, xs in rows.items():
		xs.sort()
		s = xs[0]
		for a, b in zip(xs, xs[1:] + [None]):
			if b != a + 1:
				spans.setdefault((s, a + 1), []).append(y)
				if b is not None:
					s = b
	out = []
	for (x0, x1), ys in spans.items():
		ys.sort()
		s = ys[0]
		for a, b in zip(ys, ys[1:] + [None]):
			if b != a + 1:
				out.append(m(x0, s) + m(x1, a + 1))
				if b is not None:
					s = b
	return sorted(out, key=lambda r: (r[1], r[0]))


# --- Wände -----------------------------------------------------------------------------------------

# Wandnetz: schwarz + Öffnungen + Glas; kleine Flecken davon sind Schrift
wallish = lambda c: c == WALL or c in OPENINGS or c == GLASS
WALLMASK = bytearray(W * H)
for comp in components(wallish, conn8=True):
	if len(comp) >= MIN_WALL_NET:
		for j in comp:
			WALLMASK[j] = 1

def bands(horizontal):
	"""Wandbänder: Läufe ≥ MIN_WALL_RUN in Zeilen (waagerecht) bzw. Spalten, benachbarte zusammengefasst."""
	n_outer, n_inner = (H, W) if horizontal else (W, H)
	idx = (lambda o, i: o * W + i) if horizontal else (lambda o, i: i * W + o)
	open_bands = {}
	result = []
	for o in range(n_outer):
		runs = []
		i = 0
		while i < n_inner:
			if WALLMASK[idx(o, i)]:
				s = i
				while i < n_inner and WALLMASK[idx(o, i)]:
					i += 1
				if i - s >= MIN_WALL_RUN:
					runs.append((s, i))
			else:
				i += 1
		nxt = {}
		for s, e in runs:
			# an ein Band der vorigen Zeile anhängen, wenn es sich deutlich überlappt
			hit = None
			for (bs, be), band in open_bands.items():
				if min(e, be) - max(s, bs) >= 0.8 * min(e - s, be - bs):
					hit = (bs, be)
					break
			if hit:
				band = open_bands.pop(hit)
				band["o1"] = o + 1
				band["s"], band["e"] = min(band["s"], s), max(band["e"], e)
			else:
				band = {"o0": o, "o1": o + 1, "s": s, "e": e}
			nxt[(s, e)] = band
		result.extend(open_bands.values())
		open_bands = nxt
	result.extend(open_bands.values())
	return result

h_bands = [b for b in bands(True) if b["o1"] - b["o0"] <= 3]
# Pixel waagerechter Wände: senkrechte Wände enden bündig daran (keine doppelten Flächen an Ecken)
HMASK = bytearray(W * H)
for b in h_bands:
	for y in range(b["o0"], b["o1"]):
		for x in range(b["s"], b["e"]):
			HMASK[y * W + x] = 1
saved = WALLMASK[:]
for i in range(W * H):
	if HMASK[i]:
		WALLMASK[i] = 0
v_bands = [b for b in bands(False) if b["o1"] - b["o0"] <= 3]
WALLMASK = saved

def openings_along(b, horizontal):
	"""Öffnungen in einem Wandband: zusammenhängende Läufe gleicher Öffnungsfarbe, Abstand ab Anfang."""
	out = []
	glass = 0
	i = b["s"]
	while i < b["e"]:
		cs = [col(i, y) if horizontal else col(y, i) for y in range(b["o0"], b["o1"])]
		c = next((c for c in cs if c in OPENINGS), None)
		if any(c == GLASS for c in cs):
			glass += 1
		if c:
			s = i
			while i < b["e"] and c in [col(i, y) if horizontal else col(y, i) for y in range(b["o0"], b["o1"])]:
				i += 1
			out.append({"kind": OPENINGS[c], "at": round((s - b["s"]) * PX, 2), "width": round((i - s) * PX, 2)})
		else:
			i += 1
	return out, glass / max(1, b["e"] - b["s"])

walls = []
for horizontal, bs in ((True, h_bands), (False, v_bands)):
	for b in bs:
		mid = (b["o0"] + b["o1"]) / 2
		ops, glass = openings_along(b, horizontal)
		a = m(b["s"], mid) if horizontal else m(mid, b["s"])
		e = m(b["e"], mid) if horizontal else m(mid, b["e"])
		wall = {"a": a, "b": e, "thickness": round((b["o1"] - b["o0"]) * PX, 2)}
		if glass > 0.3:
			wall["glass"] = True
		if ops:
			wall["openings"] = ops
		walls.append(wall)
walls.sort(key=lambda w: (w["a"][1], w["a"][0], w["b"][1], w["b"][0]))


# --- Lobby: graue Linie = Kante des Obergeschossbodens um den Luftraum; die Stufen liegen im Luftraum ---

gal = components(lambda c: c == GALLERY)
assert len(gal) == 1, "Lobby-Galerie nicht eindeutig"
gx0, gy0, gx1, gy1 = bbox(gal[0])
steps_y = [y for y in range(gy0 + 2, gy1) if sum(1 for x in range(gx0, gx1) if col(x, y) == GALLERY) > 10]
step_x1 = max(x for x in range(gx0 + 2, gx1 - 2) if any(col(x, y) == GALLERY for y in steps_y))
lobby = {
	"void": m(gx0, gy0) + m(gx1, gy1),
	"stair": {"rect": m(gx0, gy0) + m(step_x1 + 1, max(steps_y) + 1), "up": "north"},
}


# --- Flächen ---------------------------------------------------------------------------------------

# Schrift und Galerielinie sind keine Flächen: diese Pixel bekommen die Farbe ihrer Umgebung
hole = lambda i: COL[i] == GALLERY or (COL[i] in (WALL, "ff0000") and not WALLMASK[i])
q = deque(i for i in range(W * H) if not hole(i) and COL[i] in LEGEND)
filled = bytearray(W * H)
while q:
	i = q.popleft()
	x, y = i % W, i // W
	for X, Y in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
		k = Y * W + X
		if 0 <= X < W and 0 <= Y < H and not filled[k] and hole(k):
			filled[k] = 1
			COL[k] = COL[i]
			q.append(k)

def name_at(pts):
	ps = set(pts)
	for (x, y), rid, name in NAMES:
		if y * W + x in ps:
			return rid, name
	return None, None

regions, rooms_px = [], []
kinds = {}
for c, (kind, _) in LEGEND.items():
	kinds.setdefault(kind, []).append(c)
counter = {}
for kind, cs in kinds.items():
	for comp in components(lambda c, cs=cs: c in cs):
		x0, y0, x1, y1 = bbox(comp)
		if kind == "service" and (x0 == 0 or y0 == 0 or x1 == W or y1 == H):
			continue   # Weiß außerhalb des Gebäudes
		if len(comp) < 30:
			continue   # Reste von Schrift
		rid, name = name_at(comp)
		counter[kind] = counter.get(kind, 0) + 1
		region = {"id": rid or "%s_%d" % (kind, counter[kind]), "kind": kind,
			"outdoor": LEGEND[cs[0]][1], "rects": rects(comp)}
		if name:
			region["name"] = name
		if kind == "room":
			rooms_px.append((comp, region))
		regions.append(region)


# --- Zimmer: Tür, Fenster, Nummer ------------------------------------------------------------------

def touching(comp, colour, reach=3):
	"""Pixel der Farbe, die höchstens reach Pixel neben der Fläche liegen."""
	found = set()
	ps = set(comp)
	for j in comp:
		x, y = j % W, j // W
		for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
			X, Y = x + dx, y + dy
			if Y * W + X in ps:
				continue
			for k in range(1, reach + 1):
				if col(x + dx * k, y + dy * k) == colour:
					found.add((x + dx * k, y + dy * k))
	return found

def groups(pixels):
	"""Pixel in zusammenhängende Striche teilen → [(mitte_x, mitte_y, breite_px)]."""
	left = set(pixels)
	out = []
	while left:
		p = left.pop()
		st, g = [p], [p]
		while st:
			a, b = st.pop()
			for q in ((a + 1, b), (a - 1, b), (a, b + 1), (a, b - 1)):
				if q in left:
					left.remove(q)
					st.append(q)
					g.append(q)
		xs = [q[0] for q in g]
		ys = [q[1] for q in g]
		out.append(((min(xs) + max(xs) + 1) / 2, (min(ys) + max(ys) + 1) / 2, max(max(xs) - min(xs), max(ys) - min(ys)) + 1))
	return out

def opening_info(comp, colour, cx, cy):
	out = []
	for gx, gy, width in groups(touching(comp, colour)):
		vx, vy = gx - cx, gy - cy
		normal = [1 if vx > 0 else -1, 0] if abs(vx) > abs(vy) else [0, 1 if vy > 0 else -1]
		out.append({"pos": m(gx, gy), "normal": normal, "width": round(width * PX, 2)})
	return out

rooms = []
for comp, region in rooms_px:
	xs = [j % W for j in comp]
	ys = [j // W for j in comp]
	cx, cy = sum(xs) / len(xs), sum(ys) / len(ys)
	doors = opening_info(comp, "99e550", cx, cy)
	assert len(doors) == 1, "Zimmer bei %s hat %d Flurtüren" % (m(cx, cy), len(doors))
	rooms.append({"comp": comp, "region": region, "cx": cx, "cy": cy, "door": doors[0],
		"windows": opening_info(comp, "50a3e5", cx, cy), "garden_doors": opening_info(comp, "35ff00", cx, cy)})

def number_rooms():
	for name, w in WINGS.items():
		loop, cross = [], []
		for r in rooms:
			if (r["cx"] < WING_SPLIT_X) != (name == "west"):
				continue
			# Punkt 2 m vor der Tür im Flur
			dx, dz = r["door"]["normal"]
			px = r["door"]["pos"][0] / PX + ORIGIN[0] + dx * 20
			py = r["door"]["pos"][1] / PX + ORIGIN[1] + dz * 20
			best, t0 = None, 0.0
			for (ax, ay), (bx, by) in zip(w["path"], w["path"][1:]):
				L = math.hypot(bx - ax, by - ay)
				u = max(0.0, min(1.0, ((px - ax) * (bx - ax) + (py - ay) * (by - ay)) / L / L))
				qx, qy = ax + u * (bx - ax), ay + u * (by - ay)
				d = math.hypot(px - qx, py - qy)
				if d < 30 and (best is None or d < best[0]):
					# rechte Hand: Kreuzprodukt Laufrichtung × (Zimmer − Flurpunkt), Bild-y zeigt nach unten
					best = (d, t0 + u * L, (bx - ax) * (r["cy"] - qy) - (by - ay) * (r["cx"] - qx) > 0)
				t0 += L
			if best:
				loop.append((best[1], best[2], r))
			else:
				y, x0, direction = w["cross"]
				assert abs(py - y) < 30, "Zimmer bei %s liegt an keinem bekannten Flur" % m(r["cx"], r["cy"])
				right = (r["cy"] > y) if direction > 0 else (r["cy"] < y)
				cross.append(((px - x0) * direction, right, r))
		odd, even = w["base"] + 1, w["base"] + 2
		for _, right, r in sorted(loop, key=lambda e: e[0]) + sorted(cross, key=lambda e: e[0]):
			if right:
				r["no"], odd = "%04d" % odd, odd + 2
			else:
				r["no"], even = "%04d" % even, even + 2
			r["wing"] = name

number_rooms()
room_list = []
for r in sorted(rooms, key=lambda r: r["no"]):
	r["region"]["id"] = r["no"]
	entry = {"no": r["no"], "sign": BROKEN_SIGNS.get(r["no"], r["no"]), "wing": r["wing"],
		"rects": r["region"]["rects"], "center": m(r["cx"], r["cy"]), "door": r["door"]}
	if r["windows"]:
		entry["windows"] = r["windows"]
	if r["garden_doors"]:
		entry["garden_doors"] = r["garden_doors"]
	room_list.append(entry)


# --- Einbauten ---------------------------------------------------------------------------------------

def take(kind):
	return [r for r in regions if r["kind"] == kind]

trees = []
for t in take("tree"):
	x0 = min(r[0] for r in t["rects"]); x1 = max(r[2] for r in t["rects"])
	z0 = min(r[1] for r in t["rects"]); z1 = max(r[3] for r in t["rects"])
	trees.append({"center": [round((x0 + x1) / 2, 2), round((z0 + z1) / 2, 2)], "radius": round((x1 - x0) / 2, 2)})

def outer(rs):
	return [min(r[0] for r in rs), min(r[1] for r in rs), max(r[2] for r in rs), max(r[3] for r in rs)]

stairwells = []
for s in take("stairwell"):
	stairwells.append({"rect": outer(s["rects"])})
# Treppenhäuser sind zusammengesetzt (Fläche + Stufenstriche): Teile mit überlappendem Rechteck vereinen
merged = []
for s in stairwells:
	for t in merged:
		r, q = s["rect"], t["rect"]
		if r[0] <= q[2] + 0.2 and q[0] <= r[2] + 0.2 and r[1] <= q[3] + 0.2 and q[1] <= r[3] + 0.2:
			t["rect"] = [min(r[0], q[0]), min(r[1], q[1]), max(r[2], q[2]), max(r[3], q[3])]
			break
	else:
		merged.append(s)
for s in merged:
	cx = (s["rect"][0] + s["rect"][2]) / 2
	s["wing"] = "west" if cx < 0 else "ost"
	s["id"] = "treppenhaus_" + s["wing"]
	# Tür: Flurtür auf einer der vier Kanten
	x0, z0, x1, z1 = [v / PX for v in s["rect"]]
	x0, z0, x1, z1 = x0 + ORIGIN[0], z0 + ORIGIN[1], x1 + ORIGIN[0], z1 + ORIGIN[1]
	edge = {"S": [(x, int(z1) + 1) for x in range(int(x0), int(x1))], "N": [(x, int(z0) - 2) for x in range(int(x0), int(x1))],
		"W": [(int(x0) - 2, y) for y in range(int(z0), int(z1))], "E": [(int(x1) + 1, y) for y in range(int(z0), int(z1))]}
	for side, pts in edge.items():
		hits = [p for p in pts if col(*p) == "99e550"]
		if hits:
			s["door"] = {"pos": m(sum(p[0] for p in hits) / len(hits) + 0.5, sum(p[1] for p in hits) / len(hits) + 0.5),
				"side": side}
regions = [r for r in regions if r["kind"] != "stairwell"]

layout = {
	"source": SRC, "meters_per_pixel": PX, "origin_px": list(ORIGIN),
	"walls": walls,
	"regions": [r for r in regions if r["kind"] not in ("tree", "planter", "reception", "terrace_edge")],
	"rooms": room_list,
	"planters": [outer(r["rects"]) for r in take("planter")],
	"terrace_edges": [r["rects"] for r in take("terrace_edge")],
	"trees": trees,
	"reception": [rc for r in take("reception") for rc in r["rects"]],
	"lobby": lobby,
	"stairwells": merged,
}

# Prüfungen: Ergebnis muss zum Plan passen
assert len(room_list) == len({r["no"] for r in room_list}), "doppelte Zimmernummer"
assert any(r["no"] == "0113" for r in room_list), "Spielerzimmer 0113 fehlt"

with open(DST, "w", encoding="utf-8", newline="\n") as f:
	json.dump(layout, f, ensure_ascii=False, indent="\t")
	f.write("\n")
n_ops = sum(len(w.get("openings", [])) for w in walls)
print("%s: %d Wände (%d Öffnungen), %d Flächen, %d Zimmer (Ost %d, West %d), %d Kübel, %d Bäume, %d Treppenhäuser"
	% (DST, len(walls), n_ops, len(layout["regions"]), len(room_list),
		sum(r["wing"] == "ost" for r in room_list), sum(r["wing"] == "west" for r in room_list),
		len(layout["planters"]), len(trees), len(merged)))


# --- Vorschau aus den Layout-Daten (zur Kontrolle, nicht aus dem Bild) ----------------------------------

if PREVIEW:
	colors = {"room": "#ffb08a", "corridor": "#dde8f2", "garden": "#c8f5bd", "terrace": "#d5e8cf", "service": "#f4f4f4",
		"storage": "#cfcfcf", "bar": "#b5c47a", "party": "#ddb0e0", "toilet": "#7fd6ff", "pool_water": "#3aa6ff",
		"pool_deck": "#c3d2de", "elevator": "#a9dccb"}
	op_colors = {"door": "#2e9e00", "garden_door": "#00d000", "window": "#2a7fd0", "glass_double_door": "#e0c000",
		"service_door": "#999", "elevator_door": "#00c090", "main_entrance": "#e00000"}
	out = ['<svg xmlns="http://www.w3.org/2000/svg" viewBox="-80 -118 160 128" width="100%" style="background:#fff">']
	for r in layout["regions"]:
		for x0, z0, x1, z1 in r["rects"]:
			out.append('<rect x="%s" y="%s" width="%s" height="%s" fill="%s"/>' % (x0, z0, x1 - x0, z1 - z0, colors.get(r["kind"], "#eee")))
	for x0, z0, x1, z1 in layout["planters"]:
		out.append('<rect x="%s" y="%s" width="%s" height="%s" fill="#5c9a4c"/>' % (x0, z0, x1 - x0, z1 - z0))
	for t in trees:
		out.append('<circle cx="%s" cy="%s" r="%s" fill="#2d8f12"/>' % (t["center"][0], t["center"][1], t["radius"]))
	for s in merged:
		x0, z0, x1, z1 = s["rect"]
		out.append('<rect x="%s" y="%s" width="%s" height="%s" fill="#bbb" stroke="#555" stroke-width=".1"/>' % (x0, z0, x1 - x0, z1 - z0))
	v = lobby["void"]
	out.append('<rect x="%s" y="%s" width="%s" height="%s" fill="none" stroke="#7a8d99" stroke-width=".2" stroke-dasharray=".6 .4"/>' % (v[0], v[1], v[2] - v[0], v[3] - v[1]))
	s = lobby["stair"]["rect"]
	out.append('<rect x="%s" y="%s" width="%s" height="%s" fill="#9badb7"/>' % (s[0], s[1], s[2] - s[0], s[3] - s[1]))
	for x0, z0, x1, z1 in layout["reception"]:
		out.append('<rect x="%s" y="%s" width="%s" height="%s" fill="#df7126"/>' % (x0, z0, x1 - x0, z1 - z0))
	for w in walls:
		(ax, az), (bx, bz) = w["a"], w["b"]
		out.append('<line x1="%s" y1="%s" x2="%s" y2="%s" stroke="%s" stroke-width="%s"/>' % (ax, az, bx, bz, "#8cc" if w.get("glass") else "#000", w["thickness"]))
		L = math.hypot(bx - ax, bz - az)
		for o in w.get("openings", []):
			f0, f1 = o["at"] / L, (o["at"] + o["width"]) / L
			out.append('<line x1="%s" y1="%s" x2="%s" y2="%s" stroke="%s" stroke-width=".45"/>' % (
				ax + (bx - ax) * f0, az + (bz - az) * f0, ax + (bx - ax) * f1, az + (bz - az) * f1, op_colors[o["kind"]]))
	for r in room_list:
		fill = "#c00000" if r["sign"] != r["no"] else "#000"
		out.append('<text x="%s" y="%s" font-size="1.5" text-anchor="middle" font-family="Arial" fill="%s">%s</text>' % (r["center"][0], r["center"][1] + 0.5, fill, r["no"]))
	out.append("</svg>")
	open(PREVIEW, "w", encoding="utf-8").write("\n".join(out))
