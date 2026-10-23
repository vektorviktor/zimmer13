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
const NAMES := {"scratch": "Kratzspuren", "blood": "Blutspuren", "handprint": "Ein Handabdruck",
	"wax": "Wachsflecken", "drops": "Blutstropfen", "wax_splash": "Ein großer Wachsfleck", "soot": "Ein Rußfleck",
	"bloody_hand": "Blutige Handabdrücke", "wall_splatter": "Blutspritzer", "wall_smear": "Eine blutige Schmierspur"}

var kind := "scratch"
## Gemeinsam für alle Spuren: Ebene 1 × 1 und die Materialien der Textur-Flecken (lay_decal)
static var _decal_plane: PlaneMesh
static var _decal_mats := {}
## Auf Türen nicht anklickbar (sonst ließe sich die Tür nicht mehr öffnen) – bleibt dort.
var solid := true


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
## Auf einer Treppe läuft das Blut die Stufen hinunter (bergauf verteilt sich nichts). Nicht durch Wände. Jeder Fleck ist
## die Grafik BLOOD_TEXTURE (lay_decal).
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
		lay_decal(self, spot, red, rng, 0.004 + i * 0.00002)   # Überlappung: die Dicke entscheidet (psx_decal)


## Großer Wachsfleck einer geworfenen Kerze (6.13), gebaut wie eine Blutlache: ein Kern (WAX_CORE) und Tropfen ringsum,
## alle aus der Grafik WAX_TEXTURE und jeder auf der Fläche darunter (place_splat) – auf Treppen auf den Stufen, die
## Tropfen hinunter.
func _spread_wax() -> void:
	if not is_inside_tree():
		return
	var space := get_world_3d().direct_space_state
	var center := global_position
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var wax := decal_material(WAX_TEXTURE)
	var downhill := downhill_at(space, center)
	var core := place_splat(space, center, Vector3.ZERO, WAX_CORE, downhill, rng)
	if not core.is_empty():
		lay_decal(self, core, wax, rng, 0.004)
	for i in rng.randi_range(10, 16):
		var s := rng.randf_range(0.03, 0.08)   # die Grafik füllt ihr Quadrat nicht ganz
		var off := scatter_offset(rng, rng.randf_range(0.18, 0.4), downhill, 0.3)
		var drop := place_splat(space, center, off, Vector2(s * rng.randf_range(1.0, 2.2), s), downhill, rng)
		if drop.is_empty():
			continue
		if not drop["along"]:
			drop["yaw"] = atan2(-off.z, off.x)   # länglich vom Kern weg (lokale X), auf einer Stufe längs
		lay_decal(self, drop, wax, rng, 0.0045 + i * 0.00002)


# --- Flecken auf der Fläche darunter (Blut, Wachs, Kürbismatsch – Item._lay_mush) -------------------------------------

## Ein Fleck aus place_splat als Ebene mit Grafik (psx_decal) unter `parent`, `lift` m über der Fläche: frei gedreht
## eine Ebene (zufällig um 180° gedreht), längs auf einer Stufe eine Reihe unverzerrter Quadrate so tief wie die Stufe
## (je 85–100 %, beliebig um 90° gedreht), die sich zu DECAL_OVERLAP überlappen – der Shader verschmilzt sie (Tiefe
## nach Dicke), auf der Stufe liegt ein zusammenhängender Streifen.
static func lay_decal(parent: Node3D, spot: Dictionary, mat: Material, rng: RandomNumberGenerator, lift: float) -> void:
	if _decal_plane == null:
		_decal_plane = PlaneMesh.new()
		_decal_plane.size = Vector2.ONE   # Maße über die Basis der Ebene
	var size: Vector2 = spot["size"]
	var yaw: float = spot["yaw"]
	var along: bool = spot["along"]
	var side := minf(size.x, size.y)
	var tiles := 1 if not along else 1 + maxi(0, ceili((size.x - side) / (side * (1.0 - DECAL_OVERLAP))))
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


## Material für Textur-Flecken (psx_decal, Zug SPLAT_PULL), je Grafik einmal – Kürbismatsch hat ein eigenes (Farbe, Verblassen).
static func decal_material(path: String) -> ShaderMaterial:
	if not _decal_mats.has(path):
		var mat := Mat.decal(path)
		splat_look(mat, path)
		_decal_mats[path] = mat
	return _decal_mats[path]


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
## {} = kein Platz, sonst {at, size, yaw, along}.
static func place_splat(space: PhysicsDirectSpaceState3D, center: Vector3, off: Vector3, size: Vector2,
		downhill: Vector3, rng: RandomNumberGenerator) -> Dictionary:
	if off.length() > 0.01:
		var knee := center + Vector3.UP * 0.3
		var wall := space.intersect_ray(PhysicsRayQueryParameters3D.create(knee, knee + off, 1))
		if not wall.is_empty() and not (wall["collider"] as Object).has_meta("stair_ramp"):
			off = ((wall["position"] as Vector3) - knee) * maxf(0.0, 1.0 - 0.15 / maxf(off.length(), 0.01))
	var hit := Traces.surface_below(space, center + off + Vector3.UP * 1.2, 2.8)
	if hit.is_empty() or (hit["normal"] as Vector3).y < 0.7 or (hit["position"] as Vector3).y < center.y - 2.0:
		return {}
	var at: Vector3 = hit["position"]
	var yaw := rng.randf() * TAU
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
