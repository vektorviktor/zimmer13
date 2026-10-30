# Beruhigtes Holz der Vertäfelung (Spielkonzept 7.2, Entscheidung 29.10.): nimmt aus dem Farbbild von Wood067 die
# großen hellen und dunklen Wolken heraus und lässt die feine Faser stehen – sonst wirkt jedes Feld fleckig. Die
# Helligkeit wird durch ihren weichgezeichneten Verlauf (Gauß, SIGMA Pixel bei SIZE) geteilt, STRENGTH = Anteil;
# gefaltet über die Fourier-Transformation, also mit Umlauf – das Bild bleibt nahtlos kachelbar.
#
# Aufruf aus dem Projektordner (Blender wegen numpy):
#   blender -b --python tools/wainscot_wood.py -- assets/textures/Wood067/Wood067_2K-JPG_Color.jpg assets/textures/wainscot_wood.png
import bpy, sys, os
import numpy as np

argv = sys.argv[sys.argv.index("--") + 1:]
SRC, DST = os.path.abspath(argv[0]), os.path.abspath(argv[1])

SIZE = 1024       # = Mat.PHOTO_SIZE
SIGMA = 16.0
STRENGTH = 0.9

img = bpy.data.images.load(SRC)
img.scale(SIZE, SIZE)
px = np.array(img.pixels[:], dtype=np.float64).reshape(SIZE, SIZE, 4)
rgb = px[:, :, :3]
lum = rgb.mean(axis=2)

f = np.fft.fftfreq(SIZE)
kernel = np.exp(-2.0 * (np.pi * SIGMA) ** 2 * (f[:, None] ** 2 + f[None, :] ** 2))
low = np.real(np.fft.ifft2(np.fft.fft2(lum) * kernel))
ratio = np.clip(low / lum.mean(), 0.2, 5.0) ** STRENGTH
out = np.clip(rgb / ratio[:, :, None], 0.0, 1.0)
print("Helligkeit vorher %.3f ± %.3f (Wolken ± %.3f), nachher %.3f ± %.3f" % (
	lum.mean(), lum.std(), low.std(), out.mean(), out.mean(axis=2).std()))

res = bpy.data.images.new("wainscot_wood", SIZE, SIZE, alpha=False)
px[:, :, :3] = out
px[:, :, 3] = 1.0
res.pixels[:] = px.ravel()
res.filepath_raw = DST
res.file_format = 'PNG'
res.save()
