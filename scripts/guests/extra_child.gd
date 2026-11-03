class_name ExtraChild
extends StaticBody3D
## Das Kind zu viel (Spielkonzept 4.31). Ab dem 25. (Kostüme, 5.9), abends und nachts, nach dem ersten Angriff: Klopft
## ein Kind zu Süßes oder Saures an Zimmer 13 und die Tür ist offen, steht manchmal ein zweites dahinter – kleiner, in
## einem alten, vergilbten Laken mit Flecken, Schuhe von früher. Das echte Kind bemerkt es nicht. Es ist das Kind von
## 1987, das nicht hinauskam (K7, HANDLUNG.md): das Kichern auf dem Dachboden.
## Spricht man es an ([E]), sagt es einen Satz; gibt man ihm eine Süßigkeit (aus Hand oder Tasche), bedankt es sich.
## Sobald niemand hinsieht, ist es fort – mit einem Kichern. Hat es etwas bekommen, liegt die Süßigkeit danach verstaubt
## oben im Dachboden neben dem Kopf des Kürbismanns.
## Höchstens einmal am Spieltag, MAX_VISITS insgesamt (gespeichert unter „omens“).

const FROM_DAY := 25
const CHANCE := 0.45                  ## je Kind an der offenen Tür
const MAX_VISITS := 3
const HEIGHT := 1.22
const SHEET := Color(0.78, 0.72, 0.58)   ## vergilbt
const STAIN := Color(0.55, 0.45, 0.3)
const BEHIND := Vector3(0.75, 0, 0.9)    ## neben und hinter dem echten Kind (in dessen Blickrichtung gesehen)
const LINES := ["Hast du Süßes? Wir dürfen nicht nach Hause.", "Ist das Fest schon vorbei? Die anderen sind weg.",
	"Ich hab mich versteckt. Oben. Da findet mich keiner."]
const THANKS := "Danke. Das heb ich mir auf."

var visits := 0
var _last_day := 0
var _kid: Guest
var _given := false
var _talked := false
var _seen := false
var _time := 0.0
var _sheet: MeshInstance3D


func _ready() -> void:
	collision_layer = 4
	collision_mask = 0
	set_meta("interactable", self)
	visible = false
	_build()


func save_state() -> Dictionary:
	return {"visits": visits, "last_day": _last_day}


func load_state(d: Dictionary) -> void:
	visits = int(d.get("visits", 0))
	_last_day = int(d.get("last_day", 0))


func _build() -> void:
	var mat := ShaderMaterial.new()
	mat.shader = load("res://shaders/psx_surface.gdshader")
	mat.set_shader_parameter("albedo", Color(1, 1, 1))
	mat.set_shader_parameter("albedo_tex", _sheet_texture())
	var cone := CylinderMesh.new()   # Laken: oben rund, unten weit, knapp über dem Boden
	cone.top_radius = 0.12
	cone.bottom_radius = 0.34
	cone.height = HEIGHT - 0.3
	cone.radial_segments = 14
	cone.rings = 3
	_sheet = Geo.mesh(self, cone, mat, Vector3(0, 0.1 + (HEIGHT - 0.3) / 2.0, 0))
	Geo.mesh(self, Geo.sphere(0.17, 0.32, 14, 7), mat, Vector3(0, HEIGHT - 0.2, 0))
	for side in [-1.0, 1.0]:
		Geo.mesh(self, Geo.sphere(0.025, 0.035, 6, 3), Mat.psx(Color(0.02, 0.02, 0.02)), Vector3(side * 0.06, HEIGHT - 0.18, -0.155))
		Geo.mesh(self, Geo.box(Vector3(0.08, 0.06, 0.15)), Mat.psx(Color(0.2, 0.12, 0.07)), Vector3(side * 0.08, 0.03, -0.05))   # Schuhe
	Geo.add_box_shape(self, Vector3(0.5, HEIGHT, 0.5), Vector3(0, HEIGHT / 2.0, 0))
	for v in find_children("*", "VisualInstance3D", true, false):
		(v as VisualInstance3D).layers = PeepholeView.HIDDEN_LAYER   # im Türspion nur das echte Kind (7.17)


## Vergilbtes Leinen mit Stockflecken und einem ausgefransten Saum.
static func _sheet_texture() -> ImageTexture:
	var img := Image.create(64, 64, false, Image.FORMAT_RGB8)
	var rng := RandomNumberGenerator.new()
	rng.seed = 1987
	for y in 64:
		for x in 64:
			img.set_pixel(x, y, SHEET * (0.92 + rng.randf() * 0.1))
	for k in 9:
		var c := Vector2(rng.randi_range(0, 63), rng.randi_range(10, 63))
		var r := rng.randf_range(2.0, 6.0)
		for y in 64:
			for x in 64:
				if Vector2(x, y).distance_to(c) < r:
					img.set_pixel(x, y, img.get_pixel(x, y).lerp(STAIN, 0.5))
	return ImageTexture.create_from_image(img)


## Social._trick_at_door: Ein Kind steht vor der offenen Tür von Zimmer 13 – vielleicht nicht allein.
func on_trick_at_door(kid: Guest) -> void:
	var d := Game.director
	if visible or d == null or not d.first_attack_done or visits >= MAX_VISITS:
		return
	var day := Calendar.day_of(d.elapsed)
	if day < FROM_DAY or day == _last_day or not Calendar.phase() in [Calendar.Phase.EVENING, Calendar.Phase.NIGHT] \
			or randf() >= CHANCE:
		return
	appear_behind(kid)


func appear_behind(kid: Guest) -> void:
	var d := Game.director
	var b := kid.global_transform.basis
	var spot := kid.global_position + b.x * BEHIND.x + b.z * BEHIND.z
	if d.player_can_see(spot + Vector3.UP * 0.6):
		spot = kid.global_position + b.x * -BEHIND.x + b.z * BEHIND.z   # die andere Seite
	_kid = kid
	_given = false
	_talked = false
	_seen = false
	visits += 1
	_last_day = Calendar.day_of(d.elapsed)
	global_position = spot
	rotation.y = kid.global_rotation.y   # sieht wie das Kind zur Tür
	visible = true
	if Game.tracing:
		print("[Kind zu viel] steht hinter %s" % kid.display_name)


func get_prompt(player: Player) -> String:
	if not visible:
		return ""
	if not _given and _talked and (player.held_kind() == Item.Kind.SWEETS or player.bag.any(func(i: Item) -> bool: return i.kind == Item.Kind.SWEETS)):
		return "Süßigkeit geben [E]"
	return "Wer bist du? [E]"


func interact(player: Player) -> void:
	if not _talked:
		_talked = true
		Game.say("„%s“" % LINES[visits % LINES.size()], 4.0)
		return
	if not _given and player.consume_kind(Item.Kind.SWEETS):
		_given = true
		Game.say("„%s“" % THANKS, 3.0)


func _process(delta: float) -> void:
	if not visible:
		return
	_time += delta
	_sheet.rotation.z = sin(_time * 0.7) * 0.015
	var d := Game.director
	var seen := d.player_can_see(global_position + Vector3.UP * 0.7) and not Game.player.is_peeping()   # im Spion fehlt es
	_seen = _seen or seen
	var kid_gone := _kid == null or not is_instance_valid(_kid) or _kid.dead \
		or _kid.global_position.distance_to(global_position) > 4.0
	if not seen and (kid_gone or (_seen and (_talked or _given))):
		_vanish()


func _vanish() -> void:
	visible = false
	Game.sound_at("giggle", global_position, 6.0, self, 0.6)
	if Game.notebook and _seen:
		Game.notebook.add_note("extra_child", "Vor meiner Tür stand ein Kind zu viel, im alten Laken. Dann war es weg – und jemand kicherte.", "Zimmer 13")
	if _given:
		var b := Game.social.builder if Game.social else null
		if b and b.pumpkin_head_spot.is_finite():
			var sweet := Item.create(Item.Kind.SWEETS)
			b.world.add_child(sweet)
			sweet.global_position = b.pumpkin_head_spot + Vector3(0.45, 0.05, 0.2)
	if Game.tracing:
		print("[Kind zu viel] ist fort%s" % (" (mit der Süßigkeit)" if _given else ""))


## Debug (--kind-zu-viel): der 28. abends, ein Kind steht vor deiner offenen Tür, das zweite dahinter – du stehst in
## Zimmer 13 und siehst hinaus.
func debug() -> void:
	var d := Game.director
	d.first_attack_done = true
	d.elapsed = maxf(d.elapsed, Calendar.at(28, 19.0))
	_last_day = 0
	visits = 0
	var kid: Guest = null
	for g in Game.social.living_guests():
		if (g as Guest).is_child():
			kid = g
			break
	if kid == null:
		Game.say("Kind zu viel: Es gibt kein Kind im Hotel.", 2.5)
		return
	var b := Game.social.builder
	var info: Dictionary = b.rooms[LevelBuilder.PLAYER_ROOM]
	var door: Door = info["door"]
	door.set_open(true, true, true)
	var front: Vector3 = info["door_front"]
	var inside: Vector3 = info["door_inside"]
	kid.global_position = front + (front - inside).normalized() * 0.4
	kid.look_at(inside + Vector3(0, kid.global_position.y - inside.y, 0), Vector3.UP)
	kid.knock_politely()
	TeleportUI.place_player(inside + (inside - front).normalized() * 0.8, front - inside)
	appear_behind(kid)
