// PS1-Look für 3D-Oberflächen: Vertex-Snapping (wackelnde Polygone),
// Nearest-Filter, kein Glanz. Optional Textur in Weltkoordinaten (für Wände/Böden).
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_lambert, specular_disabled;

uniform vec4 albedo : source_color = vec4(1.0);
uniform sampler2D albedo_tex : source_color, filter_nearest, repeat_enable, hint_default_white;
uniform bool use_world_uv = false;
uniform float tex_scale = 1.0;
uniform vec3 emission : source_color = vec3(0.0);
uniform float emission_energy = 0.0;
uniform float snap_resolution = 140.0;
// Einstellungen → PS1-Look → Vertex-Wackeln (1 = an, 0 = aus)
global uniform float psx_snap;

varying vec3 world_pos;
varying vec3 world_normal;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
	vec4 clip = PROJECTION_MATRIX * (MODELVIEW_MATRIX * vec4(VERTEX, 1.0));
	if (psx_snap > 0.5 && clip.w > 0.0001) {
		vec2 ndc = clip.xy / clip.w;
		ndc = floor(ndc * snap_resolution + 0.5) / snap_resolution;
		clip.xy = ndc * clip.w;
	}
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
	ROUGHNESS = 1.0;
	SPECULAR = 0.0;
	EMISSION = emission * emission_energy;
}
