# Packt die Aseprite-Erweiterung „Palettennamen“ in eine installierbare .aseprite-extension (Zip).
# Aufruf aus dem Projektwurzelverzeichnis:  python tools/aseprite-palette-names/pack.py
import os, zipfile

HERE = os.path.dirname(os.path.abspath(__file__))
FILES = ["package.json", "palette-names.lua", "palette-file.lua"]
OUT = os.path.join(HERE, "palettennamen.aseprite-extension")

with zipfile.ZipFile(OUT, "w", zipfile.ZIP_DEFLATED) as z:
	for name in FILES:
		z.write(os.path.join(HERE, name), name)
print(OUT)
