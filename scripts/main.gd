extends Node3D
## Prototyp „Zimmer 13“ – baut Umgebung, Level, Spieler, Monster und UI zusammen.
##
## Debug-Startparameter (nach „--“ an Godot übergeben):
##   --pos=x,y,z[,blickwinkel]   Spieler versetzen
##   --monster=x,y,z             Monster sofort an dieser Stelle zeigen
##   --debug                     Debug-Werte einblenden
##   --nointro                   ohne Einführungstext
##   --trace                     Monster-Zustand alle 2 s in die Konsole schreiben
##   --warn                      sofort Vorwarnung → Monster erscheint
##   --bold=n                    Dreistigkeit setzen (0–100)
##   --friend=id                 mit einem Gast befreundet starten (edna, bruno, mila)
##   --kill=id                   Gast nach 3 s vom Monster holen lassen
##   --party                     sofort eine Feier in der Lobby starten
##   --talk=id                   direkt ein Gespräch mit dem Gast öffnen
##   --dice=id                   sofort Mäxchen mit dem Gast (Einsatz 3 Geld)
##   --shot=pfad.png             Screenshot speichern und beenden
##   --frames=n                  Frames bis zum Screenshot (Standard 120)

const INTRO := "Zimmer 13. Der Ausgang ist verriegelt – und irgendetwas schleicht durch die Flure.\nHalte es mit Deko und Licht fern. Freunde dich mit den anderen Gästen an.\n\n[WASD] Laufen  [Shift] Rennen  [Leertaste] Springen  [Strg] Ducken\n[E] Nehmen / Benutzen  [G] Ablegen  [Rechtsklick] Luft anhalten  [F3] Debug  [F5] Monster rufen"

var _shot_path := ""
var _shot_frames := 0
var _shot_at := 120
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

	var player := Player.new()
	player.name = "Player"
	player.position = builder.player_spawn
	add_child(player)
	Game.player = player

	var monster := Monster.new()
	monster.name = "Monster"
	add_child(monster)
	Game.monster = monster

	var director := MonsterDirector.new()
	director.name = "MonsterDirector"
	add_child(director)
	director.setup(builder, monster)
	director.post_material = _setup_post_fx()
	Game.director = director

	var social := Social.new()
	social.name = "Social"
	add_child(social)
	Game.social = social
	social.setup(builder, self)

	var dialog := DialogUI.new()
	dialog.name = "Dialog"
	add_child(dialog)
	Game.dialog = dialog

	var dice := DiceMatch.new()
	dice.name = "DiceMatch"
	dice.table = builder.game_table
	add_child(dice)
	Game.dice = dice

	var hud := Hud.new()
	hud.name = "Hud"
	add_child(hud)
	Game.hud = hud

	Game.player_died.connect(_on_player_died)
	if not "--nointro" in OS.get_cmdline_user_args():
		Game.say(INTRO, 12.0)
	_parse_debug_args.call_deferred()


func _process(_delta: float) -> void:
	if _autoplay and Engine.get_process_frames() % 100 == 0 and Game.dice.active:
		print("[Mäxchen] " + Game.dice.debug_press_random())
	if _trace:
		_trace_frames += 1
		if _trace_frames % 120 == 0:
			print("[%ds] Monster %s @ %s | Phase %s | Dreistigkeit %.1f" % [_trace_frames / 60,
				Monster.State.keys()[Game.monster.state], Game.monster.global_position.snapped(Vector3.ONE * 0.1),
				MonsterDirector.Phase.keys()[Game.director.phase], Game.director.effective_boldness()])
			print("      Spieler: Schock %.2f | Geld %d | Hand: %s" % [Game.player.shock, Game.money, Game.player.held.display_name if Game.player.held else "-"])
			for guest in Game.social.guests:
				print("      %s: %s @ %s | Angst %.0f | Beziehung %.0f | Hand: %s" % [guest.display_name,
					Guest.State.keys()[guest.state], guest.global_position.snapped(Vector3.ONE * 0.1), guest.fear,
					guest.relation, guest.held.display_name if guest.held else "-"])
				if "--trace-nav" in OS.get_cmdline_user_args():
					print("        Ziel %s  nächster Punkt %s  fertig %s" % [guest.get("_target"), guest.agent.get_next_path_position(), guest.agent.is_navigation_finished()])
	if _shot_path == "":
		return
	_shot_frames += 1
	if _shot_frames == _shot_at:
		get_viewport().get_texture().get_image().save_png(_shot_path)
		get_tree().quit()


func _setup_environment() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color.BLACK
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.35, 0.38, 0.5)
	env.ambient_light_energy = 0.06
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.fog_enabled = true
	env.fog_light_color = Color(0.02, 0.02, 0.03)
	env.fog_density = 0.07
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
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--shot="):
			_shot_path = arg.substr(7)
		elif arg.begins_with("--pos="):
			var v := arg.substr(6).split(",")
			Game.player.global_position = Vector3(v[0].to_float(), v[1].to_float(), v[2].to_float())
			if v.size() > 3:
				Game.player.rotation.y = deg_to_rad(v[3].to_float())
		elif arg.begins_with("--monster="):
			var m := arg.substr(10).split(",")
			var pos := Vector3(m[0].to_float(), m[1].to_float(), m[2].to_float())
			Game.monster.spawn_at(pos)
			Game.director.phase = MonsterDirector.Phase.ACTIVE
		elif arg.begins_with("--frames="):
			_shot_at = arg.substr(9).to_int()
		elif arg.begins_with("--bold="):
			Game.director.boldness = arg.substr(7).to_float()
		elif arg.begins_with("--friend="):
			var friend := Game.social.guest_by_id(arg.substr(9))
			if friend:
				friend.relation = 80.0
		elif arg.begins_with("--kill="):
			var victim := Game.social.guest_by_id(arg.substr(7))
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
		elif arg.begins_with("--challenge="):
			Game.social.challenge(Game.social.guest_by_id(arg.substr(12)))
		elif arg == "--autoplay":
			_autoplay = true
		elif arg == "--party":
			Game.social.start_party("player")
		elif arg.begins_with("--talk="):
			var partner := Game.social.guest_by_id(arg.substr(7))
			Game.player.global_position = partner.global_position + Vector3(0, 0, -1.4)
			Game.player.rotation.y = 0.0
			get_tree().create_timer(1.0).timeout.connect(func() -> void:
				Game.player.rotation.y = PI
				Game.dialog.open(partner))
		elif arg == "--warn":
			Game.director.start_warning()
		elif arg == "--trace":
			_trace = true
			Game.message_posted.connect(func(text: String, _d: float) -> void: print("  » " + text.replace("
", " ")))
		elif arg == "--debug":
			Game.hud.debug_enabled = true
