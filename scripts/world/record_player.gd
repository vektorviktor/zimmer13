class_name RecordPlayer
extends StaticBody3D
## Plattenspieler in der Lobby: Feier starten oder Musik ausschalten.

var playing := false

var _disc: MeshInstance3D


func _ready() -> void:
	collision_layer = 4
	collision_mask = 0
	set_meta("interactable", self)
	Geo.mesh(self, Geo.box(Vector3(0.45, 0.12, 0.35)), Mat.psx(Color(0.35, 0.2, 0.1)), Vector3(0, 0.06, 0))
	_disc = Geo.mesh(self, Geo.cylinder(0.14, 0.012, 12), Mat.psx(Color(0.05, 0.05, 0.05)), Vector3(-0.04, 0.13, 0))
	Geo.mesh(_disc, Geo.cylinder(0.04, 0.014, 8), Mat.psx(Color(0.7, 0.15, 0.1)), Vector3.ZERO)
	Geo.mesh(self, Geo.box(Vector3(0.02, 0.02, 0.2)), Mat.psx(Color(0.75, 0.75, 0.7)), Vector3(0.16, 0.15, 0.02))
	# Trichter
	var horn := Geo.mesh(self, Geo.cylinder(0.06, 0.3, 8), Mat.psx(Color(0.75, 0.6, 0.25)), Vector3(0.15, 0.3, -0.1))
	horn.rotation.x = -0.6
	Geo.add_box_shape(self, Vector3(0.45, 0.3, 0.35), Vector3(0, 0.15, 0))


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
