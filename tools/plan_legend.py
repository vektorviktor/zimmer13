# Liest die Legende des Gebäudeplans aus PLANFARBEN.md (Spielkonzept 7.5): die gemeinsame Arbeitsgrundlage von
# Zeichner und Code, eine Markdown-Tabelle je Gruppe. Benutzt von tools/build_map.py (Farbe → Name) und
# tools/build_colors.py (map_a.gpl und map_colors.png daraus).
#
# Aufbau, den das Skript erwartet:
#   - Überschriften „## Wände“, „## Flächen“, „## Öffnungen“, „## Möbel“, „## Teppiche“, „## Ausstattung“,
#     „## Gegenstände“, „## Lichter“ (GROUPS). Die Gruppe gibt den Vorsatz des Namens („Möbel: Bett“). Andere
#     Abschnitte (Regeln, Bestand im Code …) werden übergangen.
#   - Tabellen mit Kopfzeile; gelesen werden die Spalten „Farbe“, „Name“, „Vorderseite“ (nur Möbel/Teppiche) und
#     „Hinweis“, in beliebiger Reihenfolge.
#   - Farbe als „#rrggbb“. „–“ statt einer Farbe = im Code vorgesehen, noch ohne Farbe (wird übergangen).
#   - Vorderseite: „#rrggbb“ = die hellere Randzeile „<Name> Vorderseite“; steht „Kopfende“ dabei, heißt sie
#     „<Name> Kopfende“ (Doppelbett).
import os, re

DEFAULT = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "PLANFARBEN.md")

## Überschrift → (Schlüssel, Vorsatz des Namens)
GROUPS = {
	"Wände": ("wall", ""), "Flächen": ("fill", ""), "Öffnungen": ("opening", ""),
	"Möbel": ("furniture", "Möbel: "), "Teppiche": ("rug", "Teppich: "), "Ausstattung": ("fitting", "Ausstattung: "),
	"Gegenstände": ("item", "Gegenstand: "), "Lichter": ("light", "Licht: "),
}
HEX = re.compile(r"#([0-9a-fA-F]{6})\b")


def _cells(line):
	return [c.strip() for c in line.strip().strip("|").split("|")]


def read(path=DEFAULT):
	"""Einträge in Dateireihenfolge: dict(name, hex, group, title, short, front, front_hex, note). name mit Vorsatz,
	hex ohne „#“, front = voller Name der Vorderseite (oder ""). Fehler (doppelte Farbe oder Name) → ValueError."""
	entries, group, header = [], None, None
	for n, line in enumerate(open(path, encoding="utf-8"), 1):
		if line.startswith("## "):
			title = line[3:].strip()
			group = (title,) + GROUPS[title] if title in GROUPS else None
			header = None
			continue
		if group is None or not line.lstrip().startswith("|"):
			header = None
			continue
		cells = _cells(line)
		if header is None:
			header = {c: i for i, c in enumerate(cells)}
			if "Farbe" not in header or "Name" not in header:
				raise ValueError("%s:%d: Tabelle ohne Spalten „Farbe“ und „Name“" % (path, n))
			continue
		if set(line.strip()) <= set("|-: "):
			continue   # Trennzeile unter dem Kopf
		get = lambda col: cells[header[col]] if col in header and header[col] < len(cells) else ""
		color = HEX.search(get("Farbe"))
		if not color:
			continue   # „–“: noch ohne Farbe
		short = get("Name").strip("`* ")
		front = HEX.search(get("Vorderseite"))
		suffix = " Kopfende" if "Kopfende" in get("Vorderseite") else " Vorderseite"
		name = group[2] + short
		entries.append({"name": name, "hex": color.group(1).lower(), "group": group[1], "title": group[0],
			"short": short, "front": name + suffix if front else "", "front_hex": front.group(1).lower() if front else "",
			"note": get("Hinweis"), "line": n})
	_check(entries, path)
	return entries


def _check(entries, path):
	seen_hex, seen_name = {}, {}
	for e in entries:
		for name, hx in ((e["name"], e["hex"]), (e["front"], e["front_hex"])):
			if not name:
				continue
			if hx in seen_hex:
				raise ValueError("%s:%d: Farbe #%s doppelt (%s und %s)" % (path, e["line"], hx, seen_hex[hx], name))
			if name in seen_name:
				raise ValueError("%s:%d: Name „%s“ doppelt" % (path, e["line"], name))
			seen_hex[hx], seen_name[name] = name, hx


## Größenangaben, die sizes() erkennt (ZIM-141) – nur Pixelangaben, Meter („2 × 1 m“) beschreiben das Modell
SIZE = re.compile(r"(\d+)\s*×\s*(\d+)\s*(?:px\b|-Punkt)")
DEPTH = re.compile(r"(\d+)\s*px\s+tief\b")
PIXELS = re.compile(r"^(\d+)\s*px\b")
LINE_WIDTH = re.compile(r"Linien\b[^.|]*?(\d+)\s*px\b")


def sizes(path=DEFAULT):
	"""Größenregeln aus der Legende, für build_map.py (ZIM-141): {Name: Regel}. Gelesen werden nur Pixelangaben im
	Hinweis eines Eintrags oder im Satz unter der Überschrift (gilt dann für jeden Eintrag der Gruppe ohne eigene):
	„a × b px“ / „a×b-Punkt“ → ("size", a, b) Rechteck in beliebiger Lage · „d px tief“ → ("depth", d) kurze Seite
	(Länge frei) · Hinweis beginnt mit „n px“ → ("pixels", n) · „Linien …, n px“ → ("width", n) Strichbreite.
	Einträge ohne Angabe fehlen – für sie gibt es keine Regel."""
	intro = {}   # Gruppe → Satz unter der Überschrift
	group = None
	for line in open(path, encoding="utf-8"):
		if line.startswith("#"):
			group = GROUPS.get(line.lstrip("#").strip(), (None,))[0]
		elif group and line.strip() and not line.lstrip().startswith("|"):
			intro[group] = intro.get(group, "") + " " + line.strip()
		elif line.lstrip().startswith("|"):
			group = None   # nur der Text vor der Tabelle

	def rule(text, start=False):
		for regex, kind in ((SIZE, "size"), (DEPTH, "depth"), (LINE_WIDTH, "width")) + ((PIXELS, "pixels"),) * start:
			hit = regex.search(text)
			if hit:
				return (kind,) + tuple(int(g) for g in hit.groups())
		return None

	out = {}
	for e in read(path):
		r = rule(e["note"], True) or rule(intro.get(e["group"], ""))
		if r:
			out[e["name"]] = r
	return out


def pairs(path=DEFAULT):
	"""[(Name, Hex)] wie die GIMP-Palette: jede Farbe, Vorderseiten direkt nach ihrem Möbel."""
	out = []
	for e in read(path):
		out.append((e["name"], e["hex"]))
		if e["front"]:
			out.append((e["front"], e["front_hex"]))
	return out
