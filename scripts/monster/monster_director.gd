class_name MonsterDirector
extends Node
## Steuert das Monster über versteckte Werte (Spielkonzept 4.9):
##   Dreistigkeit (global) · Neugier (pro Zone) · Abschreckung (Deko × Licht / Anspruch)
##   Druck(Ort) = Dreistigkeit × (0,5 + 0,5 × Neugier/100)
##   Druck > Abschreckung → das Monster kommt durch.
##
## Dramaturgie (Spielkonzept 2.1, 4.13):
##   · Friedlicher Anfang – bis zum ersten Angriff (3./4. Oktober, bei einer Feier) kein Monster.
##   · Danach streift es im ganzen Hotel umher, abwechselnd mit Ruhephasen im Keller;
##     anfangs lange Pausen, mit jedem Tag kürzere.
##   · Die ersten Angriffe sind harmlos: es holt niemanden, es zeigt sich nur.
##   · Rauschen nach Entfernung (ab ~20 m, lauter bis ~4 m), Lampen flackern nur in seiner Nähe.
##   · Halluzinationen nach einem Todesfall, kleine Veränderungen im Hotel, wenn niemand hinsieht.

## CALM = ruht im Keller, ACTIVE = streift umher. WARNING/COOLDOWN gibt es nicht mehr
## (nur noch für alte Spielstände/Abfragen vorhanden).
enum Phase { CALM, WARNING, ACTIVE, COOLDOWN }

# --- Tuning -------------------------------------------------------------------
const BOLDNESS_START := 25.0
const BOLDNESS_PER_SECOND := 0.04      ## ≈ +2,4 pro Minute
const DEMAND_GROWTH_SECONDS := 900.0   ## Anspruch an Deko: +100 % alle 15 min
const DECO_RADIUS := 3.0
const LIGHT_DETERRENCE := 12.0
const CHASE_BONUS := 12.0
const MOONLIGHT := 0.3                 ## Helligkeit direkt am offenen Außenfenster
const MOONLIGHT_RANGE := 5.0
const LIGHTS_OFF_CURIOSITY := 30.0     ## Licht aus = das Monster kommt (4.4)
## Rauschen nach Entfernung zum Spieler (auch durch Wände)
const NOISE_START := 20.0
const NOISE_FULL := 4.0
## Lampen flackern nur in der Nähe des Monsters
const LAMP_FLICKER_RANGE := 9.0
## Erster Angriff: am 3. oder 4. Oktober, nach so vielen Sekunden einer Feier
const FIRST_ATTACK_DAYS := [3, 4]
const FIRST_ATTACK_PARTY_TIME := 25.0
const FALLBACK_ATTACK_DAY := 5         ## spätestens jetzt – auch ohne Feier
## So viele Angriffe (Aktivphasen) holt es niemanden
const HARMLESS_ATTACKS := 2
## Ruhe- und Aktivphasen in Sekunden: am 1. Oktober → an Halloween
const REST_TIME := Vector2(150.0, 35.0)
const ACTIVE_TIME := Vector2(70.0, 210.0)
## Kleine Veränderungen im Hotel (Sekunden zwischen zwei Ereignissen)
const HAUNT_INTERVAL := Vector2(80.0, 170.0)
## Halluzination: mittlere Sekunden zwischen zwei Rausch-Anfällen nach einem Todesfall
const HALLUCINATION_EVERY := 70.0
const GRIEF_TIME := 900.0

var phase := Phase.CALM
var boldness := BOLDNESS_START
var boldness_dip := 0.0     ## vorübergehend weniger dreist (abgewiesen)
var satiation := 0.0        ## gesättigt, nachdem es einen Gast geholt hat (4.10)
var elapsed := 0.0
var zones: Array[Dictionary] = []
var spawn_points: Array[Vector3] = []
var patrol: Array[Dictionary] = []
var rooms := {}
var player_door_front := Vector3.ZERO
var post_material: ShaderMaterial
## Dramaturgie
var first_attack_done := false
var first_attack_day := 3
var attacks := 0            ## Aktivphasen seit dem ersten Angriff
var grief := 0.0            ## Sekunden „Trauerzeit“ nach einem Todesfall → Halluzinationen
var strange_diary := false  ## im Tagebuch steht beim nächsten Mal eine fremde Zeile
## Bedrohung beim Spieler (0..1) – Rauschen, Brummen, engerer Blick
var player_threat := 0.0

var _monster: Monster
var _phase_left := 0.0
var _zone_timer := 0.0
var _noise := 0.0
var _pulse := 0.0
var _jumpscare := 0.0
var _hallucination := 0.0
var _haunt_timer := 120.0


func setup(builder: LevelBuilder, monster: Monster) -> void:
	zones = builder.zones
	spawn_points = builder.spawn_points
	patrol = builder.patrol
	rooms = builder.rooms
	player_door_front = builder.player_door_front
	_monster = monster
	first_attack_day = FIRST_ATTACK_DAYS[randi() % FIRST_ATTACK_DAYS.size()]


func _physics_process(delta: float) -> void:
	if not Game.game_over:
		if Input.is_action_just_pressed("debug_manifest") and not _monster.is_active():
			start_warning()
		elapsed += delta
		if first_attack_done:
			boldness = minf(100.0, boldness + BOLDNESS_PER_SECOND * delta)
		boldness_dip = maxf(0.0, boldness_dip - 0.15 * delta)
		satiation = maxf(0.0, satiation - 0.1 * delta)
		grief = maxf(0.0, grief - delta)
		_zone_timer -= delta
		if _zone_timer <= 0.0:
			_zone_timer = 1.0
			_update_zones()
		if not first_attack_done:
			_check_first_attack()
		else:
			_update_schedule(delta)
			_update_haunting(delta)
		_update_hallucination(delta)
	_update_effects(delta)


# --- Versteckte Werte ---------------------------------------------------------------

func effective_boldness() -> float:
	return clampf(boldness - boldness_dip - satiation, 0.0, 100.0)


func demand() -> float:
	return 1.0 + elapsed / DEMAND_GROWTH_SECONDS


func pressure_at(p: Vector3, chasing: bool = false) -> float:
	return effective_boldness() * (0.5 + 0.5 * curiosity_at(p) / 100.0) + (CHASE_BONUS if chasing else 0.0)


func deterrence_at(p: Vector3) -> float:
	var light := light_at(p + Vector3.UP)
	return deco_strength_at(p) * (0.6 + light) / demand() \
		+ light * LIGHT_DETERRENCE * (1.0 - effective_boldness() / 120.0)


func is_blocked(p: Vector3, chasing: bool) -> bool:
	return deterrence_at(p) > pressure_at(p, chasing)


## Steht jemand hier im Schutz von Deko und Licht – auch gegen ein jagendes Monster?
func is_protected(p: Vector3) -> bool:
	return is_blocked(p, true)


func deco_strength_at(p: Vector3) -> float:
	var total := 0.0
	for node in get_tree().get_nodes_in_group("items"):
		var item := node as Item
		if item.is_held or item.deco_strength <= 0.0:
			continue
		var d := Vector2(item.global_position.x - p.x, item.global_position.z - p.z).length()
		if d < DECO_RADIUS:
			total += item.deco_strength * (1.0 - 0.5 * d / DECO_RADIUS)
	return total


## Helligkeit 0..1 an einem Punkt – alle Lichtquellen mit freier Sichtlinie.
func light_at(p: Vector3) -> float:
	var space := _monster.get_world_3d().direct_space_state
	var total := 0.0
	for node in get_tree().get_nodes_in_group("light_source"):
		var light := node as OmniLight3D
		if not light.is_visible_in_tree() or light.light_energy < 0.02:
			continue
		var lp := light.global_position
		var d := lp.distance_to(p)
		if d > light.omni_range:
			continue
		var query := PhysicsRayQueryParameters3D.create(lp, p, 1 | 2)
		if not space.intersect_ray(query).is_empty():
			continue
		var att := 1.0 - d / light.omni_range
		total += light.light_energy * att * att * 1.6
	# Mondlicht durch Außenfenster mit offenen Vorhängen
	for node in get_tree().get_nodes_in_group("windows"):
		var win := node as HotelWindow
		if not win.lets_moonlight():
			continue
		var wp := win.inside_point()
		var wd := wp.distance_to(p)
		if wd > MOONLIGHT_RANGE:
			continue
		var moon_query := PhysicsRayQueryParameters3D.create(wp, p, 1 | 2)
		if space.intersect_ray(moon_query).is_empty():
			total += MOONLIGHT * (1.0 - wd / MOONLIGHT_RANGE)
	return clampf(total, 0.0, 1.0)


func curiosity_at(p: Vector3) -> float:
	var zone := _zone_at(p)
	return 40.0 if zone.is_empty() else float(zone["curiosity"])


func add_curiosity(p: Vector3, amount: float) -> void:
	var zone := _zone_at(p)
	if not zone.is_empty():
		zone["curiosity"] = clampf(float(zone["curiosity"]) + amount, 0.0, 100.0)


## Zonen sind Kreise auf einem Stockwerk (Keller, Erdgeschoss, Obergeschoss).
func _zone_at(p: Vector3) -> Dictionary:
	var best: Dictionary = {}
	var best_ratio := INF
	for zone in zones:
		var c: Vector3 = zone["center"]
		var r: float = zone["radius"]
		if absf(p.y - c.y) > 2.5:
			continue
		var ratio := Vector2(p.x - c.x, p.z - c.z).length() / r
		if ratio < best_ratio:
			best_ratio = ratio
			best = zone
	return best


func zone_name_at(p: Vector3) -> String:
	var zone := _zone_at(p)
	return "" if zone.is_empty() else String(zone["name"])


## Neugier strebt langsam zu einem Grundwert aus Dunkelheit und fehlender Deko;
## Ereignisse (Lärm, Sichtung …) addieren direkt darauf.
func _update_zones() -> void:
	for zone in zones:
		var c: Vector3 = zone["center"]
		var light := light_at(c + Vector3.UP)
		var deco := deco_strength_at(c) / demand()
		var base := 10.0 + (1.0 - light) * 55.0 + clampf(25.0 - deco, 0.0, 25.0)
		var current: float = zone["curiosity"]
		zone["curiosity"] = clampf(lerpf(current, base, 0.04), 0.0, 100.0)
	# „Angst riecht“: ein Spieler unter Schock lockt das Monster an
	if Game.player and Game.player.shock > 0.1:
		add_curiosity(Game.player.global_position, Game.player.shock * 3.0)


# --- Dramaturgie ------------------------------------------------------------------------

## Noch harmlos? Die ersten Angriffe holen niemanden (Spielkonzept 2.1).
func is_harmless() -> bool:
	return attacks <= HARMLESS_ATTACKS


## Soll ein Gast jetzt eine Feier geben, damit der erste Angriff dort passieren kann?
func wants_first_attack_party() -> bool:
	return not first_attack_done and Calendar.today() >= first_attack_day


## Ist es um diesen Ort herum ruhig (kein Monster in der Nähe)?
func is_quiet(pos: Vector3, radius: float = 25.0) -> bool:
	return not _monster.is_active() or _monster.global_position.distance_to(pos) > radius


func _check_first_attack() -> void:
	var day := Calendar.today()
	var social := Game.social
	if social and social.party_active and day >= first_attack_day and social.party_age() >= FIRST_ATTACK_PARTY_TIME:
		_first_attack_at_party()
	elif day >= FALLBACK_ATTACK_DAY:
		first_attack_done = true
		_start_activity(spawn_points[0])


## Mitten in der Feier: Licht aus, Musik aus, Stille – und es ist da.
func _first_attack_at_party() -> void:
	first_attack_done = true
	var lobby := LightSwitch.find(get_tree(), "lobby")
	if lobby:
		lobby.set_on(false)
	Game.social.end_party("")
	Game.play_sound("bang", 0.6)
	if Game.player and Game.player.global_position.x < 0.0:
		Game.say("Das Licht geht aus. Die Musik verstummt.", 3.0)
	# Es steht in der dunklen Ecke der Lobby, beim verriegelten Ausgang
	_start_activity(Vector3(-12.8, 0.05, -5.8))
	_monster.investigate(Game.social.party_center())


func _start_activity(spawn: Vector3) -> void:
	attacks += 1
	phase = Phase.ACTIVE
	_phase_left = _day_lerp(ACTIVE_TIME) * randf_range(0.8, 1.2)
	_monster.start_roaming(spawn)


func _update_schedule(delta: float) -> void:
	_phase_left -= delta
	match phase:
		Phase.ACTIVE:
			if not _monster.is_active():
				on_monster_gone()
			elif _phase_left <= 0.0 and _monster.state != Monster.State.CHASE:
				_monster.go_home()
		_:
			if _phase_left <= 0.0:
				_start_activity(spawn_points[0])


## Wert zwischen Anfang (1. Oktober) und Halloween.
func _day_lerp(range_value: Vector2) -> float:
	var t := clampf((Calendar.today() - 1) / float(Calendar.HALLOWEEN - 1), 0.0, 1.0)
	return lerpf(range_value.x, range_value.y, t)


## Das Monster ist zurück im Keller → Ruhephase (satt: länger).
func on_monster_gone() -> void:
	phase = Phase.CALM
	_phase_left = _day_lerp(REST_TIME) * randf_range(0.8, 1.2) + satiation * 3.0


## Debug (F5, --warn): sofort losschicken.
func start_warning() -> void:
	first_attack_done = true
	if not _monster.is_active():
		_start_activity(spawn_points[0])


# --- Ereignisse -------------------------------------------------------------------------

func on_noise(pos: Vector3, strength: float) -> void:
	add_curiosity(pos, 3.0 * strength)
	if _monster.is_active() and _monster.global_position.distance_to(pos) < 14.0:
		_monster.investigate(pos)


## Jemand (Spieler oder Gast) ist in ein Versteck gegangen. Hat das Monster es gesehen?
func on_actor_hid(spot: HideSpot, actor: Node3D) -> void:
	if not _monster.is_active() or _monster.state == Monster.State.KILL:
		return
	var head := actor.global_position + Vector3.UP * 1.5
	if actor == Game.player:
		head = Game.player.camera.global_position
	if _monster.global_position.distance_to(head) < 16.0 and _monster.can_see_position(head):
		spot.seen_entering = true
		_monster.go_check(spot)


func on_monster_noticed() -> void:
	boldness = minf(100.0, boldness + 8.0)
	add_curiosity(player_door_front, 40.0)
	Game.play_sound("sting", 1.0)
	_monster.stare()


## Jemand redet über das Monster – es hört mit und wird dreister (Spielkonzept 4.7).
func on_monster_talk(pos: Vector3) -> void:
	boldness = minf(100.0, boldness + 3.0)
	add_curiosity(pos, 10.0)


## Licht ausgeschaltet, Birne herausgedreht oder durchgebrannt: Dunkelheit lockt es an.
func on_lights_off(pos: Vector3) -> void:
	add_curiosity(pos, LIGHTS_OFF_CURIOSITY)
	if _monster.is_active() and _monster.global_position.distance_to(pos) < 20.0:
		_monster.investigate(pos)


func on_monster_repelled() -> void:
	boldness_dip = minf(15.0, boldness_dip + 2.0)


## Hat das Monster einen Gast geholt, ist es eine Weile satt.
func on_guest_taken() -> void:
	satiation = 40.0


func kill_guest(guest, spot: HideSpot) -> void:
	if guest == null or not is_instance_valid(guest) or guest.dead:
		return
	if is_harmless():
		_scare_guest(guest, spot)
		return
	if spot != null:
		spot.rip_open()
	Game.play_sound("scream", 0.5 if Game.player and Game.player.global_position.distance_to(guest.global_position) > 12.0 else 0.9)
	var where: Vector3 = guest.global_position
	guest.die()
	if Game.traces:
		Game.traces.add_blood(Vector3(where.x, 0.0, where.z), _monster.rotation.y)
	# Ein Kleidungsstück bleibt zurück – Andeutung statt Gore
	var cloth := Item.create(Item.Kind.CLOTHING, guest.id)
	_monster.get_parent().add_child(cloth)
	cloth.global_position = Vector3(where.x + 0.4, 0.05, where.z + 0.2)
	on_guest_taken()
	grief = GRIEF_TIME
	_monster.after_feeding()
	if Game.social:
		Game.social.on_guest_died(guest)


## Harmloser Angriff auf einen Gast: Er wird zu Tode erschreckt – aber nicht geholt.
func _scare_guest(guest, spot: HideSpot) -> void:
	if spot != null:
		spot.rip_open()
	Game.play_sound("scream", 0.4 if Game.player and Game.player.global_position.distance_to(guest.global_position) > 12.0 else 0.8)
	guest.scared_by_monster()
	_monster.after_scare()


func kill_player(spot: HideSpot) -> void:
	if Game.game_over:
		return
	if is_harmless():
		_reveal_to_player(spot)
		return
	Game.game_over = true
	var player := Game.player
	player.dead = true
	if Game.hud:
		Game.hud.set_prompt("")
	if spot != null:
		spot.rip_open()
		await get_tree().create_timer(0.2).timeout
	if Game.hud:
		Game.hud.visible = false
	_monster.play_jumpscare(player.camera)
	_jumpscare = 1.4
	Game.play_sound("scream", 1.0)
	await get_tree().create_timer(1.5).timeout
	Game.player_died.emit()


## Harmloser Angriff auf den Spieler: Es steht direkt vor dir, starrt dich an – und ist
## im nächsten Flackern verschwunden. Jetzt weißt du, dass es real ist.
func _reveal_to_player(spot: HideSpot) -> void:
	var player := Game.player
	if spot != null:
		spot.rip_open()
		player.exit_hide()
	_monster.reveal(player.camera)
	Game.play_sound("sting", 1.0)
	_jumpscare = 0.6
	await get_tree().create_timer(1.8, false).timeout
	_jumpscare = 1.0
	Game.play_sound("bang", 0.5)
	await get_tree().create_timer(0.15, false).timeout
	_monster.deactivate()
	on_monster_gone()


# --- Unheimliche Kleinigkeiten ---------------------------------------------------------------

## Halluzination nach einem Todesfall: Rauschen ohne Monster.
func _update_hallucination(delta: float) -> void:
	if _hallucination > 0.0:
		_hallucination -= delta
		return
	var p := Game.player
	if p == null or p.dead:
		return
	if (grief > 0.0 or p.shock > 0.15) and randf() < delta / HALLUCINATION_EVERY:
		_hallucination = randf_range(6.0, 11.0)


## Das Hotel verändert sich, wenn niemand hinsieht (Spielkonzept 4.13).
func _update_haunting(delta: float) -> void:
	_haunt_timer -= delta
	if _haunt_timer > 0.0:
		return
	_haunt_timer = randf_range(HAUNT_INTERVAL.x, HAUNT_INTERVAL.y)
	var p := Game.player
	if p == null or p.dead:
		return
	var away_from_room := p.global_position.distance_to(player_door_front) > 12.0
	var actions: Array[Callable] = [_haunt_door, _haunt_curtain, _haunt_light, _haunt_bed]
	if away_from_room:
		actions.append(_haunt_room_13)
	actions.shuffle()
	for action in actions:
		if action.call():
			return


func _unseen(pos: Vector3, min_dist: float = 8.0) -> bool:
	var p := Game.player
	return p.global_position.distance_to(pos) > min_dist and not player_can_see(pos)


func _haunt_door() -> bool:
	var doors := get_tree().get_nodes_in_group("doors")
	doors.shuffle()
	for node in doors:
		var door := node as Door
		if not door.is_open and not door.locked and door.monster_can_open and _unseen(door.center()):
			door.set_open(true, false, true)
			return true
	return false


func _haunt_curtain() -> bool:
	var windows := get_tree().get_nodes_in_group("windows")
	windows.shuffle()
	for node in windows:
		var win := node as HotelWindow
		if win.has_curtains() and not win.closed and _unseen(win.global_position):
			win.set_closed(true, true)
			return true
	return false


func _haunt_light() -> bool:
	var switches := get_tree().get_nodes_in_group("light_switches")
	switches.shuffle()
	var player_zone := zone_name_at(Game.player.global_position)
	for node in switches:
		var sw := node as LightSwitch
		if sw.on and sw.room_label != player_zone and _unseen(sw.global_position, 12.0):
			sw.set_on(false)
			return true
	return false


func _haunt_bed() -> bool:
	var spots := get_tree().get_nodes_in_group("hide_spots")
	spots.shuffle()
	for node in spots:
		var spot := node as HideSpot
		if spot.type == HideSpot.Type.BED and not spot.checked and spot.occupant == null and _unseen(spot.global_position):
			spot.set_checked(true)
			return true
	return false


## Zimmer 13 bleibt nicht unberührt: Bett zerwühlt, Vorhang zu, eine fremde Zeile im Tagebuch.
func _haunt_room_13() -> bool:
	var info: Dictionary = rooms.get("13", {})
	if info.is_empty():
		return false
	match randi() % 3:
		0:
			for spot in info["spots"]:
				var hs: HideSpot = spot
				if hs.type == HideSpot.Type.BED and not hs.checked:
					hs.set_checked(true)
					return true
		1:
			for node in get_tree().get_nodes_in_group("windows"):
				var win := node as HotelWindow
				if win.room_id == "13" and win.has_curtains() and not win.closed:
					win.set_closed(true, true)
					return true
		_:
			if not strange_diary:
				strange_diary = true
				return true
	return false


# --- Ziele ----------------------------------------------------------------------------------

## Nächstes Ziel beim Umherstreifen: irgendwo im Hotel, gewichtet nach Druck (Dunkelheit,
## Neugier, wenig Deko). Lieber Orte, die der Spieler gerade nicht sieht.
func next_roam_target(from: Vector3) -> Dictionary:
	var candidates: Array[Dictionary] = []
	var weights: Array[float] = []
	var current := zone_name_at(from)
	for zone in zones:
		var zone_name: String = zone["name"]
		if zone_name == current:
			continue
		var target := {"pos": zone["center"] as Vector3, "room": ""}
		if zone_name.begins_with("Zimmer "):
			var no := zone_name.substr(7)
			if rooms.has(no):
				target = {"pos": (rooms[no] as Dictionary)["door_front"] as Vector3, "room": no}
		var pos: Vector3 = target["pos"]
		var w := pow(maxf(pressure_at(pos), 1.0), 2.0)
		if Game.player and player_can_see(pos + Vector3.UP * 1.2) and pos.distance_to(Game.player.global_position) < 15.0:
			w *= 0.15
		candidates.append(target)
		weights.append(w)
	var total := 0.0
	for w in weights:
		total += w
	var r := randf() * total
	for i in candidates.size():
		r -= weights[i]
		if r <= 0.0:
			return candidates[i]
	return candidates[0] if not candidates.is_empty() else {"pos": spawn_points[0], "room": ""}


## Ein Wegpunkt in der Nähe, den der Spieler gerade nicht sieht (zum Verschwinden).
func hidden_point_near(from: Vector3) -> Vector3:
	var best := from
	var best_dist := INF
	for entry in patrol:
		var pos: Vector3 = entry["pos"]
		var d := pos.distance_to(from)
		if d < 2.0 or d > 14.0 or player_can_see(pos + Vector3.UP * 1.2):
			continue
		if Game.player and pos.distance_to(Game.player.global_position) < from.distance_to(Game.player.global_position):
			continue   # nicht auf den Spieler zu
		if d < best_dist:
			best_dist = d
			best = pos
	return best


func nearest_patrol_index(pos: Vector3) -> int:
	var best := 0
	var best_dist := INF
	for i in patrol.size():
		var d := pos.distance_to(patrol[i]["pos"])
		if d < best_dist:
			best_dist = d
			best = i
	return best


## Biegt das Monster an dieser Tür ins Zimmer ab? Neugier × Dreistigkeit, mit Zufall.
func wants_to_enter_room(no: String) -> bool:
	if not rooms.has(no):
		return false
	var info: Dictionary = rooms[no]
	var door: Door = info["door"]
	if door.locked and effective_boldness() < 50.0:
		return false
	var chance := clampf(curiosity_at(info["center"]) / 100.0, 0.1, 0.9) * (0.4 + effective_boldness() / 120.0)
	return randf() < chance


func room_search_points(no: String) -> Array[Dictionary]:
	var info: Dictionary = rooms[no]
	var points: Array[Dictionary] = [
		{"pos": info["door_inside"], "spot": null},
		{"pos": info["center"], "spot": null},
	]
	for spot in info["spots"]:
		var hide_spot: HideSpot = spot
		points.append({"pos": hide_spot.check_point.global_position, "spot": hide_spot})
	return points


## Rückzugsort: der Keller.
func retreat_point(_from: Vector3) -> Vector3:
	return spawn_points[0]


func search_points_near(center: Vector3) -> Array[Dictionary]:
	var points: Array[Dictionary] = [{"pos": center, "spot": null}]
	var spots: Array[HideSpot] = []
	for node in get_tree().get_nodes_in_group("hide_spots"):
		var spot := node as HideSpot
		if spot.check_point.global_position.distance_to(center) < 7.0:
			spots.append(spot)
	spots.sort_custom(func(a: HideSpot, b: HideSpot) -> bool:
		return a.global_position.distance_to(center) < b.global_position.distance_to(center))
	for spot in spots:
		points.append({"pos": spot.check_point.global_position, "spot": spot})
	return points


func player_can_see(p: Vector3) -> bool:
	var cam := Game.player.camera
	if not cam.is_position_in_frustum(p):
		return false
	var query := PhysicsRayQueryParameters3D.create(cam.global_position, p, Monster.SIGHT_MASK)
	return _monster.get_world_3d().direct_space_state.intersect_ray(query).is_empty()


## Bedrohung 0..1 nach Entfernung zum Monster (für Spieler und Gäste) – wirkt durch Wände.
func threat_at(pos: Vector3) -> float:
	if not _monster.is_active() or _monster.state == Monster.State.KILL:
		return 0.0
	var d := _monster.global_position.distance_to(pos)
	return clampf((NOISE_START - d) / (NOISE_START - NOISE_FULL), 0.0, 1.0)


# --- Speichern ------------------------------------------------------------------------------

func save_state() -> Dictionary:
	return {
		"first_attack_done": first_attack_done, "first_attack_day": first_attack_day, "attacks": attacks,
		"grief": grief, "strange_diary": strange_diary, "phase": int(phase), "phase_left": _phase_left,
		"haunt_timer": _haunt_timer, "monster_active": _monster.is_active(),
		"monster_pos": [_monster.global_position.x, _monster.global_position.y, _monster.global_position.z],
	}


func load_state(d: Dictionary) -> void:
	first_attack_done = bool(d.get("first_attack_done", false))
	first_attack_day = int(d.get("first_attack_day", first_attack_day))
	attacks = int(d.get("attacks", 0))
	grief = float(d.get("grief", 0.0))
	strange_diary = bool(d.get("strange_diary", false))
	_phase_left = float(d.get("phase_left", 60.0))
	_haunt_timer = float(d.get("haunt_timer", 120.0))
	phase = Phase.CALM
	if bool(d.get("monster_active", false)):
		var mp: Array = d.get("monster_pos", [32.8, 0.05, 0.2])
		phase = Phase.ACTIVE
		_monster.start_roaming(Vector3(float(mp[0]), float(mp[1]), float(mp[2])))


# --- Effekte (Rauschen, Flackern, Lampen, Ton) --------------------------------------

func _update_effects(delta: float) -> void:
	var noise_target := 0.0
	var flicker_target := 0.0
	var hum_target := 0.0
	var heart_target := 0.0
	var player := Game.player
	player_threat = threat_at(player.global_position) if player else 0.0
	if player_threat > 0.0:
		var k := pow(player_threat, 1.4)
		noise_target = 0.45 * k
		flicker_target = 0.6 * k
		hum_target = 0.1 + 0.35 * player_threat
		heart_target = player_threat * 0.7
		if _monster.state == Monster.State.CHASE:
			noise_target += 0.15
			heart_target = 0.9
	if _hallucination > 0.0:
		var h := sin(clampf(_hallucination / 8.0, 0.0, 1.0) * PI)
		noise_target = maxf(noise_target, 0.3 * h)
		hum_target = maxf(hum_target, 0.25 * h)
	if player:
		noise_target += player.hide_stress * 0.3
		heart_target = maxf(heart_target, player.hide_stress)
		if player.shock > 0.1:
			noise_target += player.shock * 0.08
			heart_target = maxf(heart_target, player.shock * 0.5)
	if _jumpscare > 0.0:
		_jumpscare -= delta
		noise_target = 0.45
		flicker_target = 0.5
	_noise = move_toward(_noise, noise_target, delta * (3.0 if _jumpscare > 0.0 else 0.5))
	_pulse = maxf(0.0, _pulse - delta * 6.0)
	if randf() < flicker_target * delta * 2.0:
		_pulse = randf_range(0.3, 0.9)
	# Konzentriert beim Spielen fällt die Ankündigung weniger auf (Spielkonzept 6.10)
	var focus := 0.45 if player and player.focused and _jumpscare <= 0.0 else 1.0
	focus *= Settings.flicker_intensity   # Barrierefreiheit: weniger Flackern und Rauschen
	if post_material:
		post_material.set_shader_parameter("noise_amount", _noise * focus)
		post_material.set_shader_parameter("flicker", _pulse * 0.6 * focus)
		post_material.set_shader_parameter("red_tint", 0.12 if _jumpscare > 0.0 else 0.0)
	# Lampen flackern nur in der Nähe des Monsters
	var active := _monster.is_active()
	var mpos := _monster.global_position
	for node in get_tree().get_nodes_in_group("lamps"):
		var lamp := node as FlickerLight
		lamp.flicker = clampf(1.0 - lamp.global_position.distance_to(mpos) / LAMP_FLICKER_RANGE, 0.0, 1.0) * 0.9 if active else 0.0
	if Game.audio:
		Game.audio.hum = move_toward(Game.audio.hum, hum_target, delta * 0.3)
		Game.audio.static_noise = _noise * 0.3
		Game.audio.heart = move_toward(Game.audio.heart, heart_target, delta * 0.5)
		Game.audio.heart_bpm = 70.0 + heart_target * 60.0


func debug_text() -> String:
	var s := "%s · Phase %s (%ds) · Angriff %d%s\n" % [Calendar.date_text(elapsed), Phase.keys()[phase], int(_phase_left),
		attacks, " harmlos" if is_harmless() else ""]
	s += "Dreistigkeit %.1f (effektiv %.1f) · Bedrohung %.2f\n" % [boldness, effective_boldness(), player_threat]
	s += "Monster: %s\n" % Monster.State.keys()[_monster.state]
	if Game.player:
		s += "Licht beim Spieler: %.2f\n" % light_at(Game.player.global_position + Vector3.UP)
	s += "Zone        Neugier Druck Abschr.\n"
	for zone in zones:
		var c: Vector3 = zone["center"]
		s += "%-11s %5.0f %5.1f %5.1f\n" % [zone["name"], zone["curiosity"], pressure_at(c), deterrence_at(c)]
	s += "F5 = Monster losschicken"
	return s
