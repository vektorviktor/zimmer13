// Spinnen (Spielkonzept 4.23, scripts/world/spiders.gd): Beine laufen im Vertex-Shader. Eckfarbe des Meshs: r = Phase
// des Beins (0 … 1, abwechselnd wie beim echten Gang), g = Gewicht (0 Körper … 1 Fußspitze). Laufphase und Gangstärke
// kommen je Instanz aus INSTANCE_CUSTOM (x, y) – rechnet das Skript, steht in der Pause –, bei der einzelnen Spinne
// im Gesicht aus den Uniforms. PS1-Wackeln wie psx_surface, beidseitig.
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_disabled, diffuse_lambert, specular_disabled;
#include "res://shaders/psx_snap.gdshaderinc"

uniform vec4 albedo : source_color = vec4(0.035, 0.03, 0.028, 1.0);   // sehr dunkel
uniform float step_swing = 0.022;
uniform float step_lift = 0.012;
uniform bool single = false;
uniform float phase = 0.0;
uniform float gait = 0.0;

void vertex() {
	float w = COLOR.g;
	if (w > 0.0) {
		float base = single ? phase : INSTANCE_CUSTOM.x;
		float g = single ? gait : INSTANCE_CUSTOM.y;
		float ph = base + COLOR.r * 6.2831853;
		VERTEX.z += sin(ph) * step_swing * w * g;
		VERTEX.y += max(0.0, cos(ph)) * step_lift * w * g;
		VERTEX.y += sin(ph * 0.37 + COLOR.r * 3.0) * 0.0015 * w * (1.0 - g);   // zuckt im Stehen
	}
	POSITION = psx_snap_clip(PROJECTION_MATRIX * (MODELVIEW_MATRIX * vec4(VERTEX, 1.0)));
}

void fragment() {
	ALBEDO = albedo.rgb * mix(1.0, 0.75, COLOR.g);
	ROUGHNESS = 0.6;
}
