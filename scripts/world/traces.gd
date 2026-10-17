class_name Traces
extends Node3D
## Spuren des Monsters (Spielkonzept 4.13) an einer Stelle gesammelt:
##   Fußspuren – dunkel und nass, verblassen über einige Minuten (zeigen Weg und Alter);
##     unter UV-Licht leuchten sie noch lange danach (UvMark, Spielkonzept 4.16)
##   Kratzspuren an Wänden und Türen, Blut, Handabdrücke am Milchglas – bleiben (TraceMark)
## Jede neue Spur wird auch den Gästen bekannt, die davon erzählen (Social.note_trace).
## Dazu Spuren der Gäste: schlammige Schuhabdrücke aus dem Garten (verblassen), Wachsflecken,
## Blutstropfen nach einem Angriff (bleiben) und Zettel, die Gäste schreiben.

const FOOTPRINT_LIFE := 240.0
const FOOTPRINT_UV_LIFE := 900.0    ## so lange sieht man sie unter UV (drei Ingame-Tage)
const MAX_FOOTPRINTS := 240
const SHOEPRINT_LIFE := 150.0
const MAX_GUEST_MARKS := 140        ## Wachs und Blutstropfen der Gäste – die ältesten verschwinden

var _footprints: Array[Dictionary] = []   ## {node, material, age, life, alpha}
var _guest_marks: Array[TraceMark] = []


func _process(delta: float) -> void:
	var i := _footprints.size() - 1
	while i >= 0:
		var f := _footprints[i]
		f["age"] = float(f["age"]) + delta
		var k := 1.0 - float(f["age"]) / float(f.get("life", FOOTPRINT_LIFE))
		if float(f["age"]) >= float(f.get("uv_life", 0.0)) and k <= 0.0:
			(f["node"] as Node).queue_free()
			_footprints.remove_at(i)
		elif k > 0.0:
			(f["material"] as StandardMaterial3D).albedo_color.a = float(f.get("alpha", 0.85)) * k
		elif not f.get("faded", false):
			# Für das Auge verschwunden – nur der UV-Nachglanz bleibt
			f["faded"] = true
			for child in (f["node"] as Node).get_children():
				if not child is UvMark:
					(child as Node3D).visible = false
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
	# Nachglanz unter UV – dieselbe Form, etwas darüber
	var glow := UvMark.new()
	foot.add_child(glow)
	glow.position.y = 0.002
	glow.add_box(Vector3(0.11, 0.003, 0.24), Vector3(0, 0, 0.02))
	for t in 3:
		glow.add_box(Vector3(0.025, 0.003, 0.08), Vector3(-0.04 + t * 0.04, 0, -0.13), (t - 1) * 0.25)
	_footprints.append({"node": foot, "material": mat, "age": 0.0, "uv_life": FOOTPRINT_UV_LIFE})
	if _footprints.size() % 12 == 1:
		_report("footprint", pos)


## Schlammiger Schuhabdruck eines Gastes, der aus dem Garten kommt.
func add_shoeprint(pos: Vector3, yaw: float) -> void:
	if _footprints.size() >= MAX_FOOTPRINTS:
		(_footprints[0]["node"] as Node).queue_free()
		_footprints.remove_at(0)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.2, 0.13, 0.07, 0.7)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.roughness = 1.0
	var shoe := Node3D.new()
	add_child(shoe)
	shoe.global_position = Vector3(pos.x, _floor_y(pos) + 0.011, pos.z)
	shoe.rotation.y = yaw
	var sole := Geo.mesh(shoe, Geo.box(Vector3(0.09, 0.004, 0.17)), mat, Vector3(0, 0, -0.03))
	sole.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var heel := Geo.mesh(shoe, Geo.box(Vector3(0.07, 0.004, 0.07)), mat, Vector3(0, 0, 0.1))
	heel.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_footprints.append({"node": shoe, "material": mat, "age": 0.0, "life": SHOEPRINT_LIFE, "alpha": 0.7})


## Wachsfleck oder Blutstropfen eines Gastes auf dem Boden.
func add_guest_drop(kind: String, pos: Vector3) -> TraceMark:
	if _guest_marks.size() >= MAX_GUEST_MARKS:
		var old: TraceMark = _guest_marks.pop_front()
		if is_instance_valid(old):
			old.queue_free()
	var mark := TraceMark.new().setup(kind)
	add_child(mark)
	mark.global_position = Vector3(pos.x, _floor_y(pos) + 0.006, pos.z)
	mark.rotation = Vector3(-PI / 2.0, randf() * TAU, 0)
	_guest_marks.append(mark)
	if kind == "drops":
		_report("drops", pos)
	return mark


## Ein Zettel, den ein Gast hinterlässt (vor seiner Tür, an einem Fundort …).
func add_guest_note(pos: Vector3, title: String, text: String) -> WarningNote:
	var note := WarningNote.new().setup_custom(title, text)
	add_child(note)
	note.global_position = Vector3(pos.x, _floor_y(pos) + 0.003, pos.z)
	note.rotation.y = randf() * TAU
	return note


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
func add_door_handprint(door: Door, from_pos: Vector3) -> TraceMark:
	var local := door.global_transform.affine_inverse() * from_pos
	var mark := TraceMark.new().setup("handprint")
	door.attach_mark(mark, 1.0 if local.z >= 0.0 else -1.0, Vector2(randf_range(0.55, 0.8), randf_range(1.35, 1.65)))
	_report("handprint", door.center())
	return mark


## Blutige Handabdrücke des Lakengeists außen auf einer Fensterscheibe (Spielkonzept 4.18).
func add_window_handprints(window: HotelWindow) -> void:
	for side in [-1.0, 1.0]:
		var mark := TraceMark.new().setup("bloody_hand")
		mark.solid = false
		window.add_child(mark)
		mark.position = Vector3(side * randf_range(0.2, 0.3), randf_range(-0.12, 0.08), -0.015)
		mark.rotation = Vector3(0, PI, side * randf_range(0.1, 0.3))
	_report("handprint", window.global_position)


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
			var at: Vector2 = mark.get_meta("door_at", Vector2(0.45, 1.35))
			entry["at"] = [at.x, at.y]
		else:
			entry["global"] = _t(mark.global_transform)
		list.append(entry)
	for node in get_tree().get_nodes_in_group("guest_notes"):
		var note := node as WarningNote
		list.append({"kind": "note", "title": note.custom_title, "text": note.custom_text, "global": _t(note.global_transform)})
	return list


func load_state(list: Array) -> void:
	for node in get_tree().get_nodes_in_group("trace_marks"):
		node.queue_free()
	for node in get_tree().get_nodes_in_group("guest_notes"):
		node.queue_free()
	_guest_marks.clear()
	var doors := get_tree().get_nodes_in_group("doors")
	var windows := get_tree().get_nodes_in_group("windows")
	for entry in list:
		if String(entry["kind"]) == "note":
			var note := WarningNote.new().setup_custom(String(entry["title"]), String(entry["text"]))
			add_child(note)
			note.global_transform = _from_t(entry["global"])
			continue
		var mark := TraceMark.new().setup(String(entry["kind"]))
		if String(entry["kind"]) in ["wax", "drops"]:
			_guest_marks.append(mark)
		if entry.has("window") and int(entry["window"]) >= 0 and int(entry["window"]) < windows.size():
			windows[int(entry["window"])].add_child(mark)
			mark.transform = _from_t(entry["local"])
		elif entry.has("door") and int(entry["door"]) >= 0 and int(entry["door"]) < doors.size():
			var at: Array = entry.get("at", [0.45, 1.35])
			(doors[int(entry["door"])] as Door).attach_mark(mark, float(entry["side"]), Vector2(float(at[0]), float(at[1])))
		elif entry.has("global"):
			add_child(mark)
			mark.global_transform = _from_t(entry["global"])


func _t(t: Transform3D) -> Array:
	var b := t.basis
	return [b.x.x, b.x.y, b.x.z, b.y.x, b.y.y, b.y.z, b.z.x, b.z.y, b.z.z, t.origin.x, t.origin.y, t.origin.z]


func _from_t(a: Array) -> Transform3D:
	var f: Array = a.map(func(v) -> float: return float(v))
	return Transform3D(Basis(Vector3(f[0], f[1], f[2]), Vector3(f[3], f[4], f[5]), Vector3(f[6], f[7], f[8])), Vector3(f[9], f[10], f[11]))
