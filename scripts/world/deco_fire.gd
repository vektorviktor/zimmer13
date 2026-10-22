class_name DecoFire
extends StaticBody3D
## Brennende Deko (Spielkonzept 5.11): Nur leichte Deko fängt Feuer – Laub, Spinnweben, Lakengespenster, Fledermäuse,
## Plastikspinnen, Hexenbesen, Bettlaken; Möbel und das Hotel nie. Angezündet von einer brennenden Kerze, die ein Kind
## vor eine Tür wirft (Item._shatter_candle), springt es auf leichte Deko daneben über. Die Deko lodert ein paar
## Sekunden (Flammen, Licht, Knistern als Lärm) und ist dann weg, zurück bleibt Ruß. Brennend zählt sie nicht als Deko,
## aber als Licht. Der Spieler kann das Feuer austreten [E] – die Deko bleibt angesengt (halbe Stärke).
## Ein eigener Körper über der Deko fängt den Blick des Spielers ab. Nicht gespeichert (brennt nur Sekunden).

const FLAMMABLE := [Item.Kind.LEAVES, Item.Kind.COBWEB, Item.Kind.SHEET_GHOST, Item.Kind.BAT_GARLAND, Item.Kind.SPIDER,
	Item.Kind.BROOM, Item.Kind.BED_SHEET]
## Anzünden: so weit (waagerecht) von der Kerze, auch Hängendes bis zu dieser Höhe darüber
const IGNITE_RANGE := 1.0
const IGNITE_HEIGHT := 2.2
## Brenndauer (Spielzeit, s); Überspringen: so nah, so oft geprüft, mit dieser Chance je Prüfung
const BURN_TIME := Vector2(6.0, 10.0)
const SPREAD_RANGE := 1.1
const SPREAD_EVERY := 1.0
const SPREAD_CHANCE := 0.35
const NOISE_EVERY := 2.0
const SCORCHED := 0.5   ## gelöscht: so viel der Deko-Stärke bleibt

var item: Item
var _left := 8.0
var _spread := SPREAD_EVERY
var _noise := 0.0
var _strength := 0.0
var _light: OmniLight3D


## Kann diese Deko (noch) Feuer fangen?
static func can_burn(it: Item) -> bool:
	return is_instance_valid(it) and not it.is_queued_for_deletion() and it.kind in FLAMMABLE and not it.is_held \
		and not it.pocketed and not it.has_meta("fire")


## Zündet die Deko an. false = brennt nicht (falsche Art, in der Hand, brennt schon).
static func ignite(it: Item) -> bool:
	if not can_burn(it):
		return false
	var fire := DecoFire.new()
	fire.item = it
	it.set_meta("fire", fire)
	it.get_parent().add_child(fire)
	fire.global_position = it.global_position
	if Game.tracing:
		print("[Feuer] %s brennt" % it.display_name)
	return true


## Eine brennende Kerze schlägt bei `pos` auf: leichte Deko in der Nähe fängt Feuer. Gibt zurück, wie viel brennt.
static func ignite_near(pos: Vector3, source: Node) -> int:
	var count := 0
	for node in source.get_tree().get_nodes_in_group("items"):
		var it := node as Item
		if it == source or not can_burn(it):
			continue
		var d := it.global_position - pos
		if Vector2(d.x, d.z).length() <= IGNITE_RANGE and d.y > -0.3 and d.y < IGNITE_HEIGHT and ignite(it):
			count += 1
	return count


func _ready() -> void:
	collision_layer = Item.LAYER   # nur für den Blick des Spielers
	collision_mask = 0
	set_meta("interactable", self)
	_left = randf_range(BURN_TIME.x, BURN_TIME.y)
	_strength = item.deco_strength
	item.deco_strength = 0.0   # brennend schützt sie nicht
	Geo.add_box_shape(self, Vector3(0.5, 0.6, 0.5), Vector3(0, 0.25, 0))
	var flames := CPUParticles3D.new()
	flames.amount = 18
	flames.lifetime = 0.55
	flames.local_coords = false
	flames.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	flames.emission_sphere_radius = 0.15
	flames.direction = Vector3.UP
	flames.spread = 20.0
	flames.initial_velocity_min = 0.4
	flames.initial_velocity_max = 0.9
	flames.gravity = Vector3(0, 1.2, 0)
	flames.scale_amount_min = 0.6
	flames.scale_amount_max = 1.3
	var ramp := Gradient.new()
	ramp.set_color(0, Color(1.0, 0.85, 0.3))
	ramp.set_color(1, Color(0.9, 0.2, 0.02, 0.0))
	flames.color_ramp = ramp
	var quad := QuadMesh.new()
	quad.size = Vector2(0.09, 0.13)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	mat.vertex_color_use_as_albedo = true
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	quad.material = mat
	flames.mesh = quad
	add_child(flames)
	_light = OmniLight3D.new()
	_light.light_color = Color(1.0, 0.55, 0.2)
	_light.omni_range = 4.0
	_light.light_energy = 1.4
	_light.position = Vector3(0, 0.3, 0)
	_light.add_to_group("light_source")   # zählt als Licht (MonsterDirector.light_at)
	add_child(_light)


func get_prompt(_player: Player) -> String:
	return "%s brennt – austreten [E]" % item.display_name if is_instance_valid(item) else ""


## Ausgetreten: Die Deko bleibt angesengt (halbe Stärke).
func interact(_player: Player) -> void:
	if not is_instance_valid(item):
		return
	item.deco_strength = _strength * SCORCHED
	if not item.display_name.ends_with("(angesengt)"):
		item.display_name += " (angesengt)"
	Game.noise("drop", global_position, Game.player)
	Game.say("Du trittst das Feuer aus.", 2.0)
	_end()


func _process(delta: float) -> void:
	if not is_instance_valid(item) or item.is_queued_for_deletion():
		queue_free()
		return
	if item.is_held or item.pocketed:   # aufgehoben (Gast): erstickt
		item.deco_strength = _strength * SCORCHED
		_end()
		return
	global_position = item.global_position
	_light.light_energy = 1.2 + randf_range(-0.35, 0.35)
	_noise -= delta
	if _noise <= 0.0:
		_noise = NOISE_EVERY
		Game.noise("fire", global_position, item)
	_spread -= delta
	if _spread <= 0.0:
		_spread = SPREAD_EVERY
		for node in get_tree().get_nodes_in_group("items"):
			var other := node as Item
			if other != item and can_burn(other) and other.global_position.distance_to(item.global_position) < SPREAD_RANGE \
					and randf() < SPREAD_CHANCE:
				ignite(other)
	_left -= delta
	if _left <= 0.0:
		_burn_down()


## Abgebrannt: weg, Ruß bleibt am Boden darunter.
func _burn_down() -> void:
	if Game.traces:
		Game.traces.add_guest_drop("soot", item.global_position)
	if Game.player and Game.player.global_position.distance_to(item.global_position) < 10.0:
		Game.caption("[Etwas ist verbrannt]")
	if Game.tracing:
		print("[Feuer] %s ist abgebrannt" % item.display_name)
	item.queue_free()
	queue_free()


func _end() -> void:
	if is_instance_valid(item):
		item.remove_meta("fire")
	queue_free()
