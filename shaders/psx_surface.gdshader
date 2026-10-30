// Grundshader für 3D-Oberflächen (Mat.psx): Textur mit Mipmaps, kein Glanz. Optional Textur in Weltkoordinaten (für Wände/Böden). Böden draußen werden im Regen
// nass und glänzen (wet_ground.gdshaderinc) – mit Glanz rechnet nur ihre Abwandlung (Mat.wettable), sonst ohne.
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_lambert, specular_disabled;
#include "res://shaders/wet_ground.gdshaderinc"

uniform vec4 albedo : source_color = vec4(1.0);
uniform sampler2D albedo_tex : source_color, filter_linear_mipmap, repeat_enable, hint_default_white;
uniform bool use_world_uv = false;
uniform float tex_scale = 1.0;
uniform vec3 emission : source_color = vec3(0.0);
uniform float emission_energy = 0.0;
// Auflagen (Teppich, Türkassetten): rückt die Fläche um diesen Anteil der Entfernung zur Kamera
// hin. Ändert nur die Tiefe, nicht die Bildposition – so kann die Unterlage nicht durch die Auflage
// flimmern.
uniform float layer_pull = 0.0;
// Helligkeit aus den Eckfarben des Meshs (z. B. Hecken: unten im Schatten dunkler)
uniform bool use_vertex_color = false;
// Einstellungen → Bild → Spiegelungen (1 = an)
global uniform float reflections;

varying vec3 world_pos;
varying vec3 world_normal;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
	vec4 view = MODELVIEW_MATRIX * vec4(VERTEX, 1.0);
	view.xyz *= 1.0 - layer_pull;
	vec4 clip = PROJECTION_MATRIX * view;
	POSITION = clip;
}

void fragment() {
	vec2 uv = UV;
	if (use_world_uv) {
		vec3 n = abs(world_normal);
		if (n.x > n.y && n.x > n.z) {
			uv = world_pos.zy;
		} else if (n.y > n.z) {
			uv = world_pos.xz;
		} else {
			uv = world_pos.xy;
		}
		uv = vec2(uv.x, -uv.y) * tex_scale;
	}
	vec4 tex = texture(albedo_tex, uv);
	ALBEDO = albedo.rgb * tex.rgb;
	if (use_vertex_color) {
		ALBEDO *= COLOR.rgb;
	}
	Wet w = wet_surface(ALBEDO, 1.0, 0.0, 0.0, reflections);
	ALBEDO = w.albedo;
	ROUGHNESS = w.roughness;
	METALLIC = w.metallic;
	SPECULAR = w.specular;
	EMISSION = emission * emission_energy;
}
