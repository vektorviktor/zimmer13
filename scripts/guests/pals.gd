class_name GuestPals
extends Node
## Freundschaften unter Gästen (Spielkonzept 6.16): Gäste werden Freunde, wenn sie oft etwas zusammen tun –
## schmücken, Deko suchen, Suppe essen, spielen, feiern, an der Bar trinken. Familie (6.13) und Zimmernachbarn sind
## es von Anfang an. Wer mit dem Spieler mindestens „befreundet“ ist, erzählt seinen Freunden beim Treffen Gutes über
## ihn – sie mögen ihn dann mehr, bis höchstens „befreundet“. Kind von Social, erreichbar über Game.social.pals.
## Feindschaften (6.16, 2026-10-22): Wer verpetzt bekommt, wessen Kind ihm einen Streich gespielt hat, ist mit dessen
## Eltern verfeindet (Pranks) – Verfeindete sind keine Freunde, auch nicht als Nachbarn.
## Freund meines Feindes (2026-10-22): Wird der Spieler mit einem Gast „befreundet“, erfahren dessen Feinde es nach
## RIVAL_DELAY und mögen ihn weniger (RIVAL_AMOUNT) – je Paar einmal.
## Freundesnetz als Kanal (Spielkonzept 6.18, 1; 2026-11-03): Lob und Klagen über den Spieler (spread) laufen nur über
## Freunde, Familie und Zimmernachbarn und werden erzählt, wenn sich zwei davon treffen. Die Stärke richtet sich nach dem
## Tratsch des Erzählers und halbiert sich je Station, nach NET_STATIONS ist Schluss (net_strength; dieselbe Regel für
## Geschichten in Talk). Wer keine Freunde hat, hört nichts; was nach NET_TIME keiner erzählt hat, ist vergessen.
## Gespeichert werden die Zähler je Paar (counts) und die verfeindeten Paare (feuds) – das Netz nicht.

## Ab so vielen gemeinsamen Taten sind zwei Gäste Freunde
const PAL_DEEDS := 3
## Zimmernachbarn: Türen höchstens so weit auseinander (gleiches Stockwerk)
const NEIGHBOR_RANGE := 6.5
## Weitererzählen: so nah stehen beide, so viel bringt es (je Paar einmal am Spieltag), höchstens bis hierhin
const TELL_RANGE := 3.2
const TELL_AMOUNT := 8.0
const TELL_CAP := 79.0
const TELL_SCAN := 1.5
## Freund meines Feindes: so viel weniger mögen dich seine Feinde, so lange dauert es, bis sie es erfahren
const RIVAL_AMOUNT := -15.0
const RIVAL_DELAY := Vector2(20.0, 60.0)
const RIVAL_LINES := ["Du bist also mit %s befreundet? Na schön.", "Mit %s gibst du dich ab? Dann such dir andere Freunde.",
	"Ich hab gehört, du und %s … Das merk ich mir."]
## Freundesnetz (6.18, 1): so viele Stationen weit, so lange (Spielzeit) wartet eine Nachricht auf ein Treffen
const NET_STATIONS := 2
const NET_TIME := Calendar.DAY_SECONDS
const NET_BAD_LINES := ["Hast du gehört, was Zimmer 13 gemacht hat?", "Pass bloß auf mit Zimmer 13 …",
	"Zimmer 13? Da würde ich mich vorsehen, glaub mir.", "Weißt du, was man über Zimmer 13 erzählt?"]
const NET_CHILD_BAD_LINES := ["Zimmer 13 ist voll gemein!", "Mit Zimmer 13 spiel ich nicht mehr!"]
const NET_BAD_REPLIES := ["Echt jetzt?", "Na so was.", "Das merk ich mir.", "Hätte ich nicht gedacht."]
## Große Gruppen (Feier, großes Schmücken): jeder merkt sich nur so viele andere aus der Gruppe
const GROUP_PAIRS := 3
const TELL_LINES := ["Hast du schon mit Zimmer 13 geredet? Echt in Ordnung!", "Zimmer 13 hat mir neulich geholfen. Wirklich nett.",
	"Auf Zimmer 13 kann man sich verlassen, glaub mir.", "Wenn du mal Hilfe brauchst – frag Zimmer 13."]
const CHILD_TELL_LINES := ["Zimmer 13 ist voll nett!", "Mit Zimmer 13 kann man super spielen!"]
const REPLY_LINES := ["Ach ja? Dann sag ich mal Hallo.", "Gut zu wissen.", "Hm. Vielleicht hast du recht.", "Wenn du das sagst …"]
## Beim nächsten Gespräch: wer ihm von dir erzählt hat
const HEARD_LINES := ["%s hat mir viel Gutes von dir erzählt.", "Du bist also die Person aus Zimmer 13, von der %s so schwärmt.",
	"%s sagt, auf dich kann man sich verlassen."]

## "id_a|id_b" (sortiert) → Anzahl gemeinsamer Taten
var counts := {}
## "id_a|id_b" (sortiert) → true: verfeindet
var feuds := {}
## Gast-ID → ID dessen, der ihm zuletzt Gutes über dich erzählt hat (für das nächste Gespräch; nicht gespeichert)
var heard := {}
var _told := {}          ## "id_a|id_b" → Spieltag des letzten Weitererzählens (nicht gespeichert)
var _rivals := {}        ## "freund|feind" → true: hat es schon erfahren (nicht gespeichert)
var _net: Array[Dictionary] = []     ## {teller, hearer, msg, amount, cap, station, until[, direct, pass]} – wartet aufs Treffen
var _net_known := {}                 ## Nachricht → {Gast-ID: true}: kennt sie schon (Erzähler, Gehörte)
var _net_next := 0
var _scan := TELL_SCAN


static func key(a: Guest, b: Guest) -> String:
	return "%s|%s" % [a.id, b.id] if a.id < b.id else "%s|%s" % [b.id, a.id]


## Eine gemeinsame Tat zweier Gäste.
func note(a: Guest, b: Guest, amount: int = 1) -> void:
	if a == null or b == null or a == b or a.dead or b.dead:
		return
	var k := key(a, b)
	var before := int(counts.get(k, 0))
	counts[k] = before + amount
	if before < PAL_DEEDS and before + amount >= PAL_DEEDS and Game.tracing:
		print("[Freunde] %s und %s sind jetzt Freunde" % [a.display_name, b.display_name])


## Alle in der Gruppe haben etwas zusammen gemacht – bei großen Gruppen merkt sich jeder nur ein paar andere.
func note_group(group: Array) -> void:
	var living := group.filter(func(g) -> bool: return is_instance_valid(g) and not g.dead)
	if living.size() <= GROUP_PAIRS + 1:
		for i in living.size():
			for j in range(i + 1, living.size()):
				note(living[i], living[j])
		return
	for g: Guest in living:
		var others := living.filter(func(o) -> bool: return o != g)
		others.shuffle()
		for o: Guest in others.slice(0, GROUP_PAIRS):
			note(g, o)


## despite_rumor: Misstrauen aus einem geglaubten Gerücht (6.9) übergehen – waren sie vorher Freunde?
func are_pals(a: Guest, b: Guest, despite_rumor: bool = false) -> bool:
	if a == null or b == null or a == b:
		return false
	if feuds.has(key(a, b)):
		return false   # verfeindet (6.16)
	if not despite_rumor and (a.has_stance("distrusts:" + b.id) or b.has_stance("distrusts:" + a.id)):
		return false   # „X hat geklaut“ – geglaubt (6.9)
	if a.parent_guest() == b or b.parent_guest() == a or a.housemate_of(b):
		return true   # Familie (6.13): Eltern und Kinder, ein Haushalt (6.20)
	if int(counts.get(key(a, b), 0)) >= PAL_DEEDS:
		return true
	return _neighbors(a, b)


## Zwei Gäste werden Feinde (Streich verpetzt, Pranks).
func add_feud(a: Guest, b: Guest) -> void:
	if a == null or b == null or a == b or a.dead or b.dead:
		return
	var k := key(a, b)
	if feuds.has(k):
		return
	feuds[k] = true
	if Game.tracing:
		print("[Feinde] %s und %s sind jetzt verfeindet" % [a.display_name, b.display_name])


func are_feuding(a: Guest, b: Guest) -> bool:
	return a != null and b != null and feuds.has(key(a, b))


## Der Spieler ist jetzt mit `friend` befreundet: Wer mit `friend` verfeindet ist, erfährt es und mag ihn weniger.
func on_player_befriended(friend: Guest) -> void:
	for other in Game.social.living_guests():
		var rival: Guest = other
		var k := "%s|%s" % [friend.id, rival.id]
		if rival == friend or not are_feuding(friend, rival) or _rivals.has(k):
			continue
		_rivals[k] = true
		get_tree().create_timer(randf_range(RIVAL_DELAY.x, RIVAL_DELAY.y), false).timeout.connect(func() -> void:
			if not is_instance_valid(rival) or rival.dead or not is_instance_valid(friend):
				return
			Game.social.change_relation(rival, RIVAL_AMOUNT)
			rival.say(RIVAL_LINES.pick_random() % friend.display_name)
			if Game.tracing:
				print("[Feinde] %s erfährt, dass du mit %s befreundet bist: %.0f" % [rival.display_name, friend.display_name, rival.relation]))


func _neighbors(a: Guest, b: Guest) -> bool:
	var da: Vector3 = a.home["door_front"]
	var db: Vector3 = b.home["door_front"]
	return absf(da.y - db.y) < 1.0 and da.distance_to(db) < NEIGHBOR_RANGE


## Lebende Freunde eines Gastes.
func pals_of(g: Guest) -> Array[Guest]:
	var result: Array[Guest] = []
	for other in Game.social.living_guests():
		if are_pals(g, other):
			result.append(other)
	return result


## Ruf (Spielkonzept 6.16): Der Gast erzählt seinen Freunden etwas Gutes über dich – sie mögen dich etwas mehr
## (übers Freundesnetz, 6.18, 1).
func praise(from: Guest, amount: float) -> void:
	spread([from], amount, TELL_CAP)


## Stärke einer Nachricht an Station `station` (1 = vom ersten Erzähler) als Faktor: nach dem Tratsch des Erzählers,
## je Station halb so stark (Spielkonzept 6.18, 1).
static func net_strength(teller: Guest, station: int) -> float:
	return float(teller.profile["gossip"]) * pow(0.5, station - 1)


## Etwas über den Spieler spricht sich herum (6.18, 1): `tellers` wissen es (Opfer, Zeugen) und erzählen es ihren
## Freunden, sobald sie sie treffen. amount: Beziehung bei voller Stärke; cap: höchstens bis hierhin (Lob).
func spread(tellers: Array, amount: float, cap: float = 100.0) -> void:
	_net_next += 1
	var known := {}
	for t in tellers:
		if is_instance_valid(t) and not t.dead:
			known[t.id] = true
	_net_known[_net_next] = known
	for t in tellers:
		if is_instance_valid(t) and not t.dead:
			_net_pass(t, _net_next, amount, cap, 1)


## Wie spread mit einem Erzähler – dazu erzählt er es den Betroffenen (affected) selbst, sobald er sie trifft, auch wenn
## sie nicht seine Freunde sind: Sie trifft es mit affected_amount, unabhängig von seinem Tratsch; weiter erzählen sie es
## mit amount wie jeder (Tagebuch beim Einbruch, 6.19, ZIM-54).
func spread_with_affected(teller: Guest, amount: float, affected: Array, affected_amount: float) -> void:
	spread([teller], amount)
	var msg := _net_next
	var until := _now() + NET_TIME
	for v in affected:
		var victim := v as Guest
		if victim == null or victim.dead or victim == teller:
			continue
		for i in range(_net.size() - 1, -1, -1):
			if _net[i]["msg"] == msg and _net[i]["hearer"] == victim:
				_net.remove_at(i)   # ist er auch sein Freund: nur die Nachricht an den Betroffenen
		_net.append({"teller": teller, "hearer": victim, "msg": msg, "amount": affected_amount, "cap": 100.0, "station": 1,
			"until": until, "direct": true, "pass": amount})


## Wie viele Nachrichten noch auf ein Treffen warten (Debug, Tests).
func net_pending() -> int:
	return _net.size()


func _net_pass(teller: Guest, msg: int, amount: float, cap: float, station: int) -> void:
	var known: Dictionary = _net_known[msg]
	var until := _now() + NET_TIME
	for pal in pals_of(teller):
		if not known.has(pal.id):
			_net.append({"teller": teller, "hearer": pal, "msg": msg, "amount": amount, "cap": cap, "station": station,
				"until": until})


func save_state() -> Dictionary:
	return {"counts": counts.duplicate(), "feuds": feuds.keys()}


## Ältere Stände (vor Version 29): nur die Zähler, ohne Feindschaften.
func load_state(data: Dictionary) -> void:
	counts = {}
	feuds = {}
	var saved: Dictionary = data.get("counts", {}) if data.get("counts") is Dictionary else data
	for k in saved:
		counts[String(k)] = int(saved[k])
	for k in data.get("feuds", []):
		feuds[String(k)] = true


## Im Gespräch: einmal sagen, wer ihm von dir erzählt hat ("" = niemand).
func take_heard_line(g: Guest) -> String:
	if not heard.has(g.id):
		return ""
	var from := String(heard[g.id])
	heard.erase(g.id)
	return HEARD_LINES.pick_random() % Game.social.guest_name(from)


func _process(delta: float) -> void:
	if Game.game_over or Game.social == null:
		return
	_scan -= delta
	if _scan <= 0.0:
		_scan = TELL_SCAN
		if not _update_net():
			_update_telling()


func _now() -> float:
	return Game.director.elapsed if Game.director else 0.0


## Freundesnetz: Wer sich trifft, erzählt (einer je Durchgang) – true, wenn erzählt. Vergessenes fällt heraus.
func _update_net() -> bool:
	if _net.is_empty():
		_net_known.clear()
		return false
	var now := _now()
	var asleep := Game.social.sleep_active
	var told := false
	var i := _net.size() - 1
	while i >= 0:
		var e := _net[i]
		var a = e["teller"]
		var b = e["hearer"]
		if now > float(e["until"]) or not is_instance_valid(a) or not is_instance_valid(b) or a.dead or b.dead \
				or (_net_known[e["msg"]] as Dictionary).has(b.id):
			_net.remove_at(i)
		elif not told and not asleep and _free(a) and _free(b) and a.global_position.distance_to(b.global_position) <= TELL_RANGE:
			_net.remove_at(i)
			_net_tell(e)   # hängt hinten an – der Durchgang läuft rückwärts, das stört nicht
			told = true
		i -= 1
	var live := {}
	for e in _net:
		live[e["msg"]] = true
	for msg in _net_known.keys():
		if not live.has(msg):
			_net_known.erase(msg)
	return told


func _net_tell(e: Dictionary) -> void:
	var a: Guest = e["teller"]
	var b: Guest = e["hearer"]
	var station := int(e["station"])
	var base := float(e["amount"])
	(_net_known[e["msg"]] as Dictionary)[b.id] = true
	var amount := base if e.get("direct", false) else base * net_strength(a, station)
	var before := b.relation
	var good := base > 0.0
	if good:
		a.say((CHILD_TELL_LINES if a.is_child() else TELL_LINES).pick_random())
		if Social.tier(b) > Social.Tier.ENEMY:
			Game.social.change_relation(b, amount, float(e["cap"]))
			heard[b.id] = a.id
	else:
		a.say((NET_CHILD_BAD_LINES if a.is_child() else NET_BAD_LINES).pick_random())
		Game.social.change_relation(b, amount)
	get_tree().create_timer(2.5, false).timeout.connect(func() -> void:
		if is_instance_valid(b) and not b.dead:
			b.say((REPLY_LINES if good else NET_BAD_REPLIES).pick_random()))
	if station < NET_STATIONS:
		_net_pass(b, int(e["msg"]), float(e.get("pass", base)), float(e["cap"]), station + 1)
	if Game.tracing:
		print("[Netz] %s erzählt %s (Station %d, Stärke %.2f): %.0f → %.0f" % [a.display_name, b.display_name, station,
			net_strength(a, station), before, b.relation])


## Wer dich mag, erzählt es Freunden, die er trifft (je Paar einmal am Spieltag).
func _update_telling() -> void:
	var social := Game.social
	if social.sleep_active:
		return
	var today := Calendar.today()
	var tellers := social.living_guests().filter(func(g: Guest) -> bool:
		return Social.tier(g) >= Social.Tier.FRIEND and _free(g))
	for a: Guest in tellers:
		for b: Guest in social.living_guests():
			if b == a or not _free(b) or Social.tier(b) >= Social.Tier.FRIEND or Social.tier(b) <= Social.Tier.ENEMY:
				continue
			if b.global_position.distance_to(a.global_position) > TELL_RANGE or not are_pals(a, b):
				continue
			var k := key(a, b)
			if int(_told.get(k, 0)) == today:
				continue
			_told[k] = today
			_tell(a, b)
			return   # einer je Durchgang reicht – sonst reden alle gleichzeitig


func _free(g: Guest) -> bool:
	return not g.dead and g.hiding == null and g.fear < 60.0 and g.state in [Guest.State.IDLE, Guest.State.WALK, Guest.State.PARTY]


func _tell(a: Guest, b: Guest) -> void:
	a.say((CHILD_TELL_LINES if a.is_child() else TELL_LINES).pick_random())
	var before := b.relation
	Game.social.change_relation(b, TELL_AMOUNT, TELL_CAP)
	heard[b.id] = a.id
	get_tree().create_timer(2.5, false).timeout.connect(func() -> void:
		if is_instance_valid(b) and not b.dead:
			b.say(REPLY_LINES.pick_random()))
	if Game.tracing:
		print("[Freunde] %s erzählt %s Gutes über dich: %.0f → %.0f" % [a.display_name, b.display_name, before, b.relation])
