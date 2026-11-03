class_name Hauntings
extends Node
## Gäste mit „kreisenden Händen“ (Spielkonzept 5.13, entschieden 2026-11-03, ZIM-32): Zwei erwachsene Gäste ohne
## Kernrolle sucht der Lakengeist gezielt heim – fest aus ihrer Identität (Guest.gen_seed, in jedem Spiel dieselben),
## der erste in der ersten Monatshälfte (er führt das Salz ein), der zweite in der zweiten; die Nacht würfelt jedes
## Spiel aus Social.night_seed.
##   · Zeichen: In der Nacht nach Tag S, zwischen HOUR.x und HOUR.y Uhr, weckt es ihn. Er zieht den Vorhang auf, der
##     Lakengeist steht am Glas und kreist mit den Händen (SheetGhost.haunt, Stufe 2, blutige Handabdrücke), dann ist er
##     weg. Am Tag erzählt der Gast davon (Erlebnis „ghost_circle“) – der erste mit dem Hinweis auf Salz. Haltung
##     „haunted“ bis zum Ende der nächsten Nacht.
##   · Ohne Hilfe: In der Nacht darauf kommt er wieder – durch den Vorhang (Stufe 4), packt zu, Losreißen gibt es nicht.
##     Schützt eine heile Salzlinie das Zimmer, weist sie ihn ab, und der Gast dankt beim nächsten Gespräch
##     („ghost_salt“). Ein Zeuge – der Spieler im Zimmer – vertreibt ihn wie sonst. Ein Versuch, danach ist es vorbei.
##   · Schläft der Spieler (SleepSkip), läuft beides abstrakt: Handabdrücke und Erlebnis, dann Salz oder Tod im Zimmer.
##   · Er kommt nur, wenn der Gast in seinem Zimmer ist (wach oder im Bett) und der Lakengeist frei ist – bis
##     LAST_HOUR versucht er es weiter. Kam das Zeichen nicht zustande, bleibt auch die zweite Nacht ruhig.
## Edna (1987 im Hotel, 2.7) kennt den Brauch: Ab dem ersten Toten streut sie abends Salz auf ihre Fensterbank (ohne
## Fenster vor ihre Tür) – nur bei sich, aus eigener Packung (Item.SALT_LINES Linien, Haltung „salt_pack“), nie aus den
## drei Packungen des Spielers. Sie streut nur, wo der Spieler gerade nicht hinsieht, und nur, wenn keine heile Linie
## ihr Zimmer schützt. Beim ersten Mal erzählt sie davon („edna_salt“).
## Nichts Neues im Spielstand: Auswahl aus der ID, Nächte aus night_seed, der Stand steht in den Haltungen der Gäste.
## Kind von Social, erreichbar über Game.social.hauntings.

const COUNT := 2
## Tag S des Zeichens (die Nacht danach), je Gast: erste Monatshälfte (Würgen spätestens in der Nacht zum 14.), zweite
const DAYS := [Vector2i(4, 12), Vector2i(16, 28)]
## So spät in der Nacht kommt er (nach der Geisterstunde, 4.18); bis LAST_HOUR versucht er es
const HOUR := Vector2(1.5, 4.0)
const LAST_HOUR := 5.5
const SCAN := 2.0
## Gast-Zustände, aus denen er geholt werden kann (im Bett liegt er im Zustand SLEEP)
const FREE_STATES := [Guest.State.SLEEP, Guest.State.IDLE, Guest.State.WALK]
const EDNA := "edna"
const EDNA_FROM := 19.0               ## ab dieser Uhrzeit streut sie (bis zum Morgen)
const KINDS := ["ghost_circle", "ghost_salt", "edna_salt"]

## Was der Gast vom Zeichen erzählt: der erste mit Salz, der zweite ohne
const SIGN_FIRST := [
	"Heute Nacht hat mich etwas geweckt. Draußen vor dem Fenster – ein Laken, und Hände, die immer im Kreis gehen. Meine Großmutter hat früher Salz vor die Tür gestreut, gegen so was. Ob das hilft?",
	"Da war etwas an meinem Fenster. Es hat die Hände an die Scheibe gelegt und kreisen lassen … Meine Oma hätte jetzt Salz über die Schwelle gestreut. Ich lach nicht mehr darüber.",
]
const SIGN_OTHER := [
	"Heute Nacht war etwas vor meinem Fenster. Hände, die kreisen, immer weiter … Es hat mich angesehen. Ich glaube, es kommt wieder.",
	"Ich bin aufgewacht, und am Fenster war ein Laken. Mit Händen. Sie haben gekreist, ganz langsam. Was will das von mir?",
]
const SIGN_AGAIN := "Die Hände am Fenster … ich sehe sie immer noch kreisen, wenn ich die Augen zumache."
const SALT_THANKS := [
	"Es war wieder da, heute Nacht. Aber es kam nicht herein – vor meiner Tür lag Salz. Warst du das? Danke.",
	"Das Laken stand wieder am Fenster. Dann hat es gezischt, und es war fort. Das Salz … ich verdanke dir mein Leben.",
]
const SALT_AGAIN := "Ohne das Salz wär ich jetzt nicht mehr hier."
const EDNA_TELLS := "Das Salz auf meiner Fensterbank? Ein alter Brauch. Ich hab ihn einmal vergessen, vor langer Zeit. Kein zweites Mal."
const EDNA_AGAIN := "Lass mein Salz liegen, Kind. Es weiß, wofür es da ist."

var _scan := SCAN
var _ids: Array[String] = []         ## die beiden Gäste (Reihenfolge = Monatshälfte), beim ersten Bedarf bestimmt
var _debug_sign := {}                ## Debug (--kreisen=nacht): Gast-ID → Beginn der Zeichen-Nacht (Spielzeit)


func reset() -> void:
	_ids.clear()
	_debug_sign.clear()


func _process(delta: float) -> void:
	if Game.game_over or Game.social == null or Game.director == null:
		return
	_scan -= delta
	if _scan > 0.0:
		return
	_scan = SCAN
	if Game.director.first_attack_done:   # erst nach dem ersten Angriff (4.20)
		for i in chosen().size():
			_check(i)
	_edna_salt()


# --- Die beiden Gäste --------------------------------------------------------------------------

## IDs der beiden Gäste: erwachsene Hausbewohner (6.20) ohne Kernrolle und ohne Schutz (CoreRoles, 6.17), nicht Gustav,
## mit Außenfenster oder Fenstertür im Zimmer und ohne Kernfigur im selben Zimmer (Ednas Salz schützte sie sonst gleich mit) – geordnet nach einem Wert
## aus ihrer festen Identität (gen_seed), kein Zufall.
func chosen() -> Array[String]:
	if _ids.is_empty():
		var list: Array[Guest] = []
		for guest in Game.social.guests:
			var g: Guest = guest
			if g.gen_seed >= 0 and g.profile.has("household") and not g.is_child() and CoreRoles.role_of(g) == "" \
					and not Grinch.is_grinch(g) and window_of(g) != null and not _with_core(g):
				list.append(g)
		list.sort_custom(func(a: Guest, b: Guest) -> bool:
			return hash([a.gen_seed, "kreisen"]) < hash([b.gen_seed, "kreisen"]))
		for g in list.slice(0, COUNT):
			_ids.append(g.id)
	return _ids


func _with_core(g: Guest) -> bool:
	for other in Game.social.guests:
		if (other as Guest).is_core() and (other as Guest).housemate_of(g):
			return true
	return false


## Fenster (mit Vorhang) bzw. unverschlossene Fenstertür seines Zimmers, nächst der Zimmermitte – null, wenn keins.
func window_of(g: Guest) -> Node3D:
	var no := String(g.home["no"])
	var center: Vector3 = Game.social.builder.rooms[no]["center"] if Game.social.builder.rooms.has(no) else g.home["door_inside"]
	var best: Node3D = null
	var best_d := INF
	for node in get_tree().get_nodes_in_group("windows") + get_tree().get_nodes_in_group("french_doors"):
		var ok := false
		if node is Door:
			ok = not (node as Door).locked and SaltLine.room_of(node) == no
		else:
			var win := node as HotelWindow
			ok = win.has_curtains() and not win.sealed and SaltLine.room_of(win) == no
		var d := (node as Node3D).global_position.distance_to(center)
		if ok and d < best_d:
			best_d = d
			best = node
	return best


## Nacht des Zeichens für den i-ten Gast: Tag S (die Nacht danach) und Beginn als Spielzeit – je Spiel aus night_seed.
func sign_day(i: int) -> int:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([Game.social.night_seed, "kreisen", i])
	var days: Vector2i = DAYS[i]
	return rng.randi_range(days.x, days.y)


## Zeitfenster [Beginn, Ende] des Besuchs in der Nacht nach Tag day (Zeichen: S, Würgen: S + 1).
func visit_window(i: int, day: int) -> Vector2:
	var id: String = chosen()[i]
	if _debug_sign.has(id):
		var start := float(_debug_sign[id]) + (day - sign_day(i)) * Calendar.DAY_SECONDS
		return Vector2(start, start + (LAST_HOUR - HOUR.x) * Calendar.HOUR)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([Game.social.night_seed, "kreisen_uhr", i, day])
	return Vector2(Calendar.at(day + 1, rng.randf_range(HOUR.x, HOUR.y)), Calendar.at(day + 1, LAST_HOUR))


## Steht der Gast unter dem Zeichen (zwischen Zeichen und Würgen)?
static func is_haunted(g: Guest) -> bool:
	return g.has_stance("haunted")


func _check(i: int) -> void:
	var g := Game.social.guest_by_id(chosen()[i])
	if g == null or g.dead:
		return
	var now := Game.director.elapsed
	var day := sign_day(i)
	var sign := visit_window(i, day)
	var kill := visit_window(i, day + 1)
	if now >= sign.x and now < sign.y and not is_haunted(g):
		visit(g, false, kill.y - now)
	elif now >= kill.x and now < kill.y and is_haunted(g):
		visit(g, true)


## Besuch beim Gast (Zeichen bzw. Würgen), wenn er zu Hause ist und der Lakengeist frei. haunted_for: so lange gilt das
## Zeichen danach (bis zum Ende der Würge-Nacht). false: diesmal nicht – beim nächsten Durchgang wieder.
func visit(g: Guest, kill: bool, haunted_for: float = Calendar.DAY_SECONDS) -> bool:
	var builder := Game.social.builder
	var no := String(g.home["no"])
	var window := window_of(g)
	if window == null or builder.home_room_at(g.global_position) != no or not g.state in FREE_STATES \
			or (g.hiding != null and g.state != Guest.State.SLEEP):
		return false
	var asleep := Game.sleep_skip != null and Game.sleep_skip.active
	if not asleep:
		var ghost := Game.ghost
		if ghost == null or ghost.state != SheetGhost.State.IDLE or Game.director.threats_paused():
			return false
		_wake(g)
		if not kill and window is HotelWindow:
			(window as HotelWindow).set_closed(false)   # er zieht den Vorhang auf – da klopft doch etwas
		if not ghost.haunt(g, window, kill):
			return false
	if kill:
		g.clear_stance("haunted")   # ein Versuch – danach ist es vorbei
	else:
		g.set_stance("haunted", haunted_for)
		g.remember("ghost_circle", window.global_position)   # das Pochen am Glas hat ihn geweckt – er erzählt sicher davon
	if Game.tracing:
		print("[Kreisen] %s (%s, Zimmer %s)%s" % ["holt " + g.display_name if kill else "Zeichen bei " + g.display_name,
			Calendar.time_text(Game.director.elapsed), no, " – im Schlaf des Spielers" if asleep else ""])
	if asleep:
		_resolve_asleep(g, window, kill)
	return true


## Aus dem Bett, Licht bleibt aus (wake_up macht es an – er ist im Dunkeln wach geworden).
func _wake(g: Guest) -> void:
	if g.state == Guest.State.SLEEP:
		g.wake_up()
		g.after_woken(true)
	var sw := LightSwitch.find(get_tree(), String(g.home["no"]))
	if sw:
		sw.set_on(false)


## Abstrakt, während der Spieler schläft: Zeichen – Handabdrücke und Erlebnis; Würgen – das Salz weist ihn ab, sonst
## stirbt der Gast in seinem Zimmer.
func _resolve_asleep(g: Guest, window: Node3D, kill: bool) -> void:
	g.ghost_visits = maxi(g.ghost_visits + 1, SheetGhost.THROUGH_CURTAIN_FROM if kill else SheetGhost.HYPNOSIS_FROM)
	if not kill:
		if Game.traces:
			if window is Door:
				Game.traces.add_french_door_handprints(window as Door)
			else:
				Game.traces.add_window_handprints(window as HotelWindow)
		return
	var line := SaltLine.guarding(String(g.home["no"]))
	if line:
		line.repel()
		g.remember("ghost_salt", window.global_position)
		if Game.tracing:
			print("[Kreisen] das Salz hält ihn von %s fern" % g.display_name)
		return
	_wake(g)
	if g.is_protected():   # geschützte Kernfigur (6.17): reißt sich los, Würgemale
		g.wound_by("choke")
		return
	Game.director.guest_slain(g, "ghost")


# --- Was sie erzählen (Social.experience_line) ---------------------------------------------------

## Satz zu einem der eigenen Erlebnisse (KINDS); again: später am Tag, kürzer.
func line(g: Guest, kind: String, again: bool) -> String:
	match kind:
		"ghost_circle":
			if again:
				return SIGN_AGAIN
			return ((SIGN_FIRST if not chosen().is_empty() and chosen()[0] == g.id else SIGN_OTHER) as Array).pick_random()
		"ghost_salt":
			return SALT_AGAIN if again else SALT_THANKS.pick_random()
		"edna_salt":
			return EDNA_AGAIN if again else EDNA_TELLS
	return ""


# --- Edna streut Salz --------------------------------------------------------------------------

## So viele Linien sind noch in Ednas eigener Packung.
func edna_salt_left(edna: Guest) -> int:
	return int(edna.stances["salt_pack"].get("left", Item.SALT_LINES)) if edna.stances.has("salt_pack") else Item.SALT_LINES


## Ab dem ersten Toten, abends zu Hause und wach: Schützt keine heile Linie ihr Zimmer, streut sie eine – auf die
## Fensterbank (verwischt niemand), ohne Fenster vor die Tür, innen. Nur, wo der Spieler gerade nicht hinsieht.
func _edna_salt() -> void:
	var edna := Game.social.guest_by_id(EDNA)
	if edna == null or edna.dead or edna.hiding != null or not edna.state in [Guest.State.IDLE, Guest.State.WALK]:
		return
	var no := String(edna.home["no"])
	var hour := Calendar.hour_of(Game.director.elapsed)
	if (hour < EDNA_FROM and hour >= Social.SLEEP_END) or not _anyone_dead():
		return
	var left := edna_salt_left(edna)
	if left <= 0 or Game.social.builder.home_room_at(edna.global_position) != no or SaltLine.guarding(no) != null:
		return
	var spot := _edna_spot(no)
	if spot.is_empty() or Game.director.player_can_see(spot["pos"] as Vector3):
		return
	SaltLine.lay(Game.player.get_parent(), spot)
	edna.set_stance("salt_pack", Calendar.at(Calendar.HALLOWEEN + 2, 0.0) - Game.director.elapsed, {"left": left - 1})
	if left == Item.SALT_LINES:
		edna.remember("edna_salt", spot["pos"])   # beim ersten Mal erzählt sie davon
	if Game.tracing:
		print("[Kreisen] Edna streut Salz (%s, noch %d Linien)" % ["Fensterbank" if spot["sill"] else "Tür", left - 1])


func _anyone_dead() -> bool:
	for guest in Game.social.guests:
		if (guest as Guest).dead:
			return true
	return false


## Wohin Edna streut: Fensterbank ihres Zimmers, sonst innen vor die Zimmertür ({} = nirgends).
func _edna_spot(no: String) -> Dictionary:
	for node in get_tree().get_nodes_in_group("windows"):
		var spot := SaltLine.spot_for(node, Vector3.ZERO)
		if spot.has("pos") and spot["room"] == no:
			return spot
	var info: Dictionary = Game.director.rooms.get(no, {})
	if info.is_empty():
		return {}
	var spot := SaltLine.spot_for(info["door"], info["door_inside"])
	return spot if spot.has("pos") else {}


# --- Debug (--kreisen) ---------------------------------------------------------------------------

## --kreisen[=liste|zeichen|tod|salz|schlaf|nacht|edna|halten][,id] (Spielkonzept 5.13):
## liste (Standard): die beiden Gäste und ihre Nächte, mit Prüfungen · zeichen: der Lakengeist kommt jetzt zum ersten
## (bzw. id) ans Fenster – Erlebnis, Haltung, Hände · tod: Zeichen, dann holt er ihn – tot · salz: wie tod, aber Salz vor
## der Tür – er lebt und dankt · schlaf: beides abstrakt im Schlaf des Spielers – einer stirbt, einer mit Salz lebt ·
## nacht: die Zeichen-Nacht beginnt in 5 s, alle liegen im Bett (der echte Ablauf mit Wecken) · edna: ein Gast stirbt,
## Edna streut abends Salz · halten: Zeichen gesetzt und Edna mit angebrochener Packung (für --savetest).
## Meldet „[Kreisen] … ok“ bzw. „FEHLER“.
func debug(parts: PackedStringArray) -> void:
	var what := parts[0] if parts.size() > 0 and parts[0] != "" else "liste"
	var check := func(text: String, ok: bool) -> void:
		print("[Kreisen] %s: %s" % [text, "ok" if ok else "FEHLER"])
	var social := Game.social
	var ids := chosen()
	check.call("zwei Gäste", ids.size() == COUNT and ids[0] != ids[1])
	for i in ids.size():
		var g := social.guest_by_id(ids[i])
		var s := sign_day(i)
		print("[Kreisen] %d. %s (%s, Zimmer %s): Zeichen in der Nacht nach dem %d. – %s, Würgen %s" % [i + 1, g.display_name,
			g.id, g.home["no"], s, Calendar.time_text(visit_window(i, s).x), Calendar.date_text(visit_window(i, s + 1).x)])
		check.call("%s erwachsen, keine Kernrolle, mit Fenster" % g.display_name, not g.is_child() and CoreRoles.role_of(g) == "" and window_of(g) != null)
		check.call("%d. in der %s Monatshälfte" % [i + 1, "ersten" if i == 0 else "zweiten"],
			(s + 1 <= 15) if i == 0 else (s >= 16 and s + 1 < Calendar.HALLOWEEN))
	if what == "liste" or ids.size() < COUNT:
		return
	var g := social.guest_by_id(parts[1]) if parts.size() > 1 and parts[1] != "" else social.guest_by_id(ids[0])
	if g == null:
		return
	Game.director.first_attack_done = true
	Game.ghost.debug_ignore_player = true
	var no := String(g.home["no"])
	match what:
		"zeichen", "tod", "salz":
			social.debug_sleep(true)   # Nacht, Mitbewohner schlafen – sonst vertreiben sie ihn als Zeugen
			_debug_home(g)
			check.call("Zeichen beginnt", visit(g, false))
			get_tree().create_timer(14.0, false).timeout.connect(func() -> void:
				check.call("erzählt von kreisenden Händen", g.untold_experience().get("kind", "") == "ghost_circle")
				check.call("Haltung „haunted“", is_haunted(g))
				check.call("lebt nach dem Zeichen", not g.dead)
				if what == "zeichen":
					print("[Kreisen] Satz: %s" % line(g, "ghost_circle", false))
					return
				_debug_home(g)
				if what == "salz":   # erst jetzt – auf der Flucht nach dem Zeichen hätte er es verwischt
					var info: Dictionary = Game.director.rooms[no]
					SaltLine.lay(Game.player.get_parent(), SaltLine.spot_for(info["door"], info["door_front"]))
				check.call("Würgen beginnt", visit(g, true))
				get_tree().create_timer(16.0, false).timeout.connect(func() -> void:
					check.call("Haltung vorbei", not is_haunted(g))
					if what == "tod":
						check.call("erwürgt", g.dead)
					else:
						check.call("lebt dank Salz", not g.dead)
						var held := false   # danach verwischt er sie vielleicht auf der Flucht
						for node in get_tree().get_nodes_in_group("salt_lines"):
							held = held or ((node as SaltLine).room == no and (node as SaltLine).hits == 1)
						check.call("Salz hat ihn abgewiesen", held)
						var told := false
						for e in g.experiences:
							told = told or e["kind"] == "ghost_salt"
						check.call("dankt fürs Salz", told)))
		"schlaf":
			var other := social.guest_by_id(ids[1] if g.id == ids[0] else ids[0])
			var info: Dictionary = Game.director.rooms[String(other.home["no"])]
			SaltLine.lay(Game.player.get_parent(), SaltLine.spot_for(info["door"], info["door_front"]))
			social.debug_sleep(true)
			Game.sleep_skip.active = true   # nur die Abfrage in visit – SleepSkip selbst läuft nicht
			for x in [g, other]:
				check.call("%s: Zeichen im Schlaf" % x.display_name, visit(x, false) and x.untold_experience().get("kind", "") == "ghost_circle")
				check.call("%s: Würgen im Schlaf" % x.display_name, visit(x, true))
			Game.sleep_skip.active = false
			check.call("%s erwürgt" % g.display_name, g.dead)
			check.call("%s lebt dank Salz" % other.display_name, not other.dead)
		"nacht":
			social.debug_sleep(true)
			check.call("liegt im Bett", g.state == Guest.State.SLEEP)
			_debug_sign[g.id] = Game.director.elapsed + 5.0
			get_tree().create_timer(25.0, false).timeout.connect(func() -> void:
				check.call("aus dem Bett geholt, Zeichen gesehen", is_haunted(g) and g.untold_experience().get("kind", "") == "ghost_circle")
				check.call("lebt", not g.dead))
		"edna", "halten":
			var edna := social.guest_by_id(EDNA)
			for other in social.living_guests():
				var o: Guest = other
				if not o.is_core() and not o.is_child() and not o.housemate_of(edna) and not o.id in ids:
					o.die("monster")
					social.on_guest_died(o, "monster", true)
					break
			Game.director.elapsed = Calendar.at(Calendar.day_of(Game.director.elapsed), EDNA_FROM + 1.0)
			_debug_home(edna)
			_edna_salt()
			check.call("Edna streut Salz", SaltLine.guarding(String(edna.home["no"])) != null)
			check.call("eigene Packung angebrochen", edna_salt_left(edna) == Item.SALT_LINES - 1)
			_edna_salt()
			check.call("kein zweites Mal, solange es hält", edna_salt_left(edna) == Item.SALT_LINES - 1)
			if what == "halten":
				g.set_stance("haunted", Calendar.DAY_SECONDS)


## Gast in sein Zimmer, wach und ruhig – Licht aus.
func _debug_home(g: Guest) -> void:
	if g.hiding:
		g._leave_hide()
	g.global_position = Game.social.builder.rooms[String(g.home["no"])]["center"] if Game.social.builder.rooms.has(String(g.home["no"])) else g.home["door_inside"]
	g.fear = 0.0
	g._set_idle(20.0)
	var sw := LightSwitch.find(get_tree(), String(g.home["no"]))
	if sw:
		sw.set_on(false)
