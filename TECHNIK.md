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
  Modelle, Texturen (`TexGen`) und Sounds (`SynthAudio`) sind prozedurale Platzhalter. Ausnahmen: das
  Monster-Modell `assets/models/monster.glb` (siehe 5, „Aussehen & Animation“) und die Lobby-Sofas
  `assets/models/couch.glb` (`LevelBuilder._couch()`: Rohmodell in Blender-Einheiten, per
  `COUCH_SCALE` auf ~2,4 m Länge gebracht; Kollision als zwei Boxen) und die Barflaschen
  `assets/models/bottles.glb` (28 Objekte `bottle_NN` in Metern, Ursprung mittig unten; gebaut von
  `tools/build_bottles.py` aus dem Paket in `assets/source/`) und der Plattenspieler
  `assets/models/record_player.glb` (`tools/build_record_player.py`: Objekte `body` und `record`, die
  Platte ist eine eigene runde Scheibe mit Ursprung auf der Drehachse, damit `RecordPlayer` sie drehen
  kann). Die Farbtextur der GLB kommt per `Mat.model(pfad, mesh)` in ein `Mat.psx` (eins pro Modelldatei).
  **Tapeten** `assets/textures/wallpaper_<variante>.png` (teal für Flure, Küche, Bar und Treppenhaus, beige für die Zimmer, red für die Lobby) + gemeinsame Höhenkarte
  `wallpaper_bump.png`, siehe „Optik“ in 9.
  **Katzenmodell** `assets/models/cat.glb` (`HotelCat`, Spielkonzept 6.11): `tools/build_cat.py` aus
  Meshys Zip (Auto-Rigging-Preset „Hund“, in `assets/source/`). 27 Knochen (`Hips`, `chest`, `head`,
  `earend`/`R_earend`, `tail`…`tail3`, je Bein `frontleg`/`backleg` + `0`–`2`, rechts mit `R_`), ~2500
  Dreiecke, Animation `walk` (1 s). Das Skript hängt falsch zugeordnete Beingewichte um (Punkt gehört
  zum nächstgelegenen Beinknochen). Größe (0,34 m hoch) und Blick nach −Z stehen nur am Wurzelknoten
  der Armatur – angewendet würden die Translations-Schlüssel der Animation nicht mitskaliert.
  **Lakengeist** `assets/models/ghost.glb` (Spielkonzept 4.18, `SheetGhost`): `tools/build_ghost.py` riggt
  Meshys Modell selbst – Knochen `root` → `hem` · `spine` → `head` · je Seite `upper_arm`/`forearm`/`hand` +
  `thumb|index|middle|ring|pinky` `1`–`3` (Suffix `.L`/`.R`, L = Geist-links). Finger werden über die Hautfarbe
  der Textur gefunden (Spitzen = weiteste Punkte vom Handgelenk über die Oberfläche, Daumen = Finger zur
  Körpermitte); lokal X der Hand-/Fingerknochen beugt zur Handfläche (positiv = krallen). Eigene Gewichte statt
  Bone-Heat (das Netz ist nach dem Verschmelzen ein Stück, aber nicht sauber geschlossen). 10 159 Dreiecke,
  1,9 m, Blick nach −Z, Ursprung mittig unten, keine Animationen.
  **Gast-Grundkörper** `assets/models/guest_<name>.glb` (Spielkonzept 6.0, `GuestBody`): `tools/build_guest.py`
  aus Meshys GLB (Auto-Rigging mit Skelettvorlage **Mixamo**, „Alle hinzugefügt“, einzelne Datei; Rohmodell
  als `assets/source/guest_<name>.glb`). Knochen ohne `mixamorig:` (`Hips`, `Spine`…`Spine2`, `Neck`, `Head`,
  `LeftArm`/`LeftForeArm`/`LeftHand` …, `LeftUpLeg`/`LeftLeg`/`LeftFoot` …), Animationen `walk` und `run`
  (auf der Stelle), Netz unverändert von Meshy (höchstens 15 000 Dreiecke – Reduzieren zieht Dreiecke über
  Meshys winzige UV-Inseln und macht Schlieren), 1024er-Textur als PNG (JPEG färbt die Inselränder), Lücken
  zwischen den Inseln vor dem Verkleinern gefüllt, Blick nach −Z, Füße auf 0, Maße in Metern. **Färbemaske** als
  Punktfarbe je Fläche (R/G/B = Oberteil/Hose/Haare): Kopf-/Hals-Knochen → Haare, sonst hellere Grautöne →
  Oberteil, dunklere → Hose; Haut, Schuhe, Hände bleiben. **Formschlüssel `build`** (Körperbau, 1 = kräftig,
  negativ = schlank). Das Skript gibt die Zeile für `GuestBody.BODIES` aus (Höhe, Schulterbreite, Laufweite
  der Animationen, mittlere Helligkeit je Färbebereich) – nach jedem Neubau übernehmen.
  **Mixamo-Animationen:** jede `assets/source/anim/<name>.fbx` (Mixamo, „Without Skin“, 30 fps, am
  Standard-Charakter heruntergeladen) landet als Animation `<name>` in **jeder** Gast-GLB – ein Download gilt für
  alle Grundkörper, solange sie Meshys Mixamo-Skelett haben. Umbenennen reicht nicht, weil Mixamo in T-Pose steht
  und unsere Gäste mit hängenden Armen: `retarget()` dreht den Gast rechnerisch in die T-Pose der Quelle
  (Knochenrichtung zum Kind, bei Hüfte und Händen zusätzlich die Querachse, `ALIGN`) und gibt jedem Knochen
  dieselbe Weltdrehung gegenüber dieser Pose wie in der Quelle gegenüber ihrer Ruhepose. Hüfthöhe im Verhältnis
  (Hüfte über Fuß), seitliches Wandern der Hüfte über `DRIFT_WINDOW` (2 s, als Schleife) gemittelt und abgezogen –
  Wackeln bleibt, der Gast tanzt auf der Stelle. Szenen-Bildrate bleibt (der FBX-Import stellt sie um, sonst
  liefen `walk`/`run` zu schnell). Die FBX liegen nicht im Repo (Mixamo-Lizenz: keine Weitergabe der Rohdateien).
  **Rahmen-Kit** `assets/models/frames.glb` (Spielkonzept 7.2, `OpeningFrame`): `tools/build_frames.py` zieht
  2D-Profile ohne Ausgangsmodell zu 1 m langen Teilen aus – `casing` (Seitenbekleidung), `fillet`, `frieze`,
  `cap` (Kopfpartie im Craftsman-Stil), `stool` (Fensterbank), `board` (Einheitswürfel für Zarge und
  Fensterrahmen). Lage: Länge entlang +X, Profilbreite +Y, Stärke +Z (Rückseite auf der Wand bei z = 0).
  Die Profile stecken 1,5 cm tief in der Wand, und benachbarte Teile überlappen sich (`OpeningFrame.TUCK`):
  Beim Vertex-Snapping rastet jedes Teil für sich ein, bloß aneinanderstoßende Teile öffnen Fugen, durch die
  die Tapete blitzt. Dazu zieht das Rahmenmaterial (`OpeningFrame.trim_material()` = `Mat.layer` mit
  `PULL` 0,5 %) die Rahmen leicht zur Kamera, und die Laibungen der Wände tragen dasselbe Holz – rutscht die
  Zarge weg, sieht man Holz statt Tapete (außer im Beton des Kellerdurchgangs). `OpeningFrame` (ein `MeshInstance3D` pro Öffnung) streckt die Teile nur in der Länge,
  teilt sie in Stücke ≤ 1 m, dreht bei gespiegelter Lage die Dreiecke um und fügt alles zu einem Mesh
  zusammen (gleiche Öffnungen teilen sich das Mesh). Benutzt von `Door`, `HotelWindow` und für Durchgänge ohne Tür
  (`LevelBuilder._frame_x/_frame_z`). Reine Optik: keine Kollision, nicht im Spielstand, nicht im NavMesh.
- **Kein Inventar.** Ein Gegenstand in der Hand (`Player.held` / `Guest.held`), Geld ist der einzige
  abstrakte Besitz (`Game.money`). Gäste haben zusätzlich einen abstrakten Vorrat (`Guest.stock`).
  Ausnahme am Körper des Spielers: Kompass, Kartenblätter, Schlüsselbund (`Player.has_compass`,
  `map_pages`, `keyring`) – siehe 8, „Am Körper“.
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
| `Settings` | `scripts/autoload/settings.gd` | Einstellungen, `user://settings.cfg`, Signal `changed`; Vollbild steht nicht in `KEYS` (Start immer im Fenster) |
| `Game` | `scripts/autoload/game.gd` | Referenzen auf alle Systeme, Geld, Meldungen, Tastenbelegung, Szenenwechsel, Screenshot-Debug |
| `SaveManager` | `scripts/autoload/save_manager.gd` | Speichern/Laden, Autosave, Tagebuchsatz |

### `Game` als Drehscheibe
`main.gd` erzeugt die Systeme und trägt sie in `Game` ein: `player`, `monster`, `director`, `social`,
`traces`, `audio`, `hud`, `dialog`, `phones`, `dice`, `menus`. Systeme rufen sich **direkt** über diese
Referenzen auf (`Game.director.on_noise(...)`), nicht über Signale. Signale gibt es nur für
UI-nahe Dinge (`Game.message_posted`, `money_changed`, `player_died`, `caption_posted`,
`Settings.changed`, `SaveManager.autosaved`).

- Referenzen können `null` sein (Titelbildschirm, Szenenwechsel) → bei Aufrufen aus Welt-Objekten
  mit `if Game.traces:` / `if Game.social:` absichern.
- `Game.reset()` am Anfang von `main._ready()` leert alles.
- Text für den Spieler: `Game.say(text, dauer)`. **Geräusch in der Welt:** `Game.noise(art, ort, quelle)`
  – Geräusch *und* Lärm in einem (siehe 8a). Nur reine UI-, Meldungs- und Monster-Stinger-Geräusche
  gehen direkt über `Game.play_sound(kind, volume)` – setzt bei Lautstärke ≥ 0,3 auch Untertitel
  (`Game.SOUND_CAPTIONS`). Sound-Arten stehen in `SynthAudio.play_shot` (`scream`, `sting`, `growl`,
  `gasp`, `bang`, `blip`, `creak`, `thud`, `knock`, `ring`).

### Reihenfolge in `main._ready()`
Umgebung → `LevelBuilder.build()` → NavMesh backen → SynthAudio → ShadowBudget → Traces → Player →
Monster → MonsterDirector (`setup(builder, monster)`) → Post-FX → Social (`setup(builder, self)`,
erzeugt die Gäste) → Dialog → PhoneCalls (findet die Telefone) → DiceMatch → ChessMatch → Hud → Menus → dann entweder Spielstand anwenden
(`_load_pending`, deferred) oder Neues Spiel (Intro, Startzustand speichern). Zum Schluss
`_parse_debug_args` (deferred).

**Wichtig:** Die Reihenfolge, in der der LevelBuilder Objekte erzeugt, ist Teil des
Speicherformats (siehe 7).

### Szenenbaum (grob)
```
Main (Node3D, main.gd)
├─ WorldEnvironment, DirectionalLight (Mond)
├─ Level (NavigationRegion3D)        ← statische Geometrie, Türen, Lampen, Schalter, Verstecke …
│   ├─ Wände, Böden, Decken, Türen … ← aus assets/maps/eg.json, direkt unter Level
│   ├─ Zimmer_0101 …                 ← je Zimmer ein gedrehter Rahmen (Ursprung = Türmitte)
│   └─ Keller                        ← unter dem Treppenhaus Ost
├─ Items, Gäste, Plattenspieler      ← dynamisch, direkt unter Main (LevelBuilder.world)
├─ SynthAudio, ShadowBudget, Traces, Player, Monster, MonsterDirector, Social, PhoneCalls
└─ CanvasLayer: PostFx (5), Hud (10), Dialog/DiceMatch/ChessMatch/PhoneUI (15), DeathScreen (20), Menus (30)
```

## 3. Konventionen

### Koordinaten & Ausrichtung
- 1 Einheit = 1 m. Erdgeschoss y = 0, Obergeschoss y = `LevelBuilder.UP_Y` (4), Keller y = −3,5.
- Ursprung = Mitte des Haupteingangs auf der Südwand; x nach Osten, z nach Süden (Norden = −Z). Das Gebäude
  reicht etwa von x −76 … 76 und z −112 … 0, die Lobby liegt in der Mitte (x ±7,4, z −28 … 0).
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
| 9 | 256 | Milchglas (`HotelWindow` mit `frosted`, derzeit nicht verbaut) | blockiert Sicht |
| 10 | 512 | zugezogene Vorhänge (`HotelWindow.LAYER_BLOCK`) | nur Sicht-/Licht-Raycasts, nicht Bewegung |
| 11 | 1024 | Hotelkatzen (`HotelCat.LAYER`) | blockiert niemanden; nur der Spieler-Strahl trifft sie (Streicheln) |

Sichtprüfungen (Monster, Zeugen) nutzen `Senses.SIGHT_MASK` = `1 | 2 | 256 | 512`, Lichtprüfungen `1 | 2`,
Lärm-Dämpfung `1 | 2 | 64`.

### Interaktion („Smart Objects“)
- Ein Kollisionskörper bekommt `set_meta("interactable", objekt)`. Der Spieler-RayCast
  (`Player._update_focus`, Reichweite 2,2 m) fragt `objekt.get_prompt(player) -> String` ab und ruft
  bei [E] `objekt.interact(player)` auf.
- **Leerer Prompt = nicht interagierbar.** Zum Abschalten `set_meta("interactable", null)`.
- Große Gegenstände blockieren Türen/Truhen: `player.hands_blocked()` prüfen.
- **Gegenstände in der Hand** hängen als Kind am Hand-Knoten und sind über `Item.set_held(true)`
  **statisch** eingefroren (`FREEZE_MODE_STATIC`). Kinematisch eingefroren schreibt die Physik die alte
  Lage zurück – der Gegenstand dreht dann nicht mit. Immer `set_held()` benutzen, nie `freeze` direkt.

### Gruppen (zum Finden und Speichern)
`items`, `guests`, `player`, `doors`, `chests`, `hide_spots`, `lamp_fixtures` (die Lampen),
`lamps` (deren Lichter), `light_source` (alles, was für die Helligkeit zählt – `FlickerLight`),
`light_switches`, `windows`, `pumpkin_plants`, `resource_spots`, `trace_marks`, `warning_notes`,
`guest_notes`, `diaries`, `phones`, `dressers`, `cats`, `uv_marks` (nicht gespeichert).

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
- **Einzige Zeitraffung:** Schläft der Spieler (`Player.start_sleep`), steht `Engine.time_scale` auf
  `SLEEP_SPEED` (5). Zurück auf 1 in `_stop_sleep()` – beim Aufwachen, Aufstehen, Tod und in `_exit_tree`.

### Bewegung von Gästen und Monster
- `NavigationAgent3D` mit `path_height_offset = 0.2` (NavMesh liegt ~0,2 m über dem Boden).
- Eigene `_move_to(point, speed, delta) -> bool` (true = angekommen) mit **Festgefahren-Erkennung**:
  bewegt sich der Körper kaum, nach 0,6–1 s seitlich 15 cm ausweichen und Ziel minimal verschieben,
  damit der Pfad neu berechnet wird. Neue Akteure sollten diese Logik übernehmen.
- Türen öffnen Gäste/Monster selbst, wenn sie nahe sind (`_open_doors()`).
- Treppen: Rampe als Kollision (Ebene 1, fürs NavMesh) + Stufen nur als Optik. Läufe müssen bündig
  an der Flurkante enden, sonst Stolperkante.

## 4. Level (`scripts/level/level_builder.gd`)

Baut das Erdgeschoss aus dem Gebäudeplan (`assets/maps/eg.json`, Abschnitt unten). Der alte, im Code
festgelegte Grundriss (`ROWS`/`FLOORS`) liegt unter dem Git-Tag `alte-karte`.
- **Ablauf von `build()`:** Flächen-Raster (`_index_places`, 25 cm) → jede Wand des Plans (`_build_wall`) →
  Böden und Decken je Fläche → Zimmer → Einrichtung aus dem Plan (`_furniture`, `_fittings`, `_items`,
  `_lights`) → Lobby, Galerie, Bar/Partyraum/Küche (`_common_rooms`), Pool, Gärten → Treppenhäuser und
  Keller → Zonen, Wegpunkte.
- **Wände:** Eine Planwand wird dort geteilt, wo sich die Räume an einer Seite ändern (abgetastet alle 25 cm,
  30 cm neben der Mitte; kurze Läufe an Querwänden geglättet). Tapete je Seite über `Mat.wallpaper_split`
  (Zimmer beige, Lobby rot, sonst teal); Seiten ohne Tapete (draußen = Fassade, Toilette/Pool = Fliesen,
  Lager = Beton) bekommen eine 2-cm-Haut knapp vor der Wand. Glaswände (Pool) als Scheibe auf Ebene 7.
- **Öffnungen → Objekte** (`_opening_object`): Türen gehen in Zimmer und Räume auf, nie in den Flur
  (`_inner_side`); ab 1,5 m Breite Doppeltür. Terrassen- und Glastüren sind gläserne Doppeltüren, Aufzüge
  verschlossen („Außer Betrieb“), der Haupteingang verriegelt. Fenster schauen von innen nach draußen; ihre
  `room_id` ist die Fläche dahinter (Zimmernummer, Bereich oder Flurabschnitt, `_room_id_at`). Unter jeder
  benutzbaren Tür liegt eine Schwelle – ohne Boden in der Wandlücke risse das NavMesh ab.
- **Zimmer** (`_room`): Rahmen am Türmittelpunkt (+X an der Flurwand entlang, +Z ins Zimmer); Innenmaß aus
  dem Rechteck an der Tür (Eckzimmer sind L-förmig). Das Innere kommt aus dem Plan; `_room` legt nur die
  Zimmerart fest (Tür offen bei `abandoned`/`derelict`, abgeschlossen bei `locked`). Arten: `player`, `guest`,
  `empty`, `vacant`, `laundry`, `abandoned`, `derelict`, `locked`; Sonderzimmer in `ROOM_KINDS` (Endziffern der
  alten Nummern, `PLAYER_ROOM` 0113, `LOCKED_ROOM` 0118, `COMPASS_ROOM` 0126). **Bauphase:** Nur Flügel in
  `OPEN_WINGS` sind bewohnbar; Zimmer anderer Flügel haben eine versiegelte Tür (`_seal`: abgeschlossen, auch
  für das Monster) und dauerhaft zugezogene Vorhänge (`HotelWindow.sealed`), aber kein Inneres und keinen Boden.
  Objekte des Plans auf versiegelten Flächen werden übersprungen.
- **Einrichtung aus dem Plan** (Objektebenen, Abschnitt unten), in dieser Reihenfolge – sie bestimmt die
  Gruppen-Reihenfolge im Spielstand:
  - `_furniture`: Rezeption, dann `furniture`. Bett/Schrank → `HideSpot` (ins `spots` des Zimmers),
    Kommode, Truhe, Schach- und Spieltisch, Sofa als eigene Bauteile in der Rechteckmitte mit Blick nach
    `facing` (ohne: zur Flächenmitte); alles andere ein Kasten in Plangröße mit Höhe aus `BOX_HEIGHTS`.
    Jedes Möbel landet mit Oberkante in `_furnishings` – `_top_at(p)` liefert daraus die Höhe, auf der
    Kerzen, Telefone, Zettel und Gegenstände stehen.
  - `_fittings`: Wandsachen (Schalter, Bild, Spinnwebe, UV-Schrift, Kalender) über `_wall_spot` an die
    Wandfläche der Seite `wall` (`_on_wall` sucht im `_wall_index`), Höhen als Konstanten (`SWITCH_Y` …).
    Telefon, Zettel, Tagebuch und Vorräte auf dem Möbel darunter, Kürbispflanzen mit `PLANT_STAGES`.
  - `_items`: `Item.Kind`-Name aus dem Plan, auf dem Möbel darunter.
  - `_lights`: Wandleuchten mit Höhe/Helligkeit/Reichweite je Flächenart (`_lamp_style`), Kerzen auf dem
    Möbel, Laternen; `broken` aus dem Plan.
  - Was der Plan nicht kennt, steht in `CONTENT` je Raum-ID: Münzbetrag, Kartenblatt, Zettel-Nummer, UV-Text.
    Lampen und Schalter gehören zur Raum-ID der Fläche davor (`_light_room_at`: Umkleiden/Duschen teilen sich
    `umkleiden`); Schalter in unbewohnten Zimmern starten aus.
  - Nicht im Plan und weiter im Code: Galerie (Leuchten, Schalter), Treppenhaus-Leuchten zwischen den
    Geschossen, der ganze Keller; dazu Flaschen, Hocker, Tanzfläche, Teppiche, Beete und die Treffpunkte für
    Gäste (`_common_rooms`, `_lobby_hall`, `_garden_beds`).
- **Lobby und Galerie:** Über dem Luftraum (`open_above`) fehlt die Decke; die Galerie ist ein 0,5 m dicker
  Boden auf 3,5–4 m (zugleich Lobbydecke) mit Geländer, Wänden bis 7,5 m und zwei gesperrten Türen ins
  Obergeschoss. Treppe aus dem Plan (`stairs`, `up` = oberes Ende).
- **Treppenhaus Ost:** Schacht von −3,5 bis 7,5 m, je Geschoss zwei Läufe mit Wendepodest im Norden
  (hinauf West/Ost, hinab Ost/West); unten die niedrige Kellertür, oben eine gesperrte Tür. Der Keller liegt
  südlich davon unter dem Flur. Treppenhaus West ist verschlossen.
- Bauen in **lokalen Rahmen**: `_parent` ist das gerade aktive Bauteil (root, Zimmerrahmen, Keller);
  `_wall_x/_wall_z` mit Öffnungen als `Vector4(mitte, breite, oberkante, unterkante)`. Gegenstände kommen in
  die Hauptszene (`world`), umgerechnet über `_global()`.
- Ergebnisse für andere Systeme: `rooms` (Nummer → `{no, sign, kind, center, door_front, door_inside,
  along, into, door, spots}`), `zones`, `spawn_points` (`[0]` = Keller), `patrol` (`{pos, room}`),
  `wander_points`, `player_spawn`, `player_door_front`, Lobby-/Bar-/Garten-/Feier-Punkte, `party_corner`,
  `stairwell_point`, `game_table`, `chess_table`, `diary`. Abfragen: `in_lobby(p)`, `in_area(p, id)`,
  `is_outdoor(p)`, `cellar_center()`.
- NavMesh wird in `main._bake_navigation` zur Laufzeit gebacken (nur Ebene 1, Agent 0,3 m / 1,6 m).
  `--navcheck` misst Bau- und Backzeit (EG: ca. 0,5 s + 0,4 s) und prüft die Wege zu allen wichtigen Orten.
- Ein neues Zimmer: im Plan zeichnen und in den Objektebenen einrichten (Bett, Schrank, Leuchte, Schalter …),
  `tools/build_map.py` laufen lassen – Wände, Tür, Einrichtung, Zone und Wegpunkt entstehen daraus.
  **Speicherformat beachten** (siehe 7): Jede Änderung an Lampen, Schaltern, Verstecken, Kommoden, Truhen,
  Telefonen, Pflanzen oder Vorräten im Plan verschiebt die Reihenfolge.

### Gebäudeplan (`map.aseprite` → `tools/build_map.py` → `assets/maps/<stockwerk>.json`)
Grundriss seit Spielkonzept 7.5. Der Plan liegt im Projektwurzelverzeichnis (der Zeichner speichert
dort), das Skript ist reines Python ohne Zusatzpakete und braucht ca. 10 s je Stockwerk:
`python tools/build_map.py [map.aseprite] [assets/maps] [vorschau-ordner]`. Die Vorschau (`<stockwerk>.svg`)
zeichnet das Ergebnis **aus den JSON-Daten** (nicht aus dem Bild) – gut zum Prüfen nach Planänderungen.
- **Aufbau der Plandatei (Vorlage):** Jede Ebenengruppe der obersten Stufe ist ein Stockwerk (`EG`, `OG1` …,
  `Keller`) und wird zu `eg.json`, `og1.json` … – sobald sie Wände enthält. Gezählt werden alle normalen
  Ebenen der Gruppe, **egal ob sichtbar**; nicht gezählt werden Referenzebenen (`OG1/EG (Referenz)` zeigt das EG
  zum Abzeichnen) und Ebenen, deren Name mit `Beschriftung`, `Skizze` oder `Notiz` beginnt.
- **Legende = Palette mit Namen:** Die Bedeutung jeder Farbe kommt aus dem **Farbnamen in der Palette**
  (`FILLS`, `OPENINGS`, `Wand`, `Glaswand` oben im Skript). Farben dürfen sich ändern, die Namen nicht.
  Farben ohne Paletteneintrag meldet das Skript mit Pixelposition. Beim Zeichnen zeigt die Aseprite-Erweiterung
  `tools/aseprite-palette-names/` (View > Palettennamen) alle Namen als Liste; sie liest dafür denselben
  Paletten-Chunk aus der gespeicherten Datei, weil Aseprites Lua-API keine Farbnamen kennt.
  1 m = 10 px, Wände 2 px, Öffnungen als Farbstriche **auf** der Wandlinie, Flächen als Füllfarben, `Luftraum` = hier kein Boden (wird beim
  Stockwerk darunter zu `open_above`). Schrift in Wandfarbe im Grundriss wird über ihre Größe erkannt und
  übermalt, gehört aber in die Ebene `Beschriftung`.
- **Objektebenen** je Stockwerk: `Möbel`, `Ausstattung`, `Gegenstände`, `Lichter`. Sie zählen nicht zum
  Grundriss und haben eine eigene Legende (Palettennamen mit Vorsatz `Möbel:`, `Ausstattung:`, `Gegenstand:`,
  `Licht:` → `FURNITURE`, `FITTINGS`, `ITEMS`, `LIGHTS` im Skript). Möbel sind Rechtecke in Grundfläche, ein
  Strich `Möbel: Vorderseite` am Rand zeigt die Vorderseite. Alles andere ist ein 3×3-Punkt; Wandsachen
  (Leuchten, Schalter, Bilder, Spinnweben, UV-Schrift, Kalender) liegen innen an der Wand, daraus ergibt sich
  ihre Wandseite. Gleichfarbige Punkte dürfen sich nicht berühren (sonst wird es einer). Höhe, Helligkeit und
  Inhalt (Zettel-Nummer, Münzen, UV-Text) stehen nicht im Plan, sondern im LevelBuilder (`CONTENT`,
  `_lamp_style`, `BOX_HEIGHTS`). Die Ebenen wurden am 2026-10-19 aus dem laufenden Spiel übertragen; der
  Keller fehlt noch (er steht nicht im Plan und bleibt im Code).
- **Slices** (sprite-weit, daher Stockwerk als Vorsatz, ohne Vorsatz EG: `OG1 Raum: Bibliothek`):
  `Raum: <Name>` benennt die Fläche mit den meisten Pixeln im Slice (ID = Name klein, Umlaute ausgeschrieben),
  `Bereich: <Name>` → `areas`, `Treppe: <Name>` (**Pivot an der oberen Kante**) und `Treppenhaus: <Name>` →
  `stairs`, `Objekt: <Name>` (Pivot an der Vorderseite) → `objects`. Unbenannte Flächen heißen `<art>_<n>`,
  der einzige Flur `flure`.
- **Ausgabe** (Meter, x Ost, z Süd, Ursprung = Mitte Haupteingang auf der Südwand, Rechtecke `[x0, z0, x1, z1]`):
  `walls` (`a`, `b`, `thickness`, optional `glass`, `openings` mit `kind`/`at` = Abstand ab `a`/`width`;
  waagerechte Wände laufen durch, senkrechte enden bündig an ihnen), `regions` (`id`, `kind`, `outdoor`,
  `rects`, optional `name`; die Fläche `flure` umfasst alle Flure **und** die Lobby), `rooms` (`no`, `sign`,
  `wing`, `rects`, `center`, `door` mit `pos`/`normal` in den Flur, `windows`, `garden_doors`), `stairs` (`id`,
  `kind` `stair`/`stairwell`, `rect`, `up` bzw. `door`), `voids`, `open_above`, `areas`, `objects` (`name`,
  `rect`, `facing`), `corridors` (Flurabschnitte: `id`, `name`, `wing`, Mittellinie `a`–`b`), `floor_patches`
  (Boden unter Kübeln, Bäumen, Rezeption und freien Treppen, mit der Art der umgebenden Fläche), `planters`,
  `terrace_edges`, `trees`, `reception`; aus den Objektebenen `furniture` (`kind`, `rect`, optional `facing`),
  `fittings` und `items` (`kind`, `pos`, optional `wall` = Wandseite, Gegenstände mit `Item.Kind`-Namen) und
  `lights` (dazu optional `broken`).
- **Zimmernummern** entstehen im Skript (`WINGS`: Laufweg je Flügel als Flurmittellinien in Pixeln, dann
  Querflur; rechts ungerade). Liegt ein Zimmer an keinem bekannten Flur, bricht das Skript ab – dann `WINGS`
  ergänzen. `BROKEN_SIGNS`: abweichende Türschilder (0113 → „13“).
- `export_presets.cfg` packt `assets/maps/*.json` mit ein (`include_filter`), weil JSON keine Godot-Ressource ist.

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
`on_noise(pos, hörweite, quelle)` (nur über `Game.noise`) · `on_lights_off(pos)` · `on_actor_hid(spot, actor)` · `on_monster_talk(pos)` ·
`on_monster_noticed()` · `on_monster_repelled()` · `on_monster_uv()` · `on_monster_gone()` · `kill_guest(guest, spot)` ·
`kill_player(spot)`. Neue Spielmechaniken, die das Monster beeinflussen sollen, melden sich hier.

### Dramaturgie
- Vor dem ersten Angriff: kein Monster. Erster Angriff am 3./4. Oktober während einer Feier
  (`_first_attack_at_party`), spätestens am 5.
- Danach Wechsel `Phase.CALM` (Keller) ↔ `Phase.ACTIVE` (streift umher); Dauern über `_day_lerp`.
  `WARNING`/`COOLDOWN` sind Altlast und werden nicht mehr benutzt.
- `attacks <= HARMLESS_ATTACKS` (2) → `is_harmless()`: es holt niemanden, `kill_*` werden zu
  Erschrecken (`_scare_guest`) bzw. Zeigen (`_reveal_to_player`).
- **Absicht** (Spielkonzept 4.17): `_start_activity` → `_choose_intent` setzt `victims_left`: 0 (umsehen) oder – mit
  `attack_chance()`, gleitend nach Tag aus `ATTACK_CHANCE` – `_draw_victims()` – n ∝ 1/n², höchstens `_max_victims()` (lebende Gäste + Spieler).
  `intent` (`ROAM`/`ONE`/`RAMPAGE`) folgt nur daraus (`_intent_for`). `kill_*` holen nur, wenn `wants_victim()` (nicht harmlos und
  `victims_left > 0`), sonst Erschrecken/Zeigen wie bei harmlosen Angriffen – gilt für Spieler und Gäste.
  Raubzug: nach einem Opfer `Monster.after_kill_hunting()` (weiterstreifen, keine Sättigung), erst das
  letzte macht satt (`after_feeding`). Satt (`satiation > SATED_ROAM`) → immer `ROAM`. Sichtung/Gerede
  können `ROAM` per `_escalate` zu `ONE` machen. `victims_left` und `_uv_angry` stehen im Spielstand.
- **Flackerwelle**: `_start_wave(ursprung, opfer)` – Dauer `SIGNAL_BASE + SIGNAL_PER_VICTIM × opfer` (1 + 2 × n s),
  Stufe `_wave_level` 0 / 1 / ab 2 Opfern (Stärke, Untertitel, Gäste, `long_signal_near`); `wave_delay(p)` = Weg vom Ursprung (Keller)
  über das Stockwerk, ins Obergeschoss über `_stairwell`, durch `WAVE_SPEED`. Jede Lampe bekommt
  `FlickerLight.wave` (getrennt von `flicker`, damit die Welle keine Birnen durchbrennen lässt). Angezeigt
  wird `shown_victims` – das kann gelogen sein (0) (`DECEIVE_CHANCE` × Dreistigkeit). Beim Spieler:
  Bildflackern, `SynthAudio.buzz`, Untertitel. Gäste bekommen `Guest.on_flicker_signal(stufe, verzögerung)`.
  Halluzination startet manchmal eine Welle mit `fake = true` (Gäste reagieren nicht). Nicht gespeichert.
  Folgen: `is_signalling()` sperrt das Tagebuch, `long_signal_near()` bricht Würfelpartien ab.
  Der erste Angriff bei der Feier hat keine Welle.
- Haunting (Türen, Vorhänge, Licht, Betten, Zimmer 13) nur, wo der Spieler nicht hinsieht (`_unseen`).

### Monster-Zustände
`INACTIVE, PATROL, INVESTIGATE, LURK, STARE, SEARCH, CHECK_HIDE, CHASE, REPELLED, RETREAT, KILL, SLINK, REVEAL`.
Wechsel nur über `_set_state()` (setzt Zustands-Timer zurück). Von außen: `start_roaming`,
`investigate`, `go_check`, `stare`, `go_home`, `spawn_at` (Tests), `spawn_near_unseen`, `deactivate`.
Sieht der Spieler es ohne Jagd länger als 0,35 s → `SLINK` (aus dem Blick verschwinden).
UV-Licht: `uv_flinch()` (im Kegel langsamer), `uv_repel()` → kurz `REPELLED`, dann `RETREAT` mit
`_fleeing` (Jagdtempo, `_calm_retreat`: jagt niemanden).
**Abschreckung** (`_check_deterrence`): Deko + Licht blockieren nur, wenn das Ziel (`_goal()`) selbst im
Schutz liegt – vorbeigehen darf es (die Deko vor den Türen deckt sonst den ganzen Flur ab). Beim Jagen gilt
`is_protected(Gejagter)`. Zurückgeschreckt ohne UV → anderes Ziel (`_next_roam`), der Gejagte kommt für
`REBUFF_TIME` in `_rebuffed`; nach `LURK` ebenso weiter. **Rückzug (`RETREAT`) nur:** Ende der Aktivphase
(`go_home`), satt (`after_feeding`), UV. Nach einem harmlosen Schreck `after_scare(opfer)` → `SLINK` und
weiterstreifen; das Opfer steht bis zur nächsten Aktivphase in `_spared`.

### Aussehen & Animation
- **Modell:** `assets/models/monster.glb` wird von `tools/build_monster.py` (Blender 4.3) aus dem
  Meshy-Original (`assets/source/`, nicht im Repo, `.gdignore`) gebaut: auf 8000 Dreiecke reduziert, Blick nach −Z, ~2,15 m hoch, 512er-Farbtextur,
  Skelett mit 24 Knochen (`hips` … `toe.R`, linke Seite bei −X). **Grundpose = aufrecht**, die
  ursprüngliche Hocke auf allen Vieren steckt als Animation `crouch` (ein Bild) in der Datei.
  Neu bauen: `blender -b --python tools/build_monster.py -- <meshy.glb> assets/models/monster.glb`.
  Die Augenpositionen druckt das Skript aus → `Monster.EYES`. Die von Godot entpackte Textur
  (`assets/models/*.jpg`) ist in `.gitignore`.
- **Animation ist Code:** `_animate()` setzt alle `ANIM_STEP` (0,09 s, Stop-Motion) eine neue Pose.
  Pro Knochen wird aufrecht ↔ Hocke gemischt (`_crouch`, Ziel aus `_crouch_target()`: `SLINK` auf
  allen Vieren, `LURK`/`CHECK_HIDE` halb, an Türen geduckt), darauf kommen mit `_turn(knochen, achse,
  winkel)` Gang, Vorbeugen, Arme, Kopf, Kiefer und Zunge. `_turn` dreht um Achsen im **Modellraum**
  (die Knochenachsen aus Blender sind uneinheitlich) – Eltern immer vor Kindern drehen.
- Der `AnimationPlayer` aus der GLB wird nur ausgelesen und dann gelöscht. Material: `Mat.psx` mit
  der Modelltextur. Augen hängen per `BoneAttachment3D` am Knochen `head`.
- Kollision und NavMesh-Agent bleiben 1,6 m hoch. Türen sind 2,1 m hoch → `_near_door` lässt es
  sich ducken. `EYE_HEIGHT` (2,1 m) ist auch die Höhe für seine Sichtprüfungen.

## 6. Gäste & Soziales

- **`GuestProfiles`**: feste Gäste in `ALL`, erzeugte in `static var generated`; Zugriff immer über
  `GuestProfiles.get_profile(id)`. Alle Profile haben dieselbe Form (Werte, `activities`-Gewichte,
  `dice`, `lines`). Sätze über `guest.line(key)`.
- **`GuestGenerator.make(seed, room, arrived_room)`**: deterministisch aus dem Seed.
  **Achtung:** Die Reihenfolge der `rng`-Aufrufe in `make()` bestimmt, wer der Gast ist. Neue
  Zufallswerte nur **ans Ende** anhängen, sonst werden aus gespeicherten Seeds andere Gäste.
  `name_for(seed)` verlässt sich darauf, dass der Name die **erste** Zufallszahl ist.
- **Aussehen** (Spielkonzept 6.0, „Gastmodelle“): `GuestBody.pick(profile, id)` wählt für erzeugte Gäste einen
  Grundkörper aus `GuestBody.BODIES` passend zum Geschlecht des Namens (`GuestGenerator.FEMALE`), reihum nach der
  Gastnummer. Ohne passenden Körper (feste Gäste, Frauen bis es Modelle gibt) bleibt die Klötzchenfigur
  (`_build_blocks`). Je Gast aus dem Profil: `height_cm`, `width_cm` (Breite nur in `WIDTH_LIMIT`, Kopfknochen
  gegengestreckt), `build`, Farben `coat`/`pants`/`hair` als Instanz-Uniforms von `psx_guest.gdshader`
  (färbt nur graue Texel, Farbe × Helligkeit / Mittelwert). **Bewegung:** `walk`/`run` aus der GLB
  (`AnimationPlayer` manuell vorgespult, Tempo nach Laufweite × Größe), im Stand Ruhepose mit Atmen. Die Posen
  in `Guest._pose()`/`_dance_pose()` drehen weiter nur die Pivots `_arm_l`/`_arm_r` (beim Modell unsichtbar);
  `GuestBody` richtet die Oberarmknochen danach aus (`_aim`), außer `_arms_free` (normales Gehen/Stehen).
  Sitzen: Beine angewinkelt, Absenken über `sit_drop()`.
- **`Guest`**: Zustandsautomat (`IDLE, WALK, CARRY_HOME, PLACE_DECO, HARVEST, STEAL, HIDE_GO, HIDING,
  PARTY, TALKING, MINIGAME, DEAD, KNOCK, SHELTER, SLEEP, SHOCKED, GHOSTED`). In `IDLE` wählt `_next_activity()` gewichtet aus
  `profile.activities`; `_arrive()` verarbeitet das Ankommen je Zustand.
- **Nachtruhe** (Spielkonzept 4.18): `Social._update_sleep` startet sie zu zufälligen Zeiten (`SLEEP_GAP`,
  nie in einer Feier) für `SLEEP_TIME` → `Guest.bedtime()`: ins Zimmer, Licht aus, still ins eigene Bett
  (`hiding` = Bett, aber Zustand `SLEEP` – kein Versteck-Lärm, kein `_watch_monster`; das Monster kann sie im
  Bett finden). Sie bleiben sichtbar und liegen auf dem Rücken auf der Matratze (`BED_FEET`/`BED_TOP`, Kopf zum
  Kissen = lokal −X des Betts; Pose in `_pose`, wie die Leiche um X gekippt). Wer redet, spielt, klopft oder sich versteckt, geht danach (`_next_activity`). Ende →
  `wake_up()`. `Social.all_asleep()` für den Lakengeist im Flur. Gespeichert: `sleep_active`, `sleep_timer`
  (Gäste laden wach und gehen wieder ins Bett).
  **Der Spieler schläft mit** (4.18): Nur das Bett mit `HideSpot.own_bed` (Zimmer 13, gesetzt im LevelBuilder)
  bietet während der Nachtruhe „Schlafen“ an (geduckt: darunter kriechen). `Player.start_sleep()` =
  `enter_hide()` + `sleeping` + Zeitraffer + Overlay-Modus 3 (Augen zu); man liegt wie in einem Versteck im
  Bett, das Monster kann einen dort finden. Aufwachen (`wake_up`, bleibt im Bett): Monster nah
  (`player_threat` > `SLEEP_WAKE_THREAT`) oder ein fremdes Geräusch mit Lautstärke ≥ 0,3 (`Game.noise`).
  Ende der Nachtruhe → `Player.on_night_over()` (vor `Guest.wake_up`): ≥ `SLEEP_MIN` Spielsekunden
  geschlafen → `nights_awake = 0`, sonst +1 (erst nach dem ersten Angriff); Gedanke 3,6 s später, damit die
  Gäste-Meldung ihn nicht überschreibt. `nights_awake` steht im Spielstand unter `player`.
  Tanzen auf Feiern: `_dance_pose()` – Lieblingstanz aus `hash(id)`, alle 7–15 s Wechsel (60 % Lieblingstanz).
  Gastmodelle tanzen die Mixamo-Animationen aus `GuestBody.DANCES` (Chicken Dance, Macarena, Hip-Hop; Guest setzt
  `_body.dance`, `GuestBody` spielt sie ab zufälliger Stelle, damit nicht alle im Gleichtakt sind, und lässt die
  Arme dann in Ruhe). Die Klötzchenfigur tanzt weiter die Code-Posen aus `DANCES` (hüpfen, wiegen, drehen, arme
  hoch, twist, schunkeln); Arme drehen dabei auch um z (seitlich) – `_animate()` setzt das außerhalb des Tanzens
  zurück.
- **Schreck & Erlebnisse** (Spielkonzept 6.12): Was erschreckt, steht in der Gruppe `shock_sights` mit Meta
  `sight_key`/`sight_kind` – Blutlachen (`Traces._as_sight`, Schlüssel aus dem Ort, auch nach dem Laden) und Leichen
  (`Guest._lie_down`, `corpse:<id>`). `Guest._scan_for_shock` alle 0,5 s (≤ 7 m, Blickfeld, Sichtlinie), jeder Schlüssel
  einmal (`seen_sights`) → `shock()`: Zustand `SHOCKED` für 2–5 s (`brave`), Haltung aus `_shock_pose()` je
  `shock_style()` (`profile["shock"]` bzw. `SHOCK_STYLES` nach Archetyp – keine neuen Zufallszahlen im Generator),
  danach `_after_shock()` (flee → verstecken, cry → heim, freeze → weiter). `remember()` legt ein Erlebnis an
  (`experiences`: kind, zone, who, at = `Director.elapsed`, told); `DialogUI.open` erzählt das älteste unerzählte
  (`Social.experience_line`), `_talk_monster` am selben Spieltag (`recent_experience`) noch einmal. Wer den Geist
  erlebt hat (`remembers("ghost")`), ruht nicht im Dunkeln und zieht den Vorhang zu. Leiche: `die("ghost")` –
  sichtbar, gekippt, ohne Kollision; `on_guest_died(guest, "ghost")` ohne Schrei/„verschwunden“.
- **`Social`** ist der Ort für alles zwischen Gästen und Spieler: Gästeliste (`guests`,
  `living_guests()`, `guest_by_id()`), Beziehungen (`change_relation`), Gerüchte mit Verzögerung,
  Diebstahl mit Zeugen, Reservierung von Verstecken (`find_hide_spot` / `release_hide_spot`),
  Feiern, Herausforderungen (`challenge(guest, game)`, `Guest.challenge_game`), Gäste-Mäxchen und Gäste-Schach
  (`_update_chess_game`, Zuschauen ≥ 30 s → `has_watched_chess`), Berichte über Spuren (`note_trace` → `report_line`),
  Klopfen an Zimmer 13, Zettel, Neuankömmlinge (`START_GUESTS` 30, `MIN_GUESTS` 24).
- **Freundschaftsstufen** (Spielkonzept 6.3): `Social.Tier` (9 Stufen, `tier(guest)` / `tier_of(wert)`,
  Grenzen −80/−55/−30/−10/10/30/55/80, Namen `TIER_NAMES`). **Im Code nie mehr `relation` mit Zahlen
  vergleichen, sondern Stufen** (`Social.tier(g) >= Social.Tier.FRIEND`). `change_relation` dämpft Zuwächse
  (× 1 − Wert/110) und deckelt bei ±79, solange die Taten fehlen: `Guest.deeds` (`games`, `gifts_to`,
  `gifts_from`, `hostile`, `revenge`; `add_deed`) gegen `BOND_*` bzw. `FEUD_*`. Taten zählen in
  `DiceMatch`/`ChessMatch._finish` (Partie), Dialog (Geschenk, Deko erbeten, Kauf, Beleidigen), `on_player_took`
  (Diebstahl), Gast klaut/Birne aus 13 (`revenge`), Rammen, Schlagen. `_update_bonds`: Zerfall der Extreme
  (`DRIFT`), Besuche (`_update_visits` → `Guest.start_visit` → `on_visit_arrived`: offene Tür → `enter_shelter`,
  sonst höfliches Klopfen über `_knock` mit `"visit"`, eigene `_visit_step`) und Erzfeinde (`_update_feuds`, alle
  2 s: allein und sichtbar → erst Drohung `threatened`, beim nächsten Mal `Guest.start_attack`). Plaudern zählt
  pro Spieltag `CHATS_PER_DAY` mal voll (`Guest.chat_day/chats_today`). Neue Gast-Zustände `FOLLOW` (bleibt
  `FOLLOW_GAP` hinter dir; im Gespräch gemerkt über `_resume_follow`), `VISIT`, `ATTACK` (rennt hin, `Player.hurt`,
  dann heim), `STAGGER` (Rückstoß `_push`, danach `_after_stagger`: zurückschlagen bei Mut ≥ 0,55, Stolz ≥ 0,65 oder
  „verfeindet“, sonst verstecken; geschlagen humpelt er `HURT_TIME` mit `HURT_SLOW`). Wütende halten im Gehen auf den
  Spieler zu und rempeln ihn an (`_wants_to_bump`/`_check_bump` → `Player.shove`).
- **Spieler schlägt und rammt** (`player.gd`): Linksklick (`use_item`) schlägt, wenn `_punch_target()` einen Gast
  in `PUNCH_REACH` im Fokus hat und keine Taschenlampe in der Hand ist (sonst wie bisher Lampe); außer bei
  „wütend“ und schlimmer erst nach Nachfrage (zweiter Klick in `PUNCH_CONFIRM_TIME`) → `Social.on_player_punched`
  (höchstens „wütend“, Zeugen −10, Gerede, Lärm `punch`). Rennen gegen einen Gast (`_check_ram`) →
  `on_player_rammed`. `injury` (0..1, gespeichert) macht langsamer (`INJURY_SLOW`), heilt in `INJURY_HEAL_TIME`;
  nach einem Treffer `BLEED_TIME` Blutstropfen (`Traces.add_guest_drop("drops")`), roter Blitz `Hud.flash_hurt`.
- Gäste melden sich mit `Game.social.on_*` (Diebstahl, fehlende Deko/Birne, Monster gesehen …).
- **`HotelCat`** (`guests/hotel_cat.gd`, Spielkonzept 6.11): drei Katzen aus `HotelCat.PROFILES`, erzeugt in
  `main.gd` nach den Gästen (`place_at_start()`; Lieblingsgast = `hash(id)` über die lebenden Gäste).
  Zustände `IDLE, WALK, SLEEP, FLEE, WAIT_DOOR, PET, FOLLOW, GIFT, FETCH` (holt Gast-Deko, `Social.cat_thefts`); Bewegung wie Gäste (NavigationAgent,
  Festgefahren-Erkennung). **Türen:** Kollisionsmaske ohne Türen (wie Gäste), geschlossene Türen erkennt
  `_door_ahead()` → `WAIT_DOOR` (miaut, gibt nach 12–20 s auf und schläft) bzw. auf der Flucht `_cowering`.
  **Möbel:** `perches()` = `LevelBuilder.cat_perches` (Sofas, Rezeption) + Betten und Fensterbänke aller
  bewohnbaren Zimmer + Lobbyfenster (`{floor, top, yaw?, room?}`, feste Reihenfolge – der Index wird
  gespeichert); gewählt wird über `_usable_perches()` (Lobby, Zimmer 13, bewohnte Zimmer); hoch/runter per Tween (`_hop`), oben ohne Schwerkraft. **Monster:** `_monster_near()`
  auch, wenn es unsichtbar umherstreift → `FLEE` mit Lärm `cat_cry` (Art mit `alarm` → Gäste); der
  Director ignoriert Lärm mit `quelle is HotelCat`, das Monster sieht Katzen nicht (eigene Ebene).
  **Deko umwerfen:** `_check_surroundings()` alle 0,4 s, `Item.knock_over()` für `Item.TOPPLE_KINDS`;
  `Item.is_toppled()` zählt nicht in `deco_strength_at`, Spieler stellt per [E] auf, Gäste in `_at_home()`.
  **Aussehen:** Laufen = Animation `walk` (`speed_scale` nach Tempo), sonst `_player.stop()` und Posen aus
  `POSES` per `_turn()` im Skelettraum (X = linke Seite, Y = oben, Z = Blickrichtung), weich überblendet;
  Fell = `Mat.psx(tint)` mit der GLB-Textur. Geschenk hängt am Knoten `_mouth`. Gespeichert (Gruppe `cats`,
  ab Version 8, angewendet nach den Gegenständen): Lage, Lieblingsgast, Zuneigung, Geschenk-Timer,
  Liegeplatz, Schlaf, Beute im Maul (liegt nach dem Laden vor ihr). Gespräche: `Social.cat_line()`
  (Plaudern), `Social.cat_monster_line()` (nach dem ersten Weinen, `cats_have_cried`).

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
- Speicherbare Welt-Objekte bieten `save_state() -> Dictionary` / `load_state(d)` (HideSpot, Lamp, HotelPhone,
  LightSwitch, HotelWindow, Dresser) oder werden in `collect()` direkt ausgelesen (Door, Chest, Plant, Resource).
  Neues Objekt mit Zustand: Gruppe + Eintrag in `collect()` und `apply()`.
- Beim Laden: `d.get(key, standard)` verwenden, damit fehlende Schlüssel nicht abstürzen.
- Je Gast außerdem (ab Version 11) `corpse` (tote Gäste mit Leiche → `die("ghost")`), `ghost_visits`, `seen`
  (gesehene Blutlachen/Leichen) und `experiences` (Zeitpunkte als `Director.elapsed`).
- Speichern am Tagebuch gesperrt bei Jagd oder Monster näher als `NOISE_START`; Autosave nur in
  sicheren Momenten (`is_safe_for_autosave`), sonst aufgeschoben.
- **Prüfen:** `--savetest` sammelt → wendet an → sammelt erneut und meldet Unterschiede.

## 8. Weitere Systeme (Kurzüberblick)

| System | Datei(en) | Merkpunkte |
|--------|-----------|------------|
| Licht | `lamp.gd`, `light_switch.gd`, `flicker_light.gd`, `util/shadow_budget.gd`, `level_builder.gd` (`_wall_lamp`, `_candle`) | Lampe = Fassung + Birne (Item `BULB`); `flicker` (Nähe des Monsters, kann Birnen durchbrennen) und `wave` (Flackerwelle, 4.17) setzt der Director; nur die 6 nächsten Lampen werfen Schatten; Licht aus → `on_lights_off`. **Seit 2026-10-17 keine Deckenlampen mehr** (`Lamp.Style.CEILING` und `_lamp` sind noch da, aber nicht verbaut): jeder Raum hat mindestens eine Wandleuchte (`WALL_LAMP_ENERGY`, Lobby ×1,3), sonst schaltet sein Schalter nichts. Zimmer haben zwei hellere (`ROOM_LAMP_ENERGY`, Tür- und Fensterwand) und eine hellere Holzdecke (`_room_ceiling`) als die Flure (`_ceiling`, abgedunkelt). Feste Deko-Kerzen (`_candle`, `CANDLE_ENERGY`, kein Item, nicht gespeichert, in `lamps` → flackern mit) auf Flurkommoden, Bank, Lobby, Theke und Zimmertischen (nicht in dunklen/unbewohnten Zimmern) sind mit den Kürbissen die hellsten Lichter. Wandleuchten und Laternen laufen zusätzlich durch `Lamp.BRIGHTNESS` (Stärke ×1,35) und `Lamp.REACH` (Reichweite ×1,3). Umgebungslicht 0,14 und Mond 0,32 (`main._setup_environment`), damit dunkle Ecken als Umriss bleiben und die Nacht nicht pechschwarz ist. Helligkeit nachjustieren: `BRIGHTNESS`/`REACH` für alle Lampen gemeinsam, sonst die drei Konstanten, die Deckenfarben, Umgebungslicht und Mond |
| Fenster | `hotel_window.gd` | klares Glas / Vorhang (Ebene 10 nur für Sicht & Mond); Milchglas kann die Klasse noch, ist aber nicht mehr verbaut |
| Türen | `door.gd` | Blatt auf Ebene 2 (Glastür 7); Rahmen über `OpeningFrame` (Zarge, Bekleidung, Kopfpartie auf beiden Wandseiten, nur Optik). Spuren über `attach_mark(mark, seite, at)` – Kratzer mittig, Handabdrücke (`Traces.add_door_handprint`) höher; `at` wird mitgespeichert |
| Spuren | `traces.gd`, `trace_mark.gd` | zentrale Stelle für alle Spuren; jede neue Spur → `Social.note_trace`; Fußabdrücke verblassen, Marken bleiben |
| Zettel | `warning_note.gd` | feste Warnungszettel (`warning_notes`, erst nach dem 1. Angriff sichtbar) und Gäste-Zettel (`guest_notes`, max. 30) |
| Kommoden | `world/dresser.gd` | Aus dem Plan (Ebene `Möbel`, `LevelBuilder._furniture`). Drei Schubladen als eigene Körper; interagierbar ist je ein `Dresser.Handle` (leitet mit Index weiter). Hohler Korpus, damit die Physik Gegenstände nicht aus geschlossenen Schubladen drückt. Fund nur beim **ersten** Öffnen einer Schublade (`searched`): leer / Münzen / Gegenstand aus `LOOT`. Beim Auf-/Zuschieben werden die darin liegenden Gegenstände kurz kinematisch eingefroren und mitbewegt (Ausnahme von „nie `freeze` direkt“ – sie liegen nicht in der Hand). Lärm `drawer`. Gespeichert: `open`, `searched` (ab Version 7) |
| Verstecke | `hide_spot.gd` | `occupant` reserviert; `seen_entering` = Todesurteil; `checked` als Spur; `own_bed` = Bett in Zimmer 13 (Schlafen, 4.18); `rattle()`/`burst_open()` für den Lakengeist |
| Am Körper | `player.gd` (`_pocket`, `_update_hand`, `set_pockets`), `player/pocket_map.gd` | `Item.goes_to_pocket()` (Kompass, Kartenblatt, Schlüssel außer `HAND_ONLY_KEYS`): `try_pick_up` löscht den Welt-Gegenstand und trägt ihn in `has_compass`/`map_pages`/`keyring` ein – braucht keine freie Hand. Linke Hand (`_left_hand`) für Aktionen `map` (Tab) und `compass` (F), nicht bei `hands_blocked()` oder im Gespräch; `inspecting` halbiert das Tempo. Türen fragen `player.has_key(id)`. Gespeichert unter `player` |
| Kompass | `item.gd` (`Kind.COMPASS`) | Nadel = Feder Richtung Welt −Z (Norden), gestört über `director.threat_at()` und – nur eingesteckt (`pocketed`) – `is_hallucinating()`; der Kompass in der linken Hand ist ein `Item` mit `make_pocketed()` (raus aus Gruppe `items`); liegt in `LevelBuilder.COMPASS_ROOM` |
| Karte | `world/hotel_map.gd`, `item.gd` (`Kind.MAP`, `extra` = Blatt-ID), `player/pocket_map.gd` | `HotelMap.PAGES` = Blätter (id, Titel, Höhenbereich, Geschoss oder eigene Zeichnung); gedruckter EG-Plan aus `assets/maps/eg.json` (neue Zimmer erscheinen von selbst), OG-Blatt bislang nur mit der Galerie, Kellerskizze von Hand gezittert (Lage aus dem Treppenhaus Ost). Alle Blätter einmal untereinander in einem SubViewport gerendert → geteilte `ImageTexture` (ohne Grafik: nur Papierfarbe); `HotelMap.material(id)` schneidet per `uv1_offset` aus. `PocketMap` = Blätterstapel in der linken Hand, Schlüsselblatt (`KEYS`) zuletzt; beim Hervorholen oben das Blatt zu `HotelMap.page_at(y)`. Neue Ebene: Eintrag in `PAGES`, Zeichnung in `_draw()`, Blatt im `LevelBuilder` auslegen |
| Lakengeist | `monster/sheet_ghost.gd`, `shaders/psx_ghost.gdshader`, `traces.gd` (`add_window_handprints`) | Spielkonzept 4.18. `Game.ghost`, eigener Knoten neben dem Monster, kein NavMesh und keine Kollision (schwebt durch Glas und Vorhang). Prüft alle 0,5 s `_window_near()`: Außenfenster mit Vorhang, ≤ 7 m, freie Sicht, alle `lamp_fixtures` mit dieser `room_id` aus, Vorhang offen (ab `THROUGH_CURTAIN_FROM` egal). Gewürfelt wird je neuem Fenster (`_last_window`, `SPAWN_CHANCE`) und, solange der Spieler dort bleibt, alle `STAY_EVERY` s erneut (`STAY_CHANCE`, `_stay`); nicht während Rauschen (`player_threat`), nicht in Gesellschaft, erst ab Tag `FROM_DAY` (2) oder nach dem ersten Angriff (`_haunting()`, gilt auch für Gäste). Abklingzeit `COOLDOWN` 45 s, Schweben `FLOAT_SPEED`/`INSIDE_SPEED` 1,6/1,1 m/s. `visits` = Stufe (gespeichert unter `ghost`, dazu die Abklingzeit; laufende Auftritte nicht). Zustände `APPROACH → HOVER → ENTER → STRANGLE` (dazu `LURK → FLY_IN` am Schrank), Ende immer über `FADE` (0,5 s, Raster-Ausblenden im Shader statt Transparenz). Spieler: `trance` (macht langsamer, `TRANCE_SLOW`), `gripped` (steht fest), `move_input` (auch im Versteck, solange `gripped`). **Losreißen** (`_struggle`): Balken `_escape`, je Richtungswechsel `ESCAPE_GAIN`, der Griff zieht `ESCAPE_GRIP` je Sekunde ab (ab dem 4. Mal fester), `ESCAPE_TIME` 3 s – erst ab ~6,5 Wechseln/s schaffbar; HUD-Balken `Hud.set_struggle()`. Solange `gripped`, gehen weder [E] noch die Versteck-Zeitgrenze. **Schrank** (`_lost_victim` → `_start_lurk`): Versteckt sich der Spieler in einem Schrank, wenn er ohnehin hereinkäme (ab `ENTER_FROM`, im Flur), wartet er `LURK_TIME` vor `check_point` und rüttelt (`HideSpot.rattle()`). Kommt der Spieler heraus → `ENTER` (packt sofort zu); keucht er (Atem leer) → sofort `FLY_IN`; sonst Wurf `FLY_IN_CHANCE` (ab `HALL_FROM` `FLY_IN_CHANCE_LATE`, + `FLY_IN_PER_NIGHT` je Nacht ohne Schlaf, angehaltene Luft senkt sie um bis zu `BREATH_SAVES`). `FLY_IN`: `HideSpot.burst_open()` (Lärm `rattle`, nicht `hide_burst` – lockt das Monster nicht), schwebt an den Hals, würgt im Schrank; losgerissen → `exit_hide()`. Unterm Bett verschwindet er wie bisher. Tod über `Game.game_over` + `director.flash()` + `player_died`. Knochen werden pro Frame aus der Ruhepose gedreht (`_pose`: Schweben, Saum, Handkreisen, Krallen). Flur: ab `HALL_FROM` (6.) Mal, nur wenn `Social.all_asleep()` und der Spieler in einer „Flur“-Zone steht, `HALL_CHANCE` je Sekunde; taucht an einem Patrouillenpunkt 8–16 m entfernt außer Sicht (auch keines wachen Gastes) auf und kommt gleich auf ihn zu. **Schlafmangel** (`Player.nights_awake`): Fensterchance + `AWAKE_CHANCE` je Nacht, Abklingzeit beim Spieler `COOLDOWN / (1 + n)`, Flurchance × (1 + n), ab `AWAKE_HALL_FROM` (2) auch vor dem 6. Mal, ab `AWAKE_SURE` (3) sicher im Flur, sobald kein wacher Gast den Spieler sieht – auch ohne Nachtruhe; Zeugen vertreiben ihn trotzdem. **Gäste als Opfer** (6.12): `_victim` (Player oder Guest), `_stage` = Zähler des Opfers (`visits` bzw. `Guest.ghost_visits`); `_check_guests()` würfelt wie beim Spieler je neuem Fenster pro Gast (`_guest_windows`), Augenpunkt `Guest.eye_height()`. Der Gast sieht ihn (`_guest_sees_me` → `shock("ghost", …, entranced)` ab Hypnose-Stufe: bleibt stehen), `ghost_grab()` → `GHOSTED`, Losreißen nach Zufall (`GUEST_ESCAPE`: 5 % + 20 % × `brave`), sonst `_kill_guest()`. Bei Gästen zählt der Spieler als Zeuge (außer `debug_ignore_player`); Zeugen, die ihn vertreiben, erschrecken. Noch nicht: Einstellung für den Blickzug |
| Taschenlampe | `world/flashlight.gd`, `world/uv_mark.gd`, `item.gd` (`FLASHLIGHT`, `BATTERY`, `UV_FILTER`) | `Flashlight` hängt als Kind am Item (`item.flashlight`), Zustand steckt in `create_extra()` (`"c=0.42;uv;m=uv;on"`), also kein eigener Speicher-Eintrag. Bewusst **ein `SpotLight3D` außerhalb von `light_source`** – zählt nicht für Helligkeit/Abschreckung (`light_at` castet ohnehin auf `OmniLight3D`) und nicht als `item.lit` (sonst bläst das Monster sie aus, Gäste tropfen Wachs …). Auffälligkeit über `flashlight.carried_conspicuity()` in `Senses.conspicuity`. Nur in der Hand des Spielers: UV prüft alle 0,1 s die Gruppe `uv_marks` (Kegel + Sichtlinie `SIGHT_MASK`, `UvMark.shine()`) und jeden Frame das Monster (`can_be_repelled_by_uv`, Brust im Kegel) → nach `director.uv_repel_time()` `on_monster_uv()`. Einsetzen von Batterie/UV-Aufsatz in `Item._fitting_prompt/_fit` (nur eigene oder herrenlose Teile). `UvMark`: Leuchtschrift (`setup_text`, im LevelBuilder `_uv_writing`) oder Kästen (`add_box`, Nachglanz der Fußspuren in `Traces`); läuft nur, solange es leuchtet. Warnungszettel: `NOTES[id]["uv"]` |
| Kalender | `calendar.gd` | statische Datumsfunktionen + Abreißkalender in Zimmer 13 |
| Telefone | `world/hotel_phone.gd`, `guests/phone_calls.gd`, `ui/phone_ui.gd` | `HotelPhone` auf jedem Zimmertisch (nicht Wäscherei) + Haupttelefon an der Rezeption (`room_id` `"lobby"`, Nummer `"0"`); gespeichert wird nur `off_hook` (Gruppe `phones`, ab Spielstand-Version 5). `PhoneCalls` (`Game.phones`) hat die Anrufe: eingehend nur für Zimmer 13 (warnen/lügen/plaudern/unheimlich), ausgehend per Wählseite, ferne Telefone als Atmosphäre. Jedes Klingeln = `Game.noise("phone", …)`. Telefonsätze in `PhoneCalls.LINES`, eigene als `"phone_<key>"` nur in den festen Profilen – **nicht** in `GuestGenerator.COMMON` (verschiebt die Zufallsfolge). Unheimliche Anrufe hinterlassen einen Hörer neben dem Apparat im Herkunftszimmer. Laufende Anrufe werden nicht gespeichert |
| Mäxchen | `minigames/` | `Maexchen` = Regeln, `DiceMatch` = Partie & Gast-KI, `GameTable` = Tisch; Würfeln macht Lärm (`dice`). Einsätze über `TableStakes` (auch Schach: `place`, `take_for_player`, `give_to_guest`, `abandon`, `split` bei Remis) |
| Schach | `minigames/chess*.gd`, `tests/chess_*.gd` | Spielkonzept 6.10. `Chess` = Regeln als reine Daten (Felder 0–63, Züge als Bitfeld, deutsche Notation, Perft). `ChessAI` = Alpha-Beta + Ruhesuche, Bewertung Material + Feldboni; rechnet in einem `Thread` (`think` / `is_done` / `take_move`, `cancel` beim Abbruch). Stärke aus `profile["chess"]["skill"]`: Tiefe 1–3 (`ChessMatch.depth_of`), Patzer 45 %→5 % plus Angst (`blunder_of`). `ChessMatch` (CanvasLayer 15) = Partie wie `DiceMatch` (Spieler Weiß, Gast überlegt mind. 1–2,6 s, gibt ohne Stolz bei < −900 auf, nimmt Remis an, wenn er nicht klar besser steht), `ChessBoardView` = Brett von oben mit Mausbedienung, `ChessTable` (erbt `GameTable`) in der Lobby, Brett = `Item.Kind.CHESS_BOARD`. Gäste: `profile["chess"]` = {likes, skill, pride}; bei erzeugten Gästen am Ende von `GuestGenerator.make()` gewürfelt, Sätze `chess_*` je Typ aus `CHESS_LINES`. Tests: `-s res://tests/chess_perft.gd` (Zuggenerierung), `-s res://tests/chess_ai_speed.gd` (Zeit je Tiefe, Matt in 1) |
| UI | `ui/` | `UiKit` = Meldezettel-Optik für Menüs; `Hud` Prompt/Meldungen/Debug (F3); `Menus` pausiert; `TeleportUI` = Debug-Teleport (F6), Ziele in `_destinations()` aus dem `LevelBuilder` (`find()` für `--tp`); `DebugConsole` ([^]/F1, nur Debug-Build oder `--debug`) = Startparameter im Spiel tippen: `submit()` → `main.run_debug("--name=wert")`, Aktion schließt die Konsole, Auskunft (`help`, `guests`) und Fehler bleiben stehen; Verlauf als `static var` |
| Optik | `util/mat.gd`, `shaders/` | Materialien immer über `Mat.psx(...)` (Vertex-Snapping über Shader-Global `psx_snap`); flache Auflagen auf anderen Flächen (Teppich, Türkassetten, Rahmen mit kleinerem `pull`) über `Mat.layer(...)`, sonst flimmert die Unterlage durch. `Geo.box` unterteilt Flächen in ≤ 1-m-Stücke, damit große Böden beim Snapping nicht schwimmen. Glasscheiben sind einzelne Flächen (`QuadMesh`), keine Boxen; Post-FX: Gamma, Dithering, Rauschen, Flackern. **PS1-Look aus** (`Settings.psx_look`, Debug `--no-psx`): 3D in Fensterauflösung (`CONTENT_SCALE_MODE_CANVAS_ITEMS`, Bedienoberfläche weiter auf 480 × 270 ausgelegt), kein Snapping/Dithering, `color_levels` 255; Filter-Hinweise lassen sich nicht per Uniform schalten, darum schreibt `Settings._apply_texture_filter` den Code der geteilten Shader in `PSX_SHADERS` von `filter_nearest` auf `filter_linear_mipmap` um (neuer PSX-Shader mit Textur → dort eintragen). Die Tapete liest per `texelFetch` und filtert über das Shader-Global `psx_smooth` bilinear von Hand; ihre Glanzkanten bleiben texelgenau. **Nebel** (`main._setup_environment`): Tiefennebel 4 → 66 m bis Schwarz, Volumennebel nur auf 12 m (sonst verschleiert Lampenlicht das Flurende beige); `camera.far` = 70 m knapp dahinter, weil `player_can_see` am Frustum hängt. **Tapete** = `Mat.wallpaper(wandhöhe, stockwerk, variante)` mit `shaders/psx_wall.gdshader`, einziges Material mit Glanz: Das Bild (512², Wandansicht) wird auf 256² verkleinert und in drei Bändern in Metern ab Stockwerksboden (`mod(y, stockwerk)`) aufgetragen – Vertäfelung unten, Rauten (eine 128-px-Wiederholung, `WALLPAPER_FIELD`) dazwischen, Leiste unter `wandhöhe`. Lobby hat ein eigenes Material (5 m, rot); ihre Wand zu Küche und Bar ist per `Mat.wallpaper_split(a, b, normale)` auf der Seite mit Normale +Z teal und 3,5 m hoch – so für jede Wand zwischen zwei Räumen mit anderer Tapete oder Deckenhöhe. Zimmerreihen (`_room_row`): Trennwände und Rückwand ganz beige, Flurwand und die beiden Endwände geteilt (Zimmerseite beige, Normale in Weltkoordinaten); Trennwände beginnen erst in der Flurwand, sonst flimmert ihre Stirnseite im Flur. Aus der Höhenkarte entsteht beim ersten Aufruf eine Oberflächentextur: R = Höhe → Normale aus dem Sprung zum Nachbar-Texel (Glanzkanten, `bump_depth`), G = Glanz je Graustufe (`WALLPAPER_GLOSS`) → Rauheit (`specular_toon`) und Rim-Schimmer. Flecken/abgegriffener Sockel per Rauschen im Shader. Neue Farbvariante: Bild mit gleichem Aufbau als `wallpaper_<name>.png` ablegen; neue Höhenstufe im Bild → Eintrag in `WALLPAPER_GLOSS` |
| Geometrie | `util/geo.gd` | `Geo.solid(parent, größe, pos, mat, ebene)` für Kollisionskästen, `Geo.mesh` für reine Optik, `Geo.collider` für Kästen ohne Mesh. **Wände** (`LevelBuilder._wall_x/_wall_z`): Kollision weiter als Kästen links/unter/über jeder Öffnung/rechts, die Optik als *ein* Mesh pro Wand (`Geo.wall_mesh`, Fläche 0 = Wand, Fläche 1 = Laibungen in Rahmenholz) mit gemeinsamen Ecken auf einem Raster aus Wandenden, Öffnungskanten und ≤ 1-m-Schritten – getrennte Kästen stießen mit Ecken mitten auf Nachbarkanten, beim Snapping klafften dort Fugen und die Tapete war versetzt |

## 8a. Lärm & Sichtbarkeit (`scripts/util/senses.gd`, Spielkonzept 4.15)

Alle Werte stehen in `Senses`: die Lärmtabelle `NOISE` (Art → Hörweite in m, Geräusch, Lautstärke,
`alarm`), Dämpfung, Auffälligkeit und Grundweiten der Beobachter.

**Lärm:** `Game.noise(art, ort, quelle)` ist der einzige Einstieg.
1. Spieler: hört fremde Geräusche bis zur doppelten gedämpften Hörweite (mindestens
   `PLAYER_MIN_REACH`), linear leiser; eigene (`quelle == player`) in voller Lautstärke. Rückgabe =
   gespielte Lautstärke (z. B. für Untertitel beim Telefon).
2. `MonsterDirector.on_noise`: aktiv → innerhalb der gedämpften Hörweite `investigate`, bis zum
   Doppelten nur Neugier (`Hörweite × NOISE_CURIOSITY`); ruhend → nur Lautes (≥ `Senses.LOUD`) als
   Neugier. Eigene Geräusche (`quelle == monster`) ignoriert es.
3. `Social.on_alarm` (nur Arten mit `alarm`): Gäste in halber gedämpfter Hörweite →
   `Guest.hear_alarm` (Angst ↑, Panik → verstecken, mutig → hingehen, sonst Gerücht in `_reports`
   mit `heard`, das `report_line` als „Hast du das gehört? …“ erzählt). 20 s Pause je Gast.

**Dämpfung** (`Senses.audible_range`): Strahl von Ohrhöhe (1,2 m über dem Boden des Stockwerks) zu
Ohrhöhe; jeder Treffer wird ausgeschlossen und neu geworfen (max. 4). Wand = Körper auf Ebene 1 mit
Box ≥ 2,5 m Höhe (×0,4, Ergebnis je Körper gecacht), Tür = Vorfahr `Door` (geschlossen ×0,6, offen ×1),
klares Glas ×0,6, je Geschossdecke ×0,3. Möbel, Böden und Brüstungen dämpfen nicht.
→ Wer eine neue Wand baut, die niedriger als 2,5 m ist, dämpft keinen Lärm.

**Neues Geräusch in der Welt:** Eintrag in `Senses.NOISE`, Aufruf `Game.noise(...)` mit `quelle`, wo
bekannt (sonst hört sich z. B. das Monster selbst und läuft seinen eigenen Türen nach).
Spielerschritte: `Player._on_soft_floor()` erkennt Teppich/Rasen an der `albedo_tex` des Bodens.
Gäste machen nur beim Rennen (Panik) Schrittlärm.

**Sichtbarkeit:** `Senses.can_see(beobachter, auge, blick, grundweite, kegel, akteur, bonus, …)`:
Sichtweite = Grundweite × `conspicuity(akteur)` + Bonus, dann Kegel (näher als 2 m ohne Kegel) und
freie Sichtlinie. Auffälligkeit = 1 + 1,2 × Licht am Ort (`light_at(p, skip)` ohne das eigene Licht
in der Hand) + Licht in der Hand (Kerze/Kürbis über `lit`, Taschenlampe über `flashlight`) + Rennen/Stillstehen/Ducken. Benutzt von `Monster.can_see_actor`
(auch für „beim Verstecken gesehen“: `at` = `exit_point` des Verstecks, Stillstehen zählt nicht) und
`Guest.can_see_actor` (Zeugen beim Diebstahl, abgelenkt ×0,6). Unverändert eigene Regeln:
`player_can_see` (Kamera), Gäste sehen das Monster (`_watch_monster`), Licht aus (4.4), Lauschen (4.7),
angehaltener Atem (×0,35).

**Debug:** `Game.noise_log` (letzte 5, im F3-Text des Directors), `--trace` druckt jedes Ereignis,
`--noise=art` erzeugt alle 6 s Lärm am Spieler.

## 9. Rezepte

**Neuer Gegenstand:** `Item.Kind` ergänzen (nur **ans Ende**, Spielstände speichern den Zahlenwert),
Preis in `PRICES`, Aussehen/`deco_strength` in `_build()`, ggf. `create_extra()`.

**Neues interagierbares Objekt:** Körper auf passender Ebene (meist 3 = Bit 4),
`set_meta("interactable", self)`, `get_prompt`/`interact`, Gruppe. Platzieren über den Plan: Farbe mit
Namen in die Palette (`Ausstattung: …`/`Möbel: …`), Eintrag in `FITTINGS`/`FURNITURE` von `tools/build_map.py`,
Fall in `LevelBuilder._fittings`/`_furniture`. Hat es Zustand → `save_state`/`load_state` + SaveManager +
`VERSION` erhöhen.

**Neue Gast-Aktivität:** Schlüssel in `activities` der Profile/Archetypen, Fall in
`Guest._next_activity()`, ggf. eigener `State` und Fall in `_arrive()`.

**Neuer Dialogsatz-Typ:** Schlüssel in `GuestGenerator.COMMON` (Fallback für alle) und bei Bedarf in
den festen Profilen und Archetypen.

**Neue Monster-Reaktion:** Ereignis-Funktion `on_xyz()` im Director, Aufruf von der Quelle aus.
Tuning-Konstante oben im Director.

**Neue Spur:** `add_xyz()` in `Traces`, `TraceMark`-Art, in `save_state`/`load_state` abdecken,
Text für Gästeberichte in `Social.TRACE_TEXT`.

**Neuer Debug-Parameter:** Zweig in `main.run_debug()` (gilt damit auch für die Debug-Konsole; `true` = erkannt),
Kopfkommentar in `main.gd`, Eintrag in `DebugConsole.COMMANDS` (Hilfe, Tab) – bei Gast-ID als erstem Wert auch
`GUEST_FIRST`, wirkt er nur beim Start (liest jemand anderes die Startparameter) stattdessen `START_ONLY` – plus
Tabelle im README.

## 10. Testen

- Start mit Godot 4.7.2 (Pfad im README), Parameter nach `--`. Schnelle Läufe ohne Fenster-Interaktion:
  `--time-scale 3`, `--quit-after N`, `--trace` (Zustand alle 2 s in die Konsole), `--day=n`,
  `--attacks=n`, `--kill=id`, `--knock` …
- Screenshots zum Prüfen: `--shot=pfad.png --frames=n` oder `--shot-on=reveal|jumpscare`; Menüs mit `--menu=…`.
  Mit `--bg` (in `Game._ready`) nimmt das Fenster keinen Fokus und liegt außerhalb des Bildschirms – nicht
  minimiert, sonst zeichnet Godot nicht und der Screenshot bleibt leer. Der Fokus würde schon beim Erstellen
  des Fensters geklaut, deshalb startet jeder Lauf mit dem Editor-Binary ohne Fokus
  (`window/size/no_focus.editor_runtime` in `project.godot`); ohne `--bg` holt `Game._ready` ihn sofort nach.
  Exportierte Spiele betrifft das nicht.
- Nach Änderungen am Speichern oder an der Welt: `--savetest` laufen lassen (`alles gleich` erwartet).
- Sonst keine automatisierten Tests – Prüfung über Debug-Parameter, Konsole und Screenshots. Ausnahme Schach:
  `Godot --headless --path . -s res://tests/chess_perft.gd` bzw. `…/chess_ai_speed.gd`. Neue Klassen kennt
  Godot erst nach einem Import (`--headless --import`).

## 11. Export

- Preset „Windows Desktop“ in `export_presets.cfg`, Befehl im README. `binary_format/embed_pck=true` →
  eine einzelne `.exe`; Skripte als Binär-Tokens (`script_export_mode=2`); Ziel `build/` (Git-ignoriert).
- Export-Filter „alle Ressourcen“: alles unter `res://` landet im Paket, außer `exclude_filter`
  (`assets/source/*`, `tools/*`, `build/*`, `monster_idea.png`, `addons/meshy-godot-plugin/*`). Neue reine Arbeitsdateien dort ergänzen.
- Nur `load()` mit festen `res://`-Pfaden verwenden – zusammengesetzte Pfade findet der Export nicht
  immer, und `res://` ist im Export schreibgeschützt. Alles Veränderliche gehört nach `user://`
  (Spielstände, `settings.cfg`), das im Export unter `%APPDATA%/Godot/app_userdata/Zimmer 13/` liegt.
- Export-Vorlagen müssen exakt zur Editor-Version passen (4.7.2).
- Debug-Tasten und Startparameter sind nicht an `OS.is_debug_build()` gebunden, also auch im
  Release-Export aktiv.
