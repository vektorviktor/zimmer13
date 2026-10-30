class_name BoilerCat
extends Node3D
## Die schwarze Kesselkatze (Spielkonzept 4.26): eine vierte Katze, die es nicht gibt. Nur nachts, erst nach dem ersten
## Angriff und nur im Untergeschoss sitzt sie irgendwo im Dunkeln, wo der Spieler gerade nicht hinsieht, und sieht ihn
## mit hellen Augen an. Gäste kennen sie nicht („Welche schwarze Katze?“) – sie kommen auch nicht hinunter.
## Sieht man sie an, steht sie auf und geht voraus: zum Kessel im Heizkeller, ist man schon dort, zur UV-Schrift
## Josefs. Unterwegs setzt sie sich und wartet, bis man nachkommt. Am Ziel sieht sie einen noch einmal an – und wenn
## man wegsieht, ist sie fort. Streicheln geht nicht: Die Hand greift ins Leere.
## Das ist Josef Ahrends Katze von 1987 (2.3): Darum tut das Monster Katzen nichts (6.11). Kommt es nah, flieht sie nicht
## und weint nicht wie die anderen – sie setzt sich und sieht ruhig zu ihm hin. Später (2.8) sitzt sie beim Ritual an
## der Werkstatttür und geht mit ihm ins Feuer – das Ritual fehlt noch.
## Modell: cat.glb (wie HotelCat) fast schwarz, mit leuchtenden Augen. Nicht gespeichert; einmal je Nacht.

enum State { GONE, WAIT, LEAD, SIT, ARRIVED }

const MODEL := HotelCat.MODEL
## Maßstab des Modells – groß wie Kasimir, die größte der Hotelkatzen
const SIZE := 1.6
const FUR := Color(0.07, 0.065, 0.07)
const EYE := Color(0.75, 0.95, 0.35)
const EYE_ENERGY := 2.5
const EYES := Vector3(0.022, 0.03, -0.075)   ## rechtes Auge vom Kopfknoten aus (m, Ruhepose) – nach dem Bild nachstellen
const WALK_SPEED := 0.55
const ANIM_SPEED := HotelCat.ANIM_SPEED
const SPAWN_RANGE := Vector2(6.0, 12.0)
const SPAWN_EVERY := 4.0
const SPAWN_CHANCE := 0.25            ## je Versuch, solange der Spieler nachts unten ist
const LEAD_AHEAD := 4.0               ## so weit geht sie voraus, dann wartet sie …
const FOLLOW_RANGE := 4.5             ## … bis man so nah ist
const ARRIVE_RANGE := 2.2             ## am Ziel so nah: Sie hat einen hingeführt
const GIVE_UP := 90.0                 ## folgt man ihr so lange nicht, ist sie fort
const MONSTER_CALM := 18.0            ## Monster so nah: Sie setzt sich und sieht zu ihm hin
const SIT_TURNS := [["Hips", Vector3.RIGHT, -0.55], ["frontleg", Vector3.RIGHT, 0.5], ["R_frontleg", Vector3.RIGHT, 0.5],
	["backleg", Vector3.RIGHT, -0.9], ["R_backleg", Vector3.RIGHT, -0.9], ["backleg1", Vector3.RIGHT, 1.6],
	["R_backleg1", Vector3.RIGHT, 1.6], ["head", Vector3.RIGHT, 0.35]]
const SIT_DROP := 0.05
const NOTE := "Im Keller war eine schwarze Katze, keine von unseren. Sie hat mich zum Kessel geführt und mich angesehen, als wüsste sie etwas. Dann war sie fort."
const PET_TEXT := "Deine Hand greift ins Leere. Die schwarze Katze sieht dich nur an."

var state := State.GONE
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
var _spawn_t := SPAWN_EVERY
var _wait := 0.0
var _seen_once := false
var _night_done := -1                 ## an diesem Spieltag (Nacht) war sie schon da
var _time := 0.0
var _moving := false
var _look_at := Vector3.INF


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


func get_prompt(_player: Player) -> String:
	return "Streicheln [E]" if visible else ""


func interact(_player: Player) -> void:
	Game.say(PET_TEXT, 3.5)
	_wait = minf(_wait, 0.5)
	state = State.ARRIVED   # danach ist sie fort, sobald man wegsieht


func _physics_process(delta: float) -> void:
	var player := Game.player
	var d := Game.director
	if player == null or d == null:
		return
	_time += delta
	if state == State.GONE:
		_spawn_t -= delta
		if _spawn_t <= 0.0:
			_spawn_t = SPAWN_EVERY
			_try_spawn(player)
		return
	var seen := d.player_can_see(global_position + Vector3.UP * 0.15)
	_wait -= delta
	match state:
		State.WAIT:   # sitzt und sieht den Spieler an, bis er sie bemerkt
			_look_at = player.global_position
			if seen:
				_seen_once = true
				_lead(player)
			elif _wait <= 0.0 or not _below(player.global_position):
				_vanish_unseen(seen)
		State.LEAD:
			if _walk(delta):
				state = State.SIT
				_wait = GIVE_UP
		State.SIT:
			_look_at = player.global_position
			var dist := player.global_position.distance_to(global_position)
			if global_position.distance_to(_goal) < 1.0 and dist < ARRIVE_RANGE:
				_arrive()
			elif dist < FOLLOW_RANGE:
				_lead(player)
			elif _wait <= 0.0 or not _below(player.global_position):
				_vanish_unseen(seen)
		State.ARRIVED:
			_look_at = player.global_position
			if not seen:
				_vanish_unseen(false)
	_calm_near_monster()
	_animate(delta)


## Nachts, nach dem ersten Angriff, der Spieler unten: irgendwo im Dunkeln, wo er nicht hinsieht.
func _try_spawn(player: Player) -> void:
	var d := Game.director
	if not d.first_attack_done or Calendar.phase() != Calendar.Phase.NIGHT or not _below(player.global_position) \
			or _night_done == _night_id() or randf() >= SPAWN_CHANCE:
		return
	if Game.monster and Game.monster.is_active() and Game.monster.global_position.distance_to(player.global_position) < 15.0:
		return
	var at := _floor_spot_near(player.global_position)
	if at == Vector3.INF:
		return
	global_position = at
	_face(player.global_position)
	state = State.WAIT
	_wait = GIVE_UP
	_seen_once = false
	visible = true
	_night_done = _night_id()
	_pick_goal(player)
	if Game.tracing:
		print("[Kesselkatze] sitzt bei %s, Ziel %s" % [at.snapped(Vector3.ONE * 0.1), _goal.snapped(Vector3.ONE * 0.1)])


## Eine Nacht = der Spieltag ihres Beginns (vor Mitternacht) – nach Mitternacht zählt der Vortag.
func _night_id() -> int:
	var e := Game.director.elapsed
	return Calendar.day_of(e) - (1 if Calendar.hour_of(e) < 12.0 else 0)


func _below(p: Vector3) -> bool:
	return p.y < LevelBuilder.CELLAR_Y + 2.0


## Ziel: der Kessel im Heizkeller – steht man schon darin, die UV-Schrift Josefs dort (wenn es sie gibt).
func _pick_goal(player: Player) -> void:
	var cellar := _builder.cellar_center()
	_goal = cellar
	if player.global_position.distance_to(cellar) < 9.0:
		for node in get_tree().get_nodes_in_group("uv_marks"):
			var mark := node as Node3D
			if mark.global_position.distance_to(cellar) < 12.0:
				_goal = mark.global_position
				break
	var map := get_world_3d().navigation_map
	_goal = NavigationServer3D.map_get_closest_point(map, _goal)


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
	_wait = GIVE_UP
	if player.global_position.distance_to(_goal) < ARRIVE_RANGE and global_position.distance_to(_goal) < 1.0:
		_arrive()


## Ein Schritt den Weg entlang; true = Ende des Stücks erreicht.
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
	var step := minf(WALK_SPEED * delta, to.length())
	var pos := global_position + to.normalized() * step
	var f := _floor_at(pos)
	if f != Vector3.INF:
		pos.y = f.y
	global_position = pos
	rotation.y = lerp_angle(rotation.y, atan2(-to.x, -to.z), minf(1.0, delta * 6.0))
	_moving = true
	return false


func _arrive() -> void:
	state = State.ARRIVED
	_moving = false
	if Game.notebook:
		Game.notebook.add_note("boiler_cat", NOTE, "Keller")
	if Game.tracing:
		print("[Kesselkatze] hat dich hingeführt")


func _vanish_unseen(seen: bool) -> void:
	if seen:
		return
	visible = false
	state = State.GONE
	_moving = false
	if Game.tracing:
		print("[Kesselkatze] ist fort")


## Monster nah: Sie flieht nicht, sie setzt sich und sieht ruhig zu ihm hin.
func _calm_near_monster() -> void:
	var m := Game.monster
	if m and m.is_active() and m.global_position.distance_to(global_position) < MONSTER_CALM:
		_moving = false
		if state == State.LEAD:
			state = State.SIT
		_look_at = m.global_position


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


func _floor_spot_near(p: Vector3) -> Vector3:
	var map := get_world_3d().navigation_map
	if NavigationServer3D.map_get_iteration_id(map) == 0:
		return Vector3.INF
	for attempt in 8:
		var a := randf() * TAU
		var dist := randf_range(SPAWN_RANGE.x, SPAWN_RANGE.y)
		var q := NavigationServer3D.map_get_closest_point(map, p + Vector3(cos(a) * dist, 0.3, sin(a) * dist))
		if absf(q.y - p.y) > 1.2:
			continue
		var f := _floor_at(q)
		if f == Vector3.INF or Game.director.player_can_see(f + Vector3.UP * 0.15) \
				or Game.director.light_at(f + Vector3.UP * 0.3) > 0.6:
			continue
		return f
	return Vector3.INF


func _floor_at(p: Vector3) -> Vector3:
	var q := PhysicsRayQueryParameters3D.create(p + Vector3.UP * 0.5, p + Vector3.DOWN * 1.2, 1)
	var hit := get_world_3d().direct_space_state.intersect_ray(q)
	return hit["position"] if not hit.is_empty() else Vector3.INF


## Debug (--kesselkatze): Nacht, der erste Angriff gilt als geschehen, du stehst im Kellergang – sie sitzt 5 m vor dir
## und sieht dich an; dreh dich nicht weg, dann geht sie voraus.
func debug_show() -> void:
	var d := Game.director
	d.first_attack_done = true
	var day := Calendar.day_of(d.elapsed)
	if Calendar.phase() != Calendar.Phase.NIGHT:
		d.elapsed = Calendar.at(day, 23.5)
	var cellar := _builder.cellar_center()
	var map := get_world_3d().navigation_map
	var stand := NavigationServer3D.map_get_closest_point(map, cellar + Vector3(0, 0, 22.0))
	TeleportUI.place_player(stand, cellar - stand)
	var player := Game.player
	var at := _floor_at(NavigationServer3D.map_get_closest_point(map, stand + (cellar - stand).normalized() * 5.0))
	if at == Vector3.INF:
		at = stand + (cellar - stand).normalized() * 5.0
	global_position = at
	_face(stand)
	state = State.WAIT
	_wait = GIVE_UP
	visible = true
	_night_done = _night_id()
	_pick_goal(player)
