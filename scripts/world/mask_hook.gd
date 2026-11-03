class_name MaskHook
extends StaticBody3D
## Ein Stift der Maskensammlung in Zimmer 13 (Spielkonzept 5.19, ZIM-128): gedrechselter Holzstift auf dem
## Maskenboard (MaskBoard), ohne Namensschild – ein leerer Stift zeigt nur, dass eine Maske fehlt, nicht welche. [E]
## nimmt die Maske in die Hand, mit ihr in der Hand hängt [E] sie zurück; jede Maske passt nur an ihren eigenen Stift.
## Gebaut von MaskBoard, lokale +Z zeigt von der Wand weg, Ursprung auf der Füllung am Fuß des Stifts. Solange die
## Verstecke fehlen, hängen die Masken mit Modell von Anfang an (MaskModel.has_model). Gespeichert unter „mask_hooks“
## (je Maske, ob sie hängt).

var mask_id := ""
var hanging := false

var _mask: Node3D


func setup(id: String) -> MaskHook:
	mask_id = id
	hanging = MaskModel.has_model(id)
	return self


func _ready() -> void:
	add_to_group("mask_hooks")
	collision_layer = 1
	collision_mask = 0
	set_meta("interactable", self)
	var peg := MeshInstance3D.new()
	peg.mesh = MaskBoard.mesh("peg")
	peg.material_override = MaskBoard.material()
	add_child(peg)
	_mask = MaskModel.build(mask_id)
	# hängt mit dem Band über dem Schaft, oben vom Stift abgehalten, unten liegt sie am Board
	var size: Vector3 = MaskModel.SIZES.get(mask_id, Vector3(0.2, 0.26, 0.1))
	_mask.position = Vector3(0, -0.015 - size.y / 2.0, size.z / 2.0 + 0.004)
	_mask.rotation.x = -0.06
	add_child(_mask)
	Geo.add_box_shape(self, Vector3(0.24, 0.34, 0.11), Vector3(0, -0.13, 0.055))
	_update()


func get_prompt(player: Player) -> String:
	var name := MaskModel.display_name(mask_id)
	if hanging:
		return "%s nehmen [E]" % name if player.held == null and player.carried_cat == null else "Hände voll"
	if player.held and player.held.kind == Item.Kind.MASK:
		return "%s aufhängen [E]" % name if player.held.mask_id == mask_id else "Hier gehört sie nicht hin"
	return "Leerer Stift"


func interact(player: Player) -> void:
	if hanging:
		if player.held != null or player.carried_cat != null:
			return
		hanging = false
		_update()
		player.receive_item(Item.create(Item.Kind.MASK, mask_id))
	elif player.held and player.held.kind == Item.Kind.MASK and player.held.mask_id == mask_id:
		player.consume_held()
		hanging = true
		_update()


func set_hanging(value: bool) -> void:
	hanging = value
	_update()


func _update() -> void:
	_mask.visible = hanging
