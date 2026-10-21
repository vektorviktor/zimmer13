// PS1-Look für Blattkarten (Hecken): wie psx_surface (Vertex-Snapping, Nearest-Filter, kein Glanz), dazu
// ausgestanzt nach dem Alpha der Textur und beidseitig. Die Normale kommt von der Fläche unter der Karte und
// zeigt auf beiden Seiten nach außen – die Blätter werden beleuchtet wie die Hecke darunter. Eckfarben
// dunkeln ab (unten im Schatten).
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_disabled, diffuse_lambert, specular_disabled;

uniform vec4 albedo : source_color = vec4(1.0);
uniform sampler2D albedo_tex : source_color, filter_nearest, repeat_disable, hint_default_white;
uniform float snap_resolution = 140.0;
// Einstellungen → PS1-Look → Vertex-Wackeln (1 = an, 0 = aus)
global uniform float psx_snap;

void vertex() {
	vec4 clip = PROJECTION_MATRIX * (MODELVIEW_MATRIX * vec4(VERTEX, 1.0));
	if (psx_snap > 0.5 && clip.w > 0.0001) {
		vec2 ndc = clip.xy / clip.w;
		ndc = floor(ndc * snap_resolution + 0.5) / snap_resolution;
		clip.xy = ndc * clip.w;
	}
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
