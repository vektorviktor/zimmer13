class_name TrashCan
extends StaticBody3D
## Mülleimer (Skizze des Nutzers 31.10.): quadratische Säule, 95 cm hoch, 50 × 50 cm. Unten matter, fast schwarzer
## Lack, oben ein Deckel aus gebürstetem Messing, der ringsum einen halben Zentimeter über den Korpus steht. Senkrechte
## Kanten gerundet (Korpus 2 cm, Deckel 2,5 cm – Änderung 31.10.), die Oberkante des Deckels auch, unten scharf. Oben
## eine quadratische Öffnung mit runden Innenecken, scharfkantig ins Innere; darunter ein dunkler Schacht.
## Bürstung waagerecht an jeder Seite, auf der Deckelfläche wie bei einem Bilderrahmen auf Gehrung: jede Seite
## parallel zu ihrer Kante, an den Diagonalen 45° auf Stoß (_mitre_uv).
## Alles aus Ringen mit gerundeten Ecken gezogen (_sweep); Texturen von tools/trash_can.gd. Ursprung am Boden in
## der Mitte, quadratisch – die Richtung ist egal.

## Deckel außen, Höhe, Überstand des Deckels, Radius der senkrechten Kanten am Korpus (am Deckel um den Überstand
## größer, damit er überall gleich weit übersteht), Rundung der Oberkante (höchstens so groß wie der Eckradius des
## Deckels, sonst gibt es keine Ecke mehr, um die sie laufen kann), Höhe des Deckels
const SIZE := 0.5
const HEIGHT := 0.95
const OVERHANG := 0.005
const CORNER := 0.02
const TOP_ROUND := 0.025
const CAP_H := 0.15
## Öffnung: Kantenlänge, Radius ihrer Ecken, wie weit das Messing hinunterreicht,
## Boden des Schachts
const OPENING := 0.3
const OPENING_CORNER := 0.01
const FLANGE := 0.04
const SHAFT_FLOOR := 0.1
## Schritte je Viertelkreis: Ecken im Grundriss, Rundungen im Profil
const CORNER_STEPS := 6
const ROUND_STEPS := 6
## Abstand zur Wand (Vertäfelung, Sockelleiste), wenn der Plan ihn an eine stellt (LevelBuilder)
const WALL_GAP := 0.03
## Texturen (tools/trash_can.gd): Kachelgröße in Metern (Bürstung entlang u); Messing nur teils metallisch wie die
## Plaketten an den Türen (voll metallisch spiegelt es fast nur die dunkle Umgebung), das Innere im Lack, dunkler
const BRASS_TEX := "res://assets/textures/trash_brass"
const COAT_TEX := "res://assets/textures/trash_coat"
const BRASS_METERS := 0.25
const COAT_METERS := 0.25
const BRASS_METALLIC := 0.55
const INSIDE := Color(0.35, 0.35, 0.35)
## Profilknicke unter so viel Grad werden weich schattiert
const CREASE := 35.0

## Fertige Meshes (Lack, Messing, Schacht) – alle Mülleimer teilen sie
static var _meshes: Array = []


func _ready() -> void:
	collision_mask = 0
	if _meshes.is_empty():
		_meshes = _build()
	Geo.mesh(self, _meshes[0], _photo(COAT_TEX, COAT_METERS, Color(1, 1, 1)), Vector3.ZERO)
	var brass := _photo(BRASS_TEX, BRASS_METERS, Color(1, 1, 1))
	brass.set_shader_parameter("metallic", BRASS_METALLIC)
	Geo.mesh(self, _meshes[1], brass, Vector3.ZERO)
	Geo.mesh(self, _meshes[2], _photo(COAT_TEX, COAT_METERS, INSIDE), Vector3.ZERO)
	Geo.add_box_shape(self, Vector3(SIZE, HEIGHT, SIZE), Vector3(0, HEIGHT / 2.0, 0))


static func _photo(base: String, meters: float, tint: Color) -> ShaderMaterial:
	return Mat.photo(base + ".png", meters, base + "_normal.png", base + "_rough.png", 0.5, tint, false, true)


## Profile als (halbe Kantenlänge, Eckradius, Höhe): Korpus von unten bis in den Deckel; Deckel von der Unterseite
## über die gerundete Oberkante und die Fläche bis an die Öffnung, scharf hinunter; Schacht von dort bis zum Boden
static func _build() -> Array:
	var body := SIZE / 2.0 - OVERHANG
	var cap := SIZE / 2.0
	var cap_r := CORNER + OVERHANG
	var y0 := HEIGHT - CAP_H
	var hole := OPENING / 2.0
	var coat := [Vector3(body, CORNER, 0.0), Vector3(body, CORNER, y0 + 0.01)]
	var brass := [Vector3(body - 0.01, CORNER - 0.01, y0), Vector3(cap, cap_r, y0), Vector3(cap, cap_r, HEIGHT - TOP_ROUND)]
	for k in range(1, ROUND_STEPS + 1):
		var a := PI / 2.0 * k / ROUND_STEPS
		var d := TOP_ROUND * (1.0 - cos(a))
		brass.append(Vector3(cap - d, cap_r - d, HEIGHT - TOP_ROUND + TOP_ROUND * sin(a)))
	brass.append(Vector3(hole, OPENING_CORNER, HEIGHT))
	brass.append(Vector3(hole, OPENING_CORNER, HEIGHT - FLANGE))
	var shaft := [Vector3(hole, OPENING_CORNER, HEIGHT - FLANGE), Vector3(hole, OPENING_CORNER, SHAFT_FLOOR),
		Vector3(0.0, 0.0, SHAFT_FLOOR)]
	var out := []
	for profile in [coat, brass, shaft]:
		var sh := GrandStair.Shape.new()
		_sweep(sh, profile)
		out.append(sh.commit())
	return out


## Zieht Ringe mit gerundeten Ecken durch das Profil (wie Geo.lathe, aber quadratisch): je Ring vier Viertelkreise
## mit CORNER_STEPS Schritten, dazwischen die geraden Seiten. UVs in Metern – u ringsum, v entlang des Profils; auf
## waagerechten Abschnitten (Deckelfläche, Unterseite, Boden) je Seite auf Gehrung (_mitre_uv).
static func _sweep(sh: GrandStair.Shape, profile: Array) -> void:
	var seg_n: Array[Vector2] = []   # Normale je Abschnitt in (nach außen, Höhe)
	var seg_v: Array[float] = [0.0]
	for i in profile.size() - 1:
		var t := Vector2(profile[i + 1].x - profile[i].x, profile[i + 1].z - profile[i].z)
		seg_n.append(Vector2(t.y, -t.x).normalized())
		seg_v.append(seg_v[-1] + t.length())
	var limit := cos(deg_to_rad(CREASE))
	for i in seg_n.size():
		var rings := []
		for e in [[i, i - 1], [i + 1, i + 1]]:
			var n := seg_n[i]
			var k: int = e[1]
			if k >= 0 and k < seg_n.size() and seg_n[k].dot(n) > limit:
				n = (n + seg_n[k]).normalized()
			rings.append(_ring(profile[e[0]], n, seg_v[e[0]]))
		var a: Array = rings[0]
		var b: Array = rings[1]
		var flat := is_zero_approx(seg_n[i].x)
		var count := a.size()
		for j in count:
			var p: Array = a[j]
			var q: Array = a[(j + 1) % count]
			var r: Array = b[(j + 1) % count]
			var s: Array = b[j]
			var uv: Array
			if flat:
				var side := _side_of(j)
				uv = [_mitre_uv(p[0], side), _mitre_uv(q[0], side), _mitre_uv(r[0], side), _mitre_uv(s[0], side)]
			else:
				# letzter Abschnitt schließt den Ring: u läuft bis zum Umfang weiter statt zurück auf 0
				uv = [p[2], q[2] if j + 1 < count else Vector2(p[3], q[2].y), r[2] if j + 1 < count else Vector2(s[3], r[2].y), s[2]]
			sh.tri(p[0], q[0], r[0], p[1], q[1], r[1], uv[0], uv[1], uv[2])
			sh.tri(p[0], r[0], s[0], p[1], r[1], s[1], uv[0], uv[2], uv[3])


## Seite (0 = +X, 1 = +Z, 2 = −X, 3 = −Z) des Abschnitts j im Ring: gerade Strecken gehören zu ihrer Seite, die
## Ecken werden in der Mitte bei 45° geteilt (CORNER_STEPS gerade)
static func _side_of(j: int) -> int:
	var c := floori(float(j) / (CORNER_STEPS + 1))
	var k := j % (CORNER_STEPS + 1)
	if k == CORNER_STEPS:
		return (c + 1) % 4
	return roundi(c + (k + 0.5) / CORNER_STEPS) % 4


## UV auf einer waagerechten Fläche für Seite side: u entlang der Kante, v quer dazu (beides in Metern)
static func _mitre_uv(p: Vector3, side: int) -> Vector2:
	var a := PI / 2.0 * side
	return Vector2(p.x * -sin(a) + p.z * cos(a), -(p.x * cos(a) + p.z * sin(a)))


## Ein Ring zum Profilpunkt e = (halbe Kantenlänge, Eckradius, Höhe) mit der Profilnormale n: je Punkt
## [Lage, Normale, UV, Umfang des Rings]
static func _ring(e: Vector3, n: Vector2, v: float) -> Array:
	var core := e.x - e.y
	var points := []
	for c in 4:
		var side := Vector2(1 if c == 0 or c == 3 else -1, 1 if c < 2 else -1)   # Ecke im Viertel c
		for k in CORNER_STEPS + 1:
			var a := PI / 2.0 * (c + float(k) / CORNER_STEPS)
			var dir := Vector3(cos(a), 0, sin(a))
			points.append([Vector3(side.x * core, e.z, side.y * core) + dir * e.y, dir * n.x + Vector3.UP * n.y])
	var length := 0.0
	var out := []
	for j in points.size():
		if j > 0:
			length += (points[j][0] as Vector3).distance_to(points[j - 1][0])
		out.append([points[j][0], points[j][1], Vector2(length, v), 0.0])
	length += (points[-1][0] as Vector3).distance_to(points[0][0])
	for p: Array in out:
		p[3] = length
	return out
