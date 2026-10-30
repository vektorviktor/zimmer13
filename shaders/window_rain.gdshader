// Regen an den Scheiben (Spielkonzept 7.8): Tropfen auf der Außenseite der Fenster (HotelWindow, Weather). Eine Fläche
// knapp vor dem Glas; das Muster liegt in Metern auf der Scheibe (VERTEX des Quads), je Fenster verschoben. Vor allem
// Rinnsale: große Tropfen rutschen ruckweise hinab, ziehen einen Wasserfaden hinter sich, der in Perlen zerfällt, und
// wischen dabei die (wenigen) stehenden Tropfen weg. Jeder Tropfen bricht das Bild dahinter (auf dem Kopf, wie eine Linse) und
// glänzt im Licht der Lampen. Wie nass die Scheiben sind, gibt die globale rain_wet (0 … 1, trocknet nach dem Regen
// langsam ab), die Zeit weather_time – beide aus Weather, Spielzeit (steht in der Pause). Blutregen (rain_blood): die
// Tropfen färben das Bild rot; danach bleiben eingetrocknete rote Flecken mit dunklerem Rand (pane_stain), bis normaler
// Regen sie abwäscht.
// Auch auf den Dachfenstern (LevelBuilder): Die Neigung der Fläche (steep, aus der Modellmatrix: lokal +Y = bergauf)
// macht die Rinnsale seltener und langsamer – sie laufen die Schräge hinab –, auf flachem Glas bleiben eher stehende
// Tropfen, größer, runder und mehr davon. Senkrechte Fenster: steep = 1.
shader_type spatial;
render_mode blend_mix, depth_draw_never, cull_disabled, shadows_disabled, specular_schlick_ggx;

global uniform float rain_wet;
global uniform float weather_time;
global uniform float rain_blood;
global uniform float pane_stain;

uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap;
uniform float refraction = 0.008;     // so weit (Bildanteil) bricht ein Tropfen das Bild dahinter
uniform float gather = 1.35;          // ein Tropfen sammelt Licht aus einem weiten Winkel: heller als das Bild dahinter
uniform vec3 catchlight : source_color = vec3(0.07, 0.075, 0.09);   // Glanzpunkt oben am Tropfen (Himmel)
uniform float run_width = 0.07;       // Breite einer Rinnsal-Spalte (m)
uniform float run_share = 0.8;        // so viele Spalten (Anteil bei voller Nässe) haben ein Rinnsal
uniform float run_height = 2.0;       // nach so viel Höhe (m) wiederholt sich eine Spalte
uniform float film_life = 2.5;        // so lange (s) bleibt die Spur ein durchgehender Wasserfaden
uniform float trail_life = 14.0;      // so lange (s) bleiben Perlen der Spur stehen
uniform vec3 blood_tint : source_color = vec3(0.85, 0.12, 0.08);   // so färbt Blutregen das Bild im Tropfen
uniform vec3 stain_color : source_color = vec3(0.22, 0.045, 0.03);  // eingetrocknete Flecken

varying vec2 pane;                    // Ort auf der Scheibe in Metern, +y oben (bergauf)
varying float steep;                  // 1 = senkrechte Scheibe, 0 = flach liegend

float hash(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

// Stehende Tropfen in einem Raster (Zelle cell m): je Zelle höchstens einer, an zufälliger Stelle und in zufälliger
// Größe; er erscheint bei Nässe über seiner Schwelle, bleibt eine Weile und verschwindet (läuft ab, neuer Treffer).
// Rückgabe: xy = Neigung der Oberfläche (−1 … 1) × Deckung, z = Deckung
vec3 static_drops(vec2 p, float cell, float wet, float seed, float stretch) {
	vec2 g = p / cell;
	vec2 id = floor(g);
	vec2 f = fract(g) - 0.5;
	float h = hash(id + seed);
	vec2 off = (vec2(hash(id + seed + 1.3), hash(id + seed + 7.1)) - 0.5) * 0.5;
	float r = mix(0.12, 0.34, hash(id + seed + 3.7));
	float life = fract(weather_time * mix(0.02, 0.07, hash(id + seed + 5.9)) + h * 13.0);
	float present = step(h, wet) * smoothstep(0.0, 0.04, life) * (1.0 - smoothstep(0.8, 1.0, life));
	vec2 d = (f - off) * vec2(1.0, stretch);   // ein wenig länglich: das Wasser zieht nach unten (liegend: rund)
	float m = smoothstep(r, r * 0.7, length(d)) * present;
	return vec3(d / r * m, m);
}

// Rinnsale: in jeder Spalte (run_width) mit Nässe über ihrer Schwelle läuft ein Tropfen hinab – ruckweise, je Spalte
// verschieden schnell – und zieht eine nasse Spur hinter sich: frisch ein durchgehender schmaler Wasserfaden, älter
// zerfällt er in kleine Perlen, die nach und nach verschwinden. Wo die Spur ist, hat der Tropfen die stehenden Tropfen
// mitgenommen (Rückgabe w = so viel weggewischt). Je flacher die Scheibe, desto seltener und langsamer; liegend keine.
vec4 running_drops(vec2 p, float wet, float steepness) {
	float col = floor(p.x / run_width);
	float h = hash(vec2(col, 17.0));
	if (h > wet * run_share * smoothstep(0.15, 0.7, steepness)) {
		return vec4(0.0);
	}
	// je Spalte versetzt, sonst lägen die Nahtstellen aller Spalten auf derselben Höhe
	float py = p.y + hash(vec2(col, 5.0)) * run_height;
	float tile = floor(py / run_height);
	float hh = hash(vec2(col, tile + 3.0));
	float y = py - tile * run_height;
	// Durchgänge je Sekunde; ruckweise: mehrere Rutscher je Durchgang, dazwischen hängt er kurz
	float speed = mix(0.07, 0.22, hh) * mix(0.35, 1.0, steepness);
	float u = weather_time * speed + hh * 7.0;
	float jumps = 5.0;
	float phase = fract(u);
	float pos = (floor(phase * jumps) + smoothstep(0.35, 1.0, fract(phase * jumps))) / jumps;
	float head = run_height * (1.0 - pos);
	float wiggle = sin(y * 17.0 + hh * 40.0) * 0.008 + sin(y * 43.0 + hh * 9.0) * 0.003;
	float x = p.x - (col + 0.5) * run_width - wiggle - (hh - 0.5) * run_width * 0.4;
	// Kopf: großer Tropfen, unten rund, nach oben in die Spur gezogen
	float rw = mix(0.009, 0.016, hash(vec2(col, tile + 11.0)));
	float above = y - head;
	vec2 d = vec2(x / rw, above / (rw * (above > 0.0 ? 1.7 : 1.1)));
	float m_head = smoothstep(1.0, 0.75, length(d));
	vec4 res = vec4(d * m_head, m_head, 0.0);
	// Spur: so lange (s) ist es her, dass der Kopf hier vorbeikam (über das Ende des Durchgangs hinaus: die alte Spur
	// steht noch, während oben der nächste Tropfen losläuft)
	float age = fract(pos - (1.0 - y / run_height)) / speed;
	if (age < trail_life) {
		float fresh = 1.0 - smoothstep(0.0, film_life, age);   // 1 = gerade erst, durchgehender Faden
		float fade = 1.0 - age / trail_life;
		res.w = max(res.w, smoothstep(rw * 1.6, rw * 0.6, abs(x)) * fade);
		// Faden: schmal, zylindrisch gewölbt – bricht das Bild weniger als ein Tropfen
		float fw = rw * mix(0.25, 0.5, fresh);
		float mf = smoothstep(1.0, 0.6, abs(x) / fw) * fresh * 0.75;
		if (mf > res.z) {
			res.xyz = vec3(x / fw * 0.6, 0.45, 1.0) * mf;
		}
		// Perlen: was vom Faden liegen bleibt, kleiner und weniger, je älter
		float cell = 0.014;
		float id = floor(y / cell);
		float keep = step(hash(vec2(col * 3.1, id + tile * 31.0)), 0.8 * fade);
		float r = mix(0.0025, 0.0055, hash(vec2(id, col))) * mix(0.6, 1.0, fade);
		vec2 c = vec2(x - (hash(vec2(id, col + 9.0)) - 0.5) * 0.004, y - (id + 0.5) * cell) / r;
		float mb = smoothstep(1.0, 0.7, length(c)) * keep * (1.0 - fresh * 0.7);
		if (mb > res.z) {
			res.xyz = vec3(c * mb, mb);
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
	steep = clamp(normalize((MODEL_MATRIX * vec4(0.0, 1.0, 0.0, 0.0)).xyz).y, 0.0, 1.0);
}

void fragment() {
	float wet = rain_wet;
	if (wet < 0.002 && pane_stain < 0.01) {
		discard;
	}
	vec2 p = pane + NODE_POSITION_WORLD.xz * 1.37 + vec2(NODE_POSITION_WORLD.y * 0.71, 0.0);
	float lying = 1.0 - steep;
	float stretch = mix(1.0, 1.1, steep);
	// senkrecht wenige stehende Tropfen – das Bild machen die Rinnsale; wo eines lief, sind sie weggewischt
	vec4 c = running_drops(p, wet, steep);
	float wiped = 1.0 - c.w;
	vec3 a = static_drops(p, 0.026, wet * mix(0.2, 1.0, lying), 0.0, stretch) * wiped;
	vec3 b = static_drops(p + 0.3, 0.06, wet * mix(0.15, 0.8, lying), 11.0, stretch) * wiped;
	vec3 d = a;
	if (b.z > d.z) { d = b; }
	if (c.z > d.z) { d = c.xyz; }
	if (lying > 0.05) {
		// schräges oder liegendes Glas: dazu große, flache Tropfen, die stehen bleiben statt abzulaufen
		vec3 e = static_drops(p + 0.7, 0.075, wet * 0.4 * lying, 23.0, 1.0);
		if (e.z > d.z) { d = e; }
	}
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
		ALPHA = stain * 0.6;
	} else {
		vec2 n = d.xy / max(m, 0.001);   // Neigung −1 … 1
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
