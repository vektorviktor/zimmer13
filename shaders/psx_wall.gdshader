// Tapete mit Vertäfelung im PS1-Look (Spielkonzept 9.2, „alte Tapeten“ 7.2): wie psx_surface (Vertex-Snapping,
// Nearest-Filter), aber mit Glanz. Die Textur ist eine Wandansicht in drei Bändern – Vertäfelung
// unten, Rauten in der Mitte (wiederholt sich), Leiste unter der Decke –, die in Metern ab dem
// Boden des Stockwerks aufgetragen werden. Die Oberflächen-Textur trägt Höhe (R) und Glanz (G):
// Höhensprünge werden zu Glanzkanten, der Glanz unterscheidet Lack, Satin und matte Rauten.
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_lambert, specular_toon;

uniform vec4 albedo : source_color = vec4(1.0);
uniform sampler2D albedo_tex : source_color, filter_nearest, repeat_enable, hint_default_white;
uniform sampler2D surface_tex : filter_nearest, repeat_enable, hint_default_black;
// Texel pro Meter (waagrecht und senkrecht gleich)
uniform float texels_per_m = 73.0;
// Bänder als Texel-Zeilen [von, bis) in der Textur
uniform vec2 frieze_rows = vec2(0.0, 6.0);
uniform vec2 field_rows = vec2(10.0, 74.0);
uniform vec2 base_rows = vec2(202.0, 256.0);
// Wandhöhe (Leiste sitzt darunter) und Stockwerkshöhe (Höhe zählt ab dem Boden des Stockwerks)
uniform float wall_top = 3.5;
uniform float storey = 4.0;
// Zweite Seite (Wand zwischen zwei Räumen mit verschiedener Tapete oder Deckenhöhe): Flächen, deren
// Normale in diese Richtung zeigt, nehmen Farbbild, Wand- und Stockwerkshöhe von hier (0 = aus)
uniform vec3 side_b_normal = vec3(0.0);
uniform sampler2D albedo_tex_b : source_color, filter_nearest, repeat_enable, hint_default_white;
uniform float wall_top_b = 3.5;
uniform float storey_b = 4.0;
// Tiefe der Höhenstufen in Metern – je größer, desto kräftiger die Glanzkanten
uniform float bump_depth = 0.035;
// Glanz → Rauheit (matt … Lack) und Stärke des Seidenschimmers bei flachem Blick
uniform float rough_matte = 0.95;
uniform float rough_gloss = 0.3;
uniform float sheen = 0.6;
// Alterung: so viel Glanz nehmen Flecken weg, so viel dunkeln sie ab
uniform float stain_gloss = 0.85;
uniform float stain_dark = 0.12;
uniform float snap_resolution = 140.0;
// Einstellungen → PS1-Look → Vertex-Wackeln (1 = an, 0 = aus)
global uniform float psx_snap;
// Einstellungen → PS1-Look aus: Farbbild bilinear statt Texel für Texel (1 = weich)
global uniform float psx_smooth;

varying vec3 world_pos;
varying vec3 world_normal;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
	vec4 clip = PROJECTION_MATRIX * (MODELVIEW_MATRIX * vec4(VERTEX, 1.0));
	if (psx_snap > 0.5 && clip.w > 0.0001) {
		vec2 ndc = clip.xy / clip.w;
		ndc = floor(ndc * snap_resolution + 0.5) / snap_resolution;
		clip.xy = ndc * clip.w;
	}
	POSITION = clip;
}

// Position auf der Wand (u waagrecht, h über dem Stockwerksboden, beides in Metern) → Texel
ivec2 texel_at(float u, float h, float top, ivec2 size) {
	float row;
	float base_h = (base_rows.y - base_rows.x) / texels_per_m;
	float frieze_h = (frieze_rows.y - frieze_rows.x) / texels_per_m;
	if (h < base_h) {
		row = base_rows.y - h * texels_per_m;
	} else if (h > top - frieze_h && h <= top) {
		row = frieze_rows.x + (top - h) * texels_per_m;
	} else {
		float period = field_rows.y - field_rows.x;
		row = field_rows.y - mod((h - base_h) * texels_per_m, period);
	}
	int x = int(floor(mod(u * texels_per_m, float(size.x))));
	return ivec2(x, clamp(int(ceil(row)) - 1, 0, size.y - 1));
}

vec3 wall_color(ivec2 t, bool side_b) {
	return side_b ? texelFetch(albedo_tex_b, t, 0).rgb : texelFetch(albedo_tex, t, 0).rgb;
}

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float value_noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x),
		mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
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
	float h = mod(world_pos.y, side_b ? storey_b : storey);
	if (tangent == vec3(0.0)) {
		h = top * 0.5;
	}
	ivec2 size = textureSize(albedo_tex, 0);
	ivec2 t = texel_at(u, h, top, size);
	vec3 tex = wall_color(t, side_b);
	if (psx_smooth > 0.5) {
		// Bilinear von Hand (die Bänder machen texture() unbrauchbar): vier Nachbar-Texel gewichten
		float half_m = 0.5 / texels_per_m;
		vec2 f = fract(vec2(u, h) * texels_per_m - 0.5);
		vec3 a = mix(wall_color(texel_at(u - half_m, h - half_m, top, size), side_b),
			wall_color(texel_at(u + half_m, h - half_m, top, size), side_b), f.x);
		vec3 b = mix(wall_color(texel_at(u - half_m, h + half_m, top, size), side_b),
			wall_color(texel_at(u + half_m, h + half_m, top, size), side_b), f.x);
		tex = mix(a, b, f.y);
	}
	vec2 surf = texelFetch(surface_tex, t, 0).rg;
	float gloss = surf.g;

	// Flecken und abgegriffene Stellen: großflächiges Rauschen nimmt Glanz weg und dunkelt leicht ab
	float stain = smoothstep(0.55, 0.8, value_noise(vec2(u, world_pos.y) * 1.3) * 0.7 + value_noise(vec2(u, world_pos.y) * 5.0) * 0.3);
	float scuff = 1.0 - smoothstep(0.05, 0.25, h);
	gloss *= 1.0 - stain_gloss * max(stain, scuff * 0.6);

	ALBEDO = albedo.rgb * tex * (1.0 - stain_dark * stain);
	ROUGHNESS = mix(rough_matte, rough_gloss, gloss);
	SPECULAR = gloss;
	RIM = sheen * gloss;
	RIM_TINT = 0.6;

	// Glanzkanten: Höhensprung zum Nachbar-Texel rechts und darüber kippt die Normale
	if (tangent != vec3(0.0)) {
		float step_m = 1.0 / texels_per_m;
		float hr = texelFetch(surface_tex, texel_at(u + step_m, h, top, size), 0).r;
		float hu = texelFetch(surface_tex, texel_at(u, h + step_m, top, size), 0).r;
		vec3 grad = ((hr - surf.r) * tangent + (hu - surf.r) * vec3(0.0, 1.0, 0.0)) * bump_depth / step_m;
		vec3 nw = normalize(world_normal - grad);
		NORMAL = normalize((VIEW_MATRIX * vec4(nw, 0.0)).xyz);
	}
}
