class_name Item
extends RigidBody3D
## Physischer Gegenstand. Kein verstecktes Inventar: Große Dinge trägt man einzeln in den Händen, Kleines
## (POCKET_KINDS) passt zusätzlich in die Tasche des Spielers (Player.bag, Spielkonzept 3.2); Münzen werden sofort
## zu Geld. Ursprung = Unterseite, lokale +Z-Achse = Vorderseite (z. B. das Gesicht eines geschnitzten Kürbisses).
##
## Handwerk: Messer in der Hand + Kürbis → schnitzen; Kerze in der Hand + geschnitzter
## Kürbis ohne Licht → Kerze hineinstellen.
##
## Kompass: Die Nadel zeigt nach Norden (Welt −Z) und schwingt nach. In der Nähe des
## Monsters zittert sie, ganz nah dreht sie sich wild – ebenso bei Halluzinationen.
##
## Taschenlampe (Spielkonzept 4.16): Licht und Batterie stecken in einem Flashlight-Knoten.
## Batterie oder UV-Aufsatz in der Hand + Taschenlampe (oder umgekehrt) → einsetzen.
##
## Aufhängen (Spielkonzept 5.6): Lakengespenst, Lichterkette und Spinnweben hängen an der Wand
## (Player: [G] auf eine Wand). Aufgehängt sind sie eingefroren, ihr Ursprung ist der Haken (Lichterkette:
## Mitte der Aufhängelinie), lokale +Z zeigt von der Wand weg. Sie bewegen sich immer ein wenig und stärker,
## wenn das Monster oder der Lakengeist naht – früher, als die Lampen flackern (MonsterDirector.deco_unrest_at).
## Einem Lakengespenst gibt man einen Zierkürbis in die Hände; bei einem starken Ruck fällt er herunter.
## Herbstlaub liegt verstreut am Boden, in der Hand ist es ein Haufen.
## Ein Kürbis (auch Zierkürbis), der mehr als BURST_HEIGHT tief fällt, zerplatzt (Spielkonzept 5.8): Stücke fliegen
## davon, übrig bleibt Kürbismatsch – am Boden ein Spritzer in Größe und Farbe der Sorte, in der Hand ein Klumpen. Der
## Spritzer des Riesenkürbisses reicht für viele Hände voll. Er wird zu Suppe gekocht (Stove) oder verblasst nach
## einem Spieltag kaum merklich und verschwindet.
## Mehr Deko (Spielkonzept 5.7): Fledermausgirlande (flattert bei Unruhe), Plastikspinne am Faden (wippt),
## Hexenbesen (lehnt an der Wand, kippt beim starken Ruck um), Totenkopf (Kerze hinein wie beim Kürbis).
##
## Kompass, Kartenblätter und Schlüssel (außer dem Ausgangsschlüssel) liegen nur in der Welt,
## bis man sie aufhebt – dann wandern sie an den Körper des Spielers (Player.has_compass,
## map_pages, keyring; Spielkonzept 3.2).

enum Kind { PUMPKIN, CARVED_PUMPKIN, CANDLE, KEY, COBWEB, LEAVES, COINS, KNIFE, DICE_CUP, LOADED_DICE, BULB, CLOTHING, COMPASS, MAP, FLASHLIGHT, BATTERY, UV_FILTER, CHESS_BOARD, SWEETS, SHEET_GHOST, LIGHT_STRING, MINI_PUMPKIN,
	BAT_GARLAND, SPIDER, SKULL, BROOM, BED_SHEET, ROAST_PUMPKIN, SODA_CAN, PUMPKIN_MUSH, CROWBAR, TOOLBOX, COFFEE,
	PUMPKIN_HEAD }

const LAYER := 4
const MASK := 1 | 2 | 4 | 16 | 64 | 256
## So tief lässt Godots Physik ruhende Körper in den Boden einsinken (contact_max_allowed_penetration, 1 cm) – die
## Kollisionsform liegt um so viel tiefer, sonst versinken flache Dinge (Schachbrett, Laub) halb oder ganz im Boden.
const SINK := 0.01
const MAP_WIDTH := 0.28   ## Kartenblatt: Breite (m), Höhe nach Seitenverhältnis des Plans
## Schlüssel, die nicht an den Schlüsselbund passen – sie müssen in der Hand getragen werden
const HAND_ONLY_KEYS := ["ausgang"]
## Grundpreise für den Handel mit Gästen
const PRICES := {
	Kind.PUMPKIN: 4, Kind.CARVED_PUMPKIN: 10, Kind.CANDLE: 3, Kind.COBWEB: 3,
	Kind.LEAVES: 1, Kind.KNIFE: 5, Kind.KEY: 0, Kind.COINS: 0, Kind.DICE_CUP: 2, Kind.LOADED_DICE: 6, Kind.BULB: 4, Kind.CLOTHING: 0, Kind.COMPASS: 6, Kind.MAP: 2,
	Kind.FLASHLIGHT: 8, Kind.BATTERY: 3, Kind.UV_FILTER: 12, Kind.CHESS_BOARD: 4, Kind.SWEETS: 1,
	Kind.SHEET_GHOST: 5, Kind.LIGHT_STRING: 9, Kind.MINI_PUMPKIN: 2,
	Kind.BAT_GARLAND: 4, Kind.SPIDER: 2, Kind.SKULL: 8, Kind.BROOM: 7, Kind.BED_SHEET: 1, Kind.ROAST_PUMPKIN: 5,
	Kind.SODA_CAN: 1,
	Kind.PUMPKIN_MUSH: 0,
	Kind.CROWBAR: 6, Kind.TOOLBOX: 8,
	Kind.COFFEE: 1,
	Kind.PUMPKIN_HEAD: 0,
}
## Kleines, das in die Tasche passt (Spielkonzept 3.2) – eine Kerze nur, wenn sie nicht brennt (fits_pocket)
const POCKET_KINDS := [Kind.SWEETS, Kind.SODA_CAN, Kind.MINI_PUMPKIN, Kind.CANDLE, Kind.KNIFE, Kind.BATTERY, Kind.BULB,
	Kind.UV_FILTER, Kind.DICE_CUP, Kind.LOADED_DICE]
## Getränkedose: die Sorten und ihre Farbe
const SODA_COLORS := {"limo": Color(0.95, 0.55, 0.1), "cola": Color(0.7, 0.07, 0.07)}
## Was man an die Wand hängen kann (Spielkonzept 5.6, 5.7) – der Besen lehnt nur daran
const HANGABLE := [Kind.SHEET_GHOST, Kind.LIGHT_STRING, Kind.COBWEB, Kind.BAT_GARLAND, Kind.SPIDER, Kind.BROOM]
## Mit Kerze darin: Kerze in der Hand + das hier → Licht (Spielkonzept 5.4, 5.7)
const CANDLE_HOLDERS := [Kind.CARVED_PUMPKIN, Kind.SKULL]
## Deko, die eine Katze umwerfen kann (Spielkonzept 6.11) – flache Dinge (Laub, Spinnweben) kippen nicht.
const TOPPLE_KINDS := [Kind.PUMPKIN, Kind.CARVED_PUMPKIN, Kind.CANDLE, Kind.SKULL]
const SPIDER_THREAD := 0.45     ## Plastikspinne: so lang hängt sie unter dem Haken
const BROOM_LENGTH := 1.55
const BROOM_LEAN := 0.2         ## Hexenbesen: so schräg lehnt er an der Wand (rad)
const GHOST_HEIGHT := 0.78      ## Lakengespenst: vom Haken bis zum Saum
const GHOST_DEPTH := 0.17       ## Kopf an der Wand: so weit sitzt der Haken vor der Wandfläche
const STRING_SAG := 0.13        ## Lichterkette: Durchhang je Bogen
const STRING_COLORS: Array[Color] = [Color(1.0, 0.5, 0.1), Color(0.6, 0.25, 0.95), Color(0.35, 0.9, 0.3), Color(1.0, 0.85, 0.5)]
## Herbstlaub: Farben der Blätter (auch der Laubhaufen unter den Bäumen, ResourceSpot)
const LEAF_COLORS: Array[Color] = [Color(0.75, 0.35, 0.08), Color(0.6, 0.15, 0.05), Color(0.8, 0.55, 0.1), Color(0.45, 0.25, 0.08)]
const JOLT_UNREST := 0.8        ## ab dieser Unruhe kann der Zierkürbis aus den Händen fallen
## Zerplatzen (Spielkonzept 5.8): diese Arten, ab so viel Fallhöhe (m); als Aufprall zählt, wenn ein Gegenstand mit
## mindestens IMPACT_SPEED (m/s) fällt und auf einen Schlag mehr als die Hälfte davon verliert
const BURST_KINDS := [Kind.PUMPKIN, Kind.CARVED_PUMPKIN, Kind.MINI_PUMPKIN, Kind.CANDLE, Kind.BULB, Kind.COFFEE]
const BURST_HEIGHT := 3.0
## Kerzen, Glühbirnen und Kaffeetassen zerbrechen schon aus geringerer Höhe (m; Spielkonzept 5.11, 7.3, 3.11)
const BREAK_HEIGHT := {Kind.CANDLE: 2.0, Kind.BULB: 1.5, Kind.COFFEE: 1.0}
## Kaffeetasse (Spielkonzept 3.11): Porzellan und Kaffee
const CUP_COLOR := Color(0.93, 0.92, 0.88)
const COFFEE_COLOR := Color(0.18, 0.09, 0.04)
## Scherben einer platzten Glühbirne: so viele (von, bis), Glas und Gewinde
const BULB_SHARDS := Vector2i(5, 8)
const BULB_GLASS := Color(0.9, 0.93, 0.97)
const BULB_SOCKET := Color(0.62, 0.56, 0.42)
const IMPACT_SPEED := 3.0
## Wurf: als Aufprall zählt, wenn er mit mindestens so viel Tempo (m/s) fliegt und auf einen Schlag die Hälfte verliert
const THROW_IMPACT := 1.5
const MUSH_TEXTURE := "res://assets/textures/pumpkin_splash.png"
## Mittlere Farbe der Textur – die Spritzer werden durch sie geteilt und in der Farbe des Kürbisses eingefärbt
const MUSH_TEX_COLOR := Color(0.836, 0.674, 0.361)
## Fruchtfleisch: Kürbismatsch hat zur Hälfte diese Farbe, zur Hälfte die der Schale
const FLESH_COLOR := Color(0.95, 0.6, 0.2)
const MUSH_SIZE := 0.9          ## Kantenlänge des Spritzers (m), wenn nichts anderes gespeichert ist
const MINI_SPLAT := 0.4         ## Spritzer eines Zierkürbisses (m; Sorten: PumpkinKinds „splat“)
const HANDFUL_SPLAT := 0.6      ## eine Hand voll aus einem großen Spritzer, wieder abgelegt (m)
const MUSH_SPLATS_PER_M := 4.0  ## kleine Spritzer rings um den großen, je Meter Kantenlänge (Item._lay_mush)
## Stücke, die beim Zerplatzen davonfliegen: so viele je Meter Spritzer (höchstens CHUNK_MAX), liegen so lange
## (Spielzeit, s), dann schrumpfen sie weg
const CHUNKS_PER_M := 7.0
const CHUNK_MAX := 26
const CHUNK_STAY := Vector2(5.0, 9.0)
const MINI_COLOR := Color(0.9, 0.48, 0.1)
const LARGE_SPEED := 0.8        ## Gehtempo mit etwas Großem in beiden Händen (Riesenkürbis: PumpkinKinds „slow“)
## Kürbismatsch: bleibt so lange (Spielzeit, s) unverändert, verblasst danach in MUSH_FADE und ist weg
const MUSH_ROT_AFTER := Calendar.DAY_SECONDS
const MUSH_FADE := Calendar.DAY_SECONDS * 0.5
## Kürbisse faulen (Spielkonzept 5.10): geschnitzte nach ROT_CARVED, ungeschnitzte und Zierkürbisse nach ROT_WHOLE –
## ab ROT_WILT der Zeit welk (dunkler, Deko × WILT_DECO), ab ROT_SAG eingefallen (gestaucht, × SAG_DECO), dann weg.
## Schnitzen setzt die Restzeit auf höchstens ROT_CARVED. Geprüft alle ROT_CHECK s.
const ROT_KINDS := [Kind.PUMPKIN, Kind.CARVED_PUMPKIN, Kind.MINI_PUMPKIN]
const ROT_CARVED := 3.0 * Calendar.DAY_SECONDS
const ROT_WHOLE := 7.0 * Calendar.DAY_SECONDS
const ROT_WILT := 0.6
const ROT_SAG := 0.85
const WILT_DECO := 0.7
const SAG_DECO := 0.4
const ROT_CHECK := 1.0
const ROT_NAMES := ["", " (welk)", " (eingefallen)"]
## Füllmaterial (5.10): wächst nach und zählt an einer Stelle nur bis MonsterDirector.FILLER_CAP – dazu die kleinen
## Kürbissorten (is_filler)
const FILLER_KINDS := [Kind.LEAVES, Kind.COBWEB, Kind.CANDLE, Kind.MINI_PUMPKIN]
## Ausschlag (rad): leichtes Wehen, bei voller Unruhe
const SWAY: Dictionary = {
	Kind.SHEET_GHOST: Vector2(0.035, 0.32), Kind.LIGHT_STRING: Vector2(0.03, 0.34), Kind.COBWEB: Vector2(0.05, 0.22),
	Kind.BAT_GARLAND: Vector2(0.03, 0.3), Kind.SPIDER: Vector2(0.04, 0.35),
}

var kind: Kind = Kind.PUMPKIN
## Kürbis, geschnitzter und gebratener Kürbis: Sorte (PumpkinKinds, Spielkonzept 5.8, 3.8)
var variety := PumpkinKinds.DEFAULT
## Geschnitzter Kürbis: Fratze 1 … PumpkinModel.FACES – beim Schnitzen ausgewürfelt, im Zusatz „f=n“ gespeichert
var face := 0
var display_name := ""
var deco_strength := 0.0
## Kürbisse (ROT_KINDS): Spielzeit, zu der er ganz verfault ist, und erreichte Stufe (0 frisch, 1 welk, 2 eingefallen)
var rot_at := INF
var rot_stage := 0
var _rot_timer := 0.0
var is_large := false
var key_id := ""
var coin_value := 0
var is_held := false
## Besitzer: "" = niemand, "player" oder die ID eines Gastes
var owner_id := ""
var lit := false
var light: FlickerLight
var burn_time := 0.0
## Glühbirne: durchgebrannt (nutzlos, nur noch Scherben im Glas)
var broken := false
## Kleidungsstück: wem es gehörte (Gast-ID) – Spur von Verschwundenen
var clothing_of := ""
## Getränkedose: „limo“ oder „cola“ (SODA_COLORS)
var flavor := ""

var _glow_material: ShaderMaterial
## Kompass: Nadel (dreht um die lokale Y-Achse), Winkel und Schwung der Feder
var _needle: Node3D
var _needle_angle := 0.0
var _needle_speed := 0.0
var _needle_spin := 0.0
var _needle_time := 0.0
## Kartenblatt: welche Ebene (HotelMap.PAGES)
var page_id := ""
## Taschenlampe: Licht, Batterie, UV (nur bei Kind.FLASHLIGHT)
var flashlight: Flashlight
## Steckt beim Spieler in der Tasche (Kompass in der linken Hand) – nicht mehr in der Welt
var pocketed := false
## Liegt in der Tasche für Kleines (Player.bag): unsichtbar, ohne Physik, nicht in der Welt
var in_bag := false
## Hängt an der Wand (HANGABLE)
var hung := false
## Lakengespenst: hält einen Zierkürbis in den Händen
var holds_pumpkin := false
## Lichterkette: Länge entlang der Wand, wenn sie hängt
var string_length := 0.0
## Lakengespenst: der Lakengeist steht davor und kreist mit den Händen – es kreist mit (SheetGhost)
var circling_with: Node3D
## Kürbismatsch: Spielzeit (MonsterDirector.elapsed), zu der der Kürbis zerplatzt ist; Kantenlänge des Spritzers
## (m); reicht für so viele Hände voll (Riesenkürbis: viele, sonst 1)
var mushed_at := 0.0
var mush_size := MUSH_SIZE
var portions := 1
## Geworfen (Streich, 6.13): zerplatzt bzw. zerbricht beim ersten Aufprall (throw_from)
var thrown := false

var _shape: CollisionShape3D
## Drehpunkt am Haken: alles, was schwingt (Lakengespenst, Lichterkette, Spinnweben)
var _swing: Node3D
var _coil: Node3D
var _strand: Node3D
var _bulb_materials: Array[ShaderMaterial] = []
var _pumpkin_mesh: Node3D
var _pile: Node3D
var _spread: Node3D
var _wings: Array[Node3D] = []   ## Fledermausgirlande: je Fledermaus linker und rechter Flügel
var _thread: Node3D              ## Plastikspinne: Faden und Spinne darunter
var _spider: Node3D
var _sway_time := 0.0
var _sway_phase := 0.0
var _sway_seed := 0.0
var _unrest := 0.0
var _unrest_timer := 0.0
var _lean := 0.0          ## seitlich weg von der Quelle der Unruhe (−1..1, lokale X)
var _fall_top := -INF     ## Zerplatzen: höchster Punkt des laufenden Falls
var _last_vy := 0.0
var _last_speed := 0.0   ## Wurf: Tempo im letzten Physikschritt
var _mush_mat: ShaderMaterial
## Kürbismatsch: hier wurden die Flecken zuletzt auf die Fläche gelegt (_lay_mush; INF = noch nicht)
var _laid_at := Vector3.INF
## Kürbismatsch gerade zerplatzt (burst): beim ersten Hinlegen breitet er sich aus (TraceMark.SPREAD „mush“) – nicht
## aus dem Spielstand und nicht nach dem Ablegen; der Tween dazu
var mush_fresh := false
## Kürbismatsch draußen im Regen verwaschen (RainVeil): 0 … 1, bei 1 wird er zum Schleier und ist weg – im Zusatzfeld
## als „w=…“ (die Zahlen davor liest _build der Reihe nach, „w=“ ist keine)
var mush_wash := 0.0
var _wash_timer := 0.0
var _mush_outdoor := -1   ## -1 = noch nicht geprüft, sonst 0/1 (je Ablageort, _lay_mush setzt zurück)
var _grow_tween: Tween


static func create(p_kind: Kind, extra: String = "") -> Item:
	var item := Item.new()
	item.kind = p_kind
	item._build(extra)
	if p_kind in ROT_KINDS:
		item._read_rot(extra)
	return item


func _ready() -> void:
	add_to_group("items")
	add_to_group("time_skip")   # Zeitsprung im Schlaf (SleepSkip)
	set_meta("interactable", self)
	set_physics_process(kind in BURST_KINDS)


func _process(delta: float) -> void:
	if _needle:
		_update_needle(delta)
	if hung:
		_sway(delta)
	if _mush_mat and not is_held:
		_settle_mush()
		_rot()
		_wash_mush(delta)
	if rot_at < INF:
		_rot_timer -= delta
		if _rot_timer <= 0.0:
			_rot_timer = ROT_CHECK
			_decay()
	if not lit or burn_time <= 0.0:
		return
	burn_time -= delta
	if burn_time <= 0.0:
		_extinguish()


## Zeitsprung im Schlaf (SleepSkip, Spielkonzept 3.6): Kerzen und Kürbislichter brennen weiter
## (Fäulnis hängt an der Uhr, Item.rot_at).
func skip_time(dt: float) -> void:
	if lit and burn_time > 0.0:
		burn_time = maxf(0.001, burn_time - dt)   # ausgehen lässt sie das nächste Bild
	if _mush_mat:
		_wash_timer += dt   # Kürbismatsch verwäscht im Regen weiter (das nächste Bild rechnet es nach)


## Beschriftung eines Schlüssels am Bund
static func key_label(id: String) -> String:
	if id == KeyCabinet.KEY_ID:
		return "Generalschlüssel"
	return "Schlüssel" if id == "" else "Schlüssel %s" % id.replace("zimmer_", "Zimmer ")


## Wandert beim Aufheben an den Körper statt in die Hand
func goes_to_pocket() -> bool:
	return kind == Kind.COMPASS or kind == Kind.MAP or (kind == Kind.KEY and not key_id in HAND_ONLY_KEYS)


## Als Taschen-Gegenstand des Spielers: aus Gruppe und Interaktion heraus (wird nicht als
## Welt-Gegenstand gespeichert).
func make_pocketed() -> void:
	pocketed = true
	set_held(true)
	remove_from_group("items")
	remove_meta("interactable")


## Passt in die Tasche für Kleines (Spielkonzept 3.2)? Brennendes nicht.
func fits_pocket() -> bool:
	return kind in POCKET_KINDS and not lit


## In die Tasche des Spielers: unsichtbar, eingefroren, aus Gruppe und Interaktion heraus. Wird mit dem Spieler
## gespeichert (SaveManager „bag“), nicht als Welt-Gegenstand.
func put_in_bag() -> void:
	in_bag = true
	set_held(true)
	visible = false
	process_mode = Node.PROCESS_MODE_DISABLED
	remove_from_group("items")
	remove_meta("interactable")


## Wieder aus der Tasche (in eine Hand – des Spielers oder eines Gastes, dem man es schenkt).
func take_from_bag() -> void:
	in_bag = false
	visible = true
	process_mode = Node.PROCESS_MODE_INHERIT
	add_to_group("items")
	set_meta("interactable", self)


func price() -> int:
	if broken:
		return 0
	match kind:
		Kind.PUMPKIN:
			return int(PumpkinKinds.data(variety)["price"])
		Kind.CARVED_PUMPKIN:
			return int(PumpkinKinds.data(variety)["price"]) + 6
	return int(PRICES.get(kind, 1))


## Gehtempo beim Tragen (Anteil): Großes mit beiden Händen LARGE_SPEED, der Riesenkürbis noch langsamer
## (Spielkonzept 5.8, PumpkinKinds „slow“).
func carry_speed() -> float:
	if not is_large:
		return 1.0
	if kind in [Kind.PUMPKIN, Kind.CARVED_PUMPKIN]:
		return float(PumpkinKinds.data(variety).get("slow", LARGE_SPEED))
	return LARGE_SPEED


## Lage in der Hand des Spielers (Hand = Player.HAND_REST vor der Kamera): Großes mittig vor dem Bauch, der
## Riesenkürbis tiefer und weiter vorn – er verdeckt trotzdem den unteren Teil der Sicht.
func hold_offset() -> Vector3:
	if not is_large:
		return Vector3.ZERO
	if kind in [Kind.PUMPKIN, Kind.CARVED_PUMPKIN] and variety == "giant":
		return Vector3(-0.22, -0.78, -0.4)
	return Vector3(-0.22, -0.28, -0.12)


func can_carve() -> bool:
	return kind == Kind.PUMPKIN and bool(PumpkinKinds.data(variety)["carve"])


## Zusatzangabe für Item.create(), mit der sich der Gegenstand nachbauen lässt (Speichern).
func create_extra() -> String:
	match kind:
		Kind.KEY:
			return key_id
		Kind.COINS:
			return str(coin_value)
		Kind.BULB:
			return "broken" if broken else ""
		Kind.ROAST_PUMPKIN:
			return "" if variety == PumpkinKinds.DEFAULT else variety
		Kind.PUMPKIN:
			return ",".join(([] if variety == PumpkinKinds.DEFAULT else [variety]) + [_rot_extra()])
		Kind.MINI_PUMPKIN:
			return _rot_extra()
		Kind.PUMPKIN_MUSH:
			return mush_extra(variety, mushed_at, mush_size, portions) + (",w=%.3f" % mush_wash if mush_wash > 0.0 else "")
		Kind.CARVED_PUMPKIN:
			var parts: Array[String] = []
			if variety != PumpkinKinds.DEFAULT:
				parts.append(variety)
			if not lit:
				parts.append("unlit")
			parts.append("f=%d" % face)
			parts.append(_rot_extra())
			return ",".join(parts)
		Kind.SKULL:
			return "lit" if lit else ""
		Kind.CLOTHING:
			return clothing_of
		Kind.MAP:
			return page_id
		Kind.FLASHLIGHT:
			return flashlight.save_extra()
		Kind.SHEET_GHOST:
			return "pumpkin" if holds_pumpkin else ""
		Kind.LIGHT_STRING:
			return ("%.2f" % string_length) if hung else ""
		Kind.SODA_CAN:
			return flavor
	return ""


func get_prompt(player: Player) -> String:
	if is_toppled():
		return "%s aufstellen [E]" % display_name
	var held := player.held_kind()
	if _carving(held):
		return "%s schnitzen [E]" % display_name if can_carve() else "%s – zu hart zum Schnitzen" % display_name
	if _takes_candle(held):
		return "Kerze hineinstellen [E]"
	var fitting := _fitting_prompt(held, player)
	if fitting != "":
		return fitting
	if _takes_mini_pumpkin(held):
		return "Zierkürbis in die Hände geben [E]"
	if kind == Kind.COINS:
		return "%s aufheben (+%d) [E]" % [display_name, coin_value]
	var verb := "abnehmen" if hung else ("aufsammeln" if kind in [Kind.LEAVES, Kind.PUMPKIN_MUSH] else "nehmen")
	if portions > 1:
		verb = "aufsammeln (noch %d Hände voll)" % portions
	if verb == "nehmen" and player.held and player.bag_takes(self):
		verb = "einstecken"   # die Hand ist voll – Kleines kommt in die Tasche (Spielkonzept 3.2)
	if owner_id != "" and owner_id != "player" and Game.social:
		return "%s %s [E]  – gehört %s" % [display_name, verb, Game.social.guest_name(owner_id)]
	return "%s %s [E]" % [display_name, verb]


## Aktions-Symbol über dem Hinweis (IconArt): Kaffee; Kerze hineinstellen und Zierkürbis in die Hände = Schmücken.
func get_icon(player: Player) -> String:
	var held := player.held_kind()
	if _takes_candle(held) or _takes_mini_pumpkin(held):
		return "decorate"
	return "coffee" if kind == Kind.COFFEE else ""


func interact(player: Player) -> void:
	if is_toppled():
		stand_up()
		Game.noise("drop", global_position, player)
		return
	var held := player.held_kind()
	if _carving(held):
		if can_carve():
			carve()
			Game.say("Du schnitzt eine Fratze in den Kürbis.", 2.5)
		return
	if _takes_candle(held):
		player.consume_held()
		light_up()
		Game.say("Die Kerze flackert im Kürbis auf." if kind == Kind.CARVED_PUMPKIN else "Die Augen des Totenkopfs glimmen.", 2.5)
		return
	if _fitting_prompt(held, player) != "":
		_fit(player)
		return
	if _takes_mini_pumpkin(held):
		player.consume_held()
		set_pumpkin(true)
		Game.noise("drop", global_position, player)
		return
	if portions > 1:
		_take_portion(player)
		return
	player.try_pick_up(self)


## Messer in der Hand + Kürbis → schnitzen (ob er sich schnitzen lässt, sagt can_carve)
func _carving(held: int) -> bool:
	return kind == Kind.PUMPKIN and held == Kind.KNIFE


## Kerze in der Hand + Kürbis oder Totenkopf ohne Licht → Kerze hineinstellen
func _takes_candle(held: int) -> bool:
	return kind in CANDLE_HOLDERS and not lit and held == Kind.CANDLE


## Zierkürbis in der Hand + Lakengespenst mit leeren Händen
func _takes_mini_pumpkin(held: int) -> bool:
	return kind == Kind.SHEET_GHOST and not holds_pumpkin and held == Kind.MINI_PUMPKIN


## Batterie bzw. UV-Aufsatz und Taschenlampe: eins in der Hand, das andere hier.
func _fitting_prompt(held: int, player: Player) -> String:
	var lamp := _lamp_pair(held, player)
	if lamp == null:
		return ""
	if held == Kind.UV_FILTER or kind == Kind.UV_FILTER:
		return "" if lamp.flashlight.has_uv else "UV-Aufsatz auf die Taschenlampe setzen [E]"
	return "Batterie einlegen [E]"


## Die Taschenlampe des Paars (in der Hand oder hier) – oder null, wenn nichts zusammenpasst.
func _lamp_pair(held: int, player: Player) -> Item:
	if owner_id != "" and owner_id != "player":
		return null   # Fremdes erst nehmen (Zeugen, Spielkonzept 6.2)
	if kind == Kind.FLASHLIGHT and held in [Kind.BATTERY, Kind.UV_FILTER]:
		return self
	if held == Kind.FLASHLIGHT and kind in [Kind.BATTERY, Kind.UV_FILTER]:
		return player.held
	return null


func _fit(player: Player) -> void:
	var held := player.held_kind()
	var lamp := _lamp_pair(held, player)
	var part := held if lamp == self else kind
	if part == Kind.BATTERY:
		lamp.flashlight.insert_battery()
		Game.say("Neue Batterie eingelegt.", 2.0)
	else:
		lamp.flashlight.add_uv_filter()
		lamp.display_name = "UV-Taschenlampe"
		if lamp == player.held and Game.hud:
			Game.hud.set_held(lamp.display_name)
		Game.say("Der UV-Aufsatz rastet ein. [R] schaltet um.", 3.0)
	Game.noise("drop", global_position, player)
	if lamp == self:
		player.consume_held()
	else:
		queue_free()


## Ersetzt diesen Kürbis durch einen geschnitzten (noch ohne Kerze).
func carve() -> Item:
	var rot := minf(rot_at, Calendar._elapsed() + ROT_CARVED)
	var carved := Item.create(Kind.CARVED_PUMPKIN, "%s,unlit,r=%d" % [variety, int(rot)])
	carved.owner_id = owner_id
	get_parent().add_child(carved)
	carved.global_transform = global_transform
	Game.noise("carve", carved.global_position)
	queue_free()
	return carved


func light_up(with_sound: bool = true) -> void:
	if light == null:
		return
	lit = true
	light.burn_out = false
	burn_time = 900.0 if kind == Kind.CARVED_PUMPKIN else 600.0
	if kind == Kind.CARVED_PUMPKIN:
		deco_strength = 30.0 * _variety_deco()
		display_name = _carved_name()
	elif kind == Kind.SKULL:
		deco_strength = 26.0
		display_name = "Totenkopf mit Kerze"
	if _glow_material:
		_glow_material.set_shader_parameter("emission_energy", 3.0)
	if with_sound:
		Game.play_sound("blip", 0.4)


## Liegt umgekippt da: zählt nicht als Deko, bis jemand sie wieder aufstellt.
func is_toppled() -> bool:
	return kind in TOPPLE_KINDS and not is_held and global_transform.basis.y.dot(Vector3.UP) < 0.6


## Von einer Katze angestoßen: kippt um, eine Flamme geht dabei meistens aus.
func knock_over(from: Vector3) -> void:
	var push := global_position - from
	push.y = 0.0
	push = push.normalized() if push.length() > 0.01 else Vector3.RIGHT
	sleeping = false
	apply_central_impulse(push * mass * 1.2 + Vector3.UP * mass * 0.6)
	apply_torque_impulse(Vector3.UP.cross(push) * mass * 0.35)
	if lit and randf() < 0.6:
		_extinguish()


## Wieder aufrecht hinstellen (Spieler oder Gast).
func stand_up() -> void:
	global_rotation = Vector3(0.0, global_rotation.y, 0.0)
	global_position.y += 0.03
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	sleeping = false


## Das Monster geht vorbei: Kerze oder Kürbis erlischt (Spur, Spielkonzept 4.13).
func blow_out() -> void:
	if not lit:
		return
	_extinguish()
	if Game.player and Game.player.global_position.distance_to(global_position) < 6.0:
		Game.caption("[Eine Kerze erlischt]")


func _extinguish() -> void:
	lit = false
	burn_time = 0.0
	if light:
		light.burn_out = true
	if _glow_material:
		_glow_material.set_shader_parameter("emission_energy", 0.0)
	match kind:
		Kind.CARVED_PUMPKIN:
			deco_strength = 20.0 * _variety_deco()
			display_name = _carved_name() + " (ohne Licht)"
		Kind.CANDLE:
			deco_strength = 2.0
			display_name = "Kerzenstummel"
		Kind.SKULL:
			deco_strength = 16.0
			display_name = "Totenkopf"


## Kompassnadel: gedämpfte Feder Richtung Norden; das Monster stört sie (Bedrohung wie beim
## Rauschen, wirkt durch Wände), nach einem Todesfall auch Halluzinationen.
func _update_needle(delta: float) -> void:
	var north := global_basis.inverse() * Vector3.FORWARD
	var target := atan2(-north.x, -north.z)
	var director := Game.director
	var threat := director.threat_at(global_position) if director else 0.0
	if pocketed and director and director.is_hallucinating():
		threat = maxf(threat, 0.8)
	_needle_time += delta
	if threat > 0.75:
		# Ganz nah: die Nadel dreht sich im Kreis
		_needle_spin += delta * (6.0 + 8.0 * threat)
		target = _needle_spin
	else:
		_needle_spin = _needle_angle
		target += sin(_needle_time * 13.0) * threat * 1.1 + randf_range(-1.0, 1.0) * threat * 0.9
	var state := needle_step(Vector2(_needle_angle, _needle_speed), target, delta)
	_needle_angle = state.x
	_needle_speed = state.y
	_needle.rotation.y = _needle_angle


## Ein Schritt der Nadelfeder: state = (Winkel, Drehgeschwindigkeit) → neuer state. In Teilschritten ≤ 20 ms – die
## steife Feder schaukelt sich bei einem langen Frame (Autosave, Ruckler) sonst bis NaN auf (tests/math_checks.gd).
static func needle_step(state: Vector2, target: float, delta: float) -> Vector2:
	var steps := maxi(1, ceili(delta / 0.02))
	var dt := delta / steps
	for i in steps:
		var accel := wrapf(target - state.x, -PI, PI) * 45.0 - state.y * 5.0
		state.y += accel * dt
		state.x = wrapf(state.x + state.y * dt, -PI, PI)
	return state


func set_held(held: bool) -> void:
	is_held = held
	hung = false
	# In der Hand: statisch eingefroren – dann folgt der Körper seinem Elternknoten (Hand).
	# Kinematisch eingefroren schrieb die Physik die alte Lage zurück: der Gegenstand drehte
	# beim Umsehen nicht mit.
	freeze_mode = RigidBody3D.FREEZE_MODE_STATIC if held else RigidBody3D.FREEZE_MODE_KINEMATIC
	freeze = held
	collision_layer = 0 if held else LAYER
	collision_mask = 0 if held else MASK
	if not held:
		sleeping = false
	_apply_pose()


func can_hang() -> bool:
	return kind in HANGABLE


## An die Wand hängen (Spielkonzept 5.6). point: Punkt auf der Wandfläche (Lakengespenst: Höhe des Hakens,
## Lichterkette: Mitte der Aufhängelinie), out: Wandnormale. length: Lichterkette entlang der Wand.
## Der Gegenstand muss schon in der Welt hängen (nicht mehr in einer Hand).
func hang(point: Vector3, out: Vector3, length: float = 0.0) -> void:
	out = Vector3(out.x, 0.0, out.z)
	out = out.normalized() if out.length() > 0.001 else global_basis.z   # Boden oder Decke: bleibt, wie er liegt
	var gap := {Kind.SHEET_GHOST: GHOST_DEPTH, Kind.LIGHT_STRING: 0.03, Kind.COBWEB: 0.012, Kind.BAT_GARLAND: 0.03,
		Kind.SPIDER: 0.03, Kind.BROOM: BROOM_LENGTH * sin(BROOM_LEAN) + 0.03}
	if kind == Kind.LIGHT_STRING:
		string_length = length
	var basis := Basis.looking_at(-out, Vector3.UP)
	if kind == Kind.BROOM:
		basis = basis * Basis(Vector3.RIGHT, -BROOM_LEAN)   # Ursprung am Boden, der Stiel lehnt an der Wand
	global_transform = Transform3D(basis, point + out * float(gap.get(kind, 0.02)))
	_fix_hung()


## Aufgehängt aus dem Spielstand: Lage stimmt schon, nur einfrieren und Form setzen.
func restore_hung() -> void:
	_fix_hung()


func _fix_hung() -> void:
	is_held = false
	hung = true
	freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC
	freeze = true
	collision_layer = LAYER
	collision_mask = 0
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	_apply_pose()


## Lakengespenst: Zierkürbis in den Händen (Deko zählt mit).
func set_pumpkin(on: bool) -> void:
	holds_pumpkin = on
	if _pumpkin_mesh:
		_pumpkin_mesh.visible = on
	deco_strength = 18.0 if on else 14.0


## Ein starker Ruck: Der Zierkürbis fällt dem Lakengespenst aus den Händen.
func drop_pumpkin() -> void:
	if not holds_pumpkin or not is_inside_tree():
		return
	var at := _pumpkin_mesh.global_position
	set_pumpkin(false)
	var fallen := Item.create(Kind.MINI_PUMPKIN)
	fallen.owner_id = owner_id
	get_parent().add_child(fallen)
	fallen.global_position = at + global_basis.z * 0.05 - Vector3(0, 0.06, 0)
	fallen.apply_central_impulse(global_basis.z * fallen.mass * 0.6)
	Game.noise("drop", at, self)
	if Game.player and Game.player.global_position.distance_to(at) < 8.0:
		Game.caption("[Etwas fällt zu Boden]")


## Ein starker Ruck: Der Hexenbesen rutscht von der Wand und fällt um.
func topple_broom() -> void:
	if not hung:
		return
	set_held(false)
	apply_central_impulse(global_basis.z * mass * 0.8)
	Game.noise("drop", global_position, self)
	if Game.player and Game.player.global_position.distance_to(global_position) < 8.0:
		Game.caption("[Etwas fällt polternd um]")


## Lage der Teile je nach Zustand: in der Hand, am Boden oder an der Wand.
func _apply_pose() -> void:
	match kind:
		Kind.SHEET_GHOST:
			# am Boden steht es (Ursprung = Saum), an der Wand hängt es (Ursprung = Haken), in der Hand gefaltet klein
			_swing.position = Vector3.ZERO if hung else Vector3(0, GHOST_HEIGHT * (0.4 if is_held else 1.0), 0)
			_swing.scale = Vector3.ONE * (0.4 if is_held else 1.0)
			_swing.rotation = Vector3.ZERO
			_shape.position = Vector3(0, -GHOST_HEIGHT / 2.0 if hung else GHOST_HEIGHT / 2.0 - SINK, 0)
		Kind.COBWEB:
			# am Boden flach, an der Wand senkrecht und größer aufgespannt (Ursprung = Mitte des Netzes)
			_swing.position = Vector3.ZERO if hung else Vector3(0, 0.02, 0)
			_swing.rotation = Vector3.ZERO
			_swing.scale = Vector3.ONE * (1.5 if hung else 1.0)
			(_swing.get_child(0) as Node3D).rotation.x = PI / 2.0 if hung else 0.0
			(_shape.shape as BoxShape3D).size = Vector3(0.75, 0.75, 0.04) if hung else Vector3(0.5, 0.03, 0.5)
			_shape.position = Vector3.ZERO if hung else Vector3(0, 0.015 - SINK, 0)
		Kind.LIGHT_STRING:
			_coil.visible = not hung
			_swing.rotation = Vector3.ZERO
			if hung and _strand == null:
				_build_strand()
			elif not hung and _strand:
				_strand.queue_free()
				_strand = null
				_bulb_materials.clear()
				if light:
					light.queue_free()
					light = null
			(_shape.shape as BoxShape3D).size = Vector3(maxf(string_length, 0.3), 0.3, 0.1) if hung else Vector3(0.26, 0.06, 0.26)
			_shape.position = Vector3(0, -0.1, 0) if hung else Vector3(0, 0.03 - SINK, 0)
		Kind.LEAVES, Kind.PUMPKIN_MUSH:
			# in der Hand ein Haufen bzw. Klumpen, am Boden verstreut bzw. ein Spritzer (Spielkonzept 5.6, 5.8)
			_pile.visible = is_held
			_spread.visible = not is_held
			if kind == Kind.PUMPKIN_MUSH and (is_held or _laid_at == Vector3.INF):
				# Matsch: die Flecken liegen in Weltlage – abgelegt kommen sie neu auf die Fläche (_settle_mush)
				_laid_at = Vector3.INF
				_pile.visible = true
				_spread.visible = false
		Kind.BAT_GARLAND:
			# an der Wand eine Leine mit Fledermäusen, sonst flach zusammengelegt (in der Hand kleiner)
			_swing.position = Vector3.ZERO if hung else Vector3(0, 0.02, 0)
			_swing.rotation = Vector3.ZERO if hung else Vector3(-PI / 2.0, 0, 0)
			_swing.scale = Vector3.ONE * (0.5 if is_held else 1.0)
			(_shape.shape as BoxShape3D).size = Vector3(1.2, 0.25, 0.08) if hung else Vector3(0.6, 0.04, 0.2)
			_shape.position = Vector3(0, -0.12, 0) if hung else Vector3(0, 0.02 - SINK, 0)
		Kind.SPIDER:
			# an der Wand am Faden, sonst sitzt sie da
			_thread.visible = hung
			_swing.rotation = Vector3.ZERO
			_spider.position = Vector3(0, -SPIDER_THREAD, 0.04) if hung else Vector3(0, 0.03, 0)
			_shape.position = Vector3(0, -SPIDER_THREAD, 0.04) if hung else Vector3(0, 0.04 - SINK, 0)
		Kind.BROOM:
			# in der Hand schräg vor dem Körper
			_swing.rotation = Vector3(0.5, 0.3, 0.0) if is_held else Vector3.ZERO
		Kind.CROWBAR:
			# in der Hand aufrecht, Klaue oben, leicht nach vorn geneigt
			_swing.rotation = Vector3(0.0, 0.0, PI / 2.0 - 0.25) if is_held else Vector3.ZERO
			_swing.position = Vector3(0, 0.05, 0) if is_held else Vector3.ZERO
			_swing.scale = Vector3.ONE * (0.6 if is_held else 1.0)


## Aufgehängt: leichtes Wehen, bei Unruhe (Monster, Lakengeist) stärker und gleichmäßiger.
func _sway(delta: float) -> void:
	_sway_time += delta
	_unrest_timer -= delta
	if _unrest_timer <= 0.0:
		_unrest_timer = 0.2
		var target := Game.director.deco_unrest_at(global_position) if Game.director else 0.0
		_unrest = target if target > _unrest else move_toward(_unrest, target, 0.1)
		# Richtung (Spielkonzept 5.6, nur schwach): weg vom Monster bzw. Lakengeist, entlang der Wand
		var source := Game.director.deco_unrest_source(global_position) if Game.director and target > 0.0 else Vector3.INF
		var lean := 0.0
		if source != Vector3.INF:
			var away := global_basis.inverse() * (global_position - source)
			lean = clampf(away.x / maxf(Vector2(away.x, away.z).length(), 0.1), -1.0, 1.0)
		_lean = move_toward(_lean, lean, 0.15)
	if not _bulb_materials.is_empty() and light:
		var energy := 2.2 * light.light_energy / maxf(light.base_energy, 0.001)
		if _bulb_materials[0].get_shader_parameter("emission_energy") != energy:
			for m in _bulb_materials:
				m.set_shader_parameter("emission_energy", energy)
	if holds_pumpkin and _unrest > JOLT_UNREST and randf() < delta * 0.6:
		drop_pumpkin()
	if kind == Kind.BROOM:
		if _unrest > JOLT_UNREST and randf() < delta * 0.4:
			topple_broom()
		return
	if _swing == null:
		return
	if kind == Kind.SHEET_GHOST and is_instance_valid(circling_with) and circling_with.has_method("hand_phase"):
		# Der Lakengeist steht davor: im Takt seiner Hände im Kreis (vom Haken aus, nie in die Wand)
		var phase: float = circling_with.hand_phase()
		_swing.rotation = Vector3(-0.09 - sin(phase) * 0.07, 0.0, cos(phase) * 0.12)
		return
	var amp: Vector2 = SWAY.get(kind, Vector2(0.03, 0.2))
	_sway_phase += delta * (1.4 + 2.6 * _unrest)
	var idle := sin(_sway_time * 0.8 + _sway_seed) * 0.6 + sin(_sway_time * 1.9 + _sway_seed * 3.1) * 0.4
	var warn := sin(_sway_phase) * _unrest
	for i in _wings.size():
		# Papierflügel: im Luftzug ein wenig, bei Unruhe flattern sie (nie in die Wand)
		var flap := 0.12 + 0.08 * sin(_sway_time * 1.3 + i) + _unrest * (0.35 + 0.35 * sin(_sway_time * 14.0 + i * 0.7))
		_wings[i].rotation.y = flap if i % 2 == 0 else -flap
	if _spider:
		# wippt am Faden auf und ab – bei Unruhe wie ein Jo-Jo
		_spider.position.y = -SPIDER_THREAD + sin(_sway_time * 1.6 + _sway_seed) * 0.015 - (0.5 + 0.5 * warn) * _unrest * 0.18
		_thread.scale.y = -_spider.position.y / SPIDER_THREAD
	match kind:
		Kind.COBWEB:
			# Netz an der Wand: dreht sich in der Fläche und beult etwas aus
			_swing.rotation = Vector3(-absf(warn) * amp.y * 0.4, 0.0, idle * amp.x + warn * amp.y * 0.7 + _lean * _unrest * amp.y * 0.3)
		_:
			# hängt vom Haken bzw. von der Leine: schwingt von der Wand weg und zurück, das Gespenst auch seitlich
			var out := (0.5 + 0.5 * idle) * amp.x + (0.5 + 0.5 * sin(_sway_phase)) * _unrest * amp.y
			# seitlich: das Gespenst pendelt, die Lichterkette neigt sich nur etwas; beide leicht weg von der Quelle
			var side := _lean * _unrest * amp.y * 0.3
			if kind == Kind.SHEET_GHOST:
				side += cos(_sway_time * 0.6 + _sway_seed * 2.0) * amp.x + cos(_sway_phase * 0.7) * _unrest * amp.y * 0.4
			else:
				side *= 0.3
			_swing.rotation = Vector3(-out, 0.0, side)


func _build(extra: String) -> void:
	collision_layer = LAYER
	collision_mask = MASK
	freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC
	var size := Vector3(0.2, 0.2, 0.2)
	match kind:
		Kind.PUMPKIN:
			variety = PumpkinKinds.from_extra(extra)
			var d := PumpkinKinds.data(variety)
			display_name = "Kürbis" if variety == PumpkinKinds.DEFAULT else String(d["name"])
			deco_strength = float(d["deco"])
			is_large = bool(d["large"])
			mass = float(d["mass"])
			size = d["size"]
			_pumpkin(false)
		Kind.CARVED_PUMPKIN:
			variety = PumpkinKinds.from_extra(extra)
			if not bool(PumpkinKinds.data(variety)["carve"]):
				variety = PumpkinKinds.DEFAULT
			var d := PumpkinKinds.data(variety)
			face = randi_range(1, PumpkinModel.FACES)
			for part in extra.split(","):
				if part.begins_with("f="):
					face = clampi(part.substr(2).to_int(), 1, PumpkinModel.FACES)
			display_name = _carved_name()
			is_large = true
			mass = float(d["mass"]) * 0.85
			size = d["size"]
			_pumpkin(true)
			var k := (size as Vector3).x / 0.42
			_add_light(Vector3(0, 0.18 * k, 0), d.get("glow", Color(1.0, 0.55, 0.15)), 0.9 * sqrt(k), 3.5 * sqrt(k))
			if "unlit" in extra.split(","):
				_extinguish()
			else:
				light_up(false)
		Kind.CANDLE:
			display_name = "Kerze"
			deco_strength = 8.0
			mass = 0.3
			size = Vector3(0.08, 0.16, 0.08)
			Geo.mesh(self, Geo.cylinder(0.035, 0.14, 6), Mat.psx(Color(0.92, 0.88, 0.75)), Vector3(0, 0.07, 0))
			_glow_material = Mat.psx(Color(1, 0.8, 0.3), "", 1.0, Color(1, 0.7, 0.2), 4.0, false)
			Geo.mesh(self, Geo.sphere(0.018, 0.045, 5, 2), _glow_material, Vector3(0, 0.165, 0))
			_add_light(Vector3(0, 0.22, 0), Color(1.0, 0.7, 0.35), 0.55, 2.6)
			light_up(false)
		Kind.KEY:
			key_id = extra
			display_name = key_label(extra)
			mass = 0.1
			size = Vector3(0.14, 0.03, 0.05)
			var gold := Mat.psx(Color(0.85, 0.68, 0.25))
			Geo.mesh(self, Geo.box(Vector3(0.09, 0.015, 0.02)), gold, Vector3(0.02, 0.01, 0))
			Geo.mesh(self, Geo.box(Vector3(0.04, 0.02, 0.045)), gold, Vector3(-0.045, 0.01, 0))
		Kind.COBWEB:
			display_name = "Spinnenweben"
			deco_strength = 12.0
			mass = 0.05
			size = Vector3(0.5, 0.03, 0.5)
			var plane := PlaneMesh.new()
			plane.size = Vector2(0.55, 0.55)
			_swing = Node3D.new()
			add_child(_swing)
			Geo.mesh(_swing, plane, Mat.cobweb(), Vector3.ZERO)
		Kind.LEAVES:
			display_name = "Herbstlaub"
			deco_strength = 5.0
			mass = 0.2
			size = Vector3(0.9, 0.03, 0.9)
			var rng := RandomNumberGenerator.new()
			_pile = Node3D.new()
			add_child(_pile)
			for i in 9:
				var leaf := Geo.mesh(_pile, Geo.box(Vector3(0.09, 0.012, 0.06)), Mat.psx(LEAF_COLORS[i % LEAF_COLORS.size()]),
					Vector3(rng.randf_range(-0.15, 0.15), 0.01 + i * 0.004, rng.randf_range(-0.15, 0.15)))
				leaf.rotation.y = rng.randf() * TAU
			# Verstreut: flach auf dem Boden, dichter zur Mitte hin
			_spread = Node3D.new()
			add_child(_spread)
			for i in 22:
				var r := sqrt(rng.randf()) * 0.45
				var a := rng.randf() * TAU
				# Mat.layer: leicht zur Kamera gezogen, sonst flimmert der Boden beim Vertex-Snapping durch
				var leaf := Geo.mesh(_spread, Geo.box(Vector3(0.09, 0.008, 0.06)), Mat.layer(LEAF_COLORS[i % LEAF_COLORS.size()], "", 1.0, 0.004),
					Vector3(cos(a) * r, 0.005 + (i % 3) * 0.003, sin(a) * r))
				leaf.rotation = Vector3(rng.randf_range(-0.1, 0.1), rng.randf() * TAU, 0.0)
		Kind.COINS:
			display_name = "Münzen"
			coin_value = extra.to_int() if extra.is_valid_int() else 3
			mass = 0.2
			size = Vector3(0.1, 0.05, 0.1)
			for i in 3:
				Geo.mesh(self, Geo.cylinder(0.04, 0.012, 8), Mat.psx(Color(0.9, 0.75, 0.3)), Vector3(0.008 * i, 0.006 + i * 0.013, 0))
		Kind.KNIFE:
			display_name = "Messer"
			mass = 0.2
			size = Vector3(0.26, 0.03, 0.04)
			Geo.mesh(self, Geo.box(Vector3(0.16, 0.006, 0.026)), Mat.psx(Color(0.75, 0.78, 0.8)), Vector3(0.05, 0.012, 0))
			Geo.mesh(self, Geo.box(Vector3(0.1, 0.022, 0.03)), Mat.psx(Color(0.15, 0.08, 0.05)), Vector3(-0.08, 0.012, 0))
		Kind.DICE_CUP:
			display_name = "Würfelbecher"
			mass = 0.2
			size = Vector3(0.11, 0.12, 0.11)
			Geo.mesh(self, Geo.cylinder(0.05, 0.11, 8), Mat.psx(Color(0.35, 0.18, 0.1)), Vector3(0, 0.055, 0))
			Geo.mesh(self, Geo.cylinder(0.055, 0.015, 8), Mat.psx(Color(0.55, 0.35, 0.15)), Vector3(0, 0.11, 0))
		Kind.LOADED_DICE:
			display_name = "Gezinkte Würfel"
			mass = 0.05
			size = Vector3(0.08, 0.03, 0.05)
			for i in 2:
				Geo.mesh(self, Geo.box(Vector3(0.025, 0.025, 0.025)), Mat.psx(Color(0.95, 0.9, 0.85)), Vector3(-0.02 + i * 0.04, 0.013, 0))
				Geo.mesh(self, Geo.box(Vector3(0.008, 0.002, 0.008)), Mat.psx(Color(0.7, 0.05, 0.05)), Vector3(-0.02 + i * 0.04, 0.026, 0))
		Kind.CLOTHING:
			clothing_of = extra
			var profile: Dictionary = GuestProfiles.get_profile(extra)
			display_name = String(profile.get("clothing", "Ein Kleidungsstück"))
			mass = 0.4
			size = Vector3(0.62, 0.08, 0.5)
			# Zerknüllt liegengeblieben: ausgebreiteter Stoff, ein Knäuel darauf, ein Ärmel/Zipfel
			var color: Color = profile.get("coat", Color(0.3, 0.25, 0.25))
			var cloth := Mat.psx(color)
			var shade := Mat.psx(color.darkened(0.25))
			var spread := Geo.mesh(self, Geo.box(Vector3(0.5, 0.02, 0.38)), cloth, Vector3(0, 0.01, 0))
			spread.rotation.y = 0.2
			var lump := Geo.mesh(self, Geo.box(Vector3(0.3, 0.05, 0.22)), shade, Vector3(-0.06, 0.035, 0.03))
			lump.rotation.y = -0.35
			var sleeve := Geo.mesh(self, Geo.box(Vector3(0.11, 0.025, 0.42)), cloth, Vector3(0.2, 0.02, 0.06))
			sleeve.rotation.y = 0.6
		Kind.BULB:
			broken = extra == "broken"
			display_name = "Kaputte Glühbirne" if broken else "Glühbirne"
			mass = 0.05
			size = Vector3(0.07, 0.11, 0.07)
			var glass := Mat.psx(Color(0.35, 0.33, 0.3) if broken else Color(1.0, 0.97, 0.85))
			if Lamp.build_bulb(self, glass) == null:
				Geo.mesh(self, Geo.cylinder(0.018, 0.03, 6), Mat.psx(Color(0.7, 0.68, 0.6)), Vector3(0, 0.015, 0))
				Geo.mesh(self, Geo.sphere(0.032, 0.07, 6, 3), glass, Vector3(0, 0.065, 0))
		Kind.COMPASS:
			display_name = "Kompass"
			mass = 0.15
			size = Vector3(0.11, 0.03, 0.11)
			_build_compass()
		Kind.MAP:
			page_id = extra if extra != "" else "eg"
			display_name = "Kartenblatt (%s)" % HotelMap.page_title(page_id)
			mass = 0.05
			size = Vector3(MAP_WIDTH, 0.01, MAP_WIDTH * HotelMap.PAGE_SIZE.y / HotelMap.PAGE_SIZE.x)
			_build_map()
		Kind.FLASHLIGHT:
			display_name = "Taschenlampe"
			mass = 0.3
			size = Vector3(0.05, 0.05, 0.25)
			flashlight = Flashlight.new().setup(extra)
			add_child(flashlight)
			if flashlight.has_uv:
				display_name = "UV-Taschenlampe"
		Kind.BATTERY:
			display_name = "Batterie"
			mass = 0.05
			size = Vector3(0.04, 0.07, 0.04)
			Geo.mesh(self, Geo.cylinder(0.017, 0.06, 6), Mat.psx(Color(0.15, 0.3, 0.6)), Vector3(0, 0.03, 0))
			Geo.mesh(self, Geo.cylinder(0.007, 0.006, 6), Mat.psx(Color(0.7, 0.7, 0.68)), Vector3(0, 0.063, 0))
		Kind.UV_FILTER:
			display_name = "UV-Aufsatz"
			mass = 0.1
			size = Vector3(0.08, 0.04, 0.08)
			var ring := Geo.mesh(self, Geo.cylinder(0.036, 0.035, 8), Mat.psx(Color(0.12, 0.12, 0.14)), Vector3(0, 0.018, 0))
			ring.rotation.y = 0.2
			var violet := Color(0.45, 0.22, 1.0)
			Geo.mesh(self, Geo.cylinder(0.029, 0.004, 8), Mat.psx(Color(0.3, 0.15, 0.55), "", 1.0, violet, 0.6), Vector3(0, 0.037, 0))
		Kind.CHESS_BOARD:
			# Schachbrett (Spielkonzept 6.10): flacher Kasten, 8 × 8 Felder, die Figuren stehen im Kasten
			display_name = "Schachbrett"
			mass = 0.8
			size = Vector3(0.36, 0.03, 0.36)
			Geo.mesh(self, Geo.box(Vector3(0.36, 0.024, 0.36)), Mat.psx(Color(0.28, 0.16, 0.08)), Vector3(0, 0.012, 0))
			var light := Mat.psx(Color(0.85, 0.78, 0.62))
			var dark := Mat.psx(Color(0.32, 0.2, 0.12))
			for i in 64:
				var field := Vector3(-0.1575 + (i & 7) * 0.045, 0.0255, -0.1575 + (i >> 3) * 0.045)
				Geo.mesh(self, Geo.box(Vector3(0.045, 0.003, 0.045)), light if ((i & 7) + (i >> 3)) % 2 == 0 else dark, field)
		Kind.BED_SHEET:
			# Bettlaken zum Überwerfen (Spielkonzept 5.9): gefaltet, mit Linksklick wird es zum Kostüm
			display_name = "Bettlaken"
			mass = 0.3
			size = Vector3(0.34, 0.06, 0.26)
			Geo.mesh(self, Geo.box(Vector3(0.34, 0.06, 0.26)), Mat.psx(Costume.SHEET_COLOR), Vector3(0, 0.03, 0))
			Geo.mesh(self, Geo.box(Vector3(0.345, 0.006, 0.265)), Mat.psx(Costume.SHEET_COLOR.darkened(0.25)), Vector3(0, 0.03, 0))   # Faltkante
		Kind.SWEETS:
			# Süßigkeiten (Spielkonzept 6.13, Süßes oder Saures): eine Handvoll eingewickelter Bonbons
			display_name = "Süßigkeiten"
			mass = 0.1
			size = Vector3(0.12, 0.04, 0.1)
			var wrappers: Array[Color] = [Color(0.85, 0.2, 0.15), Color(0.95, 0.75, 0.15), Color(0.25, 0.6, 0.3), Color(0.55, 0.25, 0.7)]
			for i in 5:
				var a := i * 1.3
				var sweet := Geo.mesh(self, Geo.box(Vector3(0.05, 0.018, 0.022)), Mat.psx(wrappers[i % wrappers.size()]),
					Vector3(cos(a) * 0.03, 0.01 + (i % 2) * 0.016, sin(a) * 0.025))
				sweet.rotation.y = a
		Kind.SHEET_GHOST:
			# Lakengespenst (Spielkonzept 5.6): Laken mit fröhlichem Gesicht – festlich, nicht der Lakengeist
			display_name = "Lakengespenst"
			mass = 0.4
			size = Vector3(0.45, GHOST_HEIGHT, 0.32)
			_build_sheet_ghost()
			set_pumpkin(extra == "pumpkin")
		Kind.LIGHT_STRING:
			display_name = "Lichterkette"
			deco_strength = 10.0
			mass = 0.3
			size = Vector3(0.26, 0.06, 0.26)
			string_length = extra.to_float() if extra.is_valid_float() else 0.0
			_swing = Node3D.new()
			add_child(_swing)
			_coil = Node3D.new()
			add_child(_coil)
			var wire := Mat.psx(Color(0.12, 0.22, 0.1))
			for i in 3:
				var ring := Geo.mesh(_coil, Geo.cylinder(0.12 - i * 0.012, 0.012, 10), wire, Vector3(0, 0.008 + i * 0.012, 0))
				ring.rotation.y = i * 0.7
			for i in 7:
				var a := i * TAU / 7.0
				var c: Color = STRING_COLORS[i % STRING_COLORS.size()]
				Geo.mesh(_coil, Geo.sphere(0.02, 0.04, 5, 2), Mat.psx(c), Vector3(cos(a) * 0.1, 0.045, sin(a) * 0.1))
		Kind.BAT_GARLAND:
			display_name = "Fledermausgirlande"
			deco_strength = 9.0
			mass = 0.1
			size = Vector3(0.6, 0.04, 0.2)
			_build_bats()
		Kind.SPIDER:
			display_name = "Plastikspinne"
			deco_strength = 6.0
			mass = 0.05
			size = Vector3(0.14, 0.06, 0.14)
			_build_spider()
		Kind.SKULL:
			display_name = "Totenkopf"
			deco_strength = 16.0
			mass = 1.0
			size = Vector3(0.2, 0.22, 0.24)
			_build_skull()
			_add_light(Vector3(0, 0.11, 0), Color(1.0, 0.65, 0.3), 0.5, 2.8)
			if extra == "lit":
				light_up(false)
			else:
				_extinguish()
		Kind.BROOM:
			display_name = "Hexenbesen"
			deco_strength = 15.0
			is_large = true
			mass = 1.0
			size = Vector3(0.24, BROOM_LENGTH, 0.24)
			_swing = Node3D.new()
			add_child(_swing)
			var straw := Mat.psx(Color(0.72, 0.55, 0.25))
			var bristles := CylinderMesh.new()
			bristles.top_radius = 0.035
			bristles.bottom_radius = 0.13
			bristles.height = 0.4
			bristles.radial_segments = 8
			Geo.mesh(_swing, bristles, straw, Vector3(0, 0.2, 0))
			Geo.mesh(_swing, Geo.cylinder(0.045, 0.05, 8), Mat.psx(Color(0.35, 0.12, 0.35)), Vector3(0, 0.38, 0))   # lila Band
			var stick := Geo.mesh(_swing, Geo.cylinder(0.018, BROOM_LENGTH - 0.3, 6), Mat.psx(Color(0.32, 0.2, 0.1)), Vector3(0.0, 0.3 + (BROOM_LENGTH - 0.3) / 2.0, 0))
			stick.rotation.z = 0.03   # knorrig, nicht ganz gerade
		Kind.ROAST_PUMPKIN:
			# Gebratener Kürbis (Spielkonzept 3.8): Spalten auf einem Teller – essen oder verschenken
			variety = PumpkinKinds.from_extra(extra)
			display_name = "Gebratener " + ("Zierkürbis" if variety == PumpkinKinds.DEFAULT else String(PumpkinKinds.data(variety)["name"]))
			if variety == "butternut" or variety == "turban":
				display_name = "Gebratener Kürbis (%s)" % PumpkinKinds.data(variety)["name"]
			mass = 0.4
			size = Vector3(0.24, 0.06, 0.24)
			Geo.mesh(self, Geo.cylinder(0.12, 0.015, 10), Mat.psx(Color(0.92, 0.9, 0.85)), Vector3(0, 0.008, 0))
			var flesh := Mat.psx((PumpkinKinds.data(variety)["color"] as Color).lerp(Color(0.95, 0.55, 0.15), 0.5))
			var crust := Mat.psx(Color(0.55, 0.25, 0.08))
			for i in 4:
				var a := i * TAU / 4.0 + 0.3
				var wedge := Geo.mesh(self, Geo.box(Vector3(0.1, 0.03, 0.04)), flesh, Vector3(cos(a) * 0.05, 0.03, sin(a) * 0.05))
				wedge.rotation.y = -a
				Geo.mesh(wedge, Geo.box(Vector3(0.1, 0.012, 0.012)), crust, Vector3(0, 0.012, 0.018))
		Kind.SODA_CAN:
			# Getränkedose (Spielkonzept 3.2, 3.7): Limo oder Cola – trinken bringt einen wieder zu Atem
			flavor = extra if SODA_COLORS.has(extra) else ("cola" if randf() < 0.5 else "limo")
			display_name = "Dose Cola" if flavor == "cola" else "Dose Limo"
			mass = 0.35
			size = Vector3(0.07, 0.12, 0.07)
			var tin := Mat.psx(Color(0.75, 0.76, 0.78))
			Geo.mesh(self, Geo.cylinder(0.033, 0.11, 8), Mat.psx(SODA_COLORS[flavor]), Vector3(0, 0.055, 0))
			Geo.mesh(self, Geo.cylinder(0.0335, 0.022, 8), Mat.psx(Color(0.95, 0.93, 0.85)), Vector3(0, 0.06, 0))   # Banderole
			Geo.mesh(self, Geo.cylinder(0.028, 0.012, 8), tin, Vector3(0, 0.116, 0))   # Deckel
			Geo.mesh(self, Geo.box(Vector3(0.014, 0.003, 0.022)), tin, Vector3(0, 0.123, 0.006))   # Lasche
		Kind.COFFEE:
			# Tasse Kaffee (Spielkonzept 3.11): überdeckt die Müdigkeit eine Weile – nur in der Hand, zerbricht leicht
			display_name = "Tasse Kaffee"
			mass = 0.3
			size = Vector3(0.1, 0.09, 0.08)
			var china := Mat.psx(CUP_COLOR)
			Geo.mesh(self, Geo.cylinder(0.038, 0.085, 8), china, Vector3(0, 0.0425, 0))
			Geo.mesh(self, Geo.cylinder(0.033, 0.004, 8), Mat.psx(COFFEE_COLOR), Vector3(0, 0.084, 0))
			Geo.mesh(self, Geo.box(Vector3(0.022, 0.05, 0.01)), china, Vector3(0.05, 0.045, 0))   # Henkel
			Geo.mesh(self, Geo.box(Vector3(0.016, 0.01, 0.01)), china, Vector3(0.042, 0.068, 0))
			Geo.mesh(self, Geo.box(Vector3(0.016, 0.01, 0.01)), china, Vector3(0.042, 0.022, 0))
		Kind.PUMPKIN_HEAD:
			# Der richtige Kopf des Kürbismanns (Spielkonzept 4.21): von den Kindern 1987 auf dem Dachboden versteckt,
			# vertrocknet, das Haar noch dran – Platzhalter bis zum Modell; damit erlöst man ihn später (Ritual)
			display_name = "Kopf des Kürbismanns"
			mass = 2.0
			size = Vector3(0.18, 0.24, 0.22)
			var skin := Mat.psx(Color(0.4, 0.29, 0.19))
			var hollow := Mat.psx(Color(0.05, 0.035, 0.03))
			var skull := Geo.mesh(self, Geo.sphere(0.095, 0.2, 9, 5), skin, Vector3(0, 0.13, -0.005))
			skull.scale = Vector3(0.92, 1.05, 1.1)
			Geo.mesh(self, Geo.box(Vector3(0.1, 0.07, 0.1)), skin, Vector3(0, 0.045, 0.035))   # eingefallene Wangen, Kiefer
			Geo.mesh(self, Geo.sphere(0.1, 0.11, 8, 3), Mat.psx(Color(0.13, 0.09, 0.06)), Vector3(0, 0.18, -0.02))   # Haar
			for side in [-1.0, 1.0]:
				var socket := Geo.mesh(self, Geo.sphere(0.024, 0.04, 6, 3), hollow, Vector3(side * 0.035, 0.125, 0.085))
				socket.scale = Vector3(1.0, 0.8, 0.5)
			Geo.mesh(self, Geo.box(Vector3(0.02, 0.03, 0.02)), hollow, Vector3(0, 0.09, 0.098))   # Nase
			Geo.mesh(self, Geo.box(Vector3(0.06, 0.012, 0.01)), hollow, Vector3(0, 0.052, 0.086))   # Mund
		Kind.CROWBAR:
			# Brecheisen (Spielkonzept 6.19): Zimmertüren aufbrechen – laut, und wer es sieht, erzählt es weiter
			display_name = "Brecheisen"
			mass = 1.6
			size = Vector3(0.62, 0.05, 0.06)
			_swing = Node3D.new()   # in der Hand aufrecht (_apply_held_pose)
			add_child(_swing)
			var steel := Mat.psx(Color(0.62, 0.12, 0.1))
			Geo.mesh(_swing, Geo.box(Vector3(0.56, 0.022, 0.022)), steel, Vector3(-0.02, 0.011, 0))
			var claw := Geo.mesh(_swing, Geo.box(Vector3(0.08, 0.02, 0.022)), steel, Vector3(0.27, 0.03, 0))
			claw.rotation.z = 0.9
			Geo.mesh(_swing, Geo.box(Vector3(0.03, 0.006, 0.03)), Mat.psx(Color(0.3, 0.3, 0.32)), Vector3(-0.3, 0.011, 0))
		Kind.TOOLBOX:
			# Werkzeugkasten (6.19): aufgebrochene Türen reparieren
			display_name = "Werkzeugkasten"
			mass = 3.0
			size = Vector3(0.44, 0.24, 0.2)
			var paint := Mat.psx(Color(0.7, 0.15, 0.1))
			Geo.mesh(self, Geo.box(Vector3(0.44, 0.18, 0.2)), paint, Vector3(0, 0.09, 0))
			Geo.mesh(self, Geo.box(Vector3(0.44, 0.01, 0.21)), Mat.psx(Color(0.4, 0.08, 0.06)), Vector3(0, 0.15, 0))
			var grip := Mat.psx(Color(0.15, 0.15, 0.16))
			Geo.mesh(self, Geo.box(Vector3(0.2, 0.02, 0.025)), grip, Vector3(0, 0.235, 0))
			for x in [-0.1, 0.1]:
				Geo.mesh(self, Geo.box(Vector3(0.02, 0.05, 0.025)), grip, Vector3(x, 0.205, 0))
		Kind.MINI_PUMPKIN:
			display_name = "Zierkürbis"
			deco_strength = 4.0
			mass = 0.3
			size = Vector3(0.15, 0.13, 0.15)
			Geo.mesh(self, Geo.sphere(0.075, 0.11, 8, 4), Mat.psx(MINI_COLOR), Vector3(0, 0.055, 0))
			Geo.mesh(self, Geo.cylinder(0.012, 0.035, 5), Mat.psx(Color(0.3, 0.35, 0.12)), Vector3(0, 0.12, 0))
		Kind.PUMPKIN_MUSH:
			# Zerplatzter Kürbis (Spielkonzept 5.8): extra = mush_extra() – Sorte, Zeitpunkt, Größe, Hände voll; die Zahlen
			# der Reihe nach (ältere Stände: nur Zeitpunkt)
			variety = PumpkinKinds.from_extra(extra)
			mushed_at = Calendar._elapsed()
			var numbers := Array(extra.split(",")).filter(func(part: String) -> bool: return part.is_valid_float())
			if numbers.size() > 0:
				mushed_at = String(numbers[0]).to_float()
			if numbers.size() > 1:
				mush_size = String(numbers[1]).to_float()
			if numbers.size() > 2:
				portions = maxi(1, String(numbers[2]).to_int())
			for part in extra.split(","):
				if part.begins_with("w="):   # im Regen verwaschen (RainVeil)
					mush_wash = clampf(part.substr(2).to_float(), 0.0, 1.0)
			display_name = "Kürbismatsch"
			mass = 0.5
			size = Vector3(mush_size * 0.7, 0.03, mush_size * 0.7)
			var color := mush_color(PumpkinKinds.data(variety)["color"])
			var flesh := Mat.psx(color)
			_pile = Node3D.new()
			add_child(_pile)
			for i in 4:
				var lump := Geo.mesh(_pile, Geo.sphere(0.07 - i * 0.01, 0.05, 6, 3), flesh, Vector3((i % 2) * 0.05 - 0.025, 0.025 + i * 0.015, 0.02 if i >= 2 else -0.02))
				lump.rotation.y = i * 1.3
			# Die Flecken am Boden legt _lay_mush wie eine Blutlache auf die Fläche darunter – in Weltlage, unabhängig davon,
			# wie der Körper liegt (auf einer Treppe auf der Rampe)
			_spread = Node3D.new()
			_spread.top_level = true
			add_child(_spread)
			_mush_mat = Mat.decal(MUSH_TEXTURE)
			_mush_mat.set_shader_parameter("albedo", Color(color.r / MUSH_TEX_COLOR.r, color.g / MUSH_TEX_COLOR.g, color.b / MUSH_TEX_COLOR.b))
			TraceMark.splat_look(_mush_mat, MUSH_TEXTURE)   # Zug zur Kamera, Glanz, Rand (wie Blut und Wachs)
			freeze = portions > 1   # der große Spritzer rutscht nicht weg
	_shape = CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	_shape.shape = box
	_shape.position.y = size.y / 2.0 - SINK
	add_child(_shape)
	_sway_seed = randf() * TAU
	_apply_pose()


## Zerplatzen (Spielkonzept 5.8): merkt sich den höchsten Punkt des Falls; beim Aufprall (siehe IMPACT_SPEED) aus mehr
## als BURST_HEIGHT zerplatzt der Kürbis, Kerzen und Glühbirnen zerbrechen schon ab BREAK_HEIGHT (_break). Nur für
## BURST_KINDS, nicht in der Hand oder an der Wand.
func _physics_process(_delta: float) -> void:
	if is_held or freeze or pocketed:
		_fall_top = -INF
		_last_vy = 0.0
		thrown = false
		return
	if thrown:
		# Geworfen (Streich, 6.13): beim ersten harten Aufprall, egal aus welcher Höhe – Kürbis zerplatzt, Kerze zerbricht
		var speed := linear_velocity.length()
		if _last_speed > THROW_IMPACT and speed < _last_speed * 0.5:
			thrown = false
			_break()
			return
		_last_speed = speed
	var vy := linear_velocity.y
	if _last_vy < -IMPACT_SPEED and vy > _last_vy * 0.5 \
			and _fall_top - global_position.y > float(BREAK_HEIGHT.get(kind, BURST_HEIGHT)):
		if Game.tracing and kind in BREAK_HEIGHT:
			print("[Fall] %s nach %.1f m" % [display_name, _fall_top - global_position.y])
		_break()
		return
	if vy > -0.5:
		_fall_top = global_position.y   # liegt, rollt oder steigt: hier beginnt ein neuer Fall
	_last_vy = vy


## Der Aufprall war zu hart: Kerze zerbricht, Glühbirne platzt, Kürbis zerplatzt.
func _break() -> void:
	match kind:
		Kind.CANDLE:
			_shatter_candle()
		Kind.BULB:
			_shatter_bulb()
		Kind.COFFEE:
			_spill_coffee()
		_:
			burst()


## Werfen (Streich der Kinder, Spielkonzept 6.13): fliegt von `from` mit `velocity` los und zerplatzt bzw. zerbricht
## beim ersten Aufprall (Kürbis, Zierkürbis, Kerze).
func throw_from(from: Vector3, velocity: Vector3) -> void:
	set_held(false)
	global_position = from
	linear_velocity = velocity
	angular_velocity = Vector3(randf_range(-6, 6), randf_range(-6, 6), randf_range(-6, 6))
	thrown = true
	_last_speed = velocity.length()
	set_physics_process(true)


## Eine Kerze zerbricht (geworfen oder tiefer als BREAK_HEIGHT gefallen): ein großer weißer Wachsfleck; brannte sie,
## fängt leichte Deko daneben Feuer (5.11).
func _shatter_candle() -> void:
	var at := global_position
	var hit := get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(at + Vector3.UP * 0.3, at + Vector3.DOWN * 1.5, 1))
	if not hit.is_empty():
		at = hit["position"]
	if Game.traces:
		Game.traces.add_guest_drop("wax_splash", at)
	Game.noise("wax_splat", at, self)
	if lit:
		DecoFire.ignite_near(at, self)
	if Game.tracing:
		print("[Kerze] zerbricht%s bei %s" % [" (brennend)" if lit else "", at])
	queue_free()


## Eine Kaffeetasse zerbricht (Spielkonzept 3.11, geworfen oder tiefer als BREAK_HEIGHT gefallen): ein Kaffeefleck
## auf dem Boden, ein paar Scherben springen davon. Die Tasse ist weg.
func _spill_coffee() -> void:
	var at := global_position
	var hit := get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(at + Vector3.UP * 0.3, at + Vector3.DOWN * 1.5, 1))
	if not hit.is_empty():
		at = hit["position"]
	if Game.traces:
		Game.traces.add_guest_drop("coffee", at)
	_fling_pieces(at, [Mat.psx(CUP_COLOR)], randi_range(3, 5), Vector3(0.02, 0.006, 0.015), Vector3(0.04, 0.012, 0.03),
		Vector2(0.5, 1.4), Vector2(0.5, 1.2), 0.03, 0.04)
	Game.noise("cup_break", at, self)
	if Game.tracing:
		print("[Kaffee] Tasse zerbricht bei %s" % at)
	queue_free()


## Eine Glühbirne platzt (Spielkonzept 7.3, tiefer als BREAK_HEIGHT gefallen – auch eine durchgebrannte): Knall (Lärm
## „bulb_burst“ wie beim Durchbrennen einer Lampe, 8 m), feine Splitter und ein paar Scherben aus Glas und dem Gewinde,
## die davonspringen und nach einer Weile verschwinden. Die Birne ist weg.
func _shatter_bulb() -> void:
	var at := global_position
	var glass := Mat.psx(BULB_GLASS, "", 1.0, BULB_GLASS, 0.15)   # leicht hell – Glas blitzt im Dunkeln
	_spray(at, Geo.box(Vector3(0.018, 0.005, 0.014)), glass, 30, Vector2(1.5, 3.5), 85.0)
	var count := randi_range(BULB_SHARDS.x, BULB_SHARDS.y)
	_fling_pieces(at, [glass], count - 1, Vector3(0.018, 0.004, 0.014), Vector3(0.045, 0.008, 0.035), Vector2(0.8, 2.2),
		Vector2(0.8, 2.0), 0.03, 0.05)
	_fling_pieces(at, [Mat.psx(BULB_SOCKET)], 1, Vector3(0.025, 0.025, 0.025), Vector3(0.03, 0.03, 0.03), Vector2(0.3, 0.8),
		Vector2(0.5, 1.0), 0.0, 0.03)   # das Gewinde
	if Game.noise("bulb_burst", at, self) >= 0.1:
		Game.caption("[Eine Glühbirne zerplatzt]")
	if Game.tracing:
		print("[Glühbirne] platzt bei %s" % at)
	queue_free()


## Der Kürbis zerplatzt: An seiner Stelle liegt Kürbismatsch der gleichen Sorte – Spritzer so groß wie die Sorte
## (PumpkinKinds „splat“, Zierkürbis MINI_SPLAT), beim Riesenkürbis für viele Hände voll –, Stücke fliegen davon.
func burst() -> Item:
	var at := global_position
	var hit := get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(at + Vector3.UP * 0.5, at + Vector3.DOWN * 1.5, 1))
	if not hit.is_empty():
		at = hit["position"]
	var d := PumpkinKinds.data(variety)
	var mini := kind == Kind.MINI_PUMPKIN
	var splat := (MINI_SPLAT if mini else float(d["splat"])) * randf_range(0.9, 1.1)
	var hands: Vector2i = Vector2i.ONE if mini else d.get("portions", Vector2i.ONE)
	var mush := Item.create(Kind.PUMPKIN_MUSH, mush_extra(variety, Calendar._elapsed(), splat, randi_range(hands.x, hands.y)))
	mush.owner_id = owner_id
	mush.mush_fresh = true
	get_parent().add_child(mush)
	mush.global_transform = Transform3D(Basis(Vector3.UP, randf() * TAU), at + Vector3.UP * 0.02)
	_splash_chunks(at, MINI_COLOR if mini else d["color"], splat)
	Game.noise("pumpkin_splat", at, self)
	if Game.player and Game.player.global_position.distance_to(at) < 12.0:
		Game.caption("[Ein Kürbis zerplatzt]")
	if Game.tracing:
		print("[Kürbis] %s zerplatzt nach %.1f m Fall – Spritzer %.2f m, %d Hände voll" % [display_name, _fall_top - global_position.y, splat, mush.portions])
	queue_free()
	return mush


## Zusatzfeld für Kürbismatsch (Item.create): Sorte, Zeitpunkt des Zerplatzens, Kantenlänge des Spritzers, Hände voll.
static func mush_extra(p_variety: String, at_time: float, splat: float, hands: int) -> String:
	return "%s,%.2f,%.2f,%d" % [p_variety, at_time, splat, hands]


## Farbe des Kürbismatschs: halb Schale, halb Fruchtfleisch – ein weißer Kürbis gibt hellen, ein grüner bräunlichen.
static func mush_color(skin: Color) -> Color:
	return skin.lerp(FLESH_COLOR, 0.5)


## Großer Spritzer (Riesenkürbis): eine Hand voll nehmen – sie liegt als eigener Kürbismatsch in der Hand, der
## Spritzer schrumpft (Fläche je Hand voll), bis die letzte Hand voll mit ihm selbst aufgesammelt wird.
func _take_portion(player: Player) -> void:
	var handful := split_handful()
	player.try_pick_up(handful)
	if player.held != handful:   # Hände voll – bleibt im Spritzer
		handful.queue_free()
		return
	shrink_by_handful()


## Eine Hand voll aus einem großen Spritzer als eigener Kürbismatsch an seiner Stelle (auch für Gäste, die putzen) – der
## Spritzer selbst schrumpft erst mit shrink_by_handful.
func split_handful() -> Item:
	var handful := Item.create(Kind.PUMPKIN_MUSH, mush_extra(variety, mushed_at, HANDFUL_SPLAT, 1))
	handful.owner_id = owner_id
	get_parent().add_child(handful)
	handful.global_position = global_position
	return handful


## Der Spritzer verliert eine Hand voll (Fläche je Hand voll).
func shrink_by_handful() -> void:
	portions -= 1
	_finish_spreading()
	var shrink := sqrt(float(portions) / (portions + 1))
	mush_size *= shrink
	for piece in _spread.get_children():   # jeder Fleck um seine eigene Mitte – so bleibt er auf seiner Fläche
		(piece as Node3D).basis = (piece as Node3D).basis * Basis.from_scale(Vector3(shrink, 1.0, shrink))
	(_shape.shape as BoxShape3D).size = Vector3(mush_size * 0.7, 0.03, mush_size * 0.7)


## Was beim Zerplatzen davonfliegt (Spielkonzept 5.8), je größer der Spritzer (m), desto mehr und weiter: feine
## Spritzer (Partikel, kurz) und Stücke aus Schale und Fruchtfleisch, die aufschlagen, eine Weile liegen und dann
## wegschrumpfen (Spielzeit – pausiert mit dem Spiel). Sie sind nur Bild, nichts zum Aufheben.
func _splash_chunks(at: Vector3, skin: Color, splat: float) -> void:
	var k := sqrt(splat / MUSH_SIZE)   # Riesenkürbis ≈ 2,2, Zierkürbis ≈ 0,7
	_spray(at, Geo.box(Vector3(0.05, 0.03, 0.04) * minf(k, 1.5)), Mat.psx(mush_color(skin)), int(14 * k),
		Vector2(1.5, 3.0) * k, 70.0)
	var size_k := minf(k, 1.6)
	_fling_pieces(at, [Mat.psx(skin), Mat.psx(mush_color(skin)), Mat.psx(FLESH_COLOR)],
		mini(CHUNK_MAX, maxi(3, roundi(CHUNKS_PER_M * splat))), Vector3(0.04, 0.02, 0.03) * size_k,
		Vector3(0.09, 0.04, 0.07) * size_k, Vector2(1.0, 3.0) * k, Vector2(2.0, 4.0) * minf(k, 1.4), 0.2 * k, 0.08 + 0.1 * k)


## Einmalige feine Spritzer bzw. Splitter (Partikel `amount` × mesh, Tempo `speed` m/s, nach oben gestreut um `spread`°),
## räumen sich nach dem Flug selbst weg (pausierbarer Timer).
func _spray(at: Vector3, mesh: Mesh, mat: Material, amount: int, speed: Vector2, spread: float) -> void:
	var spray := CPUParticles3D.new()
	spray.one_shot = true
	spray.explosiveness = 1.0
	spray.amount = maxi(1, amount)
	spray.lifetime = 0.9
	spray.local_coords = false
	spray.mesh = mesh
	spray.material_override = mat
	spray.direction = Vector3.UP
	spray.spread = spread
	spray.initial_velocity_min = speed.x
	spray.initial_velocity_max = speed.y
	spray.gravity = Vector3(0, -9.8, 0)
	spray.angular_velocity_min = -400.0
	spray.angular_velocity_max = 400.0
	spray.scale_amount_min = 0.6
	spray.scale_amount_max = 1.4
	get_parent().add_child(spray)
	spray.global_position = at + Vector3.UP * 0.1
	spray.emitting = true
	get_tree().create_timer(spray.lifetime + 0.2, false).timeout.connect(spray.queue_free)


## Stücke, die davonfliegen, aufschlagen, nach CHUNK_STAY wegschrumpfen und verschwinden (echte Körper, Ebene 0, Maske 1,
## nicht interagierbar – nur Bild): `count` Quader zwischen dims_lo und dims_hi in den Materialien reihum, starten bis
## `start_r` m seitlich und `start_h` m über `at`, fliegen mit `out` m/s zur Seite und `up` m/s nach oben.
func _fling_pieces(at: Vector3, mats: Array, count: int, dims_lo: Vector3, dims_hi: Vector3, out: Vector2, up: Vector2,
		start_r: float, start_h: float) -> void:
	for i in count:
		var piece := RigidBody3D.new()
		piece.collision_layer = 0
		piece.collision_mask = 1   # nur Wände und Böden
		piece.mass = 0.1
		piece.continuous_cd = true   # dünne Scherben fielen sonst durch den Boden
		var dims := Vector3(randf_range(dims_lo.x, dims_hi.x), randf_range(dims_lo.y, dims_hi.y), randf_range(dims_lo.z, dims_hi.z))
		var hull := dims.max(Vector3.ONE * 0.02)
		# das Bild unten im Kasten, sonst schwebt eine flache Scherbe über dem Boden
		var look := Geo.mesh(piece, Geo.box(dims), mats[i % mats.size()], Vector3(0, (dims.y - hull.y) / 2.0, 0))
		var shape := CollisionShape3D.new()
		shape.shape = BoxShape3D.new()
		(shape.shape as BoxShape3D).size = hull
		piece.add_child(shape)
		get_parent().add_child(piece)
		var a := randf() * TAU
		var side := Vector3(cos(a), 0, sin(a))
		piece.global_position = at + side * randf_range(0.25, 1.0) * start_r + Vector3.UP * start_h
		piece.rotation = Vector3(randf() * TAU, randf() * TAU, randf() * TAU)
		piece.linear_velocity = side * randf_range(out.x, out.y) + Vector3.UP * randf_range(up.x, up.y)
		piece.angular_velocity = Vector3(randf_range(-12, 12), randf_range(-12, 12), randf_range(-12, 12))
		# Am Stück selbst (der Gegenstand ist dann längst weg); der Körper lässt sich nicht skalieren, nur sein Bild
		var shrink := piece.create_tween()
		shrink.tween_interval(randf_range(CHUNK_STAY.x, CHUNK_STAY.y))
		shrink.tween_property(look, "scale", Vector3.ONE * 0.01, 0.8)
		shrink.tween_callback(piece.queue_free)


## Kürbismatsch, der nicht in der Hand ist: Liegt er still an einer neuen Stelle (frisch zerplatzt, geladen, abgelegt,
## weggerutscht), kommen seine Flecken dort auf die Fläche (_lay_mush); solange er fliegt oder rutscht, ist er ein Klumpen.
func _settle_mush() -> void:
	if _laid_at != Vector3.INF and global_position.distance_to(_laid_at) < 0.05:
		return
	var moving := not freeze and linear_velocity.length() > 0.2
	_pile.visible = moving
	_spread.visible = not moving
	if not moving:
		_lay_mush()


## Kürbismatsch am Boden, gebaut wie eine Blutlache (TraceMark.place_splat): ein großer Spritzer mit der Kantenlänge
## mush_size und MUSH_SPLATS_PER_M × mush_size kleinere drumherum, jeder senkrecht auf die Fläche darunter gefallen
## (Boden, Stufe, Möbel – nicht die Rampe, nicht durch Wände) und ganz auf ihr. Auf einer Treppe liegen sie längs auf
## den Stufen (dort als überlappende Reihe, TraceMark.lay_decal) und laufen die Stufen hinunter, über die Kanten
## manchmal ein Läufer (lay_runners). Frisch zerplatzt läuft er nach (mush_fresh, TraceMark.SPREAD). Jedes Mal anders
## verteilt.
func _lay_mush() -> void:
	if _grow_tween:
		_grow_tween.kill()
		_grow_tween = null
	var fresh := mush_fresh
	mush_fresh = false
	for child in _spread.get_children():
		child.free()
	_laid_at = global_position
	_spread.global_transform = Transform3D(Basis(), global_position)   # Ursprung in der Mitte: verwaschen läuft er von hier auseinander
	var space := get_world_3d().direct_space_state
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var center := global_position
	var downhill := TraceMark.downhill_at(space, center)
	var flow: Dictionary = TraceMark.SPREAD["mush"]
	var plan: Array = []
	# Ausbreiten von der Fläche unter dem Körper aus (auf einer Treppe ruht er auf der Rampe, über der Stufe)
	var floor_hit := Traces.surface_below(space, center + Vector3.UP * 0.5, 1.5)
	var source := center if floor_hit.is_empty() else (floor_hit["position"] as Vector3)
	var count := 1 + roundi(mush_size * MUSH_SPLATS_PER_M)
	for i in count:
		var main := i == 0
		var r := 0.0 if main else mush_size * rng.randf_range(0.4, 0.75)
		var spot := {}
		for attempt in 3:   # kein Platz (neben der Treppe, hinter der Wand): näher an der Mitte noch einmal
			var off := TraceMark.scatter_offset(rng, r, downhill, mush_size * (0.3 if main else 1.0) / (1 + attempt))
			spot = TraceMark.place_splat(space, center, off, Vector2.ONE * mush_size * (1.0 if main else rng.randf_range(0.2, 0.4)),
				downhill, rng)
			if not spot.is_empty():
				break
			r *= 0.5
		if spot.is_empty():
			continue
		var lift := 0.006 + mini(_spread.get_child_count(), 60) * 0.00002
		var pieces := TraceMark.lay_decal(_spread, spot, _mush_mat, rng, lift)
		var runners := TraceMark.lay_runners(_spread, space, spot, downhill, _mush_mat, rng, flow, lift)
		if fresh:
			TraceMark.plan_spot(plan, pieces, runners, flow, TraceMark.spread_start(flow, source, spot["at"], downhill), main, rng)
	if fresh:
		_grow_tween = TraceMark.grow(self, plan)
	_mush_outdoor = -1
	if mush_wash > 0.0:
		RainVeil.show_wash(_spread, mush_wash, "mush")


## Regen auf dem Matsch (draußen, RainVeil): heller und dünner, ganz verwaschen bleibt nur ein Schleier, der Matsch ist weg.
func _wash_mush(delta: float) -> void:
	_wash_timer += delta
	if _wash_timer < RainVeil.WASH_TICK or is_queued_for_deletion() or _laid_at == Vector3.INF:
		return
	var dt := _wash_timer
	_wash_timer = 0.0
	if Game.weather == null or Game.weather.intensity < RainVeil.RAIN_MIN:
		return
	if _mush_outdoor < 0:
		_mush_outdoor = 1 if RainVeil.is_outdoor(_laid_at) else 0
	if _mush_outdoor == 0:
		return
	var step := RainVeil.wash_step(_laid_at, dt)
	if step <= 0.0:
		return
	if mush_wash == 0.0:
		# der erste Regen: sein Schleier entsteht und wächst von nun an mit (RainVeil, gleiche Formel)
		var floor_hit := Traces.surface_below(get_world_3d().direct_space_state, _laid_at + Vector3.UP * 0.5, 1.5)
		RainVeil.spawn(_laid_at if floor_hit.is_empty() else (floor_hit["position"] as Vector3), "mush", variety, mush_size)
	mush_wash = minf(1.0, mush_wash + step)
	RainVeil.show_wash(_spread, mush_wash, "mush")
	if mush_wash >= 1.0:
		if Game.tracing:
			print("[Regen] Kürbismatsch ganz verlaufen und weg")
		queue_free()


## Breitet sich der Matsch noch aus, liegt er sofort fertig da (vor dem Schrumpfen beim Aufsammeln).
func _finish_spreading() -> void:
	if _grow_tween and _grow_tween.is_valid():
		_grow_tween.custom_step(1000.0)
	_grow_tween = null


## Kürbismatsch am Boden: nach MUSH_ROT_AFTER verblasst er über MUSH_FADE kaum merklich und verschwindet.
func _rot() -> void:
	var left := 1.0 - (Calendar._elapsed() - mushed_at - MUSH_ROT_AFTER) / MUSH_FADE
	if left <= 0.0:
		if Game.tracing:
			print("[Kürbis] Kürbismatsch verblasst und weg")
		queue_free()
		return
	var fade := minf(1.0, left)
	if _mush_mat.get_shader_parameter("fade") != fade:
		_mush_mat.set_shader_parameter("fade", fade)


## Lakengespenst: Inhalt unter dem Drehpunkt am Haken (y = 0 oben, Saum bei −GHOST_HEIGHT), Gesicht nach +Z.
func _build_sheet_ghost() -> void:
	_swing = Node3D.new()
	add_child(_swing)
	var sheet := Mat.psx(Color(0.96, 0.95, 0.9), "", 1.0, Color(1.0, 0.98, 0.92), 0.12)   # leuchtet ganz leicht – festlich
	var black := Mat.psx(Color(0.06, 0.05, 0.06))
	var white := Mat.psx(Color(1, 1, 1), "", 1.0, Color(1, 1, 1), 0.6)
	Geo.mesh(_swing, Geo.cylinder(0.006, 0.05, 4), black, Vector3(0, -0.025, 0))   # Schlaufe am Haken
	Geo.mesh(_swing, Geo.sphere(0.17, 0.34, 10, 6), sheet, Vector3(0, -0.2, 0))
	var body := CylinderMesh.new()
	body.top_radius = 0.15
	body.bottom_radius = 0.25
	body.height = 0.46
	body.radial_segments = 10
	Geo.mesh(_swing, body, sheet, Vector3(0, -0.51, 0))
	# Saum: kurze Zipfel, die nur wenig unter dem Laken hervorschauen
	for i in 9:
		var a := i * TAU / 9.0 + 0.2
		var tip := Geo.mesh(_swing, Geo.box(Vector3(0.13, 0.05, 0.02)), sheet, Vector3(cos(a) * 0.245, -0.735 - (i % 2) * 0.012, sin(a) * 0.245))
		tip.rotation.y = -a + PI / 2.0
	# Ärmchen schräg nach vorn, runde Hände vor dem Bauch (dort hält es den Zierkürbis)
	for side: float in [-1.0, 1.0]:
		var arm := Geo.mesh(_swing, Geo.cylinder(0.05, 0.17, 7), sheet, Vector3(side * 0.15, -0.45, 0.1))
		arm.rotation = Vector3(-1.3, 0.0, side * 0.4)
		Geo.mesh(_swing, Geo.sphere(0.055, 0.11, 7, 4), sheet, Vector3(side * 0.105, -0.5, 0.2))
	# Gesicht: große Kulleraugen mit Glanzpunkt, offenes Lachen, rote Bäckchen
	for side: float in [-1.0, 1.0]:
		var eye := Geo.mesh(_swing, Geo.sphere(0.034, 0.068, 8, 4), black, Vector3(side * 0.062, -0.17, 0.148))
		eye.scale = Vector3(1.0, 1.35, 0.45)
		Geo.mesh(_swing, Geo.sphere(0.01, 0.02, 5, 2), white, Vector3(side * 0.062 + 0.012, -0.152, 0.163))
		var cheek := Geo.mesh(_swing, Geo.sphere(0.024, 0.048, 6, 3), Mat.psx(Color(0.95, 0.55, 0.6)), Vector3(side * 0.108, -0.245, 0.122))
		cheek.scale = Vector3(1.2, 0.8, 0.35)
	var mouth := Geo.mesh(_swing, Geo.sphere(0.03, 0.06, 8, 4), black, Vector3(0, -0.262, 0.15))
	mouth.scale = Vector3(1.5, 0.75, 0.35)
	Geo.mesh(_swing, Geo.box(Vector3(0.03, 0.012, 0.02)), Mat.psx(Color(0.85, 0.3, 0.35)), Vector3(0, -0.275, 0.158))
	# Festlich: orange Fliege am Hals
	var orange := Mat.psx(Color(1.0, 0.5, 0.08))
	for side: float in [-1.0, 1.0]:
		var wing := Geo.mesh(_swing, Geo.box(Vector3(0.06, 0.045, 0.02)), orange, Vector3(side * 0.035, -0.355, 0.155))
		wing.rotation.z = side * 0.35
	Geo.mesh(_swing, Geo.box(Vector3(0.025, 0.03, 0.025)), Mat.psx(Color(0.15, 0.08, 0.04)), Vector3(0, -0.355, 0.16))
	# Zierkürbis in den Händen (nur sichtbar, wenn es einen hält)
	_pumpkin_mesh = Node3D.new()
	_pumpkin_mesh.position = Vector3(0, -0.53, 0.26)
	_swing.add_child(_pumpkin_mesh)
	Geo.mesh(_pumpkin_mesh, Geo.sphere(0.07, 0.1, 8, 4), Mat.psx(Color(0.9, 0.48, 0.1)), Vector3.ZERO)
	Geo.mesh(_pumpkin_mesh, Geo.cylinder(0.011, 0.03, 5), Mat.psx(Color(0.3, 0.35, 0.12)), Vector3(0, 0.055, 0))


## Fledermausgirlande: Leine (1,2 m) mit vier schwarzen Papierfledermäusen; die Flügel drehen sich um den Körper
## (_wings, nur von der Wand weg). Drehpunkt _swing in der Mitte der Leine.
func _build_bats() -> void:
	_swing = Node3D.new()
	add_child(_swing)
	var paper := Mat.psx(Color(0.08, 0.07, 0.09))
	var cord := Mat.psx(Color(0.55, 0.12, 0.6))
	for i in 12:
		var a := Vector3(-0.6 + i * 0.1, -0.07 * sin(PI * i / 12.0), 0)
		var b := Vector3(-0.5 + i * 0.1, -0.07 * sin(PI * (i + 1) / 12.0), 0)
		var seg := Geo.mesh(_swing, Geo.box(Vector3(0.104, 0.006, 0.006)), cord, (a + b) / 2.0)
		seg.rotation.z = atan2(b.y - a.y, b.x - a.x)
	var eye := Mat.psx(Color(1.0, 0.75, 0.1), "", 1.0, Color(1.0, 0.7, 0.1), 0.8)
	for i in 4:
		var x := -0.45 + i * 0.3
		var bat := Node3D.new()
		bat.position = Vector3(x, -0.07 * sin(PI * (x + 0.6) / 1.2) - 0.1, 0.015)
		bat.rotation.z = 0.15 * sin(i * 2.1)
		bat.scale = Vector3.ONE * 1.7
		_swing.add_child(bat)
		Geo.mesh(bat, Geo.cylinder(0.004, 0.06, 3), cord, Vector3(0, 0.04, 0))   # Faden zur Leine
		Geo.mesh(bat, Geo.sphere(0.022, 0.05, 6, 3), paper, Vector3.ZERO)
		for ear in [-1.0, 1.0]:
			Geo.mesh(bat, Geo.box(Vector3(0.008, 0.02, 0.006)), paper, Vector3(ear * 0.01, 0.025, 0))
			Geo.mesh(bat, Geo.box(Vector3(0.007, 0.007, 0.004)), eye, Vector3(ear * 0.008, 0.006, 0.02))
		for side in [-1.0, 1.0]:
			var wing := Node3D.new()
			bat.add_child(wing)
			var w := Geo.mesh(wing, Geo.box(Vector3(0.075, 0.04, 0.004)), paper, Vector3(side * 0.055, 0.004, 0))
			w.rotation.z = side * -0.25
			Geo.mesh(wing, Geo.box(Vector3(0.03, 0.022, 0.004)), paper, Vector3(side * 0.085, -0.018, 0))   # Zacken
			_wings.append(wing)


## Plastikspinne: Faden vom Haken (y = 0) nach unten, schwarzer Körper mit acht Beinen und roten Augen.
func _build_spider() -> void:
	_swing = Node3D.new()
	add_child(_swing)
	_thread = Node3D.new()
	_swing.add_child(_thread)
	var thread := Geo.mesh(_thread, Geo.cylinder(0.002, SPIDER_THREAD, 3), Mat.psx(Color(0.85, 0.85, 0.85)), Vector3(0, -SPIDER_THREAD / 2.0, 0.04))
	thread.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_spider = Node3D.new()
	_spider.scale = Vector3.ONE * 1.4
	_swing.add_child(_spider)
	var black := Mat.psx(Color(0.05, 0.04, 0.05))
	var body := Geo.mesh(_spider, Geo.sphere(0.04, 0.07, 7, 4), black, Vector3(0, 0, -0.015))
	body.scale = Vector3(1.0, 0.85, 1.25)
	Geo.mesh(_spider, Geo.sphere(0.022, 0.04, 6, 3), black, Vector3(0, 0, 0.04))
	var red := Mat.psx(Color(0.9, 0.1, 0.05), "", 1.0, Color(1.0, 0.1, 0.05), 1.0)
	for side in [-1.0, 1.0]:
		Geo.mesh(_spider, Geo.box(Vector3(0.008, 0.008, 0.006)), red, Vector3(side * 0.009, 0.008, 0.06))
		for j in 4:
			var leg := Node3D.new()
			leg.position = Vector3(side * 0.02, 0, 0.03 - j * 0.02)
			leg.rotation = Vector3(0, side * (0.5 - j * 0.33), side * -0.5)
			_spider.add_child(leg)
			Geo.mesh(leg, Geo.box(Vector3(0.07, 0.006, 0.006)), black, Vector3(side * 0.035, 0, 0))
			var tip := Geo.mesh(leg, Geo.box(Vector3(0.04, 0.006, 0.006)), black, Vector3(side * 0.075, -0.015, 0))
			tip.rotation.z = side * -0.9


## Totenkopf aus Gips: Schädel, Augenhöhlen (leuchten mit Kerze), Nase, Zahnreihe; Gesicht nach +Z.
func _build_skull() -> void:
	var bone := Mat.psx(Color(0.88, 0.84, 0.72))
	var dark := Mat.psx(Color(0.08, 0.06, 0.05))
	var cranium := Geo.mesh(self, Geo.sphere(0.1, 0.2, 9, 5), bone, Vector3(0, 0.13, -0.01))
	cranium.scale = Vector3(1.0, 0.95, 1.12)
	Geo.mesh(self, Geo.box(Vector3(0.12, 0.06, 0.1)), bone, Vector3(0, 0.035, 0.04))   # Kiefer
	_glow_material = Mat.psx(Color(0.15, 0.08, 0.03), "", 1.0, Color(1.0, 0.55, 0.15), 3.0, false)
	for side in [-1.0, 1.0]:
		var socket := Geo.mesh(self, Geo.sphere(0.028, 0.05, 6, 3), _glow_material, Vector3(side * 0.04, 0.12, 0.085))
		socket.scale = Vector3(1.0, 0.9, 0.5)
	Geo.mesh(self, Geo.box(Vector3(0.022, 0.03, 0.02)), dark, Vector3(0, 0.08, 0.098))
	for i in 5:
		Geo.mesh(self, Geo.box(Vector3(0.014, 0.018, 0.01)), Mat.psx(Color(0.95, 0.92, 0.82)), Vector3(-0.034 + i * 0.017, 0.045, 0.091))


## Lichterkette an der Wand: Bögen entlang der lokalen X-Achse unter der Aufhängelinie (y = 0), bunte
## Birnen und ein gemeinsames Licht ohne Schatten (flackert mit den Lampen, Gruppe „lamps“).
func _build_strand() -> void:
	_strand = Node3D.new()
	_swing.add_child(_strand)
	var length := maxf(string_length, 0.5)
	var swags := maxi(2, roundi(length / 0.9))
	var steps := ceili(length / 0.06)
	var wire := Mat.psx(Color(0.12, 0.22, 0.1))
	var points: Array[Vector3] = []
	for i in steps + 1:
		var x := -length / 2.0 + length * i / steps
		var frac := fposmod((x + length / 2.0) / (length / swags), 1.0)
		points.append(Vector3(x, -STRING_SAG * sin(PI * frac), 0))
	for i in steps:
		var a := points[i]
		var b := points[i + 1]
		var seg := Geo.mesh(_strand, Geo.box(Vector3(a.distance_to(b) + 0.004, 0.008, 0.008)), wire, (a + b) / 2.0)
		seg.rotation.z = atan2(b.y - a.y, b.x - a.x)
	_bulb_materials.clear()
	for c in STRING_COLORS:
		_bulb_materials.append(Mat.psx(c, "", 1.0, c, 2.2, false))
	var bulbs := maxi(4, floori(length / 0.17))
	for i in bulbs:
		var at := points[clampi(roundi((i + 0.5) / bulbs * steps), 0, steps)]
		Geo.mesh(_strand, Geo.sphere(0.022, 0.05, 6, 3), _bulb_materials[i % _bulb_materials.size()], at + Vector3(0, -0.03, 0.005))
	# ShadowBudget: Lichterketten werfen nie Schatten („no_shadow“), flackern aber mit den Lampen („lamps“)
	_add_light(Vector3(0, -0.12, 0.2), Color(1.0, 0.62, 0.35), 0.55, 2.5 + length * 0.5, true)


## Messingdose mit Zifferblatt; Nadel und Nordmarke leuchten schwach (Leuchtfarbe),
## damit man sie auch im dunklen Flur ablesen kann. Zifferblatt oben (lokale +Y).
func _build_compass() -> void:
	var brass := Mat.psx(Color(0.62, 0.48, 0.22))
	var glow := Color(0.55, 0.95, 0.6)
	Geo.mesh(self, Geo.cylinder(0.05, 0.022, 10), brass, Vector3(0, 0.011, 0))
	Geo.mesh(self, Geo.cylinder(0.043, 0.004, 10), Mat.psx(Color(0.82, 0.78, 0.66)), Vector3(0, 0.022, 0))
	Geo.mesh(self, Geo.box(Vector3(0.014, 0.006, 0.014)), brass, Vector3(0, 0.024, 0.056))   # Öse
	# Nordmarke bei der Öse (in der Hand oben, weg vom Spieler) und Striche für O, S, W
	Geo.mesh(self, Geo.box(Vector3(0.008, 0.002, 0.012)), Mat.psx(glow, "", 1.0, glow, 1.2), Vector3(0, 0.025, 0.034))
	for side in [Vector3(0.036, 0.025, 0), Vector3(0, 0.025, -0.036), Vector3(-0.036, 0.025, 0)]:
		Geo.mesh(self, Geo.box(Vector3(0.004, 0.002, 0.004)), Mat.psx(Color(0.25, 0.2, 0.15)), side)
	_needle = Node3D.new()
	_needle.position = Vector3(0, 0.027, 0)
	add_child(_needle)
	var red := Color(0.95, 0.2, 0.12)
	Geo.mesh(_needle, Geo.box(Vector3(0.007, 0.003, 0.036)), Mat.psx(red, "", 1.0, red, 1.5), Vector3(0, 0, -0.018))
	Geo.mesh(_needle, Geo.box(Vector3(0.007, 0.003, 0.034)), Mat.psx(Color(0.85, 0.85, 0.8), "", 1.0, glow, 0.4), Vector3(0, 0, 0.017))
	Geo.mesh(_needle, Geo.cylinder(0.005, 0.005, 6), brass, Vector3(0, 0.002, 0))


## Loses Kartenblatt, flach mit dem Plan nach oben (lokale +Y), Norden zur lokalen +Z.
func _build_map() -> void:
	var depth := MAP_WIDTH * HotelMap.PAGE_SIZE.y / HotelMap.PAGE_SIZE.x
	var plane := PlaneMesh.new()
	plane.size = Vector2(MAP_WIDTH, depth)
	var sheet := Geo.mesh(self, plane, HotelMap.material(page_id), Vector3(0, 0.002, 0))
	sheet.rotation.y = PI   # PlaneMesh: Bildoberkante liegt bei −Z
	Geo.mesh(self, Geo.box(Vector3(MAP_WIDTH, 0.0015, depth)), Mat.psx(Color(0.7, 0.64, 0.52)), Vector3(0, 0.00075, 0))


## Geschnitzt: „Geschnitzter Kürbis“, bei anderen Sorten mit deren Namen
func _carved_name() -> String:
	return ("Geschnitzter Kürbis" if variety == PumpkinKinds.DEFAULT else "Geschnitzter %s" % PumpkinKinds.data(variety)["name"]) 		+ ROT_NAMES[rot_stage]


# --- Faulen (Spielkonzept 5.10) -------------------------------------------------------------

## Deko-Stärke mit Verfall: welk und eingefallen zählt weniger.
func deco_value() -> float:
	return deco_strength * (SAG_DECO if rot_stage == 2 else (WILT_DECO if rot_stage == 1 else 1.0))


## Füllmaterial (FILLER_KINDS und kleine Kürbissorten)? Zählt an einer Stelle nur bis MonsterDirector.FILLER_CAP.
func is_filler() -> bool:
	return kind in FILLER_KINDS or (kind == Kind.PUMPKIN and not is_large)


## Faulzeit aus dem Zusatz („r=Spielzeit“) – ohne ihn beginnt sie jetzt (frisch geerntet bzw. neu erzeugt).
func _read_rot(extra: String) -> void:
	for part in extra.split(","):
		if part.begins_with("r="):
			rot_at = part.substr(2).to_float()
			return
	rot_at = Calendar._elapsed() + (ROT_CARVED if kind == Kind.CARVED_PUMPKIN else ROT_WHOLE)


func _rot_extra() -> String:
	return "r=%d" % int(rot_at)


## Stufe nachführen; ganz verfault ist er weg – in der Hand oder Tasche erst, sobald er wieder liegt.
func _decay() -> void:
	var life := ROT_CARVED if kind == Kind.CARVED_PUMPKIN else ROT_WHOLE
	var used := 1.0 - (rot_at - Calendar._elapsed()) / life
	if used >= 1.0:
		if is_held or in_bag or pocketed:
			return
		if Game.tracing:
			print("[Kürbis] %s ist verfault und weg" % display_name)
		queue_free()
		return
	var stage := 2 if used >= ROT_SAG else (1 if used >= ROT_WILT else 0)
	if stage > rot_stage:
		set_rot_stage(stage)


## Welk: dunkler und bräunlich; eingefallen: gestaucht. Nur vorwärts (Debug --rot setzt die Zeit).
func set_rot_stage(stage: int) -> void:
	var old_name: String = ROT_NAMES[rot_stage]
	for i in range(rot_stage + 1, stage + 1):
		for mi in get_children():
			var mesh := mi as MeshInstance3D
			if mesh == null:
				continue
			var mat := mesh.material_override as ShaderMaterial
			if i == 1 and mat and mat.has_meta("pumpkin_model"):
				# Modell: eigenes Material, nur die Grundfarbe abdunkeln (Textur bleibt)
				mat.set_shader_parameter("albedo", Color(1, 1, 1).darkened(0.3).lerp(Color(0.32, 0.24, 0.1), 0.35))
			elif i == 1 and mat and mat != _glow_material and mat.get_shader_parameter("emission_energy") == 0.0:
				var c: Color = mat.get_shader_parameter("albedo")
				mesh.material_override = Mat.psx(c.darkened(0.3).lerp(Color(0.32, 0.24, 0.1), 0.35))
			elif i == 2:
				mesh.scale *= Vector3(1.12, 0.7, 1.12)
				mesh.position *= Vector3(1.12, 0.7, 1.12)
	rot_stage = stage
	if kind == Kind.CARVED_PUMPKIN:
		display_name = _carved_name() + ("" if lit else " (ohne Licht)")
	else:
		display_name = display_name.trim_suffix(old_name) + ROT_NAMES[stage]
	if Game.tracing:
		print("[Kürbis] %s" % display_name)


## Deko-Stärke der Sorte im Verhältnis zum Halloween-Kürbis (geschnitzt: Weiß × 1,2, Riese × 2,5)
func _variety_deco() -> float:
	return float(PumpkinKinds.data(variety)["deco"]) / float(PumpkinKinds.data(PumpkinKinds.DEFAULT)["deco"])


## Kürbis je Sorte (PumpkinKinds): rund, flach gerippt, Flaschenform oder mit Kappe. Geschnitzt bekommt er ein Gesicht,
## mit der Größe der Sorte skaliert (Grundmaß: Halloween-Kürbis, 0,42 m). Halloween- und Riesenkürbis sind ein Modell
## (PumpkinModel).
func _pumpkin(carved: bool) -> void:
	if PumpkinModel.has_model(variety):
		_pumpkin_model(carved)
		return
	var d := PumpkinKinds.data(variety)
	var sz: Vector3 = d["size"]
	var base: Color = d["color"]
	var skin := Mat.psx(base.darkened(0.1) if carved else base)
	var stem := Mat.psx(Color(0.3, 0.35, 0.12))
	match String(d["shape"]):
		"flat":
			# Muskat: flach und tief gerippt
			Geo.mesh(self, Geo.sphere(sz.x / 2.0, sz.y, 10, 5), skin, Vector3(0, sz.y / 2.0, 0))
			var rib := Mat.psx(base.darkened(0.35))
			for i in 8:
				# Rippen nur um den Bauch (oben und unten ist die flache Kugel schmaler)
				var a := TAU * i / 8.0
				var strip := Geo.mesh(self, Geo.box(Vector3(0.03, sz.y * 0.42, 0.02)), rib,
					Vector3(cos(a) * sz.x * 0.46, sz.y * 0.5, sin(a) * sz.x * 0.46))
				strip.rotation.y = -a
		"bottle":
			# Butternut: dicker Bauch unten, schlanker Hals
			Geo.mesh(self, Geo.sphere(sz.x / 2.0, sz.x * 1.05, 8, 4), skin, Vector3(0, sz.x * 0.52, 0))
			Geo.mesh(self, Geo.cylinder(sz.x * 0.36, sz.y - sz.x * 0.75, 7), skin, Vector3(0, sz.x * 0.75 + (sz.y - sz.x * 0.75) / 2.0, 0))
			Geo.mesh(self, Geo.sphere(sz.x * 0.36, sz.x * 0.36, 7, 3), skin, Vector3(0, sz.y - 0.01, 0))   # runder Abschluss oben
		"turban":
			# Türkenturban: Unterteil kräftig orange, darauf eine hellere, grün gestreifte Kappe
			Geo.mesh(self, Geo.sphere(sz.x / 2.0, sz.y * 0.65, 9, 4), skin, Vector3(0, sz.y * 0.33, 0))
			Geo.mesh(self, Geo.sphere(sz.x * 0.3, sz.y * 0.5, 8, 4), Mat.psx(Color(0.85, 0.78, 0.5)), Vector3(0, sz.y * 0.68, 0))
			var green := Mat.psx(Color(0.3, 0.45, 0.2))
			for i in 4:
				var a := TAU * i / 4.0 + 0.4
				var stripe := Geo.mesh(self, Geo.box(Vector3(0.02, sz.y * 0.3, 0.015)), green,
					Vector3(cos(a) * sz.x * 0.27, sz.y * 0.68, sin(a) * sz.x * 0.27))
				stripe.rotation.y = -a
		_:
			Geo.mesh(self, Geo.sphere(sz.x / 2.0, sz.y * 0.94, 9, 5), skin, Vector3(0, sz.y * 0.47, 0))
	Geo.mesh(self, Geo.cylinder(0.025 * maxf(1.0, sz.x / 0.42), 0.07 * maxf(1.0, sz.x / 0.42), 5), stem, Vector3(0, sz.y, 0))
	if carved:
		var glow: Color = d.get("glow", Color(1.0, 0.6, 0.1))
		_glow_material = Mat.psx(glow.lightened(0.3), "", 1.0, glow, 3.0, false)
		var dark := Mat.psx(Color(0.1, 0.04, 0.0))
		var k := sz.x / 0.42
		var front := sz.x * 0.44
		for side: float in [-1.0, 1.0]:
			Geo.mesh(self, Geo.box(Vector3(0.06, 0.05, 0.04) * k), _glow_material, Vector3(side * 0.075 * k, 0.2 * k, front))   # Auge
		Geo.mesh(self, Geo.box(Vector3(0.15, 0.035, 0.04) * k), _glow_material, Vector3(0, 0.1 * k, front))   # Mund
		for side: float in [-1.0, 1.0]:
			Geo.mesh(self, Geo.box(Vector3(0.03, 0.02, 0.045) * k), dark, Vector3(side * 0.03 * k, 0.105 * k, front + 0.002))   # Zähne


## Meshy-Modell (PumpkinModel): glatt oder mit der Fratze face, auf die Breite der Sorte gebracht. Geschnitzt ist sein
## Material zugleich _glow_material – mit Kerze glüht das Fruchtfleisch (Glutmaske) in der Farbe der Sorte.
func _pumpkin_model(carved: bool) -> void:
	var d := PumpkinKinds.data(variety)
	var mat := PumpkinModel.material(d.get("glow", Color(1.0, 0.55, 0.15)) if carved else Color.BLACK)
	var mi := Geo.mesh(self, PumpkinModel.mesh_of(face if carved else 0), mat, Vector3.ZERO)
	mi.scale = Vector3.ONE * PumpkinModel.scale_for(variety)
	if carved:
		_glow_material = mat


## Kerzenlicht ohne Schatten; as_lamp: zählt zu den Lampen (Lichterkette).
func _add_light(pos: Vector3, color: Color, energy: float, light_range: float, as_lamp: bool = false) -> void:
	light = FlickerLight.new()
	light.position = pos
	light.light_color = color
	light.base_energy = energy
	light.omni_range = light_range
	light.soft = true
	light.shadow_enabled = false
	if as_lamp:
		light.set_meta("no_shadow", true)
		light.add_to_group("lamps")
	add_child(light)
