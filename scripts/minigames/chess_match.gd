class_name ChessMatch
extends CanvasLayer
## Schach am Schachtisch in der Lobby – Spieler gegen einen Gast (Spielkonzept 6.10).
##
## Du spielst Weiß und ziehst mit der Maus auf dem Brett von oben (ChessBoardView). Der Gast rechnet mit
## ChessAI in einem Hintergrund-Thread; seine Stärke (Suchtiefe, Patzer) kommt aus profile["chess"]["skill"].
## Ende: Matt, Patt, Remis (angeboten, 50 Züge, Wiederholung, zu wenig Material) oder Aufgabe.
## Einsätze liegen wie bei Mäxchen echt auf dem Tisch (TableStakes). Schach ist leise, aber man ist
## konzentriert – bei einer Vorwarnung springt der Gast auf, die Einsätze bleiben liegen.

const THINK_TIME := Vector2(1.0, 2.6)   ## so lange „überlegt“ der Gast mindestens
const DRAW_FROM_MOVE := 10              ## Remis erst ab diesem Zug
const RESIGN_BELOW := -900              ## so schlecht steht der Gast, bevor er (ohne Stolz) aufgibt
const COMMENT_CHANCE := 0.12            ## nach einem Zug sagt der Gast manchmal etwas
const GUEST_LINES := ["Hm.", "Interessant …", "Na warte.", "Das hast du nicht kommen sehen, oder?", "Hmmm …", "Mutig."]

var active := false
var guest: Guest
var table: ChessTable

var _board := Chess.new()
var _ai := ChessAI.new()
var _stakes := TableStakes.new()
var _thinking := false
var _think_left := 0.0
var _waiting_for_seat := false
var _abort_timer := -1.0
var _over := false
var _threw_game := false
var _draw_offered_at := -99
var _moves: Array[String] = []

var _title: Label
var _log: Label
var _moves_label: Label
var _view: ChessBoardView
var _options: VBoxContainer
var _buttons: Array[Button] = []


func _ready() -> void:
	layer = 15
	visible = false
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.05, 0.06, 0.92)
	style.border_color = Color(0.5, 0.35, 0.15)
	style.set_border_width_all(1)
	style.set_content_margin_all(5)
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)
	panel.anchor_left = 0.03
	panel.anchor_right = 0.97
	panel.anchor_top = 0.04
	panel.anchor_bottom = 0.96
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	panel.add_child(row)
	_view = ChessBoardView.new()
	_view.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_view.move_chosen.connect(_player_move)
	row.add_child(_view)
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 3)
	row.add_child(box)
	_title = _make_label(9, Color(0.95, 0.75, 0.4))
	_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_title)
	_log = _make_label(9, Color(0.9, 0.88, 0.85))
	_log.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_log.custom_minimum_size = Vector2(0, 40)
	box.add_child(_log)
	_moves_label = _make_label(8, Color(0.65, 0.65, 0.6))
	_moves_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_moves_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(_moves_label)
	_options = VBoxContainer.new()
	_options.add_theme_constant_override("separation", 0)
	box.add_child(_options)


# --- Spielstärke der Gäste --------------------------------------------------------------

static func chess_profile(p_guest: Guest) -> Dictionary:
	return p_guest.profile.get("chess", {"likes": false, "skill": 0.5, "pride": 0.5})


## Suchtiefe 1–3 Halbzüge
static func depth_of(p_guest: Guest) -> int:
	var skill := float(chess_profile(p_guest)["skill"])
	return 1 if skill < 0.35 else (2 if skill < 0.75 else 3)


## Patzer-Chance je Zug: schwache Spieler 45 %, starke 5 %. Unter Schock spielt jeder schlechter.
static func blunder_of(p_guest: Guest) -> float:
	var skill := float(chess_profile(p_guest)["skill"])
	return clampf(lerpf(0.45, 0.05, skill) + p_guest.fear / 300.0, 0.0, 0.8)


## Für Menüs und Zuschauer: „spielt stark“ …
static func strength_text(p_guest: Guest) -> String:
	return ["spielt schwach", "spielt ordentlich", "spielt stark"][depth_of(p_guest) - 1]


# --- Start ----------------------------------------------------------------------------

## Kann jetzt mit diesem Gast gespielt werden? Gibt einen Grund zurück oder "".
func why_not(p_guest: Guest) -> String:
	if active or table == null or (Game.dice and Game.dice.active):
		return "Gerade nicht."
	if table.busy:
		return "Am Schachtisch wird schon gespielt."
	if not table.has_board(Game.player):
		return "Das Schachbrett fehlt am Tisch."
	if p_guest.fear >= 60.0:
		return p_guest.line("panic")
	if not Game.director.is_quiet(table.global_position, 20.0):
		return "Jetzt? Hörst du das nicht?"
	if Game.director.long_signal_near(table.global_position):
		return "Jetzt? Hast du das Licht gesehen?"
	return ""


func can_stake_item(p_guest: Guest) -> bool:
	return TableStakes.can_stake_item(p_guest, Item.Kind.CHESS_BOARD)


## stake: {"money": int, "item": bool}
func start(p_guest: Guest, stake: Dictionary) -> void:
	guest = p_guest
	active = true
	_over = false
	_thinking = false
	_threw_game = false
	_abort_timer = -1.0
	_draw_offered_at = -99
	_moves.clear()
	table.busy = true
	_board = Chess.new()
	_board.setup_start()
	_view.board = _board
	_view.last_move = 0
	_view.interactive = false
	_view.refresh()
	_stakes = TableStakes.new()
	var player := Game.player
	# Brett auf den Tisch, falls du es in der Hand hast
	if player.held_kind() == Item.Kind.CHESS_BOARD:
		var board_item := player.held
		player.drop_held()
		board_item.global_position = table.top_center() + Vector3(0, 0.01, 0)
	_stakes.place(table, guest, stake)
	player.sit_at(table.player_seat.global_position, table.top_center())
	guest.sit_for_game(table.guest_seat.global_position, table.top_center())
	visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_waiting_for_seat = true
	_update_title()
	_update_moves()
	_say("%s kommt an den Tisch und stellt die Figuren auf …" % guest.display_name)
	_clear()
	_option("Doch nicht spielen", _abort.bind("Du stehst wieder auf."))
	if "--trace" in OS.get_cmdline_user_args():
		print("[Schach] gegen %s (Tiefe %d, Patzer %.0f %%)" % [guest.display_name, depth_of(guest), blunder_of(guest) * 100.0])


func _process(delta: float) -> void:
	if not active:
		return
	if _waiting_for_seat and guest.seated:
		_waiting_for_seat = false
		_say("Du spielst Weiß und fängst an. Klick auf eine Figur, dann aufs Zielfeld.")
		_player_turn()
	# Der Gast hat das Spiel verlassen (Panik, Monster gesehen, gestorben …)
	if not _over and (guest.dead or guest.state != Guest.State.MINIGAME):
		_abort("%s springt auf und rennt davon! Die Einsätze liegen noch auf dem Tisch …" % guest.display_name)
		return
	# Vorwarnung: je mutiger der Gast, desto später bemerkt er sie (wie bei Mäxchen)
	if not _over and (not Game.director.is_quiet(table.global_position, 20.0) or Game.director.long_signal_near(table.global_position)):
		if _abort_timer < 0.0:
			_abort_timer = 0.5 + float(guest.profile["brave"]) * 4.5
		_abort_timer -= delta
		if _abort_timer <= 0.0:
			guest.say_panic()
			guest.end_game()
			_abort("%s springt auf und rennt davon! Die Einsätze liegen noch auf dem Tisch …" % guest.display_name)
			return
	if _thinking:
		_think_left -= delta
		if _think_left <= 0.0 and _ai.is_done():
			_thinking = false
			_guest_move(_ai.take_move())


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		var index: int = (event as InputEventKey).keycode - KEY_1
		if index >= 0 and index < _buttons.size() and not _buttons[index].disabled:
			_buttons[index].pressed.emit()
			get_viewport().set_input_as_handled()


# --- Züge -------------------------------------------------------------------------------

func _player_turn() -> void:
	_view.interactive = true
	_view.refresh()
	_clear()
	_option("Remis anbieten", _offer_draw, _board.fullmove < DRAW_FROM_MOVE or _board.fullmove - _draw_offered_at < 5)
	_option("Aufgeben", _resign)
	_option("Absichtlich verlieren", _throw_game)


func _player_move(m: int) -> void:
	if _over or not _board.white_to_move:
		return
	_view.interactive = false
	_record(m)
	if _check_end():
		return
	_guest_turn()


func _guest_turn() -> void:
	_clear()
	_view.refresh()
	# Ohne Stolz gibt der Gast eine hoffnungslose Stellung auf
	var standing := ChessAI.evaluate(_board)   # Schwarz am Zug = Sicht des Gastes
	if standing < RESIGN_BELOW and float(chess_profile(guest)["pride"]) < 0.6 and randf() < 0.5:
		_say("%s kippt den eigenen König um: „Ich gebe auf.“" % guest.display_name)
		_finish("player")
		return
	_say("%s überlegt …" % guest.display_name)
	_thinking = true
	_think_left = randf_range(THINK_TIME.x, THINK_TIME.y)
	_ai.think(_board, depth_of(guest), blunder_of(guest))


func _guest_move(m: int) -> void:
	if not _still_playing():
		return
	if m == 0:
		_check_end()
		return
	var text := _record(m)
	if _check_end():
		return
	var said := "%s zieht %s." % [guest.display_name, text]
	if randf() < COMMENT_CHANCE:
		said += " „%s“" % GUEST_LINES[randi() % GUEST_LINES.size()]
	if _board.in_check():
		said += " Schach!"
	_say(said)
	_player_turn()


## Zug ausführen und notieren. Gibt die Notation zurück.
func _record(m: int) -> String:
	var text := _board.notation(m)
	var white := _board.white_to_move
	_board.play(m)
	if white or _moves.is_empty():
		_moves.append("%d. %s" % [_board.fullmove, text])
	else:
		_moves[_moves.size() - 1] += " " + text
	_view.last_move = m
	_view.refresh()
	_update_moves()
	Game.play_sound("blip", 0.08)
	return text


## Partie vorbei? Dann auswerten.
func _check_end() -> bool:
	var status := _board.status()
	match status:
		Chess.Status.PLAYING:
			return false
		Chess.Status.CHECKMATE:
			var player_won := not _board.white_to_move
			_say("Schachmatt!")
			_finish("player" if player_won else "guest")
		Chess.Status.STALEMATE:
			_say("Patt – keiner kann mehr ziehen. Remis.")
			_finish("draw")
		Chess.Status.FIFTY_MOVES:
			_say("Fünfzig Züge ohne Schlagen oder Bauernzug – Remis.")
			_finish("draw")
		Chess.Status.REPETITION:
			_say("Dreimal dieselbe Stellung – Remis.")
			_finish("draw")
		Chess.Status.NO_MATERIAL:
			_say("Zu wenig Figuren für ein Matt – Remis.")
			_finish("draw")
	return true


# --- Remis, Aufgabe, absichtlich verlieren ------------------------------------------------

func _offer_draw() -> void:
	_draw_offered_at = _board.fullmove
	# Der Gast nimmt an, wenn er nicht klar besser steht
	var for_guest := -ChessAI.evaluate(_board)   # Weiß am Zug → umdrehen
	if for_guest < 60:
		_say("%s nickt: „Remis. Einverstanden.“" % guest.display_name)
		_finish("draw")
	else:
		_say("%s schüttelt den Kopf: „Nein, ich spiele weiter.“" % guest.display_name)
		_player_turn()


func _resign() -> void:
	_say("Du legst deinen König um.")
	_finish("guest")


## Wie Aufgeben – aber wer gut steht und aufgibt, wird vielleicht durchschaut (Spielkonzept 6.10).
func _throw_game() -> void:
	_threw_game = true
	_say("Du gibst auf, obwohl …")
	_finish("guest")


# --- Ende -------------------------------------------------------------------------------

## result: "player", "guest" oder "draw"
func _finish(result: String) -> void:
	_over = true
	_thinking = false
	_ai.cancel()
	_view.interactive = false
	_view.refresh()
	var chess := chess_profile(guest)
	var change := 5.0 + (3.0 if chess["likes"] else 0.0)     # gemeinsame Zeit
	var line := ""
	match result:
		"player":
			change -= float(chess["pride"]) * 8.0                # Stolz gekränkt
			line = guest.line("chess_lose")
			if float(chess["pride"]) > 0.5:
				guest.challenge_cooldown = randf_range(90.0, 150.0)
				guest.challenge_game = "chess"
				Game.social.queue_rematch(guest)
			_stakes.take_for_player()
		"guest":
			line = guest.line("chess_win")
			if _threw_game:
				# Stand der Spieler gut da? Dann merkt es ein guter Spieler eher.
				var player_edge := ChessAI.evaluate(_board) * (1 if _board.white_to_move else -1)
				var notice := float(chess["skill"]) * 0.7 + (0.3 if player_edge > 200 else 0.0)
				if randf() < notice:
					change -= 10.0
					line = guest.line("patronized")
				else:
					change += 6.0
			_stakes.give_to_guest(guest)
		_:
			change += 4.0                                         # Remis freut beide
			line = "Remis. Ein gutes Spiel."
			_stakes.split(guest)
	Game.social.change_relation(guest, change)
	var stakes_text := " Die Einsätze liegen auf dem Tisch – nimm sie dir." if result == "player" and _stakes.any_left() else ""
	_say("%s %s: „%s“%s" % [_log.text, guest.display_name, line, stakes_text])
	_update_title()
	if "--trace" in OS.get_cmdline_user_args():
		print("[Schach] Ende nach %d Zügen: %s" % [_board.fullmove, {"player": "du gewinnst", "guest": "%s gewinnt" % guest.display_name}.get(result, "Remis")])
	_clear()
	_option("Aufstehen", _end)


func _abort(message: String) -> void:
	_over = true
	_thinking = false
	_ai.cancel()
	_view.interactive = false
	_stakes.abandon()   # Einsätze bleiben liegen – sie gehören jetzt niemandem
	_say(message)
	_clear()
	_option("Aufstehen", _end)


func _end() -> void:
	visible = false
	active = false
	table.busy = false
	_clear()
	if guest and not guest.dead:
		guest.end_game()
	Game.player.stand_up()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


## Für automatische Tests (--autoplay): Spieler zieht schwach, sonst die erste Option.
func debug_step() -> String:
	if not active:
		return ""
	if _view.interactive and _board.white_to_move and not _over:
		var m := ChessAI.best_move(_board, 1, 0.3, randi())
		var text := _board.notation(m)
		_player_move(m)
		return "Du: " + text
	if _over and not _buttons.is_empty():
		var info := _log.text
		_buttons[0].pressed.emit()
		return info
	return ""


# --- Hilfen -----------------------------------------------------------------------------

func _still_playing() -> bool:
	return active and not _over


func _update_title() -> void:
	if guest == null:
		return
	var stakes := _stakes.labels()
	_title.text = "Schach mit %s (%s)   ·   Einsatz: %s" % [guest.display_name, strength_text(guest),
		"keiner" if stakes.is_empty() else ", ".join(stakes)]


func _update_moves() -> void:
	var recent := _moves.slice(maxi(0, _moves.size() - 8))
	_moves_label.text = "  ".join(recent)


func _say(text: String) -> void:
	_log.text = text


func _clear() -> void:
	for button in _buttons:
		button.queue_free()
	_buttons.clear()


func _option(text: String, callback: Callable, disabled: bool = false) -> void:
	var button := Button.new()
	button.text = "%d. %s" % [_buttons.size() + 1, text]
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.flat = true
	button.disabled = disabled
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", 9)
	var tight := StyleBoxEmpty.new()
	tight.content_margin_top = 1
	tight.content_margin_bottom = 1
	for style_name in ["normal", "hover", "pressed", "disabled", "focus"]:
		button.add_theme_stylebox_override(style_name, tight)
	button.pressed.connect(callback)
	_options.add_child(button)
	_buttons.append(button)


func _make_label(font_size: int, color: Color) -> Label:
	var label := Label.new()
	var settings := LabelSettings.new()
	settings.font_size = font_size
	settings.font_color = color
	label.label_settings = settings
	return label
