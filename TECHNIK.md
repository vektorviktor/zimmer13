# Technisches Handbuch – „Zimmer 13“

Wie der Prototyp gebaut ist: Aufbau, Konventionen, Zusammenspiel der Systeme und Stolperfallen.
Was das Spiel *sein soll*, steht in [SPIELKONZEPT.md](SPIELKONZEPT.md), Bedienung und Debug-Parameter
stehen im [README](README.md). Hier steht nur, was man aus dem Code nicht sofort sieht.

> **Hinweis:** Kapitel 9 im Spielkonzept ist der ursprüngliche Plan. Die Umsetzung weicht an einigen
> Stellen ab (keine Gruppe `saveable`/`save_id`, Helligkeit per Raycast statt `Area3D`-Licht-Zonen,
> keine Autoloads `RelationshipManager`/`DecorationManager` …). Maßgeblich ist dieses Handbuch.

---

## 1. Grundprinzipien

- **Alles entsteht im Code.** Es gibt nur zwei winzige Szenen (`title.tscn`, `main.tscn`), beide
  hängen nur ein Skript an. Hotel, Möbel, Gäste und UI baut `main.gd` bzw. `LevelBuilder` zur Laufzeit.
  Modelle, Texturen (`TexGen`) und Sounds (`SynthAudio`) sind prozedurale Platzhalter.
- **Kein Inventar.** Ein Gegenstand in der Hand (`Player.held` / `Guest.held`), Geld ist der einzige
  abstrakte Besitz (`Game.money`). Gäste haben zusätzlich einen abstrakten Vorrat (`Guest.stock`).
  Darum ist **die Welt der Spielstand** (siehe 7).
- **Spieler und Gäste nutzen dieselben Dinge** (Türen, Verstecke, Lampen, Vorhänge, Gegenstände).
- **Sprache:** Code-Bezeichner englisch, Kommentare, Doc-Kommentare (`##`) und alle Texte deutsch.
  Doc-Kommentare verweisen auf Abschnitte im Spielkonzept, z. B. `(Spielkonzept 4.13)`.
- **Tuning-Werte** stehen als `const` oben im jeweiligen Skript unter `# --- Tuning`, mit `##`-Erklärung.
  Zeitbereiche, die sich über den Oktober verschieben, als `Vector2(1. Oktober, Halloween)`, aufgelöst
  über `MonsterDirector._day_lerp()`.
- **Node-Klassen** werden mit `XYZ.new().setup(...)` erzeugt (`setup` gibt `self` zurück), danach
  `position`/`rotation` setzen und `add_child`. Gegenstände über die Fabrik `Item.create(kind, extra)`.
- **Engine:** Godot 4.7 (Forward+), GDScript mit Typangaben. Interne Auflösung 480×270, hochskaliert.

## 2. Aufbau zur Laufzeit

### Autoloads (`project.godot`)
| Name | Datei | Aufgabe |
|------|-------|---------|
| `Settings` | `scripts/autoload/settings.gd` | Einstellungen, `user://settings.cfg`, Signal `changed` |
| `Game` | `scripts/autoload/game.gd` | Referenzen auf alle Systeme, Geld, Meldungen, Tastenbelegung, Szenenwechsel, Screenshot-Debug |
| `SaveManager` | `scripts/autoload/save_manager.gd` | Speichern/Laden, Autosave, Tagebuchsatz |

### `Game` als Drehscheibe
`main.gd` erzeugt die Systeme und trägt sie in `Game` ein: `player`, `monster`, `director`, `social`,
`traces`, `audio`, `hud`, `dialog`, `dice`, `menus`. Systeme rufen sich **direkt** über diese
Referenzen auf (`Game.director.on_noise(...)`), nicht über Signale. Signale gibt es nur für
UI-nahe Dinge (`Game.message_posted`, `money_changed`, `player_died`, `caption_posted`,
`Settings.changed`, `SaveManager.autosaved`).

- Referenzen können `null` sein (Titelbildschirm, Szenenwechsel) → bei Aufrufen aus Welt-Objekten
  mit `if Game.traces:` / `if Game.social:` absichern.
- `Game.reset()` am Anfang von `main._ready()` leert alles.
- Text für den Spieler: `Game.say(text, dauer)`. Geräusch: `Game.play_sound(kind, volume)` – setzt
  bei Lautstärke ≥ 0,3 auch Untertitel (`Game.SOUND_CAPTIONS`). Sound-Arten stehen in
  `SynthAudio.play_shot` (`scream`, `sting`, `growl`, `gasp`, `bang`, `blip`, `creak`, `thud`, `knock`).

### Reihenfolge in `main._ready()`
Umgebung → `LevelBuilder.build()` → NavMesh backen → SynthAudio → ShadowBudget → Traces → Player →
Monster → MonsterDirector (`setup(builder, monster)`) → Post-FX → Social (`setup(builder, self)`,
erzeugt die Gäste) → Dialog → DiceMatch → Hud → Menus → dann entweder Spielstand anwenden
(`_load_pending`, deferred) oder Neues Spiel (Intro, Startzustand speichern). Zum Schluss
`_parse_debug_args` (deferred).

**Wichtig:** Die Reihenfolge, in der der LevelBuilder Objekte erzeugt, ist Teil des
Speicherformats (siehe 7).

### Szenenbaum (grob)
```
Main (Node3D, main.gd)
├─ WorldEnvironment, DirectionalLight (Mond)
├─ Level (NavigationRegion3D)        ← statische Geometrie, Türen, Lampen, Schalter, Verstecke …
│   ├─ Geschoss_0 / Geschoss_4       ← Flurnetze je Stockwerk
│   └─ Zimmer_11 …                   ← gedrehte Zimmerreihen
├─ Items, Gäste, Plattenspieler      ← dynamisch, direkt unter Main (LevelBuilder.world)
├─ SynthAudio, ShadowBudget, Traces, Player, Monster, MonsterDirector, Social
└─ CanvasLayer: PostFx (5), Hud (10), Dialog/DiceMatch (15), DeathScreen (20), Menus (30)
```

## 3. Konventionen

### Koordinaten & Ausrichtung
- 1 Einheit = 1 m. Erdgeschoss y = 0, Obergeschoss y = `LevelBuilder.UP_Y` (4), Keller y = −3,5.
- Hauptflur entlang +X (x 0 … 78,4, z ±1,6), Lobby bei negativem x.
- **Lokale +Z zeigt „nach vorn / in den Raum / von der Wand weg“** (Items: Vorderseite, Verstecke:
  heraus, Fenster/Schalter/Kalender/Spuren: in den Raum). Ausnahme: Monster schaut entlang **−Z**.
- Ursprung von Gegenständen = Unterseite; von Türen = Scharnier am Boden; von Fenstern = Mitte der Öffnung.
- Die Stockwerke liegen übereinander → „angekommen“ heißt immer auch `|Δy| < 1,5`; Zonen gelten nur
  bei `|Δy| ≤ 2,5`. Wer Positionen vergleicht, muss das Stockwerk mitprüfen.

### Kollisionsebenen
| Ebene | Bit | Was | Hinweis |
|-------|-----|-----|---------|
| 1 | 1 | statisch: Wände, Böden, Möbel, Verstecke, Truhen | **einzige Ebene fürs NavMesh** |
| 2 | 2 | Türen | nicht im NavMesh → Wegplanung geht durch Türöffnungen |
| 3 | 4 | Gegenstände, Lampen, Schalter, Pflanzen, Tagebuch, Kalender, Spuren | blockiert den Spieler nicht |
| 4 | 8 | Spieler | |
| 5 | 16 | Decke | |
| 6 | 32 | Monster | |
| 7 | 64 | klares Glas (Fenster, Glastür) | Sicht geht durch |
| 8 | 128 | Gäste | |
| 9 | 256 | Milchglas | blockiert Sicht |
| 10 | 512 | zugezogene Vorhänge (`HotelWindow.LAYER_BLOCK`) | nur Sicht-/Licht-Raycasts, nicht Bewegung |

Sichtprüfungen (Monster, Zeugen) nutzen `1 | 2 | 256 | 512`, Lichtprüfungen `1 | 2`.

### Interaktion („Smart Objects“)
- Ein Kollisionskörper bekommt `set_meta("interactable", objekt)`. Der Spieler-RayCast
  (`Player._update_focus`, Reichweite 2,2 m) fragt `objekt.get_prompt(player) -> String` ab und ruft
  bei [E] `objekt.interact(player)` auf.
- **Leerer Prompt = nicht interagierbar.** Zum Abschalten `set_meta("interactable", null)`.
- Große Gegenstände blockieren Türen/Truhen: `player.hands_blocked()` prüfen.

### Gruppen (zum Finden und Speichern)
`items`, `guests`, `player`, `doors`, `chests`, `hide_spots`, `lamp_fixtures` (die Lampen),
`lamps` (deren Lichter), `light_source` (alles, was für die Helligkeit zählt – `FlickerLight`),
`light_switches`, `windows`, `pumpkin_plants`, `resource_spots`, `trace_marks`, `warning_notes`,
`guest_notes`, `diaries`.

### Räume & IDs
- **Raum-ID** = Zimmernummer (`"13"`, `"231"`) oder Bereichs-ID (`"lobby"`, `"flur_west"`,
  `"treppenhaus"`, `"keller"`, `"og_mitte"` …). Lampen und Schalter gehören über `room_id` zu einem
  Raum; `LightSwitch.find(tree, room_id)` schaltet alle Lampen des Raums.
- **Zonen** (`LevelBuilder.zones`, Kreise mit `name`, `center`, `radius`, `curiosity`) sind etwas anderes:
  sie tragen den Anzeigenamen („Nordflügel“, „Zimmer 13“) und die Neugier des Monsters.
  `MonsterDirector._zone_at(pos)` / `zone_name_at(pos)`.
- **Gast-IDs:** feste Gäste `edna`, `bruno`, `mila`; erzeugte `gast1`, `gast2` … (laufend).
- **Besitz** (`Item.owner_id`): `""` niemand, `"player"` oder eine Gast-ID.

### Pause & Zeit
- Menüs pausieren mit `get_tree().paused = true`. Was im Menü laufen muss, hat
  `process_mode = PROCESS_MODE_ALWAYS` (Game, Settings, SynthAudio, Menus, DeathScreen, TitleScreen).
- **Spielzeit ist `MonsterDirector.elapsed`** (pausiert, wird gespeichert). Datum daraus über
  `Calendar.today()` / `Calendar.date_text(elapsed)`; ein Tag = `Calendar.DAY_SECONDS` (300 s).
- Spielablauf-Timer laufen über `delta`, nie über Systemzeit. Bei `get_tree().create_timer()` für
  Spielereignisse `process_always = false` übergeben (`create_timer(t, false)`), sonst laufen sie im
  Menü weiter.

### Bewegung von Gästen und Monster
- `NavigationAgent3D` mit `path_height_offset = 0.2` (NavMesh liegt ~0,2 m über dem Boden).
- Eigene `_move_to(point, speed, delta) -> bool` (true = angekommen) mit **Festgefahren-Erkennung**:
  bewegt sich der Körper kaum, nach 0,6–1 s seitlich 15 cm ausweichen und Ziel minimal verschieben,
  damit der Pfad neu berechnet wird. Neue Akteure sollten diese Logik übernehmen.
- Türen öffnen Gäste/Monster selbst, wenn sie nahe sind (`_open_doors()`).
- Treppen: Rampe als Kollision (Ebene 1, fürs NavMesh) + Stufen nur als Optik. Läufe müssen bündig
  an der Flurkante enden, sonst Stolperkante.

## 4. Level (`scripts/level/level_builder.gd`)

- **Datengetrieben:** `FLOORS` (Flurnetze je Stockwerk: Abschnitte mit Schalter, Querflügel) und
  `ROWS` (Zimmerreihen: Ursprung, Drehung, Zimmer `[Nummer, Breite, Art, Außenfenster]`).
- Zimmer-Arten: `player`, `guest`, `empty`, `vacant` (Licht aus, freie Zimmer für neue Gäste),
  `laundry`, `abandoned`, `derelict`, `locked`.
- Bauen in **lokalen Rahmen**: `_parent` ist das gerade aktive Bauteil (Geschoss oder gedrehte
  Zimmerreihe); `_wall_x/_wall_z` mit Öffnungen als `Vector4(mitte, breite, oberkante, unterkante)`.
  Gegenstände kommen dagegen in die Hauptszene (`world`), umgerechnet über `_global()`.
- Ergebnisse für andere Systeme: `rooms` (Nummer → `{no, kind, center, door_front, door_inside,
  along, into, door, spots}`), `zones`, `spawn_points` (`[0]` = Keller), `patrol` (`{pos, room}`),
  `wander_points`, `player_spawn`, `player_door_front`, Lobby-/Bar-/Garten-/Feier-Punkte,
  `game_table`, `diary`.
- NavMesh wird in `main._bake_navigation` zur Laufzeit gebacken (nur Ebene 1, Agent 0,3 m / 1,6 m).
- Ein neues Zimmer: Eintrag in `ROWS` – Wände, Tür, Milchglas, Lampen, Schalter, Möbel, Zone und
  Wegpunkt entstehen automatisch. **Speicherformat beachten** (siehe 7).

## 5. Das Monster

Zwei Teile: **`MonsterDirector`** entscheidet *ob/wann/wohin* (versteckte Werte, Dramaturgie,
Effekte), **`Monster`** führt aus (Zustandsautomat, Bewegung, Sicht, Spuren).

### Versteckte Werte (Director)
- `boldness` (Dreistigkeit, global, steigt nach dem ersten Angriff) − `boldness_dip` − `satiation`
  = `effective_boldness()`.
- `curiosity` je Zone: strebt jede Sekunde zu einem Grundwert aus Dunkelheit und fehlender Deko,
  Ereignisse addieren direkt (`add_curiosity`).
- `pressure_at(p) = Dreistigkeit × (0,5 + 0,5 × Neugier/100)` (+ Bonus beim Jagen),
  `deterrence_at(p)` aus Deko × Licht / `demand()` plus Licht allein. `is_blocked` / `is_protected`.
- `light_at(p)`: Summe aller `light_source` mit freier Sichtlinie (Raycast) + Mondlicht durch
  Außenfenster mit offenem Vorhang. Teuer → sparsam aufrufen.

### Ereignis-Schnittstelle (andere Systeme melden, der Director reagiert)
`on_noise(pos, stärke)` · `on_lights_off(pos)` · `on_actor_hid(spot, actor)` · `on_monster_talk(pos)` ·
`on_monster_noticed()` · `on_monster_repelled()` · `on_monster_gone()` · `kill_guest(guest, spot)` ·
`kill_player(spot)`. Neue Spielmechaniken, die das Monster beeinflussen sollen, melden sich hier.

### Dramaturgie
- Vor dem ersten Angriff: kein Monster. Erster Angriff am 3./4. Oktober während einer Feier
  (`_first_attack_at_party`), spätestens am 5.
- Danach Wechsel `Phase.CALM` (Keller) ↔ `Phase.ACTIVE` (streift umher); Dauern über `_day_lerp`.
  `WARNING`/`COOLDOWN` sind Altlast und werden nicht mehr benutzt.
- `attacks <= HARMLESS_ATTACKS` (2) → `is_harmless()`: es holt niemanden, `kill_*` werden zu
  Erschrecken (`_scare_guest`) bzw. Zeigen (`_reveal_to_player`).
- Haunting (Türen, Vorhänge, Licht, Betten, Zimmer 13) nur, wo der Spieler nicht hinsieht (`_unseen`).

### Monster-Zustände
`INACTIVE, PATROL, INVESTIGATE, LURK, STARE, SEARCH, CHECK_HIDE, CHASE, REPELLED, RETREAT, KILL, SLINK, REVEAL`.
Wechsel nur über `_set_state()` (setzt Zustands-Timer zurück). Von außen: `start_roaming`,
`investigate`, `go_check`, `stare`, `go_home`, `spawn_at` (Tests), `spawn_near_unseen`, `deactivate`.
Sieht der Spieler es ohne Jagd länger als 0,35 s → `SLINK` (aus dem Blick verschwinden).

## 6. Gäste & Soziales

- **`GuestProfiles`**: feste Gäste in `ALL`, erzeugte in `static var generated`; Zugriff immer über
  `GuestProfiles.get_profile(id)`. Alle Profile haben dieselbe Form (Werte, `activities`-Gewichte,
  `dice`, `lines`). Sätze über `guest.line(key)`.
- **`GuestGenerator.make(seed, room, arrived_room)`**: deterministisch aus dem Seed.
  **Achtung:** Die Reihenfolge der `rng`-Aufrufe in `make()` bestimmt, wer der Gast ist. Neue
  Zufallswerte nur **ans Ende** anhängen, sonst werden aus gespeicherten Seeds andere Gäste.
  `name_for(seed)` verlässt sich darauf, dass der Name die **erste** Zufallszahl ist.
- **`Guest`**: Zustandsautomat (`IDLE, WALK, CARRY_HOME, PLACE_DECO, HARVEST, STEAL, HIDE_GO, HIDING,
  PARTY, TALKING, MINIGAME, DEAD, KNOCK, SHELTER`). In `IDLE` wählt `_next_activity()` gewichtet aus
  `profile.activities`; `_arrive()` verarbeitet das Ankommen je Zustand.
- **`Social`** ist der Ort für alles zwischen Gästen und Spieler: Gästeliste (`guests`,
  `living_guests()`, `guest_by_id()`), Beziehungen (`change_relation`), Gerüchte mit Verzögerung,
  Diebstahl mit Zeugen, Reservierung von Verstecken (`find_hide_spot` / `release_hide_spot`),
  Feiern, Herausforderungen, Gäste-Mäxchen, Berichte über Spuren (`note_trace` → `report_line`),
  Klopfen an Zimmer 13, Zettel, Neuankömmlinge (`START_GUESTS` 30, `MIN_GUESTS` 24).
- Gäste melden sich mit `Game.social.on_*` (Diebstahl, fehlende Deko/Birne, Monster gesehen …).

## 7. Speichern & Laden

- JSON in `user://saves/` (`slot_1..3.json`, `autosave.json` + `.png`), geschrieben über `.tmp` +
  Umbenennen. `SaveManager.collect()` sammelt, `SaveManager.apply(data)` stellt her.
- **Laden = Hauptszene neu aufbauen, dann befüllen.** `load_slot` setzt `Game.pending_load` und
  wechselt die Szene; `main.gd` ruft nach dem Aufbau `SaveManager.apply` auf.
- **Feste Welt-Objekte werden über die Reihenfolge in ihrer Gruppe zugeordnet** (`_apply_group`:
  Index i im Spielstand ↔ i-ter Knoten der Gruppe). Passt die Anzahl nicht, wird die ganze Gruppe
  mit Warnung übersprungen. Spuren an Türen/Fenstern speichern ebenfalls den Index in `doors`/`windows`.
  → **Jede Änderung, die Anzahl oder Bau-Reihenfolge von Türen, Truhen, Lampen, Schaltern, Fenstern,
  Verstecken, Pflanzen oder Ressourcen-Stellen ändert, braucht `VERSION`/`MIN_VERSION` +1** (mit
  Kommentarzeile, was sich geändert hat). Alte Stände werden dann nicht mehr angeboten.
- Gegenstände werden nicht zugeordnet: beim Laden werden alle gelöscht und aus `kind` + `extra`
  (`Item.create_extra()`) neu erzeugt. Neuer Gegenstandszustand → in `create_extra()`/`_build()`
  abbilden oder in `_item_data`/`_make_item` ergänzen.
- Erzeugte Gäste: nur `{id, seed, room, arrived}` (`Social.roster_state` / `restore_roster`), wird
  **zuerst** angewendet, weil sich alles Weitere auf Gast-IDs bezieht. Danach Welt → Director-Werte →
  Gäste → Gegenstände → Spieler → Soziales → Monster zuletzt.
- Speicherbare Welt-Objekte bieten `save_state() -> Dictionary` / `load_state(d)` (HideSpot, Lamp,
  LightSwitch, HotelWindow) oder werden in `collect()` direkt ausgelesen (Door, Chest, Plant, Resource).
  Neues Objekt mit Zustand: Gruppe + Eintrag in `collect()` und `apply()`.
- Beim Laden: `d.get(key, standard)` verwenden, damit fehlende Schlüssel nicht abstürzen.
- Speichern am Tagebuch gesperrt bei Jagd oder Monster näher als `NOISE_START`; Autosave nur in
  sicheren Momenten (`is_safe_for_autosave`), sonst aufgeschoben.
- **Prüfen:** `--savetest` sammelt → wendet an → sammelt erneut und meldet Unterschiede.

## 8. Weitere Systeme (Kurzüberblick)

| System | Datei(en) | Merkpunkte |
|--------|-----------|------------|
| Licht | `lamp.gd`, `light_switch.gd`, `flicker_light.gd`, `util/shadow_budget.gd` | Lampe = Fassung + Birne (Item `BULB`); `flicker` setzt der Director; nur die 6 nächsten Lampen werfen Schatten; Licht aus → `on_lights_off` |
| Fenster | `hotel_window.gd` | klares Glas / Milchglas / Vorhang (Ebene 10 nur für Sicht & Mond) |
| Spuren | `traces.gd`, `trace_mark.gd` | zentrale Stelle für alle Spuren; jede neue Spur → `Social.note_trace`; Fußabdrücke verblassen, Marken bleiben |
| Zettel | `warning_note.gd` | feste Warnungszettel (`warning_notes`, erst nach dem 1. Angriff sichtbar) und Gäste-Zettel (`guest_notes`, max. 30) |
| Verstecke | `hide_spot.gd` | `occupant` reserviert; `seen_entering` = Todesurteil; `checked` als Spur |
| Kalender | `calendar.gd` | statische Datumsfunktionen + Abreißkalender in Zimmer 13 |
| Mäxchen | `minigames/` | `Maexchen` = Regeln, `DiceMatch` = Partie & Gast-KI & Einsätze, `GameTable` = Tisch; Würfeln macht Lärm |
| UI | `ui/` | `UiKit` = Meldezettel-Optik für Menüs; `Hud` Prompt/Meldungen/Debug (F3); `Menus` pausiert |
| Optik | `util/mat.gd`, `shaders/` | Materialien immer über `Mat.psx(...)` (Vertex-Snapping über Shader-Global `psx_snap`); Post-FX: Gamma, Dithering, Rauschen, Flackern |
| Geometrie | `util/geo.gd` | `Geo.solid(parent, größe, pos, mat, ebene)` für Kollisionskästen, `Geo.mesh` für reine Optik |

## 9. Rezepte

**Neuer Gegenstand:** `Item.Kind` ergänzen (nur **ans Ende**, Spielstände speichern den Zahlenwert),
Preis in `PRICES`, Aussehen/`deco_strength` in `_build()`, ggf. `create_extra()`.

**Neues interagierbares Objekt:** Körper auf passender Ebene (meist 3 = Bit 4),
`set_meta("interactable", self)`, `get_prompt`/`interact`, Gruppe; im LevelBuilder über eine
`_xyz()`-Hilfsfunktion platzieren. Hat es Zustand → `save_state`/`load_state` + SaveManager +
`VERSION` erhöhen.

**Neue Gast-Aktivität:** Schlüssel in `activities` der Profile/Archetypen, Fall in
`Guest._next_activity()`, ggf. eigener `State` und Fall in `_arrive()`.

**Neuer Dialogsatz-Typ:** Schlüssel in `GuestGenerator.COMMON` (Fallback für alle) und bei Bedarf in
den festen Profilen und Archetypen.

**Neue Monster-Reaktion:** Ereignis-Funktion `on_xyz()` im Director, Aufruf von der Quelle aus.
Tuning-Konstante oben im Director.

**Neue Spur:** `add_xyz()` in `Traces`, `TraceMark`-Art, in `save_state`/`load_state` abdecken,
Text für Gästeberichte in `Social.TRACE_TEXT`.

**Neuer Debug-Parameter:** in `main._parse_debug_args` (und Kopfkommentar in `main.gd`) plus Tabelle im README.

## 10. Testen

- Start mit Godot 4.7.2 (Pfad im README), Parameter nach `--`. Schnelle Läufe ohne Fenster-Interaktion:
  `--time-scale 3`, `--quit-after N`, `--trace` (Zustand alle 2 s in die Konsole), `--day=n`,
  `--attacks=n`, `--kill=id`, `--knock` …
- Screenshots zum Prüfen: `--shot=pfad.png --frames=n` oder `--shot-on=reveal`; Menüs mit `--menu=…`.
- Nach Änderungen am Speichern oder an der Welt: `--savetest` laufen lassen (`alles gleich` erwartet).
- Es gibt keine automatisierten Tests – Prüfung über Debug-Parameter, Konsole und Screenshots.
