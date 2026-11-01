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
- **Ausstattung, Gegenstände, Lichter** sind 3×3-Punkte. Wandsachen liegen innen an der Wand (daraus die Wandseite).
  Gleichfarbige Punkte dürfen sich nicht berühren. Ausnahme: Halogenleuchten sind Striche in ihrer Länge (8×2 px).
- **Slices** (Aseprite-Werkzeug): `Raum: <Name>`, `Bereich: <Name>`, `Treppe: <Name>` (Pivot oben), `Treppenhaus: <Name>`,
  `Objekt: <Name>` (Pivot an der Vorderseite). Ein `Raum`-Slice benennt die ganze zusammenhängende Fläche gleicher
  Farbe, auf der er liegt – **je Fläche nur ein Raum-Slice** (fällt eine Wand weg, verschmelzen zwei Räume; der
  übrige Slice muss dann weg, sonst gewinnt der alphabetisch spätere Name).

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
| #dfb949 | Büro der Direktion | OG; noch nicht gebaut (ZIM-6) |
| #ecdd79 | Sekretariat | der Direktion, OG; noch nicht gebaut (ZIM-117) |

## Öffnungen

Striche auf der Wandlinie.

| Farbe | Name | Hinweis |
|---|---|---|
| #3bf316 | Tür Flur | Zimmertüren; wohin sie führen, liest das Skript beiderseits (Bad, Verbindungstür, Flur) |
| #0bcb4b | Tür Terrasse | Fenstertür nach draußen |
| #3994ef | Fenster | |
| #11d4a4 | Doppel-Glastür | |
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
| #9b753b | Tafel | | |
| #8a452e | Sofa | | |
| #777740 | Bank | #9f9f56 | auch Parkbank |
| #7e5d1b | Truhe | | im Hotelzimmer die Süßigkeiten-Truhe, so groß wie im Plan |
| #452124 | Schachtisch | | |
| #8a2e36 | Spieltisch | | |
| #5d323d | Theke | | |
| #976049 | Regal | | |
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
| #999633 | Stuhl | #c2be47 | |
| #44663d | Grab | #5e8c54 | Grabplatz 2 × 1 m, Vorderseite = Fußende |
| #85af5a | Gedenkstätte | #a3c383 | |
| #bf2263 | Videoautomat | | ohne Vorderseite – mit dem Rücken an die nächste Wand |
| #aa4f41 | Spieleschrank | | ohne Vorderseite – mit dem Rücken an die nächste Wand |
| #5a2b5a | Nachttisch | #833f83 | 5 × 5 px neben dem Bett |
| #6c7d89 | Spind | | des Hausmeisters (Spielkonzept 2.11, 7.4); noch nicht gebaut (ZIM-4) |
| #2e7d5b | Gartentisch | | 8 × 8 px, Aluminium und Holzlatten, ohne Vorderseite; leicht gedreht – der Tisch nächst der Gartentür von 13 ist der Futtertisch der Krähen |
| #4f7a3a | Gartenstuhl | #6aa34e | 5 × 6 px, Aluminium und Textilgewebe, einzeln gesetzt; leicht gedreht und versetzt |
| #734c45 | Spindblock | #99655c | 36 × 9 px in den Pool-Umkleiden: Sockel mit Sitzfläche vorn, 12 Spinde (6 × 2) und rechts ein Regal 3 × 2; Rücken zur Wand. Nummern fortlaufend, Blöcke von West nach Ost, im Raum „links unten“ zuerst (ZIM-145) |
| #d1921f | Umkleidebank | | 30 × 6 px (3 m, vier Fußrahmen), Länge entlang der langen Seite, ohne Vorderseite; Gestell anthrazit, Holzlatten, Sitzen von beiden Seiten |

## Teppiche

Ebene `Teppiche`, Rechteck (eigene Ebene, damit sie unter Möbeln liegen können).

| Farbe | Name | Vorderseite | Hinweis |
|---|---|---|---|
| #721d1d | Läufer | | läuft entlang der langen Seite |

## Ausstattung

Ebene `Ausstattung`, 3×3-Punkt, Wandsachen innen an der Wand.

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
| #b24db2 | Fotowand | je Punkt eine Position mit 2 Rahmen übereinander (Oberkanten 1,40 m und 1,90 m), Punkte im 1-m-Abstand; noch nicht gebaut (ZIM-133) |
| – | Dartscheibe | im Code vorgesehen; ohne Planeintrag hängt sie hinten in der Nische der Bar |

## Gegenstände

Ebene `Gegenstände`, 3×3-Punkt.

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
| – | Dartpfeile | im Code vorgesehen; ohne Planeintrag liegen sie auf dem Stehtisch an der Scheibe |

## Lichter

Ebene `Lichter`, 3×3-Punkt, Wandleuchten innen an der Wand. Defekt = gleiche Leuchte, dunkler.

| Farbe | Name | Hinweis |
|---|---|---|
| #ffdd00 | Wandleuchte | |
| #7a6a00 | Wandleuchte defekt | |
| #ffbb33 | Kerze | |
| #fffa66 | Laterne | |
| #6b6b2e | Laterne defekt | |
| #fff8ad | Deckenleuchte | |
| #dadf49 | Halogenleuchte | Strich in ihrer Länge, 8×2 px |

## Im Plan, aber ohne Bedeutung

Farben, die `build_map.py` im Plan findet, aber nicht kennt – es meldet sie mit Pixelposition. Stand 31.10.: keine.

## Im Code gesetzt, nicht im Plan

Stand 31.10. Ziel: Was einen Platz hat, setzt der Zeichner in den Plan; der Code baut nur noch, was dort steht.
Koordinaten in Metern (x Ost, z Süd, Ursprung Mitte Haupteingang).

### Ersatzplätze – sollen in den Plan

Der Code setzt sie an einen festen Platz, bis es einen Planeintrag gibt.

| Objekt | Jetzt | Planeintrag | Stand |
|---|---|---|---|
| Fotowand | Lobby-Westwand (`photo_wall.gd` WALL) | Ausstattung: Fotowand #b24db2 | im Plan gemalt, Bau offen (ZIM-133) |
| Dartscheibe mit Linie und Stehtisch | Nische an der Südwand der Bar (`DART_FALLBACK`) | Ausstattung: Dartscheibe | ohne Farbe – **Ersatzplatz aktiv** |
| Dartpfeile | auf dem Stehtisch an der Scheibe | Gegenstand: Dartpfeile | ohne Farbe – Ersatzplatz aktiv |
| Jackpot-Automat | Bar-Nordwand nördlich der Glastür (`SLOT_FALLBACK`) | fehlt (Möbel: Spielautomat?) | immer aus dem Code |
| Spieleschrank | Bar-Ostwand (`CABINET_FALLBACK`) | Möbel: Spieleschrank | steht im Plan – Ersatz greift nicht |
| Maskensammlung (Haken, künftig Board 4 × 2) | längste freie Wand in Zimmer 13 | fehlt | ZIM-128 |
| Apfelbottich | Südostecke Partyraum (`apple_tub.gd` SPOT) | fehlt (Ausstattung: Apfelbottich) | ZIM-84 |
| Puppenhaus | Mitte der Bibliothek im OG (`doll_house.gd` SPOT) | fehlt (Möbel: Puppenhaus) | ZIM-84 |
| Rattenkönig | Wandbord Nordwand Müllraum UG (`rat_king.gd`) | fehlt (Ausstattung: Rattenkönig) | ZIM-84, ruht |
| Sicherungskasten | Nordwand Maschinenraum UG (`power_cut.gd`) | fehlt (Ausstattung: Sicherungskasten) | |
| Salz (3 Packungen) | rechtes Ende der Küchenzeile | fehlt (Gegenstand: Salz) | |
| Futtertisch der Krähen | der Tisch draußen nächst der Gartentür von 13 (bis 12 m); Ersatz nur im Debug | Möbel: Tisch im Gärtchen | ZIM-51 |
| Leuchten im Treppenhaus Ost | Podeste EG/OG, wenn der Plan dort keine Wandleuchte hat; UG-Podest immer | Licht: Wandleuchte | |
| Fester Schubladenfund (Zimmer 022) | erste Kommode, sonst erster Tisch | Möbel: Kommode im Zimmer | |
| Notizbuch des Hausmeisters (Zimmer 18), Gustavs Tagebuch | auf dem Zimmertisch, ohne Tisch am Boden in der Mitte | Möbel: Zimmertisch | |

### Fest im Code – Kandidaten für den Plan

Feste Koordinaten oder Regeln ohne Planeintrag. Was hier einen eigenen Ort hat, könnte eine Farbe bekommen.

| Objekt | Jetzt |
|---|---|
| Teppich vor der Rezeption | fest 6 × 8 m bei (0, −5) – Teppich-Ebene kennt bisher nur den Läufer |
| Wegweiser BAR, PARTY, GARTEN, POOL | Lobbywände, feste Höhe und Lage |
| Aushangbrett | Lobby-Westwand, z −16,6 |
| Leviathan-Druck (Doré) | Lobby-Westwand südlich der Fotowand (`leviathan_name.gd` PRINT_AT) – muss mit der Fotowand mitwandern |
| Vogelscheuche | wandert je Spieltag von hinten im Garten (−3, −73) bis vor die Gartentür der Lobby (−5,5, −30,4) |
| Waschmaschinen der Wäscherei | 12 je Längswand – obwohl „Möbel: Waschmaschine“ in der Legende steht |
| Heizkeller-Einrichtung | alles relativ zur Fläche: Kessel Mitte Ostwand, 3 Kisten Südwand, Regal Westwand, Schlüssel 18, Münzen, Batterie, Spieluhr, Zettel 2011, UV-Schrift 1987, Spinnweben, Deko, kaputte Leuchte, Schalter, Rohre |
| Hotelregister | auf der Rezeption, Mitte der Kundenseite |
| Wanduhr, Schild AUSGANG | über dem Haupteingang |
| Barausstattung | Flaschen im Regal, 6 Barhocker, Zapfstelle, Dosen, Kaffee/Tee auf der Theke, Getränkekisten vor dem Regal in Kühlraum und Lager |
| Partyraum | Tanzfläche 6 × 6 m und Discokugel in der Mitte, Partylampen, dunkle Ecke im Nordwesten, Plattenspieler auf dem ersten Tisch |
| Küchenzeile | Kaffeemaschine, Wasserkocher, Brotkrumen, Eierkarton |
| Pool | Einstiegstreppen West/Ost, 4 Unterwasserlampen je Seite |
| Zimmer 13 | Laken auf dem Bett, Warnzettel 1999 hinter der Tür, Spielerstart in der Mitte |
| Zimmer 18 | Notizbuch, Schaltschlüssel, UV-Aufsatz auf dem Tisch |
| Krähennest | im Baum gegenüber der Gartentür von Zimmer 042 |
| Monster-Startpunkte | Heizkeller, Zimmer 017, Garten |

Ohne festen Ort (wandern oder erscheinen zufällig): Gäste, Hotelkatzen, Kind zu viel, Kürbismann, Ratten, Spinnen,
Motten, Pfützen, Gestalten. Sie brauchen keinen Planeintrag.

### Regeln aus dem Grundriss

Entstehen aus Flächen und Öffnungen – kein eigener Eintrag nötig.

- **Rezeption** aus der Fläche, Kundenseite zur größten Nachbarfläche. **Lobbytreppe, Treppenhäuser,
  Dachbodentreppe** aus Treppenflächen und Slices.
- **Türen, Fenster, Rahmen, Aufzüge** aus den Öffnungen; **Zimmerschilder** über jeder Zimmertür (nicht bei Suiten),
  Schloss nach Haushalt (HAUSHALTE.md).
- **Lichtschalter:** aus dem Plan; ein Zimmer ohne Schalter bekommt einen neben der Tür. **Deckenleuchten** nur aus
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
