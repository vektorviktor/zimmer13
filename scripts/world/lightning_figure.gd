class_name LightningFigure
extends Node3D
## Gestalt im Blitz (Spielkonzept 7.8): Bei manchem Blitz steht für einen Augenblick eine dunkle, zu große Gestalt
## zwischen den Bäumen – nur im ersten Aufzucken; beim zweiten, etwas später, ist sie fort. Halluzination oder
## Lakengeist, das bleibt offen: Sie tut nichts, hinterlässt nichts, niemand sonst sieht sie; wer sie sieht, erschrickt
## ein wenig. Sie erscheint nur, wo der Spieler gerade hinsieht – im Garten oder durch ein Fenster mit offenem Vorhang,
## in RANGE Abstand unter freiem Himmel, mit freier Sicht; am liebsten neben einem Baum. Weather.lightning ruft
## place, _update_flash zeigt und versteckt.

const CHANCE := 0.2               ## je Blitz
const RANGE := Vector2(9.0, 40.0)  ## so weit vom Spieler (m)
const VIEW_COS := 0.88            ## so nah an der Blickrichtung (cos des Winkels, waagerecht)
const BESIDE := Vector2(0.9, 2.0)  ## so weit neben dem Stamm (m)
## Außer neben Bäumen: so viele Stellen im Blickfeld (± OPEN_ANGLE rad) probieren; Bäume zählen so viel mehr
const OPEN_TRIES := 10
const OPEN_ANGLE := 0.4
const TREE_BONUS := 0.3
const TRUNK_CLEAR := 1.0          ## so weit muss die Sichtlinie an Stämmen vorbeigehen (m)
const GONE := Vector2(0.35, 0.5)  ## dann folgt die zweite Zuckung (s) – ohne sie
const SHOCK := 0.05               ## Schreck beim Anblick (Spielkonzept 6.8)
const HEIGHT := 2.05              ## etwas zu groß für einen Menschen

var builder: LevelBuilder
var placed := false               ## steht für den laufenden Blitz bereit

var _body: Node3D
var _scared := false


func _ready() -> void:
	_body = Node3D.new()
	add_child(_body)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.012, 0.012, 0.014)
	mat.roughness = 1.0
	var s := HEIGHT / 2.05
	# langer Mantel bis zum Boden, schmale hängende Schultern, lange Arme, kleiner Kopf
	_part(_capsule(0.2, 1.62 * s), Vector3(0, 0.81 * s, 0), Vector3(1.0, 1.0, 0.62), mat)
	_part(_capsule(0.16, 0.5 * s), Vector3(0, 1.48 * s, 0), Vector3(1.35, 1.0, 0.7), mat)
	_part(_sphere(0.11), Vector3(0.02, 1.86 * s, 0.01), Vector3(0.9, 1.15, 1.0), mat)
	_part(_capsule(0.06, 0.18), Vector3(0, 1.73 * s, 0), Vector3.ONE, mat)
	for side in [-1.0, 1.0]:
		var arm := _part(_capsule(0.048, 0.92 * s), Vector3(side * 0.25, 1.2 * s, 0.0), Vector3.ONE, mat)
		arm.rotation.z = side * 0.07
	_body.rotation.z = 0.04   # steht leicht schief
	visible = false


func _part(mesh: Mesh, pos: Vector3, scale_by: Vector3, mat: Material) -> MeshInstance3D:
	var mi := Geo.mesh(_body, mesh, mat, pos)
	mi.scale = scale_by
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	return mi


func _capsule(radius: float, height: float) -> CapsuleMesh:
	var c := CapsuleMesh.new()
	c.radius = radius
	c.height = height
	return c


func _sphere(radius: float) -> SphereMesh:
	var s := SphereMesh.new()
	s.radius = radius
	s.height = radius * 2.0
	return s


## Sucht einen Platz, den der Spieler gerade sieht. forced (Debug): auch neben einem Baum außerhalb des Blicks – dann
## wird der Spieler hingedreht. false: kein Platz.
func place(forced: bool = false) -> bool:
	placed = false
	visible = false
	var p := Game.player
	if p == null or p.dead or p.sleeping or builder == null or p.camera == null:
		return false
	var eye := p.camera.global_position
	var look := -p.camera.global_basis.z
	look.y = 0.0
	if look.length() < 0.01:
		return false
	look = look.normalized()
	# Kandidaten: neben jedem Baum (bevorzugt) und ein paar Stellen im Blickfeld, irgendwo im Garten
	var spots: Array[Dictionary] = []
	for spot: Dictionary in builder.tree_spots:
		var trunk: Vector3 = spot["pos"]
		var side := Vector3(trunk.x - eye.x, 0.0, trunk.z - eye.z).normalized().cross(Vector3.UP)
		spots.append({"pos": trunk + side * randf_range(BESIDE.x, BESIDE.y) * (1.0 if randf() < 0.5 else -1.0), "tree": true})
	for i in OPEN_TRIES * (4 if forced else 1):
		var dir := look.rotated(Vector3.UP, randf_range(-OPEN_ANGLE, OPEN_ANGLE))
		spots.append({"pos": eye + dir * randf_range(RANGE.x, RANGE.y), "tree": false})
	var space := get_world_3d().direct_space_state
	var mask := 1 | HotelWindow.LAYER_BLOCK | HotelWindow.LAYER_FROSTED   # Wände, zugezogene Vorhänge, Milchglas
	var best := {}
	var best_score := -INF
	for spot: Dictionary in spots:
		var spot_pos: Vector3 = spot["pos"]
		var to := Vector3(spot_pos.x - eye.x, 0.0, spot_pos.z - eye.z)
		var dist := to.length()
		var facing := to.normalized().dot(look)
		if dist < RANGE.x or dist > RANGE.y or facing < (-1.0 if forced else VIEW_COS):
			continue
		var ground := space.intersect_ray(PhysicsRayQueryParameters3D.create(
			Vector3(spot_pos.x, eye.y + 2.0, spot_pos.z), Vector3(spot_pos.x, eye.y - 8.0, spot_pos.z), 1))
		if ground.is_empty():
			continue
		spot_pos = ground["position"]
		if not builder.is_outdoor(spot_pos + Vector3.UP * 0.5):
			continue
		var clear := true   # freie Sicht auf Brust und Kopf
		for h in [1.3, 1.85]:
			var q := PhysicsRayQueryParameters3D.create(eye, spot_pos + Vector3.UP * h, mask)
			q.exclude = [p.get_rid()]
			if not space.intersect_ray(q).is_empty():
				clear = false
				break
		if not clear or _behind_trunk(eye, spot_pos):
			continue
		var score := facing + (TREE_BONUS if spot["tree"] else 0.0) + randf() * 0.1
		if score > best_score:
			best_score = score
			best = {"pos": spot_pos, "dist": dist, "facing": facing}
	if best.is_empty():
		if Game.tracing and forced:
			print("[Wetter] Gestalt im Blitz: keine Stelle in Sicht")
		return false
	global_position = best["pos"]
	var toward := Vector3(eye.x, global_position.y, eye.z)
	if toward.distance_to(global_position) > 0.1:
		look_at(toward, Vector3.UP, true)   # schaut her (+Z zum Spieler)
	if forced and best["facing"] < VIEW_COS:   # Debug: hindrehen
		var dir := global_position - p.global_position
		p.rotation.y = atan2(-dir.x, -dir.z)
		p.head.rotation.x = 0.0
	placed = true
	_scared = false
	if Game.tracing:
		print("[Wetter] Gestalt im Blitz bei %s, %.0f m" % [global_position.snapped(Vector3.ONE * 0.1), best["dist"]])
	return true


## Steht ein Baumstamm zwischen Auge und Stelle? Der sichtbare Stamm ist dicker als seine Kollision.
func _behind_trunk(eye: Vector3, spot_pos: Vector3) -> bool:
	var a := Vector2(eye.x, eye.z)
	var b := Vector2(spot_pos.x, spot_pos.z)
	for spot: Dictionary in builder.tree_spots:
		var trunk: Vector3 = spot["pos"]
		var t := Vector2(trunk.x, trunk.z)
		if t.distance_to(b) > 0.5 and Geometry2D.get_closest_point_to_segment(t, a, b).distance_to(t) < TRUNK_CLEAR:
			return true
	return false


## Weather: im ersten Aufzucken zeigen, danach fort (placed fällt).
func set_shown(on: bool) -> void:
	visible = on
	if not on:
		placed = false
		return
	Game.shot_event("figure", 10)
	if not _scared and Game.player:
		_scared = true
		Game.player.add_shock(SHOCK, false)
