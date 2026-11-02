class_name HotelPhone
extends StaticBody3D
## Altes Wählscheibentelefon (Spielkonzept 4.14): eins in fast jedem Zimmer, der Hauptapparat
## steht an der Rezeption. Abnehmen, wählen, Hörer daneben legen – die Anrufe selbst
## verwaltet `PhoneCalls` (Game.phones). Lokale +Z zeigt zum Spieler (Wählscheibe vorn).
## Modell aus tools/build_old_phone.py: schwarz glänzend, Wählscheibe aus gebürstetem Messing. Auf der Gabel liegt die
## Schnur des Modells in Schlaufen auf dem Tisch; liegt der Hörer daneben, verbindet ihn eine erzeugte Schnur.

const MODEL := "res://assets/models/phone.glb"
const TEX := "res://assets/textures/phone"
## Hörer neben dem Apparat: links auf dem Tisch, die Sprechmuschel mit der Schnur schräg nach hinten
const OFF_HOOK_POS := Vector3(-0.2, 0.0, 0.07)
const OFF_HOOK_YAW := -0.5
const CORD_R := 0.004
const CORD_SEGMENTS := 24
const CORD_SIDES := 6

var room_id := ""           ## Zimmernummer oder "lobby" (Rezeption)
var off_hook := false       ## Hörer liegt daneben → besetzt, klingelt nicht
var ringing := false        ## klingelt gerade (setzt PhoneCalls)

var _handset: Node3D
var _hook_pos: Vector3          ## Lage des Hörers auf der Gabel
var _cord: Node3D               ## Schnur des Modells (Hörer aufgelegt)
var _loose_cord: MeshInstance3D ## erzeugte Schnur (Hörer daneben)
var _cord_body: Node3D          ## Tülle am Gehäuse
var _cord_handset: Node3D       ## Tülle am Hörer
var _cord_uv: Vector2           ## ein Texel aus dem Gummi der Modellschnur


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
	var model: Node3D = (load(MODEL) as PackedScene).instantiate()
	add_child(model)
	var mat := Mat.pbr_model(TEX)
	for m: MeshInstance3D in model.find_children("*", "MeshInstance3D", true, false):
		m.material_override = mat
	_handset = model.get_node("handset")
	_hook_pos = _handset.position
	_cord = model.get_node("cable")
	_cord_body = model.get_node("cable_body")
	_cord_handset = _handset.get_node("cable_handset")
	_cord_uv = ((_cord as MeshInstance3D).mesh.surface_get_arrays(0)[Mesh.ARRAY_TEX_UV] as PackedVector2Array)[0]
	_loose_cord = MeshInstance3D.new()
	_loose_cord.material_override = mat
	model.add_child(_loose_cord)
	Geo.add_box_shape(self, Vector3(0.24, 0.135, 0.19), Vector3(0, 0.0675, 0))
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
		_handset.position = OFF_HOOK_POS
		_handset.rotation = Vector3(0, OFF_HOOK_YAW, 0)
		_loose_cord.mesh = _cord_mesh()
	else:
		_handset.position = _hook_pos
		_handset.rotation = Vector3.ZERO
	_cord.visible = not off_hook
	_loose_cord.visible = off_hook


## Schnur von der Tülle am Gehäuse zur Tülle am Hörer: fällt auf den Tisch und läuft dort im Bogen hinüber
func _cord_mesh() -> ArrayMesh:
	var a := _cord_body.position
	var d := _handset.transform * _cord_handset.position
	var out := _handset.transform.basis * Vector3.LEFT
	var b := Vector3(a.x - 0.03, CORD_R, a.z - 0.04)
	var c := Vector3(d.x, CORD_R, d.z) + out * 0.06
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var prev_ring := []
	for i in CORD_SEGMENTS + 1:
		var t := float(i) / CORD_SEGMENTS
		var p := a.bezier_interpolate(b, c, d, t)
		var dir := a.bezier_derivative(b, c, d, t).normalized()
		var side := dir.cross(Vector3.UP).normalized()
		var up := side.cross(dir)
		var ring := []
		for k in CORD_SIDES:
			var ang := TAU * k / CORD_SIDES
			var n := side * cos(ang) + up * sin(ang)
			ring.append([p + n * CORD_R, n])
		if i > 0:
			for k in CORD_SIDES:
				var k2 := (k + 1) % CORD_SIDES
				for v in [prev_ring[k], ring[k2], ring[k], prev_ring[k], prev_ring[k2], ring[k2]]:   # im Uhrzeigersinn = außen
					st.set_normal(v[1])
					st.set_tangent(Plane(dir, 1.0))
					st.set_uv(_cord_uv)
					st.add_vertex(v[0])
		prev_ring = ring
	return st.commit()


func _process(_delta: float) -> void:
	# Klingeln lässt den Hörer auf der Gabel zittern
	if _handset and not off_hook:
		_handset.position.y = _hook_pos.y + (randf() * 0.006 if ringing else 0.0)


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
