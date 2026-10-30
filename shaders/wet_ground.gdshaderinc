// Nasser Boden draußen im Regen (Weather, Spielkonzept 7.8) – für psx_surface und psx_photo, nur mit wettable:
// dunkler und glänzend (Glanz über Metallic, sonst sähe die Bildschirmspiegelung nichts), beim
// Blutregen ein roter Film mit rotem Glanz. Nass wie die Scheiben (rain_wet), rot, solange der letzte Schauer
// Blutregen war (rain_blood, blendet weich) – trocknet mit ab; was bleibt, sind die Pfützen (Weather).
global uniform float rain_wet;
global uniform float rain_blood;
uniform bool wettable = false;
// so glatt wird die Fläche ganz nass (1 = Pflaster mit Wasserfilm, Rasen weniger)
uniform float wet_gloss = 1.0;
uniform vec3 wet_blood : source_color = vec3(0.533, 0.031, 0.031);   // #880808 – roter Film
uniform vec3 wet_sheen : source_color = vec3(1.0, 0.133, 0.133);     // #ff2222 – sein Glanz

struct Wet {
	vec3 albedo;
	float roughness;
	float metallic;
	float specular;
};

// reflections: Einstellung Spiegelungen (1 = an) – ohne SSR machte Metallic die Fläche nur dunkler
Wet wet_surface(vec3 albedo, float roughness, float metallic, float specular, float reflections) {
	Wet w = Wet(albedo, roughness, metallic, specular);
	float wet = wettable ? rain_wet : 0.0;
	if (wet < 0.002) {
		return w;
	}
	// rot: auf glattem Stein steht der Film, in Rasen und Kies versickert mehr – nur ein Hauch (voll war zu rot)
	float blood = wet * rain_blood * mix(0.04, 0.085, wet_gloss);
	float luma = dot(albedo, vec3(0.3, 0.59, 0.11));
	// nass: dunkler (Poren voll Wasser)
	w.albedo = albedo * mix(1.0, 0.55, wet);
	// roter Film: die Struktur darunter schimmert durch
	vec3 film = wet_blood * (0.35 + luma);
	float gloss = wet * wet_gloss;
	w.roughness = mix(roughness, 0.1, gloss);
	w.specular = mix(specular, 0.5, gloss);
	float shine = gloss * 0.3 * reflections;
	w.metallic = mix(metallic, 1.0, shine);
	// rot: Glanz in Glanzfarbe, die Grundfarbe bleibt dabei (bei Metallic) etwa der Film
	float red_shine = 0.7 * wet_gloss * reflections;
	vec3 red = mix(film, wet_sheen * (0.35 + luma), red_shine);
	w.albedo = mix(w.albedo, red, blood);
	w.metallic = mix(w.metallic, red_shine, blood);
	return w;
}
