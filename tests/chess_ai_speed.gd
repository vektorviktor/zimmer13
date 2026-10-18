extends SceneTree
## Misst, wie lange die Schach-KI je Tiefe rechnet, und prüft, ob sie ein Matt in 1 findet
## (Spielkonzept 6.10). Aufruf: Godot --headless --path . -s res://tests/chess_ai_speed.gd


func _init() -> void:
	var ok := true
	var board := Chess.new()
	board.setup_start()
	for depth in [1, 2, 3]:
		var start := Time.get_ticks_msec()
		var m := ChessAI.best_move(board, depth, 0.0)
		print("Start, Tiefe %d: %s in %d ms" % [depth, board.notation(m), Time.get_ticks_msec() - start])
	board.load_fen("rnbqkbnr/pppp1ppp/8/4p3/2B1P3/5Q2/PPPP1PPP/RNB1K1NR w KQkq - 0 3")
	for depth in [1, 2, 3]:
		var start := Time.get_ticks_msec()
		var m := ChessAI.best_move(board, depth, 0.0)
		var text := board.notation(m)
		print("Schäfermatt, Tiefe %d: %s in %d ms" % [depth, text, Time.get_ticks_msec() - start])
		ok = ok and text == "Dxf7#"
	board.load_fen("r1bqkb1r/pppp1ppp/2n2n2/4p3/4P3/2N2N2/PPPP1PPP/R1BQKB1R w KQkq - 4 4")
	var start2 := Time.get_ticks_msec()
	print("Mittelspiel, Tiefe 3: %s in %d ms" % [board.notation(ChessAI.best_move(board, 3, 0.0)), Time.get_ticks_msec() - start2])
	print("KI: alles richtig" if ok else "KI: FEHLER")
	quit(0 if ok else 1)
