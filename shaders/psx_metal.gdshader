// Poliertes Metall (Edelstahl, Chrom) für schmale Teile wie die Pool-Handläufe: Das Hotel hat keine
// Umgebungsspiegelung (Environment ohne Reflexionen, SSR taugt für dünne Rohre nicht), darum spiegelt die Fläche
// einen gedachten Raum – dunkler Boden, heller Streifen am Horizont, mittlere Decke, wie beim klassischen
// Chrom-Look –, und zwar nur so hell, wie jede Lampe ihn beleuchtet; dazu ein scharfer Glanzpunkt, wo die Lampe
// selbst im Metall steht. Ohne Licht bleibt das Metall dunkel. Wie psx_mirror (Discokugel), nur ohne Textur.
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back;

// Farbe des Metalls: Edelstahl leicht kühl, Chrom fast weiß
uniform vec3 tint : source_color = vec3(0.78, 0.8, 0.84);
// Anteil der matten Beleuchtung (Schmutz, Schliff) – reines Spiegeln wirkt auf 1–2 Pixel Breite unruhig
uniform float matte = 0.15;
// gedachter Raum in Spiegelrichtung: Boden, Decke, Horizontstreifen (Helligkeit, Breite) und die dunkle Kante
// knapp darunter
uniform float ground = 0.1;
uniform float sky = 0.45;
uniform float horizon = 1.3;
uniform float horizon_width = 0.16;
uniform float horizon_dark = 0.35;
// Glanzpunkt der Lampe: Schärfe (Exponent) und Stärke
uniform float glint_power = 120.0;
uniform float glint_energy = 5.0;
uniform float snap_resolution = 140.0;
global uniform float psx_snap;

void vertex() {
	vec4 clip = PROJECTION_MATRIX * (MODELVIEW_MATRIX * vec4(VERTEX, 1.0));
	if (psx_snap > 0.5 && clip.w > 0.0001) {
		vec2 ndc = clip.xy / clip.w;
		ndc = floor(ndc * snap_resolution + 0.5) / snap_resolution;
		clip.xy = ndc * clip.w;
	}
	POSITION = clip;
}

void fragment() {
	ALBEDO = tint;
	ROUGHNESS = 1.0;
	SPECULAR = 0.0;
}

// Helligkeit des gedachten Raums in Weltrichtung d
float room(vec3 d) {
	float y = d.y;
	float r = mix(ground, sky, smoothstep(-0.25, 0.6, y));
	r += horizon * exp(-(y * y) / (horizon_width * horizon_width));
	r -= horizon_dark * exp(-pow((y + 0.2) / horizon_width, 2.0));
	return max(r, 0.0);
}

void light() {
	vec3 lit = ATTENUATION * LIGHT_COLOR / PI;
	float ndl = dot(NORMAL, LIGHT);
	DIFFUSE_LIGHT += matte * max(ndl, 0.0) * lit;
	// Spiegelbild: auf der lampenabgewandten Seite schwächer (der gespiegelte Raum liegt dort im Schatten)
	vec3 r = reflect(-VIEW, NORMAL);
	vec3 rw = (INV_VIEW_MATRIX * vec4(r, 0.0)).xyz;
	DIFFUSE_LIGHT += room(rw) * mix(0.3, 1.0, smoothstep(-0.5, 0.5, ndl)) * lit;
	// Die Lampe selbst im Metall, in dessen Farbe
	SPECULAR_LIGHT += pow(max(dot(r, LIGHT), 0.0), glint_power) * glint_energy * tint * lit;
}
