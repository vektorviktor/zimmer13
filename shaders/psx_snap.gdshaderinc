// PS1-Wackeln: Eckpunkte im Bildraum auf ein grobes Raster runden – für alle psx_*-Shader gleich
// (Einstellungen → PS1-Look → Vertex-Wackeln setzt psx_snap: 1 = an, 0 = aus)
const float SNAP_RESOLUTION = 140.0;
global uniform float psx_snap;

vec4 psx_snap_clip(vec4 clip) {
	if (psx_snap > 0.5 && clip.w > 0.0001) {
		vec2 ndc = clip.xy / clip.w;
		ndc = floor(ndc * SNAP_RESOLUTION + 0.5) / SNAP_RESOLUTION;
		clip.xy = ndc * clip.w;
	}
	return clip;
}
