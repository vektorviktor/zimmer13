// Partikel im PS1-Look (Noten am Plattenspieler, Flocken am Lakengeist, Asche hinter dem Monster):
// Billboard mit Vertex-Snapping und Nearest-Filter, Ausblenden über das 4×4-Raster wie psx_ghost.
// Für CPUParticles3D: Farbe und Deckkraft aus COLOR (color × color_ramp), INSTANCE_CUSTOM.x = Startwinkel
// (angle_min/max 0…360 → Zufallswert je Partikel), INSTANCE_CUSTOM.y = Anteil der Lebenszeit 0…1.
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_disabled, diffuse_lambert, specular_disabled, skip_vertex_transform;

uniform sampler2D albedo_tex : source_color, filter_nearest, hint_default_white;
// Bilder nebeneinander in albedo_tex – jeder Partikel nimmt per Zufall eins
uniform int frames = 1;
// Farbton der Textur ersetzen (Regenbogen): Startton per Zufall, wandert über die Lebenszeit um hue_drift
uniform bool rainbow = false;
uniform float hue_drift = 0.0;
// Helligkeit (HSV-Wert) der Textur × brighten
uniform float brighten = 1.0;
// Eigenleuchten (Anteil der Farbe)
uniform float glow = 0.0;
// 1 = ganz da, 0 = verschwunden (zusätzlich zu COLOR.a)
uniform float fade = 1.0;
// Seitliches Schaukeln (m) und Kippen (rad), sway_cycles Schwingungen je Lebenszeit
uniform float sway = 0.0;
uniform float tilt = 0.0;
uniform float sway_cycles = 1.0;
// Drehen in der Bildebene, Umdrehungen je Lebenszeit (Flocken)
uniform float spin = 0.0;
// Bodenhöhe in Weltkoordinaten: darunter liegt ein Partikel flach auf dem Boden statt weiterzufallen
// (Herbstlaub – CPUParticles3D kennt keine Kollision); Schaukeln läuft auf dem letzten halben Meter aus
uniform float floor_y = -10000.0;
uniform float snap_resolution = 140.0;
global uniform float psx_snap;

varying flat float seed;
varying float life;
varying flat float frame;

void vertex() {
	seed = INSTANCE_CUSTOM.x / 6.2831853;
	life = INSTANCE_CUSTOM.y;
	frame = floor(fract(seed * 7.13 + 0.37) * float(frames));
	float wave = sin((life * sway_cycles + seed) * 6.2831853);
	float angle = tilt * wave;
	if (spin != 0.0) {
		angle += (seed + life * spin) * 6.2831853;
	}
	float size = length(MODEL_MATRIX[0].xyz);
	vec3 world = MODEL_MATRIX[3].xyz;
	if (world.y <= floor_y) {
		float a = seed * 6.2831853;
		vec2 c = mat2(vec2(cos(a), sin(a)), vec2(-sin(a), cos(a))) * VERTEX.xy * size;
		VERTEX = (VIEW_MATRIX * vec4(world.x + c.x, floor_y, world.z + c.y, 1.0)).xyz;
		NORMAL = normalize((VIEW_MATRIX * vec4(0.0, 1.0, 0.0, 0.0)).xyz);
	} else {
		float near_floor = clamp((world.y - floor_y) / 0.5, 0.0, 1.0);
		vec2 corner = mat2(vec2(cos(angle), sin(angle)), vec2(-sin(angle), cos(angle))) * VERTEX.xy * size;
		vec3 center = (VIEW_MATRIX * vec4(world, 1.0)).xyz;
		VERTEX = center + vec3(corner + vec2(sway * wave * near_floor, 0.0), 0.0);
		NORMAL = vec3(0.0, 0.0, 1.0);
	}
	vec4 clip = PROJECTION_MATRIX * vec4(VERTEX, 1.0);
	if (psx_snap > 0.5 && clip.w > 0.0001) {
		vec2 ndc = clip.xy / clip.w;
		ndc = floor(ndc * snap_resolution + 0.5) / snap_resolution;
		clip.xy = ndc * clip.w;
	}
	POSITION = clip;
}

const float BAYER[16] = float[](0.0, 8.0, 2.0, 10.0, 12.0, 4.0, 14.0, 6.0, 3.0, 11.0, 1.0, 9.0, 15.0, 7.0, 13.0, 5.0);

vec3 rgb2hsv(vec3 c) {
	vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
	vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
	vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));
	float d = q.x - min(q.w, q.y);
	return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + 1e-10)), d / (q.x + 1e-10), q.x);
}

vec3 hsv2rgb(vec3 c) {
	vec3 p = abs(fract(c.xxx + vec3(1.0, 2.0 / 3.0, 1.0 / 3.0)) * 6.0 - 3.0);
	return c.z * mix(vec3(1.0), clamp(p - 1.0, 0.0, 1.0), c.y);
}

void fragment() {
	ivec2 p = ivec2(FRAGCOORD.xy) % 4;
	if ((BAYER[p.y * 4 + p.x] + 0.5) / 16.0 > fade * COLOR.a) {
		discard;
	}
	vec4 tex = texture(albedo_tex, vec2((UV.x + frame) / float(frames), UV.y));
	if (tex.a < 0.5) {
		discard;
	}
	vec3 hsv = rgb2hsv(tex.rgb);
	if (rainbow) {
		hsv.x = fract(seed + hue_drift * life);
	}
	hsv.z = min(1.0, hsv.z * brighten);
	vec3 col = hsv2rgb(hsv) * COLOR.rgb;
	ALBEDO = col;
	ROUGHNESS = 1.0;
	SPECULAR = 0.0;
	EMISSION = col * glow;
}
