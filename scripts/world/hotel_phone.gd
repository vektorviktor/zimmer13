class_name HotelPhone
extends StaticBody3D
## Altes Wählscheibentelefon (Spielkonzept 4.14): eins in fast jedem Zimmer, der Hauptapparat
## steht an der Rezeption. Abnehmen, wählen, Hörer daneben legen – die Anrufe selbst
## verwaltet `PhoneCalls` (Game.phones). Lokale +Z zeigt zum Spieler (Wählscheibe vorn).

var room_id := ""           ## Zimmernummer oder "lobby" (Rezeption)
var off_hook := false       ## Hörer liegt daneben → besetzt, klingelt nicht
var ringing := false        ## klingelt gerade (setzt PhoneCalls)

var _handset: Node3D


func setup(p_room_id: String) -> HotelPhone:
	room_id = p_room_id
	return self


func is_main() -> bool:
	return room_id == "lobby"


func _ready() -> void:
	collision_layer = 4
	collision_mask = 0
	set_meta("interactable", self)
	add_to_group("phones")
	var black := Mat.psx(Color(0.08, 0.07, 0.07))
	Geo.mesh(self, Geo.box(Vector3(0.2, 0.07, 0.16)), black, Vector3(0, 0.035, 0))
	var dial := Geo.mesh(self, Geo.cylinder(0.05, 0.012, 10), Mat.psx(Color(0.75, 0.72, 0.62)), Vector3(0, 0.06, 0.04))
	dial.rotation.x = 0.5
	_handset = Node3D.new()
	add_child(_handset)
	Geo.mesh(_handset, Geo.box(Vector3(0.24, 0.035, 0.05)), black, Vector3(0, 0, 0))
	for side in [-1.0, 1.0]:
		Geo.mesh(_handset, Geo.box(Vector3(0.06, 0.04, 0.06)), black, Vector3(side * 0.1, -0.02, 0))
	Geo.add_box_shape(self, Vector3(0.24, 0.12, 0.2), Vector3(0, 0.06, 0))
	_update_handset()


## Hörer auf der Gabel oder daneben.
func set_off_hook(value: bool) -> void:
	off_hook = value
	if value:
		ringing = false
	_update_handset()


func _update_handset() -> void:
	if _handset == null:
		return
	if off_hook:
		_handset.position = Vector3(0.2, 0.025, 0.06)
		_handset.rotation = Vector3(0, 0.6, 0)
	else:
		_handset.position = Vector3(0, 0.1, -0.03)
		_handset.rotation = Vector3.ZERO


func _process(_delta: float) -> void:
	# Klingeln lässt den Hörer auf der Gabel zittern
	if _handset and not off_hook:
		_handset.position.y = 0.1 + (randf() * 0.006 if ringing else 0.0)


func get_prompt(_player: Player) -> String:
	if Game.phones == null:
		return ""
	if ringing:
		return "Das Telefon klingelt – abnehmen [E]"
	if off_hook:
		return "Der Hörer liegt daneben – auflegen [E]"
	return "Telefonieren [E]" + ("  (Haupttelefon mit Zimmerliste)" if is_main() else "")


func interact(player: Player) -> void:
	if Game.phones == null:
		return
	if ringing:
		Game.phones.answer(self)
	elif off_hook:
		set_off_hook(false)
		Game.noise("handset", global_position, player)
		Game.say("Du legst den Hörer auf.", 2.0)
	elif player.hands_blocked():
		Game.say("Mit vollen Händen kannst du nicht telefonieren.", 2.0)
	else:
		Game.phones.open_dial(self)


func save_state() -> Dictionary:
	return {"off_hook": off_hook}


func load_state(d: Dictionary) -> void:
	set_off_hook(bool(d.get("off_hook", false)))
