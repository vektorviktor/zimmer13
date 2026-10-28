class_name BreakIn
extends Node
## Racheakt: Ein stark verfeindeter Gast bricht in Zimmer 13 ein (Spielkonzept 6.19 (1), entschieden 2026-10-26) – nur,
## wenn der Spieler nicht im Zimmer ist. Er geht hin, setzt an und bricht die Tür laut auf (wie der Spieler mit dem
## Brecheisen: FORCE_TIME, Lärm „door_force“ für Monster und Gäste; die Tür ist danach kaputt und steht offen, bis der
## Spieler sie mit dem Werkzeugkasten repariert – Door.broken). Drinnen nimmt er sich zurück, was der Spieler ihm
## genommen hat (Meta „taken_from“ aus Social.on_player_took), sonst ein Stück Deko des Spielers, sonst Geld. Dann
## liest er das Tagebuch am Schreibtisch und geht heim. Zählt als seine Rache (Taten „revenge“, 6.3).
## Wer zusieht: Sieht der Spieler es, erfährt er, wer es war; Gäste in der Nähe rufen etwas. Sonst merkt der Spieler es
## beim nächsten Betreten von Zimmer 13 (Tür, was fehlt) – wer es war, bleibt offen.
## Läuft über den Besuchsablauf (start_visit, Social.on_visit_arrived fragt on_arrived). Kind von Social:
## Game.social.break_in. Nicht gespeichert (ein Einbruch im Gang fällt beim Laden aus, „taken_from“ ebenso).

const SCAN := 10.0
## Je Blick auf einen freien Erzfeind; je Gast höchstens einmal am Tag, für alle zusammen höchstens alle GAP s
const CHANCE := 0.15
const GAP := 2.0 * Calendar.HOUR
## Aufbrechen wie mit dem Brecheisen (Door.FORCE_TIME); so lange liest er im Tagebuch (s)
const FORCE_TIME := Door.FORCE_TIME
const READ_TIME := 8.0
## Ohne Zurückzunehmendes und ohne Deko: so viel Geld
const MONEY := 5
## Zeugen unter den Gästen: so nah, mit Blick
const WITNESS_RANGE := 15.0
const SHOUT_LINES := ["Spinnst du? Das ist Zimmer 13!", "He! Was machst du da an der Tür?!", "Der bricht da ein!"]

## {guest, phase ("go", "force", "take", "read", "leave"), t, item, loot (Text, was fehlt)}
var job := {}
var _last_day := {}   ## Gast-ID → Tag des letzten Einbruchs
var _gap := 0.0
var _scan := SCAN
## Was beim nächsten Betreten von Zimmer 13 auffällt (leer: nichts)
var _notice := ""
## Debug (--einbruch): dieser Gast geht sofort
var force_id := ""


func reset() -> void:
	job.clear()
	_notice = ""


func _builder() -> LevelBuilder:
	return Game.social.builder


func _door() -> Door:
	return _builder().rooms[LevelBuilder.PLAYER_ROOM]["door"]


func _player_inside() -> bool:
	return Game.player != null and _builder().home_room_at(Game.player.global_position) == LevelBuilder.PLAYER_ROOM


func _process(delta: float) -> void:
	if Game.game_over or Game.social == null or not _builder().rooms.has(LevelBuilder.PLAYER_ROOM):
		return
	if _notice != "" and _player_inside() and job.is_empty():
		Game.say(_notice, 5.0)
		_notice = ""
	if not job.is_empty():
		_step(delta)
		return
	_gap -= delta
	_scan -= delta
	if _scan > 0.0:
		return
	_scan = SCAN
	if (_gap > 0.0 and force_id == "") or Game.social.sleep_active or (Game.monster and Game.monster.is_active()) \
			or _player_inside():
		return
	for g in Game.social.living_guests():
		var guest: Guest = g
		if _wants(guest):
			_start(guest)
			return


func _wants(g: Guest) -> bool:
	if g.is_child() or g.is_asleep() or g.hiding or g.is_following() or g.fear >= 60.0 \
			or not g.state in [Guest.State.IDLE, Guest.State.WALK] or Social.tier(g) != Social.Tier.STRONG_ENEMY:
		return false
	if g.id == force_id:
		return true
	return int(_last_day.get(g.id, -1)) != Calendar.today() and randf() < CHANCE


func _start(g: Guest) -> void:
	force_id = ""
	_last_day[g.id] = Calendar.today()
	_gap = GAP
	job = {"guest": g, "phase": "go", "t": 0.0, "item": null, "loot": ""}
	g.start_visit(_builder().rooms[LevelBuilder.PLAYER_ROOM]["door_front"])
	if Game.tracing:
		print("[Einbruch] %s macht sich auf zu Zimmer 13" % g.display_name)


## Angekommen (Social.on_visit_arrived): an der Tür, am Gegenstand, am Schreibtisch.
func on_arrived(g: Guest) -> bool:
	if job.is_empty() or job["guest"] != g:
		return false
	match String(job["phase"]):
		"go":
			if _player_inside():
				_give_up("Ein andermal.")
			elif _door().is_open:
				_enter()
			else:
				job["phase"] = "force"
				job["t"] = 0.0
				g._set_idle(FORCE_TIME + 3.0)
				Game.noise("rattle", _door().center(), g)
				if Game.tracing:
					print("[Einbruch] %s setzt an der Tür von Zimmer 13 an" % g.display_name)
		"take":
			_take()
		"read":
			job["phase"] = "reading"
			job["t"] = 0.0
			g._set_idle(READ_TIME + 3.0)
	return true


func _step(delta: float) -> void:
	var g: Guest = job["guest"]
	if not is_instance_valid(g) or g.dead:
		job.clear()
		return
	var phase := String(job["phase"])
	var waiting := phase in ["force", "reading"]
	if (waiting and g.state != Guest.State.IDLE) or (phase in ["go", "take", "read"] and g.state != Guest.State.VISIT):
		if Game.tracing:
			print("[Einbruch] %s bricht ab (%s)" % [g.display_name, phase])
		_finish(g)   # erschreckt, gerufen, das Monster … – was er schon hat, nimmt er mit
		return
	if not waiting:
		return
	job["t"] = float(job["t"]) + delta
	if phase == "force":
		if _player_inside():
			_give_up("Na warte …")
		elif float(job["t"]) >= FORCE_TIME:
			_force()
	elif float(job["t"]) >= READ_TIME:
		if Game.tracing:
			print("[Einbruch] %s hat in deinem Tagebuch gelesen" % g.display_name)
		_finish(g)


## Laut aufgebrochen: kaputt, offen, Lärm wie bei einer aufgebrochenen Tür (6.19, 5).
func _force() -> void:
	var g: Guest = job["guest"]
	var door := _door()
	door.locked = false
	door.broken = true
	door.broken_by_player = false
	door.broken_day = Calendar.today()
	door.set_open(true, true, true, g)
	Game.noise("door_force", door.center(), g)
	Game.social.add_deed(g, "revenge")
	_notice = "Die Tür von Zimmer 13 ist aufgebrochen! Jemand war hier drin."
	if Game.tracing:
		print("[Einbruch] %s bricht die Tür von Zimmer 13 auf" % g.display_name)
	_witnesses(g)
	_enter()


## Wer es sieht: Der Spieler erfährt, wer es war; Gäste rufen etwas.
func _witnesses(g: Guest) -> void:
	var p := Game.player
	if p and p.global_position.distance_to(g.global_position) < WITNESS_RANGE + 5.0 \
			and Game.director.player_can_see(g.global_position + Vector3.UP * 1.4):
		Game.say("%s bricht in dein Zimmer ein!" % g.display_name, 4.0)
		_notice = ""
	for other in Game.social.living_guests():
		var w: Guest = other
		if w != g and not w.is_asleep() and w.global_position.distance_to(g.global_position) < WITNESS_RANGE \
				and w.can_see_actor(g):
			w.say(SHOUT_LINES.pick_random())
			return


## Drinnen: zuerst, was der Spieler ihm genommen hat, sonst Deko des Spielers, sonst Geld.
func _enter() -> void:
	var g: Guest = job["guest"]
	var item := _loot_for(g)
	if item:
		job["phase"] = "take"
		job["item"] = item
		g.start_visit(item.global_position)
		return
	if Game.money > 0:
		var amount := mini(MONEY, Game.money)
		Game.money -= amount
		job["loot"] = "%d € fehlen." % amount
		if Game.tracing:
			print("[Einbruch] %s nimmt %d € aus Zimmer 13" % [g.display_name, amount])
	_to_diary()


func _loot_for(g: Guest) -> Item:
	var own: Item = null
	var deco: Item = null
	for node in get_tree().get_nodes_in_group("items"):
		var item := node as Item
		if item.is_held or item.is_queued_for_deletion() or Game.social.is_in_closed_chest(item) \
				or _builder().home_room_at(item.global_position) != LevelBuilder.PLAYER_ROOM:
			continue
		if String(item.get_meta("taken_from", "")) == g.id:
			own = item
		elif deco == null and item.deco_strength > 0.0 and item.owner_id == "player":
			deco = item
	return own if own else deco


func _take() -> void:
	var g: Guest = job["guest"]
	var item: Item = job["item"]
	if item == null or not is_instance_valid(item) or item.is_held or g.held:
		_to_diary()
		return
	var back := String(item.get_meta("taken_from", "")) == g.id
	item.remove_meta("taken_from")
	var victim := item.owner_id
	g._take_into_hand(item)
	if not back:
		Game.social.on_guest_stole(g, item, victim)
	job["loot"] = "%s fehlt." % item.display_name
	if Game.tracing:
		print("[Einbruch] %s nimmt %s %s" % [g.display_name, item.display_name, "zurück" if back else "mit"])
	_to_diary()


func _to_diary() -> void:
	var g: Guest = job["guest"]
	if Game.diary == null or not is_instance_valid(Game.diary):
		_finish(g)
		return
	var desk := Game.diary.global_position
	var center: Vector3 = _builder().rooms[LevelBuilder.PLAYER_ROOM]["center"]
	var toward := center - desk
	toward.y = 0.0
	job["phase"] = "read"
	g.start_visit(Vector3(desk.x, center.y, desk.z) + toward.normalized() * 0.7)


func _give_up(text: String) -> void:
	var g: Guest = job["guest"]
	g.say(text)
	if Game.tracing:
		print("[Einbruch] %s gibt auf – du bist im Zimmer" % g.display_name)
	_finish(g)


## Heim, mit dem, was er genommen hat (Deko stellt er vor seine Tür, anderes in den Koffer).
func _finish(g: Guest) -> void:
	var loot := String(job.get("loot", ""))
	job.clear()
	if loot != "" and _notice != "":
		_notice += " " + loot
	if not is_instance_valid(g) or g.dead or g.state in [Guest.State.SHOCKED, Guest.State.HIDE_GO, Guest.State.HIDING]:
		return
	if g.held and g.held.deco_strength > 0.0:
		g._walk_to(g.deco_place_point(), Guest.State.PLACE_DECO)
	elif g.held:
		g._walk_to(g._room_point(), Guest.State.CARRY_HOME)
	elif g.state in [Guest.State.IDLE, Guest.State.VISIT]:
		g._walk_to(g._room_point(), Guest.State.WALK)


## --einbruch=id[,eigen]: Er ist stark verfeindet und macht sich gleich auf; du stehst im Flur mit Blick auf die Tür von
## Zimmer 13. eigen: in Zimmer 13 liegt etwas, das du ihm genommen hast.
func debug(g: Guest, own: bool) -> void:
	var info: Dictionary = _builder().rooms[LevelBuilder.PLAYER_ROOM]
	var front: Vector3 = info["door_front"]
	var along: Vector3 = info["along"]
	TeleportUI.place_player(front + along * 4.0 - (info["into"] as Vector3) * 0.3, -along)
	g.global_position = front - along * 3.0 + Vector3.UP * 0.05
	g._set_idle(1.0)
	if own:
		var thing := Item.create(Item.Kind.SKULL)
		thing.owner_id = "player"
		thing.set_meta("taken_from", g.id)
		thing.position = (info["center"] as Vector3) + Vector3(0, 0.05, 0)
		Game.social._world.add_child(thing)
	force_id = g.id
	_scan = 0.5
	print("[Einbruch] Debug: %s (%s)" % [g.display_name, Social.relation_word(g.relation)])
