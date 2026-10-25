class_name Scarecrow
extends Node3D
## Die Vogelscheuche, die näher kommt (Spielkonzept 4.30). Bis zum ersten Angriff steht sie ganz hinten im Garten
## (Nordrand, FAR). Danach steht sie jeden Morgen ein Stück näher am Haus – auf der Linie zur gläsernen Gartentür der
## Lobby, mit dem Gesicht zum Hotel. An Halloween steht sie direkt vor der Tür und sieht in die Lobby. Niemand sieht sie
## je wandern: Sie springt nur, wenn der Spieler weder den alten noch den neuen Platz sieht (wie die Puppe, 5.5).
## Keine Bedrohung, keine Mechanik – ein Countdown, den man sehen kann. Gäste in der Lobby wundern sich, wer sie umstellt.
## Gebaut aus Grundkörpern: Pfahl und Querholz, Sack als Kopf mit aufgenähtem Gesicht, Strohhut, alter Mantel, Stroh an
## den Ärmeln. Lage aus dem Kalender, darum nicht gespeichert.

const FAR := Vector3(-3.0, 0.0, -73.0)     ## hinten im Garten (x, z – y vom Boden)
const NEAR := Vector3(-5.5, 0.0, -30.4)    ## vor der Gartentür der Lobby
const FROM_DAY := 3                        ## ab diesem Morgen rückt sie (nach dem ersten Angriff)
const CHECK_EVERY := 2.0
const HEIGHT := 2.2
const COAT := Color(0.2, 0.18, 0.15)
const SACK := Color(0.55, 0.45, 0.3)
const STRAW := Color(0.78, 0.66, 0.32)
const LINES := ["Hat einer die Vogelscheuche umgestellt? Gestern stand sie noch weiter hinten.",
	"Diese Vogelscheuche … ich schwöre, die war gestern nicht so nah.", "Wer stellt nachts die Vogelscheuche um? Das ist nicht witzig.",
	"Sieh nicht hin. Die Vogelscheuche. Sie steht schon wieder näher."]
const TALK_RANGE := 8.0

var step := -1                             ## wie viele Tage sie schon gerückt ist (−1 = noch nicht aufgestellt)
var _builder: LevelBuilder
var _check := 0.0
var _talked_day := 0
var _body: StaticBody3D


func setup(builder: LevelBuilder) -> Scarecrow:
	_builder = builder
	return self


func _ready() -> void:
	_build()
	_place(0.0)


## Wie weit sie gerade sein müsste: 0 = ganz hinten, 1 = vor der Gartentür (an Halloween).
func wanted_k() -> float:
	var d := Game.director
	if d == null or not d.first_attack_done:
		return 0.0
	var days := Calendar.day_of(d.elapsed) - FROM_DAY + 1
	return clampf(float(days) / float(Calendar.HALLOWEEN - FROM_DAY + 1), 0.0, 1.0)


func _process(delta: float) -> void:
	_check -= delta
	if _check > 0.0:
		return
	_check = CHECK_EVERY
	var k := wanted_k()
	var want_pos := _spot(k)
	if want_pos.distance_to(global_position) < 0.05:
		_maybe_talk()
		return
	var d := Game.director
	if d and (d.player_can_see(global_position + Vector3.UP * 1.8) or d.player_can_see(global_position + Vector3.UP * 0.5)
			or d.player_can_see(want_pos + Vector3.UP * 1.8) or d.player_can_see(want_pos + Vector3.UP * 0.5)):
		return
	_place(k)
	if Game.tracing:
		print("[Vogelscheuche] steht jetzt bei %.0f %% des Wegs" % (k * 100.0))


func _spot(k: float) -> Vector3:
	var p := FAR.lerp(NEAR, k)
	var q := PhysicsRayQueryParameters3D.create(p + Vector3.UP * 3.0, p + Vector3.DOWN * 3.0, 1)
	var hit := get_viewport().get_world_3d().direct_space_state.intersect_ray(q) if is_inside_tree() else {}
	if not hit.is_empty():
		p.y = (hit["position"] as Vector3).y
	return p


func _place(k: float) -> void:
	global_position = _spot(k)
	var to_house := NEAR + Vector3(0, 0, 4.0) - global_position   # Gesicht zur Lobby
	rotation.y = atan2(to_house.x, to_house.z) + (sin(k * 17.0) * 0.08)   # nie ganz gerade
	step = roundi(k * (Calendar.HALLOWEEN - FROM_DAY + 1))


## Einmal am Tag wundert sich ein Gast in der Lobby, wenn der Spieler dabei ist.
func _maybe_talk() -> void:
	var d := Game.director
	if d == null or not d.first_attack_done or step < 2 or Game.social == null or Game.player == null:
		return
	var today := Calendar.day_of(d.elapsed)
	if today == _talked_day or not _builder.in_lobby(Game.player.global_position):
		return
	for g in Game.social.living_guests():
		var guest := g as Guest
		if guest.is_child() or guest.state != Guest.State.IDLE or guest.global_position.distance_to(Game.player.global_position) > TALK_RANGE:
			continue
		_talked_day = today
		guest.say(LINES[(today + step) % LINES.size()])
		return


func get_prompt(_player: Player) -> String:
	return "Vogelscheuche ansehen [E]"


func interact(_player: Player) -> void:
	Game.say("Ein Sack mit aufgenähtem Gesicht, Stroh quillt aus den Ärmeln. Der Mantel riecht nach kaltem Rauch.", 4.5)


func _build() -> void:
	var wood := Mat.wood(false, Color(0.75, 0.68, 0.6))
	var coat := Mat.psx(COAT)
	var straw := Mat.psx(STRAW)
	Geo.mesh(self, Geo.cylinder(0.045, HEIGHT, 8), wood, Vector3(0, HEIGHT / 2.0 - 0.3, 0))   # Pfahl, steckt im Boden
	var bar := Geo.mesh(self, Geo.cylinder(0.035, 1.6, 8), wood, Vector3(0, 1.45, 0))
	bar.rotation.z = PI / 2.0
	# Mantel: Rumpf als leicht trapezförmiger Kasten, Ärmel über dem Querholz, Saum ausgefranst
	var torso := Geo.mesh(self, Geo.rounded_box(Vector3(0.55, 0.85, 0.28), 0.06, 2, 0.15), coat, Vector3(0, 1.05, 0))
	torso.rotation.x = 0.04
	for side in [-1.0, 1.0]:
		var sleeve := Geo.mesh(self, Geo.rounded_box(Vector3(0.6, 0.2, 0.2), 0.05, 2, 0.1), coat, Vector3(side * 0.5, 1.44, 0))
		sleeve.rotation.z = side * -0.12
		for t in 5:   # Stroh aus den Ärmeln
			var tuft := Geo.mesh(self, Geo.cylinder(0.006, 0.22, 3), straw, Vector3(side * (0.82 + randf() * 0.05), 1.38 + randf() * 0.08, randf_range(-0.07, 0.07)))
			tuft.rotation = Vector3(randf_range(-0.6, 0.6), 0, side * (PI / 2.0 + randf_range(-0.7, 0.4)))
	for t in 9:   # Stroh unter dem Saum
		var tuft := Geo.mesh(self, Geo.cylinder(0.006, 0.25, 3), straw, Vector3(randf_range(-0.25, 0.25), 0.55, randf_range(-0.1, 0.1)))
		tuft.rotation = Vector3(randf_range(-0.3, 0.3), 0, randf_range(-0.35, 0.35))
	# Kopf: Sack, oben zugeschnürt, mit aufgenähtem Gesicht (Textur), leicht zur Seite geneigt
	var head := Node3D.new()
	head.position = Vector3(0, 1.78, 0)
	head.rotation.z = 0.18
	add_child(head)
	var sack := ShaderMaterial.new()
	sack.shader = load("res://shaders/psx_surface.gdshader")
	sack.set_shader_parameter("albedo", Color(1, 1, 1))
	sack.set_shader_parameter("albedo_tex", _face_texture())
	var face := Geo.mesh(head, Geo.sphere(0.2, 0.42, 16, 8), sack, Vector3.ZERO)
	face.rotation.y = PI   # die Gesichtsmitte der Kugel-UV liegt sonst hinten
	Geo.mesh(head, Geo.cylinder(0.05, 0.08, 8), Mat.psx(SACK), Vector3(0, 0.22, 0))
	# Strohhut mit breiter, welliger Krempe
	Geo.mesh(head, Geo.cylinder(0.38, 0.02, 14), straw, Vector3(0, 0.2, 0)).rotation.x = 0.08
	var crown := CylinderMesh.new()
	crown.top_radius = 0.12
	crown.bottom_radius = 0.17
	crown.height = 0.18
	crown.radial_segments = 12
	Geo.mesh(head, crown, straw, Vector3(0, 0.3, 0))
	_body = StaticBody3D.new()
	_body.collision_layer = 4
	_body.collision_mask = 0
	_body.set_meta("interactable", self)
	Geo.add_box_shape(_body, Vector3(0.6, 1.9, 0.4), Vector3(0, 1.1, 0))
	add_child(_body)


## Gesicht auf dem Sack: grobes Leinen, zwei aufgenähte schwarze Knöpfe als Augen, ein langer genähter Mund mit
## Kreuzstichen – auf der Vorderseite (u = 0,5 der Kugel).
static func _face_texture() -> ImageTexture:
	var w := 128
	var h := 64
	var img := Image.create(w, h, false, Image.FORMAT_RGB8)
	var rng := RandomNumberGenerator.new()
	rng.seed = 31
	for y in h:
		for x in w:
			var weave := 0.06 if (x + y) % 2 == 0 else -0.04
			img.set_pixel(x, y, SACK * (0.85 + weave + rng.randf() * 0.12))
	var cx := w / 2
	for eye in [-9, 9]:
		for y in range(22, 31):
			for x in range(cx + eye - 4, cx + eye + 5):
				if Vector2(x - cx - eye, y - 26).length() < 4.2:
					img.set_pixel(x, y, Color(0.04, 0.035, 0.03))
	for x in range(cx - 14, cx + 15):   # Mund: Naht mit Kreuzstichen, leicht schief
		var y := 40 + int(round(sin((x - cx) * 0.25) * 1.5))
		img.set_pixel(x, y, Color(0.08, 0.06, 0.05))
		if (x - cx) % 4 == 0:
			for k in range(-3, 4):
				img.set_pixel(x, clampi(y + k, 0, h - 1), Color(0.1, 0.08, 0.06))
	return ImageTexture.create_from_image(img)


## Debug (--vogelscheuche[=tag]): Sie steht, wo sie an diesem Tag stünde (ohne Angabe Halloween), du stehst in der
## Lobby vor der Gartentür und siehst hinaus – der erste Angriff gilt als geschehen.
func debug_show(day: String) -> void:
	var d := Game.director
	d.first_attack_done = true
	var target := Calendar.HALLOWEEN if day == "" else clampi(day.to_int(), 1, Calendar.HALLOWEEN)
	d.elapsed = maxf(d.elapsed, Calendar.at(target, 21.0)) if day == "" else Calendar.at(target, 21.0)
	_place(wanted_k())
	var stand := NEAR + Vector3(0.6, 0.05, 6.0)
	TeleportUI.place_player(stand, global_position + Vector3.UP * 1.0 - stand)
