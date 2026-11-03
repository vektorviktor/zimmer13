class_name BalconyRailing
extends Node3D
## Balkongeländer im Obergeschoss (Spielkonzept 7.7, entschieden 2026-11-03, ZIM-36): Ursprung Mitte, lokal X entlang
## des Geländers, ±Z die beiden Seiten. Über ein Trenngeländer steigt man langsam und laut zum direkt angrenzenden
## Nachbarbalkon, über die Außenkante klettert man und springt in den Garten (Player.climb_railing) – danach humpelt man.
## Was auf jeder Seite liegt, rechnet LevelBuilder._railing_sides beim Bau aus dem Plan aus.

## So weit auseinander liegen die Stichproben entlang des Geländers (m)
const STEP := 0.5
## So weit neben dem Geländerstrich im Plan wird nachgesehen, was dort liegt (m)
const PROBE := 0.3
## Seiten: nichts, wohin man steigen kann (Wand, Zimmer) · Balkon oder Terrasse · nichts auf diesem Stockwerk (Garten darunter)
const NONE := 0
const DECK := 1
const AIR := 2
## Hier steht man nach dem Übersteigen: so weit hinter der Mitte des Geländers (m)
const OVER := 0.45
## Nicht näher als so an die Enden – dort stehen Pfosten und Wände (m)
const EDGE := 0.35
## Oberkante des Handlaufs über dem Boden (LevelBuilder._railing)
const TOP := 1.06
## Springen nur, wenn darunter so viel Luft ist – sonst ist es kein Sprung in den Garten (m)
const MIN_DROP := 2.5
## … und höchstens so tief
const MAX_DROP := 6.0

var length := 1.0
## je Stichprobe zwei Bytes: Seite +Z, Seite −Z (NONE, DECK, AIR)
var sides := PackedByteArray()


func _init(p_length: float = 1.0, p_sides := PackedByteArray()) -> void:
	length = p_length
	sides = p_sides
	add_to_group("balcony_railings")


func get_prompt(player: Player) -> String:
	var c := crossing(player)
	if c.is_empty():
		return ""
	if c.has("blocked"):
		return String(c["blocked"])
	if c["drop"]:
		return "Übers Geländer klettern und in den Garten springen [E]"
	return "Übers Geländer zum Nachbarbalkon steigen [E]"


func interact(player: Player) -> void:
	var c := crossing(player)
	if not c.is_empty() and not c.has("blocked"):
		player.climb_railing(c)


## Wohin es von hier aus geht: {} = nirgends (man steht nicht auf einem Balkon oder drüben ist eine Wand); mit
## "blocked" ein Hinweis, warum nicht; sonst {"over" (über dem Handlauf), "to" (Füße drüben), "drop"}.
func crossing(player: Player) -> Dictionary:
	var n := sides.size() / 2
	if n == 0 or player.climbing():
		return {}
	var local := to_local(player.global_position)
	var i := clampi(floori((local.x / length + 0.5) * n), 0, n - 1)
	var own := 0 if local.z >= 0.0 else 1
	if sides[2 * i + own] != DECK:
		return {}
	var other := sides[2 * i + 1 - own]
	if other == NONE:
		return {}
	if player.hands_blocked() or player.carried_cat:
		return {"blocked": "Mit vollen Händen kommst du nicht übers Geländer"}
	var x := clampf(local.x, -length / 2.0 + EDGE, length / 2.0 - EDGE)
	var out := -1.0 if own == 0 else 1.0
	var to := to_global(Vector3(x, 0.0, out * OVER))
	var c := {"over": to_global(Vector3(x, TOP, 0.0)), "to": to, "drop": other == AIR}
	if other == DECK:
		if not player.can_stand_at(to):
			return {"blocked": "Drüben ist kein Platz"}
		return c
	# Außenkante: unten muss Boden im Freien sein, frei und tief genug
	var space := get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(to + Vector3.UP * 0.5, to + Vector3.DOWN * MAX_DROP, player.collision_mask)
	query.exclude = [player.get_rid()]
	var hit := space.intersect_ray(query)
	if hit.is_empty() or to.y - float(hit["position"].y) < MIN_DROP or not RainVeil.is_outdoor(hit["position"]):
		return {"blocked": "Hier geht es nicht hinunter"}
	if not player.can_stand_at(to + Vector3.UP * 0.1):
		return {"blocked": "Hier ist kein Platz zum Hinüberklettern"}
	c["ground"] = hit["position"]
	return c


# --- Debug (--balkon) ---------------------------------------------------------------

## --balkon[=nachbar|humpeln]: du stehst auf einem Balkon vor der Außenkante (nachbar: vor einem Trenngeländer) und
## steigst nach 1 s hinüber · humpeln: wie ohne Wert, nach der Landung zählt der Spieler 2 Spielstunden Zeitsprung
## (Player.skip_time) – im Protokoll stehen Zählung, Ziel, Landung und wie lange man noch humpelt.
static func debug(mode: String) -> void:
	var player := Game.player
	var railings := player.get_tree().get_nodes_in_group("balcony_railings")
	var counts := [0, 0]   # Geländer mit Nachbarbalkon, mit Sprung in den Garten
	for node in railings:
		var r := node as BalconyRailing
		for k in [DECK, AIR]:
			if r._sample_toward(k) >= 0:
				counts[k - 1] += 1
	print("[Balkon] %d Geländer: %d zum Nachbarbalkon, %d zum Garten" % [railings.size(), counts[0], counts[1]])
	var want := DECK if mode == "nachbar" else AIR
	for node in railings:
		var r := node as BalconyRailing
		var i := r._sample_toward(want)
		if i < 0:
			continue
		var own := 0 if r.sides[2 * i] == DECK and r.sides[2 * i + 1] == want else 1
		var x := -r.length / 2.0 + r.length * (i + 0.5) / (r.sides.size() / 2.0)
		var at := r.to_global(Vector3(x, 0.05, (1.0 if own == 0 else -1.0) * 0.7))
		player.global_position = at
		var c := r.crossing(player)
		if c.is_empty() or c.has("blocked"):
			continue
		var look: Vector3 = c["over"] - at
		player.rotation.y = atan2(-look.x, -look.z)
		print("[Balkon] stehe bei %s, steige %s nach %s" % [at, "hinunter" if c["drop"] else "hinüber", c["to"]])
		player.get_tree().create_timer(1.0).timeout.connect(func() -> void:
			r.interact(player)
			player.get_tree().create_timer(6.0).timeout.connect(func() -> void: _debug_report(mode)))
		return
	Game.say("Balkon: kein passendes Geländer gefunden.", 3.0)
	print("[Balkon] kein passendes Geländer gefunden")


## Erste Stichprobe, an der eine Seite Balkon ist und die andere kind – −1 = keine.
func _sample_toward(kind: int) -> int:
	for i in sides.size() / 2:
		var a := sides[2 * i]
		var b := sides[2 * i + 1]
		if (a == DECK and b == kind) or (b == DECK and a == kind):
			return i
	return -1


static func _debug_report(mode: String) -> void:
	var player := Game.player
	print("[Balkon] jetzt bei %s, humpelt noch %.0f s, klettert: %s" % [player.global_position, player.limp, player.climbing()])
	if mode == "humpeln":
		player.skip_time(2.0 * Calendar.HOUR)
		print("[Balkon] nach 2 Spielstunden Zeitsprung: humpelt noch %.0f s" % player.limp)
