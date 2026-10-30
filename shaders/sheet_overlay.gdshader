// Sicht unter dem übergeworfenen Bettlaken (Spielkonzept 5.9): heller Stoff ringsum, der Blick nur durch zwei
// ausgeschnittene Augenlöcher. Die Ränder sind etwas ausgefranst.
shader_type canvas_item;

uniform float aspect = 1.7778;   // Breite / Höhe des Bildschirms
uniform vec3 cloth = vec3(0.16, 0.16, 0.17);

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

// 0 innerhalb eines Augenlochs, 1 im Stoff
float hole(vec2 uv, vec2 center) {
	vec2 d = (uv - center) * vec2(aspect, 1.0) / vec2(0.2, 0.25);
	float angle = atan(d.y, d.x);
	float fray = 0.06 * hash(vec2(floor(angle * 9.0), center.x));
	return smoothstep(0.9 + fray, 1.0 + fray, length(d));
}

void fragment() {
	// Augenlöcher 0,23 Bildhöhen links und rechts der Mitte
	float a = min(hole(UV, vec2(0.5 - 0.23 / aspect, 0.47)), hole(UV, vec2(0.5 + 0.23 / aspect, 0.47)));
	// Faltenschatten im Stoff
	float fold = 0.85 + 0.15 * sin(UV.x * 23.0 + sin(UV.y * 7.0) * 2.0);
	COLOR = vec4(cloth * fold, a * 0.97);
}
