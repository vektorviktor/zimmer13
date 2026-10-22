class_name MonsterDirector
extends Node
## Steuert das Monster über versteckte Werte (Spielkonzept 4.9):
##   Dreistigkeit (global) · Neugier (pro Zone) · Abschreckung (Deko × Licht / Anspruch)
##   Druck(Ort) = Dreistigkeit × (0,5 + 0,5 × Neugier/100)
##   Druck > Abschreckung → das Monster kommt durch.
##
## Dramaturgie (Spielkonzept 2.1, 4.13):
##   · Friedlicher Anfang – bis zum ersten Angriff (3./4. Oktober, bei einer Feier) kein Monster.
##   · Danach streift es im ganzen Hotel umher, abwechselnd mit Ruhephasen im Keller;
##     anfangs lange Pausen, mit jedem Tag kürzere.
##   · Die ersten Angriffe sind harmlos: es holt niemanden, es zeigt sich nur.
##   · Rauschen nach Entfernung (ab ~20 m, lauter bis ~4 m), Lampen flackern nur in seiner Nähe.
##   · Halluzinationen nach einem Todesfall, kleine Veränderungen im Hotel, wenn niemand hinsieht.
##   · Beim Aufbruch wählt es eine Absicht (Umsehen, einen holen, Raubzug), und eine Flackerwelle
##     vom Keller aus verrät sie mit ihrer Dauer – manchmal täuscht es (4.17).

## CALM = ruht im Keller, ACTIVE = streift umher.
enum Phase { CALM, ACTIVE }
## Was es in dieser Aktivphase vorhat (Spielkonzept 4.17) – gilt für Gäste und Spieler
enum Intent { ROAM, ONE, RAMPAGE }
const INTENT_NAMES := ["Umsehen", "Einen holen", "Raubzug"]

# --- Tuning -------------------------------------------------------------------
const BOLDNESS_START := 25.0
const BOLDNESS_PER_SECOND := 0.04      ## ≈ +2,4 pro Minute
const DEMAND_GROWTH_SECONDS := 900.0   ## Anspruch an Deko: +100 % alle 15 min
const DECO_RADIUS := 3.0
const LIGHT_DETERRENCE := 12.0
const CHASE_BONUS := 12.0
const MOONLIGHT := 0.3                 ## Helligkeit direkt am offenen Außenfenster
const MOONLIGHT_RANGE := 5.0
## light_at sucht Lichter in einem Raster (Zellen in m) statt unter allen; neu einsortiert alle LIGHT_GRID_FRAMES
## Physik-Frames – getragene Lichter wandern bis dahin höchstens LIGHT_GRID_SLACK Meter aus ihrer Zelle
const LIGHT_CELL := 8.0
const LIGHT_GRID_FRAMES := 30
const LIGHT_GRID_SLACK := 3.0
## In so vielen Sekunden führt jede Zone einmal ihre Neugier nach – verteilt auf die Physik-Frames, sonst
## hängt das Spiel bei ein paar hundert Zonen jede Sekunde kurz
const ZONE_PERIOD := 1.0
const LIGHTS_OFF_CURIOSITY := 30.0     ## Licht aus = das Monster kommt (4.4)
const NOISE_CURIOSITY := 0.25          ## Neugier je Meter Hörweite (Rennen: +2,5 alle 0,6 s)
## Rauschen nach Entfernung zum Spieler (auch durch Wände)
const NOISE_START := 20.0
const NOISE_FULL := 4.0
## Lampen flackern nur in der Nähe des Monsters
const LAMP_FLICKER_RANGE := 9.0
## Hängende Deko (Spielkonzept 5.6) rührt sich schon ab hier – früher, als die Lampen flackern
const DECO_UNREST_RANGE := 16.0
const DECO_UNREST_GHOST := 10.0   ## beim Lakengeist (er ist lautlos – die Deko verrät ihn)
## Debug F7: so weit vom Spieler erscheint das ruhende Monster
const LURE_DISTANCE := 25.0
## Erster Angriff: am 3. oder 4. Oktober, nach so vielen Sekunden einer Feier
const FIRST_ATTACK_DAYS := [3, 4]
const FIRST_ATTACK_PARTY_TIME := 25.0
const FALLBACK_ATTACK_DAY := 5         ## spätestens jetzt – auch ohne Feier
## So viele Angriffe (Aktivphasen) holt es niemanden
const HARMLESS_ATTACKS := 2
## Ruhe- und Aktivphasen in Sekunden: am 1. Oktober → an Halloween
const REST_TIME := Vector2(150.0, 35.0)
const ACTIVE_TIME := Vector2(70.0, 210.0)
## Kleine Veränderungen im Hotel (Sekunden zwischen zwei Ereignissen)
const HAUNT_INTERVAL := Vector2(80.0, 170.0)
## Blutige Schmierspuren an Flurwänden als Spuk: so oft kommt die Möglichkeit dazu, höchstens so viele im Spiel
const WALL_SMEAR_CHANCE := 0.35
const MAX_WALL_SMEARS := 12
## Halluzination: mittlere Sekunden zwischen zwei Rausch-Anfällen nach einem Todesfall
const HALLUCINATION_EVERY := 70.0
const GRIEF_TIME := 900.0
## UV-Licht (Spielkonzept 4.16): so lange muss es im Kegel stehen – mit jedem Mal länger
const UV_REPEL_TIME := 1.0
const UV_HABITUATION := 0.5
const UV_REPEL_MAX := 3.5
const UV_BOLDNESS := 6.0               ## es merkt sich, wer es geblendet hat …
const UV_CURIOSITY := 40.0             ## … und sucht rund um Zimmer 13
const UV_REST_FACTOR := 0.4            ## vertrieben ruht es nur kurz
## Aufbruch (4.17): Chance, dass es angreifen will, steigt mit dem Tag – Stützpunkte (Tag, Chance),
## dazwischen gleitend, davor/danach der erste/letzte Wert. Greift es an, will es n Opfer mit
## Wahrscheinlichkeit ∝ 1/n² (≈ 61 % eins, 15 % zwei, 7 % drei …), höchstens alle Lebenden + Spieler
const ATTACK_CHANCE := [Vector2(4, 0.2), Vector2(7, 0.5), Vector2(10, 0.75), Vector2(20, 0.9), Vector2(30, 0.95)]
## Flackerwelle: Sekunden = SIGNAL_BASE + SIGNAL_PER_VICTIM × gezeigte Opfer, schwankt um
## ± SIGNAL_JITTER; satt nur ein Zucken. Stärke je 0 / 1 / ab 2 Opfern. Läuft mit WAVE_SPEED m/s
## vom Keller aus, ins Obergeschoss über das Treppenhaus.
const SIGNAL_BASE := 1.0
const SIGNAL_PER_VICTIM := 2.0
const SIGNAL_TIME_SATED := 0.4
const SIGNAL_JITTER := 0.15
const SIGNAL_STRENGTH := [0.6, 0.75, 1.0]
const WAVE_SPEED := 15.0
## Täuschung: so oft zuckt es nur kurz, obwohl es angreift – × Dreistigkeit/100
const DECEIVE_CHANCE := 0.2
## Ab so viel Sättigung sieht es sich beim Aufbruch nur um
const SATED_ROAM := 5.0
## Umsehen wird zum Angriff: bei einer Sichtung / wenn es Gerede hört (mit dieser Chance)
const ESCALATE_ON_SIGHT := 0.5
const ESCALATE_ON_TALK := 0.15
## Halluzination: so oft kommt mit dem Rauschen eine lange Flackerwelle ohne Monster (zeigt so viele Opfer)
const FAKE_SIGNAL_CHANCE := 0.35
const FAKE_SIGNAL_VICTIMS := 3

var phase := Phase.CALM
var boldness := BOLDNESS_START
var satiation := 0.0        ## gesättigt, nachdem es einen Gast geholt hat (4.10)
var elapsed := 0.0
var zones: Array[Dictionary] = []
var spawn_points: Array[Vector3] = []
var patrol: Array[Dictionary] = []
var rooms := {}
var player_door_front := Vector3.ZERO
var post_material: ShaderMaterial
## Dramaturgie
var first_attack_done := false
var first_attack_day := 3
var attacks := 0            ## Aktivphasen seit dem ersten Angriff
var grief := 0.0            ## Sekunden „Trauerzeit“ nach einem Todesfall → Halluzinationen
var strange_diary := false  ## im Tagebuch steht beim nächsten Mal eine fremde Zeile
## Bedrohung beim Spieler (0..1) – Rauschen, Brummen, engerer Blick
var player_threat := 0.0
var uv_count := 0           ## so oft schon mit UV vertrieben (Gewöhnung, 4.8)
## Absicht der laufenden Aktivphase und wie viele es noch holen will (4.17)
var intent := Intent.ONE
var victims_left := 1
var shown_victims := 1          ## so viele Opfer hat die letzte Flackerwelle angezeigt
var debug_victims := -1         ## --intent=…: erzwungene Opferzahl (0 = umsehen)

var _monster: Monster
var _phase_left := 0.0
var _zone_timer := 0.0
var _zone_next := 0.0           ## nächste nachzuführende Zone (mit Bruchteil, _update_zones)
## Mitten und Radien der Zonen in gepackten Listen – _zone_at läuft oft (next_roam_target: für jede Zone über alle)
var _zone_centers := PackedVector3Array()
var _zone_radii := PackedFloat64Array()
var _roam_zones := {}           ## Ziel von next_roam_target (Zonenmitte, vor der Zimmertür) → Zone dort
var _light_grid := {}           ## Vector2i (Zelle) → Lichter darin
var _light_reach := 0.0         ## größte Reichweite im Raster
var _windows: Array[Node] = []  ## Fenster fürs Mondlicht, mit dem Raster neu gelesen
var _light_grid_frame := -LIGHT_GRID_FRAMES
var _noise := 0.0
var _pulse := 0.0
var _jumpscare := 0.0
var _hallucination := 0.0
var _haunt_timer := 120.0
var _uv_driven := false     ## die laufende Aktivphase endet, weil UV es vertrieben hat
var _uv_angry := false      ## vom UV vertrieben → beim nächsten Aufbruch eher ein Raubzug
## Flackerwelle: Ausgangspunkt, Start (elapsed), Dauer je Lampe, Stärke
var _wave_origin := Vector3.ZERO
var _wave_start := -1000.0
var _wave_time := 0.0
var _wave_strength := 0.0
var _wave_level := 0        ## 0 = Zucken, 1 = Flackern, 2 = langes Flackern (ab zwei Opfern)
var _wave_told := true      ## Untertitel beim Spieler schon gezeigt
var _stairwell := Vector3.ZERO
var _builder: LevelBuilder


func setup(builder: LevelBuilder, monster: Monster) -> void:
	_builder = builder
	zones = builder.zones
	spawn_points = builder.spawn_points
	patrol = builder.patrol
	rooms = builder.rooms
	player_door_front = builder.player_door_front
	_stairwell = builder.stairwell_point
	_monster = monster
	first_attack_day = FIRST_ATTACK_DAYS[randi() % FIRST_ATTACK_DAYS.size()]


func _physics_process(delta: float) -> void:
	if not Game.game_over:
		if Input.is_action_just_pressed("debug_manifest") and not _monster.is_active():
			start_warning()
		if Input.is_action_just_pressed("debug_lure"):
			debug_lure()
		elapsed += delta
		if first_attack_done:
			boldness = minf(100.0, boldness + BOLDNESS_PER_SECOND * delta)
		satiation = maxf(0.0, satiation - 0.1 * delta)
		grief = maxf(0.0, grief - delta)
		_update_zones(delta)
		_zone_timer -= delta
		if _zone_timer <= 0.0:
			_zone_timer = 1.0
			# „Angst riecht“: ein Spieler unter Schock lockt das Monster an
			if Game.player and Game.player.shock > 0.1:
				add_curiosity(Game.player.global_position, Game.player.shock * 3.0)
		if not first_attack_done:
			_check_first_attack()
		else:
			_update_schedule(delta)
			_update_haunting(delta)
		_update_hallucination(delta)
	_update_effects(delta)


# --- Versteckte Werte ---------------------------------------------------------------

func effective_boldness() -> float:
	return clampf(boldness - satiation, 0.0, 100.0)


func demand() -> float:
	return 1.0 + elapsed / DEMAND_GROWTH_SECONDS


func pressure_at(p: Vector3, chasing: bool = false) -> float:
	return _pressure_in(_zone_at(p), chasing)


func _pressure_in(zone: Dictionary, chasing: bool = false) -> float:
	return effective_boldness() * (0.5 + 0.5 * _curiosity_of(zone) / 100.0) + (CHASE_BONUS if chasing else 0.0)


func deterrence_at(p: Vector3) -> float:
	if _builder and _builder.is_safe(p):
		return INF   # Katzenraum (Spielkonzept 7.7): dort hinein kommt es nie, wer drinsteht, ist geschützt
	var light := light_at(p + Vector3.UP)
	return deco_strength_at(p) * (0.6 + light) / demand() \
		+ light * LIGHT_DETERRENCE * (1.0 - effective_boldness() / 120.0)


func is_blocked(p: Vector3, chasing: bool) -> bool:
	return deterrence_at(p) > pressure_at(p, chasing)


## Steht jemand hier im Schutz von Deko und Licht – auch gegen ein jagendes Monster?
func is_protected(p: Vector3) -> bool:
	return is_blocked(p, true)


func deco_strength_at(p: Vector3) -> float:
	return _deco_strength(p, _deco_items())


## Gegenstände, die gerade als Deko zählen (nicht in der Hand, nicht umgeworfen).
func _deco_items() -> Array[Item]:
	var result: Array[Item] = []
	for node in get_tree().get_nodes_in_group("items"):
		var item := node as Item
		if not item.is_held and item.deco_strength > 0.0 and not item.is_toppled():
			result.append(item)
	return result


func _deco_strength(p: Vector3, decos: Array[Item]) -> float:
	var total := 0.0
	for item in decos:
		var d := Vector2(item.global_position.x - p.x, item.global_position.z - p.z).length()
		if d < DECO_RADIUS and absf(item.global_position.y - p.y) < 2.5:   # nur auf demselben Stockwerk
			total += item.deco_strength * (1.0 - 0.5 * d / DECO_RADIUS)
	return total


## Helligkeit 0..1 an einem Punkt – alle Lichtquellen mit freier Sichtlinie.
## `skip`: dieses Licht nicht mitzählen (eigenes Licht in der Hand zählt in Senses extra).
func light_at(p: Vector3, skip: Node = null) -> float:
	var space := _monster.get_world_3d().direct_space_state
	var total := 0.0
	for node in _lights_near(p):
		if not is_instance_valid(node):
			continue
		var light := node as OmniLight3D
		if light.light_energy < 0.02:
			continue
		var lp := light.global_position
		var d := lp.distance_to(p)
		if d > light.omni_range or not light.is_visible_in_tree():
			continue
		if skip != null and is_instance_valid(skip) and skip.is_ancestor_of(light):
			continue
		var query := PhysicsRayQueryParameters3D.create(lp, p, 1 | 2)
		if not space.intersect_ray(query).is_empty():
			continue
		var att := 1.0 - d / light.omni_range
		total += light.light_energy * att * att * 1.6
	# Mondlicht durch Außenfenster mit offenen Vorhängen
	for node in _windows:
		var win := node as HotelWindow
		if not is_instance_valid(win) or not win.lets_moonlight():
			continue
		var wp := win.inside_point()
		var wd := wp.distance_to(p)
		if wd > MOONLIGHT_RANGE:
			continue
		var moon_query := PhysicsRayQueryParameters3D.create(wp, p, 1 | 2)
		if space.intersect_ray(moon_query).is_empty():
			total += MOONLIGHT * (1.0 - wd / MOONLIGHT_RANGE)
	return clampf(total, 0.0, 1.0)


## Lichter, deren Reichweite p erreichen könnte (Raster aus _light_grid, Kandidaten – light_at prüft genau).
func _lights_near(p: Vector3) -> Array:
	var frame := Engine.get_physics_frames()
	if frame - _light_grid_frame >= LIGHT_GRID_FRAMES:
		_light_grid_frame = frame
		_windows = get_tree().get_nodes_in_group("windows")
		_light_grid.clear()
		_light_reach = 0.0
		for node in get_tree().get_nodes_in_group("light_source"):
			var light := node as OmniLight3D
			var cell := Vector2i(floori(light.global_position.x / LIGHT_CELL), floori(light.global_position.z / LIGHT_CELL))
			if not _light_grid.has(cell):
				_light_grid[cell] = []
			_light_grid[cell].append(light)
			_light_reach = maxf(_light_reach, light.omni_range)
	var reach := _light_reach + LIGHT_GRID_SLACK
	var result := []
	for x in range(floori((p.x - reach) / LIGHT_CELL), floori((p.x + reach) / LIGHT_CELL) + 1):
		for z in range(floori((p.z - reach) / LIGHT_CELL), floori((p.z + reach) / LIGHT_CELL) + 1):
			var cell := Vector2i(x, z)
			if _light_grid.has(cell):
				result.append_array(_light_grid[cell])
	return result


func curiosity_at(p: Vector3) -> float:
	return _curiosity_of(_zone_at(p))


func _curiosity_of(zone: Dictionary) -> float:
	return 40.0 if zone.is_empty() else float(zone["curiosity"])


func add_curiosity(p: Vector3, amount: float) -> void:
	var zone := _zone_at(p)
	if not zone.is_empty():
		zone["curiosity"] = clampf(float(zone["curiosity"]) + amount, 0.0, 100.0)


## Zonen sind Kreise auf einem Stockwerk (Keller, Erdgeschoss, Obergeschoss).
func _zone_at(p: Vector3) -> Dictionary:
	if _zone_centers.size() != zones.size():
		_zone_centers.clear()
		_zone_radii.clear()
		for zone in zones:
			_zone_centers.append(zone["center"])
			_zone_radii.append(zone["radius"])
	var best := -1
	var best_ratio := INF
	for i in _zone_centers.size():
		var c := _zone_centers[i]
		if absf(p.y - c.y) > 2.5:
			continue
		var ratio := Vector2(p.x - c.x, p.z - c.z).length() / _zone_radii[i]
		if ratio < best_ratio:
			best_ratio = ratio
			best = i
	return zones[best] if best >= 0 else {}


func zone_name_at(p: Vector3) -> String:
	var zone := _zone_at(p)
	return "" if zone.is_empty() else String(zone["name"])


## Neugier strebt langsam zu einem Grundwert aus Dunkelheit und fehlender Deko;
## Ereignisse (Lärm, Sichtung …) addieren direkt darauf.
## Je Physik-Frame ein Stück der Zonen, sodass jede einmal je ZONE_PERIOD drankommt.
func _update_zones(delta: float) -> void:
	if zones.is_empty():
		return
	var until := _zone_next + zones.size() * delta / ZONE_PERIOD
	var first := int(_zone_next)
	var count := mini(int(until) - first, zones.size())
	_zone_next = fmod(until, float(zones.size()))
	if count <= 0:
		return
	var decos := _deco_items()
	for i in count:
		var zone: Dictionary = zones[(first + i) % zones.size()]
		var c: Vector3 = zone["center"]
		var light := light_at(c + Vector3.UP)
		var deco := _deco_strength(c, decos) / demand()
		var base := 10.0 + (1.0 - light) * 55.0 + clampf(25.0 - deco, 0.0, 25.0)
		var current: float = zone["curiosity"]
		zone["curiosity"] = clampf(lerpf(current, base, 0.04), 0.0, 100.0)


# --- Dramaturgie ------------------------------------------------------------------------

## Noch harmlos? Die ersten Angriffe holen niemanden (Spielkonzept 2.1).
func is_harmless() -> bool:
	return attacks <= HARMLESS_ATTACKS


## Soll ein Gast jetzt eine Feier geben, damit der erste Angriff dort passieren kann?
func wants_first_attack_party() -> bool:
	return not first_attack_done and Calendar.today() >= first_attack_day


## Ist es um diesen Ort herum ruhig (kein Monster in der Nähe)?
## Ruhig = kein Monster in der Nähe – und kein jagender Kürbismann (Spielkonzept 4.19): Wo er hinkommt, enden
## Feier und Partien von selbst.
func is_quiet(pos: Vector3, radius: float = 25.0) -> bool:
	if Game.pumpkin and Game.pumpkin.is_hunting() and Game.pumpkin.global_position.distance_to(pos) <= radius:
		return false
	return not _monster.is_active() or _monster.global_position.distance_to(pos) > radius


## Immer nur eine Bedrohung im Haus (entschieden 2026-10-20): Ist das Monster, der Lakengeist oder der Kürbismann
## unterwegs, warten die anderen, bis er weg ist. who: wer fragt – er selbst zählt nicht. Debug-Aufrufe fragen nicht.
func other_threat_active(who: Node) -> bool:
	if who != _monster and _monster.is_active():
		return true
	if who != Game.ghost and Game.ghost and Game.ghost.is_active():
		return true
	return who != Game.pumpkin and Game.pumpkin != null and Game.pumpkin.in_house()


func _check_first_attack() -> void:
	if other_threat_active(_monster):
		return   # die Feier wartet auf ihren Auftritt
	var day := Calendar.today()
	var social := Game.social
	if social and social.party_active and day >= first_attack_day and social.party_age() >= FIRST_ATTACK_PARTY_TIME:
		_first_attack_at_party()
	elif day >= FALLBACK_ATTACK_DAY:
		first_attack_done = true
		_start_activity(spawn_points[0])


## Mitten in der Feier: Licht aus, Musik aus, Stille – und es ist da.
func _first_attack_at_party() -> void:
	first_attack_done = true
	var builder := Game.social.builder
	var party_light := LightSwitch.find(get_tree(), "partyraum")
	if party_light:
		party_light.set_on(false)
	Game.social.end_party("")
	Game.play_sound("bang", 0.6)
	if Game.player and builder.in_area(Game.player.global_position, "partyraum"):
		Game.say("Das Licht geht aus. Die Musik verstummt.", 3.0)
	# Es steht in der dunklen Ecke des Partyraums
	_start_activity(builder.party_corner + Vector3(0, 0.05, 0), false)
	_monster.investigate(Game.social.party_center())


## Aufbruch: Absicht wählen, Flackerwelle vom Keller aus (der erste Angriff bei der Feier hat
## seinen eigenen Auftakt), dann losstreifen.
func _start_activity(spawn: Vector3, with_signal: bool = true) -> void:
	attacks += 1
	phase = Phase.ACTIVE
	var sated := satiation > SATED_ROAM
	_choose_intent(sated)
	_phase_left = _day_lerp(ACTIVE_TIME) * randf_range(0.8, 1.2) * minf(2.0, 1.0 + 0.2 * maxi(0, victims_left - 1))
	if with_signal:
		shown_victims = victims_left
		if not is_harmless() and victims_left > 0 and randf() < DECEIVE_CHANCE * effective_boldness() / 100.0:
			shown_victims = 0   # es täuscht: nur ein Zucken
		_start_wave(spawn_points[0], shown_victims, false, SIGNAL_TIME_SATED if sated else -1.0)
	if Game.tracing:
		var why := "erzwungen" if debug_victims >= 0 else ("satt" if sated else "Chance %.0f %%" % (attack_chance() * 100.0))
		print("[Aufbruch] %d. Angriff%s · Tag %.1f, %s → %s (%d Opfer) · Flackern zeigt %s" % [attacks,
			" (harmlos)" if is_harmless() else "", Calendar.FIRST_DAY + elapsed / Calendar.DAY_SECONDS, why,
			INTENT_NAMES[intent], victims_left, str(shown_victims) if with_signal else "-"])
	_monster.start_roaming(spawn)


## Absicht (4.17): satt → nur umsehen; sonst greift es mit attack_chance() an, dann n Opfer ∝ 1/n².
## Vom UV-Licht vertrieben kommt es wütend zurück: mindestens zwei.
func _choose_intent(sated: bool) -> void:
	if debug_victims >= 0:
		victims_left = debug_victims
	elif sated or randf() >= attack_chance():
		victims_left = 0
	else:
		victims_left = _draw_victims()
		if _uv_angry:
			victims_left = maxi(victims_left, mini(2, _max_victims()))
	_uv_angry = false
	intent = _intent_for(victims_left)


## Chance, dass es bei einem Aufbruch jetzt angreift – steigt gleitend von Tag zu Tag (4.17).
func attack_chance() -> float:
	var day := Calendar.FIRST_DAY + elapsed / Calendar.DAY_SECONDS
	var prev: Vector2 = ATTACK_CHANCE[0]
	if day <= prev.x:
		return prev.y
	for point: Vector2 in ATTACK_CHANCE:
		if day <= point.x:
			return lerpf(prev.y, point.y, (day - prev.x) / (point.x - prev.x))
		prev = point
	return prev.y


## Opferzahl n mit Wahrscheinlichkeit ∝ 1/n².
func _draw_victims() -> int:
	var top := _max_victims()
	var total := 0.0
	for n in range(1, top + 1):
		total += 1.0 / (n * n)
	var r := randf() * total
	for n in range(1, top + 1):
		r -= 1.0 / (n * n)
		if r <= 0.0:
			return n
	return top


## Mehr als alle Lebenden und den Spieler kann es nicht holen.
func _max_victims() -> int:
	var alive := 0
	if Game.social:
		for guest in Game.social.guests:
			if not guest.dead and not guest.is_child():   # Kinder holt es nie (6.13)
				alive += 1
	return alive + 1


func _intent_for(victims: int) -> Intent:
	return Intent.ROAM if victims <= 0 else (Intent.ONE if victims == 1 else Intent.RAMPAGE)


## Umsehen wird zum Angriff (Sichtung, Gerede): Die Lichter flackern noch einmal – vom Monster aus.
func _escalate(chance: float) -> void:
	if not _monster.is_active() or victims_left > 0 or is_harmless() or satiation > SATED_ROAM or randf() >= chance:
		return
	victims_left = 1
	intent = Intent.ONE
	shown_victims = 1
	_start_wave(_monster.global_position, 1)


# --- Flackerwelle (4.17) ---------------------------------------------------------------------

## Welle, die `victims` Opfer anzeigt: Sekunden = 1 + 2 × n (duration > 0 überschreibt das).
## fake = Halluzination: Lampen flackern, aber kein Gast reagiert.
func _start_wave(origin: Vector3, victims: int, fake: bool = false, duration: float = -1.0) -> void:
	if duration <= 0.0:
		duration = SIGNAL_BASE + SIGNAL_PER_VICTIM * victims
	_wave_origin = origin
	_wave_start = elapsed
	_wave_time = duration * randf_range(1.0 - SIGNAL_JITTER, 1.0 + SIGNAL_JITTER)
	_wave_level = mini(victims, 2)
	_wave_strength = SIGNAL_STRENGTH[_wave_level]
	_wave_told = false
	if fake or Game.social == null:
		return
	for guest in Game.social.guests:
		guest.on_flicker_signal(_wave_level, wave_delay(guest.global_position))


## Sekunden, bis die Welle diesen Ort erreicht: vom Ausgangspunkt übers Stockwerk, in die anderen Stockwerke
## (vom Heizkeller hinauf, Spielkonzept 7.9) über das Treppenhaus.
func wave_delay(p: Vector3) -> float:
	var o := _wave_origin
	var d: float
	if absf(p.y - o.y) > LevelBuilder.UP_Y / 2.0:
		d = _flat(o, _stairwell) + absf(p.y - o.y) + _flat(_stairwell, p)
	else:
		d = _flat(o, p) + absf(p.y - o.y)
	return d / WAVE_SPEED


func _flat(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()


## Flackerstärke der Welle an diesem Ort (0 = vorbei oder noch nicht da).
func wave_at(p: Vector3) -> float:
	var t := elapsed - _wave_start - wave_delay(p)
	if t < 0.0 or t > _wave_time:
		return 0.0
	return _wave_strength


## Läuft gerade irgendwo eine Flackerwelle? (Tagebuch gesperrt, 8.5)
func is_signalling() -> bool:
	return elapsed - _wave_start < _wave_time + 8.0


## Langes Flackern an diesem Ort (gerade oder vor Kurzem) – bricht Partien ab (6.10).
func long_signal_near(p: Vector3) -> bool:
	return _wave_level >= 2 and elapsed - _wave_start < _wave_time + wave_delay(p) + 2.0


## Will es in dieser Aktivphase (noch) jemanden holen?
func wants_victim() -> bool:
	return not is_harmless() and victims_left > 0


func _update_schedule(delta: float) -> void:
	_phase_left -= delta
	match phase:
		Phase.ACTIVE:
			if not _monster.is_active():
				on_monster_gone()
			elif _phase_left <= 0.0 and _monster.state != Monster.State.CHASE:
				_monster.go_home()
		_:
			if _phase_left <= 0.0:
				if other_threat_active(_monster):
					_phase_left = 10.0   # Lakengeist oder Kürbismann ist im Haus – es wartet
				else:
					_start_activity(spawn_points[0])


## Wert zwischen Anfang (1. Oktober) und Halloween.
func _day_lerp(range_value: Vector2) -> float:
	var t := clampf((Calendar.today() - 1) / float(Calendar.HALLOWEEN - 1), 0.0, 1.0)
	return lerpf(range_value.x, range_value.y, t)


## Das Monster ist zurück im Keller → Ruhephase (satt: länger).
func on_monster_gone() -> void:
	phase = Phase.CALM
	_phase_left = _day_lerp(REST_TIME) * randf_range(0.8, 1.2) + satiation * 3.0
	if _uv_driven:
		_phase_left *= UV_REST_FACTOR
		_uv_driven = false


## Debug (F7, --lure): Das Monster kommt zum Spieler, als hätte es dort etwas gehört. Ruht es, erscheint
## es ~25 m entfernt auf dem NavMesh; ist es unterwegs, nimmt es diesen Weg statt seines Ziels.
func debug_lure() -> void:
	var target := Game.player.global_position
	if not _monster.is_active():
		var map := _monster.get_world_3d().navigation_map
		var start := target
		for i in 12:
			var dir := Vector3.FORWARD.rotated(Vector3.UP, TAU * i / 12.0 + randf() * 0.5)
			var p := NavigationServer3D.map_get_closest_point(map, target + dir * LURE_DISTANCE)
			if absf(p.distance_to(target) - LURE_DISTANCE) < 8.0:
				start = p
				break
		_monster.spawn_at(start)
	_monster.investigate(target)


## Debug (F5, --warn): sofort losschicken.
func start_warning() -> void:
	first_attack_done = true
	if not _monster.is_active():
		_start_activity(spawn_points[0])


# --- Ereignisse -------------------------------------------------------------------------

## Lärm (Spielkonzept 4.15, über `Game.noise`): Innerhalb der gedämpften Hörweite geht das
## Monster nachsehen, bis zur doppelten Hörweite steigt nur die Neugier dort. Ruht es,
## zählt nur Lautes. Gibt zurück, was es gehört hat (für --trace und F3), sonst "".
func on_noise(pos: Vector3, loudness: float, source: Node = null) -> String:
	if source == _monster or source is HotelCat:   # Katzen überhört es – es mag sie (6.11)
		return ""
	if Game.weather:
		loudness *= Game.weather.masking()   # gleich nach einem Donner hört es schlechter (7.8)
	var curiosity := loudness * NOISE_CURIOSITY
	if not _monster.is_active():
		if loudness >= Senses.LOUD:
			add_curiosity(pos, curiosity)
			return "Monster ruht: Neugier +%.0f" % curiosity
		return ""
	var ear := _monster.global_position + Vector3.UP * 1.5
	var d := ear.distance_to(pos)
	if d > 2.0 * loudness:
		return ""
	var heard := Senses.audible_range(_monster.get_world_3d(), pos, ear, loudness, d / 2.0)
	if d <= heard:
		add_curiosity(pos, curiosity)
		_monster.investigate(pos)
		return "Monster d=%.1f/%.1f m nachsehen" % [d, heard]
	if d <= 2.0 * heard:
		add_curiosity(pos, curiosity)
		return "Monster d=%.1f/%.1f m Neugier" % [d, heard]
	return ""


## Jemand (Spieler oder Gast) ist in ein Versteck gegangen. Hat das Monster es gesehen?
## Dieselbe Rechnung wie beim Jagen (4.15) – gesehen wird nur das Hineingehen.
func on_actor_hid(spot: HideSpot, actor: Node3D) -> void:
	if not _monster.is_active() or _monster.state in [Monster.State.KILL, Monster.State.REVEAL] \
			or (actor is Guest and (actor as Guest).is_child()):
		return
	if _monster.can_see_actor(actor, spot.exit_point.global_position):
		spot.seen_entering = true
		_monster.go_check(spot)


func on_monster_noticed() -> void:
	boldness = minf(100.0, boldness + 8.0)
	add_curiosity(player_door_front, 40.0)
	Game.play_sound("sting", 1.0)
	_monster.stare()
	_escalate(ESCALATE_ON_SIGHT)


## Jemand redet über das Monster – es hört mit und wird dreister (Spielkonzept 4.7).
func on_monster_talk(pos: Vector3) -> void:
	boldness = minf(100.0, boldness + 3.0)
	add_curiosity(pos, 10.0)
	_escalate(ESCALATE_ON_TALK)


## Licht ausgeschaltet, Birne herausgedreht oder durchgebrannt: Dunkelheit lockt es an.
func on_lights_off(pos: Vector3) -> void:
	add_curiosity(pos, LIGHTS_OFF_CURIOSITY)
	if _monster.is_active() and _monster.global_position.distance_to(pos) < 20.0:
		_monster.investigate(pos)


## So lange muss das Monster im UV-Kegel stehen, bis es flieht.
func uv_repel_time() -> float:
	return minf(UV_REPEL_MAX, UV_REPEL_TIME + UV_HABITUATION * uv_count)


## UV-Licht hat es vertrieben (Spielkonzept 4.16): Es flieht in den Keller und ruht nur kurz.
## Dafür weiß es, wer es war – dreister, Neugier rund um Zimmer 13, und es gewöhnt sich daran.
func on_monster_uv() -> void:
	uv_count += 1
	boldness = minf(100.0, boldness + UV_BOLDNESS)
	add_curiosity(player_door_front, UV_CURIOSITY)
	_uv_driven = true
	_uv_angry = true
	_monster.uv_repel()


## Hat das Monster einen Gast geholt, ist es eine Weile satt.
func on_guest_taken() -> void:
	satiation = 40.0


func kill_guest(guest, spot: HideSpot) -> void:
	if guest == null or not is_instance_valid(guest) or guest.dead or guest.is_child():
		return
	if not wants_victim():   # harmlos, oder es sieht sich nur um (4.17)
		_scare_guest(guest, spot)
		return
	if Wounds.survives():
		# Er reißt sich los, als es ihn wegschleppen will (Spielkonzept 6.17): nur Kratzer – es bleibt hungrig
		if Game.tracing:
			print("[Losgerissen] %s" % guest.display_name)
		if spot != null:
			spot.rip_open()
		Game.noise("scream", guest.global_position, guest)
		guest.wound_by("scratch", _monster)
		guest.scared_by_monster()
		_monster.after_scare(guest)
		return
	if spot != null:
		spot.rip_open()
	Game.noise("death_scream", guest.global_position, guest)
	var where: Vector3 = guest.global_position
	guest.die()
	if Game.traces:
		Game.traces.add_blood(where, _monster.rotation.y)
		Game.traces.add_wall_blood(where, "wall_splatter")
	# Ein Kleidungsstück bleibt zurück – Andeutung statt Gore
	var cloth := Item.create(Item.Kind.CLOTHING, guest.id)
	_monster.get_parent().add_child(cloth)
	cloth.global_position = Vector3(where.x + 0.4, 0.05, where.z + 0.2)
	grief = GRIEF_TIME
	victims_left -= 1
	if Game.tracing:
		print("[Geholt] %s · noch %d Opfer" % [guest.display_name, victims_left])
	if victims_left > 0:   # Raubzug: weiter zum nächsten Opfer
		_monster.after_kill_hunting()
	else:
		on_guest_taken()
		_monster.after_feeding()
	if Game.social:
		Game.social.on_guest_died(guest)


## Harmloser Angriff auf einen Gast: Er wird zu Tode erschreckt – aber nicht geholt.
func _scare_guest(guest, spot: HideSpot) -> void:
	if Game.tracing:
		print("[Erschreckt] %s (%s)" % [guest.display_name, "harmlos" if is_harmless() else "umsehen"])
	if spot != null:
		spot.rip_open()
	Game.noise("scream", guest.global_position, guest)
	guest.scared_by_monster()
	_monster.after_scare(guest)


func kill_player(spot: HideSpot) -> void:
	if Game.game_over:
		return
	if not wants_victim():
		_reveal_to_player(spot)
		return
	Game.game_over = true
	var player := Game.player
	player.dead = true
	if Game.hud:
		Game.hud.set_prompt("")
	if spot != null:
		spot.rip_open()
		await get_tree().create_timer(0.2, false).timeout
	if Game.hud:
		Game.hud.visible = false
	_monster.play_jumpscare(player.camera)
	_jumpscare = 1.4
	Game.play_sound("shriek", 1.0)
	await get_tree().create_timer(1.5, false).timeout
	Game.player_died.emit()


## Rotes Aufblitzen mit Rauschen wie beim Jumpscare (auch für den Lakengeist).
func flash(seconds: float) -> void:
	_jumpscare = seconds


## Kürbismann oder Lakengeist hat den Spieler getötet (das Monster hat seinen Jumpscare, kill_player): Spiel aus,
## HUD weg, Schrei und rotes Aufblitzen, nach 1,5 s der Sterbebildschirm.
func player_slain() -> void:
	Game.game_over = true
	Game.player.dead = true
	if Game.hud:
		Game.hud.set_prompt("")
		Game.hud.visible = false
	Game.play_sound("shriek", 1.0)
	flash(1.4)
	await get_tree().create_timer(1.5, false).timeout
	Game.player_died.emit()


## Kürbismann oder Lakengeist hat einen Gast getötet: ein letztes Ächzen (kein Schrei), die Leiche bleibt liegen,
## das Hotel erfährt es (Spielkonzept 4.19, 6.12).
func guest_slain(guest: Guest, cause: String) -> void:
	Game.sound_at("grunt", guest.global_position, Senses.GRUNT_RANGE, guest)
	guest.die(cause)
	if Game.social:
		Game.social.on_guest_died(guest, cause)


## Harmloser Angriff auf den Spieler: Es steht direkt vor dir, starrt dich an – und ist
## im nächsten Flackern verschwunden. Jetzt weißt du, dass es real ist. Die Aktivphase läuft weiter: Es streift
## außer Sicht umher und lässt dich bis zur nächsten in Ruhe (Spielkonzept 4.13).
func _reveal_to_player(spot: HideSpot) -> void:
	var player := Game.player
	if spot != null:
		spot.rip_open()
		player.exit_hide()
	_monster.reveal(player.camera)
	Game.play_sound("sting", 1.0)
	_jumpscare = 0.6
	await get_tree().create_timer(1.8, false).timeout
	_jumpscare = 1.0
	Game.play_sound("bang", 0.5)
	await get_tree().create_timer(0.15, false).timeout
	_monster.vanish_after_reveal(player)


# --- Unheimliche Kleinigkeiten ---------------------------------------------------------------

## Gerade eine Halluzination (Rauschen ohne Monster)? Auch der Kompass spielt dann verrückt.
func is_hallucinating() -> bool:
	return _hallucination > 0.0


## Halluzination nach einem Todesfall, unter Schock oder betrunken (3.7): Rauschen ohne Monster.
func _update_hallucination(delta: float) -> void:
	if _hallucination > 0.0:
		_hallucination -= delta
		return
	var p := Game.player
	if p == null or p.dead:
		return
	var drunk := p.drunk >= BarTap.DRUNK
	if (grief > 0.0 or p.shock > 0.15 or drunk) and randf() < delta / HALLUCINATION_EVERY * (1.0 + (p.drunk if drunk else 0.0)):
		_hallucination = randf_range(6.0, 11.0)
		if not _monster.is_active() and randf() < FAKE_SIGNAL_CHANCE:   # langes Flackern – und nichts kommt
			_start_wave(spawn_points[0], FAKE_SIGNAL_VICTIMS, true)


## Das Hotel verändert sich, wenn niemand hinsieht (Spielkonzept 4.13).
func _update_haunting(delta: float) -> void:
	_haunt_timer -= delta
	if _haunt_timer > 0.0:
		return
	_haunt_timer = randf_range(HAUNT_INTERVAL.x, HAUNT_INTERVAL.y)
	var p := Game.player
	if p == null or p.dead:
		return
	var away_from_room := p.global_position.distance_to(player_door_front) > 12.0
	var actions: Array[Callable] = [_haunt_door, _haunt_curtain, _haunt_light, _haunt_bed]
	if randf() < WALL_SMEAR_CHANCE and _wall_smears() < MAX_WALL_SMEARS:
		actions.append(_haunt_wall_blood)
	if away_from_room:
		actions.append(_haunt_room_13)
	actions.shuffle()
	for action in actions:
		if action.call():
			return


func _unseen(pos: Vector3, min_dist: float = 8.0) -> bool:
	var p := Game.player
	return p.global_position.distance_to(pos) > min_dist and not player_can_see(pos)


func _haunt_door() -> bool:
	var doors := get_tree().get_nodes_in_group("doors")
	doors.shuffle()
	for node in doors:
		var door := node as Door
		if not door.is_open and not door.locked and door.monster_can_open and _unseen(door.center()):
			door.set_open(true, false, true)
			return true
	return false


func _haunt_curtain() -> bool:
	var windows := get_tree().get_nodes_in_group("windows")
	windows.shuffle()
	for node in windows:
		var win := node as HotelWindow
		if win.has_curtains() and not win.closed and _unseen(win.global_position):
			win.set_closed(true, true)
			return true
	return false


func _haunt_light() -> bool:
	var switches := get_tree().get_nodes_in_group("light_switches")
	switches.shuffle()
	var player_zone := zone_name_at(Game.player.global_position)
	for node in switches:
		var sw := node as LightSwitch
		if sw.on and sw.room_label != player_zone and _unseen(sw.global_position, 12.0):
			sw.set_on(false)
			return true
	return false


## Eine blutige Hand rutscht an einer Flurwand hinunter – wo der Spieler gerade nicht hinsieht (4.13).
func _haunt_wall_blood() -> bool:
	var points := patrol.duplicate()
	points.shuffle()
	for entry in points:
		var pos: Vector3 = entry["pos"]
		if Game.social.builder.in_corridor(pos) and _unseen(pos + Vector3.UP * 1.4, 10.0) \
				and Game.traces.add_wall_blood(pos, "wall_smear") != null:
			return true
	return false


## So viele Schmierspuren hängen schon (gezählt an den Spuren selbst – so stimmt es auch nach dem Laden).
func _wall_smears() -> int:
	return get_tree().get_nodes_in_group("trace_marks").filter(func(m: Node) -> bool:
		return (m as TraceMark).kind == "wall_smear").size()


func _haunt_bed() -> bool:
	var spots := get_tree().get_nodes_in_group("hide_spots")
	spots.shuffle()
	for node in spots:
		var spot := node as HideSpot
		if spot.type == HideSpot.Type.BED and not spot.checked and spot.occupant == null and _unseen(spot.global_position):
			spot.set_checked(true)
			return true
	return false


## Zimmer 13 bleibt nicht unberührt: Bett zerwühlt, Vorhang zu, eine fremde Zeile im Tagebuch.
func _haunt_room_13() -> bool:
	var info: Dictionary = rooms.get(LevelBuilder.PLAYER_ROOM, {})
	if info.is_empty():
		return false
	match randi() % 3:
		0:
			for spot in info["spots"]:
				var hs: HideSpot = spot
				if hs.type == HideSpot.Type.BED and not hs.checked:
					hs.set_checked(true)
					return true
		1:
			for node in get_tree().get_nodes_in_group("windows"):
				var win := node as HotelWindow
				if win.room_id == LevelBuilder.PLAYER_ROOM and win.has_curtains() and not win.closed:
					win.set_closed(true, true)
					return true
		_:
			if not strange_diary:
				strange_diary = true
				return true
	return false


# --- Ziele ----------------------------------------------------------------------------------

## Nächstes Ziel beim Umherstreifen: irgendwo im Hotel, gewichtet nach Druck (Dunkelheit,
## Neugier, wenig Deko). Lieber Orte, die der Spieler gerade nicht sieht.
func next_roam_target(from: Vector3) -> Dictionary:
	var candidates: Array[Dictionary] = []
	var weights: Array[float] = []
	var current := zone_name_at(from)
	for zone in zones:
		var zone_name: String = zone["name"]
		if zone_name == current:
			continue
		var target := {"pos": zone["center"] as Vector3, "room": ""}
		if zone_name.begins_with("Zimmer "):
			var no := zone_name.substr(7)
			if rooms.has(no):
				target = {"pos": (rooms[no] as Dictionary)["door_front"] as Vector3, "room": no}
		var pos: Vector3 = target["pos"]
		if not _roam_zones.has(pos):   # die Ziele liegen fest – ihre Zone auch
			_roam_zones[pos] = _zone_at(pos)
		var w := pow(maxf(_pressure_in(_roam_zones[pos]), 1.0), 2.0)
		if Game.player and player_can_see(pos + Vector3.UP * 1.2) and pos.distance_to(Game.player.global_position) < 15.0:
			w *= 0.15
		candidates.append(target)
		weights.append(w)
	var total := 0.0
	for w in weights:
		total += w
	var r := randf() * total
	for i in candidates.size():
		r -= weights[i]
		if r <= 0.0:
			return candidates[i]
	return candidates[0] if not candidates.is_empty() else {"pos": spawn_points[0], "room": ""}


## Ein Wegpunkt in der Nähe, den der Spieler gerade nicht sieht (zum Verschwinden).
func hidden_point_near(from: Vector3) -> Vector3:
	var best := from
	var best_dist := INF
	for entry in patrol:
		var pos: Vector3 = entry["pos"]
		var d := pos.distance_to(from)
		if d < 2.0 or d > 14.0 or player_can_see(pos + Vector3.UP * 1.2):
			continue
		if Game.player and pos.distance_to(Game.player.global_position) < from.distance_to(Game.player.global_position):
			continue   # nicht auf den Spieler zu
		if d < best_dist:
			best_dist = d
			best = pos
	return best


## Biegt das Monster an dieser Tür ins Zimmer ab? Neugier × Dreistigkeit, mit Zufall.
func wants_to_enter_room(no: String) -> bool:
	if not rooms.has(no):
		return false
	var info: Dictionary = rooms[no]
	var door: Door = info["door"]
	if door.locked and effective_boldness() < 50.0:
		return false
	var chance := clampf(curiosity_at(info["center"]) / 100.0, 0.1, 0.9) * (0.4 + effective_boldness() / 120.0)
	return randf() < chance


func room_search_points(no: String) -> Array[Dictionary]:
	var info: Dictionary = rooms[no]
	var points: Array[Dictionary] = [
		{"pos": info["door_inside"], "spot": null},
		{"pos": info["center"], "spot": null},
	]
	for spot in info["spots"]:
		var hide_spot: HideSpot = spot
		points.append({"pos": hide_spot.check_point.global_position, "spot": hide_spot})
	return points


## Rückzugsort: der Keller.
func retreat_point() -> Vector3:
	return spawn_points[0]


func search_points_near(center: Vector3) -> Array[Dictionary]:
	var points: Array[Dictionary] = [{"pos": center, "spot": null}]
	var spots: Array[HideSpot] = []
	for node in get_tree().get_nodes_in_group("hide_spots"):
		var spot := node as HideSpot
		if spot.check_point.global_position.distance_to(center) < 7.0:
			spots.append(spot)
	spots.sort_custom(func(a: HideSpot, b: HideSpot) -> bool:
		return a.global_position.distance_to(center) < b.global_position.distance_to(center))
	for spot in spots:
		points.append({"pos": spot.check_point.global_position, "spot": spot})
	return points


func player_can_see(p: Vector3) -> bool:
	var cam := Game.player.camera
	return cam.is_position_in_frustum(p) and Senses.clear_line(_monster.get_world_3d(), cam.global_position, p)


## Unruhe hängender Deko an p (0..1, Spielkonzept 5.6): Monster bis DECO_UNREST_RANGE (wirkt durch Wände),
## die Flackerwelle beim Aufbruch und der Lakengeist bis DECO_UNREST_GHOST.
func deco_unrest_at(p: Vector3) -> float:
	var unrest := 0.0
	if _monster.is_active() and _monster.state != Monster.State.KILL:
		var d := _monster.global_position.distance_to(p)
		unrest = clampf((DECO_UNREST_RANGE - d) / (DECO_UNREST_RANGE - 3.0), 0.0, 1.0)
	if is_signalling():
		unrest = maxf(unrest, wave_at(p) * 0.6)
	if Game.ghost and Game.ghost.is_active():
		var g := Game.ghost.global_position.distance_to(p)
		unrest = maxf(unrest, clampf(1.0 - g / DECO_UNREST_GHOST, 0.0, 1.0) * 0.75)
	return unrest


## Woher die Unruhe an p kommt: das nähere von Monster und Lakengeist (aktiv) – sonst Vector3.INF.
func deco_unrest_source(p: Vector3) -> Vector3:
	var best := Vector3.INF
	if _monster.is_active() and _monster.state != Monster.State.KILL:
		best = _monster.global_position
	if Game.ghost and Game.ghost.is_active() and (best == Vector3.INF \
			or Game.ghost.global_position.distance_to(p) < best.distance_to(p)):
		best = Game.ghost.global_position
	return best


## Bedrohung 0..1 nach Entfernung zum Monster (für Spieler und Gäste) – wirkt durch Wände.
func threat_at(pos: Vector3) -> float:
	if not _monster.is_active() or _monster.state == Monster.State.KILL:
		return 0.0
	var d := _monster.global_position.distance_to(pos)
	return clampf((NOISE_START - d) / (NOISE_START - NOISE_FULL), 0.0, 1.0)


# --- Speichern ------------------------------------------------------------------------------

func save_state() -> Dictionary:
	return {
		"first_attack_done": first_attack_done, "first_attack_day": first_attack_day, "attacks": attacks,
		"grief": grief, "strange_diary": strange_diary, "phase": int(phase), "phase_left": _phase_left,
		"haunt_timer": _haunt_timer, "uv_count": uv_count, "monster_active": _monster.is_active(),
		"victims_left": victims_left, "uv_angry": _uv_angry,
		"monster_pos": [_monster.global_position.x, _monster.global_position.y, _monster.global_position.z],
	}


func load_state(d: Dictionary) -> void:
	first_attack_done = bool(d.get("first_attack_done", false))
	first_attack_day = int(d.get("first_attack_day", first_attack_day))
	attacks = int(d.get("attacks", 0))
	grief = float(d.get("grief", 0.0))
	strange_diary = bool(d.get("strange_diary", false))
	_phase_left = float(d.get("phase_left", 60.0))
	_haunt_timer = float(d.get("haunt_timer", 120.0))
	uv_count = int(d.get("uv_count", 0))
	victims_left = int(d.get("victims_left", 1))
	intent = _intent_for(victims_left)
	_uv_angry = bool(d.get("uv_angry", false))
	phase = Phase.CALM
	if bool(d.get("monster_active", false)):
		var mp: Array = d.get("monster_pos", [32.8, 0.05, 0.2])
		phase = Phase.ACTIVE
		_monster.start_roaming(Vector3(float(mp[0]), float(mp[1]), float(mp[2])))


# --- Effekte (Rauschen, Flackern, Lampen, Ton) --------------------------------------

func _update_effects(delta: float) -> void:
	var noise_target := 0.0
	var flicker_target := 0.0
	var hum_target := 0.0
	var heart_target := 0.0
	var player := Game.player
	player_threat = threat_at(player.global_position) if player else 0.0
	if player_threat > 0.0:
		var k := pow(player_threat, 1.4)
		noise_target = 0.45 * k
		flicker_target = 0.6 * k
		hum_target = 0.1 + 0.35 * player_threat
		heart_target = player_threat * 0.7
		if _monster.state == Monster.State.CHASE:
			noise_target += 0.15
			heart_target = 0.9
	if _hallucination > 0.0:
		var h := sin(clampf(_hallucination / 8.0, 0.0, 1.0) * PI)
		noise_target = maxf(noise_target, 0.3 * h)
		hum_target = maxf(hum_target, 0.25 * h)
	if player:
		noise_target += player.hide_stress * 0.3
		heart_target = maxf(heart_target, player.hide_stress)
		if player.shock > 0.1:
			noise_target += player.shock * 0.08
			heart_target = maxf(heart_target, player.shock * 0.5)
		# Außer Atem vom Rennen: Herz und Keuchen (Ausdauer, Spielkonzept 3.1)
		heart_target = maxf(heart_target, player.exertion() * 0.85)
	# Flackerwelle beim Spieler: Bildflackern, Sirren im Stromnetz, Untertitel (Barrierefreiheit)
	var wave := wave_at(player.global_position + Vector3.UP) if player else 0.0
	if wave > 0.0:
		flicker_target = maxf(flicker_target, wave * 0.9)
		if not _wave_told:
			_wave_told = true
			if Game.tracing:
				var lit := get_tree().get_nodes_in_group("lamps").filter(func(l: Node) -> bool: return (l as FlickerLight).wave > 0.0).size()
				print("[Flackerwelle] beim Spieler nach %.1f s, %.1f s lang · %d Lampen flackern gerade" % [elapsed - _wave_start, _wave_time, lit])
			Game.caption(["[Die Lichter zucken kurz]", "[Die Lichter flackern]", "[Die Lichter flackern lange]"][_wave_level])
	if _jumpscare > 0.0:
		_jumpscare -= delta
		noise_target = 0.45
		flicker_target = 0.5
	_noise = move_toward(_noise, noise_target, delta * (3.0 if _jumpscare > 0.0 else 0.5))
	_pulse = maxf(0.0, _pulse - delta * 6.0)
	if randf() < flicker_target * delta * 2.0:
		_pulse = randf_range(0.3, 0.9)
	# Konzentriert beim Spielen fällt die Ankündigung weniger auf (Spielkonzept 6.10)
	var focus := 0.45 if player and player.focused and _jumpscare <= 0.0 else 1.0
	focus *= Settings.flicker_intensity   # Barrierefreiheit: weniger Flackern und Rauschen
	if post_material:
		post_material.set_shader_parameter("noise_amount", _noise * focus)
		post_material.set_shader_parameter("flicker", _pulse * 0.6 * focus)
		post_material.set_shader_parameter("red_tint", 0.12 if _jumpscare > 0.0 else 0.0)
	# Lampen flackern in der Nähe des Monsters – und wenn die Flackerwelle vorbeizieht
	var active := _monster.is_active()
	var mpos := _monster.global_position
	var signalling := is_signalling()
	for node in get_tree().get_nodes_in_group("lamps"):
		var lamp := node as FlickerLight
		lamp.flicker = clampf(1.0 - lamp.global_position.distance_to(mpos) / LAMP_FLICKER_RANGE, 0.0, 1.0) * 0.9 if active else 0.0
		lamp.wave = wave_at(lamp.global_position) if signalling else 0.0
	if Game.audio:
		Game.audio.hum = move_toward(Game.audio.hum, hum_target, delta * 0.3)
		Game.audio.static_noise = _noise * 0.3
		Game.audio.heart = move_toward(Game.audio.heart, heart_target, delta * 0.5)
		Game.audio.heart_bpm = 70.0 + heart_target * 60.0
		Game.audio.buzz = move_toward(Game.audio.buzz, wave * 0.5, delta * 4.0)
		# Beim Luftanhalten verstummt das Keuchen; je erschöpfter, desto schneller die Atemzüge
		var pant_target := 0.0
		if player and not player.holding_breath and not player.dead:
			pant_target = player.exertion()
		Game.audio.pant = move_toward(Game.audio.pant, pant_target, delta * (3.0 if pant_target < Game.audio.pant else 0.8))
		Game.audio.pant_rate = 0.35 + 0.5 * Game.audio.pant


func debug_text() -> String:
	var s := "%s · Phase %s (%ds) · Angriff %d%s\n" % [Calendar.date_text(elapsed), Phase.keys()[phase], int(_phase_left),
		attacks, " harmlos" if is_harmless() else ""]
	s += "Dreistigkeit %.1f (effektiv %.1f) · Bedrohung %.2f\n" % [boldness, effective_boldness(), player_threat]
	s += "UV vertrieben: %d× (nötig %.1f s)\n" % [uv_count, uv_repel_time()]
	s += "Absicht: %s (noch %d Opfer) · Flackern zeigte %d · Angriffschance %.0f %%\n" % [INTENT_NAMES[intent], victims_left, shown_victims, attack_chance() * 100.0]
	s += "Monster: %s\n" % Monster.State.keys()[_monster.state]
	if Game.player:
		s += "Licht beim Spieler: %.2f · Ausdauer %.2f%s\n" % [light_at(Game.player.global_position + Vector3.UP),
			Game.player.stamina, " außer Atem" if Game.player.winded else ""]
	s += "Zone        Neugier Druck Abschr.\n"
	for zone in zones:
		var c: Vector3 = zone["center"]
		s += "%-11s %5.0f %5.1f %5.1f\n" % [zone["name"], zone["curiosity"], pressure_at(c), deterrence_at(c)]
	if not Game.noise_log.is_empty():
		s += "Lärm:\n  " + "\n  ".join(Game.noise_log) + "\n"
	s += "F5 = Monster losschicken"
	return s
