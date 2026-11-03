class_name PeepholeView
extends CanvasLayer
## Blick durch den Türspion einer Zimmertür (Spielkonzept 7.17, ZIM-166). Eine Kamera steht im Flur vor der Linse und
## malt in ein kleines SubViewport (PX²) – nur solange man hinsieht, sonst steht es still (Zielhardware, ZIM-124).
## shaders/peephole_view.gdshader macht daraus das runde Fischauge mit Messingrand. Die Spielerkamera zeichnet
## währenddessen nichts (cull_mask 0), ShadowBudget zählt die Lichter vom Spion aus (view_from), die Taschenlampe ist
## abgeblendet. Bewegen, [E] oder Esc beendet das Hinsehen; Lärm macht es keinen. Was im Spion zu sehen ist, „sieht“ der
## Spieler (Player.view_camera – Sichtung 4.5). Selten beugt sich der Leviathan an die Linse (EYE_*).
## Nebenbei hält es die Lichtpunkte der Spione in der Nähe aktuell (Door.update_lenses).

const PX := 512
const CAM_FOV := 150.0
const FIELD := 150.0            ## Bildwinkel im Spion – mehr (~160°) machte die Mitte bei PX zu grob
const CAM_OUT := 0.13           ## Kamera so weit vor dem Blatt (außerhalb der Kollision der Tür)
const DARK := 0.06              ## Licht im Flur (MonsterDirector.light_at), unter dem fast nichts zu sehen ist …
const BRIGHT := 0.45            ## … und ab dem das Bild voll hell ist
const DIM_MIN := 0.05
const LEAVE_DIST := 1.3         ## so weit vom Spion weg (Stoß, Sog) endet das Hinsehen
const LENS_EVERY := 0.5         ## Lichtpunkte der Spione so oft prüfen (s)
## Auge des Leviathans: steht er höchstens EYE_RANGE vor der Tür, ist die Neugier dort mindestens EYE_CURIOSITY und
## schaut man schon EYE_AFTER s, wird einmal je Hinsehen mit EYE_CHANCE gewürfelt – höchstens einmal am Spieltag.
const EYE_RANGE := 3.0
const EYE_CURIOSITY := 70.0
const EYE_CHANCE := 0.2
const EYE_AFTER := 1.0
const EYE_TIME := 2.6
const EYE_SHOCK := 0.45
## Sichtebene für das, was im Spion nicht zu sehen sein darf (das Kind zu viel, 4.31)
const HIDDEN_LAYER := 1 << 16

static var _eye_day := -1
## --spion=auge: das Auge kommt beim nächsten Hinsehen sicher, sobald er nah genug ist
static var debug_eye := false

var door: Door
var camera: Camera3D
var _vp: SubViewport
var _rect: ColorRect
var _mat: ShaderMaterial
var _hint: Label
var _player: Player
var _time := 0.0
var _eye_rolled := false
var _eye_time := -1.0
var _lens_timer := 0.0
var _main_mask := 0
var _traced := false


func _ready() -> void:
	layer = 4   # unter PostFx (5): Unschärfe, Rausch und Angst wirken auch auf das Spionbild
	_player = get_parent() as Player
	_rect = ColorRect.new()
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rect.visible = false
	add_child(_rect)
	_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_hint = Label.new()
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint.add_theme_color_override("font_color", Color(0.75, 0.72, 0.65))
	_hint.add_theme_font_size_override("font_size", 18)
	_hint.visible = false
	add_child(_hint)
	_hint.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	_hint.offset_top = -54.0
	_hint.offset_bottom = -24.0
	_hint.offset_left = -300.0
	_hint.offset_right = 300.0


func _setup() -> void:
	_vp = SubViewport.new()
	_vp.size = Vector2i(PX, PX)
	_vp.render_target_update_mode = SubViewport.UPDATE_DISABLED
	add_child(_vp)
	camera = Camera3D.new()
	camera.fov = CAM_FOV
	camera.near = 0.02
	camera.far = 40.0
	camera.cull_mask = 0xFFFFF & ~PlayerBody.LAYER & ~HIDDEN_LAYER
	_vp.add_child(camera)
	camera.current = true
	var env := _player.get_world_3d().environment
	if env:
		# wie die Welt, ohne Bildschirmspiegelung und Lichtnebel (zu teuer für ein Bild im Bild, vgl. Mirror)
		var own := env.duplicate() as Environment
		own.ssr_enabled = false
		own.volumetric_fog_enabled = false
		camera.environment = own
	_mat = ShaderMaterial.new()
	_mat.shader = load("res://shaders/peephole_view.gdshader")
	_mat.set_shader_parameter("view", _vp.get_texture())
	_mat.set_shader_parameter("cam_fov", CAM_FOV)
	_mat.set_shader_parameter("field", FIELD)
	_mat.set_shader_parameter("px", float(PX))
	_rect.material = _mat


func is_active() -> bool:
	return door != null


func start(d: Door) -> void:
	if door != null:
		return
	if _vp == null:
		_setup()
	door = d
	_time = 0.0
	_eye_rolled = false
	_eye_time = -1.0
	_traced = false
	var out := d.corridor_dir()
	var at := d.peephole_point() + out * CAM_OUT
	camera.global_transform = Transform3D(Basis.looking_at(out, Vector3.UP), at)
	_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_rect.visible = true
	_hint.text = "Zurück: [E] · Esc · bewegen"
	_hint.visible = true
	_main_mask = _player.camera.cull_mask
	_player.camera.cull_mask = 0   # das Zimmer liegt hinter dem Spionbild – nicht doppelt zeichnen
	if _player.held and _player.held.flashlight:
		_player.held.flashlight.set_masked(true)   # Blendung im Glas: die Lampe hilft nicht
	ShadowBudget.view_from = at
	ShadowBudget.wake = true
	_set_eye(0.0)
	_update_dim()
	if Game.tracing:
		print("[Spion] Tür %s: hingesehen, Licht im Flur %.2f%s" % [d.room_no, _light(), _knock_text()])


func stop(why: String = "") -> void:
	if door == null:
		return
	if Game.tracing:
		print("[Spion] Tür %s: beendet (%s) nach %.1f s%s" % [door.room_no, why, _time, _knock_text()])
	door = null
	_vp.render_target_update_mode = SubViewport.UPDATE_DISABLED
	_rect.visible = false
	_hint.visible = false
	_player.camera.cull_mask = _main_mask
	if _player.held and _player.held.flashlight:
		_player.held.flashlight.set_masked(false)
	ShadowBudget.view_from = Vector3.INF
	ShadowBudget.wake = true


## E und Esc beenden, die Maus dreht nichts (der Spion sitzt fest in der Tür).
func _input(event: InputEvent) -> void:
	if door == null:
		return
	if event is InputEventMouseMotion:
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("interact") or event.is_action_pressed("pause"):
		stop("Taste")
		get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	_lens_timer -= delta
	if _lens_timer <= 0.0 and door == null and _player.is_inside_tree():
		_lens_timer = LENS_EVERY
		Door.update_lenses(_player.global_position)
	if door == null:
		return
	_time += delta
	var why := _leave_reason()
	if why != "":
		stop(why)
		return
	_update_dim()
	if _eye_time >= 0.0:
		_update_eye(delta)
		return
	if not _eye_rolled and (_time >= EYE_AFTER or debug_eye):
		_check_eye()
	if Game.tracing and not _traced and _time >= 2.0:
		_traced = true
		print("[Spion] im Bild: %s" % _seen_text())


func _leave_reason() -> String:
	var p := _player
	if p.dead or p.in_dialog or p.hiding or p.gripped or p.sleeping or not is_instance_valid(door):
		return "unterbrochen"
	if p.move_input != Vector2.ZERO:
		return "bewegt"
	if door.lets_light():
		return "Tür offen"
	if p.camera.global_position.distance_to(door.peephole_point()) > LEAVE_DIST:
		return "weggestoßen"
	return ""


## Licht im Flur vor der Linse – im Dunkeln bleibt das Bild fast schwarz.
func _light() -> float:
	if Game.director == null or camera == null:
		return 1.0
	return Game.director.light_at(camera.global_position - camera.global_transform.basis.z * 0.8)


func _update_dim() -> void:
	_mat.set_shader_parameter("dim", lerpf(DIM_MIN, 1.0, smoothstep(DARK, BRIGHT, _light())))


# --- Das Auge (selten) -----------------------------------------------------------------

func _check_eye() -> void:
	var m := Game.monster
	var d := Game.director
	if m == null or d == null or not m.is_active() or m.state in [Monster.State.CHASE, Monster.State.KILL, Monster.State.REPELLED, Monster.State.RETREAT]:
		return
	var front := camera.global_position
	var flat := Vector2(m.global_position.x - front.x, m.global_position.z - front.z)
	if flat.length() > EYE_RANGE or absf(m.global_position.y - door.global_position.y) > 1.5:
		return
	if d.curiosity_at(front) < EYE_CURIOSITY and not debug_eye:
		return
	_eye_rolled = true   # einmal je Hinsehen
	var day := Calendar.day_of(d.elapsed)
	if not debug_eye and (day == _eye_day or randf() >= EYE_CHANCE):
		return
	debug_eye = false
	_eye_day = day
	_eye_time = 0.0
	# Er beugt sich an die Linse und weiß jetzt, dass du da bist. Danach steht er wieder, wo er war, der Tür zugewandt –
	# dicht davor (Monster._open_doors, 1,5 m) risse er sie sofort auf, und der Schreck wäre ein Überfall.
	var to := Vector3(front.x, m.global_position.y, front.z)
	if m.global_position.distance_to(to) > 0.2:
		m.look_at(to, Vector3.UP)
	if not m.noticed:
		m.noticed = true
		d.on_monster_noticed()
	else:
		Game.play_sound("sting", 1.0)
		m.stare()
	Game.caption("[Ein Auge an der Linse]")
	if Game.tracing:
		print("[Spion] Auge an der Linse (Neugier %.0f, %.1f m)" % [d.curiosity_at(front), flat.length()])


func _update_eye(delta: float) -> void:
	_eye_time += delta
	var t := _eye_time
	_set_eye(smoothstep(0.0, 0.18, t))
	_mat.set_shader_parameter("pupil", lerpf(0.42, 0.24, smoothstep(0.2, 1.2, t)))   # die Pupille zieht sich zusammen
	_mat.set_shader_parameter("gaze", Vector2(sin(t * 2.3) * 0.6, cos(t * 1.7) * 0.3) * smoothstep(0.4, 1.4, t))
	_mat.set_shader_parameter("lid", smoothstep(EYE_TIME - 0.5, EYE_TIME - 0.15, t))
	if t >= EYE_TIME:
		_player.add_shock(EYE_SHOCK, false)
		stop("Auge")


func _set_eye(v: float) -> void:
	_mat.set_shader_parameter("eye", v)
	if v == 0.0:
		_mat.set_shader_parameter("lid", 0.0)
		_mat.set_shader_parameter("gaze", Vector2.ZERO)


# --- Protokoll (--trace) ---------------------------------------------------------------

func _knock_text() -> String:
	if Game.social == null or not Game.social.is_knocking() or door.room_no != LevelBuilder.PLAYER_ROOM:
		return ""
	var k: Dictionary = Game.social._knock
	return " · Klopfen %s, %.1f/%.0f s" % ["falsch" if k.get("fake", false) else "echt", float(k.get("time", 0.0)), Social.KNOCK_WAIT]


## Wer im Spion zu sehen ist (Mitte im Bild, Sichtlinie frei).
func _seen_text() -> String:
	var names: Array[String] = []
	var world := camera.get_world_3d()
	if Game.social:
		for g: Guest in Game.social.living_guests():
			var head := g.global_position + Vector3.UP * 1.2
			if camera.is_position_in_frustum(head) and head.distance_to(camera.global_position) < 15.0 \
					and Senses.clear_line(world, camera.global_position, head, g):
				names.append("%s (%s)" % [g.display_name, Guest.State.keys()[g.state].to_lower()])
	if Game.monster and Game.monster.is_active() and Game.director.player_can_see(Game.monster.global_position + Vector3.UP * 1.6):
		names.append("Leviathan")
	return ", ".join(names) if not names.is_empty() else "niemand"
