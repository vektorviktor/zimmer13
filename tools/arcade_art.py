# Malt die Gehäusebilder der beiden Videospielautomaten (ArcadeMachine, Spielkonzept 6.10) in die UVs des Rumpfs
# aus assets/models/arcade_machine.glb (tools/build_arcade.py): Farbe je Spiel, Normal Map und Rauheit gemeinsam in ATLAS²,
# dazu die umgefärbte Joystick-Textur.
#   textures/arcade_<spiel>.png         Farbe
#   textures/arcade_normal.png          Normal Map (OpenGL, Tangentenraum der GLB), beide Spiele
#   textures/arcade_rough.png           Rot = Leuchtmaske (Schild), Grün = Rauheit (glTF-Art), beide Spiele
#   textures/arcade_<spiel>_stick.png   Joystick, Kugel in der Spielfarbe
# Die Motive sind die Pixelbilder der Spiele selbst (Kästchen, Gespenster, Männchen aus arcade_machine.gd), groß
# gemalt: Deadra in Aubergine mit giftgrüner Kante, Ghost Hotel in Nachtblau mit oranger Kante.
# Jede Fläche des Rumpfs bekommt eine Rolle (Seite, Kante, Schild, Bildschirmrahmen, Bedienfeld, Lack); Bilder
# werden in Metern gemalt und über eine aus den Eckpunkten geschätzte Abbildung Meter → UV auf die Flächen gelegt.
#
# Aufruf:
#   python tools/arcade_art.py assets/models/arcade_machine.glb assets/source/arcade_machine/joystick.jpg assets/textures
import json, struct, sys
import numpy as np
from PIL import Image, ImageDraw, ImageFilter

ATLAS = 2048
PX_M = 1000                 # Bildauflösung der Motive, Pixel je Meter
RNG = np.random.default_rng(13)

# --- Pixelbilder aus arcade_machine.gd ---------------------------------------------------------------------
TILES = {
	"ghost": [".####.", "#o##o#", "######", "######", "######", "#.##.#"],
	"pumpkin": ["..g...", ".####.", "#o##o#", "######", "#oooo#", ".####."],
	"skull": [".####.", "######", "#oo#oo", "######", ".#o#o.", ".####."],
}
TILE_COLORS = {"ghost": (235, 240, 255), "pumpkin": (255, 128, 20), "skull": (219, 209, 173)}
PENTOMINOES = [
	[(1, 0), (2, 0), (0, 1), (1, 1), (1, 2)], [(0, 0), (0, 1), (0, 2), (0, 3), (0, 4)],
	[(0, 0), (0, 1), (0, 2), (0, 3), (1, 3)], [(1, 0), (1, 1), (0, 2), (1, 2), (0, 3)],
	[(0, 0), (1, 0), (0, 1), (1, 1), (0, 2)], [(0, 0), (1, 0), (2, 0), (1, 1), (1, 2)],
	[(0, 0), (2, 0), (0, 1), (1, 1), (2, 1)], [(0, 0), (0, 1), (0, 2), (1, 2), (2, 2)],
	[(0, 0), (0, 1), (1, 1), (1, 2), (2, 2)], [(1, 0), (0, 1), (1, 1), (2, 1), (1, 2)],
	[(1, 0), (0, 1), (1, 1), (1, 2), (1, 3)], [(0, 0), (1, 0), (1, 1), (1, 2), (2, 2)],
]
MAN = ["...##...", "...##...", "..####..", ".#.##.#.", "...##...", "..#..#..", "..#..#.."]
SHEET = ["..####..", ".######.", "##o##o##", "########", "########", "########", "#.##.##.", "........"]
LANTERN = ["..##..", ".#..#.", "######", "#yyyy#", "#yyyy#", "#yyyy#", "######"]
# Blockschrift 5 × 7 für die Titel
FONT = {
	"A": [".###.", "#...#", "#...#", "#####", "#...#", "#...#", "#...#"],
	"D": ["####.", "#...#", "#...#", "#...#", "#...#", "#...#", "####."],
	"E": ["#####", "#....", "#....", "####.", "#....", "#....", "#####"],
	"G": [".###.", "#...#", "#....", "#.###", "#...#", "#...#", ".###."],
	"H": ["#...#", "#...#", "#...#", "#####", "#...#", "#...#", "#...#"],
	"L": ["#....", "#....", "#....", "#....", "#....", "#....", "#####"],
	"O": [".###.", "#...#", "#...#", "#...#", "#...#", "#...#", ".###."],
	"R": ["####.", "#...#", "#...#", "####.", "#.#..", "#..#.", "#...#"],
	"S": [".####", "#....", "#....", ".###.", "....#", "....#", "####."],
	"T": ["#####", "..#..", "..#..", "..#..", "..#..", "..#..", "..#.."],
	" ": [".....", ".....", ".....", ".....", ".....", ".....", "....."],
}

LOOKS = {
	"deadra": {
		"body": (34, 13, 41), "trim": (115, 242, 64), "accent": (190, 245, 140), "dark": (12, 5, 16),
		"stick": (115, 242, 64), "title": "DEADRA",
	},
	"ghost_hotel": {
		"body": (13, 18, 51), "trim": (255, 128, 26), "accent": (255, 190, 90), "dark": (5, 7, 20),
		"stick": (255, 128, 26), "title": "GHOST HOTEL",
	},
}

# Rollen der Flächen; Rauheit und Höhe der Oberfläche je Rolle
BODY, SIDE_R, SIDE_L, TRIM, MARQUEE, BEZEL, PANEL, PANEL_EDGE = range(1, 9)
ROUGH = {BODY: 0.32, SIDE_R: 0.45, SIDE_L: 0.45, TRIM: 0.4, MARQUEE: 0.12, BEZEL: 0.22, PANEL: 0.5, PANEL_EDGE: 0.4}


# --- GLB lesen ---------------------------------------------------------------------------------------------
def read_glb(path, name):
	data = open(path, "rb").read()
	n = struct.unpack_from("<I", data, 12)[0]
	gltf = json.loads(data[20:20 + n])
	bin_at = 20 + n + 8
	def acc(i):
		a = gltf["accessors"][i]
		v = gltf["bufferViews"][a["bufferView"]]
		comps = {"SCALAR": 1, "VEC2": 2, "VEC3": 3, "VEC4": 4}[a["type"]]
		dt = {5126: np.float32, 5123: np.uint16, 5125: np.uint32}[a["componentType"]]
		start = bin_at + v.get("byteOffset", 0) + a.get("byteOffset", 0)
		return np.frombuffer(data, dt, a["count"] * comps, start).reshape(a["count"], comps) if comps > 1 \
			else np.frombuffer(data, dt, a["count"], start)
	mesh = next(m for m in gltf["meshes"] if m["name"] == name)
	prim = mesh["primitives"][0]
	at = prim["attributes"]
	return acc(at["POSITION"]), acc(at["TEXCOORD_0"]), acc(prim["indices"]).reshape(-1, 3)


# --- Flächen einteilen -------------------------------------------------------------------------------------
def classify(pos, uv, tris):
	roles = []
	for t in tris:
		p = pos[t]
		n = np.cross(p[1] - p[0], p[2] - p[0])
		n = n / (np.linalg.norm(n) + 1e-12)
		c = p.mean(0)
		u = uv[t][:, 0].mean()
		if abs(n[0]) > 0.9 and abs(c[0]) > 0.3 and u > 0.62:
			roles.append(SIDE_R if c[0] > 0 else SIDE_L)
		elif u > 0.62:
			roles.append(TRIM)       # Kanten der Seitenwände liegen im Original bei den Seitenbildern
		elif n[2] > 0.9 and 1.56 < c[1] < 1.79 and np.ptp(p[:, 0]) > 0.05:   # ohne die schmalen Randstreifen
			roles.append(MARQUEE)
		elif n[2] > 0.5 and 1.0 < c[1] < 1.56 and abs(c[0]) < 0.34:
			roles.append(BEZEL)
		elif n[1] > 0.9 and 0.86 < c[1] < 1.0 and c[2] > 0.05:
			roles.append(PANEL)
		elif n[2] > 0.8 and 0.8 < c[1] < 0.95 and c[2] > 0.3:
			roles.append(PANEL_EDGE)
		else:
			roles.append(BODY)
	return np.array(roles)


def raster(uv, pos, tris, roles):
	"""Rolle und Ort am Modell (Meter) für jedes Pixel des Atlas – je Dreieck baryzentrisch aus den Eckpunkten."""
	label = np.zeros((ATLAS, ATLAS), np.uint8)
	where = np.zeros((ATLAS, ATLAS, 3), np.float32)
	# erst die großen, dann die besonderen – an Nähten gewinnt die besondere Rolle
	for r in [BODY, TRIM, SIDE_R, SIDE_L, PANEL_EDGE, PANEL, BEZEL, MARQUEE]:
		for t in tris[roles == r]:
			q = uv[t].astype(np.float64) * ATLAS
			x0, y0 = np.floor(q.min(0)).astype(int) - 1
			x1, y1 = np.ceil(q.max(0)).astype(int) + 1
			x0, y0, x1, y1 = max(x0, 0), max(y0, 0), min(x1, ATLAS - 1), min(y1, ATLAS - 1)
			m = np.array([[q[0, 0] - q[2, 0], q[1, 0] - q[2, 0]], [q[0, 1] - q[2, 1], q[1, 1] - q[2, 1]]])
			if x1 < x0 or y1 < y0 or abs(np.linalg.det(m)) < 1e-9:
				continue
			gx, gy = np.meshgrid(np.arange(x0, x1 + 1) + 0.5, np.arange(y0, y1 + 1) + 0.5)
			inv = np.linalg.inv(m)
			dx, dy = gx - q[2, 0], gy - q[2, 1]
			l0 = inv[0, 0] * dx + inv[0, 1] * dy
			l1 = inv[1, 0] * dx + inv[1, 1] * dy
			l2 = 1.0 - l0 - l1
			tol = 0.7 / max(1.0, np.sqrt(abs(np.linalg.det(m))))   # etwa ein halbes Pixel über den Rand
			inside = (l0 >= -tol) & (l1 >= -tol) & (l2 >= -tol)
			ys, xs = np.nonzero(inside)
			label[ys + y0, xs + x0] = r
			b = np.stack([l0[inside], l1[inside], l2[inside]], 1)
			where[ys + y0, xs + x0] = b @ pos[t]
	return label, where


def project(label, where, role, axes, canvas, origin, color):
	"""Legt das Motiv (canvas in PX_M, Ecke origin in Metern = linke untere Bildecke) auf alle Pixel der Rolle;
	axes = (Achse waagrecht, Vorzeichen, Achse senkrecht, Vorzeichen) der Modellkoordinaten."""
	ys, xs = np.nonzero(label == role)
	p = where[ys, xs]
	a = p[:, axes[0]] * axes[1]
	b = p[:, axes[2]] * axes[3]
	cx = np.clip(((a - origin[0]) * PX_M).astype(int), 0, canvas.shape[1] - 1)
	cy = np.clip((canvas.shape[0] - 1 - (b - origin[1]) * PX_M).astype(int), 0, canvas.shape[0] - 1)
	color[ys, xs] = canvas[cy, cx, :3]


# --- Malhilfen ---------------------------------------------------------------------------------------------
def sprite(d, rows, at, px, colors):
	"""Pixelbild rows ab at (links oben, Bildpixel) mit px Bildpixeln je Bildpunkt; colors: Zeichen → Farbe."""
	for y, row in enumerate(rows):
		for x, ch in enumerate(row):
			if ch in colors:
				d.rectangle([at[0] + x * px, at[1] + y * px, at[0] + (x + 1) * px - 1, at[1] + (y + 1) * px - 1], fill=colors[ch])


def tile(d, kind, at, px):
	base = TILE_COLORS[kind]
	dark = tuple(int(c * 0.25) for c in base)
	sprite(d, TILES[kind], at, px, {"#": base, "o": dark, "g": (60, 160, 40)})


def text(d, s, at, px, color, gap=1):
	x = at[0]
	for ch in s:
		sprite(d, FONT[ch], (x, at[1]), px, {"#": color})
		x += (5 + gap) * px


def text_width(s, px, gap=1):
	return len(s) * (5 + gap) * px - gap * px


def glow(img, color, radius, strength=1.0):
	"""Schein um alles Nichtschwarze in img (RGBA-Ebene) in color."""
	a = img.split()[3].filter(ImageFilter.GaussianBlur(radius))
	a = a.point(lambda v: min(255, int(v * strength)))
	layer = Image.new("RGBA", img.size, color + (0,))
	layer.putalpha(a)
	return layer


def gradient(w, h, top, bottom):
	t = np.linspace(0, 1, h)[:, None, None]
	g = np.array(top)[None, None] * (1 - t) + np.array(bottom)[None, None] * t
	return Image.fromarray(np.broadcast_to(g, (h, w, 3)).astype(np.uint8), "RGB").convert("RGBA")


def titled(base, s, px, center, color, glow_color, outline=(0, 0, 0)):
	"""Titel in Blockschrift mit dunkler Kontur und Schein, zentriert auf center (Bildpixel)."""
	w, h = text_width(s, px), 7 * px
	at = (int(center[0] - w / 2), int(center[1] - h / 2))
	layer = Image.new("RGBA", base.size, (0, 0, 0, 0))
	d = ImageDraw.Draw(layer)
	text(d, s, at, px, color)
	base.alpha_composite(glow(layer, glow_color, px * 1.6, 2.2))
	edge = Image.new("RGBA", base.size, (0, 0, 0, 0))
	ImageDraw.Draw(edge)
	o = layer.split()[3].filter(ImageFilter.MaxFilter(int(px * 0.6) | 1))
	edge.paste(Image.new("RGBA", base.size, outline + (255,)), (0, 0), o)
	base.alpha_composite(edge)
	base.alpha_composite(layer)


# --- Motive je Spiel ---------------------------------------------------------------------------------------
def side_art(look, game, w, h, mirrored):
	"""Seitenbild w × h Meter; mirrored: Front liegt rechts im Bild (linke Seite des Automaten), sonst links.
	Oberhalb des Bedienfelds ist die Seite nur hinten breit (ab gut der halben Tiefe), ganz oben auch hinten schräg."""
	W, H = int(w * PX_M), int(h * PX_M)
	fx = lambda f: int((1.0 - f) * W) if mirrored else int(f * W)   # f = 0 vorn, 1 hinten
	top_mid = 0.7                       # Titel: oben ist die Seite hinten schräg abgeschnitten, darunter 0,5 m tief
	if game == "deadra":
		img = gradient(W, H, (40, 14, 52), (10, 4, 14))
		shapes = Image.new("RGBA", (W, H), (0, 0, 0, 0))
		d = ImageDraw.Draw(shapes)
		px = 7                                  # Bildpunkt 7 mm → Kästchen 42 mm
		cell = 6 * px
		kinds = list(TILES)
		# ein schräger Strom fallender Formen von oben hinten nach unten vorn
		for i in range(10):
			t = i / 9.0
			shape = PENTOMINOES[(i * 5) % 12]
			cx = fx(0.82 - 0.62 * t) - cell + int(RNG.integers(-30, 30))
			cy = int(H * (0.2 + 0.55 * t))
			for (sx, sy) in shape:
				tile(d, kinds[i % 3], (cx + sx * cell, cy + sy * cell), px)
		# zerklüfteter Haufen unten
		for col in range(W // cell + 1):
			for row in range(int(RNG.integers(2, 6))):
				tile(d, kinds[int(RNG.integers(0, 3))], (col * cell, H - (row + 1) * cell - 40), px)
		img.alpha_composite(glow(shapes, (120, 255, 80), 18, 1.3))
		img.alpha_composite(shapes)
		titled(img, "DEADRA", 10, (fx(top_mid), H * 0.2), look["accent"], (120, 255, 80))
	else:
		img = gradient(W, H, (20, 18, 70), (6, 8, 26))
		d = ImageDraw.Draw(img)
		# Mond und Sterne
		moon = (fx(0.8), int(H * 0.34))
		halo = Image.new("RGBA", (W, H), (0, 0, 0, 0))
		ImageDraw.Draw(halo).ellipse([moon[0] - 60, moon[1] - 60, moon[0] + 60, moon[1] + 60], fill=(255, 240, 200, 255))
		img.alpha_composite(glow(halo, (180, 190, 255), 60, 1.0))
		img.alpha_composite(halo)
		for _ in range(90):
			x, y = int(RNG.integers(0, W)), int(RNG.integers(0, int(H * 0.5)))
			d.rectangle([x, y, x + 3, y + 3], fill=(200, 205, 255))
		# Hotel: Giebelhaus mit Türmchen hinten, erleuchtete Fenster
		hx0, hx1 = sorted((fx(0.06), fx(0.94)))
		hy0, hy1 = int(H * 0.47), int(H * 0.88)
		house = (8, 10, 22)
		d.rectangle([hx0, hy0, hx1, hy1], fill=house)
		d.polygon([(hx0 - 20, hy0), ((hx0 + hx1) // 2, hy0 - int(H * 0.07)), (hx1 + 20, hy0)], fill=house)
		tx = fx(0.75)
		tower_top = hy0 - int(H * 0.13)
		d.rectangle([tx - 45, tower_top, tx + 45, hy0], fill=house)
		d.polygon([(tx - 60, tower_top), (tx, tower_top - int(H * 0.06)), (tx + 60, tower_top)], fill=house)
		lit = Image.new("RGBA", (W, H), (0, 0, 0, 0))
		dl = ImageDraw.Draw(lit)
		for row in range(5):
			for col in range(6):
				x = hx0 + 40 + col * ((hx1 - hx0 - 80) // 6)
				y = hy0 + 30 + row * 70
				on = RNG.random() < 0.45
				dl.rectangle([x, y, x + 34, y + 44], fill=(255, 200, 90, 255) if on else (30, 34, 60, 255))
		dl.rectangle([tx - 14, tower_top + 30, tx + 14, tower_top + 66], fill=(255, 210, 120, 255))
		img.alpha_composite(glow(lit, (255, 170, 60), 14, 0.8))
		img.alpha_composite(lit)
		# davor das Männchen mit der Laterne zur Front hin, dahinter drei Gespenster, vor ihm die Kürbisspur
		figures = Image.new("RGBA", (W, H), (0, 0, 0, 0))
		df = ImageDraw.Draw(figures)
		ground = int(H * 0.95)
		px = 12
		ahead = 1 if mirrored else -1             # Bildrichtung zur Front
		man_x = fx(0.42) - 4 * px
		sprite(df, MAN, (man_x, ground - 7 * px), px, {"#": (255, 230, 60)})
		lx = man_x + (8 * px if ahead > 0 else -6 * 6)
		sprite(df, LANTERN, (lx, ground - 9 * px), 6, {"#": (60, 40, 20), "y": (255, 220, 110)})
		for i in range(3):
			gx = man_x - ahead * (140 + i * 115)
			sprite(df, SHEET, (gx, ground - 8 * px - (i % 2) * 24), px, {"#": (235, 240, 255), "o": (20, 20, 40)})
		for i in range(5):
			tile(df, "pumpkin", (man_x + 4 * px + ahead * (110 + i * 60) - 15, ground - 34), 5)
		img.alpha_composite(glow(figures, (255, 200, 120), 12, 0.7))
		img.alpha_composite(figures)
		titled(img, "GHOST", 10, (fx(top_mid), H * 0.17), look["accent"], (255, 140, 30))
		titled(img, "HOTEL", 10, (fx(top_mid), H * 0.17 + 95), look["accent"], (255, 140, 30))
	return np.array(img)


def marquee_art(look, game, w, h):
	W, H = int(w * PX_M), int(h * PX_M)
	if game == "deadra":
		img = gradient(W, H, (20, 6, 26), (6, 2, 8))
		d = ImageDraw.Draw(img)
		for i in range(W // 30 + 1):
			tile(d, list(TILES)[i % 3], (i * 30, H - 30), 5)
			tile(d, list(TILES)[(i + 1) % 3], (i * 30, 0), 5)
		titled(img, "DEADRA", 13, (W / 2, H / 2), look["accent"], (120, 255, 80))
	else:
		img = gradient(W, H, (24, 22, 80), (8, 10, 34))
		d = ImageDraw.Draw(img)
		sprite(d, SHEET, (30, H // 2 - 40), 10, {"#": (235, 240, 255), "o": (20, 20, 40)})
		sprite(d, SHEET, (W - 110, H // 2 - 40), 10, {"#": (235, 240, 255), "o": (20, 20, 40)})
		titled(img, "GHOST HOTEL", 8, (W / 2, H / 2), look["accent"], (255, 140, 30))
	return np.array(img)


def bezel_art(look, game, w, h):
	"""Rahmen um den Bildschirm (Mitte = Bildmitte), schwarz mit Linie und Figuren."""
	W, H = int(w * PX_M), int(h * PX_M)
	img = Image.new("RGBA", (W, H), (8, 8, 10, 255))
	d = ImageDraw.Draw(img)
	inset = 18
	for i in range(0, W - 2 * inset, 14):
		d.rectangle([inset + i, inset, inset + i + 6, inset + 5], fill=look["trim"])
		d.rectangle([inset + i, H - inset - 5, inset + i + 6, H - inset], fill=look["trim"])
	for side in (0, 1):
		x = 22 if side == 0 else W - 22 - 48
		if game == "deadra":
			tile(d, "ghost", (x, int(H * 0.3)), 8)
			tile(d, "pumpkin", (x, int(H * 0.45)), 8)
			tile(d, "skull", (x, int(H * 0.6)), 8)
		else:
			sprite(d, SHEET, (x - 8, int(H * 0.32)), 8, {"#": (235, 240, 255), "o": (20, 20, 40)})
			sprite(d, MAN, (x - 8, int(H * 0.55)), 8, {"#": (255, 230, 60)})
	return np.array(img)


def panel_art(look, game, w, h):
	W, H = int(w * PX_M), int(h * PX_M)
	img = Image.new("RGBA", (W, H), (10, 10, 12, 255))
	d = ImageDraw.Draw(img)
	inset = 16
	if game == "deadra":
		for i in range(0, W - 2 * inset, 18):
			for y in (inset, H - inset - 8):
				d.rectangle([inset + i, y, inset + i + 8, y + 8], fill=look["trim"])
		tile(d, "skull", (int(W * 0.08), H // 2 - 18), 6)
	else:
		for i in range(0, W - 2 * inset, 16):
			for y in (inset, H - inset - 6):
				d.ellipse([inset + i, y, inset + i + 6, y + 6], fill=(255, 190, 120))
		tile(d, "pumpkin", (int(W * 0.08), H // 2 - 18), 6)
	return np.array(img)


# --- Zusammensetzen ----------------------------------------------------------------------------------------
def region(pos, tris, roles, role, axes):
	"""Ausdehnung der Rolle in Metern entlang axes (wie bei project): linke untere Ecke und Größe."""
	p = pos[np.unique(tris[roles == role].ravel())]
	a, b = p[:, axes[0]] * axes[1], p[:, axes[2]] * axes[3]
	return (a.min(), b.min()), (a.max() - a.min(), b.max() - b.min())


def dilate(color, mask, steps=12):
	"""Füllt die Lücken zwischen den UV-Inseln mit der Nachbarfarbe (gegen Säume in den Mipmaps)."""
	c = color.astype(np.float32)
	m = mask.astype(np.float32)
	for _ in range(steps):
		acc = np.zeros_like(c)
		cnt = np.zeros_like(m)
		for dy, dx in ((0, 1), (0, -1), (1, 0), (-1, 0)):
			acc += np.roll(c * m[..., None], (dy, dx), (0, 1))
			cnt += np.roll(m, (dy, dx), (0, 1))
		grow = (m == 0) & (cnt > 0)
		c[grow] = acc[grow] / cnt[grow][:, None]
		m = np.maximum(m, grow)
	return c.astype(color.dtype)


def noise(shape, scale, seed):
	r = np.random.default_rng(seed)
	small = r.random((shape[0] // scale + 2, shape[1] // scale + 2)).astype(np.float32)
	img = Image.fromarray((small * 255).astype(np.uint8)).resize((shape[1], shape[0]), Image.BICUBIC)
	return np.array(img, np.float32) / 255.0


def normal_from_height(h, strength):
	gx = (np.roll(h, -1, 1) - np.roll(h, 1, 1)) * 0.5
	gy = (np.roll(h, -1, 0) - np.roll(h, 1, 0)) * 0.5
	# OpenGL: Grün zeigt nach +V; Bildzeilen laufen nach unten, die UV-v der GLB auch → Zeilenrichtung = −Grün
	n = np.dstack([-gx * strength, gy * strength, np.ones_like(h)])
	n /= np.linalg.norm(n, axis=2, keepdims=True)
	return ((n * 0.5 + 0.5) * 255).astype(np.uint8)


def build(game, pos, tris, roles, label, where, out):
	look = LOOKS[game]
	color = np.zeros((ATLAS, ATLAS, 3), np.uint8)
	color[:] = look["body"]
	color[label == TRIM] = look["trim"]
	color[label == PANEL_EDGE] = look["trim"]
	height = np.zeros((ATLAS, ATLAS), np.float32)
	# Seiten: waagrecht die Tiefe; rechts (+x) sieht man die Front links im Bild, links rechts
	for role, flip in ((SIDE_R, -1.0), (SIDE_L, 1.0)):
		axes = (2, flip, 1, 1.0)
		lo, size = region(pos, tris, roles, role, axes)
		project(label, where, role, axes, side_art(look, game, size[0], size[1], flip > 0), lo, color)
	for role, fn in ((MARQUEE, marquee_art), (BEZEL, bezel_art)):
		axes = (0, 1.0, 1, 1.0)
		lo, size = region(pos, tris, roles, role, axes)
		project(label, where, role, axes, fn(look, game, size[0], size[1]), lo, color)
	# Bedienfeld: oben im Bild liegt die Kante zum Bildschirm (−z)
	axes = (0, 1.0, 2, -1.0)
	lo, size = region(pos, tris, roles, PANEL, axes)
	project(label, where, PANEL, axes, panel_art(look, game, size[0], size[1]), lo, color)

	used = label > 0
	# Rauheit: Lack mit Orangenhaut, auf dem Bedienfeld fettige Stellen vom Anfassen
	rough = np.ones((ATLAS, ATLAS), np.float32) * ROUGH[BODY]
	for r, v in ROUGH.items():
		rough[label == r] = v
	smudge = noise((ATLAS, ATLAS), 24, 5) * noise((ATLAS, ATLAS), 6, 6)
	rough[label == PANEL] -= np.clip(smudge[label == PANEL] - 0.3, 0, 1) * 0.35
	rough += (noise((ATLAS, ATLAS), 8, 7) - 0.5) * 0.06
	glow_mask = (label == MARQUEE).astype(np.float32)
	# Höhe: feine Orangenhaut im Lack, Kante als gewölbte Leiste mit Rille, Folienrand der Seitenbilder
	peel = (label == BODY) | (label == SIDE_R) | (label == SIDE_L)      # Schild, Rahmen und Bedienfeld sind glatt
	height += noise((ATLAS, ATLAS), 12, 8) * 0.8 * peel                # leichte Orangenhaut im Lack
	trim = (label == TRIM).astype(np.float32)
	soft = np.array(Image.fromarray((trim * 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(3)), np.float32) / 255
	height += soft * 4.0
	side = ((label == SIDE_R) | (label == SIDE_L)).astype(np.float32)
	height += np.array(Image.fromarray((side * 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(1)), np.float32) / 255 * 1.5

	color = dilate(color, used)
	rough_img = np.dstack([glow_mask, np.clip(rough, 0.05, 1.0), np.zeros_like(rough)])
	rough_img = dilate((rough_img * 255).astype(np.uint8), used)
	normal = normal_from_height(height, 0.35)
	Image.fromarray(color).save("%s/arcade_%s.png" % (out, game))
	Image.fromarray(normal).save("%s/arcade_normal.png" % out)          # hängt nicht vom Spiel ab
	Image.fromarray(rough_img).save("%s/arcade_rough.png" % out)


def stick(game, src, out):
	# Textur aus dem FBX-Paket (2000²): dort aufrecht, die UVs der GLB erwarten sie gespiegelt wie im glTF
	img = Image.open(src).convert("RGB").resize((1024, 1024), Image.LANCZOS).transpose(Image.FLIP_TOP_BOTTOM)
	img = np.array(img, np.float32)
	red = (img[..., 0] > 150) & (img[..., 1] < 90) & (img[..., 2] < 90)
	shade = img[..., 0:1] / 255.0
	tinted = np.array(LOOKS[game]["stick"], np.float32)[None, None] * shade
	img[red] = tinted[red]
	Image.fromarray(img.astype(np.uint8)).save("%s/arcade_%s_stick.png" % (out, game))


def main():
	glb, joystick, out = sys.argv[1:4]
	pos, uv, tris = read_glb(glb, "cabinet")
	roles = classify(pos, uv, tris)
	label, where = raster(uv, pos, tris, roles)
	print("Rollen:", {r: int((roles == r).sum()) for r in range(1, 9)})
	for game in LOOKS:
		build(game, pos, tris, roles, label, where, out)
		stick(game, joystick, out)
		print("arcade_%s: fertig" % game)


main()
