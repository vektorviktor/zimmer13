class_name DecoSearch
extends Node
## Deko-Suche mit Gästen (Spielkonzept 5.9, entschieden 2026-10-21): Gäste ziehen los und suchen Deko – Laub im Garten,
## Dekokiste, Wäschekisten, Kerzenvorrat; Mutige auch Spinnweben in dunklen Ecken. Ins UG geht kein Gast, auch nicht mit dem
## Spieler – die alte Deko im Keller bleibt ihm (Spielkonzept 7.9, Entscheidung 2026-11-03). Trifft ein Suchender den
## Spieler, fragt er, ob er mitkommt; der Spieler kann auch selbst fragen. Dann führt der Gast, wartet, wenn der Spieler
## zurückfällt, und teilt am Fundort: ein Stück für ihn, eins für den Spieler. Dafür mag er den Spieler mehr
## und erzählt es seinen Freunden (6.16). Manchmal suchen zwei Gäste zusammen und werden dabei Freunde.
## Beide Stücke kommen aus dem Vorrat des Fundorts – aus Kisten ohne Nachschub nimmt ein Gast höchstens eins am Tag
## (ResourceSpot.guest_consume, Spielkonzept 5.10); ist nichts mehr da, gibt es nichts zu teilen.
## Kommoden (3.5, Entscheidung 2026-11-03, ZIM-39): Auch eine Kommode im Flur (oder im eigenen Zimmer) ist ein Fundort –
## der Gast zieht alle Schubladen auf, nimmt Deko und Münzen mit (Dresser.search_by_guest) und lässt sie offen; die
## Kommoden leeren sich, Nachschub gibt es keinen. Ängstliche Gäste verstecken bei Knappheit ein starkes Stück aus dem
## Koffer in einer Kommode (hide, ausgelöst von DecoPlan.hide_when_scarce) – dort kann man es klauen, und wer suchend
## darauf stößt, nimmt es mit. Nichts davon wird gespeichert (das Versteckte liegt als Gegenstand in der Welt).
## Kind von Social, erreichbar über Game.social.search.

## Pause bis zur nächsten Suche am 1. … am 31. (von selbst nur tagsüber, 11–18 Uhr); so viele gleichzeitig; so oft zu zweit
const GAP_EARLY := Vector2(100.0, 200.0)
const GAP_LATE := Vector2(40.0, 90.0)
const MAX_TRIPS := 3
const PAIR_CHANCE := 0.3
## Ab diesem Mut geht ein Gast auch an gefährliche Orte (Spinnweben-Ecken) – mit dieser Chance
const BRAVE := 0.6
const DANGER_CHANCE := 0.35
## Fragen: so nah und sichtbar muss der Spieler sein, so lange gilt die Frage (Antwort im Gespräch)
const ASK_RANGE := 6.0
const OFFER_TIME := 25.0
## Führen: ab diesem Abstand wartet er, ab LOSE_RANGE zählt die Zeit bis zum Aufgeben
const LAG_RANGE := 7.0
const LOSE_RANGE := 25.0
const LOSE_TIME := 15.0
## Ganz aufgeben, wenn er so lange unterwegs ist
const MAX_TIME := 240.0
## Anerkennung, wenn der Spieler mitgesucht hat; was er seinen Freunden erzählt (GuestPals.praise)
const RELATION := 8.0
const PRAISE := 3.0
const ASK_LINES := ["Ich geh Deko suchen – kommst du mit?", "Ich such noch Deko für mein Zimmer. Hilfst du mir?",
	"Kommst du mit? Ich weiß, wo noch Deko liegt."]
const DANGER_ASK_LINES := ["Ich hol mir Spinnweben aus der dunklen Ecke. Kommst du mit? Allein ist mir das nicht geheuer.",
	"In der dunklen Ecke hängen dicke Spinnweben. Gehst du mit?"]
const START_LINES := ["Na dann los – mir nach!", "Super! Komm, hier lang.", "Prima, zu zweit macht's mehr Spaß."]
const WAIT_LINES := ["Kommst du?", "Hier lang!", "Nicht trödeln!"]
const SHARE_LINES := ["Hier – eins für dich, eins für mich.", "Schau, gleich zwei! Nimm du das.", "Für dich. Danke fürs Mitkommen!"]
const LOST_LINES := ["Na gut, dann such ich eben allein.", "Wo bist du denn hin? Dann eben ohne dich."]
const EMPTY_DRESSER_LINES := ["Leer. Da war schon jemand.", "Nichts mehr drin – alles ausgeräumt.", "Nur Staub. Schade."]
const HIDE_LINES := ["Hier findet's keiner.", "So. Da ist es sicher.", "Das bleibt hier, bis es gebraucht wird."]
## Vor der Kommode: so weit vor ihrer Front steht der Gast
const DRESSER_FRONT := 0.75

## Gast-ID → {guest, source (ResourceSpot oder Dresser), phase (go/wait), partner ("player", Gast oder null), leader (bei
## zu zweit: der Führende), lost, time, goal; hide: true = er versteckt, was er in der Hand trägt}
var _trips := {}
## Gast-ID → Zeit, bis zu der seine Frage „Kommst du mit?“ gilt
var _offers := {}
var _cooldown := 60.0


## Beim Laden eines Spielstands (SaveManager.apply): laufende Suchen vergessen (nicht gespeichert, Gäste neu gebaut).
func reset() -> void:
	_trips.clear()
	_offers.clear()


func _process(delta: float) -> void:
	if Game.game_over or Game.social == null:
		return
	for id in _offers.keys():
		_offers[id] = float(_offers[id]) - delta
		if float(_offers[id]) <= 0.0:
			_offers.erase(id)
	for id in _trips.keys():
		if _trips.has(id):
			_step(_trips[id], delta)
	_cooldown -= delta
	if _cooldown > 0.0:
		return
	var t := Game.social.decorating._progress()
	_cooldown = randf_range(lerpf(GAP_EARLY.x, GAP_LATE.x, t), lerpf(GAP_EARLY.y, GAP_LATE.y, t))
	if Calendar.phase() == Calendar.Phase.DAY and _quiet() and _leaders() < MAX_TRIPS:   # nur tagsüber (2.4)
		var free := Game.social.living_guests().filter(func(g: Guest) -> bool: return _available(g))
		if not free.is_empty():
			start(free.pick_random())


func _quiet() -> bool:
	var social := Game.social
	return not social.party_active and not social.sleep_active and not Game.monster.is_active() \
		and not (Game.pumpkin and Game.pumpkin.is_hunting())


func _leaders() -> int:
	return _trips.values().filter(func(e: Dictionary) -> bool: return e["leader"] == null).size()


func _available(g: Guest) -> bool:
	return Game.social.decorating._available(g)


## Ist er gerade auf Deko-Suche? (Decorating._available)
func is_busy(g: Guest) -> bool:
	return _trips.has(g.id)


## Fragt er gerade „Kommst du mit?“ (für den Dialog)?
func has_offer(g: Guest) -> bool:
	return _offers.has(g.id) and _trips.has(g.id) and _trips[g.id]["partner"] == null


## Ein Gast zieht los (auch Debug --search). with_player: der Spieler kommt gleich mit; forced_source: dieser Fundort
## (Debug --kommode). false = kein Fundort.
func start(g: Guest, with_player: bool = false, forced_source: Node3D = null) -> bool:
	if g == null or g.dead or _trips.has(g.id):
		return false
	var source: Node3D = forced_source if forced_source else _source_for(g)
	if source == null:
		return false
	var entry := {"guest": g, "source": source, "phase": "go", "partner": null, "leader": null, "lost": 0.0, "time": 0.0}
	_trips[g.id] = entry
	if with_player:
		entry["partner"] = "player"
	elif randf() < PAIR_CHANCE:
		var pals := Game.social.pals.pals_of(g).filter(func(o: Guest) -> bool:
			return _available(o) and o.global_position.distance_to(g.global_position) < 20.0)
		var mates := pals if not pals.is_empty() else Game.social.living_guests().filter(func(o: Guest) -> bool:
			return o != g and _available(o) and o.global_position.distance_to(g.global_position) < 12.0)
		if not mates.is_empty():
			var mate: Guest = mates.pick_random()
			entry["partner"] = mate
			_trips[mate.id] = {"guest": mate, "source": source, "phase": "go", "partner": g, "leader": g, "lost": 0.0, "time": 0.0}
			_walk(mate, _goal(source) + mate._jitter(0.8))
	_walk(g, _goal(source))
	if Game.tracing:
		var with := "mit dir" if with_player else (("mit " + (entry["partner"] as Guest).display_name) if entry["partner"] else "allein")
		print("[Deko-Suche] %s sucht bei %s (%s)%s" % [g.display_name, _label(source), with,
			" – im UG: FEHLER" if source.global_position.y < -0.5 else ""])   # nie ins UG (7.9)
	return true


## Im Gespräch: „Lass uns zusammen Deko suchen“ bzw. „Klar, ich such mit!“ – "" = es geht los, sonst der Satz des Gastes.
func ask(g: Guest) -> String:
	if not _quiet():
		return "Jetzt? Lieber nicht."
	if g.fear >= 50.0:
		return "Ich trau mich gerade nirgendwohin."
	if _trips.has(g.id):
		if _trips[g.id]["partner"] != null:
			return "Ich bin doch schon unterwegs!"
		_trips[g.id]["partner"] = "player"
		_offers.erase(g.id)
		return ""
	if Game.social.decorating.is_crew(g):
		return "Ich schmücke doch gerade!"
	return "" if start(g, true) else "Mir fällt gerade nicht ein, wo noch Deko liegen könnte."


## Nach dem Gespräch weiter (DialogUI): Er ruft „Mir nach!“ und geht los.
func lead_off(g: Guest) -> void:
	if _trips.has(g.id):
		g.say(START_LINES.pick_random())
		_walk(g, _trips[g.id]["goal"])


## Ein Fundort: der nächste erreichbare von ein paar in der Nähe – Mutige auch Spinnweben, nie im UG (7.9); sonst
## auch Kommoden, in denen noch etwas sein kann (_dressers_for).
func _source_for(g: Guest) -> Node3D:
	var danger := float(g.profile["brave"]) >= BRAVE and not g.is_child() and randf() < DANGER_CHANCE
	var spots: Array = []
	for node in get_tree().get_nodes_in_group("resource_spots"):
		var spot := node as ResourceSpot
		if spot.global_position.y > -0.5 and _risky(spot) == danger and not spot.kind in [Item.Kind.SODA_CAN, Item.Kind.BULB] and spot.guest_can_take():   # Dosen und Birnen sind keine Deko
			spots.append(spot)
	if not danger:
		spots.append_array(_dressers_for(g))
	spots.sort_custom(func(a: Node3D, b: Node3D) -> bool:
		return a.global_position.distance_to(g.global_position) < b.global_position.distance_to(g.global_position))
	var near := spots.slice(0, 5)
	near.shuffle()
	for spot: Node3D in near:
		if Game.social.decorating._reachable(g.global_position, _goal(spot)):
			return spot
	return null


## Kommoden, die g durchsuchen darf (Dresser.guests_search, nicht im UG, nicht in einem fremden Zimmer) und in denen
## noch etwas sein kann: eine nie geöffnete Schublade oder etwas, das er mitnähme (Dresser.guest_takes). Ein Gang über
## alle Gegenstände – nur beim Aufbruch, nie je Bild (ZIM-124).
func _dressers_for(g: Guest) -> Array:
	var found: Array = []
	var rest: Array = []
	for node in get_tree().get_nodes_in_group("dressers"):
		var d := node as Dresser
		if not d.guests_search() or d.global_position.y < -0.5 or not may_enter(g, d.global_position):
			continue
		if d.searched.has(false):
			found.append(d)
		else:
			rest.append(d)
	if rest.is_empty():
		return found
	for node in get_tree().get_nodes_in_group("items"):
		var item := node as Item
		if not Dresser.guest_takes(item, g):
			continue
		for d: Dresser in rest:
			if d.holds_point(item.global_position):
				found.append(d)
				rest.erase(d)
				break
		if rest.is_empty():
			break
	return found


## Darf g an diese Stelle? Nicht in ein fremdes Hotelzimmer (seins, Flure und Gemeinschaftsräume schon).
static func may_enter(g: Guest, p: Vector3) -> bool:
	var room := Game.social.builder.room_at(p)
	return room == String(g.home["no"]) or not Game.director.rooms.has(room)


## Gefährlicher Fundort: Spinnweben-Ecke.
static func _risky(source: Node3D) -> bool:
	return source is ResourceSpot and (source as ResourceSpot).kind == Item.Kind.COBWEB


static func _label(source: Node3D) -> String:
	return (source as ResourceSpot).label if source is ResourceSpot else "der Kommode"


## Wohin er geht: bei der Kommode vor ihre Front, sonst an den Fundort (jeweils der nächste Punkt im NavMesh).
func _goal(source: Node3D) -> Vector3:
	var at := source.global_position
	if source is Dresser:
		at += source.global_transform.basis.z * DRESSER_FRONT
	return NavigationServer3D.map_get_closest_point(source.get_world_3d().navigation_map, at)


func _walk(g: Guest, point: Vector3) -> void:
	if _trips.has(g.id):
		_trips[g.id]["goal"] = point
	g._walk_to(point, Guest.State.SEARCH)


func _step(entry: Dictionary, delta: float) -> void:
	var g: Guest = entry["guest"]
	entry["time"] = float(entry["time"]) + delta
	if g.dead or not g.state in [Guest.State.SEARCH, Guest.State.IDLE, Guest.State.TALKING] or float(entry["time"]) > MAX_TIME \
			or not _quiet():
		_finish(g)   # erschreckt, versteckt, Feier, Nachtruhe … – die Suche ist vorbei
		return
	if g.state == Guest.State.TALKING:
		return
	var p := Game.player
	# Fragen: Wer allein sucht und dem Spieler begegnet, fragt einmal
	if entry["partner"] == null and entry["leader"] == null and not entry.get("asked", false) and p and not p.dead \
			and p.global_position.distance_to(g.global_position) < ASK_RANGE and g.can_see_actor(p) and p.recognized_by(g) \
			and Social.tier(g) >= Social.Tier.NEUTRAL:
		entry["asked"] = true
		_offers[g.id] = OFFER_TIME
		g.say((DANGER_ASK_LINES if _risky(entry["source"]) else ASK_LINES).pick_random())
	if entry["partner"] is String and p and not p.dead:
		var d := p.global_position.distance_to(g.global_position)
		entry["lost"] = float(entry["lost"]) + delta if d > LOSE_RANGE else 0.0
		if float(entry["lost"]) > LOSE_TIME:
			g.say(LOST_LINES.pick_random())
			entry["partner"] = null
			entry["asked"] = true
			if g.state == Guest.State.IDLE:
				_walk(g, entry["goal"])
		elif d > LAG_RANGE and g.state == Guest.State.SEARCH:
			g._set_idle(30.0)   # wartet auf den Spieler
			var to := p.global_position - g.global_position
			g.rotation.y = atan2(-to.x, -to.z)
			if randf() < 0.5:
				g.say(WAIT_LINES.pick_random())
			return
		elif d <= LAG_RANGE * 0.6 and g.state == Guest.State.IDLE:
			_walk(g, entry["goal"])
			return
		if g.state == Guest.State.IDLE:
			g._timer = 30.0
			return
	elif g.state == Guest.State.IDLE:
		_walk(g, entry["goal"])   # nach einem Gespräch weiter


## Guest._arrive im Zustand SEARCH: am Fundort – teilen, dann mit seinem Stück heim (CARRY_HOME).
func on_arrived(g: Guest) -> void:
	if not _trips.has(g.id):
		g._set_idle(randf_range(2.0, 5.0))
		return
	var entry: Dictionary = _trips[g.id]
	if not is_instance_valid(entry["source"]):
		_finish(g)
		return
	if entry["source"] is Dresser:
		_at_dresser(g, entry)
		return
	var source: ResourceSpot = entry["source"]
	if not source.guest_consume():
		_finish(g)   # leer oder heute schon jemand da gewesen
		return
	var kinds: Array = source.pool if not source.pool.is_empty() else [source.kind]
	var mine := g.stock_item(kinds.pick_random())
	var partner = entry["partner"]
	if partner is String and source.consume():
		var p := Game.player
		if p and not p.dead and p.global_position.distance_to(g.global_position) < LAG_RANGE * 1.5:
			var theirs := g.stock_item(kinds.pick_random())
			theirs.owner_id = "player"
			p.receive_item(theirs)
			g.say(SHARE_LINES.pick_random())
			Game.social.change_relation(g, RELATION)
			Game.social.add_deed(g, "gifts_from")
			Game.social.pals.praise(g, PRAISE)   # er erzählt es seinen Freunden (6.16)
			if Game.tracing:
				print("[Deko-Suche] %s teilt mit dir: %s, Beziehung %.0f" % [g.display_name, theirs.display_name, g.relation])
	elif partner is Guest and is_instance_valid(partner) and entry["leader"] == null:
		Game.social.pals.note(g, partner)   # zusammen gesucht (6.16)
	_trips.erase(g.id)
	_offers.erase(g.id)
	g.stow_held()   # hält er noch etwas (Geschenk), wandert es in den Vorrat – sonst bliebe es verwaist in der Hand
	g._take_into_hand(mine)
	g._walk_to(g._room_point(), Guest.State.CARRY_HOME)


## An der Kommode (ZIM-39): verstecken (hide) oder alle Schubladen durchsuchen – Deko nimmt er mit, die erste in die
## Hand, den Rest in den Koffer, Münzen in die Tasche; mit dem Spieler teilt er, wenn es zwei Stück Deko sind.
func _at_dresser(g: Guest, entry: Dictionary) -> void:
	var dresser: Dresser = entry["source"]
	var to := dresser.global_position - g.global_position
	g.rotation.y = atan2(-to.x, -to.z)
	_trips.erase(g.id)
	_offers.erase(g.id)
	if entry.get("hide", false):
		var item := g.held
		g.held = null
		if item:
			item.get_parent().remove_child(item)
			item.set_held(false)
			dresser.stash(item)
			g.say(HIDE_LINES.pick_random())
			if Game.tracing:
				print("[Kommode] %s versteckt %s in der Kommode" % [g.display_name, item.display_name])
		g._set_idle(randf_range(2.0, 5.0))
		return
	var taken := dresser.search_by_guest(g)
	var deco: Array[Item] = []
	var coins := 0
	for item in taken:
		if item.kind == Item.Kind.COINS:
			coins += item.coin_value
			item.free()
		else:
			deco.append(item)
	g.money += coins
	var p := Game.player
	if entry["partner"] is String and deco.size() >= 2 and p and not p.dead \
			and p.global_position.distance_to(g.global_position) < LAG_RANGE * 1.5:
		var theirs: Item = deco.pop_back()
		theirs.owner_id = "player"
		p.receive_item(theirs)
		g.say(SHARE_LINES.pick_random())
		Game.social.change_relation(g, RELATION)
		Game.social.add_deed(g, "gifts_from")
		Game.social.pals.praise(g, PRAISE)
	if Game.tracing:
		print("[Kommode] %s durchsucht die Kommode: %s, %d Münzen" % [g.display_name,
			", ".join(deco.map(func(i: Item) -> String: return i.display_name)) if not deco.is_empty() else "keine Deko", coins])
	if deco.is_empty():
		if coins == 0:
			g.say(EMPTY_DRESSER_LINES.pick_random())
		g._set_idle(randf_range(2.0, 5.0))
		return
	g.stow_held()
	for item in deco.slice(1):
		g.stock[item.kind] = int(g.stock.get(item.kind, 0)) + 1
		item.free()
	g._take_into_hand(deco[0])
	g._walk_to(g._room_point(), Guest.State.CARRY_HOME)


## Aus DecoPlan.hide_when_scarce: g trägt ein Stück aus seinem Koffer zu dieser Kommode und versteckt es darin
## (_at_dresser). Er fragt niemanden mit. false = schon unterwegs.
func hide(g: Guest, dresser: Dresser, kind: int) -> bool:
	if g == null or g.dead or _trips.has(g.id) or g.held:
		return false
	g.stock[kind] = int(g.stock.get(kind, 0)) - 1
	g._take_into_hand(g.stock_item(kind))
	_trips[g.id] = {"guest": g, "source": dresser, "phase": "go", "partner": null, "leader": null, "lost": 0.0,
		"time": 0.0, "hide": true, "asked": true}
	_walk(g, _goal(dresser))
	if Game.tracing:
		print("[Kommode] %s will %s in einer Kommode verstecken" % [g.display_name, g.held.display_name])
	return true


## Suche abbrechen (der Gast bleibt, wie er ist; wer gerade dorthin ging, macht etwas anderes).
func _finish(g: Guest) -> void:
	var entry: Dictionary = _trips.get(g.id, {})
	_trips.erase(g.id)
	_offers.erase(g.id)
	if entry.get("hide", false) and not g.dead:
		g.stow_held()   # zurück in den Koffer
	if not g.dead and g.state in [Guest.State.SEARCH, Guest.State.IDLE]:
		g._set_idle(randf_range(2.0, 5.0))
	var partner = entry.get("partner")
	if partner is Guest and is_instance_valid(partner) and _trips.has(partner.id):
		_finish(partner)
