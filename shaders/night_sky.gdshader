// Nachthimmel über dem Hotel (Spielkonzept 2, 7.3): dunkler Verlauf, Mond in Richtung des Mondlichts
// (LIGHT0 = DirectionalLight in main.gd), ziehende Wolken mit silbernem Rand, Sterne in den Lücken,
// rundum eine schwarze Waldkante, die den Horizont verdeckt.
// Fasrige Wolken (verzerrtes Rauschen), weicher Rand, Mondflecken, feine funkelnde Sterne.
shader_type sky;

uniform vec3 zenith_color : source_color = vec3(0.004, 0.006, 0.014);
uniform vec3 horizon_color : source_color = vec3(0.03, 0.035, 0.05);
// Wald und Hügel rings um das Hotel, schwarz vor dem Horizont; darunter dieselbe Farbe
uniform vec3 treeline_color : source_color = vec3(0.0);
// Höhen als Blickrichtung-y (≈ Winkel im Bogenmaß): Hügel darunter, Baumspitzen obendrauf
uniform vec2 hill_height = vec2(0.02, 0.07);
uniform vec2 tree_height = vec2(0.035, 0.09);
// Bäume rundum (ganze Zahl, sonst gibt es eine Naht)
uniform float tree_count = 420.0;
uniform vec3 moon_color : source_color = vec3(0.85, 0.88, 0.95);
// Winkelradius der Mondscheibe (Bogenmaß) – größer als echt, damit man ihn durchs Fenster sieht
uniform float moon_radius = 0.045;
uniform float moon_energy = 1.6;
uniform float halo_energy = 0.12;
// Mondphase (Weather, Spielkonzept 7.8) als Winkel: 0 Vollmond, ±π Neumond, negativ zunehmend (rechts hell, wie auf
// der Nordhalbkugel); die dunkle Seite schimmert schwach (Erdschein)
uniform float moon_phase = 0.0;
uniform float earthshine = 0.04;
uniform vec3 cloud_dark : source_color = vec3(0.012, 0.013, 0.018);
uniform vec3 cloud_lit : source_color = vec3(0.42, 0.45, 0.52);
// Bedeckung: Rauschwert, ab dem Wolke ist (kleiner = mehr Wolken)
uniform float cloud_cover = 0.40;
uniform float cloud_scale = 0.55;
// Wind in Wolkenebenen-Einheiten pro Sekunde
uniform vec2 wind = vec2(0.010, 0.004);
// Spielzeit in Sekunden – setzt main.gd (nicht TIME: die liefe in der Pause weiter)
uniform float sky_time = 0.0;
uniform float star_energy = 0.5;
// Blitz (Wetter, Spielkonzept 7.8): 0 … 1, hellt Wolken und Himmel auf – der Wald steht schwarz davor
uniform float flash = 0.0;
// Blutregen (Weather, Spielkonzept 7.8): 0 … 1 – der Himmel rotbraun wie bei Saharastaub (Wolken von unten, Horizont
// glimmt), Blitze rot
uniform float blood = 0.0;
uniform vec3 blood_clouds : source_color = vec3(0.867, 0.467, 0.2);   // #dd7733
uniform vec3 blood_flash : source_color = vec3(1.0, 0.067, 0.067);    // #ff1111

// Hash ohne Sinus (Dave Hoskins) – bleibt auch bei großen Koordinaten (langer Wolkenzug) sauber
float hash12(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

float hash13(vec3 p) {
	p = fract(p * 0.1031);
	p += dot(p, p.zyx + 31.32);
	return fract((p.x + p.y) * p.z);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash12(i), hash12(i + vec2(1.0, 0.0)), u.x),
		mix(hash12(i + vec2(0.0, 1.0)), hash12(i + vec2(1.0, 1.0)), u.x), u.y);
}

float fbm(vec2 p, int octaves) {
	float sum = 0.0;
	float amp = 0.5;
	float norm = 0.0;
	for (int i = 0; i < octaves; i++) {
		sum += amp * noise(p);
		norm += amp;
		p = mat2(vec2(1.6, 1.2), vec2(-1.2, 1.6)) * p + vec2(17.0, 9.0);
		amp *= 0.5;
	}
	return sum / norm;
}

// Wolkendichte 0 … 1 an einer Stelle der Wolkenebene
float clouds(vec2 p) {
	vec2 q = p * cloud_scale + wind * sky_time;
	// Verzerrtes Rauschen: Fasern und Schlieren über einer Grundform aus drei Oktaven
	vec2 warp = vec2(fbm(q * 1.7 + vec2(3.1, 7.4), 3), fbm(q * 1.7 + vec2(8.3, 2.8), 3)) - 0.5;
	float d = fbm(q, 3) * 0.8 + fbm(q * 4.0 + warp * 1.5, 4) * 0.2;
	return smoothstep(cloud_cover, cloud_cover + 0.22, d);
}

// Oberkante von Wald und Hügeln in Blickrichtung (als dir.y): Hügel aus Rauschen auf dem Kreis (nahtlos),
// darauf Nadelbäume als Dreiecke, eins pro Zelle mit eigener Höhe, Breite und Lage, mit zerfransten Rändern (Äste)
float treeline(vec3 dir) {
	float az = atan(dir.x, dir.z) / TAU + 0.5;   // 0 … 1 rundum
	float x = az * tree_count;
	float a = x / tree_count * TAU;
	vec2 ring = vec2(cos(a), sin(a));
	float hills = mix(hill_height.x, hill_height.y, fbm(ring * 2.2 + 40.0, 3));
	// dichter und lichter Wald im Wechsel
	float density = smoothstep(0.3, 0.6, fbm(ring * 6.0 + 90.0, 2));
	float top = 0.0;
	for (int k = -2; k <= 2; k++) {
		float cell = floor(x) + float(k);
		float id = mod(cell, tree_count);
		float h = hash12(vec2(id, 3.0));
		float pos = cell + 0.5 + (hash12(vec2(id, 7.0)) - 0.5) * 0.8;
		float half_width = mix(0.7, 1.6, hash12(vec2(id, 11.0)));
		float height = mix(tree_height.x, tree_height.y, h) * mix(0.35, 1.0, density);
		top = max(top, height * (1.0 - abs(x - pos) / half_width));
	}
	top += (noise(vec2(x * 9.0, dir.y * 300.0)) - 0.5) * 0.006 * step(0.001, top);
	return hills + top;
}

// Sterne: feine, funkelnde Punkte
float stars(vec3 dir) {
	vec3 p = dir * 260.0;
	vec3 cell = floor(p);
	float h = hash13(cell);
	if (h < 0.988) {
		return 0.0;
	}
	float bright = (h - 0.988) / 0.012;
	vec3 center = cell + 0.5 + (vec3(hash13(cell + 1.7), hash13(cell + 4.3), hash13(cell + 9.1)) - 0.5) * 0.6;
	float point = smoothstep(0.45, 0.0, length(p - center));
	float twinkle = 0.7 + 0.3 * sin(mod(sky_time, 1000.0) * (1.5 + 3.0 * hash13(cell + 2.9)) + h * 600.0);
	return bright * point * twinkle;
}

void sky() {
	vec3 dir = EYEDIR;
	if (AT_CUBEMAP_PASS) {
		// Strahlung wird nicht genutzt (Umgebungslicht als Farbe, Spiegelung aus) – billig halten
		vec3 horizon = mix(horizon_color, blood_clouds * 0.09, blood);
		vec3 zenith = mix(zenith_color, blood_clouds * 0.02, blood);
		COLOR = dir.y > 0.0 ? mix(horizon, zenith, sqrt(dir.y)) : treeline_color;
	} else {
		vec3 moon_dir = LIGHT0_ENABLED ? LIGHT0_DIRECTION : normalize(vec3(0.3, 0.6, -0.7));
		float up = dir.y;
		vec3 col = mix(mix(horizon_color, blood_clouds * 0.09, blood), mix(zenith_color, blood_clouds * 0.02, blood),
				sqrt(clamp(up, 0.0, 1.0)));

		// Mond: Scheibe mit Flecken, Hof drumherum
		float ang = acos(clamp(dot(dir, moon_dir), -1.0, 1.0));
		vec3 right = normalize(cross(moon_dir, vec3(0.0, 1.0, 0.0)));
		vec3 top = cross(right, moon_dir);
		vec2 local = vec2(dot(dir, right), dot(dir, top)) / moon_radius;   // −1 … 1 über die Scheibe
		float r = length(local);
		float disc = smoothstep(1.0, 0.94, r);
		float maria = 1.0 - 0.32 * smoothstep(0.45, 0.7, fbm(local * 2.2 + vec2(4.0, 1.0), 4));
		float limb = mix(0.8, 1.0, sqrt(max(0.0, 1.0 - r * r)));
		float lit_part = 0.5 + 0.5 * cos(moon_phase);   // beleuchteter Anteil der Scheibe
		float halo = (exp(-ang / (moon_radius * 3.0)) * 0.8 + exp(-ang / (moon_radius * 10.0)) * 0.2) * lit_part;
		// Phase: Schattengrenze auf der Kugel, die Sonne seitlich hinter (zunehmend: rechts) dem Mond
		vec3 sun = vec3(-sin(moon_phase), 0.0, cos(moon_phase));
		float facing = dot(vec3(local, sqrt(max(0.0, 1.0 - r * r))), sun);
		float sunlit = smoothstep(-0.05, 0.07, facing);
		float phase_light = mix(earthshine, 1.0, sunlit);

		// Wolken auf einer flachen Ebene über dem Hof; zum Horizont hin dünner und dunkler
		float horizon_fade = smoothstep(0.02, 0.25, up);
		vec2 plane = dir.xz / max(up, 0.06);
		vec2 moon_plane = moon_dir.xz / max(moon_dir.y, 0.06);
		float d = clouds(plane) * horizon_fade;
		// Silberrand: zum Mond hin dünner werdende Wolke leuchtet, nah am Mond stärker
		vec2 to_moon = normalize(moon_plane - plane + vec2(1e-4)) * 0.06;
		float d_moon = clouds(plane + to_moon) * horizon_fade;
		float edge = clamp((d - d_moon) * 3.0 + (1.0 - d) * 0.6, 0.0, 1.0);
		float near_moon = exp(-ang / (moon_radius * 7.0)) * lit_part;
		float lit = clamp(edge * (0.12 + near_moon * 1.4), 0.0, 1.0);
		// Blutregen: der Staub färbt die Wolken, unten (zum Horizont) glimmen sie heller
		vec3 dark = mix(cloud_dark, blood_clouds * mix(0.07, 0.03, smoothstep(0.05, 0.6, up)), blood);
		vec3 cloud = mix(dark, mix(cloud_lit, blood_clouds, blood), lit) + moon_color * near_moon * 0.08;

		// Hinter den Wolken: Sterne und Mond, durch dünne Wolke schimmert der Mond als Fleck
		float star = stars(dir) * star_energy * smoothstep(0.05, 0.3, up);
		vec3 behind = col + vec3(star) * (1.0 - disc) + moon_color * (disc * maria * limb * phase_light * moon_energy + halo * halo_energy);
		col = mix(behind, cloud, d) + moon_color * disc * moon_energy * 0.25 * d * (1.0 - d) * lit_part;
		vec3 flash_col = mix(vec3(0.25, 0.27, 0.35), vec3(0.75, 0.78, 0.9), d);
		flash_col = mix(flash_col, blood_flash * mix(0.35, 0.9, d), blood);
		col += flash * flash_col * smoothstep(-0.02, 0.2, up);
		// Wald und Hügel davor (auch unter dem Horizont, über den Rand des Grundstücks hinaus)
		float line = treeline(dir);
		float forest = smoothstep(line + 0.0006, line - 0.0006, up);
		COLOR = mix(col, treeline_color, forest);
	}
}
