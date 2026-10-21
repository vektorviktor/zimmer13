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
  Modelle, Texturen (`TexGen`) und Sounds (`SynthAudio`) sind prozedurale Platzhalter. Erster echter Sound:
  `assets/sound/ghost_ambience.mp3` am Lakengeist (`SheetGhost._ambience`), dazu die Schritte
  `assets/sound/step_carpet.wav` (Teppichflure) und `step_tiles.wav` (Fliesen, `Footsteps`), das Türgeräusch `assets/sound/door_open.wav` und die Totenglocke `church_bell.wav` (`SynthAudio.SAMPLES`), der Atemzug
  `assets/sound/breath.wav` beim Keuchen (`SynthAudio.BREATH`), zwei Feierstücke `assets/sound/party_1/2.mp3`
  (`RecordPlayer.TRACKS`, siehe 6) und die Schreie in `assets/sound/screams/` (`SynthAudio.VOICES`, siehe 2, „`Game` als Drehscheibe“). Ausnahmen bei den Modellen: das
  Monster-Modell `assets/models/monster.glb` (siehe 5, „Aussehen & Animation“) und die Lobby-Sofas
  `assets/models/couch.glb` (`LevelBuilder._couch()`: Rohmodell in Blender-Einheiten, per
  `COUCH_SCALE` auf ~2,4 m Länge gebracht; Kollision als zwei Boxen) und die Barflaschen
  `assets/models/bottles.glb` (28 Objekte `bottle_NN` in Metern, Ursprung mittig unten; gebaut von
  `tools/build_bottles.py` aus dem Paket in `assets/source/`) und der Plattenspieler
  `assets/models/record_player.glb` (`tools/build_record_player.py`: Objekte `body` und `record`, die
  Platte ist eine eigene runde Scheibe mit Ursprung auf der Drehachse, damit `RecordPlayer` sie drehen
  kann; Noten aus dem Trichter siehe Partikel in 8). Die **Wanduhr** `assets/models/clock.glb` (`WallClock`,
  `LevelBuilder._clock`): offene Eisenuhr mit römischen Ziffern, `tools/build_clock.py` aus
  `assets/source/clock.glb`. Im Rohmodell stecken die Zeiger im selben Netz wie der Rahmen; das Skript findet sie
  als lose Teile (flach unter `HAND_DEPTH`, über die Mitte, länger als `HAND_MIN`; der längere = Minute), trennt
  sie als `hour_hand`/`minute_hand` ab und dreht sie auf 12 Uhr. Rest = `frame`. Dazu `dial`: Scheibe
  `DIAL_INSET` vor der Rückseite bis in die Mitte des äußeren Rings (ihr Rand verschwindet dahinter, Speichen und
  innerer Ring liegen davor). Ursprung Mitte Rückseite, Zifferblatt nach +Z, Modell 2 m Durchmesser (im Spiel
  `CLOCK_DIAMETER` 3 m), ~16 900 Dreiecke, ohne Texturen: Das Spiel setzt mattes Schwarz `WallClock.IRON`
  (poliertes Eisen ging im Halbdunkel vor der roten Tapete unter), das Blatt gebrochen weiß (`DIAL`). `set_time(stunden)` dreht die
  Zeiger um lokal −Z; bis es eine Uhrzeit gibt, zeigt sie `START_TIME` (1:55 wie im Rohmodell). Sie hängt mittig
  über dem Haupteingang, auf halber Höhe zwischen der Oberkante des AUSGANG-Schilds (`_sign` gibt sie zurück,
  `_exit_sign_top`) und der Hallendecke, `CLOCK_GAP` vor der Wand, ohne Kollision. Die Pflanzkübel `assets/models/planter.glb` (`LevelBuilder._planter()`): Granitbecken mit Erde,
  Steinen und großblättrigen Pflanzen von Meshy, `tools/build_planter.py` aus `assets/source/planter.glb`.
  Das Skript misst das Becken an den Punkten unter 20 % der Höhe, skaliert es auf genau 2 × 2 m (x und y
  einzeln, Meshy trifft das Quadrat nicht; Höhe mit dem Mittel, ~2,1 m mit Pflanzen), Ursprung mittig unten,
  ohne Unterseite, nur Farbtextur (1024er-PNG, ~8600 Dreiecke). Es gibt die Beckenkante aus →
  `PLANTER_H` (0,46 m), so hoch ist der Kollisionsquader über der Grundfläche. Die Blätter sind einseitig,
  deshalb `Mat.model(…, two_sided = true)`. Fehlt die Datei, bleiben Steinquader und Heckenkugel.
  Die Gartenbäume `assets/models/tree.glb` (`LevelBuilder._tree()`): grüner Laubbaum mit Wurzeln von Meshy,
  `tools/build_tree.py` aus `assets/source/tree.glb`. Das Skript findet die Stammachse an den Punkten
  zwischen 10 und 20 % der Höhe (Ursprung dort am Boden) und skaliert die Krone auf 5 m Radius (~9,9 m hoch,
  ~9900 Dreiecke, 1024er-PNG, ohne Unterseite). Es gibt `TREE_RADIUS` und den Stammdurchmesser `TREE_TRUNK`
  (1,53 m) aus. Das Spiel skaliert auf den Kronenradius aus dem Plan; Kollision nur als Stammquader bis
  `TREE_TRUNK_H` (3 m), unter der Krone kann man durchgehen. Offene Blattbüschel → `two_sided`. Fehlt die
  Datei, bleibt der Platzhalter (Stammquader mit drei Herbstkugeln). Beide verlieren Herbstlaub
  (`_falling_leaves`, siehe Partikel in 8); `TREE_HEIGHT` ist die Modellhöhe bei `TREE_RADIUS`.
  Die Taschenlampe `assets/models/flashlight.glb` (`Flashlight`): schwarze Stablampe von Sketchfab (Onur,
  CC-BY 4.0 – Namensnennung nötig), `tools/build_flashlight.py` aus `assets/source/flashlight.glb`. 0,25 m lang,
  Leuchtrichtung +Z, Schalter oben, Ursprung mittig in der Länge auf der Unterkante, ~2500 Dreiecke, 256er-PNG.
  Zwei Objekte: `body` (Gehäuse + Schalter) und `lens` – das Glas bekommt statt der Textur das leuchtende
  Material der Lampe. Das Skript gibt die Glasmitte aus → `Flashlight.LENS`, dort sitzt der Lichtkegel.
  Fehlt die Datei, bleiben Rohr, Kopf und roter Schalter.
  Die Glühbirne `assets/models/bulb.glb` (`Lamp.build_bulb`, für Lampen und das Item `BULB`): „Lightbulb
  (Low-Poly)“ von Sketchfab (Mirai, CC-BY 4.0 – Namensnennung nötig), `tools/build_bulb.py` aus
  `assets/source/lightbulb.glb`. Im Original schräg gestellt – das Skript nimmt die Linie zwischen den Mitten
  von Sockel und Kolben als Achse. 0,11 m lang, Glas nach +Y, Ursprung am Gewindeende, Kolben 6,7 cm, Gewinde
  3 cm. Glühwendel und Halter fallen weg (der Kolben ist undurchsichtig), Punkte an UV-Nähten werden vor dem
  Ausdünnen verschmolzen (sonst reißt es Löcher): ~150 + 180 Dreiecke, 128er-PNG nur für den Sockel. Zwei
  Objekte: `socket` und `glass` – das Glas bekommt das leuchtende Material der Lampe bzw. als Gegenstand die
  Glasfarbe (dunkel, wenn kaputt). An der Decke hängt die Birne kopfüber, `BULB_SCREWED_IN` (2 cm) des
  Gewindes stecken in der Fassung; an der Wandleuchte steht sie auf einer Fassung am Armende und reicht mit
  dem Kolben in den Schirm. Fehlt die Datei, bleibt die Kugel (Lampe) bzw. Kugel auf Zylinder (Gegenstand).
  Die Leuchte selbst (Schirm, Arm, Birne) wirft keinen Schatten: Das Licht der Wandleuchte sitzt 12 cm vor dem
  Schirm, sonst zeichnet er einen langen Keil mit dunklem Strich darüber an die Wand.
  Die Farbtextur der GLB kommt per `Mat.model(pfad, mesh, fläche)` in ein `Mat.psx` (eins pro Textur der
  Modelldatei, Grundfarbe 0,8 Grau – Farbtöne gehören in die Textur, die Materialfarbe wird ignoriert;
  `two_sided` nimmt eine Kopie des Shaders mit `cull_disabled`).
  **Discokugel** `assets/models/disco_ball.glb` (`DiscoBall`, siehe Feiern in 6): „Disco Ball“ von Sketchfab
  (araghon007, CC-BY 4.0 – Namensnennung nötig), `tools/build_disco_ball.py` aus `assets/source/disco_ball.glb`.
  Das Original hat 31 744 Dreiecke (1920 Spiegelplättchen, 64 Spalten × 30 Reihen, auf einem Grundkörper mit
  hochgezogenen Kanten) – die Plättchen allein bräuchten 3840. Das Skript baut eine glatte UV-Kugel (48 × 24,
  2208 Dreiecke, radiale Normalen, Naht bei ±180° in einer Fuge, Diagonalen fest) und backt in Cycles:
  Spiegelmaske (Emission nur der Spiegel), Verschattung der Fugen (AO, 256 Samples) und die Normal Map. Jedes
  Plättchen bekommt die exakte Flächennormale aus dem Original (nicht die gebackene – schon Bruchteile eines Grads
  Rauschen lassen Spiegelbilder zittern); die Plättchen liegen genau in Zellen von 5,625°. Den Tangentenraum
  rechnet Blender selbst um (Kopie der Kugel mit Object-Space-Map als Fließkommabild, darauf gebacken), die Fugen
  bleiben glatt, die Plättchennormale reicht ein Pixel in die Fuge (sonst blitzen Randpixel). Texturen 1024 × 512:
  Farbe, Normal Map, Metallic/Roughness (Maske hart). In Godot unkomprimiert eingebettet (`.glb.import` mit
  `embedded_image_handling=3`, .gitignore-Ausnahme), `DiscoBall` erzeugt die Mipmaps selbst – sonst flimmern die
  Fugen bei 480 × 270 als Striche. Grenze: 8 Bit je Kanal, ganz nah zeigen scharfe Spiegelbilder feine Treppen.
  **Tapeten** `assets/textures/wallpaper_<variante>.png` (teal für Flure, Küche, Bar und Treppenhaus, beige für die Zimmer, red für die Lobby) + gemeinsame Höhenkarte
  `wallpaper_bump.png`, siehe „Optik“ in 9.
  **Fototexturen** (PBR-Sets, je ein Ordner `assets/textures/<set>/`): `Mat.photo(pfad, meter, normal_pfad,
  rauheit_pfad, glanz)` mit `shaders/psx_photo.gdshader` (wie `psx_surface`, Weltkoordinaten) spannt das Farbbild über so viele
  Meter und hält es in zwei Stufen: 256² ohne Mipmaps für den PS1-Look (grob wie die Tapete), 1024² mit Mipmaps
  ohne ihn (`PHOTO_SIZE_PSX`/`_SMOOTH`). Die Normal Map (OpenGL-Format) wirkt nur ohne PS1-Look (`use_normal`; die
  PS1 kannte keine, bei 256² glitzerte sie nur); der Shader bildet Tangente und Bild-„oben“ aus der Hauptachse der
  Fläche (u entlang +x bzw. +z, oben = +y, auf Böden +z), Mipmaps mit wieder normierten Normalen.
  `Settings.apply` → `Mat.set_photo_detail` schaltet alle Fotomaterialien beim Umschalten um. **Glanz** nur bei
  glatten Oberflächen (polierte Fliesen, Lack, Metall): `glanz` > 0 (`specular`, 0,5 = übliches Nichtmetall),
  Rauheit aus dem Rotkanal der Karte (512² reicht, sie ist flächig), in beiden Looks wie bei der Tapete.
  `specular_schlick_ggx` mit `specular` 0 bleibt matt wie `psx_surface` (Godot rechnet mit F0 = 0 auch am Rand
  keinen Glanz). Glanzlichter kommen von Lampen, Kerzen und Taschenlampe, Spiegelbilder von der
  **Bildschirmspiegelung** (SSR, `main._setup_environment`, 128 Schritte; Einstellungen → Bild → Spiegelungen,
  `Settings.reflections` → `env.ssr_enabled` und Shader-Global `reflections`, das `metallic` mit ausschaltet – sonst
  wäre der Boden ohne SSR nur dunkler): Sie spiegelt nur, was im Bild ist,
  blendet zum Rand aus und rechnet für Nichtmetalle fest mit 4 % Reflexion (Fresnel) – `specular` ändert daran
  nichts. Sichtbarer wird sie über `metallic` (hebt F0, nimmt Grundfarbe weg) und `roughness_scale` (schärfer);
  auf hellem Marmor fallen vor allem angestrahlte Wände und Lampen als Lichtbahnen auf, Gleichfarbiges
  verschwimmt. Das Environment selbst spiegelt weiter nichts (kein Himmel in Tapete und Fliesen). Nicht genutzt:
  AO (wirkt in Godot nur aufs Umgebungslicht, das im Hotel fast null ist; oft einfarbig), Metallic-Karten (bei
  Stein, Beton, Holz 0), Height/Displacement (Parallax kostet und verzieht sich bei flachem Blick, die Normal Map
  reicht).
  **Neues Set:** Ordner ist eine Kopie (Originale hat der Nutzer). Erst prüfen
  (`godot --headless --path . -s tools/photo_set.gd -- assets/textures/<set>`: Größe und Wertebereich jeder Karte –
  einfarbige sind leer –, Format jeder Normal Map aus der Höhenkarte geschätzt; liefert ein Set beide, die
  OpenGL-Variante nehmen), Karten je Look bewerten und den Maßstab am Bild schätzen (Bretter, Fliesen, Ziegel),
  dann zuschneiden (`… -- assets/textures/<set> basecolor normalogl roughness:512 [--dx]`): behält die Karten, deren
  Name ein Stichwort enthält, auf 1024² bzw. der Größe hinter dem Doppelpunkt als JPEG, dreht mit `--dx` Grün der
  Normal Map (DirectX → OpenGL), löscht alle übrigen Bilder samt `.import`. `--ao[=stärke]` backt vorher die
  AO-Karte ins Farbbild (× mix(1, AO, stärke)) – für Sets, deren Muster fast nur in AO/Normal/Height steckt
  (`psx_photo` hat keinen AO-Eingang, im PS1-Look fehlt auch die Normal Map); Height bräuchte Parallax, gibt es nicht. Danach braucht es keine besonderen
  Import-Einstellungen. Herkunft und Lizenz vor dem Commit klären; bisher alle Sets von Julio Sillet (JulioVII,
  itch.io, CC-BY) – Namensnennung im README.
  Bisher: **Kellerwände** `Concrete_WoodPattern_01` (Brettschalungsbeton, Farbbild + Normal Map, DirectX gedreht)
  über `LevelBuilder.CELLAR_WALL_METERS` (3 m = 18 Brettreihen, je ~17 cm) · **Lobbyboden** `TilesMarble_01`
  (polierter Marmor, Farbbild + Normal Map + Rauheit 0,22…0,53 × `LOBBY_FLOOR_ROUGHNESS_SCALE` 0,6, Glanz
  `LOBBY_FLOOR_SPECULAR` 0,5, Spiegelanteil `LOBBY_FLOOR_MIRROR` 0,3) über
  `LOBBY_FLOOR_METERS` (2,4 m = 4 × 4 Platten à 60 cm), nur der Lobbyteil des Flurbodens im EG (`_floor`) · **Poolbecken** `pool` (Tiles_06, glasierte
  Fliesen in Blau und Grün, Farbbild + Normal Map + Rauheit, Glanz `POOL_TILES_SPECULAR` 0,5) über
  `POOL_TILES_METERS` (0,6 m = 6 × 6 Fliesen à 10 cm, die Fugen treffen die Beckenkanten): Boden, Wände, ihr 20 cm
  breiter Rand oben und die Einstiegstreppen (`_pool`) · **Poolhalle, Umgang** `TilesBasic_01` (hellgraue Fliesen,
  Farbbild + Normal Map + Rauheit, Glanz `POOL_FLOOR_SPECULAR` 0,5) über `POOL_FLOOR_METERS` (1 m = 4 × 4 Fliesen
  à 25 cm, die Fugen treffen die Beckenkanten), Fläche `pool_deck` in `_floor_material` · **Poolhalle, Wände**
  `Stone_EngraveWall_01` (Steinriemchen, Farbbild mit eingebackener AO – ohne sie fast musterlos – + Normal Map)
  über `POOL_WALL_METERS` (3 m = 6 Spalten × ~22 Reihen, Steine ~50 × 14 cm) als Haut der Seite `pool`
  (`_skin_material`); Toiletten und Bäder behalten `_wall_tiles` · **Säulen der Lobby** `TerrazzoDark_01` (polierter
  dunkler Terrazzo, Farbbild + Rauheit 0,15…0,79, Glanz `PILLAR_SPECULAR` 0,5; AO, Höhe und Metallic leer, die Normal Map
  flach) über `PILLAR_METERS` (1 m, Steinchen 5–8 mm): `_pillar` baut mittig in der Planfläche zwei quadratische
  Sockel `PILLAR_PLINTH` (80 × 80 × 30 cm) unten und unter der Galerie, dazwischen einen runden Schaft
  (`PILLAR_SHAFT_RADIUS` 0,3 m, 24 Segmente, Kollision als Zylinder) – die Projektion nach der Hauptachse wechselt am
  Schaft alle 90°, im Korn sieht man die Nähte nicht. Böden mit Fototextur nennen
  `Footsteps.floor_under` ihre Bodenart per `set_meta("floor", …)` (Lobby: `"tiles"`), weil der Abgleich sonst über die TexGen-Textur läuft.
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
  Punktfarbe je Fläche (R/G/B = Oberteil/Hose/Haare): Kopf-/Hals-Knochen → Haare (nur das größte zusammen-
  hängende Stück – Iris und Augenweiß sind kleine Inseln im Gesicht, `HAIR_MIN_PART`), sonst hellere Grautöne →
  Oberteil, dunklere → Hose; Haut, Schuhe, Hände bleiben. **Formschlüssel `build`** (Körperbau, 1 = kräftig,
  negativ = schlank). Das Skript gibt die Zeile für `GuestBody.BODIES` aus (Höhe, Schulterbreite, Laufweite
  der Animationen, mittlere Helligkeit je Färbebereich) – nach jedem Neubau übernehmen. Erwachsene: `man`/`woman`
  (mittel), `man_young`/`woman_young`, `man_old`/`woman_old` (`gen` in `BODIES`); `guest_woman_young` ist vorläufig –
  Meshys Gehen/Rennen klappt ihre Hände um bis zu 90° ab, das Modell wird neu geliefert. Kinderkörper (6.13,
  `guest_girl7`, `guest_girl10`, `guest_boy7`, `guest_boy10`) liefert Meshy mit kleinem Mixamo-Skelett (23 Knochen: keine Finger, kein
  `LeftToe_End`/`HeadTop_End`) und in Zentimetern (Objekt × 0,01) – Skript und `retarget()` rechnen beides mit
  ein, die Hände bleiben bei den Tänzen in Ruhedrehung. **Arme absenken:** Stehen die Arme in Meshys Ruhepose
  weiter als `ARM_MAX` (32°, Schulter → Handgelenk gegen die Senkrechte) ab – bisher `guest_boy10` (43°) und `guest_woman_old`
  (37°), die übrigen 14–29° –, dreht das Skript die Oberarme samt Netz auf `ARM_DOWN` (20°) und übernimmt das als Ruhepose;
  Gehen und Rennen sind relativ zur Ruhepose gespeichert und senken sich mit, die Tänze rechnet `retarget()` ohnehin
  aus der Ruhepose. Alle anderen Körper bauen dadurch byte-gleich.
  **Textur in Godot unkomprimiert** (`gltf/embedded_image_handling=3`, „Embed as Uncompressed“ in
  `assets/models/guest_<name>.glb.import`, schreibt `build_guest.py`; diese `.import` sind als Ausnahme im Repo).
  Von sich aus zieht Godot die Textur als PNG heraus und packt sie per VRAM-Kompression (S3TC) – deren
  4×4-Blöcke mischen an den UV-Nähten Haut in den Stoff, auf kräftig getönter Kleidung (`psx_guest.gdshader`
  färbt nur graue Texel) helle Streifen an Ärmeln, Bündchen und Seitennähten. Eine `.import` der PNG ins Repo
  zu legen reicht nicht: Ohne die (gitignorierte) PNG zieht Godot sie dann nicht neu heraus.
  **Mixamo-Animationen:** jede `assets/source/anim/<name>.fbx` (Mixamo, „Without Skin“, 30 fps, am
  Standard-Charakter heruntergeladen) landet als Animation `<name>` in **jeder** Gast-GLB – ein Download gilt für
  alle Grundkörper, solange sie Meshys Mixamo-Skelett haben. Umbenennen reicht nicht, weil Mixamo in T-Pose steht
  und unsere Gäste mit hängenden Armen: `retarget()` (`tools/mixamo_retarget.py`, auch für den Kürbismann) dreht den Gast rechnerisch in die T-Pose der Quelle
  (Knochenrichtung zum Kind, bei Hüfte und Händen zusätzlich die Querachse, `ALIGN`) und gibt jedem Knochen
  dieselbe Weltdrehung gegenüber dieser Pose wie in der Quelle gegenüber ihrer Ruhepose. Hüfthöhe im Verhältnis
  (Hüfte über Fuß), seitliches Wandern der Hüfte über `DRIFT_WINDOW` (2 s, als Schleife) gemittelt und abgezogen –
  Wackeln bleibt, der Gast tanzt auf der Stelle. Szenen-Bildrate bleibt (der FBX-Import stellt sie um, sonst
  liefen `walk`/`run` zu schnell). Die FBX liegen nicht im Repo (Mixamo-Lizenz: keine Weitergabe der Rohdateien).
  **SmartRig → Mixamo** (`tools/smartrig_to_mixamo.py`): Meshy-Figuren mit Skelettvorlage „SmartRig“
  (`Bone_000`…) bekommen dasselbe Skelett wie Meshys Mixamo-Vorlage (65 Knochen `mixamorig:…`, Hierarchie wie
  `guest_*.glb` ohne `headfront`). Zuordnung fest in `MAP`, abgelesen am alten Kürbismann (Meshy-SmartRig, inzwischen ersetzt);
  Meshy nummeriert die Finger links und rechts verschieden, das Skript prüft die Reihenfolge an den Gewichten.
  Übrige Knochen (Hilfsknochen an Becken und Händen, Augen, Kiefer, Kopfspitze, Requisiten wie die Axt) geben
  ihre Gewichte an den nächsten zugeordneten Vorfahren ab – die Axt hängt fest an `LeftHand`. `HeadTop_End` neu
  auf dem höchsten Kopfpunkt, Figur auf die Hüfte zentriert, Ruhepose (hängende Arme) und Blick bleiben.
  **Kürbismann** `assets/models/pumpkin_man.glb` (Spielkonzept 4.19, `PumpkinMan`, Verhalten siehe 5):
  `tools/build_pumpkin.py` aus zwei Meshy-Modellen – `assets/source/pumpkin_man.glb` (Auto-Rigging mit Skelettvorlage
  **Mixamo**, kleines Skelett mit 23 Knochen ohne Finger, in Zentimetern) und `assets/source/pumpkin_axe.glb` (ohne Rig).
  Knochen, Netz und Hüftwege rechnet das Skript in Meter um und bringt ihn auf `HEIGHT` 2,0 m (Meshy: 1,63 m; statt
  die Armatur zu skalieren), Blick nach −Z, Netz unverändert (~10 300 Dreiecke), nur Farbtexturen (Körper 1024², Axt 256², Lücken gefüllt, in Godot
  unkomprimiert – `meshy_tex.py`, gemeinsam mit `build_guest.py`; die `.import` liegt im Repo). Animationen von Meshy
  `walk`, `run`, `spin_jump` (auf der Stelle gesetzt – Meshys Sprung trägt ihn 3,1 m nach vorn, das müsste das Spiel
  selbst gehen), dazu jede Mixamo-FBX aus `assets/source/anim/` wie bei den Gästen und aus `assets/source/anim/pumpkin/`
  nur für ihn (`OWN_ANIM_DIR`; `attack` = Mixamo „Standing Melee Attack Downward“, rechtshändig).
  **Axt:** eigenes, starres Objekt am Knochen `RightHand` (`AXE_SIDE` – rechts, weil Mixamos Schläge rechtshändig sind;
  Spiegeln von Modell oder Animation wäre aufwendiger), nicht ins Körpernetz gewichtet – Godot macht daraus ein
  `BoneAttachment3D` `RightHand` mit `MeshInstance3D` `axe` (`PumpkinMan.axe`): folgt jeder Animation, lässt sich einzeln
  ausblenden, abnehmen oder werfen. Ursprung = Griffpunkt, Stiel entlang +Y (Kopf oben), Schneide −X; einhändiges
  Beil, 0,45 m (`AXE_LENGTH`), gegriffen an der Wicklung (`GRIP_AT`). **Faust:** Ohne Fingerknochen biegt das Skript die Finger
  der Axthand im Netz um den Stiel (Abstand hinter dem Fingeransatz `KNUCKLE` wird zum Bogen um die Stielachse,
  Normalen mitgedreht) – die Ruhepose behält das. Handrahmen aus dem Netz: Fingerrichtung = Handgelenk → Mitte der
  Handpunkte, Daumenseite = die Seite, die nah am Handgelenk weiter absteht, Handfläche je nach Seite gespiegelt
  (`chiral`); der Stiel liegt um `GRIP_TILT` (15°)
  schräg in der Faust, Kopf auf der Daumenseite, Schneide in Schlagrichtung. **Ruhiger Axtarm:** Meshys Gehen und
  Rennen schwingen und drehen den Axtarm so weit, dass die starre Axt fast einmal herumkreiste – für `walk`/`run`
  zieht das Skript `AXE_ARM` (Ober-, Unterarm, Hand) zur mittleren Haltung hin (`AXE_SWING` 0,35 bleibt vom
  Schwung); das Beil hängt dann vorn-unten neben dem Oberschenkel. Tänze, Drehsprung und der Schlag
  bleiben ungedämpft. Ein optionaler vierter Pfad legt Vorschaubilder ab (Ruhe, Hand, jede Animation).
  **Pool-Handlauf** `assets/models/pool_handrail.glb` (`LevelBuilder.HANDRAIL_MODEL`): `tools/build_handrail.py` legt
  die Mittellinie als Polygonzug (Pfosten 0,9 m, 0,45 m waagerecht, die Treppe hinab bis 0,9 m über die unterste
  Stufe, senkrecht auf den Beckenboden), rundet die drei Ecken mit 15 cm Biegeradius aus und zieht ein Rohr
  (Ø 5 cm, 10 Ecken) darum. Ursprung am Pfostenfuß auf dem Umgang, die Treppe hinab entlang −Z; Tiefe und Lauf
  (1,4/2,1 m) sind eingebacken und müssen zu `_pool` passen. Material in Godot (`Mat.metal()`, Edelstahl, als `material_override`);
  fehlt die Datei, baut `_pool` wie früher gerade `_rod`-Stangen.
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
`main.gd` erzeugt die Systeme und trägt sie in `Game` ein: `player`, `monster`, `ghost`, `pumpkin`, `director`, `social`,
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
  `gasp`, `bang`, `blip`, `creak`, `thud`, `knock`, `ring`). Arten mit echtem Klang stehen in
  `SynthAudio.SAMPLES` (Datei mono mit Spitze −6 dB, Pegel in dB) und laufen reihum über `SAMPLE_VOICES`
  eigene `AudioStreamPlayer` – bisher `door` (Hoteltüren, aus `temp/audio/104533__skyumori__door_open_02.wav`).
  Lange Klänge mit `"solo"` bekommen eine eigene Stimme, die kein anderer abbricht (`_solo_voices`): `bell`
  (Totenglocke, mono 11 kHz, 4,4 s) – `Social.on_guest_died` spielt sie bei jedem toten Gast nach `BELL_DELAY`
  (3 s, Timer pausiert mit dem Spiel), überall gleich laut, Untertitel `[Eine Totenglocke läutet]`. Nicht beim
  Laden (`SaveManager` ruft nur `Guest.die`) und nicht beim Tod des Spielers. Ebenfalls über `SAMPLES`:
  `shriek` (Kreischen beim Spielertod durch Monster, Lakengeist und Kürbismann, „solo“) und `cry` (die
  Hotelkatze auf der Flucht, Lärm `cat_cry`).
- **Menschliche Laute (Schreie):** `SynthAudio.VOICES` – Klang → Aufnahmen je Stimme (`m`, `f`, `child`), Pegel,
  Tonhöhe (`pitch`) und Abbruch (`cut`). Gespielt, wenn `Game.play_sound` Ort und Quelle bekommt und die Quelle
  `voice()` hat (`Guest.voice()`: Stimme, feste Aufnahme nach `hash(id)`, Tonhöhe, Länge). Jeder Gast klingt
  immer gleich: Grundtonhöhe ± `VOICE_SPREAD` nach der Id, × `VOICE_AGE` (alt tiefer, jung höher), Kinder nach
  Alter und Geschlecht (die Aufnahmen sind Mädchen), Angst höher (`VOICE_FEAR`), Rausch tiefer (`VOICE_DRUNK`),
  dazu jedes Mal ± `VOICE_JITTER`. Tonhöhe ändert auch die Länge (`pitch_scale`). Der Schreckensschrei `scream`
  läuft bei Mutigen kürzer (bis `VOICE_BRAVE` früher abgeblendet), der Todesschrei `death_scream` ist tiefer und
  bricht bei 45–75 % jäh ab (`VOICE_FADE`), das Ächzen `grunt` gibt es nur für Männer. Sie laufen auf
  `VOICE_PLAYERS` `AudioStreamPlayer3D` am Ort des Gastes (ohne Abschwächung über die Entfernung – die Lautstärke
  kommt gedämpft aus `Game.sound_at`, der Lautsprecher gibt nur die Richtung); wer schon ruft, nimmt seinen
  eigenen, `cut_voice(wer)` blendet ab. Ohne passende Stimme spielt `synth` (der synthetische `scream`).
  **Wo:** Lärm `scream` (erschreckt: `_scare_guest`, Kinder, Klopfen an Zimmer 13 – abgewiesen und überlebt),
  Lärm `death_scream` (vom Monster geholt, `kill_guest`, eigener Eintrag in `Social.HEARD_TEXT`), Kürbismann:
  `Guest.cower` schreit beim Ausholen (nur Klang), der Treffer bricht ihn ab und ein Mann ächzt; Lakengeist:
  ein Mann ächzt, wenn er erwürgt wird (nur Klang, `Senses.GRUNT_RANGE`). Feste Gäste haben dafür `sex`/`gen`
  im Profil. **Aufnahmen** aus `temp/audio/screams/` (Ordner `male_scream`, `female_scream`, `child_scream`,
  `male_grunt`, `feline`, `monster_scream`, nummeriert in Ordnerreihenfolge; `male_1` ist der Wilhelmsschrei – bewusst drin): mono 44,1 kHz, Stille vorn und
  hinten weg, auf gleiche Lautheit (Mittel −18 dB, Spitze höchstens −6 dB). Neue Aufnahme: umwandeln wie
  diese und den Namen in `SCREAMS` (bzw. `VOICES`) eintragen.
- **Nur Klang, ohne Lärm:** `Game.sound_at(klang, ort, hörweite, quelle, lautstärke)` – so laut, wie der Spieler
  es hört (dieselbe Rechnung wie `noise`, die sie benutzt), aber niemand sonst reagiert.

### Reihenfolge in `main._ready()`
Umgebung → `LevelBuilder.build()` → NavMesh backen → SynthAudio → ShadowBudget → Traces → Player →
Monster → MonsterDirector (`setup(builder, monster)`) → Post-FX → Social (`setup(builder, self)`,
erzeugt die Gäste) → Dialog → PhoneCalls (findet die Telefone) → DiceMatch → ChessMatch → Hud → Menus → dann entweder Spielstand anwenden
(`_load_pending`, deferred) oder Neues Spiel (Intro, Startzustand speichern). Zum Schluss
`_parse_debug_args` (deferred).

**Wichtig:** Die Reihenfolge, in der der LevelBuilder Objekte erzeugt, ist Teil des
Speicherformats (siehe 7) – ändert sie sich, passen alte Spielstände nicht mehr (Fingerabdruck).

### Szenenbaum (grob)
```
Main (Node3D, main.gd)
├─ WorldEnvironment (Nachthimmel), DirectionalLight (Mond)
├─ Level (NavigationRegion3D)        ← statische Geometrie, Türen, Lampen, Schalter, Verstecke …
│   ├─ Wände, Böden, Decken, Türen … ← aus assets/maps/eg.json, direkt unter Level
│   ├─ Zimmer_0101 …                 ← je Zimmer ein gedrehter Rahmen (Ursprung = Türmitte)
│   ├─ Treppenhaus                   ← Rahmen des Schachts Ost (Läufe, Podeste, Mittelwand vom UG bis oben)
│   ├─ Obergeschoss (y 4)            ← dasselbe aus assets/maps/og1.json, Zimmer_1101 …
│   └─ Untergeschoss (y −4)          ← dasselbe aus assets/maps/ug.json, darin der Heizkeller
├─ Items, Gäste, Plattenspieler      ← dynamisch, direkt unter Main (LevelBuilder.world)
├─ SynthAudio, ShadowBudget, Traces, Player, Monster, MonsterDirector, Social, PhoneCalls
└─ CanvasLayer: PostFx (5), Hud (10), Dialog/DiceMatch/ChessMatch/PhoneUI (15), DeathScreen (20), Menus (30)
```

## 3. Konventionen

### Koordinaten & Ausrichtung
- 1 Einheit = 1 m. Erdgeschoss y = 0, Obergeschoss y = `LevelBuilder.UP_Y` (4), Untergeschoss y =
  `LevelBuilder.CELLAR_Y` (−4).
- Ursprung = Mitte des Haupteingangs auf der Südwand; x nach Osten, z nach Süden (Norden = −Z). Das Gebäude
  reicht etwa von x −76 … 76 und z −112 … 0, die Lobby liegt in der Mitte (x ±7,4, z −28 … 0).
- **Lokale +Z zeigt „nach vorn / in den Raum / von der Wand weg“** (Items: Vorderseite, Verstecke:
  heraus, Fenster/Schalter/Kalender/Spuren: in den Raum). Ausnahme: Monster schaut entlang **−Z**.
- Ursprung von Gegenständen = Unterseite; von Türen = Rahmenecke am Boden (Scharnier, mit `hinge_end` die andere Ecke); von Fenstern = Mitte der Öffnung.
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
| 12 | 2048 | Trittflächen der Treppenstufen (`LevelBuilder.LAYER_TREAD`) | blockiert niemanden; nur für Spuren (`Traces.surface_below`) |

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
- **Bodenlage:** Godots Physik lässt ruhende Körper bis `contact_max_allowed_penetration` (1 cm) einsinken. Die
  Kollisionsform jedes Gegenstands liegt deshalb um `Item.SINK` tiefer als das Sichtbare – sonst versinken flache Dinge
  (Schachbrett 2,4 cm, verstreutes Laub) halb oder ganz im Boden. Wer in `_apply_pose` Formen setzt, zieht `SINK` ab
  (nur am Boden, nicht aufgehängt). Das verstreute Laub nutzt `Mat.layer` (gegen Flimmern beim Vertex-Snapping).
- **Aufgehängte Deko** (Spielkonzept 5.6, `Item.HANGABLE`: Lakengespenst, Lichterkette, Spinnweben): `Item.hang(point,
  out, length)` friert kinematisch ein (`hung`, Ebene 4 bleibt interagierbar, Maske 0), Ursprung = Haken bzw. Mitte
  der Aufhängelinie, lokale +Z von der Wand weg; `set_held()` hebt `hung` wieder auf, `restore_hung()` beim Laden.
  Was schwingt, hängt unter `_swing` (Drehpunkt am Haken); `_apply_pose()` setzt Teile und Kollisionsform je nach
  Hand, Boden oder Wand (Laub: Haufen in der Hand, verstreut am Boden).

### Gruppen (zum Finden und Speichern)
`items`, `guests`, `player`, `doors`, `chests`, `hide_spots`, `lamp_fixtures` (die Lampen),
`lamps` (deren Lichter), `light_source` (alles, was für die Helligkeit zählt – `FlickerLight`),
`light_switches`, `windows`, `pumpkin_plants`, `resource_spots`, `trace_marks`, `warning_notes`,
`guest_notes`, `diaries`, `phones`, `dressers`, `cats`, `uv_marks` (nicht gespeichert).

### Räume & IDs
- **Raum-ID** = Zimmernummer (`"13"`, `"231"`) oder Bereichs-ID (`"lobby"`, `"flur_west"`,
  `"treppenhaus"`, `"keller"` (Heizkeller), `"og_mitte"`, `"ug_cellar_1"` …). Lampen und Schalter gehören über `room_id` zu einem
  Raum; `LightSwitch.find(tree, room_id)` schaltet alle Lampen des Raums. Malt der Plan mehrere
  Schalter in einen Raum, ist das eine Wechselschaltung: `set_on` stellt alle Schalter mit derselben
  `room_id` mit um (Lärm und `on_lights_off` nur vom betätigten), `find()` darf also irgendeinen liefern.
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
- `NavigationAgent3D` mit `path_height_offset = 0.2` (NavMesh liegt ~0,2 m über dem Boden). Das Monster sucht
  ohne Grenze (`path_search_max_polygons = 0`): Godot bricht sonst nach 4096 Polygonen ab und liefert einen Weg
  nur bis zum bis dahin nächsten Punkt – vom Heizkeller in die Flügel sind es mehr (seit dem Untergeschoss).
- Eigene `_move_to(point, speed, delta) -> bool` (true = angekommen) mit **Festgefahren-Erkennung**:
  bewegt sich der Körper kaum, nach 0,6–1 s seitlich 15 cm ausweichen und Ziel minimal verschieben,
  damit der Pfad neu berechnet wird. Neue Akteure sollten diese Logik übernehmen.
- Türen öffnen Gäste/Monster selbst, wenn sie nahe sind (`_open_doors()`).
- Treppen: Rampe als Kollision (Ebene 1, fürs NavMesh, Meta `stair_ramp`) + Stufen als Optik mit eigenen
  Trittflächen (Ebene 12, nur für Spuren). Läufe müssen bündig an der Flurkante enden, sonst Stolperkante.
  Die Lobbytreppe (`GrandStair`) ist unten offen – unter ihrem hohen Ende ist Platz zum Laufen.
- **Spuren auf dem Boden** suchen die Fläche mit `Traces.surface_below` (Ebene 1 + Trittflächen, die Rampe wird
  übersprungen) – sonst schweben sie vorn an jeder Stufe. **Blut** (`TraceMark` „blood“) besteht aus `BLOOD_SPLATS`
  (18–28) Flecken aus je 2–4 Stücken, bis `BLOOD_RADIUS` (1,8 m) um das Opfer verteilt und jeder senkrecht auf die
  Fläche darunter gefallen (Boden, Stufe, Möbel; nicht durch Wände, auf Kniehöhe geprüft); auf einer Treppe laufen sie
  bis `BLOOD_DOWNHILL` die Stufen hinunter. Kein Fleck ragt über eine Kante: `_blood_fits` prüft Ecken und Kantenmitten
  (Höhe höchstens `BLOOD_FLAT` anders); passt er nicht, legt er sich auf einer Treppe längs mittig auf die Stufe
  (`_flat_span` misst Tiefe und Breite), sonst wird er kleiner. Verteilt wird erst nach dem Platzieren (`call_deferred`, auch beim Laden – jedes
  Mal anders). Leichen auf einer Treppe legt `Guest._lie_down` an die Schräge.

## 4. Level (`scripts/level/level_builder.gd`)

Baut Erdgeschoss, Obergeschoss und Untergeschoss aus dem Gebäudeplan (`assets/maps/eg.json`, `og1.json`,
`ug.json`, Abschnitt unten).
Der alte, im Code festgelegte Grundriss (`ROWS`/`FLOORS`) liegt unter dem Git-Tag `alte-karte`.
- **Ablauf von `build()`:** EG laden (`_begin_floor`: Flächen-Raster `_index_places`, 25 cm, Wandstöße),
  Treppenschächte (`_index_shafts`) → `_build_plan_floor()`: jede Wand des Plans (`_build_wall`) → Böden und
  Decken je Fläche → Zimmer → Einrichtung aus dem Plan (`_furniture`, `_fittings`, `_items`, `_lights`) →
  Schalter für Zimmer ohne Plan-Schalter (`_auto_switches`) → Lobby, Treppe zur Galerie (`_lobby_flight`; ohne
  `og1.json` die alte Galerie `_gallery`), Bar/Partyraum/Küche (`_common_rooms`), Pool, Gärten → Treppenhäuser
  → je oberes Stockwerk `_upper_floor` → Untergeschoss `_lower_floor` → Zonen, Wegpunkte.
- **Stockwerke (Spielkonzept 7.7):** `UPPER_MAP_PATHS` (fehlt eine Datei, endet das Haus darunter). Jedes
  obere Stockwerk ist ein zweiter Durchgang von `_build_plan_floor()` unter dem Knoten „Obergeschoss“
  (`root` vorübergehend dorthin, y = `UP_Y` × Stockwerk); danach Geländer an den Lufträumen
  (`_void_edges`: wo Boden angrenzt, außer wo die Lobbytreppe ankommt; wo eine Wand angrenzt, nichts – siehe
  „Wände“, Hallen), Balkon- und Terrassengeländer (`_balconies`), gesperrte Treppenhaustüren. Der Zustand je Stockwerk
  (Plan, Raster, Wandstöße, Möbel, Türen, `_level`, `_base_y`) liegt in `_floors` (`_state`/`_use`); Abfragen
  anderer Systeme wählen ihn über die Höhe (`_level_of`, ±1,5 m um den Boden, `_on_floor`). Raum-IDs ohne
  Zimmernummer tragen oben den Vorsatz `og1_` (`_prefix`: `og1_flure`, `og1_cat_room_1`, Flurabschnitte
  `og1_ost_suedflur` …), damit oben und unten nicht dieselben Schalter schalten; Treppenhäuser bleiben ein Raum
  über alle Stockwerke, die Galerie über der Lobby gehört zur Lobby (`_lobby` bleibt: rote Tapete, Lobby-Licht).
  `_floors` hat das Untergeschoss als letzten Eintrag (`_lower`); `_level_of` vergleicht mit `base_y` jedes Stockwerks
  und liefert den Index in `_floors`.
  Oben reichen die Wände bis 3,5 m hinab (`_wall_piece`: Fassade ohne Fuge), Böden sind 0,3 m stark und liegen
  auf der Decke darunter (`_floor_rect`), über den Lufträumen (`voids`) schließt eine Decke die Halle. Bäder
  gehören zum Zimmer hinter ihrer Tür (`_bath_owner`: Licht, Verschluss); Suiten (`suite`) bekommen kein
  Türschild. `_auto_switches`: Schalter innen neben der Tür auf der Griffseite, sonst neben dem Türblatt.
- **Untergeschoss** (`_lower_floor`, Spielkonzept 7.9): dritter Durchgang von `_build_plan_floor()` unter dem
  Knoten „Untergeschoss“ (y = `CELLAR_Y`, `_level` −1, Raum-IDs mit Vorsatz `ug_`). Wände aus Brettschalungsbeton
  `_cellar_wall` (`Mat.photo`, ohne Häute und Holzpfeiler), Böden `_cellar_floor`, Decken `_cellar_ceiling`; die Wände reichen
  in den EG-Boden und enden 10 cm unter seiner Oberseite mitten in der Platte (bündig flimmerten ihre Köpfe durch
  die Bodentextur); nur Wände am Treppenschacht (`_in_shaft` 30 cm daneben) gehen die vollen 4 m bis an die Wand
  darüber (sonst Fuge im Treppenhaus). Flächen `cellar` (Gänge – Türen gehen nicht in sie
  auf), `boiler_room`, `plant_room`, `laundry_room`, `cellar_room` (Boden auf Ebene 5 wie verschlossene Zimmer).
  Öffnungen in der Farbe des Haupteingangs sind hier verschlossene Türen (`DOOR_H`, „Abgeschlossen.“), die Tür des
  Treppenhauses West ist versiegelt (`_seal_stairwells`). Licht nur aus den **Halogenleuchten** des Plans
  (`_halogen`, `Lamp.Style.HALOGEN`: 80-cm-Röhre unter einem Blechgehäuse, kaltweiß, `HALOGEN_ENERGY`/`_RANGE`,
  ohne Schalter – brennen immer; keine Birne: nicht herauszudrehen, brennt nicht durch, Gäste klauen nichts;
  `FlickerLight.stutter`: alle 10–30 s Spielzeit 1–3 Aussetzer von 40–120 ms auf 5 %, zusätzlich zum Flackern
  durchs Monster). Im Code: `_boiler_room` (Versteck des Monsters, `cellar_center()` = Mitte der Halle, Inhalt des
  alten Kellers an der Südwand, weg vom Eingang im Norden – Kisten, Regal, Schlüssel 18, Münzen, Batterie, Zettel
  2011, UV-Schrift, Spinnweben, alte Deko, kaputte Leuchte und Schalter `keller` im Eingangsgang) und
  `_laundry_room` (je Längswand `WASHERS_PER_WALL` Waschmaschinen). Zonen (`_lower_zones`): Heizkeller,
  Technikraum, Wäscherei und „Keller“ für die Gänge; Wegpunkte (`_lower_waypoints`) nur in `patrol` fürs Monster,
  Gäste gehen nicht hinunter.
- **Wände:** Eine Planwand wird dort geteilt, wo sich die Räume an einer Seite ändern (abgetastet alle 25 cm,
  30 cm neben der Mitte; kurze Läufe an Querwänden geglättet). Tapete je Seite über `Mat.wallpaper_split`
  (Zimmer beige, Lobby rot, sonst teal); Seiten ohne Tapete (draußen = Fassade, Toilette/Pool = Fliesen,
  Lager = Beton) bekommen eine 2-cm-Haut knapp vor der Wand. Glaswände (Pool) als Scheibe auf Ebene 7.
  **Hallen über zwei Stockwerke** (Lufträume, z. B. über dem Haupteingang): Die Seiten werden mit
  `_wall_side_kind` abgetastet – im EG unter `open_above`, darüber in `voids` heißt die Seite `hall:<Art im EG>`
  (`_halls`, beim EG-Plan gemerkt; oben liegt dort keine Fläche, sonst wäre die Seite „draußen“ mit Fassade).
  Ihre Tapete ist die des EG mit `wall_top` = `storey` = `HALL_WALL_TOP` (100 m): keine Leiste, die Höhe zählt
  durchgehend ab dem EG-Boden, die Rauten laufen nahtlos von der EG- in die OG-Wand bis unter die Decke, unten
  bleibt die Vertäfelung. `_subtract` verwirft Reste unter 1 mm (sonst stak dort eine Deckenplatte ohne Tiefe in
  der Wandfläche).
- **Böden** (`_floor`): ein `Geo.solid` je Planrechteck, Textur in Weltkoordinaten (Muster läuft über alle
  Stöße durch). Flure tragen Teppich, die Lobby Fliesen; ein Flurrechteck, das in die Lobby ragt (der Südflur
  ist ein Stück quer hindurch), wird an deren Rand geteilt.
- **Pool** (`_pool`): Becken 1,4 m tief (Sprung reicht nur ~0,7 m), darüber die Holzdecke der Flure wie über dem
  Umgang (`_floors_and_ceilings` überspringt bei `pool_water` nur den Boden – dicht auch gegen Regen, `Weather`), Boden, Wände und Rand aus `Geo.solid`s mit `_pool_tiles` (Fototextur). Heraus kommt
  man über die Einstiegstreppen an beiden Schmalseiten (`_flight` mit Fliesen von der Südkante entlang
  der West- bzw. Ostwand, Handlauf `HANDRAIL_MODEL` ohne Kollision): 7 Stufen à 20 × 30 cm auf 2,1 m
  (`_flight(…, step_h)`, sonst 0,25 m), damit Kanten und Flächen auf dem 10-cm-Raster der Beckenfliesen liegen. **Unterwasserlampen**: je Längswand
  `POOL_LAMPS_PER_SIDE` (2) gleichmäßig verteilt (Drittel der Länge), `POOL_LAMP_Y` unter dem Boden, nicht im Plan;
  `Lamp.Style.POOL`: Chromring mit Glasscheibe bündig an der Wand, ohne Birne (wie Halogen, `has_socket()` falsch –
  Gäste klauen nichts), am Schalter des Umgangs (`pool`). Jede läuft einmal durch den Regenbogen und wieder von vorn
  (`Color.from_hsv`, Licht und Scheibe), Anfangsfarbe und Dauer (`POOL_CYCLE` 18–26 s) zufällig – nie im Gleichschritt.
  Wasser = `PoolWater`
  (`world/pool_water.gd`): `PlaneMesh` im 25-cm-Raster 0,3 m unter dem Boden mit `shaders/psx_water.gdshader`,
  halbtransparent, beidseitig, wirft keinen Schatten. Alle Wellen sind rein optisch im Vertex-Shader (keine
  Physik, kein Auftrieb, Normalen per Differenz): Grundwellen ±7 cm über `wave_time` (Spielzeit aus `delta`,
  steht in der Pause) und bis zu `MAX_RIPPLES` (32, Shader-Konstante gleich halten) **Wellenringe** im Array
  `ripples` (x, z, Alter, Stärke; nach `RIPPLE_LIFE` 9 s frei, sonst ersetzt `ripple()` den schwächsten). Ein Ring
  ist ein Wellenpaket, das mit `ripple_speed` nach außen läuft, abklingend mit `RIPPLE_DECAY` und 1/√Weg.
  **Abprall:** jeder Ring zählt zusätzlich als Spiegelquelle hinter den vier Innenwänden (× `wall_reflect` 0,6)
  und den vier Ecken (× 0,6²) – für ein rechteckiges Becken genau die erste Reflexion; die Treppen werfen
  nichts zurück. Alles wird addiert, wo Kämme zusammenkommen, steigt die Höhe über `foam_from` und es bricht.
  `_track()` prüft Spieler und Monster:
  Füße im Becken → alle `WAKE_EVERY` m ein Ring (schneller als Gehen stärker), stillstehend ab und zu ein
  schwacher; Eintauchen mit mehr als `SPLASH_SPEED` Fallgeschwindigkeit → `splash()` (hoher Ring,
  Nachschwapper, Tropfen als `CPUParticles3D` im Ring um die Stelle). **Brechen** im Fragment-Shader: Schaum,
  wo die Höhe über `foam_from` steigt oder ein Ring innerhalb 0,6 m der Innenkante (`pool_rect`) anschlägt.
  Fresnel (`sheen`) macht flache Blickwinkel heller und dichter – daran sieht man die Wellen.
  **Monster** (`_update_unrest`, Spielkonzept 4.13): Abstand vom aktiven, sichtbaren Monster zum nächsten Punkt
  der Wasserfläche → Zielwerte, angeglichen mit `CALM_RATE`/`TREMOR_RATE`/`SLOSH_UP`/`SLOSH_DOWN` je Sekunde.
  `STILL_FROM`→`STILL_FULL` (32→20 m) senkt `base_scale` auf 0 (glatt); `TREMOR_FROM`→`TREMOR_FULL` (= Rauschen
  20→4 m) `tremor`: nur im Fragment-Shader, kippt die Normale um feine Ringe (22 cm) ab `tremor_src` (Punkt am
  Rand zum Monster hin), alle 0,9 s ein Stoß, der mit 2,5 m/s läuft – das Raster ist dafür zu grob. Monster in
  `hall` (Region `pool`) → `slosh`: stehende Welle der Länge nach (`SLOSH_HEIGHT` 15 cm, `SLOSH_PERIOD` 9 s) plus
  eine schnellere quer, Grundwellen × `SLOSH_WAVES`; Schaum am Rand auch aus dem Schwappen, Gischt (`_drops`)
  entlang des hohen Endes, wenn die Längswelle anschlägt. Alles zusammen höchstens `max_rise` (27 cm) – das Wasser
  bleibt unter der Kante. Debug `--pool=still|tremor|slosh|off` setzt die Stufe ohne Übergang.
- **Öffnungen → Objekte** (`_opening_object`): Türen gehen in Zimmer und Räume auf, nie in den Flur
  (`_inner_side`, Scharnier vom Flur aus rechts) – außer der Plan gibt mit einem Türanschlag (`hinge`/`opens`)
  Scharnierende und Aufgehseite vor (`Door.hinge_end`: Scharnier bei x = width); ab 1,5 m Breite Doppeltür
  (dann zählt nur die Seite). Liegt ein Lichtschalter des Plans neben dem Scharnier auf der Aufgehseite, keine
  Blattbreite weit (`_behind_door`), warnt der Build mit der Pixelposition: Die offene Tür verdeckt ihn. Terrassen- und Glastüren sind gläserne Doppeltüren, Aufzüge
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
    Telefon, Zettel, Tagebuch und Vorräte auf dem Möbel darunter, Kürbispflanzen mit `PLANT_STAGES` – die Sorte kommt
    aus der Palettenfarbe („Ausstattung: Kürbispflanze Hokkaido“ → Art `pumpkin_plant:hokkaido`, Spielkonzept 5.8).
  - `_rugs`: Teppiche (`rugs`) als flache Auflage ohne Kollision 1 cm über dem Boden (`Mat.layer_uv`). Ein
    Läufer läuft entlang der langen Seite seines Rechtecks: `Geo.runner_mesh` legt eigene UVs an – quer spannt
    sich die Textur über die ganze Breite, an beiden Enden ein Abschluss, dazwischen eine ganze Zahl
    Musterkacheln (leicht gestreckt, damit das Muster symmetrisch sitzt). Textur `TexGen._runner` (32 px
    breit: Abschluss 16 Zeilen, Kachel 32 Zeilen; Pixel quadratisch, also Kachel so lang wie der Läufer
    breit). Stöße und Abzweigungen entscheidet der Plan: Ein Läufer endet mit seinem Abschluss am anderen.
    Art → Textur in `RUG_TEXTURES`.
  - `_items`: `Item.Kind`-Name aus dem Plan, auf dem Möbel darunter.
  - `_lights`: Wandleuchten mit Höhe/Helligkeit/Reichweite je Flächenart (`_lamp_style`), Deckenleuchten
    (`_ceiling_lamp`: `Lamp.Style.FLUSH` bündig an der Decke, über `open_above` `Lamp.Style.CEILING` als Pendel an
    einer Schnur bis `PENDANT_Y` – das Pendel bekommt noch ein eigenes Modell), Kerzen auf dem Möbel, Laternen;
    `broken` aus dem Plan. **Kupferleuchte** (`FLUSH`, `Lamp._build_flush`): Ringe nach `FLUSH_PROFILE` von der
    Decke abwärts (Radius, Höhe, Rille – breiter Rand mit zwei Rillen, abgesetzter Korpus mit einer Rille, 16,5 cm
    hoch, 48 cm breit, 24 Segmente) aus `Mat.metal(COPPER)`, Rillen matt dunkel; unten Opalglas (`FLUSH_GLASS`,
    8 mm vorstehend – die Ringe sind volle Zylinder, knapper flimmerte ihr Boden beim Vertex-Snapping durchs Glas)
    mit dem Material der Birne in `FLUSH_GLASS_GLOW`: Es leuchtet, flackert und erlischt mit ihr. Die Birne steckt
    unsichtbar dahinter und lässt sich wie sonst herausdrehen (`has_socket()`). Das Licht sitzt
    `FLUSH_LIGHT_BELOW` (35 cm) unter dem Glas – näher strahlte es das Kupfer von unten grell orange an.
  - Was der Plan nicht kennt, steht in `CONTENT` je Raum-ID: Münzbetrag, Kartenblatt, Zettel-Nummer, UV-Text.
    Lampen und Schalter gehören zur Raum-ID der Fläche davor (`_light_room_at`: Umkleiden/Duschen teilen sich
    `umkleiden`); Schalter in unbewohnten Zimmern starten aus.
  - Nicht im Plan und weiter im Code: die Leuchte über dem Podest zum Untergeschoss (und Ersatzleuchten im
    Treppenhaus, wo ein Plan keine setzt), der Inhalt des Heizkellers und die Waschmaschinen im UG; dazu Flaschen, Hocker, Tanzfläche, Teppiche, Beete und die
    Treffpunkte für Gäste (`_common_rooms`, `_lobby_hall`, `_garden_beds`).
  - **Podestregel im Treppenhaus:** Eine Wandleuchte an der Wand gegenüber der Treppenhaustür (`_landing_side`)
    hängt eine halbe Etage höher, über dem Wendepodest zum Stockwerk darüber (nicht im obersten Stockwerk).
  - **Kratzbaum** (`cat_tree`, `_cat_tree`): Kasten-Kollision bis `CAT_TREE_TOP`, oben ein Liegeplatz in
    `cat_perches` (`cat_room` = im Katzenraum).
- **Lobby und Galerie:** Mit `og1.json` baut das Obergeschoss die Galerie aus seinem Plan (Boden, Wände, Türen,
  Leuchten, Schalter, Geländer), die Lobby hat ihre Decke bis auf den Luftraum (`open_above`); hier nur die
  Treppe (`stairs`, `up` = oberes Ende). Ohne `og1.json` die alte Galerie (`_gallery`): 0,5 m Boden auf 3,5–4 m,
  Geländer, Wände bis 7,5 m, zwei gesperrte Türen. Der Partyraum hat wie die Lobby einen Luftraum mit Galerie.
- **Lobbytreppe** (`scripts/level/grand_stair.gd`, `GrandStair.build` aus `_lobby_flight`; Spielkonzept 7.5):
  gerade Wangentreppe im Rechteck des Plans (Treppe mittig im Luftraum, 3,8 × 6,9 m), unten offen. Stufenzahl
  aus der Höhe (`RISER` 17 cm → 24 Steigungen à 16,7 cm), Auftritt aus der Lauflänge (30 cm). Gebaut im Rahmen
  der Treppe (lokal −Z bergauf, `up` dreht ihn): gebeizte Trittstufen mit Überstand, lackierte Setzstufen, zwei
  Wangen, dazwischen eine schräge Untersicht; Läufer (TexGen „runner“) im Wasserfall-Stil – die Musterkachel
  wiederholt sich entlang des Wegs, in jeder Falte eine Messingstange (`Mat.metal`). Geländer beidseitig:
  Handlauf als gezogener Querschnitt (`RAIL_PROFILE`), gedrechselte Stäbe (zwei je Stufe, ein `MultiMesh` je
  Reihe), Pfosten mit Fußblock, Kappe und Knauf; die oberen hängen mit einem Zapfen unter die Galeriekante. Ein
  Mesh je Material (`GrandStair.Shape`: Quader, Drehkörper, gezogener Strang, Felder ≤ `Geo.MAX_FACE`).
  Kollision wie bei `_flight`: Rampe durch die Mitten der Trittstufen (Ebene 1, `stair_ramp`, reicht unten
  knapp unter die Untersicht), Trittflächen auf `LAYER_TREAD`, für die Geländer schräge Prismen mit senkrechten Enden (ein gekippter
  Kasten ragte mit seiner Stirn auf Hüfthöhe vor die Treppe, Gäste blieben am Eck hängen), die Pfosten. Der Läufer hängt
  an der Rampe – `Footsteps.floor_under` hört Teppich (Gehen leise wie auf den Fluren).
  **Galeriegeländer** (`GrandStair.railing`, aus `_void_edges` für alle Lufträume): Bodenholm, dieselben Stäbe
  (höchstens `BALUSTER_GAP`), Handlauf auf 1 m, Pfosten an den Enden und alle höchstens `BAY` (3 m); an einer
  Ecke nur einer (Meta `gallery_posts` am Stockwerk). Neben einer Treppe endet es genau an ihrer Kante
  (`_stair_edge`), dort steht der obere Treppenpfosten. Balkone und die alte Galerie behalten `_railing`.
- **Wandstöße** (`_index_joints`): Senkrechte Wände enden laut Plan bündig an der Fläche einer waagerechten –
  ihr Mesh ragt bis zu deren Mitte hinein (`_joint_depth`). Läuft umgekehrt eine waagerechte Wand durch eine
  senkrechte hindurch bis an deren ferne Fläche (T-Stoß: Zimmertrennwand an der Flurwand, im EG rund 140), weicht ihr
  Kopf bis zur Mitte der senkrechten zurück (`_head_inset`) – sonst läge er in einer Ebene mit deren Fläche und
  blitzte mit seiner Tapete (Zimmer) durch die Flurtapete. Wechselt die Tapete einer waagerechten Wand an einer
  anstoßenden Wand, liegt der Schnitt zwischen den Stücken in deren Mitte (`_joints_on`), damit ihr Körper die
  Stoßkante abdeckt; sonst blitzt in der Ecke beim Snapping der Boden dahinter durch. Holzpfeiler
  (`_corner_posts`, reine Optik, nicht im NavMesh) fassen jeden freien Wandkopf mit Außenecke ein, an dem zwei
  verschiedene Tapeten zusammenkommen – die beiden Wandseiten (der Kopf selbst trägt die Tapete der Nordseite,
  an Zimmerblöcken also Zimmertapete im Flur) oder der Raum vor dem Kopf (Lobby ↔ Querflur). Kein Eintrag im
  Plan nötig; Wandköpfe ins Freie bekommen keinen. Im EG sind es rund 90.
- **Treppenhaus Ost:** Schacht von −4 bis 7,5 m, gebaut im Rahmen des Schachts (`_index_shafts`: Ursprung
  Mitte, lokal −Z von der Tür zum Podest gegenüber – jede Ausrichtung geht). Je Geschoss zwei Läufe mit
  Wendepodest; Anfang und Ende der Läufe aus den Treppenstufen im Plan (`steps`), sonst 1,4 m Türzone und
  1,5 m Podest. Die Mittelwand über alle Geschosse baut der Schacht (Planwände im Schacht werden übersprungen,
  `_in_shaft`; im UG Beton), die Außenwände und Türen die Pläne. Im Untergeschoss endet die Treppe (der Plan zeigt
  dort nur noch den Lauf hinauf), die Tür des UG-Plans führt in die Kellergänge. Treppenhaus West ist verschlossen
  (auf allen Stockwerken).
- **Schilder** (`_sign`: Zimmernummern, AUSGANG, BAR, KELLER …): Buchstaben als `TextMesh` (1 cm tief, grober
  `curve_step`) im PS1-Material aus Messing auf einer dunklen Holzplatte mit Messingrand. So bekommen sie Licht,
  Schatten und Vertex-Snapping wie alles andere (früher ein ungeschattetes `Label3D`). Zimmernummern
  `SIGN_EM_ROOM` (0,17 m Geviert), Wegweiser `SIGN_EM` (0,22 m). Wie schief ein Schild hängt (bis 1,5°) und welches
  Messing es hat (blank, matt, angelaufen), folgt aus dem Hash des Texts und bleibt so bei jedem Start gleich.
  Schrift: Cinzel Bold (SIL OFL 1.1, `assets/fonts/OFL.txt`), gebaut von `tools/build_font.py` aus dem Variable
  Font in `assets/source/cinzel_variable.ttf` (google/fonts). TextMesh verträgt keine überlappenden Konturen
  (8, und bei Bold A, K, V, W, Y), deshalb eine feste Instanz mit verschmolzenen Konturen, ohne die doppelten
  Eckpunkte, die das Verschmelzen hinterlässt (sonst scheitert die Zerlegung bei M, V, W, Y). Neue Zeichen auf
  Schildern bei Fehlern „Triangulation/Convex decomposing failed“ dort prüfen.
- Bauen in **lokalen Rahmen**: `_parent` ist das gerade aktive Bauteil (root, Zimmerrahmen, Schacht);
  `_wall_x/_wall_z` mit Öffnungen als `Vector4(mitte, breite, oberkante, unterkante)`. Gegenstände kommen in
  die Hauptszene (`world`), umgerechnet über `_global()`.
- Ergebnisse für andere Systeme: `rooms` (Nummer → `{no, sign, kind, center, door_front, door_inside,
  along, into, door, spots}`), `zones`, `spawn_points` (`[0]` = Heizkeller), `patrol` (`{pos, room}`),
  `wander_points`, `player_spawn`, `player_door_front`, Lobby-/Bar-/Garten-/Feier-Punkte, `party_corner`,
  `stairwell_point`, `game_table`, `chess_table`, `diary`, `cat_perches`. `room_spot(no)`: Mitte und Blick zur Tür
  jedes Zimmers im Plan, auch verschlossener (Debug-Teleport `--tp`/`tp`). Verschlossene Zimmer haben einen Boden
  zum Draufstehen auf der Ebene der Decken (5) – nicht im NavMesh, sonst planten Gäste und Monster Wege durch
  gesperrte Türen. Abfragen (alle Stockwerke, nach der
  Höhe): `in_lobby(p)`, `in_area(p, id)`, `is_outdoor(p)` (auch Balkone), `in_corridor(p)` (Flur nach Grundriss,
  ohne Lobby und Galerien), `room_at(p)` (Raum-ID wie bei Fenstern und Schaltern: Zimmer, Bereich,
  Flurabschnitt, `lobby`, im UG `ug_…`; leer auf Podesten), `is_safe(p)` (Katzenraum), `cellar_center()`
  (Heizkeller).
- NavMesh wird in `main._bake_navigation` zur Laufzeit gebacken (nur Ebene 1, Agent 0,3 m / 1,6 m).
  `--navcheck` misst Bau- und Backzeit (EG + OG1 + UG: ca. 3,1 s + 0,85 s) und prüft die Wege zu allen wichtigen
  Orten (ohne Suchgrenze wie das Monster), oben zu Katzenraum, Bibliothek, einem Flur und einem Zimmer, unten zu
  Kellergang am Treppenhaus, Heizkeller („Keller“), Technikraum und Wäscherei.
- Ein neues Zimmer: im Plan zeichnen und in den Objektebenen einrichten (Bett, Schrank, Leuchte, Schalter …),
  `tools/build_map.py` laufen lassen – Wände, Tür, Einrichtung, Zone und Wegpunkt entstehen daraus.
  Jede Änderung an Lampen, Schaltern, Verstecken, Kommoden, Truhen, Telefonen, Pflanzen oder Vorräten im Plan
  verschiebt die Reihenfolge – alte Spielstände werden dann abgelehnt (siehe 7), zu tun ist nichts.

### Gebäudeplan (`map.aseprite` → `tools/build_map.py` → `assets/maps/<stockwerk>.json`)
Grundriss seit Spielkonzept 7.5. Der Plan liegt im Projektwurzelverzeichnis (der Zeichner speichert
dort), das Skript ist reines Python ohne Zusatzpakete und braucht ca. 10 s je Stockwerk:
`python tools/build_map.py [map.aseprite] [assets/maps] [vorschau-ordner]`. Die Vorschau (`<stockwerk>.svg`)
zeichnet das Ergebnis **aus den JSON-Daten** (nicht aus dem Bild) – gut zum Prüfen nach Planänderungen.
- **Aufbau der Plandatei (Vorlage):** Jede Ebenengruppe der obersten Stufe ist ein Stockwerk (`EG`, `OG1` …,
  `Keller`) und wird zu `eg.json`, `og1.json` … – sobald sie Wände enthält. Gezählt werden alle normalen
  Ebenen der Gruppe, **egal ob sichtbar**; nicht gezählt werden Referenzebenen (`OG1/EG (Referenz)` zeigt das EG
  zum Abzeichnen) und Ebenen, deren Name mit `Beschriftung`, `Skizze` oder `Notiz` beginnt.
- **Legende = `map.gpl`:** Die Bedeutung jeder Farbe steht als Name in der Legende neben der Plandatei
  (GIMP-Palette, „R G B<Tab>Name“, Zeile = Paletten-Index; `FILLS`, `OPENINGS`, `Wand`, `Glaswand` oben im
  Skript, Zuordnung nach Farbwert). Nicht in `map.aseprite`: Aseprite 1.3.18 behält keine Palettennamen,
  schon Öffnen und Speichern verwirft sie (19.10.). Neue Farbe in der Palette → Zeile in `map.gpl`, Farbwert
  geändert → dort auch. Farben ohne Legendeneintrag meldet das Skript mit Pixelposition. Slices liest es nach
  Namen sortiert, weil Aseprite ihre Reihenfolge beim Speichern ändert (sonst wechselt z. B. die Reihenfolge der
  Treppen und mit ihr der Fingerabdruck der Welt). Beim Zeichnen zeigt die Aseprite-Erweiterung
  `tools/aseprite-palette-names/` (View > Palettennamen) die Palette mit den Namen aus `map.gpl`.
  1 m = 10 px, Wände 2 px, Öffnungen als Farbstriche **auf** der Wandlinie (**Türanschlag**: ein Pixel
  `Türanschlag` statt eines Türpixels an einem Ende des Strichs, in der Wandhälfte, in die die Tür aufgeht – dort
  sitzt das Scharnier; es zählt als Türpixel, falsch gesetzt bricht das Skript mit der Position ab), Flächen als Füllfarben, `Luftraum` = hier kein Boden (wird beim
  Stockwerk darunter zu `open_above`). Schrift in Wandfarbe im Grundriss wird über ihre Größe erkannt und
  übermalt, gehört aber in die Ebene `Beschriftung`.
- **Objektebenen** je Stockwerk: `Möbel`, `Ausstattung`, `Gegenstände`, `Lichter`, `Teppiche`. Sie zählen nicht
  zum Grundriss und haben eine eigene Legende (Palettennamen mit Vorsatz `Möbel:`, `Ausstattung:`, `Gegenstand:`,
  `Licht:`, `Teppich:` → `FURNITURE`, `FITTINGS`, `ITEMS`, `LIGHTS`, `RUGS` im Skript). Möbel sind Rechtecke in
  Grundfläche, ein Strich `Möbel: Vorderseite` am Rand zeigt die Vorderseite. Teppiche sind volle Rechtecke auf
  eigener Ebene (dürfen unter Möbeln liegen; `Teppich: Läufer` läuft entlang der langen Seite). Alles andere ist ein 3×3-Punkt; Wandsachen
  (Leuchten, Schalter, Bilder, Spinnweben, UV-Schrift, Kalender) liegen innen an der Wand, daraus ergibt sich
  ihre Wandseite. **Halogenleuchten** (`Licht: Halogenleuchte`) sind Striche in ihrer Länge (8×2 px = 80 cm),
  die Ausgabe bekommt `axis` (`x`/`z`) und `length`. Gleichfarbige Punkte dürfen sich nicht berühren (sonst wird
  es einer). Höhe, Helligkeit und
  Inhalt (Zettel-Nummer, Münzen, UV-Text) stehen nicht im Plan, sondern im LevelBuilder (`CONTENT`,
  `_lamp_style`, `BOX_HEIGHTS`). Die Ebenen wurden am 2026-10-19 aus dem laufenden Spiel übertragen.
- **Untergeschoss** (Gruppe `UG`, 20.10.): Flächen `Kellerboden` (`cellar`, Gänge), `Heizkeller`, `Technikraum`,
  `Wäscherei`, `Kellerraum` (leer, verschlossen); unbemalte Räume hinter verschlossenen Türen (Farbe `Haupteingang`)
  haben keinen Boden. Das Skript baut zuerst das EG, damit die Treppenflächen des UG dem Schacht darüber zugeordnet
  werden (wie oben); Laufwege und Flurabschnitte (`WINGS`) gibt es unten nicht.
- **Slices** (sprite-weit, daher Stockwerk als Vorsatz, ohne Vorsatz EG: `OG1 Raum: Bibliothek`):
  `Raum: <Name>` benennt die Fläche mit den meisten Pixeln im Slice (ID = Name klein, Umlaute ausgeschrieben),
  `Bereich: <Name>` → `areas`, `Treppe: <Name>` (**Pivot an der oberen Kante**) und `Treppenhaus: <Name>` →
  `stairs`, `Objekt: <Name>` (Pivot an der Vorderseite) → `objects` (Vorsatz `UG` für das Untergeschoss). Unbenannte Flächen heißen `<art>_<n>`,
  der einzige Flur `flure`.
- **Ausgabe** (Meter, x Ost, z Süd, Ursprung = Mitte Haupteingang auf der Südwand, Rechtecke `[x0, z0, x1, z1]`):
  `walls` (`a`, `b`, `thickness`, optional `glass`, `openings` mit `kind`/`at` = Abstand ab `a`/`width`, mit Türanschlag dazu `hinge` = `start`/`end` (West- bzw.
  Nordende) und `opens` = ±1 (+1 = nach Süden bzw. Osten);
  waagerechte Wände laufen durch, senkrechte enden bündig an ihnen), `regions` (`id`, `kind`, `outdoor`,
  `rects`, optional `name`; die Fläche `flure` umfasst alle Flure **und** die Lobby), `rooms` (`no`, `sign`,
  `wing`, `rects`, `center`, `door` mit `pos`/`normal` in den Flur, `windows`, `garden_doors`, optional
  `bath_doors` und `connecting_doors`), `stairs` (`id`,
  `kind` `stair`/`stairwell`, `rect`, `up` bzw. `door`), `voids`, `open_above`, `areas`, `objects` (`name`,
  `rect`, `facing`), `corridors` (Flurabschnitte: `id`, `name`, `wing`, Mittellinie `a`–`b`), `floor_patches`
  (Boden unter Kübeln, Bäumen, Rezeption und freien Treppen, mit der Art der umgebenden Fläche), `planters`,
  `terrace_edges`, `balcony_edges` (Balkongeländer, Rechtecke wie die Terrassenkanten), `trees`, `reception`; aus den Objektebenen `furniture` (`kind`, `rect`, optional `facing`),
  `fittings` und `items` (`kind`, `pos`, optional `wall` = Wandseite, Gegenstände mit `Item.Kind`-Namen),
  `lights` (dazu optional `broken`) und `rugs` (`kind`, `rect`).
- **Türarten:** Alle Zimmertüren sind Striche in `Tür Flur`; das Skript liest beiderseits der Wand, wohin sie führen:
  ans **Bad** (Fläche `Bad`, Art `bath`) → `bath_doors`, beiderseits Zimmer → **Verbindungstür** (`connecting_doors`),
  sonst Flurtür. Im EG braucht jedes Zimmer genau eine Flurtür; darüber sind zwei erlaubt (die erste ist die
  Zimmertür, die übrigen `side_doors`) und Suiten ohne Flurtür (`suite`, Tür = erste Verbindungstür); eine Fläche
  „Zimmer“ ganz ohne Tür bleibt geschlossen (Hinweis beim Bauen). Ohne Türanschlag gehen Badtüren ins Zimmer
  auf, Verbindungstüren ins Zimmer mit der höheren Nummer (`opens`, Spielkonzept 7.7). Weitere Flächen seit dem
  OG1 (20.10.): `Katzenraum` (`cat_room`), `Bibliothek` (`library`), `Balkon` (`balcony`, draußen) mit
  `Balkongeländer` (`balcony_edge`, Einbau); Möbel `Möbel: Kratzbaum` (`cat_tree`).
- **Treppenhäuser über dem EG** brauchen keine eigenen Slices: Treppenflächen über einem Treppenhaus des EG
  gehören zu dessen Schacht (gleiche ID). Die Tür eines Treppenhauses darf jede Türart sein (Flur-, Glas-,
  Betriebstür); `steps` = Rechteck der Treppenstufen (dort beginnen und enden die Läufe).
- **Zimmernummern** entstehen im Skript (`WINGS`: Laufweg je Flügel als Flurmittellinien in Pixeln, dann
  Querflur; rechts ungerade). Liegt ein Zimmer an keinem bekannten Flur, bricht das Skript ab – dann `WINGS`
  ergänzen. Darüber (`number_from_eg`): Nummer des EG-Zimmers 1 m hinter der Flurtür mit dem Stockwerk vorne,
  sonst das mit der größten Überdeckung; zwei Zimmer über demselben behalten es für das mit der Flurtür darüber,
  die übrigen und Zimmer über keinem EG-Zimmer zählen im Flügel hinter der höchsten Nummer weiter (Norden vor
  Süden, Westen vor Osten). `BROKEN_SIGNS`: abweichende Türschilder (0113 → „13“).
- `export_presets.cfg` packt `assets/maps/*.json` mit ein (`include_filter`), weil JSON keine Godot-Ressource ist.

## 5. Das Monster

Zwei Teile: **`MonsterDirector`** entscheidet *ob/wann/wohin* (versteckte Werte, Dramaturgie,
Effekte), **`Monster`** führt aus (Zustandsautomat, Bewegung, Sicht, Spuren).

**Nur eine Bedrohung im Haus** (Spielkonzept 4.1): `MonsterDirector.other_threat_active(wer)` – Monster aktiv,
`SheetGhost.is_active()` oder `PumpkinMan.in_house()` (jagt oder geht, keine Testfigur), außer dem Fragenden selbst.
Gefragt wird beim natürlichen Erscheinen: `_update_schedule` (Aufbruch verschoben, alle 10 s neu), `_check_first_attack`,
`SheetGhost._check_spawn` (ganz am Anfang, also auch Tür, Flur und Gäste), `PumpkinMan._check_spawn` (vor dem Wurf –
der bleibt scharf). Debug-Aufrufe (F5/F7/F9, `--warn`, `--ghost`, `--pumpkin=…`) fragen nicht.

### Versteckte Werte (Director)
- `boldness` (Dreistigkeit, global, steigt nach dem ersten Angriff) − `boldness_dip` − `satiation`
  = `effective_boldness()`.
- `curiosity` je Zone: strebt jede Sekunde zu einem Grundwert aus Dunkelheit und fehlender Deko,
  Ereignisse addieren direkt (`add_curiosity`). `_update_zones(delta)` nimmt je Physik-Frame nur ein Stück der
  Zonen dran, jede einmal je `ZONE_PERIOD` (1 s) – alle auf einmal (334 Zonen × 547 Lichter) ließen das Spiel
  jede Sekunde ~140 ms hängen (21.10.).
- `pressure_at(p) = Dreistigkeit × (0,5 + 0,5 × Neugier/100)` (+ Bonus beim Jagen),
  `deterrence_at(p)` aus Deko × Licht / `demand()` plus Licht allein, im Katzenraum unendlich
  (`LevelBuilder.is_safe`: dort hinein kommt es nie, wer drinsteht, ist auch bei der Jagd geschützt). Deko zählt nur
  auf demselben Stockwerk (±2,5 m). `is_blocked` / `is_protected`.
- `light_at(p)`: Summe aller `light_source` mit freier Sichtlinie (Raycast) + Mondlicht durch
  Außenfenster mit offenem Vorhang. Teuer → sparsam aufrufen. Die Lichter kommen aus einem Raster
  (`_lights_near`: Zellen `LIGHT_CELL` 8 m, alle `LIGHT_GRID_FRAMES` neu einsortiert, Suchradius größte Reichweite
  + `LIGHT_GRID_SLACK` für getragene Lichter); An/Aus und Helligkeit prüft `light_at` jedes Mal selbst.

### Ereignis-Schnittstelle (andere Systeme melden, der Director reagiert)
`on_noise(pos, hörweite, quelle)` (nur über `Game.noise`) · `on_lights_off(pos)` · `on_actor_hid(spot, actor)` · `on_monster_talk(pos)` ·
`on_monster_noticed()` · `on_monster_repelled()` · `on_monster_uv()` · `on_monster_gone()` · `kill_guest(guest, spot)` ·
`kill_player(spot)`. Neue Spielmechaniken, die das Monster beeinflussen sollen, melden sich hier.
Debug: F5 = `start_warning()` (nur wenn es ruht), F7/`--lure` = `debug_lure()`: ruht es, `spawn_at()` auf dem
NavMesh-Punkt ~`LURE_DISTANCE` (25 m) vom Spieler (zählt damit als erster Angriff), dann `investigate(Spieler)`.

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
  `--attacks=3` macht es nur nicht mehr harmlos – ob es holt, würfelt `_choose_intent` (Tag 1–4: 20 %); sicher
  mit `--intent`. `--trace` zeigt beim Aufbruch Angriffsnummer, Tag, Chance (bzw. satt/erzwungen) und Absicht,
  dazu `[Geholt]` aus `kill_guest` und `[Erschreckt]` aus `_scare_guest`.
- **Flackerwelle**: `_start_wave(ursprung, opfer)` – Dauer `SIGNAL_BASE + SIGNAL_PER_VICTIM × opfer` (1 + 2 × n s),
  Stufe `_wave_level` 0 / 1 / ab 2 Opfern (Stärke, Untertitel, Gäste, `long_signal_near`); `wave_delay(p)` = Weg vom Ursprung (Heizkeller)
  über das Stockwerk, in jedes andere Stockwerk über `_stairwell`, durch `WAVE_SPEED`. Jede Lampe bekommt
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

### Der Kürbismann (`scripts/monster/pumpkin_man.gd`, Spielkonzept 4.19)
Dritte Bedrohung neben Monster und Lakengeist, eigener Akteur (`CharacterBody3D`, Ebene 32 wie das Monster) in
`Game.pumpkin`. Spielt die Animationen der GLB (`walk`/`run`, Abspieltempo aus der Laufweite), kein Code-Rig.
- **Spaß** zählt `Social.has_fun(gast)`: Zustand `PARTY` oder `MINIGAME`, Kind auf Süßes-oder-Saures-Runde
  (`_rounds`) oder an Zimmer 13 (`_trick`), beim Schmücken dabei (`Decorating.is_crew`, 5.9); `player_has_fun()`:
  `Game.dice`/`Game.chess` aktiv, Feier und im Partyraum, `_trick` oder in `PRESENT_RANGE` einer laufenden
  Schmück-Aktion (`Decorating.player_joins`). `fun_actors()` = beides zusammen.
- **Auslöser** (`_check_spawn`, je Sekunde): steigt `fun_guests().size()` auf `FUN_MIN` (15), wird einmal mit
  `SPAWN_CHANCE` (30 %) gewürfelt; neu gewürfelt wird erst nach einem Abfall unter die Schwelle (`_armed`). Erst nach
  `first_attack_done` und erst mit fertigem NavMesh (`map_get_iteration_id`).
- **Ankunft übers Lobbydach** (entschieden 2026-10-21): `start_hunt(akteure)` sucht die Glastür von der Lobby in
  den Mittelgarten, die einem davon am nächsten liegt (`_garden_door`: Tür mit `glass` aus der Gruppe `doors`, Lobby
  davor – `in_lobby` –, Garten dahinter – `is_outdoor`; heute x ±5,5 in der Nordwand z = −28). Warum dort: Der
  Haupteingang ist verriegelt, der Luftraum oben geschlossen, die Galerie hat kein Fenster nach draußen – die
  Gartentüren sind der einzige Weg in die Lobby, und der Garten mit den Kürbisbeeten liegt direkt dahinter. Ablauf
  ohne Physik und NavMesh (Kapsel aus, Position direkt gesetzt): `CLIMB` an der Straßenfassade genau gegenüber
  (`FACADE_Z` vor der Südwand, `CLIMB_SPEED`, oben `LEDGE_TIME` über die Kante) → `ROOF` mit `ROOF_SPEED` bis an die
  Dachkante über der Tür, dort `EDGE_WAIT` stehen (Silhouette vor dem Nachthimmel) → `LEAP` (Schritt mit `LEAP_SPEED`,
  freier Fall) → `LAND` im Garten (Kapsel an, Lärm `pumpkin_land` 16 m mit `alarm`, `Social.HEARD_TEXT`; `LAND_TIME`)
  → `LOBBY`: durch die Glastür, Halte hinter der Tür und `LOBBY_STOPS` (Seitengang neben der Treppe, hinter der
  Rezeption, vor dem Haupteingang; x zur Seite seiner Tür gespiegelt, auf den NavMesh gezogen), an jedem `LOBBY_LOOK`
  umsehen. Alle `LOOK_EVERY` s `_spot_someone`: wen er sieht (jeder Erwachsene und der Spieler, mit `_forced` nur
  der), den jagt er (`CHASE`); wer im Weg steht, stirbt, danach sucht er weiter (`_lobby_left`). Danach `_next_victim`.
  Dach- und Gartenhöhe per Strahl nach unten (`_surface_y`, Ebene 1 und Decke 16 – heute 7,7 m auf der
  Obergeschossdecke; ein späteres Dach müsste nur trittfest auf diesen Ebenen liegen). `arriving()` (`CLIMB`/`ROOF`/`LEAP`):
  `_hunt_left` läuft erst ab der Landung, `is_hunting()` erst ab `LAND` (Feiern laufen weiter, bis er unten ist),
  `in_house()` schon (keine zweite Bedrohung); `_scare_onlookers` nimmt dann die Decke dazu (sonst sähen ihn die Gäste
  darunter hindurch). Animationen `climb`/`land` (`CLIMB_ANIM`/`LAND_ANIM`, Mixamo-FBX nach `assets/source/anim/pumpkin/`)
  nimmt er, sobald die GLB sie hat – bis dahin Gehen beim Klettern, Stand in der Gehpose im Fall und nach dem Aufprall.
  `spin_jump` taugt nicht: Meshys Drehsprung dreht ihn fast über die ganze Länge. Ohne Gartentür (anderer Plan)
  erscheint er wie früher an einem Kürbisbeet.
- **Jagd:** mit `at` (Debug) bzw. ohne Gartentür erscheint er an einem Kürbisbeet
  (`_bed_point`: NavMesh-Punkt höchstens `BED_REACH` neben der Pflanze aus `pumpkin_plants`, die einem davon am nächsten
  liegt, außer Sicht des Spielers – `MonsterDirector.player_can_see`); ohne freies Beet `SPAWN_DISTANCE` vom Opfer. Zustände
  `STALK` (zum Opfer aus `_pick`: zuerst dem Nächsten, den er im Partyraum sieht – `_seen_in_party_room()`, Gäste und
  Spieler mit oder ohne Spaß, `_sees` + `LevelBuilder.in_area(…, "partyraum")`; zu ihnen sprintet er (`_has_fun`) –, dann
  dem Spieler, wenn er ihn in `PLAYER_NOTICE` (14 m) sieht (`_player_near`, auch ohne Spaß; in `CHASE` wechselt er alle
  `RECHECK` s auf ihn, außer das Opfer ist im Partyraum oder `_forced`), dann dem Nächsten aus `Social.fun_actors()` – dann sprintet er mit `CHASE_SPEED` –, sonst
  dem nächsten erwachsenen Gast, gehend; alle `RECHECK` s neu ausgesucht; `_forced` nur für `--pumpkin=jagd,…`) → `CHASE` (sieht ihn: Raycast `Senses.SIGHT_MASK`, rennt mit `CHASE_SPEED`)
  → `STRIKE` (in `STRIKE_RANGE`: Gast `cower()` erstarrt; Animation `attack` mit `ATTACK_SPEED` 1,3, Treffer bei
  `HIT_AT` 0,4 ≈ 0,7 s – da saust das Beil herunter; fehlt sie, nach `WINDUP`; getroffen wird, wer noch in `HIT_RANGE` ist) → nächstes Opfer (`_next_victim` → `_pick`; kein
  erwachsener Gast mehr → `ROAM`, umherstreifen). Keine Opfergrenze: nach `HUNT_TIME` (120–180 s) →
  `LEAVE` zum Haupteingang (`EXIT`), tut niemandem mehr etwas, weg, sobald er dort ist und der Spieler ihn nicht sieht. Opfer versteckt / `LOSE_SIGHT` ohne Sicht → `SEARCH` an der letzten
  Stelle, dann das nächste. Türen öffnet er wie das Monster (`monster_open`). **Im Weg** (`_strike_blocker`, in
  `STALK`/`CHASE`): ein jagbarer Erwachsener oder der Spieler näher als `BLOCK_RANGE` und vor ihm (`BLOCK_DOT`) wird
  geschlagen (`_strike_target`), auch ohne Spaß; danach weiter hinter dem eigentlichen Opfer (`_victim`) her.
- **Folgen:** `Guest.die("pumpkin")` → Leiche (`_lie_down`) in einer Blutlache (`Traces.add_blood`); gespeichert wie
  die Leichen des Lakengeists (`corpse`), daher kein neues Speicherfeld. `Social.on_guest_died(gast, "pumpkin")`;
  Kinder schließt `_can_hunt` aus (Spielkonzept 6.13). **Ton:** beim Schlag `assets/sound/axe_hit.mp3` als
  `AudioStreamPlayer3D` am Kürbismann; dazu Lärm `axe_swing` (ohne eigenes Geräusch, erschreckt Gäste). Das Opfer
  schreit beim Ausholen (`Guest.cower`), trifft die Axt, bricht der Schrei ab (`SynthAudio.cut_voice`), Männer ächzen. Gäste mit Sicht auf ihn: `Guest.see_pumpkin()` (beendet Spieltisch
  und Klopfen, dann `shock("pumpkin")`, Erlebnis „pumpkin“ in `Social.EXPERIENCE_LINES`). Spieler: Sterbebildschirm wie
  beim Lakengeist.
- **Ruhe:** `MonsterDirector.is_quiet` ist auch dort falsch, wo er jagt – Feier, Partien und Süßes oder Saures enden
  damit von selbst, ohne eigene Abfragen.
- Nicht gespeichert (wie der Lakengeist mitten im Auftritt). Debug: F9 bzw. `--pumpkin=dach` (`debug_roof`, Aktion
  `debug_pumpkin`: übers Lobbydach – nicht F8, das stoppt im Editor das laufende Spiel), `--pumpkin=garten`
  (`debug_garden`: gleich an den Beeten im Garten), `--pumpkin=jagd[,gast]` (`debug_hunt`, auch übers Dach), `--trace`,
  `--shot-on=pumpkin` (Schlag) bzw. `pumpkin_roof`, `pumpkin_edge`, `pumpkin_leap`, `pumpkin_land`, `pumpkin_lobby`
  (oben angekommen, an der Kante, im Sprung, gelandet, erster Halt in der Lobby); `--pumpkin[=anim]` stellt eine
  Testfigur ohne Verhalten auf (`spawn_in_front_of`).

## 6. Gäste & Soziales

- **`GuestProfiles`**: feste Gäste in `ALL`, erzeugte in `static var generated`; Zugriff immer über
  `GuestProfiles.get_profile(id)`. Alle Profile haben dieselbe Form (Werte, `activities`-Gewichte,
  `dice`, `lines`). Sätze über `guest.line(key)`.
- **`GuestGenerator.make(seed, room, arrived_room)`**: deterministisch aus dem Seed.
  **Achtung:** Die Reihenfolge der `rng`-Aufrufe in `make()` bestimmt, wer der Gast ist. Neue
  Zufallswerte nur **ans Ende** anhängen, sonst werden aus gespeicherten Seeds andere Gäste.
  `name_for(seed)` verlässt sich darauf, dass der Name die **erste** Zufallszahl ist.
- **Aussehen** (Spielkonzept 6.0, „Gastmodelle“): `GuestBody.pick(profile, id)` wählt für erzeugte Gäste einen
  Grundkörper aus `GuestBody.BODIES` passend zu Geschlecht (`GuestGenerator.FEMALE`) und Generation des Vornamens
  (`GuestGenerator.generation()`: `OLD`/`YOUNG`, alle übrigen „mid“; im Profil `gen`, kein Zufall – Spielstände
  bleiben gleich). Fehlt der Körper der Generation, nimmt `pick` den der nächsten (`GENERATIONS`), bei mehreren
  reihum nach der Gastnummer. Kinderkörper (Eintrag mit `age`, 6.13) bekommen nur Kinder (`child` im Profil) – den mit dem
  nächsten Alter –, alle übrigen nur Erwachsene. Ohne passenden Körper (feste Gäste, bis sie
  eigene Modelle haben) bleibt die Klötzchenfigur (`_build_blocks`). Je Gast aus dem Profil: `height_cm`, `width_cm`
  (Breite nur in `WIDTH_LIMIT`, Kopfknochen gegengestreckt; `head` vergrößert ihn nur auf Erwachsenenkörpern),
  `build`, Farben `coat`/`pants`/`hair` als Instanz-Uniforms von `psx_guest.gdshader`
  (färbt nur graue Texel, Farbe × Helligkeit / Mittelwert). **Bewegung:** `walk`/`run` aus der GLB
  (`AnimationPlayer` manuell vorgespult, Tempo nach Laufweite × Größe), im Stand Ruhepose mit Atmen. Die Posen
  in `Guest._pose()`/`_dance_pose()` drehen weiter nur die Pivots `_arm_l`/`_arm_r` (beim Modell unsichtbar);
  `GuestBody` richtet die Oberarmknochen danach aus (`_aim`), außer `_arms_free` (normales Gehen/Stehen).
  Sitzen: Beine angewinkelt, Absenken über `sit_drop()`.
- **`Guest`**: Zustandsautomat (`IDLE, WALK, CARRY_HOME, PLACE_DECO, HARVEST, STEAL, HIDE_GO, HIDING,
  PARTY, TALKING, MINIGAME, DEAD, KNOCK, SHELTER, SLEEP, SHOCKED, GHOSTED`, dazu `FOLLOW, VISIT, ATTACK, STAGGER, DECORATE,
  SEARCH, EAT`; der Zustand wird nicht gespeichert, neue Zustände also einfach hinten anfügen). In `IDLE` wählt `_next_activity()` gewichtet aus
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
  Gäste-Meldung ihn nicht überschreibt. `nights_awake` steht im Spielstand unter `player`. Wer im Rausch
  (`_sleep_drunk` ≥ `BarTap.TIPSY`, höchster Rausch im Bett) ausgeschlafen hat, wacht mit **Kater** auf
  (`hangover` = `HANGOVER_TIME` s, 3.7). Nächte ohne Schlaf machen die Sicht unscharf (`Player._update_sight`,
  siehe Optik).
  Tanzplätze: `LevelBuilder.party_spots` ist ein Sechseckraster mit `DANCE_SPACING` 1,4 m (≈ 1,7 m² je Tänzer)
  über den ganzen Partyraum – 1 m von den Wänden, 0,7 m von Möbeln, nicht in der dunklen Ecke –, von der Mitte
  der Tanzfläche (`party_center`) nach außen sortiert. `Social.free_party_spot(guest)` gibt jedem Gast den
  innersten freien Platz (`_dance_spots`: Gast-ID → Index; belegt, solange der Gast in `PARTY` ist, bei
  `start_party` geleert); Gäste kollidieren nicht miteinander, darum gehen sie in `PARTY` die letzten 0,6 m, an
  denen `_move_to` aufhört, genau auf den Platz.
  **Feiermusik:** `RecordPlayer.TRACKS` = das Original (`""` → `SynthAudio.music`, Walzer) und `party_1/2.mp3`
  (`AudioStreamPlayer` am Plattenspieler, `loop`, × `TRACK_GAIN` × `Settings.music_volume`). Jede Feier
  (`set_playing(true)`) nimmt ein anderes Stück als die letzte, die erste ein zufälliges. Lautstärke rechnet
  `Social._process` wie bisher aus der Entfernung; `synth_track()` entscheidet, ob sie an `Game.audio.music` oder an
  `RecordPlayer.fade_to()` geht. `--trace` zeigt `[Feier] Musik: …`. Nicht gespeichert.
  **Discokugel** (`world/disco_ball.gd`): `LevelBuilder._common_rooms` hängt sie über `party_center`, Mitte auf
  `DISCO_Y` (5,4 m, vom Boden wie von der Galerie aus zu sehen), Schnur bis zur Decke über dem Luftraum. Läuft
  `Social.party_active`, dreht sie sich (`SPIN`) und eine `OmniLight3D` in ihrer Mitte blendet in `DOTS_FADE` s
  ein: `light_projector` = Punktemuster aus `_dot_pattern()` (1024², 900 Punkte, fester Seed, ein paar farbig),
  dreht sich mit; ohne `shadow_enabled` gäbe es keinen Projektor – die Lampe ist nicht in der Gruppe „lamps“,
  `ShadowBudget` lässt sie in Ruhe. Projektorfilter Linear ohne Mipmaps (`project.godot`
  `textures/light_projectors/filter`), mit Mipmaps verschwammen die Punkte zu Flecken. Die Kugel liegt auf
  `LAYER` (Ebene 11), die ihre Lampe auslässt, und wirft keinen Schatten. Material `shaders/psx_mirror.gdshader`
  mit eigenem `light()`: Das Environment spiegelt nichts, darum spiegelt jedes Plättchen je Lampe ein
  Rauschmuster in Spiegelrichtung (Weltkoordinaten, wandert beim Drehen über die Plättchen) × deren Licht und
  blitzt, wo die Lampe selbst im Plättchen steht (`glint_cos`, `glint_energy`); Fugen matt. Ohne Licht bleibt
  sie dunkel. Nicht gespeichert (Drehwinkel egal).
  **Partylampen** (`world/party_lights.gd`, Spielkonzept 7.6): `LevelBuilder._common_rooms` setzt `PartyLights.setup(raum,
  höhe, party_center)` – sechs Strahler (Ecken und Mitte der langen Wände, 0,35 m eingerückt, knapp unter `H`), jeder
  ein Gehäuse mit Linse (unschattiertes `StandardMaterial3D`, Farbe wie das Licht) und `SpotLight3D` ohne Schatten
  (`ANGLE`, `ENERGY`, Reichweite 1,6 × Abstand zur Tanzfläche, `spot_attenuation` 0,4 – die Strahler hängen 8–12 m
  entfernt, mit dem üblichen Abfall kam auf der Tanzfläche kaum Farbe an), auf einen Punkt bis 1,5 m neben `party_center` gerichtet
  (`Basis.looking_at`, die Knoten hängen beim Aufbau noch nicht im Baum). Mit `Social.party_active` blenden sie in `FADE` s
  ein; Farbe aus `COLORS` nach Phase (`HOLD` s halten, `BLEND` s überblenden, je Strahler versetzt), alle `SYNC_GAP` s für
  `SYNC_TIME` alle dieselbe. Nicht in „lamps“, nicht gespeichert.
  **Konfetti** (`world/confetti.gd`, `Game.confetti`, ebenfalls aus `_common_rooms`): `burst(pos, anzahl)` = einmaliges
  `CPUParticles3D` (Schnipsel als `QuadMesh`, Farben über `color_initial_ramp` mit konstanter Interpolation, Dämpfung →
  flattert); nach `LIFETIME` × 0,6 legt `_lay` je `PER_DECAL` Schnipsel ein `Decal` (Strahl nach unten auf Ebene 1, Größe
  `DECAL_SIZE`, Bild aus `_paper_image()` – 128², feste Schnipsel, gedreht) in den Streukreis. Höchstens `MAX_DECALS`,
  nach `DECAL_LIFE` s verblasst (`modulate`). Auf Feiern: zu Beginn `START_AMOUNT` über `party_center`, dann alle
  `PARTY_GAP` s über einem der inneren Tanzplätze; Ende eines großen Schmückens: an der letzten Stelle. Nicht gespeichert.
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
- **Kinder** (Spielkonzept 6.13): `Social._add_families()` macht nach den Erwachsenen `CHILDREN` (4) Kinder – je ein
  anderer erzeugter Erwachsener ist Mama oder Papa (`profile["parent"]`), das Kind wohnt im freien Zimmer am nächsten
  (`_room_near`). Profil aus `GuestGenerator.make_child(seed, zimmer, eltern_id, eltern_profil)` mit eigenem Zufall
  (`make()` bleibt unberührt; Name = erste Zufallszahl, `child_name_for`): `child`, `age` 6–11, `height_cm` 112–148,
  `head` 1,25, Archetyp „Kind“, Schreckreaktion `cling`, Sätze aus `CHILD_LINES` (`{eltern}`/`{eltern_dat}` → Mama
  bzw. Papa, auch `phone_*`), Tagesablauf ohne Bar, 20 % Schach-Wunderkind (`prodigy`, Stärke 0,97).
  `Guest.is_child()`, `parent_guest()`, `is_orphan()`.
  - **Nie Opfer:** `Monster._actors()` ohne Kinder (keine Jagd), `_check_hide_step` behandelt ein Kind im Versteck als
    leer, `Director.on_actor_hid`/`kill_guest` übergehen Kinder, `_max_victims` zählt sie nicht. Sieht ein Kind das
    Monster (`_watch_monster`), merkt es sich `monster`, schreit (Lärm `scream`) und erzählt es (`_tell_grown_ups`).
    Der Lakengeist kommt öfter (`weakness()` + `CHILD_WEAKNESS`), würgt aber nie: `_grab` → `_frighten_child`
    (Schreck `ghost_attack`, `_vanish`). Kinder zählen nicht als Zeugen (`_witness_guests`) und nicht für `all_asleep()`.
  - **Familie:** Bei jedem Schreck schreit das Kind, Mama oder Papa bekommen `CHILD_SCARE_FEAR` Angst, die Eltern und
    Erwachsene in 12 m merken sich `child_saw` und erzählen es als Kinderfantasie (`Social.CHILD_SAW_LINES`). Nach dem
    Schreck (`cling`: klammern, zittern) und nach dem Umrennen rennt es zu den Eltern (`_run_to_parent`). Stirbt der
    Elternteil: Angst 100, das Waisenkind schließt sich dem Spieler an (`_child_approach`, `ORPHAN_FOLLOW`, 240 s).
  - **Verhalten:** trinkt nie (`drink`, Bar; Dialog „Einen Kakao ausgeben“ `_cocoa` statt Runde), kommt immer zu
    Feiern (`start_party`, Einladen), klaut, rempelt, droht und schlägt nicht; tobt (`_romp` mit `CHILD_ROMP`: rennen
    → Lärm `run`, lachen → `laugh` 8 m, auch auf Feiern), schenkt dir ab „nett“ Laub oder eine Kerze
    (`_child_approach`, `CHILD_GIFT`; „Hast du Deko?“ ab „nett“); die Beziehung wandert überall `CHILD_DRIFT`-mal
    schneller zur Mitte. Spieler: Schlagen geht nicht (`Player._try_punch`), Rammen → Eltern −20, Zeugen −6; ein Messer
    schenken → Eltern −20; Mäxchen und Schach nur zum Spaß. Kinder als Zeugen beim Diebstahl petzen (`tattle`, Eltern −10).
  - **Nachtruhe:** `bedtime()` würfelt `SLEEPLESS_CHANCE` (30 %) → `sleepless` für `SLEEPLESS_TIME`: `_night_activity()`
    (Licht aus, Vorhang auf, ans Fenster – dort findet es der Geist; durch den Flur; an Zimmer 13 klopfen über
    `Social.sleepless_visit`). Dialog „Ab ins Bett mit dir“ (`send_to_bed`, Eltern +8). In der Nachtruhe startet
    keine spontane Feier mehr.
  - **Süßes oder Saures:** `Social._update_tricks` (alle `TRICK_COOLDOWN`, Spieler in Zimmer 13, ruhig) schickt ein Kind
    mit Meta `visit = "trick"` zu Zimmer 13 (Besuchsablauf, `why` in `_knock`). Tür auf mit `Item.Kind.SWEETS` in der
    Hand → `_treat` (+12); sonst wartet es `TRICK_WAIT` vor der Tür (Schenken im Gespräch → `on_sweets_given`), dann
    `_trick_prank`: Laub vor die Tür oder 15–30 s später ein Klingelstreich (`PhoneCalls.kid_prank`, Anruf `kid_prank`).
    Süßigkeiten liegen in Kommoden (`Dresser.LOOT`) und bei Edna und Bruno im Vorrat.
  - **Von Tür zu Tür** (`Social._update_rounds`, alle `ROUND_COOLDOWN`, nicht in Nachtruhe, Feier oder bei aktivem
    Monster; Debug `--trick[=kind]`): `start_round(kid)` nimmt bis zu `ROUND_DOORS` Gästetüren im Umkreis
    `ROUND_RANGE` (nicht Zimmer 13, nicht die Eltern; zuerst, wo jemand zu Hause ist). `_rounds[id]` führt die
    Phasen `walk` (Besuchsablauf, `on_visit_arrived` → `_round_arrived`), `knock` (`Game.noise("knock")` alle
    `ROUND_KNOCK_EVERY` s, höchstens dreimal; Untertitel „[Es klopft an Zimmer …]“ im Umkreis von 12 m), `host`
    (`_round_host`: wach, im Zimmer, `IDLE`/`WALK` → geht zu `door_inside`, `_open_doors` öffnet) und `pause`.
    `_round_answer`: Süßes aus dem Vorrat, sonst mit `TRICK_GIVE` (Griesgram `TRICK_GIVE_GRUMPY`) – das Kind
    bekommt `SWEETS` in den Vorrat; sonst Schimpfe (`TRICK_SCOLD_LINES`) bzw. keiner da → `_round_prank`: Laub vor die
    Tür. `_round_done` schließt die Tür nach 2,5 s. `Guest.knock_politely(face)` sieht dabei zur Tür (`_knock_face`).
  - Gespeichert wird nur `parent` in der Gästeliste (Version 22); `sleepless`, Besuche und Süßes oder Saures nicht.
    `--trace` zeigt `[Süßes oder Saures]` und `[Lakengeist] … erschreckt`; die Kinder-IDs folgen auf die Erwachsenen
    (erstes Kind `gast24`).
- **Freitext-Gespräche (Prototyp, Spielkonzept 6.15)** – `guests/guest_chat.gd` (`GuestChat`, statisch) und
  `util/llm_client.gd` (`LlmClient`, Knoten unter `Game`, `Game.llm`): Nur Gäste mit Eintrag in `GuestChat.PERSONAS`
  (Edna, Bruno) bieten im Dialog „Etwas fragen …“ an. `DialogUI.open` ruft `LlmClient.ensure()` – beim ersten Mal sucht er
  in `LlmClient.dir` (Standard `~/llm`, Debug `--llm=pfad`) `llama.cpp/llama-server.exe` und das erste `models/*.gguf`
  und startet den Server mit `OS.create_process` auf `127.0.0.1:PORT` (8137; läuft dort schon einer, wird er übernommen).
  Zustände `off` (Dateien fehlen → keine Option), `starting` (Option „(lädt …)“, gesperrt), `warming` (eine Probeanfrage
  mit langem Prompt, Zeitlimit `WARM_TIMEOUT` 180 s – die erste lange Anfrage nach dem Start dauerte sonst bis über 60 s, danach
  ~0,5 s; auch ein gescheitertes Aufwärmen gibt `ready`), `ready`, `failed` (Server antwortet nicht).
  `_exit_tree` beendet den Server; nach einem harten Abbruch läuft er weiter, gibt aber nach `IDLE_SLEEP` s den
  Grafikspeicher frei (`--sleep-idle-seconds`) und wird beim nächsten Start übernommen. Denken des Modells ist aus
  (`--reasoning off`, `enable_thinking`). **Anfrage:** Systemprompt = Rolle (`PERSONAS.who`, Sätze aus `smalltalk`/`greet`
  als Stilbeispiele, `others`), Regeln, dann der **Faktenzettel** `GuestChat.facts()` – alles aus dem Spielzustand: Datum,
  Zeilen nach Thema beschriftet („Feiern:“, „Monster:“, „Gerücht …“ – sonst überging Gemma die Antwort), Ort (`zone_name_at`), Beziehungswort, Geschenke/Spiele (`deed`), Angst, Rausch, Feier läuft / zuletzt gefeiert
  (`Guest.last_party`, gesetzt in `leave_party`, nicht gespeichert) / eingeladen; vor dem ersten Angriff nur die
  `odd`-Sätze, danach die `monster`-Sätze, Erlebnisse (`experience_line(…, true)` mit „gestern“, `_ago`) und ein
  Gerücht (`report_line` – so unzuverlässig wie beim Reden über das Monster, je Frage neu gewürfelt), Verschwundene.
  Dazu die letzten `HISTORY` Nachrichten je Gast (`_history`, nicht gespeichert). `response_format` mit JSON-Schema
  erzwingt `{"absicht", "antwort"}`, `absicht` aus `INTENTS` (im Prompt mit Beispielen `INTENT_EXAMPLES`), `antwort` nach
  `ANSWER_PATTERN` ohne Anführungszeichen, Klammern und Zeilenumbrüche (Gemma beendete den Text sonst mit „“ und schrieb
  Müll bis zum Tokenlimit; eine feste Länge im Muster bremste die Grammatik auf ein Viertel). Regeln im Prompt: duzen,
  höchstens zwei Sätze unter 30 Wörtern, direkt antworten, nichts erfinden (auch keine Preise oder Zahlen); `shorten()`
  schneidet nach `MAX_SENTENCES` Satzenden ab, gemerkt wird die gekürzte Antwort. **Folgen** (`DialogUI._on_answer`): `plaudern` →
  `_count_chat()` (dieselbe Pause und Tageszählung wie „Plaudern“), `monster` → `_monster_talked()` (Beziehung, Angst,
  das Monster hört mit; vor dem ersten Angriff nur +1), `einladen` → `_invite()`, `beleidigen` → `_insult()` – bei diesen
  beiden ersetzt der Satz des Spiels die Antwort des Modells. Debug `--ask=gast,frage|frage` (setzt `--trace`): Gespräch
  öffnen, Fragen nacheinander stellen, Faktenzettel, Absicht, Antwortzeit und Token/s in die Konsole;
  `--shot-on=answer`. **Modell:** Gemma 3 4B it Q4_K_M (ggml-org, Gemma-Lizenz) – im Vergleich mit Qwen3.5-4B (20.10.,
  11 Fragen aus zwei Spielszenen, je zweimal, gleiche Faktenzettel) besseres Deutsch und klarere Figuren; Qwen erfand
  öfter (Kürbispreise in „Mark“) und baute holprige Sätze. Gemessen (RTX 4060 Laptop, Vulkan-Build b11756): ~2,55 GB VRAM,
  Laden 4–13 s, Faktenzettel ~600–1000 Token in ~0,5–1 s, 50–75 Token/s, Antwort 0,5–2,5 s (mit dem Spiel aus dem Editor auf
  derselben Grafikkarte zeitweise 10–30 Token/s). Für weitere Gäste: Eintrag in
  `PERSONAS`; erzeugte Gäste bräuchten ihn aus Archetyp und Werten.
- **Schmück-Aktionen** (`guests/decorating.gd`, `Decorating`, Kind von Social: `Game.social.decorating`, Spielkonzept 5.9;
  zählen als Spaß für den Kürbismann – `is_crew`, `player_joins`):
  Pause bis zur nächsten Aktion von `GAP_EARLY` (1.) linear bis `GAP_LATE` (31.); `_can_start`: keine Feier, keine
  Nachtruhe (auch nicht in den nächsten 60 s), Monster, Lakengeist und Kürbismann nicht unterwegs, kein Tag des ersten
  Angriffs. `start(gast)` (Debug `--decorate[=gast][,hin]`): ein freier Erwachsener ruft auf, `_find_site` sucht in 30 m
  um seine Wohnung (gleiches Stockwerk) unter Zimmertüren (`_door_site`, nicht 13 und 18) und Flurwegpunkten
  (`_corridor_site`, Wände per Strahl in vier Richtungen, ab drei Wänden „Ecke“) – nur wo `LevelBuilder.in_corridor`, also
  nie Galerie oder Partyraum (Lobby: siehe unten) – die mit den meisten freien Plätzen und der wenigsten Deko in 6 m. Plätze je Ebene:
  `top` (Lichterkette, reicht wie beim Spieler bis zur nächsten Wand, über Türen `door.height` + 0,12), `wall` (Höhe je Art
  `WALL_HEIGHT`), `floor`; frei heißt glatte Wand (`_wall_at`: Ebene 1, keine Tür, an drei Stellen und zwei Höhen) und
  nichts auf Ebene 2/4 im Umkreis (`_space_free`, erfasst Deko, Lampen, Schalter). Mitmacher (`HELPERS` nach Tag, auch
  Kinder): frei (`IDLE`/`WALK`, leere Hände, Angst < 50, nicht betrunken, kein Spaß laut `Social.has_fun`), wohnen in
  `HOME_RANGE`. Jeder macht `TRIPS` Gänge im neuen Gast-Zustand `DECORATE` (`Guest._arrive` → `on_arrived`): `fetch`
  (ins Zimmer, Platz reservieren, Deko aus dem Koffer passend zur Ebene, sonst gebastelt nach `HOMEMADE`; Kürbisse in
  der Lieblingssorte) → `carry` (sichtbar in der Hand zum Platz) → `hang` (`Guest.reach_up`, nach 1,1 s `Item.hang` bzw.
  hinstellen, Besitzer bleibt der Gast) → `admire`; der Rufer wartet danach (`wait`) bis `MIN_TIME`, damit der Spieler
  dazukommen kann. Fällt einer aus (anderer Zustand), wandert die Deko zurück in den
  Koffer; im Gespräch wartet er. Höchstens `LIGHT_STRING_CAP` hängende Lichterketten im Hotel, sonst Fledermäuse.
  Einladung: in Zimmer 13 Anruf (`PhoneCalls.decorate_call`, Art `decorate`, „Ich komme!“ → `on_accepted`), sonst Meldung.
  Spieler: neue Deko mit Besitzer „player“ im Umkreis `SITE_RADIUS` zählt (`_check_player_deco`, alle 0,5 s), sonst
  `PRESENT_TIME` in `PRESENT_RANGE`. Ende (alle fertig oder `MAX_TIME`): Angst − `FEAR_RELIEF`, hat der Spieler
  mitgemacht, Beziehung + `RELATION` (+ je Stück, bis `RELATION_MAX`) und Schock − `SHOCK_RELIEF`, Autosave. Abbruch bei
  Feier, Nachtruhe oder Unruhe (`Director.is_quiet` 30 m, Lakengeist in 20 m); `_update_sleep` schiebt die Nachtruhe
  auf, solange eine Aktion läuft. Nichts davon wird gespeichert – die Deko sind normale Gegenstände (aufgehängt mit
  `hung`). `--trace`: `[Schmücken]` mit Stelle, Mitmachern, jedem Stück und Ende.
  **Lobby:** mit `LOBBY_CHANCE` (oder `start(gast, true)`) `_lobby_site()` – `_wall_site(p, "lobby", 6 m)` von
  `lobby_center`, `lobby_seats` und Lobby-Punkten aus `patrol`; Plätze nur, wo `_in_place` (`in_lobby`, nicht
  Partyraum); Mitmacher wohnen dann in `LOBBY_HOME_RANGE` auf jedem Stockwerk. `_corridor_site` = `_wall_site(p,
  "corridor", 3 m)`; Zimmer: Zimmernummer als `place` (`room_at`).
  **Allein unterwegs** (`_update_solo`, alle `SOLO_GAP_EARLY`…`SOLO_GAP_LATE` nach Tag, höchstens `SOLO_MAX`, nicht bei
  Feier, Nachtruhe, Monster oder jagendem Kürbismann): `start_solo(gast, lobby)` – mit `SOLO_LOBBY` aus dem Koffer in
  die Lobby, sonst ins eigene Zimmer (`_room_site`) mit Deko aus der nächsten passenden `ResourceSpot` (`_source_for`:
  nicht im Keller, keine Spinnweben-Ecken, `_reachable` = NavMesh-Weg ohne verschlossene Tür in 1 m; Vorrat bleibt unberührt, Art nach
  `pool`/`kind`, passend zu einem freien Platz). Eigene Einträge in `_solo` (Stelle je Gast), gleicher Ablauf und
  gleicher Zustand `DECORATE` (`on_arrived` → `_solo_arrived`), kein Spaß, keine Belohnung. Debug
  `--decorate=allein[,gast][,lobby|haus][,hin]` (1,5 s verzögert, das NavMesh muss fertig sein).
  **Dauerhaft (2026-10-21):** Sind weniger als `SOLO_MIN` (1, ab Monatsmitte 2) unterwegs, startet `_update_solo` alle
  4 s einen neuen (`_solo_need`), sonst nach der Pause; `SOLO_MAX` 4. Mit `SOLO_HOTEL` geht das Stück aus dem Koffer
  irgendwohin (`_hotel_site`: 8 zufällige Zimmertüren und Flurpunkte auf allen Stockwerken, beste nach `_score` minus
  Weg/40 m) – so füllt sich das Hotel bis Halloween. Beim Tragen gehen sie mit `SOLO_STROLL` × Tempo
  (`strolls(g)` → `Guest._speed_factor`).
  **Mehrere Aktionen (2026-10-21):** Jede Stelle ist eine `Decorating.Action` (innere Klasse: `site`, `host`, `crew`,
  `helped`, `time`, `known`, `min_time`/`max_time`, `scan`, `group`); `actions` hält alle, `_member` Gast-ID → Action.
  `active` und `site` sind Getter (Nachtruhe, Debug). `group` = `{name, big, by_player, items, present, accepted}` – geteilt
  von allen Stellen eines großen Schmückens; Deko und Anwesenheit des Spielers zählen für die ganze Gruppe, Belohnung je
  Stelle für ihre Mitmacher, Meldung, Schock und Autosave erst, wenn die letzte Stelle der Gruppe endet (`_first_of`).
  Gäste-Aktionen: höchstens `MAX_SMALL` (1, ab Monatsmitte 2) gleichzeitig, Pause `_next_gap` ab dem Start; Stellen
  gleichzeitiger Aktionen liegen `SITE_SPACING` auseinander (`_site_taken` in `_score`). Mitmacher: zuerst Freunde des
  Rufers (`GuestPals.pals_of`, bis `PAL_RANGE`), dann wie bisher (`_helpers_for`). Bei Abschluss merken sich die
  Mitmacher einander (`pals.note_group`).
  **Armvoll:** `_enlist` würfelt `armful` (groß `ARMFUL` 2–3, klein mit `SMALL_ARMFUL` × Fortschritt 2); `on_arrived`
  „fetch“ reserviert je Stück einen Platz, das erste kommt in die Hand, die übrigen (`load`) stapelt `_stack_in_arms`
  eingefroren über der Hand (`set_held(true)` – werden darum nicht gespeichert). Nach dem Aufhängen holt
  `_next_from_load` das nächste in die Hand und geht zum nächsten Platz; `_drop_out` legt alles zurück in den Koffer.
  **Selbst aufrufen:** `call_here(gast, groß)` (Dialog „Wollen wir zusammen …“, `DialogUI._decorate_here`; Debug
  `--decorate=hier[,gast]`) gibt "" oder den Satz des Gastes zurück. Klein: `_site_here(spielerposition)` – nächste
  Zimmertür in `DOOR_REACH` (auch 13, nie 18), sonst Lobby- bzw. Flurwände, mindestens 2 Plätze; je Gast einmal am
  Spieltag (`_called`), `by_player` → ein Mitmacher mehr, gilt als mitgemacht. Groß: `can_call_big()` (≥ `BIG_FRIENDS`
  mindestens „freundlich“, `_big_player_day`) → `start_big(gast, position, true)`.
  **Großes Schmücken:** `start_big(wer, mitte, by_player, lobby)` alle `_next_big_gap` (von `BIG_GAP_EARLY` zu
  `BIG_GAP_LATE`, Fortschritt × `BIG_RAMP`; nicht neben einer anderen großen Aktion, keine kleinen währenddessen).
  Mitte: Lobby (`LOBBY_CHANCE`) oder `_big_center()` (Flurpunkt mit vielen Wohnungen in der Nähe, wenig Deko);
  `_sites_around` bewertet bis zu 28 Türen, Flurpunkte (und Lobbypunkte) in `BIG_RADIUS` auf demselben Stockwerk und nimmt
  die besten `BIG_SITES` mit `SITE_SPACING` Abstand (Zimmer 13 nur, wenn der Spieler aufruft). Gäste: die `BIG_GUESTS`
  nächsten freien (ganzes Hotel), reihum auf die Stellen verteilt, der erste ist jeweils Rufer; `BIG_MIN_TIME`/
  `BIG_MAX_TIME`. Debug `--decorate=gross[,gast][,lobby][,hin]`.
- **Deko-Suche** (`guests/deco_search.gd`, `DecoSearch`, Kind von Social: `Game.social.search`, Spielkonzept 5.9): alle
  `GAP_EARLY`…`GAP_LATE` s (nach Tag) startet ein freier Gast (`Decorating._available`), höchstens `MAX_TRIPS` gleichzeitig,
  nicht bei Feier, Nachtruhe, Monster oder jagendem Kürbismann. `_source_for`: die 5 nächsten `ResourceSpot`s, Mutige
  (`BRAVE`, mit `DANGER_CHANCE`) nur Spinnweben-Ecken und Keller, sonst nur die übrigen; erreichbar über
  `Decorating._reachable`. Mit `PAIR_CHANCE` geht ein Freund (sonst ein Gast in 12 m) mit (`leader` gesetzt). Neuer
  Gast-Zustand `SEARCH` (`Guest._arrive` → `on_arrived`). Begegnet ein allein Suchender dem Spieler (`ASK_RANGE`, sieht und
  erkennt ihn, mindestens „neutral“), fragt er einmal – `has_offer` zeigt im Dialog „Klar, ich such mit!“ (`OFFER_TIME`);
  „Wollen wir zusammen …“ → „… Deko suchen gehen?“ startet sofort (`ask`, danach `lead_off`). Mit dem Spieler
  (`partner` = "player"): ist er weiter als `LAG_RANGE` weg, wartet der Gast (`IDLE`, `_timer` hochgehalten), ab 0,6 ×
  `LAG_RANGE` geht er weiter, nach `LOSE_TIME` s über `LOSE_RANGE` gibt er auf. Am Fundort (`on_arrived`): ein Stück aus
  `pool`/`kind` in die Hand, heim mit `CARRY_HOME` (wandert in den Vorrat); war der Spieler in 1,5 × `LAG_RANGE`, bekommt
  er ein zweites (`receive_item`), Beziehung + `RELATION`, Tat `gifts_from`, `pals.praise(gast, PRAISE)`. Zu zweit:
  `pals.note`. Vorrat der Fundorte bleibt unberührt, nichts gespeichert. Debug `--search[=gast][,mit]`, `--trace`:
  `[Deko-Suche]`.
- **Freundschaften unter Gästen** (`guests/pals.gd`, `GuestPals`, Kind von Social: `Game.social.pals`, Spielkonzept 6.16):
  `counts` = `"id_a|id_b"` (sortiert, `key`) → gemeinsame Taten; `note(a, b)` bzw. `note_group(liste)` (über
  `GROUP_PAIRS` + 1 merkt sich jeder nur `GROUP_PAIRS` zufällige andere). Gezählt wird: Ende einer Schmück-Aktion,
  Deko-Suche zu zweit, Suppe gegessen (`Stove._end_soup`), Gäste-Mäxchen und -Schach (`Social._end_bar_game`/
  `_end_chess_game`), Ende einer Feier (alle in `PARTY`), an der Bar trinken (`Guest._drink_with_someone`: einer, der
  in 3 m steht). `are_pals`: Familie (`parent_guest`), ≥ `PAL_DEEDS` Taten oder Zimmernachbarn (Türen in
  `NEIGHBOR_RANGE`, gleiches Stockwerk – nicht gespeichert, ergibt sich aus dem Hotel). **Weitererzählen**
  (`_update_telling` alle `TELL_SCAN` s): ein Gast mindestens „befreundet“ und ein Freund unter „befreundet“ und über
  „verfeindet“, beide frei (`IDLE`/`WALK`/`PARTY`, Angst < 60) in `TELL_RANGE` → Sprechblase, `change_relation(b,
  TELL_AMOUNT, TELL_CAP)` (neuer Parameter `cap`: Zuwachs höchstens bis 79, also nie „guter Freund“), Antwort 2,5 s
  später; je Paar einmal am Spieltag (`_told`), einer je Durchgang. `heard[b] = a` → `DialogUI.open` hängt
  `take_heard_line` an die Begrüßung. `praise(gast, n)`: alle seine Freunde nach `PRAISE_DELAY` (`_queue`). Gespeichert
  wird nur `counts` (`social.pals`, Version 25); `heard`, `_told`, `_queue` nicht. Debug `--pals=gast1,gast2`, `--trace`:
  `[Freunde]`.
- **Überlebende & Verletzungen** (`guests/wounds.gd`, `Wounds` – nur Daten und Sätze; Zustand im Gast, Spielkonzept 6.17):
  `Wounds.survives()` (`SURVIVE` 0,4) in `MonsterDirector.kill_guest` (nach `wants_victim`: Lärm `scream`,
  `wound_by("scratch", monster)`, `scared_by_monster`, `after_scare` – zählt nicht als Opfer, keine Sättigung) und
  `PumpkinMan._hit` (`wound_by("axe", self)`, Ächzen, `_next_victim`; `_can_hunt` übergeht Gäste mit Axtwunde). Lakengeist:
  `GUEST_ESCAPE` jetzt 0,3 + 0,2 × Mut, beim Losreißen `wound_by("choke")`. `Guest.wound_by(art, angreifer)`: `wound`,
  `wound_left` (`KINDS.heal`), `wound_bed` (`bed`), `_bleeding` (`bleed` – über 60 s jeder Schritt ein Tropfen, sonst jeder
  zweite: die Blutspur der Axtwunde), Angst ≥ 50 (ansprechbar), `wound_facts` (`zone`; `went` = Zone des Angreifers 8 s
  später), `_update_wound_marks` und `_spread_wound_news` (Freunde und Gäste in `SPREAD_RANGE`: Angst + `SPREAD_FEAR`,
  Erlebnis `survivor_<art>` → `Social.experience_line` mit `Wounds.HEARD`). `_wound_step`: Zeiten nach `delta`; solange
  `wound_bed` läuft, geht er ins eigene Bett (`_go_to_bed` → `_fall_asleep`, Licht an außer in der Nachtruhe) und bleibt
  dort (`wake_up` und der `SLEEP`-Zweig warten), `in_sickbed()`: ansprechbar (`get_prompt`/`interact`), `begin_talk`/
  `end_talk` lassen ihn liegen; heiser: alle `WHEEZE_GAP` s `Game.sound_at("wheeze")` (neuer `SynthAudio.VOICES`-Eintrag mit
  eigenem `dir`: `breath.wav` tiefer in seiner Stimmlage), `say` mit „*heiser*“. Geheilt (`_heal`): befreundet und nie
  besucht → `NEGLECT`, `wound_note` für das nächste Gespräch. Wirkung: `_speed_factor` × `speed`, `can_run()` (Axt nicht),
  `weakness` + `CHOKE_WEAKNESS`, nicht verfügbar für Schmücken und Suche (`Decorating._available`), keine Feier im Bett
  (`start_party`). Marken: `GuestBody.attach(knochen)` = `BoneAttachment3D` + Halter, der den Maßstab des Skeletts
  ausgleicht (manche Modelle sind intern in Zentimetern); Kratzer an `Head`/`LeftForeArm`, Verband und Blut an `LeftLeg`/
  `LeftUpLeg`, Ring an `Neck`; Klötzchenfiguren in fester Höhe. **Dialog:** `DialogUI._wound_visit` (besucht, einmal am
  Spieltag `VISIT_HEAL`) erzählt `witness_line()` (nächstes aus `WITNESS`, alles stimmt) statt eines Erlebnisses, danach
  `GREET`; `change_relation` × `RELATION_FACTOR` (auch negativ); `_gift` × `GIFT_FACTOR`, `+FITTING` bei
  `Wounds.fitting`, Tat `gifts_to` × `GIFT_DEEDS`, `GIFT_HEAL`. `GuestChat.facts` kennt die Verletzung und alle Zeugen-Details.
  Gespeichert je Gast (Version 26): `wound`, `wound_left`, `wound_bed`, `wound_facts`, `wound_told`, `wound_visited`. Debug
  `--wound=gast,art[,hin]`, `--kill=gast` (würfelt mit), `--trace`: `[Verletzt]`, `[Losgerissen]`, `[Kürbismann] verletzt`.
- **Geschenke in der Hand** (6.17): `DialogUI._gift` gibt den Gegenstand per `Player.hand_over()` an `Guest.receive_gift`
  (in die Hand, `_gift_hold`); nach dem Gespräch trägt er ihn heim (`_carry_gift_home` → `CARRY_HOME` → Vorrat), Essbares
  (Süßes, gebratener Kürbis) isst er nach ein paar Sekunden (`_gift_step`), im Bett wandert es nach der Zeit in den Vorrat.
  Volle Hände → wie früher gleich in den Vorrat. Nicht zu verschenken: `DialogUI.NO_GIFT` (Schlüssel, Schachbrett,
  Würfelbecher – Hotelgegenstände).
- **Tränen** (Spielkonzept 7.6): `Guest.weep(s)` legt beim ersten Mal ein `CPUParticles3D` an (`top_level`, zwei
  Emissionspunkte an den Augen, × `head` bei Kindern, helle Tropfen mit Schwerkraft); `_tears_step` setzt es jedes Bild auf
  `_head_point()` mit der Drehung des Gastes. Ausgelöst in `shock` (Stil `cry`: Schreckzeit + 20–35 s, `cling`: + 8–14 s),
  `stagger` (umgerannte Kinder), `Social.on_guest_died` (Freunde 20–40 s, Kinder des Toten 60 s). Debug `--weep=gast`.
- **Kochen** (`world/stove.gd`, `Stove`, `Game.kitchen`, Spielkonzept 3.8): `LevelBuilder._common_rooms` setzt ihn auf die
  Plan-Ausstattung „stove“ in der Küche (Höhe `top`, gedreht nach `front`). `phase`: `empty` → (`dish_for(gehalten)`:
  `SOUP_VARIETIES` in den Topf, `ROAST_VARIETIES` und Zierkürbis in die Pfanne) `raw` → Messer in der Hand → `cooking`
  (`SOUP_TIME`/`ROAST_TIME`, Spielzeit über `delta`; Inhalt wippt, Dampf als `CPUParticles3D`) → Braten: Teller
  `Item.Kind.ROAST_PUMPKIN` (Sorte im Zusatzfeld) auf die Pfanne, `empty`; Suppe: `soup` mit `PORTIONS`, nach `COLD_TIME`
  kalt. `raw` mit leeren Händen: Kürbis zurück. `_call_eaters`: die `EATERS` nächsten freien Gäste in `EAT_RANGE`
  (Stockwerk), Plätze vor dem Herd in zwei Reihen (aufs NavMesh gezogen), neuer Gast-Zustand `EAT` (`Guest._arrive` →
  `on_arrived`: Schale nehmen, `EAT_TIME` s zum Herd sehen). Danach Angst − `FEAR_RELIEF`, Beziehung + `RELATION`;
  `_end_soup` (leer oder kalt) → `pals.note_group(_ate)`. Spieler: [E] am Topf einmal je Topf, Schock − `SHOCK_RELIEF`.
  Essen ist Spaß: `is_eating` in `Social.has_fun`, `player_eats` (am Topf, während Gäste essen) in `player_has_fun`.
  Teller: [Linksklick] → `Player.eat_held()` (Schock − `EAT_CALM`); verschenkt (`DialogUI._gift`) zählt die
  Lieblingssorte wie beim Kürbis, Angst − `ROAST_CALM`. Herd und Gäste beim Essen werden nicht gespeichert, der Teller
  schon (Gegenstand). Debug `--cook=suppe|braten[,fertig]`, `--trace`: `[Kochen]`.
- **`Social`** ist der Ort für alles zwischen Gästen und Spieler: Gästeliste (`guests`,
  `living_guests()`, `guest_by_id()`), Beziehungen (`change_relation`), Gerüchte mit Verzögerung,
  Diebstahl mit Zeugen, Reservierung von Verstecken (`find_hide_spot` / `release_hide_spot`),
  Feiern, Herausforderungen (`challenge(guest, game)`, `Guest.challenge_game`), Gäste-Mäxchen und Gäste-Schach
  (`_update_chess_game`, Zuschauen ≥ 30 s → `has_watched_chess`), Berichte über Spuren (`note_trace` → `report_line`),
  Klopfen an Zimmer 13, Zettel, Neuankömmlinge (`START_GUESTS` 67 einschließlich `CHILDREN` 13 Kinder, `MIN_GUESTS` 33;
  Neuankömmlinge sind immer Erwachsene).
- **Detailstufe** (Leistung bei vielen Gästen): Gäste außerhalb des Blickfelds und weiter als `Guest.LOD_RANGE` (15 m)
  bzw. weiter als `LOD_FAR` (45 m) rechnen nur jedes `LOD_STEP`-te (3.) Physikbild – mit der aufgesammelten Zeit, und
  `_move_to` macht entsprechend längere Schritte (`_lod_scale`). Im Gespräch, beim Spiel, gewürgt, taumelnd oder
  angreifend immer voll. Stehende Gäste auf festem Boden rufen kein `move_and_slide` (`_stop`). Gemessen (Lobby,
  Hintergrundfenster): 30 Gäste ~35 fps; 67 Gäste ohne Detailstufe ~22, mit ~29 fps.
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
- **`HotelCat`** (`guests/hotel_cat.gd`, Spielkonzept 6.11, 7.7): sieben Katzen aus `HotelCat.PROFILES`, vier
  davon mit `home` im Katzenraum (starten auf den Kratzbäumen, Nickerchen und Streifzüge mit `HOME_STAY` dort,
  folgen selten, bringen nichts, gehen nicht auf dein Bett), erzeugt in
  `main.gd` nach den Gästen (`place_at_start()`; Lieblingsgast = `hash(id)` über die lebenden Gäste).
  Zustände `IDLE, WALK, SLEEP, FLEE, WAIT_DOOR, PET, FOLLOW, GIFT, FETCH` (holt Gast-Deko, `Social.cat_thefts`), `CARRIED`
  (auf dem Arm: [E] im Zustand `PET` → `pick_up()`, scheue erst ab `CARRY_TRUST` Streicheln; `_carried_step` setzt sie
  jeden Frame vor die Brust des Spielers, Ebene 0, Schock − `CARRY_CALM`/s, Schnurren; `Player.carried_cat` sperrt
  Gegenstände, [G] → `put_down()` (vor einer Wand dichter heran); von selbst nach `CARRY_TIME`, beim Verstecken,
  Schlafen, Würgen, und mit Fauchen/`add_shock` + `FLEE`, wenn das Monster näher als `FEAR_DISTANCE` ist; gespeichert
  zu Füßen des Spielers, Debug `--cat=id,tragen`); Bewegung wie Gäste (NavigationAgent,
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
- **Fingerabdruck der Welt** statt Versionssprung bei jedem Umbau (Entscheidung 19.10.: Kompatibilität alter
  Stände erst spät): `main.gd` ruft nach dem Aufbau `SaveManager.note_world()` – MD5 über Anzahl und Lage
  (auf 10 cm) der Knoten jeder Gruppe in `WORLD_GROUPS`, bei `COUNT_ONLY` (Katzen, Startplatz wechselt) nur
  die Anzahl. Steht als `world` im Spielstand und in `user://saves/world.txt`, damit die Slot-Übersicht ihn
  vor dem Aufbau kennt. `fits(data)` = passende `VERSION` und gleicher Abdruck; nicht passende Stände zeigt
  `SlotList` gesperrt mit „passt nicht mehr zu diesem Hotel“, `newest_slot` (Fortsetzen) übergeht sie. Ist
  `world.txt` veraltet (Code seit dem letzten Start geändert), prüft `main._load_pending` nach dem Aufbau
  erneut und startet bei Abweichung neu mit Hinweis. Neue Gruppe mit Zustand → in `WORLD_GROUPS` eintragen.
- `VERSION`/`MIN_VERSION` nur noch für den Aufbau des Spielstands selbst (Felder in `collect`/`apply`),
  mit Kommentarzeile.
- Gegenstände werden nicht zugeordnet: beim Laden werden alle gelöscht und aus `kind` + `extra`
  (`Item.create_extra()`) neu erzeugt. Neuer Gegenstandszustand → in `create_extra()`/`_build()`
  abbilden oder in `_item_data`/`_make_item` ergänzen.
- Erzeugte Gäste: nur `{id, seed, room, arrived, parent}` (`Social.roster_state` / `restore_roster`; `parent` ≠ "" →
  Kind über `make_child`, ab Version 22 – die Liste steht in Erzeugungsreihenfolge, Eltern also vor ihren Kindern), wird
  **zuerst** angewendet, weil sich alles Weitere auf Gast-IDs bezieht. Danach Welt → Director-Werte →
  Gäste → Gegenstände → Spieler → Soziales → Monster zuletzt.
- Speicherbare Welt-Objekte bieten `save_state() -> Dictionary` / `load_state(d)` (HideSpot, Lamp, HotelPhone,
  LightSwitch, HotelWindow, Dresser) oder werden in `collect()` direkt ausgelesen (Door, Chest, Plant, Resource).
  Neues Objekt mit Zustand: Gruppe + Eintrag in `collect()` und `apply()`.
- Beim Laden: `d.get(key, standard)` verwenden, damit fehlende Schlüssel nicht abstürzen.
- Nicht gespeichert, beim Laden zurückgesetzt (`apply` ganz am Anfang): `Decorating.reset()`, `DecoSearch.reset()`,
  `Stove.reset()` – sonst zeigten laufende Aktionen nach `--savetest` auf die neu gebauten Gäste ins Leere.
- Verletzungen (ab Version 26, Spielkonzept 6.17): je Gast `wound`, `wound_left`, `wound_bed`, `wound_facts`, `wound_told`,
  `wound_visited`; nach dem Laden `_update_wound_marks`, ins Bett geht er von selbst wieder.
- Freundschaften unter Gästen (ab Version 25): `social.pals` = `GuestPals.counts` (`"id_a|id_b"` → Anzahl); ältere
  Stände laden ohne (nur Familie und Nachbarn).
- Je Gast außerdem (ab Version 11) `corpse` (tote Gäste mit Leiche → `die("ghost")`), `ghost_visits`, `seen`
  (gesehene Blutlachen/Leichen) und `experiences` (Zeitpunkte als `Director.elapsed`).
- Speichern am Tagebuch gesperrt bei Jagd oder Monster näher als `NOISE_START`; Autosave nur in
  sicheren Momenten (`is_safe_for_autosave`), sonst aufgeschoben.
- **Prüfen:** `--savetest` sammelt → wendet an → sammelt erneut und meldet Unterschiede – nur nötig, wenn sich
  am Speichern etwas ändert. Einzelne Abweichungen bei Türen oder Katzen sind Bewegung zwischen den beiden
  Sammelzeitpunkten (wechselt von Lauf zu Lauf).

## 8. Weitere Systeme (Kurzüberblick)

| System | Datei(en) | Merkpunkte |
|--------|-----------|------------|
| Licht | `lamp.gd`, `light_switch.gd`, `flicker_light.gd`, `util/shadow_budget.gd`, `level_builder.gd` (`_wall_lamp`, `_candle`, `_halogen`) | Lampe = Fassung + Birne (Item `BULB`; Halogenröhren im UG und Unterwasserlampen im Pool ohne Birne, Abschnitt 4); `flicker` (Nähe des Monsters, kann Birnen durchbrennen) und `wave` (Flackerwelle, 4.17) setzt der Director; nur 12 Lampen werfen Schatten (`ShadowBudget`, alle 0,25 s: Abstand zur Kamera minus Reichweite, wer schon Schatten hat, behält ihn mit 1,5 m Vorsprung). Lampen ohne Schatten scheinen durch Wände – mit nur 6 Schatten tauschten beim Gehen Lampen im Nachbarzimmer bzw. in der Lobby die Plätze, und im Flur ging Licht an und aus (19.10.; kostet gegenüber 6 ca. +0,4 ms GPU, +1,7 ms CPU-Renderzeit); Licht aus → `on_lights_off`. Deckenleuchten nur, wo der Plan sie setzt (`_ceiling_lamp`, Kupferleuchte bzw. Pendel); jeder Raum hat mindestens eine Wandleuchte (`WALL_LAMP_ENERGY`, Lobby ×1,3), sonst schaltet sein Schalter nichts. Zimmer haben zwei hellere (`ROOM_LAMP_ENERGY`, Tür- und Fensterwand) und eine hellere Holzdecke (`_room_ceiling`) als die Flure (`_ceiling`, abgedunkelt). Feste Deko-Kerzen (`_candle`, `CANDLE_ENERGY`, kein Item, nicht gespeichert, in `lamps` → flackern mit) auf Flurkommoden, Bank, Lobby, Theke und Zimmertischen (nicht in dunklen/unbewohnten Zimmern) sind mit den Kürbissen die hellsten Lichter. Wandleuchten und Laternen laufen zusätzlich durch `Lamp.BRIGHTNESS` (Stärke ×1,35) und `Lamp.REACH` (Reichweite ×1,3). Umgebungslicht 0,14 und Mond 0,32 (`main._setup_environment`), damit dunkle Ecken als Umriss bleiben und die Nacht nicht pechschwarz ist. Helligkeit nachjustieren: `BRIGHTNESS`/`REACH` für alle Lampen gemeinsam, sonst die drei Konstanten, die Deckenfarben, Umgebungslicht und Mond |
| Fenster | `hotel_window.gd` | klares Glas / Vorhang (Ebene 10 nur für Sicht & Mond); Milchglas kann die Klasse noch, ist aber nicht mehr verbaut |
| Türen | `door.gd` | Blatt auf Ebene 2 (Glastür 7); Rahmen über `OpeningFrame` (Zarge, Bekleidung, Kopfpartie auf beiden Wandseiten, nur Optik). Spuren über `attach_mark(mark, seite, at)` – Kratzer mittig, Handabdrücke (`Traces.add_door_handprint`) höher; `at` wird mitgespeichert |
| Spuren | `traces.gd`, `trace_mark.gd` | zentrale Stelle für alle Spuren; jede neue Spur → `Social.note_trace`; Fußabdrücke verblassen, Marken bleiben. **Blut an Wänden** (`add_wall_blood(pos, kind)`): sucht in 16 Richtungen in Spurhöhe (`WALL_BLOOD_HEIGHT`) die nächste Wand bis `WALL_BLOOD_RANGE` (2,5 m, Ebene 1, Normale waagrecht) und setzt dort `wall_splatter` (Kern, Spritzer, Läufer – wo das Monster einen Gast holt, `MonsterDirector`, und beim Kürbismann, `Guest.die`) bzw. `wall_smear` (Hand mit vier herabgezogenen Fingerstreifen – Spuk `MonsterDirector._haunt_wall_blood`: mit `WALL_SMEAR_CHANCE` je Spuk-Runde dabei, an einem Patrouillenpunkt im Flur außer Sicht, höchstens `MAX_WALL_SMEARS`, gezählt an den Spuren selbst). Beide sind Schreck-Anblicke wie Blutlachen (`_as_sight`, auch nach dem Laden) und an Zimmer 13 abwischbar; Debug `--wallblood[=smear]` an die Wand im Blick. Die Aschespur des Monsters ist nur Optik (Partikel, `monster.gd`), keine Spur in `Traces` – Gäste erzählen nicht davon |
| Partikel | `shaders/psx_particle.gdshader`, `Mat.particle`, `Geo.particles`; `record_player.gd` (`_build_notes`), `sheet_ghost.gd` (`_build_flakes`), `monster.gd` (`_build_ash`), `level_builder.gd` (`_falling_leaves`, `_leaf_texture`) | Spielkonzept 7.6. Alles `CPUParticles3D` in Weltkoordinaten (`local_coords` aus – Partikel bleiben, wo sie entstanden), quadratische `QuadMesh`, keine Schatten. Der Shader macht das Billboard selbst (`skip_vertex_transform`, Vertex-Snapping wie `psx_surface`) und blendet über das 4×4-Raster aus: Deckkraft = `fade` × `COLOR.a`, `COLOR` = `color` × `color_ramp` (`Geo.particles` legt die Rampe mit `fade_in`/`fade_out` an) × `color_initial_ramp`. Je Partikel liest er `INSTANCE_CUSTOM.x` (Startwinkel, `angle_min/max` 0…360 → Zufallswert: Bild, Farbton, Phase) und `.y` (Anteil der Lebenszeit) – darüber laufen `sway`/`tilt`/`sway_cycles`/`spin` und der Farbton, so steht alles in der Pause. `frames` = Bilder nebeneinander in `albedo_tex`; `rainbow` ersetzt den Farbton der Textur (Startton zufällig, wandert um `hue_drift` je Leben), `brighten` hebt den HSV-Wert, `glow` = Eigenleuchten. `floor_y` (Welt): darunter liegt ein Partikel flach auf dem Boden statt weiterzufallen (Laub; CPUParticles kennen keine Kollision), das Schaukeln läuft auf dem letzten halben Meter aus. **Noten:** `assets/textures/note_1…4.png` (32², rot gemalt, damit der Farbton sauber ersetzt wird) zur Laufzeit zu einem Streifen zusammengesetzt, Emitter an der Trichteröffnung (`HORN_MOUTH`), `emitting` = `playing`. **Flocken:** Ring knapp außerhalb des Lakens (Breite aus der Mesh-AABB, ohne die Arme in Z) auf `FLAKE_FROM` der Höhe – weiter innen verdeckt sie das Laken, weiter unten die Fensterbrüstung; `fade` folgt `_fade`, `_hide()` löscht alte per `restart()`. **Asche:** eigener Knoten neben dem Monster (`get_parent()`, deferred), folgt ihm auf `ASH_HEIGHT` und sendet, solange es aktiv ist – so bleibt die Spur, wenn es verschwindet. **Laub:** je Baum ein Emitter unter `world` (nicht `root`, das NavMesh liest dort), Kasten in der Krone (`TREE_CROWN` × Höhe), konstante Sinkgeschwindigkeit ohne Schwerkraft, `LEAF_LIFE` reicht für Fall und Liegen; `preprocess`, damit beim Start schon Laub liegt. Neuer Partikeleffekt: `Mat.particle` + `Geo.particles`, Bewegung am Emitter setzen |
| Zettel | `warning_note.gd` | feste Warnungszettel (`warning_notes`, erst nach dem 1. Angriff sichtbar) und Gäste-Zettel (`guest_notes`, max. 30) |
| Kommoden | `world/dresser.gd` | Aus dem Plan (Ebene `Möbel`, `LevelBuilder._furniture`). Drei Schubladen als eigene Körper; interagierbar ist je ein `Dresser.Handle` (leitet mit Index weiter). Hohler Korpus, damit die Physik Gegenstände nicht aus geschlossenen Schubladen drückt. Fund nur beim **ersten** Öffnen einer Schublade (`searched`): leer / Münzen / Gegenstand aus `LOOT`. Beim Auf-/Zuschieben werden die darin liegenden Gegenstände kurz kinematisch eingefroren und mitbewegt (Ausnahme von „nie `freeze` direkt“ – sie liegen nicht in der Hand). Lärm `drawer`. Gespeichert: `open`, `searched` (ab Version 7) |
| Aufgehängte Deko | `item.gd` (`HANGABLE`, `hang`, `_sway`, `_build_sheet_ghost`, `_build_strand`), `player.gd` (`_hang_spot`, `drop_held`), `guest.gd` (`door_hang_spot`), `monster_director.gd` (`deco_unrest_at`) | Spielkonzept 5.6. [G] auf eine Wand (Strahl Ebene 1, Normale fast waagerecht) hängt auf statt abzulegen; der Prompt zeigt „… aufhängen [G]“ bzw. „Herbstlaub verstreuen [G]“. Lakengespenst: Haken 1,6–2,5 m über dem Boden, Kopf an der Wand (`GHOST_DEPTH`). Lichterkette: Linie 1,7–2,5 m, reicht nach beiden Seiten bis zur nächsten Wand oder Tür (Strahl Ebene 1+2), höchstens 3 m, Bögen mit `STRING_SAG`, ein `FlickerLight` ohne Schatten (Meta `no_shadow` → `ShadowBudget` überspringt es) in Gruppe `lamps` – flackert also wie die Lampen; die Birnen folgen dessen Helligkeit. Gäste hängen eigene Deko an die Flurseite ihrer Tür (`door_hang_spot`: Lichterkette über, Gespenst/Spinnweben neben der Tür), auch die Start-Deko (`Social._spawn`). `own_deco_near_door` und der Tagebuchsatz messen waagerecht. **Unruhe** `deco_unrest_at(p)` 0..1: Monster linear von `DECO_UNREST_RANGE` (16 m) bis 3 m, Flackerwelle × 0,6, Lakengeist bis `DECO_UNREST_GHOST` (10 m) × 0,75; jeder hängende Gegenstand fragt alle 0,2 s, schwingt immer ein wenig (`SWAY.x`) und bei Unruhe gleichmäßiger und stärker (`SWAY.y`), nie in die Wand; seitlich neigt es sich leicht weg von der Quelle (`deco_unrest_source`, `_lean`). Ab `JOLT_UNREST` fällt der Zierkürbis aus den Händen (`drop_pumpkin`, eigener Gegenstand `MINI_PUMPKIN`, Untertitel). `circling_with` (der Lakengeist vor der Tür) lässt Lakengespenster im Takt seiner Hände kreisen (`SheetGhost.hand_phase`). Herkunft: Wäschekiste (Möbel `laundry_box` → `ResourceSpot` `SHEET_GHOST`), Plan-Ausstattung „Dekokiste“ (`deco_box` → `LIGHT_STRING`), Kommoden (`Dresser.LOOT`), Kürbisbeete (`MINI_CHANCE` je Ernte ein Zierkürbis daneben), Vorräte von Mila, Bruno, Edna und manchen erzeugten Gästen (am Ende von `GuestGenerator.make`). Debug `--deco=art[,g]`. **Mehr Deko** (5.7): `BAT_GARLAND` (`_build_bats`, Flügel `_wings` flattern mit der Unruhe), `SPIDER` (`_build_spider`, `_thread`/`_spider` wippen), `BROOM` (lehnt schräg, `BROOM_LEAN` steckt in der Drehung des Körpers; `topple_broom()` ab `JOLT_UNREST`), `SKULL` (`CANDLE_HOLDERS` wie der geschnitzte Kürbis, `extra` `"lit"`, kippt um). `ResourceSpot.with_pool()` gibt abwechselnd verschiedene Arten (Dekokiste: Lichterkette, Fledermäuse, Spinne; alte Deko im Heizkeller, `LevelBuilder._boiler_room`: Totenkopf, Besen, Fledermäuse) |
| Verstecke | `hide_spot.gd` | `occupant` reserviert; `seen_entering` = Todesurteil; `checked` als Spur; `own_bed` = Bett in Zimmer 13 (Schlafen, 4.18); `rattle()`/`burst_open()` für den Lakengeist |
| Ausdauer | `player.gd` (`_update_stamina`, `exertion()`), `monster_director.gd` (`_update_effects`), `util/synth_audio.gd` (`pant`, `_update_pant`) | Spielkonzept 3.1. `stamina` 0..1, nicht im HUD und nicht gespeichert. Rennen (Wert aus dem letzten Frame) zieht `1/STAMINA_RUN_TIME` je Sekunde ab, sonst kommt `1/STAMINA_REST_TIME` dazu (in Bewegung × `STAMINA_WALK_SLOW`). Leer → `winded`: `running` bleibt aus bis `STAMINA_CALM`. `exertion()` = Lautstärke von Herz und Atem (außer Atem 1 → 0 bis zum Beruhigen, sonst leise unter `STAMINA_HINT`); der Director nimmt sie in `heart_target` (× 0,85) und setzt `audio.pant`/`pant_rate` (stumm bei `holding_breath`). Klang: `SynthAudio._update_pant` spielt alle `1 / pant_rate` s einen Atemzug `assets/sound/breath.wav` (aus `temp/audio/345961__hkkit__breath.mp3`, mono, Spitze −6 dB) mit `BREATH_DB`, Tiefe und Tonhöhe leicht gewürfelt; die Lautstärke folgt `pant` laufend, unter 0,02 bricht der Atemzug ab. Untertitel `[Du keuchst]`. **Keuchen verrät:** `is_panting()` (ab `PANT_NOISE_FROM`, nicht beim Luftanhalten) → Lärm `pant` alle `PANT_EVERY` s; `Monster._check_hide_step` × `PANT_FOUND`; `SheetGhost._lurk` merkt es in `_heard_pant` → `PANT_CHANCE` mehr. Luftanhalten verbraucht `breath` × (1 + `WINDED_BREATH_DRAIN` × `exertion()`). F3 zeigt die Ausdauer, `--sprint`/`--winded` zum Prüfen |
| Schritte | `util/footsteps.gd`, `player.gd` (Schrittzähler in `_physics_process`), `guest.gd` (`_leave_traces`) | Reiner Ton, kein Lärm (der läuft weiter über `Game.noise("step"/"run")`, 4.15). `Footsteps` ist ein `AudioStreamPlayer3D` an den Füßen jedes Spielers und Gastes; `step(boden, rennt, kind)` spielt den nächsten Klang aus `SOUNDS[boden]` (abwechselnd linker/rechter Fuß, Tonhöhe ± `PITCH_JITTER`, Rennen + `RUN_DB`, Kinder leiser und heller) × `Settings.effects_volume`, hörbar bis `RANGE` (12 m, ungedämpft durch Wände). Bisher `carpet` (Teppichflure) und `tiles` (Fliesen: Lobby, Küche und alle anderen gefliesten Räume) – Holz und Rasen bleiben stumm, ein neuer Klang ist nur ein Eintrag in `SOUNDS` (Textur dazu in `FLOOR_TEXTURES`). `Footsteps.floor_under(körper)`: Strahl nach unten (Ebene 1), Textur-Id des getroffenen Bodens aus `FLOOR_TEXTURES`, `""` sonst, `"air"` ohne Treffer – auch der Spieler entscheidet damit, ob Gehen Lärm macht (`SOFT_FLOORS`). Spieler: Schritt alle `STEP_LENGTH` (0,75 m), rennend alle `RUN_STEP_LENGTH` (1,3 m), geduckt still; Gäste alle 0,8 m, als rennend gilt > 1,5 × `WALK_SPEED`. `step_carpet.wav` stammt aus `temp/audio/footsteps_carpet.wav` (um 20 dB angehoben, ausgeblendet), `step_tiles.wav` aus `temp/audio/footstep_church.wav` (Stille vorn jeweils weg; mono, Spitze −6 dB) |
| Am Körper | `player.gd` (`_pocket`, `_update_hand`, `set_pockets`), `player/pocket_map.gd` | `Item.goes_to_pocket()` (Kompass, Kartenblatt, Schlüssel außer `HAND_ONLY_KEYS`): `try_pick_up` löscht den Welt-Gegenstand und trägt ihn in `has_compass`/`map_pages`/`keyring` ein – braucht keine freie Hand. Linke Hand (`_left_hand`) für Aktionen `map` (Tab) und `compass` (F), nicht bei `hands_blocked()` oder im Gespräch; `inspecting` halbiert das Tempo. Türen fragen `player.has_key(id)`. Gespeichert unter `player` |
| Kompass | `item.gd` (`Kind.COMPASS`) | Nadel = Feder Richtung Welt −Z (Norden), gestört über `director.threat_at()` und – nur eingesteckt (`pocketed`) – `is_hallucinating()`; der Kompass in der linken Hand ist ein `Item` mit `make_pocketed()` (raus aus Gruppe `items`); liegt in `LevelBuilder.COMPASS_ROOM` |
| Karte | `world/hotel_map.gd`, `item.gd` (`Kind.MAP`, `extra` = Blatt-ID), `player/pocket_map.gd` | `HotelMap.PAGES` = Blätter (id, Titel, Höhenbereich, Geschoss oder eigene Zeichnung); gedruckter EG-Plan aus `assets/maps/eg.json` (neue Zimmer erscheinen von selbst), OG-Blatt aus `og1.json` (ohne die Datei nur die Galerie; ausgelegt wird es an der Rezeption über `CONTENT["lobby"]["map"]`, sobald dort eine Karte im Plan liegt), Kellerskizze von Hand gezittert (das Untergeschoss aus `ug.json`: Wände mit Lücken für offene Türen, verschlossene
zugezeichnet, Heizkeller rot eingekreist). Alle Blätter einmal untereinander in einem SubViewport gerendert → geteilte `ImageTexture` (ohne Grafik: nur Papierfarbe); `HotelMap.material(id)` schneidet per `uv1_offset` aus. `PocketMap` = Blätterstapel in der linken Hand, Schlüsselblatt (`KEYS`) zuletzt; beim Hervorholen oben das Blatt zu `HotelMap.page_at(y)`. Neue Ebene: Eintrag in `PAGES`, Zeichnung in `_draw()`, Blatt im `LevelBuilder` auslegen |
| Kostüme | `guests/costume.gd`, `guest.gd` (`_update_costume`, `_head_point`), `guest_body.gd` (`head_origin`, `head_shrink`) | Spielkonzept 5.9. `Costume.pick(guest)`: ab `FROM_DAY` (25.) fest nach `hash(id + ":kostüm")` – `WEIGHTS` bzw. `CHILD_WEIGHTS` für `sheet`, `witch`, `pumpkin`, `cape`, der Rest unverkleidet; nichts gespeichert, kein Zufall aus dem Spielstand. Guest prüft jede Sekunde (`_update_costume`), im Bett (`SLEEP` + `hiding`) aus. `Costume` hängt unter `_visual` (Skalierung der Klötzchenfiguren aufgehoben): **Laken** = Drehkörper aus `SurfaceTool` (Ringe unter dem Scheitel `eye_height() + 0.12`, `SHEET_SEGMENTS` 12, gewellter Saum bei `HEM` 0,16 m, Vorderseite im Uhrzeigersinn), Augen/Mund als flache dunkle Kugeln vorn (−Z); darunter `GuestBody.head_shrink` 0,6 bzw. Kopf und Arme der Klötzchenfigur aus, `animate(…, arms_free = false)` (Arme hängen, außer beim Tanzen), kein Namensschild. **Umhang** = Box am Rücken (+Z) und gekippter Kragen. **Hut/Kürbis** sind `top_level` und werden in `Guest._animate` nach `body.animate` per `follow(kopf, _visual.global_basis)` auf den Kopfknochen (`GuestBody.head_origin`, Klötzchen: `_head_pivot`) plus `head_lift` gesetzt – aufrecht, damit sie beim Tanzen nicht kippen. Größe über `size` (Scheitelhöhe / 1,8, ab 0,65). Debug `--costumes[=art]` (`Costume.force`: `all` oder eine Art). **Spieler im Laken:** `Item.Kind.BED_SHEET` (liegt auf dem `own_bed`, gesetzt in `LevelBuilder._furniture`); in der Hand `use_item` → `Player.put_on_sheet()` (verbraucht, `set_disguised(true)`, `disguise_count` + 1), `drop` mit leeren Händen → `take_off_sheet()` (neues Laken in die Hand). `Hud.set_disguised` blendet `_sheet_overlay` ein (`shaders/sheet_overlay.gdshader`: Stoff mit Falten, zwei ausgefranste Augenlöcher, `aspect` aus der Größe) – unabhängig vom Versteck-Overlay. `Player.recognized_by(guest)`: verkleidet nur unter `RECOGNIZE_RANGE` (1,5 m). Geprüft in `Social.on_player_took` (wer nur ein Laken sieht → Satz statt Strafe), Feind-Angriff, `_witnesses_of_player` (Schlagen, Rammen), `Guest._wants_to_bump`, Anschließen guter Freunde, `_child_approach`. `Guest._notice_disguise` (alle 0,5 s, einmal je `disguise_count`): Kinder freuen sich, im Dunkeln (`light_at` < `DISGUISE_DARK`) Angst + `DISGUISE_FRIGHT`, sonst „Huch!“; `DialogUi.open` setzt „Wer steckt denn da drunter?“ davor. Gespeichert: `player.disguised` (Version 24). Debug `--disguise` |
| Bar & Rausch | `world/bar_tap.gd`, `player.gd` (`drink`, `_update_drunk`, `_update_sight`, `_drunk_walk`, `_process`), `guest.gd` (`drink`), `dialog_ui.gd` (`_round`), `dice_match.gd`, `monster_director.gd` (`_update_hallucination`) | Spielkonzept 3.7. `BarTap` (Flasche und Glas, Ebene 4, interagierbar) steht mitten auf der Bartheke (`LevelBuilder._common_rooms`): ein Glas kostet `PRICE`, Rausch `drunk` + `DRINK` (0,3), höchstens `ENOUGH`; Schock − `CALM` (Gäste: Angst − 15). Abbau linear über `SOBER_TIME` (300 s für 1,0). Stufen: ab `TIPSY` (2. Glas) angetrunken, ab `DRUNK` (3.) betrunken; `BarTap.sway(drunk)` = 0..1 ab `TIPSY`. **Spieler:** Kopf rollt (`_drunk_roll` in `head.rotation.z`), Blick driftet (`rotate_y`), die Maus läuft über `_look_lag` und folgt in `_process` mit `LOOK_LAG` (30/s nüchtern … 7/s voll), im Gehen `STUMBLE_RATE` × sway je Sekunde ein Stolpern (`shove` zur Seite, Lärm `stumble` 5 m). Betrunken halluziniert man (Director: wie nach einem Todesfall, Rate × (1 + Rausch)). **Verschwommene Sicht** siehe Optik. Kater: Rennen leert die Ausdauer × `HANGOVER_DRAIN`. **Gäste:** kommen sie an der Bar an (`_arrive`, `in_area(…, "bar")`), trinken sie mit `BAR_DRINK` (70 %); angetrunken schwanken sie (`_visual.rotation.z`), grüßen mit „*hicks*“ und erzählen beim Monster-Thema öfter von Spuren (+ 40 % × Rausch). „Eine Runde ausgeben“ (nur an der Bar, 2 × `PRICE`): beide trinken, Beziehung + 5. **Mäxchen:** Bluff des Spielers mit Rausch → Hinweis „Deine Hand zittert“ und + 0,3 × sway Misstrauen; Wahrnehmung eines Gastes × (1 − 0,5 × Rausch), angetrunkene Gäste zeigen ihre Bluff-Gesten auch ohne Zusehen. Gespeichert: `player.drunk`/`hangover`, Gast `drunk` (Version 21). Debug `--drunk=n[,gast]` |
| Wetter | `world/weather.gd`, `shaders/rain.gdshader`, `night_sky.gdshader` (`flash`), `synth_audio.gd` (`rain`, `thunder`), `monster_director.gd` (`on_noise`) | Spielkonzept 7.8. `Game.weather`, erzeugt in `main.gd` mit dem Mondlicht (Knoten „Moon“) und dem Himmel. `kind` CLEAR/RAIN/STORM nach Zeitplan (`CLEAR_EARLY`→`CLEAR_LATE` nach Tag, `SHOWER_TIME`, `STORM_CHANCE`), `intensity` blendet über `FADE`. **Regen:** ein `GPUParticles3D` mit eigenem Partikel-Shader, `DROPS` Tropfen im Kasten ±`HALF_EXTENT` um den Spieler (`center`), jeder fällt bis zur obersten Fläche darunter und beginnt dann oben (`TOP`) neu – die Höhen stehen in einer Dach-Höhenkarte (`_build_roof_rows`: Strahl von oben auf Ebene 1 + Decke je `CELL` 0,5 m über alle Zonen + `MARGIN`, verteilt auf die ersten Bilder, `FORMAT_RF`); vorher regnet es nicht. `amount_ratio` = `intensity`, Fallgeschwindigkeit samt Wind `FALL`. Tropfen mit PS1-Look: `BoxMesh` `DROP_SIZE`; ohne (`_set_drops`, folgt `Settings.psx_look` laufend, neue `amount` startet die Partikel neu) `DROPS_FINE` Quads mit `shaders/rain_streak.gdshader`: längs `FALL` auf `STREAK` gestreckt, quer zum Blick gedreht, nie schmaler als `STREAK_PIXELS` Bildpunkte – wäre er dünner, wird er blasser (Wurzel des Verhältnisses), Enden und Ränder weich, unter `near_fade` vor der Kamera aus. Wolken: `cloud_cover` → `CLOUDS_RAIN`, Mond schwächer. **Gewitter:** `lightning()` alle `LIGHTNING_GAP` s – 2–3 Zuckungen (`_flash`, Abklingen `FLASH_DECAY`): Mondlicht + `FLASH_ENERGY` (Schatten an → Licht nur durch die Fenster), Himmel `flash`; Donner (`SynthAudio` „thunder“, Untertitel) nach `THUNDER_DELAY`, später leiser; danach `masking()` < 1 für bis zu `MASK_TIME` s – `MonsterDirector.on_noise` multipliziert die Lautstärke damit. **Klang:** `SynthAudio.rain` (draußen `RAIN_OUT`, drinnen `RAIN_IN`, `rain_muffle` dumpfer). Nicht gespeichert (nach dem Laden klar). Debug `--weather=klar|regen|gewitter|blitz`, `--shot-on=lightning`, `--trace` (`[Wetter] …`) |
| Lakengeist | `monster/sheet_ghost.gd`, `shaders/psx_ghost.gdshader`, `traces.gd` (`add_window_handprints`) | Spielkonzept 4.18. `Game.ghost`, eigener Knoten neben dem Monster, kein NavMesh und keine Kollision (schwebt durch Glas und Vorhang). Prüft alle 0,5 s `_window_near()`: Außenfenster mit Vorhang, ≤ 7 m, freie Sicht, alle `lamp_fixtures` mit dieser `room_id` aus, Vorhang offen (ab `THROUGH_CURTAIN_FROM` egal). Gewürfelt wird je neuem Fenster (`_last_window`, `SPAWN_CHANCE`) und, solange der Spieler dort bleibt, alle `STAY_EVERY` s erneut (`STAY_CHANCE`, `_stay`); nicht während Rauschen (`player_threat`), nicht in Gesellschaft, nicht im Katzenraum (`LevelBuilder.is_safe`, auch bei Gästen), erst ab Tag `FROM_DAY` (2) oder nach dem ersten Angriff (`_haunting()`, gilt auch für Gäste). Abklingzeit `COOLDOWN` 45 s, Schweben `FLOAT_SPEED`/`INSIDE_SPEED` 1,6/1,1 m/s. `visits` = Stufe (gespeichert unter `ghost`, dazu die Abklingzeit; laufende Auftritte nicht). Zustände `APPROACH → HOVER → ENTER → STRANGLE` (dazu `LURK → FLY_IN` am Schrank), Ende immer über `FADE` (0,5 s, Raster-Ausblenden im Shader statt Transparenz). Spieler: `trance` (macht langsamer, `TRANCE_SLOW`), `gripped` (steht fest), `move_input` (auch im Versteck, solange `gripped`). **Losreißen** (`_struggle`): Balken `_escape`, je Richtungswechsel `ESCAPE_GAIN`, der Griff zieht `ESCAPE_GRIP` je Sekunde ab (ab dem 4. Mal fester), `ESCAPE_TIME` 3 s – erst ab ~6,5 Wechseln/s schaffbar; HUD-Balken `Hud.set_struggle()`. Solange `gripped`, gehen weder [E] noch die Versteck-Zeitgrenze. **Schrank** (`_lost_victim` → `_start_lurk`): Versteckt sich der Spieler in einem Schrank, wenn er ohnehin hereinkäme (ab `ENTER_FROM`, im Flur), wartet er `LURK_TIME` vor `check_point` und rüttelt (`HideSpot.rattle()`). Kommt der Spieler heraus → `ENTER` (packt sofort zu); keucht er (Atem leer) → sofort `FLY_IN`; sonst Wurf `FLY_IN_CHANCE` (ab `HALL_FROM` `FLY_IN_CHANCE_LATE`, + `FLY_IN_WEAK` × Schwäche, angehaltene Luft senkt sie um bis zu `BREATH_SAVES`). `FLY_IN`: `HideSpot.burst_open()` (Lärm `rattle`, nicht `hide_burst` – lockt das Monster nicht), schwebt an den Hals, würgt im Schrank; losgerissen → `exit_hide()`. Unterm Bett verschwindet er wie bisher. Tod über `Game.game_over` + `director.flash()` + `player_died`. **Klang:** `_ambience` (`AudioStreamPlayer3D` auf Handhöhe) spielt `assets/sound/ghost_ambience.mp3` in Schleife, solange er sichtbar ist – Lautstärke `AMBIENCE_DB` + `_fade` × `Settings.effects_volume` (blendet mit Erscheinen/`FADE` ein und aus), räumlich ungedämpft bis `AMBIENCE_UNIT` (4 m), stumm ab `AMBIENCE_RANGE` (30 m); jeder Auftritt beginnt an zufälliger Stelle, im Pausenmenü pausiert er mit dem Baum. Stopp in `_hide()`, nach dem eigenen Würgetod mit dem Sterbebildschirm, bei einem Tod durchs Monster sofort. Knochen werden pro Frame aus der Ruhepose gedreht (`_pose`: Schweben, Saum, Handkreisen, Krallen). Weiße Flocken vom Saum: `_flakes` (siehe Partikel). Flur: ab `HALL_FROM` (6.) Mal, nur wenn `Social.all_asleep()` und der Spieler in einem Flur steht (`_in_hall` → `LevelBuilder.in_corridor()` – nach dem Grundriss; die Flurnamen in `eg.json` schreiben „…flur“ klein, eine Namensprüfung auf „Flur“ traf nie), `HALL_CHANCE` je Sekunde; taucht an einem Patrouillenpunkt 8–16 m entfernt außer Sicht (auch keines wachen Gastes) auf und kommt gleich auf ihn zu, gibt auf ab `HALL_GIVE_UP` (20 m) Abstand. **Schwäche** (`Player.weakness()`, `Guest.weakness()`, 0..1, `_weakness(victim)`): Fensterchance (Spieler und Gäste, `_spawn_chance(victim)`) und Bleibe-Chance + `WEAK_CHANCE` × w, Abklingzeit `COOLDOWN / (1 + WEAK_FASTER × w)` (Schwäche des letzten Opfers), Flurchance × (1 + `WEAK_FASTER` × w), ab `WEAK_HALL` (0,66) auch vor dem 6. Mal, ab `WEAK_SURE` (1,0) sicher im Flur, sobald kein wacher Gast den Spieler sieht – auch ohne Nachtruhe; Zeugen vertreiben ihn trotzdem. Spieler: `nights_awake / WEAK_NIGHTS` (3) + `drunk × WEAK_DRUNK` (betrunken = ganz schwach) + `shock × WEAK_SHOCK` + Trauer (`director.grief / GRIEF_TIME` × `WEAK_GRIEF`) + `WEAK_HANGOVER` bei Kater – zwei Nächte ohne Schlaf ergeben wie früher den Flur, drei sicher. Gast: `fear / 100 × WEAK_FEAR` + `drunk`. Mit `--trace` stehen Rausch und Schwäche in der Zustandszeile. **Gäste als Opfer** (6.12): `_victim` (Player oder Guest), `_stage` = Zähler des Opfers (`visits` bzw. `Guest.ghost_visits`); `_check_guests()` würfelt wie beim Spieler je neuem Fenster pro Gast (`_guest_windows`), Augenpunkt `Guest.eye_height()`. Der Gast sieht ihn (`_guest_sees_me` → `shock("ghost", …, entranced)` ab Hypnose-Stufe: bleibt stehen), `ghost_grab()` → `GHOSTED`, Losreißen nach Zufall (`GUEST_ESCAPE`: 5 % + 20 % × `brave`), sonst `_kill_guest()`. Bei Gästen zählt der Spieler als Zeuge (außer `debug_ignore_player`); Zeugen, die ihn vertreiben, erschrecken. **Debug** (F6, `--ghost=…`, Konsole `ghost`): `debug_summon(n)` lässt ihn ohne Sprung sofort (`_appear`, ohne Würfel und Reichweite) ans nächste Außenfenster mit Vorhang von `room_at(Spieler)` kommen – Licht aus, Vorhänge auf (ab 4 zu), Blick dorthin; `debug_summon_hall()` legt alle Gäste ins Bett und setzt ihn im Flurabschnitt des Spielers Richtung dessen weitesten Wegpunkts, höchstens `DEBUG_HALL_DISTANCE` (19 m) entfernt. Ohne Fenster bzw. Flur nur `Game.say()` (Rückgabe false). Ein laufender Auftritt wird dabei abgebrochen (`_debug_reset`). **Vor der Tür** (Spielkonzept 5.6, Zustand `DOOR`): `_check_doors()` (vor Fenster und Flur, alle 0,5 s) sucht aufgehängte Lakengespenster bis `DOOR_DECO_RANGE` an einer geschlossenen Zimmertür, hinter der jemand Waches ist (`_door_victim`: Spieler per `room_at`, sonst ein Gast, der dort wohnt). Chance `DOOR_CHANCE` je Gespenst × (1 + Schwäche), nur ungesehen. `_appear_at_door` stellt ihn `DOOR_STAND` vor die Tür (Handhöhe für `Player.EYE_HEIGHT`), zählt den Besuch, setzt `circling_with` an den Gespenstern; `_door_watch`: `DOOR_TIME` (90–150 s) lautlos (`_update_ambience` → 0), Hände kreisen. Spieler drinnen: Blick dreht durch die Wand mit `DOOR_PULL` × (1 + Schwäche) zur Tür (nur Gieren, bis `DOOR_PULL_RANGE`, keine Trance). Gast drinnen: `Guest.door_trance()` – starrt (`SHOCKED` + `_entranced`); nur mit `DOOR_OPEN` + `DOOR_OPEN_WEAK` × Schwäche geht er nach `DOOR_TRANCE` × (1 − ½ Schwäche) zu `door_inside` und öffnet; ist jemand Waches bei ihm (`_company_at_home`), wartet er weiter, ein Gespräch holt ihn heraus. Tür auf oder Opfer im Flur näher als `DOOR_GRAB_RANGE` → `ENTER` (mindestens Stufe `ENTER_FROM`) – dann hört man ihn. Gäste vertreiben ihn vor der Tür erst ab `DOOR_WITNESS_RANGE` (6 m), der Spieler wie sonst. Debug `--ghost=tür [--answer]`, `--shock=id,tür`. Noch nicht: Einstellung für den Blickzug |
| Kürbismann | `monster/pumpkin_man.gd` | Spielkonzept 4.19, Verhalten siehe 5 („Der Kürbismann“). Zusätzlich Testfigur ohne Verhalten: `PumpkinMan.spawn_in_front_of(player, anim)` (Debug `--pumpkin[=anim]`) stellt sie `DISTANCE` (2,5 m) vor den Spieler (Gruppe `pumpkin_men`) und spielt die Animation in Schleife (`chicken` → `dance_chicken`). Material `Mat.model(…, two_sided)` – die Jackenfetzen sind einseitig |
| Kürbissorten | `world/pumpkin_kinds.gd`, `item.gd` (`variety`, `_pumpkin`, `can_carry`, `can_carve`), `pumpkin_plant.gd`, `guest.gd` (`favorite_pumpkin`, `stock_item`, `_ripe_plant`), `dialog_ui.gd` (`_gift`) | Spielkonzept 5.8. `PumpkinKinds.DATA` je Sorte: Form (`round`/`flat`/`bottle`/`turban`), Farbe, Maße, tragbar, beide Hände, schnitzbar, Deko, Preis, Wachstum, Masse, Leuchtfarbe geschnitzt. Die Sorte steht im Zusatzfeld des Gegenstands (`"hokkaido"`, geschnitzt `"casper,unlit"`; leer = Halloween) – kein neues Speicherfeld, alte Stände laden als Halloween-Kürbis. Pflanzen bekommen sie aus dem Plan (Art `pumpkin_plant:<sorte>`); der Riese (`carry` false) landet beim Ernten neben dem Beet (`harvest` gibt null) und wird nicht getragen (`interact` ohne Aufheben). Geschnitzt: Deko × `deco`/10 (`_variety_deco`). Lieblingskürbis fest aus der Gast-ID (`favorite_of`, ohne Zufallsaufruf in `GuestGenerator`). Neue Sorten nur hinten an `ORDER` anfügen |
| Taschenlampe | `world/flashlight.gd`, `world/uv_mark.gd`, `item.gd` (`FLASHLIGHT`, `BATTERY`, `UV_FILTER`) | `Flashlight` hängt als Kind am Item (`item.flashlight`), Zustand steckt in `create_extra()` (`"c=0.42;uv;m=uv;on"`), also kein eigener Speicher-Eintrag. Bewusst **ein `SpotLight3D` außerhalb von `light_source`** – zählt nicht für Helligkeit/Abschreckung (`light_at` castet ohnehin auf `OmniLight3D`) und nicht als `item.lit` (sonst bläst das Monster sie aus, Gäste tropfen Wachs …). Auffälligkeit über `flashlight.carried_conspicuity()` in `Senses.conspicuity`. Nur in der Hand des Spielers: UV prüft alle 0,1 s die Gruppe `uv_marks` (Kegel + Sichtlinie `SIGHT_MASK`, `UvMark.shine()`) und jeden Frame das Monster (`can_be_repelled_by_uv`, Brust im Kegel) → nach `director.uv_repel_time()` `on_monster_uv()`. Einsetzen von Batterie/UV-Aufsatz in `Item._fitting_prompt/_fit` (nur eigene oder herrenlose Teile). `UvMark`: Leuchtschrift (`setup_text`, im LevelBuilder `_uv_writing`) oder Kästen (`add_box`, Nachglanz der Fußspuren in `Traces`); läuft nur, solange es leuchtet. Warnungszettel: `NOTES[id]["uv"]` |
| Kalender | `calendar.gd` | statische Datumsfunktionen + Abreißkalender in Zimmer 13 |
| Telefone | `world/hotel_phone.gd`, `guests/phone_calls.gd`, `ui/phone_ui.gd` | `HotelPhone` auf jedem Zimmertisch (nicht Wäscherei) + Haupttelefon an der Rezeption (`room_id` `"lobby"`, Nummer `"0"`); gespeichert wird nur `off_hook` (Gruppe `phones`, ab Spielstand-Version 5). `PhoneCalls` (`Game.phones`) hat die Anrufe: eingehend nur für Zimmer 13 (warnen/lügen/plaudern/unheimlich), ausgehend per Wählseite, ferne Telefone als Atmosphäre. Jedes Klingeln = `Game.noise("phone", …)`. Telefonsätze in `PhoneCalls.LINES`, eigene als `"phone_<key>"` nur in den festen Profilen – **nicht** in `GuestGenerator.COMMON` (verschiebt die Zufallsfolge). Unheimliche Anrufe hinterlassen einen Hörer neben dem Apparat im Herkunftszimmer. Laufende Anrufe werden nicht gespeichert |
| Mäxchen | `minigames/` | `Maexchen` = Regeln, `DiceMatch` = Partie & Gast-KI, `GameTable` = Tisch; Würfeln macht Lärm (`dice`). Einsätze über `TableStakes` (auch Schach: `place`, `take_for_player`, `give_to_guest`, `abandon`, `split` bei Remis) |
| Schach | `minigames/chess*.gd`, `tests/chess_*.gd` | Spielkonzept 6.10. `Chess` = Regeln als reine Daten (Felder 0–63, Züge als Bitfeld, deutsche Notation, Perft). `ChessAI` = Alpha-Beta + Ruhesuche, Bewertung Material + Feldboni; rechnet in einem `Thread` (`think` / `is_done` / `take_move`, `cancel` beim Abbruch). Stärke aus `profile["chess"]["skill"]`: Tiefe 1–3 (`ChessMatch.depth_of`), Patzer 45 %→5 % plus Angst (`blunder_of`). `ChessMatch` (CanvasLayer 15) = Partie wie `DiceMatch` (Spieler Weiß, Gast überlegt mind. 1–2,6 s, gibt ohne Stolz bei < −900 auf, nimmt Remis an, wenn er nicht klar besser steht), `ChessBoardView` = Brett von oben mit Mausbedienung, `ChessTable` (erbt `GameTable`) in der Lobby, Brett = `Item.Kind.CHESS_BOARD`. Gäste: `profile["chess"]` = {likes, skill, pride}; bei erzeugten Gästen am Ende von `GuestGenerator.make()` gewürfelt, Sätze `chess_*` je Typ aus `CHESS_LINES`. Tests: `-s res://tests/chess_perft.gd` (Zuggenerierung), `-s res://tests/chess_ai_speed.gd` (Zeit je Tiefe, Matt in 1) |
| UI | `ui/` | `UiKit` = Meldezettel-Optik für Menüs; `Hud` Prompt/Meldungen/Debug (F3), Bilder pro Sekunde (F10/`--fps`, `Engine.get_frames_per_second`, alle 0,25 s); `Menus` pausiert; `TeleportUI` = Debug-Teleport (F6), Ziele in `_destinations()` aus dem `LevelBuilder` (`find()` für `--tp`: erstes Wort genau, sonst Namensanfang); Räume ohne festen Standpunkt (Partyraum, Westflügel, Flur oben, Katzenraum, Bibliothek, Kellergang, Technikraum, Wäscherei unten) über `_zone()` aus `LevelBuilder.zones` (in Fluren Blick zur nächsten gleichnamigen Zone), danach rückt `_onto_navmesh` den Spieler auf den nächsten begehbaren Punkt (Zonenmitte kann in Möbeln liegen; wartet beim Start auf die erste Synchronisierung der Karte), Einträge ohne Standpunkt (`null`) springen nicht, sondern führen nur ihre Aktion aus (Lakengeist am Fenster bzw. im Flur, wo man steht); `DebugConsole` ([^]/F1, nur Debug-Build oder `--debug`) = Startparameter im Spiel tippen: `submit()` → `main.run_debug("--name=wert")`, Aktion schließt die Konsole, Auskunft (`help`, `guests`) und Fehler bleiben stehen; Verlauf als `static var` |
| Optik | `util/mat.gd`, `shaders/` | Materialien immer über `Mat.psx(...)` (Vertex-Snapping über Shader-Global `psx_snap`); flache Auflagen auf anderen Flächen (Teppich, Türkassetten, Rahmen mit kleinerem `pull`) über `Mat.layer(...)`, sonst flimmert die Unterlage durch. `Geo.box` unterteilt Flächen in ≤ 1-m-Stücke, damit große Böden beim Snapping nicht schwimmen. Glasscheiben sind einzelne Flächen (`QuadMesh`), keine Boxen; Poolwasser hat einen eigenen Shader (`psx_water.gdshader`: Snapping wie `psx_surface`, ohne Textur, Wellen und Schaum siehe Pool in 4, etwas Glanz); poliertes Metall = `Mat.metal(farbe)` (`psx_metal.gdshader`, Pool-Handläufe, Standard Edelstahl): spiegelt einen gedachten Raum in Spiegelrichtung (Boden dunkel, Streifen am Horizont hell, Decke mittel) nur so hell, wie jede Lampe ihn beleuchtet, dazu ein scharfer Glanzpunkt der Lampe in Metallfarbe – das Environment spiegelt nichts, SSR taugt für dünne Rohre nicht; ohne Licht bleibt es dunkel (wie die Discokugel, `psx_mirror`); Post-FX (`shaders/psx_post.gdshader`, `CanvasLayer` 5 unter der Bedienoberfläche ab Ebene 10): Gamma, Dithering, Rauschen, Flackern. **Verschwommene Sicht** (Spielkonzept 3.6/3.7): `Player._update_sight` (in `_update_drunk`, also nach Spielzeit) setzt `sight_blur` (0..1) = Müdigkeit `nights_awake / WEAK_NIGHTS` × `SIGHT_TIRED` (0,7) in Schüben (× 0,55…1, Periode ~14 s) + Rausch ab `SIGHT_DRUNK_FROM` (0,25) bis `BarTap.ENOUGH` hoch 1,5 (2. Glas ≈ 0,4, 3. Glas 1), pulsierend × 0,75…1 + `SIGHT_HANGOVER` bei Kater; `sight_warp` = `BarTap.sway(drunk)`. Beide folgen mit `SIGHT_FADE` (0,5/s). `main._process` reicht sie als `blur`, `warp` und `blur_time` (= `_sky_time`, steht in der Pause) an den Post-Shader: Scheibe aus 16 Abtastungen (Goldener Winkel), Radius `BLUR_RADIUS` × Bildhöhe, aus einer zweiten Screen-Textur mit `filter_linear_mipmap` und passender Mip-Stufe (weich trotz weniger Abtastungen); `warp` verzieht das Bild in langsamen Wellen und mischt ein blasses Doppelbild dazu. Läuft vor Gamma, Vignette und Farbreduktion, darum mit und ohne PS1-Look gleich; bei 0 liest der Shader wie bisher nur einen Bildpunkt. **PS1-Look aus** (`Settings.psx_look`, Debug `--no-psx`, umgekehrt `--psx`): 3D in Fensterauflösung (`CONTENT_SCALE_MODE_CANVAS_ITEMS`, Bedienoberfläche weiter auf 480 × 270 ausgelegt), kein Snapping/Dithering, `color_levels` 255; Filter-Hinweise lassen sich nicht per Uniform schalten, darum schreibt `Settings._apply_texture_filter` den Code der geteilten Shader in `PSX_SHADERS` von `filter_nearest` auf `filter_linear_mipmap` um (neuer PSX-Shader mit Textur → dort eintragen). Fototexturen (`Mat.photo`, `psx_photo.gdshader`, auch in `PSX_SHADERS`) wechseln zusätzlich die Textur: ohne PS1-Look 1024² mit Mipmaps und Normal Map statt 256² (siehe Assets oben). Die Tapete liest per `texelFetch` und filtert über das Shader-Global `psx_smooth` bilinear von Hand; ihre Glanzkanten bleiben texelgenau. **Spiegelungen** (abschaltbar, `Settings.reflections`): Bildschirmspiegelung (SSR, 128 Schritte) auf allem Glatten – Lobbymarmor, Lack der Tapete, Poolwasser; matte `psx_surface`-Flächen bleiben unberührt (siehe Fototexturen bei den Assets). **Nebel** (`main._setup_environment`): Tiefennebel 4 → 66 m bis Schwarz, Volumennebel nur auf 12 m (sonst verschleiert Lampenlicht das Flurende beige); `camera.far` = 70 m knapp dahinter, weil `player_can_see` am Frustum hängt. **Himmel** (`shaders/night_sky.gdshader`, `Sky` im Modus `REALTIME`): Verlauf, Mond in Richtung von `LIGHT0` (= Mondlicht, Scheibe größer als echt), Wolken als fbm auf einer flachen Ebene (`EYEDIR.xz / y`) mit Silberrand – Dichte einen Schritt weiter zum Mond hin abgezogen –, Sterne aus einem Zellraster auf der Blickrichtung. Rundum eine schwarze **Waldkante** (`treeline`, `treeline_color`) als Höhenlinie über dem Azimut – Hügel aus fbm auf dem Kreis (nahtlos), darauf `tree_count` Nadelbäume als Dreiecke mit eigener Höhe, Breite und Lage, Dichte wechselt; sie liegt im Himmel, also ohne Geometrie und ohne Parallaxe, und verdeckt auch alles unter dem Horizont. Der Zug kommt aus dem Uniform `sky_time`, das `main._process` hochzählt (steht in der Pause, `TIME` liefe weiter); Hash ohne Sinus, damit lange Laufzeiten nicht flimmern. Der Himmel leuchtet nichts aus: Umgebungslicht bleibt Farbe, `reflected_light_source` aus (sonst spiegelte er sich in Tapete und Fliesen), der Strahlungs-Durchgang (`AT_CUBEMAP_PASS`) gibt nur den Verlauf aus; `fog_sky_affect` 0, damit der Tiefennebel ihn nicht schwärzt. Zwei Detailstufen über `psx_smooth`: mit PS1-Look 3 Oktaven, Wolkenebene in Texel gerundet (`psx_texels`), Mondscheibe in Blöcken, Sterne als harte Punkte; ohne zusätzlich verzerrtes Rauschen (Fasern), weicher Rand, Mondflecken, Funkeln – Grundform, Sternorte und Zug sind gleich. **Tapete** = `Mat.wallpaper(wandhöhe, stockwerk, variante)` mit `shaders/psx_wall.gdshader`, neben dem Poolwasser das einzige Material mit Glanz: Das Bild (512², Wandansicht) wird auf 256² verkleinert und in drei Bändern in Metern ab Stockwerksboden (`mod(y, stockwerk)`) aufgetragen – Vertäfelung unten, Rauten (eine 128-px-Wiederholung, `WALLPAPER_FIELD`) dazwischen, Leiste unter `wandhöhe`. Lobby hat ein eigenes Material (5 m, rot); ihre Wand zu Küche und Bar ist per `Mat.wallpaper_split(a, b, normale)` auf der Seite mit Normale +Z teal und 3,5 m hoch – so für jede Wand zwischen zwei Räumen mit anderer Tapete oder Deckenhöhe. Zimmerreihen (`_room_row`): Trennwände und Rückwand ganz beige, Flurwand und die beiden Endwände geteilt (Zimmerseite beige, Normale in Weltkoordinaten); Trennwände beginnen erst in der Flurwand, sonst flimmert ihre Stirnseite im Flur. Aus der Höhenkarte entsteht beim ersten Aufruf eine Oberflächentextur: R = Höhe → Normale aus dem Sprung zum Nachbar-Texel (Glanzkanten, `bump_depth`), G = Glanz je Graustufe (`WALLPAPER_GLOSS`) → Rauheit (`specular_toon`) und Rim-Schimmer. Abgegriffener Sockel: direkt über dem Boden weniger Glanz (`scuff_gloss`). Flecken hat die Tapete vorerst keine – die per Rauschen im Shader gefielen nicht, sie sollen wieder kommen, vermutlich von Hand (Spielkonzept 7.2, offen seit 2026-10-20). Neue Farbvariante: Bild mit gleichem Aufbau als `wallpaper_<name>.png` ablegen; neue Höhenstufe im Bild → Eintrag in `WALLPAPER_GLOSS` |
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
Gäste machen nur beim Rennen (Panik; Kinder auch beim Toben, dazu Lachen `laugh`) Schrittlärm.

**Sichtbarkeit:** `Senses.can_see(beobachter, auge, blick, grundweite, kegel, akteur, bonus, …)`:
Sichtweite = Grundweite × `conspicuity(akteur)` + Bonus, dann Kegel (näher als 2 m ohne Kegel) und
freie Sichtlinie. Auffälligkeit = 1 + 1,2 × Licht am Ort (`light_at(p, skip)` ohne das eigene Licht
in der Hand) + Licht in der Hand (Kerze/Kürbis über `lit`, Taschenlampe über `flashlight`) + Rennen/Stillstehen/Ducken. Benutzt von `Monster.can_see_actor`
(auch für „beim Verstecken gesehen“: `at` = `exit_point` des Verstecks, Stillstehen zählt nicht) und
`Guest.can_see_actor` (Zeugen beim Diebstahl, abgelenkt ×0,6). Unverändert eigene Regeln:
`player_can_see` (Kamera), Gäste sehen das Monster (`_watch_monster`), Licht aus (4.4), Lauschen (4.7),
angehaltener Atem (×0,35) bzw. Keuchen (× `Monster.PANT_FOUND`).

**Debug:** `Game.noise_log` (letzte 5, im F3-Text des Directors), `--trace` druckt jedes Ereignis,
`--noise=art` erzeugt alle 6 s Lärm am Spieler.

## 9. Rezepte

**Neuer Gegenstand:** `Item.Kind` ergänzen (nur **ans Ende**, Spielstände speichern den Zahlenwert),
Preis in `PRICES`, Aussehen/`deco_strength` in `_build()`, ggf. `create_extra()`.

**Neues interagierbares Objekt:** Körper auf passender Ebene (meist 3 = Bit 4),
`set_meta("interactable", self)`, `get_prompt`/`interact`, Gruppe. Platzieren über den Plan: Farbe mit
Namen in die Palette (`Ausstattung: …`/`Möbel: …`), Eintrag in `FITTINGS`/`FURNITURE` von `tools/build_map.py`,
Fall in `LevelBuilder._fittings`/`_furniture`. Hat es Zustand → `save_state`/`load_state` + SaveManager
(Gruppe auch in `WORLD_GROUPS`) + `VERSION` erhöhen.

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
- Nach Änderungen am Speichern (nicht an der Welt): `--savetest` laufen lassen (`alles gleich` erwartet).
- Sonst keine automatisierten Tests – Prüfung über Debug-Parameter, Konsole und Screenshots. Ausnahme Schach:
  `Godot --headless --path . -s res://tests/chess_perft.gd` bzw. `…/chess_ai_speed.gd`. Neue Klassen kennt
  Godot erst nach einem Import (`--headless --import`).

## 11. Export

- Preset „Windows Desktop“ in `export_presets.cfg`, Befehl im README. `binary_format/embed_pck=true` →
  eine einzelne `.exe`; Skripte als Binär-Tokens (`script_export_mode=2`); Ziel `build/` (Git-ignoriert).
- Export-Filter „alle Ressourcen“: alles unter `res://` landet im Paket, außer `exclude_filter`
  (`assets/source/*`, `tools/*`, `build/*`, `temp/*`, `addons/meshy-godot-plugin/*`). Neue reine Arbeitsdateien dort ergänzen.
  `reference/` (Vorlagen, Referenzbilder) hat eine `.gdignore` – Godot sieht den Ordner gar nicht.
- Nur `load()` mit festen `res://`-Pfaden verwenden – zusammengesetzte Pfade findet der Export nicht
  immer, und `res://` ist im Export schreibgeschützt. Alles Veränderliche gehört nach `user://`
  (Spielstände, `settings.cfg`), das im Export unter `%APPDATA%/Godot/app_userdata/Zimmer 13/` liegt.
- Export-Vorlagen müssen exakt zur Editor-Version passen (4.7.2).
- Debug-Tasten und Startparameter sind nicht an `OS.is_debug_build()` gebunden, also auch im
  Release-Export aktiv.
