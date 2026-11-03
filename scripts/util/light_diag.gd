class_name LightDiag
extends CanvasLayer
## Lichtdiagnose (ZIM-169) – zum Messen und Berichten von Licht, das durch Wände scheint. F2 schaltet weiter:
## aus → Position → Position und Licht. F4 speichert einen Bericht (Bild und Text nach user://berichte/), F11 die
## nächste Aufteilung des Schattenatlas (ATLAS_PRESETS). Wie die übrigen F-Tasten auch im Export aktiv.
##
## Position im Format von --pos (Spieler an den Füßen, Blickwinkel = rotation.y, Neigung des Kopfs), dazu Kompass
## (Norden = −Z, im Uhrzeigersinn), Stockwerk, Raum und Lichtbereich (LightRooms).
##
## Godot 4.7 legt den Schatten eines Punktlichts in zwei nebeneinanderliegende Plätze des Atlas (vier Quadranten mit
## je 1, 4, 16, 64 … Plätzen), ein Spot braucht einen. Wie groß der Platz sein soll, richtet sich nach der Größe des
## Lichts auf dem Bildschirm (coverage: doppelte Reichweite auf die Near-Ebene projiziert, geteilt durch die halbe
## Breite + Höhe der Near-Ebene); bekommt es keinen passenden, nimmt es einen kleineren, ist keiner mehr frei, den
## am längsten nicht gebrauchten – sonst bleibt es ohne Schatten und scheint durch Wände. Welche Lampe welchen Platz
## hat, verrät Godot nicht: _estimate rechnet nach derselben Regel den Bestfall (größte Lampen zuerst), Godot geht
## dagegen in der Reihenfolge der Szene vor und behält einen Platz eine Weile.
##
## Leck-Zeiger (in „Position und Licht“): alle Lampen, in deren Reichweite die Stelle unter dem Fadenkreuz liegt, mit
## Abstand, Zustand, geschätztem Platz und einem Strahl von der Stelle zur Lampe gegen Bau, Türen und Möbel. Rot:
## gezeigt, aber verdeckt – das sind die Lampen, deren Schatten ein Leck halten muss.

## Aufteilungen für F11 und --atlas: Plätze je Quadrant (Godot-Standard zuerst)
const ATLAS_PRESETS := [[4, 4, 16, 64], [16, 16, 16, 16], [4, 4, 64, 64], [64, 64, 64, 64]]
## Plätze je Quadrant → Wert von Viewport.PositionalShadowAtlasQuadrantSubdiv (Index)
const SUBDIV_SLOTS := [0, 1, 4, 16, 64, 256, 1024]
const INTERVAL := 0.25
## Der Leck-Zeiger sucht so weit (m) und zeigt höchstens so viele Lampen
const POINT_RANGE := 40.0
const POINT_LAMPS := 10
## Der Strahl zur Lampe hält so weit vor ihr an (m) – Fassung und Wand dahinter zählen nicht
const LAMP_GAP := 0.3
## Was den Strahl zur Lampe aufhält: statisch (Wände, Möbel), Türen, Decke, Milchglas, Vorhänge (TECHNIK.md 7)
const BLOCK_MASK := 1 | 2 | 16 | 256 | 512
## So viele Wechsel zeigt die Anzeige (der Bericht alle aus ShadowBudget.changes)
const CHANGES_SHOWN := 6
const RED := "#ff6060"
const GREY := "#9a9a9a"
const MODE_NAMES := ["aus", "Position", "Position und Licht"]
const COMPASS := ["N", "NO", "O", "SO", "S", "SW", "W", "NW"]
const DIR := "user://berichte"

var shadows: ShadowBudget
var builder: LevelBuilder
## 0 aus, 1 Position, 2 Position und Licht
var mode := 0:
	set(value):
		mode = value
		_timer = 0.0
		if _text:
			_text.visible = mode > 0
var _text: RichTextLabel
var _timer := 0.0
var _lights: Array[Light3D] = []
var _collected := false
var _preset := 0
## Letzte Auswertung: Zeilen [Text, Farbe] für Anzeige und Bericht
var _lines: Array = []
## Geschätzter Platz [gewünscht, bekommen] (Pixel, 0 = keiner) je Licht mit Schatten im Blickfeld, aus _estimate
var _slot := {}
## Gezeigte Lichter ohne Schatten im Blickfeld
var _bare: Array[Light3D] = []


func _ready() -> void:
	layer = 90
	process_mode = Node.PROCESS_MODE_ALWAYS
	_text = RichTextLabel.new()
	_text.bbcode_enabled = true
	_text.fit_content = true
	_text.scroll_active = false
	_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_text.add_theme_font_size_override("normal_font_size", 8)
	_text.add_theme_constant_override("outline_size", 3)
	_text.add_theme_color_override("font_outline_color", Color.BLACK)
	_text.anchor_left = 0.42
	_text.anchor_right = 1.0
	_text.offset_top = 44.0
	_text.offset_right = -8.0
	_text.visible = false
	add_child(_text)
	get_tree().node_added.connect(_on_node_added)


func _process(delta: float) -> void:
	if Input.is_action_just_pressed("debug_diag"):
		mode = (mode + 1) % MODE_NAMES.size()
		Game.say("Lichtdiagnose: %s" % MODE_NAMES[mode], 1.5)
	if Input.is_action_just_pressed("debug_report"):
		report()
	if Input.is_action_just_pressed("debug_atlas"):
		next_atlas()
	if mode == 0:
		return
	_timer -= delta
	if _timer > 0.0:
		return
	_timer = INTERVAL
	_measure(mode >= 2)
	var parts: Array[String] = []
	for line: Array in _lines:
		var t := (line[0] as String).replace("[", "[lb]")
		parts.append(t if line[1] == "" else "[color=%s]%s[/color]" % [line[1], t])
	_text.text = "\n".join(parts)


## Nächste Aufteilung aus ATLAS_PRESETS
func next_atlas() -> void:
	_preset = (_preset + 1) % ATLAS_PRESETS.size()
	set_atlas(ATLAS_PRESETS[_preset])


## Plätze je Quadrant setzen (je 0, 1, 4, 16, 64, 256 oder 1024) – false, wenn ein Wert nicht passt
func set_atlas(counts: Array) -> bool:
	if counts.size() != 4:
		return false
	for n: int in counts:
		if not n in SUBDIV_SLOTS:
			return false
	var vp := get_viewport()
	for q in 4:
		vp.set_positional_shadow_atlas_quadrant_subdiv(q, SUBDIV_SLOTS.find(counts[q]) as Viewport.PositionalShadowAtlasQuadrantSubdiv)
	var found := ATLAS_PRESETS.find(counts)
	if found >= 0:
		_preset = found
	_timer = 0.0
	Game.say("Schattenatlas: %s – Platz für %d Punktlichter" % [_atlas_text(), _omni_capacity()], 2.5)
	print("[Lichtdiagnose] Atlas %s, Platz für %d Punktlichter" % [_atlas_text(), _omni_capacity()])
	return true


## Bericht nach user://berichte/: Bild (ohne Kopflosigkeit) und Text mit allem, was die Anzeige zeigt, dazu alle
## Lichter mit Schatten im Blickfeld und alle Wechsel. Gibt den Pfad ohne Endung zurück.
func report() -> String:
	DirAccess.make_dir_recursive_absolute(DIR)
	var t := Time.get_datetime_dict_from_system()
	var base := "%s/bericht_%04d%02d%02d_%02d%02d%02d" % [DIR, t["year"], t["month"], t["day"], t["hour"], t["minute"],
		t["second"]]
	_measure(true)
	var out: Array[String] = ["Lichtbericht %s" % base.get_file()]
	if Game.director:
		out.append("Spielzeit %s %s" % [Calendar.date_text(Game.director.elapsed), Calendar.time_text(Game.director.elapsed)])
	out.append("Grafikstufe %s" % Settings.graphics_level()["name"])
	out.append("")
	for line: Array in _lines:
		out.append(("! " if line[1] == RED else "") + (line[0] as String))
	out.append("")
	out.append("Lichter mit Schatten im Blickfeld (Abstand · Reichweite · gewünscht → geschätzt · Schatten · Bereich · Lage):")
	var cam := get_viewport().get_camera_3d()
	var listed: Array = []
	for light: Light3D in _slot:
		listed.append([light.global_position.distance_to(cam.global_position) if cam else 0.0, light])
	listed.sort_custom(func(a: Array, b: Array) -> bool: return a[0] < b[0])
	for entry: Array in listed:
		var light: Light3D = entry[1]
		var slot: Array = _slot[light]
		out.append("  %s · %s m · %s m · %d → %s · %s · %s · %s" % [_name(light), _num(entry[0]), _num(_range(light)),
			slot[0], str(slot[1]) if slot[1] > 0 else "keiner", _caster(light), str(light.get_meta("light_room", "?")),
			_vec(light.global_position)])
	out.append("")
	out.append("Ohne Schatten im Blickfeld (Abstand · Reichweite · Lage):")
	for light in _bare:
		out.append("  %s · %s m · %s m · %s" % [_name(light), _num(light.global_position.distance_to(cam.global_position))
			if cam else "?", _num(_range(light)), _vec(light.global_position)])
	out.append("")
	out.append("Wechsel (Uhr seit Start · gezeigt/aus · Licht · Grund):")
	if shadows and not shadows.changes.is_empty():
		for c: Array in shadows.changes:
			out.append("  " + _change_text(c))
	else:
		out.append("  keine")
	var file := FileAccess.open(base + ".txt", FileAccess.WRITE)
	if file == null:
		print("[Lichtdiagnose] FEHLER Bericht nicht geschrieben: %s" % ProjectSettings.globalize_path(base + ".txt"))
		return ""
	file.store_string("\n".join(out) + "\n")
	file.close()
	if _lights.is_empty():
		print("[Lichtdiagnose] FEHLER keine Lichter gefunden")
	if DisplayServer.get_name() != "headless":
		var img := get_viewport().get_texture().get_image()
		if img:
			img.save_png(base + ".png")
	print("[Lichtdiagnose] Bericht gespeichert: %s (.txt/.png), %d Zeilen" % [ProjectSettings.globalize_path(base),
		out.size()])
	Game.say("Bericht gespeichert: %s" % base.get_file(), 3.0)
	return base


func _on_node_added(node: Node) -> void:
	if _collected and node is Light3D and not node is DirectionalLight3D:
		_lights.append(node)


func _collect() -> void:
	_collected = true
	_lights.clear()
	for node in get_tree().root.find_children("*", "Light3D", true, false):
		if not node is DirectionalLight3D:
			_lights.append(node)


## Alles auswerten, was Anzeige (lights: auch Licht und Leck-Zeiger) und Bericht brauchen → _lines, _slot
func _measure(lights: bool) -> void:
	_lines.clear()
	_slot.clear()
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		_add("keine Kamera")
		return
	_position_lines(cam)
	if not lights:
		return
	if not _collected:
		_collect()
	_light_lines(cam)
	_pointer_lines(cam)


func _position_lines(cam: Camera3D) -> void:
	var p := Game.player.global_position if Game.player else cam.global_position
	var yaw := fposmod(Game.player.rotation_degrees.y if Game.player else cam.global_rotation_degrees.y, 360.0)
	var pitch := Game.player.head.rotation_degrees.x if Game.player and Game.player.head else 0.0
	var bearing := fposmod(-yaw, 360.0)
	_add("x %s  y %s  z %s · Kompass %d° %s · Neigung %d°" % [_num(p.x), _num(p.y), _num(p.z), roundi(bearing) % 360,
		COMPASS[roundi(bearing / 45.0) % 8], roundi(pitch)])
	var place := ""
	if shadows and shadows.rooms:
		var rooms := shadows.rooms
		var fi := rooms.camera_floor(cam.global_position)
		place = "%s · Lichtbereich %d" % [_level_name(rooms.level_of(fi)) if fi >= 0 else "draußen",
			rooms.region_at(cam.global_position)]
	var room := builder.room_at(p) if builder else ""
	_add("%s · Raum %s" % [place, room if room != "" else "–"])
	_add("--pos=%.2f,%.2f,%.2f,%d,%d" % [p.x, p.y, p.z, roundi(yaw), roundi(pitch)])


func _light_lines(cam: Camera3D) -> void:
	var origin := cam.global_position
	var planes := cam.get_frustum()
	var total := 0
	var on := 0
	var shown := 0
	var shadowed := 0
	var full := 0
	var omni := 0
	var spot := 0
	var seen: Array = []   # [coverage, Licht] der Lichter mit Schatten im Blickfeld
	_bare.clear()
	var alive: Array[Light3D] = []
	for light in _lights:
		if not is_instance_valid(light) or not light.is_inside_tree():
			continue
		alive.append(light)
		total += 1
		if not light.is_visible_in_tree() or light.light_energy <= 0.001:
			continue
		on += 1
		if light.has_meta("hidden_mask"):
			continue
		shown += 1
		var r := _range(light)
		var d := light.global_position.distance_to(origin)
		var visible := _in_frustum(planes, light.global_position, r) and not (light.distance_fade_enabled
			and d > light.distance_fade_begin + light.distance_fade_length)
		if not light.shadow_enabled:
			if visible:
				_bare.append(light)
			continue
		shadowed += 1
		if light.shadow_caster_mask == ShadowBudget.ALL:
			full += 1
		if not visible:
			continue
		if light is OmniLight3D:
			omni += 1
		else:
			spot += 1
		seen.append([_coverage(cam, light), light])
	_lights = alive
	var used := omni * 2 + spot
	var slots := _slot_count()
	_add("Lampen %d · an %d · gezeigt %d · mit Schatten %d (von allem %d)" % [total, on, shown, shadowed, full])
	_add("Im Blickfeld mit Schatten: %d Punkt, %d Spot → %d von %d Plätzen · Platz für %d Punktlichter" % [omni, spot,
		used, slots, _omni_capacity()], RED if omni > _omni_capacity() or used > slots else "")
	_add("Ohne Schatten im Blickfeld: %d (scheinen durch Wände – Kerzen, no_shadow, nicht von ShadowBudget geführt)" %
		_bare.size(), GREY)
	_add("Atlas %d · %s → Platzgröße %s" % [get_viewport().positional_shadow_atlas_size, _atlas_text(), _sizes_text()])
	var est := _estimate(seen)
	_add("Gewünscht (Schätzung): %s → kleiner als gewünscht %d, ohne Platz %d" % [est[0], est[1], est[2]],
		RED if est[2] > 0 else "")
	if shadows and shadows.rooms:
		var rooms := shadows.rooms
		var reach := rooms.reach(origin)
		var reached := 0
		for v in reach:
			if v != 0:
				reached += 1
		var fi := rooms.camera_floor(origin)
		var bits := rooms.passages_near(fi, Vector2(origin.x, origin.z), ShadowBudget.STAIR_NEAR) if fi >= 0 else 0
		var stair: String = ["–", "hinauf", "hinab", "hinauf und hinab"][bits & 3]
		var lost := "nie"
		if shadows.no_region_count > 0:
			lost = "%d× (zuletzt vor %d s)" % [shadows.no_region_count, roundi(shadows.clock - shadows.no_region_at)]
		_add("Kamera: erreicht %s Bereiche · Treppe bis %s m: %s · ohne Bereich %s" % [str(reached) if not reach.is_empty()
			else "alle", _num(ShadowBudget.STAIR_NEAR), stair, lost], RED if reach.is_empty() else "")
		var changes := shadows.changes
		if not changes.is_empty():
			_add("Zuletzt:")
			for i in range(maxi(0, changes.size() - CHANGES_SHOWN), changes.size()):
				var c: Array = changes[i]
				_add("  " + _change_text(c), RED if c[3] == ShadowBudget.Why.NO_CAM_REGION else "")


func _pointer_lines(cam: Camera3D) -> void:
	var space := cam.get_world_3d().direct_space_state
	var from := cam.global_position
	var query := PhysicsRayQueryParameters3D.create(from, from - cam.global_basis.z * POINT_RANGE, BLOCK_MASK)
	var hit := space.intersect_ray(query)
	if hit.is_empty():
		_add("Fadenkreuz: nichts bis %d m" % roundi(POINT_RANGE))
		return
	var point: Vector3 = hit["position"]
	var normal: Vector3 = hit["normal"]
	var room := builder.room_at(point) if builder else ""
	_add("Fadenkreuz %s m auf %s (%s) · %s" % [_num(from.distance_to(point)), _body_name(hit["collider"]),
		room if room != "" else "–", _vec(point)])
	var near: Array = []
	for light in _lights:
		if not is_instance_valid(light) or not light.is_visible_in_tree() or light.light_energy <= 0.001:
			continue
		var d := light.global_position.distance_to(point)
		if d < _range(light):
			near.append([d, light])
	near.sort_custom(func(a: Array, b: Array) -> bool: return a[0] < b[0])
	if near.is_empty():
		_add("  keine eingeschaltete Lampe reicht bis hierher")
	var start := point + normal * 0.05
	for i in mini(near.size(), POINT_LAMPS):
		var light: Light3D = near[i][1]
		var to := light.global_position
		var gap := minf(LAMP_GAP, start.distance_to(to) * 0.5)
		var ray := PhysicsRayQueryParameters3D.create(start, to - (to - start).normalized() * gap, BLOCK_MASK)
		var block := space.intersect_ray(ray)
		var hidden := light.has_meta("hidden_mask")
		var state := "abgeschaltet" if hidden else ("Schatten " + _caster(light) if light.shadow_enabled else "ohne Schatten")
		var slot := ""
		if _slot.has(light):
			slot = " · Platz ~%s" % (str(_slot[light][1]) if _slot[light][1] > 0 else "keiner")
		elif not hidden:
			slot = " · nicht im Blickfeld"
		var sight := "frei" if block.is_empty() else "verdeckt (%s)" % _body_name(block["collider"])
		var color := GREY if hidden else (RED if not block.is_empty() else "")
		_add("  %s · %s m · %s%s · %s" % [_name(light), _num(near[i][0]), state, slot, sight], color)


## Bestfall der Atlasbelegung nach Godots Regel → [Text „gewünscht“, kleiner als gewünscht, ohne Platz]; füllt _slot
func _estimate(seen: Array) -> Array:
	var size := get_viewport().positional_shadow_atlas_size
	var quad := size >> 1
	var free: Array[int] = []   # freie Plätze je Quadrant
	var sizes: Array[int] = []  # Kantenlänge eines Platzes je Quadrant
	var largest := 0
	for q in 4:
		var n: int = SUBDIV_SLOTS[get_viewport().get_positional_shadow_atlas_quadrant_subdiv(q)]
		free.append(n)
		var side := int(sqrt(float(n)))
		sizes.append(quad / side if side > 0 else 0)
		largest = maxi(largest, sizes[q])
	seen.sort_custom(func(a: Array, b: Array) -> bool: return a[0] > b[0])
	var order := range(4)
	order.sort_custom(func(a: int, b: int) -> bool: return sizes[a] > sizes[b])
	var wanted := {}
	var smaller := 0
	var none := 0
	for entry: Array in seen:
		var light: Light3D = entry[1]
		var desired := mini(largest, _pow2(int(quad * float(entry[0]))))
		wanted[desired] = int(wanted.get(desired, 0)) + 1
		var need := 2 if light is OmniLight3D else 1
		# passender Quadrant: kleinster Platz ≥ gewünscht, sonst der größte; dann abwärts
		var fit := 0
		for s in sizes:
			if s >= desired and (fit == 0 or s < fit):
				fit = s
		if fit == 0:
			fit = largest
		var got := 0
		for q: int in order:
			# ein Quadrant mit nur einem Platz hat keine zwei nebeneinander
			if sizes[q] == 0 or sizes[q] > fit or free[q] < need or (need == 2 and sizes[q] == quad):
				continue
			free[q] -= need
			got = sizes[q]
			break
		_slot[light] = [desired, got]
		if got == 0:
			none += 1
		elif got < desired:
			smaller += 1
	var keys := wanted.keys()
	keys.sort()
	keys.reverse()
	var parts: Array[String] = []
	for k: int in keys:
		parts.append("%d×%d" % [k, wanted[k]])
	return [" ".join(parts) if not parts.is_empty() else "–", smaller, none]


## Wie Godot (RendererSceneCull::_render_scene): Lichtmitte und ein Punkt eine Reichweite seitlich auf die Near-Ebene
## projiziert, doppelter Abstand geteilt durch halbe Breite + Höhe der Near-Ebene
func _coverage(cam: Camera3D, light: Light3D) -> float:
	var xf := cam.global_transform
	var zn := cam.near
	var plane := Plane(-xf.basis.z, xf.origin - xf.basis.z * zn)
	var points := [light.global_position, light.global_position + xf.basis.x * _range(light)]
	for j in 2:
		var pt: Vector3 = points[j]
		if plane.distance_to(pt) < 0.0:
			pt.y = -zn
		var cut: Variant = plane.intersects_segment(xf.origin, pt)
		points[j] = cut if cut != null else pt
	var half := cam.get_camera_projection().get_viewport_half_extents()
	return (points[0] as Vector3).distance_to(points[1]) * 2.0 / maxf(half.x + half.y, 0.0001)


func _in_frustum(planes: Array[Plane], c: Vector3, r: float) -> bool:
	for pl in planes:
		if pl.distance_to(c) > r:
			return false
	return true


func _pow2(x: int) -> int:
	if x <= 0:
		return 0
	var v := 1
	while v < x:
		v <<= 1
	return v


func _slot_count() -> int:
	var n := 0
	for q in 4:
		n += SUBDIV_SLOTS[get_viewport().get_positional_shadow_atlas_quadrant_subdiv(q)]
	return n


## Punktlichter brauchen zwei Plätze nebeneinander in einer Reihe des Quadranten
func _omni_capacity() -> int:
	var n := 0
	for q in 4:
		var side := int(sqrt(float(SUBDIV_SLOTS[get_viewport().get_positional_shadow_atlas_quadrant_subdiv(q)])))
		n += side * (side / 2)
	return n


func _atlas_text() -> String:
	var parts: Array[String] = []
	for q in 4:
		parts.append(str(SUBDIV_SLOTS[get_viewport().get_positional_shadow_atlas_quadrant_subdiv(q)]))
	return "/".join(parts)


func _sizes_text() -> String:
	var quad := get_viewport().positional_shadow_atlas_size >> 1
	var parts: Array[String] = []
	for q in 4:
		var side := int(sqrt(float(SUBDIV_SLOTS[get_viewport().get_positional_shadow_atlas_quadrant_subdiv(q)])))
		parts.append(str(quad / side) if side > 0 else "–")
	return "/".join(parts)


func _change_text(c: Array) -> String:
	var who := "Kamera"
	if typeof(c[1]) != TYPE_NIL:
		who = _name(c[1]) if is_instance_valid(c[1]) else "(Licht entfernt)"
	return "%s s %s %s – %s" % [_num(c[0]), "+" if c[2] else "−", who, ShadowBudget.WHY_TEXT[c[3]]]


## Raum und Art: „lobby wall“ (Lamp: Raum und Bauart), „lobby Item CANDLE“, „draußen FlickerLight“
func _name(light: Light3D) -> String:
	var parent := light.get_parent()
	var lamp := parent as Lamp
	if lamp:
		return "%s %s" % [lamp.room_id if lamp.room_id != "" else "–", String(Lamp.Style.keys()[lamp.style]).to_lower()]
	var room := builder.light_room_at(light.global_position) if builder else ""
	var what := _node_label(light)
	if parent is Item:
		what = "Item " + String(Item.Kind.keys()[(parent as Item).kind])
	elif parent and not parent is NavigationRegion3D:   # Level (EG) selbst sagt nichts
		what = _node_label(parent)
	return "%s %s" % [room if room != "" else "draußen", what]


func _body_name(body: Object) -> String:
	var node := body as Node
	return _node_label(node) if node else "?"


## Name eines Knotens; namenlose (@…) heißen nach ihrer Klasse und dem nächsten benannten Elternknoten
func _node_label(node: Node) -> String:
	var name := String(node.name)
	if not name.begins_with("@"):
		return name
	var script := node.get_script() as Script
	var cls := script.get_global_name() if script else StringName()
	var label := String(cls) if cls != &"" else node.get_class()
	var up := node.get_parent()
	for i in 3:
		if up == null:
			break
		if not String(up.name).begins_with("@"):
			return "%s in %s" % [label, up.name]
		up = up.get_parent()
	return label


func _caster(light: Light3D) -> String:
	if light.shadow_caster_mask == ShadowBudget.ALL:
		return "von allem"
	if light.shadow_caster_mask == ShadowBudget.LAYER:
		return "vom Bau"
	return "eigene Maske"


func _range(light: Light3D) -> float:
	if light is OmniLight3D:
		return (light as OmniLight3D).omni_range
	if light is SpotLight3D:
		return (light as SpotLight3D).spot_range
	return 0.0


func _level_name(level: int) -> String:
	if level == 0:
		return "EG"
	if level == -1:
		return "UG"
	if level < 0:
		return "U%d" % -level
	return "%d. OG" % level


func _add(text: String, color := "") -> void:
	_lines.append([text, color])


func _num(v: float) -> String:
	return ("%.1f" % v).replace(".", ",").replace("-", "−")


func _vec(v: Vector3) -> String:
	return "(%.1f, %.1f, %.1f)" % [v.x, v.y, v.z]
