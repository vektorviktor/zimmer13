class_name ChessAI
extends RefCounted
## Gegner-KI für Schach (Spielkonzept 6.10): Alpha-Beta-Suche mit Ruhesuche (nur Schlagzüge),
## Bewertung aus Material und einfachen Feldboni. Rechnet in einem eigenen Thread, damit das Spiel
## nicht ruckelt: think() startet, is_done() fragt ab, take_move() holt den Zug.
##
## Spielstärke je Gast: Suchtiefe (1–3 Halbzüge) und Patzer-Chance – ein Patzer wählt zufällig
## unter den besseren Zügen statt den besten.

const VALUES := [0, 100, 320, 330, 500, 900, 0]
const MATE := 100000
const QUIESCE_DEPTH := 4          ## so viele Schlagzüge tief rechnet die Ruhesuche höchstens
## Zentrum: Abstand zur Brettmitte (0 = Mitte) – Springer und Läufer stehen dort besser
const CENTER := [0, 1, 2, 3, 3, 2, 1, 0]

var _thread: Thread
var _move := 0


## Zug für die Seite am Zug suchen (im Hintergrund).
func think(board: Chess, depth: int, blunder: float) -> void:
	_move = 0
	_thread = Thread.new()
	_thread.start(_run.bind(board.copy(), depth, blunder, randi()))


func is_done() -> bool:
	return _thread != null and not _thread.is_alive()


func take_move() -> int:
	if _thread:
		_thread.wait_to_finish()
		_thread = null
	return _move


## Laufende Suche abwarten und verwerfen (Partie abgebrochen).
func cancel() -> void:
	if _thread:
		_thread.wait_to_finish()
		_thread = null


func _run(board: Chess, depth: int, blunder: float, seed_value: int) -> void:
	_move = best_move(board, depth, blunder, seed_value)


static func best_move(board: Chess, depth: int, blunder: float, seed_value: int = 0) -> int:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var scored: Array = []
	for m in _ordered(board, board.pseudo_moves(false)):
		var c := board.copy()
		c.make_move(m)
		if c.mover_in_check():
			continue
		# etwas Rauschen, damit nicht jede Partie gleich verläuft
		var score := -_search(c, depth - 1, -MATE, MATE, 1) + rng.randi_range(-8, 8)
		scored.append([score, m])
	if scored.is_empty():
		return 0
	scored.sort_custom(func(a: Array, b: Array) -> bool: return a[0] > b[0])
	if rng.randf() < blunder and scored.size() > 1:
		# Patzer: irgendeiner der besseren Züge, aber kein Matt-Verpassen ins Leere
		var pick := rng.randi_range(1, mini(scored.size() - 1, 4))
		return scored[pick][1]
	return scored[0][1]


static func _search(board: Chess, depth: int, alpha: int, beta: int, ply: int) -> int:
	if depth <= 0:
		return _quiesce(board, alpha, beta, QUIESCE_DEPTH)
	var any := false
	for m in _ordered(board, board.pseudo_moves(false)):
		var c := board.copy()
		c.make_move(m)
		if c.mover_in_check():
			continue
		any = true
		var score := -_search(c, depth - 1, -beta, -alpha, ply + 1)
		if score >= beta:
			return beta
		alpha = maxi(alpha, score)
	if not any:
		return -MATE + ply if board.in_check() else 0
	return alpha


static func _quiesce(board: Chess, alpha: int, beta: int, left: int) -> int:
	var stand := evaluate(board)
	if stand >= beta:
		return beta
	alpha = maxi(alpha, stand)
	if left <= 0:
		return alpha
	for m in _ordered(board, board.pseudo_moves(true)):
		var c := board.copy()
		c.make_move(m)
		if c.mover_in_check():
			continue
		var score := -_quiesce(c, -beta, -alpha, left - 1)
		if score >= beta:
			return beta
		alpha = maxi(alpha, score)
	return alpha


## Schlagzüge zuerst, wertvolle Beute mit billigem Angreifer vorn (beschleunigt Alpha-Beta).
static func _ordered(board: Chess, moves: PackedInt32Array) -> Array:
	var keyed: Array = []
	for m in moves:
		var victim := absi(board.squares[Chess.move_to(m)])
		var attacker := absi(board.squares[Chess.move_from(m)])
		var key := 0
		if victim != 0:
			key = 10 * VALUES[victim] - VALUES[attacker] + 10000
		if Chess.move_promo(m) != 0:
			key += 9000
		keyed.append([key, m])
	keyed.sort_custom(func(a: Array, b: Array) -> bool: return a[0] > b[0])
	return keyed.map(func(e: Array) -> int: return e[1])


## Bewertung aus Sicht der Seite am Zug: Material, Zentrum für Leichtfiguren, vorgerückte Bauern,
## früh keine Dame im Gewühl, König in der Ecke solange noch Damen da sind.
static func evaluate(board: Chess) -> int:
	var score := 0
	var queens := 0
	for sq in 64:
		if absi(board.squares[sq]) == Chess.QUEEN:
			queens += 1
	for sq in 64:
		var p := board.squares[sq]
		if p == 0:
			continue
		var s := 1 if p > 0 else -1
		var a := absi(p)
		var f := sq & 7
		var r := sq >> 3
		var rank_own := r if s > 0 else 7 - r
		var v: int = VALUES[a]
		match a:
			Chess.PAWN:
				v += rank_own * rank_own * 2 + (6 if f in [3, 4] and rank_own >= 3 else 0)
			Chess.KNIGHT:
				v += (CENTER[f] + CENTER[r]) * 6 - (8 if rank_own == 0 else 0)
			Chess.BISHOP:
				v += (CENTER[f] + CENTER[r]) * 3 - (8 if rank_own == 0 else 0)
			Chess.ROOK:
				v += 12 if rank_own == 6 else 0
			Chess.QUEEN:
				v += (CENTER[f] + CENTER[r]) * 1
			Chess.KING:
				if queens > 0:
					v += (10 if rank_own == 0 and f in [1, 2, 6] else 0) - rank_own * 8
				else:
					v += (CENTER[f] + CENTER[r]) * 5   # im Endspiel nach vorn
		score += v * s
	return score if board.white_to_move else -score
