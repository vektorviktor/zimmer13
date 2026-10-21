class_name PumpkinKinds
## Kürbissorten (Spielkonzept 5.8): Aussehen, Tragen, Schnitzen, Deko-Stärke, Wert und Wachstum je Sorte.
## Ein Kürbis (Item PUMPKIN / CARVED_PUMPKIN) trägt seine Sorte im Zusatzfeld (Item.create_extra), eine Pflanze bekommt
## sie aus dem Gebäudeplan (Palettenfarbe „Ausstattung: Kürbispflanze <Sorte>“). Ohne Angabe: Halloween-Kürbis.

const DEFAULT := "halloween"
## Reihenfolge = Reihenfolge im Plan und in den Lieblingssorten der Gäste – neue Sorten nur hinten anfügen
const ORDER := ["halloween", "hokkaido", "casper", "butternut", "muskat", "turban", "giant"]
## shape: round (rund), flat (flach, gerippt), bottle (Flaschenform), turban (mit Kappe)
## size: Maße (m), carry: tragbar, large: beide Hände, carve: schnitzbar, deco: Deko-Stärke, price: Grundpreis,
## grow: Sekunden bis reif, mass: kg; geschnitzt leuchtet er in glow
const DATA := {
	"halloween": {"name": "Halloween-Kürbis", "shape": "round", "color": Color(0.85, 0.42, 0.08), "size": Vector3(0.42, 0.34, 0.42),
		"carry": true, "large": true, "carve": true, "deco": 10.0, "price": 4, "grow": 225.0, "mass": 4.0, "glow": Color(1.0, 0.55, 0.15)},
	"hokkaido": {"name": "Hokkaido", "shape": "round", "color": Color(0.82, 0.3, 0.06), "size": Vector3(0.2, 0.16, 0.2),
		"carry": true, "large": false, "carve": false, "deco": 4.0, "price": 2, "grow": 150.0, "mass": 1.2},
	"casper": {"name": "Weißer Kürbis", "shape": "round", "color": Color(0.86, 0.86, 0.8), "size": Vector3(0.44, 0.32, 0.44),
		"carry": true, "large": true, "carve": true, "deco": 12.0, "price": 6, "grow": 300.0, "mass": 4.5, "glow": Color(0.75, 0.85, 1.0)},
	"butternut": {"name": "Butternut", "shape": "bottle", "color": Color(0.86, 0.7, 0.45), "size": Vector3(0.18, 0.32, 0.18),
		"carry": true, "large": false, "carve": false, "deco": 5.0, "price": 4, "grow": 210.0, "mass": 1.5},
	"muskat": {"name": "Muskatkürbis", "shape": "flat", "color": Color(0.45, 0.42, 0.2), "size": Vector3(0.5, 0.24, 0.5),
		"carry": true, "large": true, "carve": false, "deco": 8.0, "price": 6, "grow": 270.0, "mass": 6.0},
	"turban": {"name": "Türkenturban", "shape": "turban", "color": Color(0.8, 0.32, 0.1), "size": Vector3(0.3, 0.26, 0.3),
		"carry": true, "large": false, "carve": false, "deco": 9.0, "price": 6, "grow": 240.0, "mass": 2.0},
	"giant": {"name": "Riesenkürbis", "shape": "round", "color": Color(0.9, 0.52, 0.12), "size": Vector3(0.95, 0.72, 0.95),
		"carry": false, "large": true, "carve": true, "deco": 25.0, "price": 0, "grow": 450.0, "mass": 60.0, "glow": Color(1.0, 0.5, 0.12)},
}
## Was ein Gast als Lieblingskürbis haben kann (den Riesen erntet keiner)
const FAVORITES := ["halloween", "hokkaido", "casper", "butternut", "muskat", "turban"]


static func data(variety: String) -> Dictionary:
	return DATA.get(variety, DATA[DEFAULT])


## Sorte aus einem Zusatzfeld („hokkaido“, „casper,unlit“ …) – unbekannt oder leer: Halloween-Kürbis.
static func from_extra(extra: String) -> String:
	for part in extra.split(","):
		if DATA.has(part):
			return part
	return DEFAULT


## Lieblingskürbis eines Gastes – fest aus seiner ID, damit Spielstände gleich bleiben.
static func favorite_of(guest_id: String) -> String:
	return FAVORITES[absi(hash(guest_id + "|kürbis")) % FAVORITES.size()]
