// Poolwasser: halbtransparent, rein optische Wellen (ohne Physik).
// Grundwellen über wave_time (Spielzeit von PoolWater, steht in der Pause); dazu Wellenringe, die
// PoolWater (scripts/world/pool_water.gd) dort einträgt, wo jemand durchs Wasser geht oder hineinfällt.
// Die Wände werfen die Ringe zurück (Spiegelquellen hinter jeder Wand und Ecke, je Abprall wall_reflect),
// alles addiert sich. Hohe Kämme und Wellen am Beckenrand brechen zu Schaum.
// Monster in der Nähe (von PoolWater gesetzt): base_scale 0 = spiegelglatt, tremor = feine zitternde
// Ringe von seiner Seite, slosh = das Becken schwappt wie eine Badewanne.
// Licht je Ecke aus den Wellennormalen.
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_disabled, diffuse_lambert, specular_schlick_ggx;

// Muss zu PoolWater.MAX_RIPPLES passen
const int MAX_RIPPLES = 32;

uniform vec4 deep : source_color = vec4(0.05, 0.2, 0.27, 0.7);
uniform vec4 crest : source_color = vec4(0.25, 0.52, 0.58, 0.8);
// Spiegelung im flachen Blickwinkel (Fresnel) – daran sieht man die Wellen
uniform vec3 sheen : source_color = vec3(0.4, 0.55, 0.6);
uniform vec4 foam : source_color = vec4(0.85, 0.92, 0.95, 0.92);
uniform vec3 emission : source_color = vec3(0.02, 0.08, 0.1);
uniform float wave_height = 0.07;      // Meter, Grundwellen (Kamm bis Tal das Doppelte)
uniform float wave_speed = 0.7;
uniform float wave_time = 0.0;
uniform float base_scale = 1.0;        // 0 = glatt, > 1 = unruhig
uniform float ripple_height = 0.14;    // Meter bei Stärke 1
uniform float ripple_speed = 1.6;      // m/s, mit der ein Ring nach außen läuft
uniform float ripple_length = 1.1;     // Meter von Kamm zu Kamm
uniform float ripple_decay = 0.35;     // je Sekunde (exp), damit sie den Rückweg von der Wand schaffen
uniform float wall_reflect = 0.6;      // so viel bleibt je Abprall an einer Wand
uniform float foam_from = 0.09;        // ab dieser Höhe über der Ruhelage bricht ein Kamm
// höchstens so weit steigt das Wasser (knapp unter der Beckenkante)
uniform float max_rise = 0.27;
// Zittern: Stärke 0..1, Ausgangspunkt am Beckenrand (x, z)
uniform float tremor = 0.0;
uniform vec2 tremor_src = vec2(0.0);
// Schwappen: Höhe in Metern, Phase der Längs- und der Querwelle
uniform float slosh = 0.0;
uniform vec2 slosh_phase = vec2(0.0);
// Innenkante des Beckens in Weltkoordinaten (x0, z0, x1, z1): dort brechen die Ringe
uniform vec4 pool_rect = vec4(0.0);
// je Ring: x, z, Alter in s, Stärke (0 = frei)
uniform vec4 ripples[MAX_RIPPLES];

varying float v_height;
varying float v_ripple;
varying float v_slosh;
varying vec3 world_pos;

float base_waves(vec2 p, float t) {
	return sin(p.x * 1.6 + t * 1.3) * 0.45
		+ sin(p.y * 2.1 - t * 1.1) * 0.35
		+ sin((p.x - p.y) * 2.9 + t * 1.9) * 0.2;
}

// Ein Ring von src aus, so alt; d = zurückgelegter Weg (bei Spiegelquellen samt Umweg über die Wand)
float ring(vec2 p, vec2 src, float age) {
	float d = distance(p, src);
	float x = d - age * ripple_speed;   // Abstand zur Wellenfront
	float packet = exp(-x * x / (2.0 * ripple_length * ripple_length));
	return packet * cos(6.2832 / ripple_length * x) / sqrt(1.0 + d * 0.8);
}

float ring_waves(vec2 p) {
	float h = 0.0;
	vec2 lo = pool_rect.xy;
	vec2 hi = pool_rect.zw;
	for (int i = 0; i < MAX_RIPPLES; i++) {
		vec4 r = ripples[i];
		if (r.w <= 0.0) {
			continue;
		}
		vec2 s = r.xy;
		vec2 m_lo = 2.0 * lo - s;   // hinter der West- bzw. Nordwand gespiegelt
		vec2 m_hi = 2.0 * hi - s;   // hinter der Ost- bzw. Südwand
		float once = ring(p, vec2(m_lo.x, s.y), r.z) + ring(p, vec2(m_hi.x, s.y), r.z)
			+ ring(p, vec2(s.x, m_lo.y), r.z) + ring(p, vec2(s.x, m_hi.y), r.z);
		float corners = ring(p, m_lo, r.z) + ring(p, m_hi, r.z)
			+ ring(p, vec2(m_lo.x, m_hi.y), r.z) + ring(p, vec2(m_hi.x, m_lo.y), r.z);
		float total = ring(p, s, r.z) + wall_reflect * once + wall_reflect * wall_reflect * corners;
		h += r.w * exp(-r.z * ripple_decay) * total;
	}
	return h * ripple_height;
}

// Stehende Welle der Länge nach (ein Ende hoch, das andere tief) und eine kleinere quer dazu
float slosh_wave(vec2 p) {
	vec2 u = (p - pool_rect.xy) / max(pool_rect.zw - pool_rect.xy, vec2(0.1));
	return slosh * (cos(3.1416 * u.x) * sin(slosh_phase.x) + 0.4 * cos(3.1416 * u.y) * sin(slosh_phase.y));
}

float height(vec2 p, float t) {
	return min(base_waves(p, t) * wave_height * base_scale + ring_waves(p) + slosh_wave(p), max_rise);
}

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float t = wave_time * wave_speed;
	vec2 p = world_pos.xz;
	float e = 0.1;
	v_ripple = ring_waves(p);
	v_slosh = slosh_wave(p);
	float h = min(base_waves(p, t) * wave_height * base_scale + v_ripple + v_slosh, max_rise);
	float hx = height(p + vec2(e, 0.0), t);
	float hz = height(p + vec2(0.0, e), t);
	VERTEX.y += h;
	NORMAL = normalize(vec3(-(hx - h) / e, 1.0, -(hz - h) / e));
	v_height = h;
	vec4 clip = PROJECTION_MATRIX * (MODELVIEW_MATRIX * vec4(VERTEX, 1.0));
	POSITION = clip;
}

void fragment() {
	vec2 p = world_pos.xz;
	// Zittern: alle 0,9 s läuft ein Stoß feiner Ringe vom Rand her übers Wasser – nur im Licht zu sehen
	if (tremor > 0.001) {
		float d = distance(p, tremor_src);
		float beat = fract((wave_time - d / 2.5) / 0.9);
		float env = exp(-beat * 5.0) * tremor / (1.0 + d * 0.12);
		float slope = cos(d * 6.2832 / 0.22 - wave_time * 25.0) * env * 0.5;
		vec2 dir = (p - tremor_src) / max(d, 0.001);
		vec3 tilt = vec3(-dir.x * slope, 0.0, -dir.y * slope);
		NORMAL = normalize(NORMAL + (VIEW_MATRIX * vec4(tilt, 0.0)).xyz);
	}
	vec4 c = mix(deep, crest, smoothstep(-wave_height, wave_height * 1.5, v_height));
	// Brechen: hohe Kämme schäumen, am Beckenrand schon kleinere Ringwellen und das Schwappen
	float edge = min(min(p.x - pool_rect.x, pool_rect.z - p.x), min(p.y - pool_rect.y, pool_rect.w - p.y));
	float near_wall = 1.0 - smoothstep(0.0, 0.6, edge);
	float f = max(smoothstep(foam_from, foam_from * 1.6, v_height),
		near_wall * max(smoothstep(0.02, 0.07, abs(v_ripple)), smoothstep(0.06, 0.14, abs(v_slosh))));
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
