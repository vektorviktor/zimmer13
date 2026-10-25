class_name Lamp
extends StaticBody3D
## Decken- oder Wandlampe mit Glühbirne (Spielkonzept 7.3). Gehört zu einem Raum und
## wird über dessen Lichtschalter geschaltet. Die Birne lässt sich herausdrehen und
## woanders einschrauben – fehlt sie, bleibt die Lampe dunkel und das Monster kommt.
## Birnen brennen selten durch: bei starkem Flackern oder wenn das Monster nahe ist.
## HALOGEN (Untergeschoss, Spielkonzept 7.9): Röhre unter der Decke, kaltweiß, flackert ab und zu von selbst kurz
## auf – ohne Glühbirne: nichts herauszudrehen, brennt nicht durch.
## POOL (Spielkonzept 7.5): runder Scheinwerfer unter Wasser in der Beckenwand, läuft langsam einmal durch den
## Regenbogen und wieder von vorn – jede Lampe mit eigenem Anfang und Tempo; ohne Birne wie HALOGEN.
## FLUSH: runde Deckenleuchte aus Kupfer bündig an der Decke – breiter Rand mit zwei Rillen, abgesetzter Korpus mit
## einer Rille, unten Opalglas, das statt der Birne leuchtet (die Birne steckt dahinter und lässt sich wie sonst
## herausdrehen). CEILING bleibt die Pendelleuchte über den Lufträumen.

enum Style { CEILING, WALL, HALOGEN, POOL, FLUSH }

## Kupferleuchte (FLUSH): Profil von der Decke abwärts als [Radius, Höhe, Rille?] – Rillen sind schmale, etwas
## schmalere Ringe in dunklem Kupfer; darunter das Glas (Radius, Dicke, so weit steht es unter dem untersten Ring vor –
## die Ringe sind volle Zylinder, deren Boden es sonst verdeckte; knapper flimmerte er beim Vertex-Snapping durch) in
## Opalweiß.
## Das Licht sitzt FLUSH_LIGHT_BELOW unter dem Glas – näher strahlte es das Kupfer von unten grell orange an
const FLUSH_PROFILE := [[0.24, 0.03, false], [0.232, 0.006, true], [0.235, 0.024, false], [0.225, 0.006, true],
	[0.228, 0.014, false], [0.19, 0.038, false], [0.185, 0.006, true], [0.19, 0.026, false], [0.196, 0.015, false]]
const FLUSH_GLASS := Vector3(0.172, 0.012, 0.008)
const FLUSH_SEGMENTS := 24
const FLUSH_LIGHT_BELOW := 0.35
const FLUSH_GLASS_GLOW := Color(1.0, 0.95, 0.88)
const COPPER := Color(0.72, 0.42, 0.3)
const COPPER_GROOVE := Color(0.3, 0.14, 0.08)

## Durchbrenn-Chance je Sekunde (geringe Wahrscheinlichkeit)
const BREAK_PER_FLICKER := 0.004     ## × Flackern² (Ankündigung, 0..1)
const BREAK_NEAR_MONSTER := 0.012    ## × Nähe (1 direkt daneben, 0 ab 6 m)
const MONSTER_RANGE := 6.0
## Gesamthelligkeit aller Lampen: Stärke und Reichweite gegenüber den Werten im LevelBuilder
const BRIGHTNESS := 1.35
const REACH := 1.3

## Glühbirne aus tools/build_bulb.py: „socket“ und der Kolben „glass“, Ursprung am Gewindeende, Glas nach +Y,
## 0,11 m lang. Fehlt die Datei, bleibt die Kugel.
const BULB_MODEL := "res://assets/models/bulb.glb"
## So weit steckt das Gewinde (3 cm) in der Fassung
const BULB_SCREWED_IN := 0.02
## Wandleuchte aus Blender: runde Wandplatte in Anthrazit („WallLamp_Body“, 11 cm) mit Band um die Glaskugel
## („WallLamp_Ball“, 9 cm), Ursprung an der Wand, Kugel nach +Z. Die Kugel leuchtet statt der Birne (die steckt
## unsichtbar dahinter und lässt sich wie sonst herausdrehen). Fehlt die Datei, bleibt die Messingleuchte.
const WALL_MODEL := "res://assets/models/wall_lamp.glb"
const WALL_BODY_COLOR := Color(0.22, 0.22, 0.23)
## Im Spiel 1,5-mal so groß (Platte 17 cm, Kugel 13 cm) – in Originalgröße wirkte sie an der Wand verloren
const WALL_SCALE := 1.5
## Mitte der Kugel in Modellmaßen (vor dem Skalieren)
const WALL_BALL := Vector3(0, 0, 0.053)
## Das Licht sitzt wie bei der Messingleuchte 30 cm vor der Wand – die Helligkeit der Räume bleibt gleich
const WALL_LIGHT := Vector3(0, 0.04, 0.3)
## Unterwasserlampe: Sekunden für einmal durch den Regenbogen (je Lampe zufällig dazwischen)
const POOL_CYCLE := Vector2(18.0, 26.0)

var style := Style.CEILING
var length := 0.8   ## Halogenröhre: Länge entlang lokal X
var room_id := ""
var energy := 1.0
var light_range := 6.0
var has_bulb := true
var bulb_broken := false
## Wackelkontakt einer von Anfang an defekten Birne: blitzt ab und zu auf.
var sparking := false
var switched_on := true

var light: FlickerLight
var _bulb: Node3D
var _bulb_material: ShaderMaterial
var _break_timer := 0.0
var _hue := 0.0         ## Unterwasserlampe: Farbton 0..1
var _hue_speed := 0.0   ## je Sekunde


func setup(p_style: Style, p_room: String, p_energy: float, p_range: float, p_broken: bool) -> Lamp:
	style = p_style
	room_id = p_room
	energy = p_energy * BRIGHTNESS
	light_range = p_range * REACH
	bulb_broken = p_broken
	sparking = p_broken
	return self


func _ready() -> void:
	collision_layer = 4
	collision_mask = 0
	add_to_group("lamp_fixtures")
	add_to_group("time_skip")   # Zeitsprung im Schlaf (SleepSkip)
	if style == Style.HALOGEN:
		_build_halogen()
		return
	if style == Style.POOL:
		_build_pool()
		return
	set_meta("interactable", self)
	_bulb_material = Mat.psx(Color(1, 0.95, 0.8), "", 1.0, Color(1.0, 0.85, 0.6), 2.5, false)
	var bulb_pos := Vector3(0, -0.12, 0)
	var socket := Vector3(0, -0.09 + BULB_SCREWED_IN, 0)   # Gewindeende der Birne
	if style == Style.CEILING:
		Geo.mesh(self, Geo.box(Vector3(0.45, 0.06, 0.45)), Mat.psx(Color(0.75, 0.7, 0.6)), Vector3.ZERO)
		Geo.mesh(self, Geo.cylinder(0.02, 0.06, 5), Mat.psx(Color(0.3, 0.28, 0.25)), Vector3(0, -0.06, 0))
	elif style == Style.FLUSH:
		bulb_pos = _build_flush()
		socket = Vector3(0, -0.03, 0)
	elif ResourceLoader.exists(WALL_MODEL):
		_build_wall()
		bulb_pos = WALL_BALL * WALL_SCALE
	else:
		# Wandleuchte ohne Modell: Messinghalter an der Wand (lokale +Z zeigt in den Raum), Fassung am Ende, die
		# Birne steht darauf und reicht mit dem Kolben in den Schirm
		var brass := Mat.psx(Color(0.7, 0.55, 0.25))
		Geo.mesh(self, Geo.box(Vector3(0.12, 0.18, 0.03)), brass, Vector3(0, 0, 0.015))
		Geo.mesh(self, Geo.box(Vector3(0.03, 0.03, 0.16)), brass, Vector3(0, 0, 0.1))
		Geo.mesh(self, Geo.cylinder(0.02, 0.025, 5), brass, Vector3(0, 0.0275, 0.18))
		Geo.mesh(self, Geo.cylinder(0.09, 0.1, 8), Mat.psx(Color(0.85, 0.75, 0.55)), Vector3(0, 0.13, 0.18))
		bulb_pos = Vector3(0, 0.04, 0.18)
		socket = Vector3(0, 0.04 - BULB_SCREWED_IN, 0.18)
	if _bulb == null:   # die Wandleuchte aus dem Modell hat ihre unsichtbare Birne schon (_build_wall)
		_bulb = build_bulb(self, _bulb_material)
		if _bulb:
			_bulb.position = socket
			if style == Style.CEILING or style == Style.FLUSH:
				_bulb.rotation.x = PI   # hängt mit dem Kolben nach unten
		else:
			_bulb = Geo.mesh(self, Geo.sphere(0.045, 0.1, 6, 3), _bulb_material, bulb_pos)
	# Die Leuchte selbst wirft keinen Schatten: Das Licht sitzt vor dem Schirm, sonst zeichnet er einen langen
	# Keil mit dunklem Strich darüber an die Wand
	_no_shadows()
	if style == Style.FLUSH:
		Geo.add_box_shape(self, Vector3(0.48, bulb_pos.y * -1.0, 0.48), bulb_pos * 0.5)
	else:
		Geo.add_box_shape(self, Vector3(0.35, 0.3, 0.35), bulb_pos * 0.5)
	var light_pos := bulb_pos + Vector3(0, 0, 0.12)
	match style:
		Style.CEILING:
			light_pos = bulb_pos + Vector3(0, -0.13, 0)
		Style.FLUSH:
			light_pos = bulb_pos + Vector3(0, -FLUSH_LIGHT_BELOW, 0)
		Style.WALL:
			light_pos = WALL_LIGHT
	_add_light(light_pos, Color(1.0, 0.8, 0.55))
	_break_timer = randf()
	apply_state()


## Wandleuchte aus WALL_MODEL: Platte in Anthrazit, die Kugel mit dem Material der Birne (leuchtet, flackert und
## erlischt mit ihr). Die Birne selbst ist nur ein leerer Knoten – zu sehen ist sie hinter dem Glas nicht.
func _build_wall() -> void:
	var model: Node3D = (load(WALL_MODEL) as PackedScene).instantiate()
	model.scale = Vector3.ONE * WALL_SCALE
	add_child(model)
	for m: MeshInstance3D in model.find_children("*", "MeshInstance3D", true, false):
		m.material_override = _bulb_material if m.name == "WallLamp_Ball" else Mat.metal(WALL_BODY_COLOR)
	_bulb = Node3D.new()
	add_child(_bulb)


## Das Licht der Leuchte (Gruppe „lamps“, flackert mit der Birne bzw. Röhre oder Scheibe).
func _add_light(pos: Vector3, color: Color) -> void:
	light = FlickerLight.new()
	light.position = pos
	light.base_energy = energy
	light.omni_range = light_range
	light.light_color = color
	light.shadow_enabled = true
	# Viele Zimmer → weit entfernte Lampen und ihre Schatten ausblenden (spart Leistung)
	light.distance_fade_enabled = true
	light.distance_fade_begin = 26.0
	light.distance_fade_length = 6.0
	light.distance_fade_shadow = light.distance_fade_begin + light.distance_fade_length   # Schatten bis zum Schluss: ohne ihn schiene es durch Wände
	light.lamp_material = _bulb_material
	light.add_to_group("lamps")
	add_child(light)


## Gehäuse, Birne und Scheibe werfen keinen Schatten.
func _no_shadows() -> void:
	for g: GeometryInstance3D in find_children("*", "GeometryInstance3D", true, false):
		g.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


## Kupferleuchte: Ringe nach FLUSH_PROFILE von der Decke (y 0) abwärts, darunter das Glas mit dem Material der
## Birne (leuchtet, flackert und erlischt mit ihr). Gibt die Unterkante zurück (Birnenstelle für Licht und Kollision).
func _build_flush() -> Vector3:
	_bulb_material.set_shader_parameter("emission", FLUSH_GLASS_GLOW)
	var copper := Mat.metal(COPPER)
	var groove := Mat.psx(COPPER_GROOVE)
	var y := 0.0
	for ring: Array in FLUSH_PROFILE:
		var h: float = ring[1]
		Geo.mesh(self, Geo.cylinder(ring[0], h, FLUSH_SEGMENTS), groove if ring[2] else copper, Vector3(0, y - h / 2.0, 0))
		y -= h
	Geo.mesh(self, Geo.cylinder(FLUSH_GLASS.x, FLUSH_GLASS.y, FLUSH_SEGMENTS), _bulb_material,
		Vector3(0, y - FLUSH_GLASS.z + FLUSH_GLASS.y / 2.0, 0))
	return Vector3(0, y - FLUSH_GLASS.z, 0)


## Halogenleuchte: Blechgehäuse bündig unter der Decke, darunter die Röhre (statt der Birne), kaltweißes Licht mit
## eigenem Flackern (FlickerLight.stutter).
func _build_halogen() -> void:
	set_process(false)   # keine Birne, die durchbrennt
	_bulb_material = Mat.psx(Color(0.9, 0.95, 1.0), "", 1.0, Color(0.8, 0.9, 1.0), 2.5, false)
	Geo.mesh(self, Geo.box(Vector3(length + 0.06, 0.05, 0.12)), Mat.psx(Color(0.55, 0.57, 0.58)), Vector3.ZERO)
	_bulb = Geo.mesh(self, Geo.cylinder(0.02, length, 6), _bulb_material, Vector3(0, -0.045, 0))
	_bulb.rotation.z = PI / 2.0   # der Zylinder steht nach +Y, die Röhre liegt entlang X
	_no_shadows()
	Geo.add_box_shape(self, Vector3(length + 0.06, 0.1, 0.15), Vector3(0, -0.02, 0))
	_add_light(Vector3(0, -0.15, 0), Color(0.85, 0.93, 1.0))
	light.stutter = true
	apply_state()


## Unterwasserlampe: Chromring bündig an der Beckenwand (lokale +Z zeigt ins Becken), davor die Glasscheibe in
## der Farbe des Lichts. Anfangsfarbe und Tempo zufällig, damit keine zwei Lampen gleich laufen.
func _build_pool() -> void:
	_bulb_material = Mat.psx(Color(1, 1, 1), "", 1.0, Color.RED, 2.5, false)
	var ring := Geo.mesh(self, Geo.cylinder(0.14, 0.03, 10), Mat.psx(Color(0.62, 0.66, 0.7)), Vector3(0, 0, 0.015))
	ring.rotation.x = PI / 2.0   # der Zylinder steht nach +Y, die Scheibe liegt an der Wand
	_bulb = Geo.mesh(self, Geo.cylinder(0.11, 0.02, 10), _bulb_material, Vector3(0, 0, 0.035))
	_bulb.rotation.x = PI / 2.0
	_no_shadows()
	Geo.add_box_shape(self, Vector3(0.3, 0.3, 0.06), Vector3(0, 0, 0.03))
	_add_light(Vector3(0, 0, 0.25), Color.WHITE)   # Farbe setzt _set_hue
	_hue = randf()
	_hue_speed = 1.0 / randf_range(POOL_CYCLE.x, POOL_CYCLE.y)
	_set_hue()
	apply_state()


## Unterwasserlampe: Farbe des Farbtons auf Licht und Scheibe.
func _set_hue() -> void:
	light.light_color = Color.from_hsv(_hue, 0.9, 1.0)
	_bulb_material.set_shader_parameter("emission", Color.from_hsv(_hue, 1.0, 1.0))


## Steckt eine Glühbirne darin, die man herausdrehen kann (nicht bei Halogen- und Unterwasserlampen)?
func has_socket() -> bool:
	return style == Style.CEILING or style == Style.WALL or style == Style.FLUSH


## Glühbirne als Modell unter parent (Ursprung am Gewindeende, Glas nach +Y), der Kolben mit glass –
## für Lampen und das Item BULB (Spielkonzept 7.3). null, wenn das Modell fehlt.
static func build_bulb(parent: Node3D, glass: Material) -> Node3D:
	if not ResourceLoader.exists(BULB_MODEL):
		return null
	var model: Node3D = (load(BULB_MODEL) as PackedScene).instantiate()
	parent.add_child(model)
	for m: MeshInstance3D in model.find_children("*", "MeshInstance3D", true, false):
		m.material_override = glass if m.name == "glass" else Mat.model(BULB_MODEL, m)
	return model


func is_lit() -> bool:
	return switched_on and has_bulb and not bulb_broken


## Zustand auf Licht und Aussehen übertragen.
func apply_state() -> void:
	if light == null:
		return
	light.switched_off = not switched_on or not has_bulb or (bulb_broken and not sparking)
	light.broken = bulb_broken and sparking
	_bulb.visible = has_bulb
	if not light.switched_off and not light.broken:
		return
	_bulb_material.set_shader_parameter("emission_energy", 0.0)


func _process(delta: float) -> void:
	if style == Style.POOL:
		_hue = fposmod(_hue + delta * _hue_speed, 1.0)
		_set_hue()
		return
	_break_timer -= delta
	if _break_timer > 0.0:
		return
	_break_timer = 1.0
	if not is_lit():
		return
	var chance := BREAK_PER_FLICKER * light.flicker * light.flicker
	var monster := Game.monster
	if monster and monster.is_active():
		var d := monster.global_position.distance_to(global_position)
		chance += BREAK_NEAR_MONSTER * clampf(1.0 - d / MONSTER_RANGE, 0.0, 1.0)
	if randf() < chance:
		burn_out()


## Zeitsprung im Schlaf (SleepSkip, Spielkonzept 3.6): je Sekunde dieselbe Chance
## durchzubrennen wie sonst (ohne Monster in der Nähe – es war nicht wirklich da).
func skip_time(dt: float) -> void:
	if light == null or not is_lit():
		return
	var chance := BREAK_PER_FLICKER * light.flicker * light.flicker
	if chance > 0.0 and randf() < 1.0 - pow(1.0 - chance, dt):
		burn_out()


## Die Birne brennt durch: kurzes Aufblitzen, Knall – dann bleibt es dunkel.
func burn_out() -> void:
	if not is_lit():
		return
	bulb_broken = true
	sparking = false
	light.light_energy = energy * 3.0
	_bulb_material.set_shader_parameter("emission_energy", 8.0)
	var near := Game.noise("bulb_burst", global_position) >= 0.1
	if near:
		Game.caption("Eine Glühbirne zerplatzt.")
	get_tree().create_timer(0.08, false).timeout.connect(apply_state)
	if Game.director:
		Game.director.on_lights_off(global_position)


# --- Glühbirne ----------------------------------------------------------------

func take_bulb() -> Item:
	if not has_bulb:
		return null
	var item := Item.create(Item.Kind.BULB, "broken" if bulb_broken else "")
	has_bulb = false
	bulb_broken = false
	sparking = false
	apply_state()
	Game.noise("bulb", global_position)
	if switched_on and Game.director:
		Game.director.on_lights_off(global_position)
	return item


func insert_bulb(item: Item) -> void:
	has_bulb = true
	bulb_broken = item.broken
	sparking = false
	apply_state()
	Game.noise("bulb", global_position)


## Wem die Lampe gehört: der erste Erwachsene des Zimmers (Haushalt, Spielkonzept 6.20), sonst wer dort wohnt.
func owner_guest() -> Guest:
	if Game.social == null:
		return null
	var lead := Game.social.household_lead(room_id)
	if lead:
		return lead
	for guest in Game.social.guests:
		if guest.home["no"] == room_id and not guest.dead:
			return guest
	return null


func get_prompt(player: Player) -> String:
	if has_bulb:
		if not player.can_take(Item.Kind.BULB):
			return "Hände voll"
		var what := "Kaputte Glühbirne" if bulb_broken else "Glühbirne"
		var guest := owner_guest()
		if guest:
			return "%s herausdrehen [E]  – gehört %s" % [what, guest.display_name]
		return "%s herausdrehen [E]" % what
	if player.held_kind() == Item.Kind.BULB:
		return "Glühbirne einschrauben [E]"
	return "Leere Fassung"


func interact(player: Player) -> void:
	if has_bulb:
		if not player.can_take(Item.Kind.BULB):
			return
		var guest := owner_guest()
		var item := take_bulb()
		if guest:
			item.owner_id = guest.id
		player.receive_item(item)
		if is_lit_room_dark():
			Game.say("Hier ist es jetzt dunkel …", 2.0)
	elif player.held_kind() == Item.Kind.BULB:
		var item := player.held
		insert_bulb(item)
		player.consume_held()
		if item.broken:
			Game.say("Die Birne ist kaputt – sie leuchtet nicht.", 2.5)


func is_lit_room_dark() -> bool:
	for node in get_tree().get_nodes_in_group("lamp_fixtures"):
		var lamp := node as Lamp
		if lamp.room_id == room_id and lamp.is_lit():
			return false
	return true


# --- Speichern ----------------------------------------------------------------

func save_state() -> Dictionary:
	return {"bulb": has_bulb, "broken": bulb_broken, "sparking": sparking, "on": switched_on}


func load_state(data: Dictionary) -> void:
	has_bulb = bool(data.get("bulb", true))
	bulb_broken = bool(data.get("broken", false))
	sparking = bool(data.get("sparking", false))
	switched_on = bool(data.get("on", true))
	apply_state()
