class_name Chess
extends RefCounted
## Schachregeln (Spielkonzept 6.10): Stellung, erlaubte Züge, Spielende. Reine Daten ohne Knoten –
## die Gegner-KI (ChessAI) rechnet damit in einem Hintergrund-Thread.
##
## Felder 0…63 = Reihe * 8 + Linie (a1 = 0, h1 = 7, a8 = 56). Figuren als Zahl: positiv = Weiß,
## negativ = Schwarz. Ein Zug ist eine Zahl: von | nach << 6 | Umwandlung << 12 | Kennzeichen.

enum { EMPTY, PAWN, KNIGHT, BISHOP, ROOK, QUEEN, KING }
enum Status { PLAYING, CHECKMATE, STALEMATE, FIFTY_MOVES, REPETITION, NO_MATERIAL }

const FLAG_EP := 1 << 16
const FLAG_CASTLE := 1 << 17
const FLAG_DOUBLE := 1 << 18
const MOVE_BITS := (1 << 19) - 1

const CASTLE_WK := 1
const CASTLE_WQ := 2
const CASTLE_BK := 4
const CASTLE_BQ := 8

const BACK_RANK := [ROOK, KNIGHT, BISHOP, QUEEN, KING, BISHOP, KNIGHT, ROOK]
## Deutsche Figurenbuchstaben für die Zugnotation (Springer, Läufer, Turm, Dame, König)
const LETTERS := ["", "", "S", "L", "T", "D", "K"]
const NAMES := ["", "Bauer", "Springer", "Läufer", "Turm", "Dame", "König"]
const FEN_LETTERS := "pnbrqk"

## Zielfelder je Feld (Springer, König) und Strahlen je Richtung: 0–3 gerade, 4–7 schräg
static var KNIGHT_TO: Array[PackedInt32Array] = []
static var KING_TO: Array[PackedInt32Array] = []
static var RAYS: Array = []
## Rochaderechte, die übrig bleiben, wenn ein Zug dieses Feld berührt
static var CASTLE_KEEP := PackedInt32Array()

var squares := PackedInt32Array()
var white_to_move := true
var castling := 15
var ep := -1                 ## Feld, auf dem en passant geschlagen werden kann
var halfmove := 0            ## Züge seit dem letzten Bauernzug oder Schlagen (50-Züge-Regel)
var fullmove := 1
var history: Array[String] = []   ## Stellungen der Partie (dreifache Wiederholung)


static func _static_init() -> void:
	var knight := [[1, 2], [2, 1], [2, -1], [1, -2], [-1, -2], [-2, -1], [-2, 1], [-1, 2]]
	var king := [[1, 0], [1, 1], [0, 1], [-1, 1], [-1, 0], [-1, -1], [0, -1], [1, -1]]
	var dirs := [[1, 0], [-1, 0], [0, 1], [0, -1], [1, 1], [1, -1], [-1, 1], [-1, -1]]
	for d in 8:
		RAYS.append([])
	for sq in 64:
		var f := sq & 7
		var r := sq >> 3
		KNIGHT_TO.append(_steps(f, r, knight))
		KING_TO.append(_steps(f, r, king))
		for d in 8:
			var ray := PackedInt32Array()
			var x: int = f + dirs[d][0]
			var y: int = r + dirs[d][1]
			while x >= 0 and x < 8 and y >= 0 and y < 8:
				ray.append(y * 8 + x)
				x += dirs[d][0]
				y += dirs[d][1]
			RAYS[d].append(ray)
	CASTLE_KEEP.resize(64)
	CASTLE_KEEP.fill(15)
	CASTLE_KEEP[0] = 15 & ~CASTLE_WQ
	CASTLE_KEEP[7] = 15 & ~CASTLE_WK
	CASTLE_KEEP[4] = 15 & ~(CASTLE_WK | CASTLE_WQ)
	CASTLE_KEEP[56] = 15 & ~CASTLE_BQ
	CASTLE_KEEP[63] = 15 & ~CASTLE_BK
	CASTLE_KEEP[60] = 15 & ~(CASTLE_BK | CASTLE_BQ)


static func _steps(f: int, r: int, offsets: Array) -> PackedInt32Array:
	var out := PackedInt32Array()
	for o in offsets:
		var x: int = f + o[0]
		var y: int = r + o[1]
		if x >= 0 and x < 8 and y >= 0 and y < 8:
			out.append(y * 8 + x)
	return out


# --- Stellung ------------------------------------------------------------------------

func setup_start() -> void:
	squares.resize(64)
	squares.fill(EMPTY)
	for f in 8:
		squares[f] = BACK_RANK[f]
		squares[8 + f] = PAWN
		squares[48 + f] = -PAWN
		squares[56 + f] = -BACK_RANK[f]
	white_to_move = true
	castling = 15
	ep = -1
	halfmove = 0
	fullmove = 1
	history = [position_key()]


## Stellung aus FEN (für Tests)
func load_fen(fen: String) -> void:
	var parts := fen.split(" ")
	squares.resize(64)
	squares.fill(EMPTY)
	var r := 7
	var f := 0
	for c in parts[0]:
		if c == "/":
			r -= 1
			f = 0
		elif c.is_valid_int():
			f += c.to_int()
		else:
			var kind := FEN_LETTERS.find(c.to_lower()) + 1
			squares[r * 8 + f] = kind if c == c.to_upper() else -kind
			f += 1
	white_to_move = parts[1] == "w"
	castling = 0
	for c in parts[2]:
		castling |= {"K": CASTLE_WK, "Q": CASTLE_WQ, "k": CASTLE_BK, "q": CASTLE_BQ}.get(c, 0)
	ep = -1 if parts[3] == "-" else square_index(parts[3])
	halfmove = parts[4].to_int() if parts.size() > 4 else 0
	fullmove = parts[5].to_int() if parts.size() > 5 else 1
	history = [position_key()]


func copy() -> Chess:
	var c := Chess.new()
	c.squares = squares.duplicate()
	c.white_to_move = white_to_move
	c.castling = castling
	c.ep = ep
	c.halfmove = halfmove
	c.fullmove = fullmove
	return c


func position_key() -> String:
	return "%s|%s|%d|%d" % [str(squares), white_to_move, castling, ep]


func king_square(white: bool) -> int:
	return squares.find(KING if white else -KING)


func in_check() -> bool:
	return is_attacked(king_square(white_to_move), not white_to_move)


## Steht nach make_move() der König der Seite, die gerade gezogen hat, im Schach? (= Zug unerlaubt)
func mover_in_check() -> bool:
	return is_attacked(king_square(not white_to_move), white_to_move)


func is_attacked(sq: int, by_white: bool) -> bool:
	if sq < 0:
		return false
	var s := 1 if by_white else -1
	for t in KNIGHT_TO[sq]:
		if squares[t] == s * KNIGHT:
			return true
	for t in KING_TO[sq]:
		if squares[t] == s * KING:
			return true
	# Ein angreifender Bauer steht eine Reihe weiter hinten (aus seiner Sicht) daneben
	var f := sq & 7
	var pr := (sq >> 3) - s
	if pr >= 0 and pr < 8:
		if f > 0 and squares[pr * 8 + f - 1] == s * PAWN:
			return true
		if f < 7 and squares[pr * 8 + f + 1] == s * PAWN:
			return true
	for d in 8:
		for t in RAYS[d][sq]:
			var p := squares[t]
			if p != 0:
				if (p > 0) == by_white:
					var a := absi(p)
					if a == QUEEN or (d < 4 and a == ROOK) or (d >= 4 and a == BISHOP):
						return true
				break
	return false


# --- Züge ----------------------------------------------------------------------------

static func move_from(m: int) -> int:
	return m & 63


static func move_to(m: int) -> int:
	return (m >> 6) & 63


static func move_promo(m: int) -> int:
	return (m >> 12) & 7


func legal_moves() -> PackedInt32Array:
	var out := PackedInt32Array()
	for m in pseudo_moves(false):
		var c := copy()
		c.make_move(m)
		if not c.mover_in_check():
			out.append(m)
	return out


## Züge ohne Rücksicht auf das eigene Schach (die KI prüft das selbst nach dem Ziehen).
func pseudo_moves(captures_only: bool) -> PackedInt32Array:
	var moves := PackedInt32Array()
	var s := 1 if white_to_move else -1
	for sq in 64:
		var p := squares[sq] * s
		if p <= 0:
			continue
		match p:
			PAWN:
				_pawn_moves(sq, s, moves, captures_only)
			KNIGHT:
				_step_moves(sq, KNIGHT_TO[sq], s, moves, captures_only)
			BISHOP:
				_slide_moves(sq, 4, 8, s, moves, captures_only)
			ROOK:
				_slide_moves(sq, 0, 4, s, moves, captures_only)
			QUEEN:
				_slide_moves(sq, 0, 8, s, moves, captures_only)
			KING:
				_step_moves(sq, KING_TO[sq], s, moves, captures_only)
				if not captures_only:
					_castle_moves(sq, s, moves)
	return moves


func _pawn_moves(sq: int, s: int, moves: PackedInt32Array, captures_only: bool) -> void:
	var f := sq & 7
	var fwd := sq + 8 * s
	var last := 7 if s > 0 else 0
	if not captures_only and squares[fwd] == EMPTY:
		_add_pawn(sq, fwd, last, moves)
		var start := 1 if s > 0 else 6
		if (sq >> 3) == start and squares[fwd + 8 * s] == EMPTY:
			moves.append(sq | (fwd + 8 * s) << 6 | FLAG_DOUBLE)
	for df in [-1, 1]:
		if f + df < 0 or f + df > 7:
			continue
		var t: int = fwd + df
		if squares[t] * s < 0:
			_add_pawn(sq, t, last, moves)
		elif t == ep:
			moves.append(sq | t << 6 | FLAG_EP)


func _add_pawn(sq: int, t: int, last: int, moves: PackedInt32Array) -> void:
	if (t >> 3) == last:
		for promo in [QUEEN, KNIGHT, ROOK, BISHOP]:
			moves.append(sq | t << 6 | promo << 12)
	else:
		moves.append(sq | t << 6)


func _step_moves(sq: int, targets: PackedInt32Array, s: int, moves: PackedInt32Array, captures_only: bool) -> void:
	for t in targets:
		var q := squares[t] * s
		if q > 0 or (captures_only and q == 0):
			continue
		moves.append(sq | t << 6)


func _slide_moves(sq: int, d0: int, d1: int, s: int, moves: PackedInt32Array, captures_only: bool) -> void:
	for d in range(d0, d1):
		for t in RAYS[d][sq]:
			var q := squares[t] * s
			if q > 0:
				break
			if q < 0:
				moves.append(sq | t << 6)
				break
			if not captures_only:
				moves.append(sq | t << 6)


func _castle_moves(sq: int, s: int, moves: PackedInt32Array) -> void:
	var r0 := 0 if s > 0 else 56
	if sq != r0 + 4:
		return
	var enemy_white := s < 0
	var short := CASTLE_WK if s > 0 else CASTLE_BK
	var long := CASTLE_WQ if s > 0 else CASTLE_BQ
	if (castling & short) != 0 and squares[r0 + 5] == EMPTY and squares[r0 + 6] == EMPTY and squares[r0 + 7] == s * ROOK \
			and not is_attacked(r0 + 4, enemy_white) and not is_attacked(r0 + 5, enemy_white) and not is_attacked(r0 + 6, enemy_white):
		moves.append(sq | (r0 + 6) << 6 | FLAG_CASTLE)
	if (castling & long) != 0 and squares[r0 + 3] == EMPTY and squares[r0 + 2] == EMPTY and squares[r0 + 1] == EMPTY and squares[r0] == s * ROOK \
			and not is_attacked(r0 + 4, enemy_white) and not is_attacked(r0 + 3, enemy_white) and not is_attacked(r0 + 2, enemy_white):
		moves.append(sq | (r0 + 2) << 6 | FLAG_CASTLE)


## Zug ausführen (ohne Prüfung). Gibt die geschlagene Figur zurück (0 = keine).
func make_move(m: int) -> int:
	var from := m & 63
	var to := (m >> 6) & 63
	var promo := (m >> 12) & 7
	var p := squares[from]
	var s := 1 if p > 0 else -1
	var captured := squares[to]
	squares[to] = p if promo == 0 else promo * s
	squares[from] = EMPTY
	if m & FLAG_EP:
		squares[to - 8 * s] = EMPTY
		captured = -s * PAWN
	if m & FLAG_CASTLE:
		if (to & 7) == 6:
			squares[to - 1] = squares[to + 1]
			squares[to + 1] = EMPTY
		else:
			squares[to + 1] = squares[to - 2]
			squares[to - 2] = EMPTY
	ep = (from + to) >> 1 if (m & FLAG_DOUBLE) != 0 else -1
	castling &= CASTLE_KEEP[from] & CASTLE_KEEP[to]
	halfmove = 0 if absi(p) == PAWN or captured != EMPTY else halfmove + 1
	if not white_to_move:
		fullmove += 1
	white_to_move = not white_to_move
	return captured


## Zug in der laufenden Partie: wie make_move, merkt sich aber die Stellung (Wiederholung).
func play(m: int) -> int:
	var captured := make_move(m)
	history.append(position_key())
	return captured


func status() -> Status:
	if legal_moves().is_empty():
		return Status.CHECKMATE if in_check() else Status.STALEMATE
	if halfmove >= 100:
		return Status.FIFTY_MOVES
	if history.count(position_key()) >= 3:
		return Status.REPETITION
	if _no_material():
		return Status.NO_MATERIAL
	return Status.PLAYING


## Nur noch Könige, oder König gegen König mit einem Springer/Läufer: niemand kann mehr gewinnen.
func _no_material() -> bool:
	var minors := 0
	for p in squares:
		var a := absi(p)
		if a == PAWN or a == ROOK or a == QUEEN:
			return false
		if a == KNIGHT or a == BISHOP:
			minors += 1
	return minors <= 1


# --- Notation ------------------------------------------------------------------------

static func square_name(sq: int) -> String:
	return "abcdefgh"[sq & 7] + str((sq >> 3) + 1)


static func square_index(text: String) -> int:
	return "abcdefgh".find(text[0]) + (text[1].to_int() - 1) * 8


## Zug in deutscher Kurznotation („Sf3“, „exd5“, „0-0“, „e8D+“). Vor dem Ziehen aufrufen.
func notation(m: int) -> String:
	var from := move_from(m)
	var to := move_to(m)
	var kind := absi(squares[from])
	var text := ""
	if m & FLAG_CASTLE:
		text = "0-0" if (to & 7) == 6 else "0-0-0"
	else:
		var capture := squares[to] != EMPTY or (m & FLAG_EP) != 0
		if kind == PAWN:
			text = ("abcdefgh"[from & 7] + "x" if capture else "") + square_name(to)
			if move_promo(m) != 0:
				text += LETTERS[move_promo(m)]
		else:
			text = LETTERS[kind] + _disambiguation(m, kind) + ("x" if capture else "") + square_name(to)
	var after := copy()
	after.make_move(m)
	if after.in_check():
		text += "#" if after.legal_moves().is_empty() else "+"
	return text


## Können zwei gleiche Figuren aufs selbe Feld? Dann Linie (oder Reihe) dazuschreiben.
func _disambiguation(m: int, kind: int) -> String:
	var from := move_from(m)
	var same_file := false
	var same_rank := false
	var other := false
	for o in legal_moves():
		var of := move_from(o)
		if of != from and move_to(o) == move_to(m) and absi(squares[of]) == kind:
			other = true
			same_file = same_file or (of & 7) == (from & 7)
			same_rank = same_rank or (of >> 3) == (from >> 3)
	if not other:
		return ""
	if not same_file:
		return "abcdefgh"[from & 7]
	if not same_rank:
		return str((from >> 3) + 1)
	return square_name(from)


# --- Test ----------------------------------------------------------------------------

## Anzahl der Stellungen nach depth Halbzügen – zum Prüfen der Zuggenerierung gegen bekannte Werte.
func perft(depth: int) -> int:
	if depth == 0:
		return 1
	var total := 0
	for m in pseudo_moves(false):
		var c := copy()
		c.make_move(m)
		if not c.mover_in_check():
			total += c.perft(depth - 1)
	return total
