class_name MonsterDirector
extends Node
## Steuert das Monster über versteckte Werte (Spielkonzept 4.9):
##   Dreistigkeit (global) · Neugier (pro Zone) · Abschreckung (Deko × Licht / Anspruch)
##   Druck(Ort) = Dreistigkeit × (0,5 + 0,5 × Neugier/100)
##   Druck > Abschreckung → das Monster kommt durch.
## Außerdem: Ankündigung (Flackern, Rauschen, flackernde Lampen) und der Tod des Spielers.

enum Phase { CALM, WARNING, ACTIVE, COOLDOWN }

# --- Tuning -------------------------------------------------------------------
const BOLDNESS_START := 25.0
const BOLDNESS_PER_SECOND := 0.04      ## ≈ +2,4 pro Minute
const DEMAND_GROWTH_SECONDS := 900.0   ## Anspruch an Deko: +100 % alle 15 min
const DECO_RADIUS := 3.0
const LIGHT_DETERRENCE := 12.0
const CHASE_BONUS := 12.0
const WARNING_DURATION := 8.0
const FIRST_GRACE := 40.0
const MIN_COOLDOWN := 50.0

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

var _monster: Monster
var _phase_time := 0.0
var _cooldown := FIRST_GRACE
var _zone_timer := 0.0
var _noise := 0.0
var _pulse := 0.0
var _jumpscare := 0.0


func setup(builder: LevelBuilder, monster: Monster) -> void:
	zones = builder.zones
	spawn_points = builder.spawn_points
	patrol = builder.patrol
	rooms = builder.rooms
	player_door_front = builder.player_door_front
	_monster = monster


func _physics_process(delta: float) -> void:
	if not Game.game_over:
		if Input.is_action_just_pressed("debug_manifest") and phase == Phase.CALM:
			start_warning()
		elapsed += delta
		boldness = minf(100.0, boldness + BOLDNESS_PER_SECOND * delta)
		boldness_dip = maxf(0.0, boldness_dip - 0.15 * delta)
		satiation = maxf(0.0, satiation - 0.1 * delta)
		_zone_timer -= delta
		if _zone_timer <= 0.0:
			_zone_timer = 1.0
			_update_zones()
		_phase_time += delta
		match phase:
			Phase.CALM:
				_cooldown -= delta
				if _cooldown <= 0.0 and randf() < manifest_chance() * delta:
					start_warning()
			Phase.WARNING:
				if _phase_time >= WARNING_DURATION:
					_manifest()
			Phase.COOLDOWN:
				if _phase_time > 8.0:
					phase = Phase.CALM
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
	return clampf(total, 0.0, 1.0)


func curiosity_at(p: Vector3) -> float:
	var zone := _zone_at(p)
	return 40.0 if zone.is_empty() else float(zone["curiosity"])


func add_curiosity(p: Vector3, amount: float) -> void:
	var zone := _zone_at(p)
	if not zone.is_empty():
		zone["curiosity"] = clampf(float(zone["curiosity"]) + amount, 0.0, 100.0)


func _zone_at(p: Vector3) -> Dictionary:
	var best: Dictionary = {}
	var best_ratio := INF
	for zone in zones:
		var c: Vector3 = zone["center"]
		var r: float = zone["radius"]
		var ratio := Vector2(p.x - c.x, p.z - c.z).length() / r
		if ratio < best_ratio:
			best_ratio = ratio
			best = zone
	return best


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


func manifest_chance() -> float:
	var top := 0.0
	for zone in zones:
		top = maxf(top, pressure_at(zone["center"]))
	return 0.008 + pow(top / 100.0, 2.0) * 0.05


# --- Ablauf -------------------------------------------------------------------------

func start_warning() -> void:
	phase = Phase.WARNING
	_phase_time = 0.0


func _manifest() -> void:
	_monster.start_patrol(_pick_patrol_start())
	phase = Phase.ACTIVE
	_phase_time = 0.0


func on_monster_gone() -> void:
	phase = Phase.COOLDOWN
	_phase_time = 0.0
	_cooldown = MIN_COOLDOWN + randf() * 40.0


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


func on_monster_repelled() -> void:
	boldness_dip = minf(15.0, boldness_dip + 2.0)


## Für später (Gäste): Hat das Monster einen Gast geholt, ist es eine Weile satt.
func on_guest_taken() -> void:
	satiation = 40.0


func kill_guest(guest, spot: HideSpot) -> void:
	if guest == null or not is_instance_valid(guest) or guest.dead:
		return
	if spot != null:
		spot.rip_open()
	Game.play_sound("scream", 0.5 if Game.player and Game.player.global_position.distance_to(guest.global_position) > 12.0 else 0.9)
	guest.die()
	on_guest_taken()
	_monster.after_feeding()
	if Game.social:
		Game.social.on_guest_died(guest)


func kill_player(spot: HideSpot) -> void:
	if Game.game_over:
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


# --- Ziele --------------------------------------------------------------------------

## Erster Wegpunkt der Route (ab Keller), der weit genug weg und außer Sicht ist.
func _pick_patrol_start() -> int:
	var player_pos := Game.player.global_position
	for i in patrol.size():
		var pos: Vector3 = patrol[i]["pos"]
		if pos.distance_to(player_pos) > 10.0 and not player_can_see(pos + Vector3.UP * 1.2):
			return i
	return 0


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


## Nächster Rückzugsort, der nicht zu nah am Spieler liegt.
func retreat_point(from: Vector3) -> Vector3:
	var player_pos := Game.player.global_position if Game.player else Vector3.ZERO
	var best := spawn_points[0]
	var best_dist := INF
	for sp in spawn_points:
		if sp.distance_to(player_pos) < 8.0:
			continue
		var d := sp.distance_to(from)
		if d < best_dist:
			best_dist = d
			best = sp
	return best


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
	var query := PhysicsRayQueryParameters3D.create(cam.global_position, p, 1 | 2)
	return _monster.get_world_3d().direct_space_state.intersect_ray(query).is_empty()


# --- Effekte (Bildrauschen, Flackern, Lampen, Ton) --------------------------------------

func _update_effects(delta: float) -> void:
	var noise_target := 0.0
	var flicker_target := 0.0
	var hum_target := 0.0
	var heart_target := 0.0
	var player := Game.player
	match phase:
		Phase.WARNING:
			var k := clampf(_phase_time / WARNING_DURATION, 0.0, 1.0)
			noise_target = 0.06 + 0.3 * k
			flicker_target = 0.25 + 0.6 * k
			hum_target = 0.1 + 0.35 * k
		Phase.ACTIVE:
			if player and _monster.is_active():
				var d := _monster.global_position.distance_to(player.global_position)
				var prox := clampf(1.0 - d / 18.0, 0.0, 1.0)
				noise_target = 0.05 + 0.35 * prox
				flicker_target = 0.15 + 0.6 * prox
				hum_target = 0.12 + 0.4 * prox
				heart_target = prox * 0.7
				if _monster.state == Monster.State.CHASE:
					noise_target += 0.15
					heart_target = 0.9
	if player:
		noise_target += player.hide_stress * 0.3
		heart_target = maxf(heart_target, player.hide_stress)
		# Schock nach dem Tod eines Freundes: Halluzinationen (falsches Flackern/Rauschen)
		if player.shock > 0.1:
			noise_target += player.shock * 0.12
			flicker_target = maxf(flicker_target, player.shock * 0.35)
			heart_target = maxf(heart_target, player.shock * 0.5)
	if _jumpscare > 0.0:
		_jumpscare -= delta
		noise_target = 0.45
		flicker_target = 0.5
	_noise = move_toward(_noise, noise_target, delta * (3.0 if _jumpscare > 0.0 else 0.5))
	_pulse = maxf(0.0, _pulse - delta * 6.0)
	if randf() < flicker_target * delta * 2.0:
		_pulse = randf_range(0.3, 0.9)
	# Konzentriert beim Spielen fällt die Vorwarnung weniger auf (Spielkonzept 6.10)
	var focus := 0.45 if player and player.focused and _jumpscare <= 0.0 else 1.0
	if post_material:
		post_material.set_shader_parameter("noise_amount", _noise * focus)
		post_material.set_shader_parameter("flicker", _pulse * 0.6 * focus)
		post_material.set_shader_parameter("red_tint", 0.12 if _jumpscare > 0.0 else 0.0)
	for node in get_tree().get_nodes_in_group("lamps"):
		(node as FlickerLight).flicker = flicker_target
	if Game.audio:
		Game.audio.hum = move_toward(Game.audio.hum, hum_target, delta * 0.3)
		Game.audio.static_noise = _noise * 0.3
		Game.audio.heart = move_toward(Game.audio.heart, heart_target, delta * 0.5)
		Game.audio.heart_bpm = 70.0 + heart_target * 60.0


func debug_text() -> String:
	var s := "Phase %s   t=%ds   Anspruch x%.2f\n" % [Phase.keys()[phase], int(elapsed), demand()]
	s += "Dreistigkeit %.1f (effektiv %.1f)\n" % [boldness, effective_boldness()]
	s += "Monster: %s\n" % Monster.State.keys()[_monster.state]
	if Game.player:
		s += "Licht beim Spieler: %.2f\n" % light_at(Game.player.global_position + Vector3.UP)
	s += "Zone        Neugier Druck Abschr.\n"
	for zone in zones:
		var c: Vector3 = zone["center"]
		s += "%-11s %5.0f %5.1f %5.1f\n" % [zone["name"], zone["curiosity"], pressure_at(c), deterrence_at(c)]
	s += "F5 = Monster rufen"
	return s
