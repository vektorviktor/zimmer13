extends SceneTree
## Prüft die Schach-Zuggenerierung gegen bekannte Perft-Werte (Spielkonzept 6.10).
## Aufruf: Godot --headless --path . -s res://tests/chess_perft.gd

const CASES := [
	["rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1", [20, 400, 8902]],
	["r3k2r/p1ppqpb1/bn2pnp1/3PN3/1p2P3/2N2Q1p/PPPBBPPP/R3K2R w KQkq - 0 1", [48, 2039]],   # „Kiwipete“
	["8/2p5/3p4/KP5r/1R3p1k/8/4P1P1/8 w - - 0 1", [14, 191, 2812]],
	["r3k2r/Pppp1ppp/1b3nbN/nP6/BBP1P3/q4N2/Pp1P2PP/R2Q1RK1 w kq - 0 1", [6, 264, 9467]],
]


func _init() -> void:
	var ok := true
	for case in CASES:
		var board := Chess.new()
		board.load_fen(case[0])
		for depth in range(1, case[1].size() + 1):
			var start := Time.get_ticks_msec()
			var got := board.perft(depth)
			var want: int = case[1][depth - 1]
			print("%s  Tiefe %d: %d (erwartet %d) %s  %d ms" % [case[0].left(20), depth, got, want, "ok" if got == want else "FALSCH", Time.get_ticks_msec() - start])
			ok = ok and got == want
	print("Perft: alles richtig" if ok else "Perft: FEHLER")
	quit(0 if ok else 1)
