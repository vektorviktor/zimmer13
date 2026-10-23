# Zimmer 13 – Prototyp

First-Person-Horror im Hotel. Konzept: [SPIELKONZEPT.md](SPIELKONZEPT.md) · Engine: Godot 4.7

## Starten

Projekt im Godot-Editor öffnen (`project.godot`) und mit **F5** starten (Titelbildschirm), oder direkt:

```bash
"/c/Users/vikto/Downloads/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64.exe" --path .
```

Tests (Details in TECHNIK.md, Abschnitt 10): Rauchtest über alle Debug-Szenarien (~25 min) bzw. nur Spielstand-Regeln
und Rechentests (Sekunden):

```bash
bash tests/smoke.sh
```

```bash
"/c/Users/vikto/Downloads/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe" --headless --path . res://tests/run.tscn
```

## Exportieren (eine einzelne .exe)

Einmalig im Editor die Export-Vorlagen für **4.7.2** installieren (*Editor → Export-Vorlagen verwalten → Herunterladen*).
Das Preset „Windows Desktop“ liegt in `export_presets.cfg` (PCK eingebettet, Rohmodelle und `tools/` ausgeschlossen):

```bash
mkdir -p build && "/c/Users/vikto/Downloads/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64.exe" --headless --path . --export-release "Windows Desktop" build/Zimmer13.exe
```

Ergebnis: `build/Zimmer13.exe` (ignoriert von Git), läuft ohne weitere Dateien. Die Debug-Startparameter
funktionieren auch dort (`Zimmer13.exe -- --trace`); die F-Tasten (F3/F5/F6/F7/F9/F10) sind im Export ebenfalls aktiv.

## Steuerung

| Taste | Aktion |
|-------|--------|
| WASD / Maus | Laufen / Umsehen |
| Shift | Rennen (macht Lärm: 10 m statt 0–2 m beim Gehen; kostet Ausdauer) |
| Leertaste | Springen |
| Strg / C (halten) | Ducken |
| E | Nehmen, Benutzen (Schnitzen, Kerze einsetzen, Ernten), Umgeworfenes aufstellen, Katzen streicheln (gleich danach: hochnehmen), Tür/Truhe/Schublade öffnen, Licht schalten, Vorhang ziehen, Glühbirne heraus-/eindrehen, mit Gästen reden, telefonieren, Verstecken, im eigenen Bett schlafen (während der Nachtruhe; geduckt: darunter verstecken), ins Tagebuch schreiben |
| 1–9 / Maus | Im Gespräch Antwort wählen (Esc beendet) |
| 0–9 · Enter · Rücktaste · H | Am Telefon: Zimmernummer wählen · anrufen · löschen · Hörer daneben legen (Esc legt auf) |
| G | Gegenstand ablegen (Kürbis vor die Tür stellen …) |
| Q (halten) | Tasche: Fächer erscheinen über dem verschwommenen Spiel (es läuft weiter) · Maus links/rechts, Mausrad oder 1–6 wählen · Loslassen nimmt den Gegenstand in die Hand, was du vorher hieltst, fällt zu Boden · leeres Fach wählen steckt Kleines aus der Hand ein · Rechtsklick bricht ab |
| 1–6 | Fach der Tasche gleich in die Hand (das Gehaltene fällt zu Boden) |
| Rechtsklick (halten) | Im Versteck Luft anhalten |
| Tab (halten) · Linksklick / Mausrad | Kartenblätter ansehen · weiterblättern |
| F (halten) | Kompass ansehen |
| Linksklick · R | Taschenlampe in der Hand: an/aus · normales Licht ↔ UV (mit UV-Aufsatz) · Getränkedose in der Hand: trinken |
| F3 | Debug: versteckte Monster-Werte und die letzten Lärmereignisse |
| F5 | Debug: Monster sofort rufen (wenn es gerade ruht; die ersten zwei Angriffe bleiben harmlos – `--attacks=3` für echte, ob es dann jemanden holt, würfelt es nach Tag, sicher mit `--intent=one`) |
| F6 | Debug-Menü, pausiert, scrollbar (Mausrad, ↑/↓ + Enter, Bild↑/↓, 1–9 für die ersten Orte): Teleport-Liste (Zimmer 13, Lobby, Kompass-Zimmer, Keller, Partyraum, Katzenraum, Bibliothek, Kellergang …), Lakengeist zum 1.–4. Mal am Fenster bzw. an der Fenstertür des Raums, in dem du stehst, bzw. knapp 20 m vor dir im Flur (ohne Sprung; ohne Außenfenster bzw. Flur nur eine Meldung) · wo die Debug-Konsole geht, dazu alle ihre Befehle nach Gruppen (Monster, Kürbismann, Gäste, Spiele, Feiern & Deko, Telefon, Zeit & Schlaf, Welt, Spieler, Speichern & Ansicht) – Befehle mit Werten öffnen eine Eingabezeile mit dem Format, Enter führt aus wie in der Konsole (ohne help, clear, navcheck) |
| F7 | Debug: Monster kommt zu dir, als hätte es dich gehört (ruht es, erscheint es ~25 m entfernt; jedes Drücken lenkt es zu deiner neuen Stelle; harmlos wie bei F5, solange nicht `--attacks=3`) |
| F9 | Debug: Kürbismann kommt übers Lobbydach (springt vor der Gartentür in den Garten, sucht die Lobby ab) und jagt alle, die gerade Spaß haben, und dich (auch ohne Feier und vor dem ersten Angriff) |
| F10 | Bilder pro Sekunde und Bildzeit rechts oben ein/aus |
| ^ oder F1 | Debug-Konsole: Startparameter im Spiel tippen, ohne `--` (z. B. `shock edna,ghost3`, `tp lobby`, `guests`, `help`) – pausiert, ↑/↓ frühere Eingaben, Tab ergänzt · nur im Editor bzw. Debug-Build oder mit `--debug` |
| Esc | Fenster schließen (Gespräch, Tagebuch) bzw. Spielmenü – pausiert das Spiel |

## Was drin ist

- **Hotel (Graybox) nach dem Gebäudeplan `map.aseprite`:** Erdgeschoss ca. 150 × 110 m · **Lobby** mit Rezeption (Holz mit runden Ecken, Terrazzoplatte wie die Säulen, Messingrohre), verriegeltem Haupteingang, Luftraum und **Galerie** (breite Treppe mit Läufer und gedrechseltem Geländer hinauf), zwei Aufzüge außer Betrieb · **Zimmertüren** nach gemalter Vorlage (vier Bogenkassetten, Messingklinke, Bänder) · die verschlossene **Kniestocktür** zum Dachboden (Bretter, Langbänder, Kastenschloss) steht bereit und erscheint mit dem Plan des Dachgeschosses · **Bar + Spiele**, **Partyraum** über zwei Stockwerke mit Galerie, Toiletten · **Ostflügel** mit 69 Zimmern (0101–0181) um zwei Innenhöfe mit Bäumen (sie verlieren Herbstlaub, das kurz im Gras liegen bleibt) und Terrassen hinter 1,6 m hohen Formschnitthecken (nur durch die Gartentür des Zimmers zu erreichen) · **Westflügel**: Flure, Innenhöfe, Küche, Speisesaal, Lager und Kühlräume offen, die Zimmer (0201–0272) noch verschlossen · großer Mittelgarten mit acht Kürbisfeldern (je eine Sorte, über 60 Pflanzen) und vier Bäumen, auch im Innenhof Südwest ein Baum · Hallenbad mit Duschen und Umkleiden (Einstiegstreppen, vier Unterwasserlampen, die jede für sich langsam durch den Regenbogen wechseln; das Wasser schlägt Wellen, wenn man hindurchgeht, und spritzt, wenn man hineinfällt · naht das Monster, wird es spiegelglatt, dann zittert es, und ist es in der Halle, schwappt das Becken) · **Obergeschoss:** Zimmer mit 2–3 Betten, manche mit Bad und Balkon, Suiten über Verbindungstüren, Bibliothek, **Katzenraum** · **Treppenhaus Ost** vom Untergeschoss bis ins Obergeschoss · **Untergeschoss:** graue Kellergänge unter kaltweißen Halogenleuchten, die ab und zu kurz flackern, Heizkeller (Versteck des Monsters), Technikraum, Wäscherei mit Waschmaschinen, sonst verschlossene Räume · nur zwölf Lampen um die Kamera werfen Schatten (`ShadowBudget`)
- **Hände & Tasche:** ein Gegenstand in der Hand; große Dinge (Kürbisse, Deko) brauchen beide Hände und blockieren Türen/Truhen; Münzen werden zu Geld · **Tasche für Kleines** mit 6 Fächern: Süßigkeiten, Getränkedosen, Zierkürbisse, Messer, Batterien, Glühbirnen, UV-Aufsatz, Würfel und ausgegangene Kerzen – mit voller Hand wandern sie beim Aufheben gleich hinein, unten rechts zeigen kleine Fächer mit Bildern, was drin ist · Q halten zeigt die Tasche groß – wer etwas herausnimmt, lässt fallen, was er in der Hand hatte (auch einen Kürbis) · Süßes oder Saures, Schenken und Verkaufen gehen auch aus der Tasche · **Ausnahme am Körper:** Kompass, Kartenblätter und Schlüsselbund – Karte und Kompass holt die linke Hand hervor (nicht mit einem Kürbis in den Händen)
- **Getränkedosen:** Limo und Cola aus den Kisten in Kühlraum und Lager oder für 1 Geld von der Bartheke · trinken (Linksklick) bringt einen sofort wieder zu Atem und beruhigt ein wenig – das Zischen hört man ein paar Meter weit · Gäste trinken geschenkte Dosen, Kinder freuen sich besonders
- **Kompass:** liegt im verfallenen Zimmer 226 im Obergeschoss · wird eingesteckt, F halten hebt ihn vor die Augen (kein HUD), auch im Versteck · leuchtende Nadel zeigt nach Norden (Nordflügel, Treppenhaus) · in der Nähe des Monsters zittert sie, ganz nah dreht sie sich im Kreis – auch bei Halluzinationen
- **Karte aus losen Blättern:** jedes Blatt einzeln zu finden – Erdgeschoss auf dem Schreibtisch in Zimmer 13, eine handgezeichnete Skizze des Untergeschosses von 1994 in Zimmer 0117 · Tab halten hält die Blätter bildfüllend vors Gesicht, das Blatt der aktuellen Ebene liegt oben, Linksklick/Mausrad blättert · gedruckte Pläne mit Norden oben, allen Zimmernummern, Zimmer 13 rot eingekreist · das letzte Blatt listet den Schlüsselbund
- **Schlüsselbund:** gefundene Schlüssel wandern beim Aufheben an den Bund, Türen lassen sich dann aufschließen, egal was man in der Hand hält · nur der Ausgangsschlüssel an Halloween muss in der Hand getragen werden
- **Deko & Handwerk:** Kürbisse im Garten ernten (oft fällt ein **Zierkürbis** mit ab) · mit dem **Messer** (Küche) schnitzen · **Kerze** in den geschnitzten Kürbis stellen · Herbstlaub unter den Bäumen (am Boden verstreut) · Spinnweben in dunklen Ecken · Kerzenvorrat in der Küche · **Aufhängen** mit [G] an einer Wand: fröhliche **Lakengespenster** aus der Wäschekiste (mit Zierkürbis in den Händen – fällt beim Ruck herunter), bunte **Lichterketten** aus der Dekokiste, Spinnweben, **Fledermausgirlanden** (flattern) und **Plastikspinnen** am Faden (wippen) · **Totenkopf** mit Kerze (glimmende Augen) und **Hexenbesen** (lehnt an der Wand, fällt beim Ruck um) aus der Kiste mit alter Deko im Keller · hängende Deko bewegt sich immer leicht und schwingt, wenn das Monster naht – schon bevor die Lampen flackern · Lakengespenster an einer Tür locken den Lakengeist: Er steht lautlos davor, kreist mit den Händen und dreht deinen Blick durch die Wand zur Tür – wer aufmacht, wird gepackt
- **Wetter:** draußen regnet es ab und zu (durch die Fenster zu sehen, drinnen gedämpft zu hören), gegen Monatsende öfter und öfter als Gewitter – Blitze werfen kurz Licht durch die Fenster, Donner übertönt alles, und das Monster hört danach ein paar Sekunden schlechter
- **Ausdauer:** ohne Anzeige · etwa 10 s Rennen, dann außer Atem: Herzschlag und Keuchen werden hörbar, Rennen geht erst wieder, wenn man sich beruhigt hat (im Stehen schneller als beim Gehen) · kurz vorher hört man schon leise den Atem · **Keuchen verrät dich:** Monster und Lakengeist hören es (auch im Versteck), außer Atem hält man die Luft kürzer an
- **Verstecke:** Schränke (auch im Flur) und Betten, Zeitlimit wie in *Doors*, Luft anhalten
- **Schlafen:** während der Nachtruhe im eigenen Bett in Zimmer 13 – Augen zu, die Zeit läuft schneller bis zum Morgen · das Monster in der Nähe oder ein Geräusch weckt dich · wer nicht schläft, sammelt Nächte ohne Schlaf (erst nach dem ersten Angriff), und das lockt den Lakengeist · übermüdet verschwimmt die Sicht, in Schüben, je Nacht stärker
- **Dramaturgie:** friedlicher Anfang ohne Monster · erster Angriff am 3./4. Oktober während einer Feier (Licht und Musik aus, das Monster steht im Partyraum) · die ersten zwei Angriffe sind harmlos: es steht direkt vor dir, starrt dich an und verschwindet im Flackern – es streift danach weiter, lässt dich aber bis zur nächsten Aktivphase in Ruhe, Gäste werden nur erschreckt
- **Süßigkeiten-Truhen und Automaten:** in jedem Zimmer eine kleine Truhe mit 6 Süßigkeiten, Gäste geben Kindern daraus · Snack- und Colaautomaten (je 1 Geld) in der Lobby und auf jedem Stockwerk beim Treppenhaus, ihre Front leuchtet schwach
- **Monster:** dürre, über zwei Meter große Gestalt auf zwei Beinen (Modell mit Skelett, ruckartige Stop-Motion-Bewegung) · rast durch die Flure, jagend deutlich schneller als du rennst – erwischt es dich, bist du tot (auch bei den ersten Angriffen) · duckt sich unter Türen, lauert halb geduckt, schleicht auf allen Vieren davon, wenn man es sieht · streift im ganzen Hotel umher, im Wechsel mit Ruhephasen im Keller (anfangs lang, mit jedem Tag kürzer), weicht deinem Blick aus, biegt in Zimmer ab (wenn keine Deko davor), Deko und Licht drängen es ab, schicken es aber nicht nach Hause – es bleibt die ganze Aktivphase unterwegs, versteckte Werte Dreistigkeit / Neugier / Abschreckung, Rauschen ab ~20 m (lauter, je näher), Lampen flackern in seiner Nähe, beim Aufbruch läuft eine Flackerwelle vom Keller durchs Haus – kurzes Zucken: es sieht sich nur um, je länger es flackert, desto mehr will es holen (1 + 2 s pro Opfer, manchmal täuscht es), „weiß“, wenn man es anstarrt, holt Spieler **und Gäste** aus Verstecken, Jumpscare + Sterbebildschirm, nach einem Gast eine Weile satt, danach Halluzinationen
- **Die Puppe (Halloween-Jury):** eine Stoffpuppe mit Hexenhut, am Anfang auf einem Sofa in der Lobby · 1–2 Minuten vor jedem echten Angriff (nicht beim bloßen Umsehen) liegt sie vor der bewohnten Tür mit der wenigsten Deko (bei Gleichstand der dunkelsten) – sie springt nur, wenn du weder ihren alten noch ihren neuen Platz siehst · dazu schwillt im ganzen Hotel ein Grollen an – die Gäste bekommen Angst, reden darüber (das Monster hört mit), Feiern lösen sich auf, Ängstliche schließen sich ein · wer nachbessert und nicht mehr der Schwächste ist, den verlässt sie wieder · das Monster geht dann zur Puppentür und bricht unterwegs, solange es hungrig ist, in bis zu fünf bewohnte Zimmer ein, deren Deko nicht hält: dort reißt es jedes Versteck auf, jeder darin wird mit 60 % geholt · die Puppentür fällt immer, und wer im Puppenzimmer ist, stirbt · niemand kann sie hochheben – nur Kinder nehmen sie zwischen den Angriffen mit und legen sie vor die Tür ihrer Familie · Gäste, die sie vor ihrer Tür finden, bekommen Angst
- **Gäste kochen:** ab und zu kocht ein Gast mit einem Kürbis aus seinem Koffer Suppe in der Küche, die anderen kommen zum Essen
- **In Sicherheit:** bricht das Monster auf, rennen alle Gäste heim und machen die Tür zu oder verstecken sich, und bleiben drinnen, bis es weg ist
- **Flecken:** Bewohner beschweren sich über Kürbismatsch, Wachs und Ruß vor ihrer Tür · ordentliche Gäste putzen: Wachs und Ruß wischen sie weg, Kürbismatsch bringen sie in die Küche und kochen daraus Suppe
- **Feuer:** leichte Deko (Laub, Spinnweben, Lakengespenster, Fledermäuse, Spinnen, Besen, Bettlaken) kann brennen – eine brennende Kerze, die ein Kind vor eine Tür wirft, zündet sie an, das Feuer springt auf Deko daneben über · brennt ein paar Sekunden (Flammen, Licht, Knistern), dann bleibt nur Ruß · austreten mit E, dann bleibt die Deko angesengt
- **Spuren & Zettel:** Fußspuren (verblassen), Kratzspuren, Blut und Kleidungsstück bei einem Todesfall (dazu Blutspritzer an der nächsten Wand, kurz darauf läutet im ganzen Hotel eine Totenglocke), blutige Schmierspuren an Flurwänden, die auftauchen, wo man gerade nicht hinsieht, Handabdrücke an Zimmertüren, geprüfte Verstecke, ausgehende Kerzen, eine Aschespur (schwarze Flocken hängen noch ein paar Sekunden dort in der Luft, wo das Monster war) · Spuren an Zimmer 13 lassen sich wegwischen · Gäste berichten davon (nicht immer zuverlässig) · Warnungszettel früherer Gäste ab dem ersten Angriff · **Spuren der Gäste:** schlammige Schuhabdrücke nach dem Garten, Wachsflecken von Kerzen und Kürbislaternen, Blutstropfen und verlorene Münzen nach einem Angriff, Zettel an Türen und nach Todesfällen oder Sichtungen
- **Klopfen an Zimmer 13:** ein Gast in Panik bittet um Einlass – oder eine bekannte Stimme, hinter der niemand steht
- **Zimmertelefone:** Wählscheibentelefon in jedem Zimmer, Haupttelefon mit Gästeverzeichnis an der Rezeption (Zimmernummer wählen, 0 = Rezeption) · Freunde rufen an und warnen, wo es gerade ist (nicht immer richtig), Feinde lügen, Bekannte plaudern oder laden zur Feier ein · manchmal nur Atmen – danach liegt in einem leeren Zimmer ein Hörer neben dem Apparat · selbst anrufen: plaudern, fragen, einladen; **Klingeln ist Lärm** und lockt das Monster ins Zielzimmer · anrufen und sofort auflegen gilt als Telefonstreich · Hörer daneben legen: still, aber keine Warnungen mehr · ab und zu klingelt irgendwo im Hotel ein Telefon
- **Gäste:** Edna, Bruno, Mila plus zufällig erzeugte Gäste (30 zum Start, sechs Charaktere mit eigenen Sätzen und Werten; Männer, Frauen und Kinder als echte Figuren mit eigener Größe, Breite, Statur und Kleidungs-/Haarfarbe); sinkt die Zahl der Lebenden unter 24, wacht nach einigen Minuten ein neuer Gast in einem freien Zimmer auf · eigener Tagesablauf mit **Nachtruhe zu zufälligen Zeiten** (alle gehen ins Bett, Licht aus), Dialog (Plaudern, Monster, Handeln, Schenken, Deko erbitten, Beruhigen, Einladen, Beleidigen, Entschuldigen), Beziehung, Klauen in beide Richtungen mit Zeugen und Gerüchten, Panik & Verstecken, können sterben → Schock/Schuld beim Spieler, Gedenkkerze hilft
- **Gäste:** 67 zum Start, davon 13 Kinder – nie dauerhaft weniger als 33 · Gäste weit weg und außer Sicht werden seltener berechnet (Leistung)
- **Kürbissorten:** Halloween-Kürbis, Hokkaido, Weißer Kürbis, Butternut, Muskatkürbis, Türkenturban und ein Riesenkürbis – verschieden groß, schwer und wertvoll, nur große lassen sich schnitzen (der weiße leuchtet kalt), kleine trägt man in einer Hand, der Riese rollt beim Ernten neben das Beet, wird zur Laterne und lässt sich nur langsam tragen · jede Sorte wächst unterschiedlich schnell, welche wo wächst, bestimmt der Plan · jeder Gast hat einen Lieblingskürbis: als Geschenk besonders willkommen, er erntet ihn zuerst
- **Kinder:** dreizehn Kinder (6–11 Jahre) wohnen neben Mama oder Papa · das Monster übersieht sie, der Lakengeist kommt öfter, würgt sie aber nie – er erschreckt sie nur · erschreckt schreien sie (lockt das Monster zu den Erwachsenen), klammern sich an ihre Eltern und erzählen es allen – geglaubt wird es nicht, aber die Eltern bekommen Angst · kommen immer zu Feiern, trinken nie (an der Bar einen Kakao ausgeben), toben und lachen, spielen nur zum Spaß, schenken dir Laub oder Kerzen, petzen, wenn du klaust, vergessen schnell · Kinder schlägt man nicht, wer eins umrennt oder ihm ein Messer gibt, hat Ärger mit den Eltern · **Süßes oder Saures:** Kinder ziehen von Tür zu Tür (Süßes oder Saures) und klopfen ab und zu an Zimmer 13 – mit Süßigkeiten (Kommoden, Edna, Bruno) in der Hand freut es sich, mit E am Kind gibst du bis zu 3 Süßigkeiten (schon eine verhindert den Streich, jede weitere macht es dir freundlicher), Laub vor die Tür, Deko vor der Tür umwerfen, einen Kürbis aus dem Koffer der Familie holen und vor die Tür werfen (zerplatzt) oder eine Kerze (großer weißer Wachsfleck, brennend kann sie Deko anzünden), an Zimmer 13 auch ein Klingelstreich · Erwachsene, die es sehen, verpetzen das Kind beim Bewohner (nur die Eltern nicht) – der ist danach mit den Eltern verfeindet, und Verfeindete sind keine Freunde mehr · in der Nachtruhe kann manches Kind nicht schlafen: es steht am dunklen Fenster, tappt durch den Flur oder klopft bei dir („Ab ins Bett mit dir“) · stirbt Mama oder Papa, schließt sich das Kind dir an
- **Freundschaft & Feindschaft:** neun Stufen von „stark verfeindet“ bis „guter Freund“ · nach oben wird es zäh, Plaudern zählt nur zweimal am Tag voll · **guter Freund** erst nach mehreren gemeinsamen Partien und Gegenständen in beide Richtungen, **stark verfeindet** erst nach Klauen, Beleidigen, Rammen oder Schlagen – und seiner Rache · befreundete Gäste kommen auf Bitte mit („Komm mit“), gute Freunde schließen sich auch von selbst an und besuchen dich in Zimmer 13 · wütende Gäste rempeln dich an, Erzfeinde drohen und schlagen zu, wenn sie dich allein erwischen · **Linksklick auf einen Gast** (ohne Taschenlampe in der Hand) schlägt ihn – erst nach Nachfrage; er flieht oder schlägt zurück, Zeugen reden darüber · im Rennen umgerannte Gäste stolpern · Schläge verletzen dich: langsamer, Blutspur, heilt mit der Zeit
- **Mäxchen an der Hotelbar:** Bluff-Würfeln gegen Gäste um Geld oder Gegenstände (Einsätze liegen echt auf dem Tisch), Herausforderungen & Revanche, Gäste würfeln untereinander (zuschauen verrät ihre Ticks), gezinkte Würfel aus Zimmer 0117, Abbruch bei Vorwarnung
- **Schach in der Lobby:** Schachtisch mit Brett (das Brett ist ein Gegenstand – ohne Brett kein Schach) · Gast einladen oder Herausforderung annehmen, Einsätze wie bei Mäxchen · du spielst Weiß und ziehst mit der Maus auf dem Brett von oben (Figur anklicken, dann Zielfeld; Bauern werden zur Dame) · Remis anbieten, aufgeben, absichtlich verlieren (gute Spieler merken es) · jeder Gast spielt verschieden stark (Edna ordentlich, Bruno schwach und stolz, Mila stark) · Gäste spielen auch untereinander – wer 30 s zusieht, kennt danach ihre Stärke · leise, aber man ist konzentriert; bei einer Vorwarnung springt der Gast auf
- **Kürbismann:** früher Rezeptionist, von zwei Süßes-oder-Saures-Kindern mit seiner eigenen Axt geköpft – jetzt jagt er alle, die Spaß haben · das Hotel hat einen unsichtbaren Spaßwert: er sinkt von selbst, jeder Gast mit Spaß hebt ihn (Spieltisch und Feier stark, Schmücken, Suppe und Süßes oder Saures weniger, du zählst mit), Deko platzieren kurz auch – über der Schwelle kommt er mit hoher Chance, je mehr Spaß, desto sicherer (erst nach dem ersten Angriff des Monsters) · war er bis Tag 15 noch keine zwei Mal da, kommt er an Tag 15 und 16 sicher · er kündigt sich 3–4 Minuten vorher an und kommt dann sicher: alle Lampen werden rot und flackern, der Plattenspieler leiert überall eine schrille Melodie, alle Kinder bleiben stehen und singen das Lied vom Kürbiskopf · wo er ist, leuchten die Lampen greller · klettert an der Straßenseite aufs Lobbydach, steht kurz an der Dachkante über dem Garten, springt vor einer Glastür der Lobby herunter (der Aufprall ist weit zu hören) und sucht zuerst die Lobby ab – wen er dort sieht, den jagt er · danach nimmt er sich immer den Nächsten vor: zu Feiernden und Spielenden sprintet er, sonst folgt er dem nächsten Gast, und sobald er ihn sieht, rennt er los – schneller als Gäste, langsamer als du beim Rennen · holt mit dem Beil aus (Gäste erstarren, du kannst noch wegrennen) · dich verfolgt er, sobald er dich in der Nähe sieht (etwa 14 m, auch ohne Spaß), sonst, wenn du selbst mitfeierst, spielst oder schmückst und ihm am nächsten bist, und er erschlägt jeden, der ihm im Weg steht – auch ohne Spaß · im Partyraum greift er jeden an, den er sieht (auch dich), und zwar zuerst · nie zusammen mit Monster oder Lakengeist im Haus – immer nur eine Bedrohung auf einmal · Kindern tut er nie etwas (sie locken ihn aber mit und schützen niemanden) · verstecken oder außer Sicht bleiben rettet · keine Opfergrenze: 2–3 Minuten bleibt er (hat keiner Spaß, streift er umher), dann hat er keine Lust mehr und verlässt das Hotel durch den Haupteingang · Opfer bleiben in einer Blutlache liegen, wo er hinkommt, verstummt die Musik und Partien brechen ab
- **Lakengeist:** ab dem 2. Tag · war er bis Tag 10 noch nie bei dir, kommt er sicher als Warnung in den Flur, sobald du dort allein bist (schwebt heran und verschwindet) · war er an Tag 20 noch keine drei Mal da, holt er auf: jeder dunkle Raum mit Fenster ruft ihn sicher, und er kommt nach wenigen Sekunden wieder · man hört ihn, solange er da ist (geisterhafter Klang aus seiner Richtung), von seinem Saum rieseln weiße Flocken · kommt, wenn du in einem Raum mit Außenfenster bist, in dem das Licht aus und der Vorhang offen ist (sehr wahrscheinlich beim Betreten, danach alle paar Sekunden wieder, frühestens 45 s nach dem letzten Besuch) · **Fenstertüren** zur Terrasse oder zum Balkon haben keinen Vorhang: Ist dort das Licht aus, kommt er noch wahrscheinlicher und öffnet sie ab dem 3. Mal lautlos · wird von Mal zu Mal dreister: schwebt heran → blutige Handabdrücke auf der Scheibe und Hypnose mit kreisenden Händen (macht langsamer, zieht den Blick) → kommt herein und würgt → ab dem 4. Mal auch durch den zugezogenen Vorhang · losreißen nur mit wildem Hin und Her (Balken, der Griff zieht ständig zurück) – das schafft man selten, sonst tot · **im Schrank** wartet er 20–35 s vor den Türen und packt zu, wer herauskommt; dann fliegt er hinein (40 %, ab dem 6. Mal 75 %; keuchen verrät dich, Luft anhalten hilft etwas) oder gibt auf · Gäste als Zeugen vertreiben ihn, in Gesellschaft kommt er nicht · ab dem 6. Mal auch im Flur, wenn alle schlafen · **Schlafmangel:** jede Nacht ohne Schlaf macht ihn häufiger, nach zwei Nächten kommt er schon früher in den Flur, nach drei sicher, sobald du allein im Flur bist · **kommt auch zu Gästen** (wach im Dunkeln bei offenem Vorhang, eigene Stufen) – wer sich nicht losreißt, bleibt als Leiche liegen
- **Schreck & Erlebnisse:** Gäste, die eine Blutlache, eine Leiche oder den Lakengeist sehen, bleiben 2–5 s geschockt stehen – je nach Charakter Hände hoch und weglaufen, starr vor Schreck oder weinend · jeder Fund erschreckt einen Gast nur einmal · beim nächsten Gespräch erzählen sie davon, am selben Tag kommt es beim Reden über das Monster wieder vor · wer den Geist erlebt hat, lässt den Vorhang einen Tag lang zu
- **Taschenlampe:** an der Rezeption (halb leer) · Licht zum Sehen, aber kein Schutz – wer sie trägt, wird weiter gesehen · Batterien (Wäscherei, Keller, manche leeren Zimmer, Skeptiker verkaufen sie) einlegen wie eine Kerze in den Kürbis · flackert in Monsternähe, im Versteck bleibt sie aus · **UV-Aufsatz** in Zimmer 0118: UV leert eine Batterie in ~9 s; steht das Monster ~1 s im Kegel, flieht es – kommt aber bald wieder, sucht rund um Zimmer 13 und braucht jedes Mal länger · UV zeigt verblasste Fußspuren, Schrift an Wänden und eine zweite Zeile auf jedem Warnungszettel
- **Licht & Fenster:** ein Lichtschalter pro Raum (in großen Räumen an jedem Eingang einer, sie schalten gemeinsam), gedimmte Wandlampen und Kerzen (Holzdecken), vier Pendelleuchten über der Lobby, Glühbirnen herausdrehen und woanders einsetzen (auch Gäste klauen sie), Birnen brennen bei starkem Flackern oder in Monsternähe selten durch · Licht aus lockt das Monster an · Außenfenster mit Vorhängen (Mondlicht, Sicht in beide Richtungen) · Nachthimmel mit Mond, ziehenden Wolken und Sternen über dem Garten und hinter den Fenstern, ringsum eine schwarze Waldkante
- **Kostüme:** ab dem 25. Oktober verkleiden sich die Gäste – Bettlaken (wie der Lakengeist, nur die Schuhe verraten sie, kein Name), Hexenhut, glühender Kürbiskopf, Vampirumhang · selbst verkleiden: das Bettlaken in Zimmer 13 überwerfen ([Linksklick], [G] mit leeren Händen ab) – Sicht durch die Augenlöcher, Gäste erkennen dich nur aus der Nähe
- **Bar:** etwas trinken (1 Geld) nimmt Schock – angetrunken schwankt der Blick, die Maus zieht nach, man stolpert (Lärm) und sieht leicht verschwommen, betrunken wabert alles, verschwimmt deutlich und doppelt, betrunken halluziniert man, wer im Rausch schläft, hat Kater · Gäste trinken auch (schwanken, „*hicks*“, erzählen mehr) · eine Runde ausgeben · betrunken blufft man beim Mäxchen schlechter, Milchglas zwischen Flur und Zimmern (nur Umrisse)
- **Kalender:** vom 1. Oktober bis Halloween, ein Ingame-Tag ≈ 5 Minuten, draußen immer Nacht · Abreißkalender in Zimmer 13, Datum im Spielmenü und in den Spielständen
- **Menüs & Speichern:** Titelbildschirm, Spielmenü (Esc), Einstellungen (Helligkeit mit Testbild, Spiegelungen, PS1-Look, Ton, Maus, weniger Flackern, Untertitel) · Speichern nur am **Tagebuch in Zimmer 13** (3 Slots, nicht während Vorwarnung/Monster, Kürbismann im Hotel oder Lakengeist bei dir) · Autosave bei wichtigen Ereignissen in sicheren Momenten · nach dem Tod letzten Spielstand laden
- **Lärm & Sichtbarkeit:** jedes Geräusch in der Welt ist zugleich Lärm mit eigener Hörweite (Tür knarrt 5 m, Schranktür 4 m, Rennen 10 m, Telefon 18 m, Schrei 20 m, Feier 25 m …), gedämpft durch Wände, geschlossene Türen und Geschossdecken · **Schreie** echt und aus ihrer Richtung: jeder Gast mit eigener Stimme (Mann, Frau, Kind, alt tiefer, in Panik höher, betrunken tiefer) – wer erschrickt, schreit aus, wer geholt wird, verstummt jäh; beim Kürbismann bricht die Axt den Schrei ab · beim eigenen Tod kreischt es, die Katze kreischt auf der Flucht · Schritte machen nur auf Holz und Fliesen Lärm, geduckt gar keinen · auf Teppich und Fliesen (Lobby, Küche) hört man die eigenen Schritte und die der Gäste (leise, Kinder heller), auf Teppich das Monster aber nicht · das Monster geht in Hörweite nachsehen, bis zur doppelten Hörweite wird es neugierig · Gäste hören Schreie und Knalle mit halber Reichweite: sie erschrecken, sehen nach, erzählen davon oder geraten in Panik · Monster und Gäste sehen nach derselben Rechnung: Licht am Ort, **Licht in der Hand**, Rennen, Ducken, Stillstehen – im Dunkeln und geduckt klaut man unbemerkter, wer mit Kerze in den Schrank steigt, wird gesehen
- **Das Hotel schmückt sich:** Ab und zu ruft ein Gast zum gemeinsamen Schmücken auf – eine Zimmertür, ein Flurabschnitt, eine Flurecke oder eine Wand der Lobby (der Partyraum ist immer geschmückt) · zwischendurch trägt immer wieder ein Gast allein ein Stück Deko herum – aus einer Kiste im Hotel in sein Zimmer oder aus dem Koffer in die Lobby · Gäste aus der Nähe holen Deko aus ihrem Zimmer und tragen sie sichtbar hin: Lichterketten, Lakengespenster, Fledermäuse, Spinnen, Spinnweben, Kürbisse, Totenköpfe, Besen, Laub · du wirst per Meldung eingeladen (in Zimmer 13 per Anruf) · wer selbst Deko dazuhängt oder dabei bleibt, gewinnt die Mitmacher als Freunde, und allen sinkt die Angst · Schmücken ist Spaß und lockt den Kürbismann · nie bei Feier, Nachtruhe oder wenn es unterwegs ist · gegen Ende Oktober immer häufiger und größer – die Deko bleibt hängen und wächst bis Halloween · immer sind ein, zwei Gäste gemächlich mit Deko unterwegs und hängen sie dorthin, wo im Hotel noch am wenigsten hängt · ab Monatsmitte laufen zwei Aktionen gleichzeitig · **großes Schmücken** (anfangs etwa alle drei Tage, in der letzten Woche täglich): 10–20 Gäste schmücken einen ganzen Flurbereich oder die Lobby, jeder mit einem Armvoll Deko, zum Schluss fliegt Konfetti · **selbst schmücken:** im Gespräch ab „nett“ „Wollen wir zusammen …“ → „… hier schmücken?“ (wo du stehst, auch an Zimmer 13; je Gast einmal am Tag, seine Freunde kommen mit) oder „… ein großes Schmücken ausrufen?“ (wenn mindestens 8 Gäste dir freundlich gesinnt sind, einmal am Tag)
- **Deko-Suche:** Gäste ziehen los und suchen Deko (Laub, Dekokiste, Wäschekiste, Kerzen – Mutige auch Spinnweben in dunklen Ecken oder alte Deko im Keller) · begegnet dir einer, fragt er, ob du mitkommst („Klar, ich such mit!“), oder du fragst selbst („Wollen wir zusammen …“ → „… Deko suchen gehen?“) · er geht voran und wartet auf dich, am Fundort teilt er: eins für dich, eins für ihn · er mag dich mehr und erzählt es seinen Freunden
- **Zerplatzen:** Jeder Kürbis (auch geschnitzt oder ein Zierkürbis), der tiefer als 3 m fällt – etwa vom Balkon oder von der Galerie –, zerplatzt · Stücke fliegen davon · übrig bleibt **Kürbismatsch** als Spritzer in Größe und Farbe des Kürbisses (Zierkürbis ~40 cm, Riesenkürbis 4–5 m – der reicht für 10–20 Hände voll und wird beim Aufsammeln kleiner): aufsammeln und in der Küche zu Suppe kochen, sonst verblasst er nach einem Spieltag kaum merklich und ist weg
- **Kochen:** Herd in der Küche · Kürbis in der Hand [E] → große Sorten in den Topf, kleine (Hokkaido, Butternut, Türkenturban, Zierkürbis) in die Pfanne · mit dem Messer [E] klein schneiden, dann kocht es (Suppe 40 s, Braten 25 s), es dampft · **Kürbissuppe:** bis zu sechs Gäste aus der Nähe kommen zum Essen (weniger Angst, sie mögen dich mehr, werden untereinander Freunde), du isst am Topf (weniger Schock) – gemeinsames Essen ist Spaß · **gebratener Kürbis:** Teller, mit [Linksklick] essen (weniger Schock) oder verschenken (in der Lieblingssorte besonders willkommen)
- **Überlebende & Verletzungen:** etwa 4 von 10 Gästen überleben einen Angriff · vom Monster nur **Kratzer** (im Gesicht, am Arm) · vom Kürbismann eine **Axtwunde** (Verband, humpelt, kann nicht rennen, hinterlässt eine Blutspur) · vom Lakengeist **Würgemale** (am Hals, spricht heiser, man hört ihn schwer atmen) · nach Axt und Würgen liegt er einen Spieltag ansprechbar im Bett, heilt in 2–3 Tagen (Besuche und Geschenke helfen) · als **Zeuge** erzählt er bei jedem Besuch ein neues, zuverlässiges Detail und erzählt es auch Freunden und Gästen ringsum · solange er verletzt ist, zählt alles doppelt, Geschenke dreifach – passende (Kerze nach dem Würgen, Süßes oder gebratener Kürbis im Bett) noch mehr · wer befreundet ist und ihn nie besucht, kränkt ihn
- **Geschenke:** Gäste nehmen Geschenke in die Hand und tragen sie in ihr Zimmer, Essbares essen sie · Schachbrett und Würfelbecher gehören dem Hotel und lassen sich nicht verschenken
- **Freundschaften unter Gästen:** Gäste werden Freunde, wenn sie zusammen schmücken, Deko suchen, Suppe essen, spielen, feiern oder an der Bar trinken; Familien und Zimmernachbarn sind es von Anfang an · wer mit dir befreundet ist, erzählt seinen Freunden Gutes über dich – sie mögen dich dann auch mehr (bis „befreundet“) und sagen dir beim nächsten Gespräch, von wem sie es haben
- **Feiern:** Plattenspieler im Partyraum (selbst ausrichten; solange Musik läuft, steigen leuchtende Noten in Regenbogenfarben auf) oder spontan von Gästen – drei Musikstücke im Wechsel (der alte Walzer und zwei neue), laut, also lockt es das Monster an; währenddessen sind die Zimmer leer · Gäste tanzen verschieden (Gastmodelle: Chicken Dance, Macarena, Hip-Hop; Klötzchenfiguren: hüpfen, wiegen, drehen, Arme hoch, Twist, schunkeln), jeder hat seinen Lieblingstanz · über der Tanzfläche hängt eine Discokugel, die die Lampen spiegelt und funkelt – auf Feiern dreht sie sich und wirft Lichtpunkte über Wände, Decke und Tänzer · bunte Strahler unter der Decke wechseln auf Feiern langsam die Farben (ab und zu alle gemeinsam) · Konfetti schießt über der Tanzfläche hoch, rieselt herab und bleibt bunt am Boden liegen, bis es nach einer Weile verblasst
- **Katzenraum** im Obergeschoss: Kratzbäume und vier eigene Katzen (Luna, Fussel, Tiger, Mausi) · der einzige Raum, in dem man wirklich sicher ist – das Monster kommt nicht hinein, der Lakengeist zu niemandem, der drin ist
- **Hotelkatzen:** Minka, Socke und Kasimir streifen durchs Hotel, schlafen auf Sofas und Betten, folgen ihrem Lieblingsgast und miauen vor geschlossenen Türen · streicheln beruhigt (Spieler und Gäste) · das Monster tut ihnen nichts, aber sie fliehen und **weinen**, wenn es nah ist – eine Frühwarnung, auch durch Wände · sie werfen Kürbisse und Kerzen um (dann schützen sie nicht, bis man sie aufstellt) · selten bringen sie dir etwas vor die Tür (manchmal die Deko eines Gastes – der verdächtigt erst dich) oder legen sich auf dein Bett · Liegeplätze auch auf der Rezeption und auf Fensterbänken · Gäste reden über die Katzen · **tragen:** nach dem Streicheln mit [E] auf den Arm (scheue erst, wenn sie dich kennen), schnurrt und beruhigt, [G] setzt sie ab, nach einer Weile springt sie selbst herunter – naht das Monster, faucht und kratzt sie und flieht
- **Kommoden im Flur:** vier je Geschoss, jede Schublade lässt sich aufziehen – beim ersten Mal liegen manchmal Münzen oder ein Gegenstand darin (Kerze, Glühbirne, Batterie, Messer, gezinkte Würfel, Süßigkeiten); was man hineinlegt, bleibt drin
- **PS1-Look:** 480×270, Vertex-Snapping, Dithering, Farbreduktion – im Einstellungsmenü mit einem Schalter ganz abschaltbar (dann auch feinerer, dichterer Regen) · Kellerwände aus Brettschalungsbeton (ohne PS1-Look schärfer und mit Relief im Licht der Taschenlampe) · Lobbyboden aus poliertem Marmor, auf dem Lampen, Kerzen und Taschenlampe glänzen und sich Wände, Lampen und Gäste spiegeln (auch im Poolwasser) · Tapeten mit Vertäfelung, die im Licht unterschiedlich glänzen (Lack, Satin, stumpfe Rauten) und an Fugen und Leisten Glanzkanten zeigen, dazu fleckige, matte Stellen
- **Altersempfehlung ab 16** (selbst eingeschätzt, keine USK-Prüfung): Hinweis mit Inhalten beim ersten Start, Kennzeichen im Titelbildschirm (`scripts/ui/title_screen.gd`)

Bis auf das Monster, die Lobby-Sofas, die Flaschen in der Bar, den Plattenspieler, die Taschenlampe, die Glühbirnen, die Discokugel, die Wanduhr über dem Haupteingang, die Pflanzkübel, die Bäume im Garten, die Tür- und Fensterrahmen, die Tapeten, die Kellerwände und der Lobbyboden (`assets/textures/`) sind alle Modelle, Texturen und Sounds Platzhalter (prozedural erzeugt) und werden später durch Blender-Modelle (glTF) und echte Sounds ersetzt. Das Monster-Modell (`assets/models/monster.glb`) baut `tools/build_monster.py` in Blender aus dem Meshy-Original:

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

Die Discokugel (`assets/models/disco_ball.glb`) ist „Disco Ball“ von [araghon007](https://sketchfab.com/araghon007) ([Sketchfab](https://sketchfab.com/3d-models/disco-ball-e4c3b485680843c7a7a827d04ac28743), CC-BY 4.0) – von 31 744 auf 2208 Dreiecke, die Spiegelplättchen stecken in einer gebackenen Normal Map:

```bash
"/c/Program Files/Blender Foundation/Blender 4.3/blender.exe" -b --python tools/build_disco_ball.py -- assets/source/disco_ball.glb assets/models/disco_ball.glb
```

Die Wanduhr über dem Haupteingang (`assets/models/clock.glb`) – Rahmen und die beiden Zeiger als eigene Teile, damit sie sich drehen können:

```bash
"/c/Program Files/Blender Foundation/Blender 4.3/blender.exe" -b --python tools/build_clock.py -- assets/source/clock.glb assets/models/clock.glb
```

Die Fototexturen (PBR-Sets) sind von Julio Sillet ([JulioVII auf itch.io](https://juliovii.itch.io), CC-BY): `Concrete_WoodPattern_01` (Kellerwände), `TilesMarble_01` (Lobbyboden), `pool/Tiles_06` (Poolbecken), `Stone_EngraveWall_01` (Wände der Poolhalle) `TilesBasic_01` (Umgang der Poolhalle) und `TerrazzoDark_01` (Säulen der Lobby) – jeweils nur die genutzten Karten, verkleinert mit `tools/photo_set.gd` (TECHNIK.md, „Fototexturen“).

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

Den Kürbismann (`assets/models/pumpkin_man.glb`, Spielkonzept 4.19) baut `tools/build_pumpkin.py` aus zwei Meshy-Modellen: der Figur (Auto-Rigging mit Skelettvorlage „Mixamo“, alle Animationen, einzelne Datei – Gehen, Rennen, Drehsprung) und der Axt (eigenes Modell ohne Rig). Das Beil kommt als eigenes Netz an die rechte Hand, deren Finger sich um den Stiel schließen; dazu dieselben Mixamo-Animationen wie bei den Gästen und eigene aus `assets/source/anim/pumpkin/` (der Schlag als `attack.fbx` – rechtshändig wie bei Mixamo üblich, linkshändige mit „Mirror“ herunterladen). Ein optionaler vierter Pfad legt Vorschaubilder ab (Ruhe, Hand, jede Animation):

```bash
"/c/Program Files/Blender Foundation/Blender 4.3/blender.exe" -b --python tools/build_pumpkin.py -- assets/source/pumpkin_man.glb assets/source/pumpkin_axe.glb assets/models/pumpkin_man.glb
```

Den Lakengeist (`assets/models/ghost.glb`, Spielkonzept 4.18) riggt `tools/build_ghost.py` selbst – mit Armen und Fingern. Ein optionaler dritter Pfad legt Vorschaubilder ab (Ruhe, gekrümmte Finger, gehobene Arme):

```bash
"/c/Program Files/Blender Foundation/Blender 4.3/blender.exe" -b --python tools/build_ghost.py -- assets/source/Meshy_AI_floating_ghost_3d_1017173231_image-to-3d-texture.glb assets/models/ghost.glb
```

Die Tür- und Fensterrahmen (`assets/models/frames.glb`, Spielkonzept 7.2) braucht kein Ausgangsmodell: `tools/build_frames.py` zieht Profile im Craftsman-Stil aus. Ein optionaler zweiter Pfad rendert eine Vorschau-Tür:

```bash
"/c/Program Files/Blender Foundation/Blender 4.3/blender.exe" -b --python tools/build_frames.py -- assets/models/frames.glb
```

Den Handlauf der Pooltreppen (`assets/models/pool_handrail.glb`) baut `tools/build_handrail.py` ebenfalls ohne Ausgangsmodell: ein Rohr mit drei gebogenen Knicken. Optional danach Tiefe und Lauflänge des Beckens (Standard 1,4 und 2,1 m) und ein Pfad für eine Vorschau von der Seite:

```bash
"/c/Program Files/Blender Foundation/Blender 4.3/blender.exe" -b --python tools/build_handrail.py -- assets/models/pool_handrail.glb
```

## Debug-Startparameter

Nach `--` an Godot übergeben, z. B. `--path . -- --trace --warn`. Alle Aktionen lassen sich auch im laufenden Spiel in der **Debug-Konsole** (^) tippen – dort ohne `--`, Wert mit Leerzeichen oder `=`.

| Parameter | Wirkung |
|-----------|---------|
| `--trace` | Monster, Gäste und Meldungen alle 2 s in die Konsole, dazu jedes Lärmereignis (wer es hört und wie er reagiert) |
| `--noise=door` | alle 6 s Lärm dieser Art am Spieler (`door`, `hide`, `run`, `scream` … – Tabelle in `scripts/util/senses.gd`) |
| `--warn` | sofort Vorwarnung → Monster erscheint |
| `--pumpkin=ankündigung` · `--pumpkin=ankündigung,60` | Kürbismann kündigt sich an: Lampen rot, schrille Melodie, Kinder singen – in 20 (60) Sekunden kommt er übers Lobbydach |
| `--doll` · `--doll=30` · `--doll=30,13` · `--doll=kind` | Puppe: in 20 (30) Sekunden Angriff mit einem Opfer, sie liegt sofort vor der schwächsten bewohnten Tür (bzw. vor Zimmer 13) und es grollt · kind: ein Kind holt sie und legt sie vor die Tür seiner Familie (mit `--trace`: `[Puppe]` mit Weg, Einbrüchen und Opfern) |
| `--intent=roam` / `one` / `rampage` / `4` | Absicht beim Aufbruch erzwingen: umsehen, ein, zwei oder n Opfer (mit `--trace` stehen Absicht und Flackerwelle in der Konsole) |
| `--bold=90` | Dreistigkeit setzen |
| `--friend=edna` / `--enemy=bruno` · `--relation=bruno,-90` | befreundet / verfeindet · Beziehung setzen (ab ±80 mit den nötigen Taten) |
| `--follow=edna` · `--visit=edna` · `--attack=bruno` · `--punch=mila` | Gast kommt mit · besucht Zimmer 13 · schlägt dich · steht vor dir und wird geschlagen (mit Nachfrage) |
| `--kill=mila` | Gast nach 3 s vom Monster holen lassen – mit 40 % reißt er sich los und hat nur Kratzer |
| `--first-attack` · `--attacks=3` | Feier + erster Angriff nach 3 s · so viele Angriffe gab es schon (> 2: nicht mehr harmlos – ob es holt, entscheidet die Angriffschance nach Tag, bis Tag 4 nur 20 %; sicher mit `--intent=one` oder spät mit `--day=10`; mit `--trace` stehen Angriff, Tag, Chance und Absicht beim Aufbruch sowie `[Geholt]`/`[Erschreckt]` in der Konsole) |
| `--knock` · `--knock-fake` · `--answer` | Klopfen an Zimmer 13 · falsche Stimme · Spieler öffnet nach 4 s |
| `--decorate` · `--decorate=edna` · `--decorate=hin` · `--decorate=edna,hin` · `--decorate=lobby,hin` · `--decorate=allein,hin` · `--decorate=allein,lobby,hin` | Schmück-Aktion sofort: ein Gast (oder dieser) ruft auf, Gäste aus der Nähe holen Deko und hängen sie an eine Tür oder in den Flur · ohne `hin` kommt die Einladung in Zimmer 13 per Anruf (mit `--answer` nimmst du nach 4 s ab) · mit `hin` stehst du davor und siehst zu (mit `--trace`: Stelle, Mitmacher, jedes Stück, Ende; z. B. mit `--day=28` für viele Mitmacher) · `lobby`: an einer Wand der Lobby · `allein`: ein Gast (oder dieser) holt allein Deko aus einer Kiste und hängt sie in seinem Zimmer auf, mit `lobby` aus dem Koffer in die Lobby, mit `haus` irgendwohin ins Hotel, wo wenig hängt |
| `--decorate=gross[,gast][,lobby][,hin]` · `--decorate=hier[,gast]` | großes Schmücken: 10–20 Gäste schmücken mehrere Stellen eines Flurbereichs (mit `lobby`: der Lobby), jeder mit einem Armvoll Deko · `hier`: wie „… hier schmücken?“ im Gespräch – geschmückt wird, wo du stehst (mit `--tp`/`--pos`) |
| `--search[=gast][,mit]` | Deko-Suche: ein Gast (oder dieser) zieht los · `mit`: du gehst mit (folgst ihm von selbst), er teilt am Fundort (mit `--trace`: Fundort, Teilen, Beziehung) |
| `--fall` · `--fall=h` · `--fall=h,sorte` | nach 1 s fällt ein Kürbis 1,5 m vor dir aus h m Höhe (Standard 4) – ab 3 m zerplatzt er zu Kürbismatsch (mit `--trace`: Fallhöhe, Spritzergröße, Hände voll, später „verblasst und weg“) · Sorte wie im Plan (`giant`, `casper` …) oder `mini` (Zierkürbis); draußen testen, z. B. `--pos=45,0.1,-37 --fall=5,giant --trace` |
| `--cook=suppe` · `--cook=braten` · `--cook=suppe,fertig` | Kochen: Kürbis liegt geschnitten im Topf bzw. in der Pfanne, du stehst am Herd · `fertig`: gleich fertig – bei der Suppe kommen die Gäste zum Essen |
| `--cook=gast` · `--cook=gast,edna` | ein Gast (oder dieser) kocht gleich Kürbissuppe – er steht 4 m vor dem Herd, du daneben (`--trace`: `[Kochen]`) |
| `--wound=gast,scratch\|axe\|choke[,hin]` | Gast hat einen Angriff überlebt: Kratzer, Axtwunde (Blutspur, ein Tag im Bett) bzw. Würgemale (heiser, schweres Atmen) · `hin`: steht vor dir statt im Bett, Blick passend geneigt (mit `--talk=gast` erzählt er als Zeuge; mit `--trace`: `[Verletzt]`) |
| `--pals=gast1,gast2` | Weitererzählen: gast1 ist mit dir befreundet, beide sind Freunde und stehen vor dir – gast1 erzählt gast2 gleich Gutes über dich (mit `--trace`: Beziehung vorher und nachher) |
| `--trick` · `--trick=gast24` | Süßes oder Saures: ein Kind (oder dieses) zieht sofort von Tür zu Tür (mit `--trace`: Türen, Süßes oder Saures) |
| `--trick=13` · `--trick=13,3` | ein Kind steht vor Zimmer 13 (Tür auf) und will Süßes – mit `,3` gibst du ihm drei Süßigkeiten, eine je 1,5 s (`--trace`: Beziehung je Stück) |
| `--mess` · `--mess=wachs` | Kürbismatsch (bzw. großer Wachsfleck) 3 m vor dir, ein ordentlicher Gast hinter dir putzt ihn weg bzw. bringt ihn in die Küche (`--trace`: `[Flecken]`) |
| `--prank=pumpkin` · `--prank=fire,111` | Streich eines Kindes vor Zimmer 13 (bzw. 111): `leaves`, `topple` (ein Kürbis steht daneben), `pumpkin`, `candle` (wirft aus 2 m), `fire` (brennende Kerze, daneben Laub und Lakengespenst) – der Bewohner steht im Flur und verpetzt das Kind (`--trace`: `[Streich]`, `[Feuer]`, `[Feinde]`) |
| `--call=edna` · `--call=creepy` / `dead` / `door` · `--answer` | Telefon in Zimmer 13 klingelt: Gast (warnt, wenn das Monster unterwegs ist) · Atmen · Verschwundener · es steht vor der Tür · Spieler nimmt nach 4 s ab |
| `--dial=0111` · `--dial=lobby` | aus Zimmer 13 eine Nummer anrufen (0 = Rezeption) · Wählseite am Haupttelefon |
| `--wallblood[=smear]` | Blutspritzer (mit `smear`: blutige Schmierspur) an die Wand, auf die du schaust |
| `--costumes[=art]` | alle Gäste sofort verkleidet (sonst ab dem 25. Oktober) – jeder sein Kostüm, mit `sheet`, `witch`, `pumpkin` oder `cape` alle gleich |
| `--disguise` | Bettlaken übergeworfen – Sicht durch die Augenlöcher, Gäste erkennen dich nur aus der Nähe |
| `--drunk=n[,gast]` | n Gläser getrunken – du, oder mit Gast er (ab 2 angetrunken, ab 3 betrunken) |
| `--weather=klar\|regen\|gewitter\|blitz` | Wetter sofort in voller Stärke (Spielkonzept 7.8) · `blitz`: Gewitter und nach 3 s ein Blitz (mit `--shot-on=lightning` als Screenshot) |
| `--party[=gast]` | Feier im Partyraum starten – mit Gast lädt er ein (etwa drei Viertel kommen), sonst du (nur Eingeladene und Freunde) |
| `--cat=minka` · `--cat=socke,tragen` | Hotelkatze vor den Spieler setzen (`minka`, `socke`, `kasimir`, aus dem Katzenraum `luna`, `fussel`, `tiger`, `mausi`) · gleich auf den Arm |
| `--pumpkin` · `--pumpkin=run` · `--pumpkin=jagd` · `--pumpkin=jagd,edna` · `--pumpkin=dach` · `--pumpkin=garten` | Kürbismann als Testfigur ohne Verhalten 2,5 m vor dich, Animation in Schleife: `walk` (Standard), `run`, `spin_jump`, `chicken`, `macarena`, `hiphop` – erneut aufgerufen ersetzt er den alten · mit `jagd` kommt er übers Lobbydach und jagt dich bzw. den Gast (auch ohne Feier und vor dem ersten Angriff; mit `--trace` jeder Schritt in der Konsole) · `--pumpkin=dach` wie F9 · `--pumpkin=garten`: gleich an den Kürbisbeeten im Garten, ohne den Weg übers Dach |
| `--tp=lobby` · `--tp=13` · `--tp=0126` · `--tp=1157` · `--tp=edna` | hinspringen: Ort aus der F6-Liste (lobby, bar, partyraum, küche, garten, galerie, treppenhaus, westflügel, keller, kellergang, technikraum, wäscherei, obergeschoss, katzenraum, bibliothek), jedes Zimmer (Türschild oder Nummer, auch oben und verschlossene – die sind dunkel und leer), vor einen Gast · in der Konsole `tp 1157` |
| `--attic-door` | Kniestocktür zum Ansehen: Solange kein Dachgeschoss gezeichnet ist, wird beim Aufbau die erste 0,8 m breite Tür im OG1 zur Dachbodentür, du stehst vor ihrer Bandseite (nur als Startparameter; mit `--flashlight` sieht man mehr) |
| `--time=+1` · `--load-slot=2` | Spieltage vor-/zurückspulen · Spielstand laden (in der Konsole: `load 2`, `save 2` = `--diary=2`) |
| `--console` · `--console=guests;tp keller` | Debug-Konsole nach 1 s öffnen, optional Befehle (mit `;` getrennt) eintippen – für Screenshots |
| `--talk=edna` | Gespräch öffnen |
| `--look=gast1` · `--look=gast1,carry` | vor einen Gast stellen, ohne Dialog (er bleibt stehen) · mit Haltung: `carry`, `panic`, `dance`, `sit`, `walk` – zum Prüfen der Gastmodelle |
| `--shock=bruno` · `--shock=mila,corpse` · `--shock=edna,ghost3` · `--shock=mila,tür` | Gast erschrecken: Blutlache bzw. Leiche vor ihm im Flur (Spieler sieht zu) · Lakengeist kommt zum n. Mal an sein dunkles Zimmerfenster (ab 3 würgt er; Zimmer ohne Außenfenster gehen nicht) · Lakengeist lautlos vor seiner Tür (ein Lakengespenst hängt dort), der Gast starrt hin und geht irgendwann aufmachen (mit `--trace`) · mit `--talk=bruno` erzählt er danach davon |
| `--dice=bruno` · `--autoplay` | Mäxchen-Partie starten · Antworten automatisch wählen |
| `--chess=mila` · `--autoplay` | Schachpartie in der Lobby starten · der Spieler zieht selbst (schwach), mit `--trace` Stärke des Gastes und Ergebnis |
| `--challenge=bruno` · `--challenge=edna,chess` | Gast fordert dich heraus (Mäxchen bzw. Schach) |
| `--pos=x,y,z,winkel[,neigung]` · `--monster=x,y,z` | Spieler versetzen (Neigung in Grad, positiv = nach oben) · Monster erscheinen lassen |
| `--lure` | nach 1 s kommt das Monster zu dir (wie F7) |
| `--pool=still` · `--pool=tremor` · `--pool=slosh` | Poolwasser, als wäre das Monster nah: spiegelglatt · feine zitternde Ringe · Becken schwappt mit Schaum und Gischt (`--pool=off` in der Konsole: wieder normal) |
| `--splash=x,z` | nach 1 s platscht es an dieser Stelle im Pool (Wellenring, der bricht, und Spritzer), z. B. `--splash=18,-105 --pos=18,0.1,-100,0,-25` |
| `--flashlight` · `--flashlight=uv` | eingeschaltete Taschenlampe mit voller Batterie in die Hand · mit UV-Aufsatz im UV-Modus |
| `--bag` · `--bag=süßes,cola,limo,zierkürbis,kerze,messer,batterie,birne,uv,würfel,becher` | Kleines in die Tasche (Spielkonzept 3.2): ohne Angabe Süßigkeiten, Cola, Zierkürbis und Batterie (höchstens 6) |
| `--bag-menu` · `--bag-menu=n` | Tasche offen halten wie mit gehaltenem Q, Fach n gewählt – für Screenshots |
| `--deco=gespenst` · `lichter` · `netz` · `laub` · `zierkürbis` · `fledermaus` · `spinne` · `totenkopf` · `besen` · `--deco=lichter,g` | Deko in die Hand – an eine Wand sehen, [G] hängt auf bzw. verstreut · mit `,g` nach 1 s selbst [G] (mit `--pos` auf eine Wand, z. B. `--pos=55,0.1,-7.9,180,14`) |
| `--sprint` · `--winded` | vorwärts rennen, bis die Ausdauer leer ist · gleich außer Atem starten (mit `--trace`: „außer Atem“ und „beruhigt“ in der Konsole) |
| `--pocket` · `--show=map` / `keys` / `compass` | Kompass, alle Kartenblätter und Schlüssel 18 einstecken · Karte (Schlüsselblatt oben) bzw. Kompass hervorholen wie mit gehaltener Taste |
| `--shot=pfad.png --frames=n` · `--shot-on=jumpscare` · `--shot-on=strangle` · `--shot-on=shock` · `--shot-on=pumpkin` · `--shot-on=pumpkin_roof` / `_edge` / `_leap` / `_land` / `_lobby` · `--shot-on=lightning` | Screenshot nach n Frames (Standard 120) · im Jumpscare · wenn der Lakengeist zupackt · wenn ein Gast erschrickt · wenn der Kürbismann ausholt · wenn er oben auf dem Lobbydach ankommt, an der Kante steht, springt, landet, sich zum ersten Mal in der Lobby umsieht · beim Blitz |
| `--bg` | Fenster im Hintergrund: nimmt keinen Fokus und liegt außerhalb des Bildschirms (für Screenshot-Läufe nebenher); speichert wie headless nach `saves_headless/`, nicht in die echten Spielstände |
| `--ghost=n` · `--ghost=flur` · `--ghost=schrank` · `--ghost=tür` | Lakengeist sofort zum n. Mal am nächsten Außenfenster bzw. an der nächsten Fenstertür des Raums, in dem du stehst (beim Start Zimmer 13; vorher mit `--tp` woandershin, Fenstertür z. B. `--pos=34.45,0.1,-13.5` in Zimmer 0102): Licht aus, Vorhang auf (ab 4 zu), Blick dorthin (mit `--trace`: Erscheinen, Losreißen mit Balkenstand und Wechseln je Sekunde, Tod in der Konsole) · alle Gäste sofort im Bett, er taucht in deinem Flur knapp 20 m vor dir auf und kommt (vorher mit `--pos`/`--tp` in einen Flur stellen, z. B. `--pos=31.5,0,-8`) · er kommt durch den Vorhang deines Zimmers herein, du versteckst dich sofort in dessen Schrank (mit `--trace`: Wartezeit, Chance, hineinfliegen oder aufgeben) · ein Lakengespenst hängt neben deiner Zimmertür (sonst Zimmer 13), er steht lautlos davor und dreht deinen Blick durch die Wand – mit `--answer` machst du nach 4 s auf |
| `--sleep` · `--sleep=bett` | Nachtruhe sofort beginnen · alle Gäste sofort im Bett, du schläfst im Bett von Zimmer 13 (mit `--trace`: Einschlafen, Wecken, Ende der Nachtruhe) |
| `--awake=n` | so viele Nächte ohne Schlaf (der erste Angriff gilt als geschehen) – Lakengeist häufiger, ab 3 sicher im Flur (je Nacht ein Drittel Schwäche), z. B. `--awake=3 --pos=50.5,0.1,-7 --trace` |
| `--no-psx` · `--psx` | ohne bzw. mit PS1-Look starten (wie der Schalter in den Einstellungen, wird nicht gespeichert) |
| `--fps` | Bilder pro Sekunde einblenden (wie F10) |
| `--nointro` · `--debug` · `--trace-nav` | ohne Intro · Debug-Werte · mit `--trace` auch die Wegfindung der Gäste |
| `--perf` · `--perf=60` | jeden Frame Zeiten (Frame, Skripte, Physik, Navigation, Rendern CPU/GPU) und Zeichenaufrufe nach `temp/perf.csv`, Ende nach 20 bzw. n s – für Ruckler (Skripte und Physik: Höchstwert der letzten Sekunde) |
| `--title` · `--new=2` · `--load=1` | trotz Parametern Titelbildschirm · neues Spiel in Slot 2 · Slot laden (0 = Autosave) |
| `--diary=3` · `--savetest` | nach 2 s in Slot 3 speichern · Speichern → Laden → Vergleichen |
| `--navcheck` | Bau- und NavMesh-Zeit, Wege von Zimmer 13 zu Lobby, Galerie, Bar, Küche, Heizkeller, Innenhöfen, Katzenraum, Bibliothek, einem Flur und Zimmer oben, Kellergang, Technikraum, Wäscherei … (unerreichbare Orte werden gemeldet) |
| `--menu=pause` | Menü öffnen (`pause`, `diary`, `settings`, `load`, `controls`) |
| `--bulb-thief=bruno` | Gast klaut sofort eine Glühbirne aus Zimmer 13 |
| `--steal-test` · `--player-deco=x,z` | Ednas Deko unbemerkt nehmen (Schuld-Test) · geschnitzten Kürbis des Spielers an diese Stelle stellen |
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
scripts/level/              LevelBuilder (baut aus assets/maps/eg.json, og1.json, ug.json: Wände, Zimmer, Flure, Keller, Zonen, Wegpunkte)
tools/build_map.py          Gebäudeplan map.aseprite (Legende: Farbnamen in map.gpl) → assets/maps/<stockwerk>.json
tools/aseprite-palette-names/  Aseprite-Erweiterung: Palettennamen aus map.gpl als Liste neben den Farben
scripts/world/              Item, Door (auch Glas), HideSpot, Chest, FlickerLight,
                            PumpkinPlant, ResourceSpot, RecordPlayer,
                            Lamp (Glühbirne), LightSwitch, HotelWindow (Vorhang), OpeningFrame (Rahmen), Diary,
                            Traces + TraceMark (Spuren), WarningNote (Warnungszettel), HotelPhone (Telefon),
                            Flashlight (Taschenlampe, UV), UvMark (nur unter UV sichtbar), Stove (Herd, Kochen),
                            PartyLights (bunte Strahler), Confetti (Konfetti und Decals)
scripts/guests/             Guest (Verhalten), GuestProfiles (feste Gäste, Sätze), GuestGenerator (Zufallsgäste),
                            Social (Beziehungen, Gerüchte, Diebstahl, Tod, Feiern), PhoneCalls (Anrufe),
                            Decorating (Schmück-Aktionen), DecoSearch (Deko-Suche), GuestPals (Freundschaften unter Gästen)
scripts/player/             Player
scripts/monster/            Monster (Zustände), MonsterDirector (Phasen, versteckte Werte, Effekte, Spuk),
                            PumpkinMan (Kürbismann), SheetGhost (Lakengeist), NavWalker (gemeinsames Laufen)
scripts/minigames/          Mäxchen: Regeln, Partie (Ablauf, Gast-KI), Würfeltisch · Schach: Regeln, KI (Thread),
                            Brett von oben, Partie, Schachtisch · TableMatch (Ablauf am Tisch) und TableStakes
                            (Einsätze) für beide
scripts/ui/                 HUD, Dialog, Sterbebildschirm, Titelbildschirm, Menüs (Esc, Tagebuch),
                            Einstellungen, Slot-Übersicht, UiKit (Meldezettel-Optik), Telefon
scripts/util/               PS1-Materialien, Platzhalter-Geometrie/-Texturen, Synth-Sound, ShadowBudget,
                            Senses (Lärm & Sichtbarkeit: alle Werte), Footsteps (Schrittklänge)
shaders/                    PS1-Oberfläche, Tapete mit Glanz, Post-Effekt, Versteck-Overlay
```

Tuning-Werte des Monsters stehen oben in `scripts/monster/monster_director.gd`.
