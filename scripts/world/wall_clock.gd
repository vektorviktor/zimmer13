class_name WallClock
extends Node3D
## Wanduhr aus schwarzem Eisen über dem Haupteingang (tools/build_clock.py): Rahmen „frame“ auf weißem Zifferblatt
## „dial“, Zeiger „hour_hand“ und „minute_hand“ drehen um lokal Z, Ruhelage 12 Uhr. Ursprung in der Uhrmitte auf der
## Rückseite, Zifferblatt nach +Z.
## Zeigt die Tagesuhr (Spielkonzept 2.4, Calendar.hour_of) – die Zeiger laufen sichtbar, eine Spielminute je Sekunde.

const MODEL := "res://assets/models/clock.glb"
## Durchmesser des Modells in Metern (DIAMETER in tools/build_clock.py)
const MODEL_DIAMETER := 2.0
## Mattes Schwarz: hebt sich als Silhouette von der roten Tapete ab (poliertes Eisen ging oben im Halbdunkel unter)
const IRON := Color(0.06, 0.055, 0.05)
## Zifferblatt: gebrochenes Weiß (altes Emaille)
const DIAL := Color(0.88, 0.86, 0.8)
var _hour_hand: Node3D
var _minute_hand: Node3D


## Uhr mit diameter Metern Durchmesser; null, wenn das Modell fehlt.
static func create(diameter: float) -> WallClock:
	if not ResourceLoader.exists(MODEL):
		return null
	var clock := WallClock.new()
	var model: Node3D = (load(MODEL) as PackedScene).instantiate()
	model.scale = Vector3.ONE * diameter / MODEL_DIAMETER
	clock.add_child(model)
	for mi: MeshInstance3D in model.find_children("*", "MeshInstance3D", true, false):
		mi.material_override = Mat.psx(DIAL if mi.name == "dial" else IRON)
	clock._hour_hand = model.find_child("hour_hand", true, false)
	clock._minute_hand = model.find_child("minute_hand", true, false)
	return clock


func _process(_delta: float) -> void:
	set_time(Calendar.hour_of(Calendar._elapsed()))


## Zeiger auf hours stellen (0..24, Bruchteile = Minuten); im Uhrzeigersinn von vorn gesehen = um −Z.
func set_time(hours: float) -> void:
	if _hour_hand:
		_hour_hand.rotation.z = -TAU * fposmod(hours, 12.0) / 12.0
	if _minute_hand:
		_minute_hand.rotation.z = -TAU * fposmod(hours, 1.0)
