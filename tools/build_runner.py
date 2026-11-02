# Tischläufer der Tafeln (DiningTable, ZIM-157): Damast aus der Vorlage des Nutzers (zweifarbiges Rankenmuster, nahtlos)
# als Fototextur für Mat.photo – Farbe, Normale (OpenGL) und Rauheit, je SIZE² (= Mat.PHOTO_SIZE), eine Kachel =
# DiningTable.RUNNER_METERS.
#
# Damast ist einfarbig gewebt, das Muster entsteht aus der Bindung: im Grund liegen die Schussfäden obenauf (quer), im
# Muster die Kettfäden (längs, Atlasbindung, glänzt) – daraus die Normale (Fäden je THREAD Pixel, fünfbindiger Atlas
# mit Versatz 2) und die Rauheit; dazu hebt sich das Muster eine Spur ab. Die Farben der Vorlage bleiben, jeder Faden
# bekommt eine leichte eigene Helligkeit und in den Mulden zwischen den Fäden wird es dunkler.
#
#   python tools/build_runner.py temp/tischlaeufer.png assets/textures/TableRunner
#   (schreibt <ziel>/table_runner_basecolor.png, _normal.png, _roughness.png)
import sys, os
import numpy as np
from PIL import Image

SRC, DST = sys.argv[1], sys.argv[2]
SIZE = 1024
THREAD = 4                # Pixel je Faden (bei 0,5 m je Kachel 2 mm)
SATIN = 5                 # Fäden je Rapport der Atlasbindung
SATIN_STEP = 2
RAISE = 0.6               # Muster über dem Grund (in Fadenhöhen)
NORMAL_STRENGTH = 2.2
ROUGH_GROUND = 0.82
ROUGH_PATTERN = 0.58
rng = np.random.default_rng(157)

src = Image.open(SRC).convert("RGB")
a = np.asarray(src).astype(np.float32)
# zwei Farben: Grund dunkler, Muster heller und kräftiger
pattern = a[..., 0] > (a[..., 0].min() + a[..., 0].max()) / 2.0
c_pattern = a[pattern].mean(axis=0) / 255.0
c_ground = a[~pattern].mean(axis=0) / 255.0
print("Grund", np.round(c_ground * 255), "Muster", np.round(c_pattern * 255), "Vorlage", src.size)
mask = np.asarray(Image.fromarray((pattern * 255).astype(np.uint8)).resize((SIZE, SIZE), Image.LANCZOS)) / 255.0
mask = np.clip(mask, 0, 1)


## Weichzeichnen mit Umlauf (die Kachel ist nahtlos) über die Fourier-Transformation
def blur(img, sigma):
	f = np.fft.fftfreq(SIZE)
	g = np.exp(-2 * (np.pi * sigma) ** 2 * (f[:, None] ** 2 + f[None, :] ** 2))
	return np.real(np.fft.ifft2(np.fft.fft2(img) * g))


# --- Bindung -----------------------------------------------------------------------------------------------------
yy, xx = np.mgrid[0:SIZE, 0:SIZE]
row_t, col_t = yy // THREAD, xx // THREAD
fy, fx = (yy % THREAD + 0.5) / THREAD, (xx % THREAD + 0.5) / THREAD
bump_y = np.sin(np.pi * fy)   # Wölbung quer über einen waagerechten Faden
bump_x = np.sin(np.pi * fx)
# Grund: Schuss (waagerecht) obenauf, taucht alle SATIN Fäden einmal ab; Muster: Kette (senkrecht) ebenso
dip_g = ((col_t - SATIN_STEP * row_t) % SATIN == 0)
dip_p = ((row_t - SATIN_STEP * col_t) % SATIN == 0)
h_ground = bump_y * np.where(dip_g, 0.35 + 0.4 * bump_x, 1.0)
h_pattern = bump_x * np.where(dip_p, 0.35 + 0.4 * bump_y, 1.0)
soft = blur(mask, 1.2)
height = h_ground * (1 - soft) + h_pattern * soft + RAISE * blur(mask, 2.5)
# leichte Unruhe im Garn
yarn = blur(rng.standard_normal((SIZE, SIZE)), 6.0)
height += 0.15 * yarn / yarn.std()

dx = (np.roll(height, -1, axis=1) - np.roll(height, 1, axis=1)) / 2.0
dy = (np.roll(height, -1, axis=0) - np.roll(height, 1, axis=0)) / 2.0
k = NORMAL_STRENGTH / THREAD
# OpenGL: Grün = Bild-oben; die Zeilen wachsen nach unten
n = np.stack([-dx * k, dy * k, np.ones_like(height)], axis=-1)
n /= np.linalg.norm(n, axis=-1, keepdims=True)

# --- Farbe -------------------------------------------------------------------------------------------------------
threads_g = rng.uniform(0.93, 1.05, SIZE // THREAD)[row_t]   # je Schussfaden
threads_p = rng.uniform(0.93, 1.05, SIZE // THREAD)[col_t]   # je Kettfaden
shade = threads_g * (1 - soft) + threads_p * soft
weave = h_ground * (1 - soft) + h_pattern * soft
shade *= 0.88 + 0.12 * weave                                    # Mulden zwischen den Fäden
mottle = blur(rng.standard_normal((SIZE, SIZE)), 40.0)
mottle = 1.0 + 0.06 * mottle / mottle.std()
color = (c_ground[None, None, :] * (1 - mask[..., None]) + c_pattern[None, None, :] * mask[..., None])
color = color * (shade * mottle)[..., None]
rough = (ROUGH_GROUND * (1 - soft) + ROUGH_PATTERN * soft) + 0.1 * (1 - weave)

os.makedirs(DST, exist_ok=True)
base = os.path.join(DST, "table_runner")
Image.fromarray((np.clip(color, 0, 1) * 255 + 0.5).astype(np.uint8)).save(base + "_basecolor.png")
Image.fromarray((np.clip(n * 0.5 + 0.5, 0, 1) * 255 + 0.5).astype(np.uint8)).save(base + "_normal.png")
Image.fromarray((np.clip(rough, 0, 1) * 255 + 0.5).astype(np.uint8)).save(base + "_roughness.png")
print("geschrieben:", base + "_basecolor.png", "_normal.png", "_roughness.png")
