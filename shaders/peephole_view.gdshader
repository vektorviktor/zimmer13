shader_type canvas_item;
// Blick durch den Türspion (PeepholeView, Spielkonzept 7.17): Das Flurbild der Spionkamera (geradlinig, Bildwinkel
// cam_fov) wird zum Fischauge mit field Grad umgerechnet (stereografisch – die Mitte bleibt groß), in einem runden
// Ausschnitt mit Messingrand, leicht unscharf, mit Vignette. dim dunkelt nach dem Licht im Flur ab. eye (0..1)
// blendet das Auge des Leviathans ein, das die Linse füllt (kein Gore: Lid, Iris, Pupille, Glanz).

uniform sampler2D view : filter_linear, repeat_disable;
uniform float cam_fov = 150.0;      // Bildwinkel der Kamera (Grad)
uniform float field = 150.0;        // Bildwinkel im Spion (Grad)
uniform float radius = 0.66;        // Ausschnitt: Anteil der halben Bildhöhe
uniform float blur = 1.4;           // Unschärfe in Pixeln des Flurbilds
uniform float px = 512.0;           // Auflösung des Flurbilds
uniform float dim = 1.0;            // Helligkeit nach dem Licht im Flur
uniform float eye = 0.0;
uniform float pupil = 0.32;         // Pupille als Anteil der Iris
uniform vec2 gaze = vec2(0.0);      // das Auge wandert ein wenig
uniform float lid = 0.0;            // 0 offen, 1 geschlossen

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0)), u.x), u.y);
}

float fbm(vec2 p) {
	float v = 0.0;
	float a = 0.5;
	for (int i = 0; i < 4; i++) {
		v += a * noise(p);
		p *= 2.03;
		a *= 0.5;
	}
	return v;
}

vec3 sample_view(vec2 uv) {
	vec2 o = vec2(blur / px);
	vec3 c = texture(view, uv).rgb * 0.36;
	c += texture(view, uv + vec2(o.x, 0.0)).rgb * 0.16;
	c += texture(view, uv - vec2(o.x, 0.0)).rgb * 0.16;
	c += texture(view, uv + vec2(0.0, o.y)).rgb * 0.16;
	c += texture(view, uv - vec2(0.0, o.y)).rgb * 0.16;
	return c;
}

// Auge in Linsenkoordinaten q (Kreis mit Radius 1)
vec3 leviathan_eye(vec2 q) {
	vec2 e = q - gaze * 0.12;
	// Lider: mandelförmige Öffnung, die sich beim Blinzeln schließt
	float open = 0.62 * (1.0 - lid);
	float edge = open * sqrt(max(0.0, 1.0 - pow(q.x / 1.08, 2.0)));
	float in_lids = smoothstep(0.0, 0.05, edge - abs(q.y + 0.04));
	vec3 skin = vec3(0.16, 0.13, 0.11) * (0.55 + 0.6 * fbm(q * 9.0)) * (0.6 + 0.4 * (1.0 - abs(q.y)));
	skin *= 0.7 + 0.3 * smoothstep(0.0, 0.25, abs(q.y + 0.04) - edge);
	float r = length(e);
	float a = atan(e.y, e.x);
	// Lederhaut: fahl und feucht, zu den Lidern dunkler, feine Äderchen
	vec3 sclera = vec3(0.62, 0.58, 0.5) * (0.85 + 0.15 * fbm(e * 6.0));
	float vein = smoothstep(0.035, 0.0, abs(fbm(vec2(a * 3.0, r * 5.0)) - 0.5)) * smoothstep(0.42, 0.9, r);
	sclera = mix(sclera, vec3(0.45, 0.24, 0.2), vein * 0.35);
	sclera *= 0.45 + 0.55 * smoothstep(0.0, 0.35, edge - abs(q.y + 0.04));
	// Iris: milchig-blass wie die leuchtenden Augen im Modell (Monster), radiale Fasern, dunkler Ring außen
	float ir = 0.46;
	float fibers = fbm(vec2(a * 14.0, r * 4.0)) * 0.6 + fbm(vec2(a * 40.0, r * 9.0)) * 0.4;
	vec3 iris = mix(vec3(0.42, 0.4, 0.3), vec3(0.95, 0.9, 0.72), fibers);
	iris *= 0.75 + 0.5 * smoothstep(ir, ir * pupil, r);
	iris = mix(iris, vec3(0.08, 0.07, 0.05), smoothstep(ir * 0.82, ir, r));
	vec3 c = mix(sclera, iris, smoothstep(ir + 0.01, ir - 0.01, r));
	// Pupille, ein wenig unregelmäßig
	float pr = ir * pupil * (1.0 + 0.06 * (noise(vec2(a * 2.0, 3.0)) - 0.5));
	c = mix(c, vec3(0.01), smoothstep(pr + 0.012, pr - 0.012, r));
	// feuchter Glanz
	float glint = smoothstep(0.09, 0.0, length(e - vec2(-0.17, -0.16))) + 0.35 * smoothstep(0.05, 0.0, length(e - vec2(0.12, 0.1)));
	c += vec3(0.9, 0.88, 0.8) * glint * 0.8;
	return mix(skin, c, in_lids);
}

void fragment() {
	vec2 size = 1.0 / SCREEN_PIXEL_SIZE;
	vec2 p = (UV - 0.5) * vec2(size.x / size.y, 1.0) * 2.0;
	float rn = length(p) / radius;
	vec2 dir = rn > 0.0001 ? normalize(p) : vec2(0.0);
	vec3 col = vec3(0.0);
	if (rn < 1.0) {
		// stereografisch: Bildradius ~ tan(θ/2), dann auf die geradlinige Kamera
		float half_field = radians(field) * 0.5;
		float theta = 2.0 * atan(rn * tan(half_field * 0.5));
		float s = tan(theta) / tan(radians(cam_fov) * 0.5);
		vec2 uv = 0.5 + dir * s * 0.5;
		col = sample_view(clamp(uv, vec2(0.002), vec2(0.998)));
		col *= dim;
		// Glas: leicht grünlich-warm, Vignette zum Rand
		col *= vec3(0.97, 1.0, 0.92);
		col *= 1.0 - 0.6 * pow(rn, 2.6);
		col = mix(col, leviathan_eye(p / radius), eye);
	}
	// Messingrand: unscharf (nah am Auge), außen ins Dunkel der Tür
	float ring = smoothstep(0.97, 1.0, rn) * (1.0 - smoothstep(1.06, 1.16, rn));
	vec3 brass = vec3(0.42, 0.3, 0.12) * (0.55 + 0.45 * smoothstep(0.6, -0.6, dir.y)) * (0.5 + 0.5 * max(dim, 0.25));
	col = mix(col, brass, ring * (rn < 1.0 ? 0.75 : 1.0));
	col *= 1.0 - smoothstep(1.1, 1.3, rn);
	COLOR = vec4(col, 1.0);
}
