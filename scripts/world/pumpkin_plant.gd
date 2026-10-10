class_name PumpkinPlant
extends StaticBody3D
## Kürbispflanze im Hotelgarten. Wächst in Stufen (Spielkonzept 5.4) und kann reif
## geerntet werden – vom Spieler und von Gästen. Danach wächst ein neuer Kürbis nach.

const STAGE_TIME := 75.0   ## Sekunden je Wachstumsstufe → ca. 4 Minuten bis reif
const RIPE := 3

var stage := 0

var _timer := 0.0
var _fruit: MeshInstance3D
var _materials: Array[ShaderMaterial] = []


func setup(start_stage: int) -> PumpkinPlant:
	stage = clampi(start_stage, 0, RIPE)
	return self


func _ready() -> void:
	collision_layer = 4
	collision_mask = 0
	set_meta("interactable", self)
	add_to_group("pumpkin_plants")
	var leaf_mat := Mat.psx(Color(0.18, 0.32, 0.1))
	for i in 4:
		var leaf := Geo.mesh(self, Geo.box(Vector3(0.4, 0.03, 0.18)), leaf_mat, Vector3(0, 0.03 + i * 0.012, 0))
		leaf.rotation.y = i * PI / 4.0 + 0.3
	for c in [Color(0.3, 0.45, 0.12), Color(0.55, 0.45, 0.1), Color(0.75, 0.42, 0.08), Color(0.85, 0.42, 0.08)]:
		_materials.append(Mat.psx(c))
	_fruit = Geo.mesh(self, Geo.sphere(0.21, 0.32, 9, 5), _materials[0], Vector3.ZERO)
	Geo.add_box_shape(self, Vector3(0.45, 0.3, 0.45), Vector3(0, 0.15, 0))
	_timer = randf() * STAGE_TIME
	_update_visual()


func _process(delta: float) -> void:
	if stage >= RIPE:
		return
	_timer += delta
	if _timer >= STAGE_TIME:
		_timer = 0.0
		stage += 1
		_update_visual()


func is_ripe() -> bool:
	return stage >= RIPE


## Gibt einen Kürbis zurück (noch nicht in der Szene) oder null.
func harvest() -> Item:
	if not is_ripe():
		return null
	stage = 0
	_timer = 0.0
	_update_visual()
	return Item.create(Item.Kind.PUMPKIN)


func get_prompt(player: Player) -> String:
	if not is_ripe():
		return "Kürbis wächst noch …"
	if player.held:
		return "Hände voll"
	return "Kürbis ernten [E]"


func interact(player: Player) -> void:
	if not is_ripe() or player.held:
		return
	player.receive_item(harvest())
	Game.play_sound("thud", 0.5)


func _update_visual() -> void:
	var scales: Array[float] = [0.0, 0.35, 0.65, 1.0]
	var s := scales[stage]
	_fruit.visible = stage > 0
	_fruit.scale = Vector3.ONE * maxf(s, 0.01)
	_fruit.position = Vector3(0.08, 0.16 * s, 0.05)
	_fruit.material_override = _materials[stage]
