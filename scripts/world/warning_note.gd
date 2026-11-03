class_name WarningNote
extends StaticBody3D
## Warnungszettel früherer Gäste, die es nicht hinausgeschafft haben (Spielkonzept 4.13) – je aus einem Erntejahr (2.10).
## Tipps zum Monster und eine Andeutung zum Schlüssel an Halloween – zugleich der
## Story-Faden. Sie tauchen erst nach dem ersten Angriff auf (vorher ist alles friedlich).
## Unter UV-Licht zeigt jeder feste Zettel eine zweite, unsichtbare Zeile („uv“, 4.16).

const NOTES := {
	"1987": {"title": "Zettel, Oktober 1987",
		"text": "Wer das liest: Lass das Licht an. Immer. Es kommt nur, wo es dunkel ist.\nIch habe die Birne in meinem Zimmer verloren. Jetzt wird es nachts warm vor meiner Tür, und in den Rohren atmet etwas. Gesehen hat es keiner. Aber beim Frühstück fehlen jeden Tag mehr.\n– E. K., Zimmer 017",
		"uv": "Der Hausmeister war noch unten, als sie die Tür abgeschlossen haben. Ich habe den Schlüssel klirren hören.",
		"by": "E. K., Zi. 017, 1987", "jot": "Licht anlassen, immer – es kommt nur, wo es dunkel ist."},
	"1993": {"title": "Zerknitterte Seite, 1993",
		"text": "Redet nicht über ES. Es hört zu. Jedes Mal, wenn wir in der Lobby darüber geflüstert haben, kam es näher.\nUnd wenn das Rauschen anfängt – nicht rennen. Verstecken. Aber nur, wenn es dich nicht sieht.
Flackert das Licht im ganzen Haus lange, geh nicht mehr raus. Dann holt es mehr als einen.",
		"uv": "Wo die Kerzen ausgehen, ist es gerade vorbeigegangen. Zähl sie.",
		"by": "Zettel von 1993", "jot": "Nicht über ES reden, es hört zu. Beim Rauschen nicht rennen – verstecken. Flackert es lange im ganzen Haus: drinbleiben."},
	# Liegt am Morgen nach der Siegerehrung hinter der Tür von Zimmer 13 (Spielkonzept 2.5, DoorContest)
	"1999": {"title": "Vergilbter Zettel, 1999",
		"text": "Uns haben sie auch einen Wettbewerb versprochen. Einen Sieger gab es nie.\nDie Puppe sitzt vor der Tür, an der am wenigsten hängt. Wer dann in dem Zimmer ist, kommt nicht mehr heraus.\nSchmück mehr als die anderen. Und wenn sie doch vor deiner sitzt – geh woanders hin.\n– M. B., Zimmer 021",
		"uv": "Wer schmückt, ist Gastgeber. Wer nicht, ist die Gabe.",
		"by": "M. B., Zi. 021, 1999", "jot": "Die Puppe sitzt vor der Tür, an der am wenigsten hängt. Wer dann drin ist, kommt nicht mehr heraus."},
	"2005": {"title": "Notiz unter der Matratze",
		"text": "Es hat an meine Tür geklopft. Mit der Stimme meiner Schwester.\nMeine Schwester ist seit drei Tagen fort.\nWENN DU DIE STIMME KENNST – MACH NICHT AUF.",
		"uv": "Im Gästebuch steht hinter jedem Namen ein Datum. Hinter manchen ein Kreuz.",
		"by": "Zettel von 2005", "jot": "Klopft es mit einer Stimme, die ich kenne – nicht aufmachen."},
	"2011": {"title": "Seite aus einem Tagebuch, 2011",
		"text": "31. Oktober. Ich habe ihn gesehen: den Schlüssel. Er lag einfach da, als hätte er schon immer dort gelegen.\nAber ES lag daneben. Und ich war zu langsam.\nWer auch immer das findet: Du brauchst die anderen. Allein schaffst du es nicht.",
		"uv": "Der Schlüssel lag im Keller. Ganz unten. Wo es warm ist.",
		"by": "Tagebuchseite, 2011", "jot": "Am 31. lag der Schlüssel einfach da – aber ES daneben. Allein schafft man es nicht."},
	"2020": {"title": "Handschrift auf einer Serviette",
		"text": "Die ersten Male tut es dir nichts. Es will nur, dass du es siehst.\nDanach ist es anders. Danach nimmt es jemanden mit.\nVerlass dich nicht darauf, dass es dich verschont.",
		"uv": "Es hasst dieses Licht. Aber es merkt sich, wer es damit geblendet hat.",
		"by": "Serviette, 2020", "jot": "Die ersten Male tut es nichts. Danach nimmt es jemanden mit."},
}

var note_id := "1987"
## Zettel eines Gastes (statt eines festen Texts aus NOTES) – sofort sichtbar
var custom_title := ""
var custom_text := ""
## Codezettel zu einem Stahlspind (Slice „Code: <Name>“, SK 7.18, ZIM-174) – sofort sichtbar, Text aus
## SteelLocker.code_note
var code_name := ""


func setup(p_id: String) -> WarningNote:
	note_id = p_id
	return self


func setup_custom(title: String, text: String) -> WarningNote:
	note_id = ""
	custom_title = title
	custom_text = text
	return self


func setup_code(p_name: String) -> WarningNote:
	note_id = "code:" + p_name
	code_name = p_name
	return self


func _ready() -> void:
	collision_layer = 0
	collision_mask = 0
	set_meta("interactable", self)
	add_to_group("guest_notes" if note_id == "" else ("code_notes" if code_name != "" else "warning_notes"))
	var paper := Geo.mesh(self, Geo.box(Vector3(0.16, 0.004, 0.21)), Mat.psx(Color(0.82, 0.78, 0.66)), Vector3(0, 0.002, 0))
	paper.rotation.y = randf_range(-0.4, 0.4)
	Geo.mesh(self, Geo.box(Vector3(0.11, 0.005, 0.005)), Mat.psx(Color(0.25, 0.15, 0.1)), Vector3(0, 0.004, -0.04))
	Geo.mesh(self, Geo.box(Vector3(0.12, 0.005, 0.005)), Mat.psx(Color(0.25, 0.15, 0.1)), Vector3(0, 0.004, 0.0))
	Geo.add_box_shape(self, Vector3(0.24, 0.06, 0.26), Vector3(0, 0.03, 0))
	visible = false


func _process(_delta: float) -> void:
	var always := note_id == "" or code_name != ""
	var shown := always or (Game.director != null and Game.director.first_attack_done)
	if shown != visible:
		visible = shown
		collision_layer = 4 if shown else 0
	if always:
		set_process(false)   # Zettel eines Gastes, Codezettel: immer sichtbar, nichts mehr zu prüfen


func get_prompt(player: Player) -> String:
	return "Zettel lesen [E] – etwas schimmert" if _uv_text(player) != "" else "Zettel lesen [E]"


func interact(player: Player) -> void:
	if code_name != "":   # Codezettel: Ort des Spinds und Code, ins Notizbuch
		var slip := SteelLocker.code_note(code_name)
		if slip.is_empty():
			return
		if Game.menus:
			Game.menus.open_note(String(slip["title"]), String(slip["text"]))
		if Game.notebook:
			Game.notebook.add_note(note_id, String(slip["jot"]), "Zettel")
		return
	var note: Dictionary = NOTES.get(note_id, {}) if note_id != "" else {"title": custom_title, "text": custom_text}
	if Game.menus and not note.is_empty():
		var text := String(note["text"])
		var hidden := _uv_text(player)
		if hidden != "":
			text += "\n\n[Im UV-Licht, zwischen den Zeilen:]\n" + hidden
		Game.menus.open_note(String(note["title"]), text)
	if Game.notebook and note_id != "":   # was der Zettel verrät, als eine Zeile mit Quelle (3.10)
		var by := String(note.get("by", ""))
		Game.notebook.add_note("note_" + note_id, String(note.get("jot", "")), by)
		if _uv_text(player) != "":
			Game.notebook.add_note("note_%s_uv" % note_id, "Im UV-Licht: " + _uv_text(player), by)


## Die unsichtbare Zeile – nur, wenn der Spieler mit eingeschaltetem UV-Licht liest.
func _uv_text(player: Player) -> String:
	if note_id == "" or player == null or player.held == null or player.held.flashlight == null:
		return ""
	var lamp := player.held.flashlight
	if not (lamp.on and lamp.uv_mode):
		return ""
	return String(NOTES.get(note_id, {}).get("uv", ""))
