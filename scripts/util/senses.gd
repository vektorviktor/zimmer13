class_name Senses
## Lärm & Sichtbarkeit – ein gemeinsames System (Spielkonzept 4.15).
## Jede Aktion hat eine Lautstärke (= Hörweite in Metern), jeder Akteur eine Auffälligkeit.
## Monster und Gäste rechnen gleich, nur mit eigenen Ohren und Augen. Alle Werte stehen hier.
##
## Lärm entsteht über `Game.noise(art, ort, quelle)`: spielt das Geräusch für den Spieler und
## meldet es dem Director (Monster) und Social (Gäste).

# --- Tuning: Lärm -------------------------------------------------------------------
## Art → Hörweite in m (`range`), Geräusch für den Spieler (`sound`, `volume`), erschreckt Gäste (`alarm`).
## Ohne `sound` ist es Lärm, den man nicht eigens hört (Schritte, Musik läuft extra).
const NOISE := {
	"step":       {"range": 2.0,  "sound": "",       "volume": 0.0},    ## Gehen auf Holz/Fliesen (Teppich, geduckt: still)
	"run":        {"range": 10.0, "sound": "",       "volume": 0.0},    ## alle 0,6 s
	"land":       {"range": 4.0,  "sound": "thud",   "volume": 0.2},    ## nach einem Sprung
	"door":       {"range": 5.0,  "sound": "creak",  "volume": 0.5},    ## Tür öffnen/schließen (Knarren)
	"rattle":     {"range": 6.0,  "sound": "thud",   "volume": 0.6},    ## abgeschlossene Tür rütteln
	"unlock":     {"range": 3.0,  "sound": "jingle", "volume": 0.6},    ## Schlüssel klirren
	"door_burst": {"range": 20.0, "sound": "bang",   "volume": 0.8, "alarm": true},  ## Tür vom Monster aufgerissen
	"hide":       {"range": 4.0,  "sound": "creak",  "volume": 0.35},   ## in ein Versteck gehen
	"hide_burst": {"range": 20.0, "sound": "bang",   "volume": 1.0, "alarm": true},  ## Versteck vom Monster aufgerissen
	"drop":       {"range": 2.0,  "sound": "thud",   "volume": 0.4},    ## Gegenstand ablegen
	"drop_heavy": {"range": 4.0,  "sound": "thud",   "volume": 0.5},    ## Kürbis oder großer Gegenstand
	"shock_drop": {"range": 6.0,  "sound": "thud",   "volume": 0.6},    ## vor Schreck fallen gelassen (6.8)
	"chest":      {"range": 4.0,  "sound": "creak",  "volume": 0.4},
	"curtain":    {"range": 2.0,  "sound": "creak",  "volume": 0.15},
	"bulb":       {"range": 2.0,  "sound": "creak",  "volume": 0.2},    ## Glühbirne heraus-/eindrehen
	"bulb_burst": {"range": 8.0,  "sound": "bang",   "volume": 0.35, "alarm": true},
	"switch":     {"range": 1.0,  "sound": "blip",   "volume": 0.5},    ## Licht aus zusätzlich nach 4.4
	"harvest":    {"range": 3.0,  "sound": "thud",   "volume": 0.5},
	"carve":      {"range": 3.0,  "sound": "creak",  "volume": 0.6},
	"wipe":       {"range": 2.0,  "sound": "creak",  "volume": 0.15},   ## Spur wegwischen
	"map":        {"range": 1.0,  "sound": "rustle", "volume": 0.5},    ## Kartenblatt blättern
	"keys":       {"range": 3.0,  "sound": "jingle", "volume": 0.6},    ## Schlüssel an den Bund
	"handset":    {"range": 2.0,  "sound": "thud",   "volume": 0.15},   ## Hörer abnehmen/auflegen/daneben legen
	"gasp":       {"range": 10.0, "sound": "gasp",   "volume": 1.0},    ## nach Luft schnappen
	"knock":      {"range": 8.0,  "sound": "knock",  "volume": 0.7},
	"phone":      {"range": 18.0, "sound": "ring",   "volume": 0.6},    ## je Klingeln (4.14)
	"dice":       {"range": 10.0, "sound": "thud",   "volume": 0.4},    ## Würfeln, Spiel am Tisch
	"party":      {"range": 25.0, "sound": "",       "volume": 0.0},    ## Feier mit Musik, alle 8 s
	"scream":     {"range": 20.0, "sound": "scream", "volume": 0.9, "alarm": true},
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


## Stockwerk: Keller −1, Erdgeschoss 0, Obergeschoss 1
static func _storey(p: Vector3) -> int:
	if p.y >= LevelBuilder.UP_Y - 0.3:
		return 1
	return 0 if p.y >= -0.3 else -1


## Ohrhöhe über dem Boden des Stockwerks – so laufen die Strahlen durch Türöffnungen.
static func _ear(p: Vector3) -> Vector3:
	var floor_y: float = [-3.5, 0.0, LevelBuilder.UP_Y][_storey(p) + 1]
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
	var light := 0.0
	if Game.director:
		light = Game.director.light_at(target, actor.held)
	if dist > base * conspicuity(actor, light, entering_hide) + bonus:
		return false
	var query := PhysicsRayQueryParameters3D.create(eye, target, SIGHT_MASK)
	query.exclude = [observer.get_rid()]
	return observer.get_world_3d().direct_space_state.intersect_ray(query).is_empty()
