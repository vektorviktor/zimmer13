# Zimmer 13 – Hinweise für Claude

First-Person-Horror im Hotel, Godot 4.7, GDScript. Alles wird im Code gebaut (keine Editor-Szenen).

## Sparsam lesen (Token!)
- Weitere Dokumente **nie vorsorglich oder ganz lesen**, nur wenn die Aufgabe es wirklich verlangt.
- Dann **gezielt**: erst per Grep nach Stichwort, Kapitelnummer (`5.13`) oder Überschrift suchen, danach nur
  den gefundenen Abschnitt mit `offset`/`limit` lesen.
- Was schon im Gespräch steht oder aus dem Code hervorgeht, nicht noch einmal nachlesen.
- Code genauso: zuerst Grep, dann nur die betroffenen Stellen lesen statt ganzer Dateien.
- Beim Pflegen der Doku (siehe unten) nur den betroffenen Abschnitt lesen und ändern.

## Weitere Dokumente

- **Was das Spiel sein soll:** [SPIELKONZEPT.md](SPIELKONZEPT.md) (Entscheidungen mit Datum)
- **Hauptgeschichte, Meilensteine eines optimalen Durchlaufs:** [HANDLUNG.md](HANDLUNG.md)
- **Alle Gegenstände mit Stand und Handlungsbezug:** [GEGENSTAENDE.md](GEGENSTAENDE.md) – bei neuen Gegenständen pflegen
- **Offene Punkte, Lücken, nicht Gebautes, Ideen:** YouTrack, Projekt `ZIM` (siehe unten). [OFFEN.md](OFFEN.md)
  ist seit 29.10. nur noch ein Verweis – nichts mehr hineinschreiben.
- **Planfarben, Planregeln, was der Code selbst setzt:** [PLANFARBEN.md](PLANFARBEN.md) – einzige Legende des Plans;
  neue Farbe dort eintragen, dann `python tools/build_colors.py`
- **Wie es gebaut ist:** [TECHNIK.md](TECHNIK.md)
- **Starten, Steuerung, Debug-Parameter:** [README.md](README.md)

## Aufgaben in YouTrack (Projekt ZIM, Entscheidung 29.10.)
YouTrack ist die einzige Aufgabenliste – unabhängig vom Branch. Entscheidungen mit Datum bleiben im
Spielkonzept, das Ticket verweist darauf (`SK 5.13`). Ist YouTrack nicht erreichbar: sagen, nicht blind weiterarbeiten.
- **Ticket nur für Größeres:** braucht eine Entscheidung oder ist eine Idee; mehr als ein Commit
  oder eine Sitzung oder eigener Branch; berührt Querschnitt (Speicherformat, `Item.Kind`/`GuestGenerator`, mehrere
  Subsysteme); Bug aus dem Spiel, der nicht gleich behoben wird. Kleine Fixes, Werte, Doku: kein Ticket.
- **State:** `Submitted` Idee · `To be discussed` Entscheidung fehlt · `Open` entschieden, baubar · `In Progress` ·
  `Fixed` committet, Rauchtest grün · `Verified` **setzt nur der Nutzer** nach Prüfung im Spiel (sonst `Reopened`) ·
  `Won't fix`/`Obsolete` gestrichen (bleibt stehen, damit es nicht neu vorgeschlagen wird). `Fixed` zählt als
  erledigt (fehlt in `#Unresolved`); ein Epic wird automatisch erledigt, sobald alle Unteraufgaben es sind.
  Gebautes mit Werten nur headless geprüft → Unteraufgabe der Prüfliste ZIM-59 auf `Fixed`.
- **Type:** `Feature`, `Bug`, `Task`, `Cosmetics` (Grafikfeinschliff), `Epic` (große Bögen, Meilensteine).
  **Subsystem** immer setzen. **Tags** für Querschnitt: `speicherformat`, `item-kind`, `hauptgeschichte`;
  `ruht` = nicht von sich aus vorschlagen.
- **Start:** Ticket auf `In Progress`, Kommentar mit Branch und berührten Dateien/Systemen. Dann **Überschneidungen
  prüfen**: `project: ZIM State: {In Progress}` und `project: ZIM #Unresolved` im selben Subsystem bzw. mit
  denselben Tags; Treffer in zwei, drei Zeilen melden und mit `relates to`/`depends on` verknüpfen.
- **Abschluss:** Commit-Nachricht beginnt mit der Nummer (`ZIM-23: …`). Kommentar mit Commit-Hash, Branch,
  gelaufener Rauchtest-Stufe und was nicht geprüft ist, dann `Fixed`. Nach dem Merge in master kurzer Vermerk.
- Keine Secrets, Zugangsdaten oder Personaldaten in Tickets.

## Wichtigste Regeln
- Kommentare, Doc-Kommentare (`##`) und Spieltexte auf Deutsch, Bezeichner auf Englisch. Doc-Kommentare
  verweisen auf das Spielkonzept, z. B. `(Spielkonzept 4.13)`.
- Systeme sprechen über die Referenzen in `Game` miteinander (`Game.director.on_noise(...)`), nicht über Signale.
- Interagierbar = `set_meta("interactable", self)` + `get_prompt(player)` / `interact(player)`.
- **Speicherformat:** Umbauten am Hotel (Türen, Lampen, Verstecke … verschoben, neu, weg) brauchen nichts –
  der Fingerabdruck der Welt (`SaveManager.note_world`) lehnt alte Stände dann mit Hinweis ab. Rückwärts-
  kompatibilität kommt erst spät (Entscheidung 19.10.). `VERSION`/`MIN_VERSION` nur erhöhen und `--savetest`
  nur laufen lassen, wenn sich am Speichern selbst etwas ändert (Felder in `collect`/`apply`, neue Gruppe →
  auch in `WORLD_GROUPS`).
- **Grafik realistisch:** Neue Materialien, Shader und Modelle in voller Auflösung mit Mipmaps, Normal- und
  Rauheitskarten (Spielkonzept 9.2, TECHNIK.md 1 „Grafik“).
- `Item.Kind` und die Zufallsaufrufe in `GuestGenerator.make()` nur am Ende erweitern (Spielstände) – prüft
  `tests/run.tscn` (`save_rules`).
- Rauchtest in drei Stufen (TECHNIK.md 10): nach jeder Änderung `bash tests/smoke.sh schnell` (~½ min), nach Arbeit an
  einem System dessen Stichwort (`bash tests/smoke.sh schlaf`, Liste: `… stichworte`), vor größeren Commits
  `bash tests/smoke.sh` (alles, ~13 min). Neue Szenarien bekommen Stichworte, „schnell“ nur ausnahmsweise.
  Vorweg laufen immer die Selbstprüfungen (`bash tests/smoke.sh pruefen`, Sekunden) – ihre Meldungen gleich beheben.
- Spielzeit läuft über `delta` bzw. `MonsterDirector.elapsed` – nie über Systemzeit (Pause!). Was mit `delta` über
  Minuten bis Stunden zählt, braucht `skip_time(dt)` in Gruppe `time_skip` (Zeitsprung im Schlaf, TECHNIK.md 3).

## Dokumentation pflegen
- Ändert sich ein System oder kommt eines hinzu: **TECHNIK.md im selben Commit anpassen.**
- Neue Mechanik für Spieler sichtbar → README („Was drin ist“); neuer Debug-Parameter → README-Tabelle
  und Kopfkommentar in `scripts/main.gd`.
- **Überholtes löschen, das Warum behalten** (Entscheidung 4.11.): Das Spielkonzept beschreibt nur den geltenden
  Stand. Abgelöste Beschreibungen, beantwortete „Zu klären“ und Zwischenstände ganz streichen (der alte Wortlaut
  steht im Git-Verlauf), keine Archivdatei. Die geltende Entscheidung behält Datum und, wo nicht offensichtlich, ihren
  Grund. Ernsthaft erwogene Alternativen als eine Zeile „Verworfen: X (Datum, Grund)“.
- Commit-Nachrichten auf Deutsch, kurz, im Stil der bisherigen.
