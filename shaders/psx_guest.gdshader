// PS1-Look für die Gastmodelle (Spielkonzept 6.0, „Gastmodelle“): wie psx_surface, dazu Einfärben
// über die Maske aus tools/build_guest.py. Punktfarbe R/G/B = Oberteil/Hose/Haare (je Fläche 0 oder 1),
// nur graue Texel werden gefärbt (Haut, Schuhe, Augen bleiben). Gefärbt = Gastfarbe × Helligkeit /
// mittlere Helligkeit des Bereichs – Falten und Maschen bleiben, im Mittel kommt genau die Gastfarbe heraus.
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_lambert, specular_disabled;

uniform sampler2D albedo_tex : source_color, filter_nearest, hint_default_white;
uniform float snap_resolution = 140.0;
// Mittlere Helligkeit (linear) von Oberteil, Hose, Haaren in der Textur – aus GuestBody.BODIES
uniform vec3 ref_lum = vec3(0.5);
// Sättigung (linear, max − min), ab der ein Texel nicht mehr als grau gilt
uniform vec2 grey_sat = vec2(0.05, 0.11);
global uniform float psx_snap;

// Gastfarben (linear), je Instanz
instance uniform vec3 tint_top = vec3(0.5);
instance uniform vec3 tint_bottom = vec3(0.3);
instance uniform vec3 tint_hair = vec3(0.4);

varying vec3 mask;

void vertex() {
	mask = COLOR.rgb;
	vec4 clip = PROJECTION_MATRIX * (MODELVIEW_MATRIX * vec4(VERTEX, 1.0));
	if (psx_snap > 0.5 && clip.w > 0.0001) {
		vec2 ndc = clip.xy / clip.w;
		ndc = floor(ndc * snap_resolution + 0.5) / snap_resolution;
		clip.xy = ndc * clip.w;
	}
	POSITION = clip;
}

void fragment() {
	vec3 tex = texture(albedo_tex, UV).rgb;
	float lum = dot(tex, vec3(0.2126, 0.7152, 0.0722));
	float sat = max(tex.r, max(tex.g, tex.b)) - min(tex.r, min(tex.g, tex.b));
	float grey = 1.0 - smoothstep(grey_sat.x, grey_sat.y, sat);
	vec3 m = step(vec3(0.5), mask) * grey;
	vec3 col = tex;
	col = mix(col, tint_top * lum / max(ref_lum.x, 0.01), m.r);
	col = mix(col, tint_bottom * lum / max(ref_lum.y, 0.01), m.g);
	col = mix(col, tint_hair * lum / max(ref_lum.z, 0.01), m.b);
	ALBEDO = col;
	ROUGHNESS = 1.0;
	SPECULAR = 0.0;
}
