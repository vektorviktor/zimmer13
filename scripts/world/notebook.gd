class_name Notebook
extends Node
## Das Notizbuch am Körper (Spielkonzept 3.10) – neben der Karte zwei Lesezeichen:
##   · Aufgaben: fortlaufend in der Reihenfolge, in der man sie bekommt (eingetragen beim Annehmen). Erledigt =
##     durchgestrichen, verpasst = „zu spät“, Auftraggeber tot = Kreuz neben dem Namen, die Aufgabe bleibt offen.
##     Kein Umsortieren, keine Prioritäten, keine Wegmarken – es ersetzt nur das Gedächtnis der Figur.
##   · Notizen: Durchsagen, Aushänge, Anrufe, was ein Zettel verrät – mit Uhrzeit und Quelle, nie mit Urteil.
## Liegt im Umschlag des Willkommensbriefs (DoorContest). Ohne Notizbuch wird nichts notiert. Neuer Eintrag: Kritzeln
## und „Notiert“ (Hud.show_noted). Die Seiten setzt NotebookPage, in der Hand zeigt sie PocketMap (Tab).
## Erreichbar über Game.notebook; gespeichert unter „notebook“. In der Zeitschleife (2.2) beginnt es leer.

enum TaskState { OPEN, DONE, LATE }

var owned := false
## {id, text, by, by_id, room, due, at, state, dead} – at = MonsterDirector.elapsed beim Eintragen
var tasks: Array[Dictionary] = []
## {id, text, by, at}
var notes: Array[Dictionary] = []
## zählen bei jeder Änderung hoch – PocketMap setzt die Seiten dann neu
var tasks_revision := 0
var notes_revision := 0


## Notizbuch einstecken (quiet: ohne Hinweis, z. B. beim Laden).
func give(quiet: bool = false) -> void:
	if owned:
		return
	owned = true
	tasks_revision += 1
	notes_revision += 1
	if not quiet:
		Game.say("Im Umschlag steckt ein kleines Notizbuch mit dem Hotelwappen – eingesteckt. [Tab] halten zum Ansehen, [Rechtsklick] blättert zum nächsten Lesezeichen.", 6.0)
		Game.play_sound("rustle", 0.3)


# --- Aufgaben -------------------------------------------------------------------------------

## Neue Aufgabe am Ende der Liste. id: einmalig (eine zweite mit derselben id wird übergangen), "" = immer neu.
## guest: Auftraggeber (Name, Zimmer, Kreuz bei seinem Tod) – sonst by als Quelle. due: Frist als Text.
func add_task(id: String, text: String, by: String = "", guest: Guest = null, due: String = "") -> void:
	if not owned or (id != "" and _task_index(id) >= 0):
		return
	tasks.append({"id": id, "text": text, "by": guest.display_name if guest and by == "" else by,
		"by_id": guest.id if guest else "", "room": String(guest.home["sign"]) if guest else "", "due": due,
		"at": _now(), "state": TaskState.OPEN, "dead": false})
	_tasks_changed()


## Erledigt – sobald die Figur es merkt (durchgestrichen).
func finish_task(id: String) -> void:
	_settle(id, TaskState.DONE)


## Frist verpasst („zu spät“).
func miss_task(id: String) -> void:
	_settle(id, TaskState.LATE)


func task_state(id: String) -> int:
	var i := _task_index(id)
	return int(tasks[i]["state"]) if i >= 0 else -1


## Ein Gast ist tot: Kreuz neben seinem Namen bei jeder seiner Aufgaben – offen bleibt offen.
func on_guest_died(guest: Guest) -> void:
	var any := false
	for task in tasks:
		if task["by_id"] == guest.id and not task["dead"]:
			task["dead"] = true
			any = true
	if any:
		_tasks_changed()


func _settle(id: String, state: TaskState) -> void:
	var i := _task_index(id)
	if i < 0 or int(tasks[i]["state"]) != TaskState.OPEN:
		return
	tasks[i]["state"] = state
	_tasks_changed()


func _task_index(id: String) -> int:
	for i in tasks.size():
		if tasks[i]["id"] == id:
			return i
	return -1


# --- Notizen --------------------------------------------------------------------------------

## Neue Notiz mit Uhrzeit. id: einmalig (Aushang, Zettel – beim zweiten Lesen nichts Neues), "" = immer neu.
func add_note(id: String, text: String, by: String = "") -> void:
	if not owned or text == "" or (id != "" and has_note(id)):
		return
	notes.append({"id": id, "text": text, "by": by, "at": _now()})
	notes_revision += 1
	_scribble()


func has_note(id: String) -> bool:
	for note in notes:
		if note["id"] == id:
			return true
	return false


# --- Intern ---------------------------------------------------------------------------------

func _tasks_changed() -> void:
	tasks_revision += 1
	_scribble()


func _scribble() -> void:
	if Game.hud:
		Game.hud.show_noted()
	Game.play_sound("rustle", 0.15)


func _now() -> float:
	return Game.director.elapsed if Game.director else 0.0


# --- Spielstand -----------------------------------------------------------------------------

func save_state() -> Dictionary:
	return {"owned": owned, "tasks": tasks.duplicate(true), "notes": notes.duplicate(true)}


## Ältere Stände ohne „notebook“: Wer den Brief gelesen hat, hat das Notizbuch (leer).
func load_state(d: Dictionary, letter_read: bool) -> void:
	owned = bool(d.get("owned", letter_read))
	tasks.clear()
	for t: Dictionary in d.get("tasks", []):
		tasks.append({"id": String(t.get("id", "")), "text": String(t.get("text", "")), "by": String(t.get("by", "")),
			"by_id": String(t.get("by_id", "")), "room": String(t.get("room", "")), "due": String(t.get("due", "")),
			"at": float(t.get("at", 0.0)), "state": int(t.get("state", TaskState.OPEN)), "dead": bool(t.get("dead", false))})
	notes.clear()
	for n: Dictionary in d.get("notes", []):
		notes.append({"id": String(n.get("id", "")), "text": String(n.get("text", "")), "by": String(n.get("by", "")),
			"at": float(n.get("at", 0.0))})
	tasks_revision += 1
	notes_revision += 1


# --- Debug ----------------------------------------------------------------------------------

## --notizbuch: Notizbuch mit Beispielen über drei Tage – jede Art von Aufgabe (offen, erledigt, zu spät, Auftraggeber
## tot) und von Notiz, dazu ein paar Einträge im Tagebuch. Echte Gäste als Auftraggeber, keiner stirbt dabei.
func debug_fill() -> void:
	give(true)
	var guests := Game.social.living_guests().filter(func(g: Guest) -> bool: return not g.is_child()) if Game.social else []
	var who := func(i: int) -> Guest: return guests[i % guests.size()] if not guests.is_empty() else null
	var samples := [
		[1, 15.6, "task", "contest", "Meine Tür schmücken", "Direktion", null, "bis 2. Okt., 20 Uhr", TaskState.DONE, false],
		[1, 15.5, "note", "Durchsage", "Willkommen. Türschmuck-Wettbewerb: Die Jury kürt morgen um 20 Uhr in der Lobby die schönste Tür."],
		[1, 16.2, "note", "Brett in der Lobby", "Hausordnung: Nachtruhe 23–6 Uhr, die Bar schließt um Mitternacht, der Haupteingang bleibt nachts zu."],
		[1, 19.0, "task", "", "Eine Kerze bringen", "", who.call(0), "vor der Nachtruhe", TaskState.DONE, false],
		[2, 10.5, "task", "", "Nach der Katze sehen – seit gestern weg", "", who.call(1), "", TaskState.OPEN, true],
		[2, 12.0, "note", "Durchsage", "Noch acht Stunden bis zur Siegerehrung."],
		[2, 14.3, "task", "", "Eine Glühbirne für die Lampe im Bad besorgen", "", who.call(2), "bis zur Feier", TaskState.LATE, false],
		[2, 19.75, "note", "Durchsage", "Die Jury bittet in einer Viertelstunde in die Lobby."],
		[3, 7.0, "note", "M. B., Zi. 021, 1999", "Die Puppe sitzt vor der Tür, an der am wenigsten hängt. Wer dann drin ist, kommt nicht mehr heraus."],
		[3, 9.4, "note", "Brett in der Lobby", "Der Aushang ist ein anderer: Die Jury besucht jetzt die Tür, die am wenigsten zu bieten hat."],
		[3, 18.2, "task", "", "Bei der Bar auf jemanden warten, der sich nicht allein durch den Flur traut", "", who.call(3), "heute Abend", TaskState.OPEN, false],
		[3, 23.6, "note", "Telefon", "Anruf aus Zimmer 018. Nur Atmen."],
	]
	for s: Array in samples:
		var at := Calendar.at(int(s[0]), float(s[1]))
		if s[2] == "note":
			notes.append({"id": "", "text": s[4], "by": s[3], "at": at})
			continue
		var g: Guest = s[6]
		tasks.append({"id": s[3], "text": s[4], "by": g.display_name if g else String(s[5]), "by_id": g.id if g else "",
			"room": String(g.home["sign"]) if g else "", "due": s[7], "at": at, "state": s[8], "dead": s[9]})
	tasks_revision += 1
	notes_revision += 1
	if Game.diary:
		Game.diary.debug_fill()
