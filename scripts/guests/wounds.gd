class_name Wounds
## Überlebende & Verletzungen (Spielkonzept 6.17, entschieden 2026-10-21): Etwa vier von zehn Gästen überleben einen
## Angriff – entschieden beim Angriff, ohne Lebenspunkte. Je Angreifer eine Verletzung: Kratzer vom Monster (nichts
## Großes), Axtwunde vom Kürbismann (humpelt, blutet eine Spur), Würgemale vom Lakengeist (heiser, atmet schwer). Wer
## verletzt ist, erzählt zuverlässig, was er erlebt hat, und die Beziehung zu ihm ändert sich doppelt so schnell.
## Nur Daten und Sätze – den Zustand trägt der Gast (Guest.wound …).

## So oft überlebt ein Gast einen Angriff (Lakengeist: SheetGhost.GUEST_ESCAPE, im Mittel ebenso)
const SURVIVE := 0.4
## Je Art: Name, Heilung (Spielsekunden, 300 = ein Spieltag), davon im Bett, Gehtempo, ob er rennen kann, wie lange er
## blutet (Spur), ob er heiser ist und schwer atmet
const KINDS := {
	"scratch": {"name": "Kratzer und Schrammen", "heal": 360.0, "bed": 0.0, "speed": 1.0, "run": true, "bleed": 25.0, "hoarse": false},
	"axe": {"name": "Axtwunde", "heal": 750.0, "bed": 300.0, "speed": 0.55, "run": false, "bleed": 260.0, "hoarse": false},
	"choke": {"name": "Würgemale", "heal": 750.0, "bed": 300.0, "speed": 0.9, "run": true, "bleed": 0.0, "hoarse": true},
}
## Beziehung, solange er verletzt ist: alles × RELATION_FACTOR, Geschenke zusätzlich × GIFT_FACTOR (zusammen ×3),
## passende noch + FITTING; ein Geschenk zählt dann wie GIFT_DEEDS für „guter Freund“
const RELATION_FACTOR := 2.0
const GIFT_FACTOR := 1.5
const FITTING := 8.0
const GIFT_DEEDS := 2
## Geschenke und Besuche lassen ihn schneller heilen (Sekunden weniger); wer befreundet ist und nie kam, kränkt ihn
const GIFT_HEAL := 60.0
const VISIT_HEAL := 20.0
const NEGLECT := -6.0
## Er erzählt es Freunden und Gästen ringsum: so viel Angst, so weit
const SPREAD_FEAR := 15.0
const SPREAD_RANGE := 15.0
## Würgemale: so oft hört man ihn schwer atmen, so weit
const WHEEZE_GAP := Vector2(5.0, 9.0)
const WHEEZE_RANGE := 5.0
## Geist-Opfer haben Angst im Dunkeln: so viel mehr Schwäche (4.18)
const CHOKE_WEAKNESS := 0.25

## Was er als Zeuge erzählt – bei jedem Gespräch das nächste Detail, alles stimmt (anders als Gerüchte, 4.13).
## {zone}: wo es passiert ist, {went}: wohin der Angreifer danach ging.
const WITNESS := {
	"scratch": [
		"Es hat mich bei {zone} gepackt und wollte mich wegschleppen. Ich hab mich losgerissen – nur ein paar Kratzer.",
		"Es war riesig. Ganz dünn, mit viel zu langen Armen. Und eine Zunge … so lang.",
		"Danach ist es Richtung {went} verschwunden. Ich hab ihm nachgesehen, bis es weg war.",
		"Wo Licht brennt und viel Deko hängt, kommt es nicht weiter. Ich hab gesehen, wie es davor stehen blieb.",
		"Es kommt aus dem Keller, glaube ich. Da unten im Heizkeller ist es zu Hause.",
	],
	"axe": [
		"Der Kürbismann! Bei {zone}! Die Axt hat mich am Bein erwischt – nicht voll, sonst wär ich tot.",
		"Er hat einen echten Kürbis als Kopf. Und er ist schnell – schneller als ich, wenn ich renne.",
		"Er will die, die Spaß haben. Wer feiert oder spielt, den holt er zuerst.",
		"Danach ist er Richtung {went} weiter. Ich hab ihn noch lange schleifen hören.",
		"Wer sich versteckt oder außer Sicht bleibt, den findet er nicht. Und den Kindern tut er nichts.",
	],
	"choke": [
		"Das Laken … es kam an mein Fenster, bei {zone}. Ich hab mich losgerissen, irgendwie.",
		"Es kommt, wenn das Licht aus ist und der Vorhang offen. Mach nie beides.",
		"Wenn jemand dazukommt, verschwindet es. Allein ist man verloren.",
		"Es sucht sich die Schwachen. Die Betrunkenen, die Ängstlichen, die nicht schlafen.",
		"Bevor es zupackt, kreist es mit den Händen. Dann wird man ganz ruhig … das ist das Schlimmste.",
	],
}
## Was Gäste weitererzählen, denen ein Überlebender davon berichtet hat ({who}, {zone}) – Erlebnis „survivor“
const HEARD := {
	"scratch": "{who} wäre bei {zone} fast geholt worden. Hat sich losgerissen – schau dir die Kratzer an!",
	"axe": "Hast du {who} gesehen? Eine Axtwunde! Bei {zone}. Der Kürbismann, sagt {who}.",
	"choke": "{who} wurde am Fenster gewürgt, bei {zone}. Hörst du, wie {who} atmet? Furchtbar.",
}
## Begrüßung, solange er verletzt ist
const GREET := {
	"scratch": ["Halb so wild. Nur Kratzer.", "Es brennt ein bisschen. Aber ich lebe."],
	"axe": ["Schön, dass du kommst. Ich kann kaum laufen.", "Pass auf mein Bein auf … setz dich."],
	"choke": ["*keucht* Danke … dass du da bist.", "*heiser* Ich krieg kaum Luft. Bleib ein bisschen."],
}
const HEALED_LINE := "Es geht wieder. Danke, dass du da warst."
const NEGLECT_LINE := "Ich lag tagelang da. Du hättest ja mal vorbeischauen können."


static func data(kind: String) -> Dictionary:
	return KINDS.get(kind, {})


## Überlebt er? (Monster, Kürbismann – beim Lakengeist entscheidet SheetGhost über das Losreißen)
static func survives() -> bool:
	return randf() < SURVIVE


## Ein passendes Geschenk für diese Verletzung? Kerze (oder geschnitzter Kürbis mit Licht) für Geist-Opfer, Süßes und
## gebratener Kürbis für die im Bett.
static func fitting(kind: String, item: Item, in_bed: bool) -> bool:
	if kind == "choke" and (item.kind == Item.Kind.CANDLE or (item.kind in Item.CANDLE_HOLDERS and item.lit)):
		return true
	return in_bed and item.kind in [Item.Kind.SWEETS, Item.Kind.ROAST_PUMPKIN]
