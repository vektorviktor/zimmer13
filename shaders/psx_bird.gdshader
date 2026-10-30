// Krähen und Nachtfalter (Spielkonzept 4.25, scripts/world/crows.gd, scripts/world/moths.gd): ein MultiMesh, je Instanz
// schlagen die Flügel um die Schulter (|x| = shoulder) wie bei den Fledermäusen (psx_bat). INSTANCE_CUSTOM.x = Phase des
// Flügelschlags (rechnet das Skript, steht in der Pause), .y = angelegt (0 fliegt, 1 sitzt mit angelegten Flügeln),
// .z = Kopf nicken (Picken, −1 … 1). Eckfarbe r = Anteil Kopf (nickt um den Hals, z = neck_z), g = Glanz.
// Gefieder schwarz mit bläulichem Glanz, Falter matt, beidseitig.
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_disabled, diffuse_lambert;

uniform vec4 albedo : source_color = vec4(0.03, 0.03, 0.035, 1.0);
uniform vec4 sheen : source_color = vec4(0.25, 0.3, 0.45, 1.0);
uniform float shoulder = 0.03;
uniform float flap_amp = 0.9;
uniform float flap_lift = 0.1;
uniform float fold_angle = -0.15;
uniform float fold_reach = 0.55;
uniform float neck_z = -0.06;
uniform float peck = 0.7;
uniform float roughness_base = 0.45;

varying float v_gloss;

void vertex() {
	float side = sign(VERTEX.x);
	float r = abs(VERTEX.x) - shoulder;
	if (r > 0.0 && COLOR.r < 0.5) {
		float fold = INSTANCE_CUSTOM.y;
		float flap = sin(INSTANCE_CUSTOM.x) * flap_amp + flap_lift;
		float a = mix(flap, fold_angle, fold);
		float reach = r * mix(1.0, fold_reach, fold);
		VERTEX.x = side * (shoulder + reach * cos(a));
		VERTEX.y += reach * sin(a);
		NORMAL = normalize(vec3(-side * sin(a), cos(a), 0.0));
	}
	if (COLOR.r > 0.5) {   // Kopf nickt um den Hals nach vorn unten
		float a = INSTANCE_CUSTOM.z * peck;
		vec2 p = vec2(VERTEX.y, VERTEX.z - neck_z);
		float c = cos(a);
		float s = sin(a);
		p = vec2(p.x * c - p.y * s, p.x * s + p.y * c);
		VERTEX.y = p.x;
		VERTEX.z = p.y + neck_z;
	}
	v_gloss = COLOR.g;
	POSITION = PROJECTION_MATRIX * (MODELVIEW_MATRIX * vec4(VERTEX, 1.0));
}

void fragment() {
	ALBEDO = albedo.rgb;
	ROUGHNESS = mix(roughness_base, 0.25, v_gloss);
	SPECULAR = mix(0.2, 0.6, v_gloss);
	// bläulicher Schimmer am Rand, wie bei Krähenfedern
	float rim = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.0);
	EMISSION = sheen.rgb * rim * v_gloss * 0.04;
}
