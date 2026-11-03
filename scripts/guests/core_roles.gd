class_name CoreRoles
## Schutz der Kernfiguren auf Zeit (Spielkonzept 6.17, geändert 2026-10-30, ZIM-120): Eine Kernfigur überlebt jeden
## Angriff jeder Bedrohung verletzt und wird nicht verurteilt (4.33) – aber nur, bis ihre Rolle in der Geschichte erfüllt
## ist, nach Fortschritt statt nach Datum. Danach gilt für sie dasselbe wie für alle Gäste. Der Schutz bleibt unsichtbar.
## Nichts Neues im Spielstand: Das Ende leitet sich aus schon gespeicherten Fortschritten ab – einer Marke, die als
## Schlüssel am Bund (Player.keyring) oder als Notiz im Notizbuch steht (beide im Spielstand), bei Marion aus dem Tag.
##   · Bruno: bis der Spieler die Hauptsicherung hat (7.4, ZIM-4) – Marke MARKS["bruno"]
##   · Edna: bis zur gezielten Bedrohung um den 20. (HANDLUNG M15, ZIM-5) – Marke MARKS["edna"]
##   · Mila: bis sie ihre Skizze des alten Herrn gezeigt hat (HANDLUNG M15c, ZIM-8) – Marke MARKS["mila"]
##   · Marion: bis Halloween (das Ritual braucht ihre Stimme, 2.8)
##   · Liesel, Oskar: Ersatzwege noch offen – vorerst geschützt (kleinste Lösung, 6.17)
##   · Hugo nicht: Ist er tot, gibt Liesel den Namen (4.32).
## Wer eine dieser Rollen baut, setzt nur noch die Marke (Player.add_key bzw. Notebook.add_note mit dieser ID).

## Kernfiguren mit eigenem Profil (GuestProfiles) bzw. aus den festen Haushalten (6.20) → Rolle
const ROLES := {
	"bruno": "bruno", "edna": "edna", "mila": "mila",
	"H22": "marion", "H26": "liesel", "H39": "oskar",
}
## Fortschrittsmarke, die das Ende des Schutzes anzeigt (Schlüssel-ID oder Notiz-ID). Noch nicht gebaut: bruno (ZIM-4),
## edna (ZIM-5), mila (ZIM-8) – solange niemand die Marke setzt, bleiben sie geschützt.
const MARKS := {
	"bruno": "hauptsicherung",
	"edna": "edna_bedrohung",
	"mila": "milas_skizze",
}
## Debug (--kernschutz): Rollen, die als erfüllt gelten, ohne dass eine Marke steht – nicht im Spielstand
static var forced_done := {}


## Die Rolle dieses Gastes ("" = keine Kernfigur mit Schutz). Kinder haben keine (6.13 – sie sind ohnehin nie Opfer).
static func role_of(g: Guest) -> String:
	if g == null or g.is_child():
		return ""
	if ROLES.has(g.id):
		return ROLES[g.id]
	return ROLES.get(String(g.profile.get("household", "")), "")


## Geschützt? Überlebt jeden Angriff verletzt und wird nicht verurteilt (4.33, 6.17). day: Spieltag (-1 = heute).
static func is_protected(g: Guest, day: int = -1) -> bool:
	var role := role_of(g)
	return role != "" and not role_done(role, day)


## Ist diese Rolle erfüllt – endet der Schutz?
static func role_done(role: String, day: int = -1) -> bool:
	if forced_done.has(role):
		return true
	match role:
		"marion":
			if day < 0:
				day = Calendar.raw_day_of(Game.director.elapsed) if Game.director else Calendar.FIRST_DAY
			return day > Calendar.HALLOWEEN
		"liesel", "oskar":
			return false   # Ersatzweg offen (6.17)
	return MARKS.has(role) and marked(String(MARKS[role]))


## Steht die Marke im Spielstand – als Schlüssel am Bund oder als Notiz im Notizbuch?
static func marked(mark: String) -> bool:
	if Game.player and Game.player.has_key(mark):
		return true
	return Game.notebook != null and Game.notebook.has_note(mark)
