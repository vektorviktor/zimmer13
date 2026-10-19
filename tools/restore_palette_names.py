# Schreibt die Palettennamen (Legende des Gebäudeplans, Spielkonzept 7.5) aus einer früheren Fassung
# von map.aseprite zurück in die aktuelle Datei.
#
# Aseprite speichert die Palette nur dann im Chunk 0x2019 mit Namen, wenn die Palette im Speicher Namen
# hat – sonst im alten Chunk 0x0004 ohne Namen. Gehen die Namen beim Bearbeiten verloren, fällt das erst
# beim nächsten Speichern auf (build_map.py bricht mit „Die Palette hat keine Farbnamen“ ab).
#
# Zuordnung je Farbe: gleicher Index und gleiche Farbe, sonst dieselbe Farbe an anderer Stelle (eindeutig).
# Farben ohne Gegenstück bleiben ohne Namen und werden gemeldet. Aseprite dabei geschlossen halten.
#
# Aufruf (Python 3, keine Zusatzpakete, im Projektordner):
#   python tools/restore_palette_names.py [map.aseprite] [git-stand, Standard HEAD]
import struct, subprocess, sys

SRC = sys.argv[1] if len(sys.argv) > 1 else "map.aseprite"
REF = sys.argv[2] if len(sys.argv) > 2 else "HEAD"


def frame0_chunks(data):
	"""Chunks des ersten Frames als Liste (Typ, Bytes) und Lage des Frame-Kopfs."""
	size, magic, old = struct.unpack_from("<IHH", data, 128)
	assert magic == 0xF1FA, "kein Aseprite-Frame"
	new = struct.unpack_from("<I", data, 140)[0]
	chunks, p = [], 144
	for _ in range(new or old):
		csize, ctype = struct.unpack_from("<IH", data, p)
		chunks.append((ctype, data[p:p + csize]))
		p += csize
	return chunks, size


def palette(chunks):
	"""Index → [r, g, b, a, Name] aus Chunk 0x2019, sonst aus dem alten Chunk 0x0004 (ohne Namen)."""
	for ctype, c in chunks:
		if ctype == 0x2019:
			first, last = struct.unpack_from("<II", c, 10)
			q, out = 26, {}
			for i in range(first, last + 1):
				flags, r, g, b, a = struct.unpack_from("<HBBBB", c, q)
				q += 6
				name = ""
				if flags & 1:
					n = struct.unpack_from("<H", c, q)[0]
					name = c[q + 2:q + 2 + n].decode()
					q += 2 + n
				out[i] = [r, g, b, a, name]
			return out
	for ctype, c in chunks:
		if ctype == 0x0004:
			packets = struct.unpack_from("<H", c, 6)[0]
			q, i, out = 8, 0, {}
			for _ in range(packets):
				skip, count = c[q], c[q + 1] or 256
				q += 2
				i += skip
				for _ in range(count):
					out[i] = [c[q], c[q + 1], c[q + 2], 255, ""]
					q += 3
					i += 1
			return out
	return {}


data = open(SRC, "rb").read()
chunks, frame_size = frame0_chunks(data)
pal = palette(chunks)
ref = palette(frame0_chunks(subprocess.run(["git", "show", "%s:%s" % (REF, SRC)], capture_output=True,
	check=True).stdout)[0])
by_color = {}
for i, (r, g, b, a, name) in ref.items():
	if name:
		by_color.setdefault((r, g, b, a), []).append(name)

restored, missing = 0, []
for i, e in pal.items():
	if e[4]:
		continue
	old = ref.get(i)
	if old and old[:4] == e[:4] and old[4]:
		e[4] = old[4]
	elif len(by_color.get(tuple(e[:4]), [])) == 1:
		e[4] = by_color[tuple(e[:4])][0]
	else:
		missing.append(i)
		continue
	restored += 1

# Neuer Paletten-Chunk anstelle der alten Paletten-Chunks
first, last = min(pal), max(pal)
body = struct.pack("<III8x", len(pal), first, last)
for i in range(first, last + 1):
	r, g, b, a, name = pal.get(i, [0, 0, 0, 255, ""])
	body += struct.pack("<HBBBB", 1 if name else 0, r, g, b, a)
	if name:
		raw = name.encode()
		body += struct.pack("<H", len(raw)) + raw
chunk = struct.pack("<IH", 6 + len(body), 0x2019) + body
at = next(k for k, (t, _) in enumerate(chunks) if t in (0x0004, 0x2019))
chunks = [c for c in chunks if c[0] not in (0x0004, 0x2019)]
chunks.insert(at, (0x2019, chunk))

frame_body = b"".join(c for _, c in chunks)
head = bytearray(data[128:144])
struct.pack_into("<I", head, 0, 16 + len(frame_body))
struct.pack_into("<H", head, 6, min(len(chunks), 0xFFFF))
struct.pack_into("<I", head, 12, len(chunks))
out = bytearray(data[:128]) + head + frame_body + data[128 + frame_size:]
struct.pack_into("<I", out, 0, len(out))
open(SRC, "wb").write(out)
print("%s: %d Namen aus %s zurückgeschrieben, %d Farben haben jetzt einen Namen%s" % (SRC, restored, REF,
	sum(1 for e in pal.values() if e[4]), ", ohne Gegenstück: %s" % missing if missing else ""))
