"""Platzhalter-Klang für den Vorspann (Spielkonzept 8.2): eine Welle rauscht an, bricht und läuft schäumend aus.

Rauschen in reinem Python (ohne numpy), Stereo, 44,1 kHz, 16 Bit, ca. 4 s:
  0,0–1,7 s  Anrauschen: lauter, heller (Tiefpass öffnet sich), tiefes Grollen wächst
  1,7–2,0 s  Brechen: breitbandiger Schlag mit dumpfem Wumms
  2,0–4,0 s  Auslaufen: Gischt wird leiser und dumpfer, dazu knisternder Schaum

Aufruf: python tools/build_wave_sound.py [ausgabe.wav]   (Standard assets/sound/splash_wave.wav)
"""
import math
import random
import struct
import sys
import wave

RATE = 44100
LENGTH = 4.0
APPROACH = 1.7      # Sekunde, in der die Welle bricht
CRASH = 0.3         # Dauer des Schlags
PEAK_DB = -3.0      # Spitzenpegel nach dem Normalisieren
SEED = 13


def smoothstep(a: float, b: float, x: float) -> float:
    t = min(1.0, max(0.0, (x - a) / (b - a)))
    return t * t * (3.0 - 2.0 * t)


def lowpass_coeff(cutoff: float) -> float:
    """Koeffizient eines einpoligen Tiefpasses für die Grenzfrequenz in Hz."""
    return 1.0 - math.exp(-2.0 * math.pi * cutoff / RATE)


def envelope(t: float) -> tuple[float, float, float]:
    """Lautstärke, Grenzfrequenz (Hz) und Anteil Grollen zur Zeit t."""
    if t < APPROACH:
        k = t / APPROACH
        amp = 0.15 + 0.5 * k ** 2.0
        cutoff = 250.0 + 2600.0 * k ** 1.6
        rumble = 0.3 + 0.7 * k
    elif t < APPROACH + CRASH:
        k = (t - APPROACH) / CRASH
        amp = 0.65 + 0.35 * math.sin(k * math.pi) + 0.2 * (1.0 - k)
        cutoff = 2850.0 + 6000.0 * math.sin(min(1.0, k * 2.0) * math.pi / 2.0)
        rumble = 1.0
    else:
        k = (t - APPROACH - CRASH) / (LENGTH - APPROACH - CRASH)
        amp = 0.8 * math.exp(-2.6 * k) * (1.0 - smoothstep(0.75, 1.0, k))
        cutoff = 1300.0 + 6500.0 * math.exp(-3.0 * k)
        rumble = math.exp(-4.0 * k)
    # langsames Wogen, damit es nicht wie gleichmäßiges Rauschen klingt
    amp *= 1.0 + 0.12 * math.sin(t * 5.3) + 0.06 * math.sin(t * 11.7 + 1.0)
    return amp, cutoff, rumble


def build() -> list[tuple[float, float]]:
    rnd = random.Random(SEED)
    n = int(RATE * LENGTH)
    out: list[tuple[float, float]] = []
    lp = [0.0, 0.0]          # Tiefpass je Kanal (zweistufig: lp, lp2)
    lp2 = [0.0, 0.0]
    brown = 0.0              # Grollen: gemeinsames Braunes Rauschen
    foam_env = 0.0           # Hüllkurve des aktuellen Schaumknisterns
    foam_hp = [0.0, 0.0]
    for i in range(n):
        t = i / RATE
        amp, cutoff, rumble = envelope(t)
        a = lowpass_coeff(cutoff)
        common = rnd.uniform(-1.0, 1.0)
        brown = 0.995 * brown + 0.02 * rnd.uniform(-1.0, 1.0)
        # Wumms beim Brechen: tiefer, rasch abklingender Ton
        thump = 0.0
        if t >= APPROACH:
            d = t - APPROACH
            thump = math.sin(2.0 * math.pi * (55.0 * d - 8.0 * d * d)) * math.exp(-d * 9.0) * 0.9
        # Schaum: zufällige kurze Knister-Impulse, nach dem Brechen dicht, dann seltener
        foam = 0.0
        if t > APPROACH + 0.1:
            density = 0.004 * math.exp(-1.2 * (t - APPROACH))
            if rnd.random() < density:
                foam_env = rnd.uniform(0.3, 1.0)
            foam_env *= 0.993
        frame = []
        for ch in range(2):
            x = 0.7 * common + 0.3 * rnd.uniform(-1.0, 1.0)   # leicht verschieden je Kanal → Breite
            lp[ch] += a * (x - lp[ch])
            lp2[ch] += a * (lp[ch] - lp2[ch])
            hiss = lp2[ch] * (1.0 + 2.0 * (1.0 - a))   # dumpfes Rauschen nicht zu leise
            if foam_env > 0.01:
                y = rnd.uniform(-1.0, 1.0)
                foam_hp[ch] = y - foam_hp[ch] * 0.5
                foam = foam_hp[ch] * foam_env * 0.25
            frame.append(amp * (hiss + rumble * brown * 3.0) + thump + foam)
        out.append((frame[0], frame[1]))
    # weiche Ränder und Normalisieren
    fade = int(RATE * 0.02)
    for i in range(fade):
        g = i / fade
        out[i] = (out[i][0] * g, out[i][1] * g)
    peak = max(max(abs(l), abs(r)) for l, r in out)
    gain = 10.0 ** (PEAK_DB / 20.0) / peak
    return [(l * gain, r * gain) for l, r in out]


def save(path: str, frames: list[tuple[float, float]]) -> None:
    with wave.open(path, "wb") as w:
        w.setnchannels(2)
        w.setsampwidth(2)
        w.setframerate(RATE)
        data = bytearray()
        for l, r in frames:
            data += struct.pack("<hh", int(max(-1.0, min(1.0, l)) * 32767), int(max(-1.0, min(1.0, r)) * 32767))
        w.writeframes(bytes(data))


if __name__ == "__main__":
    target = sys.argv[1] if len(sys.argv) > 1 else "assets/sound/splash_wave.wav"
    save(target, build())
    print("geschrieben:", target)
