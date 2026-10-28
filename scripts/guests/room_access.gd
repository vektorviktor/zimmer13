class_name RoomAccess
extends Node
## Zimmerzugang (Spielkonzept 6.19): Jedes Gästezimmer gehört seinem Haushalt und ist abgeschlossen. Wer hinein will,
## klopft (Door.interact → knock): Ist niemand da, macht keiner auf; wer schläft, wacht genervt auf; sonst kommt einer
## an die Tür, öffnet einen Spalt, und es gibt ein kurzes Gespräch an der Tür (DialogUI.open_door) – ehrlich fragen,
## lügen, Panik machen, bestechen. Ob er hereinlässt, hängt an Stufe, Charakter und Lage (chance). Drinnen läuft ein
## Besuch mit Ende; wer uneingeladen drinnen erwischt wird, fliegt raus (Hausfriedensbruch). Kinder allein öffnen nur
## Bekannten. Aufbrechen und Reparieren: Door.
## Schlüssel stehlen (4): Einem schlafenden Gast im eigenen Bett nimmt man den Zimmerschlüssel vom Nachttisch (am Bett,
## HideSpot fragt can_steal_key) – an den Schlüsselbund, mit den Zeugenregeln des Diebstahls. Am nächsten Morgen merkt
## der Gast es und lässt das Schloss tauschen (_swap_locks): Der Schlüssel am Bund wird zum alten („alt_…“), der nicht
## mehr passt; wer es war, bleibt unbekannt. Gespeichert: stolen.

## Einlass je Stufe in Prozent (6.3); ab „wütend“ nie
const BASE_CHANCE := {
	Social.Tier.GOOD_FRIEND: 95.0, Social.Tier.FRIEND: 80.0, Social.Tier.FRIENDLY: 60.0,
	Social.Tier.NICE: 40.0, Social.Tier.NEUTRAL: 20.0, Social.Tier.ANNOYED: 5.0,
}
## Gespräch an der Tür: Zuschläge in Prozentpunkten
const LIE_BONUS := 25.0
const LIE_SKEPTIC := -20.0
const LIE_CHILD := 40.0          ## Kinder lassen sich leichter beschwatzen
const PANIC_FEARFUL := 40.0
const PANIC_OTHER := 15.0
const PANIC_SKEPTIC := -30.0
const BRIBE_BONUS := 10.0
const BRIBE_MONEY := 3
## Lage: nachts, wenn etwas unterwegs ist (Freunde eher, Fremde eher nicht), frisch geweckt
const NIGHT_MALUS := -20.0
const DANGER_FRIEND := 20.0
const DANGER_STRANGER := -20.0
const WOKEN_MALUS := -15.0
const WOKEN_RELATION := -3.0
## Je Gast ein Versuch pro Spielstunde; so lange dauert ein Besuch, so lange hat man danach zum Gehen
const RETRY := Calendar.HOUR
const VISIT_TIME := 2.0 * Calendar.HOUR
const LEAVE_GRACE := 20.0
## Versprochenes Geschenk bzw. Panik ohne Grund: so lange (s) bis es auffällt, so viel kostet es
const PROMISE_TIME := 60.0
const LIE_CAUGHT := -10.0
const FALSE_ALARM := -8.0
## Uneingeladen drinnen erwischt; ein Kind hat einen Fremden hereingelassen (die Eltern erfahren es)
const TRESPASS_RELATION := -15.0
const TRESPASS_WITNESS := -5.0
const TRESPASS_COOLDOWN := 60.0
const KID_TRICKED := -10.0
## Wie weit die Tür beim Gespräch aufgeht (Grad) und wie lange man auf jemanden an der Tür wartet
const AJAR_DEGREES := 12.0
const ANSWER_DELAY := 2.0
const ANSWER_TIMEOUT := 10.0
const WALK_AWAY := 4.0

## Aufgebrochen bzw. mit dem Generalschlüssel in ein fremdes Zimmer: Besitzer, wenn er es mitbekommt; Zeugen; Scheibe
## des Schlüsselschranks (Hoteleigentum)
const FORCED_OWNER := -35.0
const FORCED_WITNESS := -10.0
const SMASH_WITNESS := -5.0
## Reparieren: so viel Dank je Erwachsenem des Haushalts, höchstens einmal je Tür und Tag – nie für eine selbst
## aufgebrochene (das Spiel weiß es, auch wenn kein Gast es weiß)
const REPAIR_THANKS := 8.0
## Werkzeug leihen: der Haushalt, der Werkzeug hat (HAUSHALTE.md H11, Konrad Lorenz), ab dieser Stufe, einmal am Tag
const LENDER_HOUSEHOLD := "H11"
const LEND_TIER := Social.Tier.FRIEND
## Schlüssel stehlen (4): Folgen wie beim Deko-Diebstahl (Social.on_player_took) – der Besitzer, wenn es jemand gesehen
## hat, die Zeugen, Gerede; um diese Uhrzeit am Morgen danach ist das Schloss getauscht
const KEY_THEFT_OWNER := -15.0
const KEY_THEFT_WITNESS := -10.0
const KEY_THEFT_GOSSIP := -8.0
const LOCK_SWAP_HOUR := 6.0
## Vorsatz am Schlüsselbund: ein gestohlener Schlüssel, dessen Schloss getauscht ist
const OLD_KEY := "alt_"

var visit := {}       ## laufender Besuch: {room, host, door, start, until, promise, panic, warned}
var _pending := {}    ## Geklopft, jemand kommt an die Tür: {door, guest, time, woken}
var _tries := {}      ## Gast-ID → Zeitpunkt des letzten Versuchs (Game.director.elapsed)
var _caught := {}     ## Zimmer → Zeitpunkt des letzten Hausfriedensbruchs
var _check := 0.0
var _repaired := {}   ## Tür → Tag der letzten Reparatur mit Dank
var _lent_day := -1
var _morning_day := -1
var stolen := {}      ## Zimmer → Spielzeit (Game.director.elapsed), ab der der Besitzer den Diebstahl merkt


func _now() -> float:
	return Game.director.elapsed if Game.director else 0.0


func _social() -> Social:
	return get_parent() as Social


## Der Spieler klopft an eine abgeschlossene Zimmertür.
func knock(door: Door) -> void:
	Game.noise("knock", door.center(), Game.player)
	if not _pending.is_empty() or (Game.dialog and Game.dialog.visible):
		return
	var residents := residents_home(door.room_no)
	if residents.is_empty():
		_later(func() -> void: Game.say("Niemand macht auf."))
		return
	var awake := residents.filter(func(g: Guest) -> bool: return not g.is_asleep())
	var responder: Guest = null
	for g: Guest in awake:
		if responder == null or (responder.is_child() and not g.is_child()):
			responder = g
	var woken := false
	if responder == null:   # alle schlafen: einer wacht auf, genervt
		for g: Guest in residents:
			if responder == null or (responder.is_child() and not g.is_child()):
				responder = g
		woken = true
		responder.wake_up()
		_social().change_relation(responder, WOKEN_RELATION)
	if _now() - float(_tries.get(responder.id, -INF)) < RETRY:
		_later(func() -> void: responder.say("Ich hab doch schon nein gesagt."))
		return
	_pending = {"door": door, "guest": responder, "time": 0.0, "woken": woken}
	responder._walk_to(responder.home["door_inside"], Guest.State.WALK)


## Wer aus diesem Zimmer gerade drinnen ist (lebend, nicht im Versteck).
func residents_home(no: String) -> Array[Guest]:
	var result: Array[Guest] = []
	var social := _social()
	if not social.builder.rooms.has(no):
		return result
	for g in social.living_guests():
		var guest: Guest = g
		if guest.home["no"] == no and guest.hiding == null and social.builder.room_at(guest.global_position) == no:
			result.append(guest)
	return result


func _later(f: Callable) -> void:
	get_tree().create_timer(ANSWER_DELAY, false).timeout.connect(f)


func _process(delta: float) -> void:
	if not _pending.is_empty():
		_answer(delta)
	if not visit.is_empty():
		_visit_step()
	_check -= delta
	if _check <= 0.0:
		_check = 0.5
		_watch_trespass()
		_morning_repairs()
		_swap_locks()


## Jemand kommt an die Tür: angekommen (oder nach ANSWER_TIMEOUT) öffnet er einen Spalt, und das Gespräch beginnt.
func _answer(delta: float) -> void:
	var door: Door = _pending["door"]
	var guest: Guest = _pending["guest"]
	_pending["time"] = float(_pending["time"]) + delta
	if not is_instance_valid(guest) or guest.dead or guest.fear >= 60.0 \
			or Game.player.global_position.distance_to(door.center()) > WALK_AWAY + 1.5:
		_pending.clear()   # weggegangen oder er hat jetzt anderes im Kopf
		return
	var inside: Vector3 = guest.home["door_inside"]
	if guest.global_position.distance_to(inside) > 1.0 and float(_pending["time"]) < ANSWER_TIMEOUT:
		return
	var woken := bool(_pending["woken"])
	_pending.clear()
	door.set_ajar(AJAR_DEGREES)
	Game.dialog.open_door(guest, door, woken)


## Chance (0–100) auf Einlass bei diesem Weg: "honest", "lie_lamp", "lie_gift", "panic", "bribe".
func chance(guest: Guest, way: String, woken: bool) -> float:
	var tier := Social.tier(guest)
	var skeptic := String(guest.profile.get("archetype", "")) == "Skeptiker"
	var value := 0.0
	if guest.is_child():
		if not knows_player(guest) and way == "honest":
			return 0.0   # „Mama sagt, ich darf nicht aufmachen.“
		value = 90.0 if knows_player(guest) else 0.0
		if way.begins_with("lie"):
			value += LIE_CHILD
		elif way == "bribe":
			value += BRIBE_BONUS * 2.0
		elif way == "panic":
			value += PANIC_FEARFUL
	else:
		if not BASE_CHANCE.has(tier):
			return 0.0
		value = BASE_CHANCE[tier]
		if way.begins_with("lie"):
			value += LIE_BONUS + (LIE_SKEPTIC if skeptic else 0.0)
		elif way == "panic":
			value += (PANIC_FEARFUL if String(guest.profile.get("archetype", "")) == "ängstlich" else PANIC_OTHER) \
				+ (PANIC_SKEPTIC if skeptic else 0.0)
		elif way == "bribe":
			value += BRIBE_BONUS
	if Calendar.phase() == Calendar.Phase.NIGHT:
		value += NIGHT_MALUS
	if _danger():
		value += DANGER_FRIEND if tier >= Social.Tier.FRIENDLY else DANGER_STRANGER
	if woken:
		value += WOKEN_MALUS
	return clampf(value, 0.0, 100.0)


## Kennt das Kind den Spieler (ein Freund der Familie)?
func knows_player(kid: Guest) -> bool:
	if Social.tier(kid) >= Social.Tier.FRIENDLY:
		return true
	for g in _social().living_guests():
		var adult: Guest = g
		if not adult.is_child() and adult.home["no"] == kid.home["no"] and Social.tier(adult) >= Social.Tier.FRIENDLY:
			return true
	return false


func _danger() -> bool:
	return Game.monster != null and Game.monster.is_active()


## Ergebnis des Gesprächs an der Tür: {ok, line}. Bei Erfolg geht die Tür auf und der Besuch beginnt.
func try_enter(guest: Guest, door: Door, way: String, woken: bool) -> Dictionary:
	_tries[guest.id] = _now()
	var odds := chance(guest, way, woken)
	var ok := randf() * 100.0 < odds
	if Game.tracing:
		print("[Zimmer] %s an der Tür von %s: %s, Chance %.0f %% → %s" % [guest.display_name, door.room_no, way, odds,
			"herein" if ok else "abgewiesen"])
	if not ok:
		door.set_open(false, false, true, guest)
		return {"ok": false, "line": _refusal(guest)}
	if way == "bribe":   # genommen wird nur, wer hereinkommt – zählt nicht als Geschenk
		Game.money -= BRIBE_MONEY
	if guest.is_child() and not knows_player(guest):   # beschwatzt – die Eltern erfahren es
		for g in _social().living_guests():
			var adult: Guest = g
			if not adult.is_child() and adult.home["no"] == guest.home["no"]:
				_social().change_relation(adult, KID_TRICKED)
	door.locked = false
	door.set_open(true, false, true, guest)
	visit = {"room": door.room_no, "host": guest, "door": door, "start": _now(), "until": _now() + VISIT_TIME,
		"promise": way == "lie_gift", "panic": way == "panic" and not _danger(), "warned": -1.0}
	guest._walk_to(guest._room_point(), Guest.State.WALK)   # tritt beiseite
	return {"ok": true, "line": _welcome(guest, way)}


func _refusal(guest: Guest) -> String:
	if guest.is_child():
		return "Mama sagt, ich darf nicht aufmachen." if guest.profile.get("sex", "m") == "f" or randf() < 0.5 \
			else "Papa sagt, ich darf niemanden reinlassen."
	match Social.tier(guest):
		Social.Tier.GOOD_FRIEND, Social.Tier.FRIEND:
			return "Jetzt nicht, wirklich. Ein andermal."
		Social.Tier.FRIENDLY, Social.Tier.NICE:
			return "Tut mir leid – heute nicht."
		Social.Tier.NEUTRAL:
			return "Nein. Ich kenn dich doch kaum."
	return "Vergiss es."


func _welcome(guest: Guest, way: String) -> String:
	match way:
		"panic":
			return "Schnell, rein! Mach die Tür zu!"
		"lie_lamp":
			return "Die Lampe? Ach so … ja, komm rein."
		"lie_gift":
			return "Für mich? Na, dann komm rein."
		"bribe":
			return "Na gut. Aber nicht lange."
	return "Ach, du bist's. Komm rein." if Social.tier(guest) >= Social.Tier.FRIEND else "Na gut, komm rein."


## Ein Geschenk an den Gastgeber löst das Versprechen ein (DialogUI._gift).
func on_gift(guest: Guest) -> void:
	if not visit.is_empty() and visit["host"] == guest:
		visit["promise"] = false


func _visit_step() -> void:
	var host: Guest = visit["host"]
	var door: Door = visit["door"]
	var social := _social()
	if not is_instance_valid(host) or host.dead:
		visit.clear()
		return
	var inside: bool = social.builder.room_at(Game.player.global_position) == visit["room"]
	var age := _now() - float(visit["start"])
	if bool(visit["promise"]) and age > PROMISE_TIME:
		visit["promise"] = false
		host.say("Und wo ist jetzt das, was du mir mitbringen wolltest?")
		social.change_relation(host, LIE_CAUGHT)
		social.add_deed(host, "hostile")
	if bool(visit["panic"]) and age > PROMISE_TIME:
		visit["panic"] = false
		if not _danger():
			host.say("Da war gar nichts. Du hast mir Angst gemacht – umsonst.")
			social.change_relation(host, FALSE_ALARM)
	if _now() > float(visit["until"]):
		if float(visit["warned"]) < 0.0:
			visit["warned"] = _now()
			if inside:
				host.say("Ich möchte jetzt allein sein. Bitte geh.")
		elif inside and _now() - float(visit["warned"]) > LEAVE_GRACE:
			host.say("Raus jetzt! Das ist mein Zimmer!")
			social.change_relation(host, TRESPASS_RELATION)
			social.add_deed(host, "hostile")
			visit["warned"] = _now() + 1000.0   # einmal reicht; er wartet, bis du draußen bist
	if not inside and (age > 3.0):
		_end_visit()


## Besuch zu Ende: Ist der Gastgeber zu Hause, schließt er hinter dir zu.
func _end_visit() -> void:
	var host: Guest = visit["host"]
	var door: Door = visit["door"]
	visit.clear()
	if is_instance_valid(door) and not door.broken:
		if door.is_open:
			door.set_open(false, false, true, host)
		door.locked = true


## Uneingeladen in einem fremden Zimmer: Sieht ihn ein Bewohner, fliegt er raus (Beziehung, Zeugen, Gerede).
func _watch_trespass() -> void:
	var social := _social()
	if Game.player == null or Game.player.sleeping:
		return
	var no := social.builder.room_at(Game.player.global_position)
	if no == "" or no == LevelBuilder.PLAYER_ROOM or not social.builder.households.has(no):
		return
	if not visit.is_empty() and visit["room"] == no:
		return
	if _now() - float(_caught.get(no, -INF)) < TRESPASS_COOLDOWN:
		return
	for g in residents_home(no):
		var owner: Guest = g
		if owner.is_asleep() or not owner.can_see_actor(Game.player) or not Game.player.recognized_by(owner):
			continue
		_caught[no] = _now()
		owner.say("Was machst du in meinem Zimmer?! Raus hier!" if not owner.is_child() else "Du darfst hier nicht rein!")
		social.change_relation(owner, TRESPASS_RELATION * (0.5 if owner.is_child() else 1.0))
		social.add_deed(owner, "hostile")
		var involved: Array = [owner]
		for w in residents_home(no):
			if w != owner and w.can_see_actor(Game.player):
				social.change_relation(w, TRESPASS_WITNESS)
				involved.append(w)
		social._spread_gossip(-6.0, involved)
		return


## Wer sieht den Spieler gerade (und erkennt ihn)?
func _witnesses() -> Array[Guest]:
	var result: Array[Guest] = []
	for g in _social().living_guests():
		var guest: Guest = g
		if not guest.is_asleep() and guest.can_see_actor(Game.player) and Game.player.recognized_by(guest):
			result.append(guest)
	return result


## Aufgebrochen (loud) bzw. mit dem Generalschlüssel geöffnet (6.19): eine feindselige Tat – gegenüber dem Besitzer,
## wenn er zu Hause ist oder es sieht, und gegenüber allen Zeugen; weitererzählt über das Freundesnetz. Ungesehen weiß
## niemand, wer es war.
func on_forced(door: Door, loud: bool) -> void:
	var social := _social()
	var no := door.room_no
	var witnesses := _witnesses()
	var home := residents_home(no)
	var involved: Array = []
	for g in social.living_guests():
		var owner: Guest = g
		if owner.home["no"] != no or owner.is_child():
			continue
		if owner in witnesses or (owner in home and (loud or owner.can_see_actor(Game.player))):
			social.change_relation(owner, FORCED_OWNER)
			social.add_deed(owner, "hostile")
			involved.append(owner)
	for w in witnesses:
		if not w in involved:
			social.change_relation(w, FORCED_WITNESS)
			involved.append(w)
	if not involved.any(func(g: Guest) -> bool: return g.home["no"] == no) and social.talk:
		social.talk.on_break_in(no)   # ungesehen: die Bewohner fragen nach (6.9)
	if involved.is_empty():
		return
	var first: Guest = involved[0]
	first.say("Du brichst bei mir ein?!" if first.home["no"] == no else "Hast du gerade die Tür von Zimmer %s aufgebrochen?!" % no)
	social._spread_gossip(-8.0, involved)


## Repariert (6.19): Dank des Haushalts (nicht für selbst aufgebrochene, einmal je Tür und Tag), weitererzählt.
func on_repaired(door: Door, own: bool) -> void:
	var social := _social()
	door.set_open(false, false, true)
	if own or int(_repaired.get(door, -1)) == Calendar.today() or not social.builder.households.has(door.room_no):
		return
	_repaired[door] = Calendar.today()
	for g in social.living_guests():
		var owner: Guest = g
		if owner.home["no"] == door.room_no and not owner.is_child():
			social.change_relation(owner, REPAIR_THANKS)
			if owner.global_position.distance_to(door.center()) < 8.0:
				owner.say("Du hast unsere Tür repariert? Danke!")


## Scheibe des Schlüsselschranks eingeschlagen: Zeugen mögen es nicht und erzählen es weiter.
func on_smashed(_cabinet: KeyCabinet) -> void:
	var witnesses := _witnesses()
	if witnesses.is_empty():
		return
	for w in witnesses:
		_social().change_relation(w, SMASH_WITNESS)
	witnesses[0].say("Was machst du da an der Rezeption?!")
	_social()._spread_gossip(-4.0, witnesses)


## Am Morgen repariert jeder Haushalt seine aufgebrochene Tür selbst (frühestens am Tag danach); ist keiner mehr am
## Leben, bleibt sie kaputt (6.18: Gedenkort).
func _morning_repairs() -> void:
	var day := Calendar.today()
	if day == _morning_day or Calendar.phase() == Calendar.Phase.NIGHT:
		return
	_morning_day = day
	var social := _social()
	for no in social.builder.households:
		var door: Door = social.builder.rooms[no]["door"]
		if not door.broken or door.broken_day >= day or social.household_lead(no) == null:
			continue
		door.broken = false
		door.broken_by_player = false
		door.set_open(false, true, true)
		door.locked = true


## Leiht dieser Gast dem Spieler sein Werkzeug (Konrad, ab „befreundet“, einmal am Tag)?
func can_lend(guest: Guest) -> bool:
	return String(guest.profile.get("household", "")) == LENDER_HOUSEHOLD and not guest.is_child() \
		and Social.tier(guest) >= LEND_TIER and _lent_day != Calendar.today()


func lend(guest: Guest) -> String:
	_lent_day = Calendar.today()
	Game.player.receive_item(Item.create(Item.Kind.TOOLBOX))
	return "Hier, mein Werkzeugkasten. Bring ihn mir wieder – und mach nichts kaputt damit."


# --- Schlüssel stehlen (4) ------------------------------------------------------------------------------------------

## Wer schläft in diesem Bett in seinem eigenen Zimmer (und hat seinen Schlüssel auf dem Nachttisch)?
func key_sleeper(bed: HideSpot) -> Guest:
	if bed.type != HideSpot.Type.BED or bed.room_no == "" or bed.room_no == LevelBuilder.PLAYER_ROOM:
		return null
	for node in [bed.occupant, bed.partner]:
		var g := node as Guest
		if g and not g.dead and g.is_asleep() and String(g.home["no"]) == bed.room_no:
			return g
	return null


## Kann der Spieler hier einen Zimmerschlüssel nehmen? Stehend am Bett (geduckt kriecht man darunter), solange er den
## passenden noch nicht am Bund hat.
func can_steal_key(bed: HideSpot, player: Player) -> bool:
	if player.crouching or player.hiding or key_sleeper(bed) == null:
		return false
	return not player.has_key(_key_of(bed.room_no))


func _key_of(no: String) -> String:
	var info: Dictionary = _social().builder.rooms.get(no, {})
	return (info["door"] as Door).key_id if info.has("door") else ""


## Den Schlüssel vom Nachttisch nehmen: an den Bund, eine feindselige Tat (die das Spiel kennt), Zeugen wie beim
## Diebstahl. Am Morgen danach tauscht der Haushalt das Schloss.
func steal_key(bed: HideSpot) -> void:
	var owner := key_sleeper(bed)
	if owner == null:
		return
	var no := bed.room_no
	var id := _key_of(no)
	var p := Game.player
	p.keyring.erase(OLD_KEY + id)   # ein früher gestohlener, inzwischen nutzloser
	p.add_key(id)
	stolen[no] = _lock_swap_time()
	Game.say("Du nimmst den Zimmerschlüssel vom Nachttisch.")
	var social := _social()
	social.add_deed(owner, "hostile")
	if Game.diary:   # eine dunkle Tat (3.10), wie Social.on_player_took
		Game.diary.note("first_theft", "Ich habe %s etwas weggenommen. Ich brauche es dringender, rede ich mir ein." % owner.display_name)
	if Game.tracing:
		print("[Zimmer] Schlüssel von Zimmer %s gestohlen (%s schläft), Schloss getauscht am %s um %s" % [no,
			owner.display_name, Calendar.date_text(float(stolen[no])), Calendar.time_text(float(stolen[no]))])
	var witnesses := _witnesses()
	witnesses.erase(owner)
	if witnesses.is_empty():
		return   # ungesehen – am Morgen merkt er nur, dass der Schlüssel fehlt
	social.change_relation(owner, KEY_THEFT_OWNER)
	var first: Guest = witnesses[0]
	first.say(first.line("tattle") if first.is_child() \
		else "Ich hab genau gesehen, wie du %s den Schlüssel weggenommen hast!" % owner.display_name)
	var involved: Array = [owner]
	for w in witnesses:
		social.change_relation(w, KEY_THEFT_WITNESS)
		involved.append(w)
	for w in witnesses:   # Kinder petzen – Mama und Papa glauben es sofort (6.13)
		var parent := w.parent_guest()
		if parent and not parent in involved:
			social.change_relation(parent, KEY_THEFT_WITNESS)
			involved.append(parent)
	social._spread_gossip(KEY_THEFT_GOSSIP, involved)


## Der nächste Morgen um LOCK_SWAP_HOUR nach jetzt.
func _lock_swap_time() -> float:
	var now := _now()
	var day := Calendar.raw_day_of(now)
	if Calendar.hour_of(now) >= LOCK_SWAP_HOUR:
		day += 1
	return Calendar.at(day, LOCK_SWAP_HOUR)


## Am Morgen nach dem Diebstahl: Der Haushalt merkt es und lässt das Schloss tauschen – der Schlüssel am Bund passt
## nicht mehr. Lebt dort niemand mehr, merkt es keiner, und er passt weiter.
func _swap_locks() -> void:
	for no in stolen.keys():
		if _now() < float(stolen[no]):
			continue
		stolen.erase(no)
		var lead := _social().household_lead(no)
		var id := _key_of(no)
		if lead == null or not id in Game.player.keyring:
			continue
		Game.player.keyring.erase(id)
		Game.player.add_key(OLD_KEY + id)
		lead.say("Mein Zimmerschlüssel ist weg! Ich lass das Schloss austauschen.")
		if Game.tracing:
			print("[Zimmer] %s merkt den Diebstahl – Schloss von Zimmer %s getauscht" % [lead.display_name, no])


func save_state() -> Dictionary:
	return {"stolen": stolen.duplicate()}


func load_state(d: Dictionary) -> void:
	stolen = {}
	var saved: Dictionary = d.get("stolen", {})
	for no in saved:
		stolen[String(no)] = float(saved[no])


## --schluesseldieb[=zimmer[,tausch]]: Der Haushaltsvorstand des Zimmers liegt schlafend im Bett, du stehst daneben und
## nimmst nach 1 s den Schlüssel; tausch: das Schloss wird schon 10 s danach getauscht. Nur nachts schläft er weiter
## (etwa --day=3 --uhr=2:00).
func debug_steal(no: String, swap: bool) -> bool:
	if not _social().night_due():
		print("[Zimmer] Debug: tagsüber wacht er gleich wieder auf – mit --day=3 --uhr=2:00 starten")
	var owner := _social().household_lead(no)
	if owner == null:
		print("[Zimmer] Debug: in Zimmer %s wohnt niemand" % no)
		return false
	owner.bedtime(true)
	var bed := owner.hiding as HideSpot
	if bed == null:
		print("[Zimmer] Debug: %s hat kein freies Bett" % owner.display_name)
		return false
	var at := bed.exit_point.global_position
	TeleportUI.place_player(at, bed.global_position - at)
	get_tree().create_timer(1.0, false).timeout.connect(func() -> void:
		if Game.tracing:
			print("[Zimmer] Am Bett von %s: %s" % [owner.display_name, bed.get_prompt(Game.player)])
		bed.interact(Game.player)
		if swap and stolen.has(no):
			stolen[no] = _now() + 10.0)
	return true
