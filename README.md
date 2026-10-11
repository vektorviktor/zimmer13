# Zimmer 13 – Prototyp

First-Person-Horror im Hotel. Konzept: [SPIELKONZEPT.md](SPIELKONZEPT.md) · Engine: Godot 4.7

## Starten

Projekt im Godot-Editor öffnen (`project.godot`) und mit **F5** starten (Titelbildschirm), oder direkt:

```bash
"/c/Users/vikto/Downloads/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64.exe" --path .
```

## Steuerung

| Taste | Aktion |
|-------|--------|
| WASD / Maus | Laufen / Umsehen |
| Shift | Rennen (macht Lärm → Monster wird neugierig) |
| Leertaste | Springen |
| Strg / C (halten) | Ducken – nötig für die Kellertür (1,80 m) |
| E | Nehmen, Benutzen (Schnitzen, Kerze einsetzen, Ernten), Tür/Truhe öffnen, Licht schalten, Vorhang ziehen, Glühbirne heraus-/eindrehen, mit Gästen reden, Verstecken, ins Tagebuch schreiben |
| 1–9 / Maus | Im Gespräch Antwort wählen (Esc beendet) |
| G / Q | Gegenstand ablegen (Kürbis vor die Tür stellen …) |
| Rechtsklick (halten) | Im Versteck Luft anhalten |
| F3 | Debug: versteckte Monster-Werte |
| F5 | Debug: Monster sofort rufen (wenn es gerade ruht) |
| Esc | Fenster schließen (Gespräch, Tagebuch) bzw. Spielmenü – pausiert das Spiel |

## Was drin ist

- **Hotel (Graybox), zwei Geschosse, 74 Zimmer:** Erdgeschoss mit Lobby (verriegelter Ausgang), Küche, Hotelbar, Garten hinter der Glastür, 78 m Hauptflur mit **drei Flurkreuzungen** und Seitenflügeln (Zimmer 11–28, 31–38, 41–48, 51–56, 61–64), Wäscherei, **Kellertreppe** hinab in den Keller · **Obergeschoss** über das Treppenhaus am Ende des Nordflügels (Zimmer 211–228, 231–238, 241–244, zwei davon verfallen) · nur die nächsten sechs Lampen werfen Schatten (`ShadowBudget`)
- **Kein Inventar:** ein Gegenstand in der Hand; große Dinge blockieren Türen/Truhen; Münzen werden zu Geld
- **Deko & Handwerk:** Kürbisse im Garten ernten · mit dem **Messer** (Küche) schnitzen · **Kerze** in den geschnitzten Kürbis stellen · Herbstlaub unter den Bäumen · Spinnweben in dunklen Ecken · Kerzenvorrat in der Küche
- **Verstecke:** Schränke (auch im Flur) und Betten, Zeitlimit wie in *Doors*, Luft anhalten
- **Dramaturgie:** friedlicher Anfang ohne Monster · erster Angriff am 3./4. Oktober während einer Feier (Licht und Musik aus, das Monster steht in der Lobby) · die ersten zwei Angriffe sind harmlos: es steht direkt vor dir, starrt dich an und verschwindet, Gäste werden nur erschreckt
- **Monster:** streift im ganzen Hotel umher, im Wechsel mit Ruhephasen im Keller (anfangs lang, mit jedem Tag kürzer), weicht deinem Blick aus, biegt in Zimmer ab (wenn keine Deko davor), versteckte Werte Dreistigkeit / Neugier / Abschreckung, Rauschen ab ~20 m (lauter, je näher), Lampen flackern nur in seiner Nähe, „weiß“, wenn man es anstarrt, holt Spieler **und Gäste** aus Verstecken, Jumpscare + Sterbebildschirm, nach einem Gast eine Weile satt, danach Halluzinationen
- **Spuren & Zettel:** Fußspuren (verblassen), Kratzspuren, Blut und Kleidungsstück bei einem Todesfall, Handabdrücke am Milchglas, geprüfte Verstecke, ausgehende Kerzen · Spuren an Zimmer 13 lassen sich wegwischen · Gäste berichten davon (nicht immer zuverlässig) · Warnungszettel früherer Gäste ab dem ersten Angriff · **Spuren der Gäste:** schlammige Schuhabdrücke nach dem Garten, Wachsflecken von Kerzen und Kürbislaternen, Blutstropfen und verlorene Münzen nach einem Angriff, Zettel an Türen und nach Todesfällen oder Sichtungen
- **Klopfen an Zimmer 13:** ein Gast in Panik bittet um Einlass – oder eine bekannte Stimme, hinter der niemand steht
- **Gäste:** Edna, Bruno, Mila plus zufällig erzeugte Gäste (30 zum Start, sechs Charaktere mit eigenen Sätzen und Werten); sinkt die Zahl der Lebenden unter 24, wacht nach einigen Minuten ein neuer Gast in einem freien Zimmer auf · eigener Tagesablauf, Dialog (Plaudern, Monster, Handeln, Schenken, Deko erbitten, Beruhigen, Einladen, Beleidigen, Entschuldigen), Beziehung, Klauen in beide Richtungen mit Zeugen und Gerüchten, Panik & Verstecken, können sterben → Schock/Schuld beim Spieler, Gedenkkerze hilft
- **Mäxchen an der Hotelbar:** Bluff-Würfeln gegen Gäste um Geld oder Gegenstände (Einsätze liegen echt auf dem Tisch), Herausforderungen & Revanche, Gäste würfeln untereinander (zuschauen verrät ihre Ticks), gezinkte Würfel aus Zimmer 17, Abbruch bei Vorwarnung
- **Licht & Fenster:** ein Lichtschalter pro Raum, Decken- und Wandlampen, Glühbirnen herausdrehen und woanders einsetzen (auch Gäste klauen sie), Birnen brennen bei starkem Flackern oder in Monsternähe selten durch · Licht aus lockt das Monster an · Außenfenster mit Vorhängen (Mondlicht, Sicht in beide Richtungen), Milchglas zwischen Flur und Zimmern (nur Umrisse)
- **Kalender:** vom 1. Oktober bis Halloween, ein Ingame-Tag ≈ 5 Minuten, draußen immer Nacht · Abreißkalender in Zimmer 13, Datum im Spielmenü und in den Spielständen
- **Menüs & Speichern:** Titelbildschirm, Spielmenü (Esc), Einstellungen (Helligkeit mit Testbild, PS1-Look, Ton, Maus, weniger Flackern, Untertitel) · Speichern nur am **Tagebuch in Zimmer 13** (3 Slots, nicht während Vorwarnung/Monster) · Autosave bei wichtigen Ereignissen in sicheren Momenten · nach dem Tod letzten Spielstand laden
- **Feiern:** Plattenspieler in der Lobby (selbst ausrichten) oder spontan von Gästen – laut, also lockt es das Monster an; währenddessen sind die Zimmer leer
- **PS1-Look:** 480×270, Vertex-Snapping, Dithering, Farbreduktion
- **Altersempfehlung ab 16** (selbst eingeschätzt, keine USK-Prüfung): Hinweis mit Inhalten beim ersten Start, Kennzeichen im Titelbildschirm (`scripts/ui/title_screen.gd`)

Alle Modelle, Texturen und Sounds sind Platzhalter (prozedural erzeugt) und werden später durch Blender-Modelle (glTF) und echte Sounds ersetzt.

## Debug-Startparameter

Nach `--` an Godot übergeben, z. B. `--path . -- --trace --warn`:

| Parameter | Wirkung |
|-----------|---------|
| `--trace` | Monster, Gäste und Meldungen alle 2 s in die Konsole |
| `--warn` | sofort Vorwarnung → Monster erscheint |
| `--bold=90` | Dreistigkeit setzen |
| `--friend=edna` / `--enemy=bruno` | Beziehung zu einem Gast setzen |
| `--kill=mila` | Gast nach 3 s vom Monster holen lassen |
| `--first-attack` · `--attacks=3` | Feier + erster Angriff nach 3 s · so viele Angriffe gab es schon (> 2: es holt jemanden) |
| `--knock` · `--knock-fake` · `--answer` | Klopfen an Zimmer 13 · falsche Stimme · Spieler öffnet nach 4 s |
| `--party` | Feier starten |
| `--talk=edna` | Gespräch öffnen |
| `--dice=bruno` · `--autoplay` | Mäxchen-Partie starten · Antworten automatisch wählen |
| `--challenge=bruno` | Gast fordert dich heraus |
| `--pos=x,y,z,winkel` · `--monster=x,y,z` | Spieler versetzen · Monster erscheinen lassen |
| `--shot=pfad.png --frames=n` · `--shot-on=reveal` | Screenshot nach n Frames (Standard 120) · kurz nach dem harmlosen Angriff auf den Spieler |
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
                            Traces + TraceMark (Spuren), WarningNote (Warnungszettel)
scripts/guests/             Guest (Verhalten), GuestProfiles (feste Gäste, Sätze), GuestGenerator (Zufallsgäste),
                            Social (Beziehungen, Gerüchte, Diebstahl, Tod, Feiern)
scripts/player/             Player
scripts/monster/            Monster (Zustände), MonsterDirector (Phasen, versteckte Werte, Effekte, Spuk)
scripts/minigames/          Mäxchen: Regeln, Partie (Ablauf, Gast-KI, Einsätze), Würfeltisch
scripts/ui/                 HUD, Dialog, Sterbebildschirm, Titelbildschirm, Menüs (Esc, Tagebuch),
                            Einstellungen, Slot-Übersicht, UiKit (Meldezettel-Optik)
scripts/util/               PS1-Materialien, Platzhalter-Geometrie/-Texturen, Synth-Sound, ShadowBudget
shaders/                    PS1-Oberfläche, Post-Effekt, Versteck-Overlay
```

Tuning-Werte des Monsters stehen oben in `scripts/monster/monster_director.gd`.
