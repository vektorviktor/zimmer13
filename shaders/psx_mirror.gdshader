// Spiegelplättchen der Discokugel (DiscoBall): Das Hotel hat keine Reflexionen (Environment ohne
// Spiegelung), darum spiegelt jedes Plättchen hier den Raum, den die jeweilige Lampe beleuchtet – ein
// Helligkeitsmuster je Spiegelrichtung in Weltkoordinaten, das beim Drehen über die Plättchen wandert –,
// und blitzt, wo die Lampe selbst im Plättchen steht. Ohne Licht bleibt die Kugel dunkel. Die Fugen sind
// matt. Normal Map: jedes Plättchen eine eigene, flache Ausrichtung (tools/build_disco_ball.py).
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back;
#include "res://shaders/psx_snap.gdshaderinc"

// Linear gefiltert: Bei 480×270 ist die Kugel oft nur 20–40 Pixel groß, mit Nearest flimmerten die Fugen
uniform sampler2D albedo_tex : source_color, filter_linear_mipmap, hint_default_white;
uniform sampler2D normal_tex : hint_normal, filter_linear_mipmap;
// Spiegelmaske im Blaukanal (glTF-Metallic)
uniform sampler2D mirror_tex : filter_linear_mipmap, hint_default_black;
// Spiegelbild: Helligkeit des Raums (Grundwert, Schwankung) und Größe der Flecken im Spiegelbild
uniform float room_base = 0.25;
uniform float room_vary = 1.1;
uniform float room_scale = 6.0;
// Blitzen: Kegel (Kosinus des halben Winkels) und Stärke
uniform float glint_cos = 0.99;
uniform float glint_energy = 14.0;

varying float mirror;

void vertex() {
	vec4 clip = PROJECTION_MATRIX * (MODELVIEW_MATRIX * vec4(VERTEX, 1.0));
	clip = psx_snap_clip(clip);
	POSITION = clip;
}

void fragment() {
	ALBEDO = texture(albedo_tex, UV).rgb;
	NORMAL_MAP = texture(normal_tex, UV).rgb;
	mirror = texture(mirror_tex, UV).b;
	ROUGHNESS = 1.0;
}

float hash(vec3 p) {
	p = fract(p * 0.3183099 + 0.1);
	p *= 17.0;
	return fract(p.x * p.y * p.z * (p.x + p.y + p.z));
}

// Glattes Wertrauschen 0..1 – die „Einrichtung“ im Spiegelbild
float noise(vec3 x) {
	vec3 i = floor(x);
	vec3 f = fract(x);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(mix(hash(i), hash(i + vec3(1, 0, 0)), f.x), mix(hash(i + vec3(0, 1, 0)), hash(i + vec3(1, 1, 0)), f.x), f.y),
		mix(mix(hash(i + vec3(0, 0, 1)), hash(i + vec3(1, 0, 1)), f.x), mix(hash(i + vec3(0, 1, 1)), hash(i + vec3(1, 1, 1)), f.x), f.y), f.z);
}

void light() {
	vec3 lit = ATTENUATION * LIGHT_COLOR / PI;
	float ndl = dot(NORMAL, LIGHT);
	// Fuge: matt
	DIFFUSE_LIGHT += (1.0 - mirror) * max(ndl, 0.0) * lit;
	// Spiegel: der Raum in Spiegelrichtung, auf der lampenabgewandten Seite schwächer
	vec3 r = reflect(-VIEW, NORMAL);
	vec3 rw = (INV_VIEW_MATRIX * vec4(r, 0.0)).xyz;
	float room = room_base + room_vary * noise(rw * room_scale) * (0.6 + 0.4 * noise(rw * room_scale * 3.1 + 7.0));
	DIFFUSE_LIGHT += mirror * room * mix(0.35, 1.0, smoothstep(-0.5, 0.5, ndl)) * lit;
	// Die Lampe selbst im Plättchen
	SPECULAR_LIGHT += mirror * smoothstep(glint_cos, 1.0, dot(r, LIGHT)) * glint_energy * lit;
}
