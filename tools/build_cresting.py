# Baut die Karten des Firstgitters (ZIM-171, Spielkonzept 7.10, Entscheidung 3.11.): ein Feld des gotischen Gitters
# aus Schmiedeeisen, FIELD_W breit und FIELD_H hoch – Spitzbogen zwischen zwei Pfosten mit Speerspitzen, Mittelstab mit
# Ring und kleiner Spitze im Scheitel, Kämpferstab, unten ein Band. Im Spiel eine ausgeschnittene Karte je Feld
# (LevelBuilder._roof_cresting); die Pfosten liegen halb auf jedem Rand, Nachbarfelder ergänzen sie.
#
# Kein Modell: Die Form ist als Linien, Bögen und Spitzen in Metern beschrieben, daraus eine Höhenkarte (Stäbe rund,
# Spitzen mit Fase) – Normal Map (OpenGL) aus ihrem Gefälle, Verschattung in Rillen und Kanten ins Farbbild gebacken.
# Farbe: dunkles Eisen mit Rostflecken, unten und an Kanten mehr Rost; Rauheit folgt dem Rost.
#
# Das Farbbild trägt Alpha und SEINE MIPMAPS SELBST, nebeneinander in einem Streifen (Stufe 0 links, jede nächste
# halb so groß daneben, oben bündig): Beim normalen Verkleinern verblassen dünne Stäbe unter die Schwelle des
# Ausstanzens und das Gitter löst sich mit dem Abstand auf. Hier hält jede Stufe den Anteil deckender Pixel von Stufe 0
# (Alpha skaliert, bis er passt). Mat.cresting setzt die Kette in Godot wieder zusammen.
#
# Aufruf aus dem Projektordner:
#   python tools/build_cresting.py
import math
import os

import numpy as np
from PIL import Image

FIELD_W = 0.4
FIELD_H = 0.5
PX_PER_M = 1280            # 512 × 640 Pixel
SUPER = 3                  # Überabtastung für weiche Kanten
THRESHOLD = 0.4            # = Mat.CRESTING_SCISSOR
OUT = "assets/textures"

W = int(round(FIELD_W * PX_PER_M))
H = int(round(FIELD_H * PX_PER_M))

POST_T = 0.02              # Pfosten (halb je Rand)
BAR_T = 0.012              # Bogen, Mittelstab
THIN_T = 0.01              # Kämpferstab, Ring
RAIL = (0.0, 0.028)        # unteres Band (von, bis)
SPRING = 0.14              # Kämpfer: hier setzen die Bögen an
ARCH_R = 0.3               # Radius der Bogenhälften (Spitzbogen)
POST_TOP = 0.42
SPEAR = (0.024, 0.08)      # Speerspitze am Pfosten: halbe Breite, Höhe
CROWN_SPEAR = (0.016, 0.055)
RING = (0.2, 0.215, 0.034)  # Mitte x, y, Radius
BEVEL = 0.007              # Fase der Spitzen

IRON = np.array([0.15, 0.15, 0.16])
RUST = np.array([0.42, 0.22, 0.12])


def grid(n_super):
    xs = (np.arange(W * n_super) + 0.5) / (W * n_super) * FIELD_W
    ys = FIELD_H - (np.arange(H * n_super) + 0.5) / (H * n_super) * FIELD_H
    return np.meshgrid(xs, ys)


def seg_dist(x, y, a, b):
    ax, ay = a
    bx, by = b
    dx, dy = bx - ax, by - ay
    t = np.clip(((x - ax) * dx + (y - ay) * dy) / (dx * dx + dy * dy), 0.0, 1.0)
    return np.hypot(x - ax - t * dx, y - ay - t * dy)


def arc_dist(x, y, c, r, a0, a1):
    ang = np.arctan2(y - c[1], x - c[0])
    inside = (ang >= min(a0, a1)) & (ang <= max(a0, a1))
    d_ring = np.abs(np.hypot(x - c[0], y - c[1]) - r)
    p0 = (c[0] + r * math.cos(a0), c[1] + r * math.sin(a0))
    p1 = (c[0] + r * math.cos(a1), c[1] + r * math.sin(a1))
    d_end = np.minimum(np.hypot(x - p0[0], y - p0[1]), np.hypot(x - p1[0], y - p1[1]))
    return np.where(inside, d_ring, d_end)


def tri_sdf(x, y, pts):
    # vorzeichenbehafteter Abstand zu einem Dreieck (negativ innen)
    d = np.full(x.shape, np.inf)
    crosses = []
    for i in range(3):
        a, b = pts[i], pts[(i + 1) % 3]
        d = np.minimum(d, seg_dist(x, y, a, b))
        crosses.append((b[0] - a[0]) * (y - a[1]) - (b[1] - a[1]) * (x - a[0]))
    inside = ((crosses[0] > 0) & (crosses[1] > 0) & (crosses[2] > 0)) \
        | ((crosses[0] < 0) & (crosses[1] < 0) & (crosses[2] < 0))
    return np.where(inside, -d, d)


def heights(x, y):
    h = np.zeros(x.shape)

    def bar(dist, t):
        nonlocal h
        r = t / 2.0
        h = np.maximum(h, np.sqrt(np.clip(1.0 - (dist / r) ** 2, 0.0, 1.0)) * r)

    def plate(sdf, top):
        nonlocal h
        h = np.maximum(h, np.where(sdf < 0, np.clip(-sdf / BEVEL, 0.0, 1.0) * top, 0.0))

    # unteres Band: flache Leiste mit gerundeten Kanten
    rail_mid = (RAIL[0] + RAIL[1]) / 2.0
    bar(np.abs(y - rail_mid) * 1.0, RAIL[1] - RAIL[0])
    # Pfosten auf beiden Rändern, mit Speerspitze
    for px in (0.0, FIELD_W):
        bar(seg_dist(x, y, (px, 0.0), (px, POST_TOP)), POST_T)
        hw, sh = SPEAR
        plate(tri_sdf(x, y, [(px - hw, POST_TOP - 0.004), (px + hw, POST_TOP - 0.004), (px, POST_TOP + sh)]),
              POST_T / 2.0)
    # Kämpferstab
    bar(seg_dist(x, y, (0.0, SPRING), (FIELD_W, SPRING)), THIN_T)
    # Spitzbogen: zwei Bogenhälften, Mitte jeweils auf der Gegenseite
    mid = FIELD_W / 2.0
    apex = SPRING + math.sqrt(ARCH_R ** 2 - (ARCH_R - mid) ** 2)
    left_c = (ARCH_R, SPRING)
    right_c = (FIELD_W - ARCH_R, SPRING)
    bar(arc_dist(x, y, left_c, ARCH_R, math.pi, math.atan2(apex - SPRING, mid - ARCH_R)), BAR_T)
    bar(arc_dist(x, y, right_c, ARCH_R, 0.0, math.atan2(apex - SPRING, mid - (FIELD_W - ARCH_R))), BAR_T)
    # Mittelstab bis in den Scheitel, Ring, kleine Spitze
    bar(seg_dist(x, y, (mid, RAIL[1]), (mid, apex)), BAR_T)
    rx, ry, rr = RING
    bar(np.abs(np.hypot(x - rx, y - ry) - rr), THIN_T)
    hw, sh = CROWN_SPEAR
    plate(tri_sdf(x, y, [(mid - hw, apex - 0.006), (mid + hw, apex - 0.006), (mid, apex + sh)]), BAR_T / 2.0)
    return h


def value_noise(shape, cells, seed):
    rng = np.random.default_rng(seed)
    g = rng.random((cells[1] + 1, cells[0] + 1))
    ys = np.linspace(0, cells[1], shape[0], endpoint=False)
    xs = np.linspace(0, cells[0], shape[1], endpoint=False)
    xi, yi = np.meshgrid(xs, ys)
    x0, y0 = xi.astype(int), yi.astype(int)
    fx, fy = xi - x0, yi - y0
    fx, fy = fx * fx * (3 - 2 * fx), fy * fy * (3 - 2 * fy)
    a = g[y0, x0] * (1 - fx) + g[y0, x0 + 1] * fx
    b = g[y0 + 1, x0] * (1 - fx) + g[y0 + 1, x0 + 1] * fx
    return a * (1 - fy) + b * fy


def main():
    # Höhe und Deckung überabgetastet, dann auf Pixel gemittelt
    xs, ys = grid(SUPER)
    hs = heights(xs, ys)
    cover = (hs > 0).astype(float).reshape(H, SUPER, W, SUPER).mean(axis=(1, 3))
    h = hs.reshape(H, SUPER, W, SUPER).max(axis=(1, 3))

    # Normal Map (OpenGL: Grün zeigt nach oben im Bild)
    px = 1.0 / PX_PER_M
    gy, gx = np.gradient(h, px)          # gy: entlang der Zeilen (nach unten im Bild)
    n = np.dstack([-gx, gy, np.ones_like(h)])
    n /= np.linalg.norm(n, axis=2, keepdims=True)
    normal = ((n * 0.5 + 0.5) * 255).round().astype(np.uint8)

    # Rost: Flecken, nach unten und an den Kanten mehr
    noise = 0.6 * value_noise(h.shape, (6, 8), 3) + 0.3 * value_noise(h.shape, (24, 30), 5) \
        + 0.1 * value_noise(h.shape, (80, 100), 7)
    yy = np.linspace(1.0, 0.0, H)[:, None]
    edge = 1.0 - np.clip(h / (BAR_T / 2.0), 0.0, 1.0)
    rust = np.clip((noise - 0.45) * 2.2 + (1.0 - yy) * 0.35 + edge * 0.25, 0.0, 1.0) * 0.5
    shade = 0.55 + 0.45 * np.clip(h / (BAR_T / 2.0), 0.0, 1.0)   # Verschattung zu den Rändern
    color = (IRON[None, None, :] * (1 - rust[..., None]) + RUST[None, None, :] * rust[..., None]) * shade[..., None]
    rough = np.clip(0.5 + rust * 0.45 + (noise - 0.5) * 0.1, 0.0, 1.0)

    rgba0 = np.dstack([np.clip(color, 0, 1), cover])
    os.makedirs(OUT, exist_ok=True)
    Image.fromarray(normal, "RGB").save(os.path.join(OUT, "cresting_normal.png"))
    Image.fromarray((rough * 255).round().astype(np.uint8), "L").save(os.path.join(OUT, "cresting_rough.png"))

    # Mipmap-Streifen mit gleicher Deckung je Stufe
    target = float((cover > THRESHOLD).mean())
    levels = []
    w, hh = W, H
    premul = rgba0.copy()
    premul[..., :3] *= premul[..., 3:4]
    while True:
        if (w, hh) == (W, H):
            lvl = rgba0
        else:
            chans = []
            for c in range(4):
                ch = Image.fromarray((premul[..., c] * 255).astype(np.float32), "F").resize((w, hh), Image.BOX)
                chans.append(np.asarray(ch) / 255.0)
            lvl = np.dstack(chans)
            a = lvl[..., 3].copy()
            rgb = np.where(a[..., None] > 1e-4, lvl[..., :3] / np.maximum(a[..., None], 1e-4), IRON[None, None, :] * 0.6)
            lo, hi = 1.0, 64.0
            for _ in range(30):
                s = (lo + hi) / 2.0
                if float((np.clip(a * s, 0, 1) > THRESHOLD).mean()) < target:
                    lo = s
                else:
                    hi = s
            a = np.clip(a * hi, 0.0, 1.0)
            lvl = np.dstack([rgb, a])
        levels.append(lvl)
        if w == 1 and hh == 1:
            break
        w, hh = max(1, w // 2), max(1, hh // 2)
    strip_w = sum(l.shape[1] for l in levels)
    strip = np.zeros((H, strip_w, 4))
    x = 0
    for l in levels:
        strip[: l.shape[0], x: x + l.shape[1]] = l
        x += l.shape[1]
    # Farbe hinter durchsichtigen Pixeln: Eisen (kein heller Saum beim Filtern)
    clear = strip[..., 3] < 1e-4
    strip[clear, :3] = IRON * 0.6
    Image.fromarray((np.clip(strip, 0, 1) * 255).round().astype(np.uint8), "RGBA").save(
        os.path.join(OUT, "cresting_albedo.png"))
    print("Feld %d × %d px, %d Mipmap-Stufen, Deckung %.3f, Streifen %d × %d" % (W, H, len(levels), target, strip_w, H))


if __name__ == "__main__":
    main()
