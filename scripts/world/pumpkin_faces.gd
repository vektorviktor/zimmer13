class_name PumpkinFaces
extends Node
## Kürbisgesichter, die sich verändern (Spielkonzept 5.18) – eine Halluzination wie das Rauschen ohne Monster (4.13).
## Unter Schock (ab SHOCK) oder in einer Halluzination grinst ab und zu ein geschnitzter Kürbis in der Nähe anders, wenn
## man wieder hinsieht: Das Netz tauscht gegen eine andere Fratze (PumpkinModel.mesh_of), nur, solange der Spieler ihn
## nicht ansieht. Sieht man es aus der Nähe, stutzt man (ein kleiner Schreck). Ist der Schock vorbei, haben sie ihr
## Gesicht wieder, sobald man wegsieht. Nur fürs Bild: Item.face (gespeichert) bleibt, wie es ist – darum nichts zu
## speichern. Kürbisse ohne Modell (Grundkörper-Sorten) haben kein Fratzennetz und bleiben, wie sie sind.

const SHOCK := 0.35
const RANGE := 15.0
const CHANGE_EVERY := Vector2(12.0, 30.0)
const NOTICE_RANGE := 4.5
const NOTICE_SHOCK := 0.05
const LINES := ["Hatte der Kürbis nicht eben ein anderes Gesicht?", "Der Kürbis … grinst er jetzt breiter?",
	"Das war doch eben noch ein freundliches Gesicht."]

var _swapped := {}                     ## Item → {mesh_instance, true_mesh, noticed}
var _timer := 8.0
var _check := 0.0


func _process(delta: float) -> void:
	var p := Game.player
	var d := Game.director
	if p == null or d == null:
		return
	var spooked := p.shock >= SHOCK or d.is_hallucinating()
	_timer -= delta
	if spooked and _timer <= 0.0:
		_timer = randf_range(CHANGE_EVERY.x, CHANGE_EVERY.y)
		_swap_one(p)
	_check -= delta
	if _check > 0.0:
		return
	_check = 0.4
	for item in _swapped.keys():
		var e: Dictionary = _swapped[item]
		if not is_instance_valid(item) or not is_instance_valid(e["mesh"]):
			_swapped.erase(item)
			continue
		var seen := d.player_can_see((item as Item).global_position + Vector3.UP * 0.2)
		if not spooked and not seen:   # vorbei – das alte Gesicht, wenn niemand hinsieht
			(e["mesh"] as MeshInstance3D).mesh = e["true"]
			_swapped.erase(item)
			continue
		if seen and not e["noticed"] and p.global_position.distance_to((item as Item).global_position) < NOTICE_RANGE:
			e["noticed"] = true
			p.shock = minf(1.0, p.shock + NOTICE_SHOCK)
			Game.say(LINES.pick_random(), 3.0)


## Ein geschnitzter Kürbis in der Nähe, den der Spieler gerade nicht sieht, bekommt eine andere Fratze.
func _swap_one(p: Player) -> void:
	var d := Game.director
	var candidates: Array[Item] = []
	for node in get_tree().get_nodes_in_group("items"):
		var item := node as Item
		if item.kind != Item.Kind.CARVED_PUMPKIN or item.is_held or _swapped.has(item) or not PumpkinModel.has_model(item.variety) \
				or item.global_position.distance_to(p.global_position) > RANGE \
				or d.player_can_see(item.global_position + Vector3.UP * 0.2):
			continue
		candidates.append(item)
	if candidates.is_empty():
		return
	var item: Item = candidates.pick_random()
	var true_mesh := PumpkinModel.mesh_of(item.face)
	for child in item.get_children():
		var mi := child as MeshInstance3D
		if mi and mi.mesh == true_mesh:
			var other := 1 + (item.face + randi_range(0, PumpkinModel.FACES - 2)) % PumpkinModel.FACES
			mi.mesh = PumpkinModel.mesh_of(other)
			_swapped[item] = {"mesh": mi, "true": true_mesh, "noticed": false}
			if Game.tracing:
				print("[Kürbisgesichter] Fratze %d → %d" % [item.face, other])
			return


## Debug (--fratzen): unter Schock, drei geschnitzte Kürbisse 2 m vor dir – dreh dich um und wieder zurück.
func debug() -> void:
	var p := Game.player
	p.shock = 0.6
	var fwd := -p.global_transform.basis.z
	for k in 3:
		var pumpkin := Item.create(Item.Kind.CARVED_PUMPKIN, "lit,f=%d" % (k + 1))
		Game.social.builder.world.add_child(pumpkin)
		pumpkin.global_position = p.global_position + fwd * 2.0 + fwd.cross(Vector3.UP) * (k - 1) * 0.6 + Vector3.UP * 0.1
		pumpkin.rotation.y = p.rotation.y
	_timer = 3.0
