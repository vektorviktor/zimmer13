# Baut die Schilderschrift assets/fonts/cinzel_bold.ttf aus Cinzel als Variable Font (google/fonts,
# ofl/cinzel/Cinzel[wght].ttf, SIL Open Font License 1.1 – Text in assets/fonts/OFL.txt).
#
# Der Variable Font lässt überlappende Konturen stehen (die 8 aus zwei Schleifen, bei Bold berühren sich die
# Serifen von A, K, V, W, Y). Godots TextMesh kann solche Glyphen nicht triangulieren und lässt Teile weg –
# deshalb eine feste Instanz mit Gewicht 700, deren Überlappungen fontTools (mit skia-pathops) verschmilzt;
# danach fallen doppelte Eckpunkte weg, die das Verschmelzen hinterlässt.
#
#   pip install fonttools skia-pathops
#   python tools/build_font.py assets/source/cinzel_variable.ttf assets/fonts/cinzel_bold.ttf
import sys

from fontTools.ttLib import TTFont
from fontTools.ttLib.tables._g_l_y_f import GlyphCoordinates
from fontTools.varLib.instancer import OverlapMode, instantiateVariableFont

WEIGHT = 700


def drop_duplicates(glyf, name: str) -> int:
    """Entfernt doppelte Eckpunkte hintereinander, die das Verschmelzen hinterlässt (M, V, W, Y) – an ihnen
    scheitert die konvexe Zerlegung in TextMesh. Gibt die Zahl der entfernten Punkte zurück."""
    g = glyf[name]
    if g.isComposite() or g.numberOfContours <= 0:
        return 0
    coords, ends, flags = g.getCoordinates(glyf)
    new_coords, new_flags, new_ends = [], [], []
    start = 0
    for end in ends:
        kept = []
        for i in range(start, end + 1):
            p = (tuple(coords[i]), flags[i])
            if kept and p[0] == kept[-1][0] and p[1] & 1 and kept[-1][1] & 1:
                continue
            kept.append(p)
        while len(kept) > 1 and kept[0][0] == kept[-1][0] and kept[0][1] & 1 and kept[-1][1] & 1:
            kept.pop()
        new_coords += [p[0] for p in kept]
        new_flags += [p[1] for p in kept]
        new_ends.append(len(new_coords) - 1)
        start = end + 1
    removed = len(coords) - len(new_coords)
    if removed:
        g.coordinates = GlyphCoordinates(new_coords)
        g.flags = bytearray(new_flags)
        g.endPtsOfContours = new_ends
        g.recalcBounds(glyf)
    return removed


def main() -> None:
    src, dst = sys.argv[1], sys.argv[2]
    font = instantiateVariableFont(TTFont(src), {"wght": WEIGHT}, overlap=OverlapMode.REMOVE)
    glyf = font["glyf"]
    removed = sum(drop_duplicates(glyf, name) for name in font.getGlyphOrder())
    font.save(dst)
    print(f"{dst}: Gewicht {WEIGHT}, {len(font.getGlyphOrder())} Glyphen, {removed} doppelte Punkte entfernt")


if __name__ == "__main__":
    main()
