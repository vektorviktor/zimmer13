class_name PipeKit
extends RefCounted
## Rohrbaukasten (Heizkeller, Spielkonzept 7.9; Modell `assets/models/pipes.glb` aus tools/build_boiler.py): Rohre mit
## 0,2 m Durchmesser aus geraden Stücken (2 / 1 / 0,5 m, der Rest gestaucht), Bögen, T- und Kreuzstücken, Flanschen und
## Enden. Im Modell liegt jedes Teil mit der Rohrachse auf +X (Bogen: Arme nach −X und +Y; T-Stück: −X, +X, +Y);
## `piece` dreht es über zwei Achsen an seinen Platz. Nur zur Zierde: keine Kollision (die Rohre laufen über Kopfhöhe
## oder dicht an der Wand). Meshes und Materialien sind für alle Teile geteilt.

const MODEL := "res://assets/models/pipes.glb"
## Bogen, T- und Kreuzstück: von der Mitte bis zum Ansatz des geraden Rohrs
const ARM := 0.25
const STRAIGHTS := [["straight_200", 2.0], ["straight_100", 1.0], ["straight_050", 0.5]]
## Halter (Gewindestangen zur Decke bzw. Stützen zum Boden): höchstens so weit auseinander, so dick
const HOLDER_GAP := 2.0
const HOLDER_RADIUS := 0.012

var _parent: Node3D
var _meshes := {}   ## Teil → Mesh
var _mats := {}     ## Teil → Materialien je Fläche
var _iron: ShaderMaterial


func _init(parent: Node3D) -> void:
	_parent = parent
	_iron = Mat.psx(Color(0.13, 0.11, 0.1))
	if not ResourceLoader.exists(MODEL):
		return
	var scene: Node3D = (load(MODEL) as PackedScene).instantiate()
	for m: MeshInstance3D in scene.find_children("*", "MeshInstance3D", true, false):
		var mats: Array[Material] = []
		for s in m.mesh.get_surface_count():
			var src := m.mesh.surface_get_material(s) as BaseMaterial3D
			mats.append(Mat.model(MODEL, m, s) if src and src.albedo_texture else Mat.psx(src.albedo_color if src else Color.BLACK))
		_meshes[String(m.name)] = m.mesh
		_mats[String(m.name)] = mats
	scene.free()


## Ein Teil an pos: seine +X-Achse zeigt nach x_axis, +Y nach y_axis (beide normiert, senkrecht zueinander);
## stretch streckt es entlang X. null ohne Modell.
func piece(part: String, pos: Vector3, x_axis: Vector3, y_axis: Vector3, stretch := 1.0) -> MeshInstance3D:
	if not _meshes.has(part):
		return null
	var mi := MeshInstance3D.new()
	mi.mesh = _meshes[part]
	var mats: Array = _mats[part]
	for s in mats.size():
		mi.set_surface_override_material(s, mats[s])
	mi.transform = Transform3D(Basis(x_axis * stretch, y_axis, x_axis.cross(y_axis)), pos)
	_parent.add_child(mi)
	return mi


## Gerades Rohr von a nach b: 2-m-Stücke, dann 1 und 0,5 m, den Rest gestaucht; an jeder Fuge ein Flansch.
func straight(a: Vector3, b: Vector3) -> void:
	var length := a.distance_to(b)
	if length < 0.01:
		return
	var dir := (b - a) / length
	var side := _side(dir)
	var t := 0.0
	while length - t > 0.005:
		var rest := length - t
		var pick: Array = STRAIGHTS[STRAIGHTS.size() - 1]
		for s: Array in STRAIGHTS:
			if rest >= float(s[1]) - 0.005:
				pick = s
				break
		var seg := minf(float(pick[1]), rest)
		if t > 0.0:
			piece("flange", a + dir * t, dir, side)
		piece(String(pick[0]), a + dir * t, dir, side, seg / float(pick[1]))
		t += seg


## Rohrzug durch die Punkte (achsparallel), an jedem inneren Punkt ein Bogen. Enden start/end: "" offen (läuft in
## Wand, Boden oder Decke), "flange", "cap" (Blindkappe), "open" (offenes Ende mit Kragen), "joint" (dort sitzt ein
## T- oder Kreuzstück – das Rohr endet ARM davor). mount_y: endliche Höhe → waagerechte Stücke bekommen Halter bis
## dorthin (Decke oder Boden).
func run(points: Array[Vector3], start := "", end := "", mount_y := INF) -> void:
	for i in points.size() - 1:
		var a := points[i]
		var b := points[i + 1]
		var dir := (b - a).normalized()
		var from := a + dir * (ARM if i > 0 or start == "joint" else 0.0)
		var to := b - dir * (ARM if i < points.size() - 2 or end == "joint" else 0.0)
		straight(from, to)
		if is_finite(mount_y) and absf(dir.y) < 0.1:
			_holders(from, to, mount_y)
		if i > 0:
			piece("elbow", a, (a - points[i - 1]).normalized(), dir)
	if points.size() >= 2:
		_end(points[0], (points[0] - points[1]).normalized(), start)
		_end(points[-1], (points[-1] - points[-2]).normalized(), end)


## T-Stück an pos: durchgehend entlang along, der Abzweig nach branch.
func tee(pos: Vector3, along: Vector3, branch: Vector3) -> void:
	piece("tee", pos, along, branch)


## Kreuzstück an pos: durchgehend entlang along und entlang cross_axis.
func cross(pos: Vector3, along: Vector3, cross_axis: Vector3) -> void:
	piece("cross", pos, along, cross_axis)


## Rohrende bei p, out zeigt aus dem Rohr hinaus.
func _end(p: Vector3, out: Vector3, kind: String) -> void:
	match kind:
		"flange":
			piece("flange", p, out, _side(out))
		"cap":
			piece("end_cap", p, out, _side(out))
		"open":
			piece("end_open", p, out, _side(out))


## Halter eines waagerechten Stücks von a nach b: Stangen von der Rohrmitte bis zur Höhe y, gleichmäßig verteilt.
func _holders(a: Vector3, b: Vector3, y: float) -> void:
	var count := ceili(a.distance_to(b) / HOLDER_GAP)
	for k in count:
		var p := a.lerp(b, (k + 0.5) / count)
		var h := absf(y - p.y)
		if h > 0.12:
			Geo.mesh(_parent, Geo.cylinder(HOLDER_RADIUS, h, 5), _iron, Vector3(p.x, (p.y + y) / 2.0, p.z))


## Eine Achse senkrecht zu dir (für Teile, deren Drehung um die Rohrachse egal ist): oben, bei senkrechten Rohren
## Richtung +Z.
static func _side(dir: Vector3) -> Vector3:
	var up := Vector3.UP if absf(dir.y) < 0.9 else Vector3.BACK
	return (up - dir * dir.dot(up)).normalized()
