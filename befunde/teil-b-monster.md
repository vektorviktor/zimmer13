# Befunde Teil B – Monster

Geprüft wurden Kapitel 4 des Spielkonzepts (4.1–4.33, Z. 1682–3071), TECHNIK 5 und 8a sowie 15 Code-Stichproben.
Das Hauptproblem: Die vier Modi (4.33, ab 25.10.) haben das ältere Modell aus Aktivphasen, drei Absichten, Druck
je Zone und Sättigungsfenster ersetzt, doch 4.3, 4.5, 4.9–4.13, 4.16 und 4.17 beschreiben es weiter im Präsens.
Dazu kommen Gästesätze im Code, die dem Spieler noch die alte Bedeutung des Flackerns beibringen. Spielerisch am
schwersten wiegen drei Punkte: Der Raubzug lässt sich ohne Risiko entschärfen. Das Urteil vor Zimmer 13 und die
Anforderung lassen in Echtzeit kaum Zeit zum Reagieren. Die heißen Stellen (Lärm, Licht aus, Gerede) wirken unter
den Modi fast nur noch auf die Dreistigkeit, sodass das Ablenken aus 4.11 großenteils leerläuft.

## Befunde

### B-01 Raubzug lässt sich ohne Risiko entschärfen
- Art: Optimierung (Balance), mit Code-Beleg
- Schwere: hoch
- Fundstellen: `SK 4.33` (SPIELKONZEPT.md:3021, 3024–3027, 3034–3037); `TECHNIK.md:1145–1150`;
  `scripts/monster/monster_director.gd:1482–1484` (`on_chase` → `_no_break_in = true`), `:1780–1782` (jedes geworfene
  `Item` in Hörweite → `_no_break_in = true`), `:1013–1014` (`player_safe`: Zimmer 13), `:1027`
- Befund: Für einen Raubzug ohne Opfer reicht schon der **Beginn** einer Jagd auf den Spieler oder **ein
  beliebiger Wurf**, dem das Monster nachgeht. Zimmer 13 öffnet es beim Raubzug nie (TECHNIK 1120), und wer dort
  steht, gilt als „nicht gefunden“. Daraus ergibt sich eine risikolose Standardlösung: in der offenen Tür von Zimmer
  13 stehen, sich sehen lassen, einen Schritt hineingehen. Oder man wirft beim mittleren Flackern einfach irgendetwas
  in den Flur. Damit fällt der „spielerisch wichtigste Modus“ (3019) aus, und die Bilanz „Raubzüge je nach Spieler
  0–8“ (3067) landet für jeden, der das einmal herausgefunden hat, bei 0.
- Vorschlag: Ein Wurf **verzögert** nur (`RAID_DISTRACTED`) und hebt den Einbruch nicht auf. „Gefunden“ zählt erst,
  wenn die Jagd einige Sekunden dauert oder in einem Abstand unter X m beginnt. Zimmer 13 bleibt beim Raubzug zu, zählt
  dann aber wie ein Versteck: Es folgt der Einbruch bei einer schwachen Tür, am besten in der Nähe von Zimmer 13
  (Nachbarn).
- Entscheidung nötig: ja

### B-02 Gästesätze lehren die alte Bedeutung des Flackerns
- Art: Code-Abweichung
- Schwere: hoch (das Kernsignal wird dem Spieler falsch beigebracht)
- Fundstellen: `scripts/guests/guest_profiles.gd:38` („Zuckt das Licht nur kurz, sieht es sich bloß um. Aber wenn es
  lange flackert … dann hat es Hunger.“), `:152` („Verlass dich nicht auf ein kurzes Flackern … manchmal lügt es.“);
  `SK 4.17` (SPIELKONZEPT.md:2049–2051, 2059–2061, 2120); `SK 4.33` (2939)
- Befund: Seit 4.33 bedeutet kurzes Zucken **Snack**, also den einzigen Modus, der zuerst auf den Spieler zuläuft und
  jeden nimmt, der ihm über den Weg läuft. Die Gäste erklären das kurze Zucken aber weiter für harmlos. Die Täuschung
  steht ebenfalls noch in einem Gästesatz, obwohl der Code sie nicht mehr kennt (siehe B-06). Der Spieler lernt über
  den vorgesehenen Weg (2120: „So lernt der Spieler das Signal“) also das Gegenteil.
- Vorschlag: Die Sätze „monster“ aller Profile und `guest_generator.gd` auf die vier Modi umschreiben (kurz = es kommt
  zu dir, mittel = es sucht dich, lang + Rauschen = es fordert). Den Warnungszettel von 1994 (4.17 Kopf, Z. 2057) und
  die Hinweise bei Edna und Mila mitprüfen.
- Entscheidung nötig: nein (nur der Wortlaut)

### B-03 Urteil vor Zimmer 13: kurze Frist, keine gezielte Rückmeldung, sicherer Tod
- Art: Lücke / Optimierung (unfairer Tod)
- Schwere: hoch
- Fundstellen: `SK 4.33` (SPIELKONZEPT.md:2970, 2990–2991, 3000–3001); `SK 5.5` (3145–3146, 3156); `TECHNIK.md:1183`;
  `scripts/monster/monster_director.gd:95` (`JUDGMENT_HOUR` 22–26 Uhr), `:106` (`DOLL_LEAD` 2–5 Spielstunden =
  2–5 Echtminuten, `Calendar.HOUR` = 60 s)
- Befund: Liegt die Puppe vor Zimmer 13, ist der Tod sicher, sofern man nicht rechtzeitig nachbessert. Die Frist
  beträgt 2–5 Echtminuten. Das Grollen ist im ganzen Hotel gleich, verrät also nicht, **welche** Tür betroffen ist. Nur
  Gäste, die vor ihrer eigenen Tür stehen, sprechen die Puppe an (TECHNIK 1183). Vor Zimmer 13 meldet sich niemand.
  Wer in U2, im Garten oder auf dem Dachboden unterwegs ist, kommt in der Zeit kaum zurück, um sie zu finden und
  nachzubessern. Die Urteile fallen zudem auf 22–26 Uhr, also oft in den Schlaf.
- Vorschlag: Ein eigenes Signal, wenn die Puppe vor Zimmer 13 liegt: ein Anruf eines Freundes („Die Puppe sitzt vor
  deiner Tür“, passt zu 4.14), das Telefon in Zimmer 13 klingelt, oder ein Notizbucheintrag, sobald man sie sieht.
  Alternativ für Zimmer 13 eine längere Frist bzw. die Puppe dort zu Tagesbeginn setzen.
- Entscheidung nötig: ja

### B-04 Anforderung: eine Echtminute zum Nachbessern, ohne Anzeige, welche Türen fallen
- Art: Optimierung (Balance/Lesbarkeit)
- Schwere: mittel
- Fundstellen: `SK 4.33` (SPIELKONZEPT.md:3045–3047, 3061–3063); `scripts/monster/monster_director.gd:146`
  (`DEMAND_WARN := Calendar.HOUR` = 60 s)
- Befund: „Eine Spielstunde vorher“ heißt eine Echtminute. In dieser Zeit soll man Türen über den Anspruch heben und
  Gäste aus schwachen Zimmern holen. Welche Türen unter dem Anspruch liegen, sieht man aber nicht (der Wert ist
  verborgen, 4.9). Die Gäste schließen sich nach Plan in genau diesen Zimmern ein („die Falle“, 3063). Zwei bis drei
  Ereignisse mit bis zu 7 Opfern hängen so an einer Minute Raterei.
- Vorschlag: Das Rauschen deutlich früher beginnen lassen (Abenddämmerung), und/oder die schwachen Türen sichtbar
  machen: Deko „zuckt“ dort wie bei `show_repel`, nur andersherum, oder Gäste in schwachen Zimmern sprechen es an.
- Entscheidung nötig: ja

### B-05 4.17 beschreibt im Hauptteil weiter die abgelösten drei Absichten
- Art: veraltet
- Schwere: mittel
- Fundstellen: `SK 4.17` (SPIELKONZEPT.md:2059–2061, 2071–2113, 2129–2130, 2132–2138, 2140–2147)
- Befund: Ein Kopfvermerk (2048–2052) hebt den Abschnitt auf, der Text darunter gilt aber im Präsens weiter:
  Absichten-Tabelle, Opferzahl 1/n² je Aufbruch, Angriffschance je Tag mit „sechs Aufbrüchen am Tag“, „neun harmlose
  Aufbrüche“ (2094), „vom UV vertrieben → mindestens zwei“, „die Absicht kann sich ändern“ (2106), Puppe „1–2 Minuten
  vorher“ und „bis zu fünf Türen unterwegs“ (2140–2144). Laut TECHNIK (1168) hat das Urteil keine Flackerwelle; 5.5
  sagt dagegen noch „die Flackerwelle verrät, wie viele es holen will“ (3157).
- Vorschlag: 4.17 auf das Flackersignal kürzen (Welle, Dauer je Modus `SIGNAL_TIME` 1/3/8 s, Barrierefreiheit,
  Reaktion der Gäste, Halluzination) und den Rest als „Archiv 2026-10-17“ einklappen oder streichen. 5.5 (3157)
  angleichen.
- Entscheidung nötig: nein

### B-06 Täuschung des Signals: entschieden, aber nicht übernommen und nicht gebaut
- Art: Widerspruch
- Schwere: mittel
- Fundstellen: `SK 4.17` (SPIELKONZEPT.md:2098–2101, 2113, 2137); `SK 4.33` (2928, 2936–2941); `scripts/monster/
  monster_director.gd` (keine Täuschung, Grep nach „täusch/deceiv“ ohne Treffer; nur `fake` bei Halluzinationen,
  TECHNIK.md:1171)
- Befund: „Es täuscht manchmal (entschieden)“ steht unverändert in 4.17. 4.33 nennt die Täuschung weder als
  übernommen noch als gestrichen. Im Code gibt es sie nicht. Ob man sich auf ein kurzes Zucken verlassen kann, ist
  damit offen. Für die Lesbarkeit der Modi ist das eine Grundsatzfrage.
- Vorschlag: Ausdrücklich entscheiden. Empfehlung: keine Täuschung zwischen den Modi (das Signal ist das Versprechen
  von 4.33, „so weiß man nach dem Signal, was kommt“, 2932); Unsicherheit liefern nur Halluzinationen nach Todesfällen.
- Entscheidung nötig: ja

### B-07 Umherstreifen, Aktivphasen und Druck je Zone stehen weiter als geltend da
- Art: veraltet / Widerspruch
- Schwere: mittel
- Fundstellen: `SK 4.3` (SPIELKONZEPT.md:1705–1709); `SK 4.9` (1756, 1763–1770, 1779–1788); `SK 4.13` (1844–1845,
  1890–1900); `SK 4.33` (2949–2950, 2955–2959)
- Befund: 4.33 sagt: „Kein Modus 0 … bloßes Umsehen gibt es nicht mehr“, außerhalb der Modi gibt es nur die Runde im
  Keller. 4.3 („Umherstreifen statt fester Route“, „An jeder Zimmertür entscheidet es, ob es abbiegt“), 4.13
  („patrouilliert im ganzen Hotel (Flure, Zimmer, Lobby, Küche, Bar, Garten, Keller)“, „Ruhephasen werden kürzer“,
  „Regeln für Aktivphasen“) und 4.9 („Druck(Zone) > Abschreckung → Monster wählt diese Zone“, „Manifestation wächst mit
  dem höchsten Druck“) beschreiben noch das alte Modell. 4.9 widerspricht sich außerdem selbst: Der Kasten sagt
  „Dunkelheit und Deko wirken nur noch über die Abschreckung“ (1749), die Liste darunter führt „Neugier ↑ Dunkelheit,
  ↑ wenig Deko“ (1764–1765) und „Neugier pro Zone 0–100; soll zur Liste heißer Stellen werden“ (1763), obwohl das seit
  27.10. gebaut ist.
- Vorschlag: 4.3 und 4.13 auf „zwischen den Modi: Kellerrunde + Präsenz ohne Körper“ umstellen. In 4.9 nur noch
  Dreistigkeit (Start, Tagesanstieg, Boni, Abzüge) und heiße Stellen (Zweck: Startort von Snack/Raubzug) beschreiben,
  die Druck-Formel als Archiv.
- Entscheidung nötig: nein

### B-08 Heiße Stellen wirken unter den Modi kaum: Ablenken (4.11), Suchmodus (4.5), Licht aus (4.4)
- Art: Lücke / Optimierung
- Schwere: mittel
- Fundstellen: `SK 4.11` (SPIELKONZEPT.md:1802–1809, 1814); `SK 4.5` (1726–1727); `SK 4.4` (1717); `SK 4.33` (2951–2954,
  3021); `TECHNIK.md:1142–1149`; `scripts/monster/monster_director.gd:1801–1803` (bemerkt: heiße Stelle vor Zimmer 13)
- Befund: Unter den Modi bestimmen heiße Stellen nur, **wo** der nächste Snack oder Raubzug beginnt. Das Urteil folgt
  der Puppe, die Anforderung dem Anspruch, und der Raubzug peilt ohnehin den Spieler an. Damit leisten die meisten
  Ablenkmittel aus 4.11 (Licht sabotieren, Lärm, Telefon klingeln lassen, Gerüchte) fast nichts mehr gezielt gegen
  einen Gast. Gerede und Lärm erhöhen sogar die Dreistigkeit für alle. Gezielt wirkt nur noch der Deko-Diebstahl
  (Puppe). Der Suchmodus „Der eigene sichere Ort wird zum Ziel“ (4.5) und „Licht aus = das Monster kommt“ (4.4)
  versprechen eine Wirkung, die das Spiel kaum noch einlöst. Die moralische Kernspannung aus 4.11 („Opfere ich
  jemanden?“, 1814) hängt damit an einem einzigen Mittel.
- Vorschlag: Den heißen Stellen eine Rolle in den Modi geben, z. B. beim Raubzug-Einbruch (B-01) und beim Snack die
  Tür bzw. Etage mit der größten Hitze, bei Gleichstand in der Puppenwahl die heißere Tür. Alternativ 4.11, 4.4 und
  4.5 ehrlich auf das reduzieren, was gilt.
- Entscheidung nötig: ja

### B-09 Sättigung: versprochenes Zeitfenster gibt es nicht (100 Sekunden)
- Art: Code-Abweichung / Widerspruch
- Schwere: mittel
- Fundstellen: `SK 4.10` (SPIELKONZEPT.md:1793–1797); `SK 4.9` (1761); `scripts/monster/monster_director.gd:31, 33, 312`
  (`SATIATION` 10, Abbau 0,1 je Sekunde); `SK 7` (5318: Zimmer 18 „am besten … in der Sättigung“)
- Befund: 4.10 verspricht ein spürbares Zeitfenster („sicherer in dunkle Bereiche … nachts in den Garten“, „Lichter
  flackern nicht mehr“). Im Code klingt die Sättigung in 100 Echtsekunden ab (knapp 1¾ Spielstunden) und ändert nur
  die Dreistigkeit.
  Dauerhaft wirken −1,5 je Opfer (`VICTIM_BOLDNESS`). Wann das Monster kommt, legt der Plan fest, nicht der Hunger.
  Kapitel 7 rät trotzdem zum Ausflug „in der Sättigung“.
- Vorschlag: 4.10 auf „jedes Opfer schiebt die nächste Anforderung hinaus“ kürzen. Echte sichere Fenster sind die
  Lücken zwischen Kellerrunden und Modi. Will man sie lesbar machen, ginge das z. B. über die Ratten (4.25): ruhig =
  keine Runde. 7 (5318) anpassen.
- Entscheidung nötig: nein (falls das Zeitfenster gewollt bleibt: ja)

### B-10 Spürbarkeit über eine Nacht: zu wenig Körper, Rauschen wird verwässert
- Art: Optimierung (Spielerlebnis)
- Schwere: mittel
- Fundstellen: `SK 4.13` (SPIELKONZEPT.md:1838–1846); `SK 4.33` (2949–2954, 2955–2958); `scripts/monster/
  monster_director.gd:92–99` (24–33 Auftritte), `:149–153` (Kellerrunde, Präsenz alle 90–240 s)
- Befund: 24–33 Auftritte in rund 29 Spieltagen sind etwa einer je Spieltag (24 Echtminuten), viele davon tagsüber
  (`SNACK_HOUR` 9–23, `RAID_HOUR` 10–26). Viele Nächte vergehen ohne Körper. Oberhalb des Kellers bleiben dann nur
  Geräusche hinter Wänden und „Rauschen ohne Monster“. Das Rauschen ist aber das Signal für „wie nah“ (4.2, 1702).
  Kommt es oft ohne Monster, wird genau dieses Signal entwertet. Der Titel „Ständige Präsenz“ und „Silhouette am
  Flurende“ (4.1, 1688) werden kaum eingelöst.
- Vorschlag: Ohne Körper keine Rausch-Halluzination außer nach Todesfällen (wie 4.13 ursprünglich). Dazu kurze,
  ungefährliche Sichtungen (Silhouette am Flurende, die beim Hinsehen „slinkt“) als eigener Präsenz-Baustein und eine
  seltene nächtliche Runde im EG/OG ohne Angriff, oder die Kellerrunde nachts gelegentlich bis in den Erdgeschossflur.
- Entscheidung nötig: ja

### B-11 Anspruch: an Tagen oder an der Dreistigkeit?
- Art: Widerspruch
- Schwere: mittel
- Fundstellen: `SK 4.33` (SPIELKONZEPT.md:3045–3047); `SK 4.8` (1741–1742); `SK 5.10` (3391, 3469–3470);
  `TECHNIK.md:1066–1067, 1158–1159`; `scripts/monster/monster_director.gd:51–53`
- Befund: 4.33 sagt: „Je dreister der Leviathan, desto höher sein Anspruch an die Deko“. 4.8, 5.10 und der Code
  binden den Anspruch an den Tag (×1 → ×3). Die Dreistigkeit bestimmt nur, **wann** eine Anforderung kommt
  (`_demand_doors` nutzt `is_blocked`, also den Tagesanspruch).
- Vorschlag: 4.33 (3045) umformulieren: „Die Dreistigkeit bestimmt, wann; der Tagesanspruch (4.8), welche Türen.“
- Entscheidung nötig: nein

### B-12 Dreistigkeit: Startwert, Tagesanstieg und Boni widersprechen sich
- Art: Code-Abweichung / Widerspruch
- Schwere: niedrig
- Fundstellen: `SK 4.9` (SPIELKONZEPT.md:1756 „ab 0“); `SK 2.4` (299 „+12 je Spieltag“); `SK 4.33` (2921 „+2,7“,
  3059 „Ziel Tag 14 und 21“); `SK 4.16` (2034 „+6 … wie bemerkt“); `scripts/monster/monster_director.gd:26`
  (`BOLDNESS_START` 25), `:27–29`, `:1802` (bemerkt +8)
- Befund: Die Dreistigkeit startet im Code bei 25, nicht bei 0. Erst mit diesem Start passt „erste Schwelle 55 etwa an
  Tag 14“ (Code-Kommentar 27–28). 2.4 nennt noch +12 je Spieltag. 4.16 setzt UV (+6) mit „bemerkt“ gleich, der Code
  gibt für „bemerkt“ +8.
- Vorschlag: 4.9 auf Start 25, +2,7/Tag und die Bonus-Tabelle (bemerkt 8, UV 6, Gerede 1, Lärm/Licht aus 0,3, je
  höchstens einmal je Spielstunde, `LURE_EVERY` 60 s) bringen. 2.4 (299) streichen bzw. verweisen.
- Entscheidung nötig: nein

### B-13 Klopfen an Zimmer 13 ist unter den Modi ungeregelt
- Art: Lücke (mit Code-Beleg)
- Schwere: mittel
- Fundstellen: `SK 4.13` (SPIELKONZEPT.md:1864–1866); `scripts/guests/social.gd:2236` (Auslöser: Monster aktiv und
  ≤ 28 m von Zimmer 13), `:2242–2248` (auch Versteckte rennen zur Tür), `:2332–2333` (`spawn_near_unseen` am Gast +
  `kill_guest`); `TECHNIK.md:1161` (`kill_guest` holt nur, wen der Modus will)
- Befund: Das Klopfen holt einen beliebigen Gast, sogar aus seinem Versteck, sobald irgendein Modus das Monster in
  die Nähe von Zimmer 13 bringt. Das gilt auch beim Raubzug, der nur den Spieler will, und beim Urteil gegen jemand
  anderen. Öffnet man nicht, wird das Monster neben den Gast versetzt, und `kill_guest` entscheidet nach dem Modus.
  Ob dann der Schrei mit Stille (4.13) oder nur ein Schreck folgt, ist nicht festgelegt und widerspricht womöglich der
  Regel des Modus (Urteil: „in dieser Nacht stirbt niemand mehr“). Außerdem springt das Monster dabei weg.
- Vorschlag: Das Klopfen an die Modi binden: echtes Klopfen nur beim Snack und bei der Anforderung (wo Gäste
  tatsächlich Beute sind), beim Raubzug und Urteil nur die falsche Stimme. Ausdrücklich festlegen, ob der Gast vor
  der Tür stirbt.
- Entscheidung nötig: ja

### B-14 Kürbismann-Sicht: drei Zahlen, eine nicht gebaute Entscheidung
- Art: Widerspruch / Lücke (Stand)
- Schwere: mittel
- Fundstellen: `SK 4.19` (SPIELKONZEPT.md:2330 „etwa 14 m“); `SK 4.20` (2366 „18 m rundum, Licht und Ducken egal“,
  2424–2426 „nach 4.15, Vorschlag etwa 12 m“); `SK 4.21` (2463–2464 „Grundweite 12 m“); `scripts/monster/
  pumpkin_man.gd:79` (`SIGHT_RANGE` 18), `:83` (`PLAYER_NOTICE` 14), `:121` (`SHOW_SIGHT` 12)
- Befund: Punkt 3 von 4.20 (gleiche Sicht wie das Monster über `Senses.can_see`) ist entschieden, aber nicht gebaut.
  Im Spiel sieht er 18 m rundum, Ducken und Dunkel helfen nicht. Ausgerechnet „man kann ihm im Dunkeln ausweichen“ (der
  Grund für Punkt 3, 2425–2426) fehlt also gegen den tödlichsten Angreifer. Die drei Zahlen meinen Verschiedenes
  (Opfer sehen, Spieler bemerken, Kürbis zeigen), stehen aber unerklärt nebeneinander.
- Vorschlag: Punkt 3 bauen oder bewusst zurücknehmen. Danach in 4.19 eine kleine Tabelle: Sicht auf Opfer, Spieler
  bemerken, Betäuben.
- Entscheidung nötig: ja (ob Punkt 3 bleibt)

### B-15 Lakengeist und Vorhang: „hält ihn draußen“ gilt nur bis zum 3. Mal
- Art: Widerspruch / Lesbarkeit
- Schwere: mittel
- Fundstellen: `SK 4.18` (SPIELKONZEPT.md:2195–2196 „Ist eins davon nicht erfüllt, kommt er nicht“, 2208 „ab dem 4.
  Mal auch bei zugezogenem Vorhang“, 2265 „Vorhang zu hält den Geist draußen“); `scripts/monster/sheet_ghost.gd:7, 386`
- Befund: Zwei Stellen in 4.18 erklären den Vorhang zum sicheren Schutz, die Tabelle und der Code lassen ihn ab dem
  4. Mal nicht mehr gelten. Der Spieler lernt also eine Regel, die später stillschweigend wegfällt. Ein Signal, dass
  der Vorhang nicht mehr schützt, ist nicht beschrieben.
- Vorschlag: Die Stellen 2195 und 2265 angleichen („bis zum 3. Mal“). Den Wechsel sichtbar machen, z. B.
  Handabdrücke oder Wölbung **im Vorhang** beim ersten Mal, an dem er hindurchkommt, oder ein Gästegerücht.
- Entscheidung nötig: nein (Signal: ja)

### B-16 Dusche wartet auf „keine andere Bedrohung“ und sperrt solange den Schlaf
- Art: Lücke (Zustand ohne sicheren Ausweg) / Widerspruch
- Schwere: mittel
- Fundstellen: `SK 4.24` (SPIELKONZEPT.md:2676–2677, 2682–2684); `SK 4.1` (1694–1695 „Keiner wartet mehr … nur im
  Albtraum“); `TECHNIK.md:1055–1058` (Dusche fragt `other_threat_active`)
- Befund: Die Dusche läuft, bis man sie erlebt. Sie erscheint aber nur, wenn keine andere Bedrohung im Haus ist
  (Monster unterwegs oder angekündigt, Kürbismann, **Lakengeist anderswo**, Geisterstunde). Der Lakengeist besucht
  nachts Gäste an Fenstern und kommt mit Schwäche häufiger. So kann die Dusche lange blockieren. In dieser Zeit sperrt
  sie den Schlaf, das hebt die Schwäche, und die wiederum ruft den Lakengeist öfter (Teufelskreis). 4.1 behauptet
  zudem pauschal, nur im Albtraum warte etwas. Die Ausnahmen (Dusche, Zeitsprung, Siegerehrung, Namensszene) stehen
  nur in TECHNIK.
- Vorschlag: Die Dusche wartet nur auf Bedrohungen in der Nähe von Zimmer 13 bzw. auf das aktive Monster. Notfalls
  nach einer Frist Schlaf trotzdem erlauben. In 4.1 die Szenen nennen, die warten.
- Entscheidung nötig: ja

### B-17 Kürbismann erlöst: „Erdgeschoss frei“ und „Angriffschance eine Stufe höher“ ohne Grundlage
- Art: veraltet / Lücke
- Schwere: mittel
- Fundstellen: `SK 4.21` (SPIELKONZEPT.md:2487–2488, 2495–2496); `SK 4.20` (2378–2381); `SK 4.33` (3017–3019)
- Befund: „Das Erdgeschoss ist frei (4.20)“ stammt aus der Zeit des Ebenen-Ausschlusses (seit 3.11. weg). „Die
  Angriffschance (4.17) liegt eine Stufe höher“ hat unter den Modi keinen Gegenstand mehr: Die Raubzüge sind beim
  Spielstart verplant, und Stufen gibt es nicht.
- Vorschlag: z. B. +1 Raubzug im Restplan oder einmalig Dreistigkeit +X (bringt die Anforderung näher, passt zu
  „Verlust“). Den EG-Satz streichen.
- Entscheidung nötig: ja

### B-18 Dachgeschoss: „keine Bedrohung erscheint“ gegen Notausgang und Vampir; Ebenenregel des Vampirs veraltet
- Art: Widerspruch / veraltet
- Schwere: niedrig
- Fundstellen: `SK 4.21` (SPIELKONZEPT.md:2520–2525); `SK 4.20` (2388, 2396–2398); `SK 4.33` (2994–2996); `SK 4.22`
  (2542, 2569, 2584–2585, 2597–2598)
- Befund: 4.21 sagt „Auf dem Dachboden erscheint keine Bedrohung“. Dort erscheint aber das Monster beim Urteil und
  beim Raubzug (Notausgang), außerdem „ganz selten ein Vampir“. Der Vampir ist laut 4.22 eine Bedrohung „mit derselben
  Ebenenregel“, und nach der Tabelle erscheint im DG niemand. Die Ebenenregel des Vampirs („Ist die Ebene schon
  belegt, verwandelt sie sich nicht“, 2584–2585) gilt seit dem Wegfall des Ausschlusses (3.11.) nicht mehr.
- Vorschlag: In 4.21 „außer Notausgang (4.33) und Vampir (4.22)“ ergänzen, die Vampirzeile in die Tabelle von 4.20
  aufnehmen und 2584–2585 streichen.
- Entscheidung nötig: nein

### B-19 Vampir-Twist: Umfang und Konflikt mit „nichts Makabres“
- Art: Optimierung (Umfang)
- Schwere: mittel
- Fundstellen: `SK 4.22` (SPIELKONZEPT.md:2600–2607, 2609–2626); `HANDLUNG.md:93` (M21 „der Vampir zerfällt im Licht“)
- Befund: „Man wird selbst zum Vampir, muss Gäste beißen, sonst verhungert er“ ist eine zweite Spielrolle mit eigenem
  Ende, eigener KI-Reaktion und mehr als sechs offenen Fragen. Das Töten von Gästen als Pflichtmechanik reibt sich mit
  der Linie „kein Gore/keine makabren Mechaniken“ (Altersfreigabe). Der Vampir ist nicht gebaut, steht aber schon in
  einem festen Ende (M21).
- Vorschlag: Den Twist als Streichkandidat vorlegen. Den Vampir auf eine seltene Bedrohung mit Knoblauch/Kreuz
  begrenzen (der Fledermausbiss ist gebaut). M21 nicht von ihm abhängig machen.
- Entscheidung nötig: ja

### B-20 UV beim Urteil (und bei der Anforderung) wirkungslos, im Spielkonzept nicht gesagt
- Art: Lücke
- Schwere: niedrig
- Fundstellen: `SK 4.16` (SPIELKONZEPT.md:2033–2035); `SK 4.33` (2974–2978, 3036); `TECHNIK.md:1127`
  (Urteil: „Kein UV, keine Ablenkung“)
- Befund: 4.16 nennt als Ausnahmen nur „wenn es schon zupackt oder sich zurückzieht“. Dass UV und Würfe beim Urteil
  nichts bewirken, steht nur in TECHNIK. Für die Anforderung ist es nirgends festgelegt. Wer mit seiner letzten
  Batterie einen verurteilten Gast retten will, scheitert ohne Erklärung. 4.16 spricht zudem noch von „flieht in den
  Keller … Ruhephase ×0,4“ (2033–2034), ein Begriff, den es unter den Modi nicht mehr gibt.
- Vorschlag: In 4.16 eine Zeile „wirkt bei Snack, Raubzug und Kellerrunde; nicht beim Urteil (…), Anforderung: …“
  ergänzen und „Ruhephase ×0,4“ durch „der Auftritt endet“ ersetzen.
- Entscheidung nötig: ja (Anforderung)

### B-21 Lakengeist im Erdgeschoss: Flurregeln „kleinste Lösung, offen“
- Art: Lücke
- Schwere: niedrig
- Fundstellen: `SK 4.20` (SPIELKONZEPT.md:2399–2402); `SK 4.18` (2258–2259)
- Befund: Im EG soll der Lakengeist mit einem Drittel der Chance **nur an Außenfenstern** kommen, seine Flurregeln
  (Garantie Tag 10, ab dem 6. Mal, Schwäche) gelten dort aber voll. Als offen vermerkt, ohne Ticketverweis.
- Vorschlag: Entscheiden, ob die Flurregeln im EG ebenfalls auf ein Drittel gehen oder ganz entfallen.
- Entscheidung nötig: ja

### B-22 Lakengeist ohne Faden in der Hauptgeschichte
- Art: Optimierung (Story)
- Schwere: niedrig
- Fundstellen: `SK 4.20` (SPIELKONZEPT.md:2432–2433); `SK 4.18` (2282); `HANDLUNG.md` (Grep „Lakengeist“: kein Treffer)
- Befund: Monster (Josef, Ritual M19a) und Kürbismann (Rezeptionist, Erlösung M14) haben Herkunft, Fundstücke und
  Abschluss. Der Lakengeist („die Verschwundenen, Laken aus der Wäscherei“) hat nur einen Satz und taucht in der
  Handlung gar nicht auf, obwohl er der häufigste Angreifer ist und eine eigene Szene in Zimmer 13 hat (4.24).
- Vorschlag: Einen kleinen Faden anlegen, z. B. ein Fundstück in der Wäscherei (Wäscheliste mit Namen der Vermissten)
  oder einen Bezug zur Gedenktafel (Friedhof 5.15). Kein eigenes Erlösungsritual nötig.
- Entscheidung nötig: ja

### B-23 Kürbismann: Jeansjacke ist Deko in 4.21, Schlüsselträger in der Handlung; Vorgeschichte-Frage beantwortet
- Art: Lücke / veraltet
- Schwere: niedrig
- Fundstellen: `SK 4.21` (SPIELKONZEPT.md:2489–2492); `HANDLUNG.md:74` (M15b: Schlüsselbund fürs Büro in der
  Jeansjacke); `SK 4.19` (2360–2361 „Zu klären: Wie erfährt man die Vorgeschichte?“); `HANDLUNG.md:71` (M14: Liesels
  Auftrag)
- Befund: 4.21 kennt den Schlüsselbund in der Jacke nicht. Die offene Frage in 4.19 ist durch Liesel (M14, 2.7)
  wenigstens teilweise beantwortet.
- Vorschlag: In 4.21 bei der Jacke auf M15b verweisen. 4.19 „Zu klären“ auf „über Liesel (2.7, M14); weitere
  Fundstücke offen“ setzen.
- Entscheidung nötig: nein

### B-24 Erledigte „Zu klären“-Punkte und überholte Vorschläge in Kapitel 4
- Art: veraltet (Doku-Struktur)
- Schwere: niedrig
- Fundstellen: `SK 4.15` (SPIELKONZEPT.md:2015–2016, erledigt durch 1937); `SK 4.18` (2286–2287, erledigt durch 2157
  „ein wacher Gast mit Sicht“ und 2201 „Zähler über das ganze Spiel“); `SK 4.33` (3041–3042 „Vorschlag: UV gibt einen
  Bonus auf die Dreistigkeit“ – gebaut, 2034, `monster_director.gd:177`); `SK 4.8` (1743 „Evtl. Gewöhnung an konkrete
  Deko“ – nie entschieden, aber in 8 als gespeichert geführt, 6062)
- Befund: Mehrere offene Fragen sind längst beantwortet bzw. gebaut, eine Idee hängt ohne Entscheidung.
- Vorschlag: Abhaken. „Gewöhnung an konkrete Deko“ entscheiden oder als Idee ins Ticket verschieben.
- Entscheidung nötig: nein (4.8: ja)

### B-25 Dachform und Dachgeschoss-Umfang in 4.21/4.25 doppelt beschrieben
- Art: veraltet
- Schwere: niedrig
- Fundstellen: `SK 4.21` (SPIELKONZEPT.md:2501–2511 „Die Dachform darüber bleibt offen“, Kniestock 1,3 m; 2526–2527
  „kleinerer Grundriss“; 2536–2539 Mansarddach entschieden); `SK 4.25` (2766, 2773 „solange die Form des Dachs offen ist“)
- Befund: Im selben Abschnitt steht die Dachform als offen und als entschieden. „Kleinerer Grundriss“ widerspricht dem
  gebauten „Das ganze Dachgeschoss ist Dachboden“ (2501). Die Frage zum Dachnest in 4.25 hängt an der Dachform, die
  nun entschieden ist.
- Vorschlag: Den Kasten in 4.21 auf das Mansarddach umschreiben, „Kurz halten“ streichen. In 4.25 neu entscheiden,
  welches Dachfenster das Nest bekommt.
- Entscheidung nötig: nein (Nest: ja)

### B-26 Kesselkatze: alter Anfang widerspricht der Führerin
- Art: veraltet
- Schwere: niedrig
- Fundstellen: `SK 4.26` (SPIELKONZEPT.md:2778–2784, 2791–2792 gegen 2794–2803)
- Befund: Der Anfang („nur im Untergeschoss“, „geht voraus zum Kessel … zur UV-Schrift“) gilt nach der Führerin
  (ganzes Haus, Story-Punkte) nicht mehr. Der Hinweis „ersetzt das Führen oben“ hilft, die Absätze stehen aber noch im
  Präsens.
- Vorschlag: Die ersten Punkte auf Herkunft (Josefs Katze, Marion erkennt sie, Ritual) kürzen.
- Entscheidung nötig: nein

### B-27 Snack: „steigt aus dem Keller auf“ gegen „erscheint ungesehen auf der Etage“
- Art: Widerspruch
- Schwere: niedrig
- Fundstellen: `SK 4.33` (SPIELKONZEPT.md:3011); `TECHNIK.md:1142–1143`
- Befund: Das Spielkonzept lässt den Leviathan aufsteigen, der Code setzt ihn nah an die stärkste Lockung auf der
  Etage des Spielers. Für den Spieler macht das einen Unterschied: Eine Welle vom Keller her gibt Vorlauf, das
  Erscheinen auf der Etage nicht.
- Vorschlag: Eine Variante festschreiben. Bei Erscheinen auf der Etage sollte der Text die Fairness über die 5–10 s
  Anlauf und das Zucken begründen.
- Entscheidung nötig: nein

### B-28 Veraltete Monsterregeln in anderen Kapiteln
- Art: veraltet (Querbezug)
- Schwere: niedrig
- Fundstellen: `SK 2` (SPIELKONZEPT.md:200 „Ruhephasen von Anfang an kürzer“); `SK 2.1` (171 „neun Aufbrüche“);
  `SK 2.4` (295–299: sechs Aufbrüche am Tag, Absichten, +12 je Tag); `SK 2.x` (592, 643: Sättigung erklärt die
  harmlose Phase); `SK 5.5` (3157 Flackerwelle beim Urteil); `SK 7` (5318 „Ruhephase … Sättigung“); `SK 8` (6062
  Spielstand: „Absicht (4.17), Neugier je Zone, Deko-Gewöhnung“)
- Befund: Diese Stellen verweisen auf das Modell vor 4.33. Sie liegen in den Blöcken A, C und E und sind hier nur als
  Querbezug gemeldet.
- Vorschlag: Beim Zusammenführen mit den anderen Teilen abgleichen.
- Entscheidung nötig: nein

## Annahmen über andere Systeme
- Gäste gehen weder von sich aus noch auf Bitte ins Untergeschoss; Ausnahmen sind nur der Suchtrupp bis an die
  Kellertür und Doris an der Leviathanmauer (SK 4.33, Z. 2958–2961; 4.11, Z. 1808 → 7.9; 2.9, Z. 905).
- Nachtruhe 23–6 Uhr ± ½ h: alle Gäste im eigenen Bett, Licht aus; Schlafende sind keine Zeugen (4.18, Z. 2158–2159,
  2231).
- Bei der Flackerwelle laufen Gäste heim und schließen die Tür oder verstecken sich (4.33, Z. 3023; 5.5, Z. 3162–3164).
  Davon hängt ab, dass Snacks tagsüber kaum Gäste treffen.
- Kinder und Katzen sind nie Beute (4.12, Z. 1836 → 6.11, 6.13); Kernfiguren überleben verletzt, solange ihr Schutz
  gilt (4.33, Z. 2946–2947 → 6.0, 6.17).
- Eine aufgebrochene Tür lässt sich mit dem Werkzeugkasten reparieren, bis dahin nicht abschließen (4.33, Z. 2979 →
  6.19).
- Schwäche setzt sich aus Angst/Schock, Trauer, Müdigkeit, Rausch und Kindergrundwert zusammen (4.18, Z. 2269–2280 →
  3.6, 3.7, 6.8, 6.13). Der Fledermausbiss addiert +0,5, die Wunde heilt in 2–3 Spieltagen (4.22, Z. 2552 → 6.17).
- Spinnenbiss wirkt wie ein Glas an der Bar (4.23, Z. 2642 → 3.7).
- Erster Angriff = Siegerehrung am 2. Oktober, Gustav wird geholt (4.33, Z. 2967 → 2.5, 2.6); Lakengeist,
  Kürbismann, Fledermausbiss, Stromausfall, Spinnen-Biss, Spiegelgestalt und Kesselkatze erst danach (4.18 Z. 2161,
  4.19 Z. 2319, 4.22 Z. 2551, 4.28 Z. 2831, 4.23 Z. 2644, 4.27 Z. 2821, 4.26 Z. 2778).
- Balltage sind fest gesetzt, an ihnen kommt kein Modus, die Kellerrunde aber schon (4.33, Z. 2948, 2956 → 5.19,
  Z. 3776). Noch offen laut ZIM-47 (4.33, Z. 2925).
- Puppe: Nachbessern hilft bis zum Aufbruch, Kinder tragen sie zwischen den Urteilen umher, die Regel wird per
  Aushang und Warnungszettel mitgeteilt (4.33, Z. 2969–2971 → 5.5, Z. 3131, 3165–3168).
- Die Leviathanmauer schließt mit jedem Tag später und bleibt ab etwa Tag 15 nach einem Angriff offen; dahinter liegt
  der Dachboden-Schlüssel (4.21, Z. 2512–2513 → 7.4; HANDLUNG M14, M17).
- Kürbisse in Beeten und an Türen, große und geschnitzte Sorten unterscheidbar (4.21, Z. 2459–2466 → 5.10, 3c).
- Spaß-Quellen für den Kürbismann: Feier, Spieltisch, Süßes oder Saures, gemeinsames Schmücken (4.19, Z. 2307–2312 →
  7.1, 6.10, 6.13, 5.9).
- Zeugen-Regel des Lakengeists: Freunde können auf Bitte in Zimmer 13 wachen (4.18 → 6.18; SK 1409, 4823).
- Kostüme (Bettlaken, Vampir) ab dem 25., Bar schließt um Mitternacht (4.18, Z. 2255–2257; 4.22, Z. 2617 → 5.9).
- Kirchturmglocke zur Mitternacht kündigt die Geisterstunde an (4.18, Z. 2241 → 7.8).
- Lichtschalter, Vorhänge, Glühbirnen herausdrehen, Fenster/Milchglas (4.4, 4.11, 4.12 → 7.3).
- Sicherungskasten im Untergeschoss, Strom kommt sonst nach Stunden (4.28, Z. 2833–2834 → 2.5).
- Telefone in jedem Zimmer außer Wäscherei, Hauptapparat mit Nummer 0, Notruftelefon im reparierten Aufzug (4.14,
  Z. 1906, 1930 → 7.4).
- Fotowand in der Lobby für Dorés Druck und Paulas Foto (4.32, Z. 2904, 2916 → 5.14); Hugo H27, Liesel H26,
  Paula H30, Gerda Wagner H10 in 007 (4.32, 4.25, Z. 2763 → 6.20).
- Marion existiert als Figur (Tochter Josefs) und erkennt die Kesselkatze (4.26, Z. 2787–2789; 4.32, Z. 2909 → 2.8);
  im Spiel noch nicht vorhanden.
- 67 Gäste = 54 Erwachsene + 13 Kinder (4.33, Z. 3066 → 6.20, Z. 5065) – stimmt überein.
- Sterbebildschirm → letzter Spielstand (4.6, Z. 1732 → 8.7); Speichern während Ankündigung des Kürbismanns, Albtraum
  und Kamerafang gesperrt (4.20 Z. 2413, 4.29 Z. 2848, 4.24 Z. 2698 → 8.6).
- Zeitsprung im Schlaf: Der Plan der Modi läuft weiter, Raubzug bricht beim schlafenden Spieler ein, Zimmer 13 oder
  hörbarer Lärm weckt (TECHNIK.md:1173–1175 → SK 3.6, Z. 1391–1409). Nicht geprüft: ob ein Urteil vor Zimmer 13 im
  Schlaf rechtzeitig weckt (siehe B-03).
- Gruppenfoto an Halloween (4.22, Z. 2602 → 5.9) und Ende mit Schlüssel (HANDLUNG M21) setzen voraus, dass alle
  Bedrohungen an Halloween ein gemeinsames Ende haben.
- Spinnweben wachsen schneller, wo Spinnen leben (4.23, Z. 2636 → 5.4, 5.10).

## Nicht geprüft
- Kein Abgleich mit YouTrack (laut Auftrag); Ticketnummern nur aus dem Text übernommen.
- Nichts im Spiel ausprobiert; alle Balance-Aussagen (B-01, B-03, B-04, B-10) sind aus Text und Konstanten abgeleitet.
  B-01 ist über den Code belegt (`on_chase`, Wurf in `on_noise`), aber nicht im Lauf beobachtet.
- Der Ausgang des Klopfens (B-13): ob `kill_guest` beim Raubzug den Gast nur erschreckt, nicht nachverfolgt.
- Code-Stichproben (15): Dreistigkeit (Start, Tag, Boni), Sättigung, Raubzug-Ende (Jagd, Wurf, Zimmer 13), Fristen
  (Puppe, Anforderung, Notausgänge), Kürbismann-Sicht und Spaßwerte, Lakengeist-Chancen und Vorhang, Monstertempo,
  Sichtkegel (`MONSTER_FOV_DOT` 0,3 ≈ 145°, passt), UV-Werte (passen), Gästesätze, Klopfen. Nicht geprüft: Fledermäuse,
  Spinnen, Krähen, Spiegel, Vogelscheuche, Kind zu viel, Stromausfall, Albtraum, Poolwasser, Spuren und Regen (4.13).
- 4.14 (Telefone) und 4.25 (Krähen) nur auf Widersprüche zum Monster gelesen, nicht auf eigene Lücken.
- Kapitel 2.1, 2.4, 5.5, 5.10, 7 und 8 nur an den per Grep gefundenen Stellen; Details gehören zu den Blöcken A, C, E.
