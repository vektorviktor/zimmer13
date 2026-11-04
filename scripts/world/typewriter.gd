class_name Typewriter
extends StaticBody3D
## Die Schreibmaschine der Chefsekretärin (Spielkonzept 2.11, ZIM-119) auf dem Schreibtisch im Sekretariat: schwere
## Büromaschine mit Typenhebeln, grün lackiert, Walze mit eingespanntem Blatt. Ein Typenhebel ist verbogen – das „e“
## sitzt in allem, was sie getippt hat, zu hoch (TypedPage). [E] liest das Blatt (DirectorOffice.read_typed).
## Platzhalter aus Grundkörpern wie Familienfoto und Ölkännchen (ZIM-30); ein Modell nach 9.2 fehlt noch.
## Ursprung mittig unter dem Gehäuse, +Z = Tastatur (zur Sitzseite).

const SIZE := Vector3(0.42, 0.2, 0.36)
## Lack, Gummi der Walze und Tasten, Papier
const ENAMEL := Color(0.2, 0.25, 0.22)
const RUBBER := Color(0.05, 0.05, 0.05)
const PAPER := Color(0.93, 0.92, 0.88)
const INK := Color(0.12, 0.1, 0.1)
## Tastenfeld: Reihen × Tasten, Abstand, Neigung nach vorn
const KEY_ROWS := 4
const KEYS_PER_ROW := 11
const KEY_PITCH := 0.026
const DECK_TILT := 0.28

var office: DirectorOffice


func _ready() -> void:
	collision_layer = 4
	collision_mask = 0
	set_meta("interactable", self)
	add_to_group("typewriters")
	_build()


func _build() -> void:
	var enamel := Mat.psx(ENAMEL)
	var chrome := Mat.metal()
	var rubber := Mat.psx(RUBBER)
	Geo.mesh(self, Geo.box(Vector3(SIZE.x, 0.05, SIZE.z)), enamel, Vector3(0, 0.025, 0))   # Fuß
	Geo.mesh(self, Geo.box(Vector3(0.4, 0.06, 0.17)), enamel, Vector3(0, 0.08, -0.08))     # Gehäuse mit Typenkorb
	Geo.mesh(self, Geo.box(Vector3(0.2, 0.012, 0.05)), Mat.psx(Color(0.08, 0.08, 0.07)), Vector3(0, 0.111, -0.01))   # Typenkorb-Schacht
	# Tastenfeld: nach vorn geneigt, vier Reihen runder Tasten, davor die Leertaste
	var deck := Node3D.new()
	deck.position = Vector3(0, 0.062, 0.09)
	deck.rotation.x = DECK_TILT
	add_child(deck)
	Geo.mesh(deck, Geo.box(Vector3(0.38, 0.012, 0.16)), enamel, Vector3.ZERO)
	for r in KEY_ROWS:
		var shift := (r % 2) * KEY_PITCH * 0.5
		for k in KEYS_PER_ROW - (1 if r == 0 else 0):
			var x := (k - (KEYS_PER_ROW - 1) / 2.0) * KEY_PITCH + shift
			Geo.mesh(deck, Geo.cylinder(0.0085, 0.01, 10), rubber, Vector3(x, 0.011, -0.055 + r * 0.03))
			Geo.mesh(deck, Geo.cylinder(0.0092, 0.002, 10), chrome, Vector3(x, 0.006, -0.055 + r * 0.03))   # Ring
	Geo.mesh(deck, Geo.box(Vector3(0.17, 0.008, 0.018)), rubber, Vector3(0, 0.01, 0.068))   # Leertaste
	# Wagen mit Walze, Drehknöpfen und Zeilenschalthebel
	Geo.mesh(self, Geo.box(Vector3(0.46, 0.03, 0.07)), enamel, Vector3(0, 0.125, -0.12))
	var platen := Geo.mesh(self, Geo.cylinder(0.024, 0.4, 16), rubber, Vector3(0, 0.162, -0.112))
	platen.rotation.z = PI / 2.0
	for side: float in [-1.0, 1.0]:
		var knob := Geo.mesh(self, Geo.cylinder(0.019, 0.022, 14), rubber, Vector3(side * 0.222, 0.162, -0.112))
		knob.rotation.z = PI / 2.0
	var bail := Geo.mesh(self, Geo.cylinder(0.003, 0.32, 8), chrome, Vector3(0, 0.178, -0.088))   # Papierhalter
	bail.rotation.z = PI / 2.0
	var lever := Geo.mesh(self, Geo.box(Vector3(0.012, 0.006, 0.08)), chrome, Vector3(-0.235, 0.17, -0.07))
	lever.rotation.y = 0.5
	# Eingespanntes Blatt: steht hinter der Walze, leicht nach hinten geneigt, unter dem Briefkopf zwei getippte Zeilen
	var sheet := Geo.mesh(self, Geo.box(Vector3(0.21, 0.17, 0.0015)), Mat.psx(PAPER), Vector3(0, 0.235, -0.13))
	sheet.rotation.x = -0.22
	var ink := Mat.psx(INK)
	for i in 2:
		Geo.mesh(sheet, Geo.box(Vector3(0.11 if i == 0 else 0.15, 0.003, 0.0006)), ink,
			Vector3(-0.03 + (0.0 if i == 0 else 0.02), 0.03 - i * 0.01, 0.001))
	Geo.mesh(sheet, Geo.box(Vector3(0.05, 0.012, 0.0006)), Mat.psx(Color(0.45, 0.1, 0.08)), Vector3(0, 0.06, 0.001))   # Briefkopf
	Geo.add_box_shape(self, SIZE, Vector3(0, SIZE.y / 2.0, 0))


func get_prompt(_player: Player) -> String:
	return "Schreibmaschine ansehen [E]"


func interact(_player: Player) -> void:
	if office:
		office.read_typed(DirectorOffice.MACHINE_DOC, DirectorOffice.MACHINE_TITLE, DirectorOffice.MACHINE_TEXT,
			DirectorOffice.MACHINE_JOT, "Sekretariat")
