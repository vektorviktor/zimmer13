// PS1-Look für Blattkarten (Hecken): wie psx_surface (Vertex-Snapping, Nearest-Filter, kein Glanz), dazu
// ausgestanzt nach dem Alpha der Textur und beidseitig. Die Normale kommt von der Fläche unter der Karte und
// zeigt auf beiden Seiten nach außen – die Blätter werden beleuchtet wie die Hecke darunter. Eckfarben
// dunkeln ab (unten im Schatten).
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_disabled, diffuse_lambert, specular_disabled;
#include "res://shaders/psx_snap.gdshaderinc"

uniform vec4 albedo : source_color = vec4(1.0);
uniform sampler2D albedo_tex : source_color, filter_nearest, repeat_disable, hint_default_white;

void vertex() {
	vec4 clip = PROJECTION_MATRIX * (MODELVIEW_MATRIX * vec4(VERTEX, 1.0));
	clip = psx_snap_clip(clip);
	POSITION = clip;
}

void fragment() {
	vec4 tex = texture(albedo_tex, UV);
	if (!FRONT_FACING) {
		NORMAL = -NORMAL;
	}
	ALBEDO = albedo.rgb * tex.rgb * COLOR.rgb;
	ALPHA = tex.a;
	ALPHA_SCISSOR_THRESHOLD = 0.5;
	ROUGHNESS = 1.0;
	SPECULAR = 0.0;
}
