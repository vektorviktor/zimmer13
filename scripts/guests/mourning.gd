class_name GuestMourning
extends Node
## Trauer der Gäste um Freunde (Spielkonzept 6.12, 6.18 Punkt 2 und 3; entschieden 2026-11-03, ZIM-41).
## - **Wer trauert:** Stirbt ein Gast, bekommen seine Freunde (Familie, Freunde, Zimmernachbarn – GuestPals) einen
##   Spieltag lang die Haltung „grieving“ (Talk.on_guest_died, mit Name und ID des Toten). Solange schmücken sie nicht
##   (Decorating._available, DecoPlan._free) und ruhen mehr im Zimmer (Guest.GRIEVING_ACTIVITIES).
## - **Gedenkort:** Höchstens VISITS-mal (frühestens alle VISIT_GAP) geht ein trauernder Erwachsener zur Tür des Toten –
##   liegt er schon im Grab, zum Grab (Cemetery) – und steht dort STAY Sekunden mit Blick hin (Guest.hold_argument).
## - **Kerzen der Freunde:** Beim ersten Gang zur Tür nimmt er eine Kerze aus seinem Vorrat (stock) mit und stellt sie
##   brennend vor die Tür – mit eigenem Feuer (CandleCare.has_fire) oder an einer Flamme, die dort schon brennt; sonst
##   bleibt sie im Koffer. Die Kerze gehört ihm (Meta „memorial“: niemand klaut sie). So wächst ein sichtbarer Gedenkort.
## - **Trauerwunsch:** „Würdest du eine Kerze für X vor seine Tür stellen?“ – Bitte „memorial“ (GuestRequests, außerhalb
##   von SMALL_PER_DAY), erfüllt, sobald ein Licht des Spielers dort brennt (GuestDeaths.honor).
## Kind von Social, erreichbar über Game.social.mourning. Die Trauer selbst steht in der Haltung (mit dem Gast
## gespeichert: Gänge, nächster Gang, Kerze gestellt); ein Gang, der gerade läuft, nicht.

const SCAN := 5.0
## Je Durchgang und trauerndem Gast: so wahrscheinlich geht er los; frühestens nach so viel Spielzeit wieder; so oft
const VISIT_CHANCE := 0.2
const VISIT_GAP := 4.0 * Calendar.HOUR
const VISITS := 2
## So lange steht er am Gedenkort (Sekunden Spielzeit)
const STAY := Vector2(40.0, 80.0)
## Eine Flamme so nah an der Tür reicht zum Anzünden (ohne eigenes Feuer)
const FLAME_RANGE := 2.5
const FREE_STATES := [Guest.State.IDLE, Guest.State.WALK]
const LINES := ["Ach, %s …", "Warum ausgerechnet du, %s?", "Du fehlst, %s.", "Ruh dich aus, %s."]
const CANDLE_LINES := ["Für dich, %s.", "Damit es bei dir nicht dunkel ist, %s."]

## Gast-ID → {dead (ID), at (Vector3, Gedenkort), look, door (bool), candle (bool)} – laufender Gang (nicht gespeichert)
var _visits := {}
var _scan := SCAN
var _force_id := ""   ## Debug (--trauer): dieser Gast geht sicher los


func reset() -> void:
	_visits.clear()


## Trauert er gerade? Gibt die ID des Toten zurück ("" = nein).
static func mourns(g: Guest) -> String:
	if not g.has_stance("grieving"):
		return ""
	return String(g.stances["grieving"].get("id", ""))


func _process(delta: float) -> void:
	if Game.game_over or Game.social == null or Game.director == null:
		return
	for id in _visits.keys():   # abgebrochen (Schreck, Gespräch, Monster …)
		var g := Game.social.guest_by_id(String(id))
		if g == null or g.dead or g.state != Guest.State.VISIT:
			_visits.erase(id)
			if g and not g.dead and g.held and g.held.kind == Item.Kind.CANDLE:
				g.held._extinguish()
				g.stow_held()
	_scan -= delta
	if _scan > 0.0:
		return
	_scan = SCAN
	if Game.social.sleep_active or (Game.monster != null and Game.monster.is_active()):
		return
	for other in Game.social.living_guests():
		var g: Guest = other
		if _force_id != "" and g.id != _force_id:
			continue   # Debug: nur dieser
		if _free(g) and (g.id == _force_id or randf() < VISIT_CHANCE) and _send(g):
			return   # einer je Durchgang


func _free(g: Guest) -> bool:
	if g.is_child() or g.held != null or g.hiding != null or not g.state in FREE_STATES or g.is_following() \
			or g.fear >= 60.0 or _visits.has(g.id) or g._switch != null or Game.social.candles._jobs.has(g.id):
		return false
	if mourns(g) == "":
		return false
	var s: Dictionary = g.stances["grieving"]
	return int(s.get("visits", 0)) < VISITS and Game.director.elapsed >= float(s.get("next", 0.0))


## Gedenkort des Toten: sein Grab, sonst seine Tür. {at, look, door} – leer, wenn es ihn nicht mehr gibt.
func memorial_of(dead: Guest) -> Dictionary:
	var c := Game.cemetery
	if c and c.graves.size() > 0:
		var slot := c._slot_of(dead.id)
		if slot >= 0:
			var s: Dictionary = c.slots[slot]
			var center: Vector3 = s["pos"]
			return {"at": center - (s["head"] as Vector3) * 1.45, "look": center, "door": false}
	var front: Vector3 = dead.home["door_front"]
	return {"at": front - (dead.home["into"] as Vector3) * 0.4, "look": front + (dead.home["into"] as Vector3), "door": true}


## Losgehen: zum Gedenkort, beim ersten Gang zur Tür mit einer Kerze aus dem Vorrat. false = geht nicht.
func _send(g: Guest) -> bool:
	var dead := Game.social.guest_by_id(mourns(g))
	if dead == null or not dead.dead:
		return false
	var place := memorial_of(dead)
	var s: Dictionary = g.stances["grieving"]
	s["visits"] = int(s.get("visits", 0)) + 1
	s["next"] = Game.director.elapsed + VISIT_GAP
	var candle := bool(place["door"]) and not bool(s.get("lit", false)) and int(g.stock.get(Item.Kind.CANDLE, 0)) > 0
	if candle:
		g.stock[Item.Kind.CANDLE] = int(g.stock[Item.Kind.CANDLE]) - 1
		g._take_into_hand(g.stock_item(Item.Kind.CANDLE))
	_visits[g.id] = {"dead": dead.id, "at": place["at"], "look": place["look"], "door": place["door"], "candle": candle}
	g.start_visit(place["at"])
	if Game.tracing:
		print("[Trauer] %s geht %s von %s%s" % [g.display_name, "zur Tür" if place["door"] else "zum Grab",
			dead.display_name, " – mit einer Kerze" if candle else ""])
	return true


## Angekommen (Social.on_visit_arrived): true = gehört zur Trauer.
func on_arrived(g: Guest) -> bool:
	if not _visits.has(g.id):
		return false
	var v: Dictionary = _visits[g.id]
	_visits.erase(g.id)
	var dead := Game.social.guest_by_id(String(v["dead"]))
	var name := dead.display_name if dead else "…"
	if g.held and g.held.kind == Item.Kind.CANDLE:
		if _place_candle(g, v, dead):
			g.say(CANDLE_LINES.pick_random() % name)
		else:
			g.stow_held()
			g.say(LINES.pick_random() % name)
	else:
		g.say(LINES.pick_random() % name)
	g.hold_argument(v["look"], randf_range(STAY.x, STAY.y))
	return true


## Die Kerze brennend vor die Tür stellen – mit eigenem Feuer oder an einer Flamme dort. false = kein Feuer.
func _place_candle(g: Guest, v: Dictionary, dead: Guest) -> bool:
	if dead == null:
		return false
	var front: Vector3 = dead.home["door_front"]
	if not CandleCare.has_fire(g) and not flame_near(front, g.held):
		if Game.tracing:
			print("[Trauer] %s hat kein Feuer – die Kerze bleibt im Koffer" % g.display_name)
		return false
	var item := g.held
	g.held = null
	item.reparent(g.get_parent(), true)
	var along: Vector3 = dead.home["along"]
	var into: Vector3 = dead.home["into"]
	var pos := front + into * 0.45 + along * randf_range(-0.7, 0.7)
	item.global_position = Vector3(pos.x, front.y + 0.02, pos.z)
	item.rotation = Vector3(0, randf() * TAU, 0)
	item.set_held(false)
	item.linear_velocity = Vector3.ZERO
	item.owner_id = g.id
	item.set_meta("memorial", dead.id)
	item.light_up()
	g.reach_up(0.6)
	(g.stances["grieving"] as Dictionary)["lit"] = true
	if Game.tracing:
		print("[Trauer] %s stellt eine Kerze vor die Tür von %s" % [g.display_name, dead.display_name])
	return true


## Brennt schon eine Flamme am Gedenkort (zum Anzünden ohne eigenes Feuer)?
func flame_near(at: Vector3, exclude: Item) -> bool:
	for node in get_tree().get_nodes_in_group("items"):
		var item := node as Item
		if item != exclude and item.lit and not item.is_held and item.global_position.distance_to(at) < FLAME_RANGE:
			return true
	return false


# --- Debug (--trauer) ------------------------------------------------------------------------------

## --trauer=id[,feuer|ohne|wunsch|halten]: Ein Freund des Gastes stirbt. Prüft Trauer (Haltung, kein Schmücken, mehr Ruhe),
## dann geht er von ein paar Metern daneben zur Tür des Toten · feuer (Standard): mit Feuer, eine Kerze aus dem Vorrat
## brennt danach dort · ohne: ohne Feuer und ohne Flamme – keine Kerze · wunsch: der Trauerwunsch, du stellst ein Licht
## auf, er dankt · halten: er steht gleich mit brennender Kerze vor der Tür (für --savetest, ohne spätere Prüfungen).
## Meldet „[Trauer] … ok“ bzw. „FEHLER“.
func debug(parts: PackedStringArray) -> void:
	var social := Game.social
	var p := Game.player
	var g := social.find_guest(parts[0] if parts.size() > 0 and parts[0] != "" else "edna")
	var what := parts[1] if parts.size() > 1 and parts[1] != "" else "feuer"
	if g == null or g.dead or g.is_child() or not what in ["feuer", "ohne", "wunsch", "halten"]:
		print("[Trauer] Debug: --trauer=id[,feuer|ohne|wunsch|halten] (ein Erwachsener)")
		return
	if what == "ohne" and CandleCare.has_fire(g):   # einer ohne eigenes Feuer
		for other in social.living_guests():
			if not (other as Guest).is_child() and not CandleCare.has_fire(other) and not Grinch.is_grinch(other):
				g = other
				break
	var check := func(text: String, ok: bool) -> void:
		print("[Trauer] %s: %s" % [text, "ok" if ok else "FEHLER"])
	var dead: Guest = null   # ein Freund außerhalb seines Haushalts, der kein Kind ist
	for other in social.living_guests():
		var o: Guest = other
		if o != g and not o.is_child() and not o.housemate_of(g) and not Grinch.is_grinch(o):
			dead = o
			break
	social.pals.note(g, dead, GuestPals.PAL_DEEDS)
	g.stock[Item.Kind.CANDLE] = 1
	if what != "feuer":   # niemand mit Feuer: die Prüfung ohne Feuer findet dann keine Flamme am Gedenkort
		for node in get_tree().get_nodes_in_group("items"):
			if (node as Item).lit and (node as Item).global_position.distance_to(dead.home["door_front"]) < FLAME_RANGE * 2.0:
				(node as Item)._extinguish()
	print("[Trauer] Debug: %s trauert um %s (%s, %s)" % [g.display_name, dead.display_name, what,
		"hat Feuer" if CandleCare.has_fire(g) else "ohne Feuer"])
	dead.die("monster")
	social.on_guest_died(dead, "monster", true)
	check.call("trauert um %s" % dead.display_name, mourns(g) == dead.id)
	check.call("schmückt nicht", not social.decorating._available(g))
	var w := g.activity_weights(Calendar.Phase.DAY)
	check.call("ruht mehr im Zimmer", float(w.get("room", 0.0)) > float(g.profile["activities"].get("room", 0.0)))
	g.fear = 0.0
	g._set_idle(1.0)
	if what == "wunsch":
		g.global_position = p.global_position + (-p.global_transform.basis.z) * 2.5
	else:   # ein paar Meter neben der Tür des Toten – der Gang ist kurz
		g.global_position = (dead.home["door_front"] as Vector3) + (dead.home["along"] as Vector3) * 4.0
	if what == "wunsch":
		var req := social.requests.offer_for(g, true)
		check.call("Trauerwunsch: „%s“" % String(req.get("ask", "")), req.get("kind", "") == "memorial" and req["target"] == dead.id)
		social.requests.accept(g, req)
		check.call("zählt nicht zu den kleinen Bitten", social.requests._small_allowed(g) or Social.tier(g) < GuestRequests.SMALL_TIER)
		var candle := Item.create(Item.Kind.CANDLE)
		social.get_parent().add_child(candle)
		candle.owner_id = "player"
		candle.global_position = dead.home["door_front"]
		candle.light_up(false)
		get_tree().create_timer(3.0, false).timeout.connect(func() -> void:
			var line := social.requests.thanks_on_greet(g)
			check.call("Dank: „%s“" % line, line != "" and social.requests.request_of(g).is_empty()))
		return
	if not CandleCare.has_fire(g) and what in ["feuer", "halten"]:
		print("[Trauer] Debug: %s hat kein eigenes Feuer – eine Kerze brennt schon an der Tür" % g.display_name)
		var lit := Item.create(Item.Kind.CANDLE)
		social.get_parent().add_child(lit)
		lit.global_position = (dead.home["door_front"] as Vector3) + Vector3(0, 0.02, 0)
		lit.light_up(false)
	if what == "halten":   # gleich am Ziel – die Kerze steht, bevor der Savetest speichert
		check.call("geht zur Tür", _send(g))
		g.global_position = _visits[g.id]["at"]
		on_arrived(g)
		check.call("Kerze steht", bool(g.stances["grieving"].get("lit", false)))
		return
	_force_id = g.id
	get_tree().create_timer(SCAN * 2.0 + 1.0, false).timeout.connect(func() -> void:
		_force_id = ""
		check.call("geht zur Tür", int(g.stances["grieving"].get("visits", 0)) == 1))
	get_tree().create_timer(40.0, false).timeout.connect(func() -> void:
		var placed := false
		for node in get_tree().get_nodes_in_group("items"):
			var item := node as Item
			if String(item.get_meta("memorial", "")) == dead.id and item.owner_id == g.id and item.lit:
				placed = true
		if what == "feuer":
			check.call("Kerze brennt vor der Tür", placed)
		else:
			check.call("ohne Feuer keine Kerze, sie bleibt im Koffer", not placed and int(g.stock.get(Item.Kind.CANDLE, 0)) == 1)
		check.call("Gang gezählt", int(g.stances["grieving"].get("visits", 0)) == 1))
