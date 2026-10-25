class_name SlideShow
extends Control
## Bildfolge im Vollbild (Spielkonzept 8.2): Bilder und/oder Textzeilen mittig auf Schwarz, jede blendet
## ein und aus. Läuft von selbst weiter (Sequence.auto_advance) oder nur auf Tastendruck. [Leertaste]/[Enter],
## [Esc] oder ein Mausklick überspringen das aktuelle Bild, sobald es Sequence.skippable_after s zu sehen war –
## ab dann zeigt der Hinweis unten rechts das an. Bei mehreren Bildern beendet Festhalten der Taste
## (HOLD_SKIP_SECONDS) die ganze Folge. Übernommen aus rohrraser (slide.gd, slide_sequence.gd, slide_show.gd),
## hier im Code gebaut statt als Szene mit Ressourcen. Wird nicht gespeichert.
##
## Gebrauch: var show := SlideShow.new(); add_child(show); show.play(SlideShow.splash()); await show.finished

## true, wenn das letzte Bild abgelaufen ist; false, wenn stop() die Folge abgebrochen hat
signal finished(completed: bool)

## Ein Bild der Folge: Bild, Textzeile oder beides; sound klingt zu Beginn des
## Einblendens an und läuft weiter, bis der Klang eines späteren Bilds ihn ablöst; Überspringen blendet ihn mit aus,
## stop() bricht ihn ab.
class Slide:
	var texture: Texture2D
	var text := ""
	var sound: AudioStream
	## Sekunden bis zum nächsten Bild (bei auto_advance); 0 = Sequence.seconds_per_slide
	var duration := 0.0

	func _init(texture_: Texture2D = null, text_ := "", duration_ := 0.0) -> void:
		texture = texture_
		text = text_
		duration = duration_


## Die Bilder und wie sie weiterlaufen.
class Sequence:
	var slides: Array[Slide] = []
	## true: jedes Bild läuft nach seiner Dauer weiter; false: nur auf Tastendruck
	var auto_advance := true
	var seconds_per_slide := 4.0
	## so lange muss ein Bild zu sehen sein, bevor ein Tastendruck es überspringt
	var skippable_after := 1.0


## Vorspann vor dem Titelbildschirm (8.2): Logo und Platzhalterklang einer brechenden Welle (tools/build_wave_sound.py)
const SPLASH_LOGO := "res://assets/textures/splash/tsunami_games.png"
const SPLASH_SOUND := "res://assets/sound/splash_wave.wav"
const SPLASH_SECONDS := 7.5
## Ein- und Ausblenden je Bild (s); beim Überspringen schneller
const FADE := 0.8
const SKIP_FADE := 0.25
## Festhalten der Taste nach einem Überspringen beendet eine Folge aus mehreren Bildern (s)
const HOLD_SKIP_SECONDS := 1.0
const SKIP_HINT := "Überspringen [Leertaste]"

var _sequence: Sequence
var _index := -1
var _elapsed := 0.0
## Ausblenden nach Überspringen läuft (s seit dem Druck); −1 = nicht
var _leaving := -1.0
## So lange wird die Taste seit einem angenommenen Überspringen gehalten; −1 = nicht
var _hold := -1.0
var _content: VBoxContainer
var _picture: TextureRect
var _label: Label
var _hint: Label
var _sound: AudioStreamPlayer


## Der Vorspann beim Spielstart: das Studiologo.
static func splash() -> Sequence:
	var sequence := Sequence.new()
	var logo := Slide.new(load(SPLASH_LOGO), "", SPLASH_SECONDS)
	logo.sound = load(SPLASH_SOUND)
	sequence.slides.append(logo)
	return sequence


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP   # Klicks gehen nicht ans Menü darunter
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var backdrop := ColorRect.new()
	backdrop.color = Color.BLACK
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(backdrop)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_content = VBoxContainer.new()
	_content.alignment = BoxContainer.ALIGNMENT_CENTER
	_content.add_theme_constant_override("separation", 8)
	_content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_content)
	_content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_picture = TextureRect.new()
	_picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_picture.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS   # Projektstandard ist Nearest
	_picture.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_content.add_child(_picture)
	_label = UiKit.label("", 12, UiKit.PAPER, HORIZONTAL_ALIGNMENT_CENTER)
	_content.add_child(_label)
	_hint = UiKit.label(SKIP_HINT, 8, UiKit.PAPER)
	_hint.modulate.a = 0.0
	add_child(_hint)
	_hint.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT, Control.PRESET_MODE_MINSIZE, 8)
	_sound = AudioStreamPlayer.new()
	add_child(_sound)


func is_playing() -> bool:
	return _sequence != null


## Spielt die Folge vom ersten Bild an. Eine leere Folge endet im nächsten Bild (completed), damit ein
## `await finished` des Aufrufers noch zurückkehrt.
func play(sequence: Sequence) -> void:
	_sequence = sequence
	visible = true
	if sequence.slides.is_empty():
		_end.call_deferred(true)   # sofort ausgelöst käme es vor dem await
		return
	_show_slide(0)


## Bricht eine laufende Folge ab: finished(false).
func stop() -> void:
	if is_playing():
		_sound.stop()
		_end(false)


func _process(delta: float) -> void:
	if not is_playing():
		return
	_elapsed += delta
	if _hold >= 0.0:
		if not Input.is_action_pressed("ui_accept"):
			_hold = -1.0
		else:
			_hold += delta
			if _hold >= HOLD_SKIP_SECONDS:
				_end(true)
				return
	var alpha := 1.0
	if _leaving >= 0.0:
		_leaving += delta
		alpha = 1.0 - _leaving / SKIP_FADE
		_sound.volume_db = _effects_db() + linear_to_db(maxf(alpha, 0.0001))   # Klang blendet mit aus
		if alpha <= 0.0:
			_show_slide(_index + 1)
			return
	else:
		alpha = minf(1.0, _elapsed / FADE)
		if _sequence.auto_advance:
			var left := _current_duration() - _elapsed
			if left <= 0.0:
				_show_slide(_index + 1)
				return
			alpha = minf(alpha, left / FADE)
	_content.modulate.a = clampf(alpha, 0.0, 1.0)
	var hint := 1.0 if _elapsed >= _sequence.skippable_after and _skip_reachable() and _leaving < 0.0 else 0.0
	_hint.modulate.a = move_toward(_hint.modulate.a, hint * 0.7, delta * 2.0)


func _gui_input(event: InputEvent) -> void:
	var click := event as InputEventMouseButton
	if click and click.pressed and click.button_index == MOUSE_BUTTON_LEFT:
		accept_event()
		_try_skip(false)


func _unhandled_input(event: InputEvent) -> void:
	if not is_playing():
		return
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()
		_try_skip(event.is_action_pressed("ui_accept") and not event.is_echo())


func _try_skip(may_hold: bool) -> void:
	if not is_playing() or _leaving >= 0.0 or _elapsed < _sequence.skippable_after:
		return
	if may_hold and _sequence.slides.size() > 1:
		_hold = 0.0   # Festhalten ab hier überspringt den Rest
	_leaving = 0.0


## Ob ein Druck dieses Bild überspringen kann, bevor es von selbst endet – sonst kein Hinweis.
func _skip_reachable() -> bool:
	return not _sequence.auto_advance or _sequence.skippable_after < _current_duration() - FADE


func _show_slide(index: int) -> void:
	_index = index
	_elapsed = 0.0
	_leaving = -1.0
	_content.modulate.a = 0.0
	if _index >= _sequence.slides.size():
		_end(true)
		return
	var slide := _sequence.slides[_index]
	_picture.texture = slide.texture
	_picture.visible = slide.texture != null
	_label.text = slide.text
	_label.visible = slide.text != ""
	if slide.sound:
		_sound.stream = slide.sound
		_sound.volume_db = _effects_db()
		_sound.play()


## Lautstärke der Effekte aus den Einstellungen (die Gesamtlautstärke liegt schon auf dem Master-Bus).
func _effects_db() -> float:
	return linear_to_db(maxf(Settings.effects_volume, 0.0001))


func _current_duration() -> float:
	var slide := _sequence.slides[_index]
	return slide.duration if slide.duration > 0.0 else _sequence.seconds_per_slide


func _end(completed: bool) -> void:
	_sequence = null
	_index = -1
	_hold = -1.0
	_leaving = -1.0
	visible = false
	finished.emit(completed)
