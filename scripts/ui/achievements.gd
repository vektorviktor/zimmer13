class_name Achievements
extends CanvasLayer
## Erfolge (Spielkonzept 8.11): drei Stufen nach Seltenheit – Bronze, Silber, Gold –, je Erfolg in LIST festgelegt.
## Freigeschaltet wird mit unlock(id) an der passenden Stelle im Spiel (Game.achievements); was sich am Zustand ablesen
## lässt (Kalender, gute Freunde, Kürbis vor Zimmer 13, gesehene Bedrohungen), prüft _check alle CHECK_EVERY s selbst.
## Neu freigeschaltet: Karte gleitet oben rechts herein, bleibt SHOW_TIME s und gleitet nach rechts hinaus – oben der
## Name, darunter Symbol und Beschreibung, Rahmen in der Farbe der Stufe; mehrere nacheinander.
## Gespeichert wird nicht im Spielstand, sondern im Profil (PATH): Erfolge bleiben über neue Spiele, Tod und Laden.
## Debug-Starts (Parameter außer HARMLESS_ARGS) und Debug-Eingriffe (Konsole, F5/F6/F7/F9 → cheated()) schalten nur
## für diese Sitzung frei, ohne zu schreiben; headless beginnt leer. Geheime Erfolge zeigt das Spielmenü gesperrt als
## „???“ – alles, was den friedlichen Anfang (2.1) oder die Bedrohungen verraten würde.

enum Tier { BRONZE, SILVER, GOLD }
const TIER_NAMES := ["Bronze", "Silber", "Gold"]
const TIER_COLORS := [Color(0.78, 0.5, 0.26), Color(0.78, 0.8, 0.84), Color(0.96, 0.78, 0.3)]

## id (englisch, später 1:1 für Steam) → name, text, tier, icon, secret. icon: "art:<name>" (IconArt, Icon_<name>.png)
## oder "item:<Item.Kind>" (gerendert wie in der Tasche). Reihenfolge = Reihenfolge im Spielmenü.
## Masken (5.19) und „Snack auf den Träger“ kommen mit dem Maskenball dazu.
const LIST := {
	"heart_request": {"name": "Herzenssache", "text": "Einem Gast seine Herzensbitte erfüllt.",
		"tier": Tier.BRONZE, "icon": "item:SWEETS"},
	"good_friend": {"name": "Ein guter Freund", "text": "Mit einem Gast richtig gut befreundet.",
		"tier": Tier.BRONZE, "icon": "item:TEA"},
	"maexchen": {"name": "Mäxchen", "text": "Einen Gast an der Bar beim Mäxchen geschlagen.",
		"tier": Tier.BRONZE, "icon": "item:DICE_CUP"},
	"chess": {"name": "Schachmatt", "text": "Eine Schachpartie in der Lobby gewonnen.",
		"tier": Tier.BRONZE, "icon": "item:CHESS_BOARD"},
	"lantern": {"name": "Ein Licht vor der Tür", "text": "Einen geschnitzten Kürbis mit brennender Kerze vor Zimmer 13 gestellt.",
		"tier": Tier.BRONZE, "icon": "item:CARVED_PUMPKIN"},
	"salt": {"name": "Bis hierher", "text": "Eine Salzlinie hat es aufgehalten.",
		"tier": Tier.BRONZE, "icon": "item:SALT", "secret": true},
	"jury_doll": {"name": "Festgewachsen", "text": "Versucht, die alte Puppe hochzuheben.",
		"tier": Tier.BRONZE, "icon": "art:decorate", "secret": true},
	"ceremony": {"name": "Licht aus", "text": "Die Nacht der Siegerehrung überstanden.",
		"tier": Tier.SILVER, "icon": "art:themonster", "secret": true},
	"ghost_escape": {"name": "Losgerissen", "text": "Dich aus dem Griff des Lakengeists befreit.",
		"tier": Tier.SILVER, "icon": "art:sheetghost", "secret": true},
	"pumpkin_escape": {"name": "Kopflos", "text": "Den Kürbismann abgeschüttelt.",
		"tier": Tier.SILVER, "icon": "art:pumpkinhead", "secret": true},
	"week": {"name": "Eine Woche Zimmer 13", "text": "Den 8. Oktober im Hotel erlebt.",
		"tier": Tier.SILVER, "icon": "art:sleep"},
	"five_friends": {"name": "Stammtisch", "text": "Fünf gute Freunde unter den Gästen.",
		"tier": Tier.SILVER, "icon": "art:alcohol"},
	"halloween": {"name": "Halloween", "text": "Den 31. Oktober erreicht.",
		"tier": Tier.GOLD, "icon": "item:PUMPKIN"},
	"all_threats": {"name": "Alle drei", "text": "Das Monster, den Lakengeist und den Kürbismann gesehen – und noch am Leben.",
		"tier": Tier.GOLD, "icon": "art:dead", "secret": true},
}

const PATH := "user://achievements.cfg"
## Startparameter, die keinen Debug-Start machen (Laden, Titelbildschirm, Darstellung)
const HARMLESS_ARGS := ["--load=", "--new=", "--title", "--splash", "--fps", "--bg"]
const CHECK_EVERY := 1.0
const SHOW_TIME := 5.0
const SLIDE_TIME := 0.45
const CARD_WIDTH := 150.0
const MARGIN := 6.0
const ICON_SIZE := 24
## Kürbis vor Zimmer 13: so nah an der Stelle vor der Tür (m)
const LANTERN_RANGE := 2.0
const FIVE_FRIENDS := 5

## id → Unix-Zeit der Freischaltung
var unlocked := {}
## Nur für diese Sitzung freischalten, nichts schreiben (Debug-Start, Debug-Eingriff, headless)
var debug := false

var _queue: Array[String] = []
var _card: Control
var _check_t := 0.0
var _item_icons: ItemIcons


func _ready() -> void:
	layer = 35   # über Spielmenü und Sterbebildschirm
	process_mode = Node.PROCESS_MODE_ALWAYS   # die Karte läuft auch in der Pause weiter
	_item_icons = ItemIcons.new()
	add_child(_item_icons)
	if DisplayServer.get_name() == "headless":
		debug = true
	else:
		_load()
		for arg in OS.get_cmdline_user_args():
			if not HARMLESS_ARGS.any(func(a: String) -> bool: return arg == a or (a.ends_with("=") and arg.begins_with(a))):
				debug = true


func _process(delta: float) -> void:
	if _card == null and not _queue.is_empty():
		_show(_queue.pop_front())
	if get_tree().paused:
		return
	_check_t -= delta
	if _check_t <= 0.0:
		_check_t = CHECK_EVERY
		_check()


func has(id: String) -> bool:
	return unlocked.has(id)


## Erfolg freischalten (einmalig) und einblenden. Nach dem eigenen Tod nicht mehr.
func unlock(id: String) -> void:
	if not LIST.has(id):
		push_error("Unbekannter Erfolg: %s" % id)
		return
	if unlocked.has(id) or (Game.player and Game.player.dead):
		return
	unlocked[id] = int(Time.get_unix_time_from_system())
	_save()
	_queue.append(id)
	Game.play_sound("trophy", 0.5 + 0.15 * int(LIST[id]["tier"]))
	if Game.tracing or DisplayServer.get_name() == "headless":
		print("[Erfolg] %s (%s)%s" % [LIST[id]["name"], TIER_NAMES[LIST[id]["tier"]], " – nur Sitzung" if debug else ""])


## Debug-Eingriff (Konsole, F5/F6/F7/F9): ab jetzt nichts mehr ins Profil schreiben.
func cheated() -> void:
	if not debug and Game.tracing:
		print("[Erfolg] Debug-Eingriff – Erfolge gelten nur noch für diese Sitzung")
	debug = true


func count() -> int:
	return unlocked.size()


# --- Selbst prüfen ----------------------------------------------------------------------------

func _check() -> void:
	if Game.director == null or Game.player == null or Game.player.dead or Game.creating:
		return
	var day := Calendar.today()
	if day >= 3 and Game.director.first_attack_done:
		unlock("ceremony")
	if day >= 8:
		unlock("week")
	if day >= Calendar.HALLOWEEN:
		unlock("halloween")
	if Game.notebook and Game.notebook.seen.size() >= IconArt.THREAT_ORDER.size():
		unlock("all_threats")
	if Game.social:
		var friends := 0
		for g: Guest in Game.social.guests:
			if not g.dead and Social.tier(g) == Social.Tier.GOOD_FRIEND:
				friends += 1
		if friends >= 1:
			unlock("good_friend")
		if friends >= FIVE_FRIENDS:
			unlock("five_friends")
		if not has("lantern"):
			_check_lantern()


## Brennender geschnitzter Kürbis am Boden vor der Tür von Zimmer 13 – egal, wer die Kerze angezündet hat.
func _check_lantern() -> void:
	var rooms: Dictionary = Game.social.builder.rooms
	if not rooms.has(LevelBuilder.PLAYER_ROOM):
		return
	var front: Vector3 = rooms[LevelBuilder.PLAYER_ROOM]["door_front"]
	for node in get_tree().get_nodes_in_group("items"):
		var item := node as Item
		if item and item.kind == Item.Kind.CARVED_PUMPKIN and item.lit and not item.is_held \
				and Vector2(item.global_position.x - front.x, item.global_position.z - front.z).length() < LANTERN_RANGE \
				and absf(item.global_position.y - front.y) < 1.0:
			unlock("lantern")
			return


# --- Einblendung ------------------------------------------------------------------------------

func _show(id: String) -> void:
	var entry: Dictionary = LIST[id]
	var color: Color = TIER_COLORS[entry["tier"]]
	var panel := PanelContainer.new()
	panel.theme = UiKit.menu_theme()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.04, 0.03, 0.92)
	style.border_color = color
	style.set_border_width_all(1)
	style.set_content_margin_all(5)
	panel.add_theme_stylebox_override("panel", style)
	panel.custom_minimum_size = Vector2(CARD_WIDTH, 0)
	add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)
	panel.add_child(box)
	var head := HBoxContainer.new()
	box.add_child(head)
	var title := UiKit.label(String(entry["name"]), 9, color)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(title)
	head.add_child(UiKit.label(TIER_NAMES[entry["tier"]], 6, color.darkened(0.25)))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 5)
	box.add_child(row)
	row.add_child(medal(id, true))
	var text := UiKit.wrap_label(String(entry["text"]), 7, Color(0.85, 0.8, 0.7))
	text.custom_minimum_size.x = CARD_WIDTH - ICON_SIZE - 20.0
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(text)
	_card = panel
	_slide.call_deferred(panel)


## Herein, stehen, hinaus – die Breite steht erst nach dem ersten Layout fest.
func _slide(panel: Control) -> void:
	panel.reset_size()
	var screen := get_viewport().get_visible_rect().size
	var shown := screen.x - panel.size.x - MARGIN
	panel.position = Vector2(screen.x + 2.0, MARGIN)
	var tween := panel.create_tween()
	tween.tween_property(panel, "position:x", shown, SLIDE_TIME).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_interval(SHOW_TIME)
	tween.tween_property(panel, "position:x", screen.x + 2.0, SLIDE_TIME).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.tween_callback(func() -> void:
		panel.queue_free()
		_card = null)


## Symbol des Erfolgs auf dunklem Grund mit Rahmen in der Farbe der Stufe – gesperrt dunkel und ohne Farbe.
func medal(id: String, open: bool) -> Control:
	var entry: Dictionary = LIST[id]
	var frame := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.07, 0.05)
	style.border_color = TIER_COLORS[entry["tier"]] if open else Color(0.3, 0.27, 0.24)
	style.set_border_width_all(1)
	style.set_content_margin_all(1)
	frame.add_theme_stylebox_override("panel", style)
	frame.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	var pic := TextureRect.new()
	pic.custom_minimum_size = Vector2(ICON_SIZE, ICON_SIZE)
	pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	pic.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	pic.texture = _icon(String(entry["icon"])) if open or not entry.get("secret", false) else null
	if not open:
		pic.modulate = Color(0.25, 0.25, 0.25)
	frame.add_child(pic)
	return frame


func _icon(spec: String) -> Texture2D:
	var parts := spec.split(":")
	if parts[0] == "art":
		return IconArt.texture(parts[1])
	var kind: int = Item.Kind.get(parts[1], -1)
	if kind < 0:
		return null
	var item := Item.create(kind)
	var tex := _item_icons.icon(item)
	item.free()
	return tex


# --- Profil -----------------------------------------------------------------------------------

func _load() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(PATH) != OK:
		return
	for id in cfg.get_section_keys("unlocked") if cfg.has_section("unlocked") else PackedStringArray():
		if LIST.has(id):
			unlocked[id] = int(cfg.get_value("unlocked", id, 0))


func _save() -> void:
	if debug:
		return
	var cfg := ConfigFile.new()
	for id: String in unlocked:
		cfg.set_value("unlocked", id, unlocked[id])
	if cfg.save(PATH) != OK:
		push_warning("Erfolge ließen sich nicht speichern (%s)" % PATH)


# --- Debug ------------------------------------------------------------------------------------

## --erfolg=<id>|alle: einen Erfolg freischalten und einblenden (alle: still, fürs Spielmenü) – im Debug-Start nur für
## die Sitzung. --erfolge-zurueck: alle Erfolge im Profil löschen.
func debug_command(arg: String) -> bool:
	if arg == "--erfolge-zurueck":
		unlocked.clear()
		_queue.clear()
		DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))
		print("[Erfolg] alle zurückgesetzt")
		return true
	var id := arg.substr(9)
	if id == "alle":
		for key: String in LIST:
			unlocked[key] = int(Time.get_unix_time_from_system())
		return true
	if not LIST.has(id):
		return false
	unlocked.erase(id)
	unlock(id)
	return true
