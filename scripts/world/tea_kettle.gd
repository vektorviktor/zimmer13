class_name TeaKettle
extends CoffeeMachine
## Wasserkocher in der Küche (Spielkonzept 3.12), auf der Küchenzeile rechts neben der Kaffeemaschine: [E] mit leeren
## Händen – das Wasser rauscht KETTLE_TIME Sekunden (Lärm „kettle“), dann pfeift er leise (Lärm „kettle_whistle“) und neben
## ihm steht eine Tasse Kräutertee (Item.Kind.TEA). Umsonst. Abends (18–23 Uhr) holen sich Gäste hier Tee, auch Kinder.
## Sonst wie die Kaffeemaschine (CoffeeMachine). Erreichbar über Game.kettle.

const KETTLE_TIME := 15.0
const KETTLE_LINES := ["Ein Tee zum Runterkommen.", "Kamille – dann schlaf ich besser.", "Noch ein Tee vor dem Schlafengehen.",
	"Darf ich auch einen? Mit Honig?"]
## Die Tasse steht rechts neben dem Kocher
const KETTLE_CUP := Vector3(0.13, 0.0, 0.03)


func _init() -> void:
	drink_kind = Item.Kind.TEA
	brew_time = KETTLE_TIME
	noise_kind = "kettle"
	guest_phase = Calendar.Phase.EVENING
	children = true
	lines = KETTLE_LINES
	cup_spot = KETTLE_CUP
	texts = {"name": "Wasserkocher", "brewing": "Das Wasser rauscht", "make": "Tee kochen",
		"start": "Das Wasser beginnt zu rauschen.", "done": "Der Tee ist fertig.", "trace": "Tee",
		"drinks": "trinkt Tee am Wasserkocher", "to": "zum Wasserkocher"}


func _register() -> void:
	Game.kettle = self


## Weißer Kocher auf dem Sockel, Tülle nach rechts, Henkel links; daneben (cup_spot) ist Platz für die Tasse.
func _build() -> void:
	var shell := Mat.psx(Color(0.86, 0.85, 0.82))
	var dark := Mat.psx(Color(0.15, 0.15, 0.16))
	Geo.mesh(self, Geo.cylinder(0.075, 0.015, 10), dark, Vector3(-0.03, 0.0075, 0))                 # Sockel
	Geo.mesh(self, Geo.cylinder(0.065, 0.19, 10), shell, Vector3(-0.03, 0.11, 0))                   # Kanne
	Geo.mesh(self, Geo.cylinder(0.045, 0.012, 10), dark, Vector3(-0.03, 0.21, 0))                   # Deckel
	var spout := Geo.mesh(self, Geo.box(Vector3(0.05, 0.025, 0.03)), shell, Vector3(0.045, 0.17, 0))   # Tülle
	spout.rotation.z = 0.5
	Geo.mesh(self, Geo.box(Vector3(0.02, 0.15, 0.03)), dark, Vector3(-0.11, 0.12, 0))               # Henkel
	Geo.mesh(self, Geo.box(Vector3(0.04, 0.02, 0.03)), dark, Vector3(-0.09, 0.19, 0))
	Geo.add_box_shape(self, Vector3(0.17, 0.22, 0.14), Vector3(-0.03, 0.11, 0))


func _steam_spot() -> Vector3:
	return Vector3(0.065, 0.2, 0)   # aus der Tülle


func _finished() -> void:
	Game.noise("kettle_whistle", global_position, self)
