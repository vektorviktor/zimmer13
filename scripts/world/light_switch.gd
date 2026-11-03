class_name LightSwitch
extends StaticBody3D
## Lichtschalter – meist einer pro Raum bzw. Flurabschnitt (Spielkonzept 7.3), mehrere im selben
## Raum bilden eine Wechselschaltung. Schaltet alle Decken- und Wandlampen des Raums. Licht aus =
## das Monster kommt (4.4).
## Lokale +Z zeigt von der Wand in den Raum.
## Aussehen: quadratische Platte aus Altmessing mit Kordelrand und Schlitzschrauben – alles Textur
## (tools/switch_plate.gd) –, darauf eine eckige Messingwippe in schwarzem Rahmen.

## Kantenlänge und Stärke der Platte, Wippe und Rahmen (m), Neigung der Wippe (rad)
const PLATE := 0.086
const PLATE_DEPTH := 0.007
const ROCKER := Vector3(0.0145, 0.0225, 0.008)
const BEZEL := Vector3(0.0175, 0.0255, 0.0015)
const ROCKER_TILT := 0.12
const PLATE_TEX := "res://assets/textures/switch_plate.png"
const PLATE_NORMAL := "res://assets/textures/switch_plate_normal.png"
const PLATE_ROUGH := "res://assets/textures/switch_plate_rough.png"
## Ausschnitt der Textur (UV) für Wippe und Plattenkanten: gebürstetes Feld ohne Schrauben
const PLAIN_UV := Vector2(0.42, 0.56)
const METALLIC := 0.4

static var _brass: ShaderMaterial
static var _plate_mesh: ArrayMesh

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
	var brass := _brass_material()
	Geo.mesh(self, _plate(), brass, Vector3.ZERO)
	Geo.mesh(self, Geo.box(BEZEL), Mat.psx(Color(0.025, 0.022, 0.02)), Vector3(0, 0, PLATE_DEPTH + BEZEL.z / 2.0))
	_toggle = Geo.mesh(self, Geo.grain_box(ROCKER, 0, Vector2(PLATE, PLATE), PLATE, PLAIN_UV), brass,
		Vector3(0, 0, PLATE_DEPTH + ROCKER.z / 2.0))
	Geo.add_box_shape(self, Vector3(0.2, 0.25, 0.12), Vector3(0, 0, 0.04))
	_update_visual()


## Messing aller Schalter (Spielkonzept 9.2): Textur über die UVs gespannt, eine Kachel = 1 UV-Einheit
static func _brass_material() -> ShaderMaterial:
	if _brass == null:
		_brass = Mat.photo(PLATE_TEX, 1.0, PLATE_NORMAL, PLATE_ROUGH, 0.5, Color(1, 1, 1), false, true)
		_brass.set_shader_parameter("metallic", METALLIC)
	return _brass


## Platte ohne Rückseite: Vorderseite trägt die ganze Textur (oben im Bild = oben), die Kanten einen Streifen
## gebürstetes Feld
static func _plate() -> ArrayMesh:
	if _plate_mesh:
		return _plate_mesh
	var h := PLATE / 2.0
	var verts := [Vector3(-h, h, PLATE_DEPTH), Vector3(h, h, PLATE_DEPTH), Vector3(h, -h, PLATE_DEPTH), Vector3(-h, -h, PLATE_DEPTH)]
	var normals := [Vector3.BACK, Vector3.BACK, Vector3.BACK, Vector3.BACK]
	var uvs := [Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1)]
	var indices := []
	Geo._quad(indices, verts, [0, 1, 2, 3], Vector3.BACK)
	var band := PLATE_DEPTH / PLATE
	for k in 4:
		var a: Vector3 = verts[k]
		var b: Vector3 = verts[(k + 1) % 4]
		var n := ((a + b) * Vector3(1, 1, 0)).normalized()
		var first := verts.size()
		verts.append_array([a, b, b - Vector3(0, 0, PLATE_DEPTH), a - Vector3(0, 0, PLATE_DEPTH)])
		normals.append_array([n, n, n, n])
		uvs.append_array([PLAIN_UV, PLAIN_UV + Vector2(0.16, 0), PLAIN_UV + Vector2(0.16, band), PLAIN_UV + Vector2(0, band)])
		Geo._quad(indices, verts, [first, first + 1, first + 2, first + 3], n)
	_plate_mesh = Geo.add_surface(ArrayMesh.new(), PackedVector3Array(verts), PackedVector3Array(normals),
		PackedInt32Array(indices), PackedVector2Array(uvs))
	return _plate_mesh


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
	if not on and Game.social:   # bei einem Gast das Licht aus: Ursache bis zum Ende der Nacht (6.18, 2)
		Game.social.deaths.note_room(room_id, "light")


func _update_visual() -> void:
	if _toggle:
		_toggle.rotation.x = -ROCKER_TILT if on else ROCKER_TILT


func save_state() -> Dictionary:
	return {"on": on}


func load_state(data: Dictionary) -> void:
	on = not bool(data.get("on", true))
	set_on(bool(data.get("on", true)), true)
