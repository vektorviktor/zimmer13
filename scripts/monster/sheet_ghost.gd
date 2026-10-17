class_name SheetGhost
extends Node3D
## Der Lakengeist am Fenster (Spielkonzept 4.18). Er kommt, wenn man einen Raum mit Außenfenster betritt,
## in dem das Licht aus und der Vorhang offen ist – und wird mit jedem Mal dreister:
##   1. schwebt kurz heran · 2. fasst die Scheibe an (blutige Handabdrücke) und hypnotisiert mit kreisenden
##   Händen · 3. kommt herein und würgt · ab dem 4. Mal kommt er immer herein, auch durch den Vorhang.
## Wer gewürgt wird, reißt sich nur los, indem er sich hin und her bewegt (1,5 s). Gäste als Zeugen
## vertreiben ihn. Verschwinden: in 0,5 s ausgeblendet. Ab dem 6. Mal taucht er auch im Flur auf, wenn alle
## Gäste schlafen (Nachtruhe, Social) – dann gibt es keine Zeugen.

enum State { IDLE, APPROACH, HOVER, ENTER, STRANGLE, FADE }

const MODEL := "res://assets/models/ghost.glb"

# --- Tuning -------------------------------------------------------------------
const SPAWN_CHANCE := 0.7             ## beim Betreten eines dunklen Raums mit offenem Vorhang
const COOLDOWN := 90.0                ## frühestens wieder nach so vielen Sekunden
const CHECK_EVERY := 0.5
const WINDOW_RANGE := 7.0             ## so nah am Fenster (und mit freier Sicht darauf) muss man sein
const START_DISTANCE := 7.0           ## so weit draußen taucht er auf
const STOP_OUTSIDE := 1.4             ## 1. Mal: bleibt so weit vor der Scheibe
const STOP_AT_GLASS := 0.32           ## ab dem 2. Mal: Hände an der Scheibe
const FLOAT_SPEED := 1.1
const INSIDE_SPEED := 0.8
const HOVER_TIME := [1.5, 4.5, 1.2]   ## 1. Mal, 2. Mal, ab 3. Mal (dann kommt er herein)
const APPEAR_TIME := 0.8
const FADE_TIME := 0.5
const HYPNOSIS_FROM := 2
const ENTER_FROM := 3
const THROUGH_CURTAIN_FROM := 4
const TRANCE_GAIN := 0.35             ## Hypnose je Sekunde, solange man ihn ansieht
const TRANCE_DECAY := 0.25
const PULL := 0.9                     ## Blickzug (rad/s) bei voller Hypnose
const GRIP_RANGE := 0.7
const ESCAPE_TIME := 1.5
const ESCAPE_SWINGS := 3              ## so oft muss man die Richtung wechseln, um sich loszureißen
const WITNESSES := 1                  ## so viele wache Gäste mit Blick auf ihn vertreiben ihn
const WITNESS_RANGE := 12.0
const LEAVE_RANGE := 14.0             ## so weit weg vom Fenster (bzw. von ihm) gibt er auf
## Flur: ab diesem Mal, Chance je Sekunde im dunklen Flur, wenn alle schlafen; Abstand beim Auftauchen
const HALL_FROM := 6
const HALL_CHANCE := 0.04
const HALL_DISTANCE := Vector2(8.0, 16.0)
## Modell: Handgelenke so hoch über dem Ursprung, Hände so weit vor der Mitte
const HANDS_Y := 1.12
const HANDS_AHEAD := 0.45
const NECK_BELOW_EYES := 0.22
const FINGERS := ["thumb", "index", "middle", "ring", "pinky"]

var visits := 0          ## so oft ist er schon erschienen (Stufe)
var state := State.IDLE

var _window: HotelWindow
var _last_window: HotelWindow
var _cooldown := 0.0
var _check := 0.0
var _timer := 0.0
var _time := 0.0
var _fade := 0.0
var _target := Vector3.ZERO
var _swings := 0
var _last_sign := 0
var _force := false
var _force_hall := false
var _material: ShaderMaterial
var _skeleton: Skeleton3D
var _bone := {}
var _rest := {}


func _ready() -> void:
	var visual: Node3D = (load(MODEL) as PackedScene).instantiate()
	add_child(visual)
	_skeleton = visual.find_children("*", "Skeleton3D", true, false)[0]
	for i in _skeleton.get_bone_count():
		_bone[_skeleton.get_bone_name(i)] = i
		_rest[i] = _skeleton.get_bone_rest(i).basis.get_rotation_quaternion()
	var mesh: MeshInstance3D = visual.find_children("*", "MeshInstance3D", true, false)[0]
	_material = ShaderMaterial.new()
	_material.shader = load("res://shaders/psx_ghost.gdshader")
	_material.set_shader_parameter("albedo", Color(0.85, 0.85, 0.9))
	_material.set_shader_parameter("albedo_tex", (mesh.get_active_material(0) as BaseMaterial3D).albedo_texture)
	mesh.material_override = _material
	mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_hide()


func is_active() -> bool:
	return state != State.IDLE


func _physics_process(delta: float) -> void:
	var player := Game.player
	if player == null:
		return
	_time += delta
	_cooldown = maxf(0.0, _cooldown - delta)
	if state == State.IDLE:
		player.trance = maxf(0.0, player.trance - TRANCE_DECAY * delta)
		_check -= delta
		if _check <= 0.0:
			_check = CHECK_EVERY
			_check_spawn()
		return
	if Game.game_over:
		return
	if state != State.FADE and (_witnesses() >= WITNESSES or player.hiding != null or player.dead):
		_vanish()
	match state:
		State.APPROACH:
			if _float_to(_target, FLOAT_SPEED, delta):
				if visits >= HYPNOSIS_FROM and _window:
					_touch_glass()
				state = State.HOVER
				_timer = HOVER_TIME[mini(visits, 3) - 1]
		State.HOVER:
			_timer -= delta
			if _timer <= 0.0:
				if visits >= ENTER_FROM:
					state = State.ENTER
				else:
					_vanish()
		State.ENTER:
			var neck := player.camera.global_position - Vector3(0, NECK_BELOW_EYES, 0)
			var flat := Vector3(neck.x - global_position.x, 0, neck.z - global_position.z)
			var spot := Vector3(neck.x, neck.y - HANDS_Y, neck.z) - flat.normalized() * HANDS_AHEAD
			_face(flat)
			if _float_to(spot, INSIDE_SPEED, delta, false) or flat.length() < HANDS_AHEAD + GRIP_RANGE:
				_grab()
			elif player.global_position.distance_to(_window.global_position if _window else global_position) > LEAVE_RANGE + (0.0 if _window else 6.0):
				_vanish()
		State.STRANGLE:
			_struggle(delta)
		State.FADE:
			_fade = maxf(0.0, _fade - delta / FADE_TIME)
			if _fade <= 0.0:
				_hide()
				return
	if state in [State.APPROACH, State.HOVER, State.ENTER] and _fade < 1.0:
		_fade = minf(1.0, _fade + delta / APPEAR_TIME)
	_material.set_shader_parameter("fade", _fade)
	_update_trance(delta)
	_pose()


# --- Erscheinen ---------------------------------------------------------------------------

## Betritt der Spieler einen dunklen Raum mit Außenfenster (Vorhang offen – ab dem 4. Mal egal),
## würfelt es einmal. Erst nach dem ersten Angriff des Monsters (friedlicher Anfang, 2.1).
func _check_spawn() -> void:
	var player := Game.player
	var director := Game.director
	if director == null or player.dead or player.hiding != null or player.in_dialog or Game.game_over:
		return
	if not director.first_attack_done and not (_force or _force_hall):
		return
	if _check_hall(player):
		return
	var window := _window_near(player)
	if window != _last_window:
		_last_window = window
		if window == null or (_cooldown > 0.0 and not _force) or director.player_threat > 0.0:
			return
		if _witnesses_at(player.camera.global_position) >= WITNESSES:   # in Gesellschaft kommt er nicht
			return
		if _force or randf() < SPAWN_CHANCE:
			_force = false
			_appear(window)


## Ab dem 6. Mal: Schlafen alle Gäste und steht der Spieler im Flur, taucht er dort mit kleiner Chance
## je Sekunde auf – irgendwo vor oder hinter ihm, wo er gerade nicht hinsieht.
func _check_hall(player: Player) -> bool:
	if visits + 1 < HALL_FROM or Game.social == null or not Game.social.all_asleep():
		return false
	if not "Flur" in Game.director.zone_name_at(player.global_position):
		return false
	if not _force_hall and (_cooldown > 0.0 or Game.director.player_threat > 0.0 or randf() >= HALL_CHANCE * CHECK_EVERY):
		return false
	var spots: Array[Vector3] = []
	for entry in Game.director.patrol:
		var p: Vector3 = entry["pos"]
		var d := p.distance_to(player.global_position)
		if absf(p.y - player.global_position.y) < 1.5 and d >= HALL_DISTANCE.x and d <= HALL_DISTANCE.y \
				and "Flur" in Game.director.zone_name_at(p) and not Game.director.player_can_see(p + Vector3.UP * 1.2):
			spots.append(p)
	if spots.is_empty():
		return false
	_force_hall = false
	_appear_in_hall(spots[randi() % spots.size()])
	return true


func _appear_in_hall(floor_point: Vector3) -> void:
	visits += 1
	_window = null
	_last_window = null
	var neck := Game.player.camera.global_position.y - NECK_BELOW_EYES
	global_position = Vector3(floor_point.x, neck - HANDS_Y, floor_point.z)
	_face(Game.player.global_position - global_position)
	visible = true
	_fade = 0.0
	state = State.ENTER
	Game.caption("[Kälte im Flur]")
	if "--trace" in OS.get_cmdline_user_args():
		print("[Lakengeist] %d. Mal – im Flur" % visits)


func _window_near(player: Player) -> HotelWindow:
	var eye := player.camera.global_position
	var space := get_world_3d().direct_space_state
	for node in get_tree().get_nodes_in_group("windows"):
		var window := node as HotelWindow
		if not window.has_curtains() or (window.closed and visits + 1 < THROUGH_CURTAIN_FROM):
			continue
		var inside := window.inside_point()
		if inside.distance_to(eye) > WINDOW_RANGE or absf(inside.y - eye.y) > 2.0 or not _room_dark(window.room_id):
			continue
		var query := PhysicsRayQueryParameters3D.create(inside, eye, Senses.SIGHT_MASK & ~HotelWindow.LAYER_BLOCK)
		if space.intersect_ray(query).is_empty():
			return window
	return null


func _room_dark(room_id: String) -> bool:
	for node in get_tree().get_nodes_in_group("lamp_fixtures"):
		var lamp := node as Lamp
		if lamp.room_id == room_id and lamp.is_lit():
			return false
	return true


func _appear(window: HotelWindow) -> void:
	visits += 1
	_window = window
	var outward := window.global_transform.basis.z.normalized() * -1.0
	var base := window.global_position - Vector3(0, HANDS_Y, 0)
	visible = true
	_fade = 0.0
	_swings = 0
	_last_sign = 0
	_face(-outward)
	if window.closed:   # ab dem 4. Mal: hinter dem Vorhang, gleich herein
		global_position = base + outward * STOP_AT_GLASS
		state = State.ENTER
	else:
		global_position = base + outward * START_DISTANCE
		_target = base + outward * (STOP_OUTSIDE if visits < HYPNOSIS_FROM else STOP_AT_GLASS)
		state = State.APPROACH
	Game.caption("[Etwas schwebt vor dem Fenster]")
	if "--trace" in OS.get_cmdline_user_args():
		print("[Lakengeist] %d. Mal am Fenster (%s)" % [visits, window.room_id])


## Ab dem 2. Mal: blutige Handabdrücke außen auf der Scheibe.
func _touch_glass() -> void:
	Game.play_sound("thud", 0.4)
	if Game.traces:
		Game.traces.add_window_handprints(_window)


# --- Würgen -----------------------------------------------------------------------------

func _grab() -> void:
	state = State.STRANGLE
	_timer = ESCAPE_TIME
	_swings = 0
	_last_sign = 0
	Game.player.gripped = true
	Game.play_sound("gasp", 0.8)
	Game.caption("[Kalte Hände um deinen Hals – reiß dich los!]")
	Game.say("Beweg dich! Hin und her!", ESCAPE_TIME)
	Game.shot_event("strangle", 20)


## Losreißen: Die Bewegungsrichtung muss ESCAPE_SWINGS-mal wechseln, bevor die Zeit um ist.
func _struggle(delta: float) -> void:
	var player := Game.player
	var input: Vector2 = player.move_input
	var axis := input.x if absf(input.x) >= absf(input.y) else input.y
	var dir := 0 if absf(axis) < 0.5 else (1 if axis > 0.0 else -1)
	if dir != 0 and dir != _last_sign:
		if _last_sign != 0:
			_swings += 1
		_last_sign = dir
	if _swings >= ESCAPE_SWINGS:
		if "--trace" in OS.get_cmdline_user_args():
			print("[Lakengeist] losgerissen nach %.1f s" % (ESCAPE_TIME - _timer))
		player.add_shock(0.25, false)
		Game.say("Losgerissen!", 1.5)
		_vanish()
		return
	_timer -= delta
	if _timer <= 0.0:
		_kill()


func _kill() -> void:
	var player := Game.player
	if "--trace" in OS.get_cmdline_user_args():
		print("[Lakengeist] erwürgt")
	state = State.FADE   # bleibt sichtbar, bis der Sterbebildschirm kommt
	_fade = 1.0
	Game.game_over = true
	player.gripped = false
	player.dead = true
	if Game.hud:
		Game.hud.set_prompt("")
		Game.hud.visible = false
	Game.play_sound("scream", 1.0)
	Game.director.flash(1.4)
	await get_tree().create_timer(1.5).timeout
	Game.player_died.emit()


# --- Verschwinden & Zeugen ------------------------------------------------------------------

func _vanish() -> void:
	if Game.player:
		Game.player.gripped = false
	state = State.FADE
	_cooldown = COOLDOWN


func _hide() -> void:
	state = State.IDLE
	visible = false
	_fade = 0.0
	_window = null
	global_position = Vector3(0, -60, 0)
	if _material:
		_material.set_shader_parameter("fade", 0.0)


## Wache Gäste, die ihn sehen können.
func _witnesses() -> int:
	return _witnesses_at(global_position + Vector3.UP * HANDS_Y)


## Wache Gäste mit freier Sicht auf diesen Punkt.
func _witnesses_at(point: Vector3) -> int:
	if Game.social == null:
		return 0
	var count := 0
	var space := get_world_3d().direct_space_state
	for guest in Game.social.guests:
		if guest.dead or guest.hiding != null or guest.global_position.distance_to(point) > WITNESS_RANGE:
			continue
		var query := PhysicsRayQueryParameters3D.create(guest.global_position + Vector3.UP * 1.6, point, Senses.SIGHT_MASK)
		if space.intersect_ray(query).is_empty():
			count += 1
	return count


# --- Hypnose ----------------------------------------------------------------------------

## Ab dem 2. Mal: Solange man ihn ansieht, während er die Hände kreisen lässt, wird man langsamer und
## der Blick wird zu ihm gezogen. Beim Würgen hält er den Blick fest.
func _update_trance(delta: float) -> void:
	var player := Game.player
	var head := global_position + Vector3.UP * (HANDS_Y + 0.5)
	var hypnotizing := visits >= HYPNOSIS_FROM and state in [State.HOVER, State.ENTER] and _fade > 0.5
	if hypnotizing and Game.director.player_can_see(head):
		player.trance = minf(1.0, player.trance + TRANCE_GAIN * delta)
	else:
		player.trance = maxf(0.0, player.trance - TRANCE_DECAY * delta)
	var pull := PULL * player.trance
	if state == State.STRANGLE:
		pull = PULL * 2.0
	if pull <= 0.0:
		return
	var to := head - player.camera.global_position
	var want_yaw := atan2(-to.x, -to.z)
	player.rotation.y = rotate_toward(player.rotation.y, want_yaw, pull * delta)
	var want_pitch := atan2(to.y, Vector2(to.x, to.z).length())
	player.head.rotation.x = move_toward(player.head.rotation.x, want_pitch, pull * delta)


# --- Bewegung & Pose ----------------------------------------------------------------------

## Schwebt auf `to` zu; true, wenn angekommen.
func _float_to(to: Vector3, speed: float, delta: float, turn: bool = false) -> bool:
	var d := to - global_position
	if d.length() <= speed * delta:
		global_position = to
		return true
	global_position += d.normalized() * speed * delta
	if turn:
		_face(Vector3(d.x, 0, d.z))
	return false


## Blick (Modell-Vorderseite −Z) in Richtung `dir`.
func _face(dir: Vector3) -> void:
	if Vector2(dir.x, dir.z).length() > 0.01:
		rotation.y = atan2(-dir.x, -dir.z)


## Schweben, wehender Saum, kreisende Hände (Hypnose), gekrallte Finger (Würgen).
func _pose() -> void:
	var bob := sin(_time * 1.7) * 0.04
	_visual_offset(bob)
	_rotate("hem", Vector3.RIGHT, sin(_time * 1.3) * 0.08)
	_rotate("head", Vector3.FORWARD, sin(_time * 0.7) * 0.12)
	var circling := visits >= HYPNOSIS_FROM and state in [State.HOVER, State.ENTER]
	var gripping := state == State.STRANGLE
	for side in [".L", ".R"]:
		var phase := _time * 2.2 + (0.0 if side == ".L" else PI)
		var lift := 0.25 if gripping else 0.0
		var swirl_x := sin(phase) * 0.22 if circling else 0.0
		var swirl_z := cos(phase) * 0.22 if circling else 0.0
		_rotate2("upper_arm" + side, Vector3.RIGHT, swirl_x + lift, Vector3.BACK, swirl_z)
		_rotate("forearm" + side, Vector3.RIGHT, swirl_x * 0.6 + lift * 0.5)
		var curl := 0.35 if gripping else (-0.08 if state == State.HOVER and visits >= HYPNOSIS_FROM else 0.05 * sin(_time * 3.0 + phase))
		for finger in FINGERS:
			for g in [1, 2, 3]:
				_rotate("%s%d%s" % [finger, g, side], Vector3.RIGHT, curl * (0.6 if finger == "thumb" else 1.0))


func _visual_offset(y: float) -> void:
	_skeleton.get_parent_node_3d().position.y = y


func _rotate(bone_name: String, axis: Vector3, angle: float) -> void:
	var i: int = _bone.get(bone_name, -1)
	if i >= 0:
		_skeleton.set_bone_pose_rotation(i, _rest[i] * Quaternion(axis, angle))


func _rotate2(bone_name: String, axis_a: Vector3, a: float, axis_b: Vector3, b: float) -> void:
	var i: int = _bone.get(bone_name, -1)
	if i >= 0:
		_skeleton.set_bone_pose_rotation(i, _rest[i] * Quaternion(axis_a, a) * Quaternion(axis_b, b))


# --- Debug & Speichern ----------------------------------------------------------------------

## Debug (F6, --ghost=n): Licht in diesem Zimmer aus, Vorhänge auf (ab dem 4. Mal zu), beim nächsten
## Prüfen kommt er sicher – zum `stage`. Mal.
func debug_summon(stage: int, room_id: String) -> void:
	visits = maxi(0, stage - 1)
	_cooldown = 0.0
	_last_window = null
	_force = true
	var sw := LightSwitch.find(get_tree(), room_id)
	if sw:
		sw.set_on(false)
	for node in get_tree().get_nodes_in_group("windows"):
		var window := node as HotelWindow
		if window.room_id == room_id:
			window.set_closed(stage >= THROUGH_CURTAIN_FROM, true)
			var to := window.global_position - Game.player.global_position
			Game.player.rotation.y = atan2(-to.x, -to.z)


## Debug (F6, --ghost=flur): 6. Mal, alle Gäste sofort im Bett, er kommt gleich im Flur.
func debug_summon_hall() -> void:
	visits = maxi(visits, HALL_FROM - 1)
	_cooldown = 0.0
	_force_hall = true
	Game.social.start_sleep(true)


func save_state() -> Dictionary:
	return {"visits": visits, "cooldown": _cooldown}


func load_state(d: Dictionary) -> void:
	visits = int(d.get("visits", 0))
	_cooldown = float(d.get("cooldown", 0.0))
	if Game.player:
		Game.player.gripped = false
	_hide()
