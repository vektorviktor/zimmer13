class_name CandleCare
extends Node
## Gäste kümmern sich um Kerzen (Spielkonzept 5.12, Abbrennen 2026-10-27). Ist die Kerze vor der eigenen Tür aus (Kerze,
## Kürbis, Totenkopf), zündet der Haushaltsvorstand sie wieder an; steckt im Kürbis oder Totenkopf keine mehr, setzt er
## eine neue ein – aus dem Koffer (stock) oder dem Kerzenvorrat in der Küche. Ganz abgebrannte Kerzen vor der Tür ersetzt
## schon Guest._at_home aus dem Koffer; hier werden sie dann angezündet. Feste Kerzen (FixedCandle) in der Nähe zünden
## Gäste im Vorbeigehen an bzw. stellen eine neue auf den leeren Teller – nicht jeder und nicht immer.
## Feuer (Streichhölzer, Feuerzeug) haben nur manche Erwachsene (has_fire, fest nach Gast-ID). Die anderen tragen ihre
## Kerze bzw. ihren Kürbis zu einer brennenden Flamme in der Nähe und wieder zurück; feste Kerzen lassen sie dann. Findet
## sich keine Flamme, fragen sie den Spieler, wenn er in der Nähe ist.
## In der Nachtruhe und solange das Monster unterwegs ist, kümmert sich niemand darum: Was es ausbläst, bleibt bis zum
## Morgen dunkel. Ängstliche zuerst, Nachlässige und Betrunkene vergessen es öfter (Guest._forget_light).
## Läuft über den Besuchsablauf wie Tidying (start_visit, Social.on_visit_arrived fragt on_arrived). Kind von Social:
## Game.social.candles. Nicht gespeichert.

const SCAN := 4.0
## Nach einem losgeschickten Gang so lange kein neuer (für alle zusammen)
const GAP := 6.0
## So viele Erwachsene haben Feuer dabei
const FIRE_SHARE := 0.4
## Eigene Tür: so weit weg (gleiches Stockwerk) merkt er es noch
const DOOR_RANGE := 30.0
## Feste Kerzen: so nah und mit Blick darauf, Wahrscheinlichkeit je Blick
const PASS_RANGE := 7.0
const PASS_CHANCE := 0.35
## Ohne Feuer: so weit (gleiches Stockwerk) sucht er eine brennende Flamme
const FLAME_RANGE := 25.0
## Den Spieler um Feuer bitten: so nah, so oft (Sekunden Spielzeit je Gast)
const ASK_RANGE := 7.0
const ASK_GAP := 120.0
const FLOOR_DY := 1.5
const FREE_STATES := [Guest.State.IDLE, Guest.State.WALK]
const ASK_LINES := ["Hast du mal Feuer? Meine Kerze ist aus.", "Kannst du mir die Kerze anzünden? Ich hab nichts dabei.",
	"Hat hier jemand Streichhölzer? Vor meiner Tür ist es dunkel."]
const EMPTY_LINES := ["Keine Kerzen mehr in der Küche … na toll.", "Der Kerzenvorrat ist leer."]

## Gast-ID → {guest, target (Item oder FixedCandle), steps (Array), step (laufender Schritt), flame, spot, own (bool)}
var _jobs := {}
var _asked := {}
## Debug (--kerzenpflege): dieser Gast geht sicher los
var _force_id := ""
var _scan := SCAN
var _gap := 3.0


## Hat er Feuer dabei? Fest nach seiner ID, Kinder nie.
static func has_fire(g: Guest) -> bool:
	return not g.is_child() and absi(hash(g.id + "|feuer")) % 100 < int(FIRE_SHARE * 100.0)


func reset() -> void:
	_jobs.clear()


func _process(delta: float) -> void:
	if Game.game_over or Game.social == null:
		return
	for id in _jobs.keys():   # abgebrochen (Schreck, Feier, Gespräch, Monster …)
		var job: Dictionary = _jobs[id]
		var g: Guest = job["guest"]
		if is_instance_valid(g) and not g.dead and g.state == Guest.State.VISIT:
			continue
		_jobs.erase(id)
		if is_instance_valid(g) and not g.dead:
			_put_away(g, job)
	_gap -= delta
	_scan -= delta
	if _scan > 0.0:
		return
	_scan = SCAN
	if _gap > 0.0 or _quiet():
		return
	if _own_doors() or _passing():
		_gap = GAP


## Nachtruhe oder das Monster unterwegs: Jetzt geht keiner los.
func _quiet() -> bool:
	return Game.social.sleep_active or (Game.monster != null and Game.monster.is_active())


## Frei für einen Gang: wach, nichts in der Hand, nicht auf der Flucht, nicht schon unterwegs.
func _free(g: Guest) -> bool:
	return not g.is_child() and g.held == null and g.hiding == null and g.state in FREE_STATES and not g.is_following() \
			and g.fear < 60.0 and not _jobs.has(g.id) and g._switch == null


## Wie wahrscheinlich er sich jetzt darum kümmert: Ängstliche eher, Vergessliche und Betrunkene seltener.
func _care_chance(g: Guest) -> float:
	if g.id == _force_id:
		return 1.0
	return clampf((1.0 - g._forget_light()) * (0.45 + g.fear / 100.0), 0.05, 1.0)


# --- Was dunkel ist ------------------------------------------------------------------------

## Kerze, Kürbis oder Totenkopf, das brennen könnte und nicht brennt (oder in dem die Kerze fehlt).
static func is_dark(target: Object) -> bool:
	if target is FixedCandle:
		return not (target as FixedCandle).lit
	var item := target as Item
	if item == null or item.is_held or item.in_bag or item.lit:
		return false
	return item.kind == Item.Kind.CANDLE or item.kind in Item.CANDLE_HOLDERS


## Braucht eine neue Kerze: Kürbis, Totenkopf ohne Kerze, leerer Teller.
static func needs_candle(target: Object) -> bool:
	if target is FixedCandle:
		return not (target as FixedCandle).has_candle()
	var item := target as Item
	return item.kind in Item.CANDLE_HOLDERS and not item.has_candle


## Die eigene Tür: Der Haushaltsvorstand sieht nach seiner dunklen Deko. true = jemand ist losgegangen.
func _own_doors() -> bool:
	for guest in Game.social.living_guests():
		var g: Guest = guest
		if not _free(g) or not g.is_household_lead():
			continue
		var front: Vector3 = g.home["door_front"]
		if absf(g.global_position.y - front.y) > FLOOR_DY or g.global_position.distance_to(front) > DOOR_RANGE:
			continue
		for item in g.own_deco_near_door():
			if is_dark(item) and not item.has_meta("candle_care") and randf() < _care_chance(g) and _send(g, item, true):
				return true
	return false


## Feste Kerzen: Wer vorbeikommt und sie dunkel sieht, kümmert sich manchmal darum.
func _passing() -> bool:
	for node in get_tree().get_nodes_in_group("fixed_candles"):
		var candle := node as FixedCandle
		if candle.lit or candle.has_meta("candle_care"):
			continue
		for guest in Game.social.living_guests():
			var g: Guest = guest
			if not _free(g) or absf(g.global_position.y - candle.global_position.y) > FLOOR_DY \
					or g.global_position.distance_to(candle.global_position) > PASS_RANGE:
				continue
			if not Senses.clear_line(g.get_world_3d(), g.global_position + Vector3.UP * g.eye_height(), candle.global_position + Vector3.UP * 0.1, g):
				continue
			if randf() < PASS_CHANCE * _care_chance(g) and _send(g, candle, false):
				return true
	return false


# --- Losschicken -------------------------------------------------------------------------

## Plant den Gang: neue Kerze holen (Koffer oder Vorrat), ohne Feuer erst zur Flamme, dann hin. false = geht nicht.
func _send(g: Guest, target: Object, own: bool) -> bool:
	var fire := has_fire(g)
	var job := {"guest": g, "target": target, "steps": [], "step": "", "flame": null, "spot": null, "own": own}
	var steps: Array = []
	var from_stock := false
	if needs_candle(target):
		if int(g.stock.get(Item.Kind.CANDLE, 0)) > 0:
			from_stock = true
		else:
			var spot := _candle_spot(g)
			if spot == null:
				if own and randf() < 0.3:
					g.say(EMPTY_LINES.pick_random())
				return false
			job["spot"] = spot
			steps.append("fetch")
		if not fire:
			steps.append("flame")
		steps.append("go")
	elif fire:
		steps.append("go")
	elif target is Item and own:
		steps.append_array(["pickup", "flame", "place"])   # er trägt sie zur Flamme und wieder zurück
	else:
		return false   # feste Kerze ohne Feuer: lässt er
	if "flame" in steps:
		var near: Vector3 = (target as Node3D).global_position if not "fetch" in steps else g.global_position
		var flame := _nearest_flame(near, target)
		if flame == null:
			_ask_player(g)
			return false
		job["flame"] = flame
	if from_stock:
		g.stock[Item.Kind.CANDLE] = int(g.stock[Item.Kind.CANDLE]) - 1
		g._take_into_hand(g.stock_item(Item.Kind.CANDLE))
	job["steps"] = steps
	(target as Node).set_meta("candle_care", true)
	_jobs[g.id] = job
	if Game.tracing:
		print("[Kerzen] %s kümmert sich um %s (%s, %s)" % [g.display_name, _label(target), " → ".join(steps),
			"hat Feuer" if fire else "ohne Feuer"])
	_next(job)
	return true


## Nächster Schritt des Gangs – oder fertig.
func _next(job: Dictionary) -> void:
	var g: Guest = job["guest"]
	var steps: Array = job["steps"]
	if steps.is_empty():
		_finish(job)
		g._set_idle(randf_range(3.0, 6.0))
		return
	var step := String(steps.pop_front())
	job["step"] = step
	match step:
		"fetch":
			g.start_visit(_stand_near((job["spot"] as Node3D).global_position, g))
		"flame":
			g.start_visit(_stand_near((job["flame"] as Node3D).global_position, g))
		"go", "pickup":
			g.start_visit(_stand_near((job["target"] as Node3D).global_position, g))
		"place":
			_finish(job)
			if Game.tracing:
				print("[Kerzen] %s stellt %s zurück vor die Tür" % [g.display_name, g.held.display_name if g.held else "?"])
			g._walk_to(g.deco_place_point(), Guest.State.PLACE_DECO)   # stellt sie zurück vor die Tür (zählt wieder)


## Angekommen (Social.on_visit_arrived): true = gehört zur Kerzenpflege.
func on_arrived(g: Guest) -> bool:
	if not _jobs.has(g.id):
		return false
	var job: Dictionary = _jobs[g.id]
	var target = job["target"]
	if not is_instance_valid(target) or (target as Node).is_queued_for_deletion():
		_give_up(g, job)
		return true
	match String(job["step"]):
		"fetch":
			var spot := job["spot"] as ResourceSpot
			if not spot.guest_consume():
				g.say(EMPTY_LINES.pick_random())
				_give_up(g, job)
				return true
			g._take_into_hand(g.stock_item(Item.Kind.CANDLE))
		"flame":
			var flame = job["flame"]
			if g.held == null or not is_instance_valid(flame) or not flame.lit:
				_give_up(g, job)
				return true
			g.held.light_up()
			g.reach_up(0.6)
			if Game.tracing:
				print("[Kerzen] %s zündet %s an %s an" % [g.display_name, g.held.display_name, _label(flame)])
		"pickup":
			var item := target as Item
			if item.is_held or item.lit:
				_give_up(g, job)
				return true
			g.expected_deco = maxi(0, g.expected_deco - 1)   # trägt sie nur kurz weg (place zählt sie wieder)
			g._take_into_hand(item)
		"go":
			if not is_dark(target):
				_give_up(g, job)   # inzwischen brennt sie schon
				return true
			_tend(g, job)
	_next(job)
	return true


## Am Ziel: anzünden bzw. die neue, brennende Kerze einsetzen.
func _tend(g: Guest, job: Dictionary) -> void:
	var target = job["target"]
	var fire := has_fire(g)
	g.reach_up(0.8)
	if needs_candle(target):
		var candle := g.held
		if candle == null or candle.kind != Item.Kind.CANDLE or not (candle.lit or fire):
			_give_up(g, job)
			return
		var rest := candle.wax
		g.held = null
		candle.queue_free()
		if target is FixedCandle:
			(target as FixedCandle).renew(rest, true)
		else:
			(target as Item).insert_candle(rest)
	elif fire:
		target.light_up()
	if Game.tracing:
		print("[Kerzen] %s zündet %s an" % [g.display_name, _label(target)])


func _finish(job: Dictionary) -> void:
	var g: Guest = job["guest"]
	_jobs.erase(g.id)
	var target = job["target"]
	if is_instance_valid(target):
		(target as Node).remove_meta("candle_care")


## Geht nicht weiter: Was er geholt hat, kommt in den Koffer; die eigene Deko stellt er zurück.
func _give_up(g: Guest, job: Dictionary) -> void:
	if Game.tracing:
		print("[Kerzen] %s gibt auf (%s)" % [g.display_name, job["step"]])
	_finish(job)
	if g.held and is_instance_valid(job["target"]) and g.held == job["target"]:
		g._walk_to(g.deco_place_point(), Guest.State.PLACE_DECO)
		return
	_put_away(g, job)
	g._set_idle(randf_range(2.0, 4.0))


## Abgebrochen: eine geholte Kerze zurück in den Koffer, die eigene Deko fällt dort hin, wo er steht.
func _put_away(g: Guest, job: Dictionary) -> void:
	var target = job["target"]
	if is_instance_valid(target):
		(target as Node).remove_meta("candle_care")
	if g.held == null:
		return
	if is_instance_valid(target) and g.held == target:
		g._drop_held()
	elif g.held.kind == Item.Kind.CANDLE:
		g.held._extinguish()
		g.stow_held()


# --- Hilfen ---------------------------------------------------------------------------------

## Der nächste Kerzenvorrat, aus dem ein Gast gerade nehmen darf.
func _candle_spot(g: Guest) -> ResourceSpot:
	var best: ResourceSpot = null
	for node in get_tree().get_nodes_in_group("resource_spots"):
		var spot := node as ResourceSpot
		if spot.kind == Item.Kind.CANDLE and spot.pool.is_empty() and spot.guest_can_take() and (best == null
				or spot.global_position.distance_to(g.global_position) < best.global_position.distance_to(g.global_position)):
			best = spot
	return best


## Die nächste brennende Flamme (Kerze, Kürbis, Totenkopf, feste Kerze) auf diesem Stockwerk, nicht in einer Hand.
func _nearest_flame(at: Vector3, exclude: Object) -> Node3D:
	var best: Node3D = null
	var best_d := FLAME_RANGE
	for node in get_tree().get_nodes_in_group("items"):
		var item := node as Item
		if item == exclude or not item.lit or item.is_held:
			continue
		var d := item.global_position.distance_to(at)
		if d < best_d and absf(item.global_position.y - at.y) < FLOOR_DY:
			best = item
			best_d = d
	for node in get_tree().get_nodes_in_group("fixed_candles"):
		var candle := node as FixedCandle
		if candle == exclude or not candle.lit:
			continue
		var d := candle.global_position.distance_to(at)
		if d < best_d and absf(candle.global_position.y - at.y) < FLOOR_DY + 1.0:
			best = candle
			best_d = d
	return best


## Kein Feuer, keine Flamme: den Spieler fragen, wenn er nah ist – nicht ständig.
func _ask_player(g: Guest) -> void:
	var p := Game.player
	var now := Game.director.elapsed if Game.director else 0.0
	if p == null or p.dead or now < float(_asked.get(g.id, -INF)) + ASK_GAP:
		return
	if p.global_position.distance_to(g.global_position) > ASK_RANGE or not g.can_see_actor(p):
		return
	_asked[g.id] = now
	g.say(ASK_LINES.pick_random())


## Stehpunkt neben etwas (auch auf einem Tisch): auf seiner Höhe, ein Stück zu ihm hin.
func _stand_near(pos: Vector3, g: Guest) -> Vector3:
	var to := Vector3(g.global_position.x - pos.x, 0.0, g.global_position.z - pos.z)
	var off := to.normalized() * 0.55 if to.length() > 0.1 else Vector3.ZERO
	return Vector3(pos.x, g.global_position.y, pos.z) + off


func _label(target: Object) -> String:
	return "feste Kerze" if target is FixedCandle else (target as Item).display_name


## Debug (--kerzenpflege[=id]): Die Deko vor der Tür des Gastes geht aus, er steht ein paar Meter davor. Mit
## „=id,ohne“ ist zudem jede Kerze in Kürbis und Totenkopf dort abgebrannt. false = kein Gast mit Kerze an der Tür.
func debug(g: Guest, burnt: bool) -> bool:
	var lead := Game.social.household_lead(String(g.home["no"]))
	if lead:
		g = lead   # um die Tür kümmert sich der Haushaltsvorstand
	_force_id = g.id
	var dark := 0
	for item in g.own_deco_near_door():
		if not item.has_wick() and not item.kind in Item.CANDLE_HOLDERS:
			continue
		if burnt and item.kind in Item.CANDLE_HOLDERS:
			item.has_candle = false
		item._extinguish()
		dark += 1
	if dark == 0 or (burnt and not g.own_deco_near_door().any(func(i: Item) -> bool: return i.kind in Item.CANDLE_HOLDERS)):
		# nichts Passendes vor der Tür: eine erloschene Kerze bzw. (ohne) ein Kürbis ohne Kerze
		var extra := (g.favorite_pumpkin() + ",unlit") if burnt else ""
		var thing := Item.create(Item.Kind.CARVED_PUMPKIN if burnt else Item.Kind.CANDLE, extra)
		thing.owner_id = g.id
		thing.position = g.deco_place_point() + Vector3(0, 0.02, 0)
		Game.social._world.add_child(thing)
		g.expected_deco += 1
	var front: Vector3 = g.home["door_front"]
	g.global_position = front + (g.home["along"] as Vector3) * 3.0 + Vector3.UP * 0.05
	g._set_idle(1.0)
	print("[Kerzen] Debug: %s, %s, %d dunkel" % [g.display_name, "hat Feuer" if has_fire(g) else "ohne Feuer", maxi(dark, 1)])
	for item in g.own_deco_near_door():   # gleich los, ohne auf den nächsten Blick zu warten
		if is_dark(item) and _send(g, item, true):
			return true
	_gap = 0.0
	_scan = 0.5
	return false
