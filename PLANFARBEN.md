# Gebäudeplan – Farben und Regeln

Gemeinsame Arbeitsgrundlage für den Plan `map_a.aseprite` (Spielkonzept 7.5): **Diese Datei ist die einzige
Legende.** Beide lesen und schreiben hier. Aus ihr entstehen automatisch:

- `map_colors.png` – Farbfelder zum Aufnehmen mit der Pipette (`python tools/build_colors.py`)
- `map_a.gpl` – dieselben Farben als Palette für Aseprite (ebenfalls von `build_colors.py`)
- die Stockwerke `assets/maps/*.json` – `tools/build_map.py` liest die Farben direkt hier; das Spiel baut den Plan
  beim nächsten Start im Editor neu, wenn sich diese Datei geändert hat

**Neue Farbe:** Zeile in der passenden Tabelle ergänzen (oder Hexwert und Bedeutung nennen), dann
`python tools/build_colors.py`. Eine Farbe ohne Bauteil im Code meldet das Skript („noch nicht gebaut“);
„–“ in der Spalte Farbe heißt: im Code vorgesehen, aber noch ohne Farbe im Plan.

## Regeln für den Plan

- **Maßstab:** 1 m = 10 px. Wände sind 2 px dicke Linien (20 cm).
- **Stockwerke** liegen untereinander, je 790 px hoch und deckungsgleich: Dachgeschoss, Obergeschoss, Erdgeschoss, Keller.
- **Ebenen:** Grundriss (Wände, Flächen, Öffnungen) · `Zimmer` (deckende Flächen = ein Hotelzimmer) · `Beschriftung`
  (schwarze Pixelziffern = Zimmernummer) · Objektebenen `Möbel`, `Teppiche`, `Ausstattung`, `Gegenstände`, `Lichter`.
  Nicht gelesen: Ebenen, deren Name mit `Beschriftung`, `Skizze`, `Notiz` oder `temp` beginnt.
- **Öffnungen** sind Farbstriche **auf** der Wandlinie. Türanschlag: ein Pixel `Türanschlag` statt eines Türpixels am
  Ende des Strichs, in der Wandhälfte, in die die Tür aufgeht.
- **Möbel und Teppiche** sind Rechtecke. Die **Vorderseite** zeigt eine Randzeile in der helleren Farbe aus der
  Spalte „Vorderseite“ (beim Doppelbett das Kopfende) – oder, für jedes Möbel, ein Strich `Vorderseite`.
- **Ausstattung, Gegenstände, Lichter** sind Punkte, 2×2 oder 3×3 px. Wandsachen liegen innen an der Wand (daraus die Wandseite).
  Gleichfarbige Punkte dürfen sich nicht berühren. Ausnahme: Halogenleuchten sind Striche in ihrer Länge (8×2 px).
- **Größen prüft `build_map.py`** (ZIM-141): Wo diese Legende eine Größe in Pixeln nennt – Wandbreite, 2×2- oder 3×3-Punkte,
  „21 × 11 px“, „4 px tief“, Türanschlag 1 px –, warnt es bei Abweichung mit Stockwerk, Ebene, Farbe und Pixelposition
  (Möbel dürfen 1 px abweichen). Es bricht nicht ab. Angaben in Metern werden nicht geprüft. **Punkte dürfen 2×2 oder 3×3**
  sein, beides kommt im Plan vor (entschieden 3.11.); abschalten lässt sich die Prüfung mit `CHECK_SIZES` in `build_map.py`.
- **Slices** (Aseprite-Werkzeug): `Raum: <Name>`, `Bereich: <Name>`, `Treppe: <Name>` (Pivot oben), `Treppenhaus: <Name>`,
  `Objekt: <Name>` (Pivot an der Vorderseite). Ein `Raum`-Slice benennt die ganze zusammenhängende Fläche gleicher
  Farbe, auf der er liegt – **je Fläche nur ein Raum-Slice** (fällt eine Wand weg, verschmelzen zwei Räume; der
  übrige Slice muss dann weg, sonst gewinnt der alphabetisch spätere Name).
- **Slices für Stahlspinde** (SK 7.18, ZIM-174): `Spind: Hausmeister` (geht für den Spieler nie auf) bzw. `Spind: Josef`
  (Code 2803) über dem Spind mit Schloss. `Code: <Name>` zweimal mit gleichem Namen – über einem „Spind mit Schloss“ (in einer Reihe über
  genau dessen 5 × 5 px) und über einem „Zettel“, beliebig weit weg, auch auf einem anderen Stockwerk; der Zettel nennt
  dann Raum, Lage und Code. Vier Ziffern am Ende (`Code: Wäschekammer 4471`, auf einem der beiden) geben den Code vor,
  sonst kommt er fest aus dem Namen. Fehlt eine Hälfte, warnt der Bau.

Mehr Einzelheiten: TECHNIK.md 4 „Gebäudeplan“.

## Farbleitsystem

Seit 31.10. (ZIM-139): Jede Gruppe hat einen Farbbereich, Untertypen unterscheiden sich über Helligkeit und Sättigung.
Neue Farben bitte in den passenden Bereich legen; `python tools/plan_recolor.py vorschlag` prüft die Abstände.

- **Wände:** schwarz; Glaswand hellblau, Gitter dunkelviolett, Leviathanmauer dunkelrot.
- **Flächen (blass):** Gäste und Wohnen warm (orange/beige) · Bar, Party, Bowling rosa · Wasser und Sanitär blau ·
  draußen grün · Wege violett (Flur, Treppe, Aufzug, Luftraum) · Verwaltung gold · Betrieb und Keller grau.
- **Öffnungen (kräftig):** Türen grün · Fenster blau · Haupteingang rot · Türanschlag magenta.
- **Möbel (mittel bis dunkel):** Schlafen violett · Aufbewahren braun · Tische und Sitzen ocker · Bad türkis ·
  Küche und Geräte stahlblau/grau · Spiel und Bar rot · draußen und Friedhof grün. Vorderseite = dieselbe Farbe heller,
  der allgemeine Strich `Vorderseite` magenta.
- **Teppiche:** dunkelrot.
- **Ausstattung:** rosa (an der Wand und im Raum) · Garten gelbgrün (Kürbispflanzen), Laub braun.
- **Gegenstände:** orange. **Lichter:** gelb, defekt = dieselbe Farbe dunkler.

## Wände

Linien im Grundriss, 2 px.

| Farbe | Name | Hinweis |
|---|---|---|
| #000000 | Wand | 20 cm |
| #c2e8f4 | Glaswand | wie Wand, aus Glas |
| #2e2239 | Gitter | wie Wand, durchsichtig – zum Dachboden im OG; noch nicht gebaut |
| #592229 | Leviathanmauer | im Heizraum (Spielkonzept 7.4), dahinter geht es hinunter nach U2; noch nicht gebaut (ZIM-83) |

## Flächen

Füllfarben im Grundriss. „draußen“ = ohne Decke.

| Farbe | Name | Hinweis |
|---|---|---|
| #f2b488 | Zimmer | |
| #c9af9c | Zimmer leer | Zimmerfläche eines unbewohnten Zimmers |
| #d8d4ed | Flur | |
| #c2efb3 | Garten | draußen |
| #becfaa | Terrasse | draußen |
| #1e671e | Terrassenkante | draußen, Hecke am Terrassenrand |
| #1a9338 | Baum | draußen, nur der Standort – die Größe kommt aus dem Modell |
| #6eb361 | Pflanzkübel | |
| #f5f5f5 | Betriebsraum | |
| #c1bdb9 | Lagerraum | |
| #e0a3b2 | Bar | |
| #e0aed1 | Partyraum | |
| #6cb9da | Toilette | |
| #259df4 | Pool Wasser | Becken |
| #b6cad8 | Pool Umgang | Rand um das Becken |
| #b591ca | Aufzug | |
| #c2b5d9 | Treppe | Fläche der Treppe bzw. des Treppenhauses |
| #8570a9 | Treppenstufe | Anfang und Ende der Läufe |
| #da8f4e | Rezeption | |
| #342b64 | Luftraum | kein Boden – darunter offene Decke |
| #eac9b8 | Katzenraum | |
| #bd8775 | Bibliothek | |
| #a6b59b | Balkon | draußen |
| #637557 | Balkongeländer | draußen, Geländer am Balkonrand |
| #8ccfd9 | Bad | |
| #a8a8a8 | Kellerboden | |
| #964c40 | Heizkeller | |
| #8799ab | Technikraum | |
| #94aedb | Wäscherei | |
| #8c8c8c | Kellerraum | |
| #b6af91 | Kiesweg | draußen |
| #8c7554 | Müllraum | |
| #666666 | Kellerraum zu | zählt wie unbemalt, nichts gebaut |
| #9b856f | Dachboden | Bohlen, Decke 2,2 m, Türen niedrig |
| #439d70 | Heckenbogen | draußen, Torbogen – eine Lücke in der Terrassenkante |
| #be93a8 | Bowlingbahn | helles Holz |
| #c3224b | Foullinie | quer über die Bowlingbahn, darf schmal sein |
| #a9b6bc | Hausmeisterraum | Raum des heutigen Hausmeisters (Spielkonzept 2.11); noch nicht gebaut (ZIM-119) |
| #dfb949 | Büro der Direktion | OG; Innenraum mit Holzboden wie die Bibliothek (ZIM-150) – Zugang noch offen (ZIM-6) |
| #ecdd79 | Sekretariat | der Direktion, OG; Innenraum wie das Büro (ZIM-150), Fundstücke bei ZIM-117 |

## Öffnungen

Striche auf der Wandlinie.

| Farbe | Name | Hinweis |
|---|---|---|
| #3bf316 | Tür Flur | Zimmertüren; wohin sie führen, liest das Skript beiderseits (Bad, Verbindungstür, Flur) |
| #0bcb4b | Tür Terrasse | Fenstertür nach draußen |
| #3994ef | Fenster | |
| #11d4a4 | Doppel-Glastür | im Haus (Lobby, Bar …): Holz und Sprossen der Gartentür, ohne Wetterschenkel |
| #a6af79 | Betriebstür | |
| #5ae287 | Milchglastür | Pool, Duschen, Umkleiden: Holzrahmen mit Milchglas, hält den Blick auf wie eine Holztür |
| #2d7633 | Aufzugtür | |
| #ff0000 | Haupteingang | auch: verschlossene Tür; als Kreuz mitten auf einer Fläche eine Markierung |
| #f300ff | Türanschlag | 1 px am Ende des Türstrichs, Seite des Scharniers |
| #5e9438 | Gittertür | im Gitter zum Dachboden; noch nicht gebaut |
| #81d1f8 | Dachfenster | auf der Außenwand des Dachbodens – das Fenster sitzt in der Dachschräge |
| – | Kniestocktür | im Code vorgesehen (Türen in den Kniestock des Dachbodens) |

## Möbel

Ebene `Möbel`, Rechteck in der Grundfläche. Vorderseite = Randzeile in der helleren Farbe.

| Farbe | Name | Vorderseite | Hinweis |
|---|---|---|---|
| #ff00ff | Vorderseite | | Strich am Rand, gilt für jedes Möbel |
| #743d8f | Bett | | |
| #4c3824 | Schrank | | |
| #915e30 | Kommode | | |
| #bf9940 | Tisch | | |
| #c7ae6b | Couchtisch | #d8c797 | |
| #9b753b | Tafel | | so groß wie im Plan, Länge entlang der langen Seite, ohne Vorderseite; 85 cm hoch, Läufer darauf, nur Eckbeine (ZIM-157) |
| #8a452e | Sofa | | |
| #57480f | Schreibtisch | #8b7418 | Büro der Direktion: fest 2,10 × 1,05 m (21 × 11 px), zwei Unterschränke, Lederauflage, Sessel davor; mittig im Rechteck, Rücken an dessen Hinterkante (ZIM-154) |
| #655015 | Sekretariatsschreibtisch | #977820 | Sekretariat: fest 1,40 × 0,75 m (14 × 8 px), ein Unterschrank rechts, ohne Stuhl; mittig im Rechteck, Rücken an dessen Hinterkante (ZIM-154) |
| #777740 | Bank | #9f9f56 | auch Parkbank |
| #7e5d1b | Truhe | | im Hotelzimmer die Süßigkeiten-Truhe, so groß wie im Plan |
| #452124 | Schachtisch | | |
| #8a2e36 | Spieltisch | | |
| #5d323d | Theke | | |
| #976049 | Regal | | |
| #bf5b22 | Bücherregal 4 Ebenen 1 m | #dd7a40 | 2,10 m hoch, Zwischenwand etwa alle 1 m. Länge frei, 4 px tief (Korpus 30 cm, Profil bis 37 cm), Rücken an der Hinterkante (ohne Vorderseite: quer zur langen Seite, zur Raummitte); die Fächer werden gleichmäßig gestreckt, bis die Länge aufgeht. Zwei gleich hohe über Eck aneinander = Innenecke mit Gehrung (ZIM-152) |
| #dc9a38 | Bücherregal 4 Ebenen 2 m | #e5b46c | 2,10 m hoch, Zwischenwand etwa alle 2 m. Länge frei, 4 px tief (Korpus 30 cm, Profil bis 37 cm), Rücken an der Hinterkante (ohne Vorderseite: quer zur langen Seite, zur Raummitte); die Fächer werden gleichmäßig gestreckt, bis die Länge aufgeht. Zwei gleich hohe über Eck aneinander = Innenecke mit Gehrung (ZIM-152) |
| #bf4122 | Bücherregal 5 Ebenen 1 m | #dd6040 | 2,56 m hoch, Zwischenwand etwa alle 1 m. Länge frei, 4 px tief (Korpus 30 cm, Profil bis 37 cm), Rücken an der Hinterkante (ohne Vorderseite: quer zur langen Seite, zur Raummitte); die Fächer werden gleichmäßig gestreckt, bis die Länge aufgeht. Zwei gleich hohe über Eck aneinander = Innenecke mit Gehrung (ZIM-152) |
| #ad7267 | Bücherregal 5 Ebenen 2 m | #c2978e | 2,56 m hoch, Zwischenwand etwa alle 2 m. Länge frei, 4 px tief (Korpus 30 cm, Profil bis 37 cm), Rücken an der Hinterkante (ohne Vorderseite: quer zur langen Seite, zur Raummitte); die Fächer werden gleichmäßig gestreckt, bis die Länge aufgeht. Zwei gleich hohe über Eck aneinander = Innenecke mit Gehrung (ZIM-152) |
| #788fa5 | Küchenzeile | | |
| #364459 | Herd | | |
| #86b6b2 | Waschtisch | | |
| #86aecb | Waschmaschine | | |
| #b49974 | Wäschekiste | | |
| #808080 | Säule | | |
| #d89c79 | Kratzbaum | | |
| #9346b9 | Doppelbett | #ad72ca Kopfende | Versteck: man kriecht darunter wie unters Bett |
| #23bac7 | Badewanne | #49d2df | eingelassen, von Wand zu Wand |
| #2e5656 | Wannenablage | | gefliestes Stück neben der Wanne, ohne Vorderseite |
| #35d4b4 | Waschbecken | #68dfc7 | mit Spiegel, Lampe und Handtuchhalter |
| #544a45 | Fußmatte | | |
| #326c85 | Dusche | #4390b1 | |
| #147145 | WC | #1da565 | |
| #52637a | Mülleimer | #6c819d | |
| #273a86 | Snackautomat | #354fb6 | |
| #256e93 | Getränkeautomat | #3193c4 | |
| #9b8427 | Zimmertisch | #ccad33 | Tisch so groß wie im Plan, zwei Stühle einander gegenüber |
| #999633 | Stuhl | #c2be47 | fest 46 × 47 cm (5 × 5 px), mittig im Rechteck, Sitzseite zur Vorderseite – für die Tafeln im Speisesaal (ZIM-156); an einem Zimmertisch setzt die Tischgruppe ihre eigenen |
| #44663d | Grab | #5e8c54 | Grabplatz 2 × 1 m, Vorderseite = Fußende |
| #85af5a | Gedenkstätte | #a3c383 | |
| #bf2263 | Videoautomat | | ohne Vorderseite – mit dem Rücken an die nächste Wand |
| #aa4f41 | Spieleschrank | | ohne Vorderseite – mit dem Rücken an die nächste Wand |
| #5a2b5a | Nachttisch | #833f83 | 5 × 5 px neben dem Bett |
| #6c7d89 | Spind | | Stahlspind 50 × 50 cm (5 × 5 px), 1,80 m hoch; ein längeres Rechteck ist eine Reihe (30 × 5 px = 6 Spinde), Länge in 5-px-Schritten. Ohne Vorderseite mit dem Rücken an die nächste Wand (Strich „Vorderseite“ geht auch). Ein Gegenstand im Rechteck liegt auf der Hutablage des Spinds darüber (bei 180 cm von links: Spind 4). Lager, Hausmeisterraum (Spind des Hausmeisters, ZIM-4), Heizraum (Josefs Spind) (ZIM-174) |
| #4f5d68 | Spind mit Schloss | | wie „Spind“, jede Tür mit Zahlenschloss (Code je Spind fest, Fundorte offen). Gemischte Reihen als aneinanderstoßende Stücke malen (ZIM-174) |
| #2e7d5b | Gartentisch | | 8 × 8 px, Aluminium und Holzlatten, ohne Vorderseite; leicht gedreht – der Tisch nächst der Gartentür von 13 ist der Futtertisch der Krähen |
| #4f7a3a | Gartenstuhl | #6aa34e | 5 × 6 px, Aluminium und Textilgewebe, einzeln gesetzt; leicht gedreht und versetzt |
| #734c45 | Spindblock | #99655c | 36 × 9 px in den Pool-Umkleiden: Sockel mit Sitzfläche vorn, 12 Spinde (6 × 2) und rechts ein Regal 3 × 2; Rücken zur Wand. Nummern fortlaufend, Blöcke von West nach Ost, im Raum „links unten“ zuerst (ZIM-145) |
| #d1921f | Umkleidebank | | 30 × 6 px (3 m, vier Fußrahmen), Länge entlang der langen Seite, ohne Vorderseite; Gestell anthrazit, Holzlatten, Sitzen von beiden Seiten |
| #a00d28 | Spielautomat | | Jackpot-Automat der Bar, nur einer; ohne Vorderseite – mit dem Rücken an die nächste Wand. Ohne Eintrag an der Bar-Nordwand (ZIM-158) |
| #d63d3d | Puppenhaus | | Modell des Hotels auf einem Tisch (5.16), nur eins, Mitte des Rechtecks; Pläne mit Norden oben, ist das Rechteck in z länger, quer gedreht. Ohne Eintrag mitten in der Bibliothek im OG (ZIM-158) |
| #b68035 | Barhocker | | je Rechteck ein Hocker, Sitz zur Vorderseite; Gäste stehen hinter je zwei benachbarten. Stehen welche in der Bar, setzt der Code keine 6 mehr vor die Theke (ZIM-158) |

## Teppiche

Ebene `Teppiche`, Rechteck (eigene Ebene, damit sie unter Möbeln liegen können).

| Farbe | Name | Vorderseite | Hinweis |
|---|---|---|---|
| #721d1d | Läufer | | läuft entlang der langen Seite |
| #430b0a | Teppich | | dunkelrot, so groß wie im Plan. Liegt einer in der Lobby, entfällt der feste vor der Rezeption (6 × 8 m, ZIM-158) |

## Ausstattung

Ebene `Ausstattung`, 2×2- oder 3×3-Punkt, Wandsachen innen an der Wand.

| Farbe | Name | Hinweis |
|---|---|---|
| #f425af | Lichtschalter | |
| #e2125f | Telefon | |
| #d161c2 | Bild | |
| #f8bfd7 | Zettel | |
| #d51ff9 | UV-Schrift | |
| #dbd1db | Spinnweben | |
| #f877a2 | Kerzenvorrat | |
| #f17ee7 | Ersatzbirnen | |
| #8f5214 | Laubhaufen | |
| #6cbd0f | Kürbispflanze | ohne Sorte: Halloween-Kürbis |
| #b1d912 | Kürbispflanze Hokkaido | |
| #c2d897 | Kürbispflanze Weiß | |
| #c9d846 | Kürbispflanze Butternut | |
| #39721d | Kürbispflanze Muskat | |
| #39c723 | Kürbispflanze Türkenturban | |
| #6b9f04 | Kürbispflanze Riese | |
| #e85e7a | Kalender | |
| #ebadeb | Duschplatz | Pool: Punkt innen an der Wand = Mitte des Platzes – Drücker auf 1 m, Ablage rechts daneben, Duschkopf 40 cm vor der Wand (ZIM-144); je Duschraum drei im 1-m-Abstand |
| #8d1b98 | Bodenablauf | Duschen am Pool: Punkt = Mitte des Rosts (15 × 15 cm Edelstahl), am besten in der Raummitte (ZIM-144) |
| #7e2552 | Tagebuch | |
| #aa417e | Dekokiste | |
| #6f2a6f | Maskenboard | Zimmer 13: Mitte des Maskenboards (5.19, 4 × 2 Stifte, 1,32 m breit), an der Wand; ohne Eintrag an der längsten freien Wand (ZIM-158) |
| #d3697b | Apfelbottich | Partyraum (6.21), nur einer; ohne Eintrag in der Südostecke (ZIM-158) |
| #a286b6 | Sicherungskasten | Untergeschoss (4.28), an der Wand, Mitte 1,45 m; ohne Eintrag an der Nordwand des Maschinenraums (ZIM-158) |
| #6a7f5c | Aufzugsantrieb | Maschinenraum im UG (7.4): Punkt an der Wand = Mitte der Rückseite; Motor und Bremstrommel auf Sockel 1,3 × 0,7 m, Kurbel zeigt in den Raum. Ohne Eintrag an der Nordwand des Maschinenraums östlich des Sicherungskastens (ZIM-14) |
| #bf69a2 | Aushangbrett | Lobby (2.5), an der Wand, Mitte 1,55 m; ohne Eintrag an der Westwand (ZIM-158) |
| #cdacc5 | Wanduhr | 3 m Durchmesser, für die Halle gedacht; Mitte zwischen 3,27 m und der Decke (unter dem Luftraum die der Halle). Ohne Eintrag über dem Haupteingang (ZIM-158) |
| #462a3a | Krähennest | auf einen Baum: das Nest sitzt im nächsten Baum (4.25); ohne Eintrag im Baum gegenüber der Gartentür von 042 (ZIM-158) |
| #9712d9 | Leviathan-Druck | Dorés Druck, den Hugo aufhängt (4.32), an der Wand, Mitte 1,72 m; ohne Eintrag an der Lobby-Westwand, wo bis 3.11. die Fotowand hing (ZIM-158) |
| #b24db2 | Fotowand | je Punkt bzw. Strich eine Position mit 2 Rahmen übereinander (Oberkanten 1,40 m und 1,90 m), Punkte im 1-m-Abstand; Jahre spaltenweise von links nach rechts, oben das ältere (ZIM-133) |
| #962c58 | Dartscheibe | an der Wand, Abwurflinie und Stehtisch davor; nur eine im Haus – ohne Planeintrag hängt sie hinten in der Nische der Bar |

## Gegenstände

Ebene `Gegenstände`, 2×2- oder 3×3-Punkt.

| Farbe | Name | Hinweis |
|---|---|---|
| #ff6e00 | Kürbis | |
| #ff3c00 | Geschnitzter Kürbis | |
| #ffe0a3 | Kerze | |
| #f3bb20 | Schlüssel | |
| #d1c7b2 | Spinnweben | |
| #9c4411 | Laub | |
| #b69320 | Münzen | |
| #a5998d | Messer | |
| #6b3924 | Würfelbecher | |
| #f1e8da | Gezinkte Würfel | |
| #fff3c2 | Glühbirne | |
| #d87764 | Kleidung | |
| #a56a1d | Kompass | |
| #e4c381 | Karte | |
| #532e09 | Taschenlampe | |
| #ed9f82 | Batterie | |
| #bd1b0f | UV-Filter | |
| #80664d | Schachbrett | |
| #881807 | Brecheisen | |
| #e72323 | Werkzeugkasten | |
| #ee652b | Dartpfeile | ohne Planeintrag liegen sie auf dem Stehtisch an der Scheibe |
| #fb8e6a | Salz | eine Packung je Punkt (5.13); ohne Eintrag drei am rechten Ende der Küchenzeile |

## Lichter

Ebene `Lichter`, 2×2- oder 3×3-Punkt, Wandleuchten innen an der Wand. Defekt = gleiche Leuchte, dunkler.

| Farbe | Name | Hinweis |
|---|---|---|
| #ffdd00 | Wandleuchte | |
| #7a6a00 | Wandleuchte defekt | |
| #ffbb33 | Kerze | |
| #fffa66 | Laterne | |
| #6b6b2e | Laterne defekt | |
| #fff8ad | Deckenleuchte | |
| #dadf49 | Halogenleuchte | Strich in ihrer Länge, 8×2 px |
| #f8ed77 | Discokugel | Partyraum, nur eine: die Tanzfläche (6 × 6 m) liegt darunter; ohne Eintrag in der Raummitte (ZIM-158) |
| #c3c322 | Unterwasserlampe | auf den Rand des Beckens: sitzt in der nächsten Beckenwand. Steht eine im Plan, setzt der Code keine eigenen (sonst 2 je Längswand, ZIM-158) |
| #ae8509 | Schreibtischlampe | grüne Bankerlampe auf das Möbel darunter (Schreibtisch, Kommode, Tisch …), Schirm zum Sitzplatz vor dessen Vorderseite – an der Ecke schräg zur Mitte gedreht (bis 55°), mittig gerade, dazu ein paar Grad fester Versatz; ohne Vorderseite wie das Telefon (im Zimmer vom Flur weg, sonst zur Raummitte). Schaltet mit dem Raum, Birne herausdrehbar |

## Im Plan, aber ohne Bedeutung

Farben, die `build_map.py` im Plan findet, aber nicht kennt – es meldet sie mit Pixelposition. Stand 31.10.: keine.

## Im Code gesetzt, nicht im Plan

Stand 2.11. Ziel: Was einen Platz hat, setzt der Zeichner in den Plan; der Code baut nur noch, was dort steht.
Koordinaten in Metern (x Ost, z Süd, Ursprung Mitte Haupteingang).

### Ersatzplätze – sollen in den Plan

Die Farbe gibt es, der Code liest sie (seit 2.11. auch die aus ZIM-158). Solange nichts gemalt ist, setzt er das Ding an
den alten festen Platz – gemalt, wandert es dorthin.

| Objekt | Ohne Planeintrag | Planeintrag | Stand |
|---|---|---|---|
| Fotowand | Lobby-Westwand (`photo_wall.gd` WALL) | Ausstattung: Fotowand | im Plan (Lobby-Ostwand), gebaut 3.11. (ZIM-133) |
| Dartscheibe mit Linie und Stehtisch | Nische an der Südwand der Bar (`DART_FALLBACK`) | Ausstattung: Dartscheibe | **Ersatzplatz aktiv** |
| Dartpfeile | auf dem Stehtisch an der Scheibe | Gegenstand: Dartpfeile | Ersatzplatz aktiv |
| Jackpot-Automat | Bar-Nordwand nördlich der Glastür (`SLOT_FALLBACK`) | Möbel: Spielautomat | Ersatzplatz aktiv |
| Spieleschrank | Bar-Ostwand (`CABINET_FALLBACK`) | Möbel: Spieleschrank | steht im Plan – Ersatz greift nicht |
| Maskensammlung (Board 4 × 2) | längste freie Wand in Zimmer 13 | Ausstattung: Maskenboard | Ersatzplatz aktiv |
| Apfelbottich | Südostecke Partyraum (`apple_tub.gd` SPOT) | Ausstattung: Apfelbottich | Ersatzplatz aktiv |
| Puppenhaus | Mitte der Bibliothek im OG (`doll_house.gd` SPOT) | Möbel: Puppenhaus | Ersatzplatz aktiv |
| Rattenkönig | Wandbord Nordwand Müllraum UG (`rat_king.gd`) | fehlt | ZIM-84, ruht |
| Sicherungskasten | Nordwand Maschinenraum UG (`power_cut.gd` FUSE_FALLBACK) | Ausstattung: Sicherungskasten | Ersatzplatz aktiv |
| Aufzugsantrieb mit Kurbel | Nordwand Maschinenraum UG östlich des Sicherungskastens (`lift_drive.gd` FALLBACK) | Ausstattung: Aufzugsantrieb | Ersatzplatz aktiv |
| Salz (3 Packungen) | rechtes Ende der Küchenzeile | Gegenstand: Salz | Ersatzplatz aktiv |
| Teppich vor der Rezeption | fest 6 × 8 m bei (0, −5) | Teppich: Teppich (in der Lobby) | Ersatzplatz aktiv |
| Aushangbrett | Lobby-Westwand, z −16,6 | Ausstattung: Aushangbrett | Ersatzplatz aktiv |
| Leviathan-Druck (Doré) | Lobby-Westwand gegenüber der Fotowand (`leviathan_name.gd` PRINT_AT) | Ausstattung: Leviathan-Druck | Ersatzplatz aktiv – neben die Fotowand malen |
| Wanduhr | über dem Haupteingang | Ausstattung: Wanduhr | Ersatzplatz aktiv |
| Krähennest | im Baum gegenüber der Gartentür von Zimmer 042 | Ausstattung: Krähennest | Ersatzplatz aktiv |
| Barhocker | 6 vor der Theke | Möbel: Barhocker | Ersatzplatz aktiv |
| Discokugel und Tanzfläche | Mitte des Partyraums | Licht: Discokugel | Ersatzplatz aktiv |
| Unterwasserlampen | 2 je Längswand, gleichmäßig verteilt | Licht: Unterwasserlampe | Ersatzplatz aktiv |
| Waschmaschinen der Wäscherei | 12 je Längswand | Möbel: Waschmaschine | Ersatzplatz aktiv |
| Futtertisch der Krähen | der Tisch draußen nächst der Gartentür von 13 (bis 12 m); Ersatz nur im Debug | Möbel: Tisch im Gärtchen | ZIM-51 |
| Leuchten im Treppenhaus Ost | Podeste EG/OG, wenn der Plan dort keine Wandleuchte hat; UG-Podest immer | Licht: Wandleuchte | |
| Notizbuch des Hausmeisters (Zimmer 18), Gustavs Tagebuch | auf dem Zimmertisch, ohne Tisch am Boden in der Mitte | Möbel: Zimmertisch | |

### Bleibt im Code

Feste Koordinaten oder Regeln ohne Planeintrag – bewusst (2.11., ZIM-158): Sie hängen an der Geschichte, wandern
oder richten sich nach Fläche und Möbeln.

| Objekt | Jetzt |
|---|---|
| Vogelscheuche | wandert je Spieltag von hinten im Garten (−3, −73) bis vor die Gartentür der Lobby (−5,5, −30,4) |
| Heizkeller-Einrichtung | alles relativ zur Fläche: Kessel Mitte Ostwand, 3 Kisten Südwand, Regal Westwand, Schlüssel 18, Münzen, Batterie, Spieluhr, Zettel 2011, UV-Schrift 1987, Spinnweben, Deko, kaputte Leuchte, Schalter, Rohre |
| Hotelregister, Tischklingel | auf der Rezeption, an der Kundenseite |
| Barausstattung | Flaschen im Regal, Zapfstelle, Dosen, Kaffee/Tee auf der Theke, Getränkekisten vor dem Regal in Kühlraum und Lager |
| Partyraum | Partylampen, dunkle Ecke im Nordwesten, Plattenspieler auf dem ersten Tisch |
| Küchenzeile | Kaffeemaschine, Wasserkocher, Brotkrumen, Eierkarton |
| Pool | Einstiegstreppen West/Ost |
| Zimmer 13 | Laken auf dem Bett, Warnzettel 1999 hinter der Tür, Spielerstart in der Mitte |
| Zimmer 18 | Notizbuch, Schaltschlüssel, UV-Aufsatz auf dem Tisch |
| Zimmer 022 | Streichholzschachtel in der obersten Schublade der ersten Kommode im Plan (`CONTENT["022"]`, ZIM-85), ohne Kommode auf dem Tisch |
| Sekretariat | Generalschlüssel in der zweiten Schublade des Sekretariatsschreibtischs, hinter dem Zahlenschloss (ZIM-6) |
| Sekretariatsschlüssel | Zwischenort ab dem 6.: an der Wand links neben dem Sicherungskasten (`DirectorOffice.SECRETARIAT_SPOT`) – kommt in Brunos Strang (Spind, ZIM-4) |
| Josefs Schlüsselbund | Zwischenort ab dem 14.: seitlich am Kessel im Heizkeller (`DirectorOffice.JOSEF_SPOT`) – kommt an den alten Kessel in U2 |
| Monster-Startpunkte | Heizkeller, Zimmer 017, Garten |

Ohne festen Ort (wandern oder erscheinen zufällig): Gäste, Hotelkatzen, Kind zu viel, Kürbismann, Ratten, Spinnen,
Motten, Pfützen, Gestalten. Sie brauchen keinen Planeintrag.

### Regeln aus dem Grundriss

Entstehen aus Flächen und Öffnungen – kein eigener Eintrag nötig.

- **Rezeption** aus der Fläche, Kundenseite zur größten Nachbarfläche. **Lobbytreppe, Treppenhäuser,
  Dachbodentreppe** aus Treppenflächen und Slices.
- **Türen, Fenster, Rahmen, Aufzüge** aus den Öffnungen; **Zimmerschilder** über jeder Zimmertür (nicht bei Suiten),
  Schloss nach Haushalt (HAUSHALTE.md).
- **Lichtschalter:** nur aus dem Plan, auch in Zimmern und Bädern (das Bad schaltet für sich). Der Bau ergänzt keine –
  ohne Schalter im Plan brennt das Licht des Raums immer (ZIM-149). **Deckenleuchten** nur aus
  dem Plan. Wandleuchten: Höhe und Helligkeit nach Raumart.
- **Am Möbel:** 2 Stühle je Zimmertisch (Achse aus einem Stuhlpaar im Plan, sonst Ost–West), Spiegel über dem
  Waschbecken, Sitzplätze an Bank, Stuhl, Sofa, Bett und WC, 6 Süßigkeiten je Truhe im Hotelzimmer, Lakengeist in
  jeder Wäschekiste, Liegeplätze für Katzen auf Sofa und Kratzbaum, Spieleschrank/Videoautomat mit dem Rücken zur Wand.
- **Bowlingbahn:** Kegel und Kugelständer aus Bahn und Foullinie. **Tanzplätze** im Partyraum.
- **Gartenmöbel:** leicht gedreht (Stuhl auch etwas verrückt), fest je Platz im Plan.
- **Holzdeck** auf Terrassen und Balkonen, Laufrichtung von der Hauswand weg, Fuge zu Wand, Hecke und Geländer.
- **Geländer** an Lufträumen, Balkonen und Terrassen; **Hecken** aus den Terrassenkanten; **Gras** auf Rasen;
  **Kürbisbeete** unter den Kürbispflanzen; Bäume reihum aus den Modellen.
- **Dachboden:** Stützbalken im 6-m-Raster, Dachfenster in der Schräge.
- **Inhalt je Raum** (Münzbetrag, Kartenblatt, Zettel, UV-Text, Schubladenfund): Tabelle `CONTENT` im LevelBuilder –
  der Plan sagt wo, der Code was.
