# Baut die Bücher der Bibliotheksregale (Books, ZIM-153, Entscheidung 3.11.): VARIANTS alte Leinen- und Lederbände
# mit rundem Rücken (halbe Ellipse), Falz an beiden Seiten und Deckelüberstand (SQUARE) an Kopf, Schwanz und Vorderkante,
# der Buchblock darin mit hohlem Vorderschnitt. Ganzleder mit erhabenen Bünden, Halbleder (Lederrücken mit Bünden, Deckel
# Leinen mit Lederecken) und Ganzleinen mit glattem Rücken. Prägung nur als Linien (Gold oder blind, Rahmen,
# Doppellinien, Rauten), keine Schrift.
#
# Alle Varianten teilen einen Atlas ATLAS² (Farbe, Normal Map, Masken), die UVs legt das Skript selbst an: je Variante
# eine Insel für den Rücken (Bogenlänge × Höhe, dicht), eine für beide Deckel (gespiegelt), eine für Kopf- und Fußschnitt,
# eine für den Vorderschnitt und ein kleines Feld für Kanten und Innenseiten. Die Karten malt numpy aus Formeln im
# Raum (Meter) – Narbung, Gewebe, Bünde, Linien, Abrieb –, die Normale aus einer Höhe. Bezug (Leder, Leinen) ist im
# Farbbild grau: Die Farbe je Buch gibt Books im Spiel dazu (Maske Rot). Die Verschattung steckt im Farbbild.
#   <tex>_albedo.png   Farbe (sRGB): Bezug grau mit Verschattung, Gold und Papier in Farbe
#   <tex>_normal.png   Normal Map (OpenGL, Tangentenraum)
#   <tex>_mask.png     Rot = Bezug (wird gefärbt), Grün = Rauheit, Blau = Metall (Gold)
# Dazu <glb ohne .glb>.json mit den Maßen je Variante (Books liest sie).
#
# Lage (Godot-Achsen, wie Books): Buch stehend, Boden y = 0, Mitte der Stärke x = 0, Rücken vorn bei z = 0, Vorderschnitt
# hinten bei z = −Tiefe. Objekte „book_0“ … „book_<n>“.
#
# Aufruf aus dem Projektordner (Blender 4.3):
#   blender -b --python tools/build_books.py -- assets/models/books.glb assets/textures/books
import bpy, sys, os, math, json
import numpy as np
from mathutils import Vector

sys.path.append(os.path.dirname(os.path.abspath(__file__)))
from furniture_kit import B, save_image

argv = sys.argv[sys.argv.index("--") + 1:]
DST = os.path.abspath(argv[0])
TEX = os.path.abspath(argv[1])

# --- Varianten ---------------------------------------------------------------------------------------------------
# Name, Stärke, Höhe, Tiefe (m), Bezug, Bünde, Schnitt (None, „rot“ gesprenkelt, „gelb“, „gold“)
VARIANTS = [
	("oktav", 0.038, 0.215, 0.140, "leder", 5, "rot"),
	("oktav_duenn", 0.022, 0.205, 0.135, "leinen", 0, None),
	("oktav_dick", 0.055, 0.225, 0.150, "halb", 4, "gelb"),
	("duodez", 0.028, 0.170, 0.110, "leder", 0, None),
	("quart", 0.050, 0.285, 0.215, "leder", 5, "gold"),
	("quart_leinen", 0.034, 0.270, 0.200, "leinen", 0, None),
	("grossoktav", 0.042, 0.245, 0.165, "halb", 5, "rot"),
	("folio", 0.066, 0.330, 0.245, "leder", 6, None),
	("lexikon", 0.060, 0.255, 0.180, "halb", 4, "gelb"),
	("schmal", 0.018, 0.240, 0.160, "leinen", 0, None),
]

# --- Maße (Meter) ------------------------------------------------------------------------------------------------
BOARD = 0.0032            # Deckel samt Bezug
SQUARE = 0.003            # Überstand der Deckel über den Buchblock
SPINE_T = 0.0018          # Bezug am Rücken (Scheitel)
ROUND = 0.20              # Wölbung des Rückens: Anteil der Stärke, dazu ROUND_ADD
ROUND_ADD = 0.002
JOINT = 0.0012            # Falz: so tief eingezogen
JOINT_W = 0.0035          # … und so breit (entlang z)
ARC = 8                   # Abschnitte des Rückenbogens
FORE_HOLLOW = 0.6         # hohler Vorderschnitt: Anteil der Rückenwölbung
FORE = 4                  # Abschnitte des Vorderschnitts (je zwei Bogenabschnitte)

# Bünde und Prägung
BAND_H = 0.0011           # Höhe eines Bundes
BAND_W = 0.0032           # halbe Breite eines Bundes
GILT_W = 0.0007           # Goldlinie
BLIND_W = 0.0006          # Blindlinie
LINE_DEPTH = 0.00012      # Linien liegen so tief
PANEL_INSET = 0.0032      # Rahmen im Feld zwischen den Bünden

ATLAS = 2048
MARGIN = 8                # px zwischen den Inseln
PAD = 4                   # px, um die jede Insel über ihren Rand hinaus gemalt wird (Mipmaps)
# Texeldichte (px/m) je Insel; reicht der Atlas nicht, wird alles gleichmäßig verkleinert
DENSITY = {"spine": 4200.0, "board": 1500.0, "pages": 3000.0, "fore": 1200.0}
EDGE_PX = 40

GILT = np.array([0.74, 0.58, 0.30])
PAPER = np.array([0.80, 0.74, 0.60])
EDGE_COLORS = {"rot": np.array([0.55, 0.20, 0.15]), "gelb": np.array([0.78, 0.62, 0.30])}

bpy.ops.wm.read_factory_settings(use_empty=True)


# --- Rauschen in Metern (überall gleich groß, egal welche Insel) ---------------------------------------------------
def hash2(ix, iy, seed):
	h = (ix.astype(np.int64) * 73856093) ^ (iy.astype(np.int64) * 19349663) ^ np.int64(seed * 83492791)
	h = (h ^ (h >> 13)) * np.int64(1274126177)
	h = h ^ (h >> 16)
	return (h & 0xFFFFFF).astype(np.float64) / float(0xFFFFFF)


def vnoise(U, V, cu, cv, seed):
	x, y = U / cu, V / cv
	ix, iy = np.floor(x), np.floor(y)
	fx, fy = x - ix, y - iy
	fx, fy = fx * fx * (3 - 2 * fx), fy * fy * (3 - 2 * fy)
	ix, iy = ix.astype(np.int64), iy.astype(np.int64)
	a = hash2(ix, iy, seed) * (1 - fx) + hash2(ix + 1, iy, seed) * fx
	b = hash2(ix, iy + 1, seed) * (1 - fx) + hash2(ix + 1, iy + 1, seed) * fx
	return a * (1 - fy) + b * fy


## Summe mehrerer Oktaven, 0..1; Oktaven feiner als zwei Pixel fallen weg (sonst flimmert es)
def fbm(U, V, cell, seed, rho, octaves=3, stretch=(1.0, 1.0)):
	out = np.zeros_like(U)
	amp, total = 1.0, 0.0
	for o in range(octaves):
		c = cell / 2 ** o
		k = np.clip((c * min(stretch) * rho - 2.0) / 2.0, 0.0, 1.0)
		if k <= 0:
			break
		out += amp * k * (vnoise(U, V, c * stretch[0], c * stretch[1], seed + 17 * o) - 0.5)
		total += amp
		amp *= 0.5
	return 0.5 + out / max(total, 1e-6)


## Zellen (Worley): Abstand zum nächsten und zweitnächsten Punkt, in Zellen
def worley(U, V, cell, seed):
	x, y = U / cell, V / cell
	cx, cy = np.floor(x).astype(np.int64), np.floor(y).astype(np.int64)
	f1 = np.full(U.shape, 9.0)
	f2 = np.full(U.shape, 9.0)
	for dy in (-1, 0, 1):
		for dx in (-1, 0, 1):
			px = cx + dx + hash2(cx + dx, cy + dy, seed)
			py = cy + dy + hash2(cx + dx, cy + dy, seed + 1)
			d = np.hypot(x - px, y - py)
			f2 = np.where(d < f1, f1, np.minimum(f2, d))
			f1 = np.minimum(f1, d)
	return f1, f2


## Deckung einer Linie im Abstand d (m), mindestens 1,2 px breit (schmaler: blasser statt flimmernd)
def line(d, width, rho):
	w = max(width, 1.2 / rho)
	return np.clip((w / 2 - np.abs(d)) * rho + 0.5, 0, 1) * (width / w)


## Rahmen (Rechteck von u0..u1, v0..v1) als Linie
def frame(U, V, u0, u1, v0, v1, width, rho):
	inside_u = (U > u0 - width) & (U < u1 + width)
	inside_v = (V > v0 - width) & (V < v1 + width)
	h = np.maximum(line(V - v0, width, rho), line(V - v1, width, rho)) * inside_u
	v = np.maximum(line(U - u0, width, rho), line(U - u1, width, rho)) * inside_v
	return np.maximum(h, v)


## Raute (Mitte, halbe Diagonalen) als Linie
def lozenge(U, V, cu, cv, ru, rv, width, rho):
	d = np.abs(U - cu) / ru + np.abs(V - cv) / rv - 1.0
	return line(d * min(ru, rv), width, rho)


def smooth(e0, e1, x):
	t = np.clip((x - e0) / (e1 - e0), 0, 1)
	return t * t * (3 - 2 * t)


# --- Oberflächen: Rückgabe Bezug (grau), Farbe, Maske Bezug, Rauheit, Metall, Höhe ---------------------------------
class Surf:
	def __init__(self, shape):
		self.cover = np.full(shape, 0.78)     # Grau des Bezugs (wird gefärbt)
		self.color = np.zeros(shape + (3,))   # Farbe, wo nicht gefärbt (Gold, Papier)
		self.tint = np.ones(shape)            # 1 = Bezug
		self.rough = np.full(shape, 0.6)
		self.metal = np.zeros(shape)
		self.height = np.zeros(shape)
		self.shade = np.ones(shape)           # Verschattung, steckt am Ende im Farbbild


## Leder: fleckig, Narbung (Zellen), feine Poren, Glanz seidenmatt
def leather(s, U, V, rho, seed, grain=0.0011):
	mottle = fbm(U, V, 0.014, seed, rho)
	s.cover = 0.74 + 0.20 * (mottle - 0.5)
	cell = max(grain, 3.0 / rho)
	f1, f2 = worley(U, V, cell, seed + 3)
	crease = 1 - smooth(0.0, 0.25, f2 - f1)
	k = np.clip((grain * rho - 2.0) / 2.0, 0.3, 1.0)
	s.cover -= 0.07 * crease * k
	s.height += -0.00003 * crease * k + 0.00001 * (fbm(U, V, 0.003, seed + 5, rho) - 0.5)
	s.rough = 0.64 + 0.12 * (mottle - 0.5) + 0.06 * crease
	return mottle


## Leinen: Gewebe (Leinwandbindung), leicht unruhige Fäden, matt
def cloth(s, U, V, rho, seed):
	p = max(0.0011, 4.0 / rho)
	k = np.clip((0.0011 * rho - 2.0) / 3.0, 0.25, 1.0)
	slub_u = fbm(U, V, 0.004, seed, rho, 2, (0.15, 1.0))
	slub_v = fbm(U, V, 0.004, seed + 9, rho, 2, (1.0, 0.15))
	wu = np.sin(2 * math.pi * (U / p + 0.3 * slub_v))
	wv = np.sin(2 * math.pi * (V / p + 0.3 * slub_u))
	weave = wu * wv
	mottle = fbm(U, V, 0.02, seed + 2, rho)
	s.cover = (0.76 + 0.14 * (mottle - 0.5)) * (1 + 0.05 * k * weave) * (0.96 + 0.08 * (slub_u - 0.5))
	s.height += 0.000025 * k * weave
	s.rough = 0.84 + 0.06 * (mottle - 0.5)
	return mottle


## Linien prägen: gilt (Gold, abgerieben wo wear) und blind (nur vertieft, dunkler)
def stamp(s, U, V, rho, gilt, blind, wear, seed):
	worn = np.clip(1.25 * fbm(U, V, 0.003, seed + 31, rho, 2) - 0.35 + 1.2 * wear, 0, 1)
	g = gilt * (1 - worn)
	groove = np.maximum(gilt, blind)
	s.height -= LINE_DEPTH * groove
	s.shade *= 1 - 0.22 * groove
	gold = GILT[None, None, :] * (0.85 + 0.3 * fbm(U, V, 0.0015, seed + 33, rho, 2))[..., None]
	s.color = s.color * (1 - g[..., None]) + gold * g[..., None]
	s.tint *= 1 - g
	s.rough = s.rough * (1 - g) + (0.3 + 0.25 * worn) * g
	s.metal = np.maximum(s.metal, 0.9 * g)


## Abrieb: heller und stumpfer
def rub(s, amount):
	s.cover = s.cover + (0.98 - s.cover) * 0.45 * amount
	s.rough = s.rough + 0.2 * amount


# --- Inseln ------------------------------------------------------------------------------------------------------
def spine_surface(v, s, U, V, rho, L, sa, sb, H):
	name, T, _, D, kind, bands, edge = v
	seed = 101 + 7 * VARIANTS.index(v)
	leathery = kind != "leinen"
	if leathery:
		leather(s, U, V, rho, seed)
	else:
		cloth(s, U, V, rho, seed)
	in_arc = smooth(sa - 0.0005, sa + 0.0015, U) * smooth(sb + 0.0005, sb - 0.0015, U)
	ua, ub = sa + PANEL_INSET * 0.8, sb - PANEL_INSET * 0.8   # Rahmen im Feld
	gilt = np.zeros_like(U)
	blind = np.zeros_like(U)
	# Kopf und Schwanz abgegriffen (Finger beim Herausziehen), dazu Kratzer längs
	ht = np.clip(1 - np.minimum(V, H - V) / 0.007, 0, 1) ** 1.5 * (0.5 + 0.5 * fbm(U, V, 0.004, seed + 40, rho))
	scratch = np.clip((fbm(U, V, 0.03, seed + 41, rho, 2, (0.08, 1.0)) - 0.72) * 6.0, 0, 1)
	crown = np.clip(1 - np.abs(U - (sa + sb) / 2) / max((sb - sa) / 2, 1e-4), 0, 1)
	if leathery:
		y_bot = max(0.024, 0.11 * H)
		y_top = H - max(0.016, 0.065 * H)
		n = bands if bands > 0 else 4
		ys = list(np.linspace(y_bot, y_top, n))
		if bands > 0:
			for yb in ys:
				d = np.abs(V - yb)
				bump = np.where(d < BAND_W, 0.5 * (1 + np.cos(math.pi * d / BAND_W)), 0.0) * in_arc
				s.height += BAND_H * bump
				s.shade *= 1 - 0.18 * np.clip(1 - np.abs(d - BAND_W) / 0.0012, 0, 1) * in_arc   # Fuß des Bundes
				rub(s, 0.6 * np.clip(bump - 0.6, 0, 1) / 0.4 * (0.6 + 0.4 * crown))
				for off in (-1, 1):
					gilt = np.maximum(gilt, line(V - (yb + off * (BAND_W + 0.0013)), GILT_W, rho) * in_arc)
			edge_gap = BAND_W + 0.0013 + PANEL_INSET
		else:
			# glatter Rücken: Doppellinien statt Bünden
			for yb in ys:
				for off in (-0.0011, 0.0011):
					gilt = np.maximum(gilt, line(V - (yb + off), GILT_W, rho) * in_arc)
			edge_gap = 0.0011 + PANEL_INSET
		# Felder: Rahmen in jedem Feld zwischen zwei Bünden, im zweiten von oben das dunklere Rückenschild
		for i in range(len(ys) - 1):
			v0, v1 = ys[i] + edge_gap, ys[i + 1] - edge_gap
			if v1 - v0 < 0.006:
				continue
			label = i == len(ys) - 2
			if label:
				lab = smooth(ua - 0.0008, ua, U) * smooth(ub + 0.0008, ub, U) * smooth(v0 - 0.0008, v0, V) * smooth(v1 + 0.0008, v1, V)
				s.cover *= 1 - 0.5 * lab
				s.height += 0.00008 * lab
				gilt = np.maximum(gilt, frame(U, V, ua + 0.0012, ub - 0.0012, v0 + 0.0012, v1 - 0.0012, GILT_W * 0.8, rho))
			elif (i + seed) % 2 == 0:
				gilt = np.maximum(gilt, frame(U, V, ua, ub, v0, v1, GILT_W * 0.8, rho))
				ru = (ub - ua) / 2 - 0.0025
				if ru > 0.003:
					gilt = np.maximum(gilt, lozenge(U, V, (ua + ub) / 2, (v0 + v1) / 2, ru, min(ru * 1.6, (v1 - v0) / 2 - 0.0025), GILT_W * 0.8, rho))
			else:
				blind = np.maximum(blind, frame(U, V, ua, ub, v0, v1, BLIND_W, rho))
		# Doppellinien an Kopf und Schwanz
		for y in (0.0045, 0.006):
			gilt = np.maximum(gilt, line(V - y, GILT_W, rho) * in_arc)
			gilt = np.maximum(gilt, line(V - (H - y), GILT_W, rho) * in_arc)
		# Leder reißt im Falz ein
		for edge_s, sign in ((sa, 1), (sb, -1)):
			wob = 0.0006 * (fbm(U, V, 0.01, seed + 50, rho, 2) - 0.5)
			crack = line(U - (edge_s + sign * 0.0009) - wob, 0.0004, rho) * np.clip((fbm(U, V, 0.02, seed + 51, rho, 2) - 0.45) * 4, 0, 1)
			s.cover *= 1 - 0.45 * crack
			s.height -= 0.0001 * crack
	else:
		# Leinen: Doppellinien in Gold an Kopf und Schwanz, ein Schildrahmen oben, ein Blindrahmen in der Mitte
		for y in (0.011, 0.0135):
			gilt = np.maximum(gilt, line(V - y, GILT_W, rho) * in_arc)
			gilt = np.maximum(gilt, line(V - (H - y), GILT_W, rho) * in_arc)
		top0, top1 = H - 0.068, H - 0.026
		gilt = np.maximum(gilt, frame(U, V, ua, ub, top0, top1, GILT_W * 0.8, rho))
		blind = np.maximum(blind, frame(U, V, ua, ub, 0.30 * H, 0.62 * H, BLIND_W, rho))
		blind = np.maximum(blind, frame(U, V, ua + 0.0014, ub - 0.0014, 0.30 * H + 0.0014, 0.62 * H - 0.0014, BLIND_W, rho))
		# ausgeblichen: vom Licht im Regal, zur Mitte stärker
		s.cover = s.cover + (0.95 - s.cover) * 0.22 * crown
	rub(s, ht + 0.35 * scratch)
	stamp(s, U, V, rho, gilt, blind, ht, seed)


def board_surface(v, s, U, V, rho, Lb, H):
	name, T, _, D, kind, bands, edge = v
	seed = 211 + 7 * VARIANTS.index(v)
	# Ränder abgestoßen, die Ecken an der Vorderkante am stärksten
	edge_d = np.minimum(np.minimum(U, Lb - U), np.minimum(V, H - V))
	corner = np.minimum(np.hypot(U, V), np.hypot(U, H - V))
	wear = np.clip(1 - edge_d / 0.0025, 0, 1) * 0.6 + np.clip(1 - corner / 0.014, 0, 1) ** 1.5
	wear *= 0.5 + 0.5 * fbm(U, V, 0.006, seed + 3, rho)
	gilt = np.zeros_like(U)
	blind = np.zeros_like(U)
	if kind == "leder":
		leather(s, U, V, rho, seed, 0.0016)
		blind = np.maximum(frame(U, V, 0.006, Lb - 0.006, 0.006, H - 0.006, BLIND_W * 1.4, rho),
			frame(U, V, 0.0085, Lb - 0.0085, 0.0085, H - 0.0085, BLIND_W, rho))
	elif kind == "halb":
		# Leinen auf dem Deckel, Leder am Rücken entlang und als Ecken vorn, dazwischen eine feine Goldlinie
		ls = Surf(U.shape)
		leather(ls, U, V, rho, seed, 0.0016)
		cloth(s, U, V, rho, seed + 1)
		s.cover *= 0.82
		strip = Lb - max(0.02, 0.09 * H)
		cut = 0.026 + 0.05 * H
		# Abstand zur Grenze, < 0 auf dem Leder: Ecken schräg abgeschnitten, Streifen am Rücken
		dist = np.minimum((np.minimum(U + V, U + (H - V)) - cut) / math.sqrt(2), strip - U)
		lm = np.clip(-dist * rho + 0.5, 0, 1)
		s.cover = s.cover * (1 - lm) + ls.cover * lm
		s.rough = s.rough * (1 - lm) + ls.rough * lm
		s.height = s.height * (1 - lm) + ls.height * lm + 0.0002 * lm   # Leder liegt über dem Leinen
		gilt = line(dist + 0.0012, GILT_W * 0.8, rho)
	else:
		cloth(s, U, V, rho, seed)
		blind = frame(U, V, 0.0055, Lb - 0.0055, 0.0055, H - 0.0055, BLIND_W, rho)
	rub(s, wear)
	stamp(s, U, V, rho, gilt, blind, wear, seed)


## Papier: Blätter als feine Streifen längs (Lagen alle paar Millimeter dunkler), vergilbt, oben staubig
def paper_surface(v, s, U, V, rho, W, top, seed):
	name, T, _, D, kind, bands, edge = v
	page = fbm(U, V, 0.004, seed, rho, 3, (0.3, 15.0))
	sig = np.clip((fbm(U, V, 0.004, seed + 1, rho, 1, (1.0, 60.0)) - 0.62) * 5, 0, 1)
	outer = np.exp(-np.minimum(U, W - U) / 0.0018)
	col = PAPER[None, None, :] * (0.92 + 0.12 * (page - 0.5))[..., None]
	col *= (1 - 0.18 * sig)[..., None]
	col = col * (1 - 0.22 * outer)[..., None] + np.array([0.55, 0.45, 0.30])[None, None, :] * 0.22 * outer[..., None]
	rough = np.full(U.shape, 0.9)
	metal = np.zeros(U.shape)
	if top:
		dust = 0.75 + 0.15 * fbm(U, V, 0.02, seed + 4, rho)
		col *= dust[..., None]
	if edge == "rot" or edge == "gelb":   # Farbschnitt, rot gesprenkelt
		if edge == "rot":
			k = np.clip((fbm(U, V, 0.0016, seed + 6, rho, 2) - 0.56) * 6, 0, 1) * 0.6
		else:
			k = np.full(U.shape, 0.7)
		col = col * (1 - k[..., None]) + EDGE_COLORS[edge][None, None, :] * col.mean(-1, keepdims=True) / 0.7 * k[..., None]
	elif edge == "gold" and top:
		g = np.clip(0.95 - 0.6 * fbm(U, V, 0.004, seed + 7, rho, 2), 0, 1)
		col = col * (1 - g[..., None]) + GILT[None, None, :] * g[..., None]
		rough = rough * (1 - g) + 0.35 * g
		metal = 0.9 * g
	s.color = col
	s.tint = np.zeros(U.shape)
	s.rough = rough
	s.metal = metal
	s.height = 0.000015 * (page - 0.5) - 0.00004 * sig
	s.shade = 1 - 0.3 * outer


# --- Atlas -------------------------------------------------------------------------------------------------------
class Island:
	def __init__(self, key, w_m, h_m, rho):
		self.key, self.w_m, self.h_m, self.rho = key, w_m, h_m, rho
		self.x = self.y = 0
		self.w = self.h = 0

	## UV (Blender, v nach oben) eines Punkts (u, v in Metern) der Insel
	def uv(self, u, v):
		return ((self.x + u * self.rho) / ATLAS, 1.0 - (self.y + self.h - v * self.rho) / ATLAS)


def pack(islands):
	scale = 1.0
	while True:
		for isl in islands:
			isl.rho = isl.base * scale
			isl.w = int(math.ceil(isl.w_m * isl.rho)) if isl.key[1] != "edge" else EDGE_PX
			isl.h = int(math.ceil(isl.h_m * isl.rho)) if isl.key[1] != "edge" else EDGE_PX
		# Skyline: jede Insel (die höchsten zuerst) dorthin, wo ihre Oberkante am höchsten im Bild bleibt
		sky = np.full(ATLAS, MARGIN)
		ok = True
		for isl in sorted(islands, key=lambda i: (-i.h, -i.w)):
			w = isl.w + MARGIN
			best = None
			for x in range(MARGIN, ATLAS - w + 1, 4):
				y = int(sky[x:x + w].max())
				if best is None or y < best[1]:
					best = (x, y)
			if best is None or best[1] + isl.h + MARGIN > ATLAS:
				ok = False
				break
			isl.x, isl.y = best
			sky[best[0]:best[0] + w] = best[1] + isl.h + MARGIN
		if ok:
			return scale
		scale *= 0.96


# --- Geometrie ---------------------------------------------------------------------------------------------------
def norm2(x, z):
	l = math.hypot(x, z)
	return (x / l, z / l)


## Querschnitt: Punkte außen und innen von der linken Vorderkante um den Rücken zur rechten, dazu die Normale außen an
## jedem Punkt (None = Abschnitt flach) und die Art (Deckel, Rücken)
def section(T, D):
	a = T / 2.0
	ai = a - BOARD
	r = ROUND * T + ROUND_ADD
	ri = r - SPINE_T
	zh = -(r + JOINT_W)
	zg = -(r + JOINT_W / 2.0)
	out = [(-a, -D), (-a, zh), (-a + JOINT, zg)]
	inn = [(-ai, -D), (-ai, zh), (-ai, zg)]
	nrm = [None, None, None]
	for k in range(ARC + 1):
		phi = math.pi - math.pi * k / ARC
		out.append((a * math.cos(phi), -r + r * math.sin(phi)))
		inn.append((ai * math.cos(phi), -r + ri * math.sin(phi)))
		nrm.append(norm2(math.cos(phi) / a, math.sin(phi) / r))
	out += [(a - JOINT, zg), (a, zh), (a, -D)]
	inn += [(ai, zg), (ai, zh), (ai, -D)]
	nrm += [None, None, None]
	return out, inn, nrm, a, ai, r, ri


class Mesh:
	def __init__(self):
		self.verts, self.faces, self.normals, self.uvs = [], [], [], []

	## Viereck (Godot-Punkte), Normalen je Ecke (oder eine für alle), UV je Ecke; dreht die Reihenfolge so, dass die
	## Fläche nach want zeigt
	def quad(self, pts, normals, uvs, want):
		p = [Vector(q) for q in pts]
		n = (p[1] - p[0]).cross(p[2] - p[0])
		if n.length < 1e-12:
			n = (p[2] - p[0]).cross(p[3] - p[0])
		if n.dot(Vector(want)) < 0:
			pts, normals, uvs = pts[::-1], normals[::-1], uvs[::-1]
		base = len(self.verts)
		for q, nn, uv in zip(pts, normals, uvs):
			self.verts.append(B(*q))
			self.normals.append(B(*nn).normalized())
			self.uvs.append(uv)
		self.faces.append(tuple(range(base, base + 4)))

	def finish(self, name):
		me = bpy.data.meshes.new(name)
		me.from_pydata(self.verts, [], self.faces)
		me.update()
		for p in me.polygons:
			p.use_smooth = True
		uv = me.uv_layers.new(name="UVMap")
		for p in me.polygons:
			for li in p.loop_indices:
				uv.data[li].uv = self.uvs[me.loops[li].vertex_index]
		me.normals_split_custom_set([tuple(self.normals[me.loops[li].vertex_index]) for li in range(len(me.loops))])
		ob = bpy.data.objects.new(name, me)
		bpy.context.collection.objects.link(ob)
		return ob


def build_book(index, v, isl):
	name, T, H, D, kind, bands, edge = v
	out, inn, nrm, a, ai, r, ri = section(T, D)
	n = len(out)
	m = Mesh()
	spine, board, pages, fore, edge_i = isl["spine"], isl["board"], isl["pages"], isl["fore"], isl["edge"]
	# Bogenlänge außen ab dem Falz links (Punkt 1) – Rücken-Insel
	s_at = [0.0] * n
	for i in range(2, n - 1):
		s_at[i] = s_at[i - 1] + math.dist(out[i - 1], out[i])
	Lb = D + out[1][1]
	# Außenseite
	for i in range(n - 1):
		(x0, z0), (x1, z1) = out[i], out[i + 1]
		flat = norm2(-(z1 - z0), x1 - x0)
		n0 = nrm[i] if nrm[i] is not None and nrm[i + 1] is not None else flat
		n1 = nrm[i + 1] if nrm[i] is not None and nrm[i + 1] is not None else flat
		if i == 0 or i == n - 2:   # Deckel: u ab der Vorderkante
			isl_i, u0, u1 = board, z0 + D, z1 + D
		else:
			isl_i, u0, u1 = spine, s_at[i], s_at[i + 1]
		pts = [(x0, 0, z0), (x1, 0, z1), (x1, H, z1), (x0, H, z0)]
		ns = [(n0[0], 0, n0[1]), (n1[0], 0, n1[1]), (n1[0], 0, n1[1]), (n0[0], 0, n0[1])]
		uvs = [isl_i.uv(u0, 0), isl_i.uv(u1, 0), isl_i.uv(u1, H), isl_i.uv(u0, H)]
		m.quad(pts, ns, uvs, (flat[0], 0, flat[1]))
	# Innenseite, Kanten oben und unten, Vorderkanten der Deckel: kleines Feld im Bezug
	e = lambda fu, fv: edge_i.uv((0.1 + 0.8 * fu) * edge_i.w_m, (0.1 + 0.8 * fv) * edge_i.h_m)
	for i in range(n - 1):
		(x0, z0), (x1, z1) = inn[i], inn[i + 1]
		if math.dist((x0, z0), (x1, z1)) < 1e-6:
			continue
		into = norm2(z1 - z0, -(x1 - x0))
		f0, f1 = i / (n - 1), (i + 1) / (n - 1)
		m.quad([(x0, 0, z0), (x1, 0, z1), (x1, H, z1), (x0, H, z0)], [(into[0], 0, into[1])] * 4,
			[e(f0, 0), e(f1, 0), e(f1, 1), e(f0, 1)], (into[0], 0, into[1]))
	for y, up in ((H, 1), (0.0, -1)):
		for i in range(n - 1):
			f0, f1 = i / (n - 1), (i + 1) / (n - 1)
			m.quad([(out[i][0], y, out[i][1]), (out[i + 1][0], y, out[i + 1][1]), (inn[i + 1][0], y, inn[i + 1][1]),
				(inn[i][0], y, inn[i][1])], [(0, up, 0)] * 4, [e(f0, 0), e(f1, 0), e(f1, 1), e(f0, 1)], (0, up, 0))
	for i in (0, n - 1):
		m.quad([(out[i][0], 0, -D), (inn[i][0], 0, -D), (inn[i][0], H, -D), (out[i][0], H, -D)], [(0, 0, -1)] * 4,
			[e(0, 0), e(1, 0), e(1, 1), e(0, 1)], (0, 0, -1))
	# Buchblock: Kopf und Fuß zwischen Rückenbogen innen und hohlem Vorderschnitt, dazu der Vorderschnitt
	c = FORE_HOLLOW * r
	arc_in = inn[3:3 + ARC + 1]
	fz = lambda x: -D + SQUARE + c * (1 - (x / ai) ** 2)
	fore_pts = [(x, fz(x)) for x, _ in arc_in]
	for y, up in ((H - SQUARE, 1), (SQUARE, -1)):
		for k in range(ARC):
			q = [arc_in[k], arc_in[k + 1], fore_pts[k + 1], fore_pts[k]]
			m.quad([(x, y, z) for x, z in q], [(0, up, 0)] * 4, [pages.uv(x + ai, z + D - SQUARE) for x, z in q], (0, up, 0))
	for k in range(0, ARC, ARC // FORE):
		(x0, z0), (x1, z1) = fore_pts[k], fore_pts[k + ARC // FORE]
		n0 = norm2(-2 * c * x0 / ai ** 2, -1)
		n1 = norm2(-2 * c * x1 / ai ** 2, -1)
		m.quad([(x0, SQUARE, z0), (x1, SQUARE, z1), (x1, H - SQUARE, z1), (x0, H - SQUARE, z0)],
			[(n0[0], 0, n0[1]), (n1[0], 0, n1[1]), (n1[0], 0, n1[1]), (n0[0], 0, n0[1])],
			[fore.uv(x0 + ai, 0), fore.uv(x1 + ai, 0), fore.uv(x1 + ai, H - 2 * SQUARE), fore.uv(x0 + ai, H - 2 * SQUARE)],
			(0, 0, -1))
	return m.finish("book_%d" % index), s_at, Lb, a, ai, r


# --- Bau ---------------------------------------------------------------------------------------------------------
islands = {}
geo = []
for vi, v in enumerate(VARIANTS):
	name, T, H, D, kind, bands, edge = v
	out, inn, nrm, a, ai, r, ri = section(T, D)
	Ls = sum(math.dist(out[i], out[i + 1]) for i in range(1, len(out) - 2))
	Lb = D + out[1][1]
	spec = {"spine": (Ls, H), "board": (Lb, H), "pages": (2 * ai, D - SQUARE), "fore": (2 * ai, H - 2 * SQUARE),
		"edge": (0.01, 0.01)}
	for k, (w, h) in spec.items():
		isl = Island((vi, k), w, h, 0.0)
		isl.base = DENSITY.get(k, 1000.0)
		islands[(vi, k)] = isl
scale = pack(list(islands.values()))
print("Atlas %d², Dichte × %.2f (Rücken %.0f px/m)" % (ATLAS, scale, DENSITY["spine"] * scale))
for isl in islands.values():
	if isl.key[1] == "edge":   # das Feld bekommt die Dichte des Deckels, seine Größe in Metern daraus
		isl.rho = DENSITY["board"] * scale
		isl.w_m, isl.h_m = isl.w / isl.rho, isl.h / isl.rho

albedo = np.zeros((ATLAS, ATLAS, 3))
normal = np.zeros((ATLAS, ATLAS, 3))
normal[..., 2] = 1.0
mask = np.zeros((ATLAS, ATLAS, 3))
mask[..., 1] = 1.0


## Insel malen: Fläche über ihren Rand hinaus (PAD), Normale aus der Höhe, alles in die Atlasbilder (Zeile 0 oben)
def paint(isl, fn):
	x0, y0 = isl.x - PAD, isl.y - PAD
	w, h = isl.w + 2 * PAD, isl.h + 2 * PAD
	cols = np.arange(w) + x0
	rows = np.arange(h) + y0
	U = ((cols + 0.5 - isl.x) / isl.rho)[None, :].repeat(h, 0)
	V = ((isl.y + isl.h - (rows + 0.5)) / isl.rho)[:, None].repeat(w, 1)
	s = Surf(U.shape)
	fn(s, U, V, isl.rho)
	dr, dx = np.gradient(s.height, 1.0 / isl.rho)
	n = np.stack([-dx, dr, np.ones_like(dx)], axis=-1)
	n /= np.linalg.norm(n, axis=-1, keepdims=True)
	t = np.clip(s.tint, 0, 1)[..., None]
	col = (t * np.clip(s.cover, 0, 1)[..., None] + (1 - t) * s.color) * np.clip(s.shade, 0, 1)[..., None]
	r0, c0 = max(0, y0), max(0, x0)
	r1, c1 = min(ATLAS, y0 + h), min(ATLAS, x0 + w)
	sl = (slice(r0 - y0, r1 - y0), slice(c0 - x0, c1 - x0))
	albedo[r0:r1, c0:c1] = col[sl]
	normal[r0:r1, c0:c1] = n[sl]
	mask[r0:r1, c0:c1] = np.stack([s.tint, np.clip(s.rough, 0.05, 1), np.clip(s.metal, 0, 1)], axis=-1)[sl]


meta = []
total = 0
obs = []
for vi, v in enumerate(VARIANTS):
	name, T, H, D, kind, bands, edge = v
	isl = {k: islands[(vi, k)] for k in ("spine", "board", "pages", "fore", "edge")}
	ob, s_at, Lb, a, ai, r = build_book(vi, v, isl)
	obs.append(ob)
	sa, sb = s_at[3], s_at[3 + ARC]   # Rückenbogen zwischen den Falzen
	Ls = s_at[len(s_at) - 2]
	paint(isl["spine"], lambda s, U, V, rho: spine_surface(v, s, U, V, rho, Ls, sa, sb, H))
	paint(isl["board"], lambda s, U, V, rho: board_surface(v, s, U, V, rho, Lb, H))
	paint(isl["pages"], lambda s, U, V, rho: paper_surface(v, s, U, V, rho, 2 * ai, True, 300 + vi))
	paint(isl["fore"], lambda s, U, V, rho: paper_surface(v, s, U, V, rho, 2 * ai, False, 400 + vi))

	def edge_fn(s, U, V, rho):
		(leather if kind == "leder" else cloth)(s, U, V, rho, 500 + vi)
		rub(s, 0.35)
	paint(isl["edge"], edge_fn)
	tris = 2 * len(ob.data.polygons)
	total += tris
	meta.append({"name": name, "kind": kind, "size": [T, H, D], "tris": tris})
	print("%-13s %s %4.0f × %3.0f × %3.0f mm, %d Dreiecke" % (name, kind, T * 1000, H * 1000, D * 1000, tris))
print("zusammen %d Dreiecke" % total)

save_image("books_albedo", np.flipud(np.clip(albedo, 0, 1)), TEX + "_albedo.png", True)
save_image("books_normal", np.flipud(normal * 0.5 + 0.5), TEX + "_normal.png")
save_image("books_mask", np.flipud(mask), TEX + "_mask.png")

bpy.ops.object.select_all(action='DESELECT')
for ob in obs:
	ob.select_set(True)
bpy.ops.export_scene.gltf(
	filepath=DST, export_format='GLB', export_yup=True, export_apply=False, use_selection=True,
	export_texcoords=True, export_normals=True, export_tangents=False, export_materials='NONE',
	export_skins=False, export_animations=False, export_morph=False, export_cameras=False, export_lights=False)
with open(os.path.splitext(DST)[0] + ".json", "w", encoding="utf-8") as f:
	json.dump({"variants": meta}, f, indent=1)
print("geschrieben:", DST, TEX + "_albedo.png", "_normal.png", "_mask.png")
