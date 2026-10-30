// Kerzenflamme (CandleModel, Spielkonzept 7.3, Vorbild: Foto einer
// Kerzenflamme). Leuchtet additiv und in HDR – Filmic macht den Kern weiß. Farbe nach der Höhe h im Netz (0 = Fuß,
// 1 = Spitze) und nach dem Blickwinkel auf die Fläche (facing: 1 = Mitte der Flamme, 0 = Rand):
// – Kern: fast weiß, vom Fuß bis gut über die Mitte, nach außen gelb
// – Hülle: gelb, zur Spitze und zum Rand orange, die Spitze blendet aus
// – Fuß: innen dunkel (nicht leuchtende Zone, der Docht schimmert durch), außen ein blauer Saum, der nach oben violett
//   in den Kern übergeht
// halo = true: Lichthof als Billboard (QuadMesh) – ein enger heller und ein weiter schwacher Schein. Er liegt
// HALO_PULL näher zur Kamera (steckt nicht in der Kerze) und blendet vor Flächen dahinter weich aus (Tiefentextur),
// damit dort kein harter Schnitt entsteht.
shader_type spatial;
render_mode blend_add, unshaded, depth_draw_never, cull_back, shadows_disabled, fog_disabled, skip_vertex_transform;

// Höhe der Flamme im Netz (m, Ursprung am Fuß)
uniform float height = 0.044;
uniform float brightness = 1.0;
uniform vec3 core_color : source_color = vec3(1.0, 0.97, 0.9);
uniform vec3 inner_color : source_color = vec3(1.0, 0.8, 0.38);
uniform vec3 outer_color : source_color = vec3(1.0, 0.5, 0.14);
uniform vec3 base_color : source_color = vec3(0.25, 0.35, 1.0);
uniform vec3 violet_color : source_color = vec3(0.8, 0.55, 1.0);
// Leuchtkraft von Kern und Hülle (HDR, > 1 wird zu Weiß gedrückt)
uniform float core_energy = 6.0;
uniform float body_energy = 2.4;
uniform bool halo = false;
uniform float halo_strength = 0.5;
// Lichthof: so weit zur Kamera gezogen (m), so weich vor Flächen dahinter (m)
uniform float halo_pull = 0.06;
uniform float halo_soft = 0.05;
uniform sampler2D depth_tex : hint_depth_texture, filter_nearest;

varying float h;

void vertex() {
	if (halo) {
		vec3 center = (MODELVIEW_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
		float size = length(MODEL_MATRIX[1].xyz);
		float dist = length(center);
		float pull = min(halo_pull, dist * 0.5);
		center -= normalize(center) * pull;
		size *= (dist - pull) / max(dist, 0.001);   // gleich groß wie ohne Zug
		VERTEX = center + vec3(VERTEX.xy * size, 0.0);
		h = 0.5;
	} else {
		h = clamp(VERTEX.y / height, 0.0, 1.0);
		VERTEX = (MODELVIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
		NORMAL = normalize((MODELVIEW_MATRIX * vec4(NORMAL, 0.0)).xyz);
	}
	POSITION = PROJECTION_MATRIX * vec4(VERTEX, 1.0);
}

void fragment() {
	if (halo) {
		float r = length(UV - vec2(0.5)) * 2.0;
		float glow = exp(-r * r * 22.0) + 0.22 * exp(-r * r * 5.0);
		glow *= 1.0 - smoothstep(0.75, 1.0, r);
		float depth = texture(depth_tex, SCREEN_UV).r;
		vec4 view = INV_PROJECTION_MATRIX * vec4(SCREEN_UV * 2.0 - 1.0, depth, 1.0);
		float behind = -view.z / view.w - (-VERTEX.z);
		glow *= clamp(behind / halo_soft, 0.0, 1.0);
		ALBEDO = mix(inner_color, outer_color, 0.45) * glow * halo_strength * brightness;
	} else {
		float facing = clamp(abs(dot(NORMAL, VIEW)), 0.0, 1.0);
		// Hülle: gelb, zur Spitze und zum Rand orange; Rand und Spitze blenden aus
		vec3 body = mix(inner_color, outer_color, clamp(smoothstep(0.45, 1.0, h) * 0.8 + (1.0 - facing) * 0.5, 0.0, 1.0));
		float fade = smoothstep(0.0, 0.5, facing) * (1.0 - smoothstep(0.7, 1.0, h) * 0.8);
		vec3 col = body * body_energy * fade;
		// Kern
		float core = smoothstep(0.4, 0.95, facing) * smoothstep(0.12, 0.3, h) * (1.0 - smoothstep(0.5, 0.88, h));
		col = mix(col, core_color * core_energy, core);
		// Fuß: schwach blau, zum Rand etwas kräftiger, nach oben violett in den Kern – innen bleibt es dunkel genug, dass
		// der Docht durchscheint
		float foot = 1.0 - smoothstep(0.1, 0.32, h);
		vec3 rim = mix(base_color, violet_color, smoothstep(0.08, 0.28, h))
			* (0.3 + 0.7 * (1.0 - smoothstep(0.3, 0.95, facing))) * 0.75 * smoothstep(0.0, 0.08, h);
		col = mix(col, rim, foot);
		ALBEDO = col * brightness;
	}
}
