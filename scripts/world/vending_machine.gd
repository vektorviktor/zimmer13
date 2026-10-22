class_name VendingMachine
extends StaticBody3D
## Snack- und Cola-Automat (Spielkonzept 3.2, 6.13): Für PRICE Geld gibt der Snackautomat Süßigkeiten, der Colaautomat
## eine Dose Cola – unbegrenzt. Die beleuchtete Front ist ein schwaches Licht im Flur (zählt in light_at). Steht auf
## Ebene 1 (im NavMesh, Gäste gehen außen herum). Lokale +Z = Front. Kein Zustand, nicht gespeichert.
## Aufgestellt von ExtraFixtures.

const PRICE := 1
const SIZE := Vector3(0.85, 1.8, 0.7)
const KINDS := {
	"snack": {"label": "Snackautomat", "item": Item.Kind.SWEETS, "extra": "", "what": "Süßigkeiten", "body": Color(0.12, 0.2, 0.45),
		"sign": "SNACKS", "glow": Color(0.75, 0.85, 1.0)},
	"cola": {"label": "Colaautomat", "item": Item.Kind.SODA_CAN, "extra": "cola", "what": "eine Cola", "body": Color(0.62, 0.06, 0.06),
		"sign": "COLA", "glow": Color(1.0, 0.85, 0.8)},
}

var kind := "snack"


func setup(p_kind: String) -> VendingMachine:
	kind = p_kind
	return self


func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	set_meta("interactable", self)
	add_to_group("vending_machines")
	var d: Dictionary = KINDS[kind]
	var body := Mat.psx(d["body"])
	var dark := Mat.psx(Color(0.06, 0.06, 0.07))
	var glow := Mat.psx(Color(0.1, 0.1, 0.12), "", 1.0, d["glow"], 0.9)
	Geo.box_part(self, SIZE, Vector3(0, SIZE.y / 2.0, 0), body)
	# Front: beleuchtetes Fenster mit Fächern (links) und Bedienfeld (rechts), unten der Ausgabeschacht
	var front := SIZE.z / 2.0 + 0.005
	Geo.mesh(self, Geo.box(Vector3(0.52, 1.1, 0.01)), glow, Vector3(-0.1, 1.08, front))
	var colors: Array = [Color(0.85, 0.2, 0.15), Color(0.95, 0.75, 0.15), Color(0.25, 0.6, 0.3), Color(0.55, 0.25, 0.7)] \
		if kind == "snack" else [Item.SODA_COLORS["cola"]]
	for row in 5:
		Geo.mesh(self, Geo.box(Vector3(0.5, 0.012, 0.03)), dark, Vector3(-0.1, 0.6 + row * 0.21, front + 0.012))
		for col in 4:
			var c: Color = colors[(row + col) % colors.size()]
			var pack: Mesh = Geo.box(Vector3(0.07, 0.11, 0.03)) if kind == "snack" else Geo.cylinder(0.03, 0.11, 6)
			Geo.mesh(self, pack, Mat.psx(c), Vector3(-0.29 + col * 0.125, 0.67 + row * 0.21, front + 0.02))
	Geo.mesh(self, Geo.box(Vector3(0.2, 1.1, 0.01)), dark, Vector3(0.29, 1.08, front))
	for i in 3:
		Geo.mesh(self, Geo.box(Vector3(0.05, 0.03, 0.012)), Mat.psx(Color(0.75, 0.75, 0.7)), Vector3(0.29, 1.3 - i * 0.07, front + 0.006))
	Geo.mesh(self, Geo.box(Vector3(0.03, 0.08, 0.012)), Mat.psx(Color(0.8, 0.7, 0.3)), Vector3(0.29, 1.0, front + 0.006))   # Münzschlitz
	Geo.mesh(self, Geo.box(Vector3(0.6, 0.16, 0.012)), dark, Vector3(-0.05, 0.28, front))
	# Schild oben
	var sign := Label3D.new()
	sign.text = d["sign"]
	sign.font_size = 48
	sign.pixel_size = 0.0028
	sign.modulate = Color(1, 1, 1)
	sign.outline_size = 8
	sign.outline_modulate = Color(0, 0, 0)
	sign.position = Vector3(0, 1.7, front + 0.01)
	add_child(sign)
	var light := OmniLight3D.new()
	light.light_color = d["glow"]
	light.light_energy = 0.35
	light.omni_range = 2.5
	light.position = Vector3(0, 1.1, front + 0.4)
	light.add_to_group("light_source")   # schwaches Licht im Flur (MonsterDirector.light_at)
	add_child(light)


func get_prompt(player: Player) -> String:
	var d: Dictionary = KINDS[kind]
	if not player.can_take(d["item"]):
		return "%s – Hände voll" % d["label"]
	if Game.money < PRICE:
		return "%s – %d Geld, so viel hast du nicht" % [d["label"], PRICE]
	return "%s: %s kaufen – %d Geld [E]" % [d["label"], d["what"], PRICE]


func interact(player: Player) -> void:
	var d: Dictionary = KINDS[kind]
	if Game.money < PRICE or not player.can_take(d["item"]):
		return
	Game.money -= PRICE
	Game.noise("drop_heavy", global_position + Vector3.UP * 0.3, player)   # es poltert in den Ausgabeschacht
	player.receive_item(Item.create(d["item"], d["extra"]))
