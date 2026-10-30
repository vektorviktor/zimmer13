# Refactoring in kleinen Happen

Stand 28.10.2026, master `17de137` (nach dem Zusammenführen der Nacht-Branches). Nur Analyse, noch nichts geändert.

**Wie die Happen gedacht sind:** Jeder Happen fasst *eine* Datei bzw. *ein* System an und macht *eine* Art von
Änderung (umbenennen, aufteilen, Doppeltes zusammenlegen, Toten Code löschen …). Spielverhalten und Speicherformat
bleiben gleich; kleine Logikfehler aus dem Abschnitt unten dürfen im passenden Happen mit behoben werden, dann aber
im Commit genannt. Prüfen: `bash tests/smoke.sh pruefen`, `bash tests/smoke.sh schnell` und das angegebene Stichwort.
Jeder Happen ein eigener Commit (deutsch, kurz, Stil wie bisher); ändert sich ein System, TECHNIK.md im selben Commit.

Größe: **S** ≈ unter 100 geänderte Zeilen, eine Session locker · **M** ≈ 100–400 Zeilen · **L** wird in Teilhappen
geteilt (steht dann als a/b/c da). Zeilennummern gelten für `17de137` und verschieben sich nach jedem Happen.

## Überblick

- 165 Skripte, ~69 600 Zeilen. Größte: `level_builder.gd` 5112, `guest.gd` 3285, `social.gd` 2739, `main.gd` 2685,
  `item.gd` 2642, `monster_director.gd` 2578, `player.gd` 2220.
- Am häufigsten angefasst seit 20.10.: `main.gd` 64 Commits, `tests/smoke.sh` 56, `level_builder.gd` 47, `social.gd` 41,
  `save_manager.gd` 40, `debug_console.gd` 30, `guest.gd` 29, `item.gd` 28.
- Längste Funktionen: `Main.run_debug` 927 Zeilen, `Item._build` 514, `SynthAudio._shot_sample` 241,
  `SaveManager.apply` 231, `Main._ready` 203, `Guest._physics_process` 180, `LevelBuilder._furniture` 168,
  `LevelBuilder._common_rooms` 157, `SaveManager.collect` 130.
- Der Code ist insgesamt sauber: kein auskommentierter Code, keine TODO/FIXME, nur 36 untypisierte `var x = …`,
  fast alle `print` hinter `Game.tracing`. Die Baustellen sind Größe, Wiederholung und halb-private Schnittstellen.

## Happen (nach Nutzen sortiert)

### 1. main.gd: Hilfsfunktion für Debug-Argumente
- **Datei:** `scripts/main.gd` (`run_debug` und die `_debug_*`-Helfer)
- **Was:** Eine Funktion `_arg_value(arg, "--name") -> String` (bzw. `_arg_parts(arg, "--name", default) -> PackedStringArray`)
  ersetzt das Muster `arg == "--x" or arg.begins_with("--x=")` + `arg.substr(17).split(",")`. 99 Stellen mit
  handgezählten `substr(N)`-Versätzen (z. B. `--schluesseldieb=` → 17, `--brett` → 8). Die Literale `"--name"` müssen
  im Code stehen bleiben – `tests/checks.py` (`check_params`) sucht genau nach ihnen.
- **Warum:** meistgeänderte Datei; jeder neue Befehl kopiert das Muster, ein falscher Versatz fällt nur beim Ausprobieren auf.
- **Risiko:** niedrig (mechanisch; eine Prüfung im Python-Einzeiler hat gezeigt, dass alle heutigen Versätze stimmen).
- **Stichwort:** `pruefen`, `schnell`, danach stichprobenhaft `gaeste`, `speichern`.
- **Größe:** M – geteilt: **1a** Helfer + Zweige bis `--relation` (Z. 822–1150), **1b** der Rest.
- **Stand:** **1a erledigt** (28.10., c0616a0): `_is_arg(arg, "--x")`, `_arg_value(arg, "--x", default)` (leerer Wert =
  default), `_arg_parts(arg, "--x", default)` stehen vor `run_debug`; 29 Zweige umgestellt, kein Versatz war falsch.
  **1b erledigt** (28.10., d1c4423): die übrigen 69 Zweige ab `--einbruch` und `_debug_all`; kein Versatz war falsch,
  Indexfehler in `_debug_all` behoben. **Happen 1 damit erledigt.** `_debug_omens` und `_debug_all` lesen den Befehl
  allgemein (ohne gezählte Versätze) und bleiben so.

### 2. main.gd: `run_debug` in Themen-Funktionen zerlegen
- **Datei:** `scripts/main.gd`
- **Was:** Die 147 `if/elif`-Zweige von `run_debug` (Z. 822–1748) in Gruppen aufteilen, die jeweils `bool` zurückgeben:
  `_debug_world(arg)` (Aufzug, Tür, Dachboden, Pool, Zeit/Tag/Uhr), `_debug_player(arg)` (Tasche, Taschenlampe,
  Wurf, Fall, Sitzen, Werkzeug), `_debug_guests(arg)` (Gespräch, Beziehung, Kill, Wunde, Bitten …),
  `_debug_monsters(arg)` (Modus, Plan, Kürbismann, Lakengeist), `_debug_story(arg)` (Brett, Register, Zimmer 18,
  Siegerehrung, Grinch). `run_debug` probiert sie der Reihe nach. Die Reihenfolge der Präfixprüfungen innerhalb
  einer Gruppe beibehalten (z. B. `--bag-menu` vor `--bag`).
- **Warum:** 927 Zeilen in einer Funktion; Merge-Konflikte bei jedem parallelen Branch landen genau hier.
- **Risiko:** mittel (Reihenfolge der `begins_with`-Prüfungen ist Logik!).
- **Stichwort:** `pruefen`, `schnell`, je Gruppe deren Stichworte (`gaeste`, `monster`, `spieler`, `wettbewerb`, `register`).
- **Größe:** L – **2a** Welt + Spieler, **2b** Gäste, **2c** Monster + Geschichte. Nach Happen 1.

### 3. main.gd: Debug-Code in eigene Datei
- **Dateien:** `scripts/main.gd` → neu `scripts/debug/debug_commands.gd` (`DebugCommands`, Kind von Main), `tests/checks.py`
- **Was:** `run_debug`, alle `_debug_*`, `_save_test`/`_settle`/`_same`, `_nav_check*`, `_kill_options`, `_guest`,
  `_put_in_front`, `_face_toward` (Z. 809–2685) umziehen. Kopfkommentar mit der Parameterliste zieht mit.
  `checks.py` (`check_params`, Z. 196 ff.) muss dann die neue Datei statt `main.gd` lesen; `DebugConsole` ruft
  `Game.debug.run(arg)` statt `current_scene.run_debug`. Selbe Stelle: `requests.gd:487` und `talk.gd:979` rufen
  `get_tree().current_scene.call("_debug_talk", …)` – danach über die neue Referenz.
- **Warum:** `main.gd` baut das Spiel zusammen und ist zugleich 1900 Zeilen Debug – zwei Verantwortlichkeiten.
- **Risiko:** mittel (Selbstprüfung, Konsole, README-Verweise).
- **Stichwort:** `pruefen`, `schnell`, `speichern` (Savetest), `navmesh`.
- **Größe:** M. Erst nach 1 und 2.

### 4. `Game.now()` statt 27 Kopien
- **Dateien:** `scripts/autoload/game.gd` + alle Fundstellen
- **Was:** `func now() -> float: return director.elapsed if director else 0.0` in `Game`. Ersetzt 27× den Ausdruck
  `Game.director.elapsed if Game.director else 0.0` und die fünf gleichen `_now()` in `bath_use.gd:33`,
  `room_access.gd:89`, `talk.gd:136`, `hotel_register.gd:124`, `notebook.gd:170`.
- **Warum:** Spielzeit-Regel aus CLAUDE.md an einer Stelle; neue Systeme greifen nicht mehr zur Systemzeit.
- **Risiko:** niedrig. **Stichwort:** `schnell`, `gaeste`, `zimmerzugang`. **Größe:** S.

### 5. SaveManager: `save_state`/`load_state` für die letzten Inline-Gruppen
- **Dateien:** `scripts/autoload/save_manager.gd`, `scripts/world/door.gd`, `chest.gd`, `pumpkin_plant.gd`, `resource_spot.gd`
- **Was:** Türen, Truhen, Kürbispflanzen und Ressourcenstellen werden in `collect` (Z. 659–673) und `apply` (Z. 737–757)
  noch per Lambda gelesen/geschrieben, inklusive privater Felder (`n._timer`, `n._update_visual()`). Wie bei Lampen,
  Fenstern, Telefonen usw. eigene `save_state()`/`load_state(d)` in die Klassen, **mit genau denselben Schlüsseln**
  (`open`, `locked`, `broken`, `by_player`, `broken_day`, `stage`, `timer`, `uses`, `guest_day`, `refill_day`).
- **Warum:** einheitlich, kein Zugriff auf Privates von außen; danach ist Happen 6 trivial.
- **Risiko:** mittel (Speicherformat darf sich nicht ändern – Savetest vergleicht). Keine `VERSION`-Erhöhung nötig.
- **Stichwort:** `speichern`, `kuerbis`, `knappheit`. **Größe:** S–M.

### 6. SaveManager: Welt-Gruppen als eine Tabelle
- **Datei:** `scripts/autoload/save_manager.gd`
- **Was:** Eine Konstante `WORLD_SAVE := [["doors", "doors"], ["pumpkin_plants", "plants"], ["resource_spots", "resources"], …]`
  (Gruppe → Schlüssel im Spielstand). `collect`/`apply` laufen darüber; `WORLD_GROUPS` daraus ableiten oder daneben
  prüfen, dass beide gleich sind. Sonderfälle bleiben ausgeschrieben: `fixed_candles` (nur wenn vorhanden),
  `mask_hooks` (nach Masken-ID), `cats` (nach den Gästen).
- **Warum:** Heute muss man eine neue Gruppe an drei Stellen eintragen (CLAUDE.md erinnert extra daran).
- **Risiko:** mittel (Reihenfolge in `apply` beachten: Katzen nach Gästen und Gegenständen).
- **Stichwort:** `speichern`, `autosave`, `welt`. **Größe:** S. Nach Happen 5.

### 7. SaveManager: `apply` und `collect` in Abschnitte teilen
- **Datei:** `scripts/autoload/save_manager.gd`
- **Was:** `apply` (231 Zeilen) hat schon Kommentar-Abschnitte – daraus `_apply_world`, `_apply_monster`, `_apply_guests`,
  `_apply_items`, `_apply_cats`, `_apply_player`, `_apply_social`, `_apply_monster_last` machen, Reihenfolge
  unverändert. `collect` (130) spiegelbildlich. Die Reset-Liste am Anfang (Z. 718–731) wird `Game.social.reset_transient()`
  (siehe Happen 9).
- **Warum:** zweitgrößte Funktion in einer viel geänderten Datei; Reihenfolge-Abhängigkeiten werden an den Namen sichtbar.
- **Risiko:** niedrig–mittel. **Stichwort:** `speichern`, `autosave`, `tod`. **Größe:** M.

### 8. Guest: Angstschwellen als Konstanten
- **Dateien:** `scripts/guests/guest.gd` + 14 Dateien mit `fear < 60.0` / `fear >= 60.0` (30 Stellen, u. a. `dialog_ui.gd` 4×,
  `social.gd` 3×, `talk.gd`, `room_access.gd`, `leviathan_name.gd`, `pals.gd`, `grinch.gd`, `candle_care.gd`, `table_match.gd`)
- **Was:** `const SCARED := 60.0` in `Guest` (Name nach Bedeutung, Doc-Kommentar mit Spielkonzept-Verweis), alle Stellen
  darauf umstellen. Werte nicht vereinheitlichen: `DecoPlan.PANIC := 80.0` und `PhoneCalls.PANIC_FROM := 60.0` meinen
  Eigenes – nur prüfen, ob `PANIC_FROM` auf `Guest.SCARED` verweisen soll. Auch `fear - delta * 0.4` in
  `Guest._physics_process` als `FEAR_DECAY`.
- **Warum:** Magic Number in 15 Dateien; Balancing heute nur per Suchen/Ersetzen.
- **Risiko:** niedrig. **Stichwort:** `gaeste`, `gespraech`, `telefon`. **Größe:** S.

### 9. Social: Teilsysteme einheitlich anlegen und zurücksetzen
- **Dateien:** `scripts/guests/social.gd`, `scripts/autoload/save_manager.gd`
- **Was:** In `Social.setup` (Z. 360–418) wiederholt sich 12× `x = X.new(); x.name = "…"; add_child(x)` → Helfer
  `_part(node, name) -> Node`. Neue Funktion `reset_transient()` ruft `reset()` von decorating, search, pranks, tidying,
  candles, bath, break_in; `SaveManager.apply` ruft nur noch sie (dort heute 7 Einzelzeilen). Außerdem `_world` öffentlich
  als `world`: wird von außen gelesen in `pranks.gd` (3×), `grinch.gd` (3×), `tidying.gd`, `candle_care.gd`, `break_in.gd`.
- **Warum:** Wer ein Teilsystem ergänzt, vergisst heute leicht den Reset beim Laden.
- **Risiko:** niedrig. **Stichwort:** `gaeste`, `speichern`, `streiche`. **Größe:** S.

### 10. Item: Grundwerte je Art als Tabelle
- **Datei:** `scripts/world/item.gd` (`_build`, Z. 1168–1681)
- **Was:** Viele Zweige des `match kind` setzen nur `display_name`, `deco_strength`, `mass`, `size`, `is_large` und rufen
  einen `_build_x()` auf (Fledermausgirlande, Spinne, Totenkopf …). Diese Werte in eine Konstante `KIND_STATS := {Kind.SPIDER: {…}}`
  ziehen, `_build` setzt sie vorweg; in den Zweigen bleibt nur das Besondere. `Item.Kind` selbst bleibt unangetastet.
  Dabei `extra.split(",")` (10× in der Datei, mehrfach im selben Zweig) einmal am Anfang als `flags` berechnen.
- **Warum:** 514-Zeilen-Funktion, jede neue Gegenstandsart wird hier angebaut (zuletzt Ei).
- **Risiko:** niedrig–mittel (Massen/Größen beeinflussen Physik – genau abschreiben).
- **Stichwort:** `schnell`, `speichern`, `deko`, `kuerbis`, `eier`. **Größe:** M.

### 11. Item: Modellbau in eigene Funktionen bzw. Datei
- **Dateien:** `scripts/world/item.gd` → neu `scripts/world/item_models.gd` (`ItemModels`, statisch)
- **Was:** Die langen Inline-Modelle in `_build` (Besen, Lichterkette, Kürbisse, gebratener Kürbis, Kerzen …) erst in
  `_build_<art>()` auslagern, dann zusammen mit `_build_sheet_ghost`, `_build_bats`, `_build_spider`, `_build_skull`,
  `_build_strand`, `build_cup`, `_build_compass`, `_build_map`, `build_egg` (Z. 2245–2470, 1890) als statische
  Funktionen `ItemModels.x(item)` in eine eigene Datei. Felder wie `_swing`, `_coil` bleiben am Item.
- **Warum:** `item.gd` mischt Regeln (Tasche, Flammen, Faulen, Werfen) mit Geometrie.
- **Risiko:** niedrig (reine Optik; kurz ansehen). **Stichwort:** `schnell`, `deko`, `kerzen`, `eier`.
- **Größe:** L – **11a** Inline-Zweige → `_build_<art>`, **11b** Umzug in `item_models.gd`.

### 12. Item: Zerbrechen, Brei und Spritzer auslagern
- **Dateien:** `scripts/world/item.gd` → neu `scripts/world/item_breakage.gd`
- **Was:** `_break`, `_throw_hit`, `_sweep`, `_splash_wall`, `_splat_egg`, `_shatter_candle`, `_spill_coffee`,
  `_shatter_bulb`, `burst`, `mush_*`, `_take_portion`, `split_handful`, `_splash_chunks`, `_spray`, `_fling_pieces`,
  `_settle_mush`, `_lay_mush`, `_lay_streak`, `_wash_mush`, `_finish_spreading` (Z. 1722–2240, ~500 Zeilen) als
  Helfer mit Item-Referenz. Öffentliche Namen am Item bleiben als dünne Weiterleitung, damit Aufrufer unverändert bleiben.
- **Warum:** zweite große Verantwortlichkeit von `item.gd`, zuletzt durch Eier gewachsen.
- **Risiko:** mittel. **Stichwort:** `werfen`, `eier`, `kuerbis`, `streiche`. **Größe:** M–L.

### 13. Social: Minispiele und Herausforderungen auslagern
- **Dateien:** `scripts/guests/social.gd` → neu `scripts/guests/table_games.gd` (`Social.games`)
- **Was:** Abschnitt „Minispiele“ (Z. 1487–1797): `has_watched*`, `on_cheat_caught`, `queue_rematch`, `challenge`,
  `on_challenge_ignored`, `_update_challenges`, `_update_bar_game`, `_update_chess_game`, `_end_chess_game`,
  `_update_dart_game`, `_end_dart_game`, `_end_bar_game`, `_seat_pair`, `_pair_*`, `_release_pair` und `_rematches`.
  Muster wie `Pranks` (Kind von Social). Externe Aufrufer (`Game.social.challenge(…)` usw.) auf `Game.social.games.…`
  umstellen oder Weiterleitungen lassen – eins von beiden, nicht gemischt.
- **Warum:** `social.gd` ist mit 2739 Zeilen das drittgrößte Skript; diese ~310 Zeilen hängen kaum am Rest.
- **Risiko:** mittel. **Stichwort:** `spiele`, `darts`, `gaeste`. **Größe:** M.

### 14. Social: Süßes oder Saures auslagern
- **Dateien:** `scripts/guests/social.gd` → neu `scripts/guests/trick_or_treat.gd`
- **Was:** Abschnitte „Süßes oder Saures“ und „… von Tür zu Tür“ (Z. 2209–2527): `_update_tricks`, `_trick_*`,
  `give_trick_sweet`, `on_sweets_given`, `_treat_done`, `_leaves_at` (heute privat, aber von `pranks.gd` benutzt),
  `_update_rounds`, `start_round`, `_round_*`, `take_room_sweet`, `sleepless_visit`, `_visit_enter`, `debug_trick_at_13`.
- **Warum:** eigenes Spielsystem (6.13), wächst mit jedem Streich.
- **Risiko:** mittel. **Stichwort:** `streiche`, `kinder`, `halloween`, `eier`. **Größe:** M.

### 15. Social: Schlaf, fremdes Bett und Wecken auslagern
- **Dateien:** `scripts/guests/social.gd` → neu `scripts/guests/guest_sleep.gd`
- **Was:** `_update_sleep`, `night_window`, `night_ends_at`, `night_due`, `seconds_to_night`, `_end_sleep`,
  `after_day_skip`, `player_in_bed` (62 Zeilen), `start_sleep`, `debug_sleep`, `all_asleep`, `wake_guest`, `wake_reason`
  (Z. 1208–1486 ohne die Feier-Funktionen). `sleep_active` und `skip_time` mitnehmen (Gruppe `time_skip`!).
- **Warum:** dritter klar abgegrenzter Block; zuletzt zwei Branches gleichzeitig darin.
- **Risiko:** mittel–hoch (viele Aufrufer, `SleepSkip` hängt dran, Zeitsprung). Erst nach 13/14.
- **Stichwort:** `schlaf`, `fremdbett`, `wecken`, `muede`. **Größe:** M.

### 16. Guest: `_physics_process` zerlegen
- **Datei:** `scripts/guests/guest.gd` (Z. 968–1147)
- **Was:** In `_tick_cooldowns(delta)` (die ~15 Abklingzeiten), `_halted_step(delta) -> bool` (erstes `match` mit
  TALKING/HIDING/SLEEP/KNOCK/SHELTER/GHOSTED/STAGGER, `true` = fertig für diesen Frame) und `_moving_step(delta, speed)`
  (zweites `match`) aufteilen. LOD-Teil oben bleibt.
- **Warum:** 180 Zeilen, Herzstück der Gäste, jede neue Zustandsregel landet hier.
- **Risiko:** mittel (frühe `return` genau erhalten). **Stichwort:** `gaeste`, `schnell`, `schlaf`. **Größe:** M.

### 17. Guest: halb-private Schnittstelle öffentlich machen
- **Dateien:** `scripts/guests/guest.gd` + alle Helfer in `scripts/guests/`
- **Was:** Von außen werden private Methoden gerufen: `_set_idle` (51×), `_walk_to` (20×), `_take_into_hand` (14×),
  `_room_point` (10×), `_drop_held` (6×), `_is_home`, `_timer`, `_target`. Umbenennen in `set_idle`, `walk_to`,
  `take_into_hand`, `room_point`, `drop_held` … (je Name ein Durchgang, vorher nach `call("_…")` suchen).
- **Warum:** Die Gäste-Helfer (Pranks, Talk, CandleCare …) brauchen diese API wirklich; der Unterstrich lügt.
- **Risiko:** mittel (GDScript meldet Tippfehler erst zur Laufzeit – `pruefen` + `gaeste` sind Pflicht).
- **Stichwort:** `gaeste`, `streiche`, `kerzen`, `bitten`. **Größe:** M – **17a** `_set_idle` + `_walk_to`, **17b** der Rest.

### 18. Private Zugriffe zwischen Systemen beheben
- **Dateien:** `deco_search.gd`, `requests.gd`, `monster.gd`, `main.gd`, `candle_care.gd`
- **Was:** `Game.social.decorating._reachable/_progress/_available` (deco_search), `Game.dialog._text` (requests),
  `Game.director._mode_left` (monster.gd), `g._switch` (candle_care.gd:85), aus main.gd `Game.director._make_plan`,
  `Game.social.pals._scan`, `Game.social._knock_cooldown`. Jeweils öffentliche Funktion oder Eigenschaft anbieten.
- **Warum:** Regel „über die Referenzen in Game“ ist eingehalten, aber über die Hintertür.
- **Risiko:** niedrig. **Stichwort:** `deko`, `bitten`, `monster`, `kerzen`. **Größe:** S.

### 19. LevelBuilder: Dachgeschoss in eigene Datei
- **Dateien:** `scripts/level/level_builder.gd` → neu `scripts/level/attic_builder.gd`
- **Was:** `_attic_floor`, `_attic_openings`, `_attic_eaves`, `_attic_ceiling`, `_eave_strip`, `_attic_surfaces`,
  `_attic_slopes`, `_roof_window`, `_attic_gable`, `_attic_beams`, `_attic_markers`, `_attic_haze`, `_attic_stair`
  (Z. 3736–4246, ~500 Zeilen) samt ihren Konstanten. Vorbild `GrandStair` / `LightRooms` (statisch bzw. RefCounted mit
  Builder-Referenz).
- **Warum:** 5112 Zeilen, 197 Funktionen; das Dach wird noch umgebaut (Erinnerung „Dach später“).
- **Risiko:** mittel (NavMesh, Lichtbereiche). **Stichwort:** `dachboden`, `level`, `navmesh`, `licht`. **Größe:** M.

### 20. LevelBuilder: Garten und Keller-Räume auslagern
- **Dateien:** `scripts/level/level_builder.gd` → neu `garden_builder.gd`, `cellar_rooms.gd`
- **Was:** **20a** Garten: `_gardens`, `_hedge_arch`, `_planter`, `_garden_beds`, `_tree`, `_falling_leaves`,
  `_leaf_texture`, `_lantern` (Z. 3533–3735). **20b** Keller: `_boiler_room`, `_boiler_pipes`, `_north_pipe_x`,
  `_laundry_room` (Z. 4373–4506).
- **Risiko:** mittel. **Stichwort:** `level`, `navmesh`, `tiere` (Ratten/Kesselkatze), `friedhof`. **Größe:** je M.

### 21. LevelBuilder: die drei Riesenfunktionen teilen
- **Datei:** `scripts/level/level_builder.gd`
- **Was:** `_furniture` (168 Z., ab 1941), `_common_rooms` (157, ab 3281), `_fittings` (104, ab 2402) je Objekt- bzw.
  Raumart in Unterfunktionen (`_furniture_beds`, `_furniture_tables` …; `_party_room`, `_bar_room`, `_kitchen` …).
- **Risiko:** niedrig–mittel (Reihenfolge der Zufallsaufrufe beim Bau beibehalten, sonst ändert sich der Fingerabdruck).
- **Stichwort:** `level`, `welt`, `navmesh`. **Größe:** L – **21a** `_furniture`, **21b** `_common_rooms`, **21c** `_fittings`.

### 22. Toten Code entfernen
- **Dateien:** mehrere
- **Was:** Nirgends aufgerufen (auch nicht als String, auch nicht in `tests/`/`tools/`): `BathUse.in_bath` (bath_use.gd:52),
  `Guest.is_orphan` (guest.gd:590), `LeviathanName.is_named` (leviathan_name.gd:173), `Social.party_age` (social.gd:1136),
  `DartBoard.board_to_world` (dart_board.gd:112), `MonsterDirector.wants_victim` (:1344) und `_day_lerp` (:1349),
  `PocketMap.bookmark` (pocket_map.gd:181), `JuryDoll.is_judging` (jury_doll.gd:143), `Spiders.face_active` (spiders.gd:536).
  Außerdem `GuestRequests.reset` (requests.gd:463), das nur `load_state({})` aufruft und nie benutzt wird.
- **Risiko:** niedrig (vorher noch einmal greppen – Branches könnten sie gerade nutzen). **Stichwort:** `pruefen`, `schnell`.
- **Größe:** S.

### 23. Gemeinsame Helfer für Tiere und Läufer
- **Dateien:** `rats.gd`, `spiders.gd`, `boiler_cat.gd`, `hotel_cat.gd`, `monster.gd`, `guest.gd`, `nav_walker.gd`, `scripts/util/`
- **Was:** **23a** `_floor_at(p)` ist in `rats.gd:156`, `spiders.gd:254`, `boiler_cat.gd:335` wortgleich (Strahl nach
  unten, Ebene 1) → eine statische Funktion in `scripts/util/` (z. B. `Senses.floor_below(world, p)`). **23b** `_turn(bone,
  axis, angle)` (Knochen relativ zur Elternrotation drehen) in `hotel_cat.gd:955`, `monster.gd:949`, `boiler_cat.gd:305`
  → `BoneKit.turn(skeleton, bones, …)`; `guest_body.gd` und `jury_doll.gd` rechnen anders und bleiben. **23c** `_face`
  und `_move_to` in `Guest`, `HotelCat`, `NavWalker` fast gleich (nur Drehrate 5/6 und Ankunftsradius 0,4/0,6/0,7 anders)
  → statische Helfer in `NavWalker` mit diesen Werten als Parameter.
- **Risiko:** niedrig (23a), mittel (23b/c). **Stichwort:** `tiere`, `katzen`, `monster`, `gaeste`. **Größe:** je S.

### 24. main.gd: `_ready` teilen
- **Datei:** `scripts/main.gd` (`_ready`, Z. 348–550, 203 Zeilen)
- **Was:** in `_build_world()`, `_spawn_actors()`, `_spawn_systems()` (die vielen `Game.x = X.new()`), `_build_ui()`
  aufteilen; Reihenfolge exakt beibehalten (Social vor Katzen, NavMesh-Backen …).
- **Risiko:** mittel (Reihenfolge = Abhängigkeiten). **Stichwort:** `schnell`, `speichern`, `navmesh`. **Größe:** M.

### 25. Kleine Typisierungen und Namen
- **Dateien:** v. a. `monster.gd` (6), `candle_care.gd` (5), `player.gd`, `main.gd`, `tidying.gd`, `social.gd`,
  `phone_calls.gd`, `grinch.gd` (je 2)
- **Was:** die 36 `var x = …` typisieren (`:=` oder expliziter Typ). `SaveManager.DIR`/`WORLD_FILE` sind `var` mit
  Konstanten-Namen (zur Laufzeit berechnet) → klein schreiben oder Doc-Kommentar „zur Laufzeit“.
- **Risiko:** niedrig. **Stichwort:** `pruefen`, `schnell`. **Größe:** S.

### 26. Player: Eingaben und Bewegung entflechten (später)
- **Datei:** `scripts/player/player.gd`
- **Was:** `_unhandled_input` (90 Z.) in Gruppen (Bewegung, Hand, Tasche, Menüs) und `_physics_process` (93 Z.) in
  `_move_step`/`_crouch_step`/`_carry_step` teilen.
- **Warum/Wann:** Tastenbelegung ist gerade erst zusammengeführt – erst wenn sie sich gesetzt hat.
- **Risiko:** mittel. **Stichwort:** `spieler`, `tasten`, `werfen`. **Größe:** M.

### 27. MonsterDirector `_update_effects` und SynthAudio `_shot_sample` (niedrige Priorität)
- **Dateien:** `monster_director.gd` (Z. 2436, 101 Z.), `synth_audio.gd` (Z. 341, 241 Z.)
- **Was:** `_update_effects` nach Effekt (Licht, Ton, Nebel …) teilen; `_shot_sample` als `match` auf je eine
  `_shot_<art>()`-Funktion.
- **Risiko:** niedrig. **Stichwort:** `monster`, `modi`, `schnell` (für Ton keins – kurz anhören). **Größe:** je S–M.

## Kleine Logikfehler

- **`scripts/player/player.gd:1496`** – Nach dem Wurf hebt `get_tree().create_timer(0.5)` die Kollisionsausnahme mit dem
  Spieler wieder auf. Ohne `process_always = false` läuft der Zeitgeber auch in der Pause: Pausiert man direkt nach dem
  Wurf, ist die Ausnahme beim Fortsetzen schon weg, während der Gegenstand noch am Körper hängt. Fix:
  `create_timer(0.5, false)`. Alle anderen Zeitgeber ohne `false` sind Debug-Code (geprüft). Passt zu Happen 26 oder einzeln.
- **`scripts/guests/phone_calls.gd` / `SaveManager.apply`** – *zu prüfen:* `PhoneCalls` hat kein `reset()` und wird beim
  Laden im laufenden Spiel (Savetest, `--unterbrechen=laden`, falls das ohne Szenenwechsel lädt) nicht zurückgesetzt. Da
  `restore_roster` die Gäste neu baut, können `_ambient["caller"/"target"]`, `_talk["guest"]` und `_incoming["guest"]`
  auf freigegebene Gäste zeigen. Beim normalen Laden (neue Szene) unkritisch. Fix: `reset()` und in Happen 9 aufnehmen.
- **`scripts/main.gd` `_debug_all` (Z. 2005)** – nur Debug: Stehen „kinder“ oder „hin“ *vor* dem Platz `slot`, verschiebt
  `parts.remove_at` den Index, und `parts[slot] = g.id` überschreibt das falsche Feld. Heute steht „alle“ immer vorn,
  daher nur theoretisch – beim Umbau (Happen 2) mit erledigen. **Erledigt** in 1b (d1c4423).
- **`GuestRequests.reset` (requests.gd:463)** – wird nie aufgerufen; die Bitten werden nur über `load_state` geleert. Kein
  Fehler im Spiel, aber beim Zurücksetzen-Helfer (Happen 9) entscheiden: aufnehmen oder löschen (Happen 22).

## Nicht anfassen

- **Speicherformat:** Schlüssel und Struktur in `collect`/`apply` bleiben, auch bei Happen 5–7. Keine `VERSION`/`MIN_VERSION`-
  Änderung, solange sich am Format nichts ändert. Die Altlast-Zweige („vor 45 brannten sie immer“ u. Ä.) stehen lassen –
  Rückwärtskompatibilität kommt erst spät (Entscheidung 19.10.).
- **`Item.Kind`-Reihenfolge** und **die Zufallsaufrufe in `GuestGenerator.make()`**: nur am Ende erweitern, nie umsortieren
  (`tests/run.tscn`, `save_rules`). Beim Aufteilen von `item.gd` bleibt die Aufzählung, wo sie ist.
- **Reihenfolge der Zufallsaufrufe beim Bau** (`LevelBuilder`, `Social.setup` mit `randf() < 0.25` für Türzettel): beim
  Zerlegen nicht umstellen.
- **`if Game.tracing: print(…)` (282 Stellen):** sieht nach einem Helfer `Game.trace(text)` aus, aber dann würden die
  Format-Strings auch ohne `--trace` in jedem Frame gebaut. Absichtlich so lassen.
- **Debug-Funktionen in den Systemen** (`debug_*` in 22 Dateien): gewollt – das System kennt seinen Zustand am besten;
  nur das Auswerten der Parameter gehört nach main.gd bzw. DebugCommands.
- **Literale `"--name"` in main.gd:** müssen beim Umbau als String im Code stehen bleiben, sonst schlägt
  `tests/checks.py` (Selbstprüfung „Debug-Parameter“) an.
- **`tests/smoke.sh`:** schlank (386 Zeilen, Liste als Heredoc). Der Filter trifft absichtlich auch Teilstrings der Argumente
  (`*"$FILTER"*`). Kein eigener Happen nötig.
- **`guest_body.gd`/`jury_doll.gd` `_turn`:** rechnen bewusst anders (Rest-Pose bzw. ohne Elternkette) – nicht in Happen 23b ziehen.
