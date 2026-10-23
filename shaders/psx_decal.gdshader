// PS1-Look für flache Auflagen mit Umriss aus dem Alpha der Textur (Blut, Wachs, Kürbismatsch – TraceMark.lay_decal):
// wie psx_surface (Vertex-Snapping, Nearest-Filter), leicht zur Kamera gezogen wie Mat.layer, damit der Boden beim
// Snapping nicht durchflimmert. `fade` blendet stufenlos aus (echte Transparenz statt Raster: Das Verblassen soll
// kaum merkbar sein).
// Mit den Karten aus tools/splat_maps.gd (Mat.decal lädt sie, TraceMark.splat_look stellt den Look ein): Glanz
// (`specular`, Rauheit aus der Detailkarte), am dünnen Rand durchsichtig und heller, in der dicken Mitte satt und
// dunkler, leichtes Rauschen auf der Farbe – und ohne PS1-Look eine Normal Map (wie psx_photo).
// Überlappende Flecken verschmelzen: Die Tiefe wird nach der Dicke geschrieben (`thick_lift`, die dicke Mitte liegt ein
// Stück näher an der Kamera als der dünne Rand) – so gewinnt an jedem Pixel der dickste Fleck, egal in welcher
// Reihenfolge sie gezeichnet werden, und kein Rand liegt über der Mitte eines Nachbarn.
shader_type spatial;
render_mode blend_mix, depth_draw_always, cull_back, diffuse_lambert, specular_schlick_ggx;
#include "res://shaders/psx_snap.gdshaderinc"

uniform vec4 albedo : source_color = vec4(1.0);
uniform sampler2D albedo_tex : source_color, filter_nearest, repeat_disable, hint_default_white;
// 1 = frisch, 0 = verschwunden
uniform float fade = 1.0;
uniform float layer_pull = 0.004;
// Normal Map (OpenGL, Y nach oben) – nur ohne PS1-Look
uniform sampler2D normal_tex : hint_normal, filter_nearest, repeat_disable;
uniform bool use_normal = false;
uniform float normal_strength = 1.0;
// Detailkarte: R = Rauheit, G = Dicke (0 am Rand, 1 innen), B = Rauschen
uniform sampler2D detail_tex : filter_nearest, repeat_disable, hint_default_white;
uniform bool use_detail = false;
// Glanz: 0 = matt, 0,5 = übliches Nichtmetall; Rauheit ohne Detailkarte
uniform float specular = 0.0;
uniform float roughness = 1.0;
// Deckkraft am dünnen Rand (innen 1) und Farbe in der dicken Mitte (× diesen Wert, am Rand × 1)
uniform float edge_alpha = 1.0;
uniform float thick_shade = 1.0;
// Rauschen auf der Farbe: ± die Hälfte dieses Anteils
uniform float grain = 0.0;
// So viel (Anteil der Kameraentfernung) rückt die dicke Mitte für den Tiefentest vor den dünnen Rand
uniform float thick_lift = 0.002;
// Einstellungen → PS1-Look aus = 1 (Settings)
global uniform float psx_smooth;

void vertex() {
	vec4 view = MODELVIEW_MATRIX * vec4(VERTEX, 1.0);
	view.xyz *= 1.0 - layer_pull;
	vec4 clip = PROJECTION_MATRIX * view;
	clip = psx_snap_clip(clip);
	POSITION = clip;
}

void fragment() {
	vec4 tex = texture(albedo_tex, UV);
	if (tex.a < 0.5) {
		discard;
	}
	vec3 detail = use_detail ? texture(detail_tex, UV).rgb : vec3(roughness, 1.0, 0.5);
	ALBEDO = albedo.rgb * tex.rgb * mix(1.0, thick_shade, detail.g) * (1.0 + (detail.b - 0.5) * grain);
	ALPHA = fade * mix(edge_alpha, 1.0, detail.g);
	ROUGHNESS = detail.r;
	SPECULAR = specular;
	vec4 lifted = PROJECTION_MATRIX * vec4(VERTEX * (1.0 - layer_pull - thick_lift * detail.g), 1.0);
	DEPTH = lifted.z / lifted.w;
	if (use_normal && psx_smooth > 0.5) {
		NORMAL_MAP = texture(normal_tex, UV).rgb;
		NORMAL_MAP_DEPTH = normal_strength;
	}
}
