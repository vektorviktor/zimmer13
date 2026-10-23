extends Node
## Notizbuch und Tagebuch (Spielkonzept 3.10) ohne Hotel: Aufgaben (einmalig, erledigt/zu spät nur aus offen, Kreuz beim
## Tod des Auftraggebers), Notizen (einmalig je id, ohne Notizbuch nichts), Seiten setzen (Tageskopf, keine Leerzeile oben,
## Tag auf neuer Seite wiederholt, nichts geht verloren), Brief → Notizbuch und erste Aufgabe, Meilensteine (einmal,
## aufschreiben, zurücknehmen) und Spielstand über JSON. Läuft über tests/run.tscn (braucht die Autoloads).

var _ok := true
var _book: Notebook
var _diary: Diary


func run() -> bool:
	_book = Notebook.new()
	add_child(_book)
	_diary = Diary.new()
	_diary.process_mode = Node.PROCESS_MODE_DISABLED
	add_child(_diary)
	var old_book := Game.notebook
	var old_diary := Game.diary
	Game.notebook = _book
	Game.diary = _diary
	_tasks()
	_notes()
	_pages()
	_letter()
	_milestones()
	_save()
	Game.notebook = old_book
	Game.diary = old_diary
	_book.queue_free()
	_diary.queue_free()
	print("Notizbuch: alles richtig" if _ok else "Notizbuch: FEHLER")
	return _ok


func _check(good: bool, text: String) -> void:
	print(("ok      " if good else "FALSCH  ") + text)
	_ok = _ok and good


func _guest(id: String, name: String, sign: String) -> Guest:
	var g := Guest.new()
	g.id = id
	g.display_name = name
	g.home = {"sign": sign}
	return g


func _tasks() -> void:
	_book.add_task("vorher", "Ohne Notizbuch")
	_check(_book.tasks.is_empty(), "ohne Notizbuch wird nichts notiert")
	_book.give(true)
	var edna := _guest("edna", "Edna", "021")
	_book.add_task("kerze", "Eine Kerze bringen", "", edna, "vor der Nachtruhe")
	_book.add_task("kerze", "Noch einmal dieselbe")
	_book.add_task("", "Ohne id 1")
	_book.add_task("", "Ohne id 2")
	_check(_book.tasks.size() == 3, "gleiche id nur einmal, ohne id immer neu (%d Aufgaben)" % _book.tasks.size())
	var t: Dictionary = _book.tasks[0]
	_check(t["by"] == "Edna" and t["room"] == "021" and t["by_id"] == "edna", "Auftraggeber mit Name und Zimmer")
	_book.finish_task("kerze")
	_book.miss_task("kerze")
	_check(_book.task_state("kerze") == Notebook.TaskState.DONE, "erledigt bleibt erledigt (kein „zu spät“ danach)")
	_book.add_task("birne", "Glühbirne", "", edna)
	_book.on_guest_died(edna)
	_check(_book.tasks[0]["dead"] and _book.tasks[3]["dead"] and _book.task_state("birne") == Notebook.TaskState.OPEN,
		"Tod des Auftraggebers: Kreuz bei jeder seiner Aufgaben, offen bleibt offen")
	_book.miss_task("birne")
	_check(_book.task_state("birne") == Notebook.TaskState.LATE, "verpasst = zu spät")
	_check(_book.task_state("gibtsnicht") == -1, "unbekannte Aufgabe: -1")
	edna.free()


func _notes() -> void:
	var before := _book.notes.size()
	_book.add_note("brett", "Hausordnung", "Brett")
	_book.add_note("brett", "Hausordnung", "Brett")
	_book.add_note("", "Durchsage 1", "Durchsage")
	_book.add_note("", "Durchsage 1", "Durchsage")
	_book.add_note("", "")
	_check(_book.notes.size() == before + 3, "Notiz mit id einmal, ohne id immer, leere nie (%d neu)" % (_book.notes.size() - before))


func _pages() -> void:
	var entries: Array = []
	for day in [1, 1, 2, 2, 2, 3, 3, 3, 3, 4, 4, 5]:
		entries.append({"text": "Ein ziemlich langer Text, damit er umbricht und mehr als eine Zeile braucht – Tag %d" % day,
			"by": "Jemand", "at": Calendar.at(day, 16.0)})
	var pages := NotebookPage.paginate("notes", entries)
	var rows := 0
	var heads_ok := true
	var top_ok := true
	var fits := true
	for page: Array in pages:
		fits = fits and page.size() <= NotebookPage.ROWS
		top_ok = top_ok and not page.is_empty() and String(page[0]["t"]) != ""
		heads_ok = heads_ok and page[0]["day"]
		for r: Dictionary in page:
			rows += 1 if String(r["t"]).begins_with("16:") else 0
	_check(pages.size() > 1 and fits, "auf %d Seiten verteilt, keine zu voll" % pages.size())
	_check(top_ok and heads_ok, "jede Seite beginnt mit dem Tag, nie mit einer Leerzeile")
	_check(rows == entries.size(), "jeder Eintrag steht drin (%d von %d)" % [rows, entries.size()])
	var empty := NotebookPage.paginate("tasks", [])
	_check(empty.size() == 1 and (empty[0] as Array).is_empty(), "ohne Einträge eine leere Seite")
	var one := NotebookPage.paginate("tasks", [{"text": "Tür schmücken", "by": "Direktion", "room": "", "due": "bis 20 Uhr",
		"at": 0.0, "state": Notebook.TaskState.DONE, "dead": false}])
	var page: Array = one[0]
	_check(page.size() == 3 and page[1]["strike"] and not page[2]["strike"] and page[2]["t"] == "Direktion · bis 20 Uhr",
		"Aufgabe: Tag, durchgestrichene Zeile, darunter Quelle und Frist")


func _letter() -> void:
	var book := Notebook.new()
	add_child(book)
	Game.notebook = book
	var contest := DoorContest.new()
	add_child(contest)
	contest.on_letter_read()
	_check(book.owned and book.task_state(DoorContest.TASK_ID) == Notebook.TaskState.OPEN,
		"Brief gelesen: Notizbuch eingesteckt, erste Aufgabe offen")
	_check(_diary.has("arrival"), "Brief gelesen: Ankunft als Meilenstein")
	book.queue_free()
	contest.queue_free()
	Game.notebook = _book


func _milestones() -> void:
	_diary.note("tod", "Jemand ist tot.")
	_diary.note("tod", "Noch einmal.")
	var pending := _diary.pending.size()
	_check(_diary.pending.filter(func(e: Dictionary) -> bool: return e["id"] == "tod").size() == 1, "Meilenstein nur einmal")
	var n := _diary.write_pending(true)
	_check(n == pending + 1 and _diary.pending.is_empty() and _diary.entries.back()["foreign"],
		"beim Speichern aufgeschrieben, die fremde Zeile darunter")
	_diary.note("tod", "Nach dem Aufschreiben")
	_check(_diary.pending.is_empty(), "aufgeschrieben zählt auch als schon geschehen")
	_diary.unwrite(n)
	_check(_diary.pending.size() == pending and _diary.entries.is_empty(), "Speichern gescheitert: wieder offen, ohne fremde Zeile")
	_diary.write_pending(false)


func _save() -> void:
	var data: Dictionary = JSON.parse_string(JSON.stringify({"n": _book.save_state(), "d": _diary.save_state()}))
	var book := Notebook.new()
	add_child(book)
	book.load_state(data["n"], false)
	_check(book.owned and book.save_state() == _book.save_state(), "Notizbuch: Laden ergibt dasselbe")
	var diary := Diary.new()
	diary.process_mode = Node.PROCESS_MODE_DISABLED
	add_child(diary)
	diary.load_state(data["d"])
	_check(diary.save_state() == _diary.save_state(), "Tagebuch: Laden ergibt dasselbe")
	var old := Notebook.new()
	add_child(old)
	old.load_state({}, true)
	_check(old.owned and old.tasks.is_empty(), "älterer Stand ohne Notizbuch, Brief gelesen: leeres Notizbuch")
	for node: Node in [book, diary, old]:
		node.queue_free()
