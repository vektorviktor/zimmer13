# Zimmer 13 – Prototyp

First-Person-Horror im Hotel. Konzept: [SPIELKONZEPT.md](SPIELKONZEPT.md) · Engine: Godot 4.7

## Starten

Projekt im Godot-Editor öffnen (`project.godot`) und mit **F5** starten (Titelbildschirm), oder direkt:

```bash
"/c/Users/vikto/Downloads/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64.exe" --path .
```

## Exportieren (eine einzelne .exe)

Einmalig im Editor die Export-Vorlagen für **4.7.2** installieren (*Editor → Export-Vorlagen verwalten → Herunterladen*).
Das Preset „Windows Desktop“ liegt in `export_presets.cfg` (PCK eingebettet, Rohmodelle und `tools/` ausgeschlossen):

```bash
mkdir -p build && "/c/Users/vikto/Downloads/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64.exe" --headless --path . --export-release "Windows Desktop" build/Zimmer13.exe
```

Ergebnis: `build/Zimmer13.exe` (ignoriert von Git), läuft ohne weitere Dateien. Die Debug-Startparameter
funktionieren auch dort (`Zimmer13.exe -- --trace`); die F-Tasten (F3/F5/F6) sind im Export ebenfalls aktiv.

## Steuerung

| Taste | Aktion |
|-------|--------|
| WASD / Maus | Laufen / Umsehen |
| Shift | Rennen (macht Lärm: 10 m statt 0–2 m beim Gehen) |
| Leertaste | Springen |
| Strg / C (halten) | Ducken – nötig für die Kellertür (1,80 m) |
| E | Nehmen, Benutzen (Schnitzen, Kerze einsetzen, Ernten), Tür/Truhe/Schublade öffnen, Licht schalten, Vorhang ziehen, Glühbirne heraus-/eindrehen, mit Gästen reden, telefonieren, Verstecken, ins Tagebuch schreiben |
| 1–9 / Maus | Im Gespräch Antwort wählen (Esc beendet) |
| 0–9 · Enter · Rücktaste · H | Am Telefon: Zimmernummer wählen · anrufen · löschen · Hörer daneben legen (Esc legt auf) |
| G / Q | Gegenstand ablegen (Kürbis vor die Tür stellen …) |
| Rechtsklick (halten) | Im Versteck Luft anhalten |
| Tab (halten) · Linksklick / Mausrad | Kartenblätter ansehen · weiterblättern |
| F (halten) | Kompass ansehen |
| Linksklick · R | Taschenlampe in der Hand: an/aus · normales Licht ↔ UV (mit UV-Aufsatz) |
| F3 | Debug: versteckte Monster-Werte und die letzten Lärmereignisse |
| F5 | Debug: Monster sofort rufen (wenn es gerade ruht) |
| F6 | Debug: Teleport-Liste (Zimmer 13, Lobby, Kompass-Zimmer, Keller …) – pausiert, 1–9 / Maus |
| Esc | Fenster schließen (Gespräch, Tagebuch) bzw. Spielmenü – pausiert das Spiel |

## Was drin ist

- **Hotel (Graybox), zwei Geschosse, 74 Zimmer:** Erdgeschoss mit Lobby (verriegelter Ausgang), Küche, Hotelbar, Garten hinter der Glastür, 78 m Hauptflur mit **drei Flurkreuzungen** und Seitenflügeln (Zimmer 11–28, 31–38, 41–48, 51–56, 61–64), Wäscherei, **Kellertreppe** hinab in den Keller · **Obergeschoss** über das Treppenhaus am Ende des Nordflügels (Zimmer 211–228, 231–238, 241–244, zwei davon verfallen) · nur die nächsten sechs Lampen werfen Schatten (`ShadowBudget`)
- **Kein Inventar:** ein Gegenstand in der Hand; große Dinge blockieren Türen/Truhen; Münzen werden zu Geld · **Ausnahme am Körper:** Kompass, Kartenblätter und Schlüsselbund – Karte und Kompass holt die linke Hand hervor (nicht mit einem Kürbis in den Händen)
- **Kompass:** liegt im verfallenen Zimmer 226 im Obergeschoss · wird eingesteckt, F halten hebt ihn vor die Augen (kein HUD), auch im Versteck · leuchtende Nadel zeigt nach Norden (Nordflügel, Treppenhaus) · in der Nähe des Monsters zittert sie, ganz nah dreht sie sich im Kreis – auch bei Halluzinationen
- **Karte aus losen Blättern:** jedes Blatt einzeln zu finden – Erdgeschoss auf dem Schreibtisch in Zimmer 13, Obergeschoss an der Rezeption, eine handgezeichnete Kellerskizze von 1994 in Zimmer 17 · Tab halten hält die Blätter bildfüllend vors Gesicht, das Blatt der aktuellen Ebene liegt oben, Linksklick/Mausrad blättert · gedruckte Pläne mit Norden oben, allen Zimmernummern, Zimmer 13 rot eingekreist · das letzte Blatt listet den Schlüsselbund
- **Schlüsselbund:** gefundene Schlüssel wandern beim Aufheben an den Bund, Türen lassen sich dann aufschließen, egal was man in der Hand hält · nur der Ausgangsschlüssel an Halloween muss in der Hand getragen werden
- **Deko & Handwerk:** Kürbisse im Garten ernten · mit dem **Messer** (Küche) schnitzen · **Kerze** in den geschnitzten Kürbis stellen · Herbstlaub unter den Bäumen · Spinnweben in dunklen Ecken · Kerzenvorrat in der Küche
- **Verstecke:** Schränke (auch im Flur) und Betten, Zeitlimit wie in *Doors*, Luft anhalten
- **Dramaturgie:** friedlicher Anfang ohne Monster · erster Angriff am 3./4. Oktober während einer Feier (Licht und Musik aus, das Monster steht in der Lobby) · die ersten zwei Angriffe sind harmlos: es steht direkt vor dir, starrt dich an und verschwindet, Gäste werden nur erschreckt
- **Monster:** dürre, über zwei Meter große Gestalt auf zwei Beinen (Modell mit Skelett, ruckartige Stop-Motion-Bewegung) · duckt sich unter Türen, lauert halb geduckt, schleicht auf allen Vieren davon, wenn man es sieht · streift im ganzen Hotel umher, im Wechsel mit Ruhephasen im Keller (anfangs lang, mit jedem Tag kürzer), weicht deinem Blick aus, biegt in Zimmer ab (wenn keine Deko davor), versteckte Werte Dreistigkeit / Neugier / Abschreckung, Rauschen ab ~20 m (lauter, je näher), Lampen flackern nur in seiner Nähe, „weiß“, wenn man es anstarrt, holt Spieler **und Gäste** aus Verstecken, Jumpscare + Sterbebildschirm, nach einem Gast eine Weile satt, danach Halluzinationen
- **Spuren & Zettel:** Fußspuren (verblassen), Kratzspuren, Blut und Kleidungsstück bei einem Todesfall, Handabdrücke am Milchglas, geprüfte Verstecke, ausgehende Kerzen · Spuren an Zimmer 13 lassen sich wegwischen · Gäste berichten davon (nicht immer zuverlässig) · Warnungszettel früherer Gäste ab dem ersten Angriff · **Spuren der Gäste:** schlammige Schuhabdrücke nach dem Garten, Wachsflecken von Kerzen und Kürbislaternen, Blutstropfen und verlorene Münzen nach einem Angriff, Zettel an Türen und nach Todesfällen oder Sichtungen
- **Klopfen an Zimmer 13:** ein Gast in Panik bittet um Einlass – oder eine bekannte Stimme, hinter der niemand steht
- **Zimmertelefone:** Wählscheibentelefon in jedem Zimmer, Haupttelefon mit Gästeverzeichnis an der Rezeption (Zimmernummer wählen, 0 = Rezeption) · Freunde rufen an und warnen, wo es gerade ist (nicht immer richtig), Feinde lügen, Bekannte plaudern oder laden zur Feier ein · manchmal nur Atmen – danach liegt in einem leeren Zimmer ein Hörer neben dem Apparat · selbst anrufen: plaudern, fragen, einladen; **Klingeln ist Lärm** und lockt das Monster ins Zielzimmer · anrufen und sofort auflegen gilt als Telefonstreich · Hörer daneben legen: still, aber keine Warnungen mehr · ab und zu klingelt irgendwo im Hotel ein Telefon
- **Gäste:** Edna, Bruno, Mila plus zufällig erzeugte Gäste (30 zum Start, sechs Charaktere mit eigenen Sätzen und Werten); sinkt die Zahl der Lebenden unter 24, wacht nach einigen Minuten ein neuer Gast in einem freien Zimmer auf · eigener Tagesablauf, Dialog (Plaudern, Monster, Handeln, Schenken, Deko erbitten, Beruhigen, Einladen, Beleidigen, Entschuldigen), Beziehung, Klauen in beide Richtungen mit Zeugen und Gerüchten, Panik & Verstecken, können sterben → Schock/Schuld beim Spieler, Gedenkkerze hilft
- **Mäxchen an der Hotelbar:** Bluff-Würfeln gegen Gäste um Geld oder Gegenstände (Einsätze liegen echt auf dem Tisch), Herausforderungen & Revanche, Gäste würfeln untereinander (zuschauen verrät ihre Ticks), gezinkte Würfel aus Zimmer 17, Abbruch bei Vorwarnung
- **Taschenlampe:** an der Rezeption (halb leer) · Licht zum Sehen, aber kein Schutz – wer sie trägt, wird weiter gesehen · Batterien (Wäscherei, Keller, manche leeren Zimmer, Skeptiker verkaufen sie) einlegen wie eine Kerze in den Kürbis · flackert in Monsternähe, im Versteck bleibt sie aus · **UV-Aufsatz** in Zimmer 18: UV leert eine Batterie in ~9 s; steht das Monster ~1 s im Kegel, flieht es – kommt aber bald wieder, sucht rund um Zimmer 13 und braucht jedes Mal länger · UV zeigt verblasste Fußspuren, Schrift an Wänden und eine zweite Zeile auf jedem Warnungszettel
- **Licht & Fenster:** ein Lichtschalter pro Raum, Decken- und Wandlampen, Glühbirnen herausdrehen und woanders einsetzen (auch Gäste klauen sie), Birnen brennen bei starkem Flackern oder in Monsternähe selten durch · Licht aus lockt das Monster an · Außenfenster mit Vorhängen (Mondlicht, Sicht in beide Richtungen), Milchglas zwischen Flur und Zimmern (nur Umrisse)
- **Kalender:** vom 1. Oktober bis Halloween, ein Ingame-Tag ≈ 5 Minuten, draußen immer Nacht · Abreißkalender in Zimmer 13, Datum im Spielmenü und in den Spielständen
- **Menüs & Speichern:** Titelbildschirm, Spielmenü (Esc), Einstellungen (Helligkeit mit Testbild, PS1-Look, Ton, Maus, weniger Flackern, Untertitel) · Speichern nur am **Tagebuch in Zimmer 13** (3 Slots, nicht während Vorwarnung/Monster) · Autosave bei wichtigen Ereignissen in sicheren Momenten · nach dem Tod letzten Spielstand laden
- **Lärm & Sichtbarkeit:** jedes Geräusch in der Welt ist zugleich Lärm mit eigener Hörweite (Tür knarrt 5 m, Schranktür 4 m, Rennen 10 m, Telefon 18 m, Schrei 20 m, Feier 25 m …), gedämpft durch Wände, geschlossene Türen und Geschossdecken · Schritte hört man nur auf Holz und Fliesen, geduckt gar nicht · das Monster geht in Hörweite nachsehen, bis zur doppelten Hörweite wird es neugierig · Gäste hören Schreie und Knalle mit halber Reichweite: sie erschrecken, sehen nach, erzählen davon oder geraten in Panik · Monster und Gäste sehen nach derselben Rechnung: Licht am Ort, **Licht in der Hand**, Rennen, Ducken, Stillstehen – im Dunkeln und geduckt klaut man unbemerkter, wer mit Kerze in den Schrank steigt, wird gesehen
- **Feiern:** Plattenspieler in der Lobby (selbst ausrichten) oder spontan von Gästen – laut, also lockt es das Monster an; währenddessen sind die Zimmer leer · Gäste tanzen verschieden (hüpfen, wiegen, drehen, Arme hoch, Twist, schunkeln), jeder hat seinen Lieblingstanz
- **Kommoden im Flur:** vier je Geschoss, jede Schublade lässt sich aufziehen – beim ersten Mal liegen manchmal Münzen oder ein Gegenstand darin (Kerze, Glühbirne, Batterie, Messer, gezinkte Würfel); was man hineinlegt, bleibt drin
- **PS1-Look:** 480×270, Vertex-Snapping, Dithering, Farbreduktion
- **Altersempfehlung ab 16** (selbst eingeschätzt, keine USK-Prüfung): Hinweis mit Inhalten beim ersten Start, Kennzeichen im Titelbildschirm (`scripts/ui/title_screen.gd`)

Bis auf das Monster, die Lobby-Sofas, die Flaschen in der Bar und den Plattenspieler sind alle Modelle, Texturen und Sounds Platzhalter (prozedural erzeugt) und werden später durch Blender-Modelle (glTF) und echte Sounds ersetzt. Das Monster-Modell (`assets/models/monster.glb`) baut `tools/build_monster.py` in Blender aus dem Meshy-Original:

```bash
"/c/Program Files/Blender Foundation/Blender 4.3/blender.exe" -b --python tools/build_monster.py -- assets/source/Meshy_AI_Abyssal_Mawcrawler_1011084008_texture.glb assets/models/monster.glb
```

Die Barflaschen (`assets/models/bottles.glb`) und der Plattenspieler (`assets/models/record_player.glb`) entstehen ebenso aus Sketchfab-Modellen:

```bash
"/c/Program Files/Blender Foundation/Blender 4.3/blender.exe" -b --python tools/build_bottles.py -- assets/source/low_poly_pack_alcohol_bottles.glb assets/models/bottles.glb
```

```bash
"/c/Program Files/Blender Foundation/Blender 4.3/blender.exe" -b --python tools/build_record_player.py -- assets/source/vintage_record_player.glb assets/models/record_player.glb
```

Das Katzenmodell (`assets/models/cat.glb`, noch nicht im Spiel) baut `tools/build_cat.py` aus Meshys geriggtem Paket:

```bash
"/c/Program Files/Blender Foundation/Blender 4.3/blender.exe" -b --python tools/build_cat.py -- assets/source/Meshy_AI_Curious_Cat_quadruped.zip assets/models/cat.glb
```

## Debug-Startparameter

Nach `--` an Godot übergeben, z. B. `--path . -- --trace --warn`:

| Parameter | Wirkung |
|-----------|---------|
| `--trace` | Monster, Gäste und Meldungen alle 2 s in die Konsole, dazu jedes Lärmereignis (wer es hört und wie er reagiert) |
| `--noise=door` | alle 6 s Lärm dieser Art am Spieler (`door`, `hide`, `run`, `scream` … – Tabelle in `scripts/util/senses.gd`) |
| `--warn` | sofort Vorwarnung → Monster erscheint |
| `--bold=90` | Dreistigkeit setzen |
| `--friend=edna` / `--enemy=bruno` | Beziehung zu einem Gast setzen |
| `--kill=mila` | Gast nach 3 s vom Monster holen lassen |
| `--first-attack` · `--attacks=3` | Feier + erster Angriff nach 3 s · so viele Angriffe gab es schon (> 2: es holt jemanden) |
| `--knock` · `--knock-fake` · `--answer` | Klopfen an Zimmer 13 · falsche Stimme · Spieler öffnet nach 4 s |
| `--call=edna` · `--call=creepy` / `dead` / `door` · `--answer` | Telefon in Zimmer 13 klingelt: Gast (warnt, wenn das Monster unterwegs ist) · Atmen · Verschwundener · es steht vor der Tür · Spieler nimmt nach 4 s ab |
| `--dial=11` · `--dial=lobby` | aus Zimmer 13 eine Nummer anrufen (0 = Rezeption) · Wählseite am Haupttelefon |
| `--party` | Feier starten |
| `--talk=edna` | Gespräch öffnen |
| `--dice=bruno` · `--autoplay` | Mäxchen-Partie starten · Antworten automatisch wählen |
| `--challenge=bruno` | Gast fordert dich heraus |
| `--pos=x,y,z,winkel` · `--monster=x,y,z` | Spieler versetzen · Monster erscheinen lassen |
| `--flashlight` · `--flashlight=uv` | eingeschaltete Taschenlampe mit voller Batterie in die Hand · mit UV-Aufsatz im UV-Modus |
| `--pocket` · `--show=map` / `keys` / `compass` | Kompass, alle Kartenblätter und Schlüssel 18 einstecken · Karte (Schlüsselblatt oben) bzw. Kompass hervorholen wie mit gehaltener Taste |
| `--shot=pfad.png --frames=n` · `--shot-on=reveal` · `--shot-on=jumpscare` | Screenshot nach n Frames (Standard 120) · kurz nach dem harmlosen Angriff auf den Spieler · im Jumpscare |
| `--nointro` · `--debug` · `--trace-nav` | ohne Intro · Debug-Werte · mit `--trace` auch die Wegfindung der Gäste |
| `--title` · `--new=2` · `--load=1` | trotz Parametern Titelbildschirm · neues Spiel in Slot 2 · Slot laden (0 = Autosave) |
| `--diary=3` · `--savetest` | nach 2 s in Slot 3 speichern · Speichern → Laden → Vergleichen |
| `--menu=pause` | Menü öffnen (`pause`, `diary`, `settings`, `load`, `controls`) |
| `--bulb-thief=bruno` | Gast klaut sofort eine Glühbirne aus Zimmer 13 |
| `--day=31` | zu einem Tag im Oktober springen (ein Tag ≈ 5 min, `Calendar.DAY_SECONDS`) |

Ohne Parameter startet das Spiel mit dem Titelbildschirm; mit Parametern direkt im Hotel.
Für lange Testläufe hilft Godots eigenes `--time-scale 3` (vor dem `--`), z. B. `--path . --time-scale 3 --quit-after 36000 -- --day=3 --nointro --trace`.
Spielstände liegen in `%APPDATA%/Godot/app_userdata/Zimmer 13/saves/`, Einstellungen in `settings.cfg` daneben.
Spielstände älterer Versionen (vor dem größeren Hotel bzw. den Zufallsgästen) werden nicht mehr geladen.

## Aufbau

```
scenes/title.tscn           Einstiegsszene: Titelbildschirm
scenes/main.tscn            das Hotel
scripts/main.gd             baut alles zusammen, Debug-Startparameter
scripts/autoload/game.gd    globaler Zustand, Geld, Tastenbelegung, Szenenwechsel
scripts/autoload/settings.gd       Einstellungen (user://settings.cfg)
scripts/autoload/save_manager.gd   Speichern/Laden, Autosave, Tagebuchsatz
scripts/level/              LevelBuilder (Grundriss: Zimmerreihen in `ROWS`, Flure, Keller, Zonen, Wegpunkte)
scripts/world/              Item, Door (auch Glas), HideSpot, Chest, FlickerLight,
                            PumpkinPlant, ResourceSpot, RecordPlayer,
                            Lamp (Glühbirne), LightSwitch, HotelWindow (Vorhang/Milchglas), Diary,
                            Traces + TraceMark (Spuren), WarningNote (Warnungszettel), HotelPhone (Telefon),
                            Flashlight (Taschenlampe, UV), UvMark (nur unter UV sichtbar)
scripts/guests/             Guest (Verhalten), GuestProfiles (feste Gäste, Sätze), GuestGenerator (Zufallsgäste),
                            Social (Beziehungen, Gerüchte, Diebstahl, Tod, Feiern), PhoneCalls (Anrufe)
scripts/player/             Player
scripts/monster/            Monster (Zustände), MonsterDirector (Phasen, versteckte Werte, Effekte, Spuk)
scripts/minigames/          Mäxchen: Regeln, Partie (Ablauf, Gast-KI, Einsätze), Würfeltisch
scripts/ui/                 HUD, Dialog, Sterbebildschirm, Titelbildschirm, Menüs (Esc, Tagebuch),
                            Einstellungen, Slot-Übersicht, UiKit (Meldezettel-Optik), Telefon
scripts/util/               PS1-Materialien, Platzhalter-Geometrie/-Texturen, Synth-Sound, ShadowBudget,
                            Senses (Lärm & Sichtbarkeit: alle Werte)
shaders/                    PS1-Oberfläche, Post-Effekt, Versteck-Overlay
```

Tuning-Werte des Monsters stehen oben in `scripts/monster/monster_director.gd`.
