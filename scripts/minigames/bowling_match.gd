class_name BowlingMatch
extends TableMatch
## Bowling allein (Spielkonzept 6.10, 01.11.): [E] am Kugelständer stellt dich mittig in den Anlauf, eine Kugel aus
## dem Ständer in der Hand. Zielen wie beim Darts: A/D tritt zur Seite, die Maus gibt die Richtung, eine Marke auf der
## Bahn zeigt, wo die Kugel über die Pfeile läuft (ARROWS); der Blick schwankt. Linksklick halten macht ihn ruhiger
## (nach STEADY_TIME am ruhigsten, ab TIRE_AFTER zittert der Arm), Loslassen rollt – mit Streuung, mehr bei hastigem
## Wurf oder bewegter Maus; die Stärke ist fest mit etwas Zufall, Effet gibt es nicht. Rausch, Kaffeezittern, Schock
## und Müdigkeit (Player.weakness) machen es schwerer. Beim Rollen löst sich die Kamera vom Spieler und fährt der
## Kugel nach, bis FOLLOW_STOP vor dem Ende der Bahn; [E] oder Linksklick springt zurück. Ein Frame hat zwei Würfe
## (ein Strike beendet ihn), danach „Weiter?“. Eine Vorwarnung in der Nähe bricht ab wie beim Darts. Die Kugeln
## gehören zur Bahn – mitnehmen geht nicht (STEAL_LINE beim Aufhören). Gäste, Einsatz und ein ganzes Spiel mit zehn
## Frames gibt es noch nicht.

const ZOOM_IDLE := 0.85         ## Blickwinkel im Anlauf und beim ruhigen Zielen (Anteil von Settings.fov)
const ZOOM_AIM := 0.6
## Schwanken des Blicks (rad), beim Halten bis auf STEADY_MIN davon nach STEADY_TIME s; ab TIRE_AFTER s wieder mehr
const SWAY := 0.008
const STEADY_MIN := 0.3
const STEADY_TIME := 1.0
const TIRE_AFTER := 2.8
const TIRE_RATE := 0.6
## Zittern (rad): zu viel Kaffee, Schock (× shock)
const TREMOR_JITTER := 0.002
const TREMOR_SHOCK := 0.004
## Streuung der Richtung beim Loslassen (rad, Standardabweichung); hastig (kürzer als QUICK s gehalten) mal
## QUICK_FACTOR; je 1000 px/s Mausbewegung MOUSE_SPREAD dazu
const SPREAD := 0.0025
const QUICK := 0.25
const QUICK_FACTOR := 1.8
const MOUSE_SPREAD := 0.004
const AIM_LIMIT := 0.12         ## rad (≈ 7°): so schräg läuft die Kugel höchstens
const SPEED := 7.5              ## m/s beim Loslassen …
const SPEED_JITTER := 0.05      ## … ± so viel davon
const SIDESTEP := 0.7           ## m/s seitlich mit A/D
const ARROWS := 4.6             ## m hinter der Foullinie liegt die Zielmarke (wie die Pfeile echter Bahnen)
const HAND := Vector3(0.22, -0.3, -0.5)    ## Kugel in der Hand vor der Kamera
const FOLLOW := Vector3(0, 0.6, 1.4)       ## Kamera hinter und über der rollenden Kugel
const FOLLOW_STOP := 5.0        ## m vor dem Ende der Bahn bleibt die Kamera stehen
const FOLLOW_RATE := 8.0        ## wie schnell sie nachzieht (1/s)
const SHOW_RESULT := 1.5        ## s nach dem Zählen bleibt der Blick auf den Kegeln
const STEAL_LINE := "Du stellst die Kugel zurück in den Ständer. Einfach eine mitnehmen? Die anderen Gäste " \
	+ "wären stinksauer, wenn plötzlich eine fehlt."

enum Phase { AIM, ROLLING, SHOW, DONE }

var lane: BowlingLane

var _phase := Phase.DONE
var _rolls: Array[int] = []
var _frames := 0
var _offset := 0.0              ## seitlich von der Mitte der Bahn
var _hold := -1.0               ## ≥ 0: Linksklick gehalten seit so vielen s
var _sway_time := 0.0
var _sway := Vector2.ZERO       ## schon auf den Blick gelegt
var _color := Color.BLACK
var _wait := 0.0
var _then := Callable()
var _told_steal := false
var _hand_ball: Node3D
var _marker: MeshInstance3D
var _cam: Camera3D
var _look := Vector3.ZERO
var _score_label: Label


func _ready() -> void:
	var panel := _build_panel(Color(0.04, 0.05, 0.06, 0.82), 5, Vector4(0.02, 0.03, 0.4, 0.36))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)
	panel.add_child(box)
	_title = UiKit.plain_label(9, Color(0.95, 0.75, 0.4))
	box.add_child(_title)
	_score_label = UiKit.plain_label(11, Color(0.95, 0.93, 0.88))
	box.add_child(_score_label)
	_log = UiKit.plain_label(8, Color(0.9, 0.88, 0.85))
	_log.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_log.custom_minimum_size = Vector2(0, 30)
	box.add_child(_log)
	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 0)
	box.add_child(list)
	_options = list


## [E] am Kugelständer: in den Anlauf, Kugel in die Hand, erster Frame.
func play(p_lane: BowlingLane) -> void:
	if active or p_lane == null or Game.table_game_active():
		return
	lane = p_lane
	guest = null
	active = true
	_over = false
	_abort_timer = -1.0
	_frames = 0
	_offset = 0.0
	_take_places()
	visible = true
	_waiting_for_seat = true   # ohne Gast geht es im nächsten Bild los (_on_seated)
	if Game.tracing:
		print("[Bowling] Spiel beginnt")


func _take_places() -> void:
	var player := Game.player
	if player.held:   # beide Hände für die Kugel – was du hältst, legst du ab
		player.drop_held()
	player.stand_at(lane.stand_spot(_offset), lane.deck_center())
	player.fov_zoom = ZOOM_IDLE
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_color = lane.take_ball()
	_hand_ball = lane.ball_model(_color)
	player.camera.add_child(_hand_ball)
	_hand_ball.position = HAND
	_marker = Geo.mesh(lane, Geo.cylinder(0.05, 0.004, 16),
		Mat.psx(Color(1.0, 0.55, 0.15), "", 1.0, Color(1.0, 0.45, 0.1), 1.5), Vector3.ZERO)
	_marker.visible = false
	_cam = Camera3D.new()
	_cam.near = player.camera.near
	_cam.far = player.camera.far
	_cam.cull_mask = player.camera.cull_mask
	lane.add_child(_cam)


func _leave_places() -> void:
	_camera_back()
	Game.player.leave_oche()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	for node: Node in [_hand_ball, _marker, _cam]:
		if is_instance_valid(node):
			node.queue_free()
	lane.reset()
	lane.return_ball()
	if not _told_steal:
		_told_steal = true
		Game.say(STEAL_LINE, 5.0)


func _on_seated() -> void:
	_new_frame()


## Ohne Spieltisch: nur aufräumen und gehen.
func _end() -> void:
	visible = false
	active = false
	_phase = Phase.DONE
	_clear()
	_leave_places()
	if Game.tracing:
		print("[Bowling] Ende nach %d Frames" % _frames)


func _stop() -> void:
	_hold = -1.0
	_then = Callable()
	_wait = 0.0
	_phase = Phase.DONE
	_camera_back()
	if is_instance_valid(_hand_ball):
		_hand_ball.visible = false
	if is_instance_valid(_marker):
		_marker.visible = false
	lane.reset()


func _update_game(delta: float) -> void:
	if not _over and _danger():
		_abort("Du lässt die Kugel sinken – irgendetwas stimmt hier nicht.")
		return
	if _phase != Phase.AIM and _cam.current:
		_follow(delta)
	if _wait > 0.0:
		_wait -= delta
		if _wait <= 0.0 and _then.is_valid():
			var next := _then
			_then = Callable()
			next.call()
		return
	match _phase:
		Phase.AIM:
			_aim(delta)
		Phase.ROLLING:
			if _cam.current and (Input.is_action_just_pressed("interact") or Input.is_action_just_pressed("use_item")):
				_camera_back()
			if lane.settled():
				_count()


## Vorwarnung in der Nähe? (wie beim Darts allein)
func _danger() -> bool:
	return not Game.director.is_quiet(lane.deck_center(), 20.0) \
		or Game.director.long_signal_near(Game.player.global_position)


func _after(seconds: float, next: Callable) -> void:
	_wait = seconds
	_then = next


# --- Ablauf eines Frames ------------------------------------------------------------------

func _new_frame() -> void:
	lane.reset()
	_rolls.clear()
	_frames += 1
	_say("A/D: zur Seite treten · Maus: Richtung · Linksklick halten: ruhig zielen, loslassen: rollen.")
	_ready_to_throw()


func _ready_to_throw() -> void:
	_camera_back()
	_phase = Phase.AIM
	_hold = -1.0
	_hand_ball.visible = true
	_update_board()
	_clear()
	_option("Aufhören", _end)


## Alles liegt still: zählen, nach dem ersten Wurf abräumen oder den Frame beenden.
func _count() -> void:
	var n := lane.down()
	lane.finish_roll(n)
	_rolls.append(n)
	if Game.tracing:
		print("[Bowling] Frame %d, Wurf %d: %d Kegel" % [_frames, _rolls.size(), n])
	_phase = Phase.SHOW
	_update_board()
	if _rolls.size() == 1 and n == 10:
		_say("Strike! Alle zehn auf einen Schlag.")
		_after(SHOW_RESULT, _frame_over)
	elif _rolls.size() == 1:
		_say("Daneben – kein einziger Kegel. Zweiter Wurf." if n == 0 else "%d Kegel. Zweiter Wurf." % n)
		lane.sweep()
		_after(SHOW_RESULT, _ready_to_throw)
	else:
		var total := _rolls[0] + _rolls[1]
		_say("Spare! Die restlichen %d auch noch." % _rolls[1] if total == 10 else "%d von zehn." % total)
		_after(SHOW_RESULT, _frame_over)


func _frame_over() -> void:
	_camera_back()
	_phase = Phase.DONE
	_say(_log.text + " Weiter?")
	_clear()
	_option("Weiter", _new_frame)
	_option("Aufhören", _end)


func _update_board() -> void:
	_title.text = "Bowling   ·   Frame %d" % _frames
	var shown: Array[String] = []
	for i in 2:
		if i < _rolls.size():
			shown.append("X" if i == 0 and _rolls[0] == 10 else
				("/" if i == 1 and _rolls[0] + _rolls[1] == 10 else ("–" if _rolls[i] == 0 else str(_rolls[i]))))
		else:
			shown.append("·")
	_score_label.text = "%s   %s" % shown


# --- Zielen und rollen ----------------------------------------------------------------------

func _aim(delta: float) -> void:
	var player := Game.player
	var side := Input.get_axis("move_left", "move_right")
	if side != 0.0:
		_offset = clampf(_offset + side * SIDESTEP * delta, -lane.max_offset(), lane.max_offset())
		player.global_position = lane.stand_spot(_offset)
	_sway_time += delta
	var holding := Input.is_action_pressed("use_item")
	if holding:
		_hold = maxf(_hold, 0.0) + delta
	var steady := clampf(_hold / STEADY_TIME, 0.0, 1.0) if _hold >= 0.0 else 0.0
	var amount := SWAY * (1.0 + 1.5 * player.weakness()) * (1.0 + 2.5 * BarTap.sway(player.drunk))
	amount *= lerpf(1.0, STEADY_MIN, steady) + maxf(0.0, _hold - TIRE_AFTER) * TIRE_RATE
	var t := _sway_time
	var sway := Vector2(sin(t * 0.83 * TAU) + 0.5 * sin(t * 1.9 * TAU + 1.3),
		sin(t * 0.61 * TAU + 0.7) + 0.5 * sin(t * 1.37 * TAU)) * amount / 1.5
	var tremor := (TREMOR_JITTER if player.jittery() else 0.0) + player.shock * TREMOR_SHOCK
	sway += Vector2(sin(t * 71.0) + sin(t * 113.0), sin(t * 89.0) + sin(t * 61.0)) * tremor * 0.5
	var step := sway - _sway
	_sway = sway
	player.rotation.y -= step.x
	player.head.rotation.x = clampf(player.head.rotation.x + step.y, -1.45, 1.45)
	player.fov_zoom = lerpf(ZOOM_IDLE, ZOOM_AIM, steady)
	_hand_ball.position = HAND + Vector3(0, 0.02, 0.04) * steady
	var from := _release_point()
	_marker.global_position = from + _dir(clampf(_yaw(), -AIM_LIMIT, AIM_LIMIT)) * ARROWS + Vector3(0, 0.003, 0)
	_marker.visible = true
	if not holding and _hold >= 0.0:
		_throw()


## Blickrichtung zur Seite (rad, 0 = genau die Bahn hinunter).
func _yaw() -> float:
	return wrapf(Game.player.rotation.y, -PI, PI)


static func _dir(yaw: float) -> Vector3:
	return Vector3(0, 0, -1).rotated(Vector3.UP, yaw)


## Hier verlässt die Kugel die Hand (am Boden, kurz vor der Foullinie).
func _release_point() -> Vector3:
	return Vector3(lane.stand_spot(_offset).x, lane.global_position.y, lane.foul_z - 0.15)


## Loslassen: Richtung aus dem Blick mit Streuung, Stärke fest mit etwas Zufall.
func _throw() -> void:
	var player := Game.player
	var spread := SPREAD * (1.0 + 1.2 * player.weakness()) * (1.0 + 2.0 * BarTap.sway(player.drunk))
	if _hold < QUICK:
		spread *= QUICK_FACTOR
	spread += Input.get_last_mouse_screen_velocity().length() / 1000.0 * MOUSE_SPREAD
	_release(clampf(_yaw(), -AIM_LIMIT, AIM_LIMIT) + randfn(0.0, spread))


func _release(yaw: float) -> void:
	_hold = -1.0
	_phase = Phase.ROLLING
	_hand_ball.visible = false
	_marker.visible = false
	Game.player.fov_zoom = ZOOM_IDLE
	_clear()
	lane.roll(_release_point().x, yaw, SPEED * (1.0 + randf_range(-SPEED_JITTER, SPEED_JITTER)), _color, Game.player)
	_say("Die Kugel rollt … [E] oder Linksklick: zurück zu dir.")
	_start_follow()


# --- Kamera hinter der Kugel ------------------------------------------------------------------

func _start_follow() -> void:
	var eye := Game.player.camera
	_cam.fov = eye.fov
	_cam.global_transform = eye.global_transform
	_look = eye.global_position - eye.global_basis.z * 5.0
	_cam.make_current()


func _follow(delta: float) -> void:
	var stop := lane.lane.position.y + FOLLOW_STOP
	var at := Vector3(lane.lane.get_center().x, FOLLOW.y, stop)
	var look := lane.deck_center()
	var ball := lane.ball
	if is_instance_valid(ball) and ball.global_position.z + FOLLOW.z > stop:
		at = ball.global_position + FOLLOW
		look = ball.global_position + Vector3(0, 0, -1.5)
	var k := 1.0 - exp(-FOLLOW_RATE * delta)
	_cam.global_position = _cam.global_position.lerp(at, k)
	_look = _look.lerp(look, k)
	_cam.look_at(_look)


func _camera_back() -> void:
	if is_instance_valid(_cam) and _cam.current:
		Game.player.camera.make_current()


# --- Für automatische Tests -------------------------------------------------------------------

## --autoplay: von etwas rechts der Mitte in die Tasche rechts neben dem Kopfkegel, mit der normalen Streuung;
## nach dem Frame „Weiter“. Gibt aus, was passiert ist.
func debug_step() -> String:
	if not active or _wait > 0.0:
		return ""
	if _phase == Phase.AIM:
		_offset = 0.12
		Game.player.global_position = lane.stand_spot(_offset)
		var to := lane.head_spot() + Vector3(0.065, 0, 0) - _release_point()
		_release(atan2(-to.x, -to.z) + randfn(0.0, SPREAD))
		return "Wurf in die Tasche"
	if _phase == Phase.DONE and not _buttons.is_empty():
		var info := _log.text
		_buttons[0].pressed.emit()
		return info
	return ""
