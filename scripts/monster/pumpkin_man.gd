class_name PumpkinMan
extends Node3D
## Kürbismann – neues Monster mit Kürbiskopf und Axt, vorerst nur als Testfigur (Debug --pumpkin):
## steht vor dem Spieler und spielt eine Animation aus der GLB in Schleife. Modell von tools/build_pumpkin.py
## (Meshy, Skelett von tools/smartrig_to_mixamo.py auf Mixamo umgebaut, Tänze wie bei den Gästen).

const MODEL := "res://assets/models/pumpkin_man.glb"
## So weit vor dem Spieler (m)
const DISTANCE := 2.5

var _player: AnimationPlayer


## Testfigur vor den Spieler stellen, Blick zu ihm – ersetzt eine schon stehende.
static func spawn_in_front_of(p: Player, anim: String) -> PumpkinMan:
	var tree := p.get_tree()
	for old in tree.get_nodes_in_group("pumpkin_men"):
		old.queue_free()
	var man := PumpkinMan.new()
	man.add_to_group("pumpkin_men")
	tree.current_scene.add_child(man)
	var forward := -p.global_transform.basis.z
	forward.y = 0.0
	man.global_position = p.global_position + forward.normalized() * DISTANCE
	man.rotation.y = p.rotation.y + PI
	man.play(anim)
	return man


func _init() -> void:
	var model: Node3D = (load(MODEL) as PackedScene).instantiate()
	add_child(model)
	var mesh: MeshInstance3D = model.find_children("*", "MeshInstance3D", true, false)[0]
	mesh.material_override = Mat.model(MODEL, mesh, 0, true)   # Jackenfetzen sind einseitig
	_player = model.find_children("*", "AnimationPlayer", true, false)[0]


## Animation in Schleife – „chicken“ reicht für „dance_chicken“. false = gibt es nicht.
func play(anim: String) -> bool:
	if not _player.has_animation(anim):
		anim = "dance_" + anim
	if not _player.has_animation(anim):
		Game.say("Kürbismann: keine Animation „%s“ (%s)" % [anim, ", ".join(_player.get_animation_list())], 3.0)
		return false
	_player.get_animation(anim).loop_mode = Animation.LOOP_LINEAR
	_player.play(anim)
	return true
