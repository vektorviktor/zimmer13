# Zimmer 13 – Prototyp

First-Person-Horror im Hotel. Konzept: [SPIELKONZEPT.md](SPIELKONZEPT.md) · Engine: Godot 4.7

## Starten

Projekt im Godot-Editor öffnen (`project.godot`) und mit **F5** starten, oder direkt:

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
| E | Nehmen, Benutzen (Schnitzen, Kerze einsetzen, Ernten), Tür/Truhe öffnen, mit Gästen reden, Verstecken |
| 1–9 / Maus | Im Gespräch Antwort wählen (Esc beendet) |
| G / Q | Gegenstand ablegen (Kürbis vor die Tür stellen …) |
| Rechtsklick (halten) | Im Versteck Luft anhalten |
| F3 | Debug: versteckte Monster-Werte |
| F5 | Monster sofort rufen |
| Esc | Maus freigeben |

## Was drin ist

- **Hotel (Graybox):** Lobby mit verriegeltem Ausgang, Küche, Hotelbar, Garten hinter der Glastür, Flur mit 8 Zimmern (11–18), Wäscherei, Keller
- **Kein Inventar:** ein Gegenstand in der Hand; große Dinge blockieren Türen/Truhen; Münzen werden zu Geld
- **Deko & Handwerk:** Kürbisse im Garten ernten · mit dem **Messer** (Küche) schnitzen · **Kerze** in den geschnitzten Kürbis stellen · Herbstlaub unter den Bäumen · Spinnweben in dunklen Ecken · Kerzenvorrat in der Küche
- **Verstecke:** Schränke (auch im Flur) und Betten, Zeitlimit wie in *Doors*, Luft anhalten
- **Monster:** feste Patrouillenroute ab dem Keller, biegt in Zimmer ab (wenn keine Deko davor), versteckte Werte Dreistigkeit / Neugier / Abschreckung, Ankündigung (Flackern, Rauschen, Lampen), „weiß“ wenn man es anstarrt, holt Spieler **und Gäste** aus Verstecken, Jumpscare + Sterbebildschirm, nach einem Gast eine Weile satt
- **Gäste (Edna, Bruno, Mila):** eigener Tagesablauf, Dialog (Plaudern, Monster, Handeln, Schenken, Deko erbitten, Beruhigen, Einladen, Beleidigen, Entschuldigen), Beziehung, Klauen in beide Richtungen mit Zeugen und Gerüchten, Panik & Verstecken, können sterben → Schock/Schuld beim Spieler, Gedenkkerze hilft
- **Mäxchen an der Hotelbar:** Bluff-Würfeln gegen Gäste um Geld oder Gegenstände (Einsätze liegen echt auf dem Tisch), Herausforderungen & Revanche, Gäste würfeln untereinander (zuschauen verrät ihre Ticks), gezinkte Würfel aus Zimmer 17, Abbruch bei Vorwarnung
- **Feiern:** Plattenspieler in der Lobby (selbst ausrichten) oder spontan von Gästen – laut, also lockt es das Monster an; währenddessen sind die Zimmer leer
- **PS1-Look:** 480×270, Vertex-Snapping, Dithering, Farbreduktion

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
| `--party` | Feier starten |
| `--talk=edna` | Gespräch öffnen |
| `--dice=bruno` · `--autoplay` | Mäxchen-Partie starten · Antworten automatisch wählen |
| `--challenge=bruno` | Gast fordert dich heraus |
| `--pos=x,y,z,winkel` · `--monster=x,y,z` | Spieler versetzen · Monster erscheinen lassen |
| `--shot=pfad.png --frames=n` · `--nointro` · `--debug` | Screenshot · ohne Intro · Debug-Werte |

## Aufbau

```
scenes/main.tscn            Einstiegsszene
scripts/main.gd             baut alles zusammen, Debug-Startparameter
scripts/autoload/game.gd    globaler Zustand, Geld, Tastenbelegung
scripts/level/              LevelBuilder (Räume, Maße, Zonen, Patrouillenroute)
scripts/world/              Item, Door (auch Glas), HideSpot, Chest, FlickerLight,
                            PumpkinPlant, ResourceSpot, RecordPlayer
scripts/guests/             Guest (Verhalten), GuestProfiles (Persönlichkeiten, Sätze),
                            Social (Beziehungen, Gerüchte, Diebstahl, Tod, Feiern)
scripts/player/             Player
scripts/monster/            Monster (Zustände), MonsterDirector (versteckte Werte, Effekte)
scripts/minigames/          Mäxchen: Regeln, Partie (Ablauf, Gast-KI, Einsätze), Würfeltisch
scripts/ui/                 HUD, Dialog, Sterbebildschirm
scripts/util/               PS1-Materialien, Platzhalter-Geometrie/-Texturen, Synth-Sound
shaders/                    PS1-Oberfläche, Post-Effekt, Versteck-Overlay
```

Tuning-Werte des Monsters stehen oben in `scripts/monster/monster_director.gd`.
