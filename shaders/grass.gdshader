// Grasbüschel im Garten (Grass), nur ohne PS1-Look: gekreuzte Halmkarten, ausgestanzt nach dem Alpha, beidseitig,
// ohne Snapping und mit Mipmaps. Beleuchtet wie der Boden darunter (Normale nach oben), zum Grund hin dunkler. Die
// Spitzen wiegen sich im Wind (wind_time zählt Grass aus der Spielzeit hoch – steht in der Pause) und weichen
// Füßen und Gegenständen aus (pushers: Mitte xyz, w = Radius; sie drücken die Halme weg und nieder).
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_disabled, diffuse_lambert, specular_disabled;

const int MAX_PUSHERS = 24;

uniform sampler2D albedo_tex : source_color, filter_linear_mipmap, repeat_disable;
uniform float alpha_cut = 0.35;
uniform float wind_time = 0.0;
// Ausschlag der Spitzen in Metern, Wellenlänge der Böen über den Garten
uniform float wind_strength = 0.05;
uniform float wind_scale = 0.3;
uniform vec4 pushers[MAX_PUSHERS];
uniform int pusher_count = 0;
// wie weit eine Spitze am Rand des Kreises weggedrückt wird, wie tief sie in der Mitte niedergeht (Anteil der Höhe)
uniform float push_strength = 0.3;
uniform float push_down = 0.6;
// Helligkeit am Grund (Anteil der Spitze)
uniform float base_shade = 0.4;
// Regen (Weather, Spielkonzept 7.8): nasse Halme dunkler, beim Blutregen rot benetzt – wie der Boden (wet_ground)
global uniform float rain_wet;
global uniform float rain_blood;
uniform vec3 wet_blood : source_color = vec3(0.533, 0.031, 0.031);   // #880808

varying float tip;
varying vec3 tint;

void vertex() {
	tip = 1.0 - UV.y;   // 0 am Grund, 1 an der Spitze
	tint = COLOR.rgb;
	vec3 world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	vec3 root = MODEL_MATRIX[3].xyz;
	float bend = tip * tip;
	float height = world.y - root.y;
	vec3 offset = vec3(
		sin(wind_time * 1.3 + root.x * wind_scale + root.z * wind_scale * 0.6),
		0.0,
		0.5 * sin(wind_time * 0.9 + root.z * wind_scale * 1.3)) * wind_strength * bend;
	for (int i = 0; i < pusher_count; i++) {
		vec2 d = root.xz - pushers[i].xz;
		float r = pushers[i].w;
		float dist = length(d);
		if (dist < r && abs(root.y - pushers[i].y) < 1.0) {
			float k = 1.0 - dist / r;
			offset.xz += (d / max(dist, 0.001)) * k * push_strength * bend;
			offset.y -= k * push_down * height;
		}
	}
	VERTEX += inverse(mat3(MODEL_MATRIX)) * offset;
}

void fragment() {
	vec4 tex = texture(albedo_tex, UV);
	ALBEDO = tex.rgb * tint * mix(base_shade, 1.0, tip);
	float luma = dot(ALBEDO, vec3(0.3, 0.59, 0.11));
	ALBEDO *= mix(1.0, 0.7, rain_wet);
	ALBEDO = mix(ALBEDO, wet_blood * (0.5 + 1.2 * luma), rain_wet * rain_blood * 0.075);
	ALPHA = tex.a;
	ALPHA_SCISSOR_THRESHOLD = alpha_cut;
	NORMAL = normalize((VIEW_MATRIX * vec4(0.0, 1.0, 0.0, 0.0)).xyz);
	ROUGHNESS = 1.0;
}
