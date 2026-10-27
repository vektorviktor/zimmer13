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
- **Offene Punkte, Lücken, nicht Gebautes, Ideen:** [OFFEN.md](OFFEN.md) – neue Ideen dort in 6
- **Wie es gebaut ist:** [TECHNIK.md](TECHNIK.md)
- **Starten, Steuerung, Debug-Parameter:** [README.md](README.md)

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
- **Grafik realistisch, nicht PS1:** Neue Materialien, Shader und Modelle auf das Bild *ohne* PS1-Look auslegen
  und so prüfen (`--no-psx`). Der PS1-Umschalter bleibt und darf nicht brechen, wird aber nicht bevorzugt; ein
  darauf optimierter Modus kommt erst am Ende (Spielkonzept 9.2, Entscheidung 25.10., TECHNIK.md 1 „Grafik“).
- `Item.Kind` und die Zufallsaufrufe in `GuestGenerator.make()` nur am Ende erweitern (Spielstände) – prüft
  `tests/run.tscn` (`save_rules`).
- Rauchtest in drei Stufen (TECHNIK.md 10): nach jeder Änderung `bash tests/smoke.sh schnell` (~½ min), nach Arbeit an
  einem System dessen Stichwort (`bash tests/smoke.sh schlaf`, Liste: `… stichworte`), vor größeren Commits
  `bash tests/smoke.sh` (alles, ~13 min). Neue Szenarien bekommen Stichworte, „schnell“ nur ausnahmsweise.
- Spielzeit läuft über `delta` bzw. `MonsterDirector.elapsed` – nie über Systemzeit (Pause!). Was mit `delta` über
  Minuten bis Stunden zählt, braucht `skip_time(dt)` in Gruppe `time_skip` (Zeitsprung im Schlaf, TECHNIK.md 3).

## Dokumentation pflegen
- Ändert sich ein System oder kommt eines hinzu: **TECHNIK.md im selben Commit anpassen.**
- Neue Mechanik für Spieler sichtbar → README („Was drin ist“); neuer Debug-Parameter → README-Tabelle
  und Kopfkommentar in `scripts/main.gd`.
- Commit-Nachrichten auf Deutsch, kurz, im Stil der bisherigen.
