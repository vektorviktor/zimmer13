class_name Decorating
extends Node3D
## Schmück-Aktionen (Spielkonzept 5.9, „Das Hotel schmückt sich“): Ab und zu ruft ein Gast zum gemeinsamen
## Schmücken auf – eine Zimmertür, ein Flurabschnitt, eine Flurecke oder eine Wand der Lobby, nie der Partyraum.
## Mitmacher holen Deko aus ihrem Zimmer (aus dem Koffer, sonst etwas Gebasteltes), tragen sie sichtbar hin und hängen
## bzw. stellen sie auf. Der Spieler wird per Meldung oder Anruf eingeladen; wer Deko dazuhängt oder dabei ist, gewinnt
## die Mitmacher als Freunde, und allen sinkt die Angst. Gegen Monatsende werden die Aktionen häufiger und größer – so
## wächst die Deko bis Halloween. Die Deko bleibt als normale Gegenstände liegen (Besitzer: wer sie aufgehängt hat) und
## wird mit ihnen gespeichert; die Aktionen selbst nicht.
## Seit 2026-10-21: mehrere Aktionen zugleich, selbst aufrufen („Lass uns hier schmücken!“, auch an Zimmer 13) und das
## große Schmücken – 10–20 Gäste schmücken mehrere Stellen eines Flurbereichs oder der Lobby, jeder mit einem Armvoll
## Deko. Mitmacher werden dabei Freunde untereinander (6.16). Kind von Social, erreichbar über Game.social.decorating.

## Pause bis zur nächsten Aktion: am 1. Oktober … am 31. (dazwischen linear); nach dem Laden bzw. Start. Die Gäste
## rufen nur tagsüber (11–18 Uhr, Spielkonzept 2.4) zum Schmücken auf – der Spieler jederzeit.
const GAP_EARLY := Vector2(420.0, 720.0)
const GAP_LATE := Vector2(100.0, 200.0)
const FIRST_GAP := Vector2(120.0, 240.0)
## Mitmacher außer dem Rufer: am Monatsanfang … am Monatsende; so oft holt jeder Deko
const HELPERS := Vector2i(1, 5)
const TRIPS := Vector2i(1, 2)
## Wer mitmachen kann: wohnt so nah an der Stelle (gleiches Stockwerk) und ist nicht weiter weg als HELPER_RANGE;
## Freunde des Rufers (6.16) kommen zuerst und auch von weiter her (PAL_RANGE)
const HOME_RANGE := 40.0
const HELPER_RANGE := 60.0
const PAL_RANGE := 90.0
## Spätestens dann ist Schluss; Deko des Spielers in diesem Umkreis zählt, so nah ist er „dabei“
const MAX_TIME := 180.0
## So lange bleibt der Rufer mindestens an der Stelle (Zeit für den Spieler, dazuzukommen)
const MIN_TIME := 90.0
const SITE_RADIUS := 4.5
const PRESENT_RANGE := 9.0
## Dabei gewesen: so lange in der Nähe (ohne eigene Deko) reicht
const PRESENT_TIME := 30.0
## Am Ende: Angst der Mitmacher sinkt; hat der Spieler mitgemacht, mögen sie ihn mehr (+ je Stück, höchstens),
## sein Schock sinkt
const FEAR_RELIEF := 25.0
const RELATION := 5.0
const RELATION_PER_ITEM := 2.0
const RELATION_MAX := 11.0
const SHOCK_RELIEF := 0.25
## Höchstens so viele hängende Lichterketten im Hotel (jede ist ein Licht) – danach Fledermäuse
const LIGHT_STRING_CAP := 24
## Mehrere zugleich (2026-10-21): so viele Aktionen der Gäste vor bzw. ab Monatsmitte (ohne die eigene und das
## große Schmücken); so weit liegen gleichzeitig geschmückte Stellen mindestens auseinander
const MAX_SMALL := Vector2i(1, 2)
const SITE_SPACING := 8.0
## Selbst aufrufen (2026-10-21): so nah an einer Zimmertür gilt sie als Stelle
const DOOR_REACH := 2.5
## Großes Schmücken (2026-10-21): Pause in Spieltagen am Monatsanfang … am Ende (erreicht nach 1/BIG_RAMP des Monats,
## also etwa ab dem 24. täglich), das erste nach dem Start; so viele Gäste, so viele Stellen in BIG_RADIUS um die Mitte
const BIG_GAP_EARLY := Vector2(2.5, 3.5) * Calendar.DAY_SECONDS
const BIG_GAP_LATE := Vector2(0.67, 1.07) * Calendar.DAY_SECONDS
const BIG_FIRST_GAP := Vector2(1.0, 2.0) * Calendar.DAY_SECONDS
const BIG_RAMP := 1.3
const BIG_GUESTS := Vector2i(10, 20)
const BIG_SITES := Vector2i(3, 5)
const BIG_RADIUS := 22.0
const BIG_MAX_TIME := 300.0
const BIG_MIN_TIME := 150.0
## Selbst ausrufen: so viele Gäste müssen mindestens „freundlich“ sein
const BIG_FRIENDS := 8
## Armvoll: so viele Stücke trägt ein Gast beim großen Schmücken auf einmal; bei kleinen Aktionen mit dieser Chance
## (× Monatsfortschritt) zwei
const ARMFUL := Vector2i(2, 3)
const SMALL_ARMFUL := 0.5
## Deko je Ebene einer Stelle: oben (über allem), an der Wand, am Boden; Höhe über dem Boden an der Wand
const TOP_KINDS := [Item.Kind.LIGHT_STRING]
const WALL_KINDS := [Item.Kind.SHEET_GHOST, Item.Kind.BAT_GARLAND, Item.Kind.SPIDER, Item.Kind.COBWEB]
const FLOOR_KINDS := [Item.Kind.CARVED_PUMPKIN, Item.Kind.PUMPKIN, Item.Kind.MINI_PUMPKIN, Item.Kind.SKULL, Item.Kind.BROOM, Item.Kind.LEAVES]
const WALL_HEIGHT := {Item.Kind.SHEET_GHOST: 2.15, Item.Kind.BAT_GARLAND: 2.25, Item.Kind.SPIDER: 2.35, Item.Kind.COBWEB: 2.2}
const TOP_HEIGHT := 2.5
const LAYER_KINDS := {"top": TOP_KINDS, "wall": WALL_KINDS, "floor": FLOOR_KINDS}
## Lobby (Wunsch 2026-10-20): so oft schmückt eine Aktion die Lobby; Mitmacher wohnen dann irgendwo in LOBBY_HOME_RANGE
const LOBBY_CHANCE := 0.3
const LOBBY_HOME_RANGE := 70.0
## Allein unterwegs: ab und zu trägt ein Gast ein Stück Deko herum und hängt es in seinem Zimmer oder in der Lobby
## auf – Pause dazwischen am 1. … am 31.; so viele gleichzeitig; so oft geht es in die Lobby (sonst ins Zimmer)
const SOLO_GAP_EARLY := Vector2(80.0, 160.0)
const SOLO_GAP_LATE := Vector2(25.0, 60.0)
const SOLO_MAX := 4
const SOLO_LOBBY := 0.25
## Dauerhaft (Wunsch 2026-10-21): so viele Gäste sind immer mit Deko unterwegs (Monatsanfang bzw. ab Monatsmitte), so oft
## geht ihr Stück irgendwo ins Hotel – dorthin, wo am wenigsten hängt, so wird bis Halloween alles festlich –, und so
## gemächlich schlendern sie damit (× Gehtempo)
const SOLO_MIN := Vector2i(1, 2)
const SOLO_HOTEL := 0.5
const SOLO_STROLL := 0.7
## Ist der Koffer leer, bringt er Füllmaterial mit (Gewichte) – Starkes gibt es nicht mehr aus dem Nichts, nur aus dem
## Koffer oder den Kisten (Spielkonzept 5.10); für Lichterketten oben bleibt der Platz dann frei
const HOMEMADE := {Item.Kind.COBWEB: 2, Item.Kind.MINI_PUMPKIN: 2, Item.Kind.LEAVES: 3}
const CALL_LINES := ["Wer hilft mir schmücken? Bringt Deko mit!", "Kommt, wir machen es hier richtig gruselig!",
	"Halloween kommt – hier fehlt noch Deko!"]
const BIG_LINES := ["Alle mal herhören: Heute wird groß geschmückt! Holt eure Deko!", "Großes Schmücken! Jeder bringt mit, was er hat!",
	"Kommt alle – wir machen hier alles richtig gruselig!"]
const PLAYER_CALL_LINES := ["Gute Idee! Ich hol was – und sag den anderen Bescheid.", "Hier? Klar! Bin gleich zurück.",
	"Oh ja! Wartet, ich hol meine Deko."]
const JOIN_LINES := ["Ich hol schnell was!", "Bin dabei!", "Warte, ich hab noch was im Koffer.", "Oh ja, schmücken!"]
const HANG_LINES := ["So.", "Hängt!", "Schön gruselig.", "Passt.", "Noch ein bisschen schief … egal."]
const THANKS_LINES := ["Oh, das ist schön! Danke!", "Gute Idee, das passt hierher!", "Super – gleich viel gruseliger."]


## Eine laufende Aktion an einer Stelle. Beim großen Schmücken teilen sich mehrere Stellen eine `group`.
class Action:
	## {pos, wall (Fußpunkt auf der Hauptwand), out, name, slots: [{layer, point, out, stand, length?, height?, used}]}
	var site: Dictionary
	var host: Guest
	## Gast-ID → {guest, phase (fetch/carry/hang/admire/wait), trips, armful, slot, item, load, time, wait, goal}
	var crew := {}
	var helped: Array[Guest] = []   ## alle, die hier mitgemacht haben (auch schon fertig)
	var time := 0.0
	var known := {}                 ## Gegenstände, die schon an der Stelle lagen (Instanz-ID)
	var min_time := 90.0
	var max_time := 180.0
	var scan := 0.0              ## bis zum nächsten Blick nach neuer Deko des Spielers
	## {name, big, by_player, items, present} – geteilt von allen Stellen eines großen Schmückens
	var group: Dictionary


var actions: Array[Action] = []
## Läuft gerade irgendeine Aktion? (Nachtruhe wartet, Social._update_sleep)
var active: bool:
	get:
		return not actions.is_empty()
## Stelle der zuletzt begonnenen Aktion (Debug --decorate)
var site: Dictionary:
	get:
		return actions.back().site if not actions.is_empty() else {}

var _member := {}             ## Gast-ID → Action, bei der er mitmacht
var _cooldown := 0.0
var _big_cooldown := 0.0
var _builder: LevelBuilder
var _solo := {}               ## Gast-ID → wie in Action.crew, dazu site (eigene Stelle) und source (ResourceSpot oder null)
var _solo_cooldown := 40.0
var _solo_need := 0.0         ## bis zum nächsten Versuch, wenn gerade zu wenige mit Deko unterwegs sind
var _called := {}             ## Gast-ID → Spieltag, an dem der Spieler mit ihm geschmückt hat (einmal am Tag)
var _big_player_day := 0      ## Spieltag, an dem der Spieler zuletzt groß ausgerufen hat
var _invited: Dictionary = {} ## Gruppe, zu der der Spieler zuletzt eingeladen wurde (Anruf → on_accepted)
## Gäste schmücken mit Plan und klauen bei Knappheit (Spielkonzept 5.10, Stufe 3)
var plan: DecoPlan


## Beim Laden eines Spielstands (SaveManager.apply): laufende Aktionen vergessen – sie werden nicht gespeichert, und die
## erzeugten Gäste werden dabei neu gebaut.
func reset() -> void:
	actions.clear()
	_member.clear()
	_solo.clear()
	_invited = {}
	if plan:
		plan.reset()


func setup(builder: LevelBuilder) -> void:
	_builder = builder
	plan = DecoPlan.new(self)
	add_child(plan)
	_cooldown = randf_range(FIRST_GAP.x, FIRST_GAP.y)
	_big_cooldown = randf_range(BIG_FIRST_GAP.x, BIG_FIRST_GAP.y)


func _process(delta: float) -> void:
	if Game.game_over or _builder == null:
		return
	_update_solo(delta)
	for a in actions.duplicate():
		_step(a, delta)
	_big_cooldown -= delta
	if _big_cooldown <= 0.0:
		_big_cooldown = 30.0   # später noch einmal versuchen
		if _guests_call() and not _has_big() and start_big(null):
			_big_cooldown = _next_big_gap()
	_cooldown -= delta
	if _cooldown > 0.0:
		return
	_cooldown = 20.0
	if _guests_call() and not _has_big() and _small_count() < _max_small() and start(null):
		_cooldown = _next_gap()


## Ruhig genug? Keine Feier, keine Nachtruhe (auch nicht gleich), kein Monster, Lakengeist oder jagender Kürbismann.
func _can_start() -> bool:
	var social := Game.social
	if social.party_active or social.sleep_active or social.seconds_to_night() < 60.0:
		return false
	if Game.monster.is_active() or (Game.ghost and Game.ghost.is_active()) or (Game.pumpkin and Game.pumpkin.is_hunting()):
		return false
	return not (Game.contest and Game.contest.holds_parties())   # Abend der Siegerehrung (2.5)


## Rufen die Gäste von selbst zum Schmücken auf? Nur tagsüber und wenn es ruhig ist.
func _guests_call() -> bool:
	return Calendar.phase() == Calendar.Phase.DAY and _can_start()


func _has_big() -> bool:
	return actions.any(func(a: Action) -> bool: return a.group["big"])


## Laufende Aktionen der Gäste (ohne die des Spielers und das große Schmücken).
func _small_count() -> int:
	return actions.filter(func(a: Action) -> bool: return not a.group["big"] and not a.group["by_player"]).size()


func _max_small() -> int:
	return MAX_SMALL.x if _progress() < 0.5 else MAX_SMALL.y


## Eine Aktion beginnt (auch Debug --decorate): who ruft auf, null = irgendein Erwachsener. false = keiner oder keine Stelle.
func start(who: Guest, lobby: bool = false) -> bool:
	var candidates: Array = [who] if who else Game.social.living_guests().filter(func(g: Guest) -> bool:
		return not g.is_child() and _available(g))
	candidates.shuffle()
	for guest in candidates.slice(0, 6):
		if _member.has(guest.id):
			continue
		var found := _find_site(guest, lobby)
		if not found.is_empty():
			var a := _begin(guest, found, _new_group(found["name"], false, false))
			_invite_player(a.group, guest)
			return true
	return false


func _available(g: Guest) -> bool:
	return not g.dead and g.hiding == null and g.held == null and g.state in [Guest.State.IDLE, Guest.State.WALK] \
		and not Grinch.is_grinch(g) and g.fear < 50.0 and g.drunk < BarTap.DRUNK and not g.is_following() and not Game.social.has_fun(g) \
		and not _member.has(g.id) and not _solo.has(g.id) and not Game.social.search.is_busy(g) and g.wound == ""


## Tag 1 → 0, Halloween → 1.
func _progress() -> float:
	return clampf(float(Calendar.today() - Calendar.FIRST_DAY) / float(Calendar.HALLOWEEN - Calendar.FIRST_DAY), 0.0, 1.0)


func _new_group(name: String, big: bool, by_player: bool) -> Dictionary:
	return {"name": name, "big": big, "by_player": by_player, "items": 0, "present": 0.0}


## Eine Stelle beginnt: der Rufer und seine Mitmacher – beim großen Schmücken vorgegeben (crew), sonst zuerst seine
## Freunde (6.16), dann wer in der Nähe wohnt.
func _begin(caller: Guest, found: Dictionary, group: Dictionary, crew: Array = []) -> Action:
	var a := Action.new()
	a.site = found
	a.host = caller
	a.group = group
	a.min_time = BIG_MIN_TIME if group["big"] else MIN_TIME
	a.max_time = BIG_MAX_TIME if group["big"] else MAX_TIME
	for item in _items_at(found):
		a.known[item.get_instance_id()] = true
	actions.append(a)
	_enlist(a, caller)
	if not group["big"]:
		var want := roundi(lerpf(HELPERS.x, HELPERS.y, _progress())) + randi_range(0, 1) + (1 if group["by_player"] else 0)
		crew = _helpers_for(a, caller, want)
	for g: Guest in crew:
		_enlist(a, g)
		if randf() < 0.5:
			g.say(JOIN_LINES.pick_random())
	if not group["big"] and not group["by_player"]:
		caller.say(CALL_LINES.pick_random())
	if Game.tracing:
		var names: Array = a.crew.values().map(func(e: Dictionary) -> String: return (e["guest"] as Guest).display_name)
		print("[Schmücken] %s ruft auf%s: %s, %d Plätze – dabei: %s" % [caller.display_name,
			" (groß)" if group["big"] else (" (für dich)" if group["by_player"] else ""), found["name"], found["slots"].size(),
			", ".join(names)])
	return a


func _helpers_for(a: Action, caller: Guest, want: int) -> Array:
	var pos: Vector3 = a.site["pos"]
	var pals := Game.social.pals.pals_of(caller).filter(func(g: Guest) -> bool:
		return _available(g) and g.global_position.distance_to(pos) < PAL_RANGE)
	pals.shuffle()
	var list: Array = pals.slice(0, want)
	var near := Game.social.living_guests().filter(func(g: Guest) -> bool:
		return g != caller and not g in list and _available(g) and _near_home(g, a.site) and g.global_position.distance_to(pos) < HELPER_RANGE)
	near.sort_custom(func(x: Guest, y: Guest) -> bool:
		return (x.home["center"] as Vector3).distance_to(pos) < (y.home["center"] as Vector3).distance_to(pos))
	list.append_array(near.slice(0, maxi(0, want - list.size())))
	return list


func _near_home(g: Guest, at: Dictionary) -> bool:
	var home: Vector3 = g.home["center"]
	var pos: Vector3 = at["pos"]
	if at.get("place", "") == "lobby":
		return home.distance_to(pos) < LOBBY_HOME_RANGE
	return absf(home.y - pos.y) < 2.0 and home.distance_to(pos) < HOME_RANGE


func _enlist(a: Action, g: Guest) -> void:
	if _solo.has(g.id):
		_cancel_solo(g)   # war allein mit Deko unterwegs (z. B. selbst aufgerufen) – sonst steuerten ihn beide
	var t := _progress()
	var armful := randi_range(ARMFUL.x, ARMFUL.y) if a.group["big"] else (2 if randf() < SMALL_ARMFUL * t else 1)
	var trips := randi_range(TRIPS.x, TRIPS.y) + (1 if randf() < t * 0.5 and not a.group["big"] else 0)
	a.crew[g.id] = {"guest": g, "phase": "fetch", "trips": trips, "armful": armful, "slot": {}, "item": null, "load": [],
		"time": 0.0, "wait": 0.0}
	a.helped.append(g)
	_member[g.id] = a
	_walk(g, g._room_point())


func _walk(g: Guest, point: Vector3) -> void:
	var entry: Dictionary = (_member[g.id] as Action).crew[g.id] if _member.has(g.id) else _solo[g.id]
	entry["goal"] = point
	g._walk_to(point, Guest.State.DECORATE)


## Anruf in Zimmer 13 (wenn du dort bist), sonst eine Meldung.
func _invite_player(group: Dictionary, host: Guest) -> void:
	var p := Game.player
	if p == null or p.dead:
		return
	_invited = group
	var text := "%s schmückt %s – bring Deko mit und hilf!" % [host.display_name, group["name"]]
	if group["big"]:
		text = "Großes Schmücken: %s und viele andere schmücken %s – bring Deko mit!" % [host.display_name, group["name"]]
	if _builder.room_at(p.global_position) == LevelBuilder.PLAYER_ROOM and Game.phones and Game.phones.decorate_call(host, group["name"]):
		if Game.tracing:
			print("[Schmücken] Einladung per Anruf in Zimmer 13")
		return
	Game.say(text, 5.0)


## Macht er gerade mit (holt, trägt, hängt, wartet)? Schmücken zählt als Spaß (Social.has_fun, Kürbismann 4.19).
func is_crew(g: Guest) -> bool:
	return _member.has(g.id)


## Der Spieler ist beim Schmücken dabei: in PRESENT_RANGE einer Stelle (Social.player_has_fun).
func player_joins() -> bool:
	var p := Game.player
	if p == null or p.dead:
		return false
	return actions.any(func(a: Action) -> bool: return p.global_position.distance_to(a.site["pos"]) < PRESENT_RANGE)


## Der Spieler hat am Telefon zugesagt.
func on_accepted() -> void:
	var a := _first_of(_invited)
	if a == null:
		return
	if a.host and not a.host.dead:
		Game.social.change_relation(a.host, 2.0)


func _first_of(group: Dictionary) -> Action:
	for a in actions:
		if a.group == group:
			return a
	return null


# --- Selbst aufrufen (2026-10-21) --------------------------------------------------------

## Im Gespräch: „Lass uns hier schmücken!“ bzw. „Großes Schmücken ausrufen!“ – geschmückt wird, wo der Spieler steht
## (Zimmertür auch von Zimmer 13, Flur, Lobby). "" = es geht los, sonst der Satz des Gastes, warum nicht.
func call_here(g: Guest, big: bool) -> String:
	var today := Calendar.today()
	if not _can_start():
		return "Jetzt? Lieber nicht – gerade ist es zu unruhig."
	if g.fear >= 50.0:
		return "Ich trau mich gerade nicht. Später vielleicht."
	if g.drunk >= BarTap.DRUNK:
		return "Schmücken? *hicks* Ich treff ja nicht mal die Wand."
	if _member.has(g.id):
		return "Ich bin doch schon dabei!"
	var pos := Game.player.global_position
	var allowed := _in_place(pos, "corridor") or _in_place(pos, "lobby")
	if big:
		if _has_big():
			return "Es wird doch schon groß geschmückt!"
		if _big_player_day == today:
			return "Heute haben wir doch schon groß geschmückt. Morgen wieder!"
		if not allowed:
			return "Hier? Lass uns das lieber im Flur oder in der Lobby machen."
		if not start_big(g, pos, true):
			return "Hm, hier ist kaum noch Platz – oder keiner hat Zeit."
		_big_player_day = today
		return ""
	if int(_called.get(g.id, 0)) == today:
		return "Heute haben wir schon zusammen geschmückt. Morgen wieder!"
	var found := _site_here(pos)
	if found.is_empty():
		return "Hier hängt schon alles voll." if allowed else "Hier? Lass uns das lieber im Flur, an einer Tür oder in der Lobby machen."
	if _site_taken(found["pos"]):
		return "Da wird doch gerade schon geschmückt!"
	_called[g.id] = today
	_begin(g, found, _new_group(found["name"], false, true))
	return ""


## Großes Schmücken selbst ausrufen: genug Gäste mögen dich (BIG_FRIENDS mindestens „freundlich“), heute noch nicht.
func can_call_big() -> bool:
	if _has_big() or _big_player_day == Calendar.today():
		return false
	var friends := Game.social.living_guests().filter(func(g: Guest) -> bool: return Social.tier(g) >= Social.Tier.FRIENDLY)
	return friends.size() >= BIG_FRIENDS


## Stelle an der Position des Spielers: die nächste Zimmertür in DOOR_REACH (auch Zimmer 13), sonst Flur- bzw.
## Lobbywände ringsum. {} = keine (oder zu wenig Platz).
func _site_here(pos: Vector3) -> Dictionary:
	var best := ""
	var best_d := DOOR_REACH
	for no in _builder.rooms:
		var front: Vector3 = _builder.rooms[no]["door_front"]
		if no != LevelBuilder.LOCKED_ROOM and absf(front.y - pos.y) < 1.0 and front.distance_to(pos) < best_d:
			best = no
			best_d = front.distance_to(pos)
	var found := {}
	if best != "" and _builder.in_corridor(_builder.rooms[best]["door_front"]):
		found = _door_site(best)
	if found.is_empty() or found["slots"].size() < 2:
		if _in_place(pos, "lobby"):
			found = _lobby_wall_site(pos)
		elif _builder.in_corridor(pos):
			found = _corridor_site(pos)
	return found if not found.is_empty() and found["slots"].size() >= 2 else {}


# --- Großes Schmücken (2026-10-21) --------------------------------------------------------

## 10–20 Gäste schmücken mehrere Stellen um `center` (INF: die Lobby oder ein belebter Flurbereich). who ruft auf
## (null = der nächste Mitmacher). false = zu wenig Stellen oder Gäste.
func start_big(who: Guest, center: Vector3 = Vector3.INF, by_player: bool = false, lobby: bool = false) -> bool:
	if _has_big() or (who and _member.has(who.id)):
		return false
	if center == Vector3.INF:
		lobby = lobby or randf() < LOBBY_CHANCE
		center = _builder.lobby_center if lobby else _big_center()
	else:
		lobby = _builder.in_lobby(center)
	var sites := _sites_around(center, lobby, randi_range(BIG_SITES.x, BIG_SITES.y), by_player)
	if sites.size() < 2:
		return false
	var pool := Game.social.living_guests().filter(func(g: Guest) -> bool: return g != who and _available(g))
	pool.sort_custom(func(x: Guest, y: Guest) -> bool:
		return x.global_position.distance_to(center) < y.global_position.distance_to(center))
	var want := roundi(lerpf(BIG_GUESTS.x, BIG_GUESTS.y, _progress())) + randi_range(0, 2)
	var crew: Array = [who] if who else []
	crew.append_array(pool.slice(0, want - crew.size()))
	if crew.size() < 4:
		return false
	sites = sites.slice(0, mini(sites.size(), crew.size() / 2))
	var name := "die Lobby" if lobby else _corridor_name(Game.director.zone_name_at(center), false)
	var group := _new_group(name, true, by_player)
	for i in sites.size():
		var members: Array = []
		for k in range(i, crew.size(), sites.size()):
			members.append(crew[k])
		_begin(members[0], sites[i], group, members.slice(1))
	var host: Guest = crew[0]
	if not by_player:
		host.say(BIG_LINES.pick_random())
	if by_player:
		_invited = group
		Game.say("Großes Schmücken: %s ruft alle zusammen – gleich wimmelt es hier von Deko!" % host.display_name, 5.0)
	else:
		_invite_player(group, host)
	if Game.tracing:
		print("[Schmücken] Großes Schmücken: %s, %d Stellen, %d Gäste" % [name, sites.size(), crew.size()])
	return true


## Mitte für ein großes Schmücken: ein Flurpunkt, um den viele Gäste wohnen und noch wenig Deko hängt.
func _big_center() -> Vector3:
	var points := _builder.wander_points.filter(func(p: Vector3) -> bool: return _builder.in_corridor(p))
	points.shuffle()
	var best := _builder.lobby_center
	var best_score := -INF
	for p: Vector3 in points.slice(0, 10):
		var homes := Game.social.living_guests().filter(func(g: Guest) -> bool:
			var h: Vector3 = g.home["center"]
			return absf(h.y - p.y) < 2.0 and h.distance_to(p) < BIG_RADIUS + 6.0).size()
		var score := homes - _crowd(p, BIG_RADIUS * 0.6) * 0.3 + randf() * 3.0
		if score > best_score:
			best_score = score
			best = p
	return best


## Bis zu `count` Stellen um `center` (gleiches Stockwerk, BIG_RADIUS): Zimmertüren, Flurwände und in der Lobby ihre
## Wände – die mit den meisten freien Plätzen, mindestens SITE_SPACING auseinander. Zimmer 13 nur, wenn du aufrufst.
func _sites_around(center: Vector3, lobby: bool, count: int, own_door: bool) -> Array:
	var skip: Array = [LevelBuilder.LOCKED_ROOM] if own_door else [LevelBuilder.LOCKED_ROOM, LevelBuilder.PLAYER_ROOM]
	var options := _corridor_options(center, 1.0, BIG_RADIUS, skip)
	if lobby:
		for p in _lobby_points():
			options.append({"pos": p, "lobby": true})
	options.shuffle()
	var found_list: Array = []
	for option: Dictionary in options.slice(0, 28):
		var found := _site_for(option)
		var score := _score(found)
		if score > -INF and found["slots"].size() >= 3:
			found_list.append({"found": found, "score": score})
	found_list.sort_custom(func(x: Dictionary, y: Dictionary) -> bool: return x["score"] > y["score"])
	var picked: Array = []
	for e: Dictionary in found_list:
		var pos: Vector3 = e["found"]["pos"]
		if picked.all(func(f: Dictionary) -> bool: return (f["pos"] as Vector3).distance_to(pos) >= SITE_SPACING):
			picked.append(e["found"])
			if picked.size() >= count:
				break
	return picked


# --- Ablauf -----------------------------------------------------------------------------

func _step(a: Action, delta: float) -> void:
	a.time += delta
	var social := Game.social
	var pos: Vector3 = a.site["pos"]
	if social.party_active:
		_end(a, "Alle zieht es in den Partyraum – das Schmücken hat Pause.", false)
		return
	if social.sleep_active:
		_end(a, "", false)
		return
	if not Game.director.is_quiet(pos, 30.0) or (Game.ghost and Game.ghost.is_active() and Game.ghost.global_position.distance_to(pos) < 20.0):
		_end(a, "Die Schmückenden laufen auseinander.", false)
		return
	var p := Game.player
	if p and not p.dead and p.global_position.distance_to(pos) < PRESENT_RANGE:
		a.group["present"] = float(a.group["present"]) + delta
	_check_player_deco(a, delta)
	for id in a.crew.keys():
		_crew_step(a, a.crew[id], delta)
	if a.crew.is_empty() or a.time > a.max_time:
		_end(a, "", true)


func _crew_step(a: Action, entry: Dictionary, delta: float) -> void:
	var g: Guest = entry["guest"]
	match _entry_step(entry, delta):
		"out":
			_drop_out(a, entry)   # erschreckt, versteckt, feiert, schläft …
		"hung":
			if _next_from_load(entry):
				return   # noch etwas im Arm: zum nächsten Platz
			_admire(entry, randf_range(2.5, 5.0))
			if randf() < 0.35:
				g.say(HANG_LINES.pick_random())
		"admired":
			entry["trips"] = int(entry["trips"]) - 1
			if int(entry["trips"]) > 0 and _free_slot_count(a.site) > 0:
				entry["phase"] = "fetch"
				_walk(g, g._room_point())
			elif g == a.host and a.time < a.min_time:
				entry["phase"] = "wait"   # der Rufer bleibt, bis der Spieler kommen konnte
			else:
				_leave(a, g)
		"":
			if entry["phase"] == "wait" and a.time >= a.min_time:
				_leave(a, g)


## Gemeinsamer Schritt für Mitmacher und allein Schmückende: "out" = fällt aus (anderer Zustand), "busy" = unterwegs
## oder im Gespräch, "hung" = hat gerade aufgehängt (Platz belegt), "admired" = fertig mit Anschauen, sonst "".
func _entry_step(entry: Dictionary, delta: float) -> String:
	var g: Guest = entry["guest"]
	var phase := String(entry["phase"])
	if g.dead or not g.state in [Guest.State.DECORATE, Guest.State.IDLE, Guest.State.TALKING]:
		return "out"
	if g.state == Guest.State.TALKING:
		return "busy"   # wartet, bis das Gespräch vorbei ist
	if phase in ["fetch", "carry"]:
		if g.state == Guest.State.IDLE:
			g._walk_to(entry["goal"], Guest.State.DECORATE)   # nach einem Gespräch weiter
		return "busy"
	entry["time"] = float(entry["time"]) + delta
	g._timer = 30.0   # nicht von selbst weiterziehen (Guest._next_activity)
	if phase == "hang" and float(entry["time"]) >= 1.1:
		_place(entry)
		entry["slot"] = {}   # belegt – fällt er danach aus, wird der Platz nicht wieder frei
		return "hung"
	if phase == "admire" and float(entry["time"]) >= float(entry["wait"]):
		return "admired"
	return ""


func _admire(entry: Dictionary, wait: float) -> void:
	entry["phase"] = "admire"
	entry["time"] = 0.0
	entry["wait"] = wait


func _leave(a: Action, g: Guest) -> void:
	a.crew.erase(g.id)
	_member.erase(g.id)
	g._set_idle(randf_range(3.0, 6.0))


## Guest._arrive im Zustand DECORATE.
func on_arrived(g: Guest) -> void:
	if _solo.has(g.id):
		_solo_arrived(_solo[g.id])
		return
	if not _member.has(g.id):
		g._set_idle(randf_range(2.0, 5.0))
		return
	var a: Action = _member[g.id]
	var entry: Dictionary = a.crew[g.id]
	match String(entry["phase"]):
		"fetch":
			# Ein Armvoll: für jedes Stück einen Platz reservieren, das erste in die Hand, die anderen obendrauf
			var load: Array = []
			for i in int(entry["armful"]):
				var slot := _reserve_slot(a.site, _bring_layers(g))
				if slot.is_empty():
					break
				var kind := _pick_kind(g, slot, a.site)
				if kind < 0:
					slot["used"] = false
					break
				load.append({"slot": slot, "item": g.stock_item(kind)})
			if load.is_empty():
				_leave(a, g)
				return
			var first: Dictionary = load.pop_front()
			g.stow_held()   # hält er noch etwas (Geschenk), wandert es in den Koffer – sonst bliebe es verwaist in der Hand
			g._take_into_hand(first["item"])
			entry["item"] = first["item"]
			entry["slot"] = first["slot"]
			entry["load"] = load
			_stack_in_arms(g, load)
			entry["phase"] = "carry"
			_walk(g, first["slot"]["stand"])
		"carry":
			_start_hang(entry)
		_:
			g._set_idle(30.0)


## Weitere Stücke eines Armvolls: über dem ersten in der Hand gestapelt (eingefroren, ohne Kollision – gespeichert wird
## nur, was nicht gehalten ist, Item.is_held).
func _stack_in_arms(g: Guest, load: Array) -> void:
	for i in load.size():
		var item: Item = load[i]["item"]
		if not item.is_inside_tree():
			g.get_parent().add_child(item)
		item.owner_id = g.id
		item.set_held(true)
		item.reparent(g._hand, false)
		item.position = Vector3(0.05 * (i % 2 * 2 - 1), 0.16 + 0.14 * i, 0.06)
		item.rotation = Vector3(0.15, PI + 0.5 * (i + 1), 0.1)


## Nächstes Stück aus dem Arm in die Hand und zum nächsten Platz. false = Arme leer.
func _next_from_load(entry: Dictionary) -> bool:
	var load: Array = entry["load"]
	while not load.is_empty():
		var next: Dictionary = load.pop_front()
		var item := _alive(next["item"])
		if item == null:
			next["slot"]["used"] = false
			continue
		var g: Guest = entry["guest"]
		g._take_into_hand(item)   # liegt schon eingefroren in der Hand – nur nach vorn
		entry["item"] = item
		entry["slot"] = next["slot"]
		entry["phase"] = "carry"
		_walk(g, next["slot"]["stand"])
		return true
	return false


## Gegenstand aus einem Eintrag – null, wenn es ihn nicht mehr gibt (nach dem Laden eines Spielstands werden alle neu
## erzeugt, laufende Aktionen zeigen dann ins Leere).
static func _alive(value: Variant) -> Item:
	return value as Item if is_instance_valid(value) else null


## Am Platz angekommen: zur Wand drehen, Arme hoch – nach 1,1 s hängt es (_crew_step / _solo_step).
func _start_hang(entry: Dictionary) -> void:
	var g: Guest = entry["guest"]
	var slot: Dictionary = entry["slot"]
	g._set_idle(30.0)
	var to := (slot["point"] as Vector3) - g.global_position
	g.rotation.y = atan2(-to.x, -to.z)
	if slot["layer"] != "floor":
		g.reach_up(1.2)
	entry["phase"] = "hang"
	entry["time"] = 0.0


## Was er holt: passend zur Ebene, zuerst aus dem Koffer, sonst etwas Gebasteltes. Eine Fledermausgirlande (1,2 m)
## nur, wo die Wandplätze daneben frei sind – sie belegt sie dann mit.
func _pick_kind(g: Guest, slot: Dictionary, at: Dictionary) -> int:
	var kinds: Array = LAYER_KINDS[slot["layer"]]
	var beside := _wall_neighbors(slot, at)
	if beside.any(func(s: Dictionary) -> bool: return s["used"]):
		kinds = kinds.filter(func(k: int) -> bool: return k != Item.Kind.BAT_GARLAND)
	var kind := _choose_kind(g, kinds)
	if kind == Item.Kind.BAT_GARLAND:
		for s: Dictionary in beside:
			s["used"] = true
	return kind


## Ebenen, für die der Gast etwas mitbringen kann: aus seinem Koffer oder Füllmaterial (HOMEMADE).
func _bring_layers(g: Guest) -> Array:
	var layers: Array = []
	for layer: String in LAYER_KINDS:
		if (LAYER_KINDS[layer] as Array).any(func(k: int) -> bool: return int(g.stock.get(k, 0)) > 0 or HOMEMADE.has(k)):
			layers.append(layer)
	return layers


func _wall_neighbors(slot: Dictionary, at: Dictionary) -> Array:
	if slot["layer"] != "wall":
		return []
	return (at["slots"] as Array).filter(func(s: Dictionary) -> bool:
		return s != slot and s["layer"] == "wall" and (s["point"] as Vector3).distance_to(slot["point"]) < 1.3)


func _choose_kind(g: Guest, kinds: Array) -> int:
	var own := kinds.filter(func(k: int) -> bool: return int(g.stock.get(k, 0)) > 0)
	if not own.is_empty():
		var kind: int = own.pick_random()
		g.stock[kind] = int(g.stock[kind]) - 1
		return kind
	kinds = kinds.filter(func(k: int) -> bool: return HOMEMADE.has(k))
	if kinds.is_empty():
		return -1
	var total := 0
	for k in kinds:
		total += int(HOMEMADE.get(k, 1))
	var roll := randi() % maxi(total, 1)
	for k in kinds:
		roll -= int(HOMEMADE.get(k, 1))
		if roll < 0:
			return k
	return kinds[0]


## Aufhängen bzw. hinstellen – wie der Spieler mit [G] (Spielkonzept 5.6).
func _place(entry: Dictionary) -> void:
	var g: Guest = entry["guest"]
	var item := _alive(entry["item"])
	var slot: Dictionary = entry["slot"]
	entry["item"] = null
	if item == null or g.held != item:
		return
	g.held = null
	item.reparent(g.get_parent(), true)
	var out: Vector3 = slot["out"]
	var point: Vector3 = slot["point"]
	if item.kind == Item.Kind.LIGHT_STRING and _light_strings() >= LIGHT_STRING_CAP:
		item.queue_free()   # genug Lichter im Hotel – stattdessen Fledermäuse
		item = Item.create(Item.Kind.BAT_GARLAND)
		item.owner_id = g.id
		g.get_parent().add_child(item)
	if slot["layer"] == "floor" and item.kind != Item.Kind.BROOM:
		item.global_position = point + Vector3.UP * 0.02
		item.rotation = Vector3(0, atan2(out.x, out.z), 0)
		item.set_held(false)
		item.linear_velocity = Vector3.ZERO
	else:
		var y: float = point.y
		if slot["layer"] == "wall":
			y += float(WALL_HEIGHT.get(item.kind, 0.0))
		elif slot["layer"] == "top" and item.kind != Item.Kind.LIGHT_STRING:
			y += TOP_HEIGHT - 0.2
		elif slot["layer"] == "top":
			y += float(slot.get("height", TOP_HEIGHT))
		item.hang(Vector3(point.x, y, point.z), out, float(slot.get("length", 0.0)))
	Game.noise("drop", item.global_position, g)
	if _member.has(g.id):
		(_member[g.id] as Action).known[item.get_instance_id()] = true
	if Game.tracing:
		print("[Schmücken] %s: %s (%s)" % [g.display_name, item.display_name, slot["layer"]])


## Fällt aus (erschreckt, versteckt, Feier …): Deko in der Hand und im Arm wandert zurück in den Koffer.
func _drop_out(a: Action, entry: Dictionary) -> void:
	var g: Guest = entry["guest"]
	a.crew.erase(g.id)
	_member.erase(g.id)
	_return_items(entry)


## Deko in der Hand und im Arm zurück in den Koffer, reservierte Plätze wieder frei (Mitmacher und allein Schmückende).
func _return_items(entry: Dictionary) -> void:
	var g: Guest = entry["guest"]
	var slot: Dictionary = entry["slot"]
	if not slot.is_empty():
		slot["used"] = false
	var item := _alive(entry["item"])
	entry["item"] = null
	if item and g.held == item:
		g.stow_held()
	for rest: Dictionary in entry.get("load", []):
		rest["slot"]["used"] = false
		var extra := _alive(rest["item"])
		if extra:
			g.stock[extra.kind] = int(g.stock.get(extra.kind, 0)) + 1
			extra.queue_free()
	entry["load"] = []


func _end(a: Action, message: String, finished: bool) -> void:
	if not a in actions:
		return
	actions.erase(a)
	for id in a.crew.keys():
		var entry: Dictionary = a.crew[id]
		var g: Guest = entry["guest"]
		var state_before := g.state
		_drop_out(a, entry)
		if not g.dead and state_before in [Guest.State.DECORATE, Guest.State.IDLE]:
			g._set_idle(randf_range(2.0, 5.0))
	var group := a.group
	var helped: bool = int(group["items"]) > 0 or float(group["present"]) >= PRESENT_TIME or bool(group["by_player"])
	var last := _first_of(group) == null   # letzte Stelle eines großen Schmückens
	if finished:
		Game.social.pals.note_group(a.helped)   # zusammen geschmückt (6.16)
		for g in a.helped:
			if g.dead:
				continue
			g.fear = maxf(0.0, g.fear - FEAR_RELIEF)
			if helped:
				Game.social.change_relation(g, minf(RELATION + RELATION_PER_ITEM * int(group["items"]), RELATION_MAX))
		if helped and Game.player and last:
			Game.player.shock = maxf(0.0, Game.player.shock - SHOCK_RELIEF)
		if message == "":
			var who := "%s und die anderen haben" % a.host.display_name if a.host and not a.host.dead else "Die Gäste haben"
			if group["big"]:
				who = "Die Gäste haben"
			message = "%s %s geschmückt%s" % [who, group["name"], " – danke fürs Helfen!" if helped else "."]
		if last and group["big"] and Game.confetti:
			Game.confetti.burst(a.site["pos"] + Vector3.UP * 2.6, 40)   # zum Abschluss Konfetti
	if Game.tracing:
		var placed := _items_at(a.site).filter(func(i: Item) -> bool: return not a.known.has(i.get_instance_id()) or i.owner_id != "").size()
		print("[Schmücken] Ende %s (%s): %d s, Spieler: %d Stück, %d s dabei, Deko an der Stelle: %d" % [a.site["name"],
			"fertig" if finished else "abgebrochen", int(a.time), int(group["items"]), int(group["present"]), placed])
	var p := Game.player
	if message != "" and (last or not finished) and p and (helped or p.global_position.distance_to(a.site["pos"]) < 25.0 or not finished):
		Game.say(message, 4.0)


func _next_gap() -> float:
	var t := _progress()
	return randf_range(lerpf(GAP_EARLY.x, GAP_LATE.x, t), lerpf(GAP_EARLY.y, GAP_LATE.y, t))


func _next_big_gap() -> float:
	var t := minf(_progress() * BIG_RAMP, 1.0)
	return randf_range(lerpf(BIG_GAP_EARLY.x, BIG_GAP_LATE.x, t), lerpf(BIG_GAP_EARLY.y, BIG_GAP_LATE.y, t))


## Neue Deko des Spielers an der Stelle: zählt als Mithilfe, der Rufer bedankt sich beim ersten Stück.
func _check_player_deco(a: Action, delta: float) -> void:
	a.scan -= delta
	if a.scan > 0.0:
		return
	a.scan = 0.5
	for item in _items_at(a.site):
		var key := item.get_instance_id()
		if a.known.has(key) or item.owner_id != "player" or item.deco_strength <= 0.0:
			continue
		a.known[key] = true
		a.group["items"] = int(a.group["items"]) + 1
		if int(a.group["items"]) == 1 and a.host and not a.host.dead:
			a.host.say(THANKS_LINES.pick_random())
			Game.social.change_relation(a.host, 2.0)


func _items_at(at: Dictionary) -> Array[Item]:
	var result: Array[Item] = []
	var pos: Vector3 = at["pos"]
	for node in get_tree().get_nodes_in_group("items"):
		var item := node as Item
		if item.is_held or item.pocketed:
			continue
		var flat := Vector2(item.global_position.x - pos.x, item.global_position.z - pos.z)
		if flat.length() < SITE_RADIUS and absf(item.global_position.y - pos.y) < 3.2:
			result.append(item)
	return result


## Wird dort gerade geschmückt? (Stellen gleichzeitiger Aktionen liegen SITE_SPACING auseinander)
func _site_taken(pos: Vector3) -> bool:
	return actions.any(func(a: Action) -> bool: return (a.site["pos"] as Vector3).distance_to(pos) < SITE_SPACING)


## So viel Deko liegt bzw. hängt im Umkreis.
func _crowd(p: Vector3, radius: float) -> int:
	var crowd := 0
	for node in get_tree().get_nodes_in_group("items"):
		var item := node as Item
		if not item.is_held and item.deco_strength > 0.0 and item.global_position.distance_to(p) < radius:
			crowd += 1
	return crowd


func _light_strings() -> int:
	var n := 0
	for node in get_tree().get_nodes_in_group("items"):
		var item := node as Item
		if item.kind == Item.Kind.LIGHT_STRING and item.hung:
			n += 1
	return n


# --- Allein unterwegs ---------------------------------------------------------------------

func _update_solo(delta: float) -> void:
	for id in _solo.keys():
		_solo_step(_solo[id], delta)
	_solo_cooldown -= delta
	_solo_need -= delta
	var t := _progress()
	var need := _solo.size() < (SOLO_MIN.x if t < 0.5 else SOLO_MIN.y)   # immer jemand mit Deko unterwegs
	if need and _solo_need <= 0.0:
		_solo_need = 4.0
	elif _solo_cooldown > 0.0:
		return
	else:
		_solo_cooldown = randf_range(lerpf(SOLO_GAP_EARLY.x, SOLO_GAP_LATE.x, t), lerpf(SOLO_GAP_EARLY.y, SOLO_GAP_LATE.y, t))
	var social := Game.social
	if _solo.size() >= SOLO_MAX or social.party_active or social.sleep_active or Game.monster.is_active() \
			or (Game.pumpkin and Game.pumpkin.is_hunting()):
		return
	var free := social.living_guests().filter(func(g: Guest) -> bool: return _available(g))
	free.shuffle()
	var roll := randf()
	for g: Guest in free.slice(0, 4):
		if start_solo(g, roll < SOLO_LOBBY, roll >= SOLO_LOBBY and roll < SOLO_LOBBY + SOLO_HOTEL):
			return


## Ein Gast trägt ein Stück Deko herum (auch Debug --decorate=allein): in sein Zimmer – geholt aus einer Kiste im Hotel
## (Dekokiste, Wäschekiste, Laub im Garten …, nie im Keller und nur ohne verschlossene Tür auf dem Weg; der Vorrat
## bleibt) – oder aus seinem Koffer in die Lobby bzw. (anywhere) irgendwohin ins Hotel, wo noch wenig hängt.
## false = kein freier Platz oder keine Quelle.
func start_solo(g: Guest, to_lobby: bool, anywhere: bool = false) -> bool:
	if g == null or g.dead or _solo.has(g.id) or _member.has(g.id):
		return false
	var at := _lobby_site() if to_lobby else (_hotel_site(g) if anywhere else _room_site(g))
	if at.is_empty():
		return false
	var entry := {"guest": g, "site": at, "phase": "fetch", "slot": {}, "item": null, "time": 0.0, "wait": 0.0, "source": null}
	var goal := g._room_point()
	if not to_lobby and not anywhere:
		var source := _source_for(g, at)
		if source == null:
			return false
		entry["source"] = source
		goal = NavigationServer3D.map_get_closest_point(get_world_3d().navigation_map, source.global_position)
	_solo[g.id] = entry
	_walk(g, goal)
	if Game.tracing:
		var source: ResourceSpot = entry["source"]
		print("[Schmücken] %s holt allein Deko für %s (%s)" % [g.display_name, at["name"],
			source.label if source else "aus dem Koffer"])
	return true


## Mit Plan (Spielkonzept 5.10, Stufe 3, DecoPlan): ein Stück an die Tür von Zimmer no – aus dem Koffer; ist darin nichts
## Starkes mehr, aus einer Kiste, sonst etwas Gebasteltes (HOMEMADE). why steht nur in --trace. false = kein freier Platz.
func start_solo_door(g: Guest, no: String, why: String) -> bool:
	if g == null or g.dead or _solo.has(g.id) or _member.has(g.id) or not _builder.rooms.has(no):
		return false
	var at := _door_site(no)
	if _score(at) == -INF or _free_slot_count(at) == 0 or _solo.values().any(func(e: Dictionary) -> bool:
			return (e["site"]["pos"] as Vector3).distance_to(at["pos"]) < 1.0):
		return false
	var source: ResourceSpot = null if DecoPlan.has_strong_stock(g) else _source_for(g, at)
	var goal := g._room_point() if source == null \
		else NavigationServer3D.map_get_closest_point(get_world_3d().navigation_map, source.global_position)
	_solo[g.id] = {"guest": g, "site": at, "phase": "fetch", "slot": {}, "item": null, "time": 0.0, "wait": 0.0, "source": source}
	_walk(g, goal)
	if Game.tracing:
		print("[Schmuckplan] %s schmückt %s (%s, %s)" % [g.display_name, at["name"], why,
			source.label if source else "aus dem Koffer"])
	return true


## Er schlendert gerade mit Deko durchs Hotel (Guest._speed_factor: gemächlicher).
func strolls(g: Guest) -> bool:
	return _solo.has(g.id) and _solo[g.id]["phase"] == "carry"


## Irgendwo im Hotel, wo noch wenig hängt (Wunsch 2026-10-21): ein paar zufällige Zimmertüren und Flurstellen auf allen
## Stockwerken, die beste nach freien Plätzen und Deko ringsum – weite Wege zählen etwas dagegen, und wo schon ein
## anderer allein hinträgt, geht kein zweiter hin.
func _hotel_site(g: Guest) -> Dictionary:
	var options := _corridor_options(g.global_position, INF, INF, [LevelBuilder.PLAYER_ROOM, LevelBuilder.LOCKED_ROOM])
	options.shuffle()
	var best := {}
	var best_score := -INF
	for option: Dictionary in options.slice(0, 8):
		var found := _site_for(option)
		var score := _score(found)
		if score == -INF or _solo.values().any(func(e: Dictionary) -> bool:
				return (e["site"]["pos"] as Vector3).distance_to(found["pos"]) < SITE_SPACING):
			continue   # dort ist schon ein anderer mit Deko hin unterwegs
		score -= (found["pos"] as Vector3).distance_to(g.global_position) / 40.0
		if score > best_score:
			best_score = score
			best = found
	return best


## Stelle, an der gerade ein Gast allein schmückt ({} = keine) – für den Debug-Parameter.
func solo_site(g: Guest) -> Dictionary:
	return _solo[g.id]["site"] if g and _solo.has(g.id) else {}


## Wände im eigenen Zimmer (ohne Möbel davor, nicht über Türen und Fenstern).
func _room_site(g: Guest) -> Dictionary:
	var no := String(g.home["no"])
	if no == LevelBuilder.PLAYER_ROOM:
		return {}
	return _wall_site(g.home["center"], no, 6.0)


## Eine der vier nächsten Kisten mit Deko, die auf einen freien Platz der Stelle passt (nicht im Keller, nicht die Spinnweben in dunklen
## Ecken, erreichbar ohne verschlossene Tür). null = keine.
func _source_for(g: Guest, at: Dictionary) -> ResourceSpot:
	var wanted := _free_kinds(at)
	var spots: Array = []
	for node in get_tree().get_nodes_in_group("resource_spots"):
		var spot := node as ResourceSpot
		if spot.global_position.y > -0.5 and spot.kind != Item.Kind.COBWEB and spot.guest_can_take() 				and not _spot_kinds(spot).filter(func(k: int) -> bool: return k in wanted).is_empty():
			spots.append(spot)
	spots.sort_custom(func(a: ResourceSpot, b: ResourceSpot) -> bool:
		return a.global_position.distance_to(g.global_position) < b.global_position.distance_to(g.global_position))
	var near := spots.slice(0, 4)
	near.shuffle()   # nicht immer derselbe Laubhaufen
	for spot: ResourceSpot in near:
		if _reachable(g.global_position, spot.global_position):
			return spot
	return null


func _spot_kinds(spot: ResourceSpot) -> Array:
	return spot.pool if not spot.pool.is_empty() else [spot.kind]


## Arten, die auf einen freien Platz der Stelle passen.
func _free_kinds(at: Dictionary) -> Array:
	var kinds: Array = []
	for slot: Dictionary in at["slots"]:
		if not slot["used"]:
			kinds.append_array(LAYER_KINDS[slot["layer"]])
	return kinds


static func _layer_of(kind: int) -> String:
	if kind in TOP_KINDS:
		return "top"
	return "wall" if kind in WALL_KINDS else "floor"


## Weg über das NavMesh ohne verschlossene Tür (Gäste schließen nicht auf).
func _reachable(from: Vector3, to: Vector3) -> bool:
	var map := get_world_3d().navigation_map
	var path := NavigationServer3D.map_get_path(map, from, to, true)
	if path.is_empty() or path[path.size() - 1].distance_to(NavigationServer3D.map_get_closest_point(map, to)) > 1.0:
		return false
	for node in get_tree().get_nodes_in_group("doors"):
		var door := node as Door
		if not door.locked:
			continue
		var c := door.center()
		for i in path.size() - 1:
			var a: Vector3 = path[i] + Vector3.UP
			var b: Vector3 = path[i + 1] + Vector3.UP
			if Geometry3D.get_closest_point_to_segment(c, a, b).distance_to(c) < 1.0:
				return false
	return true


func _solo_arrived(entry: Dictionary) -> void:
	var g: Guest = entry["guest"]
	var at: Dictionary = entry["site"]
	match String(entry["phase"]):
		"fetch":
			var source: ResourceSpot = entry["source"]
			var slot := {}
			var kind := -1
			if source and is_instance_valid(source) and source.guest_can_take():
				var wanted := _free_kinds(at)
				var kinds := _spot_kinds(source).filter(func(k: int) -> bool: return k in wanted)
				if not kinds.is_empty():
					kind = kinds.pick_random()
					slot = _reserve_slot(at, [_layer_of(kind)])
			elif source == null:
				slot = _reserve_slot(at, _bring_layers(g))
				if not slot.is_empty():
					kind = _pick_kind(g, slot, at)
			if slot.is_empty() or kind < 0 or (source and is_instance_valid(source) and not source.guest_consume()):
				if not slot.is_empty():
					slot["used"] = false
				_solo.erase(g.id)
				g._set_idle(randf_range(3.0, 6.0))
				return
			var item := g.stock_item(kind)
			g.stow_held()
			g._take_into_hand(item)
			entry["item"] = item
			entry["slot"] = slot
			entry["phase"] = "carry"
			_walk(g, slot["stand"])
		"carry":
			_start_hang(entry)
		_:
			g._set_idle(30.0)


func _solo_step(entry: Dictionary, delta: float) -> void:
	var g: Guest = entry["guest"]
	match _entry_step(entry, delta):
		"out":
			_cancel_solo(g)   # erschreckt, versteckt, feiert, schläft … – Deko zurück in den Koffer
		"hung":
			_admire(entry, randf_range(2.0, 4.0))
		"admired":
			_solo.erase(g.id)
			g._set_idle(randf_range(3.0, 6.0))


## Allein Schmücken abbrechen: Deko zurück in den Koffer, der Platz wird wieder frei.
func _cancel_solo(g: Guest) -> void:
	_return_items(_solo[g.id])
	_solo.erase(g.id)


# --- Stellen -----------------------------------------------------------------------------

func _free_slot_count(at: Dictionary) -> int:
	return (at["slots"] as Array).filter(func(s: Dictionary) -> bool: return not s["used"]).size()


## Nächster freier Platz der Stelle `at` – erst eine Lichterkette oben, dann abwechselnd Wand und Boden, von der Mitte
## nach außen; mit `layers` nur auf diesen Ebenen.
func _reserve_slot(at: Dictionary, layers: Array = ["top", "wall", "floor"]) -> Dictionary:
	var free := (at["slots"] as Array).filter(func(s: Dictionary) -> bool: return not s["used"] and s["layer"] in layers)
	if free.is_empty():
		return {}
	var wall_used := (at["slots"] as Array).filter(func(s: Dictionary) -> bool: return s["used"] and s["layer"] == "wall").size()
	var floor_used := (at["slots"] as Array).filter(func(s: Dictionary) -> bool: return s["used"] and s["layer"] == "floor").size()
	var want := "wall" if wall_used <= floor_used + 1 else "floor"
	var pick: Dictionary = free[0]
	for s: Dictionary in free:
		if s["layer"] == "top":
			pick = s
			break
		if s["layer"] == want:
			pick = s
			break
	pick["used"] = true
	return pick


## Eine Stelle in der Nähe der Wohnung des Rufers (gleiches Stockwerk, nie der Partyraum) oder – mit LOBBY_CHANCE bzw.
## `lobby` – in der Lobby: die mit den meisten freien Plätzen und der wenigsten Deko ringsum, so breitet sich die Deko
## mit den Tagen aus. {} = keine.
func _find_site(caller: Guest, lobby: bool = false) -> Dictionary:
	if lobby or randf() < LOBBY_CHANCE:
		var found := _lobby_site()
		if not found.is_empty() or lobby:
			return found
	var options := _corridor_options(caller.home["center"], 2.0, 30.0, [LevelBuilder.PLAYER_ROOM, LevelBuilder.LOCKED_ROOM])
	options.shuffle()
	return _best_site(options.slice(0, 10))


## Zimmertüren (außer `skip`) und Flurpunkte im Flur um center – höchstens dy höher bzw. tiefer, näher als radius – als
## Kandidaten für Stellen ({door, pos} bzw. {pos}, siehe _site_for).
func _corridor_options(center: Vector3, dy: float, radius: float, skip: Array) -> Array:
	var options: Array = []
	for no in _builder.rooms:
		var front: Vector3 = _builder.rooms[no]["door_front"]
		if not no in skip and absf(front.y - center.y) < dy and front.distance_to(center) < radius and _builder.in_corridor(front):
			options.append({"door": no, "pos": front})
	for p in _builder.wander_points:
		if absf(p.y - center.y) < dy and p.distance_to(center) < radius and _builder.in_corridor(p):
			options.append({"pos": p})
	return options


## Stelle zu einem Kandidaten: Zimmertür, Lobbywand ({pos, lobby}) oder Flurwand.
func _site_for(option: Dictionary) -> Dictionary:
	if option.has("door"):
		return _door_site(option["door"])
	if option.has("lobby"):
		return _lobby_wall_site(option["pos"])
	return _corridor_site(option["pos"])


## Die beste Stelle der Kandidaten nach _score; {} = keine mit mindestens drei Plätzen.
func _best_site(options: Array) -> Dictionary:
	var best := {}
	var best_score := -INF
	for option: Dictionary in options:
		var found := _site_for(option)
		var score := _score(found)
		if score > best_score:
			best_score = score
			best = found
	return best if not best.is_empty() and best["slots"].size() >= 3 else {}


## Viele freie Plätze, wenig Deko ringsum (6 m); -INF für keine Stelle oder eine, an der schon geschmückt wird.
func _score(found: Dictionary) -> float:
	if found.is_empty() or _site_taken(found["pos"]):
		return -INF
	return found["slots"].size() - _crowd(found["pos"], 6.0) * 1.5 + randf() * 2.0


## Eine Wand der Lobby (Erdgeschoss): von Sitzplätzen und Wegpunkten der Lobby aus gesucht, die beste von ein paar.
func _lobby_site() -> Dictionary:
	var points := _lobby_points()
	points.shuffle()
	return _best_site(points.slice(0, 8).map(func(p: Vector3) -> Dictionary: return {"pos": p, "lobby": true}))


## Ausgangspunkte für Lobbywände: Mitte, Sitzplätze und Lobby-Punkte der Patrouille.
func _lobby_points() -> Array[Vector3]:
	var points: Array[Vector3] = [_builder.lobby_center]
	points.append_array(_builder.lobby_seats)
	for entry in _builder.patrol:
		if _builder.in_lobby(entry["pos"]):
			points.append(entry["pos"])
	return points


func _door_site(no: String) -> Dictionary:
	var room: Dictionary = _builder.rooms[no]
	var door: Door = room["door"]
	var into: Vector3 = room["into"]
	var along: Vector3 = room["along"]
	var out := -into
	var c := door.center()
	var face := Vector3(c.x, door.global_position.y, c.z) - into * (LevelBuilder.T / 2.0)
	var slots: Array = []
	var top := {"layer": "top", "point": face, "out": out, "stand": face + out * 0.7, "length": door.width + 1.0,
		"height": door.height + 0.12, "used": false}
	if _space_free(face + Vector3.UP * (door.height + 0.05) + out * 0.1, 0.35, 4):
		slots.append(top)
	for off in [door.width / 2.0 + 0.45, -(door.width / 2.0 + 0.45), door.width / 2.0 + 1.15, -(door.width / 2.0 + 1.15)]:
		_add_wall_slots(slots, face + along * off, out)
	if slots.is_empty():
		return {}
	return {"pos": room["door_front"], "wall": face, "out": out, "name": "die Tür von Zimmer %s" % room["sign"], "slots": slots}


func _corridor_site(p: Vector3) -> Dictionary:
	return _wall_site(p, "corridor", 3.0)


func _lobby_wall_site(p: Vector3) -> Dictionary:
	return _wall_site(p, "lobby", 6.0)


## Wände rings um p (Strahlen in vier Richtungen, so weit wie reach), Plätze daran, die in `place` liegen ("corridor",
## "lobby" oder eine Zimmernummer). {} = keine Wand, kein Platz.
func _wall_site(p: Vector3, place: String, reach: float) -> Dictionary:
	var space := get_world_3d().direct_space_state
	var walls: Array = []
	for dir: Vector3 in [Vector3.RIGHT, Vector3.LEFT, Vector3.FORWARD, Vector3.BACK]:
		var from := p + Vector3.UP * 1.6
		var query := PhysicsRayQueryParameters3D.create(from, from + dir * reach, 1 | 2)
		var hit := space.intersect_ray(query)
		if hit.is_empty() or not _is_wall(hit):
			continue
		var normal: Vector3 = hit["normal"]
		if absf(normal.y) > 0.3:
			continue
		var at: Vector3 = hit["position"]
		walls.append({"point": Vector3(at.x, p.y, at.z), "out": Vector3(normal.x, 0, normal.z).normalized()})
	if walls.is_empty():
		return {}
	var slots: Array = []
	walls.shuffle()
	var main: Dictionary = walls[0]
	var top := _top_slot(main["point"], main["out"])
	if not top.is_empty():
		slots.append(top)
	for wall: Dictionary in walls.slice(0, 2):
		var tangent := Vector3.UP.cross(wall["out"])
		for off in [0.0, 1.2, -1.2, 2.4, -2.4]:
			_add_wall_slots(slots, (wall["point"] as Vector3) + tangent * off, wall["out"], place)
	if slots.is_empty():
		return {}
	var center := Vector3.ZERO   # Mitte der Plätze – dort zählt die Deko (SITE_RADIUS)
	for slot: Dictionary in slots:
		center += slot["point"]
	center /= slots.size()
	var name := "die Lobby" if place == "lobby" else ("Zimmer %s" % _builder.rooms[place]["sign"] if _builder.rooms.has(place) else "")
	if place == "corridor":
		name = _corridor_name(Game.director.zone_name_at(p), walls.size() >= 3)
	return {"pos": Vector3(center.x, p.y, center.z), "wall": main["point"], "out": main["out"], "name": name, "place": place,
		"slots": slots}


## „den Südflur (Ostflügel)“, „eine Ecke im Nordflur (Westflügel, oben)“.
static func _corridor_name(zone: String, corner: bool) -> String:
	var upper := zone.ends_with(" (oben)")
	zone = zone.trim_suffix(" (oben)")
	var parts := zone.split(", ")
	if parts.size() != 2:
		return "eine Flurecke" if corner else "den Flur"
	var wing := parts[0] + (", oben" if upper else "")
	return ("eine Ecke im %s (%s)" if corner else "den %s (%s)") % [parts[1], wing]


## Lichterkette oben an der Wand: reicht nach beiden Seiten bis zur nächsten Wand, höchstens 1,5 m.
func _top_slot(wall_point: Vector3, out: Vector3) -> Dictionary:
	var space := get_world_3d().direct_space_state
	var point := wall_point + Vector3.UP * TOP_HEIGHT
	if not _wall_at(point, out) or not _space_free(point + out * 0.1, 0.35, 4):
		return {}
	var along := Vector3.UP.cross(out)
	var reach: Array[float] = [1.5, 1.5]
	for i in 2:
		var start := point + out * 0.06
		var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(start, start + along * (1.0 if i == 0 else -1.0) * 1.5, 1 | 2))
		if not hit.is_empty():
			reach[i] = start.distance_to(hit["position"]) - 0.05
	if reach[0] + reach[1] < 1.0:
		return {}
	var center := wall_point + along * (reach[0] - reach[1]) / 2.0
	return {"layer": "top", "point": center, "out": out, "stand": center + out * 0.8, "length": reach[0] + reach[1],
		"height": TOP_HEIGHT, "used": false}


## Wand- und Bodenplatz an dieser Wandstelle (Fußpunkt auf der Wandfläche), wenn dort glatte Wand ist (keine Tür,
## kein Fenster) und nichts hängt oder steht.
func _add_wall_slots(slots: Array, wall_point: Vector3, out: Vector3, place: String = "corridor") -> void:
	var along := Vector3.UP.cross(out)
	for side in [-0.35, 0.0, 0.35]:
		if not _wall_at(wall_point + along * side + Vector3.UP * 1.6, out) or not _wall_at(wall_point + along * side + Vector3.UP * 0.6, out):
			return
	if not _in_place(wall_point + out * 0.6, place):
		return
	var stand := wall_point + out * 0.75
	if _space_free(wall_point + out * 0.25 + Vector3.UP * 2.0, 0.32, 2 | 4) and _space_free(wall_point + out * 0.25 + Vector3.UP * 1.5, 0.32, 2 | 4):
		slots.append({"layer": "wall", "point": wall_point, "out": out, "stand": stand, "used": false})
	var floor_point := wall_point + out * 0.3
	if _space_free(floor_point + Vector3.UP * 0.35, 0.28, 1 | 2 | 4) and _floor_at(floor_point):
		slots.append({"layer": "floor", "point": floor_point, "out": out, "stand": stand, "used": false})


func _in_place(p: Vector3, place: String) -> bool:
	match place:
		"corridor":
			return _builder.in_corridor(p)
		"lobby":
			return _builder.in_lobby(p) and not _builder.in_area(p, "partyraum")
	return _builder.room_at(p) == place


## Glatte Wand (Ebene 1, keine Tür) genau an dieser Stelle?
func _wall_at(point: Vector3, out: Vector3) -> bool:
	var space := get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(point + out * 0.4, point - out * 0.2, 1 | 2)
	var hit := space.intersect_ray(query)
	if hit.is_empty() or not _is_wall(hit):
		return false
	return (hit["normal"] as Vector3).dot(out) > 0.9 and (hit["position"] as Vector3).distance_to(point) < 0.12


func _is_wall(hit: Dictionary) -> bool:
	var body := hit["collider"] as CollisionObject3D
	return body != null and (body.collision_layer & 1) != 0 and (body.collision_layer & 2) == 0


func _floor_at(point: Vector3) -> bool:
	var space := get_world_3d().direct_space_state
	var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(point + Vector3.UP * 1.0, point + Vector3.DOWN * 0.3, 1))
	return not hit.is_empty() and absf((hit["position"] as Vector3).y - point.y) < 0.08


func _space_free(center: Vector3, radius: float, mask: int) -> bool:
	var shape := SphereShape3D.new()
	shape.radius = radius
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = shape
	query.transform = Transform3D(Basis.IDENTITY, center)
	query.collision_mask = mask
	return get_world_3d().direct_space_state.intersect_shape(query, 1).is_empty()
