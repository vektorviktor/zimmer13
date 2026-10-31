// Sicht aus dem Versteck: 1 = Schrank (nur dunkle Ränder – die Lamellen sind echt, HideSpot.show_inside),
// 2 = unter dem Bett, 3 = schlafen (Augen zu).
// „stress“ steigt, je länger man drin bleibt.
shader_type canvas_item;

uniform int mode = 0;
uniform float stress = 0.0;

void fragment() {
	vec2 uv = UV;
	float a = 0.0;
	if (mode == 1) {
		a = 0.85 * smoothstep(0.35, 0.75, length((uv - 0.5) * vec2(1.6, 1.0)));
	} else if (mode == 2) {
		a = 1.0 - smoothstep(0.38, 0.46, uv.y);
		a = max(a, smoothstep(0.88, 1.0, uv.y) * 0.8);
		a = max(a, smoothstep(0.38, 0.5, abs(uv.x - 0.5)) * 0.9);
	} else if (mode == 3) {
		a = 0.985 + 0.015 * sin(TIME * 0.8);
	}
	float pulse = stress * (0.6 + 0.4 * sin(TIME * 9.0));
	COLOR = vec4(0.12 * pulse, 0.0, 0.0, clamp(a + pulse * 0.25, 0.0, 1.0));
}
