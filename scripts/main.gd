extends Node3D
## Prototyp „Zimmer 13“ – baut Umgebung, Level, Spieler, Monster und UI zusammen.
## Wird vom Titelbildschirm gestartet: neues Spiel (Game.new_game_slot) oder Laden
## eines Spielstands (Game.pending_load → SaveManager.apply nach dem Aufbau).
##
## Debug-Startparameter (nach „--“ an Godot übergeben; ohne Titelbildschirm). Im Spiel dieselben Befehle
## ohne „--“ in der Debug-Konsole ([^]/F1, DebugConsole) – ausgeführt von run_debug():
##   --load=n                    Spielstand n laden (0 = Autosave; TitleScreen)
##   --new=n                     neues Spiel in Slot n (TitleScreen)
##   --savetest                  Speichern → Laden → Vergleichen (Ausgabe in der Konsole)
##   --diary=n                   nach 2 s wie am Tagebuch in Slot n speichern
##   --day=n                     zu Tag n im Oktober springen
##   --attacks=n                 so viele Angriffe gab es schon (> 2: nicht mehr harmlos, ob es holt, entscheidet die Tageskurve; sicher mit --intent)
##   --first-attack              Feier starten, kurz darauf der erste Angriff
##   --knock [--knock-fake] [--answer]   Klopfen an Zimmer 13 (falsche Stimme / Tür öffnen)
##   --trick[=kind]              Süßes oder Saures von Tür zu Tür (6.13): ein Kind (oder dieses) zieht sofort los und
##                               klopft an die nächsten Gästetüren (mit --trace: Türen, Süßes oder Saures)
##   --decorate[=gast][,hin]     Schmück-Aktion sofort (5.9): ein Gast (oder dieser) ruft auf, Gäste aus der Nähe holen
##                               Deko und hängen sie an eine Tür bzw. in den Flur · hin: du stehst davor (mit --trace:
##                               Stelle, Mitmacher, jedes Stück, Ende) · sonst Anruf in Zimmer 13, mit --answer nach 4 s abnehmen
##   --decorate=lobby[,gast][,hin]   Schmück-Aktion in der Lobby
##   --decorate=allein[,gast][,lobby][,hin]   ein Gast holt allein Deko aus einer Kiste und hängt sie in seinem Zimmer
##                               auf (lobby: aus dem Koffer in die Lobby; haus: irgendwohin ins Hotel, wo wenig hängt)
##   --decorate=gross[,gast][,lobby][,hin]   großes Schmücken (2026-10-21): 10–20 Gäste, mehrere Stellen eines
##                               Flurbereichs (bzw. der Lobby), jeder mit einem Armvoll Deko
##   --decorate=hier[,gast]      wie „Lass uns hier schmücken!“ im Gespräch: geschmückt wird, wo du stehst (mit --tp/--pos)
##   --search[=gast][,mit]       Deko-Suche (5.9): ein Gast (oder dieser) zieht los · mit: du gehst mit (er führt, du
##                               folgst ihm von selbst, er teilt am Fundort) – mit --trace: Fundort, Teilen, Beziehung
##   --cook=suppe|braten[,fertig]  Kochen (3.8): Kürbis liegt geschnitten im Topf bzw. in der Pfanne, du stehst am Herd ·
##                               fertig: gleich fertig (Suppe: Gäste kommen zum Essen)
##   --pals=gast1,gast2          Weitererzählen (6.16): gast1 ist mit dir befreundet, beide sind Freunde und stehen vor dir
##                               nebeneinander – gast1 erzählt gast2 gleich Gutes über dich (mit --trace: Beziehung)
##   --call=id|creepy|dead|door [--answer]  Telefon in Zimmer 13 klingelt (Gast, Atmen, Verschwundener,
##                               vor der Tür) – mit --answer nimmt der Spieler nach 4 s ab
##   --dial=n|lobby              vom Telefon in Zimmer 13 aus Zimmer n anrufen (0 = Rezeption) ·
##                               lobby: Wählseite am Haupttelefon mit Gästeverzeichnis
##   --menu=name                 nach 1 s ein Menü öffnen (pause, diary, settings, load, controls)
##   --title                     trotz Parametern mit dem Titelbildschirm starten
##   --pos=x,y,z[,blickwinkel[,neigung]]   Spieler versetzen (Neigung in Grad, positiv = nach oben)
##   --tp=ort|zimmer|gast        hinspringen: Ort der F6-Liste (lobby, partyraum, keller, obergeschoss, katzenraum …), jedes Zimmer (Nummer oder Türschild, auch oben und verschlossene), vor einen Gast
##   --time=+n|-n                Spieltage vor- oder zurückspulen
##   --load-slot=n               Spielstand n laden, auch mitten im Spiel (Konsole: load n; save n = --diary=n)
##   --console[=befehl;befehl]   Debug-Konsole nach 1 s öffnen und Befehle eintippen (für Screenshots)
##   --monster=x,y,z             Monster sofort an dieser Stelle zeigen
##   --lure                      nach 1 s kommt das Monster zu dir (wie F7; ruht es, erscheint es ~25 m entfernt)
##   --splash=x,z                nach 1 s platscht es dort im Pool (Wellenring, Schaum, Spritzer)
##   --pool=still|tremor|slosh   Poolwasser so, als wäre das Monster nah: glatt · zitternde Ringe · schwappt (off = wieder normal)
##   --pocket                    Kompass, alle Kartenblätter und Schlüssel 18 einstecken
##   --flashlight[=uv]           eingeschaltete Taschenlampe mit voller Batterie in die Hand (uv: mit UV-Aufsatz, im UV-Modus)
##   --bag[=a,b,…]               Kleines in die Tasche (3.2): süßes, cola, limo, zierkürbis, kerze, messer, batterie, birne,
##                               uv, würfel, becher – ohne Angabe Süßigkeiten, Cola, Zierkürbis und Batterie
##   --bag-menu[=n]              Tasche offen halten wie mit gehaltenem [Q], Fach n (1–6) gewählt – für Screenshots
##   --deco=art[,g]              Deko in die Hand (5.6, 5.7): gespenst, lichter, netz, laub, zierkürbis, fledermaus,
##                               spinne, totenkopf, besen – an eine Wand sehen
##                               und [G] zum Aufhängen bzw. Verstreuen · ,g: nach 1 s selbst [G] (mit --pos auf eine Wand)
##   --show=map|keys|compass     Karte (bzw. Schlüsselblatt) oder Kompass hervorholen (wie Tab/F halten)
##   --sprint · --winded         vorwärts rennen, bis die Ausdauer leer ist · gleich außer Atem starten (3.1) –
##                               mit --trace stehen „außer Atem“ und „beruhigt“ in der Konsole
##   --no-psx · --psx            ohne bzw. mit PS1-Look (wie der Schalter in den Einstellungen, wird nicht gespeichert)
##   --fps                       Bilder pro Sekunde einblenden (wie F10)
##   --debug                     Debug-Werte einblenden
##   --nointro                   ohne Einführungstext
##   --perf[=s]                  Frame-Zeiten nach temp/perf.csv schreiben, nach s Sekunden (Standard 20) beenden (PerfLog)
##   --trace                     Monster-Zustand alle 2 s und jedes Lärmereignis in die Konsole schreiben
##   --trace-nav                 mit --trace auch Ziel und Wegfindung jedes Gastes
##   --noise=art                 alle 6 s Lärm dieser Art am Spieler (door, hide, run, scream … – Senses.NOISE)
##   --warn                      sofort Vorwarnung → Monster erscheint
##   --ghost=n|flur|schrank|tür  Lakengeist sofort zum n. Mal am Außenfenster bzw. an der Fenstertür des Raums, in dem
##                               du stehst (beim Start Zimmer 13): Licht aus, Vorhang auf, Blick dorthin (4.18) · flur: alle Gäste
##                               schlafen sofort, er taucht in deinem Flur knapp 20 m vor dir auf und kommt (vorher mit
##                               --tp/--pos in einen Flur stellen) · schrank: kommt durch den Vorhang deines Zimmers
##                               herein, du versteckst dich sofort in dessen Schrank – er wartet davor (mit --trace:
##                               Wartezeit, Chance, ob er hineinfliegt) · tür: ein Lakengespenst hängt neben der Tür
##                               deines Zimmers (sonst Zimmer 13), er steht lautlos davor und hypnotisiert durch die
##                               Wand (5.6), mit --answer öffnest du nach 4 s · ohne Fenster bzw. Flur nur eine Meldung
##   --sleep[=bett]              Nachtruhe sofort beginnen (Gäste gehen ins Bett) · bett: alle liegen sofort,
##                               du schläfst im Bett von Zimmer 13
##   --awake=n                   so viele Nächte ohne Schlaf (Lakengeist häufiger, ab 3 sicher im Flur; 4.18) –
##                               der erste Angriff gilt dann als geschehen
##   --intent=roam|one|rampage|n Absicht beim Aufbruch erzwingen (umsehen, 1 oder 2 Opfer, oder n Opfer; 4.17)
##   --bold=n                    Dreistigkeit setzen (0–100)
##   --friend=id                 mit einem Gast befreundet starten (edna, bruno, mila, gast1 …)
##   --enemy=id                  mit einem Gast verfeindet starten
##   --relation=id,wert          Beziehung setzen (−100 … 100); ab ±80 werden die nötigen Taten mit eingetragen (6.3)
##   --follow=id · --visit=id    Gast kommt mit (steht hinter dir) · Gast geht zu Zimmer 13 und klopft an
##   --attack=id                 Gast steht vor dir und schlägt zu
##   --punch=id                  Gast vor dich stellen und ihn schlagen (mit Nachfrage)
##   --kill=id                   Gast nach 3 s vom Monster holen lassen (überlebt mit 40 %: Kratzer, 6.17)
##   --bulb-thief=id             Gast klaut sofort eine Glühbirne aus Zimmer 13
##   --steal-test                Ednas Deko unbemerkt nehmen (Schuld-Test)
##   --player-deco=x,z           geschnitzten Kürbis des Spielers an diese Stelle stellen
##   --weep=gast                 der Gast weint 30 s (Tränen, 7.6) – mit --look=gast steht er vor dir
##   --wound=gast,scratch|axe|choke[,hin]   Gast hat überlebt (6.17): Kratzer, Axtwunde (Blutspur, ein Tag im Bett) bzw.
##                               Würgemale (heiser, schweres Atmen) · hin: steht vor dir statt im Bett (mit --talk=gast)
##   --wallblood[=smear]         Blutspritzer (smear: blutige Schmierspur) an die Wand, auf die du schaust (4.13)
##   --costumes[=art]            alle Gäste sofort verkleidet (sonst ab dem 25.): jeder sein Kostüm, art = sheet|witch|
##                               pumpkin|cape für alle gleich (5.9)
##   --disguise                  Bettlaken übergeworfen (5.9): Sicht durch Augenlöcher, Gäste erkennen dich nur aus der Nähe
##   --drunk=n[,gast]            n Gläser getrunken (du, mit Gast: er) – ab 2 angetrunken, ab 3 betrunken (3.7)
##   --weather=klar|regen|gewitter|blitz   Wetter sofort in voller Stärke (7.8) · blitz: gleich ein Blitz (mit Gewitter)
##   --party[=gast]              sofort eine Feier im Partyraum starten (mit Gast: er lädt ein, ~3/4 kommen;
##                               sonst du – dann kommen nur Eingeladene und Freunde)
##   --cat=id[,tragen]           Hotelkatze vor den Spieler setzen (minka, socke, kasimir; im Katzenraum luna, fussel, tiger, mausi) – mit tragen gleich auf den Arm
##   --pumpkin[=anim]            Kürbismann als Testfigur (ohne Verhalten) 2,5 m vor dich, Animation in Schleife:
##                               walk (Standard), run, spin_jump, chicken, macarena, hiphop – ersetzt eine alte
##   --pumpkin=jagd[,gast]       Kürbismann (Spielkonzept 4.19) kommt übers Lobbydach und jagt dich bzw. den Gast
##   --pumpkin=dach              wie F9: Kürbismann klettert übers Lobbydach, springt in den Garten, sucht die Lobby ab
##   --pumpkin=garten            Kürbismann gleich an den Kürbisbeeten im Garten (ohne Dach), jagt alle mit Spaß und dich
##   --talk=id                   direkt ein Gespräch mit dem Gast öffnen
##   --look=id[,pose]            Gast ansehen (ohne Dialog, er bleibt stehen); pose: carry (trägt einen Kürbis),
##                               panic (Arme hoch), dance (tanzt), sit (sitzt), walk (geht quer vorbei) –
##                               zum Prüfen der Gastmodelle
##   --shock=id[,blood|corpse|ghostN|tür]  Gast erschrecken (6.12): Blutlache bzw. Leiche vor ihm im Flur, oder der
##                               Lakengeist kommt zum N. Mal an sein dunkles Zimmerfenster (ab 3 würgt er) –
##                               mit --talk=id erzählt er danach davon
##   --dice=id                   sofort Mäxchen mit dem Gast (Einsatz 3 Geld)
##   --chess=id                  sofort Schach mit dem Gast in der Lobby (Einsatz 3 Geld; mit --autoplay zieht der Spieler selbst)
##   --challenge=id[,chess]      Gast fordert dich heraus (Mäxchen bzw. Schach)
##   --autoplay                  Mäxchen-Antworten bzw. Schachzüge automatisch wählen
##   --shot=pfad.png             Screenshot speichern und beenden
##   --frames=n                  Frames bis zum Screenshot (Standard 120)
##   --shot-on=reveal|jumpscare|strangle|shock|pumpkin|lightning  Screenshot kurz nach einem Ereignis statt nach n Frames
##                               (Kürbismann auch pumpkin_roof|pumpkin_edge|pumpkin_leap|pumpkin_land|pumpkin_lobby)
##   --bg                        Fenster im Hintergrund: kein Fokus, außerhalb des Bildschirms (Game._to_background)
##   --navcheck                  Bau- und NavMesh-Zeit, Wege von Zimmer 13 zu allen wichtigen Orten (Spielkonzept 7.5)

## Der Anfang wirkt friedlich – nichts deutet auf das Monster hin (Spielkonzept 2.1).
const INTRO := "Willkommen im Hotel – zur Halloween-Woche! Heute ist der 1. Oktober.\nLerne die anderen Gäste kennen, schmücke deine Tür und feiere mit.\nDein Tagebuch liegt auf dem Schreibtisch in Zimmer 13.\n\n[WASD] Laufen  [Shift] Rennen  [Leertaste] Springen  [Strg] Ducken\n[E] Nehmen / Benutzen  [G] Ablegen  [Rechtsklick] Luft anhalten  [Esc] Menü"
const START_ENTRY := "Ich bin in Zimmer 13 aufgewacht. Die Tür nach draußen ist verriegelt."

var _post: ShaderMaterial
## Nachthimmel (shaders/night_sky.gdshader) – Wolkenzug nach Spielzeit
var _sky: ShaderMaterial
var _env: Environment
var _sky_time := 0.0

var _trace := false
var _trace_frames := 0
var _autoplay := false
## Dauer von LevelBuilder.build() und NavMesh-Backen in ms (--navcheck)
var _load_times := Vector2i.ZERO


func _ready() -> void:
	Game.reset()
	_setup_environment()

	var level := NavigationRegion3D.new()
	level.name = "Level"
	add_child(level)
	var builder := LevelBuilder.new(level, self)
	var t0 := Time.get_ticks_msec()
	builder.build()
	var t1 := Time.get_ticks_msec()
	_bake_navigation(level)
	_load_times = Vector2i(t1 - t0, Time.get_ticks_msec() - t1)

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

	var pumpkin := PumpkinMan.new()
	pumpkin.name = "PumpkinMan"
	add_child(pumpkin)
	Game.pumpkin = pumpkin

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

	var weather := Weather.new()   # Regen und Gewitter draußen (Spielkonzept 7.8)
	weather.name = "Weather"
	add_child(weather)
	weather.setup(builder, get_node("Moon") as DirectionalLight3D, _sky)
	Game.weather = weather

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

	for arg in OS.get_cmdline_user_args():
		if arg == "--perf" or arg.begins_with("--perf="):
			add_child(PerfLog.new(arg.substr(7).to_float() if arg.length() > 7 else 20.0))

	Game.player_died.connect(_on_player_died)
	SaveManager.note_world.call_deferred()   # nach dem Aufbau, bevor sich etwas bewegt
	if not Game.pending_load.is_empty():
		_load_pending.call_deferred()
	else:
		_fresh_session()
		if not "--nointro" in OS.get_cmdline_user_args():
			Game.say(INTRO, 12.0)
		if Game.new_game_slot > 0:
			_save_start.call_deferred(Game.new_game_slot)
		Game.new_game_slot = 0
	_parse_debug_args.call_deferred()


func _load_pending() -> void:
	var data := Game.pending_load
	Game.pending_load = {}
	if not SaveManager.fits(data):   # Hotel seit dem Speichern umgebaut – nicht falsch befüllen
		_fresh_session()
		Game.say("Dieser Spielstand passt nicht mehr zum Hotel. Das Spiel beginnt von vorn.", 8.0)
		return
	SaveManager.apply(data)
	Game.say("„%s“" % String(data.get("text", "")), 5.0)


## Neues Spiel: noch nichts besucht (Autosave „neuer Bereich“), noch nicht gespeichert.
func _fresh_session() -> void:
	SaveManager.visited = []
	SaveManager.last_save_msec = -1


## Neues Spiel in einem Slot: Startzustand gleich speichern, damit „Fortsetzen“ greift.
func _save_start(slot: int) -> void:
	for i in 3:
		await get_tree().process_frame
	SaveManager.save_to(slot, START_ENTRY, get_viewport().get_texture().get_image())


func _apply_settings() -> void:
	_env.ssr_enabled = Settings.reflections
	if _post:
		_post.set_shader_parameter("gamma", Settings.gamma)
		_post.set_shader_parameter("dither", 1.0 if Settings.dither_on() else 0.0)
		_post.set_shader_parameter("color_levels", 28.0 if Settings.psx_look else 255.0)


func _process(delta: float) -> void:
	_sky_time += delta
	_sky.set_shader_parameter("sky_time", _sky_time)
	if _post and Game.player:   # verschwommene Sicht (Spielkonzept 3.6/3.7)
		_post.set_shader_parameter("blur", Game.player.sight_blur)
		_post.set_shader_parameter("warp", Game.player.sight_warp)
		_post.set_shader_parameter("blur_time", _sky_time)
	if _autoplay and Engine.get_process_frames() % 100 == 0 and Game.dice.active:
		print("[Mäxchen] " + Game.dice.debug_press_random())
	if _autoplay and Engine.get_process_frames() % 30 == 0 and Game.chess.active:
		var step := Game.chess.debug_step()
		if step != "":
			print("[Schach] " + step)
	if _trace:
		_trace_frames += 1
		if _trace_frames % 120 == 0:
			var nav := "--trace-nav" in OS.get_cmdline_user_args()
			print("[%ds] Monster %s @ %s | Phase %s | Dreistigkeit %.1f" % [_trace_frames / 60,
				Monster.State.keys()[Game.monster.state], Game.monster.global_position.snapped(Vector3.ONE * 0.1),
				MonsterDirector.Phase.keys()[Game.director.phase], Game.director.effective_boldness()])
			print("      Spieler @ %s | Schock %.2f | Rausch %.2f | Schwäche %.2f | Geld %d | Hand: %s" % [Game.player.global_position.snapped(Vector3.ONE * 0.1), Game.player.shock, Game.player.drunk, Game.player.weakness(), Game.money, Game.player.held.display_name if Game.player.held else "-"])
			for guest in Game.social.guests:
				print("      %s: %s @ %s | Angst %.0f | Rausch %.2f | Beziehung %.0f | Hand: %s" % [guest.display_name,
					Guest.State.keys()[guest.state], guest.global_position.snapped(Vector3.ONE * 0.1), guest.fear,
					guest.drunk, guest.relation, guest.held.display_name if guest.held else "-"])
				if nav:
					print("        Ziel %s  nächster Punkt %s  fertig %s" % [guest.get("_target"), guest.agent.get_next_path_position(), guest.agent.is_navigation_finished()])


func _setup_environment() -> void:
	var env := Environment.new()
	# Nachthimmel mit Mond und Wolken (7.3): zu sehen im Garten und durch die Fenster. Er leuchtet nichts
	# aus – Umgebungslicht bleibt eine feste Farbe, Spiegelungen aus (sonst glänzte er in Tapete und Fliesen)
	_sky = ShaderMaterial.new()
	_sky.shader = load("res://shaders/night_sky.gdshader")
	var sky := Sky.new()
	sky.sky_material = _sky
	sky.process_mode = Sky.PROCESS_MODE_REALTIME   # Wolken ziehen jedes Bild; Strahlungs-Durchgang ist billig
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.reflected_light_source = Environment.REFLECTION_SOURCE_DISABLED
	# Spiegelbilder nur aus dem Bild selbst (SSR, 2026-10-21): polierter Lobbymarmor, Lack der Tapete, Poolwasser
	# spiegeln, was gerade zu sehen ist – zum Bildrand und nach hinten blendet es aus. Matte Flächen
	# (psx_surface, Rauheit 1) bleiben unberührt. Godot nimmt für Nichtmetalle fest 4 % Reflexion an, darum hat
	# der Lobbyboden etwas Metallic (LevelBuilder.LOBBY_FLOOR_MIRROR). Schritte: ein Bildpunkt je Schritt –
	# mit 64 fanden Strahlen über den Boden die Wände dahinter oft nicht
	env.ssr_enabled = Settings.reflections   # Einstellungen → Bild → Spiegelungen (_apply_settings)
	env.ssr_max_steps = 128
	env.ssr_fade_in = 0.15
	env.ssr_fade_out = 2.0
	env.ssr_depth_tolerance = 0.2
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.35, 0.38, 0.5)
	env.ambient_light_energy = 0.14  # ohne Deckenlampen: dunkle Ecken bleiben als Umriss erkennbar
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.fog_enabled = true
	env.fog_light_color = Color(0.02, 0.02, 0.03)
	# Nebel nach Entfernung: ab 4 m dichter, bei 66 m schwarz (Flurende verschwindet im Dunkel statt im Dunst)
	env.fog_mode = Environment.FOG_MODE_DEPTH
	env.fog_density = 1.0
	env.fog_depth_begin = 4.0
	env.fog_depth_end = 66.0
	env.fog_depth_curve = 0.6
	env.fog_sky_affect = 0.0   # Himmel bleibt hinter dem Nebel sichtbar, Bäume und Dächer stehen schwarz davor
	# Lichtschein im Dunst: Lampen werfen sichtbare Lichtkegel, dazwischen bleibt es finster
	env.volumetric_fog_enabled = true
	env.volumetric_fog_density = 0.0175
	env.volumetric_fog_albedo = Color(0.6, 0.6, 0.65)
	env.volumetric_fog_length = 12.0   # nur nah: weiter hinten würde das Lampenlicht den Flur beige verschleiern
	_env = env
	var world_env := WorldEnvironment.new()
	world_env.environment = env
	add_child(world_env)
	# Schwaches Mondlicht – erhellt den Garten und fällt durch die Lobbyfenster
	var moon := DirectionalLight3D.new()
	moon.name = "Moon"   # Weather lässt ihn blitzen
	moon.light_color = Color(0.55, 0.65, 1.0)
	moon.light_energy = 0.32
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
		if arg.begins_with("--intent=") or arg in ["--no-psx", "--psx"]:
			run_debug(arg)
	for arg in args:
		if not (arg.begins_with("--intent=") or arg in ["--no-psx", "--psx"]):
			run_debug(arg)


## Einen Debug-Befehl ausführen – beim Start für jeden Parameter, im Spiel aus der Debug-Konsole
## (DebugConsole, dort ohne „--“ getippt). false = unbekannt. Neuer Befehl: hier ein Zweig, eine Zeile
## im Kopfkommentar, in DebugConsole.COMMANDS und in der README.
func run_debug(arg: String) -> bool:
	if arg.begins_with("--intent="):
		var wanted := arg.substr(9)
		Game.director.debug_victims = wanted.to_int() if wanted.is_valid_int() else ["roam", "one", "rampage"].find(wanted)
	elif arg == "--no-psx" or arg == "--psx":
		Settings.psx_look = arg == "--psx"
		Settings.apply()
	elif arg == "--fps":
		Game.hud.fps_enabled = not Game.hud.fps_enabled
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
	elif arg.begins_with("--splash="):
		var at := arg.substr(9).split(",")
		get_tree().create_timer(1.0, false).timeout.connect(func() -> void:
			var water := get_tree().get_first_node_in_group("pool_water") as PoolWater
			if water:
				water.splash(Vector2(at[0].to_float(), at[1].to_float()), 1.0))
	elif arg == "--lure":
		get_tree().create_timer(1.0, false).timeout.connect(Game.director.debug_lure)
	elif arg.begins_with("--pool="):
		var water := get_tree().get_first_node_in_group("pool_water") as PoolWater
		if water:
			water.debug_stage = "" if arg == "--pool=off" else arg.substr(7)
	elif arg == "--pocket":
		Game.player.give_compass()
		for page in HotelMap.PAGES:
			Game.player.add_map_page(page["id"])
		Game.player.add_key("zimmer_18")
	elif arg.begins_with("--bag-menu"):
		# erst nach den übrigen Parametern (--bag, --flashlight) öffnen
		Game.player.debug_open_bag.call_deferred(arg.substr(11).to_int() - 1 if arg.begins_with("--bag-menu=") else -1)
	elif arg.begins_with("--bag"):
		var kinds := {"süßes": Item.Kind.SWEETS, "suesses": Item.Kind.SWEETS, "cola": Item.Kind.SODA_CAN, "limo": Item.Kind.SODA_CAN,
			"zierkürbis": Item.Kind.MINI_PUMPKIN, "zierkuerbis": Item.Kind.MINI_PUMPKIN, "kerze": Item.Kind.CANDLE,
			"messer": Item.Kind.KNIFE, "batterie": Item.Kind.BATTERY, "birne": Item.Kind.BULB, "uv": Item.Kind.UV_FILTER,
			"würfel": Item.Kind.LOADED_DICE, "wuerfel": Item.Kind.LOADED_DICE, "becher": Item.Kind.DICE_CUP}
		var names := (arg.substr(6) if arg.begins_with("--bag=") else "süßes,cola,zierkürbis,batterie").split(",", false)
		for what in names:
			if not kinds.has(what):
				Game.say("Tasche: " + ", ".join(kinds.keys()), 3.0)
				return true
			var item := Item.create(kinds[what], what if what in ["cola", "limo"] else "")
			if item.kind == Item.Kind.CANDLE:
				item._extinguish()   # brennend passt sie nicht hinein
			if Game.player.bag.size() < Player.BAG_SLOTS:
				Game.player.bag_add(item)
			else:
				item.free()
	elif arg.begins_with("--flashlight"):
		var uv := arg == "--flashlight=uv"
		var lamp := Item.create(Item.Kind.FLASHLIGHT, "c=1;on" + (";uv;m=uv" if uv else ""))
		Game.player.drop_held()
		Game.player.receive_item(lamp)
	elif arg.begins_with("--deco="):
		var kinds := {"gespenst": Item.Kind.SHEET_GHOST, "lichter": Item.Kind.LIGHT_STRING, "netz": Item.Kind.COBWEB,
			"laub": Item.Kind.LEAVES, "zierkürbis": Item.Kind.MINI_PUMPKIN, "zierkuerbis": Item.Kind.MINI_PUMPKIN,
			"fledermaus": Item.Kind.BAT_GARLAND, "spinne": Item.Kind.SPIDER, "totenkopf": Item.Kind.SKULL, "besen": Item.Kind.BROOM}
		var what := arg.substr(7).trim_suffix(",g")
		if not kinds.has(what):
			Game.say("Deko: gespenst, lichter, netz, laub, zierkürbis, fledermaus, spinne, totenkopf oder besen", 3.0)
			return true
		Game.player.drop_held()
		Game.player.receive_item(Item.create(kinds[what]))
		if arg.ends_with(",g"):
			get_tree().create_timer(1.0).timeout.connect(func() -> void: Game.player.drop_held())
	elif arg.begins_with("--show="):
		Game.player.debug_show = arg.substr(7)
	elif arg == "--winded":
		Game.player.stamina = 0.0
		Game.player.winded = true
	elif arg == "--sprint":
		Game.player.debug_sprint = true
	elif arg.begins_with("--bold="):
		Game.director.boldness = arg.substr(7).to_float()
	elif arg.begins_with("--friend="):
		var friend := _guest(arg.substr(9))
		if friend:
			friend.relation = 65.0   # befreundet (6.3)
	elif arg.begins_with("--relation="):
		# Beziehung setzen; für die Extreme werden die nötigen Taten gleich mit eingetragen (6.3)
		var rel := arg.substr(11).split(",")
		var g := _guest(rel[0])
		if g and rel.size() > 1:
			g.relation = clampf(rel[1].to_float(), -100.0, 100.0)
			if g.relation >= 80.0:
				g.deeds.merge({"games": Social.BOND_GAMES, "gifts_to": Social.BOND_GIFTS_TO, "gifts_from": Social.BOND_GIFTS_FROM}, true)
			elif g.relation <= -80.0:
				g.deeds.merge({"hostile": Social.FEUD_HOSTILE, "revenge": Social.FEUD_REVENGE}, true)
	elif arg.begins_with("--follow="):
		var follower := _guest(arg.substr(9))
		if follower:
			_put_in_front(follower, -2.0, false)   # hinter dir
			follower.start_follow()
	elif arg.begins_with("--visit="):
		var visitor := _guest(arg.substr(8))
		if visitor:
			Game.social.start_visit(visitor)
	elif arg.begins_with("--punch="):
		# Gast vor den Spieler stellen und zweimal zuschlagen (Nachfrage + Schlag)
		var target := _guest(arg.substr(8))
		if target:
			_put_in_front(target, 1.0)
			target._set_idle(5.0)
			get_tree().create_timer(1.0).timeout.connect(func() -> void:
				Game.player.debug_punch(target)
				Game.player.debug_punch(target))
	elif arg.begins_with("--attack="):
		var attacker := _guest(arg.substr(9))
		if attacker:
			_put_in_front(attacker, 4.0, false)
			get_tree().create_timer(1.0).timeout.connect(attacker.start_attack)
	elif arg.begins_with("--kill="):
		var victim := _guest(arg.substr(7))
		if victim == null:
			return true
		Game.director.attacks = MonsterDirector.HARMLESS_ATTACKS + 1   # wirklich holen
		get_tree().create_timer(3.0).timeout.connect(func() -> void:
			if victim.dead:
				return
			Game.monster.spawn_at(victim.global_position + Vector3(1, 0, 0))
			Game.director.phase = MonsterDirector.Phase.ACTIVE
			Game.director.kill_guest(victim, null))
	elif arg.begins_with("--weep="):
		# Tränen (Spielkonzept 7.6): der Gast weint eine halbe Minute – mit --look=gast vor dir
		var crying := _guest(arg.substr(7))
		if crying:
			crying.weep(30.0)
	elif arg.begins_with("--wound="):
		# Überlebender (Spielkonzept 6.17): gast,scratch|axe|choke[,hin] – verletzt wie nach dem Angriff; hin: er liegt
		# bzw. steht vor dir (mit --talk=gast erzählt er als Zeuge)
		var parts := arg.substr(8).split(",")
		var hurt := Game.social.guest_by_id(parts[0])
		if hurt == null or parts.size() < 2 or not Wounds.KINDS.has(parts[1]):
			Game.say("--wound=gast,scratch|axe|choke[,hin]", 3.0)
		else:
			hurt.wound_by(parts[1])
			if "hin" in parts:
				_put_in_front(hurt, 1.4)
				hurt.wound_bed = 0.0   # zum Ansehen: steht vor dir statt im Bett
				hurt._set_idle(30.0)
				Game.player.head.rotation.x = deg_to_rad(-28.0 if parts[1] == "axe" else -5.0)
	elif arg == "--steal-test":
		# Spieler nimmt Ednas Deko unbemerkt (für Schuld-Test)
		for node in get_tree().get_nodes_in_group("items"):
			if node.owner_id == "edna":
				Game.player.try_pick_up(node)
				break
	elif arg.begins_with("--enemy="):
		var enemy := _guest(arg.substr(8))
		if enemy:
			enemy.relation = -65.0   # verfeindet (6.3)
	elif arg.begins_with("--player-deco="):
		var xz := arg.substr(14).split(",")
		var deco := Item.create(Item.Kind.CARVED_PUMPKIN)
		deco.owner_id = "player"
		deco.position = Vector3(xz[0].to_float(), 0.02, xz[1].to_float())
		add_child(deco)
	elif arg.begins_with("--dice="):
		var opponent := _guest(arg.substr(7))
		if opponent == null:
			return true
		get_tree().create_timer(0.5).timeout.connect(func() -> void:
			Game.dice.start(opponent, {"money": 3, "item": false}))
	elif arg.begins_with("--chess="):
		var chess_opponent := _guest(arg.substr(8))
		if chess_opponent == null:
			return true
		get_tree().create_timer(0.5).timeout.connect(func() -> void:
			Game.chess.start(chess_opponent, {"money": 3, "item": false}))
	elif arg.begins_with("--challenge="):
		var challenger := _guest(arg.substr(12).split(",")[0])
		if challenger:
			Game.social.challenge(challenger, "chess" if arg.ends_with(",chess") else "dice")
	elif arg == "--autoplay":
		_autoplay = true
	elif arg.begins_with("--cat="):
		# Katze vor den Spieler setzen (sitzt, zum Streicheln) – mit ",tragen" gleich auf den Arm
		var parts := arg.substr(6).split(",")
		for cat in get_tree().get_nodes_in_group("cats"):
			if cat.id == parts[0]:
				cat.place_in_front_of(Game.player)
				if parts.size() > 1 and parts[1] == "tragen":
					cat.affection = maxi(cat.affection, HotelCat.CARRY_TRUST)
					Game.player.drop_held()
					cat.pick_up(Game.player)
	elif arg == "--pumpkin=dach":
		get_tree().create_timer(0.5, false).timeout.connect(Game.pumpkin.debug_roof)   # NavMesh muss erst stehen
	elif arg == "--pumpkin=garten":
		get_tree().create_timer(0.5, false).timeout.connect(Game.pumpkin.debug_garden)   # NavMesh muss erst stehen
	elif arg.begins_with("--pumpkin=jagd"):
		_debug_pumpkin_hunt(arg.substr(14).trim_prefix(","))
	elif arg.begins_with("--pumpkin"):
		PumpkinMan.spawn_in_front_of(Game.player, arg.substr(10) if arg.begins_with("--pumpkin=") else "walk")
	elif arg == "--wallblood" or arg == "--wallblood=smear":
		var kind := "wall_smear" if arg.ends_with("smear") else "wall_splatter"
		# Ein Stück vor der Wand im Blick ansetzen – dann ist sie die nächste
		var cam := Game.player.camera
		var ahead := -cam.global_basis.z
		var hit := cam.get_world_3d().direct_space_state.intersect_ray(
			PhysicsRayQueryParameters3D.create(cam.global_position, cam.global_position + ahead * 6.0, 1))
		var near: Vector3 = hit.get("position", Vector3.ZERO) - ahead * 0.4
		near.y = Game.player.global_position.y   # Boden unter dem Spieler – die Spur sitzt in Höhe über dem Boden
		if hit.is_empty() or Game.traces.add_wall_blood(near, kind) == null:
			Game.say("Keine Wand im Blick.", 2.5)
	elif arg == "--costumes" or arg.begins_with("--costumes="):
		Costume.force = arg.substr(11) if arg.begins_with("--costumes=") else "all"
	elif arg == "--disguise":
		Game.player.set_disguised(true)
	elif arg.begins_with("--drunk="):
		var parts := arg.substr(8).split(",")
		var glasses := parts[0].to_int()
		var who: Guest = _guest(parts[1]) if parts.size() > 1 else null
		if parts.size() > 1 and who == null:
			return true   # nicht stattdessen selbst trinken
		for i in glasses:
			if who:
				who.drink()
			else:
				Game.player.drink(i < glasses - 1)
	elif arg.begins_with("--weather="):
		# Wetter sofort (7.8): klar, regen, gewitter (gleich in voller Stärke) oder blitz (ein Blitz, ggf. mit Gewitter)
		match arg.substr(10):
			"klar":
				Game.weather.set_weather(Weather.Kind.CLEAR, true)
			"regen":
				Game.weather.set_weather(Weather.Kind.RAIN, true)
			"gewitter":
				Game.weather.set_weather(Weather.Kind.STORM, true)
			"blitz":
				if Game.weather.kind != Weather.Kind.STORM:
					Game.weather.set_weather(Weather.Kind.STORM, true)
				get_tree().create_timer(3.0).timeout.connect(Game.weather.lightning)   # erst, wenn es regnet
			_:
				Game.say("Wetter: klar, regen, gewitter oder blitz", 3.0)
	elif arg == "--party" or arg.begins_with("--party="):
		var host := arg.substr(8) if arg.begins_with("--party=") else "player"
		if host == "player" or _guest(host):
			Game.social.start_party(host)
	elif arg.begins_with("--look="):
		var parts := arg.substr(7).split(",")
		var guest := _guest(parts[0])
		if guest:
			_debug_look(guest, parts[1] if parts.size() > 1 else "")
	elif arg.begins_with("--shock="):
		var parts := arg.substr(8).split(",")
		var shocked := _guest(parts[0])
		if shocked:
			_debug_shock(shocked, parts[1] if parts.size() > 1 else "blood")
	elif arg.begins_with("--talk="):
		var partner := _guest(arg.substr(7))
		if partner == null:
			return true
		var after_shock := Array(OS.get_cmdline_user_args()).any(func(a: String) -> bool: return a.begins_with("--shock="))
		if not after_shock:
			Game.player.global_position = partner.global_position + Vector3(0, 0, -1.4)
			Game.player.rotation.y = 0.0
		get_tree().create_timer(8.0 if after_shock else 1.0).timeout.connect(func() -> void:
			if after_shock:   # erst erschrecken lassen, dann hingehen
				var front := -partner.global_transform.basis.z
				Game.player.global_position = partner.global_position + front * 1.4
			_face_toward(partner.global_position)
			Game.dialog.open(partner))
	elif arg == "--ghost=flur":
		Game.ghost.debug_summon_hall()
	elif arg == "--ghost=tür" or arg == "--ghost=tuer":
		if Game.ghost.debug_summon_door() and "--answer" in OS.get_cmdline_user_args():
			get_tree().create_timer(4.0).timeout.connect(Game.ghost.debug_open_door)   # du machst nach 4 s auf
	elif arg == "--ghost=schrank":
		# kommt durch den Vorhang deines Zimmers herein – du versteckst dich gleich in dessen Schrank
		var room: Dictionary = Game.director.rooms.get(Game.social.builder.room_at(Game.player.global_position), {})
		var wardrobe: HideSpot = null
		for spot in room.get("spots", []):
			if (spot as HideSpot).type == HideSpot.Type.WARDROBE:
				wardrobe = spot
		if wardrobe == null:
			Game.say("Lakengeist: Hier ist kein Schrank.", 2.5)
		elif Game.ghost.debug_summon(4):
			get_tree().create_timer(1.5).timeout.connect(func() -> void:
				if Game.player.hiding == null:
					Game.player.enter_hide(wardrobe))
	elif arg.begins_with("--awake="):
		# so viele Nächte ohne Schlaf (zählen erst nach dem ersten Angriff, also gilt der als geschehen)
		Game.director.first_attack_done = true
		Game.player.nights_awake = arg.substr(8).to_int()
	elif arg == "--sleep":
		Game.social.start_sleep()
	elif arg == "--sleep=bett":
		# alle Gäste sofort im Bett, du schläfst im Bett von Zimmer 13
		Game.social.start_sleep(true)
		for spot in Game.director.rooms[LevelBuilder.PLAYER_ROOM]["spots"]:
			if (spot as HideSpot).own_bed:
				Game.player.start_sleep(spot)
	elif arg.begins_with("--ghost="):
		Game.ghost.debug_summon(arg.substr(8).to_int())
	elif arg == "--warn":
		Game.director.start_warning()
	elif arg.begins_with("--attacks="):
		# so viele Angriffe gab es schon (über 2 = gefährlich, ob es holt, würfelt _choose_intent nach Tag)
		Game.director.first_attack_done = true
		Game.director.attacks = arg.substr(10).to_int()
	elif arg == "--first-attack":
		# Feier starten, kurz darauf der erste Angriff
		Game.social.start_party("mila")
		get_tree().create_timer(3.0).timeout.connect(Game.director._first_attack_at_party)
	elif arg == "--trick" or arg.begins_with("--trick="):
		var kid: Guest = Game.social.guest_by_id(arg.substr(8)) if arg.begins_with("--trick=") else null
		if kid == null:
			var kids := Game.social.living_guests().filter(func(g: Guest) -> bool: return g.is_child())
			kid = kids.pick_random() if not kids.is_empty() else null
		if kid == null or not kid.is_child() or not Game.social.start_round(kid):
			Game.say("Süßes oder Saures: kein Kind oder keine Gästetür in der Nähe", 3.0)
	elif arg == "--decorate" or arg.begins_with("--decorate="):
		# Schmück-Aktion sofort (Spielkonzept 5.9); „lobby“: in der Lobby; „allein“: ein Gast trägt allein ein Stück
		# Deko in sein Zimmer (mit „lobby“ in die Lobby); „hin“: Spieler vor die Stelle, Blick zur Wand
		var parts := arg.substr(11).split(",") if arg.begins_with("--decorate=") else PackedStringArray()
		if "allein" in parts:   # der Weg zur Kiste braucht das fertige NavMesh
			get_tree().create_timer(1.5).timeout.connect(func() -> void: _debug_decorate(parts))
		else:
			_debug_decorate(parts)
	elif arg == "--search" or arg.begins_with("--search="):
		# Deko-Suche (Spielkonzept 5.9) – der Weg zum Fundort braucht das fertige NavMesh
		var parts := arg.substr(9).split(",") if arg.begins_with("--search=") else PackedStringArray()
		get_tree().create_timer(1.5).timeout.connect(func() -> void: _debug_search(parts))
	elif arg.begins_with("--cook="):
		_debug_cook(arg.substr(7).split(","))
	elif arg.begins_with("--pals="):
		_debug_pals(arg.substr(7).split(","))
	elif arg == "--knock":
		# Klopfen an Zimmer 13 vorbereiten (Spieler steht im Zimmer, Monster ist unterwegs)
		Game.director.first_attack_done = true
		Game.player.global_position = (Game.social.builder.rooms[LevelBuilder.PLAYER_ROOM]["center"] as Vector3) + Vector3(0, 0.05, -0.6)
		Game.monster.spawn_at(Game.social.builder.wander_points[8] + Vector3(0, 0.05, 0))
		Game.social._knock_cooldown = 1.0
		Game.social.debug_fake_knock = "--knock-fake" in OS.get_cmdline_user_args()
		if "--answer" in OS.get_cmdline_user_args():
			# nach 4 s öffnet der Spieler die Tür
			get_tree().create_timer(4.0).timeout.connect(func() -> void:
				(Game.social.builder.rooms[LevelBuilder.PLAYER_ROOM]["door"] as Door).set_open(true))
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
		Game.tracing = true
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
		var thief := _guest(arg.substr(13))
		var lamp: Lamp = thief._bulb_to_steal(true) if thief else null
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
	elif arg == "--navcheck":
		get_tree().create_timer(2.0).timeout.connect(_nav_check)
	else:
		return false
	return true


## --tp: zu einem Ort aus der F6-Liste (lobby, bar, küche, keller …), in ein Zimmer (Nummer) oder vor einen Gast.
func _debug_teleport(where: String) -> bool:
	var p := Game.player
	var guest := Game.social.guest_by_id(where)
	if guest and not guest.dead:
		var front := -guest.global_transform.basis.z
		TeleportUI.place_player(guest.global_position + front * 1.6, -front)
		return true
	# Zimmer: Nummer (auch verschlossene, auch oben), „113“ → 0113, Türschild „13“ → 0113
	var b := Game.social.builder
	var no := where
	if b.room_spot(no).is_empty() and where.is_valid_int():
		no = "%04d" % where.to_int()
	for key in b.rooms:
		if b.rooms[key]["sign"] == where:
			no = key
	var spot := b.room_spot(no)
	if not spot.is_empty():
		TeleportUI.place_player(spot["pos"], spot["look"])
		return true
	var entry := (get_node("Teleport") as TeleportUI).find(where)
	if entry.is_empty():
		return false
	if p.hiding:
		p.exit_hide()
	(get_node("Teleport") as TeleportUI).go_to(entry)
	return true


## --navcheck: Ladezeiten und ob die wichtigen Orte vom Spielerzimmer aus auf dem NavMesh erreichbar sind.
func _nav_check() -> void:
	var b := Game.social.builder
	print("[navcheck] Bau %d ms, NavMesh %d ms" % [_load_times.x, _load_times.y])
	var map := get_world_3d().navigation_map
	var from := NavigationServer3D.map_get_closest_point(map, b.player_spawn)
	var ground := b.wander_points.filter(func(p: Vector3) -> bool: return p.y < 1.0)
	var targets := {"Lobby": b.lobby_center, "Galerie": b.lobby_center + Vector3(-5.5, LevelBuilder.UP_Y, -2.0),
		"Bar": b.bar_spots[0], "Partyraum": b.party_spots[0], "Küche": b.kitchen_spot, "Garten": b.garden_spots[0],
		"Keller": b.cellar_center(), "Treppenhaus": b.stairwell_point + Vector3(0, 0, 2.2),
		"Westflügel": ground[ground.size() - 1]}
	for t in b._map["trees"]:
		targets["Innenhof %.0f,%.0f" % [t["center"][0], t["center"][1]]] = Vector3(t["center"][0], 0, t["center"][1] + 7.0)
	# Obergeschoss (Spielkonzept 7.7): Katzenraum, Bibliothek, ein Flur und ein Zimmer oben
	for zone in b.zones:
		var name := String(zone["name"])
		if (name in ["Katzenraum", "Bibliothek"] or (name.ends_with("(oben)") and not targets.has("Flur oben"))) \
				and not targets.has(name):
			targets["Flur oben" if name.ends_with("(oben)") else name] = zone["center"]
	# Untergeschoss (Spielkonzept 7.9): Gang unten am Treppenhaus, Technikraum, Wäscherei (der Heizkeller ist „Keller“)
	var below := b.zones.filter(func(z: Dictionary) -> bool: return z["name"] == "Keller")
	below.sort_custom(func(z1: Dictionary, z2: Dictionary) -> bool:
		return (z1["center"] as Vector3).distance_to(b.stairwell_point) < (z2["center"] as Vector3).distance_to(b.stairwell_point))
	if not below.is_empty():
		targets["Kellergang"] = below[0]["center"]
	for zone in b.zones:
		if zone["name"] in ["Technikraum", "Wäscherei"]:
			targets[zone["name"]] = zone["center"]
	for no in b.rooms:
		if b.rooms[no]["kind"] == "vacant" and (b.rooms[no]["center"] as Vector3).y > 2.0:
			targets["Zimmer %s" % no] = b.rooms[no]["center"]
			break
	var bad := 0
	for label in targets:
		var to := NavigationServer3D.map_get_closest_point(map, targets[label])
		# ohne Grenze bei der Suche, wie das Monster (Monster.agent.path_search_max_polygons)
		var query := NavigationPathQueryParameters3D.new()
		query.map = map
		query.start_position = from
		query.target_position = to
		query.path_search_max_polygons = 0
		var result := NavigationPathQueryResult3D.new()
		NavigationServer3D.query_path(query, result)
		var path := result.path
		var reached := not path.is_empty() and path[path.size() - 1].distance_to(to) < 0.5 and to.distance_to(targets[label]) < 1.0
		var length := 0.0
		for i in range(1, path.size()):
			length += path[i - 1].distance_to(path[i])
		print("[navcheck]   %-22s %s" % [label, ("%.0f m" % length) if reached else "UNERREICHBAR (nächster Punkt %s)" % to])
		bad += 0 if reached else 1
	print("[navcheck] alles erreichbar" if bad == 0 else "[navcheck] %d Orte unerreichbar" % bad)
	get_tree().quit()


## Gast für einen Debug-Befehl – unbekannte ID: Meldung und null.
func _guest(id: String) -> Guest:
	var guest := Game.social.guest_by_id(id)
	if guest == null:
		Game.say("Unbekannter Gast: %s" % id, 3.0)
	return guest


## Gast `distance` m vor den Spieler stellen (negativ: dahinter); face: er schaut den Spieler an.
func _put_in_front(guest: Guest, distance: float, face: bool = true) -> void:
	guest.global_position = Game.player.global_position - Game.player.global_transform.basis.z * distance
	if face:
		guest.rotation.y = Game.player.rotation.y + PI


## Spieler waagerecht zu einem Punkt drehen.
func _face_toward(point: Vector3) -> void:
	var to := point - Game.player.global_position
	Game.player.rotation.y = atan2(-to.x, -to.z)


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
	if what == "tür" or what == "tuer":
		# Er steht im eigenen Zimmer, der Lakengeist vor seiner Tür; du stehst im Flur dahinter (kein Zeuge)
		var center: Vector3 = home["center"]
		guest.global_position = center + Vector3(0, 0.05, 0)
		var front: Vector3 = home["door_front"]
		Game.player.global_position = front - into * 3.5 + along * 2.5 + Vector3(0, 0.05, 0)
		_face_toward(front)
		Game.ghost.debug_summon_door(guest)
		return
	if what.begins_with("ghost"):
		var center: Vector3 = home["center"]
		guest.global_position = center + into * 0.8 + Vector3(0, 0.05, 0)
		guest.rotation.y = atan2(-into.x, -into.z)
		Game.player.global_position = center - into * 1.6 + along * 1.4 + Vector3(0, 0.05, 0)
		_face_toward(center + into * 2.5)
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
	_face_toward(front)
	Game.player.head.rotation.x = -0.25


## --savetest: Speichern und Laden ohne Datei durchspielen und Unterschiede ausgeben.
func _save_test() -> void:
	# Etwas Unordnung, damit der Test mehr abdeckt: Vorhang zu, Licht aus, Birne in der Hand
	(get_tree().get_nodes_in_group("windows").filter(func(w: Node) -> bool: return w.has_curtains())[0] as HotelWindow).set_closed(true)
	LightSwitch.find(get_tree(), "keller").set_on(false)
	var lamp: Lamp = get_tree().get_nodes_in_group("lamp_fixtures").filter(func(l: Node) -> bool: return l.room_id == "0115")[0]
	if Game.player.held == null:
		Game.player.receive_item(lamp.take_bulb())
	for kind in [Item.Kind.SWEETS, Item.Kind.SODA_CAN]:   # mit voller Hand: in die Tasche
		Game.player.receive_item(Item.create(kind))
	await get_tree().create_timer(0.5).timeout
	var before: Dictionary = JSON.parse_string(JSON.stringify(SaveManager.collect()))
	SaveManager.apply(before)
	await get_tree().physics_frame
	await get_tree().process_frame
	var after: Dictionary = JSON.parse_string(JSON.stringify(SaveManager.collect()))
	for note in _settle(before, after):
		print("[savetest]   (kein Fehler) " + note)
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


## Bekanntes Rauschen zwischen den beiden Sammelzeitpunkten angleichen, damit nur echte Lade-Lücken zählen:
## Lage von Gegenständen in der Hand (folgt der Hand, apply setzt sie nicht), Türen, die ein Gast im Türrahmen
## gleich nach dem Laden öffnet (sein Zustand – Klopfen, Schlafen … – wird nicht gespeichert, er steht danach
## untätig da), Drehung liegender Gegenstände bis ~15° und Katzen-Zeitgeber, die genau dazwischen abliefen.
## Gibt Hinweise dazu zurück.
func _settle(before: Dictionary, after: Dictionary) -> Array[String]:
	var notes: Array[String] = []
	for data: Dictionary in [before, after]:
		var hands: Array = [data["player"]]
		hands.append_array((data["guests"] as Dictionary).values())
		for who: Dictionary in hands:
			if who.get("held") is Dictionary:
				who["held"].erase("pos")
				who["held"].erase("rot")
	var doors := get_tree().get_nodes_in_group("doors")
	var was: Array = before.get("doors", [])
	var now: Array = after.get("doors", [])
	if was.size() == doors.size() and now.size() == doors.size():
		for i in doors.size():
			var center: Vector3 = (doors[i] as Door).center()
			if bool(was[i]["open"]) != bool(now[i]["open"]) and Game.social.living_guests().any(func(g: Guest) -> bool:
					return center.distance_to(g.global_position + Vector3.UP) < 1.3):
				now[i] = was[i]
				notes.append("doors[%d]: ein Gast im Türrahmen hat sie nach dem Laden geöffnet" % i)
	# Liegende Gegenstände: Euler-Winkel sind nahe ±90° Neigung mehrdeutig, und was beim Sammeln noch rollte, setzt
	# sich ohne Schwung (wird nicht gespeichert) etwas anders – gleich, wenn die Lage auf ~15° stimmt
	var items_was: Array = before.get("items", [])
	var items_now: Array = after.get("items", [])
	if items_was.size() == items_now.size():
		for i in items_was.size():
			var a: Dictionary = items_was[i]
			var b: Dictionary = items_now[i]
			if a.get("kind") == b.get("kind") and a.get("rot") is Array and b.get("rot") is Array and a["rot"] != b["rot"]:
				var qa := Quaternion.from_euler(Vector3(a["rot"][0], a["rot"][1], a["rot"][2]))
				var qb := Quaternion.from_euler(Vector3(b["rot"][0], b["rot"][1], b["rot"][2]))
				if qa.angle_to(qb) < deg_to_rad(15.0):
					b["rot"] = a["rot"]
	var cats_was: Array = before.get("cats", [])
	var cats_now: Array = after.get("cats", [])
	if cats_was.size() == cats_now.size():
		for i in cats_was.size():
			if float(cats_was[i].get("timer", 1.0)) <= 0.05 and not _same(cats_was[i], cats_now[i]):
				cats_now[i] = cats_was[i]   # neuer Zeitgeber, neue Richtung – sie hat gerade etwas Neues angefangen
				notes.append("cats[%d]: Zeitgeber lief zwischen den Messungen ab" % i)
	return notes


## Gleich bis auf kleine Zahlenabweichungen (zwischen den Messungen vergeht ein Frame).
func _same(a, b) -> bool:
	if typeof(a) == TYPE_FLOAT or typeof(a) == TYPE_INT:
		# Winkel: π und −π sind dieselbe Drehung (aufgehängte Deko blickt oft genau nach Süden)
		if typeof(b) != TYPE_FLOAT and typeof(b) != TYPE_INT:
			return false
		var diff := absf(float(a) - float(b))
		return diff < 2.0 or absf(diff - TAU) < 0.01
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

## --pumpkin=jagd[,gast]: Der Kürbismann jagt den Spieler bzw. den Gast (auch ohne Spaß und vor dem ersten Angriff).
func _debug_pumpkin_hunt(id: String) -> void:
	await get_tree().create_timer(0.5, false).timeout   # NavMesh muss erst synchronisiert sein
	var target: Node3D = Game.player
	if id != "":
		target = Game.social.guest_by_id(id)
		if target == null:
			Game.say("Kein Gast „%s“" % id)
			return
		if (target as Guest).is_child():
			Game.say("Kindern tut der Kürbismann nichts")
			return
	if not Game.pumpkin.debug_hunt(target):
		Game.say("Kürbismann: kein Platz zum Erscheinen")


## --search[=gast][,mit]: Deko-Suche (Spielkonzept 5.9) – mit „mit“ geht der Spieler mit (folgt ihm von selbst).
func _debug_search(parts: PackedStringArray) -> void:
	var search := Game.social.search
	var who: Guest = null
	for part in parts:
		if part != "mit":
			who = Game.social.guest_by_id(part)
	var walkers: Array = [who] if who else Game.social.living_guests().filter(func(g: Guest) -> bool: return search._available(g))
	walkers.shuffle()
	for g: Guest in walkers.slice(0, 8):
		if search.start(g, "mit" in parts):
			if "mit" in parts:
				search.lead_off(g)
				# Der Spieler folgt ihm von selbst (2,5 m dahinter), bis er geteilt hat
				var follow := Timer.new()
				follow.wait_time = 0.3
				add_child(follow)
				follow.timeout.connect(func() -> void:
					if not search.is_busy(g):
						follow.queue_free()
						return
					var back := g.global_position - (-g.global_transform.basis.z) * 2.5
					Game.player.global_position = Vector3(back.x, g.global_position.y + 0.05, back.z)
					_face_toward(g.global_position))
				follow.start()
			return
	Game.say("Deko-Suche: kein Gast frei oder kein Fundort erreichbar", 3.0)


## --cook=suppe|braten[,fertig]: Kochen (Spielkonzept 3.8) – Spieler vor den Herd, Kürbis schon geschnitten.
func _debug_cook(parts: PackedStringArray) -> void:
	var stove := Game.kitchen
	if stove == null:
		Game.say("Kein Herd im Hotel", 3.0)
		return
	var soup := "braten" not in parts
	stove.dish = "soup" if soup else "roast"
	stove.variety = "halloween" if soup else "hokkaido"
	stove.phase = "cooking"
	stove._timer = 0.5 if "fertig" in parts else (Stove.SOUP_TIME if soup else Stove.ROAST_TIME)
	stove._show()
	var front: Vector3 = stove.front
	Game.player.global_position = Vector3(stove.global_position.x, 0.05, stove.global_position.z) + front * 1.4
	Game.player.rotation.y = atan2(front.x, front.z)
	Game.player.head.rotation.x = deg_to_rad(-25.0)


## --pals=gast1,gast2: gast1 ist mit dir befreundet, beide sind Freunde und stehen vor dir (Spielkonzept 6.16).
func _debug_pals(parts: PackedStringArray) -> void:
	var a := Game.social.guest_by_id(parts[0])
	var b := Game.social.guest_by_id(parts[1]) if parts.size() > 1 else null
	if a == null or b == null:
		Game.say("--pals: zwei Gäste angeben, z. B. --pals=edna,bruno", 3.0)
		return
	a.relation = 60.0
	b.relation = minf(b.relation, 5.0)
	Game.social.pals.counts[GuestPals.key(a, b)] = GuestPals.PAL_DEEDS
	var p := Game.player
	var forward := -p.global_transform.basis.z
	var side := forward.cross(Vector3.UP).normalized()
	for g: Guest in [a, b]:
		g.global_position = p.global_position + forward * 2.5 + side * (0.6 if g == a else -0.6)
		g._set_idle(30.0)
	Game.social.pals._scan = 0.5


## --decorate[=…]: Schmück-Aktion bzw. allein schmückender Gast (Spielkonzept 5.9), mit „hin“ steht der Spieler davor.
func _debug_decorate(parts: PackedStringArray) -> void:
	var caller: Guest = null
	for part in parts:
		if not part in ["hin", "lobby", "allein", "gross", "hier", "haus"]:
			caller = Game.social.guest_by_id(part)
	var deco := Game.social.decorating
	var spot: Dictionary = {}
	if "hier" in parts:
		var host: Guest = caller if caller else Game.social.living_guests().filter(func(g: Guest) -> bool:
			return not g.is_child() and deco._available(g)).pick_random()
		var why := deco.call_here(host, false)
		if why != "":
			Game.say("Schmücken: " + why, 3.0)
		return
	if "gross" in parts:
		if deco.start_big(caller, Vector3.INF, false, "lobby" in parts):
			spot = deco.site
	elif "allein" in parts:
		var walkers: Array = [caller] if caller else Game.social.living_guests().filter(func(g: Guest) -> bool: return deco._available(g))
		walkers.shuffle()
		for g: Guest in walkers.slice(0, 8):
			if deco.start_solo(g, "lobby" in parts, "haus" in parts):
				spot = deco.solo_site(g)
				break
	elif deco.start(caller, "lobby" in parts):
		spot = deco.site
	if spot.is_empty():
		Game.say("Schmücken: kein Gast frei oder keine passende Stelle in der Nähe", 3.0)
	elif "hin" in parts:
		var out: Vector3 = spot["out"]
		var wall: Vector3 = spot["wall"]
		var back := 3.2   # so weit zurück, wie der Flur reicht
		var hit := Game.player.get_world_3d().direct_space_state.intersect_ray(
			PhysicsRayQueryParameters3D.create(wall + out * 0.1 + Vector3.UP * 1.2, wall + out * 3.6 + Vector3.UP * 1.2, 1 | 2))
		if not hit.is_empty():
			back = minf(back, wall.distance_to(Vector3(hit["position"].x, wall.y, hit["position"].z)) - 0.4)
		Game.player.global_position = wall + out * back + Vector3(0, 0.05, 0)
		Game.player.rotation.y = atan2(out.x, out.z)
		Game.player.head.rotation.x = deg_to_rad(-12.0)
	elif "--answer" in OS.get_cmdline_user_args():
		# in Zimmer 13 kommt die Einladung per Anruf – nach 4 s abnehmen
		get_tree().create_timer(4.0).timeout.connect(func() -> void: Game.phones.answer(Game.phones.home_phone))
