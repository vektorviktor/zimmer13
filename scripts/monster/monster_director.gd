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
##   · Danach folgt jeder Auftritt einem von vier Modi (4.33): Urteil (Puppe, 8–12 im Spiel), Snack (4–5), Raubzug
##     (10–13, die ersten drei harmlos) und Anforderung (2–3, an Schwellen der Dreistigkeit). Die Tage stehen ab dem
##     ersten Angriff in einem Plan, der je Spiel schwankt; dazu etwa dreimal am Tag eine Runde im Keller (kein Modus).
##   · Zwischen den Modi ist es ohne Körper da: Geräusche hinter Wänden, Spuk, Halluzinationen.
##   · Rauschen nach Entfernung (ab ~20 m, lauter bis ~4 m), Lampen flackern nur in seiner Nähe.
##   · Eine Flackerwelle vom Keller aus verrät den Modus: Zucken = Snack, Flackern = Raubzug, langes Flackern =
##     Anforderung (4.17); das Urteil kündigt die Puppe an.

## CALM = im Keller (ohne Körper), ACTIVE = unterwegs.
enum Phase { CALM, ACTIVE }
## Die vier Modi (Spielkonzept 4.33); PATROL = Runde im Keller, kein Modus
enum Mode { NONE, JUDGMENT, SNACK, RAID, DEMAND, PATROL }
const MODE_NAMES := ["-", "Urteil", "Snack", "Raubzug", "Anforderung", "Kellerrunde"]

# --- Tuning -------------------------------------------------------------------
const BOLDNESS_START := 25.0
## nach dem ersten Angriff, je Spieltag (2.4) – ohne Obergrenze; so liegt die erste Schwelle der Anforderung (55) ohne
## Boni etwa an Tag 14 (4.33)
const BOLDNESS_PER_DAY := 2.7
## Jedes Opfer zieht so viel dauerhaft ab und schiebt die nächste Anforderung hinaus (Sättigung, 4.10, 4.33)
const VICTIM_BOLDNESS := 1.5
## Sättigung nach einem Opfer (4.10): ein Abzug auf die Dreistigkeit, der mit 0,1 je Sekunde abklingt
const SATIATION := 10.0
## Lärm und Licht aus, während es im Keller ist, und Gerede (4.7) machen es dreister (4.33) – jedes höchstens einmal
## je LURE_EVERY, sonst triebe eine Feier oder ein Grollen die Dreistigkeit in Minuten über die Schwellen der Anforderung
const LURE_BOLDNESS := 0.3
const TALK_BOLDNESS := 1.0
const LURE_EVERY := 60.0
## Ereignisse (belauscht, bemerkt, UV) geben Boni obendrauf, die mit dieser Halbwertszeit abklingen (Spielkonzept 4.9)
const BOLDNESS_BONUS_HALF_LIFE := Calendar.HOUR * 6.0
## Heiße Stellen statt Neugier je Zone (Spielkonzept 4.9): überall gilt die Grundneugier, eine Stelle (Lärm, Licht aus,
## Sichtung, „Angst riecht“) wirkt voll bis HOT_CORE und auslaufend bis HOT_RADIUS auf demselben Stockwerk, klingt
## mit HOT_HALF_LIFE ab und verschmilzt mit einer Stelle unter HOT_MERGE; höchstens HOT_MAX, die schwächste fällt heraus
const CURIOSITY_BASE := 40.0
const HOT_RADIUS := 10.0
const HOT_CORE := 3.0
const HOT_HALF_LIFE := 40.0
const HOT_MERGE := 3.0
const HOT_MAX := 24
const HOT_MIN := 2.0
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
## Die vier Modi (4.33) – Zahl im Spiel, Uhrzeit (Stunden ab Mitternacht des Tages, über 24 = nach Mitternacht):
## Urteile etwa alle drei Tage (Abstand in Tagen), das erste nach der Siegerehrung
const JUDGMENTS := Vector2i(8, 12)
const JUDGMENT_FIRST := Vector2(4.0, 5.0)
const JUDGMENT_GAP := Vector2(2.0, 4.0)
const JUDGMENT_HOUR := Vector2(22.0, 26.0)
const SNACKS := Vector2i(4, 5)
const SNACK_HOUR := Vector2(9.0, 23.0)
const RAIDS := Vector2i(10, 13)
const RAID_HOUR := Vector2(10.0, 26.0)
## Raubzüge werden von Tag zu Tag wahrscheinlicher (4.17): Gewicht eines Tages beim Verteilen, Stützpunkte (Tag, Gewicht)
const RAID_WEIGHT := [Vector2(3, 0.2), Vector2(7, 0.5), Vector2(10, 0.8), Vector2(20, 0.95), Vector2(30, 1.0)]
const FIRST_MODE_DAY := 3
## Zwischen zwei Auftritten im Plan mindestens so viel Spielzeit
const MODE_GAP := Calendar.HOUR * 3.0
## Die Puppe (5.5): so lange vor dem Urteil liegt sie vor der schwächsten bewohnten Tür; so oft wird nachgerechnet
const DOLL_LEAD := Vector2(2.0, 5.0) * Calendar.HOUR
const DOLL_RECHECK := 3.0
## Gleich wenig Deko bzw. gleich dunkel, wenn sich die Werte höchstens so stark unterscheiden
const DOLL_DECO_TIE := 0.25
const DOLL_LIGHT_TIE := 0.03
## Urteil, Notausgang (4.33, 3.): Erreicht es den Verurteilten so lange nicht, verschwindet er unbeobachtet – den
## Spieler holt es schon nach JUDGMENT_REACH_PLAYER, dann taucht es ungesehen neben ihm auf
const JUDGMENT_REACH := 120.0
const JUDGMENT_REACH_PLAYER := 60.0
## Notausgang auf dem Dachboden (4.33, 3a): so lange (s) vom Knarren der Kniestocktür bis zum Angriff; dazwischen
## Schritte über die Bohlen alle ATTIC_STEP s, Staub aus der Tür so lange vor dem Angriff
const ATTIC_WARN := Vector2(3.0, 5.0)
const ATTIC_STEP := 0.7
const ATTIC_DUST := 0.9
## Nach dem Urteil greift es nur noch an, wer ihm so nah in den Weg tritt
const IN_THE_WAY := 1.8
## Snack: so lange auf der Etage des Spielers, davon zuerst so lange auf ihn zu
const SNACK_TIME := 30.0
const SNACK_RUSH := Vector2(5.0, 10.0)
## Raubzug: so lange sucht es den Spieler, so oft peilt es ihn neu an (wie ein Peilsender), so lange lenkt ein Geräusch ab
const RAID_TIME := Vector2(90.0, 150.0)
const RAID_SENSE := 4.0
const RAID_DISTRACTED := 10.0
## Die ersten Raubzüge sind harmlos: so nah vor dem Zugriff bricht es ab
const HARMLESS_RAIDS := 3
const HARMLESS_ABORT := 2.6
## Findet es den Spieler nicht, bricht es eine der schwächsten bewohnten Türen auf (dieser Anteil, mindestens drei)
const RAID_WEAK_SHARE := 0.34
## Anforderung: Schwellen der Dreistigkeit (55, 80, 105), höchstens so viele im Spiel; bis zur Garantie-Tag kommt die
## zweite sicher; abends, eine Spielstunde Rauschen vorher; 1–5 Türen
const DEMAND_FIRST := 55.0
const DEMAND_STEP := 25.0
const DEMANDS := 3
const DEMAND_GUARANTEE_DAY := 28
const DEMAND_HOUR := Vector2(20.0, 23.0)
const DEMAND_WARN := Calendar.HOUR
const DEMAND_DOORS := Vector2i(1, 5)
## Runde im Keller (4.33): etwa dreimal am Tag (Abstand in Spielstunden), je etwa 90 Spielminuten
const PATROL_GAP := Vector2(5.0, 11.0) * Calendar.HOUR
const PATROL_TIME := Vector2(75.0, 105.0) / 60.0 * Calendar.HOUR
## Ohne Körper (4.33): so viele Sekunden zwischen zwei Geräuschen hinter einer Wand, so weit vom Spieler
const PRESENCE_EVERY := Vector2(90.0, 240.0)
const PRESENCE_RANGE := Vector2(7.0, 14.0)
## Wo der nächste Snack oder Raubzug beginnt (4.33): die stärkste Lockung (Lärm, Licht aus, Gerede), klingt so ab
const LURE_HALF_LIFE := Calendar.HOUR * 6.0
## Findet es nach so vielen Sekunden nicht ans Ziel einer Tür, gibt es auf
const RAID_OVERTIME := 240.0
## Kleine Veränderungen im Hotel (Sekunden zwischen zwei Ereignissen)
const HAUNT_INTERVAL := Vector2(80.0, 170.0)
## Blutige Schmierspuren an Flurwänden als Spuk: so oft kommt die Möglichkeit dazu, höchstens so viele im Spiel
const WALL_SMEAR_CHANCE := 0.35
const MAX_WALL_SMEARS := 12
## Engerer Blick unter Stress (4.13): Vignette am Bildschirmrand (Grundwert + bei vollem Stress), so schnell steigt
## und fällt der Stress je Sekunde
const VIGNETTE := 0.6
const STRESS_VIGNETTE := 1.2
const STRESS_RISE := 1.5
const STRESS_FALL := 0.25
## Halluzination: mittlere Sekunden zwischen zwei Rausch-Anfällen nach einem Todesfall
const HALLUCINATION_EVERY := 70.0
const GRIEF_TIME := 900.0
## UV-Licht (Spielkonzept 4.16): so lange muss es im Kegel stehen – mit jedem Mal länger
const UV_REPEL_TIME := 1.0
const UV_HABITUATION := 0.5
const UV_REPEL_MAX := 3.5
const UV_BOLDNESS := 6.0               ## es merkt sich, wer es geblendet hat – und die Anforderung rückt näher (4.33)
const UV_CURIOSITY := 40.0             ## … und sucht rund um Zimmer 13
## Flackerwelle (4.17, 4.33): Sekunden je Stufe (Zucken = Snack, Flackern = Raubzug, lang = Anforderung), schwankt um
## ± SIGNAL_JITTER. Läuft mit WAVE_SPEED m/s vom Keller aus, ins Obergeschoss über das Treppenhaus.
const SIGNAL_TIME := [1.0, 3.0, 8.0]
const SIGNAL_JITTER := 0.15
const SIGNAL_STRENGTH := [0.6, 0.75, 1.0]
const WAVE_SPEED := 15.0
## Halluzination: so oft kommt mit dem Rauschen eine lange Flackerwelle ohne Monster
const FAKE_SIGNAL_CHANCE := 0.35
## Grollen (5.5): so leise am Anfang, voll am Ende der Frist; so schnell verklingt es nach dem Aufbruch
const RUMBLE_START := 0.12
const RUMBLE_FADE := 0.4
## So oft wirkt das Grollen (und das Rauschen vor der Anforderung) auf die Gäste (Social.on_rumble)
const RUMBLE_GUEST_EVERY := 3.0

var phase := Phase.CALM
var boldness := BOLDNESS_START
var boldness_bonus := 0.0   ## abklingende Boni aus Ereignissen (4.9)
## Heiße Stellen (4.9): {"pos": Vector3, "heat": float}
var hot_spots: Array[Dictionary] = []
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
var attacks := 0            ## Auftritte seit dem ersten Angriff (alle Modi und Kellerrunden)
var raids := 0              ## Raubzüge bisher – die ersten HARMLESS_RAIDS sind harmlos (4.33)
var demands := 0            ## Anforderungen bisher
var grief := 0.0            ## Sekunden „Trauerzeit“ nach einem Todesfall → Halluzinationen
var strange_diary := false  ## im Tagebuch steht beim nächsten Mal eine fremde Zeile
## Bedrohung beim Spieler (0..1) – Rauschen, Brummen
var player_threat := 0.0
## Stress des Spielers (0..1, geglättet): Bedrohung, Jagd, Versteck, Schock – der Blick wird enger (4.13)
var player_stress := 0.0
var uv_count := 0           ## so oft schon mit UV vertrieben (Gewöhnung, 4.8)
## Plan der Modi (4.33): [{"mode": Mode, "at": elapsed, "lead": Frist der Puppe}], nach Zeit sortiert, ab dem ersten
## Angriff gewürfelt; Anforderungen kommen dazu, sobald eine Schwelle der Dreistigkeit fällt
var plan: Array[Dictionary] = []
var _plan_made := false
## Der laufende Auftritt: Modus und wie viele es noch holen darf (Anforderung 1–7, sonst eins)
var mode := Mode.NONE
var victims_left := 0
var debug_mode := -1             ## --mode=…: der nächste Auftritt folgt diesem Modus
var debug_doom := ""             ## --doll=s,zimmer: die Puppe urteilt immer über dieses Zimmer
## Die Puppe (5.5): Zimmer, vor dessen Tür sie urteilt ("" = kein Urteil); der Verurteilte (Gast oder Spieler, ab
## dem Aufbruch). Die Türen, die es aufbricht (Urteil: nur die Puppentür, Anforderung 1–5, Raubzug eine), und das
## Zimmer, das es gerade durchsucht
var doom_room := ""
var condemned = null
var raid_room := ""
## Puppenmaske (5.19): Zimmer ihres Trägers – vor dessen Tür liegt beim nächsten Urteil die Puppe ("" = keins)
var doll_mask := ""
var _route: Array[String] = []
var _raid_kills := 0
var _raiding := false            ## unterwegs zu Türen, die es aufbricht (bis die letzte durchsucht ist)
var _judged := false             ## das Urteil ist vollstreckt – danach greift es nur an, wer ihm in den Weg tritt
var _reach_timer := 0.0          ## so lange ist es schon hinter dem Verurteilten her
var _lift_wait := false          ## wartet an der Haltestelle des Aufzugs, in dem der Verurteilte fährt (4.33)
var _attic := {}                 ## Notausgang auf dem Dachboden, läuft: {"t", "end", "door", "from", "to", "step"}
var _door_reach := {}            ## Zimmer → seine Tür ist vom Keller aus erreichbar (NavMesh, einmal je Zimmer)
var debug_reach := -1.0          ## --dachboden=urteil: Frist bis zum Notausgang (s) statt JUDGMENT_REACH(_PLAYER)
var _mode_left := 0.0            ## Restzeit von Snack, Raubzug-Suche und Kellerrunde
var _rush_left := 0.0            ## Snack: noch so lange geradewegs auf den Spieler zu
var _sense_timer := 0.0          ## Raubzug: bis es den Spieler wieder anpeilt
var _distracted := 0.0           ## Raubzug: so lange folgt es einem Geräusch statt dem Spieler
var _checked_spot: HideSpot      ## Raubzug: dieses Versteck des Spielers hat es schon abgesucht
var _no_break_in := false        ## Raubzug: es hat den Spieler gejagt oder ist einem Wurf gefolgt – kein Einbruch
var _next_patrol := 0.0          ## nächste Runde im Keller (elapsed)
var _presence_timer := 120.0
var _lure := {}                  ## stärkste Lockung {"pos": Vector3, "heat": float}
var _lured_at := -INF            ## zuletzt durch Lärm oder Licht aus dreister geworden
var _talked_at := -INF           ## zuletzt durch Gerede dreister geworden
var _rumble_total := 0.0        ## so lang war die Frist, als das Grollen begann
var _doll_check := 0.0
var _rumble_told := false
var _rumble_tick := 0.0
var _demand_told := false
var skipping := false            ## Zeitsprung im Schlaf läuft: Zeitplan und Spuk rechnet skip() (SleepSkip)

var _monster: Monster
var _zone_timer := 0.0
## Mitten und Radien der Zonen in gepackten Listen – _zone_at läuft oft
var _zone_centers := PackedVector3Array()
var _zone_radii := PackedFloat64Array()
var _light_grid := {}           ## Vector2i (Zelle) → Lichter darin
var _light_reach := 0.0         ## größte Reichweite im Raster
var _windows: Array[Node] = []  ## Fenster fürs Mondlicht, mit dem Raster neu gelesen
var _light_grid_frame := -LIGHT_GRID_FRAMES
var _noise := 0.0
var _pulse := 0.0
var _jumpscare := 0.0
var _hallucination := 0.0
var _haunt_timer := 120.0
var _uv_driven := false     ## der laufende Auftritt endet, weil UV es vertrieben hat (Raubzug: niemand stirbt)
## Flackerwelle: Ausgangspunkt, Start (elapsed), Dauer je Lampe, Stärke
var _wave_origin := Vector3.ZERO
var _wave_start := -1000.0
var _wave_time := 0.0
var _wave_strength := 0.0
var _wave_level := 0        ## 0 = Zucken, 1 = Flackern, 2 = langes Flackern
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
			Game.achievements.cheated()   # Erfolge nur noch für diese Sitzung (8.11)
			start_warning()
		if Input.is_action_just_pressed("debug_lure"):
			Game.achievements.cheated()
			debug_lure()
		elapsed += delta
		if first_attack_done:
			boldness += BOLDNESS_PER_DAY * delta / Calendar.DAY_SECONDS
		satiation = maxf(0.0, satiation - 0.1 * delta)
		grief = maxf(0.0, grief - delta)
		_cool_down(delta)
		_zone_timer -= delta
		if _zone_timer <= 0.0:
			_zone_timer = 1.0
			# „Angst riecht“: ein Spieler unter Schock lockt das Monster an
			if Game.player and Game.player.shock > 0.1:
				add_curiosity(Game.player.global_position, Game.player.shock * 3.0)
			if _plan_made:
				_check_demand()
		if first_attack_done and not skipping:
			_update_schedule(delta)
			_update_haunting(delta)
			_update_presence(delta)
		_update_hallucination(delta)
	_update_effects(delta)


# --- Versteckte Werte ---------------------------------------------------------------

## Grundwert (steigt in Spieltagen) + abklingende Boni − Sättigung (4.9, 4.10).
func effective_boldness() -> float:
	return maxf(0.0, boldness + boldness_bonus - satiation)


func add_boldness(amount: float) -> void:
	boldness_bonus += amount


func demand() -> float:
	var t := clampf((Calendar.day_float(elapsed) - DEMAND_FROM_DAY) / (Calendar.HALLOWEEN - DEMAND_FROM_DAY), 0.0, 1.0)
	return lerpf(1.0, DEMAND_MAX, t)


func pressure_at(p: Vector3, chasing: bool = false) -> float:
	return effective_boldness() * (0.5 + 0.5 * curiosity_at(p) / 100.0) + (CHASE_BONUS if chasing else 0.0)


func deterrence_at(p: Vector3) -> float:
	if _builder and _builder.is_safe(p):
		return INF   # Katzenraum (Spielkonzept 7.7): dort hinein kommt es nie, wer drinsteht, ist geschützt
	var light := light_at(p + Vector3.UP)
	return deco_strength_at(p) * (0.6 + light) / (demand() * _household_factor(p)) \
		+ light * LIGHT_DETERRENCE * maxf(0.0, 1.0 - effective_boldness() / 120.0)


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
	if _at_target(p):
		return false   # die Tür, die es aufbricht, fällt immer, auch gut geschmückt (Spielkonzept 5.5, 4.33)
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
	# Mondlicht durch Außenfenster mit offenen Vorhängen – so hell, wie Phase und Wolken es zulassen (Weather, 7.8)
	var moon := Game.weather.moonlight() if Game.weather else 1.0
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
			total += MOONLIGHT * moon * (1.0 - wd / MOONLIGHT_RANGE)
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


## Neugier an einer Stelle: Grundwert + heiße Stellen in der Nähe auf demselben Stockwerk (4.9).
func curiosity_at(p: Vector3) -> float:
	var c := CURIOSITY_BASE
	for spot in hot_spots:
		var sp: Vector3 = spot["pos"]
		if absf(p.y - sp.y) > 2.5:
			continue
		var d := Vector2(p.x - sp.x, p.z - sp.z).length()
		if d < HOT_RADIUS:
			c += float(spot["heat"]) * clampf((HOT_RADIUS - d) / (HOT_RADIUS - HOT_CORE), 0.0, 1.0)
	return minf(c, 100.0)


## Macht eine Stelle heiß – oder heißer, wenn schon eine nah genug liegt.
## Die stärkste Lockung merkt es sich länger (_lure, 4.33): Dort beginnt der nächste Snack oder Raubzug.
func add_curiosity(p: Vector3, amount: float) -> void:
	if amount <= 0.0:
		return
	if amount >= float(_lure.get("heat", 0.0)):
		_lure = {"pos": p, "heat": amount}
	for spot in hot_spots:
		var sp: Vector3 = spot["pos"]
		if absf(p.y - sp.y) <= 2.5 and Vector2(p.x - sp.x, p.z - sp.z).length() < HOT_MERGE:
			spot["heat"] = minf(100.0, float(spot["heat"]) + amount)
			return
	hot_spots.append({"pos": p, "heat": minf(100.0, amount)})
	if hot_spots.size() > HOT_MAX:
		var weakest := 0
		for i in hot_spots.size():
			if float(hot_spots[i]["heat"]) < float(hot_spots[weakest]["heat"]):
				weakest = i
		hot_spots.remove_at(weakest)


## Heiße Stellen und Boni der Dreistigkeit klingen ab (4.9) – auch im Zeitsprung.
func _cool_down(dt: float) -> void:
	boldness_bonus *= pow(0.5, dt / BOLDNESS_BONUS_HALF_LIFE)
	if not _lure.is_empty():
		_lure["heat"] = float(_lure["heat"]) * pow(0.5, dt / LURE_HALF_LIFE)
	var k := pow(0.5, dt / HOT_HALF_LIFE)
	for i in range(hot_spots.size() - 1, -1, -1):
		var heat := float(hot_spots[i]["heat"]) * k
		if heat < HOT_MIN:
			hot_spots.remove_at(i)
		else:
			hot_spots[i]["heat"] = heat


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


# --- Dramaturgie ------------------------------------------------------------------------

## Noch harmlos? Die ersten Raubzüge brechen kurz vor dem Zugriff ab (4.33, ersetzt die harmlosen Aufbrüche aus 2.1).
func is_harmless() -> bool:
	return mode == Mode.RAID and raids <= HARMLESS_RAIDS


## Ist es um diesen Ort herum ruhig (kein Monster in der Nähe)?
## Ruhig = kein Monster in der Nähe – und kein jagender Kürbismann (Spielkonzept 4.19): Wo er hinkommt, enden
## Feier und Partien von selbst.
func is_quiet(pos: Vector3, radius: float = 25.0) -> bool:
	if Game.pumpkin and Game.pumpkin.is_hunting() and Game.pumpkin.global_position.distance_to(pos) <= radius:
		return false
	return not _monster.is_active() or _monster.global_position.distance_to(pos) > radius


## Immer nur eine Bedrohung im Haus (entschieden 2026-10-20): Ist das Monster, der Lakengeist oder der Kürbismann
## unterwegs, warten die anderen, bis er weg ist. who: wer fragt – er selbst zählt nicht. Debug-Aufrufe fragen nicht.
## Die Runde im Keller (4.33) zählt nicht – sie ist kein Auftritt im Haus.
func other_threat_active(who: Node) -> bool:
	if Game.nightmare and Game.nightmare.active():   # im Albtraum von 1987 wartet alles (4.29)
		return true
	if who != _monster and _monster.is_active() and mode != Mode.PATROL:
		return true
	if who != Game.ghost and Game.ghost and Game.ghost.is_active():
		return true
	return who != Game.pumpkin and Game.pumpkin != null and (Game.pumpkin.in_house() or Game.pumpkin.announcing())


## Der erste Angriff (Spielkonzept 2.5, 2.6): Während alle zur Puppe schauen, holt es ungesehen Gustav Peters aus
## Zimmer 020 – es zeigt sich nicht und streift danach nicht herum. Steht der Spieler in Zimmer 020, holt es ihn mit
## (wie im Puppenzimmer, 5.5). victim null: kein Gustav (alte Haushaltsdatei) – dann nur der Bruch. Danach wird der
## Plan der Modi gewürfelt (4.33).
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
	if not _monster.is_active():   # ein schon laufender Auftritt (Debug, Spielstand mitten in der Szene) läuft weiter
		on_monster_gone()


# --- Der Plan der Modi (4.33) ----------------------------------------------------------------

## Einmal nach dem ersten Angriff: Urteile etwa alle drei Tage, Snacks an Tagen ohne Urteil, Raubzüge nach der
## Tageskurve verteilt – Tage und Uhrzeiten schwanken je Spiel. Anforderungen kommen später dazu (_check_demand).
## Was schon vorbei wäre (Debug-Sprung in einen späten Tag), fällt weg.
func _make_plan() -> void:
	_plan_made = true
	plan.clear()
	var first := maxi(FIRST_MODE_DAY, Calendar.today())
	var judgment_days: Array[int] = []
	var count := randi_range(JUDGMENTS.x, JUDGMENTS.y)
	var start := randf_range(JUDGMENT_FIRST.x, JUDGMENT_FIRST.y)
	var step := (Calendar.HALLOWEEN - 0.5 - start) / float(count - 1)
	for i in count:
		var day := clampi(roundi(start + step * i + randf_range(-0.6, 0.6)), 1, Calendar.HALLOWEEN - 1)
		if not judgment_days.is_empty() and day <= judgment_days.back():
			day = judgment_days.back() + 1
		if day >= Calendar.HALLOWEEN:
			break
		judgment_days.append(day)
		_add_to_plan(Mode.JUDGMENT, day, JUDGMENT_HOUR)
	var free: Array[int] = []
	for day in range(first, Calendar.HALLOWEEN):
		if not day in judgment_days:
			free.append(day)
	free.shuffle()
	for day in free.slice(0, randi_range(SNACKS.x, SNACKS.y)):
		_add_to_plan(Mode.SNACK, day, SNACK_HOUR)
	# Raubzüge: Tage gewichtet ohne Zurücklegen, höchstens einer am Tag
	var days: Array[int] = []
	var weights: Array[float] = []
	for day in range(first, Calendar.HALLOWEEN):
		days.append(day)
		weights.append(_curve(RAID_WEIGHT, day))
	for i in mini(randi_range(RAIDS.x, RAIDS.y), days.size()):
		var total := 0.0
		for w in weights:
			total += w
		var r := randf() * total
		var pick := days.size() - 1
		for j in days.size():
			r -= weights[j]
			if r <= 0.0:
				pick = j
				break
		_add_to_plan(Mode.RAID, days[pick], RAID_HOUR)
		days.remove_at(pick)
		weights.remove_at(pick)
	_space_plan()
	plan = plan.filter(func(e: Dictionary) -> bool: return float(e["at"]) > elapsed + 1.0)
	_next_patrol = elapsed + randf_range(PATROL_GAP.x, PATROL_GAP.y) * 0.5
	if Game.tracing:
		print("[Plan] %d Urteile, %d Snacks, %d Raubzüge ab Tag %d" % [_count_planned(Mode.JUDGMENT),
			_count_planned(Mode.SNACK), _count_planned(Mode.RAID), first])
		for e in plan:
			print("  %s %s %s" % [Calendar.date_text(e["at"]), Calendar.time_text(e["at"]), MODE_NAMES[e["mode"]]])


## Ein Auftritt an diesem Tag zu einer Stunde aus hours (über 24 = nach Mitternacht).
func _add_to_plan(m: Mode, day: int, hours: Vector2) -> void:
	var at := Calendar.at(day, randf_range(hours.x, hours.y))
	plan.append({"mode": m, "day": day, "at": at, "lead": randf_range(DOLL_LEAD.x, DOLL_LEAD.y)})


## Nach Zeit sortieren und auseinanderschieben: Zwischen zwei Auftritten liegen mindestens MODE_GAP.
func _space_plan() -> void:
	plan.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a["at"]) < float(b["at"]))
	for i in range(1, plan.size()):
		var earliest := float(plan[i - 1]["at"]) + MODE_GAP
		if float(plan[i]["at"]) < earliest:
			plan[i]["at"] = earliest


func _count_planned(m: Mode) -> int:
	return plan.filter(func(e: Dictionary) -> bool: return e["mode"] == m).size()


## Wert einer Kurve aus Stützpunkten (x, y), dazwischen gleitend, davor/danach der erste/letzte Wert.
func _curve(points: Array, x: float) -> float:
	var prev: Vector2 = points[0]
	if x <= prev.x:
		return prev.y
	for point: Vector2 in points:
		if x <= point.x:
			return lerpf(prev.y, point.y, (x - prev.x) / (point.x - prev.x))
		prev = point
	return prev.y


## Anforderung fällig (4.33)? Überschreitet die Dreistigkeit die nächste Schwelle (55, 80, 105) – oder ist bis
## DEMAND_GUARANTEE_DAY erst eine gekommen –, kommt sie am nächsten Abend ohne Urteil.
func _check_demand() -> void:
	var pending := _count_planned(Mode.DEMAND)
	if demands + pending >= DEMANDS:
		return
	var due := effective_boldness() >= DEMAND_FIRST + DEMAND_STEP * (demands + pending)
	if not due and not (Calendar.today() >= DEMAND_GUARANTEE_DAY and demands + pending < 2):
		return
	var day := Calendar.today()
	if Calendar.hour_of(elapsed) > DEMAND_HOUR.x - 1.5:
		day += 1
	while plan.any(func(e: Dictionary) -> bool: return e["mode"] == Mode.JUDGMENT and int(e["day"]) == day):
		day += 1
	if day > Calendar.HALLOWEEN:
		return
	_add_to_plan(Mode.DEMAND, day, DEMAND_HOUR)
	_space_plan()
	if Game.tracing:
		print("[Plan] Anforderung %d fällig (Dreistigkeit %.0f) – am %s abends" % [demands + pending + 1,
			effective_boldness(), Calendar.date_text(Calendar.at(day, 12.0))])


## Der nächste Auftritt im Plan ({} = keiner) und die Spielzeit bis dahin.
func next_planned() -> Dictionary:
	return plan[0] if not plan.is_empty() else {}


func _time_to_next() -> float:
	return float(plan[0]["at"]) - elapsed if not plan.is_empty() else INF


func _update_schedule(delta: float) -> void:
	if not _plan_made:
		_make_plan()
	match phase:
		Phase.ACTIVE:
			if not _monster.is_active():
				on_monster_gone()
			else:
				_update_mode(delta)
		_:
			var due := _update_calm(delta)
			if due == Mode.PATROL and other_threat_active(_monster):
				_next_patrol = elapsed + 60.0
			elif due != Mode.NONE:
				if other_threat_active(_monster):
					plan[0]["at"] = elapsed + 10.0   # Lakengeist oder Kürbismann ist im Haus – es wartet
				else:
					if due != Mode.PATROL:
						plan.pop_front()
					_start_mode(due)


## Im Keller (ohne Körper): die Puppe vor dem Urteil, das Rauschen vor der Anforderung, die Kellerrunden.
## Rückgabe: der Modus, der jetzt fällig ist (Mode.NONE = keiner) – den beginnt der Aufrufer, wirklich oder im
## Zeitsprung.
func _update_calm(delta: float) -> Mode:
	var next := next_planned()
	var left := _time_to_next()
	var next_mode: Mode = next.get("mode", Mode.NONE)
	if next_mode == Mode.JUDGMENT and doom_room == "" and left <= float(next["lead"]):
		_place_doll(left)
	if doom_room != "":
		_doll_check -= delta
		if _doll_check <= 0.0:
			_doll_check = DOLL_RECHECK
			_judge(_weakest_door())   # Nachbessern: wer nicht mehr der Schwächste ist, den verlässt sie
	if (doom_room != "" and _rumble_total > 0.0) or (next_mode == Mode.DEMAND and left <= DEMAND_WARN):
		if next_mode == Mode.DEMAND and not _demand_told:
			_demand_told = true
			Game.caption("[Ein wildes Rauschen geht durchs ganze Haus]")
		_rumble_tick -= delta
		if _rumble_tick <= 0.0 and Game.social:
			_rumble_tick = RUMBLE_GUEST_EVERY
			var total := _rumble_total if doom_room != "" else DEMAND_WARN
			Game.social.on_rumble(clampf(1.0 - left / total, 0.0, 1.0))   # Angst, Gerede, Feier aus
	if left < -Calendar.HOUR:
		plan.pop_front()   # nach einem Sprung der Uhr (Debug) längst vorbei – nicht nachholen
		if next_mode == Mode.JUDGMENT:
			_end_raid(true)   # die Puppe geht zurück in die Lobby
		return Mode.NONE
	if left <= 0.0:
		return next_mode
	if elapsed >= _next_patrol:
		_next_patrol = elapsed + randf_range(PATROL_GAP.x, PATROL_GAP.y)
		if left > PATROL_TIME.y + 60.0:
			return Mode.PATROL
	return Mode.NONE


## Ein Auftritt beginnt (4.33): Ziel, Signal und wo es erscheint, je Modus.
func _start_mode(m: Mode) -> void:
	_begin_mode(m)
	var spawn: Vector3 = spawn_points[0]
	match m:
		Mode.JUDGMENT:
			if condemned == null:
				if Game.tracing:
					print("[Urteil] Niemand mehr in Zimmer %s – das Urteil fällt aus" % doom_room)
				on_monster_gone()
				return
		Mode.SNACK:
			spawn = _floor_spawn(Game.player.global_position)
		Mode.RAID:
			spawn = _lure_spawn()
	if m in [Mode.SNACK, Mode.RAID, Mode.DEMAND]:
		_start_wave(spawn_points[0], _mode_level(m))
	if Game.tracing:
		print("[Aufbruch] %s%s · Tag %.1f · Dreistigkeit %.0f%s" % [MODE_NAMES[m], " (harmlos)" if is_harmless() else "",
			Calendar.day_float(elapsed), effective_boldness(), _mode_detail()])
	_monster.start_roaming(spawn)


## Was für alle Auftritte gleich ist – wirklich und im Zeitsprung.
func _begin_mode(m: Mode) -> void:
	attacks += 1
	phase = Phase.ACTIVE
	mode = m
	victims_left = 1
	_judged = false
	_reach_timer = 0.0
	_lift_wait = false
	_attic = {}
	_no_break_in = false
	_checked_spot = null
	_uv_driven = false
	_distracted = 0.0
	_sense_timer = 0.0
	_route.clear()
	raid_room = ""
	_raid_kills = 0
	_raiding = false
	_mode_left = 0.0
	match m:
		Mode.JUDGMENT:
			condemned = _condemned_in(doom_room)
			if condemned != null:
				_route.append(doom_room)
				_raiding = true
			if condemned is Guest:
				condemned.pin_down()   # ab dem Aufbruch nicht mehr dorthin, wo es nicht hinkommt (4.33, 2.)
		Mode.SNACK:
			_mode_left = SNACK_TIME
			_rush_left = randf_range(SNACK_RUSH.x, SNACK_RUSH.y)
		Mode.RAID:
			raids += 1
			_mode_left = randf_range(RAID_TIME.x, RAID_TIME.y)
		Mode.DEMAND:
			demands += 1
			_demand_told = false
			victims_left = _draw_victims()
			_route = _demand_doors()
			_raiding = not _route.is_empty()
		Mode.PATROL:
			_mode_left = randf_range(PATROL_TIME.x, PATROL_TIME.y)


func _mode_detail() -> String:
	match mode:
		Mode.JUDGMENT:
			return " · Zimmer %s, %s" % [doom_room, _actor_name(condemned)]
		Mode.DEMAND:
			return " · bis %d Opfer, Türen %s" % [victims_left, ", ".join(_route)]
		Mode.RAID:
			return " · %d. Raubzug, %.0f s" % [raids, _mode_left]
	return ""


func _actor_name(actor) -> String:
	if actor == null or not is_instance_valid(actor):
		return "-"
	return "Spieler" if actor == Game.player else String(actor.display_name)


## Stufe der Flackerwelle je Modus: Zucken = Snack, Flackern = Raubzug, lang = Anforderung (4.17).
func _mode_level(m: Mode) -> int:
	return {Mode.SNACK: 0, Mode.RAID: 1, Mode.DEMAND: 2}.get(m, 0)


## Der laufende Auftritt, jedes Bild: Fristen, Peilen, Notausgang.
func _update_mode(delta: float) -> void:
	var chasing := _monster.state == Monster.State.CHASE
	_mode_left -= delta
	match mode:
		Mode.JUDGMENT:
			if _judged:
				return
			if condemned == null or not is_instance_valid(condemned) or condemned.dead:
				_finish_raid()
				_monster.go_home()   # anders gestorben – das Urteil ist hinfällig
				return
			if not _attic.is_empty():
				_update_attic(delta)
				return
			if not _raiding and _wait_for_lift():
				return   # fährt er Aufzug, wartet es an der Haltestelle – die Frist des Notausgangs ruht (4.33, 2.)
			_reach_timer += delta
			var limit := debug_reach if debug_reach >= 0.0 else JUDGMENT_REACH_PLAYER if condemned == Game.player \
				else JUDGMENT_REACH
			if (not _raiding and _reach_timer > limit) or _reach_timer > limit + RAID_OVERTIME:
				_judgment_escape()
		Mode.SNACK:
			_rush_left -= delta
			if victims_left <= 0:
				_monster.go_home()   # einen hat es – zurück
			elif _rush_left > 0.0 and not chasing:
				_sense(false)
			elif _mode_left <= 0.0 and not chasing:
				_monster.go_home()
		Mode.RAID:
			if _raiding:
				if _mode_left < -RAID_OVERTIME:
					_give_up()
				return
			_distracted -= delta
			if _mode_left <= 0.0 and not chasing:
				_end_raid_search()
			elif _distracted <= 0.0 and not chasing:
				_sense(true)
		Mode.DEMAND:
			if _mode_left < -RAID_OVERTIME:
				_give_up()
		Mode.PATROL:
			if (_mode_left <= 0.0 or _time_to_next() <= 0.0) and not chasing:
				_monster.go_home()
		Mode.NONE:   # Debug (--lure, --kill): eine Weile, dann zurück
			if _mode_left <= 0.0 and not chasing:
				_monster.go_home()


## Es spürt den Spieler, wo er ist (Raubzug, Anfang des Snacks): alle RAID_SENSE s geht es zu ihm. Versteckt er sich,
## sucht es dieses eine Versteck ab (dort findet es ihn nur, wenn er auf sich aufmerksam macht); in Zimmer 13 ist er
## nicht zu finden. hide_check: Verstecke absuchen (beim Snack läuft es nur auf ihn zu).
func _sense(hide_check: bool) -> void:
	_sense_timer -= get_physics_process_delta_time()
	if _sense_timer > 0.0:
		return
	_sense_timer = RAID_SENSE
	var p := Game.player
	if p == null or p.dead or player_safe():
		return
	if p.hiding != null:
		if hide_check and p.hiding != _checked_spot:
			_checked_spot = p.hiding
			_monster.go_check(p.hiding)
		return
	_monster.track(p.global_position)


## Zimmer, in dessen Bett der Spieler gerade schläft, falls nicht Zimmer 13 ("" = keins) – das Monster biegt dort
## ein wie in Zimmer 13 (Spielkonzept 3.6).
func foreign_sleep_room() -> String:
	var p := Game.player
	if p == null or not p.sleeping or p.hiding == null or p.hiding.own_bed:
		return ""
	return p.hiding.room_no


## Zählt als „nicht gefunden“: Der Spieler ist in seinem Zimmer (4.33, Raubzug).
func player_safe() -> bool:
	return Game.player != null and _builder != null and _builder.room_at(Game.player.global_position) == LevelBuilder.PLAYER_ROOM


## Ende der Suche beim Raubzug: Hat es den Spieler gejagt, wurde es abgelenkt oder vertrieben, oder war es harmlos,
## geht es heim – sonst bricht es eine der schwächsten Türen auf, hinter der jemand ist, und holt einen daraus.
func _end_raid_search() -> void:
	if _no_break_in or _uv_driven or is_harmless() or not _plan_break_in():
		if Game.tracing:
			print("[Raubzug] vorbei, niemand geholt (%s)" % ("Spieler gejagt" if _no_break_in else "harmlos" if is_harmless()
				else "abgelenkt" if _uv_driven else "keine Tür"))
		_monster.go_home()
		return
	_mode_left = 0.0
	_monster.replan()


## Die Tür für den Einbruch nach dem Raubzug: bewohnt, nicht Zimmer 13, jemand Erwachsenes drin – unter den
## schwächsten (RAID_WEAK_SHARE, mindestens drei) eine zufällige. false = keine.
func _plan_break_in() -> bool:
	var decos := _deco_items()
	var entries: Array[Dictionary] = []
	var bed_room := foreign_sleep_room()   # schläft er in einem fremden Bett, ist das Zimmer dabei (3.6)
	if rooms.has(bed_room):
		entries.append({"no": bed_room, "deco": _deco_strength(rooms[bed_room]["door_front"], decos)})
	for no in inhabited_rooms():
		if no != LevelBuilder.PLAYER_ROOM and no != bed_room and not _skip_guests_in(no).is_empty():
			entries.append({"no": no, "deco": _deco_strength(rooms[no]["door_front"], decos)})
	if entries.is_empty():
		return false
	entries.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a["deco"]) < float(b["deco"]))
	var weak := entries.slice(0, maxi(3, ceili(entries.size() * RAID_WEAK_SHARE)))
	_route = [String(weak.pick_random()["no"])]
	_raiding = true
	victims_left = 1
	if Game.tracing:
		print("[Raubzug] Spieler nicht gefunden – es bricht in Zimmer %s ein" % _route[0])
	return true


## Fährt der Verurteilte Aufzug (4.33, 2.), wartet es an der Haltestelle, an der die Kabine als Nächstes hält; steht
## sie dort mit geschlossener Tür, drückt es den Rufknopf (sie geht auf). Steigt er aus, jagt es weiter.
## true = es wartet (die Frist des Notausgangs ruht).
func _wait_for_lift() -> bool:
	var lift := lift_with(condemned)
	if lift == null:
		if _lift_wait:
			_lift_wait = false
			if _monster.waiting():
				_monster.ambush(_monster.global_position, condemned)
		return false
	if not _lift_wait and Game.tracing:
		print("[Urteil] %s fährt Aufzug – es wartet an der Haltestelle" % _actor_name(condemned))
	_lift_wait = true
	var i := lift.next_stop()
	var spot := lift.waiting_spot(i)
	_monster.wait_at(spot[0], spot[1])
	var there := Vector2(spot[0].x - _monster.global_position.x, spot[0].z - _monster.global_position.z).length() < 1.0 \
		and absf(spot[0].y - _monster.global_position.y) < 1.5
	if there and not lift.moving():
		lift.call_cabin(i)
	return lift.moving() or _monster.waiting()


## Der Aufzug, in dessen Kabine der Akteur steht (null = keiner).
func lift_with(actor) -> Elevator:
	if _builder == null or actor == null or not is_instance_valid(actor):
		return null
	for lift in _builder.elevators:
		if lift.carries(actor.global_position):
			return lift
	return null


## Notausgang auf dem Dachboden (4.33, 3a, Hauptfall): Unten knarrt die Kniestocktür, Schritte kommen über die Bohlen,
## Staub rieselt aus einer Kammertür – nach ATTIC_WARN s stößt es sie geduckt auf und fällt über den Spieler her. Bis
## dahin wartet es ungesehen in einer Kammer 1–2 Türen neben ihm (AtticSpook.ambush_spot). false = der Spieler ist
## nicht oben oder es gibt dort keine solche Kammer.
func _start_attic_scene() -> bool:
	var spook := _builder.attic_spook if _builder else null
	var p := Game.player
	if spook == null or spook.room_at(p.global_position) < 0:
		return false
	var spot := spook.ambush_spot(p)
	if spot.is_empty():
		return false
	var door: Door = spot["door"]
	var knee: Vector3 = spot["pos"]
	for d in _builder.attic_doors:   # die Kniestocktür auf dieser Höhe
		if absf(d.global_position.y - p.global_position.y) < 1.5:
			knee = d.center()
	push_warning("[Urteil] Notausgang auf dem Dachboden: Das Monster kommt durch eine Kammertür")
	_monster.hide_at(spot["pos"], door.center())
	_attic = {"t": 0.0, "end": randf_range(ATTIC_WARN.x, ATTIC_WARN.y), "door": door, "from": knee, "to": spot["pos"],
		"step": 0.0}
	Game.play_sound("creak", 0.7, knee, null, "[Unten knarrt die Kniestocktür]")
	if Game.tracing:
		print("[Urteil] Notausgang Dachboden: Kniestocktür knarrt, Angriff in %.1f s durch die Tür @ %s" % [
			_attic["end"], door.center().snapped(Vector3.ONE * 0.1)])
	return true


## Ablauf der Dachboden-Szene: Schritte, Staub, dann der Angriff. Sieht es den Spieler schon vorher (er kam herein),
## jagt es gleich.
func _update_attic(delta: float) -> void:
	var t: float = _attic["t"] + delta
	var end: float = _attic["end"]
	var door: Door = _attic["door"]
	_attic["t"] = t
	if not _monster.waiting():
		_attic = {}
		return
	if t >= 1.0 and t < end - ATTIC_DUST and t - float(_attic["step"]) >= ATTIC_STEP:
		var k := clampf((t - 1.0) / maxf(0.1, end - ATTIC_DUST - 1.0), 0.0, 1.0)
		var at: Vector3 = (_attic["from"] as Vector3).lerp(_attic["to"], k)
		var first := float(_attic["step"]) == 0.0
		Game.play_sound("thud", 0.3 + 0.3 * k, at, null, "[Schwere Schritte über die Bohlen]" if first else "")
		_attic["step"] = t
	if t >= end - ATTIC_DUST and not _attic.has("dust"):
		_attic["dust"] = true
		if _builder.attic_spook:
			_builder.attic_spook.dust(door)
		Game.play_sound("creak", 0.5, door.center(), null, "[Etwas drückt gegen die Tür]")
	if t >= end:
		_attic = {}
		if Game.tracing:
			print("[Urteil] Notausgang Dachboden: es stößt die Tür auf")
		_monster.ambush(_monster.global_position, Game.player)


## Kommt das Monster vom Keller aus (spawn_points[0]) auf dem NavMesh bis pos? Wie --navcheck: Der nächste Punkt des
## NavMesh liegt höchstens 1 m neben pos, und der Weg endet dort (4.33, gegen Fehlverhalten des Spiels). Ohne fertiges
## NavMesh: ja.
func reachable(pos: Vector3) -> bool:
	if spawn_points.is_empty() or _monster == null or not _monster.is_inside_tree():
		return true
	var map := _monster.get_world_3d().navigation_map
	if NavigationServer3D.map_get_iteration_id(map) == 0:
		return true
	var to := NavigationServer3D.map_get_closest_point(map, pos)
	if to.distance_to(pos) > 1.0:
		return false
	var query := NavigationPathQueryParameters3D.new()
	query.map = map
	query.start_position = NavigationServer3D.map_get_closest_point(map, spawn_points[0])
	query.target_position = to
	query.path_search_max_polygons = 0   # wie das Monster (Monster.agent): vom Keller bis in die Flügel ist es weit
	var result := NavigationPathQueryResult3D.new()
	NavigationServer3D.query_path(query, result)
	var path := result.path
	return not path.is_empty() and path[path.size() - 1].distance_to(to) < 0.5


## Ist die Tür dieses Zimmers vom Keller aus erreichbar (4.33, Prüfung bei der Wahl)? Einmal je Zimmer berechnet –
## das NavMesh ändert sich im Spiel nicht. Ohne fertiges NavMesh: ja (und später noch einmal).
func door_reachable(no: String) -> bool:
	if not _door_reach.has(no):
		if _monster == null or not _monster.is_inside_tree() \
				or NavigationServer3D.map_get_iteration_id(_monster.get_world_3d().navigation_map) == 0:
			return true
		_door_reach[no] = reachable(rooms[no]["door_front"])
		if not _door_reach[no]:
			push_warning("[Urteil] Zimmer %s: Tür vom Keller aus nicht erreichbar" % no)
	return _door_reach[no]


## Kommt es nicht ans Ziel (Weg gescheitert), gibt es auf und geht heim.
func _give_up() -> void:
	if Game.tracing:
		print("[%s] Das Monster kommt nicht bis zur Tür – es gibt auf" % MODE_NAMES[mode])
	_finish_raid()
	_monster.go_home()


## Notausgang beim Urteil (4.33, 3. und 3a.): Den Verurteilten erreicht es nicht – ein Gast verschwindet unbeobachtet
## (Schleifspur Richtung Keller, wie Gustav), beim Spieler taucht es ungesehen ein, zwei Räume neben ihm auf.
func _judgment_escape() -> void:
	_reach_timer = 0.0
	if condemned == Game.player:
		if _start_attic_scene():
			return
		var p := Game.player
		var at := _point_near_unseen(p.global_position, Vector2(5.0, 12.0))
		push_warning("[Urteil] Notausgang: Das Monster erscheint neben dem Spieler")
		Game.play_sound("creak", 0.9, at)
		Game.caption("[Schritte, ganz nah]")
		_monster.ambush(at, p)
		return
	var g: Guest = condemned
	push_warning("[Urteil] Notausgang: %s verschwindet unbeobachtet" % g.display_name)
	var map := _monster.get_world_3d().navigation_map
	var path := NavigationServer3D.map_get_path(map, g.global_position, spawn_points[0], true)
	var trail := PackedVector3Array()
	var walked := 0.0
	for i in path.size():
		trail.append(path[i])
		if i > 0:
			walked += path[i].distance_to(path[i - 1])
		if walked > 6.0:
			break
	if Game.traces and trail.size() >= 2:
		Game.traces.add_drag_trail(trail)
	var where := g.global_position
	g.die("monster")
	var cloth := Item.create(Item.Kind.CLOTHING, g.id)
	_monster.get_parent().add_child(cloth)
	cloth.global_position = Vector3(where.x, where.y + 0.05, where.z)
	grief = GRIEF_TIME
	on_guest_taken()
	_judged = true
	if Game.social:
		Game.social.on_guest_died(g, "unseen")
	_finish_raid()
	_monster.go_home()


## Snack (4.33): Es steigt auf die Etage des Spielers – an einem Wegpunkt dort, den er nicht sieht, lieber nah an
## der stärksten Lockung (_lure), 12–25 m von ihm.
func _floor_spawn(p: Vector3) -> Vector3:
	var best := Vector3.INF
	var best_score := INF
	var lure: Vector3 = _lure.get("pos", p)
	for entry in patrol:
		var pos: Vector3 = entry["pos"]
		var d := pos.distance_to(p)
		if absf(pos.y - p.y) > 1.5 or d < 12.0 or d > 25.0 or player_can_see(pos + Vector3.UP * 1.2):
			continue
		var score := pos.distance_to(lure) + randf() * 4.0
		if score < best_score:
			best_score = score
			best = pos
	return best if best != Vector3.INF else hidden_point_near(p)


## Raubzug: Es beginnt dort, wo es zuletzt am stärksten gelockt wurde (Lärm, Licht aus, Gerede, 4.33) – ungesehen,
## mindestens 10 m vom Spieler; ohne Lockung im Keller.
func _lure_spawn() -> Vector3:
	if _lure.is_empty() or Game.player == null:
		return spawn_points[0]
	var lure: Vector3 = _lure["pos"]
	var best := spawn_points[0]
	var best_d := INF
	for entry in patrol:
		var pos: Vector3 = entry["pos"]
		var d := pos.distance_to(lure)
		if d < best_d and pos.distance_to(Game.player.global_position) > 10.0 and not player_can_see(pos + Vector3.UP * 1.2):
			best_d = d
			best = pos
	return best


## Ein Wegpunkt in diesem Abstand zu p (gleiches Stockwerk), den der Spieler nicht sieht – sonst der nächstbeste.
func _point_near_unseen(p: Vector3, dist: Vector2) -> Vector3:
	var best := Vector3.INF
	var best_d := INF
	for entry in patrol:
		var pos: Vector3 = entry["pos"]
		var d := pos.distance_to(p)
		if absf(pos.y - p.y) > 1.5 or player_can_see(pos + Vector3.UP * 1.2):
			continue
		var miss := 0.0 if d >= dist.x and d <= dist.y else minf(absf(d - dist.x), absf(d - dist.y)) + 10.0
		if miss < best_d:
			best_d = miss
			best = pos
	return best if best != Vector3.INF else hidden_point_near(p)


## Opferzahl n mit Wahrscheinlichkeit ∝ 1/n² (Anforderung: 1–7, 4.33).
func _draw_victims() -> int:
	var total := 0.0
	for n in range(1, 8):
		total += 1.0 / (n * n)
	var r := randf() * total
	for n in range(1, 8):
		r -= 1.0 / (n * n)
		if r <= 0.0:
			return n
	return 7


## Anforderung (4.33): alle bewohnten Türen, deren Abschreckung unter seinem Anspruch liegt (die Deko hält nicht,
## is_blocked), die schwächsten zuerst – mindestens eine (dann die schwächste), höchstens fünf.
func _demand_doors() -> Array[String]:
	var decos := _deco_items()
	var entries: Array[Dictionary] = []
	for no in inhabited_rooms():
		var front: Vector3 = rooms[no]["door_front"]
		entries.append({"no": no, "deco": _deco_strength(front, decos), "weak": not is_blocked(front, false)})
	entries.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a["deco"]) < float(b["deco"]))
	var result: Array[String] = []
	for e in entries:
		if e["weak"] and result.size() < DEMAND_DOORS.y:
			result.append(String(e["no"]))
	if result.is_empty() and not entries.is_empty():
		result.append(String(entries[0]["no"]))
	return result


# --- Flackerwelle (4.17) ---------------------------------------------------------------------

## Welle der Stufe level (0 = Zucken, 1 = Flackern, 2 = lang): Dauer nach SIGNAL_TIME. fake = Halluzination: Lampen
## flackern, aber kein Gast reagiert.
func _start_wave(origin: Vector3, level: int, fake: bool = false) -> void:
	_wave_origin = origin
	_wave_start = elapsed
	_wave_time = float(SIGNAL_TIME[level]) * randf_range(1.0 - SIGNAL_JITTER, 1.0 + SIGNAL_JITTER)
	_wave_level = level
	_wave_strength = SIGNAL_STRENGTH[level]
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


## Will es in diesem Auftritt (noch) jemanden holen?
func wants_victim() -> bool:
	return phase == Phase.ACTIVE and not is_harmless() and victims_left > 0


## Wert zwischen Anfang (1. Oktober) und Halloween.
func _day_lerp(range_value: Vector2) -> float:
	var t := clampf((Calendar.today() - 1) / float(Calendar.HALLOWEEN - 1), 0.0, 1.0)
	return lerpf(range_value.x, range_value.y, t)


## Das Monster ist zurück im Keller – bis zum nächsten Auftritt ist es nur noch zu hören.
## Nach einem Urteil stirbt in dieser Nacht niemand mehr (4.33): Snacks und Raubzüge bis zum Morgen rücken dahinter.
func on_monster_gone() -> void:
	phase = Phase.CALM
	var judged := mode == Mode.JUDGMENT
	_end_raid(judged)
	if judged:
		var day := Calendar.day_of(elapsed) + (1 if Calendar.hour_of(elapsed) >= Calendar.PHASE_START[0] else 0)
		var morning := Calendar.at(day, Calendar.PHASE_START[0])
		for e in plan:
			if float(e["at"]) < morning and e["mode"] in [Mode.SNACK, Mode.RAID]:
				e["at"] = morning + randf_range(0.0, MODE_GAP)
		_space_plan()
	mode = Mode.NONE
	condemned = null
	victims_left = 0
	_uv_driven = false


# --- Wen es jagt, welche Türen es öffnet (4.33) -----------------------------------------------

## Jagt es diesen Akteur, wenn es ihn sieht (dist m entfernt; INF = im Versteck gefunden)? Urteil: nur den
## Verurteilten; Raubzug: den Spieler (außer in Zimmer 13); Anforderung: den Spieler und wer im aufgebrochenen Zimmer
## steht; Snack und Kellerrunde: jeden. Wer ihm direkt in den Weg tritt (IN_THE_WAY), den immer.
func may_hunt(actor, dist: float = INF) -> bool:
	if dist < IN_THE_WAY:
		return true
	match mode:
		Mode.JUDGMENT:
			return actor == condemned and not _judged
		Mode.RAID:
			return (actor == Game.player and not player_safe()) or is_raid_prey(actor)
		Mode.DEMAND:
			return actor == Game.player or is_raid_prey(actor)
	return true


## Auf dem Rückweg in den Keller greift es nur an, wer ihm in den Weg tritt (4.33) – und nicht im Schutz steht.
func hunts_on_retreat(actor) -> bool:
	return actor.global_position.distance_to(_monster.global_position) < IN_THE_WAY and not is_protected(actor.global_position)


## Ist dieser Akteur der Verurteilte? Ihn spürt es, wo er auch ist – auch im Dunkeln, auch hinter Deko.
func is_condemned(actor) -> bool:
	return mode == Mode.JUDGMENT and not _judged and actor != null and actor == condemned


## Darf es diese Tür öffnen? Flurtüren immer, die Tür, die es gerade aufbricht, immer; beim Snack keine Zimmertür
## (wer drinnen ist, ist sicher), beim Raubzug nie Zimmer 13 – sonst nur Zimmertüren, die nicht abgeschlossen sind.
func may_open(door: Door) -> bool:
	if door.room_no == "":
		return true
	if breaks(door):
		return true
	match mode:
		Mode.SNACK:
			return false
		Mode.RAID:
			return door.room_no != LevelBuilder.PLAYER_ROOM and not door.locked
	return not door.locked


## Bricht es diese Tür gerade auf (Puppentür, Tür der Anforderung, Einbruch nach dem Raubzug)? Sie ist danach kaputt.
func breaks(door: Door) -> bool:
	return _raiding and door.room_no != "" and (door.room_no == raid_room or (not _route.is_empty() and door.room_no == _route[0]))


## Eilt es (Suchschritt statt Gehen)? Auf dem Weg zu einer Tür, beim Snack und beim Raubzug.
func hurries() -> bool:
	return _raiding or mode in [Mode.SNACK, Mode.RAID]


## Die Jagd beginnt (Monster._start_chase): Beim Raubzug hat es den Spieler damit gefunden.
func on_chase(actor) -> void:
	if mode == Mode.RAID and actor == Game.player:
		_no_break_in = true


# --- Die Puppe und ihr Urteil (Spielkonzept 5.5, 4.33) ---------------------------------------------

## Frist vor dem Urteil (2–5 Spielstunden): Die Puppe liegt ab jetzt vor der schwächsten bewohnten Tür, und ein
## Grollen schwillt an.
func _place_doll(left: float) -> void:
	if Game.doll == null:
		return
	_rumble_total = maxf(left, 1.0)
	_rumble_told = false
	_doll_check = DOLL_RECHECK
	_judge(_weakest_door())
	if doom_room == "":
		return
	Game.caption("[Ein tiefes Grollen geht durchs Haus]")
	if Game.tracing:
		print("[Puppe] Urteil in %.0f s – Zimmer %s" % [left, doom_room])


## Puppenmaske aufgesetzt (Player.put_on_mask, Spielkonzept 5.19): Das nächste Urteil trifft dieses Zimmer; läuft
## schon eine Frist, wechselt die Puppe beim nächsten Nachbessern (DOLL_RECHECK) dorthin.
func mark_doll_mask(no: String) -> void:
	doll_mask = no


func _judge(no: String) -> void:
	if no == "" or no == doom_room:
		return
	doom_room = no
	Game.doll.judge(no)


## Debug (--mode=…, --doll, --warn): Dieser Modus beginnt in so vielen Sekunden – beim Urteil liegt die Puppe sofort
## vor der Tür.
func debug_start(m: Mode, seconds: float = 0.0) -> void:
	first_attack_done = true
	if not _plan_made:
		_make_plan()
	if _monster.is_active():
		_monster.deactivate()
		on_monster_gone()
	if m == Mode.RAID:
		raids = maxi(raids, HARMLESS_RAIDS)   # wirklich: ab dem vierten
	plan.push_front({"mode": m, "day": Calendar.today(), "at": elapsed + seconds, "lead": seconds + 1.0})
	if m == Mode.JUDGMENT:
		_end_raid(true)
		_place_doll(maxf(seconds, 0.1))


## Debug: so lange beginnt kein Auftritt und keine Kellerrunde (Geisterstunde, 4.18).
func hold(seconds: float) -> void:
	if not _plan_made:
		_make_plan()
	for e in plan:
		e["at"] = maxf(float(e["at"]), elapsed + seconds)
	_space_plan()
	_next_patrol = maxf(_next_patrol, elapsed + seconds)


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


## Türen, vor die die Puppe sich setzt (4.33): Zimmer 13 und Zimmer mit einem Erwachsenen, der keine Kernfigur ist –
## nur, wenn das Monster ihre Tür vom Keller aus erreicht.
func judgeable_rooms() -> Array[String]:
	var result: Array[String] = []
	for no in inhabited_rooms():
		if _condemned_in(no) != null and door_reachable(no):   # nur Türen, die es erreicht (Prüfung bei der Wahl)
			result.append(no)
	return result


## Wen das Urteil über dieses Zimmer trifft (4.33): in Zimmer 13 den Spieler, sonst den erwachsenen Bewohner mit der
## höchsten Schwäche (4.18), bei Gleichstand einen zufälligen – nie Kinder oder Kernfiguren. null = niemand.
func _condemned_in(no: String):
	if no == "":
		return null
	if no == LevelBuilder.PLAYER_ROOM:
		return Game.player if Game.player and not Game.player.dead else null
	if Game.social == null:
		return null
	var best: Array = []
	var most := -INF
	for guest in Game.social.living_guests():
		var g: Guest = guest
		if String(g.home["no"]) != no or g.is_child() or g.is_core():
			continue
		var w := g.weakness()
		if w > most + 0.001:
			most = w
			best = [g]
		elif absf(w - most) <= 0.001:
			best.append(g)
	return best.pick_random() if not best.is_empty() else null


## Wohin die Puppe als Nächstes ginge (Puppenhaus, Spielkonzept 5.16): das Zimmer des Urteils, sonst die
## schwächste bewohnte Tür – eine Tendenz, die sich mit jeder Deko ändern kann.
func forecast_room() -> String:
	return doom_room if doom_room != "" else _weakest_door()


## Die schwächste Tür, vor die sich die Puppe setzt: am wenigsten Deko (wie das Monster sie zählt), bei Gleichstand
## die dunkelste, sonst eine zufällige.
func _weakest_door() -> String:
	if rooms.has(debug_doom):
		return debug_doom
	if rooms.has(doll_mask):
		return doll_mask   # wer die Puppenmaske trug, wird geurteilt – egal wie gut seine Tür geschmückt ist (5.19)
	var decos := _deco_items()
	var entries: Array[Dictionary] = []
	for no in judgeable_rooms():
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


## Unterwegs zu Türen, die es aufbricht (Urteil, Anforderung, Einbruch nach dem Raubzug)?
func raid_active() -> bool:
	return _raiding


## Liegt p an der Tür, die es gerade aufbricht, oder in dem Zimmer dahinter? Diese Tür fällt immer, auch gut
## geschmückt (5.5, 4.33).
func _at_target(p: Vector3) -> bool:
	if not _raiding:
		return false
	var no := raid_room if raid_room != "" else (_route[0] if not _route.is_empty() else "")
	if not rooms.has(no):
		return false
	if p.distance_to(rooms[no]["door_front"]) < 3.5:
		return true
	return _builder != null and _builder.room_at(p) == no


## Gehört p zum Zimmer, das es gerade durchsucht? In einem gewählten Zimmer helfen keine Verstecke.
func in_raid_room(p: Vector3) -> bool:
	return raid_room != "" and _builder != null and _builder.room_at(p) == raid_room


## Steht der Akteur (Spieler oder Gast) offen im Zimmer, das es gerade durchsucht? Dem entkommt er nicht. Beim Urteil
## gilt das nur für den Verurteilten.
func is_raid_prey(actor) -> bool:
	if raid_room == "" or not is_instance_valid(actor) or actor.dead or actor.hiding != null \
			or not in_raid_room(actor.global_position) or actor in _monster._spared:
		return false
	return mode != Mode.JUDGMENT or actor == condemned


## Der nächste, der offen im durchsuchten Zimmer steht (null = keiner) – Verstecke prüft es ohnehin alle.
func raid_prey():
	if raid_room == "":
		return null
	for actor in _monster._actors():
		if is_raid_prey(actor):
			return actor
	return null


## Nächstes Ziel (Monster._next_roam): {"pos", "room"} wie next_roam_target; {"home": true} = zurück in den Keller;
## {"hunt": Akteur} = den Verurteilten holen, wo er ist. Zuerst die Türen, die es aufbricht, der Reihe nach (solange
## es noch jemanden holen darf), dann je Modus.
func next_target(from: Vector3) -> Dictionary:
	if _raiding:
		raid_room = ""
		while not _route.is_empty():
			var no: String = _route[0]
			if victims_left > 0 and not _judged:
				return {"pos": rooms[no]["door_front"], "room": no}
			_route.pop_front()
		_finish_raid()
	match mode:
		Mode.JUDGMENT:
			if is_condemned(condemned) and is_instance_valid(condemned) and not condemned.dead:
				return {"hunt": condemned}
			return {"home": true}
		Mode.DEMAND:
			return {"home": true}
		Mode.RAID:
			if _mode_left <= 0.0 or victims_left <= 0 or _raid_kills > 0:
				return {"home": true}
			return next_roam_target(from)
		Mode.SNACK:
			return next_roam_target(from, from.y)
		Mode.PATROL:
			return next_roam_target(from, LevelBuilder.CELLAR_Y)
	return next_roam_target(from)


## Alle Türen erledigt.
func _finish_raid() -> void:
	if _raiding and Game.tracing:
		print("[%s] Türen vorbei – %d geholt" % [MODE_NAMES[mode], _raid_kills])
	_raiding = false
	_route.clear()
	raid_room = ""
	if _raid_kills > 0 and mode != Mode.JUDGMENT:
		victims_left = 0


## release_doll: die Puppe kehrt in die Lobby zurück (nach dem Urteil, nicht nach einer Kellerrunde in ihrer Frist).
func _end_raid(release_doll: bool) -> void:
	if release_doll:
		if doom_room != "" and Game.doll:
			Game.doll.release()
		if doom_room == doll_mask:
			doll_mask = ""   # das Urteil ist vollstreckt
		doom_room = ""
		_rumble_total = 0.0
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


## Debug (F5, --warn): sofort ein Raubzug.
func start_warning() -> void:
	if not _monster.is_active():
		debug_start(Mode.RAID)


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
			_lured_bolder()   # Lärm macht es dreister (4.33)
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
		if mode == Mode.RAID and source is Item and not _raiding:
			_distracted = RAID_DISTRACTED   # geworfen (3.13): es folgt dem Geräusch statt dem Spieler …
			_no_break_in = true            # … und geht danach heim, ohne einzubrechen (4.33)
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
	add_boldness(8.0)
	add_curiosity(player_door_front, 40.0)
	Game.play_sound("sting", 1.0)
	if mode in [Mode.SNACK, Mode.RAID, Mode.PATROL] and not _raiding:
		_monster.stare()


## Jemand redet über das Monster – es hört mit und wird dreister (Spielkonzept 4.7).
func on_monster_talk(pos: Vector3) -> void:
	add_curiosity(pos, 10.0)
	if elapsed - _talked_at >= LURE_EVERY:
		_talked_at = elapsed
		add_boldness(TALK_BOLDNESS)


## Licht ausgeschaltet, Birne herausgedreht oder durchgebrannt: Dunkelheit lockt es an.
func on_lights_off(pos: Vector3) -> void:
	add_curiosity(pos, LIGHTS_OFF_CURIOSITY)
	_lured_bolder()
	if _monster.is_active() and _monster.global_position.distance_to(pos) < 20.0:
		_monster.investigate(pos)


func _lured_bolder() -> void:
	if first_attack_done and elapsed - _lured_at >= LURE_EVERY:
		_lured_at = elapsed
		add_boldness(LURE_BOLDNESS)


## So lange muss das Monster im UV-Kegel stehen, bis es flieht.
func uv_repel_time() -> float:
	return minf(UV_REPEL_MAX, UV_REPEL_TIME + UV_HABITUATION * uv_count)


## UV-Licht hat es vertrieben (Spielkonzept 4.16): Es flieht in den Keller – beim Raubzug stirbt dann niemand (4.33).
## Dafür weiß es, wer es war – dreister (die Anforderung rückt näher), Neugier rund um Zimmer 13, und es gewöhnt
## sich daran.
func on_monster_uv() -> void:
	uv_count += 1
	add_boldness(UV_BOLDNESS)
	add_curiosity(player_door_front, UV_CURIOSITY)
	_uv_driven = true
	_finish_raid()
	_monster.uv_repel()


## Hat das Monster einen Gast geholt, ist es eine Weile satt – und die nächste Anforderung rückt hinaus (4.10, 4.33).
func on_guest_taken() -> void:
	satiation = SATIATION
	boldness = maxf(0.0, boldness - VICTIM_BOLDNESS)


## Es packt einen Gast (4.33). Holen darf es nur, wen der Modus will: beim Urteil den Verurteilten, beim Snack und in
## der Kellerrunde den Ersten, den es erwischt, bei Anforderung und Einbruch nach dem Raubzug jeden im aufgebrochenen
## Zimmer, bis die Opferzahl erreicht ist – alle anderen erschreckt es nur. Wer gepackt wird, überlebt mit 20 %
## verletzt (6.17), Kernfiguren immer; beides zählt als Opfer.
func kill_guest(guest, spot: HideSpot) -> void:
	if guest == null or not is_instance_valid(guest) or guest.dead or guest.is_child():
		return
	var raided := in_raid_room(spot.global_position if spot != null else guest.global_position)
	var takes: bool = guest == condemned if mode == Mode.JUDGMENT else (raided or mode in [Mode.SNACK, Mode.PATROL, Mode.NONE])
	if not takes or is_harmless() or victims_left <= 0:
		_scare_guest(guest, spot)
		return
	victims_left = maxi(0, victims_left - 1)
	if raided:
		_raid_kills += 1
	if mode == Mode.JUDGMENT:
		_judged = true
	if Wounds.survives(guest):   # Kernfiguren immer
		# Er reißt sich los, als es ihn wegschleppen will (Spielkonzept 6.17): verletzt, aber am Leben
		if Game.tracing:
			print("[Losgerissen] %s (%s) · noch %d Opfer" % [guest.display_name, MODE_NAMES[mode], victims_left])
		if spot != null:
			spot.rip_open()
		Game.noise("scream", guest.global_position, guest)
		guest.wound_by("scratch", _monster)
		guest.scared_by_monster()
	else:
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
		cloth.global_position = Vector3(where.x + 0.4, where.y + 0.05, where.z + 0.2)
		grief = GRIEF_TIME
		on_guest_taken()
		if Game.tracing:
			print("[Geholt] %s (%s) · noch %d Opfer" % [guest.display_name, MODE_NAMES[mode], victims_left])
		if Game.social:
			Game.social.on_guest_died(guest)
	if skipping:
		return   # im Zeitsprung ist es nicht wirklich da
	if not guest.dead:
		_monster._spared.append(guest)   # den Verletzten packt es in diesem Auftritt nicht noch einmal
	if raided and victims_left > 0:
		_monster.continue_raid(null)   # weiter durchsuchen
	else:
		_monster.after_feeding()


## Erschreckt, nicht geholt: Der Gast schreit und rennt – es lässt ihn für den Rest des Auftritts in Ruhe.
func _scare_guest(guest, spot: HideSpot) -> void:
	if Game.tracing:
		print("[Erschreckt] %s (%s%s)" % [guest.display_name, MODE_NAMES[mode], ", harmlos" if is_harmless() else ""])
	if spot != null:
		spot.rip_open()
	Game.noise("scream", guest.global_position, guest)
	guest.scared_by_monster()
	if not skipping and _monster.state != Monster.State.RETREAT:
		_monster.after_scare(guest)


## Erwischt es den Spieler, stirbt er – immer (2026-10-22, 8.7); nur die harmlosen Raubzüge brechen vorher ab
## (Monster._abort).
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

## dt Sekunden auf einmal (SleepSkip): Uhr, versteckte Werte, Spuk und der Plan der Modi (4.33). Ein Auftritt läuft
## abstrakt (_skip_mode) – mit denselben Regeln, nur ohne zu gehen. Kommt es zu Zimmer 13 oder hörte der Spieler, was es
## tut, ist es ab da wirklich unterwegs: Rückgabe = Gedanke beim Hochschrecken, sonst "".
func skip(dt: float) -> String:
	elapsed += dt
	if first_attack_done:
		boldness += BOLDNESS_PER_DAY * dt / Calendar.DAY_SECONDS
	satiation = maxf(0.0, satiation - 0.1 * dt)
	grief = maxf(0.0, grief - dt)
	_cool_down(dt)
	if not first_attack_done or _monster.is_active():
		return ""
	if not _plan_made:
		_make_plan()
	_check_demand()
	_update_haunting(dt)
	var due := _update_calm(dt)
	if due == Mode.NONE or due == Mode.PATROL:
		return ""   # die Kellerrunde: unten, während man schläft
	if other_threat_active(_monster):
		plan[0]["at"] = elapsed + 10.0
		return ""
	plan.pop_front()
	return _skip_mode(due)


## Ein Auftritt im Zeitsprung. Wer schläft, liegt hinter seiner Tür: Der Snack holt dann niemanden, der Raubzug findet
## den Spieler in Zimmer 13 nicht und bricht ein (_plan_break_in); Urteil und Anforderung gehen ihre Türen ab
## (_skip_raid), den Verurteilten holt es auch anderswo. Danach ist es wieder im Keller.
func _skip_mode(m: Mode) -> String:
	_begin_mode(m)
	if Game.tracing:
		print("[Zeitsprung] %s%s um %s%s" % [MODE_NAMES[m], " (harmlos)" if is_harmless() else "",
			Calendar.time_text(elapsed), _mode_detail()])
	var wake := ""
	match m:
		Mode.JUDGMENT:
			if condemned != null:
				wake = _skip_raid()
				if wake == "" and is_condemned(condemned) and condemned is Guest and not condemned.dead:
					kill_guest(condemned, condemned.hiding)   # nicht im Zimmer – es holt ihn, wo er ist
		Mode.RAID:
			if not is_harmless() and _plan_break_in():
				wake = _skip_raid()
		Mode.DEMAND:
			wake = _skip_raid()
	if wake != "":
		return wake
	on_monster_gone()
	return ""


## Tür für Tür wie next_target: Zimmer 13 oder Lärm, den der Spieler hört, wecken ihn – sonst reißt es jedes Versteck
## auf und packt, wen der Modus will (kill_guest).
func _skip_raid() -> String:
	while not _route.is_empty():
		var no: String = _route[0]
		if victims_left <= 0 or _judged:
			_route.pop_front()
			continue
		var front: Vector3 = rooms[no]["door_front"]
		if no == LevelBuilder.PLAYER_ROOM or no == foreign_sleep_room() or _skip_heard(no, true):
			return _skip_wake(front)   # der Rest des Wegs steht noch in _route
		_route.pop_front()
		raid_room = no
		var door: Door = rooms[no]["door"]
		door.monster_open(true)
		for spot: HideSpot in rooms[no]["spots"]:
			spot.rip_open()   # gewähltes Zimmer: es reißt jedes Versteck auf
			spot.checked = true
		for guest in _skip_guests_in(no):
			kill_guest(guest, guest.hiding)
		raid_room = ""
	_finish_raid()
	return ""


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
## ankommt, und geht den Rest des Wegs (_route). Die Lichter flackern wie beim Aufbruch (nicht beim Urteil).
func _skip_wake(goal: Vector3) -> String:
	var lead: float = Game.sleep_skip.lead() if Game.sleep_skip else SleepSkip.LEAD
	var start := _point_before(goal, Monster.SEARCH_SPEED * lead)
	if mode != Mode.JUDGMENT:
		_start_wave(spawn_points[0], _mode_level(mode))
	_monster.start_roaming(start)
	if Game.tracing:
		print("[Zeitsprung] Es kommt – zu Zimmer %s, %.0f m vor dem Ziel" % [_route[0] if not _route.is_empty() else "?",
			start.distance_to(goal)])
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


## Halluzination nach einem Todesfall, unter Schock, betrunken (3.7) oder übermüdet (3.6): Rauschen ohne Monster.
func _update_hallucination(delta: float) -> void:
	if _hallucination > 0.0:
		_hallucination -= delta
		return
	var p := Game.player
	if p == null or p.dead:
		return
	var drunk := p.drunk >= BarTap.DRUNK
	if (grief > 0.0 or p.shock > 0.15 or drunk or p.overtired()) and randf() < delta / HALLUCINATION_EVERY * (1.0 + (p.drunk if drunk else 0.0)):
		_hallucination = randf_range(6.0, 11.0)
		if not _monster.is_active() and randf() < FAKE_SIGNAL_CHANCE:   # langes Flackern – und nichts kommt
			_start_wave(spawn_points[0], 2, true)


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


## Ohne Körper präsent (4.33): Zwischen den Auftritten hört man es – Kratzen, Poltern, Knurren hinter einer Wand in
## der Nähe, an einer Stelle, die man nicht sieht. Ein Monster ist dort nicht.
func _update_presence(delta: float) -> void:
	if phase != Phase.CALM:
		return
	_presence_timer -= delta
	if _presence_timer > 0.0:
		return
	_presence_timer = randf_range(PRESENCE_EVERY.x, PRESENCE_EVERY.y)
	var p := Game.player
	if p == null or p.dead or p.sleeping:
		return
	var at := _point_near_unseen(p.global_position, PRESENCE_RANGE)
	if at.distance_to(p.global_position) < PRESENCE_RANGE.x - 2.0:
		return
	var sound: Array = [["creak", "[Kratzen hinter der Wand]"], ["thud", "[Etwas poltert hinter der Wand]"],
		["growl", "[Ein leises Knurren hinter der Wand]"]].pick_random()
	Game.play_sound(sound[0], 0.28, at)   # unter 0,3: ohne den allgemeinen Untertitel
	Game.caption(sound[1])
	if Game.tracing:
		print("[Ohne Körper] %s @ %s" % [sound[1], at.snapped(Vector3.ONE * 0.1)])


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

## Nächstes Ziel beim Umherstreifen: irgendwo im Hotel (floor_y: nur auf diesem Stockwerk), gewichtet nach Druck
## (Dreistigkeit und heiße Stellen, 4.9). Lieber Orte, die der Spieler gerade nicht sieht.
func next_roam_target(from: Vector3, floor_y: float = INF) -> Dictionary:
	var candidates: Array[Dictionary] = []
	var weights: Array[float] = []
	var current := zone_name_at(from)
	for zone in zones:
		var zone_name: String = zone["name"]
		if zone_name == current or (floor_y != INF and absf((zone["center"] as Vector3).y - floor_y) > LevelBuilder.UP_Y / 2.0):
			continue
		var target := {"pos": zone["center"] as Vector3, "room": ""}
		if zone_name.begins_with("Zimmer "):
			var no := zone_name.substr(7)
			if rooms.has(no):
				target = {"pos": (rooms[no] as Dictionary)["door_front"] as Vector3, "room": no}
		var pos: Vector3 = target["pos"]
		var w := pow(maxf(pressure_at(pos), 1.0), 2.0)
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


## Biegt das Monster an dieser Tür ins Zimmer ab? Nur, wenn es diese Tür aufbricht (4.33) – sonst bleibt es im Flur.
func wants_to_enter_room(no: String) -> bool:
	if not rooms.has(no) or not _raiding or _route.is_empty() or _route[0] != no:
		return false
	_route.pop_front()
	raid_room = no   # gewähltes Zimmer (5.5): die Tür fällt, es durchsucht alles
	if Game.tracing:
		print("[%s] Das Monster bricht in Zimmer %s ein%s" % [MODE_NAMES[mode], no, " – die Puppentür" if no == doom_room else ""])
	return true


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
		"first_attack_done": first_attack_done, "attacks": attacks, "raids": raids, "demands": demands,
		"grief": grief, "strange_diary": strange_diary, "phase": int(phase),
		"haunt_timer": _haunt_timer, "uv_count": uv_count, "monster_active": _monster.is_active(),
		"monster_pos": [_monster.global_position.x, _monster.global_position.y, _monster.global_position.z],
		# Plan der Modi (4.33) und der laufende Auftritt – ein angefangenes Zimmer kommt wieder an den Anfang
		"plan_made": _plan_made,
		"plan": plan.map(func(e: Dictionary) -> Array: return [int(e["mode"]), int(e["day"]), float(e["at"]), float(e["lead"])]),
		"next_patrol": _next_patrol, "mode": int(mode), "victims_left": victims_left, "mode_left": _mode_left,
		"condemned": _condemned_key(),
		"judged": _judged, "no_break_in": _no_break_in,
		# Puppe (5.5): Frist, Urteil und Türen
		"rumble_total": _rumble_total, "doom_room": doom_room, "raiding": _raiding,
		"route": ([raid_room] if raid_room != "" else []) + _route, "raid_kills": _raid_kills,
		"doll_mask": doll_mask,
		# versteckte Werte (4.9): abklingende Boni, heiße Stellen, stärkste Lockung
		"boldness_bonus": boldness_bonus,
		"hot_spots": hot_spots.map(func(h: Dictionary) -> Array:
			var p: Vector3 = h["pos"]
			return [p.x, p.y, p.z, h["heat"]]),
		"lure": _lure_array(),
	}


func _condemned_key() -> String:
	if condemned == null or not is_instance_valid(condemned):
		return ""
	return "player" if condemned == Game.player else String(condemned.id)


func _lure_array() -> Array:
	if _lure.is_empty():
		return []
	var p: Vector3 = _lure["pos"]
	return [p.x, p.y, p.z, _lure["heat"]]


func load_state(d: Dictionary) -> void:
	first_attack_done = bool(d.get("first_attack_done", false))
	attacks = int(d.get("attacks", 0))
	raids = int(d.get("raids", 0))
	demands = int(d.get("demands", 0))
	grief = float(d.get("grief", 0.0))
	strange_diary = bool(d.get("strange_diary", false))
	_haunt_timer = float(d.get("haunt_timer", 120.0))
	uv_count = int(d.get("uv_count", 0))
	_plan_made = bool(d.get("plan_made", false))
	plan.clear()
	for e in d.get("plan", []):
		var a: Array = e
		plan.append({"mode": int(a[0]), "day": int(a[1]), "at": float(a[2]), "lead": float(a[3])})
	_next_patrol = float(d.get("next_patrol", elapsed + PATROL_GAP.x))
	mode = int(d.get("mode", Mode.NONE)) as Mode
	victims_left = int(d.get("victims_left", 0))
	_mode_left = float(d.get("mode_left", 0.0))
	var who := String(d.get("condemned", ""))
	condemned = null
	if who == "player":
		condemned = Game.player
	elif who != "" and Game.social:
		condemned = Game.social.guest_by_id(who)
	_judged = bool(d.get("judged", false))
	_no_break_in = bool(d.get("no_break_in", false))
	_rumble_total = float(d.get("rumble_total", 0.0))
	doom_room = String(d.get("doom_room", ""))
	doll_mask = String(d.get("doll_mask", ""))
	boldness_bonus = float(d.get("boldness_bonus", 0.0))
	hot_spots.clear()
	for h in d.get("hot_spots", []):
		var a: Array = h
		hot_spots.append({"pos": Vector3(float(a[0]), float(a[1]), float(a[2])), "heat": float(a[3])})
	var lure: Array = d.get("lure", [])
	_lure = {}
	if not lure.is_empty():
		_lure = {"pos": Vector3(float(lure[0]), float(lure[1]), float(lure[2])), "heat": float(lure[3])}
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
	else:
		mode = Mode.NONE


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
	# Vor der Anforderung (4.33): eine Spielstunde langes, wildes Rauschen im ganzen Hotel, immer stärker
	var demand_k := demand_warning()
	if demand_k > 0.0:
		noise_target = maxf(noise_target, 0.12 + 0.2 * demand_k)
		hum_target = maxf(hum_target, 0.2 + 0.25 * demand_k)
		flicker_target = maxf(flicker_target, 0.15 * demand_k)
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
	# Engerer Blick unter Stress (4.13): schnell eng, langsam wieder weit
	var stress := 0.0
	if player and not player.dead:
		stress = maxf(maxf(player_threat, player.hide_stress), player.shock * 0.6)
		if _monster.state == Monster.State.CHASE and player_threat > 0.0:
			stress = 1.0
	player_stress = move_toward(player_stress, stress, delta * (STRESS_RISE if stress > player_stress else STRESS_FALL))
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
		post_material.set_shader_parameter("vignette", VIGNETTE + STRESS_VIGNETTE * player_stress)
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
			var k := clampf(1.0 - _time_to_next() / _rumble_total, 0.0, 1.0)
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


## Rauschen vor der Anforderung: 0 = keins, steigt in der letzten Spielstunde bis 1.
func demand_warning() -> float:
	if phase != Phase.CALM or plan.is_empty() or plan[0]["mode"] != Mode.DEMAND:
		return 0.0
	var left := _time_to_next()
	return clampf(1.0 - left / DEMAND_WARN, 0.0, 1.0) if left <= DEMAND_WARN else 0.0


func debug_text() -> String:
	var next := next_planned()
	var s := "%s %s · Phase %s · %s · Auftritt %d · Raubzug %d%s · Anforderung %d\n" % [Calendar.date_text(elapsed),
		Calendar.time_text(elapsed), Phase.keys()[phase], MODE_NAMES[mode], attacks, raids,
		" harmlos" if is_harmless() else "", demands]
	s += "Dreistigkeit %.1f + %.1f (effektiv %.1f, Schwelle %.0f) · Anspruch ×%.2f · Bedrohung %.2f · Stress %.2f\n" % [
		boldness, boldness_bonus, effective_boldness(), DEMAND_FIRST + DEMAND_STEP * demands, demand(), player_threat,
		player_stress]
	s += "UV vertrieben: %d× (nötig %.1f s)\n" % [uv_count, uv_repel_time()]
	var next_text := "-"
	if not next.is_empty():
		next_text = "%s %s %s" % [MODE_NAMES[next["mode"]], Calendar.date_text(next["at"]), Calendar.time_text(next["at"])]
	s += "Nächster Auftritt: %s · Kellerrunde in %d s · noch %d Opfer\n" % [next_text, int(_next_patrol - elapsed),
		victims_left]
	s += "Monster: %s\n" % Monster.State.keys()[_monster.state]
	if Game.pumpkin:
		s += "Kürbismann: Spaßwert %.0f (Schwelle %.0f) · %d× da%s\n" % [Game.pumpkin.fun_value(), Game.pumpkin.threshold(),
			Game.pumpkin.visits, " · Garantie offen" if not Game.pumpkin.guarantee_at.is_empty() else ""]
	if doom_room != "":
		s += "Puppe: Zimmer %s%s · Verurteilt: %s\n" % [doom_room, " (Frist %d s)" % int(_time_to_next())
			if phase == Phase.CALM else "", _actor_name(condemned)]
	if _raiding:
		s += "Türen: %s\n" % ", ".join(([raid_room] if raid_room != "" else []) + _route)
	if Game.player:
		s += "Licht beim Spieler: %.2f · Ausdauer %.2f%s\n" % [light_at(Game.player.global_position + Vector3.UP),
			Game.player.stamina, " außer Atem" if Game.player.winded else ""]
	s += "Heiße Stelle  Hitze Neugier Druck Abschr.\n"
	for spot in hot_spots:
		var c: Vector3 = spot["pos"]
		s += "%-13s %5.0f %7.0f %5.1f %5.1f\n" % [zone_name_at(c), spot["heat"], curiosity_at(c), pressure_at(c),
			deterrence_at(c)]
	if not Game.noise_log.is_empty():
		s += "Lärm:\n  " + "\n  ".join(Game.noise_log) + "\n"
	s += "F5 = Monster losschicken"
	return s
