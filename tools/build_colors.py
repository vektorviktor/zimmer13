# Zeichnet die Legende des Gebäudeplans (Spielkonzept 7.5) als Bild map_colors.png: jede Farbe aus <plan>.gpl
# als Farbfeld mit Name, Hex-Wert und kurzer Beschreibung, nach Gruppen (Wände, Flächen, Öffnungen, Möbel,
# Teppiche, Ausstattung, Gegenstände, Lichter) in drei Spalten. Ersetzt die Palette in Aseprite als Vorlage
# zum Zeichnen: Farbe mit der Pipette aus dem Bild nehmen. Die Farbfelder sind exakt die Legendenfarben.
# Welche Namen Flächen und Öffnungen sind, liest das Skript aus FILLS/OPENINGS in tools/build_map.py.
# Neue Farbe: Zeile in <plan>.gpl ergänzen, dann dieses Skript neu laufen lassen.
#
# Aufruf (Python 3 mit Pillow):
#   python tools/build_colors.py [map_a.gpl] [map_colors.png]
import ast, os, sys
from PIL import Image, ImageDraw, ImageFont

SRC = sys.argv[1] if len(sys.argv) > 1 else "map_a.gpl"
DST = sys.argv[2] if len(sys.argv) > 2 else "map_colors.png"
BUILD_MAP = os.path.join(os.path.dirname(os.path.abspath(__file__)), "build_map.py")

ROW = 24                ## Zeilenhöhe in px
SWATCH = (40, 18)       ## Farbfeld
FRONT_SWATCH = (18, 18) ## Farbfeld der Vorderseite neben dem Möbel
COL_W = 560             ## Spaltenbreite
MARGIN = 24
FRAME = (200, 200, 200)
TEXT = (20, 20, 20)
GREY = (120, 120, 120)

## Kurzbeschreibungen für Farben, deren Name nicht alles sagt (sonst bleibt die Zeile ohne)
NOTES = {
	"Wand": "2 px breite Linie (20 cm)",
	"Glaswand": "wie Wand, aus Glas",
	"Zimmer leer": "Zimmerfläche eines unbewohnten Zimmers",
	"Ausstattung: Schlüsselschrank": "an der Wand, verglast – Generalschlüssel",
	"Luftraum": "kein Boden – darunter offene Decke",
	"Kellerraum zu": "zählt wie unbemalt, nichts gebaut",
	"Treppe": "Fläche der Treppe bzw. des Treppenhauses",
	"Treppenstufe": "Anfang und Ende der Läufe",
	"Terrassenkante": "Hecke am Terrassenrand",
	"Balkongeländer": "Geländer am Balkonrand",
	"Pool Wasser": "Becken",
	"Pool Umgang": "Rand um das Becken",
	"Haupteingang": "auch: verschlossene Tür",
	"Türanschlag": "1 px am Ende des Türstrichs, Seite des Scharniers",
	"Möbel: Vorderseite": "Strich am Rand, gilt für jedes Möbel",
	"Möbel: Wannenablage": "gefliest, neben die Wanne (1 m = 10 px)",
	"Dachboden": "Bohlen, Decke 2,2 m, Türen niedrig",
	"Dachfenster": "auf der Außenwand – Fenster in der Dachschräge",
}
## Gruppen in Spalten: (Überschrift, Zeichenregel, Auswahl)
COLUMNS = [
	[("Wände", "Linien im Grundriss", "wall"), ("Flächen", "Füllfarben im Grundriss", "fill"),
		("Öffnungen", "Striche auf der Wandlinie", "opening")],
	[("Möbel", "Ebene Möbel · Rechteck in Grundfläche, hellere Randzeile = Vorderseite", "Möbel: "),
		("Teppiche", "Ebene Teppiche · Rechteck", "Teppich: ")],
	[("Ausstattung", "Ebene Ausstattung · 3×3-Punkt, Wandsachen innen an der Wand", "Ausstattung: "),
		("Gegenstände", "Ebene Gegenstände · 3×3-Punkt", "Gegenstand: "),
		("Lichter", "Ebene Lichter · 3×3-Punkt, Wandleuchten innen an der Wand", "Licht: ")],
]
FRONT_SUFFIXES = (" Vorderseite", " Kopfende")


def read_legend(path):
	"""Zeilen „R G B<Tab>Name“ der GIMP-Palette in Dateireihenfolge."""
	legend = []
	for line in open(path, encoding="utf8"):
		parts = line.split(None, 3)
		if len(parts) == 4 and all(p.isdigit() for p in parts[:3]):
			legend.append((parts[3].strip(), tuple(int(p) for p in parts[:3])))
	return legend


def plan_names(path, *names):
	"""Schlüssel der Wörterbücher names aus build_map.py (ohne das Skript auszuführen)."""
	keys = set()
	for node in ast.parse(open(path, encoding="utf8").read()).body:
		if isinstance(node, ast.Assign) and any(getattr(t, "id", "") in names for t in node.targets):
			keys |= set(ast.literal_eval(node.value))
	return keys


def font(size, bold=False):
	for name in (("segoeuib.ttf", "arialbd.ttf") if bold else ("segoeui.ttf", "arial.ttf")):
		try:
			return ImageFont.truetype(name, size)
		except OSError:
			pass
	return ImageFont.load_default(size)


legend = read_legend(SRC)
fills = plan_names(BUILD_MAP, "FILLS", "EMPTY_FILLS")
openings = plan_names(BUILD_MAP, "OPENINGS") | {"Türanschlag"}
color = dict(legend)
fronts = {n for n, _ in legend if n.endswith(FRONT_SUFFIXES) and n.rsplit(" ", 1)[0] in color}


def group_of(name):
	if name in ("Wand", "Glaswand"):
		return "wall"
	if name in openings:
		return "opening"
	if name in fills:
		return "fill"
	return next((p for col in COLUMNS for _, _, p in col if p.endswith(": ") and name.startswith(p)), "")


def entries(key):
	return [n for n, _ in legend if group_of(n) == key and n not in fronts]


unknown = [n for n, _ in legend if not group_of(n) and n not in fronts]
f_title, f_head, f_rule, f_name, f_hex = font(26, True), font(17, True), font(13), font(15), font(13)

# Höhe: längste Spalte (Überschrift + Regel + Einträge je Gruppe, „Sonstige“ in der ersten)
def column_rows(col):
	return sum(2.6 + len(entries(key)) for _, _, key in col)
rows = max(column_rows(col) + (2.6 + len(unknown) if i == 0 and unknown else 0) for i, col in enumerate(COLUMNS))
img = Image.new("RGB", (MARGIN * 2 + COL_W * len(COLUMNS), int(MARGIN * 2 + 60 + rows * ROW)), (255, 255, 255))
draw = ImageDraw.Draw(img)
draw.text((MARGIN, MARGIN), "Gebäudeplan – Farben", font=f_title, fill=TEXT)
draw.text((MARGIN + 300, MARGIN + 10), "aus %s · 1 m = 10 px · Pipette ins Farbfeld" % os.path.basename(SRC),
	font=f_rule, fill=GREY)


def swatch(x, y, rgb, size):
	w, h = size
	draw.rectangle((x - 1, y - 1, x + w, y + h), outline=FRAME)
	draw.rectangle((x, y, x + w - 1, y + h - 1), fill=rgb)


def label(name, prefix):
	return name[len(prefix):] if prefix.endswith(": ") else name


for i, col in enumerate(COLUMNS):
	x, y = MARGIN + i * COL_W, MARGIN + 60
	groups = list(col) + ([("Sonstige", "ohne Gruppe in build_map.py", None)] if i == 0 and unknown else [])
	for title, rule, key in groups:
		draw.text((x, y), title, font=f_head, fill=TEXT)
		draw.text((x, y + ROW), rule, font=f_rule, fill=GREY)
		y += int(ROW * 2.2)
		for name in (entries(key) if key else unknown):
			sy = y + (ROW - SWATCH[1]) // 2
			swatch(x, sy, color[name], SWATCH)
			tx = x + SWATCH[0] + 12
			front = next((name + s for s in FRONT_SUFFIXES if name + s in fronts), None)
			if front:
				swatch(tx, sy, color[front], FRONT_SWATCH)
				tx += FRONT_SWATCH[0] + 10
			text = label(name, key or "")
			draw.text((tx, y + 2), text, font=f_name, fill=TEXT)
			tx += draw.textlength(text, font=f_name) + 10
			note = NOTES.get(name, "")
			if front:
				note = "rechts: " + front.rsplit(" ", 1)[1] + ("; " + note if note else "")
			hexes = "#%02x%02x%02x" % color[name] + (" / #%02x%02x%02x" % color[front] if front else "")
			draw.text((tx, y + 4), hexes + ("  " + note if note else ""), font=f_hex, fill=GREY)
			y += ROW
		y += int(ROW * 0.4)

img.save(DST)
print("%d Farben (%d Vorderseiten) -> %s" % (len(legend), len(fronts), DST))
if unknown:
	print("  Ohne Gruppe (weder Fläche, Öffnung noch Objektvorsatz):", ", ".join(unknown))
