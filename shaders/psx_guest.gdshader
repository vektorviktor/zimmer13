// Gastmodelle (Spielkonzept 6.0, „Gastmodelle“): wie psx_surface, dazu Einfärben
// über die Maske aus tools/build_guest.py. Punktfarbe R/G/B = Oberteil/Hose/Haare (je Fläche 0 oder 1),
// nur graue Texel werden gefärbt (Haut, Schuhe, Augen bleiben). Gefärbt = Gastfarbe × Helligkeit /
// mittlere Helligkeit des Bereichs – Falten und Maschen bleiben, im Mittel kommt genau die Gastfarbe heraus.
// Haut (außerhalb der gefärbten Texel) wird mit tint_skin multipliziert – GuestBody rechnet den Faktor je Grundkörper aus.
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_lambert, specular_disabled;

uniform sampler2D albedo_tex : source_color, filter_linear_mipmap, hint_default_white;
// Mittlere Helligkeit (linear) von Oberteil, Hose, Haaren in der Textur – aus GuestBody.BODIES
uniform vec3 ref_lum = vec3(0.5);
// Sättigung (linear, max − min), ab der ein Texel nicht mehr als grau gilt
uniform vec2 grey_sat = vec2(0.05, 0.11);

// Gastfarben (linear), je Instanz
instance uniform vec3 tint_top = vec3(0.5);
instance uniform vec3 tint_bottom = vec3(0.3);
instance uniform vec3 tint_hair = vec3(0.4);
// Hautton: Faktor (linear) auf die Hauttexel außerhalb der Färbebereiche – 1 = Haut wie in der Textur
instance uniform vec3 tint_skin = vec3(1.0);
// Vorschau: Hauterkennung magenta zeigen
uniform bool debug_skin = false;

varying vec3 mask;

void vertex() {
	mask = COLOR.rgb;
	vec4 clip = PROJECTION_MATRIX * (MODELVIEW_MATRIX * vec4(VERTEX, 1.0));
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
	// Haut: rot > grün > blau, mäßig gesättigt, nicht zu dunkel (Schuhe, Brauen, Pupillen bleiben)
	float hue = (tex.g - tex.b) / max(tex.r - tex.b, 0.001);
	float skin = step(tex.g, tex.r) * step(tex.b, tex.g) * smoothstep(0.04, 0.08, sat)
		* (1.0 - smoothstep(0.75, 0.9, hue)) * smoothstep(0.03, 0.06, lum)
		* (1.0 - max(m.r, max(m.g, m.b)));
	col = mix(col, col * tint_skin, skin);
	if (debug_skin) {
		col = mix(col, vec3(1.0, 0.0, 1.0), skin);
	}
	ALBEDO = col;
	ROUGHNESS = 1.0;
	SPECULAR = 0.0;
}
