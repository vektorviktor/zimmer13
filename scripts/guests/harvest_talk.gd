class_name HarvestTalk
extends RefCounted
## Was Gäste von der Ernte alle drei Jahre wissen oder ahnen (Spielkonzept 2.6, 2.10; ZIM-117). Jeder Satz kommt einmal
## zu Gesprächsbeginn (Talk.greeting); dass er gesagt ist, merkt sich der Gast als Haltung „said:<id>“ (gespeichert mit
## den Haltungen), ins Notizbuch kommt eine Zeile. Texte: Vorschlag.
##   · Walter Ruprecht (H23) war erst nach der Ernte 2023 hier, in gewöhnlichen Jahren – eine falsche Fährte. Bis zur
##     Siegerehrung der erste Riss im Aushang „Wie jedes Jahr“ (2.5), nach Gustavs Tod die Direktion, die er nie gesehen
##     hat (2.6).
##   · Oskar Pohl (H39) hat 2005 überlebt und erinnert sich bruchstückhaft: je Stück ab einem Tag, höchstens eins bis zum
##     nächsten Morgen.

const WALTER := "H23"
const OSKAR := "H39"
## So lange gilt „gesagt“ (Spielzeit) – für immer
const SAID := 1.0e9
## Notiz-ID, Satz, Zeile im Notizbuch
const WALTER_CONTEST := ["walter_contest", "Wie jedes Jahr? Letztes Jahr gab's keinen. Und das Jahr davor auch nicht.",
	"Walter Ruprecht war letztes und vorletztes Jahr hier – einen Wettbewerb gab es da nicht. „Wie jedes Jahr“ stimmt nicht."]
const WALTER_DIRECTION := ["walter_direction", "Die Direktion? Hab ich nie gesehen. Läuft trotzdem wie ein Uhrwerk.",
	"Walter Ruprecht war schon öfter hier und hat die Direktion nie gesehen."]
## Oskar: ab Tag, Notiz-ID, Satz, Zeile im Notizbuch
const OSKAR_MEMORIES := [
	[3, "oskar_1", "Ich war schon einmal hier. Ich weiß nur nicht mehr, wann.",
		"Oskar Pohl meint, er sei schon einmal hier gewesen."],
	[7, "oskar_2", "Vor dem Eingang haben sie uns fotografiert. Damals auch. Alle in Reihen, die Koffer vorn.",
		"Oskar Pohl erinnert sich an ein Foto vor dem Haupteingang – „damals auch“."],
	[12, "oskar_3", "Einer hat das Tor aufgemacht. Er hatte einen Schlüssel.",
		"Oskar Pohl: Damals hat einer das Tor aufgemacht. Er hatte einen Schlüssel."],
	[18, "oskar_4", "Zwei waren nicht mehr dabei, als wir hinausgingen. Ihre Gesichter … weg.",
		"Oskar Pohl: Als sie damals hinausgingen, fehlten zwei."],
]


## Satz zu Gesprächsbeginn ("" = nichts). day < 0: heute (Debug gibt den Tag vor).
static func greeting(g: Guest, day: int = -1) -> String:
	if g.is_child() or Game.social == null:
		return ""
	if day < 0:
		day = Calendar.today()
	match String(g.profile.get("household", "")):
		WALTER:
			if day <= DoorContest.CEREMONY_DAY:
				return _once(g, WALTER_CONTEST)
			var grinch := Game.social.grinch
			if grinch and grinch.gustav and grinch.gustav.dead:
				return _once(g, WALTER_DIRECTION)
		OSKAR:
			if g.has_stance("remembered"):
				return ""
			for m: Array in OSKAR_MEMORIES:
				if day < int(m[0]):
					break
				if not g.has_stance("said:" + String(m[1])):
					var now := Game.director.elapsed if Game.director else 0.0
					g.set_stance("remembered", HotelRegister.next_morning(now) - now)
					return _once(g, m.slice(1))
	return ""


## Einmal: Satz zurück und ins Notizbuch – oder "", wenn er schon gesagt ist.
static func _once(g: Guest, line: Array) -> String:
	var key := "said:" + String(line[0])
	if g.has_stance(key):
		return ""
	g.set_stance(key, SAID)
	if Game.notebook:
		Game.notebook.add_note(String(line[0]), String(line[2]), g.display_name)
	return String(line[1])
