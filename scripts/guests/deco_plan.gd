class_name DecoPlan
extends Node
## Gäste schmücken mit Plan – und klauen bei Knappheit (Spielkonzept 5.10, Stufe 3). Kind von Decorating, erreichbar über
## Game.social.decorating.plan; die Gänge selbst laufen als Allein-Schmücken (Decorating.start_solo_door).
## - **Angst:** Wer Angst hat, schmückt zuerst die eigene Tür – solange sie nicht sicher hält.
## - **Tod in der Nähe:** Die Nachbarn eines Toten schmücken ihre Türen nach (on_guest_died).
## - **Freunde:** schmücken die Tür eines Freundes (6.16) mit, die nicht hält – auch Zimmer 13, wenn sie mit dir
##   befreundet sind.
## - **Klauen:** Sind die Kisten fast leer, hat ein ängstlicher Gast nichts Starkes mehr im Koffer und hält seine Tür nicht,
##   holt er sich ein starkes Stück von einer gut geschmückten fremden Tür (steal_when_scarce, aus Guest._try_steal) –
##   nie von Freunden, Familie oder Mitbewohnern, nie vom Spieler. Folgen für Freundschaften (Streit, 6.16) sind offen.
## Nichts davon wird gespeichert – nach dem Laden zählen nur Angst, Deko und Kisten.

## Pause zwischen zwei geplanten Gängen am Monatsanfang bzw. an Halloween (s), so viele zugleich, je Gast am Spieltag
const GAP_EARLY := Vector2(150.0, 300.0)
const GAP_LATE := Vector2(40.0, 90.0)
const PLAN_MAX := 2
const DAILY := 2
## Ab dieser Angst schmückt er die eigene Tür; ab PANIC versteckt er sich lieber
const AFRAID := 35.0
const PANIC := 80.0
## Eine Tür gilt erst als sicher, wenn ihre Abschreckung den Druck dort um so viel übertrifft (der Anspruch steigt)
const SAFE_MARGIN := 1.5
## Freunde: so oft schmückt ein freier Gast ohne Angst die Tür eines Freundes, wenn eine nicht hält
const FRIEND_CHANCE := 0.5
## Tod in der Nähe: Nachbarn bis so weit (Türen, dasselbe Stockwerk), höchstens so viele, nach so langer Zeit (s);
## wer bis MOURN_GIVE_UP nicht frei war, lässt es
const MOURN_RANGE := 14.0
const MOURNERS := 4
const MOURN_DELAY := Vector2(60.0, 240.0)
const MOURN_GIVE_UP := 900.0
## Knappheit: Die Kisten ohne Nachschub (ResourceSpot.runs_out) haben höchstens noch diesen Anteil ihres Vorrats
const SCARCE_SHARE := 0.25
## Klauen: ab dieser Angst, mit dieser Chance je Versuch (× 0,5 + Gier), einmal am Spieltag, nur wenn der Spieler
## weiter weg ist; Deko zählt bis LOOT_REACH vor einer Tür zu ihr
const THEFT_FEAR := 25.0
const THEFT_CHANCE := 0.35
const THEFT_UNSEEN := 8.0
const LOOT_REACH := 2.5
## Findet er nichts zu klauen, sucht er frühestens nach so vielen Sekunden wieder (die Suche prüft jede fremde Tür)
const THEFT_RETRY := 600.0

var _deco: Decorating
var _cooldown := 60.0
var _tick := 0.0
var _trips := {}         ## Gast-ID → [Spieltag, Gänge an dem Tag]
var _theft_day := {}     ## Gast-ID → Spieltag des letzten Diebstahls
var _theft_retry := {}   ## Gast-ID → MonsterDirector.elapsed, ab dem er nach erfolgloser Suche wieder sucht
var _mourners: Array[Dictionary] = []   ## {id, at (MonsterDirector.elapsed), dead (Name)}
var _mine: Array[String] = []           ## Gäste, die gerade mit Plan unterwegs sind
## Debug (--schmuckplan): Nachbarn eines Toten machen sich nach wenigen Sekunden auf
var debug_fast := false


func _init(decorating: Decorating) -> void:
	_deco = decorating


## Beim Laden: alles Laufende vergessen (die Gäste werden neu gebaut).
func reset() -> void:
	_mourners.clear()
	_mine.clear()


func _process(delta: float) -> void:
	if Game.game_over or Game.director == null:
		return
	_tick -= delta
	_cooldown -= delta
	if _tick > 0.0:
		return
	_tick = 5.0
	_mine = _mine.filter(func(id: String) -> bool:
		var g := _guest(id)
		return g != null and not _deco.solo_site(g).is_empty())
	if not _calm() or _mine.size() >= PLAN_MAX:
		return
	if _start_mourning():
		return
	if _cooldown > 0.0:
		return
	_cooldown = 20.0   # nichts gefunden: bald noch einmal
	if _start_planned():
		var t := clampf(float(Calendar.today() - Calendar.FIRST_DAY) / float(Calendar.HALLOWEEN - Calendar.FIRST_DAY), 0.0, 1.0)
		_cooldown = randf_range(lerpf(GAP_EARLY.x, GAP_LATE.x, t), lerpf(GAP_EARLY.y, GAP_LATE.y, t))


## Ruhig genug zum Schmücken – wie beim Allein-Schmücken (Decorating._update_solo).
func _calm() -> bool:
	var social := Game.social
	return not (social.party_active or social.sleep_active or Game.monster.is_active() \
		or (Game.pumpkin and Game.pumpkin.is_hunting()))


## Frei für einen Gang – wie Decorating._available, aber auch mit Angst (nur nicht in Panik).
func _free(g: Guest) -> bool:
	return not g.dead and g.hiding == null and g.held == null and g.state in [Guest.State.IDLE, Guest.State.WALK] \
		and not Grinch.is_grinch(g) and g.fear < PANIC and g.drunk < BarTap.DRUNK and not g.is_following() \
		and not Game.social.has_fun(g) and not _deco.is_crew(g) and _deco.solo_site(g).is_empty() \
		and not Game.social.search.is_busy(g) and g.wound == "" and _trips_today(g) < DAILY


func _trips_today(g: Guest) -> int:
	var t: Array = _trips.get(g.id, [0, 0])
	return int(t[1]) if int(t[0]) == Calendar.today() else 0


## Hält die Tür von Zimmer no nicht sicher? (Abschreckung unter Druck × SAFE_MARGIN)
func weak(no: String) -> bool:
	var front: Vector3 = Game.director.rooms[no]["door_front"]
	return Game.director.deterrence_at(front) < Game.director.pressure_at(front) * SAFE_MARGIN


## Wie sicher die Tür hält (Abschreckung / Druck) – die schwächste zuerst.
func _safety(no: String) -> float:
	var front: Vector3 = Game.director.rooms[no]["door_front"]
	return Game.director.deterrence_at(front) / maxf(Game.director.pressure_at(front), 0.1)


func _go(g: Guest, no: String, why: String) -> bool:
	if not _deco.start_solo_door(g, no, why):
		return false
	_trips[g.id] = [Calendar.today(), _trips_today(g) + 1]
	_mine.append(g.id)
	return true


# --- Tod in der Nähe ---------------------------------------------------------------------

## Ein Gast ist tot (Social.on_guest_died): Die nächsten Nachbarn schmücken bald ihre eigene Tür nach.
func on_guest_died(dead: Guest) -> void:
	var at: Vector3 = dead.home["door_front"]
	var near: Array = []
	for other in Game.social.living_guests():
		var g: Guest = other
		var front: Vector3 = g.home["door_front"]
		if g != dead and absf(front.y - at.y) < 1.5 and front.distance_to(at) < MOURN_RANGE \
				and String(g.home["no"]) != LevelBuilder.PLAYER_ROOM:
			near.append(g)
	near.sort_custom(func(a: Guest, b: Guest) -> bool:
		return (a.home["door_front"] as Vector3).distance_to(at) < (b.home["door_front"] as Vector3).distance_to(at))
	var delay := Vector2(3.0, 8.0) if debug_fast else MOURN_DELAY
	for g: Guest in near.slice(0, MOURNERS):
		_mourners.append({"id": g.id, "at": Game.director.elapsed + randf_range(delay.x, delay.y), "dead": dead.display_name})
	if Game.tracing and not near.is_empty():
		print("[Schmuckplan] Tod von %s: %s schmücken nach" % [dead.display_name,
			", ".join(near.slice(0, MOURNERS).map(func(g: Guest) -> String: return g.display_name))])


func _start_mourning() -> bool:
	var now := Game.director.elapsed
	for m in _mourners.duplicate():
		if now < float(m["at"]):
			continue
		var g := _guest(String(m["id"]))
		if g == null or now - float(m["at"]) > MOURN_GIVE_UP:
			_mourners.erase(m)
			continue
		if not _free(g):
			continue
		_mourners.erase(m)
		if _go(g, String(g.home["no"]), "nach dem Tod von %s" % m["dead"]):
			return true
	return false


# --- Angst und Freunde -------------------------------------------------------------------

## Ein freier Gast mit Plan: mit Angst an die eigene Tür, sonst vielleicht an die eines Freundes, die nicht hält.
func _start_planned() -> bool:
	var free := Game.social.living_guests().filter(func(g: Guest) -> bool: return _free(g))
	free.shuffle()
	for g: Guest in free.slice(0, 6):
		var own := String(g.home["no"])
		if g.fear >= AFRAID and own != LevelBuilder.PLAYER_ROOM and weak(own):
			if _go(g, own, "Angst"):
				return true
			continue
		if randf() < FRIEND_CHANCE:
			var friend := friend_door(g)
			if friend != "" and _go(g, friend, "für einen Freund" if friend != LevelBuilder.PLAYER_ROOM else "für dich"):
				return true
	return false


## Die schwächste Tür seiner Freunde (6.16), die nicht hält – Zimmer 13, wenn er mit dir befreundet ist. "" = keine.
func friend_door(g: Guest) -> String:
	var options: Array[String] = []
	for pal in Game.social.pals.pals_of(g):
		var no := String(pal.home["no"])
		if no != String(g.home["no"]) and not no in options:
			options.append(no)
	if Social.tier(g) >= Social.Tier.FRIEND:
		options.append(LevelBuilder.PLAYER_ROOM)
	var best := ""
	for no in options:
		if weak(no) and (best == "" or _safety(no) < _safety(best)):
			best = no
	return best


# --- Klauen bei Knappheit ----------------------------------------------------------------

## Sind die Kisten mit starker Deko fast leer?
func scarce() -> bool:
	var left := 0
	var full := 0
	for node in get_tree().get_nodes_in_group("resource_spots"):
		var spot := node as ResourceSpot
		if spot.runs_out():
			left += spot.uses
			full += spot.max_uses
	return full == 0 or left <= full * SCARCE_SHARE


## Noch etwas Starkes (kein Füllmaterial) im Koffer?
static func has_strong_stock(g: Guest) -> bool:
	for kind in g.stock:
		if int(g.stock[kind]) > 0 and not kind in Item.FILLER_KINDS:
			return true
	return false


## Aus Guest._try_steal: Klaut er bei Knappheit ein starkes Stück von einer fremden Tür? Er bringt es wie jeder Dieb an
## seine Tür (Guest._finish_steal). forced: ohne Bedingungen und Zufall (Debug).
func steal_when_scarce(g: Guest, forced: bool = false) -> bool:
	if g.is_child():
		return false
	if not forced:
		var own := String(g.home["no"])
		if g.fear < THEFT_FEAR or own == LevelBuilder.PLAYER_ROOM or int(_theft_day.get(g.id, -1)) == Calendar.today() \
				or Game.director.elapsed < float(_theft_retry.get(g.id, 0.0)) \
				or has_strong_stock(g) or not scarce() or not weak(own) \
				or randf() > THEFT_CHANCE * (0.5 + float(g.profile.get("greed", 0.5))):
			return false
	var loot := _loot_for(g, not forced)
	if loot.is_empty():
		_theft_retry[g.id] = Game.director.elapsed + THEFT_RETRY
		return false
	var item: Item = loot["item"]
	_theft_day[g.id] = Calendar.today()
	g._steal_item = item
	g._walk_to(item.global_position, Guest.State.STEAL)
	if Game.tracing:
		print("[Schmuckplan] Knappheit: %s klaut %s von der Tür von Zimmer %s" % [g.display_name, item.display_name,
			String(Game.director.rooms[loot["no"]]["sign"])])
	return true


## Das beste starke Stück an einer fremden Tür, die hält (nicht von Freunden, Familie, Mitbewohnern, nicht vom Spieler,
## nicht unter seinen Augen – unseen) – {item, no} oder {}.
func _loot_for(g: Guest, unseen: bool = true) -> Dictionary:
	var doors := _strangers(g).filter(func(no: String) -> bool: return not weak(no))
	var best := {}
	var best_score := -INF
	for node in get_tree().get_nodes_in_group("items"):
		var item := node as Item
		if item.is_held or item.deco_strength <= 0.0 or item.is_filler() or item.is_toppled() or item.owner_id == "player" \
				or item.owner_id == g.id:
			continue
		if unseen and Game.player and Game.player.global_position.distance_to(item.global_position) < THEFT_UNSEEN:
			continue
		for no in doors:
			var front: Vector3 = Game.director.rooms[no]["door_front"]
			if absf(item.global_position.y - front.y) > 3.0 \
					or Vector2(item.global_position.x - front.x, item.global_position.z - front.z).length() > LOOT_REACH:
				continue
			var score := item.deco_value() - item.global_position.distance_to(g.global_position) / 10.0
			if score > best_score and not Game.social.is_in_closed_chest(item):
				best_score = score
				best = {"item": item, "no": no}
			break
	# Weg im Flur von Tür zu Tür – aus dem eigenen Zimmer kommt er immer, und an einer abgeschlossenen Tür selbst
	# scheitert Decorating._reachable sonst
	if not best.is_empty() and not _deco._reachable(_hall(String(g.home["no"])), _hall(String(best["no"]))):
		if Game.tracing:
			print("[Schmuckplan] %s käme nicht zu %s an Zimmer %s" % [g.display_name, (best["item"] as Item).display_name, best["no"]])
		return {}
	return best


## Flurpunkt vor der Tür von Zimmer no (weit genug weg, dass Decorating._reachable die Tür selbst nicht stört).
func _hall(no: String) -> Vector3:
	var room: Dictionary = Game.director.rooms[no]
	return room["door_front"] - (room["into"] as Vector3) * 0.8


## Bewohnte Zimmer ohne Freunde, Familie oder Mitbewohner von g (und nicht Zimmer 13).
func _strangers(g: Guest) -> Array[String]:
	var residents := {}
	for other in Game.social.living_guests():
		var o: Guest = other
		var no := String(o.home["no"])
		if not residents.has(no):
			residents[no] = []
		residents[no].append(o)
	var result: Array[String] = []
	for no in Game.director.inhabited_rooms():
		if no == String(g.home["no"]) or no == LevelBuilder.PLAYER_ROOM \
				or (residents.get(no, []) as Array).any(func(o: Guest) -> bool: return Game.social.pals.are_pals(g, o)):
			continue
		result.append(no)
	return result


func _guest(id: String) -> Guest:
	for other in Game.social.living_guests():
		if (other as Guest).id == id:
			return other
	return null


# --- Debug (--schmuckplan) ----------------------------------------------------------------

## Debug: what = angst | tod | freund | klau mit dem Gast who (null = einer, der passt). Gibt die Tür zurück, vor die der
## Spieler sich stellt ("" = nichts gestartet).
func debug(what: String, who: Guest) -> String:
	var guests := Game.social.living_guests().filter(func(g: Guest) -> bool:
		return not g.is_child() and String(g.home["no"]) != LevelBuilder.PLAYER_ROOM and not Grinch.is_grinch(g))
	guests.shuffle()
	if who == null and guests.is_empty():
		return ""
	var g: Guest = who if who else guests[0]
	match what:
		"angst":
			g.fear = 60.0
			print("[Schmuckplan] Debug: %s hat Angst" % g.display_name)
			return String(g.home["no"]) if _go(g, String(g.home["no"]), "Angst") else ""
		"freund":
			g.relation = maxf(g.relation, 60.0)
			print("[Schmuckplan] Debug: %s ist mit dir befreundet" % g.display_name)
			return LevelBuilder.PLAYER_ROOM if _go(g, LevelBuilder.PLAYER_ROOM, "für dich") else ""
		"tod":
			debug_fast = true
			return String(g.home["no"])   # main.gd lässt ihn sterben (on_guest_died)
		"klau":
			for node in get_tree().get_nodes_in_group("resource_spots"):
				var spot := node as ResourceSpot
				if spot.runs_out():
					spot.uses = 0
			# wer nicht hinkommt (abgeschlossene Tür auf dem Weg), dem nächsten versuchen – ohne Angabe bis zu sechs
			var loot := {}
			for thief: Guest in ([who] if who else guests.slice(0, 6)):
				g = thief
				loot = _loot_for(g, false)
				if loot.is_empty():
					_debug_bait(g)
					loot = _loot_for(g, false)
				if not loot.is_empty():
					break
			if loot.is_empty():
				print("[Schmuckplan] Debug: keine erreichbare fremde Tür mit starker Deko")
				return ""
			g.fear = 60.0
			var no := String(loot["no"])
			print("[Schmuckplan] Debug: Kisten leer, %s hat Angst" % g.display_name)
			get_tree().create_timer(2.0, false).timeout.connect(func() -> void:
				if is_instance_valid(g) and not g.dead:
					steal_when_scarce(g, true))
			return no
	return ""


## Debug: Vor die nächste fremde Tür (kein Freund) stellt ihr Bewohner zwei brennende Kürbisse.
func _debug_bait(g: Guest) -> void:
	var doors := _strangers(g)
	doors.sort_custom(func(a: String, b: String) -> bool:
		return (Game.director.rooms[a]["door_front"] as Vector3).distance_to(g.global_position) \
			< (Game.director.rooms[b]["door_front"] as Vector3).distance_to(g.global_position))
	for no in doors.slice(0, 1):
		var owner := ""
		for other in Game.social.living_guests():
			if String((other as Guest).home["no"]) == no:
				owner = (other as Guest).id
		var room: Dictionary = Game.director.rooms[no]
		var front: Vector3 = room["door_front"]
		var along: Vector3 = room["along"]
		for side in [-0.6, 0.6]:
			var pumpkin := Item.create(Item.Kind.CARVED_PUMPKIN)
			pumpkin.owner_id = owner
			Game.player.get_parent().add_child(pumpkin)
			pumpkin.global_position = front + along * side + Vector3.UP * 0.05
