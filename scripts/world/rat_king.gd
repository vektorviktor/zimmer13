class_name RatKing
extends StaticBody3D
## Ein Rattenkönig im Glas (Spielkonzept 4.25): sieben Ratten, deren Schwänze zu einem Knoten verwachsen sind, in trüber
## Flüssigkeit auf einem Wandbord im Müllraum des Untergeschosses. Reine Stimmung mit einem Zettel am Glas, den man
## liest ([E]) – das Hotel hebt auf, was es findet. Ort: Ausstattung „Rattenkönig“ im Plan, bis dahin FALLBACK.
## Nicht gespeichert.

## Bis der Plan einen Platz hat: Nordwand des Müllraums (x, z) im Untergeschoss, Glas mit Blick nach +Z
const FALLBACK := Vector2(-31.5, -27.75)
const SHELF_Y := 1.25
const JAR := Vector2(0.11, 0.3)             ## Halbmesser und Höhe
const LABEL := "Gefunden im Kohlenkeller, Winter 1962. Sieben Stück. Nicht wegwerfen. – A. R."
const NOTE := "Im Müllraum steht ein Glas mit einem Rattenkönig, 1962 im Kohlenkeller gefunden. „Nicht wegwerfen.“"


static func place(parent: Node3D) -> RatKing:
	var k := RatKing.new()
	k.position = Vector3(FALLBACK.x, LevelBuilder.CELLAR_Y + SHELF_Y, FALLBACK.y + 0.17)
	parent.add_child(k)
	return k


func _ready() -> void:
	collision_layer = 4
	collision_mask = 0
	set_meta("interactable", self)
	# Wandbord aus Holz mit zwei Winkeln
	var wood := Mat.psx(Color(0.33, 0.24, 0.16))
	Geo.mesh(self, Geo.box(Vector3(0.5, 0.03, 0.26)), wood, Vector3(0, -0.015, 0))
	for x in [-0.18, 0.18]:
		Geo.mesh(self, Geo.box(Vector3(0.02, 0.16, 0.02)), wood, Vector3(x, -0.1, -0.11))
	Geo.add_box_shape(self, Vector3(0.3, JAR.y, 0.26), Vector3(0, JAR.y / 2.0, 0))
	# Flüssigkeit, trüb gelblich, darin die Ratten im Kreis, Schwänze in der Mitte verknotet
	var fluid := StandardMaterial3D.new()
	fluid.albedo_color = Color(0.55, 0.5, 0.3, 0.55)
	fluid.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	fluid.roughness = 0.2
	Geo.mesh(self, Geo.cylinder(JAR.x - 0.006, JAR.y * 0.82, 16), fluid, Vector3(0, JAR.y * 0.41 + 0.005, 0))
	var fur := Mat.psx(Color(0.28, 0.24, 0.2))
	for k in 7:
		var a := TAU * k / 7.0
		var body := Geo.mesh(self, Geo.sphere(0.022, 0.07, 8, 4), fur, Vector3(cos(a) * 0.055, 0.06 + 0.025 * (k % 3), sin(a) * 0.055))
		body.rotation = Vector3(0.4, -a, PI / 2.0)
		var tail := Geo.mesh(self, Geo.cylinder(0.004, 0.06, 4), Mat.psx(Color(0.45, 0.35, 0.32)),
			Vector3(cos(a) * 0.025, 0.07 + 0.01 * (k % 2), sin(a) * 0.025))
		tail.rotation = Vector3(0, -a, PI / 2.0)
	Geo.mesh(self, Geo.sphere(0.024, 0.04, 8, 4), Mat.psx(Color(0.4, 0.32, 0.28)), Vector3(0, 0.075, 0))   # der Knoten
	var glass := Mat.glass()
	Geo.mesh(self, Geo.cylinder(JAR.x, JAR.y, 16), glass, Vector3(0, JAR.y / 2.0, 0))
	Geo.mesh(self, Geo.cylinder(JAR.x + 0.008, 0.03, 16), Mat.metal(Color(0.5, 0.45, 0.35)), Vector3(0, JAR.y + 0.012, 0))
	# Zettel am Glas
	Geo.mesh(self, Geo.box(Vector3(0.09, 0.06, 0.002)), Mat.psx(Color(0.82, 0.76, 0.6)),
		Vector3(0, JAR.y * 0.45, JAR.x + 0.002))


func get_prompt(_player: Player) -> String:
	return "Glas ansehen [E]"


func interact(_player: Player) -> void:
	Game.say("Ein Rattenkönig in trübem Spiritus. Auf dem Zettel: „%s“" % LABEL, 7.0)
	if Game.notebook:
		Game.notebook.add_note("rat_king", NOTE, "Müllraum")
