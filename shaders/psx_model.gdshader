// Modelle mit allen Karten (Kürbisse, PumpkinModel): wie psx_surface mit der Farbtextur der GLB (Mesh-UVs,
// Vertex-Snapping), dazu ohne PS1-Look die Normal Map (Tangenten aus der GLB), in beiden Looks Glanz mit der
// Rauheit aus der Karte und eine Glutmaske: Emission nur, wo die Maske hell ist (Fruchtfleisch mit Kerze).
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_lambert, specular_schlick_ggx;
#include "res://shaders/psx_snap.gdshaderinc"

uniform vec4 albedo : source_color = vec4(1.0);
uniform sampler2D albedo_tex : source_color, filter_nearest, hint_default_white;
// Normal Map im OpenGL-Format (glTF), nur ohne PS1-Look (psx_smooth)
uniform sampler2D normal_tex : hint_normal, filter_nearest;
uniform bool use_normal = false;
// glTF-Karte: Rauheit im Grünkanal
uniform sampler2D roughness_tex : filter_nearest, hint_default_white;
uniform float specular = 0.5;
uniform sampler2D glow_tex : source_color, filter_nearest, hint_default_black;
uniform vec3 emission : source_color = vec3(0.0);
uniform float emission_energy = 0.0;
// Einstellungen → PS1-Look aus (1) – wie bei der Tapete (psx_wall)
global uniform float psx_smooth;

void vertex() {
	vec4 clip = PROJECTION_MATRIX * (MODELVIEW_MATRIX * vec4(VERTEX, 1.0));
	clip = psx_snap_clip(clip);
	POSITION = clip;
}

void fragment() {
	ALBEDO = albedo.rgb * texture(albedo_tex, UV).rgb;
	if (use_normal && psx_smooth > 0.5) {
		NORMAL_MAP = texture(normal_tex, UV).rgb;
	}
	ROUGHNESS = texture(roughness_tex, UV).g;
	SPECULAR = specular;
	EMISSION = emission * emission_energy * texture(glow_tex, UV).r;
}
