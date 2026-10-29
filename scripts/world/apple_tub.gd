class_name AppleTub
extends StaticBody3D
## Apfeltauchen im Partyraum (Spielkonzept 6.21): ein Holzbottich mit Wasser, darin schwimmende Äpfel. Mit leeren Händen
## [E]: Man beugt sich darüber (Player.stand_at, nur der Blick geht) und taucht mit gehaltenem Linksklick das Gesicht ins
## Wasser – die Sicht verschwimmt, es blubbert (Lärm „apple_tub“). Bleibt das Fadenkreuz lange genug (BITE_TIME) auf einem
## Apfel, beißt man zu und hat ihn (Item.Kind.APPLE); die Äpfel weichen dem Mund aber aus. Die Luft reicht nur BREATH
## Sekunden am Stück, dann kommt man prustend hoch. [E] beendet. Zählt als Spaß (lockt den Kürbismann, 4.19); wer es auf
## einer Feier schafft, wird von den Umstehenden gefeiert.
## **Das Gesicht im Wasser:** Nach dem ersten Angriff, nachts, spiegelt sich beim Hochkommen manchmal ein bleiches Gesicht
## hinter dem eigenen im Wasser – wer sich umdreht, sieht niemanden. Einmal je Feier höchstens.
## Ort: Ausstattung „Apfelbottich“ im Plan, bis dahin SPOT (Südostecke des Partyraums). Die Äpfel wachsen nach
## (APPLES, je Spieltag wieder voll). Nicht gespeichert.

const SPOT := Vector3(20.5, 0.0, -11.0)
const RADIUS := 0.42
const TUB_H := 0.62
const WATER_Y := 0.54
const APPLES := 5
const BITE_TIME := 1.1
const BITE_RANGE := 0.055                ## so nah muss das Fadenkreuz am Apfel sein
const DODGE := 0.12                      ## so schnell weichen die Äpfel dem Mund aus (m/s)
const BREATH := 7.0
const MAX_TIME := 45.0
const CHEER_RANGE := 7.0
const CHEER := 2.0                       ## Beziehung je Umstehendem
const FACE_CHANCE := 0.3
const FACE_TIME := 1.4
const FACE_SHOCK := 0.08
const NOTE := "Beim Apfeltauchen sah ich im Wasser ein bleiches Gesicht hinter meinem. Hinter mir stand niemand."

var active := false
var _apples: Array[Dictionary] = []      ## {node, pos (lokal xz), vel, phase}
var _left := APPLES
var _refill_day := 0
var _under := false
var _breath := BREATH
var _bite := 0.0
var _time := 0.0
var _face: MeshInstance3D
var _face_t := 0.0
var _face_done_day := 0
var _water: MeshInstance3D
var _sound_t := 0.0


func _ready() -> void:
	collision_layer = 1 | 4
	collision_mask = 0
	set_meta("interactable", self)
	position = SPOT
	var wood := Mat.wood(false, Color(0.6, 0.45, 0.32))
	var staves := CylinderMesh.new()
	staves.top_radius = RADIUS
	staves.bottom_radius = RADIUS * 0.9
	staves.height = TUB_H
	staves.radial_segments = 20
	staves.cap_top = false   # oben offen, sonst liegt ein Deckel über Wasser und Äpfeln
	Geo.mesh(self, staves, wood, Vector3(0, TUB_H / 2.0, 0))
	var inner := staves.duplicate() as CylinderMesh   # Innenwand: Flächen nach innen, sonst sieht man durch die Wand
	inner.top_radius = RADIUS - 0.025
	inner.bottom_radius = RADIUS * 0.9 - 0.025
	inner.cap_bottom = false
	inner.flip_faces = true
	Geo.mesh(self, inner, wood, Vector3(0, TUB_H / 2.0, 0))
	var rim := TorusMesh.new()   # Rand der Dauben oben
	rim.inner_radius = RADIUS - 0.027
	rim.outer_radius = RADIUS + 0.002
	rim.rings = 20
	rim.ring_segments = 6
	Geo.mesh(self, rim, wood, Vector3(0, TUB_H, 0))
	for y in [0.1, TUB_H - 0.08]:   # Eisenreifen, offene Ringe
		var hoop := Geo.cylinder(RADIUS * (0.93 if y < 0.3 else 1.0) + 0.006, 0.035, 20).duplicate() as CylinderMesh   # geteilt (Geo-Cache)
		hoop.cap_top = false
		hoop.cap_bottom = false
		Geo.mesh(self, hoop, Mat.metal(Color(0.3, 0.3, 0.32)), Vector3(0, y, 0))
	var water := StandardMaterial3D.new()
	water.albedo_color = Color(0.16, 0.22, 0.2)
	water.roughness = 0.06
	var ripples := NoiseTexture2D.new()   # leichte Wellen, die langsam treiben (_float)
	ripples.noise = FastNoiseLite.new()
	ripples.noise.frequency = 0.03
	ripples.seamless = true
	ripples.as_normal_map = true
	ripples.bump_strength = 4.0
	water.normal_enabled = true
	water.normal_texture = ripples
	water.normal_scale = 0.6
	water.uv1_scale = Vector3(2, 2, 2)
	_water = Geo.mesh(self, Geo.cylinder(RADIUS - 0.03, 0.01, 20), water, Vector3(0, WATER_Y, 0))
	Geo.add_box_shape(self, Vector3(RADIUS * 2.0, TUB_H, RADIUS * 2.0), Vector3(0, TUB_H / 2.0, 0))
	var face_mat := StandardMaterial3D.new()
	face_mat.albedo_texture = _face_texture()
	face_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	face_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	face_mat.albedo_color = Color(1, 1, 1, 0)
	var quad := QuadMesh.new()
	quad.size = Vector2(0.22, 0.28)
	_face = Geo.mesh(self, quad, face_mat, Vector3(0, WATER_Y + 0.008, 0))
	_face.rotation.x = -PI / 2.0
	_face.visible = false
	_refill()


func _refill() -> void:
	for a in _apples:
		(a["node"] as Node3D).queue_free()
	_apples.clear()
	_left = APPLES
	for i in APPLES:
		var node := Node3D.new()
		add_child(node)
		Geo.mesh(node, Geo.sphere(0.04, 0.074, 10, 6), Mat.psx(Color(0.72, 0.08, 0.06) if i % 3 else Color(0.55, 0.7, 0.2)), Vector3.ZERO)
		Geo.mesh(node, Geo.cylinder(0.003, 0.02, 4), Mat.psx(Color(0.3, 0.2, 0.1)), Vector3(0, 0.04, 0))
		var a := TAU * i / APPLES
		_apples.append({"node": node, "pos": Vector2(cos(a), sin(a)) * RADIUS * 0.45, "vel": Vector2.ZERO, "phase": randf() * TAU})


func get_prompt(player: Player) -> String:
	if active:
		return "Linksklick halten: Gesicht ins Wasser · [E] aufhören"
	if _apples.is_empty():
		return "Keine Äpfel mehr im Bottich"
	if player.held:
		return "Apfeltauchen – erst die Hände frei"
	return "Apfeltauchen [E]"


func interact(player: Player) -> void:
	if active:
		_stop(player, "")
		return
	if player.held or _apples.is_empty():
		return
	var to := player.global_position - global_position
	to.y = 0.0
	var at := global_position + to.normalized() * (RADIUS + 0.35)
	at.y = player.global_position.y
	player.stand_at(at, global_position + Vector3.UP * WATER_Y)
	active = true
	_breath = BREATH
	_bite = 0.0
	_time = 0.0
	if Game.tracing:
		print("[Apfeltauchen] beginnt")


func _process(delta: float) -> void:
	var d := Game.director
	if d and Calendar.day_of(d.elapsed) != _refill_day and not active:
		_refill_day = Calendar.day_of(d.elapsed)
		_refill()
	_float(delta)
	_update_face(delta)
	if not active:
		return
	var p := Game.player
	_time += delta
	if Input.is_action_just_pressed("interact") and _time > 0.3:
		_stop(p, "")
		return
	var want_under := Input.is_action_pressed("use_item")
	if want_under != _under:
		_under = want_under
		if _under:
			Game.noise("apple_tub", global_position, p)
		else:
			_surface(p)
	p.fov_zoom = 0.75 if _under else 0.9
	p.intro_blur = 0.55 if _under else 0.0
	if _under:
		_breath -= delta
		_sound_t -= delta
		if _sound_t <= 0.0:
			_sound_t = 1.2
			Game.play_sound("bubble", 0.5)
		_try_bite(p, delta)
		if _breath <= 0.0:
			_under = false
			Game.play_sound("gasp", 0.7)
			Game.say("Prustend kommst du hoch – keine Luft mehr.", 2.5)
			_breath = BREATH
			_surface(p)
	else:
		_breath = minf(BREATH, _breath + delta * 1.5)
	if _time > MAX_TIME or p.dead or (d and not d.is_quiet(global_position, 12.0)):
		_stop(p, "Du richtest dich auf.")


## Wo das Fadenkreuz die Wasserfläche trifft (lokal, xz) – INF, wenn es daneben zeigt.
func _aim(p: Player) -> Vector2:
	var cam := p.camera
	var from := to_local(cam.global_position)
	var dir := global_transform.basis.inverse() * -cam.global_transform.basis.z
	if dir.y >= -0.05:
		return Vector2.INF
	var t := (WATER_Y - from.y) / dir.y
	var hit := from + dir * t
	return Vector2(hit.x, hit.z)


func _try_bite(p: Player, delta: float) -> void:
	var aim := _aim(p)
	if not aim.is_finite():
		_bite = 0.0
		return
	var best := -1
	for i in _apples.size():
		var pos: Vector2 = _apples[i]["pos"]
		if pos.distance_to(aim) < BITE_RANGE * 2.5:
			_apples[i]["vel"] = (pos - aim).normalized() * DODGE   # weicht aus
		if pos.distance_to(aim) < BITE_RANGE and (best < 0 or pos.distance_to(aim) < (_apples[best]["pos"] as Vector2).distance_to(aim)):
			best = i
	if best < 0:
		_bite = maxf(0.0, _bite - delta)
		return
	_bite += delta
	if _bite < BITE_TIME:
		return
	_bite = 0.0
	(_apples[best]["node"] as Node3D).queue_free()
	_apples.remove_at(best)
	Game.play_sound("bite", 0.8)
	_stop(p, "Erwischt! Du kommst mit dem Apfel zwischen den Zähnen hoch.")
	p.receive_item(Item.create(Item.Kind.APPLE))
	if Game.social and Game.social.party_active:
		var cheered := 0
		for g in Game.social.living_guests():
			var guest := g as Guest
			if guest.global_position.distance_to(global_position) < CHEER_RANGE and guest.state == Guest.State.PARTY:
				Game.social.change_relation(guest, CHEER)
				cheered += 1
				if cheered == 1:
					guest.say("Bravo! Mit den Zähnen!")


func _surface(p: Player) -> void:
	p.intro_blur = 0.0
	var d := Game.director
	var day := Calendar.day_of(d.elapsed) if d else 0
	if d and d.first_attack_done and Calendar.phase() == Calendar.Phase.NIGHT and day != _face_done_day and randf() < FACE_CHANCE:
		_face_done_day = day
		show_face(p)


## Das bleiche Gesicht im Wasser: hinter dem eigenen Spiegelbild, also auf der Seite des Spielers.
func show_face(p: Player) -> void:
	var toward := to_local(p.global_position)
	var v := Vector2(toward.x, toward.z).normalized() * RADIUS * 0.35
	_face.position = Vector3(v.x, WATER_Y + 0.008, v.y)
	_face.rotation = Vector3(-PI / 2.0, atan2(v.x, v.y), 0)
	_face.visible = true
	_face_t = FACE_TIME
	p.shock = minf(1.0, p.shock + FACE_SHOCK)
	if Game.notebook:
		Game.notebook.add_note("apple_face", NOTE, "Partyraum")
	if Game.tracing:
		print("[Apfeltauchen] ein Gesicht im Wasser")


func _update_face(delta: float) -> void:
	if not _face.visible:
		return
	_face_t -= delta
	var k := clampf(minf(FACE_TIME - _face_t, _face_t) / 0.4, 0.0, 1.0)
	(_face.material_override as StandardMaterial3D).albedo_color = Color(1, 1, 1, k * 0.7)
	if _face_t <= 0.0:
		_face.visible = false


func _stop(p: Player, text: String) -> void:
	active = false
	_under = false
	p.intro_blur = 0.0
	p.leave_oche()
	if text != "":
		Game.say(text, 3.0)


## Äpfel schaukeln auf dem Wasser, treiben langsam, stoßen an den Rand.
func _float(delta: float) -> void:
	var w := _water.material_override as StandardMaterial3D
	w.uv1_offset += Vector3(0.01, 0.006, 0) * delta * (4.0 if _under else 1.0)
	for a in _apples:
		var pos: Vector2 = a["pos"]
		var vel: Vector2 = a["vel"]
		pos += vel * delta
		vel = vel.move_toward(Vector2.ZERO, delta * 0.15)
		if pos.length() > RADIUS - 0.08:
			pos = pos.normalized() * (RADIUS - 0.08)
			vel = vel.bounce(pos.normalized()) * 0.5
		a["pos"] = pos
		a["vel"] = vel
		a["phase"] = float(a["phase"]) + delta * 1.3
		var node: Node3D = a["node"]
		node.position = Vector3(pos.x, WATER_Y + 0.012 + sin(float(a["phase"])) * 0.006, pos.y)
		node.rotation.z = sin(float(a["phase"]) * 0.7) * 0.3


## Bleiches Gesicht, dunkle Augenhöhlen, offener Mund – weich am Rand, damit es aus dem Wasser auftaucht.
static func _face_texture() -> ImageTexture:
	var img := Image.create(48, 64, false, Image.FORMAT_RGBA8)
	for y in 64:
		for x in 48:
			var d := Vector2((x - 24.0) / 20.0, (y - 30.0) / 28.0)
			var a := clampf(1.0 - d.length(), 0.0, 1.0)
			var c := Color(0.8, 0.82, 0.8, a * 1.6)
			for eye: Vector2 in [Vector2(16, 26), Vector2(32, 26)]:
				if Vector2(x, y).distance_to(eye) < 4.5:
					c = Color(0.05, 0.05, 0.06, a * 2.0)
			if Vector2((x - 24.0) / 4.0, (y - 44.0) / 6.0).length() < 1.0:
				c = Color(0.08, 0.06, 0.06, a * 2.0)
			img.set_pixel(x, y, c)
	return ImageTexture.create_from_image(img)


## Debug (--apfel[=gesicht]): du stehst über dem Bottich und tauchst gleich · gesicht: Nacht, der erste Angriff gilt als
## geschehen, beim Hochkommen ist das Gesicht sicher da.
func debug(what: String) -> void:
	var p := Game.player
	if what == "gesicht":
		Game.director.first_attack_done = true
		var day := Calendar.day_of(Game.director.elapsed)
		if Calendar.phase() != Calendar.Phase.NIGHT:
			Game.director.elapsed = Calendar.at(day, 23.5)
		_face_done_day = -1
		get_tree().create_timer(2.0, false).timeout.connect(show_face.bind(p))
	var front := global_position + Vector3(0, 0.05, -1.2)
	TeleportUI.place_player(front, global_position - front)
	interact(p)
