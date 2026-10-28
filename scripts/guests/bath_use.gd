class_name BathUse
extends Node
## Gäste benutzen ihr Bad (Spielkonzept 6.19, Einzelheiten): Wer zu Hause herumsteht, geht ab und zu ins Bad und schließt
## die Badtür hinter sich, leise. Abschließen lässt sie sich nicht (entschieden 2026-10-26) – wer sie aufmacht, steht
## im Bad vor ihm („Besetzt!“). Hinaus geht er mit seinem nächsten Vorhaben; die Tür öffnet er dabei wie jede auf
## seinem Weg (Guest._open_doors) und lässt sie offen. Badtüren gehören nicht zur Zugangsregel: Sie haben kein Schloss,
## und Guest._close_behind übergeht sie.
## Läuft über den Besuchsablauf wie Kerzenpflege und Putzen (start_visit, Social.on_visit_arrived fragt on_arrived).
## Kind von Social: Game.social.bath. Nicht gespeichert.

const SCAN := 5.0
## Je Blick auf einen Gast, der zu Hause herumsteht, und so lange danach (s Spielzeit) nicht noch einmal
const CHANCE := 0.06
const GAP := 2.0 * Calendar.HOUR
## So lange bleibt er im Bad (s)
const STAY := Vector2(40.0, 110.0)
## So lange versucht er, die Tür zu schließen, solange jemand im Schwenkbereich steht (s)
const CLOSE_TRIES := 8.0
const BUSY_LINES := ["Besetzt!", "Hey! Besetzt!", "Klopfen kann man auch!"]

## Gast-ID → {guest, bath ({door, id, spot}), phase ("go", "close", "in"), wait, said}
var _jobs := {}
var _last := {}   ## Gast-ID → Zeitpunkt (Game.director.elapsed) des letzten Badgangs
var _scan := SCAN
## Debug (--bad): dieser Gast geht beim nächsten Blick sicher
var force_id := ""


func reset() -> void:
	_jobs.clear()


func _now() -> float:
	return Game.director.elapsed if Game.director else 0.0


## Ist gerade jemand (Spieler, Gast) in diesem Bad oder auf dem Weg dorthin – außer except?
func occupied(bath_id: String, except: Guest = null) -> bool:
	for id in _jobs:
		if _jobs[id]["bath"]["id"] == bath_id and _jobs[id]["guest"] != except:
			return true
	var builder := Game.social.builder
	if Game.player and builder.room_at(Game.player.global_position) == bath_id:
		return true
	for g in Game.social.living_guests():
		if g != except and builder.room_at((g as Guest).global_position) == bath_id:
			return true
	return false


## Benutzt dieser Gast gerade sein Bad (ist drin oder auf dem Weg)?
func in_bath(g: Guest) -> bool:
	return _jobs.has(g.id)


func _process(delta: float) -> void:
	if Game.game_over or Game.social == null:
		return
	for id in _jobs.keys():
		_step(id, delta)
	_scan -= delta
	if _scan > 0.0:
		return
	_scan = SCAN
	if Game.social.sleep_active or Game.social.party_active or (Game.monster != null and Game.monster.is_active()):
		return
	for g in Game.social.living_guests():
		var guest: Guest = g
		if _wants(guest):
			_send(guest)


func _wants(g: Guest) -> bool:
	if _jobs.has(g.id) or g.state != Guest.State.IDLE or g.is_asleep() or g.hiding or g.is_following() \
			or g.fear >= 60.0 or (g.home.get("baths", []) as Array).is_empty() or not g._is_home():
		return false
	if g.id == force_id:
		return true
	return _now() - float(_last.get(g.id, -INF)) > GAP and randf() < CHANCE


func _send(g: Guest) -> void:
	var bath: Dictionary = (g.home["baths"] as Array)[0]
	if occupied(bath["id"], g):
		return
	if g.id == force_id:
		force_id = ""
	_last[g.id] = _now()
	_jobs[g.id] = {"guest": g, "bath": bath, "phase": "go", "wait": 0.0, "said": false}
	g.start_visit(bath["spot"])
	if Game.tracing:
		print("[Bad] %s geht ins Bad (Zimmer %s)" % [g.display_name, g.home["no"]])


## Angekommen (Social.on_visit_arrived): Tür zu, eine Weile bleiben.
func on_arrived(g: Guest) -> bool:
	if not _jobs.has(g.id):
		return false
	var job: Dictionary = _jobs[g.id]
	job["phase"] = "close"
	g._set_idle(randf_range(STAY.x, STAY.y))
	return true


func _step(id: String, delta: float) -> void:
	var job: Dictionary = _jobs[id]
	var g: Guest = job["guest"]
	var door: Door = job["bath"]["door"]
	var phase := String(job["phase"])
	var gone := not is_instance_valid(g) or g.dead
	if gone or (phase == "go" and g.state != Guest.State.VISIT) or (phase != "go" and g.state != Guest.State.IDLE):
		_jobs.erase(id)   # fertig oder abgebrochen – hinaus geht er von selbst
		return
	if phase == "close":
		job["wait"] = float(job["wait"]) + delta
		if not door.is_open:
			job["phase"] = "in"
		elif not g._someone_in_swing(door):
			door.set_open(false, false, true, g)   # leise (6.19)
			job["phase"] = "in"
			if Game.tracing:
				print("[Bad] %s schließt die Badtür" % g.display_name)
		elif float(job["wait"]) > CLOSE_TRIES:
			job["phase"] = "in"   # es steht dauernd jemand im Weg – dann eben offen
			job["said"] = true
	elif phase == "in" and door.is_open and not bool(job["said"]) and Game.player \
			and Game.player.global_position.distance_to(g.global_position) < 4.0 and g.can_see_actor(Game.player):
		job["said"] = true   # jemand hat aufgemacht
		g.say(BUSY_LINES.pick_random())



## --bad=id: Er steht zu Hause und geht gleich ins Bad; der Spieler steht im Zimmer mit Blick auf die Badtür.
func debug(g: Guest) -> bool:
	if (g.home.get("baths", []) as Array).is_empty():
		print("[Bad] Debug: Zimmer %s hat kein Bad" % g.home["no"])
		return false
	var bath: Dictionary = (g.home["baths"] as Array)[0]
	var door: Door = bath["door"]
	var spot: Vector3 = bath["spot"]
	var out := door.center() - spot
	out.y = 0.0
	out = out.normalized()
	TeleportUI.place_player(Vector3(door.center().x, spot.y, door.center().z) + out * 2.2, -out)
	g.global_position = g.home["center"] + Vector3.UP * 0.05
	g._set_idle(1.0)
	force_id = g.id
	_scan = 0.5
	return true
