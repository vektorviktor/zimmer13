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
funktionieren auch dort (`Zimmer13.exe -- --trace`); die F-Tasten (F3/F5/F6/F7) sind im Export ebenfalls aktiv.

## Steuerung

| Taste | Aktion |
|-------|--------|
| WASD / Maus | Laufen / Umsehen |
| Shift | Rennen (macht Lärm: 10 m statt 0–2 m beim Gehen; kostet Ausdauer) |
| Leertaste | Springen |
| Strg / C (halten) | Ducken – nötig für die Kellertür (1,80 m) |
| E | Nehmen, Benutzen (Schnitzen, Kerze einsetzen, Ernten), Umgeworfenes aufstellen, Katzen streicheln, Tür/Truhe/Schublade öffnen, Licht schalten, Vorhang ziehen, Glühbirne heraus-/eindrehen, mit Gästen reden, telefonieren, Verstecken, im eigenen Bett schlafen (während der Nachtruhe; geduckt: darunter verstecken), ins Tagebuch schreiben |
| 1–9 / Maus | Im Gespräch Antwort wählen (Esc beendet) |
| 0–9 · Enter · Rücktaste · H | Am Telefon: Zimmernummer wählen · anrufen · löschen · Hörer daneben legen (Esc legt auf) |
| G / Q | Gegenstand ablegen (Kürbis vor die Tür stellen …) |
| Rechtsklick (halten) | Im Versteck Luft anhalten |
| Tab (halten) · Linksklick / Mausrad | Kartenblätter ansehen · weiterblättern |
| F (halten) | Kompass ansehen |
| Linksklick · R | Taschenlampe in der Hand: an/aus · normales Licht ↔ UV (mit UV-Aufsatz) |
| F3 | Debug: versteckte Monster-Werte und die letzten Lärmereignisse |
| F5 | Debug: Monster sofort rufen (wenn es gerade ruht; die ersten zwei Angriffe bleiben harmlos – `--attacks=3` für echte) |
| F6 | Debug: Teleport-Liste (Zimmer 13, Lobby, Kompass-Zimmer, Keller …) und Lakengeist zum 1.–4. Mal (in Zimmer 13) bzw. im Flur – pausiert, 1–9 / Maus |
| F7 | Debug: Monster kommt zu dir, als hätte es dich gehört (ruht es, erscheint es ~25 m entfernt; jedes Drücken lenkt es zu deiner neuen Stelle; harmlos wie bei F5, solange nicht `--attacks=3`) |
| ^ oder F1 | Debug-Konsole: Startparameter im Spiel tippen, ohne `--` (z. B. `shock edna,ghost3`, `tp lobby`, `guests`, `help`) – pausiert, ↑/↓ frühere Eingaben, Tab ergänzt · nur im Editor bzw. Debug-Build oder mit `--debug` |
| Esc | Fenster schließen (Gespräch, Tagebuch) bzw. Spielmenü – pausiert das Spiel |

## Was drin ist

- **Hotel (Graybox) nach dem Gebäudeplan `map.aseprite`:** Erdgeschoss ca. 150 × 110 m · **Lobby** mit Rezeption, verriegeltem Haupteingang, Luftraum und **Galerie** (Treppe hinauf, Obergeschoss noch gesperrt), zwei Aufzüge außer Betrieb · **Bar + Spiele**, **Partyraum**, Toiletten · **Ostflügel** mit 69 Zimmern (0101–0181) um zwei Innenhöfe mit Bäumen und Terrassen · **Westflügel**: Flure, Innenhöfe, Küche, Speisesaal, Lager und Kühlräume offen, die Zimmer (0201–0272) noch verschlossen · großer Mittelgarten mit Kürbisbeeten · Hallenbad mit Duschen und Umkleiden (Einstiegstreppen; das Wasser schlägt Wellen, wenn man hindurchgeht, und spritzt, wenn man hineinfällt · naht das Monster, wird es spiegelglatt, dann zittert es, und ist es in der Halle, schwappt das Becken) · **Treppenhaus Ost** hinab in den Keller · nur die nächsten sechs Lampen werfen Schatten (`ShadowBudget`)
- **Kein Inventar:** ein Gegenstand in der Hand; große Dinge blockieren Türen/Truhen; Münzen werden zu Geld · **Ausnahme am Körper:** Kompass, Kartenblätter und Schlüsselbund – Karte und Kompass holt die linke Hand hervor (nicht mit einem Kürbis in den Händen)
- **Kompass:** liegt im verfallenen Zimmer 226 im Obergeschoss · wird eingesteckt, F halten hebt ihn vor die Augen (kein HUD), auch im Versteck · leuchtende Nadel zeigt nach Norden (Nordflügel, Treppenhaus) · in der Nähe des Monsters zittert sie, ganz nah dreht sie sich im Kreis – auch bei Halluzinationen
- **Karte aus losen Blättern:** jedes Blatt einzeln zu finden – Erdgeschoss auf dem Schreibtisch in Zimmer 13, eine handgezeichnete Kellerskizze von 1994 in Zimmer 0117 · Tab halten hält die Blätter bildfüllend vors Gesicht, das Blatt der aktuellen Ebene liegt oben, Linksklick/Mausrad blättert · gedruckte Pläne mit Norden oben, allen Zimmernummern, Zimmer 13 rot eingekreist · das letzte Blatt listet den Schlüsselbund
- **Schlüsselbund:** gefundene Schlüssel wandern beim Aufheben an den Bund, Türen lassen sich dann aufschließen, egal was man in der Hand hält · nur der Ausgangsschlüssel an Halloween muss in der Hand getragen werden
- **Deko & Handwerk:** Kürbisse im Garten ernten · mit dem **Messer** (Küche) schnitzen · **Kerze** in den geschnitzten Kürbis stellen · Herbstlaub unter den Bäumen · Spinnweben in dunklen Ecken · Kerzenvorrat in der Küche
- **Ausdauer:** ohne Anzeige · etwa 10 s Rennen, dann außer Atem: Herzschlag und Keuchen werden hörbar, Rennen geht erst wieder, wenn man sich beruhigt hat (im Stehen schneller als beim Gehen) · kurz vorher hört man schon leise den Atem · **Keuchen verrät dich:** Monster und Lakengeist hören es (auch im Versteck), außer Atem hält man die Luft kürzer an
- **Verstecke:** Schränke (auch im Flur) und Betten, Zeitlimit wie in *Doors*, Luft anhalten
- **Schlafen:** während der Nachtruhe im eigenen Bett in Zimmer 13 – Augen zu, die Zeit läuft schneller bis zum Morgen · das Monster in der Nähe oder ein Geräusch weckt dich · wer nicht schläft, sammelt Nächte ohne Schlaf (erst nach dem ersten Angriff), und das lockt den Lakengeist
- **Dramaturgie:** friedlicher Anfang ohne Monster · erster Angriff am 3./4. Oktober während einer Feier (Licht und Musik aus, das Monster steht in der Lobby) · die ersten zwei Angriffe sind harmlos: es steht direkt vor dir, starrt dich an und verschwindet, Gäste werden nur erschreckt
- **Monster:** dürre, über zwei Meter große Gestalt auf zwei Beinen (Modell mit Skelett, ruckartige Stop-Motion-Bewegung) · duckt sich unter Türen, lauert halb geduckt, schleicht auf allen Vieren davon, wenn man es sieht · streift im ganzen Hotel umher, im Wechsel mit Ruhephasen im Keller (anfangs lang, mit jedem Tag kürzer), weicht deinem Blick aus, biegt in Zimmer ab (wenn keine Deko davor), Deko und Licht drängen es ab, schicken es aber nicht nach Hause – es bleibt die ganze Aktivphase unterwegs, versteckte Werte Dreistigkeit / Neugier / Abschreckung, Rauschen ab ~20 m (lauter, je näher), Lampen flackern in seiner Nähe, beim Aufbruch läuft eine Flackerwelle vom Keller durchs Haus – kurzes Zucken: es sieht sich nur um, je länger es flackert, desto mehr will es holen (1 + 2 s pro Opfer, manchmal täuscht es), „weiß“, wenn man es anstarrt, holt Spieler **und Gäste** aus Verstecken, Jumpscare + Sterbebildschirm, nach einem Gast eine Weile satt, danach Halluzinationen
- **Spuren & Zettel:** Fußspuren (verblassen), Kratzspuren, Blut und Kleidungsstück bei einem Todesfall, Handabdrücke an Zimmertüren, geprüfte Verstecke, ausgehende Kerzen · Spuren an Zimmer 13 lassen sich wegwischen · Gäste berichten davon (nicht immer zuverlässig) · Warnungszettel früherer Gäste ab dem ersten Angriff · **Spuren der Gäste:** schlammige Schuhabdrücke nach dem Garten, Wachsflecken von Kerzen und Kürbislaternen, Blutstropfen und verlorene Münzen nach einem Angriff, Zettel an Türen und nach Todesfällen oder Sichtungen
- **Klopfen an Zimmer 13:** ein Gast in Panik bittet um Einlass – oder eine bekannte Stimme, hinter der niemand steht
- **Zimmertelefone:** Wählscheibentelefon in jedem Zimmer, Haupttelefon mit Gästeverzeichnis an der Rezeption (Zimmernummer wählen, 0 = Rezeption) · Freunde rufen an und warnen, wo es gerade ist (nicht immer richtig), Feinde lügen, Bekannte plaudern oder laden zur Feier ein · manchmal nur Atmen – danach liegt in einem leeren Zimmer ein Hörer neben dem Apparat · selbst anrufen: plaudern, fragen, einladen; **Klingeln ist Lärm** und lockt das Monster ins Zielzimmer · anrufen und sofort auflegen gilt als Telefonstreich · Hörer daneben legen: still, aber keine Warnungen mehr · ab und zu klingelt irgendwo im Hotel ein Telefon
- **Gäste:** Edna, Bruno, Mila plus zufällig erzeugte Gäste (30 zum Start, sechs Charaktere mit eigenen Sätzen und Werten; Männer als echte Figuren mit eigener Größe, Breite, Statur und Kleidungs-/Haarfarbe, Frauen vorerst noch Klötzchen); sinkt die Zahl der Lebenden unter 24, wacht nach einigen Minuten ein neuer Gast in einem freien Zimmer auf · eigener Tagesablauf mit **Nachtruhe zu zufälligen Zeiten** (alle gehen ins Bett, Licht aus), Dialog (Plaudern, Monster, Handeln, Schenken, Deko erbitten, Beruhigen, Einladen, Beleidigen, Entschuldigen), Beziehung, Klauen in beide Richtungen mit Zeugen und Gerüchten, Panik & Verstecken, können sterben → Schock/Schuld beim Spieler, Gedenkkerze hilft
- **Freundschaft & Feindschaft:** neun Stufen von „stark verfeindet“ bis „guter Freund“ · nach oben wird es zäh, Plaudern zählt nur zweimal am Tag voll · **guter Freund** erst nach mehreren gemeinsamen Partien und Gegenständen in beide Richtungen, **stark verfeindet** erst nach Klauen, Beleidigen, Rammen oder Schlagen – und seiner Rache · befreundete Gäste kommen auf Bitte mit („Komm mit“), gute Freunde schließen sich auch von selbst an und besuchen dich in Zimmer 13 · wütende Gäste rempeln dich an, Erzfeinde drohen und schlagen zu, wenn sie dich allein erwischen · **Linksklick auf einen Gast** (ohne Taschenlampe in der Hand) schlägt ihn – erst nach Nachfrage; er flieht oder schlägt zurück, Zeugen reden darüber · im Rennen umgerannte Gäste stolpern · Schläge verletzen dich: langsamer, Blutspur, heilt mit der Zeit
- **Mäxchen an der Hotelbar:** Bluff-Würfeln gegen Gäste um Geld oder Gegenstände (Einsätze liegen echt auf dem Tisch), Herausforderungen & Revanche, Gäste würfeln untereinander (zuschauen verrät ihre Ticks), gezinkte Würfel aus Zimmer 0117, Abbruch bei Vorwarnung
- **Schach in der Lobby:** Schachtisch mit Brett (das Brett ist ein Gegenstand – ohne Brett kein Schach) · Gast einladen oder Herausforderung annehmen, Einsätze wie bei Mäxchen · du spielst Weiß und ziehst mit der Maus auf dem Brett von oben (Figur anklicken, dann Zielfeld; Bauern werden zur Dame) · Remis anbieten, aufgeben, absichtlich verlieren (gute Spieler merken es) · jeder Gast spielt verschieden stark (Edna ordentlich, Bruno schwach und stolz, Mila stark) · Gäste spielen auch untereinander – wer 30 s zusieht, kennt danach ihre Stärke · leise, aber man ist konzentriert; bei einer Vorwarnung springt der Gast auf
- **Lakengeist:** ab dem 2. Tag · kommt, wenn du in einem Raum mit Außenfenster bist, in dem das Licht aus und der Vorhang offen ist (sehr wahrscheinlich beim Betreten, danach alle paar Sekunden wieder, frühestens 45 s nach dem letzten Besuch) · wird von Mal zu Mal dreister: schwebt heran → blutige Handabdrücke auf der Scheibe und Hypnose mit kreisenden Händen (macht langsamer, zieht den Blick) → kommt herein und würgt → ab dem 4. Mal auch durch den zugezogenen Vorhang · losreißen nur mit wildem Hin und Her (Balken, der Griff zieht ständig zurück) – das schafft man selten, sonst tot · **im Schrank** wartet er 20–35 s vor den Türen und packt zu, wer herauskommt; dann fliegt er hinein (40 %, ab dem 6. Mal 75 %; keuchen verrät dich, Luft anhalten hilft etwas) oder gibt auf · Gäste als Zeugen vertreiben ihn, in Gesellschaft kommt er nicht · ab dem 6. Mal auch im Flur, wenn alle schlafen · **Schlafmangel:** jede Nacht ohne Schlaf macht ihn häufiger, nach zwei Nächten kommt er schon früher in den Flur, nach drei sicher, sobald du allein im Flur bist · **kommt auch zu Gästen** (wach im Dunkeln bei offenem Vorhang, eigene Stufen) – wer sich nicht losreißt, bleibt als Leiche liegen
- **Schreck & Erlebnisse:** Gäste, die eine Blutlache, eine Leiche oder den Lakengeist sehen, bleiben 2–5 s geschockt stehen – je nach Charakter Hände hoch und weglaufen, starr vor Schreck oder weinend · jeder Fund erschreckt einen Gast nur einmal · beim nächsten Gespräch erzählen sie davon, am selben Tag kommt es beim Reden über das Monster wieder vor · wer den Geist erlebt hat, lässt den Vorhang einen Tag lang zu
- **Taschenlampe:** an der Rezeption (halb leer) · Licht zum Sehen, aber kein Schutz – wer sie trägt, wird weiter gesehen · Batterien (Wäscherei, Keller, manche leeren Zimmer, Skeptiker verkaufen sie) einlegen wie eine Kerze in den Kürbis · flackert in Monsternähe, im Versteck bleibt sie aus · **UV-Aufsatz** in Zimmer 0118: UV leert eine Batterie in ~9 s; steht das Monster ~1 s im Kegel, flieht es – kommt aber bald wieder, sucht rund um Zimmer 13 und braucht jedes Mal länger · UV zeigt verblasste Fußspuren, Schrift an Wänden und eine zweite Zeile auf jedem Warnungszettel
- **Licht & Fenster:** ein Lichtschalter pro Raum, gedimmte Wandlampen und Kerzen (Holzdecken), vier Pendelleuchten über der Lobby, Glühbirnen herausdrehen und woanders einsetzen (auch Gäste klauen sie), Birnen brennen bei starkem Flackern oder in Monsternähe selten durch · Licht aus lockt das Monster an · Außenfenster mit Vorhängen (Mondlicht, Sicht in beide Richtungen), Milchglas zwischen Flur und Zimmern (nur Umrisse)
- **Bar:** etwas trinken (1 Geld) nimmt Schock – angetrunken schwankt der Blick, die Maus zieht nach und man stolpert (Lärm), betrunken halluziniert man, wer im Rausch schläft, hat Kater · Gäste trinken auch (schwanken, „*hicks*“, erzählen mehr) · eine Runde ausgeben · betrunken blufft man beim Mäxchen schlechter
- **Kalender:** vom 1. Oktober bis Halloween, ein Ingame-Tag ≈ 5 Minuten, draußen immer Nacht · Abreißkalender in Zimmer 13, Datum im Spielmenü und in den Spielständen
- **Menüs & Speichern:** Titelbildschirm, Spielmenü (Esc), Einstellungen (Helligkeit mit Testbild, PS1-Look, Ton, Maus, weniger Flackern, Untertitel) · Speichern nur am **Tagebuch in Zimmer 13** (3 Slots, nicht während Vorwarnung/Monster) · Autosave bei wichtigen Ereignissen in sicheren Momenten · nach dem Tod letzten Spielstand laden
- **Lärm & Sichtbarkeit:** jedes Geräusch in der Welt ist zugleich Lärm mit eigener Hörweite (Tür knarrt 5 m, Schranktür 4 m, Rennen 10 m, Telefon 18 m, Schrei 20 m, Feier 25 m …), gedämpft durch Wände, geschlossene Türen und Geschossdecken · Schritte hört man nur auf Holz und Fliesen, geduckt gar nicht · das Monster geht in Hörweite nachsehen, bis zur doppelten Hörweite wird es neugierig · Gäste hören Schreie und Knalle mit halber Reichweite: sie erschrecken, sehen nach, erzählen davon oder geraten in Panik · Monster und Gäste sehen nach derselben Rechnung: Licht am Ort, **Licht in der Hand**, Rennen, Ducken, Stillstehen – im Dunkeln und geduckt klaut man unbemerkter, wer mit Kerze in den Schrank steigt, wird gesehen
- **Feiern:** Plattenspieler in der Lobby (selbst ausrichten) oder spontan von Gästen – laut, also lockt es das Monster an; währenddessen sind die Zimmer leer · Gäste tanzen verschieden (Gastmodelle: Chicken Dance, Macarena, Hip-Hop; Klötzchenfiguren: hüpfen, wiegen, drehen, Arme hoch, Twist, schunkeln), jeder hat seinen Lieblingstanz
- **Hotelkatzen:** Minka, Socke und Kasimir streifen durchs Hotel, schlafen auf Sofas und Betten, folgen ihrem Lieblingsgast und miauen vor geschlossenen Türen · streicheln beruhigt (Spieler und Gäste) · das Monster tut ihnen nichts, aber sie fliehen und **weinen**, wenn es nah ist – eine Frühwarnung, auch durch Wände · sie werfen Kürbisse und Kerzen um (dann schützen sie nicht, bis man sie aufstellt) · selten bringen sie dir etwas vor die Tür (manchmal die Deko eines Gastes – der verdächtigt erst dich) oder legen sich auf dein Bett · Liegeplätze auch auf der Rezeption und auf Fensterbänken · Gäste reden über die Katzen
- **Kommoden im Flur:** vier je Geschoss, jede Schublade lässt sich aufziehen – beim ersten Mal liegen manchmal Münzen oder ein Gegenstand darin (Kerze, Glühbirne, Batterie, Messer, gezinkte Würfel); was man hineinlegt, bleibt drin
- **PS1-Look:** 480×270, Vertex-Snapping, Dithering, Farbreduktion – im Einstellungsmenü mit einem Schalter ganz abschaltbar · Tapeten mit Vertäfelung, die im Licht unterschiedlich glänzen (Lack, Satin, stumpfe Rauten) und an Fugen und Leisten Glanzkanten zeigen, dazu fleckige, matte Stellen
- **Altersempfehlung ab 16** (selbst eingeschätzt, keine USK-Prüfung): Hinweis mit Inhalten beim ersten Start, Kennzeichen im Titelbildschirm (`scripts/ui/title_screen.gd`)

Bis auf das Monster, die Lobby-Sofas, die Flaschen in der Bar, den Plattenspieler, die Taschenlampe, die Glühbirnen, die Pflanzkübel, die Bäume im Garten, die Tür- und Fensterrahmen und die Tapeten (`assets/textures/`) sind alle Modelle, Texturen und Sounds Platzhalter (prozedural erzeugt) und werden später durch Blender-Modelle (glTF) und echte Sounds ersetzt. Das Monster-Modell (`assets/models/monster.glb`) baut `tools/build_monster.py` in Blender aus dem Meshy-Original:

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

Die Taschenlampe (`assets/models/flashlight.glb`) ist „Flashlight“ von [Onur](https://sketchfab.com/onurpearl) ([Sketchfab](https://sketchfab.com/3d-models/flashlight-d73e5a7dc8464bf0a065e677f3c4d55c), CC-BY 4.0):

```bash
"/c/Program Files/Blender Foundation/Blender 4.3/blender.exe" -b --python tools/build_flashlight.py -- assets/source/flashlight.glb assets/models/flashlight.glb
```

Die Schilderschrift (`assets/fonts/cinzel_bold.ttf`) ist [Cinzel](https://github.com/NDISCOVER/Cinzel) von Natanael Gama (SIL Open Font License 1.1, `assets/fonts/OFL.txt`), als feste Bold-Instanz ohne überlappende Konturen aus dem Variable Font von [google/fonts](https://github.com/google/fonts/tree/main/ofl/cinzel) (`pip install fonttools skia-pathops`):

```bash
python tools/build_font.py assets/source/cinzel_variable.ttf assets/fonts/cinzel_bold.ttf
```

Die Glühbirne (`assets/models/bulb.glb`) ist „Lightbulb (Low-Poly)“ von [Mirai](https://sketchfab.com/MrMirai) ([Sketchfab](https://sketchfab.com/3d-models/lightbulb-low-poly-2566774276944542a01ff47a67a6eb51), CC-BY 4.0):

```bash
"/c/Program Files/Blender Foundation/Blender 4.3/blender.exe" -b --python tools/build_bulb.py -- assets/source/lightbulb.glb assets/models/bulb.glb
```

Pflanzkübel (`assets/models/planter.glb`) und Laubbaum (`assets/models/tree.glb`) kommen von Meshy:

```bash
"/c/Program Files/Blender Foundation/Blender 4.3/blender.exe" -b --python tools/build_planter.py -- assets/source/planter.glb assets/models/planter.glb
```

```bash
"/c/Program Files/Blender Foundation/Blender 4.3/blender.exe" -b --python tools/build_tree.py -- assets/source/tree.glb assets/models/tree.glb
```

Das Katzenmodell (`assets/models/cat.glb`) baut `tools/build_cat.py` aus Meshys geriggtem Paket:

```bash
"/c/Program Files/Blender Foundation/Blender 4.3/blender.exe" -b --python tools/build_cat.py -- assets/source/Meshy_AI_Curious_Cat_quadruped.zip assets/models/cat.glb
```

Die Gast-Grundkörper (`assets/models/guest_<name>.glb`, Spielkonzept 6.0) baut `tools/build_guest.py` aus Meshys GLB (Auto-Rigging mit Skelettvorlage „Mixamo“, alle Animationen, einzelne Datei). Dazu kommt jede Mixamo-Animation aus `assets/source/anim/<name>.fbx` (bei mixamo.com am Standard-Charakter herunterladen: FBX Binary, „Without Skin“, 30 fps, Keyframe Reduction „none“, bei Geh-/Laufzyklen „In Place“) – sie wird auf die Grundpose des Gastes umgerechnet und gilt für alle Grundkörper. Das Skript gibt am Ende die Zeile für `GuestBody.BODIES` aus; ein optionaler dritter Pfad legt Vorschaubilder ab (Ruhe, Maske, Körperbau, Gehen, Rennen, Tänze):

```bash
"/c/Program Files/Blender Foundation/Blender 4.3/blender.exe" -b --python tools/build_guest.py -- assets/source/guest_man.glb assets/models/guest_man.glb
"/c/Program Files/Blender Foundation/Blender 4.3/blender.exe" -b --python tools/build_guest.py -- assets/source/guest_girl10.glb assets/models/guest_girl10.glb
```

Den Kürbismann (`assets/models/pumpkin_man.glb`, neues Monster, vorerst Testfigur für `--pumpkin`) liefert Meshy mit der Skelettvorlage „SmartRig“. `tools/smartrig_to_mixamo.py` baut das Skelett auf Mixamo um (die Axt hängt danach fest an der linken Hand), `tools/build_pumpkin.py` macht daraus das Spielmodell mit denselben Mixamo-Tänzen wie bei den Gästen. Ein optionaler dritter Pfad legt Vorschaubilder ab:

```bash
"/c/Program Files/Blender Foundation/Blender 4.3/blender.exe" -b --python tools/smartrig_to_mixamo.py -- Meshy_AI_Character_output.glb assets/source/pumpkin_man.glb
```

```bash
"/c/Program Files/Blender Foundation/Blender 4.3/blender.exe" -b --python tools/build_pumpkin.py -- assets/source/pumpkin_man.glb assets/models/pumpkin_man.glb
```
Den Lakengeist (`assets/models/ghost.glb`, Spielkonzept 4.18) riggt `tools/build_ghost.py` selbst – mit Armen und Fingern. Ein optionaler dritter Pfad legt Vorschaubilder ab (Ruhe, gekrümmte Finger, gehobene Arme):

```bash
"/c/Program Files/Blender Foundation/Blender 4.3/blender.exe" -b --python tools/build_ghost.py -- assets/source/Meshy_AI_floating_ghost_3d_1017173231_image-to-3d-texture.glb assets/models/ghost.glb
```

Die Tür- und Fensterrahmen (`assets/models/frames.glb`, Spielkonzept 7.2) braucht kein Ausgangsmodell: `tools/build_frames.py` zieht Profile im Craftsman-Stil aus. Ein optionaler zweiter Pfad rendert eine Vorschau-Tür:

```bash
"/c/Program Files/Blender Foundation/Blender 4.3/blender.exe" -b --python tools/build_frames.py -- assets/models/frames.glb
```

## Debug-Startparameter

Nach `--` an Godot übergeben, z. B. `--path . -- --trace --warn`. Alle Aktionen lassen sich auch im laufenden Spiel in der **Debug-Konsole** (^) tippen – dort ohne `--`, Wert mit Leerzeichen oder `=`.

| Parameter | Wirkung |
|-----------|---------|
| `--trace` | Monster, Gäste und Meldungen alle 2 s in die Konsole, dazu jedes Lärmereignis (wer es hört und wie er reagiert) |
| `--noise=door` | alle 6 s Lärm dieser Art am Spieler (`door`, `hide`, `run`, `scream` … – Tabelle in `scripts/util/senses.gd`) |
| `--warn` | sofort Vorwarnung → Monster erscheint |
| `--intent=roam` / `one` / `rampage` / `4` | Absicht beim Aufbruch erzwingen: umsehen, ein, zwei oder n Opfer (mit `--trace` stehen Absicht und Flackerwelle in der Konsole) |
| `--bold=90` | Dreistigkeit setzen |
| `--friend=edna` / `--enemy=bruno` · `--relation=bruno,-90` | befreundet / verfeindet · Beziehung setzen (ab ±80 mit den nötigen Taten) |
| `--follow=edna` · `--visit=edna` · `--attack=bruno` · `--punch=mila` | Gast kommt mit · besucht Zimmer 13 · schlägt dich · steht vor dir und wird geschlagen (mit Nachfrage) |
| `--kill=mila` | Gast nach 3 s vom Monster holen lassen |
| `--first-attack` · `--attacks=3` | Feier + erster Angriff nach 3 s · so viele Angriffe gab es schon (> 2: es holt jemanden) |
| `--knock` · `--knock-fake` · `--answer` | Klopfen an Zimmer 13 · falsche Stimme · Spieler öffnet nach 4 s |
| `--call=edna` · `--call=creepy` / `dead` / `door` · `--answer` | Telefon in Zimmer 13 klingelt: Gast (warnt, wenn das Monster unterwegs ist) · Atmen · Verschwundener · es steht vor der Tür · Spieler nimmt nach 4 s ab |
| `--dial=0111` · `--dial=lobby` | aus Zimmer 13 eine Nummer anrufen (0 = Rezeption) · Wählseite am Haupttelefon |
| `--party` | Feier starten |
| `--cat=minka` | Hotelkatze vor den Spieler setzen (`minka`, `socke`, `kasimir`) |
| `--pumpkin` · `--pumpkin=macarena` | Kürbismann (neues Monster, nur Testfigur ohne Verhalten) 2,5 m vor dich, tanzt in Schleife: `chicken` (Standard), `macarena`, `hiphop` – erneut aufgerufen ersetzt er den alten |
| `--tp=lobby` · `--tp=13` · `--tp=0126` · `--tp=edna` | hinspringen: Ort aus der F6-Liste (lobby, bar, küche, garten, galerie, treppenhaus, keller …), Zimmer (Türschild oder Nummer), vor einen Gast |
| `--time=+1` · `--load-slot=2` | Spieltage vor-/zurückspulen · Spielstand laden (in der Konsole: `load 2`, `save 2` = `--diary=2`) |
| `--console` · `--console=guests;tp keller` | Debug-Konsole nach 1 s öffnen, optional Befehle (mit `;` getrennt) eintippen – für Screenshots |
| `--talk=edna` | Gespräch öffnen |
| `--look=gast1` · `--look=gast1,carry` | vor einen Gast stellen, ohne Dialog (er bleibt stehen) · mit Haltung: `carry`, `panic`, `dance`, `sit`, `walk` – zum Prüfen der Gastmodelle |
| `--shock=bruno` · `--shock=mila,corpse` · `--shock=edna,ghost3` | Gast erschrecken: Blutlache bzw. Leiche vor ihm im Flur (Spieler sieht zu) · Lakengeist kommt zum n. Mal an sein dunkles Zimmerfenster (ab 3 würgt er; Zimmer ohne Außenfenster gehen nicht) · mit `--talk=bruno` erzählt er danach davon |
| `--dice=bruno` · `--autoplay` | Mäxchen-Partie starten · Antworten automatisch wählen |
| `--chess=mila` · `--autoplay` | Schachpartie in der Lobby starten · der Spieler zieht selbst (schwach), mit `--trace` Stärke des Gastes und Ergebnis |
| `--challenge=bruno` · `--challenge=edna,chess` | Gast fordert dich heraus (Mäxchen bzw. Schach) |
| `--pos=x,y,z,winkel[,neigung]` · `--monster=x,y,z` | Spieler versetzen (Neigung in Grad, positiv = nach oben) · Monster erscheinen lassen |
| `--lure` | nach 1 s kommt das Monster zu dir (wie F7) |
| `--pool=still` · `--pool=tremor` · `--pool=slosh` | Poolwasser, als wäre das Monster nah: spiegelglatt · feine zitternde Ringe · Becken schwappt mit Schaum und Gischt (`--pool=off` in der Konsole: wieder normal) |
| `--splash=x,z` | nach 1 s platscht es an dieser Stelle im Pool (Wellenring, der bricht, und Spritzer), z. B. `--splash=18,-105 --pos=18,0.1,-100,0,-25` |
| `--flashlight` · `--flashlight=uv` | eingeschaltete Taschenlampe mit voller Batterie in die Hand · mit UV-Aufsatz im UV-Modus |
| `--sprint` · `--winded` | vorwärts rennen, bis die Ausdauer leer ist · gleich außer Atem starten (mit `--trace`: „außer Atem“ und „beruhigt“ in der Konsole) |
| `--pocket` · `--show=map` / `keys` / `compass` | Kompass, alle Kartenblätter und Schlüssel 18 einstecken · Karte (Schlüsselblatt oben) bzw. Kompass hervorholen wie mit gehaltener Taste |
| `--shot=pfad.png --frames=n` · `--shot-on=reveal` · `--shot-on=jumpscare` · `--shot-on=strangle` · `--shot-on=shock` | Screenshot nach n Frames (Standard 120) · kurz nach dem harmlosen Angriff auf den Spieler · im Jumpscare · wenn der Lakengeist zupackt · wenn ein Gast erschrickt |
| `--bg` | Fenster im Hintergrund: nimmt keinen Fokus und liegt außerhalb des Bildschirms (für Screenshot-Läufe nebenher) |
| `--ghost=n` · `--ghost=flur` · `--ghost=schrank` | Lakengeist zum n. Mal: Spieler in Zimmer 13, Licht aus, Vorhang auf (ab 4 zu), er kommt sicher (mit `--trace`: Erscheinen, Losreißen mit Balkenstand und Wechseln je Sekunde, Tod in der Konsole) · alle Gäste sofort im Bett, er kommt im Flur (mit `--pos` in einen Flur stellen) · er kommt in Zimmer 13 herein, du versteckst dich sofort im Schrank (mit `--trace`: Wartezeit, Chance, hineinfliegen oder aufgeben) |
| `--sleep` · `--sleep=bett` | Nachtruhe sofort beginnen · alle Gäste sofort im Bett, du schläfst im Bett von Zimmer 13 (mit `--trace`: Einschlafen, Wecken, Ende der Nachtruhe) |
| `--no-psx` | ohne PS1-Look starten (wie der Schalter in den Einstellungen, wird nicht gespeichert) |
| `--awake=n` | so viele Nächte ohne Schlaf (der erste Angriff gilt als geschehen) – Lakengeist häufiger, ab 3 sicher im Flur (je Nacht ein Drittel Schwäche), z. B. `--awake=3 --pos=40,0.1,0 --trace` |
| `--nointro` · `--debug` · `--trace-nav` | ohne Intro · Debug-Werte · mit `--trace` auch die Wegfindung der Gäste |
| `--title` · `--new=2` · `--load=1` | trotz Parametern Titelbildschirm · neues Spiel in Slot 2 · Slot laden (0 = Autosave) |
| `--diary=3` · `--savetest` | nach 2 s in Slot 3 speichern · Speichern → Laden → Vergleichen |
| `--navcheck` | Bau- und NavMesh-Zeit, Wege von Zimmer 13 zu Lobby, Galerie, Bar, Küche, Keller, Innenhöfen … (unerreichbare Orte werden gemeldet) |
| `--menu=pause` | Menü öffnen (`pause`, `diary`, `settings`, `load`, `controls`) |
| `--bulb-thief=bruno` | Gast klaut sofort eine Glühbirne aus Zimmer 13 |
| `--day=31` | zu einem Tag im Oktober springen (ein Tag ≈ 5 min, `Calendar.DAY_SECONDS`) |

Ohne Parameter startet das Spiel mit dem Titelbildschirm; mit Parametern direkt im Hotel.
Für lange Testläufe hilft Godots eigenes `--time-scale 3` (vor dem `--`), z. B. `--path . --time-scale 3 --quit-after 36000 -- --day=3 --nointro --trace`.
Spielstände liegen in `%APPDATA%/Godot/app_userdata/Zimmer 13/saves/`, Einstellungen in `settings.cfg` daneben.
Spielstände aus einem älteren Hotel (seitdem umgebaut) oder einer älteren Spielstand-Version werden in der Übersicht als „passt nicht mehr zu diesem Hotel“ gezeigt und nicht geladen.

## Aufbau

```
scenes/title.tscn           Einstiegsszene: Titelbildschirm
scenes/main.tscn            das Hotel
scripts/main.gd             baut alles zusammen, Debug-Startparameter
scripts/autoload/game.gd    globaler Zustand, Geld, Tastenbelegung, Szenenwechsel
scripts/autoload/settings.gd       Einstellungen (user://settings.cfg)
scripts/autoload/save_manager.gd   Speichern/Laden, Autosave, Tagebuchsatz
scripts/level/              LevelBuilder (baut aus assets/maps/eg.json: Wände, Zimmer, Flure, Keller, Zonen, Wegpunkte)
tools/build_map.py          Gebäudeplan map.aseprite (Legende: Farbnamen in map.gpl) → assets/maps/<stockwerk>.json
tools/aseprite-palette-names/  Aseprite-Erweiterung: Palettennamen aus map.gpl als Liste neben den Farben
scripts/world/              Item, Door (auch Glas), HideSpot, Chest, FlickerLight,
                            PumpkinPlant, ResourceSpot, RecordPlayer,
                            Lamp (Glühbirne), LightSwitch, HotelWindow (Vorhang), OpeningFrame (Rahmen), Diary,
                            Traces + TraceMark (Spuren), WarningNote (Warnungszettel), HotelPhone (Telefon),
                            Flashlight (Taschenlampe, UV), UvMark (nur unter UV sichtbar)
scripts/guests/             Guest (Verhalten), GuestProfiles (feste Gäste, Sätze), GuestGenerator (Zufallsgäste),
                            Social (Beziehungen, Gerüchte, Diebstahl, Tod, Feiern), PhoneCalls (Anrufe)
scripts/player/             Player
scripts/monster/            Monster (Zustände), MonsterDirector (Phasen, versteckte Werte, Effekte, Spuk)
scripts/minigames/          Mäxchen: Regeln, Partie (Ablauf, Gast-KI), Würfeltisch · Schach: Regeln, KI (Thread),
                            Brett von oben, Partie, Schachtisch · TableStakes (Einsätze für beide)
scripts/ui/                 HUD, Dialog, Sterbebildschirm, Titelbildschirm, Menüs (Esc, Tagebuch),
                            Einstellungen, Slot-Übersicht, UiKit (Meldezettel-Optik), Telefon
scripts/util/               PS1-Materialien, Platzhalter-Geometrie/-Texturen, Synth-Sound, ShadowBudget,
                            Senses (Lärm & Sichtbarkeit: alle Werte)
shaders/                    PS1-Oberfläche, Tapete mit Glanz, Post-Effekt, Versteck-Overlay
```

Tuning-Werte des Monsters stehen oben in `scripts/monster/monster_director.gd`.
