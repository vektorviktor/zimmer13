class_name SaltLine
extends Node3D
## Salzlinie (Spielkonzept 5.13): mit der Salzpackung auf eine Türschwelle oder eine Fensterbank gestreut. Eine heile
## Linie an einer Öffnung schützt das ganze Zimmer dahinter (mit Bad): Der Lakengeist kommt noch ans Glas und kreist mit
## den Händen, aber nicht herein – zu niemandem, der drinnen ist. Nach HOLDS Abweisungen wird das Salz grau und hält
## nichts mehr. Wer über die Schwelle geht, verwischt sie (geduckt steigt der Spieler vorsichtig darüber); das Monster
## zögert an ihr (Monster._check_salt) und geht dann hindurch. Ursprung = Mitte der Linie auf der Fläche, lokale X =
## entlang, +Z = zum Zimmer bzw. zum Spieler hin. Gruppe „salt_lines“, gespeichert unter „salt“ (SaveManager).

const HOLDS := 2                ## so oft weist sie den Lakengeist ab, dann ist sie grau
const BAND := 0.035             ## halbe Breite der Linie (m)
const GRAINS_PER_M := 1100
const SMUDGE_HALF := 0.14       ## so breit wird die Lücke, wo jemand darübergeht (halbe Breite)
const SMUDGE_DEPTH := 0.28      ## so nah (quer zur Linie, waagrecht) muss ein Fuß kommen
const CHECK_EVERY := 0.2
const COLOR_FRESH := Color(0.93, 0.93, 0.9)
const COLOR_WORN := Color(0.74, 0.73, 0.7)
const COLOR_DEAD := Color(0.4, 0.39, 0.37)
## Lage: so weit vor der Türebene (auf der Seite dessen, der streut), so weit muss er selbst davor stehen (sonst stünde
## er darin); am Fenster so weit vor der Scheibe in der Laibung, so viel kürzer als Tür bzw. Fenster
const THRESHOLD_Z := 0.2
const STEP_BACK := 0.55
const SILL_Z := 0.07
const DOOR_TRIM := 0.05
const SILL_TRIM := 0.08

var length := 1.0
var room := ""                  ## Zimmer, das sie schützt (LevelBuilder.home_room_at; "" = keins)
var on_sill := false            ## auf einer Fensterbank (keiner läuft darüber)
var hits := 0                   ## so oft hat sie ihn schon abgewiesen
var smudge := NAN               ## verwischt an dieser Stelle (lokale X), sonst NAN
var grain_seed := 0

var _grains: MultiMeshInstance3D
var _check := 0.0
var _sides := {}                ## Instanz-ID → Seite (lokale Z) beim letzten Prüfen – wer schnell ist, springt übers Band


func setup(p_length: float, p_room: String, p_sill: bool, p_seed: int = -1) -> SaltLine:
	length = p_length
	room = p_room
	on_sill = p_sill
	grain_seed = p_seed if p_seed >= 0 else randi()
	return self


func _ready() -> void:
	add_to_group("salt_lines")
	_check = randf() * CHECK_EVERY
	_build()


## Hält sie noch? Nicht verwischt und noch nicht grau.
func intact() -> bool:
	return is_nan(smudge) and hits < HOLDS


## Heile Linie, die dieses Zimmer schützt (oder null).
static func guarding(p_room: String) -> SaltLine:
	if p_room == "" or Game.player == null:
		return null
	for node in Game.player.get_tree().get_nodes_in_group("salt_lines"):
		var line := node as SaltLine
		if line.room == p_room and line.intact():
			return line
	return null


## Zimmer hinter einer Öffnung: Zimmertür → ihre Nummer, Fenstertür und Fenster → das Zimmer drinnen (ein Bad zählt
## zum Zimmer davor). Flurtüren schützen kein Zimmer.
static func room_of(opening: Node3D) -> String:
	var builder := Game.social.builder if Game.social else null
	if opening is Door:
		var door := opening as Door
		if door.room_no != "":
			return door.room_no
		return builder.home_of(door.room_id) if door.room_id != "" and builder else ""
	if opening is HotelWindow and builder:
		return builder.home_of((opening as HotelWindow).room_id)
	return ""


## Wohin eine Linie an dieser Tür bzw. diesem Außenfenster käme, gestreut von `from` aus: {} = hier nicht; sonst
## {"yaw", "len", "room", "sill", "prompt"} und "pos" – fehlt an einer Tür, wenn `from` zu nah an der Schwelle ist.
static func spot_for(opening: Node3D, from: Vector3) -> Dictionary:
	var room := room_of(opening)
	if opening is HotelWindow:
		var win := opening as HotelWindow
		if not win.has_curtains() or win.sealed:
			return {}
		return {"pos": win.global_transform * Vector3(0, -win.height / 2.0 + OpeningFrame.JAMB + 0.003, SILL_Z),
			"yaw": win.global_rotation.y, "len": win.width - SILL_TRIM, "room": room, "sill": true,
			"prompt": "Salz auf die Fensterbank streuen [Linksklick]"}
	if opening is Door:
		var door := opening as Door
		var local := door.global_transform.affine_inverse() * from
		var side := 1.0 if local.z >= 0.0 else -1.0
		var spot := {"yaw": door.global_rotation.y + (0.0 if side > 0.0 else PI), "len": door.width - DOOR_TRIM,
			"room": room, "sill": false, "prompt": "Salz über die Schwelle streuen [Linksklick]"}
		if absf(local.z) < STEP_BACK:
			spot["prompt"] = "Für das Salz einen Schritt zurücktreten"
		else:
			spot["pos"] = door.global_transform * Vector3(door.width / 2.0, 0.003, side * THRESHOLD_Z)
		return spot
	return {}


## Neue Linie nach spot_for in `parent` – eine alte an derselben Stelle ersetzt sie.
static func lay(parent: Node, spot: Dictionary) -> SaltLine:
	var at: Vector3 = spot["pos"]
	for node in parent.get_tree().get_nodes_in_group("salt_lines"):
		if (node as Node3D).global_position.distance_to(at) < 0.3:
			node.queue_free()
	var line := SaltLine.new().setup(float(spot["len"]), String(spot["room"]), bool(spot["sill"]))
	parent.add_child(line)
	line.global_position = at
	line.rotation.y = float(spot["yaw"])
	if Game.tracing:
		print("[Salz] %s gestreut" % line._label())
	return line


## Der Lakengeist kam nicht hinein: einmal mehr gehalten, ab HOLDS grau.
func repel() -> void:
	hits += 1
	Game.sound_at("hiss", global_position, 4.0, self, 0.5)
	if Game.tracing:
		print("[Salz] %s hält den Lakengeist ab (%d/%d)%s" % [_label(), hits, HOLDS, " – jetzt grau" if hits >= HOLDS else ""])
	_build()


func _physics_process(delta: float) -> void:
	if on_sill or not is_nan(smudge):
		return
	_check -= delta
	if _check > 0.0:
		return
	_check = CHECK_EVERY
	for actor in _walkers():
		var local: Vector3 = global_transform.affine_inverse() * (actor as Node3D).global_position
		var id := (actor as Object).get_instance_id()
		var before: float = _sides.get(id, local.z)
		_sides[id] = local.z
		if absf(local.x) > length / 2.0 + 0.1 or absf(local.y) > 0.5:
			continue
		if absf(local.z) < SMUDGE_DEPTH or (signf(before) != signf(local.z) and absf(before - local.z) < 3.0):
			_smudge_at(local.x, actor)
			return


## Wer über die Schwelle laufen kann: der Spieler (nicht geduckt), wache Gäste, das Monster.
func _walkers() -> Array:
	var list: Array = []
	var player := Game.player
	if player and not player.dead and player.hiding == null and not player.crouching:
		list.append(player)
	if Game.social:
		for guest in Game.social.guests:
			var g: Guest = guest
			if not g.dead and g.hiding == null:
				list.append(g)
	if Game.monster and Game.monster.is_active():
		list.append(Game.monster)
	return list


func _smudge_at(x: float, actor: Node) -> void:
	smudge = clampf(x, -length / 2.0, length / 2.0)
	if Game.tracing:
		var who := "dir" if actor == Game.player else ("dem Monster" if actor == Game.monster else (actor as Guest).display_name)
		print("[Salz] %s verwischt von %s" % [_label(), who])
	if actor == Game.player:
		Game.say("Du bist durch das Salz gelaufen.", 2.5)
	_build()


func _label() -> String:
	return "Linie %s" % ("am Fenster von %s" % room if on_sill else ("vor %s" % room if room != "" else "an einer Tür"))


## Körner als MultiMesh, aus grain_seed immer gleich gestreut; verwischt mit einer Lücke, an deren Rand das Salz
## breit verteilt liegt.
func _build() -> void:
	if _grains:
		_grains.queue_free()
	var rng := RandomNumberGenerator.new()
	rng.seed = grain_seed
	var spots: Array[Transform3D] = []
	for i in int(length * GRAINS_PER_M):
		var x := rng.randf_range(-length / 2.0, length / 2.0)
		var z := clampf(rng.randfn(0.0, BAND * 0.45), -BAND * 1.6, BAND * 1.6)
		if rng.randf() < 0.06:   # einzelne Körner springen weiter
			z = rng.randf_range(-0.07, 0.07)
		var s := rng.randf_range(0.003, 0.0065)
		var keep := true
		if not is_nan(smudge) and absf(x - smudge) < SMUDGE_HALF:
			keep = rng.randf() < 0.3
			z = rng.randf_range(-0.16, 0.16)
			x += signf(x - smudge) * rng.randf_range(0.0, 0.05)
		if not keep:
			continue
		var basis := Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3(s, s * rng.randf_range(0.5, 1.0), s))
		spots.append(Transform3D(basis, Vector3(x, s * 0.3, z)))
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = Geo.box(Vector3.ONE)
	mm.instance_count = spots.size()
	for i in spots.size():
		mm.set_instance_transform(i, spots[i])
	_grains = MultiMeshInstance3D.new()
	_grains.multimesh = mm
	_grains.material_override = Mat.psx(COLOR_DEAD if hits >= HOLDS else (COLOR_WORN if hits > 0 else COLOR_FRESH))
	_grains.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_grains)


func save_state() -> Dictionary:
	return {"pos": [global_position.x, global_position.y, global_position.z], "yaw": global_rotation.y, "len": length,
		"room": room, "sill": on_sill, "hits": hits, "smudge": null if is_nan(smudge) else smudge, "seed": grain_seed}


static func from_state(d: Dictionary) -> SaltLine:
	var line := SaltLine.new().setup(float(d.get("len", 1.0)), String(d.get("room", "")), bool(d.get("sill", false)),
		int(d.get("seed", 0)))
	line.hits = int(d.get("hits", 0))
	line.smudge = NAN if d.get("smudge") == null else float(d["smudge"])
	return line   # Lage setzt der Aufrufer nach dem Einhängen (pos, yaw)
