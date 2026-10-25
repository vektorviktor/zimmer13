// Kerzenflamme (CandleModel, Spielkonzept 7.3): additiv und ungeschattet, Farbe nach der Höhe im Netz – unten ein
// bläulicher Saum um den dunklen Fuß am Docht, darüber der fast weiße Kern, nach oben gelb bis orange an der Spitze.
// Zum Rand hin (Blick streift die Fläche) blendet sie weich aus. halo = true: dieselbe Farbe als Schein um die Flamme –
// ein Billboard (QuadMesh), radial ausblendend.
shader_type spatial;
render_mode blend_add, unshaded, depth_draw_never, cull_back, shadows_disabled, fog_disabled, skip_vertex_transform;
#include "res://shaders/psx_snap.gdshaderinc"

// Höhe der Flamme im Netz (m, Ursprung am Fuß)
uniform float height = 0.044;
uniform float brightness = 1.6;
uniform vec3 core_color : source_color = vec3(1.0, 0.96, 0.82);
uniform vec3 mid_color : source_color = vec3(1.0, 0.78, 0.32);
uniform vec3 tip_color : source_color = vec3(1.0, 0.45, 0.12);
uniform vec3 base_color : source_color = vec3(0.35, 0.42, 1.0);
// Schärfe des Randes: größer = schmalerer heller Kern
uniform float edge = 1.6;
uniform bool halo = false;
uniform float halo_strength = 0.35;

varying float h;

void vertex() {
	if (halo) {
		vec3 center = (MODELVIEW_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
		float size = length(MODEL_MATRIX[1].xyz);
		VERTEX = center + vec3(VERTEX.xy * size, 0.0);
		h = 0.5;
	} else {
		h = clamp(VERTEX.y / height, 0.0, 1.0);
		VERTEX = (MODELVIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
		NORMAL = normalize((MODELVIEW_MATRIX * vec4(NORMAL, 0.0)).xyz);
	}
	POSITION = psx_snap_clip(PROJECTION_MATRIX * vec4(VERTEX, 1.0));
}

void fragment() {
	if (halo) {
		float r = length(UV - vec2(0.5)) * 2.0;
		float a = pow(clamp(1.0 - r, 0.0, 1.0), 2.2);
		ALBEDO = mix(mid_color, tip_color, 0.4) * a * halo_strength * brightness;
	} else {
		float facing = clamp(abs(dot(NORMAL, VIEW)), 0.0, 1.0);
		float body = pow(facing, edge);
		vec3 col = mix(core_color, mid_color, smoothstep(0.25, 0.6, h));
		col = mix(col, tip_color, smoothstep(0.65, 1.0, h));
		// Fuß: blauer Saum außen, innen dunkel (der Docht schimmert durch)
		float foot = 1.0 - smoothstep(0.0, 0.22, h);
		col = mix(col, base_color * (1.0 - body) * 0.8, foot);
		// Spitze und Rand laufen aus
		float fade = body * (1.0 - smoothstep(0.75, 1.0, h) * 0.6);
		ALBEDO = col * fade * brightness;
	}
}
