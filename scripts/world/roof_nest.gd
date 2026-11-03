class_name RoofNest
extends StaticBody3D
## Krähennest vor einem Dachfenster (Spielkonzept 4.25 „Nest am Dach“, ZIM-50): außen auf dem unteren Rahmen eines
## Dachfensters im Dachgeschoss, von innen durch die Scheibe zu sehen. Darin liegt von Anfang an der Ehering von Gerda
## Wagner – sie hat ihn draußen auf einem Tisch liegen lassen, eine Krähe hat ihn geholt (seltene Bitte „Wiederfinden“,
## GuestRequests.RING, 6.14). Kein Klettern aufs Dach: [E] am Fenster klappt es auf, man greift mit ausgestrecktem Arm
## hinaus und nimmt, was darin liegt. Welches Fenster: das dem Futtertisch im Gärtchen von Zimmer 13 am nächsten
## (kleinste Lösung, solange die Form des Dachs offen ist), ohne Tisch das erste.
## Der Körper selbst ist nur die Griff-Fläche innen vor der Scheibe (Ebene HotelCat.LAYER: blockiert niemanden, nur der
## Strahl des Spielers trifft sie). Der Inhalt steht in Crows.roof_nest (gespeichert unter „omens“).

const RING_YEAR := 1976          ## Gravur im Ring: Hochzeit vor fünfzig Jahren (HAUSHALTE.md H10)
const NEST_AT := 0.33            ## Mitte des Nests: so weit die Schräge hinauf (Anteil; das Fenster reicht von 0,25 bis 0,85)
const NEST_OUT := 0.17           ## … so weit über der Dachfläche (liegt in ihrer Neigung – kein Zweig sticht nach innen)
const NEST_SCALE := 0.75
const GRIP_SIZE := Vector3(0.6, 1.3, 0.03)   ## Griff-Fläche: Breite, entlang der Schräge (die ganze Scheibe), Dicke

var crows: Crows
var center := Vector3.ZERO       ## Mitte der Scheibe
var nest_pos := Vector3.ZERO
var stand := Transform3D()       ## unter dem Fenster, Blick zu ihm (LevelBuilder.attic_window_spots)
var _ring: Node3D


## Am Dachfenster nahe dem Futtertisch bauen (null = kein Dachfenster im Plan).
static func make(builder: LevelBuilder, p_crows: Crows) -> RoofNest:
	if builder.attic_window_spots.is_empty():
		return null
	var spot: Transform3D = builder.attic_window_spots[0]
	if not builder.feed_table.is_empty():
		var table: Vector3 = builder.feed_table["pos"]
		for t: Transform3D in builder.attic_window_spots:
			if Vector2(t.origin.x - table.x, t.origin.z - table.z).length() \
					< Vector2(spot.origin.x - table.x, spot.origin.z - table.z).length():
				spot = t
	var nest := RoofNest.new()
	nest.name = "Dachnest"
	nest.crows = p_crows
	p_crows.add_child(nest)
	nest._build(spot)
	return nest


## Lage aus dem Platz unter dem Fenster (LevelBuilder._attic_slopes): Die Schräge beginnt ATTIC_SLOPE + 0,6 m weiter
## draußen auf Kniestockhöhe und steigt nach innen bis ATTIC_H.
func _build(spot: Transform3D) -> void:
	stand = spot
	var out := -spot.basis.z
	out.y = 0.0
	out = out.normalized()
	var rise := LevelBuilder.ATTIC_H - LevelBuilder.ATTIC_KNEE
	var length := Vector2(LevelBuilder.ATTIC_SLOPE, rise).length()
	var foot := spot.origin + out * (LevelBuilder.ATTIC_SLOPE + 0.6) + Vector3.UP * LevelBuilder.ATTIC_KNEE
	var up_slope := (-out * LevelBuilder.ATTIC_SLOPE + Vector3.UP * rise) / length
	var normal := (out * rise + Vector3.UP * LevelBuilder.ATTIC_SLOPE) / length   # aus der Dachfläche heraus
	var mid := (LevelBuilder.ATTIC_WINDOW.x + LevelBuilder.ATTIC_WINDOW.y) / 2.0
	center = foot + up_slope * (mid * length) + normal * 0.04
	nest_pos = foot + up_slope * (NEST_AT * length) + normal * NEST_OUT
	# Griff-Fläche innen vor der Scheibe, in der Ebene der Schräge
	var side := up_slope.cross(normal)
	global_transform = Transform3D(Basis(side, up_slope, normal), center - normal * 0.1)
	collision_layer = HotelCat.LAYER
	collision_mask = 0
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = GRIP_SIZE
	shape.shape = box
	add_child(shape)
	set_meta("interactable", self)
	# Das Nest draußen auf dem unteren Rahmen, in der Neigung des Dachs
	var holder := Node3D.new()
	holder.name = "Nest"
	add_child(holder)
	holder.global_transform = Transform3D(Basis(side, normal, -up_slope).scaled(Vector3.ONE * NEST_SCALE), nest_pos)
	Crows.build_twigs(holder, 1976)
	_ring = Node3D.new()
	holder.add_child(_ring)
	_ring.position = Vector3(0.03, 0.06, -0.02)
	_ring.rotation = Vector3(0.5, 0.0, 0.3)
	var band := TorusMesh.new()   # wie Item.Kind.RING, nur etwas größer, damit man ihn durchs Glas blitzen sieht
	band.inner_radius = 0.011
	band.outer_radius = 0.014
	band.rings = 24
	band.ring_segments = 8
	Geo.mesh(_ring, band, Mat.metal(Color(0.95, 0.76, 0.36)), Vector3.ZERO).scale = Vector3(1.0, 2.0, 1.0)
	update()
	if Game.tracing:
		print("[Dachnest] am Dachfenster bei %s, Nest bei %s" % [center.snapped(Vector3.ONE * 0.01), nest_pos.snapped(Vector3.ONE * 0.01)])


func update() -> void:
	if _ring:
		_ring.visible = not crows.roof_nest.is_empty()


func get_prompt(player: Player) -> String:
	if crows.roof_nest.is_empty():
		return "Draußen vor dem Fenster: ein leeres Krähennest"
	if not player.can_take(Item.Kind.RING):
		return "Draußen im Krähennest glänzt etwas – erst die Hände frei machen"
	return "Dachfenster aufklappen und ins Krähennest greifen [E]"


func interact(player: Player) -> void:
	if crows.roof_nest.is_empty() or not player.can_take(Item.Kind.RING):
		return
	var item := crows.take_from_roof_nest()
	player.receive_item(item)
	Game.say("Du klappst das Dachfenster auf, lehnst dich hinaus und greifst ins Nest: %s." % item.display_name, 4.0)
	if Game.notebook and item.kind == Item.Kind.RING:
		Game.notebook.add_note("roof_nest_ring", "Im Krähennest vor einem Dachfenster lag ein goldener Ehering. Innen eingraviert: „O. & G. %d“." % RING_YEAR, "Dachgeschoss")
	if Game.tracing:
		print("[Dachnest] %s herausgeholt" % item.display_name)
