// Sisal-Dartscheibe (Spielkonzept 6.10) auf einem Quad: Felder nach Turniermaß (Darts.gd), Borstenenden als feines
// Rauschen, Einstiche um die 20 dichter, Spinne aus Draht mit Glanz. Außerhalb der Scheibe wird verworfen. Drähte
// sind höchstens so schmal wie ein Bildpunkt, nur blasser – sonst flimmern sie in der kleinen Auflösung.
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back;
#include "res://shaders/psx_snap.gdshaderinc"

uniform float size = 0.451;   // Kantenlänge des Quads in m (= Durchmesser der Scheibe)
uniform vec3 black : source_color = vec3(0.04, 0.038, 0.035);
uniform vec3 cream : source_color = vec3(0.80, 0.71, 0.53);
uniform vec3 red : source_color = vec3(0.60, 0.07, 0.05);
uniform vec3 green : source_color = vec3(0.05, 0.33, 0.13);
uniform vec3 wire : source_color = vec3(0.80, 0.80, 0.82);
uniform float wire_width = 0.0011;

const float R_BULL = 0.00635;
const float R_OUTER_BULL = 0.0159;
const float R_TRIPLE_IN = 0.099;
const float R_TRIPLE_OUT = 0.107;
const float R_DOUBLE_IN = 0.162;
const float R_DOUBLE_OUT = 0.170;
const float R_BOARD = 0.2255;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void vertex() {
	POSITION = psx_snap_clip(PROJECTION_MATRIX * (MODELVIEW_MATRIX * vec4(VERTEX, 1.0)));
}

void fragment() {
	vec2 p = (UV - 0.5) * size * vec2(1.0, -1.0);
	float r = length(p);
	if (r > R_BOARD) {
		discard;
	}
	float a = mod(degrees(atan(p.x, p.y)) + 9.0 + 360.0, 360.0);   // im Uhrzeigersinn ab oben, Segmentgrenze bei 0
	bool dark = mod(floor(a / 18.0), 2.0) < 0.5;                   // die 20 ist schwarz
	vec3 col = black;
	if (r <= R_BULL) {
		col = red;
	} else if (r <= R_OUTER_BULL) {
		col = green;
	} else if (r < R_TRIPLE_IN || (r > R_TRIPLE_OUT && r < R_DOUBLE_IN)) {
		col = dark ? black : cream;
	} else if (r <= R_DOUBLE_OUT) {
		col = dark ? red : green;
	}
	// Sisal: dicht gepresste Borstenenden, dazu etwas gröbere Flecken
	col *= 0.86 + 0.22 * hash(floor(p / 0.0007)) + 0.1 * (hash(floor(p / 0.0024) + 17.0) - 0.5);
	// Einstiche: dunkle Pünktchen, oben um die 20 (dort zielt jeder) viel dichter
	float wear = smoothstep(0.07, 0.0, distance(p, vec2(0.0, 0.115)));
	float hole = step(0.988 - wear * 0.05, hash(floor(p / 0.0011) + 3.0));
	col *= 1.0 - hole * 0.5 * step(r, R_DOUBLE_OUT);
	// Drähte: Ringe und die Speichen zwischen Single-Bull und Double
	float d = min(min(abs(r - R_BULL), abs(r - R_OUTER_BULL)), min(abs(r - R_TRIPLE_IN), abs(r - R_TRIPLE_OUT)));
	d = min(d, min(abs(r - R_DOUBLE_IN), abs(r - R_DOUBLE_OUT)));
	if (r > R_OUTER_BULL && r < R_DOUBLE_OUT + wire_width) {
		float edge = mod(a, 18.0);
		d = min(d, radians(min(edge, 18.0 - edge)) * r);
	}
	float px = fwidth(r) + 1e-6;
	float width = max(wire_width, px);
	float on_wire = (1.0 - smoothstep(width * 0.5 - px * 0.5, width * 0.5 + px * 0.5, d)) * min(1.0, wire_width / width * 1.6);
	ALBEDO = mix(col, wire, on_wire);
	METALLIC = on_wire;
	ROUGHNESS = mix(0.93, 0.3, on_wire);
	SPECULAR = mix(0.2, 0.5, on_wire);
}
