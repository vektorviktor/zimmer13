// Fledermäuse (Spielkonzept 4.22, scripts/world/bats.gd): ein MultiMesh, je Instanz schlagen die Flügel um die
// Schulter (|x| = SHOULDER). INSTANCE_CUSTOM.x = Phase des Flügelschlags (rechnet das Skript, steht in der Pause),
// .y = angelegt (0 fliegt, 1 hängt mit eingeschlagenen Flügeln). PS1-Wackeln wie psx_surface, beidseitig.
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_disabled, diffuse_lambert, specular_disabled;
#include "res://shaders/psx_snap.gdshaderinc"

uniform vec4 albedo : source_color = vec4(0.07, 0.055, 0.05, 1.0);
uniform float shoulder = 0.02;
uniform float flap_amp = 0.95;
uniform float flap_lift = 0.15;
uniform float fold_angle = -1.9;

void vertex() {
	float side = sign(VERTEX.x);
	float r = abs(VERTEX.x) - shoulder;
	if (r > 0.0) {
		float fold = INSTANCE_CUSTOM.y;
		float flap = sin(INSTANCE_CUSTOM.x) * flap_amp + flap_lift;
		float a = mix(flap, fold_angle, fold);
		float reach = r * mix(1.0, 0.45, fold);
		VERTEX.x = side * (shoulder + reach * cos(a));
		VERTEX.y += reach * sin(a);
		NORMAL = normalize(vec3(-side * sin(a), cos(a), 0.0));
	}
	POSITION = psx_snap_clip(PROJECTION_MATRIX * (MODELVIEW_MATRIX * vec4(VERTEX, 1.0)));
}

void fragment() {
	ALBEDO = albedo.rgb;
}
