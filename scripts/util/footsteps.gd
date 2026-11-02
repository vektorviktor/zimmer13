class_name Footsteps
extends AudioStreamPlayer3D
## Schritte zum Hören, an den Füßen von Spieler und Gästen. Bisher auf Teppich (Flure), Fliesen (Lobby, Küche) und
## altem, knarrendem Holz – Rasen bleibt stumm, bis es einen Klang dafür gibt. Reiner Ton: Lärm für Monster und Gäste macht weiter
## `Game.noise("step", …)` (Spielkonzept 4.15, Teppich schluckt dort Schritte).

## Bodenart (Textur-Id aus TexGen) → Klänge, je Schritt ein zufälliger (nie zweimal hintereinander derselbe)
const SOUNDS := {
	"carpet": ["res://assets/sound/step_carpet.wav"],   ## Teppichflure
	"tiles": ["res://assets/sound/step_tiles.wav"],     ## Lobby, Küche
	## Böden mit Meta "floor" = "wood": Speisesaal, Kegelbahn, Holzdeck, Dachboden – jeder Schritt knarrt
	"wood": ["res://assets/sound/step_wood_1.wav", "res://assets/sound/step_wood_2.wav",
		"res://assets/sound/step_wood_3.wav", "res://assets/sound/step_wood_4.wav", "res://assets/sound/step_wood_5.wav",
		"res://assets/sound/step_wood_6.wav", "res://assets/sound/step_wood_7.wav", "res://assets/sound/step_wood_8.wav"],
## (ein Klang je Boden reicht – die Tonhöhe streut)
}
## Texturen, die `floor_under` erkennt
const FLOOR_TEXTURES := ["carpet", "grass", "tiles"]
const VOLUME_DB := -8.0
const RUN_DB := 4.0               ## Rennen: so viel lauter
const CHILD_DB := -4.0            ## Kinder treten leiser auf …
const CHILD_PITCH := 1.15         ## … und heller
const PITCH_JITTER := 0.08        ## jeder Schritt klingt etwas anders
const UNIT := 2.0                 ## bis hier ungedämpft
const RANGE := 12.0               ## ab hier stumm

static var _streams := {}

var _foot := -1   ## zuletzt gespielter Klang aus der Liste des Bodens


func _ready() -> void:
	unit_size = UNIT
	max_distance = RANGE
	position.y = 0.05


## Ein Schritt am eigenen Ort – Bodenart vorher mit `floor_under` holen. Ohne Klang für den Boden: nichts.
func step(floor_id: String, running := false, child := false) -> void:
	if not SOUNDS.has(floor_id) or Settings.effects_volume <= 0.0:
		return
	var list: Array = SOUNDS[floor_id]
	var foot := randi() % list.size()
	if list.size() > 1 and foot == _foot:
		foot = (foot + 1 + randi() % (list.size() - 1)) % list.size()
	_foot = foot
	if not _streams.has(list[foot]):
		_streams[list[foot]] = load(list[foot])
	stream = _streams[list[foot]]
	volume_db = VOLUME_DB + (RUN_DB if running else 0.0) + (CHILD_DB if child else 0.0) \
		+ linear_to_db(Settings.effects_volume)
	pitch_scale = (CHILD_PITCH if child else 1.0) * randf_range(1.0 - PITCH_JITTER, 1.0 + PITCH_JITTER)
	play()


## Boden unter einem Körper: Textur-Id aus FLOOR_TEXTURES, "" für alles andere, "air" ohne Boden. Materialien ohne
## TexGen-Textur (Fototexturen, Mat.photo) nennen ihre Bodenart im Meta "floor" (Lobbymarmor = "tiles").
## Teppichläufer haben keine Kollision – darunter liegt im Flur ohnehin Teppich (Spielkonzept 7.5).
static func floor_under(body: Node3D) -> String:
	var from := body.global_position + Vector3.UP * 0.1
	var query := PhysicsRayQueryParameters3D.create(from, from + Vector3.DOWN * 0.5, 1)
	var hit := body.get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return "air"
	for child in (hit["collider"] as Node).get_children():
		var mi := child as MeshInstance3D
		if mi and mi.material_override is ShaderMaterial:
			if mi.material_override.has_meta("floor"):
				return mi.material_override.get_meta("floor")
			var tex = (mi.material_override as ShaderMaterial).get_shader_parameter("albedo_tex")
			for id in FLOOR_TEXTURES:
				if tex == TexGen.get_tex(id):
					return id
	return ""
