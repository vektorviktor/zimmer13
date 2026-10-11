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
const EYE_HEIGHT := 2.1            ## Augenhöhe im Modell (aufrecht)
## Modell aus tools/build_monster.py: aufrecht als Grundpose, die Hocke als Animation „crouch“
const MODEL := "res://assets/models/monster.glb"
const EYES: Array[Vector3] = [Vector3(-0.068, 2.1, -0.6), Vector3(0.068, 2.1, -0.6)]
const ANIM_STEP := 0.09            ## Stop-Motion: so oft wird eine neue Pose gesetzt
const LEG_LENGTH := 1.25
## Sichtlinie: Wände, Türen, Vorhänge und Milchglas (klares Glas lässt den Blick durch).
## Sichtweiten stehen in Senses (Spielkonzept 4.15).
const SIGHT_MASK := Senses.SIGHT_MASK

var state := State.INACTIVE
var noticed := false
var agent: NavigationAgent3D

var _collider: CollisionShape3D
var _visual: Node3D
var _skeleton: Skeleton3D
var _bone := {}                         ## Knochenname → Index
var _rest: Array[Quaternion] = []       ## aufrecht
var _crouch_rot: Array[Quaternion] = [] ## Hocke
var _rot: Array[Quaternion] = []        ## Pose, die gerade gebaut wird
var _rest_hips := Vector3.ZERO
var _crouch_hips := Vector3.ZERO
var _crouch := 0.0                      ## 0 = aufrecht, 1 = auf allen Vieren
var _gait := 0.0                        ## Schrittphase
var _near_door := false                 ## unter dem Türsturz (2,1 m) ducken
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
var _fleeing := false           ## vom UV-Licht vertrieben: rennt in den Keller (4.16)
var _uv_slow := 0.0             ## steht im UV-Kegel: zögert, wird langsamer
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
	# Kollision und Wegfindung bleiben 1,6 m hoch – durch Türen kommt es geduckt.
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
	# Auf dem Boden, vorgebeugt – dann ruckartig mit dem Kopf auf die Kamera zu
	var base := Vector3(cam.global_position.x, cam.global_position.y - 1.7, cam.global_position.z)
	global_position = base + forward * 2.2
	rotation = Vector3(0, atan2(forward.x, forward.z), 0)
	_eye_mat.set_shader_parameter("emission_energy", 8.0)
	_face_light.light_energy = 1.4
	_crouch = 0.0
	_anim_step = ANIM_STEP
	create_tween().tween_property(self, "global_position", base + forward * 0.8, 0.22).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
	Game.shot_event("jumpscare", 12)


## Kann UV-Licht es gerade vertreiben? (nicht beim Holen, nicht schon auf dem Rückzug)
func can_be_repelled_by_uv() -> bool:
	return state in [State.PATROL, State.INVESTIGATE, State.LURK, State.STARE, State.SEARCH,
		State.CHECK_HIDE, State.CHASE, State.SLINK]


## Steht im UV-Kegel: zögert kurz.
func uv_flinch() -> void:
	_uv_slow = 0.2


## UV hat es vertrieben: zurückzucken, dann fliehen – ohne unterwegs jemanden zu jagen.
func uv_repel() -> void:
	_chase_target = null
	_hide_target = null
	_search.clear()
	_fleeing = true
	_eye_mat.set_shader_parameter("emission_energy", 0.3)
	Game.play_sound("growl", 1.0)
	Game.caption("[Ein Kreischen]")
	_set_state(State.REPELLED)


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
	_crouch = 0.0
	_anim_step = ANIM_STEP
	Game.shot_event("reveal")


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
	_fleeing = false
	_uv_slow = 0.0
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


## Sichtweite = 8 m × Auffälligkeit, Kegel ca. 145°; während der Jagd +5 m ohne Kegel
## (Spielkonzept 4.12, 4.15). `at`: Stelle vor einem Versteck – gesehen wird das Hineingehen.
func can_see_actor(actor, at: Vector3 = Vector3.INF) -> bool:
	var entering := at != Vector3.INF
	if actor == null or not is_instance_valid(actor) or actor.dead or (actor.hiding != null and not entering):
		return false
	var chasing := state == State.CHASE
	return Senses.can_see(self, global_position + Vector3.UP * EYE_HEIGHT, -global_transform.basis.z,
		Senses.MONSTER_SIGHT, -2.0 if chasing else Senses.MONSTER_FOV_DOT, actor,
		Senses.CHASE_SIGHT_BONUS if chasing else 0.0, entering, at)


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
	_uv_slow = maxf(0.0, _uv_slow - delta)
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
			if _state_timer > (0.5 if _fleeing else 1.6):
				_start_retreat()
				_calm_retreat = _fleeing
		State.RETREAT:
			# Kein sicherer Rückzug (4.12): Wen es sieht, den jagt es wieder – außer es ist satt
			# oder der Gesehene steht im Schutz von Deko und Licht. Nach einem harmlosen Schreck
			# verschwindet es einfach – sonst erschreckt es denselben Gast immer wieder.
			if seen != null and not _calm_retreat and Game.director.satiation <= 0.0 and not Game.director.is_protected(seen.global_position):
				_start_chase(seen)
			elif _move_to(_target, CHASE_SPEED if _fleeing else SEARCH_SPEED, delta) or _state_timer > 30.0 or _can_vanish():
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
	_near_door = false
	for node in get_tree().get_nodes_in_group("doors"):
		var door := node as Door
		if door.center().distance_to(global_position + Vector3.UP) >= 1.5:
			continue
		_near_door = true
		if door.is_open or not door.monster_can_open:
			continue
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
	var near := Vector2(point.x - global_position.x, point.z - global_position.z).length() < 0.7 		and absf(point.y - global_position.y) < 1.5
	if near or agent.is_navigation_finished():
		_stop(delta)
		return true
	var next := agent.get_next_path_position()
	var dir := next - global_position
	dir.y = 0.0
	if dir.length() > 0.01:
		dir = dir.normalized()
		rotation.y = lerp_angle(rotation.y, atan2(-dir.x, -dir.z), minf(1.0, 8.0 * delta))
	if _uv_slow > 0.0:
		speed *= 0.35
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
	_visual = (load(MODEL) as PackedScene).instantiate()
	add_child(_visual)
	_skeleton = _visual.find_children("*", "Skeleton3D", true, false)[0]
	for i in _skeleton.get_bone_count():
		_bone[_skeleton.get_bone_name(i)] = i
		_rest.append(_skeleton.get_bone_rest(i).basis.get_rotation_quaternion())
	_crouch_rot = _rest.duplicate()
	_rot = _rest.duplicate()
	_rest_hips = _skeleton.get_bone_rest(_bone["hips"]).origin
	_crouch_hips = _rest_hips
	# Die Hocke wird nur als Pose gelesen, nicht abgespielt.
	var player: AnimationPlayer = _visual.find_children("*", "AnimationPlayer", true, false)[0]
	var crouch := player.get_animation("crouch")
	for t in crouch.get_track_count():
		var i: int = _bone[String(crouch.track_get_path(t).get_subname(0))]
		match crouch.track_get_type(t):
			Animation.TYPE_ROTATION_3D:
				_crouch_rot[i] = crouch.track_get_key_value(t, 0)
			Animation.TYPE_POSITION_3D:
				if i == _bone["hips"]:
					_crouch_hips = crouch.track_get_key_value(t, 0)
	player.queue_free()

	var mesh: MeshInstance3D = _visual.find_children("*", "MeshInstance3D", true, false)[0]
	var skin := Mat.psx(Color(0.55, 0.55, 0.6), "", 1.0, Color.BLACK, 0.0, false)
	skin.set_shader_parameter("albedo_tex", (mesh.get_active_material(0) as BaseMaterial3D).albedo_texture)
	mesh.material_override = skin
	_eye_mat = Mat.psx(Color(1, 1, 1), "", 1.0, Color(0.9, 0.85, 0.7), 1.2, false)
	var head := BoneAttachment3D.new()
	head.bone_name = "head"
	_skeleton.add_child(head)
	var head_rest := _skeleton.get_bone_global_rest(_bone["head"])
	for eye in EYES:
		Geo.mesh(head, Geo.sphere(0.016, 0.022, 4, 2), _eye_mat, head_rest.affine_inverse() * eye)
	_face_light = OmniLight3D.new()
	_face_light.position = Vector3(0, 1.9, -1.3)
	_face_light.light_color = Color(0.75, 0.8, 1.0)
	_face_light.omni_range = 1.6
	_face_light.light_energy = 0.0
	add_child(_face_light)


## Dreht einen Knochen um eine Achse im Modellraum (X = seitlich, Y = oben, −Z = vorn).
## Positiver Winkel um X: hängende Glieder nach vorn, Oberkörper nach hinten.
## Eltern vor Kindern drehen.
func _turn(bone: String, axis: Vector3, angle: float) -> void:
	var i: int = _bone[bone]
	var parent_rot := Quaternion.IDENTITY
	var p := _skeleton.get_bone_parent(i)
	while p >= 0:
		parent_rot = _rot[p] * parent_rot
		p = _skeleton.get_bone_parent(p)
	_rot[i] = Quaternion((parent_rot.inverse() * axis).normalized(), angle) * _rot[i]


## Wie tief es geht: schleichend auf allen Vieren, lauernd halb geduckt, sonst aufrecht.
func _crouch_target() -> float:
	var c := 0.0
	match state:
		State.SLINK:
			c = 0.6
		State.LURK, State.CHECK_HIDE:
			c = 0.4
		State.SEARCH:
			c = 0.15
		State.KILL, State.REVEAL:
			return 0.0
	return maxf(c, 0.3) if _near_door else c


## Pose aus aufrecht ↔ Hocke mischen, dann Gang, Haltung, Kopf und Kiefer daraufsetzen.
func _animate(delta: float) -> void:
	_anim_time += delta
	_anim_step += delta
	if _anim_step < ANIM_STEP:
		return
	var dt := _anim_step
	_anim_step = 0.0
	var speed := Vector2(velocity.x, velocity.z).length()
	_crouch = move_toward(_crouch, _crouch_target(), dt * 2.5)
	_gait = fmod(_gait + dt * speed * PI / STEP_LENGTH, TAU)
	for i in _rot.size():
		_rot[i] = _rest[i].slerp(_crouch_rot[i], _crouch)
	var hips := _rest_hips.lerp(_crouch_hips, _crouch)

	var amp := clampf(speed * 0.2, 0.0, 0.55)
	var s := sin(_gait)
	var lean := 0.0    # vorbeugen
	var reach := 0.0   # Arme nach vorn
	var nod := randf_range(-0.05, 0.1)
	var tilt := sin(_anim_time * 0.6) * 0.3 + randf_range(-0.1, 0.1)
	var jaw := 0.05 + sin(_anim_time * 1.7) * 0.04 + randf_range(0.0, 0.04)
	match state:
		State.CHASE:
			lean = 0.3
			reach = 0.6
			jaw += 0.1
		State.KILL:
			lean = 0.5
			reach = 1.3
			nod = 0.2
			tilt = 0.3 + randf_range(-0.25, 0.25)
			jaw = 0.4 + randf_range(-0.05, 0.05)
		State.REVEAL, State.STARE, State.LURK:
			nod = 0.3
			tilt = sin(_anim_time * 0.4) * 0.45 + randf_range(-0.04, 0.04)
		State.REPELLED:
			lean = -0.2
			reach = 0.5
			tilt = randf_range(-0.4, 0.4)

	# Rumpf
	_turn("hips", Vector3.UP, s * amp * 0.3)
	hips.y -= LEG_LENGTH * (1.0 - cos(s * amp)) * (1.0 - _crouch)
	_turn("spine", Vector3.RIGHT, -lean * 0.5)
	_turn("chest", Vector3.RIGHT, -lean * 0.5 + randf_range(-0.03, 0.03))
	_turn("chest", Vector3.UP, -s * amp * 0.4)
	_turn("neck", Vector3.RIGHT, -nod * 0.5)
	_turn("head", Vector3.BACK, tilt)
	_turn("head", Vector3.RIGHT, -nod * 0.5)
	_turn("jaw", Vector3.RIGHT, -jaw)
	_turn("tongue1", Vector3.UP, sin(_anim_time * 2.3) * 0.25)
	_turn("tongue2", Vector3.RIGHT, sin(_anim_time * 3.1) * 0.3)
	# Arme gegengleich zu den Beinen, Beine heben den Fuß beim Vorschwingen
	for side in [["L", 1.0], ["R", -1.0]]:
		var n: String = side[0]
		var dir: float = side[1]
		_turn("upperarm." + n, Vector3.RIGHT, reach - s * dir * amp * 0.7 + randf_range(-0.06, 0.06))
		_turn("forearm." + n, Vector3.RIGHT, reach * 0.3 + randf_range(0.0, 0.12))
		_turn("hand." + n, Vector3.RIGHT, randf_range(-0.1, 0.1))
		var lift := maxf(0.0, cos(_gait) * dir) * amp
		_turn("thigh." + n, Vector3.RIGHT, s * dir * amp + lift * 0.3)
		_turn("shin." + n, Vector3.RIGHT, -lift * 1.4)
		_turn("foot." + n, Vector3.RIGHT, lift * 0.8)

	for i in _rot.size():
		_skeleton.set_bone_pose_rotation(i, _rot[i])
	_skeleton.set_bone_pose_position(_bone["hips"], hips)
	_visual.rotation.z = sin(_anim_time * 1.1) * 0.03
