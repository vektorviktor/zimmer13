# Zeichnet die Hoteltapeten als hochaufgelöste Kacheln (Spielkonzept 7.2, Entscheidung 29.10.): Harlekin-Rauten im
# Wechsel aus Satin (hell, glänzend, feine waagerechte Webung) und Velours (dunkel, matt, Flor), dazwischen schmale
# Fugen. Bilder in assets/textures/ (Aufbau wie bei Mat.WALLPAPERS beschrieben):
#   wallpaper_<variante>.png        Farbe (sRGB), je Farbvariante
#   wallpaper_harlequin_normal.png  Normal Map (OpenGL, Y nach oben) aus der Höhe: Fugen vertieft, Flor erhaben
#   wallpaper_harlequin_rough.png   Rauheit (Satin glatt, Velours und Fugen stumpf) – beide für alle Farben gleich
# Kachel = TILE_M × TILE_M Meter (eine Bahnbreite), SIZE Pixel, zwei Rapporte je Richtung, nahtlos in beide
# Richtungen. Eigene Tapeten im selben Format brauchen dieses Skript nicht.
#
# Aufruf aus dem Projektordner (Blender 4.3, wegen numpy):
#   blender -b --python tools/build_wallpaper.py -- assets/textures
import bpy, sys, os, math
import numpy as np

argv = sys.argv[sys.argv.index("--") + 1:]
DST = os.path.abspath(argv[0])

SIZE = 1024
TILE_M = 0.53
PERIOD = SIZE // 2                 # Rapport in Pixeln (Rauten 26,5 cm breit)
PX_PER_M = SIZE / TILE_M
GROOVE_HALF = 0.0025 * PX_PER_M    # halbe Fugenbreite (Pixel)
GROOVE_DEPTH = 0.0006              # Meter
PILE_HEIGHT = 0.0002               # Flor des Velours über dem Satin (Meter)
# Farben (sRGB 0–255) wie die bisherigen gemalten Tapeten: Satin, Velours, Fuge
VARIANTS = {
	"teal": ((1, 113, 106), (4, 100, 94), (1, 92, 87)),
	"red": ((113, 1, 8), (100, 4, 10), (92, 1, 6)),
	"beige": ((146, 121, 101), (133, 117, 104), (133, 111, 93)),
	"brown": ((107, 74, 42), (96, 69, 44), (92, 64, 37)),
}
ROUGH_SATIN, ROUGH_VELOURS, ROUGH_GROOVE = 0.53, 0.9, 0.95   # Glanz wie zuvor: Satin 0,65, Velours 0,1

rng = np.random.default_rng(13)


## Kachelbares Wertrauschen: Zufallsgitter cells × cells, bilinear auf SIZE hochgezogen (mit Umlauf), −1 … 1.
def noise(cells):
	g = rng.uniform(-1.0, 1.0, (cells, cells))
	t = (np.arange(SIZE) + 0.5) * cells / SIZE - 0.5
	i0 = np.floor(t).astype(int)
	f = t - i0
	f = f * f * (3 - 2 * f)
	i0 %= cells
	i1 = (i0 + 1) % cells
	rows = g[i0][:, None, :] * (1 - f)[:, None, None] + g[i1][:, None, :] * f[:, None, None]
	rows = rows[:, 0, :]
	return rows[:, i0] * (1 - f)[None, :] + rows[:, i1] * f[None, :]


y, x = np.mgrid[0:SIZE, 0:SIZE].astype(np.float64) + 0.5
a = (x + y) / PERIOD + 0.5
b = (x - y) / PERIOD + 0.5
satin = ((np.floor(a) + np.floor(b)) % 2) == 0
fa = a - np.floor(a)
fb = b - np.floor(b)
d = np.minimum(np.minimum(fa, 1 - fa), np.minimum(fb, 1 - fb)) * PERIOD / math.sqrt(2.0)   # Pixel bis zur Fuge
groove = np.where(d < GROOVE_HALF, 0.5 + 0.5 * np.cos(np.pi * np.clip(d / GROOVE_HALF, 0, 1)), 0.0)

fiber = noise(512)                 # Flor, 2 px
weave = np.sin(y * 2 * np.pi / 4.0)   # Satin: waagerechte Webung, 4 px ≈ 2 mm
fine = noise(256)
mottle = noise(8)                  # großflächig ungleich gedruckt

height = np.where(satin, 0.00003 * weave, PILE_HEIGHT * (0.6 + 0.4 * fiber)) - GROOVE_DEPTH * groove
dx = (np.roll(height, -1, axis=1) - np.roll(height, 1, axis=1)) * 0.5 * PX_PER_M
dy = (np.roll(height, -1, axis=0) - np.roll(height, 1, axis=0)) * 0.5 * PX_PER_M   # Bild-y nach unten
normal = np.stack([-dx, dy, np.ones_like(dx)], axis=-1)
normal /= np.linalg.norm(normal, axis=-1, keepdims=True)

rough = np.where(satin, ROUGH_SATIN + 0.04 * fine, ROUGH_VELOURS + 0.03 * fiber)
rough = rough * (1 - groove) + ROUGH_GROOVE * groove


def save(name, rgb, color_space):
	img = bpy.data.images.new(name, SIZE, SIZE, alpha=False, float_buffer=False)
	img.colorspace_settings.name = color_space
	px = np.ones((SIZE, SIZE, 4))
	px[:, :, :3] = np.clip(rgb, 0.0, 1.0)
	img.pixels[:] = np.flipud(px).ravel()   # Blender zählt Zeilen von unten
	img.filepath_raw = os.path.join(DST, name + ".png")
	img.file_format = 'PNG'
	img.save()
	print("gespeichert", img.filepath_raw)


for variant, (c_satin, c_velours, c_groove) in VARIANTS.items():
	c_satin, c_velours, c_groove = (np.array(c) / 255.0 for c in (c_satin, c_velours, c_groove))
	shade = np.where(satin, 1.0 + 0.015 * weave + 0.01 * fine, 1.0 + 0.05 * fiber)[..., None]
	base = np.where(satin[..., None], c_satin, c_velours) * shade
	color = base * (1 - groove[..., None]) + c_groove * groove[..., None]
	color *= (1.0 + 0.025 * mottle)[..., None]
	save("wallpaper_%s" % variant, color, 'sRGB')
save("wallpaper_harlequin_normal", normal * 0.5 + 0.5, 'Non-Color')
save("wallpaper_harlequin_rough", np.repeat(rough[..., None], 3, axis=-1), 'Non-Color')
