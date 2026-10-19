# Palettennamen – Aseprite-Erweiterung

Zeigt die Palette der aktiven Datei als Liste: **Farbkachel, Index, Name**. Gedacht für den Gebäudeplan
`map.aseprite`, dessen Legende nur in den Farbnamen steht („Wand“, „Tür Flur“, „Möbel: Bett“, „Licht: Kerze“ …).
Getestet mit Aseprite 1.3.18.6 (Steam).

## Installieren

Doppelklick auf `palettennamen.aseprite-extension` – oder in Aseprite
*Edit > Preferences > Extensions > Add Extension* und die Datei wählen.

Neu packen nach Änderungen an den Lua-Dateien (aus dem Projektwurzelverzeichnis), danach erneut installieren:

```bash
python tools/aseprite-palette-names/pack.py
```

## Benutzen

- Öffnen und schließen über **View > Palettennamen** oder im Paletten-Menü (☰-Knopf über der Palette)
  **Palettennamen anzeigen**. Fenster lässt sich verschieben und in der Größe ändern; Lage und Einstellungen
  bleiben gespeichert.
- **Beim ersten Öffnen fragt Aseprite** „The following script … wants to access this file“. Die Erweiterung
  liest die gespeicherte Datei, weil Aseprites Skript-Schnittstelle keine Farbnamen kennt. Am besten
  *Give full trust to this script* anhaken und *Allow Read Access* klicken – dann kommt die Frage nicht wieder.
  Die Erweiterung schreibt nie etwas; Palette und Datei bleiben unverändert.
- **Linksklick** auf einen Eintrag setzt die Vordergrundfarbe, **Rechtsklick** die Hintergrundfarbe.
  Die aktuelle Vordergrundfarbe ist in der Liste markiert; unten steht der Eintrag unter der Maus
  (oder die Vordergrundfarbe) mit Index, vollem Namen und Hex-Wert.
- **Gruppe:** nur einen Namensvorsatz zeigen (`Möbel`, `Ausstattung`, `Gegenstand`, `Licht`,
  `Ohne Vorsatz`, `Ohne Namen`). Die Liste wird aus der Palette gebildet, neue Vorsätze erscheinen von selbst.
- **Gruppiert:** Überschrift je Vorsatz; der Vorsatz fällt dann im Namen weg. Klick auf eine Überschrift
  klappt die Gruppe ein und aus.
- **Suche:** Teil des Namens, Index (`29`) oder Hex-Wert (`#7a3b`).
- Mausrad oder Leiste rechts zum Blättern.

## Wann sich die Liste aktualisiert

- Andere Datei (Tab) gewählt → Liste dieser Datei.
- Palette geändert (Farbe bearbeitet, verschoben, hinzugefügt, Rückgängig) → Farben sofort.
- Gespeichert → Namen neu aus der Datei.
- **Neu einlesen** liest die Namen von Hand nach (z. B. wenn die Datei außerhalb von Aseprite geändert wurde).

Die **Farben** kommen immer live aus der Palette, die **Namen aus der zuletzt gespeicherten Datei**. Wurde die
Palette seit dem Speichern geändert, ordnet die Erweiterung die Namen nach Farbwert bzw. Index zu und hängt
ein `*` an (unsicher); unten steht die Anzahl. Nach dem Speichern verschwindet der Stern. Neue, nie
gespeicherte Dateien und andere Formate als `.aseprite`/`.ase` haben keine Namen.

Farbnamen selbst lassen sich mit der Erweiterung nicht ändern. Für `tools/build_map.py` gilt weiter:
Namen und Reihenfolge der Palette nicht verändern.

## Dateien

| Datei | Inhalt |
|---|---|
| `package.json` | Beschreibung der Erweiterung für Aseprite |
| `palette-names.lua` | Fenster, Menübefehle, Ereignisse (Dateiwechsel, Palettenänderung, Speichern) |
| `palette-file.lua` | liest den Paletten-Chunk 0x2019 des ersten Frames (wie `build_map.py`) und ordnet die Namen zu |
| `test.lua` | Test im Batch-Modus, siehe unten |
| `pack.py` | baut `palettennamen.aseprite-extension` |

Test ohne Fenster (verändert nichts):

```bash
"C:/Steam/steamapps/common/Aseprite/Aseprite.exe" -b map.aseprite --script tools/aseprite-palette-names/test.lua
```

Bei mehreren Paletten in einer Datei (Palettenwechsel in späteren Frames) werden nur die Namen der
Palette im ersten Frame gelesen.
