// Vollbild-Effekt: Farbreduktion + Dithering (PS1), dazu Rauschen, Bild-Flackern
// und Zeilenversatz, die der MonsterDirector bei Erscheinen des Monsters hochregelt.
shader_type canvas_item;

uniform sampler2D screen_tex : hint_screen_texture, filter_nearest;
uniform float color_levels = 28.0;
uniform float dither = 1.0;
uniform float noise_amount = 0.0;
uniform float flicker = 0.0;
uniform float vignette = 0.6;
uniform float red_tint = 0.0;
uniform float gamma = 1.0;   // Einstellungen → Helligkeit

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

float bayer2(vec2 a) {
	a = floor(a);
	return fract(a.x / 2.0 + a.y * a.y * 0.75);
}

float bayer4(vec2 a) {
	return bayer2(0.5 * a) * 0.25 + bayer2(a);
}

void fragment() {
	vec2 uv = SCREEN_UV;
	float n2 = noise_amount * noise_amount;
	// Zeilenversatz (VHS-Tearing)
	float row = floor(uv.y * 135.0);
	float tear = (hash(vec2(row, floor(TIME * 24.0))) - 0.5) * n2 * 0.05;
	vec3 col = texture(screen_tex, uv + vec2(tear, 0.0)).rgb;
	// Körniges Rauschen
	float grain = hash(FRAGCOORD.xy + vec2(fract(TIME * 7.0) * 311.0, fract(TIME * 3.0) * 173.0));
	col = mix(col, vec3(grain * 0.8), noise_amount * 0.5);
	// Rollbalken
	float roll = 1.0 - smoothstep(0.0, 0.04, abs(fract(uv.y * 0.5 - TIME * 0.21) - 0.5));
	col += roll * n2 * 0.15;
	// Bild-Flackern
	col *= 1.0 - flicker;
	// Helligkeit (vor Vignette und Farbreduktion)
	col = pow(max(col, vec3(0.0)), vec3(1.0 / gamma));
	// Vignette
	vec2 d = uv - 0.5;
	col *= clamp(1.0 - dot(d, d) * vignette * 2.0, 0.0, 1.0);
	col.r += red_tint;
	// Dithering + Farbreduktion
	col += (bayer4(FRAGCOORD.xy) - 0.5) * dither / color_levels;
	col = floor(col * color_levels + 0.5) / color_levels;
	COLOR = vec4(col, 1.0);
}
