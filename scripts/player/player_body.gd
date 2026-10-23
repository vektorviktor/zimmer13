class_name PlayerBody
extends Node3D
## Körper des Spielers (Spielkonzept 3.9): ein GuestBody mit dem Aussehen aus der Charaktererstellung. Die Spielerkamera
## sieht ihn nicht (Sichtebene LAYER fehlt in ihrer cull_mask) – zu sehen ist er nur im Spiegel (Mirror) und als
## Schatten. Godot rechnet Schatten nur für Sichtbares, darum wirft eine zweite Kopie jedes Netzes am selben Skelett
## den Schatten (SHADOWS_ONLY auf SHADOW_LAYER, den alle Kameras sehen); das sichtbare Netz wirft keinen. Er folgt dem Spieler: Gehen und Rennen aus der Animation, gehockt und im Sitzen mit angewinkelten Beinen,
## der Kopf neigt sich mit dem Blick, mit etwas in der Hand ist der rechte Arm vorn. Im Versteck und im Bett ist er weg.
## Lichter, die der Spieler trägt (Taschenlampe, Kerze), werfen seinen Schatten nicht (Light3D.shadow_caster_mask).
##
## Aussehen (look, gespeichert): body (Grundkörper aus GuestBody.BODIES, nur Erwachsene), height (m), slim und fit
## (Anteile der Ecken „schlank“ und „definiert“ im Dreieck, der Rest ist „kräftig“), skin, hair, coat, pants (Farben
## als HTML-Text).

const LAYER := 1 << 18
const SHADOW_LAYER := 1 << 17
const HEIGHT_RANGE := Vector2(1.45, 2.0)
## Körperbau-Dreieck: „schlank“ zieht build bis hierhin, „kräftig“ bis 1; „definiert“ breitet die Schultern
const SLIM_BUILD := -0.7
const FIT_WIDTH := 0.07
const HEAVY_WIDTH := 0.05
const SLIM_WIDTH := 0.06

var look: Dictionary = {}
var _body: GuestBody
var _arm_l := Node3D.new()
var _arm_r := Node3D.new()
var _costume: Costume
var _lit := {}   ## Lichter in der Hand, deren Schattenmaske gerade ohne LAYER ist


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS   # auch in der Charaktererstellung (Spiel pausiert)
	add_child(_arm_l)
	add_child(_arm_r)


## Ohne Charaktererstellung (Debug-Start) sieht man so aus: Mann mittleren Alters, 1,80 m, Mitte des Dreiecks.
static func default_look() -> Dictionary:
	return {
		"body": "man", "height": 1.8, "slim": 1.0 / 3.0, "fit": 1.0 / 3.0,
		"skin": GuestGenerator.SKIN[1].to_html(false), "hair": GuestGenerator.HAIR[3].to_html(false),
		"coat": GuestGenerator.COATS[4].to_html(false), "pants": GuestGenerator.PANTS[6].to_html(false),
	}


## Erwachsene Grundkörper in der Reihenfolge der Auswahl (Geschlecht, dann Alter)
static func adult_bodies() -> Array[String]:
	var out: Array[String] = []
	for sex in ["f", "m"]:
		for gen in GuestBody.GENERATIONS:
			for key in GuestBody.BODIES:
				var info: Dictionary = GuestBody.BODIES[key]
				if info["sex"] == sex and info.get("gen", "") == gen and not info.has("age"):
					out.append(key)
	return out


## Aussehen übernehmen und die Figur neu bauen.
func apply(new_look: Dictionary) -> void:
	look = default_look()
	look.merge(new_look, true)
	if not GuestBody.BODIES.has(String(look["body"])) or GuestBody.BODIES[look["body"]].has("age"):
		look["body"] = default_look()["body"]
	look["height"] = clampf(float(look["height"]), HEIGHT_RANGE.x, HEIGHT_RANGE.y)
	if _body:
		_body.queue_free()
	_body = GuestBody.new()
	_body.setup(look["body"], profile_of(look))
	add_child(_body)
	_set_layers(_body)
	_costume_changed()


## Profil für GuestBody aus dem Aussehen: Dreieck → Formschlüssel und Schulterbreite.
static func profile_of(l: Dictionary) -> Dictionary:
	var slim := clampf(float(l["slim"]), 0.0, 1.0)
	var fit_w := clampf(float(l["fit"]), 0.0, 1.0 - slim)
	var heavy := 1.0 - slim - fit_w
	var fit := clampf((3.0 * fit_w - 1.0) / 2.0, 0.0, 1.0)   # Mitte des Dreiecks = Grundkörper
	var info: Dictionary = GuestBody.BODIES[l["body"]]
	var width := 1.0 + FIT_WIDTH * fit + HEAVY_WIDTH * heavy - SLIM_WIDTH * slim
	return {
		"coat": Color.html(l["coat"]), "pants": Color.html(l["pants"]), "hair": Color.html(l["hair"]),
		"skin": Color.html(l["skin"]), "build": heavy + SLIM_BUILD * slim, "fit": fit,
		"height_cm": float(l["height"]) * 100.0, "width_cm": float(info["width"]) * float(l["height"]) / float(info["height"]) * width * 100.0,
	}


## Netze nur für den Spiegel, daneben je eine Kopie, die nur den Schatten wirft
func _set_layers(node: Node) -> void:
	for v in node.find_children("*", "VisualInstance3D", true, false):
		(v as VisualInstance3D).layers = LAYER
		var mesh := v as MeshInstance3D
		if mesh == null or mesh.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_OFF:
			continue
		var caster := mesh.duplicate() as MeshInstance3D
		caster.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY
		caster.layers = SHADOW_LAYER
		mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mesh.add_sibling(caster)


## Bettlaken übergeworfen (Spielkonzept 5.9): das Laken des Kostüms, Kopf kleiner
func _costume_changed() -> void:
	var p := get_parent() as Player
	var want := p != null and p.disguised
	if want == (_costume != null) or _body == null:
		return
	_body.head_shrink = 0.6 if want else 1.0
	if _costume:
		_costume.queue_free()
		_costume = null
	if want:
		_costume = Costume.new()
		var height := float(look["height"])
		_costume.setup("sheet", height, 0.2, clampf(height / 1.8, 0.8, 1.15))
		add_child(_costume)
		_set_layers(_costume)


func _process(delta: float) -> void:
	var p := get_parent() as Player
	if _body == null or p == null:
		return
	_costume_changed()
	visible = not p.dead and p.hiding == null and not p.sleeping
	_shadow_through_held(p)
	if not visible:
		return
	var sitting := p.seat != null or p.crouching
	position.y = -_body.sit_drop() if sitting else 0.0
	var speed := 0.0 if get_tree().paused else Vector2(p.velocity.x, p.velocity.z).length()
	# Etwas in der Hand: rechter Arm vorn; Karte oder Kompass: der linke
	_arm_r.rotation = Vector3(-1.0, 0, 0) if p.held or p.carried_cat else Vector3.ZERO
	_arm_l.rotation = Vector3(-1.3, 0, 0.2) if p.inspecting else (Vector3(-1.0, 0, 0) if p.carried_cat else Vector3.ZERO)
	var arms_free := _arm_r.rotation == Vector3.ZERO and _arm_l.rotation == Vector3.ZERO and _costume == null
	_body.head_pitch = p.head.rotation.x
	_body.animate(delta, speed, p.running, [_arm_l, _arm_r], arms_free, sitting)


## Lichter in der Hand werfen den eigenen Schatten nicht – sonst stünde der Kopf vor der Taschenlampe.
func _shadow_through_held(p: Player) -> void:
	var now := {}
	if p.held:
		for light in p.held.find_children("*", "Light3D", true, false):
			now[light] = true
	for light in _lit.keys():
		if is_instance_valid(light) and not now.has(light):
			(light as Light3D).shadow_caster_mask = 0xFFFFFFFF
	for light: Light3D in now:
		light.shadow_caster_mask = 0xFFFFFFFF & ~SHADOW_LAYER
	_lit = now
