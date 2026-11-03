class_name LiftDrive
extends StaticBody3D
## Antrieb des Aufzugs im Maschinenraum (Spielkonzept 7.4, 7.10; ZIM-14): Motor und Bremstrommel auf einem Sockel,
## vorn die Kurbel. Die Bremse ist festgefressen – einer der drei Mängel aus dem Notizbuch des Hausmeisters. Lösen:
## [E] gedrückt halten, CRANK_TIME Sekunden; die Kurbel quietscht durch den ganzen Keller (Lärm „lift_brake“ alle
## NOISE_EVERY s, laut genug für das ruhende Monster). Loslassen oder Weggehen unterbricht, der Fortschritt bleibt –
## aber nur in dieser Sitzung, nach dem Laden beginnt man von vorn. Gelöst: Elevator.fix_all(„brake“).
## Ort: Ausstattung „Aufzugsantrieb“ im Plan (vor der Wand, Kurbel in den Raum), bis dahin FALLBACK an der Nordwand des
## Maschinenraums östlich des Sicherungskastens. Gebaut von place() (main.gd).

const CRANK_TIME := 20.0
const NOISE_EVERY := 1.6
## So nah muss man an der Kurbel stehen, damit sie sich dreht
const REACH := 1.8
## Kurbelumdrehungen je Sekunde
const TURN_SPEED := 0.7
## Sockel: Breite (x), Tiefe (z), Höhe; Mitte der Welle über dem Boden
const BASE := Vector3(1.3, 0.25, 0.7)
const SHAFT_Y := 0.62
## Ohne Planeintrag: Boden vor der Nordwand des Maschinenraums, Kurbel nach +Z (Süden)
const FALLBACK := Vector3(40.5, LevelBuilder.CELLAR_Y, -49.4)

var progress := 0.0
var _cranking := false
var _noise := 0.0
var _crank: Node3D     ## dreht sich um die Welle (lokal Z)
var _lever: Node3D     ## Bremshebel: hebt sich mit dem Fortschritt


## Den Antrieb in den Maschinenraum stellen (Planeintrag „lift_drive“ oder FALLBACK).
static func place(builder: LevelBuilder) -> LiftDrive:
	var drive := LiftDrive.new()
	drive.name = "Aufzugsantrieb"
	builder.world.add_child(drive)
	drive.global_transform = builder.planned_at("lift_drive", Transform3D(Basis(), FALLBACK), 0.0, BASE.z / 2.0)
	return drive


func _ready() -> void:
	collision_layer = 4
	collision_mask = 0
	set_meta("interactable", self)
	add_to_group("lift_drives")
	var concrete := Mat.psx(Color(0.46, 0.45, 0.43))
	var paint := Mat.metal(Color(0.32, 0.4, 0.34))
	var steel := Mat.metal(Color(0.36, 0.36, 0.38))
	var rust := Mat.psx(Color(0.38, 0.2, 0.1))
	Geo.mesh(self, Geo.box(BASE), concrete, Vector3(0, BASE.y / 2.0, 0))
	# Motor (liegend, Achse X) links, Bremstrommel rechts, dazwischen die Welle
	var motor := Geo.mesh(self, Geo.cylinder(0.24, 0.6, 16), paint, Vector3(-0.3, SHAFT_Y, 0))
	motor.rotation.z = PI / 2.0
	for x: float in [-0.5, -0.1]:
		Geo.mesh(self, Geo.box(Vector3(0.08, SHAFT_Y - BASE.y, 0.36)), paint, Vector3(x, (SHAFT_Y + BASE.y) / 2.0 - 0.12, 0))
	var drum := Geo.mesh(self, Geo.cylinder(0.2, 0.22, 16), steel, Vector3(0.3, SHAFT_Y, 0))
	drum.rotation.z = PI / 2.0
	var band := Geo.mesh(self, Geo.cylinder(0.215, 0.12, 16), rust, Vector3(0.3, SHAFT_Y, 0))   # festgefressenes Bremsband
	band.rotation.z = PI / 2.0
	Geo.mesh(self, Geo.box(Vector3(0.3, SHAFT_Y - 0.2 - BASE.y, 0.3)), paint, Vector3(0.3, BASE.y + (SHAFT_Y - 0.2 - BASE.y) / 2.0, 0))
	# Bremshebel oben auf der Trommel
	_lever = Node3D.new()
	_lever.position = Vector3(0.3, SHAFT_Y + 0.2, 0)
	add_child(_lever)
	Geo.mesh(_lever, Geo.box(Vector3(0.04, 0.04, 0.42)), steel, Vector3(0, 0.02, -0.12))
	# Kurbel vorn an der Trommel: Welle nach +Z, Arm, Griff
	Geo.mesh(self, Geo.box(Vector3(0.05, 0.05, 0.2)), steel, Vector3(0.3, SHAFT_Y, BASE.z / 2.0 - 0.05))
	_crank = Node3D.new()
	_crank.position = Vector3(0.3, SHAFT_Y, BASE.z / 2.0 + 0.05)
	add_child(_crank)
	Geo.mesh(_crank, Geo.box(Vector3(0.04, 0.26, 0.03)), steel, Vector3(0, 0.11, 0))
	var grip := Geo.mesh(_crank, Geo.cylinder(0.018, 0.12, 8), Mat.psx(Color(0.15, 0.1, 0.07)), Vector3(0, 0.22, 0.07))
	grip.rotation.x = PI / 2.0
	Geo.add_box_shape(self, Vector3(BASE.x, SHAFT_Y + 0.3, BASE.z + 0.2), Vector3(0, (SHAFT_Y + 0.3) / 2.0, 0.1))
	_show()


func done() -> bool:
	return Elevator.part_fixed(get_tree(), "brake")


func get_prompt(_player: Player) -> String:
	if done():
		return "Aufzugsantrieb – die Bremse ist gelöst"
	if progress <= 0.0:
		return "Bremse lösen – Kurbel drehen, [E] gedrückt halten"
	return "Bremse lösen – weiterkurbeln, [E] gedrückt halten (%d %%)" % int(progress / CRANK_TIME * 100.0)


func interact(_player: Player) -> void:
	if not done():
		_cranking = true


func _process(delta: float) -> void:
	if not _cranking:
		if _lever.rotation.x > -0.5 and done():   # nach dem Laden gelöst
			_show()
		return
	var p := Game.player
	if p == null or p.hiding != null or p.sleeping or not Input.is_action_pressed("interact") \
			or p.global_position.distance_to(_crank.global_position) > REACH:
		_cranking = false
		return
	crank(delta)


## delta Sekunden weiterkurbeln (auch Debug): Kurbel dreht, Hebel hebt sich, alle NOISE_EVERY s quietscht es; am Ende
## gibt die Bremse nach.
func crank(delta: float) -> void:
	if done():
		_cranking = false
		return
	progress = minf(CRANK_TIME, progress + delta)
	_crank.rotation.z -= TAU * TURN_SPEED * delta
	_noise -= delta
	if _noise <= 0.0:
		_noise = NOISE_EVERY
		Game.noise("lift_brake", _crank.global_position, Game.player)
	_show()
	if progress >= CRANK_TIME:
		_cranking = false
		Game.say("Mit einem Ruck gibt die Bremse nach. Das Quietschen hallt im Keller nach.", 4.0)
		Elevator.fix_all(get_tree(), "brake")
		_show()


func _show() -> void:
	var t := 1.0 if is_inside_tree() and done() else progress / CRANK_TIME
	_lever.rotation.x = -0.5 * t
