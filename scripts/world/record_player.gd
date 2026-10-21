class_name RecordPlayer
extends StaticBody3D
## Plattenspieler in der Lobby: Feier starten oder Musik ausschalten (Spielkonzept 7.1).
## Modell aus tools/build_record_player.py: „body“ und die drehbare Platte „record“.
## Solange Musik läuft, steigen Noten in Regenbogenfarben aus dem Trichter.

const MODEL := "res://assets/models/record_player.glb"
## Das Modell ist 0,64 × 0,54 m (Trichter nach −X/−Z) – so verschoben steht es mittig auf dem Tisch.
const MODEL_OFFSET := Vector3(0.16, 0, 0.02)
## Notenbilder (rot gemalt, der Shader ersetzt den Farbton), je 32 × 32
const NOTES := "res://assets/textures/note_%d.png"
const NOTE_COUNT := 4
## Trichteröffnung (Modellraum), aus der die Noten steigen
const HORN_MOUTH := Vector3(-0.3, 0.62, -0.1)
const NOTE_SIZE := 0.13
## Feiermusik: das Original (SynthAudio, "") und zwei Stücke als MP3 – jede Feier spielt ein anderes als die letzte
const TRACKS := ["", "res://assets/sound/party_1.mp3", "res://assets/sound/party_2.mp3"]
const TRACK_GAIN := 0.8   ## MP3s sind lauter abgemischt als der Synthesizer

var playing := false
var track := -1           ## Index in TRACKS (-1: noch keine Feier)

var _music: AudioStreamPlayer
var _level := 0.0         ## Lautstärke der MP3 (0..1, wie SynthAudio.music)

var _disc: MeshInstance3D
var _notes: CPUParticles3D


func _ready() -> void:
	collision_layer = 4
	collision_mask = 0
	set_meta("interactable", self)
	var model: Node3D = (load(MODEL) as PackedScene).instantiate()
	model.position = MODEL_OFFSET
	add_child(model)
	for m: MeshInstance3D in model.find_children("*", "MeshInstance3D", true, false):
		m.material_override = Mat.model(MODEL, m)
	_disc = model.find_child("record", true, false) as MeshInstance3D
	# Gehäuse und Trichter
	Geo.add_box_shape(self, Vector3(0.34, 0.2, 0.34), MODEL_OFFSET + Vector3(0, 0.1, 0))
	Geo.add_box_shape(self, Vector3(0.37, 0.5, 0.42), MODEL_OFFSET + Vector3(-0.29, 0.45, -0.08))
	_build_notes()
	_music = AudioStreamPlayer.new()
	add_child(_music)


func _process(delta: float) -> void:
	if playing:
		_disc.rotation.y += delta * 3.5


func set_playing(value: bool) -> void:
	if value and not playing:
		track = randi() % TRACKS.size() if track < 0 else (track + randi_range(1, TRACKS.size() - 1)) % TRACKS.size()
		if TRACKS[track] != "":
			var stream := load(TRACKS[track]) as AudioStreamMP3
			stream.loop = true
			_music.stream = stream
			_level = 0.0
			_music.volume_db = linear_to_db(0.0001)
			_music.play()
		if "--trace" in OS.get_cmdline_user_args():
			print("[Feier] Musik: %s" % (TRACKS[track].get_file() if TRACKS[track] != "" else "Original (SynthAudio)"))
	elif not value:
		_music.stop()
	playing = value
	_notes.emitting = value


## Spielt das Original (SynthAudio) statt einer MP3?
func synth_track() -> bool:
	return playing and TRACKS[track] == ""


## Lautstärke der MP3 sanft auf level (0..1) bringen – Social rechnet sie wie beim Synthesizer aus der Entfernung.
func fade_to(level: float, delta: float) -> void:
	_level = move_toward(_level, level if playing and not synth_track() else 0.0, delta)
	_music.volume_db = linear_to_db(maxf(_level * TRACK_GAIN * Settings.music_volume, 0.0001))


## Noten: steigen langsam, schaukeln und kippen, leuchten und wandern dabei durch den Regenbogen.
func _build_notes() -> void:
	var sheet := Image.create(32 * NOTE_COUNT, 32, false, Image.FORMAT_RGBA8)
	for i in NOTE_COUNT:
		var img := (load(NOTES % (i + 1)) as Texture2D).get_image()
		img.convert(Image.FORMAT_RGBA8)
		sheet.blit_rect(img, Rect2i(0, 0, 32, 32), Vector2i(32 * i, 0))
	var mat := Mat.particle(ImageTexture.create_from_image(sheet), 1.3, NOTE_COUNT)
	mat.set_shader_parameter("rainbow", true)
	mat.set_shader_parameter("hue_drift", 0.6)
	mat.set_shader_parameter("brighten", 1.8)
	mat.set_shader_parameter("sway", 0.06)
	mat.set_shader_parameter("tilt", 0.35)
	mat.set_shader_parameter("sway_cycles", 1.5)
	_notes = Geo.particles(6, 3.2, NOTE_SIZE, mat, 0.08, 0.35)
	_notes.position = MODEL_OFFSET + HORN_MOUTH
	_notes.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	_notes.emission_sphere_radius = 0.1
	_notes.direction = Vector3(-0.4, 1, -0.3)
	_notes.spread = 25.0
	_notes.gravity = Vector3(0, 0.04, 0)
	_notes.initial_velocity_min = 0.22
	_notes.initial_velocity_max = 0.38
	_notes.damping_min = 0.02
	_notes.damping_max = 0.05
	_notes.scale_amount_min = 0.8
	_notes.scale_amount_max = 1.15
	_notes.emitting = playing
	add_child(_notes)


func get_prompt(_player: Player) -> String:
	return "Musik ausschalten [E]" if playing else "Feier in der Lobby starten [E]"


func interact(_player: Player) -> void:
	if playing:
		Game.social.end_party("Du schaltest die Musik aus.")
	else:
		Game.social.start_party("player")
