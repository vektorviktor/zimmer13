// Staubnebel im Dachgeschoss (AtticHaze, Spielkonzept 4.21): blaugrau, fleckig wie aufgewirbelter Staub – Rauschen in
// Weltkoordinaten (die Rechtecke der FogVolumes stoßen nahtlos aneinander), das langsam treibt und leicht flimmert.
// Die Zeit kommt als Uniform t aus dem Skript (Spielzeit – steht in der Pause, TIME liefe weiter).
shader_type fog;

uniform float density = 0.09;
uniform vec3 albedo : source_color = vec3(0.5, 0.56, 0.68);
uniform vec3 emission : source_color = vec3(0.035, 0.04, 0.055);
// Flimmern: Anteil, um den die Dichte schwankt, und wie schnell
uniform float flicker = 0.18;
uniform float flicker_speed = 2.5;
uniform float t = 0.0;

float hash(vec3 p) {
	p = fract(p * vec3(0.1031, 0.1030, 0.0973));
	p += dot(p, p.yxz + 33.33);
	return fract((p.x + p.y) * p.z);
}

float noise(vec3 p) {
	vec3 i = floor(p);
	vec3 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(mix(hash(i), hash(i + vec3(1, 0, 0)), f.x), mix(hash(i + vec3(0, 1, 0)), hash(i + vec3(1, 1, 0)), f.x), f.y),
		mix(mix(hash(i + vec3(0, 0, 1)), hash(i + vec3(1, 0, 1)), f.x), mix(hash(i + vec3(0, 1, 1)), hash(i + vec3(1, 1, 1)), f.x), f.y), f.z);
}

void fog() {
	vec3 p = WORLD_POSITION;
	float clouds = noise(p * 0.45 + vec3(t * 0.04, t * 0.015, -t * 0.03)) * 0.6
		+ noise(p * 1.6 + vec3(0.0, -t * 0.06, t * 0.02)) * 0.4;
	float shimmer = noise(vec3(p.xz * 0.8, t * flicker_speed)) * 2.0 - 1.0;
	DENSITY = density * (0.45 + clouds) * (1.0 + flicker * shimmer);
	ALBEDO = albedo;
	EMISSION = emission;
}
