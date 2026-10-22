# Zimmer 13 – Hinweise für Claude

First-Person-Horror im Hotel, Godot 4.7, GDScript. Alles wird im Code gebaut (keine Editor-Szenen).

- **Was das Spiel sein soll:** [SPIELKONZEPT.md](SPIELKONZEPT.md) (Entscheidungen mit Datum)
- **Wie es gebaut ist:** [TECHNIK.md](TECHNIK.md) – vor Änderungen an einem System den passenden Abschnitt lesen
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
- `Item.Kind` und die Zufallsaufrufe in `GuestGenerator.make()` nur am Ende erweitern (Spielstände) – prüft
  `tests/run.tscn` (`save_rules`). Vor größeren Commits `bash tests/smoke.sh` (TECHNIK.md 10).
- Spielzeit läuft über `delta` bzw. `MonsterDirector.elapsed` – nie über Systemzeit (Pause!).

## Dokumentation pflegen
- Ändert sich ein System oder kommt eines hinzu: **TECHNIK.md im selben Commit anpassen.**
- Neue Mechanik für Spieler sichtbar → README („Was drin ist“); neuer Debug-Parameter → README-Tabelle
  und Kopfkommentar in `scripts/main.gd`.
- Commit-Nachrichten auf Deutsch, kurz, im Stil der bisherigen.
