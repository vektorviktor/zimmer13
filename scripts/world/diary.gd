class_name Diary
extends StaticBody3D
## Das Tagebuch auf dem Schreibtisch in Zimmer 13 – der einzige Speicherpunkt
## (Spielkonzept 8.5). Fest verankert: nicht tragbar, nicht klaubar.
## Meilensteine (3.10): Wendepunkte der Geschichte – auch die dunklen Taten – sammelt note() als „noch nicht
## aufgeschrieben“; beim Speichern am Schreibtisch schreibt die Figur sie auf (write_pending), danach lassen sie sich
## nachlesen (Menus). Jeder Meilenstein einmal. Erreichbar über Game.diary; gespeichert unter „diary“.

## Meilensteine, die das Tagebuch selbst bemerkt (alle CHECK_EVERY s): Lakengeist beim Spieler, Kürbismann in Sicht
const CHECK_EVERY := 1.0
const GHOST_ENTRY := "Heute Nacht war etwas bei mir – wie ein Laken, unter dem niemand ist. Ich konnte den Blick nicht abwenden."
const PUMPKIN_ENTRY := "Heute war ein Mann im Haus, der statt eines Kopfes einen Kürbis trägt. Kein Kostüm. Die Fratze hat sich bewegt."
## Fremde Zeile beim Schreiben (MonsterDirector.strange_diary, 4.13)
const STRANGE_ENTRY := "Darunter, in fremder Schrift: »Ich sehe dir beim Schreiben zu.«"

## Dunkle Taten, die ein Einbrecher beim Lesen erfährt (8.9, ZIM-54): bestohlen, sorglos in den Tod geschickt
const DARK := ["first_theft", "careless_death"]

## aufgeschrieben: {id, at, text, foreign, who} – at = MonsterDirector.elapsed, als es geschah; who = Gast-ID, um den es
## geht (dunkle Taten, sonst "")
var entries: Array[Dictionary] = []
## geschehen, aber noch nicht aufgeschrieben
var pending: Array[Dictionary] = []

var _check := CHECK_EVERY


func _ready() -> void:
	collision_layer = 4
	collision_mask = 0
	set_meta("interactable", self)
	add_to_group("diaries")
	var cover := Mat.psx(Color(0.28, 0.1, 0.08))
	Geo.mesh(self, Geo.box(Vector3(0.24, 0.035, 0.18)), cover, Vector3(0, 0.0175, 0))
	Geo.mesh(self, Geo.box(Vector3(0.22, 0.025, 0.17)), Mat.psx(Color(0.85, 0.8, 0.65)), Vector3(0.008, 0.018, 0))
	var pen := Geo.mesh(self, Geo.cylinder(0.006, 0.14, 4), Mat.psx(Color(0.1, 0.1, 0.12)), Vector3(0.17, 0.008, 0.02))
	pen.rotation = Vector3(0, 0.4, PI / 2.0)
	Geo.add_box_shape(self, Vector3(0.3, 0.08, 0.24), Vector3(0, 0.04, 0))


func get_prompt(_player: Player) -> String:
	if not SaveManager.can_save():
		return "Tagebuch – deine Hände zittern zu sehr"
	return "Ins Tagebuch schreiben (speichern) [E]"


func interact(_player: Player) -> void:
	if not SaveManager.can_save():
		Game.say("Meine Hände zittern zu sehr.", 2.5)
		return
	if Game.menus:
		Game.menus.open_diary()


# --- Meilensteine ---------------------------------------------------------------------------

## Ein Wendepunkt ist geschehen – aufgeschrieben wird er beim nächsten Speichern. Jede id nur einmal. who: Gast-ID, um
## den es geht (dunkle Taten – das liest ein Einbrecher, BreakIn).
func note(id: String, text: String, who: String = "") -> void:
	if text == "" or has(id):
		return
	pending.append({"id": id, "at": Game.director.elapsed if Game.director else 0.0, "text": text, "foreign": false,
		"who": who})
	if Game.tracing:
		print("[Tagebuch] Meilenstein „%s“ – wird beim nächsten Speichern aufgeschrieben" % id)


## Aufgeschriebene dunkle Taten mit Betroffenem (8.9) – was noch aufs nächste Speichern wartet, steht nicht drin.
func dark_entries() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for e in entries:
		if String(e["id"]) in DARK and String(e.get("who", "")) != "":
			result.append(e)
	return result


func has(id: String) -> bool:
	for e in entries + pending:
		if e["id"] == id:
			return true
	return false


## Beim Speichern: alles seit dem letzten Mal aufschreiben, mit strange die fremde Zeile darunter. Gibt zurück, wie
## viele Einträge dazukamen (unwrite nimmt sie zurück, falls das Speichern scheitert).
func write_pending(strange: bool) -> int:
	var count := pending.size()
	entries.append_array(pending)
	pending.clear()
	if strange:
		entries.append({"id": "", "at": Game.director.elapsed if Game.director else 0.0, "text": STRANGE_ENTRY, "foreign": true,
			"who": ""})
		count += 1
	return count


func unwrite(count: int) -> void:
	for i in count:
		var e: Dictionary = entries.pop_back()
		if not e["foreign"]:
			pending.push_front(e)


func _process(delta: float) -> void:
	_check -= delta
	if _check > 0.0:
		return
	_check = CHECK_EVERY
	if Game.ghost and Game.ghost.with_player():
		note("first_ghost", GHOST_ENTRY)
	if Game.pumpkin and Game.pumpkin.in_house() and Game.director \
			and Game.director.player_can_see(Game.pumpkin.global_position + Vector3.UP * 1.6):
		note("pumpkin_man", PUMPKIN_ENTRY)


# --- Spielstand -----------------------------------------------------------------------------

func save_state() -> Dictionary:
	return {"entries": entries.duplicate(true), "pending": pending.duplicate(true)}


func load_state(d: Dictionary) -> void:
	entries.clear()
	pending.clear()
	for e: Dictionary in d.get("entries", []):
		entries.append(_entry(e))
	for e: Dictionary in d.get("pending", []):
		pending.append(_entry(e))


func _entry(e: Dictionary) -> Dictionary:
	return {"id": String(e.get("id", "")), "at": float(e.get("at", 0.0)), "text": String(e.get("text", "")),
		"foreign": bool(e.get("foreign", false)), "who": String(e.get("who", ""))}


## --notizbuch: ein paar aufgeschriebene Einträge zum Nachlesen.
func debug_fill() -> void:
	var samples := [
		[1, 15.6, "arrival", DoorContest.ARRIVAL_ENTRY],
		[2, 20.1, "first_attack", DoorContest.CEREMONY_ENTRY],
		[3, 22.4, "first_verdict", "Die Puppe saß vor Zimmer 021. An der Tür hing fast nichts."],
		[4, 1.3, "first_ghost", GHOST_ENTRY],
	]
	for s: Array in samples:
		if not has(String(s[2])):
			entries.append({"id": s[2], "at": Calendar.at(int(s[0]), float(s[1])), "text": s[3], "foreign": false, "who": ""})
	entries.append({"id": "", "at": Calendar.at(4, 1.4), "text": STRANGE_ENTRY, "foreign": true, "who": ""})
