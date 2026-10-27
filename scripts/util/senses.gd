class_name Senses
## Lärm & Sichtbarkeit – ein gemeinsames System (Spielkonzept 4.15).
## Jede Aktion hat eine Lautstärke (= Hörweite in Metern), jeder Akteur eine Auffälligkeit.
## Monster und Gäste rechnen gleich, nur mit eigenen Ohren und Augen. Alle Werte stehen hier.
##
## Lärm entsteht über `Game.noise(art, ort, quelle)`: spielt das Geräusch für den Spieler und
## meldet es dem Director (Monster) und Social (Gäste).

# --- Tuning: Lärm -------------------------------------------------------------------
## Art → Hörweite in m (`range`), Geräusch für den Spieler (`sound`, `volume`), erschreckt Gäste (`alarm`),
## Untertitel (`caption`) – erscheint, sobald man es überhaupt hört, auch leise (Einstellung „Untertitel“).
## Ohne `sound` ist es Lärm, den man nicht eigens hört (Schritte, Musik läuft extra).
const NOISE := {
	"step":       {"range": 2.0,  "sound": "",       "volume": 0.0},    ## Gehen auf Holz/Fliesen (Teppich, geduckt: still)
	"run":        {"range": 10.0, "sound": "",       "volume": 0.0},    ## alle 0,6 s
	"land":       {"range": 4.0,  "sound": "thud",   "volume": 0.2, "caption": "[Ein dumpfer Aufprall]"},    ## nach einem Sprung
	"stumble":    {"range": 5.0,  "sound": "thud",   "volume": 0.35, "caption": "[Stolpern]"},   ## im Rausch gestolpert (3.7)
	"door":       {"range": 5.0,  "sound": "door",   "volume": 0.5, "caption": "[Eine Tür knarrt]"},    ## Tür öffnen/schließen (echter Klang)
	"rattle":     {"range": 6.0,  "sound": "thud",   "volume": 0.6, "caption": "[Rütteln an einer Tür]"},    ## abgeschlossene Tür rütteln
	"unlock":     {"range": 3.0,  "sound": "jingle", "volume": 0.6, "caption": "[Schlüssel klirren im Schloss]"},    ## Schlüssel klirren
	"door_burst": {"range": 20.0, "sound": "bang",   "volume": 0.8, "alarm": true, "caption": "[Eine Tür kracht auf]"},
	"door_force": {"range": 20.0, "sound": "bang",   "volume": 0.8, "alarm": true, "caption": "[Eine Tür wird aufgebrochen]"},   ## Zimmertür aufgebrochen (6.19)
	"repair":     {"range": 6.0,  "sound": "thud",   "volume": 0.5, "caption": "[Hämmern an einer Tür]"},    ## Tür reparieren (6.19)
	"glass":      {"range": 16.0, "sound": "bang",   "volume": 0.7, "alarm": true, "caption": "[Glas splittert]"},   ## Scheibe des Schlüsselschranks  ## Tür vom Monster aufgerissen
	"hide":       {"range": 4.0,  "sound": "creak",  "volume": 0.35, "caption": "[Eine Schranktür knarrt]"},   ## in ein Versteck gehen
	"hide_burst": {"range": 20.0, "sound": "bang",   "volume": 1.0, "alarm": true, "caption": "[Eine Schranktür kracht auf]"},  ## Versteck vom Monster aufgerissen
	"drop":       {"range": 2.0,  "sound": "thud",   "volume": 0.4, "caption": "[Etwas wird abgestellt]"},    ## Gegenstand ablegen
	"drop_heavy": {"range": 4.0,  "sound": "thud",   "volume": 0.5, "caption": "[Etwas Schweres plumpst]"},    ## Kürbis oder großer Gegenstand
	"pumpkin_splat": {"range": 8.0, "sound": "thud", "volume": 0.8, "caption": "[Ein Kürbis zerplatzt]"},    ## Kürbis zerplatzt nach tiefem Fall (5.8)
	"wax_splat":  {"range": 5.0,  "sound": "thud",   "volume": 0.5, "caption": "[Eine Kerze zerbricht]"},    ## geworfene Kerze zerbricht (Streich, 6.13)
	"throw_land": {"range": 6.0,  "sound": "thud",   "volume": 0.5, "caption": "[Etwas fällt polternd]"},    ## Geworfenes landet (3.13) – lockt das Monster hin
	"throw_land_heavy": {"range": 9.0, "sound": "thud", "volume": 0.7, "caption": "[Etwas Schweres kracht zu Boden]"},  ## … ab Item.THROW_HEAVY kg
	"fire":       {"range": 5.0,  "sound": "rustle", "volume": 0.6, "caption": "[Feuer knistert]"},    ## Deko brennt, alle 2 s (5.11)
	"shock_drop": {"range": 6.0,  "sound": "thud",   "volume": 0.6, "caption": "[Etwas fällt zu Boden]"},    ## vor Schreck fallen gelassen (6.8)
	"chest":      {"range": 4.0,  "sound": "creak",  "volume": 0.4, "caption": "[Ein Truhendeckel knarrt]"},
	"drawer":     {"range": 3.0,  "sound": "creak",  "volume": 0.3, "caption": "[Eine Schublade schabt]"},    ## Schublade einer Kommode
	## Hotelkatzen (Spielkonzept 6.11) – das Monster überhört sie, es mag die Katzen
	"cat_meow":   {"range": 8.0,  "sound": "meow",   "volume": 0.45},   ## miaut (vor einer Tür, Geschenk)
	"cat_purr":   {"range": 1.5,  "sound": "purr",   "volume": 0.6, "caption": "[Schnurren]"},    ## schnurrt beim Streicheln
	"cat_cry":    {"range": 16.0, "sound": "cry",    "volume": 0.6, "alarm": true},  ## weint auf der Flucht vor dem Monster
	"cat_knock":  {"range": 5.0,  "sound": "thud",   "volume": 0.5, "caption": "[Etwas fällt um]"},    ## wirft Deko um
	"bats":       {"range": 8.0,  "sound": "flutter", "volume": 0.7},   ## aufgeschreckter Fledermausschwarm (4.22)
	"curtain":    {"range": 2.0,  "sound": "creak",  "volume": 0.15, "caption": "[Ein Vorhang raschelt]"},
	"bulb":       {"range": 2.0,  "sound": "creak",  "volume": 0.2, "caption": "[Eine Glühbirne quietscht im Gewinde]"},    ## Glühbirne heraus-/eindrehen
	"bulb_burst": {"range": 8.0,  "sound": "bang",   "volume": 0.35, "alarm": true, "caption": "[Eine Glühbirne platzt]"},
	"switch":     {"range": 1.0,  "sound": "blip",   "volume": 0.5, "caption": "[Klick – ein Lichtschalter]"},    ## Licht aus zusätzlich nach 4.4
	"harvest":    {"range": 3.0,  "sound": "thud",   "volume": 0.5, "caption": "[Ein Kürbisstiel reißt]"},
	"carve":      {"range": 3.0,  "sound": "creak",  "volume": 0.6, "caption": "[Ein Messer schabt im Kürbis]"},
	"salt":       {"range": 1.5,  "sound": "rustle", "volume": 0.3, "caption": "[Salz rieselt]"},    ## Salzlinie streuen (5.13)
	"wipe":       {"range": 2.0,  "sound": "creak",  "volume": 0.15, "caption": "[Wischen]"},   ## Spur wegwischen
	"map":        {"range": 1.0,  "sound": "rustle", "volume": 0.5, "caption": "[Papier raschelt]"},    ## Kartenblatt blättern
	"bag":        {"range": 1.0,  "sound": "rustle", "volume": 0.3, "caption": "[Rascheln in einer Tasche]"},    ## Kleines in die Tasche / heraus (3.2)
	"can":        {"range": 3.0,  "sound": "hiss",   "volume": 0.5, "caption": "[Zischen – eine Dose]"},    ## Getränkedose aufreißen
	"coffee":     {"range": 6.0,  "sound": "hiss",   "volume": 0.35, "caption": "[Die Kaffeemaschine gurgelt]"},   ## Kaffeemaschine mahlt und gurgelt, alle 5 s (3.11)
	"cup_break":  {"range": 5.0,  "sound": "bang",   "volume": 0.3, "caption": "[Eine Tasse zerbricht]"},    ## Tasse zerbricht (3.11, 3.12)
	"kettle":     {"range": 4.0,  "sound": "hiss",   "volume": 0.25, "caption": "[Ein Wasserkocher rauscht]"},   ## Wasserkocher rauscht, alle 5 s (3.12)
	"kettle_whistle": {"range": 8.0, "sound": "hiss", "volume": 0.5, "caption": "[Ein Wasserkocher pfeift]"},   ## Wasserkocher pfeift leise, wenn er fertig ist
	"keys":       {"range": 3.0,  "sound": "jingle", "volume": 0.6, "caption": "[Schlüssel klirren]"},    ## Schlüssel an den Bund
	"handset":    {"range": 2.0,  "sound": "thud",   "volume": 0.15, "caption": "[Ein Telefonhörer klappert]"},   ## Hörer abnehmen/auflegen/daneben legen
	"gasp":       {"range": 10.0, "sound": "gasp",   "volume": 1.0, "caption": "[Hastiges Luftholen]"},    ## nach Luft schnappen
	"pant":       {"range": 4.0,  "sound": "",       "volume": 0.0},    ## Keuchen außer Atem, alle 1,5 s (3.1) – zu hören über SynthAudio
	"knock":      {"range": 8.0,  "sound": "knock",  "volume": 0.7, "caption": "[Es klopft]"},
	"phone":      {"range": 18.0, "sound": "ring",   "volume": 0.6, "caption": "[Ein Telefon klingelt]"},    ## je Klingeln (4.14)
	"dice":       {"range": 10.0, "sound": "thud",   "volume": 0.4, "caption": "[Würfel klappern]"},    ## Würfeln, Spiel am Tisch
	"dart":       {"range": 6.0,  "sound": "dart",   "volume": 0.5, "caption": "[Ein Pfeil trifft die Scheibe]"},    ## Pfeil steckt in der Scheibe (6.10)
	"dart_wall":  {"range": 9.0,  "sound": "thud",   "volume": 0.5, "caption": "[Ein Pfeil prallt ab]"},    ## … prallt an der Wand ab und fällt
	"party":      {"range": 25.0, "sound": "",       "volume": 0.0},    ## Feier mit Musik, alle 8 s
	"punch":      {"range": 9.0,  "sound": "thud",   "volume": 0.8, "caption": "[Ein Schlag]"},    ## Schlag (Spieler oder Gast, 6.3)
	"scream":     {"range": 20.0, "sound": "scream", "volume": 1.0, "alarm": true},   ## Schreck – Stimme des Gastes (SynthAudio.VOICES)
	"death_scream": {"range": 20.0, "sound": "death_scream", "volume": 1.0, "alarm": true},   ## vom Monster geholt – jäh abgerissen
	"axe_swing":  {"range": 20.0, "sound": "",       "volume": 0.0, "alarm": true},   ## Kürbismann schlägt zu (4.19) – Ton spielt er selbst (3D)
	"pumpkin_land": {"range": 16.0, "sound": "thud", "volume": 1.0, "alarm": true, "caption": "[Ein schwerer Aufprall im Garten]"},   ## Kürbismann springt vom Lobbydach in den Garten (4.19)
	"laugh":      {"range": 8.0,  "sound": "",       "volume": 0.0},    ## Kinder lachen beim Toben und auf Feiern (6.13)
	## Aufzug (7.4): Motor an der Abfahrt, Glocke am Ziel – beide machen das Monster neugierig; Alarmknopf in der Kabine
	"elevator":   {"range": 14.0, "sound": "motor",  "volume": 0.5},
	"elevator_bell": {"range": 14.0, "sound": "ding", "volume": 0.6},
	"elevator_alarm": {"range": 30.0, "sound": "alarm", "volume": 1.0, "alarm": true},
	## Vorzeichen und Spuk (Spielkonzept 4.25–4.28, 5.17, 6.21)
	"crows":      {"range": 10.0, "sound": "caw",    "volume": 0.6},    ## aufgescheuchter Krähentrupp
	"crow":       {"range": 14.0, "sound": "caw",    "volume": 0.75},   ## eine Krähe krächzt dich an (Groll) – das Monster hört es
	"music_box":  {"range": 12.0, "sound": "",       "volume": 0.0},    ## Spieluhr spielt, alle 3 s – Ton spielt sie selbst
	"fuse":       {"range": 10.0, "sound": "fuse",   "volume": 0.8},    ## Sicherung wieder eingelegt (Stromausfall)
	"apple_tub":  {"range": 4.0,  "sound": "bubble", "volume": 0.5, "caption": "[Blubbern im Wasser]"},    ## Apfeltauchen, Gesicht ins Wasser
}
## Dämpfung je Hindernis zwischen Quelle und Hörer (offene Tür: ungedämpft)
const DAMP_WALL := 0.4
const DAMP_DOOR := 0.6
const DAMP_FLOOR := 0.3          ## je Geschossdecke
## Als Wand zählt nur, was mindestens so hoch ist (Möbel, Böden, Brüstungen nicht)
const WALL_MIN_HEIGHT := 2.5
const MAX_HITS := 4
## Wände, Türen, klares Glas
const NOISE_MASK := 1 | 2 | 64
## Ab dieser Hörweite zählt Lärm auch, wenn das Monster ruht (es lauscht aus dem Keller)
const LOUD := 8.0
## Gäste hören mit halber Reichweite
const GUEST_HEARING := 0.5
## Der Spieler hört fremde Geräusche bis zur doppelten Hörweite, mindestens aber so weit
const PLAYER_MIN_REACH := 8.0
## Nur Klang, ohne Lärm (`Game.sound_at`): so weit hört man das Ächzen eines Sterbenden (Axt, Lakengeist)
const GRUNT_RANGE := 8.0

# --- Tuning: Sichtbarkeit -----------------------------------------------------------
## Auffälligkeit (1,0 = steht normal im Dunkeln)
const LIGHT_FACTOR := 1.2        ## Licht am Ort: 1,0 (dunkel) … 2,2 (hell)
const CARRY_CANDLE := 0.6        ## eigenes Licht in der Hand
const CARRY_LANTERN := 0.8       ## Kürbislaterne
const CARRY_FLASHLIGHT := 0.9    ## Taschenlampe: der Kegel ist weit zu sehen (4.16)
const CARRY_UV := 1.2            ## UV-Licht: grell und fremd
const RUNNING := 0.4
const STANDING := -0.1
const CROUCHED := -0.25
## Beobachter: Grundweite × Auffälligkeit, Sichtkegel als Skalarprodukt (0,3 ≈ 145°, 0 = 180°)
const MONSTER_SIGHT := 8.0
const MONSTER_FOV_DOT := 0.3
const CHASE_SIGHT_BONUS := 5.0   ## während der Jagd, dann ohne Kegel (4.12)
const GUEST_SIGHT := 5.0
const GUEST_FOV_DOT := 0.0
const DISTRACTED := 0.6          ## Gast im Gespräch, beim Würfeln, auf der Feier, in Panik
## So nah zählt der Kegel nicht (man spürt, wer direkt neben einem steht)
const NEAR := 2.0
## Höchste mögliche Auffälligkeit – für die billige Vorprüfung
const MAX_CONSPICUITY := 1.0 + LIGHT_FACTOR + CARRY_UV + RUNNING
## Sichtlinie: Wände, Türen, Milchglas, Vorhänge (klares Glas lässt den Blick durch)
const SIGHT_MASK := 1 | 2 | 256 | HotelWindow.LAYER_BLOCK

static var _wall_cache := {}     ## Instanz-ID → Dämpfungsfaktor


## Beim Verlassen der Spielwelt (Game.reset): Die Instanz-IDs gehören dann nicht mehr zu Wänden.
static func clear_cache() -> void:
	_wall_cache.clear()


# --- Lärm ---------------------------------------------------------------------------

static func range_of(kind: String) -> float:
	return float(NOISE[kind]["range"])


## Hörweite einer Quelle am Ort des Hörers nach Wänden, Türen und Geschossdecken.
## `enough`: Ist die Hörweite schon darunter, wird nicht weiter gerechnet (spart Strahlen).
static func audible_range(world: World3D, src: Vector3, listener: Vector3, loudness: float, enough: float = 0.0) -> float:
	var a := _ear(src)
	var b := _ear(listener)
	var r := loudness * pow(DAMP_FLOOR, absi(_storey(src) - _storey(listener)))
	if r < enough or a.distance_to(b) < 0.3:
		return r
	var space := world.direct_space_state
	var query := PhysicsRayQueryParameters3D.create(a, b, NOISE_MASK)
	var exclude: Array[RID] = []
	for i in MAX_HITS:
		query.exclude = exclude
		var hit := space.intersect_ray(query)
		if hit.is_empty():
			break
		r *= _damping(hit["collider"])
		if r < enough:
			break
		exclude.append(hit["rid"])
	return r


## Stockwerk: Untergeschoss −1, Erdgeschoss 0, Obergeschoss 1
static func _storey(p: Vector3) -> int:
	if p.y >= LevelBuilder.UP_Y - 0.3:
		return 1
	return 0 if p.y >= -0.3 else -1


## Ohrhöhe über dem Boden des Stockwerks – so laufen die Strahlen durch Türöffnungen.
static func _ear(p: Vector3) -> Vector3:
	var floor_y: float = [LevelBuilder.CELLAR_Y, 0.0, LevelBuilder.UP_Y][_storey(p) + 1]
	return Vector3(p.x, floor_y + 1.2, p.z)


static func _damping(collider: Object) -> float:
	var node := collider as Node
	if node == null:
		return 1.0
	var door := _door_of(node)
	if door:
		return 1.0 if door.is_open else DAMP_DOOR
	var body := node as CollisionObject3D
	if body and body.collision_layer & 64:
		return DAMP_DOOR   # geschlossenes Fenster
	var key := node.get_instance_id()
	if not _wall_cache.has(key):
		var f := 1.0
		for child in node.get_children():
			var cs := child as CollisionShape3D
			if cs and cs.shape is BoxShape3D and (cs.shape as BoxShape3D).size.y >= WALL_MIN_HEIGHT:
				f = DAMP_WALL
		_wall_cache[key] = f
	return _wall_cache[key]


static func _door_of(node: Node) -> Door:
	var n := node
	for i in 4:
		if n == null:
			return null
		if n is Door:
			return n
		n = n.get_parent()
	return null


# --- Sichtbarkeit -------------------------------------------------------------------

## Wie auffällig ist ein Akteur (Spieler oder Gast)? `light` = Licht am Ort ohne eigenes Licht.
static func conspicuity(actor, light: float, entering_hide: bool = false) -> float:
	var c := 1.0 + LIGHT_FACTOR * clampf(light, 0.0, 1.0)
	var held = actor.held
	if held != null and is_instance_valid(held):
		if held.flashlight:
			c += held.flashlight.carried_conspicuity()
		elif held.lit:
			c += CARRY_LANTERN if held.kind == Item.Kind.CARVED_PUMPKIN else CARRY_CANDLE
	if actor.running:
		c += RUNNING
	elif actor.crouching:
		c += CROUCHED
	elif not entering_hide and Vector2(actor.velocity.x, actor.velocity.z).length() < 0.1:
		c += STANDING
	return c


## Sieht `observer` (Augen bei `eye`, Blick `forward`) den Akteur? Sichtweite = base × Auffälligkeit
## + bonus; fov_dot < −1 = ohne Kegel. `at`: andere Zielstelle (z. B. vor dem Versteck).
static func can_see(observer: CollisionObject3D, eye: Vector3, forward: Vector3, base: float, fov_dot: float,
		actor, bonus: float = 0.0, entering_hide: bool = false, at: Vector3 = Vector3.INF) -> bool:
	var feet: Vector3 = actor.global_position if at == Vector3.INF else at
	var target: Vector3 = feet + Vector3.UP * (0.95 if actor.crouching else 1.5)
	var dist := observer.global_position.distance_to(feet)
	if dist > base * MAX_CONSPICUITY + bonus:
		return false
	var to := target - eye
	var length := to.length()
	if fov_dot >= -1.0 and length > NEAR and forward.dot(to / length) < fov_dot:
		return false
	# Billig vor teuer: Auffälligkeit bei vollem Licht und ein Sichtstrahl, erst dann light_at (viele Strahlen)
	if dist > base * conspicuity(actor, 1.0, entering_hide) + bonus \
			or not clear_line(observer.get_world_3d(), eye, target, observer):
		return false
	var light := 0.0
	if Game.director:
		light = Game.director.light_at(target, actor.held)
	return dist <= base * conspicuity(actor, light, entering_hide) + bonus


## Freie Sichtlinie von `from` nach `to` (Standard: Wände, Türen, Milchglas, Vorhänge – klares Glas lässt durch).
## `skip`: dieser Körper zählt nicht (der Beobachter selbst).
static func clear_line(world: World3D, from: Vector3, to: Vector3, skip: CollisionObject3D = null, mask: int = SIGHT_MASK) -> bool:
	var query := PhysicsRayQueryParameters3D.create(from, to, mask)
	if skip:
		query.exclude = [skip.get_rid()]
	return world.direct_space_state.intersect_ray(query).is_empty()
