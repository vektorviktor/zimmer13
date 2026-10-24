# Liest HAUSHALTE.md (Spielkonzept 6.20) und schreibt assets/data/households.json: wer mit wem in welchem Zimmer
# wohnt. HAUSHALTE.md bleibt die einzige Quelle – sie gehört dem Spielkonzept und wird von Hand gepflegt.
#
# Gelesen werden die Tabellen der Haushalte (Zeilen „| H01 | …“) und die Zimmerliste. Ein Haushalt hängt an der
# Stelle seines Zimmers im Plan (Spalte „Mitte im Plan (px)“ der Zimmerliste, je Stockwerk ab der Oberkante seines
# Bands) – nicht an der Nummer, die sich noch ändern kann. Der LevelBuilder sucht das Zimmer an dieser Stelle.
#
# Ausgabe:
#   {"households": [{"id": "H01", "surname": "Brandt", "label": "122", "floor": 1, "px": [209, 739],
#                    "members": [{"name": "Henrik", "sex": "m", "gen": "mid", "archetype": "Bastler"},
#                                {"name": "Max", "sex": "m", "child": true, "age": 9}, …],
#                    "core": "edna"}, …],          # core: Kernfigur mit eigenem Profil (GuestProfiles.ALL)
#    "special": [{"label": "017", "floor": 0, "px": [1329, 199], "kind": "abandoned"}, …]}
#
# Aufruf (Python 3, keine Zusatzpakete):  python tools/build_households.py [HAUSHALTE.md] [assets/data/households.json]
import json, os, re, sys

SRC = sys.argv[1] if len(sys.argv) > 1 else "HAUSHALTE.md"
DST = sys.argv[2] if len(sys.argv) > 2 else "assets/data/households.json"

GEN = {"jung": "young", "mittel": "mid", "alt": "old"}
## Kernfiguren mit eigenem Profil in GuestProfiles.ALL (Vorname → ID); Marion hat noch keins
CORE = {"Edna": "edna", "Bruno": "bruno", "Mila": "mila"}
## Geschlecht der Vornamen – wie GuestGenerator.FEMALE / CHILD_FEMALE, dazu die Kernfiguren
FEMALE = {"Berta", "Carla", "Elif", "Frieda", "Hanna", "Ida", "Lotte", "Nora", "Paula", "Rosa", "Uschi", "Vera",
	"Yara", "Zoe", "Greta", "Lena", "Ines", "Marta", "Selma", "Johanna", "Wilma", "Tilda", "Agnes", "Clara",
	"Fiona", "Gerda", "Irma", "Klara", "Magda", "Olga", "Ruth", "Thea", "Wanda", "Zita", "Alma", "Doris",
	"Gisela", "Hedwig", "Jule", "Liesel", "Nele", "Edna", "Mila", "Marion",
	"Lina", "Emma", "Merle", "Juna", "Ella", "Pia", "Ronja", "Smilla"}
## Sonderzimmer der Zimmerliste (Anfang der Spalte „Belegung“) → Zimmerart im LevelBuilder
SPECIAL = {"Spieler": "player", "verlassen": "abandoned", "abgeschlossen (bisher": "locked", "verfallen": "derelict"}
FLOORS = {"EG": 0, "OG1": 1}


def cells(line):
	return [c.strip() for c in line.strip().strip("|").split("|")]


def main():
	text = open(SRC, encoding="utf-8").read()
	head, rooms_part = text.split("## Zimmerliste", 1)
	rooms = {}
	special = []
	for line in rooms_part.splitlines():
		c = cells(line)
		if len(c) != 7 or not re.fullmatch(r"\d+", c[0]):
			continue
		floor = FLOORS[c[1].split()[0]]
		px = [int(v) for v in re.findall(r"\d+", c[5])]
		rooms[c[0]] = (floor, px)
		for start, kind in SPECIAL.items():
			if c[6].startswith(start):
				special.append({"label": c[0], "floor": floor, "px": px, "kind": kind})
	households = []
	for line in head.splitlines():
		m = re.match(r"\| (H\d\d)( ★)? \|", line)
		if not m:
			continue
		c = cells(line)
		hid, name, room = c[0].split()[0], c[1], c[2].split()[0]
		person = re.sub(r"\s*\(Kernfigur\)", "", name)
		surname = person.split()[-1]
		members = []
		core = ""
		for first, gen, arche in re.findall(r"([A-ZÄÖÜ][a-zäöüß]+) \((jung|mittel|alt), ([^)]+)\)", c[3]):
			sex = "f" if first in FEMALE else "m"
			entry = {"name": first, "sex": sex, "gen": GEN[gen]}
			if arche != "eigenes Profil":
				entry["archetype"] = arche
			if first in CORE and "Kernfigur" in name:
				core = CORE[first]
			members.append(entry)
		if len(c) == 7:   # Familien: Spalte „Kinder“
			for first, age in re.findall(r"([A-ZÄÖÜ][a-zäöüß]+) \((\d+)\)", c[4]):
				members.append({"name": first, "sex": "f" if first in FEMALE else "m", "child": True, "age": int(age)})
		assert members, "%s: keine Mitglieder erkannt" % hid
		assert room in rooms, "%s: Zimmer %s fehlt in der Zimmerliste" % (hid, room)
		floor, px = rooms[room]
		entry = {"id": hid, "surname": surname, "label": room, "floor": floor, "px": px, "members": members}
		if core:
			entry["core"] = core
		households.append(entry)
	labels = [h["label"] for h in households]
	assert len(labels) == len(set(labels)), "zwei Haushalte im selben Zimmer"
	os.makedirs(os.path.dirname(DST), exist_ok=True)
	json.dump({"households": households, "special": special}, open(DST, "w", encoding="utf-8"), ensure_ascii=False,
		indent="\t")
	adults = sum(1 for h in households for p in h["members"] if not p.get("child"))
	kids = sum(1 for h in households for p in h["members"] if p.get("child"))
	print("%d Haushalte (%d Erwachsene, %d Kinder), %d Sonderzimmer -> %s" % (len(households), adults, kids,
		len(special), DST))


main()
