// Fototexturen (Mat.photo): wie psx_surface mit Textur in Weltkoordinaten (Vertex-Snapping), dazu ohne PS1-Look
// eine Normal Map und auf Wunsch Glanz (specular > 0, Rauheit aus einer Karte – polierte Fliesen). Matt
// (specular 0) sieht es aus wie psx_surface: Godot rechnet mit F0 = 0 keinen Glanz, auch nicht am Rand. Die Projektion folgt der Hauptachse der Flächennormale; die Achse, in
// die u bzw. das Bild-„oben“ zeigt, ist dort fest – daraus entsteht die Normale ohne Tangenten im Mesh.
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_lambert, specular_schlick_ggx;
#include "res://shaders/psx_snap.gdshaderinc"

uniform vec4 albedo : source_color = vec4(1.0);
uniform sampler2D albedo_tex : source_color, filter_nearest, repeat_enable, hint_default_white;
// Normal Map im OpenGL-Format (Y nach oben; DirectX-Karten dreht tools/photo_set.gd mit --dx)
uniform sampler2D normal_tex : hint_normal, filter_nearest, repeat_enable;
uniform bool use_normal = false;
uniform float normal_strength = 1.0;
// Glanz: Stärke (0 = matt, 0,5 = übliches Nichtmetall) und Rauheit – fest oder aus dem Rotkanal der Karte
uniform float specular = 0.0;
uniform float roughness = 1.0;
uniform sampler2D roughness_tex : filter_nearest, repeat_enable, hint_default_white;
uniform bool use_roughness = false;
uniform float roughness_scale = 1.0;
// Spiegelanteil: Godots Bildschirmspiegelung (SSR) nimmt für Nichtmetalle fest 4 % Reflexion an – Metallic hebt
// sie an (und nimmt dafür etwas Grundfarbe weg). 0 = gewöhnlicher Stein
uniform float metallic = 0.0;
// Einstellungen → Bild → Spiegelungen (1 = an): ohne SSR machte Metallic den Boden nur dunkler
global uniform float reflections;
// Kacheln pro Meter
uniform float tex_scale = 1.0;

varying vec3 world_pos;
varying vec3 world_normal;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
	vec4 clip = PROJECTION_MATRIX * (MODELVIEW_MATRIX * vec4(VERTEX, 1.0));
	clip = psx_snap_clip(clip);
	POSITION = clip;
}

void fragment() {
	// Wie psx_surface: u entlang Welt +z bzw. +x, v nach unten (Bild steht aufrecht); „oben“ im Bild = Welt +y,
	// auf Böden und Decken Welt +z
	vec3 n = abs(world_normal);
	vec2 uv;
	vec3 u_axis;
	vec3 up_axis;
	if (n.x > n.y && n.x > n.z) {
		uv = world_pos.zy;
		u_axis = vec3(0.0, 0.0, 1.0);
		up_axis = vec3(0.0, 1.0, 0.0);
	} else if (n.y > n.z) {
		uv = world_pos.xz;
		u_axis = vec3(1.0, 0.0, 0.0);
		up_axis = vec3(0.0, 0.0, 1.0);
	} else {
		uv = world_pos.xy;
		u_axis = vec3(1.0, 0.0, 0.0);
		up_axis = vec3(0.0, 1.0, 0.0);
	}
	uv = vec2(uv.x, -uv.y) * tex_scale;
	ALBEDO = albedo.rgb * texture(albedo_tex, uv).rgb;
	if (use_normal) {
		vec3 t = texture(normal_tex, uv).rgb * 2.0 - 1.0;
		vec3 wn = normalize(normalize(world_normal) * t.z + (u_axis * t.x + up_axis * t.y) * normal_strength);
		NORMAL = normalize((VIEW_MATRIX * vec4(wn, 0.0)).xyz);
	}
	ROUGHNESS = (use_roughness ? texture(roughness_tex, uv).r : roughness) * roughness_scale;
	METALLIC = metallic * reflections;
	SPECULAR = specular;
}
