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
const COFFEE_LOOK := {"specular": 0.6, "normal_strength": 0.4, "edge_alpha": 0.45, "thick_shade": 0.6, "grain": 0.04}
## Grafiken der Flecken am Boden (Umriss aus dem Alpha, psx_decal) – Blutlache und Kern des Wachsflecks
const BLOOD_TEXTURE := "res://assets/textures/blood_pool.png"
const WAX_TEXTURE := "res://assets/textures/wax_splash.png"
## Look je Grafik (psx_decal, Karten aus tools/splat_maps.gd): Glanz, Stärke der Normal Map, Deckkraft am dünnen Rand,
## Farbe der dicken Mitte, Rauschen auf der Farbe. Blut nass glänzend, am Rand dünn und hell; Wachs matter Schimmer,
## Rand durchscheinend; Kürbismatsch feucht und körnig.
const SPLAT_LOOK := {
	BLOOD_TEXTURE: {"specular": 0.5, "normal_strength": 1.0, "edge_alpha": 0.55, "thick_shade": 0.55, "grain": 0.12},
	WAX_TEXTURE: {"specular": 0.35, "normal_strength": 1.0, "edge_alpha": 0.7, "thick_shade": 0.92, "grain": 0.08},
	Item.MUSH_TEXTURE: {"specular": 0.4, "normal_strength": 1.0, "edge_alpha": 0.75, "thick_shade": 0.8, "grain": 0.25},
}
## Frische Flecken breiten sich aus und laufen die Treppe hinunter (Spielzeit – Tweens pausieren mit dem Spiel): je Art
## Fließtempo über eine ebene Fläche (m/s), Dauer, bis ein großer bzw. kleiner Fleck ganz liegt (s), Zeit je Stufe
## hinunter und davon für den Läufer über die Kante (s), Läufer je Fleck längs auf einer Stufe (von, bis) und ihre
## Breite (m). Blut breitet sich in etwa 30 s aus, Kürbismatsch liegt sofort und läuft etwa 5 s nach, Wachs ist in 2 s
## erstarrt.
const SPREAD := {
	"blood": {"flow": 0.12, "grow_big": Vector2(8.0, 14.0), "grow_small": Vector2(3.0, 6.0), "step": 2.5, "run": 1.5,
		"runners": Vector2i(1, 2), "runner_w": Vector2(0.04, 0.09)},
	"mush": {"flow": 3.0, "grow_big": Vector2(0.15, 0.25), "grow_small": Vector2(0.15, 0.3), "step": 1.6, "run": 1.4,
		"runners": Vector2i(0, 1), "runner_w": Vector2(0.05, 0.1)},
	"wax": {"flow": 0.4, "grow_big": Vector2(0.8, 1.2), "grow_small": Vector2(0.3, 0.6), "step": 0.8, "run": 0.5,
		"runners": Vector2i(0, 1), "runner_w": Vector2(0.025, 0.045)},
	"coffee": {"flow": 1.2, "grow_big": Vector2(0.4, 0.7), "grow_small": Vector2(0.2, 0.4), "step": 1.0, "run": 0.7,
		"runners": Vector2i(0, 1), "runner_w": Vector2(0.02, 0.04)},
}
## Ungefähre Stufenhöhe (m) – zählt beim Ausbreiten die Stufen hinunter
const STEP_RISE := 0.2
## Läufer nur von Flecken, die längs auf der Stufe mindestens so breit sind (m)
const RUNNER_MIN_WIDTH := 0.15
const NAMES := {"scratch": "Kratzspuren", "blood": "Blutspuren", "handprint": "Ein Handabdruck",
	"wax": "Wachsflecken", "drops": "Blutstropfen", "wax_splash": "Ein großer Wachsfleck", "soot": "Ein Rußfleck",
	"coffee": "Ein Kaffeefleck",
	"bloody_hand": "Blutige Handabdrücke", "wall_splatter": "Blutspritzer", "wall_smear": "Eine blutige Schmierspur"}

var kind := "scratch"
## Gemeinsam für alle Spuren: Ebene 1 × 1 und die Materialien der Textur-Flecken (lay_decal)
static var _decal_plane: PlaneMesh
static var _runner_plane: PlaneMesh
static var _decal_mats := {}
static var _coffee_mat: ShaderMaterial
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
		"coffee":
			# Zerbrochene Kaffeetasse (3.11): brauner Fleck mit Spritzern – gebaut wie der große Wachsfleck (_spread_wax)
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


## Blutlache (Spielkonzept 4.13, 6.12): BLOOD_SPLATS Flecken um das Opfer, große in der Mitte, kleine bis BLOOD_RADIUS.
## Jeder fällt senkrecht auf die Fläche darunter (place_splat) – auf Treppen also auf die Stufen, nicht auf die Rampe.
## Auf einer Treppe läuft das Blut die Stufen hinunter (bergauf verteilt sich nichts, über die Stufenkanten Läufer –
## lay_runners). Nicht durch Wände. Jeder Fleck ist die Grafik BLOOD_TEXTURE (lay_decal). Frisch breitet sie sich
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
	for i in count:
		var big := i < 4
		var r := rng.randf_range(0.0, 0.35) if big else sqrt(rng.randf()) * BLOOD_RADIUS
		var size := Vector2.ONE * (rng.randf_range(BLOOD_BIG.x, BLOOD_BIG.y) if big else rng.randf_range(BLOOD_SMALL.x, BLOOD_SMALL.y))
		size.y *= rng.randf_range(0.8, 1.0)   # nicht zu oval – die Grafik ist rund
		var spot := place_splat(space, center, scatter_offset(rng, r, downhill, BLOOD_DOWNHILL * (0.4 if big else 1.0)), size,
			downhill, rng)
		if spot.is_empty():
			continue
		var lift := 0.004 + i * 0.00002   # Überlappung: die Dicke entscheidet (psx_decal)
		var pieces := lay_decal(self, spot, red, rng, lift)
		var runners := lay_runners(self, space, spot, downhill, red, rng, flow, lift)
		if fresh:
			plan_spot(plan, pieces, runners, flow, spread_start(flow, center, spot["at"], downhill), big, rng)
	if fresh:
		grow(self, plan)
	if wash > 0.0:
		RainVeil.show_wash(self, wash, "blood")


## Großer Wachsfleck einer geworfenen Kerze (6.13), gebaut wie eine Blutlache: ein Kern (WAX_CORE) und Tropfen ringsum,
## alle aus der Grafik WAX_TEXTURE und jeder auf der Fläche darunter (place_splat) – auf Treppen auf den Stufen, die
## Tropfen hinunter, manchmal ein kurzer Läufer über die Kante. Frisch in etwa 2 s erstarrt (SPREAD).
## Der Kaffeefleck (3.11) ebenso, kleiner, in Kaffeebraun (coffee_material) und flüssiger.
func _spread_wax() -> void:
	if not is_inside_tree():
		return
	var coffee := kind == "coffee"
	var space := get_world_3d().direct_space_state
	var center := global_position
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var wax := coffee_material() if coffee else decal_material(WAX_TEXTURE)
	var downhill := downhill_at(space, center)
	var flow: Dictionary = SPREAD["coffee" if coffee else "wax"]
	var plan: Array = []
	var core := place_splat(space, center, Vector3.ZERO, COFFEE_CORE if coffee else WAX_CORE, downhill, rng)
	if not core.is_empty():
		var pieces := lay_decal(self, core, wax, rng, 0.004)
		var runners := lay_runners(self, space, core, downhill, wax, rng, flow, 0.004)
		if fresh:
			plan_spot(plan, pieces, runners, flow, 0.0, true, rng)
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


## Läufer über die Vorderkante der Stufe (nur Flecken längs auf einer Stufe, mindestens RUNNER_MIN_WIDTH breit): je
## `flow` „runners“ schmale senkrechte Bahnen an der Stirnseite (Setzstufe bzw. Blockstufe – dort endet die
## Trittfläche, _edge_ahead), von der Stufe bis auf die nächste, darunter ein kleiner Auffangfleck. Auf der Lobbytreppe
## hängen sie in der Mitte vor dem Teppich-Wasserfall (Meta „carpet_half“/„carpet_out“ der Trittflächen, GrandStair).
## Die Grafik ist der Fleck, senkrecht gestreckt. → [{runner, landing: [Node3D]}]
static func lay_runners(parent: Node3D, space: PhysicsDirectSpaceState3D, spot: Dictionary, downhill: Vector3,
		mat: Material, rng: RandomNumberGenerator, flow: Dictionary, lift: float) -> Array:
	var size: Vector2 = spot["size"]
	if downhill == Vector3.ZERO or not spot["along"] or size.x < RUNNER_MIN_WIDTH:
		return []
	var count := rng.randi_range((flow["runners"] as Vector2i).x, (flow["runners"] as Vector2i).y)
	var at: Vector3 = spot["at"]
	var front := _edge_ahead(space, at, downhill, 0.6) if count > 0 else -1.0
	if front < 0.0:
		return []
	var edge := at + downhill * front
	var below := Traces.surface_below(space, edge + downhill * 0.06 + Vector3.UP * 0.3, 1.0)
	if below.is_empty():
		return []
	var drop := at.y - (below["position"] as Vector3).y
	if drop < 0.06 or drop > 0.4:
		return []
	if _runner_plane == null:
		_runner_plane = PlaneMesh.new()
		_runner_plane.orientation = PlaneMesh.FACE_Z
		_runner_plane.size = Vector2.ONE
		_runner_plane.center_offset = Vector3(0, -0.5, 0)   # Ursprung an der Oberkante: wächst nach unten
	var tread := Traces.surface_below(space, edge - downhill * 0.03 + Vector3.UP * 0.3, 0.5)
	var across := Basis(Vector3.UP, float(spot["yaw"])) * Vector3.RIGHT
	var face := Basis.looking_at(-downhill, Vector3.UP)   # +Z zeigt die Treppe hinunter, zum Betrachter
	var out: Array = []
	for k in count:
		var top := edge + across * rng.randf_range(-0.4, 0.4) * size.x
		var gap := 0.0
		if not tread.is_empty() and (tread["collider"] as Object).has_meta("carpet_half"):
			var body := tread["collider"] as Node3D
			if absf((body.global_transform.affine_inverse() * top).x) < float(body.get_meta("carpet_half")):
				gap = float(body.get_meta("carpet_out"))
		var w := rng.randf_range((flow["runner_w"] as Vector2).x, (flow["runner_w"] as Vector2).y)
		var runner := Geo.mesh(parent, _runner_plane, mat, Vector3.ZERO)
		runner.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		runner.global_transform = Transform3D(face * Basis.from_scale(Vector3(w, drop + 0.01, 1.0)),
			top + downhill * (gap + 0.002) + Vector3.UP * 0.005)
		var s := w * 2.2
		var land := place_splat(space, top + downhill * (gap + 0.01 + 0.65 * s) + Vector3.DOWN * drop, Vector3.ZERO,
			Vector2.ONE * s, downhill, rng)
		out.append({"runner": runner, "landing": [] if land.is_empty() else lay_decal(parent, land, mat, rng, lift)})
	return out


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


## Zeitplan eines frischen Flecks: seine Stücke ab `start` (je etwas versetzt) über „grow_big“ bzw. „grow_small“; seine
## Läufer, sobald der Fleck die Kante erreicht (so dass sie nach „step“ unten sind), wachsen in „run“ nach unten,
## danach der Auffangfleck.
static func plan_spot(plan: Array, pieces: Array[Node3D], runners: Array, flow: Dictionary, start: float, big: bool,
		rng: RandomNumberGenerator) -> void:
	var grow_range: Vector2 = flow["grow_big" if big else "grow_small"]
	var time := rng.randf_range(grow_range.x, grow_range.y)
	for piece in pieces:
		plan.append({"node": piece, "at": start + rng.randf_range(0.0, 0.2) * time, "time": time})
	var run := float(flow["run"])
	var small: Vector2 = flow["grow_small"]
	for r in runners:
		var at := start + maxf(0.0, float(flow["step"]) - run) + rng.randf_range(0.0, 0.3) * run
		plan.append({"node": r["runner"], "at": at, "time": run, "down": true})
		for piece in r["landing"]:
			plan.append({"node": piece, "at": at + run, "time": rng.randf_range(small.x, small.y)})


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


## Kaffeefleck (3.11): die Wachsgrafik in Kaffeebraun (COFFEE_TINT, COFFEE_LOOK) – ein Material für alle.
static func coffee_material() -> ShaderMaterial:
	if _coffee_mat == null:
		_coffee_mat = Mat.decal(WAX_TEXTURE)
		_coffee_mat.set_shader_parameter("layer_pull", SPLAT_PULL)
		_coffee_mat.set_shader_parameter("albedo", COFFEE_TINT)
		for key in COFFEE_LOOK:
			_coffee_mat.set_shader_parameter(key, COFFEE_LOOK[key])
	return _coffee_mat


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
	var label: String = NAMES.get(kind, "Eine Spur")
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
