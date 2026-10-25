// Kerzenwachs (CandleModel, Spielkonzept 7.3), ausgelegt auf das Bild ohne PS1-Look: Wachs ist durchscheinend.
// – Licht greift um die Kerze herum (wrap) und schimmert in der Farbe des Wachses durch (scatter) – keine harte Kante
//   zwischen Licht- und Schattenseite
// – matter Wachsglanz (sheen)
// – brennt sie (instance uniform glow, CandleFlame setzt es), glüht das Wachs unter der Flamme warm von innen: oben am
//   stärksten, nach glow_depth Metern abwärts ausgelaufen
// Ursprung mittig unten, height = Höhe des Wachses (m). Snapping und Filter wie die psx-Shader (Settings.PSX_SHADERS).
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back;
#include "res://shaders/psx_snap.gdshaderinc"

uniform sampler2D albedo_tex : source_color, filter_nearest, hint_default_white;
uniform float height = 0.16;
uniform float wrap = 0.55;
uniform float scatter = 0.2;
uniform float sheen = 0.12;
uniform vec3 glow_color : source_color = vec3(1.0, 0.78, 0.5);
uniform float glow_energy = 1.2;
uniform float glow_depth = 0.035;
instance uniform float glow = 0.0;

varying float y;

void vertex() {
	y = VERTEX.y;
	POSITION = psx_snap_clip(PROJECTION_MATRIX * MODELVIEW_MATRIX * vec4(VERTEX, 1.0));
}

void fragment() {
	ALBEDO = texture(albedo_tex, UV).rgb;
	ROUGHNESS = 0.7;
	float t = smoothstep(height - glow_depth, height, y);
	EMISSION = ALBEDO * glow_color * glow_energy * glow * t * t;
}

void light() {
	float nl = dot(NORMAL, LIGHT);
	float diffuse = max((nl + wrap) / (1.0 + wrap), 0.0);
	float through = max(-nl, 0.0) * scatter;
	DIFFUSE_LIGHT += (vec3(diffuse) + ALBEDO * through) * LIGHT_COLOR * ATTENUATION / PI;
	vec3 half_dir = normalize(LIGHT + VIEW);
	SPECULAR_LIGHT += pow(max(dot(NORMAL, half_dir), 0.0), 24.0) * sheen * LIGHT_COLOR * ATTENUATION;
}
