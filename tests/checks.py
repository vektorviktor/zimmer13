"""Selbstprüfungen (TECHNIK.md 10): schnelle Textprüfungen ohne Godot, laufen bei jedem Rauchtest vor den Godot-Läufen
mit (bash tests/smoke.sh pruefen einzeln). Fehler brechen den Rauchtest nicht ab, zählen aber im Fazit.

  python tests/checks.py        Exit 0 = keine Fehler (Warnungen erlaubt), 1 = Fehler

Prüft:
  1. class_name doppelt im res://-Baum, wie Godot ihn scannt (ohne Ordner mit .gdignore und versteckte wie .claude/),
     class_name gleich einem Autoload, doppelte .uid-Dateien (kopierte Sicherung); Warnung bei Skripten außerhalb von
     scripts/, shaders/, tests/, tools/, addons/ (Sicherungskopien in temp/ – Godot lädt sie mit)
  2. Verweise wie „(Spielkonzept 4.13)“, „SK 5.12“, nackt „(2.5)“ im Kommentar, „TECHNIK.md 10“,
     „TECHNIK.md 1 „Grafik““ zeigen auf vorhandene Kapitel und Abschnitte (Unterpunkte wie „6.19 (7)“ nicht)
  3. Debug-Parameter: was scripts/main.gd auswertet, steht im Kopfkommentar und in der README-Tabelle – und umgekehrt
  4. Rauchtest-Liste in tests/smoke.sh: jede Zeile Frames|Stichworte|Parameter mit Stichwort, höchstens SCHNELL_MAX
     mit „schnell“ (sonst Warnung), jedes in der Doku genannte Stichwort gibt es
  5. preload/load mit festem res://-Pfad zeigen auf vorhandene Dateien
  6. Godots Klassen-Cache kennt jede class_name mit ihrem Pfad (Warnung; mit --cache allein, Exit 1 = veraltet –
     smoke.sh führt dann vor den Läufen einmal --import aus)
Item.Kind prüft tests/run.tscn (save_rules) gegen tests/golden/save_rules.json – hier nicht doppelt.
"""

import functools
import os
import re
import sys
import time

ROOT = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
SCRIPT_DIRS = ("scripts", "shaders", "tests", "tools", "addons")
DOCS = ("CLAUDE.md", "README.md", "TECHNIK.md", "SPIELKONZEPT.md", "HANDLUNG.md", "GEGENSTAENDE.md", "OFFEN.md")
# Stichwörter von smoke.sh, die keine Szenario-Stichwörter sind
SMOKE_WORDS = {"schnell", "stichworte", "pruefen"}
SCHNELL_MAX = 8   # mehr Szenarien mit „schnell“ → die Stufe dauert über eine Minute (CLAUDE.md)

errors: list[str] = []
warnings: list[str] = []


def rel(path: str) -> str:
	return os.path.relpath(path, ROOT).replace("\\", "/")


def error(where: str, what: str, fix: str) -> None:
	errors.append(f"FEHLER   {where}: {what}\n         → {fix}")


def warn(where: str, what: str, fix: str) -> None:
	warnings.append(f"WARNUNG  {where}: {what}\n         → {fix}")


@functools.cache
def read(path: str) -> str:
	with open(path, encoding="utf-8", errors="replace") as f:
		return f.read()


def res_files() -> list[str]:
	"""Alle Dateien, die Godot im res://-Baum sieht."""
	found = []
	for dirpath, dirnames, filenames in os.walk(ROOT):
		if ".gdignore" in filenames:
			dirnames[:] = []
			continue
		dirnames[:] = sorted(d for d in dirnames if not d.startswith("."))
		found += [os.path.join(dirpath, f) for f in sorted(filenames)]
	return found


def code_files(files: list[str]) -> list[str]:
	return [f for f in files if f.endswith((".gd", ".gdshader"))]


# --- 1. class_name, Autoloads, .uid ---------------------------------------------------------------------------------

def check_classes(files: list[str]) -> None:
	classes: dict[str, list[str]] = {}
	for path in code_files(files):
		r = rel(path)
		if path.endswith(".gd"):
			for n, line in enumerate(read(path).splitlines(), 1):
				m = re.match(r"\s*(?:@\w+\s+)*class_name\s+(\w+)", line)
				if m:
					classes.setdefault(m.group(1), []).append(f"{r}:{n}")
		if r.split("/")[0] not in SCRIPT_DIRS:
			warn(r, "Skript außerhalb von scripts/, shaders/, tests/, tools/, addons/ – Godot lädt es mit (Sicherungskopie?)",
				"löschen, unter anderem Namen als .txt ablegen oder in einen Ordner mit .gdignore verschieben")
	for name, where in sorted(classes.items()):
		if len(where) > 1:
			error(", ".join(where), f"class_name {name} mehrfach – Godot nimmt eine davon, Fehler entstehen woanders",
				"Kopien löschen oder dort die class_name-Zeile entfernen (Sicherungen nicht im res://-Baum)")
	autoloads = re.findall(r"^(\w+)=\"\*?res://", read(os.path.join(ROOT, "project.godot")), re.M)
	for name in autoloads:
		if name in classes:
			error(classes[name][0], f"class_name {name} heißt wie ein Autoload in project.godot",
				"class_name umbenennen oder entfernen")
	uids: dict[str, list[str]] = {}
	for path in files:
		if path.endswith(".uid"):
			uids.setdefault(read(path).strip(), []).append(rel(path))
	for uid, where in sorted(uids.items()):
		if len(where) > 1:
			error(", ".join(where), f"dieselbe UID {uid} mehrfach (mitkopierte .uid-Datei)",
				"die .uid-Datei der Kopie löschen – Godot vergibt beim nächsten Import eine neue")


def class_cache_stale(files: list[str]) -> list[str]:
	"""Abweichungen zwischen den class_name der Skripte und Godots Klassen-Cache (.godot/global_script_class_cache.cfg).
	Veraltet nach einem Merge mit neuer Klasse → hunderte Folgefehler („Identifier … not declared“), bis --import lief."""
	cache_path = os.path.join(ROOT, ".godot", "global_script_class_cache.cfg")
	if not os.path.exists(cache_path):
		return ["kein Klassen-Cache (.godot/ fehlt – noch nie importiert)"]
	cached = dict(re.findall(r'"class": &"(\w+)",.*?"path": "res://([^"]+)"', read(cache_path), re.S))
	scripts = {}
	for path in files:
		if path.endswith(".gd"):
			m = re.search(r"^\s*(?:@\w+\s+)*class_name\s+(\w+)", read(path), re.M)
			if m:
				scripts.setdefault(m.group(1), rel(path))
	stale = [f"{name} fehlt im Cache ({path})" for name, path in sorted(scripts.items()) if name not in cached]
	stale += [f"{name} zeigt im Cache auf {cached[name]} statt {path}" for name, path in sorted(scripts.items())
		if name in cached and cached[name] != path]
	stale += [f"{name} steht noch im Cache ({path}), das Skript gibt es so nicht mehr" for name, path in sorted(cached.items())
		if name not in scripts]
	return stale


# --- 2. Verweise auf Spielkonzept und TECHNIK ----------------------------------------------------------------------

def headings(path: str) -> tuple[set[str], list[str]]:
	"""Kapitelnummern („4.13“, „7“, „8a“) und alle Überschriften- bzw. Fettdruck-Texte einer Markdown-Datei."""
	numbers, titles = set(), []
	for line in read(path).splitlines():
		m = re.match(r"#{2,4}\s+(\d+[a-z]?(?:\.\d+)?)\.?\s+(.*)", line)
		if m:
			numbers.add(m.group(1))
		if line.startswith("#"):
			titles.append(line.lstrip("# "))
		titles += re.findall(r"\*\*([^*]+)\*\*", line)
	return numbers, titles


# erste Nummer nach dem Namen, weitere durch , – + / ; „und“ getrennt (ein Datum wie „24.10.“ beendet die Liste)
NUM = r"\d+(?:\.\d+)?"
SK_REF = re.compile(r"\b(?:Spielkonzept|SK)\s+(" + NUM + r")((?:\s*(?:,|–|-|\+|/|;|und)\s*" + NUM + r"(?![.\d]|-\d))*)")
# nackt im Kommentar: „(2.5)“, „(4.33, …“ – nur Hauptkapitel 1–11, Werte wie „(0.5)“ fallen so heraus
BARE_REF = re.compile(r"\(((?:[1-9]|1[01])\.\d{1,2})(?=[),;])")
TECH_REF = re.compile(r"\bTECHNIK(?:\.md)?(?:\s+(\d+a?)(?![.\d])|,)?\s*„([^“]+)“|\bTECHNIK(?:\.md)?\s+(\d+a?)(?![.\d])")


def comment(path: str, line: str) -> str:
	"""Kommentarteil einer Codezeile (# bzw. // außerhalb von Strings), in Markdown nichts."""
	mark = "#" if path.endswith(".gd") else "//" if path.endswith(".gdshader") else None
	if not mark:
		return ""
	quote = None
	for i, ch in enumerate(line):
		if quote:
			quote = None if ch == quote and line[i - 1] != "\\" else quote
		elif ch in "\"'":
			quote = ch
		elif line.startswith(mark, i):
			return line[i:]
	return ""


def check_refs(files: list[str]) -> None:
	sk_numbers, _ = headings(os.path.join(ROOT, "SPIELKONZEPT.md"))
	tech_numbers, tech_titles = headings(os.path.join(ROOT, "TECHNIK.md"))
	sources = [f for f in code_files(files)] + [os.path.join(ROOT, d) for d in DOCS]
	for path in sources:
		if not os.path.exists(path):
			continue
		for n, line in enumerate(read(path).splitlines(), 1):
			for m in SK_REF.finditer(line):
				for num in [m.group(1)] + re.findall(NUM, m.group(2)):
					if num not in sk_numbers:
						error(f"{rel(path)}:{n}", f"„{m.group(0).strip()}“ – Kapitel {num} gibt es in SPIELKONZEPT.md nicht",
							"Nummer an die Überschriften (### …) in SPIELKONZEPT.md anpassen")
			for m in BARE_REF.finditer(comment(path, line)):
				if m.group(1) not in sk_numbers:
					error(f"{rel(path)}:{n}", f"„({m.group(1)}“ im Kommentar – Kapitel {m.group(1)} gibt es in "
						"SPIELKONZEPT.md nicht", "Nummer an die Überschriften (### …) in SPIELKONZEPT.md anpassen")
			for m in TECH_REF.finditer(line):
				num = m.group(1) or m.group(3)
				if num and num not in tech_numbers:
					error(f"{rel(path)}:{n}", f"„{m.group(0).strip()}“ – Abschnitt {num} gibt es in TECHNIK.md nicht",
						"Nummer an die Überschriften (## …) in TECHNIK.md anpassen")
				title = m.group(2)
				if title and not any(title.lower() in t.lower() for t in tech_titles):
					error(f"{rel(path)}:{n}", f"„{title}“ ist in TECHNIK.md weder Überschrift noch fett gedruckt",
						"auf eine vorhandene Überschrift verweisen oder den Begriff dort fett setzen")


# --- 3. Debug-Parameter ---------------------------------------------------------------------------------------------

PARAM = r"--([a-z0-9äöüß][a-z0-9äöüß_-]*)"


def check_params(files: list[str]) -> None:
	main_path = os.path.join(ROOT, "scripts", "main.gd")
	lines = read(main_path).splitlines()
	header: dict[str, int] = {}
	start = next(i for i, l in enumerate(lines) if "Debug-Startparameter" in l)
	for i in range(start + 1, len(lines)):
		if not lines[i].startswith("##"):
			break
		m = re.match(r"##   (--\S.*?)(?:\s{2,}|$)", lines[i])
		if m:
			for p in re.findall(PARAM, m.group(1)):
				header.setdefault(p, i + 1)
	in_main: dict[str, int] = {}
	for n, line in enumerate(lines, 1):
		code = line.split("#")[0] if not line.lstrip().startswith("#") else ""
		for p in re.findall(r"\"" + PARAM, code):
			in_main.setdefault(p, n)
	in_code = set(in_main)   # auch andere Skripte werten Parameter aus (Titelbildschirm, Game …)
	for path in files:
		if path.endswith(".gd") and path != main_path:
			for line in read(path).splitlines():
				if not line.lstrip().startswith("#"):
					in_code.update(re.findall(r"\"" + PARAM, line))
	readme_path = os.path.join(ROOT, "README.md")
	readme: dict[str, int] = {}
	inside = False
	for n, line in enumerate(read(readme_path).splitlines(), 1):
		if line.startswith("## "):
			inside = "Debug-Startparameter" in line
		elif inside and line.startswith("|"):
			for p in re.findall(PARAM, line.split("|")[1]):
				readme.setdefault(p, n)
	for p, n in sorted(in_main.items()):
		if p not in header:
			error(f"scripts/main.gd:{n}", f"--{p} wird ausgewertet, fehlt aber im Kopfkommentar",
				f"Zeile „##   --{p} …“ in den Kopfkommentar von main.gd (Debug-Startparameter)")
		if p not in readme:
			error(f"scripts/main.gd:{n}", f"--{p} wird ausgewertet, fehlt aber in der README-Tabelle",
				f"Zeile „| `--{p}` | … |“ unter README.md „Debug-Startparameter“")
	for p, n in sorted(header.items()):
		if p not in in_code:
			error(f"scripts/main.gd:{n}", f"--{p} steht im Kopfkommentar, kein Skript wertet es aus",
				"Zeile entfernen oder den Parameter (wieder) auswerten")
	for p, n in sorted(readme.items()):
		if p not in in_code:
			error(f"README.md:{n}", f"--{p} steht in der README-Tabelle, kein Skript wertet es aus",
				"Zeile entfernen oder den Parameter (wieder) auswerten")


# --- 4. Rauchtest-Liste ---------------------------------------------------------------------------------------------

def check_smoke() -> None:
	path = os.path.join(ROOT, "tests", "smoke.sh")
	lines = read(path).splitlines()
	tags: set[str] = set()
	args_all = []
	schnell = 0
	inside = False
	for n, line in enumerate(lines, 1):
		if line == "done <<'LIST'":
			inside = True
			continue
		if line == "LIST":
			break
		if not inside or not line.strip():
			continue
		parts = line.split("|")
		where = f"tests/smoke.sh:{n}"
		if len(parts) != 3 or not parts[0].isdigit():
			error(where, f"„{line}“ hat nicht die Form Frames|Stichworte|Parameter", "Zeile in diese Form bringen")
			continue
		line_tags = [t for t in parts[1].split(",") if t]
		if not line_tags:
			error(where, "Szenario ohne Stichwort – läuft nur im vollen Rauchtest",
				"ein oder mehrere Stichwörter vor die Parameter (bash tests/smoke.sh stichworte listet die vorhandenen)")
		for t in line_tags:
			if not re.fullmatch(r"[a-z0-9äöüß_]+", t):
				error(where, f"Stichwort „{t}“ – nur Kleinbuchstaben, Ziffern, _", "Stichwort umschreiben")
		tags.update(line_tags)
		schnell += "schnell" in line_tags
		args_all.append(parts[2])
	if schnell > SCHNELL_MAX:
		warn("tests/smoke.sh", f"{schnell} Szenarien mit „schnell“ (bis {SCHNELL_MAX} vorgesehen, Stufe < 1 min)",
			"„schnell“ nur für wenige, die viel auf einmal berühren (CLAUDE.md)")
	known = tags | SMOKE_WORDS
	sources = [os.path.join(ROOT, d) for d in DOCS] + [path]
	for src in sources:
		if not os.path.exists(src):
			continue
		for n, line in enumerate(read(src).splitlines(), 1):
			words = re.findall(r"smoke\.sh ([a-z0-9äöüß_]+)", line)
			words += re.findall(r"Stichw[oö]rt(?:e|en)?\s+[`„]([a-z0-9äöüß_]+)[`“]", line)
			if "Stichw" in line:   # Aufzählung wie (`schlaf`, `monster`, `gaeste` …)
				for group in re.findall(r"\((`[a-z0-9äöüß_]+`(?:, `[a-z0-9äöüß_]+`)+)", line):
					words += re.findall(r"`([a-z0-9äöüß_]+)`", group)
			for w in words:
				if w not in known and not any(w in a for a in args_all):
					error(f"{rel(src)}:{n}", f"Rauchtest-Stichwort „{w}“ gibt es nicht",
						"Stichwort in tests/smoke.sh vergeben oder den Verweis auf ein vorhandenes ändern "
						"(bash tests/smoke.sh stichworte)")


# --- 5. preload/load ------------------------------------------------------------------------------------------------

LOAD = re.compile(r"\b(?:preload|load|ResourceLoader\.load|ResourceLoader\.exists)\(\s*\"(res://[^\"%]+)\"")


def check_loads(files: list[str]) -> None:
	for path in files:
		if not path.endswith(".gd"):
			continue
		for n, line in enumerate(read(path).splitlines(), 1):
			if line.lstrip().startswith("#"):
				continue
			for target in LOAD.findall(line):
				if "ResourceLoader.exists" in line or target.startswith("res://temp/"):
					continue   # bewusst bedingt, bzw. erst zur Laufzeit erzeugt
				if not os.path.exists(os.path.join(ROOT, target[len("res://"):])):
					error(f"{rel(path)}:{n}", f"lädt {target} – die Datei gibt es nicht",
						"Pfad korrigieren (umbenannt, verschoben?) oder die Datei anlegen")


def main() -> int:
	t0 = time.time()
	files = res_files()
	if "--cache" in sys.argv:   # nur den Klassen-Cache prüfen (smoke.sh: veraltet → --import), Exit 1 = veraltet
		stale = class_cache_stale(files)
		for line in stale[:5]:
			print(f"[import] {line}")
		if len(stale) > 5:
			print(f"[import] … und {len(stale) - 5} weitere")
		return 1 if stale else 0
	for line in class_cache_stale(files)[:3]:
		warn(".godot/global_script_class_cache.cfg", f"Klassen-Cache veraltet: {line}",
			"Godot --headless --path . --import (der Rauchtest macht das vorweg selbst)")
	check_classes(files)
	check_refs(files)
	check_params(files)
	check_smoke()
	check_loads(files)
	for line in errors + warnings:
		print(line)
	print(f"[pruefen] {len(errors)} Fehler, {len(warnings)} Warnungen ({time.time() - t0:.1f} s)")
	return 1 if errors else 0


if __name__ == "__main__":
	sys.stdout.reconfigure(encoding="utf-8")
	sys.exit(main())
