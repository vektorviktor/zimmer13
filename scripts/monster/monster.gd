class_name Monster
extends CharacterBody3D
## Das Monster (Spielkonzept 4, 4.13). Streift im ganzen Hotel umher – gewichtet nach Druck
## (Dunkelheit, Neugier, wenig Deko) – und biegt in Zimmer ab, wenn Neugier und Dreistigkeit
## groß genug sind. Es bleibt meist verborgen: Sieht der Spieler es, verschwindet es aus
## seinem Blickfeld. Sieht es jemanden, jagt es ihn. Es hinterlässt Spuren (Fußspuren,
## Kratzspuren, ausgehende Kerzen, Handabdrücke, geprüfte Verstecke).
## Lokale −Z-Achse = Blickrichtung. Bewegt sich ruckartig („Stop-Motion“).

enum State { INACTIVE, PATROL, INVESTIGATE, LURK, STARE, SEARCH, CHECK_HIDE, CHASE, REPELLED, RETREAT, KILL, SLINK, REVEAL }

const WALK_SPEED := 1.6
const SEARCH_SPEED := 2.0
const CHASE_SPEED := 4.3
const KILL_DISTANCE := 1.1
## Wird es länger als so lange gesehen, verschwindet es aus dem Blickfeld
const SEEN_BEFORE_SLINK := 0.35
const STEP_LENGTH := 0.85          ## Abstand der Fußspuren
const CANDLE_RANGE := 2.0          ## Kerzen in dieser Nähe gehen aus
const HANDPRINT_RANGE := 1.4       ## Abstand zum Milchglas für einen Handabdruck
const HANDPRINT_CHANCE := 0.35
const EYE_HEIGHT := 1.85
## Sichtweite (Spielkonzept 4.12): im Dunkeln ~8 m, im Hellen ~18 m
const SIGHT_DARK := 8.0
const SIGHT_LIGHT_BONUS := 10.0
## Sichtlinie: Wände, Türen, Vorhänge und Milchglas (klares Glas lässt den Blick durch)
const SIGHT_MASK := 1 | 2 | 256

var state := State.INACTIVE
var noticed := false
var agent: NavigationAgent3D

var _collider: CollisionShape3D
var _visual: Node3D
var _head: Node3D
var _arm_l: Node3D
var _arm_r: Node3D
var _eye_mat: ShaderMaterial
var _face_light: OmniLight3D
var _target := Vector3.ZERO
var _roam: Dictionary = {}       ## aktuelles Ziel beim Umherstreifen {pos, room}
var _seen_timer := 0.0
var _step_dist := 0.0
var _foot_side := 1.0
var _trace_timer := 0.0
var _handprinted: Array = []
var _scratched := false
var _search: Array[Dictionary] = []
var _hide_target: HideSpot
var _chase_target = null          ## Player oder Guest
var _last_seen := Vector3.ZERO
var _lose_timer := 0.0
var _calm_retreat := false      ## nach einem harmlosen Schreck: niemanden mehr jagen
var _state_timer := 0.0
var _idle_timer := 0.0
var _active_time := 0.0
var _look_timer := 0.0
var _deter_timer := 0.0
var _lurk_count := 0
var _anim_time := 0.0
var _stuck_time := 0.0
var _last_pos := Vector3.ZERO
var _anim_step := 0.0
var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")


func _ready() -> void:
	collision_layer = 32
	collision_mask = 1
	_collider = CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.3
	capsule.height = 1.6
	_collider.shape = capsule
	_collider.position.y = 0.8
	add_child(_collider)
	agent = NavigationAgent3D.new()
	agent.radius = 0.3
	agent.height = 1.6
	agent.path_desired_distance = 0.3
	agent.target_desired_distance = 0.5
	agent.path_height_offset = 0.2   # NavMesh liegt ~0,2 m über dem Boden
	add_child(agent)
	_build_visual()
	deactivate()


func is_active() -> bool:
	return state != State.INACTIVE


# --- Steuerung von außen ----------------------------------------------------

## Erscheint (meist im Keller) und streift umher, bis der Director es heimschickt.
func start_roaming(pos: Vector3) -> void:
	_appear(pos)
	_handprinted.clear()
	_next_roam()


## Für Tests: an einer beliebigen Stelle erscheinen.
func spawn_at(pos: Vector3) -> void:
	Game.director.first_attack_done = true
	Game.director.phase = MonsterDirector.Phase.ACTIVE
	Game.director._phase_left = MonsterDirector.ACTIVE_TIME.x
	start_roaming(pos)


## Hinter jemandem auftauchen, den der Spieler gerade nicht sieht (Klopfen, Tür zu).
func spawn_near_unseen(pos: Vector3) -> void:
	if not is_active():
		_appear(pos + Vector3(1.4, 0, 0))
		_set_state(State.PATROL)
	else:
		global_position = pos + Vector3(1.4, 0, 0)


## Ende der Aktivphase: zurück in den Keller.
func go_home() -> void:
	if not state in [State.RETREAT, State.INACTIVE, State.KILL, State.REVEAL]:
		_start_retreat()


func deactivate() -> void:
	_set_state(State.INACTIVE)
	visible = false
	_collider.disabled = true
	velocity = Vector3.ZERO
	global_position = Vector3(0, -50, 0)
	_search.clear()
	_hide_target = null
	_chase_target = null
	noticed = false
	_look_timer = 0.0
	_face_light.light_energy = 0.0


## Geräusch gehört → nachsehen, danach weiter auf der Route.
func investigate(pos: Vector3) -> void:
	if state in [State.PATROL, State.LURK, State.SEARCH, State.INVESTIGATE, State.SLINK]:
		_target = pos
		_set_state(State.INVESTIGATE)


## Gezielt ein Versteck aufsuchen (es hat gesehen, wie jemand hineinging).
func go_check(spot: HideSpot) -> void:
	_search = [{"pos": spot.check_point.global_position, "spot": spot}]
	_set_state(State.SEARCH)


## Der Spieler hat es bemerkt → es starrt zurück und sucht dann rund um sein Zimmer.
func stare() -> void:
	_set_state(State.STARE)


func play_jumpscare(cam: Camera3D) -> void:
	_set_state(State.KILL)
	visible = true
	_collider.disabled = true
	var forward := -cam.global_transform.basis.z
	forward.y = 0.0
	if forward.length() < 0.01:
		forward = Vector3.FORWARD
	forward = forward.normalized()
	# Kopf auf Augenhöhe, dann ruckartig auf die Kamera zu
	var base := cam.global_position - Vector3.UP * (EYE_HEIGHT - 0.05)
	global_position = base + forward * 1.5
	rotation = Vector3(0, atan2(forward.x, forward.z), 0)
	_eye_mat.set_shader_parameter("emission_energy", 8.0)
	_face_light.light_energy = 1.4
	_head.rotation = Vector3(0.1, 0, 0.3)
	_arm_l.rotation.x = -1.2
	_arm_r.rotation.x = -1.3
	create_tween().tween_property(self, "global_position", base + forward * 0.5, 0.22).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)


## Nach einem geholten Gast: satt, zurück ins Versteck.
func after_feeding() -> void:
	_chase_target = null
	_start_retreat()


## Harmloser Angriff (die ersten Male): den Gast erschreckt, dann zurück in den Keller.
func after_scare() -> void:
	_chase_target = null
	_start_retreat()
	_calm_retreat = true


## Harmloser Angriff auf den Spieler: Es steht direkt vor ihm und starrt ihn an.
func reveal(cam: Camera3D) -> void:
	_set_state(State.REVEAL)
	visible = true
	_collider.disabled = true
	velocity = Vector3.ZERO
	var forward := -cam.global_transform.basis.z
	forward.y = 0.0
	if forward.length() < 0.01:
		forward = Vector3.FORWARD
	forward = forward.normalized()
	var base := cam.global_position - Vector3.UP * (EYE_HEIGHT - 0.1)
	global_position = Vector3(base.x, cam.global_position.y - 1.7, base.z) + forward * 1.3
	rotation = Vector3(0, atan2(forward.x, forward.z), 0)
	_eye_mat.set_shader_parameter("emission_energy", 6.0)
	_face_light.light_energy = 0.9
	_head.rotation = Vector3(0.15, 0, 0.2)
	if "--shot-reveal" in OS.get_cmdline_user_args():
		Game._shot_at = Game._shot_frames + 25


func _appear(pos: Vector3) -> void:
	global_position = pos
	_scratched = false
	_last_pos = pos
	visible = true
	_collider.disabled = false
	_active_time = 0.0
	_lurk_count = 0
	noticed = false
	_look_timer = 0.0
	_chase_target = null
	_eye_mat.set_shader_parameter("emission_energy", 1.2)


# --- Wahrnehmung --------------------------------------------------------------

## Alle, die es sehen und jagen kann: Spieler + lebende Gäste.
func _actors() -> Array:
	var list: Array = []
	if Game.player:
		list.append(Game.player)
	if Game.social:
		list.append_array(Game.social.living_guests())
	return list


func can_see_actor(actor) -> bool:
	if actor == null or not is_instance_valid(actor) or actor.dead or actor.hiding != null:
		return false
	var target: Vector3 = actor.global_position + Vector3.UP * (0.95 if actor.crouching else 1.5)
	var light := Game.director.light_at(target)
	var sight := SIGHT_DARK + SIGHT_LIGHT_BONUS * light
	if actor.running:
		sight += 3.0
	if actor.crouching:
		sight -= 2.0
	elif Vector2(actor.velocity.x, actor.velocity.z).length() < 0.1:
		sight -= 1.0   # wer still steht, fällt weniger auf
	if state == State.CHASE:
		sight += 5.0
	if global_position.distance_to(actor.global_position) > sight:
		return false
	return can_see_position(target, state != State.CHASE)


func can_see_position(target: Vector3, check_fov: bool = true) -> bool:
	var eye := global_position + Vector3.UP * EYE_HEIGHT
	var to := target - eye
	var dist := to.length()
	if check_fov and dist > 2.0:
		var forward := -global_transform.basis.z
		if forward.dot(to / dist) < 0.3:
			return false
	return _los(eye, target)


func _visible_actor():
	if _chase_target != null and is_instance_valid(_chase_target) and can_see_actor(_chase_target):
		return _chase_target
	var best = null
	var best_dist := INF
	for actor in _actors():
		if can_see_actor(actor):
			var d := global_position.distance_to(actor.global_position)
			if d < best_dist:
				best_dist = d
				best = actor
	return best


func _los(a: Vector3, b: Vector3) -> bool:
	var query := PhysicsRayQueryParameters3D.create(a, b, SIGHT_MASK)
	query.exclude = [get_rid()]
	return get_world_3d().direct_space_state.intersect_ray(query).is_empty()


## Schaut der Spieler das Monster ~0,8 s direkt an, „weiß“ es, dass es bemerkt wurde.
func _update_noticed(delta: float) -> void:
	if noticed or not (state in [State.PATROL, State.INVESTIGATE, State.LURK, State.SEARCH, State.SLINK]):
		return
	var p := Game.player
	if p == null or p.dead:
		return
	var cam := p.camera
	var head_pos := global_position + Vector3.UP * 1.7
	var to := head_pos - cam.global_position
	var looking := to.length() < 22.0 \
		and (-cam.global_transform.basis.z).dot(to.normalized()) > 0.93 \
		and _los(cam.global_position, head_pos)
	_look_timer = _look_timer + delta if looking else maxf(0.0, _look_timer - delta)
	if _look_timer > 0.8:
		noticed = true
		Game.director.on_monster_noticed()


# --- Zustände -----------------------------------------------------------------

func _physics_process(delta: float) -> void:
	if state == State.INACTIVE:
		return
	_animate(delta)
	if state == State.KILL or state == State.REVEAL:
		return
	_active_time += delta
	_update_traces(delta)
	_state_timer += delta
	var seen = _visible_actor()
	_update_noticed(delta)
	if state in [State.PATROL, State.INVESTIGATE] and seen == null:
		_check_seen(delta)
	match state:
		State.PATROL:
			if seen != null:
				_start_chase(seen)
			else:
				_patrol_step(delta)
		State.SLINK:
			# Gesehen worden – aus dem Blickfeld verschwinden, dann weiter
			if seen != null and global_position.distance_to(seen.global_position) < 4.0:
				_start_chase(seen)
			elif _move_to(_target, SEARCH_SPEED, delta) or _state_timer > 8.0:
				_next_roam()
		State.INVESTIGATE:
			if seen != null:
				_start_chase(seen)
			elif _move_to(_target, SEARCH_SPEED, delta):
				_idle_timer += delta
				if _idle_timer > 2.0:
					_set_state(State.PATROL)
		State.LURK:
			# An der Grenze zu Licht/Deko stehen bleiben und starren – dann weiter.
			_stop(delta)
			if Game.player:
				_face(Game.player.global_position, delta)
			if seen != null and global_position.distance_to(seen.global_position) < 4.0:
				_start_chase(seen)
			elif _state_timer > 2.5:
				if _lurk_count >= 4:
					_start_retreat()
				else:
					_next_roam()
		State.STARE:
			_stop(delta)
			if Game.player:
				_face(Game.player.global_position, delta)
			if seen != null and global_position.distance_to(seen.global_position) < 5.0:
				_start_chase(seen)
			elif _state_timer > 1.4:
				_start_search(Game.director.player_door_front)
		State.SEARCH:
			if seen != null:
				_start_chase(seen)
			else:
				_search_step(delta)
		State.CHECK_HIDE:
			_check_hide_step(delta)
		State.CHASE:
			_chase_step(seen, delta)
		State.REPELLED:
			_stop(delta)
			if _state_timer > 1.6:
				_start_retreat()
		State.RETREAT:
			# Kein sicherer Rückzug (4.12): Wen es sieht, den jagt es wieder – außer es ist satt
			# oder der Gesehene steht im Schutz von Deko und Licht. Nach einem harmlosen Schreck
			# verschwindet es einfach – sonst erschreckt es denselben Gast immer wieder.
			if seen != null and not _calm_retreat and Game.director.satiation <= 0.0 and not Game.director.is_protected(seen.global_position):
				_start_chase(seen)
			elif _move_to(_target, SEARCH_SPEED, delta) or _state_timer > 30.0 or _can_vanish():
				Game.director.on_monster_gone()
				deactivate()
				return
	_check_deterrence(delta)
	_open_doors()


func _set_state(new_state: State) -> void:
	state = new_state
	_state_timer = 0.0
	_idle_timer = 0.0


func _patrol_step(delta: float) -> void:
	if _roam.is_empty():
		_next_roam()
		return
	if not _move_to(_roam["pos"], WALK_SPEED, delta):
		return
	var room: String = _roam["room"]
	if room != "" and Game.director.wants_to_enter_room(room):
		_search = Game.director.room_search_points(room)
		_roam = {}
		_set_state(State.SEARCH)
		if Game.player and Game.player.global_position.distance_to(global_position) < 12.0:
			Game.play_sound("growl", 0.4)
	else:
		_next_roam()


## Neues Ziel irgendwo im Hotel.
func _next_roam() -> void:
	_roam = Game.director.next_roam_target(global_position)
	_set_state(State.PATROL)


## Bleibt verborgen: Sieht der Spieler es (und jagt es nicht), verschwindet es aus dem Blick.
func _check_seen(delta: float) -> void:
	var p := Game.player
	if p == null or p.dead or noticed:
		_seen_timer = 0.0
		return
	var head := global_position + Vector3.UP * 1.6
	if head.distance_to(p.camera.global_position) > 6.0 and Game.director.player_can_see(head):
		_seen_timer += delta
		if _seen_timer > SEEN_BEFORE_SLINK:
			_seen_timer = 0.0
			_target = Game.director.hidden_point_near(global_position)
			_set_state(State.SLINK)
	else:
		_seen_timer = maxf(0.0, _seen_timer - delta)


func _start_chase(actor) -> void:
	if state != State.CHASE:
		Game.play_sound("sting", 0.8)
	_chase_target = actor
	_eye_mat.set_shader_parameter("emission_energy", 3.0)
	_last_seen = actor.global_position
	_lose_timer = 0.0
	_set_state(State.CHASE)


func _chase_step(seen, delta: float) -> void:
	if seen != null:
		_chase_target = seen
		_last_seen = seen.global_position
		_lose_timer = 0.0
	else:
		_lose_timer += delta
	if _lose_timer > 3.5:
		_start_search(_last_seen)
		return
	_move_to(_last_seen, CHASE_SPEED, delta)
	if seen != null and global_position.distance_to(seen.global_position) < KILL_DISTANCE:
		_kill(seen, null)


func _start_search(center: Vector3) -> void:
	_eye_mat.set_shader_parameter("emission_energy", 1.2)
	_chase_target = null
	_search = Game.director.search_points_near(center)
	_set_state(State.SEARCH)


func _start_retreat() -> void:
	_calm_retreat = false
	_target = Game.director.retreat_point(global_position)
	_set_state(State.RETREAT)


## Ist es weit genug weg und außer Sicht, löst es sich einfach in der Dunkelheit auf.
func _can_vanish() -> bool:
	var p := Game.player
	if p == null:
		return true
	return global_position.distance_to(p.global_position) > 14.0 \
		and not Game.director.player_can_see(global_position + Vector3.UP * 1.2)


func _search_step(delta: float) -> void:
	if _search.is_empty():
		_next_roam()
		return
	var point := _search[0]
	if _move_to(point["pos"], SEARCH_SPEED, delta):
		var spot: HideSpot = point["spot"]
		if spot != null:
			_hide_target = spot
			_set_state(State.CHECK_HIDE)
			Game.play_sound("growl", 0.8)
		else:
			_idle_timer += delta
			if _idle_timer > 1.2:
				_idle_timer = 0.0
				_search.pop_front()


## Vor einem Versteck stehen, schnüffeln – und mit etwas Pech die Tür aufreißen.
func _check_hide_step(delta: float) -> void:
	_stop(delta)
	if _hide_target == null:
		_set_state(State.SEARCH)
		return
	_face(_hide_target.global_position, delta)
	var occupant = _hide_target.occupant
	if occupant != null and _hide_target.seen_entering and _state_timer > 0.4:
		_kill(occupant, _hide_target)
		return
	if _state_timer > 2.2:
		var spot := _hide_target
		_hide_target = null
		spot.set_checked(true)   # Spur: offene Schranktür / zerwühltes Bett
		if not _search.is_empty():
			_search.pop_front()
		_set_state(State.SEARCH)
		if occupant != null:
			var chance := clampf(Game.director.effective_boldness() / 140.0, 0.1, 0.65)
			if occupant.holding_breath:
				chance *= 0.35
			if randf() < chance:
				_kill(occupant, spot)


func _kill(actor, spot: HideSpot) -> void:
	if actor == Game.player:
		Game.director.kill_player(spot)
	else:
		Game.director.kill_guest(actor, spot)


## Deko + Licht vor dem Monster stärker als sein Druck → es kommt nicht weiter.
func _check_deterrence(delta: float) -> void:
	if not (state in [State.PATROL, State.INVESTIGATE, State.SEARCH, State.CHASE]):
		return
	_deter_timer -= delta
	if _deter_timer > 0.0:
		return
	_deter_timer = 0.25
	var ahead := global_position + (-global_transform.basis.z) * 0.9
	if not Game.director.is_blocked(ahead, state == State.CHASE):
		return
	# Deko schützt nur, wer drinsteht (4.12): Steht der Gejagte außerhalb des Schutzes,
	# geht das Monster durch die Deko hindurch.
	if state == State.CHASE and _chase_target != null and is_instance_valid(_chase_target) 			and not Game.director.is_protected(_chase_target.global_position):
		return
	Game.director.on_monster_repelled()
	if not _scratched and Game.traces:
		_scratched = Game.traces.scratch_wall_ahead(self)
	if state == State.CHASE:
		Game.play_sound("growl", 0.7)
		_set_state(State.REPELLED)
	else:
		_lurk_count += 1
		_search.clear()
		_set_state(State.LURK)


func _open_doors() -> void:
	for node in get_tree().get_nodes_in_group("doors"):
		var door := node as Door
		if door.is_open or not door.monster_can_open:
			continue
		if door.center().distance_to(global_position + Vector3.UP) < 1.5:
			door.monster_open()
			if Game.traces and randf() < 0.6:
				Game.traces.add_door_scratch(door, global_position)


# --- Spuren --------------------------------------------------------------------

## Fußspuren, ausgehende Kerzen, Handabdrücke am Milchglas (Spielkonzept 4.13).
func _update_traces(delta: float) -> void:
	var moved := Vector2(velocity.x, velocity.z).length() * delta
	_step_dist += moved
	if _step_dist >= STEP_LENGTH and Game.traces and is_on_floor():
		_step_dist = 0.0
		_foot_side = -_foot_side
		var side := global_transform.basis.x * 0.13 * _foot_side
		Game.traces.add_footprint(global_position + side, rotation.y)
	_trace_timer -= delta
	if _trace_timer > 0.0:
		return
	_trace_timer = 0.4
	for node in get_tree().get_nodes_in_group("items"):
		var item := node as Item
		if item.lit and not item.is_held and item.global_position.distance_to(global_position) < CANDLE_RANGE:
			item.blow_out()
	for node in get_tree().get_nodes_in_group("windows"):
		var win := node as HotelWindow
		if not win.frosted or win in _handprinted:
			continue
		var outside := win.global_transform * Vector3(0, 0, -0.5)
		if Vector2(outside.x - global_position.x, outside.z - global_position.z).length() < HANDPRINT_RANGE:
			_handprinted.append(win)
			if randf() < HANDPRINT_CHANCE and Game.traces:
				Game.traces.add_handprint(win)


# --- Bewegung -------------------------------------------------------------------

func _move_to(point: Vector3, speed: float, delta: float) -> bool:
	if agent.target_position.distance_to(point) > 0.25:
		agent.target_position = point
	var flat := Vector3(point.x, global_position.y, point.z)
	if global_position.distance_to(flat) < 0.7 or agent.is_navigation_finished():
		_stop(delta)
		return true
	var next := agent.get_next_path_position()
	var dir := next - global_position
	dir.y = 0.0
	if dir.length() > 0.01:
		dir = dir.normalized()
		rotation.y = lerp_angle(rotation.y, atan2(-dir.x, -dir.z), minf(1.0, 8.0 * delta))
	velocity.x = dir.x * speed
	velocity.z = dir.z * speed
	_apply_gravity(delta)
	move_and_slide()
	# Festgefahren (z. B. an einer Türkante)? Seitlich ausweichen, Weg neu berechnen.
	if global_position.distance_to(_last_pos) < speed * delta * 0.2:
		_stuck_time += delta
		if _stuck_time > 0.6:
			_stuck_time = 0.0
			global_position += Vector3(-dir.z, 0, dir.x) * (0.15 if randf() < 0.5 else -0.15)
			agent.target_position = point + Vector3(0.01, 0, 0)
	else:
		_stuck_time = 0.0
	_last_pos = global_position
	return false


func _stop(delta: float) -> void:
	velocity.x = 0.0
	velocity.z = 0.0
	_apply_gravity(delta)
	move_and_slide()


func _face(pos: Vector3, delta: float) -> void:
	var to := pos - global_position
	if Vector2(to.x, to.z).length() < 0.01:
		return
	rotation.y = lerp_angle(rotation.y, atan2(-to.x, -to.z), minf(1.0, 6.0 * delta))


func _apply_gravity(delta: float) -> void:
	if is_on_floor():
		velocity.y = 0.0
	else:
		velocity.y -= _gravity * delta


# --- Aussehen ----------------------------------------------------------------------

func _build_visual() -> void:
	_visual = Node3D.new()
	add_child(_visual)
	var skin := Mat.psx(Color(0.02, 0.02, 0.025))
	_eye_mat = Mat.psx(Color(1, 1, 1), "", 1.0, Color(0.9, 0.85, 0.7), 1.2, false)
	for side in [-1.0, 1.0]:
		Geo.mesh(_visual, Geo.box(Vector3(0.07, 0.86, 0.07)), skin, Vector3(side * 0.1, 0.43, 0))
	var torso := Geo.mesh(_visual, Geo.box(Vector3(0.3, 0.78, 0.16)), skin, Vector3(0, 1.22, -0.03))
	torso.rotation.x = -0.12
	_arm_l = _make_arm(-1.0, skin)
	_arm_r = _make_arm(1.0, skin)
	_head = Node3D.new()
	_head.position = Vector3(0, 1.72, -0.08)
	_visual.add_child(_head)
	Geo.mesh(_head, Geo.sphere(0.13, 0.3, 6, 4), skin, Vector3(0, 0.13, 0))
	for side in [-1.0, 1.0]:
		Geo.mesh(_head, Geo.sphere(0.022, 0.03, 4, 2), _eye_mat, Vector3(side * 0.05, 0.16, -0.115))
	_face_light = OmniLight3D.new()
	_face_light.position = Vector3(0, 1.85, -0.6)
	_face_light.light_color = Color(0.75, 0.8, 1.0)
	_face_light.omni_range = 1.6
	_face_light.light_energy = 0.0
	add_child(_face_light)


func _make_arm(side: float, mat: Material) -> Node3D:
	var pivot := Node3D.new()
	pivot.position = Vector3(side * 0.2, 1.55, -0.03)
	pivot.rotation.z = side * 0.08
	_visual.add_child(pivot)
	Geo.mesh(pivot, Geo.box(Vector3(0.05, 1.1, 0.05)), mat, Vector3(0, -0.55, 0))
	for i in 3:
		Geo.mesh(pivot, Geo.box(Vector3(0.012, 0.16, 0.012)), mat, Vector3((i - 1) * 0.018, -1.17, 0))
	return pivot


func _animate(delta: float) -> void:
	_anim_time += delta
	_anim_step += delta
	if _anim_step < 0.09:
		return
	_anim_step = 0.0
	if state == State.KILL:
		_head.rotation.z = 0.3 + randf_range(-0.25, 0.25)
	else:
		var speed := Vector2(velocity.x, velocity.z).length()
		var swing := sin(_anim_time * (1.5 + speed * 2.2)) * clampf(speed * 0.35, 0.05, 0.9)
		_arm_l.rotation.x = swing + randf_range(-0.06, 0.06)
		_arm_r.rotation.x = -swing + randf_range(-0.06, 0.06)
		_head.rotation.z = sin(_anim_time * 0.6) * 0.3 + randf_range(-0.1, 0.1)
		_head.rotation.x = randf_range(-0.05, 0.1)
	_visual.rotation.z = sin(_anim_time * 1.1) * 0.05
