class_name Tidying
extends Node
## Flecken und Putzen (Spielkonzept 6.13, 5.8, 2026-10-22): Kürbismatsch, große Wachsflecken, Ruß und Kaffeeflecken
## (3.11) bleiben nicht unbemerkt. Wer so etwas vor der eigenen Tür sieht, beschwert sich (einmal je Fleck). Ordentliche Gäste (TIDY_SHARE,
## fest nach Gast-ID, nur Erwachsene) putzen: Wachs, Ruß und Kaffee wischen sie weg (TraceMark.wipe); Kürbismatsch sammeln sie
## auf – vom großen Spritzer eine Hand voll (Item.split_handful) – und bringen ihn in die Küche. Ist der Herd frei,
## kochen sie daraus Suppe (Stove.claim_cook, dann wie ein kochender Gast), sonst legen sie ihn dort ab.
## Läuft über den Besuchsablauf (start_visit, Social.on_visit_arrived fragt on_arrived). Kind von Social:
## Game.social.tidying. Nicht gespeichert.

const SCAN := 3.0
## Beschweren: Fleck so nah an der eigenen Tür, der Bewohner so nah und mit Blick darauf
const COMPLAIN_RANGE := 4.0
const SEE_RANGE := 8.0
## Putzen: so viele Gäste putzen gern, so weit (gleiches Stockwerk) sehen sie einen Fleck, so viel Pause zwischen zwei Gängen
const TIDY_SHARE := 0.4
const TIDY_RANGE := 14.0
const TIDY_GAP := 15.0
const MESS_TRACES := ["wax_splash", "soot", "coffee", "tea"]
const COMPLAIN_MUSH := ["Wer schmeißt hier mit Kürbissen?!", "Igitt – Kürbismatsch vor meiner Tür.", "Das war bestimmt wieder eins von den Kindern …"]
const COMPLAIN_COFFEE := ["Wer hat hier seinen Kaffee verschüttet?", "Kaffee vor meiner Tür – und keiner wischt es weg.", "Scherben und Kaffee … na toll."]
const COMPLAIN_TEA := ["Wer hat hier seinen Tee verschüttet?", "Tee und Scherben vor meiner Tür … wer war das?"]
const COMPLAIN_WAX := ["Überall Wachs vor meiner Tür … wer war das?", "Was ist das denn für eine Sauerei?", "Hat hier jemand gezündelt?!"]
const CLEAN_LINES := ["Das mach ich mal weg.", "So kann das nicht bleiben.", "Na, dann putz ich das eben."]
const KITCHEN_LINES := ["Daraus wird noch eine Suppe.", "Ab in die Küche damit."]

## Gast-ID → {guest, target (Item oder TraceMark), phase ("go" | "drop")}
var _jobs := {}
var _scan := SCAN
var _gap := 5.0


## Putzt dieser Gast gern? Fest nach seiner ID, Kinder nie.
static func is_tidy(g: Guest) -> bool:
	return not g.is_child() and absi(hash(g.id + "|tidy")) % 100 < int(TIDY_SHARE * 100.0)


func reset() -> void:
	_jobs.clear()


func _process(delta: float) -> void:
	if Game.game_over or Game.social == null:
		return
	for id in _jobs.keys():   # abgebrochen (Schreck, Feier, Gespräch …): Geholtes fällt zu Boden
		var job: Dictionary = _jobs[id]
		var g: Guest = job["guest"]
		if is_instance_valid(g) and not g.dead and g.state == Guest.State.VISIT:
			continue
		_jobs.erase(id)
		var target = job.get("target")
		if is_instance_valid(target):
			target.remove_meta("cleaning")
		if is_instance_valid(g) and not g.dead and g.held and g.held.kind == Item.Kind.PUMPKIN_MUSH and g.state != Guest.State.EAT:
			g._drop_held()
	_gap -= delta
	_scan -= delta
	if _scan > 0.0:
		return
	_scan = SCAN
	var messes := _messes()
	for mess in messes:
		_complaints(mess)
	if _gap <= 0.0 and not Game.social.sleep_active:
		for mess in messes:
			if _send_cleaner(mess):
				_gap = TIDY_GAP
				break


## Kürbismatsch am Boden, große Wachsflecken, Ruß und Kaffeeflecken.
func _messes() -> Array[Node3D]:
	var result: Array[Node3D] = []
	for node in get_tree().get_nodes_in_group("items"):
		var item := node as Item
		if item.kind == Item.Kind.PUMPKIN_MUSH and not item.is_held:
			result.append(item)
	for node in get_tree().get_nodes_in_group("trace_marks"):
		var mark := node as TraceMark
		if mark.kind in MESS_TRACES:
			result.append(mark)
	return result


## Bewohner, die den Fleck vor der eigenen Tür sehen, beschweren sich – einmal je Fleck.
func _complaints(mess: Node3D) -> void:
	if mess.has_meta("complained"):
		return
	for guest in Game.social.living_guests():
		var g: Guest = guest
		if g.is_child() or g.state in [Guest.State.SLEEP, Guest.State.HIDING, Guest.State.TALKING]:
			continue
		var front: Vector3 = g.home["door_front"]
		if mess.global_position.distance_to(front) > COMPLAIN_RANGE or g.global_position.distance_to(mess.global_position) > SEE_RANGE \
				or not Senses.clear_line(g.get_world_3d(), g.global_position + Vector3.UP * g.eye_height(), mess.global_position + Vector3.UP * 0.1, g):
			continue
		mess.set_meta("complained", true)
		var mark_kind := (mess as TraceMark).kind if mess is TraceMark else ""
		var lines: Array = COMPLAIN_MUSH if mess is Item else {"coffee": COMPLAIN_COFFEE, "tea": COMPLAIN_TEA}.get(mark_kind, COMPLAIN_WAX)
		g.say(lines.pick_random())
		if Game.tracing:
			print("[Flecken] %s beschwert sich über %s vor der Tür" % [g.display_name, "Kürbismatsch" if mess is Item else "Wachs/Ruß/Kaffee"])
		return


## Ein ordentlicher, freier Gast in der Nähe, der den Fleck sieht, geht hin. false = keiner.
func _send_cleaner(mess: Node3D) -> bool:
	if mess.has_meta("cleaning"):
		return false
	var best: Guest = null
	var best_d := TIDY_RANGE
	for guest in Game.social.living_guests():
		var g: Guest = guest
		if not is_tidy(g) or g.held != null or g.hiding != null or not g.state in [Guest.State.IDLE, Guest.State.WALK] \
				or g.is_following() or g.fear >= 50.0 or _jobs.has(g.id) or absf(g.global_position.y - mess.global_position.y) > 1.5:
			continue
		var d := g.global_position.distance_to(mess.global_position)
		if d < best_d and Senses.clear_line(g.get_world_3d(), g.global_position + Vector3.UP * g.eye_height(), mess.global_position + Vector3.UP * 0.1, g):
			best = g
			best_d = d
	if best == null:
		return false
	mess.set_meta("cleaning", true)
	_jobs[best.id] = {"guest": best, "target": mess, "phase": "go"}
	best.say(CLEAN_LINES.pick_random())
	best.start_visit(mess.global_position)
	if Game.tracing:
		print("[Flecken] %s geht putzen (%.0f m)" % [best.display_name, best_d])
	return true


## Angekommen (Social.on_visit_arrived): true = gehört zum Putzen.
func on_arrived(g: Guest) -> bool:
	if not _jobs.has(g.id):
		return false
	var job: Dictionary = _jobs[g.id]
	var target = job["target"]
	if String(job["phase"]) == "drop":   # in der Küche abgelegt (der Herd war belegt)
		_jobs.erase(g.id)
		g._drop_held()
		g._set_idle(randf_range(3.0, 6.0))
		return true
	_jobs.erase(g.id)
	if not is_instance_valid(target) or target.is_queued_for_deletion():
		g._set_idle(randf_range(2.0, 4.0))
		return true
	if target is TraceMark:
		(target as TraceMark).wipe(g)
		g._set_idle(randf_range(3.0, 6.0))
		if Game.tracing:
			print("[Flecken] %s wischt %s weg" % [g.display_name, (target as TraceMark).kind])
		return true
	var mush := target as Item
	var handful := mush
	if mush.portions > 1:
		handful = mush.split_handful()
		mush.shrink_by_handful()
		mush.remove_meta("cleaning")
	g._take_into_hand(handful)
	g.say(KITCHEN_LINES.pick_random())
	var stove := Game.kitchen
	if stove and stove.claim_cook(g):
		g._walk_to(stove.cook_spot(), Guest.State.EAT)   # am Herd kocht er daraus Suppe (Stove.on_arrived)
		if Game.tracing:
			print("[Flecken] %s bringt Kürbismatsch in die Küche und kocht" % g.display_name)
	elif stove:
		_jobs[g.id] = {"guest": g, "target": null, "phase": "drop"}
		g.start_visit(stove.cook_spot() + stove.front * 1.2)
		if Game.tracing:
			print("[Flecken] %s bringt Kürbismatsch in die Küche" % g.display_name)
	else:
		g._drop_held()
		g._set_idle(randf_range(2.0, 4.0))
	return true


## Debug (--mess[=wachs]): 3 m vor dem Spieler liegt Kürbismatsch (bzw. ein großer Wachsfleck), der erste ordentliche
## Erwachsene steht hinter dem Spieler und sieht ihn. false = keiner da.
func debug(wax: bool) -> bool:
	var p := Game.player
	var forward := -p.global_transform.basis.z
	forward = Vector3(forward.x, 0, forward.z).normalized()
	var at := p.global_position + forward * 3.0
	var mess: Node3D
	if wax:
		mess = Game.traces.add_guest_drop("wax_splash", at)
	else:
		var mush := Item.create(Item.Kind.PUMPKIN_MUSH, Item.mush_extra("halloween", Calendar._elapsed(), 0.9, 1))
		Game.social._world.add_child(mush)
		mush.global_position = at + Vector3.UP * 0.02
		mess = mush
	var tidy := Game.social.living_guests().filter(func(g: Guest) -> bool: return is_tidy(g))
	if tidy.is_empty():
		return false
	var g: Guest = tidy[0]
	g.global_position = p.global_position - forward * 1.5 + forward.cross(Vector3.UP) * 0.8 + Vector3.UP * 0.05   # hinter dir
	g.look_at(Vector3(at.x, g.global_position.y, at.z), Vector3.UP)
	g._set_idle(20.0)
	_gap = 0.0
	_scan = 0.5
	return mess != null
