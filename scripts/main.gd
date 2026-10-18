extends Node3D
## Prototyp „Zimmer 13“ – baut Umgebung, Level, Spieler, Monster und UI zusammen.
## Wird vom Titelbildschirm gestartet: neues Spiel (Game.new_game_slot) oder Laden
## eines Spielstands (Game.pending_load → SaveManager.apply nach dem Aufbau).
##
## Debug-Startparameter (nach „--“ an Godot übergeben; ohne Titelbildschirm). Im Spiel dieselben Befehle
## ohne „--“ in der Debug-Konsole ([^]/F1, DebugConsole) – ausgeführt von run_debug():
##   --load=n                    Spielstand n laden (0 = Autosave)
##   --savetest                  Speichern → Laden → Vergleichen (Ausgabe in der Konsole)
##   --diary=n                   nach 2 s wie am Tagebuch in Slot n speichern
##   --day=n                     zu Tag n im Oktober springen
##   --attacks=n                 so viele Angriffe gab es schon (> 2: es holt jemanden)
##   --first-attack              Feier starten, kurz darauf der erste Angriff
##   --knock [--knock-fake] [--answer]   Klopfen an Zimmer 13 (falsche Stimme / Tür öffnen)
##   --call=id|creepy|dead|door [--answer]  Telefon in Zimmer 13 klingelt (Gast, Atmen, Verschwundener,
##                               vor der Tür) – mit --answer nimmt der Spieler nach 4 s ab
##   --dial=n|lobby              vom Telefon in Zimmer 13 aus Zimmer n anrufen (0 = Rezeption) ·
##                               lobby: Wählseite am Haupttelefon mit Gästeverzeichnis
##   --menu=name                 nach 1 s ein Menü öffnen (pause, diary, settings, load, controls)
##   --title                     trotz Parametern mit dem Titelbildschirm starten
##   --pos=x,y,z[,blickwinkel[,neigung]]   Spieler versetzen (Neigung in Grad, positiv = nach oben)
##   --tp=ort|zimmer|gast        hinspringen: Ort der F6-Liste (lobby, keller …), Zimmernummer, vor einen Gast
##   --time=+n|-n                Spieltage vor- oder zurückspulen
##   --load-slot=n               Spielstand n laden, auch mitten im Spiel (Konsole: load n; save n = --diary=n)
##   --console[=befehl;befehl]   Debug-Konsole nach 1 s öffnen und Befehle eintippen (für Screenshots)
##   --monster=x,y,z             Monster sofort an dieser Stelle zeigen
##   --pocket                    Kompass, alle Kartenblätter und Schlüssel 18 einstecken
##   --flashlight[=uv]           eingeschaltete Taschenlampe mit voller Batterie in die Hand (uv: mit UV-Aufsatz, im UV-Modus)
##   --show=map|keys|compass     Karte (bzw. Schlüsselblatt) oder Kompass hervorholen (wie Tab/F halten)
##   --no-psx                    ohne PS1-Look (wie Einstellungen → PS1-Look aus, wird nicht gespeichert)
##   --debug                     Debug-Werte einblenden
##   --nointro                   ohne Einführungstext
##   --trace                     Monster-Zustand alle 2 s und jedes Lärmereignis in die Konsole schreiben
##   --noise=art                 alle 6 s Lärm dieser Art am Spieler (door, hide, run, scream … – Senses.NOISE)
##   --warn                      sofort Vorwarnung → Monster erscheint
##   --ghost=n|flur|schrank      Lakengeist zum n. Mal: Zimmer 13, Licht aus, Vorhang auf, er kommt sicher (4.18) ·
##                               flur: alle Gäste schlafen sofort, er kommt im Flur (Spieler vorher mit --pos hinstellen)
##                               schrank: kommt in Zimmer 13 herein, du versteckst dich sofort im Schrank – er
##                               wartet davor (mit --trace: Wartezeit, Chance, ob er hineinfliegt)
##   --sleep[=bett]              Nachtruhe sofort beginnen (Gäste gehen ins Bett) · bett: alle liegen sofort,
##                               du schläfst im Bett von Zimmer 13
##   --awake=n                   so viele Nächte ohne Schlaf (Lakengeist häufiger, ab 3 sicher im Flur; 4.18) –
##                               der erste Angriff gilt dann als geschehen
##   --intent=roam|one|rampage|n Absicht beim Aufbruch erzwingen (umsehen, 1 oder 2 Opfer, oder n Opfer; 4.17)
##   --bold=n                    Dreistigkeit setzen (0–100)
##   --friend=id                 mit einem Gast befreundet starten (edna, bruno, mila, gast1 …)
##   --kill=id                   Gast nach 3 s vom Monster holen lassen
##   --party                     sofort eine Feier in der Lobby starten
##   --cat=id                    Hotelkatze vor den Spieler setzen (minka, socke, kasimir)
##   --talk=id                   direkt ein Gespräch mit dem Gast öffnen
##   --look=id[,pose]            Gast ansehen (ohne Dialog, er bleibt stehen); pose: carry (trägt einen Kürbis),
##                               panic (Arme hoch), dance (tanzt), sit (sitzt), walk (geht quer vorbei) –
##                               zum Prüfen der Gastmodelle
##   --shock=id[,blood|corpse|ghostN]  Gast erschrecken (6.12): Blutlache bzw. Leiche vor ihm im Flur, oder der
##                               Lakengeist kommt zum N. Mal an sein dunkles Zimmerfenster (ab 3 würgt er) –
##                               mit --talk=id erzählt er danach davon
##   --dice=id                   sofort Mäxchen mit dem Gast (Einsatz 3 Geld)
##   --chess=id                  sofort Schach mit dem Gast in der Lobby (Einsatz 3 Geld; mit --autoplay zieht der Spieler selbst)
##   --challenge=id[,chess]      Gast fordert dich heraus (Mäxchen bzw. Schach)
##   --autoplay                  Mäxchen-Antworten bzw. Schachzüge automatisch wählen
##   --shot=pfad.png             Screenshot speichern und beenden
##   --frames=n                  Frames bis zum Screenshot (Standard 120)
##   --shot-on=reveal|jumpscare|strangle|shock  Screenshot kurz nach einem Ereignis statt nach n Frames
##   --bg                        Fenster im Hintergrund: kein Fokus, außerhalb des Bildschirms (Game._to_background)

## Der Anfang wirkt friedlich – nichts deutet auf das Monster hin (Spielkonzept 2.1).
const INTRO := "Willkommen im Hotel – zur Halloween-Woche! Heute ist der 1. Oktober.\nLerne die anderen Gäste kennen, schmücke deine Tür und feiere mit.\nDein Tagebuch liegt auf dem Schreibtisch in Zimmer 13.\n\n[WASD] Laufen  [Shift] Rennen  [Leertaste] Springen  [Strg] Ducken\n[E] Nehmen / Benutzen  [G] Ablegen  [Rechtsklick] Luft anhalten  [Esc] Menü"
const START_ENTRY := "Ich bin in Zimmer 13 aufgewacht. Die Tür nach draußen ist verriegelt."

var _post: ShaderMaterial

var _trace := false
var _trace_frames := 0
var _autoplay := false


func _ready() -> void:
	Game.reset()
	_setup_environment()

	var level := NavigationRegion3D.new()
	level.name = "Level"
	add_child(level)
	var builder := LevelBuilder.new(level, self)
	builder.build()
	_bake_navigation(level)

	var audio := SynthAudio.new()
	audio.name = "SynthAudio"
	add_child(audio)
	Game.audio = audio

	var shadows := ShadowBudget.new()
	shadows.name = "ShadowBudget"
	add_child(shadows)

	var traces := Traces.new()
	traces.name = "Traces"
	add_child(traces)
	Game.traces = traces

	var player := Player.new()
	player.name = "Player"
	player.position = builder.player_spawn
	add_child(player)
	Game.player = player

	var monster := Monster.new()
	monster.name = "Monster"
	add_child(monster)
	Game.monster = monster

	var ghost := SheetGhost.new()
	ghost.name = "SheetGhost"
	add_child(ghost)
	Game.ghost = ghost

	var director := MonsterDirector.new()
	director.name = "MonsterDirector"
	add_child(director)
	director.setup(builder, monster)
	_post = _setup_post_fx()
	director.post_material = _post
	Game.director = director
	Settings.changed.connect(_apply_settings)
	_apply_settings()

	var social := Social.new()
	social.name = "Social"
	add_child(social)
	Game.social = social
	social.setup(builder, self)

	# Hotelkatzen (6.11) – nach den Gästen, sie suchen sich einen Lieblingsgast
	for cat_id in HotelCat.PROFILES:
		var cat := HotelCat.new().setup(cat_id, builder)
		cat.name = "Katze_" + cat_id
		add_child(cat)
		cat.place_at_start()

	var dialog := DialogUI.new()
	dialog.name = "Dialog"
	add_child(dialog)
	Game.dialog = dialog

	var phones := PhoneCalls.new()
	phones.name = "PhoneCalls"
	add_child(phones)
	phones.setup()
	Game.phones = phones

	var dice := DiceMatch.new()
	dice.name = "DiceMatch"
	dice.table = builder.game_table
	add_child(dice)
	Game.dice = dice

	var chess := ChessMatch.new()
	chess.name = "ChessMatch"
	chess.table = builder.chess_table
	add_child(chess)
	Game.chess = chess

	var hud := Hud.new()
	hud.name = "Hud"
	add_child(hud)
	Game.hud = hud

	var menus := Menus.new()
	menus.name = "Menus"
	add_child(menus)
	Game.menus = menus

	var teleport := TeleportUI.new()   # nach den Menüs: bekommt Esc/F6 zuerst
	teleport.name = "Teleport"
	add_child(teleport)
	teleport.setup(builder)

	if DebugConsole.enabled():   # Befehle wie die Startparameter, im Spiel getippt
		var console := DebugConsole.new()
		console.name = "DebugConsole"
		add_child(console)
		console.setup(run_debug)

	Game.player_died.connect(_on_player_died)
	if not Game.pending_load.is_empty():
		_load_pending.call_deferred()
	else:
		SaveManager.visited = []
		SaveManager.last_save_msec = -1
		if not "--nointro" in OS.get_cmdline_user_args():
			Game.say(INTRO, 12.0)
		if Game.new_game_slot > 0:
			_save_start.call_deferred(Game.new_game_slot)
		Game.new_game_slot = 0
	_parse_debug_args.call_deferred()


func _load_pending() -> void:
	var data := Game.pending_load
	Game.pending_load = {}
	SaveManager.apply(data)
	Game.say("„%s“" % String(data.get("text", "")), 5.0)


## Neues Spiel in einem Slot: Startzustand gleich speichern, damit „Fortsetzen“ greift.
func _save_start(slot: int) -> void:
	for i in 3:
		await get_tree().process_frame
	SaveManager.save_to(slot, START_ENTRY, get_viewport().get_texture().get_image())


func _apply_settings() -> void:
	if _post:
		_post.set_shader_parameter("gamma", Settings.gamma)
		_post.set_shader_parameter("dither", 1.0 if Settings.dither_on() else 0.0)
		_post.set_shader_parameter("color_levels", 28.0 if Settings.psx_look else 255.0)


func _process(_delta: float) -> void:
	if _autoplay and Engine.get_process_frames() % 100 == 0 and Game.dice.active:
		print("[Mäxchen] " + Game.dice.debug_press_random())
	if _autoplay and Engine.get_process_frames() % 30 == 0 and Game.chess.active:
		var step := Game.chess.debug_step()
		if step != "":
			print("[Schach] " + step)
	if _trace:
		_trace_frames += 1
		if _trace_frames % 120 == 0:
			print("[%ds] Monster %s @ %s | Phase %s | Dreistigkeit %.1f" % [_trace_frames / 60,
				Monster.State.keys()[Game.monster.state], Game.monster.global_position.snapped(Vector3.ONE * 0.1),
				MonsterDirector.Phase.keys()[Game.director.phase], Game.director.effective_boldness()])
			print("      Spieler @ %s | Schock %.2f | Geld %d | Hand: %s" % [Game.player.global_position.snapped(Vector3.ONE * 0.1), Game.player.shock, Game.money, Game.player.held.display_name if Game.player.held else "-"])
			for guest in Game.social.guests:
				print("      %s: %s @ %s | Angst %.0f | Beziehung %.0f | Hand: %s" % [guest.display_name,
					Guest.State.keys()[guest.state], guest.global_position.snapped(Vector3.ONE * 0.1), guest.fear,
					guest.relation, guest.held.display_name if guest.held else "-"])
				if "--trace-nav" in OS.get_cmdline_user_args():
					print("        Ziel %s  nächster Punkt %s  fertig %s" % [guest.get("_target"), guest.agent.get_next_path_position(), guest.agent.is_navigation_finished()])


func _setup_environment() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color.BLACK
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.35, 0.38, 0.5)
	env.ambient_light_energy = 0.1   # ohne Deckenlampen: dunkle Ecken bleiben als Umriss erkennbar
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.fog_enabled = true
	env.fog_light_color = Color(0.02, 0.02, 0.03)
	# Nebel nach Entfernung: ab 4 m dichter, bei 66 m schwarz (Flurende verschwindet im Dunkel statt im Dunst)
	env.fog_mode = Environment.FOG_MODE_DEPTH
	env.fog_density = 1.0
	env.fog_depth_begin = 4.0
	env.fog_depth_end = 66.0
	env.fog_depth_curve = 0.6
	# Lichtschein im Dunst: Lampen werfen sichtbare Lichtkegel, dazwischen bleibt es finster
	env.volumetric_fog_enabled = true
	env.volumetric_fog_density = 0.0175
	env.volumetric_fog_albedo = Color(0.6, 0.6, 0.65)
	env.volumetric_fog_length = 12.0   # nur nah: weiter hinten würde das Lampenlicht den Flur beige verschleiern
	var world_env := WorldEnvironment.new()
	world_env.environment = env
	add_child(world_env)
	# Schwaches Mondlicht – erhellt den Garten und fällt durch die Lobbyfenster
	var moon := DirectionalLight3D.new()
	moon.light_color = Color(0.55, 0.65, 1.0)
	moon.light_energy = 0.18
	moon.shadow_enabled = true
	moon.directional_shadow_max_distance = 40.0
	moon.rotation = Vector3(deg_to_rad(-55.0), deg_to_rad(-30.0), 0.0)
	add_child(moon)


## NavMesh zur Laufzeit backen: nur statische Kollision auf Ebene 1
## (Wände, Böden, Möbel). Türen (Ebene 2) bleiben offen für die Wegplanung.
func _bake_navigation(region: NavigationRegion3D) -> void:
	var nav_mesh := NavigationMesh.new()
	nav_mesh.cell_size = 0.1
	nav_mesh.cell_height = 0.1
	nav_mesh.agent_radius = 0.3
	nav_mesh.agent_height = 1.6
	nav_mesh.agent_max_climb = 0.2
	nav_mesh.geometry_parsed_geometry_type = NavigationMesh.PARSED_GEOMETRY_STATIC_COLLIDERS
	nav_mesh.geometry_collision_mask = 1
	region.navigation_mesh = nav_mesh
	region.bake_navigation_mesh(false)


func _setup_post_fx() -> ShaderMaterial:
	var layer := CanvasLayer.new()
	layer.name = "PostFx"
	layer.layer = 5
	add_child(layer)
	var material := ShaderMaterial.new()
	material.shader = load("res://shaders/psx_post.gdshader")
	var rect := ColorRect.new()
	rect.material = material
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(rect)
	rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	return material


func _on_player_died() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	add_child(DeathScreen.new())


func _parse_debug_args() -> void:
	var args := OS.get_cmdline_user_args()
	for arg in args:   # vor allem, was einen Aufbruch auslöst (--warn …)
		if arg.begins_with("--intent=") or arg == "--no-psx":
			run_debug(arg)
	for arg in args:
		if not (arg.begins_with("--intent=") or arg == "--no-psx"):
			run_debug(arg)


## Einen Debug-Befehl ausführen – beim Start für jeden Parameter, im Spiel aus der Debug-Konsole
## (DebugConsole, dort ohne „--“ getippt). false = unbekannt. Neuer Befehl: hier ein Zweig, eine Zeile
## im Kopfkommentar, in DebugConsole.COMMANDS und in der README.
func run_debug(arg: String) -> bool:
	if arg.begins_with("--intent="):
		var wanted := arg.substr(9)
		Game.director.debug_victims = wanted.to_int() if wanted.is_valid_int() else ["roam", "one", "rampage"].find(wanted)
	elif arg == "--no-psx":
		Settings.psx_look = false
		Settings.apply()
	elif arg.begins_with("--tp="):
		return _debug_teleport(arg.substr(5))
	elif arg.begins_with("--time="):
		# Spieltage vor- oder zurückspulen (+1, -2 …)
		Game.director.elapsed = maxf(0.0, Game.director.elapsed + arg.substr(7).to_float() * Calendar.DAY_SECONDS)
		Game.say(Calendar.date_text(Game.director.elapsed), 2.0)
	elif arg.begins_with("--console"):
		# Konsole nach 1 s öffnen, optional Befehle (mit ; getrennt) eintippen
		var console := get_node_or_null("DebugConsole") as DebugConsole
		if console == null:
			return false
		get_tree().create_timer(1.0).timeout.connect(func() -> void:
			console.open()
			for line in arg.substr(10).split(";", false):
				console.submit(line))
	elif arg.begins_with("--load-slot="):
		SaveManager.load_slot(arg.substr(12).to_int())
	elif arg.begins_with("--pos="):
		var v := arg.substr(6).split(",")
		Game.player.global_position = Vector3(v[0].to_float(), v[1].to_float(), v[2].to_float())
		if v.size() > 3:
			Game.player.rotation.y = deg_to_rad(v[3].to_float())
		if v.size() > 4:
			Game.player.head.rotation.x = deg_to_rad(v[4].to_float())
	elif arg.begins_with("--monster="):
		var m := arg.substr(10).split(",")
		var pos := Vector3(m[0].to_float(), m[1].to_float(), m[2].to_float())
		Game.monster.spawn_at(pos)
		Game.director.phase = MonsterDirector.Phase.ACTIVE
	elif arg == "--pocket":
		Game.player.give_compass()
		for page in HotelMap.PAGES:
			Game.player.add_map_page(page["id"])
		Game.player.add_key("zimmer_18")
	elif arg.begins_with("--flashlight"):
		var uv := arg == "--flashlight=uv"
		var lamp := Item.create(Item.Kind.FLASHLIGHT, "c=1;on" + (";uv;m=uv" if uv else ""))
		Game.player.drop_held()
		Game.player.receive_item(lamp)
	elif arg.begins_with("--show="):
		Game.player.debug_show = arg.substr(7)
	elif arg.begins_with("--bold="):
		Game.director.boldness = arg.substr(7).to_float()
	elif arg.begins_with("--friend="):
		var friend := Game.social.guest_by_id(arg.substr(9))
		if friend:
			friend.relation = 80.0
	elif arg.begins_with("--kill="):
		var victim := Game.social.guest_by_id(arg.substr(7))
		Game.director.attacks = MonsterDirector.HARMLESS_ATTACKS + 1   # wirklich holen
		get_tree().create_timer(3.0).timeout.connect(func() -> void:
			Game.monster.spawn_at(victim.global_position + Vector3(1, 0, 0))
			Game.director.phase = MonsterDirector.Phase.ACTIVE
			Game.director.kill_guest(victim, null))
	elif arg == "--steal-test":
		# Spieler nimmt Ednas Deko unbemerkt (für Schuld-Test)
		for node in get_tree().get_nodes_in_group("items"):
			if node.owner_id == "edna":
				Game.player.try_pick_up(node)
				break
	elif arg.begins_with("--enemy="):
		var enemy := Game.social.guest_by_id(arg.substr(8))
		if enemy:
			enemy.relation = -80.0
	elif arg.begins_with("--player-deco="):
		var xz := arg.substr(14).split(",")
		var deco := Item.create(Item.Kind.CARVED_PUMPKIN)
		deco.owner_id = "player"
		deco.position = Vector3(xz[0].to_float(), 0.02, xz[1].to_float())
		add_child(deco)
	elif arg.begins_with("--dice="):
		var opponent := Game.social.guest_by_id(arg.substr(7))
		get_tree().create_timer(0.5).timeout.connect(func() -> void:
			Game.dice.start(opponent, {"money": 3, "item": false}))
	elif arg.begins_with("--chess="):
		var chess_opponent := Game.social.guest_by_id(arg.substr(8))
		get_tree().create_timer(0.5).timeout.connect(func() -> void:
			Game.chess.start(chess_opponent, {"money": 3, "item": false}))
	elif arg.begins_with("--challenge="):
		var challenger := Game.social.guest_by_id(arg.substr(12).split(",")[0])
		Game.social.challenge(challenger, "chess" if arg.ends_with(",chess") else "dice")
	elif arg == "--autoplay":
		_autoplay = true
	elif arg.begins_with("--cat="):
		# Katze vor den Spieler setzen (sitzt, zum Streicheln)
		for cat in get_tree().get_nodes_in_group("cats"):
			if cat.id == arg.substr(6):
				cat.place_in_front_of(Game.player)
	elif arg == "--party":
		Game.social.start_party("player")
	elif arg.begins_with("--look="):
		var parts := arg.substr(7).split(",")
		var guest := Game.social.guest_by_id(parts[0])
		_debug_look(guest, parts[1] if parts.size() > 1 else "")
	elif arg.begins_with("--shock="):
		var parts := arg.substr(8).split(",")
		_debug_shock(Game.social.guest_by_id(parts[0]), parts[1] if parts.size() > 1 else "blood")
	elif arg.begins_with("--talk="):
		var partner := Game.social.guest_by_id(arg.substr(7))
		var after_shock := Array(OS.get_cmdline_user_args()).any(func(a: String) -> bool: return a.begins_with("--shock="))
		if not after_shock:
			Game.player.global_position = partner.global_position + Vector3(0, 0, -1.4)
			Game.player.rotation.y = 0.0
		get_tree().create_timer(8.0 if after_shock else 1.0).timeout.connect(func() -> void:
			if after_shock:   # erst erschrecken lassen, dann hingehen
				var front := -partner.global_transform.basis.z
				Game.player.global_position = partner.global_position + front * 1.4
			var to := partner.global_position - Game.player.global_position
			Game.player.rotation.y = atan2(-to.x, -to.z)
			Game.dialog.open(partner))
	elif arg == "--ghost=flur":
		Game.ghost.debug_summon_hall()
	elif arg == "--ghost=schrank":
		# kommt durch den Vorhang herein – du versteckst dich gleich im Schrank von Zimmer 13
		var room: Dictionary = Game.director.rooms["13"]
		Game.player.global_position = (room["center"] as Vector3) + Vector3(0, 0.05, 0)
		Game.ghost.debug_summon(4, "13")
		get_tree().create_timer(1.5).timeout.connect(func() -> void:
			for spot in room["spots"]:
				if (spot as HideSpot).type == HideSpot.Type.WARDROBE and Game.player.hiding == null:
					Game.player.enter_hide(spot))
	elif arg.begins_with("--awake="):
		# so viele Nächte ohne Schlaf (zählen erst nach dem ersten Angriff, also gilt der als geschehen)
		Game.director.first_attack_done = true
		Game.player.nights_awake = arg.substr(8).to_int()
	elif arg == "--sleep":
		Game.social.start_sleep()
	elif arg == "--sleep=bett":
		# alle Gäste sofort im Bett, du schläfst im Bett von Zimmer 13
		Game.social.start_sleep(true)
		for spot in Game.director.rooms["13"]["spots"]:
			if (spot as HideSpot).own_bed:
				Game.player.start_sleep(spot)
	elif arg.begins_with("--ghost="):
		var room: Dictionary = Game.director.rooms["13"]
		Game.player.global_position = (room["center"] as Vector3) + Vector3(0, 0.05, 0)
		Game.ghost.debug_summon(arg.substr(8).to_int(), "13")
	elif arg == "--warn":
		Game.director.start_warning()
	elif arg.begins_with("--attacks="):
		# so viele Angriffe gab es schon (über 2 = gefährlich)
		Game.director.first_attack_done = true
		Game.director.attacks = arg.substr(10).to_int()
	elif arg == "--first-attack":
		# Feier starten, kurz darauf der erste Angriff
		Game.social.start_party("mila")
		get_tree().create_timer(3.0).timeout.connect(Game.director._first_attack_at_party)
	elif arg == "--knock":
		# Klopfen an Zimmer 13 vorbereiten (Spieler steht im Zimmer, Monster ist unterwegs)
		Game.director.first_attack_done = true
		Game.player.global_position = (Game.social.builder.rooms["13"]["center"] as Vector3) + Vector3(0, 0.05, -0.6)
		Game.monster.spawn_at(Vector3(24.0, 0.05, 0.0))
		Game.social._knock_cooldown = 1.0
		Game.social.debug_fake_knock = "--knock-fake" in OS.get_cmdline_user_args()
		if "--answer" in OS.get_cmdline_user_args():
			# nach 4 s öffnet der Spieler die Tür
			get_tree().create_timer(4.0).timeout.connect(func() -> void:
				(Game.social.builder.rooms["13"]["door"] as Door).set_open(true))
	elif arg.begins_with("--call=") or arg.begins_with("--dial="):
		# Telefon: Spieler steht in Zimmer 13 vor dem Schreibtisch und sieht auf den Apparat
		var phone_pos := Game.phones.home_phone.global_position
		Game.player.global_position = Vector3(phone_pos.x, 0.05, phone_pos.z + 0.9)
		Game.player.rotation.y = 0.0
		Game.player.head.rotation.x = -0.75
		var value := arg.substr(7)
		get_tree().create_timer(1.0).timeout.connect(func() -> void:
			if arg.begins_with("--call="):
				Game.phones.debug_call(value)
				if "--answer" in OS.get_cmdline_user_args():
					get_tree().create_timer(4.0).timeout.connect(func() -> void:
						Game.phones.answer(Game.phones.home_phone))
			else:
				Game.phones.debug_dial(value))
	elif arg == "--trace":
		_trace = true
		Game.noise_trace = true
		Game.message_posted.connect(func(text: String, _d: float) -> void: print("  » " + text.replace("
", " ")))
	elif arg.begins_with("--noise="):
		var kind := arg.substr(8)
		var timer := Timer.new()
		timer.wait_time = 6.0
		timer.autostart = true
		timer.timeout.connect(func() -> void:
			if Game.player:
				Game.noise(kind, Game.player.global_position, Game.player))
		add_child(timer)
	elif arg == "--debug":
		Game.hud.debug_enabled = true
	elif arg.begins_with("--day="):
		# zu einem Tag im Oktober springen (1–31)
		Game.director.elapsed = (clampi(arg.substr(6).to_int(), 1, Calendar.HALLOWEEN) - 1) * Calendar.DAY_SECONDS
	elif arg.begins_with("--bulb-thief="):
		# Gast klaut sofort eine Glühbirne aus Zimmer 13
		var thief := Game.social.guest_by_id(arg.substr(13))
		var lamp := thief._bulb_to_steal(true)
		if lamp:
			thief._steal_lamp = lamp
			thief._walk_to(Vector3(lamp.global_position.x, 0, lamp.global_position.z) + thief._toward_room(lamp), Guest.State.STEAL)
	elif arg.begins_with("--diary="):
		# wie am Tagebuch speichern (nach 2 s)
		var slot := arg.substr(8).to_int()
		get_tree().create_timer(2.0).timeout.connect(func() -> void:
			var ok := SaveManager.save_to(slot, SaveManager.diary_sentence(), get_viewport().get_texture().get_image())
			print("[diary] Slot %d gespeichert: %s – „%s“" % [slot, ok, SaveManager.diary_sentence()]))
	elif arg.begins_with("--menu="):
		# Menü für Screenshots öffnen: pause, diary, settings, load, controls
		var which := arg.substr(7)
		get_tree().create_timer(1.0).timeout.connect(func() -> void:
			if which == "diary":
				Game.menus.open_diary()
			else:
				Game.menus.open_pause()
				if which != "pause":
					Game.menus.call("_show_" + which))
	elif arg == "--savetest":
		get_tree().create_timer(6.0).timeout.connect(_save_test)
	else:
		return false
	return true


## --tp: zu einem Ort aus der F6-Liste (lobby, bar, küche, keller …), in ein Zimmer (Nummer) oder vor einen Gast.
func _debug_teleport(where: String) -> bool:
	var p := Game.player
	var guest := Game.social.guest_by_id(where)
	if guest and not guest.dead:
		var front := -guest.global_transform.basis.z
		_place_player(guest.global_position + front * 1.6, -front)
		return true
	var rooms: Dictionary = Game.social.builder.rooms
	if rooms.has(where):
		_place_player(rooms[where]["center"], -(rooms[where]["into"] as Vector3))
		return true
	var entry := (get_node("Teleport") as TeleportUI).find(where)
	if entry.is_empty():
		return false
	if p.hiding:
		p.exit_hide()
	(get_node("Teleport") as TeleportUI).go_to(entry)
	return true


func _place_player(pos: Vector3, look: Vector3) -> void:
	var p := Game.player
	if p.hiding:
		p.exit_hide()
	p.global_position = pos + Vector3(0, 0.05, 0)
	p.velocity = Vector3.ZERO
	p.rotation = Vector3(0, atan2(-look.x, -look.z), 0)
	p.head.rotation.x = 0.0


## --savetest: Speichern und Laden ohne Datei durchspielen und Unterschiede ausgeben.
## --look: Spieler vor den Gast (in dessen Blickrichtung), der Gast bleibt stehen und schaut her.
## pose stellt eine Haltung nach, damit man die Gastmodelle prüfen kann (Spielkonzept 6.0).
func _debug_look(guest: Guest, pose: String) -> void:
	guest.state = Guest.State.TALKING
	guest.velocity = Vector3.ZERO
	var forward := -guest.global_transform.basis.z
	Game.player.global_position = guest.global_position + forward * 2.4
	Game.player.rotation.y = atan2(forward.x, forward.z)
	match pose:
		"walk":
			guest._walk_to(guest.global_position + forward.cross(Vector3.UP) * 2.0, Guest.State.WALK)
		"carry":
			guest._take_into_hand(Item.create(Item.Kind.PUMPKIN))
		"panic":
			guest.running = true
		"dance":
			guest.state = Guest.State.PARTY
			guest._target = guest.global_position
		"sit":
			guest.state = Guest.State.MINIGAME
			guest.seated = true


## --shock (Spielkonzept 6.12): Gast erschrecken lassen. blood/corpse: Er steht im Flur vor seiner Tür, 2,5 m
## vor ihm liegt eine Blutlache bzw. ein anderer Gast (erwürgt), der Spieler steht dahinter und sieht zu.
## ghostN: Er steht im dunklen Zimmer, der Lakengeist kommt zum N. Mal (ab 3 würgt er), der Spieler sieht
## aus der Zimmerecke zu (zählt dabei nicht als Zeuge).
func _debug_shock(guest: Guest, what: String) -> void:
	var home := guest.home
	var along: Vector3 = home["along"]
	var into: Vector3 = home["into"]
	guest.velocity = Vector3.ZERO
	guest._set_idle(60.0)
	if what.begins_with("ghost"):
		var center: Vector3 = home["center"]
		guest.global_position = center + into * 0.8 + Vector3(0, 0.05, 0)
		guest.rotation.y = atan2(-into.x, -into.z)
		Game.player.global_position = center - into * 1.6 + along * 1.4 + Vector3(0, 0.05, 0)
		var look := center + into * 2.5 - Game.player.global_position
		Game.player.rotation.y = atan2(-look.x, -look.z)
		Game.player.head.rotation.x = -0.2
		Game.ghost.debug_summon_guest(guest, maxi(1, what.substr(5).to_int()))
		return
	var front: Vector3 = home["door_front"]
	# in die Flurrichtung, in der 6 m frei sind
	var ray := PhysicsRayQueryParameters3D.create(front + Vector3.UP, front + Vector3.UP + along * 6.0, 1)
	if not get_world_3d().direct_space_state.intersect_ray(ray).is_empty():
		along = -along
	guest.global_position = front + Vector3(0, 0.05, 0)
	guest.rotation.y = atan2(-along.x, -along.z)
	var spot := front + along * 2.5
	if what == "corpse":
		for other in Game.social.living_guests():
			if other != guest and other.gen_seed >= 0:
				other.global_position = spot
				other.rotation.y = atan2(-into.x, -into.z)
				other.die("ghost")
				break
	else:
		Game.traces.add_blood(spot, 0.4)
	Game.player.global_position = front + along * 4.2 + Vector3(0, 0.05, 0)
	var to := front + Vector3.UP * 0.8 - Game.player.global_position
	Game.player.rotation.y = atan2(-to.x, -to.z)
	Game.player.head.rotation.x = -0.25


func _save_test() -> void:
	# Etwas Unordnung, damit der Test mehr abdeckt: Vorhang zu, Licht aus, Birne in der Hand
	(get_tree().get_nodes_in_group("windows").filter(func(w: Node) -> bool: return w.has_curtains())[0] as HotelWindow).set_closed(true)
	LightSwitch.find(get_tree(), "keller").set_on(false)
	var lamp: Lamp = get_tree().get_nodes_in_group("lamp_fixtures").filter(func(l: Node) -> bool: return l.room_id == "15")[0]
	if Game.player.held == null:
		Game.player.receive_item(lamp.take_bulb())
	await get_tree().create_timer(0.5).timeout
	var before: Dictionary = JSON.parse_string(JSON.stringify(SaveManager.collect()))
	SaveManager.apply(before)
	await get_tree().physics_frame
	await get_tree().process_frame
	var after: Dictionary = JSON.parse_string(JSON.stringify(SaveManager.collect()))
	var problems := 0
	for key in before:
		if key == "saved_at":
			continue
		if not _same(before[key], after.get(key)):
			problems += 1
			if before[key] is Array and after.get(key) is Array and before[key].size() == after[key].size():
				for i in before[key].size():
					if not _same(before[key][i], after[key][i]):
						print("[savetest]   %s[%d]: %s → %s" % [key, i, JSON.stringify(before[key][i]), JSON.stringify(after[key][i])])
				continue
			if before[key] is Array:
				var kinds := func(list: Array) -> String:
					return ", ".join(list.map(func(e) -> String: return "%s@%s" % [e.get("kind"), str(e.get("pos"))]))
				print("[savetest]   vorher  %d: %s\n[savetest]   nachher %d: %s" % [before[key].size(), kinds.call(before[key]), after[key].size(), kinds.call(after[key])])
				continue
			if before[key] is Dictionary and after.get(key) is Dictionary:
				for sub in before[key]:
					if not _same(before[key][sub], after[key].get(sub)):
						print("[savetest]   %s.%s: %s → %s" % [key, sub, JSON.stringify(before[key][sub]).left(600), JSON.stringify(after[key].get(sub)).left(600)])
				continue
			print("[savetest] Unterschied in „%s“:\n  vorher  %s\n  nachher %s" % [key,
				JSON.stringify(before[key]).left(400), JSON.stringify(after.get(key)).left(400)])
	print("[savetest] %d Gegenstände, %d Gäste, %d Spuren, Angriffe %d – %s" % [(before["items"] as Array).size(), (before["guests"] as Dictionary).size(),
		(before["traces"] as Array).size(), int(before["director"]["state"]["attacks"]),
		"alles gleich" if problems == 0 else "%d Unterschiede" % problems])


## Gleich bis auf kleine Zahlenabweichungen (zwischen den Messungen vergeht ein Frame).
func _same(a, b) -> bool:
	if typeof(a) == TYPE_FLOAT or typeof(a) == TYPE_INT:
		return (typeof(b) == TYPE_FLOAT or typeof(b) == TYPE_INT) and absf(float(a) - float(b)) < 2.0
	if typeof(a) != typeof(b):
		return false
	if a is Array:
		if a.size() != b.size():
			return false
		for i in a.size():
			if not _same(a[i], b[i]):
				return false
		return true
	if a is Dictionary:
		if a.size() != b.size():
			return false
		for k in a:
			if not b.has(k) or not _same(a[k], b[k]):
				return false
		return true
	return a == b
