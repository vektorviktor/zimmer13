class_name ResourceSpot
extends StaticBody3D
## Stelle, an der man Material bekommt: Laubhaufen unter Bäumen, Spinnweben in
## dunklen Ecken, Kerzenvorrat in der Küche, Lakengespenster in der Wäschekiste, Lichterketten
## in der Dekokiste (Spielkonzept 5.6), alte Deko im Keller (5.7). Begrenzter Vorrat, wächst langsam nach.
## Mit `pool` gibt es abwechselnd verschiedene Dinge (Dekokiste, alte Deko); `kind` bestimmt nur das Aussehen.
## Spinnweben: lokale +Z zeigt von der Wand weg.

var kind: Item.Kind = Item.Kind.LEAVES
var label := ""
var uses := 3
var max_uses := 3
var regen_time := 90.0
var pool: Array = []

var _timer := 0.0
var _visual: Node3D


func setup(p_kind: Item.Kind, p_label: String, p_max_uses: int, p_regen_time: float) -> ResourceSpot:
	kind = p_kind
	label = p_label
	max_uses = p_max_uses
	uses = p_max_uses
	regen_time = p_regen_time
	return self


## Kiste mit gemischtem Inhalt: Jedes Mal etwas anderes aus `kinds`.
func with_pool(kinds: Array) -> ResourceSpot:
	pool = kinds
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
		Item.Kind.SHEET_GHOST:
			# Wäschekiste: ein Laken hängt heraus, ein aufgemaltes Auge schaut hervor
			var sheet := Geo.mesh(_visual, Geo.box(Vector3(0.36, 0.05, 0.26)), Mat.psx(Color(0.96, 0.95, 0.9)), Vector3(0, 0.025, 0))
			sheet.rotation.y = 0.15
			Geo.mesh(_visual, Geo.sphere(0.025, 0.05, 6, 3), Mat.psx(Color(0.06, 0.05, 0.06)), Vector3(0.06, 0.05, 0.03))
			Geo.add_box_shape(self, Vector3(0.6, 0.3, 0.5), Vector3(0, 0.1, 0))
		Item.Kind.LIGHT_STRING:
			# Pappkarton mit alter Halloween-Deko, obenauf eine aufgerollte Lichterkette
			Geo.mesh(self, Geo.box(Vector3(0.5, 0.32, 0.38)), Mat.psx(Color(0.55, 0.4, 0.25)), Vector3(0, 0.16, 0))
			var wire := Mat.psx(Color(0.12, 0.22, 0.1))
			Geo.mesh(_visual, Geo.cylinder(0.13, 0.02, 10), wire, Vector3(0, 0.33, 0))
			for i in 6:
				var a := i * TAU / 6.0
				Geo.mesh(_visual, Geo.sphere(0.02, 0.04, 5, 2), Mat.psx(Item.STRING_COLORS[i % 4]), Vector3(cos(a) * 0.11, 0.35, sin(a) * 0.11))
			Geo.add_box_shape(self, Vector3(0.5, 0.38, 0.38), Vector3(0, 0.19, 0))
		Item.Kind.BROOM:
			# Holzkiste mit alter Halloween-Deko im Keller: ein Besenstiel ragt heraus, ein Totenkopf grinst
			Geo.mesh(self, Geo.box(Vector3(0.55, 0.3, 0.4)), Mat.psx(Color(0.3, 0.2, 0.12)), Vector3(0, 0.15, 0))
			var stick := Geo.mesh(_visual, Geo.cylinder(0.018, 0.9, 6), Mat.psx(Color(0.32, 0.2, 0.1)), Vector3(0.12, 0.6, 0))
			stick.rotation.z = -0.35
			var skull := Geo.mesh(_visual, Geo.sphere(0.07, 0.14, 8, 4), Mat.psx(Color(0.88, 0.84, 0.72)), Vector3(-0.12, 0.36, 0.05))
			skull.scale = Vector3(1.0, 0.95, 1.1)
			Geo.add_box_shape(self, Vector3(0.55, 0.5, 0.4), Vector3(0, 0.25, 0))
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
	return Item.create(pool.pick_random() if not pool.is_empty() else kind)


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
