class_name Traces
extends Node3D
## Spuren des Monsters (Spielkonzept 4.13) an einer Stelle gesammelt:
##   Fußspuren – dunkel und nass, verblassen über einige Minuten (zeigen Weg und Alter)
##   Kratzspuren an Wänden und Türen, Blut, Handabdrücke am Milchglas – bleiben (TraceMark)
## Jede neue Spur wird auch den Gästen bekannt, die davon erzählen (Social.note_trace).

const FOOTPRINT_LIFE := 240.0
const MAX_FOOTPRINTS := 160

var _footprints: Array[Dictionary] = []   ## {node, material, age}


func _process(delta: float) -> void:
	var i := _footprints.size() - 1
	while i >= 0:
		var f := _footprints[i]
		f["age"] = float(f["age"]) + delta
		var k := 1.0 - float(f["age"]) / FOOTPRINT_LIFE
		if k <= 0.0:
			(f["node"] as Node).queue_free()
			_footprints.remove_at(i)
		else:
			(f["material"] as StandardMaterial3D).albedo_color.a = 0.85 * k
		i -= 1


# --- Fußspuren ----------------------------------------------------------------

func add_footprint(pos: Vector3, yaw: float) -> void:
	if _footprints.size() >= MAX_FOOTPRINTS:
		(_footprints[0]["node"] as Node).queue_free()
		_footprints.remove_at(0)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.06, 0.035, 0.03, 0.85)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.roughness = 0.2   # nass glänzend
	var foot := Node3D.new()
	add_child(foot)
	foot.global_position = Vector3(pos.x, _floor_y(pos) + 0.012, pos.z)
	foot.rotation.y = yaw
	# lang gezogener Fuß mit drei Zehen (Krallen)
	var sole := Geo.mesh(foot, Geo.box(Vector3(0.11, 0.004, 0.24)), mat, Vector3(0, 0, 0.02))
	sole.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for t in 3:
		var toe := Geo.mesh(foot, Geo.box(Vector3(0.025, 0.004, 0.08)), mat, Vector3(-0.04 + t * 0.04, 0, -0.13))
		toe.rotation.y = (t - 1) * 0.25
		toe.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_footprints.append({"node": foot, "material": mat, "age": 0.0})
	if _footprints.size() % 12 == 1:
		_report("footprint", pos)


func _floor_y(pos: Vector3) -> float:
	var query := PhysicsRayQueryParameters3D.create(pos + Vector3.UP * 0.5, pos + Vector3.DOWN * 1.0, 1)
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	return pos.y if hit.is_empty() else float((hit["position"] as Vector3).y)


# --- Bleibende Spuren ------------------------------------------------------------

## Kratzspuren an der Wand vor dem Monster (wenn es aufgehalten wird).
func scratch_wall_ahead(monster: Node3D) -> bool:
	var from := monster.global_position + Vector3.UP * 1.3
	var to := from + (-monster.global_transform.basis.z) * 1.8
	var hit := get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(from, to, 1))
	if hit.is_empty():
		return false
	var normal: Vector3 = hit["normal"]
	if absf(normal.y) > 0.3:
		return false
	add_scratch(hit["position"], normal)
	return true


func add_scratch(pos: Vector3, normal: Vector3) -> TraceMark:
	var mark := TraceMark.new().setup("scratch")
	add_child(mark)
	mark.global_position = pos + normal * 0.012
	mark.look_at(mark.global_position - normal, Vector3.UP)
	_report("scratch", pos)
	return mark


## Kratzspuren auf einer Tür – auf der Seite, von der das Monster kam.
func add_door_scratch(door: Door, from_pos: Vector3) -> TraceMark:
	var local := door.global_transform.affine_inverse() * from_pos
	var side := 1.0 if local.z >= 0.0 else -1.0
	var mark := TraceMark.new().setup("scratch")
	door.attach_mark(mark, side)
	_report("scratch", door.center())
	return mark


## Blut und Schleifspur, wo ein Gast geholt wurde.
func add_blood(pos: Vector3, yaw: float) -> TraceMark:
	var mark := TraceMark.new().setup("blood")
	add_child(mark)
	mark.global_position = Vector3(pos.x, _floor_y(pos) + 0.008, pos.z)
	mark.rotation = Vector3(-PI / 2.0, yaw, 0)
	_report("blood", pos)
	return mark


## Handabdruck auf der Flurseite eines Milchglasfensters.
func add_handprint(win: HotelWindow) -> TraceMark:
	var mark := TraceMark.new().setup("handprint")
	win.add_child(mark)
	mark.position = Vector3(randf_range(-0.3, 0.3), randf_range(-0.2, 0.25), -0.035)
	mark.rotation.y = PI
	_report("handprint", win.global_position)
	return mark


func _report(kind: String, pos: Vector3) -> void:
	if Game.social:
		Game.social.note_trace(kind, pos)


# --- Speichern ------------------------------------------------------------------------

func save_state() -> Array:
	var list: Array = []
	var doors := get_tree().get_nodes_in_group("doors")
	var windows := get_tree().get_nodes_in_group("windows")
	for node in get_tree().get_nodes_in_group("trace_marks"):
		var mark := node as TraceMark
		var entry := {"kind": mark.kind}
		var host := mark.get_parent()
		var door := host.get_parent().get_parent() if host.get_parent() else null   # Tür → Pivot → Körper → Spur
		if host is HotelWindow:
			entry["window"] = windows.find(host)
			entry["local"] = _t(mark.transform)
		elif mark.has_meta("door_side") and door is Door:
			entry["door"] = doors.find(door)
			entry["side"] = float(mark.get_meta("door_side"))
		else:
			entry["global"] = _t(mark.global_transform)
		list.append(entry)
	return list


func load_state(list: Array) -> void:
	for node in get_tree().get_nodes_in_group("trace_marks"):
		node.queue_free()
	var doors := get_tree().get_nodes_in_group("doors")
	var windows := get_tree().get_nodes_in_group("windows")
	for entry in list:
		var mark := TraceMark.new().setup(String(entry["kind"]))
		if entry.has("window") and int(entry["window"]) >= 0 and int(entry["window"]) < windows.size():
			windows[int(entry["window"])].add_child(mark)
			mark.transform = _from_t(entry["local"])
		elif entry.has("door") and int(entry["door"]) >= 0 and int(entry["door"]) < doors.size():
			(doors[int(entry["door"])] as Door).attach_mark(mark, float(entry["side"]))
		elif entry.has("global"):
			add_child(mark)
			mark.global_transform = _from_t(entry["global"])


func _t(t: Transform3D) -> Array:
	var b := t.basis
	return [b.x.x, b.x.y, b.x.z, b.y.x, b.y.y, b.y.z, b.z.x, b.z.y, b.z.z, t.origin.x, t.origin.y, t.origin.z]


func _from_t(a: Array) -> Transform3D:
	var f: Array = a.map(func(v) -> float: return float(v))
	return Transform3D(Basis(Vector3(f[0], f[1], f[2]), Vector3(f[3], f[4], f[5]), Vector3(f[6], f[7], f[8])), Vector3(f[9], f[10], f[11]))
