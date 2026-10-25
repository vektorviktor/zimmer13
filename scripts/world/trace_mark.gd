class_name TraceMark
extends StaticBody3D
## Eine bleibende Spur des Monsters (Spielkonzept 4.13): Kratzspuren, Blut, Handabdruck.
## Lokale +Z zeigt von der Fläche weg (zum Betrachter). Spuren rund um Zimmer 13
## kann der Spieler wegwischen.

const WIPE_RANGE := 4.5   ## so nah an der Tür von Zimmer 13 darf man putzen
## Blutlache aus Einzelflecken, die auf die Fläche darunter fallen (Boden, Stufe, Tischplatte): so viele, so weit um
## das Opfer (m), auf Treppen zusätzlich bis so weit die Stufen hinunter
const BLOOD_SPLATS := Vector2i(18, 28)
const BLOOD_RADIUS := 1.8
const BLOOD_DOWNHILL := 1.8
## Fleckgröße (m): die großen in der Mitte, die kleinen drumherum
const BLOOD_BIG := Vector2(0.45, 0.75)
const BLOOD_SMALL := Vector2(0.12, 0.35)
## So weit darf die Fläche unter einem Fleck in der Höhe abweichen (m) – sonst ragt er über eine Stufen- oder Möbelkante
const BLOOD_FLAT := 0.02
## Zug der Flecken am Boden zur Kamera (Blut, Wachs, Kürbismatsch – Anteil der Kameraentfernung): mehr als Auflagen
## am Boden (Mat.layer 0,01, Treppenläufer der Lobby), sonst decken die sie zu
const SPLAT_PULL := 0.014
## Flecken längs auf einer Stufe überlappen sich zu diesem Anteil ihrer Breite (lay_decal)
const DECAL_OVERLAP := 0.45
## Kern eines großen Wachsflecks (m), die Tropfen liegen drumherum
const WAX_CORE := Vector2(0.4, 0.4)
## Kaffeefleck einer zerbrochenen Tasse (Spielkonzept 3.11): Kern (m), so viele Spritzer, aus der Wachsgrafik in
## Kaffeebraun, nass glänzend und dünn
const COFFEE_CORE := Vector2(0.32, 0.28)
const COFFEE_DROPS := Vector2i(6, 10)
const COFFEE_TINT := Color(0.3, 0.16, 0.07)
## Teefleck (3.12): wie der Kaffeefleck, heller und goldbraun
const TEA_TINT := Color(0.72, 0.5, 0.2)
const COFFEE_LOOK := {"specular": 0.6, "normal_strength": 0.4, "edge_alpha": 0.45, "thick_shade": 0.6, "grain": 0.04}
## Grafiken der Flecken am Boden (Umriss aus dem Alpha, psx_decal) – Blutlache und Kern des Wachsflecks
const BLOOD_TEXTURE := "res://assets/textures/blood_pool.png"
const WAX_TEXTURE := "res://assets/textures/wax_splash.png"
## Look je Grafik (psx_decal, Karten aus tools/splat_maps.gd): Glanz, Stärke der Normal Map, Deckkraft am dünnen Rand,
## Farbe der dicken Mitte, Rauschen auf der Farbe. Blut nass glänzend, am Rand dünn und hell; Wachs matter Schimmer,
## Rand durchscheinend; Kürbismatsch breiig: matt, klumpig, deckend.
const SPLAT_LOOK := {
	BLOOD_TEXTURE: {"specular": 0.5, "normal_strength": 1.0, "edge_alpha": 0.55, "thick_shade": 0.55, "grain": 0.12},
	WAX_TEXTURE: {"specular": 0.35, "normal_strength": 1.0, "edge_alpha": 0.7, "thick_shade": 0.92, "grain": 0.08},
	Item.MUSH_TEXTURE: {"specular": 0.2, "normal_strength": 1.6, "edge_alpha": 0.92, "thick_shade": 0.7, "grain": 0.35},
}
## Frische Flecken breiten sich aus und laufen die Treppe hinunter (Spielzeit – Tweens pausieren mit dem Spiel): je Art
## Fließtempo über eine ebene Fläche (m/s), Dauer, bis ein großer bzw. kleiner Fleck ganz liegt (s), Zeit je Stufe
## hinunter und davon für die Bahn an der Stirnseite (s), auf Treppen ein durchgehender Strom (lay_stream) über höchstens
## so viele Stufen, so breit (m), unten eine Pfütze so groß (m). Blut breitet sich in etwa 30 s aus, Kürbismatsch liegt
## sofort und läuft nach, Wachs ist in 2 s erstarrt (nur ein kurzer Strom).
const SPREAD := {
	"blood": {"flow": 0.12, "grow_big": Vector2(8.0, 14.0), "grow_small": Vector2(3.0, 6.0), "step": 2.5, "run": 1.5,
		"stream_steps": 20, "stream_w": Vector2(0.1, 0.15), "puddle": Vector2(0.6, 0.9)},
	"mush": {"flow": 3.0, "grow_big": Vector2(0.15, 0.25), "grow_small": Vector2(0.15, 0.3), "step": 1.6, "run": 1.4,
		"stream_steps": 20, "stream_w": Vector2(0.11, 0.16), "puddle": Vector2(0.4, 0.7)},
	"wax": {"flow": 0.4, "grow_big": Vector2(0.8, 1.2), "grow_small": Vector2(0.3, 0.6), "step": 0.8, "run": 0.5,
		"stream_steps": 3, "stream_w": Vector2(0.05, 0.08), "puddle": Vector2(0.15, 0.25)},
	"coffee": {"flow": 1.2, "grow_big": Vector2(0.4, 0.7), "grow_small": Vector2(0.2, 0.4), "step": 1.0, "run": 0.7,
		"stream_steps": 10, "stream_w": Vector2(0.05, 0.08), "puddle": Vector2(0.2, 0.35)},
}
## Geworfenes an der Wand (Spielkonzept 3.13, Traces.add_wall_splash, _spread_wall): je Flüssigem der Fleck (m;
## Kürbis: halber Spritzer der Sorte), der Strom herunter (m/s, Breite m) und die Pfütze am Boden (m)
const WALL_SPLASH := {
	"mush": {"splat": 0.5, "speed": 0.35, "width": Vector2(0.05, 0.08), "puddle": Vector2(0.25, 0.4)},
	"wax": {"splat": 0.2, "speed": 0.5, "width": Vector2(0.025, 0.04), "puddle": Vector2(0.1, 0.16)},
	"coffee": {"splat": 0.26, "speed": 0.6, "width": Vector2(0.03, 0.05), "puddle": Vector2(0.18, 0.28)},
}
const WALL_COFFEE_SPECULAR := 0.15
## Ungefähre Stufenhöhe (m) – zählt beim Ausbreiten die Stufen hinunter
const STEP_RISE := 0.2
## Strom die Treppe hinunter (lay_stream): die Quadrate der Kette liegen so weit auseinander (× ihre Kantenlänge, sie
## überlappen) und wachsen jedes so schnell (s)
const STREAM_SPACING := 0.5
const STREAM_GROW := 0.4
const NAMES := {"scratch": "Kratzspuren", "blood": "Blutspuren", "handprint": "Ein Handabdruck",
	"wax": "Wachsflecken", "drops": "Blutstropfen", "wax_splash": "Ein großer Wachsfleck", "soot": "Ein Rußfleck",
	"coffee": "Ein Kaffeefleck", "tea": "Ein Teefleck",
	"bloody_hand": "Blutige Handabdrücke", "wall_splatter": "Blutspritzer", "wall_smear": "Eine blutige Schmierspur",
	"splash_mush": "Kürbismatsch an der Wand", "splash_wax": "Wachs an der Wand", "splash_coffee": "Kaffee an der Wand",
	"splash_tea": "Tee an der Wand"}

var kind := "scratch"
## Gemeinsam für alle Spuren: Ebene 1 × 1 und die Materialien der Textur-Flecken (lay_decal)
static var _decal_plane: PlaneMesh
static var _runner_plane: PlaneMesh
static var _decal_mats := {}
static var _coffee_mat: ShaderMaterial
static var _tea_mat: ShaderMaterial
static var _wall_plane: PlaneMesh
static var _mush_mats := {}   ## an der Wand: Kürbismatsch je Sorte, dazu „coffee“ und „tea“ (_wall_material)
## Auf Türen nicht anklickbar (sonst ließe sich die Tür nicht mehr öffnen) – bleibt dort.
var solid := true
## Gerade entstanden (Traces.add_blood, add_guest_drop): Blut und Wachs breiten sich aus (SPREAD); aus dem Spielstand
## liegen sie gleich fertig da
var fresh := false
## Im Regen verwaschen (Blut, großer Wachsfleck draußen – RainVeil): 0 … 1, bei 1 wird er zum Schleier
var wash := 0.0


func setup(p_kind: String) -> TraceMark:
	kind = p_kind
	return self


func _ready() -> void:
	collision_layer = 4 if solid else 0
	collision_mask = 0
	if solid:
		set_meta("interactable", self)
	add_to_group("trace_marks")
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(str(get_instance_id()))
	match kind:
		"scratch":
			var dark := Mat.psx(Color(0.06, 0.03, 0.02))
			for i in 4:
				var line := Geo.mesh(self, Geo.box(Vector3(0.025, 0.55, 0.006)), dark, Vector3(-0.09 + i * 0.06, -i * 0.02, 0.004))
				line.rotation.z = 0.25 + rng.randf_range(-0.05, 0.05)
			Geo.add_box_shape(self, Vector3(0.35, 0.6, 0.05), Vector3.ZERO)
		"blood":
			# Ursprung = Boden unter dem Opfer; die Flecken fallen erst, wenn die Spur steht (beim Laden wird die Lage
			# nach add_child gesetzt) – jedes Mal anders verteilt
			Geo.add_box_shape(self, Vector3(1.6, 0.05, 1.6), Vector3(0, 0.025, 0))
			_spread_blood.call_deferred()
		"bloody_hand":
			# Lange Finger, verschmiert, mit Läufern nach unten (Lakengeist, 4.18)
			var blood := Mat.psx(Color(0.35, 0.03, 0.03))
			Geo.mesh(self, Geo.box(Vector3(0.1, 0.11, 0.003)), blood, Vector3(0, -0.04, 0))
			for i in 5:
				var finger := Geo.mesh(self, Geo.box(Vector3(0.018, rng.randf_range(0.11, 0.17), 0.003)), blood,
					Vector3(-0.045 + i * 0.022, 0.07 + rng.randf_range(-0.01, 0.02), 0))
				finger.rotation.z = (i - 2) * 0.12 if i > 0 else 0.7
			for i in 3:
				Geo.mesh(self, Geo.box(Vector3(0.008, rng.randf_range(0.08, 0.25), 0.003)), blood,
					Vector3(rng.randf_range(-0.04, 0.04), -0.15 - rng.randf_range(0.0, 0.08), 0))
		"wall_splatter":
			# Blut an der Wand, wo jemand geholt wurde: ein unregelmäßiger dunkler Kern, Kleckse und Spritzer nach außen,
			# Läufer nach unten
			var blood := Mat.psx(Color(0.32, 0.02, 0.02))
			var dark := Mat.psx(Color(0.17, 0.01, 0.01))
			for i in 4:
				var core := Geo.mesh(self, Geo.box(Vector3(rng.randf_range(0.1, 0.2), rng.randf_range(0.08, 0.16), 0.003)), dark,
					Vector3(rng.randf_range(-0.05, 0.05), rng.randf_range(-0.04, 0.04), 0.002 + i * 0.0005))
				core.rotation.z = rng.randf() * TAU
			for i in rng.randi_range(14, 20):
				var a := rng.randf() * TAU
				var d := rng.randf_range(0.1, 0.5)
				var s := rng.randf_range(0.015, 0.08) * (1.3 - d)
				var blob := Geo.mesh(self, Geo.box(Vector3(s * rng.randf_range(1.0, 2.5), s, 0.003)), blood,
					Vector3(cos(a) * d, sin(a) * d * 0.8, 0.004))
				blob.rotation.z = a   # Spritzer zeigen vom Kern weg
			for i in rng.randi_range(4, 6):
				var length := rng.randf_range(0.15, 0.6)
				Geo.mesh(self, Geo.box(Vector3(rng.randf_range(0.01, 0.022), length, 0.003)), blood,
					Vector3(rng.randf_range(-0.14, 0.14), -0.05 - length / 2.0, 0.005))
			Geo.add_box_shape(self, Vector3(0.8, 0.9, 0.05), Vector3(0, -0.1, 0))
		"wall_smear":
			# Eine blutige Hand, die an der Wand hinuntergerutscht ist: Abdruck oben, darunter vier Fingerstreifen, die
			# nach unten dünner und blasser werden
			var blood := Mat.psx(Color(0.3, 0.02, 0.02))
			Geo.mesh(self, Geo.box(Vector3(0.11, 0.12, 0.003)), blood, Vector3(0, 0, 0.003))
			var thumb := Geo.mesh(self, Geo.box(Vector3(0.025, 0.07, 0.003)), blood, Vector3(0.07, 0.0, 0.003))
			thumb.rotation.z = -0.6
			var drift := rng.randf_range(-0.1, 0.1)
			var length := rng.randf_range(0.5, 0.8)
			for i in 4:
				var x := -0.036 + i * 0.024
				var finger := Geo.mesh(self, Geo.box(Vector3(0.02, 0.08, 0.003)), blood, Vector3(x, 0.09, 0.003))
				finger.rotation.z = (i - 1.5) * 0.06
				for j in 4:   # Streifen in Stücken, damit sie blasser werden
					var t := float(j) / 3.0
					var piece := Geo.mesh(self, Geo.box(Vector3(lerpf(0.018, 0.008, t), length / 4.0, 0.003)),
						Mat.psx(Color(0.3, 0.02, 0.02).lerp(Color(0.22, 0.08, 0.06), t)),
						Vector3(x + drift * (j + 0.5) / 4.0, -0.06 - length * (j + 0.5) / 4.0, 0.002))
					piece.rotation.z = -drift * 0.4
			Geo.add_box_shape(self, Vector3(0.3, 1.0, 0.05), Vector3(0, -0.35, 0))
		"handprint":
			var smudge := Mat.psx(Color(0.12, 0.07, 0.06))
			Geo.mesh(self, Geo.box(Vector3(0.09, 0.1, 0.004)), smudge, Vector3(0, -0.02, 0.002))
			for i in 4:
				var finger := Geo.mesh(self, Geo.box(Vector3(0.018, 0.07, 0.004)), smudge, Vector3(-0.033 + i * 0.022, 0.065, 0.002))
				finger.rotation.z = (i - 1.5) * 0.08
			var thumb := Geo.mesh(self, Geo.box(Vector3(0.02, 0.06, 0.004)), smudge, Vector3(0.06, -0.01, 0.002))
			thumb.rotation.z = -0.7
			Geo.add_box_shape(self, Vector3(0.18, 0.2, 0.05), Vector3.ZERO)
		"wax":
			# Spur eines Gastes: getropftes Kerzenwachs
			var wax := Mat.psx(Color(0.9, 0.85, 0.7))
			for i in rng.randi_range(2, 4):
				Geo.mesh(self, Geo.box(Vector3(rng.randf_range(0.02, 0.05), rng.randf_range(0.02, 0.05), 0.005)), wax,
					Vector3(rng.randf_range(-0.08, 0.08), rng.randf_range(-0.08, 0.08), 0.0025))
			Geo.add_box_shape(self, Vector3(0.25, 0.25, 0.04), Vector3.ZERO)
		"wax_splash":
			# Geworfene Kerze (Streich der Kinder, 6.13): großer weißer Wachsfleck mit Spritzern – wie Blut Fleck für Fleck auf
			# der Fläche darunter, sobald die Spur steht (_spread_wax)
			Geo.add_box_shape(self, Vector3(0.7, 0.7, 0.04), Vector3.ZERO)
			_spread_wax.call_deferred()
		"coffee", "tea":
			# Zerbrochene Tasse (3.11, 3.12): brauner bzw. goldbrauner Fleck mit Spritzern – gebaut wie der große Wachsfleck
			# (_spread_wax)
			Geo.add_box_shape(self, Vector3(0.6, 0.6, 0.04), Vector3.ZERO)
			_spread_wax.call_deferred()
		"soot":
			# Verbrannte Deko (5.11): dunkler Rußfleck
			var soot := Mat.psx(Color(0.07, 0.06, 0.05))
			for i in 3:
				var patch := Geo.mesh(self, Geo.box(Vector3(rng.randf_range(0.18, 0.32), rng.randf_range(0.14, 0.28), 0.005)), soot,
					Vector3(rng.randf_range(-0.06, 0.06), rng.randf_range(-0.06, 0.06), 0.003 + i * 0.0004))
				patch.rotation.z = rng.randf() * TAU
			Geo.add_box_shape(self, Vector3(0.45, 0.45, 0.04), Vector3.ZERO)
		"drops":
			# Spur eines verletzten Gastes: einzelne Blutstropfen
			var red := Mat.psx(Color(0.3, 0.02, 0.02))
			for i in rng.randi_range(2, 5):
				var s := rng.randf_range(0.015, 0.035)
				Geo.mesh(self, Geo.box(Vector3(s, s, 0.005)), red, Vector3(rng.randf_range(-0.1, 0.1), rng.randf_range(-0.1, 0.1), 0.0025))
			Geo.add_box_shape(self, Vector3(0.25, 0.25, 0.04), Vector3.ZERO)
	if kind.begins_with("splash_"):
		# Geworfenes an der Wand (3.13): Fleck, Strom herunter, Pfütze – sobald die Spur steht (_spread_wall)
		Geo.add_box_shape(self, Vector3(0.4, 0.4, 0.04), Vector3.ZERO)
		_spread_wall.call_deferred()


## Blutlache (Spielkonzept 4.13, 6.12): BLOOD_SPLATS Flecken um das Opfer, große in der Mitte, kleine bis BLOOD_RADIUS.
## Jeder fällt senkrecht auf die Fläche darunter (place_splat) – auf Treppen also auf die Stufen, nicht auf die Rampe.
## Auf einer Treppe bleiben nur die großen Flecken, von dort läuft ein durchgehender Strom die Stufen hinunter bis zu
## einer Pfütze (lay_stream). Nicht durch Wände. Jeder Fleck ist die Grafik BLOOD_TEXTURE (lay_decal). Frisch breitet sie sich
## langsam aus (SPREAD).
func _spread_blood() -> void:
	if not is_inside_tree():
		return
	rotation = Vector3(0, rotation.y, 0)   # alte Spielstände: Blut lag als gekippte Fläche
	var space := get_world_3d().direct_space_state
	var center := global_position
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var red := decal_material(BLOOD_TEXTURE)
	var downhill := downhill_at(space, center)
	var flow: Dictionary = SPREAD["blood"]
	var plan: Array = []
	var count := rng.randi_range(BLOOD_SPLATS.x, BLOOD_SPLATS.y)
	var streamed := false
	for i in count:
		var big := i < 4
		if downhill != Vector3.ZERO and not big:
			continue   # auf der Treppe läuft das Blut als Strom hinunter statt in Flecken (lay_stream)
		var r := rng.randf_range(0.0, 0.35) if big else sqrt(rng.randf()) * BLOOD_RADIUS
		var size := Vector2.ONE * (rng.randf_range(BLOOD_BIG.x, BLOOD_BIG.y) if big else rng.randf_range(BLOOD_SMALL.x, BLOOD_SMALL.y))
		size.y *= rng.randf_range(0.8, 1.0)   # nicht zu oval – die Grafik ist rund
		var spot := place_splat(space, center, scatter_offset(rng, r, downhill, BLOOD_DOWNHILL * (0.4 if big else 1.0)), size,
			downhill, rng)
		if spot.is_empty():
			continue
		var lift := 0.004 + i * 0.00002   # Überlappung: die Dicke entscheidet (psx_decal)
		var pieces := lay_decal(self, spot, red, rng, lift)
		var stream := [] if streamed else lay_stream(self, space, spot, downhill, red, rng, flow, lift)
		streamed = streamed or not stream.is_empty()
		if fresh:
			plan_spot(plan, pieces, stream, flow, spread_start(flow, center, spot["at"], downhill), big, rng)
	if fresh:
		grow(self, plan)
	if wash > 0.0:
		RainVeil.show_wash(self, wash, "blood")


## Großer Wachsfleck einer geworfenen Kerze (6.13), gebaut wie eine Blutlache: ein Kern (WAX_CORE) und Tropfen ringsum,
## alle aus der Grafik WAX_TEXTURE und jeder auf der Fläche darunter (place_splat) – auf Treppen auf den Stufen, die
## Tropfen hinunter, ein kurzer Strom über wenige Stufen (lay_stream). Frisch in etwa 2 s erstarrt (SPREAD).
## Der Kaffee- und der Teefleck (3.11, 3.12) ebenso, kleiner, in ihrer Farbe (coffee_material) und flüssiger.
func _spread_wax() -> void:
	if not is_inside_tree():
		return
	var coffee := kind in ["coffee", "tea"]
	var space := get_world_3d().direct_space_state
	var center := global_position
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var wax := coffee_material(kind == "tea") if coffee else decal_material(WAX_TEXTURE)
	var downhill := downhill_at(space, center)
	var flow: Dictionary = SPREAD["coffee" if coffee else "wax"]
	var plan: Array = []
	var core := place_splat(space, center, Vector3.ZERO, COFFEE_CORE if coffee else WAX_CORE, downhill, rng)
	if not core.is_empty():
		var pieces := lay_decal(self, core, wax, rng, 0.004)
		var stream := lay_stream(self, space, core, downhill, wax, rng, flow, 0.004)
		if fresh:
			plan_spot(plan, pieces, stream, flow, 0.0, true, rng)
	var drop_count := COFFEE_DROPS if coffee else Vector2i(10, 16)
	for i in rng.randi_range(drop_count.x, drop_count.y):
		var s := rng.randf_range(0.03, 0.08)   # die Grafik füllt ihr Quadrat nicht ganz
		var off := scatter_offset(rng, rng.randf_range(0.18, 0.4), downhill, 0.3)
		var drop := place_splat(space, center, off, Vector2(s * rng.randf_range(1.0, 2.2), s), downhill, rng)
		if drop.is_empty():
			continue
		if not drop["along"]:
			drop["yaw"] = atan2(-off.z, off.x)   # länglich vom Kern weg (lokale X), auf einer Stufe längs
		var drops := lay_decal(self, drop, wax, rng, 0.0045 + i * 0.00002)
		if fresh:
			plan_spot(plan, drops, [], flow, spread_start(flow, center, drop["at"], downhill), false, rng)
	if fresh:
		grow(self, plan)
	if wash > 0.0:
		RainVeil.show_wash(self, wash, "wax")


## Geworfenes an der Wand (Spielkonzept 3.13): „splash_mush:<sorte>“ (bzw. „:mini“ für den Zierkürbis), „splash_wax“,
## „splash_coffee“, „splash_tea“. Lokale +Z zeigt von der Wand weg, Ursprung am Treffpunkt. Ein Fleck (Grafik wie am
## Boden, als Ebene an der Wand), darunter ein kleiner Strom bis zum Boden – eine Kette unverzerrter Quadrate wie auf der
## Treppe (lay_stream: Ursprung oben, wachsen nach unten) – und unten eine Pfütze (place_splat). Frisch läuft er mit
## WALL_SPLASH „speed“ herunter; aus dem Spielstand liegt alles fertig da (jedes Mal etwas anders).
func _spread_wall() -> void:
	if not is_inside_tree():
		return
	var liquid := kind.trim_prefix("splash_").get_slice(":", 0)
	var look: Dictionary = WALL_SPLASH["coffee" if liquid == "tea" else liquid]
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var space := get_world_3d().direct_space_state
	var mat := _wall_material(liquid)
	var size := float(look["splat"])
	var k := 1.0
	if liquid == "mush":
		var sort := kind.get_slice(":", 1)
		var full := Item.MINI_SPLAT if sort == "mini" else float(PumpkinKinds.data(sort).get("splat", Item.MUSH_SIZE))
		k = full / Item.MUSH_SIZE
		size *= k
	if _wall_plane == null:
		_wall_plane = PlaneMesh.new()
		_wall_plane.orientation = PlaneMesh.FACE_Z
		_wall_plane.size = Vector2.ONE
	_runner_mesh()
	var plan: Array = []
	var splat := Geo.mesh(self, _wall_plane, mat, Vector3(0, 0, 0.001))
	splat.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	splat.basis = Basis(Vector3.BACK, rng.randf() * TAU) * Basis.from_scale(Vector3(size, size * rng.randf_range(0.8, 1.0), 1.0))
	plan.append({"node": splat, "at": 0.0, "time": 0.12})
	var out := global_basis.z
	var floor_hit := Traces.surface_below(space, global_position + out * 0.05, 4.0)
	if not floor_hit.is_empty():
		var floor_at: Vector3 = floor_hit["position"]
		var drop := global_position.y - floor_at.y
		var speed := float(look["speed"])
		var widths: Vector2 = look["width"]
		var w := rng.randf_range(widths.x, widths.y) * sqrt(k)
		var top := -size * 0.2
		var x := rng.randf_range(-0.15, 0.15) * size
		var i := 0
		while top > -drop and i < 200:
			var side := minf(w * rng.randf_range(0.9, 1.1), top + drop)   # das letzte Stück endet am Boden
			var piece := Geo.mesh(self, _runner_plane, mat, Vector3.ZERO)
			piece.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			piece.transform = Transform3D(Basis.from_scale(Vector3(side, side, 1.0)), Vector3(x, top, 0.0015 + i * 0.00002))
			plan.append({"node": piece, "at": 0.1 + (-size * 0.2 - top) / speed, "time": STREAM_GROW, "down": true})
			x += rng.randf_range(-0.004, 0.004)
			top -= w * STREAM_SPACING
			i += 1
		var puddles: Vector2 = look["puddle"]
		var p := rng.randf_range(puddles.x, puddles.y) * sqrt(k)
		var spot := place_splat(space, floor_at + out * (p * 0.45 + 0.02), Vector3.ZERO, Vector2(p, p), Vector3.ZERO, rng)
		if not spot.is_empty():
			for piece in lay_decal(self, spot, mat, rng, 0.004):
				plan.append({"node": piece, "at": 0.1 + maxf(0.0, drop - size * 0.2) / speed, "time": rng.randf_range(0.4, 0.8)})
	if fresh:
		grow(self, plan)


## Material des Flecks an der Wand (_spread_wall): Kürbismatsch in der Farbe der Sorte (wie Item._mush_mat), Wachs wie
## am Boden, Kaffee und Tee matter als am Boden (WALL_COFFEE_SPECULAR – senkrecht fing der nasse Glanz das Licht und
## sah grau aus).
func _wall_material(liquid: String) -> ShaderMaterial:
	match liquid:
		"wax":
			return decal_material(WAX_TEXTURE)
		"coffee", "tea":
			if not _mush_mats.has(liquid):
				var mat := coffee_material(liquid == "tea").duplicate() as ShaderMaterial
				mat.set_shader_parameter("specular", WALL_COFFEE_SPECULAR)
				_mush_mats[liquid] = mat
			return _mush_mats[liquid]
	var sort := kind.get_slice(":", 1)
	if not _mush_mats.has(sort):
		var skin: Color = Item.MINI_COLOR if sort == "mini" else PumpkinKinds.data(sort)["color"]
		var color := Item.mush_color(skin)
		var mat := Mat.decal(Item.MUSH_TEXTURE)
		mat.set_shader_parameter("albedo", Color(color.r / Item.MUSH_TEX_COLOR.r, color.g / Item.MUSH_TEX_COLOR.g,
			color.b / Item.MUSH_TEX_COLOR.b))
		splat_look(mat, Item.MUSH_TEXTURE)
		_mush_mats[sort] = mat
	return _mush_mats[sort]


## Die Ebene der Ströme (FACE_Z, Ursprung an der Oberkante – wächst nach unten), einmal für alle.
static func _runner_mesh() -> PlaneMesh:
	if _runner_plane == null:
		_runner_plane = PlaneMesh.new()
		_runner_plane.orientation = PlaneMesh.FACE_Z
		_runner_plane.size = Vector2.ONE
		_runner_plane.center_offset = Vector3(0, -0.5, 0)   # Ursprung an der Oberkante: wächst nach unten
	return _runner_plane


# --- Flecken auf der Fläche darunter (Blut, Wachs, Kürbismatsch – Item._lay_mush) -------------------------------------

## Ein Fleck aus place_splat als Ebene mit Grafik (psx_decal) unter `parent`, `lift` m über der Fläche: frei gedreht
## eine Ebene (zufällig um 180° gedreht), längs auf einer Stufe eine Reihe unverzerrter Quadrate so tief wie die Stufe
## (je 85–100 %, beliebig um 90° gedreht), die sich zu DECAL_OVERLAP überlappen – der Shader verschmilzt sie (Tiefe
## nach Dicke), auf der Stufe liegt ein zusammenhängender Streifen.
static func lay_decal(parent: Node3D, spot: Dictionary, mat: Material, rng: RandomNumberGenerator, lift: float) -> Array[Node3D]:
	if _decal_plane == null:
		_decal_plane = PlaneMesh.new()
		_decal_plane.size = Vector2.ONE   # Maße über die Basis der Ebene
	var size: Vector2 = spot["size"]
	var yaw: float = spot["yaw"]
	var along: bool = spot["along"]
	var side := minf(size.x, size.y)
	var tiles := 1 if not along else 1 + maxi(0, ceili((size.x - side) / (side * (1.0 - DECAL_OVERLAP))))
	var pieces: Array[Node3D] = []
	for t in tiles:
		var dims := size
		var turn := PI if rng.randf() < 0.5 else 0.0
		var x := 0.0
		var z := 0.0
		if along:
			dims = Vector2.ONE * side * rng.randf_range(0.85, 1.0)
			turn = rng.randi_range(0, 3) * PI / 2.0
			x = 0.0 if tiles == 1 else -size.x / 2.0 + side / 2.0 + t * (size.x - side) / (tiles - 1)
			z = rng.randf_range(-0.5, 0.5) * (size.y - dims.y)
		var piece := Geo.mesh(parent, _decal_plane, mat, Vector3.ZERO)
		piece.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		piece.global_transform = Transform3D(Basis(Vector3.UP, yaw + turn) * Basis.from_scale(Vector3(dims.x, 1.0, dims.y)),
			spot["at"] + Basis(Vector3.UP, yaw) * Vector3(x, 0.0, z) + Vector3.UP * lift)
		pieces.append(piece)
	return pieces


## Ein Strom die Treppe hinunter (2026-10-24): Von einem Fleck längs auf einer Stufe läuft ein durchgehender kleiner Strom
## Stufe für Stufe hinunter – als Kette kleiner, unverzerrter Quadrate aus der Grafik (Kantenlänge = Breite des Stroms,
## je STREAM_SPACING × Breite weiter, sie verschmelzen über die Tiefe nach Dicke zu einem Band): auf jeder Trittfläche
## liegend von der Setzstufe bis an die Kante, an jeder Stirnseite senkrecht bis auf die nächste Stufe (Setzstufe bzw.
## Blockstufe – dort endet die Trittfläche, _edge_ahead), bis an die sichtbare Vorderkante (_edge_front: auf der
## Lobbytreppe die Nase der Stufe, in der Mitte der Teppich-Wasserfall – das oberste Stück der Bahn liegt davor, sonst
## bliebe an der Kante eine Lücke). Leicht schlängelnd, nach unten etwas breiter, höchstens „stream_steps“ Stufen; wo die Fläche eben
## weiterläuft (Fuß der Treppe, Podest), sammelt er sich zu einer Pfütze („puddle“ m). Breite „stream_w“ (m).
## → Zeitplan relativ zum Fleck [{node, at, time, down}]: je Stufe „step“ s, davon „run“ an der Stirnseite, die Pfütze
## wächst in „grow_big“.
static func lay_stream(parent: Node3D, space: PhysicsDirectSpaceState3D, spot: Dictionary, downhill: Vector3,
		mat: Material, rng: RandomNumberGenerator, flow: Dictionary, lift: float) -> Array:
	var plan: Array = []
	if downhill == Vector3.ZERO or not spot["along"] or int(flow["stream_steps"]) <= 0:
		return plan
	_runner_mesh()
	var size: Vector2 = spot["size"]
	var across := Basis(Vector3.UP, float(spot["yaw"])) * Vector3.RIGHT
	var face := Basis.looking_at(-downhill, Vector3.UP)   # +Z zeigt die Treppe hinunter, zum Betrachter
	var widths: Vector2 = flow["stream_w"]
	var puddle: Vector2 = flow["puddle"]
	var grow_big: Vector2 = flow["grow_big"]
	var step_time := float(flow["step"])
	var run := float(flow["run"])
	var p: Vector3 = spot["at"] + across * rng.randf_range(-0.25, 0.25) * size.x
	var w := rng.randf_range(widths.x, widths.y)
	var t := 0.0
	var pool := false
	var back := 0.0   # ab der zweiten Stufe beginnt die Kette schon an der Setzstufe
	for s in int(flow["stream_steps"]):
		var front := _edge_ahead(space, p, downhill, 1.0)
		if front < 0.0:
			pool = s > 0   # die Fläche läuft eben weiter: unten angekommen
			break
		# liegend auf der Trittfläche, von hinten bis an die sichtbare Vorderkante (Nase bzw. Teppich darüber)
		var edge_at := p + downhill * front
		var lip := _edge_front(space, edge_at, downhill)
		var from := -back + w * 0.35
		var to := front + float(lip["front"]) - w * 0.15
		var n := maxi(1, ceili((to - from) / (w * STREAM_SPACING)) + 1)
		for i in n:
			var d := from if n == 1 else lerpf(from, to, float(i) / (n - 1))
			var side := w * rng.randf_range(0.9, 1.1)
			var square := {"at": p + downhill * d + across * rng.randf_range(-0.12, 0.12) * w, "size": Vector2(side, side),
				"yaw": rng.randi_range(0, 3) * PI / 2.0, "along": false}
			for piece in lay_decal(parent, square, mat, rng, lift + 0.0002):
				plan.append({"node": piece, "at": t + (step_time - run) * float(i) / n, "time": STREAM_GROW})
		var edge := edge_at
		var below := Traces.surface_below(space, edge + downhill * (0.05 + float(lip["front"])) + Vector3.UP * 0.3, 1.0)
		if below.is_empty():
			break
		var drop := p.y - (below["position"] as Vector3).y
		if drop < 0.06:   # kaum eine Stufe: eben weiter, die Pfütze gleich hinter der Kante
			p = edge + downhill * 0.05
			pool = true
			break
		if drop > 0.45:
			break
		# senkrecht an der Stirnseite, von der Kante bis auf die nächste Stufe: vor dem Teppich ganz, sonst das oberste Stück
		# auf der Stirn der Nase, der Rest an der Setzstufe
		var gap: float = lip["front"] if lip["carpet"] else 0.0
		var rows := maxi(1, ceili((drop - w * 0.5) / (w * STREAM_SPACING)) + 1)
		for i in rows:
			var top := 0.01 - (0.0 if rows == 1 else (drop - w * 0.6) * float(i) / (rows - 1))
			var side := w * rng.randf_range(0.9, 1.1)
			var piece := Geo.mesh(parent, _runner_plane, mat, Vector3.ZERO)
			piece.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			var off: float = lip["front"] if (lip["carpet"] or i == 0) else 0.0
			piece.global_transform = Transform3D(face * Basis.from_scale(Vector3(side, side, 1.0)),
				edge + downhill * (off + 0.002 + i * 0.0002) + Vector3.UP * top)
			plan.append({"node": piece, "at": t + step_time - run + run * float(i) / rows, "time": STREAM_GROW, "down": true})
		p = Vector3(edge.x, (below["position"] as Vector3).y, edge.z) + downhill * (gap + 0.01) \
			+ across * rng.randf_range(-0.02, 0.02)
		back = gap + 0.01
		w = minf(w * 1.03, widths.y * 1.4)
		t += step_time
	if pool:
		var side := rng.randf_range(puddle.x, puddle.y)
		var spot_p := place_splat(space, p, downhill * side * 0.4, Vector2(side, side), Vector3.ZERO, rng)
		if not spot_p.is_empty():
			for piece in lay_decal(parent, spot_p, mat, rng, lift):
				plan.append({"node": piece, "at": t, "time": rng.randf_range(grow_big.x, grow_big.y)})
	return plan


## Die sichtbare Vorderkante einer Stufe vor der Kante ihrer Trittfläche (der Setzstufe): auf der Lobbytreppe in der
## Mitte der Teppich-Wasserfall (Meta „carpet_half“/„carpet_out“ der Trittflächen, GrandStair), daneben die Nase der
## Stufe (Meta „nosing“, dick „nosing_t“); im Treppenhaus (Blockstufen) nichts. → {front (m davor), carpet, lip_t (m)}
static func _edge_front(space: PhysicsDirectSpaceState3D, edge: Vector3, downhill: Vector3) -> Dictionary:
	var tread := Traces.surface_below(space, edge - downhill * 0.03 + Vector3.UP * 0.3, 0.5)
	if tread.is_empty() or not (tread["collider"] as Object).has_meta("carpet_half"):
		return {"front": 0.0, "carpet": false, "lip_t": 0.0}
	var body := tread["collider"] as Node3D
	if absf((body.global_transform.affine_inverse() * edge).x) < float(body.get_meta("carpet_half")):
		return {"front": float(body.get_meta("carpet_out")), "carpet": true, "lip_t": 0.0}
	return {"front": float(body.get_meta("nosing", 0.0)), "carpet": false, "lip_t": float(body.get_meta("nosing_t", 0.0))}


## Abstand von `at` bis zur Kante der Fläche in Richtung dir (auf 2 mm genau, höchstens reach); −1 = keine Kante.
static func _edge_ahead(space: PhysicsDirectSpaceState3D, at: Vector3, dir: Vector3, reach: float) -> float:
	var flat := 0.0
	var off := -1.0
	var d := 0.03
	while d <= reach:
		if not _same_level(space, at, at + dir * d):
			off = d
			break
		flat = d
		d += 0.03
	if off < 0.0:
		return -1.0
	for i in 4:
		var mid := (flat + off) / 2.0
		if _same_level(space, at, at + dir * mid):
			flat = mid
		else:
			off = mid
	return flat


static func _same_level(space: PhysicsDirectSpaceState3D, at: Vector3, q: Vector3) -> bool:
	var hit := Traces.surface_below(space, q + Vector3.UP * 0.3, 0.5)
	return not hit.is_empty() and absf((hit["position"] as Vector3).y - at.y) <= BLOOD_FLAT


## Wann ein frischer Fleck bei `at` anfängt, sich auszubreiten (s nach dem Entstehen): über eine ebene Fläche mit
## „flow“ m/s von `center` aus, auf einer Treppe je Stufe tiefer „step“ s und quer dazu wieder mit „flow“.
static func spread_start(flow: Dictionary, center: Vector3, at: Vector3, downhill: Vector3) -> float:
	var off := Vector3(at.x - center.x, 0.0, at.z - center.z)
	if downhill == Vector3.ZERO:
		return off.length() / float(flow["flow"])
	var steps := roundf(maxf(0.0, center.y - at.y) / STEP_RISE)
	return steps * float(flow["step"]) + (off - downhill * off.dot(downhill)).length() / float(flow["flow"])


## Zeitplan eines frischen Flecks: seine Stücke ab `start` (je etwas versetzt) über „grow_big“ bzw. „grow_small“; sein
## Strom die Treppe hinunter (Zeitplan aus lay_stream, relativ zum Fleck) ab `start`.
static func plan_spot(plan: Array, pieces: Array[Node3D], stream: Array, flow: Dictionary, start: float, big: bool,
		rng: RandomNumberGenerator) -> void:
	var grow_range: Vector2 = flow["grow_big" if big else "grow_small"]
	var time := rng.randf_range(grow_range.x, grow_range.y)
	for piece in pieces:
		plan.append({"node": piece, "at": start + rng.randf_range(0.0, 0.2) * time, "time": time})
	for e in stream:
		var entry: Dictionary = (e as Dictionary).duplicate()
		entry["at"] = float(entry["at"]) + start
		plan.append(entry)


## Lässt die Stücke nach dem Plan wachsen (Spielzeit, pausiert mit dem Spiel): Flecken aus der Mitte auf ihre Größe,
## Läufer von der Kante nach unten. Bis zu ihrem Start sind sie winzig. → der Tween (null = nichts zu tun)
static func grow(owner: Node, plan: Array) -> Tween:
	if plan.is_empty():
		return null
	var tween := owner.create_tween().set_parallel(true)
	for p in plan:
		var node: Node3D = p["node"]
		var full := node.scale
		var down: bool = p.get("down", false)
		node.scale = Vector3(full.x, full.y * 0.02, full.z) if down else Vector3(full.x * 0.02, full.y, full.z * 0.02)
		tween.tween_property(node, "scale", full, float(p["time"])).set_delay(float(p["at"])) \
			.set_trans(Tween.TRANS_LINEAR if down else Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	return tween


## Material für Textur-Flecken (psx_decal, Zug SPLAT_PULL), je Grafik einmal – Kürbismatsch hat ein eigenes (Farbe, Verblassen).
static func decal_material(path: String) -> ShaderMaterial:
	if not _decal_mats.has(path):
		var mat := Mat.decal(path)
		splat_look(mat, path)
		_decal_mats[path] = mat
	return _decal_mats[path]


## Kaffeefleck (3.11): die Wachsgrafik in Kaffeebraun (COFFEE_TINT, COFFEE_LOOK) – ein Material für alle; tea: der
## Teefleck (3.12) in TEA_TINT.
static func coffee_material(tea: bool = false) -> ShaderMaterial:
	var mat := _tea_mat if tea else _coffee_mat
	if mat == null:
		mat = Mat.decal(WAX_TEXTURE)
		mat.set_shader_parameter("layer_pull", SPLAT_PULL)
		mat.set_shader_parameter("albedo", TEA_TINT if tea else COFFEE_TINT)
		for key in COFFEE_LOOK:
			mat.set_shader_parameter(key, COFFEE_LOOK[key])
		if tea:
			_tea_mat = mat
		else:
			_coffee_mat = mat
	return mat


## Zug zur Kamera (SPLAT_PULL) und Look der Grafik (SPLAT_LOOK) für ein psx_decal-Material.
static func splat_look(mat: ShaderMaterial, path: String) -> void:
	mat.set_shader_parameter("layer_pull", SPLAT_PULL)
	var look: Dictionary = SPLAT_LOOK.get(path, {})
	for key in look:
		mat.set_shader_parameter(key, look[key])


## Steht `center` auf einer Treppe? Dann waagrecht die Richtung die Stufen hinunter (aus der Rampe), sonst ZERO.
static func downhill_at(space: PhysicsDirectSpaceState3D, center: Vector3) -> Vector3:
	var under := space.intersect_ray(PhysicsRayQueryParameters3D.create(center + Vector3.UP * 0.5, center + Vector3.DOWN, 1))
	if under.is_empty() or not (under["collider"] as Object).has_meta("stair_ramp"):
		return Vector3.ZERO
	var n: Vector3 = under["normal"]
	return Vector3(n.x, 0.0, n.z).normalized()


## Versatz eines Flecks, `r` vom Mittelpunkt in zufälliger Richtung; auf einer Treppe bergauf gespiegelt und dazu bis
## `reach` die Stufen hinunter.
static func scatter_offset(rng: RandomNumberGenerator, r: float, downhill: Vector3, reach: float) -> Vector3:
	var off := Vector3.FORWARD.rotated(Vector3.UP, rng.randf() * TAU) * r
	if downhill != Vector3.ZERO:
		if off.dot(downhill) < 0.0:
			off -= downhill * 2.0 * off.dot(downhill)   # bergauf gespiegelt
		off += downhill * rng.randf_range(0.0, reach)
	return off


## Ein Fleck (Maße size: x quer, y längs) bei center + off, senkrecht auf die Fläche darunter gefallen
## (Traces.surface_below: Boden, Stufe, Möbel – nicht die Rampe), nicht durch Wände (auf Kniehöhe geprüft). Er muss ganz
## auf derselben Fläche liegen: Ragt er über eine Kante, legt er sich auf einer Treppe längs mittig auf die Stufe (lang
## quer zur Laufrichtung, _flat_span misst Tiefe und Breite), sonst wird er kleiner.
## {} = kein Platz, sonst {at, size, yaw, along}. `yaw` fest (statt zufällig): Schleier im Regen (RainVeil) liegt in
## Laufrichtung.
static func place_splat(space: PhysicsDirectSpaceState3D, center: Vector3, off: Vector3, size: Vector2,
		downhill: Vector3, rng: RandomNumberGenerator, fixed_yaw: float = INF) -> Dictionary:
	if off.length() > 0.01:
		var knee := center + Vector3.UP * 0.3
		var wall := space.intersect_ray(PhysicsRayQueryParameters3D.create(knee, knee + off, 1))
		if not wall.is_empty() and not (wall["collider"] as Object).has_meta("stair_ramp"):
			off = ((wall["position"] as Vector3) - knee) * maxf(0.0, 1.0 - 0.15 / maxf(off.length(), 0.01))
	var hit := Traces.surface_below(space, center + off + Vector3.UP * 1.2, 2.8)
	if hit.is_empty() or (hit["normal"] as Vector3).y < 0.7 or (hit["position"] as Vector3).y < center.y - 2.0:
		return {}
	var at: Vector3 = hit["position"]
	var yaw := rng.randf() * TAU if is_inf(fixed_yaw) else fixed_yaw
	var along := false
	for attempt in 6:
		if _blood_fits(space, at, size, yaw, along):
			return {"at": at, "size": size, "yaw": yaw, "along": along}
		if downhill != Vector3.ZERO and not along:
			# Längs auf die Stufe: mittig in ihre Tiefe, so breit, wie die Stufe neben ihm noch reicht
			along = true
			yaw = atan2(downhill.x, downhill.z)   # lokale X quer zur Treppe, Z die Stufe hinunter
			var deep := _flat_span(space, at, downhill, 0.8)
			at += downhill * (deep.y - deep.x) / 2.0
			var across := downhill.cross(Vector3.UP)
			var wide := _flat_span(space, at, across, 1.2)
			size = Vector2(minf(size.x * 1.5, 2.0 * minf(wide.x, wide.y)), minf(size.y, deep.x + deep.y)) * 0.9
			if minf(size.x, size.y) < 0.02:   # Stufenkante oder Treppenrand direkt daneben – hier ist keine Fläche
				return {}
		else:
			size *= 0.75
	return {}


## Wie weit reicht die Fläche unter `at` in Richtung dir (y) und dagegen (x), bis sie um mehr als BLOOD_FLAT springt
## (Stufenkante, Treppenrand)? Höchstens `reach` je Seite, in 3-cm-Schritten.
static func _flat_span(space: PhysicsDirectSpaceState3D, at: Vector3, dir: Vector3, reach: float) -> Vector2:
	var span := Vector2.ZERO
	for side in 2:
		var d := 0.0
		while d < reach:
			var q := at + dir * (d + 0.03) * (1.0 if side == 1 else -1.0)
			var hit := Traces.surface_below(space, q + Vector3.UP * 0.3, 0.5)
			if hit.is_empty() or absf((hit["position"] as Vector3).y - at.y) > BLOOD_FLAT:
				break
			d += 0.03
		span[side] = d
	return span


## Liegt ein Fleck (Maße size, gedreht um yaw) um `at` ganz auf einer Fläche? Geprüft werden Ecken und Kantenmitten –
## frei gedrehte Flecken mit Reserve für ihre schräg liegenden Stücke, längs auf einer Stufe genau.
static func _blood_fits(space: PhysicsDirectSpaceState3D, at: Vector3, size: Vector2, yaw: float, along: bool) -> bool:
	var basis := Basis(Vector3.UP, yaw)
	var half := Vector3(size.x, 0.0, size.y) * (0.52 if along else 0.62)
	for x in [-1, 0, 1]:
		for z in [-1, 0, 1]:
			if x == 0 and z == 0:
				continue
			var q := at + basis * Vector3(x * half.x, 0.0, z * half.z)
			var hit := Traces.surface_below(space, q + Vector3.UP * 0.3, 0.5)
			if hit.is_empty() or absf((hit["position"] as Vector3).y - at.y) > BLOOD_FLAT:
				return false
	return true


## Regen auf dem Fleck (Traces._wash_marks): Beim ersten Regen entsteht sein Schleier (RainVeil, wächst nach derselben
## Formel mit); der Fleck läuft auseinander und wird dünnflüssig, ganz verlaufen ist er weg.
func wash_by(amount: float) -> void:
	var look := "wax" if kind == "wax_splash" else "blood"
	if wash == 0.0:
		RainVeil.spawn(global_position, look, "", float(RainVeil.SIZE.get(look, 1.0)))
	wash = minf(1.0, wash + amount)
	RainVeil.show_wash(self, wash, look)
	if wash >= 1.0:
		remove_from_group("trace_marks")
		if Game.tracing:
			print("[Regen] %s ganz verlaufen und weg" % NAMES.get(kind, kind))
		queue_free()


func can_wipe() -> bool:
	return Game.director != null and global_position.distance_to(Game.director.player_door_front) < WIPE_RANGE \
		or (Game.director != null and Game.director.zone_name_at(global_position) == "Zimmer 13")


func get_prompt(_player: Player) -> String:
	var label: String = NAMES.get(kind.get_slice(":", 0), "Eine Spur")   # „splash_mush:<sorte>“
	return "%s – wegwischen [E]" % label if can_wipe() else label


func interact(_player: Player) -> void:
	if not can_wipe():
		return
	wipe(Game.player)


## Wegwischen (Spieler an Zimmer 13, Gäste beim Putzen – Tidying): schrumpft weg und ist fort.
func wipe(by: Node) -> void:
	remove_from_group("trace_marks")
	set_meta("interactable", null)
	collision_layer = 0
	Game.noise("wipe", global_position, by)
	var tw := create_tween()
	tw.tween_property(self, "scale", Vector3(1, 1, 0.01) * 0.2, 0.6)
	tw.tween_callback(queue_free)
