// Regen (Spielkonzept 7.8): Tropfen in einem Kasten um den Spieler. Jeder fällt bis zur obersten Fläche unter sich –
// Boden im Garten, Dach bzw. Decke über dem Hotel – und beginnt dann oben neu. So regnet es nie drinnen.
// Die Höhen stehen in roof_height (Weather._build_roofs: ein Wert je Zelle, Meter; tief unten = nichts darunter).
shader_type particles;

uniform sampler2D roof_height : filter_nearest, repeat_disable;
uniform vec2 map_origin;          // Weltkoordinaten (x, z) der Ecke von Pixel (0, 0)
uniform float cell = 0.5;         // Kantenlänge einer Zelle (m)
uniform vec3 center;              // um diesen Punkt (Spieler) regnet es
uniform float half_extent = 18.0;
uniform float top = 16.0;         // so hoch (Welt-y) beginnen die Tropfen
uniform float speed = 11.0;
uniform vec2 wind = vec2(0.8, 0.3);

float rnd(inout uint seed) {
	seed = seed * 747796405u + 2891336453u;
	uint w = ((seed >> ((seed >> 28u) + 4u)) ^ seed) * 277803737u;
	w = (w >> 22u) ^ w;
	return float(w) / 4294967295.0;
}

float roof_at(vec2 xz) {
	ivec2 size = textureSize(roof_height, 0);
	ivec2 px = ivec2(floor((xz - map_origin) / cell));
	if (px.x < 0 || px.y < 0 || px.x >= size.x || px.y >= size.y) {
		return 0.0;   // außerhalb des Plans: offenes Gelände
	}
	return texelFetch(roof_height, px, 0).r;
}

vec3 new_drop(inout uint seed, bool anywhere) {
	vec3 p = vec3(center.x + (rnd(seed) * 2.0 - 1.0) * half_extent, top,
		center.z + (rnd(seed) * 2.0 - 1.0) * half_extent);
	if (anywhere) {
		p.y = mix(roof_at(p.xz), top, rnd(seed));   // am Anfang überall in der Säule
	}
	return p;
}

void start() {
	uint seed = RANDOM_SEED + INDEX * 7919u + NUMBER * 104729u;
	TRANSFORM = mat4(1.0);
	TRANSFORM[3].xyz = new_drop(seed, true);
	VELOCITY = vec3(wind.x, -speed, wind.y);
	CUSTOM.x = float(seed % 65536u);
}

void process() {
	vec3 p = TRANSFORM[3].xyz;
	vec2 off = p.xz - center.xz;
	if (p.y < roof_at(p.xz) || max(abs(off.x), abs(off.y)) > half_extent * 1.05) {
		uint seed = uint(CUSTOM.x) * 2654435761u + NUMBER * 31u + INDEX;
		CUSTOM.x = float(seed % 65536u);
		p = new_drop(seed, false);
		// unter einem Dach (oder außerhalb des Kastens) neu oben anfangen, in einer anderen Spalte
	}
	TRANSFORM[3].xyz = p;   // weiter bewegt ihn die Engine (VELOCITY × DELTA)
	VELOCITY = vec3(wind.x, -speed, wind.y);
}
