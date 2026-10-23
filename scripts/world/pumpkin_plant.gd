class_name PumpkinPlant
extends StaticBody3D
## Kürbispflanze im Hotelgarten. Wächst in Stufen (Spielkonzept 5.4) und kann reif
## geerntet werden – vom Spieler und von Gästen. Danach wächst ein neuer Kürbis nach.
## Oft hängt ein Zierkürbis mit an der Ranke – er fällt beim Ernten daneben (Spielkonzept 5.6).
## Jede Pflanze trägt eine Sorte (PumpkinKinds, Spielkonzept 5.8) – aus dem Gebäudeplan: Aussehen der Frucht und
## Wachstum (grow = Sekunden bis reif). Der Riesenkürbis landet beim Ernten neben dem Beet, nicht in der Hand – tragen
## lässt er sich danach trotzdem, nur langsam (Item.carry_speed).

const RIPE := 3
## Frost (Spielkonzept 5.10): ab diesem Tag wachsen große Sorten nicht mehr nach – die letzte Woche wird knapp
const FROST_DAY := 25
const MINI_CHANCE := 0.5   ## Zierkürbis beim Ernten

var stage := 0
var variety := PumpkinKinds.DEFAULT

var _timer := 0.0
var _fruit: MeshInstance3D
var _materials: Array[ShaderMaterial] = []


func setup(start_stage: int, p_variety: String = PumpkinKinds.DEFAULT) -> PumpkinPlant:
	stage = clampi(start_stage, 0, RIPE)
	variety = p_variety if PumpkinKinds.DATA.has(p_variety) else PumpkinKinds.DEFAULT
	return self


## Sekunden je Wachstumsstufe (je Sorte)
func stage_time() -> float:
	return float(PumpkinKinds.data(variety)["grow"]) / RIPE


func is_giant() -> bool:
	return variety == "giant"


func _ready() -> void:
	collision_layer = 4
	collision_mask = 0
	set_meta("interactable", self)
	add_to_group("pumpkin_plants")
	var leaf_mat := Mat.psx(Color(0.18, 0.32, 0.1))
	for i in 4:
		var leaf := Geo.mesh(self, Geo.box(Vector3(0.4, 0.03, 0.18)), leaf_mat, Vector3(0, 0.03 + i * 0.012, 0))
		leaf.rotation.y = i * PI / 4.0 + 0.3
	# Frucht: erst grün, dann zur Farbe der Sorte; Form wie die Sorte (Maße aus PumpkinKinds)
	var d := PumpkinKinds.data(variety)
	var ripe: Color = d["color"]
	for c in [Color(0.3, 0.45, 0.12), Color(0.3, 0.45, 0.12).lerp(ripe, 0.35), Color(0.3, 0.45, 0.12).lerp(ripe, 0.75), ripe]:
		_materials.append(Mat.psx(c))
	var sz: Vector3 = d["size"]
	_fruit = Geo.mesh(self, Geo.sphere(sz.x / 2.0, sz.y, 9, 5), _materials[0], Vector3.ZERO)
	if is_giant():
		leaf_mat = Mat.psx(Color(0.16, 0.3, 0.09))
		for i in 3:
			var big_leaf := Geo.mesh(self, Geo.box(Vector3(0.9, 0.03, 0.4)), leaf_mat, Vector3(0, 0.05 + i * 0.012, 0))
			big_leaf.rotation.y = i * PI / 3.0
	var footprint := maxf(0.45, sz.x + 0.05)
	Geo.add_box_shape(self, Vector3(footprint, 0.3, footprint), Vector3(0, 0.15, 0))
	_timer = randf() * stage_time()
	_update_visual()


func _process(delta: float) -> void:
	if stage >= RIPE or frozen():
		return
	_timer += delta
	if _timer >= stage_time():
		_timer = 0.0
		stage += 1
		_update_visual()


## Große Sorte nach dem Frost: trägt nicht mehr (ein schon reifer Kürbis lässt sich noch ernten).
func frozen() -> bool:
	return bool(PumpkinKinds.data(variety)["large"]) and Calendar.today() >= FROST_DAY


func is_ripe() -> bool:
	return stage >= RIPE


## Gibt einen Kürbis zurück (noch nicht in der Szene) oder null.
func harvest() -> Item:
	if not is_ripe():
		return null
	stage = 0
	_timer = 0.0
	_update_visual()
	if randf() < MINI_CHANCE and _minis_near() < 2:
		var mini := Item.create(Item.Kind.MINI_PUMPKIN)
		get_parent().add_child(mini)
		mini.global_position = global_position + Vector3(randf_range(-0.35, 0.35), 0.05, randf_range(0.25, 0.4))
	var pumpkin := Item.create(Item.Kind.PUMPKIN, variety)
	if is_giant():
		# Zu schwer, um ihn einfach zu pflücken: Er rollt neben das Beet
		get_parent().add_child(pumpkin)
		pumpkin.global_position = global_position + Vector3(0, 0.05, 0.8)
		pumpkin.rotation.y = randf() * TAU
		return null
	return pumpkin


## Liegen schon Zierkürbisse am Beet? (Sonst sammeln sie sich mit der Zeit im Garten.)
func _minis_near() -> int:
	var count := 0
	for node in get_tree().get_nodes_in_group("items"):
		var item := node as Item
		if item.kind == Item.Kind.MINI_PUMPKIN and not item.is_held and item.global_position.distance_to(global_position) < 2.5:
			count += 1
	return count


func get_prompt(player: Player) -> String:
	var label: String = "Kürbis" if variety == PumpkinKinds.DEFAULT else String(PumpkinKinds.data(variety)["name"])
	if not is_ripe():
		return ("%s – erfroren, trägt nicht mehr" if frozen() else "%s wächst noch …") % label
	if is_giant():
		return "%s abschneiden [E]" % label
	if player.held:
		return "Hände voll"
	return "%s ernten [E]" % label


func interact(player: Player) -> void:
	if not is_ripe():
		return
	if is_giant():
		harvest()   # rollt neben das Beet
		Game.noise("drop_heavy", global_position, player)
		Game.say("Mit einem dumpfen Schlag rollt der Riesenkürbis vom Beet.", 3.0)
		return
	if player.held:
		return
	player.receive_item(harvest())
	Game.noise("harvest", global_position, player)


func _update_visual() -> void:
	var scales: Array[float] = [0.0, 0.35, 0.65, 1.0]
	var s := scales[stage]
	var sz: Vector3 = PumpkinKinds.data(variety)["size"]
	_fruit.visible = stage > 0
	_fruit.scale = Vector3.ONE * maxf(s, 0.01)
	_fruit.position = Vector3(0.08 if not is_giant() else 0.0, sz.y / 2.0 * s, 0.05)
	_fruit.material_override = _materials[stage]
