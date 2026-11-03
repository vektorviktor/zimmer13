class_name PhotoMode
extends CanvasLayer
## Fotomodus (Debug, F12): freie Kamera, die durch Wände, Böden und Decken fliegt – um Stellen im Level gezielt
## anzusehen. Eine eigene Camera3D übernimmt den Blick des Spielers; der Spieler bleibt stehen, wo er war (ganz
## abgeschaltet: keine Eingaben, keine Bewegung), seine Figur ist zu sehen. Die Zeit steht (Baum pausiert); [T] lässt
## sie weiterlaufen – dann kann das Monster den stehenden Spieler holen. Das Schattenbudget läuft in beiden Fällen
## mit (ShadowBudget zählt ab der aktuellen Kamera), Spiegel ohnehin.
## Steuerung: Maus schaut, Vorwärts/Rückwärts/Links/Rechts fliegt in Blickrichtung, Springen und [E] hoch, Ducken und
## [Q] runter, Rennen ×4, Alt ×¼, Mausrad stellt das Grundtempo, [H] blendet Hud und Hinweis aus, F12 oder Esc zurück
## zum Spieler – er steht noch, wo er war –, [Enter] setzt ihn stattdessen unter die Kamera und beendet. Schaltet Erfolge für die Sitzung ab (8.11).

const SPEED := 3.0          ## Grundtempo (m/s)
const SPEED_RANGE := Vector2(0.25, 48.0)
const WHEEL_STEP := 1.25
const FAST := 4.0
const SLOW := 0.25
const NEAR := 0.02          ## dicht an Flächen heran, ohne dass sie wegschneiden

var active := false
var time_runs := false
var speed := SPEED
var camera: Camera3D
## Wird beim Start nachgeführt (main.gd), damit es auch bei stehender Zeit weiterzählt
var shadows: ShadowBudget
var _label: Label
var _yaw := 0.0
var _pitch := 0.0
var _prev_cam: Camera3D
var _was_paused := false
var _hud_was := true
var _hud_hidden := false
var _shadows_mode := Node.PROCESS_MODE_INHERIT
var _player_mode := Node.PROCESS_MODE_INHERIT


func _ready() -> void:
	layer = 6   # über PostFx (5): der Hinweis bleibt lesbar
	process_mode = Node.PROCESS_MODE_ALWAYS
	camera = Camera3D.new()
	camera.near = NEAR
	camera.cull_mask = 0xFFFFF   # mit der eigenen Figur
	add_child(camera)
	_label = Label.new()
	_label.add_theme_color_override("font_color", Color(0.85, 0.9, 0.95))
	_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_label.add_theme_constant_override("outline_size", 4)
	_label.add_theme_font_size_override("font_size", 15)
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label.visible = false
	add_child(_label)
	_label.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	_label.offset_left = 16.0
	_label.offset_top = -58.0
	_label.offset_bottom = -12.0


func start() -> void:
	var p := Game.player
	if active or p == null or p.dead or Game.creating:
		return
	Game.achievements.cheated()
	active = true
	_prev_cam = get_viewport().get_camera_3d()
	var from := _prev_cam if _prev_cam else p.camera
	camera.global_transform = from.global_transform
	camera.fov = Settings.fov
	camera.far = p.camera.far
	var euler := from.global_basis.get_euler()
	_pitch = euler.x
	_yaw = euler.y
	_apply_look()
	camera.make_current()
	_player_mode = p.process_mode
	p.process_mode = Node.PROCESS_MODE_DISABLED
	_was_paused = get_tree().paused
	if shadows:
		_shadows_mode = shadows.process_mode
		shadows.process_mode = Node.PROCESS_MODE_ALWAYS
		ShadowBudget.wake = true
	_hud_was = Game.hud.visible if Game.hud else true
	_set_hud_hidden(_hud_hidden)
	time_runs = false
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_update_label()


func stop() -> void:
	if not active:
		return
	active = false
	Game.player.process_mode = _player_mode
	if _prev_cam and is_instance_valid(_prev_cam):
		_prev_cam.make_current()
	else:
		Game.player.camera.make_current()
	if shadows:
		shadows.process_mode = _shadows_mode
		ShadowBudget.wake = true
	if Game.hud:
		Game.hud.visible = _hud_was
	_label.visible = false
	get_tree().paused = _was_paused


## Spieler unter die Kamera setzen (Augenhöhe abgezogen), Blick waagerecht wie die Kamera, und zurück.
func drop_player() -> void:
	var look := -camera.global_basis.z
	look.y = 0.0
	if look.length() < 0.01:
		look = -Game.player.global_basis.z
	var feet := camera.global_position - Vector3(0, Player.EYE_HEIGHT + 0.05, 0)   # place_player hebt um 5 cm
	stop()
	TeleportUI.place_player(feet, look)
	Game.say("Spieler an die Kamera gesetzt", 2.0)


func set_time_runs(on: bool) -> void:
	time_runs = on
	get_tree().paused = not on
	_update_label()


## Ein Stück fliegen: dir in Kamerarichtung (x rechts, y hoch – waagerecht zur Welt –, z zurück), Dauer in s.
func fly(dir: Vector3, seconds: float, factor := 1.0) -> void:
	var b := camera.global_basis
	var move := b.x * dir.x + b.z * dir.z + Vector3.UP * dir.y
	camera.global_position += move.limit_length(1.0) * speed * factor * seconds


func _process(delta: float) -> void:
	if not active:
		return
	if not time_runs and not get_tree().paused:
		get_tree().paused = true   # ein anderes Debug-Fenster (F6) hat die Pause beim Schließen aufgehoben
	if get_viewport().gui_get_focus_owner() == null:
		var dir := Vector3(Input.get_axis("move_left", "move_right"), 0.0, Input.get_axis("move_forward", "move_back"))
		if Input.is_action_pressed("jump") or Input.is_physical_key_pressed(KEY_E):
			dir.y += 1.0
		if Input.is_action_pressed("crouch") or Input.is_physical_key_pressed(KEY_Q):
			dir.y -= 1.0
		var factor := FAST if Input.is_action_pressed("run") else 1.0
		if Input.is_physical_key_pressed(KEY_ALT):
			factor *= SLOW
		if dir != Vector3.ZERO:
			fly(dir, delta, factor)
	_update_label()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("debug_photo") and not event.is_echo():
		if active:
			stop()
		elif not get_tree().paused:   # nicht über Menüs und Debug-Fenstern
			start()
		get_viewport().set_input_as_handled()
		return
	if not active:
		return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		var rel: Vector2 = (event as InputEventMouseMotion).screen_relative * Player.MOUSE_SENSITIVITY * Settings.mouse_sensitivity
		if Settings.invert_y:
			rel.y = -rel.y
		_yaw -= rel.x
		_pitch = clampf(_pitch - rel.y, -PI / 2.0 + 0.01, PI / 2.0 - 0.01)
		_apply_look()
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.pressed:
		var button := (event as InputEventMouseButton).button_index
		if button == MOUSE_BUTTON_WHEEL_UP or button == MOUSE_BUTTON_WHEEL_DOWN:
			var step := WHEEL_STEP if button == MOUSE_BUTTON_WHEEL_UP else 1.0 / WHEEL_STEP
			speed = clampf(speed * step, SPEED_RANGE.x, SPEED_RANGE.y)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("pause"):
		stop()
		get_viewport().set_input_as_handled()
	elif event is InputEventKey and event.pressed and not event.is_echo():
		match (event as InputEventKey).physical_keycode:
			KEY_T:
				set_time_runs(not time_runs)
			KEY_H:
				_set_hud_hidden(not _hud_hidden)
			KEY_ENTER, KEY_KP_ENTER:
				drop_player()
			_:
				return
		get_viewport().set_input_as_handled()


func _apply_look() -> void:
	camera.global_basis = Basis.from_euler(Vector3(_pitch, _yaw, 0.0))


func _set_hud_hidden(on: bool) -> void:
	_hud_hidden = on
	if Game.hud:
		Game.hud.visible = _hud_was and not on
	_label.visible = active and not on


func _update_label() -> void:
	if not _label.visible:
		return
	var at := camera.global_position
	_label.text = "Fotomodus · %s m/s (Mausrad) · Zeit %s [T] · x %.2f  y %.2f  z %.2f\nWASD fliegen · Leertaste/E hoch · Strg/Q runter · Umschalt schnell · Alt langsam · [H] Hinweis aus · Enter: Spieler hierher · F12/Esc zurück" % [
		String.num(speed, 2), "läuft" if time_runs else "steht", at.x, at.y, at.z]
