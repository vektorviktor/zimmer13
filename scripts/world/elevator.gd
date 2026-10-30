class_name Elevator
extends Node3D
## Aufzug (Spielkonzept 7.4, 7.10): ein Schacht vom untersten bis zum obersten Stockwerk des Plans. An jedem Halt
## Teleskoptüren, die zur Mitte schließen (je Seite zwei Blätter, das innere läuft doppelt so schnell), in einem
## Portal aus dunklem Holz mit Messingkante, darüber die Lampenanzeige der Stockwerke („U“, „0“, „1“ als runde
## Lampen, 8 cm) und rechts daneben ein Rufknopf.
## Die Kabine (working) fährt wirklich – ein AnimatableBody3D, auf dem Spieler und Gegenstände mitfahren: Holzwände,
## drei Messinghandläufe wie an der Rezeption, gegenüber der Tür ein Spiegel (echtes Spiegelbild über eine zweite
## Kamera, nur in der Nähe und mit „Spiegelungen“ in den Einstellungen), eine Deckenleuchte (Lamp, Birne
## herausdrehbar) und links das Bedienfeld aus Messing: drei Etagenknöpfe untereinander, darunter „Tür auf“ und
## „Tür zu“ nebeneinander, darunter der Alarmknopf. Motor und Glocke machen an Abfahrt und Ziel Lärm (7.4).
## Ein toter Schacht (working = false; 7.10: der Weg des Monsters) hat dieselben Türen, Anzeigen und Rufknöpfe, aber
## keine Kabine – seine Anzeige wandert ab und zu von selbst.
## Rahmen: Ursprung = Mitte der Türöffnung auf der Wandmittellinie in Höhe des EG-Bodens, lokal +Z aus dem Schacht
## (vor die Tür), +X von dort aus gesehen rechts. Gebaut von LevelBuilder._elevators.

const WALL_T := 0.2             ## Wandstärke im Plan (LevelBuilder.T)
## Türen: Luft zur Schachtwand, so weit stecken geschlossene Blätter hinter der Leibung, Überdeckung der Blätter,
## Blattstärke, Sturz (lichte Höhe = Öffnung im Plan − HEAD), Sekunden für ganz auf bzw. zu, so lange bleibt sie offen
const SIDE_ROOM := 0.05
const JAMB_TUCK := 0.05
const OVERLAP := 0.03
const PANEL_T := 0.03
const HEAD := 0.1
const DOOR_TIME := 1.8
const DOOR_HOLD := 5.0
const DOOR_HOLD_CHOSEN := 2.0   ## Etage gewählt: die Tür schließt bald
const DEBUG_HOLD := 60.0        ## --aufzug=offen
## Portal: Verkleidung der Leibung steht so weit vor der Wand und greift so weit über die Wandkante; Messingkante an der
## lichten Öffnung (Breite, Vorsprung vor der Verkleidung)
const PORTAL_FACE := 0.015
const PORTAL_OVER := 0.04
const TRIM := Vector2(0.04, 0.012)
## Fahrt: Höchstgeschwindigkeit (m/s), Beschleunigung (m/s²); Grube unter dem untersten Halt
const SPEED := 1.0
const ACCEL := 0.7
const PIT := 0.5
## Kabine: lichte Höhe, Wand-, Dach- und Bodenstärke
const CAB_H := 2.5
const CAB_WALL := 0.04
const CAB_ROOF := 0.1
const CAB_FLOOR := 0.1
## Lampenanzeige: Durchmesser, Mittenabstand, Messingring (so viel breiter), Schrifthöhe (Geviert)
const LAMP_D := 0.08
const LAMP_GAP := 0.12
const LAMP_RIM := 0.008
const LAMP_EM := 0.075
const LAMP_ON := Color(1.0, 0.72, 0.38)
## Rufknopf neben der Tür: Höhe der Mitte, Abstand vom Portal
const CALL_Y := 1.1
const CALL_GAP := 0.12
## Bedienfeld (links in der Kabine): Mitte so weit hinter der Kabinenfront, Ober- und Unterkante, Breite
const PANEL_Z := 0.65
const PANEL_TOP := 1.56
const PANEL_BOTTOM := 1.02
const PANEL_W := 0.17
const BUTTON_R := 0.019        ## Knopf (Elfenbein bzw. gelb), darum ein Messingring
const BUTTON_EM := 0.03
## Handläufe: Höhe der Rohrmitte, Rohrradius, Abstand der Rohrmitte von der Wand, Abstand der Enden von den Ecken bzw.
## der Front, höchstens so weit zwischen zwei Haltern
const RAIL_Y := 0.88
const RAIL_R := 0.022
const RAIL_OFF := 0.065
const RAIL_END := 0.35
const RAIL_BAY := 1.3
const RAIL_SIDES := 10
const RAIL_BEND := 5            ## Abschnitte je Viertelbogen am Rohrende
## Spiegel: Unterkante, lichte Höhe, Rand zu den Seitenwänden, Messingrahmen; Bildbreite in Pixeln
const MIRROR_Y := 1.0
const MIRROR_H := 1.3
const MIRROR_MARGIN := 0.25
const MIRROR_FRAME := 0.03
const MIRROR_RANGE := 12.0
## Deckenleuchte
const LAMP_ENERGY := 0.65
const LAMP_RANGE := 5.0
## Geräusche: Hörweite der Türen, Motor alle so viele Sekunden während der Fahrt (Länge des Klangs „motor“)
const SLIDE_RANGE := 5.0
const MOTOR_RANGE := 14.0
const MOTOR_REPEAT := 3.4
const ALARM_TIME := 2.6
## Toter Schacht: Pause bis zur nächsten Geisterfahrt, je Halt, Verweilen am Ziel (Sekunden Spielzeit); so oft klingt
## dort leise die Glocke
const GHOST_PAUSE := Vector2(120.0, 300.0)
const GHOST_STEP := Vector2(4.0, 6.0)
const GHOST_HOLD := Vector2(6.0, 15.0)
const GHOST_DING := 0.3
const DOOR_COLOR := Color(0.6, 0.48, 0.32)   ## Türblätter: dunkle Bronze

enum Do { CALL, FLOOR, OPEN, CLOSE, ALARM }

var working := true
var stops: Array[float] = []      ## Bodenhöhen der Halte (Welt-y), von unten nach oben
var levels: Array[int] = []       ## Stockwerk je Halt (−1 Untergeschoss, 0 EG, 1 …)
var opening := Vector2(2.5, 2.4)  ## Öffnung im Plan: Breite, Höhe
var shaft := Rect2()              ## Schacht innen, lokal (x, z)

var cabin: AnimatableBody3D
var _doorway: CollisionShape3D    ## schließt die Kabinentür, solange sie zu ist
var _hw := 1.0                   ## halbe lichte Breite
var _pw := 0.5                    ## Blattbreite
var _travel := 0.5                ## Weg des äußeren Blatts (das innere doppelt)
var _clear_h := 2.3
var _z_landing := Vector2.ZERO    ## Mitte der Schachttürblätter (äußeres, inneres)
var _z_cabin := Vector2.ZERO      ## Mitte der Kabinentürblätter
var _cab_front := 0.0             ## Innenseite der Kabinenfront
var _cab_back := 0.0              ## Innenseite der Rückwand
var _cab_side := 0.0              ## Innenseite der Seitenwände (±)
var _landing_doors: Array = []    ## je Halt [[Blatt, Seite, schnell?] …]
var _cabin_doors: Array = []
var _lamp_mats: Array[ShaderMaterial] = []     ## je Halt: Lampe der Anzeige (alle Anzeigen dieses Schachts)
var _button_mats: Array[ShaderMaterial] = []   ## je Halt: Etagen- und Rufknopf
var _open_mat: ShaderMaterial
var _close_mat: ShaderMaterial
var _alarm_mat: ShaderMaterial
var _brass: Material
var _dark_wood: Material
var _font: Font

var _cab_y := 0.0         ## Boden der Kabine (Welt-y)
var _at := -1             ## Halt, an dem die Kabine steht (−1 = unterwegs)
var _target := -1
var _queue: Array[int] = []
var _lit: Array[bool] = []
var _door := 0.0          ## 0 zu … 1 offen
var _door_dir := 0
var _hold := 0.0
var _speed := 0.0
var _motor := 0.0
var _alarm := 0.0
var _flash := {}          ## Material → Sekunden, die es noch aufleuchtet
var _shown := -1          ## Halt, den die Anzeige gerade zeigt

var _ghost_timer := 0.0
var _ghost_path: Array[int] = []
var _rng := RandomNumberGenerator.new()

var _mirror: Mirror


## Ein Knopf (Ruf-, Etagen-, Tür- oder Alarmknopf): interagierbar, alles Weitere entscheidet der Aufzug.
class Push extends StaticBody3D:
	var elevator: Elevator
	var action: Elevator.Do
	var stop := -1

	func get_prompt(_player: Player) -> String:
		return elevator.prompt(self)

	func interact(_player: Player) -> void:
		elevator.press(self)


func setup(p_working: bool, p_stops: Array[float], p_levels: Array[int], p_opening: Vector2, p_shaft: Rect2) -> Elevator:
	working = p_working
	stops = p_stops
	levels = p_levels
	opening = p_opening
	shaft = p_shaft
	return self


func _ready() -> void:
	if working:
		add_to_group("elevators")
	_rng.randomize()
	_brass = Mat.metal(GrandStair.BRASS)
	_dark_wood = Mat.psx(Color(0.22, 0.13, 0.08))
	_font = load(LevelBuilder.SIGN_FONT)
	_layout()
	for i in stops.size():
		_lamp_mats.append(Mat.psx(Color(0.55, 0.5, 0.42), "", 1.0, LAMP_ON, 0.0, false))
		_button_mats.append(Mat.psx(Color(0.9, 0.86, 0.74), "", 1.0, LAMP_ON, 0.0, false))
		_lit.append(false)
	_open_mat = Mat.psx(Color(0.9, 0.86, 0.74), "", 1.0, LAMP_ON, 0.0, false)
	_close_mat = Mat.psx(Color(0.9, 0.86, 0.74), "", 1.0, LAMP_ON, 0.0, false)
	_alarm_mat = Mat.psx(Color(0.95, 0.75, 0.1), "", 1.0, Color(1.0, 0.8, 0.2), 0.0, false)
	for i in stops.size():
		_landing(i)
	_shaft_ends()
	if working:
		_at = maxi(0, levels.find(0))
		_cab_y = stops[_at]
		_build_cabin()
		_show(_at)
	else:
		_ghost_timer = _rng.randf_range(GHOST_PAUSE.x, GHOST_PAUSE.y) * 0.3


## Maße der Türen und der Kabine aus Schacht und Öffnung (Spielkonzept 7.4): Die Blätter müssen offen neben der
## lichten Öffnung im Schacht Platz haben – daraus ergibt sich die lichte Breite, das Portal deckt den Rest der
## Öffnung im Plan.
func _layout() -> void:
	var room := minf(-shaft.position.x, shaft.end.x) - SIDE_ROOM
	# offen: inneres Blatt bei 2 × Weg, Paket außen = lichte Hälfte + Einstand − Überdeckung + Blattbreite ≤ room
	_hw = minf(opening.x / 2.0, floorf((room + OVERLAP / 2.0 - 1.5 * JAMB_TUCK) / 1.5 * 100.0) / 100.0)
	_pw = (_hw + JAMB_TUCK + OVERLAP) / 2.0
	_travel = _hw + JAMB_TUCK - _pw
	_clear_h = opening.y - HEAD
	var face := -WALL_T / 2.0
	_z_landing = Vector2(face - 0.005 - PANEL_T / 2.0, face - 0.015 - PANEL_T * 1.5)
	var sill := _z_landing.y - PANEL_T / 2.0 - 0.005
	_z_cabin = Vector2(sill - 0.025 - PANEL_T * 1.5, sill - 0.015 - PANEL_T / 2.0)
	_cab_front = _z_cabin.x - PANEL_T / 2.0 - 0.005 - CAB_WALL
	_cab_back = shaft.position.y + SIDE_ROOM + CAB_WALL
	_cab_side = minf(-shaft.position.x, shaft.end.x) - SIDE_ROOM - CAB_WALL


# --- Bau -------------------------------------------------------------------------------------------------------

## Ein Halt: Portal, Schwelle, Schachttüren, Anzeige und Rufknopf auf der Seite vor der Tür.
func _landing(i: int) -> void:
	var holder := Node3D.new()
	holder.name = "Halt_%s" % _label(i)
	holder.position.y = stops[i] - position.y
	add_child(holder)
	var w := opening.x / 2.0
	var front := WALL_T / 2.0 + PORTAL_FACE
	var depth := front + WALL_T / 2.0
	# Leibung: dunkles Holz in der Öffnung neben und über der lichten Öffnung, greift über die Wandkante; massiv, sonst
	# fiele, was man dort ablegt, in den Schacht
	for s: float in [-1.0, 1.0]:
		var x0 := _hw
		var x1 := w + PORTAL_OVER
		Geo.solid(holder, Vector3(x1 - x0, opening.y + PORTAL_OVER, depth),
			Vector3(s * (x0 + x1) / 2.0, (opening.y + PORTAL_OVER) / 2.0, front - depth / 2.0), _dark_wood)
		Geo.mesh(holder, Geo.box(Vector3(TRIM.x, _clear_h + TRIM.x, TRIM.y)), _brass,
			Vector3(s * (_hw + TRIM.x / 2.0), (_clear_h + TRIM.x) / 2.0, front + TRIM.y / 2.0))
	var head_h := opening.y + PORTAL_OVER - _clear_h
	Geo.solid(holder, Vector3(_hw * 2.0, head_h, depth), Vector3(0, _clear_h + head_h / 2.0, front - depth / 2.0), _dark_wood)
	Geo.mesh(holder, Geo.box(Vector3(_hw * 2.0 + TRIM.x * 2.0, TRIM.x, TRIM.y)), _brass,
		Vector3(0, _clear_h + TRIM.x / 2.0, front + TRIM.y / 2.0))
	# Schwelle aus Messing in der Wandlücke bis unter die Schachttüren
	var sill_back := _z_landing.y - PANEL_T / 2.0 - 0.005
	Geo.solid(holder, Vector3(_hw * 2.0, 0.05, WALL_T / 2.0 - sill_back), Vector3(0, -0.022, (WALL_T / 2.0 + sill_back) / 2.0), _brass)
	_landing_doors.append(_door_set(holder, _z_landing, 0.005, true))
	_indicator(holder, Vector3(0, opening.y + PORTAL_OVER + 0.12, WALL_T / 2.0), Vector3.BACK)
	# Rufknopf: Messingschild rechts neben dem Portal
	var plate := Node3D.new()
	plate.position = Vector3(w + PORTAL_OVER + CALL_GAP, CALL_Y, WALL_T / 2.0)
	holder.add_child(plate)
	Geo.mesh(plate, Geo.box(Vector3(0.09, 0.15, 0.01)), _brass, Vector3(0, 0, 0.005))
	_button(plate, Vector3(0, 0, 0.01), Do.CALL, i, _button_mats[i], "")


## Die Blätter einer Tür (je Seite das langsame neben der Leibung, das schnelle zur Mitte). solid: Kollision auf der
## Türebene (2) – Schachttüren; die Kabinentür schließt eine Form am Kabinenkörper (_doorway).
func _door_set(parent: Node3D, z: Vector2, bottom: float, solid: bool) -> Array:
	var leaves := []
	var mat := Mat.metal(DOOR_COLOR)
	var h := _clear_h + 0.04
	for s: float in [-1.0, 1.0]:
		for fast: bool in [false, true]:
			var leaf: Node3D = Node3D.new()
			if solid:
				var body := AnimatableBody3D.new()
				body.sync_to_physics = false
				body.collision_layer = 2
				body.collision_mask = 0
				leaf = body
			parent.add_child(leaf)
			var size := Vector3(_pw, h, PANEL_T)
			Geo.mesh(leaf, Geo.box(size), mat, Vector3(0, h / 2.0 + bottom, 0))
			# Zierleisten in Kniehöhe und unter dem Sturz
			for y: float in [0.45, h - 0.25]:
				Geo.mesh(leaf, Geo.box(Vector3(_pw - 0.06, 0.02, PANEL_T + 0.006)), _brass, Vector3(0, y + bottom, 0))
			if solid:
				Geo.add_box_shape(leaf as CollisionObject3D, size, Vector3(0, h / 2.0 + bottom, 0))
			leaf.position.z = z.y if fast else z.x
			leaves.append([leaf, s, fast])
	_place_leaves(leaves, 0.0)
	return leaves


## Kabinentür und die Schachttüren aller Halte nach _door (nur am Halt der Kabine offen).
func _apply_doors() -> void:
	_place_leaves(_cabin_doors, _door)
	for i in _landing_doors.size():
		_place_leaves(_landing_doors[i], _door if i == _at else 0.0)
	_doorway.set_deferred("disabled", _door > 0.05)


func _place_leaves(leaves: Array, open: float) -> void:
	var f := smoothstep(0.0, 1.0, open)
	for entry in leaves:
		var leaf: Node3D = entry[0]
		var s: float = entry[1]
		if entry[2]:
			leaf.position.x = s * (_pw / 2.0 + 2.0 * _travel * f)
		else:
			leaf.position.x = s * (_hw + JAMB_TUCK - _pw / 2.0 + _travel * f)


## Lampenanzeige: Messingleiste mit runden Lampen, links das unterste Stockwerk. pos = Mitte auf der Wandfläche,
## out = von der Wand weg.
func _indicator(parent: Node3D, pos: Vector3, out: Vector3) -> void:
	var holder := Node3D.new()
	holder.position = pos
	holder.basis = Basis(Vector3.UP, atan2(out.x, out.z))
	parent.add_child(holder)
	var n := stops.size()
	Geo.mesh(holder, Geo.box(Vector3(n * LAMP_GAP + 0.03, LAMP_D + 0.05, 0.01)), _brass, Vector3(0, 0, 0.005))
	for i in n:
		var x := (i - (n - 1) / 2.0) * LAMP_GAP
		var rim := Geo.mesh(holder, Geo.cylinder(LAMP_D / 2.0 + LAMP_RIM, 0.012, 16), _brass, Vector3(x, 0, 0.016))
		rim.rotation.x = PI / 2.0
		var glass := Geo.mesh(holder, Geo.cylinder(LAMP_D / 2.0, 0.006, 16), _lamp_mats[i], Vector3(x, 0, 0.024))
		glass.rotation.x = PI / 2.0
		_letter(holder, _label(i), Vector3(x, 0, 0.027), LAMP_EM, Mat.psx(Color(0.12, 0.07, 0.04)))


## Buchstabe (Cinzel wie die Schilder) mittig um pos, Vorderseite +Z des Halters.
func _letter(parent: Node3D, text: String, pos: Vector3, em: float, mat: Material) -> void:
	var letters := TextMesh.new()
	letters.text = text
	letters.font = _font
	letters.font_size = LevelBuilder.SIGN_FONT_SIZE
	letters.pixel_size = em / LevelBuilder.SIGN_FONT_SIZE
	letters.curve_step = LevelBuilder.SIGN_CURVE_STEP
	letters.depth = 0.002
	var box := letters.get_aabb()
	var c := box.get_center()
	Geo.mesh(parent, letters, mat, pos - Vector3(c.x, c.y, box.position.z + 0.001))


## Runder Knopf mit Messingring an pos (Vorderseite +Z des Halters); label auf dem Knopf.
func _button(parent: Node3D, pos: Vector3, action: Do, stop: int, face: Material, label: String) -> Push:
	var push := Push.new()
	push.elevator = self
	push.action = action
	push.stop = stop
	push.collision_layer = 4
	push.collision_mask = 0
	push.position = pos
	push.set_meta("interactable", push)
	parent.add_child(push)
	var rim := Geo.mesh(push, Geo.cylinder(BUTTON_R + 0.007, 0.006, 16), _brass, Vector3(0, 0, 0.003))
	rim.rotation.x = PI / 2.0
	var cap := Geo.mesh(push, Geo.cylinder(BUTTON_R, 0.008, 16), face, Vector3(0, 0, 0.007))
	cap.rotation.x = PI / 2.0
	if label != "":
		_letter(push, label, Vector3(0, 0, 0.011), BUTTON_EM, Mat.psx(Color(0.1, 0.07, 0.05)))
	Geo.add_box_shape(push, Vector3(0.045, 0.045, 0.03), Vector3(0, 0, 0.01))
	return push


## Grube unter dem untersten Halt und Decke über dem obersten (die Plan-Stockwerke lassen den Schacht offen).
func _shaft_ends() -> void:
	var size := Vector3(shaft.size.x, 0.2, shaft.size.y)
	var center := Vector3(shaft.get_center().x, 0, shaft.get_center().y)
	var concrete := Mat.psx(Color(0.45, 0.45, 0.45), "concrete", 1.0)
	Geo.solid(self, size, center + Vector3(0, stops[0] - position.y - CAB_FLOOR - PIT - 0.1, 0), concrete)
	Geo.solid(self, size, center + Vector3(0, stops[-1] - position.y + LevelBuilder.H + 0.1, 0), concrete)


## Kabine: Boden, Wände, Dach und Türen als ein AnimatableBody3D (Ebene 1 – nicht im NavMesh, der Aufzug hängt unter
## der Hauptszene); Innenausbau als Kinder.
func _build_cabin() -> void:
	cabin = AnimatableBody3D.new()
	cabin.name = "Kabine"
	cabin.sync_to_physics = true
	cabin.collision_layer = 1
	cabin.collision_mask = 0
	cabin.position.y = _cab_y - position.y
	add_child(cabin)
	var outer := _cab_side + CAB_WALL
	var front_out := _cab_front + CAB_WALL
	var back_out := _cab_back - CAB_WALL
	var len_in := _cab_front - _cab_back
	var mid_z := (_cab_front + _cab_back) / 2.0
	var wood := Mat.photo(LevelBuilder.CEILING_TEX, LevelBuilder.CEILING_METERS, LevelBuilder.CEILING_NORMAL,
		LevelBuilder.CEILING_ROUGHNESS, LevelBuilder.CEILING_SPECULAR, Color(0.62, 0.48, 0.38), true)
	var floor_z0 := _z_cabin.y + PANEL_T / 2.0 + 0.004   # Bodenvorderkante unter den Kabinentüren
	# Boden mit Teppich, Decke hell gestrichen (beide waagerecht: Textur in Weltkoordinaten wandert nicht mit). Alle
	# Formen hängen am Kabinenkörper selbst – nur so fährt der Spieler mit (Geschwindigkeit der Plattform)
	Geo.box_part(cabin, Vector3(outer * 2.0, CAB_FLOOR, floor_z0 - back_out), Vector3(0, -CAB_FLOOR / 2.0, (floor_z0 + back_out) / 2.0),
		Mat.psx(Color(0.75, 0.3, 0.25), "carpet", 1.0))
	Geo.box_part(cabin, Vector3(outer * 2.0, CAB_ROOF, front_out - back_out), Vector3(0, CAB_H + CAB_ROOF / 2.0, (front_out + back_out) / 2.0),
		Mat.psx(Color(0.82, 0.78, 0.7)))
	# Wände (Holz in Kabinenkoordinaten): Seiten über die ganze Tiefe, Rückwand und Front dazwischen
	for s: float in [-1.0, 1.0]:
		Geo.box_part(cabin, Vector3(CAB_WALL, CAB_H, front_out - back_out), Vector3(s * (_cab_side + CAB_WALL / 2.0), CAB_H / 2.0,
			(front_out + back_out) / 2.0), wood)
		var ret := _cab_side - _hw
		Geo.box_part(cabin, Vector3(ret, CAB_H, CAB_WALL), Vector3(s * (_hw + ret / 2.0), CAB_H / 2.0, _cab_front + CAB_WALL / 2.0), wood)
		Geo.mesh(cabin, Geo.box(Vector3(TRIM.x, _clear_h + TRIM.x, TRIM.y)), _brass,
			Vector3(s * (_hw + TRIM.x / 2.0), (_clear_h + TRIM.x) / 2.0, _cab_front - TRIM.y / 2.0))
	Geo.box_part(cabin, Vector3(_hw * 2.0, CAB_H - _clear_h, CAB_WALL), Vector3(0, (_clear_h + CAB_H) / 2.0, _cab_front + CAB_WALL / 2.0), wood)
	Geo.mesh(cabin, Geo.box(Vector3(_hw * 2.0 + TRIM.x * 2.0, TRIM.x, TRIM.y)), _brass,
		Vector3(0, _clear_h + TRIM.x / 2.0, _cab_front - TRIM.y / 2.0))
	Geo.box_part(cabin, Vector3(_cab_side * 2.0, CAB_H, CAB_WALL), Vector3(0, CAB_H / 2.0, _cab_back - CAB_WALL / 2.0), wood)
	# Kabinentür: Die Blätter sind nur Optik; solange sie zu sind, schließt eine Form am Kabinenkörper die Öffnung
	_cabin_doors = _door_set(cabin, _z_cabin, 0.0, false)
	_doorway = Geo.add_box_shape(cabin, Vector3(_hw * 2.0, _clear_h, PANEL_T * 3.0), Vector3(0, _clear_h / 2.0, _z_cabin.x))
	_indicator(cabin, Vector3(0, (_clear_h + CAB_H) / 2.0 + 0.02, _cab_front), Vector3.FORWARD)
	_rails()
	_mirror_wall()
	_panel()
	var lamp := Lamp.new().setup(Lamp.Style.FLUSH, "aufzug", LAMP_ENERGY, LAMP_RANGE, false)
	lamp.position = Vector3(0, CAB_H, mid_z + len_in * 0.15)
	cabin.add_child(lamp)


## Drei Messinghandläufe (links, rechts, hinten) wie die Rohre der Rezeption: am Ende im Viertelbogen zur Wand, dort
## eine Rosette, dazwischen Halter.
func _rails() -> void:
	var sh := GrandStair.Shape.new()
	var side_from := _cab_front - RAIL_END
	var side_to := _cab_back + RAIL_END
	for s: float in [-1.0, 1.0]:
		var x := s * (_cab_side - RAIL_OFF)
		_rail(sh, Vector3(x, RAIL_Y, side_from), Vector3(x, RAIL_Y, side_to), Vector3(-s, 0, 0))
	var z := _cab_back + RAIL_OFF
	_rail(sh, Vector3(-_cab_side + RAIL_END, RAIL_Y, z), Vector3(_cab_side - RAIL_END, RAIL_Y, z), Vector3.BACK)
	Geo.mesh(cabin, sh.commit(), _brass, Vector3.ZERO)


## Rohr von a nach b (beide RAIL_OFF vor der Wand), n zeigt von der Wand weg.
func _rail(sh: GrandStair.Shape, a: Vector3, b: Vector3, n: Vector3) -> void:
	var dir := (b - a).normalized()
	var pts: Array[Vector3] = []
	var bend := func(corner: Vector3, along: Vector3, reverse: bool) -> void:
		var center := corner - n * RAIL_OFF + along * RAIL_OFF
		var arc: Array[Vector3] = []
		for k in RAIL_BEND + 1:
			var phi := PI / 2.0 * k / RAIL_BEND
			arc.append(center - along * RAIL_OFF * cos(phi) + n * RAIL_OFF * sin(phi))
		if reverse:
			arc.reverse()
		pts.append_array(arc)
	bend.call(a, dir, false)
	bend.call(b, -dir, true)
	_tube(sh, pts, RAIL_R)
	for end: Vector3 in [a, b]:
		_disc(sh, end - n * RAIL_OFF, n, RAIL_R * 1.7, 0.008)
	var length := a.distance_to(b)
	var bays := ceili(length / RAIL_BAY)
	for k in range(1, bays):
		var p := a + dir * length * k / bays
		var bracket: Array[Vector3] = [p - n * RAIL_OFF, p - n * RAIL_R]
		_tube(sh, bracket, RAIL_R * 0.35)
		_disc(sh, p - n * RAIL_OFF, n, RAIL_R * 1.2, 0.006)


## Rohr entlang pts (Radius r), weich schattiert, offene Enden.
func _tube(sh: GrandStair.Shape, pts: Array[Vector3], r: float) -> void:
	var rings: Array = []
	for i in pts.size():
		var t := (pts[mini(i + 1, pts.size() - 1)] - pts[maxi(i - 1, 0)]).normalized()
		var up := Vector3.UP if absf(t.y) < 0.9 else Vector3.RIGHT
		var side := t.cross(up).normalized()
		up = side.cross(t)
		var ring: Array[Vector3] = []
		for k in RAIL_SIDES:
			var phi := TAU * k / RAIL_SIDES
			ring.append(up * cos(phi) + side * sin(phi))
		rings.append(ring)
	for i in pts.size() - 1:
		var r0: Array[Vector3] = rings[i]
		var r1: Array[Vector3] = rings[i + 1]
		for k in RAIL_SIDES:
			var k1 := (k + 1) % RAIL_SIDES
			sh.tri(pts[i] + r0[k] * r, pts[i] + r0[k1] * r, pts[i + 1] + r1[k1] * r, r0[k], r0[k1], r1[k1])
			sh.tri(pts[i] + r0[k] * r, pts[i + 1] + r1[k1] * r, pts[i + 1] + r1[k] * r, r0[k], r1[k1], r1[k])


## Flache Rosette (Zylinder) auf der Wand bei p, n von der Wand weg.
func _disc(sh: GrandStair.Shape, p: Vector3, n: Vector3, r: float, h: float) -> void:
	var up := Vector3.UP
	var side := n.cross(up).normalized()
	for k in RAIL_SIDES * 2:
		var p0 := TAU * k / (RAIL_SIDES * 2)
		var p1 := TAU * (k + 1) / (RAIL_SIDES * 2)
		var d0 := up * cos(p0) + side * sin(p0)
		var d1 := up * cos(p1) + side * sin(p1)
		sh.quad(p + d0 * r, p + d1 * r, p + d1 * r + n * h, p + d0 * r + n * h, (d0 + d1).normalized())
		sh.tri(p + n * h, p + d0 * r + n * h, p + d1 * r + n * h, n, n, n)


## Spiegel an der Rückwand (gegenüber der Tür) im Messingrahmen – echtes Spiegelbild (Mirror), nur in einer Kabine,
## die fährt.
func _mirror_wall() -> void:
	var width := _cab_side * 2.0 - MIRROR_MARGIN * 2.0
	var cy := MIRROR_Y + MIRROR_H / 2.0
	for s: float in [-1.0, 1.0]:
		Geo.mesh(cabin, Geo.box(Vector3(MIRROR_FRAME, MIRROR_H + MIRROR_FRAME * 2.0, 0.02)), _brass,
			Vector3(s * (width + MIRROR_FRAME) / 2.0, cy, _cab_back + 0.01))
		Geo.mesh(cabin, Geo.box(Vector3(width + MIRROR_FRAME * 2.0, MIRROR_FRAME, 0.02)), _brass,
			Vector3(0, cy + s * (MIRROR_H + MIRROR_FRAME) / 2.0, _cab_back + 0.01))
	_mirror = Mirror.make(cabin, Vector2(width, MIRROR_H), Vector3(0, cy, _cab_back + 0.012), Vector3.BACK, MIRROR_RANGE)
	_mirror.active = working


## Bedienfeld links in der Kabine (vom Eingang aus): Messingplatte, oben die Etagen (oberste zuoberst), darunter
## „Tür auf“ (◀▶) und „Tür zu“ (▶◀) nebeneinander, darunter der gelbe Alarmknopf mit Glocke.
func _panel() -> void:
	var holder := Node3D.new()
	holder.position = Vector3(-_cab_side, 0, _cab_front - PANEL_Z)
	holder.basis = Basis(Vector3.UP, PI / 2.0)   # +Z des Halters zeigt in die Kabine (+X)
	cabin.add_child(holder)
	var h := PANEL_TOP - PANEL_BOTTOM
	Geo.mesh(holder, Geo.box(Vector3(PANEL_W, h, 0.012)), _brass, Vector3(0, PANEL_BOTTOM + h / 2.0, 0.006))
	var y := PANEL_TOP - 0.06
	for k in stops.size():
		var i := stops.size() - 1 - k
		_button(holder, Vector3(0, y, 0.012), Do.FLOOR, i, _button_mats[i], _label(i))
		y -= 0.07
	y -= 0.035
	var open := _button(holder, Vector3(-0.036, y, 0.012), Do.OPEN, -1, _open_mat, "")
	_arrows(open, false)
	var close := _button(holder, Vector3(0.036, y, 0.012), Do.CLOSE, -1, _close_mat, "")
	_arrows(close, true)
	y -= 0.1
	var alarm := _button(holder, Vector3(0, y, 0.012), Do.ALARM, -1, _alarm_mat, "")
	_bell(alarm)


## Zwei Dreiecke auf einem Türknopf: auseinander (auf) oder aufeinander zu (zu).
func _arrows(push: Node3D, inward: bool) -> void:
	var ink := Mat.psx(Color(0.1, 0.07, 0.05))
	for s: float in [-1.0, 1.0]:
		var tri := PrismMesh.new()
		tri.size = Vector3(0.012, 0.012, 0.002)
		var m := Geo.mesh(push, tri, ink, Vector3(s * 0.0075, 0, 0.0115))
		# Spitze der PrismMesh zeigt nach +Y – nach außen (auf) bzw. zur Mitte (zu) drehen
		m.rotation.z = -s * PI / 2.0 if not inward else s * PI / 2.0


## Glocke auf dem Alarmknopf: Kelch, Rand, Klöppel.
func _bell(push: Node3D) -> void:
	var ink := Mat.psx(Color(0.1, 0.07, 0.05))
	var cup := CylinderMesh.new()
	cup.top_radius = 0.003
	cup.bottom_radius = 0.008
	cup.height = 0.012
	cup.radial_segments = 8
	cup.rings = 1
	var bell := Geo.mesh(push, cup, ink, Vector3(0, 0.003, 0.0115))
	bell.scale.z = 0.15   # flach wie ein Relief
	Geo.mesh(push, Geo.box(Vector3(0.02, 0.002, 0.002)), ink, Vector3(0, -0.0035, 0.0115))
	Geo.mesh(push, Geo.box(Vector3(0.004, 0.004, 0.002)), ink, Vector3(0, -0.007, 0.0115))


# --- Knöpfe -----------------------------------------------------------------------------------------------------

func prompt(push: Push) -> String:
	match push.action:
		Do.CALL:
			return "Aufzug rufen [E]"
		Do.FLOOR:
			return "%s [E]  – Knopf „%s“" % [_floor_name(push.stop), _label(push.stop)]
		Do.OPEN:
			return "Tür öffnen [E]"
		Do.CLOSE:
			return "Tür schließen [E]"
		Do.ALARM:
			return "Alarm [E]"
	return ""


func press(push: Push) -> void:
	Game.play_sound("blip", 0.25)
	if not working:   # toter Schacht: der Knopf leuchtet kurz, sonst nichts
		_flash[_button_mats[push.stop]] = 1.2
		_set_glow(_button_mats[push.stop], true)
		return
	match push.action:
		Do.CALL, Do.FLOOR:
			_request(push.stop, push.action == Do.FLOOR)
		Do.OPEN:
			_flash[_open_mat] = 0.4
			_set_glow(_open_mat, true)
			if _target < 0 and _at >= 0:
				_open()
		Do.CLOSE:
			_flash[_close_mat] = 0.4
			_set_glow(_close_mat, true)
			if _door > 0.0 and _door_dir >= 0:
				_close()
		Do.ALARM:
			if _alarm <= 0.0:
				_alarm = ALARM_TIME
				_set_glow(_alarm_mat, true)
				Game.noise("elevator_alarm", cabin.global_position + Vector3(0, 1.2, 0), Game.player)


## Etage gewünscht (Ruf- oder Etagenknopf). Steht die Kabine schon dort, geht die Tür auf.
func _request(i: int, inside: bool) -> void:
	if _target < 0 and _at == i:
		_open()
		return
	if i == _target or i in _queue:
		return
	_queue.append(i)
	_lit[i] = true
	_set_glow(_button_mats[i], true)
	if inside and _door > 0.0:
		_hold = minf(_hold, DOOR_HOLD_CHOSEN)


func _set_glow(mat: ShaderMaterial, on: bool) -> void:
	mat.set_shader_parameter("emission_energy", 2.2 if on else 0.0)


# --- Ablauf -----------------------------------------------------------------------------------------------------

func _physics_process(delta: float) -> void:
	if not working:
		return
	if _alarm > 0.0:
		_alarm -= delta
		if _alarm <= 0.0:
			_set_glow(_alarm_mat, false)
	if _door_dir != 0:
		if _door_dir < 0 and _in_doorway():
			_open()   # wie eine Lichtschranke: wer in der Tür steht, wird nicht eingeklemmt
		_door = clampf(_door + _door_dir * delta / DOOR_TIME, 0.0, 1.0)
		_apply_doors()
		if _door >= 1.0 and _door_dir > 0:
			_door_dir = 0
		elif _door <= 0.0 and _door_dir < 0:
			_door_dir = 0
		return
	if _door > 0.0:
		_hold -= delta
		if _hold <= 0.0:
			_close()
		return
	if _target >= 0:
		_drive(delta)
	elif not _queue.is_empty():
		_depart(_queue.pop_front())


func _process(delta: float) -> void:
	for mat: ShaderMaterial in _flash.keys():
		_flash[mat] -= delta
		if _flash[mat] <= 0.0:
			_flash.erase(mat)
			_set_glow(mat, false)
	if working:
		var nearest := 0
		for i in stops.size():
			if absf(stops[i] - _cab_y) < absf(stops[nearest] - _cab_y):
				nearest = i
		if nearest != _shown:
			_show(nearest)
	else:
		_ghost(delta)


func _open() -> void:
	if _at < 0 or _target >= 0:
		return
	_hold = DOOR_HOLD if _queue.is_empty() else DOOR_HOLD_CHOSEN   # läuft erst, wenn sie ganz offen ist
	if _door < 1.0 and _door_dir <= 0:
		_door_dir = 1
		_slide_sound()


func _close() -> void:
	if _door > 0.0 and _door_dir >= 0:
		_door_dir = -1
		_slide_sound()


func _slide_sound() -> void:
	Game.sound_at("slide", _landing_point(_at), SLIDE_RANGE)


func _depart(i: int) -> void:
	if i == _at:
		_open()
		return
	_target = i
	Game.noise("elevator", _landing_point(_at))
	_motor = MOTOR_REPEAT
	_at = -1
	_speed = 0.0


## Fahrt zum Ziel: anfahren, gleiten, bremsen; der Motor brummt weiter (nur Klang, Lärm gab es bei der Abfahrt).
func _drive(delta: float) -> void:
	var goal := stops[_target]
	var left := absf(goal - _cab_y)
	_speed = minf(minf(SPEED, _speed + ACCEL * delta), maxf(sqrt(2.0 * ACCEL * left), 0.05))
	var step := minf(_speed * delta, left)
	_cab_y += signf(goal - _cab_y) * step
	cabin.position.y = _cab_y - position.y
	_motor -= delta
	if _motor <= 0.0 and left - step > 1.0:
		_motor = MOTOR_REPEAT
		Game.sound_at("motor", cabin.global_position + Vector3(0, 1.2, 0), MOTOR_RANGE)
	if left - step <= 0.0001:
		_arrive()


func _arrive() -> void:
	_at = _target
	_target = -1
	_speed = 0.0
	_cab_y = stops[_at]
	cabin.position.y = _cab_y - position.y
	_lit[_at] = false
	_set_glow(_button_mats[_at], false)
	Game.noise("elevator_bell", _landing_point(_at))
	_open()


## Steht der Spieler in der Türebene (zwischen Kabinenfront und Wand vor der Tür)?
func _in_doorway() -> bool:
	if Game.player == null or _at < 0:
		return false
	var p := to_local(Game.player.global_position)
	var r := Player.RADIUS
	return absf(p.y - (stops[_at] - position.y)) < 1.5 and absf(p.x) < _hw + r \
		and p.z + r > _cab_front and p.z - r < WALL_T / 2.0


## Mitte vor der Tür am Halt i in Ohrhöhe (Welt).
func _landing_point(i: int) -> Vector3:
	return to_global(Vector3(0, stops[i] - position.y + 1.2, 0))


## Anzeige: Lampe des Halts i an, alle anderen aus (−1 = alle dunkel).
func _show(i: int) -> void:
	_shown = i
	for k in _lamp_mats.size():
		var mat := _lamp_mats[k]
		mat.set_shader_parameter("emission_energy", 2.5 if k == i else 0.0)
		mat.set_shader_parameter("albedo", Color(1.0, 0.85, 0.6) if k == i else Color(0.55, 0.5, 0.42))


## Toter Schacht (7.4, 7.10): Ab und zu geht eine Lampe an und wandert Halt für Halt weiter, als führe eine Kabine
## – manchmal klingt am Ziel leise die Glocke. Dann wird die Anzeige wieder dunkel.
func _ghost(delta: float) -> void:
	_ghost_timer -= delta
	if _ghost_timer > 0.0:
		return
	if not _ghost_path.is_empty():
		_show(_ghost_path.pop_front())
		if _ghost_path.is_empty():
			_ghost_timer = _rng.randf_range(GHOST_HOLD.x, GHOST_HOLD.y)
			if _rng.randf() < GHOST_DING:
				Game.sound_at("ding", _landing_point(_shown), MOTOR_RANGE * 0.5)
		else:
			_ghost_timer = _rng.randf_range(GHOST_STEP.x, GHOST_STEP.y)
	elif _shown >= 0:
		_show(-1)
		_ghost_timer = _rng.randf_range(GHOST_PAUSE.x, GHOST_PAUSE.y)
	else:
		var from := _rng.randi_range(0, stops.size() - 1)
		var to := (from + _rng.randi_range(1, stops.size() - 1)) % stops.size()
		var step := 1 if to > from else -1
		for i in range(from, to + step, step):
			_ghost_path.append(i)
		_ghost_timer = 0.0


# --- Namen ------------------------------------------------------------------------------------------------------

## Beschriftung des Halts i auf Anzeige und Knopf: U (Untergeschoss), 0 (Erdgeschoss), 1 … (Obergeschosse),
## T (Tiefkeller, 7.4).
func _label(i: int) -> String:
	var level := levels[i]
	if level < -1:
		return "T"
	return "U" if level == -1 else str(level)


func _floor_name(i: int) -> String:
	var level := levels[i]
	if level < -1:
		return "Tiefkeller"
	match level:
		-1:
			return "Untergeschoss"
		0:
			return "Erdgeschoss"
	return "%d. Obergeschoss" % level


## Tür am Halt der Kabine öffnen und eine Minute offen halten (Debug: --aufzug=offen).
func open_doors() -> void:
	_open()
	_hold = DEBUG_HOLD


## Fahrt ins oberste Stockwerk (bzw. ins EG, wenn sie schon oben steht) wählen (Debug: --aufzug=fahrt).
func ride_to_top() -> void:
	_request(stops.size() - 1 if _at != stops.size() - 1 else maxi(0, levels.find(0)), true)


## Steht pos (Welt, Füße) in der Kabine dieses Aufzugs?
func carries(pos: Vector3) -> bool:
	if not working:
		return false
	var p := to_local(pos)
	var floor_y := _cab_y - position.y
	return p.y > floor_y - 0.3 and p.y < floor_y + CAB_H and absf(p.x) < _cab_side and p.z < _cab_front and p.z > _cab_back


## Fährt die Kabine gerade?
func moving() -> bool:
	return _target >= 0


## Der Halt, an dem die Kabine als Nächstes steht: ihr Fahrtziel, sonst der, an dem sie steht.
func next_stop() -> int:
	return _target if _target >= 0 else maxi(0, _at)


## Wo man vor der Tür am Halt i auf die Kabine wartet (Welt, Boden): so weit vor der Schachtwand, dorthin sieht man.
func waiting_spot(i: int, out: float = 1.2) -> Array[Vector3]:
	var y := stops[i] - position.y
	return [to_global(Vector3(0, y, out)), to_global(Vector3(0, y + 1.2, 0))]


## Den Rufknopf am Halt i drücken (Spielkonzept 4.33: das Monster an der Haltestelle) – steht die Kabine dort mit
## geschlossener Tür, geht sie auf.
func call_cabin(i: int) -> void:
	_request(i, false)


## Wo man steht und wohin man schaut (Welt) – vor der Tür am Halt der Kabine oder darin mit Blick aufs Bedienfeld
## (Debug: --aufzug).
func spot(inside: bool) -> Array[Vector3]:
	var y := stops[_at if _at >= 0 else 0] - position.y
	if inside:
		return [to_global(Vector3(-_cab_side + 0.75, y, _cab_front - PANEL_Z - 0.35)), global_basis * Vector3(-1, 0, 0.45).normalized()]
	return [to_global(Vector3(0, y, 3.0)), global_basis * Vector3.FORWARD]


# --- Speichern --------------------------------------------------------------------------------------------------

func save_state() -> Dictionary:
	var queue := _queue.duplicate()
	if _target >= 0:
		queue.push_front(_target)
	return {"y": _cab_y, "queue": queue, "open": _door > 0.5 and _door_dir >= 0}


## Kabine an die gespeicherte Höhe; war sie unterwegs, fährt sie zum Ziel weiter.
func load_state(d: Dictionary) -> void:
	_cab_y = float(d.get("y", stops[maxi(0, levels.find(0))]))
	cabin.position.y = _cab_y - position.y
	_queue.clear()
	for i in d.get("queue", []):
		_queue.append(int(i))
	for i in _lit.size():
		_lit[i] = i in _queue
		_set_glow(_button_mats[i], _lit[i])
	_at = -1
	_target = -1
	_door_dir = 0
	_door = 0.0
	for i in stops.size():
		if absf(stops[i] - _cab_y) < 0.001:
			_at = i
	if _at < 0:   # zwischen zwei Halten gespeichert
		var goal: int = _queue.pop_front() if not _queue.is_empty() else 0
		_target = goal
	elif bool(d.get("open", false)):
		_door = 1.0
		_hold = DOOR_HOLD
	_apply_doors()
