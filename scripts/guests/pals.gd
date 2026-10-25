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
## Gespeichert werden die Zähler je Paar (counts) und die verfeindeten Paare (feuds).

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
## Ruf (Deko-Suche): was ein Gast seinen Freunden über gemeinsame Taten erzählt, nach dieser Verzögerung
const PRAISE_DELAY := Vector2(20.0, 60.0)
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
var _queue: Array[Dictionary] = []   ## {guest, amount, delay, from} – Ruf mit Verzögerung
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


## Ruf (Spielkonzept 6.16): Der Gast erzählt seinen Freunden etwas Gutes über dich – sie mögen dich etwas mehr.
func praise(from: Guest, amount: float) -> void:
	for pal in pals_of(from):
		_queue.append({"guest": pal, "amount": amount, "delay": randf_range(PRAISE_DELAY.x, PRAISE_DELAY.y), "from": from.id})


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
	var i := _queue.size() - 1
	while i >= 0:
		var entry := _queue[i]
		entry["delay"] = float(entry["delay"]) - delta
		if float(entry["delay"]) <= 0.0:
			var g = entry["guest"]
			if is_instance_valid(g) and not g.dead and Social.tier(g) > Social.Tier.ENEMY:
				Game.social.change_relation(g, entry["amount"], TELL_CAP)
				heard[g.id] = entry["from"]
			_queue.remove_at(i)
		i -= 1
	_scan -= delta
	if _scan <= 0.0:
		_scan = TELL_SCAN
		_update_telling()


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
