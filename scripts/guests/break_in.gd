class_name BreakIn
extends Node
## Racheakt: Ein stark verfeindeter Gast bricht in Zimmer 13 ein (Spielkonzept 6.19 (1), entschieden 2026-10-26) – nur,
## wenn der Spieler nicht im Zimmer ist. Er geht hin, setzt an und bricht die Tür laut auf (wie der Spieler mit dem
## Brecheisen: FORCE_TIME, Lärm „door_force“ für Monster und Gäste; die Tür ist danach kaputt und steht offen, bis der
## Spieler sie mit dem Werkzeugkasten repariert – Door.broken). Drinnen nimmt er sich zurück, was der Spieler ihm
## genommen hat (Meta „taken_from“ aus Social.on_player_took), sonst ein Stück Deko des Spielers, sonst Geld. Dann
## liest er das Tagebuch am Schreibtisch und geht heim. Zählt als seine Rache (Taten „revenge“, 6.3).
## Wer zusieht: Sieht der Spieler es, erfährt er, wer es war; Gäste in der Nähe rufen etwas. Sonst merkt der Spieler es
## beim nächsten Betreten von Zimmer 13 (Tür, was fehlt) – wer es war, bleibt offen, außer ein Zeuge sagt es ihm.
## Zeugen (ZIM-54, entschieden 2026-11-03, spiegelt 6.19 (5)): werten es als feindselige Tat des Einbrechers – sie
## trauen ihm nicht mehr (Haltung „distrusts:<id>“ wie nach einem geglaubten Diebstahl, 6.9; keine Freunde mehr) – und
## nennen dir beim nächsten Gespräch den Namen (Haltung „saw_break_in“, Talk.greeting; ins Notizbuch).
## Tagebuch (8.9, ZIM-54): Was aufgeschrieben ist (Diary.dark_entries – bestohlen, sorglos in den Tod geschickt),
## erfährt er und erzählt es übers Freundesnetz weiter; die Betroffenen (der Bestohlene bzw. Freunde und Familie des
## Toten) sucht er selbst auf, sie trifft es härter (GuestPals.spread_with_affected). Jeden Eintrag nur einmal je Gast.
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
## So lange merkt sich ein Zeuge den Namen fürs nächste Gespräch (s)
const WITNESS_MEMORY := 3.0 * Calendar.DAY_SECONDS
## Tagebuch: Gerede übers Netz (wie ein gesehener Schlüsseldiebstahl), die Betroffenen trifft es voll; so lange weiß der
## Einbrecher, was er gelesen hat (s)
const DIARY_GOSSIP := -8.0
const DIARY_AFFECTED := -15.0
const READ_MEMORY := 31.0 * Calendar.DAY_SECONDS

## {guest, phase ("go", "force", "take", "read", "leave"), t, item, loot (Text, was fehlt)}
var job := {}
var _last_day := {}   ## Gast-ID → Tag des letzten Einbruchs
var _gap := 0.0
var _scan := SCAN
## Was beim nächsten Betreten von Zimmer 13 auffällt (leer: nichts)
var _notice := ""
## Debug (--einbruch): dieser Gast geht sofort
var force_id := ""
## Debug (--einbruch=…,tagebuch): dieser Gast trifft den Einbrecher, sobald der gelesen hat
var debug_meet: Guest


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
		_read_diary(g)
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


## Wer es sieht: Der Spieler erfährt, wer es war; Gäste rufen etwas, trauen ihm nicht mehr und sagen es dir später.
func _witnesses(g: Guest) -> void:
	var p := Game.player
	if p and p.global_position.distance_to(g.global_position) < WITNESS_RANGE + 5.0 \
			and Game.director.player_can_see(g.global_position + Vector3.UP * 1.4):
		Game.say("%s bricht in dein Zimmer ein!" % g.display_name, 4.0)
		_notice = ""
	var shouted := false
	for other in Game.social.living_guests():
		var w: Guest = other
		if w != g and not w.is_asleep() and w.global_position.distance_to(g.global_position) < WITNESS_RANGE \
				and w.can_see_actor(g):
			if not shouted:
				w.say(SHOUT_LINES.pick_random())
				shouted = true
			w.set_stance("distrusts:" + g.id, Talk.STANCE_TIME)
			w.set_stance("saw_break_in", WITNESS_MEMORY, {"who": g.id})
			if Game.tracing:
				print("[Einbruch] %s hat es gesehen und traut %s nicht mehr" % [w.display_name, g.display_name])


## Er hat das Tagebuch gelesen: Was dort an dunklen Taten steht, erzählt er weiter (8.9) – jeden Eintrag einmal.
func _read_diary(g: Guest) -> void:
	if Game.diary == null or not is_instance_valid(Game.diary):
		return
	var pals := Game.social.pals
	for e in Game.diary.dark_entries():
		var key := "read:" + String(e["id"])
		if g.has_stance(key):
			continue
		g.set_stance(key, READ_MEMORY)
		var who := Game.social.guest_by_id(String(e["who"]))
		var affected: Array = []
		if who and String(e["id"]) == "first_theft":
			affected.append(who)   # der Bestohlene
		elif who:
			affected.append_array(pals.pals_of(who))   # Freunde und Familie des Toten
		affected.erase(g)
		pals.spread_with_affected(g, DIARY_GOSSIP, affected, DIARY_AFFECTED)
		if Game.tracing:
			print("[Einbruch] %s liest „%s“ und erzählt es weiter – Betroffene: %s" % [g.display_name, e["text"],
				", ".join(affected.map(func(a: Guest) -> String: return a.display_name))])
	if debug_meet and is_instance_valid(debug_meet) and not debug_meet.dead:
		var victim := debug_meet
		debug_meet = null
		victim.global_position = g.global_position + g.global_transform.basis.x * 1.2
		victim._set_idle(30.0)
		pals._update_net()   # sie treffen sich gleich
		print("[Einbruch] %s erfährt es vom Einbrecher: %.0f – %s" % [victim.display_name, victim.relation,
			"ok" if victim.relation <= DIARY_AFFECTED * 0.9 else "FEHLER"])


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


## --einbruch=id[,eigen|tagebuch|zeuge]: Er ist stark verfeindet und macht sich gleich auf; du stehst im Flur mit Blick
## auf die Tür von Zimmer 13. eigen: in Zimmer 13 liegt etwas, das du ihm genommen hast · tagebuch: im Tagebuch steht,
## dass du einem anderen Gast etwas genommen hast – der trifft den Einbrecher, sobald der gelesen hat · zeuge: ein anderer
## Gast steht neben der Tür und sieht zu; 30 s später beginnt ein Gespräch mit ihm (Talk.greeting).
func debug(g: Guest, what: String) -> void:
	var info: Dictionary = _builder().rooms[LevelBuilder.PLAYER_ROOM]
	var front: Vector3 = info["door_front"]
	var along: Vector3 = info["along"]
	TeleportUI.place_player(front + along * 4.0 - (info["into"] as Vector3) * 0.3, -along)
	g.global_position = front - along * 3.0 + Vector3.UP * 0.05
	g._set_idle(1.0)
	var other: Guest = null
	for o in Game.social.living_guests():
		var cand: Guest = o
		if cand != g and not cand.is_child() and not cand.housemate_of(g) and String(cand.home["no"]) != LevelBuilder.PLAYER_ROOM:
			other = cand
			break
	if other and what == "tagebuch":
		Game.diary.note("first_theft", "Ich habe %s etwas weggenommen. Ich brauche es dringender, rede ich mir ein." % other.display_name,
			other.id)
		Game.diary.write_pending(false)
		other.relation = 0.0
		debug_meet = other
		print("[Einbruch] Debug: im Tagebuch steht der Diebstahl bei %s" % other.display_name)
	elif other and what == "zeuge":
		other.global_position = front + along * 2.0 + Vector3.UP * 0.05
		other._set_idle(60.0)
		other.look_at(Vector3(front.x, other.global_position.y, front.z) - along * 0.5)
		print("[Einbruch] Debug: %s sieht zu" % other.display_name)
		get_tree().create_timer(30.0, false).timeout.connect(func() -> void:
			var line := Game.social.talk.greeting(other)
			print("[Einbruch] Zeuge im Gespräch: „%s“: %s" % [line, "ok" if g.display_name in line \
				and other.has_stance("distrusts:" + g.id) and not Game.social.pals.are_pals(other, g) else "FEHLER"]))
	if what == "eigen":
		var thing := Item.create(Item.Kind.SKULL)
		thing.owner_id = "player"
		thing.set_meta("taken_from", g.id)
		thing.position = (info["center"] as Vector3) + Vector3(0, 0.05, 0)
		Game.social._world.add_child(thing)
	force_id = g.id
	_scan = 0.5
	print("[Einbruch] Debug: %s (%s)" % [g.display_name, Social.relation_word(g.relation)])
