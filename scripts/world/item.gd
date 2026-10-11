class_name Item
extends RigidBody3D
## Physischer Gegenstand. Es gibt kein Inventar – alles wird einzeln in den Händen
## getragen (Ausnahme: Münzen werden sofort zu Geld). Ursprung = Unterseite,
## lokale +Z-Achse = Vorderseite (z. B. das Gesicht eines geschnitzten Kürbisses).
##
## Handwerk: Messer in der Hand + Kürbis → schnitzen; Kerze in der Hand + geschnitzter
## Kürbis ohne Licht → Kerze hineinstellen.
##
## Kompass: Die Nadel zeigt nach Norden (Welt −Z) und schwingt nach. In der Nähe des
## Monsters zittert sie, ganz nah dreht sie sich wild – ebenso bei Halluzinationen.

enum Kind { PUMPKIN, CARVED_PUMPKIN, CANDLE, KEY, COBWEB, LEAVES, COINS, KNIFE, DICE_CUP, LOADED_DICE, BULB, CLOTHING, COMPASS }

const LAYER := 4
const MASK := 1 | 2 | 4 | 16 | 64 | 256
## Grundpreise für den Handel mit Gästen
const PRICES := {
	Kind.PUMPKIN: 4, Kind.CARVED_PUMPKIN: 10, Kind.CANDLE: 3, Kind.COBWEB: 3,
	Kind.LEAVES: 1, Kind.KNIFE: 5, Kind.KEY: 0, Kind.COINS: 0, Kind.DICE_CUP: 2, Kind.LOADED_DICE: 6, Kind.BULB: 4, Kind.CLOTHING: 0, Kind.COMPASS: 6,
}

var kind: Kind = Kind.PUMPKIN
var display_name := ""
var deco_strength := 0.0
var is_large := false
var key_id := ""
var coin_value := 0
var is_held := false
## Besitzer: "" = niemand, "player" oder die ID eines Gastes
var owner_id := ""
var lit := false
var light: FlickerLight
var burn_time := 0.0
## Glühbirne: durchgebrannt (nutzlos, nur noch Scherben im Glas)
var broken := false
## Kleidungsstück: wem es gehörte (Gast-ID) – Spur von Verschwundenen
var clothing_of := ""

var _glow_material: ShaderMaterial
## Kompass: Nadel (dreht um die lokale Y-Achse), Winkel und Schwung der Feder
var _needle: Node3D
var _needle_angle := 0.0
var _needle_speed := 0.0
var _needle_spin := 0.0
var _needle_time := 0.0


static func create(p_kind: Kind, extra: String = "") -> Item:
	var item := Item.new()
	item.kind = p_kind
	item._build(extra)
	return item


func _ready() -> void:
	add_to_group("items")
	set_meta("interactable", self)


func _process(delta: float) -> void:
	if _needle:
		_update_needle(delta)
	if not lit or burn_time <= 0.0:
		return
	burn_time -= delta
	if burn_time <= 0.0:
		_extinguish()


func price() -> int:
	if broken:
		return 0
	return int(PRICES.get(kind, 1))


## Zusatzangabe für Item.create(), mit der sich der Gegenstand nachbauen lässt (Speichern).
func create_extra() -> String:
	match kind:
		Kind.KEY:
			return key_id
		Kind.COINS:
			return str(coin_value)
		Kind.BULB:
			return "broken" if broken else ""
		Kind.CARVED_PUMPKIN:
			return "" if lit else "unlit"
		Kind.CLOTHING:
			return clothing_of
	return ""


func get_prompt(player: Player) -> String:
	var held := player.held_kind()
	if kind == Kind.PUMPKIN and held == Kind.KNIFE:
		return "Kürbis schnitzen [E]"
	if kind == Kind.CARVED_PUMPKIN and not lit and held == Kind.CANDLE:
		return "Kerze hineinstellen [E]"
	if kind == Kind.COINS:
		return "%s aufheben (+%d) [E]" % [display_name, coin_value]
	if owner_id != "" and owner_id != "player" and Game.social:
		return "%s nehmen [E]  – gehört %s" % [display_name, Game.social.guest_name(owner_id)]
	return "%s nehmen [E]" % display_name


func interact(player: Player) -> void:
	var held := player.held_kind()
	if kind == Kind.PUMPKIN and held == Kind.KNIFE:
		carve()
		Game.say("Du schnitzt eine Fratze in den Kürbis.", 2.5)
		return
	if kind == Kind.CARVED_PUMPKIN and not lit and held == Kind.CANDLE:
		player.consume_held()
		light_up()
		Game.say("Die Kerze flackert im Kürbis auf.", 2.5)
		return
	player.try_pick_up(self)


## Ersetzt diesen Kürbis durch einen geschnitzten (noch ohne Kerze).
func carve() -> Item:
	var carved := Item.create(Kind.CARVED_PUMPKIN, "unlit")
	carved.owner_id = owner_id
	get_parent().add_child(carved)
	carved.global_transform = global_transform
	Game.play_sound("creak", 0.6)
	queue_free()
	return carved


func light_up(with_sound: bool = true) -> void:
	if light == null:
		return
	lit = true
	light.burn_out = false
	burn_time = 900.0 if kind == Kind.CARVED_PUMPKIN else 600.0
	if kind == Kind.CARVED_PUMPKIN:
		deco_strength = 30.0
		display_name = "Geschnitzter Kürbis"
	if _glow_material:
		_glow_material.set_shader_parameter("emission_energy", 3.0)
	if with_sound:
		Game.play_sound("blip", 0.4)


## Das Monster geht vorbei: Kerze oder Kürbis erlischt (Spur, Spielkonzept 4.13).
func blow_out() -> void:
	if not lit:
		return
	_extinguish()
	if Game.player and Game.player.global_position.distance_to(global_position) < 6.0:
		Game.caption("[Eine Kerze erlischt]")


func _extinguish() -> void:
	lit = false
	burn_time = 0.0
	if light:
		light.burn_out = true
	if _glow_material:
		_glow_material.set_shader_parameter("emission_energy", 0.0)
	match kind:
		Kind.CARVED_PUMPKIN:
			deco_strength = 20.0
			display_name = "Geschnitzter Kürbis (ohne Licht)"
		Kind.CANDLE:
			deco_strength = 2.0
			display_name = "Kerzenstummel"


## Kompassnadel: gedämpfte Feder Richtung Norden; das Monster stört sie (Bedrohung wie beim
## Rauschen, wirkt durch Wände), nach einem Todesfall auch Halluzinationen.
func _update_needle(delta: float) -> void:
	var north := global_basis.inverse() * Vector3.FORWARD
	var target := atan2(-north.x, -north.z)
	var director := Game.director
	var threat := director.threat_at(global_position) if director else 0.0
	if is_held and director and director.is_hallucinating() and Game.player and Game.player.held == self:
		threat = maxf(threat, 0.8)
	_needle_time += delta
	if threat > 0.75:
		# Ganz nah: die Nadel dreht sich im Kreis
		_needle_spin += delta * (6.0 + 8.0 * threat)
		target = _needle_spin
	else:
		_needle_spin = _needle_angle
		target += sin(_needle_time * 13.0) * threat * 1.1 + randf_range(-1.0, 1.0) * threat * 0.9
	var accel := wrapf(target - _needle_angle, -PI, PI) * 45.0 - _needle_speed * 5.0
	_needle_speed += accel * delta
	_needle_angle = wrapf(_needle_angle + _needle_speed * delta, -PI, PI)
	_needle.rotation.y = _needle_angle


func set_held(held: bool) -> void:
	is_held = held
	# In der Hand: statisch eingefroren – dann folgt der Körper seinem Elternknoten (Hand).
	# Kinematisch eingefroren schrieb die Physik die alte Lage zurück: der Gegenstand drehte
	# beim Umsehen nicht mit.
	freeze_mode = RigidBody3D.FREEZE_MODE_STATIC if held else RigidBody3D.FREEZE_MODE_KINEMATIC
	freeze = held
	collision_layer = 0 if held else LAYER
	collision_mask = 0 if held else MASK
	if not held:
		sleeping = false


func _build(extra: String) -> void:
	collision_layer = LAYER
	collision_mask = MASK
	freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC
	var size := Vector3(0.2, 0.2, 0.2)
	match kind:
		Kind.PUMPKIN:
			display_name = "Kürbis"
			deco_strength = 10.0
			is_large = true
			mass = 4.0
			size = Vector3(0.42, 0.34, 0.42)
			_pumpkin(false)
		Kind.CARVED_PUMPKIN:
			display_name = "Geschnitzter Kürbis"
			is_large = true
			mass = 3.5
			size = Vector3(0.42, 0.34, 0.42)
			_pumpkin(true)
			_add_light(Vector3(0, 0.18, 0), Color(1.0, 0.55, 0.15), 0.9, 3.5)
			if extra == "unlit":
				_extinguish()
			else:
				light_up(false)
		Kind.CANDLE:
			display_name = "Kerze"
			deco_strength = 8.0
			mass = 0.3
			size = Vector3(0.08, 0.16, 0.08)
			Geo.mesh(self, Geo.cylinder(0.035, 0.14, 6), Mat.psx(Color(0.92, 0.88, 0.75)), Vector3(0, 0.07, 0))
			_glow_material = Mat.psx(Color(1, 0.8, 0.3), "", 1.0, Color(1, 0.7, 0.2), 4.0, false)
			Geo.mesh(self, Geo.sphere(0.018, 0.045, 5, 2), _glow_material, Vector3(0, 0.165, 0))
			_add_light(Vector3(0, 0.22, 0), Color(1.0, 0.7, 0.35), 0.55, 2.6)
			light_up(false)
		Kind.KEY:
			key_id = extra
			display_name = "Schlüssel" if extra == "" else "Schlüssel %s" % extra.replace("zimmer_", "Zimmer ")
			mass = 0.1
			size = Vector3(0.14, 0.03, 0.05)
			var gold := Mat.psx(Color(0.85, 0.68, 0.25))
			Geo.mesh(self, Geo.box(Vector3(0.09, 0.015, 0.02)), gold, Vector3(0.02, 0.01, 0))
			Geo.mesh(self, Geo.box(Vector3(0.04, 0.02, 0.045)), gold, Vector3(-0.045, 0.01, 0))
		Kind.COBWEB:
			display_name = "Spinnenweben"
			deco_strength = 12.0
			mass = 0.05
			size = Vector3(0.5, 0.03, 0.5)
			var plane := PlaneMesh.new()
			plane.size = Vector2(0.55, 0.55)
			Geo.mesh(self, plane, Mat.cobweb(), Vector3(0, 0.02, 0))
		Kind.LEAVES:
			display_name = "Herbstlaub"
			deco_strength = 5.0
			mass = 0.2
			size = Vector3(0.4, 0.06, 0.4)
			var rng := RandomNumberGenerator.new()
			var colors: Array[Color] = [Color(0.75, 0.35, 0.08), Color(0.6, 0.15, 0.05), Color(0.8, 0.55, 0.1), Color(0.45, 0.25, 0.08)]
			for i in 9:
				var leaf := Geo.mesh(self, Geo.box(Vector3(0.09, 0.012, 0.06)), Mat.psx(colors[i % colors.size()]),
					Vector3(rng.randf_range(-0.15, 0.15), 0.01 + i * 0.004, rng.randf_range(-0.15, 0.15)))
				leaf.rotation.y = rng.randf() * TAU
		Kind.COINS:
			display_name = "Münzen"
			coin_value = extra.to_int() if extra.is_valid_int() else 3
			mass = 0.2
			size = Vector3(0.1, 0.05, 0.1)
			for i in 3:
				Geo.mesh(self, Geo.cylinder(0.04, 0.012, 8), Mat.psx(Color(0.9, 0.75, 0.3)), Vector3(0.008 * i, 0.006 + i * 0.013, 0))
		Kind.KNIFE:
			display_name = "Messer"
			mass = 0.2
			size = Vector3(0.26, 0.03, 0.04)
			Geo.mesh(self, Geo.box(Vector3(0.16, 0.006, 0.026)), Mat.psx(Color(0.75, 0.78, 0.8)), Vector3(0.05, 0.012, 0))
			Geo.mesh(self, Geo.box(Vector3(0.1, 0.022, 0.03)), Mat.psx(Color(0.15, 0.08, 0.05)), Vector3(-0.08, 0.012, 0))
		Kind.DICE_CUP:
			display_name = "Würfelbecher"
			mass = 0.2
			size = Vector3(0.11, 0.12, 0.11)
			Geo.mesh(self, Geo.cylinder(0.05, 0.11, 8), Mat.psx(Color(0.35, 0.18, 0.1)), Vector3(0, 0.055, 0))
			Geo.mesh(self, Geo.cylinder(0.055, 0.015, 8), Mat.psx(Color(0.55, 0.35, 0.15)), Vector3(0, 0.11, 0))
		Kind.LOADED_DICE:
			display_name = "Gezinkte Würfel"
			mass = 0.05
			size = Vector3(0.08, 0.03, 0.05)
			for i in 2:
				Geo.mesh(self, Geo.box(Vector3(0.025, 0.025, 0.025)), Mat.psx(Color(0.95, 0.9, 0.85)), Vector3(-0.02 + i * 0.04, 0.013, 0))
				Geo.mesh(self, Geo.box(Vector3(0.008, 0.002, 0.008)), Mat.psx(Color(0.7, 0.05, 0.05)), Vector3(-0.02 + i * 0.04, 0.026, 0))
		Kind.CLOTHING:
			clothing_of = extra
			var profile: Dictionary = GuestProfiles.get_profile(extra)
			display_name = String(profile.get("clothing", "Ein Kleidungsstück"))
			mass = 0.2
			size = Vector3(0.36, 0.04, 0.24)
			var cloth := Mat.psx(profile.get("coat", Color(0.3, 0.25, 0.25)))
			var folded := Geo.mesh(self, Geo.box(Vector3(0.34, 0.025, 0.2)), cloth, Vector3(0, 0.013, 0))
			folded.rotation.y = 0.2
			Geo.mesh(self, Geo.box(Vector3(0.12, 0.02, 0.26)), cloth, Vector3(0.1, 0.03, 0.02))
		Kind.BULB:
			broken = extra == "broken"
			display_name = "Kaputte Glühbirne" if broken else "Glühbirne"
			mass = 0.05
			size = Vector3(0.07, 0.11, 0.07)
			Geo.mesh(self, Geo.cylinder(0.018, 0.03, 6), Mat.psx(Color(0.7, 0.68, 0.6)), Vector3(0, 0.015, 0))
			var glass := Color(0.35, 0.33, 0.3) if broken else Color(1.0, 0.97, 0.85)
			Geo.mesh(self, Geo.sphere(0.032, 0.07, 6, 3), Mat.psx(glass), Vector3(0, 0.065, 0))
		Kind.COMPASS:
			display_name = "Kompass"
			mass = 0.15
			size = Vector3(0.11, 0.03, 0.11)
			_build_compass()
	var cs := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	cs.shape = box
	cs.position.y = size.y / 2.0
	add_child(cs)


## Messingdose mit Zifferblatt; Nadel und Nordmarke leuchten schwach (Leuchtfarbe),
## damit man sie auch im dunklen Flur ablesen kann. Zifferblatt oben (lokale +Y).
func _build_compass() -> void:
	var brass := Mat.psx(Color(0.62, 0.48, 0.22))
	var glow := Color(0.55, 0.95, 0.6)
	Geo.mesh(self, Geo.cylinder(0.05, 0.022, 10), brass, Vector3(0, 0.011, 0))
	Geo.mesh(self, Geo.cylinder(0.043, 0.004, 10), Mat.psx(Color(0.82, 0.78, 0.66)), Vector3(0, 0.022, 0))
	Geo.mesh(self, Geo.box(Vector3(0.014, 0.006, 0.014)), brass, Vector3(0, 0.024, 0.056))   # Öse
	# Nordmarke bei der Öse (in der Hand oben, weg vom Spieler) und Striche für O, S, W
	Geo.mesh(self, Geo.box(Vector3(0.008, 0.002, 0.012)), Mat.psx(glow, "", 1.0, glow, 1.2), Vector3(0, 0.025, 0.034))
	for side in [Vector3(0.036, 0.025, 0), Vector3(0, 0.025, -0.036), Vector3(-0.036, 0.025, 0)]:
		Geo.mesh(self, Geo.box(Vector3(0.004, 0.002, 0.004)), Mat.psx(Color(0.25, 0.2, 0.15)), side)
	_needle = Node3D.new()
	_needle.position = Vector3(0, 0.027, 0)
	add_child(_needle)
	var red := Color(0.95, 0.2, 0.12)
	Geo.mesh(_needle, Geo.box(Vector3(0.007, 0.003, 0.036)), Mat.psx(red, "", 1.0, red, 1.5), Vector3(0, 0, -0.018))
	Geo.mesh(_needle, Geo.box(Vector3(0.007, 0.003, 0.034)), Mat.psx(Color(0.85, 0.85, 0.8), "", 1.0, glow, 0.4), Vector3(0, 0, 0.017))
	Geo.mesh(_needle, Geo.cylinder(0.005, 0.005, 6), brass, Vector3(0, 0.002, 0))


func _pumpkin(carved: bool) -> void:
	var orange := Color(0.75, 0.36, 0.06) if carved else Color(0.85, 0.42, 0.08)
	Geo.mesh(self, Geo.sphere(0.21, 0.32, 9, 5), Mat.psx(orange), Vector3(0, 0.16, 0))
	Geo.mesh(self, Geo.cylinder(0.025, 0.07, 5), Mat.psx(Color(0.3, 0.35, 0.12)), Vector3(0, 0.34, 0))
	if carved:
		_glow_material = Mat.psx(Color(1, 0.8, 0.3), "", 1.0, Color(1.0, 0.6, 0.1), 3.0, false)
		var dark := Mat.psx(Color(0.1, 0.04, 0.0))
		Geo.mesh(self, Geo.box(Vector3(0.06, 0.05, 0.04)), _glow_material, Vector3(-0.075, 0.2, 0.185))
		Geo.mesh(self, Geo.box(Vector3(0.06, 0.05, 0.04)), _glow_material, Vector3(0.075, 0.2, 0.185))
		Geo.mesh(self, Geo.box(Vector3(0.15, 0.035, 0.04)), _glow_material, Vector3(0, 0.1, 0.185))
		Geo.mesh(self, Geo.box(Vector3(0.03, 0.02, 0.045)), dark, Vector3(-0.03, 0.105, 0.187))
		Geo.mesh(self, Geo.box(Vector3(0.03, 0.02, 0.045)), dark, Vector3(0.03, 0.105, 0.187))


func _add_light(pos: Vector3, color: Color, energy: float, light_range: float) -> void:
	light = FlickerLight.new()
	light.position = pos
	light.light_color = color
	light.base_energy = energy
	light.omni_range = light_range
	light.soft = true
	light.shadow_enabled = false
	add_child(light)
