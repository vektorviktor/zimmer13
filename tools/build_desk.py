# Baut die Schreibtische (Desk, ZIM-154) selbst im Look von Kommode und Bücherregal (tools/furniture_kit.py): Holz der
# Vertäfelung, Sockel mit Fase und Viertelstab, Eckpfosten mit drei Furchen, Rundstab, Fries mit stehenden Mulden,
# Platte über einer kleinen Hohlkehle mit gerundeter Nase. Zwei Fassungen (VARIANTS):
#   direktion    2,10 × 1,05 m, zwei Unterschränke mit je drei Schubladen (unten tief für Akten), dazwischen der
#                Knieraum mit flacher Mittelschublade im Fries; grüne Lederauflage (DIN A1) mit Goldprägung in der
#                Holzplatte, vorn mittig
#   sekretariat  1,40 × 0,75 m, rechts ein Unterschrank, links eine Wange, Mittelschublade, Platte ganz aus Holz
# Beide 0,78 m hoch. Außenseiten mit gefelderten Füllungen; die Rückseite (Besucherseite) über die ganze Breite mit
# durchgehendem Sockel, Rundstab und Querleisten und drei gleichen Feldern (Wunsch des Nutzers 2.11.). Schubladen der Unterschränke mit gefaster, vertiefter Füllung wie die Kommode, je zwei
# Messingknöpfe und ein Schlüsselschild (nur Zier – Abschließen ist ZIM-6); die Mittelschublade mit glatter Front.
#
# Lage (Godot-Achsen): Boden y = 0, Mitte x = 0, Vorderseite (Schubladen) nach +Z.
# Objekte:
#   „carcass“              Korpus außen und innen, Holz (Mat.hotel_wood mit AO und Normale aus dem Atlas)
#   „drawer_s/_l/_c“       Schublade (Front und Kasten): Unterschrank klein, Unterschrank tief, Mitte; Ursprung in der
#                          Mitte ihres Fachs auf dessen Unterkante – Desk setzt sie nach <glb>.json an ihren Platz
#   „pulls_s/_l/_c“        Knöpfe und Schlüsselschild einer Schublade (Messing, Schlüsselloch schwarz), Ursprung wie dort
#   „leather“              nur direktion: Lederauflage, UV ganz über die Fläche, zweiter UV-Satz in GRAIN_TILE für die Narbung
# Furchen und Mulden sind wie bei der Kommode in den Atlas gemalt (furniture_kit.paint_details). Gebacken wird jede
# Schublade an einem ihrer Plätze, die übrigen Plätze sind dabei mit Kopien als Schattenwerfer belegt.
#
# Aufruf aus dem Projektordner (Blender 4.3):
#   blender -b --python tools/build_desk.py -- direktion assets/models/desk_direktion.glb assets/textures/desk_direktion
#   blender -b --python tools/build_desk.py -- sekretariat assets/models/desk_sekretariat.glb assets/textures/desk_sekretariat
# Schreibt das Modell, <tex>_ao.png und <tex>_normal.png, die Lage von Schubladen und Kollision in <glb ohne .glb>.json,
# für direktion dazu das Leder: <tex>_leather_albedo/_normal/_orm.png (ganze Fläche, Goldprägung, abgegriffene Mitte),
# <tex>_leather_mask.png (Narbung nicht auf der Prägung), <tex>_leather_grain_albedo/_normal.png (Narbung, Kachel).
import bpy, bmesh, sys, os, math, random, json
import numpy as np

sys.path.append(os.path.dirname(os.path.abspath(__file__)))
from furniture_kit import B, arc, Part, lathe, finish_plain, atlas_uv, setup_cycles, new_image, bake_material, \
	brass_material, bake, godot_normals, save_image, paint_details, capsules, board

argv = sys.argv[sys.argv.index("--") + 1:]
VARIANT = argv[0]
DST = os.path.abspath(argv[1])
TEX = os.path.abspath(argv[2])

# --- Maße (Meter) ------------------------------------------------------------------------------------------------
## Stützen von links nach rechts: (Art, Breite) – „pedestal“ Unterschrank mit Schubladen, „panel“ Wange; zwischen zwei
## Stützen liegt ein Knieraum mit Mittelschublade
VARIANTS = {
	"direktion": {"width": 2.10, "depth": 1.05, "supports": [("pedestal", 0.564), ("pedestal", 0.564)], "post": 0.07,
		"leather": True, "tray_d": 0.55, "slide": 0.38, "center_d": 0.45, "center_slide": 0.26, "knob_x": 0.12,
		"center_knob_x": 0.26},
	"sekretariat": {"width": 1.40, "depth": 0.75, "supports": [("panel", 0.06), ("pedestal", 0.45)], "post": 0.06,
		"leather": False, "tray_d": 0.45, "slide": 0.32, "center_d": 0.40, "center_slide": 0.28, "knob_x": 0.095,
		"center_knob_x": 0.24},
}
V = VARIANTS[VARIANT]
TOP = 0.78
OVER = 0.026              # Platte steht über den Korpus vor (Nase des Profils)
HX = V["width"] / 2.0 - OVER
HZ = V["depth"] / 2.0 - OVER
POST = V["post"]
PLINTH = 0.10             # Sockel bis hier, darüber die Fächer der Unterschränke
BODY_TOP = 0.62           # Oberkante der Fächer, darauf der Rundstab
F0 = 0.646                # Fries (Unterkante = Oberkante Rundstab) …
F1 = 0.715                # … bis unter die Hohlkehle
KNEE_TOP = 0.634          # Decke des Knieraums (Boden der Mittelschublade 12 mm darunter)
SLOTS = [(0.47, 0.15, "s"), (0.32, 0.15, "s"), (0.10, 0.22, "l")]   # Fächer eines Unterschranks von oben: Unterkante, Höhe
FRONT_INSET = 0.008       # Fronten sitzen so weit hinter der Vorderseite
FRONT_T = 0.022
FRONT_Z = HZ - FRONT_INSET
GAP = 0.0015              # Fuge je Kante
BAND = 0.032              # Rahmen der Front bis zur Fase
CHAMFER = 0.006
PANEL_BAND = 0.07         # Rahmen der Füllungen an Rück- und Außenseiten
BACK_FIELDS = 3           # gleiche Felder auf der Rückseite
SIDE_WALL = 0.018
BACK_WALL = 0.02          # Rückwand der Unterschränke und des Knieraums
TRAY_WALL = 0.012
TRAY_LIFT = 0.012         # Kastenboden über der Unterkante des Fachs
TRAY_CLEAR = 0.02         # Kasten schmaler als die Öffnung
TRAY_SPACE = 0.04         # Kasten niedriger als das Fach …
CENTER_SPACE = 0.02       # … bei der flachen Mittelschublade weniger
FLUTES = 3
FLUTE_W = 0.010
FLUTE_GAP = 0.008
FLUTE_DEPTH = 0.004
FLUTE_END = 0.05
NICHE_W = 0.010
NICHE_H = 0.03
NICHE_DEPTH = 0.003
NICHE_PITCH = 0.04
NICHE_CORNER = 0.04
LEATHER = (0.841, 0.594)  # Lederauflage DIN A1 quer, mittig …
LEATHER_FRONT = 0.12      # … mit so viel Holz davor (hinten bleibt Platz für Lampe und Telefon)
LEATHER_DROP = 0.0008     # Leder so viel tiefer als das Holz
GRAIN_TILE = 0.10         # eine Kachel der Narbung (Meter)

ATLAS = 2048
AO_DISTANCE = 0.06
AO_STRENGTH = 0.9
AO_SAMPLES = 128
BRASS_SIZE = 512
## Abstand der Inseln im Atlas (Anteil, 0,006 = 12 px) und Bake-Rand (px): Die gebackene Normale ersetzt im Spiel die
## des Meshs – liegen die Inseln zu dicht, mischt eine kleinere Mipmap-Stufe (flacher Blick auf Kanten) die Normale der
## Nachbarinsel herein, und Ecken und Leistenenden leuchten hell auf
ISLAND_MARGIN = 0.006
BAKE_MARGIN = 16

bpy.ops.wm.read_factory_settings(use_empty=True)
random.seed(54)

LOW = [(0.02, 0.0), (0.02, 0.072), (0.017, 0.075), (0.010, 0.075), (0.010, 0.09)] + arc(0.0, 0.09, 0.01, 0, 90, 4)
BEAD = [(0.0, BODY_TOP)] + arc(0.0, BODY_TOP + 0.013, 0.013, -90, 90, 8)
UPPER = [(0.0, F1)] + arc(0.02, F1, 0.02, 180, 90, 4) + [(OVER, F1 + 0.02)] + arc(OVER, F1 + 0.032, 0.012, -90, 0, 3) \
	+ [(OVER + 0.012, F1 + 0.053)] + arc(OVER, F1 + 0.053, 0.012, 0, 90, 3)
assert abs(LOW[-1][1] - PLINTH) < 1e-6 and abs(BEAD[-1][1] - F0) < 1e-6 and abs(UPPER[-1][1] - TOP) < 1e-6

# Stützen und Knieräume in x
(LEFT, LEFT_W), (RIGHT, RIGHT_W) = V["supports"]
SUPPORTS = [(LEFT, -HX, -HX + LEFT_W), (RIGHT, HX - RIGHT_W, HX)]
KNEES = [(a[2], b[1]) for a, b in zip(SUPPORTS, SUPPORTS[1:])]


# --- Flächen ------------------------------------------------------------------------------------------------------
## Ebene einer Seite: Punkt aus (u, y, k) – u entlang der Seite, k nach innen –, Normale, Faserachse waagerecht
def plane(side, d):
	if side == "f":
		return (lambda u, y, k: (u, y, d - k)), (0, 0, 1), "x"
	if side == "b":
		return (lambda u, y, k: (u, y, d + k)), (0, 0, -1), "x"
	if side == "r":
		return (lambda u, y, k: (d - k, y, u)), (1, 0, 0), "z"
	return (lambda u, y, k: (d + k, y, u)), (-1, 0, 0), "z"


def quad(part, side, d, u0, u1, y0, y1, piece, axis, group=0):
	p, n, _ = plane(side, d)
	part.face([p(u0, y0, 0), p(u1, y0, 0), p(u1, y1, 0), p(u0, y1, 0)], n, piece, axis, group)


## Gerahmte Füllung (wie die Schubladenfront der Kommode): Rahmen bündig, Fase hinab zur vertieften Füllung
def framed(part, side, d, u0, u1, y0, y1, band_u, band_y, tag):
	p, n, hor = plane(side, d)
	U = [u0, u0 + band_u, u1 - band_u, u1]
	Y = [y0, y0 + band_y, y1 - band_y, y1]
	for i in range(3):
		for j in range(3):
			if (i, j) == (1, 1):
				continue
			stile = i != 1
			part.face([p(U[i], Y[j], 0), p(U[i + 1], Y[j], 0), p(U[i + 1], Y[j + 1], 0), p(U[i], Y[j + 1], 0)], n,
				(tag, "stile", i) if stile else (tag, "rail", j), "y" if stile else hor)
	sunk(part, p, n, hor, U[1], U[2], Y[1], Y[2], (tag, "rail", 0), (tag, "rail", 2), (tag, "stile", 0),
		(tag, "stile", 2), (tag, "panel"))


## Gerahmte Reihe von count gleichen Feldern (Rückseite): die Querleisten laufen über die ganze Breite durch, die
## Höhenstücke stehen dazwischen
def framed_row(part, side, d, u0, u1, y0, y1, stile, rail, count, tag):
	p, n, hor = plane(side, d)
	field = (u1 - u0 - (count + 1) * stile) / count
	xs = [u0]
	for k in range(count):
		xs += [xs[-1] + stile, xs[-1] + stile + field]
	xs.append(u1)
	Y = [y0, y0 + rail, y1 - rail, y1]
	for j in (0, 2):   # an den Stößen geteilt (keine T-Kreuzungen), ein Stück für die Maserung
		for a, b in zip(xs, xs[1:]):
			part.face([p(a, Y[j], 0), p(b, Y[j], 0), p(b, Y[j + 1], 0), p(a, Y[j + 1], 0)], n, (tag, "rail", j), hor)
	for k in range(count + 1):
		a, b = xs[2 * k], xs[2 * k + 1]
		part.face([p(a, Y[1], 0), p(b, Y[1], 0), p(b, Y[2], 0), p(a, Y[2], 0)], n, (tag, "stile", k), "y")
	for k in range(count):
		sunk(part, p, n, hor, xs[2 * k + 1], xs[2 * k + 2], Y[1], Y[2], (tag, "rail", 0), (tag, "rail", 2),
			(tag, "stile", k), (tag, "stile", k + 1), (tag, "panel", k))


## Fase rings um das Feld [u0, u1] × [y0, y1] hinab zur vertieften Füllung; die Fasen gehören zu den Stücken des Rahmens
def sunk(part, p, n, hor, u0, u1, y0, y1, bottom, top, left, right, panel):
	c = CHAMFER
	iu = [u0 + c, u1 - c]
	iy = [y0 + c, y1 - c]
	cp = p((u0 + u1) / 2.0, (y0 + y1) / 2.0, c)
	for (a0, a1), (b0, b1), piece, axis in [
			(((u0, y0), (u1, y0)), ((iu[0], iy[0]), (iu[1], iy[0])), bottom, hor),
			(((u0, y1), (u1, y1)), ((iu[0], iy[1]), (iu[1], iy[1])), top, hor),
			(((u0, y0), (u0, y1)), ((iu[0], iy[0]), (iu[0], iy[1])), left, "y"),
			(((u1, y0), (u1, y1)), ((iu[1], iy[0]), (iu[1], iy[1])), right, "y")]:
		pts = [p(a0[0], a0[1], 0), p(a1[0], a1[1], 0), p(b1[0], b1[1], c), p(b0[0], b0[1], c)]
		# Normale der Fase (nur für die Richtung): nach außen und zur Mitte der Füllung
		mid = [sum(q[i] for q in pts) / 4.0 for i in range(3)]
		to_mid = [cp[i] - mid[i] for i in range(3)]
		ln = math.sqrt(sum(v * v for v in to_mid)) or 1.0
		part.face(pts, tuple(n[i] + to_mid[i] / ln for i in range(3)), piece, axis)
	part.face([p(iu[0], iy[0], c), p(iu[1], iy[0], c), p(iu[1], iy[1], c), p(iu[0], iy[1], c)], n, panel, hor)


## Profil ringsum um das Rechteck [x0, x1] × [z0, z1] (Ecken auf Gehrung); sides: Auswahl aus „fbrl“
def sweep(part, x0, x1, z0, z1, profile, tag, sides="fbrl"):
	for (oa, ya), (ob, yb) in zip(profile, profile[1:]):
		t = (ob - oa, yb - ya)
		ln = math.hypot(*t)
		no, ny = t[1] / ln, -t[0] / ln
		if "f" in sides:
			part.face([(x0 - oa, ya, z1 + oa), (x1 + oa, ya, z1 + oa), (x1 + ob, yb, z1 + ob), (x0 - ob, yb, z1 + ob)],
				(0, ny, no), (tag, "f"), "x")
		if "b" in sides:
			part.face([(x0 - oa, ya, z0 - oa), (x1 + oa, ya, z0 - oa), (x1 + ob, yb, z0 - ob), (x0 - ob, yb, z0 - ob)],
				(0, ny, -no), (tag, "b"), "x")
		if "r" in sides:
			part.face([(x1 + oa, ya, z0 - oa), (x1 + oa, ya, z1 + oa), (x1 + ob, yb, z1 + ob), (x1 + ob, yb, z0 - ob)],
				(no, ny, 0), (tag, "r"), "z")
		if "l" in sides:
			part.face([(x0 - oa, ya, z0 - oa), (x0 - oa, ya, z1 + oa), (x0 - ob, yb, z1 + ob), (x0 - ob, yb, z0 - ob)],
				(-no, ny, 0), (tag, "l"), "z")


# --- Korpus ------------------------------------------------------------------------------------------------------
def build_carcass():
	c = Part("carcass")
	for si, (kind, a, b) in enumerate(SUPPORTS):
		tag = "sup%d" % si
		sweep(c, a, b, -HZ, HZ, LOW, tag + "plinth", "frl")
		sweep(c, a, b, -HZ, HZ, BEAD, tag + "bead", "frl")
		outer_l, outer_r = abs(a + HX) < 1e-6, abs(b - HX) < 1e-6
		for side, d, outer in (("l", a, outer_l), ("r", b, outer_r)):
			if outer:
				framed(c, side, d, -HZ, HZ, PLINTH, BODY_TOP, PANEL_BAND, PANEL_BAND, (tag, side))
			else:
				quad(c, side, d, -HZ, HZ, PLINTH, BODY_TOP, (tag, side), "y")
		if kind == "panel":
			quad(c, "f", HZ, a, b, PLINTH, BODY_TOP, (tag, "front"), "y", 1)
			continue
		# Unterschrank: Pfosten vorn, Füllung hinten, innen hohl (wie der Korpus der Kommode)
		quad(c, "f", HZ, a, a + POST, PLINTH, BODY_TOP, (tag, "post", 0), "y", 1)
		quad(c, "f", HZ, b - POST, b, PLINTH, BODY_TOP, (tag, "post", 1), "y", 1)
		xo0, xo1 = a + POST, b - POST
		xi0, xi1 = a + SIDE_WALL, b - SIDE_WALL
		zi = -HZ + BACK_WALL
		zp = FRONT_Z - FRONT_T
		y0, y1 = PLINTH, BODY_TOP
		c.face([(xi0, y0, zi), (xi1, y0, zi), (xi1, y1, zi), (xi0, y1, zi)], (0, 0, 1), (tag, "in", "back"), "y")
		for xi, xo, s in ((xi0, xo0, 1), (xi1, xo1, -1)):
			c.face([(xi, y0, zi), (xi, y0, zp), (xi, y1, zp), (xi, y1, zi)], (s, 0, 0), (tag, "in", s), "y")
			c.face([(xo, y0, zp), (xi, y0, zp), (xi, y1, zp), (xo, y1, zp)], (0, 0, -1), (tag, "in", "post", s), "y")
			c.face([(xo, y0, zp), (xo, y0, HZ), (xo, y1, HZ), (xo, y1, zp)], (s, 0, 0), (tag, "reveal", s), "y")
		for y, ny in ((y0, 1), (y1, -1)):
			for u0, u1, z1 in ((xi0, xo0, zp), (xo0, xo1, HZ), (xo1, xi1, zp)):
				c.face([(u0, y, zi), (u1, y, zi), (u1, y, z1), (u0, y, z1)], (0, ny, 0), (tag, "in", y), "x")
	for ki, (a, b) in enumerate(KNEES):
		tag = "knee%d" % ki
		quad(c, "f", -HZ + BACK_WALL, a, b, 0.0, KNEE_TOP, (tag, "inner"), "y")
		c.face([(a, KNEE_TOP, -HZ + BACK_WALL), (b, KNEE_TOP, -HZ + BACK_WALL), (b, KNEE_TOP, HZ), (a, KNEE_TOP, HZ)],
			(0, -1, 0), (tag, "ceiling"), "x")
		quad(c, "f", HZ, a, b, KNEE_TOP, F0, (tag, "rail"), "x")
		# Gehäuse der Mittelschublade
		hb = housing_back()
		c.face([(a, F0, hb), (b, F0, hb), (b, F0, HZ), (a, F0, HZ)], (0, 1, 0), (tag, "h", "floor"), "x")
		c.face([(a, F1, hb), (b, F1, hb), (b, F1, HZ), (a, F1, HZ)], (0, -1, 0), (tag, "h", "ceiling"), "x")
		c.face([(a, F0, hb), (a, F0, HZ), (a, F1, HZ), (a, F1, hb)], (1, 0, 0), (tag, "h", "l"), "z")
		c.face([(b, F0, hb), (b, F0, HZ), (b, F1, HZ), (b, F1, hb)], (-1, 0, 0), (tag, "h", "r"), "z")
		c.face([(a, F0, hb), (b, F0, hb), (b, F1, hb), (a, F1, hb)], (0, 0, 1), (tag, "h", "back"), "x")
	# Rückseite (Besucherseite) über die ganze Breite: Sockel und Rundstab durchgehend, dazwischen BACK_FIELDS gleiche
	# Felder mit durchlaufenden Querleisten
	sweep(c, -HX, HX, -HZ, HZ, LOW, "back_plinth", "b")
	sweep(c, -HX, HX, -HZ, HZ, BEAD, "back_bead", "b")
	framed_row(c, "b", -HZ, -HX, HX, PLINTH, BODY_TOP, POST, PANEL_BAND, BACK_FIELDS, "back")
	# Fries: vorn über den Stützen, hinten und an den Seiten durchgehend (Gruppe 4: Mulden)
	for si, (kind, a, b) in enumerate(SUPPORTS):
		quad(c, "f", HZ, a, b, F0, F1, ("frieze", "f", si), "x", 4)
	quad(c, "b", -HZ, -HX, HX, F0, F1, ("frieze", "b"), "x", 4)
	quad(c, "l", -HX, -HZ, HZ, F0, F1, ("frieze", "l"), "z", 4)
	quad(c, "r", HX, -HZ, HZ, F0, F1, ("frieze", "r"), "z", 4)
	sweep(c, -HX, HX, -HZ, HZ, UPPER, "upper")
	# Platte: durchgehend Holz (ein Stück, Faser entlang x), beim Leder um dessen 0,8 mm tiefere Vertiefung herum
	ox, oz = HX + OVER, HZ + OVER
	if V["leather"]:
		x0, x1, z0, z1 = leather_rect()
		yl = TOP - LEATHER_DROP
		for a, b, za, zb in ((-ox, ox, z1, oz), (-ox, ox, -oz, z0), (-ox, x0, z0, z1), (x1, ox, z0, z1)):
			c.face([(a, TOP, za), (b, TOP, za), (b, TOP, zb), (a, TOP, zb)], (0, 1, 0), ("top",), "x")
		c.face([(x0, yl, z1), (x1, yl, z1), (x1, TOP, z1), (x0, TOP, z1)], (0, 0, -1), ("top",), "x")
		c.face([(x0, yl, z0), (x1, yl, z0), (x1, TOP, z0), (x0, TOP, z0)], (0, 0, 1), ("top",), "x")
		c.face([(x1, yl, z0), (x1, yl, z1), (x1, TOP, z1), (x1, TOP, z0)], (-1, 0, 0), ("top",), "x")
		c.face([(x0, yl, z0), (x0, yl, z1), (x0, TOP, z1), (x0, TOP, z0)], (1, 0, 0), ("top",), "x")
	else:
		c.face([(-ox, TOP, -oz), (ox, TOP, -oz), (ox, TOP, oz), (-ox, TOP, oz)], (0, 1, 0), ("top",), "x")
	return c.finish()


def housing_back():
	return FRONT_Z - FRONT_T - V["center_d"] - 0.02


## Lederauflage in der Platte: x0, x1, z0 (hinten), z1 (vorn)
def leather_rect():
	z1 = HZ + OVER - LEATHER_FRONT
	return -LEATHER[0] / 2.0, LEATHER[0] / 2.0, z1 - LEATHER[1], z1


# --- Schubladen --------------------------------------------------------------------------------------------------
## Fächer: (Name, Mitte x, Unterkante y, halbe Breite der Öffnung, Höhe, Kasten außen, Auszug) – von oben gezählt:
## erst die Mittelschubladen, dann je Unterschrank von oben nach unten (Desk zählt so für feste Funde)
def slots():
	out = []
	for a, b in KNEES:
		out.append(("c", (a + b) / 2.0, F0, (b - a) / 2.0, F1 - F0, V["center_d"], V["center_slide"]))
	for kind, a, b in SUPPORTS:
		if kind != "pedestal":
			continue
		for y0, h, size in SLOTS:
			out.append((size, (a + b) / 2.0, y0, (b - a) / 2.0 - POST, h, V["tray_d"], V["slide"]))
	return out


def tray_out(half, h, depth):
	return (2.0 * half - TRAY_CLEAR, h - (TRAY_SPACE if h > 0.1 else CENTER_SPACE), depth)


def build_drawer(name, cx, y0, half, h, depth, framed_front):
	d = Part(name)
	zf, zb = FRONT_Z, FRONT_Z - FRONT_T
	X0, X1 = -half + GAP, half - GAP
	Y0, Y1 = GAP, h - GAP
	if framed_front:
		framed(d, "f", zf, X0, X1, Y0, Y1, BAND, BAND, ("front",))
	else:
		quad(d, "f", zf, X0, X1, Y0, Y1, ("front",), "x")
	d.face([(X0, Y0, zf), (X1, Y0, zf), (X1, Y0, zb), (X0, Y0, zb)], (0, -1, 0), ("front", "rail", 0), "x")
	d.face([(X0, Y1, zf), (X1, Y1, zf), (X1, Y1, zb), (X0, Y1, zb)], (0, 1, 0), ("front", "rail", 2), "x")
	for xx, s in ((X0, -1), (X1, 1)):
		d.face([(xx, Y0, zf), (xx, Y1, zf), (xx, Y1, zb), (xx, Y0, zb)], (s, 0, 0), ("front", "stile", s), "y")
	d.face([(X0, Y0, zb), (X1, Y0, zb), (X1, Y1, zb), (X0, Y1, zb)], (0, 0, -1), ("front", "back"), "x")
	tw, th, td = tray_out(half, h, depth)
	w = TRAY_WALL
	zm = zb - td / 2.0
	board(d, (0, TRAY_LIFT + w / 2.0, zm), (tw, w, td), ("tray", "bottom"), "x")
	board(d, (0, TRAY_LIFT + th / 2.0, zb - td + w / 2.0), (tw - 2 * w, th, w), ("tray", "back"), "x")
	for s in (-1, 1):
		board(d, (s * (tw - w) / 2.0, TRAY_LIFT + th / 2.0, zm), (w, th, td), ("tray", s), "z")
	return d.finish((cx, y0, 0))


KNOB = [(0.011, 0.0), (0.011, 0.003), (0.0075, 0.005), (0.0045, 0.008), (0.0045, 0.015), (0.0085, 0.018),
	(0.012, 0.022), (0.011, 0.026), (0.007, 0.029), (0, 0.030)]


## Zwei Knöpfe und dazwischen das Schlüsselschild (Messing, Ovalplatte mit gefaster Kante) mit schwarzem Schlüsselloch
## (Material 1)
def build_pulls(name, cx, y0, h, knob_x, zs):
	bm = bmesh.new()
	yc = h / 2.0
	for kx in (-knob_x, knob_x):
		lathe(bm, (kx, yc, zs), (0, 0, 1), KNOB, segs=12)
	rx, ry, t, bevel, n = 0.011, 0.016, 0.0013, 0.0007, 20
	rings = []
	for z, shrink in ((zs, 0.0), (zs + t * 0.6, 0.0), (zs + t, bevel)):
		rings.append([bm.verts.new(B((rx - shrink) * math.cos(a), yc + (ry - shrink) * math.sin(a), z))
			for a in (2 * math.pi * i / n for i in range(n))])
	plate = []
	for r0, r1 in zip(rings, rings[1:]):
		for i in range(n):
			j = (i + 1) % n
			plate.append(bm.faces.new((r0[i], r0[j], r1[j], r1[i])))
	plate.append(bm.faces.new(rings[-1]))
	plate.append(bm.faces.new(list(reversed(rings[0]))))
	bmesh.ops.recalc_face_normals(bm, faces=plate)
	zk = zs + t + 0.0002
	hole = [bm.verts.new(B(0.0028 * math.cos(a), yc + 0.003 + 0.0028 * math.sin(a), zk))
		for a in (2 * math.pi * i / 12 for i in range(12))]
	slot = [bm.verts.new(B(*p)) for p in ((-0.0012, yc - 0.0065, zk), (0.0012, yc - 0.0065, zk),
		(0.0012, yc + 0.003, zk), (-0.0012, yc + 0.003, zk))]
	for vs in (hole, slot):
		f = bm.faces.new(vs)
		f.normal_update()
		if f.normal.dot(B(0, 0, 1)) < 0:
			f.normal_flip()
		f.material_index = 1
	return finish_plain(bm, name, (cx, y0, 0))


# --- Leder -------------------------------------------------------------------------------------------------------
def build_leather():
	x0, x1, z0, z1 = leather_rect()
	bm = bmesh.new()
	uv = bm.loops.layers.uv.new("UVMap")
	grain = bm.loops.layers.uv.new("grain")
	y = TOP - LEATHER_DROP
	f = bm.faces.new([bm.verts.new(B(*p)) for p in ((x0, y, z1), (x1, y, z1), (x1, y, z0), (x0, y, z0))])
	f.normal_update()
	if f.normal.dot(B(0, 1, 0)) < 0:
		f.normal_flip()
	for loop in f.loops:
		gx, gz = loop.vert.co.x, -loop.vert.co.y   # Blender → Godot x, z
		# Bildzeile 0 = hinten: Blender-v 1 oben, glTF dreht v beim Export
		loop[uv].uv = ((gx - x0) / (x1 - x0), 1.0 - (gz - z0) / (z1 - z0))
		loop[grain].uv = (gx / GRAIN_TILE, -gz / GRAIN_TILE)
	return finish_plain(bm, "leather")


def smooth_noise(h, w, cy, cx, rng):
	g = rng.random((cy + 2, cx + 2))
	ys = (np.arange(h) + 0.5) / h * cy
	xs = (np.arange(w) + 0.5) / w * cx
	y0, x0 = ys.astype(int), xs.astype(int)
	fy, fx = ys - y0, xs - x0
	fy, fx = fy * fy * (3 - 2 * fy), fx * fx * (3 - 2 * fx)
	a = g[y0][:, x0] * (1 - fx) + g[y0][:, x0 + 1] * fx
	b = g[y0 + 1][:, x0] * (1 - fx) + g[y0 + 1][:, x0 + 1] * fx
	return a * (1 - fy)[:, None] + b * fy[:, None]


def fbm(h, w, size_m, meters, rng, octaves=3):
	out = np.zeros((h, w))
	amp, total = 1.0, 0.0
	for o in range(octaves):
		s = size_m / 2 ** o
		out += amp * smooth_noise(h, w, max(1, int(meters[1] / s)), max(1, int(meters[0] / s)), rng)
		total += amp
		amp *= 0.5
	return out / total


## Normal Map (OpenGL wie Godot) aus einer Höhe in Metern; Bildzeile 0 oben
def height_normals(hm, px, wrap=False):
	if wrap:
		dx = (np.roll(hm, -1, 1) - np.roll(hm, 1, 1)) / (2 * px)
		dr = (np.roll(hm, -1, 0) - np.roll(hm, 1, 0)) / (2 * px)
	else:
		dr, dx = np.gradient(hm, px)
	n = np.stack([-dx, dr, np.ones_like(hm)], axis=-1)
	return n / np.linalg.norm(n, axis=-1, keepdims=True)


def rect_line(xm, zm, lx, lz, inset, width, px):
	qx = np.abs(xm - lx / 2) - (lx / 2 - inset)
	qz = np.abs(zm - lz / 2) - (lz / 2 - inset)
	sd = np.hypot(np.maximum(qx, 0), np.maximum(qz, 0)) + np.minimum(np.maximum(qx, qz), 0)
	return np.clip((width / 2 - np.abs(sd)) / px + 0.5, 0, 1)


def save_rows(name, data, path, color_data=False):
	save_image(name, np.flipud(data), path, color_data)   # Blender speichert die unterste Zeile zuerst


def leather_textures():
	rng = np.random.default_rng(13)
	lx, lz = LEATHER
	W = 2048
	H = int(round(W * lz / lx))
	px = lx / W
	xm = ((np.arange(W) + 0.5) * px)[None, :].repeat(H, 0)
	zm = ((np.arange(H) + 0.5) * lz / H)[:, None].repeat(W, 1)
	mottle = fbm(H, W, 0.25, (lx, lz), rng)
	fine = fbm(H, W, 0.02, (lx, lz), rng, 2)
	# abgegriffen vorn in der Mitte, wo der Direktor schreibt; Ränder dunkler
	e = ((xm - lx / 2) / 0.28) ** 2 + ((zm - lz * 0.72) / 0.18) ** 2
	wear = np.clip(1 - e, 0, 1) ** 0.7 * (0.6 + 0.4 * fbm(H, W, 0.06, (lx, lz), rng))
	edge = np.minimum(np.minimum(xm, lx - xm), np.minimum(zm, lz - zm))
	dark = np.clip(1 - edge / 0.04, 0, 1) ** 2 * 0.3
	green = np.array([0.085, 0.170, 0.115])
	worn = np.array([0.20, 0.26, 0.18])
	col = green[None, None, :] * (0.82 + 0.36 * mottle[..., None]) * (0.94 + 0.12 * fine[..., None])
	col = col * (1 - 0.55 * wear[..., None]) + worn[None, None, :] * 0.55 * wear[..., None]
	col *= 1 - dark[..., None]
	rough = 0.72 + 0.08 * (mottle - 0.5) - 0.2 * wear
	# Goldprägung: breite und feine Linie, Raute in den inneren Ecken; eine blinde Linie ohne Gold weiter innen
	gold = np.maximum(rect_line(xm, zm, lx, lz, 0.013, 0.004, px), rect_line(xm, zm, lx, lz, 0.021, 0.0011, px))
	for cxm in (0.036, lx - 0.036):
		for czm in (0.036, lz - 0.036):
			gold = np.maximum(gold, np.clip((0.0055 - (np.abs(xm - cxm) + np.abs(zm - czm))) / px + 0.5, 0, 1))
	groove = np.maximum(gold, rect_line(xm, zm, lx, lz, 0.028, 0.001, px))
	gilt = gold * np.clip(0.8 + 0.9 * (fbm(H, W, 0.01, (lx, lz), rng, 2) - 0.5) - 0.6 * wear, 0, 1)
	gold_col = np.array([0.80, 0.63, 0.32])[None, None, :] * (0.85 + 0.3 * fine[..., None])
	col = col * (1 - gilt[..., None]) + gold_col * gilt[..., None]
	col = col * (1 - 0.25 * (groove - gilt))[..., None]
	rough = rough * (1 - gilt) + 0.32 * gilt
	hm = -0.0003 * groove + 0.00015 * fbm(H, W, 0.03, (lx, lz), rng)
	nrm = height_normals(hm, px)
	orm = np.stack([1 - 0.25 * groove, np.clip(rough, 0, 1), gilt], axis=-1)
	save_rows("leather_albedo", np.clip(col, 0, 1), TEX + "_leather_albedo.png", True)
	save_rows("leather_normal", nrm * 0.5 + 0.5, TEX + "_leather_normal.png")
	save_rows("leather_orm", orm, TEX + "_leather_orm.png")
	save_rows("leather_mask", 1 - groove, TEX + "_leather_mask.png")
	# Narbung: Zellen (Worley, nahtlos) – Falten an den Grenzen dunkler und tiefer
	S, N = 1024, 72
	pts = rng.random((N, N, 2))
	yy, xx = np.mgrid[0:S, 0:S] * (N / S)
	cy, cx = np.floor(yy).astype(int), np.floor(xx).astype(int)
	f1 = np.full((S, S), 9.0)
	f2 = np.full((S, S), 9.0)
	for dy in (-1, 0, 1):
		for dx in (-1, 0, 1):
			p = pts[(cy + dy) % N, (cx + dx) % N]
			d = np.hypot(yy - (cy + dy + p[..., 0]), xx - (cx + dx + p[..., 1]))
			f2 = np.where(d < f1, f1, np.minimum(f2, d))
			f1 = np.minimum(f1, d)
	crease = np.clip((f2 - f1) / 0.25, 0, 1)
	crease = crease * crease * (3 - 2 * crease)
	tile_noise = smooth_noise(S, S, 256, 256, rng)
	gh = 0.00004 * (0.7 * crease + 0.3 * np.clip(1 - f1, 0, 1)) + 0.000006 * tile_noise
	save_rows("grain_normal", height_normals(gh, GRAIN_TILE / S, True) * 0.5 + 0.5, TEX + "_leather_grain_normal.png")
	save_rows("grain_albedo", np.repeat((0.92 + 0.08 * crease)[..., None], 3, -1), TEX + "_leather_grain_albedo.png",
		True)


# --- Bauen -------------------------------------------------------------------------------------------------------
carcass = build_carcass()
specs = slots()
drawers, pulls, casters, layout = {}, {}, [], []
for size, cx, y0, half, h, depth, slide in specs:
	name = "drawer_" + size
	zs = FRONT_Z - (CHAMFER if size != "c" else 0.0)
	knob_x = V["center_knob_x"] if size == "c" else V["knob_x"]
	tw, th, td = tray_out(half, h, depth)
	layout.append({"mesh": name, "pulls": "pulls_" + size, "x": round(cx, 4), "y": round(y0, 4),
		"front": [round(2 * half - 2 * GAP, 4), round(h - 2 * GAP, 4)], "h": round(h, 4),
		"tray_out": [round(tw, 4), round(th, 4), round(td, 4)],
		"inner": [round(tw - 2 * TRAY_WALL, 4), round(th - TRAY_WALL, 4), round(td - TRAY_WALL, 4)], "slide": slide})
	if name not in drawers:
		drawers[name] = build_drawer(name, cx, y0, half, h, depth, size != "c")
		pulls[name] = build_pulls("pulls_" + size, cx, y0, h, knob_x, zs)
	else:
		for src in (drawers[name], pulls[name]):
			ob = bpy.data.objects.new(src.name + "_%d" % len(casters), src.data)
			ob.location = B(cx, y0, 0)
			bpy.context.scene.collection.objects.link(ob)
			casters.append(ob)
leather = build_leather() if V["leather"] else None
wood = [carcass] + list(drawers.values())
brass = list(pulls.values())
atlas_uv(wood, ISLAND_MARGIN, {1: 3.0, 4: 2.5})
atlas_uv(brass, 0.01)


# --- Gemalte Formen ----------------------------------------------------------------------------------------------
def flutes_paint():
	posts = []
	for kind, a, b in SUPPORTS:
		posts += [(a, b)] if kind == "panel" else [(a, a + POST), (b - POST, b)]
	r = FLUTE_W / 2.0
	centers = []
	for a, b in posts:
		margin = (b - a - FLUTES * FLUTE_W - (FLUTES - 1) * FLUTE_GAP) / 2.0
		centers += [a + margin + r + k * (FLUTE_W + FLUTE_GAP) for k in range(FLUTES)]

	def paint(pts, n, px):
		gs, gy, shade, mask = capsules(pts[:, 0], pts[:, 1], centers, PLINTH + FLUTE_END + r, BODY_TOP - FLUTE_END - r,
			r, FLUTE_DEPTH, px)
		normals = np.array(n)[None, :] - gs[:, None] * np.array([1.0, 0, 0]) - gy[:, None] * np.array([0, 1.0, 0])
		return normals / np.linalg.norm(normals, axis=1, keepdims=True), shade, mask

	return paint


def even(a, b, pitch, margin):
	k = max(1, int(round((b - a - 2 * margin) / pitch)) + 1)
	step = (b - a - 2 * margin) / max(1, k - 1)
	return [a + margin + i * step for i in range(k)]


def niches_paint():
	r = NICHE_W / 2.0
	mid = (F0 + F1) / 2.0
	y0, y1 = mid - NICHE_H / 2.0 + r, mid + NICHE_H / 2.0 - r
	front = []
	for kind, a, b in SUPPORTS:
		front += even(a, b, NICHE_PITCH, NICHE_PITCH / 2.0 if b - a > 0.1 else (b - a) / 2.0)
	back = even(-HX, HX, NICHE_PITCH, NICHE_CORNER)
	side = even(-HZ, HZ, NICHE_PITCH, NICHE_CORNER)

	def paint(pts, n, px):
		if abs(n[2]) > 0.5:
			axis = np.array([1.0, 0, 0])
			centers = front if n[2] > 0 else back
		else:
			axis = np.array([0, 0, 1.0])
			centers = side
		gs, gy, shade, mask = capsules(pts @ axis, pts[:, 1], centers, y0, y1, r, NICHE_DEPTH, px)
		normals = n[None, :] - gs[:, None] * axis[None, :] - gy[:, None] * np.array([0, 1.0, 0])[None, :]
		return normals / np.linalg.norm(normals, axis=1, keepdims=True), shade, mask

	return paint


# --- Backen ------------------------------------------------------------------------------------------------------
sc = setup_cycles()
sc.render.bake.margin = BAKE_MARGIN
for ob in wood:
	ob.data.materials.append(bake_material("wood_src"))
brass_src = brass_material()
key_src = bake_material("key_src", (0.02, 0.02, 0.02, 1))
for ob in brass:
	ob.data.materials.append(brass_src)
	ob.data.materials.append(key_src)
if leather:
	leather.data.materials.append(bake_material("leather_src"))   # nur als Schattenwerfer, kein Atlas nötig

sc.world.light_settings.distance = AO_DISTANCE
ao = bake(wood, 'AO', new_image("desk_ao", ATLAS, False, True), AO_SAMPLES)[..., 0]
print("AO: Mittel %.3f, dunkelster Wert %.3f" % (ao.mean(), ao.min()))
ao = 1.0 - AO_STRENGTH * (1.0 - np.clip(ao, 0, 1))
nrm = godot_normals(bake(wood, 'NORMAL', new_image("desk_nrm", ATLAS, False, True), 1, normal_space='OBJECT'))
paint_details(wood, nrm, ao, {1: flutes_paint(), 4: niches_paint()})
save_image("desk_ao_out", ao, TEX + "_ao.png")
save_image("desk_normal_out", nrm * 0.5 + 0.5, TEX + "_normal.png")

bcol = bake(brass, 'DIFFUSE', new_image("brass_color", BRASS_SIZE, True), 1, pass_filter={'COLOR'})
sc.world.light_settings.distance = 0.02
bao = bake(brass, 'AO', new_image("brass_ao", BRASS_SIZE, False), 128)
bcol[..., :3] *= (1.0 - 0.8 * (1.0 - np.clip(bao[..., :1], 0, 1))) ** (1 / 2.2)
brass_img = new_image("desk_brass_albedo", BRASS_SIZE, True)
brass_img.pixels[:] = bcol.ravel()
brass_img.pack()

if leather:
	leather_textures()


# --- Export ------------------------------------------------------------------------------------------------------
for ob in casters:
	bpy.data.objects.remove(ob)
mat = bpy.data.materials.new("desk_brass")
mat.use_nodes = True
nt = mat.node_tree
bsdf = nt.nodes["Principled BSDF"]
t = nt.nodes.new("ShaderNodeTexImage")
t.image = brass_img
nt.links.new(t.outputs["Color"], bsdf.inputs["Base Color"])
bsdf.inputs["Metallic"].default_value = 1.0
bsdf.inputs["Roughness"].default_value = 0.32
key = bpy.data.materials.new("desk_keyhole")
key.use_nodes = True
key.node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value = (0.01, 0.01, 0.01, 1)
key.node_tree.nodes["Principled BSDF"].inputs["Roughness"].default_value = 0.9
for ob in wood + ([leather] if leather else []):
	ob.data.materials.clear()   # Holz und Leder setzt Desk
for ob in brass:
	ob.data.materials.clear()
	ob.data.materials.append(mat)
	ob.data.materials.append(key)
everything = wood + brass + ([leather] if leather else [])
for ob in everything:
	if "group" in ob.data.attributes:
		ob.data.attributes.remove(ob.data.attributes["group"])
	tris = sum(len(p.vertices) - 2 for p in ob.data.polygons)
	print("%-10s %5d Dreiecke, UV-Sätze %s" % (ob.name, tris, [l.name for l in ob.data.uv_layers]))

bpy.ops.object.select_all(action='DESELECT')
for ob in everything:
	ob.select_set(True)
bpy.ops.export_scene.gltf(
	filepath=DST, export_format='GLB', export_yup=True, export_apply=False, use_selection=True,
	export_texcoords=True, export_normals=True, export_tangents=False, export_materials='EXPORT',
	export_image_format='JPEG', export_jpeg_quality=92, export_skins=False, export_animations=False,
	export_morph=False, export_cameras=False, export_lights=False)


# --- Lage für Desk -----------------------------------------------------------------------------------------------
## Kollision als Kästen (Größe, Mitte): Platte mit Fries, Stützen, Knieräume; die Unterschränke und das Gehäuse der
## Mittelschublade hohl (sonst drückt die Physik die Gegenstände aus geschlossenen Schubladen)
def box(x0, x1, y0, y1, z0, z1):
	return [round(v, 4) for v in (x1 - x0, y1 - y0, z1 - z0, (x0 + x1) / 2, (y0 + y1) / 2, (z0 + z1) / 2)]


boxes = [box(-HX - OVER, HX + OVER, F1, TOP, -HZ - OVER, HZ + OVER)]
for kind, a, b in SUPPORTS:
	boxes.append(box(a - 0.02, b + 0.02, 0, PLINTH, -HZ - 0.02, HZ + 0.02))
	boxes.append(box(a, b, BODY_TOP, F1, -HZ, HZ))
	if kind == "panel":
		boxes.append(box(a, b, PLINTH, BODY_TOP, -HZ, HZ))
		continue
	boxes.append(box(a, a + POST, PLINTH, BODY_TOP, -HZ, HZ))
	boxes.append(box(b - POST, b, PLINTH, BODY_TOP, -HZ, HZ))
	boxes.append(box(a + POST, b - POST, PLINTH, BODY_TOP, -HZ, -HZ + BACK_WALL))
for a, b in KNEES:
	boxes.append(box(a, b, 0, KNEE_TOP, -HZ, -HZ + BACK_WALL))
	boxes.append(box(a, b, KNEE_TOP, F0, -HZ, HZ))
	boxes.append(box(a, b, F0, F1, -HZ, housing_back()))
info = {"size": [round(2 * (HX + OVER), 4), TOP, round(2 * (HZ + OVER), 4)], "front_z": round(FRONT_Z, 4),
	"front_t": FRONT_T, "tray_lift": TRAY_LIFT, "wall": TRAY_WALL, "leather": V["leather"], "drawers": layout,
	"boxes": boxes}
with open(os.path.splitext(DST)[0] + ".json", "w", encoding="utf-8") as fh:
	json.dump(info, fh, indent="\t")
print("geschrieben:", DST, TEX + "_ao.png", TEX + "_normal.png")
