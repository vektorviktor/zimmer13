// Regen an den Scheiben (Spielkonzept 7.8): Tropfen auf der Außenseite der Fenster (HotelWindow, Weather). Eine Fläche
// knapp vor dem Glas; das Muster liegt in Metern auf der Scheibe (VERTEX des Quads), je Fenster verschoben. Zwei Lagen
// stehender Tropfen, die kommen und gehen, dazu Rinnsale: ein großer Tropfen rutscht ruckweise hinab und zieht eine
// Spur kleiner Tropfen hinter sich her. Jeder Tropfen bricht das Bild dahinter (auf dem Kopf, wie eine Linse) und
// glänzt im Licht der Lampen. Wie nass die Scheiben sind, gibt die globale rain_wet (0 … 1, trocknet nach dem Regen
// langsam ab), die Zeit weather_time – beide aus Weather, Spielzeit (steht in der Pause). Blutregen (rain_blood): die
// Tropfen färben das Bild rot; danach bleiben eingetrocknete rote Flecken mit dunklerem Rand (pane_stain), bis normaler
// Regen sie abwäscht.
shader_type spatial;
render_mode blend_mix, depth_draw_never, cull_disabled, shadows_disabled, specular_schlick_ggx;

global uniform float rain_wet;
global uniform float weather_time;
global uniform float psx_smooth;
global uniform float rain_blood;
global uniform float pane_stain;

uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap;
uniform float refraction = 0.008;     // so weit (Bildanteil) bricht ein Tropfen das Bild dahinter
uniform float gather = 1.35;          // ein Tropfen sammelt Licht aus einem weiten Winkel: heller als das Bild dahinter
uniform vec3 catchlight : source_color = vec3(0.07, 0.075, 0.09);   // Glanzpunkt oben am Tropfen (Himmel)
uniform float run_width = 0.1;        // Breite einer Rinnsal-Spalte (m)
uniform float run_height = 1.2;       // nach so viel Höhe (m) wiederholt sich eine Spalte
uniform float trail = 0.45;           // so lang (m) ist die Spur über einem Rinnsal
uniform vec3 blood_tint : source_color = vec3(0.85, 0.12, 0.08);   // so färbt Blutregen das Bild im Tropfen
uniform vec3 stain_color : source_color = vec3(0.22, 0.045, 0.03);  // eingetrocknete Flecken

varying vec2 pane;                    // Ort auf der Scheibe in Metern, +y oben

float hash(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

// Stehende Tropfen in einem Raster (Zelle cell m): je Zelle höchstens einer, an zufälliger Stelle und in zufälliger
// Größe; er erscheint bei Nässe über seiner Schwelle, bleibt eine Weile und verschwindet (läuft ab, neuer Treffer).
// Rückgabe: xy = Neigung der Oberfläche (−1 … 1) × Deckung, z = Deckung
vec3 static_drops(vec2 p, float cell, float wet, float seed) {
	vec2 g = p / cell;
	vec2 id = floor(g);
	vec2 f = fract(g) - 0.5;
	float h = hash(id + seed);
	vec2 off = (vec2(hash(id + seed + 1.3), hash(id + seed + 7.1)) - 0.5) * 0.5;
	float r = mix(0.12, 0.34, hash(id + seed + 3.7));
	float life = fract(weather_time * mix(0.02, 0.07, hash(id + seed + 5.9)) + h * 13.0);
	float present = step(h, wet) * smoothstep(0.0, 0.04, life) * (1.0 - smoothstep(0.8, 1.0, life));
	vec2 d = (f - off) * vec2(1.0, 1.1);   // ein wenig länglich: das Wasser zieht nach unten
	float m = smoothstep(r, r * 0.7, length(d)) * present;
	return vec3(d / r * m, m);
}

// Rinnsale: in jeder Spalte (run_width) mit Nässe über ihrer Schwelle rutscht ein Tropfen ruckweise hinab und lässt
// darüber eine Spur kleiner Tropfen zurück.
vec3 running_drops(vec2 p, float wet) {
	float col = floor(p.x / run_width);
	float h = hash(vec2(col, 17.0));
	if (h > wet * 0.55) {
		return vec3(0.0);
	}
	float tile = floor(p.y / run_height);
	float hh = hash(vec2(col, tile + 3.0));
	float y = p.y - tile * run_height;
	// Ruckweise: drei Rutscher je Durchgang, dazwischen hängt er
	float u = weather_time * mix(0.25, 0.6, hh) + hh * 7.0;
	float jumps = 3.0;
	float pos = (floor(u * jumps) + smoothstep(0.55, 1.0, fract(u * jumps))) / jumps;
	float head = run_height * (1.0 - fract(pos)) * 0.9 + run_height * 0.05;
	float wiggle = sin(y * 17.0 + hh * 40.0) * 0.009 + sin(y * 43.0 + hh * 9.0) * 0.003;
	float x = p.x - (col + 0.5) * run_width - wiggle - (hh - 0.5) * run_width * 0.4;
	// Kopf: großer, unten runder Tropfen
	vec2 d = vec2(x, y - head) / vec2(0.011, 0.014);
	float m_head = smoothstep(1.0, 0.75, length(d));
	vec3 res = vec3(d * m_head, m_head);
	// Spur: kleine Tropfen in einem schmalen Streifen über dem Kopf, nach oben hin weniger
	float above = y - head;
	if (above > 0.0 && above < trail) {
		float cell = 0.018;
		float id = floor(y / cell);
		float hs = hash(vec2(col * 3.1, id));
		float keep = step(hs, 0.75 * (1.0 - above / trail));
		float r = mix(0.003, 0.006, hash(vec2(id, col)));
		vec2 c = vec2(x - (hash(vec2(id, col + 9.0)) - 0.5) * 0.003, y - (id + 0.5) * cell) / r;
		float m = smoothstep(1.0, 0.7, length(c)) * keep;
		if (m > res.z) {
			res = vec3(c * m, m);
		}
	}
	return res;
}

// Eingetrocknete Flecken: dieselben Stellen wie die kleinen stehenden Tropfen, aber fest; am Rand dunkler (Ring).
float stain_spots(vec2 p, float cell, float amount) {
	vec2 g = p / cell;
	vec2 id = floor(g);
	vec2 f = fract(g) - 0.5;
	float h = hash(id);
	vec2 off = (vec2(hash(id + 1.3), hash(id + 7.1)) - 0.5) * 0.5;
	float r = mix(0.12, 0.34, hash(id + 3.7));
	float l = length((f - off) * vec2(1.0, 1.1));
	return smoothstep(r, r * 0.75, l) * mix(0.45, 1.0, smoothstep(r * 0.3, r * 0.9, l)) * step(h, amount);
}

void vertex() {
	pane = VERTEX.xy;
}

void fragment() {
	float wet = rain_wet;
	if (wet < 0.002 && pane_stain < 0.01) {
		discard;
	}
	vec2 p = pane + NODE_POSITION_WORLD.xz * 1.37 + vec2(NODE_POSITION_WORLD.y * 0.71, 0.0);
	if (psx_smooth < 0.5) {
		p = floor(p * 120.0) / 120.0;   // PS1-Look: grobe Texel
	}
	vec3 a = static_drops(p, 0.026, wet * 0.85, 0.0);
	vec3 b = static_drops(p + 0.3, 0.06, wet * 0.5, 11.0);
	vec3 c = running_drops(p, wet);
	vec3 d = a;
	if (b.z > d.z) { d = b; }
	if (c.z > d.z) { d = c; }
	float m = wet < 0.002 ? 0.0 : d.z;
	float stain = pane_stain > 0.01 ? stain_spots(p, 0.026, 0.85) * pane_stain : 0.0;
	if (m < 0.02) {
		if (stain < 0.02) {
			discard;
		}
		// nur ein eingetrockneter Fleck: matt, deckt ein wenig
		NORMAL = FRONT_FACING ? NORMAL : -NORMAL;
		ALBEDO = stain_color;
		ROUGHNESS = 0.9;
		SPECULAR = 0.1;
		ALPHA = psx_smooth < 0.5 ? step(0.25, stain) * 0.5 : stain * 0.6;
	} else {
		vec2 n = d.xy / max(m, 0.001);   // Neigung −1 … 1
		if (psx_smooth < 0.5) {
			m = step(0.5, m);
		}
		// Bild dahinter, durch die Linse auf den Kopf gestellt; zum Rand dunkler (Brechung schickt dort weniger Licht)
		vec3 behind = textureLod(screen_tex, SCREEN_UV - n * refraction, 2.5).rgb * gather;
		behind *= mix(1.0, 0.35, smoothstep(0.55, 1.0, length(n)));
		behind += catchlight * smoothstep(0.35, 0.8, dot(n, vec2(-0.35, 0.85)));
		behind = mix(behind, behind * blood_tint * 1.8 + blood_tint * 0.025, rain_blood);
		// Oberfläche des Tropfens als Normale in Blickkoordinaten (Ebene der Scheibe aus der Modellmatrix)
		vec3 right = normalize((VIEW_MATRIX * MODEL_MATRIX * vec4(1.0, 0.0, 0.0, 0.0)).xyz);
		vec3 up = normalize((VIEW_MATRIX * MODEL_MATRIX * vec4(0.0, 1.0, 0.0, 0.0)).xyz);
		vec3 face = FRONT_FACING ? NORMAL : -NORMAL;
		float nz = sqrt(max(0.0, 1.0 - dot(n, n)));
		NORMAL = normalize(right * n.x + up * n.y + face * max(nz, 0.15));
		ALBEDO = vec3(0.02);
		ROUGHNESS = 0.06;
		SPECULAR = 0.9;
		EMISSION = behind;
		ALPHA = m * 0.92;
	}
}
