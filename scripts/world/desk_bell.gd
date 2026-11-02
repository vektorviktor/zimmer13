class_name DeskBell
extends StaticBody3D
## Tischklingel auf dem Rezeptionstresen (Spielkonzept 2.9: „Dort ist niemand, nur die Klingel.“, ZIM-146): runder
## Fuß aus schwarzem Lack mit gerundeter Oberkante, darüber auf einem kurzen Stift die Glocke aus Messing (halbes
## Ellipsoid, innen hohl), oben der Drücker mit flachem Knopf. [E] schlägt sie an: der Drücker geht hinunter, es
## klingelt hell (Lärm „desk_bell“) – niemand kommt.
## Low Poly und ganz im Code gedreht (_lathe): Unterteilungen stehen in SIDES … KNOB_STEPS und lassen sich frei
## ändern. Texturen vom Mülleimer (tools/trash_can.gd): Bürstung ringsum wie die Drehriefen einer gedrückten Glocke.
## Ursprung mittig auf der Unterseite des Fußes; rund, die Richtung ist egal.

## Fuß: Radius, Höhe, Fase unten, Rundung der Oberkante
const BASE_R := 0.045
const BASE_H := 0.016
const BASE_CHAMFER := 0.0015
const BASE_ROUND := 0.004
## Glocke: Radius am Rand, Höhe über dem Rand, Wandstärke, Luft zwischen Rand und Fuß; Stift darunter
const DOME_R := 0.038
const DOME_H := 0.03
const DOME_T := 0.0015
const DOME_GAP := 0.004
const POST_R := 0.005
## Drücker: Stange (Radius, so weit über der Glocke), Knopf (Radius, Höhe, Rundung), Hub beim Anschlagen
const ROD_R := 0.0022
const ROD_H := 0.009
const KNOB_R := 0.0065
const KNOB_H := 0.004
const KNOB_ROUND := 0.0015
const PRESS := 0.004
## Unterteilungen: Segmente ringsum (Fuß und Glocke, Stift und Drücker), Schritte über die Glockenwölbung, je
## gerundeter Kante (Viertelkreis)
const SIDES := 24
const SMALL_SIDES := 10
const DOME_STEPS := 8
const ROUND_STEPS := 3
const KNOB_STEPS := 2
## Profilknicke unter so viel Grad werden weich schattiert
const CREASE := 40.0
## Texturen (= TrashCan, dort steht auch der Grund für das nur teils metallische Messing)
const BRASS_TEX := TrashCan.BRASS_TEX
const COAT_TEX := TrashCan.COAT_TEX
const TEX_METERS := TrashCan.BRASS_METERS
const BRASS_METALLIC := TrashCan.BRASS_METALLIC
## Anschlagen: Drücker hinunter und wieder hoch (s); frühestens so bald wieder; ab so viel Pause (Spielzeit, s) kommt
## wieder ein Gedanke
const DOWN_TIME := 0.04
const UP_TIME := 0.12
const COOLDOWN := 0.35
const THOUGHT_PAUSE := 30.0
const THOUGHTS := ["Niemand kommt.", "Der Ton verhallt in der Halle. Niemand kommt.", "Nichts. Nur das Nachklingen.",
	"Hinter dem Tresen bleibt es leer."]

## Fertige Meshes (Fuß, Glocke mit Stift, Drücker) – teilt sich jede Klingel
static var _meshes: Array = []

var _plunger: Node3D
var _busy := 0.0
var _last_ring := -INF


func _ready() -> void:
	collision_layer = 4
	collision_mask = 0
	set_meta("interactable", self)
	add_to_group("desk_bells")
	if _meshes.is_empty():
		_meshes = _build()
	var brass := Mat.photo(BRASS_TEX + ".png", TEX_METERS, BRASS_TEX + "_normal.png", BRASS_TEX + "_rough.png", 0.5,
		Color(1, 1, 1), false, true)
	brass.set_shader_parameter("metallic", BRASS_METALLIC)
	var coat := Mat.photo(COAT_TEX + ".png", TEX_METERS, COAT_TEX + "_normal.png", COAT_TEX + "_rough.png", 0.5,
		Color(1, 1, 1), false, true)
	Geo.mesh(self, _meshes[0], coat, Vector3.ZERO)
	Geo.mesh(self, _meshes[1], brass, Vector3.ZERO)
	_plunger = Node3D.new()
	add_child(_plunger)
	Geo.mesh(_plunger, _meshes[2], brass, Vector3.ZERO)
	var top := _dome_top()
	Geo.add_box_shape(self, Vector3(BASE_R * 2.0, top + ROD_H + KNOB_H, BASE_R * 2.0),
		Vector3(0, (top + ROD_H + KNOB_H) / 2.0, 0))


func _process(delta: float) -> void:
	_busy = maxf(0.0, _busy - delta)


func get_prompt(_player: Player) -> String:
	return "Klingeln [E]"


func interact(player: Player) -> void:
	if _busy > 0.0:
		return
	_busy = COOLDOWN
	var tw := create_tween()
	tw.tween_property(_plunger, "position:y", -PRESS, DOWN_TIME)
	tw.tween_property(_plunger, "position:y", 0.0, UP_TIME).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	Game.noise("desk_bell", global_position + Vector3.UP * _dome_top(), player)
	var now := Game.director.elapsed if Game.director else 0.0
	if now - _last_ring >= THOUGHT_PAUSE:
		get_tree().create_timer(1.2, false).timeout.connect(Game.say.bind(String(THOUGHTS.pick_random()), 2.5))
	_last_ring = now


## Höhe des Glockenscheitels über der Unterseite
static func _dome_top() -> float:
	return BASE_H + DOME_GAP + DOME_H


## Profile als (Radius, Höhe), jeweils in einer Laufrichtung, damit die Normalen nach außen zeigen (wie Geo.lathe):
## Fuß von der Mitte der Unterseite über Fase, Seite und Rundung zur Mitte oben; Glocke vom Loch innen hinunter, um
## den Rand und außen hinauf zum Loch, der Stift darunter; Drücker von der Stange in der Glocke über den Knopf
static func _build() -> Array:
	var base := [Vector2(0, 0), Vector2(BASE_R - BASE_CHAMFER, 0), Vector2(BASE_R, BASE_CHAMFER),
		Vector2(BASE_R, BASE_H - BASE_ROUND)]
	base.append_array(_arc(Vector2(BASE_R - BASE_ROUND, BASE_H - BASE_ROUND), BASE_ROUND, 0.0, ROUND_STEPS))
	base.append(Vector2(0, BASE_H))
	var y0 := BASE_H + DOME_GAP
	var hole := ROD_R + 0.0005
	var outer := _dome(DOME_R, DOME_H, y0, hole)
	var inner := _dome(DOME_R - DOME_T, DOME_H - DOME_T, y0, hole)
	inner.reverse()
	var dome := [outer[-1]] + inner + outer   # vorn die Wand des Lochs
	var post_top := y0 + DOME_H - DOME_T * 1.5   # knapp unter der Innenseite des Scheitels
	var post := [Vector2(0, BASE_H), Vector2(POST_R, BASE_H), Vector2(POST_R, post_top), Vector2(0, post_top)]
	var rod_y := y0 + DOME_H - DOME_T * 3.0
	var top := _dome_top() + ROD_H
	var plunger := [Vector2(0, rod_y), Vector2(ROD_R, rod_y), Vector2(ROD_R, top), Vector2(KNOB_R - KNOB_ROUND, top)]
	plunger.append_array(_arc(Vector2(KNOB_R - KNOB_ROUND, top + KNOB_ROUND), KNOB_ROUND, -PI / 2.0, KNOB_STEPS))
	plunger.append(Vector2(KNOB_R, top + KNOB_H - KNOB_ROUND))
	plunger.append_array(_arc(Vector2(KNOB_R - KNOB_ROUND, top + KNOB_H - KNOB_ROUND), KNOB_ROUND, 0.0, KNOB_STEPS))
	plunger.append(Vector2(0, top + KNOB_H))
	var sh := GrandStair.Shape.new()
	_lathe(sh, dome, SIDES)
	_lathe(sh, post, SMALL_SIDES)
	var foot := GrandStair.Shape.new()
	_lathe(foot, base, SIDES)
	var push := GrandStair.Shape.new()
	_lathe(push, plunger, SMALL_SIDES)
	return [foot.commit(), sh.commit(), push.commit()]


## Viertelkreis um c mit Radius r ab Winkel from (0 = außen, gegen den Uhrzeigersinn nach oben), ohne Startpunkt
static func _arc(c: Vector2, r: float, from: float, steps: int) -> Array:
	var out := []
	for k in range(1, steps + 1):
		var a := from + PI / 2.0 * k / steps
		out.append(c + Vector2(cos(a), sin(a)) * r)
	return out


## Glockenwand als halbes Ellipsoid (Radius r am Rand, Höhe h über y0) vom Rand hinauf bis zum Loch
static func _dome(r: float, h: float, y0: float, hole: float) -> Array:
	var end := acos(hole / r)
	var out := []
	for k in DOME_STEPS + 1:
		var a := end * k / DOME_STEPS
		out.append(Vector2(r * cos(a), y0 + h * sin(a)))
	return out


## Dreht das Profil um die senkrechte Achse (sides Segmente). Normalen weich, wo der Knick unter CREASE bleibt; UVs
## in Metern: u ringsum (Bürstung als Drehriefen), v entlang des Profils.
static func _lathe(sh: GrandStair.Shape, profile: Array, sides: int) -> void:
	var seg_n: Array[Vector2] = []
	var seg_v: Array[float] = [0.0]
	for i in profile.size() - 1:
		var t: Vector2 = profile[i + 1] - profile[i]
		seg_n.append(Vector2(t.y, -t.x).normalized())
		seg_v.append(seg_v[-1] + t.length())
	var limit := cos(deg_to_rad(CREASE))
	for i in seg_n.size():
		var ends := []
		for e in [[i, i - 1], [i + 1, i + 1]]:
			var n := seg_n[i]
			var k: int = e[1]
			if k >= 0 and k < seg_n.size() and seg_n[k].dot(n) > limit:
				n = (n + seg_n[k]).normalized()
			ends.append([profile[e[0]], n, seg_v[e[0]]])
		for j in sides:
			var quad := []
			for c in [[0, j], [0, j + 1], [1, j + 1], [1, j]]:
				var p: Vector2 = ends[c[0]][0]
				var n: Vector2 = ends[c[0]][1]
				var phi := TAU * float(c[1]) / sides
				var d := Vector3(cos(phi), 0, sin(phi))
				quad.append([d * p.x + Vector3.UP * p.y, d * n.x + Vector3.UP * n.y, Vector2(p.x * phi, ends[c[0]][2])])
			if is_zero_approx((quad[0][0] as Vector3).distance_to(quad[1][0])) and \
					is_zero_approx((quad[2][0] as Vector3).distance_to(quad[3][0])):
				continue   # auf der Achse
			sh.tri(quad[0][0], quad[1][0], quad[2][0], quad[0][1], quad[1][1], quad[2][1], quad[0][2], quad[1][2], quad[2][2])
			sh.tri(quad[0][0], quad[2][0], quad[3][0], quad[0][1], quad[2][1], quad[3][1], quad[0][2], quad[2][2], quad[3][2])


# --- Debug ----------------------------------------------------------------------------------

## --klingel[=nah|an]: vor die Rezeption, Blick auf die Klingel. nah: von schräg oben dicht heran · an: schlägt sie
## nach 1 s an (mit --trace steht der Lärm im Protokoll)
func debug(near: bool, ring: bool) -> void:
	var out := global_basis.z
	var side := global_basis.x
	var at := global_position + out * 0.7 + side * 0.25 if not near else global_position + out * 0.35 + side * 0.08
	at.y = 0.0
	TeleportUI.place_player(at, global_position - at)
	Game.player.head.rotation.x = deg_to_rad(-30.0 if not near else -55.0)
	if ring:
		get_tree().create_timer(1.0).timeout.connect(interact.bind(Game.player))
