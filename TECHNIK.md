# Technisches Handbuch – „Zimmer 13“

Wie der Prototyp gebaut ist: Aufbau, Konventionen, Zusammenspiel der Systeme und Stolperfallen.
Was das Spiel *sein soll*, steht in [SPIELKONZEPT.md](SPIELKONZEPT.md), Bedienung und Debug-Parameter
stehen im [README](README.md). Hier steht nur, was man aus dem Code nicht sofort sieht – Zahlenwerte stehen als
Konstanten im Code, hier nur deren Namen.

---

## 1. Grundprinzipien

- **Alles entsteht im Code.** Es gibt nur zwei winzige Szenen (`title.tscn`, `main.tscn`), beide hängen nur ein
  Skript an. Hotel, Möbel, Gäste und UI baut `main.gd` bzw. `LevelBuilder` zur Laufzeit. Modelle kommen als GLB aus
  `assets/models/` (Bauskripte in `tools/`, Übersicht unten); **fehlt eine Modelldatei, baut der Code einen
  Platzhalter** aus Grundkörpern. Was keine Datei hat, ist prozedural: Texturen aus `TexGen`, Klänge aus `SynthAudio`.
- **Kein verstecktes Inventar.** Ein Gegenstand in der Hand (`Player.held` / `Guest.held`), Geld ist der einzige
  abstrakte Besitz (`Game.money`). Gäste haben zusätzlich einen abstrakten Vorrat (`Guest.stock`). Der Spieler hat
  eine **Tasche für Kleines** (`Player.bag`, `Item.POCKET_KINDS`) – echte `Item`s, nur unsichtbar (siehe 8,
  „Tasche“) – und am Körper Kompass, Kartenblätter, Schlüsselbund (`has_compass`, `map_pages`, `keyring`; 8, „Am
  Körper“). Darum ist **die Welt der Spielstand** (siehe 7).
- **Spieler und Gäste nutzen dieselben Dinge** (Türen, Verstecke, Lampen, Vorhänge, Gegenstände).
- **Sprache:** Code-Bezeichner englisch, Kommentare, Doc-Kommentare (`##`) und alle Texte deutsch.
  Doc-Kommentare verweisen auf Abschnitte im Spielkonzept, z. B. `(Spielkonzept 4.13)`.
- **Tuning-Werte** stehen als `const` oben im jeweiligen Skript unter `# --- Tuning`, mit `##`-Erklärung.
  Zeitbereiche, die sich über den Oktober verschieben, als `Vector2(1. Oktober, Halloween)`, aufgelöst
  über `MonsterDirector._day_lerp()`.
- **Node-Klassen** werden mit `XYZ.new().setup(...)` erzeugt (`setup` gibt `self` zurück), danach
  `position`/`rotation` setzen und `add_child`. Gegenstände über die Fabrik `Item.create(kind, extra)`.
- **Engine:** Godot 4.7 (Forward+), GDScript mit Typangaben. 3D in Fensterauflösung (auf den Grafikstufen Mittel und
  Niedrig darunter, siehe 8 „Grafikstufen“); die Bedienoberfläche ist immer auf 480×270 ausgelegt.
- **Grafik: Maßstab ist der realistische Look** (Spielkonzept 9.2). Neue Materialien, Shader und Modelle: Texturen in
  voller Größe mit Mipmaps und linearem Filter, Normal-/Rauheitskarten, glatte Normalen, Polygonzahl nach Bedarf.
  Ältere Stellen mit kleinen Texturen oder `Closest`-Filter sind kein Vorbild; die Namen `psx_*` und `Mat.psx` sind
  nur historisch.
- **Wenige verschiedene Meshes:** Jedes eigene Mesh legt je Fläche Puffer auf der Grafikkarte an; manche
  Vulkan-Treiber (Onboard-Grafik) brechen bei zu vielen mit `VkResult error -10` (`VK_ERROR_TOO_MANY_OBJECTS`) ab –
  das Fenster geht beim Bau des Hotels einfach zu. Darum teilen `Geo.box`, `cylinder`, `sphere`, `wall_mesh`,
  `grain_box`, `rounded_box`, `lathe` und `runner_mesh` gleiche Meshes über einen Cache (Schlüssel auf 0,1 mm gerundet), ebenso
  `Bathtub` je Blockgröße: **diese Meshes nie verändern**, sonst ändern sich alle gleichen mit – wer das will, nimmt
  `.duplicate()`. Neue Formen, die oft vorkommen, ebenso teilen. Zählen mit Debug `--meshes` (29.10.: ohne Cache
  15 289 Meshes mit 16 600 Flächen, mit 3 252 bzw. 3 867).

### Modelle (`assets/models/`)

Gemeinsame Regeln:
- **Lage:** Ursprung meist mittig unten, Vorderseite nach +Z (Ausnahmen in der Tabelle; Figuren blicken nach −Z).
  Maße in Metern. Die Bauskripte geben Werte aus, die als Konstanten ins Spiel gehören (z. B. `GuestBody.BODIES`,
  `TREE_MODELS`, `Flashlight.LENS`) – nach jedem Neubau übernehmen. Wie ein Skript arbeitet, steht in seinem
  Kopfkommentar.
- **Material:** `Mat.model(pfad, mesh, fläche)` macht aus der Farbtextur der GLB ein `Mat.psx` (eins pro Textur,
  Grundfarbe 0,8 Grau – Farbtöne gehören in die Textur, die Materialfarbe der GLB wird ignoriert; `two_sided` für
  einseitige Blätter, `cutout` für Alpha-Blätter). Flächen mit sprechenden Namen (`glass`, `lens`, `brass` …)
  bekommen im Spiel eigene Materialien.
- **Texturen unkomprimiert einbetten**, wo Godots VRAM-Kompression (S3TC, 4×4-Blöcke) an UV-Nähten Farben
  verschmiert (Meshy-Modelle: helle Streifen an Ärmeln und Nähten) oder feine Fugen flimmern (Discokugel):
  `gltf/embedded_image_handling=3` („Embed as Uncompressed“) in der `.glb.import`, geschrieben von
  `tools/meshy_tex.py` (`write_import`). Diese `.import`-Dateien sind als Ausnahme im Repo (`.gitignore`). Eine
  `.import` der herausgezogenen PNG reicht nicht – ohne die (gitignorierte) PNG zieht Godot sie nicht neu heraus.
- **Meshy-Netze nicht ausdünnen:** Reduzieren zieht Dreiecke über Meshys winzige UV-Inseln und macht Schlieren;
  Farbtextur als PNG (JPEG färbt die Inselränder), Lücken zwischen den Inseln vor dem Verkleinern füllen
  (`meshy_tex.py`).
- **Lizenzen:** Sketchfab-Modelle sind meist CC-BY 4.0 – Namensnennung im README nötig. Ausnahmen: die
  Kerzenflamme ist **CC-BY-SA 4.0** (Änderungen unter gleicher Lizenz), das Brecheisen „Sketchfab Standard“ (keine
  Namensnennung, darf aber nicht einzeln weitergegeben werden). Mixamo-FBX liegen nicht im Repo (keine Weitergabe der
  Rohdateien). Rohmodelle liegen in `assets/source/`.

| Datei | Im Spiel | Bauskript, Quelle | Worauf achten |
|-------|----------|-------------------|---------------|
| `couch.glb` | Lobby-Sofas, `LevelBuilder._couch` | Rohmodell in Blender-Einheiten | `COUCH_SCALE`; Kollision zwei Boxen |
| `bottles.glb` | Barflaschen (`bottle_NN`) | `build_bottles.py`, Sketchfab-Paket | je Fach zwei auf beiden Glasböden (`BACK_BAR_SHELVES`) |
| `record_player.glb` | `RecordPlayer` | `build_record_player.py` | Platte `record` eigene Scheibe mit Ursprung auf der Drehachse |
| `clock.glb` | Wanduhr `WallClock`, `LevelBuilder._clock` | `build_clock.py` | Zeiger aus dem Rahmennetz getrennt (`hour_hand`/`minute_hand`, auf 12 Uhr), drehen um lokal −Z; mattes Schwarz `WallClock.IRON` – poliertes Eisen ging vor der roten Tapete unter |
| `reception.glb` | Rezeption, `_reception` | `build_reception.py`, neu gebaut nach Sketchfab-Vorbild (nur dessen Texturen) | Kollision und NavMesh aus dem Netz (`create_trimesh_shape`) wegen der Rundungen; Planrechtecke bleiben in `_furnishings` (Höhe für Telefon, Kerze, Katzen) |
| `planter.glb` | Pflanzkübel, `_planter` | `build_planter.py`, Meshy | Kollision bis Beckenkante `PLANTER_H`; Blätter `two_sided` |
| `tree_1…3.glb` | Gartenbäume, `_tree` | `build_trees.py`, „Realistic Trees Collection“ (Jungle Jim, CC-BY) | Zeile für `TREE_MODELS`; Blätter `cutout` (`psx_leaves`); Kollision nur Stamm bis `TREE_TRUNK_H` – unter der Krone kann man durch; der Plan zeigt nur den Standort |
| `bench.glb` | Parkbänke draußen, `_bench` | `build_bench.py`, Sketchfab (Decoratopia, CC-BY) | Kollision aus `BENCH_SEAT` und Lehne; drinnen bleibt der Holzkasten |
| `armchair.glb` | Ledersessel am Schreibtisch, `Armchair` | `build_armchair.py`, Sketchfab (VoGAn, CC-BY) | volles PBR-Set mit Verdeckung im Rot von `armchair_orm.png`; Leder beim Bauen rot gefärbt (Helligkeit bleibt, Beine per UV-Maske und helle Nieten ausgespart); Kollision Unterbau, Lehne, Armlehnen; ein Sitzplatz „sessel“; in `_furnishings` als `armchair` |
| `chair.glb` | Stuhl (Planfarbe „Stuhl“), `Chair` | `build_chair.py` (Blender, Möbelbausatz, ohne Vorlage) | 286 Dreiecke; zwei Teile `frame` (Holz, `Mat.hotel_wood`) und `cushion` (Stoff `Fabric_Pattern_08` getönt, `mesh_uv`); beide mit `chair_ao.png` über UV2, Normale aus dem Mesh; Maße gibt das Skript aus (`Chair.SIZE`, `SEAT_H`, Lehne `BACK_*_Z`) |
| `mask_board.glb` + `textures/mask_board_ao.png` | Maskenboard in Zimmer 13, `MaskBoard`/`MaskHook` (ZIM-128) | `build_mask_board.py` (Blender, Möbelbausatz, ohne Vorlage) | Teile `board` (Füllung mit senkrechter Faser, Rahmenleiste mit Profil `PROFILE` auf Gehrung) und `peg` (ein gedrechselter Stift, 12° nach oben, Ursprung auf der Füllung, `MaskHook` setzt ihn achtmal); beide `Mat.hotel_wood` mit der Verschattung über UV2 (Atlas 1024², Mipmaps; Board automatisch abgewickelt, Stift als Streifen von Hand – die automatische Abwicklung zerlegte den Drehkörper in Inseln mit Nähten), Normale aus dem Mesh; gebacken mit allen acht Stiften als Schattenwerfer. Maße und Plätze in `MaskBoard` = Bauskript |
| `room_table.glb` | Tischgruppen in Zimmern, `_room_table` | `build_room_table.py`, Sketchfab (MaX3Dd, CC-BY) | immer zwei Stühle gegenüber; Plan-Stühle im Umkreis `ROOM_CHAIR_REACH` fallen weg |
| `washbasin`, `shower`, `toilet`, `bar_counter`, `back_bar`, `bar_stool` | Bad und Bar | `build_fixtures.py`, Rohmodelle des Nutzers | Flächen nach Namen (`_fixture_materials`); siehe unten „Bad und Bar“ |
| `flashlight.glb` | `Flashlight` | `build_flashlight.py`, Sketchfab (Onur, CC-BY) | Glas `lens` bekommt das Lampenmaterial; Kegel an `Flashlight.LENS` |
| `crowbar.glb` | Item `CROWBAR` | `build_crowbar.py`, Sketchfab (SketchyBot, Standard-Lizenz) | hängt unter `_swing`, damit `_apply_held_pose` es aufrichtet |
| `matchbox.glb` | Item `MATCHBOX` | `build_matchbox.py`, Sketchfab (Freepoly.org, CC-BY) | liegt flach |
| `bulb.glb` | `Lamp.build_bulb`, Item `BULB` | `build_bulb.py`, Sketchfab (Mirai, CC-BY) | `glass` bekommt Lampenmaterial bzw. Glasfarbe; an der Decke kopfüber, `BULB_SCREWED_IN` in der Fassung |
| `wainscot.glb` + `textures/wainscot_ao.png` | Vertäfelung, `Wainscot` (`LevelBuilder._wainscot`) | `build_wainscot.py`, kein Ausgangsmodell | 0,8-m-Module `panel`/`plain`/`low` und das Halbfeld `half` (0,4 m); die Füllung im Rahmenfeld ist ein eigenes Brett (UVMap v + 50, Faser waagerecht wie die Leisten); Atlas der gebackenen Verschattung über UV2 (Stirnseiten auf eine weiße Ecke); nach Änderungen an Maßen `Wainscot.MODULE`/`HEIGHT` nachziehen; siehe 4 „Vertäfelung“ |
| `wall_lamp.glb` | `Lamp._build_wall` | `tools/build_wall_lamp.py` (Blender, ohne Vorlage) | Wandplatte, 5 cm Zylinder (12 Seiten), geschlossener Ring um die Kugel; in Spielgröße, Kugelmitte `WALL_BALL` (gibt das Skript aus). Kugel leuchtet mit dem Material der Birne, die Birne ist ein leerer Knoten (herausdrehen geht wie sonst). Das Licht sitzt in der Kugel, ein Projektor (`_wall_fan`, `FAN_*`) lässt nur je einen Kegel nach oben und unten durch, wie es der Ring täte: An der Wand steht ein zweigeteilter Fächer. Kostet je Leuchte einen Texturzugriff, den Schatten hat das Licht ohnehin. **Projektor auf Punktlichtern:** Godot erwartet ein Panorama (equirektangular, Zeile = Höhe, um die lokale Y-Achse) und wandelt es beim Kopieren in den Atlas selbst ins Paraboloid um – in dem Platz, den die Textur belegt, darum quadratisch und nicht zu klein; gelesen wird sie als sRGB |
| `mug.glb` | `Item.build_cup` (Kaffee, Tee, Tabletts) | `build_mug.py`, Sketchfab (Ole Gunnar Isager, CC-BY) | Oberflächen `coffee`/`tea`, `build_cup` entfernt die ungenutzte; Tassen auf dem Tablett quer, Henkel zu den Gästen |
| `candle.glb`, `candle_flame.glb` | `CandleModel` (Item `CANDLE`, `FixedCandle`, Vorrat in `ResourceSpot`) | `build_candle.py` aus drei Sketchfab-Modellen (Kerze, Teller CC-BY; Flamme **CC-BY-SA**) | Flamme: 100 Formschlüssel → `CandleModel._load` macht 100 Netze, `CandleFlame` tauscht mit `FPS` das Netz (keine Blend-Shapes, kein AnimationPlayer je Kerze), steht immer senkrecht (auch an gekippter oder liegender Kerze), `FLAME_WIDEN` breiter als das Netz. Farbe aus `shaders/candle_flame.gdshader`, Vorbild Kerzenfoto: additiv in HDR – Kern `core_energy` wird unter Filmic weiß, Hülle gelb → orange zu Spitze und Rand, Fuß schwach blau mit violettem Übergang, innen dunkel; Lichthof-Billboard (`halo`, `HALO_SIZE`) in zwei Stufen, `halo_pull` zur Kamera gezogen (steckt nicht in der Kerze) und weich vor Flächen dahinter (Tiefentextur, `halo_soft`). **Wachs:** eigener Shader `shaders/candle_wax.gdshader` – Licht greift herum (`wrap`), schimmert durch (`scatter`), matter Glanz; `instance uniform glow` lässt das Wachs unter der Flamme glühen (`glow_depth`), `CandleFlame` setzt es bei jeder Sichtbarkeitsänderung (Wachs als Meta „candle_wax“ am Elternknoten aus `build`). Nahaufnahme: `--kerzen=nah`. `candle_red` noch ungenutzt |
| `disco_ball.glb` | `DiscoBall` | `build_disco_ball.py`, Sketchfab (araghon007, CC-BY) | glatte Kugel mit gebackener Normal Map, exakte Plättchennormalen (Rauschen ließe Spiegelbilder zittern); unkomprimiert, `DiscoBall` erzeugt Mipmaps selbst (sonst flimmern die Fugen) |
| `cat.glb` | `HotelCat` | `build_cat.py`, Meshy (Rig-Preset „Hund“) | Größe und Blickrichtung nur am Wurzelknoten der Armatur – angewendet würden Translations-Schlüssel nicht mitskaliert |
| `ghost.glb` | `SheetGhost` | `build_ghost.py`, Meshy ohne Rig | eigenes Skelett mit Fingern; lokal X der Finger beugt zur Handfläche |
| `guest_<name>.glb` | `GuestBody` | `build_guest.py`, Meshy (Mixamo-Vorlage) | siehe unten „Gastkörper“ |
| `doll.glb` | `JuryDoll` | `doll_weights.py`, dann `build_doll.py` | siehe unten „Puppe“ |
| `pumpkin_man.glb` | `PumpkinMan` | `build_pumpkin.py`, Meshy (Figur + Axt) | siehe unten „Kürbismann“ |
| `pumpkins.glb` | `PumpkinModel` | `build_pumpkins.py`, Meshy-Kürbisgruppe, Textur prozedural gebacken | `psx_model.gdshader`; `PumpkinModel.material` je Kürbis ein eigenes Material, reife Früchte an der Pflanze teilen `shared_material()` |
| `arcade_machine.glb` + `textures/arcade_*.png` | `ArcadeMachine` (Videoautomaten der Bar) | `build_arcade.py`, Sketchfab (Tomas_Tew, CC-BY), Bilder `arcade_art.py` | nur das Netz – die Pac-Man-Bilder des Originals kommen nicht ins Repo; `cabinet` (Rumpf), `screen` (Röhre, UVs wie im Original), `stick` (Flächen `stick_ball`/`stick_ring`), `button_a/b`. `arcade_art.py` gibt jeder Rumpffläche eine Rolle (Seite, Kante, Schild, Rahmen, Bedienfeld, Lack) und malt die Motive in Metern, je Pixel baryzentrisch auf den Ort am Modell abgebildet: Farbe je Spiel (`arcade_deadra.png`, `arcade_ghost_hotel.png`, 2048²), Normal Map und Rauheit gemeinsam (`arcade_normal.png`, `arcade_rough.png`, Rot = Leuchtmaske des Schilds → `psx_model` mit `glow_albedo`), Joystick umgefärbt (`arcade_<spiel>_stick.png`, Textur aus dem FBX-Paket, dort gegenüber dem glTF gespiegelt). Mipmaps erzeugt `ArcadeMachine._tex`; Maße (`SIZE`, `SCREEN_BOTTOM/TOP`) = Ausgabe des Bauskripts |
| `masks.glb` | `MaskModel` (Item `MASK`, `MaskHook`) | `build_masks.py`, Meshy (je Maske ein Bild-zu-3D-Modell) | Netz „mask_<id>“, Ursprung mittig hinten, Gesicht +Z, echte Größe (`HEIGHT` im Skript → `MaskModel.SIZES`); alles, was ganz hinter dem Gesicht liegt, fällt weg (Meshys Rückschale beim Kürbismann); Farbe, Normal Map und Rauheit 1024², `psx_model.gdshader` |
| `monster.glb` | `Monster` | `build_monster.py`, Meshy | siehe 5, „Aussehen & Animation“ |
| `pool_handrail.glb` | `HANDRAIL_MODEL` | `build_handrail.py` | Tiefe und Lauf der Treppe sind eingebacken und müssen zu `_pool` passen |
| `lantern.glb` | Gartenlaterne, `LANTERN_MODEL` | `build_lantern.py`, nach Skizze des Nutzers | Licht in der Glasmitte (`LANTERN_LIGHT_Y`), Kopf und Glas werfen keinen Schatten |
| `door_room.glb` + `textures/door_room_ao.png` | `Door.Look.HOTEL` (Zimmer-, Bad- und übrige Holztüren) | `build_room_door.py`, kein Ausgangsmodell | Blatt (vier Kassetten, je eine 45°-Fase hinab zur flachen Füllung) und Beschläge `hinge` (schlichter Zylinder), `handle`, `peephole` (2,5 × echte Größe), `plaque`; das Blatt ohne Material mit zwei UV-Sätzen – UVMap in Metern (Faser je Fries) für `Mat.hotel_wood`, dem Holz der Vertäfelung, und UV2 auf den Atlas der in Cycles gebackenen Verschattung (`door_room_ao.png`, 1024²); Messing mit gebackener Farbe × AO 512², glTF-Material, eingebettet unkomprimiert. `Door.HOTEL_LEAF` = `LEAF` im Skript; Bänder (`HINGE_AT`) auf der Aufgehseite +Z; geht höchstens `HOTEL_MAX_ANGLE` (95°) auf; Rahmen statt `OpeningFrame` ist `DoorCasing` (im Code aus einem Profil: Zarge mit Anschlag auf −Z außerhalb des Schwenkkreises, gestufte Bekleidung beidseits mit Gehrung, `Mat.hotel_wood`, Mesh je Türgröße geteilt; Fliesen, Fassade und Beton liegen auf der Wandfläche, Zarge und Bekleidung sitzen also immer direkt auf der Wand); `Door.add_room_number` setzt an Zimmertüren den Spion auf die Flurseite (Seite aus `door_front`, notfalls `scale.z` gespiegelt) und darüber die Plakette aus `RoomPlate` (siehe `room_plate*.png`) – ein Mesh mit 38 Dreiecken je Tür, ein gemeinsames Material, kein Schattenwurf, `visibility_range_end` `PLATE_RANGE`. `plaque` im Modell bleibt ungenutzt |
| `wardrobe.glb` + `textures/wardrobe_ao.png`, `wardrobe_normal.png` | `HideSpot` (Kleiderschrank, ZIM-130) | `build_wardrobe.py` mit dem Möbelbausatz `furniture_kit.py`, kein Ausgangsmodell | Korpus (Sockel mit Fase und Viertelstab, Eckpfosten, Rundstab, Fries, Kranz aus Hohlkehle und Deckplatte, innen hohl mit Kleiderstange), zwei Lamellentüren (`door_l/r`, Ursprung auf der Drehachse; `louvre_l/r` die Füllung, `slats_l/r` echte Lamellen, `knob_l/r`), `brass` (Bänder, Stange). Holz `Mat.hotel_wood(ao, normal)`: UVMap in Metern, UV2 auf einen Atlas (2048²) mit gebackener Verschattung **und** Normale (Objektraum, Godot-Achsen) – darin gemalt, nicht modelliert: vier Furchen je Pfosten, eine Reihe stehender Mulden im Fries (vorn und an den Seiten) und die Lamellen (`paint_details`: Normale und Verschattung je Pixel aus einer Formel, dieselben Maße wie `slats_l/r`). **Innensicht:** `Player.enter_hide` → `HideSpot.show_inside(true)` blendet die gemalte Füllung aus und die echten Lamellen ein – man sieht durch die Schlitze hinaus; `hide_overlay` (Modus 1) dunkelt nur noch die Ränder ab. Messing wie bei der Zimmertür (Farbe × AO 512², glTF-Material). Höhe `HideSpot.WARDROBE_TOP` = `TOP` im Skript |
| `dresser.glb` + `textures/dresser_ao.png`, `dresser_normal.png` | `Dresser` (Kommode, ZIM-130) | `build_dresser.py` mit `furniture_kit.py` | Look des Kleiderschranks, 1,00 m hoch (31.10.: 15 cm höher): `carcass` (Sockel, Eckpfosten mit vier Furchen, Rundstab, Fries mit Mulden, Hohlkehle und Deckplatte, innen hohl), `drawer` (eine Schublade: Front mit Fase zur vertieften Füllung und Kasten, Ursprung auf der Unterkante ihres Fachs – `Dresser` setzt sie dreimal), `pulls` (zwei Messingknöpfe). Holz `Mat.hotel_wood(ao, normal)`, Atlas 1024², gebacken mit der Schublade im mittleren Fach (die anderen als Schattenwerfer). Korpus und Muster (`Body`, `carcass`, `flutes`, `niches`) teilen sich Schrank und Kommode im Bausatz; Maße in `Dresser` = Bauskript (`SIZE`, `PLINTH`, `OPEN_TOP`, `OPEN_X`, `TRAY_OUT`) |
| `bookshelf_4.glb`, `bookshelf_5.glb` + `textures/bookshelf_<n>_ao.png`, `_normal.png` | `Bookshelf` (Bücherregal, ZIM-152) | `build_bookshelf.py` mit `furniture_kit.py`, je Höhe ein Aufruf (4 bzw. 5 Ebenen) | Look der Kommode (Profil mit 7 cm hohem Fries), Korpus 30 cm tief, Fachraster 0,46 m (4 Ebenen 2,10 m, 5 Ebenen 2,56 m hoch): `end_l`/`end_r` (freies Ende, 9 cm massive Seite mit vier Furchen, Profil um die Ecke), `span1`/`span2` (ein Fach von 0,94 bzw. 1,94 m: Profil vorn, Deckel, Rückwand, Boden, Decke, Fachböden), `divider` (Zwischenwand 6 cm, drei schmalere Furchen), `miter_l`/`miter_r` (Ende an der Innenecke: Profil auf der 45°-Gehrung, x = 0 = Vorderseite des anderen Regals, Deckel und Rückwand bis an dessen Rückseite). Die waagerechten Flächen tragen die Holz-UV ohne Versatz in Metern entlang x, damit sie im Spiel über `instance_shift` durchlaufen. Atlas 2048² für alle Teile, gebacken als Zeile und als Ecke mit den Gegenstücken als Schattenwerfer. Leisten, Pfosten und Fries bekommen eine eigene Abwicklung (`STRIPS`: Leisten entlang × Bogenlänge im Profil, quer gestreckt) – die automatische zerlegte die millimeterschmalen Profilflächen in 1–4 px dünne Streifen, jedes Teil anders, und Normale und Verschattung brachen an jedem Stoß und jeder Gehrung. Maße in `Bookshelf` = Bauskript |
| `books.glb` + `books.json`, `textures/books_albedo.png`, `_normal.png`, `_mask.png` | `Books` (Bücher in den Regalen, ZIM-153) | `build_books.py` (Blender, ohne Vorlage), Karten mit numpy | 10 Varianten `book_0` … `book_9`, je 156 Dreiecke, Ursprung unten mittig am Rücken (Rücken +z bei 0, Vorderschnitt bei −Tiefe); ein gemeinsamer Atlas 2048² mit eigener Abwicklung, Bezug grau (Farbe je Buch im Spiel), Maske Rot Bezug / Grün Rauheit / Blau Gold; Maße je Variante in `books.json` |
| `dining_table.glb` + `textures/dining_table_ao.png`, `_normal.png` | `DiningTable` (Tafel, ZIM-157) | `build_dining_table.py` mit `furniture_kit.py` | Teile `leg_corner` (15 × 15 cm bis unter die 4-cm-Platte, Fasen, je Seite drei gemalte Furchen) und `apron`, `apron_l`, `apron_r` (ein Zargenstück von 3,1 cm mit einer Mulde wie im Fries der Regale, Außenfläche bei z = 0); Holz-UV ohne Versatz, Atlas 2048², gebacken an zwei Ecken und frei mit Platte und Boden als Schattenwerfer. Die Platte und der Läufer (`textures/TableRunner/`, `build_runner.py` aus der Vorlage des Nutzers) entstehen im Spiel |
| `desk_direktion.glb`, `desk_sekretariat.glb` + `.json`, `textures/desk_<fassung>_ao.png`, `_normal.png`, `desk_direktion_leather_*.png` | `Desk` (Schreibtisch, ZIM-154) | `build_desk.py` mit `furniture_kit.py`, je Fassung ein Aufruf | Look der Kommode: Unterschränke bzw. Wange mit Sockel und Rundstab, vorn Pfosten mit drei Furchen, an den Außenseiten gefelderte Füllungen (Rahmen, Fase, vertieftes Feld); die Rückseite über die ganze Breite mit durchgehendem Sockel, Rundstab und Querleisten und drei gleichen Feldern (`BACK_FIELDS`, `framed_row`); Fries mit Mulden vorn über den Stützen, hinten und an den Seiten durchgehend; Platte über Hohlkehle mit Nase, durchgehend Holz, beim Leder um die 0,8 mm tiefere Auflage (DIN A1, mittig, 12 cm hinter der Vorderkante). Inseln im Atlas 12 px auseinander, Bake-Rand 16 px – die gebackene Normale ersetzt die des Meshs, bei dichteren Inseln mischten kleinere Mipmap-Stufen an Kanten die Normale der Nachbarinsel herein (helle Flecken an den Ecken). Schubladen `drawer_s/_l/_c` (Ursprung Mitte ihres Fachs auf der Unterkante) mit `pulls_s/_l/_c` (Knöpfe, Schlüsselschild; Material 1 = schwarzes Loch), Atlas 2048² für Korpus und Schubladen, gebacken mit Kopien in den übrigen Fächern als Schattenwerfer. Lage und Kollision in `<glb>.json` – `Desk` liest sie, Maße stehen nur im Skript |
| `door_attic.glb` (`door_hotel.glb` ungenutzt) | `Door.Look.ATTIC` | `build_doors.py` aus den Pixelbildern `assets/source/door_*.png` | Blattgröße `Door.ATTIC_LEAF` muss zu `size` im Skript passen; Scharnierkante x = 0, Aufgehseite +Z |
| `frames.glb` | `OpeningFrame` | `build_frames.py` | siehe unten „Rahmen“ |
| `boiler.glb`, `pipes.glb` | `Boiler`, `PipeKit` | `build_boiler.py` | siehe 4, „Untergeschoss“ |

**Bad und Bar** (`build_fixtures.py`): Flächen `tiles` = Fliesen des Raums (`_bath_tiles`, in Toiletten
`_wall_tiles`, Weltkoordinaten), `ceramic`, `steel`/`chrome`/`brass` = `Mat.metal`, `glass`, `cushion`. **Fliesenmaß:**
Waschtisch und Duschsockel messen Vielfache von 5 cm (Raster der früheren Badfliesen); seit Tiles045 (gemischte
Formate) treffen die Fugen ihre Kanten nicht mehr. Die Fliesen liegen auf der Wandfläche des Plans – Becken und Rosetten sitzen an der Wand, die
Drückerplatte setzt das Skript 4 mm davor (`PLATE_GAP`). Spiegelglas des
Rohmodells fällt weg, an seiner Stelle ein `Mirror` (8). Dusche: wird gespiegelt, wenn die Wand rechts steht
(`_wall_beside`); Kollisionsblock bis `SHOWER_BLOCK` – **zu hoch fürs NavMesh**, sonst schickte es Gäste durchs Glas
auf die Wanne; Glasseiten auf Ebene 7. WC: Sitzplatz `Seat` „klo“. Bar: Das Barregal steht mit der Rückseite an der
Wand hinter dem Plan-Regal (`_bar_wall`), die Theke so weit davor, dass ihr Rückschenkel ans Regal stößt
(`BAR_RETURN`) – der Plan hätte zu wenig Gang. `_furnishings`: `bar_counter` (Flaschen, Dosen, Kaffee),
`bar_return`, `shelf`; `bar_spots` zwischen den Hockern.

**Gastkörper** (`build_guest.py`, Spielkonzept 6.0): Meshy-Auto-Rigging mit Skelettvorlage **Mixamo** („Alle
hinzugefügt“), Knochen ohne `mixamorig:`. Netz unverändert. **Färbemaske** als Punktfarbe (R/G/B = Oberteil/Hose/
Haare; Haare = größtes zusammenhängendes Stück am Kopf, `HAIR_MIN_PART`), `psx_guest.gdshader` färbt nur graue
Texel. Formschlüssel `build` (Körperbau) und `fit` (definiert, für die Spielerfigur, Spielkonzept 3.9). Das Skript
gibt die Zeile für `GuestBody.BODIES` aus. Kinderkörper haben ein kleines Skelett (keine Finger) und kommen in
Zentimetern – Skript und `retarget()` rechnen das ein. Arme, die in Meshys Ruhepose weiter als `ARM_MAX` abstehen,
dreht das Skript auf `ARM_DOWN` (übrige Körper bauen byte-gleich). `guest_woman_young` ist vorläufig (Meshy klappt
die Hände beim Gehen ab).
**Mixamo-Animationen:** jede `assets/source/anim/<name>.fbx` („Without Skin“, 30 fps) landet als Animation in
**jeder** Gast-GLB. Umbenennen reicht nicht (Mixamo steht in T-Pose, die Gäste mit hängenden Armen): `retarget()`
(`tools/mixamo_retarget.py`, auch für den Kürbismann) rechnet die Weltdrehungen gegen die T-Pose der Quelle um,
mittelt seitliches Wandern der Hüfte heraus (`DRIFT_WINDOW`, tanzt auf der Stelle) und behält die Szenen-Bildrate
(sonst liefen `walk`/`run` zu schnell). **SmartRig → Mixamo** (`tools/smartrig_to_mixamo.py`): Meshy-Figuren mit
„SmartRig“ bekommen Mixamos Skelett; Zuordnung in `MAP`, Finger prüft es an den Gewichten.

**Puppe** (`JuryDoll`, Spielkonzept 5.5): Meshy mit Mixamo-Vorlage, in zwei Schritten – `tools/doll_weights.py`
(reines Python, ändert nur `JOINTS_0`/`WEIGHTS_0`) trennt Meshys verschmierte Gewichte an Beinen und Ärmeln, lässt aber
den Streifen, wo Ärmel und Mieder verschmolzen sind (`SLEEVE_IN`…`SLEEVE_OUT`), und die Haare – harte Trennung dort
spannte beim Armschwingen eine Haut. Dann `build_doll.py`; es legt den Formschlüssel **„sit“** an: Der Rock hängt an
den Oberschenkeln und dreht beim Sitzen mit – seine Glocke stünde vorn über den Knien hoch. „sit“ drückt jeden Rockpunkt
unter dem Hüftgelenk zur späteren Sitzfläche hin flach (`SKIRT_THIGH`, `SKIRT_SEAT`, `SKIRT_LAP`, `SKIRT_RAMP`).
Sitzen und Aufstehen macht das Spiel (5, „Die Puppe“).

**Kürbismann** (`build_pumpkin.py`): Meshy-Figur (kleines Mixamo-Skelett, Zentimeter → Meter, auf `HEIGHT`) und
Axt. Animationen von Meshy (`spin_jump` auf die Stelle gesetzt), dazu alle Mixamo-FBX wie bei den Gästen und aus
`assets/source/anim/pumpkin/` nur für ihn (`attack`). **Axt** ist ein starres Objekt am Knochen `RightHand` (Mixamos
Schläge sind rechtshändig) → in Godot `BoneAttachment3D` mit `axe` (`PumpkinMan.axe`): folgt jeder Animation, lässt
sich ausblenden, abnehmen, werfen. Ohne Fingerknochen biegt das Skript die Finger der Axthand im Netz zur Faust. Für
`walk`/`run` dämpft es den Axtarm (`AXE_ARM`, `AXE_SWING`) – sonst kreiste die starre Axt fast einmal herum.

**Rahmen** (`frames.glb`, `OpeningFrame`, Spielkonzept 7.2): 1 m lange Profilteile (`casing`, `fillet`, `frieze`,
`cap`, `stool`, `board`), im Spiel nur in der Länge gestreckt und je Öffnung zu einem Mesh gefügt (gleiche Öffnungen
teilen es). Die Teile stecken in der Wand und **überlappen sich** (`OpeningFrame.TUCK`): So entstehen
an den Stößen keine Fugen. Das Rahmenmaterial (`trim_material()` = `Mat.layer`)
zieht leicht zur Kamera, die Laibungen tragen dasselbe Holz (rutscht die Zarge weg, sieht man Holz statt Tapete). Für
`Door` und `HotelWindow`; Durchgänge ohne Tür haben nur die Laibungen (`Geo.wall_mesh`, Fläche 1). Reine Optik, keine
Kollision, nicht im Spielstand.

### Klänge (`assets/sound/`)
Einzelne Aufnahmen statt `SynthAudio`: Lakengeist-Atmosphäre (`ghost_ambience.mp3`, `SheetGhost._ambience`),
Schritte `step_carpet`/`step_tiles`/`step_wood_1–8` (`Footsteps`), Türen `door_open_1–4`/`door_close_1–4`, Schublade
`drawer_open_1–3`, zerspringendes Glas `glass_break_1–4`, Donner `thunder_close/short/far_1–4`, Totenglocke
`church_bell`, Klopfen `door_knock_1–4`,
Krähen `crow_caw_1–3` (je zwei Krächzer), auffliegende Vögel `bird_flap_1–4` (`SynthAudio.SAMPLES`), Atem
`breath` (`SynthAudio.BREATH`), Feiermusik `party_1/2` (`RecordPlayer.TRACKS`), Axttreffer `axe_hit`
(`PumpkinMan.HIT_SOUND`), Vorspann `splash_wave` (`SlideShow`), Schreie in `screams/` (`SynthAudio.VOICES`, siehe 2).

### Texturen
**Vertäfelung** Wood067 (ambientCG, CC0, dunkle Nuss) in `assets/textures/Wood067/` (Farbe, Normal Map, Rauheit);
das Farbbild ohne die großen hellen und dunklen Wolken als `assets/textures/wainscot_wood.png` (`tools/wainscot_wood.py`,
Blender wegen numpy: Helligkeit durch ihren weichgezeichneten Verlauf geteilt, mit Umlauf – bleibt kachelbar), Verschattung
`assets/textures/wainscot_ao.png`, siehe 4 „Vertäfelung“. Dasselbe Holz tragen Zimmertüren und ihre Rahmen
(`Mat.hotel_wood`: eine Tönung und ein Glanz für alle, dunkel wie der Türrahmen – Wunsch des Nutzers 30.10.).

**Tapeten** (`Mat.WALLPAPERS`): hochaufgelöste, nahtlose Kacheln – Farbe `assets/textures/wallpaper_<variante>.png`,
Normal Map (OpenGL) und Rauheit je Muster `wallpaper_<muster>_normal.png` / `_rough.png`. Kachelbreite = Bahnbreite
0,53 m, damit Muster und Bahnen zusammenpassen; empfohlen 1024 px auf 0,53 m (≈ 2000 px/m – aus 30 cm noch scharf),
Höhe ein Rapport des Musters. Die Rautentapeten (Satin/Velours mit Fugen, 2 × 2 Rapporte) zeichnet
`tools/build_wallpaper.py` (Blender wegen numpy). **Holz** (Leiste und gemalte Vertäfelung) `wainscot_<variante>.png`
+ `wainscot_bump.png`. Siehe 8, „Optik“.

**Dorés „Die Zerstörung des Leviathan“** (`assets/textures/dore_leviathan.jpg`, Spielkonzept 4.32): Holzstich von
1865, gemeinfrei (Wikimedia Commons, `File:Destruction_of_Leviathan.png`), auf 800 px Breite in Graustufen verkleinert.

**Gemälde** (`Painting`, `scripts/world/painting.gd`, ZIM-151): Planfarbe „Ausstattung: Bild“ → `LevelBuilder._fittings`
hängt je Bild ein Werk aus `Painting.WORKS`, die Gruppe kommt aus der Flächenart an der Wand (`GROUPS`: lobby, bar
+ party, corridor, study = Bibliothek/Sekretariat, director = Büro der Direktion, room; sonst corridor), innerhalb
der Gruppe reihum je Stockwerk. Höhe der Bildmitte Lobby 2,2 m, Büro 2,0 m, Bar 1,9 m, sonst 1,75 m. **Ölbilder**:
lange Seite 1,7 m (Büro), 1,5 m (Lobby), 1 m (Bar), sonst 0,75 m; Leinwand als StandardMaterial3D, Bild auf UV, Leinwandstruktur
(`canvas_normal.png`, Kachel 5 cm) als Detail-Normal-Map auf UV2; Goldrahmen aus drei nach innen abfallenden
Stufen, Rauheit und Riefen aus `NoiseTexture2D` (mit Mipmaps). **Drucke** (`print`): 0,48 m, Passepartout,
Holzrahmen (`Mat.hotel_wood`), Glas davor. Bilder mit Mipmaps, ohne VRAM-Kompression (wie `Mat.pbr_model`).
[E] → `Menus.open_photo`. Werke ohne Datei werden übersprungen. Quellen (Wikimedia Commons, gemeinfrei bzw. CC0),
aufbereitet mit `tools/build_paintings.gd` (≤ 2048 px, Rahmenkanten der Scans per `CROP` weg):

| Datei (`assets/textures/paintings/`) | Commons |
|---|---|
| `boecklin_toteninsel` | `Island of the Dead MET DP-14201-003.jpg` (CC0) |
| `aivazovsky_neunte_woge` | `Hovhannes Aivazovsky - The Ninth Wave - Google Art Project.jpg` |
| `maclise_snap_apple` | `Snap-Apple Night globalphilosophy.PNG` (nur 800 px vorhanden) |
| `hokusai_geistergeschichten` | `One Hundred Ghost Stories in a Haunted House.jpg` |
| `friedrich_abtei` | `Caspar David Friedrich - Abtei im Eichwald - Google Art Project.jpg` |
| `dore_rabe` | `Dore raven shadow2.jpg` |
| `haeckel_discomedusae` / `haeckel_siphonophorae` | `Haeckel Discomedusae 8.jpg` / `Haeckel Siphonophorae 7.jpg` |
| `blake_leviathan` | `Behemoth and Leviathan, from Illustrations of the Book of Job MET DP816554.jpg` (CC0) |
| `ruisdael_friedhof` | `Jacob Isaackszoon van Ruisdael - The Jewish Cemetery (1654 or 1655).jpg` |
| `portraet_frau` / `portraet_mann` | `Portrait of a Woman Rijksmuseum SK-A-2866.jpg` / `Portrait of a Man Rijksmuseum Amsterdam SK-A-2867.jpg` |
| `fuessli_nachtmahr` | `Johann Heinrich Füssli - The Nightmare 55.5.A-d1-2019-04-15.jpg` |
| `friedrich_mond` | `Caspar David Friedrich - Two Men Contemplating the Moon - Google Art Project.jpg` |
| `grimshaw_roundhay` | `John Atkinson Grimshaw - Moonlight on the Lake, Roundhay Park, Leeds.jpg` |
| `portraet_alter_herr` | keine – eigens erstelltes Porträt des alten Herrn (Spielkonzept 2.10), 765 × 1024 px; einziges Werk im Büro, hinter dem Schreibtisch |

Nicht frei und deshalb nicht dabei: Kubin (frei erst 2030), Beksiński, Giger. Debug `--bilder[=gruppe]`.

**Fototexturen** (PBR-Sets, je ein Ordner `assets/textures/<set>/`): `Mat.photo(pfad, meter, normal_pfad,
rauheit_pfad, glanz)` mit `shaders/psx_photo.gdshader`, Projektion in Weltkoordinaten; `object_uv` in
Modellkoordinaten (für Bewegtes wie die Aufzugskabine – in Weltkoordinaten wanderte die Textur), `mesh_uv` über die
UVs des Meshs (Holz mit Faserrichtung, `Geo.grain_box`).
- Normal Map im OpenGL-Format; Tangente aus der Hauptachse der Fläche.
- **Glanz** nur bei glatten Oberflächen (polierte Fliesen, Lack, Metall): `glanz` > 0 (`specular`), Rauheit aus dem
  Rotkanal. `specular` 0 bleibt matt (Godot rechnet mit F0 = 0 auch am Rand keinen Glanz).
- **Bildschirmspiegelung** (SSR, `main._setup_environment`; `Settings.reflections` → `env.ssr_enabled` und
  Shader-Global `reflections`, das `metallic` mit ausschaltet – sonst wäre der Boden ohne SSR nur dunkler): spiegelt
  nur, was im Bild ist, und rechnet für Nichtmetalle fest mit 4 % – `specular` ändert daran nichts. Sichtbarer wird
  sie über `metallic` und `roughness_scale`. Das Environment spiegelt nichts (kein Himmel in Tapete und Fliesen).
- **Gebackene Verschattung** (`ao_tex`, `use_ao`): multipliziert die Grundfarbe über UV2 – wirkt auch im Lampenlicht.
  Vertäfelung und Türblatt der Zimmertür (`Mat.hotel_wood(ao)`; `Mat.wainscot` dazu mit `instance_shift`: INSTANCE_CUSTOM legt die Holz-UVs je
  MultiMesh-Instanz an die Wand – x Lage, y Versatz je Wandstück, z Streckung mit Vorzeichen, w eigener Ausschnitt der
  Füllung, erkannt an v > 25).
- **Gebackene Normale** (`detail_tex`, `use_detail`, Möbel aus `tools/furniture_kit.py`): Objektraum-Normale über UV2, ersetzt die Normale des Meshs (mit `MODEL_MATRIX` gedreht, Türen drehen also mit); die Holz-Normal-Map wirkt darauf. Import verlustfrei mit Mipmaps, ohne Normal-Map-Erkennung (sonst blieben nur zwei Kanäle).
- **Nicht genutzt:** AO-Karten (wirken in Godot nur aufs Umgebungslicht, das im Hotel fast null ist), Metallic-Karten,
  Height/Parallax.
- **Böden mit Fototextur** nennen `Footsteps.floor_under` ihre Bodenart per `set_meta("floor", …)` (Lobby
  `"tiles"`); ohne Meta klingen sie wie Holz.
- **Neues Set:** Der Ordner ist eine Kopie (Originale hat der Nutzer). Erst prüfen:
  `godot --headless --path . -s tools/photo_set.gd -- assets/textures/<set>` (Größe, Wertebereich – einfarbige
  Karten sind leer –, Format der Normal Map; liefert ein Set beide, die OpenGL-Variante nehmen). Karten je Look
  bewerten, Maßstab am Bild schätzen, dann zuschneiden:
  `… -- assets/textures/<set> basecolor normalogl roughness:512 [--dx] [--ao[=stärke]]` – behält die Karten mit
  diesen Stichwörtern, verkleinert, dreht mit `--dx` Grün (DirectX → OpenGL), backt mit `--ao` die AO ins Farbbild
  (für Sets, deren Muster fast nur in AO/Normal steckt) und löscht den Rest. Herkunft und Lizenz vor dem Commit
  klären; bisher alle Sets von Julio Sillet (JulioVII, itch.io, CC-BY) – Namensnennung im README.
- **Verwendet** (Maßstab je Konstante `*_METERS`, Glanz `*_SPECULAR`):

| Set | Wo | Hinweis |
|-----|----|---------|
| `Concrete_WoodPattern_01` | Kellerwände (`_cellar_wall`) | `CELLAR_WALL_METERS` |
| `TilesMarble_01` | Lobbyboden (`_floor`) | Spiegelanteil `LOBBY_FLOOR_MIRROR`, `LOBBY_FLOOR_ROUGHNESS_SCALE` |
| `pool` (Tiles_06) | Poolbecken, Rand, Einstiegstreppen (`_pool_tiles`) | Fugen treffen die Beckenkanten (`POOL_TILES_METERS`) |
| `TilesBasic_01` | Pool-Umgang (`pool_deck`) | |
| `Stone_EngraveWall_01` | Poolhalle, Wände (Haut der Seite `pool`) | AO eingebacken – ohne fast musterlos |
| `Tiles045` (ambientCG, CC0) | Bäder, Umkleiden und Duschen am Pool: Wände bis `BATH_TILE_HEIGHT`, Boden, Wannensockel, Waschtisch, Duschsockel (`_bath_tiles`; Pool-Räume über `TILED_CHANGING_ROOMS` – Wände per `_skin_kind`, Boden und Badecke in `_floors_and_ceilings`, sonst Betriebsraum) | dunkler Schiefer, gemischte Formate, `BATH_TILES_METERS` 1,8 m, Weltkoordinaten; Displacement verworfen (Relief steckt in der Normal Map) |
| `Scifi_PaintedWall_01` | Bad, Umkleiden und Duschen darüber und Decke, Decke der Küche (`_bath_paint`) | |
| `Tiles136B` (ambientCG, CC0) | Küchenboden (`_kitchen_floor`; Küche `KITCHEN_ROOM` über `_look` als „kitchen“) | helle 15-cm-Fliesen im Halbverband, `KITCHEN_TILES_METERS` 1,8 m, AO eingebacken |
| `Tiles133B` (ambientCG, CC0) | Küchenwände bis unter die Decke (Haut der Seite `kitchen`, `_kitchen_tiles`; ohne Vertäfelung) | hellblaue 15-cm-Fliesen, 1,8 m, AO eingebacken |
| `WoodFloor014` (ambientCG, CC0) | Speisesaal, Boden (`_dining_floor`, `DINING_ROOM`; Wände bleiben tapeziert) | Fischgrätparkett, Stäbe 7,5 × 30 cm, `DINING_FLOOR_METERS` 1,2 m; AO-Karte einfarbig, verworfen |
| `StoneWall_01` | Kieswege (`gravel`) | `GRAVEL_NORMAL_STRENGTH` – ohne wirkten sie flach |
| `StoneFloor_02` | Außenwände (Haut der Seite `outside`, `_facade`) | |
| `Wood_Panels_01` | alle Holzdecken (`_ceiling`, `_room_ceiling`), Aufzugskabine | aufgehellt `CEILING_SHADE`/`ROOM_CEILING_SHADE` |
| `WoodenFloor_03` | alle Holzböden (`_wood_floor`) | |
| `Wood_02` | Balkenbett, Stützbalken (`Mat.wood`, UVs von `Geo.grain_box`); grobe Bohlen des Dachgeschosses (`Mat.planks`: Bild aus Brettern mit Stößen, Fugen und Abdunklung, `PLANK_*`, `Mat._photo_from`) | Hirnholz aus TexGen `wood_end` |
| `Fabric_Pattern_08` | Laken und Kissen (`BedModel.FABRIC_METERS`, Modellkoordinaten) | |
| `TerrazzoDark_01` | Säulen der Lobby (`_pillar`), Platte des Couchtischs (`_coffee_table`) | Säulen mit Poren: eigene Normal Map aus `tools/pore_map.gd` (etwa eine je 2 cm², fester Startwert), feiner gekachelt über psx_photo `normal_tiling`; `cavity` macht die Porenwände dunkler und rauer (`PILLAR_PORES_*`) |
| `garden_coat*.png`, `garden_fabric*.png` (eigene Sets) | Gartenmöbel (`GardenFurniture`) | Aus `tools/garden_furniture.gd` (fester Startwert), nahtlos. Pulverlack anthrazit, seidenmatt (Rauheit 0,58), Orangenhaut und feines Korn als Normal Map, in Weltkoordinaten, Kachel 0,25 m. Textilgewebe grau in Leinwandbindung (64 Fäden je 10 cm), jeder Faden etwas heller oder dunkler, kleine dunkle Löcher dazwischen, über die UVs in Metern, Kachel 0,1 m |
| `locker_melamine*.png` (eigenes Set) | Spindblöcke (`LockerBank`) | Aus `tools/locker_melamine.gd` (fester Startwert), nahtlos. Melamin neutral grau mit feiner Perlstruktur und leichten Wolken, Rauheit 0,55, in Weltkoordinaten, Kachel 0,2 m; `LockerBank` tönt es fast schwarz (Korpus, Schloss), anthrazit (Regal, Sockel) und weiß (innen) |
| `trash_brass*.png`, `trash_coat*.png` (eigene Sets) | Mülleimer (`TrashCan`) | Aus `tools/trash_can.gd` (fester Startwert), nahtlos, über die UVs in Metern, Kachel 0,25 m: Messing gebürstet entlang u in den Farben der Plaketten – Riefen in mehreren Breiten, entlang lang gezogen, und einzelne tiefere; Farbe und Rauheit folgen den Riefen, keine Flecken; `METALLIC` wie die Plaketten (`BRASS_METALLIC`). Lack fast schwarz, seidenmatt (Rauheit 0,38), Orangenhaut als Normal Map – das Innere im Lack, dunkler |
| `room_plate*.png` (eigenes Set) | Zimmerplaketten (`RoomPlate`, `Door.add_room_number`) | Ziffernsatz 1024²: Zellen für Schraube links/rechts, Füller, Ziffern 0–9 (Cinzel, Tinte aus den Dreiecken eines `TextMesh` gerastert) den Abdruck der abgefallenen Null (013 → „13“: blanker Schatten, Kleberand, zwei Stiftlöcher) und ein Band mit der Kordel (2,6 mm, gedreht wie am Lichtschalter), je Zelle 4 mm Rand gegen Mipmap-Übersprechen. Farbe, Normal Map und Rauheit aus einer Höhenkarte von `tools/room_plate.gd`: Platte gebürstet wie die Lichtschalter, Ziffern erhaben (Fuß 0,3 mm, Rundung 1,1 mm) und poliert, Schmutz am Fuß. Die Vorderseite der Platte (140 × 74 mm, 3 mm, 45°-Fase) ist ein Streifen aus Zellen-Vierecken – Schraube, Füller, Ziffern, Füller, Schraube –, die Füller werden gestreckt; drumherum ein Rahmen aus vier Trapezen auf Gehrung, unverzerrt aus dem Kordelband geschnitten; Bürstung und Anlauf hängen nur von der Höhe in der Zelle ab, damit die Stöße unsichtbar bleiben. `METALLIC` `Door.PLATE_METALLIC`. Lage der Zellen rechnen Werkzeug und Spiel gleich aus (`RoomPlate.layout()`) – nach Änderungen an Maßen oder Schrift das Werkzeug neu laufen lassen |
| `year_plaque*.png` (eigenes Set) | Jahres-Plaketten der Fotorahmen (`YearPlaque`, `PhotoWall.PhotoFrame`, ZIM-134) | Ziffernsatz 1024² wie bei `room_plate*.png`, aber nur Füller und Ziffern 0–9 (Cinzel, 6,5 mm hoch, 16 px/mm, 2 mm Rand je Zelle). Farbe, Normal Map und Rauheit aus einer Höhenkarte von `tools/year_plaque.gd` (nutzt Rastern, Abstand und Weichzeichnen aus `tools/room_plate.gd`): Gold poliert mit feinen Riefen, Anlauf zu den Kanten, Ziffern als V-Gravur (0,12 mm tief), dunkel ausgelegt. Blech 40 × 12 mm, 0,8 mm, Fase 0,35 mm; Vorderseite aus Zellen-Vierecken (Füller, Ziffern, Füller), die Füller gestreckt. `METALLIC` `YearPlaque.METALLIC`. Lage der Zellen aus `YearPlaque.layout()` – nach Änderungen an Maßen oder Schrift das Werkzeug neu laufen lassen |
| `frosted_glass_normal.png`, `frosted_glass_rough.png` (eigenes Set) | Milchglas (`Mat.frosted_glass`: Milchglastüren) | Aus `tools/frosted_glass.gd` (fester Startwert), nahtlos: satiniertes Glas – feine Ätzkörnung (0,35 mm) und flache Walzwellen als Normal Map, Rauheit um 0,42 mit geätzten Flecken; Farbe mit Deckkraft 0,8 und Gegenlicht (`backlight`) im Material, dreiseitig in Modellkoordinaten, Kachel 0,12 m |
| `switch_plate*.png` (eigenes Set) | Lichtschalter (`LightSwitch`): Platte, Kanten und Wippe | Altmessing mit Kordelrand, Rille, Schlitzschrauben, Bürstung und Patina – Farbe, Normal Map und Rauheit aus einer Höhenkarte von `tools/switch_plate.gd` (fester Startwert); über die UVs gespannt (`mesh_uv`, Platte `_plate()` mit eigener Vorderseite, Kanten und Wippe aus `PLAIN_UV`), `METALLIC`. Plastisch sind nur Platte, schwarzer Rahmen und die eckige Wippe |

## 2. Aufbau zur Laufzeit

### Autoloads (`project.godot`)
| Name | Datei | Aufgabe |
|------|-------|---------|
| `Settings` | `scripts/autoload/settings.gd` | Einstellungen, `user://settings.cfg`, Signal `changed`; Grafikstufen `GRAPHICS` (8 „Grafikstufen“); Vollbild steht nicht in `KEYS` (Start immer im Fenster); `key_bindings` = Abweichungen der Tastenbelegung (`Keys`) |
| `Game` | `scripts/autoload/game.gd` | Referenzen auf alle Systeme, Geld, Meldungen, Tastenbelegung, Szenenwechsel, Screenshot-Debug |
| `SaveManager` | `scripts/autoload/save_manager.gd` | Speichern/Laden, Autosave, Tagebuchsatz |

### `Game` als Drehscheibe
`main.gd` erzeugt die Systeme und trägt sie in `Game` ein: `player`, `monster`, `ghost`, `pumpkin`, `director`,
`social`, `traces`, `audio`, `hud`, `dialog`, `phones`, `dice`, `menus`, `doll` (Puppe, 5.5), `contest`
(Türschmuck-Wettbewerb, 2.5), `sleep_skip`, `shower_scare` (Dusche, 4.24), `weather` …. Systeme rufen sich **direkt** über diese Referenzen auf
(`Game.director.on_noise(...)`), nicht über Signale. Signale gibt es nur für UI-nahe Dinge (`Game.message_posted`,
`money_changed`, `player_died`, `caption_posted`, `Settings.changed`, `SaveManager.autosaved`).

- Referenzen können `null` sein (Titelbildschirm, Szenenwechsel) → bei Aufrufen aus Welt-Objekten
  mit `if Game.traces:` / `if Game.social:` absichern.
- `Game.reset()` am Anfang von `main._ready()` leert alles.
- Text für den Spieler: `Game.say(text, dauer)`. **Geräusch in der Welt:** `Game.noise(art, ort, quelle)`
  – Geräusch *und* Lärm in einem (siehe 8a). **Nur Klang, ohne Lärm:** `Game.sound_at(klang, ort, hörweite, quelle,
  lautstärke)` – so laut, wie der Spieler es hört, aber niemand reagiert. Reine UI-, Meldungs- und Stinger-Geräusche
  gehen direkt über `Game.play_sound(kind, volume)` – ab Lautstärke 0,3 mit Untertitel (`Game.SOUND_CAPTIONS`).
- **Klangarten:** synthetisch in `SynthAudio.play_shot`; Aufnahmen in `SynthAudio.SAMPLES` (Datei mono, Spitze
  −6 dB, Pegel in dB), reihum über `SAMPLE_VOICES` Player. Lange Klänge mit `"solo"` bekommen eine eigene Stimme, die
  niemand abbricht (`_solo_voices`): `bell` (Totenglocke – `Social.on_guest_died` nach `BELL_DELAY`, nicht beim Laden,
  nicht beim Tod des Spielers), `shriek` (Spielertod). `cry` = Hotelkatze auf der Flucht. Mit `"files"` statt `"file"`
  spielt jedes Mal eine zufällige Aufnahme, nie zweimal hintereinander dieselbe (`_sample_file`): `door`/`door_close`
  (Lärm `door` beim Öffnen, `door_close` beim Schließen, `Door.set_open`), `drawer` (Kommode), `glass_break` (Lärm
  `cup_break`, `bulb_burst`), `thunder_close`/`thunder_short`/`thunder_far` (`Weather._thunder` nach Lautstärke, Grenzen
  `THUNDER_CLOSE`/`THUNDER_MID`; die Aufnahmen sind kurz, rund 1 s), `knock` (Klopfen an
  Türen), `caw` (Krähen, auch fern in `DistantAnimals`: 1–2 Aufnahmen je Ruf), `wings` (Flügelschlagen, wenn ein
  Krähentrupp auffliegt, `Crows._caw`). Neue Aufnahme wie die Schreie umwandeln (mono 44,1 kHz, Stille vorn weg, Spitze
  −6 dB). Der Fledermausschwarm (`flutter`) bleibt synthetisch.
- **Menschliche Laute (Schreie):** `SynthAudio.VOICES` – Klang → Aufnahmen je Stimme (`m`, `f`, `child`), Pegel,
  Tonhöhe, Abbruch. Gespielt, wenn `Game.play_sound` Ort und Quelle bekommt und die Quelle `voice()` hat
  (`Guest.voice()`): Jeder Gast klingt immer gleich (Aufnahme und Grundtonhöhe nach `hash(id)`, `VOICE_AGE`), Angst
  höher, Rausch tiefer, dazu `VOICE_JITTER`. `death_scream` bricht jäh ab (`VOICE_FADE`), `grunt` nur Männer. Die
  `AudioStreamPlayer3D` (`VOICE_PLAYERS`) haben keine Entfernungsabschwächung – die Lautstärke kommt gedämpft aus
  `Game.sound_at`, der Lautsprecher gibt nur die Richtung. Ohne passende Stimme spielt der synthetische `scream`.
  **Aufnahmen** in `assets/sound/screams/` (aus `temp/audio/screams/`): mono 44,1 kHz, Stille vorn und hinten weg, auf
  gleiche Lautheit (Mittel −18 dB, Spitze höchstens −6 dB); neue Aufnahme genauso umwandeln und in `SCREAMS`/`VOICES`
  eintragen. `male_1` ist der Wilhelmsschrei – bewusst.

### Reihenfolge in `main._ready()`
Umgebung → `LevelBuilder.refresh_maps()` / `build()` → NavMesh backen → SynthAudio → ShadowBudget → Traces → Player
(mit `PlayerBody.default_look()`) → Monster → MonsterDirector (`setup(builder, monster)`) → Post-FX → Social
(`setup(builder, self)`, erzeugt die Gäste) → Puppe → DoorContest (`setup(builder)`: Brett, Brief) → Katzen → … →
Dialog → PhoneCalls (findet die Telefone) → DiceMatch → ChessMatch → Hud → Menus → Achievements → dann entweder Spielstand anwenden
(`_load_pending`, deferred) oder Neues Spiel: vom Titelbildschirm erst die Charaktererstellung (`_start_creation`,
`CharacterCreation`), nach „Ja“ der Gedanke an den Brief (`DoorContest.welcome`) und Startzustand speichern
(Tagebuchsatz `DoorContest.ARRIVAL_ENTRY`); Debug-Starts ohne `--figur` sofort mit Standardfigur (`--nointro`: ohne
Gedanken). Zum Schluss `_parse_debug_args` (deferred).

**Wichtig:** Die Reihenfolge, in der der LevelBuilder Objekte erzeugt, ist Teil des Speicherformats (siehe 7) –
ändert sie sich, lehnt der Fingerabdruck alte Spielstände ab.

### Szenenbaum (grob)
```
Main (Node3D, main.gd)
├─ WorldEnvironment (Nachthimmel), DirectionalLight (Mond)
├─ Level (NavigationRegion3D)        ← statische Geometrie, Türen, Lampen, Schalter, Verstecke …
│   ├─ Wände, Böden, Decken, Türen … ← aus assets/maps/eg.json, direkt unter Level
│   ├─ Zimmer_013 …                  ← je Zimmer ein gedrehter Rahmen (Ursprung = Türmitte)
│   ├─ Treppenhaus                   ← Rahmen des Schachts Ost (Läufe, Podeste, Mittelwand vom UG bis oben)
│   ├─ Obergeschoss (y 4)            ← dasselbe aus assets/maps/og1.json
│   ├─ Dachgeschoss (y 8)            ← eigener Durchgang aus assets/maps/dg.json
│   └─ Untergeschoss (y −4)          ← dasselbe aus assets/maps/ug.json, darin der Heizkeller
├─ Items, Gäste, Plattenspieler      ← dynamisch, direkt unter Main (LevelBuilder.world)
├─ Aufzug_1, Aufzug_2                ← Elevator je Schacht (bewegte Kabine – nicht im NavMesh)
├─ SynthAudio, ShadowBudget, Traces, Player, Monster, MonsterDirector, Social, PhoneCalls …
└─ CanvasLayer: PostFx (5), Hud (10), Dialog/DiceMatch/ChessMatch/PhoneUI (15), DeathScreen (20), Menus (30)
```

## 3. Konventionen

### Koordinaten & Ausrichtung
- 1 Einheit = 1 m. Erdgeschoss y = 0, Stockwerke je `LevelBuilder.UP_Y` höher, Untergeschoss y =
  `LevelBuilder.CELLAR_Y`.
- Ursprung = Mitte des Haupteingangs auf der Südwand; x nach Osten, z nach Süden (Norden = −Z), die Lobby liegt
  mittig nördlich davon.
- **Lokale +Z zeigt „nach vorn / in den Raum / von der Wand weg“** (Items: Vorderseite, Verstecke:
  heraus, Fenster/Schalter/Kalender/Spuren: in den Raum). Ausnahme: Figuren (Monster, Gäste) schauen entlang **−Z**.
- Ursprung von Gegenständen = Unterseite; von Türen = Rahmenecke am Boden (Scharnier, mit `hinge_end` die andere
  Ecke); von Fenstern = Mitte der Öffnung.
- Die Stockwerke liegen übereinander → „angekommen“ heißt immer auch `|Δy| < 1,5`; Zonen gelten nur
  bei `|Δy| ≤ 2,5`. Wer Positionen vergleicht, muss das Stockwerk mitprüfen.

### Kollisionsebenen
| Ebene | Bit | Was | Hinweis |
|-------|-----|-----|---------|
| 1 | 1 | statisch: Wände, Böden, Möbel, Verstecke, Truhen | **einzige Ebene fürs NavMesh** |
| 2 | 2 | Türen | nicht im NavMesh → Wegplanung geht durch Türöffnungen |
| 3 | 4 | Gegenstände, Lampen, Schalter, Pflanzen, Tagebuch, Kalender, Spuren | blockiert den Spieler nicht |
| 4 | 8 | Spieler | |
| 5 | 16 | Decke; Böden verschlossener Zimmer und Kellerräume | nicht im NavMesh |
| 6 | 32 | Monster | |
| 7 | 64 | klares Glas (Fenster, Glastür, Duschglas) | Sicht geht durch |
| 8 | 128 | Gäste | |
| 9 | 256 | Milchglas (`HotelWindow` mit `frosted`, derzeit nicht verbaut; Milchglastüren liegen auf 2) | blockiert Sicht |
| 10 | 512 | zugezogene Vorhänge (`HotelWindow.LAYER_BLOCK`) | nur Sicht-/Licht-Raycasts, nicht Bewegung |
| 11 | 1024 | Hotelkatzen (`HotelCat.LAYER`) | blockiert niemanden; nur der Spieler-Strahl trifft sie (Streicheln) |
| 12 | 2048 | Trittflächen der Treppenstufen (`LevelBuilder.LAYER_TREAD`) | blockiert niemanden; nur für Spuren (`Traces.surface_below`) |

**Sichtebenen** (render layers, nicht Kollision): 11 = Discokugel (`DiscoBall.LAYER`), 15 = Schatten vom Bau
(`ShadowBudget.LAYER`), 17 = was der Türspion nicht zeigt (`PeepholeView.HIDDEN_LAYER`, das Kind zu viel),
18 = Schattenkopie der Spielerfigur (`PlayerBody.SHADOW_LAYER`), 19 = Spielerfigur
(`PlayerBody.LAYER`, fehlt in der `cull_mask` der Spielerkamera), 20 = Spiegelflächen (`Mirror.LAYER`, fehlt in der
der Spiegelkameras). Lichter, die die Kamera nach dem Grundriss nicht erreicht (`LightRooms`, 8 „Licht“), bekommen
von `ShadowBudget` `light_cull_mask` 0 und keinen Schatten; die eigenen Werte liegen solange in den Metas
`hidden_mask`/`hidden_shadow` – wer einem Licht eine eigene Maske gibt, muss das wissen.

Sichtprüfungen (Monster, Zeugen) nutzen `Senses.SIGHT_MASK` (Ebenen 1, 2, 9, 10) – als Strahl immer über
`Senses.clear_line(world, von, nach, ohne, maske)` –, Lichtprüfungen Ebenen 1 und 2, Lärm-Dämpfung 1, 2 und 7.

### Interaktion („Smart Objects“)
- Ein Kollisionskörper bekommt `set_meta("interactable", objekt)`. Der Spieler-RayCast (`Player._update_focus`)
  fragt `objekt.get_prompt(player) -> String` ab und ruft bei [E] `objekt.interact(player)` auf.
- **Leerer Prompt = nicht interagierbar.** Zum Abschalten `set_meta("interactable", null)`.
- Große Gegenstände blockieren Türen/Truhen: `player.hands_blocked()` prüfen.
- **Gegenstände in der Hand** hängen als Kind am Hand-Knoten und sind über `Item.set_held(true)` **statisch**
  eingefroren (`FREEZE_MODE_STATIC`). Kinematisch eingefroren schreibt die Physik die alte Lage zurück – der
  Gegenstand dreht dann nicht mit. Immer `set_held()` benutzen, nie `freeze` direkt.
- **Bodenlage:** Godots Physik lässt ruhende Körper bis `contact_max_allowed_penetration` einsinken. Die
  Kollisionsform jedes Gegenstands liegt deshalb um `Item.SINK` tiefer als das Sichtbare – sonst versinken flache
  Dinge. Wer in `_apply_pose` Formen setzt, zieht `SINK` ab (nur am Boden, nicht aufgehängt).
- **Aufgehängte Deko** (Spielkonzept 5.6, `Item.HANGABLE`): `Item.hang(point, out, length)` friert kinematisch ein
  (`hung`, Ebene 3 bleibt interagierbar, Maske 0), Ursprung = Haken bzw. Mitte der Aufhängelinie, lokale +Z von der
  Wand weg; `set_held()` hebt `hung` wieder auf, `restore_hung()` beim Laden. Was schwingt, hängt unter `_swing`
  (Drehpunkt am Haken); `_apply_pose()` setzt Teile und Kollisionsform je nach Hand, Boden oder Wand.

### Gruppen (zum Finden und Speichern)
`items`, `guests`, `player`, `doors`, `chests`, `hide_spots`, `lamp_fixtures` (die Lampen), `lamps` (deren Lichter),
`light_source` (alles, was für die Helligkeit zählt – `FlickerLight`), `light_switches`, `windows`,
`pumpkin_plants`, `resource_spots`, `trace_marks`, `warning_notes`, `guest_notes`, `diaries`, `phones`, `dressers`,
`cats`, `elevators` (der fahrende Aufzug), `fixed_candles`; nicht gespeichert: `uv_marks`, `seats` (Sitzmöbel),
`time_skip` (hat `skip_time(dt)`, siehe unten). Neue gespeicherte Gruppe → auch in `SaveManager.WORLD_GROUPS`.

### Räume & IDs
- **Raum-ID** = Zimmernummer (dreistellig: `"013"`, `"113"`) oder Bereichs-ID (`"lobby"`, `"treppenhaus"`,
  `"keller"` (Heizkeller), `"og1_flure"`, `"ug_cellar_1"` …). Lampen und Schalter gehören über `room_id` zu einem Raum;
  `LightSwitch.find(tree, room_id)` schaltet alle Lampen des Raums. Ein Bad hat seine eigene Raum-ID (`bath_7`,
  `og1_bath_5`) und eigene Schalter (ZIM-149); `LevelBuilder.home_of(id)` bzw. `Lamp.home_id()` führen es auf das
  Zimmer davor zurück (Besitz, Birnenklau, Ersatzbirnen). Lichtschalter kommen nur aus dem Plan, der Bau
  ergänzt keine (ZIM-149): Ohne Schalter brennt das Licht des Raums immer. Badschalter starten aus. Mehrere Schalter in einem Raum sind eine
  Wechselschaltung: `set_on` stellt alle mit derselben `room_id` um (Lärm und `on_lights_off` nur vom betätigten),
  `find()` darf also irgendeinen liefern.
- **Zonen** (`LevelBuilder.zones`, Kreise mit `name`, `center`, `radius`) sind etwas anderes: Sie tragen nur den
  Anzeigenamen („Nordflügel“, „Zimmer 13“). `MonsterDirector._zone_at(pos)` / `zone_name_at(pos)`.
- **Gast-IDs:** feste Gäste `edna`, `bruno`, `mila` (`GuestProfiles`); erzeugte `gast1`, `gast2` … (laufend).
- **Besitz** (`Item.owner_id`): `""` niemand, `"player"` oder eine Gast-ID.

### Pause & Zeit
- Menüs pausieren mit `get_tree().paused = true`. Was im Menü laufen muss, hat
  `process_mode = PROCESS_MODE_ALWAYS` (Game, Settings, SynthAudio, Menus, DeathScreen, TitleScreen).
- Auch die **Charaktererstellung** pausiert (`CharacterCreation`, `Game.creating`: kein Spielmenü auf Esc, keine
  Eingaben an den Spieler). Dort laufen weiter: `Mirror` (Wandprüfung entfällt – die Physik steht), `PlayerBody`
  (Atmen) und die Erstellung selbst; sie setzt die Unschärfe direkt am Post-Shader (`main._process` steht).
- **Spielzeit ist `MonsterDirector.elapsed`** (pausiert, wird gespeichert). Datum und Uhrzeit daraus über `Calendar`
  (Spielkonzept 2.4): ein Tag = `Calendar.DAY_SECONDS`, Stunde `HOUR`, Spielzeit 0 = 1. Oktober `START_HOUR`.
  `today()`/`day_of(elapsed)` (bis 31), `raw_day_of`, `day_float` (gleitend, für Kurven über den Monat), `hour_of`,
  `at(tag, stunde)` (→ Spielzeit, vor der Anreise negativ), `phase()`/`phase_at(stunde)`, `date_text`/`time_text`.
  Werte, die je Spieltag gelten, rechnen mit `Calendar.DAY_SECONDS` statt mit festen Sekunden.
- Spielablauf-Timer laufen über `delta`, nie über Systemzeit. Bei `get_tree().create_timer()` für Spielereignisse
  `process_always = false` übergeben (`create_timer(t, false)`), sonst laufen sie im Menü weiter.
- **Zeitraffer:** Schläft der Spieler (`Player.start_sleep`), steht `Engine.time_scale` auf `SLEEP_SPEED`. Zurück auf
  1 in `_stop_sleep()` – beim Aufwachen, Aufstehen, Tod und in `_exit_tree`.
- **Zeitsprung im Schlaf** (`scripts/player/sleep_skip.gd`, `Game.sleep_skip`, Spielkonzept 3.6): Im Schlaf springt
  die Uhr statt zu raffen – ein 60-facher Zeitraffer ginge nicht (jeder Physikschritt eine Spielsekunde: Gäste und
  Monster sprängen meterweise).
  - `SleepSkip.try_begin()` (aus `start_sleep`, im Zeitraffer jede Sekunde erneut) springt nur, wenn keine Bedrohung
    unterwegs oder angekündigt ist (`MonsterDirector.other_threat_active(null)`): in der Nachtruhe
    (`Social.sleep_active`) bis `min(Ende der gewählten Stunden, Social.night_ends_at())`, **am Tag** (`_day`) nur,
    solange `_quiet_day()` (keine Feier, kein Schmücken, keine Siegerehrung), bis zur Nachtruhe
    (`seconds_to_night`) und bis `DAY_MARGIN` vor dem nächsten Eintrag im Plan des Monsters (`next_planned`, je Bild
    neu – ein Auftritt am Tag ist so immer echt); jeweils mindestens `MIN_SKIP`. Endet ein Sprung am Tag, stellt
    `Social.after_day_skip()` → `Guest.after_day_skip()` die Gäste an ihre Plätze: Wer frei war, wählt seine nächste
    Tätigkeit (`_next_activity`), steht am Ziel (`_target`) und kommt an (`_arrive` – ablegen, ernten, heimtragen);
    Versteckte, Verletzte im Bett und Beschäftigte (Gespräch, Spiel, Feier …) bleiben, wo sie sind. `Engine.time_scale` = 1; je Bild rückt die Zeit um delta / `HOUR_REAL` Spielstunden vor:
    erst `MonsterDirector.skip(dt)`, dann `call_group("time_skip", "skip_time", dt)`. Die Welt läuft daneben im
    normalen Takt; das Spielmenü hält den Sprung an. Uhrzeit mitten im Bild (`Hud.set_sleep_clock`).
  - Ende: Stunden um, Nachtruhe vorbei (weiter mit `SLEEP_SPEED`), geweckt (Lärm ≥ 0,3, Mitternachtsglocke
    `Weather._update_bell`, Monster nah) oder eine Bedrohung taucht auf.
  - **`skip_time(dt)`** rechnet nach, was sonst je Bild mit `delta` zählt: Player (Schock, Rausch, Kater,
    Verletzung, Ausdauer, Schlaf), Guest (Angst, Rausch, Pausen, Wunde – Restzeiten bleiben bei 0,001, Fälliges meldet
    das nächste Bild), Social (Beziehungsdrift, Nachrücker, Pausen; das Freundesnetz läuft über `MonsterDirector.elapsed`), ResourceSpot und PumpkinPlant (mehrere
    Stufen auf einmal), Item (Kürbismatsch verwäscht), Lamp (Durchbrennen als Wurf über dt), Traces, RainVeil,
    Weather, HotelCat, PumpkinMan, SheetGhost, PhoneCalls (das Telefon in Zimmer 13 klingelt also und weckt). Was an
    der Uhr hängt (Fäulnis, Termine), holt von selbst auf. **Neues System, das mit `delta` über Minuten bis
    Stunden zählt → in die Gruppe `time_skip`.** Bewusst nicht: kurze Pausen der Tagesgäste – nachts schlafen alle, am Tag stellt `after_day_skip` sie neu auf.
  - **Das Monster im Sprung** (`MonsterDirector.skip`; `skipping` hält `_update_schedule`/`_update_haunting` an):
    Werte und Spuk wie sonst. Ein Aufbruch (`_skip_activity`) würfelt die Absicht wie sonst; mit Puppe geht
    `_skip_raid` den Weg aus `_plan_route` Tür für Tür (im Zimmer alle Verstecke auf, jeder Erwachsene →
    `kill_guest`), ohne Puppe nimmt sich `_skip_roam` Ziele aus `next_roam_target` vor (`_skip_search` würfelt
    Verstecke wie `Monster._check_hide_step`). `kill_guest`/`_scare_guest` rufen im Sprung nichts am Monster auf.
  - **Übergabe:** Ist das Ziel Zimmer 13 oder das Zimmer des fremden Betts, in dem der Spieler schläft
    (`MonsterDirector.foreign_sleep_room()`, das auch beim Einbruch nach dem Raubzug mitwürfelt – `_plan_break_in`), mit
    Wache – `SleepSkip.guarded()`: ein wacher Erwachsener in diesem Zimmer – zu `SKIP_GUARD` nicht, oder hört der
    Spieler, was es tut (`_skip_heard`), wird es echt: `_skip_wake` stellt es `SleepSkip.lead()` Sekunden vor das Ziel
    auf den Weg (`_point_before`), `Monster.start_roaming`, Flackerwelle; der Spieler schreckt hoch.
  - Wer im Sprung stirbt, liegt da wie sonst – nur `Social.on_guest_died` schweigt, solange der Spieler schläft. Der
    Lakengeist kommt nie zu Schlafenden. Debug: `--sleep=bett[,h]`, `--uhr=1:10`, `--hoerer`, `--trace`
    „[Zeitsprung] …“.

### Bewegung von Gästen und Monster
- `NavigationAgent3D` mit `path_height_offset = 0.2` (NavMesh liegt ~0,2 m über dem Boden). Monster und Kürbismann
  suchen ohne Grenze (`path_search_max_polygons = 0`): Godot bricht sonst nach 4096 Polygonen ab und liefert einen
  Weg nur bis zum bis dahin nächsten Punkt – vom Heizkeller in die Flügel sind es mehr.
- Eigene `_move_to(point, speed, delta) -> bool` (true = angekommen) mit **Festgefahren-Erkennung**: bewegt sich der
  Körper kaum, nach kurzer Zeit seitlich ausweichen und das Ziel minimal verschieben, damit der Pfad neu berechnet
  wird. Monster und Kürbismann erben das samt `_stop`, `_face` und Schwerkraft von **`NavWalker`**
  (`scripts/monster/nav_walker.gd`); neue Akteure auf dem NavMesh sollten davon erben. Gäste haben eine eigene Fassung
  (Detailstufe `_lod_scale`) und geben zusätzlich auf, wenn sie `STALL_TIME` lang nicht `STALL_RANGE` vorankommen
  (`_stalled`/`_give_up_walk`, Trace „kommt nicht weiter“) – Netz für alles, was die Wegfindung nicht löst.
- **Wegpunkt-Abstand wächst mit der Schrittlänge:** `_move_to` setzt `path_desired_distance` auf mindestens
  Tempo × Schrittzeit × 1,5. Ferne Gäste (Detailstufe), Zeitraffer oder wenige Bilder machen große Schritte – sonst
  springen sie über den Wegpunkt und pendeln minutenlang um ihn herum.
- Türen öffnen Gäste/Monster selbst, wenn sie nahe sind (`_open_doors()`), Gäste nur im Gehen. Die Türen in der Nähe
  liefert **`Door.near(pos)`** (Raster `Door.CELL`) – nicht die Gruppe `doors` je Frame durchgehen (Hunderte Türen ×
  Dutzende Gäste).
- Treppen: Rampe als Kollision (Ebene 1, fürs NavMesh, Meta `stair_ramp`) + Stufen als Optik mit eigenen
  Trittflächen (Ebene 12, nur für Spuren). Läufe müssen bündig an der Flurkante enden, sonst Stolperkante (das NavMesh
  verbindet über `agent_max_climb` trotzdem, die Gastkapsel kommt aber nicht hinauf). Die Lobbytreppe ist unten offen.

### Spuren auf dem Boden
(`scripts/world/trace_mark.gd`, `Traces`)
- **Fläche finden:** `Traces.surface_below` (Ebene 1 + Trittflächen, die Rampe wird übersprungen) – sonst schweben
  Spuren vorn an jeder Stufe. Leichen auf einer Treppe legt `Guest._lie_down` an die Schräge.
- **Flecken** (Blut, großer Wachsfleck `_spread_wax`, Kürbismatsch `Item._lay_mush`) teilen sich die statische
  Platzierung (`TraceMark.downhill_at`, `scatter_offset`, `place_splat` – `{}`, wenn kein Platz ist): Jeder Fleck
  fällt senkrecht auf die Fläche darunter, auf Treppen bergab; kein Fleck ragt über eine Kante (`_blood_fits`), sonst
  längs mittig auf die Stufe (`_flat_span`) oder kleiner. Verteilt wird erst nach dem Platzieren (`call_deferred`, auch
  beim Laden – jedes Mal anders).
- **Zeichnen:** `TraceMark.lay_decal` – `PlaneMesh` mit `shaders/psx_decal.gdshader` (Umriss aus dem Alpha); auf
  einer Stufe eine Reihe **unverzerrter** Quadrate, die sich überlappen (`DECAL_OVERLAP`) – gestreckte Grafiken sahen
  gequetscht aus. Material je Grafik geteilt (`decal_material`), der Kürbismatsch hat ein eigenes. Alle ziehen sich mit
  `SPLAT_PULL` zur Kamera – mehr als Auflagen (`Mat.layer`), sonst verdeckt der Treppenläufer Blut und Matsch.
- **Glanz, Relief, Rand:** `tools/splat_maps.gd` erzeugt aus dem Umriss jeder Grafik `<name>_n.png` (Normal Map) und
  `<name>_d.png` (R Rauheit, G Dicke, B Rauschen); `Mat.decal` lädt beide, `TraceMark.SPLAT_LOOK` stellt je Grafik
  ein. **Überlappende Flecken verschmelzen,** weil der Shader die Tiefe nach der Dicke schreibt (`depth_draw_always`,
  `thick_lift`) – an jedem Pixel gewinnt der dickste Fleck, unabhängig von der Zeichenreihenfolge; deshalb sind die
  Flecken nur hauchdünn gestaffelt (`lift`). Die Karten nach einer neuen Grafik neu erzeugen:
  `godot --headless --path . -s tools/splat_maps.gd -- assets/textures/blood_pool.png edge=10 rough=0.06,0.4 bump=1.6 noise=0.1 grain=8 seed=1`,
  `… wax_splash.png edge=14 rough=0.3,0.55 bump=4 noise=0.35 grain=6 seed=2`,
  `… pumpkin_splash.png edge=8 rough=0.5,0.75 bump=3 noise=0.4 grain=5 seed=3` – feineres Rauschen oder mehr
  `bump` glitzert wie Zucker.
- **Runterlaufen und Ausbreiten:** Auf einer Treppe bleiben nur die großen Flecken; vom ersten, der längs auf einer
  Stufe liegt, läuft ein **Strom** hinunter (`TraceMark.lay_stream`: Kette unverzerrter Quadrate, auf jeder
  Trittfläche liegend, an jeder Stirnseite senkrecht, unten eine Pfütze). Die Vorderkante sucht `_edge_ahead`; auf der
  Lobbytreppe geben die Trittflächen Teppich und Stufennase als Meta mit (`carpet_half`, `carpet_out`, `nosing`,
  `nosing_t`, aus `GrandStair.build`). **Frische** Flecken (`TraceMark.fresh`, `Item.mush_fresh`) breiten sich als
  Tween in Spielzeit aus (`spread_start`, `plan_spot`, `grow`; Werte je Art in `TraceMark.SPREAD`); aus dem Spielstand
  liegen sie gleich fertig. Aufsammeln beendet das Ausbreiten sofort (`Item._finish_spreading`).
- **Im Regen verwaschen** (`world/rain_veil.gd`, Spielkonzept 4.13): Blutlachen, große Wachsflecken
  (`Traces._wash_marks`) und Kürbismatsch (`Item._wash_mush`) unter freiem Himmel (`LevelBuilder.is_outdoor`, Meta
  `outdoor`) verlaufen, solange es regnet: `wash` steigt mit Zeit × Regenstärke / `WASH_TIME`; `RainVeil.show_wash`
  streckt den Fleck und setzt den Instanz-Wert „wash“ von `psx_decal` (kein eigenes Material je Fleck). Beim ersten
  Regen legt `RainVeil.spawn` einen **Schleier** an (Arme und Schlieren mit dem Wind bzw. bergab, aus einem Seed
  gebaut), der nach derselben Formel weiterwächst – Fleck und Schleier bleiben ohne Verbindung im Gleichschritt, auch
  nach dem Laden. Bei wash 1 ist der Fleck weg, der Schleier verblasst danach über `life`. Je Art Maße und Deckkraft in
  `LOOK`. **Gespeichert:** `wash` je Spur, Schleier als Spur `{"kind": "veil", …}`, Kürbismatsch als „w=…“ im
  Zusatzfeld. Debug `--verwaschen[=schleier]`; Rauchtest `spuren`, `wetter`, `kuerbis`.
- **An der Wand** (Spielkonzept 3.13, `Traces.add_wall_splash`, `TraceMark._spread_wall`): Geworfenes Flüssiges ist
  eine Spur „splash_mush:<sorte>“ (Zierkürbis „:mini“), „splash_wax“, „splash_coffee“ oder „splash_tea“ – die Sorte
  steckt im Namen, darum kein neues Speicherfeld. +Z von der Wand weg, Ursprung am Treffpunkt. Ein Fleck als Ebene
  (`_wall_plane`, `FACE_Z`) an der Wand, darunter ein Strom aus `_runner_mesh`-Quadraten bis zum Boden
  (`Traces.surface_below` vor der Wand), unten eine Pfütze (`place_splat`); Maße und Fließtempo je Flüssigem in
  `WALL_SPLASH`, Kürbis nach der Sorte skaliert. Material: Matsch je Sorte wie `Item._mush_mat`, Kaffee und Tee matter
  als am Boden (`WALL_COFFEE_SPECULAR` – senkrecht wirkte der Glanz grau). Frisch läuft er herunter (`grow`). Zählt zu
  den Spuren der Gäste (`MAX_GUEST_MARKS`).

## 4. Level (`scripts/level/level_builder.gd`)

Baut alle Stockwerke aus dem Gebäudeplan (`assets/maps/eg.json`, `og1.json`, `dg.json`, `ug.json`, Abschnitt
unten). **Den Plan zeichnet und möbliert der Zeichner von Hand; der Code stellt nichts dazu.** Braucht eine Mechanik
etwas im Zimmer, kommt es in den Plan. Was der Plan nicht kennt (Münzbetrag, Zettel-Nummer, UV-Text, Schubladeninhalt),
steht in `CONTENT` je Raum-ID; Höhen und Helligkeiten in `BOX_HEIGHTS`, `_lamp_style` und Konstanten.

### Ablauf von `build()`
EG laden (`_begin_floor`: Flächen-Raster `_index_places`, Wandstöße, Haushalte), Treppenschächte (`_index_shafts`) →
`_build_plan_floor()`: Wände (`_build_wall`) → Böden und Decken → Zimmer → Einrichtung (`_furniture`, `_fittings`,
`_rugs`, `_items`, `_lights`) → Lobby und Lobbytreppe
(`_lobby_flight`), Bar/Partyraum/Küche (`_common_rooms`), Pool, Gärten → Treppenhäuser → obere Stockwerke
(`_upper_floor`, Dachgeschoss `_attic_floor`) → Untergeschoss (`_lower_floor`) → Aufzüge → Lichtbereiche
(`light_rooms.finish()`) → Schatten vom Bau (`ShadowBudget.merge(structure_parts)`) → Zonen, Wegpunkte.

**Die Reihenfolge ist Teil des Speicherformats** (Gruppen-Index, siehe 7). Jede Änderung an Lampen, Schaltern,
Verstecken, Kommoden, Truhen, Telefonen, Pflanzen oder Vorräten im Plan verschiebt sie – alte Spielstände werden dann
vom Fingerabdruck abgelehnt, zu tun ist nichts.

- Bauen in **lokalen Rahmen**: `_parent` ist das gerade aktive Bauteil (root, Zimmerrahmen, Schacht); `_wall_x/_wall_z`
  mit Öffnungen als `Vector4(mitte, breite, oberkante, unterkante)`. Gegenstände kommen in die Hauptszene (`world`),
  umgerechnet über `_global()`.
- **Stockwerke** (`UPPER_MAP_PATHS`, fehlt eine Datei, endet das Haus darunter): Jedes obere Stockwerk ist ein weiterer
  Durchgang von `_build_plan_floor()` unter eigenem Knoten (`root` vorübergehend dorthin). Der Zustand je Stockwerk liegt
  in `_floors` (`_state`/`_use`, das UG als letzter Eintrag `_lower`); Abfragen anderer Systeme wählen ihn über die Höhe
  (`_level_of`, `_on_floor`). Raum-IDs ohne Zimmernummer tragen einen Vorsatz (`og1_`, `dg_`, `ug_`; `_prefix`), damit
  oben und unten nicht dieselben Schalter schalten; Treppenhäuser bleiben ein Raum über alle Stockwerke, die Galerie
  über der Lobby gehört zur Lobby. Oben reichen die Wände bis in die Decke darunter (Fassade ohne Fuge), über Lufträumen
  (`voids`) schließt eine Decke die Halle; Geländer mit Blende an Lufträumen (`_void_edges`), Balkone (`_balconies`:
  jedes Balkon- und Terrassengeländer oben ist ein `BalconyRailing`, siehe 8 „Balkongeländer“).
  Bäder gehören zum Zimmer hinter ihrer Tür (`_bath_owner`: Licht, Verschluss); Suiten (`suite`) haben kein Türschild.

### Wände, Böden, Stöße
- **Wände:** Eine Planwand wird dort geteilt, wo sich die Räume an einer Seite ändern (abgetastet, kurze Läufe
  geglättet). Tapete je Seite über `Mat.wallpaper_split` (Zimmer, Bibliothek, Büro der Direktion und Sekretariat –
  `office`/`secretariat`, ZIM-150 – beige, Lobby und Katzenraum rot, sonst teal); Seiten
  ohne Tapete (draußen = Fassade, Bad/Toilette/Pool und Pool-Umkleiden = Fliesen, Lager = Beton) tragen ihr Material
  (`_skin_material`) **auf der Wandfläche selbst** (31.10., ZIM-145; vorher eine 2 cm starke Haut 2,2 cm davor – das
  Fliesenraster ging in den Ecken nicht auf, Schalter steckten dahinter): `Geo.wall_mesh` mit `sides` liefert dann je
  Seite eigene, benannte Flächen (`plus`/`minus`, im Bad bei `BATH_TILE_HEIGHT` geteilt in `…_top` = Farbe), freie
  Stirnseiten (`ends`, `ends_top`) nehmen das Material der gefliesten Seite. Glaswände als Scheibe auf Ebene 7.
  Kollision als Kästen um jede Öffnung, die Optik als **ein** Mesh pro Wand (`Geo.wall_mesh`, Fläche 0 = Wand, 1 =
  Laibungen in Rahmenholz) mit gemeinsamen Ecken auf einem Raster – getrennte Kästen stießen mit Ecken mitten auf
  Nachbarkanten, dort klafften Fugen.
- **Hallen über zwei Stockwerke** (Lufträume): Seiten über `_wall_side_kind` abgetastet, oben heißt die Seite
  `hall:<Art im EG>` (`_halls`); Tapete des EG mit `wall_top` = `HALL_WALL_TOP` – die Rauten laufen nahtlos bis unter
  die Decke. `_subtract` verwirft Reste unter 1 mm (sonst stak eine Deckenplatte ohne Tiefe in der Wand).
- **Wandstöße** (`_index_joints`): Senkrechte Wände ragen bis zur Mitte der waagerechten (`_joint_depth`); läuft eine
  waagerechte durch eine senkrechte (T-Stoß), weicht ihr Kopf bis zu deren Mitte zurück (`_head_inset`) – sonst
  blitzte ihre Tapete durch. Wechselt die Tapete an einer anstoßenden Wand, liegt der Schnitt in deren Mitte
  (`_joints_on`). **Holzpfeiler** (`_corner_posts`, reine Optik) fassen jeden freien Wandkopf ein, an dem zwei Tapeten
  zusammenkommen – kein Eintrag im Plan nötig. Quadratisch (Wanddicke + 6 cm), im Holz der Türen und der Vertäfelung
  (`Mat.hotel_wood`), Sockel und Kapitell profiliert: `Geo.square_profile` zieht ein Profil mit Gehrung um die vier
  Seiten, UVs in Metern (Schaft mit senkrechter Faser, Leisten waagerecht). An der Innenecke (dort stößt eine senkrechte
  Wand bündig mit dem Kopf an, also an jedem Pfeiler des Zimmerblocks) schneidet `notch` den Pfeiler an den
  Wandflächen des Raums ab – sonst ragten Schaft, Sockel und Kapitell in dessen Ecke.
- **Vertäfelung** (`level/wainscot.gd`, Spielkonzept 7.2, entschieden 29.10.): Sockelleiste, Brett mit Rahmenfeldern und
  Brüstungsleiste bis 0,9 m (`Wainscot.HEIGHT`), modelliert als Bausatz (`tools/build_wainscot.py`). `_build_wall` merkt
  jede Wandseite mit Tapete (`_note_wainscot`; nicht Treppenhaus, Aufzug, verschlossene Zimmer, Lufträume über dem EG),
  `_wainscot` zieht nach den Holzpfeilern ab, was sie unterbricht – anstoßende und durchlaufende Wände
  (`_wainscot_blocks`), Türen bis 1 cm unter die Außenkante der Bekleidung, Holzpfeiler (`_post_spans`, 2 mm in den
  Schaft, unten deckt der Sockel) –, unter
  Fenstern (Brüstung 0,9 m) kommt `low` ohne Leiste (dort sitzen Bank und Schürze). Je freies Stück **festes Raster**
  im halben Feld: so viele 0,8-m-Felder wie passen, mittig; steht das Stück um ein halbes Feld über, kommt ein Halbfeld
  `half` (0,4 m) an das Ende zur Tür bzw. zum Fenster (sonst an den Anfang), der Rest als gestrecktes Passstück
  `plain` an beiden Enden (bis 3 cm je Ende strecken oder stauchen stattdessen die Felder; geprüft in
  `tests/math_checks.gd`). Plant man eine Tür nah an eine Ecke, passt ein Abstand von 0,4 oder 1,2 m genau. An
  Außenecken ohne Holzpfeiler läuft ein **Eckstück** mit Gehrung um den Wandkopf (`_wainscot_corner`,
  `Wainscot.add_corner`, `Geo.mitre_profile`): Umriss `Wainscot.OUTLINE` ohne Rahmenfeld im Holz der Pfeiler, 10 cm an
  der Wandseite entlang und über den Kopf bis zur anstoßenden Wand bzw. bis zur Mitte; sonst endeten beide Stücke
  offen und zeigten ihre hellen Stirnseiten. Alles als
  MultiMesh je 16-m-Zelle, ohne Schatten; Holz `wainscot_wood.png` über die Mesh-UVs (0,7 m je Kachel – nicht im
  Verhältnis zum Feld, sonst glichen sich die Felder): Sockelleiste, Brett und Brüstungsleiste laufen über das ganze
  Stück durch (keine Sprünge an den Modulgrenzen), nur die Füllungen sind eigene Bretter (Faser ebenfalls waagerecht) mit
  eigenem Ausschnitt; gestreckte Teile mit unverzerrter Faser (INSTANCE_CUSTOM, siehe 1 „Fototexturen“). Ein dünner
  Kollisionskasten je Stück (bis 12 mm vor der Wand, ein Körper je Stockwerk mit Meta „wainscot“): Flecken, Eier und
  Deko landen auf dem Brett; das Rinnsal eines Wandflecks läuft darunter vor der Brüstungsleiste (`RAIL_FRONT`,
  `TraceMark._spread_wall`). Achtung `Vector4` rechnet in 32 Bit – die Brüstung 0,9 kommt als 0,8999… an.
- **Böden** (`_floor`): ein `Geo.solid` je Planrechteck, Textur in Weltkoordinaten (das Muster läuft über die Stöße).
  Ein Flurrechteck, das in die Lobby ragt, wird an deren Rand geteilt. Verschlossene Zimmer haben einen Boden auf der
  Ebene der Decken (5) – nicht im NavMesh, sonst planten Gäste und Monster Wege durch gesperrte Türen. Unter jeder
  benutzbaren Tür liegt eine Schwelle – ohne Boden in der Wandlücke risse das NavMesh ab.
- **Tapete, Fototexturen, Optik** siehe 1 „Texturen“ und 8 „Optik“.

### Öffnungen, Zimmer, Einrichtung
- **Öffnungen → Objekte** (`_opening_object`): Türen gehen in Zimmer und Räume auf, nie in den Flur (`_inner_side`) –
  außer der Plan gibt mit einem Türanschlag (`hinge`/`opens`) Scharnier und Aufgehseite vor (`Door.hinge_end`); ab
  breiten Öffnungen Doppeltür. Liegt ein Lichtschalter hinter der offenen Tür (`_behind_door`), warnt der Build mit
  Pixelposition. **Aussehen** (`Door.look`): `door` = gemaltes Zimmertür-Modell, `attic_door` = Kniestocktür
  (verschlossen mit Schlüssel `dachboden`, das Monster bricht sie nicht auf), `attic_inner_door` = übrige Türen im
  Dachgeschoss, `frosted_door` = Milchglastür (`Look.FROSTED`, ZIM-143); Betriebstüren behalten das gebaute Blatt.
  Terrassen- und Glastüren sind gläserne Doppeltüren; Fenstertüren nach draußen kommen in die Gruppe `french_doors`
  (Lakengeist). Der Haupteingang ist verriegelt. Fenster: `room_id` = Fläche dahinter (`_room_id_at`).
- **Zimmer** (`_room`): Rahmen am Türmittelpunkt (+X an der Flurwand entlang, +Z ins Zimmer); das Innere kommt aus dem
  Plan, `_room` legt nur die Zimmerart fest: `player`, `guest`, `vacant`, `abandoned`, `derelict`, `locked`.
  **Belegung aus HAUSHALTE.md** (Spielkonzept 6.19, 6.20): `_index_households` liest `assets/data/households.json` und
  ordnet jeden Haushalt und jedes Sonderzimmer über seine Stelle im Plan dem Zimmer zu (`households[no]`,
  `_room_kinds[no]`), alle übrigen sind `vacant`; `ROOM_KINDS` ist nur Rückfall ohne Datei. Weicht das vom Plan ab
  („Zimmer leer“), warnt `_room`. Gäste- und unbewohnte Zimmer sind abgeschlossen (`key_id` `zimmer_<nr>`), bewohnte
  tragen `resident_name` (im Hinweis an der Tür). `PLAYER_ROOM`, `LOCKED_ROOM`, `COMPASS_ROOM`. **Bauphase:** Nur Flügel
  in `OPEN_WINGS`/`OPEN_WINGS_UPPER` sind bewohnbar (`_wing_open`); Zimmer anderer Flügel werden versiegelt (`_seal`,
  auch für das Monster, Vorhänge `HotelWindow.sealed`, kein Inneres).
- **Einrichtung aus dem Plan**, in dieser Reihenfolge (bestimmt die Gruppen-Reihenfolge im Spielstand):
  - `_furniture`: Rezeption (Modell, siehe 1), dann `furniture`. Bett/Schrank → `HideSpot`; Kommode, Nachttisch, Truhe, Schach- und
    Spieltisch, Sofa, Bank, Zimmertisch, Bücherregal als eigene Bauteile mit Blick nach `facing`; sonst ein Kasten in Plangröße mit
    Höhe aus `BOX_HEIGHTS`. **Betten** = Balkenbetten (`BedModel`, 8) in Plangröße (`bed_size`); das Doppelbett hat das
    Kopfteil zur Seite `head`, heraus geht es zur Längsseite mit mehr Platz (`_free_run`), ab `HideSpot.DOUBLE_WIDTH`
    für zwei Schläfer. **Badewanne** = `Bathtub` (`world/bathtub.gd`): gefliester Block in Plangröße mit hohlem
    Keramikbecken; der Fliesenausschnitt ist `CUT` größer als die Öffnung (sonst flimmert er in der Beckenwand); man kann
    hineinsteigen. **Wannenablage** (`tub_shelf`): gefliester Block zum Ansetzen. Waschbecken, Dusche, WC, Bar siehe 1.
    **Mülleimer** = `TrashCan` (`world/trash_can.gd`, Skizze 31.10.): fest 50 × 50 × 95 cm, mittig auf dem Platz im Plan,
    von Wänden um `WALL_GAP` weggerückt (`_clear_of_walls`); Korpus Lack, Deckel Messing mit 5 mm Überstand, gerundeter
    Oberkante und scharfkantiger Öffnung mit dunklem Schacht – Ringe mit runden Ecken durch ein Profil gezogen (`_sweep`),
    Meshes geteilt. UVs in Metern, u ringsum (Bürstrichtung), auf waagerechten Flächen je Seite auf 45°-Gehrung
    (`_mitre_uv`) wie bei einem Bilderrahmen.
    **Gartentisch, Gartenstuhl** = `GardenFurniture` (`world/garden_furniture.gd`, ZIM-51, Fotos 31.10.): Tisch 80 × 80 ×
    75 cm, Stuhl 50 × 60 cm mit Sitzplatz (`Seat`), Gestell aus Vierkantrohr (`Geo.rounded_box`, je Rohr beliebig
    gedreht), Latten und Armauflagen aus Wood_02 wie Teak getönt (`Geo.grain_box`), Sitz und gerade geneigte Lehne aus
    Gewebe, das zwischen den Rohren durchhängt (`Parts.sheet`, beidseitig). Je Möbel ein Mesh mit den Flächen Lack,
    Längsholz, Hirnholz, Gewebe, von allen Tischen bzw. Stühlen geteilt. **Leichte Drehung:** `_jitter(rect)` zieht aus
    Stockwerk und Lage im Plan einen festen Zufall – der Tisch dreht sich bis `GARDEN_TABLE_TURN`, der Stuhl
    `GARDEN_CHAIR_TURN` Grad nach links oder rechts zu seiner Vorderseite und rückt bis `GARDEN_CHAIR_SHIFT`. Bei jedem
    Start und nach dem Laden gleich, ohne Spielstand; wird das Möbel im Plan verschoben, fällt der Zufall neu. Der
    Gartentisch nächst einer Gartentür von 13 ist der Futtertisch der Krähen (`feed_table`).
    **Spindblock** = `LockerBank` (`world/locker_bank.gd`, ZIM-145, Foto 31.10.): 3,60 × 0,90 m (Plan 36 × 9 px),
    Rücken `WALL_CLEAR` (5 mm) vor der Hinterkante des Rechtecks. Sockel mit Sitzplatte 50 cm
    (eigener Körper mit `Seat`), hinten darauf 6 × 2 Spinde 40 × 90 × 50 cm und rechts (von vorn) ein Regal 1,20 m mit
    3 × 2 Fächern. Platten als Kästen mit gleicher Kollision (Fächer hohl), innen je Fach eine weiße Auskleidung; Türen
    mit schwarzem Kern und Holzdekor (Wood_02, `Geo.grain_box` mit senkrechter Faser), 8 mm Luft ringsum, Schloss oben
    rechts. Ein Mesh je Block mit allen festen Türen; die, die aufgehen, sind eigene Körper mit Scharnier links (95°).
    Gebaut erst nach allen Möbeln (`_locker_banks`): die Nummern laufen je Stockwerk über alle Blöcke, nach Raum von West
    nach Ost, im Raum „links unten im Plan“ zuerst (kleinstes x − z), im Block spaltenweise von links oben. Welche
    aufgehen, steht in `LockerBank.OPENABLE` (frei oder mit `KEY` „spind_NN“, Bund-Beschriftung „Spindschlüssel N“);
    die übrigen rütteln nur. Beim ersten Öffnen ein Fund wie in der Kommode (Schlüsselspinde nie leer), Spinne wie bei
    der Schublade. Gruppe `locker_banks` (offen, aufgeschlossen, durchsucht). Hinweis „Spind N · …“, Lärm `locker`.
    **Umkleidebank** = `ChangingBench` (`world/changing_bench.gd`): so lang wie im Plan (3 m), 60 cm breit, 50 cm
    hoch, Fußrahmen an den Enden und an jedem Meter (3 m → vier), Längsrohre, fünf Latten – Rohr und Holz aus `GardenFurniture.Parts`, ein
    `Seat` mit Plätzen auf beiden Seiten, ein Mesh je Länge.
    Eine Truhe in einem Hotelzimmer ist dessen Süßigkeiten-Truhe (`_sweets_chest`); Snack- und Getränkeautomat sind
    `VendingMachine`. Jedes Möbel landet mit Oberkante in `_furnishings` – `_top_at(p)` liefert die Höhe, auf der
    Kerzen, Telefone, Zettel und Gegenstände stehen.
  - `_fittings`: Wandsachen (Schalter, Bild, Spinnwebe, UV-Schrift, Kalender) über `_wall_spot` an die Wandfläche
    (`_on_wall`), Höhen als Konstanten (`SWITCH_Y` …). Telefon, Zettel, Tagebuch und Vorräte auf dem Möbel darunter,
    Kürbispflanzen mit der Sorte aus der Palettenfarbe (`pumpkin_plant:<sorte>`).
    **Duschplatz** am Pool = `PoolShower` (`world/pool_shower.gd`, ZIM-144, Fotos 1.11.): Ursprung am Boden auf der
    Wandfläche (`POOL_SHOWER_GAP` 2 mm davor), alles Code-Geometrie in `Mat.metal()` wie die Badarmaturen. Drücker als
    Drehkörper (`Geo.lathe`, Achse aus der Wand): Manschette Ø 14 cm, Knopf 8 cm tief auf 1 m, dunkler Dichtring.
    Ablage 24 × 11 cm rechts daneben (von vorn), Mitte auf Drückerhöhe, aus gerundeten Kästen (Rückenplatte, Boden,
    Rand), ohne Halterung. Duschkopf Ø 25 cm, Mitte 40 cm vor der Wand, Unterkante 2,10 m: Wandarm als Rohr mit Bogen
    (`_tube`), Rosette, Kugelgelenk, Düsenplatte mit `shower_shower_nozzles.png` der Zimmerdusche. Ohne Kollision
    (zu hoch bzw. weniger tief als der Spielerradius) bis auf einen Körper um den Drücker (Ebene 4, `interactable`):
    Druck → `RUN_TIME` 25 s Wasser (nicht gespeichert), Knopf geht 6 mm hinein. Strahl = `CPUParticles3D` aus Punkten
    über der Düsenplatte mit `shaders/rain_streak.gdshader` (Lebenszeit = Fallzeit bis zum Boden), Dampf weiche
    Ballen wie in `ShowerScare`, deren Deckkraft in `STEAM_WARMUP` wächst. Rauschen über `SynthAudio.pool_shower`
    (lautester Platz aus `_sounds`, dumpf außerhalb des Raums), mischt sich mit `shower` der Zimmerdusche; Lärm
    `shower_button` beim Drücken und `shower` alle 3 s. Gruppe `pool_showers`, Debug `--duschen[=an]`.
    **Bodenablauf** (`floor_drain`) = `PoolShower.drain`: Edelstahlplatte 15 × 15 × 0,3 cm, darüber eine Fläche mit den
    8 × 8 Löchern als Textur (zur Laufzeit erzeugt, durchsichtig außer den Löchern, mit Mipmaps). Im Becken auf dessen
    Boden (`POOL_DEPTH`).
  - `_rugs`: Teppiche als flache Auflage (`Mat.layer_uv`). Ein Läufer läuft entlang der langen Seite
    (`Geo.runner_mesh`: Abschluss an beiden Enden, ganze Zahl Musterkacheln); Art → Textur in `RUG_TEXTURES`. Im
    Katzenraum lose Teppiche aus `CAT_ROOM_RUGS` (`TexGen.rug`), jeder etwas höher als der vorige (Überlappen ohne
    Flimmern).
  - `_items`: `Item.Kind`-Name aus dem Plan, auf dem Möbel darunter.
  - `_lights`: Wandleuchten je Flächenart (`_lamp_style`), Deckenleuchten (`_ceiling_lamp`: `Lamp.Style.FLUSH` =
    Kupferleuchte, über `open_above` Pendel `CEILING`), Kerzen auf dem Möbel, Laternen; `broken` aus dem Plan.
    **Schreibtischlampe** (`_desk_lamp`, `Lamp.Style.DESK`, „Licht: Schreibtischlampe“): grüne Bankerlampe aus
    `tools/build_desk_lamp.py` (CGTrader-Modell ohne Röhre und Zugkette, PBR-Set 2048 px, `Mat.pbr_model`) auf dem Möbel
    darunter (`_top_at`), Schirm zum Sitzplatz (`_seat_yaw`: `SEAT_REACH` vor der Mitte der Vorderkante, höchstens
    `DESK_LAMP_MAX_TURN` neben der Vorderseite – an der Ecke schräg, mittig gerade), dazu ±`DESK_LAMP_JITTER` fest aus
    der Lage (`_jitter`); ohne Möbel mit Vorderseite wie das Telefon (`_upright_yaw`); Raum-ID wie die
    übrigen Lampen, `DESK_LAMP_ENERGY`/`_RANGE`. Die gewöhnliche Birne liegt waagerecht unter dem Schirm
    (`DESK_SOCKET`, herausdrehbar). Anders als die übrigen Leuchten wirft das Modell Schatten – so hält der Schirm das
    Licht nach oben und hinten ab, ohne Projektor.
    Kupferleuchte: Opalglas mit dem Material der Birne (leuchtet, flackert, erlischt mit ihr), die Birne steckt unsichtbar
    dahinter; Licht `FLUSH_LIGHT_BELOW` unter dem Glas – näher strahlte es das Kupfer grell an. Lampen und Schalter
    gehören zur Raum-ID der Fläche davor (`_light_room_at`); Schalter in unbewohnten Zimmern starten aus.
    **Immer an** (`ALWAYS_LIT`, ZIM-145: die Lichtgruppe „umkleiden“ = Vorraum, Duschen, Umkleiden am Pool): Schalter
    im Plan entfallen dort mit Warnung, die Lampen sind `Lamp.fixed` – kein Hinweis, nichts herauszudrehen
    (`has_socket` falsch), brennen nicht durch; Stromausfall und Flackern wirken über `FlickerLight` wie überall.
    Über jedem Badspiegel (`_washbasin` mit Raum-ID, nicht in den Toiletten) eine Spiegelleuchte `Lamp.Style.MIRROR`:
    Edelstahlbalken (`Mat.metal()` wie die Armatur) mit Lichtband aus dem Material der Birne, keine Birne zum
    Herausdrehen (`has_socket` falsch), brennt nicht durch; Werte `MIRROR_LAMP_*`.
    **Podestregel im Treppenhaus:** Eine Wandleuchte gegenüber der Treppenhaustür hängt eine halbe Etage höher.
  - Nicht im Plan, im Code: Ersatzleuchten im Treppenhaus, Inhalt des Heizkellers, Waschmaschinen, Flaschen, Hocker,
    Tanzfläche, Beete, Treffpunkte der Gäste (`_common_rooms`, `_lobby_hall`, `_garden_beds`).
- **Kratzbaum** (`_cat_tree`): Liegeplatz in `cat_perches`.
- **Holzdeck** auf Terrassen und Balkonen (`scripts/level/deck.gd`, `Deck.build` aus `_deck`, ZIM-127): Bretter als
  Geometrie (Oberseite auf y = 0, gefaste Längskanten, Seiten, Hirnholz; unten offen), 14,5 cm breit, 8 mm Fuge, 2,8 cm
  stark, Wood_02 hell getönt über die UVs (je Brett ein anderer Ausschnitt), nass glänzend. Reihen über die ganze
  Fläche: `_row_pieces` teilt eine Reihe an den Kanten der Plan-Rechtecke in Streifen und legt je Abschnitt ein Brett
  über die Streifen, die dort Fläche sind – über Nahtstellen von L-Formen durchgehend, am Rand schmaler aufgetrennt.
  Läufe über `MAX_BOARD` bekommen versetzte Stöße (`_cuts`). Laufrichtung quer zu der Seite, hinter der auf der
  längsten Strecke das Haus liegt (eine Richtung je Fläche, auch bei L-Formen). Fuge `DECK_WALL_GAP` zur Wand,
  `DECK_EDGE_GAP` zu Hecke bzw. Geländer (Kantenstreifen im Plan), sonst keine. Darunter `_deck_base`: Kollision wie ein
  Boden mit Oberkante 0, die sichtbare Platte `DECK_DROP` tiefer und dunkel (durch die Fugen zu sehen); Schritte über
  die Meta „floor“ = wood. Kantenstreifen und Kübel bleiben Stein.
- **Hecken** (`scripts/level/hedge.gd`, `Hedge.build` aus `_gardens`): Terrassenkanten im EG werden Formschnitthecken.
  `_lines` fasst Stücke einer Mittellinie zusammen, Abschlüsse (`_end`) mit Gehrung oder verdeckt. Die Ecken wandern
  nach einem Rauschen ihrer **Weltlage** – gleiche Ecken zweier Stücke wandern gleich, an Gehrungen bleibt keine Fuge.
  Blattkarten (`_cards`, `psx_leaves`) brechen den Umriss auf; Normale der Fläche darunter, damit die Blätter wie die
  Hecke beleuchtet werden. Eigener Zufall je Linie (Spielstände unberührt).
- **Schrift im Haus:** Schilder über den Türen (Zimmernummern, BAR, PARTY, GARTEN, POOL, TREPPENHAUS, AUSGANG) sind
  seit 31.10. weg; beschriftet sind nur die Gästezimmertüren (Messingplakette, `RoomPlate`) und der Aufzug. Buchstaben als `TextMesh` bekommen Licht wie alles andere. Schrift Cinzel Bold (SIL OFL 1.1,
  `assets/fonts/OFL.txt`), gebaut von `tools/build_font.py`: TextMesh verträgt keine überlappenden Konturen, deshalb
  eine feste Instanz mit verschmolzenen Konturen ohne doppelte Eckpunkte. Bei „Triangulation/Convex decomposing failed“
  neue Zeichen dort prüfen.

### Lobby, Treppen, Aufzug, Pool
- **Lobby und Galerie:** Mit `og1.json` baut das Obergeschoss die Galerie aus seinem Plan, die Lobby hat ihre Decke
  bis auf den Luftraum (`open_above`); ohne die Datei die alte Galerie (`_gallery`).
- **Lobbytreppe** (`scripts/level/grand_stair.gd`, `GrandStair.build` aus `_lobby_flight`): gerade Wangentreppe im
  Rechteck des Plans, unten offen; Läufer im Wasserfall-Stil, gedrechselte Stäbe als `MultiMesh`. Ein Mesh je Material
  (`GrandStair.Shape`). **Kollision:** Rampe unten durch die Mitte der ersten Trittstufe, oben bündig mit der
  Galeriekante (lief sie auch oben durch die Trittmitten, blieb eine halbe Stufe Kante, an der Gäste festhingen);
  Geländer als schräge Prismen mit senkrechten Enden (ein gekippter Kasten ragte auf Hüfthöhe vor die Treppe). Der Läufer
  hängt an der Rampe – `Footsteps.floor_under` hört Teppich. Geprüft in `tests/math_checks.gd`.
  **Galeriegeländer** (`GrandStair.railing`, aus `_void_edges`) mit **Blende** (`GrandStair.fascia`): `out` zeigt in
  den Luftraum – andersherum steckt die Blende in der Platte und flimmert.
- **Treppenhaus Ost:** Schacht über alle Geschosse im eigenen Rahmen (`_index_shafts`), je Geschoss zwei Läufe mit
  Wendepodest; Anfang und Ende aus den Treppenstufen im Plan (`steps`). Die Mittelwand baut der Schacht (Planwände im
  Schacht werden übersprungen, `_in_shaft`), Außenwände und Türen die Pläne. Treppenhaus West ist auf allen Stockwerken
  versiegelt (`_seal_stairwells`), außer der Tür im OG1 zur Dachbodentreppe.
- **Aufzug** (`scripts/world/elevator.gd`, Spielkonzept 7.4): `_elevators()` baut je Schacht (Fläche `elevator`) einen
  `Elevator` unter `world` – **die Kabine bewegt sich, sie darf nicht ins NavMesh**. Der westlichste Schacht fährt
  (`working`, Gruppe `elevators`), die übrigen sind tot (`_ghost`: wandernde Anzeige, nicht gespeichert).
  - Kabine: `AnimatableBody3D` (`sync_to_physics`), **alle Formen am Körper selbst** – nur so bekommt der Spieler die
    Geschwindigkeit der Plattform und fährt mit. Wände `Mat.photo(…, object_uv = true)` (in Weltkoordinaten wanderte die
    Textur). Spiegel an der Rückwand (`_mirror_wall`, `Mirror`).
  - Teleskoptüren je Halt (`_layout`: lichte Breite aus dem Platz im Schacht, den Rest füllt ein Portal), Schachttüren
    `AnimatableBody3D` auf Ebene 2; die Kabinentür ist nur Optik, solange sie zu ist, schließt `_doorway` die Öffnung.
    Lichtschranke `_in_doorway`.
  - Für das Monster beim Urteil (4.33): `carries(pos)`, `moving()`, `next_stop()`, `waiting_spot(i)`, `call_cabin(i)`.
  - Ablauf in `_physics_process` (Warteschlange `_queue`); Lärm `elevator`, `elevator_bell` (machen das Monster
    neugierig), `elevator_alarm`. Gäste und Monster benutzen ihn nicht (beim Urteil wartet das Monster an der
    Haltestelle, s. u.); die Reparatur (Spielkonzept 7.4) fehlt.
- **Pool** (`_pool`): Becken mit Fototextur-Fliesen, Einstiegstreppen (`_flight(…, step_h)` – Stufen auf dem
  Fliesenraster), Handlauf `HANDRAIL_MODEL`. Darüber die Holzdecke (dicht auch gegen Regen). **Unterwasserlampen**
  (`Lamp.Style.POOL`, „Licht: Unterwasserlampe“ in der nächsten Beckenwand, sonst `POOL_LAMPS_PER_SIDE` je Längswand; ohne Birne – `has_socket()` falsch, Gäste klauen nichts) laufen durch den
  Regenbogen. **Wasser** = `PoolWater` (`world/pool_water.gd`, `shaders/psx_water.gdshader`): Wellen rein optisch im
  Vertex-Shader; Wellenringe im Array `ripples` (`MAX_RIPPLES` – **Shader-Konstante gleich halten**), Abprall als
  Spiegelquellen hinter den Wänden; `_track()` erzeugt Ringe für Spieler und Monster, `splash()` beim Eintauchen;
  Schaum, wo Kämme zusammenkommen. **Monster** (`_update_unrest`, Spielkonzept 4.13): nah → glatt, näher → Zittern
  (`tremor`, nur Fragment-Shader), in der Halle → Schwappen (`slosh`), höchstens `max_rise` – das Wasser bleibt unter der
  Kante. Debug `--pool=still|tremor|slosh|off`.

### Dachgeschoss (`_attic_floor`, Spielkonzept 4.21)
Eigener Durchgang statt `_build_plan_floor` (`dg.json`, `_attic` an, Raum-IDs mit `dg_`). Alles aus **groben Bohlen**
(`Mat.planks`). **Schrägen** (`_attic_eaves`, `_eave_strip`, `_attic_slopes`): Wo eine Wand draußen auf der einen und
Dachboden auf der anderen Seite hat, ist sie nur Kniestock (`ATTIC_KNEE`) hoch, darüber steigt eine Schräge bis zur
Decke (Kollision auf Ebene 5). `_attic_ceiling(p)` liefert die Deckenhöhe an jeder Stelle; `_wall_piece` kappt damit
jede Wand (`_wall_top`, `_top_breaks`, `_cap_top`, `_wall_box`). Giebeldreiecke schließen Spalte (`_attic_gable`).
**Dachfenster** (`roof_window` auf der Außenwand) sitzen in der Schräge darüber (`_roof_window`), mit kaltem Lichtkegel
von außen (`ATTIC_SHAFT_*`, `AtticHaze` regelt ihn mit dem Mond). **Türen:** Kniestocktür-Modell, `ATTIC_DOOR_H` (2,1 m) hoch,
unter einer Schräge nur so hoch, dass `ATTIC_DOOR_HEAD` bis zu ihr bleibt (`_attic_openings` → `o["height"]`, darum
laufen `_attic_eaves` vorher); die zum Treppenhaus verschlossen. Unter niedrigen bäckt das NavMesh nicht durch
(Agentenhöhe 1,6 m): Jede niedrige Kammertür bekommt einen `NavigationLink3D` (`ATTIC_LINK_REACH`), die Kniestocktür keinen – der Dachboden bleibt vom Rest getrennt. **Stützbalken** (`_attic_beams`): Felder von etwa `ATTIC_BAY`, je ein Pfosten mit
Balkenkreuz und Kopfbändern, nie unter einer Schräge oder zu nah an einer Tür; ein Arm, der näher als
`ATTIC_ARM_DOOR_GAP` an einer Tür auf die Wand träfe, entfällt (die Türen reichen über die Balkenunterkante). „Dekokiste“ wird hier zur Kiste mit alter
Deko. **Kopf des Kürbismanns** auf der Markierung `cross` des Plans (`_attic_markers`, `pumpkin_head_spot`). Nebel
`_attic_haze` (`AtticHaze`, 8), Spuk `AtticSpook` (8). **Treppe** (`_attic_stair`): im Schacht des Treppenhauses West ein
steiler Lauf hinauf, oben ein Verschlag; Planstriche ohne Dachboden daneben baut `_build_wall` nicht. Debug
`--dachboden[=kopf|fenster|treppe|blitz|urteil]`.

### Untergeschoss (`_lower_floor`, Spielkonzept 7.9)
Durchgang unter „Untergeschoss“ (y = `CELLAR_Y`, Raum-IDs mit `ug_`). Wände aus Brettschalungsbeton (`_cellar_wall`,
ohne Häute und Holzpfeiler); sie reichen in den EG-Boden und **enden mitten in der Platte** (bündig flimmerten ihre
Köpfe durch die Bodentextur), nur am Treppenschacht die vollen Höhe (sonst Fuge im Treppenhaus). Flächen `cellar`
(Gänge – Türen gehen nicht in sie auf), `boiler_room`, `plant_room`, `laundry_room`, `trash_room`, `cellar_room` (Boden
auf Ebene 5 wie verschlossene Zimmer). Öffnungen in der Farbe des Haupteingangs sind hier verschlossene Türen. Licht nur
aus **Halogenleuchten** (`_halogen`, `Lamp.Style.HALOGEN`: brennen immer, keine Birne, `FlickerLight.stutter`
Aussetzer). Zonen `_lower_zones`; Wegpunkte (`_lower_waypoints`) nur in `patrol` fürs Monster – Gäste gehen nicht
hinunter.
- **Heizkeller** (`_boiler_room`): Versteck des Monsters, `cellar_center()`, dazu Kisten, Schlüssel 18, Zettel, alte
  Deko. **Kohlekessel** (`scripts/world/boiler.gd`, `Boiler`, `boiler.glb` aus `tools/build_boiler.py`): Feuerklappe
  (`fire_door`, Ursprung im Scharnier) offen, Glut, Flammen-Partikel; Licht als `SpotLight3D` mit eigenem Schatten im
  Feuerraum – der Kessel selbst begrenzt den Kegel auf die Öffnung – plus schwacher Schein (`FlickerLight` in `lamps`,
  zählt für `light_at`: am Kessel schreckt das Monster etwas zurück). Der Kegel ist kein `light_source` (die Gruppe
  erwartet `OmniLight3D`), er folgt dem Schein (Meta `hidden_mask`). Knistern `SynthAudio.fire` über `Game.hearing`.
  Nicht gespeichert.
- **Rohre** (`scripts/level/pipe_kit.gd`, `PipeKit`, `pipes.glb`): `run(punkte, anfang, ende, halter_y)` legt einen
  achsparallelen Rohrzug mit Bögen, Flanschen und Haltern; keine Kollision, Meshes geteilt. `_boiler_pipes` legt die
  Leitungen im Heizkeller.

### Ergebnisse für andere Systeme
`rooms` (Nummer → `{no, sign, kind, center, door_front, door_inside, along, into, door, spots}`), `zones`,
`spawn_points` (`[0]` = Heizkeller), `patrol` (`{pos, room}`), `wander_points`, `player_spawn`, `player_door_front`,
Lobby-/Bar-/Garten-/Feier-Punkte, `party_corner`, `stairwell_point`, `game_table`, `chess_table`, `diary`,
`cat_perches`, `tree_spots`, `room_spot(no)` (Debug-Teleport). Abfragen (alle Stockwerke, nach der Höhe – Punkte am
Boden abfragen): `in_lobby(p)`, `in_area(p, id)`, `is_outdoor(p)` (auch Balkone), `in_corridor(p)` (Flur nach Grundriss,
ohne Lobby und Galerien), `room_at(p)` (Raum-ID wie bei Fenstern und Schaltern, leer auf Podesten), `home_room_at(p)`
(Bad zählt zum Zimmer), `is_safe(p)` (Katzenraum), `cellar_center()`.

**NavMesh** wird in `main._bake_navigation` zur Laufzeit gebacken (nur Ebene 1). `--navcheck` misst Bau- und Backzeit
und prüft die Wege zu allen wichtigen Orten (ohne Suchgrenze wie das Monster). `--navcheck=tueren` prüft, ob das
Monster vom Keller aus jede bewohnte Zimmertür erreicht (`MonsterDirector.reachable`, Spielkonzept 4.33).

**Ein neues Zimmer:** im Plan zeichnen und in den Objektebenen einrichten (Bett, Schrank, Leuchte, Schalter …),
Bewohner in HAUSHALTE.md – Wände, Tür, Einrichtung, Zone und Wegpunkt entstehen daraus.

### Gebäudeplan (`map_a.aseprite` → `tools/build_map.py` → `assets/maps/<stockwerk>.json`)
Der Plan liegt im Projektwurzelverzeichnis und wird **nur gelesen** (nie bearbeiten). Umsetzen:
`python tools/build_map.py [map_a.aseprite] [assets/maps] [vorschau-ordner]` (reines Python). Die Vorschau
(`<stockwerk>.svg`) zeichnet das Ergebnis **aus den JSON-Daten** – gut zum Prüfen nach Planänderungen.
**Automatisch beim Spielstart** (`LevelBuilder.refresh_maps()`): Ist eine Datei aus `PLAN_SOURCES` neuer als die
älteste Karte, ruft das Spiel `build_map.py` auf (blockierend) – nur mit dem Feature `editor`, im Export fehlt der Plan.
Warnungen erscheinen als `push_warning` „build_map: …“; schlägt es fehl, baut das Spiel aus den alten Karten.
`PYTHONIOENCODING=:replace` hält Python in der Codepage, in der Godot die Ausgabe liest (Umlaute).
- **Aufbau der Plandatei:** Die Stockwerke liegen untereinander, je `BAND` hoch und deckungsgleich versetzt (DG, OG1,
  EG, UG – `ALL_FLAT_FLOORS`; ein Plan mit weniger Bändern beginnt weiter unten). Gezählt werden alle normalen Ebenen,
  **egal ob sichtbar**; nicht gezählt Referenzebenen und Ebenen, deren Name mit `Beschriftung`, `Skizze`, `Notiz` oder
  `temp` beginnt (`IGNORED_LAYERS`). Ältere Pläne mit Ebenengruppen je Stockwerk gehen weiterhin. Ursprung = Mitte des
  Haupteingangs im EG (`entrance_origin`), `WING_SPLIT_X` dessen x.
- **Legende = `PLANFARBEN.md`** (seit 31.10., gemeinsame Arbeitsgrundlage von Zeichner und Code): je Gruppe eine
  Markdown-Tabelle (Farbe, Name, Vorderseite, Hinweis), die Überschrift gibt den Vorsatz („## Möbel“ → `Möbel: …`);
  „–“ statt Farbe = im Code vorgesehen, noch ohne Farbe. Gelesen über `tools/plan_legend.py` (prüft doppelte Farben
  und Namen); dort stehen auch die Regeln des Plans und der **Bestand**, was der Code selbst setzt (Ersatzplätze,
  feste Orte, Regeln). **Planplätze statt fester Orte** (ZIM-158): Was der Code sonst an eine feste Stelle setzt,
  merkt sich der LevelBuilder beim Bau aus dem Plan in `planned` (Art → `{level, pos, out, rect, at}`; `_plan`,
  `_plan_wall` für Wandsachen, `PLANNED_ONCE` = nur der erste Punkt gilt). Im Builder fragt `_planned_here(kind, area)`,
  von außen `planned_at(kind, fallback, y, gap)` (Transform, +Z in den Raum) – ohne Planeintrag gilt der alte feste
  Platz. So: Spielautomat, Puppenhaus, Barhocker, Maskenboard, Apfelbottich, Sicherungskasten, Aushangbrett, Wanduhr,
  Krähennest, Leviathan-Druck, Teppich, Discokugel (Tanzfläche darunter), Unterwasserlampen, Waschmaschinen.
  Die Zuordnung Name → Bauteil bleibt in `FILLS`, `OPENINGS`, `FURNITURE` … oben in
  `build_map.py`. **Nicht in der Plandatei**: Aseprite behält keine Palettennamen. Neue Farbe → Zeile in
  `PLANFARBEN.md`, dann `python tools/build_colors.py`: zeichnet `map_colors.png` (Vorlage mit exakten Farben für die
  Pipette, rot = noch nicht gebaut), schreibt `map_a.gpl` (Palette für Aseprite, nicht von Hand ändern) und meldet
  Namen ohne Bauteil bzw. Bauteile ohne Farbe. **Farbleitsystem** (Farbbereich je Gruppe, Vorderseite heller) in
  `tools/plan_recolor.py` (`DESIGN`): `vorschlag` prüft Abstände und zeichnet Vorschauen nach `temp/umfaerben/`,
  `anwenden` färbt den Plan verlustfrei um (nur Ebenen, die nach Farben gelesen werden; Sicherung, Probe an einer
  Kopie – build_map muss dieselben Karten ergeben, sonst Abbruch) und schreibt `PLANFARBEN.md` um. Ältere Pläne (`map.aseprite`) lesen weiter `<plan>.gpl`. Farben ohne
  Legendeneintrag meldet `build_map.py` mit Pixelposition, Legendenfarben in der falschen Ebene ebenfalls. Slices liest
  es nach Namen sortiert (Aseprite ändert ihre Reihenfolge beim Speichern – sonst wechselte der Fingerabdruck der Welt).
- **Grundriss:** 1 m = 10 px, Wände 2 px, Öffnungen als Farbstriche **auf** der Wandlinie (**Türanschlag**: ein Pixel
  `Türanschlag` statt eines Türpixels an einem Ende, in der Wandhälfte, in die die Tür aufgeht; falsch gesetzt bricht
  das Skript mit Position ab), Flächen als Füllfarben, `Luftraum` = hier kein Boden (darunter `open_above`). Schrift in
  Wandfarbe wird übermalt, gehört aber in die Ebene `Beschriftung`.
- **Ebene `Zimmer`** (`UNITS_LAYER`): deckende Flächen markieren die Hotelzimmer; alle Flächen „Zimmer“ unter einer
  Markierung werden ein Zimmer (Türen dazwischen sind Innentüren, Bäder bleiben `bath`). **„Zimmer leer“** statt
  „Zimmer“ gemalt → `"vacant": true`. **Zimmernummern** aus schwarzen Pixelziffern (`DIGITS`) in der Ebene
  `Beschriftung` auf der Markierung („13“ → `no` „013“, `sign` „13“); ohne Ziffern zählt das Skript selbst (`WINGS`,
  `PINNED`, `number_from_eg`, `BROKEN_SIGNS`). Sonderzimmer und feste Gäste hängen an der Nummer, nicht am Ort.
- **Objektebenen** je Stockwerk: `Möbel`, `Ausstattung`, `Gegenstände`, `Lichter`, `Teppiche` (eigene Legende mit
  Vorsatz `Möbel:` … → `FURNITURE`, `FITTINGS`, `ITEMS`, `LIGHTS`, `RUGS`). Möbel sind Rechtecke, `Möbel: Vorderseite`
  bzw. `<Möbel> Vorderseite` (`FRONT_SUFFIXES`; Doppelbett `Kopfende` → `head`) zeigt die Vorderseite. Alles andere ist
  ein 3×3-Punkt; Wandsachen liegen innen an der Wand (daraus die Wandseite); Halogenleuchten sind Striche in ihrer
  Länge. Gleichfarbige Punkte dürfen sich nicht berühren.
- **Türarten:** Zimmertüren sind Striche in `Tür Flur`; das Skript liest beiderseits, wohin sie führen: Bad →
  `bath_doors`, beiderseits Zimmer → `connecting_doors`, sonst Flurtür (weitere Flurtüren `side_doors`; ohne Flurtür
  über dem EG eine Suite). Ein Zimmer ganz ohne Tür bleibt geschlossen (Hinweis beim Bauen).
- **Slices:** `Raum: <Name>` benennt eine Fläche (die ganze zusammenhängende; zwei Raum-Slices auf einer Fläche →
  Warnung, der alphabetisch spätere gewinnt), `Bereich: <Name>` → `areas`, `Treppe: <Name>` (**Pivot an der oberen
  Kante**) und `Treppenhaus: <Name>` → `stairs`, `Objekt: <Name>` (Pivot an der Vorderseite) → `objects`. Treppenhäuser
  über dem EG brauchen keine eigenen Slices (gleiche ID wie der Schacht im EG). Das Skript baut zuerst das EG, damit die
  Treppenflächen darüber und darunter dem Schacht zugeordnet werden.
- **Markierungen:** Ein Kreuz in der Farbe `Haupteingang` mitten auf einer Fläche → `{"kind": "cross", "pos"}`.
- **Ausgabe** (Meter, x Ost, z Süd, Ursprung = Mitte Haupteingang, Rechtecke `[x0, z0, x1, z1]`):
  `walls` (`a`, `b`, `thickness`, optional `glass`, `openings` mit `kind`/`at` = Abstand ab `a`/`width`, mit
  Türanschlag `hinge` = `start`/`end` und `opens` = ±1 (+1 = nach Süden bzw. Osten); waagerechte Wände laufen durch,
  senkrechte enden bündig an ihnen), `regions` (`id`, `kind`, `outdoor`, `rects`, optional `name`; die Fläche `flure`
  umfasst alle Flure **und** die Lobby), `rooms` (`no`, `sign`, `wing`, `rects`, `center`, `door` mit `pos`/`normal` in
  den Flur, `windows`, `garden_doors`, optional `bath_doors`, `connecting_doors`, `side_doors`, `suite`, `vacant`),
  `stairs` (`id`, `kind` `stair`/`stairwell`, `rect`, `up` bzw. `door`, `steps`), `voids`, `open_above`, `areas`,
  `objects` (`name`, `rect`, `facing`), `corridors` (Flurabschnitte mit Mittellinie), `floor_patches` (Boden unter
  Kübeln, Bäumen, Rezeption, freien Treppen), `planters`, `terrace_edges`, `balcony_edges`, `trees`, `reception`,
  `markers`; aus den Objektebenen `furniture` (`kind`, `rect`, optional `facing` bzw. `head`), `fittings` und `items`
  (`kind`, `pos`, optional `wall`), `lights` (optional `broken`, Halogen mit `axis`/`length`) und `rugs`.
- `export_presets.cfg` packt `assets/maps/*.json` und `assets/data/*.json` (Haushalte) mit ein (`include_filter`),
  weil JSON keine Godot-Ressource ist. Fehlt die Haushaltsdatei, fällt das Spiel auf `ROOM_KINDS` und die alte
  Gästeverteilung zurück.

## 5. Das Monster

Zwei Teile: **`MonsterDirector`** entscheidet *ob/wann/wohin* (versteckte Werte, Dramaturgie,
Effekte), **`Monster`** führt aus (Zustandsautomat, Bewegung, Sicht, Spuren).

**Nur eine Bedrohung im Haus** (Spielkonzept 4.20): `MonsterDirector.other_threat_active(wer)` – Monster aktiv,
`SheetGhost.is_active()`, `PumpkinMan.in_house()` oder seine Ankündigung, außer dem Fragenden selbst. Gefragt wird beim
natürlichen Erscheinen: `_update_schedule` (Auftritt um 10 s verschoben), die Siegerehrung (`DoorContest`),
`SheetGhost._check_spawn`, `PumpkinMan._check_spawn` (vor dem Wurf), der Zeitsprung. Debug-Aufrufe (F5/F7/F9,
`--warn`, `--ghost`, `--pumpkin=…`) fragen nicht. Die Runde im Keller (`Mode.PATROL`) zählt nicht als Bedrohung.

### Versteckte Werte (Director)
- `boldness` (Dreistigkeit, steigt nach dem ersten Angriff um `BOLDNESS_PER_DAY` je Spieltag, **ohne Obergrenze**,
  jedes Opfer zieht `VICTIM_BOLDNESS` ab) + `boldness_bonus` (Ereignisse über `add_boldness`: bemerkt, UV; Gerede
  `TALK_BOLDNESS`, Lärm und Licht aus `LURE_BOLDNESS` – je höchstens einmal in `LURE_EVERY`; Halbwertszeit
  `BOLDNESS_BONUS_HALF_LIFE`) − `satiation` (`SATIATION` nach einem Opfer) = `effective_boldness()` (4.9, 4.33). `demand()` (Anspruch an Deko, Spielkonzept 5.10) gleitend nach Tag von
  `DEMAND_FROM_DAY` bis `DEMAND_MAX`.
- **Heiße Stellen** statt Neugier je Zone (4.9): `hot_spots` ({pos, heat}, höchstens `HOT_MAX`). `add_curiosity(p, n)`
  macht eine Stelle heiß oder verschmilzt mit einer unter `HOT_MERGE`; `curiosity_at(p)` = `CURIOSITY_BASE` + Hitze der
  Stellen auf demselben Stockwerk (voll bis `HOT_CORE`, auslaufend bis `HOT_RADIUS`). `_cool_down(dt)` lässt Hitze
  (`HOT_HALF_LIFE`) und Boni abklingen, je Frame und im Zeitsprung. Gespeichert in `save_state` (Speicherformat 53).
- `pressure_at(p)` aus Dreistigkeit und Neugier, `deterrence_at(p)` aus Deko / `demand()` plus Licht allein,
  im Katzenraum unendlich (`LevelBuilder.is_safe`). Deko zählt nur auf demselben Stockwerk, mit `Item.deco_value()`;
  Füllmaterial (`Item.is_filler()`) zusammen höchstens `FILLER_CAP` je Stelle (`_deco_strength`, auch für die Puppe).
  `is_blocked` / `is_protected`.
- **Schutzkreis = Lichtschein** (5.10, Stufe 2, `_deco_share`): Deko mit Licht zählt bis `Item.glow_reach()`
  (`GLOW_REACH` × Lichtreichweite; 0, wenn aus, ohne Kerze oder im Stromausfall) und nur, wenn ihr Schein p erreicht
  (`_glow_reaches`, Strahl vom Licht wie in `light_at`), ×`GLOW_DECO`, zum Rand hin halb – darin ist der frühere
  Licht-Faktor aufgegangen. Deko ohne Licht zählt ×`DARK_DECO` und nur vor einer Zimmertür (`_door_front_at`, bis
  `DOOR_DEMAND_RANGE`), wenn sie höchstens `DARK_DECO_RADIUS` von ihr steht oder hängt. **Sichtbare Abweisung:**
  `show_repel(p)` (aus `Monster._check_deterrence`) ruft `Item.flinch` an allem, was bei p schützt – Flamme
  (`CandleFlame.duck`) und Licht (`FlickerLight.duck`) ducken sich `FLINCH_TIME` s, der Kürbis glüht schwächer,
  hängende Deko schwingt mit `FLINCH_UNREST`. Debug `--abweisung[=dunkel]`, `--trace` `[Abweisung]`, `--shot-on=repel`.
- `light_at(p)`: Summe aller `light_source` mit freier Sichtlinie (Raycast) + Mondlicht durch Außenfenster mit offenem
  Vorhang. Teuer → sparsam aufrufen. Die Lichter kommen aus einem Raster (`_lights_near`, `LIGHT_CELL`, neu einsortiert
  alle `LIGHT_GRID_FRAMES`, Spielraum `LIGHT_GRID_SLACK` für getragene Lichter); An/Aus prüft `light_at` selbst.

### Ereignis-Schnittstelle (andere Systeme melden, der Director reagiert)
`on_noise(pos, hörweite, quelle)` (nur über `Game.noise`) · `on_lights_off(pos)` · `on_actor_hid(spot, actor)` ·
`on_monster_talk(pos)` · `on_monster_noticed()` · `on_monster_uv()` · `on_monster_gone()` · `kill_guest(guest, spot)` ·
`kill_player(spot)`. Neue Spielmechaniken, die das Monster beeinflussen sollen, melden sich hier. Kürbismann und
Lakengeist töten über `player_slain()` (Spiel aus, Schrei, Sterbebildschirm) bzw. `guest_slain(gast, ursache)`.
`on_actor_hid` schickt das Monster nicht nachsehen, während es tötet (`KILL`).
Debug: F5 = `start_warning()` (ein Raubzug, nur wenn es ruht), F7/`--lure` = `debug_lure()`: ruht es, `spawn_at()` auf dem
NavMesh-Punkt ~`LURE_DISTANCE` vom Spieler (zählt als erster Angriff), dann `investigate(Spieler)`.

### Dramaturgie: die vier Modi (Spielkonzept 4.33)
- Vor dem ersten Angriff: kein Monster. Den ersten Angriff löst die Siegerehrung aus (`DoorContest`, 8 „Der
  Anfang“): `first_attack_unseen(gustav)` – es zeigt sich nicht, holt Gustav Peters (`Grinch.taken`), zählt als
  Auftritt (`attacks += 1`), ist satt (`on_guest_taken`). Steht der Spieler in Zimmer 020, stirbt er mit
  (`kill_player`). Läuft schon ein Auftritt (Debug), bleibt er.
- **Plan:** Danach würfelt `_make_plan()` einmal (lazy in `_update_schedule`, `_plan_made`) alle Auftritte bis
  Halloween in `plan` ({mode, day, at, lead}, nach Zeit sortiert): `JUDGMENTS` Urteile gleichmäßig ab
  `JUDGMENT_FIRST` mit Streuung, `SNACKS` an Tagen ohne Urteil, `RAIDS` Raubzüge nach `RAID_WEIGHT` (Tageskurve,
  ohne Zurücklegen); Uhrzeit je Modus (`*_HOUR`, über 24 = nach Mitternacht), `_space_plan()` hält `MODE_GAP`
  Abstand. `_check_demand()` (jede Sekunde) setzt eine **Anforderung** an den nächsten Abend ohne Urteil, sobald
  `effective_boldness()` die nächste Schwelle (`DEMAND_FIRST` + `DEMAND_STEP` × bisherige) überschreitet, höchstens
  `DEMANDS`, ab `DEMAND_GUARANTEE_DAY` sicher die zweite. Prüft `tests/mode_checks.gd` (Zahlen, Abstände).
- **Ohne Körper** (`Phase.CALM`, `_update_calm`): Puppe und Grollen vor dem Urteil (unten), das Rauschen vor der
  Anforderung (`demand_warning()`: `DEMAND_WARN` lang Rauschen, Brummen, `Social.on_rumble`), Geräusche hinter Wänden
  (`_update_presence`, `PRESENCE_EVERY`, an `_point_near_unseen`), Spuk, Halluzinationen. Etwa dreimal am Tag eine
  **Runde im Keller** (`Mode.PATROL`, `PATROL_GAP`/`PATROL_TIME`, Ziele nur auf `LevelBuilder.CELLAR_Y`), nicht
  kurz vor einem Auftritt. Ist ein Auftritt fällig: `_start_mode(m)` (`_begin_mode` setzt alles zurück, Signal,
  Ort), danach `_update_mode(delta)` jedes Bild bis `on_monster_gone()`. Überfällig um mehr als eine Spielstunde
  (Uhr gesprungen) → verworfen.
- **Wen es jagt** (`may_hunt(akteur, abstand)` in `Monster._visible_actor` und `_check_hide_step`): Urteil nur den
  Verurteilten (`condemned`), Raubzug den Spieler (nicht in Zimmer 13, `player_safe()`), Anforderung den Spieler und
  wer im aufgebrochenen Zimmer steht, Snack und Kellerrunde jeden; wer näher als `IN_THE_WAY` kommt, immer. Auf dem
  Rückweg nur, wer im Weg steht (`hunts_on_retreat`). **Türen** (`may_open`, `Monster._open_doors`): Snack keine
  Zimmertür, Raubzug nie Zimmer 13, sonst nur unverschlossene; die Tür, die es gerade aufbricht (`breaks`), immer –
  `Door.monster_open(smash)` macht sie kaputt. `is_blocked` ist dort immer falsch (`_at_target`).
- **Urteil** (`Mode.JUDGMENT`): Weg nur zur Puppentür (`_route = [doom_room]`), im Zimmer packt es nur den
  Verurteilten; ist er woanders, `next_target` → `{"hunt": …}`: Jagd, die er nicht verliert (`is_condemned`, keine Deko
  hält). **Notausgang** `_judgment_escape()` nach `JUDGMENT_REACH` (Spieler `JUDGMENT_REACH_PLAYER`): ein Gast
  verschwindet mit Schleifspur Richtung Keller (`push_warning`), beim Spieler taucht es ungesehen daneben auf
  (`Monster.ambush`). Danach (`_judged`) nur noch heim; `on_monster_gone` schiebt Snacks und Raubzüge bis zum Morgen.
  Kein UV (`can_be_repelled_by_uv`), keine Ablenkung (`investigate`).
  - **Gegen Fehlverhalten** (4.33): `reachable(pos)` – Weg vom Keller (`spawn_points[0]`) auf dem NavMesh wie
    `--navcheck` (ohne Polygongrenze, nächster Punkt ≤ 1 m neben pos). `judgeable_rooms()` nimmt nur Türen mit
    `door_reachable(no)` (einmal je Zimmer, `_door_reach`). **Ziel festnageln:** Beim Aufbruch `Guest.pin_down()` (ist
    das Ziel unerreichbar, geht er heim), danach lenkt `Guest._walk_to` den Verurteilten von unerreichbaren Zielen heim.
    **Haltestelle** (`_wait_for_lift`, nach der Puppentür): Steht der Verurteilte in einer Kabine (`lift_with` →
    `Elevator.carries`), wartet es (`Monster.wait_at`) vor dem nächsten Halt (`next_stop`, `waiting_spot`); steht die
    Kabine dort zu, drückt es den Rufknopf (`call_cabin`). Solange die Kabine fährt oder es wartet, ruht die Frist
    (`_reach_timer`); in die Kabine (kein NavMesh) geht es geradeaus (`Monster._step_straight`). **Dachboden**
    (`_start_attic_scene`, Spieler in einem Raum von `AtticSpook`): `ambush_spot` wählt eine Kammer 1–2 Türen weiter,
    die er nicht sieht (lieber eine, deren Tür er nicht ansieht); `Monster.hide_at` dort, dann `_update_approach`
    (Szene in `_approach`, auch beim Raubzug): Kniestocktür knarrt, Schritte (`thud`) alle `ATTIC_STEP` s, `ATTIC_DUST` s
    vor Schluss Staub (`AtticSpook.dust`), nach `ATTIC_WARN` s (Raubzug `RAID_WARN`) `ambush` – es stößt die Tür geduckt
    auf. Sieht es ihn vorher, jagt es gleich. Debug `--dachboden=urteil`, `--aufzug=urteil` (`debug_reach`,
    `SheetGhost.debug_rest`), `--frist=s`, `--navcheck=tueren`.
- **Snack** (`Mode.SNACK`): erscheint ungesehen auf der Etage des Spielers (`_floor_spawn`, nah an der stärksten
  Lockung `_lure`), Zucken; `SNACK_RUSH` lang auf den Spieler zu (`_sense`, `Monster.track`), dann umherstreifen auf
  dieser Etage, `SNACK_TIME` lang. Ein Opfer, dann heim.
- **Raubzug** (`Mode.RAID`, `raids`): beginnt an `_lure_spawn()` (stärkste Lockung, sonst Keller), mittleres Flackern.
  Alle `RAID_SENSE` s peilt es den Spieler an; versteckt sucht es dieses Versteck einmal ab (`_checked_spot`) und findet
  ihn nur, wenn er keucht. Nach `RAID_TIME` (`_end_raid_search`): hat es ihn gejagt, ist es einem Wurf gefolgt
  (`on_noise` mit `Item` als Quelle) oder wurde es mit UV vertrieben (`_no_break_in`, `_uv_driven`), geht es heim –
  sonst `_plan_break_in()`: eine der schwächsten bewohnten Türen (`RAID_WEAK_SHARE`), hinter der jemand ist, ein Opfer.
  Die ersten `HARMLESS_RAIDS` sind harmlos (`is_harmless()`): `Monster._abort()` kurz vor dem Zugriff
  (`HARMLESS_ABORT`), kein Einbruch. **Notausgang** (4.33, 3., ZIM-27): Solange der Spieler offen dasteht
  (`player_exposed()`: nicht versteckt, nicht in Zimmer 13, nicht im Aufzug), endet die Suche nicht (höchstens
  `RAID_OVERTIME` nach `RAID_TIME`), und `_reach_timer` zählt – nicht, solange es einem Wurf folgt oder vertrieben ist.
  Nach `RAID_REACH` (`debug_reach`) `_raid_escape()`: auf dem Dachboden `_start_attic_scene(RAID_WARN)`, sonst
  `_start_near_scene`: `hide_at` an `_point_near_unseen` (5–12 m, ungesehen), Tür knarrt 8 m weiter draußen, Schritte
  kommen näher, nach `RAID_WARN` s `ambush`; danach Jagd wie sonst (verliert ihn, wenn er sich versteckt oder flieht,
  kein Einbruch). Debug `--frist=s`, `--dachboden=raubzug`.
- **Anforderung** (`Mode.DEMAND`, `demands`): `_draw_victims()` (1–7, ∝ 1/n²), `_demand_doors()`: bewohnte Türen, deren
  Deko nicht hält (`is_blocked`), schwächste zuerst, `DEMAND_DOORS`; langes Flackern. Tür für Tür bis die Opferzahl
  erreicht ist.
- **Opfer** (`kill_guest`): geholt wird nur, wen der Modus will (sonst `_scare_guest`); 20 % überleben verletzt
  (`Wounds.survives`, Kernfiguren immer) – zählt trotzdem als Opfer; der Verletzte kommt in `_spared`. **Den Spieler
  tötet es immer** (außer harmlos). Gespeichert: Plan, Modus, Verurteilter (Gast-ID/„player“), `raids`, `demands`,
  `_lure`, Restzeiten (Speicherformat 55). Debug `--mode=…`, `--plan`, `--warn`, `--doll`, `--attacks=n` (Raubzüge
  bisher); `--trace` zeigt `[Plan]`, `[Aufbruch]`, `[Raubzug]`, `[Urteil]`, `[Anforderung]`, `[Geholt]`,
  `[Losgerissen]`, `[Erschreckt]`.
- **Flackerwelle**: `_start_wave(ursprung, stufe)` – 0 Zucken (Snack), 1 Flackern (Raubzug), 2 lang (Anforderung),
  Dauer `SIGNAL_TIME`; das Urteil hat keine (die Puppe kündigt es an). `wave_delay(p)` = Weg vom Ursprung über das
  Stockwerk, in andere Stockwerke über `_stairwell`, durch `WAVE_SPEED`. Jede Lampe bekommt `FlickerLight.wave`
  (getrennt von `flicker`, damit die Welle keine Birnen durchbrennen lässt). Gäste: `Guest.on_flicker_signal(stufe,
  verzögerung)`. Halluzination startet Wellen mit `fake = true` (Gäste reagieren nicht). Nicht gespeichert.
  `is_signalling()` sperrt das Tagebuch, `long_signal_near()` bricht Würfelpartien ab.
- **Zeitsprung** (`skip`): derselbe Plan; `_skip_mode` – Snack holt niemanden (alle hinter ihren Türen), Raubzug findet
  den Spieler in Zimmer 13 nicht und bricht ein, Urteil und Anforderung gehen ihre Türen ab (`_skip_raid`). Zimmer 13
  oder hörbarer Lärm → `_skip_wake`.
- Haunting (Türen, Vorhänge, Licht, Betten, Zimmer 13) nur, wo der Spieler nicht hinsieht (`_unseen`).

### Die Puppe (`scripts/world/jury_doll.gd`, Spielkonzept 5.5)
- **`JuryDoll`** (`Game.doll`, Start auf dem ersten Lobby-Sofa): `StaticBody3D` auf Ebene 3 (nur für den Blick),
  Modell `doll.glb` × `SIZE`, Ursprung auf der Sitzfläche, Gesicht nach +Z. `verdict` = Zimmer des Urteils,
  `at_room` = Zimmer, vor dessen Tür sie liegt. `judge(no)` → `_pending`; `_try_jump` setzt sie vor die Tür
  (`_door_spot`), sobald `Director.player_can_see` weder alten noch neuen Platz sieht – **sie bewegt sich nie
  sichtbar**. `release()` hebt das Urteil auf (`Director._end_raid`). Gäste der Tür, die sie sehen, bekommen Angst und
  sagen es (`NOTICE_LINES`).
- **Kinder** (`_update_kids`, nur ohne Urteil, erst nach `first_attack_done`) holen sie und tragen sie zur Tür der
  Familie (`carrier`, `_carried_step` an `Guest._hand`); `judge` lässt sofort los. Debug `--doll=kind`.
- **Wettbewerb** (Spielkonzept 2.5): Schildchen „Jury“ (`_card`) bis zum ersten Angriff. Sitzen und Aufstehen über die
  Knochen (`stand_pose(k)`, `_turn`: Drehung im Modellraum gegenüber der Ruhepose), der Rock über den Formschlüssel
  „sit“ (`_skirt`, Wert 1 − k); Arme immer `ARM_DOWN` aus Meshys A-Pose. `HEAD_HEIGHT` = Blickziel für DoorContest. `vanish()` (Rauch bei der Siegerehrung): `gone`, unsichtbar;
  `_reappear` beim nächsten Urteil. `DoorContest.on_doll_placed` schreibt das erste Urteil ins Tagebuch.
- Gespeichert unter `doll` (Lage, Drehung, `verdict`, `at_room`, `pending`, `gone`).
- **Frist und Urteil** (`MonsterDirector`): Ist das nächste Urteil im Plan näher als sein `lead` (`DOLL_LEAD`),
  `_place_doll()`: `_judge(_weakest_door())`, Grollen. `_weakest_door()`: zuerst `doll_mask` (Puppenmaske getragen,
  5.19), sonst unter `judgeable_rooms()` (Zimmer 13 und Zimmer mit einem Erwachsenen, der keine Kernfigur ist) die mit
  der wenigsten Deko (Gleichstand `DOLL_DECO_TIE`, die bisherige Tür bleibt), dann die dunkelste (`DOLL_LIGHT_TIE`),
  dann Zufall; alle `DOLL_RECHECK` neu (Nachbessern). Beim Aufbruch `_condemned_in(zimmer)`: der Spieler bzw. der
  Bewohner mit der höchsten `Guest.weakness()`. **Grollen:** `SynthAudio.rumble` steigt bis zum Ende der Frist.
  `_end_raid(true)` (nur nach dem Urteil) gibt die Puppe frei.
- **Gewähltes Zimmer** (`in_raid_room`): Verstecke aufgerissen (`rip_open`), wer offen steht und gemeint ist, gejagt und
  nicht verloren (`raid_prey`, beim Urteil nur der Verurteilte). Gespeichert im Director: `rumble_total`, `doom_room`,
  `raiding`, `route`, `raid_kills`. Debug `--doll[=s[,zimmer]]`, `--trace` `[Puppe]`, `[Urteil]`.
- **Gäste beim Grollen und Aufbruch:** Während der Frist `Social.on_rumble(k)` (Angst, Erlebnis „rumble“, in Deckung,
  Feiern enden ab `RUMBLE_PARTY_END`). Die Flackerwelle ruft bei jedem Gast `_react_to_flicker` → `take_cover()`:
  nah am eigenen Zimmer heim (`_flee_home`, dann `_shut_in()` – Tür zu), sonst `_go_hide()`. Solange
  `Game.monster.is_active()`, bleibt `_next_activity` daheim.

### Monster-Zustände
`INACTIVE, PATROL, INVESTIGATE, LURK, STARE, SEARCH, CHECK_HIDE, CHASE, REPELLED, RETREAT, KILL, SLINK, WAIT`.
Wechsel nur über `_set_state()` (setzt Zustands-Timer zurück). Von außen: `start_roaming`, `investigate`, `go_check`,
`stare`, `go_home`, `spawn_at` (Tests), `spawn_near_unseen`, `deactivate`.
- Sieht der Spieler es ohne Jagd länger als einen Moment → `SLINK` (aus dem Blick verschwinden).
- UV-Licht: `uv_flinch()` (im Kegel langsamer), `uv_repel()` → kurz `REPELLED`, dann `RETREAT` mit `_fleeing`.
- **Abschreckung** (`_check_deterrence`): Deko + Licht blockieren nur, wenn das Ziel (`_goal()`) selbst im Schutz
  liegt – vorbeigehen darf es (die Deko vor den Türen deckte sonst den ganzen Flur ab). Beim Jagen gilt
  `is_protected(Gejagter)`. Zurückgeschreckt ohne UV → anderes Ziel (`_next_roam`), der Gejagte kommt für
  `REBUFF_TIME` in `_rebuffed`. Was abgewiesen hat, zeigt es (`MonsterDirector.show_repel`).
- **Rückzug (`RETREAT`) nur:** Ende des Auftritts (`go_home`), nach einem Opfer (`after_feeding`), UV, harmloser
  Raubzug (`_abort`). Nach einem Schreck `after_scare(opfer)` → `SLINK` (nicht auf dem Rückweg); das Opfer steht bis
  zum nächsten Auftritt in `_spared`. Von außen außerdem `track(pos)` (Peilen), `replan()` (neues Ziel vom Director),
  `ambush(pos, akteur)` (Notausgang beim Urteil und Raubzug), `wait_at(pos, blick)` (`WAIT`: hingehen, stehen, wer gemeint ist und
  näher als `WAIT_SEE` kommt, wird gejagt; Türen öffnet es dabei nicht) und `hide_at` (ungesehen dorthin versetzen).
- **Ducken:** unter Türen (`_near_door`) halb, an niedrigen Türen (`_low_door`, Dachboden unter der Schräge) tiefer.
- Tempo `WALK_SPEED`, `SEARCH_SPEED`, `CHASE_SPEED` – jagend weit schneller als der rennende Spieler.

### Aussehen & Animation
- **Modell:** `assets/models/monster.glb`, gebaut von `tools/build_monster.py` (Blender) aus dem Meshy-Original
  (`assets/source/`, nicht im Repo, `.gdignore`): **Grundpose aufrecht**, die ursprüngliche Hocke auf allen Vieren
  steckt als Animation `crouch` (ein Bild) in der Datei. Neu bauen:
  `blender -b --python tools/build_monster.py -- <meshy.glb> assets/models/monster.glb`. Die Augenpositionen druckt das
  Skript aus → `Monster.EYES`. Die entpackte Textur (`assets/models/*.jpg`) ist in `.gitignore`.
- **Animation ist Code:** `_animate()` setzt alle `ANIM_STEP` eine neue Pose (Stop-Motion). Pro Knochen wird
  aufrecht ↔ Hocke gemischt (`_crouch`, Ziel aus `_crouch_target()`), darauf kommen mit `_turn(knochen, achse,
  winkel)` Gang, Vorbeugen, Arme, Kopf, Kiefer und Zunge. `_turn` dreht um Achsen im **Modellraum** (die
  Knochenachsen aus Blender sind uneinheitlich) – Eltern immer vor Kindern drehen.
- Der `AnimationPlayer` aus der GLB wird nur ausgelesen und dann gelöscht. Augen hängen per `BoneAttachment3D` am
  Knochen `head`.
- Kollision und NavMesh-Agent sind niedriger als das Modell; Türen sind niedriger als das Monster → `_near_door`
  lässt es sich ducken. `EYE_HEIGHT` ist auch die Höhe für seine Sichtprüfungen.

### Der Kürbismann (`scripts/monster/pumpkin_man.gd`, Spielkonzept 4.19, 4.21)
Dritte Bedrohung, eigener Akteur (`CharacterBody3D`, Kollisionsbit 32 wie das Monster, erbt `NavWalker`) in
`Game.pumpkin`. Spielt die Animationen der GLB (Abspieltempo aus der Laufweite), kein Code-Rig.
- **Spaß** zählt `Social.has_fun(gast)` (Feier, Minispiel, Süßes oder Saures, Schmücken – `Decorating.is_crew`) und
  `player_has_fun()`; `fun_actors()` = beides.
- **Auslöser: Spaßwert** (`_check_spawn`): `fun` steigt je Gast nach `FUN_GAIN[Social.fun_kind(g)]`, fällt mit
  `FUN_DECAY`; `on_deco_placed()` (aus `Player.drop_held`) gibt kurz `_fun_deco` dazu; `fun_value()` = Summe. Ab
  `threshold()` (`FUN_THRESHOLD`, mit der Kürbismann-Maske `MASK_THRESHOLD`, 5.19) regelmäßig ein Wurf → Ankündigung. **Garantie** `_guarantee_due()` ab `GUARANTEE_DAY`, wenn er
  selten kam (`visits`, `guarantee_at`). Erst nach `first_attack_done`, nie neben einer anderen Bedrohung, erst mit
  fertigem NavMesh (`map_get_iteration_id`). Gespeichert unter `pumpkin` (`fun`, `visits`, `guarantee_at`,
  `guarantee_checked`; er selbst nicht). F3 zeigt den Wert.
- **Ankündigung** (`_begin_announce`, `announcing()`): Kinder singen (`Guest.singing`: stehen, sehen zur Lobby, [E] gibt
  eine Liedzeile), Erwachsene bekommen Angst; Liedzeilen aus `SONG` als Untertitel. `_update_omens`: `FlickerLight.red`
  färbt alle Lampen (Licht und Emission des Lampenmaterials – geteilte Materialien sind gewollt), `hot_spot` = sein
  Kopf, solange er im Haus ist; dazu `SynthAudio.creepy` (leiernde Plattenspielermelodie) und `chorus` (Kinderchor). `PumpkinMan._ready` setzt beides
  zurück. `Director.other_threat_active` und `SaveManager.can_save` zählen `announcing()` mit; nicht gespeichert.
  Debug `--pumpkin=ankündigung[,s]`.
- **Ankunft übers Lobbydach** (`start_hunt`): sucht die Glastür von der Lobby in den Mittelgarten (`_garden_door`: Tür
  mit `glass`, Lobby davor, Garten dahinter) – der einzige Weg in die Lobby. Ablauf **ohne Physik und NavMesh**
  (Kapsel aus, Position direkt gesetzt): `CLIMB` an der Straßenfassade gegenüber → `ROOF` bis zur Dachkante über der
  Tür, `EDGE_WAIT` als Silhouette → `LEAP` → `LAND` im Garten (Kapsel an, Lärm `pumpkin_land`) → `LOBBY` mit Halten
  (`LOBBY_STOPS`) und Umsehen. Dach- und Gartenhöhe per Strahl nach unten (`_surface_y`, Ebene 1 und Decke):
  `_roof_y`/`_edge_y` folgen der Dachform – ein späteres Dach muss nur trittfest auf diesen Ebenen liegen.
  `arriving()`: `is_hunting()` erst ab `LAND` (Feiern laufen weiter, bis er unten ist), `in_house()` schon;
  `_scare_onlookers` nimmt dann die Decke dazu (sonst sähen ihn Gäste hindurch). Animationen `climb`/`land`
  (`CLIMB_ANIM`/`LAND_ANIM`) nimmt er, sobald die GLB sie hat; `spin_jump` taugt nicht (trägt ihn weit nach vorn).
  Ohne Gartentür erscheint er an einem Kürbisbeet (`_bed_point`, außer Sicht des Spielers).
- **Jagd:** `STALK` (Opfer aus `_pick`: zuerst wer im Partyraum zu sehen ist, dann der Spieler in `PLAYER_NOTICE`,
  dann Spaß-Akteure – zu ihnen sprintet er –, sonst der nächste erwachsene Gast; alle `RECHECK` neu) → `CHASE` (Sicht
  über `Senses.SIGHT_MASK`) → `STRIKE` (Gast `cower()`, Animation `attack`, Treffer bei `HIT_AT`, getroffen wird, wer
  noch in `HIT_RANGE` ist) → nächstes Opfer bzw. `ROAM`. Nach `HUNT_TIME` → `LEAVE` zum Haupteingang, weg, sobald der
  Spieler ihn nicht sieht. Versteckt / `LOSE_SIGHT` → `SEARCH`. **Im Weg** (`_strike_blocker`): wer näher als
  `BLOCK_RANGE` vor ihm steht, wird geschlagen, auch ohne Spaß. Kinder schließt `_can_hunt` aus (Spielkonzept 6.13).
- **Folgen:** `Guest.die("pumpkin")` → Leiche in Blutlache, gespeichert wie die Leichen des Lakengeists (`corpse`).
  Ton: `PumpkinMan.HIT_SOUND` am Kürbismann, Lärm `axe_swing`; das Opfer schreit beim Ausholen, der Treffer bricht
  ab (`SynthAudio.cut_voice`). Gäste mit Sicht: `Guest.see_pumpkin()`. `MonsterDirector.is_quiet` ist dort falsch, wo
  er jagt – Feier, Partien, Süßes oder Saures enden damit von selbst.
- **Den Kürbismann aufhalten** (Spielkonzept 4.21, 1): `_check_shown()` jedes Bild, solange er jagt (auch beim
  Ausholen, bis der Treffer fällt): hält der Spieler einen Kürbis, der `stops_him()` (`CARVED_PUMPKIN` oder großer
  `PUMPKIN`, `Item.is_large`), steht höchstens `SHOW_RANGE` (5 m) weit weg, sieht in `SHOW_DOT` zu ihm hin (zur Stelle
  seiner Körperachse, die der Blick kreuzt) und sieht er den Spieler (`Senses.can_see` mit Grundweite `SHOW_SIGHT`
  12 m und `MONSTER_FOV_DOT`), geht er in `STUNNED`: `STUN_TIME` (5 s) still, Ende über `_resume()` (wie nach dem
  Schlag). Jeder Kürbis wirkt je Auftritt einmal (`_shown`, Instanz-IDs, in `start_hunt` geleert). Helfer und Ritual
  fehlen (ZIM-20); sein Kopf (`Item.Kind.PUMPKIN_HEAD`) liegt im Dachgeschoss (4, „Dachgeschoss“).
- Nicht gespeichert. Debug: F9 bzw. `--pumpkin=dach` (Aktion `debug_pumpkin` – **nicht F8**, das stoppt im Editor
  das laufende Spiel), `--pumpkin=garten`, `--pumpkin=jagd[,gast]`, `--pumpkin=zeigen[,was]` (`debug_show`, Lobby,
  der Spieler dreht sich laufend zu ihm; Szenarien mit Stichwort „zeigen“), `--shot-on=pumpkin|pumpkin_roof|pumpkin_edge|
  pumpkin_leap|pumpkin_land|pumpkin_lobby`; `--pumpkin[=anim]` stellt eine Testfigur ohne Verhalten auf.

## 6. Gäste & Soziales

Die Regeln (wer was wann tut, Beziehungswerte, Sätze) stehen im Spielkonzept, Kapitel 6; Zahlen als Konstanten oben in
den Skripten. Hier der Aufbau.

### Profile, Erzeugung, Aussehen
- **`GuestProfiles`**: feste Gäste in `ALL`, erzeugte in `static var generated`, in Haushalte eingesetzte in `placed`;
  Zugriff immer über `GuestProfiles.get_profile(id)`. Alle Profile haben dieselbe Form (Werte, `activities`-Gewichte,
  `dice`, `lines`). Sätze über `guest.line(key)`.
- **`GuestGenerator.make(seed, room, arrived_room)`**: deterministisch aus dem Seed. **Achtung:** Die Reihenfolge der
  `rng`-Aufrufe in `make()` bestimmt, wer der Gast ist. Neue Zufallswerte nur **ans Ende** anhängen, sonst werden aus
  gespeicherten Seeds andere Gäste (`tests/run.tscn`, `save_rules`, prüft das). `name_for(seed)` verlässt sich darauf,
  dass der Name die **erste** Zufallszahl ist. `make_member` (Haushalte) überspringt die ersten beiden Zufallszahlen und
  zieht den Rest in derselben Reihenfolge; `make_child` hat eigenen Zufall.
- **Aussehen** (`GuestBody`, Spielkonzept 6.0): `GuestBody.pick(profile, id)` wählt einen Grundkörper aus
  `GuestBody.BODIES` passend zu Geschlecht und Generation (`GuestGenerator.generation()`, im Profil `gen` – kein
  Zufall, Spielstände bleiben gleich); Kinderkörper nur für Kinder (nächstes Alter). Ohne passenden Körper bleibt die
  Klötzchenfigur (`_build_blocks`). Je Gast `height_cm`, `width_cm` (`WIDTH_LIMIT`, Kopf gegengestreckt), `head`,
  `build`, Farben `coat`/`pants`/`hair` als Instanz-Uniforms von `psx_guest.gdshader` (färbt nur graue Texel). **Die
  `Color` geht unverändert hinein** – Godot rechnet Instanz-Uniforms selbst nach linear um; ein zusätzliches
  `srgb_to_linear()` macht die Gäste zu dunkel und zu satt. **Hautton** `skin` (`GuestGenerator.SKIN`, Kinder erben
  ihn): Der Shader erkennt Haut an der Texelfarbe und multipliziert sie mit `tint_skin`, einem `Vector3` (wird nicht
  umgerechnet) aus Zielton / mittlerer Haut des Körpers (`_skin_ref`) – so sieht derselbe Ton auf jedem Modell gleich
  aus. `debug_skin` im Material färbt die erkannte Haut magenta.
- **Bewegung:** `walk`/`run` aus der GLB (`AnimationPlayer` manuell vorgespult, Tempo nach Laufweite × Größe), im
  Stand Ruhepose mit Atmen. Die Posen in `Guest._pose()`/`_dance_pose()` drehen die Pivots `_arm_l`/`_arm_r` (beim
  Modell unsichtbar); `GuestBody` richtet die Oberarmknochen danach aus (`_aim`), außer `_arms_free`. Tänze auf Feiern:
  Mixamo-Animationen aus `GuestBody.DANCES`, ab zufälliger Stelle (nicht im Gleichtakt); die Klötzchenfigur tanzt
  Code-Posen. Sitzen: `sit_drop()`.
- **Marken am Körper** (Wunden): `GuestBody.attach(knochen)` = `BoneAttachment3D` + Halter, der den Maßstab des
  Skeletts ausgleicht (manche Modelle sind intern in Zentimetern).

### `Guest` (Zustandsautomat)
- Zustände `IDLE, WALK, CARRY_HOME, PLACE_DECO, HARVEST, STEAL, HIDE_GO, HIDING, PARTY, TALKING, MINIGAME, DEAD,
  KNOCK, SHELTER, SLEEP, SHOCKED, GHOSTED, FOLLOW, VISIT, ATTACK, STAGGER, DECORATE, SEARCH, EAT`. Der Zustand wird
  nicht gespeichert – neue Zustände einfach hinten anfügen.
- In `IDLE` wählt `_next_activity()` gewichtet aus `profile.activities`, je Phase der Uhr mit `PHASE_ACTIVITIES`
  (Spielkonzept 2.4) und Haltungen (`activity_weights`). `_arrive()` verarbeitet das Ankommen je Zustand; Systeme mit
  eigenem Ablauf (Schmücken, Suche, Herd, Kaffeemaschine, Streiche, Putzen) bekommen es über ihr `on_arrived` – den
  Zustand `EAT` teilen sich Herd und Kaffeemaschine (`CoffeeMachine.expects(gast)` zuerst).
- **Gedränge** (ZIM-155): Gäste kollidieren nicht miteinander (Schicht 128, Maske `1 | 16`) und weichen sich beim
  Gehen nicht aus (kein RVO – Rechenzeit, große Schritte der fernen Gäste). Stattdessen: `_free_spot(spots, jitter)`
  nimmt für Lobby, Küche (`kitchen_spots`, Raster `KITCHEN_SPOT_STEP`), Bar, Garten, Flure und das eigene Zimmer einen
  Platz (aufs NavMesh gezogen), an dem im Umkreis `SPOT_GAP` keiner steht oder hingeht (`_crowding`: Stand und `_target`
  der anderen, ohne Schlafende/Versteckte), sonst den mit dem meisten Abstand. `_phase_activities` senkt das Gewicht
  einer Aktivität mit der Belegung ihrer Plätze (`_occupancy`, belegt = einer näher als `SPOT_TAKEN`; für alle Gäste gemeinsam höchstens alle `OCCUPANCY_TTL` s
  gezählt, statisch `_occupancy_seen`), geteilt durch `0,5 + gossip` – Gesprächige stört volles
  Haus kaum. Talk fragt `activity_weights` ohne Belegung (Pläne für später). In `IDLE` tritt `_keep_space` alle
  `SPACE_CHECK` s beiseite, wenn ihm einer näher als `PERSONAL_SPACE` steht. Debug `--gedraenge` zählt das alle 10 s.
- Gäste melden sich mit `Game.social.on_*` (Diebstahl, fehlende Deko/Birne, Monster gesehen …).
- **Lichtschalter** (Spielkonzept 7.3): `_track_light_room` schaut alle `LIGHT_CHECK` s nach dem Raum unter ihm
  (`LevelBuilder.light_room_at` – Schalter-ID, das Bad hat eine eigene). Beim Wechsel: verlässt er als Letzter ein
  Hotelzimmer oder dessen Bad (nicht 13; auch der Spieler zählt, nur nicht im Versteck – Schreckmoment: Licht aus, während man im
  Schrank oder unterm Bett sitzt), geht er zurück und macht aus – außer er vergisst es
  (`_forget_light`, fest je Gast aus der ID, betrunken öfter, ab Angst 60 immer); betritt er einen dunklen Raum, macht er
  an (Chance nach `brave` und Angst), nicht wenn dort jemand schläft oder ruht bzw. im Hotelzimmer schon jemand im
  Dunkeln sitzt. Brennt keine Lampe des Raums (Birne fehlt/kaputt), beschwert er sich (`_complain_dark`). Der Gang
  (`_switch`, `_switch_step`) ist kein eigener Zustand: Er läuft nur in `SWITCH_STATES` und ohne Rennen, danach geht der
  alte Zustand mit seinem Ziel weiter; was dazwischenkommt, bricht ihn ab. Höchstens `SWITCH_REACH` m weit, aufgeben
  nach `SWITCH_GIVE_UP` s. Schlafen, Ausruhen, Aufwachen im eigenen Zimmer schalten weiter direkt (`_set_room_light`, beim Ausschalten
  auch das Bad).
  Nichts davon wird gespeichert (`"?"` = nach Laden/Erscheinen erst merken, nicht schalten). Debug `--lichtgang=id`
  (`,versteckt`: du sitzt in seinem Schrank).
- **Ersatzbirne** (Spielkonzept 7.3): Brennt daheim keine Lampe (`home_dark`, Wackelkontakt zählt als Licht) und hat der
  Haushaltsvorstand keine Birne im Vorrat, geht er tagsüber in `_next_activity` los (`_seek_bulb`, höchstens alle
  `BULB_RETRY` s, Haltung `bulb_tried`): zum nächsten erreichbaren `ResourceSpot` mit `Item.Kind.BULB`
  (`_bulb_supply`, Gang als `State.STEAL` mit `_bulb_spot` → `_take_supply_bulb`, `guest_consume`) – im Plan
  „Ausstattung: Ersatzbirnen“ –, sonst ab `BULB_BRAVE` Mut oder feindselig zu einer Lampe in einem leeren Raum oder
  Flur (`_bulb_for_home`: keine Bewohner, niemand drin, nicht Lobby/Aufzug, 13 nur feindselig, nicht unter den Augen des
  Spielers, `_finish_steal`). Die Birne geht in `stock`, `_check_lights` schraubt sie daheim ein. Wer sich nicht traut,
  meidet das Zimmer (`avoids_home`, gilt für den ganzen Haushalt): `activity_weights` setzt „room“ auf 0, in der
  Nachtruhe schläft er bei einem Freund (`pals_of`) mit freiem Bett in einem hellen, offenen Zimmer (`_dark_refuge`,
  `_bed_host`, `_bed_home` für Weg und Bett, dort nur Einzelplätze, Licht des Gastgebers bleibt) oder sitzt in der Lobby.
  Nicht gespeichert (nach dem Laden entscheidet `_go_to_bed` neu). Debug `--birnenersatz=id[,lager|klauen|meiden]`.
- **Detailstufe** (Leistung bei vielen Gästen): außerhalb des Blickfelds und weiter als `Guest.LOD_RANGE` bzw.
  weiter als `LOD_FAR` rechnen Gäste nur jedes `LOD_STEP`-te Physikbild – mit der aufgesammelten Zeit, `_move_to` macht
  entsprechend längere Schritte (`_lod_scale`). Im Gespräch, Spiel, gewürgt, taumelnd oder angreifend immer voll.
  Stehende Gäste auf festem Boden rufen kein `move_and_slide` (`_stop`).

### `Social`
Der Ort für alles zwischen Gästen und Spieler: Gästeliste (`guests`, `living_guests()`, `guest_by_id()`; für Debug
`find_guest()` – auch nach Namen, da nur die Kernfiguren ihren Namen als ID haben),
Beziehungen (`change_relation`), Gerede über das Freundesnetz (`_spread_gossip` → `GuestPals.spread`), Diebstahl mit Zeugen, Reservierung von Verstecken
(`find_hide_spot` / `release_hide_spot(spot, gast)` – der Gast gibt sie auch frei, wenn sein Weg abbricht oder er stirbt,
sonst bleibt das Versteck für alle gesperrt), Feiern, Herausforderungen (`challenge`), Gäste-Mäxchen und -Schach,
Berichte über Spuren (`note_trace` → `report_line`), Klopfen an Zimmer 13, Zettel, Nachrücker (`START_GUESTS`,
`MIN_GUESTS`; Nachrücker sind immer Erwachsene). Teilsysteme hängen als Kinder an Social (`Game.social.tidying`,
`pranks`, `decorating`, `search`, `pals`, `talk`, `access`, `requests`).
- **Freundschaftsstufen** (Spielkonzept 6.3): `Social.Tier` (`tier(guest)` / `tier_of(wert)`, `TIER_NAMES`). **Im
  Code nie `relation` mit Zahlen vergleichen, sondern Stufen** (`Social.tier(g) >= Social.Tier.FRIEND`).
  `change_relation` dämpft Zuwächse und deckelt, solange die Taten fehlen: `Guest.deeds` (`games`, `gifts_to`,
  `gifts_from`, `hostile`, `revenge`; `add_deed`) gegen `BOND_*`/`FEUD_*`. `_update_bonds`: Zerfall, Besuche
  (`Guest.start_visit` → `on_visit_arrived`), Erzfeinde (`_update_feuds`: Drohung, dann `Guest.start_attack`).
- **Beziehung nicht erschleichen** (Spielkonzept 6.18, 5; 2026-11-03): Beziehungsbudget `Talk.friendly` – alle
  freundlichen Gesten (Plaudern im Gespräch und am Telefon, Beruhigen, Monster-Gespräch, Anlässe, kleine Bitten)
  zählen je Spieltag `Talk.FULL_PER_DAY` mal voll, danach × `OVER_BUDGET` (`Guest.chat_day`/`chats_today`).
  Gesprächsbereitschaft: `Talk.start_talk` beim Öffnen (`DialogUI.open`, `PhoneCalls._guest_answers`) zählt
  `Guest.talk_day`/`talks_today` gegen `TALKS_PER_DAY` (genervt/wütend 2, neutral 4, sonst und bei Kindern frei;
  in Panik redet er trotzdem) – sonst „Ich hab zu tun.“ (`DialogUI._busy`, nur Warnen bleibt). `Talk.cuts_short`:
  Verärgerte brechen nach `SHORT_TALK` Hauptmenüs ab (`DialogUI._steps`, am Telefon `_talk["steps"]`).
  Geschenke (`DialogUI._gift`): Füllmaterial (`Item.is_filler`) bringt Erwachsenen `FILLER_GIFT` einmal am Tag
  (`Guest.filler_day`; Passendes für Verletzte ausgenommen), `gifts_to` nur nach `Social.bond_gift` (Preis ≥
  `BOND_GIFT_PRICE`, kein Füllmaterial, kein roher Kürbis); `Item.got_from` (beim Kaufen und „Deko erbitten“ gesetzt,
  gespeichert als „got“) – das nimmt er nicht zurück. Beruhigen (`_calm`, Telefon-Panik) nur mit Beziehung, wenn
  `Guest.stoked_recently()` falsch ist: `scared_by_player()` setzt `stoked_at` bei Monster-Gespräch, geglaubter
  Geschichte, „schlechte Nacht“-Antwort, Schlag und Laken im Dunkeln; gilt `Guest.STOKED_TIME` (2 Spielstunden,
  nicht gespeichert). Vergebung `Social._update_forgiveness` (im 2-s-Takt von `_update_bonds`): an jedem neuen
  Spieltag ohne Tat seit dem Vortag (`Guest.hostile_day`, gesetzt in `add_deed`) `hostile` −1; fehlt dann die
  Bedingung für „stark verfeindet“, springt der Wert auf −79. `_forgive_day` nicht gespeichert (nach dem Laden ab
  heute). Debug `--budget=id`, Szenario mit Stichwort „budget“.
  Neid (ZIM-164) `Social._update_envy` im selben Takt, einmal je neuem Spieltag (`_envy_day`, nicht gespeichert;
  mehrere Morgen zählen einzeln): `envious_neighbors()` misst nur dann – Knappheit (`DecoPlan.scarce`), Abschreckung
  vor 13 (`MonsterDirector.deterrence_at`, > 0) mindestens `ENVY_RATIO` × die der Nachbartür und die hält nicht
  (`DecoPlan.weak`); Türnachbar = Erwachsener, Tür auf demselben Stockwerk bis `GuestPals.NEIGHBOR_RANGE`, Stufe unter
  „befreundet“; jede Tür einmal gemessen. Folge: Beziehung −`ENVY_DAILY`, nicht unter `ENVY_FLOOR` (−30, „wütend“ –
  ab da klaut er nach `Guest._try_steal`), Haltung „envy“ für einen Spieltag (wird mit `stances` gespeichert). Den
  spitzen Satz (`ENVY_LINES`) sagt er einmal: beim Vorbeigehen (`_envy_remark`, im 2-s-Takt, bis
  `ENVY_REMARK_RANGE`) oder zu Gesprächsbeginn (`Talk.greeting`). Debug `--neid[=id]`, Szenario mit Stichwort „neid“.
- **Spieler schlägt und rammt** (`player.gd`): Linksklick schlägt, wenn `_punch_target()` einen Gast im Fokus hat
  (außer bei „wütend“ erst nach Nachfrage) → `Social.on_player_punched`; Rennen gegen einen Gast (`_check_ram`) →
  `on_player_rammed`; ein Wurf trifft (3.13) → `on_player_threw_at`: `THROWN_AT` bzw. mit Zerplatzendem
  `THROWN_AT_MESSY`, Eltern wie beim Rammen, Zeugen −3/−6 und nur mit Zeugen Gerede, der Gast taumelt (`stagger`).
  `injury` (gespeichert) macht langsamer; Blutstropfen über `Traces.add_guest_drop`.
- **Nachtruhe** (Spielkonzept 2.4): `night_window(tag)` würfelt Beginn und Ende aus `hash([night_seed, tag])`, damit
  Laden und Debug-Sprünge der Uhr dieselbe Nacht ergeben (`night_due()`, `seconds_to_night()`, `night_ends_at()`).
  `_update_sleep` startet sie, sobald keine Feier oder Schmück-Aktion mehr läuft → `Guest.bedtime()`: ins Zimmer, Licht
  aus (nur, wenn kein Mitbewohner wach ist), ins eigene Bett (`hiding` = Bett, aber Zustand `SLEEP` – kein
  Versteck-Lärm; das Monster kann sie dort finden). Im Doppelbett liegt ein Zweiter (`HideSpot.partner`,
  `takes_partner`, `sleep_offset`). `Social.all_asleep()` für den Lakengeist. Gespeichert: `sleep_active`,
  `night_seed` (Gäste laden wach und gehen wieder ins Bett). Debug `debug_sleep` (`--sleep`).
- **Der Spieler schläft, wann er will** (Spielkonzept 3.6): Jedes Bett in einem Zimmer (`HideSpot.room_no`, von
  `LevelBuilder` gesetzt; `sleepable`) – im eigenen (`own_bed`, Zimmer 13) stellt das Mausrad `Player.sleep_hours` ein,
  im fremden `bed_hours` (0 = auf die Kante setzen, so bleibt Sitzen möglich; neuer Fokus setzt es zurück);
  `can_sleep` = schlafbereit. `Player.start_sleep()` = `enter_hide()` + `sleeping` + Zeitraffer (Zeitsprung, 3 „Pause
  & Zeit“). Aufwachen ohne Aufstehen (`wake_up`): Monster nah oder fremder Lärm.
  **Wachzeit** `awake_time` (Spielsekunden, von Anfang an) zählt wach in `_update_awake`; Schlaf senkt sie je Sekunde
  um `_sleep_from × credit / SLEEP_FULL` (`_rest`, Kaffee/Tee über `_sleep_credit`) – eine ganze Mütze auf null und
  `rested` = `RESTED_TIME`. `tiredness()` = gefühlte Wachzeit (Kaffee), `tired_stage()` 0–4 (`TIRED_FROM` 16 h,
  `OVERTIRED_FROM` 24 h, `NODDING_FROM` 36 h, `sure_awake` je Spiel aus `SURE_AWAKE` 48–72 h, eigener
  `RandomNumberGenerator`): neue Stufe → Gedanke, müde Gähnen/Lider (`Hud.close_eyes`), ab 36 h Sekundenschlaf.
  `tired_weakness()` (bis `sure_awake` auf 1, übermüdet + `OVERTIRED_WEAK`) geht in `weakness()` und die Sicht;
  `strain()` (ausgeschlafen `RESTED_STRAIN`, übermüdet `OVERTIRED_STRAIN`) auf Ausdauer, Luft, Schockabbau, Hypnose
  und Griff des Lakengeists; übermüdet halluziniert man (`MonsterDirector._update_hallucination`). Gespeichert unter
  `player`: `awake_time`, `sure_awake`, `rested`. Rausch beim Einschlafen → **Kater** (`HANGOVER_TIME`, 3.7).
  **Fremdes Bett:** `Guest._fall_asleep` fragt zuerst `Social.player_in_bed(guest)`: Freunde legen sich woanders hin,
  gute Freunde halten mit `BED_GUARD_CHANCE` Wache (`wait_awake`, Meta `guards_player` – zählt für `guarded()`),
  neutrale bis genervte und Kinder wecken (`BED_ANNOY`, Gerede, Meta `woke_player` → beim nächsten Mal hinauswerfen,
  `BED_EVICT`), Verfeindete klauen `BED_ROB` Münzen (`Player.robbed`, gemeldet beim Aufwachen) oder schlagen wach.
  **Wache in Zimmer 13** (6.18, ZIM-62): Bitte `DialogUI._guard` (guter Freund, Erwachsener; Absage ab `GUARD_FEAR`,
  verletzt, schon eine Wache, Meta `guarded_at` jünger als `GUARD_REST`) → `Guest.start_guard`: `guarding`, Mitkommen
  (`start_follow(GUARD_WAIT)`). `_follow_step` sieht vor dem Versteck-Fall `player_in_own_bed()` (Bett mit `own_bed`,
  wach oder schlafend) → `_begin_watch`: `State.WATCH`, Platz `GUARD_SPREAD` um die Zimmermitte, Blick zum Bett;
  `_watch_step` endet mit `end_guard`, sobald du nicht mehr liegst. `bedtime` lässt ihn in Ruhe, `_next_activity`
  bringt ihn nach einem Schreck zurück (sonst `guarding` aus), `_react_to_flicker` weckt dich statt `take_cover`.
  `SleepSkip.guard()` liefert den wachen Erwachsenen im Zimmer (`guarded()` → `lead()` mal `GUARD_LEAD`), bei `_end`
  mit Grund rüttelt er dich wach. Zeuge gegen den Lakengeist über `_witness_guests`, und `Social.all_asleep` ist
  falsch. Nicht gespeichert. Debug `--wache[=id]`, Rauchtest-Stichwort `wache`.
  **Gäste wecken:** Am Bett (`HideSpot._sleeper` → „… wecken [E]“, auch am im Stehen Schlafenden, `Guest.get_prompt`)
  oder durch Klopfen (`RoomAccess.knock`, `residents_home(no, true)` zählt Schlafende im Bett mit) ruft
  `Social.wake_guest`. Grund aus `wake_reason`: „danger“ (Monster aktiv im selben Geschoss oder näher als
  `WAKE_DANGER_RANGE`, echte Flackerwelle – `MonsterDirector.wave_fake` –, Lakengeist aktiv, Kürbismann im Haus oder
  angekündigt) → `WAKE_THANKS`, Haltung `woken_alert` (`WAKE_ALERT` s wach im Zimmer bei Licht, `_next_activity`;
  aus dem Bett heraus ist er Zeuge gegen den Geist); „false“ (Halluzination läuft) → `WAKE_FALSE` und `doubts_waking`
  (`WAKE_DOUBT` s: auch echte Gefahr bringt keinen Dank); sonst `WAKE_ANNOY` (Freunde `WAKE_ANNOY_FRIEND`). Ohne Dank
  Haltung `grumpy` (`WAKE_GRUMPY` s: kein Gespräch, keine Geschenke, „gereizt“ im Hinweis) und nach `WAKE_BACK` s
  wieder ins Bett (`Guest.after_woken`). Haltungen werden mit dem Gast gespeichert. Debug
  `--wecken=id[,gefahr|halluzination|klopfen]`.
- **Feiern:** Tanzplätze `LevelBuilder.party_spots` (Sechseckraster `DANCE_SPACING`, von der Mitte nach außen);
  `Social.free_party_spot(guest)` vergibt den innersten freien. Gäste kollidieren nicht miteinander, darum gehen sie
  in `PARTY` die letzten Zentimeter, an denen `_move_to` aufhört, genau auf den Platz. Spontane Feiern
  (`_update_party`) nur abends.
  - **Musik:** `RecordPlayer.TRACKS` (`""` → `SynthAudio.music`, dazu die MP3), jede Feier ein anderes Stück;
    `synth_track()` entscheidet, ob die Lautstärke an `Game.audio.music` oder `RecordPlayer.fade_to()` geht.
  - **Discokugel** (`world/disco_ball.gd`, über `party_center`): dreht sich auf Feiern; eine `OmniLight3D` in ihrer Mitte
    projiziert Punkte (`light_projector` aus `_dot_pattern()`). Ohne `shadow_enabled` gibt es keinen Projektor – die
    Lampe ist nicht in „lamps“, `ShadowBudget` lässt sie in Ruhe. Projektorfilter Linear ohne Mipmaps
    (`project.godot` `textures/light_projectors/filter`), mit Mipmaps verschwammen die Punkte. Die Kugel liegt auf
    Sichtebene 11, die ihre Lampe auslässt. Material `psx_mirror.gdshader` mit eigenem `light()`: Das Environment
    spiegelt nichts, darum spiegelt jedes Plättchen je Lampe ein Rauschmuster × deren Licht und blitzt (`glint_*`);
    ohne Licht bleibt sie dunkel.
  - **Partylampen** (`world/party_lights.gd`, Spielkonzept 7.6): `SpotLight3D` ohne Schatten mit flachem
    `spot_attenuation` – mit dem üblichen Abfall kam auf der Tanzfläche kaum Farbe an; ausgerichtet per
    `Basis.looking_at` (die Knoten hängen beim Aufbau noch nicht im Baum). Nicht in „lamps“.
  - **Konfetti** (`world/confetti.gd`, `Game.confetti`): `burst(pos, anzahl)` = einmaliges `CPUParticles3D`, danach
    `Decal`-Schnipsel am Boden (`MAX_DECALS`, verblassen). Auf Feiern und am Ende eines großen Schmückens.
  - Nichts davon gespeichert.

### Schreck, Erlebnisse, Wunden
- **Schreck** (Spielkonzept 6.12): Was erschreckt, steht in der Gruppe `shock_sights` mit Meta `sight_key`/
  `sight_kind` – Blutlachen (`Traces._as_sight`, Schlüssel aus dem Ort, auch nach dem Laden) und Leichen
  (`corpse:<id>`). `Guest._scan_for_shock` → jeder Schlüssel einmal (`seen_sights`) → `shock()`: `SHOCKED`, Haltung
  je `shock_style()` (aus dem Archetyp – keine neuen Zufallszahlen im Generator), dann `_after_shock()`. Steht er dabei
  in der Lache bzw. an der Leiche (`_keep_off`: Rand `TraceMark.keep_off()` bzw. `SHOCK_CORPSE`, plus `SHOCK_GAP`),
  tritt er zuerst rückwärts dorthin zurück, Blick hin (Richtung übers Navigationsnetz, gerade Linie, höchstens
  `SHOCK_BACK_TIME`) – der Schreck läuft erst danach ab. `remember()`
  legt ein Erlebnis an (`experiences`), `DialogUI.open` erzählt das älteste unerzählte (`Social.experience_line`).
- **Überlebende & Verletzungen** (`guests/wounds.gd`, `Wounds` – nur Daten und Sätze, Zustand im Gast; Spielkonzept
  6.17): `Wounds.survives(gast)` (20 %, `SURVIVE`) in `MonsterDirector.kill_guest` (zählt dann nicht als Opfer) und
  `PumpkinMan._hit`; der Lakengeist verwundet beim Losreißen (`SheetGhost.GUEST_ESCAPE`, im Mittel ebenso 20 %).
  **Kernfiguren** (`Guest.is_core()`: Profil aus `GuestProfiles.ALL`) überleben jeden Angriff, auch im Puppenzimmer. `Guest.wound_by(art, angreifer)` setzt Wunde, Heilzeit, Bettruhe
  (`_go_to_bed`, `in_sickbed()` – ansprechbar), Blutspur (`_bleeding`), `wound_facts` und erzählt es weiter
  (`_spread_wound_news`). Heiser: `Game.sound_at("wheeze")` (eigener `VOICES`-Eintrag aus `breath.wav`). Besuch am
  Krankenbett: `DialogUI._wound_visit`. Gespeichert je Gast: `wound`, `wound_left`, `wound_bed`, `wound_facts`,
  `wound_told`, `wound_visited`. Debug `--wound=gast,art[,hin]`, `--kill=gast`.
- **Geschenke in der Hand:** `DialogUI._gift` → `Player.hand_over()` → `Guest.receive_gift` (Hand); danach trägt er es
  heim (`_carry_gift_home`) oder isst es (`_gift_step`). Nicht zu verschenken: `DialogUI.NO_GIFT` (Hotelgegenstände).

### Haushalte (Spielkonzept 6.20)
- **HAUSHALTE.md** ist die Quelle (von Hand gepflegt). `tools/build_households.py` macht daraus
  `assets/data/households.json` (`households` mit Mitgliedern, `special`: Sonderzimmer). `LevelBuilder.refresh_households()`
  (in `main._ready` nach `refresh_maps`) setzt neu um, wenn HAUSHALTE.md oder der Umsetzer neuer sind. Der LevelBuilder
  ordnet Haushalte über ihre Stelle im Plan den Zimmern zu (4, „Zimmer“).
- `Social._add_households()`: je Zimmer erst Erwachsene, dann Kinder (`_add_member`); Kernfiguren als Kopie aus
  `GuestProfiles.ALL` (`placed`), die übrigen über `GuestGenerator.make_member` bzw. `make_child`, Seed fest je Person
  (`"H05/Luis".hash()`). Profil: `surname`, `household`, `member`. Ohne Datei die alte Verteilung (`_add_families`).
- **Eine Tür je Haushalt:** Startdeko gebündelt beim `household_lead(no)` (höchstens `HOUSEHOLD_START_DECO`, bei einer
  Kernfigur `CORE_START_DECO` – ihre 4–5 Stück mit einem starken Licht stehen fest in `GuestProfiles.ALL`, 5.10); nur er
  füllt die Tür auf, prüft Lampen und
  beschwert sich (`Guest.is_household_lead`). Mitbewohner klauen einander nichts. `MonsterDirector._household_factor`:
  der Deko-Anspruch wächst je weiterem Erwachsenen (`HOUSEHOLD_DEMAND`). `Guest.housemate_of` zählt als Familie.
- **Spielstand:** Roster-Einträge mit `household` und `member`; `restore_roster` baut sie über `_add_member` neu und
  stellt die Reihenfolge des Einzugs wieder her (`_household_order`).

### Zimmerzugang (Spielkonzept 6.19, `guests/room_access.gd`, `RoomAccess` als `Social.access`)
- **Gästetüren:** `Guest._open_doors` öffnet nur Türen, durch die der eigene Weg führt (`_path_through`), die eigene
  schließt er dazu auf. Zimmertüren (außer 013) schließt er hinter sich (`_door_behind`), sobald niemand im
  Schwenkbereich steht (`_someone_in_swing`), die eigene schließt er ab. `Social.behind_lock`/`spot_room`: keine
  Verstecke und keine Birnen hinter fremden Schlössern.
- **Klopfen** (`Door._knockable` → `knock`): niemand da (`residents_home`, mit Schlafenden im Bett) → „Niemand macht
  auf“; schlafen alle, weckt es einen (`Social.wake_guest`, Grund wie am Bett – mit gutem Grund ohne `WOKEN_MALUS`);
  sonst öffnet einer
  einen Spalt (`Door.set_ajar`, zählt nicht als offen) und `DialogUI.open_door` zeigt das Gespräch (fragen, lügen,
  Panik, bestechen). `chance()` aus Stufe und Zuschlägen; je Gast ein Versuch pro Spielstunde (`RETRY`).
- **Besuch** (`visit`), **von innen** geht jede abgeschlossene Zimmertür auf (`Door._inside`, niemand wird
  eingesperrt), **Hausfriedensbruch** (`_watch_trespass`).
- **Aufbrechen** (Brecheisen, `Door._forcible`, `Door._work`): Tür danach `broken` (offen, `set_open(false)` greift
  nicht) → `RoomAccess.on_forced` (Zeugen, Gerede, `suspects`). Leise mit dem **Generalschlüssel**
  (`RoomAccess.GENERAL_KEY` am Bund, `Door._general_fits`); der Schlüsselschrank in der Lobby ist weg (ZIM-136), der
  neue Ort offen (ZIM-6) – bis dahin nur über `--werkzeug=schluessel`. `Door.monster_open` macht eine
  abgeschlossene Zimmertür ebenfalls kaputt. **Reparieren** mit Werkzeugkasten (`on_repaired`); am Morgen
  (`_morning_repairs`) repariert jeder Haushalt seine Tür selbst; `LENDER_HOUSEHOLD` leiht seinen Werkzeugkasten.
- **Schlüssel stehlen** (`RoomAccess.steal_key`): Am Bett, in dem ein Gast in seinem Zimmer schläft (`key_sleeper`,
  auch der Zweite im Doppelbett), fragt `HideSpot._key_here` → `can_steal_key` (stehend, Schlüssel noch nicht am Bund)
  und ersetzt Schlafen/Hinsetzen durch „Zimmerschlüssel vom Nachttisch nehmen“. Der Schlüssel (`Door.key_id`) kommt an
  den Bund, `stolen[zimmer]` = nächster Morgen `LOCK_SWAP_HOUR`; feindselige Tat, Tagebuch „first_theft“, Zeugen wie
  `Social.on_player_took` (`KEY_THEFT_*`). `_swap_locks`: Lebt der Haushalt noch, wird der Schlüssel am Bund zu
  `OLD_KEY` + ID (`Item.key_label`: „passt nicht mehr“). Gespeichert als `social.access` (`save_state`).
- **Zweitschlüssel** (`_offer_spares`, `give_spare`): Ein erwachsener guter Freund (`Social.Tier.GOOD_FRIEND`), frei
  (`IDLE`/`WALK`), in `SPARE_RANGE` und mit Blick auf dich, gibt ihn – einmal je Haushalt (`spares`, gespeichert), nicht
  in Gefahr oder im Gespräch. Mit ihm kein Hausfriedensbruch (`_watch_trespass`). Zurück (ZIM-54): `_revoke_spares`
  (im 0,5-s-Takt, nur über `spares`) – ist ein Erwachsener des Haushalts ab `Social.Tier.ENEMY` (`_spare_enemy`), kommt
  das Zimmer in `stolen` (nächster Morgen `LOCK_SWAP_HOUR`); `_swap_locks` tauscht dann, wenn er noch verfeindet ist
  (`_revoke`: aus `spares`, Schlüssel zu `OLD_KEY`; er sagt es, bist du bis 10 m nah, sonst Haltung „lock_swapped“ für
  `Talk.greeting`), sonst bleibt der Schlüssel. Kein neues Feld (über `stolen`/`spares`). Debug
  `--zweitschluessel=id,zurueck`.
- **Feinde** (6.18, 4; ZIM-162): `_shut_out_enemies` (im 0,5-s-Takt): Gast ab `Social.Tier.ENEMY`, daheim
  (`room_at`), frei, Tür offen und nicht kaputt, du draußen bis `ENEMY_DOOR_RANGE` – erst dann die Zeugensicht
  (`Guest.can_see_actor`, `Player.recognized_by`). Er geht zu `door_inside` (`_shutting`, höchstens
  `ENEMY_DOOR_TIMEOUT`), schlägt die Tür zu, sobald niemand im Schwenkbereich steht, und schließt ab (`_shut_step`).
  Versteck: `Player.enter_hide` → `Social.on_player_hid`: ein stark Verfeindeter, der das Hineingehen sieht
  (`can_see_actor(p, at)` wie `Monster.can_see_actor`, Auffälligkeit beim Hineingehen), ruft `BETRAY_LINES` und macht
  Lärm `betray` (12 m). Nur beim Ereignis, nicht je Frame. Nicht gespeichert. Debug `--feind=id,tuer|versteck`.
- **Einbruch bei 13** (`guests/break_in.gd`, `BreakIn` als `Social.break_in`): Racheakt eines stark verfeindeten
  Erwachsenen (`Social.Tier.STRONG_ENEMY`), frei, je Gast einmal am Tag, für alle zusammen höchstens alle `GAP`; nur,
  wenn der Spieler nicht in Zimmer 13 ist (`_player_inside`, auch vor dem Aufbrechen geprüft), nicht in Nachtruhe oder
  solange das Monster unterwegs ist. Ablauf über den Besuchsablauf in `job["phase"]`: `go` (vor die Tür) → `force`
  (`FORCE_TIME`, Rütteln; dann wie `Door._forced`: `broken`, offen, Lärm `door_force`, Tat „revenge“) → `take`
  (Meta `taken_from`, gesetzt in `Social.on_player_took`, sonst Deko des Spielers über `Social.on_guest_stole`, sonst
  `MONEY`) → `read` (vor den Schreibtisch, `READ_TIME`) → heim (Deko vor seine Tür, anderes in den Koffer). Bricht ab,
  sobald er aus dem Ablauf fällt. Zeugen: Spieler (`player_can_see`) erfährt den Namen, Gäste rufen; sonst Hinweis beim
  nächsten Betreten (`_notice`). Die Tür repariert nur der Spieler (Zimmer 13 hat keinen Haushalt). Nicht gespeichert.
  Zeugen unter den Gästen (ZIM-54, `_witnesses`, alle, die es sehen – `can_see_actor`): Haltung `distrusts:<id>`
  (`Talk.STANCE_TIME`, keine Freunde mehr, `GuestPals.are_pals`) und `saw_break_in` mit `who` (`WITNESS_MEMORY`) →
  `Talk.greeting` nennt den Namen und schreibt ihn ins Notizbuch. Tagebuch (`_read_diary`, nach `READ_TIME`):
  `Diary.dark_entries()` (aufgeschriebene Einträge aus `Diary.DARK` mit `who`, gesetzt bei `note(id, text, who)`,
  gespeichert ab Version 66), je Eintrag einmal (Haltung `read:<id>`, `READ_MEMORY`) →
  `GuestPals.spread_with_affected`: Netz wie `spread` mit `DIARY_GOSSIP`, dazu Einträge an die Betroffenen
  (Bestohlener; bei „careless_death“ `pals_of` des Toten) mit `DIARY_AFFECTED` ohne Tratsch-Faktor (`direct`), weiter
  mit `pass`. Debug `--einbruch=id,tagebuch|zeuge`.
- **Bad** (`guests/bath_use.gd`, `BathUse` als `Social.bath`): `LevelBuilder._room_baths` legt je Zimmer `baths`
  an ({door, id, spot `BATH_SPOT_DEPTH` hinter der Badtür}). Wer zu Hause herumsteht (`IDLE`, `_is_home`), geht mit
  `CHANCE` je Blick (alle `SCAN` s, höchstens alle `GAP`) über den Besuchsablauf hinein, wenn niemand drin oder auf dem
  Weg ist (`occupied`), schließt die Tür leise (`_someone_in_swing`, bis `CLOSE_TRIES`) und steht `STAY` s; hinaus geht
  er mit dem nächsten Vorhaben (`_open_doors` öffnet sie, sie bleibt offen). Kein Schloss; wer aufmacht, hört
  „Besetzt!“. Nicht in Nachtruhe, Feier, solange das Monster unterwegs ist. Nicht gespeichert.
- Debug: `--klopfen[=zimmer[,weg]]`, `--tuer=zimmer`, `--werkzeug=brecheisen|kasten|schluessel`, `--bad=id`,
  `--schluesseldieb[=zimmer[,tausch]]`, `--zweitschluessel=id`, `--einbruch=id[,eigen]`.

### Kinder (Spielkonzept 6.13)
- `Guest.is_child()`, `parent_guest()`, `is_orphan()`; Profil mit `child`, `age`, Archetyp „Kind“, Sätze aus
  `CHILD_LINES` (`{eltern}` → Mama bzw. Papa).
- **Nie Opfer** – an allen Stellen einzeln abgesichert: `Monster._actors()` ohne Kinder, `_check_hide_step` behandelt
  ein Kind im Versteck als leer, `Director.on_actor_hid`/`kill_guest` übergehen Kinder, `_max_victims` zählt sie nicht,
  der Lakengeist würgt nie (`_frighten_child`), der Kürbismann jagt sie nicht (`_can_hunt`). Kinder zählen nicht als
  Zeugen (`_witness_guests`) und nicht für `all_asleep()`. Neue Bedrohung → dasselbe beachten.
- Familie: Schreck des Kindes trifft die Eltern. Waisen (`is_orphan()`) schließen sich dem Spieler nicht an (seit
  2026-10-25); die Zeile „orphan“ im Generator ist ungenutzt, bleibt aber (Spielstände, `save_rules`).
- **Nachtruhe:** `sleepless` (`_night_activity()`: ans Fenster, durch den Flur, an Zimmer 13 klopfen).
- **Süßes oder Saures:** an Zimmer 13 (`Social._update_tricks`, `_trick_at_door`, `give_trick_sweet`, sonst
  `_trick_prank`) und **von Tür zu Tür** (`_update_rounds`, `start_round`, `_rounds[id]` mit Phasen `walk`, `knock`,
  `host`, `pause`; `_round_answer` nimmt Süßes aus dem Vorrat oder der Süßigkeiten-Truhe des Zimmers –
  `take_room_sweet`). Süßigkeiten liegen in Kommoden (`Dresser.LOOT`), Vorräten, Süßigkeiten-Truhen
  (`LevelBuilder._sweets_chest`) und im Snackautomaten. Debug `--trick=13[,n]`, `--trick[=kind]`.
- Gespeichert wird nur `parent` in der Gästeliste; `sleepless`, Besuche und Süßes oder Saures nicht.

### Weitere Teilsysteme (Kinder von `Social`)
- **Flecken und Putzen** (`guests/tidying.gd`): `_messes()` = Kürbismatsch und Spuren `MESS_TRACES`; Beschwerden
  (`_complaints`, Meta `complained`), ein ordentlicher Gast (`is_tidy`) wischt (`TraceMark.wipe`) oder trägt Matsch
  in die Küche bzw. kocht ihn (`Stove.claim_cook`). Nicht gespeichert. Debug `--mess[=wachs]`.
- **Kerzenpflege** (`guests/candle_care.gd`, Spielkonzept 5.12; `Social.candles`): alle `SCAN` s, nicht in der
  Nachtruhe und nicht, solange das Monster unterwegs ist (`_quiet`), höchstens ein Gang je `GAP`. `_own_doors`: der
  Haushaltsvorstand (bis `DOOR_RANGE`, gleiches Stockwerk) sieht nach dunkler eigener Deko (`is_dark`: Kerze, Kürbis,
  Totenkopf aus oder ohne Kerze), Wahrscheinlichkeit `_care_chance` (Angst rauf, `Guest._forget_light` runter).
  `_passing`: feste Kerzen in `PASS_RANGE` mit Blick, `PASS_CHANCE`. `_send` plant die Schritte (`steps`, Meta
  `candle_care` am Ziel): `fetch` (neue Kerze aus dem Kerzenvorrat, `ResourceSpot.guest_consume`; aus dem Koffer
  `stock` gleich in die Hand), `flame` (ohne Feuer: zur nächsten brennenden Flamme `_nearest_flame`, `FLAME_RANGE`),
  `go` (`_tend`: anzünden bzw. `Item.insert_candle`/`FixedCandle.renew`), ohne Feuer an der eigenen Tür `pickup` →
  `flame` → `place` (über `PLACE_DECO`, `expected_deco` −1/+1). Feuer: `has_fire` fest nach Gast-ID (`FIRE_SHARE`,
  Kinder nie). Keine Flamme: `_ask_player` (`ASK_RANGE`, `ASK_GAP`). Gänge über `start_visit` →
  `Social.on_visit_arrived` → `on_arrived`; abgebrochen (`_process`): geholte Kerze in den Koffer, eigene Deko fällt.
  Nicht gespeichert. Debug `--kerzenpflege=id[,ohne]`.
- **Der Grinch** (`guests/grinch.gd`, Spielkonzept 2.6; `Social.grinch`): Gustav Peters = Gast mit Haushalt `H25`
  (`Grinch.is_grinch`, static – Hooks in `start_party`, `_household_deco`, `Guest._at_home`, `Decorating._available`,
  `GuestRequests.offer_for`, `_round_answer`, `DoorContest._can_gather`). `relation` beim Start höchstens −35.
  `_process` alle `SCAN` s: Gänge (`_job`: `door`, `wreck`, `party`, `punch`) laufen über `start_visit` →
  `Social.on_visit_arrived` → `on_arrived`; ohne Gang der Reihe nach Partyraum (`_party_due`: Feier oder Licht an),
  eigene Tür (`_go_door`), Begegnung (`_meet`: Spruch, `_spoil`, oder mit `ATTACK_CHANCE` `_attack`), fremde Tür
  (`_go_wreck`), Streit suchen (`_seek`). Wegwerfen (`_dispose`): Zerbrechliches an fremden Türen vor die Füße,
  sonst den Flur hinunter in die freiere Richtung (Strahl), zu kurz oder zum zweiten Mal (`grinch_tossed`) →
  `_tear`. Würfe über `Item.throw_from` mit Gustav als Werfer – Treffer an Gästen meldet `Item._throw_hit` an
  `on_thrown_hit`; den Spieler trifft Geworfenes physikalisch nicht (`THROW_MASK`), daher `_check_player_hit` nach
  der Flugzeit. Schlag gegen Gäste: `stagger` und `_hit_back = false`; gegen den Spieler `Guest.start_attack`.
  Während der Versammlung (`is_gathering`) geht er heim. `taken`: Tür auf und entriegelt, `Traces.add_drag_trail`,
  `die`, Kleidungsstück, `Social.on_guest_died(g, "unseen")` (keine Meldung, kein „first_death“). Danach Gerede bis
  `found()` (Zimmer 020 betreten oder Tagebuch gelesen → Tagebuch „first_death“). `GustavDiary` (innere Klasse) auf
  `LevelBuilder.room_tables[020]`, Text nach Uhrzeit (`DIARY`, letzter Eintrag erst nach seinem Tod). Nicht
  gespeichert – alles ergibt sich aus Gustav tot, Tür, Spuren und dem Tagebuch des Spielers. Debug `--grinch[=tot]`.
- **Streiche** (`guests/pranks.gd`): `play(kind, zimmer)` wählt nach `WEIGHTS`: `leaves`, `topple`
  (`Item.knock_over`), `pumpkin`/`candle` werfen (aus dem Koffer der Familie holen, `_go_throw`, `_throw` →
  `Item.throw_from`). **Zeugen** (`_witnesses`) erzählen es dem Bewohner → `pals.add_feud`. Debug
  `--prank=art[,zimmer]`. **Eier** (`egg`, 6.13): aus dem Koffer der Familie (`stock`) oder dem Eierkarton in der Küche
  (`ResourceSpot` Art `EGG`, `refill_mornings(EGG_BOX)` – morgens wieder 10, Gäste je eins am Tag) – `_fetch_egg`;
  geworfen an die Tür (`Door.center` + 0,25 m) oder mit `EGG_WINDOW` von draußen ans Zimmerfenster (`_window_target`:
  klares Außenfenster des Zimmers, Platz im Garten `EGG_WINDOW_DIST` davor, draußen, auf dem NavMesh, höchstens
  `EGG_WINDOW_HEIGHT` tiefer); Flugzeit nach Abstand (`EGG_THROW_TIME`). Debug `--prank=egg|eggwindow[,zimmer]`.
- **Schmück-Aktionen** (`guests/decorating.gd`, Spielkonzept 5.9; zählen als Spaß für den Kürbismann – `is_crew`,
  `player_joins`): Jede Stelle ist eine `Decorating.Action` (`site`, `host`, `crew`, `group` …); eine `group` umfasst
  alle Stellen eines großen Schmückens (Belohnung und Konfetti, wenn die letzte endet). Ablauf je Mitmacher im Zustand
  `DECORATE`: `fetch` (Platz reservieren `_reserve_slot`, Deko aus dem Koffer passend zur Ebene `top`/`wall`/`floor`)
  → `carry` → `hang` (`Item.hang`) → `admire`; mehrere Stücke tragen sie gestapelt (`_stack_in_arms`, eingefroren –
  darum nicht gespeichert). Platzsuche: `_find_site`/`_door_site`/`_wall_site`/`_lobby_site`, frei heißt glatte Wand
  (`_wall_at`) und nichts im Umkreis (`_space_free`). Arten: klein (Gast ruft auf, nur tagsüber), **allein**
  (`_update_solo`, dauerhaft mindestens `SOLO_MIN` unterwegs – so füllt sich das Hotel bis Halloween; Deko aus einer
  `ResourceSpot` mit Tageslimit), **groß** (`start_big`, mehrere Stellen), vom Spieler aufgerufen (`call_here`).
  Abbruch bei Feier, Nachtruhe oder Unruhe; `_update_sleep` schiebt die Nachtruhe auf, solange eine Aktion läuft.
  Nichts gespeichert – die Deko sind normale Gegenstände (`hung`). Debug `--decorate[=…]`, `--trace` `[Schmücken]`.
- **Schmücken mit Plan, Klauen bei Knappheit** (`guests/deco_plan.gd`, `DecoPlan`, Kind von `Decorating` als `plan`,
  Spielkonzept 5.10 Stufe 3): Alle paar Minuten (`GAP_EARLY` … `GAP_LATE`, höchstens `PLAN_MAX` zugleich, je Gast
  `DAILY` am Tag) schickt es einen freien Gast (`_free` – wie `_available`, aber auch mit Angst bis `PANIC`) als
  Allein-Schmücken an eine Tür (`Decorating.start_solo_door`: aus dem Koffer, ohne Starkes darin aus einer Kiste, sonst
  Gebasteltes): mit Angst ab `AFRAID` an die eigene, solange sie nicht sicher hält (`weak`: Abschreckung unter Druck ×
  `SAFE_MARGIN`), sonst mit `FRIEND_CHANCE` an die schwächste Tür eines Freundes (`friend_door`, `pals_of`; Zimmer 13
  ab `Social.Tier.FRIEND`). Nach einem Tod (`Social.on_guest_died` → `on_guest_died`) schmücken die `MOURNERS`
  nächsten Nachbarn bis `MOURN_RANGE` nach `MOURN_DELAY` ihre Türen nach (vor allen anderen). **Klauen:**
  `Guest._try_steal` fragt `steal_when_scarce`, wenn er weder feindlich noch verzweifelt ist – bei Knappheit (`scarce`:
  die Kisten ohne Nachschub haben höchstens `SCARCE_SHARE` ihres Vorrats), Angst ab `THEFT_FEAR`, ohne Starkes im
  Koffer und mit schwacher eigener Tür, einmal am Spieltag mit `THEFT_CHANCE` × (0,5 + Gier): das beste starke Stück
  (kein Füllmaterial) bis `LOOT_REACH` vor einer fremden Tür, die hält (`_strangers`: ohne Freunde, Familie,
  Mitbewohner, Zimmer 13; nicht vom Spieler, nicht in `THEFT_UNSEEN` um ihn, Weg im Flur über `_hall`) – dann wie jeder
  Dieb `STEAL` → `PLACE_DECO` vor die eigene Tür. Erfolglos sucht er erst nach `THEFT_RETRY` wieder. Nichts
  gespeichert. Debug `--schmuckplan=angst|freund|tod|klau[,gast]`, `--trace` `[Schmuckplan]`.
- **Deko-Suche** (`guests/deco_search.gd`, Spielkonzept 5.9): ein freier Gast (nur tagsüber) geht zu einer
  erreichbaren `ResourceSpot` (`Decorating._reachable`, `guest_can_take()`), Mutige zu Spinnweben und Keller, manchmal
  zu zweit; bietet dem Spieler an mitzukommen (`has_offer`, `ask`). Zustand `SEARCH`. Nicht gespeichert. Debug
  `--search[=gast][,mit]`.
- **Freundschaften unter Gästen** (`guests/pals.gd`, `GuestPals`, Spielkonzept 6.16): `counts` (`"id_a|id_b"` →
  gemeinsame Taten; `note`, `note_group`), `are_pals` (Familie, genug Taten oder Zimmernachbarn – nie bei `feuds`, nicht
  bei Gerücht `distrusts:<id>`), Weitererzählen (`_update_telling`, `heard`), `praise`, Feindschaften (`feuds`,
  `add_feud`), „Freund meines Feindes“ (`on_player_befriended`). Gespeichert: `counts`, `feuds`. Debug
  `--pals=…`, `--rival=…`, `--netz=…`.
  - **Freundesnetz als Kanal** (Spielkonzept 6.18, 1; 2026-11-03): `spread(tellers, amount, cap)` – Lob (`praise`) und
    Klagen (`Social._spread_gossip`: Schlag, Diebstahl, Einbruch, fremdes Bett, Beleidigung, Schummeln, Eier;
    aufgeflogene Lügen aus `Talk.expose`) gehen nur an die Freunde (`pals_of`) der Erzähler (Opfer, Zeugen) und warten
    in `_net` auf ein Treffen (`TELL_RANGE`, beide `_free`, nicht im Schlaf, einer je `TELL_SCAN`, `_update_net` vor
    `_update_telling`). Wirkung `amount × net_strength(Erzähler, Station)` = Tratsch (`profile.gossip`) × 0,5^(Station−1);
    nach `NET_STATIONS` (2) ist Schluss, jeder hört eine Nachricht nur einmal (`_net_known`), nach `NET_TIME` (ein
    Spieltag) ist sie vergessen. Dieselbe Stärke nutzt `Talk._pass_on` für die Angst aus weitererzählten Geschichten.
    Nicht gespeichert (wie früher das Gerede). Debug `--netz=a,b,c[,lob]`, Stichwort „netz“, `--trace` „[Netz]“.
- **Streit unter Gästen** (`guests/quarrels.gd`, `GuestQuarrels`, Spielkonzept 6.16; 2026-11-03, ZIM-33): Kind von
  Social, `Game.social.quarrels`. `Social.on_guest_stole` → `on_theft(Dieb, Bestohlener)` bei Diebstahl unter Gästen
  (`DecoPlan.steal_when_scarce` und Panik-Diebstahl, nicht im Haushalt): sieht der Bestohlene den Dieb
  (`Guest.can_see_actor`), gleich `_discover`, sonst merken sich bis zu `NEWS_WITNESSES` wache Freunde des Bestohlenen
  (`GuestPals.are_pals`), die den Dieb sehen, die Nachricht in `_news` (bis `NEWS_TIME`) und erzählen sie beim Treffen
  (`TELL_RANGE`, beide `GuestPals._free`). `_discover` → `active[GuestPals.key]` = {thief, victim, day, argued, keep}
  und `pals.add_feud`. `_update_meetings` (alle `SCAN`, nicht im Schlaf): beide frei, bis `ARGUE_RANGE`, einer sieht
  den anderen → Wortwechsel (`_start_argument`: wer frei und ohne etwas in der Hand ist, bleibt stehen und sieht den
  anderen an, `Guest.hold_argument`; `_argue_step` vier Sätze im Abstand `LINE_GAP`, je Satz `Game.noise("quarrel")`,
  10 m); danach unter `AVOID_RANGE` → `_avoid`: einer geht nach Hause (`Guest.walk_home`), je Gast höchstens alle
  `AVOID_COOLDOWN`. Ende über `_end`: `reconcile` (aus `GuestRequests.deliver`) oder `_fade` nach `FADE_DAYS`
  Spieltagen (beim Tageswechsel, daher auch nach dem Zeitsprung im Schlaf); `keep` (schon vorher verfeindet) lässt
  `pals.feuds` stehen. Vermitteln: Anlass `DialogUI._mediate` (`partner_of`, nur ohne eigene Bitte und ab „neutral“) →
  `GuestRequests.make_reconcile` + `accept`. `Talk.opinion` nennt den Diebstahl (`stole_from`). Gespeichert unter
  `social.quarrels` (`active`, Version 67), nicht `_news` und kein laufender Wortwechsel. Debug
  `--streit=dieb,opfer[,gesehen|freund|versoehnen|verblassen|halten]`, Stichwort „streit“, `--trace` „[Streit]“.
- **Gespräche** (`guests/talk.gd`, `Talk`, Spielkonzept 6.9): Die Knöpfe baut `DialogUI` (`_show_main`, Optionen in
  einem `ScrollContainer`), die Logik liegt in `Talk`: Anlässe (`_occasions()`), Erlebnisse des Spielers (`log`,
  `_scan_sights`), Gedächtnis je Gast (`Guest.claims`, höchstens `MAX_CLAIMS`), Erzählen/Lügen (`tell`, `_believes`,
  `_see_through`), Auffliegen (`expose`, `_check_lies`), Weitererzählen (`_update_spread`), Fragen der Gäste
  (`pick_question`, `answer()`), Haltungen `Guest.stances` (`wary`, `careless`, `distrusts:<id>`, `brave_thinks`,
  `promise`, `no_trust`, `confront`, `grieving`; `set_stance`/`has_stance`, `prune_stances`). Freundliche Gesten über
  `Talk.friendly` (Tagesbudget wie Plaudern). Gespeichert je Gast `claims`, `stances`; `social.talk` = `log`, `next_id`,
  `suspects`, `deaths`. Debug `--gespraech=frage|erlebnis|luege,…`, `--trace` `[Gespräch]`.
- **Bitten** (`guests/requests.gd`, `GuestRequests`, Spielkonzept 6.14): Eine Bitte ist ein Dictionary (`kind` = `item`,
  `escort`, `message`, `game`, `reconcile`; `heart`; `item`/`variety`, `target`, `game`, `money`; Texte `ask`, `task`, `thanks`,
  `say`, `reply`). **Herzensbitte** je Gast einmal (`hearts`: offen/erfüllt), aus `CORE` (Kernfiguren) bzw. `HEART`
  nach `Talk.temper` – ohne Zufall, Plaudertaschen wählen den Empfänger fest aus der ID (`_message_target`).
  **Kleine Bitten** nach Lage (`_make_small`: Kind → Süßes, kahle Tür des Haushaltsvorstands → Lieblingskürbis, abends
  Kerze, morgens Kaffee, sonst `profile.likes`), `SMALL_PER_DAY` im ganzen Hotel, `MAX_SMALL` zugleich, verfallen am
  Ende des Spieltags (`_end_of_day` → `Notebook.miss_task`). Ablauf: `DialogUI.open` fragt `offer_for` (vor den Fragen
  des Gastes; „Sag mal …“ → „Kann ich dir irgendwie helfen?“ ohne Zufall) → `_show_offer` → `accept`
  (`Notebook.add_task` mit der Bitte-ID) bzw. `decline`. Erfüllen: `on_gift` aus `DialogUI._gift` (Kürbis →
  `Guest.gift_to_door`: `_carry_gift_home` geht mit `PLACE_DECO` vor die Tür), `on_game_played` aus Würfel-, Schach-
  und Dartspiel, Begleiten (`start_escort` = `start_follow`, `_check_escort`: an der Bar), Ausrichten als Anlass beim
  Empfänger (`message_for`/`deliver`), der Auftraggeber dankt beim nächsten Gespräch (`thanks_on_greet`).
  `reconcile` (Vermitteln im Streit, `make_reconcile`, `RECONCILE`) läuft wie `message`, ohne Frist, zählt nicht zu
  `SMALL_PER_DAY`/`MAX_SMALL`; `deliver` ruft `GuestQuarrels.reconcile`. `_complete`:
  Herzensbitte `HEART_REWARD` direkt (außerhalb des Budgets), kleine über `Talk.friendly`, dazu `pals.praise`.
  Gespeichert unter `social.requests` (`active`, `hearts`, Tageszähler). Debug `--bitte=gast[,art[,annehmen|erfuellen]]`,
  `--trace` `[Bitte]`.

### Kochen (`world/stove.gd`, `Stove`, `Game.kitchen`, Spielkonzept 3.8)
Herd auf der Plan-Ausstattung „stove“. `phase`: `empty` → `raw` (`dish_for`) → Messer → `cooking` (Spielzeit über
`delta`) → Teller `ROAST_PUMPKIN` bzw. Suppe mit Portionen, die kalt wird. `_call_eaters` holt Gäste in den Zustand
`EAT`; `_end_soup` → `pals.note_group`. **Gäste kochen** selbst (`_update_guest_cook`, `start_guest_cook`). Essen ist
Spaß (`is_eating`, `player_eats`). Herd und Essende nicht gespeichert, der Teller schon. Debug
`--cook=suppe|braten[,fertig]`, `--cook=gast[,id]`.

### `HotelCat` (`guests/hotel_cat.gd`, Spielkonzept 6.11)
Katzen aus `HotelCat.PROFILES` (einige mit `home` im Katzenraum), erzeugt nach den Gästen (`place_at_start()`).
Zustände `IDLE, WALK, SLEEP, FLEE, WAIT_DOOR, PET, FOLLOW, GIFT, FETCH, CARRIED`.
- **Größe:** `size` je Profil (1,1 Mausi bis 1,6 Kasimir) skaliert `_visual`, Kollisionsbox, Agent, Posen-`drop` und
  das Lauftempo der Animation; Beute im Maul wird gegenskaliert, auf dem Arm sitzen große Katzen tiefer.
  `BoilerCat.SIZE` = 1,6.
- **Tragen:** `pick_up()`/`put_down()`, `_carried_step` setzt sie jeden Frame vor die Brust, `Player.carried_cat`
  sperrt Gegenstände; gespeichert zu Füßen des Spielers. Debug `--cat=id,tragen`.
- **Türen:** Kollisionsmaske ohne Türen (wie Gäste); geschlossene Türen erkennt `_door_ahead()` → `WAIT_DOOR`.
- **Möbel:** `perches()` = `LevelBuilder.cat_perches` + Betten und Fensterbänke bewohnbarer Zimmer + Lobbyfenster –
  **feste Reihenfolge, der Index wird gespeichert**. Hoch/runter per Tween (`_hop`), oben ohne Schwerkraft.
- **Monster:** `_monster_near()` auch, wenn es unsichtbar umherstreift → `FLEE` mit Lärm `cat_cry`; der Director
  ignoriert Lärm mit `quelle is HotelCat`, das Monster sieht Katzen nicht (eigene Ebene).
- **Deko umwerfen:** `Item.knock_over()` für `Item.TOPPLE_KINDS`; `Item.is_toppled()` zählt nicht als Deko, Spieler
  stellt per [E] auf, Gäste daheim. Gast-Deko holen: `FETCH`, `Social.cat_thefts`, Verdacht `Social.cat_blame`.
- **Aussehen:** Laufen = Animation `walk`, sonst Posen aus `POSES` per `_turn()` im Skelettraum.
- Gespeichert (Gruppe `cats`, angewendet nach den Gegenständen): Lage, Lieblingsgast, Zuneigung, Geschenk-Timer,
  Liegeplatz, Schlaf, Beute im Maul.

## 7. Speichern & Laden

- JSON in `user://saves/` (`slot_1..3.json`, `autosave.json`, `suspend.json` + `.png`), geschrieben über `.tmp` + Umbenennen.
  `SaveManager.collect()` sammelt, `SaveManager.apply(data)` stellt her. Headless (Testläufe, Rauchtest) und mit `--bg`
  stattdessen `user://saves_headless/` (`SaveManager.DIR`) – sonst überschreibt ein Testlauf den echten Autosave.
- **Laden = Hauptszene neu aufbauen, dann befüllen.** `load_slot` setzt `Game.pending_load` und wechselt die Szene;
  `main.gd` ruft nach dem Aufbau `SaveManager.apply` auf.
- **Feste Welt-Objekte werden über die Reihenfolge in ihrer Gruppe zugeordnet** (`_apply_group`: Index i im
  Spielstand ↔ i-ter Knoten der Gruppe). Passt die Anzahl nicht, wird die ganze Gruppe mit Warnung übersprungen.
  Spuren an Türen/Fenstern speichern ebenfalls den Index in `doors`/`windows`.
- **Fingerabdruck der Welt** statt Versionssprung bei jedem Umbau (Rückwärtskompatibilität erst spät, Entscheidung
  19.10.): `main.gd` ruft nach dem Aufbau `SaveManager.note_world()` – MD5 über Anzahl und Lage der Knoten jeder Gruppe
  in `WORLD_GROUPS` (bei `COUNT_ONLY` nur die Anzahl). Steht als `world` im Spielstand und in `user://saves/world.txt`,
  damit die Slot-Übersicht ihn vor dem Aufbau kennt. `fits(data)` = passende Version und gleicher Abdruck; nicht passende
  Stände zeigt `SlotList` gesperrt („passt nicht mehr zu diesem Hotel“), `newest_slot` übergeht sie. Ist `world.txt`
  veraltet, prüft `main._load_pending` nach dem Aufbau erneut. **Neue gespeicherte Gruppe → in `WORLD_GROUPS`.**
- `VERSION`/`MIN_VERSION` nur für den Aufbau des Spielstands selbst (Felder in `collect`/`apply`), mit Kommentarzeile.
- **Gegenstände** werden nicht zugeordnet: beim Laden alle gelöscht und aus `kind` + `extra` (`Item.create_extra()`)
  neu erzeugt. Neuer Gegenstandszustand → in `create_extra()`/`_build()` abbilden oder in `_item_data`/`_make_item`
  ergänzen. Viele Zustände stecken im Zusatzfeld (Kürbissorte, Fratze `f=`, Faulzeit `r=`, Matsch `mush_extra` mit `w=`,
  Kerze `lit`/`out`/`unlit`, Taschenlampe `c=…;uv;on`).
- **Reihenfolge beim Anwenden:** erzeugte Gäste zuerst (`Social.roster_state` / `restore_roster`: nur
  `{id, seed, room, arrived, parent, household, member}`, in Erzeugungsreihenfolge), weil sich alles Weitere auf
  Gast-IDs bezieht. Dann Welt → Director-Werte → Gäste → Gegenstände → Spieler (`look` zuerst über `Player.set_look`,
  dann Hand, Tasche `bag` über `Player.set_bag`) → Soziales → Monster zuletzt.
- Speicherbare Welt-Objekte bieten `save_state() -> Dictionary` / `load_state(d)` (HideSpot, Lamp, HotelPhone,
  LightSwitch, HotelWindow, Dresser, LockerBank, Elevator, FixedCandle …) oder werden in `collect()` direkt ausgelesen
  (Door, Chest, Plant, Resource). Neues Objekt mit Zustand: Gruppe + Eintrag in `collect()` und `apply()` + `WORLD_GROUPS`.
- Beim Laden `d.get(key, standard)` verwenden, damit fehlende Schlüssel nicht abstürzen.
- **Nicht gespeichert**, beim Laden zurückgesetzt (`apply` ganz am Anfang): `Decorating`, `DecoSearch`, `Stove`,
  `CoffeeMachine` (auch der Wasserkocher), `Pranks`, `Tidying`, `CandleCare` (`reset()`) – sonst zeigten laufende Aktionen nach
  `--savetest` auf die neu gebauten Gäste ins Leere. Ebenso nicht: Auftritte von Lakengeist und Kürbismann, Wetter,
  Flackerwelle, Feiern, Spinnen, Fledermäuse.
- **Was wo steht** (Überblick; Einzelheiten in `collect`): `player` (Lage, Hand, `bag`, `look`, Geld, Schock,
  `awake_time`/`sure_awake`/`rested`, `drunk`/`hangover`, `coffee`/`caffeine`/`tea`, `injury`, `disguised`, Kompass, Kartenblätter,
  Schlüssel), `guests` (je Gast Lage, Werte, Vorrat, Erlebnisse, `seen`, `corpse`, Wunden, `claims`, `stances`),
  `social` (Beziehungen, `pals` = `{counts, feuds}`, `talk`, `sleep_active`, `night_seed`, `cat_blame`), `director`
  (Werte, Phase, Absicht, Puppenfrist und Weg), `doll`, `ghost` (`visits`, `catch_up_day`, `hour_meetings`,
  `first_seen`), `shower` (Dusche in Zimmer 13: `stage`), `pumpkin`
  (Spaßwert, Besuche, Garantie), `contest`, `notebook` (mit `seen`), `diary`, `traces` (mit Schleiern), `elevators`,
  `resources` (mit `guest_day`) und die Welt-Gruppen.
- **Speichern gesperrt** (`can_save`) bei Jagd oder Monster in der Nähe, während der Flackerwelle, solange der
  Kürbismann sich ankündigt oder im Hotel ist und der Lakengeist beim Spieler ist; Autosave nur in sicheren Momenten
  (`is_safe_for_autosave`, auch nicht ohne Boden unter den Füßen), sonst aufgeschoben (`request_autosave` merkt einen
  Grund vor, `_process` prüft jede Sekunde).
- **Autosave-Auslöser (Spielkonzept 8.10)** – nur noch drei, nicht mehr Tod eines Gastes, Ende einer Feier oder
  aufgeschlossene Türen:
  - **Fortschritt:** `SaveManager.on_progress(grund)` – der Aufruf für alle Systeme, die einen großen Schritt erkennen
    (Aufzug repariert, Kürbismann erlöst, Fluchtweg …); einmal je Ereignis rufen. Heute hängt daran nur
    `Player.add_key` → `on_key(id)`: Schlüssel aus `PROGRESS_KEYS` (`zimmer_18`, `dachboden`, Schaltschlüssel `aufzug`). Debug `--fortschritt`.
  - **Neuer Bereich:** `NEW_AREAS` (Dachboden, U2, Sperrbereiche – bisher Zimmer 018), erster Besuch je Spiel in
    `visited` (gespeichert). `_area_at` nimmt den Zonennamen, im Dachgeschoss „Dachboden“ (dessen Flurzonen heißen wie
    im OG; Bodenhöhe aus `LevelBuilder.attic_beams`).
  - **Aufwachen in Zimmer 13:** `_check_wake` merkt sich beim Einschlafen Zeit und Bett (`HideSpot.own_bed`) und
    sichert beim Aufwachen, wenn der Schlaf mindestens `NIGHT_SLEEP` in einer Nachtruhe (`Social.night_window`) lag –
    einmal je Nacht (`_night_saved`). Abgefragt statt im Schlafsystem eingehängt; der Autosave folgt, sobald man aus
    dem Bett ist (sichere Momente).
  `reset_pending` (neues Spiel, `apply`) verwirft Vorgemerktes. Mit `--trace` „[Autosave] vorgemerkt/gespeichert“.
- **Zwischenstand (8.10):** „Unterbrechen und beenden“ im Spielmenü (`Menus._confirm_suspend`) → `SaveManager.suspend`
  schreibt Slot `SUSPEND` (`suspend.json`, Bild ohne Menü nach einem gezeichneten Bild) und beendet. Gesperrt wie das
  Tagebuch (`can_save`). Im Versteck oder Bett speichert `collect` die Lage vor dem Versteck (`exit_point`). `load_slot`
  löscht ihn bei jedem Laden (`drop_suspend` – der Stand steckt dann in `pending_load`), ebenso `Game.start_new_game`.
  `newest_slot` (Fortsetzen) und `SlotList` im Modus LOAD kennen ihn. Debug `--unterbrechen[=laden]`.
- **Tagebuchsatz** (`diary_sentence`, 8.5, 8.10): Zeile der Puppe, dann je Gruppe ein Teil (`_guest_lines`: Tote,
  Feinde, Freunde) – mit Namen nur `_named_in_diary` (Kernfiguren; zentrale Gäste docken dort an), der Rest gezählt
  („Edna ist fort. Neun andere auch.“, Zahlwörter bis zwölf), dann Kürbisse vor der Tür, Zittern; höchstens drei Teile.
- **Prüfen:** `--savetest` sammelt → wendet an → sammelt erneut und meldet Unterschiede – nur nötig, wenn sich am
  Speichern etwas ändert. Bekanntes Rauschen gleicht `main._settle` an und meldet es als „(kein Fehler)“: Türen mit
  einem Gast im Türrahmen, Dinge in der Hand, Drehung liegender Gegenstände (Euler-Mehrdeutigkeit, Nachrollen),
  Katzen, deren Zeitgeber zwischen den Messungen ablief, und schwache heiße Stellen (bis `SAVETEST_NOISE_HEAT`) aus
  Lärm gleich nach dem Laden – Krähen und Fledermäuse sitzen dann wieder (Flug wird nicht gespeichert) und fliegen vor
  einer nahen Bedrohung (Lakengeist, Monster) erneut auf. Selten bleibt ein Gegenstand, den ein Gast dazwischen anstößt.
  Der Savetest stellt vorher eine andere Spielerfigur ein und setzt sie danach zurück.

## 8. Weitere Systeme

### Licht
(`lamp.gd`, `light_switch.gd`, `flicker_light.gd`, `world/fixed_candle.gd`, `util/shadow_budget.gd`,
`level/light_rooms.gd`, `LevelBuilder._wall_lamp`/`_desk_lamp`/`_candle`/`_halogen`)
- Lampe = Fassung + Birne (Item `BULB`; Halogenröhren und Unterwasserlampen ohne Birne – `has_socket()` falsch).
  `flicker` (Nähe des Monsters, kann Birnen durchbrennen), `wave` (Flackerwelle), `red`/`hot_spot` (Kürbismann) setzt
  der Director bzw. der Kürbismann. Licht aus → `on_lights_off`. `FlickerLight.hold` (≥ 0) legt die Helligkeit fest,
  egal was der Schalter sagt – das Flackern kommt noch dazu (Badlampe der Dusche, 4.24); −1 = aus.
- **Alle Lampen werfen Schatten** (`lamps`, außer Meta `no_shadow`): Godot hält Licht nur mit Schatten an Wänden auf –
  eine Lampe ohne Schatten scheint durch alles hindurch. Damit das bezahlbar ist, werfen die meisten nur Schatten vom
  Bau (`shadow_caster_mask` = `ShadowBudget.LAYER`, Sichtebene 15): Wände, Böden und Decken fasst `ShadowBudget.merge`
  nach dem Bau je Kachel (`TILE`, je Stockwerk) zu unsichtbaren Meshes zusammen, die nur Schatten werfen
  (`SHADOWS_ONLY`, Knoten „Schattenbau“); Türen liegen selbst auf der Ebene (sie bewegen sich). Die `full` nächsten
  Lampen nehmen alles außer den Kacheln (Möbel, Figuren, echte Wände). Der Schatten blendet erst mit dem Licht aus
  (`distance_fade_shadow` = Anfang + Länge der Licht-Ausblendung) – sonst schien es dazwischen durch Wände.
  Bias der Lampen `ShadowBudget.BIAS` (0,03) statt Godots 0,1: mit 0,1 löste sich der Schatten von Möbeln an der
  Wand, und an Fugen dünner Bretter (Regalfächer) lief Licht als helle Linie durch; 0 gibt Flecken (Spiegel in 13).
  Normal Bias, Atlasgröße und Filter änderten daran kaum etwas (verglichen 31.10.). Abgleichen: `--schatten-bias`.
- **Geprüft und verworfen:** Paraboloid-Schatten (verbiegen große Wandflächen, lassen Licht in Flecken durch), größerer
  Schattenatlas 8192 (deutlich teurer). Godot 4.7 rendert Punktlicht-Schatten jedes Bild neu, auch ohne Bewegung; die
  CPU-Zeit hängt an der Zahl der Schattenlampen, nicht der Meshes. Der Atlas hat 88 Plätze.
- **Abschalten nach Grundriss:** Lichter (`lamps` und `light_source`), die die Kamera nicht erreicht, schaltet
  `ShadowBudget` für die Darstellung ab (`light_cull_mask` 0, kein Schatten; eigene Werte in den Metas
  `hidden_mask`/`hidden_shadow`) – sie konkurrierten sonst um die Atlasplätze, und wer keinen bekommt, scheint durch
  Wände. An/Aus, Energie und `light_at` bleiben unberührt. Die Bereiche baut `LightRooms` (`LevelBuilder.light_rooms`)
  automatisch aus dem Plan: Raster je Stockwerk, Wände gerastert, freie Läufe per Union-Find zu Bereichen. Dauerhaft
  verbunden: Treppenhäuser, Treppen, `open_above`/`voids`, freier Himmel. Türen verbinden, solange `Door.lets_light()`;
  Fenster, Aufzugtüren, Glaswände nur einen Schritt weit. `reach` regelmäßig und sofort nach `Door.set_open`
  (`ShadowBudget.wake`, sonst kommt das Licht durch den Spalt zu spät); liegt die Kamera in keinem Bereich, bleibt alles
  an. Stockwerk der Kamera nach der Höhe (`_floor_at`); liegt unter ihr keine Fläche, aber im Stockwerk darüber (bis
  `BELOW`), gehört sie dorthin (ins Becken gefallen) – nicht, wenn bis `NEAR` eine Fläche ihres Stockwerks liegt oder
  sie über einem `voids`-Luftraum steht (sonst kippte sie im Sprung an Wänden und an der Galerie über der Lobby ins
  Dachgeschoss). **Im Code gebaute Wände ohne Plan-Eintrag trennen keine Bereiche.**
- **Andere Stockwerke:** Über Treppen und offene Türen hängt fast das ganze Haus an einem Bereich – ging im Speisesaal
  eine Tür auf, zählten auch die Halogenröhren im UG darunter und die Lampen im OG darüber (103 statt 45 im Umkreis,
  über den 88 Plätzen: Licht durch Boden und Decke, das mit jeder Tür sprang). Darum zählt ein Licht auf einem anderen
  Stockwerk als die Kamera nur, wenn seine Reichweite eine Treppe oder einen Luftraum zu ihr hin erreicht
  (`LightRooms.passages_near`, Bits hinauf/hinab, gemerkt in der Meta `light_passages`). Steht die Kamera bis
  `ShadowBudget.STAIR_NEAR` an einer, zählt das ganze Nachbarstockwerk in diese Richtung (Treppe, unter der Galerie);
  im Freien gilt die Regel nicht.
- Jeder Raum hat mindestens eine Wandleuchte, sonst schaltet sein Schalter nichts. **Helligkeit nachjustieren:**
  `Lamp.BRIGHTNESS`/`REACH` für alle gemeinsam, sonst `WALL_LAMP_ENERGY` (Wandleuchten mit Fächer dazu `Lamp.FAN_REST`/`FAN_BOOST`), `ROOM_LAMP_ENERGY`, `CANDLE_ENERGY`, die
  Deckenfarben (`CEILING_SHADE` …), Umgebungslicht und Mond (`main._setup_environment`).
- **Feste Kerzen** (`FixedCandle`, aus `_candle` auf Möbeln) siehe „Kerzen“.
- **Statische Testszene** (`util/static_export.gd`, `util/static_walker.gd`, Debug `--static-eg[=pfad]`): kopiert das
  Erdgeschoss (Bauteile aus `structure_parts`, eingeschaltete Lampen als schlichte `OmniLight3D` mit Schatten) in
  `res://temp/eg_static.scn` mit eigenem Läufer – zum Messen der Renderkosten ohne Spiellogik. Dazu feste Messpunkte
  (`StaticExport.BENCH_POINTS`, Kameras unter „Messpunkte“) und für den Engine-Vergleich (ZIM-121) derselbe Bau mit
  Lampen und Messpunkten als `eg_static.glb` (ShaderMaterials gehen verloren) samt `eg_static_lampen.json` (Godot-Werte
  der Lampen, Messpunkte). Messlauf: Szene direkt starten mit `-- --bench[=pfad] --bg` – je Punkt 2 s einschwingen,
  6 s messen ohne VSync, Bildzeiten nach `temp/bench_godot.csv`, Übersicht in die Konsole, dann beenden; je Punkt ein
  Bild nach `temp/bench_shots/` (mitten im Einschwingen). Unsichtbare Knoten fliegen vor dem Export raus (sonst verlangt
  das glTF `KHR_node_visibility`, das Unreal ablehnt). MultiMeshes (z. B. Vertäfelung) fehlen im glTF.

### Grafikstufen (Spielkonzept 8.4, ZIM-94)
Einstellung `Settings.graphics` (Index in `Settings.GRAPHICS`, in `user://settings.cfg`, nicht im Spielstand; ohne
Eintrag Hoch). Wirkt sofort über `Settings.changed`: Fenster und RenderingServer stellt `Settings.apply` ein, Umgebung,
Mond und `ShadowBudget.full` `main._apply_settings`, die Sichtweite `Player` (`camera.far` = Sicht +
`Settings.VIEW_MARGIN` 4 m). Hoch ist der Stand vom 3.11.2026 (Ziel RTX 4060 Laptop, 1080p mit 30 FPS), Niedrig zielt auf
neuere Onboard-Grafik mit 30 FPS. Die Werte sind Vorschläge, im Spiel nicht gemessen (Debug `--grafik=…`, `--perf`).

| Wert | Niedrig | Mittel | Hoch |
|------|---------|--------|------|
| Auflösung der 3D-Ansicht (`scaling_3d_scale`, Modus) | 67 %, FSR 1 | 85 %, FSR 1 | 100 %, bilinear |
| Schattenatlas der Lampen (`positional_shadow_atlas_size`) | 2048 | 4096 | 4096 |
| Lampen mit Schatten von allem (`ShadowBudget.full`) | 5 | 8 | 12 |
| Weiche Schatten (`*_soft_shadow_filter_set_quality`) | sehr niedrig (1) | niedrig (2) | niedrig (2) |
| Mondschatten: Atlas / Reichweite | 2048 / 25 m | 4096 / 40 m | 4096 / 40 m |
| Spiegelungen (SSR) beim Wählen / Schritte je Strahl | aus / 64 | an / 96 | an / 128 |
| SSAO · GI (SDFGI) | aus · aus | aus · aus | aus · aus |
| Lichtnebel-Raster (`environment_set_volumetric_fog_volume_size`) | 48 | 64 | 64 |
| Sichtweite: Nebelende (`fog_depth_end`) / Kamera | 40 / 44 m | 52 / 56 m | 66 / 70 m |

- **Spiegelungen:** Die Stufe setzt beim Wählen (`Settings.set_graphics`) den Haken „Spiegelungen“ auf ihren Wert;
  danach lässt er sich wieder umstellen und gilt (auch auf Niedrig). Die Schritte je Strahl gehören fest zur Stufe.
  Andere Einzelregler (Helligkeit, Sichtfeld, VSync) berührt die Stufe nicht.
- **Schatten:** Die 88 Plätze im Atlas bleiben auf jeder Stufe (weniger Plätze: Lampen schienen durch Wände, siehe
  „Licht“) – nur ihre Auflösung sinkt. Weniger `full`-Lampen heißt: Möbel und Figuren werfen nur nah an der Kamera
  Schatten, das Licht im Raum bleibt gleich.
- **SSAO und GI** nutzt das Hotel in keiner Stufe (Umgebungslicht ist eine feste Farbe, `_setup_environment`); die
  Spalten `ssao`/`sdfgi` machen sie je Stufe schaltbar, falls Hoch sie bekommen soll.
- **Sichtweite:** Der Nebel wird zum Ende hin schwarz, darum sieht man den Schnitt nicht – auf Niedrig verschwinden
  Flure und das Monster aber schon nach 40 m im Dunkel. Andere Kameras (Bowling) übernehmen `camera.far` beim Start,
  der Türspion bleibt bei 40 m.
- Debug `--grafik=niedrig|mittel|hoch` setzt die Stufe nur für die Sitzung (nichts gespeichert), Szenarien mit
  Stichwort „grafik“. Headless rendert Godot nichts – der Rauchtest prüft nur, dass das Umschalten ohne Fehler läuft.

### Fenster, Türen, Verstecke, Kommoden
- **Fenster** (`hotel_window.gd`): klares Glas / Vorhang (Ebene 10 nur für Sicht & Mond); Milchglas kann die Klasse,
  ist aber nicht verbaut.
- **Türen** (`door.gd`): Blatt auf Ebene 2 (Glastür 7); Rahmen über `OpeningFrame`. Blatt gebaut (`Look.PLAIN`,
  Glastüren) oder Modell (`HOTEL`, `ATTIC`): `leaf` auf die Blattgröße gestreckt, bei `dir` = −1 gespiegelt; Klinke und
  Bänder ungestreckt. **Milchglastür** (`Look.FROSTED`, Planfarbe „Milchglastür“): Seiten-, Ober- und Unterholz aus
  `Geo.grain_box` im Holz der Zimmertür (`FROSTED_STILE`/`_TOP`/`_BOTTOM` wie deren Friese), Scheibe `Mat.frosted_glass`
  ohne Schattenwurf in Glashalteleisten, Drücker und Bänder der Zimmertür (`_add_fittings`), Rahmen `DoorCasing`; Ebene 2
  wie eine Holztür (Sicht zu, Handabdrücke ja). Spuren über `attach_mark(mark, seite, at)`. Zustände `locked`, `broken`, angelehnt
  (`set_ajar`), Zimmerzugang siehe 6.
- **Türspion** (`player/peephole_view.gd`, `PeepholeView` als Kind des Spielers, `shaders/peephole_view.gdshader`,
  Spielkonzept 7.17): `add_room_number` merkt sich die Flurseite (`_peep_side`) und setzt vor die Linse den Lichtpunkt
  (`_peep_dot`, Scheibe mit gemeinsamem Leuchtmaterial, `PEEP_DOT_RANGE`). `Door.aims_at_peephole` – Tür zu, Auge auf der
  Zimmerseite höchstens `PEEP_REACH` vor dem Blatt, `aim_point` höchstens `PEEP_AIM` neben der Linse – macht aus [E]
  `Player.peep`. Die Kamera (Bildwinkel `CAM_FOV`) steht `CAM_OUT` vor dem Blatt im Flur und malt in ein SubViewport
  `PX`², das nur beim Hinsehen `UPDATE_ALWAYS` ist; der Shader rechnet stereografisch auf `FIELD` um (Messingrand,
  5-Tap-Unschärfe, Vignette) und dunkelt nach `MonsterDirector.light_at` vor der Linse ab (`DARK`…`BRIGHT`).
  Beim Hinsehen: Spielerkamera `cull_mask` 0, `ShadowBudget.view_from` = Spionkamera (sonst wären die Flurlichter
  hinter der geschlossenen Tür aus), Taschenlampe `Flashlight.set_masked`, `_input` schluckt Maus, [E] und Esc;
  Bewegen, Dialog, Verstecken, Würgen, offene Tür oder `LEAVE_DIST` beenden. `Player.view_camera()` ist dann die
  Spionkamera – `MonsterDirector.player_can_see` und `Monster._update_noticed` (dort das ganze Bild statt der
  Blickmitte) sehen hindurch, Sichtung 4.5 inklusive. Auge (`EYE_*`): einmal je Hinsehen gewürfelt, höchstens einmal
  am Spieltag (`_eye_day`, nicht gespeichert); er steht danach dicht vor der Tür, `noticed`. Ohne Hinsehen prüft
  `PeepholeView` alle `LENS_EVERY` s `Door.update_lenses` (Türen aus `Door.near`, Licht 0,6 m hinter dem Spion).
  Panik-Klopfen: `Guest.KNOCK_GLANCE` (umdrehen über die Schulter). Nichts davon wird gespeichert.
- **Verstecke** (`hide_spot.gd`): `occupant` reserviert; `seen_entering` = Todesurteil; `checked` als Spur;
  `own_bed` = Bett in Zimmer 13, `room_no` = Zimmer jedes Betts (fremde Betten, 3.6); `rattle()`/`burst_open()` für den Lakengeist; Betten mit `bed_size`, `head_x`,
  `partner`. Zerwühlt verschiebt `set_checked` die Bettdecke.
- **Balkenbett** (`bed_model.gd`): `BedModel.build(parent, size, head_x)` für alle Betten; Holz über `Geo.grain_box`
  (UVs folgen der Faser, Hirnholz an den Stirnseiten), Meshes je Maß geteilt. `Guest.BED_TOP`/`BED_FOOT_GAP` und der
  Katzenplatz (`BedModel.blanket_top`) richten sich danach.
- **Kommoden** (`world/dresser.gd`): Drei Schubladen als eigene Körper, interagierbar je ein `Dresser.Handle`. Hohler
  Korpus, damit die Physik Gegenstände nicht aus geschlossenen Schubladen drückt. Modell aus `tools/build_dresser.py` (Meshes aus dem glTF, Kollision als Kästen; Tabelle in 1). Fund nur beim **ersten** Öffnen
  (`searched`, `LOOT`); feste Inhalte aus `CONTENT[…]["drawer"]` (`fixed`). Beim Schieben werden die darin liegenden
  Gegenstände kurz kinematisch eingefroren und mitbewegt (Ausnahme von „nie `freeze` direkt“). Unterarten bauen sich in
  `_build()` selbst und legen Schubladen mit `add_drawer(y)` an (setzen `size`, `tray`, `slide`); `add_drawer` nimmt je
  Schublade auch Mitte `x`, Innenmaß, Auszug und Vorderkante des Kastens (Schreibtisch). `loot = false`: nur feste
  Funde (`fixed`, Index von oben über `_top_index`), sonst ein Spruch aus `empty_lines`.
- **Schreibtische** (`world/desk.gd`, ZIM-154): `Desk extends Dresser`, zwei Fassungen aus `tools/build_desk.py` mit dem
  Möbelbausatz – `direktion` (Plan „Möbel: Schreibtisch“, 2,10 × 1,05 × 0,78 m, zwei Unterschränke, sieben Schubladen,
  Lederauflage DIN A1, stellt den Sessel `Armchair` davor, `CHAIR_GAP`) und `sekretariat` („Möbel: Sekretariatsschreibtisch“,
  1,40 × 0,75 m, Wange links, Unterschrank rechts, vier Schubladen). Feste Größe, mittig im Rechteck, Rücken an dessen
  Hinterkante. Modell `desk_<fassung>.glb`: Korpus (`carcass`), je Schubladenart Kasten und Beschläge
  (`drawer_s/_l/_c`, `pulls_s/_l/_c`: Unterschrank klein, tief, Mitte; Knöpfe, Schlüsselschild mit schwarzem Loch – nur
  Zier, Abschließen ZIM-6), `leather`. Lage der Schubladen (von oben: Mittelschublade, dann je Unterschrank von oben,
  links zuerst) und Kollisionskästen schreibt das Bauskript nach `desk_<fassung>.json`; Unterschränke und das Gehäuse
  der Mittelschublade bleiben hohl. Holz `Mat.hotel_wood` mit `desk_<fassung>_ao/_normal.png` (Atlas 2048, Furchen und
  Mulden gemalt). Leder: `Mat.pbr_model(desk_direktion_leather)` – Farbe, Goldprägung (Metall im Blau der ORM-Karte)
  und abgegriffene Mitte über die ganze Auflage (DIN A1, 2048 px), dazu als Detail über UV2 (Kachel 10 cm) die Narbung
  (`_leather_grain_albedo` multipliziert, `_leather_grain_normal`), `_leather_mask` hält sie von der Prägung fern; alles
  im Bauskript mit numpy erzeugt (Worley-Zellen, Rauschen), kein Foto. Nur feste Funde (`loot = false`).
- **Nachttische** (`world/nightstand.gd`, 30.10.): `Nightstand extends Dresser`, Plan „Möbel: Nachttisch“ (5 × 5 px,
  Vorderseite als hellere Zeile). 0,5 × 0,5 m, Höhe `BedModel.POST_TOP` (0,51 m, bündig mit den Bettpfosten). Bretter
  aus heller Eiche über `BedModel.beam` mit eigener Kollisionsform: Deckplatte, Seiten bis zum Boden, Rückwand, Fachboden.
  Oben eine Schublade ohne Griff, darunter ein offenes Fach ohne Bodenbrett. Gruppe `dressers`, also gespeichert,
  mit Fund und Spinnen wie die Kommode.
- **Bücherregale** (`world/bookshelf.gd`, ZIM-152): Plan „Möbel: Bücherregal <4|5> Ebenen <1|2> m“ → `bookshelf_<n>_<m>`,
  gesammelt und nach allen Möbeln in `LevelBuilder._bookshelves` gebaut. Rücken `BACK_GAP` (3 cm, Vertäfelung) vor der
  Hinterkante, Länge = Rechteck minus Kranzvorsprung; ohne Vorderseite im Plan quer zur langen Seite zur Mitte der Fläche. **Innenecke:** steht am Ende ein gleich hohes Regal quer, das zur
  Zeile zurückblickt (Rechtecke berühren sich; egal, welches bis an die Wand reicht), endet die Kante des Korpus auf
  dessen Vorderseite (aus dessen Hinterkante + `BACK_GAP` + `DEPTH`) und das Ende wird `miter_l/r` – beide Seiten
  der Ecke rechnen das gleich, die Gehrungen treffen sich. Verschieden hoch: Warnung, freie Enden. `Bookshelf._ready`
  teilt die Länge in n = round((innen + Zwischenwand) / Teilung) gleiche Fächer und setzt je Teil einen MultiMesh unter
  sich (Fächer in x gestreckt); `INSTANCE_CUSTOM` = (Lage + `grain.x`, `grain.y`, Streckung) wie bei der Vertäfelung,
  daher keine Spiegelung (eigene Teile links und rechts). Kollision: Sockel und Kranz durchgehend (an der Ecke bis an die
  Wand), Rückwand, Seiten, Zwischenwände, Fachböden – die Fächer bleiben hohl. Nicht im Spielstand. `_furnishings`
  mit Oberkante `Bookshelf.height(levels)`.
- **Bücher** (`world/books.gd`, ZIM-153, Spielkonzept 7.7): nur Ausstattung, keine Kollision, nichts gespeichert.
  `LevelBuilder._bookshelves` (und die Demo von `--regale`) ruft am Ende `Books.fill(regale)`: je Fach aus
  `Bookshelf.compartments()` (linke Kante, lichte Breite, Boden, lichte Höhe; Fachboden vorn bei `DEPTH/2 − SHELF_SET`)
  füllt `_compartment` von links nach rechts – Griffe aus einer Reihe (`SET_CHANCE`, 3–9 gleiche Bände, eine Farbe) oder
  einem Band, Streuung je Griff in Stärke und Höhe (`THICK`, `TALL`, als Skalierung der Instanz), Rücken `SETBACK` hinter
  der Vorderkante, je Buch `JITTER`, selten `PUSHED` tiefer, kleine Drehungen. Lücken zieht es aus einem Budget
  (Fachbreite × (1 − `FILL` ± `FILL_SPREAD`)); nach einer Lücke lehnt sich das nächste Buch mit `LEAN_CHANCE` schräg an
  den Nachbarn (`_lean`: Kopf am Nachbarn bzw. an dessen Oberkante, Fuß auf dem Boden), am Ende eines Fachs manchmal
  eines nach rechts an die Fachseite. In Fächern ab `STACK_MIN_SPAN` mit `STACK_CHANCE` ein liegender Stapel am Rand
  (größtes Buch unten, leicht verdreht). Zufall fest je Regal (Lage). Gezeichnet als ein `MultiMeshInstance3D` je
  Variante und Kachel `TILE` (10 m, Elternknoten der Regale, Gruppe `books`), Farbe je Buch linear in
  `INSTANCE_CUSTOM.rgb`. Schatten werfen sie erst ab `SHADOW_LEVEL` (Hoch; `Books.apply_graphics` aus
  `main._apply_settings`), sonst dunkelt `shaders/book.gdshader` nach hinten im Fach ab (lokal −z, `back_shade`).
  Modelle aus `tools/build_books.py` (Blender, ohne Vorlage): 10 Varianten (`VARIANTS`, Name, Stärke, Höhe, Tiefe,
  Bezug, Bünde, Schnitt), je 156 Dreiecke – Querschnitt aus halbelliptischem Rücken (`ARC` Abschnitte, Normalen glatt),
  Falz (`JOINT`), Deckeln (`BOARD`) mit Überstand `SQUARE`, Buchblock mit hohlem Vorderschnitt; Normalen von Hand
  gesetzt. Ein Atlas 2048² für alle mit eigener Abwicklung (Rücken dicht, ~3700 px/m; Deckel beide auf einer Insel;
  Kopf/Fuß; Vorderschnitt; kleines Feld für Kanten und Innenseiten), Skyline-Packung, die Dichte schrumpft, bis alles
  passt. Die Karten rechnet numpy je Pixel aus Formeln in Metern (Wert-Rauschen, Zellen für die Narbung, Leinwandbindung,
  Bünde als Höhe, Linien mit Mindestbreite 1,2 px, Abrieb an Kopf, Schwanz, Kanten und Ecken, Risse im Falz, Papier mit
  Lagen, Staub oben, Farbschnitt): `books_albedo.png` (Bezug grau, Gold und Papier farbig, Verschattung eingerechnet –
  Godots AO wirkte nur aufs Umgebungslicht), `books_normal.png` (OpenGL, Tangentenraum aus der Höhe), `books_mask.png`
  (Rot Bezug, Grün Rauheit, Blau Metall), dazu `books.json` mit den Maßen je Variante.
- **Stühle** (`world/chair.gd`, ZIM-156, Spielkonzept 7.14): Plan „Möbel: Stuhl“ → `chair`, fest 46 × 47 cm mittig im
  Rechteck, Sitzseite zur Vorderseite (Stühle im Umkreis eines Zimmertischs setzt weiter `_room_table`).
  `tools/build_chair.py` baut alles kantig mit Absicht schlicht (286 Dreiecke): Hölzer als Stränge mit rechteckigem
  Querschnitt (`sweep`, Deckel nur, wo man sie sieht – Enden in Beinen, Pfosten und auf dem Boden bleiben offen), die
  Pfosten über dem Sitz gerade um `RAKE` nach hinten geneigt (`post_z`), Kopfbrett und Querleiste in deren Ebene, in
  `BOW_STEPS` Abschnitten um `BOW` gewölbt. Das Kissen: vier Ringe um das Rechteck (senkrechte Seite, Rundung in
  `ROUND_STEPS` Schritten), oben ein Fächer zur gewölbten Mitte. Mesh und Material teilen alle Stühle. Kollision
  Sitzblock und Lehne (bis `BACK_REAR_Z`), ein Sitzplatz „stuhl“. Gruppe `chairs`, nicht im Spielstand.
- **Tafeln** (`world/dining_table.gd`, ZIM-157, Spielkonzept 7.15): Plan „Möbel: Tafel“ → `dining_table`, so groß wie
  das Rechteck (`DiningTable.fits`, sonst Kasten), lokal x entlang der langen Seite. Beine mit Mitte `OVERHANG` + `LEG`/2
  hinter der Plattenkante, nur vier Eckbeine, auch an langen Tafeln. Beine und Zargen aus
  `tools/build_dining_table.py` als MultiMesh je Teil: `leg_corner` (gebacken mit Zargen nach +x und −z, an den übrigen
  Ecken gedreht), Zargen aus Stücken von `PITCH` (eine Mulde) zwischen zwei Beinen aneinandergereiht und
  gestreckt (`apron_l`/`apron_r` am Bein mit eigener Verschattung, dazwischen `apron`); Basis (d · Streckung, oben,
  außen) mit d = oben × außen, `INSTANCE_CUSTOM` wie bei `Bookshelf`, die Holz-UV läuft je Seite durch. Platte und
  Läufer baut `DiningTable` mit SurfaceTool: Platte mit Kante `_edge` (Rundung oben, Fase unten, Gehrung an den Ecken),
  `Mat.hotel_wood()` ohne gebackene Karten; Läufer als 3 mm dünnes Band über die Rundung der Kante und `RUNNER_DROP`
  hinab, UV quer × entlang in Metern, `Mat.photo` mit `mesh_uv` (Texturen `TableRunner/` aus `tools/build_runner.py`:
  Damast der Vorlage, Bindung als Normale – Grund Schuss, Muster Kette, fünfbindiger Atlas –, Muster glatter in der
  Rauheit). Kollision Platte, Beine, Zargen; unter der Tafel frei. Gruppe `dining_tables`, nicht im Spielstand.
- **Süßigkeiten-Truhen, Automaten** (`world/chest.gd`, `world/vending_machine.gd`): nur aus dem Plan. Truhe in einem
  Hotelzimmer = Süßigkeiten-Truhe (Meta `sweets_room`, Gruppe `sweet_chests` und `chests`); Automaten mit leuchtender
  Front (`light_source`), nicht gespeichert.

### Sitzen
(`world/seat.gd`, `player.gd` `sit_down`/`leave_seat`/`stand_position`, Spielkonzept 3.1)
`Seat.attach(körper, art, sitzhöhe, boden, blick, länge, aufstehen)` hängt Plätze (`Marker3D`, je `SPOT_WIDTH`) unter
den Möbelkörper und setzt dessen `interactable` (außer der Körper hat schon eine – Betten fragt `HideSpot`).
`free_spot(aim_point())` nimmt den freien Platz, auf den man schaut. Spieler: Kollision aus, `_look` dreht nur um die
Sitzrichtung (± `SIT_TURN`). `stand_position()` sucht einen Platz für die Kapsel mit freiem Strahl (nie durch die
Wand); `leave_seat(true)` (vor Stoß, Verstecken, Spieltisch, Teleport, Laden, Würgen) steht notfalls vor dem Platz auf.
**Gespeichert** wird `pos` = `stand_position()` – geladen wird stehend. Debug `--sitzen[=…]`.

### Ausdauer, Schritte
- **Ausdauer** (`player.gd` `_update_stamina`, `exertion()`; Spielkonzept 3.1): nicht im HUD, nicht gespeichert.
  `exertion()` speist Herz und Atem (`SynthAudio._update_pant` spielt `breath.wav`). **Keuchen verrät:**
  `is_panting()` → Lärm `pant`; `Monster._check_hide_step` × `PANT_FOUND`; der Lakengeist merkt es. Debug
  `--sprint`/`--winded`.
- **Schritte** (`util/footsteps.gd`): Reiner Ton, kein Lärm (der läuft über `Game.noise("step"/"run")`). `Footsteps`
  ist ein `AudioStreamPlayer3D` an den Füßen; `step(boden, rennt, kind)` spielt aus `SOUNDS[boden]`.
  `Footsteps.floor_under(körper)`: Textur-Id des Bodens aus `FLOOR_TEXTURES` bzw. Meta `floor` (Fototexturen), `"air"`
  ohne Treffer – auch der Spieler entscheidet damit, ob Gehen Lärm macht (`Player.SOFT_FLOORS`). Neuer Klang = Eintrag in
  `SOUNDS`; je Schritt ein zufälliger aus der Liste, nie zweimal derselbe. `wood` (knarrende alte Dielen) gilt für alle
  Böden mit Meta `floor` = `wood` (Speisesaal, Kegelbahn, Holzdeck, Dachboden).

### Balkongeländer (`world/balcony_railing.gd`, `BalconyRailing`, Spielkonzept 7.7, ZIM-36)
- **Bau:** `LevelBuilder._balconies` legt auf den Stockwerken über dem EG jedes Geländer aus `balcony_edges`/`terrace_edges`
  als `BalconyRailing` an (Gruppe `balcony_railings`, lokal X entlang, ±Z die Seiten; der Kollider trägt `interactable`).
  `_railing_sides` sieht alle `STEP` m `PROBE` m neben dem Planstrich nach: `DECK` (Balkon, Terrasse), `AIR` (nichts auf
  diesem Stockwerk – darunter der Garten), `NONE`. Fehlt im Plan ein Balkon, gibt es dort auch nichts zu übersteigen.
- **`crossing(player)`:** an der Stichprobe vor dem Spieler – eigene Seite `DECK`, drüben `DECK` → Nachbarbalkon (Platz
  drüben per `Player.can_stand_at`), drüben `AIR` → Sprung, wenn ein Strahl nach unten zwischen `MIN_DROP` und
  `MAX_DROP` auf Boden im Freien trifft (`RainVeil.is_outdoor`). Mit vollen Händen (großer Gegenstand, Katze) nur ein Hinweis.
- **Spieler** (`climb_railing`, `_update_climb`): Kollision aus, die Füße laufen auf einer quadratischen Bézierkurve über
  den Handlauf (`CLIMB_TIME` 2 s zum Nachbarn, `CLIMB_DROP_TIME` 1,2 s bis zum Loslassen), Lärm `railing` (8 m) am Anfang und
  beim Übersteigen noch einmal auf halbem Weg. Danach fällt man frei (`_dropping`); beim Aufkommen `_land_from_balcony`:
  Lärm `fall` (4 m, statt `land`), Ruck, `limp` = `LIMP_TIME` (3 Spielstunden). `limp_share()` macht `LIMP_SLOW`
  langsamer und lässt in den letzten `LIMP_FADE` s nach, Rennen geht erst ohne `limp`, der Kopf sackt jeden zweiten
  Schritt ab. `limp` zählt in `_update_injury` und `skip_time` herunter und wird gespeichert (Speicherformat 70).
  `climbing()` (auch im Fall) sperrt Speichern und Autosave.
- **Bedrohungen** springen nicht: Im NavMesh gibt es keine Verbindung über die Kante, sie laufen zu `_last_seen` über die
  Treppe; aus dem Blick bricht die Jagd ab wie sonst auch (`Monster._chase_step`, 3,5 s, dann Suche). Der Notausgang beim
  Raubzug (`player_exposed`, ZIM-27) gilt auf dem Balkon wie im Garten unverändert.
- Debug `--balkon[=nachbar|humpeln]` (`BalconyRailing.debug`), Stichwort `balkon`.

### Gegenstände
- **Aufgehängte Deko** (Spielkonzept 5.6, `item.gd` `HANGABLE`, `hang`, `_sway`; `player.gd` `_hang_spot`):
  [G] auf eine Wand hängt auf statt abzulegen. Lichterkette = `FlickerLight` ohne Schatten (Meta `no_shadow`) in
  `lamps` – flackert also wie die Lampen. Gäste hängen eigene Deko an ihre Tür (`door_hang_spot`). **Unruhe**
  `MonsterDirector.deco_unrest_at(p)`: jeder hängende Gegenstand schwingt danach, nie in die Wand; ab `JOLT_UNREST`
  fallen Dinge herunter. Weitere Deko (5.7): `BAT_GARLAND`, `SPIDER`, `BROOM`, `SKULL` (`CANDLE_HOLDERS`).
  `ResourceSpot.with_pool()` gibt abwechselnd verschiedene Arten. Debug `--deco=art[,g]`.
- **Kürbissorten** (`world/pumpkin_kinds.gd`, Spielkonzept 5.8): `PumpkinKinds.DATA` je Sorte; die Sorte steht im
  Zusatzfeld (`"hokkaido"`, geschnitzt `"casper,unlit"`; leer = Halloween). **Neue Sorten nur hinten an `ORDER`.**
  Lieblingskürbis aus der Gast-ID (`favorite_of`, ohne Zufallsaufruf im Generator). Der Riese landet beim Ernten neben
  dem Beet und bremst beim Tragen (`Item.carry_speed`, `hold_offset`). Modell für Halloween- und Riesenkürbis
  (`PumpkinModel.VARIETIES`), Weißer und Hokkaido noch Grundkörper. Debug `--kuerbis[=n]`.
- **Knappheit & Verfall** (Spielkonzept 5.10): Kisten mit starker Deko leeren sich (`runs_out`), Gäste nehmen je Kiste
  höchstens ein Stück am Spieltag (`guest_day`) und bis Tag d zusammen höchstens `guest_allowance(d)` =
  ⌊`max_uses` × d / `EMPTY_DAY`⌋ (`guest_taken`, beides gespeichert; `guest_may_take(day)`) – ohne Spieler leer um den 15.,
  was der Spieler nimmt, kommt obendrauf (2026-11-03, ZIM-81). Debug `--kisten` rechnet je Kiste den Monat durch und zählt
  die Startdeko der Kernfiguren. Im Plan stehen derzeit weder Dekokiste noch Wäschekiste – nur die alte Deko im
  Heizkeller leert sich. **Kürbisse faulen** (`ROT_KINDS`, `rot_at` im Zusatzfeld
  `r=`): welk, eingefallen, weg (`_decay`). Füllmaterial zählt begrenzt (`FILLER_CAP`). Debug `--rot[=…]`.
- **Zerplatzen, Kürbismatsch** (`item.gd` `BURST_KINDS`, `burst`, `_break`): Nur `BURST_KINDS` haben
  `_physics_process` (andere nur im Flug, siehe Werfen); ein Aufprall aus mehr als `BURST_HEIGHT` (Kerze, Birne, Tasse: `BREAK_HEIGHT`) zerbricht sie
  (`_shatter_candle`, `_shatter_bulb`, `_spill_coffee`, sonst `burst()` → `PUMPKIN_MUSH`). Stücke (`_splash_chunks`)
  mit `continuous_cd` und mindestens 2 cm Kollision – dünne fielen durch den Boden; sie schrumpfen per Tween am Stück
  selbst weg (der Kürbis ist da schon frei – kein Lambda an ihm). **Kürbismatsch** liegt wie eine Blutlache
  (`_lay_mush`, Flecken unter `_spread` mit `top_level`), wird neu gelegt, sobald er still an einer neuen Stelle liegt
  (`_settle_mush`), Farbe über `albedo` = `mush_color` / `MUSH_TEX_COLOR`. Riesenspritzer: Hände voll entnehmen
  (`_take_portion`). Zusatzfeld `mush_extra` = `"sorte,zeitpunkt,größe,hände"`, dahinter wahlweise „w=…“ (Regen) und
  „s=drehung:länge“ (langer Spritzer, siehe Werfen). Debug `--fall[=h[,sorte]]`.
- **Werfen** (Spielkonzept 3.13; `player.gd` `_update_throw`, `throw_held`, `throw_speed`, `THROW_*`; `item.gd`
  `throw_from`, `_sweep`, `_throw_hit`, `_splash_wall`, `_lay_streak`; `hud.gd` `set_throw_power`): [G] mit etwas in
  der Hand setzt `_throw_hold`; losgelassen vor `THROW_HOLD` (0,3 s) legt bzw. hängt es wie bisher ab (`drop_held` –
  also erst beim Loslassen), länger gehalten steigt `throw_power` bis `THROW_FULL` (1,2 s), die Hand geht um
  `THROW_WINDUP` zurück, unter dem Fadenkreuz ein Balken. Loslassen wirft aus der Hand in Blickrichtung (+`THROW_LIFT`)
  mit `throw_speed(masse, kraft)` = `THROW_PUSH` / Masse^`THROW_MASS_EXP`, höchstens `THROW_MAX`, mit wenig Kraft
  `THROW_WEAK` davon (Kürbis 4 kg ≈ 5,7 m/s, Riese ≈ 1 m/s), dazu das eigene Tempo; 0,5 s keine Kollision mit dem
  Spieler. Auch die Kinder (`Pranks._throw`) werfen über `throw_from(start, tempo, wer)`. **Flug:** Solange `thrown`,
  fegt `_physics_process` je Schritt eine Kugel (0,45 × größte Kante der Kollisionskiste) vom letzten Ort bis einen
  Schritt voraus (`cast_motion` + `get_rest_info`, `THROW_MASK` = `MASK` | Gäste, ohne Werfer) – ein Strahl aus der
  Mitte kam zu spät, die Physik hatte den Körper schon gebremst; dazu als Rückfall der harte Aufprall (`THROW_IMPACT`).
  **Treffer** (`_throw_hit`): Gast → `Social.on_player_threw_at` (nur vom Spieler). **Ei** (`EGG`, 6.13) → `_splat_egg`:
  klebt als `TraceMark` „egg“ an Tür (`Traces.add_door_egg` → `Door.attach_mark`, aber anklickbar: klein, die Tür geht
  daneben auf), Scheibe (`add_window_egg`, Kind der `HotelWindow`, zweiseitig – verdeckt ein Stück Sicht; gewischt über
  `HotelWindow.get_prompt`/`on_egg`), Wand (`add_wall_splash`) oder Boden (`add_guest_drop`); Lärm `egg_splat`, dann
  `Social.on_egg_splat` (Bewohner/Getroffene sauer: auf das Kind, auf dich ab `EGG_BLAME_RANGE`, eigene Würfe nur mit
  Zeugen `EGG_PLAYER`). Grafik im Code gemalt (`TraceMark.egg_material`: Eiweiß dünn und glänzend, Eigelb gewölbt,
  Normal- und Detailkarte). Eierflecken lassen sich überall wischen (`can_wipe`), ordentliche Gäste putzen sie an
  Türen und Wänden (`Tidying`, `_stand_point`), nicht an Scheiben. Gespeichert wie die übrigen Spuren (Tür/Fenster/Welt).
  Debug `--eier`. `BURST_KINDS` zerplatzen bzw.
  zerbrechen (`_break`): an einer Wand (Normale flach, keine Tür `_is_door`, kein Glas) zuerst `_splash_wall` →
  `Traces.add_wall_splash`, der Kürbismatsch fällt davor herunter; am Boden merkt sich `_impact_velocity` das Tempo, und
  `burst` schreibt ab `STREAK_MIN` m/s „s=richtung:länge“ (`STREAK_PER_SPEED` je m/s, höchstens `STREAK_MAX`) in den
  Matsch. Alles andere prallt ab und macht Lärm `throw_land` bzw. ab `THROW_HEAVY` kg `throw_land_heavy` am Aufschlag –
  Quelle ist der Gegenstand, also geht das Monster dorthin (`MonsterDirector.on_noise` → `investigate`, Ablenkung 4.11).
  **Langer Spritzer** (`_lay_streak`, nur auf ebener Fläche): vom Aufschlag in Flugrichtung eine Kette unverzerrter
  Flecken wie der Strom auf Treppen, vorn 0,55, hinten 0,15 × Spritzergröße, leicht schlängelnd, jeder über
  `place_splat`; endet an Wand, Kante oder Stufe; frisch rutscht er mit `STREAK_FLOW` nach vorn. Aufgehoben ist er weg.
  Debug `--wurf=k[,gegenstand]`; Test `throw_checks`, Rauchtest `werfen`.
- **Feuer** (`world/deco_fire.gd`, Spielkonzept 5.11): `DecoFire.ignite_near(ort)` zündet leichte Deko
  (`FLAMMABLE`) an: eigener Körper mit Prompt „austreten [E]“, Licht in `light_source`, springt über, hinterlässt Ruß
  (`soot`). Nicht gespeichert.
- **Kerzen** (Spielkonzept 5.12; `item.gd` `lit`, `has_candle`, `light_up`, `snuff`, `blow_out`, `light_by`;
  `player.gd` `_use_flame`, `_snuff_target`, `_update_flame_wind`). Neue Kerzen brennen nicht, nur
  mit Zusatz `lit`; Kürbis/Totenkopf: `unlit` = ohne Kerze, `out` = Kerze erloschen. Anzünden mit Flamme oder
  `MATCHBOX` (Fundort `CONTENT["022"]["drawer"]`), auspusten, ausdrücken; in Bewegung kann der Wind sie ausblasen
  (`FLAME_OUT_*`, draußen und bei Wetter mehr, in Kürbis/Totenkopf geschützt, Stummel mal `STUB_WIND`). `FixedCandle`
  (feste Kerze auf Möbeln): Licht in `lamps`, das Monster bläst sie aus, gespeichert in `fixed_candles` (`lit`, `wax`).
  **Abbrennen** (2026-10-27): `Item.wax` (1 = neu) sinkt, solange sie brennt, um dt / `BURN_TIME` (ein Spieltag) –
  in `_process` alle `BURN_STEP` s und in `skip_time` (Zeitsprung); gespeichert im Zusatz `w=…` (Kerze, Kürbis,
  Totenkopf). `set_wax`: `CandleModel.burn_down` staucht das Wachs-Netz (Meta „candle_wax“, mindestens `MIN_STUB`) und
  setzt Flamme und Licht auf die neue Dochtspitze; unter `STUB` heißt sie „Kerzenstummel“, Licht `STUB_LIGHT`
  (`_light_full` = Licht der vollen Flamme aus `_add_light`). Bei 0 `_burn_out`: Kerze weg (aus der Spielerhand mit
  Satz, `Social.on_candle_burned_out` nimmt sie aus Gästehänden und senkt `expected_deco` des Besitzers), Kürbis und
  Totenkopf `has_candle = false`. Kerze in den Kürbis behält ihre Länge (`insert_candle`). `FixedCandle` genauso
  (`burn`, `renew`); leerer Teller nimmt eine Kerze aus der Hand. Startlängen zufällig in `FixedCandle.START_WAX`
  (feste Kerzen, Startdeko der Gäste). Kerzenvorrat: `ResourceSpot.refill_mornings` – kein laufender Nachwuchs, ab
  6 Uhr (erstes Bild sofort) auf ⌈bewohnte Zimmer / 2⌉ (`MonsterDirector.inhabited_rooms`), `refill_day` gespeichert.
  Gäste zünden an: `CandleCare` (s. Gäste). Debug `--abbrennen[=rest]`. Rauchtest `kerzen`, `abbrennen`.
- **Salz** (Spielkonzept 5.13; `world/salt_line.gd` `SaltLine`; `item.gd` `SALT`, `salt_left` im Zusatzfeld,
  `use_salt`; `player.gd` `salt_spot`, `strew_salt`): Linksklick mit der Packung → `SaltLine.spot_for(öffnung, von)`
  (Tür: Schwelle auf der eigenen Seite, `THRESHOLD_Z`, zu nah = `STEP_BACK`; Außenfenster mit Vorhang: in der Laibung
  auf der unteren Zarge) → `SaltLine.lay`. Das Zimmer kommt aus `room_of` (Zimmertür `room_no`, sonst `room_id` über
  `LevelBuilder.home_of` – ein Bad gehört zum Zimmer). `guarding(zimmer)` = heile Linie dafür (`intact`: keine Lücke,
  weniger als `HOLDS` Abweisungen). **Lakengeist** `_salt_repels()`: Opfer im geschützten Zimmer, er selbst nicht → `repel()`
  und `_vanish()` – am Ende von HOVER, in ENTER (Vorhang, Tür auf), in `_check_doors` und `_start_lurk`; nicht in der
  Dusche (`_scripted`). **Monster** `_check_salt`: auf eine heile Türlinie zu (`SALT_NEAR`) → `SALT_PAUSE` s stehen,
  je Linie höchstens alle `SALT_AGAIN` s. **Verwischen:** jede Linie prüft alle `CHECK_EVERY` s Spieler (nicht geduckt),
  Gäste und Monster im Band (`SMUDGE_DEPTH`). Körner als MultiMesh aus `grain_seed`, neu gebaut bei jeder Änderung.
  Gespeichert unter `salt` (Speicherstand 48), Packungen auf der Küchenzeile (`LevelBuilder.SALT_BOXES`, solange kein
  `SALT` im Plan steht). Debug `--salz[=…]`, Rauchtest `salz`.
- **Getränkedosen** (`Kind.SODA_CAN`, `drink_can`), **Kaffee** (`world/coffee_machine.gd`, Spielkonzept 3.11),
  **Tee** (`world/tea_kettle.gd`, `TeaKettle` erbt von `CoffeeMachine`, Spielkonzept 3.12): `CoffeeMachine` hat Felder
  statt fester Werte (`drink_kind`, `brew_time`, `noise_kind`, `guest_phase`, `children`, `lines`, `cup_spot`) und Haken
  (`_register`, `_build`, `_steam_spot`, `_finished`). Gäste holen sich morgens Kaffee, abends Tee (Zustand `EAT`, nie
  zu beiden zugleich – `_taken`). **Wirkung:** `Player.tiredness()` ersetzt `awake_time` in `weakness()` und
  `_update_sight` (Kaffee verdeckt Müdigkeit, danach ein Tief), `jittery()` bei viel Koffein (Hand zittert, Bluff
  verrät); `_sleep_credit(dt)` rechnet Schlaf mit Kaffee schwächer, mit Tee stärker an. Tasse zerbricht → Fleck
  „coffee“/„tea“ (gebaut wie Wachs). Gespeichert unter `player`: `coffee`, `coffee_low`, `caffeine`, `tea`. Debug
  `--kaffee=…`, `--tee=…`.
- **Bar & Rausch** (`world/bar_tap.gd`, Spielkonzept 3.7): `BarTap` mitten auf der Theke; Rausch `drunk`, Stufen
  `TIPSY`/`DRUNK`, `BarTap.sway(drunk)`. Spieler: Kopf rollt, Maus folgt verzögert (`_look_lag`), Stolpern; betrunken
  halluziniert man. Gäste trinken an der Bar. Gespeichert: `player.drunk`/`hangover`, Gast `drunk`. Debug
  `--drunk=n[,gast]`.
- **Taschenlampe** (`world/flashlight.gd`, `world/uv_mark.gd`): `Flashlight` hängt als Kind am Item, Zustand in
  `create_extra()` (`"c=0.42;uv;m=uv;on"`). Bewusst **ein `SpotLight3D` außerhalb von `light_source`** – zählt nicht
  für Helligkeit/Abschreckung und nicht als `item.lit` (sonst bläst das Monster sie aus …). Auffälligkeit über
  `flashlight.carried_conspicuity()`. UV nur in der Hand des Spielers: prüft `uv_marks` und das Monster
  (`can_be_repelled_by_uv`) → `on_monster_uv()`. `UvMark`: Leuchtschrift (`_uv_writing`) oder Kästen (Nachglanz der
  Fußspuren).
- **Kompass** (`Kind.COMPASS`): Nadel = Feder Richtung Norden (−Z), **in Teilschritten ≤ 20 ms gerechnet**
  (`Item.needle_step`, geprüft in `tests/math_checks.gd`) – die steife Feder schaukelte sich bei einem langen Frame bis
  NaN auf; gestört über `director.threat_at()` und `is_hallucinating()`.
- **Karte** (`world/hotel_map.gd`, `Kind.MAP` mit Blatt-ID): `HotelMap.PAGES` = Blätter; gedruckte Pläne aus den
  JSON-Karten (neue Zimmer erscheinen von selbst), Kellerskizze von Hand gezittert. Alle Blätter einmal in einem
  SubViewport gerendert → geteilte Textur, `HotelMap.material(id)` schneidet aus. Neue Ebene: Eintrag in `PAGES`,
  Zeichnung in `_draw()`, Blatt im Plan auslegen.
- **Kostüme** (`guests/costume.gd`, Spielkonzept 5.9): ab `FROM_DAY` fest nach `hash(id + ":kostüm")` – nichts
  gespeichert, kein Zufall aus dem Spielstand. Hut/Kürbis sind `top_level` und folgen dem Kopfknochen
  (`GuestBody.head_origin`) aufrecht, damit sie beim Tanzen nicht kippen. **Spieler im Laken** (`BED_SHEET` auf dem
  eigenen Bett): `put_on_sheet()`/`take_off_sheet()`, Overlay `shaders/sheet_overlay.gdshader`;
  `Player.recognized_by(guest)` prüfen überall, wo Gäste den Spieler erkennen (Diebstahl, Angriff, Zeugen, Rempeln …).
  Gespeichert: `player.disguised`. Debug `--costumes[=art]`, `--disguise`.
- **Verbotene Masken** (Spielkonzept 5.19; `world/mask_model.gd` `MaskModel`, `world/mask_board.gd` `MaskBoard`,
  `world/mask_hook.gd` `MaskHook`, `item.gd`
  `MASK` mit `mask_id` im Zusatzfeld; `player.gd` `mask`, `put_on_mask`, `take_off_mask`): `MaskModel.ORDER` = die acht
  in der Reihenfolge der Stifte, `SIZES` = die mit Modell (Kürbismann, Puppe). **Board (ZIM-128):**
  `LevelBuilder._mask_hooks` hängt ein `MaskBoard` (1,32 × 0,96 m, Unterkante `BOTTOM` 1,0 m) mittig an den Plan-
  punkt „Maskenboard“ oder ohne ihn an die längste freie Wand von Zimmer 13 (`_free_wall`: ohne Öffnungen, Möbel,
  Wandsachen bis 0,6 m davor; `MASK_WALL_MARGIN`, `MASK_WALL_MIN`). Das Board setzt acht `MaskHook` auf `SLOTS`
  (4 × 2, obere Reihe zuerst, von vorn gelesen von links nach rechts). Jeder Stift zeigt seine Maske, solange
  `hanging`; kein Schild – der leere Stift heißt nur „Leerer Stift“, mit einer fremden Maske in der Hand „Hier gehört
  sie nicht hin“ (welche fehlt, verrät nichts). [E] nimmt sie in die Hand, mit ihr in der Hand hängt [E] sie zurück
  (nur an den eigenen Stift). Masken mit Modell hängen von Anfang an.
  **Tragen:** Linksklick mit der Maske in der Hand, [G] mit leeren Händen nimmt sie ab (nicht zusammen mit dem Laken);
  Overlay `shaders/mask_overlay.gdshader` (`Hud.MASK_VIEWS`: Innenfarbe, Stern- oder Mandelaugen); `recognized_by`
  wie unter dem Laken. **Wirkung:** Kürbismann `PumpkinMan.threshold()` = `MASK_THRESHOLD` statt `FUN_THRESHOLD`, in
  `_pick` ist der Träger sein erstes Ziel; Puppe `MonsterDirector.mark_doll_mask(zimmer)` → `doll_mask`, das
  `_weakest_door()` vor allen anderen nimmt, bis `_end_raid` das Urteil dort vollstreckt hat. Gespeichert:
  `player.mask`, `mask_hooks` (je Masken-ID, ob sie hängt – nicht nach Reihenfolge), `director.doll_mask`. Debug
  `--maske[=id]`, Rauchtest `masken`.

### Am Körper
(`player.gd` `_pocket`, `_update_hand`, `set_pockets`; `player/pocket_map.gd`)
`Item.goes_to_pocket()` (Kompass, Kartenblatt, Schlüssel außer `HAND_ONLY_KEYS`): `try_pick_up` löscht den
Welt-Gegenstand und trägt ihn in `has_compass`/`map_pages`/`keyring` ein. Linke Hand für Karte (Tab) und Kompass (F),
nicht bei `hands_blocked()`. Türen fragen `player.has_key(id)`. Der Kompass in der linken Hand ist ein `Item` mit
`make_pocketed()` (raus aus Gruppe `items`).

### Tasche
(`player.gd` `bag`, `open_bag`/`close_bag`, `stow_held`, `take_from_bag`, `consume_kind`, `give_away`; `item.gd`
`POCKET_KINDS`, `fits_pocket`; `hud.gd`; `ui/item_icons.gd`; `shaders/bag_blur.gdshader`; `tests/bag_checks.gd`;
Spielkonzept 3.2)
- Kleines kommt bei voller Hand mit [E] gleich in die Tasche. **[Q] halten** öffnet sie, die Maus wählt
  (`_bag_cursor`), Loslassen nimmt heraus bzw. steckt ein. Die Gegenstände hängen unsichtbar unter dem Spieler, raus aus
  Gruppe `items` und Interaktion (`Item.in_bag`) – Gäste sehen und stehlen sie nicht.
- **Wer Hand-Gegenstände prüft**, fragt für Neues `player.can_take(kind)`, für Verbrauch
  `consume_kind`/`consume_item`/`give_away` – sonst übersieht er die Tasche.
- Bilder: `ItemIcons` rendert jede Art einmal in einem SubViewport, `RENDER_FRAMES` Bilder lang (beim ersten Bild sind
  die Shader oft noch nicht übersetzt), dann eingefroren. Gespeichert unter `player.bag` (ohne Lage).

### Notizbuch & Tagebuch
(`world/notebook.gd`, `world/diary.gd`, `player/notebook_page.gd`, `player/pocket_map.gd`, `menus.gd`
`_write_diary`; `tests/notebook_checks.gd`; Spielkonzept 3.10)
- **Notizbuch** `Game.notebook`: `owned` (kommt mit dem Brief), sonst wird nichts notiert. `add_task(id, text, by,
  gast, frist)`, `finish_task`/`miss_task` nur aus `OPEN`, `on_guest_died` setzt `dead`; `add_note(id, text, quelle)`.
  Jede Änderung erhöht `tasks_revision`/`notes_revision` (die Seiten werden dann neu gesetzt). Quellen: `DoorContest`,
  `NoticeBoard.pin(…, jot_id, jot)`, `WarningNote.NOTES` (`jot`/`by`), `PhoneCalls`.
- **In der Hand:** `PocketMap` hängt nach den Kartenblättern die Seiten an (`NotebookPage.paginate`); jede Seite wird
  erst beim Ansehen in einem eigenen SubViewport gerendert. Material **ungeschattet** – beleuchtet war die Schrift unter
  Filmic grau auf grau. Lesezeichen (`BOOKMARKS`), Rechtsklick springt (`next_bookmark`).
- **Gesehene Bedrohungen** (`Notebook.note_seen`, `seen`): `_check_sight` prüft die aktiven Bedrohungen mit
  `player_can_see`; Seite „threats“ mit Porträts (`NotebookPage._draw_threats`).
- **Tagebuch** `Game.diary` (= `LevelBuilder.diary`): `note(id, text)` sammelt Meilensteine in `pending` (jede id
  einmal); `Menus._write_diary` schreibt sie vor dem Speichern auf (`write_pending`), scheitert das Speichern, `unwrite`.
- Gespeichert unter `notebook` und `diary`. Debug `--notizbuch`, `--show=aufgaben|notizen|gesehen`,
  `--menu=diary_pages`.

### Hotelregister, Zimmer 18 (Dokumente)
- **Hotelregister** (`world/hotel_register.gd` `HotelRegister`, `ui/register_view.gd` `RegisterView`; Spielkonzept 2.3,
  2.9, HANDLUNG K1): festes Buch auf `LevelBuilder.register_spot` (in `_lobby_hall`: Front der Rezeption,
  `REGISTER_SHIFT` neben der Mitte, +Z zu den Gästen), `Game.register`. [E] → `Menus.open_register` (Doppelseite,
  blättern baut den Bogen neu wie das Tagebuch). `pages()`: die Jahre 1987–2025 einmal gesetzt (`_old_rows`: fester
  Seed je Jahr, Kreuze = `PhotoWall.TAKEN`, Zimmer aus `rooms` ohne 13/18, Vornamen nach `ERA_YEAR`, keine Nachnamen der
  heutigen Haushalte, `FIXED` = Edna 1987 in 017), dann Oktober 2026 frisch aus `builder.households` und
  `Game.social.guests` (Mitglied über `profile["member"]`, Name `LevelBuilder.door_name`, `BIRTH_NAMES`). Der laufende
  Oktober beginnt auf einer linken Seite. `RegisterView.paginate` verteilt Jahresblöcke auf `ROWS` Zeilen (ein Jahr
  bricht nur, wenn es allein nicht passt); Kreuze zeichnet `_draw_page` wie `NotebookPage` (Zeile `crosses` = Zeichen
  davor, drei Leerzeichen Platz). **Kreuz** (`is_crossed`): tot und `next_morning(Todeszeit)` erreicht (`CROSS_HOUR`).
  Die Todeszeit kommt über `Social.on_guest_died` → `on_guest_died` und lebt nur in der Sitzung (`_died_at`); ohne sie
  (nach dem Laden) steht das Kreuz sofort, Gustav immer ab dem 3. Oktober, 6 Uhr – **nichts davon wird gespeichert**.
  `on_pages_read` schreibt Notizen (`register_old`, `register_<Gast>`). Debug `--register[=tot][,offen|anfang]`.
- **Tischklingel** (`world/desk_bell.gd` `DeskBell`, ZIM-146, Spielkonzept 2.9): `LevelBuilder.desk_bell`, in
  `_lobby_hall` `BELL_SHIFT` auf der anderen Seite der Rezeptionsmitte (zwischen Kerze und Register), `BELL_OUT` zu den
  Gästen. Low Poly, ganz im Code gedreht (`_lathe`: Profil (Radius, Höhe) in einer Laufrichtung, Normalen weich unter
  `CREASE`, UVs in Metern, u ringsum): Fuß im Lack, Glocke als halbes Ellipsoid, innen hohl, mit Lochwand, Stift
  darunter, Drücker als eigener Knoten. Unterteilungen `SIDES`, `SMALL_SIDES`, `DOME_STEPS`, `ROUND_STEPS`,
  `KNOB_STEPS` frei änderbar; drei Meshes für alle Klingeln (`_meshes`). Texturen des Mülleimers (`TrashCan.BRASS_TEX`,
  `COAT_TEX`, `mesh_uv`), die Bürstung ringsum wirkt wie Drehriefen. [E] → Drücker per Tween `PRESS` hinunter, Lärm
  `desk_bell` (10 m, synthetischer Klang `desk_bell` in `SynthAudio`), ein Gedanke aus `THOUGHTS` nach
  `THOUGHT_PAUSE` s Spielzeit Ruhe. Nicht im Spielstand. Debug `--klingel[=nah|an]`, Rauchtest-Stichwort `klingel`.
- **Zimmer 18** (`world/caretaker_book.gd` `CaretakerBook`; Spielkonzept 7.4, HANDLUNG M8): `furnish(builder)` aus
  `main` legt die Kladde, den Schaltschlüssel (`Item.Kind.KEY` „aufzug“ = `KEY_ID`, `Item.key_label` „Schaltschlüssel“,
  Stahl statt Messing) und den UV-Aufsatz auf den ersten Tisch des Zimmers (`room_tables`, entlang
  `LevelBuilder.room_table_axes` – halbe Länge der langen Tischseite; das Telefon steht in der Mitte). Schlüssel und
  Aufsatz sind gewöhnliche Gegenstände (gespeichert in „items“). [E] → `Menus.open_pages` (`PAGES`, eine Seite je
  Bogen), `read()` trägt `TASKS` mit `TASK_BY` ein – `Notebook.add_task` übergeht vorhandene IDs, gespeichert ist es
  nur im Notizbuch. `fixed(part)` streicht einen Mangel durch – aufrufen, sobald die Reparatur gebaut ist. Debug
  `--zimmer18[=offen|gelesen]`.

### Symbole & Porträts
(`ui/icon_art.gd`, `assets/textures/icons/Icon_<name>.png`, Quelle `Icon_themonster.aseprite`)
`IconArt.texture(name, größe)`: kleiner einmal mit Lanczos verkleinert und zwischengespeichert (Nearest zerriss die
Striche). **Aktions-Symbol:** Interaktionsobjekte können `get_icon(spieler) -> String` haben – `_update_focus` fragt
es, wenn der Hinweis nicht leer ist. Meldungen mit Symbol über `Game.say(text, dauer, icon)`. Leichen bekommen einen
Kasten `CorpseTouch` (Meta interactable = Gast; der Körper selbst hat keine Kollision mehr). Sterbebildschirm mit
Porträt nach `Player.killed_by`. Debug `--tot[=geist|kuerbis]`.

### Der Anfang
(`world/door_contest.gd` `DoorContest`/`Letter`, `world/notice_board.gd` `NoticeBoard`/`Sheet`,
`LevelBuilder._lobby_hall`, `jury_doll.gd`, `guest.gd` `join_party(platz, blick)`, `player.gd` `spellbound`;
Spielkonzept 2.5)
- `Game.contest`, Abschnitte `Stage` CONTEST → GATHERING → SCENE → DONE.
- **Brief:** `Letter` neben dem Tagebuch – `_place_letter` sucht nach zwei Physikbildern einen freien Platz auf der
  Tischplatte. Lesen → `letter_read` (Tagebuchsatz, Notizbuch, erste Aufgabe).
- **Brett:** `NoticeBoard` an der Lobbywand (`NOTICE_BOARD_Z`/`_Y`), eigene Bilderleuchte in `lamps`; `pin(id, …)`
  heftet `Sheet`s an ([E] → `Menus.open_note`), `unpin(id)` nimmt eins ab. `_pin_board` wechselt nach `first_attack_done`
  den Aushang und heftet ab `DEPARTURE_HOUR` am Morgen nach der Siegerehrung die Mitteilung „abgereist“ an
  (`_departure_due`: Gustav tot oder schon freigegeben, 2.9) – abgeleitet, nicht gespeichert; `_after_step` prüft es je
  Sekunde, Laden heftet neu an bzw. ab.
- **Durchsagen:** `ANNOUNCEMENTS` (Tag, Stunde, Text, Kurzfassung) → Gong und Meldung; verpasste bis `ANNOUNCE_LATE`.
- **Siegerehrung:** `_begin_gathering` stellt die Gäste auf (`_gather_spots`, vor der Puppe bleibt ein Halbkreis frei),
  `Social` feiert an dem Abend nicht (`holds_parties`), keine Besuche (`is_gathering`). Beginn, sobald der Spieler in
  der Lobby steht und genug Gäste da sind, nie neben einer anderen Bedrohung, spätestens `CEREMONY_LATEST` ohne ihn.
- **Szene** (`T_*`): `Player.spellbound` (keine Eingabe), `_pull_gaze` zur Puppe, Puppe steigt und verpufft
  (`_puff`, `vanish`) – beim Verschwinden `MonsterDirector.first_attack_unseen` (Gustav, 2.6), im Partyraum läuft dabei
  Musik (`RecordPlayer.set_playing` ohne Feier); `_end_scene`: Licht aus, Musik aus, Gäste fliehen. Autosave nicht während der Szene. Laden mitten in der
  Versammlung: die Gäste kommen erst beim nächsten Rundgang (sonst ließen sie fallen, was sie in der Hand hielten).
- **Danach:** `_deliver_note` (Zettel „1999“ hinter der Tür von Zimmer 13, sobald der Spieler die Stelle nicht sieht),
  Gäste lesen am Brett (hängt die Mitteilung, auch `DEPARTURE_LINES`), erstes Urteil der Puppe ins Tagebuch.
- Gespeichert unter `contest`. Debug `--siegerehrung[=ohne]`, `--brett[=nachher|abgereist]`, `--brief`, `--zettel`.
- **Hilfe** (Spielmenü, `Menus._show_help`, `CONTROLS`/`BASICS`; Einträge mit „danach“ erst nach dem ersten Angriff,
  „debug“ nur mit Debug-Konsole): muss in 480 × 270 passen – neue Einträge mit `--attacks=1 --menu=help` prüfen.

### Titelbildschirm, Vorspann
(`ui/title_screen.gd`, `ui/slide_show.gd` `SlideShow`; Spielkonzept 8.2)
- **Vorspann:** `SlideShow` mit inneren Klassen `Slide` (Bild, Text, Klang, Dauer) und `Sequence`; überspringbar nach
  `skippable_after`. `SlideShow.splash()` = Logo mit `splash_wave.wav` (Platzhalter aus `tools/build_wave_sound.py`).
  `TitleScreen._ready` wartet darauf (`await finished`) – **erst danach Knöpfe mit Fokus**, sonst löste die Leertaste
  „Fortsetzen“ aus. Einmal je Programmlauf, nur ohne Debug-Parameter oder mit `--title --splash`.
- **Schrift:** `UiKit.menu_theme()` mit `UiKit.MENU_FONT` (Cinzel) für Titelbildschirm und Spielmenü.
- **Laden:** Neues Spiel, Fortsetzen und Laden (auch aus Spielmenü und Todesbildschirm) gehen über `Game.enter_game()`:
  sofort abgedunkelt mit „Lädt …“ (`CanvasLayer` am Game-Knoten, fängt Klicks ab), zwei Bilder warten, dann
  `change_scene_to_file`; weg nach dem ersten Bild der neuen Szene (`scene_changed`). Solange `Game.entering`, zählen
  weitere Aufrufe nicht (kein doppelter Start).
- **Hintergrund** `LOBBY_IMAGE` (`title_lobby.jpg`, Screenshot vom Haupteingang): `TextureRect` mit
  `TEXTURE_FILTER_LINEAR_WITH_MIPMAPS` (Standardfilter des Projekts ist Nearest), Flackern über `modulate`, Rauschen
  darüber. Neu erzeugen: Befehl im Kommentar über `LOBBY_IMAGE`. `--shot-size=BxH` macht das Fenster rahmenlos und so
  groß (Windows begrenzt Fenster mit Rahmen auf den Bildschirm).

### Spielerfigur, Spiegel, Charaktererstellung
- **Spielerfigur** (`player/player_body.gd`, Spielkonzept 3.9): `PlayerBody` baut aus `look` (`profile_of`) einen
  `GuestBody`. Netze auf Sichtebene 19 (fehlt in der Kamera), je eine `duplicate()` mit `SHADOWS_ONLY` auf Ebene 18 –
  **Godot rechnet Schatten nur für Netze, die die Kamera sieht**. Lichter des gehaltenen Gegenstands lassen Ebene 18
  aus (sonst stünde der Kopf vor der Taschenlampe). `Player.set_look`: Kapsel, Augenhöhe und Hocken = Standard ×
  Größe / 1,8 (`HEIGHT` usw. bleiben die Werte für 1,80 m; `EYE_HEIGHT` 1,62 = 90 % der Größe, Spielkonzept 3.1).
- **Spiegel** (`world/mirror.gd`, `shaders/mirror_view.gdshader`): `Mirror.make(eltern, größe, mitte, normale,
  reichweite)` – matt (`DULL`), solange nicht zu sehen (`_visible_to`). SubViewport und Kamera entstehen beim ersten
  Hinsehen: Spiegelpunkt der Spielerkamera, schiefes Frustum genau durch die Fläche (`set_frustum`), eigene Umgebung
  ohne Tonemapping, SSR und Glow. Benutzt von Aufzug und Waschbecken (`sink_mirrors`).
- **Charaktererstellung** (`ui/character_creation.gd`, `main._start_creation`): `Game.creating`, `Mirror.force`;
  `_find_mirror` sucht den Spiegel im Bad von Zimmer 13 (`home_room_at` = `PLAYER_ROOM` zuerst – das Bad nebenan liegt
  näher). Solange `Game.creating` gilt, nimmt `Player` weder Maus noch Tasten an. Neigung fest `MIRROR_PITCH`, damit
  Scheitel und Spiegelunterkante bei jeder Größe im Bild bleiben. Änderungen → `Player.set_look` höchstens alle
  `APPLY_EVERY`. Debug `--figur[=schnell]`.

### Wetter, Natur
- **Wetter** (`world/weather.gd`, Spielkonzept 7.8): `Game.weather`, `kind` CLEAR/RAIN/STORM nach Zeitplan,
  `intensity` blendet. **Regen:** `GPUParticles3D` um den Spieler; jeder Tropfen fällt bis zur obersten Fläche darunter
  – aus einer Dach-Höhenkarte (`_build_roof_rows`, auf die ersten Bilder verteilt, je Bild höchstens
  `ROOF_BUDGET_USEC` = 1,5 ms – feste Zeilenzahl kostete über dem Gebäude bis 50 ms je Bild); vorher regnet es nicht. Tropfen
  als Striche (`shaders/rain_streak.gdshader`, nie schmaler als `STREAK_PIXELS`, sonst blasser). **Gewitter:**
  Blitze über Mondlicht und Himmel `flash`, Donner, danach `masking()` – `MonsterDirector.on_noise` multipliziert die
  Lautstärke damit. **Kirchturmglocke** um Mitternacht (`_update_bell`, kein Lärm). Nicht gespeichert (außer Blutregen). Debug
  `--weather=klar|regen|gewitter|blitz|gestalt|blut`.
  Globale Shader-Werte (project.godot) aus Weather: `weather_time` (Spielzeit), `rain_wet`, `wind_strength`.
  **Scheiben:** `wet` folgt `intensity` (`WET_RATE`, trocknet in `DRY_TIME`); jedes klare Außenfenster hat vor dem Glas
  eine Fläche mit `shaders/window_rain.gdshader` (Gruppe `rain_panes`, nur sichtbar, solange nass; `render_priority` 1
  wegen des Glases). Muster in Metern auf der Scheibe, je Fenster verschoben; Brechung über `hint_screen_texture`.
  Senkrecht prägen die Rinnsale das Bild (`running_drops`, Anteil `run_share` der Spalten `run_width`): Kopf ruckweise,
  dahinter die Spur nach ihrem Alter (`fract(pos − Höhe)/speed`) – bis `film_life` ein durchgehender Faden, danach
  Perlen bis `trail_life`; wo sie ist, sind die stehenden Tropfen weggewischt (Rückgabe `w`). Spalten in der Höhe
  versetzt, sonst lägen alle Nahtstellen (`run_height`) gleich hoch.
  **Nasser Boden:** Rasen, Kies und Stein draußen (`LevelBuilder`: `_grass`, `_gravel`, `_stone`, eigene Materialien)
  meldet `Mat.wettable(mat, glanz)` an (`WET_GLOSS`; bei `psx_surface` eine Abwandlung mit `specular_schlick_ggx`,
  sonst rechnet er keinen Glanz). `shaders/wet_ground.gdshaderinc` (in `psx_surface` und `psx_photo`) liest `rain_wet`
  und `rain_blood`: dunkler, glatt mit etwas Metallic (sonst sähe SSR nichts); beim Blutregen ein Hauch roter
  Film (#880808, höchstens ~8 %), auf glattem Stein Glanz in #ff2222 (Metallic mit Glanzfarbe als Albedo, so bleibt die Grundfarbe
  etwa der Film). Gras (`grass.gdshader`) wird mit nass und rot.
  Die Fläche baut `HotelWindow.rain_drops(parent, quad, offset)` – auch für die Dachfenster (`LevelBuilder._roof_window`,
  knapp über dem Glas). Der Shader liest die Neigung aus der Modellmatrix (`steep`: lokal +Y = bergauf, senkrecht 1):
  Rinnsale laufen entlang lokal −Y, auf schrägem Glas seltener und langsamer (flach keine), dafür mehr, rundere und
  eine Lage großer stehender Tropfen. Senkrechte Fenster bleiben unverändert.
  **Wind** (`wind`, 0 … 1): Grundbrise nach `_season()`, `WIND_RAIN`/`WIND_STORM` × `intensity`, Böen. Wirkt auf Gras
  (`Grass`: Ausschlag und Takt), Baumblätter (`psx_leaves.gdshader`, Uniform `sway` nur an Bäumen), Laub
  (`LevelBuilder.leaf_emitters`: `speed_scale`, `direction`), Regenschräge, Nebel und Klang (`SynthAudio.wind`,
  `wind_gust`: Rauschen durch ein Bandfilter, dessen Mitte mit der Böe steigt). Werte mit Wirkung über die Zeit
  (Nebeldrift, Grastakt) werden aufsummiert, nie als Zeit × Wind gerechnet – sonst springen sie.
  **Nebel:** ein `FogVolume` über dem Plan mit `shaders/ground_fog.gdshader`; Dichte nur über der obersten Fläche der
  Dach-Höhenkarte des Regens (dieselbe Textur) – drinnen keine. Dichte und Schichthöhe nach `_season()`. Nur sichtbar
  bis `volumetric_fog_length`; im Blitz begrenzt `light_volumetric_fog_energy` des Monds (`FLASH_FOG`) das Aufleuchten.
  **Mond:** `moon_phase()` aus `Calendar.day_float` (`SYNODIC`, `FULL_MOON` = Mitternacht nach Halloween) → Shader
  `moon_phase` (Schattengrenze, Erdschein, Hof); Mondlicht × Phase × Bewölkung (`moonlight()`), auch in
  `MonsterDirector.light_at` (Mondlicht durch Fenster). Bewölkung bei klarem Himmel steigt bis Halloween (`CLOUDS_LATE`).
  **Gestalt im Blitz** (`world/lightning_figure.gd`, `LightningFigure`): `lightning()` ruft `place` (Chance, einmal je
  Gewitter) – Stellen neben Bäumen und im Blickfeld, draußen, freie Sicht (Ebenen 1, Vorhang, Milchglas) und kein
  Stamm in der Sichtlinie (`_behind_trunk`, der sichtbare Stamm ist dicker als die Kollision); dann zweite Zuckung
  erst nach `GONE`. `_update_flash` zeigt sie in der ersten Zuckung, danach weg. Schock `SHOCK`. Gestalt aus
  Grundkörpern. `--shot-on=figure`.
  **Blutregen** (Seltenwetter): `set_weather(kind, instant, blood)`; der Zeitplan fragt `_blood_due()` (einmal je Spiel,
  `BLOOD_FROM`…`BLOOD_SURE`, nur wenn `_player_sees_rain()`). `_blood` gilt bis zum nächsten Schauer; `_blood_amount`
  folgt ihm weich (`BLOOD_FADE`) → globale `rain_blood` (Tropfen färben das Bild, Boden rot), Himmel `blood`
  (× `intensity`: Wolken #dd7733, Horizont glimmt, Blitz #ff1111 – auch das Blitzlicht `BLOOD_FLASH`), Regenfarbe
  (`_tint_rain`, auch nach `_set_drops`). `stain` (0 … 1) steigt mit
  `wet`, normaler Regen wäscht es ab (`BLOOD_WASH`): globale `pane_stain` (eingetrocknete Flecken im Scheiben-Shader,
  die Scheiben bleiben dafür sichtbar, `panes_wet`) und rötliche Pfützen (#a80808, `Decal`, `PUDDLES` feste Stellen aus der
  Dach-Höhenkarte, nur ebener Boden draußen, erst bei Bedarf gebaut). Gäste: `_blood_reactions` (Angst, Sätze, der
  Mutigste erklärt). Gespeichert bei den Omen (`SaveManager._collect_omens`, Schlüssel „weather“: `blood_done`, `stain`).
- **Gras** (`world/grass.gd`, `shaders/grass.gdshader`): Nach
  dem NavMesh erzeugt (nicht darin, keine Kollision, nicht gespeichert), fester Zufall (`SEED`), nur wo `is_lawn` und
  frei von Bäumen, Beeten, Gegenständen. `MultiMeshInstance3D` je Kachel mit `visibility_range_end`. Wind über
  `wind_time` (steht in der Pause); `pushers` (Figuren, Gegenstände) drücken das Gras weg.
- **Fledermäuse** (`world/bats.gd`, `shaders/psx_bat.gdshader`, Spielkonzept 4.22 ohne Vampir): ein
  `MultiMeshInstance3D`, Daten in Arrays; Flügelschlag im Shader über `INSTANCE_CUSTOM` (vom Skript – steht in der
  Pause). Schlafbäume aus `LevelBuilder.tree_spots`; abends und nachts fliegen sie, nie über das Haus. Scheu vor
  Bedrohungen und lautem Lärm (`Game.noise` → `Bats.on_noise`) – flattern auf (Lärm `bats`). Nicht gespeichert. Debug
  `--fledermaus[=tag|schwarm|dachboden|biss]`.
  **Biss** (ZIM-29, Entscheidung 3.11.): in `_look_around` (nur wenn der Spieler draußen ist) nachts nach
  `MonsterDirector.first_attack_done` mit `BITE_RATE` je Sekunde `_start_bite` – die nächste `FLY` höchstens `BITE_NEAR`
  waagrecht wird `Mode.BITE` (nie mehr als eine, nicht bei offener Wunde, im Versteck oder im Schlaf), fliegt ohne
  Zittern und unter `MIN_Y` zum Hals (`BITE_NECK` unter der Kamera); ab `BITE_REACH` `_bite` → `Player.bat_bite`,
  Flügelschlag mit Untertitel, dann `_flee_from`. Nach `BITE_TIME` oder wenn der Spieler hineingeht/sich versteckt,
  dreht sie ab. `Player.bat_bite`: `bite = bite_heal` = 2–3 Spieltage (`BITE_HEAL`), Schock, Ruck, roter Blitz;
  `weakness()` + `bite_share()` × `BITE_WEAK` (0,5); `bite` sinkt mit `delta` und in `skip_time`. Gespeichert:
  `player.bite`, `bite_heal` (Version 69). Gäste beißen sie noch nicht; der Vampir ist ZIM-49.
  **Dachboden:** `LevelBuilder.attic_beams` ({pos, arms}) aus `_attic_beams`; `ATTIC_COUNT` Fledermäuse ab Index `COUNT`
  in Kolonien an zufälligen Pfosten (Gruppe `_trees.size() + k`, `_roost_center` = Balkenkreuz), hängen unter einem Arm.
  Aufgeschreckt (`_flutter`) kreisen sie in der Kammer um den Pfosten (Halbmesser nach dem kürzesten Arm, unter den
  Balken festgehalten), dann `HOME`. Nachts `OUT` (nicht gezeichnet); der Wechsel ROOST ↔ OUT nur, solange der Spieler
  nicht im Dachgeschoss ist (`_player_in_attic`, Höhe). Keine Flucht durch Wände: `_flee_from` nur für die draußen.
- **Spinnen** (`world/spiders.gd`, `shaders/psx_spider.gdshader`, Spielkonzept 4.23): `Game.spiders`, ein
  `MultiMeshInstance3D`, nur nahe beim Spieler und wo er nicht hinsieht (`_floor_spot_near`), Beine im Shader. Fliehen,
  werden zertreten; Gäste reagieren nach Mut. Lassen Spinnweben-Vorräte schneller nachwachsen (`ResourceSpot.grow`).
  **Schublade:** selten springt eine ins Gesicht (`jump_at_face`, abschütteln oder Biss = Rausch). **Arachnophobie:**
  `Settings.spider_blobs` tauscht das Mesh. Nicht gespeichert. Debug `--spinne[=gesicht|schublade]`.

### Dachgeschoss: Staub und Spuk
- **Staubnebel** (`world/attic_haze.gd`, `shaders/attic_dust.gdshader`): je Rechteck der Dachbodenfläche ein
  `FogVolume` mit gemeinsamem Nebel-Shader (Rauschen in Weltkoordinaten – die Rechtecke stoßen nahtlos), Zeit als
  Uniform aus `delta`; Staubpartikel um die Kamera nur im Dachboden. Setzt das Licht der Dachfenster nach dem Mond.
- **Spuk im Dachboden** (`world/attic_spook.gd`, Spielkonzept 4.21): Ein Blitz (`Weather._update_flash` → `on_flash`)
  dreht den Spieler in einer Kammer selten um 90° (weißer Bildblitz, Kichern), höchstens einmal je Gewitter, nie bei
  Bedrohung; bei abgeschwächtem Flackern nur das Kichern. Debug `--dachboden=blitz`. Außerdem kennt er alle Räume des
  Dachbodens (`_rooms`, `room_at`, `last_room`) und ihre Türen (`_link_rooms`, beim ersten Gebrauch) für den Notausgang
  beim Urteil (`ambush_spot`, `dust`, 4.33).

### Lakengeist
(`monster/sheet_ghost.gd`, `shaders/psx_ghost.gdshader`, Spielkonzept 4.18)
- `Game.ghost`, eigener Knoten, **kein NavMesh und keine Kollision** (schwebt durch Glas und Vorhang). Erscheint an
  dunklen Außenfenstern mit offenem Vorhang (`_window_near()`) und an Fenstertüren (Gruppe `french_doors`, `Door.room_id`,
  `Door.outward`), nicht in Gesellschaft, nicht im Katzenraum, erst nach dem ersten Angriff (4.20). `visits`
  = Stufe (gespeichert unter `ghost`; laufende Auftritte nicht).
- Zustände `APPROACH → HOVER → ENTER → STRANGLE`, dazu `LURK → FLY_IN` am Schrank, `DOOR` vor der Tür, `PATROL` in der
  Geisterstunde; Ende immer über `FADE` (Raster-Ausblenden im Shader statt Transparenz). Knochen werden pro Frame aus
  der Ruhepose gedreht (`_pose`).
- **Spieler:** `trance`, `gripped`; **Losreißen** (`_struggle`, Richtungswechsel, `Hud.set_struggle()`); solange
  `gripped`, gehen weder [E] noch die Versteck-Zeitgrenze. **Schrank:** wartet davor und rüttelt (`HideSpot.rattle()`),
  fliegt hinein (`burst_open()`, Lärm `rattle` – nicht `hide_burst`, lockt das Monster nicht). Unterm Bett verschwindet er.
- **Flur** (`_in_hall` → `LevelBuilder.in_corridor()`): wenn alle schlafen und der Spieler im Flur steht.
  **Schwäche** (`Player.weakness()`, `Guest.weakness()`) aus Müdigkeit, Rausch, Schock, Trauer, Kater – macht alles
  wahrscheinlicher. **Gäste als Opfer** (`_check_guests()`, `ghost_grab()` → `GHOSTED`); Kinder würgt er nie.
- **Vor der Tür** (Spielkonzept 5.6): aufgehängte Lakengespenster an einer Zimmertür rufen ihn (`_check_doors()`),
  er wartet lautlos, zieht den Blick des Spielers durch die Wand bzw. lässt einen Gast öffnen (`door_trance`).
- **Garantien** (`_check_guarantee_hall`, `catching_up()`) und **Geisterstunde** (`ghost_hour()` nach der
  Mitternachtsglocke: geht im Obergeschoss um, `_patrol`, `_meet_in_hour`, die ersten Begegnungen nur Warnung). Solange
  er umgeht, ist er aktiv – das Monster wartet.
- **Klang:** `_ambience` spielt `ghost_ambience.mp3`, solange er sichtbar ist (an zufälliger Stelle, pausiert mit dem
  Baum). Weiße Flocken vom Saum (`_flakes`, siehe Partikel).
- **Blickzug** (Hypnose, Würgen, vor der Tür) × `Settings.look_pull` (Einstellung „Blickzug“, 0,2 … 1).
- `first_seen`: Spielzeit der ersten Begegnung mit dem Spieler (`_start_visit`, also auch Warnung und Geisterstunde;
  `NEVER_SEEN` = noch nie, `met()`), gespeichert unter `ghost` – danach richtet sich die Dusche.
- Debug (F6, `--ghost=…`, Konsole `ghost`): `debug_summon(n)`, `debug_summon_hall()`, `--ghost=tür`,
  `--ghost=stunde[,n]`, `--shock=id,tür`; `--trace` „[Lakengeist] …“.

### Lakengeist in der Dusche
(`world/shower_scare.gd`, `ShowerScare` als `Game.shower_scare`, `shaders/shower_steam.gdshader`, Spielkonzept 4.24)
- Findet beim Start die Duschecke im Bad von Zimmer 13 (LevelBuilder, Gruppe `showers`, `home_room_at` = Zimmer 13),
  die Lampen darüber (`lamp_fixtures` im selben Raum) und das Glas des Modells (Flächen mit `Mat.glass`; deren
  Außenfläche vorn = `_door_z`). Stufen `WAITING → RUNNING → CAUGHT → CLEARING → DONE`.
- **Auslöser:** `Social.start_sleep` → `on_night_rest()`: läuft, wenn `SheetGhost.first_seen` mindestens
  `Calendar.DAY_SECONDS` zurückliegt. Schläft der Spieler, `Player.wake_up`.
- **RUNNING:** zwei `FogVolume` (Duschecke bis über das Glas, Schwade darüber und vor der Tür) mit eigenem Nebelshader
  (steigt auf, weicher Rand über `UVW`, Eigenleuchten – sonst stünde im dunklen Bad ein dunkler Block), Dampfballen
  (`CPUParticles3D`, durchsichtig, ohne Licht), Flocken wie am Geist, beschlagenes Glas (Kopie von `Mat.glass`, milchig mit
  etwas Eigenleuchten), Badlampe über `FlickerLight.hold` (langsam von „wie geschaltet“ in den Puls, ohne Birne nichts).
  Wasser: `SynthAudio.shower` (Rauschen mit Tropfenschlägen, `shower_muffle` außerhalb des Bads) über `Game.hearing` –
  **kein Lärm**; leiser Geisterklang als eigener `AudioStreamPlayer3D`, bis der Geist selbst da ist. `blocks_sleep()` →
  `HideSpot.interact` lehnt ab; `reserves(player)` → `SheetGhost._player_free` lässt ihn in Zimmer 13 nicht auf
  gewöhnlichem Weg kommen.
- **Fang** (`_check_catch`): im Bad, waagerecht höchstens `CATCH_RANGE` vor der Tür, keine Bedrohung (`other_threat_active(null)`,
  `is_signalling`, Geisterstunde). `Player.spellbound` (steht fest, keine Maus), Blick per `_pull_gaze` zum Nebel, dann zum
  Geist – mit `look_pull` 1 gerissen (`SNAP_SPEED`), darunter sanft. Nach `GHOST_DELAY` `SheetGhost.shower_visit()`:
  eigener Auftritt (`_scripted`: keine Zeugen, zählt nicht für `visits`, `_stage` = `ENTER_FROM`), `HOVER` im Nebel, dann
  mit `SHOWER_SPEED` durch die Glastür und `_grab`. Ab `gripped` ist `spellbound` aus (Losreißen braucht die
  Bewegungstasten). Speichern gesperrt (`busy()` in `SaveManager.can_save`).
- **Losgerissen:** `_struggle` → `on_escaped()`: Lampen frei, `Traces.add_shower_handprints` (außen auf der Tür, Weltlage
  wie Spuren am Boden), Wasser in `WATER_STOP`, Nebel und Glas in `CLEAR_TIME`. Erwürgt: nichts – gespeichert war `running`.
- Gespeichert unter `shower` (`waiting`/`running`/`done`; gefangen zählt als laufend). Debug `--dusche[=fang|los|nacht]`
  (`debug`, `debug_night`; `los` drückt abwechselnd links/rechts über `Input.action_press`), `--trace` „[Dusche] …“.

### Kürbismann
Verhalten siehe 5 („Der Kürbismann“). Testfigur ohne Verhalten: `PumpkinMan.spawn_in_front_of(player, anim)`
(Debug `--pumpkin[=anim]`, Gruppe `pumpkin_men`). Material `Mat.model(…, two_sided)` – die Jackenfetzen sind einseitig.

### Vorzeichen, Tiere, Erinnerungsstücke (Spielkonzept 4.25–4.31, 5.14–5.18, 6.21)
Je ein Knoten unter `main` (eingehängt in `main._ready()`, Referenz in `Game`), alle in `scripts/world/` außer
`guests/extra_child.gd`. Fast alles setzt erst nach dem ersten Angriff ein und ist reine Stimmung ohne eigene Bedrohung.
- **Tiere** `Crows`, `Rats` (+ `RatKing` im Glas, `RatKing.place`), `Moths`: je ein MultiMesh mit
  `shaders/psx_bird.gdshader` (matt), Flug/Hüpfen/Flügelschlag im Skript, in der Pause steht alles. Krähen: Scheu über
  `Senses.conspicuity`, Krächzen ist Lärm. **Ruf** `favor` (−1 Groll … +1 Gunst, `grudge()` = Groll-Anteil) sinkt bei
  Würfen/Rammen/Wurf ins Nest, steigt beim Füttern, klingt mit `FAVOR_DECAY` je Spieltag zur Mitte (auch `skip_time`).
  **Glänzendes** (`SHINY`: Münzen, Schlüssel, Messer, Kompass) draußen holen sie unbeobachtet (`_carry` je Krähe – vor dem
  Zugriff `is_instance_valid` prüfen; im Schnabel unsichtbar und eingefroren, `_drop` bei Schreck im Flug lässt es an
  der Krähe fallen). Weite Flüge (`FAR_FLIGHT`) gehen über `CRUISE_Y`. **Nest** (`_build_nest`) im Baum, der am
  geradesten vor der Gartentür von `NEST_ROOM` 042 steht (`LevelBuilder.garden_doors`), in der Stammgabel knapp unter
  dem Laub (`NEST_BELOW_CROWN`, `NEST_OUT` zur Tür hin – höher oder weiter außen verdeckt es das herabhängende Laub):
  Zweige, Messing obenauf, Aufblitzen (Billboard, additiv), `StaticBody3D` auf Ebene 1 fängt Würfe – `on_noise` erkennt
  den Aufschlag eines Spielerwurfs bis `NEST_HIT` am Nest (`_nest_hit`: ein Stück fällt, Trupp fliegt auf, Ruf −0,6).
  Inhalt `nest` als `{kind, extra}` (wie `Item.create`), von Anfang an `OLD_KEY` `zimmer_042` – passt ins Schloss der
  Tür von 042 (das Versiegeln, 6.19 (7), ist nicht gebaut). **Futtertisch** `LevelBuilder.feed_table` (`_note_gardens`:
  Tisch draußen bis `FEED_TABLE_RANGE` an einer Gartentür von Zimmer 13; ohne Tisch im Plan leer, dann gibt es kein
  Füttern). Futter = `PUMPKIN_SEEDS` (Zusatz „brot“ = Brotkrumen) auf dem Tisch; `food_time` zählt alle `LOOK_EVERY` s
  bzw. im Zeitsprung, nach `FOOD_HOURS` unbeobachtet weg (`_eat`): erste Mahlzeit des Tages +0,35, weitere +0,1; ab
  `GIFT_FAVOR` ein Geschenk (`_gift`): Schlüssel ab `KEY_FAVOR` und `KEY_DAYS` Fütterungstagen, sonst Gestohlenes, sonst
  Münzen. Gespeichert unter „omens“ „crows“ (Speicherformat 59). Ratten: Welle weg vom Monster (`WAVE_RANGE`), nur Klang.
- **Hund:** `Weather.howl(delay)`, zufällig alle `HOWL_EVERY` s Spielzeit (`_howl_timer`, im Schlaf nur weitergezählt).
- **Tiere in der Ferne** (7.8): `DistantAnimals` unter `Weather` (`Weather.animals`), nur Klang (`SynthAudio`: `owl`,
  `owl_kewick`, `caw`, `bark`, `bark_deep`), draußen `*_VOLUME`, drinnen × `Weather.BELL_INSIDE`, im Schlaf nichts.
  Je Tier ein Zeitgeber (`*_EVERY`, Gruppe `time_skip`: im Schlaf nur weitergezählt); beim Ablauf entscheiden Uhrzeit
  (Kauz `OWL_HOURS`, Krähen `CROW_ACTIVITY` je Tagesphase, Hunde nachts `BARK_NIGHT`) und Wetter (`RAIN_QUIET`,
  `RAIN_DAMP`), ob gerufen wird. `on_thunder(loud)` aus `Weather._thunder`: Hunde schlagen an, Krähen fliegen auf.
  Debug `--tiere[=eule|kraehen|hunde]`.
- **`BoilerCat`** (Modell `cat.glb` fast schwarz, leuchtende Augen) führt zu Kessel bzw. UV-Schrift, einmal je Nacht.
- **`MirrorOmens`:** verhängte Spiegel aus den Toten abgeleitet (`Mirror.active`), Spiegel in 13 selbst verhängbar;
  Zimmer eines Spiegels über `_home_of` (1 m unter der Mitte abgefragt – `LevelBuilder._level_of` kennt nur 1,5 m);
  Gestalt im Spiegel auf `PlayerBody.LAYER` (nur im Spiegel sichtbar), `FIGURE_TIME`.
- **`PowerCut`:** `FlickerLight.brownout` → `FlickerLight.power_off`, Sicherungskasten `FuseBox` im Untergeschoss,
  sonst nach `RESTORE` Stunden. Höchstens einmal je Spieltag, nur mit Gewitter.
- **`Nightmare`:** einmal ab `FROM_DAY` im eigenen Bett; Post-Shader-Modus `dream`, während des Traums
  `MonsterDirector.other_threat_active`, kein Zeitsprung, `SaveManager.can_save` gesperrt.
- **`Scarecrow`:** Lage aus dem Kalender (`FAR` → Lobby-Gartentür), springt nur ungesehen. Grundkörper.
- **`ExtraChild`:** beim Süßes oder Saures an 13, höchstens einmal je Spieltag, `MAX_VISITS`.
- **`PhotoWall`** (Fotos als `Image` im Code, je Jahr fester Zufall, mit Mipmaps). Ort (ZIM-133): `setup(builder)` holt
  die Punkte „Fotowand“ aus `LevelBuilder.planned` (je Punkt eine Position, Wandfläche und Blick aus `_plan_wall`),
  sortiert sie von links nach rechts (Blick zur Wand) und hängt `YEARS` spaltenweise, oben das ältere Jahr; Oberkanten
  `TOPS`, Rahmen `GAP` vor der Wand. Ohne Planeintrag 7 Positionen an `WALL`, bei anderer Zahl eine Warnung. `MISSING`
  (2005) wird `BarePatch`: `Decal` (weißer Fleck mit weichem Rand 512×384, Mipmaps, `BRIGHTER` – geringe Deckkraft, die
  Mischung ist linear), schräger Nagel, nur Hinweis ohne [E]. `PhotoFrame` (ZIM-134): Leiste
  aus `PROFILE` (u quer, z aus der Wand) ringsum auf Gehrung gezogen, ein Mesh für alle Rahmen, UVs in Metern längs
  jeder Leiste für `Mat.hotel_wood`; Knicke unter `CREASE_DEG` rund schattiert. Glas (`glass_material(cracked)`) als
  `StandardMaterial3D` mit Alpha und Rauheit aus einem beim ersten Bau gerechneten Bild (256², mit Sprung 512²), kein
  Schattenwurf. Plakette `YearPlaque` auf der flachen Bahn der unteren Leiste (siehe `year_plaque*.png`),
  `PLAQUE_RANGE`. **`DollHouse`**
  (Pläne über `HotelMap`, Figuren je Gast, Urteil aus `JuryDoll.verdict`), **`PumpkinFaces`** (tauscht nur das Netz,
  `PumpkinModel.mesh_of`; `Item.face` bleibt).
- **Neue Gegenstände** (hinten an `Item.Kind`): `MUSIC_BOX` (`MusicBox.build`/`MusicBox.wind`: Lärm alle `NOISE_EVERY`
  s, nahes Monster horcht über `Monster.listen_to`, einmal je Aktivphase) und `APPLE` aus **`AppleTub`**
  (`Player.stand_at`, `BITE_TIME`, `BREATH`, Lärm „apple_tub“).
- `PUMPKIN_SEEDS` (Kürbiskerne, 5.4): Schnitzt der Spieler (`Item.interact` → `carve`), legt `_drop_seeds` eine Handvoll
  neben den Kürbis, auf seine Seite – Gäste schnitzen ohne Kerne. Tasche; Krähenfutter (4.25). Mit Zusatz „brot“
  (`flavor`) sind es Brotkrumen – Vorrat `ResourceSpot` mit `with_extra("brot")` auf der Küchenzeile (`BREAD_OFFSET`).
- **Ort aus dem Plan** (ZIM-158): Puppenhaus, Apfelbottich, Sicherungskasten, Krähennest über
  `LevelBuilder.planned_at`, sonst feste Ausweichplätze (`FALLBACK`/`SPOT`) im jeweiligen Skript. Ohne Planfarbe
  noch Rattenkönig (ruht). Die Fotowand liest alle ihre Punkte (`PhotoWall.setup`, ZIM-133).
- **Gespeichert** (Speicherstand 49) unter `omens`: `crows`, `mirrors`, `power`, `nightmare`, `extra_child`
  (`SaveManager._collect_omens`/`_apply_omens`); alles andere wird aus Toten, Kalender oder Gegenständen abgeleitet.
- Debug: `--kraehen`, `--ratten`, `--hund`, `--kesselkatze`, `--spiegel`, `--strom`, `--albtraum`,
  `--vogelscheuche`, `--kind-zu-viel`, `--fotos`, `--gedenken`, `--puppenhaus`, `--fratzen`, `--apfel`, `--spieluhr`;
  Rauchtest-Stichwort `halloween`.

### Der Name Leviathan (Spielkonzept 4.32)
- **`LeviathanName`** (`scripts/guests/leviathan_name.gd`, `Game.leviathan_name`, `setup(builder)`), Stufen `NONE →
  SEEN → GATHERING → SCENE → NAMED`. **Sichtung:** `Guest._watch_monster` (Sichtlinie) und `Guest.scared_by_monster`
  melden `on_sighting` (nur Erwachsene, nicht im Zeitsprung); bestätigt, wenn der Zeuge `CONFIRM_AFTER` s später
  noch lebt (`witness`, `seen_at`).
- **Szene:** ab `EVENING` (nach `LATEST` erst am nächsten Abend) und nur in Ruhe (`_quiet`: kein Monster, keine andere
  Bedrohung, kein Schlaf, keine Feier, keine Siegerehrung). Benenner `_namer_guest`: Haushalt `H27` (Hugo), sonst
  `H26` (Liesel); beide tot → benannt ohne Szene. `_gather`: Benenner, Zeuge, `pals_of(Benenner)`, ein Skeptiker
  (`Talk.temper`), höchstens `MAX_GATHER`, Plätze im Kreis um `LevelBuilder.lobby_table` (Mitte der Couchtischplatte),
  `Guest.join_party(platz, tisch)`. Ist Hugo am Platz, liegt der Druck (`PrintSheet`) auf dem Tisch; Sätze
  (`SCENE_HUGO`/`SCENE_LIESEL`, fehlender Sprecher entfällt) beginnen, wenn der Spieler 3 s in der Lobby ist, nach
  `WAIT_PLAYER` bzw. spätestens `GATHER_MAX`. Sätze mit dem Namen → `Social.on_monster_talk` (4.7). Danach `knowers`,
  der Druck hängt an `PRINT_AT` (Westwand der Lobby, zwischen Aushangbrett und Wandlampe), `leave_party` nach `LINGER`.
- **Verbreitung:** `_spread` alle `TELL_SCAN` s – zwei freie Freunde (`are_pals`) in `TELL_RANGE`, Chance
  `max(TELL_CHANCE, gossip)`; nach `ALL_KNOW_AFTER` kennen ihn alle (`knows`).
- **Sätze:** `Guest.line` → `speak`: Wer den Namen kennt (keine Kinder), sagt statt des Satzes den aus `RENAMED`
  (Satz → Satz, wörtlich; neue Monster-Sätze mit „es“ dort nachtragen – `tests/run.tscn` `leviathan_checks` prüft,
  dass jeder Schlüssel bei den Gästen steht), bei „monster“ mit `OWN_LINE_CHANCE` einen aus `OWN_LINES`. `name_for`
  macht aus „das Monster“ „den Leviathan“: Gerüchte (`Talk._pass_on`), Erzähl- und Lügenknöpfe des Spielers
  (`Talk.tell_label`, `DialogUI._show_lie`); Zettel `Social.SIGHT_NOTES_NAMED`.
- **Spieler:** `learn()` – in der Lobby bei der Szene, ein Satz mit dem Namen in `HEAR_RANGE` (`_heard`) oder den Druck
  ansehen (`Menus.open_photo`): Notiz `leviathan`, Tagebuch-Meilenstein `leviathan`.
- **Gespeichert** (Speicherstand 54) unter `leviathan`: Stufe (Versammlung/Szene als `SEEN` – beginnt neu), Zeuge,
  Zeiten, Benenner, `knowers`, `player_knows`. Unbestätigte Sichtungen nicht. Debug `--leviathan[=benannt|liesel]`,
  Rauchtest-Stichwort `leviathan`.

### Friedhof (Spielkonzept 5.15)
- **Plan:** `Möbel: Grab` (2 × 1 m, hellere Zeile `… Vorderseite` = Fußende, gegenüber das Kopfende mit dem Kreuz),
  `Möbel: Gedenkstätte` (mit Vorderseite) und die Fläche `Heckenbogen` (Lücke in der `Terrassenkante`). Grab und
  Gedenkstätte sind im **Grundriss** gemalt: `build_map.lift_furniture` hebt Möbelfarben aus dem Grundriss in die
  Objektebene und füllt den Boden darunter mit der umgebenden Fläche. Ausgabe `hedge_arches` (je ein Rechteck).
- **LevelBuilder:** `grave_slots` ({pos, head}) und `memorial_spot` ({pos, front, size}) statt Möbeln;
  `_hedge_arch` (zwei Pfosten aus `_hedge` mittig auf den Heckenenden, `ARCH_POST_H`, Halbbogen `ARCH_RISE` ohne
  Kollision), Rasen darunter.
- **`Cemetery`** (`scripts/world/cemetery.gd`, `Game.cemetery`, nach dem Bau mit `setup`): `on_guest_died` (aus
  `Social.on_guest_died`) → Leichen in `pending` (ID → Todeszeit), sonst auf die Tafel (`_refresh_missing`: tot, keine
  Leiche, nicht `buried`). Platz `_free_slot` fest je Gast (`hash(id)`). **Selbst beerdigen:** `Guest.get_prompt`/
  `interact` an der Leiche → `bury_by_player`: `threat()` (Monster aktiv, Kürbismann im Haus oder angekündigt,
  Albtraum – der Lakengeist hält nicht auf), `Player.spellbound`, `Hud.fade_black`, `_bury` (`Guest.bury`: unsichtbar,
  raus aus `shock_sights`, `CorpseTouch` weg), Zeitsprung `BURY_TIME` in `BURY_STEP`-Schritten über
  `MonsterDirector.skip` und Gruppe `time_skip` (bricht bei `threat()` ab, das Grab bleibt), Spieler ans Fußende,
  `_gather` (Trauernde sofort dort), Glocke `bell`, `_thank` (`GAIN_BURY`, je Toter und Gast einmal über Meta).
  **Sonst** `_update_funeral`: `funeral_time` = erste 10 Uhr ≥ `MIN_LIE` nach dem Tod, ab 9:30 begraben und Glocke,
  Trauernde gehen hin, ab 10 Uhr zählt der Spieler in `ATTEND_RANGE` als dabei (`GAIN_ATTEND`).
- **Trauernde:** `mourners_of` – Haushalt, Eltern/Kinder, dann `GuestPals.are_pals`, höchstens `MAX_MOURNERS`;
  `Guest.join_party(spot, grab)` (Angst vorher auf 50 gedeckelt), Ende nach `MOURN_TIME` mit `leave_party`.
- **Bild:** Erdhügel, Kreuz, Grablicht (eigene `FlickerLight`, geht nie aus), Blumen nach `FLOWERS_AFTER` ungesehen;
  `GraveTouch`/`TabletTouch`/`ShovelTouch` (Ebene 4) für Hinweis und Gedenken (`remember`, einmal je Spieltag
  `COMFORT`). Tafel als ungeschattetes `Label3D`, Kerzen je Vermisstem davor. Schaufel am ersten freien Platz.
- **Gespeichert** (Speicherstand 50): `cemetery` (`graves`, `pending`), je Gast `buried` (`Guest.die("buried")` beim
  Laden). Trauernde und laufende Feier nicht. Debug `--beerdigen[=gast|jetzt]`, `--trauerfeier`.

### Partikel
(`shaders/psx_particle.gdshader`, `Mat.particle`, `Geo.particles`; Spielkonzept 7.6)
Alles `CPUParticles3D` in Weltkoordinaten (`local_coords` aus), `QuadMesh`, keine Schatten. Der Shader macht das
Billboard selbst und liest je Partikel `INSTANCE_CUSTOM.x` (Zufallswert) und `.y` (Anteil der Lebenszeit) – darüber
laufen Schaukeln, Drehen und Farbton, **so steht alles in der Pause**. `frames` = Bilder nebeneinander, `rainbow`,
`brighten`, `glow`; `floor_y`: darunter liegt ein Partikel flach (CPUParticles kennen keine Kollision). Beispiele:
Noten am Plattenspieler, Flocken des Lakengeists, Asche des Monsters (eigener Knoten neben ihm – die Spur bleibt, wenn
es verschwindet), Herbstlaub je Baum (unter `world`, nicht `root` – das NavMesh liest dort; `preprocess`).
**Neuer Partikeleffekt:** `Mat.particle` + `Geo.particles`, Bewegung am Emitter setzen.

### Spuren, Zettel
- **Spuren** (`traces.gd`, `trace_mark.gd`): zentrale Stelle für alle Spuren; jede neue Spur → `Social.note_trace`.
  Fußabdrücke verblassen, Marken bleiben. **Blut an Wänden** (`add_wall_blood(pos, kind)`: `wall_splatter`,
  `wall_smear`) sucht die nächste Wand in Spurhöhe; Schreck-Anblick wie Blutlachen. **Schleifspur**
  (`add_drag_trail(punkte)`, Spielkonzept 2.6): Stücke `drag` bzw. am Ende `drag_end` (je `DRAG_LENGTH`, lokale Z in
  Zugrichtung, `_spread_drag` legt gestreckte Blutflecken), ebenfalls Schreck-Anblick. Die Aschespur des Monsters ist nur
  Optik, keine Spur – Gäste erzählen nicht davon. Flecken am Boden siehe 3 „Spuren auf dem Boden“. Debug
  `--wallblood[=smear]`.
- **Zettel** (`warning_note.gd`): feste Warnungszettel (`warning_notes`, erst nach dem ersten Angriff sichtbar) und
  Gäste-Zettel (`guest_notes`, begrenzt); der Zettel „1999“ steht nicht im Plan, `DoorContest` legt ihn.

### Telefone, Spieltische
- **Telefone** (`world/hotel_phone.gd`, `guests/phone_calls.gd`, `ui/phone_ui.gd`): `HotelPhone` auf jedem Zimmertisch
  + Haupttelefon an der Rezeption (`"0"`); gespeichert nur `off_hook`. Modell aus `tools/build_old_phone.py` (Sketchfab,
  schwarz mit Messing-Wählscheibe, `Mat.pbr_model`): Teile `body`, `handset`, `cable` (Schnur in Schlaufen) und die
  Leerknoten `cable_body`/`cable_handset` an den Tüllen. Liegt der Hörer daneben, ist die Modellschnur aus und
  `_cord_mesh` legt eine Bézier-Schnur zwischen die Tüllen (UV ein Gummi-Texel der Modellschnur); die Rundung des groben
  Hörers steckt in der Normal Map. `PhoneCalls` (`Game.phones`): eingehend nur für
  Zimmer 13, ausgehend per Wählseite. Jedes Klingeln = `Game.noise("phone", …)`. Telefonsätze in `PhoneCalls.LINES`,
  eigene als `"phone_<key>"` nur in den festen Profilen – **nicht** in `GuestGenerator.COMMON` (verschiebt die
  Zufallsfolge). Laufende Anrufe nicht gespeichert.
  **Gäste rufen sich an** (`_update_ambient` → `_pick_guest_call`, je Anruf ein `_ambient`): Anrufer ist ein
  Erwachsener daheim (`_at_home` = `home_room_at`), wach und frei; angerufen wird ein Freund (`pals_of`) in einem
  anderen Zimmer, lieber einer, der abnimmt (`_answers`). Jedes Klingeln im Zielzimmer ist Lärm (`_ring`); ab
  `GUEST_ANSWER_RINGS` nimmt er ab, beide stehen `GUEST_CALL_TIME` am Hörer, `Talk.phone_spread` gibt eine Geschichte
  weiter wie `_update_spread` (`_try_pass`), nur ohne `TELL_RANGE`. **Panik:** `_panicky` (Angst ≥ `PANIC_FROM`,
  Mut < `PANIC_BRAVE`) ruft zuerst und auch in der Nachtruhe, Pause `PANIC_COOLDOWN`, zur Not den nächsten Nachbarn,
  der abnimmt; Angst steckt an (`PANIC_FEAR`), der Anrufer wird ruhiger. Eingehend für Zimmer 13 Art `"panic"`
  (beruhigen: Angst −25, `Talk.friendly` 1,5, nicht nach selbst geschürter Angst; Plaudern am Telefon ebenfalls über
  `Talk.friendly`, Gespräche zählen zur Gesprächsbereitschaft, 6.18, 5). Debug `--gastanruf`, `--call=id,panik`. Telefonzentrale fehlt (4.14).
- **Spieltische** (`minigames/`): `TableMatch` (CanvasLayer 15) = Basis von `DiceMatch`, `ChessMatch`, `DartMatch` und `BowlingMatch`
  (Hooks `_table`, `_gear`, `_on_seated`, `_update_game`, `_stop`, `_take_places`/`_leave_places` – Standard: hinsetzen,
  Maus frei); Einsätze über `TableStakes`. Ob gerade eins läuft: `Game.table_game_active()` (Autosave, Herausforderungen,
  Kürbismann). **Mäxchen:** `Maexchen` = Regeln, `DiceMatch` = Partie & Gast-KI, `GameTable` = Tisch. **Schach:**
  `Chess` = Regeln als reine Daten, `ChessAI` = Alpha-Beta in einem `Thread` (`think`/`is_done`/`take_move`,
  **`cancel`** beim Abbruch, vor neuer Suche und in `ChessMatch._exit_tree`); Stärke aus `profile["chess"]`.
- **Darts** (Spielkonzept 6.10): `Darts` = Regeln als Rechnung (Turniermaße, `score_at`, `aim_point`, `target_for` –
  Zielfeld des Gastes für seinen Rest, `apply` – 301 mit einfachem Aus, Überwerfen setzt auf den Stand vor der
  Aufnahme zurück). `DartBoard` erbt von `GameTable`: Scheibe (`shaders/dartboard.gdshader` auf einem Quad – Felder,
  Sisalrauschen, Einstiche, Drähte höchstens pixelbreit), Zahlen als `TextMesh`, schwarzer Ring, Messinglinie `OCHE`
  vor der Vorderseite, Stehtisch (`top_center`/`stake_spot` dort, Pfeile `Item.Kind.DARTS` liegen darauf);
  `player_seat`/`guest_seat` sind Stehplätze an der Linie. Ursprung am Wandfuß, lokal +Z in den Raum. `throw_dart`
  fliegt per Tween, steckt (Scheibe, Ring) oder fällt von der Wand, Lärm `dart`/`dart_wall`; `guest_throw` mit
  `Guest.throw_dart_pose` und Loslassen nach `RELEASE`; `clear_darts` nach jeder Aufnahme. `DartModel` = Pfeil aus
  Grundkörpern (Spitze am Ursprung, entlang +Z). **Ort:** Ausstattung „Dartscheibe“ im Plan (Wandseite), sonst
  `LevelBuilder.DART_FALLBACK` (hinten in der Nische an der Südwand der Bar neben der Bowlingbahn); ohne „Gegenstand: Dartpfeile“ im Plan liegen sie auf dem Stehtisch.
  **`DartMatch`:** Spieler mit `Player.stand_at` (setzt `in_dialog` und `at_oche`; `_aim_input` dreht nur den Blick,
  feiner je enger, `fov_zoom` verengt ihn), Maus bleibt gefangen, Knöpfe über die Zahlentasten. Zielen in `_aim`:
  Schwanken als Summe von Sinuswellen (`SWAY` × Schwäche × Rausch, beim Halten bis `STEADY_MIN`, ab `TIRE_AFTER`
  mehr), Zittern bei `jittery()`/Schock, als Differenz auf Gier und Neigung gelegt; Loslassen streut den Strahl aus der
  Bildmitte (`SPREAD`, hastig `QUICK_FACTOR`, Mausgeschwindigkeit) und trifft die Ebene der Scheibe
  (`ray_to_board`). Gast: Streuung `sigma_of` aus `profile["darts"]["skill"]` (+ Angst, Rausch). Ablauf über `_after`
  (Pausen), `_landed` zählt. Schummeln = `throw_spot(true)`, nach der Aufnahme `_noticed_cheat` mit
  `dice.perception`; ≥ 3 nüchtern neben die Scheibe = absichtlich verloren. Ohne Gast `practice()` (endlos, bricht bei
  Vorwarnung ab). Sätze `darts_*` aus dem Profil, sonst `DartMatch.LINES`; Kinder spielen nicht. Gäste untereinander:
  `Social._update_dart_game` (`_seat_pair(…, stand = true)`, `Guest.stand_for_game`), Zuschauen → `darts_watched`
  (gespeichert). Debug `--darts[=gast]`, Test `darts_checks`, Rauchtest `darts`.
- **Barspiele** (Spielkonzept 6.10, 28.10.): `BarMatch` erbt von `TableMatch` – Fenster wie Mäxchen mit Platz für ein
  Spielbild (`_view_box`), `why_not` (Spielgerät, Kinder bei `adults_only`, Angst/Lärm), `start`, `_finish(result,
  close)` (Beziehung, Einsätze, `add_deed`, `requests.on_game_played`), `_caught_cheating`. Lust/Können/Stolz:
  `profile_of` nimmt `profile[id]`, sonst fest aus `hash(guest.id + ":" + id)` (keine neuen Zufallsaufrufe in
  `GuestGenerator.make()`; Armdrücken mischt `profile.build` ein). Sätze `<id>_yes/no/win/lose` aus dem Profil, sonst
  `BarMatch.LINES`. `player_shake`/`guest_shake` = Zittern aus Schwäche, Kaffee, Angst, Rausch. Spiele (alle am
  **zweiten Würfeltisch im Plan**, `LevelBuilder.bar_table`, ohne ihn am ersten – der erste mit dem Becher bleibt
  Mäxchen): `SchockenMatch` (Regeln `Schocken`: `score` = Klasse × 1000 + Feinwert, `deckel`, `beats` mit Wurfzahl;
  Würfelbecher, `DiceView` zeichnet jetzt beliebig viele Würfel), `ArmWrestleMatch` (Taste 1 drückt, Gast mit
  `GUEST_FORCE` je s), `CoasterTowerMatch` und `DrinkDuelMatch` (Wackelnadel `BarGauge`; Trinkduell ruft echte
  `Player.drink`/`Guest.drink`), `SeventeenFourMatch` (Skatblatt, `hand_value`), `PubQuizMatch` (`TRIVIA` + Fragen aus
  den lebenden Gästen: Zimmer, `likes`, Anzahl), `TruthDareMatch` (ohne Einsatz, `report_line`, Lärm `singing`).
  `Game.bar_games` (id → Spiel), in `table_game_active`. Dialog: „Ein Barspiel spielen …“ nur in der Fläche `bar`.
  Noch nicht: Gäste untereinander, Herausforderungen, Zuschauen. **Spielgerät:** `Item.Kind.BAR_GAME` mit Sorte in
  `flavor` (`Item.BAR_GAMES`: karten, deckel, quiz, flasche – die Flasche passt nicht in die Tasche). **Spieleschrank**
  `GameCabinet` (Gruppe `chests`, gespeichert wie eine Truhe; `holds` für `Social.is_in_closed_chest`) mit den vier
  Spielen und einem zweiten Würfelbecher (`CONTENTS`). **Spielautomat** `SlotMachine` (Walzen als `Label3D`, Gewichte
  in `SYMBOLS`, `payout`; Erwartungswert ≈ 0,69 je Geld; läuft alle 4–10 min von selbst an, wenn niemand davorsteht –
  Gruppe `time_skip`; Lärm `slot`/`slot_win`). Spieleschrank aus dem Plan (Möbel „Spieleschrank“,
  ohne Vorderseite: `_back_to_wall` stellt ihn mit dem Rücken an die nächste Wand), sonst `CABINET_FALLBACK`; der
  Jackpot-Automat ebenso aus „Spielautomat“, sonst an `SLOT_FALLBACK` (Ecke oben rechts in der Bar). **Videoautomaten** `ArcadeMachine` (Möbel
  „Videoautomat“, der Reihe nach `ARCADE_GAMES`: Deadra, Ghost Hotel – eigene Entwürfe statt Tetris und Pac-Man):
  Gehäuse = `arcade_machine.glb` (Tabelle in 1), Bildschirm = kleines `Image` (`SCREEN_PX`) auf der gewölbten
  Röhre des Modells (`shaders/arcade_screen.gdshader`: Bild in `PICTURE_RECT` der UVs, Zeilen, außen schwarzes Glas),
  alle `TICK` s neu gemalt, nur in `AWAKE_RANGE` um den Spieler. Drei Modi (`Mode`): `ATTRACT` – Vorführung
  (Fünferformen fallen ins Feld 12 × 18; das Männchen läuft die äußere Flurrunde, Gespenster hinterher, rot nach
  einer Laterne) im Wechsel mit der Bestenliste (`_list_draw`, Schrift 3 × 5 `FONT`); `PLAY` – für `PRICE` Geld
  (Spielkonzept 6.10, ZIM-72) steht der Spieler davor (`Player.stand_at`, also `at_oche` und `focused`: Maus schaut,
  Vorwarnungen halb), `_process` liest die Bewegungstasten selbst (`_press` mit Wiederholung), `_input` fängt [Esc] vor
  dem Pausenmenü ab; Bild nur bei Änderung neu (`_dirty`). Deadra: gedrehte Kästchen in `_cells` (`_turned`, seitlich
  ausweichen beim Drehen), `_deadra_lock` zählt Reihen, Stufe alle `LINES_PER_LEVEL`. Ghost Hotel: Männchen Feld für
  Feld (`MAN_STEP`), drei Gespenster mit eigener Uhr (`_ghost_move`: an Kreuzungen neu wählen, nie umkehren; jagen
  direkt, vier Felder voraus, irrt öfter; rot = zufällig fliehen; Augen heim nach `HOME`), Treffer in `_hotel_caught`.
  Spielende (auch [Esc], Vorwarnung `_danger`, Spieler weg) → `_game_over`: Bestenliste, Lärm `arcade_over`,
  `leave_oche`. `GUEST` – ein freier Gast (`likes`: Kinder, sonst fest aus der ID jeder dritte; IDLE, Angst < 40, nicht
  eingeladen) stellt sich davor (`Guest.stand_for_game`, State `MINIGAME`), alle `GUEST_CHECK` s mit `GUEST_CHANCE`,
  wenn es ruhig ist; nach `GUEST_LENGTH` trägt er sich mit Punkten nach `skill_of` (fest aus der ID, kein
  Zufallsaufruf im `GuestGenerator`) ein. `_overtaken`: stolze Zuschauer (`profile.dice.pride` > 0,6) −3, andere +3.
  Lärm `arcade` alle `NOISE_EVERY` s (7 m), `arcade_coin`, `arcade_over` (10 m), Klänge in `SynthAudio` („arcade“,
  „arcade_over“). Gespeichert: Gruppe `arcades` (`save_state`: Einträge [Kürzel, Punkte, wer]). Debug
  `--automaten[=seite|deadra|hotel|gast[,id]]`, mit `--autoplay` spielt er selbst (Deadra sucht Drehung und Spalte,
  `_bot_best`), Rauchtest-Stichwort `automaten`. **Bowlingbahn:** Flächen „Bowlingbahn“/„Foullinie“ im Grundriss
  (`bowling_lane`/`foul_line`, die Linie darf schmal sein – `THIN_FILLS` in `build_map.py`), Boden `_lane_floor`
  (Dielenfoto heller und glatter, `LANE_*`). `BowlingLane` (Weltkoordinaten, Bahn nach −z): zehn `RigidBody3D`-Kegel
  (Drehkörper aus `PROFILE`, Kollision = konvexe Hülle desselben Umrisses, `_pin_hull` – als Zylinder in Bauchbreite
  standen sie doppelt so breit und fielen kaum; `continuous_cd`), eingefroren, bis eine Kugel rollt (`roll`);
  `settled` meldet, wenn Kugel durch und alles `QUIET_TIME` ruhig ist (spätestens `MAX_ROLL`), `down` zählt
  Umgefallene/Verrutschte, `sweep` räumt sie nach dem ersten Wurf weg (unsichtbar, ohne Kollision), `reset` stellt
  alle auf. Ständer mit `BALL_COLORS`-Kugeln ist das Interactable. `BowlingMatch` (`TableMatch` ohne Tisch und Gast,
  `Game.bowling`, eigenes `_end`): `Player.stand_at` mittig in den Anlauf (`STAND` hinter der Foullinie), Kugel aus
  dem Ständer vor der Kamera; Zielen wie `DartMatch` (Schwanken, Halten, Streuung) auf die Gierung, A/D versetzt um
  `SIDESTEP`, Marke auf der Bahn bei `ARROWS`; Stärke `SPEED` ± `SPEED_JITTER`, kein Effet. Beim Rollen eigene
  `Camera3D` (Werte der Spielerkamera) hinter der Kugel (`FOLLOW`), bleibt `FOLLOW_STOP` vor dem Bahnende stehen;
  [E]/Linksklick oder Vorwarnung → `Player.camera.make_current()`. Ein Frame, dann „Weiter“/„Aufhören“; beim ersten
  Aufhören `STEAL_LINE`. Debug `--bowling` (mit `--autoplay` in die Tasche, Frame um Frame), Rauchtest `bowling`. Debug `--bargame=spiel[,gast]`, `--spieleschrank`, Test `bar_games_checks`,
  Rauchtest `barspiele`.

### UI
(`ui/`) `UiKit` = Meldezettel-Optik und schlichte Bausteine (`dark_panel`, `option_grid`, `flat_option`,
`press_number`, `plain_label`); `Hud` Prompt/Meldungen/Debug (F3), Bilder pro Sekunde (F10/`--fps`); `Menus`
pausiert. `TeleportUI` = Debug-Menü (F6): Orte und – nur mit `DebugConsole.enabled()` – alle `DebugConsole.COMMANDS`
nach `GROUPS`; Ziele aus dem `LevelBuilder`, `_onto_navmesh` rückt auf begehbaren Boden. `DebugConsole` ([^]/F1, nur
Debug-Build oder `--debug`) = Startparameter im Spiel tippen: `submit()` → `main.run_debug("--name=wert")`. Gäste
gehen als ID oder Name: Bei Befehlen in `GUEST_FIRST` (erster Wert) bzw. `GUEST_ANY` (jeder Wert) setzt `_guest_ids`
vorher die IDs ein (`Social.find_guest`), `main.gd` sucht ebenfalls mit `find_guest`. „alle“ statt eines Gastes:
`GUEST_ALL` (Befehl → Stelle des Gastes); `main._debug_all` fängt das vor allen anderen Zweigen ab und ruft `run_debug`
je lebendem Gast auf, `kill` direkt über `_debug_kill(…, quiet)` – `Social.on_guest_died(…, quiet)` ohne Meldung und
Glocke, dafür eine Sammelmeldung.

### Tastenbelegung (`util/keys.gd`, `Keys`, Spielkonzept 8.4)
- **Standard** legt `Game._setup_input` in der InputMap an (physische Tasten, also unabhängig vom Tastaturlayout),
  danach `Keys.apply_saved(Settings.key_bindings)`: merkt beim ersten Mal den Standard und setzt die Abweichungen aus
  dem Profil (`settings.cfg`, Schlüssel `key_bindings`: Aktion → Liste „key:<physischer Code>“ bzw. „mouse:<Taste>“).
  Nichts davon steht im Spielstand. Ungültiges oder Gesperrtes aus der Datei wird übergangen.
- **Umbelegbar** sind nur `Keys.ACTIONS` (Laufen, Rennen, Springen, Ducken, Interagieren, Ablegen/Werfen, Tasche,
  Notizbuch, Kompass, Benutzen, Licht/UV, Luft anhalten), je zwei Plätze (`SLOTS`). Fest bleiben Esc (`pause`),
  `bag_1`–`bag_6`, das Mausrad (Tasche, Notizbuch, Schlafdauer), alle `debug_*` und die Tasten in Fenstern
  (Telefon, Gespräch, Diashow, Brettspiele). `Keys.allowed` lehnt diese und **F8** (stoppt im Editor das Spiel) ab.
- **Doppelbelegung → Tausch** (`Keys.assign`): Liegt die neue Taste schon auf einer anderen umbelegbaren Aktion,
  bekommt die die bisherige Taste des Platzes; war der Platz leer, verliert sie die Taste – die Einstellungen warnen
  dann deutlich („hat jetzt keine Taste mehr“). `Keys.clear` (Entf) lässt jeder Aktion mindestens eine Taste.
- **Einstellungen** (`SettingsPanel._key_list`): Knopf je Aktion und Platz; nach dem Klick fängt `_input` die nächste
  Taste oder Maustaste vor allem anderen ab (auch vor Esc des Menüs, das Mausrad rollt weiter), Esc bricht ab.
  Jede Änderung → `Settings.store_key_bindings()` (`Keys.changed()`), „Standard wiederherstellen“ → `Keys.reset()`.
- **Texte:** Hinweise und Meldungen schreiben weiter die Standardtaste in Klammern („Öffnen [E]“, „[Linksklick]“).
  `Hud.set_prompt`/`show_message` setzen mit `Keys.localize` die aktuelle ein (`Keys.TAGS`, ein Durchgang – getauschte
  Tasten werden nicht doppelt ersetzt; Untertitel wie „[Ein Knall]“ bleiben). Die Hilfe im Menü nutzt Platzhalter
  `{aktion}` bzw. `{aktion.1}` (`Keys.fill`), der Hinweis unter der Tasche `Keys.key_name`. Texte außerhalb des Huds
  (Telefon, Diashow) nennen nur feste Tasten. Notizbuch-Blättern und Abbrechen der Tasche hängen an `use_item` bzw.
  `hold_breath` statt an Links-/Rechtsklick.
- Debug `--taste=aktion,taste[,platz]` belegt nur für die Sitzung um; Test `tests/key_checks.gd`, Rauchtest-Stichwort
  `tasten`.

### Erfolge (`ui/achievements.gd`, `Achievements` als `Game.achievements`, Spielkonzept 8.11)
- **Liste:** `Achievements.LIST` – ID (englisch, später für Steam) → Name, Text, Stufe (`Tier`: Bronze, Silber,
  Gold), Symbol (`art:<name>` = `IconArt`, `item:<Item.Kind>` = wie in der Tasche gerendert, eigene `ItemIcons`),
  `secret`. Reihenfolge = Spielmenü. Neuer Erfolg: Eintrag in `LIST` und `Game.achievements.unlock("id")` an der
  Stelle im Spiel (mit `if Game.achievements:` absichern).
- **Auslöser:** `unlock` direkt in `GuestRequests._complete` (Herzensbitte), `DiceMatch._finish`, `ChessMatch._finish`,
  `Monster._check_salt`, `SheetGhost._struggle` (Spieler losgerissen), `PumpkinMan._search` (Suche nach dem Spieler
  vorbei), `JuryDoll.interact`. Was am Zustand abzulesen ist, prüft `_check` jede Sekunde (nicht in der Pause):
  Kalendertag (3 mit erstem Angriff, 8, 31), gute Freunde (`Social.tier`), gesehene Bedrohungen (`Notebook.seen`),
  brennender geschnitzter Kürbis am Boden vor Zimmer 13 (`door_front`). Nach dem eigenen Tod schaltet nichts mehr frei.
- **Profil statt Spielstand:** `user://achievements.cfg` (Abschnitt `unlocked`, ID → Unix-Zeit). Nichts davon steht im
  Spielstand, am Speicherformat ändert es nichts. `debug` = nur für die Sitzung freischalten, nicht schreiben: headless
  (beginnt leer), Startparameter außer `HARMLESS_ARGS`, Debug-Konsole, F5/F6/F7/F9 (`cheated()`).
- **Einblendung:** `CanvasLayer` 35 (über Menü und Sterbebildschirm), läuft in der Pause weiter; eine Karte zur Zeit
  aus `_queue`, Tween herein (`SLIDE_TIME`), `SHOW_TIME` stehen, hinaus. `medal()` (Symbol auf dunklem Grund, Rahmen in
  der Stufenfarbe, gesperrt grau) nutzt auch die Seite „Erfolge“ im Spielmenü (`Menus._show_achievements`). Klang
  `trophy` (`SynthAudio`, ohne Untertitel).

### Optik
(`util/mat.gd`, `util/geo.gd`, `shaders/`) Ausgelegt auf den realistischen Look (siehe 1, „Grafik“).
- **Materialien** über die Fabriken in `Mat` (`Mat.psx(...)` heißt nur noch so; für Neues mit Karten eher
  `Mat.photo`/`Mat.model` oder ein eigener Shader mit voller Auflösung).
- **Gegen Flimmern:** flache Auflagen (Teppich, Türkassetten, Rahmen) über `Mat.layer(...)` (zieht zur
  Kamera); `Geo.box` unterteilt Flächen in ≤ 1-m-Stücke, damit große Böden nicht schwimmen. Glasscheiben sind einzelne
  Flächen (`QuadMesh`), keine Boxen.
- **Poliertes Metall** = `Mat.metal(farbe)` (`psx_metal.gdshader`): spiegelt einen gedachten Raum nur so hell, wie jede
  Lampe ihn beleuchtet, plus Glanzpunkt – das Environment spiegelt nichts, SSR taugt für dünne Rohre nicht.
- **Post-FX** (`shaders/psx_post.gdshader`, `CanvasLayer` 5 unter der Bedienoberfläche): Gamma, Rauschen,
  Flackern, dazu **verschwommene Sicht** (Spielkonzept 3.6/3.7): `Player._update_sight` setzt `sight_blur` (Müdigkeit
  über `tiredness()`, Rausch, Kater, Fledermausbiss) und `sight_warp`; `main._process` reicht sie mit `blur_time`
  (steht in der Pause) an den Shader – Scheibe aus Abtastungen über eine Mip-Stufe der Screen-Textur. Nach dem
  **Fledermausbiss** (4.22) setzt `_update_sight` zusätzlich `sight_dark` (Shader `dark`, multipliziert das Bild):
  Stärke `_bite_sight` (die ersten `BITE_FRESH` s voll, dann `bite_share()` hoch `BITE_SIGHT_POW`), Herzschlag aus zwei
  Gauß-Spitzen je `1 / BITE_BEAT` s; `Settings.bite_pulse` (Einstellung „Pulsieren nach Biss“, 0,2 … 1) dämpft nur
  den pulsierenden Anteil, die Grunddunkelheit bleibt (4.4).
- **Engerer Blick unter Stress** (Spielkonzept 4.13): `MonsterDirector.player_stress` (geglättet, schnell hoch
  `STRESS_RISE`, langsam runter `STRESS_FALL`) aus Bedrohung, Versteck-Stress, Schock, Jagd = 1. `_update_effects`
  setzt damit `vignette` (`VIGNETTE` + `STRESS_VIGNETTE` × Stress), `Player._update_dread` verkleinert den Blickwinkel
  um bis zu 12°.
- **Nebel** (`main._setup_environment`): Tiefennebel bis Schwarz, Volumennebel nur nah (sonst verschleiert Lampenlicht
  das Flurende beige); `camera.far` knapp dahinter, weil `player_can_see` am Frustum hängt.
- **Himmel** (`shaders/night_sky.gdshader`, `Sky` `REALTIME`): Verlauf, Mond in Richtung von `LIGHT0`, Wolken, Sterne,
  rundum eine **Waldkante** im Himmel (ohne Geometrie, verdeckt alles unter dem Horizont). Zug über das Uniform
  `sky_time` (steht in der Pause, `TIME` liefe weiter); Hash ohne Sinus, damit lange Laufzeiten nicht flimmern. Der
  Himmel leuchtet nichts aus: `reflected_light_source` aus (sonst spiegelte er sich in Tapete und Fliesen),
  `fog_sky_affect` 0.
- **Tapete** = `Mat.wallpaper(wandhöhe, stockwerk, variante, holz)` mit `shaders/psx_wall.gdshader`: drei Bänder ab
  Stockwerksboden – Vertäfelung und Leiste unter `wandhöhe` aus dem Holzbild (`WALLPAPER_BASE`/`_FRIEZE`), dazwischen
  die Tapetenkachel; die gemalte Vertäfelung sieht man nur noch, wo keine modellierte davorsteht (Treppenhäuser,
  Aufzüge); `Mat.wallpaper_split(a, b, normale)` für Wände zwischen zwei Räumen (Tapete, Kachel und Holz je Seite).
  Der Shader tastet die Tapetenkachel (`paper_tex`, `paper_normal`, `paper_rough`, `paper_tile` in
  Metern) normal mit Mipmaps ab – `textureGrad` mit den Ableitungen ohne Bahnversatz, sonst flimmerte die Naht;
  Glanz aus der Rauheit (`rough_matte`/`rough_gloss`); das Holz per Hand bilinear. Holzoberfläche aus der Höhenkarte: Normale aus dem Sprung zum Nachbar-Texel, Glanz
  je Graustufe (`WALLPAPER_GLOSS`).
  **Bahnen** (gegen die Eintönigkeit langer Flure): die Tapete klebt in Bahnen von `strip_width` 0,53 m in Weltkoordinaten,
  jede mit fester Zufallszahl aus Bahn, Wandlage (`wall_key`, flach aus dem Vertex) und Stockwerk – Helligkeit
  ±`strip_shade`, selten ausgeblichen (`strip_faded`) oder um 1–4 cm versetzt angesetzt (`strip_shifted`).
  Nähte (unter einem Pixel nur anteilig dunkler, `fwidth`), ein Teil (`seam_loose`) gelöst: oben unter der
  Leiste oder über der Vertäfelung (`paper_bottom` 0,9 m) zum Ende hin offen, die Kante daneben gewölbt (Normale) mit heller Rückseite. Keine
  Speicherfelder, gleich nach jedem Laden.
  Neue Tapete: Farbe als `wallpaper_<name>.png`, Normal Map und Rauheit als `wallpaper_<muster>_normal.png` /
  `_rough.png` und eine Zeile in `Mat.WALLPAPERS` (Muster, Kachel in Metern); neues Holz als `wainscot_<name>.png`
  (gleicher Aufbau), neue Höhenstufe → `WALLPAPER_GLOSS`. Flecken auf der Tapete sind offen (Spielkonzept 7.2).
- **Geometrie** (`util/geo.gd`): `Geo.solid` (Kollisionskasten mit Mesh), `Geo.mesh` (nur Optik), `Geo.collider`
  (Kasten ohne Mesh), `Geo.box_part` (Mesh + Form an vorhandenem Körper), `Geo.add_surface` (eigene Flächen),
  `Geo.wall_mesh` (siehe 4 „Wände“), `Geo.grain_box`, `Geo.rounded_box`, `Geo.runner_mesh`, `Geo.lathe` (Drehkörper
  aus einem Profil, entlang weich bis auf Knicke – Lobbysäulen, unter 1000 Dreiecken je Säule).

## 8a. Lärm & Sichtbarkeit (`scripts/util/senses.gd`, Spielkonzept 4.15)

Alle Werte stehen in `Senses`: die Lärmtabelle `NOISE` (Art → Hörweite in m, Geräusch, Lautstärke, `alarm`),
Dämpfung, Auffälligkeit und Grundweiten der Beobachter.

**Lärm:** `Game.noise(art, ort, quelle)` ist der einzige Einstieg.
1. Spieler: hört fremde Geräusche bis zur doppelten gedämpften Hörweite (mindestens `PLAYER_MIN_REACH`), linear
   leiser; eigene (`quelle == player`) in voller Lautstärke. Rückgabe = gespielte Lautstärke (z. B. für Untertitel).
2. `MonsterDirector.on_noise`: aktiv → innerhalb der gedämpften Hörweite `investigate`, bis zum Doppelten nur Neugier;
   ruhend → nur Lautes (≥ `Senses.LOUD`) als Neugier. Eigene Geräusche (`quelle == monster`) und Katzen ignoriert es;
   Donner dämpft (`Weather.masking()`).
3. `Social.on_alarm` (nur Arten mit `alarm`): Gäste in halber gedämpfter Hörweite → `Guest.hear_alarm` (Angst,
   verstecken, hingehen oder Gerücht).
4. `Social.on_player_noise` (nur `quelle == player`): Lärm ab `NOISE_ANNOY_MIN` m Hörweite bis `NOISE_ANNOY_REACH` m
   vor einer Zimmertür ärgert, wer drin ist (`change_relation`, schlafend doppelt, je Gast Sperrzeit), Sätze aus
   `Social.NOISE_LINES`. Ausgenommen `NOISE_POLITE` (Klopfen, Tür, Schlüssel, Aufbrechen, Schlag) und `player_threat > 0`.
5. Fledermäuse (`Bats.on_noise`), Krähen.

**Untertitel:** `caption` in `Senses.NOISE` geht über `sound_at` → `play_sound(…, caption_text)` und erscheint bei
jeder hörbaren Lautstärke (> 0,02); ohne `caption` gilt `Game.SOUND_CAPTIONS` erst ab 0,3. Nur mit `Settings.subtitles`.

**Dämpfung** (`Senses.audible_range`): Strahl von Ohrhöhe zu Ohrhöhe; jeder Treffer wird ausgeschlossen und neu
geworfen (höchstens 4). Wand = Körper auf Ebene 1 mit Box ≥ 2,5 m Höhe (Ergebnis je Körper gecacht), Tür = Vorfahr
`Door` (geschlossen dämpft, offen nicht), klares Glas, je Geschossdecke. Möbel, Böden und Brüstungen dämpfen nicht.
→ **Wer eine neue Wand baut, die niedriger als 2,5 m ist, dämpft keinen Lärm.**

**Neues Geräusch in der Welt:** Eintrag in `Senses.NOISE` (mit `caption`), Aufruf `Game.noise(...)` mit `quelle`, wo bekannt (sonst
hört sich z. B. das Monster selbst und läuft seinen eigenen Türen nach). Gäste machen nur beim Rennen Schrittlärm.

**Sichtbarkeit:** `Senses.can_see(beobachter, auge, blick, grundweite, kegel, akteur, bonus, …)`: Sichtweite =
Grundweite × `conspicuity(akteur)` + Bonus, dann Kegel (ganz nah ohne Kegel) und freie Sichtlinie. Auffälligkeit aus
Licht am Ort (`light_at(p, skip)` ohne das eigene Licht in der Hand), Licht in der Hand (Kerze/Kürbis über `lit`,
Taschenlampe über `flashlight`), Rennen/Stillstehen/Ducken. Benutzt von `Monster.can_see_actor` (auch „beim Verstecken
gesehen“: `at` = `exit_point` des Verstecks) und `Guest.can_see_actor` (Zeugen). Eigene Regeln: `player_can_see`
(Kamera), Gäste sehen das Monster (`_watch_monster`), Licht aus (Spielkonzept 4.4), Lauschen (4.7), angehaltener Atem
bzw. Keuchen.

**Debug:** `Game.noise_log` (letzte 5, im F3-Text), `--trace` druckt jedes Ereignis, `--noise=art` erzeugt
regelmäßig Lärm am Spieler.

## 9. Rezepte

**Neuer Gegenstand:** `Item.Kind` ergänzen (nur **ans Ende**, Spielstände speichern den Zahlenwert – `save_rules`
prüft das), Preis in `PRICES`, Aussehen/`deco_strength` in `_build()`, ggf. `create_extra()`. Kleines für die Tasche
→ `POCKET_KINDS`; Symbol entsteht über `ItemIcons` von selbst.

**Neues interagierbares Objekt:** Körper auf passender Ebene (meist 3 = Bit 4), `set_meta("interactable", self)`,
`get_prompt`/`interact` (optional `get_icon`), Gruppe. Platzieren über den Plan: Farbe mit Namen in die Legende
(`PLANFARBEN.md`, Tabelle `Ausstattung: …`/`Möbel: …`), Eintrag in `FITTINGS`/`FURNITURE` von `tools/build_map.py`, Fall in
`LevelBuilder._fittings`/`_furniture`. Hat es Zustand → `save_state`/`load_state` + SaveManager (Gruppe auch in
`WORLD_GROUPS`) + `VERSION` erhöhen.

**Neue Gast-Aktivität:** Schlüssel in `activities` der Profile/Archetypen, Fall in `Guest._next_activity()`, ggf.
eigener `State` (hinten anfügen) und Fall in `_arrive()`.

**Neuer Dialogsatz-Typ:** Schlüssel in `GuestGenerator.COMMON` (Rückfall für alle) und bei Bedarf in den festen
Profilen und Archetypen. Telefonsätze nicht in `COMMON` (siehe Telefone).

**Neue Monster-Reaktion:** Ereignis-Funktion `on_xyz()` im Director, Aufruf von der Quelle aus. Tuning-Konstante oben
im Director.

**Neue Bedrohung oder neuer Angreifer:** `MonsterDirector.other_threat_active` einbeziehen, Kinder ausnehmen (6
„Kinder“), `SaveManager.can_save` sperren, `Notebook` „gesehen“ und `Talk._scan_sights` ergänzen.

**Neues System, das mit delta über Minuten bis Stunden zählt** (Abklingen, Nachwachsen, Pausen): Gruppe `time_skip`
und `skip_time(dt)`, sonst bleibt es beim Zeitsprung im Schlaf stehen (3 „Pause & Zeit“). Lieber gleich an
`MonsterDirector.elapsed` festmachen (Zeitstempel), dann holt es von selbst auf.

**Neue Spur:** `add_xyz()` in `Traces`, `TraceMark`-Art, in `save_state`/`load_state` abdecken, Text für Gästeberichte
in `Social.TRACE_TEXT`.

**Neues Modell:** Bauskript in `tools/` mit Kopfkommentar (Quelle, Lizenz, Lage, Ausgabewerte), Rohmodell in
`assets/source/`, Platzhalter im Code behalten, Lizenz ins README; Meshy-Texturen unkomprimiert (1 „Modelle“).

**Neuer Debug-Parameter:** Zweig in `main.run_debug()` (gilt damit auch für die Debug-Konsole; `true` = erkannt),
dort mit `_is_arg(arg, "--name")` erkennen und den Wert mit `_arg_value`/`_arg_parts` holen statt mit `substr(N)` –
das Literal `"--name"` muss im Code stehen (Selbstprüfung `check_params`). Kopfkommentar in `main.gd`, Eintrag in `DebugConsole.COMMANDS` (Hilfe, Tab) – bei Gast-ID als erstem Wert auch
`GUEST_FIRST`, weiter hinten `GUEST_ANY` (Gast in `main.gd` mit `Social.find_guest` suchen), wirkt er nur beim Start stattdessen `START_ONLY` – plus Tabelle im README. Im F6-Menü erscheint er von
selbst; in `TeleportUI.GROUPS` einsortieren (sonst „Sonstiges“). Für den Rauchtest eine Zeile mit Stichworten in
`tests/smoke.sh`. **Keine Debug-Taste auf F8** – das stoppt im Editor das laufende Spiel.

## 10. Testen

- Start mit Godot 4.7.2 (Pfad im README), Parameter nach `--`. Schnelle Läufe: `--time-scale 3` (headless mit
  `--fixed-fps 60`, siehe Rauchtest), `--quit-after N`, `--trace` (Zustand alle 2 s in die Konsole; im Code immer
  `Game.tracing` abfragen, nicht die Startparameter – so wirkt auch `trace` aus der Konsole), `--day=n`, `--attacks=n`,
  `--kill=id` …
- Screenshots zum Prüfen: `--shot=pfad.png --frames=n` oder `--shot-on=ereignis`; Menüs mit `--menu=…`. Mit `--bg`
  nimmt das Fenster keinen Fokus und liegt außerhalb des Bildschirms – nicht minimiert, sonst zeichnet Godot nicht und
  der Screenshot bleibt leer. Der Fokus würde schon beim Erstellen des Fensters geklaut, deshalb startet jeder Lauf mit
  dem Editor-Binary ohne Fokus (`window/size/no_focus.editor_runtime` in `project.godot`); ohne `--bg` holt
  `Game._ready` ihn sofort nach.
- Nach Änderungen am Speichern (nicht an der Welt): `--savetest` (`alles gleich` erwartet).
- Headless gibt es kein Bild: Autosave ohne Vorschau (in `user://saves_headless/`), Shader werden nicht kompiliert
  (Shader-Änderungen mit Fenster und `--bg --shot=…` prüfen).
- **Bekannt, offen:** Headless-Läufe stürzen nach dem Hotel selten beim Beenden mit Segfault ab (Exit 139) oder hängen;
  der Titelbildschirm allein nie. Am 22.10. noch etwa jeder dritte Lauf, am 28.10. nur 1 von 234 (kurze Szenarien aus
  dem Rauchtest, 6 nebeneinander, dazu 78 mit `--verbose`; beide bekannten Fälle waren `--shock=bruno,lache`, das für
  sich aber auch nur 1 von 50). Der Absturz liegt nach der Endmarke `[Ende]` und vor der ObjectDB-Bilanz („… instances
  were leaked“), also im Abbau der Engine (Skriptsprachen, Server), nicht im Spiel. Ausgeschlossen: Abbau der Szene,
  statische Caches, asynchrone Navigation, Rückkehr zum Titel; Threads aus GDScript gibt es nur in der Schach-KI (wartet
  in `cancel`), Server-RIDs legt das Spiel nicht von Hand an. So selten ohne Debug-Symbole von Godot nicht einzugrenzen
  – nach dem nächsten Refactoring neu zählen. Nebenbei harmlos: 24 `Node3D` bleiben beim Beenden übrig („leaked“).
- **Tests** (`tests/`, nicht im Export). Neue Klassen kennt Godot erst nach einem Import (`--headless --import`) – der
  Rauchtest prüft vorweg den Klassen-Cache (`.godot/global_script_class_cache.cfg`) und importiert selbst, wenn eine
  `class_name` fehlt oder woandershin zeigt (nach einem Merge mit neuer Klasse, im frischen Worktree), sonst hagelt es
  Folgefehler („Identifier … not declared“).
  - **Rauchtest** `bash tests/smoke.sh [stufe]` (`JOBS` Läufe nebeneinander, Protokolle in `temp/smoke/`), drei Stufen:
    **`schnell`** nach jeder Änderung (~½ min: Szenarien mit Stichwort „schnell“ und die Spielstand-Regeln), **ein
    Stichwort** nach Arbeit an einem System (`schlaf`, `monster`, `gaeste` …; trifft auch Wörter in den Parametern;
    `stichworte` listet alle), **ohne Angabe** alles vor größeren Commits (lang, nur nach Rückfrage). Die Liste im
    Skript steht als `Frames|Stichworte|Parameter`. Das Skript spielt die Debug-Szenarien headless mit fester
    Schrittweite (`--fixed-fps 60 --time-scale 3`: jedes Bild genau 0,05 s Spielzeit – ohne holt Godot bei langsamen
    Bildern Physikschritte nach und die Läufe ziehen sich in einer Abwärtsspirale; Kosten ≈ simulierte Spielzeit, darum
    je Szenario nur so lange wie nötig) und meldet Skriptfehler, NaN, festhängende Gäste („kommt nicht weiter“),
    Zeitüberschreitung, Savetest ohne „alles gleich“, unerreichbare Orte im Navcheck; danach die Tests unten und den
    Titelbildschirm. Absturz oder Hängen nach der Endmarke `[Ende]` (`Game._exit_tree`, nur headless) ist das offene
    Problem oben und zählt nicht. Neue Mechanik mit Debug-Parameter → Zeile mit Stichworten; „schnell“ nur
    ausnahmsweise (die Stufe soll unter einer Minute bleiben). Am Ende fasst es Laufzeit-`WARNING`s von Godot
    zusammen (zählen nicht als Fehler).
  - **Selbstprüfungen** `tests/checks.py` (Python, ohne Godot, wenige Sekunden): laufen bei jeder Stufe vor den
    Godot-Läufen mit (Protokoll `temp/smoke/00-pruefen.log`; Fehler brechen nicht ab, zählen aber im Fazit), einzeln
    `bash tests/smoke.sh pruefen`. Jede Meldung mit Datei:Zeile, Fehler und Behebung. Prüft: `class_name` doppelt im
    res://-Baum, wie Godot ihn scannt (ohne Ordner mit `.gdignore` und versteckte wie `.claude/` – eine vergessene
    Sicherungskopie in `temp/` gibt sonst rätselhafte Parse-Fehler woanders), `class_name` gleich einem Autoload,
    doppelte `.uid`-Dateien, Skripte außerhalb von `scripts/`, `shaders/`, `tests/`, `tools/`, `addons/` (Warnung);
    Verweise `Spielkonzept 4.13`, `SK 5.12`, nackt `(2.5)` im Kommentar, `TECHNIK.md 10`, `TECHNIK.md 1 „Grafik“`
    auf vorhandene Kapitel, Unterpunkte wie „6.19 (7)“ oder „4.33, Punkt 5“ auf einen nummerierten Listenpunkt des
    Kapitels (`1. **…**`, `**1. …**`, auch eingerückt – `list_items`); Debug-Parameter: was `main.gd` auswertet, steht im
    Kopfkommentar und in der README-Tabelle und umgekehrt; die Rauchtest-Liste (jede Zeile mit Stichwort, höchstens
    8× „schnell“ – sonst Warnung, Stichwörter in der Doku gibt es); `preload`/`load` mit festem `res://`-Pfad.
    Veralteter Klassen-Cache nur als Warnung (`--cache` allein: Exit 1 = veraltet). `Item.Kind` prüft `save_rules` (unten). `temp/` bekommt bewusst kein `.gdignore`: Godot importiert dort
    Modelle zur Ansicht im Editor und `--static-eg` legt dort seine Szene ab.
  - **Spielstand-Regeln und Rechentests** über die Szene `res://tests/run.tscn` (`tests/run.gd`; Klassen des Spiels
    brauchen die Autoloads, die Godot mit `-s` nicht lädt): `Godot --headless --path . res://tests/run.tscn
    [-- name …]`, jeder Test ein Node mit `run() -> bool`, neue in `run.gd` `TESTS` eintragen.
    `save_rules`: `Item.Kind` behält Namen und Reihenfolge, `GuestGenerator.make`/`make_child` liefern für feste Seeds
    dieselben Werte, jede gespeicherte Gruppe steht in `WORLD_GROUPS` und wird geladen – Vergleichswerte in
    `tests/golden/save_rules.json`, nach gewollter Änderung (Spielstand-Version erhöhen!) mit
    `… res://tests/run.tscn -- save_rules --update` neu schreiben. `math_checks`: Rampe der Lobbytreppe, Kompassnadel,
    `Door.near`. `bag_checks`: Tasche ohne Hotel. `notebook_checks`: Notizbuch und Tagebuch ohne Hotel.
    `throw_checks`: Abwurftempo und langer Spritzer im Zusatzfeld (Spielkonzept 3.13). `darts_checks`: Felder der
    Dartscheibe, Zielpunkte, Zielwahl der Gäste, 301-Regeln und eine Simulation der Aufnahmen je Treffsicherheit.
    `leviathan_checks`: jeder Satz in `LeviathanName.RENAMED` steht wörtlich bei den Gäste-Sätzen (4.32).
  - Schach ohne Autoloads mit `-s`: `-s res://tests/chess_perft.gd` (Zuggenerierung) bzw. `…/chess_ai_speed.gd`.
  - Sonst Prüfung über Debug-Parameter, Konsole und Screenshots.

## 11. Export

- Preset „Windows Desktop“ in `export_presets.cfg`, Befehl im README. `binary_format/embed_pck=true` → eine einzelne
  `.exe`; Skripte als Binär-Tokens (`script_export_mode=2`); Ziel `build/` (Git-ignoriert).
- Export-Filter „alle Ressourcen“: alles unter `res://` landet im Paket, außer `exclude_filter` (`assets/source/*`,
  `tools/*`, `build/*`, `temp/*`, `addons/meshy-godot-plugin/*`). Neue reine Arbeitsdateien dort ergänzen. Dateien, die
  keine Godot-Ressource sind (JSON), brauchen einen Eintrag in `include_filter` (siehe 4, Gebäudeplan).
  `reference/` hat eine `.gdignore` – Godot sieht den Ordner gar nicht.
- Nur `load()` mit festen `res://`-Pfaden verwenden – zusammengesetzte Pfade findet der Export nicht immer, und
  `res://` ist im Export schreibgeschützt. Alles Veränderliche gehört nach `user://` (Spielstände, `settings.cfg`), das
  im Export unter `%APPDATA%/Godot/app_userdata/Zimmer 13/` liegt.
- Export-Vorlagen müssen exakt zur Editor-Version passen (4.7.2).
- Debug-Tasten und Startparameter sind nicht an `OS.is_debug_build()` gebunden, also auch im Release-Export aktiv.
