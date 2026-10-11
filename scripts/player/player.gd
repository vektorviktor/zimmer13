class_name Player
extends CharacterBody3D
## Ego-Perspektive-Spieler. Kapsel 1,80 m × 0,45 m (Spielkonzept 3.1).
## Kein Inventar: genau ein Gegenstand in der Hand (3.2).
## Kann sich in Schränken und unter Betten verstecken (3.4).

const HEIGHT := 1.8
const RADIUS := 0.225
const CROUCH_HEIGHT := 1.15
const EYE_HEIGHT := 1.68
const CROUCH_EYE_HEIGHT := 1.02
const WALK_SPEED := 2.6
const RUN_SPEED := 4.8
const CROUCH_SPEED := 1.3
const JUMP_VELOCITY := 3.6
const REACH := 2.2
const MOUSE_SENSITIVITY := 0.0022
const HIDE_COMFORT_TIME := 22.0   ## ab hier wird es im Versteck unangenehm
const HIDE_MAX_TIME := 38.0       ## dann muss man raus (wie in „Doors“)
const BREATH_MAX := 6.0
## Hand mit dem Gegenstand: unten rechts – beim Ansehen (Kompass) vor die Brust gehoben
const HAND_REST := Vector3(0.22, -0.22, -0.45)
const HAND_INSPECT := Vector3(0.0, -0.12, -0.3)
const INSPECT_TILT := 1.05        ## so weit kippt der Kompass zum Gesicht (rad)
const INSPECT_SPEED := 0.5        ## Laufen beim Draufschauen: halbe Geschwindigkeit

var head: Node3D
var camera: Camera3D
var held: Item
var crouching := false
var running := false
var dead := false
var hiding: HideSpot
var hide_time := 0.0
var hide_stress := 0.0
var breath := BREATH_MAX
var holding_breath := false
## Schock nach dem Tod eines Freundes (0..1, klingt ab) – Spielkonzept 6.8
var shock := 0.0
var shock_recovery := 1.0   ## schneller durch Gedenken oder Feiern (Social)
var in_dialog := false
var focused := false   ## sitzt konzentriert am Spieltisch → Vorwarnungen fallen weniger auf
var inspecting := false  ## schaut auf den Kompass in der Hand (Rechtsklick halten)

var _hand: Node3D
var _shape: CapsuleShape3D
var _collider: CollisionShape3D
var _ray: RayCast3D
var _focus = null
var _noise_timer := 0.0
var _bob := 0.0
var _hide_yaw := 0.0
var _hide_pitch := 0.0
var _breath_locked := false
var _crouch_toggled := false
var _dread_time := 0.0
var _shock_drop_timer := 0.0
var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")


func _ready() -> void:
	add_to_group("player")
	collision_layer = 8
	# Ebene 4 (Gegenstände, Pflanzen, Schalter) blockiert nicht – lose Dinge werden weggeschoben
	collision_mask = 1 | 2 | 16 | 64 | 128 | 256
	_shape = CapsuleShape3D.new()
	_shape.radius = RADIUS
	_shape.height = HEIGHT
	_collider = CollisionShape3D.new()
	_collider.shape = _shape
	_collider.position.y = HEIGHT / 2.0
	add_child(_collider)
	head = Node3D.new()
	head.position.y = EYE_HEIGHT
	add_child(head)
	camera = Camera3D.new()
	camera.fov = Settings.fov
	Settings.changed.connect(func() -> void: camera.fov = Settings.fov)
	camera.near = 0.03
	camera.far = 60.0
	head.add_child(camera)
	camera.make_current()
	_hand = Node3D.new()
	_hand.position = HAND_REST
	camera.add_child(_hand)
	_ray = RayCast3D.new()
	_ray.target_position = Vector3(0, 0, -REACH)
	_ray.collision_mask = 1 | 2 | 4 | 64 | 128 | 256 | HotelWindow.LAYER_BLOCK
	_ray.add_exception(self)
	camera.add_child(_ray)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _unhandled_input(event: InputEvent) -> void:
	if dead or in_dialog:
		return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		var rel: Vector2 = (event as InputEventMouseMotion).screen_relative * MOUSE_SENSITIVITY * Settings.mouse_sensitivity
		if Settings.invert_y:
			rel.y = -rel.y
		if hiding:
			_hide_yaw = clampf(_hide_yaw - rel.x, -0.45, 0.45)
			_hide_pitch = clampf(_hide_pitch - rel.y, -0.3, 0.3)
			_apply_hide_view()
		else:
			rotate_y(-rel.x)
			head.rotation.x = clampf(head.rotation.x - rel.y, -1.45, 1.45)
	elif event is InputEventMouseButton and event.pressed and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	elif event.is_action_pressed("interact"):
		if hiding:
			exit_hide()
		elif _focus != null and is_instance_valid(_focus):
			_focus.interact(self)
	elif event.is_action_pressed("drop") and not hiding:
		drop_held()


func _physics_process(delta: float) -> void:
	if dead:
		return
	_update_shock(delta)
	_update_dread(delta)
	_update_hand(delta)
	if in_dialog:
		velocity = Vector3.ZERO
		return
	if hiding:
		_update_hiding(delta)
		return
	_update_crouch()
	if not is_on_floor():
		velocity.y -= _gravity * delta
	elif Input.is_action_just_pressed("jump") and not crouching:
		velocity.y = JUMP_VELOCITY
	var input := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var dir := (transform.basis * Vector3(input.x, 0, input.y)).normalized()
	running = Input.is_action_pressed("run") and not crouching and input.length() > 0.1
	var speed := CROUCH_SPEED if crouching else (RUN_SPEED if running else WALK_SPEED)
	if held and held.is_large:
		speed *= 0.8
	if inspecting:
		speed *= INSPECT_SPEED
	velocity.x = dir.x * speed
	velocity.z = dir.z * speed
	move_and_slide()
	_push_items(dir, speed)

	var moving := is_on_floor() and input.length() > 0.1
	if moving:
		_bob += delta * speed * 2.4
	var eye := CROUCH_EYE_HEIGHT if crouching else EYE_HEIGHT
	var bob := sin(_bob) * 0.03 if moving else 0.0
	head.position.y = lerpf(head.position.y, eye + bob, minf(1.0, 12.0 * delta))

	# Rennen macht Lärm → das Monster wird neugierig
	if running and moving:
		_noise_timer -= delta
		if _noise_timer <= 0.0:
			_noise_timer = 0.6
			if Game.director:
				Game.director.on_noise(global_position, 1.0)
	_update_focus()


## Kompass ansehen: Rechtsklick halten hebt ihn vor die Brust, das Zifferblatt zum Gesicht
## gekippt. Im Versteck bleibt Rechtsklick „Luft anhalten“.
func _update_hand(delta: float) -> void:
	inspecting = held != null and held.kind == Item.Kind.COMPASS and Input.is_action_pressed("inspect") 		and hiding == null and not in_dialog
	var t := minf(1.0, 10.0 * delta)
	_hand.position = _hand.position.lerp(HAND_INSPECT if inspecting else HAND_REST, t)
	_hand.rotation.x = lerpf(_hand.rotation.x, INSPECT_TILT if inspecting else 0.0, t)


# --- Am Spieltisch sitzen -------------------------------------------------------

func sit_at(seat: Vector3, look: Vector3) -> void:
	if hiding:
		exit_hide()
	in_dialog = true
	focused = true
	_collider.disabled = true
	velocity = Vector3.ZERO
	global_position = seat
	var to := look - seat
	rotation = Vector3(0, atan2(-to.x, -to.z), 0)
	head.position.y = 1.2
	head.rotation.x = -0.55
	if Game.hud:
		Game.hud.set_prompt("")


func stand_up() -> void:
	in_dialog = false
	focused = false
	global_position += transform.basis.z * 0.5
	_collider.disabled = false
	head.position.y = EYE_HEIGHT
	head.rotation.x = 0.0


# --- Angst: engerer Blick, schwerer Atem (Spielkonzept 4.13) ---------------------------

func _update_dread(delta: float) -> void:
	var threat := Game.director.player_threat if Game.director else 0.0
	camera.fov = lerpf(camera.fov, Settings.fov - 10.0 * threat, minf(1.0, 2.0 * delta))
	_dread_time += delta * (1.5 + threat * 1.5)
	camera.position.y = sin(_dread_time) * 0.012 * threat


# --- Schock (Spielkonzept 6.8) -------------------------------------------------

func add_shock(amount: float, guilt: bool) -> void:
	shock = clampf(shock + amount, 0.0, 1.0)
	_shock_drop_timer = 8.0
	if guilt:
		Game.say("Das war deine Schuld …", 4.0)


func _update_shock(delta: float) -> void:
	if shock <= 0.0:
		camera.rotation = Vector3.ZERO
		return
	shock = maxf(0.0, shock - delta / 180.0 * shock_recovery)
	# Zittern
	camera.rotation = Vector3(randf_range(-1, 1), randf_range(-1, 1), randf_range(-1, 1)) * shock * 0.008
	# Zittrige Hände: ab und zu fällt etwas herunter
	_shock_drop_timer -= delta
	if _shock_drop_timer <= 0.0:
		_shock_drop_timer = 12.0
		if held and not hiding and randf() < shock * 0.35:
			Game.say("Deine Hände zittern – %s fällt dir herunter." % held.display_name)
			drop_held()


# --- Gegenstände -----------------------------------------------------------

func try_pick_up(item: Item) -> void:
	if item.kind == Item.Kind.COINS:
		Game.money += item.coin_value
		Game.say("+%d Geld" % item.coin_value, 2.0)
		Game.play_sound("blip")
		item.queue_free()
		return
	if held:
		Game.say("Du hast schon etwas in der Hand. Erst ablegen [G].")
		return
	if item.owner_id != "" and item.owner_id != "player" and Game.social:
		Game.social.on_player_took(item)
	item.owner_id = "player"
	held = item
	item.set_held(true)
	item.reparent(_hand, false)
	item.position = Vector3(-0.22, -0.28, -0.12) if item.is_large else Vector3.ZERO
	item.rotation = Vector3(0, PI, 0)
	Game.play_sound("blip", 0.5)
	if Game.hud:
		Game.hud.set_held(item.display_name)
	if item.kind == Item.Kind.COMPASS:
		Game.say("Ein alter Kompass. [Rechtsklick] halten, um draufzuschauen.", 3.5)


func drop_held() -> void:
	if held == null:
		return
	var item := held
	held = null
	var place := _drop_position()
	item.reparent(get_parent(), false)
	item.global_position = place
	item.rotation = Vector3(0, rotation.y, 0)
	item.set_held(false)
	item.linear_velocity = Vector3.ZERO
	Game.play_sound("thud", 0.4)
	if Game.hud:
		Game.hud.set_held("")


## Neuer Gegenstand direkt in die Hand (Ernte, Vorrat, Kauf, Geschenk).
func receive_item(item: Item) -> bool:
	if item == null:
		return false
	get_parent().add_child(item)
	item.global_position = global_position + Vector3.UP
	if held:
		Game.say("Die Hände sind voll – %s liegt jetzt vor dir." % item.display_name)
		item.global_position = _drop_position()
		return false
	try_pick_up(item)
	return true


## Gegenstand in der Hand wird verbraucht (z. B. Kerze in den Kürbis).
func consume_held() -> void:
	if held == null:
		return
	held.queue_free()
	held = null
	if Game.hud:
		Game.hud.set_held("")


func held_kind() -> int:
	return held.kind if held else -1


func held_key_id() -> String:
	if held and held.kind == Item.Kind.KEY:
		return held.key_id
	return ""


## Große Gegenstände (Kürbis …) brauchen beide Hände → keine Türen/Truhen öffnen.
func hands_blocked() -> bool:
	return held != null and held.is_large


func _drop_position() -> Vector3:
	var space := get_world_3d().direct_space_state
	var from := camera.global_position
	var forward := -camera.global_transform.basis.z
	var query := PhysicsRayQueryParameters3D.create(from, from + forward * 1.6, 1 | 2 | 4 | 64)
	query.exclude = [get_rid()]
	var hit := space.intersect_ray(query)
	var point: Vector3
	if not hit.is_empty():
		var normal: Vector3 = hit["normal"]
		var pos: Vector3 = hit["position"]
		if normal.y > 0.6:
			return pos + Vector3.UP * 0.01
		point = pos - forward * 0.3
	else:
		point = from + forward * 1.2
	var down := PhysicsRayQueryParameters3D.create(point + Vector3.UP * 0.1, point + Vector3.DOWN * 3.0, 1 | 4)
	down.exclude = [get_rid()]
	var floor_hit := space.intersect_ray(down)
	if floor_hit.is_empty():
		return point
	var floor_pos: Vector3 = floor_hit["position"]
	return floor_pos + Vector3.UP * 0.01


func _update_focus() -> void:
	_focus = null
	if _ray.is_colliding():
		var collider := _ray.get_collider()
		if collider and collider.has_meta("interactable"):
			_focus = collider.get_meta("interactable")
	if Game.hud:
		var text := ""
		if _focus != null and is_instance_valid(_focus):
			text = _focus.get_prompt(self)
		Game.hud.set_prompt(text)


# --- Ducken ---------------------------------------------------------------

## Lose Gegenstände vor den Füßen beiseiteschieben, statt an ihnen hängenzubleiben.
func _push_items(dir: Vector3, speed: float) -> void:
	if dir.length() < 0.1:
		return
	for node in get_tree().get_nodes_in_group("items"):
		var item := node as Item
		if item.is_held or item.freeze:
			continue
		var to := item.global_position - global_position
		if to.y > 0.8 or to.y < -0.3:
			continue   # liegt auf einem Tisch oder tiefer
		var flat := Vector3(to.x, 0, to.z)
		if flat.length() > RADIUS + 0.3 or flat.dot(dir) <= 0.0:
			continue
		var away := flat.normalized() if flat.length() > 0.01 else dir
		item.sleeping = false
		item.linear_velocity = (dir + away).normalized() * speed * 0.9 + Vector3.UP * 0.4


func _update_crouch() -> void:
	var want := Input.is_action_pressed("crouch")
	if Settings.crouch_toggle:
		if Input.is_action_just_pressed("crouch"):
			_crouch_toggled = not crouching
		want = _crouch_toggled
	if want and not crouching:
		_set_crouch(true)
	elif not want and crouching and _can_stand():
		_set_crouch(false)


func _set_crouch(value: bool) -> void:
	crouching = value
	_shape.height = CROUCH_HEIGHT if value else HEIGHT
	_collider.position.y = _shape.height / 2.0


func _can_stand() -> bool:
	var probe := CapsuleShape3D.new()
	probe.radius = RADIUS - 0.02
	probe.height = HEIGHT
	var params := PhysicsShapeQueryParameters3D.new()
	params.shape = probe
	params.transform = Transform3D(Basis(), global_position + Vector3(0, HEIGHT / 2.0 + 0.02, 0))
	params.collision_mask = collision_mask
	params.exclude = [get_rid()]
	return get_world_3d().direct_space_state.intersect_shape(params, 1).is_empty()


# --- Verstecken -------------------------------------------------------------

func enter_hide(spot: HideSpot) -> void:
	if held and held.is_large:
		Game.say("Du stellst %s ab." % held.display_name, 2.0)
		drop_held()
	_set_crouch(false)
	hiding = spot
	spot.occupant = self
	hide_time = 0.0
	hide_stress = 0.0
	breath = BREATH_MAX
	_breath_locked = false
	_collider.disabled = true
	velocity = Vector3.ZERO
	_hide_yaw = 0.0
	_hide_pitch = 0.0
	head.position.y = EYE_HEIGHT
	spot.on_enter()
	_apply_hide_view()
	if Game.hud:
		Game.hud.set_hide_mode(1 if spot.type == HideSpot.Type.WARDROBE else 2)
	if Game.director:
		Game.director.on_actor_hid(spot, self)


func exit_hide() -> void:
	if hiding == null:
		return
	var spot := hiding
	hiding = null
	spot.occupant = null
	spot.on_exit()
	global_position = spot.exit_point.global_position
	rotation = Vector3(0, spot.exit_point.global_rotation.y, 0)
	head.rotation.x = 0.0
	_collider.disabled = false
	holding_breath = false
	hide_stress = 0.0
	if Game.hud:
		Game.hud.set_hide_mode(0)
		Game.hud.set_hide_state(0.0, 1.0, false)


func _apply_hide_view() -> void:
	var view := hiding.view_point.global_transform
	global_position = view.origin - Vector3(0, EYE_HEIGHT, 0)
	rotation = Vector3(0, view.basis.get_euler().y + _hide_yaw, 0)
	head.rotation.x = _hide_pitch


func _update_hiding(delta: float) -> void:
	hide_time += delta
	# Luft anhalten: senkt die Chance, dass das Monster dich findet – aber nicht zu lange.
	if not Input.is_action_pressed("hold_breath"):
		_breath_locked = false
	holding_breath = Input.is_action_pressed("hold_breath") and not _breath_locked and breath > 0.0
	if holding_breath:
		breath -= delta
		if breath <= 0.0:
			breath = 0.0
			holding_breath = false
			_breath_locked = true
			Game.play_sound("gasp", 1.0)
			if Game.director:
				Game.director.on_noise(global_position, 1.5)
	else:
		breath = minf(BREATH_MAX, breath + delta * 0.8)
	# Unter Schock hält man es im Versteck kürzer aus
	var comfort := HIDE_COMFORT_TIME * (1.0 - 0.4 * shock)
	hide_stress = clampf((hide_time - comfort) / (HIDE_MAX_TIME - comfort), 0.0, 1.0)
	if Game.hud:
		Game.hud.set_hide_state(hide_stress, breath / BREATH_MAX, holding_breath)
		Game.hud.set_prompt("Verlassen [E]    Luft anhalten [Rechtsklick]")
	if hide_stress >= 1.0:
		Game.say("Du hältst es hier drin nicht mehr aus!")
		Game.play_sound("gasp", 1.0)
		exit_hide()
