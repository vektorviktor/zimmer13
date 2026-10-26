class_name MaskHook
extends StaticBody3D
## Ein Haken der Maskensammlung in Zimmer 13 (Spielkonzept 5.19): acht Messinghaken nebeneinander, unter jedem ein
## Schildchen mit dem Namen seiner Maske – ein leerer Haken zeigt, was noch fehlt. [E] nimmt die Maske in die Hand,
## mit ihr in der Hand hängt [E] sie zurück; jede Maske passt nur an ihren eigenen Haken. Gebaut von
## LevelBuilder._mask_hooks, lokale +Z zeigt von der Wand weg, Ursprung am Hakenende. Solange die Verstecke fehlen,
## hängen die Masken mit Modell von Anfang an (MaskModel.has_model). Gespeichert unter „mask_hooks“ (je Maske, ob sie
## hängt).

## So weit (m) liegen die Haken auseinander – passt die Wand nicht, rücken sie zusammen
const SPACING := 0.3
## Höhe des Hakens über dem Boden (m)
const HEIGHT := 1.85
const BRASS := Color(0.78, 0.62, 0.28)

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
	var brass := Mat.metal(BRASS)
	Geo.mesh(self, Geo.cylinder(0.012, 0.006, 8), brass, Vector3(0, 0, -0.03)).rotation.x = PI / 2.0   # Rosette
	Geo.mesh(self, Geo.box(Vector3(0.008, 0.008, 0.035)), brass, Vector3(0, 0, -0.015))
	Geo.mesh(self, Geo.box(Vector3(0.008, 0.025, 0.008)), brass, Vector3(0, 0.01, 0))   # aufgebogene Spitze
	# Schildchen unter der Maske
	var plate_y := -0.06 - float(MaskModel.SIZES.get(mask_id, Vector3(0.2, 0.26, 0.1)).y) - 0.06
	Geo.mesh(self, Geo.box(Vector3(0.16, 0.035, 0.004)), brass, Vector3(0, plate_y, -0.031))
	var label := Label3D.new()
	label.text = MaskModel.display_name(mask_id)
	label.font_size = 24
	label.pixel_size = 0.0004
	label.modulate = Color(0.18, 0.12, 0.05)
	label.outline_size = 0
	label.position = Vector3(0, plate_y, -0.028)
	add_child(label)
	_mask = MaskModel.build(mask_id)
	_mask.position = Vector3(0, -0.02 - float(MaskModel.SIZES.get(mask_id, Vector3.ZERO).y) / 2.0, -0.025)
	_mask.rotation.x = -0.06   # oben am Haken, unten liegt sie an der Wand
	add_child(_mask)
	Geo.add_box_shape(self, Vector3(0.22, 0.36, 0.1), Vector3(0, -0.16, -0.02))
	_update()


func get_prompt(player: Player) -> String:
	var name := MaskModel.display_name(mask_id)
	if hanging:
		return "%s nehmen [E]" % name if player.held == null and player.carried_cat == null else "Hände voll"
	if player.held and player.held.kind == Item.Kind.MASK:
		return "%s aufhängen [E]" % name if player.held.mask_id == mask_id else "Hier hängt die %s" % name
	return "Leerer Haken: %s" % name


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
