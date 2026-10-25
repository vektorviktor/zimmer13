class_name Pranks
extends Node
## Streiche der Kinder (Spielkonzept 6.13, Süßes oder Saures): Gibt es nichts Süßes, sucht sich das Kind einen Streich
## aus – Laub vor die Tür streuen, Deko vor der Tür umwerfen oder einen Kürbis bzw. eine Kerze aus dem Koffer der
## Familie holen und vor die Tür werfen (zerplatzt bzw. zerbricht beim Aufprall, Item.throw_from; eine brennende Kerze
## kann leichte Deko anzünden, 5.11). Danach rennt es lachend davon.
## Zeugen: Erwachsene, die es sehen, verpetzen es sehr wahrscheinlich – nur die eigenen Eltern nicht. Erzählt wird es dem
## Bewohner der getroffenen Tür; der ist danach mit den Eltern verfeindet (GuestPals.add_feud, 6.16).
## Kind von Social, erreichbar über Game.social.pranks. Laufende Streiche werden nicht gespeichert.

## Streiche und ihr Gewicht (geht einer nicht, fällt er weg; Laub geht immer)
const WEIGHTS := {"leaves": 0.25, "topple": 0.25, "pumpkin": 0.3, "candle": 0.2}
## Umwerfen: Deko so nah an der Tür
const TOPPLE_RANGE := 2.0
## Wurf: von hier (so weit vor der Tür im Flur) auf diesen Punkt (so weit vor der Tür), Flugzeit
const THROW_FROM := 2.2
const THROW_AT := 0.5
const THROW_TIME := 0.55
## Eine brennende Kerze der Familie nimmt das Kind mit, wenn sie so nah an der Zimmertür steht (m, Spielkonzept 5.12)
const FLAME_REACH := 4.0
## Zeugen: so weit, so sicher verpetzen sie, so lange dauert es, bis der Bewohner es erfährt (s)
const WITNESS_RANGE := 14.0
const TATTLE_CHANCE := 0.85
const TATTLE_DELAY := Vector2(15.0, 45.0)
const LAUGH_LINES := ["Hihihi!", "Saures!", "Selber schuld!", "Wegrennen!"]
const WITNESS_LINES := ["He! Lass das!", "Na warte, das sag ich!", "Was machst du denn da?!"]
## Der Bewohner erfährt es: Zeuge, Kind, Eltern
const TOLD_LINES := ["%s sagt, %s war das vor meiner Tür. Na warte, %s!",
	"%s hat %s gesehen – vor meiner Tür! Mit %s rede ich nicht mehr."]

## Gast-ID des Kindes → {kid, no, kind, phase ("fetch" | "throw"), parent}
var _jobs := {}


## Saures vor der Tür von Zimmer `no`. true = das Kind ist jetzt mit dem Streich beschäftigt (holt etwas) – eine
## Runde von Tür zu Tür endet dann; false = erledigt (Laub, umgeworfen). forced: dieser Streich (Debug).
func play(kid: Guest, no: String, forced: String = "") -> bool:
	if no == String(kid.home["no"]):
		return false   # nie an der eigenen Tür (Haushalt, 6.20)
	var kind := forced if forced != "" else _choose(kid, no)
	if Game.tracing:
		print("[Streich] %s: %s vor Zimmer %s" % [kid.display_name, kind, no])
	match kind:
		"topple":
			_topple(kid, no)
			return false
		"pumpkin", "candle":
			_fetch(kid, no, kind)
			return true
	Game.social._leaves_at(no, kid)
	_witnesses(kid, no)
	return false


## Welcher Streich: gewichtet unter denen, die gehen.
func _choose(kid: Guest, no: String) -> String:
	var options := {"leaves": WEIGHTS["leaves"]}
	if not _toppable(no).is_empty():
		options["topple"] = WEIGHTS["topple"]
	if _family_has(kid, [Item.Kind.PUMPKIN, Item.Kind.MINI_PUMPKIN]) != -1:
		options["pumpkin"] = WEIGHTS["pumpkin"]
	if _family_has(kid, [Item.Kind.CANDLE]) != -1 or _family_flame(kid) != null:
		options["candle"] = WEIGHTS["candle"]
	var total := 0.0
	for k in options:
		total += float(options[k])
	var r := randf() * total
	for k in options:
		r -= float(options[k])
		if r <= 0.0:
			return k
	return "leaves"


## Deko vor der Tür, die umfallen kann und noch steht.
func _toppable(no: String) -> Array[Item]:
	var front: Vector3 = Game.social.builder.rooms[no]["door_front"]
	var result: Array[Item] = []
	for node in get_tree().get_nodes_in_group("items"):
		var it := node as Item
		if it.kind in Item.TOPPLE_KINDS and not it.is_held and not it.hung and not it.is_toppled() \
				and it.global_position.distance_to(front) < TOPPLE_RANGE:
			result.append(it)
	return result


## Hat die Familie (das Kind selbst, dann Mama oder Papa) etwas davon im Koffer? Index in kinds, sonst −1.
func _family_has(kid: Guest, kinds: Array) -> int:
	for g: Guest in _family(kid):
		for i in kinds.size():
			if int(g.stock.get(kinds[i], 0)) > 0:
				return i
	return -1


func _family(kid: Guest) -> Array[Guest]:
	var result: Array[Guest] = [kid]
	var parent := kid.parent_guest()
	if parent and not parent.dead:
		result.append(parent)
	for guest in Game.social.living_guests():   # der andere Elternteil im selben Zimmer (Haushalt, 6.20)
		var g: Guest = guest
		if not g in result and not g.is_child() and g.home["no"] == kid.home["no"]:
			result.append(g)
	return result


## Umwerfen: Das Kind stößt die Deko vor der Tür um (die Flamme geht dabei meist aus).
func _topple(kid: Guest, no: String) -> void:
	for it in _toppable(no):
		it.knock_over(kid.global_position)
	Game.noise("cat_knock", Game.social.builder.rooms[no]["door_front"], kid)
	kid.say(LAUGH_LINES.pick_random())
	_witnesses(kid, no)


## Holen: zur Tür der Familie, dort aus dem Koffer in die Hand.
func _fetch(kid: Guest, no: String, kind: String) -> void:
	var parent := kid.parent_guest()
	var home: Guest = parent if parent and not parent.dead else kid
	_jobs[kid.id] = {"kid": kid, "no": no, "kind": kind, "phase": "fetch", "home": home}
	kid.start_visit(home.home["door_inside"])


## Angekommen (Social.on_visit_arrived): true = gehört zu einem Streich.
func on_arrived(kid: Guest) -> bool:
	if not _jobs.has(kid.id):
		return false
	var job: Dictionary = _jobs[kid.id]
	if String(job["phase"]) == "fetch":
		var item := _take_from_family(kid, String(job["kind"]))
		if item == null:
			_jobs.erase(kid.id)
			kid._set_idle(randf_range(2.0, 4.0))
			return true
		_go_throw(kid, String(job["no"]), item)
		return true
	_throw(kid, job)
	_jobs.erase(kid.id)
	return true


## Mit dem Geholten in der Hand zurück: in den Flur vor die Tür, von dort wirft es.
func _go_throw(kid: Guest, no: String, item: Item) -> void:
	kid._take_into_hand(item)
	_jobs[kid.id] = {"kid": kid, "no": no, "phase": "throw"}
	var room: Dictionary = Game.social.builder.rooms[no]
	kid.start_visit((room["door_front"] as Vector3) - (room["into"] as Vector3) * (THROW_FROM - 0.9))


## Kürbis (lieber der große) bzw. Kerze. Anzünden können Gäste nicht (Spielkonzept 5.12): Brennt noch eine Kerze der
## Familie (vor ihrer Tür), nimmt das Kind die mit – sonst eine kalte aus dem Koffer.
func _take_from_family(kid: Guest, kind: String) -> Item:
	if kind == "candle":
		var flame := _family_flame(kid, FLAME_REACH)
		if flame:
			return flame
	var kinds: Array = [Item.Kind.PUMPKIN, Item.Kind.MINI_PUMPKIN] if kind == "pumpkin" else [Item.Kind.CANDLE]
	for g: Guest in _family(kid):
		for k in kinds:
			if int(g.stock.get(k, 0)) > 0:
				var item := g.stock_item(k)
				g.stock[k] = int(g.stock[k]) - 1
				return item
	return null


## Eine brennende Kerze der Familie, die irgendwo steht – höchstens reach vom Kind entfernt (null = keine).
func _family_flame(kid: Guest, reach: float = INF) -> Item:
	var ids := _family(kid).map(func(g: Guest) -> String: return g.id)
	for node in Game.social.get_tree().get_nodes_in_group("items"):
		var item := node as Item
		if item.kind == Item.Kind.CANDLE and item.lit and not item.is_held and item.owner_id in ids \
				and item.global_position.distance_to(kid.global_position) < reach:
			return item
	return null


## Werfen: aus der Hand im Bogen auf den Boden vor der Tür.
func _throw(kid: Guest, job: Dictionary) -> void:
	var item := kid.held
	if item == null:
		return
	var room: Dictionary = Game.social.builder.rooms[job["no"]]
	var target: Vector3 = (room["door_front"] as Vector3) + (room["into"] as Vector3) * (0.9 - THROW_AT) + Vector3.UP * 0.05
	kid._face(target, 1.0)
	kid.held = null
	var start := item.global_position
	item.reparent(Game.social._world, true)
	var gravity := Vector3(0, -float(ProjectSettings.get_setting("physics/3d/default_gravity")), 0)
	var velocity := (target - start) / THROW_TIME - gravity * THROW_TIME * 0.5
	item.throw_from(start, velocity, kid)   # das Kind selbst trifft der Wurf nicht
	_witnesses(kid, String(job["no"]))
	_run_off(kid)


## Lachend weg – nach Hause.
func _run_off(kid: Guest) -> void:
	kid.say(LAUGH_LINES.pick_random())
	kid._romp = true
	kid._walk_to(kid._room_point(), Guest.State.WALK)


## Zeugen (nur Erwachsene, nicht die Eltern): rufen etwas und verpetzen das Kind beim Bewohner der Tür.
func _witnesses(kid: Guest, no: String) -> void:
	var parent := kid.parent_guest()
	if parent == null or parent.dead:
		return   # Waisenkind – keine Eltern, auf die man sauer sein könnte
	var victim: Guest = null
	for guest in Game.social.living_guests():
		var g: Guest = guest
		if String(g.home["no"]) == no and not g.is_child():
			victim = g
	for guest in Game.social.living_guests():
		var w: Guest = guest
		if w.is_child() or w == parent or w.state == Guest.State.SLEEP or w.global_position.distance_to(kid.global_position) > WITNESS_RANGE \
				or not w.can_see_actor(kid) or randf() >= TATTLE_CHANCE:
			continue
		w.say(WITNESS_LINES.pick_random())
		if Game.tracing:
			print("[Streich] %s hat %s gesehen" % [w.display_name, kid.display_name])
		if no == LevelBuilder.PLAYER_ROOM:
			if Game.player and Game.player.global_position.distance_to(w.global_position) < 12.0:
				Game.say("%s: „Das war %s – das Kind von %s!“" % [w.display_name, kid.display_name, parent.display_name], 4.0)
			return
		if victim and victim != parent and victim.home["no"] != kid.home["no"]:
			var delay := 1.5 if w == victim else randf_range(TATTLE_DELAY.x, TATTLE_DELAY.y)
			get_tree().create_timer(delay, false).timeout.connect(_tell.bind(w, victim, kid, parent))
		return   # einer reicht


## Der Bewohner erfährt es: Er ist mit den Eltern des Kindes verfeindet.
func _tell(witness: Guest, victim: Guest, kid: Guest, parent: Guest) -> void:
	if not is_instance_valid(victim) or victim.dead or not is_instance_valid(parent) or parent.dead:
		return
	if victim != witness:
		victim.say(TOLD_LINES.pick_random() % [witness.display_name, kid.display_name, parent.display_name])
	else:
		victim.say("Das war %s! Na warte, %s …" % [kid.display_name, parent.display_name])
	Game.social.pals.add_feud(victim, parent)


## Laufende Streiche: bricht das Kind ab (Schreck, Feier, ins Bett), wandert das Geholte zurück in den Koffer.
func _process(_delta: float) -> void:
	for id in _jobs.keys():
		var job: Dictionary = _jobs[id]
		var kid: Guest = job["kid"]
		if is_instance_valid(kid) and not kid.dead and kid.state == Guest.State.VISIT:
			continue
		_jobs.erase(id)
		if is_instance_valid(kid) and kid.held:
			kid.stow_held()


func reset() -> void:
	_jobs.clear()


## Debug (--prank=art[,zimmer]): Das erste freie Kind steht vor der Tür (Standard Zimmer 13) und spielt diesen
## Streich (leaves, topple, pumpkin, candle, fire = brennende Kerze neben Laub und Lakengespenst); Wurfgeschosse hat es
## gleich in der Hand (ohne den Weg zum Koffer), zum Umwerfen steht ein Kürbis vor der Tür. false = kein Kind.
func debug(kind: String, no: String) -> bool:
	var kids := Game.social.living_guests().filter(func(g: Guest) -> bool: return g.is_child() and g.parent_guest() != null)
	if kids.is_empty() or not Game.social.builder.rooms.has(no):
		return false
	var kid: Guest = kids[0]
	var room: Dictionary = Game.social.builder.rooms[no]
	var front: Vector3 = room["door_front"]
	kid.global_position = front + Vector3.UP * 0.05
	kid._set_idle(5.0)
	# Der Bewohner steht im Flur und sieht zu – er wird es verpetzen (Zeuge, Feindschaft mit den Eltern)
	for guest in Game.social.living_guests():
		var g: Guest = guest
		if String(g.home["no"]) == no and not g.is_child() and g != kid.parent_guest():
			g.global_position = front + (room["along"] as Vector3) * 3.0 + Vector3.UP * 0.05
			g.look_at(Vector3(front.x, g.global_position.y, front.z), Vector3.UP)
			g._set_idle(20.0)
	if kind == "topple":
		var pumpkin := Item.create(Item.Kind.PUMPKIN)
		Game.social._world.add_child(pumpkin)
		pumpkin.global_position = front + (room["along"] as Vector3) * 0.9 + (room["into"] as Vector3) * 0.4 + Vector3.UP * 0.05
	if kind == "fire":
		for k in [Item.Kind.LEAVES, Item.Kind.SHEET_GHOST]:
			var deco := Item.create(k)
			Game.social._world.add_child(deco)
			deco.global_position = front + (room["into"] as Vector3) * 0.4 + (room["along"] as Vector3) * (0.3 if k == Item.Kind.LEAVES else -0.4) + Vector3.UP * 0.05
	if kind in ["pumpkin", "candle", "fire"]:   # gleich mit dem Wurfgeschoss in der Hand, ohne den Weg zum Koffer
		var item := kid.stock_item(Item.Kind.PUMPKIN if kind == "pumpkin" else Item.Kind.CANDLE)
		if kind == "fire":
			item.light_up(false)
		kid.global_position = front - (room["into"] as Vector3) * 2.0 + Vector3.UP * 0.05
		_go_throw(kid, no, item)
		return true
	play(kid, no, kind)
	return true
