# Haushalte – Entwurf zum Bearbeiten

Gehört zu [SPIELKONZEPT.md](SPIELKONZEPT.md) 6.20 (Haushalte) und 6.19 (Zimmerzugang). **Entwurf vom 2026-10-24, noch nicht
im Spiel.** Fest sind die Anzahlen je Haushaltsart; alles andere (Namen, Paare, Charaktere, Ideen) darf geändert werden.

- **67 Gäste = 54 Erwachsene + 13 Kinder in 39 Haushalten.** Kinder wohnen immer bei ihren Eltern.
- **Generation** wie bei den Grundkörpern (6.0): jung / mittel / alt. Die Vornamen stammen aus den Listen in
  `GuestGenerator` (`NAMES`, `FEMALE`, `OLD`, `YOUNG`, `CHILD_NAMES`) und passen dort zu Geschlecht und Generation.
- **Charakter** (6.0): ängstlich · geschäftstüchtig · Plaudertasche · Skeptiker · Bastler · Griesgram. Kinder haben
  keinen Charakter, nur ein Alter (6–11). Die vier Kernfiguren haben ihr eigenes Profil.
- **★** = Vorschlag für die 10–12 zentralen Gäste (6.0) – fester Name, eigener Faden.
- **Nur das „Wer“ steht hier** (Name, Nachname, Geschlecht, Generation, Charakter, Haushalt). Alles Übrige – Werte,
  Vorrat, Sätze, Spielstil, Aussehen – würfelt der Generator wie bisher (6.20).
- **Zimmer** (zugeordnet 2026-10-24 nach Größe, Plan `map_a.aseprite` vom selben Tag): Die Nummern sind **Platzhalter**
  aus der Ebene „Beschriftung“ und werden noch ausgetauscht – maßgeblich ist die **Stelle**. Darum steht unten in der
  Zimmerliste zu jeder Nummer Lage, Größe und Mitte im Plan (Pixel, je Stockwerk ab der Oberkante seines Bands).
  Nur Zimmer 13 bleibt, wie es ist.
- **Nachnamen** erscheinen beim Hinsehen an der Tür und im Hotelregister: bei mehreren Personen nur der Nachname
  („Brandt“), bei einer Person Vor- und Nachname („Walter Ruprecht“).
- **Das Spiel liest diese Datei** (tools/build_households.py → assets/data/households.json, beim Start neu, wenn sie
  sich geändert hat): die Tabellenzeilen „| H01 | …“ und die Zimmerliste. Spalten, Schreibweise „Vorname (Generation,
  Charakter)“ bzw. „Vorname (Alter)“ und die Zimmernummer am Anfang der Zimmerspalte bitte beibehalten.

## Familien mit zwei Eltern

| Nr | Haushalt | Zimmer | Erwachsene | Kinder | Betten | Idee |
|----|----------|--------|------------|--------|--------|------|
| H01 | Familie Brandt | 122 · 103 m² | Henrik (mittel, Bastler) · Johanna (mittel, ängstlich) | Max (9) · Lina (7) | Doppelbett + 2 | Er baut jede Deko mit, sie will eigentlich abreisen |
| H02 | Familie Aydın | 121 · 103 m² | Kemal (mittel, geschäftstüchtig) · Elif (jung, Plaudertasche) | Ella (10) · Jan (7) | Doppelbett + 2 | Verkaufen Kürbisse vom Beet, die Kinder schleppen mit |
| H03 ★ | Familie Lindner | 124 · 103 m² | Simon (mittel, Skeptiker) · Klara (mittel, Bastler) | Paul (11) · Pia (8) | Doppelbett + 2 | Der Vater glaubt den Kindern kein Wort (6.13) – bis es zu spät ist |
| H04 | Familie Krüger | 104 · 103 m² | Peter (mittel, Griesgram) · Vera (mittel, geschäftstüchtig) | Tom (9) | Doppelbett + 1 | Beste Deko im Flur, teuer, und sie lassen es jeden wissen |
| H05 ★ | Familie Sommer | 106 · 103 m² | Luis (jung, Plaudertasche) · Thea (jung, ängstlich) | Emma (6) | Doppelbett + 1 | Junge Eltern; Emma kann nicht schlafen und klopft nachts an Zimmer 13 |
| H06 | Familie Demir | 129 · 103 m² | Yusuf (jung, Bastler) · Nora (mittel, Skeptiker) | Ben (10) | Doppelbett + 1 | Schnitzen um die Wette, Ben will unbedingt ein Messer |

## Alleinerziehende

| Nr | Haushalt | Zimmer | Erwachsene | Kinder | Betten | Idee |
|----|----------|--------|------------|--------|--------|------|
| H07 ★ | Familie Roth | 112 · 103 m² | Ines (mittel, Plaudertasche) | Felix (11) · Ronja (9) | 3 | Überfordert; die beiden streunen allein durchs Hotel |
| H08 | Familie Albers | 123 · 80 m² | Wanda (mittel, Griesgram) | Smilla (7) | 2 | Streng – Smilla macht niemandem auf, auch Bekannten nur zögernd |
| H09 ★ | Familie Berger | 126 · 68 m² | Malte (mittel, ängstlich) | Till (8) | 2 | Witwer, lässt Till nicht aus den Augen; verliert er ihn, bricht er zusammen |

## Paare ohne Kinder

| Nr | Haushalt | Zimmer | Erwachsene | Betten | Idee |
|----|----------|--------|------------|--------|------|
| H10 ★ | Ehepaar Wagner | 007 · 80 m² | Otto (alt, Griesgram) · Gerda (alt, Plaudertasche) | Doppelbett | Seit fünfzig Jahren verheiratet, streiten laut – man hört sie durch die Wand |
| H11 | Ehepaar Lorenz | 036 · 80 m² | Konrad (alt, Bastler) · Hedwig (alt, ängstlich) | Doppelbett | Er repariert gern und leiht Freunden sein Werkzeug (6.19), sie bittet ihn, es zu lassen |
| H12 | Ehepaar Schulte | 041 · 92 m² | Kurt (alt, Skeptiker) · Irma (alt, geschäftstüchtig) | Doppelbett | Jedes Jahr hier „wegen der Ruhe“ – woher kennen sie das Hotel? |
| H13 | Paar Weiß | 128 · 80 m² | Jonas (jung, Plaudertasche) · Lena (jung, Bastler) | Doppelbett | Flitterwochen; schmücken ihre Tür als Erste |
| H14 ★ | Paar Engel | 130 · 68 m² | Leon (jung, Skeptiker) · Jule (jung, ängstlich) | Doppelbett | Wollen den Spuk „beweisen“ – sie hält es bald nicht mehr aus |
| H15 | Paar Haas | 111 · 80 m² | Bastian (mittel, geschäftstüchtig) · Marta (mittel, Griesgram) | Doppelbett | Handeln mit allem, trauen niemandem |
| H16 | Paar Vogel | 119 · 68 m² | Arne (mittel, ängstlich) · Selma (mittel, Plaudertasche) | Doppelbett | Sie erzählt alles weiter, was er sich nur traut zu flüstern |
| H17 | Paar Nowak | 035 · 103 m² | Carla (mittel, Skeptiker) · Rosa (mittel, Bastler) | Doppelbett | Ruhig, hilfsbereit, schließen immer ab |
| H18 | Paar Falk | 034 · 103 m² | Niklas (jung, Griesgram) · Greta (jung, geschäftstüchtig) | Doppelbett | Wollten eigentlich woanders hin; er schimpft über alles |

## Alleinstehende

| Nr | Haushalt | Zimmer | Gast | Betten | Idee |
|----|----------|--------|------|--------|------|
| H19 | Edna Wiegand (Kernfigur) | 003 · 68 m² | Edna (alt, eigenes Profil) | 1 | 6.0 |
| H20 | Bruno Kaminski (Kernfigur) | 102 · 68 m² | Bruno (mittel, eigenes Profil) | 1 | 6.0 |
| H21 | Mila Hellwig (Kernfigur) | 021 · 68 m² | Mila (jung, eigenes Profil) | 1 | 6.0 |
| H22 | Marion Teske (Kernfigur) | 001 · 68 m² | Marion (mittel, eigenes Profil) | 1 | Tochter des Heizers Josef Ahrend (2.3) – im Register „geb. Ahrend“; sucht, was 1987 geschah |
| H23 ★ | Walter Ruprecht | 014 · 34 m² | Walter (alt, Griesgram) | 1 | Dauergast, kennt jeden Winkel – und schweigt |
| H24 ★ | Agnes Möller | 029 · 34 m² | Agnes (alt, Plaudertasche) | 1 | Witwe, weiß über jeden etwas |
| H25 | Gustav Peters | 033 · 34 m² | Gustav (alt, Skeptiker) | 1 | Pensionierter Lehrer, glaubt nur, was er sieht |
| H26 | Liesel Brück | 025 · 34 m² | Liesel (alt, ängstlich) | 1 | Betet abends laut, schläft mit Licht |
| H27 ★ | Hugo Stein | 023 · 34 m² | Hugo (alt, geschäftstüchtig) | 1 | Antiquitätenhändler, kauft Fundstücke (Dokumente, 2.3) |
| H28 | Ruth Behrens | 008 · 34 m² | Ruth (alt, Bastler) | 1 | Näht Kostüme für die Kinder (5.9) |
| H29 | Ulrich Kranz | 009 · 34 m² | Ulrich (mittel, Plaudertasche) | 1 | Vertreter, verteilt Visitenkarten |
| H30 | Paula Jansen | 117 · 68 m² | Paula (jung, Skeptiker) | 1 | Studentin, schreibt über das Hotel |
| H31 | Moritz Graf | 011 · 34 m² | Moritz (jung, ängstlich) | 1 | Kam mit Freunden, die nie ankamen |
| H32 | Fiona Kühn | 026 · 34 m² | Fiona (jung, Plaudertasche) | 1 | Immer an der Bar, kennt alle Gerüchte zuerst |
| H33 | Emil Hartung | 016 · 34 m² | Emil (jung, Bastler) | 1 | Baut aus allem Kürbislaternen |
| H34 | Doris Lange | 006 · 34 m² | Doris (alt, Griesgram) | 1 | Beschwert sich über Lärm – über jeden Lärm |
| H35 | Theo Busch | 019 · 34 m² | Theo (jung, geschäftstüchtig) | 1 | Würfelt um alles (Mäxchen, 6.10) |
| H36 | Magda Seidel | 020 · 34 m² | Magda (alt, Skeptiker) | 1 | Hält das Monster für einen Trick der Direktion |
| H37 | Sami Haddad | 039 · 68 m² | Sami (mittel, Bastler) | 1 | Koch von Beruf, hilft in der Küche (3.8) |
| H38 | Zita Fuchs | 043 · 34 m² | Zita (alt, geschäftstüchtig) | 1 | Verleiht Geld gegen Pfand |
| H39 | Oskar Pohl | 045 · 68 m² | Oskar (alt, ängstlich) | 1 | Meint, er sei schon einmal hier gewesen – erinnert sich an nichts (2.2) |

## Zusammen

| | Haushalte | Erwachsene | Kinder |
|---|---|---|---|
| Eltern + 2 Kinder | 3 | 6 | 6 |
| Eltern + 1 Kind | 3 | 6 | 3 |
| Elternteil + 2 Kinder | 1 | 1 | 2 |
| Elternteil + 1 Kind | 2 | 2 | 2 |
| Paare ohne Kinder | 9 | 18 | – |
| Alleinstehende | 21 | 21 | – |
| **Summe** | **39** | **54** | **13** |

- **Generationen** der Erwachsenen: 17 alt, 21 mittel, 16 jung.
- **Geschlecht:** 25 Männer, 29 Frauen.
- **Charaktere** (ohne die vier Kernfiguren): ängstlich 9, geschäftstüchtig 8, Plaudertasche 9, Skeptiker 8, Bastler 9, Griesgram 7.
- **Zimmer:** 3 mit vier Betten, 4 mit drei, 9 mit Doppelbett, 2 mit zwei Betten, 21 Einzelzimmer – dazu Zimmer 13.
  Mit Sonderzimmern und Reserve rund 55 (6.20).

## Zimmerliste (Platzhalter → Stelle)

Größe = Fläche der Ebene „Zimmer“ samt Bad. Außenzugang = Tür „Tür Terrasse“ in der Zimmerwand (EG Terrasse, OG1
Balkon). Unbewohnte Zimmer schließt das Hotel ab (6.19).

| Zimmer | Stockwerk, Lage | Größe | Bad | Außenzugang | Mitte im Plan (px) | Belegung |
|---|---|---|---|---|---|---|
| 13 | EG Ost, innen | 68 m² | ja | Terrasse | 1149, 639 | Spieler (bleibt an der Stelle) |
| 001 | EG Ost, Südseite | 68 m² | ja | – | 909, 739 | H22 Marion Teske (Kernfigur) |
| 002 | EG Ost, Südseite | 68 m² | ja | – | 1029, 739 | unbewohnt, abgeschlossen |
| 003 | EG Ost, Südseite | 68 m² | ja | – | 1149, 739 | H19 Edna Wiegand (Kernfigur) |
| 004 | EG Ost, Südseite | 34 m² | – | – | 1279, 739 | unbewohnt, abgeschlossen |
| 005 | EG Ost, Südseite | 34 m² | – | – | 1339, 739 | unbewohnt, abgeschlossen |
| 006 | EG Ost, Südseite | 34 m² | – | – | 1399, 739 | H34 Doris Lange |
| 007 | EG Ost, Südseite | 80 m² | ja | – | 1485, 725 | H10 Ehepaar Wagner |
| 008 | EG Ost, innen | 34 m² | – | – | 1499, 639 | H28 Ruth Behrens |
| 009 | EG Ost, innen | 34 m² | – | – | 1499, 579 | H29 Ulrich Kranz |
| 010 | EG Ost, innen | 34 m² | – | – | 1499, 519 | unbewohnt, abgeschlossen |
| 011 | EG Ost, innen | 34 m² | – | – | 1499, 419 | H31 Moritz Graf |
| 012 | EG Ost, innen | 34 m² | – | – | 1499, 359 | unbewohnt, abgeschlossen |
| 014 | EG Ost, innen | 34 m² | – | – | 1499, 299 | H23 Walter Ruprecht |
| 015 | EG Ost, Nordflügel | 57 m² | – | – | 1479, 199 | unbewohnt, abgeschlossen |
| 016 | EG Ost, Nordflügel | 34 m² | – | – | 1399, 199 | H33 Emil Hartung |
| 017 | EG Ost, Nordflügel | 45 m² | – | – | 1329, 199 | verlassen, dunkel (bisher „17“: Kellerskizze, UV-Schrift) |
| 018 | EG Ost, innen | 34 m² | – | Terrasse | 959, 299 | abgeschlossen (bisher „18“: Schaltschlüssel, Notizbuch) |
| 019 | EG Ost, innen | 34 m² | – | Terrasse | 959, 359 | H35 Theo Busch |
| 020 | EG Ost, innen | 34 m² | – | Terrasse | 959, 419 | H36 Magda Seidel |
| 021 | EG Ost, innen | 68 m² | ja | Terrasse | 1059, 549 | H21 Mila Hellwig (Kernfigur) |
| 022 | EG Ost, innen | 34 m² | – | Terrasse | 1279, 639 | unbewohnt, abgeschlossen |
| 023 | EG Ost, innen | 34 m² | – | Terrasse | 1339, 639 | H27 Hugo Stein |
| 024 | EG Ost, innen | 34 m² | – | Terrasse | 1399, 579 | unbewohnt, abgeschlossen |
| 025 | EG Ost, innen | 34 m² | – | Terrasse | 1399, 519 | H26 Liesel Brück |
| 026 | EG Ost, innen | 34 m² | – | Terrasse | 1399, 419 | H32 Fiona Kühn |
| 027 | EG Ost, innen | 34 m² | – | Terrasse | 1399, 359 | unbewohnt, abgeschlossen |
| 028 | EG Ost, innen | 34 m² | – | Terrasse | 1339, 299 | unbewohnt, abgeschlossen |
| 029 | EG Ost, innen | 34 m² | – | Terrasse | 1279, 299 | H24 Agnes Möller |
| 030 | EG Ost, innen | 34 m² | – | Terrasse | 1179, 299 | unbewohnt, abgeschlossen |
| 031 | EG Ost, innen | 34 m² | – | Terrasse | 1119, 299 | unbewohnt, abgeschlossen |
| 032 | EG Ost, innen | 34 m² | – | Terrasse | 1059, 359 | unbewohnt, abgeschlossen |
| 033 | EG Ost, innen | 34 m² | – | Terrasse | 1059, 419 | H25 Gustav Peters |
| 034 | EG West, Südseite | 103 m² | ja | – | 429, 739 | H18 Paar Falk |
| 035 | EG West, Südseite | 103 m² | ja | – | 209, 739 | H17 Paar Nowak |
| 036 | EG West, Südseite | 80 m² | ja | – | 63, 725 | H11 Ehepaar Lorenz |
| 037 | EG West, innen | 103 m² | ja | – | 49, 579 | unbewohnt, abgeschlossen |
| 038 | EG West, Nordflügel | 68 m² | ja | – | 79, 199 | unbewohnt, abgeschlossen |
| 039 | EG West, Nordflügel | 68 m² | ja | – | 199, 199 | H37 Sami Haddad |
| 040 | EG West, Nordflügel | 68 m² | ja | – | 399, 199 | unbewohnt, abgeschlossen |
| 041 | EG West, Nordflügel | 92 m² | ja | Terrasse | 539, 199 | H12 Ehepaar Schulte |
| 042 | EG West, innen | 34 m² | – | Terrasse | 589, 299 | unbewohnt, abgeschlossen |
| 043 | EG West, innen | 34 m² | – | Terrasse | 589, 359 | H38 Zita Fuchs |
| 044 | EG West, innen | 34 m² | – | Terrasse | 589, 419 | unbewohnt, abgeschlossen |
| 045 | EG West, innen | 68 m² | ja | Terrasse | 489, 549 | H39 Oskar Pohl |
| 046 | EG West, innen | 68 m² | ja | Terrasse | 399, 639 | unbewohnt, abgeschlossen |
| 047 | EG West, innen | 68 m² | ja | Terrasse | 239, 639 | unbewohnt, abgeschlossen |
| 048 | EG West, innen | 68 m² | ja | Terrasse | 149, 549 | unbewohnt, abgeschlossen |
| 101 | OG1 Ost, Südseite | 68 m² | – | – | 909, 739 | unbewohnt, abgeschlossen |
| 102 | OG1 Ost, Südseite | 68 m² | – | – | 1029, 739 | H20 Bruno Kaminski (Kernfigur) |
| 103 | OG1 Ost, Südseite | 68 m² | – | – | 1149, 739 | unbewohnt, abgeschlossen |
| 104 | OG1 Ost, Südseite | 103 m² | ja | – | 1339, 739 | H04 Familie Krüger |
| 105 | OG1 Ost, Südseite | 80 m² | ja | – | 1485, 725 | verfallen, Tür offen (Vorschlag) |
| 106 | OG1 Ost, innen | 103 m² | ja | – | 1499, 579 | H05 Familie Sommer |
| 107 | OG1 Ost, innen | 103 m² | – | – | 1499, 359 | unbewohnt, abgeschlossen |
| 108 | OG1 Ost, Nordflügel | 68 m² | ja | – | 1469, 199 | unbewohnt, abgeschlossen |
| 109 | OG1 Ost, Nordflügel | 68 m² | ja | – | 1349, 199 | unbewohnt, abgeschlossen |
| 110 | OG1 Ost, Nordflügel | 80 m² | ja | – | 1139, 199 | unbewohnt, abgeschlossen |
| 111 | OG1 Ost, Nordflügel | 80 m² | ja | Balkon | 999, 199 | H15 Paar Haas |
| 112 | OG1 Ost, innen | 103 m² | – | Balkon | 959, 359 | H07 Familie Roth |
| 113 | OG1 Ost, innen | 68 m² | ja | Balkon | 1059, 389 | unbewohnt, abgeschlossen |
| 114 | OG1 Ost, innen | 68 m² | ja | Balkon | 1059, 549 | unbewohnt, abgeschlossen |
| 115 | OG1 Ost, innen | 68 m² | ja | Balkon | 1149, 639 | unbewohnt, abgeschlossen |
| 116 | OG1 Ost, innen | 68 m² | ja | Balkon | 1309, 639 | unbewohnt, abgeschlossen |
| 117 | OG1 Ost, innen | 68 m² | ja | Balkon | 1399, 549 | H30 Paula Jansen |
| 118 | OG1 Ost, innen | 68 m² | ja | Balkon | 1399, 389 | unbewohnt, abgeschlossen |
| 119 | OG1 Ost, innen | 68 m² | ja | Balkon | 1309, 299 | H16 Paar Vogel |
| 120 | OG1 Ost, innen | 68 m² | ja | Balkon | 1149, 299 | unbewohnt, abgeschlossen |
| 121 | OG1 West, Südseite | 103 m² | ja | – | 429, 739 | H02 Familie Aydın |
| 122 | OG1 West, Südseite | 103 m² | ja | – | 209, 739 | H01 Familie Brandt |
| 123 | OG1 West, Südseite | 80 m² | ja | – | 63, 725 | H08 Familie Albers |
| 124 | OG1 West, innen | 103 m² | ja | – | 49, 579 | H03 Familie Lindner |
| 125 | OG1 West, Nordflügel | 68 m² | ja | – | 79, 199 | verfallen, Tür offen (Vorschlag) |
| 126 | OG1 West, Nordflügel | 68 m² | ja | – | 199, 199 | H09 Familie Berger |
| 127 | OG1 West, Nordflügel | 80 m² | ja | – | 409, 199 | unbewohnt, abgeschlossen |
| 128 | OG1 West, Nordflügel | 80 m² | ja | Balkon | 549, 199 | H13 Paar Weiß |
| 129 | OG1 West, innen | 103 m² | – | Balkon | 589, 359 | H06 Familie Demir |
| 130 | OG1 West, innen | 68 m² | ja | Balkon | 149, 549 | H14 Paar Engel |
| 131 | OG1 West, innen | 68 m² | ja | Balkon | 239, 639 | unbewohnt, abgeschlossen |
| 132 | OG1 West, innen | 68 m² | ja | Balkon | 399, 639 | unbewohnt, abgeschlossen |
| 133 | OG1 West, innen | 68 m² | ja | Balkon | 489, 549 | unbewohnt, abgeschlossen |

**Zusammen:** 81 Zimmer (EG 48, OG1 33) – 39 Haushalte und Zimmer 13 bewohnt, 4 Sonderzimmer (017, 018 und zwei verfallene), **37 unbewohnt** und abgeschlossen. **41 Zimmer haben einen Außenzugang**, davon 18 bewohnt (dazu Zimmer 13).
