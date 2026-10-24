class_name NotebookPage
extends Control
## Eine Seite des Notizbuchs (Spielkonzept 3.10) – liniertes Papier mit rotem Rand, oben das Lesezeichen und die
## Seitenzahl, darunter Zeile für Zeile die Einträge. Wird einmal in einem SubViewport gerendert (PocketMap).
## paginate() verteilt die Einträge auf Seiten: ein Tageskopf je Spieltag, ein Eintrag bricht nicht über die Seite um.
##   Aufgabe: „– Text“, darunter klein Auftraggeber, Zimmer und Frist; erledigt durchgestrichen, verpasst „zu spät“,
##            Auftraggeber tot: ein Kreuz hinter seinem Namen.
##   Notiz:   klein Uhrzeit und Quelle, darunter der Text.
## Gesehen (kind „threats“, rows = [{id, at}]): je Bedrohung ein Bild wie ein eingeklebtes Foto (Porträt aus IconArt,
## dreifach, Pixel für Pixel), darunter Name, Tag und Uhrzeit, als man sie zuerst sah.
## Die Seite hat das Seitenverhältnis der Kartenblätter. In der Hand ist oben und unten ein Streifen abgeschnitten
## (TOP, BOTTOM halten Abstand), bei 480 × 270 sieht man die Seite etwa halb so groß wie die Textur.

const SIZE := Vector2i(900, 727)
const MARGIN_X := 58.0       ## roter Rand
const TEXT_X := 72.0
const RIGHT := 860.0
const INDENT := 26.0
const HEAD_Y := 118.0        ## Grundlinie der Kopfzeile
const TOP := 128.0           ## erste Linie oben
const LINE_H := 34.0
const ROWS := 14             ## Zeilen je Seite
const TEXT_PX := 23
const SMALL_PX := 19
const HEAD_PX := 27

const RULE := Color(0.5, 0.6, 0.75, 0.45)
const MARGIN_COLOR := Color(0.75, 0.3, 0.28, 0.6)
const DONE_INK := Color(0.42, 0.36, 0.3)

## Lesezeichen: Titel und Farbe (auch der Reiter am Rand, PocketMap)
const BOOKMARKS := {
	"map": {"title": "Karte", "color": Color(0.72, 0.55, 0.22)},
	"tasks": {"title": "Aufgaben", "color": Color(0.55, 0.13, 0.1)},
	"notes": {"title": "Notizen", "color": Color(0.2, 0.4, 0.3)},
	"threats": {"title": "Gesehen", "color": Color(0.22, 0.2, 0.26)},
}
## Gesehen: Bild (Porträt × PHOTO_SCALE), Rahmen ringsum, Abstand von oben, Hintergrund des Bilds und Rahmenfarbe
const PHOTO_SCALE := 3
const PHOTO_FRAME := 10.0
const PHOTO_Y := 160.0
const PHOTO_DARK := Color(0.3, 0.29, 0.33)   # hell genug, dass das dunkle Monster sich abhebt
const PHOTO_PAPER := Color(0.95, 0.93, 0.88)

var kind := "tasks"
var rows: Array = []
var page := 0
var pages := 1


func setup(p_kind: String, p_rows: Array, p_page: int, p_pages: int) -> NotebookPage:
	kind = p_kind
	rows = p_rows
	page = p_page
	pages = p_pages
	return self


func _ready() -> void:
	size = Vector2(SIZE)
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST   # die Porträts Pixel für Pixel vergrößert


## Die Seiten eines Lesezeichens: Liste von Seiten, jede eine Liste von Zeilen
## {t, x, px, c, strike, cross_after, late, day} – cross_after: Kreuz hinter so vielen Zeichen, -1 = keins.
static func paginate(p_kind: String, entries: Array) -> Array:
	var result: Array = []
	var current: Array = []
	var day := -1
	for e: Dictionary in entries:
		var block: Array = []
		var d := Calendar.day_of(float(e["at"]))
		if d != day:
			day = d
			if not current.is_empty():
				block.append(_row("", 0.0, TEXT_PX, HotelMap.INK))
			block.append(_day_row(float(e["at"])))
		block.append_array(_task_rows(e) if p_kind == "tasks" else _note_rows(e))
		if current.size() + block.size() > ROWS and not current.is_empty():
			result.append(current)
			current = []
			if String(block[0]["t"]) == "":
				block.pop_front()   # Leerzeile vor dem Tageskopf nicht oben auf der Seite
			if not block[0]["day"]:   # auf neuer Seite den Tag noch einmal nennen
				block.push_front(_day_row(float(e["at"])))
		while block.size() > ROWS:   # sehr langer Eintrag: notfalls doch umbrechen
			result.append(block.slice(0, ROWS))
			block = block.slice(ROWS)
		current.append_array(block)
	if not current.is_empty() or result.is_empty():
		result.append(current)
	return result


static func _day_row(at: float) -> Dictionary:
	var r := _row(Calendar.date_text(at), 0.0, TEXT_PX, HotelMap.INK)
	r["day"] = true
	return r


static func _task_rows(e: Dictionary) -> Array:
	var state := int(e["state"])
	var done := state == Notebook.TaskState.DONE
	var ink := DONE_INK if done else HotelMap.INK
	var out: Array = []
	var lines := _wrap("–  " + String(e["text"]), TEXT_PX, RIGHT - TEXT_X)
	for i in lines.size():
		var r := _row(lines[i] if i == 0 else lines[i].strip_edges(), 0.0 if i == 0 else INDENT, TEXT_PX, ink)
		r["strike"] = done
		out.append(r)
	var by := String(e["by"])
	var dead := bool(e["dead"]) and by != ""
	var sub := by + ("     " if dead else "")   # Platz für das Kreuz
	if String(e["room"]) != "":
		sub += (" · " if sub != "" else "") + "Zi. " + String(e["room"])
	if String(e["due"]) != "":
		sub += (" · " if sub != "" else "") + String(e["due"])
	if sub != "" or state == Notebook.TaskState.LATE:
		var r := _row(sub, INDENT, SMALL_PX, HotelMap.FADED)
		r["cross_after"] = by.length() if dead else -1
		r["late"] = state == Notebook.TaskState.LATE
		out.append(r)
	return out


static func _note_rows(e: Dictionary) -> Array:
	var head := Calendar.time_text(float(e["at"]))
	if String(e["by"]) != "":
		head += " · " + String(e["by"])
	var out: Array = [_row(head, 0.0, SMALL_PX, HotelMap.FADED)]
	for line in _wrap(String(e["text"]), TEXT_PX, RIGHT - TEXT_X - INDENT):
		out.append(_row(line, INDENT, TEXT_PX, HotelMap.INK))
	return out


static func _row(t: String, x: float, px: int, c: Color) -> Dictionary:
	return {"t": t, "x": x, "px": px, "c": c, "strike": false, "cross_after": -1, "late": false, "day": false}


## Wortweise umbrechen auf width Pixel.
static func _wrap(text: String, px: int, width: float) -> PackedStringArray:
	var font := ThemeDB.fallback_font
	var lines: PackedStringArray = []
	var line := ""
	for word in text.split(" ", false):
		var test := word if line == "" else line + " " + word
		if line != "" and font.get_string_size(test, HORIZONTAL_ALIGNMENT_LEFT, -1, px).x > width:
			lines.append(line)
			line = word
		else:
			line = test
	if line != "" or lines.is_empty():
		lines.append(line)
	return lines


func _draw() -> void:
	var font := ThemeDB.fallback_font
	draw_rect(Rect2(Vector2.ZERO, Vector2(SIZE)), HotelMap.NOTE_PAPER)
	for i in ROWS + 1:
		var y := TOP + LINE_H * i
		draw_line(Vector2(0, y), Vector2(SIZE.x, y), RULE, 2.0)
	draw_line(Vector2(MARGIN_X, 0), Vector2(MARGIN_X, SIZE.y), MARGIN_COLOR, 2.0)
	# Kopfzeile: Lesezeichen (mit seiner Farbe) und Seitenzahl
	var mark: Dictionary = BOOKMARKS[kind]
	draw_rect(Rect2(TEXT_X, HEAD_Y - 22.0, 10.0, 24.0), mark["color"])
	draw_string(font, Vector2(TEXT_X + 20.0, HEAD_Y), String(mark["title"]), HORIZONTAL_ALIGNMENT_LEFT, -1, HEAD_PX, HotelMap.INK)
	if pages > 1:   # gleich neben dem Titel – rechts oben liegt im Spiel die Geldanzeige darüber
		var after := TEXT_X + 20.0 + font.get_string_size(String(mark["title"]), HORIZONTAL_ALIGNMENT_LEFT, -1, HEAD_PX).x
		draw_string(font, Vector2(after + 18.0, HEAD_Y), "Seite %d/%d" % [page + 1, pages], HORIZONTAL_ALIGNMENT_LEFT, -1,
			SMALL_PX, HotelMap.FADED)
	if kind == "threats":
		_draw_threats(font)
		return
	if rows.is_empty():
		draw_string(font, Vector2(TEXT_X + INDENT, TOP + LINE_H * 1.0 - 9.0), "Noch nichts notiert.", HORIZONTAL_ALIGNMENT_LEFT,
			-1, TEXT_PX, HotelMap.FADED)
		return
	for i in rows.size():
		var r: Dictionary = rows[i]
		var t := String(r["t"])
		var px := int(r["px"])
		var pos := Vector2(TEXT_X + float(r["x"]), TOP + LINE_H * (i + 1) - 9.0)
		var color: Color = r["c"]
		draw_string(font, pos, t, HORIZONTAL_ALIGNMENT_LEFT, -1, px, color)
		var w := font.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, px).x
		if r["strike"]:   # mit dem Stift durchgestrichen, leicht schief
			var y := pos.y - px * 0.32
			var from := pos.x + (font.get_string_size("–  ", HORIZONTAL_ALIGNMENT_LEFT, -1, px).x if t.begins_with("–") else 0.0)
			draw_line(Vector2(from - 4.0, y + 1.5), Vector2(pos.x + w + 4.0, y - 1.5), HotelMap.INK, 2.5)
		var cross := int(r["cross_after"])
		if cross >= 0:   # Kreuz hinter dem Namen, wie im Hotelregister
			var cx := pos.x + font.get_string_size(t.substr(0, cross), HORIZONTAL_ALIGNMENT_LEFT, -1, px).x + 14.0
			var top := pos.y - px * 0.85
			draw_line(Vector2(cx, top), Vector2(cx, pos.y + 2.0), HotelMap.INK, 2.5)
			draw_line(Vector2(cx - 6.0, top + 6.0), Vector2(cx + 6.0, top + 6.0), HotelMap.INK, 2.5)
		if r["late"]:
			draw_string(font, Vector2(pos.x + w + (14.0 if t != "" else 0.0), pos.y), "zu spät", HORIZONTAL_ALIGNMENT_LEFT, -1,
				TEXT_PX, HotelMap.PEN)


## Gesehen: nebeneinander je ein Foto mit Rahmen (leicht schief eingeklebt), darunter Name, Tag und Uhrzeit.
func _draw_threats(font: Font) -> void:
	var column := (RIGHT - TEXT_X) / 3.0
	var side := float(IconArt.SIZE * PHOTO_SCALE)
	for i in rows.size():
		var r: Dictionary = rows[i]
		var id := String(r["id"])
		var cx := TEXT_X + column * (i + 0.5)
		var tilt := (-0.03 if i % 2 == 0 else 0.025)
		draw_set_transform(Vector2(cx, PHOTO_Y + side / 2.0), tilt)
		var frame := Rect2(Vector2(-side / 2.0 - PHOTO_FRAME, -side / 2.0 - PHOTO_FRAME), Vector2(side, side) + Vector2.ONE * PHOTO_FRAME * 2.0)
		draw_rect(frame.grow(2.0), Color(0, 0, 0, 0.18))   # Schatten unter dem Foto
		draw_rect(frame, PHOTO_PAPER)
		draw_rect(Rect2(Vector2(-side / 2.0, -side / 2.0), Vector2(side, side)), PHOTO_DARK)
		var tex := IconArt.threat(id)
		if tex:
			draw_texture_rect(tex, Rect2(Vector2(-side / 2.0, -side / 2.0), Vector2(side, side)), false)
		draw_set_transform(Vector2.ZERO)
		var at := float(r["at"])
		var y := PHOTO_Y + side + PHOTO_FRAME + 44.0
		for line: Array in [[IconArt.threat_name(id), HEAD_PX, HotelMap.INK], [Calendar.date_text(at), SMALL_PX, HotelMap.FADED],
				[Calendar.time_text(at), SMALL_PX, HotelMap.FADED]]:
			var text := String(line[0])
			var px := int(line[1])
			var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, px).x
			draw_string(font, Vector2(cx - w / 2.0, y), text, HORIZONTAL_ALIGNMENT_LEFT, -1, px, line[2])
			y += LINE_H
