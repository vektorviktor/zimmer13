class_name ChessBoardView
extends Control
## Schachbrett von oben (Spielkonzept 6.10), Weiß unten. Klick auf eine eigene Figur zeigt ihre Züge,
## Klick auf ein Zielfeld zieht (Bauern werden zur Dame). Figuren als Scheiben mit deutschem Buchstaben
## (K, D, T, L, S – Bauern ohne), damit sie in der kleinen PS1-Auflösung lesbar bleiben.

signal move_chosen(m: int)

const CELL := 22
const LIGHT := Color(0.86, 0.78, 0.6)
const DARK := Color(0.45, 0.3, 0.18)

var board: Chess
var interactive := false
var last_move := 0

var _selected := -1
var _targets: Array[int] = []   ## erlaubte Züge der ausgewählten Figur


func _ready() -> void:
	custom_minimum_size = Vector2(CELL * 8, CELL * 8)
	mouse_filter = Control.MOUSE_FILTER_STOP


func refresh() -> void:
	if not interactive:
		_selected = -1
		_targets.clear()
	queue_redraw()


## Feld unter einem Punkt (−1 = außerhalb)
func square_at(pos: Vector2) -> int:
	var f := int(pos.x / CELL)
	var r := 7 - int(pos.y / CELL)
	if pos.x < 0 or pos.y < 0 or f > 7 or r < 0:
		return -1
	return r * 8 + f


func _cell(sq: int) -> Rect2:
	return Rect2(Vector2((sq & 7) * CELL, (7 - (sq >> 3)) * CELL), Vector2(CELL, CELL))


func _gui_input(event: InputEvent) -> void:
	if not interactive or board == null:
		return
	if not (event is InputEventMouseButton and event.pressed and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT):
		return
	accept_event()
	var sq := square_at((event as InputEventMouseButton).position)
	if sq < 0:
		return
	for m in _targets:
		if Chess.move_to(m) == sq and Chess.move_promo(m) in [0, Chess.QUEEN]:
			_selected = -1
			_targets.clear()
			queue_redraw()
			move_chosen.emit(m)
			return
	var p := board.squares[sq]
	_targets.clear()
	_selected = -1
	if (p > 0) == board.white_to_move and p != 0:
		_selected = sq
		for m in board.legal_moves():
			if Chess.move_from(m) == sq:
				_targets.append(m)
	queue_redraw()


func _draw() -> void:
	if board == null:
		return
	var font := get_theme_default_font()
	var check_sq := board.king_square(board.white_to_move) if board.in_check() else -1
	for sq in 64:
		var rect := _cell(sq)
		var color := LIGHT if ((sq & 7) + (sq >> 3)) % 2 == 1 else DARK
		if last_move != 0 and sq in [Chess.move_from(last_move), Chess.move_to(last_move)]:
			color = color.lerp(Color(0.9, 0.75, 0.2), 0.35)
		if sq == _selected:
			color = color.lerp(Color(0.3, 0.7, 0.3), 0.5)
		if sq == check_sq:
			color = color.lerp(Color(0.85, 0.1, 0.1), 0.55)
		draw_rect(rect, color)
	for m in _targets:
		var center := _cell(Chess.move_to(m)).get_center()
		draw_circle(center, 3.0 if board.squares[Chess.move_to(m)] == 0 else CELL * 0.45, Color(0.15, 0.45, 0.15, 0.6))
	for sq in 64:
		var p := board.squares[sq]
		if p == 0:
			continue
		var center := _cell(sq).get_center()
		var white := p > 0
		var fill := Color(0.95, 0.93, 0.88) if white else Color(0.12, 0.1, 0.1)
		var ink := Color(0.1, 0.08, 0.08) if white else Color(0.92, 0.88, 0.8)
		var kind := absi(p)
		var radius := CELL * (0.24 if kind == Chess.PAWN else 0.38)
		draw_circle(center, radius + 1.0, ink)
		draw_circle(center, radius, fill)
		if kind != Chess.PAWN:
			draw_string(font, center + Vector2(-CELL * 0.5, 4.0), Chess.LETTERS[kind], HORIZONTAL_ALIGNMENT_CENTER, CELL, 11, ink)
	# Linien und Reihen am Rand
	for i in 8:
		draw_string(font, Vector2(i * CELL + 1, CELL * 8 - 1), "abcdefgh"[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 6, Color(0, 0, 0, 0.55))
		draw_string(font, Vector2(CELL * 8 - 5, (7 - i) * CELL + 7), str(i + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, 6, Color(0, 0, 0, 0.55))
