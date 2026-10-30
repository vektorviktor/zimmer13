class_name Nightmare
extends Node
## Der Albtraum von 1987 (Spielkonzept 4.29): einmal im Spiel, frühestens ab FROM_DAY, schläft man nachts im eigenen Bett
## ein – und steht im Heizkeller, Halloween 1987. Das Bild ist alt und warm getönt (Post-Shader `dream`), der Kessel
## faucht, Rauch quillt aus der Klappe und wird dichter (die Sicht verschwimmt). Draußen dreht sich ein Schlüssel im
## Schloss: „Die Direktion will heute Nacht keine Störung.“ Die Tür bleibt zu. Man ist der Hausmeister: schwarze Hände, eine
## fremde Stimme, die „Macht auf!“ schreit. Zuletzt ruft von fern ein Mädchen „Papa?“ (Marion, 2.3) – dann wird es weiß,
## und man schreckt im Bett hoch. Wer vorher aus dem Heizkeller läuft, wacht früher auf.
## Was man erfährt: Der Vorname Josef, dass jemand von außen abschloss, und dass er eine Tochter hatte – die Indiz-Stufe
## vor dem Kesselbuch (2.3, HANDLUNG.md M12). Füllt die Lücke 16.–22. Oktober.
## Während des Traums wartet jede Bedrohung (MonsterDirector.other_threat_active), es gibt keinen Zeitsprung und kein
## Speichern. Gespeichert unter „omens“: ob er schon war.

enum Stage { WAITING, DREAMING, DONE }

const FROM_DAY := 15
const START_DELAY := 3.0              ## so lange nach dem Einschlafen
const LENGTH := 36.0
const LEAVE_RANGE := 11.0             ## so weit vom Kessel weg: man wacht auf
const SHOCK := 0.3
## Ablauf: Sekunde → Meldung (Untertitel) bzw. Klang
const SCRIPT := [
	[0.6, "sound", "jingle"],
	[1.2, "say", "Ein Schlüssel dreht sich im Schloss. Von draußen, gedämpft: „Die Direktion will heute Nacht keine Störung.“"],
	[6.5, "say", "Deine Hände sind schwarz vom Kohlenstaub. Es sind nicht deine Hände."],
	[11.0, "say", "Hinter dir faucht der Kessel. Rauch quillt aus der Klappe."],
	[16.0, "sound", "gasp"],
	[19.0, "say", "„Macht auf! Da sind noch Leute hier unten!“ – Du schreist es, aber es ist nicht deine Stimme."],
	[22.0, "sound", "knock"],
	[25.0, "sound", "gasp"],
	[28.0, "say", "Ganz fern, durch die Wand, eine Mädchenstimme: „Papa?“"],
	[31.0, "sound", "gasp"],
]
const DOOR_TEXT := "Abgeschlossen. Von außen."
const WAKE_TEXT := "Du schreckst aus dem Schlaf hoch. Kohlengeruch hängt in deinen Kleidern."
const NOTE := "Ich habe geträumt, ich sei der Hausmeister. Halloween 1987. Jemand schloss den Heizkeller von außen ab, es brannte, und ein Mädchen rief „Papa“. Er hieß Josef – so rief ihn einer im Traum."
const DIARY := "Ein Traum, so wirklich wie nichts in diesen Wochen: der Heizkeller, Feuer, eine verschlossene Tür. Jemand rief „Papa“."

var stage := Stage.WAITING
var _builder: LevelBuilder
var _bed: HideSpot
var _t := 0.0
var _delay := -1.0
var _next := 0
var _door: Door
var _door_state := {}
var _smoke: CPUParticles3D
var _glow: OmniLight3D
var _start := Vector3.ZERO


func setup(builder: LevelBuilder) -> Nightmare:
	_builder = builder
	return self


## Läuft gerade (oder steht gleich bevor)? Dann wartet jede Bedrohung.
func active() -> bool:
	return stage == Stage.DREAMING or _delay >= 0.0


func save_state() -> Dictionary:
	return {"nightmare": "done" if stage == Stage.DONE else "waiting"}


func load_state(d: Dictionary) -> void:
	stage = Stage.DONE if String(d.get("nightmare", "waiting")) == "done" else Stage.WAITING


## Aus Player.start_sleep: heute Nacht der Traum? Dann beginnt er nach START_DELAY (statt des Zeitsprungs).
func on_fell_asleep(bed: HideSpot) -> void:
	var d := Game.director
	if stage != Stage.WAITING or d == null or not d.first_attack_done or Calendar.day_of(d.elapsed) < FROM_DAY \
			or Calendar.phase() != Calendar.Phase.NIGHT or d.other_threat_active(null) or not bed.own_bed:
		return
	_bed = bed
	_delay = START_DELAY


func _process(delta: float) -> void:
	if _delay >= 0.0:
		_delay -= delta
		var p := Game.player
		if p == null or not p.sleeping or p.hiding != _bed:   # vorher geweckt
			_delay = -1.0
		elif _delay < 0.0:
			_begin()
		return
	if stage != Stage.DREAMING:
		return
	_t += delta
	_update(delta)


func _begin() -> void:
	var p := Game.player
	var cellar := _builder.cellar_center()
	_door = _boiler_door(cellar)
	stage = Stage.DREAMING
	_t = 0.0
	_next = 0
	p.exit_hide()
	var into := (cellar - (_door.global_position if _door else cellar + Vector3(0, 0, -8))).normalized()
	into.y = 0.0
	_start = (_door.global_position if _door else cellar) + into * 2.2
	_start.y = LevelBuilder.CELLAR_Y + 0.05
	TeleportUI.place_player(_start, -into)   # mit dem Gesicht zur Tür
	if _door:
		_door_state = {"open": _door.is_open, "locked": _door.locked, "text": _door.locked_text}
		_door.set_open(false, true, true)
		_door.locked = true
		_door.locked_text = DOOR_TEXT
	# Feuerschein und Rauch am Kessel – nur Bild, zählt nicht als Licht (nicht in light_source)
	_glow = OmniLight3D.new()
	_glow.light_color = Color(1.0, 0.45, 0.15)
	_glow.omni_range = 14.0
	_glow.light_energy = 0.0
	_glow.position = cellar + Vector3(0, 1.4, 0)
	add_child(_glow)
	_smoke = Geo.particles(160, 7.0, 1.6, Mat.particle(null, 0.0), 0.15, 0.4)
	_smoke.color = Color(0.12, 0.1, 0.09, 0.55)
	_smoke.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	_smoke.emission_box_extents = Vector3(4.5, 0.3, 6.0)
	_smoke.direction = Vector3.UP
	_smoke.spread = 25.0
	_smoke.initial_velocity_min = 0.1
	_smoke.initial_velocity_max = 0.35
	_smoke.gravity = Vector3(0, 0.08, 0)
	_smoke.position = cellar + Vector3(0, 0.6, 0)
	add_child(_smoke)
	if Game.monster and not Game.monster.is_active():
		Game.monster.visible = false
	if Game.tracing:
		print("[Albtraum] beginnt im Heizkeller")


func _update(delta: float) -> void:
	var p := Game.player
	var k := clampf(_t / LENGTH, 0.0, 1.0)
	var post := Game.director.post_material if Game.director else null
	if post:
		var white := clampf((_t - (LENGTH - 2.0)) / 2.0, 0.0, 1.0)
		post.set_shader_parameter("dream", minf(1.0, _t / 1.5) + white)   # gegen Ende wird es gleißend weiß
	p.intro_blur = clampf(0.1 + k * 0.75, 0.0, 0.85) if _t > 1.0 else 1.0 - _t
	_glow.light_energy = (0.6 + 1.6 * k) * randf_range(0.75, 1.0)
	_smoke.color = Color(0.12, 0.1, 0.09, 0.2 + 0.5 * k)   # der Rauch wird dichter
	while _next < SCRIPT.size() and _t >= float(SCRIPT[_next][0]):
		var step: Array = SCRIPT[_next]
		_next += 1
		if step[1] == "say":
			Game.say(String(step[2]), 5.0)
		elif step[2] == "jingle" or step[2] == "knock":
			if _door:
				Game.sound_at(String(step[2]), _door.global_position, 6.0)
		else:
			Game.play_sound(String(step[2]), 0.7)
	var away := p.global_position.distance_to(_builder.cellar_center()) > LEAVE_RANGE \
		or absf(p.global_position.y - LevelBuilder.CELLAR_Y) > 2.0
	if _t >= LENGTH or away or p.dead:
		_end()


func _end() -> void:
	var p := Game.player
	stage = Stage.DONE
	if _door:
		_door.locked = bool(_door_state.get("locked", false))
		_door.locked_text = String(_door_state.get("text", _door.locked_text))
		_door.set_open(bool(_door_state.get("open", false)), true, true)
	if _glow:
		_glow.queue_free()
	if _smoke:
		_smoke.queue_free()
	var post := Game.director.post_material if Game.director else null
	if post:
		post.set_shader_parameter("dream", 0.0)
	p.intro_blur = 0.0
	if p.dead:
		return
	if _bed and is_instance_valid(_bed) and _bed.occupant == null:
		p.enter_hide(_bed)   # im Bett, wach
	p.shock = minf(1.0, p.shock + SHOCK)
	Game.play_sound("gasp", 0.8)
	Game.say(WAKE_TEXT, 4.5)
	if Game.notebook:
		Game.notebook.add_note("nightmare_1987", NOTE, "Traum")
	if Game.diary:
		Game.diary.note("nightmare_1987", DIARY)
	if Game.tracing:
		print("[Albtraum] vorbei nach %.0f s" % _t)


## Die Tür des Heizkellers: die nächste an seiner Nordseite (dem Eingang).
func _boiler_door(cellar: Vector3) -> Door:
	var best: Door = null
	for node in get_tree().get_nodes_in_group("doors"):
		var door := node as Door
		if absf(door.global_position.y - LevelBuilder.CELLAR_Y) > 1.5:
			continue
		if best == null or door.global_position.distance_to(cellar) < best.global_position.distance_to(cellar):
			best = door
	return best if best and best.global_position.distance_to(cellar) < 15.0 else null


## Debug (--albtraum): Nacht am 16., du schläfst in Zimmer 13 ein – nach START_DELAY beginnt der Traum.
func debug() -> void:
	var d := Game.director
	d.first_attack_done = true
	stage = Stage.WAITING
	d.elapsed = maxf(d.elapsed, Calendar.at(FROM_DAY + 1, 0.5))
	var bed: HideSpot = null
	for node in get_tree().get_nodes_in_group("hide_spots"):
		if (node as HideSpot).own_bed:
			bed = node
	if bed == null:
		Game.say("Albtraum: Zimmer 13 hat kein Bett.", 2.5)
		return
	Game.player.start_sleep(bed)
	on_fell_asleep(bed)
