// Tapete mit Vertäfelung (Spielkonzept 7.2, „alte Tapeten“): die Tapete als hochaufgelöste Kachel (paper_tile Meter,
// wiederholt sich waagrecht und senkrecht) mit Normal Map und Rauheit, mit Mipmaps abgetastet; dazu das Holz in zwei
// Bändern – Leiste unter der Decke oben, Vertäfelung darunter –, in Metern ab dem Boden des Stockwerks, per Hand
// bilinear (wood_surface_tex: Höhe R – Höhensprünge werden zu Glanzkanten –, Glanz G).
// Das gemalte Holz bleibt nur, wo keine modellierte Vertäfelung davorsteht (Treppenhäuser, Aufzüge, Lufträume).
// Die Tapete klebt in Bahnen: jede Bahn weicht etwas ab (Helligkeit, selten ausgeblichen oder versetzt angesetzt),
// man sieht die Nähte, manche haben sich gelöst. Welche Bahn wie ist, folgt fest aus ihrem Platz.
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_lambert, specular_toon;

uniform vec4 albedo : source_color = vec4(1.0);
uniform sampler2D wood_tex : source_color, filter_nearest, repeat_enable, hint_default_white;
uniform sampler2D wood_surface_tex : filter_nearest, repeat_enable, hint_default_black;
// Tapete: Farbe, Normal Map (OpenGL), Rauheit; eine Kachel über paper_tile Meter
uniform sampler2D paper_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable, hint_default_white;
uniform sampler2D paper_normal : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D paper_rough : filter_linear_mipmap_anisotropic, repeat_enable, hint_default_white;
uniform vec2 paper_tile = vec2(0.53);
// Texel pro Meter im Holzbild
uniform float texels_per_m = 73.0;
// Bänder im Holzbild als Texel-Zeilen [von, bis)
uniform vec2 frieze_rows = vec2(0.0, 6.0);
uniform vec2 base_rows = vec2(10.0, 64.0);
// Wandhöhe (Leiste sitzt darunter) und Stockwerkshöhe (Höhe zählt ab dem Boden des Stockwerks)
uniform float wall_top = 3.5;
uniform float storey = 4.0;
// Zweite Seite (Wand zwischen zwei Räumen mit verschiedener Tapete oder Deckenhöhe): Flächen, deren
// Normale in diese Richtung zeigt, nehmen Bilder, Wand- und Stockwerkshöhe von hier (0 = aus)
uniform vec3 side_b_normal = vec3(0.0);
uniform sampler2D paper_tex_b : source_color, filter_linear_mipmap_anisotropic, repeat_enable, hint_default_white;
uniform sampler2D paper_normal_b : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D paper_rough_b : filter_linear_mipmap_anisotropic, repeat_enable, hint_default_white;
uniform vec2 paper_tile_b = vec2(0.53);
uniform sampler2D wood_tex_b : source_color, filter_nearest, repeat_enable, hint_default_white;
uniform float wall_top_b = 3.5;
uniform float storey_b = 4.0;
// Stärke der Normal Map der Tapete
uniform float paper_normal_strength = 1.0;
// Tiefe der Höhenstufen des Holzes in Metern – je größer, desto kräftiger die Glanzkanten
uniform float bump_depth = 0.035;
// Glanz → Rauheit (matt … Lack) und Stärke des Seidenschimmers bei flachem Blick
uniform float rough_matte = 0.95;
uniform float rough_gloss = 0.3;
uniform float sheen = 0.6;
// Abgegriffener Sockel: so viel Glanz verliert die Wand direkt über dem Boden
uniform float scuff_gloss = 0.51;
// Bahnen: Breite in Metern, Helligkeitsstreuung, Anteil ausgeblichener und versetzt angesetzter Bahnen, Versatz in
// Metern (höchstens), Anteil der Nähte, die sich gelöst haben, und wie weit sie aufklaffen
uniform float strip_width = 0.53;
uniform float strip_shade = 0.05;
uniform float strip_faded = 0.08;
uniform float strip_shifted = 0.12;
uniform float strip_shift_max = 0.04;
uniform float seam_loose = 0.2;
uniform float seam_gap = 0.004;
// Unterkante der sichtbaren Tapete: die modellierte Vertäfelung (Wainscot.HEIGHT) deckt die gemalte darunter ab
uniform float paper_bottom = 0.9;

varying vec3 world_pos;
varying vec3 world_normal;
// Lage der Wandfläche quer zu ihr (für die Bahnen; flach, damit sie auf einer Fläche nicht springt)
varying flat float wall_key;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
	vec3 n = abs(world_normal);
	wall_key = n.x > n.z ? world_pos.x * 7.0 + 0.37 : world_pos.z * 5.0 + 113.0;
	POSITION = PROJECTION_MATRIX * (MODELVIEW_MATRIX * vec4(VERTEX, 1.0));
}

// Zufallswert 0…1 ohne Sinus (flimmert bei großen Werten nicht)
float hash(vec3 p) {
	p = fract(p * vec3(0.1031, 0.1030, 0.0973));
	p += dot(p, p.yzx + 33.33);
	return fract((p.x + p.y) * p.z);
}

// Werte der Bahn an der Stelle u (Meter) auf der Wand key, Stockwerk level; salt wählt den Wert
float strip_rand(float u, float key, float level, float salt) {
	return hash(vec3(floor(u / strip_width) + salt * 17.0, key, level * 3.0 + salt));
}

// Versetzt angesetzte Bahn: so viele Meter ist das Muster verschoben (0 = passt), mindestens 1 cm
float strip_shift(float u, float key, float level) {
	if (strip_rand(u, key, level, 1.0) >= strip_shifted) {
		return 0.0;
	}
	float r = strip_rand(u, key, level, 2.0);
	return (r < 0.5 ? -1.0 : 1.0) * mix(0.01, strip_shift_max, fract(r * 2.0));
}

int wrap_x(float u, float per_m, int width) {
	return int(floor(mod(u * per_m, float(width))));
}

// Position auf der Wand (u waagrecht, h über dem Stockwerksboden, beides in Metern) → Texel im Holzbild (z = 1) oder
// Tapete (z = 0, ohne Texel)
ivec3 texel_at(float u, float h, float top) {
	ivec2 wood = textureSize(wood_tex, 0);
	float base_h = (base_rows.y - base_rows.x) / texels_per_m;
	float frieze_h = (frieze_rows.y - frieze_rows.x) / texels_per_m;
	if (h < base_h) {
		float row = base_rows.y - h * texels_per_m;
		return ivec3(wrap_x(u, texels_per_m, wood.x), clamp(int(ceil(row)) - 1, 0, wood.y - 1), 1);
	}
	if (h > top - frieze_h && h <= top) {
		float row = frieze_rows.x + (top - h) * texels_per_m;
		return ivec3(wrap_x(u, texels_per_m, wood.x), clamp(int(ceil(row)) - 1, 0, wood.y - 1), 1);
	}
	return ivec3(0);
}

// Farbe am Texel t; auf der Tapete die der Kachel an dieser Stelle (paper_color)
vec3 wall_color(ivec3 t, bool side_b, vec3 paper_color) {
	if (t.z == 1) {
		return side_b ? texelFetch(wood_tex_b, t.xy, 0).rgb : texelFetch(wood_tex, t.xy, 0).rgb;
	}
	return paper_color;
}

// Höhe (R) und Glanz (G) am Texel t; die Tapete ist eben
vec2 wall_surface(ivec3 t) {
	return t.z == 1 ? texelFetch(wood_surface_tex, t.xy, 0).rg : vec2(0.5, 0.0);
}

void fragment() {
	vec3 n = abs(world_normal);
	vec3 tangent;
	float u;
	if (n.y > n.x && n.y > n.z) {
		// Ober- und Unterseiten (Wandkanten): nur Rautenfeld, keine Stufen
		tangent = vec3(0.0);
		u = world_pos.x;
	} else if (n.x > n.z) {
		tangent = vec3(0.0, 0.0, 1.0);
		u = world_pos.z;
	} else {
		tangent = vec3(1.0, 0.0, 0.0);
		u = world_pos.x;
	}
	bool side_b = dot(world_normal, side_b_normal) > 0.5;
	float top = side_b ? wall_top_b : wall_top;
	float st = side_b ? storey_b : storey;
	float h = mod(world_pos.y, st);
	float level = floor(world_pos.y / st + 0.001);
	if (tangent == vec3(0.0)) {
		h = top * 0.5;
	}
	float key = tangent == vec3(0.0) ? 0.0 : wall_key;
	float aa = max(fwidth(u), 1e-5);   // Breite eines Pixels auf der Wand (vor allen Verzweigungen)
	vec2 tile = side_b ? paper_tile_b : paper_tile;
	ivec3 t = texel_at(u, h, top);
	bool paper = t.z == 0;
	float base_h = (base_rows.y - base_rows.x) / texels_per_m;
	// Tapete: Kachel in Metern; Ableitungen ohne den Sprung des Bahnversatzes (sonst wählte die Naht
	// eine zu kleine Mipmap-Stufe), vor allen Verzweigungen
	vec2 smooth_uv = vec2(u / tile.x, -h / tile.y);
	vec2 duv_x = dFdx(smooth_uv);
	vec2 duv_y = dFdy(smooth_uv);
	vec2 puv = vec2(u / tile.x, -(h - base_h + strip_shift(u, key, level)) / tile.y);
	vec3 hi_color = side_b ? textureGrad(paper_tex_b, puv, duv_x, duv_y).rgb : textureGrad(paper_tex, puv, duv_x, duv_y).rgb;
	vec3 hi_normal = (side_b ? textureGrad(paper_normal_b, puv, duv_x, duv_y).rgb
		: textureGrad(paper_normal, puv, duv_x, duv_y).rgb) * 2.0 - 1.0;
	float hi_rough = side_b ? textureGrad(paper_rough_b, puv, duv_x, duv_y).r : textureGrad(paper_rough, puv, duv_x, duv_y).r;
	vec3 tex = hi_color;
	if (!paper) {
		// Holz bilinear von Hand (die Bänder machen texture() unbrauchbar): vier Nachbar-Texel gewichten
		float half_m = 0.5 / texels_per_m;
		vec2 f = fract(vec2(u, h) * texels_per_m - 0.5);
		vec3 a = mix(wall_color(texel_at(u - half_m, h - half_m, top), side_b, hi_color),
			wall_color(texel_at(u + half_m, h - half_m, top), side_b, hi_color), f.x);
		vec3 b = mix(wall_color(texel_at(u - half_m, h + half_m, top), side_b, hi_color),
			wall_color(texel_at(u + half_m, h + half_m, top), side_b, hi_color), f.x);
		tex = mix(a, b, f.y);
	}
	vec2 surf = wall_surface(t);
	float gloss = paper ? clamp((rough_matte - hi_rough) / (rough_matte - rough_gloss), 0.0, 1.0) : surf.g;
	vec3 grad = vec3(0.0);

	// Bahnen der Tapete (nicht auf dem Holz und den Wandkanten)
	if (paper && tangent != vec3(0.0)) {
		tex *= 1.0 + (strip_rand(u, key, level, 3.0) - 0.5) * 2.0 * strip_shade;
		if (strip_rand(u, key, level, 4.0) < strip_faded) {
			// ausgeblichen oder nachtapeziert: blasser, heller, stumpfer
			tex = mix(tex, vec3(dot(tex, vec3(0.299, 0.587, 0.114))), 0.2) * 1.05;
			gloss *= 0.7;
		}
		// Naht: Abstand zur nächsten Bahnkante, Richtung zu ihr längs der Wand
		float x = fract(u / strip_width) * strip_width;
		float d = min(x, strip_width - x);
		float toward = x < strip_width * 0.5 ? -1.0 : 1.0;
		float seam_u = u + toward * d;   // Lage der Naht, sie gehört zu beiden Bahnen
		// Gelöste Naht: oben unter der Leiste oder unten über der Vertäfelung, zum Ende hin weiter offen
		float lift = 0.0;
		if (strip_rand(seam_u + strip_width * 0.5, key, level, 5.0) < seam_loose) {
			float r = strip_rand(seam_u + strip_width * 0.5, key, level, 6.0);
			float frieze_h = (frieze_rows.y - frieze_rows.x) / texels_per_m;
			float len = 0.15 + fract(r * 7.0) * 0.6;
			float from_end = r < 0.6 ? (top - frieze_h) - h : h - max(base_h, paper_bottom);
			lift = pow(clamp(1.0 - from_end / len, 0.0, 1.0), 1.5);
		}
		float gap = mix(0.0006, seam_gap, lift);
		float cover = clamp(gap / aa, 0.0, 1.0);
		float line = (1.0 - smoothstep(max(gap, aa) * 0.5, max(gap, aa), d)) * cover;
		tex *= 1.0 - line * mix(0.25, 0.7, lift);
		// Aufgewölbte Kante neben der Fuge: steigt zur Naht hin an, fängt Licht, die Rückseite schimmert hell durch
		float curl_w = 0.015 * lift;
		if (curl_w > 0.0 && d < curl_w && d > gap * 0.5) {
			float k = 1.0 - d / curl_w;
			grad += tangent * toward * k * lift * 0.8;
			tex = mix(tex, vec3(0.78, 0.74, 0.64) * albedo.rgb, smoothstep(0.7, 1.0, k) * lift * 0.5);
		}
	}

	// Abgegriffener Sockel: direkt über dem Boden weniger Glanz. Flecken hat die Tapete vorerst keine
	// (offener Punkt, Spielkonzept 7.2)
	float scuff = 1.0 - smoothstep(0.05, 0.25, h);
	gloss *= 1.0 - scuff_gloss * scuff;

	ALBEDO = albedo.rgb * tex;
	ROUGHNESS = mix(rough_matte, rough_gloss, gloss);
	SPECULAR = gloss;
	RIM = sheen * gloss;
	RIM_TINT = 0.6;

	// Normale: Tapete aus der Normal Map (x längs u, y nach oben), Holz mit Glanzkanten – Höhensprung zum
	// Nachbar-Texel rechts und darüber kippt sie
	if (tangent != vec3(0.0)) {
		vec3 nw;
		if (paper) {
			nw = normalize(world_normal * hi_normal.z
				+ (tangent * hi_normal.x + vec3(0.0, 1.0, 0.0) * hi_normal.y) * paper_normal_strength - grad);
		} else {
			float step_m = 1.0 / texels_per_m;
			float hr = wall_surface(texel_at(u + step_m, h, top)).r;
			float hu = wall_surface(texel_at(u, h + step_m, top)).r;
			grad += ((hr - surf.r) * tangent + (hu - surf.r) * vec3(0.0, 1.0, 0.0)) * bump_depth / step_m;
			nw = normalize(world_normal - grad);
		}
		NORMAL = normalize((VIEW_MATRIX * vec4(nw, 0.0)).xyz);
	}
}
