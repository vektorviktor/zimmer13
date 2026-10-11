class_name Lamp
extends StaticBody3D
## Decken- oder Wandlampe mit Glühbirne (Spielkonzept 7.3). Gehört zu einem Raum und
## wird über dessen Lichtschalter geschaltet. Die Birne lässt sich herausdrehen und
## woanders einschrauben – fehlt sie, bleibt die Lampe dunkel und das Monster kommt.
## Birnen brennen selten durch: bei starkem Flackern oder wenn das Monster nahe ist.

enum Style { CEILING, WALL }

## Durchbrenn-Chance je Sekunde (geringe Wahrscheinlichkeit)
const BREAK_PER_FLICKER := 0.004     ## × Flackern² (Ankündigung, 0..1)
const BREAK_NEAR_MONSTER := 0.012    ## × Nähe (1 direkt daneben, 0 ab 6 m)
const MONSTER_RANGE := 6.0

var style := Style.CEILING
var room_id := ""
var energy := 1.0
var light_range := 6.0
var has_bulb := true
var bulb_broken := false
## Wackelkontakt einer von Anfang an defekten Birne: blitzt ab und zu auf.
var sparking := false
var switched_on := true

var light: FlickerLight
var _bulb: MeshInstance3D
var _bulb_material: ShaderMaterial
var _break_timer := 0.0


func setup(p_style: Style, p_room: String, p_energy: float, p_range: float, p_broken: bool) -> Lamp:
	style = p_style
	room_id = p_room
	energy = p_energy
	light_range = p_range
	bulb_broken = p_broken
	sparking = p_broken
	return self


func _ready() -> void:
	collision_layer = 4
	collision_mask = 0
	set_meta("interactable", self)
	add_to_group("lamp_fixtures")
	_bulb_material = Mat.psx(Color(1, 0.95, 0.8), "", 1.0, Color(1.0, 0.85, 0.6), 2.5, false)
	var bulb_pos := Vector3(0, -0.12, 0)
	if style == Style.CEILING:
		Geo.mesh(self, Geo.box(Vector3(0.45, 0.06, 0.45)), Mat.psx(Color(0.75, 0.7, 0.6)), Vector3.ZERO)
		Geo.mesh(self, Geo.cylinder(0.02, 0.06, 5), Mat.psx(Color(0.3, 0.28, 0.25)), Vector3(0, -0.06, 0))
	else:
		# Wandleuchte: Halter an der Wand (lokale +Z zeigt in den Raum), offener Schirm
		var brass := Mat.psx(Color(0.7, 0.55, 0.25))
		Geo.mesh(self, Geo.box(Vector3(0.12, 0.18, 0.03)), brass, Vector3(0, 0, 0.015))
		Geo.mesh(self, Geo.box(Vector3(0.03, 0.03, 0.16)), brass, Vector3(0, 0, 0.1))
		Geo.mesh(self, Geo.cylinder(0.09, 0.1, 8), Mat.psx(Color(0.85, 0.75, 0.55)), Vector3(0, 0.1, 0.18))
		bulb_pos = Vector3(0, 0.04, 0.18)
	_bulb = Geo.mesh(self, Geo.sphere(0.045, 0.1, 6, 3), _bulb_material, bulb_pos)
	Geo.add_box_shape(self, Vector3(0.35, 0.3, 0.35), bulb_pos * 0.5)
	light = FlickerLight.new()
	light.position = bulb_pos + (Vector3(0, -0.13, 0) if style == Style.CEILING else Vector3(0, 0, 0.12))
	light.base_energy = energy
	light.omni_range = light_range
	light.light_color = Color(1.0, 0.8, 0.55)
	light.shadow_enabled = true
	# Viele Zimmer → weit entfernte Lampen und ihre Schatten ausblenden (spart Leistung)
	light.distance_fade_enabled = true
	light.distance_fade_begin = 26.0
	light.distance_fade_length = 6.0
	light.distance_fade_shadow = 16.0
	light.lamp_material = _bulb_material
	light.add_to_group("lamps")
	add_child(light)
	_break_timer = randf()
	apply_state()


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


func owner_guest() -> Guest:
	if Game.social == null:
		return null
	for guest in Game.social.guests:
		if guest.home["no"] == room_id and not guest.dead:
			return guest
	return null


func get_prompt(player: Player) -> String:
	if has_bulb:
		if player.held:
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
		if player.held:
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
