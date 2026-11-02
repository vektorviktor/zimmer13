# Farbleitsystem des Gebäudeplans (ZIM-139) und verlustfreies Umfärben von map_a.aseprite (ZIM-140).
#
# Jede Gruppe hat einen Farbbereich, Untertypen unterscheiden sich über Helligkeit und Sättigung (DESIGN, HSL):
#   Flächen blass – Gäste/Wohnen warm, Gesellschaft rosa, Wasser blau, draußen grün, Wege violett, Betrieb grau ·
#   Öffnungen kräftig – Türen grün, Fenster blau, Haupteingang rot · Möbel mittel – Schlafen violett, Aufbewahren
#   braun, Tische/Sitzen ocker, Bad türkis, Geräte stahlblau, Spiel rot, draußen grün · Ausstattung rosa (Wand) bzw.
#   gelbgrün (Pflanzen) · Gegenstände orange · Lichter gelb (defekt = dunkler) · Markierungen magenta.
# Vorderseite = gleiche Farbe, heller (FRONT_LIGHTER).
#
# Aufruf (Python 3 mit Pillow):
#   python tools/plan_recolor.py vorschlag   Abstände prüfen, Vorschau nach temp/umfaerben/ (Legende alt → neu, Stockwerke)
#   python tools/plan_recolor.py anwenden    Sicherung nach temp/umfaerben/, Plan umfärben, PLANFARBEN.md umschreiben,
#                                            map_colors.png/map_a.gpl neu, Prüfung: build_map ergibt dieselben Karten
import colorsys, os, shutil, struct, subprocess, sys, zlib

TOOLS = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(TOOLS)
sys.path.insert(0, TOOLS)
import plan_legend

PLAN = os.path.join(ROOT, "map_a.aseprite")
LEGEND = plan_legend.DEFAULT
OUT = os.path.join(ROOT, "temp", "umfaerben")
## Ebenen, deren Farben build_map.py nach der Legende liest (die anderen bleiben, wie sie sind)
LAYERS = ("Grundriss", "Möbel", "Ausstattung", "Gegenstände", "Lichter", "Teppiche")
FLOORS = ("DG", "OG1", "EG", "UG")
BAND = 790
MIN_DIST = 18            ## kleinster Abstand zweier Legendenfarben (RGB, euklidisch)
FRONT_LIGHTER = 12       ## Vorderseite: so viel heller (Prozentpunkte L)
## Markierungen dürfen sich ähneln (beide magenta, verschiedene Ebenen)
MARKERS = {"Türanschlag", "Möbel: Vorderseite"}

## Name → (Farbton °, Sättigung %, Helligkeit %) oder fester Hexwert. Gruppen siehe Kopf.
DESIGN = {
	# Wände
	"Wand": "000000", "Glaswand": (195, 70, 86), "Gitter": (270, 25, 18), "Leviathanmauer": (352, 45, 24),
	# Flächen · Gäste und Wohnen (warm)
	"Zimmer": (25, 80, 74), "Zimmer leer": (25, 30, 70), "Rezeption": (28, 65, 58), "Bibliothek": (15, 35, 60),
	"Katzenraum": (20, 55, 82),
	# Flächen · Gesellschaft (rosa)
	"Bar": (345, 50, 76), "Partyraum": (318, 45, 78), "Bowlingbahn": (330, 25, 66), "Foullinie": (345, 70, 45),
	# Flächen · Wasser und Sanitär (blau)
	"Pool Wasser": (205, 90, 55), "Pool Umgang": (205, 30, 78), "Bad": (188, 50, 70), "Toilette": (198, 60, 64),
	"Wäscherei": (218, 50, 72),
	# Flächen · draußen (grün)
	"Garten": (105, 65, 82), "Terrasse": (88, 28, 74), "Terrassenkante": (120, 55, 26), "Baum": (135, 70, 34),
	"Pflanzkübel": (110, 35, 54), "Kiesweg": (50, 20, 64), "Heckenbogen": (150, 40, 44), "Balkon": (95, 15, 66),
	"Balkongeländer": (95, 15, 40),
	# Flächen · Wege (violett)
	"Flur": (250, 40, 88), "Treppe": (262, 32, 78), "Treppenstufe": (262, 25, 55), "Aufzug": (278, 35, 68),
	"Luftraum": (250, 40, 28),
	# Flächen · Verwaltung (gold)
	"Büro der Direktion": (45, 70, 58), "Sekretariat": (52, 75, 70),
	# Flächen · Betrieb und Keller (grau)
	"Betriebsraum": (0, 0, 96), "Lagerraum": (30, 6, 74), "Kellerboden": (0, 0, 66), "Kellerraum": (0, 0, 55),
	"Kellerraum zu": (0, 0, 40), "Heizkeller": (8, 40, 42), "Technikraum": (210, 18, 60), "Müllraum": (35, 25, 44),
	"Dachboden": (30, 18, 52), "Hausmeisterraum": (200, 12, 70),
	# Öffnungen · Türen grün, Fenster blau, Haupteingang rot, Türanschlag magenta
	"Tür Flur": (110, 90, 52), "Tür Terrasse": (140, 90, 42), "Doppel-Glastür": (165, 85, 45),
	"Betriebstür": (70, 25, 58), "Milchglastür": (140, 70, 62), "Aufzugtür": (125, 45, 32), "Haupteingang": "ff0000", "Türanschlag": "f300ff",
	"Gittertür": (95, 45, 40), "Fenster": (210, 85, 58), "Dachfenster": (200, 90, 74),
	# Möbel · Markierung
	"Möbel: Vorderseite": "ff00ff",
	# Möbel · Schlafen (violett)
	"Möbel: Bett": (280, 40, 40), "Möbel: Doppelbett": (280, 45, 50), "Möbel: Nachttisch": (300, 35, 26),
	# Möbel · Aufbewahren (braun)
	"Möbel: Schrank": (30, 35, 22), "Möbel: Kommode": (28, 50, 38), "Möbel: Truhe": (40, 65, 30),
	"Möbel: Regal": (18, 35, 44), "Möbel: Wäschekiste": (35, 30, 58), "Möbel: Kratzbaum": (22, 55, 66),
	"Möbel: Bücherregal 4 Ebenen 1 m": (22, 70, 44), "Möbel: Bücherregal 4 Ebenen 2 m": (36, 70, 54),
	"Möbel: Bücherregal 5 Ebenen 1 m": (12, 70, 44), "Möbel: Bücherregal 5 Ebenen 2 m": (10, 30, 54),
	# Möbel · Tische und Sitzen (ocker)
	"Möbel: Tisch": (42, 50, 50), "Möbel: Couchtisch": (44, 45, 60), "Möbel: Tafel": (36, 45, 42),
	"Möbel: Zimmertisch": (48, 60, 38), "Möbel: Schreibtisch": (48, 70, 20), "Möbel: Sekretariatsschreibtisch": (44, 65, 24),
	"Möbel: Stuhl": (58, 50, 40), "Möbel: Bank": (60, 30, 36),
	"Möbel: Sofa": (15, 50, 36), "Möbel: Fußmatte": (20, 10, 30),
	# Möbel · Bad (türkis)
	"Möbel: Badewanne": (185, 70, 46), "Möbel: Wannenablage": (180, 30, 26), "Möbel: Waschbecken": (168, 65, 52),
	"Möbel: Dusche": (198, 45, 36), "Möbel: WC": (152, 70, 26), "Möbel: Waschtisch": (175, 25, 62),
	# Möbel · Küche und Geräte (stahlblau)
	"Möbel: Küchenzeile": (210, 20, 56), "Möbel: Herd": (215, 25, 28), "Möbel: Waschmaschine": (205, 40, 66),
	"Möbel: Snackautomat": (228, 55, 34), "Möbel: Getränkeautomat": (200, 60, 36), "Möbel: Mülleimer": (215, 20, 40),
	# Möbel · Spiel und Bar (rot)
	"Möbel: Theke": (345, 30, 28), "Möbel: Schachtisch": (355, 35, 20), "Möbel: Spieltisch": (355, 50, 36),
	"Möbel: Videoautomat": (335, 70, 44), "Möbel: Spieleschrank": (8, 45, 46), "Möbel: Spielautomat": (349, 85, 34),
	"Möbel: Puppenhaus": (0, 65, 54), "Möbel: Barhocker": (35, 55, 46),
	# Möbel · draußen und Friedhof (grün), Bau (grau)
	"Möbel: Grab": (110, 25, 32), "Möbel: Gedenkstätte": (90, 35, 52), "Möbel: Säule": (0, 0, 50), "Möbel: Spind": (205, 12, 48),
	# Teppiche
	"Teppich: Läufer": (0, 60, 28), "Teppich: Teppich": (1, 75, 15),
	# Ausstattung · an der Wand und im Raum (rosa)
	"Ausstattung: Lichtschalter": (320, 90, 55), "Ausstattung: Telefon": (338, 85, 48),
	"Ausstattung: Bild": (308, 55, 60), "Ausstattung: Zettel": (335, 80, 86), "Ausstattung: UV-Schrift": (290, 95, 55),
	"Ausstattung: Kalender": (348, 75, 64), "Ausstattung: Tagebuch": (330, 55, 32),
	"Ausstattung: Fotowand": (300, 40, 50),
	 "Ausstattung: Spinnweben": (300, 12, 84),
	"Ausstattung: Dekokiste": (325, 45, 46), "Ausstattung: Kerzenvorrat": (340, 90, 72),
	"Ausstattung: Ersatzbirnen": (305, 80, 72), "Ausstattung: Duschplatz": (300, 60, 80),
	"Ausstattung: Bodenablauf": (295, 70, 35), "Ausstattung: Dartscheibe": (335, 55, 38),
	"Ausstattung: Maskenboard": (300, 45, 30), "Ausstattung: Apfelbottich": (350, 55, 62),
	"Ausstattung: Sicherungskasten": (275, 25, 62), "Ausstattung: Aushangbrett": (320, 40, 58),
	"Ausstattung: Wanduhr": (315, 25, 74), "Ausstattung: Krähennest": (325, 25, 22),
	"Ausstattung: Leviathan-Druck": (280, 85, 46),
	# Ausstattung · Garten (gelbgrün)
	"Ausstattung: Kürbispflanze": (88, 85, 40), "Ausstattung: Kürbispflanze Hokkaido": (72, 85, 46),
	"Ausstattung: Kürbispflanze Weiß": (80, 45, 72), "Ausstattung: Kürbispflanze Butternut": (66, 65, 56),
	"Ausstattung: Kürbispflanze Muskat": (100, 60, 28), "Ausstattung: Kürbispflanze Türkenturban": (112, 70, 46),
	"Ausstattung: Kürbispflanze Riese": (80, 95, 32), "Ausstattung: Laubhaufen": (30, 75, 32),
	# Gegenstände (orange)
	"Gegenstand: Kürbis": (26, 100, 50), "Gegenstand: Geschnitzter Kürbis": (14, 100, 50),
	"Gegenstand: Kerze": (40, 100, 82), "Gegenstand: Schlüssel": (44, 90, 54), "Gegenstand: Spinnweben": (40, 25, 76),
	"Gegenstand: Laub": (22, 80, 34), "Gegenstand: Münzen": (46, 70, 42), "Gegenstand: Messer": (30, 12, 60),
	"Gegenstand: Würfelbecher": (18, 50, 28), "Gegenstand: Gezinkte Würfel": (36, 45, 90),
	"Gegenstand: Glühbirne": (48, 100, 88), "Gegenstand: Kleidung": (10, 60, 62), "Gegenstand: Kompass": (34, 70, 38),
	"Gegenstand: Karte": (40, 65, 70), "Gegenstand: Taschenlampe": (30, 80, 18), "Gegenstand: Batterie": (16, 75, 72),
	"Gegenstand: UV-Filter": (4, 85, 40), "Gegenstand: Schachbrett": (30, 25, 40), "Gegenstand: Brecheisen": (8, 90, 28),
	"Gegenstand: Werkzeugkasten": (0, 80, 52), "Gegenstand: Dartpfeile": (18, 85, 55), "Gegenstand: Salz": (15, 95, 70),
	# Lichter (gelb, defekt = dunkler)
	"Licht: Wandleuchte": (52, 100, 50), "Licht: Wandleuchte defekt": (52, 100, 24), "Licht: Kerze": (40, 100, 60),
	"Licht: Laterne": (58, 100, 70), "Licht: Laterne defekt": (60, 40, 30), "Licht: Deckenleuchte": (55, 100, 84),
	"Licht: Halogenleuchte": (62, 70, 58),
	"Licht: Discokugel": (55, 90, 72), "Licht: Unterwasserlampe": (60, 70, 45),
}


def hex_of(spec, lighter=0):
	if isinstance(spec, str):
		return spec
	h, s, l = spec
	r, g, b = colorsys.hls_to_rgb(h / 360.0, min(100, l + lighter) / 100.0, s / 100.0)
	return "%02x%02x%02x" % tuple(round(c * 255) for c in (r, g, b))


def rgb(hx):
	return tuple(int(hx[i:i + 2], 16) for i in (0, 2, 4))


def dist(a, b):
	return sum((x - y) ** 2 for x, y in zip(rgb(a), rgb(b))) ** 0.5


def mapping():
	"""Alte Farbe → neue Farbe (Hex) und Name → neue Farbe, je Eintrag samt Vorderseite."""
	entries = plan_legend.read(LEGEND)
	missing = [e["name"] for e in entries if e["name"] not in DESIGN]
	assert not missing, "Ohne Farbe im DESIGN: " + ", ".join(missing)
	old_new, by_name = {}, {}
	for e in entries:
		spec = DESIGN[e["name"]]
		old_new[e["hex"]], by_name[e["name"]] = hex_of(spec), hex_of(spec)
		if e["front"]:
			fh = hex_of(spec, FRONT_LIGHTER)
			old_new[e["front_hex"]], by_name[e["front"]] = fh, fh
	return entries, old_new, by_name


# --- Aseprite lesen und schreiben ---------------------------------------------------------------------

def read_plan(path=PLAN):
	"""(Bytes, Breite, Höhe, Ebenen [Name], Zellen [(Ebene, x, y, w, h, Pixel, Chunk-Start, Chunk-Ende)])."""
	data = open(path, "rb").read()
	_, magic, frames, w, h, depth = struct.unpack_from("<IHHHHH", data, 0)
	assert magic == 0xA5E0 and depth == 32 and frames == 1, "erwartet: RGBA-Aseprite mit einem Frame"
	fsize, _, old, _, _, new = struct.unpack_from("<IHHH2sI", data, 128)
	layers, cels, p = [], [], 144
	for _ in range(new or old):
		size, ctype = struct.unpack_from("<IH", data, p)
		cd = p + 6
		if ctype == 0x2004:
			n = struct.unpack_from("<H", data, cd + 16)[0]
			layers.append(data[cd + 18:cd + 18 + n].decode())
		elif ctype == 0x2005:
			li, x, y, _, ctyp = struct.unpack_from("<HhhBH", data, cd)
			assert ctyp in (0, 2), "Zellenart %d nicht unterstützt" % ctyp
			cw, ch = struct.unpack_from("<HH", data, cd + 16)
			raw = data[cd + 20:p + size]
			cels.append((li, x, y, cw, ch, raw if ctyp == 0 else zlib.decompress(raw), p, p + size))
		p += size
	return data, w, h, layers, cels


def recolor_bytes(path, old_new):
	"""Plan mit umgefärbten Ebenen (LAYERS) und Palette als neue Bytes; zählt die ersetzten Pixel."""
	data, w, h, layers, cels = read_plan(path)
	count = 0
	table = {bytes(rgb(o)): bytes(rgb(n)) for o, n in old_new.items()}
	chunks = []
	p = 144
	fsize, _, old, _, _, new = struct.unpack_from("<IHHH2sI", data, 128)
	for _ in range(new or old):
		size, ctype = struct.unpack_from("<IH", data, p)
		chunk = data[p:p + size]
		if ctype == 0x2005:
			cel = next(c for c in cels if c[6] == p)
			if layers[cel[0]] in LAYERS:
				px = bytearray(cel[5])
				for i in range(0, len(px), 4):
					if px[i + 3] and bytes(px[i:i + 3]) in table:
						px[i:i + 3] = table[bytes(px[i:i + 3])]
						count += 1
				body = chunk[6:6 + 20]
				body = body[:7] + struct.pack("<H", 2) + body[9:]   # Zellenart 2: komprimiert speichern
				payload = body + zlib.compress(bytes(px), 9)
				chunk = struct.pack("<IH", 6 + len(payload), 0x2005) + payload
		elif ctype == 0x0004:   # alte Palette: Pakete mit RGB-Tripeln
			buf, q = bytearray(chunk), 6
			packets = struct.unpack_from("<H", buf, q)[0]
			q += 2
			for _ in range(packets):
				n = buf[q + 1] or 256
				q += 2
				for k in range(n):
					c = bytes(buf[q + 3 * k:q + 3 * k + 3])
					if c in table:
						buf[q + 3 * k:q + 3 * k + 3] = table[c]
				q += 3 * n
			chunk = bytes(buf)
		elif ctype == 0x2019:
			raise SystemExit("Neue Palette (0x2019) – nicht unterstützt, bitte melden")
		chunks.append(chunk)
		p += size
	frame_body = b"".join(chunks)
	frame = bytearray(data[128:144])
	struct.pack_into("<I", frame, 0, 16 + len(frame_body))
	result = bytearray(data[:128]) + frame + frame_body
	struct.pack_into("<I", result, 0, len(result))
	return bytes(result), count


def stray_colors(path, legend_hex):
	"""Farben in den Legenden-Ebenen, die nicht in der Legende stehen (dürfen keine neue Farbe treffen)."""
	_, w, h, layers, cels = read_plan(path)
	seen = set()
	for li, x, y, cw, ch, px, _, _ in cels:
		if layers[li] in LAYERS:
			for i in range(0, len(px), 4):
				if px[i + 3]:
					seen.add(px[i:i + 3].hex())
	return seen - set(legend_hex)


# --- Vorschau -----------------------------------------------------------------------------------------

def render(path, old_new=None):
	"""Plan als Bild: Legenden-Ebenen übereinander auf Weiß, optional umgefärbt."""
	from PIL import Image
	_, w, h, layers, cels = read_plan(path)
	img = Image.new("RGB", (w, h), (255, 255, 255))
	table = {bytes(rgb(o)): bytes(rgb(n)) for o, n in (old_new or {}).items()}
	order = {name: i for i, name in enumerate(layers)}
	for li, x, y, cw, ch, px, _, _ in sorted(cels, key=lambda c: c[0]):
		if layers[li] not in LAYERS and layers[li] != "Beschriftung":
			continue
		buf = bytearray(px)
		if table and layers[li] in LAYERS:
			for i in range(0, len(buf), 4):
				if buf[i + 3] and bytes(buf[i:i + 3]) in table:
					buf[i:i + 3] = table[bytes(buf[i:i + 3])]
		cel = Image.frombytes("RGBA", (cw, ch), bytes(buf))
		img.paste(cel, (x, y), cel)
	return img


def preview(entries, old_new):
	from PIL import Image, ImageDraw, ImageFont
	os.makedirs(OUT, exist_ok=True)
	old_img, new_img = render(PLAN), render(PLAN, old_new)
	for i, floor in enumerate(FLOORS):
		box = (0, i * BAND, old_img.width, (i + 1) * BAND)
		a, b = old_img.crop(box), new_img.crop(box)
		pair = Image.new("RGB", (a.width, a.height * 2 + 10), (40, 40, 40))
		pair.paste(a, (0, 0))
		pair.paste(b, (0, a.height + 10))
		pair.save(os.path.join(OUT, "vorschau_%s.png" % floor.lower()))
	# Legende alt → neu, nach Gruppen
	def font(size, bold=False):
		for name in (("segoeuib.ttf",) if bold else ("segoeui.ttf",)):
			try:
				return ImageFont.truetype(name, size)
			except OSError:
				pass
		return ImageFont.load_default(size)
	groups = []
	for e in entries:
		if not groups or groups[-1][0] != e["title"]:
			groups.append((e["title"], []))
		groups[-1][1].append(e)
	cols = [["Wände", "Flächen", "Öffnungen"], ["Möbel", "Teppiche"], ["Ausstattung", "Gegenstände", "Lichter"]]
	row, colw = 22, 520
	height = max(sum(2 + len(dict(groups)[t]) for t in col if t in dict(groups)) for col in cols) * row + 90
	img = Image.new("RGB", (colw * 3 + 40, height), (255, 255, 255))
	d = ImageDraw.Draw(img)
	d.text((20, 16), "Farbleitsystem – Vorschlag (links alt, rechts neu)", font=font(22, True), fill=(20, 20, 20))
	fh, fn, fx = font(16, True), font(14), font(12)
	for c, col in enumerate(cols):
		x, y = 20 + c * colw, 60
		for title in col:
			items = dict(groups).get(title, [])
			d.text((x, y), title, font=fh, fill=(20, 20, 20))
			y += int(row * 1.4)
			for e in items:
				nh = old_new[e["hex"]]
				d.rectangle((x, y + 2, x + 26, y + 17), fill=rgb(e["hex"]), outline=(200, 200, 200))
				d.text((x + 32, y + 2), "→", font=fn, fill=(120, 120, 120))
				d.rectangle((x + 50, y + 2, x + 90, y + 17), fill=rgb(nh), outline=(200, 200, 200))
				tx = x + 96
				if e["front"]:
					d.rectangle((tx, y + 2, tx + 16, y + 17), fill=rgb(old_new[e["front_hex"]]), outline=(200, 200, 200))
					tx += 22
				d.text((tx, y + 1), e["short"], font=fn, fill=(20, 20, 20))
				d.text((tx + d.textlength(e["short"], font=fn) + 8, y + 3), "#" + nh, font=fx, fill=(120, 120, 120))
				y += row
			y += int(row * 0.6)
	img.save(os.path.join(OUT, "vorschau_legende.png"))


def check(entries, old_new, by_name):
	problems = []
	names = list(by_name)
	for i, a in enumerate(names):
		for b in names[i + 1:]:
			dd = dist(by_name[a], by_name[b])
			if dd < MIN_DIST and {a, b} != MARKERS:
				problems.append("%-40s %-40s Abstand %4.1f (#%s / #%s)" % (a, b, dd, by_name[a], by_name[b]))
	for s in sorted(stray_colors(PLAN, old_new)):
		for n, hx in by_name.items():
			if dist(s, hx) < 1:
				problems.append("neue Farbe von %s trifft eine fremde Farbe im Plan (#%s)" % (n, s))
	return problems


def build_maps(plan_dir, out_dir):
	env = dict(os.environ, PYTHONIOENCODING="utf-8")
	os.makedirs(out_dir, exist_ok=True)
	subprocess.run([sys.executable, os.path.join(TOOLS, "build_map.py"), os.path.join(plan_dir, "map_a.aseprite"), out_dir],
		check=True, capture_output=True, env=env)
	return {f: open(os.path.join(out_dir, f), "rb").read() for f in os.listdir(out_dir) if f.endswith(".json")}


def rewrite_legend(path, entries, old_new):
	"""Farben in den Legenden-Tabellen einer PLANFARBEN.md ersetzen (nur Spalten Farbe und Vorderseite)."""
	lines = open(path, encoding="utf-8").read().split("\n")
	for e in entries:
		i = e["line"] - 1
		line = lines[i].replace("#" + e["hex"], "#" + old_new[e["hex"]], 1)
		if e["front"]:
			line = line.replace("#" + e["front_hex"], "#" + old_new[e["front_hex"]], 1)
		lines[i] = line
	open(path, "w", encoding="utf-8", newline="\n").write("\n".join(lines))


def apply(entries, old_new):
	os.makedirs(OUT, exist_ok=True)
	before = os.path.join(OUT, "vorher")
	shutil.rmtree(before, ignore_errors=True)
	os.makedirs(before)
	shutil.copy2(PLAN, os.path.join(before, "map_a.aseprite"))
	shutil.copy2(LEGEND, os.path.join(before, "PLANFARBEN.md"))
	maps_before = build_maps(before, os.path.join(before, "karten"))
	data, count = recolor_bytes(PLAN, old_new)
	after = os.path.join(OUT, "nachher")
	shutil.rmtree(after, ignore_errors=True)
	os.makedirs(after)
	open(os.path.join(after, "map_a.aseprite"), "wb").write(data)
	shutil.copy2(LEGEND, os.path.join(after, "PLANFARBEN.md"))
	# Legende in der Kopie umschreiben, dann prüfen – erst wenn alles gleich ist, die echten Dateien ersetzen
	rewrite_legend(os.path.join(after, "PLANFARBEN.md"), entries, old_new)
	maps_after = build_maps(after, os.path.join(after, "karten"))
	diff = [f for f in maps_before if maps_before[f] != maps_after.get(f)]
	if diff or set(maps_before) != set(maps_after):
		raise SystemExit("Abbruch – Karten weichen ab: %s (Plan unverändert, Kopien in %s)" % (", ".join(diff), OUT))
	shutil.copy2(os.path.join(after, "map_a.aseprite"), PLAN)
	shutil.copy2(os.path.join(after, "PLANFARBEN.md"), LEGEND)
	env = dict(os.environ, PYTHONIOENCODING="utf-8")
	subprocess.run([sys.executable, os.path.join(TOOLS, "build_colors.py")], check=True, env=env)
	print("%d Pixel umgefärbt, %d Karten gleich. Sicherung: %s" % (count, len(maps_before), before))


if __name__ == "__main__":
	mode = sys.argv[1] if len(sys.argv) > 1 else "vorschlag"
	entries, old_new, by_name = mapping()
	problems = check(entries, old_new, by_name)
	for p in problems:
		print("  " + p)
	print("%d Farben, %d zu nah oder doppelt" % (len(by_name), len(problems)))
	if mode == "vorschlag":
		preview(entries, old_new)
		print("Vorschau in", OUT)
	elif mode == "anwenden":
		if problems:
			raise SystemExit("Erst die Abstände beheben.")
		apply(entries, old_new)
