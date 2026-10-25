class_name IconArt
## Gezeichnete Symbole (64 × 64 Pixel, assets/textures/icons/Icon_<name>.png): Aktions-Symbole über dem
## Interaktions-Hinweis (Hud.set_prompt, get_icon der Interaktionsobjekte), der Totenkopf bei Todesmeldungen und
## Leichen, die Porträts der drei Bedrohungen auf dem Sterbebildschirm und im Notizbuch (Spielkonzept 3.10, 4.20).
## Kleiner als 64 werden sie einmal sauber heruntergerechnet (Lanczos) und je Größe zwischengespeichert – bei
## 480 × 270 würde Nearest-Verkleinern die Striche zerreißen.

const DIR := "res://assets/textures/icons/Icon_%s.png"
const SIZE := 64
## Die drei Bedrohungen (Spielkonzept 4.20): Porträt und Name – Schlüssel wie Player.killed_by und Notebook.seen
const THREATS := {
	"monster": {"icon": "themonster", "name": "Das Monster"},
	"ghost": {"icon": "sheetghost", "name": "Der Lakengeist"},
	"pumpkin": {"icon": "pumpkinhead", "name": "Der Kürbismann"},
}
const THREAT_ORDER := ["monster", "ghost", "pumpkin"]

static var _cache := {}


## Symbol `name` (ohne „Icon_“) in `size` Pixeln Kantenlänge; null, wenn es die Datei nicht gibt.
static func texture(name: String, size: int = SIZE) -> Texture2D:
	var key := "%s|%d" % [name, size]
	if _cache.has(key):
		return _cache[key]
	var path := DIR % name
	if name == "" or not ResourceLoader.exists(path):
		return null
	var tex: Texture2D = load(path)
	if size != SIZE:
		var img := tex.get_image()
		if img == null:
			return tex
		img = img.duplicate()
		img.decompress()
		img.convert(Image.FORMAT_RGBA8)
		img.resize(size, size, Image.INTERPOLATE_LANCZOS)
		tex = ImageTexture.create_from_image(img)
	_cache[key] = tex
	return tex


## Aktions-Symbol eines Getränks: Kaffee, Tee (eigenes Icon_tea.png, sobald es das gibt – bis dahin die Tasse vom
## Kaffee).
static func drink_icon(kind: int) -> String:
	if kind == Item.Kind.TEA:
		return "tea" if ResourceLoader.exists(DIR % "tea") else "coffee"
	return "coffee" if kind == Item.Kind.COFFEE else ""


## Porträt einer Bedrohung („monster“, „ghost“, „pumpkin“).
static func threat(id: String, size: int = SIZE) -> Texture2D:
	return texture(String(THREATS[id]["icon"]), size) if THREATS.has(id) else null


static func threat_name(id: String) -> String:
	return String(THREATS[id]["name"]) if THREATS.has(id) else ""
