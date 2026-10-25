class_name Traces
extends Node3D
## Spuren des Monsters (Spielkonzept 4.13) an einer Stelle gesammelt:
##   Fußspuren – dunkel und nass, verblassen über einige Minuten (zeigen Weg und Alter);
##     unter UV-Licht leuchten sie noch lange danach (UvMark, Spielkonzept 4.16)
##   Kratzspuren an Wänden und Türen, Blut (am Boden und an Wänden), Handabdrücke am Milchglas – bleiben (TraceMark)
## Jede neue Spur wird auch den Gästen bekannt, die davon erzählen (Social.note_trace).
## Dazu Spuren der Gäste: schlammige Schuhabdrücke aus dem Garten (verblassen), Wachsflecken,
## Blutstropfen nach einem Angriff (bleiben) und Zettel, die Gäste schreiben.

const FOOTPRINT_LIFE := 240.0
const FOOTPRINT_UV_LIFE := 900.0    ## so lange sieht man sie unter UV (15 Spielstunden)
const MAX_FOOTPRINTS := 240
const SHOEPRINT_LIFE := 150.0
const MAX_GUEST_MARKS := 140        ## Wachs und Blutstropfen der Gäste – die ältesten verschwinden
## Blut an Wänden: so weit sucht es ringsum nach der nächsten Wand, in dieser Höhe sitzt die Spur
const WALL_BLOOD_RANGE := 2.5
const WALL_BLOOD_HEIGHT := {"wall_splatter": 1.15, "wall_smear": 1.45}

var _footprints: Array[Dictionary] = []   ## {node, material, age, life, alpha}
var _guest_marks: Array = []   ## TraceMark – weggewischte und verwaschene sind schon freigegeben (ungetypt)
var _wash_timer := 0.0


func _ready() -> void:
	add_to_group("time_skip")   # Zeitsprung im Schlaf (SleepSkip)


## Zeitsprung im Schlaf (SleepSkip, Spielkonzept 3.6): Fußspuren altern (das nächste Bild blendet sie aus).
func skip_time(dt: float) -> void:
	for f in _footprints:
		f["age"] = float(f["age"]) + dt
	_wash_timer += dt


func _process(delta: float) -> void:
	_wash_timer += delta
	if _wash_timer >= RainVeil.WASH_TICK:
		_wash_marks(_wash_timer)
		_wash_timer = 0.0
	var i := _footprints.size() - 1
	while i >= 0:
		var f := _footprints[i]
		f["age"] = float(f["age"]) + delta
		var k := 1.0 - float(f["age"]) / float(f.get("life", FOOTPRINT_LIFE))
		if float(f["age"]) >= float(f.get("uv_life", 0.0)) and k <= 0.0:
			(f["node"] as Node).queue_free()
			_footprints.remove_at(i)
		elif k > 0.0:
			# Bis zu MAX_FOOTPRINTS Materialien: nur schreiben, wenn sich der Wert um eine Stufe (1/255) ändert
			var mat := f["material"] as StandardMaterial3D
			var a := float(f.get("alpha", 0.85)) * k
			if absf(mat.albedo_color.a - a) >= 1.0 / 255.0:
				mat.albedo_color.a = a
		elif not f.get("faded", false):
			# Für das Auge verschwunden – nur der UV-Nachglanz bleibt
			f["faded"] = true
			for child in (f["node"] as Node).get_children():
				if not child is UvMark:
					(child as Node3D).visible = false
		i -= 1


# --- Fußspuren ----------------------------------------------------------------

func add_footprint(pos: Vector3, yaw: float) -> void:
	_drop_oldest_footprint()
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
	_drop_oldest_footprint()
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


## Platz für eine neue Fuß- oder Schuhspur: Bei MAX_FOOTPRINTS verschwindet die älteste.
func _drop_oldest_footprint() -> void:
	if _footprints.size() >= MAX_FOOTPRINTS:
		(_footprints[0]["node"] as Node).queue_free()
		_footprints.remove_at(0)


## Wachsfleck oder Blutstropfen eines Gastes auf dem Boden – auch der große Wachsfleck einer geworfenen Kerze
## („wax_splash“, 6.13), Ruß verbrannter Deko („soot“, 5.11) und der Fleck einer zerbrochenen Kaffeetasse („coffee“, 3.11).
func add_guest_drop(kind: String, pos: Vector3) -> TraceMark:
	if _guest_marks.size() >= MAX_GUEST_MARKS:
		# Weggewischt (TraceMark.wipe) oder vom Regen verwaschen (wash_by): schon fort, zählt nicht mehr mit
		_guest_marks = _guest_marks.filter(func(m: Variant) -> bool: return is_instance_valid(m))
		if _guest_marks.size() >= MAX_GUEST_MARKS:
			(_guest_marks.pop_front() as Node).queue_free()
	var mark := TraceMark.new().setup(kind)
	mark.fresh = true   # der große Wachsfleck breitet sich aus (TraceMark.SPREAD)
	add_child(mark)
	mark.global_position = Vector3(pos.x, _floor_y(pos) + 0.006, pos.z)
	mark.rotation = Vector3(-PI / 2.0, randf() * TAU, 0)
	_guest_marks.append(mark)
	if kind == "drops":
		_report("drops", pos)
	return mark


## Geworfenes Flüssiges an der Wand (Spielkonzept 3.13): „splash_mush:<sorte>“, „splash_wax“, „splash_coffee“,
## „splash_tea“ – ein Fleck am Treffpunkt, der bis zum Boden herunterläuft (TraceMark._spread_wall). Zählt zu den
## Spuren der Gäste (MAX_GUEST_MARKS).
func add_wall_splash(kind: String, pos: Vector3, normal: Vector3) -> TraceMark:
	if _guest_marks.size() >= MAX_GUEST_MARKS:
		_guest_marks = _guest_marks.filter(func(m: Variant) -> bool: return is_instance_valid(m))
		if _guest_marks.size() >= MAX_GUEST_MARKS:
			(_guest_marks.pop_front() as Node).queue_free()
	var flat := Vector3(normal.x, 0.0, normal.z).normalized()
	var mark := TraceMark.new().setup(kind)
	mark.fresh = true   # läuft herunter
	add_child(mark)
	mark.global_position = pos + flat * 0.012
	mark.look_at(mark.global_position - flat, Vector3.UP)
	_guest_marks.append(mark)
	return mark


## Ein Zettel, den ein Gast hinterlässt (vor seiner Tür, an einem Fundort …).
func add_guest_note(pos: Vector3, title: String, text: String) -> WarningNote:
	var note := WarningNote.new().setup_custom(title, text)
	add_child(note)
	note.global_position = Vector3(pos.x, _floor_y(pos) + 0.003, pos.z)
	note.rotation.y = randf() * TAU
	return note


func _floor_y(pos: Vector3) -> float:
	var hit := surface_below(get_world_3d().direct_space_state, pos + Vector3.UP * 0.5, 1.5)
	return pos.y if hit.is_empty() else float((hit["position"] as Vector3).y)


## Die Fläche unter `from` (Strahl `depth` nach unten), auf der Spuren liegen: Boden, Möbel und auf Treppen die
## sichtbaren Stufen (LevelBuilder.LAYER_TREAD) – nicht die Rampe, über die man läuft (sonst schweben Spuren vorn an
## jeder Stufe). {} = nichts gefunden, sonst das Ergebnis von intersect_ray (position, normal, collider …).
static func surface_below(space: PhysicsDirectSpaceState3D, from: Vector3, depth: float) -> Dictionary:
	var query := PhysicsRayQueryParameters3D.create(from, from + Vector3.DOWN * depth, 1 | LevelBuilder.LAYER_TREAD)
	var skip: Array[RID] = []
	for i in 4:
		query.exclude = skip
		var hit := space.intersect_ray(query)
		if hit.is_empty() or not (hit["collider"] as Object).has_meta("stair_ramp"):
			return hit
		skip.append(hit["rid"])
	return {}


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
	mark.fresh = true   # breitet sich aus (TraceMark.SPREAD)
	add_child(mark)
	mark.global_position = Vector3(pos.x, _floor_y(pos), pos.z)
	mark.rotation.y = yaw   # die Flecken verteilt TraceMark selbst (auf Treppen die Stufen hinunter)
	_as_sight(mark)
	_report("blood", pos)
	return mark


## Blut an der nächsten Wand (Spielkonzept 4.13): „wall_splatter“, wo das Monster einen Gast geholt oder der
## Kürbismann zugeschlagen hat; „wall_smear“ – eine blutige Hand, die hinuntergerutscht ist – als Spuk
## (MonsterDirector._haunt_wall_blood). Sucht ringsum in Spurhöhe die nächste Wand bis WALL_BLOOD_RANGE; null = keine.
func add_wall_blood(pos: Vector3, kind: String) -> TraceMark:
	var space := get_world_3d().direct_space_state
	var from := Vector3(pos.x, _floor_y(pos) + float(WALL_BLOOD_HEIGHT[kind]), pos.z)
	var best := {}
	var best_d := INF
	for i in 16:
		var a := TAU * i / 16.0
		var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(from, from + Vector3(sin(a), 0, cos(a)) * WALL_BLOOD_RANGE, 1))
		if hit.is_empty() or absf((hit["normal"] as Vector3).y) > 0.3:
			continue
		var d := from.distance_to(hit["position"])
		if d < best_d:
			best_d = d
			best = hit
	if best.is_empty():
		return null
	var normal: Vector3 = best["normal"]
	var mark := TraceMark.new().setup(kind)
	add_child(mark)
	mark.global_position = best["position"] + normal * 0.012
	mark.look_at(mark.global_position - normal, Vector3.UP)
	mark.rotate_object_local(Vector3.FORWARD, randf_range(-0.2, 0.2))
	_as_sight(mark)
	_report("blood", mark.global_position)
	return mark


## Blutlachen erschrecken Gäste (Guest._scan_for_shock, Spielkonzept 6.12). Der Schlüssel hängt am Ort,
## damit ein Gast dieselbe Lache auch nach dem Laden wiedererkennt.
func _as_sight(mark: TraceMark) -> void:
	var p := mark.global_position
	mark.set_meta("sight_key", "blood@%d,%d,%d" % [roundi(p.x * 10.0), roundi(p.y * 10.0), roundi(p.z * 10.0)])
	mark.set_meta("sight_kind", "blood")
	mark.add_to_group("shock_sights")


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


## Dasselbe außen auf der Scheibe einer Fenstertür (am ersten Flügel, gespeichert wie Spuren an Türen).
func add_french_door_handprints(door: Door) -> void:
	var side := 1.0 if door.global_transform.basis.z.dot(door.outward) > 0.0 else -1.0
	for x in [0.3, 0.7]:
		var mark := TraceMark.new().setup("bloody_hand")
		door.attach_mark(mark, side, Vector2(x + randf_range(-0.05, 0.05), randf_range(1.3, 1.5)))
	_report("handprint", door.center())


## Blutige Handabdrücke auf der Glastür der Duschecke von Zimmer 13 (Lakengeist in der Dusche, Spielkonzept 4.24) – außen,
## wo er hindurchgegriffen hat (innen lägen sie im Schatten der Scheibe). door_z = Außenfläche der Tür (lokal z der
## Duschecke); gespeichert wie Spuren am Boden (Weltlage).
func add_shower_handprints(shower: Node3D, door_z: float) -> void:
	for side in [-1.0, 1.0]:
		var mark := TraceMark.new().setup("bloody_hand")
		mark.solid = false
		add_child(mark)
		var local := Transform3D(Basis(Vector3.BACK, side * randf_range(0.1, 0.3)),
			Vector3(side * randf_range(0.14, 0.24), randf_range(1.35, 1.6), door_z + 0.004))
		mark.global_transform = shower.global_transform * local
	_report("handprint", shower.global_position)


func _report(kind: String, pos: Vector3) -> void:
	if Game.social:
		Game.social.note_trace(kind, pos)


# --- Regen ------------------------------------------------------------------------------

## Im Regen verwaschen (RainVeil): Blutlachen und große Wachsflecken unter freiem Himmel werden heller und dünner, ganz
## verwaschen zum Schleier. Nur Spuren am Boden (nicht an Türen und Fenstern); ob draußen, merkt sich jede Spur.
func _wash_marks(delta: float) -> void:
	if Game.weather == null or Game.weather.intensity < RainVeil.RAIN_MIN:
		return
	for node in get_tree().get_nodes_in_group("trace_marks"):
		var mark := node as TraceMark
		if not mark.kind in ["blood", "wax_splash"] or mark.get_parent() != self:
			continue
		if not mark.has_meta("outdoor"):
			mark.set_meta("outdoor", RainVeil.is_outdoor(mark.global_position))
		if mark.get_meta("outdoor"):
			var step := RainVeil.wash_step(mark.global_position, delta)
			if step > 0.0:
				mark.wash_by(step)


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
			if mark.wash > 0.0:
				entry["wash"] = mark.wash
		list.append(entry)
	for node in get_tree().get_nodes_in_group("rain_veils"):
		list.append((node as RainVeil).to_save())
	for node in get_tree().get_nodes_in_group("guest_notes"):
		var note := node as WarningNote
		list.append({"kind": "note", "title": note.custom_title, "text": note.custom_text, "global": _t(note.global_transform)})
	return list


func load_state(list: Array) -> void:
	for node in get_tree().get_nodes_in_group("trace_marks"):
		node.queue_free()
	for node in get_tree().get_nodes_in_group("guest_notes"):
		node.queue_free()
	for node in get_tree().get_nodes_in_group("rain_veils"):
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
		if String(entry["kind"]) == "veil":
			RainVeil.from_save(self, entry)
			continue
		var mark := TraceMark.new().setup(String(entry["kind"]))
		mark.wash = float(entry.get("wash", 0.0))
		if entry.has("window") and int(entry["window"]) >= 0 and int(entry["window"]) < windows.size():
			windows[int(entry["window"])].add_child(mark)
			mark.transform = _from_t(entry["local"])
		elif entry.has("door") and int(entry["door"]) >= 0 and int(entry["door"]) < doors.size():
			var at: Array = entry.get("at", [0.45, 1.35])
			(doors[int(entry["door"])] as Door).attach_mark(mark, float(entry["side"]), Vector2(float(at[0]), float(at[1])))
		elif entry.has("global"):
			add_child(mark)
			mark.global_transform = _from_t(entry["global"])
			if mark.kind in ["blood", "wall_splatter", "wall_smear"]:
				_as_sight(mark)
		else:
			mark.free()   # Tür oder Fenster gibt es nicht mehr – die Spur fällt weg
			continue
		if mark.kind in ["wax", "drops", "wax_splash", "soot", "coffee", "tea"] or mark.kind.begins_with("splash_"):
			_guest_marks.append(mark)


func _t(t: Transform3D) -> Array:
	var b := t.basis
	return [b.x.x, b.x.y, b.x.z, b.y.x, b.y.y, b.y.z, b.z.x, b.z.y, b.z.z, t.origin.x, t.origin.y, t.origin.z]


func _from_t(a: Array) -> Transform3D:
	var f: Array = a.map(func(v) -> float: return float(v))
	return Transform3D(Basis(Vector3(f[0], f[1], f[2]), Vector3(f[3], f[4], f[5]), Vector3(f[6], f[7], f[8])), Vector3(f[9], f[10], f[11]))
