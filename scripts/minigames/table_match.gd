class_name TableMatch
extends CanvasLayer
## Gemeinsame Grundlage der Tischspiele gegen einen Gast (Spielkonzept 6.10): Mäxchen (DiceMatch), Schach
## (ChessMatch) und Darts (DartMatch). Fenster mit Titel, Verlauf und nummerierten Knöpfen (auch über die Tasten 1,
## 2 …), Hinsetzen, Einsätze auf dem Tisch (TableStakes), Abbruch bei einer Vorwarnung oder wenn der Gast davonläuft,
## Aufstehen. Jedes Spiel liefert seinen Tisch (_table) und sein Spielgerät (_gear) und baut sein Fenster mit
## _build_panel; Darts steht statt zu sitzen (_take_places, _leave_places) und kennt auch eine Partie ohne Gast.

const RUN_AWAY := "%s springt auf und rennt davon! Die Einsätze liegen noch auf dem Tisch …"

var active := false
var guest: Guest

var _stakes := TableStakes.new()
var _waiting_for_seat := false
var _abort_timer := -1.0
var _over := false
var _threw_game := false

var _title: Label
var _log: Label
var _options: Container
var _buttons: Array[Button] = []
var _button_width := 0.0   ## Mindestbreite der Knöpfe (0 = so breit wie der Text)


# --- Vom Spiel zu liefern ------------------------------------------------------------

## Der Tisch, an dem gespielt wird.
func _table() -> GameTable:
	return null


## Spielgerät, das auf dem Tisch liegen muss (Würfelbecher, Schachbrett) – nicht als Einsatz erlaubt.
func _gear() -> Item.Kind:
	return Item.Kind.DICE_CUP


## Beide sitzen: Die Partie beginnt.
func _on_seated() -> void:
	pass


## Jedes Bild, solange die Partie läuft und der Gast bleibt.
func _update_game(_delta: float) -> void:
	pass


## Partie vorbei oder abgebrochen: Laufendes anhalten (Schach: die KI).
func _stop() -> void:
	pass


## Beide an ihre Plätze: setzen sich an den Tisch, die Maus wird frei fürs Fenster.
func _take_places() -> void:
	var table := _table()
	Game.player.sit_at(table.player_seat.global_position, table.top_center())
	guest.sit_for_game(table.guest_seat.global_position, table.top_center())
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


## Partie zu Ende: aufstehen, die Maus steuert wieder den Blick.
func _leave_places() -> void:
	Game.player.stand_up()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


# --- Ablauf ----------------------------------------------------------------------------

func can_stake_item(p_guest: Guest) -> bool:
	return TableStakes.can_stake_item(p_guest, _gear())


## Gemeinsame Gründe, nicht zu spielen (Angst, Lärm, langes Flackern) – "" = der Gast spielt.
func _guest_unwilling(p_guest: Guest) -> String:
	var table := _table()
	if p_guest.fear >= 60.0:
		return p_guest.line("panic")
	if not Game.director.is_quiet(table.global_position, 20.0):
		return "Jetzt? Hörst du das nicht?"
	if Game.director.long_signal_near(table.global_position):
		return "Jetzt? Hast du das Licht gesehen?"
	return ""


## Partie beginnen: Spielgerät aus der Hand auf den Tisch (um gear_offset neben die Mitte), Einsätze hinlegen,
## beide setzen sich. Das Spiel setzt vorher seine eigenen Werte zurück und schreibt danach Titel und Optionen.
## stake: {"money": int, "item": bool}
func _begin(p_guest: Guest, stake: Dictionary, gear_offset: Vector3) -> void:
	var table := _table()
	guest = p_guest
	active = true
	_over = false
	_threw_game = false
	_abort_timer = -1.0
	table.busy = true
	_stakes = TableStakes.new()
	var player := Game.player
	if player.held_kind() == _gear():
		var gear := player.held
		player.drop_held()
		gear.global_position = table.top_center() + gear_offset
	_stakes.place(table, guest, stake)
	_take_places()
	visible = true
	_waiting_for_seat = true


func _process(delta: float) -> void:
	if not active:
		return
	if _waiting_for_seat and (guest == null or guest.seated):
		_waiting_for_seat = false
		_on_seated()
	if not _over and guest != null and _guest_leaves(delta):
		return
	_update_game(delta)


## Springt der Gast auf? Gestorben, geflohen – oder er bemerkt eine Vorwarnung: je mutiger, desto später;
## langes Flackern bricht ab (4.17). Die Einsätze bleiben liegen.
func _guest_leaves(delta: float) -> bool:
	if guest.dead or guest.state != Guest.State.MINIGAME:
		_abort(RUN_AWAY % guest.display_name)
		return true
	var table := _table()
	if not Game.director.is_quiet(table.global_position, 20.0) or Game.director.long_signal_near(table.global_position):
		if _abort_timer < 0.0:
			_abort_timer = 0.5 + float(guest.profile["brave"]) * 4.5
		_abort_timer -= delta
		if _abort_timer <= 0.0:
			guest.say_panic()
			guest.end_game()
			_abort(RUN_AWAY % guest.display_name)
			return true
	return false


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if UiKit.press_number(event, _buttons):
		get_viewport().set_input_as_handled()


func _abort(message: String) -> void:
	_over = true
	_stop()
	_stakes.abandon()   # Einsätze bleiben liegen – sie gehören jetzt niemandem
	_say(message)
	_clear()
	_option("Aufstehen", _end)


func _end() -> void:
	visible = false
	active = false
	_table().busy = false
	_clear()
	if guest and not guest.dead:
		guest.end_game()
	_leave_places()


func _still_playing() -> bool:
	return active and not _over


# --- Fenster ---------------------------------------------------------------------------

## Rahmen des Fensters: Hintergrund, Innenabstand und Lage als Anker (links, oben, rechts, unten).
func _build_panel(bg: Color, margin: float, anchors: Vector4) -> PanelContainer:
	layer = 15
	visible = false
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = Color(0.5, 0.35, 0.15)
	style.set_border_width_all(1)
	style.set_content_margin_all(margin)
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)
	panel.anchor_left = anchors.x
	panel.anchor_top = anchors.y
	panel.anchor_right = anchors.z
	panel.anchor_bottom = anchors.w
	return panel


func _say(text: String) -> void:
	_log.text = text


func _clear() -> void:
	for button in _buttons:
		button.queue_free()
	_buttons.clear()


func _option(text: String, callback: Callable, disabled: bool = false) -> void:
	var button := UiKit.flat_option("%d. %s" % [_buttons.size() + 1, text], callback, disabled)
	button.custom_minimum_size = Vector2(_button_width, 0)
	button.size_flags_horizontal = Control.SIZE_FILL
	_options.add_child(button)
	_buttons.append(button)
