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
- **Speicherformat:** Feste Welt-Objekte werden über die Reihenfolge in ihrer Gruppe zugeordnet.
  Ändert sich Anzahl oder Bau-Reihenfolge von Türen, Lampen, Schaltern, Fenstern, Verstecken, Truhen,
  Pflanzen oder Ressourcen-Stellen → `SaveManager.VERSION`/`MIN_VERSION` erhöhen. Danach `--savetest`.
- `Item.Kind` und die Zufallsaufrufe in `GuestGenerator.make()` nur am Ende erweitern (Spielstände).
- Spielzeit läuft über `delta` bzw. `MonsterDirector.elapsed` – nie über Systemzeit (Pause!).

## Dokumentation pflegen
- Ändert sich ein System oder kommt eines hinzu: **TECHNIK.md im selben Commit anpassen.**
- Neue Mechanik für Spieler sichtbar → README („Was drin ist“); neuer Debug-Parameter → README-Tabelle
  und Kopfkommentar in `scripts/main.gd`.
- Commit-Nachrichten auf Deutsch, kurz, im Stil der bisherigen.
