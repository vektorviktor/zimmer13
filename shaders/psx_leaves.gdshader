// PS1-Look für Blattkarten (Hecken): wie psx_surface (Vertex-Snapping, Nearest-Filter, kein Glanz), dazu
// ausgestanzt nach dem Alpha der Textur und beidseitig. Die Normale kommt von der Fläche unter der Karte und
// zeigt auf beiden Seiten nach außen – die Blätter werden beleuchtet wie die Hecke darunter. Eckfarben
// dunkeln ab (unten im Schatten).
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_disabled, diffuse_lambert, specular_disabled;
#include "res://shaders/psx_snap.gdshaderinc"

uniform vec4 albedo : source_color = vec4(1.0);
uniform sampler2D albedo_tex : source_color, filter_nearest, repeat_disable, hint_default_white;
// Bäume (sway 1): Blätter flattern im Wind (Weather, Spielkonzept 7.8) – wenige Zentimeter, oben in der Krone mehr;
// Stärke und Spielzeit global aus Weather. Hecken bleiben still (sway 0).
uniform float sway = 0.0;
global uniform float wind_strength;
global uniform float weather_time;

void vertex() {
	if (sway > 0.0) {
		vec3 w = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
		float reach = smoothstep(1.0, 8.0, VERTEX.y) * sway * wind_strength;
		float t = weather_time;
		float flutter = sin(t * 7.0 + w.x * 3.1 + w.y * 2.3 + w.z * 1.7) * 0.6 + sin(t * 11.3 + w.z * 4.1 - w.x * 2.2) * 0.4;
		float bend = sin(t * 0.9 + w.x * 0.15 + w.z * 0.11) * 0.5 + 0.5;
		vec3 push = vec3(0.8, 0.0, 0.3) * bend * 0.035 + vec3(flutter * 0.6, flutter * 0.5, flutter * 0.4) * 0.025;
		VERTEX += (inverse(mat3(MODEL_MATRIX)) * push) * reach;
	}
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
