class_name HideSpot
extends StaticBody3D
## Versteck (Kleiderschrank oder Bett), Mechanik angelehnt an Roblox „Doors“.
## Lokale +Z-Achse zeigt aus dem Versteck heraus. Spieler und (später) Gäste
## nutzen dieselbe Schnittstelle; „occupant“ reserviert den Platz.

enum Type { WARDROBE, BED }

var type := Type.WARDROBE
var occupant: Node = null
## Das Monster hat gesehen, wie jemand hineingegangen ist → es holt ihn.
var seen_entering := false
## Vom Monster geprüft (Spur): Schranktür steht offen / Bett ist zerwühlt.
var checked := false
var view_point: Marker3D
var exit_point: Marker3D
var check_point: Marker3D

var _visual: Node3D
var _leaves: Array[Node3D] = []
var _blanket: MeshInstance3D


func setup(p_type: Type) -> HideSpot:
	type = p_type
	return self


func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	set_meta("interactable", self)
	add_to_group("hide_spots")
	_visual = Node3D.new()
	add_child(_visual)
	view_point = _marker()
	exit_point = _marker()
	check_point = _marker()
	if type == Type.WARDROBE:
		_build_wardrobe()
	else:
		_build_bed()


func get_prompt(player: Player) -> String:
	if occupant != null and occupant != player:
		return "Besetzt"
	if checked and type == HideSpot.Type.BED:
		return "Das Bett ist zerwühlt … Unters Bett kriechen [E]"
	return "Im Schrank verstecken [E]" if type == Type.WARDROBE else "Unters Bett kriechen [E]"


func interact(player: Player) -> void:
	if occupant == null:
		player.enter_hide(self)


func on_enter() -> void:
	set_checked(false)
	_set_leaves(deg_to_rad(7.0))
	Game.play_sound("creak", 0.35)


func on_exit() -> void:
	_set_leaves(0.0)
	seen_entering = false


## Spur „geprüftes Versteck“: Schranktüren bleiben halb offen, das Bett zerwühlt.
func set_checked(value: bool) -> void:
	checked = value
	if type == Type.WARDROBE:
		_set_leaves(deg_to_rad(38.0) if value else 0.0)
	elif _blanket:
		_blanket.position = Vector3(0.1, 0.56, 0.12) if value else Vector3(0.3, 0.54, 0)
		_blanket.rotation = Vector3(0.12, 0.35, 0.08) if value else Vector3.ZERO


func save_state() -> Dictionary:
	return {"checked": checked}


func load_state(data: Dictionary) -> void:
	if bool(data.get("checked", false)) != checked:
		set_checked(bool(data.get("checked", false)))


## Das Monster reißt das Versteck auf.
func rip_open() -> void:
	Game.play_sound("bang", 1.0)
	var tw := create_tween().set_parallel(true)
	if type == Type.WARDROBE:
		for i in _leaves.size():
			var side := -1.0 if i == 0 else 1.0
			tw.tween_property(_leaves[i], "rotation:y", side * deg_to_rad(115.0), 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	else:
		tw.tween_property(_visual, "position", Vector3(0, 0.3, 0.35), 0.15).set_trans(Tween.TRANS_BACK)


func _set_leaves(angle: float) -> void:
	for i in _leaves.size():
		var side := -1.0 if i == 0 else 1.0
		create_tween().tween_property(_leaves[i], "rotation:y", side * angle, 0.2)


func _marker() -> Marker3D:
	var m := Marker3D.new()
	m.rotation.y = PI   # Blickrichtung (−Z) zeigt nach lokal +Z, also aus dem Versteck heraus
	add_child(m)
	return m


func _build_wardrobe() -> void:
	var wood := Mat.psx(Color(0.32, 0.2, 0.12))
	var door_wood := Mat.psx(Color(0.36, 0.23, 0.13))
	var dark := Mat.psx(Color(0.06, 0.04, 0.03))
	var brass := Mat.psx(Color(0.8, 0.65, 0.25))
	Geo.mesh(_visual, Geo.box(Vector3(1.1, 2.1, 0.56)), wood, Vector3(0, 1.05, -0.02))
	Geo.mesh(_visual, Geo.box(Vector3(1.18, 0.08, 0.64)), wood, Vector3(0, 2.14, 0))
	for side in [-1.0, 1.0]:
		var pivot := Node3D.new()
		pivot.position = Vector3(side * 0.55, 0.05, 0.28)
		_visual.add_child(pivot)
		var x: float = -side * 0.26
		Geo.mesh(pivot, Geo.box(Vector3(0.52, 2.0, 0.03)), door_wood, Vector3(x, 1.0, 0))
		for i in 7:
			Geo.mesh(pivot, Geo.box(Vector3(0.36, 0.022, 0.036)), dark, Vector3(x, 1.25 + i * 0.075, 0.003))
		Geo.mesh(pivot, Geo.box(Vector3(0.025, 0.12, 0.05)), brass, Vector3(-side * 0.48, 1.05, 0.02))
		_leaves.append(pivot)
	Geo.add_box_shape(self, Vector3(1.1, 2.1, 0.6), Vector3(0, 1.05, 0))
	view_point.position = Vector3(0, 1.6, 0.05)
	exit_point.position = Vector3(0, 0, 0.85)
	check_point.position = Vector3(0, 0, 1.05)


func _build_bed() -> void:
	var wood := Mat.psx(Color(0.3, 0.18, 0.1))
	var sheet := Mat.psx(Color(0.55, 0.52, 0.48))
	var blanket := Mat.psx(Color(0.35, 0.08, 0.08))
	Geo.mesh(_visual, Geo.box(Vector3(2.05, 0.08, 1.45)), wood, Vector3(0, 0.33, 0))
	Geo.mesh(_visual, Geo.box(Vector3(2.0, 0.16, 1.4)), sheet, Vector3(0, 0.45, 0))
	_blanket = Geo.mesh(_visual, Geo.box(Vector3(1.3, 0.04, 1.44)), blanket, Vector3(0.3, 0.54, 0))
	Geo.mesh(_visual, Geo.box(Vector3(0.35, 0.1, 0.9)), sheet, Vector3(-0.75, 0.58, 0))
	Geo.mesh(_visual, Geo.box(Vector3(0.08, 1.0, 1.45)), wood, Vector3(-1.02, 0.5, 0))
	for x in [-0.95, 0.95]:
		for z in [-0.65, 0.65]:
			Geo.mesh(_visual, Geo.box(Vector3(0.07, 0.3, 0.07)), wood, Vector3(x, 0.15, z))
	Geo.add_box_shape(self, Vector3(2.05, 0.6, 1.45), Vector3(0, 0.3, 0))
	Geo.add_box_shape(self, Vector3(0.08, 1.0, 1.45), Vector3(-1.02, 0.5, 0))
	view_point.position = Vector3(0.2, 0.17, 0.15)
	exit_point.position = Vector3(0, 0, 1.25)
	check_point.position = Vector3(0, 0, 1.35)
