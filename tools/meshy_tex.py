# Texturhilfen für Meshy-Modelle – gemeinsam für tools/build_guest.py und tools/build_pumpkin.py
# (Import: sys.path um tools/ erweitern).
import os
import numpy as np

## Godot-Import der GLB: Textur unkomprimiert einbetten („Embed as Uncompressed“)
GLB_IMPORT = {"gltf/embedded_image_handling": "3"}


def fill_gaps(rgb, filled, steps):
	"""Leere Texel (zwischen den UV-Inseln) bekommen die Farbe ihrer gefüllten Nachbarn – Schritt für Schritt."""
	for _ in range(steps):
		if filled.all():
			break
		acc = np.zeros_like(rgb)
		cnt = np.zeros(filled.shape, dtype=np.float32)
		for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1)):
			f = np.roll(filled, (dy, dx), axis=(0, 1))
			acc += np.roll(rgb, (dy, dx), axis=(0, 1)) * f[:, :, None]
			cnt += f
		grow = (~filled) & (cnt > 0)
		rgb[grow] = acc[grow] / cnt[grow][:, None]
		filled |= grow


def shrink(img, size, work_size=None):
	"""Lücken zwischen den UV-Inseln füllen und auf size verkleinern – erst in voller Größe füllen, sonst
	mischt das Verkleinern Schwarz in die Inselränder. work_size: Zwischengröße, in der noch einmal gefüllt
	wird (gibt die Pixel als Feld zurück, für Auswertungen wie die Färbemaske der Gäste)."""
	full = img.size[0]
	px = np.array(img.pixels[:], dtype=np.float32).reshape(full, full, 4)
	rgb = px[:, :, :3].copy()
	fill_gaps(rgb, rgb.max(axis=2) > 0.012, 4 * full // (work_size or size))
	px[:, :, :3] = rgb
	px[:, :, 3] = 1.0
	img.pixels[:] = px.ravel()
	del px, rgb
	if work_size:
		img.scale(work_size, work_size)
		px = np.array(img.pixels[:], dtype=np.float32).reshape(work_size, work_size, 4)
		rgb = px[:, :, :3].copy()
		fill_gaps(rgb, rgb.max(axis=2) > 0.012, 24)
		px[:, :, :3] = rgb
		img.pixels[:] = px.ravel()
		if work_size != size:
			img.scale(size, size)
		return rgb
	img.scale(size, size)
	return None


def write_import(dst):
	"""Textur unkomprimiert in Godot: Von sich aus zieht Godot sie als PNG heraus und packt sie per VRAM-Kompression –
	deren 4×4-Blöcke mischen an den UV-Nähten benachbarte Inseln ineinander (helle Streifen). Deshalb in der .import
	der GLB „Embed as Uncompressed“ (3); die liegt im Repo (.gitignore-Ausnahme), fehlt sie, legt das Skript sie an
	und Godot ergänzt den Rest."""
	imp = dst + ".import"
	lines = open(imp, encoding="utf-8").read().splitlines() if os.path.exists(imp) else \
		["[remap]", "", 'importer="scene"', 'type="PackedScene"', "", "[params]", ""]
	for key, value in GLB_IMPORT.items():
		at = [i for i, l in enumerate(lines) if l.startswith(key + "=")]
		if at:
			lines[at[0]] = key + "=" + value
		else:
			lines.append(key + "=" + value)   # [params] ist der letzte Abschnitt
	open(imp, "w", encoding="utf-8", newline="\n").write("\n".join(lines) + "\n")
	print("Godot-Import: Textur unkomprimiert eingebettet (%s)" % imp)
