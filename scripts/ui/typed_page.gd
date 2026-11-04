class_name TypedPage
extends RefCounted
## Getipptes von der Schreibmaschine der Chefsekretärin (Spielkonzept 2.11, ZIM-119): Ein Typenhebel ist verbogen, das
## „e“ sitzt in jedem Text ein wenig zu hoch – im Willkommensbrief, in den Aushängen der Direktion, im Vertrag von 1987.
## Lesbar über Menus.open_typed (DirectorOffice.read_typed zählt mit). Auszeichnung im Text:
##   [hand]…[/hand]   von Hand nachgetragen: Tinte, schräg, ohne springendes „e“
##   [note]…[/note]   was die Figur sieht (Beschreibung), blass, ohne springendes „e“
##   [s]…[/s]         durchgestrichen (BBCode, getippt)
## Sonst kein BBCode; eckige Klammern im Text werden geschützt.

## So weit sitzt das „e“ zu hoch (Pixel der Oberfläche bei Schriftgröße 9)
const RAISE := 1.0
## Tinte der Handschrift, Schräge der Schrift (Verschiebung je Höhe)
const HAND_INK := Color(0.16, 0.2, 0.42)
const HAND_SLANT := 0.22
## Beschreibungen in den Texten
const NOTE_INK := Color(0.42, 0.36, 0.28)
const _MARKUP := ["hand", "note"]


## Leseblatt: RichTextLabel mit dem springenden „e“, bricht um wie UiKit.wrap_label.
static func make(text: String, size: int = 9, color: Color = UiKit.INK) -> RichTextLabel:
	var l := RichTextLabel.new()
	l.bbcode_enabled = true
	l.fit_content = true
	l.scroll_active = false
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(120, 0)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.add_theme_font_size_override("normal_font_size", size)
	l.add_theme_font_size_override("italics_font_size", size)
	l.add_theme_color_override("default_color", color)
	l.install_effect(JumpingE.new())
	l.text = bbcode(text)
	return l


## Schräge Schrift für die Handschrift aus der Schrift des Blatts – erst im Baum bekannt (Thema des Menüs).
static func slant(l: RichTextLabel) -> void:
	var slanted := FontVariation.new()
	slanted.base_font = l.get_theme_font("normal_font")
	slanted.variation_transform = Transform2D(Vector2(1, 0), Vector2(-HAND_SLANT, 1), Vector2.ZERO)
	l.add_theme_font_override("italics_font", slanted)


## Text mit Auszeichnung → BBCode: jedes getippte „e“ in [hoch]…[/hoch], Handschrift und Beschreibung ohne.
static func bbcode(text: String) -> String:
	var out := ""
	var rest := text
	while true:
		var at := -1
		var tag := ""
		for t: String in _MARKUP:
			var i := rest.find("[%s]" % t)
			if i >= 0 and (at < 0 or i < at):
				at = i
				tag = t
		if at < 0:
			return out + _typed(rest)
		out += _typed(rest.substr(0, at))
		var start := at + tag.length() + 2
		var end := rest.find("[/%s]" % tag, start)
		if end < 0:
			end = rest.length()
		var inner := _escape(rest.substr(start, end - start))
		if tag == "hand":
			out += "[i][color=#%s]%s[/color][/i]" % [HAND_INK.to_html(false), inner]
		else:
			out += "[color=#%s]%s[/color]" % [NOTE_INK.to_html(false), inner]
		rest = rest.substr(mini(end + tag.length() + 3, rest.length()))
	return out


## Getippter Abschnitt: Klammern schützen (außer [s]), dann das „e“ anheben.
static func _typed(part: String) -> String:
	var safe := _escape(part).replace("[lb]s]", "[s]").replace("[lb]/s]", "[/s]")
	return safe.replace("e", "[hoch]e[/hoch]")


static func _escape(part: String) -> String:
	return part.replace("[", "[lb]")


## Wie viele „e“ ein Text getippt hat (Debug-Prüfung)
static func raised_count(text: String) -> int:
	return bbcode(text).count("[hoch]")


## Das verbogene „e“: jede Type in [hoch] sitzt RAISE Pixel über der Zeile.
class JumpingE:
	extends RichTextEffect

	var bbcode := "hoch"

	func _process_custom_fx(fx: CharFXTransform) -> bool:
		fx.offset = Vector2(0, -TypedPage.RAISE)
		return true
