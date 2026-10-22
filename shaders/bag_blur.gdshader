shader_type canvas_item;
// Tasche offen (Spielkonzept 3.2): Das Spiel dahinter verschwimmt und wird dunkler – es läuft weiter (Hud.show_bag_menu).

uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap;
uniform float amount = 1.0;   // 0..1, blendet ein
const float SPREAD = 2.5;     // Abstand der Stichproben in Pixeln der internen Auflösung
const float DARKEN = 0.5;

void fragment() {
	vec3 col = vec3(0.0);
	for (int x = -2; x <= 2; x++) {
		for (int y = -2; y <= 2; y++) {
			col += textureLod(screen_tex, SCREEN_UV + vec2(float(x), float(y)) * SCREEN_PIXEL_SIZE * SPREAD, 1.5).rgb;
		}
	}
	vec3 sharp = textureLod(screen_tex, SCREEN_UV, 0.0).rgb;
	COLOR = vec4(mix(sharp, col / 25.0 * DARKEN, amount), 1.0);
}
