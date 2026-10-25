// Dichter weißer Nebel in der Duschecke von Zimmer 13 (ShowerScare, Spielkonzept 4.24): Dampf, der langsam aufsteigt
// und wirbelt, zum Rand der Box hin weich ausläuft (UVW) und etwas selbst leuchtet – im dunklen Bad steht er hell im
// Raum. density folgt dem Moment (Aufziehen, Verziehen); die Zeit kommt als Uniform t aus dem Skript (steht in der Pause).
shader_type fog;

uniform float density = 2.0;
uniform vec3 albedo : source_color = vec3(0.92, 0.93, 0.95);
uniform vec3 emission : source_color = vec3(0.05, 0.05, 0.055);
// Anteil der Box, über den der Nebel zum Rand hin ausläuft (je Achse)
uniform vec3 edge = vec3(0.12, 0.2, 0.12);
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
	// steigt auf (Muster wandert nach oben) und wirbelt seitlich
	float swirl = noise(p * 1.7 + vec3(sin(t * 0.3) * 0.4, -t * 0.35, t * 0.07)) * 0.6
		+ noise(p * 4.2 + vec3(t * 0.12, -t * 0.6, 0.0)) * 0.4;
	vec3 e = min(UVW, 1.0 - UVW) / edge;
	float soft = clamp(min(min(e.x, e.y), e.z), 0.0, 1.0);
	DENSITY = density * soft * soft * (0.4 + swirl);
	ALBEDO = albedo;
	EMISSION = emission;
}
