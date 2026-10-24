class_name KeyCabinet
extends StaticBody3D
## Verglaster Schlüsselschrank hinter der Rezeption (Spielkonzept 6.19): Darin hängt der Generalschlüssel – er passt in
## jede Zimmertür, außer jemand hat von innen den Riegel vorgeschoben. Die Scheibe einzuschlagen ist laut, mitten in
## der Lobby, und wer es sieht, erzählt es weiter (RoomAccess.on_smashed). Steht im Plan („Ausstattung:
## Schlüsselschrank“), lokale +Z zeigt von der Wand weg.

const KEY_ID := "general"
const SIZE := Vector3(0.42, 0.56, 0.08)

var smashed := false
var key_taken := false

var _glass: MeshInstance3D
var _shards: Node3D
var _key: Node3D


func _ready() -> void:
	add_to_group("key_cabinets")
	collision_layer = 1
	collision_mask = 0
	set_meta("interactable", self)
	var wood := Mat.psx(Color(0.28, 0.16, 0.09))
	Geo.mesh(self, Geo.box(Vector3(SIZE.x, SIZE.y, 0.02)), wood, Vector3(0, 0, 0.01))   # Rückwand
	for x in [-1.0, 1.0]:
		Geo.mesh(self, Geo.box(Vector3(0.03, SIZE.y, SIZE.z)), wood, Vector3(x * (SIZE.x - 0.03) / 2.0, 0, SIZE.z / 2.0))
	for y in [-1.0, 1.0]:
		Geo.mesh(self, Geo.box(Vector3(SIZE.x, 0.03, SIZE.z)), wood, Vector3(0, y * (SIZE.y - 0.03) / 2.0, SIZE.z / 2.0))
	var brass := Mat.psx(Color(0.8, 0.65, 0.25))
	for i in 6:   # leere Haken für die Zimmerschlüssel, einer trägt den Generalschlüssel
		var x := -0.14 + (i % 3) * 0.14
		var y := 0.12 - floori(i / 3.0) * 0.2
		Geo.mesh(self, Geo.box(Vector3(0.01, 0.01, 0.03)), brass, Vector3(x, y, 0.035))
	_key = Node3D.new()
	_key.position = Vector3(0.0, -0.08, 0.04)
	add_child(_key)
	Geo.mesh(_key, Geo.box(Vector3(0.012, 0.09, 0.006)), brass, Vector3(0, -0.03, 0))
	Geo.mesh(_key, Geo.box(Vector3(0.04, 0.03, 0.006)), brass, Vector3(0, 0.025, 0))
	Geo.mesh(_key, Geo.box(Vector3(0.05, 0.03, 0.004)), Mat.psx(Color(0.85, 0.15, 0.12)), Vector3(0, 0.06, 0))   # Anhänger
	_glass = Geo.mesh(self, Geo.box(Vector3(SIZE.x - 0.06, SIZE.y - 0.06, 0.005)), Mat.glass(), Vector3(0, 0, SIZE.z))
	_glass.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_shards = Node3D.new()
	add_child(_shards)
	for i in 4:   # Scherben am Rand, wenn die Scheibe eingeschlagen ist
		var shard := Geo.mesh(_shards, Geo.box(Vector3(0.05, 0.08, 0.004)), Mat.glass(), Vector3(-0.15 + i * 0.1, -0.22, SIZE.z))
		shard.rotation.z = 0.4 * (i - 1.5)
	Geo.add_box_shape(self, SIZE, Vector3(0, 0, SIZE.z / 2.0))
	_update()


func get_prompt(player: Player) -> String:
	if not smashed:
		return "Hände voll" if player.hands_blocked() else "Scheibe einschlagen [E]"
	if not key_taken:
		return "Generalschlüssel nehmen [E]"
	return ""


func interact(player: Player) -> void:
	if not smashed:
		if player.hands_blocked():
			return
		smashed = true
		Game.noise("glass", global_position, player)
		Game.say("Die Scheibe zerspringt. Das hat man gehört.")
		if Game.social and Game.social.access:
			Game.social.access.on_smashed(self)
		_update()
	elif not key_taken:
		key_taken = true
		player.add_key(KEY_ID)
		Game.noise("keys", global_position, player)
		Game.say("Der Generalschlüssel. Er passt in jede Zimmertür – außer, jemand hat von innen den Riegel vorgeschoben.", 5.0)
		_update()


func _update() -> void:
	_glass.visible = not smashed
	_shards.visible = smashed
	_key.visible = not key_taken


func save_state() -> Dictionary:
	return {"smashed": smashed, "key": key_taken}


func load_state(d: Dictionary) -> void:
	smashed = bool(d.get("smashed", false))
	key_taken = bool(d.get("key", false))
	_update()
