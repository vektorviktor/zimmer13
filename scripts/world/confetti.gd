class_name Confetti
extends Node3D
## Konfetti (Spielkonzept 7.6, entschieden 2026-10-21): Zu Beginn einer Feier und dann alle paar Sekunden schießt
## Konfetti über der Tanzfläche hoch und rieselt herab (CPUParticles3D, bunte Schnipsel); zum Abschluss eines großen
## Schmückens auch dort (Decorating). Was landet, bleibt als Decals am Boden liegen und verblasst langsam
## (höchstens MAX_DECALS, die ältesten gehen zuerst). Nicht gespeichert. Erreichbar über Game.confetti.

const COLORS: Array[Color] = [Color(0.95, 0.2, 0.25), Color(1.0, 0.75, 0.1), Color(0.25, 0.85, 0.35), Color(0.2, 0.5, 1.0),
	Color(0.8, 0.3, 0.95), Color(1.0, 0.5, 0.1)]
## Feier: großer Schuss zu Beginn, dann alle PARTY_GAP Sekunden einer über einem Tanzplatz, so hoch
const PARTY_GAP := Vector2(10.0, 22.0)
const START_AMOUNT := 90
const SHOT_AMOUNT := 45
const SHOT_HEIGHT := 2.8
const LIFETIME := 3.2
## Am Boden: je so viele Schnipsel ein Decal, höchstens so viele im Hotel, so lange bis verblasst
const PER_DECAL := 8
const MAX_DECALS := 80
const DECAL_LIFE := 900.0
const DECAL_SIZE := Vector2(0.5, 1.0)

var _texture: ImageTexture
var _decals: Array[Dictionary] = []   ## {decal, age}
var _was_party := false
var _shot_timer := 0.0


func _ready() -> void:
	Game.confetti = self
	_texture = ImageTexture.create_from_image(_paper_image())


## Ein Schuss Konfetti bei `pos` (Mitte, in der Luft): fliegt hoch und rieselt herab, landet als Decals.
func burst(pos: Vector3, amount: int) -> void:
	var p := CPUParticles3D.new()
	p.one_shot = true
	p.explosiveness = 0.92
	p.amount = amount
	p.lifetime = LIFETIME
	p.local_coords = false
	p.direction = Vector3.UP
	p.spread = 55.0
	p.initial_velocity_min = 1.8
	p.initial_velocity_max = 3.6
	p.gravity = Vector3(0, -2.2, 0)
	p.damping_min = 1.2
	p.damping_max = 2.4
	p.angular_velocity_min = -360.0
	p.angular_velocity_max = 360.0
	p.particle_flag_rotate_y = true
	p.scale_amount_min = 0.7
	p.scale_amount_max = 1.3
	var colors := Gradient.new()
	colors.interpolation_mode = Gradient.GRADIENT_INTERPOLATE_CONSTANT
	colors.set_color(0, COLORS[0])
	colors.set_offset(1, 1.0)
	colors.set_color(1, COLORS[COLORS.size() - 1])
	for i in range(1, COLORS.size() - 1):
		colors.add_point(float(i) / COLORS.size(), COLORS[i])
	p.color_initial_ramp = colors
	var quad := QuadMesh.new()
	quad.size = Vector2(0.035, 0.05)
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	mat.roughness = 0.6
	quad.material = mat
	p.mesh = quad
	add_child(p)
	p.global_position = pos
	p.emitting = true
	get_tree().create_timer(LIFETIME * 2.0, false).timeout.connect(p.queue_free)
	# Was herunterkommt, bleibt liegen – kurz nach der Landung
	var spread := 0.8 + amount / 40.0
	get_tree().create_timer(LIFETIME * 0.6, false).timeout.connect(func() -> void:
		for i in maxi(1, amount / PER_DECAL):
			var r := sqrt(randf()) * spread
			var a := randf() * TAU
			_lay(pos + Vector3(cos(a) * r, 0, sin(a) * r)))


func _process(delta: float) -> void:
	for i in range(_decals.size() - 1, -1, -1):
		var e: Dictionary = _decals[i]
		e["age"] = float(e["age"]) + delta
		var decal: Decal = e["decal"]
		var left := 1.0 - float(e["age"]) / DECAL_LIFE
		if left <= 0.0:
			decal.queue_free()
			_decals.remove_at(i)
		elif left < 0.3:
			decal.modulate.a = left / 0.3
	var social := Game.social
	if social == null or Game.game_over:
		return
	if social.party_active and not _was_party:
		burst(social.party_center() + Vector3.UP * SHOT_HEIGHT, START_AMOUNT)
		_shot_timer = randf_range(PARTY_GAP.x, PARTY_GAP.y)
	_was_party = social.party_active
	if not social.party_active:
		return
	_shot_timer -= delta
	if _shot_timer <= 0.0:
		_shot_timer = randf_range(PARTY_GAP.x, PARTY_GAP.y)
		var spots: Array[Vector3] = social.builder.party_spots
		var at: Vector3 = spots[randi() % mini(spots.size(), 12)] if not spots.is_empty() else social.party_center()
		burst(at + Vector3.UP * SHOT_HEIGHT, SHOT_AMOUNT)


## Ein Fleck Konfetti am Boden unter `above` (Strahl nach unten auf Ebene 1).
func _lay(above: Vector3) -> void:
	var space := get_world_3d().direct_space_state
	var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(above, above + Vector3.DOWN * 6.0, 1))
	if hit.is_empty():
		return
	var decal := Decal.new()
	var s := randf_range(DECAL_SIZE.x, DECAL_SIZE.y)
	decal.size = Vector3(s, 0.3, s)
	decal.texture_albedo = _texture
	decal.upper_fade = 0.3
	decal.lower_fade = 0.3
	add_child(decal)
	decal.global_position = (hit["position"] as Vector3) + Vector3.UP * 0.05
	decal.rotation.y = randf() * TAU
	_decals.append({"decal": decal, "age": 0.0})
	while _decals.size() > MAX_DECALS:
		(_decals.pop_front()["decal"] as Decal).queue_free()


## Papierschnipsel auf durchsichtigem Grund (128², pixelig) – ein Bild für alle Decals, Drehung sorgt für Abwechslung.
func _paper_image() -> Image:
	var img := Image.create(128, 128, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var rng := RandomNumberGenerator.new()
	rng.seed = 1031
	for i in 70:
		var c: Color = COLORS[i % COLORS.size()]
		var cx := rng.randi_range(4, 123)
		var cy := rng.randi_range(4, 123)
		var w := rng.randi_range(2, 4)
		var h := rng.randi_range(3, 6)
		if rng.randf() < 0.5:
			var t := w
			w = h
			h = t
		var shade := rng.randf_range(0.8, 1.0)
		for x in range(cx - w / 2, cx + (w + 1) / 2):
			for y in range(cy - h / 2, cy + (h + 1) / 2):
				img.set_pixel(clampi(x, 0, 127), clampi(y, 0, 127), Color(c.r * shade, c.g * shade, c.b * shade, 1.0))
	return img
