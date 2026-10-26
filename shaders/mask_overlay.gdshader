// Sicht unter einer verbotenen Maske (Spielkonzept 5.19): die Innenseite der Maske ringsum, der Blick nur durch ihre
// zwei Augenlöcher – mandelförmig (Puppe) oder als vierzackiger Stern (Kürbismann). Ränder weich, innen zum Rand hin
// dunkler, weil die Maske nah vor dem Gesicht sitzt.
shader_type canvas_item;

uniform float aspect = 1.7778;   // Breite / Höhe des Bildschirms
uniform vec3 inside = vec3(0.12, 0.1, 0.08);
uniform float star = 0.0;        // 0 = Mandel, 1 = Stern
uniform vec2 hole_size = vec2(0.17, 0.11);   // Halbachsen eines Augenlochs in Bildhöhen
uniform float eye_gap = 0.2;     // Abstand eines Augenlochs von der Mitte in Bildhöhen

// 0 innerhalb eines Augenlochs, 1 auf der Maske
float hole(vec2 uv, vec2 center) {
	vec2 d = (uv - center) * vec2(aspect, 1.0) / hole_size;
	float almond = length(d * vec2(1.0, 1.0 + 0.6 * abs(d.x)));
	// Stern: Spitzen auf den Achsen (Norm mit Exponent unter 1 – je kleiner, desto spitzer)
	vec2 a = abs(d);
	float pointed = pow(pow(a.x, 0.65) + pow(a.y, 0.65), 1.0 / 0.65);
	float r = mix(almond, pointed, star);
	return smoothstep(0.9, 1.05, r);
}

void fragment() {
	// Augenlöcher eye_gap Bildhöhen links und rechts der Mitte
	float a = min(hole(UV, vec2(0.5 - eye_gap / aspect, 0.46)), hole(UV, vec2(0.5 + eye_gap / aspect, 0.46)));
	vec2 c = (UV - vec2(0.5, 0.46)) * vec2(aspect, 1.0);
	float shade = 1.0 - 0.45 * smoothstep(0.3, 1.1, length(c));
	COLOR = vec4(inside * shade, a * 0.98);
}
