// Bildröhre der Spielautomaten (ArcadeMachine, Spielkonzept 6.10): das kleine Pixelbild der Vorführung auf der
// gewölbten Scheibe aus tools/build_arcade.py. picture_rect = Lage des Bildes in den UVs der Scheibe (links, unten,
// rechts, oben – v läuft auf der Scheibe nach oben); außerhalb schwarzes Glas. Zeilen wie bei einer Röhre, zum Rand
// hin dunkler; das Glas spiegelt.
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_lambert, specular_schlick_ggx;

uniform sampler2D picture : source_color, filter_nearest;
uniform vec4 picture_rect = vec4(0.25, 0.22, 0.75, 0.8);
uniform vec2 picture_px = vec2(120.0, 160.0);
uniform vec4 screen_rect = vec4(0.046, 0.187, 0.954, 0.813);   // ganze Scheibe in den UVs
uniform float brightness = 1.6;

void fragment() {
	vec2 p = (UV - picture_rect.xy) / (picture_rect.zw - picture_rect.xy);
	vec3 c = vec3(0.0);
	if (p.x >= 0.0 && p.x <= 1.0 && p.y >= 0.0 && p.y <= 1.0) {
		c = texture(picture, vec2(p.x, 1.0 - p.y)).rgb;
		float row = fract(p.y * picture_px.y);
		c *= mix(0.55, 1.0, sin(row * PI));            // Zeilen
	}
	vec2 s = (UV - screen_rect.xy) / (screen_rect.zw - screen_rect.xy) * 2.0 - 1.0;
	float edge = 1.0 - smoothstep(0.6, 1.05, max(abs(s.x), abs(s.y)));
	ALBEDO = vec3(0.015);
	ROUGHNESS = 0.12;
	SPECULAR = 0.5;
	EMISSION = c * brightness * mix(0.55, 1.0, edge) + vec3(0.004, 0.006, 0.008) * edge;
}
