// Nebel draußen (Weather, Spielkonzept 7.8): ein FogVolume über dem ganzen Plan, das nur unter freiem Himmel Dichte
// hat – über der obersten Fläche der Dach-Höhenkarte des Regens (Weather._build_roof_rows), drinnen also nie. Am Boden
// am dichtesten, nach oben dünner (height m halbiert ihn etwa), fleckig und mit dem Wind treibend. Die Dichte steigt
// mit jedem Tag bis Halloween (density aus Weather). Wie weit er getrieben ist, zählt Weather aus der Spielzeit (drift,
// steht in der Pause).
shader_type fog;

uniform sampler2D roof_height : filter_nearest, repeat_disable;
uniform vec2 map_origin = vec2(0.0);
uniform float cell = 0.5;
uniform float density = 0.0;
uniform float height = 2.5;
uniform vec3 albedo : source_color = vec3(0.62, 0.66, 0.74);
uniform vec3 emission : source_color = vec3(0.004, 0.005, 0.007);
uniform vec2 drift = vec2(0.0);   // so weit getrieben (m)

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
	vec2 size = vec2(textureSize(roof_height, 0)) * cell;
	vec2 uv = (p.xz - map_origin) / size;
	float floor_y = texture(roof_height, uv).r;
	float above = p.y - floor_y;
	if (density <= 0.0 || above < 0.0 || uv.x < 0.0 || uv.y < 0.0 || uv.x > 1.0 || uv.y > 1.0) {
		DENSITY = 0.0;
	} else {
		vec3 d = vec3(drift.x, 0.0, drift.y);
		float patches = noise((p - d) * vec3(0.09, 0.3, 0.09)) * 0.65 + noise((p - d * 1.3) * 0.35) * 0.35;
		float layer = exp(-above / height);
		DENSITY = density * layer * (0.35 + 1.3 * patches);
		ALBEDO = albedo;
		EMISSION = emission;
	}
}
