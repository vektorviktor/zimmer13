// Lakengeist (Spielkonzept 4.18): wie psx_surface (Vertex-Snapping, Nearest-Filter, kein Glanz), aber
// beidseitig und mit Ausblenden. Statt echter Transparenz fallen Pixel nach einem 4×4-Raster weg
// („Screen-Door“, wie auf der PlayStation) – so bleibt der Geist im undurchsichtigen Durchgang.
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_disabled, diffuse_lambert, specular_disabled;
#include "res://shaders/psx_snap.gdshaderinc"

uniform vec4 albedo : source_color = vec4(1.0);
uniform sampler2D albedo_tex : source_color, filter_nearest, hint_default_white;
// 1 = ganz da, 0 = verschwunden
uniform float fade = 1.0;
// schwaches Eigenleuchten, damit er im Dunkeln vor dem Fenster zu sehen ist
uniform float glow = 0.06;

void vertex() {
	vec4 clip = PROJECTION_MATRIX * (MODELVIEW_MATRIX * vec4(VERTEX, 1.0));
	clip = psx_snap_clip(clip);
	POSITION = clip;
}

const float BAYER[16] = float[](0.0, 8.0, 2.0, 10.0, 12.0, 4.0, 14.0, 6.0, 3.0, 11.0, 1.0, 9.0, 15.0, 7.0, 13.0, 5.0);

void fragment() {
	ivec2 p = ivec2(FRAGCOORD.xy) % 4;
	if (fade < 1.0 && (BAYER[p.y * 4 + p.x] + 0.5) / 16.0 > fade) {
		discard;
	}
	vec3 tex = texture(albedo_tex, UV).rgb * albedo.rgb;
	ALBEDO = tex;
	ROUGHNESS = 1.0;
	SPECULAR = 0.0;
	EMISSION = tex * glow;
}
