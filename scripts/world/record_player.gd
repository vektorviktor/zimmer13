class_name RecordPlayer
extends StaticBody3D
## Plattenspieler in der Lobby: Feier starten oder Musik ausschalten (Spielkonzept 7.1).
## Modell aus tools/build_record_player.py: „body“ und die drehbare Platte „record“.

const MODEL := "res://assets/models/record_player.glb"
## Das Modell ist 0,64 × 0,54 m (Trichter nach −X/−Z) – so verschoben steht es mittig auf dem Tisch.
const MODEL_OFFSET := Vector3(0.16, 0, 0.02)

var playing := false

var _disc: MeshInstance3D


func _ready() -> void:
	collision_layer = 4
	collision_mask = 0
	set_meta("interactable", self)
	var model: Node3D = (load(MODEL) as PackedScene).instantiate()
	model.position = MODEL_OFFSET
	add_child(model)
	for m: MeshInstance3D in model.find_children("*", "MeshInstance3D", true, false):
		m.material_override = Mat.model(MODEL, m)
	_disc = model.find_child("record", true, false) as MeshInstance3D
	# Gehäuse und Trichter
	Geo.add_box_shape(self, Vector3(0.34, 0.2, 0.34), MODEL_OFFSET + Vector3(0, 0.1, 0))
	Geo.add_box_shape(self, Vector3(0.37, 0.5, 0.42), MODEL_OFFSET + Vector3(-0.29, 0.45, -0.08))


func _process(delta: float) -> void:
	if playing:
		_disc.rotation.y += delta * 3.5


func set_playing(value: bool) -> void:
	playing = value


func get_prompt(_player: Player) -> String:
	return "Musik ausschalten [E]" if playing else "Feier in der Lobby starten [E]"


func interact(_player: Player) -> void:
	if playing:
		Game.social.end_party("Du schaltest die Musik aus.")
	else:
		Game.social.start_party("player")
