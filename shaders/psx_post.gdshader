// Vollbild-Effekt: Gamma, Rauschen, Bild-Flackern
// und Zeilenversatz, die der MonsterDirector bei Erscheinen des Monsters hochregelt.
// Müde oder im Rausch verschwimmt die Sicht (blur, warp – setzt main._process aus Player.sight_blur/sight_warp).
shader_type canvas_item;

uniform sampler2D screen_tex : hint_screen_texture, filter_nearest;
// dasselbe Bild mit Mipmaps für die Unschärfe (weich, wenige Abtastungen)
uniform sampler2D blur_tex : hint_screen_texture, filter_linear_mipmap;
uniform float noise_amount = 0.0;
uniform float flicker = 0.0;
uniform float vignette = 0.6;
uniform float red_tint = 0.0;
uniform float gamma = 1.0;   // Einstellungen → Helligkeit
uniform float blur = 0.0;    // Unschärfe 0..1 (Müdigkeit, Rausch – Spielkonzept 3.6/3.7)
uniform float warp = 0.0;    // Wabern und Doppelbild im Rausch 0..1
uniform float blur_time = 0.0;   // Spielzeit fürs Wabern (steht in der Pause)
uniform float dream = 0.0;   // Albtraum von 1987 (Spielkonzept 4.29): verblichenes Foto in Rauchorange, dunkler Rand; über 1 weiß

const float BLUR_RADIUS = 0.012;   // Radius bei blur = 1, Anteil der Bildhöhe
const float WARP_SHIFT = 0.004;    // Verzerrung bei warp = 1, Anteil der Bildhöhe
const float DOUBLE_SHIFT = 0.012;  // Versatz des Doppelbilds bei warp = 1
const float GOLDEN_ANGLE = 2.39996;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
	vec2 uv = SCREEN_UV;
	float n2 = noise_amount * noise_amount;
	// Zeilenversatz (VHS-Tearing)
	float row = floor(uv.y * 135.0);
	float tear = (hash(vec2(row, floor(TIME * 24.0))) - 0.5) * n2 * 0.05;
	vec2 suv = uv + vec2(tear, 0.0);
	vec3 col;
	if (blur > 0.001 || warp > 0.001) {
		// Höhe → Breite: Radien sind Anteile der Bildhöhe
		vec2 aspect = vec2(SCREEN_PIXEL_SIZE.x / SCREEN_PIXEL_SIZE.y, 1.0);
		// Wabern: langsame Wellen verziehen das Bild
		suv += vec2(sin(uv.y * 7.0 + blur_time * 1.3), sin(uv.x * 5.0 - blur_time * 0.9)) * aspect * warp * WARP_SHIFT;
		// Unschärfe: Scheibe aus 16 Abtastungen (Goldener Winkel) in einer weichen Mipmap-Stufe
		float r = blur * BLUR_RADIUS;
		float lod = log2(max(r / SCREEN_PIXEL_SIZE.y * 0.3, 1.0));
		col = vec3(0.0);
		for (int i = 0; i < 16; i++) {
			float k = (float(i) + 0.5) / 16.0;
			float a = float(i) * GOLDEN_ANGLE;
			col += textureLod(blur_tex, suv + vec2(cos(a), sin(a)) * sqrt(k) * r * aspect, lod).rgb;
		}
		col /= 16.0;
		// Doppelbild im Rausch: ein blasser, schwankend versetzter zweiter Blick
		vec2 ghost = vec2(0.6 + 0.4 * sin(blur_time * 0.7), 0.15 * sin(blur_time * 0.5)) * aspect * warp * DOUBLE_SHIFT;
		col = mix(col, textureLod(blur_tex, suv + ghost, lod).rgb, 0.35 * warp);
	} else {
		col = texture(screen_tex, suv).rgb;
	}
	// Körniges Rauschen
	float grain = hash(FRAGCOORD.xy + vec2(fract(TIME * 7.0) * 311.0, fract(TIME * 3.0) * 173.0));
	col = mix(col, vec3(grain * 0.8), noise_amount * 0.5);
	// Rollbalken
	float roll = 1.0 - smoothstep(0.0, 0.04, abs(fract(uv.y * 0.5 - TIME * 0.21) - 0.5));
	col += roll * n2 * 0.15;
	// Bild-Flackern
	col *= 1.0 - flicker;
	// Helligkeit (vor der Vignette)
	col = pow(max(col, vec3(0.0)), vec3(1.0 / gamma));
	// Albtraum: entsättigt wie ein altes Foto, warm getönt, Rand dunkler und unruhig
	if (dream > 0.001) {
		float lum = dot(col, vec3(0.3, 0.55, 0.15));
		vec3 old = vec3(lum * 1.15, lum * 0.82, lum * 0.55) + vec3(0.03, 0.012, 0.0);
		col = mix(col, old, min(dream, 1.0) * 0.85);
		col = mix(col, vec3(1.0, 0.96, 0.9), clamp(dream - 1.0, 0.0, 1.0));   // > 1: es wird gleißend weiß
	}
	// Vignette
	vec2 d = uv - 0.5;
	col *= clamp(1.0 - dot(d, d) * (vignette + min(dream, 1.0) * (1.6 + 0.3 * sin(TIME * 2.3))) * 2.0, 0.0, 1.0);
	col.r += red_tint;
	COLOR = vec4(col, 1.0);
}
