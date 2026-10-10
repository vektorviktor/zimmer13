class_name Social
extends Node
## Das soziale Gefüge im Hotel (Spielkonzept 6 + 7.1): Gäste, Beziehungen, Gerüchte,
## Diebstahl (mit Zeugen), Panik, Tod & Schock, Gedenken und Feiern in der Lobby.

const PARTY_DURATION := 90.0
const PARTY_COOLDOWN := 240.0

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
	for id in GuestProfiles.ALL:
		var profile: Dictionary = GuestProfiles.ALL[id]
		var info: Dictionary = builder.rooms[profile["room"]]
		var guest := Guest.new().setup(id, info)
		guest.name = "Gast_" + String(id)
		guest.position = (info["center"] as Vector3) + Vector3(0, 0.05, 0)
		world.add_child(guest)
		guests.append(guest)
		# Start-Deko vor der Tür
		for kind in profile["start_deco"]:
			var item := Item.create(kind)
			item.owner_id = id
			item.position = guest.deco_place_point() + Vector3(0, 0.02, 0)
			world.add_child(item)
		guest.expected_deco = (profile["start_deco"] as Array).size()
	record_player = RecordPlayer.new()
	record_player.position = builder.record_player_pos
	world.add_child(record_player)


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
	var head := Game.player.camera.global_position
	var witnesses: Array[Guest] = []
	for guest in guests:
		if guest.can_see_point(head):
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
func on_guest_noticed_missing(guest: Guest, count: int) -> void:
	change_relation(guest, -5.0 * count)
	guest.say(guest.line("missing"))


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
	guest.say(guest.line("panic"))


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

func party_center() -> Vector3:
	return Vector3(-4.0, 0, 0)


func free_party_spot() -> Vector3:
	var spots := builder.party_spots
	return spots[randi() % spots.size()]


func start_party(host: String) -> bool:
	if party_active:
		return false
	if Game.director.phase != MonsterDirector.Phase.CALM:
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
			Game.director.on_noise(party_center(), 1.5)
		if Game.director.phase != MonsterDirector.Phase.CALM:
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
	if _party_cooldown > 0.0 or alive.size() < 2 or Game.director.phase != MonsterDirector.Phase.CALM:
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
	if p == null or p.in_dialog or (Game.dice and Game.dice.active) or Game.director.phase != MonsterDirector.Phase.CALM:
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
		if table.busy or not table.has_cup(null) or Game.director.phase != MonsterDirector.Phase.CALM:
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
			or Game.director.phase != MonsterDirector.Phase.CALM:
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
		Game.director.on_noise(table.global_position, 0.7)
		Game.play_sound("thud", 0.25 if dist < 7.0 else 0.05)
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
	_update_bar_game(delta)
	_update_challenges(delta)
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
