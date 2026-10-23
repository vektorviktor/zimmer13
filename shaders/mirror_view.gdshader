// Spiegel im Aufzug (Elevator._mirror_wall): zeigt das Bild der Spiegelkamera (SubViewport) unbeleuchtet – Licht und
// Nebel hat die Kamera schon gerechnet, ohne Tonemapping (das kommt hier im Hauptbild). Die Kamera schaut von hinten
// durch die Spiegelfläche, ihr Bild ist darum seitenverkehrt zur Fläche: u wird gespiegelt. Grob gefiltert wie alles.
shader_type spatial;
render_mode unshaded, cull_back, shadows_disabled;

uniform sampler2D view : source_color, filter_nearest;
// leicht grünliches, etwas dunkleres Glas
uniform vec3 tint : source_color = vec3(0.86, 0.9, 0.88);

void fragment() {
	ALBEDO = texture(view, vec2(1.0 - UV.x, UV.y)).rgb * tint;
}
