// Regen ohne PS1-Look (Spielkonzept 7.8): feine Striche statt Klötzchen. Ein Quad je Tropfen (shaders/rain.gdshader
// bewegt sie), hier längs der Fallrichtung gestreckt und quer zum Blick gedreht. Schmaler als min_pixels Bildpunkte
// wird ein Strich nie – wäre er dünner (weiter weg), wird er stattdessen blasser (gedämpft: Wurzel, sonst verschwindet
// ferner Regen ganz); so flimmern feine Linien nicht.
// Enden und Ränder weich, ganz nah an der Kamera blendet er aus.
shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled, skip_vertex_transform;

uniform vec4 color : source_color = vec4(0.72, 0.77, 0.88, 0.3);
uniform vec3 fall = vec3(0.8, -11.0, 0.3);   // Geschwindigkeit (m/s) – gibt die Richtung des Strichs
uniform float streak_length = 0.5;           // m
uniform float streak_width = 0.0015;         // m
uniform float min_pixels = 1.5;
uniform float near_fade = 0.6;               // m

varying float coverage;

void vertex() {
	vec3 center = (VIEW_MATRIX * vec4(MODEL_MATRIX[3].xyz, 1.0)).xyz;
	vec3 dir = (VIEW_MATRIX * vec4(normalize(fall), 0.0)).xyz;
	vec3 side = cross(dir, normalize(center));
	side = length(side) > 0.0001 ? normalize(side) : vec3(1.0, 0.0, 0.0);   // Blick genau längs des Strichs
	float depth = max(-center.z, 0.01);
	float pixel = 2.0 * depth / (PROJECTION_MATRIX[1][1] * VIEWPORT_SIZE.y);   // so viele Meter misst ein Bildpunkt
	float w = max(streak_width, pixel * min_pixels);
	coverage = sqrt(streak_width / w) * smoothstep(near_fade * 0.5, near_fade, depth);
	VERTEX = center + dir * streak_length * VERTEX.y + side * w * VERTEX.x;
	NORMAL = vec3(0.0, 0.0, 1.0);
}

void fragment() {
	float along = 1.0 - abs(UV.y * 2.0 - 1.0);
	float across = 1.0 - abs(UV.x * 2.0 - 1.0);
	ALBEDO = color.rgb;
	ALPHA = color.a * coverage * along * across;
}
