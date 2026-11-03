class_name BoilerCat
extends Node3D
## Die schwarze Kesselkatze (Spielkonzept 4.26): eine vierte Katze, die es nicht gibt. Gäste kennen sie nicht
## („Welche schwarze Katze?“). Das ist Josef Ahrends Katze von 1987 (2.3): Darum tut das Monster Katzen nichts (6.11).
## Kommt es nah, flieht sie nicht und weint nicht wie die anderen – sie setzt sich und sieht ruhig zu ihm hin.
## Führerin zu den Story-Punkten (ZIM-99): Nachts nach dem ersten Angriff, im ganzen Haus und höchstens einmal je Nacht
## taucht sie mit einer Chance auf, wenn ein noch nicht gefundener Story-Punkt in der Nähe ist – nah am Spieler, in
## seiner Blickrichtung, aber nicht direkt vor ihm, aus einer Rauchschliere. Sie verharrt, sieht ihn mit hellen Augen
## an und maunzt leise, dann geht sie zum Punkt voraus und wartet unterwegs, bis man nachkommt; vor einer geschlossenen
## Tür setzt sie sich davor. Nach höchstens einer Minute löst sie sich in Rauchschlieren auf, auch wenn das Ziel nicht
## erreicht ist – am Ziel schon, wenn man sie kurz angesehen hat. Streicheln geht nicht: Die Hand greift ins Leere.
## Später (2.8) sitzt sie beim Ritual im alten Heizkeller und geht mit ihm ins Feuer – das Ritual fehlt noch.
## Story-Punkte: Gruppe STORY_GROUP, Kennung in Meta „story_id“ (_tag_story_points). Gefunden zählt, was schon einen
## Zustand hat (Notiz, Aufgabe, Schlüssel am Bund); UV-Schriften meldet UvMark. Gespeichert: die gefundenen Punkte
## und die Nacht ihres letzten Auftauchens.
## Modell: cat.glb (wie HotelCat) fast schwarz, mit leuchtenden Augen.

enum State { GONE, WAIT, LEAD, SIT, ARRIVED, SMOKE }

const MODEL := HotelCat.MODEL
## Maßstab des Modells – groß wie Kasimir, die größte der Hotelkatzen
const SIZE := 1.6
const FUR := Color(0.07, 0.065, 0.07)
const EYE := Color(0.75, 0.95, 0.35)
const EYE_ENERGY := 2.5
const EYES := Vector3(0.022, 0.03, -0.075)   ## rechtes Auge vom Kopfknoten aus (m, Ruhepose) – nach dem Bild nachstellen
const WALK_SPEED := 0.55
const ANIM_SPEED := HotelCat.ANIM_SPEED
const CHECK_EVERY := 4.0
const APPEAR_CHANCE := 0.2            ## je Prüfung, solange nachts ein ungefundener Story-Punkt in der Nähe ist
const NEAR := 18.0                    ## „in der Nähe“: Luftlinie (m) …
const NEAR_PATH := 30.0               ## … und Weg dorthin höchstens so lang
const NEAR_MIN := 4.0                 ## näher steht man schon davor – dafür kommt sie nicht
const FLOOR_SPAN := Vector2(-1.0, 3.0)   ## Höhe des Punkts über den Füßen: noch dieselbe Ebene
const APPEAR_RANGE := Vector2(3.5, 7.0)
const APPEAR_ANGLE := Vector2(0.24, 0.52)   ## Winkel zur Blickrichtung (rad, etwa 14°–30°): im Bild, nicht direkt davor
const HOLD := Vector2(2.5, 8.0)       ## verharrt mindestens / höchstens so lange (s) …
const HOLD_SEEN := 1.5                ## … und geht, sobald man sie so lange angesehen hat
const MEOWS := [0.8, 4.5]             ## leises Maunzen (s nach dem Auftauchen), das zweite nur, wenn sie keiner ansah
const MEOW_RANGE := 9.0               ## Hörweite des Maunzens (m) – kein Lärm, niemand sonst reagiert
const LIFETIME := 60.0                ## höchstens so lange da, dann Rauch
const LEAD_AHEAD := 4.0               ## so weit geht sie voraus, dann wartet sie …
const FOLLOW_RANGE := 4.5             ## … bis man so nah ist
const ARRIVE_RANGE := 2.2             ## am Ziel so nah: Sie hat einen hingeführt
const LINGER := 2.5                   ## am Ziel sieht sie einen noch so lange an, dann Rauch
const LOSE_RANGE := 25.0              ## so weit weg der Spieler: Rauch
const MONSTER_CALM := 18.0            ## Monster so nah: Sie setzt sich und sieht zu ihm hin
const SMOKE_TIME := 3.2               ## so lange steigt der Rauch, dann ist sie ganz fort
const SMOKE_HIDE := 0.35              ## nach so vielen Sekunden Rauch ist der Körper fort
const SMOKE_COLOR := Color(0.12, 0.115, 0.13, 0.38)
const SMOKE_FRAME := 128              ## Kantenlänge eines Rauchbilds (Pixel), vier nebeneinander
const SIT_TURNS := [["Hips", Vector3.RIGHT, -0.55], ["frontleg", Vector3.RIGHT, 0.5], ["R_frontleg", Vector3.RIGHT, 0.5],
	["backleg", Vector3.RIGHT, -0.9], ["R_backleg", Vector3.RIGHT, -0.9], ["backleg1", Vector3.RIGHT, 1.6],
	["R_backleg1", Vector3.RIGHT, 1.6], ["head", Vector3.RIGHT, 0.35]]
const SIT_DROP := 0.05
const NOTE := "Eine schwarze Katze, keine von unseren, saß auf einmal da und sah mich an. Sie wollte, dass ich ihr folge. Dann war sie nur noch Rauch."
const PET_TEXT := "Deine Hand greift ins Leere. Die schwarze Katze sieht dich nur an."

## Story-Punkte (4.26): Fundstellen mit wichtigem Bezug zur Hauptgeschichte (GEGENSTAENDE.md, Spalte Handlung)
const STORY_GROUP := "story_points"
## Schlüssel, die als Story-Punkt liegen: Zimmer 18 an der Leviathanmauer, Schaltschlüssel in Zimmer 18 (7.4)
const STORY_KEYS := ["zimmer_18", "aufzug"]

var state := State.GONE
var found := {}                       ## Kennungen gefundener Story-Punkte (gespeichert)
var _builder: LevelBuilder
var _visual: Node3D
var _skeleton: Skeleton3D
var _anim: AnimationPlayer
var _bone := {}
var _rest: Array[Quaternion] = []
var _rot: Array[Quaternion] = []
var _body: StaticBody3D
var _path := PackedVector3Array()
var _path_i := 0
var _goal := Vector3.ZERO
var _target: Node3D                   ## der Story-Punkt, zu dem sie führt
var _target_id := ""
var _door: Door                       ## geschlossene Tür, vor der sie sitzt
var _check_t := CHECK_EVERY
var _life := 0.0                      ## seit dem Auftauchen (s)
var _seen_for := 0.0
var _meows := 0
var _wait := 0.0
var _seen_once := false
var _night_done := -1                 ## an diesem Spieltag (Nacht) war sie schon da
var _time := 0.0
var _moving := false
var _look_at := Vector3.INF
var _smoke_t := 0.0
var last_life := -1.0                 ## so lange war sie beim letzten Mal da, bis der Rauch kam (Prüfung)

static var _smoke_tex: ImageTexture
static var _smoke_mat: StandardMaterial3D


func setup(builder: LevelBuilder) -> BoilerCat:
	_builder = builder
	return self


func _ready() -> void:
	visible = false
	_visual = (load(MODEL) as PackedScene).instantiate()
	_visual.scale = Vector3.ONE * SIZE
	add_child(_visual)
	_skeleton = _visual.find_children("*", "Skeleton3D", true, false)[0]
	_anim = _visual.find_children("*", "AnimationPlayer", true, false)[0]
	_anim.get_animation("walk").loop_mode = Animation.LOOP_LINEAR
	for i in _skeleton.get_bone_count():
		_bone[_skeleton.get_bone_name(i)] = i
		_rest.append(_skeleton.get_bone_rest(i).basis.get_rotation_quaternion())
	_rot = _rest.duplicate()
	var mesh: MeshInstance3D = _visual.find_children("*", "MeshInstance3D", true, false)[0]
	var fur := Mat.psx(FUR, "", 1.0, Color.BLACK, 0.0, false)
	fur.set_shader_parameter("albedo_tex", (mesh.get_active_material(0) as BaseMaterial3D).albedo_texture)
	mesh.material_override = fur
	# Augen: zwei kleine leuchtende Punkte am Kopf, ohne Licht (sie leuchten nur selbst)
	if _bone.has("head"):
		var at := BoneAttachment3D.new()
		at.bone_name = "head"
		_skeleton.add_child(at)
		var eye_mat := Mat.psx(EYE, "", 1.0, EYE, EYE_ENERGY, false)
		# Lage in Metern vor dem Kopfknoten (Ruhepose, Blick nach −Z) – ins Bezugssystem des Knochens umgerechnet, das
		# Skelett ist intern anders skaliert (tools/build_cat.py)
		var head := _skeleton.global_transform * _skeleton.get_bone_global_rest(_bone["head"])
		for side in [-1.0, 1.0]:
			var eye := Geo.mesh(at, Geo.sphere(0.008, 0.012, 6, 3), eye_mat, Vector3.ZERO)
			eye.position = head.affine_inverse() * (head.origin + EYES * Vector3(side, 1, 1))
			eye.scale = Vector3.ONE / head.basis.get_scale()
	_body = StaticBody3D.new()   # nur für den Blick ([E]), blockiert niemanden
	_body.collision_layer = HotelCat.LAYER
	_body.collision_mask = 0
	_body.set_meta("interactable", self)
	Geo.add_box_shape(_body, Vector3(0.16, 0.26, 0.42) * SIZE, Vector3(0, 0.14 * SIZE, 0))
	add_child(_body)
	if _smoke_tex == null:
		_smoke_tex = _make_smoke_texture()


func get_prompt(_player: Player) -> String:
	return "Streicheln [E]" if visible and state != State.SMOKE else ""


func interact(_player: Player) -> void:
	Game.say(PET_TEXT, 3.5)
	_arrive()   # danach löst sie sich auf


func _physics_process(delta: float) -> void:
	var player := Game.player
	var d := Game.director
	if player == null or d == null:
		return
	_time += delta
	if state == State.GONE:
		_check_t -= delta
		if _check_t <= 0.0:
			_check_t = CHECK_EVERY
			_try_appear(player, false)
		return
	if state == State.SMOKE:
		_smoke_t += delta
		if _smoke_t >= SMOKE_HIDE:
			_visual.visible = false
		if _smoke_t >= SMOKE_TIME:
			visible = false
			_visual.visible = true
			state = State.GONE
		return
	_life += delta
	var seen := d.player_can_see(global_position + Vector3.UP * 0.15)
	_seen_once = _seen_once or seen
	var dist := player.global_position.distance_to(global_position)
	if _life >= LIFETIME or dist > LOSE_RANGE or not is_instance_valid(_target) or is_story_found(_target):
		_dissolve()
		return
	_wait -= delta
	match state:
		State.WAIT:   # verharrt, sieht den Spieler an und maunzt, bis er sie bemerkt
			_look_at = player.global_position
			_seen_for += delta if seen else 0.0
			if _meows < MEOWS.size() and _life >= MEOWS[_meows]:
				if _meows == 0 or _seen_for <= 0.0:
					Game.sound_at("meow", global_position, MEOW_RANGE, self, 0.45, "[Leises Maunzen]")
				_meows += 1
			if (_life >= HOLD.x and _seen_for >= HOLD_SEEN) or _life >= HOLD.y:
				_lead(player)
		State.LEAD:
			if _walk(delta):
				state = State.SIT
		State.SIT:
			_look_at = _door.center() if _door else player.global_position
			if _door and _door.is_open:
				_door = null
				_lead(player)
			elif (_door or global_position.distance_to(_goal) < 1.0) and dist < ARRIVE_RANGE:
				_arrive()
			elif not _door and global_position.distance_to(_goal) >= 1.0 and dist < FOLLOW_RANGE:
				_lead(player)
		State.ARRIVED:
			_look_at = player.global_position
			if _wait <= 0.0:
				_dissolve()
	_calm_near_monster()
	_animate(delta)


# --- Auftauchen ----------------------------------------------------------------------------

## Nachts, nach dem ersten Angriff, einmal je Nacht, mit APPEAR_CHANCE: ein ungefundener Story-Punkt in der Nähe? Dann
## taucht sie seitlich im Blickfeld auf. force (Debug): ohne Uhrzeit, Nacht und Zufall. true = sie ist da.
func _try_appear(player: Player, force: bool) -> bool:
	var d := Game.director
	if not force and (not d.first_attack_done or Calendar.phase() != Calendar.Phase.NIGHT
			or _night_done == _night_id() or randf() >= APPEAR_CHANCE or player.hiding != null):
		return false
	if not force and Game.monster and Game.monster.is_active() \
			and Game.monster.global_position.distance_to(player.global_position) < 15.0:
		return false
	var point := nearest_story_point(player)
	if point.is_empty():
		return false
	var at := _appear_spot(player, (point["node"] as Node3D).global_position)
	if at == Vector3.INF:
		return false
	global_position = at
	_face(player.global_position)
	_target = point["node"]
	_target_id = point["id"]
	_goal = point["goal"]
	_door = null
	state = State.WAIT
	_life = 0.0
	_seen_for = 0.0
	_meows = 0
	_seen_once = false
	_moving = false
	_visual.visible = true
	visible = true
	_night_done = _night_id()
	_smoke(40, 0.5)   # sie verdichtet sich aus einer Schliere
	Game.shot_event("kesselkatze", 30)
	if Game.tracing:
		print("[Kesselkatze] taucht auf bei %s, %.1f m vor dir, Ziel %s (%.0f m Weg)" % [at.snapped(Vector3.ONE * 0.1),
			at.distance_to(player.global_position), _target_id, float(point["length"])])
	return true


## Eine Nacht = der Spieltag ihres Beginns (vor Mitternacht) – nach Mitternacht zählt der Vortag.
func _night_id() -> int:
	var e := Game.director.elapsed
	return Calendar.day_of(e) - (1 if Calendar.hour_of(e) < 12.0 else 0)


## Boden nah am Spieler, in seiner Blickrichtung, aber nicht direkt davor: APPEAR_ANGLE seitlich (zuerst auf der Seite des
## Ziels), APPEAR_RANGE weit, auf seiner Ebene und frei im Blick. Vector3.INF = keiner gefunden.
func _appear_spot(player: Player, toward: Vector3) -> Vector3:
	var map := get_world_3d().navigation_map
	var fwd := -player.view_camera().global_transform.basis.z
	fwd.y = 0.0
	if fwd.length() < 0.1:
		return Vector3.INF
	fwd = fwd.normalized()
	var feet := player.global_position
	var side := 1.0 if fwd.signed_angle_to(toward - feet, Vector3.UP) >= 0.0 else -1.0
	for attempt in 12:
		var a := randf_range(APPEAR_ANGLE.x, APPEAR_ANGLE.y) * (side if attempt < 8 else -side)
		var want := feet + fwd.rotated(Vector3.UP, a) * randf_range(APPEAR_RANGE.x, APPEAR_RANGE.y)
		var q := NavigationServer3D.map_get_closest_point(map, want + Vector3.UP * 0.3)
		if absf(q.y - feet.y) > 0.6:
			continue
		var off := Vector3(q.x - feet.x, 0.0, q.z - feet.z)
		var angle := absf(fwd.signed_angle_to(off, Vector3.UP))
		if off.length() < APPEAR_RANGE.x * 0.85 or off.length() > APPEAR_RANGE.y * 1.1 \
				or angle < APPEAR_ANGLE.x * 0.8 or angle > APPEAR_ANGLE.y * 1.25:
			continue
		var f := _floor_at(q)
		if f == Vector3.INF or not Game.director.player_can_see(f + Vector3.UP * 0.15):
			continue
		return f
	return Vector3.INF


# --- Story-Punkte --------------------------------------------------------------------------

## Kennung einer UV-Schrift: ihr Ort auf den Dezimeter (die Schriften baut der LevelBuilder fest).
static func uv_id(mark: Node3D) -> String:
	var p := (mark.global_position * 10.0).round()
	return "uv:%d,%d,%d" % [p.x, p.y, p.z]


## Fundstellen der Hauptgeschichte in die Gruppe STORY_GROUP, Kennung in Meta „story_id“: UV-Schriften, Warnungszettel,
## Hotelregister, Notizbuch des Hausmeisters, Gustavs Tagebuch, die Schlüssel aus STORY_KEYS. Läuft bei jeder Suche
## (Schlüssel können neu liegen). Kommen Kesselbuch, Tagebuch in 042 & Co. dazu, hier eintragen.
func _tag_story_points() -> void:
	for node in get_tree().get_nodes_in_group("uv_marks"):
		if (node as UvMark).is_text():
			_tag(node, uv_id(node))
	for node in get_tree().get_nodes_in_group("warning_notes"):
		_tag(node, "note:" + (node as WarningNote).note_id)
	for node in get_tree().get_nodes_in_group("registers"):
		_tag(node, "register")
	for node in get_tree().get_nodes_in_group("caretaker_books"):
		_tag(node, "caretaker_book")
	if Game.social and Game.social.grinch and is_instance_valid(Game.social.grinch.diary):
		_tag(Game.social.grinch.diary, "gustav_diary")
	for node in get_tree().get_nodes_in_group("items"):
		var item := node as Item
		if item.kind == Item.Kind.KEY and item.key_id in STORY_KEYS and not item.is_held:
			_tag(item, "key:" + item.key_id)


func _tag(node: Node, id: String) -> void:
	if not node.is_in_group(STORY_GROUP):
		node.add_to_group(STORY_GROUP)
	node.set_meta("story_id", id)


## Gefunden? Was schon einen Zustand hat, fragt diesen (Notiz, Aufgabe, Schlüssel am Bund) und merkt es sich; der Rest
## (UV-Schriften) steht in found.
func is_story_found(node: Node) -> bool:
	var id := String(node.get_meta("story_id", ""))
	if id == "" or found.has(id):
		return true
	var nb := Game.notebook
	var yes := false
	match id.get_slice(":", 0):
		"note":
			yes = nb != null and nb.has_note("note_" + id.get_slice(":", 1))
		"register":
			yes = nb != null and nb.has_note("register_old")
		"gustav_diary":
			yes = nb != null and nb.has_note("gustav_diary")
		"caretaker_book":
			var task_id := String(CaretakerBook.TASKS["key"][0])
			yes = nb != null and nb.tasks.any(func(t: Dictionary) -> bool: return t["id"] == task_id)
		"key":
			yes = Game.player != null and Game.player.has_key(id.get_slice(":", 1))
	if yes:
		found[id] = true
	return yes


## Gefunden (UvMark: Schrift einmal ganz zu sehen).
func mark_found(id: String) -> void:
	if id != "" and not found.has(id):
		found[id] = true
		if Game.tracing:
			print("[Kesselkatze] Story-Punkt gefunden: " + id)


## Der nächste ungefundene Story-Punkt in der Nähe (NEAR, NEAR_PATH, auf der Ebene des Spielers, nicht schon davor):
## {node, id, goal (Ziel auf dem NavMesh), length (Weg)} – leer, wenn keiner.
func nearest_story_point(player: Player) -> Dictionary:
	var map := get_world_3d().navigation_map
	if NavigationServer3D.map_get_iteration_id(map) == 0:
		return {}
	_tag_story_points()
	var feet := player.global_position
	var from := NavigationServer3D.map_get_closest_point(map, feet)
	var best := {}
	for node in get_tree().get_nodes_in_group(STORY_GROUP):
		var n := node as Node3D
		if not n.is_visible_in_tree() or is_story_found(n):
			continue
		var p := n.global_position
		var flat := Vector2(p.x - feet.x, p.z - feet.z).length()
		if p.y - feet.y < FLOOR_SPAN.x or p.y - feet.y > FLOOR_SPAN.y or flat < NEAR_MIN or flat > NEAR:
			continue
		var goal := NavigationServer3D.map_get_closest_point(map, p)
		if Vector2(goal.x - p.x, goal.z - p.z).length() > 1.5:
			continue
		var path := NavigationServer3D.map_get_path(map, from, goal, true)
		if path.is_empty() or path[path.size() - 1].distance_to(goal) > 0.5:
			continue
		var length := 0.0
		for i in range(1, path.size()):
			length += path[i - 1].distance_to(path[i])
		if length <= NEAR_PATH and (best.is_empty() or length < float(best["length"])):
			best = {"node": n, "id": String(n.get_meta("story_id")), "goal": goal, "length": length}
	return best


# --- Führen --------------------------------------------------------------------------------

func _lead(player: Player) -> void:
	var map := get_world_3d().navigation_map
	var full := NavigationServer3D.map_get_path(map, global_position, _goal, true)
	# nur ein Stück voraus, dann wieder warten
	_path = PackedVector3Array()
	var left := LEAD_AHEAD
	var prev := global_position
	for p in full:
		var seg := prev.distance_to(p)
		if seg > left:
			_path.append(prev.lerp(p, left / seg))
			break
		_path.append(p)
		left -= seg
		prev = p
	_path_i = 0
	state = State.LEAD if not _path.is_empty() else State.SIT
	if player.global_position.distance_to(_goal) < ARRIVE_RANGE and global_position.distance_to(_goal) < 1.0:
		_arrive()


## Ein Schritt den Weg entlang; true = Ende des Stücks erreicht oder eine geschlossene Tür davor (das NavMesh kennt
## keine Türen) – dann sitzt sie davor.
func _walk(delta: float) -> bool:
	if _path_i >= _path.size():
		_moving = false
		return true
	var target := _path[_path_i]
	var to := target - global_position
	to.y = 0.0
	if to.length() < 0.08:
		_path_i += 1
		return false
	_door = _door_ahead(to.normalized())
	if _door:
		_moving = false
		return true
	var step := minf(WALK_SPEED * delta, to.length())
	var pos := global_position + to.normalized() * step
	var f := _floor_at(pos)
	if f != Vector3.INF:
		pos.y = f.y
	global_position = pos
	rotation.y = lerp_angle(rotation.y, atan2(-to.x, -to.z), minf(1.0, delta * 6.0))
	_moving = true
	return false


## Wie HotelCat._door_ahead: geschlossene Tür direkt voraus?
func _door_ahead(dir: Vector3) -> Door:
	var probe := global_position + dir * 0.45
	for door: Door in Door.near(probe):
		if door.is_open:
			continue
		var c := door.center()
		if absf(c.y - 1.05 - global_position.y) < 1.0 and Vector2(c.x - probe.x, c.z - probe.z).length() < 0.7:
			return door
	return null


## Hingeführt (oder gestreichelt): Sie sieht einen noch einen Moment an, dann Rauch.
func _arrive() -> void:
	if state == State.ARRIVED or state == State.SMOKE:
		return
	state = State.ARRIVED
	_moving = false
	_wait = LINGER
	if Game.tracing:
		print("[Kesselkatze] hat dich hingeführt (%s)" % _target_id)


## Löst sich in Rauchschlieren auf.
func _dissolve() -> void:
	if Game.notebook and _seen_once:
		Game.notebook.add_note("boiler_cat", NOTE, "Nachts")
	last_life = _life
	state = State.SMOKE
	_smoke_t = 0.0
	_moving = false
	if _anim.is_playing():
		_anim.stop()
	_smoke(70, 1.0)
	Game.shot_event("kesselkatze_rauch", 40)
	if Game.tracing:
		print("[Kesselkatze] löst sich in Rauch auf nach %.1f s" % _life)


## Monster nah: Sie flieht nicht, sie setzt sich und sieht ruhig zu ihm hin.
func _calm_near_monster() -> void:
	var m := Game.monster
	if m and m.is_active() and m.global_position.distance_to(global_position) < MONSTER_CALM:
		_moving = false
		if state == State.LEAD:
			state = State.SIT
		_look_at = m.global_position


# --- Rauch ---------------------------------------------------------------------------------

## Rauchschlieren aus ihrem Körper: dunkelgraue Fahnen, die sich drehen, aufsteigen und verwehen.
## amount Partikel, strength 0..1 (Auftauchen schwächer als Auflösen).
func _smoke(amount: int, strength: float) -> void:
	if _smoke_mat == null:
		_smoke_mat = _make_smoke_material()
	var life := SMOKE_TIME * (0.6 + 0.4 * strength)
	var smoke := Geo.particles(amount, life, 0.45, _smoke_mat, 0.06, 0.6)
	smoke.color = SMOKE_COLOR
	smoke.draw_order = CPUParticles3D.DRAW_ORDER_VIEW_DEPTH
	smoke.anim_offset_min = 0.0   # je Partikel eins der vier Bilder
	smoke.anim_offset_max = 1.0
	smoke.angular_velocity_min = -25.0   # die Fahnen drehen sich langsam
	smoke.angular_velocity_max = 25.0
	smoke.one_shot = true
	smoke.explosiveness = 0.55
	smoke.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	smoke.emission_box_extents = Vector3(0.07, 0.11, 0.19) * SIZE
	smoke.direction = Vector3.UP
	smoke.spread = 25.0
	smoke.initial_velocity_min = 0.2
	smoke.initial_velocity_max = 0.45 + 0.25 * strength
	smoke.gravity = Vector3(0, 0.3, 0)
	smoke.damping_min = 0.2
	smoke.damping_max = 0.5
	smoke.scale_amount_min = 0.5
	smoke.scale_amount_max = 1.3
	var grow := Curve.new()
	grow.add_point(Vector2(0.0, 0.6))
	grow.add_point(Vector2(1.0, 1.0 + strength))
	smoke.scale_amount_curve = grow
	get_parent().add_child(smoke)
	smoke.global_transform = Transform3D(global_basis.orthonormalized(), global_position + Vector3.UP * 0.14 * SIZE)
	smoke.emitting = true
	get_tree().create_timer(life + 0.5, false).timeout.connect(smoke.queue_free)


## Weicher Rauch: Billboard je Partikel mit Drehung, Bild aus anim_offset, Farbe und Deckkraft aus der Partikelfarbe,
## weich überblendet und an Wänden und Boden weich ausgeblendet (proximity_fade) – Mat.particle schneidet Alpha hart
## ab und rastert die Deckkraft, das zerfällt bei Rauch in Pünktchen.
static func _make_smoke_material() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_texture = _smoke_tex
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.vertex_color_use_as_albedo = true
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	m.particles_anim_h_frames = 4
	m.particles_anim_v_frames = 1
	m.particles_anim_loop = false
	m.roughness = 1.0
	m.metallic_specular = 0.0
	m.disable_receive_shadows = true
	m.proximity_fade_enabled = true
	m.proximity_fade_distance = 0.25
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	return m


## Vier Rauchbilder nebeneinander (je SMOKE_FRAME², mit Mipmaps): weiche Fahnen aus Rauschen, nach außen ausgeblendet,
## längs gestreckt, damit sie wie Schlieren aussehen. Farbe gibt der Partikel (SMOKE_COLOR).
static func _make_smoke_texture() -> ImageTexture:
	var n := SMOKE_FRAME
	var img := Image.create(n * 4, n, false, Image.FORMAT_RGBA8)
	var noise := FastNoiseLite.new()
	noise.seed = 1987
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	noise.fractal_octaves = 4
	noise.frequency = 0.035
	for frame in 4:
		for y in n:
			for x in n:
				var u := (x + 0.5) / n * 2.0 - 1.0
				var v := (y + 0.5) / n * 2.0 - 1.0
				var r := Vector2(u * 1.25, v).length()
				var fall := clampf(1.0 - r, 0.0, 1.0)
				fall = fall * fall * (3.0 - 2.0 * fall)
				# Rauschen quer gestaucht: Fahnen längs der Bildhöhe, je Bild ein anderer Ausschnitt
				var s := noise.get_noise_2d(x * 2.2 + frame * 300.0, y * 0.7) * 0.5 + 0.5
				var a := clampf((s - 0.28) * 1.8, 0.0, 1.0) * fall
				img.set_pixel(frame * n + x, y, Color(1, 1, 1, a))
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)


# --- Bild ----------------------------------------------------------------------------------

func _face(p: Vector3) -> void:
	var to := p - global_position
	rotation.y = atan2(-to.x, -to.z)


func _animate(delta: float) -> void:
	if _moving:
		if _anim.current_animation != "walk":
			_anim.play("walk")
		_anim.speed_scale = clampf(WALK_SPEED / (ANIM_SPEED * SIZE), 0.6, 3.0)
		_visual.position.y = 0.0
		return
	if _anim.is_playing():
		_anim.stop()
	if _look_at.is_finite():   # dreht sich langsam zu dem hin, den sie ansieht
		var to := _look_at - global_position
		rotation.y = lerp_angle(rotation.y, atan2(-to.x, -to.z), minf(1.0, delta * 1.5))
	_visual.position.y = lerpf(_visual.position.y, -SIT_DROP * SIZE, minf(1.0, 6.0 * delta))
	_rot = _rest.duplicate()
	for t in SIT_TURNS:
		_turn(t[0], t[1], t[2])
	_turn("tail1", Vector3.UP, sin(_time * 0.9) * 0.2)
	_turn("tail2", Vector3.UP, sin(_time * 0.9 - 0.6) * 0.3)
	for i in _rot.size():
		var current := _skeleton.get_bone_pose_rotation(i)
		_skeleton.set_bone_pose_rotation(i, current.slerp(_rot[i], minf(1.0, 8.0 * delta)))


## Wie HotelCat._turn: dreht einen Knochen um eine Achse im Skelettraum (Eltern vor Kindern).
func _turn(bone: String, axis: Vector3, angle: float) -> void:
	if not _bone.has(bone):
		return
	var i: int = _bone[bone]
	var parent_rot := Quaternion.IDENTITY
	var p := _skeleton.get_bone_parent(i)
	while p >= 0:
		parent_rot = _rot[p] * parent_rot
		p = _skeleton.get_bone_parent(p)
	_rot[i] = Quaternion((parent_rot.inverse() * axis).normalized(), angle) * _rot[i]


func _floor_at(p: Vector3) -> Vector3:
	var q := PhysicsRayQueryParameters3D.create(p + Vector3.UP * 0.5, p + Vector3.DOWN * 1.2, 1)
	var hit := get_world_3d().direct_space_state.intersect_ray(q)
	return hit["position"] if not hit.is_empty() else Vector3.INF


# --- Speichern -----------------------------------------------------------------------------

func save_state() -> Dictionary:
	var ids := found.keys()
	ids.sort()
	return {"found": ids, "night": _night_done}


func load_state(d: Dictionary) -> void:
	found.clear()
	for id in d.get("found", []):
		found[String(id)] = true
	_night_done = int(d.get("night", -1))
	state = State.GONE
	visible = false
	_visual.visible = true


# --- Debug ---------------------------------------------------------------------------------

## Debug (--kesselkatze[=pruefen|rauch]): Nacht, der erste Angriff gilt als geschehen. Du stehst im Untergeschoss 10 m
## vor dem ungefundenen Story-Punkt, der dem Heizraum am nächsten liegt, und siehst den Weg entlang – sie taucht seitlich
## auf, sieh hin, dann geht sie voraus. pruefen: bleib stehen; geprüft werden Auftauchen (Abstand, Winkel, sichtbar),
## Richtung (näher am Ziel), Auflösen nach höchstens LIFETIME und dass der Punkt danach als gefunden herausfällt.
## rauch: nach 3 s löst sie sich noch im Blickfeld auf (Rauchschlieren ansehen, mit --shot-on=kesselkatze_rauch).
func debug_show(value: String = "") -> void:
	var d := Game.director
	d.first_attack_done = true
	var day := Calendar.day_of(d.elapsed)
	if Calendar.phase() != Calendar.Phase.NIGHT:
		d.elapsed = Calendar.at(day, 23.5)
	var map := get_world_3d().navigation_map
	var cellar := _builder.cellar_center()
	_tag_story_points()
	var target: Node3D = null
	for node in get_tree().get_nodes_in_group(STORY_GROUP):
		var n := node as Node3D
		if n.is_visible_in_tree() and not is_story_found(n) and absf(n.global_position.y - cellar.y) < 3.0 \
				and (target == null or n.global_position.distance_to(cellar) < target.global_position.distance_to(cellar)):
			target = n
	if target == null:
		print("[Kesselkatze] FEHLER kein ungefundener Story-Punkt im Untergeschoss")
		return
	# 10 m den Weg zurück, Blick den Weg entlang zum Punkt
	var goal := NavigationServer3D.map_get_closest_point(map, target.global_position)
	var start := NavigationServer3D.map_get_closest_point(map, cellar + Vector3(0, 0, 22.0))
	var path := NavigationServer3D.map_get_path(map, goal, start, true)
	var stand := goal
	var left := 10.0
	for i in range(1, path.size()):
		var seg := path[i - 1].distance_to(path[i])
		if seg >= left:
			stand = path[i - 1].lerp(path[i], left / seg)
			break
		left -= seg
		stand = path[i]
	var ahead := goal
	for p in NavigationServer3D.map_get_path(map, stand, goal, true):
		if Vector2(p.x - stand.x, p.z - stand.z).length() > 2.0:
			ahead = p
			break
	TeleportUI.place_player(stand, ahead - stand)
	_night_done = -1
	state = State.GONE
	for attempt in 30:
		await get_tree().physics_frame
		if _try_appear(Game.player, true):
			break
	if state != State.WAIT:
		print("[Kesselkatze] FEHLER taucht nicht auf (Ziel %s)" % String(target.get_meta("story_id")))
		return
	if value == "pruefen":
		_debug_check(Game.player)
	elif value == "rauch":
		await get_tree().create_timer(3.0, false).timeout
		_dissolve()


func _debug_check(player: Player) -> void:
	var errors := 0
	var tree := get_tree()
	# Auftauchen: nah, im Bild, nicht direkt voraus
	var fwd := -player.view_camera().global_transform.basis.z
	fwd.y = 0.0
	var off := global_position - player.global_position
	off.y = 0.0
	var angle := rad_to_deg(absf(fwd.signed_angle_to(off, Vector3.UP)))
	var seen := Game.director.player_can_see(global_position + Vector3.UP * 0.15)
	var ok := off.length() >= APPEAR_RANGE.x * 0.85 and off.length() <= APPEAR_RANGE.y * 1.1 and seen \
		and angle >= rad_to_deg(APPEAR_ANGLE.x) * 0.8 and angle <= rad_to_deg(APPEAR_ANGLE.y) * 1.25
	errors += 0 if ok else 1
	print("[Kesselkatze] %s Auftauchen: %.1f m, %.0f° neben der Blickrichtung, im Bild %s" % ["ok" if ok else "FEHLER",
		off.length(), angle, seen])
	# Richtung: nach dem Verharren ein Stück näher am Ziel
	var target := _target
	var id := _target_id
	var before := global_position.distance_to(_goal)
	await tree.create_timer(HOLD.y + 6.0, false).timeout
	var after := global_position.distance_to(_goal) if state != State.SMOKE and state != State.GONE else 0.0
	ok = after < before - 1.5
	errors += 0 if ok else 1
	print("[Kesselkatze] %s Richtung: %.1f m → %.1f m bis zum Ziel" % ["ok" if ok else "FEHLER", before, after])
	# Auflösen nach höchstens einer Minute (der Spieler folgt nicht)
	var waited := 0.0
	while state != State.GONE and waited < LIFETIME + SMOKE_TIME + 5.0:
		await tree.create_timer(0.5, false).timeout
		waited += 0.5
	ok = state == State.GONE and last_life >= 0.0 and last_life <= LIFETIME + 0.05
	errors += 0 if ok else 1
	print("[Kesselkatze] %s Auflösen: nach %.1f s in Rauch, fort %s" % ["ok" if ok else "FEHLER", last_life,
		state == State.GONE])
	# Ein gefundener Punkt fällt heraus
	mark_found(id)
	var next := nearest_story_point(player)
	ok = is_instance_valid(target) and is_story_found(target) and (next.is_empty() or next["node"] != target)
	errors += 0 if ok else 1
	print("[Kesselkatze] %s gefunden fällt heraus: %s, nächster %s" % ["ok" if ok else "FEHLER", id,
		next.get("id", "keiner")])
	# Einmal je Nacht
	ok = _night_done == _night_id()
	errors += 0 if ok else 1
	print("[Kesselkatze] %s einmal je Nacht" % ("ok" if ok else "FEHLER"))
	print("[Kesselkatze] Prüfung fertig: %d Fehler" % errors)
