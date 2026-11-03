// Bücher der Bibliotheksregale (Books, ZIM-153): ein Atlas für alle Varianten aus tools/build_books.py (Farbe mit
// Verschattung, Normal Map, Masken). Der Bezug (Maske Rot) bekommt die Farbe je Buch aus INSTANCE_CUSTOM.rgb (linear),
// Gold und Papier bleiben, wie sie sind; Grün ist die Rauheit, Blau das Metall der Goldprägung. Je tiefer im Fach
// (lokal −z, vom Rücken nach hinten), desto dunkler – zwischen die Bretter kommt wenig Licht, und das ist billiger
// als Schatten der Bücher.
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_lambert, specular_schlick_ggx;

uniform sampler2D albedo_tex : source_color, filter_linear_mipmap_anisotropic, repeat_disable;
uniform sampler2D normal_tex : hint_normal, filter_linear_mipmap_anisotropic, repeat_disable;
uniform sampler2D mask_tex : hint_default_white, filter_linear_mipmap_anisotropic, repeat_disable;
// hinten im Fach so viel Licht wie vorn × back_shade, ab back_depth Metern hinter dem Rücken
uniform float back_shade = 0.55;
uniform float back_depth = 0.24;

varying vec3 tint;
varying float back;

void vertex() {
	tint = INSTANCE_CUSTOM.rgb;
	back = clamp(-VERTEX.z / back_depth, 0.0, 1.0);
}

void fragment() {
	vec3 a = texture(albedo_tex, UV).rgb;
	vec3 m = texture(mask_tex, UV).rgb;
	ALBEDO = mix(a, a * tint, m.r) * mix(1.0, back_shade, back);
	ROUGHNESS = m.g;
	METALLIC = m.b;
	SPECULAR = 0.5;
	NORMAL_MAP = texture(normal_tex, UV).rgb;
}
