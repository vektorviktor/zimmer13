class_name LightSwitch
extends StaticBody3D
## Lichtschalter – meist einer pro Raum bzw. Flurabschnitt (Spielkonzept 7.3), mehrere im selben
## Raum bilden eine Wechselschaltung. Schaltet alle Decken- und Wandlampen des Raums. Licht aus =
## das Monster kommt (4.4).
## Lokale +Z zeigt von der Wand in den Raum.

var room_id := ""
var room_label := ""
var on := true

var _toggle: MeshInstance3D


func setup(p_room: String, p_label: String) -> LightSwitch:
	room_id = p_room
	room_label = p_label
	return self


func _ready() -> void:
	collision_layer = 4
	collision_mask = 0
	set_meta("interactable", self)
	add_to_group("light_switches")
	Geo.mesh(self, Geo.box(Vector3(0.08, 0.12, 0.02)), Mat.psx(Color(0.85, 0.8, 0.7)), Vector3(0, 0, 0.01))
	_toggle = Geo.mesh(self, Geo.box(Vector3(0.025, 0.045, 0.025)), Mat.psx(Color(0.6, 0.5, 0.3)), Vector3(0, 0, 0.03))
	Geo.add_box_shape(self, Vector3(0.2, 0.25, 0.12), Vector3(0, 0, 0.04))
	_update_visual()


static func find(tree: SceneTree, p_room: String) -> LightSwitch:
	for node in tree.get_nodes_in_group("light_switches"):
		var sw := node as LightSwitch
		if sw.room_id == p_room:
			return sw
	return null


## loading = true: nur Zustand setzen (Spielstand laden), keine Folgen.
## Mehrere Schalter im selben Raum sind eine Wechselschaltung: alle springen mit um, Lärm und
## Monster kommen nur vom betätigten.
func set_on(value: bool, loading: bool = false) -> void:
	if on == value:
		return
	for node in get_tree().get_nodes_in_group("light_switches"):
		var sw := node as LightSwitch
		if sw.room_id == room_id:
			sw.on = value
			sw._update_visual()
	for node in get_tree().get_nodes_in_group("lamp_fixtures"):
		var lamp := node as Lamp
		if lamp.room_id == room_id:
			lamp.switched_on = on
			lamp.apply_state()
	if loading:
		return
	Game.noise("switch", global_position)
	if not on and Game.director:
		Game.director.on_lights_off(global_position)


func get_prompt(_player: Player) -> String:
	return ("Licht ausschalten [E]" if on else "Licht einschalten [E]") + "  – " + room_label


func interact(_player: Player) -> void:
	set_on(not on)


func _update_visual() -> void:
	if _toggle:
		_toggle.rotation.x = -0.35 if on else 0.35


func save_state() -> Dictionary:
	return {"on": on}


func load_state(data: Dictionary) -> void:
	on = not bool(data.get("on", true))
	set_on(bool(data.get("on", true)), true)
