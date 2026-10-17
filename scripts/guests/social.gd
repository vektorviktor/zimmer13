class_name Social
extends Node
## Das soziale Gefüge im Hotel (Spielkonzept 6 + 7.1): Gäste, Beziehungen, Gerüchte,
## Diebstahl (mit Zeugen), Panik, Tod & Schock, Gedenken und Feiern in der Lobby.
## Dazu (4.13): Gäste berichten von Spuren – nicht immer zuverlässig – und klopfen nachts
## an Zimmer 13. Manchmal klopft auch etwas anderes …

const PARTY_DURATION := 90.0
const PARTY_COOLDOWN := 240.0
## Klopfen an Zimmer 13
const KNOCK_COOLDOWN := Vector2(120.0, 240.0)
const KNOCK_WAIT := 10.0          ## so lange klopft es, bevor es still wird
const FAKE_KNOCK_CHANCE := 0.3
const HIDE_MONSTER_DISTANCE := 8.0  ## Verstecke so nah am Monster meiden Gäste
## Gäste: zum Start so viele, und nie dauerhaft weniger als MIN_GUESTS Lebende –
## nach einem Todesfall wacht irgendwann ein neuer Gast in einem freien Zimmer auf.
const START_GUESTS := 30
const MIN_GUESTS := 24
const ARRIVAL_DELAY := Vector2(150.0, 360.0)
const TRACE_TEXT := {
	"footprint": "nasse Fußspuren", "scratch": "Kratzspuren", "blood": "Blut",
	"handprint": "einen Handabdruck an einer Tür", "drops": "Blutstropfen",
}
## Gerüchte über Gehörtes (4.15): was man gehört hat, und wie man davon erzählt
const HEARD_TEXT := {
	"scream": "Jemand hat geschrien", "door_burst": "Eine Tür ist aufgeflogen, mit einem Knall",
	"hide_burst": "Ein Schrank ist aufgerissen worden", "bulb_burst": "Eine Glühbirne ist geplatzt",
	"cat_cry": "Eine Katze hat jämmerlich geweint",
}
const HEARD_LINES := [
	"Hast du das auch gehört? %s – bei %s.",
	"%s. Bei %s. Ich hab's genau gehört.",
	"Da war was. %s, irgendwo bei %s.",
]
## Zettel, die Gäste hinterlassen ({name}, {room}, {dead}, {zone})
const DEATH_NOTES := [
	"{dead} ist fort. Ich habe den Schrei gehört. Wer das liest: Bleibt nicht allein im Flur.\n– {name}",
	"Für {dead}. Wir zünden eine Kerze an, wenn es ruhig ist. Lobby.\n– {name}",
	"Es hat {dead} geholt. Ich schließe ab und mache nicht mehr auf. Für niemanden.\n– {name}, Zimmer {room}",
	"Klopft dreimal, wenn ihr es seid. Sonst bleibt die Tür zu.\n– {name}, Zimmer {room}",
	"Wer hat {dead} zuletzt gesehen? Bitte meldet euch. Zimmer {room}.\n– {name}",
]
const SIGHT_NOTES := [
	"Ich habe es gesehen. Hier. ({zone})\nKommt nicht allein hierher.\n– {name}",
	"Es stand am Ende des Flurs und hat mich angesehen. {zone}. Ich schwöre es.\n– {name}",
	"Nicht rennen. Nicht hinsehen. Verstecken.\n– {name}",
]
const DOOR_NOTES := [
	"Bitte nicht stören.\n– {name}",
	"Tausche Kerzen gegen Kürbisse. Einfach klopfen.\n– {name}, Zimmer {room}",
	"Wer meine Deko anfasst, bekommt Ärger.\n– {name}",
	"Bin in der Lobby. Oder an der Bar. Oder schlafe.\n– {name}",
	"Halloween-Feier? Ich bin dabei!\n– {name}, Zimmer {room}",
]
const MAX_GUEST_NOTES := 30
## Nachtruhe zu zufälligen Zeiten: alle Gäste schlafen eine Weile in ihren Betten, das Licht ist aus
## (Spielkonzept 4.18 – dann kommt der Lakengeist auch in den Flur). Abstand und Dauer in Sekunden.
const SLEEP_GAP := Vector2(240.0, 540.0)
const SLEEP_TIME := Vector2(70.0, 140.0)


var guests: Array[Guest] = []
var builder: LevelBuilder
var record_player: RecordPlayer
var party_active := false
var party_host := ""            ## "player" oder Gast-ID

var _party_time := 0.0
var _party_presence := 0.0
var _party_noise := 0.0
var _party_cooldown := 150.0
var _spontaneous_timer := 30.0
var _gossip: Array[Dictionary] = []      ## {delay, amount}
var _thefts := {}                        ## Gast-ID → Zeitpunkt des letzten Diebstahls durch den Spieler
var _reserved := {}                      ## HideSpot → Guest
var _memorial_doors: Array[Vector3] = []
var _check_timer := 0.0
var _time := 0.0
## Minispiele (Spielkonzept 6.10)
var _watched := {}                       ## Gast-ID → du kennst seine Ticks beim Bluffen
var _rematches: Array[Guest] = []
var _challenge_timer := 45.0
var _bar_game := {}                      ## laufende Partie zweier Gäste
var _bar_timer := 25.0
## Spuren, von denen die Gäste erzählen: {kind, zone, time}
var _reports: Array[Dictionary] = []
## Hotelkatzen (6.11): Gast-ID → Name der Katze, die ihm etwas weggetragen hat; ob schon eine geweint hat
var cat_thefts := {}
var cats_have_cried := false
var sleep_active := false
var sleep_timer := 300.0                 ## bis zur nächsten Nachtruhe bzw. bis zu ihrem Ende
## Klopfen an Zimmer 13: {guest, fake, time, opened}
var _knock: Dictionary = {}
var _knock_cooldown := 90.0
var debug_fake_knock := false
var _world: Node3D
var _arrival_timer := -1.0
var _next_guest := 1                     ## laufende Nummer für IDs erzeugter Gäste

const BAR_LINES := [
	"%s: „Zweiundsechzig!“ – %s: „Glaub ich dir nicht!“",
	"%s knallt den Becher auf den Tisch: „Mäxchen!“ – %s stöhnt.",
	"%s: „Aufdecken!“ – %s lacht laut.",
	"Würfel klappern. %s grinst %s herausfordernd an.",
	"%s: „Einundfünfzig …“ – %s zieht eine Augenbraue hoch.",
]


static func relation_word(value: float) -> String:
	if value >= 50.0:
		return "Freund"
	if value >= 15.0:
		return "freundlich"
	if value > -15.0:
		return "neutral"
	if value > -50.0:
		return "genervt"
	return "feindlich"


func setup(p_builder: LevelBuilder, world: Node3D) -> void:
	builder = p_builder
	_world = world
	GuestProfiles.generated.clear()
	for id in GuestProfiles.ALL:
		_spawn(id, true)
	while guests.size() < START_GUESTS:
		if _add_generated(randi(), "", false) == null:
			break
	# Manche Gäste haben schon einen Zettel an ihre Tür gelegt
	for guest in guests:
		if randf() < 0.25:
			_leave_note(guest, DOOR_NOTES, (guest.home["door_front"] as Vector3) + (guest.home["into"] as Vector3) * 0.35, "")
	record_player = RecordPlayer.new()
	record_player.position = builder.record_player_pos
	world.add_child(record_player)


## Gast ins Hotel setzen (Profil muss schon bekannt sein); mit Start-Deko vor der Tür.
func _spawn(id: String, with_deco: bool) -> Guest:
	var profile := GuestProfiles.get_profile(id)
	var info: Dictionary = builder.rooms[profile["room"]]
	info["kind"] = "guest"
	var guest := Guest.new().setup(id, info)
	guest.name = "Gast_" + id
	guest.position = (info["center"] as Vector3) + Vector3(0, 0.05, 0)
	_world.add_child(guest)
	guests.append(guest)
	if with_deco:
		for kind in profile["start_deco"]:
			var item := Item.create(kind)
			item.owner_id = id
			item.position = guest.deco_place_point() + Vector3(0, 0.02, 0)
			_world.add_child(item)
		guest.expected_deco = (profile["start_deco"] as Array).size()
	return guest


## Einen zufälligen Gast erzeugen. room = "": ein freies Zimmer wählen.
## arrived: neu aufgewacht (eigene Sätze, Licht geht sofort an). Beim Laden (restoring)
## bleibt das Licht, wie es ist – der Spielstand setzt die Schalter selbst.
func _add_generated(gen_seed: int, room: String, arrived: bool, id: String = "", restoring: bool = false) -> Guest:
	if room == "":
		room = _free_room()
		if room == "":
			return null
		# Jeder Name nur einmal im Hotel
		var taken := guests.map(func(g: Guest) -> String: return g.display_name)
		var tries := 0
		while GuestGenerator.name_for(gen_seed) in taken and tries < 60:
			gen_seed += 1
			tries += 1
	if id == "":
		id = "gast%d" % _next_guest
	_next_guest = maxi(_next_guest, int(id.trim_prefix("gast")) + 1)
	GuestProfiles.generated[id] = GuestGenerator.make(gen_seed, room, room if arrived else "")
	var guest := _spawn(id, true)
	guest.gen_seed = gen_seed
	guest.set_meta("arrived", arrived)
	var sw := LightSwitch.find(get_tree(), room)
	if sw and not restoring:
		if arrived:
			sw.set_on(true, true)
		else:
			sw.set_on.call_deferred(true, true)   # nach dem „Licht aus“ des LevelBuilders
	return guest


## Ein unbewohntes Zimmer (nie das eines Verschwundenen), möglichst weit weg vom Spieler.
func _free_room() -> String:
	var free: Array[String] = []
	for no in builder.rooms:
		if builder.rooms[no]["kind"] == "vacant":
			free.append(no)
	if free.is_empty():
		return ""
	free.shuffle()
	if Game.player:
		for no in free:
			var c: Vector3 = builder.rooms[no]["center"]
			if c.distance_to(Game.player.global_position) > 12.0 and not Game.director.player_can_see(c + Vector3.UP):
				return no
	return free[0]


## Nach Todesfällen: Ist das Hotel zu leer, taucht irgendwann jemand Neues auf.
func _update_arrivals(delta: float) -> void:
	if living_guests().size() >= MIN_GUESTS:
		_arrival_timer = -1.0
		return
	if _arrival_timer < 0.0:
		_arrival_timer = randf_range(ARRIVAL_DELAY.x, ARRIVAL_DELAY.y)
		return
	_arrival_timer -= delta
	if _arrival_timer > 0.0:
		return
	_arrival_timer = -1.0
	var guest := _add_generated(randi(), "", true)
	if guest:
		Game.say("Irgendwo im Hotel fällt eine Tür ins Schloss. In Zimmer %s brennt plötzlich Licht." % guest.home["no"], 5.0)


## Für Spielstände: die erzeugten Gäste (lebend und verschwunden) mit Seed und Zimmer.
func roster_state() -> Array:
	var list: Array = []
	for guest in guests:
		if guest.gen_seed >= 0:
			list.append({"id": guest.id, "seed": guest.gen_seed, "room": guest.home["no"], "arrived": bool(guest.get_meta("arrived", false))})
	return list


## Spielstand laden: erzeugte Gäste der frischen Partie durch die gespeicherten ersetzen.
func restore_roster(list: Array) -> void:
	for guest in guests.duplicate():
		if guest.gen_seed < 0:
			continue
		builder.rooms[guest.home["no"]]["kind"] = "vacant"
		GuestProfiles.generated.erase(guest.id)
		guests.erase(guest)
		guest.queue_free()
	_reserved.clear()
	for entry in list:
		var room := String(entry["room"])
		_add_generated(int(entry["seed"]), room, bool(entry.get("arrived", false)), String(entry["id"]), true)


## Ein Zettel eines Gastes (Spur der Gäste): an pos, Text aus templates.
func _leave_note(guest: Guest, templates: Array, pos: Vector3, dead: String) -> void:
	if Game.traces == null:
		return
	var notes := get_tree().get_nodes_in_group("guest_notes")
	if notes.size() >= MAX_GUEST_NOTES:
		notes[0].queue_free()
	var text := String(templates[randi() % templates.size()]).format({
		"name": guest.display_name, "room": guest.home["no"], "dead": dead,
		"zone": Game.director.zone_name_at(pos) if Game.director else "",
	})
	Game.traces.add_guest_note(pos + guest._jitter(0.3), "Zettel von %s" % guest.display_name, text)


func living_guests() -> Array:
	var list: Array = []
	for guest in guests:
		if not guest.dead:
			list.append(guest)
	return list


func guest_by_id(id: String) -> Guest:
	for guest in guests:
		if guest.id == id:
			return guest
	return null


func guest_name(id: String) -> String:
	var guest := guest_by_id(id)
	return guest.display_name if guest else id


func change_relation(guest: Guest, amount: float) -> void:
	guest.relation = clampf(guest.relation + amount, -100.0, 100.0)


# --- Diebstahl & Gerüchte ----------------------------------------------------------

## Der Spieler nimmt Deko, die einem Gast gehört. Haben es Gäste gesehen?
func on_player_took(item: Item) -> void:
	var owner_guest := guest_by_id(item.owner_id)
	if owner_guest == null or owner_guest.dead:
		return
	_thefts[owner_guest.id] = _time
	var witnesses: Array[Guest] = []
	for guest in guests:
		if guest.can_see_actor(Game.player):
			witnesses.append(guest)
	if witnesses.is_empty():
		return   # unbemerkt – der Besitzer merkt es später an seiner Tür
	if owner_guest in witnesses:
		change_relation(owner_guest, -35.0)
		owner_guest.say(owner_guest.line("caught"))
		owner_guest.expected_deco = maxi(0, owner_guest.expected_deco - 1)
	else:
		change_relation(owner_guest, -15.0)
		var witness: Guest = witnesses[0]
		witness.say("Ich hab genau gesehen, wie du %s' Sachen genommen hast!" % owner_guest.display_name)
	for witness in witnesses:
		if witness != owner_guest:
			change_relation(witness, -10.0)
	var involved: Array = [owner_guest]
	involved.append_array(witnesses)
	_spread_gossip(-8.0, involved)


## Ein Gast merkt, dass Deko vor seiner Tür fehlt.
## Plauderei über die Hotelkatzen (Spielkonzept 6.11) – Lieblingsgast, Diebin oder einfach so.
func cat_line(guest: Guest) -> String:
	var cats := get_tree().get_nodes_in_group("cats")
	if cats.is_empty():
		return ""
	if cat_thefts.has(guest.id):
		var thief: String = cat_thefts[guest.id]
		cat_thefts.erase(guest.id)
		return "%s hat mir meine Deko weggeschleppt! Ich dachte erst, das warst du." % thief
	for cat in cats:
		if cat.favourite == guest.id:
			return (["%s läuft mir den ganzen Tag hinterher.", "%s schläft ständig auf meinem Bett. Ich hab's aufgegeben.",
				"Ohne %s würde ich hier verrückt werden."] as Array).pick_random() % cat.display_name
	var any = cats.pick_random()
	return (["Hast du %s heute schon gesehen?", "%s hat mir eine Kerze umgeworfen. Frechheit.",
		"Die Katzen haben es hier besser als wir. %s schläft einfach überall.",
		"Neulich hat %s vor meiner Tür miaut, bis ich aufgemacht habe."] as Array).pick_random() % any.display_name


## Nach dem ersten Weinen einer Katze wissen die Gäste: Die Katzen spüren es zuerst.
func cat_monster_line() -> String:
	if not cats_have_cried:
		return ""
	return (["Die Katzen spüren es. Wenn sie weinen, ist es in der Nähe.",
		"Hör auf die Katzen. Wenn sie jammern und rennen, renn auch.",
		"Es tut den Katzen nichts. Aber sie haben trotzdem Angst vor ihm."] as Array).pick_random()


func on_guest_noticed_missing(guest: Guest, count: int) -> void:
	change_relation(guest, -5.0 * count)
	guest.say(guest.line("missing"))


## Ein Gast merkt, dass in seinem Zimmer eine Glühbirne fehlt.
func on_guest_noticed_missing_bulb(guest: Guest) -> void:
	change_relation(guest, -5.0)
	guest.say("Wer hat meine Glühbirne herausgedreht?! Das warst doch du …")


func on_guest_stole_bulb(guest: Guest, lamp: Lamp, room_id: String) -> void:
	if room_id == "13" and Game.player and Game.director.player_can_see(lamp.global_position) \
			and Game.player.global_position.distance_to(guest.global_position) < 15.0:
		Game.say("%s dreht deine Glühbirne heraus!" % guest.display_name, 4.0)


func on_guest_stole(guest: Guest, item: Item, victim: String) -> void:
	if victim == "player" and Game.player and Game.director.player_can_see(guest.global_position + Vector3.UP * 1.4) \
			and Game.player.global_position.distance_to(guest.global_position) < 15.0:
		Game.say("%s klaut deine Deko (%s)!" % [guest.display_name, item.display_name], 4.0)


func on_insult(guest: Guest) -> void:
	_spread_gossip(-3.0, [guest])


## Gerüchte verbreiten sich zeitversetzt – je nach Tratschfreude der Gäste.
func _spread_gossip(amount: float, exclude: Array) -> void:
	for guest in guests:
		if guest.dead or guest in exclude:
			continue
		_gossip.append({"guest": guest, "amount": amount * float(guest.profile["gossip"]), "delay": randf_range(15.0, 40.0)})


# --- Monster, Tod, Schock ---------------------------------------------------------------

func on_guest_saw_monster(guest: Guest) -> void:
	guest.say_panic()
	if randf() < 0.08:
		_leave_note(guest, SIGHT_NOTES, guest.global_position, "")


## Über das Monster reden: hilfreich – aber es hört mit (Spielkonzept 4.7).
func on_monster_talk(guest: Guest) -> void:
	Game.director.on_monster_talk(guest.global_position)


func on_guest_died(guest: Guest) -> void:
	for other in living_guests():
		other.fear = minf(100.0, other.fear + 50.0)
	Game.say("Ein Schrei hallt durch das Hotel …", 4.0)
	get_tree().create_timer(5.0).timeout.connect(func() -> void:
		Game.say("%s ist verschwunden." % guest.display_name, 4.0))
	_memorial_doors.append(guest.home["door_front"])
	# Ein, zwei Gäste schreiben einen Zettel und legen ihn vor ihre Tür
	var writers := living_guests()
	writers.shuffle()
	for writer in writers.slice(0, randi_range(1, 2)):
		var w: Guest = writer
		get_tree().create_timer(randf_range(20.0, 60.0)).timeout.connect(func() -> void:
			if is_instance_valid(w) and not w.dead:
				_leave_note(w, DEATH_NOTES, w.home["door_front"], guest.display_name))
	SaveManager.request_autosave("Tod eines Gastes")
	if party_active and party_host == guest.id:
		end_party("")
	# Schock, wenn es ein Freund war – stärker, wenn man ihn vorher bestohlen hat (Schuld)
	if guest.relation >= 50.0 and Game.player:
		var guilt := _thefts.has(guest.id) and _time - float(_thefts[guest.id]) < 600.0
		var amount := clampf(guest.relation / 100.0, 0.5, 1.0) * (1.5 if guilt else 1.0)
		Game.player.add_shock(amount, guilt)


func find_hide_spot(guest: Guest) -> HideSpot:
	var best: HideSpot = null
	var best_score := INF
	var own_spots: Array = guest.home["spots"]
	for node in get_tree().get_nodes_in_group("hide_spots"):
		var spot := node as HideSpot
		if spot.occupant != null or (_reserved.has(spot) and _reserved[spot] != guest):
			continue
		var d := guest.global_position.distance_to(spot.global_position)
		if d > 25.0:
			continue
		# Nicht direkt vor dem Monster hineinklettern – es sähe ihn und reißt die Tür gleich wieder auf
		if Game.monster.is_active() and Game.monster.global_position.distance_to(spot.global_position) < HIDE_MONSTER_DISTANCE:
			continue
		var score := d - (6.0 if spot in own_spots else 0.0)
		if score < best_score:
			best_score = score
			best = spot
	if best:
		_reserved[best] = guest
	return best


func release_hide_spot(spot: HideSpot) -> void:
	_reserved.erase(spot)


func is_in_closed_chest(item: Item) -> bool:
	for node in get_tree().get_nodes_in_group("chests"):
		var chest := node as Chest
		if not chest.is_open and chest.global_position.distance_to(item.global_position) < 0.6:
			return true
	return false


# --- Feiern ---------------------------------------------------------------------------

## Wie lange läuft die Feier schon?
func party_age() -> float:
	return PARTY_DURATION - _party_time if party_active else 0.0


func party_center() -> Vector3:
	return Vector3(-4.0, 0, 0)


func free_party_spot() -> Vector3:
	var spots := builder.party_spots
	return spots[randi() % spots.size()]


func start_party(host: String) -> bool:
	if party_active:
		return false
	if not Game.director.is_quiet(party_center(), 25.0):
		Game.say("Jetzt nicht – es ist zu unruhig im Hotel.")
		return false
	party_active = true
	party_host = host
	_party_time = PARTY_DURATION
	_party_presence = 0.0
	_party_noise = 0.0
	record_player.set_playing(true)
	var spots := builder.party_spots.duplicate()
	spots.shuffle()
	var coming: Array[String] = []
	for guest in living_guests():
		var comes := false
		if host == "player":
			comes = guest.invited or guest.relation >= 40.0
		else:
			comes = guest.id == host or randf() < 0.75
		if comes and guest.fear < 60.0 and guest.state != Guest.State.TALKING:
			guest.invited = true
			guest.join_party(spots[coming.size() % spots.size()])
			coming.append(guest.display_name)
	if host == "player":
		if coming.is_empty():
			Game.say("Die Musik spielt … aber niemand kommt.", 4.0)
		else:
			Game.say("Feier in der Lobby! Es kommen: %s" % ", ".join(coming), 4.0)
	else:
		Game.say("Aus der Lobby klingt Musik – %s feiert." % guest_name(host), 4.0)
	return true


## Nachtruhe: beginnt zu zufälligen Zeiten (nie mitten in einer Feier) und endet nach einer Weile.
func _update_sleep(delta: float) -> void:
	sleep_timer -= delta
	if sleep_timer > 0.0:
		return
	if sleep_active:
		sleep_active = false
		sleep_timer = randf_range(SLEEP_GAP.x, SLEEP_GAP.y)
		for guest in living_guests():
			guest.wake_up()
		Game.say("Türen gehen auf, Schritte im Flur – die Gäste sind wieder wach.", 3.5)
	elif party_active:
		sleep_timer = 20.0
	else:
		start_sleep()


## instant (Debug): alle liegen sofort im Bett.
func start_sleep(instant: bool = false) -> void:
	sleep_active = true
	sleep_timer = randf_range(SLEEP_TIME.x, SLEEP_TIME.y)
	for guest in living_guests():
		guest.bedtime(instant)
	Game.say("Im Hotel wird es still – die Gäste gehen schlafen.", 3.5)
	if "--trace" in OS.get_cmdline_user_args():
		print("[Nachtruhe] für %d s" % int(sleep_timer))


## Schlafen alle lebenden Gäste gerade?
func all_asleep() -> bool:
	if not sleep_active:
		return false
	for guest in living_guests():
		if not guest.is_asleep():
			return false
	return true


func end_party(message: String) -> void:
	if not party_active:
		return
	party_active = false
	record_player.set_playing(false)
	var present := _party_presence / PARTY_DURATION >= 0.4
	for guest in living_guests():
		if guest.state == Guest.State.PARTY:
			guest.fear = maxf(0.0, guest.fear - 40.0)
			if present:
				change_relation(guest, 10.0)
		guest.leave_party()
	if present and Game.player:
		Game.player.shock = maxf(0.0, Game.player.shock - 0.3)
	_party_cooldown = PARTY_COOLDOWN
	if message != "":
		Game.say(message, 3.5)
	SaveManager.request_autosave("Ende einer Feier")


func _update_party(delta: float) -> void:
	if party_active:
		_party_time -= delta
		var p := Game.player
		if p and p.global_position.x < 0.0 and absf(p.global_position.z) < 7.0:
			_party_presence += delta
		# Musik ist laut – das Monster wird neugierig auf die Lobby
		_party_noise -= delta
		if _party_noise <= 0.0:
			_party_noise = 8.0
			Game.noise("party", party_center())
		if not Game.director.is_quiet(party_center(), 22.0):
			end_party("Die Musik verstummt abrupt.")
		elif _party_time <= 0.0:
			end_party("Die Feier ist vorbei.")
		return
	_party_cooldown -= delta
	_spontaneous_timer -= delta
	if _spontaneous_timer > 0.0:
		return
	_spontaneous_timer = 30.0
	var alive := living_guests()
	# Der erste Angriff passiert bei einer Feier (Spielkonzept 2.1): an diesem Tag lädt jemand ein
	if Game.director.wants_first_attack_party() and alive.size() >= 1:
		var party_host_guest: Guest = alive[randi() % alive.size()]
		start_party(party_host_guest.id)
		return
	if _party_cooldown > 0.0 or alive.size() < 2 or not Game.director.is_quiet(party_center(), 30.0):
		return
	var total_fear := 0.0
	for guest in alive:
		total_fear += guest.fear
	if total_fear / alive.size() < 35.0 and randf() < 0.15:
		var host: Guest = alive[randi() % alive.size()]
		start_party(host.id)


# --- Minispiele -------------------------------------------------------------------------

func has_watched(guest: Guest) -> bool:
	return _watched.has(guest.id)


func on_cheat_caught(guest: Guest) -> void:
	_spread_gossip(-10.0, [guest])


func queue_rematch(guest: Guest) -> void:
	if not guest in _rematches:
		_rematches.append(guest)


func challenge(guest: Guest) -> void:
	guest.challenge_time = 30.0
	guest.challenge_cooldown = 240.0
	guest.say(guest.line("challenge"))


func on_challenge_ignored(guest: Guest) -> void:
	if Game.player and Game.player.global_position.distance_to(guest.global_position) < 15.0:
		change_relation(guest, -2.0)
		guest.say("Pff. Dann eben nicht.")


## Gäste fordern dich heraus: Revanche nach einer Niederlage oder einfach aus Spaß.
func _update_challenges(delta: float) -> void:
	_challenge_timer -= delta
	if _challenge_timer > 0.0:
		return
	_challenge_timer = 20.0
	var p := Game.player
	if p == null or p.in_dialog or (Game.dice and Game.dice.active) or not Game.director.is_quiet(p.global_position, 25.0):
		return
	for guest in living_guests():
		var g: Guest = guest
		if g.challenge_cooldown > 0.0 or g.challenge_time > 0.0 or g.fear >= 40.0:
			continue
		if not (g.state == Guest.State.IDLE or g.state == Guest.State.WALK):
			continue
		if g.global_position.distance_to(p.global_position) > 6.0:
			continue
		if g in _rematches:
			_rematches.erase(g)
			challenge(g)
			return
		var dice: Dictionary = g.profile["dice"]
		if dice["likes"] and g.relation >= 30.0 and randf() < 0.25:
			challenge(g)
			return


## Gäste würfeln auch untereinander – Zuschauen verrät ihre Ticks beim Bluffen.
func _update_bar_game(delta: float) -> void:
	var table := builder.game_table
	if _bar_game.is_empty():
		_bar_timer -= delta
		if _bar_timer > 0.0:
			return
		_bar_timer = 20.0
		if table.busy or not table.has_cup(null) or not Game.director.is_quiet(table.global_position, 25.0):
			return
		var free: Array = []
		for guest in living_guests():
			var g: Guest = guest
			if g.state == Guest.State.IDLE and g.fear < 40.0 and not g.invited:
				free.append(g)
		if free.size() < 2 or randf() > 0.35:
			return
		free.shuffle()
		var a: Guest = free[0]
		var b: Guest = free[1]
		table.busy = true
		a.sit_for_game(table.player_seat.global_position, table.top_center())
		b.sit_for_game(table.guest_seat.global_position, table.top_center())
		_bar_game = {"a": a, "b": b, "time": 0.0, "noise": 0.0, "watch": 0.0}
		return
	var ga: Guest = _bar_game["a"]
	var gb: Guest = _bar_game["b"]
	if ga.dead or gb.dead or ga.state != Guest.State.MINIGAME or gb.state != Guest.State.MINIGAME \
			or not Game.director.is_quiet(table.global_position, 22.0):
		_end_bar_game(false)
		return
	if not (ga.seated and gb.seated):
		return
	_bar_game["time"] = float(_bar_game["time"]) + delta
	var dist := Game.player.global_position.distance_to(table.global_position) if Game.player else INF
	if dist < 5.0:
		_bar_game["watch"] = float(_bar_game["watch"]) + delta
	_bar_game["noise"] = float(_bar_game["noise"]) - delta
	if float(_bar_game["noise"]) <= 0.0:
		_bar_game["noise"] = 7.0
		Game.noise("dice", table.global_position)
		if dist < 7.0:
			var pair := [ga.display_name, gb.display_name]
			pair.shuffle()
			Game.say(String(BAR_LINES[randi() % BAR_LINES.size()]) % pair, 3.0)
	if float(_bar_game["time"]) > 45.0:
		_end_bar_game(true)


func _end_bar_game(completed: bool) -> void:
	var ga: Guest = _bar_game["a"]
	var gb: Guest = _bar_game["b"]
	if completed:
		var winner := ga if randf() < 0.5 else gb
		var loser := gb if winner == ga else ga
		if Game.player and Game.player.global_position.distance_to(builder.game_table.global_position) < 7.0:
			Game.say("%s gewinnt beim Würfeln gegen %s." % [winner.display_name, loser.display_name], 3.5)
		if float(_bar_game["watch"]) > 25.0 and not (has_watched(ga) and has_watched(gb)):
			_watched[ga.id] = true
			_watched[gb.id] = true
			Game.say("Du hast genau hingesehen: Jetzt kennst du die Ticks von %s und %s beim Bluffen." % [ga.display_name, gb.display_name], 4.5)
	for g in [ga, gb]:
		if not g.dead:
			g.end_game()
	builder.game_table.busy = false
	_bar_game = {}


# --- Laufend ----------------------------------------------------------------------------

func _process(delta: float) -> void:
	_time += delta
	var i := _gossip.size() - 1
	while i >= 0:
		var entry := _gossip[i]
		entry["delay"] = float(entry["delay"]) - delta
		if float(entry["delay"]) <= 0.0:
			var guest: Guest = entry["guest"]
			if not guest.dead:
				change_relation(guest, entry["amount"])
			_gossip.remove_at(i)
		i -= 1
	_update_party(delta)
	_update_arrivals(delta)
	_update_knocking(delta)
	_update_bar_game(delta)
	_update_challenges(delta)
	_update_sleep(delta)
	_check_timer -= delta
	if _check_timer <= 0.0:
		_check_timer = 2.0
		_update_memorials()
	if Game.audio and record_player:
		var target := 0.0
		if record_player.playing and Game.player:
			var d := record_player.global_position.distance_to(Game.player.global_position)
			target = clampf(1.0 - d / 30.0, 0.08, 1.0) * 0.6
		Game.audio.music = move_toward(Game.audio.music, target, delta)


## Gedenken: Brennt ein Licht vor der Tür eines verschwundenen Freundes, heilt der Schock schneller.
func _update_memorials() -> void:
	var p := Game.player
	if p == null:
		return
	var mult := 1.0
	for door_front in _memorial_doors:
		for node in get_tree().get_nodes_in_group("items"):
			var item := node as Item
			if item.lit and not item.is_held and item.global_position.distance_to(door_front) < 2.5:
				mult = 3.0
	if party_active and p.global_position.x < 0.0:
		mult = maxf(mult, 2.0)
	p.shock_recovery = mult



# --- Spuren & Berichte (Spielkonzept 4.13) -----------------------------------------------------

## Ein erschreckendes Geräusch (Spielkonzept 4.15): Gäste hören mit halber Reichweite,
## gedämpft durch Wände und Türen. Gibt die Reaktionen zurück (Debug).
func on_alarm(kind: String, pos: Vector3, loudness: float, source: Node) -> Array[String]:
	var result: Array[String] = []
	var reach := loudness * Senses.GUEST_HEARING
	var told := false
	for guest in guests:
		if guest == source or guest.dead or guest.hiding:
			continue
		var ear := guest.global_position + Vector3.UP * 1.5
		var d := ear.distance_to(pos)
		if d > reach or d > Senses.audible_range(guest.get_world_3d(), pos, ear, reach, d):
			continue
		var reaction := guest.hear_alarm(pos)
		if reaction == "":
			continue
		result.append("%s %s" % [guest.display_name, reaction])
		if reaction == "erzählt davon" and not told:
			told = true
			_reports.append({"kind": kind, "heard": true, "zone": Game.director.zone_name_at(pos), "time": _time})
			if _reports.size() > 12:
				_reports.pop_front()
	return result


func note_trace(kind: String, pos: Vector3) -> void:
	_reports.append({"kind": kind, "zone": Game.director.zone_name_at(pos), "time": _time})
	if _reports.size() > 12:
		_reports.pop_front()


## Was ein Gast über Spuren erzählt – je nach Persönlichkeit zuverlässig oder nicht.
## Leer, wenn es nichts zu berichten gibt.
func report_line(guest: Guest) -> String:
	var recent: Array[Dictionary] = []
	for r in _reports:
		if _time - float(r["time"]) < 600.0:
			recent.append(r)
	if recent.is_empty():
		return ""
	var r: Dictionary = recent[randi() % recent.size()]
	var zone: String = r["zone"]
	if r.get("heard", false):
		var heard: String = HEARD_TEXT.get(r["kind"], "Ein lautes Geräusch")
		if randf() > float(guest.profile.get("reliable", 0.7)):
			var zone_names: Array = Game.director.zones.map(func(z: Dictionary) -> String: return z["name"])
			zone = zone_names[randi() % zone_names.size()]
		return HEARD_LINES[randi() % HEARD_LINES.size()] % [heard, zone]
	var what: String = TRACE_TEXT.get(r["kind"], "etwas Seltsames")
	if randf() > float(guest.profile.get("reliable", 0.7)):
		# Falsch erinnert, erfunden oder übertrieben
		var names: Array = Game.director.zones.map(func(z: Dictionary) -> String: return z["name"])
		zone = names[randi() % names.size()]
		what = TRACE_TEXT.values()[randi() % TRACE_TEXT.size()]
	var template: String = guest.profile.get("report", "Ich habe %s gesehen. %s.")
	return template % [what, zone]


# --- Klopfen an Zimmer 13 -----------------------------------------------------------------------

func is_knocking() -> bool:
	return not _knock.is_empty()


## Meistens ein echter Gast in Panik („Mach auf!“) – manchmal nicht (bekannte Stimme,
## aber draußen ist niemand, nur ein Kleidungsstück).
func _update_knocking(delta: float) -> void:
	if not _knock.is_empty():
		_knock_step(delta)
		return
	_knock_cooldown -= delta
	var director := Game.director
	var p := Game.player
	if _knock_cooldown > 0.0 or not director.first_attack_done or p == null or p.dead:
		return
	var door: Door = builder.rooms["13"]["door"]
	if door.is_open or director.zone_name_at(p.global_position) != "Zimmer 13":
		return
	if not Game.monster.is_active() or Game.monster.global_position.distance_to(door.center()) > 28.0:
		return
	_knock_cooldown = randf_range(KNOCK_COOLDOWN.x, KNOCK_COOLDOWN.y)
	var fake := debug_fake_knock or randf() < FAKE_KNOCK_CHANCE
	var guest: Guest = null
	if not fake:
		# auch Versteckte: Sie halten es nicht mehr aus und rennen zu deiner Tür
		var candidates: Array = living_guests().filter(func(g: Guest) -> bool:
			return not g.state in [Guest.State.TALKING, Guest.State.MINIGAME, Guest.State.KNOCK, Guest.State.SHELTER])
		if candidates.is_empty():
			fake = true
		else:
			guest = candidates[randi() % candidates.size()]
	if fake:
		# Am liebsten die Stimme eines Verschwundenen – sonst die eines Gastes (der woanders ist)
		var voices: Array = guests.filter(func(g: Guest) -> bool: return g.dead)
		if voices.is_empty():
			voices = guests.duplicate()
		guest = voices[randi() % voices.size()]
	_knock = {"guest": guest, "fake": fake, "time": 0.0, "next": 0.0, "said": 0}
	if not fake:
		guest.start_knock(builder.rooms["13"]["door_front"])


func _knock_step(delta: float) -> void:
	var guest: Guest = _knock["guest"]
	var fake: bool = _knock["fake"]
	var door: Door = builder.rooms["13"]["door"]
	_knock["time"] = float(_knock["time"]) + delta
	var t := float(_knock["time"])
	if not fake and (guest.dead or guest.state != Guest.State.KNOCK):
		_knock = {}
		return
	if door.is_open:
		if door.opened_by_monster:
			_knock_ignored(guest, fake)   # nicht der Spieler hat aufgemacht – es war schneller
		else:
			_knock_answered(guest, fake)
		return
	if t >= KNOCK_WAIT:
		_knock_ignored(guest, fake)
		return
	_knock["next"] = float(_knock["next"]) - delta
	if float(_knock["next"]) <= 0.0:
		_knock["next"] = randf_range(1.0, 1.6) if not fake else 2.4
		Game.noise("knock", builder.rooms["13"]["door_front"], guest)
		Game.caption("[Es klopft an deiner Tür]")
	var said := int(_knock["said"])
	if fake and said == 0 and t > 1.5:
		_knock["said"] = 1
		Game.say("%s: „Ich bin's … mach bitte auf.“" % guest.display_name, 4.0)
	elif not fake and said < 2 and t > 0.8 + said * 4.0:
		_knock["said"] = said + 1
		Game.say("%s: „%s“" % [guest.display_name, guest.line("knock")], 3.5)
		if said == 1:
			# Das Geschrei lockt es an – jetzt bleibt nicht mehr viel Zeit
			Game.noise("scream", guest.global_position, guest)


func _knock_answered(guest: Guest, fake: bool) -> void:
	_knock = {}
	var front: Vector3 = builder.rooms["13"]["door_front"]
	if fake:
		# Niemand da. Nur ein Kleidungsstück auf dem Boden.
		var cloth := Item.create(Item.Kind.CLOTHING, guest.id)
		get_parent().add_child(cloth)
		cloth.global_position = front + Vector3(0, 0.02, -0.2)
		Game.play_sound("sting", 0.6)
		Game.say("Draußen ist niemand.", 3.0)
		Game.director.add_curiosity(front, 30.0)
		if Game.monster.is_active():
			Game.monster.investigate(front)
		return
	guest.enter_shelter(builder.rooms["13"]["center"])
	change_relation(guest, 15.0)
	guest.say(guest.line("sheltered"))


func _knock_ignored(guest: Guest, fake: bool) -> void:
	_knock = {}
	if fake:
		# Stille. Später findet man Kratzspuren an der Tür.
		if Game.traces:
			Game.traces.add_door_scratch(builder.rooms["13"]["door"], builder.rooms["13"]["door_front"] + Vector3(0, 0, -1.0))
		return
	Game.noise("scream", guest.global_position, guest)
	if Game.director.is_harmless() or randf() < 0.5:
		guest.scared_by_monster()
		change_relation(guest, -20.0)
		get_tree().create_timer(4.0, false).timeout.connect(func() -> void:
			if not guest.dead:
				guest.say(guest.line("left_outside")))
	else:
		Game.monster.spawn_near_unseen(guest.global_position)
		Game.director.kill_guest(guest, null)
