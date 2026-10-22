class_name WarningNote
extends StaticBody3D
## Warnungszettel früherer Gäste, die es nicht hinausgeschafft haben (Spielkonzept 4.13).
## Tipps zum Monster und eine Andeutung zum Schlüssel an Halloween – zugleich der
## Story-Faden. Sie tauchen erst nach dem ersten Angriff auf (vorher ist alles friedlich).
## Unter UV-Licht zeigt jeder feste Zettel eine zweite, unsichtbare Zeile („uv“, 4.16).

const NOTES := {
	"1987": {"title": "Zettel, Oktober 1987",
		"text": "Wer das liest: Lass das Licht an. Immer. Es kommt nur, wo es dunkel ist.\nIch habe die Birne in meinem Zimmer verloren. Jetzt höre ich es jede Nacht vor der Tür.\n– E. K., Zimmer 0117",
		"uv": "Der Heizer war noch unten, als sie die Tür abgeschlossen haben. Ich habe den Schlüssel klirren hören."},
	"1994": {"title": "Zerknitterte Seite, 1994",
		"text": "Redet nicht über ES. Es hört zu. Jedes Mal, wenn wir in der Lobby darüber geflüstert haben, kam es näher.\nUnd wenn das Rauschen anfängt – nicht rennen. Verstecken. Aber nur, wenn es dich nicht sieht.
Flackert das Licht im ganzen Haus lange, geh nicht mehr raus. Dann holt es mehr als einen.",
		"uv": "Wo die Kerzen ausgehen, ist es gerade vorbeigegangen. Zähl sie."},
	"2003": {"title": "Notiz unter der Matratze",
		"text": "Es hat an meine Tür geklopft. Mit der Stimme meiner Schwester.\nMeine Schwester ist seit drei Tagen fort.\nWENN DU DIE STIMME KENNST – MACH NICHT AUF.",
		"uv": "Im Gästebuch steht hinter jedem Namen ein Datum. Hinter manchen ein Kreuz."},
	"2011": {"title": "Seite aus einem Tagebuch, 2011",
		"text": "31. Oktober. Ich habe ihn gesehen: den Schlüssel. Er lag einfach da, als hätte er schon immer dort gelegen.\nAber ES lag daneben. Und ich war zu langsam.\nWer auch immer das findet: Du brauchst die anderen. Allein schaffst du es nicht.",
		"uv": "Der Schlüssel lag im Keller. Ganz unten. Wo es warm ist."},
	"2019": {"title": "Handschrift auf einer Serviette",
		"text": "Die ersten Male tut es dir nichts. Es will nur, dass du es siehst.\nDanach ist es anders. Danach nimmt es jemanden mit.\nVerlass dich nicht darauf, dass es dich verschont.",
		"uv": "Es hasst dieses Licht. Aber es merkt sich, wer es damit geblendet hat."},
}

var note_id := "1987"
## Zettel eines Gastes (statt eines festen Texts aus NOTES) – sofort sichtbar
var custom_title := ""
var custom_text := ""


func setup(p_id: String) -> WarningNote:
	note_id = p_id
	return self


func setup_custom(title: String, text: String) -> WarningNote:
	note_id = ""
	custom_title = title
	custom_text = text
	return self


func _ready() -> void:
	collision_layer = 0
	collision_mask = 0
	set_meta("interactable", self)
	add_to_group("guest_notes" if note_id == "" else "warning_notes")
	var paper := Geo.mesh(self, Geo.box(Vector3(0.16, 0.004, 0.21)), Mat.psx(Color(0.82, 0.78, 0.66)), Vector3(0, 0.002, 0))
	paper.rotation.y = randf_range(-0.4, 0.4)
	Geo.mesh(self, Geo.box(Vector3(0.11, 0.005, 0.005)), Mat.psx(Color(0.25, 0.15, 0.1)), Vector3(0, 0.004, -0.04))
	Geo.mesh(self, Geo.box(Vector3(0.12, 0.005, 0.005)), Mat.psx(Color(0.25, 0.15, 0.1)), Vector3(0, 0.004, 0.0))
	Geo.add_box_shape(self, Vector3(0.24, 0.06, 0.26), Vector3(0, 0.03, 0))
	visible = false


func _process(_delta: float) -> void:
	var shown := note_id == "" or (Game.director != null and Game.director.first_attack_done)
	if shown != visible:
		visible = shown
		collision_layer = 4 if shown else 0
	if note_id == "":
		set_process(false)   # Zettel eines Gastes: immer sichtbar, nichts mehr zu prüfen


func get_prompt(player: Player) -> String:
	return "Zettel lesen [E] – etwas schimmert" if _uv_text(player) != "" else "Zettel lesen [E]"


func interact(player: Player) -> void:
	var note: Dictionary = NOTES.get(note_id, {}) if note_id != "" else {"title": custom_title, "text": custom_text}
	if Game.menus and not note.is_empty():
		var text := String(note["text"])
		var hidden := _uv_text(player)
		if hidden != "":
			text += "\n\n[Im UV-Licht, zwischen den Zeilen:]\n" + hidden
		Game.menus.open_note(String(note["title"]), text)


## Die unsichtbare Zeile – nur, wenn der Spieler mit eingeschaltetem UV-Licht liest.
func _uv_text(player: Player) -> String:
	if note_id == "" or player == null or player.held == null or player.held.flashlight == null:
		return ""
	var lamp := player.held.flashlight
	if not (lamp.on and lamp.uv_mode):
		return ""
	return String(NOTES.get(note_id, {}).get("uv", ""))
