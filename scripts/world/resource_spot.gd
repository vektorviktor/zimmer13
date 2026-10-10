class_name ResourceSpot
extends StaticBody3D
## Stelle, an der man Material bekommt: Laubhaufen unter Bäumen, Spinnweben in
## dunklen Ecken, Kerzenvorrat in der Küche. Begrenzter Vorrat, wächst langsam nach.
## Spinnweben: lokale +Z zeigt von der Wand weg.

var kind: Item.Kind = Item.Kind.LEAVES
var label := ""
var uses := 3
var max_uses := 3
var regen_time := 90.0

var _timer := 0.0
var _visual: Node3D


func setup(p_kind: Item.Kind, p_label: String, p_max_uses: int, p_regen_time: float) -> ResourceSpot:
	kind = p_kind
	label = p_label
	max_uses = p_max_uses
	uses = p_max_uses
	regen_time = p_regen_time
	return self


func _ready() -> void:
	collision_layer = 4
	collision_mask = 0
	set_meta("interactable", self)
	add_to_group("resource_spots")
	_visual = Node3D.new()
	add_child(_visual)
	match kind:
		Item.Kind.LEAVES:
			var rng := RandomNumberGenerator.new()
			var colors: Array[Color] = [Color(0.75, 0.35, 0.08), Color(0.6, 0.15, 0.05), Color(0.8, 0.55, 0.1), Color(0.45, 0.25, 0.08)]
			for i in 30:
				var r := rng.randf() * 0.45
				var a := rng.randf() * TAU
				var leaf := Geo.mesh(_visual, Geo.box(Vector3(0.1, 0.015, 0.07)), Mat.psx(colors[i % 4]),
					Vector3(cos(a) * r, 0.02 + (0.45 - r) * 0.35 * rng.randf(), sin(a) * r))
				leaf.rotation = Vector3(rng.randf() * 0.5, rng.randf() * TAU, 0)
			Geo.add_box_shape(self, Vector3(0.9, 0.25, 0.9), Vector3(0, 0.12, 0))
		Item.Kind.COBWEB:
			var plane := PlaneMesh.new()
			plane.size = Vector2(0.9, 0.9)
			var web := Geo.mesh(_visual, plane, Mat.cobweb(), Vector3.ZERO)
			web.rotation.x = PI / 2.0
			Geo.add_box_shape(self, Vector3(0.6, 0.6, 0.1), Vector3.ZERO)
		Item.Kind.CANDLE:
			Geo.mesh(_visual, Geo.box(Vector3(0.32, 0.08, 0.2)), Mat.psx(Color(0.4, 0.28, 0.16)), Vector3(0, 0.04, 0))
			for i in 3:
				Geo.mesh(_visual, Geo.cylinder(0.03, 0.14, 6), Mat.psx(Color(0.92, 0.88, 0.75)), Vector3(-0.09 + i * 0.09, 0.15, 0))
			Geo.add_box_shape(self, Vector3(0.34, 0.24, 0.22), Vector3(0, 0.12, 0))
	_update_visual()


func _process(delta: float) -> void:
	if uses >= max_uses:
		return
	_timer += delta
	if _timer >= regen_time:
		_timer = 0.0
		uses += 1
		_update_visual()


## Gibt ein neues Item zurück (noch nicht in der Szene) oder null, wenn leer.
func take() -> Item:
	if uses <= 0:
		return null
	uses -= 1
	_update_visual()
	return Item.create(kind)


func get_prompt(player: Player) -> String:
	if uses <= 0:
		return "%s – gerade nichts zu holen" % label
	if player.held:
		return "Hände voll"
	return "%s nehmen [E]" % label


func interact(player: Player) -> void:
	if uses <= 0 or player.held:
		return
	player.receive_item(take())


func _update_visual() -> void:
	_visual.visible = uses > 0
	if kind == Item.Kind.LEAVES:
		_visual.scale = Vector3.ONE * lerpf(0.5, 1.0, float(uses) / max_uses)
