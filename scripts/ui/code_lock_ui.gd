class_name CodeLockUI
extends CanvasLayer
## Zahlenschloss mit vier Rädern (Spielkonzept 2.10, ZIM-6) in der Optik des Telefonfensters: Ziffern tippen,
## [Enter] probiert, [Rücktaste] löscht, [Esc] lässt das Schloss. Pausiert nicht – das Hotel geht weiter. Ob der Code
## stimmt, entscheidet der Aufrufer (open: try_code(code) -> true = offen, das Fenster schließt sich).

const DIGITS := 4

var _title: Label
var _text: Label
var _options: GridContainer
var _buttons: Array[Button] = []
var _code := ""
var _hint := ""
var _try: Callable


func _ready() -> void:
	layer = 15
	visible = false
	var box := UiKit.dark_panel(self, Color(0.03, 0.03, 0.04, 0.92), Color(0.35, 0.33, 0.3), Vector4(0.08, 0.62, 0.92, 0.98))
	_title = UiKit.plain_label(10, Color(0.8, 0.8, 0.75))
	box.add_child(_title)
	_text = UiKit.plain_label(10, Color(0.9, 0.88, 0.85))
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_text)
	_options = UiKit.option_grid(box)


## Fenster öffnen; try_code(code: String) -> bool prüft den Code.
func open(title: String, hint: String, try_code: Callable) -> void:
	_try = try_code
	_code = ""
	_hint = hint
	_title.text = title
	_update()
	for button in _buttons:
		button.queue_free()
	_buttons.clear()
	_option("Probieren [Enter]", _submit)
	_option("Lassen [Esc]", close)
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
	if Game.player:
		Game.player.in_dialog = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


## Den Code eingeben wie getippt (Debug, Prüfung)
func enter(code: String) -> void:
	_code = code.left(DIGITS)
	_submit()


func _update() -> void:
	var wheels := PackedStringArray()
	for i in DIGITS:
		wheels.append(_code[i] if i < _code.length() else "_")
	_text.text = "Räder:  %s\n%s" % [" ".join(wheels), _hint]


func _submit() -> void:
	if _code.length() < DIGITS:
		Game.say("Vier Räder – vier Ziffern.", 2.0)
		return
	if _try.is_valid() and bool(_try.call(_code)):
		close()
		return
	_code = ""
	_update()


func _process(_delta: float) -> void:
	if visible and (Game.game_over or Game.player == null or Game.player.dead):
		close()


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("pause"):
		close()
		get_viewport().set_input_as_handled()
		return
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	var key := (event as InputEventKey).keycode
	var digit := -1   # Ziffernreihe oder Ziffernblock
	if key >= KEY_0 and key <= KEY_9:
		digit = key - KEY_0
	elif key >= KEY_KP_0 and key <= KEY_KP_9:
		digit = key - KEY_KP_0
	if digit >= 0 and _code.length() < DIGITS:
		_code += str(digit)
		Game.play_sound("tap", 0.25)   # das Rad rastet ein
		_update()
	elif key == KEY_BACKSPACE:
		_code = _code.left(-1)
		_update()
	elif key == KEY_ENTER or key == KEY_KP_ENTER:
		_submit()
	else:
		return
	get_viewport().set_input_as_handled()


func _option(text: String, callback: Callable) -> void:
	var button := UiKit.flat_option(text, callback)
	_options.add_child(button)
	_buttons.append(button)
