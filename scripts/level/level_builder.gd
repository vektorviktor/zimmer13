class_name LevelBuilder
extends RefCounted
## Baut das Hotel aus dem Gebäudeplan (Spielkonzept 7.5): `assets/maps/eg.json`, `og1.json` und `ug.json`, erzeugt von
## `tools/build_map.py` aus `map.aseprite`. 1 Einheit = 1 m, x nach Osten, z nach Süden (Norden = −Z),
## Ursprung = Mitte des Haupteingangs auf der Südwand.
##
##   Erdgeschoss (y 0): Lobby mit Luftraum und Galerie (Treppe hinauf), Bar + Spiele, Partyraum über zwei
##   Stockwerke, Toiletten · Ostflügel 0101–0181 · Westflügel 0201–0272 (Bauphase: Zimmer verschlossen, Flure
##   begehbar) · Küchenblock im Westflügel · Mittelgarten und vier Innenhöfe · Pool im Norden · Treppenhaus
##   Ost vom Untergeschoss bis ins Obergeschoss, Treppenhaus West gesperrt.
##   Obergeschoss (y 4, Spielkonzept 7.7): derselbe Bau in einem zweiten Durchgang (_upper_floor) unter dem
##   Knoten „Obergeschoss“ – Zimmer 11xx/12xx mit Bädern und Balkonen, Katzenraum, Bibliothek, Galerien um
##   die Lufträume von Lobby und Partyraum.
##   Untergeschoss (y −4, Spielkonzept 7.9): derselbe Bau unter dem Knoten „Untergeschoss“ (_lower_floor) – graue
##   Gänge mit Halogenleuchten, Heizkeller (Versteck des Monsters), Technikraum, Wäscherei, verschlossene Räume.
##
## Kollisionsebenen: 1 statisch/NavMesh · 2 Türen · 3 Gegenstände · 4 Spieler · 5 Decke
##                   · 6 Monster · 7 Glas · 8 Gäste · 9 Milchglas · 10 zugezogene Vorhänge
##
## Einrichtung (Spielkonzept 7.5): Möbel, Ausstattung, Gegenstände und Lichter stehen im Plan (Objektebenen).
## Was der Plan nicht kennt – Höhen, Helligkeit je Raumart, Zettel-Nummern, Münzbeträge, UV-Texte, Zimmerarten –
## steht hier und wird über die Fläche zugeordnet, auf der ein Objekt liegt.
##
## Licht (Spielkonzept 7.3): Jede Lampe gehört zu einem Raum; ein Lichtschalter pro Raum bzw. Flurabschnitt
## (malt der Plan mehrere in einen Raum, schalten sie gemeinsam – Wechselschaltung).

const MAP_PATH := "res://assets/maps/eg.json"
## Stockwerke über dem Erdgeschoss, von unten nach oben (fehlt eine Datei, endet das Haus darunter)
const UPPER_MAP_PATHS := ["res://assets/maps/og1.json"]
## Untergeschoss (Spielkonzept 7.9) – die Treppenhäuser enden dort
const LOWER_MAP_PATH := "res://assets/maps/ug.json"
## Kellerwände: Brettschalungsbeton (Farbbild und Normal Map des PBR-Sets), eine Kachel = 18 Brettreihen auf
## CELLAR_WALL_METERS
const CELLAR_WALL_TEX := "res://assets/textures/Concrete_WoodPattern_01/Concrete_WoodPattern_01_Base_Color.jpg"
const CELLAR_WALL_NORMAL := "res://assets/textures/Concrete_WoodPattern_01/Concrete_WoodPattern_01_Normal.jpg"
const CELLAR_WALL_METERS := 3.0
## Lobbyboden: polierte Marmorplatten (Farbbild, Normal Map, Rauheit), eine Kachel = 4 × 4 Platten à 60 cm
const LOBBY_FLOOR_TEX := "res://assets/textures/TilesMarble_01/T_TilesMarble_01_basecolor.jpg"
const LOBBY_FLOOR_NORMAL := "res://assets/textures/TilesMarble_01/T_TilesMarble_01_normalogl.jpg"
const LOBBY_FLOOR_ROUGHNESS := "res://assets/textures/TilesMarble_01/T_TilesMarble_01_roughness.jpg"
const LOBBY_FLOOR_METERS := 2.4
## Glanz des Lobbybodens (0,5 = übliches Nichtmetall), Spiegelanteil (Metallic: hebt Godots Bildschirmspiegelung
## über die festen 4 % für Stein, kostet etwas Grundfarbe) und Rauheit der Karte × Faktor (schärfere Spiegelbilder)
const LOBBY_FLOOR_SPECULAR := 0.5
const LOBBY_FLOOR_MIRROR := 0.3
const LOBBY_FLOOR_ROUGHNESS_SCALE := 0.6
## Poolbecken: glasierte Fliesen in Blau- und Grüntönen (Farbbild, Normal Map, Rauheit), eine Kachel = 6 × 6 Fliesen
## à 10 cm – die Fugen treffen so die Kanten des Beckens (Innenwände, Boden, Rand auf Zehntelmetern)
const POOL_TILES_TEX := "res://assets/textures/pool/Tiles_06_basecolor.jpg"
const POOL_TILES_NORMAL := "res://assets/textures/pool/Tiles_06_normalOgl.jpg"
const POOL_TILES_ROUGHNESS := "res://assets/textures/pool/Tiles_06_roughness.jpg"
const POOL_TILES_METERS := 0.6
const POOL_TILES_SPECULAR := 0.5
## Wände der Poolhalle: Riemchen aus Naturstein (Farbbild mit eingebackener AO – das Muster steckt im Set fast nur in
## AO und Normal Map –, Normal Map), eine Kachel = 6 Spalten × ~22 Reihen, also Steine à ~50 × 14 cm
const POOL_WALL_TEX := "res://assets/textures/Stone_EngraveWall_01/Stone_EngraveWall_01_basecolor.jpg"
const POOL_WALL_NORMAL := "res://assets/textures/Stone_EngraveWall_01/Stone_EngraveWall_01_normalogl.jpg"
const POOL_WALL_METERS := 3.0
## Umgang der Poolhalle: hellgraue Fliesen (Farbbild, Normal Map, Rauheit), eine Kachel = 4 × 4 Fliesen à 25 cm –
## die Fugen treffen die Kanten des Beckens
const POOL_FLOOR_TEX := "res://assets/textures/TilesBasic_01/T_TilesBasic_01_basecolor.jpg"
const POOL_FLOOR_NORMAL := "res://assets/textures/TilesBasic_01/T_TilesBasic_01_normalogl.jpg"
const POOL_FLOOR_ROUGHNESS := "res://assets/textures/TilesBasic_01/T_TilesBasic_01_roughness.jpg"
const POOL_FLOOR_METERS := 1.0
const POOL_FLOOR_SPECULAR := 0.5
## Säulen der Lobby unter der Galerie: polierter dunkler Terrazzo (Farbbild, Rauheit; die Normal Map des Sets ist
## flach), eine Kachel = 1 m, Steinchen 5–8 mm. Runder Schaft zwischen zwei quadratischen Sockeln, mittig im Plan
const PILLAR_TEX := "res://assets/textures/TerrazzoDark_01/TerrazzoDark_01_basecolor.jpg"
const PILLAR_ROUGHNESS := "res://assets/textures/TerrazzoDark_01/TerrazzoDark_01_roughness.jpg"
const PILLAR_METERS := 1.0
const PILLAR_SPECULAR := 0.5
const PILLAR_SHAFT_RADIUS := 0.3
const PILLAR_SHAFT_SEGMENTS := 24
const PILLAR_PLINTH := Vector3(0.8, 0.3, 0.8)
const H := 3.5
const T := 0.2
## Höhe des Obergeschosses (Oberkante Boden)
const UP_Y := 4.0
## Wandhöhe der Tapete in Hallen über zwei Stockwerke (Lufträume): so hoch, dass keine Leiste und kein neues
## Stockwerk kommt
const HALL_WALL_TOP := 100.0
## Gedimmtes Licht (Spielkonzept 7.3): keine Deckenlampen, Wandleuchten schwächer als Kerzen
const WALL_LAMP_ENERGY := 0.5
## Abstand der Tanzplätze im Sechseckraster – rund 1,7 m² Freiraum je Tänzer (Spielkonzept 7.1)
const DANCE_SPACING := 1.4
const CANDLE_ENERGY := 0.85
## Zimmer etwas heller als die Flure
const ROOM_LAMP_ENERGY := 0.65
## Deckenleuchten (wieder seit 2026-10-19, nur wo der Plan sie setzt): gedimmt, aber mit Reichweite bis zum Boden.
## Über dem Luftraum hängen sie als Pendel an einer Schnur bis PENDANT_Y herab (Oberkante Schirm).
const CEILING_LAMP_ENERGY := 0.65
const CEILING_LAMP_RANGE := 9.0
const PENDANT_Y := 4.8
## Mitte der Discokugel über der Tanzfläche (Partyraum, Luftraum) – vom Boden wie von der Galerie aus zu sehen
const DISCO_Y := 5.4
const DOOR_W := 1.2
const DOOR_H := 2.1
## Doppeltüren, Glastüren, Terrassentüren
const WIDE_DOOR_H := 2.4
const ENTRANCE_H := 2.8
const COUCH_MODEL := "res://assets/models/couch.glb"
## Rohmodell ist 4,34 Einheiten lang → ~2,4 m lang, Sitzhöhe ~0,45 m, Lehne ~0,92 m.
const COUCH_SCALE := 0.55
## 28 einzelne Flaschen „bottle_NN“ in Metern, Ursprung mittig unten (tools/build_bottles.py)
const BOTTLES_MODEL := "res://assets/models/bottles.glb"
## Pflanzkübel samt Bepflanzung in Metern, Ursprung mittig unten, Grundfläche 2 × 2 m wie im Plan
## (tools/build_planter.py aus Meshys Modell). Fehlt die Datei, baut `_gardens()` den Platzhalter aus
## Steinquader und Heckenkugel.
const PLANTER_MODEL := "res://assets/models/planter.glb"
## Handlauf der Pooltreppen mit gebogenen Knicken (tools/build_handrail.py, Tiefe 1,4 m und Lauf 2,1 m wie in _pool);
## Ursprung am Fuß des Pfostens auf dem Umgang, die Treppe hinab entlang −Z. Fehlt die Datei, gerade Stangen.
const HANDRAIL_MODEL := "res://assets/models/pool_handrail.glb"
## Höhe des Kollisionsquaders (und des Platzhalter-Kübels) = Beckenkante, ausgegeben von tools/build_planter.py
const PLANTER_H := 0.46
## Laubbaum in Metern, Ursprung auf der Stammachse am Boden (tools/build_tree.py aus Meshys Modell).
## `_tree()` skaliert ihn auf den Kronenradius aus dem Plan; fehlt die Datei, bleibt der Platzhalter.
const TREE_MODEL := "res://assets/models/tree.glb"
## Wanduhr über dem Haupteingang (WallClock): Durchmesser und Abstand der Rückseite zur Wandfläche; die Mitte hängt
## auf halber Höhe zwischen der Oberkante des AUSGANG-Schilds und der Hallendecke
const CLOCK_DIAMETER := 3.0
const CLOCK_GAP := 0.02
## Kronenradius und Stammdurchmesser des Modells (ausgegeben von tools/build_tree.py), Höhe der Stammkollision
const TREE_RADIUS := 5.0
const TREE_TRUNK := 1.53
const TREE_TRUNK_H := 3.0
## Höhe des Modells (bei TREE_RADIUS); fallendes Laub entsteht zwischen diesen Anteilen davon (Krone)
const TREE_HEIGHT := 9.9
const TREE_CROWN := Vector2(0.35, 0.6)
## Fallendes Herbstlaub je Baum: so viele Blätter gleichzeitig, Lebenszeit (s) – reicht für den Fall aus
## der Krone und ein paar Sekunden am Boden –, Sinkgeschwindigkeit (m/s), Kantenlänge (m)
const LEAF_FALL := 40
const LEAF_LIFE := 20.0
const LEAF_SPEED := Vector2(0.45, 0.8)
const LEAF_SIZE := 0.13
const LEAF_GLOW := 0.35          ## etwas Eigenleuchten, sonst verschluckt sie die Nacht unter der Krone
const LEAF_COLORS: Array[Color] = [Color(0.75, 0.35, 0.08), Color(0.6, 0.15, 0.05), Color(0.8, 0.55, 0.1), Color(0.45, 0.25, 0.08)]
const LAYER_CEILING := 16
const LAYER_GLASS := 64
## Trittflächen der Treppenstufen – nur für Spuren (Traces.surface_below), blockiert niemanden. Gelaufen wird auf der
## glatten Rampe darunter (Ebene 1, Meta „stair_ramp“), die vorn an jeder Stufe über der Trittfläche liegt.
const LAYER_TREAD := 2048
## Fenster: Unterkante (bündig mit der Vertäfelung), Oberkante – die Breite kommt aus dem Plan
const WINDOW_SILL := 0.75
const WINDOW_TOP := 3.05
## Oberkante Boden des Untergeschosses (ein Stockwerk unter dem EG)
const CELLAR_Y := -UP_Y
## Halogenleuchten im Untergeschoss (Spielkonzept 7.9): Helligkeit und Reichweite (vor Lamp.BRIGHTNESS/REACH)
const HALOGEN_ENERGY := 0.6
const HALOGEN_RANGE := 7.0
## Unterwasserlampen im Pool (Spielkonzept 7.5): je Längswand so viele, Höhe der Mitte unter dem Boden,
## Helligkeit und Reichweite (vor Lamp.BRIGHTNESS/REACH)
const POOL_LAMPS_PER_SIDE := 2
const POOL_LAMP_Y := -0.85
const POOL_LAMP_ENERGY := 1.2
const POOL_LAMP_RANGE := 6.0
## Wäscherei im Untergeschoss: Waschmaschinen je Längswand (nicht im Plan)
const WASHERS_PER_WALL := 12
## Rasterweite der Flächen-Nachschlagetabelle (Wandmaterial, Raum-IDs)
const GRID := 0.25

## Zimmer mit besonderer Rolle (Spielkonzept 7.5: die alten Nummern sind die Endziffern). Alle übrigen
## Zimmer im Ostflügel sind unbewohnt („vacant“), die im Westflügel noch verschlossen (Bauphase).
## Arten: player, guest, empty, vacant (unbewohnt, Licht aus), laundry, abandoned, derelict, locked.
const PLAYER_ROOM := "0113"
const COMPASS_ROOM := "0126"
const LOCKED_ROOM := "0118"
const ROOM_KINDS := {
	"0111": "guest", "0112": "guest", "0113": "player", "0114": "empty", "0115": "guest",
	"0116": "laundry", "0117": "abandoned", "0118": "locked", "0126": "derelict", "0137": "derelict",
}
## Flügel, deren Zimmer schon bewohnbar sind
const OPEN_WINGS := ["ost"]

## Inhalt, der nicht im Plan steht, je Raum-ID (Zimmernummer oder Bereich): Münzbetrag (ohne Eintrag 1),
## Kartenblatt, Zettel-Nummer (Spielkonzept 4.12) und UV-Schrift (4.16) der Objekte in diesem Raum.
const CONTENT := {
	"0113": {"coins": "3", "map": "eg", "uv": "DU WARST SCHON\nEINMAL HIER"},
	"0114": {"note": "2003"},
	"0116": {"note": "1994"},
	"0117": {"coins": "2", "map": "keller", "note": "1987",
		"uv": "ICH HABE ES GEBLENDET.\nJETZT KENNT ES MEINE TÜR.\n– E. K."},
	"0118": {"coins": "5", "uv": "NUR EINER\nKOMMT HINAUS"},
	"lobby": {"note": "2019", "map": "og"},   # Kartenblatt Obergeschoss an der Rezeption (Spielkonzept 3.2)
}
## Möbel ohne eigenes Bauteil (Kästen in der Grundfläche aus dem Plan): Art → Höhe
const BOX_HEIGHTS := {
	"table": 0.75, "coffee_table": 0.4, "dining_table": 0.78, "bench": 0.45, "bar_counter": 1.1, "shelf": 2.0,
	"kitchen_counter": 0.9, "stove": 0.95, "washbasin": 0.85, "washing_machine": 0.85, "laundry_box": 0.5,
}
const RECEPTION_H := 1.1
## Teppiche aus dem Plan: Art → Textur (TexGen); Oberseite knapp über dem Boden
const RUG_TEXTURES := {"runner": "runner"}
const RUG_Y := 0.01
## Wandsachen: Abstand zur Wandfläche (bündig, ohne Flimmern) und Höhen über dem Boden
const WALL_GAP := 0.01
const SWITCH_Y := 1.3
const CALENDAR_Y := 1.7
const UV_Y := 1.5
const COBWEB_Y := 2.4
## Schilder (Zimmernummern, AUSGANG, BAR …): Messingbuchstaben in Cinzel Bold (OFL, assets/fonts/OFL.txt;
## ohne überlappende Konturen aus tools/build_font.py) auf einer Holzplatte mit Messingrand.
## Schriftgröße (Geviert) in Metern – Wegweiser, Zimmernummern –, Versalhöhe ~0,7 davon; CURVE_STEP in
## Schriftpixeln – grob, damit die Rundungen kantig bleiben (PS1-Look)
const SIGN_FONT := "res://assets/fonts/cinzel_bold.ttf"
const SIGN_EM := 0.22
const SIGN_EM_ROOM := 0.17
const SIGN_FONT_SIZE := 16
const SIGN_CURVE_STEP := 2.0
## Wie weit die Buchstaben vor der Platte stehen, Stärke der Platte, Rand um den Text, Messingrand
const SIGN_DEPTH := 0.01
const SIGN_PLATE := 0.016
const SIGN_MARGIN := Vector2(0.05, 0.035)
const SIGN_RIM := 0.008
## Messing je Schild: blank, matt, angelaufen
const SIGN_BRASS: Array[Color] = [Color(0.8, 0.64, 0.28), Color(0.68, 0.54, 0.25), Color(0.52, 0.45, 0.27)]
## Ersatzbirnen liegen im Lagerregal, nicht obendrauf
const BULB_SUPPLY_Y := 1.4
## Reifegrade der Kürbispflanzen in Planreihenfolge (von Norden nach Süden, je Beet von Westen nach Osten)
const PLANT_STAGES := [0, 3, 2, 3, 1, 3]
const PAINTING_COLORS: Array[Color] = [Color(0.22, 0.14, 0.12), Color(0.16, 0.2, 0.15), Color(0.12, 0.13, 0.2),
	Color(0.2, 0.18, 0.1), Color(0.18, 0.1, 0.12), Color(0.1, 0.14, 0.18), Color(0.25, 0.1, 0.1)]
## Umkleiden und Duschen am Pool teilen sich einen Lichtschalter
const CHANGING_ROOMS := ["vorraum", "dusche_west", "dusche_ost", "umkleide_west", "umkleide_ost"]
## Flächenarten ohne Namen im Plan → Name (Schalter, Zonen)
const KIND_NAMES := {"cat_room": "Katzenraum", "library": "Bibliothek", "bath": "Bad", "balcony": "Balkon",
	"terrace": "Terrasse", "toilet": "Toilette", "storage": "Lager", "cellar": "Keller", "boiler_room": "Heizkeller",
	"plant_room": "Technikraum", "laundry_room": "Wäscherei", "cellar_room": "Kellerraum"}
## Kratzbaum (Spielkonzept 7.7): Höhe der oberen Liegefläche
const CAT_TREE_TOP := 1.45

var root: Node3D     ## NavigationRegion3D – statische Geometrie, wird fürs NavMesh geparst
var world: Node3D    ## Hauptszene – dynamische Gegenstände
var _leaf_tex: ImageTexture
var zones: Array[Dictionary] = []
var spawn_points: Array[Vector3] = []
## Wegpunkte im ganzen Hotel (Verschwinden aus dem Blickfeld): {pos, room}
var patrol: Array[Dictionary] = []
## Punkte in den Fluren, an denen Gäste herumschlendern
var wander_points: Array[Vector3] = []
## Zimmernummer → {no, sign, kind, center, door_front, door_inside, along, into, door, spots}
var rooms := {}
var lobby_center := Vector3.ZERO
## Tanzplätze im Partyraum, von der Mitte der Tanzfläche nach außen sortiert (Social.free_party_spot)
var party_spots: Array[Vector3] = []
var party_center := Vector3.ZERO
var lobby_seats: Array[Vector3] = []
## Liegeplätze der Hotelkatzen auf Möbeln (6.11): {"floor": davor auf dem Boden, "top": obendrauf}
var cat_perches: Array[Dictionary] = []
var kitchen_spot := Vector3.ZERO
var garden_spots: Array[Vector3] = []
var player_spawn := Vector3.ZERO
var player_door_front := Vector3.ZERO
var record_player_pos := Vector3.ZERO
## Dunkle Ecke des Partyraums (dort steht es beim ersten Angriff, MonsterDirector)
var party_corner := Vector3.ZERO
var game_table: GameTable
var chess_table: ChessTable
var bar_spots: Array[Vector3] = []
var diary: Diary
## Treppenhaus zwischen den Geschossen (Ausbreitung der Flacker-Welle, MonsterDirector.wave_delay)
var stairwell_point := Vector3.ZERO

## Plan und Nachschlagetabellen je Stockwerk (_state), nach dem Bau für die Abfragen anderer Systeme
var _floors: Array[Dictionary] = []
var _has_upper := false
var _top_level := 0   ## oberstes Stockwerk
var _lower := -1      ## Index des Untergeschosses in _floors
## Stockwerk, das gerade gebaut wird bzw. dessen Zustand geladen ist (0 = EG, −1 = UG), und seine Bodenhöhe
var _level := 0
var _base_y := 0.0
## Treppenhäuser des EG (Schächte über alle Stockwerke): ID → {rect, frame (Transform3D: lokal −Z = zum Podest)}
var _shafts := {}
## Bad → Zimmernummer (Licht und Verschluss gehören zum Zimmer)
var _bath_owner := {}
## Räume, für die der Plan einen Lichtschalter hat
var _switched := {}
var _cellar_center := Vector3.ZERO
## Jedes Zimmer des Plans, auch verschlossene: Nummer → {pos (Mitte am Boden), look (zur Tür)}
var _room_spots := {}
var _upper_plans: Array[Dictionary] = []

var _map: Dictionary
var _parent: Node3D  ## wohin die Bausteine gerade bauen (root oder ein gedrehter Rahmen)
## Flächen-Nachschlagetabelle: Index in _places + 1 je Rasterzelle, 0 = keine Fläche (draußen oder Wand)
var _grid := PackedInt32Array()
var _grid_origin := Vector2.ZERO
var _grid_size := Vector2i.ZERO
var _places: Array[Dictionary] = []   ## {id, kind, region}
var _lobby := Rect2()                 ## Innenmaß der Lobby (x, z)
## Hallen über zwei Stockwerke (Lufträume des EG): {rect, kind (Art im EG)} – für ihre Wände (_wall_side_kind)
var _halls: Array[Dictionary] = []
var _exit_sign_top := 0.0             ## Oberkante des AUSGANG-Schilds über dem Haupteingang (für _clock)
var _hall_wallpapers := {}            ## Tapete im EG → dieselbe ohne Leiste, Höhe ab dem EG-Boden
var _named := {}                    ## Flächen-ID → Rect2 (Umriss)
## Wandstücke des Plans, an die Wandsachen gehängt werden: {horizontal, at (Mittellinie), from, to, half (halbe Dicke)}
var _wall_index: Array[Dictionary] = []
## Wandstöße für _joint_depth/_joints_on (siehe _index_joints)
var _faces := {}
var _ends := {}
## Gebaute Möbel und die Rezeption: {kind, rect: Rect2, top (Oberkante), front: Vector2, node}
var _furnishings: Array[Dictionary] = []
var _doors: Array[Dictionary] = []    ## {pos: Vector3 (Mitte unten), door: Door, kind, into}
var _open_rooms := {}                 ## Nummern der bewohnbaren Zimmer (OPEN_WINGS)

var _wallpaper: Material
var _room_wallpaper: Material
var _lobby_wallpaper: Material
var _facade: Material
var _wall_tiles: Material
var _concrete: Material
var _wood: Material
var _dark_wood: Material
var _ceiling: Material
var _room_ceiling: Material
var _hedge: Material
var _carpet: Material
var _wood_floor: Material
var _floor_tiles: Material
var _lobby_floor: Material
var _pool_tiles: Material
var _pool_wall: Material
var _pool_floor: Material
var _pillar_stone: Material
var _grass: Material
var _stone: Material
var _cellar_wall: Material
var _cellar_floor: Material
var _cellar_ceiling: Material
var _sign_font: Font


func _init(p_root: Node3D, p_world: Node3D) -> void:
	root = p_root
	world = p_world
	_parent = root


func build() -> void:
	_materials()
	var ground: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(MAP_PATH))
	assert(ground != null, "Gebäudeplan %s fehlt – tools/build_map.py ausführen" % MAP_PATH)
	var uppers: Array[Dictionary] = []
	for path: String in UPPER_MAP_PATHS:
		if not FileAccess.file_exists(path):
			break
		uppers.append(JSON.parse_string(FileAccess.get_file_as_string(path)))
	var lower: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(LOWER_MAP_PATH))
	assert(lower != null, "Gebäudeplan %s fehlt – tools/build_map.py ausführen" % LOWER_MAP_PATH)
	_has_upper = not uppers.is_empty()
	_upper_plans = uppers
	_top_level = uppers.size()
	_begin_floor(ground, 0)
	_index_shafts()
	_build_plan_floor()
	_lobby_hall()
	if _has_upper:
		_lobby_flight()
	else:
		_gallery()
	_common_rooms()
	_pool()
	_gardens()
	_stairwells()
	_floors = [_state()]
	for i in uppers.size():
		_upper_floor(uppers[i], i + 1)
	_lower_floor(lower)
	_use(_floors[0])
	var home: Dictionary = rooms[PLAYER_ROOM]
	player_spawn = (home["center"] as Vector3) + Vector3(0, 0.05, 0) + (home["into"] as Vector3) * 0.1
	player_door_front = home["door_front"]
	_zones()
	_waypoints()


## Was jedes Stockwerk aus seinem Plan baut: Wände, Böden und Decken, Zimmer, Einrichtung, Lichter.
func _build_plan_floor() -> void:
	for w in _map["walls"]:
		_build_wall(w)
	_corner_posts()
	_floors_and_ceilings()
	for info in _map["rooms"]:
		_room(info)
	_furniture()
	_rugs()
	_fittings()
	_items()
	_lights()
	_auto_switches()


## Obergeschoss (Spielkonzept 7.7): derselbe Bau wie im Erdgeschoss, nur unter einem um UP_Y angehobenen
## Knoten. Dazu Geländer an Lufträumen und Balkonen, gesperrte Treppenhaustüren.
func _upper_floor(plan: Dictionary, level: int) -> void:
	var ground := root
	var upper := Node3D.new()
	upper.name = "Obergeschoss" if level == 1 else "Obergeschoss_%d" % level
	upper.position.y = UP_Y * level
	ground.add_child(upper)
	root = upper
	_parent = upper
	_begin_floor(plan, level)
	_build_plan_floor()
	_void_edges()
	_balconies()
	_seal_stairwells()
	_floors.append(_state())
	root = ground
	_parent = root


## Untergeschoss (Spielkonzept 7.9): derselbe Bau unter einem um UP_Y abgesenkten Knoten. Alles grau, Licht nur
## aus den Halogenleuchten des Plans; dazu das Versteck des Monsters im Heizkeller und Waschmaschinen.
func _lower_floor(plan: Dictionary) -> void:
	var ground := root
	var lower := Node3D.new()
	lower.name = "Untergeschoss"
	lower.position.y = CELLAR_Y
	ground.add_child(lower)
	root = lower
	_parent = lower
	_begin_floor(plan, -1)
	_build_plan_floor()
	_seal_stairwells()
	_boiler_room()
	_laundry_room()
	_lower = _floors.size()
	_floors.append(_state())
	root = ground
	_parent = root


## Treppenhaustüren dieses Stockwerks absperren – offen ist nur das Treppenhaus Ost.
func _seal_stairwells() -> void:
	for s in _map["stairs"]:
		if s["kind"] == "stairwell" and s["id"] != "treppenhaus_ost" and s.has("door"):
			var door := _door_near(_v3(s["door"]["pos"]), 0.8)
			if door:
				_seal(door, "Das Treppenhaus ist abgesperrt.")


## Plan eines Stockwerks laden und seine Nachschlagetabellen neu aufbauen.
func _begin_floor(plan: Dictionary, level: int) -> void:
	var lobby := _lobby
	_map = plan
	_level = level
	_base_y = UP_Y * level
	_grid = PackedInt32Array()
	_places = []
	_named = {}
	_wall_index = []
	_faces = {}
	_ends = {}
	_furnishings = []
	_doors = []
	_index_places()
	_index_joints()
	if level > 0:
		_lobby = lobby   # die Galerie über der Lobby gehört zur Halle (rote Tapete, Lobby-Licht)
	elif level < 0:
		_lobby = Rect2()
	else:
		_halls = []
		for rc in _map["open_above"]:
			var r := Rect2(rc[0], rc[1], rc[2] - rc[0], rc[3] - rc[1])
			_halls.append({"rect": r, "kind": _kind_at(r.get_center())})


## Zustand des geladenen Stockwerks (für _use).
func _state() -> Dictionary:
	return {"map": _map, "level": _level, "base_y": _base_y, "grid": _grid, "grid_origin": _grid_origin,
		"grid_size": _grid_size, "places": _places, "lobby": _lobby, "named": _named, "wall_index": _wall_index,
		"faces": _faces, "ends": _ends, "furnishings": _furnishings, "doors": _doors}


func _use(s: Dictionary) -> void:
	_map = s["map"]
	_level = s["level"]
	_base_y = s["base_y"]
	_grid = s["grid"]
	_grid_origin = s["grid_origin"]
	_grid_size = s["grid_size"]
	_places = s["places"]
	_lobby = s["lobby"]
	_named = s["named"]
	_wall_index = s["wall_index"]
	_faces = s["faces"]
	_ends = s["ends"]
	_furnishings = s["furnishings"]
	_doors = s["doors"]


## Stockwerk zur Höhe y als Index in _floors (EG 0, darüber 1 …, das Untergeschoss zuletzt; −1 = keins:
## Treppenpodest, in der Luft).
func _level_of(y: float) -> int:
	for i in _floors.size():
		if absf(y - float(_floors[i]["base_y"])) < 1.5:
			return i
	return -1


## f mit dem Plan des Stockwerks level (Index in _floors) aufrufen (Abfragen anderer Systeme nach dem Bau).
func _on_floor(level: int, f: Callable) -> Variant:
	var keep := _state()
	_use(_floors[level])
	var result: Variant = f.call()
	_use(keep)
	return result


## Treppenhäuser des EG: Rechteck und Rahmen (Ursprung Mitte, lokal −Z zum Podest gegenüber der Tür).
func _index_shafts() -> void:
	for s in _map["stairs"]:
		if s["kind"] != "stairwell":
			continue
		var rc: Array = s["rect"]
		var r := Rect2(rc[0], rc[1], rc[2] - rc[0], rc[3] - rc[1])
		var to_landing := -_dir(String(s.get("door", {}).get("side", "south")))
		var frame := Transform3D(Basis(Vector3.UP, atan2(-to_landing.x, -to_landing.y)), Vector3(r.get_center().x, 0, r.get_center().y))
		_shafts[String(s["id"])] = {"rect": r, "frame": frame, "plan": s}


func _materials() -> void:
	_wallpaper = Mat.wallpaper(H, UP_Y)
	_room_wallpaper = Mat.wallpaper(H, UP_Y, "beige")   # nur in den Zimmern
	_lobby_wallpaper = Mat.wallpaper(H, UP_Y, "red")
	_facade = Mat.psx(Color(0.62, 0.56, 0.5), "concrete", 0.5)
	_wall_tiles = Mat.psx(Color(0.82, 0.88, 0.9), "tiles", 1.0)
	_concrete = Mat.psx(Color(0.8, 0.8, 0.8), "concrete", 0.5)
	_wood = Mat.psx(Color(0.45, 0.28, 0.15))
	_dark_wood = Mat.psx(Color(0.22, 0.13, 0.08))
	_ceiling = Mat.psx(Color(0.55, 0.55, 0.55), "wood", 1.0)   # Holzdecke wie der Zimmerboden, abgedunkelt (7.3)
	_room_ceiling = Mat.psx(Color(0.85, 0.85, 0.85), "wood", 1.0)   # in den Zimmern heller
	_hedge = Mat.psx(Color(1, 1, 1), "hedge", 1.0)
	_carpet = Mat.psx(Color(1, 1, 1), "carpet", 1.0)
	_wood_floor = Mat.psx(Color(1, 1, 1), "wood", 1.0)
	_floor_tiles = Mat.psx(Color(1, 1, 1), "tiles", 0.5)
	_lobby_floor = Mat.photo(LOBBY_FLOOR_TEX, LOBBY_FLOOR_METERS, LOBBY_FLOOR_NORMAL, LOBBY_FLOOR_ROUGHNESS, LOBBY_FLOOR_SPECULAR)
	_lobby_floor.set_meta("floor", "tiles")   # Schritte klingen wie auf den übrigen Fliesen (Footsteps)
	_lobby_floor.set_shader_parameter("metallic", LOBBY_FLOOR_MIRROR)
	_lobby_floor.set_shader_parameter("roughness_scale", LOBBY_FLOOR_ROUGHNESS_SCALE)
	_pool_tiles = Mat.photo(POOL_TILES_TEX, POOL_TILES_METERS, POOL_TILES_NORMAL, POOL_TILES_ROUGHNESS, POOL_TILES_SPECULAR)
	_pool_tiles.set_meta("floor", "tiles")
	_pool_wall = Mat.photo(POOL_WALL_TEX, POOL_WALL_METERS, POOL_WALL_NORMAL)
	_pool_floor = Mat.photo(POOL_FLOOR_TEX, POOL_FLOOR_METERS, POOL_FLOOR_NORMAL, POOL_FLOOR_ROUGHNESS, POOL_FLOOR_SPECULAR)
	_pool_floor.set_meta("floor", "tiles")
	_pillar_stone = Mat.photo(PILLAR_TEX, PILLAR_METERS, "", PILLAR_ROUGHNESS, PILLAR_SPECULAR)
	_grass = Mat.psx(Color(1, 1, 1), "grass", 1.0)
	_stone = Mat.psx(Color(0.62, 0.57, 0.5), "concrete", 1.0)
	# Untergeschoss (Spielkonzept 7.9): Wände aus Brettschalungsbeton, Boden und Decke einfach grau
	_cellar_wall = Mat.photo(CELLAR_WALL_TEX, CELLAR_WALL_METERS, CELLAR_WALL_NORMAL)
	_cellar_floor = Mat.psx(Color(0.45, 0.45, 0.45), "concrete", 1.0)
	_cellar_ceiling = Mat.psx(Color(0.5, 0.5, 0.5), "concrete", 0.5)
	_sign_font = load(SIGN_FONT)


# --- Plan: Flächen nachschlagen --------------------------------------------------------------------

## Füllt das Raster mit den Flächen des Plans (Regionen, Bodenflicken, Treppen, Terrassenkanten).
func _index_places() -> void:
	var lo := Vector2(INF, INF)
	var hi := Vector2(-INF, -INF)
	# Über dem EG tragen Flächen ohne Zimmernummer das Stockwerk vorne (og1_flure …), sonst schalteten oben und
	# unten dieselben Schalter; Treppenhäuser bleiben ein Raum über alle Stockwerke
	var pre := _prefix()
	var add := func(id: String, kind: String, rects: Array, region: Dictionary) -> void:
		_places.append({"id": id, "kind": kind, "rects": rects, "region": region})
	for r in _map["regions"]:
		var kind := String(r["kind"])
		add.call(String(r["id"]) if kind == "room" else pre + String(r["id"]), kind, r["rects"], r)
	for p in _map["floor_patches"]:
		add.call("", String(p["kind"]), p["rects"], {})
	for s in _map["stairs"]:
		add.call(String(s["id"]), "stairs", [s["rect"]], {})
	for rs in _map["terrace_edges"]:
		add.call("", "terrace", rs, {})
	for rs in _map.get("balcony_edges", []):
		add.call("", "balcony", rs, {})
	for place in _places:
		for rc in place["rects"]:
			lo = Vector2(minf(lo.x, rc[0]), minf(lo.y, rc[1]))
			hi = Vector2(maxf(hi.x, rc[2]), maxf(hi.y, rc[3]))
	_grid_origin = lo - Vector2.ONE
	_grid_size = Vector2i(ceili((hi.x - lo.x + 2.0) / GRID), ceili((hi.y - lo.y + 2.0) / GRID))
	_grid.resize(_grid_size.x * _grid_size.y)
	_grid.fill(0)
	for i in _places.size():
		for rc in _places[i]["rects"]:
			var c0 := Vector2i(ceili((rc[0] - _grid_origin.x) / GRID - 0.5), ceili((rc[1] - _grid_origin.y) / GRID - 0.5))
			var c1 := Vector2i(floori((rc[2] - _grid_origin.x) / GRID - 0.5), floori((rc[3] - _grid_origin.y) / GRID - 0.5))
			for cy in range(c0.y, c1.y + 1):
				for cx in range(c0.x, c1.x + 1):
					_grid[cy * _grid_size.x + cx] = i + 1
	for r in _map["regions"]:
		if r.has("name"):
			_named[pre + String(r["id"])] = _bounds(r["rects"])
	for a in _map["areas"]:
		if a["id"] == "lobby":
			var rc: Array = a["rect"]
			_lobby = Rect2(rc[0], rc[1], rc[2] - rc[0], rc[3] - rc[1])
	for info in _map["rooms"]:
		if String(info["wing"]) in OPEN_WINGS:
			_open_rooms[String(info["no"])] = true
		# Bäder gehören zum Zimmer hinter ihrer Tür
		for d in info.get("bath_doors", []):
			var bath := _place_at(_v2(d["pos"]) + _v2(d["normal"]) * 0.4)
			if not bath.is_empty() and bath["kind"] == "bath":
				_bath_owner[String(bath["id"])] = String(info["no"])


## Vorsatz der Raum-IDs auf diesem Stockwerk („“ im EG, „og1_“ darüber, „ug_“ darunter).
func _prefix() -> String:
	if _level < 0:
		return "ug_"
	return "" if _level == 0 else "og%d_" % _level


func _bounds(rects: Array) -> Rect2:
	var r := Rect2(rects[0][0], rects[0][1], rects[0][2] - rects[0][0], rects[0][3] - rects[0][1])
	for rc in rects:
		r = r.merge(Rect2(rc[0], rc[1], rc[2] - rc[0], rc[3] - rc[1]))
	return r


func _place_at(p: Vector2) -> Dictionary:
	var c := Vector2i(floori((p.x - _grid_origin.x) / GRID), floori((p.y - _grid_origin.y) / GRID))
	if c.x < 0 or c.y < 0 or c.x >= _grid_size.x or c.y >= _grid_size.y:
		return {}
	var i := _grid[c.y * _grid_size.x + c.x]
	return _places[i - 1] if i > 0 else {}


## Art des Ortes für Wandmaterial und Türrichtung: room, sealed, corridor, lobby, bar, party, service,
## storage, toilet, pool, elevator, stairs, outside (Garten, Terrasse, außerhalb).
func _kind_at(p: Vector2) -> String:
	var place := _place_at(p)
	if place.is_empty():
		return "outside"
	var kind: String = place["kind"]
	match kind:
		"room":
			return "room" if _room_open(String(place["id"])) else "sealed"
		"bath":
			var owner := String(_bath_owner.get(String(place["id"]), ""))
			return "sealed" if owner != "" and not _room_open(owner) else "bath"
		"corridor":
			return "lobby" if _lobby.has_point(p) else "corridor"
		"garden", "terrace", "balcony":
			return "outside"
		"pool_water", "pool_deck":
			return "pool"
	return kind


## Raum-ID für Lampen, Fenster und Schalter am Ort p: Zimmernummer, Bereich, benannte Fläche oder Flurabschnitt.
func _room_id_at(p: Vector2) -> String:
	var place := _place_at(p)
	if place.is_empty():
		return ""
	if place["kind"] == "corridor":
		return "lobby" if _lobby.has_point(p) else _section_at(p)
	return String(place["id"])


func _room_open(no: String) -> bool:
	return _open_rooms.has(no)


## Nächster Flurabschnitt (Mittellinie aus dem Plan).
func _section_at(p: Vector2) -> String:
	var best := ""
	var best_d := INF
	for c in _map["corridors"]:
		var d := _dist_segment(p, _v2(c["a"]), _v2(c["b"]))
		if d < best_d:
			best_d = d
			best = String(c["id"])
	return _prefix() + best


func _dist_segment(p: Vector2, a: Vector2, b: Vector2) -> float:
	var ab := b - a
	var t := clampf((p - a).dot(ab) / maxf(ab.length_squared(), 0.0001), 0.0, 1.0)
	return p.distance_to(a + ab * t)


func _v2(a: Array) -> Vector2:
	return Vector2(float(a[0]), float(a[1]))


func _v3(a: Array, y: float = 0.0) -> Vector3:
	return Vector3(float(a[0]), y, float(a[1]))


# --- Wände, Türen, Fenster ----------------------------------------------------------------------------

## Eine Wand des Plans. Sie wird dort geteilt, wo sich die Räume auf einer Seite ändern (anderes Material);
## Seiten ohne Tapete (draußen, Fliesen, Beton) bekommen eine dünne Haut mit eigenem Material.
func _build_wall(w: Dictionary) -> void:
	var a := _v2(w["a"])
	var b := _v2(w["b"])
	var horizontal := is_equal_approx(a.y, b.y)
	var along := Vector2(1, 0) if horizontal else Vector2(0, 1)
	var side := Vector2(0, 1) if horizontal else Vector2(1, 0)   # „Plus“-Seite: Süden bzw. Osten
	var s0 := a.x if horizontal else a.y
	var s1 := b.x if horizontal else b.y
	var fixed := a.y if horizontal else a.x
	var openings: Array = w.get("openings", [])
	var glass := bool(w.get("glass", false))
	if _in_shaft(a) and _in_shaft(b):
		return   # Mittelwand im Treppenhaus: baut _stairwells über alle Stockwerke

	# Seiten abtasten (alle 25 cm, 30 cm neben der Wandmitte), kurze Läufe (Querwände) glätten
	var steps := maxi(1, roundi((s1 - s0) / GRID))
	var minus: Array[String] = []
	var plus: Array[String] = []
	for i in steps:
		var p := a + along * (i + 0.5) * (s1 - s0) / steps
		minus.append(_wall_side_kind(p - side * 0.3))
		plus.append(_wall_side_kind(p + side * 0.3))
	_smooth(minus)
	_smooth(plus)
	# Wechselt die Seite an einer anstoßenden Wand, liegt der Schnitt in deren Mitte: Ihr Körper deckt dann die
	# Stoßkante der beiden Stücke ab (sonst blitzt dort beim Vertex-Snapping der Boden dahinter durch)
	var joints: Array[float] = []
	if horizontal:
		joints = _joints_on(fixed, float(w.get("thickness", T)) / 2.0)
	var cuts: Array[float] = [s0]
	for i in range(1, steps):
		if minus[i] != minus[i - 1] or plus[i] != plus[i - 1]:
			var s := s0 + i * (s1 - s0) / steps
			var best := GRID * 1.2
			var snapped := s
			for j: float in joints:
				if absf(j - s) < best:
					best = absf(j - s)
					snapped = j
			s = snapped
			if s > cuts[-1] + 0.05 and s < s1 - 0.05 and not _in_opening(openings, s - s0):
				cuts.append(s)
	cuts.append(s1)

	# Senkrechte Wände enden laut Plan bündig an waagerechten – das Mesh steckt bis zu deren Mitte darin,
	# sonst klafft beim Vertex-Snapping in der Ecke eine Fuge, durch die der Boden dahinter blitzt. Endet
	# umgekehrt eine waagerechte Wand an der Fläche einer durchgehenden senkrechten (T-Stoß), weicht ihr Kopf bis
	# zu deren Mitte zurück: Sonst läge er in einer Ebene mit der Fläche davor und blitzte mit seiner Tapete durch.
	var ext0 := -_head_inset(a, -1.0) if horizontal else _joint_depth(a, -1.0)
	var ext1 := -_head_inset(b, 1.0) if horizontal else _joint_depth(b, 1.0)

	var ops3: Array = []
	for o in openings:
		ops3.append(_opening_vec(o, s0))
	for k in cuts.size() - 1:
		var p0 := cuts[k]
		var p1 := cuts[k + 1]
		var m0 := p0 - (ext0 if k == 0 else 0.0)
		var m1 := p1 + (ext1 if k == cuts.size() - 2 else 0.0)
		var i := clampi(roundi(((p0 + p1) / 2.0 - s0) / (s1 - s0) * steps - 0.5), 0, steps - 1)
		var mine: Array = []
		for op: Vector4 in ops3:
			if op.x > p0 and op.x < p1:
				mine.append(op)
		if glass:
			_glass_wall(horizontal, fixed, p0, p1)
		else:
			_wall_piece(horizontal, fixed, m0, m1, mine, minus[i], plus[i])
		_wall_index.append({"horizontal": horizontal, "at": fixed, "from": p0, "to": p1,
			"half": float(w.get("thickness", T)) / 2.0})
	for o in openings:
		_opening_object(o, a, along, side, horizontal)


## Wandstöße aus dem Plan, nach z in Zentimetern: Flächen der waagerechten Wände (Vector2i(Seite, z) →
## [Vector3(x0, x1, halbe Dicke)], Seite -1 = Nordfläche) und Enden der senkrechten Wände (z → [x]).
func _index_joints() -> void:
	for w in _map["walls"]:
		var a := _v2(w["a"])
		var b := _v2(w["b"])
		if is_equal_approx(a.y, b.y):
			var half := float(w.get("thickness", T)) / 2.0
			for s: int in [-1, 1]:
				var key := Vector2i(s, roundi((a.y + s * half) * 100.0))
				if not _faces.has(key):
					_faces[key] = []
				_faces[key].append(Vector3(minf(a.x, b.x), maxf(a.x, b.x), half))
		else:
			for p: Vector2 in [a, b]:
				var key := roundi(p.y * 100.0)
				if not _ends.has(key):
					_ends[key] = []
				_ends[key].append(a.x)


## Halbe Dicke der waagerechten Wand, an deren Fläche das Ende p einer senkrechten Wand stößt
## (dir -1 = nach Norden, 1 = nach Süden), sonst 0.
func _joint_depth(p: Vector2, dir: float) -> float:
	# nach Süden stößt das Ende an eine Nordfläche und umgekehrt
	for f: Vector3 in _faces.get(Vector2i(-int(dir), roundi(p.y * 100.0)), []):
		if p.x > f.x - 0.01 and p.x < f.y + 0.01:
			return f.z
	return 0.0


## Wie weit der Kopf end einer waagerechten Wand (ex = Richtung nach außen) zurückweicht: Läuft sie laut Plan
## durch eine senkrechte Wand hindurch bis an deren ferne Fläche und geht die senkrechte dort beidseits weiter
## (Stücke nördlich und südlich, die bis zur Mitte der waagerechten reichen, siehe _joint_depth), deren halbe
## Dicke, sonst 0.
func _head_inset(end: Vector2, ex: float) -> float:
	var half := T / 2.0
	var x := end.x - ex * half
	if _vertical_at(x, end.y - half) and _vertical_at(x, end.y + half):
		return half
	return 0.0


## Holzpfeiler um freie Wandköpfe, an deren Außenecken zwei verschiedene Tapeten zusammenstoßen (Zimmerblock
## und Flur, rote Lobby und Flur): Der Pfeiler fasst den Übergang ein. Außenecken gibt es nur an freien Enden waagerechter
## Wände – senkrechte stoßen immer an eine waagerechte. Reine Optik wie die Türrahmen.
func _corner_posts() -> void:
	var wood := OpeningFrame.trim_material()
	for w in _map["walls"]:
		var a := _v2(w["a"])
		var b := _v2(w["b"])
		if not is_equal_approx(a.y, b.y) or bool(w.get("glass", false)):
			continue
		var half := float(w.get("thickness", T)) / 2.0
		for end: Vector2 in [a, b]:
			var ex := 1.0 if end.x > minf(a.x, b.x) + 0.01 else -1.0   # vom Wandkopf nach außen
			if _continues(end, half, ex):
				continue
			# Beide Seiten der Wand am Kopf (der Kopf selbst trägt die Tapete der Nordseite) und, an jeder
			# Außenecke, der Raum vor dem Kopf
			var kinds: Array[String] = []
			var convex := false
			for s: float in [-1.0, 1.0]:
				kinds.append(_kind_at(Vector2(end.x - ex * 0.3, end.y + s * 0.3)))
				if not _vertical_at(end.x - ex * half, end.y + s * half):   # sonst Innenecke
					convex = true
					kinds.append(_kind_at(Vector2(end.x + ex * 0.3, end.y - s * 0.3)))
			if not convex or "outside" in kinds:
				continue
			var mats := {}
			for k in kinds:
				var m := _wall_material(k)
				mats[m if m else _skin_material(k)] = true
			if mats.size() < 2:
				continue
			var depth := 0.17   # 12 cm in der Wand, 5 cm vor der Stirnseite
			var width := 2.0 * half + 0.06
			var pos := Vector2(end.x + ex * (0.05 - depth / 2.0), end.y)
			Geo.mesh(root, Geo.box(Vector3(depth, H, width)), wood, Vector3(pos.x, H / 2.0, pos.y))
			Geo.mesh(root, Geo.box(Vector3(depth + 0.03, 0.18, width + 0.03)), wood, Vector3(pos.x + ex * 0.015, 0.09, pos.y))
			Geo.mesh(root, Geo.box(Vector3(depth + 0.03, 0.1, width + 0.03)), wood, Vector3(pos.x + ex * 0.015, H - 0.05, pos.y))


## Läuft die waagerechte Wand am Ende end in Richtung ex mit einer anderen weiter?
func _continues(end: Vector2, half: float, ex: float) -> bool:
	for f: Vector3 in _faces.get(Vector2i(-1, roundi((end.y - half) * 100.0)), []):
		if absf((f.x if ex > 0 else f.y) - end.x) < 0.02:
			return true
	return false


## Endet bei (x, z) eine senkrechte Wand?
func _vertical_at(x: float, z: float) -> bool:
	for vx: float in _ends.get(roundi(z * 100.0), []):
		if absf(vx - x) < 0.02:
			return true
	return false


## x der senkrechten Wände, die mit einem Ende an die waagerechte Wand bei z (halbe Dicke half) stoßen.
func _joints_on(z: float, half: float) -> Array[float]:
	var xs: Array[float] = []
	for s: float in [-1.0, 1.0]:
		for x: float in _ends.get(roundi((z + s * half) * 100.0), []):
			xs.append(x)
	return xs


## Kurze Läufe (unter 0,6 m – Querwände, Ecken) bekommen die Art des Nachbarn.
func _smooth(kinds: Array[String]) -> void:
	var i := 0
	while i < kinds.size():
		var j := i
		while j < kinds.size() and kinds[j] == kinds[i]:
			j += 1
		if (j - i) * GRID < 0.6:
			var fill: String = kinds[i - 1] if i > 0 else (kinds[j] if j < kinds.size() else kinds[i])
			for k in range(i, j):
				kinds[k] = fill
		i = j


func _in_opening(openings: Array, at: float) -> bool:
	for o in openings:
		if at > float(o["at"]) - 0.05 and at < float(o["at"]) + float(o["width"]) + 0.05:
			return true
	return false


## Öffnung als Vector4(Mitte entlang der Wand, Breite, Oberkante, Unterkante).
func _opening_vec(o: Dictionary, s0: float) -> Vector4:
	var width := float(o["width"])
	var center := s0 + float(o["at"]) + width / 2.0
	match String(o["kind"]):
		"window":
			return Vector4(center, width, WINDOW_TOP, WINDOW_SILL)
		"main_entrance":   # im Untergeschoss: Türen der verschlossenen Räume
			return Vector4(center, width, ENTRANCE_H if _level >= 0 else DOOR_H, 0.0)
		"door", "service_door":
			return Vector4(center, width, DOOR_H if width < 1.5 else WIDE_DOOR_H, 0.0)
	return Vector4(center, width, WIDE_DOOR_H, 0.0)


## Art einer Wandseite: wie _kind_at, an einem Luftraum aber „hall:<Art im EG>“ – im EG darunter wie darüber
## (dort liegt im Plan keine Fläche, die Seite wäre sonst draußen und trüge Fassade).
func _wall_side_kind(p: Vector2) -> String:
	if _level >= 0:
		for hall in _halls:
			if (hall["rect"] as Rect2).has_point(p):
				return "hall:" + String(hall["kind"])
	return _kind_at(p)


func _wall_material(kind: String) -> Material:
	if _level < 0:
		return _cellar_wall   # im Untergeschoss überall Beton
	if kind.begins_with("hall:"):
		# Halle über zwei Stockwerke: Rauten ohne Leiste bis unter die Decke, die Höhe zählt durchgehend ab dem
		# EG-Boden (nahtlos zwischen EG- und OG-Wand); unten die Vertäfelung wie sonst
		var below := _wall_material(kind.trim_prefix("hall:")) as ShaderMaterial
		if below == null:
			return null
		if not _hall_wallpapers.has(below):
			var m := below.duplicate() as ShaderMaterial
			m.set_shader_parameter("wall_top", HALL_WALL_TOP)
			m.set_shader_parameter("storey", HALL_WALL_TOP)
			_hall_wallpapers[below] = m
		return _hall_wallpapers[below]
	match kind:
		"room", "sealed", "cat_room", "library":
			return _room_wallpaper
		"lobby":
			return _lobby_wallpaper
		"corridor", "bar", "party", "service", "stairs", "elevator":
			return _wallpaper
	return null


func _skin_material(kind: String) -> Material:
	if _level < 0:
		return null
	match kind:
		"outside":
			return _facade
		"toilet", "bath":
			return _wall_tiles
		"pool":
			return _pool_wall
		"storage":
			return _concrete
	return null


## Liegt p im Inneren eines Treppenschachts (nicht auf seinen Außenwänden)?
func _in_shaft(p: Vector2) -> bool:
	for id in _shafts:
		if (_shafts[id]["rect"] as Rect2).grow(-0.15).has_point(p):
			return true
	return false


func _wall_piece(horizontal: bool, fixed: float, p0: float, p1: float, openings: Array, minus: String, plus: String) -> void:
	# Über dem EG reichen die Wände bis zur Oberkante der Wände darunter hinab (sonst klafft in der Fassade die
	# Fuge zwischen Decke und Boden)
	var drop := UP_Y - H if _level > 0 else 0.0
	if _level < 0:
		# Im Untergeschoss reichen sie in den Boden darüber und enden mitten in seiner Platte (bündig mit seiner
		# Oberseite flimmerten sie dort durch); am Treppenschacht, wo oben kein Boden liegt, bis an die Wand darüber
		var mid := Vector2((p0 + p1) / 2.0, fixed) if horizontal else Vector2(fixed, (p0 + p1) / 2.0)
		var side := Vector2(0, 0.3) if horizontal else Vector2(0.3, 0)
		var shaft := _in_shaft(mid - side) or _in_shaft(mid + side)
		_wall_piece_at(horizontal, fixed, p0, p1, openings, minus, plus, UP_Y if shaft else UP_Y - 0.1)
		return
	if drop > 0.0:
		var keep := _parent
		_parent = Node3D.new()
		_parent.position.y = -drop
		keep.add_child(_parent)
		var lifted: Array = []
		for op: Vector4 in openings:
			lifted.append(Vector4(op.x, op.y, op.z + drop, op.w + drop))
		_wall_piece_at(horizontal, fixed, p0, p1, lifted, minus, plus, H + drop)
		_parent = keep
		return
	_wall_piece_at(horizontal, fixed, p0, p1, openings, minus, plus, H)


func _wall_piece_at(horizontal: bool, fixed: float, p0: float, p1: float, openings: Array, minus: String, plus: String, height: float) -> void:
	var m_minus := _wall_material(minus)
	var m_plus := _wall_material(plus)
	var normal_plus := Vector3(0, 0, 1) if horizontal else Vector3(1, 0, 0)
	var mat: Material
	if m_minus and m_plus and m_minus != m_plus:
		mat = Mat.wallpaper_split(m_minus, m_plus, normal_plus)
	else:
		mat = m_minus if m_minus else (m_plus if m_plus else _wallpaper)
	if horizontal:
		_wall_x(fixed, p0, p1, openings, mat, height)
	else:
		_wall_z(fixed, p0, p1, openings, mat, height)
	# Häute für Seiten ohne Tapete, knapp vor der Wandfläche
	for s: float in [-1.0, 1.0]:
		var skin := _skin_material(minus if s < 0 else plus)
		if skin == null:
			continue
		var offset := s * (T / 2.0 + 0.012)
		var holder := Node3D.new()
		if horizontal:
			holder.position = Vector3(0, 0, fixed + offset)
		else:
			holder.position = Vector3(fixed + offset, 0, 0)
			holder.rotation.y = -PI / 2.0
		_parent.add_child(holder)
		Geo.mesh(holder, Geo.wall_mesh(p0, p1, height, 0.02, openings), skin, Vector3.ZERO)


## Glaswand (Pool): Scheibe auf der Glas-Ebene, Rahmen und Pfosten alle ~1,8 m.
func _glass_wall(horizontal: bool, fixed: float, p0: float, p1: float) -> void:
	var holder := Node3D.new()
	if horizontal:
		holder.position = Vector3((p0 + p1) / 2.0, 0, fixed)
	else:
		holder.position = Vector3(fixed, 0, (p0 + p1) / 2.0)
		holder.rotation.y = -PI / 2.0
	root.add_child(holder)
	var length := p1 - p0
	var pane := StaticBody3D.new()
	pane.collision_layer = LAYER_GLASS
	pane.collision_mask = 0
	holder.add_child(pane)
	Geo.add_box_shape(pane, Vector3(length, H, T), Vector3(0, H / 2.0, 0))
	var quad := QuadMesh.new()
	quad.size = Vector2(length, H - 0.4)
	var g := Geo.mesh(pane, quad, Mat.glass(), Vector3(0, H / 2.0 + 0.1, 0))
	g.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var frame := Mat.psx(Color(0.2, 0.22, 0.24))
	Geo.solid(holder, Vector3(length, 0.3, T), Vector3(0, 0.15, 0), frame)        # Sockel (auch fürs NavMesh)
	Geo.mesh(holder, Geo.box(Vector3(length, 0.12, T)), frame, Vector3(0, H - 0.06, 0))
	var posts := maxi(1, roundi(length / 1.8))
	for i in posts + 1:
		Geo.mesh(holder, Geo.box(Vector3(0.08, H, 0.12)), frame, Vector3(-length / 2.0 + length * i / posts, H / 2.0, 0))


## Tür oder Fenster für eine Öffnung des Plans.
func _opening_object(o: Dictionary, a: Vector2, along: Vector2, side: Vector2, horizontal: bool) -> void:
	var kind := String(o["kind"])
	var width := float(o["width"])
	var c := a + along * (float(o["at"]) + width / 2.0)
	var k_minus := _kind_at(c - side * 0.5)
	var k_plus := _kind_at(c + side * 0.5)
	# „Innen“ = die Seite, in die Türen aufgehen bzw. in die das Fenster schaut; ein Türanschlag im Plan
	# gibt sie vor
	var inner := float(o["opens"]) if o.has("opens") else _inner_side(k_minus, k_plus, kind)
	var into := side * inner
	var into3 := Vector3(into.x, 0, into.y)
	var yaw := atan2(into3.x, into3.z)
	var right := Vector3(cos(yaw), 0, -sin(yaw))
	var center := Vector3(c.x, 0, c.y)
	var inside_kind := k_plus if inner > 0 else k_minus
	var room_id := _room_id_at(c + into * 0.5)
	if kind == "window":
		var exterior := (k_plus if inner < 0 else k_minus) == "outside"
		var win := HotelWindow.new().setup(width, WINDOW_TOP - WINDOW_SILL, false, exterior, room_id)
		win.position = center + Vector3(0, (WINDOW_SILL + WINDOW_TOP) / 2.0, 0)
		win.rotation.y = yaw
		win.sealed = inside_kind == "sealed"
		root.add_child(win)
		return
	var wide := width >= 1.5
	var height := _opening_vec(o, 0.0).z
	var glass := kind in ["garden_door", "glass_double_door"]
	# Scharnier: ohne Türanschlag im Ursprung der Tür (vom Flur aus rechts), sonst am Ende aus dem Plan
	var hinge := center - right * width / 2.0
	if o.has("hinge"):
		hinge = center + Vector3(along.x, 0, along.y) * width / 2.0 * (1.0 if o["hinge"] == "end" else -1.0)
	var hinge_end := not wide and (hinge - center).dot(right) > 0.0
	var door := Door.new().setup(width, height, -90.0 if wide else -100.0, wide, glass, hinge_end)
	door.position = center - right * width / 2.0
	door.rotation.y = yaw
	root.add_child(door)
	_doors.append({"pos": center, "door": door, "kind": kind, "into": into3, "hinge": hinge})
	match kind:
		"main_entrance" when _level < 0:   # Untergeschoss: verschlossene Räume in der Farbe des Haupteingangs
			_seal(door, "Abgeschlossen.")
		"main_entrance":
			door.locked = true
			door.key_id = "ausgang"
			door.monster_can_open = false
			door.locked_text = "Der Ausgang ist verriegelt. Es muss einen anderen Weg hinaus geben …"
			_exit_sign_top = _sign("AUSGANG", center + Vector3(0, ENTRANCE_H + 0.35, 0) + into3 * 0.11, rad_to_deg(yaw))
		"elevator_door":
			door.locked = true
			door.key_id = "aufzug"
			door.monster_can_open = false
			door.locked_text = "Außer Betrieb."
			_sign("AUSSER BETRIEB", center + Vector3(0, WIDE_DOOR_H + 0.3, 0) - into3 * 0.11, rad_to_deg(yaw) + 180.0)
	if k_minus == "sealed" or k_plus == "sealed":
		_seal(door, "Abgeschlossen.")


func _inner_side(k_minus: String, k_plus: String, kind: String) -> float:
	# Türen gehen in Zimmer und Räume auf, nicht in Flure; Fenster schauen von innen nach draußen
	var rank := func(k: String) -> int:
		match k:
			"outside":
				return 0 if kind == "window" else 1
			"corridor", "lobby", "cellar":
				return 2
		return 3
	return 1.0 if rank.call(k_plus) >= rank.call(k_minus) else -1.0


## Tür, die (in dieser Bauphase) niemand öffnen kann – auch das Monster nicht.
func _seal(door: Door, text: String) -> void:
	door.locked = true
	door.key_id = "gesperrt"
	door.monster_can_open = false
	door.locked_text = text


## Pixel in map.aseprite zu einem Punkt des Plans (für Warnungen).
func _plan_pixel(p: Vector2) -> Vector2i:
	var origin: Array = _map["origin_px"]
	return Vector2i((p / float(_map["meters_per_pixel"])).round()) + Vector2i(int(origin[0]), int(origin[1]))


## Liegt p (an der Wand) dort, wo eine offene Tür steht? Neben dem Scharnier auf der Aufgehseite, bis eine
## Blattbreite weit – dort verdeckt das Blatt die Wand (Lichtschalter gehören auf die Griffseite).
func _behind_door(p: Vector3) -> bool:
	for d in _doors:
		var door: Door = d["door"]
		var center: Vector3 = d["pos"]
		var hinges: Array = [d["hinge"], center * 2.0 - d["hinge"]] if door.double else [d["hinge"]]
		var leaf := door.width / 2.0 if door.double else door.width
		for hinge: Vector3 in hinges:
			var rel := Vector3(p.x - hinge.x, 0, p.z - hinge.z)
			var depth := rel.dot(d["into"])
			var beside := rel.dot((hinge - center).normalized())
			if depth > 0.0 and depth < 0.5 and beside > 0.0 and beside < leaf:
				return true
	return false


func _door_near(p: Vector3, max_dist: float = 0.6) -> Door:
	var best: Door = null
	var best_d := max_dist
	for d in _doors:
		var dist := (d["pos"] as Vector3).distance_to(Vector3(p.x, 0, p.z))
		if dist < best_d:
			best_d = dist
			best = d["door"]
	return best


# --- Böden und Decken -------------------------------------------------------------------------------

func _floors_and_ceilings() -> void:
	var holes: Array[Rect2] = []
	for rc in _map["open_above"]:
		holes.append(Rect2(rc[0], rc[1], rc[2] - rc[0], rc[3] - rc[1]))
	if not _has_upper:
		holes.append(_lobby)   # die Lobby-Decke ist der Boden der Galerie (_gallery)
	for r in _map["regions"]:
		var kind := String(r["kind"])
		if kind == "elevator":
			continue   # Aufzüge außer Betrieb
		# Verschlossene Zimmer und Kellerräume: Boden nur zum Draufstehen (Debug-Teleport), auf der Ebene der Decken –
		# nicht im NavMesh, sonst planten Gäste und Monster Wege durch abgesperrte Türen
		var layer := LAYER_CEILING if (kind == "room" and not _room_open(String(r["id"]))) or kind == "cellar_room" else 1
		var ceiling := _cellar_ceiling if _level < 0 else (_room_ceiling if kind == "room" else _ceiling)
		for rc in r["rects"]:
			if kind != "pool_water":   # das Becken baut _pool, die Decke darüber ist die Holzdecke der Halle
				_floor(kind, rc, layer)
			if not bool(r["outdoor"]):
				for piece in _subtract(Rect2(rc[0], rc[1], rc[2] - rc[0], rc[3] - rc[1]), holes):
					Geo.solid(root, Vector3(piece.size.x, 0.2, piece.size.y), Vector3(piece.get_center().x, H + 0.1, piece.get_center().y),
						ceiling, LAYER_CEILING)
	for p in _map["floor_patches"]:
		for rc in p["rects"]:
			_floor(String(p["kind"]), rc)
			if not bool(p["outdoor"]):
				for piece in _subtract(Rect2(rc[0], rc[1], rc[2] - rc[0], rc[3] - rc[1]), holes):
					Geo.solid(root, Vector3(piece.size.x, 0.2, piece.size.y), Vector3(piece.get_center().x, H + 0.1, piece.get_center().y), _ceiling, LAYER_CEILING)
	for rs in _map["terrace_edges"] + _map.get("balcony_edges", []):
		for rc in rs:
			_floor_rect(rc, _stone)
	# Über einem Luftraum (Lobby, Partyraum) schließt die Decke dieses Stockwerks die Halle nach oben ab
	for rc in _map["voids"]:
		Geo.solid(root, Vector3(float(rc[2]) - float(rc[0]), 0.2, float(rc[3]) - float(rc[1])),
			Vector3((float(rc[0]) + float(rc[2])) / 2.0, H + 0.1, (float(rc[1]) + float(rc[3])) / 2.0), _ceiling, LAYER_CEILING)
	# Schwellen: unter jeder Tür liegt die Wand – ohne Boden dort risse das NavMesh ab
	for d in _doors:
		var door: Door = d["door"]
		if door.monster_can_open:
			var into: Vector3 = d["into"]
			var size := Vector3(door.width, 0.2, T) if absf(into.z) > 0.5 else Vector3(T, 0.2, door.width)
			Geo.solid(root, size, (d["pos"] as Vector3) + Vector3(0, -0.1, 0), _wood)


## Boden über dem EG: 0,3 m stark, liegt auf der Decke darunter (H … H + 0,2) auf – keine Fuge an Lufträumen
## und Balkonkanten, keine doppelte Fläche mit der Decke.
func _floor_rect(rc: Array, mat: Material, layer: int = 1) -> void:
	var thick := 0.2 if _level <= 0 else UP_Y - H - 0.2
	var size := Vector3(float(rc[2]) - float(rc[0]), thick, float(rc[3]) - float(rc[1]))
	Geo.solid(root, size, Vector3((float(rc[0]) + float(rc[2])) / 2.0, -thick / 2.0, (float(rc[1]) + float(rc[3])) / 2.0), mat, layer)


## Boden eines Plan-Rechtecks. Flure tragen Teppich, nur in der Lobby Fliesen: Ragt ein Flurrechteck in die
## Lobby (der Südflur läuft als ein Stück quer hindurch), wird es an deren Rand geteilt.
func _floor(kind: String, rc: Array, layer: int = 1) -> void:
	if kind != "corridor":
		_floor_rect(rc, _floor_material(kind), layer)
		return
	var r := Rect2(rc[0], rc[1], rc[2] - rc[0], rc[3] - rc[1])
	var inside := r.intersection(_lobby) if _level == 0 else Rect2()   # die Galerie trägt Teppich
	if inside.has_area():
		_floor_rect([inside.position.x, inside.position.y, inside.end.x, inside.end.y], _lobby_floor)
	for piece in (_subtract(r, [_lobby]) if _level == 0 else [r]):
		_floor_rect([piece.position.x, piece.position.y, piece.end.x, piece.end.y], _carpet)


func _floor_material(kind: String) -> Material:
	if _level < 0:
		return _cellar_floor
	match kind:
		"room", "bar", "party", "cat_room", "library":
			return _wood_floor
		"garden":
			return _grass
		"terrace", "balcony":
			return _stone
		"storage":
			return _concrete
		"pool_deck":
			return _pool_floor
	return _floor_tiles


## Rechteck minus Löcher → Rechtecke.
func _subtract(r: Rect2, holes: Array[Rect2]) -> Array[Rect2]:
	var pieces: Array[Rect2] = [r]
	for h in holes:
		var next: Array[Rect2] = []
		for p in pieces:
			var i := p.intersection(h)
			if i.size.x <= 0.001 or i.size.y <= 0.001:
				next.append(p)
				continue
			# Reste unter 1 mm (Rundung der Plankoordinaten) fallen weg – sonst steckt z. B. eine Deckenplatte ohne
			# Tiefe in der Wandfläche und flimmert durch die Tapete
			if i.position.y > p.position.y + 0.001:
				next.append(Rect2(p.position.x, p.position.y, p.size.x, i.position.y - p.position.y))
			if i.end.y < p.end.y - 0.001:
				next.append(Rect2(p.position.x, i.end.y, p.size.x, p.end.y - i.end.y))
			if i.position.x > p.position.x + 0.001:
				next.append(Rect2(p.position.x, i.position.y, i.position.x - p.position.x, i.size.y))
			if i.end.x < p.end.x - 0.001:
				next.append(Rect2(i.end.x, i.position.y, p.end.x - i.end.x, i.size.y))
		pieces = next
	return pieces


# --- Zimmer ------------------------------------------------------------------------------------------

## Ein Zimmer des Plans. Gebaut wird im Rahmen der Tür: Ursprung = Türmitte auf der Wandmitte,
## +X an der Flurwand entlang, +Z ins Zimmer. x0…x1 = Innenmaß an der Türwand, depth = bis zur Rückwand.
func _room(plan: Dictionary) -> void:
	var no := String(plan["no"])
	var door_pos := _v3(plan["door"]["pos"])
	var normal: Array = plan["door"]["normal"]
	var into := Vector3(-float(normal[0]), 0, -float(normal[1]))
	var door := _door_near(door_pos)
	var c: Array = plan["center"]
	_room_spots[no] = {"pos": Vector3(float(c[0]), _base_y, float(c[1])), "look": -into}
	if not String(plan["wing"]) in OPEN_WINGS:
		return   # Bauphase: Tür verschlossen (_opening_object), kein Inneres
	assert(door != null, "Zimmer %s: keine Tür an der Stelle aus dem Plan" % no)
	var kind: String = ROOM_KINDS.get(no, "vacant")
	var holder := Node3D.new()
	holder.name = "Zimmer_%s" % no
	holder.position = door_pos
	holder.rotation.y = atan2(into.x, into.z)
	root.add_child(holder)
	_parent = holder
	# Innenmaß aus dem Rechteck an der Tür (Eckzimmer sind L-förmig)
	var rect: Array = plan["rects"][0]
	for rc in plan["rects"]:
		var probe := door_pos + into * 1.0
		if probe.x >= float(rc[0]) and probe.x <= float(rc[2]) and probe.z >= float(rc[1]) and probe.z <= float(rc[3]):
			rect = rc
	var x0 := INF
	var x1 := -INF
	var depth := 0.0
	for corner: Vector3 in [Vector3(rect[0], 0, rect[1]), Vector3(rect[2], 0, rect[1]), Vector3(rect[0], 0, rect[3]), Vector3(rect[2], 0, rect[3])]:
		var local: Vector3 = holder.global_transform.affine_inverse() * corner
		x0 = minf(x0, local.x)
		x1 = maxf(x1, local.x)
		depth = maxf(depth, local.z)
	var cx := (x0 + x1) / 2.0
	var label := String(plan["sign"])
	var info := {
		"no": no, "sign": label, "kind": kind,
		"center": _global(Vector3(cx, 0, depth / 2.0)),
		"door_front": _global(Vector3(0, 0, -0.9)),
		"door_inside": _global(Vector3(0, 0, 1.0)),
		"along": holder.global_transform.basis.x.normalized(),   # an der Flurwand entlang
		"into": into,                                             # vom Flur ins Zimmer
		"door": door,
		"spots": [],
	}
	if not plan.get("suite", false):   # Suiten betritt man durchs Nachbarzimmer: kein Schild an der Verbindungstür
		_sign(label, Vector3(0, 2.45, -0.11), 180.0, SIGN_EM_ROOM)
	# Das Innere steht im Plan (_furniture, _fittings, _items, _lights); hier nur, was die Zimmerart ausmacht
	match kind:
		"abandoned", "derelict":
			door.set_open.call_deferred(true)   # verlassen bzw. verfallen: die Tür steht offen
		"locked":
			door.locked = true
			door.key_id = "zimmer_18"
			door.locked_text = "Zimmer %s ist abgeschlossen." % label
	rooms[no] = info
	_room_spots[no]["pos"] = info["center"]   # Mitte des Rechtecks an der Tür (bei L-Zimmern sicher drinnen)
	_parent = root


# --- Einrichtung aus dem Plan ---------------------------------------------------------------------------

## Platz an der Wand für eine Wandsache des Plans (Leuchte, Schalter, Bild …).
class WallSpot:
	var pos: Vector2      ## auf der Wandfläche, plus Abstand
	var out: Vector2      ## von der Wand weg in den Raum
	var inside: Vector2   ## ein Stück im Raum – dort werden Raum-ID und Flächenart nachgeschlagen
	var side: String      ## Wandseite aus dem Plan (`wall`)

	func yaw() -> float:
		return atan2(out.x, out.y)

	func at(y: float) -> Vector3:
		return Vector3(pos.x, y, pos.y)


## Möbel (Ebene „Möbel“): Rechteck = Grundfläche, `facing` = Vorderseite. Verstecke, Kommoden, Truhe, Spieltische
## und Sofas sind eigene Bauteile in der Mitte des Rechtecks, alles andere Kästen in Plangröße (BOX_HEIGHTS).
## Dazu die Rezeption aus dem Grundriss. Verschlossene Zimmer bleiben leer.
func _furniture() -> void:
	for rc in _map["reception"]:
		var r := Rect2(rc[0], rc[1], rc[2] - rc[0], rc[3] - rc[1])
		var desk := Geo.solid(root, Vector3(r.size.x, RECEPTION_H, r.size.y), Vector3(r.get_center().x, RECEPTION_H / 2.0, r.get_center().y), _dark_wood)
		_furnishings.append({"kind": "reception", "rect": r, "top": RECEPTION_H, "front": Vector2.ZERO, "node": desk})
	for f in _map["furniture"]:
		var rc: Array = f["rect"]
		var rect := Rect2(rc[0], rc[1], rc[2] - rc[0], rc[3] - rc[1])
		var c := rect.get_center()
		if _kind_at(c) == "sealed":
			continue
		var kind := String(f["kind"])
		var front := _facing(String(f.get("facing", "")), c)
		var yaw := atan2(front.x, front.y)
		var pos := Vector3(c.x, 0, c.y)
		var node: Node3D
		var top := 0.0
		match kind:
			"bed", "wardrobe":
				var spot := _hide_spot(HideSpot.Type.BED if kind == "bed" else HideSpot.Type.WARDROBE, pos, yaw)
				var room: Dictionary = rooms.get(_room_id_at(c), {})
				if not room.is_empty():
					spot.own_bed = kind == "bed" and room["kind"] == "player"
					if spot.own_bed:   # ein frisches Laken zum Verkleiden (Spielkonzept 5.9)
						_item(Item.Kind.BED_SHEET, pos + Vector3(0, 0.62, 0))
					(room["spots"] as Array).append(spot)
				node = spot
				top = 0.6 if kind == "bed" else 2.18
			"dresser":
				node = Dresser.new()   # Schubladen (Spielkonzept 3.5)
				top = Dresser.SIZE.y
			"chest":
				node = Chest.new()
				top = Chest.SIZE.y
			"chess_table":
				chess_table = ChessTable.new()
				node = chess_table
				top = 0.76
			"game_table":
				game_table = GameTable.new()
				node = game_table
				top = 0.76
			"couch":
				node = _couch(pos, yaw - PI / 2.0)   # das Modell sitzt nach +X
				top = 0.45
			"pillar":
				node = _pillar(rect)
				top = H
			"cat_tree":
				node = _cat_tree(rect)
				top = CAT_TREE_TOP
				var below := c + front * (maxf(rect.size.x, rect.size.y) / 2.0 + 0.35)
				cat_perches.append({"floor": Vector3(below.x, _base_y, below.y), "top": Vector3(c.x, _base_y + CAT_TREE_TOP + 0.01, c.y),
					"cat_room": _kind_at(c) == "cat_room"})
			_:
				if not BOX_HEIGHTS.has(kind):
					push_warning("Gebäudeplan: unbekannte Möbelart „%s“ bei %s" % [kind, c])
					continue
				top = BOX_HEIGHTS[kind]
				node = _box_furniture(kind, rect, top, front)
				if kind == "bar_counter":
					top += 0.045   # Thekenplatte
				elif kind == "laundry_box":
					# alte Laken mit aufgemalten Gesichtern – Deko vom letzten Jahr (Spielkonzept 5.6)
					var lc := rect.get_center()
					_supply(ResourceSpot.new().setup(Item.Kind.SHEET_GHOST, "Lakengespenst", 2, 400.0), Vector3(lc.x, top, lc.y))
		if node.get_parent() == null:
			node.position = pos
			node.rotation.y = yaw
			root.add_child(node)
		_furnishings.append({"kind": kind, "rect": rect, "top": top, "front": front, "node": node})


## Teppiche aus dem Plan (Ebene „Teppiche“, Spielkonzept 7.5): flache Auflage ohne Kollision (Schritte hört man
## wie auf dem Boden darunter). Ein Läufer läuft entlang der langen Seite seines Rechtecks, das Muster spannt sich
## quer über die ganze Breite (TexGen._runner). Wo zwei Läufer zusammenstoßen, entscheidet der Plan.
func _rugs() -> void:
	for r in _map["rugs"]:
		var rc: Array = r["rect"]
		var rect := Rect2(rc[0], rc[1], rc[2] - rc[0], rc[3] - rc[1])
		var c := rect.get_center()
		var kind := String(r["kind"])
		if _kind_at(c) == "sealed":
			continue
		if not RUG_TEXTURES.has(kind):
			push_warning("Gebäudeplan: unbekannte Teppichart „%s“ bei %s" % [kind, c])
			continue
		var length := maxf(rect.size.x, rect.size.y)
		var width := minf(rect.size.x, rect.size.y)
		var px := width / TexGen.RUNNER_WIDTH   # Kantenlänge eines Texturpixels: quadratisch wie quer
		var rows := float(TexGen.RUNNER_CAP_ROWS + TexGen.RUNNER_TILE_ROWS)
		var mesh := Geo.runner_mesh(length, width, TexGen.RUNNER_CAP_ROWS * px, TexGen.RUNNER_TILE_ROWS * px,
			TexGen.RUNNER_CAP_ROWS / rows)
		var mi := Geo.mesh(root, mesh, Mat.layer_uv(RUG_TEXTURES[kind]), Vector3(c.x, RUG_Y, c.y))
		if rect.size.y > rect.size.x:
			mi.rotation.y = PI / 2.0


## Möbel als Kasten in der Grundfläche des Plans; Theke mit Platte, Waschmaschine mit Bullauge vorn.
func _box_furniture(kind: String, rect: Rect2, height: float, front: Vector2) -> StaticBody3D:
	var mat := _wood
	match kind:
		"bench", "bar_counter":
			mat = _dark_wood
		"kitchen_counter":
			mat = Mat.psx(Color(0.55, 0.5, 0.42))
		"stove":
			mat = Mat.psx(Color(0.2, 0.2, 0.22))
		"washbasin":
			mat = Mat.psx(Color(0.85, 0.85, 0.82))
		"washing_machine":
			mat = Mat.psx(Color(0.75, 0.75, 0.72))
		"laundry_box":
			mat = Mat.psx(Color(0.6, 0.58, 0.5))
	var c := rect.get_center()
	var body := Geo.solid(root, Vector3(rect.size.x, height, rect.size.y), Vector3(c.x, height / 2.0, c.y), mat)
	match kind:
		"bar_counter":
			Geo.mesh(body, Geo.box(Vector3(rect.size.x + 0.1, 0.05, rect.size.y + 0.1)), _wood, Vector3(0, height / 2.0 + 0.02, 0))
		"washing_machine":
			var half := rect.size / 2.0
			var porthole := Geo.mesh(body, Geo.cylinder(0.2, 0.02, 10), Mat.psx(Color(0.15, 0.17, 0.2)),
				Vector3(front.x * (half.x + 0.005), 0.1, front.y * (half.y + 0.005)))
			if absf(front.x) > 0.5:
				porthole.rotation.z = PI / 2.0
			else:
				porthole.rotation.x = PI / 2.0
	return body


## Ausstattung (Ebene „Ausstattung“). Wandsachen hängen an der Wandseite aus dem Plan; Telefone, Zettel, Tagebuch
## und Vorräte stehen auf dem Möbel darunter. Zettel-Nummern und UV-Texte kommen aus CONTENT.
func _fittings() -> void:
	var paintings := 0
	var plants := 0
	for o in _map["fittings"]:
		var p := _v2(o["pos"])
		if _kind_at(p) == "sealed":
			continue
		var kind := String(o["kind"])
		var top := _top_at(p)
		var content: Dictionary = CONTENT.get(_room_id_at(p), {})
		if kind.begins_with("pumpkin_plant"):
			# Kürbispflanze, Sorte nach Palettenfarbe („pumpkin_plant:hokkaido“, Spielkonzept 5.8)
			var variety := kind.get_slice(":", 1) if ":" in kind else PumpkinKinds.DEFAULT
			var plant := PumpkinPlant.new().setup(PLANT_STAGES[plants % PLANT_STAGES.size()], variety)
			plant.position = Vector3(p.x, 0.05, p.y)   # auf dem Beet (_garden_beds)
			root.add_child(plant)
			plants += 1
			continue
		match kind:
			"switch":
				var at := _wall_spot(o, WALL_GAP)
				var id := _light_room_at(at.inside)
				var sw := _switch(id, _switch_label(id), at.at(SWITCH_Y), at.yaw())
				_switched[id] = true
				if _behind_door(sw.position):
					var why := "liegt hinter der offenen Tür – auf die Griffseite setzen oder den Türanschlag ans andere Ende"
					push_warning("Gebäudeplan: Lichtschalter (%s) bei Pixel %s %s" % [_switch_label(id), _plan_pixel(p), why])
				if rooms.has(id) and rooms[id]["kind"] == "vacant":
					sw.set_on.call_deferred(false, true)   # unbewohnt: dunkel
			"painting":
				var at := _wall_spot(o, WALL_GAP)
				var area := _kind_at(at.inside)
				var y := 2.2 if area == "lobby" else (1.9 if area == "bar" else 1.75)   # im Flur über den Kommoden
				_painting(at.at(y), at.yaw(), PAINTING_COLORS[paintings % PAINTING_COLORS.size()])
				paintings += 1
			"cobweb":
				# In einer Ecke (zweite Wand quer dazu nah) hängt die Spinnwebe schräg über Eck
				var at := _wall_spot(o, 0.02)
				for side in _perpendicular(at.side):
					if not _on_wall(p, side, 0.5).is_empty():
						at = _wall_spot(o, 0.12)
						at.out = (at.out - _dir(side)).normalized()
				_resource_web(at.at(COBWEB_Y), at.yaw())
			"uv_writing":
				var at := _wall_spot(o, WALL_GAP)
				var text := String(CONTENT.get(_room_id_at(at.inside), {}).get("uv", ""))
				if text == "":
					push_warning("Gebäudeplan: UV-Schrift bei %s ohne Text in CONTENT" % p)
					continue
				_uv_writing(text, at.at(UV_Y), at.yaw())
			"calendar":
				var at := _wall_spot(o, WALL_GAP)
				var calendar := Calendar.new()
				calendar.position = at.at(CALENDAR_Y)
				calendar.rotation.y = at.yaw()
				root.add_child(calendar)
			"phone":
				var phone := HotelPhone.new().setup(_room_id_at(p))   # Wählscheibentelefon (Spielkonzept 4.14)
				phone.position = Vector3(p.x, top, p.y)
				phone.rotation.y = _upright_yaw(p)
				root.add_child(phone)
			"note":
				if not content.has("note"):
					push_warning("Gebäudeplan: Zettel bei %s ohne Nummer in CONTENT" % p)
					continue
				var note := _note(String(content["note"]), Vector3(p.x, top + 0.01, p.y))
				note.rotation.y = _upright_yaw(p)
			"diary":
				diary = Diary.new()
				diary.position = Vector3(p.x, top + 0.01, p.y)
				diary.rotation.y = _upright_yaw(p) + 0.3   # leicht schräg hingelegt
				root.add_child(diary)
			"candle_supply":
				_supply(ResourceSpot.new().setup(Item.Kind.CANDLE, "Kerze aus dem Vorrat", 3, 150.0), Vector3(p.x, top, p.y))
			"bulb_supply":
				_supply(ResourceSpot.new().setup(Item.Kind.BULB, "Ersatzbirne aus dem Lager", 2, 300.0), Vector3(p.x, BULB_SUPPLY_Y, p.y))
			"leaf_pile":
				_supply(ResourceSpot.new().setup(Item.Kind.LEAVES, "Herbstlaub", 4, 60.0), Vector3(p.x, top, p.y))
			"deco_box":
				# Karton mit alter Halloween-Deko: Lichterketten (Spielkonzept 5.6)
				var box := ResourceSpot.new().setup(Item.Kind.LIGHT_STRING, "Deko aus der Kiste", 3, 500.0) \
					.with_pool([Item.Kind.LIGHT_STRING, Item.Kind.BAT_GARLAND, Item.Kind.SPIDER])
				box.rotation.y = _upright_yaw(p)
				_supply(box, Vector3(p.x, top, p.y))
			_:
				push_warning("Gebäudeplan: unbekannte Ausstattung „%s“ bei %s" % [kind, p])


func _supply(spot: ResourceSpot, pos: Vector3) -> void:
	spot.position = pos
	root.add_child(spot)


## Gegenstände (Ebene „Gegenstände“, Art = Item.Kind): auf dem Möbel darunter oder am Boden. Münzbetrag und
## Kartenblatt aus CONTENT.
func _items() -> void:
	for o in _map["items"]:
		var p := _v2(o["pos"])
		if _kind_at(p) == "sealed":
			continue
		var kind_id: int = Item.Kind.get(String(o["kind"]), -1)
		if kind_id < 0:
			push_warning("Gebäudeplan: unbekannter Gegenstand „%s“ bei %s" % [o["kind"], p])
			continue
		var kind := kind_id as Item.Kind
		var content: Dictionary = CONTENT.get(_room_id_at(p), {})
		var extra := ""
		match kind:
			Item.Kind.COINS:
				extra = String(content.get("coins", "1"))
			Item.Kind.MAP:
				extra = String(content.get("map", "eg"))
			Item.Kind.KEY:
				extra = String(content.get("key", ""))
		_item(kind, Vector3(p.x, _top_at(p) + 0.02, p.y), extra)


## Lichter (Ebene „Lichter“): Wandleuchten an der Wand (Höhe und Helligkeit je Fläche, _lamp_style),
## Deckenleuchten an der Decke darüber, Kerzen auf dem Möbel darunter, Laternen im Garten. Defekt laut Plan.
func _lights() -> void:
	for o in _map["lights"]:
		var p := _v2(o["pos"])
		if _kind_at(p) == "sealed":
			continue
		var broken := bool(o.get("broken", false))
		match String(o["kind"]):
			"wall_lamp":
				var at := _wall_spot(o, WALL_GAP)
				var id := _light_room_at(at.inside)
				var style := _lamp_style(_kind_at(at.inside), id, at.side)
				var y: float = style["y"]
				if _kind_at(at.inside) == "stairs" and at.side == _landing_side(at.inside) and _level < _top_level:
					y += UP_Y / 2.0   # Podestseite: hängt über dem Wendepodest zum Stockwerk darüber
				_wall_lamp(at.at(y), at.yaw(), style["energy"], style["range"], id, broken)
			"ceiling_lamp":
				_ceiling_lamp(p, _light_room_at(p), broken)
			"halogen":
				_halogen(p, String(o.get("axis", "x")), float(o.get("length", 0.8)), _light_room_at(p), broken)
			"candle":
				_candle(Vector3(p.x, _top_at(p), p.y))
			"lantern":
				_lantern(Vector3(p.x, 0, p.y), broken, 1.0 if absf(p.x) < 15.0 else 0.8)   # in den Innenhöfen schwächer
			_:
				push_warning("Gebäudeplan: unbekanntes Licht „%s“ bei %s" % [o["kind"], p])


## Höhe, Helligkeit und Reichweite einer Wandleuchte je Flächenart (Spielkonzept 7.3): {y, energy, range}.
func _lamp_style(area: String, id: String, side: String) -> Dictionary:
	if id == "umkleiden":
		return {"y": 2.1, "energy": WALL_LAMP_ENERGY * 0.8, "range": 5.0}
	match area:
		"room":
			return {"y": 2.0, "energy": ROOM_LAMP_ENERGY, "range": 6.5}
		"lobby":   # große, hohe Halle: kräftiger, mehr Reichweite; über dem Eingang höher
			return {"y": 2.6 if side == "south" else 2.4, "energy": WALL_LAMP_ENERGY * 1.3, "range": 8.0}
		"pool":
			return {"y": 2.4, "energy": WALL_LAMP_ENERGY, "range": 7.0}
		"storage":
			return {"y": 2.1, "energy": WALL_LAMP_ENERGY * 0.8, "range": 5.0}
		"toilet":
			return {"y": 2.1, "energy": WALL_LAMP_ENERGY, "range": 5.0}
		"stairs":   # an der Podestseite eine halbe Etage höher (_lights)
			return {"y": 1.9, "energy": WALL_LAMP_ENERGY, "range": 6.0}
		"cat_room", "library":
			return {"y": 2.2, "energy": ROOM_LAMP_ENERGY, "range": 7.0}
		"bath":
			return {"y": 2.0, "energy": ROOM_LAMP_ENERGY, "range": 4.5}
	return {"y": 2.1, "energy": WALL_LAMP_ENERGY, "range": 6.0}


## Wand gegenüber der Tür des Treppenhauses, in dem p liegt – dort liegen die Wendepodeste („“ = keins).
func _landing_side(p: Vector2) -> String:
	for s in _map["stairs"]:
		var rc: Array = s["rect"]
		if s["kind"] == "stairwell" and s.has("door") and Rect2(rc[0], rc[1], rc[2] - rc[0], rc[3] - rc[1]).grow(0.3).has_point(p):
			match String(s["door"]["side"]):
				"south":
					return "north"
				"north":
					return "south"
				"east":
					return "west"
				"west":
					return "east"
	return ""


## Raum-ID für Lampen und Schalter: wie _room_id_at, nur teilen sich Umkleiden und Duschen einen Schalter.
func _light_room_at(p: Vector2) -> String:
	var id := _room_id_at(p)
	if id in CHANGING_ROOMS:
		return "umkleiden"
	if id == "treppenhaus_ost":
		return "treppenhaus"
	return String(_bath_owner.get(id, id))   # das Bad schaltet mit dem Zimmer


func _switch_label(id: String) -> String:
	if rooms.has(id):
		return "Zimmer " + String(rooms[id]["sign"])
	if _level != 0 and id.begins_with(_prefix()):
		var base := id.substr(_prefix().length())
		for c in _map["corridors"]:
			if c["id"] == base:
				return "%s (oben)" % c["name"]
		return _region_name(id)
	match id:
		"lobby":
			return "Lobby"
		"umkleiden":
			return "Umkleiden"
		"treppenhaus":
			return "Treppenhaus"
		"toilette_west", "toilette_ost":
			return "Toilette"
	for c in _map["corridors"]:
		if c["id"] == id:
			return String(c["name"])
	return _region_name(id)


## Wandsache o des Plans an ihre Wand setzen: Wandseite `wall`, Abstand gap vor der Wandfläche.
func _wall_spot(o: Dictionary, gap: float) -> WallSpot:
	var spot := WallSpot.new()
	var p := _v2(o["pos"])
	spot.side = String(o.get("wall", ""))
	if spot.side == "":
		push_warning("Gebäudeplan: %s bei %s liegt an keiner Wand" % [o["kind"], p])
		spot.side = "north"
	spot.out = -_dir(spot.side)
	var face := _on_wall(p, spot.side, 0.6)
	var on_face: Vector2 = face.get("pos", p - spot.out * 0.15)   # ohne Wandstück: der Punkt liegt an der Wand
	spot.pos = on_face + spot.out * gap
	spot.inside = p + spot.out * 0.3
	return spot


## Nächste Wandfläche von p aus in Richtung side (höchstens max_dist entfernt): {pos} oder {}.
func _on_wall(p: Vector2, side: String, max_dist: float) -> Dictionary:
	var dir := _dir(side)
	var horizontal := absf(dir.y) > 0.5   # Wand quer zu z → verläuft entlang x
	var s := p.x if horizontal else p.y
	var across := p.y if horizontal else p.x
	var toward := dir.y if horizontal else dir.x
	var best := {}
	var best_d := max_dist
	for w in _wall_index:
		if w["horizontal"] != horizontal or s < float(w["from"]) - 0.05 or s > float(w["to"]) + 0.05:
			continue
		var face := float(w["at"]) - toward * float(w["half"])
		var d := (face - across) * toward
		if d < -0.05 or d > best_d:
			continue
		best_d = d
		best = {"pos": Vector2(p.x, face) if horizontal else Vector2(face, p.y)}
	return best


## Himmelsrichtung → Richtung (x, z).
func _dir(side: String) -> Vector2:
	match side:
		"north":
			return Vector2(0, -1)
		"south":
			return Vector2(0, 1)
		"west":
			return Vector2(-1, 0)
	return Vector2(1, 0)


func _perpendicular(side: String) -> Array[String]:
	if side == "north" or side == "south":
		return ["west", "east"]
	return ["north", "south"]


## Vorderseite: Himmelsrichtung aus dem Plan, sonst zur Mitte der Fläche hin (auf eine Achse gerundet).
func _facing(side: String, p: Vector2) -> Vector2:
	if side != "":
		return _dir(side)
	var to := _area_center(p) - p
	if absf(to.x) > absf(to.y):
		return Vector2(signf(to.x), 0)
	return Vector2(0, -1 if to.y < 0 else 1)


## Blickrichtung für Telefon, Zettel und Tagebuch: in Zimmern vom Flur weg, sonst zur Mitte der Fläche.
func _upright_yaw(p: Vector2) -> float:
	var dir := _facing("", p)
	var room: Dictionary = rooms.get(_room_id_at(p), {})
	if not room.is_empty():
		var into: Vector3 = room["into"]
		dir = Vector2(into.x, into.z)
	return atan2(dir.x, dir.y)


func _area_center(p: Vector2) -> Vector2:
	var id := _room_id_at(p)
	if rooms.has(id):
		var c: Vector3 = rooms[id]["center"]
		return Vector2(c.x, c.z)
	if id == "lobby":
		return _lobby.get_center()
	if _named.has(id):
		return (_named[id] as Rect2).get_center()
	return p


## Oberkante des Möbels unter p (0 = Boden): darauf stehen Kerzen, Telefone und Gegenstände des Plans.
func _top_at(p: Vector2) -> float:
	var top := 0.0
	for f in _furnishings:
		if (f["rect"] as Rect2).grow(0.05).has_point(p):
			top = maxf(top, float(f["top"]))
	return top


## Erstes Möbel dieser Art in der benannten Fläche ({} = keins).
func _furnishing(kind: String, area: String) -> Dictionary:
	for f in _furnishings:
		if f["kind"] == kind and (_named[area] as Rect2).has_point((f["rect"] as Rect2).get_center()):
			return f
	return {}


# --- Lobby und Galerie ---------------------------------------------------------------------------------

## Lobby: Teppich vor der Rezeption, Liegeplatz der Katzen auf der Rezeption, Sitzplätze vor den Sofas,
## Schilder. Die Einrichtung steht im Plan.
func _lobby_hall() -> void:
	lobby_center = Vector3(_lobby.get_center().x, 0, _lobby.get_center().y)
	var west := _lobby.position.x
	var east := _lobby.end.x
	Geo.mesh(root, Geo.box(Vector3(6.0, 0.02, 8.0)), Mat.layer(Color(0.32, 0.07, 0.08)), Vector3(0, 0.01, -5.0))
	var front: Array = _map["reception"][0]
	for rc in _map["reception"]:
		if float(rc[2]) - float(rc[0]) > float(front[2]) - float(front[0]):
			front = rc
	var fz := (float(front[1]) + float(front[3])) / 2.0
	cat_perches.append({"floor": Vector3(2.9, 0, fz - 0.8), "top": Vector3(2.3, RECEPTION_H + 0.02, fz - 0.8), "yaw": PI / 2.0})
	# Vor jedem Sofa zwei Sitzplätze für Gäste, obendrauf zwei Liegeplätze für die Katzen
	for f in _furnishings:
		var c: Vector2 = (f["rect"] as Rect2).get_center()
		if f["kind"] != "couch" or not _lobby.has_point(c):
			continue
		var out: Vector2 = f["front"]
		for s: float in [-0.5, 0.5]:
			var seat := c + out * 0.7 + Vector2(-out.y, out.x) * s
			var top := c + out * 0.07 + Vector2(-out.y, out.x) * s
			lobby_seats.append(Vector3(seat.x, 0, seat.y))
			cat_perches.append({"floor": Vector3(seat.x, 0, seat.y), "top": Vector3(top.x, 0.46, top.y)})
	_clock()
	_sign("BAR", Vector3(west + 0.11, 2.75, -13.0), 90.0)
	_sign("PARTY", Vector3(east - 0.11, 2.75, -13.0), -90.0)
	_sign("GARTEN", Vector3(-5.5, 2.75, _lobby.position.y + 0.11), 0.0)
	_sign("POOL", Vector3(5.5, 2.75, _lobby.position.y + 0.11), 0.0)


## Wanduhr über dem Haupteingang (WallClock): Mitte über der Tür, Zifferblatt in die Lobby, ohne Kollision.
func _clock() -> void:
	for w in _map["walls"]:
		for o in w.get("openings", []):
			if o["kind"] != "main_entrance":
				continue
			var clock := WallClock.create(CLOCK_DIAMETER)
			if clock == null:
				return
			var a := _v2(w["a"])
			var along := (_v2(w["b"]) - a).normalized()
			var center := a + along * (float(o["at"]) + float(o["width"]) / 2.0)
			var into := Vector2(-along.y, along.x)   # Normale der Wand, zur Lobby hin gedreht
			if not _lobby.has_point(center + into * 0.5):
				into = -into
			var back := center + into * (float(w.get("thickness", T)) / 2.0 + CLOCK_GAP)
			var ceiling := UP_Y + H if _has_upper else H   # Halle über zwei Stockwerke (Luftraum)
			clock.position = Vector3(back.x, (_exit_sign_top + ceiling) / 2.0, back.y)
			clock.rotation.y = atan2(into.x, into.y)   # +Z der Uhr zeigt in die Lobby
			root.add_child(clock)
			return


func _void() -> Rect2:
	var rc: Array = _map["open_above"][0]
	return Rect2(rc[0], rc[1], rc[2] - rc[0], rc[3] - rc[1])


## Galerie im Obergeschoss rund um den Luftraum (Spielkonzept 7.5): Boden mit Geländer, Treppe hinauf,
## Wände bis zur Decke über dem Luftraum. Die Türen ins Obergeschoss sind noch gesperrt.
func _gallery() -> void:
	var void_rect := _void()
	var hall := Rect2(_lobby.position, _lobby.size)
	# Boden der Galerie = Decke der Lobby unter ihr (0,5 m dick, sonst klafft eine Fuge an der Kante)
	for piece in _subtract(hall, [void_rect]):
		Geo.solid(root, Vector3(piece.size.x, 0.5, piece.size.y), Vector3(piece.get_center().x, H + 0.25, piece.get_center().y), _ceiling, LAYER_CEILING)
		Geo.solid(root, Vector3(piece.size.x, 0.02, piece.size.y), Vector3(piece.get_center().x, UP_Y + 0.01, piece.get_center().y), _carpet)
	# Wände im Obergeschoss (über den Lobbywänden) und Decke über allem
	var top := UP_Y + H
	var x0 := hall.position.x - T / 2.0
	var x1 := hall.end.x + T / 2.0
	var z0 := hall.position.y - T / 2.0
	var z1 := hall.end.y + T / 2.0
	var upper := Node3D.new()
	upper.position.y = H
	root.add_child(upper)
	_parent = upper
	var door_bottom := UP_Y - H
	_wall_z(x0, z0, z1, [Vector4(-8.0, DOOR_W, door_bottom + DOOR_H, door_bottom)], _lobby_wallpaper, top - H)
	_wall_z(x1, z0, z1, [Vector4(-8.0, DOOR_W, door_bottom + DOOR_H, door_bottom)], _lobby_wallpaper, top - H)
	_wall_x(z0, x0 - T / 2.0, x1 + T / 2.0, [], _lobby_wallpaper, top - H)
	_wall_x(z1, x0 - T / 2.0, x1 + T / 2.0, [], _lobby_wallpaper, top - H)
	_parent = root
	# Holzleiste über der Fuge zwischen Lobbywand und Obergeschosswand (beide rasten beim Vertex-Snapping
	# für sich ein, dazwischen blitzte ein gezackter Spalt)
	var trim := OpeningFrame.trim_material()
	var c := hall.get_center()
	for z: float in [hall.position.y + 0.015, hall.end.y - 0.015]:
		Geo.mesh(root, Geo.box(Vector3(hall.size.x, 0.14, 0.03)), trim, Vector3(c.x, H, z))
	for x: float in [hall.position.x + 0.015, hall.end.x - 0.015]:
		Geo.mesh(root, Geo.box(Vector3(0.03, 0.14, hall.size.y)), trim, Vector3(x, H, c.y))
	Geo.solid(root, Vector3(hall.size.x + 0.4, 0.2, hall.size.y + 0.4), Vector3(hall.get_center().x, top + 0.1, hall.get_center().y), _ceiling, LAYER_CEILING)
	for x: float in [x0, x1]:
		var door := Door.new().setup(DOOR_W, DOOR_H, -100.0)
		var inward := 1.0 if x < 0 else -1.0   # +Z der Tür zeigt in die Galerie
		door.rotation.y = PI / 2.0 * inward
		door.position = Vector3(x, UP_Y, -8.0 + DOOR_W / 2.0 * inward)
		root.add_child(door)
		_seal(door, "Abgesperrt. Das Obergeschoss ist noch nicht zugänglich.")
	# Geländer an den offenen Kanten (die Treppe kommt im Nordwesten an)
	var stair: Dictionary = _lobby_stair()
	var stair_rect: Array = stair["rect"]
	_railing(Vector3(void_rect.position.x, UP_Y, void_rect.position.y), Vector3(void_rect.position.x, UP_Y, void_rect.end.y))
	_railing(Vector3(void_rect.end.x, UP_Y, void_rect.position.y), Vector3(void_rect.end.x, UP_Y, void_rect.end.y))
	_railing(Vector3(float(stair_rect[2]), UP_Y, void_rect.position.y), Vector3(void_rect.end.x, UP_Y, void_rect.position.y))
	# Treppe: vom Lobbyboden hinauf zur Galerie, oberes Ende laut Plan
	var up := String(stair.get("up", "north"))
	var sx := (float(stair_rect[0]) + float(stair_rect[2])) / 2.0
	var width := float(stair_rect[2]) - float(stair_rect[0])
	var z_low := float(stair_rect[3]) if up == "north" else float(stair_rect[1])
	var z_high := float(stair_rect[1]) if up == "north" else float(stair_rect[3])
	_flight(sx, z_low, z_high, 0.0, UP_Y, width)
	for x: float in [x0 + 0.12, x1 - 0.12]:
		_wall_lamp(Vector3(x, UP_Y + 2.0, -14.0), PI / 2.0 if x < 0 else -PI / 2.0, WALL_LAMP_ENERGY, 7.0, "galerie")
	_switch("galerie", "Galerie", Vector3(sx + width / 2.0 + 0.6, UP_Y + 1.3, hall.position.y + 0.12), 0.0)


func _lobby_stair() -> Dictionary:
	for s in _map["stairs"]:
		if s["kind"] == "stair":
			return s
	return {}


## Treppe von der Lobby hinauf zur Galerie, oberes Ende laut Plan (GrandStair: Wangentreppe mit Geländer, unten
## offen). Galerie, Geländer, Wände und Türen baut das Obergeschoss aus seinem Plan (_upper_floor).
func _lobby_flight() -> void:
	var stair := _lobby_stair()
	if stair.is_empty():
		return
	var rc: Array = stair["rect"]
	GrandStair.build(_parent, Rect2(rc[0], rc[1], rc[2] - rc[0], rc[3] - rc[1]), String(stair.get("up", "north")), UP_Y)


## Ränder der Lufträume dieses Stockwerks (Lobby, Partyraum): Geländer, wo Boden angrenzt – außer, wo eine Treppe
## von unten ankommt. Wo eine Wand angrenzt, nichts: Ihre Tapete läuft ohne Fuge von unten durch (_wall_side_kind).
func _void_edges() -> void:
	var stairs: Array[Rect2] = []
	for st in (_floors[0]["map"] as Dictionary)["stairs"]:
		if st["kind"] == "stair":
			var rc: Array = st["rect"]
			stairs.append(Rect2(rc[0], rc[1], rc[2] - rc[0], rc[3] - rc[1]).grow(0.05))
	for rc in _map["voids"]:
		var v := Rect2(rc[0], rc[1], rc[2] - rc[0], rc[3] - rc[1])
		var edges := [[v.position, Vector2(v.end.x, v.position.y), Vector2(0, -1)], [Vector2(v.position.x, v.end.y), v.end, Vector2(0, 1)],
			[v.position, Vector2(v.position.x, v.end.y), Vector2(-1, 0)], [Vector2(v.end.x, v.position.y), v.end, Vector2(1, 0)]]
		for e in edges:
			var a: Vector2 = e[0]
			var b: Vector2 = e[1]
			var out: Vector2 = e[2]
			var n := maxi(1, roundi(a.distance_to(b) / 0.25))
			var kinds: Array[String] = []
			for i in n:
				var on := a.lerp(b, (i + 0.5) / n)
				var beyond := on + out * 0.3
				var k := "floor"
				if stairs.any(func(r: Rect2) -> bool: return r.has_point(on)):
					k = "stair"
				elif _place_at(beyond).is_empty() or _kind_at(beyond) == "outside":
					k = "wall"
				kinds.append(k)
			var i0 := 0
			while i0 < n:
				var i1 := i0
				while i1 < n and kinds[i1] == kinds[i0]:
					i1 += 1
				var p0 := a.lerp(b, float(i0) / n)
				var p1 := a.lerp(b, float(i1) / n)
				if kinds[i0] == "floor":
					# Neben einer Treppe endet das Geländer genau an ihrer Kante – dort steht ihr oberer Pfosten
					var by_a := i0 > 0 and kinds[i0 - 1] == "stair"
					var by_b := i1 < n and kinds[i1] == "stair"
					if by_a:
						p0 = _stair_edge(p0, b - a, stairs)
					if by_b:
						p1 = _stair_edge(p1, b - a, stairs)
					GrandStair.railing(root, Vector3(p0.x, 0, p0.y), Vector3(p1.x, 0, p1.y), not by_a, not by_b)
				i0 = i1


## Punkt p auf einer Luftraumkante (Richtung along) an die nächste Seitenkante der Treppe daneben geschoben.
func _stair_edge(p: Vector2, along: Vector2, stairs: Array[Rect2]) -> Vector2:
	for grown in stairs:
		if grown.grow(0.3).has_point(p):
			var r := grown.grow(-0.05)
			if absf(along.x) > absf(along.y):
				return Vector2(r.position.x if absf(p.x - r.position.x) < absf(p.x - r.end.x) else r.end.x, p.y)
			return Vector2(p.x, r.position.y if absf(p.y - r.position.y) < absf(p.y - r.end.y) else r.end.y)
	return p


## Balkone und Terrassen über dem EG (Spielkonzept 7.7): Geländer auf den Kanten aus dem Plan.
func _balconies() -> void:
	for rs in _map["terrace_edges"] + _map.get("balcony_edges", []):
		for rc in rs:
			var r := Rect2(rc[0], rc[1], rc[2] - rc[0], rc[3] - rc[1])
			if r.size.x >= r.size.y:
				_railing(Vector3(r.position.x, 0, r.get_center().y), Vector3(r.end.x, 0, r.get_center().y))
			else:
				_railing(Vector3(r.get_center().x, 0, r.position.y), Vector3(r.get_center().x, 0, r.end.y))


## Zimmer ohne Lichtschalter im Plan (Obergeschoss): einer innen neben der Tür, auf der Griffseite (gegenüber dem
## Scharnier); unbewohnte Zimmer bleiben dunkel.
func _auto_switches() -> void:
	for info in _map["rooms"]:
		var no := String(info["no"])
		if _switched.has(no) or not _room_open(no) or not rooms.has(no):
			continue
		var entry := {}
		for d in _doors:
			if d["door"] == rooms[no]["door"]:
				entry = d
		if entry.is_empty():
			continue
		var door: Door = entry["door"]
		var center: Vector3 = entry["pos"]
		var into := _global_dir(rooms[no]["into"])
		var handle := (center - (entry["hinge"] as Vector3)).normalized()
		for side: float in [1.0, -1.0]:   # Griffseite, sonst neben dem Scharnier hinter dem Türblatt hervor
			var reach := door.width / 2.0 + (0.25 if side > 0 else door.width + 0.3)
			var p := center + handle * side * reach + into * (T / 2.0 + WALL_GAP)
			if _room_id_at(Vector2(p.x, p.z) + Vector2(into.x, into.z) * 0.3) != no:
				continue
			var sw := _switch(no, _switch_label(no), Vector3(p.x, SWITCH_Y, p.z), atan2(into.x, into.z))
			_switched[no] = true
			if rooms[no]["kind"] == "vacant":
				sw.set_on.call_deferred(false, true)
			break


## Richtung aus der Welt in den Rahmen dieses Stockwerks (nur Drehung – die Stockwerke sind nicht gedreht).
func _global_dir(v: Vector3) -> Vector3:
	return Vector3(v.x, 0, v.z).normalized()


## Säule bis unter die Galerie: quadratischer Sockel unten und oben, dazwischen ein runder Schaft (Terrazzo).
func _pillar(rect: Rect2) -> StaticBody3D:
	var c := rect.get_center()
	var body := StaticBody3D.new()
	body.collision_mask = 0
	body.position = Vector3(c.x, 0, c.y)
	root.add_child(body)
	var shaft_h := H - 2.0 * PILLAR_PLINTH.y
	for y: float in [PILLAR_PLINTH.y / 2.0, H - PILLAR_PLINTH.y / 2.0]:
		Geo.mesh(body, Geo.box(PILLAR_PLINTH), _pillar_stone, Vector3(0, y, 0))
		Geo.add_box_shape(body, PILLAR_PLINTH, Vector3(0, y, 0))
	Geo.mesh(body, Geo.cylinder(PILLAR_SHAFT_RADIUS, shaft_h, PILLAR_SHAFT_SEGMENTS), _pillar_stone, Vector3(0, H / 2.0, 0))
	var cs := CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	shape.radius = PILLAR_SHAFT_RADIUS
	shape.height = shaft_h
	cs.shape = shape
	cs.position = Vector3(0, H / 2.0, 0)
	body.add_child(cs)
	return body


## Kratzbaum (Spielkonzept 7.7): Plüschsockel, Sisalstämme, Zwischenetage mit Höhle, Liegefläche oben.
func _cat_tree(rect: Rect2) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.collision_mask = 0
	var c := rect.get_center()
	body.position = Vector3(c.x, 0, c.y)
	_parent.add_child(body)
	var w := minf(rect.size.x, rect.size.y)
	Geo.add_box_shape(body, Vector3(w * 0.8, CAT_TREE_TOP, w * 0.8), Vector3(0, CAT_TREE_TOP / 2.0, 0))
	var plush := Mat.psx(Color(0.6, 0.52, 0.45), "carpet", 1.0)
	var sisal := Mat.psx(Color(0.78, 0.68, 0.46))
	Geo.mesh(body, Geo.box(Vector3(w, 0.08, w)), plush, Vector3(0, 0.04, 0))
	Geo.mesh(body, Geo.cylinder(0.07, CAT_TREE_TOP, 6), sisal, Vector3(0, CAT_TREE_TOP / 2.0, 0))
	Geo.mesh(body, Geo.cylinder(0.06, 0.75, 6), sisal, Vector3(w * 0.3, 0.42, w * 0.3))
	Geo.mesh(body, Geo.box(Vector3(w * 0.65, 0.05, w * 0.55)), plush, Vector3(w * 0.12, 0.8, w * 0.12))
	Geo.mesh(body, Geo.box(Vector3(0.42, 0.34, 0.42)), plush, Vector3(-w * 0.2, 0.25, -w * 0.2))   # Höhle
	Geo.mesh(body, Geo.box(Vector3(0.24, 0.2, 0.02)), Mat.psx(Color(0.12, 0.1, 0.09)), Vector3(-w * 0.2, 0.22, -w * 0.2 + 0.215))
	Geo.mesh(body, Geo.box(Vector3(0.55, 0.06, 0.55)), plush, Vector3(0, CAT_TREE_TOP - 0.03, 0))
	return body


## Geländer von a nach b (Kollision 1 m hoch, Handlauf und Stäbe).
func _railing(a: Vector3, b: Vector3) -> void:
	var length := a.distance_to(b)
	if length < 0.1:
		return
	var holder := Node3D.new()
	holder.position = (a + b) / 2.0
	holder.rotation.y = atan2(b.x - a.x, b.z - a.z) - PI / 2.0
	root.add_child(holder)
	Geo.collider(holder, Vector3(length, 1.0, 0.1), Vector3(0, 0.5, 0))
	Geo.mesh(holder, Geo.box(Vector3(length, 0.06, 0.1)), _dark_wood, Vector3(0, 1.0, 0))
	var n := maxi(2, roundi(length / 0.5))
	for i in n + 1:
		Geo.mesh(holder, Geo.box(Vector3(0.04, 1.0, 0.04)), _dark_wood, Vector3(-length / 2.0 + length * i / n, 0.5, 0))


# --- Gemeinschaftsräume, Pool ---------------------------------------------------------------------------

## Was Bar, Partyraum und Küche über den Plan hinaus brauchen: Flaschen auf dem Barregal, Hocker vor der Theke
## (Spielkonzept 6.10), Tanzfläche mit Discokugel und Plattenspieler-Tisch, Treffpunkte für Gäste und Monster.
func _common_rooms() -> void:
	var shelf := _furnishing("shelf", "bar")
	if not shelf.is_empty():
		var r: Rect2 = shelf["rect"]
		var along := Vector2(1, 0) if r.size.x >= r.size.y else Vector2(0, 1)
		var length := maxf(r.size.x, r.size.y)
		var pack := (load(BOTTLES_MODEL) as PackedScene).instantiate()
		var bottles := pack.find_children("bottle_*", "MeshInstance3D", true, false)
		for i in 14:   # jede Flasche nur einmal (5 und 28 sind teilerfremd)
			var src: MeshInstance3D = bottles[i * 5 % bottles.size()]
			var p := r.get_center() + along * (-length / 2.0 + 0.3 + i * (length - 0.6) / 13.0)
			var bottle := Geo.mesh(root, src.mesh, Mat.model(BOTTLES_MODEL, src), Vector3(p.x, float(shelf["top"]), p.y))
			bottle.rotation.y = i * 1.3
		pack.free()
	var counter := _furnishing("bar_counter", "bar")
	if not counter.is_empty():
		var r: Rect2 = counter["rect"]
		var out: Vector2 = counter["front"]
		var along := Vector2(1, 0) if r.size.x >= r.size.y else Vector2(0, 1)
		var span := maxf(r.size.x, r.size.y) - 2.2
		for i in 4:
			var p := r.get_center() + along * (-span / 2.0 + i * span / 3.0)
			var stool := Geo.mesh(root, Geo.cylinder(0.18, 0.05, 8), Mat.psx(Color(0.4, 0.1, 0.1)), Vector3(p.x + out.x * 0.8, 0.7, p.y + out.y * 0.8))
			Geo.mesh(stool, Geo.cylinder(0.04, 0.7, 5), _dark_wood, Vector3(0, -0.35, 0))
			bar_spots.append(Vector3(p.x + out.x * 1.2, 0, p.y + out.y * 1.2))
		# Flasche und Glas zum Trinken (3.7): mitten auf der Theke, zur Gästeseite hin
		var tap := BarTap.new()
		var at := r.get_center() + out * (minf(r.size.x, r.size.y) / 2.0 - 0.18)
		tap.position = Vector3(at.x, float(counter["top"]), at.y)
		tap.rotation.y = atan2(-along.y, along.x)   # Flasche und Glas nebeneinander entlang der Theke
		root.add_child(tap)
	# Partyraum: Plattenspieler auf dem Tisch, dunkle Ecke (dort steht es beim ersten Angriff), Tanzfläche mit
	# Discokugel darüber
	var r: Rect2 = _named["partyraum"]
	var c := r.get_center()
	var table := _furnishing("table", "partyraum")
	if not table.is_empty():
		var t: Vector2 = (table["rect"] as Rect2).get_center()
		record_player_pos = Vector3(t.x, float(table["top"]), t.y)
	party_corner = Vector3(r.position.x + 0.9, 0, r.position.y + 0.9)
	Geo.mesh(root, Geo.box(Vector3(6.0, 0.02, 6.0)), Mat.layer(Color(0.12, 0.1, 0.16)), Vector3(c.x, 0.01, c.y))
	party_center = Vector3(c.x, 0, c.y)
	party_spots = _dance_spots(r, c)
	var top := H
	for rc in _map["open_above"]:
		if Rect2(rc[0], rc[1], rc[2] - rc[0], rc[3] - rc[1]).has_point(c):
			top = UP_Y + H
	var ball := DiscoBall.new().setup(top - DISCO_Y)
	ball.position = Vector3(c.x, DISCO_Y, c.y)
	root.add_child(ball)
	# Bunte Partylampen und Konfetti (Spielkonzept 7.6, 2026-10-21)
	root.add_child(PartyLights.new().setup(r, minf(top, H) - 0.35, party_center))
	root.add_child(Confetti.new())
	var k: Rect2 = _named["kueche"]
	kitchen_spot = Vector3(k.get_center().x, 0, k.get_center().y)
	# Herd zum Kochen (Spielkonzept 3.8)
	var stove_info := _furnishing("stove", "kueche")
	if not stove_info.is_empty():
		var sr: Rect2 = stove_info["rect"]
		var sf: Vector2 = stove_info["front"] if stove_info["front"] != Vector2.ZERO else Vector2(0, 1)
		var stove := Stove.new()
		stove.position = Vector3(sr.get_center().x, float(stove_info["top"]), sr.get_center().y)
		stove.rotation.y = atan2(sf.x, sf.y)
		stove.front = Vector3(sf.x, 0, sf.y)
		root.add_child(stove)


## Tanzplätze im Sechseckraster (DANCE_SPACING) über den ganzen Partyraum, die Mitte der Tanzfläche zuerst:
## 1 m Abstand zu den Wänden, 0,7 m zu Möbeln, die dunkle Ecke bleibt frei.
func _dance_spots(room: Rect2, c: Vector2) -> Array[Vector3]:
	var inner := room.grow(-1.0)
	var blockers: Array[Rect2] = []
	for f in _furnishings:
		var fr: Rect2 = f["rect"]
		if fr.intersects(room):
			blockers.append(fr.grow(0.7))
	var row_h := DANCE_SPACING * sqrt(3.0) / 2.0
	var rows := int(ceil(room.size.y / row_h))
	var cols := int(ceil(room.size.x / DANCE_SPACING))
	var corner := Vector2(party_corner.x, party_corner.z)
	var spots: Array[Vector3] = []
	for j in range(-rows, rows + 1):
		for i in range(-cols, cols + 1):
			var p := c + Vector2((i + 0.5 * (absi(j) % 2)) * DANCE_SPACING, j * row_h)
			if not inner.has_point(p) or p.distance_to(corner) < 2.0:
				continue
			if blockers.any(func(b: Rect2) -> bool: return b.has_point(p)):
				continue
			spots.append(Vector3(p.x, 0, p.y))
	spots.sort_custom(func(a: Vector3, b: Vector3) -> bool:
		return a.distance_squared_to(party_center) < b.distance_squared_to(party_center))
	return spots


func _region_name(id: String) -> String:
	var base := id.substr(_prefix().length()) if id.begins_with(_prefix()) else id
	for r in _map["regions"]:
		if r["id"] == base:
			return String(r.get("name", KIND_NAMES.get(String(r["kind"]), base)))
	return id


## Hallenbad: Becken 1,4 m tief mit Wasseroberfläche. An beiden Schmalseiten führt eine Einstiegstreppe
## mit Handlauf hinaus – hochspringen reicht nicht (Sprung ≈ 0,7 m).
func _pool() -> void:
	var w: Rect2 = _named["becken"]
	var depth := 1.4
	Geo.solid(root, Vector3(w.size.x, 0.2, w.size.y), Vector3(w.get_center().x, -depth - 0.1, w.get_center().y), _pool_tiles)
	# Beckenränder innerhalb der Wasserfläche (der Umgang endet an ihrer Kante); ihre Oberseite ist der geflieste Rand
	for s: float in [-1.0, 1.0]:
		Geo.solid(root, Vector3(w.size.x, depth, 0.2), Vector3(w.get_center().x, -depth / 2.0, w.get_center().y + s * (w.size.y / 2.0 - 0.1)), _pool_tiles)
		Geo.solid(root, Vector3(0.2, depth, w.size.y - 0.4), Vector3(w.get_center().x + s * (w.size.x / 2.0 - 0.1), -depth / 2.0, w.get_center().y), _pool_tiles)
	# Einstiegstreppen: von der Südkante entlang der West- bzw. Ostwand hinab, Handlauf an der offenen Seite. 7 Stufen
	# à 20 cm hoch und 30 cm tief: Kanten und Stufenflächen liegen auf dem 10-cm-Raster der Beckenfliesen
	var stair_w := 1.2
	var run := 2.1
	var z_top := w.end.y - 0.2
	var chrome := Mat.metal()   # Edelstahl
	for s: float in [-1.0, 1.0]:
		var x := w.get_center().x + s * (w.size.x / 2.0 - 0.2 - stair_w / 2.0)
		_flight(x, z_top, z_top - run, 0.0, -depth, stair_w, _pool_tiles, 0.2)
		var xr := x - s * (stair_w / 2.0 - 0.08)
		if ResourceLoader.exists(HANDRAIL_MODEL):
			var rail: Node3D = (load(HANDRAIL_MODEL) as PackedScene).instantiate()
			rail.position = Vector3(xr, 0.0, z_top + 0.35)
			root.add_child(rail)
			for m: MeshInstance3D in rail.find_children("*", "MeshInstance3D", true, false):
				m.material_override = chrome
			continue
		var top := Vector3(xr, 0.9, z_top + 0.35)
		var bend := Vector3(xr, 0.9, z_top - 0.1)
		var low := Vector3(xr, -depth + 0.9, z_top - run + 0.2)
		_rod(Vector3(top.x, 0.0, top.z), top, chrome)
		_rod(top, bend, chrome)
		_rod(bend, low, chrome)
		_rod(low, Vector3(low.x, -depth, low.z), chrome)
	# Unterwasserlampen: gleichmäßig verteilt in beiden Längswänden, am Schalter der Halle
	var long_x := w.size.x >= w.size.y
	var length := w.size.x if long_x else w.size.y
	var room_id := _light_room_at((_named["pool"] as Rect2).position + Vector2(0.5, 0.5))   # Umgang, nicht das Becken
	for s: float in [-1.0, 1.0]:
		for i in POOL_LAMPS_PER_SIDE:
			var along := (i + 1.0) / (POOL_LAMPS_PER_SIDE + 1.0) * length - length / 2.0
			var across := s * ((w.size.y if long_x else w.size.x) / 2.0 - 0.2)
			var p := w.get_center() + (Vector2(along, across) if long_x else Vector2(across, along))
			var lamp := Lamp.new().setup(Lamp.Style.POOL, room_id, POOL_LAMP_ENERGY, POOL_LAMP_RANGE, false)
			lamp.position = Vector3(p.x, POOL_LAMP_Y, p.y)
			# lokale +Z zeigt ins Becken
			lamp.rotation.y = (PI if s > 0.0 else 0.0) if long_x else (-PI / 2.0 if s > 0.0 else PI / 2.0)
			root.add_child(lamp)
	# Wasser: halbtransparent, Wellen rein optisch (PoolWater)
	root.add_child(PoolWater.new(w, -0.3, 0.2, _named["pool"]))


## Dünne Stange von a nach b (Handlauf, Geländerpfosten), ohne Kollision.
func _rod(a: Vector3, b: Vector3, mat: Material, radius: float = 0.025) -> void:
	var mi := Geo.mesh(root, Geo.cylinder(radius, a.distance_to(b), 6), mat, (a + b) / 2.0)
	var up := (b - a).normalized()
	var side := up.cross(Vector3.FORWARD if absf(up.z) < 0.9 else Vector3.RIGHT).normalized()
	mi.basis = Basis(side, up, side.cross(up))


# --- Gärten -----------------------------------------------------------------------------------------

func _gardens() -> void:
	_garden_beds()
	for t in _map["trees"]:
		_tree(_v3(t["center"]), float(t["radius"]))
	var has_model := ResourceLoader.exists(PLANTER_MODEL)
	for rc in _map["planters"]:
		var size := Vector2(float(rc[2]) - float(rc[0]), float(rc[3]) - float(rc[1]))
		var c := Vector3((float(rc[0]) + float(rc[2])) / 2.0, 0, (float(rc[1]) + float(rc[3])) / 2.0)
		if has_model:
			_planter(c, size)
		else:
			Geo.solid(root, Vector3(size.x, PLANTER_H, size.y), c + Vector3(0, PLANTER_H / 2.0, 0), _stone)
			Geo.mesh(root, Geo.sphere(size.x * 0.4, 1.2, 7, 4), _hedge, c + Vector3(0, PLANTER_H + 0.5, 0))
	for rs in _map["terrace_edges"]:
		for rc in rs:
			Geo.mesh(root, Geo.box(Vector3(float(rc[2]) - float(rc[0]), 0.25, float(rc[3]) - float(rc[1]))), _hedge,
				Vector3((float(rc[0]) + float(rc[2])) / 2.0, 0.125, (float(rc[1]) + float(rc[3])) / 2.0))


## Pflanzkübel aus `PLANTER_MODEL` auf der Bodenmitte c; Kollision (auch für das NavMesh) nur als Quader
## über die Grundfläche aus dem Plan, die Bepflanzung darüber bleibt durchlässig wie beim Platzhalter.
func _planter(c: Vector3, size: Vector2) -> void:
	var body := Geo.collider(root, Vector3(size.x, PLANTER_H, size.y), c + Vector3(0, PLANTER_H / 2.0, 0))
	var model: Node3D = (load(PLANTER_MODEL) as PackedScene).instantiate()
	model.position.y = -PLANTER_H / 2.0
	body.add_child(model)
	for m: MeshInstance3D in model.find_children("*", "MeshInstance3D", true, false):
		for s in m.mesh.get_surface_count():
			m.set_surface_override_material(s, Mat.model(PLANTER_MODEL, m, s, true))   # einseitige Blätter


## Kürbisbeete unter den Pflanzen des Plans (je Reihe ein Beet) und davor die Plätze, an denen Gäste im Garten
## stehen – das Beet nächst der Lobby zuerst.
func _garden_beds() -> void:
	var rows := {}   # z → x der Pflanzen
	for o in _map["fittings"]:
		if String(o["kind"]).begins_with("pumpkin_plant"):
			var z := snappedf(float(o["pos"][1]), 0.5)
			if not rows.has(z):
				rows[z] = []
			(rows[z] as Array).append(float(o["pos"][0]))
	var order := rows.keys()
	order.sort_custom(func(a: float, b: float) -> bool: return absf(a - _lobby.position.y) < absf(b - _lobby.position.y))
	var dirt := Mat.psx(Color(0.22, 0.14, 0.08))
	for z: float in order:
		var xs: Array = rows[z]
		var x0: float = xs.min()
		var x1: float = xs.max()
		Geo.mesh(root, Geo.box(Vector3(x1 - x0 + 1.6, 0.06, 1.3)), dirt, Vector3((x0 + x1) / 2.0, 0.03, z))
		garden_spots.append(Vector3((x0 + x1) / 2.0, 0, z + 1.0))


## Baum mit Krone in der Größe des Plans (radius = Kronenradius). Kollision nur am Stamm, unter der Krone
## kann man durchgehen.
func _tree(pos: Vector3, radius: float) -> void:
	if ResourceLoader.exists(TREE_MODEL):
		var s := radius / TREE_RADIUS
		var body := Geo.collider(root, Vector3(TREE_TRUNK * s, TREE_TRUNK_H, TREE_TRUNK * s), pos + Vector3(0, TREE_TRUNK_H / 2.0, 0))
		var model: Node3D = (load(TREE_MODEL) as PackedScene).instantiate()
		model.position.y = -TREE_TRUNK_H / 2.0
		model.scale = Vector3.ONE * s
		body.add_child(model)
		for m: MeshInstance3D in model.find_children("*", "MeshInstance3D", true, false):
			for i in m.mesh.get_surface_count():
				m.set_surface_override_material(i, Mat.model(TREE_MODEL, m, i, true))   # offene Blattbüschel
		_falling_leaves(pos, radius, TREE_HEIGHT * s)
		return
	var height := clampf(radius * 1.1, 3.2, 6.0)
	_falling_leaves(pos, radius, height + radius * 0.45)
	var trunk := Geo.solid(root, Vector3(0.5, height, 0.5), pos + Vector3(0, height / 2.0, 0), Mat.psx(Color(0.22, 0.15, 0.1)))
	var colors: Array[Color] = [Color(0.6, 0.25, 0.05), Color(0.7, 0.4, 0.08), Color(0.45, 0.12, 0.05)]
	var offsets: Array[Vector3] = [Vector3(0, height / 2.0, 0), Vector3(radius * 0.35, height / 2.0 - 0.6, radius * 0.2), Vector3(-radius * 0.3, height / 2.0 - 0.4, -radius * 0.25)]
	for i in 3:
		Geo.mesh(trunk, Geo.sphere(radius * (0.7 - i * 0.12), radius * (0.9 - i * 0.12), 8, 4), Mat.psx(colors[i]), offsets[i])


## Herbstlaub löst sich aus der Krone, sinkt schaukelnd und trudelnd und bleibt kurz flach am Boden liegen
## (floor_y im Partikel-Shader), bevor es verblasst.
func _falling_leaves(pos: Vector3, radius: float, height: float) -> void:
	var mat := Mat.particle(_leaf_texture(), LEAF_GLOW)
	mat.set_shader_parameter("sway", 0.25)
	mat.set_shader_parameter("sway_cycles", 6.0)
	mat.set_shader_parameter("spin", 3.0)
	mat.set_shader_parameter("floor_y", pos.y + 0.03)
	var leaves := Geo.particles(LEAF_FALL, LEAF_LIFE, LEAF_SIZE, mat, 0.03, 0.2)
	var colors := Gradient.new()
	colors.interpolation_mode = Gradient.GRADIENT_INTERPOLATE_CONSTANT
	colors.offsets = PackedFloat32Array([0.0, 0.25, 0.5, 0.75])
	colors.colors = PackedColorArray(LEAF_COLORS)
	leaves.color_initial_ramp = colors
	leaves.position = pos + Vector3(0, height * (TREE_CROWN.x + TREE_CROWN.y) / 2.0, 0)
	leaves.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	leaves.emission_box_extents = Vector3(radius * 0.75, height * (TREE_CROWN.y - TREE_CROWN.x) / 2.0, radius * 0.75)
	leaves.direction = Vector3.DOWN
	leaves.spread = 20.0
	leaves.gravity = Vector3.ZERO
	leaves.initial_velocity_min = LEAF_SPEED.x
	leaves.initial_velocity_max = LEAF_SPEED.y
	leaves.scale_amount_min = 0.7
	leaves.scale_amount_max = 1.2
	leaves.preprocess = LEAF_LIFE   # beim Betreten des Gartens liegt schon Laub
	leaves.emitting = true
	world.add_child(leaves)   # nicht unter root: das NavMesh liest dort die Geometrie


## Blatt 12 × 12 px, diagonal: Linse mit Stiel, die Mittelrippe etwas dunkler – weiß, die Farbe kommt
## vom Partikel. Für alle Bäume dasselbe Bild.
func _leaf_texture() -> ImageTexture:
	if _leaf_tex:
		return _leaf_tex
	const N := 12
	var img := Image.create(N, N, false, Image.FORMAT_RGBA8)
	for y in N:
		for x in N:
			var u := (x + 0.5) / N * 2.0 - 1.0
			var v := (y + 0.5) / N * 2.0 - 1.0
			var along := (u - v) / sqrt(2.0)    # von unten links nach oben rechts
			var across := (u + v) / sqrt(2.0)
			var leaf := absf(across) < 0.42 * (1.0 - along * along) and along < 0.85
			var stem := along >= 0.6 and along < 1.0 and absf(across) < 0.12
			if leaf or stem:
				var g := 0.75 if absf(across) < 0.1 else 1.0
				img.set_pixel(x, y, Color(g, g, g))
	_leaf_tex = ImageTexture.create_from_image(img)
	return _leaf_tex


func _lantern(pos: Vector3, broken: bool, energy: float) -> void:
	Geo.solid(root, Vector3(0.12, 2.4, 0.12), pos + Vector3(0, 1.2, 0), Mat.psx(Color(0.1, 0.1, 0.1)))
	var mat := Mat.psx(Color(1, 0.95, 0.8), "", 1.0, Color(1.0, 0.8, 0.5), 2.5, false)
	Geo.mesh(root, Geo.box(Vector3(0.25, 0.3, 0.25)), mat, pos + Vector3(0, 2.55, 0))
	var light := FlickerLight.new()
	light.position = pos + Vector3(0, 2.3, 0)
	light.base_energy = energy * Lamp.BRIGHTNESS
	light.omni_range = 6.0 * Lamp.REACH
	light.light_color = Color(1.0, 0.75, 0.45)
	light.shadow_enabled = true
	light.broken = broken
	light.lamp_material = mat
	light.add_to_group("lamps")
	root.add_child(light)


# --- Treppenhäuser und Keller -----------------------------------------------------------------------

## Treppenhaus Ost: Schacht vom Keller bis unters oberste Stockwerk, je zwei Läufe mit Wendepodest gegenüber der
## Tür. Gebaut im Rahmen des Schachts (_index_shafts: lokal −Z von der Tür zum Podest) – jede Ausrichtung geht.
## Stufen und Podeste folgen den Treppenstufen im Plan. Die eine Hälfte steigt nach oben, die andere führt hinab
## in den Keller. Das Treppenhaus West ist in dieser Bauphase verschlossen.
func _stairwells() -> void:
	for id: String in _shafts:
		var sh: Dictionary = _shafts[id]
		var s: Dictionary = sh["plan"]
		var door := _door_near(_v3(s["door"]["pos"]), 0.8) if s.has("door") else null
		if id != "treppenhaus_ost":
			if door:
				_seal(door, "Das Treppenhaus ist abgesperrt.")
			continue
		var frame := Node3D.new()
		frame.name = "Treppenhaus"
		frame.transform = sh["frame"]
		root.add_child(frame)
		_parent = frame
		var inv := (sh["frame"] as Transform3D).affine_inverse()
		var r: Rect2 = sh["rect"]
		var c0 := inv * Vector3(r.position.x, 0, r.position.y)
		var c1 := inv * Vector3(r.end.x, 0, r.end.y)
		var x0 := minf(c0.x, c1.x)
		var x1 := maxf(c0.x, c1.x)
		var zn := minf(c0.z, c1.z)   # Podestseite
		var zs := maxf(c0.z, c1.z)   # Türseite
		var z_door := zs - 1.4       # Ende der Türzone
		var z_land := zn + 1.5       # Beginn des Podests
		if s.has("steps"):
			var st: Array = s["steps"]
			var s0 := inv * Vector3(st[0], 0, st[1])
			var s1 := inv * Vector3(st[2], 0, st[3])
			z_land = minf(s0.z, s1.z)
			z_door = maxf(s0.z, s1.z)
		var mid := (x0 + x1) / 2.0
		var lane_w := (x1 - x0 - T) / 2.0
		var west := x0 + lane_w / 2.0
		var east := x1 - lane_w / 2.0
		var bottom := CELLAR_Y
		var top := UP_Y + H
		stairwell_point = frame.transform * Vector3(mid, 0, (zn + zs) / 2.0)
		# Böden: Türzone in jedem Geschoss, Schachtboden ganz unten, Podeste
		Geo.solid(frame, Vector3(x1 - x0, 0.2, zs - z_door), Vector3(mid, -0.1, (zs + z_door) / 2.0), _wood_floor)
		Geo.solid(frame, Vector3(x1 - x0, 0.2, zs - zn), Vector3(mid, bottom - 0.1, (zs + zn) / 2.0), _cellar_floor)
		Geo.solid(frame, Vector3(x1 - x0, 0.2, zs - z_door), Vector3(mid, UP_Y - 0.1, (zs + z_door) / 2.0), _wood_floor)
		Geo.solid(frame, Vector3(x1 - x0, 0.2, z_land - zn), Vector3(mid, UP_Y / 2.0 - 0.1, (zn + z_land) / 2.0), _wood_floor)
		Geo.solid(frame, Vector3(x1 - x0, 0.2, z_land - zn), Vector3(mid, bottom / 2.0 - 0.1, (zn + z_land) / 2.0), _concrete)
		Geo.solid(frame, Vector3(x1 - x0 + 0.4, 0.2, zs - zn + 0.4), Vector3(mid, top + 0.1, (zs + zn) / 2.0), _ceiling, LAYER_CEILING)
		# Läufe: hinauf auf der einen Seite und zurück auf der anderen; hinab umgekehrt
		_flight(west, z_door, z_land, 0.0, UP_Y / 2.0, lane_w)
		_flight(east, z_land, z_door, UP_Y / 2.0, UP_Y, lane_w)
		_flight(east, z_door, z_land, 0.0, bottom / 2.0, lane_w)
		_flight(west, z_land, z_door, bottom / 2.0, bottom, lane_w)
		# Mittelwand zwischen den Läufen über alle Geschosse (die Mittelwand im Untergeschoss grau); die Schachtwände
		# bauen die Pläne, ohne Obergeschoss-Plan baut sie der Schacht über dem Erdgeschoss
		Geo.solid(frame, Vector3(T, -bottom, z_door - z_land), Vector3(mid, bottom / 2.0, (z_door + z_land) / 2.0), _cellar_wall)
		Geo.solid(frame, Vector3(T, top, z_door - z_land), Vector3(mid, top / 2.0, (z_door + z_land) / 2.0), _wallpaper)
		if not _has_upper:
			var holder := Node3D.new()
			holder.position.y = H
			frame.add_child(holder)
			_parent = holder
			_wall_x(zs + T / 2.0, x0 - T, x1 + T, [Vector4(east, DOOR_W, UP_Y - H + DOOR_H, UP_Y - H)], _wallpaper, top - H)
			_wall_x(zn - T / 2.0, x0 - T, x1 + T, [], _wallpaper, top - H)
			_wall_z(x0 - T / 2.0, zn, zs, [], _wallpaper, top - H)
			_wall_z(x1 + T / 2.0, zn, zs, [], _wallpaper, top - H)
			_parent = frame
			# die gesperrte Tür nach oben
			var og := Door.new().setup(DOOR_W, DOOR_H, -100.0)
			og.position = Vector3(east + DOOR_W / 2.0, UP_Y, zs + T / 2.0)
			og.rotation.y = PI
			frame.add_child(og)
			_seal(og, "Abgesperrt. Das Obergeschoss ist noch nicht zugänglich.")
		_sign("TREPPENHAUS", Vector3(mid, 2.9, zs + T / 2.0 + 0.11), 0.0)
		# Leuchten: die Pläne setzen sie (Podestseite = eine halbe Etage höher, _lights); das Podest zum Untergeschoss
		# steht in keinem Plan, und wo ein Plan nichts setzt, hängt eine Ersatzleuchte
		_wall_lamp(Vector3(mid, bottom / 2.0 + 1.9, zn + WALL_GAP), 0.0, WALL_LAMP_ENERGY, 6.0, "treppenhaus")
		if not _plan_has_lamp(_map, r):
			_wall_lamp(Vector3(mid, UP_Y / 2.0 + 1.9, zn + WALL_GAP), 0.0, WALL_LAMP_ENERGY, 6.0, "treppenhaus")
		if _upper_plans.is_empty() or not _plan_has_lamp(_upper_plans[0], r):
			_wall_lamp(Vector3(x1 - WALL_GAP, UP_Y + 1.9, z_door - 0.4), -PI / 2.0, WALL_LAMP_ENERGY, 6.0, "treppenhaus")
		_parent = root


## Setzt der Plan eine Wandleuchte in das Rechteck r?
func _plan_has_lamp(plan: Dictionary, r: Rect2) -> bool:
	for o in plan["lights"]:
		if o["kind"] == "wall_lamp" and r.grow(0.3).has_point(_v2(o["pos"])):
			return true
	return false


## Ein gerader Treppenlauf entlang z von (z_from, y_from) nach (z_to, y_to) im aktuellen Rahmen; Stufenhöhe
## ungefähr step_h (gerundet auf ganze Stufen).
func _flight(x: float, z_from: float, z_to: float, y_from: float, y_to: float, width: float = 1.4, mat: Material = null,
		step_h: float = 0.25) -> void:
	if y_to < y_from:
		_flight(x, z_to, z_from, y_to, y_from, width, mat, step_h)   # abwärts = derselbe Lauf von unten gesehen
		return
	var run := absf(z_to - z_from)
	var rise := y_to - y_from
	var angle := atan2(rise, run)
	var dir := signf(z_to - z_from)   # Laufrichtung in z
	var ramp := StaticBody3D.new()
	ramp.collision_layer = 1
	ramp.collision_mask = 0
	ramp.rotation.x = angle * -dir
	ramp.position = Vector3(x, (y_from + y_to) / 2.0, (z_from + z_to) / 2.0)
	ramp.position -= ramp.transform.basis.y * 0.1
	ramp.set_meta("stair_ramp", true)
	_parent.add_child(ramp)
	Geo.add_box_shape(ramp, Vector3(width, 0.2, Vector2(run, rise).length()), Vector3.ZERO)
	var treads := StaticBody3D.new()
	treads.collision_layer = LAYER_TREAD
	treads.collision_mask = 0
	_parent.add_child(treads)
	var steps := roundi(rise / step_h)
	var step_rise := rise / steps
	for i in steps:
		var y_top := y_from + step_rise * (i + 0.5)
		var z := z_from + dir * run * (i + 0.5) / steps
		Geo.mesh(_parent, Geo.box(Vector3(width, y_top - y_from + 0.05, run / steps)), mat if mat else _concrete, Vector3(x, (y_top + y_from - 0.05) / 2.0, z))
		Geo.add_box_shape(treads, Vector3(width, 0.05, run / steps), Vector3(x, y_top - 0.025, z))


## Heizkeller im Untergeschoss (Spielkonzept 7.9): Versteck des Monsters, mit allem, was früher im Keller unter dem
## Treppenhaus lag – Kisten, altes Regal, Schlüssel zu Zimmer 18, Münzen, Batterie, Zettel 2011, UV-Schrift von 1987,
## Spinnweben, alte Deko (5.7), die kaputte Kellerleuchte und ihr Schalter. Der Eingang liegt laut Plan im Norden
## (schmaler Gang zwischen zwei Kellerräumen); die Sachen stehen in der Halle an der Südwand, weg von der Tür.
func _boiler_room() -> void:
	var hall := _largest_rect("boiler_room")
	if not hall.has_area():
		push_warning("Gebäudeplan: Untergeschoss ohne Heizkeller")
		return
	var w := hall.position.x   # Innenflächen der Wände
	var e := hall.end.x
	var n := hall.position.y
	var s := hall.end.y        # Südwand, gegenüber dem Eingang
	var c := hall.get_center()
	_cellar_center = Vector3(c.x, CELLAR_Y, c.y)
	_wall_lamp(Vector3(c.x - 6.0, 2.1, n + WALL_GAP), 0.0, 0.6, 6.0, "keller", true)   # kaputte Birne, blitzt nur auf
	for r in _map["regions"]:   # Schalter im Eingangsgang, an der Ostwand neben der Tür
		if r["kind"] == "boiler_room":
			for rc in r["rects"]:
				if float(rc[3]) <= n + 0.01:
					_switch("keller", "Heizkeller", Vector3(float(rc[2]) - 0.02, SWITCH_Y, float(rc[1]) + 1.6), -PI / 2.0)
	Geo.solid(root, Vector3(0.7, 0.7, 0.7), Vector3(e - 0.8, 0.35, s - 0.8), _dark_wood)
	Geo.solid(root, Vector3(0.6, 0.6, 0.6), Vector3(w + 0.7, 0.3, s - 0.7), _dark_wood)
	Geo.solid(root, Vector3(0.6, 0.45, 0.6), Vector3(w + 1.45, 0.225, s - 0.6), _dark_wood)
	Geo.solid(root, Vector3(0.5, 1.6, 1.8), Vector3(w + 0.27, 0.8, c.y + 1.0), _wood)   # altes Regal
	_item(Item.Kind.KEY, Vector3(e - 0.8, 0.72, s - 0.8), "zimmer_18")
	_item(Item.Kind.COINS, Vector3(c.x + 1.5, 0.02, n + 1.2), "2")
	_item(Item.Kind.BATTERY, Vector3(w + 0.3, 1.61, c.y + 1.4))   # auf dem alten Regal
	_note("2011", Vector3(w + 0.7, 0.61, s - 0.7))
	_uv_writing("31.10.1987\nSIE HABEN IHN\nEINGESCHLOSSEN", Vector3(c.x, 1.5, s - 0.01), PI)
	_resource_web(Vector3(e - 0.5, 1.7, s - 0.02), PI)
	_resource_web(Vector3(w + 1.0, 1.7, n + 0.02), 0.0)
	# Alte Halloween-Deko früherer Jahre (Spielkonzept 5.7) – im Versteck des Monsters
	var old := ResourceSpot.new().setup(Item.Kind.BROOM, "Alte Deko", 3, 900.0) \
		.with_pool([Item.Kind.SKULL, Item.Kind.BROOM, Item.Kind.BAT_GARLAND])
	old.position = Vector3(w + 1.45, 0.45, s - 0.6)
	old.rotation.y = PI / 2.0
	root.add_child(old)


## Wäscherei im Untergeschoss (Spielkonzept 7.9): an beiden Längswänden eine Reihe Waschmaschinen (nicht im Plan),
## das Bullauge zur Raummitte.
func _laundry_room() -> void:
	var room := _largest_rect("laundry_room")
	if not room.has_area():
		return
	var along_z := room.size.y >= room.size.x
	var size := 0.6
	var step := 0.65
	var height: float = BOX_HEIGHTS["washing_machine"]
	var c := room.get_center()
	for side: float in [-1.0, 1.0]:
		for i in WASHERS_PER_WALL:
			var t := step * (i - (WASHERS_PER_WALL - 1) / 2.0)
			var p := Vector2(c.x + side * (room.size.x / 2.0 - size / 2.0 - 0.05), c.y + t)
			var front := Vector2(-side, 0)
			if not along_z:
				p = Vector2(c.x + t, c.y + side * (room.size.y / 2.0 - size / 2.0 - 0.05))
				front = Vector2(0, -side)
			var rect := Rect2(p - Vector2.ONE * size / 2.0, Vector2.ONE * size)
			var node := _box_furniture("washing_machine", rect, height, front)
			_furnishings.append({"kind": "washing_machine", "rect": rect, "top": height, "front": front, "node": node})


## Größtes Rechteck einer Fläche dieser Art im geladenen Plan (Rect2() = keine).
func _largest_rect(kind: String) -> Rect2:
	var best := Rect2()
	for r in _map["regions"]:
		if r["kind"] != kind:
			continue
		for rc in r["rects"]:
			var rect := Rect2(rc[0], rc[1], rc[2] - rc[0], rc[3] - rc[1])
			if rect.get_area() > best.get_area():
				best = rect
	return best


# --- Zonen & Wegpunkte ------------------------------------------------------------------------------

func _zones() -> void:
	zones = [
		{"name": "Lobby", "center": lobby_center, "radius": 10.0},
		{"name": "Galerie", "center": lobby_center + Vector3(0, UP_Y, 0), "radius": 10.0},
		{"name": "Treppenhaus", "center": stairwell_point, "radius": 4.0},
	]
	for id in _named:
		var r: Rect2 = _named[id]
		zones.append({"name": _region_name(id), "center": Vector3(r.get_center().x, 0, r.get_center().y), "radius": minf(r.size.x, r.size.y) / 2.0 + 0.5})
	for r in _map["regions"]:
		if r["kind"] == "garden":
			var b := _bounds(r["rects"])
			zones.append({"name": _garden_name(b.get_center()), "center": Vector3(b.get_center().x, 0, b.get_center().y), "radius": minf(b.size.x, b.size.y) / 2.0})
	# Flurabschnitte: lange Flure als Kette von Kreisen
	for c in _map["corridors"]:
		var a := _v2(c["a"])
		var b := _v2(c["b"])
		var n := maxi(1, ceili(a.distance_to(b) / 12.0))
		for i in n:
			var p := a.lerp(b, (i + 0.5) / n)
			zones.append({"name": String(c["name"]), "center": Vector3(p.x, 0, p.y), "radius": a.distance_to(b) / n / 2.0 + 1.0})
	for level in range(1, _top_level + 1):
		_on_floor(level, _upper_zones)
	_on_floor(_lower, _lower_zones)
	for no in rooms:
		var info: Dictionary = rooms[no]
		zones.append({"name": "Zimmer " + String(info["sign"]), "center": info["center"], "radius": 3.2})
	for zone in zones:
		zone["curiosity"] = 50.0
	spawn_points = [
		cellar_center() + Vector3(0, 0.05, 0),                             # Heizkeller – das Versteck des Monsters
		(rooms["0117"]["center"] as Vector3) + Vector3(0, 0.05, 0),        # verlassenes Zimmer
		(rooms["0116"]["center"] as Vector3) + Vector3(0, 0.05, 0),        # Wäscherei
		garden_spots[0] + Vector3(0, 0.05, -12.0),                         # Garten
	]


## Zonen eines oberen Stockwerks (Plan geladen): Katzenraum, Bibliothek und die Flure.
func _upper_zones() -> void:
	for r in _map["regions"]:
		var kind := String(r["kind"])
		if kind in ["cat_room", "library"]:
			var b := _bounds(r["rects"])
			zones.append({"name": KIND_NAMES[kind], "center": Vector3(b.get_center().x, _base_y, b.get_center().y),
				"radius": minf(b.size.x, b.size.y) / 2.0 + 0.5})
	for c in _map["corridors"]:
		var a := _v2(c["a"])
		var b := _v2(c["b"])
		var n := maxi(1, ceili(a.distance_to(b) / 12.0))
		for i in n:
			var p := a.lerp(b, (i + 0.5) / n)
			zones.append({"name": "%s (oben)" % c["name"], "center": Vector3(p.x, _base_y, p.y), "radius": a.distance_to(b) / n / 2.0 + 1.0})


## Wegpunkte eines oberen Stockwerks: Flure alle 4 m (nur wo dort Boden ist, nicht über dem Luftraum), Bibliothek.
func _upper_waypoints() -> void:
	for c in _map["corridors"]:
		var a := _v2(c["a"])
		var b := _v2(c["b"])
		var n := maxi(1, floori(a.distance_to(b) / 4.0))
		for i in n + 1:
			var p := a.lerp(b, float(i) / n)
			if _kind_at(p) in ["corridor", "lobby"]:
				wander_points.append(Vector3(p.x, _base_y, p.y))
	for r in _map["regions"]:
		if r["kind"] == "library":
			var b := _bounds(r["rects"])
			patrol.append({"pos": Vector3(b.get_center().x, _base_y, b.get_center().y), "room": ""})


## Zonen des Untergeschosses (Plan geladen): Heizkeller, Technikraum und Wäscherei je ein Kreis, die Gänge als
## Kette von Kreisen je Planrechteck („Keller“ – der erste Besuch löst einen Autosave aus, SaveManager.NEW_AREAS).
func _lower_zones() -> void:
	for r in _map["regions"]:
		var kind := String(r["kind"])
		if kind in ["boiler_room", "plant_room", "laundry_room"]:
			var b := _largest_rect(kind)
			zones.append({"name": KIND_NAMES[kind], "center": Vector3(b.get_center().x, _base_y, b.get_center().y),
				"radius": minf(b.size.x, b.size.y) / 2.0 + 0.5})
		elif kind == "cellar":
			for rc in r["rects"]:
				var a := Vector2(rc[0], rc[1])
				var b := Vector2(rc[2], rc[3])
				var size := b - a
				if minf(size.x, size.y) < 1.0:
					continue   # Streifen an Ecken und Türen
				var n := maxi(1, ceili(maxf(size.x, size.y) / 12.0))
				for i in n:
					var f := (i + 0.5) / n
					var p := Vector2(lerpf(a.x, b.x, f), (a.y + b.y) / 2.0) if size.x > size.y else Vector2((a.x + b.x) / 2.0, lerpf(a.y, b.y, f))
					zones.append({"name": "Keller", "center": Vector3(p.x, _base_y, p.y), "radius": maxf(size.x, size.y) / n / 2.0 + 1.0})


## Wegpunkte des Untergeschosses – nur fürs Monster (patrol), Gäste gehen nicht hinunter: die Gänge alle 6 m und die
## Mitte jedes Kellerraums, der nicht verschlossen ist.
func _lower_waypoints() -> void:
	for r in _map["regions"]:
		var kind := String(r["kind"])
		if kind in ["plant_room", "laundry_room"]:
			var b := _largest_rect(kind)
			patrol.append({"pos": Vector3(b.get_center().x, _base_y, b.get_center().y), "room": ""})
		elif kind == "cellar":
			for rc in r["rects"]:
				var a := Vector2(rc[0], rc[1])
				var b := Vector2(rc[2], rc[3])
				var size := b - a
				if minf(size.x, size.y) < 1.0:
					continue
				var n := maxi(1, floori(maxf(size.x, size.y) / 6.0))
				for i in n:
					var f := (i + 0.5) / n
					var p := Vector2(lerpf(a.x, b.x, f), (a.y + b.y) / 2.0) if size.x > size.y else Vector2((a.x + b.x) / 2.0, lerpf(a.y, b.y, f))
					patrol.append({"pos": Vector3(p.x, _base_y, p.y), "room": ""})


func cellar_center() -> Vector3:
	return _cellar_center


func _garden_name(c: Vector2) -> String:
	if absf(c.x) < 15.0:
		return "Garten"
	return "Innenhof " + ("Nord" if c.y < -60.0 else "Süd") + ("ost" if c.x > 0.0 else "west")


## Wegpunkte: Flure alle 4 m, Zimmertüren, Lobby, Treppenhaus, Heizkeller, Untergeschoss und die Gemeinschaftsräume.
## Das Monster nutzt sie, um aus dem Blickfeld zu verschwinden; Gäste schlendern durch die Flure.
func _waypoints() -> void:
	for c in _map["corridors"]:
		var a := _v2(c["a"])
		var b := _v2(c["b"])
		var n := maxi(1, floori(a.distance_to(b) / 4.0))
		for i in n + 1:
			var p := a.lerp(b, float(i) / n)
			if not _lobby.has_point(p):
				wander_points.append(Vector3(p.x, 0, p.y))
	for level in range(1, _top_level + 1):
		_on_floor(level, _upper_waypoints)
	for p in wander_points:
		patrol.append({"pos": p, "room": ""})
	_on_floor(_lower, _lower_waypoints)
	for no in rooms:
		patrol.append({"pos": rooms[no]["door_front"], "room": no})
	var extra: Array[Vector3] = [lobby_center, lobby_center + Vector3(-4.0, 0, 6.0), lobby_center + Vector3(4.0, 0, -8.0),
		stairwell_point, stairwell_point + Vector3(0, UP_Y / 2.0, -2.2), cellar_center(), cellar_center() + Vector3(0, 0, 2.5),
		kitchen_spot, garden_spots[0], garden_spots[0] + Vector3(0, 0, -20.0)]
	for id: String in ["bar", "partyraum", "speisesaal", "pool"]:
		var r: Rect2 = _named[id]
		extra.append(Vector3(r.get_center().x, 0, r.get_center().y))
	for t in _map["trees"]:
		extra.append(_v3(t["center"]) + Vector3(0, 0, 7.0))
	for p in extra:
		patrol.append({"pos": p, "room": ""})


# --- Abfragen für andere Systeme --------------------------------------------------------------------

## Steht p in der Lobby (Erdgeschoss)?
func in_lobby(p: Vector3) -> bool:
	return absf(p.y) < 1.5 and _lobby.has_point(Vector2(p.x, p.z))


## Steht p in der benannten Fläche (z. B. "partyraum", "bar"; oben mit Vorsatz „og1_“)?
func in_area(p: Vector3, id: String) -> bool:
	var level := _level_of(p.y)
	if level < 0:
		return false
	return _on_floor(level, func() -> bool: return _named.has(id) and (_named[id] as Rect2).has_point(Vector2(p.x, p.z)))


## Steht p in einem Flur (nicht in der Lobby; Galerien zählen zur Lobby)?
func in_corridor(p: Vector3) -> bool:
	var level := _level_of(p.y)
	if level < 0:
		return false
	return _on_floor(level, func() -> bool: return _kind_at(Vector2(p.x, p.z)) == "corridor")


## Raum an p, wie bei Fenstern und Schaltern: Zimmernummer, Bereich (bar, pool, og1_… oben, ug_… unten),
## Flurabschnitt oder "lobby" – leer draußen und auf Treppenpodesten.
func room_at(p: Vector3) -> String:
	var level := _level_of(p.y)
	if level < 0:
		return ""
	return _on_floor(level, func() -> String: return _room_id_at(Vector2(p.x, p.z)))


## Ist p draußen (Garten, Innenhof, Terrasse, Balkon)?
func is_outdoor(p: Vector3) -> bool:
	var level := _level_of(p.y)
	if level < 0:
		return false
	return _on_floor(level, func() -> bool:
		var place := _place_at(Vector2(p.x, p.z))
		return not place.is_empty() and String(place["kind"]) in ["garden", "terrace", "balcony"])


## Wohin der Debug-Teleport in Zimmer no springt: {pos, look} – auch verschlossene Zimmer; {} = kein Zimmer.
func room_spot(no: String) -> Dictionary:
	return _room_spots.get(no, {})


## Sicher vor allem (Spielkonzept 7.7): der Katzenraum – Monster und Lakengeist kommen nicht hinein.
func is_safe(p: Vector3) -> bool:
	var level := _level_of(p.y)
	if level < 0:
		return false
	return _on_floor(level, func() -> bool:
		var place := _place_at(Vector2(p.x, p.z))
		return not place.is_empty() and place["kind"] == "cat_room")


# --- Bausteine ------------------------------------------------------------------------------------

## Wand entlang X bei z. Öffnungen als Vector4(Mitte x, Breite, Oberkante, Unterkante).
func _wall_x(z: float, x0: float, x1: float, openings: Array, mat: Material = null, height: float = H, thick: float = T) -> void:
	var holder := Node3D.new()
	holder.position = Vector3(0, 0, z)
	_parent.add_child(holder)
	_wall(holder, x0, x1, openings, mat, height, thick)


## Wand entlang Z bei x. Öffnungen als Vector4(Mitte z, Breite, Oberkante, Unterkante).
func _wall_z(x: float, z0: float, z1: float, openings: Array, mat: Material = null, height: float = H, thick: float = T) -> void:
	var holder := Node3D.new()
	holder.position = Vector3(x, 0, 0)
	holder.rotation.y = -PI / 2.0   # lokale +X zeigt entlang +Z
	_parent.add_child(holder)
	_wall(holder, z0, z1, openings, mat, height, thick)


## Wand im lokalen Rahmen von holder (entlang X von a0 bis a1): Kollision als Kästen wie gehabt
## (links, unter und über jeder Öffnung, rechts), die Optik als ein Mesh mit gemeinsamen Ecken (Geo.wall_mesh).
## Laibungen in Rahmenholz: Rutscht die Zarge beim Vertex-Snapping weg, blitzt Holz statt Tapete durch
## (nur der Beton im Keller hat keinen Rahmen).
func _wall(holder: Node3D, a0: float, a1: float, openings: Array, mat: Material, height: float, thick: float) -> void:
	var cursor := a0
	for o in openings:
		var op: Vector4 = o
		var a := op.x - op.y / 2.0
		if a > cursor:
			Geo.collider(holder, Vector3(a - cursor, height, thick), Vector3((cursor + a) / 2.0, height / 2.0, 0))
		if op.w > 0.0:
			Geo.collider(holder, Vector3(op.y, op.w, thick), Vector3(op.x, op.w / 2.0, 0))
		if op.z < height:
			Geo.collider(holder, Vector3(op.y, height - op.z, thick), Vector3(op.x, op.z + (height - op.z) / 2.0, 0))
		cursor = op.x + op.y / 2.0
	if a1 > cursor:
		Geo.collider(holder, Vector3(a1 - cursor, height, thick), Vector3((cursor + a1) / 2.0, height / 2.0, 0))
	var wall := Geo.mesh(holder, Geo.wall_mesh(a0, a1, height, thick, openings), null, Vector3.ZERO)
	var m: Material = mat if mat else _wallpaper
	wall.set_surface_override_material(0, m)
	if wall.mesh.get_surface_count() > 1:
		wall.set_surface_override_material(1, m if m == _concrete else OpeningFrame.trim_material())


## Schild an der Wand (pos = 1 cm vor der Wandfläche, Schrift zeigt nach +Z): Buchstaben als echte Geometrie
## (TextMesh) im PS1-Material, damit Lampen und Taschenlampe sie treffen wie alles andere (Spielkonzept 7.3).
## Wie schief es hängt und wie angelaufen das Messing ist, folgt fest aus dem Text, nicht aus dem Zufall.
## Gibt die Oberkante der Platte zurück (Höhe wie pos).
func _sign(text: String, pos: Vector3, yaw: float, em: float = SIGN_EM) -> float:
	var holder := Node3D.new()
	holder.rotation = Vector3(0, deg_to_rad(yaw), 0)
	holder.position = pos - holder.basis.z * WALL_GAP
	var h := text.hash()
	holder.rotate_object_local(Vector3.BACK, deg_to_rad(float(posmod(h, 7) - 3) * 0.5))   # bis 1,5° schief
	_parent.add_child(holder)
	var letters := TextMesh.new()
	letters.text = text
	letters.font = _sign_font
	letters.font_size = SIGN_FONT_SIZE
	letters.pixel_size = em / SIGN_FONT_SIZE
	letters.curve_step = SIGN_CURVE_STEP
	letters.depth = SIGN_DEPTH
	var box := letters.get_aabb()
	var center := box.get_center()
	var plate := Vector2(box.size.x, box.size.y) + SIGN_MARGIN * 2.0
	var brass := Mat.psx(SIGN_BRASS[posmod(h >> 3, SIGN_BRASS.size())])
	var rim := Vector3(plate.x + SIGN_RIM * 2.0, plate.y + SIGN_RIM * 2.0, SIGN_PLATE * 0.6)
	Geo.mesh(holder, Geo.box(rim), brass, Vector3(0, 0, rim.z / 2.0))
	Geo.mesh(holder, Geo.box(Vector3(plate.x, plate.y, SIGN_PLATE)), _dark_wood, Vector3(0, 0, SIGN_PLATE / 2.0))
	# Hinterkante der Buchstaben 2 mm in der Platte, sonst flimmert beim Vertex-Snapping ein Spalt
	Geo.mesh(holder, letters, brass, Vector3(-center.x, -center.y, SIGN_PLATE - 0.002 - box.position.z))
	return pos.y + rim.y / 2.0


## Feste Kerze als Deko-Licht (kein Gegenstand): brennt immer, flackert leicht und in Monsternähe.
## Kerzen und Kürbisse sind die hellsten Lichter im Haus (Spielkonzept 7.3).
func _candle(pos: Vector3) -> void:
	var holder := Node3D.new()
	holder.position = pos
	_parent.add_child(holder)
	Geo.mesh(holder, Geo.cylinder(0.05, 0.015, 8), Mat.psx(Color(0.6, 0.47, 0.22)), Vector3(0, 0.0075, 0))   # Messingteller
	Geo.mesh(holder, Geo.cylinder(0.03, 0.18, 6), Mat.psx(Color(0.92, 0.88, 0.75)), Vector3(0, 0.105, 0))
	var flame := Mat.psx(Color(1, 0.8, 0.3), "", 1.0, Color(1, 0.7, 0.2), 4.0, false)
	Geo.mesh(holder, Geo.sphere(0.016, 0.04, 5, 2), flame, Vector3(0, 0.215, 0))
	var light := FlickerLight.new()
	light.position = Vector3(0, 0.26, 0)
	light.light_color = Color(1.0, 0.68, 0.32)
	light.base_energy = CANDLE_ENERGY
	light.omni_range = 4.5
	light.soft = true
	light.shadow_enabled = false
	light.distance_fade_enabled = true
	light.distance_fade_begin = 20.0
	light.distance_fade_length = 5.0
	light.add_to_group("lamps")
	holder.add_child(light)


## Wandleuchte; yaw dreht die lokale +Z-Achse (von der Wand weg) in den Raum.
func _wall_lamp(pos: Vector3, yaw: float, energy: float, light_range: float, room_id: String, broken: bool = false) -> Lamp:
	var lamp := Lamp.new().setup(Lamp.Style.WALL, room_id, energy, light_range, broken)
	lamp.position = pos
	lamp.rotation.y = yaw
	_parent.add_child(lamp)
	return lamp


## Deckenleuchte bei p (Spielkonzept 7.3): runde Kupferleuchte bündig an der Decke (Lamp.Style.FLUSH), über dem
## Luftraum (open_above) als Pendel an einer Schnur von der oberen Decke herab (Lamp.Style.CEILING).
func _ceiling_lamp(p: Vector2, room_id: String, broken: bool) -> Lamp:
	var y := H
	var style := Lamp.Style.FLUSH
	for rc in _map["open_above"]:
		if Rect2(rc[0], rc[1], rc[2] - rc[0], rc[3] - rc[1]).has_point(p):
			var top := UP_Y + H
			y = PENDANT_Y
			style = Lamp.Style.CEILING
			Geo.mesh(_parent, Geo.cylinder(0.01, top - y, 4), Mat.psx(Color(0.2, 0.18, 0.16)), Vector3(p.x, (top + y) / 2.0, p.y))
	var lamp := Lamp.new().setup(style, room_id, CEILING_LAMP_ENERGY, CEILING_LAMP_RANGE, broken)
	lamp.position = Vector3(p.x, y, p.y)
	_parent.add_child(lamp)
	return lamp


## Halogenleuchte (Spielkonzept 7.9): Röhre der Länge length entlang axis („x“/„z“) bündig unter der Decke,
## kaltweiß, flackert ab und zu von selbst kurz auf (Lamp.Style.HALOGEN).
func _halogen(p: Vector2, axis: String, length: float, room_id: String, broken: bool) -> Lamp:
	var lamp := Lamp.new().setup(Lamp.Style.HALOGEN, room_id, HALOGEN_ENERGY, HALOGEN_RANGE, broken)
	lamp.length = length
	lamp.position = Vector3(p.x, H - 0.03, p.y)
	if axis == "z":
		lamp.rotation.y = PI / 2.0   # die Röhre liegt lokal entlang X
	_parent.add_child(lamp)
	return lamp


## Schrift, die nur unter UV-Licht leuchtet (Spielkonzept 4.16); yaw (Bogenmaß) dreht die Schrift
## (lokale +Z) von der Wand weg in den Raum.
func _uv_writing(text: String, pos: Vector3, yaw: float) -> void:
	var mark := UvMark.new().setup_text(text)
	mark.position = pos
	mark.rotation.y = yaw
	_parent.add_child(mark)


## Warnungszettel eines früheren Gastes (erscheint erst nach dem ersten Angriff).
func _note(id: String, pos: Vector3) -> WarningNote:
	var note := WarningNote.new().setup(id)
	note.position = pos
	_parent.add_child(note)
	return note


func _switch(room_id: String, label: String, pos: Vector3, yaw: float) -> LightSwitch:
	var sw := LightSwitch.new().setup(room_id, label)
	sw.position = pos
	sw.rotation.y = yaw
	_parent.add_child(sw)
	return sw


func _hide_spot(type: HideSpot.Type, pos: Vector3, yaw: float) -> HideSpot:
	var spot := HideSpot.new().setup(type)
	spot.position = pos
	spot.rotation.y = yaw
	_parent.add_child(spot)
	return spot


func _painting(pos: Vector3, yaw: float, color: Color) -> void:
	var holder := Node3D.new()
	holder.position = pos
	holder.rotation.y = yaw
	_parent.add_child(holder)
	Geo.mesh(holder, Geo.box(Vector3(0.8, 0.6, 0.04)), _dark_wood, Vector3(0, 0, 0.02))
	Geo.mesh(holder, Geo.box(Vector3(0.66, 0.46, 0.045)), Mat.psx(color), Vector3(0, 0, 0.025))


## Ledercouch (`assets/models/couch.glb`, Rohmodell in Blender-Einheiten → `COUCH_SCALE`).
## Lokal liegt die Lehne bei −X, die Sitzfläche zeigt nach +X; yaw dreht um Y.
func _couch(pos: Vector3, yaw: float) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.collision_mask = 0
	body.position = pos
	body.rotation.y = yaw
	_parent.add_child(body)
	var model: Node3D = (load(COUCH_MODEL) as PackedScene).instantiate()
	model.scale = Vector3.ONE * COUCH_SCALE
	model.position.y = 0.066 * COUCH_SCALE   # Unterkante des Modells liegt bei y = −0,066
	body.add_child(model)
	for m: MeshInstance3D in model.find_children("*", "MeshInstance3D", true, false):
		m.material_override = Mat.model(COUCH_MODEL, m)
	# Kollision (auch für das NavMesh): Sitzblock und Lehne, Maße aus dem skalierten Modell.
	Geo.add_box_shape(body, Vector3(0.64, 0.45, 2.39), Vector3(0, 0.225, 0))
	Geo.add_box_shape(body, Vector3(0.18, 0.47, 2.25), Vector3(-0.23, 0.685, 0))
	return body


## Spinnweben, die man abnehmen kann (lokale +Z zeigt in den Raum, yaw im Bogenmaß).
func _resource_web(pos: Vector3, yaw: float) -> void:
	var spot := ResourceSpot.new().setup(Item.Kind.COBWEB, "Spinnenweben", 1, 240.0)
	spot.position = pos
	spot.rotation.y = yaw
	_parent.add_child(spot)


## Gegenstände liegen in der Hauptszene – pos im Rahmen des aktuellen Bauteils.
func _item(kind: Item.Kind, pos: Vector3, extra: String = "") -> Item:
	var item := Item.create(kind, extra)
	item.position = _global(pos)
	world.add_child(item)
	return item


func _global(local: Vector3) -> Vector3:
	return _parent.global_transform * local
