// Modelle mit allen Karten (Kürbisse, PumpkinModel): wie psx_surface mit der Farbtextur der GLB (Mesh-UVs,
// dazu die Normal Map (Tangenten aus der GLB), Glanz mit der
// Rauheit aus der Karte und eine Glutmaske: Emission nur, wo die Maske hell ist (Fruchtfleisch mit Kerze).
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_lambert, specular_schlick_ggx;

uniform vec4 albedo : source_color = vec4(1.0);
uniform sampler2D albedo_tex : source_color, filter_linear_mipmap, hint_default_white;
// Normal Map im OpenGL-Format (glTF)
uniform sampler2D normal_tex : hint_normal, filter_linear_mipmap;
uniform bool use_normal = false;
// glTF-Karte: Rauheit im Grünkanal
uniform sampler2D roughness_tex : filter_linear_mipmap, hint_default_white;
uniform float specular = 0.5;
uniform sampler2D glow_tex : source_color, filter_linear_mipmap, hint_default_black;
uniform vec3 emission : source_color = vec3(0.0);
uniform float emission_energy = 0.0;

void vertex() {
	vec4 clip = PROJECTION_MATRIX * (MODELVIEW_MATRIX * vec4(VERTEX, 1.0));
	POSITION = clip;
}

void fragment() {
	ALBEDO = albedo.rgb * texture(albedo_tex, UV).rgb;
	if (use_normal) {
		NORMAL_MAP = texture(normal_tex, UV).rgb;
	}
	ROUGHNESS = texture(roughness_tex, UV).g;
	SPECULAR = specular;
	EMISSION = emission * emission_energy * texture(glow_tex, UV).r;
}
