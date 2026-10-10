class_name Diary
extends StaticBody3D
## Das Tagebuch auf dem Schreibtisch in Zimmer 13 – der einzige Speicherpunkt
## (Spielkonzept 8.5). Fest verankert: nicht tragbar, nicht klaubar.


func _ready() -> void:
	collision_layer = 4
	collision_mask = 0
	set_meta("interactable", self)
	add_to_group("diaries")
	var cover := Mat.psx(Color(0.28, 0.1, 0.08))
	Geo.mesh(self, Geo.box(Vector3(0.24, 0.035, 0.18)), cover, Vector3(0, 0.0175, 0))
	Geo.mesh(self, Geo.box(Vector3(0.22, 0.025, 0.17)), Mat.psx(Color(0.85, 0.8, 0.65)), Vector3(0.008, 0.018, 0))
	var pen := Geo.mesh(self, Geo.cylinder(0.006, 0.14, 4), Mat.psx(Color(0.1, 0.1, 0.12)), Vector3(0.17, 0.008, 0.02))
	pen.rotation = Vector3(0, 0.4, PI / 2.0)
	Geo.add_box_shape(self, Vector3(0.3, 0.08, 0.24), Vector3(0, 0.04, 0))


func get_prompt(_player: Player) -> String:
	if not SaveManager.can_save():
		return "Tagebuch – deine Hände zittern zu sehr"
	return "Ins Tagebuch schreiben (speichern) [E]"


func interact(_player: Player) -> void:
	if not SaveManager.can_save():
		Game.say("Meine Hände zittern zu sehr.", 2.5)
		return
	if Game.menus:
		Game.menus.open_diary()
