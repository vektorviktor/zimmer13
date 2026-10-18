class_name SheetGhost
extends Node3D
## Der Lakengeist am Fenster (Spielkonzept 4.18). Er kommt, wenn man einen Raum mit Außenfenster betritt,
## in dem das Licht aus und der Vorhang offen ist – und wird mit jedem Mal dreister:
##   1. schwebt kurz heran · 2. fasst die Scheibe an (blutige Handabdrücke) und hypnotisiert mit kreisenden
##   Händen · 3. kommt herein und würgt · ab dem 4. Mal kommt er immer herein, auch durch den Vorhang.
## Wer gewürgt wird, reißt sich nur mit wildem Hin und Her los – der Griff zieht ständig zurück, Losreißen
## ist die seltene Ausnahme. Gäste als Zeugen vertreiben ihn. Verschwinden: in 0,5 s ausgeblendet.
## Wer sich vor ihm im Schrank versteckt, den wartet er ab: Er schwebt vor den Türen, packt zu, wer
## herauskommt, und fliegt am Ende vielleicht hinein (Luft anhalten hilft ein wenig).
## Ab dem 6. Mal taucht er auch im Flur auf, wenn alle Gäste schlafen (Nachtruhe, Social) – dann gibt es
## keine Zeugen. Schlafmangel (Player.nights_awake) macht ihn häufiger; nach drei Nächten ohne Schlaf
## kommt er sicher im Flur, sobald man dort allein ist.
## Gäste behandelt er wie den Spieler (Spielkonzept 6.12): Wer wach im Dunkeln bei offenem Vorhang steht,
## bekommt Besuch – mit eigenem Zähler (Guest.ghost_visits). Ein erwürgter Gast bleibt als Leiche liegen.
## Wer ihn sieht, erschrickt (Guest.shock) und erzählt später davon.

enum State { IDLE, APPROACH, HOVER, ENTER, STRANGLE, FADE, LURK, FLY_IN }

const MODEL := "res://assets/models/ghost.glb"

# --- Tuning -------------------------------------------------------------------
const FROM_DAY := 2                   ## spukt ab diesem Tag (oder schon nach dem ersten Angriff)
const SPAWN_CHANCE := 0.7             ## beim Betreten eines dunklen Raums mit offenem Vorhang
const STAY_CHANCE := 0.25             ## … und alle STAY_EVERY Sekunden, solange man darin bleibt
const STAY_EVERY := 6.0
const COOLDOWN := 45.0                ## frühestens wieder nach so vielen Sekunden
const CHECK_EVERY := 0.5
const WINDOW_RANGE := 7.0             ## so nah am Fenster (und mit freier Sicht darauf) muss man sein
const START_DISTANCE := 7.0           ## so weit draußen taucht er auf
const STOP_OUTSIDE := 1.4             ## 1. Mal: bleibt so weit vor der Scheibe
const STOP_AT_GLASS := 0.32           ## ab dem 2. Mal: Hände an der Scheibe
const FLOAT_SPEED := 1.6
const INSIDE_SPEED := 1.1
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
## Losreißen: Jeder Richtungswechsel füllt den Balken, der Griff zieht ihn ständig zurück. Erst ab etwa
## 6,5 Wechseln je Sekunde über die ganze Zeit reicht es – ab dem 4. Mal greift er noch fester zu.
const ESCAPE_TIME := 3.0
const ESCAPE_GAIN := 0.16             ## je Richtungswechsel
const ESCAPE_GRIP := 0.72             ## so viel zieht der Griff je Sekunde zurück
const ESCAPE_GRIP_STAGE := 0.06       ## ab dem 4. Mal je Mal fester (höchstens +0,3)
## Gäste reißen sich nur selten los: so viel + Mut × so viel
const GUEST_ESCAPE := Vector2(0.05, 0.2)
## Schrank: so lange wartet er vor den Türen, dann fliegt er mit dieser Chance hinein (sonst gibt er auf)
const LURK_TIME := Vector2(20.0, 35.0)
const FLY_IN_CHANCE := 0.4
const FLY_IN_CHANCE_LATE := 0.75      ## ab dem 6. Mal
const FLY_IN_PER_NIGHT := 0.1         ## je Nacht ohne Schlaf mehr
const BREATH_SAVES := 0.5             ## Luft anhalten senkt die Chance um bis zu diesen Anteil …
const BREATH_FULL := 12.0             ## … bei so vielen Sekunden angehaltener Luft während des Wartens
const FLY_IN_SPEED := 2.4
const RATTLE_EVERY := Vector2(3.0, 7.0)
const WITNESSES := 1                  ## so viele wache Gäste mit Blick auf ihn vertreiben ihn
const WITNESS_RANGE := 12.0
const LEAVE_RANGE := 14.0             ## so weit weg vom Fenster (bzw. von ihm) gibt er auf
## Flur: ab diesem Mal, Chance je Sekunde im dunklen Flur, wenn alle schlafen; Abstand beim Auftauchen
const HALL_FROM := 6
const HALL_CHANCE := 0.04
const HALL_DISTANCE := Vector2(8.0, 16.0)
## Schlafmangel (Nächte ohne Schlaf, Player.nights_awake): je Nacht mehr Chance, kürzere Pause, mehr Flur;
## ab AWAKE_HALL_FROM auch vor dem 6. Mal im Flur, ab AWAKE_SURE sicher im Flur, sobald man dort allein ist
## (auch ohne Nachtruhe)
const AWAKE_CHANCE := 0.1
const AWAKE_HALL_FROM := 2
const AWAKE_SURE := 3
## Modell: Handgelenke so hoch über dem Ursprung, Hände so weit vor der Mitte
const HANDS_Y := 1.12
const HANDS_AHEAD := 0.45
const NECK_BELOW_EYES := 0.22
const FINGERS := ["thumb", "index", "middle", "ring", "pinky"]

var visits := 0          ## so oft ist er schon beim Spieler erschienen (Stufe)
var state := State.IDLE
var debug_ignore_player := false   ## Debug (--shock=id,ghost): Spieler zählt bei Gästen nicht als Zeuge

var _victim: Node3D      ## Player oder Guest, zu dem er gerade kommt
var _stage := 0          ## das wievielte Mal bei diesem Opfer
var _victim_saw := false ## Gast hat ihn schon gesehen (Schreck)
var _escape_at := -1.0   ## Gast: reißt sich nach so vielen Sekunden los (< 0: schafft es nicht)
var _guest_windows := {} ## Gast-ID → Fenster, an dem er zuletzt stand (wie _last_window beim Spieler)
var _force_guest: Guest

var _window: HotelWindow
var _last_window: HotelWindow
var _cooldown := 0.0
var _check := 0.0
var _stay := 0.0         ## bis zum nächsten Wurf, solange der Spieler im dunklen Raum bleibt
var _timer := 0.0
var _time := 0.0
var _fade := 0.0
var _target := Vector3.ZERO
var _swings := 0
var _last_sign := 0
var _force := false
var _force_hall := false
var _escape := 0.0       ## Losreißen: Balken 0..1
var _lurk_spot: HideSpot ## Schrank, vor dem er wartet bzw. in den er hineinfliegt
var _rattle := 0.0
var _held_breath := 0.0  ## so lange hat der Spieler beim Warten die Luft angehalten
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
	if state != State.FADE:
		var seen_by := _witness_guests(global_position + Vector3.UP * HANDS_Y, _victim)
		if seen_by.size() + _player_witness(global_position + Vector3.UP * HANDS_Y) >= WITNESSES:
			for guest in seen_by:
				guest.shock("ghost", global_position)
			if "--trace" in OS.get_cmdline_user_args():
				var names := seen_by.map(func(g: Guest) -> String: return g.display_name)
				print("[Lakengeist] vertrieben von %s" % (", ".join(names) if not names.is_empty() else "dir"))
			_vanish()
		elif _lost_victim():
			_vanish()
	if _victim is Guest and not _victim_saw and state in [State.APPROACH, State.HOVER, State.ENTER] and _fade > 0.5:
		_guest_sees_me(_victim as Guest)
	match state:
		State.APPROACH:
			if _float_to(_target, FLOAT_SPEED, delta):
				if _stage >= HYPNOSIS_FROM and _window:
					_touch_glass()
				state = State.HOVER
				_timer = HOVER_TIME[mini(_stage, 3) - 1]
		State.HOVER:
			_timer -= delta
			if _timer <= 0.0:
				if _stage >= ENTER_FROM:
					state = State.ENTER
				else:
					_vanish()
		State.ENTER:
			var neck := _eye_of(_victim) - Vector3(0, NECK_BELOW_EYES, 0)
			var flat := Vector3(neck.x - global_position.x, 0, neck.z - global_position.z)
			if _float_to(_grip_spot(), INSIDE_SPEED, delta, false) or flat.length() < HANDS_AHEAD + GRIP_RANGE:
				_grab()
			elif _victim.global_position.distance_to(_window.global_position if _window else global_position) > LEAVE_RANGE + (0.0 if _window else 6.0):
				_vanish()
		State.STRANGLE:
			_struggle(delta)
		State.LURK:
			_lurk(delta)
		State.FLY_IN:
			if _float_to(_grip_spot(), FLY_IN_SPEED, delta):
				_grab()
		State.FADE:
			_fade = maxf(0.0, _fade - delta / FADE_TIME)
			if _fade <= 0.0:
				_hide()
				return
	if state in [State.APPROACH, State.HOVER, State.ENTER, State.LURK, State.FLY_IN] and _fade < 1.0:
		_fade = minf(1.0, _fade + delta / APPEAR_TIME)
	_material.set_shader_parameter("fade", _fade)
	_update_trance(delta)
	_pose()


# --- Erscheinen ---------------------------------------------------------------------------

## Betritt der Spieler einen dunklen Raum mit Außenfenster (Vorhang offen – ab dem 4. Mal egal),
## würfelt es (SPAWN_CHANCE); bleibt er darin, alle STAY_EVERY Sekunden erneut (STAY_CHANCE).
## Ab Tag FROM_DAY oder nach dem ersten Angriff des Monsters (der Anfang bleibt friedlich, 2.1).
func _check_spawn() -> void:
	var player := Game.player
	var director := Game.director
	if director == null or Game.game_over:
		return
	if not (player.dead or player.hiding != null or player.in_dialog) and (_haunting() or _force or _force_hall):
		if _check_hall(player):
			return
		var eye := player.camera.global_position
		var window := _window_near(eye, visits + 1)
		var chance := 0.0
		if window != _last_window:
			_last_window = window
			_stay = STAY_EVERY
			chance = _spawn_chance()
		elif window != null:
			_stay -= CHECK_EVERY
			if _stay <= 0.0:
				_stay = STAY_EVERY
				chance = minf(1.0, STAY_CHANCE + AWAKE_CHANCE * player.nights_awake)
		# in Gesellschaft kommt er nicht
		if window != null and (_cooldown <= 0.0 or _force) and director.player_threat <= 0.0 \
				and _witness_guests(eye, player).size() < WITNESSES and (_force or randf() < chance):
			_force = false
			_appear(window, player)
			return
	if _haunting() or _force_guest != null:
		_check_guests()


## Spukt er schon? Ab Tag FROM_DAY oder nach dem ersten Angriff, je nachdem, was früher kommt.
func _haunting() -> bool:
	return Game.director.first_attack_done or Calendar.today() >= FROM_DAY


## Gäste behandelt er wie den Spieler (Spielkonzept 6.12): Steht ein wacher Gast in einem dunklen Raum mit
## offenem Vorhang (meist: er ruht im eigenen Zimmer), würfelt es einmal – gleiche Chance, gleiche Stufen.
func _check_guests() -> void:
	if Game.social == null:
		return
	for guest in Game.social.guests:
		var g: Guest = guest
		if _force_guest != null and g != _force_guest:
			continue   # Debug: nur zu diesem Gast
		if g.dead or g.hiding != null or g.state in [Guest.State.TALKING, Guest.State.MINIGAME, Guest.State.SLEEP, Guest.State.KNOCK, Guest.State.SHELTER]:
			_guest_windows.erase(g.id)
			continue
		var eye := g.global_position + Vector3.UP * g.eye_height()
		var window := _window_near(eye, g.ghost_visits + 1)
		if window == _guest_windows.get(g.id):
			continue
		_guest_windows[g.id] = window
		if window == null:
			continue
		var forced := _force_guest == g
		if not forced and (_cooldown > 0.0 or Game.director.player_threat > 0.0 \
				or _witness_guests(eye, g).size() + _player_witness(eye) >= WITNESSES or randf() >= SPAWN_CHANCE):
			continue
		_force_guest = null
		_appear(window, g)
		return


## Ab dem 6. Mal: Schlafen alle Gäste und steht der Spieler im Flur, taucht er dort mit kleiner Chance
## je Sekunde auf – irgendwo vor oder hinter ihm, wo er gerade nicht hinsieht. Schlafmangel: je Nacht ohne
## Schlaf öfter, ab der 2. auch vor dem 6. Mal, ab der 3. sicher, sobald man allein im Flur ist.
func _check_hall(player: Player) -> bool:
	var nights := player.nights_awake
	if Game.social == null or not "Flur" in Game.director.zone_name_at(player.global_position):
		return false
	if nights >= AWAKE_SURE:
		if _cooldown > 0.0 or Game.director.player_threat > 0.0 \
				or _witness_guests(player.camera.global_position, player).size() >= WITNESSES:
			return false
	else:
		if (visits + 1 < HALL_FROM and nights < AWAKE_HALL_FROM) or not Game.social.all_asleep():
			return false
		if not _force_hall and (_cooldown > 0.0 or Game.director.player_threat > 0.0 \
				or randf() >= HALL_CHANCE * (1 + nights) * CHECK_EVERY):
			return false
	var spots: Array[Vector3] = []
	for entry in Game.director.patrol:
		var p: Vector3 = entry["pos"]
		var d := p.distance_to(player.global_position)
		if absf(p.y - player.global_position.y) < 1.5 and d >= HALL_DISTANCE.x and d <= HALL_DISTANCE.y \
				and "Flur" in Game.director.zone_name_at(p) and not Game.director.player_can_see(p + Vector3.UP * 1.2) \
				and _witness_guests(p + Vector3.UP * HANDS_Y, player).size() < WITNESSES:   # wache Gäste (Schlafmangel)
			spots.append(p)
	if spots.is_empty():
		return false
	_force_hall = false
	_appear_in_hall(spots[randi() % spots.size()])
	return true


func _appear_in_hall(floor_point: Vector3) -> void:
	visits += 1
	_victim = Game.player
	_victim_saw = false
	_stage = visits
	_window = null
	_last_window = null
	_lurk_spot = null
	var neck := Game.player.camera.global_position.y - NECK_BELOW_EYES
	global_position = Vector3(floor_point.x, neck - HANDS_Y, floor_point.z)
	_face(Game.player.global_position - global_position)
	visible = true
	_fade = 0.0
	state = State.ENTER
	Game.caption("[Kälte im Flur]")
	if "--trace" in OS.get_cmdline_user_args():
		var nights := Game.player.nights_awake
		print("[Lakengeist] %d. Mal – im Flur (%d Nächte ohne Schlaf%s)" % [visits, nights, ", sicher" if nights >= AWAKE_SURE else ""])


## Dunkles Außenfenster in der Nähe dieses Augenpunkts, durch das er zum `stage`. Mal käme.
func _window_near(eye: Vector3, stage: int) -> HotelWindow:
	var space := get_world_3d().direct_space_state
	for node in get_tree().get_nodes_in_group("windows"):
		var window := node as HotelWindow
		if not window.has_curtains() or (window.closed and stage < THROUGH_CURTAIN_FROM):
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


func _appear(window: HotelWindow, victim: Node3D) -> void:
	_victim = victim
	_victim_saw = false
	if victim is Guest:
		var guest := victim as Guest
		guest.ghost_visits += 1
		_stage = guest.ghost_visits
	else:
		visits += 1
		_stage = visits
	_window = window
	_lurk_spot = null
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
		_target = base + outward * (STOP_OUTSIDE if _stage < HYPNOSIS_FROM else STOP_AT_GLASS)
		state = State.APPROACH
	if victim is Player:
		Game.caption("[Etwas schwebt vor dem Fenster]")
	if "--trace" in OS.get_cmdline_user_args():
		print("[Lakengeist] %d. Mal am Fenster (%s) – bei %s" % [_stage, window.room_id, (victim as Guest).display_name if victim is Guest \
			else "dir (%d Nächte ohne Schlaf)" % Game.player.nights_awake])


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
	_escape = 0.0
	if _victim is Guest:
		# Mutige reißen sich eher los (ein Gast zappelt nicht nach Anleitung)
		var guest := _victim as Guest
		guest.ghost_grab(global_position + Vector3.UP * HANDS_Y)
		_escape_at = ESCAPE_TIME * randf_range(0.3, 0.9) if randf() < GUEST_ESCAPE.x + GUEST_ESCAPE.y * float(guest.profile["brave"]) else -1.0
		if Game.player.global_position.distance_to(guest.global_position) < 12.0:
			Game.play_sound("gasp", 0.6)
		Game.shot_event("strangle", 20)
		return
	Game.player.gripped = true
	Game.play_sound("gasp", 0.8)
	Game.caption("[Kalte Hände um deinen Hals – reiß dich los!]")
	Game.say("Beweg dich! Schnell hin und her!", ESCAPE_TIME)
	if Game.hud:
		Game.hud.set_struggle(0.0)
	Game.shot_event("strangle", 20)


## Losreißen: Jeder Richtungswechsel füllt den Balken um ESCAPE_GAIN, der Griff zieht ihn ständig zurück.
## Voll, bevor die Zeit um ist → los (aus dem Schrank stürzt man dabei heraus).
func _struggle(delta: float) -> void:
	if _victim is Guest:
		_timer -= delta
		if _escape_at >= 0.0 and ESCAPE_TIME - _timer >= _escape_at:
			if "--trace" in OS.get_cmdline_user_args():
				print("[Lakengeist] %s hat sich losgerissen" % (_victim as Guest).display_name)
			_vanish()
		elif _timer <= 0.0:
			_kill_guest(_victim as Guest)
		return
	var player := Game.player
	var input: Vector2 = player.move_input
	var axis := input.x if absf(input.x) >= absf(input.y) else input.y
	var dir := 0 if absf(axis) < 0.5 else (1 if axis > 0.0 else -1)
	if dir != 0 and dir != _last_sign:
		if _last_sign != 0:
			_swings += 1
			_escape += ESCAPE_GAIN
		_last_sign = dir
	var grip := ESCAPE_GRIP + minf(0.3, ESCAPE_GRIP_STAGE * maxi(0, _stage - ENTER_FROM))
	_escape = maxf(0.0, _escape - grip * delta)
	if Game.hud:
		Game.hud.set_struggle(_escape)
	var held := ESCAPE_TIME - _timer
	if _escape >= 1.0:
		if "--trace" in OS.get_cmdline_user_args():
			print("[Lakengeist] losgerissen nach %.1f s (%d Wechsel, %.1f je s)" % [held, _swings, _swings / maxf(0.1, held)])
		player.add_shock(0.25, false)
		Game.say("Losgerissen!", 1.5)
		if player.hiding:
			player.exit_hide()   # aus dem Schrank gestürzt
		_vanish()
		return
	_timer -= delta
	if _timer <= 0.0:
		if "--trace" in OS.get_cmdline_user_args():
			print("[Lakengeist] Balken bei %.0f %% (%d Wechsel in %.1f s)" % [_escape * 100.0, _swings, ESCAPE_TIME])
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
		Game.hud.set_struggle(-1.0)
		Game.hud.set_prompt("")
		Game.hud.visible = false
	Game.play_sound("scream", 1.0)
	Game.director.flash(1.4)
	await get_tree().create_timer(1.5).timeout
	Game.player_died.emit()


## Ein Gast stirbt – er bleibt liegen (Spielkonzept 6.12), das Hotel erfährt es wie beim Monster.
func _kill_guest(guest: Guest) -> void:
	if "--trace" in OS.get_cmdline_user_args():
		print("[Lakengeist] %s erwürgt" % guest.display_name)
	guest.die("ghost")
	if Game.social:
		Game.social.on_guest_died(guest, "ghost")
	_vanish()


# --- Verschwinden & Zeugen ------------------------------------------------------------------

func _vanish() -> void:
	if Game.player:
		Game.player.gripped = false
	if Game.hud:
		Game.hud.set_struggle(-1.0)
	if _victim is Guest:
		(_victim as Guest).ghost_gone()
	state = State.FADE
	_lurk_spot = null
	# Schlafmangel: Zum Spieler kommt er umso schneller wieder
	_cooldown = COOLDOWN / (1.0 + (Game.player.nights_awake if _victim is Player else 0))


func _hide() -> void:
	state = State.IDLE
	visible = false
	_fade = 0.0
	_window = null
	_victim = null
	_lurk_spot = null
	global_position = Vector3(0, -60, 0)
	if _material:
		_material.set_shader_parameter("fade", 0.0)


## Wache Gäste (außer dem Opfer) mit freier Sicht auf diesen Punkt.
func _witness_guests(point: Vector3, victim: Node3D) -> Array[Guest]:
	var result: Array[Guest] = []
	if Game.social == null:
		return result
	var space := get_world_3d().direct_space_state
	for guest in Game.social.guests:
		if guest == victim or guest.dead or guest.hiding != null or guest.global_position.distance_to(point) > WITNESS_RANGE:
			continue
		var query := PhysicsRayQueryParameters3D.create(guest.global_position + Vector3.UP * guest.eye_height(), point, Senses.SIGHT_MASK)
		if space.intersect_ray(query).is_empty():
			result.append(guest)
	return result


## Kommt er zu einem Gast, ist der Spieler ein Zeuge wie jeder andere (1 oder 0).
func _player_witness(point: Vector3) -> int:
	var player := Game.player
	if not _victim is Guest or debug_ignore_player or player == null or player.dead or player.hiding != null:
		return 0
	var eye := player.camera.global_position
	if eye.distance_to(point) > WITNESS_RANGE:
		return 0
	var query := PhysicsRayQueryParameters3D.create(eye, point, Senses.SIGHT_MASK)
	return 1 if get_world_3d().direct_space_state.intersect_ray(query).is_empty() else 0


## Der Gast, zu dem er kommt, sieht ihn (Sicht durchs Glas): Schreck – ab der Hypnose-Stufe bleibt er
## gebannt stehen, statt wegzulaufen.
func _guest_sees_me(guest: Guest) -> void:
	var eye := guest.global_position + Vector3.UP * guest.eye_height()
	var head := global_position + Vector3.UP * (HANDS_Y + 0.5)
	if eye.distance_to(head) > LEAVE_RANGE:
		return
	var query := PhysicsRayQueryParameters3D.create(eye, head, Senses.SIGHT_MASK & ~HotelWindow.LAYER_BLOCK)
	query.exclude = [guest.get_rid()]
	if not get_world_3d().direct_space_state.intersect_ray(query).is_empty():
		return
	_victim_saw = true
	guest.shock("ghost", head, "", _stage >= HYPNOSIS_FROM)


## Opfer versteckt (Gast: auch im Bett) oder tot – dann verschwindet er.
func _victim_gone() -> bool:
	if _victim is Guest:
		var guest := _victim as Guest
		return guest.hiding != null or guest.dead
	var player := _victim as Player
	return player.hiding != null or player.dead


## Opfer verloren? Versteckt sich der Spieler vor ihm im Schrank, wartet er davor, statt zu verschwinden.
func _lost_victim() -> bool:
	if not _victim_gone():
		return false
	var player := _victim as Player
	if player == null or player.dead:
		return true
	if _lurk_spot != null and player.hiding == _lurk_spot:
		return false   # wartet davor, fliegt hinein oder würgt schon im Schrank
	return not _start_lurk(player.hiding)


## Nur wenn er ohnehin hereingekommen wäre (ab dem 3. Mal, im Flur) – und nur vor Schränken.
func _start_lurk(spot: HideSpot) -> bool:
	if spot == null or spot.type != HideSpot.Type.WARDROBE or state == State.STRANGLE \
			or not (_stage >= ENTER_FROM or _window == null):
		return false
	_lurk_spot = spot
	state = State.LURK
	_timer = randf_range(LURK_TIME.x, LURK_TIME.y)
	_rattle = randf_range(RATTLE_EVERY.x, RATTLE_EVERY.y)
	_held_breath = 0.0
	if "--trace" in OS.get_cmdline_user_args():
		print("[Lakengeist] wartet %.0f s vor dem Schrank" % _timer)
	return true


## Vor dem Schrank: schwebt vor die Türen und rüttelt ab und zu. Wer herauskommt, wird gepackt; wer nach
## Luft schnappt, verrät sich – dann fliegt er sofort hinein. Am Ende würfelt er: hinein oder aufgeben.
func _lurk(delta: float) -> void:
	var player := Game.player
	if player.hiding != _lurk_spot:   # herausgekommen (oder musste raus)
		_lurk_spot = null
		state = State.ENTER
		Game.caption("[Er hat gewartet]")
		return
	var front := _lurk_spot.check_point.global_position
	var hands := _lurk_spot.view_point.global_position.y - NECK_BELOW_EYES - HANDS_Y
	_float_to(Vector3(front.x, hands, front.z), INSIDE_SPEED, delta)
	_face(_lurk_spot.global_position - global_position)
	if player.holding_breath:
		_held_breath += delta
	_rattle -= delta
	if _rattle <= 0.0:
		_rattle = randf_range(RATTLE_EVERY.x, RATTLE_EVERY.y)
		_lurk_spot.rattle()
		Game.caption("[Etwas rüttelt an der Schranktür]" if randf() < 0.6 else "[Flüstern vor dem Schrank]")
	if player.breath <= 0.0:
		if "--trace" in OS.get_cmdline_user_args():
			print("[Lakengeist] hört dich keuchen – fliegt in den Schrank")
		_fly_in()
		return
	_timer -= delta
	if _timer > 0.0:
		return
	var chance := (FLY_IN_CHANCE_LATE if _stage >= HALL_FROM else FLY_IN_CHANCE) + FLY_IN_PER_NIGHT * player.nights_awake
	chance *= 1.0 - BREATH_SAVES * clampf(_held_breath / BREATH_FULL, 0.0, 1.0)
	var flies := randf() < chance
	if "--trace" in OS.get_cmdline_user_args():
		print("[Lakengeist] Schrank: Chance %.0f %% (Luft angehalten %.1f s) – %s" % [chance * 100.0, _held_breath,
			"fliegt hinein" if flies else "gibt auf"])
	if flies:
		_fly_in()
	else:
		_vanish()


## Die Türen fliegen auf, er schwebt hinein und würgt im Schrank.
func _fly_in() -> void:
	state = State.FLY_IN
	_lurk_spot.burst_open(self)
	Game.caption("[Die Schranktüren fliegen auf]")


## Wohin er schwebt, um zuzupacken: Hände am Hals des Opfers. Dreht ihn zum Opfer.
func _grip_spot() -> Vector3:
	var neck := _eye_of(_victim) - Vector3(0, NECK_BELOW_EYES, 0)
	var flat := Vector3(neck.x - global_position.x, 0, neck.z - global_position.z)
	_face(flat)
	return Vector3(neck.x, neck.y - HANDS_Y, neck.z) - flat.normalized() * HANDS_AHEAD


## Erscheinen beim Spieler – Schlafmangel macht es wahrscheinlicher.
func _spawn_chance() -> float:
	return minf(1.0, SPAWN_CHANCE + AWAKE_CHANCE * Game.player.nights_awake)


## Augenpunkt des Opfers (Spieler: Kamera).
func _eye_of(victim: Node3D) -> Vector3:
	if victim is Guest:
		return victim.global_position + Vector3.UP * (victim as Guest).eye_height()
	return (victim as Player).camera.global_position


# --- Hypnose ----------------------------------------------------------------------------

## Ab dem 2. Mal: Solange man ihn ansieht, während er die Hände kreisen lässt, wird man langsamer und
## der Blick wird zu ihm gezogen. Beim Würgen hält er den Blick fest.
func _update_trance(delta: float) -> void:
	var player := Game.player
	var head := global_position + Vector3.UP * (HANDS_Y + 0.5)
	var mine := _victim == player   # bei einem Gast hält er den Spieler nicht fest
	var hypnotizing := mine and _stage >= HYPNOSIS_FROM and state in [State.HOVER, State.ENTER] and _fade > 0.5
	if hypnotizing and Game.director.player_can_see(head):
		player.trance = minf(1.0, player.trance + TRANCE_GAIN * delta)
	else:
		player.trance = maxf(0.0, player.trance - TRANCE_DECAY * delta)
	var pull := PULL * player.trance
	if state == State.STRANGLE and mine:
		pull = PULL * 2.0
	if pull <= 0.0 or player.hiding:   # im Versteck ist der Blick fest
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
	var circling := _stage >= HYPNOSIS_FROM and state in [State.HOVER, State.ENTER, State.LURK]
	var gripping := state in [State.STRANGLE, State.FLY_IN]
	for side in [".L", ".R"]:
		var phase := _time * 2.2 + (0.0 if side == ".L" else PI)
		var lift := 0.25 if gripping else 0.0
		var swirl_x := sin(phase) * 0.22 if circling else 0.0
		var swirl_z := cos(phase) * 0.22 if circling else 0.0
		_rotate2("upper_arm" + side, Vector3.RIGHT, swirl_x + lift, Vector3.BACK, swirl_z)
		_rotate("forearm" + side, Vector3.RIGHT, swirl_x * 0.6 + lift * 0.5)
		var curl := 0.35 if gripping else (-0.08 if state == State.HOVER and _stage >= HYPNOSIS_FROM else 0.05 * sin(_time * 3.0 + phase))
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


## Debug (--shock=id,ghostN): Licht im Zimmer des Gastes aus, Vorhänge auf (ab dem 4. Mal zu); er kommt
## sicher zum `stage`. Mal zu diesem Gast. Der Spieler zählt dabei nicht als Zeuge.
func debug_summon_guest(guest: Guest, stage: int) -> void:
	guest.ghost_visits = maxi(0, stage - 1)
	_cooldown = 0.0
	_guest_windows.erase(guest.id)
	_force_guest = guest
	debug_ignore_player = true
	var sw := LightSwitch.find(get_tree(), guest.home["no"])
	if sw:
		sw.set_on(false)
	var found := false
	for node in get_tree().get_nodes_in_group("windows"):
		var window := node as HotelWindow
		if window.room_id == guest.home["no"] and window.has_curtains():
			window.set_closed(stage >= THROUGH_CURTAIN_FROM, true)
			found = true
	if not found:
		print("[Lakengeist] Zimmer %s hat kein Außenfenster – er kann nicht zu %s kommen" % [guest.home["no"], guest.display_name])


func save_state() -> Dictionary:
	return {"visits": visits, "cooldown": _cooldown}


func load_state(d: Dictionary) -> void:
	visits = int(d.get("visits", 0))
	_cooldown = float(d.get("cooldown", 0.0))
	_guest_windows.clear()
	if Game.player:
		Game.player.gripped = false
	_hide()
