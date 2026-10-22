class_name ExtraFixtures
extends RefCounted
## Was nach dem Hotel aufgestellt wird, ohne im Gebäudeplan zu stehen (aus main.gd nach LevelBuilder.build, vor dem
## Backen des NavMesh – beides steht auf Ebene 1 unter der NavigationRegion3D und ist damit Hindernis für die Wegfindung):
## - **Süßigkeiten-Truhe** in jedem Zimmer (Spielkonzept 6.13): kleine Truhe an der Türwand (sonst an der Rückwand), darin
##   SWEETS_START Süßigkeiten als echte Gegenstände (kein Inventar, 3.2). Gäste geben Kindern daraus (Social.take_room_sweet).
## - **Snack- und Colaautomaten** (VendingMachine): je ein Paar in der Lobby und auf jedem Stockwerk nahe dem Treppenhaus,
##   mit dem Rücken an einer Wand, wo vor ihnen AISLE frei bleibt und keine Tür in DOOR_CLEAR ist.
## Physikabfragen sehen frisch gebaute Körper erst nach dem nächsten Physikschritt – darum prüft `_Space` selbst gegen die
## Hüllquader aller Kollisionsformen auf Ebene 1 und 2 (Wände, Möbel, Türen). Ohne freien Platz fällt ein Stück weg.

const SWEETS_START := 6
const CHEST_SIZE := Vector3(0.5, 0.32, 0.36)
const CHEST_COLOR := Color(0.55, 0.22, 0.1)
## Truhe: so weit seitlich neben der Türmitte (m) wird probiert, erst an der Türwand, dann an der Rückwand
const CHEST_OFFSETS := [1.25, -1.25, 1.65, -1.65, 2.05, -2.05, 0.75, -0.75]
## Automaten: so weit vom Wegpunkt nach einer Wand suchen, so viel muss vor ihnen frei bleiben, so weit von Türen
const WALL_SEARCH := 2.6
const AISLE := 1.5
const DOOR_CLEAR := 1.6
const WALL_HEIGHT := 2.2   ## so hoch muss eine Form sein, damit sie als Wand zählt
const STEP := 0.05


static func place(builder: LevelBuilder, world: Node3D) -> void:
	var space := _Space.new(builder.root)
	var chests := 0
	for no: String in builder.rooms:
		if _place_sweets_chest(space, builder, no, world):
			chests += 1
	var machines := _place_machines(space, builder)
	print("[Ausstattung] %d von %d Zimmern mit Süßigkeiten-Truhe, %d Automaten" % [chests, builder.rooms.size(), machines])


## Hüllquader der Kollisionsformen (Ebene 1 und 2) unter der Region – dazu kommt, was hier aufgestellt wird.
class _Space:
	var boxes: Array[AABB] = []

	func _init(root: Node) -> void:
		for node in root.find_children("*", "CollisionShape3D", true, false):
			var shape_node := node as CollisionShape3D
			var body := shape_node.get_parent() as CollisionObject3D
			if body == null or shape_node.disabled or shape_node.shape == null or (body.collision_layer & (1 | 2)) == 0:
				continue
			var local: AABB
			if shape_node.shape is BoxShape3D:
				var size: Vector3 = (shape_node.shape as BoxShape3D).size
				local = AABB(-size / 2.0, size)
			else:
				local = shape_node.shape.get_debug_mesh().get_aabb()
			boxes.append(shape_node.global_transform * local)

	## Ist der Quader frei (etwas geschrumpft, damit Berühren erlaubt ist)?
	func is_free(box: AABB) -> bool:
		var inner := box.grow(-0.03)
		for b in boxes:
			if b.intersects(inner):
				return false
		return true

	## Erster Treffer auf dem Weg von `from` in Richtung `dir` (waagerecht, bis `reach`): Abstand, sonst −1.
	## min_height: nur Formen, die mindestens so hoch sind (Wände statt Möbel).
	func hit_distance(from: Vector3, dir: Vector3, reach: float, min_height: float = 0.0) -> float:
		var d := 0.0
		while d <= reach:
			var p := from + dir * d
			for b in boxes:
				if b.size.y >= min_height and b.has_point(p):
					return d
			d += STEP
		return -1.0

	func add(box: AABB) -> void:
		boxes.append(box)


## Hüllquader eines Stücks: Ursprung am Boden, Front nach `face` (waagerecht, achsparallel genug für die Hotelwände).
static func _box_at(pos: Vector3, face: Vector3, size: Vector3) -> AABB:
	var basis := Basis(Vector3.UP, atan2(face.x, face.z))
	return Transform3D(basis, pos + Vector3.UP * (size.y / 2.0 + 0.02)) * AABB(-size / 2.0, size)


# --- Süßigkeiten-Truhen --------------------------------------------------------------------

static func _place_sweets_chest(space: _Space, builder: LevelBuilder, no: String, world: Node3D) -> bool:
	var room: Dictionary = builder.rooms[no]
	var into: Vector3 = room["into"]
	var along: Vector3 = room["along"]
	var front: Vector3 = room["door_front"]
	var wall := front + into * 0.9   # Mitte der Türwand
	# Rückwand: vom Zimmer aus geradeaus bis zur nächsten Wand
	var depth := space.hit_distance(wall + into * 0.3 + Vector3.UP * 1.0, into, 12.0)
	var candidates: Array[Dictionary] = []
	for s: float in CHEST_OFFSETS:
		candidates.append({"pos": wall + into * (CHEST_SIZE.z / 2.0 + 0.12) + along * s, "face": into})
	if depth > 0.0:
		var back := wall + into * (0.3 + depth)
		for s: float in CHEST_OFFSETS:
			candidates.append({"pos": back - into * (CHEST_SIZE.z / 2.0 + 0.06) + along * s, "face": -into})
	for c in candidates:
		var pos: Vector3 = c["pos"]
		pos.y = front.y
		var face: Vector3 = c["face"]
		var box := _box_at(pos, face, CHEST_SIZE)
		if builder.room_at(pos + Vector3.UP * 0.1) != no or not space.is_free(box):
			continue
		space.add(box)
		var basis := Basis(Vector3.UP, atan2(face.x, face.z))
		var chest := Chest.new()
		chest.size = CHEST_SIZE
		chest.wood_color = CHEST_COLOR
		chest.title = "Süßigkeiten-Truhe"
		chest.set_meta("sweets_room", no)
		chest.add_to_group("sweet_chests")
		builder.root.add_child(chest)
		chest.global_transform = Transform3D(basis, pos)
		for i in SWEETS_START:   # zwei Reihen à drei, liegen sichtbar darin
			var sweet := Item.create(Item.Kind.SWEETS)
			sweet.position = pos + basis * Vector3(-0.14 + (i % 3) * 0.14, 0.08 + 0.03 * floorf(i / 3.0), -0.07 + floorf(i / 3.0) * 0.14)
			sweet.rotation.y = randf() * TAU
			world.add_child(sweet)
		return true
	return false


# --- Automaten -----------------------------------------------------------------------------

## Je ein Paar (Snack, Cola) in der Lobby und auf jedem Stockwerk nahe dem Treppenhaus.
static func _place_machines(space: _Space, builder: LevelBuilder) -> int:
	var anchors: Array[Vector3] = [builder.lobby_center]
	var levels := {}
	for entry in builder.patrol:
		var p: Vector3 = entry["pos"]
		if builder.in_corridor(p):
			levels[roundi(p.y / LevelBuilder.UP_Y)] = true
	for level: int in levels:
		anchors.append(Vector3(builder.stairwell_point.x, level * LevelBuilder.UP_Y, builder.stairwell_point.z))
	var doors := builder.root.get_tree().get_nodes_in_group("doors")
	var placed := 0
	for i in anchors.size():
		var anchor := anchors[i]
		var lobby := i == 0
		var points: Array[Vector3] = []
		for entry in builder.patrol:
			var p: Vector3 = entry["pos"]
			if absf(p.y - anchor.y) < 1.5 and (builder.room_at(p) == "lobby" if lobby else builder.in_corridor(p)):
				points.append(p)
		points.sort_custom(func(a: Vector3, b: Vector3) -> bool: return a.distance_to(anchor) < b.distance_to(anchor))
		for p in points.slice(0, 40):
			var pair := _machine_spots(space, builder, doors, p, WALL_SEARCH * (2.0 if lobby else 1.0))
			if pair.is_empty():
				continue
			for j in 2:
				var m := VendingMachine.new().setup("snack" if j == 0 else "cola")
				builder.root.add_child(m)
				m.global_transform = pair[j]
				space.add(_box_at(pair[j].origin, pair[j].basis.z, VendingMachine.SIZE))
				placed += 1
			break
	return placed


## Zwei Plätze nebeneinander mit dem Rücken an der nächsten Wand (vom Wegpunkt in vier Richtungen gesucht). [] = keiner.
static func _machine_spots(space: _Space, builder: LevelBuilder, doors: Array, p: Vector3, reach: float) -> Array[Transform3D]:
	var size := VendingMachine.SIZE
	var from := p + Vector3.UP * 1.0
	for dir: Vector3 in [Vector3.RIGHT, Vector3.LEFT, Vector3.FORWARD, Vector3.BACK]:
		var d := space.hit_distance(from, dir, reach, WALL_HEIGHT)   # an eine Wand, nicht an die Rezeption
		if d < 0.0:
			continue
		var n := -dir   # Front zeigt vom Wandstück weg, zurück zum Wegpunkt
		var side := n.cross(Vector3.UP)
		var base := from + dir * d + n * (size.z / 2.0 + 0.04)
		base.y = p.y
		var spots: Array[Transform3D] = []
		for s: float in [-0.5, 0.5]:
			var pos := base + side * s * (size.x + 0.08)
			var box := _box_at(pos, n, size)
			var aisle := space.hit_distance(pos + Vector3.UP * 1.0 + n * (size.z / 2.0 + 0.05), n, AISLE)
			if not space.is_free(box) or aisle >= 0.0 or _near_door(doors, pos) or builder.room_at(pos + Vector3.UP * 0.1) != builder.room_at(p):
				break
			spots.append(Transform3D(Basis(Vector3.UP, atan2(n.x, n.z)), pos))
		if spots.size() == 2:
			return spots
	return []


static func _near_door(doors: Array, pos: Vector3) -> bool:
	for node in doors:
		var door := node as Door
		var c := door.center()
		if absf(c.y - 1.05 - pos.y) < 1.5 and Vector2(c.x - pos.x, c.z - pos.z).length() < DOOR_CLEAR + door.width / 2.0:
			return true
	return false
