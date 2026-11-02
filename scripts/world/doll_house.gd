class_name DollHouse
extends StaticBody3D
## Das Puppenhaus in der Bibliothek (Spielkonzept 5.16): ein Modell des Hotels im Maßstab 1:100 auf einem langen Tisch,
## Erdgeschoss und Obergeschoss nebeneinander als gedruckte Pläne (HotelMap) unter Glas. Darauf kleine Holzfiguren – eine
## je erwachsenem Gast, dort, wo er gerade ist. Wer tot ist, liegt umgekippt in seinem Zimmer. Vor einer Tür steht eine
## winzige Puppe: das Urteil (JuryDoll.verdict) – sobald es gefällt ist, auch wenn die große Puppe noch wartet, bis
## niemand hinsieht. Vorwarnung um Minuten, nicht um Stunden; das Urteil bleibt bei der Puppe (5.5).
## Die Figuren bewegen sich nur, wenn niemand hinsieht. Und das Modell lügt: unter Schock oder in einer Halluzination
## stehen sie falsch, und die kleine Puppe steht vor Zimmer 13.
## Ort: Möbel „Puppenhaus“ im Plan (ZIM-158, Mitte des Rechtecks; ist es länger in z, quer gedreht), sonst SPOT (Mitte
## der Bibliothek im Obergeschoss). Nicht gespeichert.

const SPOT := Vector3(-45.5, LevelBuilder.UP_Y, -41.0)
const SCALE := 0.01                       ## 1:100
const TABLE_H := 0.78
const PLATE := Vector2(HotelMap.X_MAX - HotelMap.X_MIN, HotelMap.Z_MAX - HotelMap.Z_MIN) * SCALE
const GAP := 0.12                         ## zwischen den beiden Plänen
const PEG_H := 0.03
const UPDATE_EVERY := 1.5
const LIE_SHOCK := 0.5
const NOTE := "In der Bibliothek steht ein Modell des Hotels mit kleinen Holzfiguren. Sie stehen, wo die Gäste sind – und vor einer Tür steht eine winzige Puppe."

var spot := Transform3D(Basis(), SPOT)   ## Platz (global), setzt main aus dem Plan
var _pegs := {}                           ## Gast-ID → Node3D
var _mini_doll: Node3D
var _plates: Array[Node3D] = []           ## [EG, OG]
var _update := 0.0
var _noted := false


func _ready() -> void:
	collision_layer = 1 | 4
	collision_mask = 0
	set_meta("interactable", self)
	transform = spot
	var size := Vector3(PLATE.x * 2.0 + GAP + 0.16, TABLE_H, PLATE.y + 0.16)
	var wood := Mat.wood(false, Color(0.55, 0.38, 0.26))
	Geo.mesh(self, Geo.box(Vector3(size.x, 0.05, size.z)), wood, Vector3(0, TABLE_H - 0.025, 0))
	for x in [-1.0, 1.0]:
		for z in [-1.0, 1.0]:
			Geo.mesh(self, Geo.box(Vector3(0.07, TABLE_H - 0.05, 0.07)), wood,
				Vector3(x * (size.x / 2.0 - 0.08), (TABLE_H - 0.05) / 2.0, z * (size.z / 2.0 - 0.08)))
	Geo.add_box_shape(self, size, Vector3(0, TABLE_H / 2.0, 0))
	for i in 2:
		var plate := Node3D.new()
		plate.position = Vector3((i - 0.5) * (PLATE.x + GAP), TABLE_H + 0.004, 0)
		add_child(plate)
		_plates.append(plate)
		var quad := QuadMesh.new()
		quad.size = PLATE
		var sheet := Geo.mesh(plate, quad, HotelMap.material("eg" if i == 0 else "og"), Vector3.ZERO)
		sheet.rotation.x = -PI / 2.0   # Norden (−Z) oben auf dem Blatt
		# Rahmen aus Leisten
		for side in [-1.0, 1.0]:
			Geo.mesh(plate, Geo.box(Vector3(PLATE.x + 0.04, 0.03, 0.02)), wood, Vector3(0, 0.01, side * (PLATE.y / 2.0 + 0.01)))
			Geo.mesh(plate, Geo.box(Vector3(0.02, 0.03, PLATE.y)), wood, Vector3(side * (PLATE.x / 2.0 + 0.01), 0.01, 0))
		var label := Label3D.new()
		label.text = "Erdgeschoss" if i == 0 else "1. Obergeschoss"
		label.font_size = 28
		label.pixel_size = 0.0012
		label.modulate = Color(0.2, 0.15, 0.1)
		label.outline_size = 0
		label.rotation.x = -PI / 2.0
		label.position = Vector3(0, 0.002, PLATE.y / 2.0 + 0.05)
		plate.add_child(label)
	_mini_doll = _make_doll()
	_mini_doll.visible = false
	add_child(_mini_doll)


func get_prompt(_player: Player) -> String:
	return "Modell ansehen [E]"


func interact(_player: Player) -> void:
	Game.say("Ein Modell des Hotels aus Pappe und Holz. Kleine Figuren stehen auf den Plänen – so viele, wie Gäste da sind.", 4.5)
	if not _noted and Game.notebook:
		_noted = true
		Game.notebook.add_note("doll_house", NOTE, "Bibliothek")


func _process(delta: float) -> void:
	_update -= delta
	if _update > 0.0:
		return
	_update = UPDATE_EVERY
	var d := Game.director
	if d == null or Game.social == null:
		return
	if d.player_can_see(global_position + Vector3.UP * TABLE_H) \
			and Game.player.global_position.distance_to(global_position) < 25.0:
		return   # sie rücken nur, wenn niemand hinsieht
	var lying := Game.player.shock >= LIE_SHOCK or d.is_hallucinating()
	for g in Game.social.guests:
		var guest := g as Guest
		if guest.is_child():
			continue
		var peg: Node3D = _pegs.get(guest.id)
		if peg == null:
			peg = _make_peg(guest)
			_pegs[guest.id] = peg
		var at := guest.global_position
		if guest.dead:
			at = guest.home.get("center", at)
		if lying:
			at = Vector3(randf_range(-60, 50), at.y, randf_range(-70, -5))
		var spot := _to_model(at)
		peg.visible = spot.is_finite()
		if spot.is_finite():
			peg.position = spot
			peg.rotation = Vector3(0, 0, PI / 2.0) if guest.dead else Vector3.ZERO
	var room := LevelBuilder.PLAYER_ROOM if lying else (Game.doll.verdict if Game.doll else "")
	_mini_doll.visible = false
	if room != "" and d.rooms.has(room):
		var spot := _to_model(d.rooms[room]["door_front"])
		if spot.is_finite():
			_mini_doll.position = spot
			_mini_doll.visible = true


## Welt → Lage auf einem der Pläne (EG oder OG), INF = anderes Stockwerk.
func _to_model(p: Vector3) -> Vector3:
	var level := 0 if p.y < LevelBuilder.UP_Y - 1.5 else (1 if p.y < LevelBuilder.UP_Y * 2.0 - 1.5 else -1)
	if p.y < -1.0 or level < 0:
		return Vector3.INF
	var cx := (HotelMap.X_MIN + HotelMap.X_MAX) / 2.0
	var cz := (HotelMap.Z_MIN + HotelMap.Z_MAX) / 2.0
	var plate := _plates[level].position
	return plate + Vector3((p.x - cx) * SCALE, 0.002, (p.z - cz) * SCALE)


func _make_peg(guest: Guest) -> Node3D:
	var peg := Node3D.new()
	add_child(peg)
	var coat := Color(0.5, 0.4, 0.3)
	if guest.profile.get("coat") is Color:
		coat = guest.profile["coat"]
	var body := CylinderMesh.new()
	body.top_radius = 0.004
	body.bottom_radius = 0.006
	body.height = PEG_H * 0.7
	body.radial_segments = 6
	Geo.mesh(peg, body, Mat.psx(coat.lerp(Color(0.6, 0.45, 0.3), 0.5)), Vector3(0, PEG_H * 0.35, 0))
	Geo.mesh(peg, Geo.sphere(0.005, 0.01, 6, 3), Mat.psx(Color(0.8, 0.65, 0.45)), Vector3(0, PEG_H * 0.82, 0))
	return peg


## Die winzige Puppe: weißes Kleid, dunkles Haar – so groß wie eine Figur.
func _make_doll() -> Node3D:
	var doll := Node3D.new()
	var dress := CylinderMesh.new()
	dress.top_radius = 0.002
	dress.bottom_radius = 0.007
	dress.height = PEG_H * 0.7
	dress.radial_segments = 8
	Geo.mesh(doll, dress, Mat.psx(Color(0.92, 0.9, 0.86)), Vector3(0, PEG_H * 0.35, 0))
	Geo.mesh(doll, Geo.sphere(0.0045, 0.009, 6, 3), Mat.psx(Color(0.95, 0.85, 0.8)), Vector3(0, PEG_H * 0.82, 0))
	Geo.mesh(doll, Geo.sphere(0.005, 0.006, 6, 3), Mat.psx(Color(0.15, 0.08, 0.05)), Vector3(0, PEG_H * 0.9, 0.001))
	return doll


## Debug (--puppenhaus[=urteil]): du stehst in der Bibliothek vor dem Modell · urteil: die Puppe urteilt gleich über
## die schwächste Tür (wie --doll) – die kleine steht schon davor, solange du hinsiehst nicht.
func debug_show(what: String) -> void:
	var front := global_position + Vector3(0, 0.05, PLATE.y / 2.0 + 1.0)
	TeleportUI.place_player(front, global_position + Vector3.UP * TABLE_H - front - Vector3.UP * 0.4)
	_update = 0.0
	if what == "urteil" and Game.doll:
		Game.director.first_attack_done = true
		Game.doll.judge(Game.director.forecast_room())
