# Liest den Gebäudeplan map_a.aseprite (Spielkonzept 7.5, 7.10) und schreibt je Stockwerk eine Layout-Datei, aus
# der der LevelBuilder baut: Wände mit Öffnungen, Flächen (Zimmer, Flure, Gärten …), Zimmer mit Nummer, Tür und
# Fenstern, dazu Pflanzkübel, Bäume, Treppen, Aufzüge, Rezeption, Luftraum, Bereiche und Objekte.
#
# Der Plan gehört dem Zeichner – das Skript liest ihn nur (auch die Zimmer werden von Hand eingerichtet).
#
# Aufbau der Plandatei (Vorlage, mit dem Zeichner abgestimmt):
#   - Maßstab 1 m = 10 px. Wände sind 2 px dicke Linien in der Palettenfarbe „Wand“ (20 cm).
#   - Die Stockwerke liegen untereinander auf derselben Ebene, je BAND px hoch (FLAT_FLOORS: oben das Obergeschoss,
#     in der Mitte das Erdgeschoss, unten der Keller) – deckungsgleich, wenn man sie um BAND verschiebt. Gezählt
#     werden alle normalen Ebenen, egal ob sichtbar; nicht gezählt: Referenzebenen und Ebenen, deren Name mit
#     „Beschriftung“, „Skizze“ oder „Notiz“ beginnt. Ältere Pläne (map.aseprite) mit einer Ebenengruppe je
#     Stockwerk („EG“, „OG1“ …, „Keller“) gehen weiterhin.
#   - Die Bedeutung jeder Farbe steht als Name in der **Legende <plan>.gpl** neben der Plandatei (GIMP-Palette,
#     „R G B<Tab>Name“ je Zeile, FILLS/OPENINGS unten). Aseprite 1.3.18 speichert keine Palettennamen; ohne
#     .gpl gelten die Namen aus dem Paletten-Chunk (ältere Dateien). Farben ohne Namen werden gemeldet und
#     übergangen.
#   - Öffnungen sind Farbstriche auf der Wandlinie, Flächen sind Füllfarben.
#   - Türanschlag: ein Pixel „Türanschlag“ statt eines Türpixels an einem Ende des Strichs, in der Wandhälfte
#     der Seite, in die die Tür aufgeht – dort sitzt das Scharnier, dort steht die offene Tür. Ohne Pixel gilt
#     die Regel im LevelBuilder (in Räume, nicht in Flure; Scharnier rechts). Bei Doppeltüren zählt nur die Seite.
#   - Ebene „Zimmer“: deckende Flächen markieren die Hotelzimmer – alles darunter (Zimmerflächen, Bad,
#     Verbindungstüren dazwischen) gehört zu einem Zimmer mit einer Nummer. Ohne die Ebene ist jede Fläche
#     „Zimmer“ ein eigenes Zimmer.
#   - Objektebenen (eigene Legende, Palettennamen mit Vorsatz): „Möbel“ (Grundfläche als Rechteck; die
#     Vorderseite zeigt ein Strich „Möbel: Vorderseite“ am Rand oder – bei den neueren Möbeln – eine Zeile in
#     der helleren Farbe „<Möbel> Vorderseite“, beim Doppelbett „… Kopfende“), „Ausstattung“, „Gegenstände“ und
#     „Lichter“ (je ein 3×3-Punkt, Wandsachen innen an der Wand; Halogenleuchten als Strich in ihrer Länge, 8×2 px),
#     dazu „Teppiche“ (Rechtecke; eigene Ebene, damit sie unter Möbeln liegen können – ein Läufer läuft entlang
#     der langen Seite). Sie zählen nicht zum Grundriss.
#   - Bäume (Fläche „Baum“) markieren nur den Standort, die Größe kommt aus dem Modell.
#   - Slices (Aseprite-Werkzeug „Slice“) tragen Namen: „Raum: Küche“, „Bereich: Lobby“, „Treppe: Lobby“
#     (Pivot = oberes Ende), „Treppenhaus: Ost“, „Objekt: Sofa“ (Pivot = Vorderseite). Sie gelten im Stockwerk,
#     in dem ihre Mitte liegt (bei Ebenengruppen: ohne Vorsatz im EG, sonst „OG1 Raum: Bibliothek“).
#
# Koordinaten der Ausgabe: Meter, x nach Osten, z nach Süden (Norden = −Z wie in Godot), Ursprung = Mitte
# des Haupteingangs auf der Mittellinie der Südwand (aus dem Plan des EG). Rechtecke als [x0, z0, x1, z1].
#
# Aufruf (Python 3, keine Zusatzpakete):
#   python tools/build_map.py [map_a.aseprite] [assets/maps] [vorschau-ordner]
import json, math, os, struct, sys, zlib
from collections import deque

SRC = sys.argv[1] if len(sys.argv) > 1 else "map_a.aseprite"
DST_DIR = sys.argv[2] if len(sys.argv) > 2 else "assets/maps"
PREVIEW_DIR = sys.argv[3] if len(sys.argv) > 3 else ""

PX = 0.1                    ## Meter pro Pixel
BAND = 790                  ## Höhe eines Stockwerks im Plan ohne Ebenengruppen (Versatz zwischen den Stockwerken)
FLAT_FLOORS = ("OG1", "EG", "UG")   ## Stockwerke von oben nach unten
UNITS_LAYER = "Zimmer"      ## Ebene mit den Flächen der Hotelzimmer
MIN_WALL_RUN = 6            ## kürzeste erkannte Wand in Pixeln (kürzere Läufe sind Querschnitte)
MIN_WALL_NET = 300          ## kleinere Flecken in Wandfarbe sind Schrift, keine Wände
IGNORED_LAYERS = ("Beschriftung", "Skizze", "Notiz")
## Objektebenen → Schlüssel in der Ausgabe. Zählen nicht zum Grundriss.
OBJECT_LAYERS = {"Möbel": "furniture", "Ausstattung": "fittings", "Gegenstände": "items", "Lichter": "lights",
	"Teppiche": "rugs"}

## Palettenname → (Flächenart, draußen = ohne Decke)
FILLS = {
	"Zimmer": ("room", False), "Flur": ("corridor", False), "Garten": ("garden", True),
	"Terrasse": ("terrace", True), "Terrassenkante": ("terrace_edge", True), "Baum": ("tree", True),
	"Pflanzkübel": ("planter", False), "Betriebsraum": ("service", False), "Lagerraum": ("storage", False),
	"Bar": ("bar", False), "Partyraum": ("party", False), "Toilette": ("toilet", False),
	"Pool Wasser": ("pool_water", False), "Pool Umgang": ("pool_deck", False), "Aufzug": ("elevator", False),
	"Treppe": ("stairs", False), "Treppenstufe": ("stairs", False), "Rezeption": ("reception", False),
	"Luftraum": ("void", False), "Katzenraum": ("cat_room", False), "Bibliothek": ("library", False),
	"Balkon": ("balcony", True), "Balkongeländer": ("balcony_edge", True), "Bad": ("bath", False),
	# Untergeschoss (20.10.): Gänge, Heizkeller, Technikraum, Wäscherei, leere (verschlossene) Kellerräume
	"Kellerboden": ("cellar", False), "Heizkeller": ("boiler_room", False), "Technikraum": ("plant_room", False),
	"Wäscherei": ("laundry_room", False), "Kellerraum": ("cellar_room", False),
	# Plan map_a (22.10.): Kieswege im Garten, Müllraum im Keller
	"Kiesweg": ("gravel", True), "Müllraum": ("trash_room", False),
}
## Palettenname → Öffnungsart (Strich auf der Wandlinie)
OPENINGS = {
	"Tür Flur": "door", "Tür Terrasse": "garden_door", "Fenster": "window", "Doppel-Glastür": "glass_double_door",
	"Betriebstür": "service_door", "Aufzugtür": "elevator_door", "Haupteingang": "main_entrance",
	"Kniestocktür": "attic_door",
}
## Flächen, die wie unbemalt zählen (kein Boden, nichts gebaut)
EMPTY_FILLS = ("Kellerraum zu",)
WALL_NAME, GLASS_NAME = "Wand", "Glaswand"
HINGE_NAME = "Türanschlag"   ## ein Pixel auf dem Türstrich: Scharnierende und Aufgehseite
## Objektlegende (Palettenname → Art). Möbel und Teppiche sind Rechtecke, alles andere 3×3-Punkte.
FURNITURE = {
	"Möbel: Bett": "bed", "Möbel: Schrank": "wardrobe", "Möbel: Kommode": "dresser", "Möbel: Tisch": "table",
	"Möbel: Couchtisch": "coffee_table", "Möbel: Tafel": "dining_table", "Möbel: Sofa": "couch", "Möbel: Bank": "bench",
	"Möbel: Truhe": "chest", "Möbel: Schachtisch": "chess_table", "Möbel: Spieltisch": "game_table",
	"Möbel: Theke": "bar_counter", "Möbel: Regal": "shelf", "Möbel: Küchenzeile": "kitchen_counter", "Möbel: Herd": "stove",
	"Möbel: Waschtisch": "washbasin", "Möbel: Waschmaschine": "washing_machine", "Möbel: Wäschekiste": "laundry_box",
	"Möbel: Säule": "pillar", "Möbel: Kratzbaum": "cat_tree",
	# Plan map_a (22.10., Legende map_legend.png): Vorderseite als hellere Zeile „<Name> Vorderseite“ (FRONT_SUFFIXES)
	"Möbel: Doppelbett": "double_bed", "Möbel: Badewanne": "bathtub", "Möbel: Waschbecken": "sink",
	"Möbel: Fußmatte": "doormat", "Möbel: Dusche": "shower", "Möbel: WC": "toilet", "Möbel: Mülleimer": "trash_can",
	"Möbel: Snackautomat": "snack_machine", "Möbel: Getränkeautomat": "drink_machine",
	"Möbel: Zimmertisch": "room_table", "Möbel: Stuhl": "chair",
}
FRONT_NAME = "Möbel: Vorderseite"   ## Strich am Rand, gilt für jedes Möbel
## Hellere Zeile am Rand, gilt nur für ihr Möbel: „Möbel: Dusche Vorderseite“ → facing. Beim Doppelbett ist sie das
## Kopfende (→ head statt facing).
FRONT_SUFFIXES = {" Vorderseite": "facing", " Kopfende": "head"}
FITTINGS = {
	"Ausstattung: Lichtschalter": "switch", "Ausstattung: Telefon": "phone", "Ausstattung: Bild": "painting",
	"Ausstattung: Zettel": "note", "Ausstattung: UV-Schrift": "uv_writing", "Ausstattung: Spinnweben": "cobweb",
	"Ausstattung: Kerzenvorrat": "candle_supply", "Ausstattung: Ersatzbirnen": "bulb_supply",
	"Ausstattung: Laubhaufen": "leaf_pile", "Ausstattung: Kürbispflanze": "pumpkin_plant",
	# Kürbissorten (Spielkonzept 5.8, PumpkinKinds) – ohne Sorte: Halloween-Kürbis
	"Ausstattung: Kürbispflanze Hokkaido": "pumpkin_plant:hokkaido", "Ausstattung: Kürbispflanze Weiß": "pumpkin_plant:casper",
	"Ausstattung: Kürbispflanze Butternut": "pumpkin_plant:butternut", "Ausstattung: Kürbispflanze Muskat": "pumpkin_plant:muskat",
	"Ausstattung: Kürbispflanze Türkenturban": "pumpkin_plant:turban", "Ausstattung: Kürbispflanze Riese": "pumpkin_plant:giant",
	"Ausstattung: Kalender": "calendar", "Ausstattung: Tagebuch": "diary", "Ausstattung: Dekokiste": "deco_box",
}
## Teppiche → Art (LevelBuilder.RUG_TEXTURES)
RUGS = {"Teppich: Läufer": "runner"}
## Gegenstände → Item.Kind
ITEMS = {
	"Gegenstand: Kürbis": "PUMPKIN", "Gegenstand: Geschnitzter Kürbis": "CARVED_PUMPKIN", "Gegenstand: Kerze": "CANDLE",
	"Gegenstand: Schlüssel": "KEY", "Gegenstand: Spinnweben": "COBWEB", "Gegenstand: Laub": "LEAVES",
	"Gegenstand: Münzen": "COINS", "Gegenstand: Messer": "KNIFE", "Gegenstand: Würfelbecher": "DICE_CUP",
	"Gegenstand: Gezinkte Würfel": "LOADED_DICE", "Gegenstand: Glühbirne": "BULB", "Gegenstand: Kleidung": "CLOTHING",
	"Gegenstand: Kompass": "COMPASS", "Gegenstand: Karte": "MAP", "Gegenstand: Taschenlampe": "FLASHLIGHT",
	"Gegenstand: Batterie": "BATTERY", "Gegenstand: UV-Filter": "UV_FILTER", "Gegenstand: Schachbrett": "CHESS_BOARD",
}
## Lichter → (Art, defekt)
LIGHTS = {
	"Licht: Wandleuchte": ("wall_lamp", False), "Licht: Wandleuchte defekt": ("wall_lamp", True),
	"Licht: Kerze": ("candle", False), "Licht: Laterne": ("lantern", False), "Licht: Laterne defekt": ("lantern", True),
	"Licht: Deckenleuchte": ("ceiling_lamp", False), "Licht: Halogenleuchte": ("halogen", False),
}
## Einbauten, die keine eigenen Bodenflächen sind
FIXTURES = ("tree", "planter", "reception", "terrace_edge", "balcony_edge", "stairs", "void")

## Zimmernummern (Spielkonzept 7.5): je Flügel ein Laufweg ab der Lobby um den Rundflur (Mittellinien in px des
## Stockwerks), optional danach ein Querflur (cross = (y, x-Anfang, Richtung), cross_end = Ende). Rechte Hand ungerade,
## linke gerade. Ost = x1xx, West = x2xx; die erste Ziffer ist das Stockwerk (EG 0, OG1 1 …). Darüber gilt die Nummer
## des EG-Zimmers unter der Flurtür mit dem Stockwerk vorne (number_from_eg); die Laufwege dienen dort nur noch den
## Flurabschnitten (der Grundriss der Flure ist oben derselbe).
## legs: Name je Teilstück des Laufwegs (wird zu einem Flurabschnitt mit eigenem Lichtschalter).
WINGS = {
	"EG": {
		"ost": dict(base=100, path=[(850, 690), (1450, 690), (1450, 250), (1010, 250), (1010, 690)],
			legs=["Südflur", "Ostflur", "Nordflur", "Gartenflur"]),
		"west": dict(base=200, path=[(700, 690), (100, 690), (100, 250), (540, 250), (540, 690)],
			legs=["Südflur", "Westflur", "Nordflur", "Gartenflur"]),
	},
}
## Zimmer mit fester Nummer, wo der Plan sie beschriftet: Nummer → Pixel im Zimmer. Der Laufweg überspringt sie.
PINNED = {"EG": {"0113": (1120, 640)}}   # Zimmer 13 des Spielers
WING_NAMES = {"ost": "Ostflügel", "west": "Westflügel"}
## Türschilder, die nicht die Nummer zeigen: 0113 ist das Spielerzimmer, das Schild ist abgebrochen
BROKEN_SIGNS = {"0113": "13"}


# --- Aseprite lesen --------------------------------------------------------------------------------

def read_aseprite(path):
	"""Erstes Frame einer RGBA-Datei: Ebenen (mit Gruppenstufe und Bild), Palette mit Namen, Slices, Größe."""
	data = open(path, "rb").read()
	_, magic, _, w, h, depth = struct.unpack_from("<IHHHHH", data, 0)
	assert magic == 0xA5E0, "keine Aseprite-Datei"
	assert depth == 32, "nur RGBA-Dateien werden unterstützt"
	_, _, old, _, _, new = struct.unpack_from("<IHHH2sI", data, 128)
	layers, palette, slices = [], [], []
	p = 144
	for _ in range(new or old):
		size, ctype = struct.unpack_from("<IH", data, p)
		cd = p + 6
		if ctype == 0x2004:
			flags, ltype, level = struct.unpack_from("<HHH", data, cd)
			n = struct.unpack_from("<H", data, cd + 16)[0]
			layers.append({"name": data[cd + 18:cd + 18 + n].decode(), "flags": flags, "type": ltype,
				"level": level, "cel": None})
		elif ctype == 0x2005:
			li, x, y, _, ctyp = struct.unpack_from("<HhhBH", data, cd)
			if ctyp in (0, 2):
				cw, ch = struct.unpack_from("<HH", data, cd + 16)
				raw = data[cd + 20:p + size]
				layers[li]["cel"] = (x, y, cw, ch, raw if ctyp == 0 else zlib.decompress(raw))
		elif ctype == 0x2019:
			first, last = struct.unpack_from("<II", data, cd + 4)
			q = cd + 20
			for _ in range(first, last + 1):
				flags, r, g, b, _ = struct.unpack_from("<HBBBB", data, q)
				q += 6
				name = ""
				if flags & 1:
					n = struct.unpack_from("<H", data, q)[0]
					name = data[q + 2:q + 2 + n].decode()
					q += 2 + n
				palette.append((name.strip(), "%02x%02x%02x" % (r, g, b)))
		elif ctype == 0x2022:
			keys, flags = struct.unpack_from("<II", data, cd)
			n = struct.unpack_from("<H", data, cd + 12)[0]
			name = data[cd + 14:cd + 14 + n].decode()
			q = cd + 14 + n
			_, x, y, sw, sh = struct.unpack_from("<IiiII", data, q)
			q += 20 + (16 if flags & 1 else 0)
			pivot = struct.unpack_from("<ii", data, q) if flags & 2 else None
			slices.append({"name": name.strip(), "x": x, "y": y, "w": sw, "h": sh, "pivot": pivot})
		p += size
	slices.sort(key=lambda sl: sl["name"])   # Aseprite ändert ihre Reihenfolge beim Speichern
	return w, h, layers, palette, slices


def read_legend(path):
	"""Legende als GIMP-Palette: [(Name, Hex)] in Dateireihenfolge."""
	legend = []
	for line in open(path, encoding="utf-8"):
		parts = line.split(None, 3)
		if len(parts) == 4 and all(x.isdigit() for x in parts[:3]):
			legend.append((parts[3].strip(), "%02x%02x%02x" % tuple(int(x) for x in parts[:3])))
	return legend


W, H, LAYERS, PALETTE, SLICES = read_aseprite(SRC)
## Ohne Ebenengruppen liegen die Stockwerke untereinander (FLAT_FLOORS); jedes wird ein eigenes Bild der Höhe BAND
FLAT = not any(l["level"] == 0 and l["type"] == 1 for l in LAYERS)
if FLAT:
	H = BAND
LEGEND = os.path.splitext(SRC)[0] + ".gpl"
if os.path.exists(LEGEND):
	PALETTE = read_legend(LEGEND)
assert any(n for n, _ in PALETTE), "Keine Farbnamen – Legende %s fehlt (siehe Kopf dieses Skripts)" % LEGEND
BY_NAME = {n: c for n, c in PALETTE if n}
WALL = BY_NAME[WALL_NAME]
GLASS = BY_NAME.get(GLASS_NAME, "-")
FILL_OF = {BY_NAME[n]: k for n, k in FILLS.items() if n in BY_NAME}          # Farbe → (Art, draußen)
OPENING_OF = {BY_NAME[n]: k for n, k in OPENINGS.items() if n in BY_NAME}    # Farbe → Öffnungsart
DOOR = BY_NAME["Tür Flur"]
HINGE = BY_NAME.get(HINGE_NAME, "-")
EMPTY = {BY_NAME[n] for n in EMPTY_FILLS if n in BY_NAME}                     # Farben, die wie unbemalt zählen
KNOWN = set(FILL_OF) | set(OPENING_OF) | {WALL, GLASS}

def floor_level(name):
	if name == "EG":
		return 0
	if name.startswith("OG") and name[2:].isdigit():
		return int(name[2:])
	if name in ("Keller", "UG"):
		return -1
	return None

OBJECT_IMAGES = {}   # Stockwerk → Objektebene → {Pixelindex: Farbe}
UNIT_IMAGES = {}     # Stockwerk → {Pixelindex: Farbe} der Ebene „Zimmer“

def paint(layer, img, dy=0):
	"""Deckende Pixel einer Ebene in img eintragen (Liste oder dict, Index = y·W + x), dy Pixel nach oben versetzt."""
	x, y, cw, ch, px = layer["cel"]
	for yy in range(ch):
		Y = y + yy - dy
		if not 0 <= Y < H:
			continue
		for xx in range(cw):
			X = x + xx
			s = (yy * cw + xx) * 4
			if 0 <= X < W and px[s + 3] > 127:
				c = px[s:s + 3].hex()
				img[Y * W + X] = "" if c in EMPTY else c
	return img


def floor_images():
	"""Stockwerksname → Farbliste (Hex, „“ = leer), zusammengesetzt aus den gezählten Ebenen des Stockwerks."""
	floors, group = {}, None
	def add(layer, floor, dy=0):
		if layer["name"] in OBJECT_LAYERS:
			OBJECT_IMAGES.setdefault(floor, {})[layer["name"]] = paint(layer, {}, dy)
		elif layer["name"] == UNITS_LAYER:
			UNIT_IMAGES[floor] = paint(layer, {}, dy)
		else:
			paint(layer, floors[floor], dy)
	if FLAT:
		for floor in FLAT_FLOORS:
			floors[floor] = [""] * (W * H)
	for layer in LAYERS:
		if not FLAT and layer["level"] == 0:
			group = layer["name"] if layer["type"] == 1 else None
			if group:
				assert floor_level(group) is not None, "Unbekannte Stockwerksgruppe „%s“ (EG, OG1 …, Keller)" % group
				floors[group] = [""] * (W * H)
			continue
		if not (FLAT or group) or layer["type"] != 0 or layer["flags"] & 64 or layer["cel"] is None:
			continue
		if layer["name"].startswith(IGNORED_LAYERS):
			continue
		if FLAT:
			for n, floor in enumerate(FLAT_FLOORS):
				add(layer, floor, n * BAND)
		else:
			add(layer, group)
	assert floors, "Keine Stockwerksgruppen gefunden (Ebenengruppen „EG“, „OG1“ …)"
	return floors


def entrance_origin(COL):
	"""Ursprung in Pixeln: Mitte des Haupteingangs auf der Mittellinie seiner Wand (Plan des EG)."""
	c = BY_NAME["Haupteingang"]
	pts = [i for i, v in enumerate(COL) if v == c]
	assert pts, "EG: kein Haupteingang im Plan – er legt den Ursprung fest"
	xs, ys = [i % W for i in pts], [i // W for i in pts]
	mid = lambda v: (min(v) + max(v) + 1) / 2   # Pixelkanten
	return tuple(int(c) if c == int(c) else c for c in (mid(xs), mid(ys)))


def slices_of(floor):
	"""Slices dieses Stockwerks als (Art, Name, Slice): ohne Ebenengruppen nach der Lage ihrer Mitte (y dann im
	Stockwerk), sonst wählt der Vorsatz „OG1 “ usw. das Stockwerk."""
	out = []
	for s in SLICES:
		name = s["name"]
		if FLAT:
			n = int((s["y"] + s["h"] / 2) // BAND)
			if n >= len(FLAT_FLOORS) or FLAT_FLOORS[n] != floor:
				continue
			s = dict(s, y=s["y"] - n * BAND)
		else:
			head = name.split(" ", 1)
			target = "EG"
			if len(head) == 2 and floor_level(head[0]) is not None:
				target, name = head
			if target != floor:
				continue
		if ":" not in name:
			print("  Warnung: Slice „%s“ ohne Art (z. B. „Raum: …“) – übergangen" % s["name"])
			continue
		kind, label = (t.strip() for t in name.split(":", 1))
		out.append((kind, label, s))
	return out


def slug(text):
	t = text.lower()
	for a, b in (("ä", "ae"), ("ö", "oe"), ("ü", "ue"), ("ß", "ss")):
		t = t.replace(a, b)
	return "_".join("".join(c if c.isalnum() else " " for c in t).split())


def m(px, py):
	"""Pixelkante → Meter (gerundet auf cm)."""
	return [round((px - ORIGIN[0]) * PX, 2), round((py - ORIGIN[1]) * PX, 2)]


def pivot_side(s):
	"""Pivot eines Slices → Himmelsrichtung der Kante, an der er liegt (oder None)."""
	if not s["pivot"]:
		return None
	px, py = s["pivot"]
	d = {"north": py, "south": s["h"] - py, "west": px, "east": s["w"] - px}
	return min(d, key=d.get)


# --- Ein Stockwerk ---------------------------------------------------------------------------------

def build_floor(floor, COL, open_above, eg=None):
	"""Layout eines Stockwerks. eg = Layout des Erdgeschosses (für obere Stockwerke: Zimmernummern, Treppenhäuser)."""
	level = floor_level(floor)

	def col(x, y):
		return COL[y * W + x] if 0 <= x < W and 0 <= y < H else ""

	def components(pred, conn8=False):
		seen = bytearray(W * H)
		out = []
		steps = ((1, 0), (-1, 0), (0, 1), (0, -1)) + (((1, 1), (1, -1), (-1, 1), (-1, -1)) if conn8 else ())
		for i in range(W * H):
			if seen[i] or not COL[i] or not pred(COL[i]):
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
						if not seen[k] and COL[k] and pred(COL[k]):
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

	# Türanschläge merken; das Pixel zählt danach als Teil seiner Tür
	hinges = {}
	for i, c in enumerate(COL):
		if c == HINGE:
			x, y = i % W, i // W
			near = [col(X, Y) for X, Y in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1))]
			door = next((n for n in near if OPENING_OF.get(n, "window") != "window"), None)
			assert door, "%s: Türanschlag bei Pixel %d,%d liegt an keiner Tür" % (floor, x, y)
			COL[i] = door
			hinges[(x, y)] = False   # → True, sobald einer Öffnung zugeordnet

	# Unbekannte Farben melden
	unknown = {}
	for i, c in enumerate(COL):
		if c and c not in KNOWN:
			unknown.setdefault(c, i)
	front = BY_NAME.get(FRONT_NAME)
	for c, i in unknown.items():
		hint = " (gehört auf die Ebene „Möbel“ – für Türen gibt es „%s“)" % HINGE_NAME if c == front else ""
		print("  Warnung: Farbe #%s (z. B. bei Pixel %d,%d) steht nicht in der Palette – übergangen%s" % (c, i % W, i // W, hint))

	# --- Wände ---
	wallish = lambda c: c == WALL or c in OPENING_OF or c == GLASS
	WALLMASK = bytearray(W * H)
	for comp in components(wallish, conn8=True):
		if len(comp) >= MIN_WALL_NET:
			for j in comp:
				WALLMASK[j] = 1
	if not any(WALLMASK):
		return None

	def bands(mask, horizontal):
		"""Wandbänder: Läufe ≥ MIN_WALL_RUN in Zeilen (waagerecht) bzw. Spalten, benachbarte zusammengefasst."""
		n_outer, n_inner = (H, W) if horizontal else (W, H)
		idx = (lambda o, i: o * W + i) if horizontal else (lambda o, i: i * W + o)
		open_bands, result = {}, []
		for o in range(n_outer):
			runs = []
			i = 0
			while i < n_inner:
				if mask[idx(o, i)]:
					s = i
					while i < n_inner and mask[idx(o, i)]:
						i += 1
					if i - s >= MIN_WALL_RUN:
						runs.append((s, i))
				else:
					i += 1
			nxt = {}
			for s, e in runs:
				hit = None
				for (bs, be) in open_bands:
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
		return [b for b in result if b["o1"] - b["o0"] <= 3]

	h_bands = bands(WALLMASK, True)
	# Senkrechte Wände enden bündig an waagerechten (keine doppelten Flächen an Ecken)
	vmask = WALLMASK[:]
	for b in h_bands:
		for y in range(b["o0"], b["o1"]):
			for x in range(b["s"], b["e"]):
				vmask[y * W + x] = 0
	v_bands = bands(vmask, False)

	def openings_along(b, horizontal):
		out, glass = [], 0
		at = (lambda i, y: col(i, y)) if horizontal else (lambda i, y: col(y, i))
		i = b["s"]
		while i < b["e"]:
			cs = [at(i, y) for y in range(b["o0"], b["o1"])]
			c = next((c for c in cs if c in OPENING_OF), None)
			if GLASS in cs:
				glass += 1
			if c:
				s = i
				while i < b["e"] and c in [at(i, y) for y in range(b["o0"], b["o1"])]:
					i += 1
				op = {"kind": OPENING_OF[c], "at": round((s - b["s"]) * PX, 2), "width": round((i - s) * PX, 2)}
				for (x, y) in hinges:
					a, o = (x, y) if horizontal else (y, x)
					if not (s <= a < i and b["o0"] <= o < b["o1"]):
						continue
					where = "%s: Türanschlag bei Pixel %d,%d" % (floor, x, y)
					assert "opens" not in op, where + ": zweiter Anschlag an derselben Tür"
					assert a in (s, i - 1), where + ": liegt nicht an einem Ende der Tür"
					assert o in (b["o0"], b["o1"] - 1) and b["o1"] - b["o0"] > 1, where + ": liegt nicht in einer Wandhälfte"
					op["hinge"] = "start" if a == s else "end"     # start = West- bzw. Nordende
					op["opens"] = -1 if o == b["o0"] else 1         # +1 = nach Süden bzw. Osten
					hinges[(x, y)] = True
				out.append(op)
			else:
				i += 1
		return out, glass / max(1, b["e"] - b["s"])

	walls = []
	for horizontal, bs in ((True, h_bands), (False, v_bands)):
		for b in bs:
			mid = (b["o0"] + b["o1"]) / 2
			ops, glass = openings_along(b, horizontal)
			wall = {"a": m(b["s"], mid) if horizontal else m(mid, b["s"]),
				"b": m(b["e"], mid) if horizontal else m(mid, b["e"]),
				"thickness": round((b["o1"] - b["o0"]) * PX, 2)}
			if glass > 0.3:
				wall["glass"] = True
			if ops:
				wall["openings"] = ops
			walls.append(wall)
	walls.sort(key=lambda w: (w["a"][1], w["a"][0], w["b"][1], w["b"][0]))
	for (x, y), used in hinges.items():
		assert used, "%s: Türanschlag bei Pixel %d,%d gehört zu keiner Tür auf einer Wandlinie" % (floor, x, y)

	# --- Flächen ---
	# Schrift in Wandfarbe (kleine Flecken) bekommt die Farbe ihrer Umgebung
	hole = lambda i: COL[i] in (WALL, BY_NAME.get("Haupteingang")) and not WALLMASK[i]
	q = deque(i for i in range(W * H) if COL[i] in FILL_OF)
	while q:
		i = q.popleft()
		x, y = i % W, i // W
		for X, Y in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
			k = Y * W + X
			if 0 <= X < W and 0 <= Y < H and hole(k):
				COL[k] = COL[i]
				q.append(k)

	regions, comps_of = [], {}
	kinds = {}
	for c, (kind, _) in FILL_OF.items():
		kinds.setdefault(kind, []).append(c)
	counter = {}
	for kind, cs in kinds.items():
		for comp in components(lambda c, cs=cs: c in cs):
			if len(comp) < 30:
				continue   # Reste von Schrift
			counter[kind] = counter.get(kind, 0) + 1
			region = {"id": "%s_%d" % (kind, counter[kind]), "kind": kind, "outdoor": FILL_OF[cs[0]][1],
				"rects": rects(comp)}
			comps_of[id(region)] = (comp, bbox(comp))
			regions.append(region)
	corridors = [r for r in regions if r["kind"] == "corridor"]
	if len(corridors) == 1:
		corridors[0]["id"] = "flure"

	# Hotelzimmer aus der Ebene „Zimmer“: alle Zimmerflächen unter einer zusammenhängenden Markierung werden
	# eine Fläche (ein Zimmer mit einer Nummer); Türen zwischen ihnen sind Innentüren
	unit_of = {}
	marks = UNIT_IMAGES.get(floor, {})
	for start in marks:
		if start in unit_of:
			continue
		unit_of[start] = start
		q = deque([start])
		while q:
			j = q.popleft()
			for k in (j + 1, j - 1, j + W, j - W):
				if k in marks and k not in unit_of and abs(k % W - j % W) <= 1:
					unit_of[k] = start
					q.append(k)
	units = {}
	for r in [r for r in regions if r["kind"] == "room"]:
		comp, _ = comps_of[id(r)]
		votes = {}
		for j in comp:
			if j in unit_of:
				votes[unit_of[j]] = votes.get(unit_of[j], 0) + 1
		if not votes:
			if marks:
				print("  Warnung: %s – Fläche „Zimmer“ bei %s liegt auf keiner Markierung der Ebene „%s“" % (floor,
					r["rects"][0][:2], UNITS_LAYER))
			continue
		units.setdefault(max(votes, key=votes.get), []).append(r)
	for parts in units.values():
		first = parts[0]
		comp = [j for r in parts for j in comps_of[id(r)][0]]
		for r in parts[1:]:
			regions.remove(r)
		first["rects"] = rects(comp)
		comps_of[id(first)] = (comp, bbox(comp))

	def region_for(s, kinds=None):
		"""Fläche mit den meisten Pixeln im Slice-Rechteck."""
		best, best_n = None, 0
		x0, y0, x1, y1 = s["x"], s["y"], s["x"] + s["w"], s["y"] + s["h"]
		for r in regions:
			if kinds and r["kind"] not in kinds:
				continue
			comp, (bx0, by0, bx1, by1) = comps_of[id(r)]
			if bx1 <= x0 or bx0 >= x1 or by1 <= y0 or by0 >= y1:
				continue
			n = sum(1 for j in comp if x0 <= j % W < x1 and y0 <= j // W < y1)
			if n > best_n:
				best, best_n = r, n
		return best

	def slice_rect(s):
		return m(s["x"], s["y"]) + m(s["x"] + s["w"], s["y"] + s["h"])

	areas, objects, stairs = [], [], []
	for kind, label, s in slices_of(floor):
		if kind == "Raum":
			r = region_for(s, [k for k, _ in FILLS.values() if k not in FIXTURES])
			if r is None:
				print("  Warnung: Slice „Raum: %s“ liegt auf keiner Fläche" % label)
				continue
			r["id"], r["name"] = slug(label), label
		elif kind == "Bereich":
			# auf die überdeckte Fläche zusammenziehen (Slices dürfen großzügig gezogen sein)
			rect = slice_rect(s)
			r = region_for(s)
			if r:
				comp, _ = comps_of[id(r)]
				inside = [j for j in comp if s["x"] <= j % W < s["x"] + s["w"] and s["y"] <= j // W < s["y"] + s["h"]]
				x0, y0, x1, y1 = bbox(inside)
				rect = m(x0, y0) + m(x1, y1)
			areas.append({"id": slug(label), "name": label, "rect": rect})
		elif kind == "Objekt":
			objects.append({"name": label, "rect": slice_rect(s), "facing": pivot_side(s)})
		elif kind in ("Treppe", "Treppenhaus"):
			r = region_for(s, ["stairs"])
			rect = slice_rect(s)
			if r:
				r["claimed"] = True
				_, (bx0, by0, bx1, by1) = comps_of[id(r)]
				rect = m(bx0, by0) + m(bx1, by1)
			stair = {"id": slug(("treppenhaus " if kind == "Treppenhaus" else "treppe ") + label), "name": label,
				"kind": "stairwell" if kind == "Treppenhaus" else "stair", "rect": rect}
			if r and kind == "Treppenhaus":
				r["shaft"] = True   # eigener Schacht, bekommt keinen Bodenflicken
			if kind == "Treppe":
				stair["up"] = pivot_side(s)
				if not stair["up"]:
					print("  Warnung: „Treppe: %s“ ohne Pivot – Richtung nach oben unbekannt" % label)
			stairs.append(stair)
		else:
			print("  Warnung: unbekannte Slice-Art „%s“ (Raum, Bereich, Treppe, Treppenhaus, Objekt)" % kind)
	# Andere Stockwerke: Treppenflächen über (oder unter) einem Treppenhaus des EG gehören zu dessen Schacht (gleiche
	# ID, keine eigenen Slices nötig)
	for es in (eg or {}).get("stairs", []) if level != 0 else []:
		if es["kind"] != "stairwell":
			continue
		ex0, ez0, ex1, ez1 = es["rect"]
		for r in regions:
			if r["kind"] != "stairs" or r.get("claimed"):
				continue
			_, (bx0, by0, bx1, by1) = comps_of[id(r)]
			rx0, rz0 = m(bx0, by0)
			rx1, rz1 = m(bx1, by1)
			if min(rx1, ex1) - max(rx0, ex0) > 0.5 and min(rz1, ez1) - max(rz0, ez0) > 0.5:
				r["claimed"] = r["shaft"] = True
				stairs.append({"id": es["id"], "name": es["name"], "kind": "stairwell", "rect": [rx0, rz0, rx1, rz1]})
	for r in regions:
		if r["kind"] == "stairs" and not r.pop("claimed", False):
			print("  Warnung: Treppe bei %s ohne Slice „Treppe: …“ oder „Treppenhaus: …“" % r["rects"][0][:2])

	# Bodenflicken: Einbauten (Kübel, Bäume, Rezeption, freie Treppen) sind Löcher in ihrer Fläche – der Boden
	# darunter bekommt die Art der umgebenden Fläche
	patches = []
	for r in regions:
		if r["kind"] not in ("tree", "planter", "reception", "stairs") or r.pop("shaft", False):
			continue
		comp, _ = comps_of[id(r)]
		ps = set(comp)
		around = {}
		for j in comp:
			x, y = j % W, j // W
			for k in ((y * W + x + 1), (y * W + x - 1), ((y + 1) * W + x), ((y - 1) * W + x)):
				c = COL[k] if 0 <= k < W * H else ""
				if k not in ps and c in FILL_OF and FILL_OF[c][0] not in FIXTURES:
					around[c] = around.get(c, 0) + 1
		if around:
			c = max(around, key=around.get)
			patches.append({"kind": FILL_OF[c][0], "outdoor": FILL_OF[c][1], "under": r["kind"], "rects": r["rects"]})

	# Treppenhaustür: eine Tür (Flur-, Glas-, Betriebstür …) an einer Kante; Stufen: Rechteck der Treppenstufen
	STEP = BY_NAME.get("Treppenstufe", "-")
	for s in stairs:
		if s["kind"] != "stairwell":
			continue
		x0, z0, x1, z1 = [round(v / PX) for v in s["rect"]]
		x0, x1, z0, z1 = x0 + ORIGIN[0], x1 + ORIGIN[0], z0 + ORIGIN[1], z1 + ORIGIN[1]
		edge = {"south": [(x, z1 + 1) for x in range(x0, x1)], "north": [(x, z0 - 2) for x in range(x0, x1)],
			"west": [(x0 - 2, y) for y in range(z0, z1)], "east": [(x1 + 1, y) for y in range(z0, z1)]}
		for side, pts in edge.items():
			hits = [p for p in pts if OPENING_OF.get(col(*p), "window") != "window"]
			if hits:
				s["door"] = {"pos": m(sum(p[0] for p in hits) / len(hits) + 0.5, sum(p[1] for p in hits) / len(hits) + 0.5),
					"side": side}
		steps = [(x, y) for x in range(x0, x1) for y in range(z0, z1) if col(x, y) == STEP]
		if steps:
			s["steps"] = m(min(p[0] for p in steps), min(p[1] for p in steps)) + m(max(p[0] for p in steps) + 1, max(p[1] for p in steps) + 1)

	# --- Zimmer: Tür, Fenster, Nummer ---
	def touching(comp, colour, reach=3):
		found, ps = set(), set(comp)
		for j in comp:
			x, y = j % W, j // W
			for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
				if (y + dy) * W + x + dx in ps:
					continue
				for k in range(1, reach + 1):
					if col(x + dx * k, y + dy * k) == colour:
						found.add((x + dx * k, y + dy * k))
		return found

	def strokes(pixels):
		left, out = set(pixels), []
		while left:
			p = left.pop()
			st, g = [p], [p]
			while st:
				a, b = st.pop()
				for nb in ((a + 1, b), (a - 1, b), (a, b + 1), (a, b - 1)):
					if nb in left:
						left.remove(nb)
						st.append(nb)
						g.append(nb)
			xs = [v[0] for v in g]
			ys = [v[1] for v in g]
			horizontal = max(xs) - min(xs) >= max(ys) - min(ys)
			out.append(((min(xs) + max(xs) + 1) / 2, (min(ys) + max(ys) + 1) / 2, max(max(xs) - min(xs), max(ys) - min(ys)) + 1,
				horizontal))
		return out

	def door_to(gx, gy):
		"""Wohin führt ein Türstrich (Mitte)? „bath“ ins Bad, „inner“ in einen Raum desselben Hotelzimmers (Ebene
		„Zimmer“), „room“ ins Nachbarzimmer (Verbindungstür), sonst „corridor“ (Flur, Lobby …). Gelesen wird
		beiderseits der Wand."""
		x, y = int(gx), int(gy)
		pts = [(x + dx * k, y + dy * k) for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)) for k in (2, 3)]
		sides = [FILL_OF.get(col(*p), ("", False))[0] for p in pts]
		if "bath" in sides:
			return "bath"
		if sides.count("room") < 4:
			return "corridor"
		owners = {unit_of.get(p[1] * W + p[0]) for p, kind in zip(pts, sides) if kind == "room"}
		return "inner" if len(owners) == 1 and None not in owners else "room"

	def opening_info(comp, name, cx, cy, to=None):
		"""Öffnungen der Farbe name am Rand von comp: Mitte, Normale (aus dem Raum hinaus) und Breite."""
		out = []
		if name not in BY_NAME:
			return out
		inside = set(comp)
		for gx, gy, width, horizontal in strokes(touching(comp, BY_NAME[name])):
			if to is not None and door_to(gx, gy) != to:
				continue
			# Normale: auf welcher Seite der Wand liegt der Raum? (bei L-förmigen Zimmern trügt die Mitte)
			x, y = int(gx), int(gy)
			a, b = ((x, y - 3), (x, y + 3)) if horizontal else ((x - 3, y), (x + 3, y))
			in_a, in_b = (p[1] * W + p[0] in inside for p in (a, b))
			if in_a != in_b:
				normal = ([0, 1] if in_a else [0, -1]) if horizontal else ([1, 0] if in_a else [-1, 0])
			else:
				vx, vy = gx - cx, gy - cy
				normal = [1 if vx > 0 else -1, 0] if abs(vx) > abs(vy) else [0, 1 if vy > 0 else -1]
			out.append({"pos": m(gx, gy), "normal": normal, "width": round(width * PX, 2)})
		return out

	rooms = []
	for r in regions:
		if r["kind"] != "room":
			continue
		comp, _ = comps_of[id(r)]
		xs = [j % W for j in comp]
		ys = [j // W for j in comp]
		cx, cy = sum(xs) / len(xs), sum(ys) / len(ys)
		doors = opening_info(comp, "Tür Flur", cx, cy, to="corridor")
		connecting = opening_info(comp, "Tür Flur", cx, cy, to="room")
		suite = False
		if level > 0 and not doors and connecting:
			doors, suite = connecting[:1], True   # Suite: nur über das Nachbarzimmer erreichbar (Spielkonzept 7.7)
		elif not doors:
			print("  Hinweis: %s – Fläche „Zimmer“ bei %s (Pixel %d,%d) hat keine Tür, bleibt geschlossen" % (floor,
				m(cx, cy), cx, cy))
			continue
		rooms.append({"region": r, "cx": cx, "cy": cy, "door": doors[0], "side_doors": doors[1:], "suite": suite,
			"bath_doors": opening_info(comp, "Tür Flur", cx, cy, to="bath"),
			"connecting_doors": connecting,
			"windows": opening_info(comp, "Fenster", cx, cy), "garden_doors": opening_info(comp, "Tür Terrasse", cx, cy)})

	def number_from_eg(r):
		"""Obere Stockwerke (Spielkonzept 7.5): Nummer des EG-Zimmers darunter mit dem Stockwerk vorne – gemessen
		1 m hinter der Flurtür, sonst das EG-Zimmer mit der größten Überdeckung."""
		(px, pz), (nx, nz) = r["door"]["pos"], r["door"]["normal"]
		px, pz = px - nx * 1.0, pz - nz * 1.0
		def area(a, b):
			return max(0, min(a[2], b[2]) - max(a[0], b[0])) * max(0, min(a[3], b[3]) - max(a[1], b[1]))
		below = next((e for e in eg["rooms"] if any(rc[0] <= px <= rc[2] and rc[1] <= pz <= rc[3] for rc in e["rects"])), None)
		r["by_door"] = below is not None
		if below is None:
			best = max(eg["rooms"], key=lambda e: sum(area(a, b) for a in e["rects"] for b in r["region"]["rects"]))
			if sum(area(a, b) for a in best["rects"] for b in r["region"]["rects"]) > 0:
				below = best
		if below:
			r["no"], r["wing"] = "%d%s" % (level, below["no"][1:]), below["wing"]

	for r in rooms if level > 0 and eg else []:
		number_from_eg(r)
	# Liegen zwei Zimmer über demselben EG-Zimmer, behält es das mit der Flurtür darüber (sonst das erste)
	keep = set()
	for r in sorted((r for r in rooms if "no" in r), key=lambda r: not r["by_door"]):
		if r["no"] in keep:
			del r["no"]
		keep.add(r.get("no"))
	# Die übrigen (über keinem EG-Zimmer oder verdrängt) zählen im Flügel hinter dessen höchster Nummer weiter,
	# Norden vor Süden, Westen vor Osten
	for r in sorted((r for r in rooms if level > 0 and eg and "no" not in r), key=lambda r: (r["cy"], r["cx"])):
		r["wing"] = "west" if r["cx"] < WING_SPLIT_X else "ost"
		used = [int(o["no"][1:]) for o in rooms if "no" in o and o["wing"] == r["wing"]] + \
			[int(e["no"][1:]) for e in eg["rooms"] if e["wing"] == r["wing"]]
		r["no"] = "%d%03d" % (level, max(used + [WINGS["EG"][r["wing"]]["base"]]) + 1)
	# Laufwege: eigene je Stockwerk, sonst die des EG (darüber gleicher Grundriss); das Untergeschoss hat keine
	wings = WINGS.get(floor, WINGS["EG"] if level >= 0 else {})
	pinned = {}
	for no, (x, y) in PINNED.get(floor, {}).items():
		r = next((r for r in rooms if y * W + x in set(comps_of[id(r["region"])][0])), None)
		assert r, "%s: Zimmer %s bei Pixel %d,%d (PINNED) liegt in keinem Zimmer" % (floor, no, x, y)
		r["no"], r["wing"] = no, "west" if r["cx"] < WING_SPLIT_X else "ost"
		pinned[no] = r
	for name, w in (wings if not (level > 0 and eg) else {}).items():
		loop, cross = [], []
		for r in rooms:
			if (r["cx"] < WING_SPLIT_X) != (name == "west") or r.get("no") in pinned:
				continue
			dx, dz = r["door"]["normal"]
			px = r["door"]["pos"][0] / PX + ORIGIN[0] + dx * 20   # Punkt 2 m vor der Tür im Flur
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
				y, x0, direction = w.get("cross", (None, 0, 1))
				assert y is not None and abs(py - y) < 30, "%s: Zimmer bei %s (Tür bei Pixel %d,%d) liegt an keinem Flur aus WINGS" % (
					floor, m(r["cx"], r["cy"]), px, py)
				cross.append(((px - x0) * direction, (r["cy"] > y) if direction > 0 else (r["cy"] < y), r))
		odd, even = w["base"] + 1, w["base"] + 2
		number = lambda n: "%04d" % (level * 1000 + n)
		for _, right, r in sorted(loop, key=lambda e: e[0]) + sorted(cross, key=lambda e: e[0]):
			if right:
				while number(odd) in pinned:
					odd += 2
				r["no"], odd = number(odd), odd + 2
			else:
				while number(even) in pinned:
					even += 2
				r["no"], even = number(even), even + 2
			r["wing"] = name

	# Flurabschnitte: Mittellinien der Laufwege, je Teilstück einer (Lichtschalter, Lampen, Wegpunkte)
	corridors = []
	for name, w in wings.items():
		for leg, (a, b) in zip(w["legs"], zip(w["path"], w["path"][1:])):
			corridors.append({"id": slug("%s %s" % (name, leg)), "name": "%s, %s" % (WING_NAMES[name], leg),
				"wing": name, "a": m(*a), "b": m(*b)})
		if "cross" in w:
			y, x0, _ = w["cross"]
			corridors.append({"id": slug("%s querflur" % name), "name": "%s, Querflur" % WING_NAMES[name],
				"wing": name, "a": m(x0, y), "b": m(w["cross_end"], y)})

	room_list = []
	for r in sorted(rooms, key=lambda r: r["no"]):
		r["region"]["id"] = r["no"]
		entry = {"no": r["no"], "sign": BROKEN_SIGNS.get(r["no"], r["no"]), "wing": r["wing"],
			"rects": r["region"]["rects"], "center": m(r["cx"], r["cy"]), "door": r["door"]}
		if r["windows"]:
			entry["windows"] = r["windows"]
		if r["garden_doors"]:
			entry["garden_doors"] = r["garden_doors"]
		for key in ("bath_doors", "connecting_doors", "side_doors"):
			if r[key]:
				entry[key] = r[key]
		if r["suite"]:
			entry["suite"] = True
		room_list.append(entry)
	dup = sorted({r["no"] for r in room_list if sum(o["no"] == r["no"] for o in room_list) > 1})
	assert not dup, "%s: doppelte Zimmernummer %s (zwei Zimmer über demselben EG-Zimmer?)" % (floor, ", ".join(dup))

	# Aufgehseite ohne Türanschlag (Spielkonzept 7.7): Badtüren gehen ins Zimmer auf, Verbindungstüren ins
	# Zimmer mit der höheren Nummer. Ein Pixel „Türanschlag“ im Plan geht immer vor.
	def opening_at(pos):
		for w in walls:
			(ax, az), (bx, bz) = w["a"], w["b"]
			length = math.hypot(bx - ax, bz - az)
			for o in w.get("openings", []):
				t = (o["at"] + o["width"] / 2) / length
				if math.hypot(ax + (bx - ax) * t - pos[0], az + (bz - az) * t - pos[1]) < 0.3:
					return w, o
		return None, None

	def open_towards(door, target):
		w, o = opening_at(door["pos"])
		if o is None or "opens" in o:
			return
		horizontal = w["a"][1] == w["b"][1]
		o["opens"] = 1 if target[1 if horizontal else 0] > door["pos"][1 if horizontal else 0] else -1

	for r in room_list:
		for d in r.get("bath_doors", []):
			open_towards(d, r["center"])
		for d in r.get("connecting_doors", []):
			other = next((o for o in room_list if o is not r and any(
				math.hypot(e["pos"][0] - d["pos"][0], e["pos"][1] - d["pos"][1]) < 0.3 for e in o.get("connecting_doors", []))), None)
			if other is None or r["no"] > other["no"]:
				open_towards(d, r["center"])

	placed = read_objects(floor, COL)

	# --- Einbauten ---
	def take(kind):
		return [r for r in regions if r["kind"] == kind]

	def outer(rs):
		return [min(r[0] for r in rs), min(r[1] for r in rs), max(r[2] for r in rs), max(r[3] for r in rs)]

	trees = []
	for t in take("tree"):
		x0, z0, x1, z1 = outer(t["rects"])
		trees.append({"center": [round((x0 + x1) / 2, 2), round((z0 + z1) / 2, 2)]})   # nur der Standort, Größe im Spiel

	layout = {
		"source": os.path.basename(SRC), "floor": floor, "level": level, "meters_per_pixel": PX, "origin_px": list(ORIGIN),
		"walls": walls,
		"regions": [r for r in regions if r["kind"] not in FIXTURES],
		"rooms": room_list,
		"corridors": corridors,
		"stairs": stairs,
		"floor_patches": patches,
		"voids": [rc for r in take("void") for rc in r["rects"]],
		"open_above": open_above,
		"areas": areas,
		"objects": objects,
		"planters": [outer(r["rects"]) for r in take("planter")],
		"terrace_edges": [r["rects"] for r in take("terrace_edge")],
		"balcony_edges": [r["rects"] for r in take("balcony_edge")],
		"trees": trees,
		"reception": [rc for r in take("reception") for rc in r["rects"]],
		**placed,
	}
	n_ops = sum(len(w.get("openings", [])) for w in walls)
	print("%s: %d Wände (%d Öffnungen), %d Flächen, %d Zimmer (Ost %d, West %d), %d Treppen, %d Kübel, %d Bäume, "
		"%d Bereiche, %d Objekte" % (floor, len(walls), n_ops, len(layout["regions"]), len(room_list),
		sum(r["wing"] == "ost" for r in room_list), sum(r["wing"] == "west" for r in room_list), len(stairs),
		len(layout["planters"]), len(trees), len(areas), len(objects)))
	print("    Objektebenen: %s" % ", ".join("%d %s" % (len(v), k) for k, v in placed.items()))
	return layout


def read_objects(floor, COL):
	"""Objektebenen eines Stockwerks: Möbel als Rechtecke mit Vorderseite, Teppiche als Rechtecke, sonst Punkte
	mit Wandseite."""
	by_color = {}
	for legend in (FURNITURE, FITTINGS, ITEMS, LIGHTS, RUGS):
		for name, kind in legend.items():
			if name in BY_NAME:
				by_color[BY_NAME[name]] = kind
	front = BY_NAME.get(FRONT_NAME)
	own_fronts = {}   # Farbe der helleren Zeile → (Möbelart, Schlüssel in der Ausgabe)
	for name, kind in FURNITURE.items():
		for suffix, side_key in FRONT_SUFFIXES.items():
			if name + suffix in BY_NAME:
				own_fronts[BY_NAME[name + suffix]] = (kind, side_key)
	walls = {WALL, GLASS} | set(OPENING_OF)
	out = {key: [] for key in OBJECT_LAYERS.values()}
	for layer, img in OBJECT_IMAGES.get(floor, {}).items():
		key = OBJECT_LAYERS[layer]
		seen = set()
		blobs = []   # (Farbe, Pixel) – zusammenhängend über Kanten
		for i, c in img.items():
			if i in seen:
				continue
			seen.add(i)
			q, pts = deque([i]), []
			while q:
				j = q.popleft()
				pts.append(j)
				for k in (j + 1, j - 1, j + W, j - W):
					if k not in seen and img.get(k) == c and abs(k % W - j % W) <= 1:
						seen.add(k)
						q.append(k)
			blobs.append((c, pts))
		is_front = lambda c: key == "furniture" and (c == front or c in own_fronts)
		fronts = [(c, pts) for c, pts in blobs if is_front(c)]
		for c, pts in blobs:
			if is_front(c):
				continue
			xs, ys = [j % W for j in pts], [j // W for j in pts]
			x0, y0, x1, y1 = min(xs), min(ys), max(xs) + 1, max(ys) + 1
			if c not in by_color:
				print("  Warnung: %s/%s – Farbe #%s ohne Eintrag in der Objektlegende bei Pixel %d,%d" % (floor, layer, c, x0, y0))
				continue
			if key == "rugs":
				if len(pts) != (x1 - x0) * (y1 - y0):
					print("  Warnung: %s/%s – Teppich bei Pixel %d,%d ist kein volles Rechteck" % (floor, layer, x0, y0))
				out[key].append({"kind": by_color[c], "rect": m(x0, y0) + m(x1, y1)})
				continue
			if key == "furniture":
				# Vorderseite: der Strich bzw. die hellere Zeile des Möbels, die am Rand des Rechtecks anliegt
				facing, side_key = None, "facing"
				for fc, f in fronts:
					if fc != front and own_fronts[fc][0] != by_color[c]:
						continue
					fx, fy = [j % W for j in f], [j // W for j in f]
					if not (x0 - 1 <= min(fx) and max(fx) <= x1 and y0 - 1 <= min(fy) and max(fy) <= y1):
						continue
					x0, y0, x1, y1 = min(x0, min(fx)), min(y0, min(fy)), max(x1, max(fx) + 1), max(y1, max(fy) + 1)
					horizontal = max(fx) - min(fx) >= max(fy) - min(fy)
					d = {"north": min(fy) - y0, "south": y1 - 1 - max(fy)} if horizontal else \
						{"west": min(fx) - x0, "east": x1 - 1 - max(fx)}
					facing = min(d, key=d.get)
					if fc != front:
						side_key = own_fronts[fc][1]
				entry = {"kind": by_color[c], "rect": m(x0, y0) + m(x1, y1)}
				if facing:
					entry[side_key] = facing
				out[key].append(entry)
				continue
			cx, cy = (x0 + x1) / 2, (y0 + y1) / 2
			entry = {"kind": by_color[c], "pos": m(cx, cy)}
			if key == "lights":
				entry["kind"], broken = by_color[c]
				if broken:
					entry["broken"] = True
				if x1 - x0 != y1 - y0:   # Strich (Halogenleuchte): liegt entlang seiner langen Seite
					entry["axis"] = "x" if x1 - x0 > y1 - y0 else "z"
					entry["length"] = round(max(x1 - x0, y1 - y0) * PX, 2)
			# Wandseite: Wandsachen liegen innen an der Wand – die Seite mit dem nächsten Wand- oder Öffnungspixel
			# (je Abstand eine Zeile/Spalte in Breite des Punkts; gleich nah → mehr Pixel)
			best = None
			for side in ("north", "south", "west", "east"):
				for k in range(1, 4):
					if side in ("north", "south"):
						Y = y0 - k if side == "north" else y1 - 1 + k
						line = [(X, Y) for X in range(x0, x1)]
					else:
						X = x0 - k if side == "west" else x1 - 1 + k
						line = [(X, Y) for Y in range(y0, y1)]
					n = sum(1 for X, Y in line if 0 <= X < W and 0 <= Y < H and COL[Y * W + X] in walls)
					if n:
						if best is None or (k, -n) < best[:2]:
							best = (k, -n, side)
						break
			if best:
				entry["wall"] = best[2]
			out[key].append(entry)
	for key in out:
		out[key].sort(key=lambda e: (e["kind"], e.get("pos", e.get("rect"))[1], e.get("pos", e.get("rect"))[0]))
	return out


def voids_of(COL):
	"""Luftraum eines Stockwerks als Rechtecke (für die Decke des Stockwerks darunter)."""
	c = BY_NAME.get("Luftraum")
	pts = [i for i, v in enumerate(COL) if v == c]
	rows = {}
	for i in pts:
		rows.setdefault(i // W, []).append(i % W)
	out, open_ = [], {}   # Lauf (x0, x1) → [x0, x1, y0, y1], solange er in der Zeile darüber auch vorkam
	for y in sorted(rows):
		xs = sorted(rows[y])
		runs, s = [], xs[0]
		for a, b in zip(xs, xs[1:] + [None]):
			if b != a + 1:
				runs.append((s, a + 1))
				s = b
		nxt = {}
		for r in runs:
			cur = open_.pop(r, None)
			if cur and cur[3] == y:
				cur[3] = y + 1
			else:
				if cur:
					out.append(cur)
				cur = [r[0], r[1], y, y + 1]
			nxt[r] = cur
		out.extend(open_.values())
		open_ = nxt
	out.extend(open_.values())
	out.sort(key=lambda r: (r[2], r[0]))
	return [m(x0, y0) + m(x1, y1) for x0, x1, y0, y1 in out]


# --- Vorschau aus den Layout-Daten (zur Kontrolle, nicht aus dem Bild) ----------------------------------

def preview(layout, path):
	colors = {"room": "#ffb08a", "corridor": "#dde8f2", "garden": "#c8f5bd", "terrace": "#d5e8cf", "service": "#f4f4f4",
		"storage": "#cfcfcf", "bar": "#b5c47a", "party": "#ddb0e0", "toilet": "#7fd6ff", "pool_water": "#3aa6ff",
		"pool_deck": "#c3d2de", "elevator": "#a9dccb", "cellar": "#999", "boiler_room": "#821b1b", "plant_room": "#7c6bff",
		"laundry_room": "#6bb6ff", "cellar_room": "#7b7b7b"}
	op_colors = {"door": "#2e9e00", "garden_door": "#00d000", "window": "#2a7fd0", "glass_double_door": "#e0c000",
		"service_door": "#999", "elevator_door": "#00c090", "main_entrance": "#e00000", "attic_door": "#8a5a2a"}
	out = ['<svg xmlns="http://www.w3.org/2000/svg" viewBox="-80 -118 160 128" width="100%" style="background:#fff">']
	box = '<rect x="%s" y="%s" width="%s" height="%s" %s/>'
	for r in layout["regions"]:
		for x0, z0, x1, z1 in r["rects"]:
			out.append(box % (x0, z0, x1 - x0, z1 - z0, 'fill="%s"' % colors.get(r["kind"], "#eee")))
	for x0, z0, x1, z1 in layout["planters"]:
		out.append(box % (x0, z0, x1 - x0, z1 - z0, 'fill="#5c9a4c"'))
	for t in layout["trees"]:
		out.append('<circle cx="%s" cy="%s" r="5" fill="#2d8f12" fill-opacity=".6"/>' % (t["center"][0], t["center"][1]))
	for s in layout["stairs"]:
		x0, z0, x1, z1 = s["rect"]
		out.append(box % (x0, z0, x1 - x0, z1 - z0, 'fill="#bbb" stroke="#555" stroke-width=".1"'))
	for x0, z0, x1, z1 in layout["open_above"]:
		out.append(box % (x0, z0, x1 - x0, z1 - z0, 'fill="none" stroke="#3f3f74" stroke-width=".2" stroke-dasharray=".6 .4"'))
	for x0, z0, x1, z1 in layout["reception"]:
		out.append(box % (x0, z0, x1 - x0, z1 - z0, 'fill="#df7126"'))
	for w in layout["walls"]:
		(ax, az), (bx, bz) = w["a"], w["b"]
		out.append('<line x1="%s" y1="%s" x2="%s" y2="%s" stroke="%s" stroke-width="%s"/>' % (ax, az, bx, bz, "#8cc" if w.get("glass") else "#000", w["thickness"]))
		L = math.hypot(bx - ax, bz - az)
		for o in w.get("openings", []):
			f0, f1 = o["at"] / L, (o["at"] + o["width"]) / L
			out.append('<line x1="%s" y1="%s" x2="%s" y2="%s" stroke="%s" stroke-width=".45"/>' % (
				ax + (bx - ax) * f0, az + (bz - az) * f0, ax + (bx - ax) * f1, az + (bz - az) * f1, op_colors[o["kind"]]))
			if "hinge" in o:   # Türanschlag: Punkt am Scharnier auf der Aufgehseite
				f = f0 if o["hinge"] == "start" else f1
				nx, nz = (0, o["opens"]) if az == bz else (o["opens"], 0)
				out.append('<circle cx="%s" cy="%s" r=".15" fill="#f300ff"/>' % (ax + (bx - ax) * f + nx * .25, az + (bz - az) * f + nz * .25))
	for r in layout.get("rugs", []):
		x0, z0, x1, z1 = r["rect"]
		out.append(box % (x0, z0, x1 - x0, z1 - z0, 'fill="#5c1420" fill-opacity=".45"'))
	for f in layout.get("furniture", []):
		x0, z0, x1, z1 = f["rect"]
		out.append(box % (x0, z0, x1 - x0, z1 - z0, 'fill="#8a5a2b" fill-opacity=".7"'))
	dots = {"fittings": "#7a3fb0", "items": "#d02020", "lights": "#ffc000"}
	for key, c in dots.items():
		for o in layout.get(key, []):
			out.append('<circle cx="%s" cy="%s" r=".18" fill="%s"/>' % (o["pos"][0], o["pos"][1], "#555" if o.get("broken") else c))
	for r in layout["rooms"]:
		fill = "#c00000" if r["sign"] != r["no"] else "#000"
		out.append('<text x="%s" y="%s" font-size="1.5" text-anchor="middle" font-family="Arial" fill="%s">%s</text>' % (r["center"][0], r["center"][1] + 0.5, fill, r["no"]))
	for r in layout["regions"]:
		if "name" in r:
			x0, z0, x1, z1 = r["rects"][0]
			out.append('<text x="%s" y="%s" font-size="1.2" text-anchor="middle" font-family="Arial" fill="#333">%s</text>' % ((x0 + x1) / 2, (z0 + z1) / 2, r["name"]))
	out.append("</svg>")
	with open(path, "w", encoding="utf-8") as f:
		f.write("\n".join(out))


# --- Ablauf ------------------------------------------------------------------------------------------

floors = floor_images()
ORIGIN = entrance_origin(floors["EG"])
WING_SPLIT_X = ORIGIN[0]   ## Zimmer westlich davon gehören zum Westflügel
by_level = {floor_level(f): f for f in floors}
eg_layout = None
for floor in sorted(floors, key=lambda f: (floor_level(f) != 0, floor_level(f))):   # EG zuerst, die anderen brauchen es
	above = by_level.get(floor_level(floor) + 1)
	layout = build_floor(floor, floors[floor], voids_of(floors[above]) if above else [],
		eg_layout)
	if floor == "EG":
		eg_layout = layout
	if layout is None:
		print("%s: noch keine Wände – keine Layout-Datei" % floor)
		continue
	path = os.path.join(DST_DIR, floor.lower() + ".json")
	with open(path, "w", encoding="utf-8", newline="\n") as f:
		json.dump(layout, f, ensure_ascii=False, indent="\t")
		f.write("\n")
	print("  -> " + path)
	if PREVIEW_DIR:
		preview(layout, os.path.join(PREVIEW_DIR, floor.lower() + ".svg"))
eg = json.load(open(os.path.join(DST_DIR, "eg.json"), encoding="utf-8"))
assert any(r["no"] == "0113" for r in eg["rooms"]), "Spielerzimmer 0113 fehlt"
