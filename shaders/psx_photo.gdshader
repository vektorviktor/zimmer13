// Fototexturen (Mat.photo): wie psx_surface mit Textur in Weltkoordinaten, dazu
// eine Normal Map und auf Wunsch Glanz (specular > 0, Rauheit aus einer Karte – polierte Fliesen). Matt
// (specular 0) sieht es aus wie psx_surface: Godot rechnet mit F0 = 0 keinen Glanz, auch nicht am Rand. Die Projektion folgt der Hauptachse der Flächennormale; die Achse, in
// die u bzw. das Bild-„oben“ zeigt, ist dort fest – daraus entsteht die Normale ohne Tangenten im Mesh.
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_lambert, specular_schlick_ggx;
#include "res://shaders/wet_ground.gdshaderinc"

uniform vec4 albedo : source_color = vec4(1.0);
uniform sampler2D albedo_tex : source_color, filter_linear_mipmap, repeat_enable, hint_default_white;
// Normal Map im OpenGL-Format (Y nach oben; DirectX-Karten dreht tools/photo_set.gd mit --dx)
uniform sampler2D normal_tex : hint_normal, filter_linear_mipmap, repeat_enable;
uniform bool use_normal = false;
uniform float normal_strength = 1.0;
// Normal Map so oft je Farbkachel (feine Poren, tools/pore_map.gd); cavity > 0: wo die Normale kippt (Porenwand),
// dunkler und rauer – Schmutz in den Vertiefungen
uniform float normal_tiling = 1.0;
uniform float cavity = 0.0;
// Glanz: Stärke (0 = matt, 0,5 = übliches Nichtmetall) und Rauheit – fest oder aus dem Rotkanal der Karte
uniform float specular = 0.0;
uniform float roughness = 1.0;
uniform sampler2D roughness_tex : filter_linear_mipmap, repeat_enable, hint_default_white;
uniform bool use_roughness = false;
uniform float roughness_scale = 1.0;
// Spiegelanteil: Godots Bildschirmspiegelung (SSR) nimmt für Nichtmetalle fest 4 % Reflexion an – Metallic hebt
// sie an (und nimmt dafür etwas Grundfarbe weg). 0 = gewöhnlicher Stein
uniform float metallic = 0.0;
// Einstellungen → Bild → Spiegelungen (1 = an): ohne SSR machte Metallic den Boden nur dunkler
global uniform float reflections;
// Kacheln pro Meter
uniform float tex_scale = 1.0;
// Textur in Modellkoordinaten statt in Weltkoordinaten – für Bewegtes (Aufzugskabine): sonst wanderte das Bild
// über die Wand, während sie fährt
uniform bool object_uv = false;
// Textur über die UVs des Meshs (in Metern, × tex_scale) statt projiziert – für Holz mit Faserrichtung
// (Geo.grain_box): Tangente und Bild-„oben“ der Normal Map kommen aus den Ableitungen auf dem Bildschirm
uniform bool mesh_uv = false;
// Gebackene Verschattung über den zweiten UV-Satz (Vertäfelung, tools/build_wainscot.py): multipliziert die
// Grundfarbe, wirkt also auch im Lampenlicht (Godots AO wirkt nur aufs Umgebungslicht, das im Hotel fast null ist)
uniform sampler2D ao_tex : hint_default_white, filter_linear, repeat_disable;
uniform bool use_ao = false;
// Gebackene Normale über UV2 im Objektraum (Möbel, tools/furniture_kit.py): ersetzt die Normale des Meshs, darin
// gemalt sind Formen, die nicht modelliert sind (Furchen, Lamellen). Die Holz-Normal-Map wirkt darauf weiter.
uniform sampler2D detail_tex : filter_linear_mipmap, repeat_disable;
uniform bool use_detail = false;
// Je Instanz eines MultiMesh (mesh_uv, Vertäfelung, Wainscot._put): Leisten und Brett laufen über das Wandstück
// durch – u = UV.x × INSTANCE_CUSTOM.z (Streckung, negativ bei rückwärts gesetzten Teilen) + x (Lage des Modulanfangs
// an der Wand), v + y (Versatz je Wandstück), alles in Metern; die Füllung (UV.y > FILL_V / 2, tools/build_wainscot.py)
// bekommt aus w je Feld einen eigenen Ausschnitt
uniform bool instance_shift = false;
const float FILL_V = 50.0;

varying vec3 world_pos;
varying vec3 world_normal;
varying vec3 tex_pos;
varying vec3 tex_normal;
varying vec4 uv_shift;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
	tex_pos = object_uv ? VERTEX : world_pos;
	tex_normal = object_uv ? NORMAL : world_normal;
	uv_shift = instance_shift ? INSTANCE_CUSTOM : vec4(0.0, 0.0, 1.0, 0.0);
	vec4 clip = PROJECTION_MATRIX * (MODELVIEW_MATRIX * vec4(VERTEX, 1.0));
	POSITION = clip;
}

void fragment() {
	// Wie psx_surface: u entlang Welt +z bzw. +x, v nach unten (Bild steht aufrecht); „oben“ im Bild = Welt +y,
	// auf Böden und Decken Welt +z
	vec3 n = abs(tex_normal);
	vec2 uv;
	vec3 u_axis;
	vec3 up_axis;
	if (n.x > n.y && n.x > n.z) {
		uv = tex_pos.zy;
		u_axis = vec3(0.0, 0.0, 1.0);
		up_axis = vec3(0.0, 1.0, 0.0);
	} else if (n.y > n.z) {
		uv = tex_pos.xz;
		u_axis = vec3(1.0, 0.0, 0.0);
		up_axis = vec3(0.0, 0.0, 1.0);
	} else {
		uv = tex_pos.xy;
		u_axis = vec3(1.0, 0.0, 0.0);
		up_axis = vec3(0.0, 1.0, 0.0);
	}
	uv = vec2(uv.x, -uv.y) * tex_scale;
	vec3 base_n = normalize(world_normal);
	if (use_detail) {
		base_n = normalize((MODEL_MATRIX * vec4(texture(detail_tex, UV2).rgb * 2.0 - 1.0, 0.0)).xyz);
		NORMAL = normalize((VIEW_MATRIX * vec4(base_n, 0.0)).xyz);
	}
	if (mesh_uv) {
		// ohne Verzweigung – die Ableitungen unten brauchen gleichmäßigen Kontrollfluss
		float fill = instance_shift ? step(FILL_V / 2.0, UV.y) : 0.0;
		vec2 run = vec2(UV.x * uv_shift.z + uv_shift.x, UV.y + uv_shift.y);
		vec2 own = vec2(UV.x, UV.y - FILL_V) + vec2(uv_shift.w, fract(uv_shift.w * 7.13) * 7.0);
		uv = mix(run, own, fill) * tex_scale;
		vec3 n_w = base_n;
		vec3 dp1 = dFdx(world_pos);
		vec3 dp2 = dFdy(world_pos);
		vec2 duv1 = dFdx(uv);
		vec2 duv2 = dFdy(uv);
		vec3 dp2perp = cross(dp2, n_w);
		vec3 dp1perp = cross(n_w, dp1);
		vec3 t = dp2perp * duv1.x + dp1perp * duv2.x;
		vec3 b = dp2perp * duv1.y + dp1perp * duv2.y;
		float inv = inversesqrt(max(max(dot(t, t), dot(b, b)), 1e-12));
		u_axis = t * inv;
		up_axis = -b * inv;   // v wächst im Bild nach unten
	} else if (object_uv) {
		u_axis = normalize((MODEL_MATRIX * vec4(u_axis, 0.0)).xyz);
		up_axis = normalize((MODEL_MATRIX * vec4(up_axis, 0.0)).xyz);
	}
	ALBEDO = albedo.rgb * texture(albedo_tex, uv).rgb;
	if (use_ao) {
		ALBEDO *= texture(ao_tex, UV2).r;
	}
	float pit = 0.0;
	if (use_normal) {
		vec3 t = texture(normal_tex, uv * normal_tiling).rgb * 2.0 - 1.0;
		vec3 wn = normalize(base_n * t.z + (u_axis * t.x + up_axis * t.y) * normal_strength);
		NORMAL = normalize((VIEW_MATRIX * vec4(wn, 0.0)).xyz);
		pit = cavity * clamp((1.0 - t.z) * 5.0, 0.0, 1.0);
	}
	ALBEDO *= 1.0 - 0.35 * pit;
	Wet w = wet_surface(ALBEDO, mix((use_roughness ? texture(roughness_tex, uv).r : roughness) * roughness_scale, 1.0, pit),
			metallic * reflections, specular, reflections);
	ALBEDO = w.albedo;
	ROUGHNESS = w.roughness;
	METALLIC = w.metallic;
	SPECULAR = w.specular;
}
