class_name MonsterDirector
extends Node
## Steuert das Monster über versteckte Werte (Spielkonzept 4.9):
##   Dreistigkeit (global) · Neugier (pro Zone) · Abschreckung (Deko × Licht / Anspruch)
##   Druck(Ort) = Dreistigkeit × (0,5 + 0,5 × Neugier/100)
##   Druck > Abschreckung → das Monster kommt durch.
##
## Dramaturgie (Spielkonzept 2.1, 4.13):
##   · Friedlicher Anfang – bis zum ersten Angriff kein Monster; den löst die Siegerehrung des Türschmuck-Wettbewerbs
##     am Abend des 2. Oktober aus (DoorContest, 2.5).
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
const BOLDNESS_PER_DAY := 12.0         ## nach dem ersten Angriff, je Spieltag (2.4)
## Anspruch an Deko (Spielkonzept 5.10): ×1 am DEMAND_FROM_DAY, gleitend bis ×DEMAND_MAX an Halloween, dann gedeckelt
const DEMAND_FROM_DAY := 2.0
const DEMAND_MAX := 3.0
## Haushalte (Spielkonzept 6.20): Je weiterem Erwachsenen hinter einer Zimmertür wächst ihr Anspruch um diesen Anteil
## (mehr Leute bringen mehr Deko, sind aber auch mehr Beute) – gilt bis DOOR_DEMAND_RANGE vor der Tür
const HOUSEHOLD_DEMAND := 0.35
const DOOR_DEMAND_RANGE := 1.6
const DECO_RADIUS := 3.0
## Füllmaterial (Item.is_filler: Laub, Spinnweben, Kerzen, Zierkürbisse, kleine Sorten) zählt an einer Stelle
## zusammen höchstens so viel – ein Grundschutz, der ab Monatsmitte nie allein reicht (5.10)
const FILLER_CAP := 20.0
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
## Den ersten Angriff löst die Siegerehrung des Türschmuck-Wettbewerbs aus (DoorContest, Spielkonzept 2.5)
## So viele Aufbrüche holt es niemanden – etwa anderthalb Spieltage (früher zwei Aufbrüche bei 5-Minuten-Tagen)
const HARMLESS_ATTACKS := 9
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
## Wahrscheinlichkeit ∝ 1/n² (≈ 61 % eins, 15 % zwei, 7 % drei …), höchstens alle Lebenden + Spieler.
## Seit der Tagesuhr (2.4) bricht es etwa sechsmal am Tag auf statt gut einmal – die Chancen sind deshalb ein
## Fünftel der früheren (20/50/75/90/95 %), damit es je Tag etwa gleich oft angreift; die übrigen Aufbrüche sind Umsehen
const ATTACK_CHANCE := [Vector2(4, 0.04), Vector2(7, 0.1), Vector2(10, 0.16), Vector2(20, 0.19), Vector2(30, 0.2)]
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
## Umsehen wird zum Angriff: bei einer Sichtung / wenn es Gerede hört (mit dieser Chance; Gerede seit der Tagesuhr
## ein Fünftel, weil es fünfmal so oft je Tag unterwegs ist, 2.4)
const ESCALATE_ON_SIGHT := 0.5
const ESCALATE_ON_TALK := 0.03
## Halluzination: so oft kommt mit dem Rauschen eine lange Flackerwelle ohne Monster (zeigt so viele Opfer)
const FAKE_SIGNAL_CHANCE := 0.35
const FAKE_SIGNAL_VICTIMS := 3
## Die Puppe (Spielkonzept 5.5): so viele Sekunden vor einem echten Angriff liegt sie vor der schwächsten bewohnten
## Tür (ist die Ruhephase kürzer, wartet das Monster); so oft wird bis zum Aufbruch nachgerechnet (Nachbessern)
const DOLL_LEAD := Vector2(60.0, 120.0)
const DOLL_RECHECK := 3.0
## Gleich wenig Deko bzw. gleich dunkel, wenn sich die Werte höchstens so stark unterscheiden
const DOLL_DECO_TIE := 0.25
const DOLL_LIGHT_TIE := 0.03
## Weg zur Puppentür: unterwegs bis zu so viele schwache bewohnte Türen, deren Flurpunkt höchstens so weit vom Weg liegt
const ROUTE_DOORS := 5
const ROUTE_REACH := 4.0
## Findet es nach so vielen Sekunden über der Aktivzeit nicht ans Ziel, gibt es auf
const RAID_OVERTIME := 300.0
## Grollen (5.5): so leise am Anfang, voll am Ende der Frist; so schnell verklingt es nach dem Aufbruch
const RUMBLE_START := 0.12
const RUMBLE_FADE := 0.4
## So oft wirkt das Grollen auf die Gäste (Social.on_rumble)
const RUMBLE_GUEST_EVERY := 3.0
## Zeitsprung im Schlaf (Spielkonzept 3.6): So lange dauert im Mittel ein Weg zu einem Ziel samt Absuchen – so viele
## Ziele nimmt es sich je Aktivphase vor; mit Wache biegt es so oft doch nicht zu Zimmer 13 ab
const SKIP_LEG := 30.0
const SKIP_GUARD := 0.5

var phase := Phase.CALM
var boldness := BOLDNESS_START
var satiation := 0.0        ## gesättigt, nachdem es einen Gast geholt hat (4.10)
var elapsed := 0.0
var zones: Array[Dictionary] = []
var spawn_points: Array[Vector3] = []
var patrol: Array[Dictionary] = []
var rooms := {}
var _adults := {}             ## Zimmer → Zahl lebender Erwachsener (_adults_per_room, einmal je Sekunde)
var _adults_frame := -1000
var player_door_front := Vector3.ZERO
var post_material: ShaderMaterial
## Dramaturgie
var first_attack_done := false
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
var debug_doom := ""             ## --doll=s,zimmer: die Puppe urteilt immer über dieses Zimmer
## Die Puppe (5.5): Zimmer, vor dessen Tür sie urteilt ("" = kein Urteil); der Weg dorthin (Zimmer der Reihe nach,
## die Puppentür zuletzt) und das Zimmer, das es gerade durchsucht
var doom_room := ""
var raid_room := ""
var _route: Array[String] = []
var _raid_kills := 0
var _raiding := false            ## unterwegs zur Puppentür (Weg geplant, Puppenzimmer noch nicht durchsucht)
var _planned := false           ## Absicht für den nächsten Aufbruch steht schon (Frist der Puppe)
var _lead := 90.0               ## Frist der Puppe vor diesem Aufbruch
var _rumble_total := 0.0        ## so lang war die Frist, als das Grollen begann
var _doll_check := 0.0
var _rumble_told := false
var _rumble_tick := 0.0
var skipping := false            ## Zeitsprung im Schlaf läuft: Zeitplan und Spuk rechnet skip() (SleepSkip)

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


func _physics_process(delta: float) -> void:
	if not Game.game_over:
		if Input.is_action_just_pressed("debug_manifest") and not _monster.is_active():
			start_warning()
		if Input.is_action_just_pressed("debug_lure"):
			debug_lure()
		elapsed += delta
		if first_attack_done:
			boldness = minf(100.0, boldness + BOLDNESS_PER_DAY * delta / Calendar.DAY_SECONDS)
		satiation = maxf(0.0, satiation - 0.1 * delta)
		grief = maxf(0.0, grief - delta)
		_update_zones(delta)
		_zone_timer -= delta
		if _zone_timer <= 0.0:
			_zone_timer = 1.0
			# „Angst riecht“: ein Spieler unter Schock lockt das Monster an
			if Game.player and Game.player.shock > 0.1:
				add_curiosity(Game.player.global_position, Game.player.shock * 3.0)
		if first_attack_done and not skipping:
			_update_schedule(delta)
			_update_haunting(delta)
		_update_hallucination(delta)
	_update_effects(delta)


# --- Versteckte Werte ---------------------------------------------------------------

func effective_boldness() -> float:
	return clampf(boldness - satiation, 0.0, 100.0)


func demand() -> float:
	var t := clampf((Calendar.day_float(elapsed) - DEMAND_FROM_DAY) / (Calendar.HALLOWEEN - DEMAND_FROM_DAY), 0.0, 1.0)
	return lerpf(1.0, DEMAND_MAX, t)


func pressure_at(p: Vector3, chasing: bool = false) -> float:
	return _pressure_in(_zone_at(p), chasing)


func _pressure_in(zone: Dictionary, chasing: bool = false) -> float:
	return effective_boldness() * (0.5 + 0.5 * _curiosity_of(zone) / 100.0) + (CHASE_BONUS if chasing else 0.0)


func deterrence_at(p: Vector3) -> float:
	if _builder and _builder.is_safe(p):
		return INF   # Katzenraum (Spielkonzept 7.7): dort hinein kommt es nie, wer drinsteht, ist geschützt
	var light := light_at(p + Vector3.UP)
	return deco_strength_at(p) * (0.6 + light) / (demand() * _household_factor(p)) \
		+ light * LIGHT_DETERRENCE * (1.0 - effective_boldness() / 120.0)


## Anspruch einer Zimmertür nach ihren Bewohnern (6.20): 1 vor Türen mit einem Erwachsenen und abseits von Türen.
func _household_factor(p: Vector3) -> float:
	var frame := Engine.get_process_frames()
	if frame - _adults_frame > 60:
		_adults_frame = frame
		_adults.clear()
		if Game.social:
			for guest in Game.social.living_guests():
				if not guest.is_child():
					_adults[guest.home["no"]] = int(_adults.get(guest.home["no"], 0)) + 1
	for no in _adults:
		if int(_adults[no]) > 1 and rooms.has(no):
			var front: Vector3 = rooms[no]["door_front"]
			if absf(front.y - p.y) < 1.5 and Vector2(front.x - p.x, front.z - p.z).length() < DOOR_DEMAND_RANGE:
				return 1.0 + HOUSEHOLD_DEMAND * (int(_adults[no]) - 1)
	return 1.0


func is_blocked(p: Vector3, chasing: bool) -> bool:
	if _at_doom(p):
		return false   # die Puppentür fällt immer, auch gut geschmückt (Spielkonzept 5.5)
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
	var filler := 0.0
	for item in decos:
		var d := Vector2(item.global_position.x - p.x, item.global_position.z - p.z).length()
		if d < DECO_RADIUS and absf(item.global_position.y - p.y) < 2.5:   # nur auf demselben Stockwerk
			var value := item.deco_value() * (1.0 - 0.5 * d / DECO_RADIUS)
			if item.is_filler():
				filler += value
			else:
				total += value
	return total + minf(filler, FILLER_CAP)


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
	if Game.nightmare and Game.nightmare.active():   # im Albtraum von 1987 wartet alles (4.29)
		return true
	if who != _monster and _monster.is_active():
		return true
	if who != Game.ghost and Game.ghost and Game.ghost.is_active():
		return true
	return who != Game.pumpkin and Game.pumpkin != null and (Game.pumpkin.in_house() or Game.pumpkin.announcing())


## Der erste Angriff (Spielkonzept 2.5, 2.6): Während alle zur Puppe schauen, holt es ungesehen Gustav Peters aus
## Zimmer 020 – es zeigt sich nicht und streift danach nicht herum. Er zählt als erster Aufbruch (die harmlose Phase
## danach bleibt gleich lang), satt ist es auch (4.10). Steht der Spieler in Zimmer 020, holt es ihn mit (wie im
## Puppenzimmer, 5.5). victim null: kein Gustav (alte Haushaltsdatei) – dann nur der Bruch.
func first_attack_unseen(victim: Guest) -> void:
	first_attack_done = true
	attacks += 1
	if victim and not victim.dead:
		var no := String(victim.home["no"])
		if Game.tracing:
			print("[Geholt] %s in Zimmer %s – ungesehen (erster Angriff)" % [victim.display_name, no])
		if Game.social and Game.social.grinch:
			Game.social.grinch.taken(victim)
		grief = GRIEF_TIME
		on_guest_taken()
		var p := Game.player
		if p and not p.dead and _builder.room_at(p.global_position) == no:
			kill_player(null)
	on_monster_gone()


## Aufbruch: Absicht wählen, Flackerwelle vom Keller aus (der erste Angriff bei der Siegerehrung hat
## seinen eigenen Auftakt), dann losstreifen.
func _start_activity(spawn: Vector3, with_signal: bool = true) -> void:
	attacks += 1
	phase = Phase.ACTIVE
	var sated := satiation > SATED_ROAM
	if not _planned:
		_choose_intent(sated)
	_planned = false
	_plan_route(spawn)
	_phase_left = _day_lerp(ACTIVE_TIME) * randf_range(0.8, 1.2) * minf(2.0, 1.0 + 0.2 * maxi(0, victims_left - 1))
	if with_signal:
		shown_victims = victims_left
		if not is_harmless() and victims_left > 0 and randf() < DECEIVE_CHANCE * effective_boldness() / 100.0:
			shown_victims = 0   # es täuscht: nur ein Zucken
		_start_wave(spawn_points[0], shown_victims, false, SIGNAL_TIME_SATED if sated else -1.0)
	if Game.tracing:
		var why := "erzwungen" if debug_victims >= 0 else ("satt" if sated else "Chance %.0f %%" % (attack_chance() * 100.0))
		print("[Aufbruch] %d. Angriff%s · Tag %.1f, %s → %s (%d Opfer) · Flackern zeigt %s" % [attacks,
			" (harmlos)" if is_harmless() else "", Calendar.day_float(elapsed), why,
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
	var day := Calendar.day_float(elapsed)
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
			elif _phase_left <= 0.0 and _monster.state != Monster.State.CHASE and (not raid_active() or _phase_left < -RAID_OVERTIME):
				if raid_active() and Game.tracing:
					print("[Puppe] Das Monster kommt nicht bis zur Puppentür – es gibt auf")
				_raiding = false
				_route.clear()
				raid_room = ""
				_monster.go_home()
		_:
			if not _planned and _phase_left <= _lead and first_attack_done:
				_plan_departure()
			if doom_room != "":
				_doll_check -= delta
				if _doll_check <= 0.0:
					_doll_check = DOLL_RECHECK
					_judge(_weakest_door())   # Nachbessern: wer nicht mehr der Schwächste ist, den verlässt sie
				_rumble_tick -= delta
				if _rumble_tick <= 0.0 and _rumble_total > 0.0 and Game.social:
					_rumble_tick = RUMBLE_GUEST_EVERY
					Game.social.on_rumble(clampf(1.0 - _phase_left / _rumble_total, 0.0, 1.0))   # Angst, Gerede, Feier aus
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
	_end_raid()
	_planned = false
	_lead = randf_range(DOLL_LEAD.x, DOLL_LEAD.y)


# --- Die Puppe und ihr Urteil (Spielkonzept 5.5) -------------------------------------------------

## Frist vor dem Aufbruch: Die Absicht steht jetzt fest. Will es wirklich jemanden holen (nicht harmlos, nicht nur
## umsehen), liegt die Puppe ab jetzt vor der schwächsten bewohnten Tür, und ein Grollen schwillt an – ist die
## Ruhephase kürzer als die Frist, wartet das Monster so lange.
func _plan_departure() -> void:
	_planned = true
	var sated := satiation - 0.1 * maxf(_phase_left, 0.0) > SATED_ROAM   # so satt wird es beim Aufbruch noch sein
	_choose_intent(sated)
	if victims_left <= 0 or Game.doll == null:
		return   # beim Umsehen keine Puppe (auch vor den ersten, für Gäste harmlosen Angriffen kommt sie)
	_phase_left = maxf(_phase_left, _lead)
	_rumble_total = _phase_left
	_rumble_told = false
	_doll_check = DOLL_RECHECK
	_judge(_weakest_door())
	Game.caption("[Ein tiefes Grollen geht durchs Haus]")
	if Game.tracing:
		print("[Puppe] %s (%d Opfer) in %.0f s – Urteil: Zimmer %s" % [INTENT_NAMES[intent], victims_left, _phase_left, doom_room])


func _judge(no: String) -> void:
	if no == "" or no == doom_room:
		return
	doom_room = no
	Game.doll.judge(no)


## Debug (--doll[=sekunden]): Der nächste Aufbruch ist ein Angriff mit Puppe – in so vielen Sekunden.
func debug_doll(seconds: float) -> void:
	first_attack_done = true
	attacks = maxi(attacks, HARMLESS_ATTACKS)
	if _monster.is_active():
		_monster.deactivate()
		on_monster_gone()
	var keep := debug_victims
	debug_victims = maxi(debug_victims, 1)
	_lead = seconds
	_phase_left = seconds
	_plan_departure()
	debug_victims = keep


## Zimmer zu einer Eingabe (Debug): Schlüssel („0113“), Nummer („113“) oder Türschild („13“); "" = keins.
func room_by_label(text: String) -> String:
	if rooms.has(text):
		return text
	for key in rooms:
		if String(rooms[key]["sign"]) == text:
			return key
	var padded := "%04d" % text.to_int() if text.is_valid_int() else ""
	return padded if rooms.has(padded) else ""


## Bewohnte Türen (5.5): die Zimmer lebender erwachsener Gäste und Zimmer 13.
func inhabited_rooms() -> Array[String]:
	var result: Array[String] = [LevelBuilder.PLAYER_ROOM]
	if Game.social:
		for guest in Game.social.living_guests():
			var no := String(guest.home["no"])
			if not guest.is_child() and rooms.has(no) and not no in result:
				result.append(no)
	return result


## Wohin die Puppe als Nächstes ginge (Puppenhaus, Spielkonzept 5.16): das Zimmer des Urteils, sonst die
## schwächste bewohnte Tür – eine Tendenz, die sich mit jeder Deko ändern kann.
func forecast_room() -> String:
	return doom_room if doom_room != "" else _weakest_door()


## Die schwächste bewohnte Tür: am wenigsten Deko (wie das Monster sie zählt), bei Gleichstand die dunkelste, sonst
## eine zufällige.
func _weakest_door() -> String:
	if rooms.has(debug_doom):
		return debug_doom
	var decos := _deco_items()
	var entries: Array[Dictionary] = []
	for no in inhabited_rooms():
		var front: Vector3 = rooms[no]["door_front"]
		entries.append({"no": no, "deco": _deco_strength(front, decos), "front": front})
	if entries.is_empty():
		return ""
	var least: float = entries.map(func(e: Dictionary) -> float: return e["deco"]).min()
	entries = entries.filter(func(e: Dictionary) -> bool: return float(e["deco"]) <= least + DOLL_DECO_TIE)
	if doom_room != "" and entries.any(func(e: Dictionary) -> bool: return e["no"] == doom_room):
		return doom_room   # weiter unter den Schwächsten – sie bleibt, wo sie ist
	for e in entries:
		e["light"] = light_at((e["front"] as Vector3) + Vector3.UP)
	var darkest: float = entries.map(func(e: Dictionary) -> float: return e["light"]).min()
	entries = entries.filter(func(e: Dictionary) -> bool: return float(e["light"]) <= darkest + DOLL_LIGHT_TIE)
	return String(entries.pick_random()["no"])


## Beim Aufbruch mit Puppe: der Weg vom Keller zur Puppentür und unterwegs bis zu ROUTE_DOORS bewohnte Türen, deren Deko
## nicht hält (undekoriert oder billig, 4.9) – in der Reihenfolge des Wegs, die Puppentür zuletzt.
func _plan_route(spawn: Vector3) -> void:
	_route.clear()
	raid_room = ""
	_raid_kills = 0
	_raiding = false
	if doom_room == "" or victims_left <= 0:
		return
	_raiding = true
	var goal: Vector3 = rooms[doom_room]["door_front"]
	var path := NavigationServer3D.map_get_path(_monster.get_world_3d().navigation_map, spawn, goal, true)
	var stops: Array[Dictionary] = []
	for no in inhabited_rooms():
		if no == doom_room:
			continue
		var front: Vector3 = rooms[no]["door_front"]
		var along := _along_path(path, front)
		if along < 0.0 or is_blocked(front, false):
			continue
		stops.append({"no": no, "along": along})
	stops.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a["along"]) < float(b["along"]))
	for s in stops.slice(0, ROUTE_DOORS):
		_route.append(String(s["no"]))
	_route.append(doom_room)
	if Game.tracing:
		print("[Puppe] Weg zur Puppentür (Zimmer %s): %s" % [doom_room, ", ".join(_route)])


## Wie weit entlang des Wegs (m) liegt p, wenn es höchstens ROUTE_REACH daneben und auf derselben Höhe liegt? −1 = nicht.
func _along_path(path: PackedVector3Array, p: Vector3) -> float:
	var walked := 0.0
	var best := -1.0
	var best_d := ROUTE_REACH
	for i in range(1, path.size()):
		var a := path[i - 1]
		var b := path[i]
		var q := Geometry3D.get_closest_point_to_segment(p, a, b)
		var d := Vector2(q.x - p.x, q.z - p.z).length()
		if d < best_d and absf(q.y - p.y) < 1.5:
			best_d = d
			best = walked + a.distance_to(q)
		walked += a.distance_to(b)
	return best


## Unterwegs zur Puppentür (von _plan_route bis das Puppenzimmer durchsucht ist)?
func raid_active() -> bool:
	return _raiding


## Liegt p an der Puppentür oder im Puppenzimmer, während das Monster dorthin unterwegs ist?
func _at_doom(p: Vector3) -> bool:
	if not _raiding or not rooms.has(doom_room):
		return false
	if p.distance_to(rooms[doom_room]["door_front"]) < 3.5:
		return true
	return _builder != null and _builder.room_at(p) == doom_room


## Gehört p zum Zimmer, das es gerade durchsucht? In einem gewählten Zimmer helfen keine Verstecke.
func in_raid_room(p: Vector3) -> bool:
	return raid_room != "" and _builder != null and _builder.room_at(p) == raid_room


## Steht der Akteur (Spieler oder Gast) offen im Zimmer, das es gerade durchsucht? Dem entkommt er nicht.
func is_raid_prey(actor) -> bool:
	return raid_room != "" and is_instance_valid(actor) and not actor.dead and actor.hiding == null \
		and in_raid_room(actor.global_position) and not actor in _monster._spared


## Der nächste, der offen im durchsuchten Zimmer steht (null = keiner) – Verstecke prüft es ohnehin alle.
func raid_prey():
	if raid_room == "":
		return null
	for actor in _monster._actors():
		if is_raid_prey(actor):
			return actor
	return null


## Nächstes Ziel auf dem Weg zur Puppentür (Monster._next_roam): {} = kein Weg, normal umherstreifen;
## {"home": true} = das Puppenzimmer ist durchsucht – zurück in den Keller. Türen unterwegs nur, solange es hungrig
## ist und ihre Deko noch nicht hält; die Puppentür immer.
func next_raid_target() -> Dictionary:
	if not _raiding:
		return {}
	if raid_room != "":
		var done := raid_room
		raid_room = ""
		if done == doom_room:
			_finish_raid()
			return {"home": true}
	while not _route.is_empty():
		var no: String = _route[0]
		var front: Vector3 = rooms[no]["door_front"]
		if no == doom_room or (victims_left > 0 and not is_blocked(front, false)):
			return {"pos": front, "room": no}
		_route.pop_front()
	_finish_raid()
	return {"home": true}


## Weg zu Ende: satt, wenn es jemanden geholt hat (4.10); die Puppe bleibt liegen, bis es im Keller ist.
func _finish_raid() -> void:
	_raiding = false
	_route.clear()
	raid_room = ""
	victims_left = 0
	if _raid_kills > 0:
		on_guest_taken()
	if Game.tracing:
		print("[Puppe] Angriff vorbei – %d geholt" % _raid_kills)


func _end_raid() -> void:
	if doom_room != "" and Game.doll:
		Game.doll.release()
	doom_room = ""
	raid_room = ""
	_route.clear()
	_raid_kills = 0
	_raiding = false


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


## Debug (--despawn): Das Monster ist sofort zurück im Keller, die Flackerwelle bricht ab – danach Ruhephase wie nach
## jedem Aufbruch. false = es war nicht unterwegs.
func debug_despawn() -> bool:
	if not _monster.is_active():
		return false
	_monster.deactivate()
	on_monster_gone()
	_wave_start = -1000.0
	_wave_time = 0.0
	return true


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
	if not _monster.is_active() or _monster.state == Monster.State.KILL \
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
	# Gewähltes Zimmer (Puppe, 5.5): jeder darin wird angegriffen; im Puppenzimmer stirbt er immer
	var raided := in_raid_room(spot.global_position if spot != null else guest.global_position) and not is_harmless()
	var doomed := raided and raid_room == doom_room
	if not wants_victim() and not raided:   # harmlos, oder es sieht sich nur um (4.17)
		_scare_guest(guest, spot)
		return
	if guest.is_core() or (not doomed and Wounds.survives()):
		# Er reißt sich los, als es ihn wegschleppen will (Spielkonzept 6.17): nur Kratzer – es bleibt hungrig.
		# Kernfiguren überleben immer, auch im Puppenzimmer (4.33)
		if Game.tracing:
			print("[Losgerissen] %s" % guest.display_name)
		if spot != null:
			spot.rip_open()
		Game.noise("scream", guest.global_position, guest)
		guest.wound_by("scratch", _monster)
		guest.scared_by_monster()
		if skipping:
			pass   # im Zeitsprung ist es nicht wirklich da
		elif raided:
			_monster.continue_raid(guest)
		else:
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
	if not doomed:   # das Puppenzimmer zählt nicht gegen die Opferzahl
		victims_left = maxi(0, victims_left - 1)
	if raided:
		_raid_kills += 1
	if Game.tracing:
		print("[Geholt] %s · noch %d Opfer%s" % [guest.display_name, victims_left, " (Puppenzimmer)" if doomed else ""])
	if raided:   # gewähltes Zimmer: weiter durchsuchen
		if not skipping:
			_monster.continue_raid(null)
	elif victims_left > 0 or _raiding:   # Raubzug bzw. weiter zur Puppentür
		if not skipping:
			_monster.after_kill_hunting()
	else:
		on_guest_taken()
		if not skipping:
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
	if not skipping:
		_monster.after_scare(guest)


## Erwischt es den Spieler, stirbt er – immer, auch beim Umsehen und bei den ersten Angriffen (2026-10-22, ersetzt das
## harmlose Anstarren und Verschwinden).
func kill_player(spot: HideSpot) -> void:
	if Game.game_over:
		return
	Game.game_over = true
	var player := Game.player
	player.dead = true
	player.killed_by = "monster"
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
## HUD weg, Schrei und rotes Aufblitzen, nach 1,5 s der Sterbebildschirm. by: „ghost“ oder „pumpkin“ (Porträt dort).
func player_slain(by: String) -> void:
	Game.game_over = true
	Game.player.dead = true
	Game.player.killed_by = by
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


# --- Zeitsprung im Schlaf (Spielkonzept 3.6) --------------------------------------------------

## dt Sekunden auf einmal (SleepSkip): Uhr, versteckte Werte, Spuk und Zeitplan. Ein Aufbruch läuft abstrakt
## (_skip_activity) – mit denselben Regeln und Würfen, nur ohne zu gehen. Kommt es zu Zimmer 13 oder hörte der Spieler,
## was es tut, ist es ab da wirklich unterwegs: Rückgabe = Gedanke beim Hochschrecken, sonst "".
func skip(dt: float) -> String:
	elapsed += dt
	if first_attack_done:
		boldness = minf(100.0, boldness + BOLDNESS_PER_DAY * dt / Calendar.DAY_SECONDS)
	satiation = maxf(0.0, satiation - 0.1 * dt)
	grief = maxf(0.0, grief - dt)
	_update_zones(dt)
	if not first_attack_done or _monster.is_active():
		return ""
	_update_haunting(dt)
	_phase_left -= dt
	if not _planned and _phase_left <= _lead:
		_plan_departure()
	if _phase_left > 0.0:
		return ""
	if other_threat_active(_monster):
		_phase_left = 10.0
		return ""
	return _skip_activity()


## Ein Aufbruch im Zeitsprung: Absicht wie sonst (_choose_intent bzw. schon bei der Frist der Puppe), dann mit Puppe
## der Weg zur Puppentür (_skip_raid), sonst einige Ziele wie beim Umherstreifen (_skip_roam). Danach ruht es wieder.
func _skip_activity() -> String:
	attacks += 1
	if not _planned:
		_choose_intent(satiation > SATED_ROAM)
	_planned = false
	var active := _day_lerp(ACTIVE_TIME) * randf_range(0.8, 1.2) * minf(2.0, 1.0 + 0.2 * maxi(0, victims_left - 1))
	if Game.tracing:
		print("[Zeitsprung] %d. Aufbruch%s um %s → %s (%d Opfer)%s" % [attacks, " (harmlos)" if is_harmless() else "",
			Calendar.time_text(elapsed), INTENT_NAMES[intent], victims_left, ", Puppe vor Zimmer " + doom_room if doom_room != "" else ""])
	_plan_route(spawn_points[0])
	var wake := _skip_raid() if _raiding else _skip_roam(active)
	if wake != "":
		phase = Phase.ACTIVE
		_phase_left = active
		return wake
	on_monster_gone()
	return ""


## Mit Puppe: Tür für Tür wie next_raid_target – unterwegs nur, solange es hungrig ist und die Deko nicht hält.
func _skip_raid() -> String:
	while not _route.is_empty():
		var no: String = _route[0]
		var front: Vector3 = rooms[no]["door_front"]
		if no != doom_room and (victims_left <= 0 or is_blocked(front, false)):
			_route.pop_front()
			continue
		if no == LevelBuilder.PLAYER_ROOM or _skip_heard(no, true):
			return _skip_wake(front, {})   # der Rest des Wegs steht noch in _route
		_route.pop_front()
		raid_room = no
		for spot: HideSpot in rooms[no]["spots"]:
			spot.rip_open()   # gewähltes Zimmer: es reißt jedes Versteck auf
			spot.checked = true
		for guest in _skip_guests_in(no):
			kill_guest(guest, guest.hiding)
		raid_room = ""
	_finish_raid()
	return ""


## Ohne Puppe: so viele Ziele, wie in die Aktivphase passen (next_roam_target). Vor Deko, die hält, kehrt es um; an
## Zimmertüren biegt es ab wie sonst (wants_to_enter_room) und sucht ab (_skip_search). Zimmer 13: Es kommt.
func _skip_roam(active: float) -> String:
	var at: Vector3 = spawn_points[0]
	for i in maxi(1, roundi(active / SKIP_LEG)):
		var target := next_roam_target(at)
		at = target["pos"]
		var no: String = target["room"]
		if no == "" or is_blocked(at, false):
			continue
		if no == LevelBuilder.PLAYER_ROOM:
			if Game.sleep_skip and Game.sleep_skip.guarded() and randf() < SKIP_GUARD:
				continue
			return _skip_wake(at, target)
		if not wants_to_enter_room(no):
			continue
		if _skip_heard(no):
			return _skip_wake(at, target)
		if _skip_search(no):
			break   # satt – zurück in den Keller
	return ""


## Ein Zimmer absuchen wie Monster._check_hide_step: Wer offen darin steht, den sieht es; Verstecke (auch Betten mit
## Schlafenden) reißt es mit dem Wurf aus der Dreistigkeit auf. true = es hat sich satt gefressen.
func _skip_search(no: String) -> bool:
	for guest in _skip_guests_in(no):
		if guest.hiding == null:
			kill_guest(guest, null)
	for spot: HideSpot in rooms[no]["spots"]:
		var occupant = spot.occupant
		spot.set_checked(true)
		if occupant is Guest and not occupant.dead and not occupant.is_child() \
				and randf() < clampf(effective_boldness() / 140.0, 0.1, 0.65):
			kill_guest(occupant, spot)
	return satiation > SATED_ROAM


## Lebende Erwachsene in diesem Zimmer (Kinder übersieht es, 6.13).
func _skip_guests_in(no: String) -> Array:
	if Game.social == null or _builder == null:
		return []
	return Game.social.living_guests().filter(func(g: Guest) -> bool:
		return not g.is_child() and _builder.room_at(g.global_position) == no)


## Hörte der Spieler, was es in diesem Zimmer tut, so laut, dass er aufwachte (Game.noise: ab 0,3)? Schrei und
## aufgerissenes Versteck tragen gleich weit. raid: es reißt alles auf, auch leer – sonst nur, wenn dort jemand ist.
func _skip_heard(no: String, raid: bool = false) -> bool:
	return (raid or not _skip_guests_in(no).is_empty()) and Game.heard_volume("hide_burst", rooms[no]["center"]) >= 0.3


## Ab hier wirklich: Es erscheint auf dem Weg vom Keller so weit vor `goal`, dass es nach SleepSkip.lead() Sekunden
## ankommt, mit `roam` als Ziel (leer: das nächste Ziel des Wegs zur Puppe). Die Lichter flackern wie beim Aufbruch.
func _skip_wake(goal: Vector3, roam: Dictionary) -> String:
	var lead: float = Game.sleep_skip.lead() if Game.sleep_skip else SleepSkip.LEAD
	var speed := Monster.SEARCH_SPEED if _raiding else Monster.WALK_SPEED
	var start := _point_before(goal, speed * lead)
	shown_victims = victims_left
	_start_wave(spawn_points[0], shown_victims)
	_monster.start_roaming(start, roam)
	if Game.tracing:
		var to: String = roam.get("room", _route[0] if not _route.is_empty() else "?")
		print("[Zeitsprung] Es kommt – zu Zimmer %s, %.0f m vor dem Ziel" % [to, start.distance_to(goal)])
	return "Du schreckst hoch – irgendetwas kommt näher!"


## Punkt auf dem Weg vom Keller nach `goal`, `dist` Meter vor dem Ziel (NavMesh).
func _point_before(goal: Vector3, dist: float) -> Vector3:
	var path := NavigationServer3D.map_get_path(_monster.get_world_3d().navigation_map, spawn_points[0], goal, true)
	if path.is_empty():
		return spawn_points[0]
	var left := dist
	for i in range(path.size() - 1, 0, -1):
		var seg := path[i].distance_to(path[i - 1])
		if seg >= left:
			return path[i].lerp(path[i - 1], left / seg)
		left -= seg
	return path[0]


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
	if _raiding and not _route.is_empty() and _route[0] == no:
		_route.pop_front()
		raid_room = no   # gewähltes Zimmer (5.5): die Tür fällt, es durchsucht alles
		if Game.tracing:
			print("[Puppe] Das Monster bricht in Zimmer %s ein%s" % [no, " – die Puppentür" if no == doom_room else ""])
		return true
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
		"first_attack_done": first_attack_done, "attacks": attacks,
		"grief": grief, "strange_diary": strange_diary, "phase": int(phase), "phase_left": _phase_left,
		"haunt_timer": _haunt_timer, "uv_count": uv_count, "monster_active": _monster.is_active(),
		"victims_left": victims_left, "uv_angry": _uv_angry,
		"monster_pos": [_monster.global_position.x, _monster.global_position.y, _monster.global_position.z],
		# Puppe (5.5): Frist, Urteil und Weg – ein angefangenes Zimmer kommt wieder an den Anfang
		"planned": _planned, "lead": _lead, "rumble_total": _rumble_total, "doom_room": doom_room, "raiding": _raiding,
		"route": ([raid_room] if raid_room != "" else []) + _route, "raid_kills": _raid_kills,
	}


func load_state(d: Dictionary) -> void:
	first_attack_done = bool(d.get("first_attack_done", false))
	attacks = int(d.get("attacks", 0))
	grief = float(d.get("grief", 0.0))
	strange_diary = bool(d.get("strange_diary", false))
	_phase_left = float(d.get("phase_left", 60.0))
	_haunt_timer = float(d.get("haunt_timer", 120.0))
	uv_count = int(d.get("uv_count", 0))
	victims_left = int(d.get("victims_left", 1))
	intent = _intent_for(victims_left)
	_uv_angry = bool(d.get("uv_angry", false))
	_planned = bool(d.get("planned", false))
	_lead = float(d.get("lead", randf_range(DOLL_LEAD.x, DOLL_LEAD.y)))
	_rumble_total = float(d.get("rumble_total", 0.0))
	doom_room = String(d.get("doom_room", ""))
	_raiding = bool(d.get("raiding", false))
	_route.clear()
	for no in d.get("route", []):
		if rooms.has(String(no)):
			_route.append(String(no))
	raid_room = ""
	_raid_kills = int(d.get("raid_kills", 0))
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
		if player.jittery():   # zu viel Kaffee (3.11)
			heart_target = maxf(heart_target, Player.COFFEE_HEART)
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
		# Grollen bis zum Aufbruch (Puppe, 5.5): im ganzen Hotel gleich laut, schwillt bis zum Ende der Frist an
		var rumble_target := 0.0
		if doom_room != "" and phase == Phase.CALM and _rumble_total > 0.0:
			var k := clampf(1.0 - _phase_left / _rumble_total, 0.0, 1.0)
			rumble_target = RUMBLE_START + (1.0 - RUMBLE_START) * k * k
			if k > 0.6 and not _rumble_told:
				_rumble_told = true
				Game.caption("[Das Grollen wird lauter]")
		Game.audio.rumble = move_toward(Game.audio.rumble, rumble_target, delta * (0.2 if rumble_target > Game.audio.rumble else RUMBLE_FADE))
		# Beim Luftanhalten verstummt das Keuchen; je erschöpfter, desto schneller die Atemzüge
		var pant_target := 0.0
		if player and not player.holding_breath and not player.dead:
			pant_target = player.exertion()
		Game.audio.pant = move_toward(Game.audio.pant, pant_target, delta * (3.0 if pant_target < Game.audio.pant else 0.8))
		Game.audio.pant_rate = 0.35 + 0.5 * Game.audio.pant


func debug_text() -> String:
	var s := "%s %s · Phase %s (%ds) · Angriff %d%s\n" % [Calendar.date_text(elapsed), Calendar.time_text(elapsed),
		Phase.keys()[phase], int(_phase_left), attacks, " harmlos" if is_harmless() else ""]
	s += "Dreistigkeit %.1f (effektiv %.1f) · Anspruch ×%.2f · Bedrohung %.2f\n" % [boldness, effective_boldness(), demand(),
		player_threat]
	s += "UV vertrieben: %d× (nötig %.1f s)\n" % [uv_count, uv_repel_time()]
	s += "Absicht: %s (noch %d Opfer) · Flackern zeigte %d · Angriffschance %.0f %%\n" % [INTENT_NAMES[intent], victims_left, shown_victims, attack_chance() * 100.0]
	s += "Monster: %s\n" % Monster.State.keys()[_monster.state]
	if Game.pumpkin:
		s += "Kürbismann: Spaßwert %.0f (Schwelle %.0f) · %d× da%s\n" % [Game.pumpkin.fun_value(), PumpkinMan.FUN_THRESHOLD,
			Game.pumpkin.visits, " · Garantie offen" if not Game.pumpkin.guarantee_at.is_empty() else ""]
	if doom_room != "":
		s += "Puppe: Zimmer %s%s · Weg %s\n" % [doom_room, " (Frist %d s)" % int(_phase_left) if phase == Phase.CALM else "",
			", ".join(_route) if _raiding else "-"]
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
