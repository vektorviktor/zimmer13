class_name Flashlight
extends Node3D
## Taschenlampe (Spielkonzept 4.16) – hängt an einem Item der Art FLASHLIGHT.
##   · Normales Licht: zum Sehen. Kein Schutzbereich – die Lampe gehört nicht zur Gruppe
##     „light_source“ und zählt nicht für die Abschreckung (sonst wäre sie eine helle Zone zum
##     Mitnehmen). Wer sie trägt, ist auffälliger als mit einer Kerze (Senses, 4.15).
##   · UV-Licht (erst mit dem UV-Aufsatz, einem späteren Fund): leert die Batterie in Sekunden.
##     Steht das Monster lange genug im Kegel, flieht es – aber es weiß dann, wer es war
##     (MonsterDirector.on_monster_uv). UV zeigt Verborgenes (UvMark, Warnungszettel).
##   · In der Nähe des Monsters flackert sie wie die Lampen.
## Lokale +Z = Leuchtrichtung (Vorderseite des Gegenstands).

# --- Tuning -------------------------------------------------------------------
const NORMAL_SECONDS := 300.0   ## eine Batterie reicht für einen Ingame-Tag normales Licht …
const UV_SECONDS := 9.0         ## … aber nur für Sekunden UV
const START_CHARGE := 0.5       ## die gefundene Lampe ist halb leer
const LOW_CHARGE := 0.15        ## darunter wird das Licht schwach und unruhig
const UV_RANGE := 6.0           ## so nah muss das Monster sein
const UV_CONE_DOT := 0.94       ## ca. 20° um die Mitte des Kegels
const UV_REVEAL_RANGE := 7.0    ## Verborgenes sichtbar machen
const UV_REVEAL_DOT := 0.9
const SCAN_INTERVAL := 0.1
const NORMAL_COLOR := Color(1.0, 0.93, 0.8)
const UV_COLOR := Color(0.45, 0.22, 1.0)

var charge := START_CHARGE
var has_uv := false
var uv_mode := false
var on := false

var _beam: SpotLight3D
var _lens: ShaderMaterial
var _scan := 0.0
var _exposure := 0.0
var _level := 1.0
var _level_timer := 0.0


## Aus Item.create_extra(): "c=0.42;uv;m=uv;on" (alles optional)
func setup(extra: String) -> Flashlight:
	for part in extra.split(";", false):
		if part.begins_with("c="):
			charge = clampf(part.substr(2).to_float(), 0.0, 1.0)
		elif part == "uv":
			has_uv = true
		elif part == "m=uv":
			uv_mode = true
		elif part == "on":
			on = true
	uv_mode = uv_mode and has_uv
	on = on and charge > 0.0
	return self


func save_extra() -> String:
	var parts: Array[String] = ["c=%.2f" % charge]
	if has_uv:
		parts.append("uv")
	if uv_mode:
		parts.append("m=uv")
	if on:
		parts.append("on")
	return ";".join(parts)


func _ready() -> void:
	# Gehäuse: Rohr entlang +Z, Kopf mit Glas vorn
	var body := Geo.mesh(self, Geo.cylinder(0.02, 0.15, 8), Mat.psx(Color(0.16, 0.17, 0.19)), Vector3(0, 0.035, -0.01))
	body.rotation.x = PI / 2.0
	var head := Geo.mesh(self, Geo.cylinder(0.031, 0.045, 8), Mat.psx(Color(0.55, 0.56, 0.58)), Vector3(0, 0.035, 0.085))
	head.rotation.x = PI / 2.0
	Geo.mesh(self, Geo.box(Vector3(0.012, 0.008, 0.03)), Mat.psx(Color(0.6, 0.1, 0.08)), Vector3(0, 0.057, 0.0))   # Schalter
	_lens = Mat.psx(Color(0.85, 0.85, 0.8), "", 1.0, NORMAL_COLOR, 0.0, false)
	var glass := Geo.mesh(self, Geo.cylinder(0.026, 0.004, 8), _lens, Vector3(0, 0.035, 0.108))
	glass.rotation.x = PI / 2.0
	_beam = SpotLight3D.new()
	_beam.position = Vector3(0, 0.035, 0.115)
	_beam.rotation.y = PI   # SpotLight leuchtet entlang −Z
	_beam.shadow_enabled = true
	_beam.spot_attenuation = 0.8
	add_child(_beam)
	_apply_light()


func is_held_by_player() -> bool:
	return Game.player != null and Game.player.held == get_parent()


## Linksklick: an/aus
func toggle() -> void:
	if not on and charge <= 0.0:
		Game.say("Klick. Nichts – die Batterie ist leer.")
		Game.play_sound("blip", 0.25)
		return
	on = not on
	_exposure = 0.0
	Game.play_sound("blip", 0.3)
	if on and charge < LOW_CHARGE:
		Game.say("Das Licht ist nur noch schwach.", 2.0)
	_apply_light()


## [R]: zwischen normalem Licht und UV umschalten
func switch_mode() -> void:
	if not has_uv:
		Game.say("Die Lampe hat nur normales Licht.")
		return
	uv_mode = not uv_mode
	_exposure = 0.0
	Game.play_sound("blip", 0.3)
	Game.say("UV-Licht" if uv_mode else "Normales Licht", 1.2)
	_apply_light()


## Neue Batterie: voll
func insert_battery() -> void:
	charge = 1.0
	_apply_light()


func add_uv_filter() -> void:
	has_uv = true
	_apply_light()


## Auffälligkeit für Senses: 0 = aus
func carried_conspicuity() -> float:
	if not on:
		return 0.0
	return Senses.CARRY_UV if uv_mode else Senses.CARRY_FLASHLIGHT


func _process(delta: float) -> void:
	if not on:
		return
	charge -= delta / (UV_SECONDS if uv_mode else NORMAL_SECONDS)
	if charge <= 0.0:
		charge = 0.0
		on = false
		_apply_light()
		if is_held_by_player():
			Game.say("Die Lampe flackert – und geht aus. Die Batterie ist leer.")
		return
	_update_level(delta)
	if uv_mode and is_held_by_player():
		_scan -= delta
		if _scan <= 0.0:
			_scan = SCAN_INTERVAL
			_reveal()
		_check_monster(delta)


## Schwache Batterie und die Nähe des Monsters lassen das Licht flackern.
func _update_level(delta: float) -> void:
	_level_timer -= delta
	if _level_timer > 0.0:
		return
	_level_timer = randf_range(0.04, 0.14)
	var level := 1.0
	if charge < LOW_CHARGE:
		level = 0.35 + 0.65 * charge / LOW_CHARGE
		if randf() < 0.08:
			level *= 0.3
	var monster := Game.monster
	if monster and monster.is_active():
		var near := clampf(1.0 - monster.global_position.distance_to(global_position) / MonsterDirector.LAMP_FLICKER_RANGE, 0.0, 1.0)
		var f := near * 0.9 * Settings.flicker_intensity
		if randf() < f * 0.35:
			level *= randf_range(0.0, 0.2)
		else:
			level -= randf() * f * 0.3
	_level = level
	_apply_light()


func _apply_light() -> void:
	if _beam == null:
		return
	_beam.visible = on
	if uv_mode:
		_beam.light_color = UV_COLOR
		_beam.light_energy = 1.6 * _level
		_beam.spot_range = UV_RANGE + 1.5
		_beam.spot_angle = 20.0
	else:
		_beam.light_color = NORMAL_COLOR
		_beam.light_energy = 2.4 * _level
		_beam.spot_range = 14.0
		_beam.spot_angle = 24.0
	_lens.set_shader_parameter("emission", UV_COLOR if uv_mode else NORMAL_COLOR)
	_lens.set_shader_parameter("emission_energy", 3.0 * _level if on else 0.0)


func _forward() -> Vector3:
	return global_transform.basis.z.normalized()


## Im UV-Kegel und frei sichtbar (Wände, Türen, Milchglas und Vorhänge halten UV auf)?
func _in_cone(p: Vector3, max_range: float, min_dot: float, exclude: Array[RID] = []) -> bool:
	var from := _beam.global_position
	var to := p - from
	var dist := to.length()
	if dist > max_range or dist < 0.01 or _forward().dot(to / dist) < min_dot:
		return false
	# Kurz vor dem Ziel aufhören – Schrift sitzt direkt auf der Wand
	var end := from + to * maxf(0.0, (dist - 0.08) / dist)
	var query := PhysicsRayQueryParameters3D.create(from, end, Senses.SIGHT_MASK)
	query.exclude = exclude
	return get_world_3d().direct_space_state.intersect_ray(query).is_empty()


## Verborgenes im Kegel aufleuchten lassen
func _reveal() -> void:
	for node in get_tree().get_nodes_in_group("uv_marks"):
		var mark := node as UvMark
		if mark.is_visible_in_tree() and _in_cone(mark.global_position, UV_REVEAL_RANGE, UV_REVEAL_DOT):
			mark.shine()


## Steht das Monster lange genug im UV-Kegel, flieht es (Spielkonzept 4.16).
func _check_monster(delta: float) -> void:
	var monster := Game.monster
	var director := Game.director
	if monster == null or director == null or not monster.can_be_repelled_by_uv():
		_exposure = 0.0
		return
	var chest := monster.global_position + Vector3.UP * 1.3
	if _in_cone(chest, UV_RANGE, UV_CONE_DOT, [monster.get_rid()]):
		_exposure += delta
		monster.uv_flinch()
		if _exposure >= director.uv_repel_time():
			_exposure = 0.0
			director.on_monster_uv()
	else:
		_exposure = maxf(0.0, _exposure - delta * 2.0)
