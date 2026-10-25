class_name Guest
extends CharacterBody3D
## Hotelgast mit eigenem Tagesablauf (Spielkonzept 6). Nutzt dieselben Dinge wie der
## Spieler: trägt Gegenstände in der Hand, öffnet Türen, versteckt sich in Schränken.
## Stellt Deko vor die eigene Tür, erntet und schnitzt Kürbisse, klaut, wenn er dich
## nicht mag (oder in Panik ist), feiert in der Lobby – und kann vom Monster geholt werden.
## Der Koffer („stock“) ist abstrakt; was er in der Hand hat, ist echt.
## Licht & Vorhänge (7.3): schaltet sein Zimmerlicht, zieht Vorhänge zu, wenn er Angst hat,
## ersetzt fehlende Glühbirnen – und klaut selbst welche.
## Schreck (6.12): Sieht er eine Blutlache, eine Leiche oder den Lakengeist, bleibt er geschockt stehen –
## je nach Charakter mit erhobenen Händen und Flucht, starr oder weinend – und erzählt später davon.
## Freundschaft & Feindschaft (6.3): folgt dir als Freund, besucht dich in Zimmer 13, rempelt dich an,
## wenn er wütend ist, stolpert, wenn du ihn rammst, und schlägt zurück oder flieht, wenn du zuschlägst.

enum State { IDLE, WALK, CARRY_HOME, PLACE_DECO, HARVEST, STEAL, HIDE_GO, HIDING, PARTY, TALKING, MINIGAME, DEAD, KNOCK, SHELTER, SLEEP, SHOCKED, GHOSTED,
	FOLLOW, VISIT, ATTACK, STAGGER, DECORATE, SEARCH, EAT }

const WALK_SPEED := 1.4
const DART_THROW_TIME := 0.55   ## Wurfbewegung beim Darts (throw_dart_pose)
## Detailstufe (Leistung bei vielen Gästen): Wer nicht im Blickfeld und weiter als LOD_RANGE vom Spieler ist (oder
## weiter als LOD_FAR), rechnet nur jedes LOD_STEP-te Physikbild – mit der aufgesammelten Zeit und entsprechend
## längeren Schritten (_lod_scale in _move_to). In der Nähe und im Blick bleibt alles flüssig.
const LOD_RANGE := 15.0
const LOD_FAR := 45.0
const LOD_STEP := 3
const RUN_SPEED := 3.3
## Hört das Monster (Rauschen) ab dieser Entfernung – vorsichtige Gäste verstecken sich
const HEAR_DISTANCE := 15.0
## Erschreckendes Geräusch (4.15): Angst-Zuwachs (× (1,2 − Mut)) und Pause bis zur nächsten Reaktion
const ALARM_FEAR := 25.0
const ALARM_COOLDOWN := 20.0
const ALARM_LINES := ["Was war das?!", "Hast du das gehört?", "Da war doch was …", "Hallo? Ist da jemand?"]
## Erst wieder aus dem Versteck, wenn das Monster so weit weg ist
const SAFE_DISTANCE := 22.0
## Festgefahren: kommt er beim Gehen so lange nicht weiter als STALL_RANGE vom Fleck, gibt er das Ziel auf
## (sonst rennt er auf dem Weg ins Versteck endlos auf der Stelle – mit Lärm, der das Monster lockt)
const STALL_TIME := 10.0
const STALL_RANGE := 1.5
## Schlafen im Bett (Nachtruhe): Füße so weit vom Bettmittelpunkt zum Fußende, so hoch liegt die Matratze
const BED_FEET := 0.9
## Türen (Spielkonzept 6.19): so weit voraus schaut er auf seinem Weg, ob er durch eine Tür muss; so weit hinter der
## Tür schließt er sie, so lange (s) bzw. bis so weit wartet er, wenn jemand im Schwenkbereich steht
const DOOR_LOOKAHEAD := 4.0
const DOOR_CLOSE_DISTANCE := 1.4
const DOOR_SWING_CLEAR := 1.15
const DOOR_GIVE_UP_DISTANCE := 9.0
const DOOR_GIVE_UP_WAIT := 12.0
## Liegen: so weit vom Fußende entfernt liegen die Füße (Bettlänge aus dem Plan, HideSpot.bed_size)
const BED_FOOT_GAP := (BedModel.POST + BedModel.BEAM) / 2.0 + 0.05
## So weit von der Zimmermitte gilt ein Mitbewohner als zu Hause (für das Licht beim Schlafengehen)
const HOME_RADIUS := 6.0
const BED_TOP := BedModel.TOP
## Spuren: so viele schlammige Schritte nach dem Garten, so lange blutet ein Gast nach einem Angriff
const MUD_STEPS := 14
const BLEED_TIME := 45.0
## Tänze bei Feiern (`_dance_pose`) für die Klötzchenfigur – Gastmodelle tanzen GuestBody.DANCES
const DANCES := ["hüpfen", "wiegen", "drehen", "arme hoch", "twist", "schunkeln"]
## Stimme (Schreie, SynthAudio.VOICES): jeder klingt etwas anders hoch (± VOICE_SPREAD, fest nach der Id), dazu
## Alter, Panik (höher) und Rausch (tiefer, schleppend); Mutige brechen den Schreckensschrei bis VOICE_BRAVE früher ab
const VOICE_SPREAD := 0.06
const VOICE_AGE := {"young": 1.04, "mid": 1.0, "old": 0.92}
const VOICE_FEAR := 0.06
const VOICE_DRUNK := 0.08
const VOICE_BRAVE := 0.35
## Schreck (Spielkonzept 6.12): so weit sieht er Blut und Leichen, so oft schaut er sich um;
## Reaktion je Charakter (feste Gäste: profile["shock"])
const SHOCK_RANGE := 7.0
const SHOCK_SCAN := 0.5
const SHOCK_STYLES := {
	"ängstlich": "flee", "geschäftstüchtig": "flee", "Plaudertasche": "cry", "Bastler": "cry",
	"Skeptiker": "freeze", "Griesgram": "freeze",
}
## Lakengeist vor der Tür (Spielkonzept 5.6): so lange starrt er hin, bevor er aufmachen geht (bei voller
## Schwäche halb so lange) – aufmachen gehen nur so viele (+ Schwäche × DOOR_OPEN_WEAK), die anderen starren nur
const DOOR_TRANCE := Vector2(20.0, 50.0)
const DOOR_OPEN := 0.2
const DOOR_OPEN_WEAK := 0.8
const SHOCK_CRIES := {
	"flee": ["Oh Gott! Nein, nein, nein!", "Hilfe! HILFE!", "Weg hier, nur weg!"],
	"freeze": ["…", "Was zum …", "Das … das ist nicht wahr."],
	"cry": ["Nein … *schluchzt*", "Oh nein, oh nein … *weint*", "Warum … *schluchzt*"],
	"cling": ["*schreit*", "Neiiin!", "*weint laut*"],
}
## So viele Erlebnisse merkt er sich (die ältesten fallen heraus)
const MAX_EXPERIENCES := 5
## Freundschaft & Feindschaft (6.3): Abstand beim Folgen, Reichweite eines Schlags, so lange humpelt er
## nach einem Schlag (langsamer), so stark trifft er dich
const FOLLOW_GAP := 1.8
const PUNCH_REACH := 1.1
const HURT_TIME := 90.0
const HURT_SLOW := 0.7
const PUNCH_INJURY := 0.35
const RUDE_LINES := ["Aus dem Weg!", "Pass doch auf!", "Geh mir aus den Augen.", "Na, wieder unterwegs?"]
const RAMMED_LINES := ["Hey! Spinnst du?", "Au! Pass doch auf!", "Was soll das denn?!"]
const HIT_BACK_LINES := ["Na warte!", "Das wirst du bereuen!", "Jetzt reicht's mir!"]
## An der Bar (Spielkonzept 3.7): so oft trinkt ein Gast etwas, wenn er dort ankommt; so viel zählt Angst
## (0..100 → 0..1) für die Schwäche, nach der sich der Lakengeist seine Opfer sucht (4.18)
const BAR_DRINK := 0.7
## Spieler unter dem Bettlaken (5.9): so dunkel (Director.light_at), dass er einen Gast wirklich erschreckt – und so sehr
const DISGUISE_DARK := 0.25
const DISGUISE_FRIGHT := 20.0
const WEAK_FEAR := 0.6
const HIT_FLEE_LINES := ["Hilfe! Der ist verrückt!", "Lass mich in Ruhe!", "Au! Hör auf!"]
const DECO_KINDS := [Item.Kind.CARVED_PUMPKIN, Item.Kind.SKULL, Item.Kind.SHEET_GHOST, Item.Kind.LIGHT_STRING, Item.Kind.BROOM,
	Item.Kind.BAT_GARLAND, Item.Kind.CANDLE, Item.Kind.COBWEB, Item.Kind.SPIDER, Item.Kind.LEAVES, Item.Kind.PUMPKIN, Item.Kind.MINI_PUMPKIN]
## Essbare Geschenke (6.17), auch Getränkedosen und Kaffee (3.11, auch an der Kaffeemaschine): isst bzw. trinkt er nach
## ein paar Sekunden, statt sie heimzutragen
const FOOD_GIFTS := [Item.Kind.SWEETS, Item.Kind.ROAST_PUMPKIN, Item.Kind.SODA_CAN, Item.Kind.COFFEE, Item.Kind.TEA]
## Eine Tasse Kräutertee (3.12) nimmt so viel Angst – geschenkt oder am Wasserkocher
const TEA_CALM := 15.0
## Kinder (Spielkonzept 6.13): Grundwert an Schwäche für den Lakengeist; so viel Angst bekommen die Eltern,
## wenn ihr Kind erschrickt; so oft rennt ein Kind los (Lärm wie Rennen) und so oft lacht es dabei bzw. auf
## Feiern; so oft kann es in der Nachtruhe nicht schlafen und so lange bleibt es dann wach; so oft schenkt es
## dir etwas, wenn es dich mag
const CHILD_WEAKNESS := 0.5
const CHILD_SCARE_FEAR := 40.0
const CHILD_ROMP := 0.35
const CHILD_LAUGH := Vector2(6.0, 14.0)
const SLEEPLESS_CHANCE := 0.3
const SLEEPLESS_TIME := Vector2(120.0, 240.0)
const CHILD_GIFT := 0.2
## Tagesablauf (Spielkonzept 2.4): Faktoren auf die Vorlieben des Gasts (profile.activities) je Phase der Uhr –
## morgens Küche und Garten, tagsüber wie gewohnt, abends Bar und Lobby, die Zimmer sind dann fast leer
const PHASE_ACTIVITIES := {
	Calendar.Phase.MORNING: {"kitchen": 3.0, "garden": 3.0, "room": 0.7, "bar": 0.1},
	Calendar.Phase.DAY: {"bar": 0.4},
	Calendar.Phase.EVENING: {"room": 0.15, "bar": 3.0, "lobby": 1.5, "kitchen": 0.7, "garden": 0.3},
}
## Monster unterwegs: so nah am eigenen Zimmer rennt er heim (Tür zu), sonst sucht er ein Versteck
const COVER_HOME_RANGE := 80.0
## Haltungen aus Gesprächen (Spielkonzept 6.9, Talk): vorsichtig → mehr im Zimmer, sorglos → mehr unterwegs
const WARY_ACTIVITIES := {"room": 3.0, "wander": 0.3, "garden": 0.4, "bar": 0.6}
const CARELESS_ACTIVITIES := {"room": 0.5, "wander": 1.8, "garden": 1.3}
const CARELESS_LINES := ["Ach, das ist nur der Strom.", "Wieder die alten Leitungen.", "Da war doch nichts, hieß es."]

var id := ""
var profile: Dictionary
var display_name := ""
var relation := 0.0          ## −100 (Feind) … +100 (Freund)
var fear := 0.0              ## 0 … 100, ab 60 Panik
var stock := {}              ## Item.Kind → Anzahl
var home: Dictionary         ## Zimmer-Info vom LevelBuilder
var dead := false
var hiding: HideSpot
var crouching := false
var running := false
var holding_breath := false
var held: Item
var invited := false
## Siegerehrung (Spielkonzept 2.5): im Zustand PARTY dorthin sehen statt zu tanzen (INF = gewöhnliche Feier)
var _gather_look := Vector3.INF
var chat_cooldown := 0.0
var gift_cooldown := 0.0
var monster_line := 0
var expected_deco := 0      ## so viel eigene Deko sollte vor der Tür stehen
var money := 0
var seated := false          ## sitzt am Spieltisch (bzw. steht beim Darts an der Linie)
var game_stand := false      ## Darts: steht statt zu sitzen (Spielkonzept 6.10)
var _dart_throw := 0.0       ## > 0: Wurfbewegung läuft (Sekunden)
var challenge_time := 0.0    ## > 0: hat dich gerade herausgefordert (Sekunden bis es verfällt)
var challenge_cooldown := 0.0
var challenge_game := "dice"  ## wozu er herausfordert: "dice" (Mäxchen), "chess" oder "darts" (Spielkonzept 6.10)
var state := State.IDLE
var gen_seed := -1           ## ≥ 0: zufällig erzeugter Gast (GuestGenerator)
var corpse := false          ## tot, liegt aber noch da (Lakengeist, Spielkonzept 6.12)
var buried := false          ## auf dem Friedhof begraben (Cemetery, Spielkonzept 5.15) – die Leiche ist fort
var ghost_visits := 0        ## so oft kam der Lakengeist schon zu ihm (Stufe, wie beim Spieler)
var drunk := 0.0             ## Rausch (0..1) von der Bar – Stufen in BarTap (Spielkonzept 3.7)
var seen_sights: Array = []  ## Blutlachen und Leichen, die er schon gesehen hat (sight_key)
## Eigene Erlebnisse: {kind (blood/corpse/ghost/ghost_attack), zone, who, at (Director.elapsed), told}
var experiences: Array = []
## Taten zwischen ihm und dem Spieler (6.3): games, gifts_to, gifts_from, hostile, revenge
var deeds := {}
var chat_day := 0            ## Tag des letzten Plauderns
var chats_today := 0         ## nur die ersten zwei Plaudereien am Tag zählen voll
var attack_cooldown := 0.0
var threatened := false      ## hat dir schon gedroht – beim nächsten Mal schlägt er zu
var sleepless := false       ## Kind, das in dieser Nachtruhe nicht schlafen kann (Spielkonzept 6.13)
var singing := false         ## Kind singt das Lied vom Kürbiskopf, während er sich ankündigt (PumpkinMan, 4.19)
var _flee_home := false        ## rennt vor dem Monster heim und macht die Tür zu (take_cover)
## Überlebt (Spielkonzept 6.17): Art der Verletzung ("" = unverletzt, sonst Wounds.KINDS), so lange noch bis geheilt, davon
## noch im Bett; was er als Zeuge weiß (zone, went, visit_day) und wie viel er erzählt hat; ob der Spieler ihn besucht hat
var wound := ""
var wound_left := 0.0
var wound_bed := 0.0
var wound_facts := {}
var wound_told := 0
var wound_visited := false
var wound_note := ""         ## beim nächsten Gespräch: "healed" oder "neglect" (nicht gespeichert)
## Gedächtnis fürs Gespräch (Spielkonzept 6.9, Talk): was der Spieler (oder ein Freund) ihm gesagt hat –
## {topic, zone, who, lie, at, from, hops, src, spread, exposed, believed, stance, value}
var claims: Array = []
## Haltungen daraus: Name → {until (Director.elapsed), …} – wary, careless, distrusts:<id>, brave_thinks, promise,
## no_trust, confront, grieving
var stances := {}
var talk_prev := State.IDLE  ## was er tat, bevor das Gespräch begann (Anlässe, DialogUI)
var _wheeze := 3.0
var _wound_nodes: Array[Node3D] = []   ## Verletzungsmarken am Körper
var _gift_item: Item         ## Geschenk in der Hand (6.17): er trägt es heim bzw. isst es nach _gift_hold Sekunden
var _gift_hold := 0.0

var agent: NavigationAgent3D
var _collider: CollisionShape3D
var _visual: Node3D
var _lod_frame := randi() % LOD_STEP   ## Detailstufe: Bilder seit dem letzten Rechnen (versetzt, damit nicht alle zugleich)
var _lod_time := 0.0          ## … und die Zeit dazwischen
var _lod_scale := 1.0         ## so viele Physikbilder stecken im aktuellen Schritt
var _hand: Node3D
var _arm_l: Node3D
var _arm_r: Node3D
var _body: GuestBody         ## Gastmodell; null = Klötzchenfigur (noch kein passender Grundkörper)
var _head_pivot: Node3D      ## Kopf der Klötzchenfigur (Hut und Kürbis des Kostüms sitzen darauf)
var _costume: Costume        ## Halloween-Kostüm ab dem 25. (Spielkonzept 5.9), null = unverkleidet
var _costume_check := 0.0
var _disguise_seen := 0      ## Player.disguise_count, über das er schon gestaunt hat (5.9)
var _disguise_check := 0.0
var _arms_free := true       ## Gastmodell: Arme schwingen mit der Laufanimation
var _label: Label3D
var _target := Vector3.ZERO
var _timer := 0.0
var _steal_item: Item
var _steal_lamp: Lamp
var _resting := false        ## ruht im Zimmer bei ausgeschaltetem Licht
var _plant: PumpkinPlant
var _hide_spot: HideSpot
var _steal_timer := 0.0
var _monster_cooldown := 0.0
var _panic_quiet := 0.0      ## Panik-Satz nicht ständig wiederholen
var _alarm_cooldown := 0.0
var _run_noise := 0.0
var _warned := false
var _to_bed := false       ## Nachtruhe: auf dem Weg ins eigene Bett
var _flicker_fear := 0.0   ## nach langem Flackern so lange im Versteck bleiben (Sekunden)
var _anim := 0.0
var _dance := -1   ## Index in DANCES bzw. GuestBody.DANCES, -1 = tanzt gerade nicht
var _dance_timer := 0.0
var _game_look := Vector3.ZERO
var _stuck_time := 0.0
var _last_pos := Vector3.ZERO
var _stall_pos := Vector3.ZERO   ## Festgefahren: hier stand er, als er zuletzt vorankam …
var _stall_since := 0.0          ## … seit dieser Spielzeit (Director.elapsed)
var _stall_seen := -10.0         ## letzter Schritt in _move_to (Spielzeit) – wer zwischendurch stand, fängt neu an
var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var _door_timer := 0.0
## Zimmertür, durch die er zuletzt gegangen ist – er schließt sie hinter sich (Spielkonzept 6.19)
var _door_behind: Door = null
var _door_side := 0.0
var _door_wait := 0.0
var _mud := 0
var _bleeding := 0.0
var _step_dist := 0.0
var _foot_side := 1.0
var _trace_pos := Vector3.ZERO
var _steps: Footsteps
var _shock_scan := 0.0
var _shock_look := Vector3.ZERO
var _shock_style := ""
var _entranced := false    ## vom Lakengeist hypnotisiert – bleibt stehen, bis er weg ist
var _door_trance := 0.0    ## Lakengeist vor der Tür: so lange starrt er noch hin, dann geht er aufmachen
var _knock_face := Vector3.INF   ## beim Klopfen dorthin sehen (Tür); INF: wie vor Zimmer 13
var _hurt_time := 0.0      ## geschlagen: humpelt so lange langsamer
var _bump_cooldown := 0.0
var _push := Vector3.ZERO  ## Rückstoß beim Stolpern
var _hit_back := false     ## nach dem Stolpern: zurückschlagen statt fliehen
var _resume_follow := 0.0  ## Begleiter im Gespräch: so lange kommt er danach noch mit
var _romp := false         ## Kind rennt aus Spaß (oder zu Mama und Papa) – Lärm wie beim Rennen
var _laugh := 0.0
var _awake_left := 0.0     ## schlafloses Kind: so lange bleibt es noch wach
var _reach := 0.0          ## Schmücken (5.9): so lange noch die Arme hoch zur Wand


func setup(p_id: String, p_home: Dictionary) -> Guest:
	id = p_id
	profile = GuestProfiles.get_profile(p_id)
	display_name = profile["name"]
	stock = (profile["stock"] as Dictionary).duplicate()
	money = int(profile.get("money", 5))
	home = p_home
	return self


func _ready() -> void:
	add_to_group("time_skip")   # Zeitsprung im Schlaf (SleepSkip)
	collision_layer = 128
	collision_mask = 1 | 16
	set_meta("interactable", self)
	add_to_group("guests")
	_collider = CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.25
	capsule.height = 1.7
	_collider.shape = capsule
	_collider.position.y = 0.85
	add_child(_collider)
	agent = NavigationAgent3D.new()
	agent.radius = 0.3
	agent.height = 1.6
	agent.path_desired_distance = 0.3
	agent.target_desired_distance = 0.4
	agent.path_height_offset = 0.2   # NavMesh liegt ~0,2 m über dem Boden
	add_child(agent)
	_steps = Footsteps.new()
	add_child(_steps)
	_build_visual()
	_steal_timer = randf_range(30.0, 60.0)
	_timer = randf_range(2.0, 6.0)


# --- Für Dialog & Social ------------------------------------------------------

## Kind (Spielkonzept 6.13): nie Opfer, trinkt nicht, kommt immer zu Feiern, schlägt und klaut nicht.
func is_child() -> bool:
	return bool(profile.get("child", false))


## Kernfigur (Spielkonzept 6.0) – handgeschriebenes Profil statt erzeugtem; überlebt jeden Angriff (4.33, 6.17).
func is_core() -> bool:
	return GuestProfiles.ALL.has(id)


## Seine Stimme für SynthAudio.play_shot: "voice" ("m", "f", "child"), "pick" (immer dieselbe Aufnahme),
## "pitch" (Tonhöhe und Tempo, 1 = Aufnahme) und "length" (Anteil des Schreckensschreis, Mutige kürzer).
## Die Kinderaufnahmen sind Mädchen um 8: Jungen klingen tiefer, Siebenjährige höher.
func voice() -> Dictionary:
	var pitch := 1.0 + float(posmod(hash(id + "voice"), 101) - 50) / 50.0 * VOICE_SPREAD
	var key := "child" if is_child() else String(profile.get("sex", "m"))
	if is_child():
		pitch *= (1.05 if int(profile.get("age", 8)) <= 7 else 0.98) * (0.93 if profile.get("sex", "m") == "m" else 1.0)
	else:
		pitch *= float(VOICE_AGE.get(String(profile.get("gen", "mid")), 1.0))
	pitch *= (1.0 + fear / 100.0 * VOICE_FEAR) * (1.0 - drunk * VOICE_DRUNK)
	var length := 1.0 if is_child() else 1.0 - float(profile["brave"]) * VOICE_BRAVE
	return {"voice": key, "pick": posmod(hash(id), 1000), "pitch": pitch, "length": length}


# --- Überlebende & Verletzungen (Spielkonzept 6.17) -------------------------------------------

## Überlebt einen Angriff: verletzt (Wounds.KINDS), merkt sich, wo es war und wohin der Angreifer ging, und erzählt es
## seinen Freunden und den Gästen ringsum. attacker: wohin er danach ging (nach 8 s nachgesehen), null = egal.
func wound_by(kind: String, attacker: Node3D = null) -> void:
	var d := Wounds.data(kind)
	if d.is_empty() or dead:
		return
	wound = kind
	wound_left = float(d["heal"])
	wound_bed = float(d["bed"])
	wound_told = 0
	wound_visited = false
	_bleeding = maxf(_bleeding, float(d["bleed"]))
	fear = maxf(fear, 50.0)   # erschüttert, aber ansprechbar (Panik ab 60)
	var zone := Game.director.zone_name_at(global_position) if Game.director else ""
	wound_facts = {"zone": zone, "went": zone}
	if attacker:
		get_tree().create_timer(8.0, false).timeout.connect(func() -> void:
			if is_instance_valid(attacker) and Game.director:
				wound_facts["went"] = Game.director.zone_name_at(attacker.global_position))
	_update_wound_marks()
	_spread_wound_news()
	if Game.tracing:
		print("[Verletzt] %s überlebt: %s bei %s" % [display_name, d["name"], zone])


func is_hoarse() -> bool:
	return wound != "" and bool(Wounds.data(wound)["hoarse"])


## Liegt er verletzt im eigenen Bett? (ansprechbar, steht dafür nicht auf)
func in_sickbed() -> bool:
	return wound_bed > 0.0 and state == State.SLEEP and hiding != null


## Das nächste Detail, das er als Zeuge erzählt ("" = alles erzählt).
func witness_line() -> String:
	var lines: Array = Wounds.WITNESS.get(wound, [])
	if wound_told >= lines.size():
		return ""
	var zone := String(wound_facts.get("zone", ""))
	var went := String(wound_facts.get("went", ""))
	var text := String(lines[wound_told]).format({"zone": zone if zone != "" else "hier", "went": went if went != "" else "irgendwohin"})
	wound_told += 1
	return text


## Freunde und Gäste ringsum erfahren davon: Angst steigt, sie erzählen es weiter (Erlebnis „survivor_<art>“).
func _spread_wound_news() -> void:
	var told: Array = Game.social.pals.pals_of(self)
	for g in Game.social.living_guests():
		if g != self and not g in told and g.global_position.distance_to(global_position) < Wounds.SPREAD_RANGE:
			told.append(g)
	for g: Guest in told:
		g.fear = minf(100.0, g.fear + Wounds.SPREAD_FEAR)
		g.remember("survivor_" + wound, global_position, display_name)


func _wound_step(delta: float) -> void:
	if wound == "":
		return
	wound_left -= delta
	if wound_bed > 0.0:
		wound_bed -= delta
		if wound_bed <= 0.0:
			if state == State.SLEEP and not Game.social.sleep_active:
				wake_up()   # der erste Tag im Bett ist vorbei
		elif state in [State.IDLE, State.WALK] and not _to_bed and hiding == null and fear < 60.0 and _gift_item == null:
			_go_to_bed()   # erst einmal ins Bett
	if is_hoarse():
		_wheeze -= delta
		if _wheeze <= 0.0:
			_wheeze = randf_range(Wounds.WHEEZE_GAP.x, Wounds.WHEEZE_GAP.y)
			Game.sound_at("wheeze", global_position, Wounds.WHEEZE_RANGE, self, 0.8)   # schweres Atmen
	if wound_left <= 0.0:
		_heal()


## Geheilt: Wer befreundet ist und ihn nie besucht hat, ist gekränkt.
func _heal() -> void:
	var neglected := not wound_visited and Social.tier(self) >= Social.Tier.FRIEND
	wound = ""
	wound_bed = 0.0
	wound_note = "neglect" if neglected else ("healed" if wound_visited else "")
	if neglected:
		Game.social.change_relation(self, Wounds.NEGLECT)
	_update_wound_marks()
	if state == State.SLEEP and not Game.social.sleep_active:
		wake_up()


## Zeitsprung im Schlaf (SleepSkip, Spielkonzept 3.6): Angst, Rausch, Pausen und Wunden um dt.
## Was danach fällig ist (geheilt, aufstehen, Herausforderung verstrichen), meldet das nächste Bild.
func skip_time(dt: float) -> void:
	if dead:
		return
	fear = maxf(0.0, fear - dt * 0.4)
	drunk = maxf(0.0, drunk - dt / BarTap.SOBER_TIME)
	chat_cooldown = maxf(0.0, chat_cooldown - dt)
	challenge_cooldown = maxf(0.0, challenge_cooldown - dt)
	gift_cooldown = maxf(0.0, gift_cooldown - dt)
	_hurt_time = maxf(0.0, _hurt_time - dt)
	if challenge_time > 0.0:
		challenge_time = maxf(0.001, challenge_time - dt)
	if wound != "":
		wound_left = maxf(0.001, wound_left - dt)
		if wound_bed > 0.0:
			wound_bed = maxf(0.001, wound_bed - dt)
	if _awake_left > 0.0:
		_awake_left = maxf(0.001, _awake_left - dt)


## Gegessen bzw. heimgetragen nach Wounds.GIFT_HEAL … – Geschenke und Besuche lassen ihn schneller heilen.
func speed_healing(seconds: float) -> void:
	if wound == "":
		return
	wound_left = maxf(1.0, wound_left - seconds)
	wound_bed = minf(wound_bed, wound_left) if wound_bed > 0.0 else 0.0


## Sichtbar am Körper: Kratzer im Gesicht und am Arm, Verband am Bein, dunkle Male am Hals.
func _update_wound_marks() -> void:
	for n in _wound_nodes:
		if is_instance_valid(n):
			n.queue_free()
	_wound_nodes.clear()
	if wound == "" or _visual == null:
		return
	var red := Mat.psx(Color(0.45, 0.04, 0.04))
	match wound:
		"scratch":
			var face := _mark_root("Head", Vector3(0, 1.62, 0))
			for i in 3:
				var line := Geo.mesh(face, Geo.box(Vector3(0.009, 0.06, 0.01)), red, Vector3(0.035 + i * 0.014, 0.045, 0.095))
				line.rotation.z = 0.5
			var arm := _mark_root("LeftForeArm", Vector3(0.25, 1.1, 0))
			for i in 3:
				var line := Geo.mesh(arm, Geo.box(Vector3(0.012, 0.09, 0.012)), red, Vector3(0.045, 0.08 + i * 0.03, 0.01 * i))
				line.rotation.x = 0.6
		"axe":
			var leg := _mark_root("LeftLeg", Vector3(0.1, 0.35, 0))
			Geo.mesh(leg, Geo.cylinder(0.078, 0.15, 8), Mat.psx(Color(0.92, 0.9, 0.84)), Vector3(0, 0.2, 0))
			Geo.mesh(leg, Geo.cylinder(0.081, 0.04, 8), red, Vector3(0, 0.19, 0))   # durchgeblutet
			var thigh := _mark_root("LeftUpLeg", Vector3(0.1, 0.7, 0))
			Geo.mesh(thigh, Geo.cylinder(0.092, 0.1, 8), red, Vector3(0, 0.36, 0))   # Blut auf der Hose
		"choke":
			var neck := _mark_root("Neck", Vector3(0, 1.48, 0))
			Geo.mesh(neck, Geo.cylinder(0.062, 0.035, 8), Mat.psx(Color(0.35, 0.12, 0.2)), Vector3(0, 0.04, 0))


## Knoten für die Verletzungsmarken: am Knochen des Gastmodells, bei der Klötzchenfigur in dieser Höhe.
func _mark_root(bone: String, fallback: Vector3) -> Node3D:
	var root: Node3D = _body.attach(bone) if _body else null
	if root == null:
		root = Node3D.new()
		root.position = fallback
		_visual.add_child(root)
	_wound_nodes.append(root)
	return root


# --- Geschenke in der Hand (6.17, gilt für alle Gäste) ----------------------------------------

## Ein Geschenk des Spielers: Er nimmt es in die Hand. false = Hände voll (dann wandert es wie früher in den Vorrat).
func receive_gift(item: Item) -> bool:
	if held != null or item == null:
		return false
	_take_into_hand(item)
	_gift_item = item
	var food := item.kind in FOOD_GIFTS
	_gift_hold = randf_range(8.0, 14.0) if food else randf_range(25.0, 40.0)
	return true


## Nach dem Gespräch: mit dem Geschenk heim (CARRY_HOME legt es in den Vorrat). false = nichts zu tragen.
func _carry_gift_home() -> bool:
	if _gift_item == null or held != _gift_item or _gift_item.kind in FOOD_GIFTS:
		return false
	_gift_item = null
	_walk_to(_room_point(), State.CARRY_HOME)
	return true


func _gift_step(delta: float) -> void:
	if _gift_item == null:
		return
	if not is_instance_valid(_gift_item) or held != _gift_item:
		_gift_item = null   # fallen gelassen, abgelegt, heimgebracht
		return
	_gift_hold -= delta
	if _gift_hold > 0.0 or state == State.TALKING:
		return
	var item := _gift_item
	_gift_item = null
	if item.kind in FOOD_GIFTS:
		held = null
		item.queue_free()   # aufgegessen
		if item.kind == Item.Kind.TEA:
			fear = maxf(0.0, fear - TEA_CALM)   # Kräutertee beruhigt (3.12)
		if randf() < 0.5:
			say({Item.Kind.SWEETS: "Mmh.", Item.Kind.SODA_CAN: "Ahh, schön kalt.", Item.Kind.COFFEE: "Jetzt bin ich wach.",
				Item.Kind.TEA: "Ah, das tut gut."}.get(item.kind, "Das war lecker."))
	elif state in [State.IDLE, State.WALK]:
		_walk_to(_room_point(), State.CARRY_HOME)
	else:
		stow_held()   # im Bett oder anderweitig beschäftigt: wandert in den Vorrat


## Mama oder Papa eines Kindes – null, wenn er kein Kind ist oder sie nicht mehr da sind.
func parent_guest() -> Guest:
	if not is_child() or Game.social == null:
		return null
	var parent := Game.social.guest_by_id(String(profile.get("parent", "")))
	return parent if parent and not parent.dead else null


func is_orphan() -> bool:
	return is_child() and parent_guest() == null


func get_prompt(_player: Player) -> String:
	if dead:
		if not corpse:
			return ""
		if Game.cemetery and Game.cemetery.can_bury(self):   # selbst beerdigen (5.15)
			return "%s – tot · beerdigen [E]" % display_name
		return "%s – tot" % display_name   # Leiche (Ghost, Kürbismann): mit Totenkopf, get_icon
	if (hiding and not in_sickbed()) or state == State.GHOSTED:
		return ""
	if singing:
		return "%s singt und hört dich nicht [E]" % display_name
	var sweets := Game.social.trick_sweets_given(self) if Game.social else -1
	if sweets >= 0 and _player.has_kind(Item.Kind.SWEETS):   # Süßes oder Saures an Zimmer 13 (6.13)
		return "%s eine Süßigkeit geben (%d/%d) [E]" % [display_name, sweets + 1, Social.TRICK_SWEETS_MAX]
	return "Mit %s sprechen [E]  (%s)" % [display_name, Social.relation_word(relation)]


## Aktions-Symbol über dem Hinweis (IconArt): Totenkopf an der Leiche.
func get_icon(_player: Player) -> String:
	return "dead" if dead else ""


func interact(_player: Player) -> void:
	if dead and corpse and Game.cemetery and Game.cemetery.can_bury(self):
		Game.cemetery.bury_by_player(self)
		return
	if singing and Game.pumpkin:
		say(Game.pumpkin.song_line())   # antwortet nur mit der nächsten Liedzeile
		return
	if Game.social and Game.social.give_trick_sweet(self):
		return
	if not dead and (not hiding or in_sickbed()) and state != State.GHOSTED and Game.dialog:
		Game.dialog.open(self)


func begin_talk() -> void:
	talk_prev = state
	if in_sickbed():
		return   # bleibt liegen (6.17)
	_resume_follow = _timer if state == State.FOLLOW else 0.0
	state = State.TALKING


func end_talk() -> void:
	if state != State.TALKING:
		return
	if _resume_follow > 0.0:
		_timer = _resume_follow   # ein Begleiter kommt nach dem Gespräch weiter mit
		_resume_follow = 0.0
		state = State.FOLLOW
	elif not _carry_gift_home():
		_set_idle(randf_range(2.0, 5.0))


func say(text: String) -> void:
	if is_hoarse():
		text = "*heiser* " + text   # Würgemale (6.17)
	if Game.player and Game.player.global_position.distance_to(global_position) < 14.0:
		Game.say("%s: „%s“" % [display_name, text], 4.0)


## Panik-Satz – höchstens alle 45 s, sonst klingt er wie eine Schallplatte mit Sprung.
func say_panic() -> void:
	if _panic_quiet > 0.0:
		return
	_panic_quiet = 45.0
	say(line("panic"))


func line(key: String) -> String:
	return GuestProfiles.line(profile, key)


## An Zimmer 13 klopfen (Spielkonzept 4.13). Die Tür ist zu – ist der Gast weit weg,
## steht er einfach schon davor.
func start_knock(door_front: Vector3) -> void:
	if hiding:
		_leave_hide()
	_drop_held()
	if global_position.distance_to(door_front) > 6.0:
		global_position = door_front + Vector3(randf_range(-0.3, 0.3), 0.05, -0.15)
	_target = door_front
	fear = maxf(fear, 70.0)
	_knock_face = Vector3.INF
	state = State.KNOCK


## Der Spieler hat aufgemacht: hinein ins Zimmer 13, dort eine Weile bleiben.
func enter_shelter(room_center: Vector3) -> void:
	_target = room_center + _jitter(0.8)
	_timer = randf_range(25.0, 45.0)
	fear = maxf(0.0, fear - 30.0)
	state = State.SHELTER


## Harmloser Angriff: zu Tode erschrocken, aber nicht geholt – rennt davon. Ist er verletzt (auch gerade eben beim
## Losreißen, wound_by), bleibt es bei der Blutspur der Verletzung (Spielkonzept 6.17).
func scared_by_monster() -> void:
	if dead:
		return
	if hiding:
		_leave_hide()
	fear = 100.0
	say_panic()
	if randf() < 0.6 and not is_child() and wound == "":
		_bleeding = BLEED_TIME   # verletzt – hinterlässt Blutstropfen
	if randf() < 0.35:
		_lose_coins()
	_monster_cooldown = 10.0
	_go_hide()


## Zur Feier auf seinen Platz – oder mit look zur Siegerehrung (Spielkonzept 2.5): dort stehen und dorthin sehen,
## ohne zu tanzen.
func join_party(spot: Vector3, look := Vector3.INF) -> void:
	if dead or hiding or fear >= 60.0:
		return
	_drop_held()
	_target = spot
	_gather_look = look
	state = State.PARTY


## Zum Spieltisch gehen und hinsetzen (Minispiel).
func sit_for_game(seat: Vector3, look: Vector3) -> void:
	_drop_held()
	_target = seat
	_game_look = look
	seated = false
	game_stand = false
	state = State.MINIGAME


## An die Abwurflinie gehen und dort stehen bleiben (Darts) – sonst wie sit_for_game.
func stand_for_game(spot: Vector3, look: Vector3) -> void:
	sit_for_game(spot, look)
	game_stand = true


## Einen Pfeil werfen: Arm hoch, kurz zurück, nach vorn (Darts).
func throw_dart_pose() -> void:
	_dart_throw = DART_THROW_TIME


func end_game() -> void:
	seated = false
	game_stand = false
	if state == State.MINIGAME:
		_set_idle(randf_range(3.0, 8.0))


func leave_party() -> void:
	if state == State.PARTY:
		_set_idle(randf_range(2.0, 6.0))
	invited = false


## Sieht dieser Gast den Akteur? 5 m × Auffälligkeit, 180°, abgelenkt ×0,6 (Spielkonzept 4.15).
## Für Zeugen beim Diebstahl.
func can_see_actor(actor) -> bool:
	if dead or hiding or actor == null or actor.dead or actor.hiding != null:
		return false
	var base := Senses.GUEST_SIGHT * (Senses.DISTRACTED if is_distracted() else 1.0)
	return Senses.can_see(self, global_position + Vector3.UP * 1.6, -global_transform.basis.z,
		base, Senses.GUEST_FOV_DOT, actor)


## Abgelenkt: im Gespräch, beim Würfeln, auf der Feier, in Panik.
func is_distracted() -> bool:
	return state in [State.TALKING, State.MINIGAME, State.PARTY] or fear >= 60.0


## Ein erschreckendes Geräusch gehört (Spielkonzept 4.15). Ängstliche geraten in Panik,
## Mutige sehen nach, die anderen erzählen davon. Gibt die Reaktion zurück (Debug), sonst "".
func hear_alarm(pos: Vector3) -> String:
	if dead or hiding or _alarm_cooldown > 0.0 or state in [State.TALKING, State.MINIGAME, State.KNOCK, State.SHELTER, State.HIDE_GO, State.SHOCKED, State.GHOSTED, State.STAGGER, State.ATTACK]:
		return ""
	_alarm_cooldown = ALARM_COOLDOWN
	var brave := float(profile["brave"])
	fear = minf(100.0, fear + ALARM_FEAR * (1.2 - brave))
	if fear >= 60.0:
		say_panic()
		_go_hide()
		return "Panik"
	if state == State.PARTY:
		return "erschrickt"
	say(ALARM_LINES.pick_random())
	if randf() < brave:
		_drop_held()
		_walk_to(pos, State.WALK)
		return "sieht nach"
	return "erzählt davon"


## Streichelt eine Hotelkatze im Vorbeigehen (Spielkonzept 6.11) – das beruhigt.
func pet_cat(cat: HotelCat) -> void:
	fear = maxf(0.0, fear - 15.0)
	_set_idle(randf_range(2.5, 4.0))
	var to := cat.global_position - global_position
	rotation.y = atan2(-to.x, -to.z)
	if randf() < 0.4:
		say(["Na, %s?", "Na du, %s.", "Hallo %s, meine Schöne.", "%s! Komm her."].pick_random() % cat.display_name)


## Wandstelle an der eigenen Tür (Flurseite) für aufgehängte Deko (Spielkonzept 5.6): Lichterkette über der
## Tür, Lakengespenst und Spinnweben daneben, abwechselnd links und rechts. {point, out[, length]}
func door_hang_spot(kind: int) -> Dictionary:
	var door: Door = home["door"]
	var into: Vector3 = home["into"]
	var along: Vector3 = home["along"]
	var c := door.center()
	var face := Vector3(c.x, door.global_position.y, c.z) - into * (LevelBuilder.T / 2.0)
	var hung := _deco_near_door().filter(func(i: Item) -> bool: return i.hung)
	if kind == Item.Kind.LIGHT_STRING and not hung.any(func(i: Item) -> bool: return i.kind == Item.Kind.LIGHT_STRING):
		return {"point": face + Vector3.UP * (door.height + 0.12), "out": -into, "length": door.width + 1.0}
	var hung_here := hung.size()
	var side := 1.0 if (hung_here + id.length()) % 2 == 0 else -1.0
	var up: float = {Item.Kind.SHEET_GHOST: 2.15, Item.Kind.BAT_GARLAND: 2.25, Item.Kind.SPIDER: 2.35, Item.Kind.BROOM: 0.0}.get(kind, 1.9)
	var beside := door.width / 2.0 + (0.75 if kind == Item.Kind.BAT_GARLAND else 0.45)
	return {"point": face + along * side * beside + Vector3.UP * up, "out": -into}


## Deko vor der eigenen Tür, egal von wem (Mitbewohner schmücken dieselbe Tür, 6.20).
func _deco_near_door() -> Array[Item]:
	var result: Array[Item] = []
	var door_front: Vector3 = home["door_front"]
	for node in get_tree().get_nodes_in_group("items"):
		var item := node as Item
		var flat := Vector2(item.global_position.x - door_front.x, item.global_position.z - door_front.z)
		if item.owner_id != "" and not item.is_held and flat.length() < 2.5 and absf(item.global_position.y - door_front.y) < 3.0:
			result.append(item)
	return result


## Wohnt other im selben Haushalt (HAUSHALTE.md, Spielkonzept 6.20)?
func housemate_of(other: Guest) -> bool:
	return other != null and other != self and profile.has("household") \
		and String(other.profile.get("household", "")) == String(profile["household"])


## Erster lebender Erwachsener des Zimmers (Social.household_lead): er schmückt die Tür und kümmert sich um die Lampen.
func is_household_lead() -> bool:
	return Game.social == null or Game.social.household_lead(home["no"]) == self


## Ein anderer aus dem Zimmer ist wach und zu Hause.
func _housemate_awake() -> bool:
	if Game.social == null:
		return false
	var c: Vector3 = home["center"]
	for g in Game.social.guests:
		if g != self and not g.dead and g.home["no"] == home["no"] and not g.is_asleep() \
				and absf(g.global_position.y - c.y) < 1.5 and g.global_position.distance_to(c) < HOME_RADIUS:
			return true
	return false


## Gehört der Gegenstand jemandem aus demselben Zimmer?
func _housemate_item(item: Item) -> bool:
	if item.owner_id == "" or item.owner_id == "player":
		return false
	return String(GuestProfiles.get_profile(item.owner_id).get("room", "")) == String(home["no"])


func own_deco_near_door() -> Array[Item]:
	var result: Array[Item] = []
	var door_front: Vector3 = home["door_front"]
	for node in get_tree().get_nodes_in_group("items"):
		var item := node as Item
		var flat := Vector2(item.global_position.x - door_front.x, item.global_position.z - door_front.z)
		if item.owner_id == id and not item.is_held and flat.length() < 2.5 and absf(item.global_position.y - door_front.y) < 3.0:
			result.append(item)
	return result


## cause "monster": er verschwindet, zurück bleiben Kratzer und ein Schuh. "ghost": vom Lakengeist
## erwürgt – er bleibt liegen (Spielkonzept 6.12). "pumpkin": vom Kürbismann erschlagen – er bleibt in
## einer Blutlache liegen (4.19).
func die(cause: String = "monster") -> void:
	if dead:
		return
	dead = true
	if hiding:
		hiding.release(self)
		hiding = null
	_drop_held()
	_release_hide_spot()
	state = State.DEAD
	_collider.disabled = true
	collision_layer = 0
	_label.visible = false
	for node in get_tree().get_nodes_in_group("items"):
		var item := node as Item
		if item.owner_id == id:
			item.owner_id = ""
	if cause == "pumpkin" and Game.traces:
		Game.traces.add_blood(global_position, randf() * TAU)
		Game.traces.add_wall_blood(global_position, "wall_splatter")
	if cause in ["ghost", "pumpkin"]:
		_lie_down()
		return
	if cause == "buried":   # Spielstand: liegt schon auf dem Friedhof (5.15)
		corpse = true
		bury()
		return
	visible = false
	# Spuren statt Gore: Kratzer am Boden und ein einzelner Schuh
	var traces := Node3D.new()
	get_parent().add_child(traces)
	traces.global_position = global_position
	for i in 3:
		var scratch := Geo.mesh(traces, Geo.box(Vector3(1.1, 0.01, 0.05)), Mat.psx(Color(0.12, 0.02, 0.02)), Vector3(0, 0.012, -0.12 + i * 0.12))
		scratch.rotation.y = 0.3
	Geo.mesh(traces, Geo.box(Vector3(0.12, 0.08, 0.26)), Mat.psx(profile["pants"]), Vector3(0.5, 0.04, 0.3))


## Begraben (Cemetery, Spielkonzept 5.15): Die Leiche ist fort – nichts mehr zu sehen, zu erschrecken, anzusehen.
func bury() -> void:
	if not corpse:
		return
	corpse = false
	buried = true
	visible = false
	remove_from_group("shock_sights")
	if has_node("CorpseTouch"):
		get_node("CorpseTouch").queue_free()


## Leiche: auf den Rücken gekippt, Arme zur Seite. Andere Gäste erschrecken davor (Gruppe shock_sights).
func _lie_down() -> void:
	corpse = true
	visible = true
	velocity = Vector3.ZERO
	_arm_l.rotation = Vector3(0, 0, -0.5)
	_arm_r.rotation = Vector3(0, 0, 0.4)
	if _body:
		_body.animate(0.0, 0.0, false, [_arm_l, _arm_r], false, false)
	_visual.position = Vector3(0, 0.13, 0)
	_visual.rotation = Vector3(PI / 2.0, 0, 0.08)
	# Auf der Treppe an die Schräge anlegen, sonst schwebt er über den unteren Stufen
	var under := get_world_3d().direct_space_state.intersect_ray(
		PhysicsRayQueryParameters3D.create(global_position + Vector3.UP * 0.5, global_position + Vector3.DOWN, 1, [get_rid()]))
	if not under.is_empty() and (under["normal"] as Vector3).y < 0.98 and (under["normal"] as Vector3).y > 0.1:
		global_basis = Basis(Quaternion(Vector3.UP, (under["normal"] as Vector3).normalized())) * global_basis
	set_meta("sight_key", "corpse:" + id)
	set_meta("sight_kind", "corpse")
	add_to_group("shock_sights")
	# Der Körper hat keine Kollision mehr – damit man die Leiche ansehen kann („… – tot“), ein flacher Kasten auf
	# Ebene 4 (Gegenstände, Schalter: hält nichts auf, nur der Interaktionsstrahl trifft ihn), so lang wie der Gast
	if not has_node("CorpseTouch"):
		var touch := StaticBody3D.new()
		touch.name = "CorpseTouch"
		touch.collision_layer = 4
		touch.collision_mask = 0
		touch.set_meta("interactable", self)
		var length := eye_height() + 0.15
		Geo.add_box_shape(touch, Vector3(0.5, 0.25, length), Vector3(0, 0.13, length / 2.0))
		add_child(touch)


# --- Ablauf ---------------------------------------------------------------------

func _physics_process(delta: float) -> void:
	if dead:
		return
	_lod_time += delta
	_lod_frame += 1
	if _lod_frame < LOD_STEP and _lod_far():
		return
	_lod_scale = maxf(1.0, _lod_time / maxf(delta, 0.0001))   # nie 0 – _move_to teilt dadurch
	delta = _lod_time
	_lod_time = 0.0
	_lod_frame = 0
	_animate(delta)
	_update_label()
	_update_costume(delta)
	_notice_disguise(delta)
	_leave_traces(delta)
	_wound_step(delta)
	_gift_step(delta)
	fear = maxf(0.0, fear - delta * 0.4)
	drunk = maxf(0.0, drunk - delta / BarTap.SOBER_TIME)
	chat_cooldown = maxf(0.0, chat_cooldown - delta)
	challenge_cooldown = maxf(0.0, challenge_cooldown - delta)
	if challenge_time > 0.0:
		challenge_time -= delta
		if challenge_time <= 0.0:
			Game.social.on_challenge_ignored(self)
	gift_cooldown = maxf(0.0, gift_cooldown - delta)
	_monster_cooldown -= delta
	_panic_quiet -= delta
	_alarm_cooldown -= delta
	_hurt_time = maxf(0.0, _hurt_time - delta)
	_bump_cooldown -= delta
	attack_cooldown = maxf(0.0, attack_cooldown - delta)
	if _hide_spot and state != State.HIDE_GO:
		_release_hide_spot()   # Weg ins Versteck abgebrochen (Gespräch, Schreck, Klopfen …)
	if singing and not state in [State.SLEEP, State.HIDING, State.GHOSTED, State.TALKING, State.DEAD]:
		# Der Kürbiskopf kündigt sich an: Das Kind bleibt stehen, sieht zur Lobby und singt
		_stop(delta)
		_face(Game.social.builder.lobby_center, delta)
		_open_doors(delta)
		return
	match state:
		State.TALKING:
			_stop(delta)
			if Game.player:
				_face(Game.player.global_position, delta)
			return
		State.HIDING:
			_hiding_step(delta)
			return
		State.SLEEP:
			# schläft – bemerkt nichts (kein Rauschen, kein Monster) bis zum Ende der Nachtruhe
			if not Game.social.sleep_active and wound_bed <= 0.0:
				wake_up()
			return
		State.KNOCK:
			# klopft an eine Tür (meist Zimmer 13) und wartet, dass jemand aufmacht
			_stop(delta)
			_face(_knock_face if _knock_face != Vector3.INF else _target + Vector3(0, 0, 1.0), delta)
			return
		State.SHELTER:
			# Schutz in Zimmer 13 gefunden – eine Weile bleiben
			if _move_to(_target, WALK_SPEED, delta):
				_timer -= delta
				if _timer <= 0.0:
					_set_idle(randf_range(2.0, 5.0))
			_open_doors(delta)
			return
		State.GHOSTED:
			# Der Lakengeist hält ihn am Hals (SheetGhost) – bis er sich losreißt oder stirbt
			_stop(delta)
			return
		State.STAGGER:
			# gerammt oder geschlagen: taumelt zurück, dann flieht er oder schlägt zurück
			velocity = Vector3(_push.x, 0.0 if is_on_floor() else velocity.y - _gravity * delta, _push.z)
			_push = _push.move_toward(Vector3.ZERO, 8.0 * delta)
			move_and_slide()
			_timer -= delta
			if _timer <= 0.0:
				_after_stagger()
			return
	_watch_monster()
	_scan_for_shock(delta)
	running = state == State.HIDE_GO or ((_romp or _flee_home) and state == State.WALK)
	if is_child():
		_child_step(delta)
	if running:
		# Wer in Panik rennt, macht Lärm (6.5, 4.15)
		_run_noise -= delta
		if _run_noise <= 0.0:
			_run_noise = 0.6
			Game.noise("run", global_position, self)
	var speed := (RUN_SPEED if running and can_run() else WALK_SPEED) * _speed_factor()
	match state:
		State.IDLE:
			_stop(delta)
			_timer -= delta
			_steal_timer -= delta
			if _steal_timer <= 0.0:
				_steal_timer = randf_range(30.0, 60.0)
				if _try_steal():
					return
			if _timer <= 0.0:
				_next_activity()
		State.PARTY:
			# Die letzten Schritte genau auf den eigenen Platz – _move_to hört 0,6 m davor auf, dann
			# stünden Nachbarn zu dicht (Gäste gehen durcheinander durch)
			var rest := Vector2(_target.x - global_position.x, _target.z - global_position.z)
			if rest.length() > 0.1 and rest.length() < 0.6:
				var step := rest.normalized() * minf(WALK_SPEED * 0.6, rest.length() / maxf(delta, 0.001))
				velocity = Vector3(step.x, 0.0 if is_on_floor() else velocity.y - _gravity * delta, step.y)
				move_and_slide()
			elif _move_to(_target, WALK_SPEED, delta):
				_face(_gather_look if _gather_look.is_finite() else Game.social.party_center(), delta)
		State.MINIGAME:
			if seated:
				_stop(delta)
				_face(_game_look, delta)
			elif _move_to(_target, WALK_SPEED, delta):
				global_position = Vector3(_target.x, global_position.y, _target.z)
				seated = true
		State.SHOCKED:
			_stop(delta)
			_face(_shock_look, delta)
			if _door_trance > 0.0:
				_door_trance -= delta
				if _door_trance <= 0.0:
					if _company_at_home():
						_door_trance = randf_range(8.0, 15.0)   # wird zurückgehalten
					else:
						_entranced = false
						_walk_to(home["door_inside"], State.WALK)   # geht aufmachen (_open_doors)
						if Game.tracing:
							print("[Lakengeist] %s geht zur Tür" % display_name)
						return
			_timer -= delta
			if _timer <= 0.0 and not _entranced:
				_after_shock()
		State.FOLLOW:
			_follow_step(delta)
		State.ATTACK:
			_attack_step(delta)
		_:
			# Wütende Gäste halten im Vorbeigehen auf dich zu, um dich anzurempeln (6.3)
			var goal := _target
			if _wants_to_bump():
				goal = Game.player.global_position
			if _move_to(goal, speed, delta) and goal == _target:
				_arrive()
			elif state in [State.HIDE_GO, State.WALK] and _stalled():
				_give_up_walk()
			_check_bump()
	_open_doors(delta)


# --- Freundschaft & Feindschaft (Spielkonzept 6.3) ------------------------------------

func is_following() -> bool:
	return state == State.FOLLOW or (state == State.TALKING and _resume_follow > 0.0)


## Mitkommen: bleibt etwa FOLLOW_GAP hinter dir, rennt, wenn du davonläufst.
func start_follow(duration: float = 120.0) -> void:
	if dead or hiding:
		return
	if state == State.PARTY:
		leave_party()
	_timer = duration
	state = State.FOLLOW


func stop_follow(text: String = "") -> void:
	if not is_following():
		return
	_resume_follow = 0.0
	if text != "":
		say(text)
	if state == State.FOLLOW:
		_set_idle(randf_range(2.0, 5.0))


func _follow_step(delta: float) -> void:
	var p := Game.player
	_timer -= delta
	if p == null or p.dead or _timer <= 0.0:
		stop_follow("Ich geh dann mal wieder.")
		return
	if p.hiding:
		stop_follow("Ich such mir selbst ein Versteck …")
		_go_hide()   # und tut es auch – ein freies Versteck in der Nähe, sonst ins eigene Zimmer
		return
	if p.sleeping:
		stop_follow("Schlaf gut.")
		return
	var d := global_position.distance_to(p.global_position)
	if d > 25.0:
		stop_follow("Wo bist du denn hin?")
		return
	if d > FOLLOW_GAP:
		_move_to(p.global_position, (RUN_SPEED if d > 5.0 else WALK_SPEED * 1.4) * _speed_factor(), delta)
	else:
		_stop(delta)
		_face(p.global_position, delta)


## Besuch in Zimmer 13: hingehen, dann klopft er (Social.on_visit_arrived).
func start_visit(door_front: Vector3) -> void:
	if dead or hiding:
		return
	_walk_to(door_front, State.VISIT)


## Steht vor einer Tür (meist Zimmer 13) und klopft höflich (kein Panik-Klopfen); face: dorthin sehen.
func knock_politely(face: Vector3 = Vector3.INF) -> void:
	_drop_held()
	_knock_face = face
	state = State.KNOCK


## Arme hoch zur Wand (Schmücken, Spielkonzept 5.9) – für t Sekunden.
func reach_up(t: float) -> void:
	_reach = t


func end_visit() -> void:
	if state == State.KNOCK:
		_set_idle(randf_range(2.0, 5.0))


## Auf den Spieler losgehen und zuschlagen (Erzfeind oder Vergeltung). Läufst du weg, gibt er auf.
func start_attack(duration: float = 12.0) -> void:
	if dead or hiding:
		return
	if state == State.PARTY:
		leave_party()
	_drop_held()
	_timer = duration
	state = State.ATTACK


func _attack_step(delta: float) -> void:
	var p := Game.player
	_timer -= delta
	if p == null or p.dead or p.hiding or p.in_dialog or _timer <= 0.0:
		_set_idle(randf_range(3.0, 6.0))
		return
	if global_position.distance_to(p.global_position) > PUNCH_REACH:
		_move_to(p.global_position, RUN_SPEED * 0.95 * _speed_factor(), delta)
		return
	_stop(delta)
	_face(p.global_position, delta)
	p.hurt(PUNCH_INJURY, global_position)
	Game.social.on_guest_hit_player(self)
	_bump_cooldown = 60.0
	_walk_to(_room_point(), State.WALK)


## Gerammt (hit = false) oder geschlagen (hit = true): taumelt zurück. Danach – je nach Mut, Stolz
## und Beziehung – weiter, weg oder zurückschlagen.
func stagger(push: Vector3, hit: bool) -> void:
	if dead or hiding or state in [State.GHOSTED, State.SLEEP]:
		return
	if state == State.PARTY:
		leave_party()
	_drop_held()
	_push = push
	_timer = 0.9 if hit else 0.6
	_hit_back = false
	state = State.STAGGER
	if not hit:
		say("Aua! *weint*" if is_child() else RAMMED_LINES.pick_random())
		return
	_hurt_time = HURT_TIME
	var brave := float(profile["brave"])
	var pride := float((profile["dice"] as Dictionary).get("pride", 0.5))
	fear = minf(100.0, fear + 35.0 * (1.2 - brave))
	_hit_back = brave >= 0.55 or pride >= 0.65 or Social.tier(self) <= Social.Tier.ENEMY
	say((HIT_BACK_LINES if _hit_back else HIT_FLEE_LINES).pick_random())


func _after_stagger() -> void:
	if _hit_back:
		_hit_back = false
		start_attack(8.0)
	elif is_child():
		_run_to_parent()   # umgerannt: weinend zu Mama oder Papa
	elif _hurt_time > 0.0:
		fear = maxf(fear, 70.0)
		_go_hide()
	else:
		_set_idle(randf_range(1.0, 3.0))


## Ein Glas (Bar oder Runde vom Spieler, Spielkonzept 3.7): nimmt Angst, macht betrunken.
func drink() -> void:
	if is_child():
		return   # Kinder trinken nie (6.13)
	drunk = minf(1.0, drunk + BarTap.DRINK)
	fear = maxf(0.0, fear - BarTap.CALM * 100.0)


## An der Bar: wer gerade daneben steht, trinkt mit – einer davon zählt als gemeinsame Tat (Spielkonzept 6.16).
func _drink_with_someone() -> void:
	var near := Game.social.living_guests().filter(func(g: Guest) -> bool:
		return g != self and not g.is_child() and g.state in [State.IDLE, State.WALK] and g.global_position.distance_to(global_position) < 3.0)
	if not near.is_empty():
		Game.social.pals.note(self, near.pick_random())


## Wie angreifbar der Gast gerade ist (0..1) – danach sucht sich der Lakengeist seine Opfer (4.18).
func weakness() -> float:
	return clampf(fear / 100.0 * WEAK_FEAR + drunk + (CHILD_WEAKNESS if is_child() else 0.0)
		+ (Wounds.CHOKE_WEAKNESS if wound == "choke" else 0.0), 0.0, 1.0)


func _speed_factor() -> float:
	var f := HURT_SLOW if _hurt_time > 0.0 else 1.0
	if state == State.DECORATE and Game.social.decorating.strolls(self):
		f *= Decorating.SOLO_STROLL   # schlendert mit Deko durchs Hotel (5.9)
	if wound != "":
		f *= float(Wounds.data(wound)["speed"])   # humpelt (6.17)
	return f


## Mit einer Axtwunde rennt er nicht (6.17).
func can_run() -> bool:
	return wound == "" or bool(Wounds.data(wound)["run"])


## Wütend oder schlimmer, der Spieler nah und sichtbar: hält auf ihn zu.
func _wants_to_bump() -> bool:
	if is_child() or state != State.WALK or _bump_cooldown > 0.0 or Social.tier(self) > Social.Tier.ANGRY:
		return false
	var p := Game.player
	if p == null or p.dead or p.hiding or p.in_dialog:
		return false
	return p.global_position.distance_to(global_position) < 3.5 and can_see_actor(p) and p.recognized_by(self)


func _check_bump() -> void:
	if not _wants_to_bump():
		return
	var p := Game.player
	var to := p.global_position - global_position
	to.y = 0.0
	if to.length() > 0.9:
		return
	_bump_cooldown = 45.0
	p.shove(to.normalized() * 3.0)
	say(RUDE_LINES.pick_random())
	Game.social.on_guest_rammed_player(self)


# --- Nachtruhe --------------------------------------------------------------------------

## Nachtruhe beginnt (Social): ins Zimmer, Licht aus, ins Bett. Wer gerade redet, spielt, klopft oder
## sich versteckt, geht später (über _next_activity).
## instant (Debug): sofort im eigenen Bett.
func bedtime(instant: bool = false) -> void:
	# Manches Kind kann nicht schlafen (6.13) – es bleibt eine Weile wach (_night_activity)
	sleepless = is_child() and not instant and randf() < SLEEPLESS_CHANCE
	set_meta("visit", "")   # ein angefangener Besuch an Zimmer 13 fällt aus
	_awake_left = randf_range(SLEEPLESS_TIME.x, SLEEPLESS_TIME.y)
	if instant and not dead and state != State.SLEEP:
		if hiding:
			_leave_hide()
		global_position = _room_point()
		_fall_asleep()
		return
	if dead or state in [State.TALKING, State.MINIGAME, State.KNOCK, State.SHELTER, State.HIDING, State.HIDE_GO, State.SLEEP, State.SHOCKED, State.GHOSTED, State.STAGGER, State.ATTACK]:
		return
	if state == State.PARTY:
		leave_party()
	if sleepless:
		_night_activity()
		return
	_go_to_bed()


func _go_to_bed() -> void:
	_to_bed = true
	_walk_to(_room_point(), State.WALK)


## Licht aus, ins eigene Bett (still – kein Versteck-Geräusch): Er liegt sichtbar auf dem Rücken, den Kopf
## am Kissen (lokal −X des Betts; Pose in _pose). Ist das Bett belegt, schläft er im Stehen.
func _fall_asleep() -> void:
	_to_bed = false
	_set_room_light(wound_bed > 0.0 and not Game.social.sleep_active)   # verletzt liegt er nicht im Dunkeln (6.17)
	state = State.SLEEP
	# Ein freies Bett – im Doppelbett liegt auch ein Zweiter (Haushalte, Spielkonzept 6.20)
	for second in [false, true]:
		for spot in home["spots"]:
			var bed := spot as HideSpot
			if bed.type != HideSpot.Type.BED or (bed.occupant != null if not second else not bed.takes_partner()):
				continue
			hiding = bed
			if second:
				bed.partner = self
			else:
				bed.occupant = self
			bed.set_checked(false)
			_collider.disabled = true
			velocity = Vector3.ZERO
			var along := bed.global_transform.basis.x.normalized() * -bed.head_x   # zum Fußende
			var across := bed.global_transform.basis.z.normalized() * bed.sleep_offset(second)
			global_position = bed.global_position + along * (bed.bed_size.x / 2.0 - BED_FOOT_GAP) + across + Vector3.UP * BED_TOP
			rotation.y = atan2(-along.x, -along.z)   # lokale +Z (Kopf beim Liegen) zum Kissen
			return


func is_asleep() -> bool:
	return state == State.SLEEP


## Nachtruhe vorbei: aus dem Bett, Licht an.
func wake_up() -> void:
	_to_bed = false
	sleepless = false
	if state != State.SLEEP or wound_bed > 0.0:   # verletzt bleibt er liegen (6.17)
		return
	if hiding:
		_leave_hide()
	_set_room_light(true)
	_set_idle(randf_range(2.0, 8.0))


func _set_idle(duration: float) -> void:
	_romp = false
	state = State.IDLE
	_timer = duration


func _next_activity() -> void:
	_to_bed = false   # ein abgebrochener Weg ins Bett gilt nicht mehr (in der Nachtruhe geht er gleich wieder)
	_flee_home = false
	if _resting:
		_resting = false
		_set_room_light(true)
	if Game.social.sleep_active:
		if sleepless and _awake_left > 0.0:
			_night_activity()
		else:
			sleepless = false
			_go_to_bed()
		return
	if Game.monster and Game.monster.is_active():   # draußen ist es – drinnen bleiben bzw. in Sicherheit
		if _is_home():
			_set_idle(randf_range(10.0, 20.0))
		else:
			take_cover()
		return
	if Game.social.party_active and invited:
		join_party(Game.social.free_party_spot(self))
		return
	if fear >= 60.0:
		_walk_to(_room_point(), State.WALK)
		return
	# Gute Freunde schließen sich manchmal von selbst an (6.3)
	var p := Game.player
	if Social.tier(self) == Social.Tier.GOOD_FRIEND and p and not p.dead and p.hiding == null and randf() < 0.25 \
			and p.global_position.distance_to(global_position) < 6.0 and can_see_actor(p) and p.recognized_by(self):
		say("Ich komm ein Stück mit.")
		start_follow(60.0)
		return
	if is_child() and _child_approach():
		return
	_romp = is_child() and randf() < CHILD_ROMP
	var choice := _weighted_choice(_phase_activities())
	match choice:
		"room":
			_walk_to(_room_point(), State.WALK)
		"lobby":
			_walk_to(Game.social.builder.lobby_seats.pick_random() + _jitter(0.3), State.WALK)
		"kitchen":
			_walk_to(Game.social.builder.kitchen_spot + _jitter(1.2), State.WALK)
		"bar":
			_walk_to(Game.social.builder.bar_spots.pick_random() + _jitter(0.3), State.WALK)
		"garden":
			_plant = _ripe_plant() if profile["harvester"] else null
			if _plant:
				_walk_to(_plant.global_position + Vector3(0, 0, 0.7), State.HARVEST)
			else:
				_walk_to(Game.social.builder.garden_spots.pick_random() + _jitter(1.5), State.WALK)
		_:
			_walk_to(_wander_point(), State.WALK)


func _walk_to(point: Vector3, new_state: State) -> void:
	_target = point
	state = new_state


func _arrive() -> void:
	match state:
		State.WALK:
			if _to_bed and _is_home():
				_fall_asleep()
				return
			if _flee_home:
				_shut_in()
				return
			_set_idle(randf_range(15.0, 40.0))
			# An der Bar wird meist etwas getrunken (3.7)
			if drunk < BarTap.ENOUGH and not is_child() and randf() < BAR_DRINK and Game.social.builder.in_area(global_position, "bar"):
				drink()
				_drink_with_someone()
				if randf() < 0.4:
					say("Prost!" if drunk < BarTap.DRUNK else "Noch eins … *hicks*")
			if _is_home() and not (sleepless and Game.social.sleep_active):
				_at_home()
				if fear < 30.0 and float(profile["brave"]) >= 0.4 and not remembers("ghost") and not is_child() and randf() < 0.3:
					_resting = true
					_set_room_light(false)
		State.CARRY_HOME:
			stow_held()
			_set_idle(randf_range(8.0, 20.0))
			_at_home()
		State.HARVEST:
			if _plant and _plant.is_ripe() and held == null:
				_take_into_hand(_plant.harvest())
				Game.noise("harvest", global_position, self)
				_walk_to(_room_point(), State.CARRY_HOME)
			else:
				_set_idle(randf_range(5.0, 10.0))
		State.PLACE_DECO:
			_drop_held()
			expected_deco += 1
			_set_idle(randf_range(5.0, 12.0))
		State.STEAL:
			_finish_steal()
		State.VISIT:
			Game.social.on_visit_arrived(self)
		State.DECORATE:
			Game.social.decorating.on_arrived(self)   # Schmück-Aktion (Spielkonzept 5.9)
		State.SEARCH:
			Game.social.search.on_arrived(self)   # Deko-Suche (5.9)
		State.EAT:
			if Game.coffee and Game.coffee.expects(self):
				Game.coffee.on_arrived(self)   # Kaffee am Morgen (3.11)
			elif Game.kettle and Game.kettle.expects(self):
				Game.kettle.on_arrived(self)   # Tee am Abend (3.12)
			else:
				Game.kitchen.on_arrived(self)   # Kürbissuppe (3.8)
		State.HIDE_GO:
			if _hide_spot and _hide_spot.occupant == null:
				_enter_hide(_hide_spot)
			else:
				_go_hide()


## Zu Hause: Licht, Vorhänge und Glühbirnen prüfen, Deko kontrollieren, Kürbisse
## schnitzen, Deko vor die Tür stellen.
func _at_home() -> void:
	_check_lights()
	var placed := own_deco_near_door()
	for item in placed:
		if item.is_toppled():
			item.stand_up()   # von einer Katze umgeworfen (6.11)
		elif item.kind == Item.Kind.SHEET_GHOST and not item.holds_pumpkin and int(stock.get(Item.Kind.MINI_PUMPKIN, 0)) > 0:
			stock[Item.Kind.MINI_PUMPKIN] = int(stock[Item.Kind.MINI_PUMPKIN]) - 1
			item.set_pumpkin(true)   # Zierkürbis in die Hände (Spielkonzept 5.6)
	if placed.size() < expected_deco:
		Game.social.on_guest_noticed_missing(self, expected_deco - placed.size())
	expected_deco = placed.size()
	if profile["carver"] and int(stock.get(Item.Kind.PUMPKIN, 0)) > 0:
		stock[Item.Kind.PUMPKIN] = int(stock[Item.Kind.PUMPKIN]) - 1
		stock[Item.Kind.CARVED_PUMPKIN] = int(stock.get(Item.Kind.CARVED_PUMPKIN, 0)) + 1
	if placed.size() < 2 and held == null and is_household_lead():   # eine Tür je Haushalt (6.20)
		for kind in DECO_KINDS:
			if int(stock.get(kind, 0)) > 0:
				stock[kind] = int(stock[kind]) - 1
				_take_into_hand(stock_item(kind))
				_walk_to(deco_place_point(), State.PLACE_DECO)
				return


func _home_lamps() -> Array[Lamp]:
	var result: Array[Lamp] = []
	for node in get_tree().get_nodes_in_group("lamp_fixtures"):
		var lamp := node as Lamp
		if lamp.room_id == home["no"]:
			result.append(lamp)
	return result


## Fenster mit Vorhang im eigenen Zimmer.
func _home_curtains() -> Array[HotelWindow]:
	var result: Array[HotelWindow] = []
	for node in get_tree().get_nodes_in_group("windows"):
		var win := node as HotelWindow
		if win.room_id == home["no"] and win.has_curtains():
			result.append(win)
	return result


func _set_room_light(on: bool) -> void:
	if not on and _housemate_awake():   # wer schlafen geht, lässt den Wachen das Licht (6.20)
		return
	var sw := LightSwitch.find(get_tree(), home["no"])
	if sw:
		sw.set_on(on)


func _check_lights() -> void:
	# Ängstlich (oder den Lakengeist erlebt) → Vorhänge zu (nicht gesehen werden – macht das Zimmer aber dunkler)
	for win in _home_curtains():
		win.set_closed(fear >= 30.0 or remembers("ghost"))
	_set_room_light(true)
	if not is_household_lead():   # Birnen und Beschwerden: einer je Haushalt (6.20)
		return
	for lamp in _home_lamps():
		if lamp.has_bulb and not lamp.bulb_broken:
			continue
		if lamp.has_bulb and lamp.bulb_broken and lamp.sparking:
			continue   # alter Wackelkontakt – daran hat er sich gewöhnt
		if int(stock.get(Item.Kind.BULB, 0)) > 0:
			stock[Item.Kind.BULB] = int(stock[Item.Kind.BULB]) - 1
			if lamp.has_bulb:
				lamp.take_bulb()
			lamp.insert_bulb(Item.create(Item.Kind.BULB))
		elif not lamp.has_bulb:
			Game.social.on_guest_noticed_missing_bulb(self)
		else:
			say("Meine Lampe ist durchgebrannt … jetzt sitze ich im Dunkeln.")


## Platz neben der eigenen Tür (im Flur), an dem Deko steht.
func deco_place_point() -> Vector3:
	var door_front: Vector3 = home["door_front"]
	var along: Vector3 = home["along"]
	var into: Vector3 = home["into"]
	var p := door_front + into * 0.45 + along * (1.0 if randf() < 0.5 else -1.0) * randf_range(0.9, 1.3)
	return Vector3(p.x, door_front.y, p.z)


# --- Klauen -------------------------------------------------------------------------

## Mag uns nicht (und ist gierig) → klaut Deko des Spielers. In Panik ohne eigene Deko
## → klaut irgendeine Deko, um sich zu schützen.
func _try_steal() -> bool:
	if held or is_child():
		return false
	var hostile := Social.tier(self) <= Social.Tier.ANGRY and randf() < float(profile["greed"])
	var desperate := fear >= 60.0 and own_deco_near_door().is_empty()
	if not hostile and not desperate:
		return false
	var best: Item = null
	var best_dist := INF
	for node in get_tree().get_nodes_in_group("items"):
		var item := node as Item
		if item.is_held or item.deco_strength <= 0.0 or item.owner_id == id or _housemate_item(item):
			continue
		if hostile and item.owner_id != "player":
			continue
		if Game.player and Game.player.global_position.distance_to(item.global_position) < 8.0:
			continue
		if Game.social.is_in_closed_chest(item):
			continue
		var d := global_position.distance_to(item.global_position)
		if d < best_dist:
			best_dist = d
			best = item
	if best == null or randf() < 0.35:
		var lamp := _bulb_to_steal(hostile)
		if lamp:
			_steal_lamp = lamp
			_steal_item = null
			_walk_to(_floor_below(lamp.global_position) + _toward_room(lamp), State.STEAL)
			return true
	if best == null:
		return false
	_steal_item = best
	_walk_to(best.global_position, State.STEAL)
	return true


## Eine Lampe, deren Birne er klauen würde: feindlich → aus dem Zimmer des Spielers,
## in Panik → irgendeine (nicht die eigene), um das eigene Zimmer hell zu halten.
func _bulb_to_steal(hostile: bool) -> Lamp:
	var best: Lamp = null
	var best_dist := INF
	for node in get_tree().get_nodes_in_group("lamp_fixtures"):
		var lamp := node as Lamp
		if not lamp.has_bulb or lamp.bulb_broken or lamp.room_id == home["no"] or not lamp.has_socket():
			continue
		if Game.social.behind_lock(lamp.room_id, self):
			continue   # fremdes Zimmer, abgeschlossen (6.19)
		if lamp.room_id in ["lobby", "aufzug"]:
			continue   # Lobbydecke – zu hoch; Aufzugskabine – Gäste fahren (noch) nicht mit (7.4)
		if hostile and lamp.room_id != LevelBuilder.PLAYER_ROOM:
			continue
		if Game.player and Game.player.global_position.distance_to(lamp.global_position) < 8.0:
			continue
		var d := global_position.distance_to(lamp.global_position)
		if d < best_dist:
			best_dist = d
			best = lamp
	return best


## Kleiner Schritt von der Wand weg, damit der Gast unter der Wandleuchte stehen kann.
func _toward_room(lamp: Lamp) -> Vector3:
	if lamp.style == Lamp.Style.WALL:
		var out := lamp.global_transform.basis.z
		return Vector3(out.x, 0, out.z).normalized() * 0.6
	return Vector3.ZERO


func _finish_steal() -> void:
	if _steal_lamp != null:
		var lamp := _steal_lamp
		_steal_lamp = null
		if not is_instance_valid(lamp) or not lamp.has_bulb or held:
			_set_idle(randf_range(3.0, 6.0))
			return
		var victim := lamp.room_id
		var bulb := lamp.take_bulb()
		_take_into_hand(bulb)
		Game.social.on_guest_stole_bulb(self, lamp, victim)
		_walk_to(_room_point(), State.CARRY_HOME)
		return
	var item := _steal_item
	_steal_item = null
	if item == null or not is_instance_valid(item) or item.is_held:
		_set_idle(randf_range(3.0, 6.0))
		return
	var victim := item.owner_id
	_take_into_hand(item)
	Game.social.on_guest_stole(self, item, victim)
	_walk_to(deco_place_point(), State.PLACE_DECO)


# --- Schreck & Erlebnisse (Spielkonzept 6.12) ---------------------------------------------------

## Reaktion auf Schreckliches, fest je Charakter: "flee" (Hände hoch, weglaufen), "freeze" (starr), "cry" (weinen).
func shock_style() -> String:
	if profile.has("shock"):
		return profile["shock"]
	return SHOCK_STYLES.get(profile.get("archetype", ""), "freeze")


## Augenhöhe über den Füßen (Sichtlinien, Hals für den Lakengeist).
func eye_height() -> float:
	if _body:
		return float(profile.get("height_cm", 170.0)) / 100.0 - 0.1
	return 1.6 * float(profile.get("height", 1.0))


## Schaut sich alle 0,5 s nach Blutlachen und Leichen um, die er noch nicht kennt (Gruppe shock_sights,
## Schlüssel in Meta „sight_key“). Jeder Fund erschreckt ihn nur einmal.
func _scan_for_shock(delta: float) -> void:
	_shock_scan -= delta
	if _shock_scan > 0.0:
		return
	_shock_scan = SHOCK_SCAN
	if state in [State.HIDE_GO, State.SHOCKED]:
		return
	var eye := global_position + Vector3.UP * eye_height()
	var forward := -global_transform.basis.z
	for node in get_tree().get_nodes_in_group("shock_sights"):
		var sight := node as Node3D
		if sight == self or not sight.has_meta("sight_key"):
			continue
		var key := String(sight.get_meta("sight_key"))
		if key in seen_sights:
			continue
		var at := sight.global_position + Vector3.UP * 0.15
		if eye.distance_to(at) > SHOCK_RANGE or absf(at.y - global_position.y) > 1.5:
			continue
		if forward.dot((at - eye).normalized()) < Senses.GUEST_FOV_DOT:
			continue
		if not Senses.clear_line(get_world_3d(), eye, at, self):
			continue
		seen_sights.append(key)
		shock(String(sight.get_meta("sight_kind", "blood")), sight.global_position, (sight as Guest).display_name if sight is Guest else "")
		return


## Schreck: bleibt 2–5 s stehen (je mutiger, desto kürzer) und starrt hin – danach je nach Charakter
## weglaufen und verstecken, weitermachen oder weinend heim. Wird zum Erlebnis, von dem er erzählt.
## entranced: vom Lakengeist hypnotisiert – bleibt stehen, bis der weg ist.
func shock(kind: String, pos: Vector3, who: String = "", entranced: bool = false) -> void:
	if dead:
		return
	remember(kind, pos, who)
	if hiding or state in [State.TALKING, State.MINIGAME, State.KNOCK, State.SHELTER, State.SLEEP, State.GHOSTED]:
		return
	if state == State.PARTY:
		leave_party()
	_drop_held()
	var brave := float(profile["brave"])
	_shock_style = shock_style()
	_shock_look = pos
	_entranced = entranced
	state = State.SHOCKED
	_timer = lerpf(5.0, 2.0, brave)
	fear = minf(100.0, fear + (50.0 if kind == "corpse" else 30.0) * (1.2 - brave))
	var cries: Array = SHOCK_CRIES[_shock_style]
	say(cries.pick_random())
	if is_child():
		Game.noise("scream", global_position, self)   # Kinder schreien – das lockt das Monster zu den Erwachsenen (6.13)
		_tell_grown_ups(pos)
	if Game.player and Game.player.global_position.distance_to(global_position) < 10.0:
		Game.play_sound("gasp", 0.5)
	Game.shot_event("shock", 40)


func _after_shock() -> void:
	match _shock_style:
		"flee":
			fear = maxf(fear, 70.0)
			_go_hide()
		"cry":
			_walk_to(_room_point(), State.WALK)
		"cling":
			_run_to_parent()
		_:
			_set_idle(randf_range(2.0, 4.0))


## Der Kürbismann ist da (Spielkonzept 4.19): Spiel, Feier und Süßes oder Saures sind vorbei – wer ihn sieht,
## erschrickt, auch am Spieltisch (shock allein lässt Spielende und Klopfende in Ruhe). Im Gespräch nicht.
func see_pumpkin(pos: Vector3) -> void:
	if dead or hiding or state in [State.TALKING, State.SLEEP, State.GHOSTED, State.SHOCKED]:
		return
	if state in [State.MINIGAME, State.KNOCK]:
		seated = false
		_set_idle(0.5)
	shock("pumpkin", pos)


## Er holt aus – wer so nah ist, erstarrt vor Angst (sonst wäre jeder Gast schneller weg als die Axt).
func cower(pos: Vector3) -> void:
	if dead or hiding:
		return
	if state == State.PARTY:
		leave_party()
	_drop_held()
	seated = false
	_shock_style = "freeze"
	_shock_look = pos
	_entranced = false
	_door_trance = 0.0   # die Axt geht vor – kein Gang mehr zur Tür des Lakengeists
	state = State.SHOCKED
	_timer = 2.0
	say(["*schreit*", "Nein! NEIN!", "Bitte nicht!"].pick_random())
	# Nur der Klang – die Axt (Lärm axe_swing) bricht ihn ab, wenn sie trifft
	var scream: Dictionary = Senses.NOISE["scream"]
	Game.sound_at("scream", global_position, scream["range"], self, scream["volume"])


## Der Lakengeist hat ihn am Hals (SheetGhost) – er zappelt, bis er sich losreißt oder stirbt.
func ghost_grab(ghost_pos: Vector3) -> void:
	if state == State.PARTY:
		leave_party()
	_drop_held()
	_entranced = false
	_shock_look = ghost_pos
	state = State.GHOSTED
	say("*röchelt*")


## Der Lakengeist steht vor der Zimmertür (Spielkonzept 4.18, 5.6): Er starrt zur Tür, bis der Geist weg ist –
## Schwache (DOOR_OPEN) gehen nach einer Weile hin, je schwächer, desto früher, und machen auf. Ist jemand Waches bei ihm im Zimmer, hält der ihn
## zurück; ein Gespräch mit dem Spieler holt ihn heraus.
func door_trance(door_point: Vector3) -> void:
	if dead or hiding or state in [State.TALKING, State.MINIGAME, State.KNOCK, State.SHELTER, State.SLEEP, State.GHOSTED]:
		return
	if state == State.PARTY:
		leave_party()
	_drop_held()
	_shock_style = "stare"
	_shock_look = door_point
	_entranced = true
	var weak := weakness()
	_door_trance = randf_range(DOOR_TRANCE.x, DOOR_TRANCE.y) * (1.0 - 0.5 * weak) if randf() < DOOR_OPEN + DOOR_OPEN_WEAK * weak else 0.0
	state = State.SHOCKED
	_timer = 2.0


## Jemand Waches (Spieler oder erwachsener Gast) mit ihm im eigenen Zimmer.
func _company_at_home() -> bool:
	var builder := Game.social.builder
	var no := String(home["no"])
	if Game.player and not Game.player.dead and builder.room_at(Game.player.global_position) == no:
		return true
	for guest in Game.social.guests:
		var g: Guest = guest
		if g != self and not g.dead and not g.is_child() and g.state != State.SLEEP and builder.room_at(g.global_position) == no:
			return true
	return false


## Der Lakengeist ist weg. Wer gewürgt wurde und sich losgerissen hat, rennt in Panik davon.
func ghost_gone() -> void:
	_entranced = false
	if _door_trance > 0.0 or (state == State.WALK and _target == home["door_inside"]):
		_door_trance = 0.0
		if state in [State.SHOCKED, State.WALK]:
			say(["Hm? … Ich dachte, da wär jemand an der Tür.", "Was wollte ich gerade …?"].pick_random())
			_set_idle(randf_range(2.0, 5.0))
	if dead or state != State.GHOSTED:
		return
	remember("ghost_attack", _shock_look)
	fear = 100.0
	say_panic()
	_go_hide()


## Ein Erlebnis merken (für Gespräche). Dasselbe kurz hintereinander zählt einmal; wird man nach dem
## Anblick des Lakengeists noch gewürgt, wird daraus ein Angriff.
func remember(kind: String, pos: Vector3, who: String = "") -> void:
	var now := Game.director.elapsed if Game.director else 0.0
	if not experiences.is_empty():
		var last: Dictionary = experiences.back()
		var same: bool = last["kind"] == kind or (last["kind"] == "ghost" and kind == "ghost_attack")
		if same and last["who"] == who and now - float(last["at"]) < 60.0:
			if last["kind"] != kind:
				last["kind"] = kind
				last["told"] = false
			return
	var zone := Game.director.zone_name_at(pos) if Game.director else ""
	experiences.append({"kind": kind, "zone": zone, "who": who, "at": now, "told": false})
	if experiences.size() > MAX_EXPERIENCES:
		experiences.pop_front()


## Jüngstes Erlebnis dieser Art („ghost“ passt auch auf „ghost_attack“, "" auf alles) aus dem
## letzten Spieltag, sonst {}.
func recent_experience(kind: String = "") -> Dictionary:
	var now := Game.director.elapsed if Game.director else 0.0
	for i in range(experiences.size() - 1, -1, -1):
		var e: Dictionary = experiences[i]
		if String(e["kind"]).begins_with(kind) and now - float(e["at"]) < Calendar.DAY_SECONDS:
			return e
	return {}


func remembers(kind: String) -> bool:
	return not recent_experience(kind).is_empty()


## Das älteste Erlebnis, von dem er dem Spieler noch nicht erzählt hat, sonst {}.
func untold_experience() -> Dictionary:
	for e in experiences:
		if not e["told"]:
			return e
	return {}


# --- Kinder (Spielkonzept 6.13) ---------------------------------------------------------

## Lachen beim Toben und auf Feiern (Lärm), Wachzeit eines schlaflosen Kindes.
func _child_step(delta: float) -> void:
	if sleepless:
		_awake_left -= delta
	if not ((_romp and fear < 30.0) or state == State.PARTY):
		return
	_laugh -= delta
	if _laugh <= 0.0:
		_laugh = randf_range(CHILD_LAUGH.x, CHILD_LAUGH.y)
		Game.noise("laugh", global_position, self)
		if randf() < 0.3:
			say(["Hihi!", "Hahaha!", "Fang mich doch!"].pick_random())


## Ein Kind hat etwas Schlimmes gesehen: Mama oder Papa bekommen große Angst (und werden schwächer, 4.18),
## und wer in der Nähe ist, bekommt es erzählt – als Kinderfantasie (Erlebnis „child_saw“).
func _tell_grown_ups(pos: Vector3) -> void:
	var parent := parent_guest()
	if parent:
		parent.fear = minf(100.0, parent.fear + CHILD_SCARE_FEAR)
	for other in Game.social.living_guests():
		var g: Guest = other
		if g != self and not g.is_child() and (g == parent or g.global_position.distance_to(global_position) < 12.0):
			g.remember("child_saw", pos, display_name)


## Nach einem Schreck (oder umgerannt): rennend zu Mama oder Papa, sonst ins eigene Zimmer.
func _run_to_parent() -> void:
	var parent := parent_guest()
	if parent and parent.hiding == null:
		_walk_to(parent.global_position + _jitter(0.5), State.WALK)
	else:
		_walk_to(parent._room_point() if parent else _room_point(), State.WALK)
	_romp = true


## Kinder, die dich mögen, schenken dir ab und zu etwas. Waisen schließen sich dir nicht an (Spielkonzept 6.13,
## 2026-10-25). true = beschäftigt.
func _child_approach() -> bool:
	var p := Game.player
	if p == null or p.dead or p.hiding != null or p.in_dialog or not can_see_actor(p) or not p.recognized_by(self):
		return false
	var d := p.global_position.distance_to(global_position)
	if d < 4.0 and p.held == null and gift_cooldown <= 0.0 and Social.tier(self) >= Social.Tier.NICE and randf() < CHILD_GIFT:
		for kind in [Item.Kind.LEAVES, Item.Kind.CANDLE]:
			if int(stock.get(kind, 0)) > 0:
				stock[kind] = int(stock[kind]) - 1
				gift_cooldown = DialogUI.GIFT_COOLDOWN
				p.receive_item(Item.create(kind))
				Game.social.add_deed(self, "gifts_from")
				say(line("give_deco"))
				return true
	return false


## Schlafloses Kind in der Nachtruhe: im dunklen Zimmer mit offenem Vorhang am Fenster stehen (dort findet es
## der Lakengeist), durch den Flur tappen oder an Zimmer 13 klopfen („Ich kann nicht schlafen.“).
func _night_activity() -> void:
	_romp = false
	var roll := randf()
	if roll < 0.5:
		_set_room_light(false)
		for win in _home_curtains():
			win.set_closed(false)
			var inside := win.inside_point()
			_walk_to(Vector3(inside.x, (home["center"] as Vector3).y, inside.z), State.WALK)
			return
	if roll >= 0.8 and Game.social.sleepless_visit(self):
		return
	_walk_to(_wander_point(), State.WALK)


## Zurück ins Bett geschickt (Dialog): Es schläft jetzt.
func send_to_bed() -> void:
	sleepless = false
	_go_to_bed()


# --- Monster & Verstecken -------------------------------------------------------------

func _watch_monster() -> void:
	var monster := Game.monster
	if not monster.is_active():
		_warned = false
		return
	var d := global_position.distance_to(monster.global_position)
	if d > SAFE_DISTANCE:
		_warned = false
	elif d < HEAR_DISTANCE and not _warned and state != State.HIDE_GO:
		_warned = true
		# Sie hören es (Rauschen, Flackern) – vorsichtige Gäste verstecken sich sofort (Haltungen aus Gesprächen, 6.9)
		var nerve := float(profile["brave"]) * (0.5 if has_stance("wary") else 1.0) + (0.4 if has_stance("careless") else 0.0)
		if randf() > nerve and state != State.PARTY:
			fear = minf(100.0, fear + 15.0)
			_go_hide()
			return
	if _monster_cooldown > 0.0 or state == State.HIDE_GO:
		return
	var eye := global_position + Vector3.UP * 1.6
	var monster_head := monster.global_position + Vector3.UP * 1.7
	if eye.distance_to(monster_head) > 15.0:
		return
	if not Senses.clear_line(get_world_3d(), eye, monster_head, self):
		return
	_monster_cooldown = 10.0
	if is_child():
		# Es geht an ihm vorbei (6.13) – das Kind schreit und erzählt es allen; geglaubt wird es nicht
		remember("monster", monster.global_position)
		Game.noise("scream", global_position, self)
		_tell_grown_ups(monster.global_position)
	fear = minf(100.0, fear + 45.0 * (1.2 - float(profile["brave"])))
	Game.social.on_guest_saw_monster(self)
	if randf() < 0.1:
		_lose_coins()
	_go_hide()


## Flackerwelle beim Aufbruch des Monsters (Spielkonzept 4.17), erreicht den Gast nach `delay` s.
## level 0 = kurzes Zucken, 1 = Flackern, 2 = langes Flackern.
func on_flicker_signal(level: int, delay: float) -> void:
	# etwas gestreut – sonst rennen alle aus einer Feier im selben Augenblick zur selben Tür
	get_tree().create_timer(delay + randf_range(0.0, 3.0), false).timeout.connect(_react_to_flicker.bind(level))


## Das Monster bricht auf (Flackerwelle, 2026-10-22): Alle bringen sich in Sicherheit – auch Feiernde –, je länger es
## flackert, desto mehr Angst. Wer im Gespräch oder am Spieltisch ist, bleibt (das Langflackern bricht Partien ab).
func _react_to_flicker(level: int) -> void:
	if dead or hiding != null or state in [State.HIDE_GO, State.TALKING, State.MINIGAME, State.DEAD, State.GHOSTED, State.SLEEP]:
		return
	if has_stance("careless") and level < 2 and randf() < 0.6:   # „da war nichts“ (6.9)
		fear = minf(100.0, fear + 5.0)
		say(CARELESS_LINES.pick_random())
		return
	fear = minf(100.0, fear + [10.0, 15.0, 25.0][level] * (1.4 if has_stance("wary") else 1.0))
	_flicker_fear = 30.0 + 15.0 * level
	take_cover()


## In Sicherheit bringen (Monster unterwegs): Wer nah genug an seinem Zimmer ist (COVER_HOME_RANGE, gleiches Stockwerk),
## rennt heim und macht die Tür zu – sonst ins nächste Versteck.
func take_cover() -> void:
	if dead or hiding != null or state in [State.HIDE_GO, State.DEAD, State.GHOSTED, State.SLEEP]:
		return
	if state == State.PARTY:
		leave_party()
	var door_front: Vector3 = home["door_front"]
	if door_front.distance_to(global_position) < COVER_HOME_RANGE and absf(door_front.y - global_position.y) < 1.5:
		_flee_home = true
		_walk_to(_room_point(), State.WALK)
	else:
		_go_hide()


## Daheim angekommen (take_cover): Tür zu, drinnen bleiben, solange das Monster unterwegs ist (_next_activity).
func _shut_in() -> void:
	_flee_home = false
	var door: Door = home.get("door")
	if door and door.is_open and not door.broken:
		door.set_open(false, false, false, self)   # in Panik: nicht leise (6.19)
	if door and not door.broken:
		door.locked = true
	_set_idle(randf_range(20.0, 40.0))


func _go_hide() -> void:
	_drop_held()
	if state == State.PARTY:
		state = State.IDLE
	_release_hide_spot()
	_hide_spot = Game.social.find_hide_spot(self)
	if _hide_spot:
		_walk_to(_hide_spot.exit_point.global_position, State.HIDE_GO)
	else:
		_walk_to(_room_point(), State.WALK)


func _enter_hide(spot: HideSpot) -> void:
	Game.director.on_actor_hid(spot, self)
	_release_hide_spot()
	hiding = spot
	spot.occupant = self
	spot.on_enter(self)
	visible = false
	_collider.disabled = true
	velocity = Vector3.ZERO
	global_position = spot.global_position
	state = State.HIDING
	_timer = 0.0


## Reserviertes Versteck freigeben – beim Hineingehen, und wenn der Weg dorthin abbricht (sonst bliebe es für alle
## anderen Gäste gesperrt, auch nach seinem Tod).
func _release_hide_spot() -> void:
	if _hide_spot:
		Game.social.release_hide_spot(_hide_spot, self)
		_hide_spot = null


func _hiding_step(delta: float) -> void:
	_timer += delta
	var monster := Game.monster
	_flicker_fear = maxf(0.0, _flicker_fear - delta)
	var calm := (not monster.is_active() or monster.global_position.distance_to(global_position) > SAFE_DISTANCE) and _flicker_fear <= 0.0
	if not calm:
		_timer = minf(_timer, 0.0)
	if calm and _timer > 8.0:
		_leave_hide()
		_set_idle(randf_range(2.0, 5.0))


func _leave_hide() -> void:
	var spot := hiding
	if spot == null:
		return
	hiding = null
	spot.release(self)
	spot.on_exit()
	visible = true
	_collider.disabled = false
	global_position = spot.exit_point.global_position
	state = State.IDLE


# --- Hände ------------------------------------------------------------------------

func _take_into_hand(item: Item) -> void:
	if item == null:
		return
	if not item.is_inside_tree():
		get_parent().add_child(item)
	item.owner_id = id
	item.set_held(true)
	item.reparent(_hand, false)
	item.position = Vector3(0, -0.15, 0) if item.is_large else Vector3.ZERO
	item.rotation = Vector3(0, PI, 0)
	held = item


## Was er in der Hand hat, wandert in den Vorrat (Koffer).
func stow_held() -> void:
	if held == null:
		return
	stock[held.kind] = int(stock.get(held.kind, 0)) + 1
	held.queue_free()
	held = null


func _drop_held() -> void:
	if held == null:
		return
	var item := held
	held = null
	item.reparent(get_parent(), true)
	if state == State.PLACE_DECO and item.can_hang():
		var spot := door_hang_spot(item.kind)
		item.hang(spot["point"], spot["out"], float(spot.get("length", 0.0)))
		return
	var pos := Vector3(item.global_position.x, global_position.y + 0.02, item.global_position.z)
	if state == State.PLACE_DECO:
		pos = Vector3(_target.x, _target.y + 0.02, _target.z)
	item.global_position = pos
	item.rotation = Vector3(0, rotation.y + PI, 0)
	item.set_held(false)
	item.linear_velocity = Vector3.ZERO


# --- Hilfen ------------------------------------------------------------------------

func _room_point() -> Vector3:
	var c: Vector3 = home["center"]
	return c + _jitter(1.0)


func _is_home() -> bool:
	var c: Vector3 = home["center"]
	return global_position.distance_to(c) < 2.5


## Eine reife Pflanze – am liebsten seine Lieblingssorte, nie den Riesenkürbis (den trägt keiner).
func _ripe_plant() -> PumpkinPlant:
	var any: PumpkinPlant = null
	for node in get_tree().get_nodes_in_group("pumpkin_plants"):
		var plant := node as PumpkinPlant
		if not plant.is_ripe() or plant.is_giant():
			continue
		if plant.variety == favorite_pumpkin():
			return plant
		if any == null:
			any = plant
	return any


## Lieblingskürbis (Spielkonzept 5.8): als Geschenk besonders willkommen, beim Ernten bevorzugt, eigene Kürbisse
## aus dem Vorrat sind von dieser Sorte. Fest aus der ID (PumpkinKinds.favorite_of) – kein Speicherfeld.
func favorite_pumpkin() -> String:
	return PumpkinKinds.favorite_of(id)


## Ein Gegenstand aus seinem Vorrat – Kürbisse in seiner Lieblingssorte (geschnitzt: Halloween, wenn sie sich nicht schnitzen lässt).
## Aus dem Koffer brennt nichts: Kerzen sind aus, im geschnitzten Kürbis steckt eine erloschene Kerze (Spielkonzept 5.12).
func stock_item(kind: int) -> Item:
	if kind == Item.Kind.CARVED_PUMPKIN:
		return Item.create(kind, favorite_pumpkin() + ",out")
	if kind == Item.Kind.PUMPKIN:
		return Item.create(kind, favorite_pumpkin())
	return Item.create(kind)


# --- Spuren der Gäste ------------------------------------------------------------------

## Schritte zum Hören (Footsteps), schlammige Schuhabdrücke nach dem Garten, Wachs von etwas Brennendem in der Hand,
## Blutstropfen nach einem Angriff.
func _leave_traces(delta: float) -> void:
	_bleeding = maxf(0.0, _bleeding - delta)
	var moved := Vector2(global_position.x - _trace_pos.x, global_position.z - _trace_pos.z).length()
	_trace_pos = global_position
	if moved > 1.0 * maxf(1.0, _lod_scale) or moved < 0.001 or hiding:
		return   # versetzt (Versteck, Laden) oder steht still
	_step_dist += moved
	if _step_dist < 0.8:
		return
	_step_dist = 0.0
	# Garten erst beim Schritt prüfen – das kostet bei vielen Gästen sonst jedes Bild
	var in_garden := Game.social != null and Game.social.builder.is_outdoor(global_position)
	if in_garden:
		_mud = MUD_STEPS
	_steps.step(Footsteps.floor_under(self), moved / maxf(delta, 0.001) > WALK_SPEED * 1.5, is_child())
	var traces := Game.traces
	if traces == null:
		return
	if _mud > 0 and not in_garden:
		_mud -= 1
		_foot_side = -_foot_side
		traces.add_shoeprint(global_position + global_transform.basis.x * 0.1 * _foot_side, rotation.y)
	if (_bleeding > 0.0 or _hurt_time > HURT_TIME - 20.0) and randf() < (1.0 if _bleeding > 60.0 else 0.5):   # Axtwunde: dichte Spur
		traces.add_guest_drop("drops", global_position + _jitter(0.15))
	if held and held.lit and randf() < 0.15:
		traces.add_guest_drop("wax", global_position + _jitter(0.2))


## In Panik fallen ein paar Münzen aus der Tasche – wer sie findet, darf sie behalten.
func _lose_coins() -> void:
	if money < 2:
		return
	var n := randi_range(1, mini(4, money))
	money -= n
	var coins := Item.create(Item.Kind.COINS, str(n))
	get_parent().add_child(coins)
	coins.global_position = global_position + _jitter(0.4) + Vector3.UP * 0.05


## Boden unter einem Punkt (z. B. unter einer Lampe) – auf jedem Stockwerk.
func _floor_below(p: Vector3) -> Vector3:
	var query := PhysicsRayQueryParameters3D.create(p + Vector3.DOWN * 0.3, p + Vector3.DOWN * 4.0, 1)
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	return Vector3(p.x, global_position.y if hit.is_empty() else (hit["position"] as Vector3).y, p.z)


## Ein zufälliger Punkt auf den Fluren (Herumschlendern).
func _wander_point() -> Vector3:
	return Game.social.builder.wander_points.pick_random() + _jitter(0.5)


func _jitter(r: float) -> Vector3:
	return Vector3(randf_range(-r, r), 0, randf_range(-r, r))


## Vorlieben des Gasts, gewichtet nach der Phase des Tages (PHASE_ACTIVITIES).
func _phase_activities() -> Dictionary:
	return activity_weights(Calendar.phase())


## Vorlieben in einer Phase – mit den Haltungen aus Gesprächen (6.9): vorsichtig bzw. sorglos.
func activity_weights(phase: Calendar.Phase) -> Dictionary:
	var factors: Dictionary = PHASE_ACTIVITIES.get(phase, {})
	var mood: Dictionary = WARY_ACTIVITIES if has_stance("wary") else (CARELESS_ACTIVITIES if has_stance("careless") else {})
	var weights := {}
	for key in profile["activities"]:
		weights[key] = float(profile["activities"][key]) * float(factors.get(key, 1.0)) * float(mood.get(key, 1.0))
	return weights


# --- Haltungen (Spielkonzept 6.9, Talk) -------------------------------------------------------

## Gilt die Haltung noch?
func has_stance(key: String) -> bool:
	return stances.has(key) and float(stances[key]["until"]) > (Game.director.elapsed if Game.director else 0.0)


## Haltung für duration Sekunden Spielzeit (überschreibt eine ältere gleichen Namens); extra: weitere Felder.
func set_stance(key: String, duration: float, extra: Dictionary = {}) -> void:
	var s := extra.duplicate()
	s["until"] = (Game.director.elapsed if Game.director else 0.0) + duration
	stances[key] = s


func clear_stance(key: String) -> void:
	stances.erase(key)


## Abgelaufene Haltungen entfernen (Talk, ab und zu) – „promise“ bleibt, bis Talk es auswertet.
func prune_stances() -> void:
	for key in stances.keys():
		if key != "promise" and not has_stance(key):
			stances.erase(key)


## Heim ins eigene Zimmer (Bitte im Gespräch, 6.9).
func go_home() -> void:
	if not dead and hiding == null and state in [State.IDLE, State.WALK, State.TALKING]:
		_walk_to(_room_point(), State.WALK)


func _weighted_choice(weights: Dictionary) -> String:
	var total := 0.0
	for key in weights:
		total += float(weights[key])
	var r := randf() * total
	for key in weights:
		r -= float(weights[key])
		if r <= 0.0:
			return key
	return weights.keys()[0]


## Weit weg und nicht im Blick? Im Gespräch, beim Spiel, gewürgt oder taumelnd immer voll.
func _lod_far() -> bool:
	var player := Game.player
	if player == null or state in [State.TALKING, State.MINIGAME, State.GHOSTED, State.STAGGER, State.ATTACK]:
		return false
	var d := global_position.distance_squared_to(player.global_position)
	if d > LOD_FAR * LOD_FAR:
		return true
	return d > LOD_RANGE * LOD_RANGE and not player.camera.is_position_in_frustum(global_position + Vector3.UP)


func _open_doors(delta: float) -> void:
	# Bei vielen Gästen und Türen nicht jeden Frame alle Türen prüfen (delta: mit Detailstufe die aufgesammelte Zeit)
	_door_timer -= delta
	if _door_timer > 0.0:
		return
	_door_timer = 0.15
	_close_behind()
	# Nur wer geht, macht auf – wer steht (wartet, klopft, ist gerade geladen), lässt die Tür neben sich zu
	if Vector2(velocity.x, velocity.z).length_squared() < 0.01:
		return
	for door: Door in Door.near(global_position):
		if door.is_open or door.broken:
			continue
		# Nur eine Tür, durch die der eigene Weg führt (Spielkonzept 6.19) – nicht jede, an der er vorbeigeht
		if door.center().distance_to(global_position + Vector3.UP) >= 1.2 or not _path_through(door):
			continue
		if door.locked:
			if door.room_no == "" or door.room_no != String(home["no"]):
				continue   # abgeschlossen, und es ist nicht sein Zimmer
			door.locked = false
		door.set_open(true, false, false, self)
		if door.room_no != "" and door.room_no != LevelBuilder.PLAYER_ROOM:
			_door_behind = door   # Zimmertür: hinter sich wieder schließen
			_door_side = _side_of(door)
			_door_wait = 0.0


## Führt der eigene Weg durch diese Tür? Ein Wegpunkt der nächsten Meter (oder das Ziel) liegt auf der anderen Seite,
## in der Breite der Öffnung.
func _path_through(door: Door) -> bool:
	var side := _side_of(door)
	var path := agent.get_current_navigation_path()
	var points: Array[Vector3] = []
	for k in range(agent.get_current_navigation_path_index(), mini(agent.get_current_navigation_path_index() + 6, path.size())):
		points.append(path[k])
	points.append(agent.target_position)
	var c := door.center()
	var across := door.global_transform.basis.x.normalized()
	var normal := door.global_transform.basis.z.normalized()
	for p in points:
		if p.distance_to(global_position) > DOOR_LOOKAHEAD and p != agent.target_position:
			break
		var d := normal.dot(p - c)
		if signf(d) != signf(side) and absf(d) > 0.15 and absf(across.dot(p - c)) < door.width / 2.0 + 0.8 \
				and p.distance_to(c) < DOOR_LOOKAHEAD:
			return true
	return false


## Seite der Tür, auf der er steht (Vorzeichen entlang der Türnormalen).
func _side_of(door: Door) -> float:
	return door.global_transform.basis.z.normalized().dot(global_position - door.center())


## Die Zimmertür, durch die er gegangen ist, wieder schließen, sobald er durch ist und niemand im Schwenkbereich steht –
## leise; in Panik knallt er sie zu. Die eigene schließt er auch ab (6.19).
func _close_behind() -> void:
	var door := _door_behind
	if door == null:
		return
	if not is_instance_valid(door) or not door.is_open or door.broken or dead:
		_door_behind = null
		return
	var c := door.center()
	var flat := Vector2(global_position.x - c.x, global_position.z - c.z).length()
	if flat < DOOR_CLOSE_DISTANCE:
		return
	if flat > DOOR_GIVE_UP_DISTANCE or _door_wait > DOOR_GIVE_UP_WAIT:
		_door_behind = null   # zu weit weg oder zu lange gewartet – dann bleibt sie eben offen
		return
	if _someone_in_swing(door):
		_door_wait += 0.15
		return
	var slam := fear >= 60.0
	door.set_open(false, slam, not slam, self)
	if door.room_no == String(home["no"]):
		door.locked = true
	_door_behind = null


func _someone_in_swing(door: Door) -> bool:
	var c := door.center()
	var near := func(n: Node3D) -> bool:
		return Vector2(n.global_position.x - c.x, n.global_position.z - c.z).length() < DOOR_SWING_CLEAR \
			and absf(n.global_position.y + 1.0 - c.y) < 1.5
	if Game.player and near.call(Game.player):
		return true
	for g in Game.social.guests if Game.social else []:
		if g != self and not g.dead and near.call(g):
			return true
	for cat in get_tree().get_nodes_in_group("cats"):
		if near.call(cat):
			return true
	return false


func _move_to(point: Vector3, speed: float, delta: float) -> bool:
	if agent.target_position.distance_to(point) > 0.25:
		agent.target_position = point
	# Nur angekommen, wenn auch das Stockwerk stimmt (Zimmer liegen übereinander)
	var near := Vector2(point.x - global_position.x, point.z - global_position.z).length() < 0.6 and absf(point.y - global_position.y) < 1.5
	if near or agent.is_navigation_finished():
		_stop(delta)
		return true
	# Große Schritte (fern mit _lod_scale, Zeitraffer beim Schlafen, wenige Bilder) springen über den Wegpunkt – ohne
	# größeren Abstand pendelte er dann um ihn herum, ohne je weiterzuschalten
	agent.path_desired_distance = maxf(0.3, speed * _lod_scale * get_physics_process_delta_time() * 1.5)
	var next := agent.get_next_path_position()
	var dir := next - global_position
	dir.y = 0.0
	if dir.length() > 0.01:
		dir = dir.normalized()
		rotation.y = lerp_angle(rotation.y, atan2(-dir.x, -dir.z), minf(1.0, 8.0 * delta))
	velocity.x = dir.x * speed * _lod_scale   # seltener gerechnet → längerer Schritt (_lod_far)
	velocity.z = dir.z * speed * _lod_scale
	velocity.y = 0.0 if is_on_floor() else velocity.y - _gravity * delta
	move_and_slide()
	velocity.x /= _lod_scale
	velocity.z /= _lod_scale
	_note_progress()
	# Festgefahren? Weg neu berechnen und kurz seitlich ausweichen.
	if global_position.distance_to(_last_pos) < speed * delta * 0.2:
		_stuck_time += delta
		if _stuck_time > 1.0:
			_stuck_time = 0.0
			var side := Vector3(-dir.z, 0, dir.x) * (1.0 if randf() < 0.5 else -1.0)
			global_position += side * 0.15
			agent.target_position = point + Vector3(0.01, 0, 0)
	else:
		_stuck_time = 0.0
	_last_pos = global_position
	return false


## Kommt er voran? Merkt sich, wo er zuletzt STALL_RANGE weiter war.
func _note_progress() -> void:
	var now := Game.director.elapsed if Game.director else 0.0
	if now - _stall_seen > 1.0 or global_position.distance_to(_stall_pos) > STALL_RANGE:
		_stall_pos = global_position
		_stall_since = now
	_stall_seen = now


func _stalled() -> bool:
	var now := Game.director.elapsed if Game.director else 0.0
	return now - _stall_seen < 1.0 and now - _stall_since > STALL_TIME


## Festgefahren: Der Weg ins Versteck führt nicht weiter – dann eben ins eigene Zimmer; sonst bleibt er stehen
## und sucht sich etwas Neues (_next_activity).
func _give_up_walk() -> void:
	_stall_seen = -10.0
	if Game.tracing:
		print("[Gast] %s kommt nicht weiter (%s) bei %s → Ziel %s" % [display_name, State.keys()[state],
			global_position.snapped(Vector3.ONE * 0.1), _target.snapped(Vector3.ONE * 0.1)])
	if state == State.HIDE_GO:
		_release_hide_spot()
		_walk_to(_room_point(), State.WALK)
	else:
		_set_idle(randf_range(2.0, 5.0))


func _stop(delta: float) -> void:
	var still := is_on_floor() and velocity.length_squared() < 0.0001
	velocity.x = 0.0
	velocity.z = 0.0
	velocity.y = 0.0 if is_on_floor() else velocity.y - _gravity * delta
	if not still:
		move_and_slide()   # wer schon still auf dem Boden steht, braucht keine Kollision (Leistung bei vielen Gästen)


func _face(pos: Vector3, delta: float) -> void:
	var to := pos - global_position
	if Vector2(to.x, to.z).length() < 0.01:
		return
	rotation.y = lerp_angle(rotation.y, atan2(-to.x, -to.z), minf(1.0, 6.0 * delta))


# --- Aussehen -------------------------------------------------------------------------

func _build_visual() -> void:
	_visual = Node3D.new()
	add_child(_visual)
	var body_id := GuestBody.pick(profile, id)
	if body_id != "":
		_body = GuestBody.new()
		_body.setup(body_id, profile)
		_visual.add_child(_body)
		# Unsichtbare Pivots: die Posen drehen sie, das Modell zielt mit den Oberarmen danach
		_arm_l = Node3D.new()
		_arm_r = Node3D.new()
		_visual.add_child(_arm_l)
		_visual.add_child(_arm_r)
	else:
		_build_blocks()
	_hand = Node3D.new()
	_hand.position = Vector3(0, 1.0, -0.35)
	_visual.add_child(_hand)
	_label = Label3D.new()
	_label.text = display_name
	_label.font_size = 28
	_label.pixel_size = 0.005
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	_label.modulate = Color(0.9, 0.85, 0.7)
	_label.position = Vector3(0, 2.0, 0)
	_label.visible = false
	add_child(_label)


## Klötzchenfigur für Gäste ohne Grundkörper
func _build_blocks() -> void:
	_visual.scale = Vector3.ONE * float(profile.get("height", 1.0))
	var coat := Mat.psx(profile["coat"])
	var pants := Mat.psx(profile["pants"])
	var skin := Mat.psx(Color(0.82, 0.66, 0.55))
	var hair := Mat.psx(profile["hair"])
	for side in [-1.0, 1.0]:
		Geo.mesh(_visual, Geo.box(Vector3(0.13, 0.85, 0.15)), pants, Vector3(side * 0.09, 0.425, 0))
	Geo.mesh(_visual, Geo.box(Vector3(0.4, 0.62, 0.24)), coat, Vector3(0, 1.15, 0))
	_arm_l = _make_arm(-1.0, coat, skin)
	_arm_r = _make_arm(1.0, coat, skin)
	# Kopf auf dem Hals (1,47 m) – bei Kindern größer (Spielkonzept 6.13)
	var head := Node3D.new()
	head.position = Vector3(0, 1.47, 0)
	head.scale = Vector3.ONE * float(profile.get("head", 1.0))
	_head_pivot = head
	_visual.add_child(head)
	Geo.mesh(head, Geo.sphere(0.13, 0.28, 7, 4), skin, Vector3(0, 0.13, 0))
	Geo.mesh(head, Geo.box(Vector3(0.28, 0.1, 0.28)), hair, Vector3(0, 0.25, 0.01))
	Geo.mesh(head, Geo.box(Vector3(0.28, 0.2, 0.08)), hair, Vector3(0, 0.15, 0.12))
	for side in [-1.0, 1.0]:
		Geo.mesh(head, Geo.box(Vector3(0.03, 0.03, 0.02)), Mat.psx(Color(0.05, 0.05, 0.05)), Vector3(side * 0.05, 0.15, -0.12))


## Meist der Lieblingstanz des Gastes, ab und zu ein anderer (Spielkonzept 7.1).
func _dance_pose(delta: float) -> void:
	var dances: Array = GuestBody.DANCES if _body else DANCES
	_dance_timer -= delta
	if _dance < 0 or _dance_timer <= 0.0:
		var favourite := absi(hash(id)) % dances.size()
		_dance = favourite if randf() < 0.6 else randi() % dances.size()
		_dance_timer = randf_range(7.0, 15.0)
		_visual.rotation = Vector3.ZERO
	if _body:
		_body.dance = dances[_dance]
		_visual.position.y = 0.0
		return
	var t := _anim
	var beat := sin(t * 4.0)
	_arm_l.rotation.z = 0.0
	_arm_r.rotation.z = 0.0
	match DANCES[_dance]:
		"hüpfen":
			_visual.position.y = absf(beat) * 0.08
			_visual.rotation.y = sin(t * 2.0) * 0.4
			_arm_l.rotation.x = -1.2 + beat * 0.6
			_arm_r.rotation.x = -1.2 - beat * 0.6
		"wiegen":
			# Langsam von einer Seite zur anderen, Arme leicht ausgebreitet
			_visual.position.y = 0.0
			_visual.rotation.z = sin(t * 1.8) * 0.12
			_visual.rotation.y = sin(t * 0.9) * 0.25
			_arm_l.rotation.x = -0.3
			_arm_r.rotation.x = -0.3
			_arm_l.rotation.z = -0.6 + sin(t * 1.8) * 0.2
			_arm_r.rotation.z = 0.6 + sin(t * 1.8) * 0.2
		"drehen":
			# Pirouetten mit ausgestreckten Armen
			_visual.position.y = absf(sin(t * 3.0)) * 0.03
			_visual.rotation.y += delta * 3.2
			_arm_l.rotation.x = 0.0
			_arm_r.rotation.x = 0.0
			_arm_l.rotation.z = -1.4
			_arm_r.rotation.z = 1.4
		"arme hoch":
			# Arme über dem Kopf, im Takt winken
			_visual.position.y = absf(beat) * 0.05
			_visual.rotation.y = sin(t * 1.0) * 0.2
			_arm_l.rotation.x = -2.9 + beat * 0.15
			_arm_r.rotation.x = -2.9 - beat * 0.15
			_arm_l.rotation.z = -0.25 + beat * 0.2
			_arm_r.rotation.z = 0.25 + beat * 0.2
		"twist":
			# Schnelles Hin- und Herdrehen, in die Knie gehen
			_visual.position.y = -0.06 + sin(t * 3.0) * 0.05
			_visual.rotation.y = sin(t * 9.0) * 0.6
			_arm_l.rotation.x = -1.0 + sin(t * 9.0) * 0.3
			_arm_r.rotation.x = -1.0 - sin(t * 9.0) * 0.3
		"schunkeln":
			# Seitlich wippen, Arme angewinkelt vor dem Körper
			_visual.position.y = absf(sin(t * 2.5)) * 0.03
			_visual.rotation.z = sin(t * 2.5) * 0.2
			_visual.rotation.y = 0.0
			_arm_l.rotation.x = -1.5
			_arm_r.rotation.x = -1.5
			_arm_l.rotation.z = -0.3
			_arm_r.rotation.z = 0.3


## Schreckhaltung (6.12): Hände hoch und zittern (flee), Hand vor den Mund (freeze), zusammengesunken
## mit den Händen vorm Gesicht (cry). Hypnotisiert: Arme hängen, leises Schwanken. Gewürgt: Hände am
## Hals, zappeln.
## Darts an der Linie: rechter Arm vorn mit dem Pfeil auf Augenhöhe; beim Wurf erst zurück nach oben, dann nach vorn
## durchgezogen (_dart_throw läuft von DART_THROW_TIME bis 0).
func _dart_pose(delta: float) -> void:
	_arm_l.rotation.x = -0.25
	var aim := -1.55
	if _dart_throw > 0.0:
		_dart_throw = maxf(0.0, _dart_throw - delta)
		var t := 1.0 - _dart_throw / DART_THROW_TIME
		if t < 0.45:
			aim = lerpf(-1.55, -2.35, smoothstep(0.0, 0.45, t))     # ausholen
		elif t < 0.6:
			aim = lerpf(-2.35, -1.2, (t - 0.45) / 0.15)              # werfen
		else:
			aim = lerpf(-1.2, -1.55, smoothstep(0.6, 1.0, t))       # zurück
	_arm_r.rotation.x = aim


func _shock_pose() -> void:
	var t := _anim
	if state == State.GHOSTED:
		_visual.rotation.y = sin(t * 11.0) * 0.12
		_visual.rotation.x = 0.12
		_arm_l.rotation = Vector3(-2.5 + sin(t * 13.0) * 0.15, 0, 0.55)
		_arm_r.rotation = Vector3(-2.5 - sin(t * 13.0) * 0.15, 0, -0.55)
		return
	if _entranced:
		_visual.rotation.z = sin(t * 0.9) * 0.04
		_arm_l.rotation.x = 0.0
		_arm_r.rotation.x = 0.0
		return
	match _shock_style:
		"flee":
			var shake := sin(t * 23.0) * 0.08
			_visual.rotation.x = 0.1   # weicht zurück
			_arm_l.rotation = Vector3(-2.8 + shake, 0, -0.35)
			_arm_r.rotation = Vector3(-2.8 - shake, 0, 0.35)
		"cling":
			# klammert sich fest: geduckt, Arme nach vorn, zittert
			var shake := sin(t * 19.0) * 0.06
			_visual.rotation.x = -0.15
			_arm_l.rotation = Vector3(-1.5 + shake, 0, 0.35)
			_arm_r.rotation = Vector3(-1.5 - shake, 0, -0.35)
		"cry":
			_visual.rotation.x = -0.3
			_visual.position.y = -0.06 + absf(sin(t * 7.0)) * 0.015   # Schluchzen
			_arm_l.rotation = Vector3(-2.3, 0, 0.5)
			_arm_r.rotation = Vector3(-2.3, 0, -0.5)
		_:
			_arm_l.rotation = Vector3(-0.15, 0, 0)
			_arm_r.rotation = Vector3(-2.1, 0, -0.6)


func _make_arm(side: float, coat: Material, skin: Material) -> Node3D:
	var pivot := Node3D.new()
	pivot.position = Vector3(side * 0.26, 1.42, 0)
	_visual.add_child(pivot)
	Geo.mesh(pivot, Geo.box(Vector3(0.1, 0.55, 0.11)), coat, Vector3(0, -0.27, 0))
	Geo.mesh(pivot, Geo.box(Vector3(0.08, 0.1, 0.09)), skin, Vector3(0, -0.6, 0))
	return pivot


func _update_label() -> void:
	var p := Game.player
	var d := p.global_position.distance_to(global_position) if p else INF
	_label.visible = hiding == null and d > 2.2 and d < 7.0 and state != State.TALKING \
		and not (_costume and _costume.kind == "sheet")   # unter dem Laken: wer ist das? (5.9)


## Ab dem 25. verkleidet (Spielkonzept 5.9) – einmal je Sekunde prüfen, ob das Kostüm wechselt. Im Bett zieht
## man es aus.
func _update_costume(delta: float) -> void:
	_costume_check -= delta
	if _costume_check > 0.0:
		return
	_costume_check = 1.0
	var want := "" if state == State.SLEEP and hiding else Costume.pick(self)
	if want == (_costume.kind if _costume else ""):
		return
	if _costume:
		_costume.queue_free()
		_costume = null
	# Unter dem Laken: Kopf kleiner bzw. weg, sonst sticht er durch
	if _body:
		_body.head_shrink = 0.6 if want == "sheet" else 1.0
	else:   # Klötzchenfigur: Kopf und Arme stecken ganz im Laken
		_head_pivot.visible = want != "sheet"
		_arm_l.visible = want != "sheet"
		_arm_r.visible = want != "sheet"
	if want == "":
		return
	_costume = Costume.new()
	_costume.scale = Vector3.ONE / _visual.scale   # Klötzchenfiguren sind über _visual skaliert
	var height := eye_height() + 0.12
	var size := clampf(height / 1.8, 0.65, 1.0)
	# Scheitel über dem Kopfpunkt: Kopfknochen des Modells bzw. Kopf der Klötzchenfigur
	var lift := 0.2 * size if _body else 0.27 * float(profile.get("height", 1.0)) * float(profile.get("head", 1.0))
	_costume.setup(want, height, lift, size)
	_visual.add_child(_costume)


## Der Spieler unter dem Bettlaken kommt in Sicht (Spielkonzept 5.9): einmal je Überwerfen staunen – im Dunkeln
## mit echtem Schreck, Kinder freuen sich. Wer ihn schon erkennt (ganz nah), staunt nicht.
func _notice_disguise(delta: float) -> void:
	_disguise_check -= delta
	var p := Game.player
	if _disguise_check > 0.0 or p == null or not p.disguised or p.disguise_count == _disguise_seen:
		return
	_disguise_check = 0.5
	if state in [State.SLEEP, State.TALKING, State.MINIGAME] or hiding \
			or p.global_position.distance_to(global_position) > 6.0 or not can_see_actor(p):
		return
	_disguise_seen = p.disguise_count
	if is_child():
		say("Ein Gespenst! Hihi – buuuh!")
	elif Game.director and Game.director.light_at(p.global_position + Vector3.UP) < DISGUISE_DARK:
		fear = minf(100.0, fear + DISGUISE_FRIGHT * (1.2 - float(profile["brave"])))
		say("Aaah! … Ach so, nur ein Kostüm. Wer ist da drunter?")
	else:
		say("Huch! … Ach, ein Kostüm.")


func _head_point() -> Vector3:
	return _body.head_origin() if _body else _head_pivot.global_position


func _animate(delta: float) -> void:
	_anim += delta
	var speed := Vector2(velocity.x, velocity.z).length()
	_pose(delta, speed)
	if _body and visible:
		# unter dem Laken hängen die Arme still, sonst schwingen sie beim Gehen heraus (Tanzen darf man sie sehen)
		var arms_free := _arms_free and not (_costume and _costume.kind == "sheet")
		_body.animate(delta, speed, running, [_arm_l, _arm_r], arms_free, state == State.MINIGAME and seated and not game_stand)
	if _costume and visible:
		_costume.follow(_head_point(), _visual.global_basis)


func _pose(delta: float, speed: float) -> void:
	_arms_free = false
	if state == State.PARTY and speed < 0.1 and not _gather_look.is_finite():
		_dance_pose(delta)
		return
	_dance = -1
	if _body:
		_body.dance = ""
	_visual.position.y = 0.0
	_visual.rotation = Vector3.ZERO
	_arm_l.rotation.z = 0.0
	_arm_r.rotation.z = 0.0
	if hiding == null and state in [State.IDLE, State.WALK, State.TALKING, State.PARTY]:
		_visual.rotation.z = sin(_anim * 1.9) * 0.07 * BarTap.sway(drunk)   # im Rausch schwankt er (3.7)
	if state in [State.SHOCKED, State.GHOSTED]:
		_shock_pose()
		return
	if state == State.SLEEP and hiding:
		# schläft auf dem Rücken im Bett, Arme an der Seite, atmet ruhig
		_visual.position.y = 0.13 + sin(_anim * 1.6) * 0.006
		_visual.rotation.x = PI / 2.0
		_arm_l.rotation = Vector3(0, 0, -0.15)
		_arm_r.rotation = Vector3(0, 0, 0.15)
		return
	if state == State.MINIGAME and seated and game_stand:
		_dart_pose(delta)
		return
	if state == State.MINIGAME and seated:
		_visual.position.y = -(_body.sit_drop() if _body else 0.35)   # sitzt
		_arm_l.rotation.x = -1.1 + sin(_anim * 3.0) * 0.05
		_arm_r.rotation.x = -1.1
		return
	if _reach > 0.0:
		_reach -= delta
		_arm_l.rotation.x = -2.5   # hängt Deko an die Wand (Spielkonzept 5.9)
		_arm_r.rotation.x = -2.5
	elif running:
		_arm_l.rotation.x = -2.6 + sin(_anim * 14.0) * 0.3   # Arme hoch – Panik
		_arm_r.rotation.x = -2.6 - sin(_anim * 14.0) * 0.3
	elif held:
		_arm_l.rotation.x = -1.2
		_arm_r.rotation.x = -1.2
	else:
		var swing := sin(_anim * 6.0) * clampf(speed * 0.35, 0.0, 0.6)
		_arm_l.rotation.x = swing
		_arm_r.rotation.x = -swing
		_arms_free = true
