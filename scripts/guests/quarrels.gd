class_name GuestQuarrels
extends Node
## Streit unter Gästen (Spielkonzept 6.16, 5.10; entschieden 2026-11-03, ZIM-33): Ein Gast klaut einem anderen Deko
## (Knappheit, DecoPlan.steal_when_scarce, oder in Panik). Sieht der Bestohlene es selbst oder erzählt es ihm ein Freund,
## der es gesehen hat (übers Freundesnetz, 6.18, 1 – eine Station), sind beide verfeindet (GuestPals.add_feud).
## - **Sichtbar:** Treffen sie sich danach (oder sieht er es gleich), gibt es einen lauten Wortwechsel – Sprechblasen
##   abwechselnd, Lärm „quarrel“ (~10 m). Danach meiden sie sich: Kommen sie sich nah, geht einer nach Hause.
## - **Versöhnung:** Der Spieler vermittelt – im Gespräch mit einem der beiden „Wollt ihr euch nicht vertragen?“, dann
##   richtet er dem anderen die Entschuldigung aus (Bitte „reconcile“, Art „Überbringen“ aus 6.14, GuestRequests).
##   Sonst verblasst der Streit nach FADE_DAYS Spieltagen von selbst.
## Kind von Social, erreichbar über Game.social.quarrels. Gespeichert werden die laufenden Streits (active), nicht die
## Nachrichten, die noch auf ein Treffen warten, und nicht ein gerade laufender Wortwechsel.

## Nach so vielen Spieltagen verblasst ein Streit (ohne Vermittlung)
const FADE_DAYS := 3
## Wortwechsel: so nah und in Sicht, so viele Sekunden zwischen zwei Sätzen
const ARGUE_RANGE := 7.0
const LINE_GAP := 2.2
## Meiden: so nah, dann geht einer nach Hause – je Gast höchstens alle AVOID_COOLDOWN Sekunden (Spielzeit)
const AVOID_RANGE := 4.0
const AVOID_COOLDOWN := 120.0
## Ein Freund, der den Diebstahl gesehen hat, erzählt es so lange (Spielzeit) beim nächsten Treffen; höchstens so viele
const NEWS_TIME := Calendar.DAY_SECONDS
const NEWS_WITNESSES := 2
const SCAN := 1.0
## Wortwechsel: Bestohlener, Dieb, Bestohlener, Dieb – %s ist jeweils der andere
const ACCUSE := ["%s! Das ist meine Deko – gib sie sofort zurück!", "Hab ich dich, %s! Finger weg von meiner Tür!",
	"%s, du Dieb! Glaubst du, ich seh das nicht?"]
const DEFEND := ["Ach, stell dich nicht so an, %s! Du hast doch genug!", "Was willst du, %s? Meine Tür hält sonst nicht!",
	"Reg dich ab, %s. Jeder muss sehen, wo er bleibt."]
const ACCUSE_2 := ["Genug?! Mit dir bin ich fertig, %s!", "Das vergess ich dir nicht, %s!", "Komm mir nicht mehr unter die Augen, %s!"]
const DEFEND_2 := ["Pff. Dann eben nicht, %s.", "Wie du willst, %s!", "Schrei hier nicht so rum, %s!"]
## Ein Freund hat es gesehen (an den Bestohlenen) und dessen Antwort
const NEWS_LINES := ["Du, ich hab gesehen, wie %s Deko von deiner Tür genommen hat!", "Pass auf – %s war an deiner Tür und hat was mitgehen lassen."]
const NEWS_REPLIES := ["Was?! Na warte …", "%s? Das gibt's doch nicht!"]
## Meiden: wenn einer abdreht
const AVOID_LINES := ["Pff.", "Ich geh lieber.", "Mit dem red ich nicht."]
## Vermitteln (DialogUI): was er sagt, wenn er sich vertragen will bzw. nicht mit dir darüber redet
const PEACE_LINES := {"thief": "Ach … ich hab's nur aus Angst getan. Sag %s, dass es mir leidtut, ja?",
	"victim": "Na gut. Sag %s, ich bin nicht mehr böse – aber nie wieder."}
const PEACE_REFUSE := "Halt du dich da raus."

## Schlüssel GuestPals.key → {thief, victim, day (Spieltag), argued (Wortwechsel schon gewesen), keep (schon vorher
## verfeindet – beim Verblassen bzw. Versöhnen bleibt die alte Feindschaft)}
var active := {}
var _news: Array[Dictionary] = []    ## {teller, victim, thief, until} – ein Freund hat es gesehen (nicht gespeichert)
var _argument := {}                  ## laufender Wortwechsel: {a (Bestohlener), b (Dieb), key, step, next}
var _avoided := {}                   ## Gast-ID → MonsterDirector.elapsed, ab dem er wieder ausweicht
var _day := -1
var _scan := SCAN


## Social.on_guest_stole: thief hat victim Deko geklaut. Sieht victim es, gibt es gleich Streit; sonst erzählen es ihm
## Freunde, die es gesehen haben.
func on_theft(thief: Guest, victim: Guest) -> void:
	if thief == null or victim == null or thief == victim or victim.dead or thief.dead or thief.housemate_of(victim):
		return
	if not victim.is_asleep() and victim.can_see_actor(thief):
		_discover(victim, thief, "gesehen")
		return
	var told := 0
	for other in Game.social.living_guests():
		var w: Guest = other
		if told >= NEWS_WITNESSES:
			break
		if w == thief or w == victim or w.is_asleep() or not Game.social.pals.are_pals(w, victim) or not w.can_see_actor(thief):
			continue
		_news.append({"teller": w, "victim": victim, "thief": thief, "until": _now() + NEWS_TIME})
		told += 1
		if Game.tracing:
			print("[Streit] %s hat gesehen, wie %s bei %s klaut" % [w.display_name, thief.display_name, victim.display_name])


## Streiten die beiden gerade (Diebstahl, noch nicht versöhnt oder verblasst)?
func quarreling(a: Guest, b: Guest) -> bool:
	return a != null and b != null and active.has(GuestPals.key(a, b))


## Mit wem er im Streit liegt (für „Wollt ihr euch nicht vertragen?“) – null: mit keinem.
func partner_of(g: Guest) -> Guest:
	for k in active:
		var q: Dictionary = active[k]
		var other := ""
		if q["thief"] == g.id:
			other = String(q["victim"])
		elif q["victim"] == g.id:
			other = String(q["thief"])
		if other != "":
			var o := Game.social.guest_by_id(other)
			if o and not o.dead:
				return o
	return null


## Hat g other beklaut (Meinung im Gespräch, Talk.opinion)?
func stole_from(g: Guest, other: Guest) -> bool:
	var q: Dictionary = active.get(GuestPals.key(g, other), {})
	return not q.is_empty() and q["thief"] == g.id


## Er will sich mit other vertragen – sein Satz an den Spieler (Vermitteln, DialogUI).
func peace_line(g: Guest, other: Guest) -> String:
	return String(PEACE_LINES["thief" if stole_from(g, other) else "victim"]) % other.display_name


## Die Entschuldigung ist ausgerichtet (GuestRequests.deliver): Der Streit ist vorbei, die Feindschaft auch – außer sie
## waren schon vorher verfeindet.
func reconcile(a: Guest, b: Guest) -> void:
	_end(GuestPals.key(a, b), "versöhnt")


func _discover(victim: Guest, thief: Guest, how: String) -> void:
	var k := GuestPals.key(victim, thief)
	if active.has(k):
		return
	var pals := Game.social.pals
	active[k] = {"thief": thief.id, "victim": victim.id, "day": Calendar.today(), "argued": false,
		"keep": pals.are_feuding(victim, thief)}
	pals.add_feud(victim, thief)
	if Game.tracing:
		print("[Streit] %s weiß jetzt, dass %s geklaut hat (%s)" % [victim.display_name, thief.display_name, how])


func _end(k: String, why: String) -> void:
	if not active.has(k):
		return
	var q: Dictionary = active[k]
	active.erase(k)
	if not q["keep"]:
		Game.social.pals.feuds.erase(k)
	if not _argument.is_empty() and _argument["key"] == k:
		_argument = {}
	if Game.tracing:
		print("[Streit] %s und %s: %s" % [Game.social.guest_name(String(q["victim"])), Game.social.guest_name(String(q["thief"])), why])


func _now() -> float:
	return Game.director.elapsed if Game.director else 0.0


func _process(delta: float) -> void:
	if Game.game_over or Game.social == null or Game.director == null:
		return
	if not _argument.is_empty():
		_argue_step()
	_scan -= delta
	if _scan > 0.0:
		return
	_scan = SCAN
	var today := Calendar.today()
	if _day != today:
		_day = today
		_fade(today)
	if (active.is_empty() and _news.is_empty()) or Game.social.sleep_active:
		return
	_update_news()
	if _argument.is_empty():
		_update_meetings()


## Verblassen: nach FADE_DAYS Spieltagen ohne Vermittlung (auch über einen Zeitsprung im Schlaf hinweg).
func _fade(today: int) -> void:
	for k in active.keys():
		if today - int(active[k]["day"]) >= FADE_DAYS:
			_end(k, "verblasst")


## Ein Freund, der es gesehen hat, trifft den Bestohlenen: erzählt es ihm (einer je Durchgang).
func _update_news() -> void:
	var pals := Game.social.pals
	for i in range(_news.size() - 1, -1, -1):
		var e := _news[i]
		var w = e["teller"]
		var v = e["victim"]
		var t = e["thief"]
		if _now() > float(e["until"]) or not is_instance_valid(w) or not is_instance_valid(v) or not is_instance_valid(t) \
				or w.dead or v.dead or t.dead or active.has(GuestPals.key(v, t)):
			_news.remove_at(i)
			continue
		if pals._free(w) and pals._free(v) and w.global_position.distance_to(v.global_position) <= GuestPals.TELL_RANGE:
			_news.remove_at(i)
			var victim: Guest = v
			var thief: Guest = t
			(w as Guest).say(NEWS_LINES.pick_random() % thief.display_name)
			get_tree().create_timer(2.5, false).timeout.connect(func() -> void:
				if is_instance_valid(victim) and not victim.dead and is_instance_valid(thief):
					var reply: String = NEWS_REPLIES.pick_random()
					victim.say(reply % thief.display_name if "%s" in reply else reply))
			_discover(victim, thief, "von " + (w as Guest).display_name)
			return


## Treffen sich zwei Streitende: erst der Wortwechsel, danach meiden sie sich.
func _update_meetings() -> void:
	var pals := Game.social.pals
	for k in active.keys():
		var q: Dictionary = active[k]
		var v := Game.social.guest_by_id(String(q["victim"]))
		var t := Game.social.guest_by_id(String(q["thief"]))
		if v == null or t == null or v.dead or t.dead or not pals._free(v) or not pals._free(t):
			continue
		var d := v.global_position.distance_to(t.global_position)
		if not q["argued"]:
			if d <= ARGUE_RANGE and (v.can_see_actor(t) or t.can_see_actor(v)):
				_start_argument(k, v, t)
				return
		elif d <= AVOID_RANGE:
			_avoid(v, t)


func _start_argument(k: String, v: Guest, t: Guest) -> void:
	active[k]["argued"] = true
	_argument = {"a": v, "b": t, "key": k, "step": 0, "next": _now()}
	for pair in [[v, t], [t, v]]:
		var g: Guest = pair[0]
		if g.held == null and g.state in [Guest.State.IDLE, Guest.State.WALK]:
			g.hold_argument((pair[1] as Guest).global_position, LINE_GAP * 4.0 + 1.0)
	if Game.tracing:
		print("[Streit] Wortwechsel: %s und %s" % [v.display_name, t.display_name])


## Vier Sätze abwechselnd, jeder laut (Lärm „quarrel“); bricht ab, wenn einer stirbt oder sich versteckt.
func _argue_step() -> void:
	if _now() < float(_argument["next"]):
		return
	var a = _argument["a"]
	var b = _argument["b"]
	var step := int(_argument["step"])
	if step >= 4 or not is_instance_valid(a) or not is_instance_valid(b) or a.dead or b.dead or a.hiding or b.hiding:
		_argument = {}
		return
	var speaker: Guest = a if step % 2 == 0 else b
	var other: Guest = b if step % 2 == 0 else a
	var lines: Array = [ACCUSE, DEFEND, ACCUSE_2, DEFEND_2][step]
	speaker.say(String(lines.pick_random()) % other.display_name)
	Game.noise("quarrel", speaker.global_position, speaker)
	_argument["step"] = step + 1
	_argument["next"] = _now() + LINE_GAP


## Sie kommen sich nah: einer dreht ab und geht nach Hause (wer gerade steht, sonst der Dieb).
func _avoid(v: Guest, t: Guest) -> void:
	var now := _now()
	if now < float(_avoided.get(v.id, 0.0)) or now < float(_avoided.get(t.id, 0.0)):
		return   # einer ist gerade erst abgedreht
	var g: Guest = v if v.state == Guest.State.IDLE and t.state != Guest.State.IDLE else t
	if g.state == Guest.State.PARTY:
		return
	_avoided[g.id] = now + AVOID_COOLDOWN
	g.say(AVOID_LINES.pick_random())
	g.walk_home()
	if Game.tracing:
		print("[Streit] %s meidet %s und geht nach Hause" % [g.display_name, (t if g == v else v).display_name])


func save_state() -> Dictionary:
	return {"active": active.duplicate(true)}


## Ältere Stände (vor Version 67): kein Streit.
func load_state(d: Dictionary) -> void:
	active = {}
	var saved: Dictionary = d.get("active", {})
	for k in saved:
		var q: Dictionary = saved[k]
		active[String(k)] = {"thief": String(q.get("thief", "")), "victim": String(q.get("victim", "")),
			"day": int(q.get("day", Calendar.today())), "argued": bool(q.get("argued", true)), "keep": bool(q.get("keep", false))}
	reset()


## Beim Laden: Laufendes vergessen (die Gäste werden neu gebaut).
func reset() -> void:
	_news.clear()
	_argument = {}
	_avoided.clear()
	_day = Calendar.today()


# --- Debug (--streit) ----------------------------------------------------------------------------

## --streit=dieb,opfer[,gesehen|freund|versoehnen|verblassen]: Beide (bei freund auch ein Freund des Opfers) stehen vor
## dir; die Regeln laufen durch und melden „[Streit] … ok“ bzw. „FEHLER“.
func debug(parts: PackedStringArray) -> void:
	var social := Game.social
	var thief := social.find_guest(parts[0] if parts.size() > 0 and parts[0] != "" else "bruno")
	var victim := social.find_guest(parts[1] if parts.size() > 1 and parts[1] != "" else "edna")
	var what := parts[2] if parts.size() > 2 and parts[2] != "" else "gesehen"
	if thief == null or victim == null or thief == victim:
		print("[Streit] Debug: zwei verschiedene Gäste angeben, z. B. --streit=bruno,edna")
		return
	var check := func(text: String, ok: bool) -> void:
		print("[Streit] %s: %s" % [text, "ok" if ok else "FEHLER"])
	var p := Game.player
	var ahead := -p.global_transform.basis.z
	var side := p.global_transform.basis.x
	var base := p.global_position + ahead * 2.5
	var k := GuestPals.key(thief, victim)
	social.pals.feuds.erase(k)
	active.erase(k)
	for g: Guest in [thief, victim]:
		g._set_idle(60.0)
	thief.global_position = base - side * 1.2
	victim.global_position = base + side * 1.2
	print("[Streit] Debug: %s klaut bei %s (%s)" % [thief.display_name, victim.display_name, what])
	match what:
		"gesehen":
			victim.look_at(thief.global_position, Vector3.UP, false)
			on_theft(thief, victim)
			check.call("gesehen: verfeindet", social.pals.are_feuding(thief, victim) and quarreling(thief, victim))
			get_tree().create_timer(LINE_GAP * 5.0 + 2.0, false).timeout.connect(func() -> void:
				check.call("Wortwechsel gewesen", bool(active.get(k, {}).get("argued", false)) and _argument.is_empty())
				_avoided.clear()   # gleich nach dem Wortwechsel ist einer vielleicht schon gegangen
				victim._set_idle(30.0)
				thief.global_position = victim.global_position + side * 1.5
				thief._set_idle(30.0)
				get_tree().create_timer(SCAN * 2.5, false).timeout.connect(func() -> void:
					check.call("meiden: einer geht", thief.state == Guest.State.WALK or victim.state == Guest.State.WALK)))
		"freund":
			var w: Guest = null
			for other in social.living_guests():
				var o: Guest = other
				if o != thief and o != victim and not o.is_child() and not o.housemate_of(victim) and not o.housemate_of(thief):
					w = o
					break
			social.pals.feuds.erase(GuestPals.key(w, victim))
			social.pals.note(w, victim, GuestPals.PAL_DEEDS)
			w._set_idle(60.0)
			w.global_position = thief.global_position - ahead * 1.5   # zwischen dir und ihm – dahinter steht vielleicht eine Wand
			w.look_at(thief.global_position, Vector3.UP, false)
			victim.look_at(victim.global_position + side * 3.0, Vector3.UP, false)   # sieht weg, der Dieb steht hinter ihm
			on_theft(thief, victim)
			check.call("nicht selbst gesehen: noch kein Streit", not quarreling(thief, victim))
			check.call("Freund %s hat es gesehen" % w.display_name, _news.size() == 1)
			thief.global_position = base - side * 4.0
			victim.global_position = w.global_position + side * 1.2
			get_tree().create_timer(SCAN * 3.0, false).timeout.connect(func() -> void:
				check.call("vom Freund erfahren: verfeindet", social.pals.are_feuding(thief, victim) and quarreling(thief, victim)))
		"versoehnen":
			_discover(victim, thief, "Debug")
			active[k]["argued"] = true
			var req := social.requests.make_reconcile(thief, victim)
			check.call("Vermitteln möglich", partner_of(thief) == victim and not req.is_empty())
			print("[Streit] %s: %s" % [thief.display_name, peace_line(thief, victim)])
			social.requests.accept(thief, req)
			check.call("Ausrichten beim Opfer", social.requests.message_for(victim) == req)
			print("[Streit] %s antwortet: %s" % [victim.display_name, social.requests.deliver(victim, req)])
			check.call("versöhnt", not social.pals.are_feuding(thief, victim) and not quarreling(thief, victim))
			check.call("Dank: „%s“" % social.requests.thanks_on_greet(thief), social.requests.request_of(thief).is_empty())
		"verblassen":
			_discover(victim, thief, "Debug")
			active[k]["day"] = Calendar.today() - FADE_DAYS + 1
			_fade(Calendar.today())
			check.call("nach %d Tagen noch Streit" % (FADE_DAYS - 1), quarreling(thief, victim))
			active[k]["day"] = Calendar.today() - FADE_DAYS
			_fade(Calendar.today())
			check.call("nach %d Tagen verblasst" % FADE_DAYS, not quarreling(thief, victim) and not social.pals.are_feuding(thief, victim))
			social.pals.add_feud(thief, victim)   # schon vorher verfeindet (Streich): bleibt
			_discover(victim, thief, "Debug")
			active[k]["day"] = Calendar.today() - FADE_DAYS
			_fade(Calendar.today())
			check.call("alte Feindschaft bleibt", not quarreling(thief, victim) and social.pals.are_feuding(thief, victim))
		"halten":   # für --savetest: ein Streit, der gespeichert wird
			_discover(victim, thief, "Debug")
