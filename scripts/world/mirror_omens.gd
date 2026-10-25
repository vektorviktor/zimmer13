class_name MirrorOmens
extends Node
## Spiegel (Spielkonzept 4.27).
## **Verhängte Spiegel:** Stirbt ein Gast, verhängt seine Familie die Spiegel im Zimmer mit einem dunklen Tuch – ein
## alter Brauch, damit die Seele nicht darin hängen bleibt. Die Spiegel bleiben dann matt (Mirror.active). Abgeleitet aus
## den Toten, darum nicht gespeichert. Den Spiegel in Zimmer 13 kann man selbst verhängen und wieder freimachen ([E]
## vor dem Waschbecken) – das steht unter „omens“ im Spielstand.
## **Gestalt im Spiegel:** Wer nach dem ersten Angriff in einen freien Spiegel sieht, sieht selten hinter sich eine
## Gestalt stehen – den zuletzt Verschwundenen, still, mit hängenden Armen. Nur im Spiegel: Sie liegt auf der Sichtebene
## der Spielerfigur (PlayerBody.LAYER), die die Spielerkamera nicht zeigt. Dreht man sich um, ist sie fort; sonst nach
## FIGURE_TIME. Häufiger mit Schock und Schwäche, nachts, im Dunkeln. Ein kleiner Schreck (Schock), keine Gefahr.

const CHECK_EVERY := 0.5
const COVER_DELAY := 40.0               ## so lange nach dem Tod hängt das Tuch
const CLOTH := Color(0.08, 0.075, 0.08)
const LOOK_RANGE := 2.6                 ## so nah vor dem Spiegel …
const LOOK_DOT := 0.75                  ## … und so gerade hinein
const FIGURE_CHANCE := 0.012            ## je Prüfung (bei Schwäche 0, ohne Schock)
const FIGURE_PAUSE := 240.0             ## danach so lange keine
const FIGURE_TIME := 1.8
const FIGURE_BEHIND := 0.9              ## so weit hinter dem Spieler
const FIGURE_SHOCK := 0.1
const NOTE := "Im Spiegel stand jemand hinter mir. Als ich mich umdrehte, war da niemand."

var covered_13 := false
var _builder: LevelBuilder
var _covers := {}                       ## Mirror → Tuch (Node3D)
var _died_at := {}                      ## Zimmernummer → Spielzeit des Todes
var _check := 0.0
var _pause := 60.0
var _figure: Node3D
var _figure_t := 0.0
var _figure_mirror: Mirror
var _arms: Array[Node3D] = []
var _body: GuestBody
var _switch: Array[StaticBody3D] = []


func setup(builder: LevelBuilder) -> void:
	_builder = builder
	_arms = [Node3D.new(), Node3D.new()]
	for a in _arms:
		add_child(a)


## Nach dem Aufbau: [E]-Flächen vor den Spiegeln in Zimmer 13.
func _ready() -> void:
	_add_switches.call_deferred()


func _add_switches() -> void:
	for m in _mirrors():
		if _builder.home_room_at(m.global_position - m.global_transform.basis.z * 0.0 + m.global_transform.basis.z * 0.4) \
				!= LevelBuilder.PLAYER_ROOM:
			continue
		var body := StaticBody3D.new()
		body.collision_layer = 4
		body.collision_mask = 0
		body.set_meta("interactable", self)
		body.set_meta("mirror", m)
		m.add_child(body)
		body.position = Vector3(0, 0, 0.03)
		Geo.add_box_shape(body, Vector3(m.size.x, m.size.y, 0.04), Vector3.ZERO)
		_switch.append(body)
	if Game.tracing:
		print("[Spiegel] %d von %d Spiegeln in Zimmer 13" % [_switch.size(), _mirrors().size()])
	_apply_13()


func save_state() -> Dictionary:
	return {"covered_13": covered_13}


func load_state(d: Dictionary) -> void:
	covered_13 = bool(d.get("covered_13", false))
	_apply_13()


func get_prompt(_player: Player) -> String:
	return "Tuch abnehmen [E]" if covered_13 else "Spiegel verhängen [E]"


func interact(_player: Player) -> void:
	covered_13 = not covered_13
	Game.noise("curtain", _player.global_position, _player)
	_apply_13()


func _apply_13() -> void:
	for body in _switch:
		if is_instance_valid(body):
			_set_cover(body.get_meta("mirror") as Mirror, covered_13)


func _mirrors() -> Array[Mirror]:
	var result: Array[Mirror] = []
	for node in get_tree().get_nodes_in_group("sink_mirrors"):
		result.append(node as Mirror)
	return result


## Stirbt ein Gast (Social.on_guest_died): nach COVER_DELAY hängt die Familie die Spiegel im Zimmer zu.
func on_guest_died(guest: Guest) -> void:
	var no := String(guest.home.get("no", ""))
	if no != "" and no != LevelBuilder.PLAYER_ROOM:
		_died_at[no] = Game.director.elapsed if Game.director else 0.0


func _process(delta: float) -> void:
	if _figure:
		_update_figure(delta)
	_check -= delta
	if _check > 0.0:
		return
	_check = CHECK_EVERY
	_pause -= CHECK_EVERY
	_cover_mourning()
	_maybe_figure()


## Zimmer, in denen ein Bewohner tot ist (auch nach dem Laden: aus den toten Gästen), bekommen ihr Tuch.
func _cover_mourning() -> void:
	if Game.social == null:
		return
	var now := Game.director.elapsed if Game.director else 0.0
	for g in Game.social.guests:
		var guest := g as Guest
		var no := String(guest.home.get("no", ""))
		if guest.dead and no != "" and no != LevelBuilder.PLAYER_ROOM and not _died_at.has(no):
			_died_at[no] = now - COVER_DELAY   # schon länger tot (geladen)
	for no in _died_at:
		if now - float(_died_at[no]) < COVER_DELAY:
			continue
		for m in _mirrors():
			if not _covers.has(m) and _builder.home_room_at(m.global_position + m.global_transform.basis.z * 0.4) == no:
				_set_cover(m, true)


## Dunkles Tuch über dem Spiegel: oben an zwei Ecken eingehängt, unten länger, mit Falten.
func _set_cover(m: Mirror, on: bool) -> void:
	if m == null:
		return
	if not on:
		if _covers.has(m):
			(_covers[m] as Node3D).queue_free()
			_covers.erase(m)
		m.active = true
		return
	if _covers.has(m):
		return
	m.active = false
	var cloth := MeshInstance3D.new()
	cloth.mesh = _cloth_mesh(m.size + Vector2(0.14, 0.28))
	cloth.material_override = Mat.psx(CLOTH)
	cloth.position = Vector3(0, -0.07, 0.012)
	m.add_child(cloth)
	_covers[m] = cloth


static func _cloth_mesh(size: Vector2) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var nx := 10
	var ny := 8
	var pts := []
	for j in ny + 1:
		var row := []
		var v := float(j) / ny   # 0 oben, 1 unten
		for i in nx + 1:
			var u := float(i) / nx
			var fold := sin(u * TAU * 2.5 + v * 1.3) * 0.012 * v + v * v * 0.02
			row.append(Vector3((u - 0.5) * size.x * (1.0 - 0.06 * v), size.y / 2.0 - v * size.y - sin(u * PI) * 0.03 * v, fold))
		pts.append(row)
	for j in ny:
		for i in nx:
			var q: Array = [pts[j][i], pts[j][i + 1], pts[j + 1][i + 1], pts[j + 1][i]]
			var n := ((q[1] - q[0]) as Vector3).cross(q[3] - q[0]).normalized()
			for k in [0, 1, 2, 0, 2, 3]:
				st.set_normal(n)
				st.add_vertex(q[k])
	return st.commit()


# --- Gestalt im Spiegel -----------------------------------------------------------------------------

func _maybe_figure() -> void:
	var p := Game.player
	var d := Game.director
	if _figure or p == null or d == null or p.dead or not d.first_attack_done or _pause > 0.0 or not Settings.reflections:
		return
	var m := _mirror_in_view(p)
	if m == null:
		return
	var dark := clampf(1.0 - d.light_at(p.camera.global_position) / 2.0, 0.0, 1.0)
	var night := 1.5 if Calendar.phase() == Calendar.Phase.NIGHT else 1.0
	var chance := FIGURE_CHANCE * (0.5 + p.shock * 2.0 + p.weakness()) * night * (0.5 + dark)
	if randf() < chance:
		show_figure(m)


## Der freie Spiegel, in den der Spieler gerade nah und gerade hineinsieht.
func _mirror_in_view(p: Player) -> Mirror:
	var cam := p.camera
	var fwd := -cam.global_transform.basis.z
	for m in _mirrors():
		if not m.active or _covers.has(m) or not m.is_visible_in_tree():
			continue
		var n := m.global_transform.basis.z
		var to := m.global_position - cam.global_position
		if to.length() > LOOK_RANGE or to.dot(n) > 0.0 or absf(to.y) > 1.2:
			continue
		if fwd.dot(to.normalized()) > LOOK_DOT:
			return m
	return null


## Hinter den Spieler (vom Spiegel weg) eine Gestalt nur für die Spiegelkameras stellen.
func show_figure(m: Mirror) -> void:
	var p := Game.player
	var who := _last_dead()
	_figure = Node3D.new()
	add_child(_figure)
	_body = GuestBody.new()
	if who:
		_body.setup(GuestBody.pick(who.profile, who.id), who.profile)
	else:
		_body.setup(GuestBody.BODIES.keys()[0], {"coat": Color(0.12, 0.12, 0.13), "pants": Color(0.1, 0.1, 0.1), "hair": Color(0.15, 0.13, 0.12)})
	_figure.add_child(_body)
	for v in _figure.find_children("*", "VisualInstance3D", true, false):
		(v as VisualInstance3D).layers = PlayerBody.LAYER
		if v is GeometryInstance3D:
			(v as GeometryInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var away := p.global_position - m.global_position
	away.y = 0.0
	away = away.normalized() if away.length() > 0.01 else m.global_transform.basis.z
	_figure.global_position = p.global_position + away * FIGURE_BEHIND
	_figure.rotation.y = atan2(away.x, away.z)   # Figuren blicken nach −Z: zum Spiegel (über die Schulter des Spielers)
	_figure_t = FIGURE_TIME
	_figure_mirror = m
	_pause = FIGURE_PAUSE
	_body.animate(0.0, 0.0, false, _arms, false, false)
	if Game.tracing:
		print("[Spiegel] Gestalt hinter dir: %s" % (who.display_name if who else "niemand"))


func _update_figure(delta: float) -> void:
	_body.animate(delta, 0.0, false, _arms, false, false)
	_figure_t -= delta
	var p := Game.player
	var gone := _figure_t <= 0.0 or p == null
	if not gone:   # umgedreht (der Spiegel nicht mehr im Blick) – fort
		gone = _mirror_in_view(p) != _figure_mirror
		if not gone and _figure_t < FIGURE_TIME - 0.4 and not _figure.has_meta("seen"):
			_figure.set_meta("seen", true)
			p.shock = minf(1.0, p.shock + FIGURE_SHOCK)
			if Game.notebook:
				Game.notebook.add_note("mirror_figure", NOTE, "Spiegel")
	if gone:
		_figure.queue_free()
		_figure = null
		_body = null


func _last_dead() -> Guest:
	if Game.social == null:
		return null
	var best: Guest = null
	for g in Game.social.guests:
		var guest := g as Guest
		if guest.dead and not guest.is_child():
			best = guest
	return best


## Debug (--spiegel[=tuch]): du stehst vor dem Spiegel im Bad von Zimmer 13 – nach 2 s steht die Gestalt hinter dir
## (der erste Angriff gilt als geschehen) · tuch: der Spiegel ist verhängt.
func debug(what: String) -> void:
	Game.director.first_attack_done = true
	var mirror: Mirror = null
	for body in _switch:
		mirror = body.get_meta("mirror") as Mirror
	if mirror == null:
		Game.say("Spiegel: In Zimmer 13 hängt keiner.", 2.5)
		return
	var n := mirror.global_transform.basis.z
	var stand := mirror.global_position + n * 0.85
	stand.y = mirror.global_position.y - 1.55
	TeleportUI.place_player(stand, -n)
	if what == "tuch":
		covered_13 = true
		_apply_13()
		return
	_pause = 999.0
	get_tree().create_timer(2.0, false).timeout.connect(func() -> void:
		if _figure == null:
			show_figure(mirror))
