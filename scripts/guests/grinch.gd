class_name Grinch
extends Node
## Gustav Peters, der „Halloween-Grinch“ (Spielkonzept 2.6): pensionierter Lehrer in Zimmer 020, hasst Halloween und
## alle im Hotel. Bis zur Siegerehrung:
##   · Deko vor seiner Tür (am Anfang ein „Jahrmarkt“ der Kinder, später, was jemand hinlegt) holt er und wirft sie weg:
##     Kürbisse, Kerzen und Glühbirnen zerschmettert er vor seinen Füßen, alles andere fliegt den Flur hinunter
##   · Ab und zu geht er an eine fremde Tür auf seinem Stockwerk, wirft die Deko dort um und eins davon weg
##   · Brennt im Partyraum Licht, geht er hinüber und schaltet es aus; läuft eine Feier, stellt er den Plattenspieler ab
##   · Er sucht Streit: Immer wieder geht er zu jemandem hin. Wer ihm über den Weg läuft, bekommt etwas zu hören – Kinder hören auf zu toben und laufen weinend zu ihren Eltern,
##     Feiernde verlassen die Feier, manche Erwachsene sind danach mit ihm verfeindet (GuestPals, 6.16). Manchmal wirft
##     er mit etwas (liegt nichts in Reichweite, aus seinem Koffer) oder schlägt zu – Kinder schlägt er nicht, den
##     Spieler schon (Guest.start_attack)
##   · Er schmückt nicht, feiert nicht, gibt nichts Süßes, bittet um nichts und kommt nicht zur Siegerehrung (Hooks
##     über is_grinch). Während sich die Gäste versammeln, geht er heim und schreibt Tagebuch.
## Bei der Siegerehrung holt ihn das Monster ungesehen (taken, MonsterDirector.first_attack_unseen): Tür offen,
## Schleifspur bis 2 m in den Flur Richtung Treppenhaus (Traces.add_drag_trail), kein Schrei. Bis man Zimmer 020 findet,
## reden die Gäste darüber; wer es findet, schreibt es ins Tagebuch („first_death“), sein Tagebuch auf dem Tisch
## (GustavDiary) ins Notizbuch.
## Ausnahme ist Doris Lange (FRIEND_HOUSEHOLD), seine einzige Freundin (2.6, 2.9): sie verschont er – kein Streit, kein
## Wurf, ihre Tür lässt er in Ruhe.
## Kind von Social, erreichbar über Game.social.grinch. Nicht gespeichert: Was zählt, steht im Spielstand der Welt
## (Gustav tot, Tür, Spuren, Tagebuch des Spielers).

const HOUSEHOLD := "H25"
## Doris Lange aus 033 gegenüber (HAUSHALTE.md)
const FRIEND_HOUSEHOLD := "H34"
const SCAN := 0.5
## Deko vor seiner Tür: so nah an der Tür
const DOOR_RANGE := 2.5
## Die Kinder haben ihm zum Anfang das hingelegt (Besitzer: ein Kind)
const START_GIFTS := [Item.Kind.PUMPKIN, Item.Kind.MINI_PUMPKIN, Item.Kind.SHEET_GHOST, Item.Kind.LEAVES]
## Wegwerfen: so weit fliegt es den Flur hinunter (m), so lange (s)
const TOSS_FAR := Vector2(5.0, 8.0)
const TOSS_TIME := 0.7
const SMASH_TIME := 0.3
## Fremde Tür: so oft (s), Türen so weit weg (gleiches Stockwerk), Deko so nah an ihr
const WRECK_EVERY := Vector2(240.0, 480.0)
const WRECK_RANGE := 30.0
const WRECK_DOOR := 2.2
## Partyraum: so oft sieht er nach dem Licht (s)
const PARTY_EVERY := Vector2(120.0, 260.0)
## Begegnungen: so nah, so lange je Person Ruhe, so lange zwischen zwei Sprüchen überhaupt
const MEET_RANGE := 3.5
const MEET_AGAIN := 90.0
const GRUMBLE_GAP := 8.0
## Er sucht Streit: so oft (s) geht er zu jemandem hin, der höchstens so weit weg ist (gleiches Stockwerk)
const SEEK_EVERY := Vector2(50.0, 110.0)
const SEEK_RANGE := 40.0
## Angreifen: so oft höchstens (s), so wahrscheinlich bei einer Begegnung, Wurf statt Schlag, aufheben in dieser Nähe
const ATTACK_EVERY := Vector2(60.0, 130.0)
const ATTACK_CHANCE := 0.5
const THROW_SHARE := 0.55
const PICK_RANGE := 2.2
const THROW_TIME := 0.45
## Wurf am Spieler: trifft, wenn er so nah an der Zielstelle steht, wenn es ankommt; so sehr verletzt es
const PLAYER_HIT := 0.8
const PLAYER_INJURY := 0.15
## Faustschlag gegen einen Gast: so nah, so lange läuft er höchstens hinterher (s)
const PUNCH_REACH := 1.2
const CHASE_TIME := 10.0
## Was er wirft (aus der Nähe bzw. aus dem Koffer)
const THROWABLE := [Item.Kind.PUMPKIN, Item.Kind.MINI_PUMPKIN, Item.Kind.CARVED_PUMPKIN, Item.Kind.CANDLE, Item.Kind.SKULL,
	Item.Kind.SODA_CAN, Item.Kind.APPLE, Item.Kind.SWEETS, Item.Kind.LEAVES, Item.Kind.SPIDER, Item.Kind.DICE_CUP,
	Item.Kind.COFFEE, Item.Kind.TEA, Item.Kind.ROAST_PUMPKIN]
## Nach seinem Tod: so oft sagt ein Gast in der Nähe des Spielers etwas darüber, bis man Zimmer 020 findet
const GOSSIP_EVERY := 45.0
const GOSSIP_RANGE := 8.0

const GRUMBLE_LINES := ["Halloween. Was für ein Unfug.", "Gehen Sie mir aus dem Weg.",
	"Erwachsene Leute basteln Fledermäuse. Unfassbar.", "Ihr Kürbis stinkt bis auf den Flur.",
	"Nehmen Sie das Grinsen aus dem Gesicht.", "Ruhe! Manche Leute wollen lesen."]
const KID_LINES := ["Weg da, du Gör!", "Lass mich mit deinen Kürbissen in Ruhe!", "Hör auf zu kichern!",
	"Ab zu deinen Eltern, aber flott!"]
const PLAYER_LINES := ["Sie schon wieder.", "Wenn Sie mir einen Kürbis vor die Tür legen, fliegt er.",
	"Sie gehören wohl auch zu diesen Kürbisleuten.", "Haben Sie nichts Besseres zu tun?"]
const REPLY_LINES := ["Was für ein Griesgram!", "Na, Ihnen auch einen schönen Tag.", "Der Grinch hat wieder Laune …",
	"Unverschämt!"]
const KID_REPLY_LINES := ["*schnief*", "Der Grinch ist gemein!", "Mamaaa!"]
const DOOR_LINES := ["Was soll der Plunder vor meiner Tür?!", "Weg damit.", "Ich nehme an keinem Wettbewerb teil!"]
const WRECK_LINES := ["Kitsch. Weg damit.", "So ein Plunder.", "Das braucht kein Mensch."]
const PARTY_LINES := ["Ruhe jetzt! Es gibt Leute, die lesen wollen.", "Schluss mit dem Gedudel!"]
const LIGHT_LINES := ["Wer lässt hier das Licht brennen? Strom kostet Geld.", "Licht aus. Hier feiert keiner."]
const THROW_LINES := ["Da, nimm!", "Fang!", "Verschwinde!"]
const PUNCH_LINES := ["Jetzt reicht's mir!", "Ich hab gesagt, Sie sollen verschwinden!"]
const AFTER_LINES := ["Habt ihr gehört? Bei Herrn Peters steht die Tür offen.", "Da ist Blut … bis raus auf den Flur.",
	"Zimmer 020 … ich geh da nicht mehr vorbei.", "Herr Peters war nicht bei der Siegerehrung. Und jetzt ist er weg."]
const AFTER_KID_LINES := ["Der Grinch ist weg.", "Wir haben ihm doch Kürbisse hingelegt …"]
## Tagebuch des Spielers, wenn er Zimmer 020 findet (statt des gewöhnlichen ersten Toten, Social.on_guest_died)
const FOUND_ENTRY := "Gustav Peters aus Zimmer 020 ist fort. Seine Tür stand offen, eine Blutspur führt in den Flur und hört einfach auf. Er war nicht bei der Siegerehrung."
const DIARY_TITLE := "Tagebuch von Gustav Peters"
## Sein Tagebuch: ab wann ein Eintrag dasteht (Tag, Stunde) und der Text; der letzte erst nach seinem Tod (ohne Zeit)
const DIARY := [
	[1, 16.5, "1. Oktober. Angekommen. Das Zimmer ist ordentlich, mehr lässt sich nicht sagen. Im ganzen Haus Kürbisse, als hätte ein Gemüsehändler Pleite gemacht. Erwachsene Menschen basteln Fledermäuse aus Pappe. Und überall Kinder, die einem Kürbisse vor die Füße stellen und kichern. Vierzig Jahre Schuldienst – ich weiß, wie man das nennt."],
	[1, 21.0, "1. Oktober, abends. Vor meiner Tür lag ein ganzer Jahrmarkt. „Für den Wettbewerb“, sagt die Kleine. Ich nehme an keinem Wettbewerb teil. Ich habe alles weggeworfen, bis auf das letzte Pappgespenst. Im Partyraum brennt den ganzen Tag das Licht, als ob Strom nichts kostet."],
	[-1, 0.0, "2. Oktober, abends. Seit einer Stunde dröhnt drüben im Partyraum diese Musik. Zweimal war ich schon drüben, habe das Licht ausgeknipst und den Plattenspieler abgestellt, zweimal läuft er wieder. Und jetzt johlen sie auch noch in der Lobby um eine Puppe herum. Eine Jury! Erwachsene Leute! Morgen früh gehe ich als Erstes zur Direktion und\n\n(Darunter blutige Fingerabdrücke.)"],
]
const DIARY_JOT := "Gustav Peters hat alles weggeworfen, was vor seiner Tür lag. Bei der Siegerehrung hat es ihn geholt – an seiner Tür hing nichts."

var builder: LevelBuilder
var diary: GustavDiary
## Gustav (auch tot) – nach dem Laden neu gesucht
var gustav: Guest:
	get:
		if not is_instance_valid(_gustav) or not _gustav in Game.social.guests:
			_gustav = null
			for g in Game.social.guests:
				if is_grinch(g):
					_gustav = g
					break
		return _gustav

var _gustav: Guest
var _scan := 0.0
## Laufender Gang: {kind: "door" | "wreck" | "party" | "punch", item, no, target, time}
var _job := {}
var _wreck_timer := 0.0
var _party_timer := 0.0
var _attack_timer := 0.0
var _grumble_timer := 0.0
var _seek_timer := 0.0
var _met := {}               ## Gast-ID bzw. "player" → Zeitpunkt der letzten Begegnung
var _time := 0.0
var _gossip := 20.0


## Ist das Gustav Peters? (Haushalt H25, Spielkonzept 2.6)
static func is_grinch(g: Guest) -> bool:
	return g != null and not g.is_child() and String(g.profile.get("household", "")) == HOUSEHOLD


## Ist das Doris Lange, die er verschont?
static func is_friend(g: Guest) -> bool:
	return g != null and not g.is_child() and String(g.profile.get("household", "")) == FRIEND_HOUSEHOLD


## Zimmernummer von Doris ("" ohne sie)
func _friend_room() -> String:
	for g in Game.social.guests:
		if is_friend(g):
			return String((g as Guest).home["no"])
	return ""


func setup(p_builder: LevelBuilder) -> void:
	builder = p_builder
	_wreck_timer = randf_range(WRECK_EVERY.x, WRECK_EVERY.y) * 0.5
	_party_timer = randf_range(PARTY_EVERY.x, PARTY_EVERY.y) * 0.5
	_attack_timer = randf_range(ATTACK_EVERY.x, ATTACK_EVERY.y) * 0.5
	var g := gustav
	if g == null:
		return
	g.relation = minf(g.relation, -35.0)   # er mag niemanden – auch dich nicht („wütend“)
	_place_start_gifts(g)
	var no := String(g.home["no"])
	var table: Vector3 = builder.room_tables.get(no, Vector3.INF)
	diary = GustavDiary.new()
	diary.grinch = self
	builder.world.add_child(diary)
	if table != Vector3.INF:
		diary.global_position = table + Vector3(0.12, 0.01, -0.08)
	else:
		diary.global_position = (g.home["center"] as Vector3) + Vector3(0, 0.01, 0)
	diary.rotation.y = 0.4


## Der „Jahrmarkt“ vor seiner Tür: von einem Kind, das sich freut – er wirft ihn weg, sobald er heimkommt.
func _place_start_gifts(g: Guest) -> void:
	var kids := Game.social.guests.filter(func(k: Guest) -> bool: return k.is_child())
	var giver: Guest = kids[0] if not kids.is_empty() else null
	var front: Vector3 = g.home["door_front"]
	var along: Vector3 = g.home["along"]
	var i := 0
	for kind: Item.Kind in START_GIFTS:
		var item := Item.create(kind, "")
		item.owner_id = giver.id if giver else ""
		item.position = front + along * (-0.45 + 0.3 * i) + (g.home["into"] as Vector3) * 0.15 + Vector3(0, 0.03, 0)
		item.rotation.y = randf() * TAU
		Game.social._world.add_child(item)
		i += 1


# --- Ablauf ---------------------------------------------------------------------------------------

func _process(delta: float) -> void:
	if Game.game_over or Game.social == null or Game.director == null:
		return
	_time += delta
	_wreck_timer -= delta
	_party_timer -= delta
	_attack_timer -= delta
	_grumble_timer -= delta
	_seek_timer -= delta
	_scan -= delta
	if _scan > 0.0:
		return
	_scan = SCAN
	var g := gustav
	if g == null:
		return
	if g.dead:
		_after_death()
		return
	if Game.director.first_attack_done:
		return   # alter Spielstand o. Ä.: er lebt noch, aber der Bruch ist vorbei – dann ist er einfach still
	if Game.contest and Game.contest.is_gathering():
		_stay_home(g)
		return
	if not _job.is_empty():
		_job_step(g)
		return
	if not _free(g):
		return
	if _party_due() and _go_party(g):
		return
	if _go_door(g):
		return
	if _meet(g):
		return
	if _wreck_timer <= 0.0:
		_wreck_timer = randf_range(WRECK_EVERY.x, WRECK_EVERY.y)
		_go_wreck(g)
	elif _seek_timer <= 0.0:
		_seek_timer = randf_range(SEEK_EVERY.x, SEEK_EVERY.y)
		_seek(g)


## Streit suchen: zu einem wachen Gast (oder dir) auf seinem Stockwerk – dort trifft er ihn (_meet).
func _seek(g: Guest) -> void:
	var options: Array[Node3D] = []
	for other in Game.social.living_guests():
		var o: Guest = other
		if o != g and not o.is_asleep() and o.hiding == null and absf(o.global_position.y - g.global_position.y) < 1.5 				and o.global_position.distance_to(g.global_position) < SEEK_RANGE:
			options.append(o)
	var p := Game.player
	if p and not p.dead and p.hiding == null and absf(p.global_position.y - g.global_position.y) < 1.5 			and p.global_position.distance_to(g.global_position) < SEEK_RANGE:
		options.append(p)
	if options.is_empty():
		return
	var target: Node3D = options.pick_random()
	g._walk_to(_floor_near(target.global_position + (g.global_position - target.global_position).normalized() * 1.5),
		Guest.State.WALK)


## Frei für einen Gang: steht oder geht herum, wach, ohne Angst, nichts in der Hand, kein Gespräch.
func _free(g: Guest) -> bool:
	return g.state in [Guest.State.IDLE, Guest.State.WALK] and not Game.social.sleep_active and g.fear < 60.0 \
		and g.held == null and g.hiding == null and not g.is_following()


## Siegerehrung: Er geht heim, macht die Tür zu und schreibt Tagebuch (2.6).
func _stay_home(g: Guest) -> void:
	if not _job.is_empty():
		_end_job(g)
	if g.state in [Guest.State.IDLE, Guest.State.WALK] and builder.room_at(g.global_position) != String(g.home["no"]) \
			and g._target.distance_to(g._room_point()) > 1.5:
		g._walk_to(g._room_point(), Guest.State.WALK)


## Der Gang läuft noch? Abgebrochen (Schreck, Gespräch, Feier …): Was er geholt hat, fällt hin.
func _job_step(g: Guest) -> void:
	var kind := String(_job["kind"])
	if g.state != Guest.State.VISIT:
		_end_job(g)
		return
	if kind != "punch":
		return
	var target: Guest = _job["target"]
	if not is_instance_valid(target) or target.dead or target.hiding or _time > float(_job["time"]) + CHASE_TIME:
		_end_job(g)
		g._set_idle(randf_range(3.0, 6.0))
		return
	if g.global_position.distance_to(target.global_position) <= PUNCH_REACH:
		_punch(g, target)
		return
	g._target = target.global_position   # er läuft hinterher


func _end_job(g: Guest) -> void:
	_job = {}
	if g.held:
		g._drop_held()


## Gast ist am Ziel seines Gangs (Social.on_visit_arrived). true = es war Gustav auf einem Gang.
func on_arrived(g: Guest) -> bool:
	if not is_grinch(g) or _job.is_empty():
		return false
	match String(_job["kind"]):
		"party":
			_at_party(g)
		"door", "wreck":
			_at_deco(g)
		"punch":
			var target: Guest = _job["target"]
			if is_instance_valid(target) and not target.dead and g.global_position.distance_to(target.global_position) <= PUNCH_REACH:
				_punch(g, target)
			elif is_instance_valid(target) and not target.dead:
				g._walk_to(target.global_position, Guest.State.VISIT)   # weiter hinterher (_job_step)
			else:
				_end_job(g)
				g._set_idle(randf_range(3.0, 6.0))
	return true


# --- Partyraum ------------------------------------------------------------------------------------

func _party_switch() -> LightSwitch:
	return LightSwitch.find(get_tree(), builder.room_at(builder.party_center))


func _party_due() -> bool:
	if Game.social.party_active:
		return true
	if _party_timer > 0.0:
		return false
	_party_timer = randf_range(PARTY_EVERY.x, PARTY_EVERY.y)
	var sw := _party_switch()
	return sw != null and sw.on


## Hinüber zum Lichtschalter des Partyraums (bei einer Feier zum Plattenspieler).
func _go_party(g: Guest) -> bool:
	var sw := _party_switch()
	var goal: Vector3
	if Game.social.party_active:
		goal = Game.social.record_player.global_position
	elif sw:
		goal = sw.global_position + sw.global_basis.z * 0.7
	else:
		return false
	goal = NavigationServer3D.map_get_closest_point(g.get_world_3d().navigation_map, Vector3(goal.x, builder.party_center.y, goal.z))
	_job = {"kind": "party", "time": _time}
	g.start_visit(goal)
	if Game.tracing:
		print("[Grinch] %s geht in den Partyraum (%s)" % [g.display_name, "Feier" if Game.social.party_active else "Licht"])
	return true


func _at_party(g: Guest) -> void:
	_job = {}
	if Game.social.party_active:
		g.say(PARTY_LINES.pick_random())
		Game.social.end_party("%s stellt den Plattenspieler ab." % g.display_name)
	var sw := _party_switch()
	if sw and sw.on:
		if not Game.social.party_active:
			g.say(LIGHT_LINES.pick_random())
		sw.set_on(false)
	g._set_idle(randf_range(2.0, 4.0))
	if Game.tracing:
		print("[Grinch] Partyraum: Musik aus, Licht aus")


# --- Deko -----------------------------------------------------------------------------------------

## Deko vor der Tür von Zimmer no (ohne Gehaltenes); auch aufgehängte – er reißt sie ab.
func _deco_at(no: String, reach: float) -> Array[Item]:
	var front: Vector3 = builder.rooms[no]["door_front"]
	var result: Array[Item] = []
	for node in get_tree().get_nodes_in_group("items"):
		var it := node as Item
		if it.kind in Guest.DECO_KINDS and not it.is_held and absf(it.global_position.y - front.y) < 2.5 \
				and Vector2(it.global_position.x - front.x, it.global_position.z - front.z).length() < reach \
				and not Game.social.is_in_closed_chest(it):
			result.append(it)
	return result


## Liegt etwas vor seiner Tür? Hin, holen.
func _go_door(g: Guest) -> bool:
	var no := String(g.home["no"])
	var found := _deco_at(no, DOOR_RANGE)
	if found.is_empty():
		return false
	var item: Item = found[0]
	_job = {"kind": "door", "item": item, "no": no, "time": _time}
	g.start_visit(_floor_near(item.global_position))
	return true


## Fremde Tür auf seinem Stockwerk mit Deko davor (auch Zimmer 13): hin, umwerfen, eins wegwerfen.
func _go_wreck(g: Guest) -> void:
	var own := String(g.home["no"])
	var spared := _friend_room()
	var doors: Array[String] = []
	for no: String in builder.rooms:
		var front: Vector3 = builder.rooms[no]["door_front"]
		if no == own or no == spared or absf(front.y - g.global_position.y) > 1.5 or front.distance_to(g.global_position) > WRECK_RANGE:
			continue
		if not _deco_at(no, WRECK_DOOR).is_empty():
			doors.append(no)
	if doors.is_empty():
		return
	var no: String = doors.pick_random()
	var item: Item = _deco_at(no, WRECK_DOOR).pick_random()
	_job = {"kind": "wreck", "item": item, "no": no, "time": _time}
	g.start_visit(_floor_near(item.global_position))
	if Game.tracing:
		print("[Grinch] %s geht zur Tür von Zimmer %s (%s)" % [g.display_name, String(builder.rooms[no]["sign"]), item.display_name])


func _floor_near(p: Vector3) -> Vector3:
	return NavigationServer3D.map_get_closest_point(get_viewport().world_3d.navigation_map, p)


## Angekommen: das Stück holen und wegwerfen (an fremden Türen erst alles umwerfen). Vor seiner Tür gleich das nächste.
func _at_deco(g: Guest) -> void:
	var found = _job.get("item")   # kann inzwischen fort sein (verfault, geholt)
	var no := String(_job["no"])
	var wreck := String(_job["kind"]) == "wreck"
	_job = {}
	if not is_instance_valid(found) or (found as Item).is_held or (found as Item).global_position.distance_to(g.global_position) > 2.0:
		g._set_idle(randf_range(1.0, 3.0))
		return
	var item: Item = found
	if wreck:
		for it in _deco_at(no, WRECK_DOOR):
			if it != item and it.kind in Item.TOPPLE_KINDS and not it.hung and not it.is_toppled():
				it.knock_over(g.global_position)
		Game.noise("cat_knock", item.global_position, g)
	var owner := Game.social.guest_by_id(item.owner_id)
	g.say((WRECK_LINES if wreck else DOOR_LINES).pick_random())
	_dispose(g, item, no)
	if owner and owner != g and not owner.dead:
		owner.expected_deco = maxi(0, owner.expected_deco - 1)   # weiß, wer es war – sucht nicht nach einem Dieb
		if not owner.is_child():
			Game.social.pals.add_feud(g, owner)
		if owner.can_see_actor(g):
			owner.say(KID_REPLY_LINES.pick_random() if owner.is_child() else "He! Das ist meins!")
	if Game.tracing:
		print("[Grinch] %s wirft %s vor Zimmer %s weg" % [g.display_name, item.display_name, String(builder.rooms[no]["sign"])])
	if not wreck and not _deco_at(no, DOOR_RANGE).is_empty():
		_go_door.call_deferred(g)   # der Rest auch
	else:
		g._set_idle(randf_range(3.0, 6.0))


## Wegwerfen: Zerbrechliches an fremden Türen vor die Füße geschmettert, alles andere den Flur hinunter (in die Richtung mit mehr Platz).
## Ist der Flur zu kurz – oder liegt es schon zum zweiten Mal hier –, zerreißt er es. Gehört danach niemandem mehr.
func _dispose(g: Guest, item: Item, no: String) -> void:
	var start := g.global_position + Vector3.UP * 1.3 - g.global_basis.z * 0.3
	if item.kind in Item.BURST_KINDS and no != String(g.home["no"]):   # vor der eigenen Tür will er keinen Matsch
		g._take_into_hand(item)
		_throw(g, start, g.global_position - g.global_basis.z * 0.6, SMASH_TIME)
		return
	var front: Vector3 = builder.rooms[no]["door_front"]
	var along: Vector3 = builder.rooms[no]["along"]
	var free := 0.0
	var space := g.get_world_3d().direct_space_state
	for dir: Vector3 in [along, -along]:
		var eye := front + Vector3.UP * 1.3
		var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(eye, eye + dir * TOSS_FAR.y, 1))
		var reach := TOSS_FAR.y if hit.is_empty() else eye.distance_to(hit["position"]) - 0.6
		if reach > free:
			free = reach
			along = dir
	if free < DOOR_RANGE + 1.0 or item.has_meta("grinch_tossed"):
		_tear(g, item)
		return
	g._take_into_hand(item)
	item.set_meta("grinch_tossed", true)
	var to := front + along * randf_range(minf(TOSS_FAR.x, free), free)
	g._face(to, 1.0)
	_throw(g, start, to, TOSS_TIME)


## Zerreißen bzw. zertreten: Das Stück ist fort.
func _tear(g: Guest, item: Item) -> void:
	Game.noise("drop", item.global_position, g)
	if Game.player and Game.player.global_position.distance_to(item.global_position) < 12.0:
		Game.caption("[Etwas zerreißt]")
	item.remove_from_group("items")
	item.queue_free()


## Das Gehaltene von start auf target werfen (wie Pranks._throw).
func _throw(g: Guest, start: Vector3, target: Vector3, time: float) -> Item:
	var item := g.held
	if item == null:
		return null
	g.held = null
	item.reparent(Game.social._world, true)
	item.owner_id = ""
	var gravity := Vector3(0, -float(ProjectSettings.get_setting("physics/3d/default_gravity")), 0)
	item.throw_from(start, (target - start) / time - gravity * time * 0.5, g)   # ihn selbst trifft der Wurf nicht
	return item


# --- Begegnungen ----------------------------------------------------------------------------------

## Jemand in der Nähe, den er sieht? Ein Spruch – oder er wirft bzw. schlägt. true = beschäftigt.
func _meet(g: Guest) -> bool:
	if _grumble_timer > 0.0:
		return false
	var best = null
	var best_d := MEET_RANGE
	var p := Game.player
	if p and not p.dead and p.hiding == null and not p.sleeping and _time - float(_met.get("player", -1000.0)) > MEET_AGAIN \
			and g.can_see_actor(p):
		best_d = g.global_position.distance_to(p.global_position)
		best = p if best_d < MEET_RANGE else null
		best_d = minf(best_d, MEET_RANGE)
	for other in Game.social.living_guests():
		var o: Guest = other
		if o == g or is_friend(o) or o.is_asleep() or o.hiding or o.state in [Guest.State.TALKING, Guest.State.MINIGAME] \
				or _time - float(_met.get(o.id, -1000.0)) <= MEET_AGAIN:
			continue
		var d := g.global_position.distance_to(o.global_position)
		if d < best_d and g.can_see_actor(o):
			best = o
			best_d = d
	if best == null:
		return false
	_met["player" if best == p else (best as Guest).id] = _time
	_grumble_timer = GRUMBLE_GAP
	g._face(best.global_position, 1.0)
	if _attack_timer <= 0.0 and randf() < ATTACK_CHANCE:
		_attack_timer = randf_range(ATTACK_EVERY.x, ATTACK_EVERY.y)
		if _attack(g, best):
			return true
	if best == p:
		g.say(PLAYER_LINES.pick_random())
	else:
		_spoil(g, best)
	return false


## Die Stimmung verderben: Kinder hören auf zu toben und laufen weinend zu Mama oder Papa, Feiernde gehen,
## Erwachsene antworten pikiert – manche sind danach mit ihm verfeindet.
func _spoil(g: Guest, o: Guest) -> void:
	if o.is_child():
		g.say(KID_LINES.pick_random())
		o.say(KID_REPLY_LINES.pick_random())
		o.fear = minf(100.0, o.fear + 15.0)
		o._laugh = 0.0
		if o.state in [Guest.State.IDLE, Guest.State.WALK, Guest.State.PARTY]:
			if o.state == Guest.State.PARTY:
				o.leave_party()
			o._run_to_parent()
		return
	g.say(GRUMBLE_LINES.pick_random())
	o.say(REPLY_LINES.pick_random())
	if o.state == Guest.State.PARTY:
		o.leave_party()
		o._set_idle(randf_range(4.0, 8.0))
	if randf() < 0.3:
		Game.social.pals.add_feud(g, o)


## Werfen (etwas in Reichweite oder aus dem Koffer) oder zuschlagen. Kinder schlägt er nicht. false = nichts davon.
func _attack(g: Guest, target) -> bool:
	var is_player: bool = target == Game.player
	var child: bool = not is_player and (target as Guest).is_child()
	if randf() < THROW_SHARE or child:
		var item := _something_to_throw(g)
		if item:
			g._take_into_hand(item)
			g.say(THROW_LINES.pick_random())
			var aim: Vector3 = target.global_position + Vector3.UP * (1.1 if is_player else 0.9)
			var start := g.global_position + Vector3.UP * 1.4 - g.global_basis.z * 0.3
			_throw(g, start, aim, THROW_TIME * clampf(start.distance_to(aim) / 3.0, 0.7, 1.6))
			if is_player:
				_check_player_hit.call_deferred(aim, g.global_position, THROW_TIME * clampf(start.distance_to(aim) / 3.0, 0.7, 1.6))
			if Game.tracing:
				print("[Grinch] %s wirft %s nach %s" % [g.display_name, item.display_name, "dir" if is_player else (target as Guest).display_name])
			return true
	if child:
		return false
	g.say(PUNCH_LINES.pick_random())
	if is_player:
		g.start_attack(10.0)   # wie ein Erzfeind (Social._update_feuds)
		if Game.tracing:
			print("[Grinch] %s geht auf dich los" % g.display_name)
		return true
	_job = {"kind": "punch", "target": target, "time": _time}
	g.start_visit(target.global_position)
	g.running = true
	if Game.tracing:
		print("[Grinch] %s geht auf %s los" % [g.display_name, (target as Guest).display_name])
	return true


## Was er werfen kann: zuerst etwas, das in Reichweite herumliegt, sonst aus seinem Koffer. null = nichts.
func _something_to_throw(g: Guest) -> Item:
	for node in get_tree().get_nodes_in_group("items"):
		var it := node as Item
		if it.kind in THROWABLE and not it.is_held and not it.hung and not Game.social.is_in_closed_chest(it) \
				and it.global_position.distance_to(g.global_position) < PICK_RANGE:
			return it
	for kind: Item.Kind in THROWABLE:
		if int(g.stock.get(kind, 0)) > 0:
			g.stock[kind] = int(g.stock[kind]) - 1
			return g.stock_item(kind)
	return null


## Wurf auf den Spieler: Er kollidiert nicht mit Geworfenem (Item.THROW_MASK) – trifft, wenn er beim Ankommen noch dort
## steht, wohin gezielt war.
func _check_player_hit(aim: Vector3, from: Vector3, time: float) -> void:
	await get_tree().create_timer(time, false).timeout
	var p := Game.player
	if p == null or p.dead or p.hiding:
		return
	if (p.global_position + Vector3.UP * 1.1).distance_to(aim) < PLAYER_HIT:
		p.hurt(PLAYER_INJURY, from)
		Game.say("Gustav Peters hat dich getroffen!", 3.0)


## Ein Wurf von ihm trifft einen Gast (Item._throw_hit): taumelt, ist mit ihm verfeindet; ein Kind weint, die Eltern auch.
func on_thrown_hit(g: Guest, victim: Guest, item: Item, velocity: Vector3) -> void:
	if victim.dead:
		return
	var push := Vector3(velocity.x, 0.0, velocity.z)
	victim.stagger(push.normalized() * minf(2.5, 0.25 * push.length() * sqrt(item.mass)), false)
	if victim.is_child():
		var parent := victim.parent_guest()
		if parent and not parent.dead:
			Game.social.pals.add_feud(g, parent)
			parent.say("Lassen Sie mein Kind in Ruhe!")
	else:
		Game.social.pals.add_feud(g, victim)


## Faustschlag gegen einen Gast: Er taumelt – zurückgeschlagen wird nicht (sonst ginge er auf dich los, Guest._after_stagger).
func _punch(g: Guest, target: Guest) -> void:
	_job = {}
	g.running = false
	g._face(target.global_position, 1.0)
	var dir := target.global_position - g.global_position
	dir.y = 0.0
	target.stagger(dir.normalized() * 3.5, true)
	target._hit_back = false
	Game.noise("punch", target.global_position, g)
	Game.social.pals.add_feud(g, target)
	g._set_idle(randf_range(3.0, 6.0))
	if Game.tracing:
		print("[Grinch] %s schlägt %s" % [g.display_name, target.display_name])


# --- Das Ende (Siegerehrung) ----------------------------------------------------------------------

## Das Monster holt ihn ungesehen (MonsterDirector.first_attack_unseen): Tür auf, Schleifspur von der Zimmermitte durch
## die Tür und 2 m den Flur hinunter Richtung Treppenhaus, dort endet sie – mit einem Kleidungsstück. Kein Schrei.
func taken(g: Guest) -> void:
	_job = {}
	if g.held:
		g._drop_held()
	var room: Dictionary = builder.rooms[String(g.home["no"])]
	var door: Door = room["door"]
	door.locked = false
	door.set_open(true, false, true)
	var along: Vector3 = room["along"]
	var front: Vector3 = room["door_front"]
	var stairs := builder.stairwell_point
	if stairs != Vector3.ZERO and (front + along).distance_to(stairs) > (front - along).distance_to(stairs):
		along = -along
	var c := door.center()
	var path := PackedVector3Array([g.home["center"], room["door_inside"], Vector3(c.x, front.y, c.z), front, front + along * 2.0])
	if Game.traces:
		Game.traces.add_drag_trail(path)
		Game.traces.add_guest_drop("drops", g.home["center"])
	var end: Vector3 = path[path.size() - 1]
	g.global_position = end
	g.die("monster")
	var cloth := Item.create(Item.Kind.CLOTHING, g.id)   # ein Hausschuh am Ende der Spur (6.7)
	Game.social._world.add_child(cloth)
	cloth.global_position = end + along * 0.3 + Vector3.UP * 0.05
	Game.social.on_guest_died(g, "unseen")


## Bis man Zimmer 020 gefunden hat: Gäste in der Nähe reden darüber. Wer hineingeht, schreibt es ins Tagebuch.
func _after_death() -> void:
	if Game.diary == null or Game.diary.has("first_death"):
		return
	var p := Game.player
	if p == null or p.dead:
		return
	var g := gustav
	if builder.room_at(p.global_position) == String(g.home["no"]):
		found()
		return
	_gossip -= SCAN
	if _gossip > 0.0 or Game.social.sleep_active:
		return
	for other in Game.social.living_guests():
		var o: Guest = other
		if o.state in [Guest.State.IDLE, Guest.State.WALK] and o.fear < 80.0 \
				and o.global_position.distance_to(p.global_position) < GOSSIP_RANGE and o.can_see_actor(p):
			o.say((AFTER_KID_LINES if o.is_child() else AFTER_LINES).pick_random())
			_gossip = GOSSIP_EVERY
			return


## Zimmer 020 gefunden (hineingegangen oder sein Tagebuch gelesen): ins Tagebuch des Spielers.
func found() -> void:
	if Game.diary and not Game.diary.has("first_death"):
		Game.diary.note("first_death", FOUND_ENTRY)
		if Game.tracing:
			print("[Grinch] Zimmer 020 gefunden")


## Text seines Tagebuchs, so weit er schon geschrieben ist.
func diary_text() -> String:
	var g := gustav
	var dead := g != null and g.dead
	var parts: Array[String] = []
	for e: Array in DIARY:
		if int(e[0]) < 0:
			if dead:
				parts.append(String(e[2]))
		elif dead or Game.director.elapsed >= Calendar.at(int(e[0]), float(e[1])):
			parts.append(String(e[2]))
	return "\n\n".join(parts) if not parts.is_empty() else "Noch leer."


## Gelesen: nach seinem Tod ins Notizbuch (3.10) – und Zimmer 020 gilt als gefunden.
func on_diary_read() -> void:
	var g := gustav
	if g == null or not g.dead:
		return
	found()
	if Game.notebook:
		Game.notebook.add_note("gustav_diary", DIARY_JOT, "Gustavs Tagebuch")


## Debug (--grinch[=tot]): Spieler vor Zimmer 020 mit Blick auf die Tür; tot: die Siegerehrung ist vorbei, Gustav geholt.
func debug(dead: bool) -> void:
	var g := gustav
	if g == null:
		push_warning("--grinch: kein Gustav Peters (Haushalt %s)" % HOUSEHOLD)
		return
	if dead:
		Game.director.first_attack_unseen(g)   # DoorContest schließt den Wettbewerb dann selbst ab
	var room: Dictionary = builder.rooms[String(g.home["no"])]
	var into: Vector3 = room["into"]
	TeleportUI.place_player((room["door_front"] as Vector3) - into * 1.2, into)
	if not dead:
		g.global_position = (room["door_front"] as Vector3) + (room["along"] as Vector3) * 1.5
		g._set_idle(1.0)


## Sein Tagebuch auf dem Tisch in Zimmer 020 (Spielkonzept 2.6): aufgeschlagen, liest man vor Ort (Menus.open_note);
## nach seinem Tod mit blutigen Fingerabdrücken. Fest, nicht tragbar.
class GustavDiary:
	extends StaticBody3D

	var grinch: Grinch
	var _prints: Node3D

	func _ready() -> void:
		collision_layer = 4
		collision_mask = 0
		set_meta("interactable", self)
		var cover := Mat.psx(Color(0.2, 0.17, 0.14))
		var paper := Mat.psx(Color(0.9, 0.87, 0.78))
		var ink := Mat.psx(Color(0.15, 0.13, 0.2))
		Geo.mesh(self, Geo.box(Vector3(0.3, 0.012, 0.21)), cover, Vector3(0, 0.006, 0))
		for side: float in [-1.0, 1.0]:
			var page := Geo.mesh(self, Geo.box(Vector3(0.14, 0.01, 0.2)), paper, Vector3(side * 0.072, 0.016, 0))
			page.rotation.z = -side * 0.04
			for i in 6:
				var short := side > 0.0 and i == 5
				Geo.mesh(self, Geo.box(Vector3(0.05 if short else 0.11, 0.002, 0.004)), ink,
					Vector3(side * 0.072 - (0.03 if short else 0.0), 0.022, -0.075 + i * 0.026))
		_prints = Node3D.new()
		add_child(_prints)
		var blood := Mat.psx(Color(0.4, 0.03, 0.03))
		for at: Vector2 in [Vector2(0.09, 0.07), Vector2(0.11, 0.05), Vector2(0.06, 0.085), Vector2(0.03, 0.06)]:
			var dot := Geo.mesh(_prints, Geo.box(Vector3(0.018, 0.002, 0.024)), blood, Vector3(at.x, 0.024, at.y))
			dot.rotation.y = at.x * 4.0
		Geo.add_box_shape(self, Vector3(0.32, 0.06, 0.24), Vector3(0, 0.03, 0))

	func _process(_delta: float) -> void:
		var g := grinch.gustav if grinch else null
		_prints.visible = g != null and g.dead

	func get_prompt(_player: Player) -> String:
		return "Gustavs Tagebuch lesen [E]"

	func interact(_player: Player) -> void:
		if Game.menus:
			Game.menus.open_note(DIARY_TITLE, grinch.diary_text())
		grinch.on_diary_read()
