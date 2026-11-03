# Erzeugt aus der Legende des Gebäudeplans PLANFARBEN.md (Spielkonzept 7.5, gemeinsame Arbeitsgrundlage):
#   - map_colors.png: jede Farbe als Farbfeld mit Name, Hex-Wert und Hinweis, nach Gruppen (Wände, Flächen,
#     Öffnungen, Möbel, Teppiche, Ausstattung, Gegenstände, Lichter) in drei Spalten – Vorlage zum Zeichnen, Farbe mit
#     der Pipette aus dem Bild nehmen. Die Farbfelder sind exakt die Legendenfarben.
#   - map_a.gpl: dieselben Farben als GIMP-Palette (in Aseprite ladbar). Nicht von Hand ändern.
# Prüft dabei, ob tools/build_map.py jeden Namen kennt („noch nicht gebaut“) und welche Namen dort noch keine Farbe
# haben. Neue Farbe: Zeile in PLANFARBEN.md ergänzen, dann dieses Skript laufen lassen.
#
# Aufruf (Python 3 mit Pillow):
#   python tools/build_colors.py [PLANFARBEN.md] [map_colors.png] [map_a.gpl]
import ast, os, sys
from PIL import Image, ImageDraw, ImageFont

TOOLS = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, TOOLS)
import plan_legend

SRC = sys.argv[1] if len(sys.argv) > 1 else plan_legend.DEFAULT
DST = sys.argv[2] if len(sys.argv) > 2 else os.path.join(os.path.dirname(SRC), "map_colors.png")
GPL = sys.argv[3] if len(sys.argv) > 3 else os.path.join(os.path.dirname(SRC), "map_a.gpl")
BUILD_MAP = os.path.join(TOOLS, "build_map.py")

ROW = 24                ## Zeilenhöhe in px
SWATCH = (40, 18)       ## Farbfeld
FRONT_SWATCH = (18, 18) ## Farbfeld der Vorderseite neben dem Möbel
COL_W = 600             ## Spaltenbreite
MARGIN = 24
FRAME = (200, 200, 200)
TEXT = (20, 20, 20)
GREY = (120, 120, 120)
UNBUILT = (190, 60, 40)

## Gruppen in Spalten: (Überschrift, Zeichenregel, Schlüssel aus plan_legend.GROUPS)
COLUMNS = [
	[("Wände", "Linien im Grundriss, 2 px", "wall"), ("Flächen", "Füllfarben im Grundriss", "fill"),
		("Öffnungen", "Striche auf der Wandlinie", "opening")],
	[("Möbel", "Ebene Möbel · Rechteck in Grundfläche, hellere Randzeile = Vorderseite", "furniture"),
		("Teppiche", "Ebene Teppiche · Rechteck", "rug")],
	[("Ausstattung", "Ebene Ausstattung · 2×2- oder 3×3-Punkt, Wandsachen innen an der Wand", "fitting"),
		("Gegenstände", "Ebene Gegenstände · 2×2- oder 3×3-Punkt", "item"),
		("Lichter", "Ebene Lichter · 2×2- oder 3×3-Punkt, Wandleuchten innen an der Wand", "light")],
]
## Namen, die build_map.py als Konstante statt in einem Wörterbuch kennt
BUILT_CONSTANTS = ("WALL_NAME", "GLASS_NAME", "HINGE_NAME", "FRONT_NAME", "VACANT_NAME")
BUILT_DICTS = ("FILLS", "EMPTY_FILLS", "OPENINGS", "FURNITURE", "FITTINGS", "ITEMS", "LIGHTS", "RUGS")


def built_names():
	"""Alle Namen, für die build_map.py ein Bauteil kennt (ohne das Skript auszuführen)."""
	keys = set()
	for node in ast.parse(open(BUILD_MAP, encoding="utf8").read()).body:
		if not isinstance(node, ast.Assign):
			continue
		targets = [getattr(t, "id", "") for t in node.targets] + [getattr(e, "id", "") for t in node.targets
			for e in getattr(t, "elts", [])]
		if any(t in BUILT_DICTS for t in targets):
			keys |= set(ast.literal_eval(node.value))
		elif any(t in BUILT_CONSTANTS for t in targets):
			value = ast.literal_eval(node.value)
			keys |= set(value) if isinstance(value, tuple) else {value}
	return keys


def font(size, bold=False):
	for name in (("segoeuib.ttf", "arialbd.ttf") if bold else ("segoeui.ttf", "arial.ttf")):
		try:
			return ImageFont.truetype(name, size)
		except OSError:
			pass
	return ImageFont.load_default(size)


def rgb(hx):
	return tuple(int(hx[i:i + 2], 16) for i in (0, 2, 4))


entries = plan_legend.read(SRC)
built = built_names()
unbuilt = [e["name"] for e in entries if e["name"] not in built]
colorless = sorted(built - {e["name"] for e in entries})

# --- Palette für Aseprite ---------------------------------------------------------------------------
with open(GPL, "w", encoding="utf-8", newline="\n") as f:
	f.write("GIMP Palette\nName: Zimmer 13 – Gebäudeplan (map_a.aseprite)\nColumns: 0\n")
	f.write("# Erzeugt von tools/build_colors.py aus PLANFARBEN.md – nicht von Hand ändern, die Legende steht dort.\n")
	for name, hx in plan_legend.pairs(SRC):
		f.write("%3d %3d %3d\t%s\n" % (rgb(hx) + (name,)))

# --- Bild zum Zeichnen ------------------------------------------------------------------------------
f_title, f_head, f_rule, f_name, f_hex = font(26, True), font(17, True), font(13), font(15), font(13)


def group(key):
	return [e for e in entries if e["group"] == key]


rows = max(sum(2.6 + len(group(key)) for _, _, key in col) for col in COLUMNS)
img = Image.new("RGB", (MARGIN * 2 + COL_W * len(COLUMNS), int(MARGIN * 2 + 60 + rows * ROW)), (255, 255, 255))
draw = ImageDraw.Draw(img)
draw.text((MARGIN, MARGIN), "Gebäudeplan – Farben", font=f_title, fill=TEXT)
draw.text((MARGIN + 300, MARGIN + 10), "aus PLANFARBEN.md · 1 m = 10 px · Pipette ins Farbfeld · rot = noch nicht gebaut",
	font=f_rule, fill=GREY)


def swatch(x, y, color, size):
	w, h = size
	draw.rectangle((x - 1, y - 1, x + w, y + h), outline=FRAME)
	draw.rectangle((x, y, x + w - 1, y + h - 1), fill=color)


def fit(text, fnt, width):
	"""Text auf width px kürzen (mit …)."""
	if draw.textlength(text, font=fnt) <= width:
		return text
	while text and draw.textlength(text + " …", font=fnt) > width:
		text = text[:-1]
	return text.rstrip(" ,;–") + " …"


for i, col in enumerate(COLUMNS):
	x, y = MARGIN + i * COL_W, MARGIN + 60
	for title, rule, key in col:
		draw.text((x, y), title, font=f_head, fill=TEXT)
		draw.text((x, y + ROW), rule, font=f_rule, fill=GREY)
		y += int(ROW * 2.2)
		for e in group(key):
			sy = y + (ROW - SWATCH[1]) // 2
			swatch(x, sy, rgb(e["hex"]), SWATCH)
			tx = x + SWATCH[0] + 12
			if e["front"]:
				swatch(tx, sy, rgb(e["front_hex"]), FRONT_SWATCH)
				tx += FRONT_SWATCH[0] + 10
			draw.text((tx, y + 2), e["short"], font=f_name, fill=UNBUILT if e["name"] in unbuilt else TEXT)
			tx += draw.textlength(e["short"], font=f_name) + 10
			note = e["note"]
			if e["front"]:
				note = "rechts: " + e["front"].rsplit(" ", 1)[1] + ("; " + note if note else "")
			hexes = "#" + e["hex"] + (" / #" + e["front_hex"] if e["front"] else "")
			text = fit(hexes + ("  " + note if note else ""), f_hex, x + COL_W - 16 - tx)
			draw.text((tx, y + 4), text, font=f_hex, fill=GREY)
			y += ROW
		y += int(ROW * 0.4)

img.save(DST)
print("%d Farben (%d Vorderseiten) -> %s, %s" % (len(plan_legend.pairs(SRC)), sum(1 for e in entries if e["front"]),
	DST, GPL))
if unbuilt:
	print("  Noch nicht gebaut (Farbe ohne Bauteil in build_map.py):", ", ".join(unbuilt))
if colorless:
	print("  In build_map.py vorgesehen, noch ohne Farbe:", ", ".join(colorless))
