class_name RegisterView
extends Control
## Eine Doppelseite des Hotelregisters (Spielkonzept 2.3, HotelRegister) im Menü: vergilbtes Papier mit Linien, links
## die Zimmernummer, daneben der Name. Kreuze hinter Namen zeichnet sie mit zwei Strichen wie das Notizbuch
## (NotebookPage), je Jahr eine Kopfzeile „Oktober 1988“. paginate() verteilt die Jahre auf Seiten.

const SIZE := Vector2(440, 212)
const PAGE_W := 220.0
const MARGIN := 9.0
const ROOM_W := 24.0          ## Spalte der Zimmernummer
const TOP := 8.0
const LINE_H := 13.0
const ROWS := 15              ## Zeilen je Seite
const NAME_PX := 9
const ROOM_PX := 8
const HEAD_PX := 10

const PAPER := Color(0.86, 0.81, 0.68)
const PAPER_RIGHT := Color(0.84, 0.79, 0.66)
const RULE := Color(0.45, 0.38, 0.3, 0.22)
const COLUMN := Color(0.62, 0.22, 0.18, 0.35)
const INK := Color(0.16, 0.11, 0.09)
const OLD_INK := Color(0.42, 0.34, 0.27)
const HEAD_INK := Color(0.45, 0.12, 0.09)

var left: Dictionary = {}
var right: Dictionary = {}


func setup(p_left: Dictionary, p_right: Dictionary) -> RegisterView:
	left = p_left
	right = p_right
	custom_minimum_size = SIZE
	return self


## Neue Zeile: Zimmer, Text; crosses: Kreuz hinter so vielen Zeichen, guests: [Gast-ID, Name, Zimmer] je Kreuz.
static func row(room: String, t: String) -> Dictionary:
	return {"room": room, "t": t, "crosses": [], "ink": INK, "guests": [], "head": false}


## Blöcke {year, rows} auf Seiten {title, year, rows}: je Jahr eine Kopfzeile, ein Jahr bricht nur um, wenn es allein
## nicht auf eine Seite passt (dann mit „Forts.“ in der Kopfzeile der nächsten).
static func paginate(blocks: Array) -> Array:
	var pages: Array = []
	var current: Array = []
	var first_year := 0
	for b: Dictionary in blocks:
		var year := int(b["year"])
		var rows: Array = b["rows"]
		var need := rows.size() + 1 + (0 if current.is_empty() else 1)
		if not current.is_empty() and current.size() + need > ROWS:
			pages.append({"title": "", "year": first_year, "rows": current})
			current = []
		if current.is_empty():
			first_year = year
		else:
			current.append(_blank())
		current.append(_head("Oktober %d" % year))
		for r: Dictionary in rows:
			if current.size() >= ROWS:
				pages.append({"title": "", "year": first_year, "rows": current})
				current = [_head("Oktober %d (Forts.)" % year)]
				first_year = year
			current.append(r)
	if not current.is_empty() or pages.is_empty():
		pages.append({"title": "", "year": first_year, "rows": current})
	return pages


static func _head(t: String) -> Dictionary:
	var r := row("", t)
	r["head"] = true
	r["ink"] = HEAD_INK
	return r


static func _blank() -> Dictionary:
	return row("", "")


func _draw() -> void:
	var font := get_theme_font("font", "Label")
	draw_rect(Rect2(Vector2(-3, -3), SIZE + Vector2(6, 6)), Color(0.25, 0.08, 0.06))   # Einband
	_draw_page(font, left, 0.0, PAPER)
	_draw_page(font, right, PAGE_W, PAPER_RIGHT)
	for i in 4:   # Falz in der Mitte
		draw_line(Vector2(PAGE_W - 2.0 + i, 0), Vector2(PAGE_W - 2.0 + i, SIZE.y), Color(0, 0, 0, 0.16 - i * 0.035), 1.0)


func _draw_page(font: Font, page: Dictionary, x0: float, paper: Color) -> void:
	draw_rect(Rect2(Vector2(x0, 0), Vector2(PAGE_W, SIZE.y)), paper)
	for i in ROWS:
		var y := TOP + LINE_H * (i + 1) + 2.0
		draw_line(Vector2(x0 + 4.0, y), Vector2(x0 + PAGE_W - 4.0, y), RULE, 1.0)
	draw_line(Vector2(x0 + MARGIN + ROOM_W - 4.0, TOP + 4.0), Vector2(x0 + MARGIN + ROOM_W - 4.0, SIZE.y - 4.0), COLUMN, 1.0)
	var rows: Array = page.get("rows", [])
	for i in rows.size():
		var r: Dictionary = rows[i]
		var y := TOP + LINE_H * (i + 1)
		var ink: Color = r["ink"]
		var t := String(r["t"])
		if r["head"]:
			draw_string(font, Vector2(x0 + MARGIN, y), t, HORIZONTAL_ALIGNMENT_LEFT, -1, HEAD_PX, ink)
			continue
		draw_string(font, Vector2(x0 + MARGIN, y), String(r["room"]), HORIZONTAL_ALIGNMENT_LEFT, -1, ROOM_PX, ink)
		var x := x0 + MARGIN + ROOM_W
		var px := NAME_PX
		while px > 6 and font.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, px).x > PAGE_W - MARGIN - ROOM_W - 6.0:
			px -= 1   # lange Zeile: enger schreiben
		draw_string(font, Vector2(x, y), t, HORIZONTAL_ALIGNMENT_LEFT, -1, px, ink)
		for c: int in r["crosses"]:   # Kreuz hinter dem Namen, wie im Notizbuch
			var cx := x + font.get_string_size(t.substr(0, c), HORIZONTAL_ALIGNMENT_LEFT, -1, px).x + 5.0
			var top := y - px * 0.85
			draw_line(Vector2(cx, top), Vector2(cx, y + 1.0), ink, 1.0)
			draw_line(Vector2(cx - 2.5, top + 2.5), Vector2(cx + 2.5, top + 2.5), ink, 1.0)
