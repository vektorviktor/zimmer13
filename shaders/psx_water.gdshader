// Poolwasser im PS1-Look: halbtransparent, rein optische Wellen (ohne Physik).
// Grundwellen über wave_time (Spielzeit von PoolWater, steht in der Pause); dazu Wellenringe, die
// PoolWater (scripts/world/pool_water.gd) dort einträgt, wo jemand durchs Wasser geht oder hineinfällt.
// Hohe Kämme und Wellen am Beckenrand brechen zu Schaum.
// Vertex-Snapping wie psx_surface, Licht je Ecke aus den Wellennormalen.
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_disabled, diffuse_lambert, specular_schlick_ggx;

// Muss zu PoolWater.MAX_RIPPLES passen
const int MAX_RIPPLES = 24;

uniform vec4 deep : source_color = vec4(0.05, 0.2, 0.27, 0.7);
uniform vec4 crest : source_color = vec4(0.25, 0.52, 0.58, 0.8);
// Spiegelung im flachen Blickwinkel (Fresnel) – daran sieht man die Wellen
uniform vec3 sheen : source_color = vec3(0.4, 0.55, 0.6);
uniform vec4 foam : source_color = vec4(0.85, 0.92, 0.95, 0.92);
uniform vec3 emission : source_color = vec3(0.02, 0.08, 0.1);
uniform float wave_height = 0.07;      // Meter, Grundwellen (Kamm bis Tal das Doppelte)
uniform float wave_speed = 0.7;
uniform float wave_time = 0.0;
uniform float ripple_height = 0.14;    // Meter bei Stärke 1
uniform float ripple_speed = 1.6;      // m/s, mit der ein Ring nach außen läuft
uniform float ripple_length = 1.1;     // Meter von Kamm zu Kamm
uniform float foam_from = 0.09;        // ab dieser Höhe über der Ruhelage bricht ein Kamm
// Innenkante des Beckens in Weltkoordinaten (x0, z0, x1, z1): dort brechen die Ringe
uniform vec4 pool_rect = vec4(0.0);
// je Ring: x, z, Alter in s, Stärke (0 = frei)
uniform vec4 ripples[MAX_RIPPLES];
uniform float snap_resolution = 140.0;
// Einstellungen → PS1-Look → Vertex-Wackeln (1 = an, 0 = aus)
global uniform float psx_snap;

varying float v_height;
varying float v_ripple;
varying vec3 world_pos;

float base_waves(vec2 p, float t) {
	return sin(p.x * 1.6 + t * 1.3) * 0.45
		+ sin(p.y * 2.1 - t * 1.1) * 0.35
		+ sin((p.x - p.y) * 2.9 + t * 1.9) * 0.2;
}

float ring_waves(vec2 p) {
	float h = 0.0;
	float k = 6.2832 / ripple_length;
	for (int i = 0; i < MAX_RIPPLES; i++) {
		vec4 r = ripples[i];
		if (r.w <= 0.0) {
			continue;
		}
		float d = distance(p, r.xy);
		float x = d - r.z * ripple_speed;   // Abstand zur Wellenfront
		float packet = exp(-x * x / (2.0 * ripple_length * ripple_length));
		float fade = exp(-r.z * 0.7) / (1.0 + d * 0.6);
		h += r.w * packet * fade * cos(k * x);
	}
	return h * ripple_height;
}

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float t = wave_time * wave_speed;
	vec2 p = world_pos.xz;
	float e = 0.1;
	float b = base_waves(p, t) * wave_height;
	float r = ring_waves(p);
	float h = b + r;
	float hx = base_waves(p + vec2(e, 0.0), t) * wave_height + ring_waves(p + vec2(e, 0.0));
	float hz = base_waves(p + vec2(0.0, e), t) * wave_height + ring_waves(p + vec2(0.0, e));
	VERTEX.y += h;
	NORMAL = normalize(vec3(-(hx - h) / e, 1.0, -(hz - h) / e));
	v_height = h;
	v_ripple = r;
	vec4 clip = PROJECTION_MATRIX * (MODELVIEW_MATRIX * vec4(VERTEX, 1.0));
	if (psx_snap > 0.5 && clip.w > 0.0001) {
		vec2 ndc = clip.xy / clip.w;
		ndc = floor(ndc * snap_resolution + 0.5) / snap_resolution;
		clip.xy = ndc * clip.w;
	}
	POSITION = clip;
}

void fragment() {
	vec4 c = mix(deep, crest, smoothstep(-wave_height, wave_height * 1.5, v_height));
	// Brechen: hohe Kämme schäumen, am Beckenrand schon kleinere Ringwellen
	vec2 p = world_pos.xz;
	float edge = min(min(p.x - pool_rect.x, pool_rect.z - p.x), min(p.y - pool_rect.y, pool_rect.w - p.y));
	float near_wall = 1.0 - smoothstep(0.0, 0.6, edge);
	float f = max(smoothstep(foam_from, foam_from * 1.6, v_height),
		near_wall * smoothstep(0.02, 0.07, abs(v_ripple)));
	float fres = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 4.0);
	c.rgb = mix(c.rgb, sheen, fres * 0.7);
	c.a = mix(c.a, 0.95, fres);
	c = mix(c, foam, f);
	ALBEDO = c.rgb;
	ALPHA = c.a;
	ROUGHNESS = mix(0.3, 0.9, f);
	SPECULAR = 0.4;
	EMISSION = emission + sheen * fres * 0.05 + foam.rgb * f * 0.08;
}
