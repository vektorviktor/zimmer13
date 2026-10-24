class_name RainVeil
extends Node3D
## Im Regen verwaschen (Spielkonzept 4.13, Nachtrag 2026-10-23/24): Blutlachen, große Wachsflecken und Kürbismatsch unter
## freiem Himmel (LevelBuilder.is_outdoor) beginnen mit dem ersten Regen langsam zu verlaufen – `wash` steigt in WASH_TIME
## Regen voller Stärke von 0 auf 1. Der Fleck läuft dabei auseinander (bis × 1 + WASH_WIDEN), wird dünnflüssig, leuchtender
## und glänzt nass (psx_decal, Instanz-Wert „wash“). Zugleich wächst sein Schleier: eine sehr große Fläche mit dem Wind
## (Weather.FALL), auf Treppen und Gefälle bergab, an Wänden entlang, nie ins Haus – eine blasse breite Fläche (Fächer aus
## VEIL_ARMS Armen) und darüber VEIL_STREAKS schmale, kräftige Schlieren in Fließrichtung. Jedes Stück erscheint, wenn
## der Regen weit genug ist (seine Schwelle entlang der Schliere), und wächst dann langsam. Bei 1 ist der Fleck weg,
## der Schleier ganz da – erst dann verblasst er (im Regen schneller) und verschwindet.
## Fleck und Schleier rechnen beide nach derselben Regenformel (wash_step am Ort des Flecks) und bleiben so ohne
## Verbindung im Gleichschritt, auch nach dem Laden. Die Flecken: Traces._wash_marks, Item._wash_mush; gespeichert in
## Traces (Art „veil“).

const WASH_TIME := 90.0           ## so lange Regen voller Stärke (Spielzeit, s), bis ein Fleck ganz verlaufen ist
const WASH_TICK := 0.2            ## so oft wird gerechnet (s) – oft genug, dass das Wachsen flüssig aussieht
const WASH_WIDEN := 0.8           ## so viel breiter läuft ein Fleck beim Verwaschen auseinander (ganz verwaschen: × 1,8)
const RAIN_MIN := 0.05            ## darunter regnet es nicht (Weather.intensity)
const VEIL_LENGTH := Vector2(15.0, 25.0)
## Breite Fläche: so viele Arme (von, bis), so weit gedreht die äußersten (rad), Schritt (m), Breite am Anfang (aus der
## Größe des Flecks, begrenzt), so viel breiter je Stück, höchstens so breit (m), Deckkraft innen → außen
const VEIL_ARMS := Vector2i(3, 5)
const VEIL_FAN := 0.6
const VEIL_STEP := 1.6
const VEIL_WIDTH := Vector2(0.8, 2.0)
const VEIL_WIDEN := 1.1
const VEIL_MAX_WIDTH := 5.0
const SHEET_STRENGTH := Vector2(0.55, 0.15)
## Schlieren: so viele (von, bis), über diesen Fächer (rad), Schritt (m), Stücklänge × Schritt, Breite (m), Deckkraft
## innen → außen
const VEIL_STREAKS := Vector2i(10, 16)
const STREAK_FAN := 0.8
const STREAK_STEP := 2.0
const STREAK_LENGTH := 1.8
const STREAK_WIDTH := Vector2(0.12, 0.45)
const STREAK_STRENGTH := Vector2(1.0, 0.35)
## Ein Stück erscheint bei seiner Schwelle (0 am Fleck … REACH am Ende der Schliere, Anteil von wash) und wächst über
## so viel wash auf seine Größe
const REACH := 0.85
const GROW_SPAN := 0.15
const VEIL_ALPHA := 0.9           ## Deckkraft des Schleiers – kräftig, der Regen soll dramatisch aussehen
## Je Art: Größe von Schleier und Auseinanderlaufen (× aller Längen und Breiten, auch WASH_WIDEN; Anzahl der Arme und
## Schlieren × 1,5 davon, höchstens 1) und Deckkraft (× VEIL_ALPHA) – Blut 45 %, Kürbismatsch nur 20 % (2026-10-24)
const LOOK := {"blood": {"size": 0.45, "alpha": 0.7}, "mush": {"size": 0.2, "alpha": 0.6}, "wax": {"size": 1.0, "alpha": 1.0}}
const VEIL_FADE_RAIN := 180.0     ## ganz ausgebreitet: so lange verblasst er im Regen (s) …
const VEIL_FADE_DRY := 420.0      ## … und im Trockenen
## Fleckgröße für die Breite des Schleiers (m)
const SIZE := {"blood": 1.4, "wax": 0.5}
## Der Schleier ist immer die rundliche, helle Wachsgrafik (TraceMark.WAX_TEXTURE, Mittel VEIL_TEX_COLOR), getönt in der
## Farbe des Flecks – lang gezogen ergibt sie Schlieren; die stacheligen Spritzer des Kürbismatschs nicht
const VEIL_TEX_COLOR := Color(0.9014, 0.8808, 0.8217)
const VEIL_COLOR := {"blood": Color(0.62, 0.03, 0.03), "wax": Color(0.9, 0.88, 0.82)}   ## Blut satt rot, nicht rosa
## Relief des Schleiers (Normal Map) – flach, sonst glitzert er im Regen
const VEIL_NORMAL := 0.25

## --verwaschen: so viel schneller verwaschen Flecken (Debug)
static var debug_speed := 1.0

var look := "blood"     ## "blood", "wax" oder "mush"
var variety := ""       ## Kürbismatsch: Sorte (Farbe)
var width := 1.0
## Wie weit er sich ausgebreitet hat (0 … 1, wie wash seines Flecks); bei 1 verblasst er über `life` (1 … 0)
var progress := 0.0
var life := 1.0
var veil_seed := 0
var _mat: ShaderMaterial
var _timer := 0.0
var _pieces: Array[Dictionary] = []   ## {node, at (Schwelle), full (Größe)}


## Wie viel ein Fleck bei `pos` in `delta` s verwäscht – 0, wenn es nicht regnet oder er nicht draußen liegt.
static func wash_step(pos: Vector3, delta: float) -> float:
	if Game.weather == null or Game.weather.intensity < RAIN_MIN or not is_outdoor(pos):
		return 0.0
	return delta * Game.weather.intensity / WASH_TIME * debug_speed


static func is_outdoor(pos: Vector3) -> bool:
	return Game.social != null and Game.social.builder != null and Game.social.builder.is_outdoor(pos + Vector3.UP * 0.1)


## Zeigt, wie verwaschen ein Fleck ist: Instanz-Wert „wash“ an jedem Stück unter `node`, und `node` selbst läuft
## waagrecht auseinander (× 1 + WASH_WIDEN × wash um seinen Ursprung – die Stücke rücken mit nach außen). Liegt seine
## lokale Z nach oben (Gästespuren wie der große Wachsfleck, gekippt), wird in X und Y gestreckt.
static func show_wash(node: Node3D, wash: float, look: String) -> void:
	var f := 1.0 + WASH_WIDEN * size_of(look) * wash
	node.scale = Vector3(f, f, 1.0) if absf(node.global_basis.z.normalized().y) > 0.7 else Vector3(f, 1.0, f)
	for child in node.get_children():
		if child is GeometryInstance3D:
			(child as GeometryInstance3D).set_instance_shader_parameter("wash", wash)


## Größe je Art (LOOK)
static func size_of(look: String) -> float:
	return float((LOOK.get(look, {}) as Dictionary).get("size", 1.0))


## Der erste Regen auf einem Fleck: sein Schleier entsteht (noch unsichtbar) und wächst von nun an mit dem Regen (look:
## „blood“, „wax“, „mush“; size: Größe des Flecks in m – davon hängt die Breite ab).
static func spawn(at: Vector3, p_look: String, p_variety: String, size: float) -> RainVeil:
	if Game.traces == null:
		return null
	var veil := RainVeil.new()
	veil.look = p_look
	veil.variety = p_variety
	veil.width = clampf(size * 0.8, VEIL_WIDTH.x, VEIL_WIDTH.y)
	veil.veil_seed = randi()
	Game.traces.add_child(veil)
	veil.global_position = at
	if Game.tracing:
		print("[Regen] %s beginnt zu verlaufen – Schleier bei %s" % [p_look, at])
	return veil


## Aus dem Spielstand (Traces.load_state): gleiche Schlieren aus dem gespeicherten Seed, so weit ausgebreitet wie gespeichert.
static func from_save(parent: Node, entry: Dictionary) -> RainVeil:
	var veil := RainVeil.new()
	veil.look = String(entry.get("look", "blood"))
	veil.variety = String(entry.get("variety", ""))
	veil.width = float(entry.get("width", 1.0))
	veil.veil_seed = int(entry.get("seed", 0))
	veil.progress = float(entry.get("progress", 1.0))
	veil.life = float(entry.get("life", 1.0))
	parent.add_child(veil)
	var at: Array = entry.get("at", [0, 0, 0])
	veil.global_position = Vector3(float(at[0]), float(at[1]), float(at[2]))
	return veil


func to_save() -> Dictionary:
	var p := global_position
	return {"kind": "veil", "look": look, "variety": variety, "width": width, "seed": veil_seed, "progress": progress,
		"life": life, "at": [p.x, p.y, p.z]}


func _ready() -> void:
	add_to_group("rain_veils")
	add_to_group("time_skip")   # wächst und verblasst auch im Schlaf (SleepSkip)
	_mat = Mat.decal(TraceMark.WAX_TEXTURE)   # eigenes Material: verblasst für sich
	TraceMark.splat_look(_mat, TraceMark.WAX_TEXTURE)
	_mat.set_shader_parameter("normal_strength", VEIL_NORMAL)
	var color: Color = VEIL_COLOR.get(look, Item.mush_color(PumpkinKinds.data(variety)["color"]) if look == "mush" else Color.WHITE)
	_mat.set_shader_parameter("albedo", Color(color.r / VEIL_TEX_COLOR.r, color.g / VEIL_TEX_COLOR.g, color.b / VEIL_TEX_COLOR.b))
	_mat.set_shader_parameter("fade", _alpha() * life)
	_build.call_deferred()   # die Lage wird nach add_child gesetzt


## Der ganze Schleier wird gleich gebaut, die Stücke bleiben bis zu ihrer Schwelle winzig (_show_progress). Grundrichtung
## mit dem Wind (±0,4 rad) bzw. bergab. Erst die breite Fläche: VEIL_ARMS Arme, der erste in der Mitte, die übrigen
## abwechselnd links und rechts bis VEIL_FAN, nach außen breiter (× VEIL_WIDEN bis VEIL_MAX_WIDTH). Darüber
## VEIL_STREAKS Schlieren gleichmäßig über STREAK_FAN, schmal und lang gezogen. Alles verschmilzt (Tiefe nach Dicke).
func _build() -> void:
	if not is_inside_tree():
		return
	var space := get_world_3d().direct_space_state
	var rng := RandomNumberGenerator.new()
	rng.seed = veil_seed
	var start := global_position
	var slope := TraceMark.downhill_at(space, start)
	var main := slope if slope != Vector3.ZERO \
		else Vector3(Weather.FALL.x, 0.0, Weather.FALL.z).normalized().rotated(Vector3.UP, rng.randf_range(-0.4, 0.4))
	var k := size_of(look)   # Blut und Matsch kleiner (LOOK)
	var count_k := minf(1.0, k * 1.5)
	var length := rng.randf_range(VEIL_LENGTH.x, VEIL_LENGTH.y) * k
	var w0 := width * k
	var arms := maxi(1, roundi(rng.randi_range(VEIL_ARMS.x, VEIL_ARMS.y) * count_k))
	for a in arms:
		var side := 1.0 if a % 2 == 1 else -1.0
		var reach := ceilf(a / 2.0) / maxf(1.0, ceilf((arms - 1) / 2.0))
		var dir := main.rotated(Vector3.UP, side * reach * VEIL_FAN + rng.randf_range(-0.12, 0.12))
		_arm(space, rng, start, dir, length * (1.0 if a == 0 else 0.75), {"step": maxf(0.4, VEIL_STEP * k), "long": 1.8,
			"width": w0, "widen": VEIL_WIDEN, "max": VEIL_MAX_WIDTH * k, "strength": SHEET_STRENGTH, "lift": 0.003})
	var streaks := maxi(2, roundi(rng.randi_range(VEIL_STREAKS.x, VEIL_STREAKS.y) * count_k))
	for s in streaks:
		var dir := main.rotated(Vector3.UP, (float(s) / maxf(1.0, streaks - 1) - 0.5) * STREAK_FAN + rng.randf_range(-0.08, 0.08))
		var w := rng.randf_range(STREAK_WIDTH.x, STREAK_WIDTH.y) * maxf(k, 0.35)   # schmaler, aber nicht zu Fäden
		_arm(space, rng, start + dir.cross(Vector3.UP) * rng.randf_range(-0.4, 0.4) * w0, dir,
			length * rng.randf_range(0.6, 1.0), {"step": maxf(0.5, STREAK_STEP * k), "long": STREAK_LENGTH, "width": w, "widen": 1.03,
			"max": w * 2.0, "strength": STREAK_STRENGTH, "lift": 0.0034})
	_show_progress()


## Ein Arm bzw. eine Schliere: vom Fleck aus Stück für Stück „step“ weiter, leicht schlängelnd, auf Treppen und Gefälle
## bergab, an Wänden entlang (frontal: Ende), nie ins Haus (is_outdoor); jedes Stück fällt auf die Fläche darunter
## (TraceMark.place_splat, fester Winkel in Laufrichtung), „long“ × so lang wie der Schritt, nach außen breiter und blasser.
## Seine Schwelle: wie weit es den Arm entlang liegt (× REACH).
func _arm(space: PhysicsDirectSpaceState3D, rng: RandomNumberGenerator, start: Vector3, base: Vector3, length: float,
		cfg: Dictionary) -> void:
	var step := float(cfg["step"])
	var p := start
	var dir := base
	var w := float(cfg["width"])
	var walked := 0.0
	var k := 0
	while walked < length and k < 30:
		dir = dir.rotated(Vector3.UP, rng.randf_range(-0.2, 0.2)).lerp(base, 0.4).normalized()
		var knee := p + Vector3.UP * 0.3
		var wall := space.intersect_ray(PhysicsRayQueryParameters3D.create(knee, knee + dir * step, 1))
		if not wall.is_empty() and not (wall["collider"] as Object).has_meta("stair_ramp"):
			var n: Vector3 = wall["normal"]
			n.y = 0.0
			dir = dir.slide(n.normalized()) if n.length() > 0.1 else Vector3.ZERO
			if dir.length() < 0.2:
				break   # frontal vor der Wand
			dir = dir.normalized()
			base = dir   # an der Wand entlang weiter
		var next := p + dir * step
		if not is_outdoor(next):
			break
		var slope := TraceMark.downhill_at(space, next)
		if slope != Vector3.ZERO:
			dir = slope
			base = slope
		var spot := TraceMark.place_splat(space, p, dir * step * 0.5, Vector2(w, maxf(step * float(cfg["long"]), w * 0.8)),
			slope, rng, atan2(dir.x, dir.z))
		if not spot.is_empty():
			var t := walked / length
			var strength: Vector2 = cfg["strength"]
			for piece in TraceMark.lay_decal(self, spot, _mat, rng, float(cfg["lift"]) + k * 0.00002):
				piece.set_instance_shader_parameter("wash", 1.0)
				piece.set_instance_shader_parameter("strength", lerpf(strength.x, strength.y, t))
				_pieces.append({"node": piece, "at": t * REACH, "full": piece.scale})
			next.y = (spot["at"] as Vector3).y
		p = next
		w = minf(w * float(cfg["widen"]), float(cfg["max"]))
		walked += step
		k += 1


## Jedes Stück nach `progress`: bis zu seiner Schwelle winzig, dann über GROW_SPAN auf volle Größe (weich auslaufend).
func _show_progress() -> void:
	for p in _pieces:
		var node: Node3D = p["node"]
		var k := clampf((progress - float(p["at"])) / GROW_SPAN, 0.0, 1.0)
		k = 1.0 - (1.0 - k) * (1.0 - k)
		var full: Vector3 = p["full"]
		node.visible = k > 0.0
		node.scale = Vector3(full.x * maxf(k, 0.02), full.y, full.z * maxf(k, 0.02))


## Zeitsprung im Schlaf (SleepSkip, Spielkonzept 3.6): wächst bzw. verblasst weiter (das nächste Bild rechnet es nach).
func skip_time(dt: float) -> void:
	_timer += dt


func _process(delta: float) -> void:
	_timer += delta
	if _timer < WASH_TICK:
		return
	var dt := _timer
	_timer = 0.0
	if progress < 1.0:
		# breitet sich aus, solange es auf den Fleck regnet (dieselbe Formel wie beim Fleck)
		var step := wash_step(global_position, dt)
		if step > 0.0:
			progress = minf(1.0, progress + step)
			_show_progress()
		return
	var raining := Game.weather != null and Game.weather.intensity >= RAIN_MIN
	life -= dt / (VEIL_FADE_RAIN if raining else VEIL_FADE_DRY)
	if life <= 0.0:
		if Game.tracing:
			print("[Regen] Schleier verblasst und weg")
		queue_free()
		return
	_mat.set_shader_parameter("fade", _alpha() * life)


func _alpha() -> float:
	return VEIL_ALPHA * float((LOOK.get(look, {}) as Dictionary).get("alpha", 1.0))
