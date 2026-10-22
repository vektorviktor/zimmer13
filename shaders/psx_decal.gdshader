// PS1-Look für flache Auflagen mit Umriss aus dem Alpha der Textur (Kürbismatsch, Spielkonzept 5.8): wie psx_surface
// (Vertex-Snapping, Nearest-Filter, kein Glanz), leicht zur Kamera gezogen wie Mat.layer, damit der Boden beim
// Snapping nicht durchflimmert. `fade` blendet stufenlos aus (echte Transparenz statt Raster: Das Verblassen soll
// kaum merkbar sein).
shader_type spatial;
render_mode blend_mix, depth_draw_never, cull_back, diffuse_lambert, specular_disabled;
#include "res://shaders/psx_snap.gdshaderinc"

uniform vec4 albedo : source_color = vec4(1.0);
uniform sampler2D albedo_tex : source_color, filter_nearest, repeat_disable, hint_default_white;
// 1 = frisch, 0 = verschwunden
uniform float fade = 1.0;
uniform float layer_pull = 0.004;

void vertex() {
	vec4 view = MODELVIEW_MATRIX * vec4(VERTEX, 1.0);
	view.xyz *= 1.0 - layer_pull;
	vec4 clip = PROJECTION_MATRIX * view;
	clip = psx_snap_clip(clip);
	POSITION = clip;
}

void fragment() {
	vec4 tex = texture(albedo_tex, UV);
	if (tex.a < 0.5) {
		discard;
	}
	ALBEDO = albedo.rgb * tex.rgb;
	ALPHA = fade;
	ROUGHNESS = 1.0;
	SPECULAR = 0.0;
}
