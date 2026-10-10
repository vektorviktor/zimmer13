class_name SlotList
extends VBoxContainer
## Slot-Übersicht (Spielkonzept 8.5): Vorschaubild, Tagebuchsatz, Spielzeit, Datum,
## lebende Gäste. Modus LOAD zeigt zusätzlich den Autosave; leere Slots sind dann gesperrt.

signal picked(slot: int)

enum Mode { LOAD, SAVE, NEW }

var mode := Mode.LOAD
var highlight := -1


func setup(p_mode: Mode, p_highlight: int = -1) -> SlotList:
	mode = p_mode
	highlight = p_highlight
	return self


func _ready() -> void:
	add_theme_constant_override("separation", 2)
	refresh()


func refresh() -> void:
	UiKit.clear(self)
	var slots: Array[int] = [1, 2, 3]
	if mode == Mode.LOAD:
		slots.push_front(SaveManager.AUTOSAVE)
	for slot in slots:
		add_child(_row(slot))


func _row(slot: int) -> Control:
	var info := SaveManager.slot_info(slot)
	var button := Button.new()
	button.custom_minimum_size = Vector2(0, 44)
	button.focus_mode = Control.FOCUS_ALL
	button.disabled = info.is_empty() and mode == Mode.LOAD
	button.pressed.connect(func() -> void: picked.emit(slot))
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 6)
	button.add_child(row)
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	row.offset_left = 4
	row.offset_top = 2
	row.offset_bottom = -2
	var thumb := TextureRect.new()
	thumb.custom_minimum_size = Vector2(70, 39)
	thumb.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	thumb.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	thumb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	thumb.texture = SaveManager.thumbnail(slot) if not info.is_empty() else null
	var frame := ColorRect.new()
	frame.color = Color(0.1, 0.06, 0.04)
	frame.custom_minimum_size = Vector2(70, 39)
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_child(thumb)
	thumb.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	row.add_child(frame)
	var text := VBoxContainer.new()
	text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text.add_theme_constant_override("separation", 0)
	row.add_child(text)
	var slot_name := "Autosave" if slot == SaveManager.AUTOSAVE else "Slot %d" % slot
	if slot == highlight:
		slot_name += "  (aktuell)"
	var head := UiKit.label(slot_name, 10, UiKit.ACCENT if slot == highlight else UiKit.INK)
	head.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text.add_child(head)
	if info.is_empty():
		text.add_child(_small("– leer –"))
	else:
		var alive: Array = info["alive"]
		text.add_child(_small("%s · %s · Spielzeit %s · Gäste: %s" % [Calendar.date_text(float(info["playtime"])),
			UiKit.date_text(int(info["saved_at"])), UiKit.playtime_text(float(info["playtime"])),
			", ".join(alive) if not alive.is_empty() else "keiner mehr"]))
		var entry := _small("„%s“" % String(info["text"]))
		entry.add_theme_color_override("font_color", UiKit.INK)
		entry.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		entry.custom_minimum_size = Vector2(240, 0)
		text.add_child(entry)
	return button


func _small(t: String) -> Label:
	var l := UiKit.label(t, 8, UiKit.INK_FAINT)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.clip_text = true
	return l
