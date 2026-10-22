class_name PhoneUI
extends CanvasLayer
## Fenster für Telefonate (Spielkonzept 4.14) in der Optik des Gesprächsfensters. Pausiert
## nicht – während man telefoniert, geht das Hotel weiter. Zwei Arten von Seiten:
##   · Gespräch: Text + Antworten (Maus oder Zifferntasten 1–9)
##   · Wählen: Ziffern tippen, [Enter] wählt, [Rücktaste] löscht, [H] Hörer daneben legen
## Esc legt immer auf. Die Logik steckt in `PhoneCalls`.

const MAX_DIGITS := 4

var dialing := false

var _title: Label
var _text: Label
var _options: GridContainer
var _buttons: Array[Button] = []
var _number := ""
var _dial_hint := ""


func _ready() -> void:
	layer = 15
	visible = false
	var box := UiKit.dark_panel(self, Color(0.03, 0.03, 0.04, 0.92), Color(0.35, 0.33, 0.3), Vector4(0.08, 0.5, 0.92, 0.98))
	_title = UiKit.plain_label(10, Color(0.8, 0.8, 0.75))
	box.add_child(_title)
	_text = UiKit.plain_label(10, Color(0.9, 0.88, 0.85))
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_text)
	_options = UiKit.option_grid(box)


func open() -> void:
	if visible:
		return
	visible = true
	Game.player.in_dialog = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if Game.hud:
		Game.hud.set_prompt("")


func close() -> void:
	if not visible:
		return
	visible = false
	dialing = false
	if Game.player:
		Game.player.in_dialog = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


## Gesprächsseite. options: [[Text, Callable], …] oder [Text, Callable, gesperrt].
func show_page(title: String, text: String, options: Array) -> void:
	open()
	dialing = false
	_title.text = title
	_text.text = text
	_clear()
	for entry in options:
		_option(String(entry[0]), entry[1], entry.size() > 2 and bool(entry[2]))


## Text austauschen, ohne die Antworten neu aufzubauen (Freizeichen, Atmen …).
func set_text(text: String) -> void:
	_text.text = text


func title() -> String:
	return _title.text


## Wählseite. quick: [[Text, Nummer], …] – z. B. die Zimmerliste an der Rezeption.
func show_dial(title: String, hint: String, quick: Array) -> void:
	open()
	dialing = true
	_number = ""
	_dial_hint = hint
	_title.text = title
	_update_number()
	_clear()
	for entry in quick:
		var number := String(entry[1])
		_option(String(entry[0]), func() -> void: Game.phones.dial(number), false, false)
	_option("Wählen [Enter]", func() -> void: Game.phones.dial(_number), false, false)
	_option("Hörer daneben legen [H]", func() -> void: Game.phones.leave_off_hook(), false, false)
	_option("Auflegen [Esc]", func() -> void: Game.phones.hang_up(), false, false)


func _update_number() -> void:
	var shown := _number if _number != "" else "_"
	_text.text = "Wählscheibe:  %s\n%s" % [shown, _dial_hint]


func _process(_delta: float) -> void:
	if visible and (Game.game_over or Game.player == null or Game.player.dead):
		close()


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("pause"):
		Game.phones.hang_up()
		get_viewport().set_input_as_handled()
		return
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	var key := (event as InputEventKey).keycode
	if dialing:
		var digit := -1   # Ziffernreihe oder Ziffernblock
		if key >= KEY_0 and key <= KEY_9:
			digit = key - KEY_0
		elif key >= KEY_KP_0 and key <= KEY_KP_9:
			digit = key - KEY_KP_0
		if digit >= 0 and _number.length() < MAX_DIGITS:
			_number += str(digit)
			Game.play_sound("creak", 0.12)   # die Wählscheibe schnurrt zurück
			_update_number()
		elif key == KEY_BACKSPACE:
			_number = _number.left(-1)
			_update_number()
		elif key == KEY_ENTER or key == KEY_KP_ENTER:
			Game.phones.dial(_number)
		elif key == KEY_H:
			Game.phones.leave_off_hook()
		else:
			return
		get_viewport().set_input_as_handled()
		return
	if UiKit.press_number(event, _buttons):
		get_viewport().set_input_as_handled()


func _clear() -> void:
	for button in _buttons:
		button.queue_free()
	_buttons.clear()


func _option(text: String, callback: Callable, disabled: bool = false, numbered: bool = true) -> void:
	var button := UiKit.flat_option(("%d. %s" % [_buttons.size() + 1, text]) if numbered else text, callback, disabled)
	_options.add_child(button)
	_buttons.append(button)
