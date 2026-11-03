extends Node
## Speichern & Laden (Autoload „SaveManager“, Spielkonzept 8).
##   Slot 1–3: manuell am Tagebuch in Zimmer 13 · Slot 0: Autosave bei Fortschritt (on_progress), beim ersten Betreten
##   eines neuen Bereichs (NEW_AREAS) und beim Aufwachen in Zimmer 13 nach einer Nacht Schlaf (8.10) ·
##   Zwischenstand (SUSPEND): „Unterbrechen und beenden“ im Spielmenü, beim nächsten Laden gelöscht (8.10).
## Weil es kein Inventar gibt, ist die Welt der Spielstand: jeder Gegenstand mit Ort und
## Zustand, alle Gäste, die versteckten Werte des Monsters, Lampen, Türen, Vorhänge …
## Dateien: user://saves/slot_N.json (+ .png Vorschaubild), sicher geschrieben über .tmp.
## Laden = Hauptszene neu aufbauen und dann aus dem Spielstand befüllen.
## Feste Welt-Objekte werden über ihre Reihenfolge in der Gruppe zugeordnet. Ein Spielstand passt deshalb nur
## zu genau dem Hotel, in dem er entstand: Der Fingerabdruck der Welt (world_fingerprint) steht im Spielstand,
## ändert sich das Hotel, wird der Stand mit Hinweis abgelehnt statt falsch befüllt.

signal autosaved

## Headless (Testläufe, tests/smoke.sh) und mit --bg (Screenshot-Läufe nebenher) ein eigener Ordner – sonst
## überschreibt ein Testlauf den echten Autosave
var DIR := "user://saves_headless/" if DisplayServer.get_name() == "headless" or "--bg" in OS.get_cmdline_user_args() \
	else "user://saves/"
## 2: größeres Hotel (Kreuzungen, 30 Zimmer, Kellertreppe) – ältere Stände passen nicht mehr
## 3: zufällig erzeugte Gäste (Seed + Zimmer im Spielstand)
## 4: Obergeschoss, dritte Kreuzung, Spuren und Zettel der Gäste
## 5: Zimmertelefone (Gruppe phones) – Stände mit Version 4 laden weiter, alle Hörer liegen auf
## 6: am Körper (player.compass/map_pages/keyring), Kartenblätter – ältere Stände laden weiter,
##    Kompass, Karte und Schlüssel liegen dort noch in der Welt
## 7: Kommoden im Flur (Gruppe dressers) – ältere Stände laden weiter, alle Schubladen sind zu und unberührt
## 8: Hotelkatzen (Gruppe cats) – ältere Stände laden weiter, die Katzen beginnen an ihren Startplätzen
## 9: Milchglas zwischen Flur und Zimmern entfernt (Gruppe windows kleiner, Spuren hängen an Fenster-Indizes)
## 10: Deckenlampen entfernt, dafür Wandleuchten, zwei je Zimmer (Gruppe lamp_fixtures anders)
## 11: Schreck & Erlebnisse der Gäste, Leichen, Lakengeist bei Gästen (corpse, ghost_visits, seen, experiences)
##     – Stände mit Version 10 laden weiter, die Gäste haben dann noch nichts erlebt
## 12: Nächte ohne Schlaf (player.nights_awake) – ältere Stände laden weiter, der Spieler gilt als ausgeschlafen
## 13: Schachbrett (Item.Kind.CHESS_BOARD) – in älteren Ständen bleibt das Brett vom Start auf dem Schachtisch
## 14: Freundschaftsstufen (Gast: deeds, chat_day, chats_today; Spieler: injury) – ältere Stände laden weiter,
##     es gab dann noch keine Taten (die Extreme müssen neu verdient werden)
## 15: neuer Grundriss aus dem Gebäudeplan (Spielkonzept 7.5) – alle Gruppen neu, ältere Stände passen nicht mehr
## 16: Einrichtung aus den Objektebenen des Plans – Lampen, Schalter, Verstecke, Kommoden, Telefone … in neuer
##     Reihenfolge, ältere Stände passen nicht mehr
## 17: vier Deckenleuchten in der Lobby (Spielkonzept 7.3) – mehr Lampen, ältere Stände passen nicht mehr
## 18: Deckenleuchten in Bar, Partyraum und Lobby – mehr Lampen, ältere Stände passen nicht mehr
## 19: Deckenleuchten über den zehn Flurkübeln – mehr Lampen, ältere Stände passen nicht mehr
## 20: Fingerabdruck der Welt („world“) – Umbauten am Hotel brauchen keine neue Version mehr, nur noch
##     Änderungen am Aufbau des Spielstands selbst
## 21: Rausch und Kater (player.drunk/hangover, Gast drunk) – Stände mit Version 20 laden weiter, alle nüchtern
## 22: Kinder (Spielkonzept 6.13) – „parent“ in der Gästeliste (roster); ältere Stände laden weiter, ohne Kinder
## 23: aufgehängte Deko (Spielkonzept 5.6) – „hung“ an Gegenständen, neue Arten Lakengespenst, Lichterkette,
##     Zierkürbis; ältere Stände laden weiter, dort hängt noch nichts
## 24: übergeworfenes Bettlaken (player.disguised, Item.Kind.BED_SHEET) – ältere Stände laden weiter, unverkleidet
## 25: Freundschaften unter Gästen (Spielkonzept 6.16) – „pals“ unter „social“; ältere Stände laden weiter, dort
##     sind nur Familie und Zimmernachbarn befreundet
## 26: Überlebende & Verletzungen (Spielkonzept 6.17) – je Gast wound, wound_left, wound_bed, wound_facts, wound_told,
##     wound_visited; ältere Stände laden weiter, alle unverletzt
## 27: Verdacht wegen Katzendiebstahl (social.cat_blame), ohne Delle der Dreistigkeit (director.boldness_dip entfällt) –
##     ältere Stände laden weiter, dort verdächtigt keiner den Spieler, eine gespeicherte Delle wird übergangen
## 28: Tasche für Kleines (player.bag, Spielkonzept 3.2) und Getränkedosen (Item.Kind.SODA_CAN) – ältere Stände
##     laden weiter, die Tasche ist dann leer
## 29: Puppe (Spielkonzept 5.5: „doll“, im Director Frist, Urteil und Weg), Feindschaften unter Gästen (social.pals mit
##     counts und feuds), Spaßwert und Garantie des Kürbismanns („pumpkin“), Aufholen des Lakengeists (ghost.catch_up_day)
##     – ältere Stände laden weiter, die Puppe sitzt dann in der Lobby
## 30: Aufzug (Spielkonzept 7.4, Gruppe elevators: Höhe der Kabine, gewählte Halte, Tür offen) – ältere Stände passen
##     ohnehin nicht mehr (Aufzugtüren und Kabinenleuchte ändern den Fingerabdruck)
## 31: Tagesuhr (Spielkonzept 2.4) – ein Tag dauert 1440 statt 300 s, die Nachtruhe folgt der Uhr (social.night_seed statt
##     sleep_timer); ältere Stände laden nicht mehr (ihre Spielzeit ergäbe einen ganz anderen Tag)
## 32: Knappheit (Spielkonzept 5.10) – Faulzeit der Kürbisse im Zusatz der Gegenstände („r=…“), Tag der letzten
##     Entnahme eines Gastes je Kiste (resources.guest_day); ältere Stände laden nicht (Kisten wären wieder voll)
## 33: Spielerfigur (Spielkonzept 3.9, player.look: Grundkörper, Größe, Statur, Farben) – ältere Stände laden weiter
##     mit der Standardfigur
## 34: Fratze geschnitzter Kürbisse im Zusatz („f=1…5“, PumpkinModel) – ältere Stände laden weiter, die Fratze wird
##     beim Laden ausgewürfelt
## 35: Geisterstunde (Spielkonzept 4.18, ghost.hour_meetings) – ältere Stände laden weiter, er bemerkt einen dann wieder
##     zum ersten Mal
## 36: Türschmuck-Wettbewerb (Spielkonzept 2.5, „contest“: Abschnitt, Brief, Durchsagen, Zettel, erstes Urteil; Puppe
##     „gone“), ohne director.first_attack_day – ältere Stände laden weiter: Ist der erste Angriff schon gewesen, ist
##     der Wettbewerb vorbei, sonst beginnt er von vorn
## 37: Notizbuch (Spielkonzept 3.10, „notebook“: Aufgaben und Notizen) und Meilensteine im Tagebuch („diary“:
##     aufgeschrieben und noch nicht) – ältere Stände laden weiter: Wer den Brief gelesen hat, hat ein leeres Notizbuch
## 38: Im Regen verwaschen (Spielkonzept 4.13, RainVeil): Spuren mit „wash“, Schleier als Spur „veil“ in „traces“,
##     Kürbismatsch „w=…“ im Zusatzfeld – ältere Stände laden weiter, alles unverwaschen
## 39: Haushalte und Zimmerzugang (Spielkonzept 6.19, 6.20): Roster mit „household“/„member“ (Identität aus
##     HAUSHALTE.md), Türen mit „broken“, „by_player“, „broken_day“, Gruppe „key_cabinets“ – ältere Stände passen nicht
##     mehr zu den Haushalten
## 40: Nächte ohne Schlaf anteilig (Spielkonzept 3.6, player.nights_awake als Kommazahl) – ältere Stände laden weiter
## 41: Kaffee (Spielkonzept 3.11): player.coffee, coffee_low, caffeine und die Tasse (Item.Kind.COFFEE) – ältere Stände
##     laden weiter, ohne Kaffee im Blut
## 42: Notizbuch „seen“ (Spielkonzept 3.10: gesehene Bedrohungen, Lesezeichen „Gesehen“) – ältere Stände laden weiter,
##     noch nichts gesehen
## 43: Tee (Spielkonzept 3.12): player.tea und die Tasse (Item.Kind.TEA) – ältere Stände laden weiter, ohne Tee
## 44: Gespräche (Spielkonzept 6.9, Talk): je Gast „claims“ (was du ihm gesagt hast) und „stances“ (Haltungen),
##     social.talk (deine Erlebnisse, Einbruchsverdacht, Todesfälle) – ältere Stände laden weiter, alle ohne Gedächtnis
## 45: Kerzen (Spielkonzept 5.12): feste Kerzen („fixed_candles“, brennen oder nicht), keine Brenndauer mehr („burn“
##     entfällt), Kürbis und Totenkopf mit erloschener Kerze (Zusatz „out“), Streichholzschachtel (Item.Kind.MATCHBOX)
## 46: Lakengeist in der Dusche (Spielkonzept 4.24): ghost.first_seen (erste Begegnung), „shower“ (wartet, läuft,
##     erlebt) – ältere Stände laden weiter: Wer ihm schon begegnet ist, gilt als am Anfang begegnet
## 47: Darts (Spielkonzept 6.10): Pfeile (Item.Kind.DARTS), social.darts_watched (wem du beim Werfen zugesehen hast) –
##     ältere Stände laden weiter, noch niemandem zugesehen
## 48: Salz (Spielkonzept 5.13): Salzpackung (Item.Kind.SALT, Zusatz = übrige Linien), Salzlinien („salt“) – ältere
##     Stände laden weiter, ohne Salz
## 49: Vorzeichen und Spuk (Spielkonzept 4.25–4.31, 5.17, 6.21): „omens“ (Groll der Krähen, verhängter Spiegel in
##     Zimmer 13, Stromausfall, Albtraum, Kind zu viel), Spieluhr und Apfel (Item.Kind.MUSIC_BOX, APPLE) – ältere Stände
##     laden weiter, alles wie am Anfang
## 50: Friedhof (Spielkonzept 5.15): je Gast „buried“, „cemetery“ (Gräber, wartende Leichen) – ältere Stände laden
##     weiter, ihre Leichen warten dann aufs Grab
## 51: Bitten der Gäste (Spielkonzept 6.14): social.requests (offene Bitten, erfüllte Herzensbitten) – ältere Stände
##     laden weiter, ohne Bitten
## 52: Verbotene Masken (Spielkonzept 5.19): Item.Kind.MASK, player.mask (aufgesetzt), „mask_hooks“ (je Maske, ob sie in
##     Zimmer 13 hängt), director.doll_mask – ältere Stände laden weiter, die Masken hängen dann an ihren Haken
## 53: Heiße Stellen statt Neugier je Zone (Spielkonzept 4.9): director.state.hot_spots und boldness_bonus statt
##     director.curiosity – ältere Stände laden weiter, ohne heiße Stellen und Boni
## 54: Der Name Leviathan (Spielkonzept 4.32): „leviathan“ (Stufe, Zeuge, wer den Namen kennt) – ältere Stände laden
##     weiter, noch ohne Sichtung
## 55: Die vier Modi des Leviathan (Spielkonzept 4.33): Plan der Modi, laufender Modus, Verurteilter, Raubzüge,
##     Anforderungen, stärkste Lockung; die Dreistigkeit steigt viel langsamer und ohne Obergrenze – ältere Stände
##     laden nicht mehr (ihre Dreistigkeit läge weit über den Schwellen der Anforderung)
## 56: Wachzeit statt Nächte ohne Schlaf (Spielkonzept 3.6): player.awake_time, sure_awake, rested – ältere Stände laden
##     weiter, ihre Nächte ohne Schlaf werden zu je 24 Stunden wach
## 57: Kerzen brennen ab (Spielkonzept 5.12): übriges Wachs im Zusatz („w=…“ bei Kerze, Kürbis, Totenkopf) und bei den
##     festen Kerzen („wax“), Kerzenvorrat mit „refill_day“ – ältere Stände laden weiter, alle Kerzen dann neu
## 59: Krähen-Erweiterung (Spielkonzept 4.25): omens.crows mit Ruf („favor“ statt „grudge“), Nest, Fütterungen und
##     Futterzeit; Krähenfutter mit Zusatz „brot“ (Brotkrumen) – ältere Stände laden weiter, Groll wird zum Ruf, das Nest
##     ist wie am Anfang
## 60: Schlüssel stehlen und Zweitschlüssel (Spielkonzept 6.19): social.access.stolen (Zimmer → wann das Schloss
##     getauscht wird), social.access.spares, alte Schlüssel am Bund („alt_…“) – ältere Stände laden weiter, ohne
##     gestohlene und Zweitschlüssel
## 61: Gezinkte Würfel stecken im Würfelbecher (Zusatz „loaded“, Spielkonzept 6.10) statt am Würfeltisch
##     (table_loaded) – ältere Stände laden weiter, die Würfel kommen in den Becher auf dem Mäxchen-Tisch
## 62: Spinde der Pool-Umkleiden (Gruppe locker_banks, ZIM-145): je Block offen, aufgeschlossen, durchsucht –
##     ohne Eintrag sind alle Spinde zu und unberührt
## 63: Schlüsselschrank entfällt (ZIM-136): Gruppe key_cabinets nicht mehr gespeichert – ein alter Eintrag wird
##     übergangen
## 64: Bestenlisten der Videoautomaten (Gruppe arcades, ZIM-72): je Gerät die Einträge [Kürzel, Punkte, wer] –
##     ohne Eintrag stehen nur die alten Einträge von früher darin
## 65: Beziehung nicht erschleichen (Spielkonzept 6.18, 5; ZIM-163): je Gast talk_day, talks_today, filler_day,
##     hostile_day, an Gegenständen „got“ (von wem bekommen) – ältere Stände laden weiter, ohne Markierung und mit
##     vollen Tagesbudgets
## 66: Tagebuch beim Einbruch (Spielkonzept 8.9, 6.19; ZIM-54): je Tagebucheintrag „who“ (Gast-ID, um den es bei einer
##     dunklen Tat geht) – ältere Stände laden weiter, ihre Einträge nennen niemanden (ein Einbrecher erfährt nichts)
## 67: Streit unter Gästen (Spielkonzept 6.16, ZIM-33): social.quarrels – je Paar Dieb, Bestohlener, Spieltag,
##     Wortwechsel gewesen, schon vorher verfeindet; ältere Stände laden weiter, ohne Streit
## 68: Kisten ohne Nachschub über den Monat verteilt (Spielkonzept 5.10, ZIM-81): resources.guest_taken (so viele Stück
##     haben Gäste genommen) – ältere Stände laden weiter und zählen alles Fehlende als von Gästen genommen
## 69: Fledermausbiss (Spielkonzept 4.22; ZIM-29): player.bite und bite_heal (Bisswunde, Spielsekunden) – ältere Stände
##     laden weiter, ungebissen
## 70: Humpeln nach dem Sprung vom Balkon (Spielkonzept 7.7, ZIM-36): player.limp (Spielsekunden) – ältere Stände laden
##     weiter, ohne Humpeln
## 71: Jeder Tod hat eine Ursache (Spielkonzept 6.18, 2; ZIM-160): social.deaths – offene Ursachen je Gast (causes) und
##     die Toten mit Ursache, Schuld und Gedenken (records); an Gegenständen „taken“ (wem der Spieler sie genommen hat,
##     Meta taken_from); director.grief entfällt (Schock und Trauer sind ein Wert) – ältere Stände laden weiter, ohne
##     Ursachen und Schuld
## 72: Trauer der Gäste (Spielkonzept 6.12; ZIM-41): an Gegenständen „memorial“ (Gedenkkerze eines Freundes für diesen
##     Toten – niemand klaut sie); die Trauer selbst steht in der Haltung „grieving“ (id, visits, next, lit) – ältere
##     Stände laden weiter, ihre Trauernden gehen nicht zum Gedenkort (ohne ID des Toten)
## 73: Schwere Momente (Spielkonzept 6.18, 3; ZIM-161): Bitten mit „state“ (der Zustand, mit dem der Wunsch verfällt),
##     social.requests.granted (erfüllte Wünsche je Gast und Zustand), an Gegenständen „cat_took“ (von einer Katze
##     verschleppt – wem es gehört); die Zustände selbst stehen in den Haltungen (after_ghost, doll_door, cat_took) –
##     ältere Stände laden weiter, ohne Wünsche aus schweren Momenten
## 74: Gläser von der Bar (Spielkonzept 3.7; ZIM-35): neue Art Item.Kind.GLASS, die Sorte (bier, wein, schnaps) im
##     Zusatz wie bei den Dosen – ältere Stände laden weiter, ohne Gläser
## 75: Puppenmaske entschärft (Spielkonzept 5.19; ZIM-102): director.doll_mask entfällt – ältere Stände laden weiter,
##     das alte Feld wird übergangen
## 76: Ehering im Dachnest (Spielkonzept 4.25, 6.14; ZIM-50): neue Art Item.Kind.RING, omens.crows.roof_nest (Inhalt des
##     Dachnests), social.requests.rare (erfüllte seltene Bitten) – ältere Stände laden weiter, der Ring liegt im Nest
## 77: Halt des Aufzugs im Dachgeschoss freigeschaltet (Spielkonzept 7.10; ZIM-42: elevators.unlocked) – ältere Stände
##     laden weiter, der Halt ist dann noch gesperrt
const VERSION := 77
const MIN_VERSION := 55
const SLOTS := 3
const AUTOSAVE := 0
## Zwischenstand von „Unterbrechen und beenden“ (8.10): nur einmal ladbar, steht in keiner Slot-Nummer 1–3
const SUSPEND := SLOTS + 1
## Mindestabstand zum Monster für den Autosave (Tuning)
const AUTOSAVE_MONSTER_DISTANCE := 25.0
## Aufwachen in Zimmer 13 (8.10): so viele Spielsekunden muss der Schlaf in der Nachtruhe gelegen haben
## (= Player.SLEEP_MIN, zwei Stunden) – wer nur kurz nachts die Augen zumacht, hat keine Nacht geschlafen
const NIGHT_SLEEP := 120.0
## Schlüssel, deren Fund Fortschritt ist (8.10): Zimmer 18 (Sperrbereich 2.3, Aufzug 7.4), Dachboden (4.21) und der
## Schaltschlüssel des Aufzugs aus Zimmer 18 (7.4)
const PROGRESS_KEYS := ["zimmer_18", "dachboden", "aufzug"]
## Gruppen fester Welt-Objekte, die nach Reihenfolge gespeichert werden; bei COUNT_ONLY zählt nur die Anzahl
## (Katzen beginnen nicht immer am selben Platz)
const WORLD_GROUPS := ["doors", "chests", "pumpkin_plants", "resource_spots", "lamp_fixtures", "light_switches",
	"windows", "hide_spots", "phones", "dressers", "cats", "elevators", "fixed_candles", "locker_banks", "arcades"]
const COUNT_ONLY := ["cats"]
## Fingerabdruck des zuletzt gebauten Hotels – für die Slot-Übersicht, bevor ein Hotel steht
var WORLD_FILE := DIR + "world.txt"
## Neue Bereiche (8.10): Ihr erster Besuch löst einen Autosave aus – nur Dachboden, U2 (sobald es die Zone gibt, 7.4)
## und die Sperrbereiche (2.3, bisher Zimmer 18), nicht mehr der Alltag (Lobby, Flure, Keller …). Weitere Sperrbereiche
## (Personaltrakt, Büro der Direktion) kommen hierher, sobald sie gebaut sind. Namen wie in _area_at.
const NEW_AREAS := ["Dachboden", "U2", "Zimmer 018"]

## Zeitpunkt (Ticks in ms) des letzten Speicherns oder Ladens in dieser Sitzung
var last_save_msec := -1
var visited: Array = []

## Fingerabdruck des aktuellen Hotels ("" = noch keins gebaut, dann aus WORLD_FILE)
var world := ""
var _pending_autosave := ""
var _check_timer := 0.0
var _sleep_from := -1.0      ## Spielzeit, seit der der Spieler schläft (−1 = wach)
var _sleep_home := false     ## … im eigenen Bett in Zimmer 13
var _night_saved := -1.0     ## Ende der Nachtruhe, nach der zuletzt beim Aufwachen gesichert wurde (einmal je Nacht)


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	DirAccess.make_dir_recursive_absolute(DIR)
	if FileAccess.file_exists(WORLD_FILE):
		world = FileAccess.get_file_as_string(WORLD_FILE).strip_edges()


func _process(delta: float) -> void:
	if Game.player == null or Game.game_over:
		return
	_check_timer -= delta
	if _check_timer > 0.0:
		return
	_check_timer = 1.0
	_check_new_area()
	_check_wake()
	if _pending_autosave != "" and is_safe_for_autosave():
		var reason := _pending_autosave
		_pending_autosave = ""
		autosave(reason)


# --- Slots -------------------------------------------------------------------------

func slot_path(slot: int, ext: String = "json") -> String:
	var file := "autosave" if slot == AUTOSAVE else ("suspend" if slot == SUSPEND else "slot_%d" % slot)
	return DIR + file + "." + ext


func slot_exists(slot: int) -> bool:
	return FileAccess.file_exists(slot_path(slot))


## Kopfdaten für die Slot-Übersicht ({} = leer oder unlesbar). "fits" = false: stammt aus einem anderen
## Hotel oder einer anderen Spielstand-Version und lässt sich nicht laden.
func slot_info(slot: int) -> Dictionary:
	var data := _read(slot)
	if data.is_empty():
		return {}
	return {
		"text": data.get("text", ""), "saved_at": data.get("saved_at", 0),
		"playtime": data.get("playtime", 0.0), "alive": data.get("alive", []), "fits": fits(data),
	}


## Passt der Spielstand zu diesem Spiel? Ist das Hotel noch nicht gebaut und auch kein Fingerabdruck
## gemerkt, gilt er vorerst als passend – main.gd prüft nach dem Aufbau noch einmal.
func fits(data: Dictionary) -> bool:
	var version := int(data.get("version", 0))
	if version > VERSION or version < MIN_VERSION:
		return false
	return world == "" or String(data.get("world", "")) == world


## Fingerabdruck aus Anzahl und Lage der festen Welt-Objekte – nach dem Aufbau des Hotels aufrufen,
## bevor sich etwas bewegt. Merkt ihn sich auch für die Slot-Übersicht im Titelbildschirm.
func note_world() -> void:
	var parts: PackedStringArray = []
	for group in WORLD_GROUPS:
		var nodes := get_tree().get_nodes_in_group(group)
		parts.append("%s:%d" % [group, nodes.size()])
		if group in COUNT_ONLY:
			continue
		for node in nodes:
			var p: Vector3 = (node as Node3D).global_position.snapped(Vector3.ONE * 0.1)
			parts.append("%.1f,%.1f,%.1f" % [p.x, p.y, p.z])
	var fingerprint := ";".join(parts).md5_text()
	if fingerprint != world:
		world = fingerprint
		var file := FileAccess.open(WORLD_FILE, FileAccess.WRITE)
		if file:
			file.store_string(world)


func thumbnail(slot: int) -> Texture2D:
	var path := slot_path(slot, "png")
	if not FileAccess.file_exists(path):
		return null
	var img := Image.load_from_file(ProjectSettings.globalize_path(path))
	return ImageTexture.create_from_image(img) if img else null


## Neuester Spielstand (Slots, Autosave und Zwischenstand), −1 = keiner.
func newest_slot() -> int:
	var best := -1
	var best_time := -1
	for slot in range(0, SUSPEND + 1):
		var info := slot_info(slot)
		if not info.is_empty() and info["fits"] and int(info["saved_at"]) > best_time:
			best_time = int(info["saved_at"])
			best = slot
	return best


func has_any_save() -> bool:
	return newest_slot() >= 0


# --- Speichern ---------------------------------------------------------------------

## Am Tagebuch: gesperrt, solange das Monster in der Nähe ist (Rauschen) oder jagt (8.5, 4.13),
## solange die Flackerwelle läuft (4.17), der Kürbismann im Hotel ist (4.19) und der Lakengeist beim
## Spieler ist (4.18). Der Kürbismann wird nicht gespeichert – sonst wäre man ihn durch Laden los.
func can_save() -> bool:
	if Game.director == null or Game.game_over or Game.player == null or Game.director.is_signalling():
		return false
	if Game.player.climbing():   # übers Balkongeländer (7.7) – sonst lädt man mitten darauf oder im Fall
		return false
	if (Game.pumpkin and (Game.pumpkin.in_house() or Game.pumpkin.announcing())) or (Game.ghost and Game.ghost.with_player()):
		return false
	if Game.shower_scare and Game.shower_scare.busy():   # die Dusche hat den Blick gefangen (4.24)
		return false
	if Game.nightmare and Game.nightmare.active():   # im Albtraum von 1987 (4.29)
		return false
	var monster := Game.monster
	if not monster.is_active():
		return true
	return monster.state != Monster.State.CHASE \
		and monster.global_position.distance_to(Game.player.global_position) >= MonsterDirector.NOISE_START


## Vorzeichen und Spuk (Spielkonzept 4.25–4.31): je System ein Eintrag, fehlende bleiben wie am Anfang.
func _collect_omens() -> Dictionary:
	var omens := {}
	for entry in [["crows", Game.crows], ["mirrors", Game.mirror_omens], ["power", Game.power_cut],
			["nightmare", Game.nightmare], ["extra_child", Game.extra_child], ["weather", Game.weather]]:
		if entry[1]:
			omens[entry[0]] = entry[1].save_state()
	return omens


func _apply_omens(omens: Dictionary) -> void:
	for entry in [["crows", Game.crows], ["mirrors", Game.mirror_omens], ["power", Game.power_cut],
			["nightmare", Game.nightmare], ["extra_child", Game.extra_child], ["weather", Game.weather]]:
		if entry[1]:
			entry[1].load_state(omens.get(entry[0], {}))


func save_to(slot: int, text: String, thumb: Image) -> bool:
	var data := collect()
	data["text"] = text
	data["slot"] = slot
	var ok := _write(slot, data)
	if ok and thumb:
		thumb.save_png(slot_path(slot, "png"))
	if ok:
		last_save_msec = Time.get_ticks_msec()
	return ok


## Autosave im nächsten sicheren Moment (8.6). Auslöser nur noch Fortschritt, neue Bereiche und das Aufwachen (8.10) –
## nicht Tod eines Gastes, Ende einer Feier oder eine aufgeschlossene Tür: sonst wäre man alle paar Minuten gesichert.
func request_autosave(reason: String) -> void:
	_pending_autosave = reason
	if Game.tracing:
		print("[Autosave] vorgemerkt: %s" % reason)


## Fortschritt (Spielkonzept 8.10): Systeme rufen das, wenn ein großer Schritt geschafft ist – Aufzug repariert (7.4),
## Kopf gefunden und Kürbismann erlöst (4.21), ein wichtiger Schlüssel (on_key), später der Fluchtweg. Einmal je
## Ereignis rufen; der Autosave folgt im nächsten sicheren Moment.
func on_progress(reason: String) -> void:
	request_autosave("Fortschritt: " + reason)


## Ein Schlüssel kommt an den Bund (Player.add_key): Die aus PROGRESS_KEYS sind Fortschritt.
func on_key(id: String) -> void:
	if id in PROGRESS_KEYS:
		on_progress("Schlüssel „%s“" % id)


## Nur in sicheren Momenten (8.6) – sonst wird der Autosave aufgeschoben.
func is_safe_for_autosave() -> bool:
	var p := Game.player
	if p == null or p.dead or p.hiding != null or p.in_dialog or Game.game_over:
		return false
	if not p.is_on_floor() or p.climbing():   # nicht im Sprung oder Fall – sonst lädt man womöglich mitten in der Luft oder im Leeren
		return false
	if Game.table_game_active():
		return false
	if Game.menus and Game.menus.is_open():
		return false
	if Game.contest and Game.contest.in_scene():   # Siegerehrung (2.5) – gleich geht das Licht aus
		return false
	if not can_save():
		return false
	if Game.monster.is_active() and Game.monster.global_position.distance_to(p.global_position) < AUTOSAVE_MONSTER_DISTANCE:
		return false
	return true


func autosave(reason: String) -> void:
	# Headless (Testläufe) gibt es kein Bild – dann ohne Vorschau
	var thumb: Image = null if DisplayServer.get_name() == "headless" else get_viewport().get_texture().get_image()
	var text := diary_sentence()
	if save_to(AUTOSAVE, text, thumb):
		autosaved.emit()
		if Game.tracing:
			print("[Autosave] gespeichert (%s): „%s“" % [reason, text])


func _check_new_area() -> void:
	var area := _area_at(Game.player.global_position)
	if area in NEW_AREAS and not area in visited:
		visited.append(area)
		request_autosave("Neuer Bereich: " + area)


## Bereich für NEW_AREAS: der Name der Zone – im Dachgeschoss „Dachboden“ (dessen Flurzonen heißen wie die im
## Obergeschoss; Höhe des Bodens wie bei den Fledermäusen aus den Pfosten).
func _area_at(p: Vector3) -> String:
	var builder: LevelBuilder = Game.social.builder if Game.social else null
	if builder and not builder.attic_beams.is_empty() and absf(p.y - (builder.attic_beams[0]["pos"] as Vector3).y) < 1.5:
		return "Dachboden"
	return Game.director.zone_name_at(p)


## Aufwachen in Zimmer 13 nach einer Nacht Schlaf (8.10, 2.4, 3.6): Der Schlaf im eigenen Bett lag mindestens
## NIGHT_SLEEP in einer Nachtruhe – dann ein Autosave, einmal je Nacht. Fremde Betten zählen nicht. Hier abgefragt
## statt im Schlaf selbst, damit Player und SleepSkip unberührt bleiben.
func _check_wake() -> void:
	var p := Game.player
	var now := Game.director.elapsed
	if p.sleeping:
		if _sleep_from < 0.0:
			_sleep_from = now
			_sleep_home = p.hiding != null and p.hiding.own_bed
		return
	if _sleep_from < 0.0:
		return
	var from := _sleep_from
	_sleep_from = -1.0
	if not _sleep_home or p.dead or Game.social == null:
		return
	var day := Calendar.raw_day_of(from)
	for d in [day - 1, day]:
		var night: Vector2 = Game.social.night_window(d)
		if minf(now, night.y) - maxf(from, night.x) >= NIGHT_SLEEP and night.y != _night_saved:
			_night_saved = night.y
			request_autosave("Aufgewacht in Zimmer 13")
			return


## Neues Spiel oder geladener Stand: nichts mehr vorgemerkt, Schlaf von vorn.
func reset_pending() -> void:
	_pending_autosave = ""
	_sleep_from = -1.0
	_night_saved = -1.0


## „Unterbrechen und beenden“ (8.10): legt den Zwischenstand an – jederzeit, aber nicht in Momenten, die der
## Spielstand nicht festhält (can_save: Monster unterwegs, Kürbismann, Lakengeist …). false = nicht gespeichert.
func suspend(thumb: Image) -> bool:
	return can_save() and save_to(SUSPEND, diary_sentence(), thumb)


## Den Zwischenstand gibt es nur einmal: Beim nächsten Laden – egal welchen Standes – und bei einem neuen Spiel
## vom Titelbildschirm ist er weg.
func drop_suspend() -> void:
	for ext in ["json", "png"]:
		if FileAccess.file_exists(slot_path(SUSPEND, ext)):
			DirAccess.remove_absolute(slot_path(SUSPEND, ext))


# --- Laden -------------------------------------------------------------------------

func load_slot(slot: int) -> bool:
	if Game.entering:
		return true
	var data := _read(slot)
	if data.is_empty() or not fits(data):
		return false
	Game.pending_load = data
	Game.new_game_slot = 0
	if slot != AUTOSAVE and slot != SUSPEND:
		Game.current_slot = slot
	drop_suspend()   # nur einmal ladbar (8.10) – der Stand steckt jetzt in pending_load
	Game.enter_game()
	return true


func load_newest() -> bool:
	var slot := newest_slot()
	return slot >= 0 and load_slot(slot)


# --- Tagebuchsatz ---------------------------------------------------------------------

## Zahlwörter für den Tagebuchsatz („zwei Kürbisse“), darüber Ziffern
const NUMBER_WORDS := ["null", "ein", "zwei", "drei", "vier", "fünf", "sechs", "sieben", "acht", "neun", "zehn", "elf",
	"zwölf"]


## Ein kurzer Tagebuchsatz aus dem aktuellen Stand – erscheint in der Slot-Übersicht. Mit Namen nur, wer zählt
## (_named_in_diary), die übrigen Gäste werden gezählt (8.10): „Edna ist fort. Neun andere auch.“
func diary_sentence() -> String:
	var parts: Array[String] = []
	var contest_line := Game.contest.diary_line() if Game.contest else ""   # Ankunft bzw. erstes Urteil der Puppe (2.5)
	if contest_line != "":
		parts.append(contest_line)
	if Game.social:
		parts.append_array(_guest_lines())
	var lit := 0
	var deco := 0
	if Game.director:
		var door: Vector3 = Game.director.player_door_front
		for node in get_tree().get_nodes_in_group("items"):
			var item := node as Item
			if item.is_held or item.deco_strength <= 0.0:
				continue
			if Vector2(item.global_position.x - door.x, item.global_position.z - door.z).length() < 2.5 and absf(item.global_position.y - door.y) < 3.0:
				deco += 1
				if item.lit and item.kind == Item.Kind.CARVED_PUMPKIN:
					lit += 1
	if lit > 0:
		parts.append("Vor meiner Tür brennt ein Kürbis." if lit == 1 else "Vor meiner Tür brennen %s Kürbisse." % _number(lit))
	elif deco == 0:
		parts.append("Vor meiner Tür steht nichts. Gar nichts.")
	if Game.player and Game.player.shock > 0.3:
		parts.append("Ich kann nicht aufhören zu zittern.")
	var date := Calendar.date_text(Game.director.elapsed) + ". " if Game.director else ""
	if Game.director and Game.director.strange_diary:
		# Zimmer 13 bleibt nicht unberührt (4.13): eine Zeile, die man nicht geschrieben hat
		return date + " ".join(parts.slice(0, 2)) + " – Darunter, in fremder Schrift: »Ich sehe dir beim Schreiben zu.«"
	if parts.is_empty():
		parts.append("Noch ein Abend in diesem Hotel. Es ist still. Zu still.")
	return date + " ".join(parts.slice(0, 3))


## Wer im Tagebuchsatz mit Namen vorkommt (8.10): die Kernfiguren (6.0). Die zentralen Gäste kommen hier dazu, sobald
## sie besetzt sind.
static func _named_in_diary(guest: Guest) -> bool:
	return guest.is_core()


## Die Gäste im Tagebuchsatz, je Gruppe ein Teil: die Toten, wer nicht mehr mit mir redet, Freunde. Mit Namen nur
## _named_in_diary, die übrigen als Zahl dahinter – „Edna ist fort. Neun andere auch.“
func _guest_lines() -> Array[String]:
	var names := {"dead": [], Social.Tier.STRONG_ENEMY: [], Social.Tier.ENEMY: [], Social.Tier.FRIEND: [],
		Social.Tier.GOOD_FRIEND: []}
	var count := {"dead": 0, "enemies": 0, "friends": 0}
	for guest in Game.social.guests:
		var g: Guest = guest
		var tier := Social.tier(g) if not g.dead else Social.Tier.NEUTRAL
		var group := "dead" if g.dead else ("enemies" if tier in [Social.Tier.ENEMY, Social.Tier.STRONG_ENEMY]
			else ("friends" if tier in [Social.Tier.FRIEND, Social.Tier.GOOD_FRIEND] else ""))
		if group == "":
			continue
		if _named_in_diary(g):
			names["dead" if g.dead else tier].append(g.display_name)
		else:
			count[group] += 1
	# Benannte: je Stufe ein Satz, mehrere Namen darin zusammen („Auf Edna und Bruno kann ich mich verlassen.“)
	var said := func(key: Variant, one: String, many: String) -> String:
		var list: Array = names[key]
		return "" if list.is_empty() else (one if list.size() == 1 else many) % _names(list)
	var enemies := " ".join([said.call(Social.Tier.STRONG_ENEMY, "%s hasst mich. Ich halte mich fern.",
		"%s hassen mich. Ich halte mich fern."), said.call(Social.Tier.ENEMY, "%s redet nicht mehr mit mir.",
		"%s reden nicht mehr mit mir.")]).strip_edges()
	var friends := " ".join([said.call(Social.Tier.GOOD_FRIEND, "Auf %s kann ich mich verlassen.",
		"Auf %s kann ich mich verlassen."), said.call(Social.Tier.FRIEND, "%s und ich sind Freunde geworden.",
		"Mit %s bin ich befreundet.")]).strip_edges()
	var lines: Array[String] = []
	for entry in [
			[said.call("dead", "%s ist fort.", "%s sind fort."), count["dead"],
				["Und noch einer.", "%s andere auch.", "Ein Gast ist fort.", "%s Gäste sind fort."], true],
			[enemies, count["enemies"], ["Noch einer redet nicht mehr mit mir.", "%s andere reden nicht mehr mit mir.",
				"Ein Gast redet nicht mehr mit mir.", "%s Gäste reden nicht mehr mit mir."], true],
			[friends, count["friends"], ["Mit noch einem bin ich befreundet.", "Mit %s anderen bin ich befreundet.",
				"Mit einem Gast bin ich befreundet.", "Mit %s Gästen bin ich befreundet."], false]]:
		var text: String = entry[0]
		var n: int = entry[1]
		if n > 0:
			var form: String = entry[2][(0 if text != "" else 2) + (0 if n == 1 else 1)]
			text += (" " if text != "" else "") + (form % _number(n, entry[3]) if n > 1 else form)
		if text != "":
			lines.append(text)
	return lines


## „Edna“, „Edna und Bruno“, „Edna, Bruno und Mila“.
static func _names(names: Array) -> String:
	if names.size() == 1:
		return names[0]
	return ", ".join(names.slice(0, names.size() - 1)) + " und " + names[-1]


## Zahl als Wort bis zwölf („neun“, am Satzanfang „Neun“), darüber in Ziffern.
static func _number(n: int, capital: bool = false) -> String:
	var word: String = NUMBER_WORDS[n] if n < NUMBER_WORDS.size() else str(n)
	return word.capitalize() if capital else word


# --- Zustand einsammeln ------------------------------------------------------------------

func collect() -> Dictionary:
	var tree := get_tree()
	var p := Game.player
	var stand := p.stand_position()   # im Sitzen: wo er aufstünde (geladen wird stehend)
	if p.hiding:   # im Versteck oder Bett (nur beim Zwischenstand, 8.10): davor
		stand = p.hiding.exit_point.global_position
	var data := {
		"version": VERSION,
		"world": world,
		"saved_at": int(Time.get_unix_time_from_system()),
		"playtime": Game.director.elapsed,
		"money": Game.money,
		"current_slot": Game.current_slot,
		"visited": visited.duplicate(),
		"player": {
			"pos": _v(stand if stand != Vector3.INF else p.global_position), "yaw": p.rotation.y, "pitch": p.head.rotation.x,
			"crouch": p.crouching, "shock": p.shock, "injury": p.injury, "bite": p.bite, "bite_heal": p.bite_heal,
			"limp": p.limp,
			"awake_time": p.awake_time, "sure_awake": p.sure_awake, "rested": p.rested,
			"drunk": p.drunk, "hangover": p.hangover, "disguised": p.disguised, "mask": p.mask,
			"coffee": p.coffee, "coffee_low": p.coffee_low, "caffeine": p.caffeine, "tea": p.tea,
			"held": _item_data(p.held) if p.held else null,
			"bag": p.bag.map(_bag_data),
			"compass": p.has_compass, "map_pages": p.map_pages.duplicate(), "keyring": p.keyring.duplicate(),
			"look": p.body.look.duplicate(),
		},
		"items": [],
		"guests": {},
		"social": {},
		"director": {},
	}
	for node in tree.get_nodes_in_group("items"):
		var item := node as Item
		if item.is_held or item.is_queued_for_deletion():
			continue
		data["items"].append(_item_data(item))
	var alive: Array = []
	for guest in Game.social.guests:
		var g: Guest = guest
		var pos := g.stand_point()   # sitzend: der Platz davor – Sitzen wird nicht gespeichert (Spielkonzept 3.1)
		var yaw := g.rotation.y
		if g.hiding:
			pos = g.hiding.exit_point.global_position
			yaw = g.hiding.exit_point.global_rotation.y
		if not g.dead:
			alive.append(g.display_name)
		var stock := {}
		for kind in g.stock:
			stock[str(int(kind))] = int(g.stock[kind])
		data["guests"][g.id] = {
			"pos": _v(pos), "yaw": yaw, "dead": g.dead, "relation": g.relation, "fear": g.fear,
			"money": g.money, "stock": stock, "expected_deco": g.expected_deco,
			"chat_cooldown": g.chat_cooldown, "gift_cooldown": g.gift_cooldown,
			"challenge_cooldown": g.challenge_cooldown, "monster_line": g.monster_line,
			"held": _item_data(g.held) if g.held else null,
			"corpse": g.corpse, "buried": g.buried, "ghost_visits": g.ghost_visits, "seen": g.seen_sights, "experiences": g.experiences,
			"drunk": g.drunk,
			"deeds": g.deeds, "chat_day": g.chat_day, "chats_today": g.chats_today,
			"talk_day": g.talk_day, "talks_today": g.talks_today, "filler_day": g.filler_day, "hostile_day": g.hostile_day,
			"wound": g.wound, "wound_left": g.wound_left, "wound_bed": g.wound_bed, "wound_facts": g.wound_facts,
			"wound_told": g.wound_told, "wound_visited": g.wound_visited,
			"claims": g.claims, "stances": g.stances,
		}
	data["alive"] = alive
	var social := Game.social
	var thefts := {}
	for id in social._thefts:
		thefts[id] = social._time - float(social._thefts[id])   # vor wie vielen Sekunden
	var memorials: Array = []
	for door_front in social._memorial_doors:
		memorials.append(_v(door_front))
	data["social"] = {
		"thefts_ago": thefts, "memorials": memorials, "watched": social._watched.keys(), "chess_watched": social._chess_watched.keys(),
		"darts_watched": social._darts_watched.keys(),
		"party_cooldown": social._party_cooldown, "roster": social.roster_state(),
		"arrival_timer": social._arrival_timer,
		"cat_thefts": social.cat_thefts, "cat_blame": social.cat_blame, "cats_have_cried": social.cats_have_cried,
		"sleep_active": social.sleep_active, "night_seed": social.night_seed,
		"pals": social.pals.save_state(),
		"talk": social.talk.save_state(),
		"requests": social.requests.save_state(),
		"quarrels": social.quarrels.save_state(),
		"deaths": social.deaths.save_state(),
		"access": social.access.save_state(),
	}
	var director := Game.director
	data["director"] = {
		"boldness": director.boldness,
		"satiation": director.satiation, "elapsed": director.elapsed,
		"state": director.save_state(),
	}
	data["traces"] = Game.traces.save_state() if Game.traces else []
	# gelegte Salzlinien: kein fester Welt-Teil (nicht in WORLD_GROUPS), beim Laden neu erzeugt
	data["salt"] = get_tree().get_nodes_in_group("salt_lines").map(func(n: Node) -> Dictionary: return n.save_state())
	data["ghost"] = Game.ghost.save_state() if Game.ghost else {}
	data["shower"] = Game.shower_scare.save_state() if Game.shower_scare else {}
	data["omens"] = _collect_omens()
	if Game.cemetery:
		data["cemetery"] = Game.cemetery.save_state()
	if Game.leviathan_name:
		data["leviathan"] = Game.leviathan_name.save_state()
	data["doll"] = Game.doll.save_state() if Game.doll else {}
	data["contest"] = Game.contest.save_state() if Game.contest else {}
	data["notebook"] = Game.notebook.save_state() if Game.notebook else {}
	data["diary"] = Game.diary.save_state() if Game.diary else {}
	data["pumpkin"] = Game.pumpkin.save_state() if Game.pumpkin else {}
	data["hide_spots"] = _collect_group("hide_spots", func(n: Node) -> Dictionary: return n.save_state())
	data["doors"] = _collect_group("doors", func(n: Node) -> Dictionary:
		return {"open": n.is_open, "locked": n.locked, "broken": n.broken, "by_player": n.broken_by_player,
			"broken_day": n.broken_day})
	# Maskenhaken in Zimmer 13 (5.19): je Maske, ob sie hängt – nach der Maske, nicht nach der Reihenfolge
	var hooks := {}
	for hook: MaskHook in get_tree().get_nodes_in_group("mask_hooks"):
		hooks[hook.mask_id] = hook.hanging
	data["mask_hooks"] = hooks
	data["chests"] = _collect_group("chests", func(n: Node) -> Dictionary:
		return {"open": n.is_open})
	data["plants"] = _collect_group("pumpkin_plants", func(n: Node) -> Dictionary:
		return {"stage": n.stage, "timer": n._timer})
	data["resources"] = _collect_group("resource_spots", func(n: Node) -> Dictionary:
		return {"uses": n.uses, "timer": n._timer, "guest_day": n.guest_day, "guest_taken": n.guest_taken,
			"refill_day": n.refill_day})
	data["lamps"] = _collect_group("lamp_fixtures", func(n: Node) -> Dictionary: return n.save_state())
	data["fixed_candles"] = _collect_group("fixed_candles", func(n: Node) -> Dictionary: return n.save_state())
	data["switches"] = _collect_group("light_switches", func(n: Node) -> Dictionary: return n.save_state())
	data["windows"] = _collect_group("windows", func(n: Node) -> Dictionary: return n.save_state())
	data["phones"] = _collect_group("phones", func(n: Node) -> Dictionary: return n.save_state())
	data["dressers"] = _collect_group("dressers", func(n: Node) -> Dictionary: return n.save_state())
	data["locker_banks"] = _collect_group("locker_banks", func(n: Node) -> Dictionary: return n.save_state())
	data["arcades"] = _collect_group("arcades", func(n: Node) -> Dictionary: return n.save_state())
	data["cats"] = _collect_group("cats", func(n: Node) -> Dictionary: return n.save_state())
	data["elevators"] = _collect_group("elevators", func(n: Node) -> Dictionary: return n.save_state())
	return data


func _collect_group(group: String, fn: Callable) -> Array:
	var list: Array = []
	for node in get_tree().get_nodes_in_group(group):
		list.append(fn.call(node))
	return list


func _item_data(item: Item) -> Dictionary:
	var e := item.global_rotation
	var d := {
		"kind": int(item.kind), "extra": item.create_extra(), "pos": _v(item.global_position),
		"rot": _v(e), "owner": item.owner_id, "lit": item.lit, "hung": item.hung,
	}
	if item.got_from != "":
		d["got"] = item.got_from
	if item.has_meta("taken_from"):   # solange die Deko fehlt, zählt der Diebstahl als Ursache (6.18, 2)
		d["taken"] = String(item.get_meta("taken_from"))
	if item.has_meta("memorial"):   # Gedenkkerze eines Freundes (6.12)
		d["memorial"] = String(item.get_meta("memorial"))
	if item.has_meta("cat_took"):   # von einer Katze verschleppt – der Besitzer wünscht es sich zurück (6.18, 3)
		d["cat_took"] = String(item.get_meta("cat_took"))
	return d


## Gegenstand in der Tasche: ohne Lage – er liegt beim Spieler
func _bag_data(item: Item) -> Dictionary:
	var d := _item_data(item)
	for key in ["pos", "rot", "hung"]:
		d.erase(key)
	return d


# --- Zustand wiederherstellen ------------------------------------------------------------

## Wird von main.gd aufgerufen, nachdem das Hotel frisch aufgebaut ist.
func apply(data: Dictionary) -> void:
	var tree := get_tree()
	var parent := Game.player.get_parent()   # dort liegen die Gegenstände (nicht `world`, das ist der Fingerabdruck)
	visited = (data.get("visited", []) as Array).duplicate()
	reset_pending()
	Game.money = int(data.get("money", 5))
	Game.current_slot = int(data.get("current_slot", Game.current_slot))
	# Laufendes Schmücken, Deko-Suche, Suppenessen und Kaffeekochen werden nicht gespeichert – und die Gäste gleich neu gebaut
	Game.social.decorating.reset()
	Game.social.search.reset()
	Game.social.pranks.reset()
	Game.social.tidying.reset()
	Game.social.candles.reset()
	Game.social.bath.reset()
	Game.social.break_in.reset()
	Game.social.hauntings.reset()
	if Game.kitchen:
		Game.kitchen.reset()
	if Game.coffee:
		Game.coffee.reset()
	if Game.kettle:
		Game.kettle.reset()
	# Zuerst die zufällig erzeugten Gäste – alles Weitere bezieht sich auf ihre IDs
	Game.social.restore_roster((data.get("social", {}) as Dictionary).get("roster", []))

	# Welt
	_apply_group("doors", data.get("doors", []), func(n: Node, d: Dictionary) -> void:
		n.locked = bool(d["locked"])
		n.broken = false
		if bool(d["open"]) != n.is_open:
			n.set_open(bool(d["open"]), true, true)
		n.broken = bool(d.get("broken", false))
		n.broken_by_player = bool(d.get("by_player", false))
		n.broken_day = int(d.get("broken_day", 0)))
	_apply_group("chests", data.get("chests", []), func(n: Node, d: Dictionary) -> void:
		n.set_open(bool(d["open"]), true))
	_apply_group("pumpkin_plants", data.get("plants", []), func(n: Node, d: Dictionary) -> void:
		n.stage = int(d["stage"])
		n._timer = float(d["timer"])
		n._update_visual())
	_apply_group("resource_spots", data.get("resources", []), func(n: Node, d: Dictionary) -> void:
		n.uses = int(d["uses"])
		n._timer = float(d["timer"])
		n.guest_day = int(d.get("guest_day", 0))
		n.guest_taken = int(d.get("guest_taken", maxi(0, n.max_uses - n.uses)))   # vor 68: alles Fehlende
		n.refill_day = int(d.get("refill_day", 0))
		n._update_visual())
	_apply_group("light_switches", data.get("switches", []), func(n: Node, d: Dictionary) -> void: n.load_state(d))
	_apply_group("lamp_fixtures", data.get("lamps", []), func(n: Node, d: Dictionary) -> void: n.load_state(d))
	if data.has("fixed_candles"):   # vor 45 brannten sie immer
		_apply_group("fixed_candles", data["fixed_candles"], func(n: Node, d: Dictionary) -> void: n.load_state(d))
	_apply_group("windows", data.get("windows", []), func(n: Node, d: Dictionary) -> void: n.load_state(d))
	_apply_group("hide_spots", data.get("hide_spots", []), func(n: Node, d: Dictionary) -> void: n.load_state(d))
	var hooks: Dictionary = data.get("mask_hooks", {})
	for hook: MaskHook in get_tree().get_nodes_in_group("mask_hooks"):
		if hooks.has(hook.mask_id):
			hook.set_hanging(bool(hooks[hook.mask_id]))
	_apply_group("phones", data.get("phones", []), func(n: Node, d: Dictionary) -> void: n.load_state(d))
	_apply_group("dressers", data.get("dressers", []), func(n: Node, d: Dictionary) -> void: n.load_state(d))
	if data.has("locker_banks"):   # ältere Stände: alle Spinde zu
		_apply_group("locker_banks", data["locker_banks"], func(n: Node, d: Dictionary) -> void: n.load_state(d))
	if data.has("arcades"):   # ältere Stände: nur die alten Einträge
		_apply_group("arcades", data["arcades"], func(n: Node, d: Dictionary) -> void: n.load_state(d))
	_apply_group("elevators", data.get("elevators", []), func(n: Node, d: Dictionary) -> void: n.load_state(d))
	if Game.traces:
		Game.traces.load_state(data.get("traces", []))
	for node in tree.get_nodes_in_group("salt_lines"):
		node.free()
	for entry in data.get("salt", []):
		var line := SaltLine.from_state(entry)
		parent.add_child(line)
		line.global_position = _vec(entry["pos"])
		line.global_rotation = Vector3(0, float(entry.get("yaw", 0.0)), 0)
	if Game.ghost:
		Game.ghost.load_state(data.get("ghost", {}))
	if Game.shower_scare:
		Game.shower_scare.load_state(data.get("shower", {}))
	_apply_omens(data.get("omens", {}))
	if Game.cemetery:
		Game.cemetery.load_state(data.get("cemetery", {}))
	if Game.leviathan_name:
		Game.leviathan_name.load_state(data.get("leviathan", {}))

	# Monster-Werte
	var director := Game.director
	var dd: Dictionary = data.get("director", {})
	director.boldness = float(dd.get("boldness", director.boldness))
	director.satiation = float(dd.get("satiation", 0.0))
	director.elapsed = float(dd.get("elapsed", 0.0))
	director.phase = MonsterDirector.Phase.CALM

	# Gäste (vor den Gegenständen: ein toter Gast gibt seine Sachen frei)
	var gd: Dictionary = data.get("guests", {})
	for guest in Game.social.guests:
		var g: Guest = guest
		if not gd.has(g.id):
			continue
		var d: Dictionary = gd[g.id]
		g.global_position = _vec(d["pos"])
		g.rotation.y = float(d["yaw"])
		g.relation = float(d["relation"])
		g.fear = float(d["fear"])
		g.money = int(d["money"])
		g.expected_deco = int(d["expected_deco"])
		g.chat_cooldown = float(d.get("chat_cooldown", 0.0))
		g.gift_cooldown = float(d.get("gift_cooldown", 0.0))
		g.challenge_cooldown = float(d.get("challenge_cooldown", 0.0))
		g.monster_line = int(d.get("monster_line", 0))
		g.ghost_visits = int(d.get("ghost_visits", 0))
		g.drunk = float(d.get("drunk", 0.0))
		g.seen_sights = (d.get("seen", []) as Array).duplicate()
		g.experiences = (d.get("experiences", []) as Array).duplicate(true)
		g.deeds = (d.get("deeds", {}) as Dictionary).duplicate()
		g.chat_day = int(d.get("chat_day", 0))
		g.chats_today = int(d.get("chats_today", 0))
		g.talk_day = int(d.get("talk_day", 0))
		g.talks_today = int(d.get("talks_today", 0))
		g.filler_day = int(d.get("filler_day", 0))
		g.hostile_day = int(d.get("hostile_day", 0))
		g.wound = String(d.get("wound", ""))
		g.wound_left = float(d.get("wound_left", 0.0))
		g.wound_bed = float(d.get("wound_bed", 0.0))
		g.wound_facts = (d.get("wound_facts", {}) as Dictionary).duplicate()
		g.wound_told = int(d.get("wound_told", 0))
		g.wound_visited = bool(d.get("wound_visited", false))
		g.claims = Talk.load_claims(d.get("claims", []))
		g.stances = (d.get("stances", {}) as Dictionary).duplicate(true)
		g._update_wound_marks()
		g.stock = {}
		var stock: Dictionary = d["stock"]
		for key in stock:
			g.stock[int(key)] = int(stock[key])
		g._set_idle(randf_range(1.0, 4.0))
		if bool(d["dead"]):
			g.die("buried" if bool(d.get("buried", false)) else "ghost" if bool(d.get("corpse", false)) else "monster")

	# Gegenstände: alle Start-Gegenstände weg, dann aus dem Spielstand neu erzeugen
	Game.player.held = null
	for guest in Game.social.guests:
		guest.held = null
	for node in tree.get_nodes_in_group("items"):
		var item := node as Item
		item.remove_from_group("items")
		item.queue_free()
	for entry in data.get("items", []):
		var item := _make_item(entry)
		parent.add_child(item)
		item.global_position = _vec(entry["pos"])
		item.global_rotation = _vec(entry["rot"])
		if bool(entry.get("hung", false)):
			item.restore_hung()
	if bool(data.get("table_loaded", false)) and Game.dice and Game.dice.table:   # vor 61: am Tisch statt im Becher
		Game.dice.table.loaded = true
	for guest in Game.social.guests:
		var g: Guest = guest
		var held = gd.get(g.id, {}).get("held")
		if held != null and not g.dead:
			g._take_into_hand(_make_item(held))

	# Katzen (nach den Gästen: Lieblingsgast; nach den Gegenständen: ihre Beute im Maul)
	_apply_group("cats", data.get("cats", []), func(n: Node, d: Dictionary) -> void: n.load_state(d))

	# Spieler
	var pd: Dictionary = data["player"]
	var p := Game.player
	p.leave_seat(true)
	p.set_look(pd.get("look", PlayerBody.default_look()))
	p.global_position = _vec(pd["pos"])
	p.rotation.y = float(pd["yaw"])
	p.head.rotation.x = float(pd["pitch"])
	p.set_crouching(bool(pd.get("crouch", false)))
	p.shock = float(pd.get("shock", 0.0))
	p.awake_time = float(pd.get("awake_time", float(pd.get("nights_awake", 0.0)) * Calendar.DAY_SECONDS))
	p.sure_awake = float(pd.get("sure_awake", p.sure_awake))
	p.rested = float(pd.get("rested", 0.0))
	p.injury = float(pd.get("injury", 0.0))
	p.bite = float(pd.get("bite", 0.0))
	p.bite_heal = float(pd.get("bite_heal", 0.0))
	p.limp = float(pd.get("limp", 0.0))
	p.drunk = float(pd.get("drunk", 0.0))
	p.hangover = float(pd.get("hangover", 0.0))
	p.coffee = float(pd.get("coffee", 0.0))
	p.coffee_low = float(pd.get("coffee_low", 0.0))
	p.caffeine = float(pd.get("caffeine", 0.0))
	p.tea = float(pd.get("tea", 0.0))
	p.set_disguised(bool(pd.get("disguised", false)))
	p.set_mask(String(pd.get("mask", "")))
	p.set_pockets(bool(pd.get("compass", false)), pd.get("map_pages", []), pd.get("keyring", []))
	if pd.get("held") != null:
		var held_item := _make_item(pd["held"])
		held_item.owner_id = "player"
		parent.add_child(held_item)
		p.try_pick_up(held_item)
	var bag: Array[Item] = []
	for entry in pd.get("bag", []):
		bag.append(_make_item(entry))
	p.set_bag(bag)

	# Soziales
	var sd: Dictionary = data.get("social", {})
	var social := Game.social
	social._thefts = {}
	var thefts: Dictionary = sd.get("thefts_ago", {})
	for id in thefts:
		social._thefts[id] = social._time - float(thefts[id])
	social._memorial_doors.clear()
	for m in sd.get("memorials", []):
		social._memorial_doors.append(_vec(m))
	social._watched = {}
	for id in sd.get("watched", []):
		social._watched[id] = true
	social._chess_watched = {}
	for id in sd.get("chess_watched", []):
		social._chess_watched[id] = true
	social._darts_watched = {}
	for id in sd.get("darts_watched", []):
		social._darts_watched[id] = true
	social._party_cooldown = float(sd.get("party_cooldown", 150.0))
	social.cat_thefts = (sd.get("cat_thefts", {}) as Dictionary).duplicate()
	social.cat_blame = (sd.get("cat_blame", {}) as Dictionary).duplicate()
	social.cats_have_cried = bool(sd.get("cats_have_cried", false))
	social.sleep_active = bool(sd.get("sleep_active", false))
	social.night_seed = int(sd.get("night_seed", social.night_seed))
	social._arrival_timer = float(sd.get("arrival_timer", -1.0))
	social._forgive_day = -1   # Vergebung zählt ab dem geladenen Tag (6.18, 5)
	social.pals.load_state(sd.get("pals", {}))
	social.talk.load_state(sd.get("talk", {}))
	social.requests.load_state(sd.get("requests", {}))
	social.quarrels.load_state(sd.get("quarrels", {}))
	social.deaths.load_state(sd.get("deaths", {}))
	social.access.load_state(sd.get("access", {}))
	if Game.doll:
		Game.doll.load_state(data.get("doll", {}))
	if Game.pumpkin:
		Game.pumpkin.load_state(data.get("pumpkin", {}))
	# Monster zuletzt: ggf. wieder unterwegs an seiner gespeicherten Stelle
	director.load_state(dd.get("state", {}))
	if Game.contest:   # nach dem Director (erster Angriff schon gewesen?) und der Puppe
		Game.contest.load_state(data.get("contest", {}))
	if Game.notebook:   # nach dem Wettbewerb (Brief gelesen?)
		Game.notebook.load_state(data.get("notebook", {}), Game.contest != null and Game.contest.letter_read)
	if Game.diary:
		Game.diary.load_state(data.get("diary", {}))
	last_save_msec = Time.get_ticks_msec()


func _apply_group(group: String, list: Array, fn: Callable) -> void:
	var nodes := get_tree().get_nodes_in_group(group)
	if nodes.size() != list.size():
		push_warning("Spielstand passt nicht zum Hotel (%s: %d statt %d) – wird übersprungen." % [group, list.size(), nodes.size()])
		return
	for i in nodes.size():
		fn.call(nodes[i], list[i])


func _make_item(entry: Dictionary) -> Item:
	var item := Item.create(int(entry["kind"]) as Item.Kind, String(entry.get("extra", "")))
	item.owner_id = String(entry.get("owner", ""))
	item.got_from = String(entry.get("got", ""))
	if entry.has("taken"):
		item.set_meta("taken_from", String(entry["taken"]))
	if entry.has("memorial"):
		item.set_meta("memorial", String(entry["memorial"]))
	if entry.has("cat_took"):
		item.set_meta("cat_took", String(entry["cat_took"]))
	if item.has_wick():   # brennt oder nicht (Spielkonzept 5.12); in Kürbis und Totenkopf sagt der Zusatz, ob eine Kerze steckt
		if bool(entry.get("lit", false)) and not item.lit:
			item.light_up(false)
		elif not bool(entry.get("lit", false)) and item.lit:
			item._extinguish()
	return item


# --- Dateien -------------------------------------------------------------------------

func _write(slot: int, data: Dictionary) -> bool:
	DirAccess.make_dir_recursive_absolute(DIR)
	var path := slot_path(slot)
	var tmp := path + ".tmp"
	var file := FileAccess.open(tmp, FileAccess.WRITE)
	if file == null:
		push_error("Spielstand konnte nicht geschrieben werden: %s" % tmp)
		return false
	file.store_string(JSON.stringify(data, "\t"))
	file.close()
	var dir := DirAccess.open(DIR)
	if dir == null:
		push_error("Spielstand-Ordner nicht erreichbar: %s" % DIR)
		return false
	if dir.file_exists(path.get_file()):
		dir.remove(path.get_file())
	return dir.rename(tmp.get_file(), path.get_file()) == OK


func _read(slot: int) -> Dictionary:
	var path := slot_path(slot)
	if not FileAccess.file_exists(path):
		return {}
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	return parsed


func _v(v: Vector3) -> Array:
	return [v.x, v.y, v.z]


func _vec(a) -> Vector3:
	return Vector3(float(a[0]), float(a[1]), float(a[2]))
