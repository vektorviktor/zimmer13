class_name LevelBuilder
extends RefCounted
## Baut das Hotel aus dem Gebäudeplan (Spielkonzept 7.5): `assets/maps/eg.json`, `og1.json` und `ug.json`, erzeugt von
## `tools/build_map.py` aus `map.aseprite`. 1 Einheit = 1 m, x nach Osten, z nach Süden (Norden = −Z),
## Ursprung = Mitte des Haupteingangs auf der Südwand.
##
##   Erdgeschoss (y 0): Lobby mit Luftraum und Galerie (Treppe hinauf), Bar + Spiele, Partyraum über zwei
##   Stockwerke, Toiletten · Ostflügel 001–049 · Westflügel 051–099 (Bauphase: Zimmer verschlossen, Flure
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
const UPPER_MAP_PATHS := ["res://assets/maps/og1.json", "res://assets/maps/dg.json"]
## Untergeschoss (Spielkonzept 7.9) – die Treppenhäuser enden dort
const LOWER_MAP_PATH := "res://assets/maps/ug.json"
## Plan, Legende (PLANFARBEN.md) und Umsetzer: Ist eins davon neuer als die Karten, liest refresh_maps() den Plan neu ein
const PLAN_SOURCES := ["res://map_a.aseprite", "res://PLANFARBEN.md", "res://tools/build_map.py",
	"res://tools/plan_legend.py"]
## Haushalte (Spielkonzept 6.20): wer mit wem in welchem Zimmer wohnt – aus HAUSHALTE.md (tools/build_households.py)
const HOUSEHOLDS_PATH := "res://assets/data/households.json"
const HOUSEHOLD_SOURCES := ["res://HAUSHALTE.md", "res://tools/build_households.py"]
## Kellerwände: Brettschalungsbeton (Farbbild und Normal Map des PBR-Sets), eine Kachel = 18 Brettreihen auf
## CELLAR_WALL_METERS
const CELLAR_WALL_TEX := "res://assets/textures/Concrete_WoodPattern_01/Concrete_WoodPattern_01_Base_Color.jpg"
const CELLAR_WALL_NORMAL := "res://assets/textures/Concrete_WoodPattern_01/Concrete_WoodPattern_01_Normal.jpg"
const CELLAR_WALL_METERS := 3.0
## Kieswege im Garten (Plan map_a, Fläche „Kiesweg“): Kopfsteine in Moos (StoneWall_01, Farbbild mit eingebackener
## AO + Normal Map, verstärkt – sonst wirken sie flach), Steine 10–18 cm
const GRAVEL_TEX := "res://assets/textures/StoneWall_01/StoneWall_01_basecolor.jpg"
const GRAVEL_NORMAL := "res://assets/textures/StoneWall_01/StoneWall_01_normalOGL.jpg"
const GRAVEL_METERS := 0.5
const GRAVEL_NORMAL_STRENGTH := 2.0
## Holzdeck auf Terrassen und Balkonen (Deck, ZIM-127): so tief liegt die dunkle Platte unter der Oberkante der Bretter,
## Fuge zur Hauswand und zur Hecke bzw. zum Geländer
const DECK_DROP := 0.04
const DECK_WALL_GAP := 0.02
const DECK_EDGE_GAP := 0.04
## So glatt werden Rasen, Stein (Kantenstreifen an Terrasse und Balkon, Kübel) und Kies, wenn sie ganz nass sind
## (Weather, 1 = Wasserfilm)
const WET_GLOSS := Vector3(0.45, 1.0, 0.8)
## Außenwände des Hotels: Bruchsteinplatten mit Fugen (StoneFloor_02, Farbbild mit eingebackener AO + verstärkte
## Normal Map), Platten 20–40 cm
const FACADE_TEX := "res://assets/textures/StoneFloor_02/StoneFloor_02_basecolor.jpg"
const FACADE_NORMAL := "res://assets/textures/StoneFloor_02/StoneFloor_02_normalOGL.jpg"
const FACADE_METERS := 2.0
const FACADE_NORMAL_STRENGTH := 2.0
## Holzdecken (Flure, Hallen, Treppenhäuser, Zimmer): dunkle Kassettendecke mit Schnitzwerk (Wood_Panels_01,
## Farbbild mit eingebackener AO, Normal Map, Rauheit – lackiert), eine Kachel = 2 × 2 Kassetten à 1 m.
## Das Farbbild ist dunkler als die frühere TexGen-Holzdecke – aufgehellt, in den Fluren weniger (Spielkonzept 7.3)
const CEILING_TEX := "res://assets/textures/Wood_Panels_01/Wood_Panels_01_basecolor.jpg"
const CEILING_NORMAL := "res://assets/textures/Wood_Panels_01/Wood_Panels_01_normalogl.jpg"
const CEILING_ROUGHNESS := "res://assets/textures/Wood_Panels_01/Wood_Panels_01_roughness.jpg"
const CEILING_METERS := 2.0
const CEILING_SPECULAR := 0.5
const CEILING_SHADE := Color(1.2, 1.2, 1.2)
const ROOM_CEILING_SHADE := Color(1.8, 1.8, 1.8)
## Lobbyboden: polierte Marmorplatten (Farbbild, Normal Map, Rauheit), eine Kachel = 4 × 4 Platten à 60 cm
## Holzböden (Zimmer, Bar, Partyraum, Katzenzimmer, Bibliothek, Treppenpodeste): lackierte Dielen (WoodenFloor_03),
## 16 Dielen je Kachel à ~12,5 cm, längs +z; leichter Glanz aus der Rauheitskarte
const WOOD_FLOOR_TEX := "res://assets/textures/WoodenFloor_03/WoodenFloor_03_basecolor.jpg"
const WOOD_FLOOR_NORMAL := "res://assets/textures/WoodenFloor_03/WoodenFloor_03_normalogl.jpg"
const WOOD_FLOOR_ROUGHNESS := "res://assets/textures/WoodenFloor_03/WoodenFloor_03_roughness.jpg"
const WOOD_FLOOR_METERS := 2.0
const WOOD_FLOOR_SPECULAR := 0.5
## Bowlingbahn (Spielkonzept 6.10, 28.10.): versiegeltes Parkett aus schmalen Riemen (Mat.lane_boards), hell wie
## Ahorn, glatt lackiert – spiegelt ein wenig (SSR wie der Lobbymarmor)
const LANE_TINT := Color(1.15, 1.05, 0.88)
const LANE_SPECULAR := 0.9
const LANE_ROUGHNESS := 0.18
const LANE_MIRROR := 0.15
const FOUL_LINE_COLOR := Color(0.42, 0.06, 0.05)
const LOBBY_FLOOR_TEX :="res://assets/textures/TilesMarble_01/T_TilesMarble_01_basecolor.jpg"
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
## Bäder, Umkleiden und Duschen am Pool (31.10.): Wände bis BATH_TILE_HEIGHT, Boden, Wannensockel, Waschtisch und
## Duschsockel mit dunklen Schieferfliesen in gemischten Formaten (Tiles045, ambientCG), eine Kachel =
## BATH_TILES_METERS (größte Fliesen etwa 45 cm) – in Weltkoordinaten, die Fugen laufen so von der Wand über den
## Boden auf die Wanne durch; darüber und an der Decke gestrichene Wand
const BATH_TILES_TEX := "res://assets/textures/Tiles045/Tiles045_basecolor.jpg"
const BATH_TILES_NORMAL := "res://assets/textures/Tiles045/Tiles045_normalogl.jpg"
const BATH_TILES_ROUGHNESS := "res://assets/textures/Tiles045/Tiles045_roughness.jpg"
const BATH_TILES_METERS := 1.8
const BATH_TILE_HEIGHT := 2.0
const BATH_PAINT_TEX := "res://assets/textures/Scifi_PaintedWall_01/Scifi_PaintedWall_01_basecolor.jpg"
const BATH_PAINT_NORMAL := "res://assets/textures/Scifi_PaintedWall_01/Scifi_PaintedWall_01_normalogl.jpg"
const BATH_PAINT_ROUGHNESS := "res://assets/textures/Scifi_PaintedWall_01/Scifi_PaintedWall_01_roughness.jpg"
const BATH_PAINT_METERS := 2.5
const BATH_PAINT_SPECULAR := 0.3
## Küche (2.11.): Boden aus hellen 15-cm-Fliesen im Halbverband (Tiles136B, ambientCG), Wände bis unter die Decke mit
## hellblauen 15-cm-Fliesen (Tiles133B), je Bild 12 Kacheln; Decke gestrichen wie im Bad
const KITCHEN_FLOOR_TEX := "res://assets/textures/Tiles136B/Tiles136B_basecolor.jpg"
const KITCHEN_FLOOR_NORMAL := "res://assets/textures/Tiles136B/Tiles136B_normalogl.jpg"
const KITCHEN_FLOOR_ROUGHNESS := "res://assets/textures/Tiles136B/Tiles136B_roughness.jpg"
const KITCHEN_WALL_TEX := "res://assets/textures/Tiles133B/Tiles133B_basecolor.jpg"
const KITCHEN_WALL_NORMAL := "res://assets/textures/Tiles133B/Tiles133B_normalogl.jpg"
const KITCHEN_WALL_ROUGHNESS := "res://assets/textures/Tiles133B/Tiles133B_roughness.jpg"
const KITCHEN_TILES_METERS := 1.8
const KITCHEN_ROOM := "kueche"
## Speisesaal (2.11.): dunkles Fischgrätparkett (WoodFloor014, ambientCG), Stäbe 7,5 × 30 cm, 16 Stabbreiten je Bild
const DINING_FLOOR_TEX := "res://assets/textures/WoodFloor014/WoodFloor014_basecolor.jpg"
const DINING_FLOOR_NORMAL := "res://assets/textures/WoodFloor014/WoodFloor014_normalogl.jpg"
const DINING_FLOOR_ROUGHNESS := "res://assets/textures/WoodFloor014/WoodFloor014_roughness.jpg"
const DINING_FLOOR_METERS := 1.2
const DINING_ROOM := "speisesaal"
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
## flach, dafür Poren, PILLAR_PORES), eine Kachel = 1 m, Steinchen 5–8 mm. Toskanisch, mittig im Plan: quadratische Plinthe, Wulst,
## gerader Schaft, Halsring, flacher Echinus, quadratische Deckplatte mit Stufe darunter.
## Low Poly: Drehkörper mit PILLAR_SIDES Seiten, zusammen unter 1000 Dreiecken je Säule.
const PILLAR_TEX := "res://assets/textures/TerrazzoDark_01/TerrazzoDark_01_basecolor.jpg"
const PILLAR_ROUGHNESS := "res://assets/textures/TerrazzoDark_01/TerrazzoDark_01_roughness.jpg"
const PILLAR_METERS := 1.0
const PILLAR_SPECULAR := 0.5
## Poren der Säulen (nur dort, Couchtisch und Rezeption bleiben glatt): eigene Normal Map aus tools/pore_map.gd,
## eine Kachel = PILLAR_PORES_METERS, etwa eine Pore je 2 cm²; Stärke und Schmutz in den Poren (psx_photo „cavity“)
const PILLAR_PORES := "res://assets/textures/TerrazzoDark_01/TerrazzoDark_01_pores_normal.png"
const PILLAR_PORES_METERS := 0.25
const PILLAR_PORES_STRENGTH := 0.8
const PILLAR_PORES_CAVITY := 1.0
const PILLAR_SIDES := 18
const PILLAR_PLINTH := Vector3(0.81, 0.16, 0.81)
const PILLAR_ABACUS := Vector3(0.76, 0.07, 0.76)
const PILLAR_ABACUS_STEP := Vector3(0.68, 0.03, 0.68)
## Profil (Radius, Höhe): Fuß über dem Boden (Wulst, Plättchen, Anlauf), Kopf unter der Deckplattenstufe (Ring,
## Hals, Halsring, flacher Echinus); dazwischen der gerade Schaft mit PILLAR_SHAFT_RADIUS.
const PILLAR_FOOT := [Vector2(0.3, 0.16), Vector2(0.3225, 0.185), Vector2(0.33, 0.21), Vector2(0.318, 0.235),
	Vector2(0.285, 0.255), Vector2(0.255, 0.26), Vector2(0.255, 0.285), Vector2(0.237, 0.3), Vector2(0.225, 0.33)]
const PILLAR_HEAD := [Vector2(0.225, -0.35), Vector2(0.245, -0.335), Vector2(0.245, -0.315), Vector2(0.222, -0.3),
	Vector2(0.222, -0.2), Vector2(0.24, -0.19), Vector2(0.24, -0.17), Vector2(0.232, -0.16), Vector2(0.262, -0.12),
	Vector2(0.292, -0.07), Vector2(0.312, -0.03), Vector2(0.316, 0.0)]
const PILLAR_SHAFT_RADIUS := 0.225
## Couchtisch der Lobby: quadratisch (kurze Seite des Plan-Rechtecks), Platte aus dem Terrazzo der Säulen, so stark,
## wie sie über den Unterbau steht und wie ihre Ecken gerundet sind; Beine und Zarge aus dunklem Holz, gleich stark
const COFFEE_TABLE_SLAB := 0.03
const COFFEE_TABLE_WOOD := 0.1
const COFFEE_TABLE_CORNER_SEGMENTS := 4
## Kaffeemaschine (Spielkonzept 3.11): so weit vom linken Ende der Küchenzeile (Mitte der Maschine)
const COFFEE_MACHINE_INSET := 0.3
## Wasserkocher (3.12): so weit rechts neben der Kaffeemaschine (Mitte zu Mitte); Tee-Tablett so weit neben dem Kaffee
const KETTLE_GAP := 0.38
## Stehplätze der Gäste in der Küche (ZIM-155): höchstens so weit auseinander, 0,8 m von der Wand
const KITCHEN_SPOT_STEP := 1.2
const BAR_TEA_GAP := 0.42
## Salzpackungen (Spielkonzept 5.13) in der Küche, bis sie im Plan stehen – ohne Nachschub
const SALT_BOXES := 3
const FEED_TABLE_RANGE := 12.0   ## Futtertisch der Krähen (4.25): so weit höchstens von einer Gartentür von Zimmer 13
const BREAD_OFFSET := 0.8   ## Brotkrumen (4.25): so weit links der Mitte der Küchenzeile
## Eierkarton in der Küche (Spielkonzept 6.13): so viele Eier, morgens wieder aufgefüllt
const EGG_BOX := 10
const H := 3.5
const T := 0.2
## Holzpfeiler (_corner_posts): Höhe von Sockel und Kapitell, so weit steht der Sockel vor dem Schaft
const POST_BASE := 0.25
const POST_CAP := 0.22
const POST_PLINTH := 0.025
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
## Schreibtischlampe (Lamp.Style.DESK, Planfarbe „Licht: Schreibtischlampe“): schwächer, leuchtet nur den Platz darunter aus
const DESK_LAMP_ENERGY := 0.45
const DESK_LAMP_RANGE := 4.0
const DESK_LAMP_MAX_TURN := deg_to_rad(55.0)   # weiter dreht niemand eine Lampe vom Platz weg
const DESK_LAMP_JITTER := deg_to_rad(6.0)
## Sitzplatz vor einem Möbel: so weit vor der Mitte der Vorderkante sitzt man (Brust, Hände auf der Platte)
const SEAT_REACH := 0.45
## Mitte der Discokugel über der Tanzfläche (Partyraum, Luftraum) – vom Boden wie von der Galerie aus zu sehen
const DISCO_Y := 5.4
const DOOR_W := 1.2
const DOOR_H := 2.1
## Doppeltüren, Glastüren, Terrassentüren
const WIDE_DOOR_H := 2.4
const ENTRANCE_H := 2.8
## Türen im Dachgeschoss (Spielkonzept 4.21, seit 27.10. so hoch wie die übrigen): unter einer Dachschräge nur so
## hoch, dass über dem Sturz noch ATTIC_DOOR_HEAD bis zur Schräge bleibt – dort muss man sich weiter ducken
const ATTIC_DOOR_H := 2.1
const ATTIC_DOOR_HEAD := 0.1
## Dachgeschoss (Spielkonzept 4.21, Plan „DG“, 24.10.): Deckenhöhe, Kniestock (so hoch ist die Außenwand) und wie weit
## die Dachschräge darüber in den Raum reicht, bis sie die Decke trifft
const ATTIC_H := 2.2
const ATTIC_KNEE := 1.3
const ATTIC_SLOPE := 2.0
## Dachfenster in der Schräge: von/bis als Anteil der Schräge (unten = Kniestock), Rahmen und Kreuz aus Holz
const ATTIC_WINDOW := Vector2(0.25, 0.85)
const ATTIC_WINDOW_BAR := 0.06
## Licht durchs Dachfenster: Kegel (Winkel, Reichweite, Farbe, Anteil im Nebel – der Lichtschacht); Stärke folgt dem Mond
const ATTIC_SHAFT_ANGLE := 24.0
const ATTIC_SHAFT_RANGE := 5.0
const ATTIC_SHAFT_COLOR := Color(0.62, 0.72, 1.0)
const ATTIC_SHAFT_FOG := 3.0
const ATTIC_PLANK_TINT := Color(0.62, 0.6, 0.58)   ## grobe Bohlen, alt und grau
const ATTIC_BEAM_TINT := Color(0.5, 0.45, 0.4)
const ATTIC_ROOF_COLOR := Color(0.16, 0.15, 0.15)   ## Dachhaut außen
## Stützbalken: je Feld von etwa ATTIC_BAY m ein Pfosten in der Mitte, darauf ein Balkenkreuz (Unterkante, Querschnitt)
## bis an die Wände, jeder Arm mit einem Kopfband unter 45° (so weit vom Pfosten)
const ATTIC_BAY := 6.0
const ATTIC_BEAM_BOTTOM := 1.98
const ATTIC_BEAM := 0.2
const ATTIC_POST := 0.22
const ATTIC_BRACE := 0.5
const ATTIC_BRACE_SIZE := 0.12
const ATTIC_POST_DOOR_GAP := 1.0   ## kein Pfosten so nah an einer Tür
const ATTIC_ARM_DOOR_GAP := 0.75   ## kein Balkenarm, der so nah an einer Tür endet (die Türen reichen über ATTIC_BEAM_BOTTOM)
## Unter niedrigen Türen (unter der Schräge) bäckt das NavMesh nicht durch (Agentenhöhe 1,6 m): Je niedrige Kammertür
## verbindet ein NavigationLink3D die beiden Seiten, so weit vor und hinter der Wand – das Monster duckt sich hindurch
## (4.33, 3a). Die Kniestocktür bekommt keinen (verschlossen, das Monster bricht sie nicht auf).
const ATTIC_LINK_REACH := 0.8
const ATTIC_BOX_SIZE := 4          ## Kiste mit wertvollerer alter Deko auf dem Dachboden, ohne Nachschub
const COUCH_MODEL := "res://assets/models/couch.glb"
## Rohmodell ist 4,34 Einheiten lang → ~2,4 m lang, Sitzhöhe ~0,45 m, Lehne ~0,92 m.
const COUCH_SCALE := 0.55
## Parkbank für Bänke im Außenbereich (tools/build_bench.py): 1,6 m lang, in Metern, Ursprung mittig unten, Sitzseite
## nach +Z. Fehlt die Datei oder steht die Bank drinnen, bleibt sie ein Holzkasten.
const BENCH_MODEL := "res://assets/models/bench.glb"
const BENCH_LENGTH := 1.6
## Sitzoberkante, ausgegeben von tools/build_bench.py
const BENCH_SEAT := 0.476
## Tischgruppe in den Zimmern (tools/build_room_table.py): „table“ quadratisch 1 × 1 m, 0,75 m hoch, und ein „chair“,
## Sitzseite nach +Z, beide mit Ursprung mittig unten. Je Gruppe zwei Stühle einander gegenüber, auch wenn der Plan
## mehr zeigt. Fehlt die Datei, bleiben Kasten-Tisch und Kasten-Stühle aus dem Plan.
const ROOM_TABLE_MODEL := "res://assets/models/room_table.glb"
const ROOM_TABLE_SIDE := 1.0
## Stuhl: Breite, Sitzhöhe, Tiefe (ausgegeben von tools/build_room_table.py); Lehne von z −0,215 bis −0,149
const ROOM_CHAIR := Vector3(0.375, 0.46, 0.431)
const ROOM_CHAIR_H := 0.84
## Abstand der Stuhlmitte von der Tischmitte – die Sitzfläche ragt ein Stück unter die Platte
const ROOM_CHAIR_GAP := 0.66
## Stühle aus dem Plan, deren Mitte so nah am Zimmertisch liegt, gehören zu dessen Gruppe
const ROOM_CHAIR_REACH := 0.5
## 28 einzelne Flaschen „bottle_NN“ in Metern, Ursprung mittig unten (tools/build_bottles.py)
const BOTTLES_MODEL := "res://assets/models/bottles.glb"
## Pflanzkübel samt Bepflanzung in Metern, Ursprung mittig unten, Grundfläche 2 × 2 m wie im Plan
## (tools/build_planter.py aus Meshys Modell). Fehlt die Datei, baut `_gardens()` den Platzhalter aus
## Steinquader und Heckenkugel.
const PLANTER_MODEL := "res://assets/models/planter.glb"
## Handlauf der Pooltreppen mit gebogenen Knicken (tools/build_handrail.py, Tiefe 1,4 m und Lauf 2,1 m wie in _pool);
## Ursprung am Fuß des Pfostens auf dem Umgang, die Treppe hinab entlang −Z. Fehlt die Datei, gerade Stangen.
const HANDRAIL_MODEL := "res://assets/models/pool_handrail.glb"
## Gartenlaterne (tools/build_lantern.py): 3 m hoch, Ursprung mittig unter der Bodenplatte, Teile „post“ (Fuß und
## Mast, achteckig), „head“ (eckiger Kopf) und „glass“. Fehlt die Datei, Mast und Leuchtkasten als Platzhalter.
const LANTERN_MODEL := "res://assets/models/lantern.glb"
## Glasmitte (dort sitzt das Licht), ausgegeben von tools/build_lantern.py
const LANTERN_LIGHT_Y := 2.58
## Höhe des Kollisionsquaders (und des Platzhalter-Kübels) = Beckenkante, ausgegeben von tools/build_planter.py
const PLANTER_H := 0.46
## Die drei großen Laubbäume aus der „Realistic Trees Collection“ (tools/build_trees.py, Werte von dort): Ursprung
## auf der Stammachse am Boden, in Metern. Kronenradius, Höhe, Krone als Anteile der Höhe (von dort fällt Laub),
## Stammdurchmesser in 1 m Höhe (Kollision). Der Plan zeigt nur den Standort, die Bäume wechseln sich der Reihe
## nach ab; fehlt eine Datei, bleibt dort der Platzhalter.
const TREE_MODELS: Array[Dictionary] = [
	{"path": "res://assets/models/tree_1.glb", "radius": 4.9, "height": 10.3, "crown": Vector2(0.33, 1.00), "trunk": 0.55},
	{"path": "res://assets/models/tree_2.glb", "radius": 3.5, "height": 8.2, "crown": Vector2(0.30, 1.00), "trunk": 0.41},
	{"path": "res://assets/models/tree_3.glb", "radius": 5.4, "height": 10.7, "crown": Vector2(0.34, 1.00), "trunk": 0.56},
]
## Wanduhr über dem Haupteingang (WallClock): Durchmesser und Abstand der Rückseite zur Wandfläche; die Mitte hängt
## auf halber Höhe zwischen CLOCK_ABOVE_DOOR über dem Haupteingang (früher Oberkante des AUSGANG-Schilds) und der
## Hallendecke
const CLOCK_DIAMETER := 3.0
const CLOCK_GAP := 0.02
const CLOCK_ABOVE_DOOR := 0.47
## Höhe der Stammkollision; Kronenradius und Krone (Anteile der Höhe) des Platzhalters
const TREE_TRUNK_H := 3.0
const TREE_RADIUS := 5.0
const TREE_CROWN := Vector2(0.35, 0.6)
## Drehung von Baum zu Baum (Grad), damit zwei gleiche nicht gleich aussehen
const TREE_TURN := 137.0
## Fallendes Herbstlaub je Baum: so viele Blätter gleichzeitig, Lebenszeit (s) – reicht für den Fall aus
## der Krone und ein paar Sekunden am Boden –, Sinkgeschwindigkeit (m/s), Kantenlänge (m)
const LEAF_FALL := 40
const LEAF_LIFE := 20.0
const LEAF_SPEED := Vector2(0.45, 0.8)
const LEAF_SIZE := 0.13
const LEAF_GLOW := 0.35          ## etwas Eigenleuchten, sonst verschluckt sie die Nacht unter der Krone
const LEAF_COLORS: Array[Color] = [Color(0.75, 0.35, 0.08), Color(0.6, 0.15, 0.05), Color(0.8, 0.55, 0.1), Color(0.45, 0.25, 0.08)]
const LAYER_CEILING := 16
## Trittflächen der Treppenstufen – nur für Spuren (Traces.surface_below), blockiert niemanden. Gelaufen wird auf der
## glatten Rampe darunter (Ebene 1, Meta „stair_ramp“), die vorn an jeder Stufe über der Trittfläche liegt.
const LAYER_TREAD := 2048
## Fenster: Unterkante (überall 90 cm, Entscheidung 23.10.), Oberkante – die Breite kommt aus dem Plan
const WINDOW_SILL := 0.9
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

## Zimmerarten (Spielkonzept 6.19, 6.20): Wer wo wohnt und welche Zimmer eine besondere Rolle haben, steht in
## HAUSHALTE.md (HOUSEHOLDS_PATH, je Zimmer über seine Stelle im Plan); alle übrigen sind unbewohnt.
## Arten: player, guest, vacant (unbewohnt, Licht aus, vom Hotel abgeschlossen), abandoned, derelict, locked.
const PLAYER_ROOM := "013"
## Dartscheibe (Spielkonzept 6.10), solange sie nicht im Plan steht: hinten in der Nische an der Südwand der Bar
## neben der Bowlingbahn (28.10.) – wer danebenwirft, trifft niemanden. Blick nach Norden.
const DART_FALLBACK := {"kind": "dartboard", "pos": [-16.4, -10.25], "wall": "south"}
## Spieleschrank (Spielkonzept 6.10, 28.10.), solange er nicht im Plan steht (Möbel „Spieleschrank“): an der Ostwand
## der Bar (zur Lobby) südlich der Glastür
const CABINET_FALLBACK := {"kind": "game_cabinet", "pos": [-7.7, -13.2], "wall": "east"}
## Jackpot-Automat (einarmiger Bandit), solange er nicht im Plan steht (Möbel „Spielautomat“): Ecke oben rechts in der
## Bar, an der Nordwand nördlich der Glastür (28.10.)
const SLOT_FALLBACK := {"kind": "slot_machine", "pos": [-8.0, -18.75], "wall": "north"}
## Plätze aus dem Plan (planned, ZIM-158), die es nur einmal gibt – ein zweiter Punkt gilt nicht
const PLANNED_ONCE: Array[String] = ["doll_house", "apple_tub", "fuse_box", "notice_board", "wall_clock", "crow_nest",
	"leviathan_print", "mask_board", "disco_ball"]
## Videoautomaten (Spielkonzept 6.10, 28.10.) aus dem Plan der Reihe nach: welches Spiel darauf läuft
const ARCADE_GAMES: Array[String] = ["deadra", "ghost_hotel"]
const COMPASS_ROOM := "026"
## Maskensammlung (Spielkonzept 5.19), solange sie nicht im Plan steht: so weit bleiben die Haken von Ecken und
## Öffnungen weg, und so viel freie Wand (m) muss es in Zimmer 13 mindestens geben
const MASK_WALL_MARGIN := 0.2
const MASK_WALL_MIN := 1.6
const LOCKED_ROOM := "018"
const ROOM_KINDS := {"013": "player"}   ## gilt, wenn die Haushaltsdatei fehlt
## So weit hinter der Badtür steht ein Gast, der das Bad benutzt (BathUse, Spielkonzept 6.19)
const BATH_SPOT_DEPTH := 1.0
## Flügel, deren Zimmer schon bewohnbar sind – im EG bzw. darüber (seit 24.10. überall: die Haushalte wohnen in beiden)
const OPEN_WINGS := ["ost", "west"]
const OPEN_WINGS_UPPER := ["ost", "west"]

## Inhalt, der nicht im Plan steht, je Raum-ID (Zimmernummer oder Bereich): Münzbetrag (ohne Eintrag 1),
## Kartenblatt, Zettel-Nummer (Spielkonzept 4.12) und UV-Schrift (4.16) der Objekte in diesem Raum; „drawer“ = Item.Kind
## für die oberste Schublade der Kommode im Raum (_drawer_content).
const CONTENT := {
	"013": {"coins": "3", "map": "eg", "uv": "DU WARST SCHON\nEINMAL HIER"},
	"014": {"note": "2003"},
	"017": {"coins": "2", "map": "keller", "note": "1987",
		"uv": "ICH HABE ES GEBLENDET.\nJETZT KENNT ES MEINE TÜR.\n– E. K."},
	"018": {"coins": "5", "uv": "NUR EINER\nKOMMT HINAUS"},
	"022": {"drawer": "MATCHBOX"},   # Streichholzschachtel neben Zimmer 13 (Spielkonzept 5.12)
	"ug_laundry_room_1": {"note": "1994"},   # Wäscherei im Keller (seit 23.10. ohne Zimmernummer)
	"lobby": {"note": "2019", "map": "og"},   # Kartenblatt Obergeschoss an der Rezeption (Spielkonzept 3.2)
}
## Möbel ohne eigenes Bauteil (Kästen in der Grundfläche aus dem Plan): Art → Höhe
const BOX_HEIGHTS := {
	"table": 0.75, "coffee_table": 0.4, "dining_table": 0.85, "bench": 0.45, "bar_counter": 1.1, "shelf": 2.0,
	"kitchen_counter": 0.9, "stove": 0.95, "washbasin": 0.85, "washing_machine": 0.85, "laundry_box": 0.5,
	# Plan map_a (PLANFARBEN.md), Platzhalter bis zu den Modellen
	"bathtub": 0.6, "sink": 0.85, "shower": 0.06, "toilet": 0.42, "room_table": 0.75,
}
## Platzhalter-Möbel: Spiegel über dem Waschbecken (Breite, Höhe; Mitte über dem Boden), Fußmatte
## Sitzmöbel (Seat): Aufstehen so weit vor der Sitzkante (Spielerradius und etwas Luft)
const SEAT_CLEAR := 0.33
## Gartenmöbel (ZIM-51): so weit höchstens dreht sich ein Gartentisch (Grad); ein Gartenstuhl dreht sich zwischen x und y
## Grad nach links oder rechts und rückt bis GARDEN_CHAIR_SHIFT Meter von seinem Platz im Plan – fest je Möbel (_jitter)
const GARDEN_TABLE_TURN := 1.5
const GARDEN_CHAIR_TURN := Vector2(3.0, 8.0)
const GARDEN_CHAIR_SHIFT := 0.05
## Spiegel über dem Waschbecken-Kasten (Mirror, ohne Modell): Breite höchstens, Unter- und Oberkante über dem Boden,
## so nah rechnet er
const MIRROR_WIDTH := 0.6
const MIRROR_BOTTOM := 1.1
const MIRROR_TOP := 1.95
const MIRROR_RANGE := 6.0
const MIRROR_GAP := 0.03   ## vor der Wand
## Bad und Bar aus den Modellen des Nutzers (tools/build_fixtures.py, Maße von dort). Die Flächen „tiles“ bekommen
## die Fliesen des Raums in Weltkoordinaten: Waschtisch und Duschsockel messen Vielfache einer Fliese (5 cm) und
## stehen auf dem Fugenraster, die Fugen laufen von Boden und Wand her durch. Fehlt eine Datei, bleiben die Kästen.
const WASHBASIN_MODEL := "res://assets/models/washbasin.glb"
const SHOWER_MODEL := "res://assets/models/shower.glb"
const TOILET_MODEL := "res://assets/models/toilet.glb"
const BAR_COUNTER_MODEL := "res://assets/models/bar_counter.glb"
const BACK_BAR_MODEL := "res://assets/models/back_bar.glb"
const BAR_STOOL_MODEL := "res://assets/models/bar_stool.glb"
## Waschtisch (Breite, Stärke, Tiefe; 20 × 3 × 10 Fliesen) und seine Oberkante – das Aufsatzbecken steht 12,6 cm
## darauf, die Armatur reicht bis 28 cm darüber. Am langen Waschtisch der Toiletten je WASH_PLACE ein Becken. Der
## Tisch steht an der Wandfläche (Fugenraster), das Becken auch: Sein Rand stößt an die Fliesen auf der Wand, die
## Rosetten der Armatur liegen bündig auf ihnen.
const WASH_TABLE := Vector3(1.0, 0.15, 0.5)
const WASH_TABLE_TOP := 0.75
const WASH_PLACE := 0.8
## Spiegel über dem Becken: Rahmen ab MIRROR_FRAME_BOTTOM (über der Armatur), darin das Spiegelbild (Mirror) mit
## Mitte MIRROR_GLASS_MID über der Rahmenunterkante – von 1,10 bis 2,04 m: Figuren von 1,45 bis 2,00 m sehen
## darin Scheitel und Bauch (Spielkonzept 3.9)
const MIRROR_FRAME_BOTTOM := 1.07
const MIRROR_GLASS := Vector2(0.54, 0.94)
const MIRROR_GLASS_MID := 0.5
## Spiegelleuchte im Bad (Lamp.Style.MIRROR): so breit wie der Spiegelrahmen, Mitte des Balkens über dem Boden (der
## Rahmen endet bei 2,07 m), Helligkeit und Reichweite
const MIRROR_LAMP_WIDTH := 0.6
const MIRROR_LAMP_Y := 2.12
const MIRROR_LAMP_ENERGY := 0.35
const MIRROR_LAMP_RANGE := 3.5
## Duschecke in Plangröße: Sockel 10 cm (2 Fliesenreihen), Wanne darauf bis SHOWER_TRAY, Glas bis SHOWER_GLASS_H,
## Glaswand (lokal +X) und Tür (+Z) SHOWER_GLASS_INSET innerhalb der Kante. Kollision über der Wanne bis
## SHOWER_BLOCK – zu hoch zum Hinaufsteigen, damit das NavMesh niemanden durchs Glas hineinschickt.
const SHOWER_SIZE := 1.1
const SHOWER_TRAY := 0.16
const SHOWER_GLASS_H := 2.24
const SHOWER_GLASS_INSET := 0.019
const SHOWER_BLOCK := 0.5
## Wand-WC: Schüssel (Breite, Sitzhöhe, Tiefe ab der Wand), Sitzmitte vor der Wand; der Papierhalter (lokal +X)
## reicht so weit zur Seite – steht dort eine Wand, kommt er auf die andere Seite
const TOILET_BOWL := Vector3(0.363, 0.42, 0.54)
const TOILET_SIT := 0.27
const TOILET_HOLDER_REACH := 0.5
const TOILET_CHROME := Color(0.5, 0.5, 0.53)   ## Drückerplatte und Halter: dunkles Chrom
## Theke (L, Rückschenkel bei −X): Korpus des langen Schenkels und des Rückschenkels (x0, z0, x1, z1), Platte des
## langen Schenkels (darauf Flasche, Dosen, Kaffee), Oberkante; sie reicht hinten BAR_RETURN bis an die Platte des
## Barregals. Barregal: Tiefe (Ursprung in der Mitte), Korpus für die Kollision, Glasböden (Oberkanten, Mitte
## der Tiefe) und Mitten der vier Fächer – darauf die Flaschen.
const BAR_ARM := Rect2(-3.45, 0.35, 6.9, 0.75)
const BAR_RETURN_BODY := Rect2(-3.45, -1.1, 0.75, 1.45)
const BAR_TOP_ARM := Rect2(-3.51, 0.405, 7.02, 0.755)
const BAR_TOP := 1.2
const BAR_RETURN := 1.16
const BACK_BAR_DEPTH := 0.56
const BACK_BAR_BODY := Vector3(6.0, 2.7, 0.5)
const BACK_BAR_SHELVES: Array[float] = [1.56, 1.91]
const BACK_BAR_SHELF_Z := -0.11
const BACK_BAR_BAYS: Array[float] = [-2.19, -0.73, 0.73, 2.19]
## Barhocker vor der Theke: so viele, Mitte so weit vor der Plattenkante, Sitzhöhe, Polster
const BAR_STOOLS := 6
const BAR_STOOL_OUT := 0.45
const BAR_STOOL_SEAT := 0.83
const BAR_CUSHION := Color(0.45, 0.08, 0.07)
const DOORMAT_H := 0.012
## Süßigkeiten-Truhe (Truhe aus dem Plan in einem Hotelzimmer, Spielkonzept 6.13): Höhe, Holz, Inhalt
const SWEETS_CHEST_H := 0.32
const SWEETS_CHEST_COLOR := Color(0.55, 0.22, 0.1)
const SWEETS_CHEST_COUNT := 6
const RECEPTION_H := 1.1
## Hotelregister so weit neben der Mitte der Rezeptionsfront (zwischen Kerze und Kartenblatt, 2.3)
const REGISTER_SHIFT := 0.35
## Tischklingel (ZIM-146): so weit auf der anderen Seite der Mitte (zwischen Kerze und Register), so weit zur Kundenseite
const BELL_SHIFT := 0.3
const BELL_OUT := 0.06
## Rezeption als U mit runden vorderen Ecken (tools/build_reception.py): Holzkorpus, Platte im Terrazzo der Säulen,
## zwei Messingrohre; Kundenseite nach +Z, Ursprung mittig im Grundriss am Boden, Grundriss 5 × 1,5 m wie im Plan.
## Fehlt die Datei, bleiben die Kästen aus dem Plan.
const RECEPTION_MODEL := "res://assets/models/reception.glb"
## Teppiche aus dem Plan: Art → Textur (TexGen); Oberseite knapp über dem Boden
const RUG_TEXTURES := {"runner": "runner"}
const RUG_Y := 0.01
## Teppich (Planfarbe „Teppich: Teppich“, ZIM-158) und ohne ihn der feste vor der Rezeption: Farbe, Maß, Mitte
const LOBBY_RUG := Color(0.32, 0.07, 0.08)
const LOBBY_RUG_SIZE := Vector2(6.0, 8.0)
const LOBBY_RUG_AT := Vector2(0.0, -5.0)
## Teppiche im Katzenraum auf dem Holzboden (nicht im Plan): Mitte als Anteil der Raumgrenzen, Größe quer × längs
## in Metern (längs = +Z vor der Drehung), Drehung in Grad, Farbe (TexGen.RUG_COLORS). Ein Texturpixel ≈ RUG_PIXEL.
const CAT_ROOM_RUGS := [
	{"at": Vector2(0.5, 0.52), "size": Vector2(5.0, 7.0), "yaw": 0.0, "colors": 0},
	{"at": Vector2(0.3, 0.2), "size": Vector2(1.8, 2.8), "yaw": 96.0, "colors": 2},
	{"at": Vector2(0.72, 0.18), "size": Vector2(1.5, 2.2), "yaw": 80.0, "colors": 1},
	{"at": Vector2(0.38, 0.84), "size": Vector2(2.0, 3.2), "yaw": 86.0, "colors": 3},
	{"at": Vector2(0.82, 0.78), "size": Vector2(1.4, 2.2), "yaw": 0.0, "colors": 4},
	{"at": Vector2(0.2, 0.55), "size": Vector2(1.2, 1.8), "yaw": 12.0, "colors": 1},
]
const RUG_PIXEL := 0.08
## Wandsachen: Abstand zur Wandfläche (bündig, ohne Flimmern) und Höhen über dem Boden
const WALL_GAP := 0.01
const SWITCH_Y := 1.3
const CALENDAR_Y := 1.7
const POOL_SHOWER_GAP := 0.002   ## Manschetten liegen auf den Fliesen auf
const POOL_DEPTH := 1.4          ## Hallenbad: Beckenboden so tief unter dem Umgang
const UV_Y := 1.5
const COBWEB_Y := 2.4
## Schrift im Haus (Zimmernummern an den Türen, Aufzug): Cinzel Bold (OFL, assets/fonts/OFL.txt; ohne überlappende
## Konturen aus tools/build_font.py) als echte Geometrie (TextMesh). Schilder über den Türen gibt es keine mehr
## (Entscheidung 31.10.): beschriftet sind nur die Gästezimmer, mit einer Messingplakette (RoomPlate).
## Schriftgröße und CURVE_STEP in Schriftpixeln
const SIGN_FONT := "res://assets/fonts/cinzel_bold.ttf"
const SIGN_FONT_SIZE := 16
const SIGN_CURVE_STEP := 2.0
## Ersatzbirnen liegen im Lagerregal, nicht obendrauf
const BULB_SUPPLY_Y := 1.4
## Kisten mit starker Deko ohne Nachschub (Spielkonzept 5.10): so viele Stücke je Dekokiste, Wäschekiste und alte Deko
## im Heizkeller
const DECO_BOX_SIZE := 15
const LAUNDRY_BOX_SIZE := 8
const OLD_DECO_SIZE := 10
## Heizkeller (Boiler, PipeKit): Kesselmitte so weit vor der Ostwand; Rohrmitte so weit vor den Wänden, die
## Ringleitung so weit unter der Decke, der Rücklauf so hoch über dem Boden
const BOILER_WALL := 1.1
const PIPE_WALL := 0.16
const PIPE_RING := 0.4
const PIPE_LOW := 0.45
## Reifegrade der Kürbispflanzen in Planreihenfolge (von Norden nach Süden, je Beet von Westen nach Osten)
const PLANT_STAGES := [0, 3, 2, 3, 1, 3]
## Umkleiden und Duschen am Pool sind eine Lichtgruppe (ohne Schalter, ALWAYS_LIT)
const CHANGING_ROOMS := ["vorraum", "dusche_west", "dusche_ost", "umkleide_west", "umkleide_ost"]
## davon wie ein Bad: Fliesen bis BATH_TILE_HEIGHT, darüber gestrichen, Fliesenboden, gestrichene Decke
## (Wände über _skin_kind, Boden und Decke in _floors_and_ceilings; ZIM-145, Duschen seit 31.10.)
const TILED_CHANGING_ROOMS := ["umkleide_west", "umkleide_ost", "dusche_west", "dusche_ost"]
## Lichtgruppen (_light_room_at) ohne Schalter: Das Licht brennt immer, die Leuchtmittel sind fest verbaut
## (Lamp.fixed, ZIM-145) – Schalter im Plan entfallen dort
const ALWAYS_LIT := ["umkleiden"]
## Flächenarten ohne Namen im Plan → Name (Schalter, Zonen)
const KIND_NAMES := {"cat_room": "Katzenraum", "library": "Bibliothek", "bath": "Bad", "balcony": "Balkon",
	"office": "Büro der Direktion", "secretariat": "Sekretariat",
	"terrace": "Terrasse", "toilet": "Toilette", "storage": "Lager", "cellar": "Keller", "boiler_room": "Heizkeller",
	"plant_room": "Technikraum", "laundry_room": "Wäscherei", "cellar_room": "Kellerraum", "trash_room": "Müllraum",
	"gravel": "Kiesweg", "bowling_lane": "Bowlingbahn", "foul_line": "Bowlingbahn"}
## Kratzbaum (Spielkonzept 7.7): Höhe der oberen Liegefläche
const CAT_TREE_TOP := 1.45
## Aushangbrett (Spielkonzept 2.5): an der Westwand der Lobby zwischen Glastür zur Bar und Wandleuchte – man sieht es,
## wenn man aus dem Ostflur (Zimmer 13) hereinkommt; Mitte der Tafel so hoch
const NOTICE_BOARD_Z := -16.6
const NOTICE_BOARD_Y := 1.55

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
## Haushalt je Zimmernummer (aus HOUSEHOLDS_PATH, Spielkonzept 6.20) und Zimmerart je Nummer (_index_households)
var households := {}
var _room_kinds := {}
var lobby_center := Vector3.ZERO
## Tanzplätze im Partyraum, von der Mitte der Tanzfläche nach außen sortiert (Social.free_party_spot)
var party_spots: Array[Vector3] = []
var party_center := Vector3.ZERO
var lobby_seats: Array[Vector3] = []
## Liegeplätze der Hotelkatzen auf Möbeln (6.11): {"floor": davor auf dem Boden, "top": obendrauf}
var cat_perches: Array[Dictionary] = []
var kitchen_spot := Vector3.ZERO
var kitchen_spots: Array[Vector3] = []   ## Stehplätze der Gäste in der Küche, Raster KITCHEN_SPOT_STEP (ZIM-155)
var garden_spots: Array[Vector3] = []
var garden_beds: Array[Rect2] = []   ## Kürbisbeete (Erde) – dort wächst kein Gras (Grass)
## Bäume: {pos (Stammachse am Boden), radius (Krone), height, crown (Höhenbereich der Krone als Anteile)} – für die
## Fledermäuse (Bats)
var tree_spots: Array[Dictionary] = []
## Fallendes Laub je Baum – Weather lässt es im Wind schneller und schräg fallen (7.8)
var leaf_emitters: Array[CPUParticles3D] = []
## Stützbalken auf dem Dachboden: {pos (Fuß des Pfostens), arms (Array von [Richtung, Länge] je Arm des Balkenkreuzes)} –
## dort hängen tagsüber Fledermäuse (Bats, Spielkonzept 4.22)
var attic_beams: Array[Dictionary] = []
var player_spawn := Vector3.ZERO
var player_door_front := Vector3.ZERO
var record_player_pos := Vector3.ZERO
## Dunkle Ecke des Partyraums (dort bleibt die Tanzfläche frei)
var party_corner := Vector3.ZERO
var game_table: GameTable
var chess_table: ChessTable
## Friedhof (Spielkonzept 5.15) aus dem Plan: Grabplätze {pos, head} (head = Richtung zum Kopfende mit dem Kreuz) und
## die Gedenkstätte {pos, front, size}
var grave_slots: Array[Dictionary] = []
const ARCH_POST_H := 1.9    ## Torbogen aus Hecke: Höhe der Pfosten
const ARCH_RISE := 0.55     ## so hoch wölbt sich der Bogen darüber
const ARCH_INSET := 0.25    ## Pfosten mittig auf dem Heckenende (keine Fuge, 1,3 m Durchgang)
var memorial_spot: Dictionary = {}
var dart_board: DartBoard                ## Darts in der Bar (Spielkonzept 6.10) – aus dem Plan oder DART_FALLBACK
var bar_table: GameTable                 ## zweiter Würfeltisch im Plan: Barspiele (6.10); ohne ihn der erste
var game_cabinet: GameCabinet            ## Spieleschrank in der Bar (Spielkonzept 6.10) – CABINET_FALLBACK
var slot_machine: SlotMachine            ## Spielautomat in der Bar (Spielkonzept 6.10) – SLOT_FALLBACK
var arcades: Array[ArcadeMachine] = []   ## Videoautomaten in der Bar (Spielkonzept 6.10) – Möbel „Videoautomat“
var bowling: BowlingLane                ## Bowlingbahn in der Bar (Spielkonzept 6.10) – Flächen „Bowlingbahn“/„Foullinie“
var bar_spots: Array[Vector3] = []
var diary: Diary
## Zimmer → Mitte der Platte seines ersten Tischs (global) – dort liegt etwa Gustavs Tagebuch (Spielkonzept 2.6)
var room_tables := {}
var room_table_axes := {}   ## Zimmernummer → halbe Länge des Tischs entlang seiner langen Seite (global)
## Futtertisch der Krähen (Spielkonzept 4.25): der Tisch im Gärtchen von Zimmer 13, den der Nutzer in den Plan setzt –
## {pos: Mitte der Platte (global), size: Grundfläche (x, z)}; {} = (noch) keiner im Plan
var feed_table := {}
## Plätze aus dem Plan für Dinge, die ohne Planeintrag an festen Stellen im Code stehen (ZIM-158): Art → Array von
## {level, pos (lokal: Mitte bzw. Punkt auf der Wandfläche), out (Blick in den Raum bzw. zur Vorderseite), rect (lokal,
## nur Möbel), at (global, auf dem Boden)}. Abfrage: planned_at, im Builder _planned_here.
var planned := {}
## Gartentüren der Zimmer im Erdgeschoss: Nummer → Array von {pos (global), out (nach draußen)} – das Krähennest sitzt im
## Baum gegenüber der von Zimmer 042 (Crows, 4.25)
var garden_doors := {}
## Mitte der Platte des Lobby-Couchtischs (global) – dort legt Hugo Dorés Druck hin (Spielkonzept 4.32)
var lobby_table := Vector3.INF
## Aushangbrett in der Lobby (Spielkonzept 2.5) und Innenmaß der Lobby (x, z)
var notice_board: NoticeBoard
var lobby_rect := Rect2()
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
var _cellar_center := Vector3.ZERO
## Jedes Zimmer des Plans, auch verschlossene: Nummer → {pos (Mitte am Boden), look (zur Tür)}
var _room_spots := {}
var _upper_plans: Array[Dictionary] = []
var _attic := false                   ## das geladene Stockwerk ist das Dachgeschoss (Plan „DG“)
var _attic_shaft := ""                ## Treppenhaus, das hinauf ins Dachgeschoss führt (im Stockwerk darunter offen)
var _eaves: Array[Dictionary] = []    ## Dachgeschoss: Außenwände mit Schräge {horizontal, fixed, from, to, inward}
var _roof_windows: Array[Dictionary] = []   ## Dachgeschoss: Dachfenster aus dem Plan {pos, width}
var _window_shafts: Array[SpotLight3D] = []   ## Dachgeschoss: Licht durch die Dachfenster (an AtticHaze)
var _wall_top := Callable()           ## Dachgeschoss: Oberkante der Wand gerade im Bau (lokal x → y, unter der Schräge)

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
var _hall_wallpapers := {}            ## Tapete im EG → dieselbe ohne Leiste, Höhe ab dem EG-Boden
var _named := {}                    ## Flächen-ID → Rect2 (Umriss)
## Wandstücke des Plans, an die Wandsachen gehängt werden: {horizontal, at (Mittellinie), from, to, half (halbe Dicke)}
var _wall_index: Array[Dictionary] = []
var _wainscot_runs: Array[Dictionary] = []   ## Wandseiten mit Vertäfelung (_note_wainscot), je Stockwerk
var _post_spans: Array[Dictionary] = []      ## Holzpfeiler und Eckstücke an waagerechten Wänden: z, Bereich in x (_corner_posts)
var _wainscot_corners: Array = []   ## Eckstücke der Vertäfelung (_wainscot_corner): Ecke, Normalen A und B, Längen
## Wandstöße für _joint_depth/_joints_on (siehe _index_joints)
var _faces := {}
var _ends := {}
## Gebaute Möbel und die Rezeption: {kind, rect: Rect2, top (Oberkante), front: Vector2, node}
var _furnishings: Array[Dictionary] = []
var _doors: Array[Dictionary] = []    ## {pos: Vector3 (Mitte unten), door: Door, kind, into}
var attic_doors: Array[Door] = []     ## Kniestocktüren aller Ebenen
var attic_haze: AtticHaze             ## Staubnebel im Dachgeschoss (null ohne Plan „DG“)
var attic_spook: AtticSpook           ## Blitz-Dreh in den Kammern des Dachbodens (null ohne Plan „DG“)
var register_spot := Transform3D()    ## Hotelregister auf der Rezeption (2.3): auf der Platte, +Z zu den Gästen
var desk_bell: DeskBell               ## Tischklingel auf der Rezeption (ZIM-146)
var pumpkin_head_spot := Vector3.INF  ## wo der Kopf des Kürbismanns liegt (rotes Kreuz im Plan „DG“)
var attic_stair_foot := Transform3D() ## Fuß der Dachbodentreppe im Obergeschoss, Blick hinauf (Debug --dachboden=treppe)
var attic_window_spots: Array[Transform3D] = []   ## unter jedem Dachfenster, Blick zu ihm (Debug --dachboden=fenster)
var _attic_posts: Array[Vector2] = []  ## Stützbalken des Dachgeschosses (der Kopf lehnt daneben)
var elevators: Array[Elevator] = []   ## Aufzüge (je Schacht einer, der erste fährt)
var _elevator_doors: Array[Dictionary] = []   ## Aufzugtüren aller Stockwerke (_elevators baut sie)
var structure_parts: Array[Node] = []   ## Wände, Böden, Decken – für ShadowBudget.merge und StaticExport
var light_rooms := LightRooms.new()     ## Bereiche fürs Licht aus Wänden, Türen und Öffnungen des Plans (ShadowBudget)
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
var _lane_floor: Material       ## Bowlingbahn (28.10.): helles, glänzend versiegeltes Holz
var _foul_line: Material
var _floor_tiles: Material
var _lobby_floor: Material
var _pool_tiles: Material
var _bath_tiles: Material
var _bath_paint: Material
var _kitchen_floor: Material
var _kitchen_tiles: Material
var _dining_floor: Material
var _pool_wall: Material
var _pool_floor: Material
var _pillar_stone: Material
var _pillar_porous: ShaderMaterial
var _grass: Material
var _stone: Material
var _deck_under: Material   ## dunkel unter den Brettern des Holzdecks (_deck_base)
var _gravel: Material
var _ceramic: Material
var _doormat: Material
var _cellar_wall: Material
var _cellar_floor: Material
var _cellar_ceiling: Material
var _attic_planks: Material
var _attic_roof: Material


func _init(p_root: Node3D, p_world: Node3D) -> void:
	root = p_root
	world = p_world
	_parent = root


## Liest den Gebäudeplan neu ein (python tools/build_map.py), wenn Plan, Legende oder Umsetzer neuer sind als die
## älteste Karte – nur beim Start aus den Quellen (Editor, `godot --path .`); im Export fehlt der Plan.
static func refresh_maps() -> void:
	if not OS.has_feature("editor") or not FileAccess.file_exists(PLAN_SOURCES[0]):
		return
	var built := 0
	for path: String in [MAP_PATH, LOWER_MAP_PATH] + UPPER_MAP_PATHS:
		var t := FileAccess.get_modified_time(path) if FileAccess.file_exists(path) else 0
		built = t if built == 0 else mini(built, t)
	var newest := 0
	for path: String in PLAN_SOURCES:
		if FileAccess.file_exists(path):
			newest = maxi(newest, FileAccess.get_modified_time(path))
	if newest <= built:
		return
	print("Gebäudeplan geändert – lese ihn neu ein (tools/build_map.py) …")
	# Python schreibt in dieselbe Codepage, in der Godot die Ausgabe liest; Zeichen außerhalb werden ersetzt
	OS.set_environment("PYTHONIOENCODING", ":replace")
	var out := []
	var code := OS.execute("python", [ProjectSettings.globalize_path("res://tools/build_map.py"),
		ProjectSettings.globalize_path(PLAN_SOURCES[0]), ProjectSettings.globalize_path("res://assets/maps")], out, true)
	for line: String in "".join(out).split("\n"):
		if line.begins_with("  Warnung") or line.contains("Error") or line.contains("Traceback"):
			push_warning("build_map: " + line.strip_edges())
	if code != 0:
		push_warning("build_map: fehlgeschlagen (Code %d) – das Spiel nimmt die alten Karten" % code)


## Liest HAUSHALTE.md neu ein (python tools/build_households.py), wenn sie oder der Umsetzer neuer sind als die
## Datendatei – wie refresh_maps nur beim Start aus den Quellen.
static func refresh_households() -> void:
	if not OS.has_feature("editor") or not FileAccess.file_exists(HOUSEHOLD_SOURCES[0]):
		return
	var built := FileAccess.get_modified_time(HOUSEHOLDS_PATH) if FileAccess.file_exists(HOUSEHOLDS_PATH) else 0
	var newest := 0
	for path: String in HOUSEHOLD_SOURCES:
		newest = maxi(newest, FileAccess.get_modified_time(path))
	if newest <= built:
		return
	print("Haushalte geändert – lese HAUSHALTE.md neu ein (tools/build_households.py) …")
	OS.set_environment("PYTHONIOENCODING", ":replace")
	var out := []
	var code := OS.execute("python", [ProjectSettings.globalize_path("res://tools/build_households.py"),
		ProjectSettings.globalize_path(HOUSEHOLD_SOURCES[0]), ProjectSettings.globalize_path(HOUSEHOLDS_PATH)], out, true)
	if code != 0:
		push_warning("build_households: fehlgeschlagen (Code %d) – %s" % [code, "".join(out).strip_edges()])


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
	for plan in uppers:
		if String(plan.get("floor", "")) == "DG" and not (plan["stairs"] as Array).is_empty():
			_attic_shaft = String(plan["stairs"][0]["id"])
	if "--attic-door" in OS.get_cmdline_user_args() and _attic_shaft == "":
		_debug_attic_door(uppers[0] if _has_upper else ground)
	_begin_floor(ground, 0)
	_index_shafts()
	_build_plan_floor()
	_lobby_hall()
	if _has_upper:
		_lobby_flight()
	else:
		_gallery()
	_common_rooms()
	_dart_fallback()
	_bar_games_fallback()
	_bowling_lane()
	_pool()
	_gardens()
	_stairwells()
	_floors = [_state()]
	for i in uppers.size():
		if String(uppers[i].get("floor", "")) == "DG":
			_attic_floor(uppers[i], i + 1)
		else:
			_upper_floor(uppers[i], i + 1)
	_lower_floor(lower)
	_elevators()
	light_rooms.finish()
	ShadowBudget.merge(structure_parts, world)
	_use(_floors[0])
	var home: Dictionary = rooms[PLAYER_ROOM]
	player_spawn = (home["center"] as Vector3) + Vector3(0, 0.05, 0) + (home["into"] as Vector3) * 0.1
	player_door_front = home["door_front"]
	_mask_hooks()
	_zones()
	_waypoints()


## Was jedes Stockwerk aus seinem Plan baut: Wände, Böden und Decken, Zimmer, Einrichtung, Lichter.
func _build_plan_floor() -> void:
	for w in _map["walls"]:
		_build_wall(w)
	_corner_posts()
	_wainscot()
	_floors_and_ceilings()
	for info in _map["rooms"]:
		_room(info)
	var first_furnishing := _furnishings.size()
	_furniture()
	_rugs()
	_fittings()
	_items()
	_drawer_content(first_furnishing)
	_note_room_tables(first_furnishing)
	_note_gardens(first_furnishing)
	_lights()


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


## Treppenhaustüren dieses Stockwerks absperren – offen ist nur das Treppenhaus Ost und unter dem Dachgeschoss das
## Treppenhaus, das hinaufführt (_attic_stair).
func _seal_stairwells() -> void:
	for s in _map["stairs"]:
		if s["id"] == _attic_shaft and _level == _top_level - 1:
			continue
		if s["kind"] == "stairwell" and s["id"] != "treppenhaus_ost" and s.has("door"):
			var door := _door_near(_v3(s["door"]["pos"]), 0.8)
			if door:
				_seal(door, "Das Treppenhaus ist abgesperrt.")


## Plan eines Stockwerks laden und seine Nachschlagetabellen neu aufbauen.
func _begin_floor(plan: Dictionary, level: int) -> void:
	var lobby := _lobby
	_map = plan
	_level = level
	_attic = String(plan.get("floor", "")) == "DG"
	_base_y = UP_Y * level
	_grid = PackedInt32Array()
	_places = []
	_named = {}
	_wall_index = []
	_wainscot_runs = []
	_post_spans = []
	_wainscot_corners = []
	_faces = {}
	_ends = {}
	_furnishings = []
	_doors = []
	_index_places()
	_index_joints()
	_index_households()
	light_rooms.begin_floor(level, _base_y, root, _grid_origin, _grid_size, _grid, _places)
	for s in _map["stairs"]:   # eine Treppe führt hinauf, Treppenhäuser gehen durch alle Stockwerke
		light_rooms.opening(_rect(s["rect"]), true, s["kind"] == "stairwell")
	for rc in _map["open_above"]:
		light_rooms.opening(_rect(rc), true, false)
	for rc in _map["voids"]:
		light_rooms.opening(_rect(rc), false, true)
	if level > 0:
		_lobby = lobby   # die Galerie über der Lobby gehört zur Halle (rote Tapete, Lobby-Licht)
	elif level < 0:
		_lobby = Rect2()
	else:
		_halls = []
		for rc in _map["open_above"]:
			var r := _rect(rc)
			_halls.append({"rect": r, "kind": _kind_at(r.get_center())})


## Zustand des geladenen Stockwerks (für _use).
func _state() -> Dictionary:
	return {"map": _map, "level": _level, "attic": _attic, "base_y": _base_y, "grid": _grid, "grid_origin": _grid_origin,
		"grid_size": _grid_size, "places": _places, "lobby": _lobby, "named": _named, "wall_index": _wall_index,
		"faces": _faces, "ends": _ends, "furnishings": _furnishings, "doors": _doors}


func _use(s: Dictionary) -> void:
	_map = s["map"]
	_level = s["level"]
	_attic = s["attic"]
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
## Läuft für jede Abfrage von Gästen und Monster – ist das Stockwerk schon geladen (meist das EG), ohne Umladen.
func _on_floor(level: int, f: Callable) -> Variant:
	if int(_floors[level]["level"]) == _level:
		return f.call()
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
		var r := _rect(rc)
		var to_landing := -_dir(String(s.get("door", {}).get("side", "south")))
		var frame := Transform3D(Basis(Vector3.UP, atan2(-to_landing.x, -to_landing.y)), Vector3(r.get_center().x, 0, r.get_center().y))
		_shafts[String(s["id"])] = {"rect": r, "frame": frame, "plan": s}


func _materials() -> void:
	_wallpaper = Mat.wallpaper(H, UP_Y)
	_room_wallpaper = Mat.wallpaper(H, UP_Y, "beige")   # nur in den Zimmern
	_lobby_wallpaper = Mat.wallpaper(H, UP_Y, "red")
	_facade = Mat.photo(FACADE_TEX, FACADE_METERS, FACADE_NORMAL)
	(_facade as ShaderMaterial).set_shader_parameter("normal_strength", FACADE_NORMAL_STRENGTH)
	_wall_tiles = Mat.psx(Color(0.82, 0.88, 0.9), "tiles", 1.0)
	_concrete = Mat.psx(Color(0.8, 0.8, 0.8), "concrete", 0.5)
	_wood = Mat.psx(Color(0.45, 0.28, 0.15))
	_dark_wood = Mat.psx(Color(0.22, 0.13, 0.08))
	_ceiling = Mat.photo(CEILING_TEX, CEILING_METERS, CEILING_NORMAL, CEILING_ROUGHNESS, CEILING_SPECULAR, CEILING_SHADE)
	_room_ceiling = Mat.photo(CEILING_TEX, CEILING_METERS, CEILING_NORMAL, CEILING_ROUGHNESS, CEILING_SPECULAR, ROOM_CEILING_SHADE)
	_hedge = Mat.psx(Color(1, 1, 1), "hedge", 1.0)
	_carpet = Mat.psx(Color(1, 1, 1), "carpet", 1.0)
	_wood_floor = Mat.photo(WOOD_FLOOR_TEX, WOOD_FLOOR_METERS, WOOD_FLOOR_NORMAL, WOOD_FLOOR_ROUGHNESS, WOOD_FLOOR_SPECULAR)
	_floor_tiles = Mat.psx(Color(1, 1, 1), "tiles", 0.5)
	_lane_floor = Mat.lane_boards(LANE_TINT)
	_lane_floor.set_meta("floor", "wood")
	_lane_floor.set_shader_parameter("specular", LANE_SPECULAR)
	_lane_floor.set_shader_parameter("roughness", LANE_ROUGHNESS)
	_lane_floor.set_shader_parameter("metallic", LANE_MIRROR)
	_foul_line = Mat.psx(FOUL_LINE_COLOR)
	_lobby_floor = Mat.photo(LOBBY_FLOOR_TEX, LOBBY_FLOOR_METERS, LOBBY_FLOOR_NORMAL, LOBBY_FLOOR_ROUGHNESS, LOBBY_FLOOR_SPECULAR)
	_lobby_floor.set_meta("floor", "tiles")   # Schritte klingen wie auf den übrigen Fliesen (Footsteps)
	_lobby_floor.set_shader_parameter("metallic", LOBBY_FLOOR_MIRROR)
	_lobby_floor.set_shader_parameter("roughness_scale", LOBBY_FLOOR_ROUGHNESS_SCALE)
	_pool_tiles = Mat.photo(POOL_TILES_TEX, POOL_TILES_METERS, POOL_TILES_NORMAL, POOL_TILES_ROUGHNESS, POOL_TILES_SPECULAR)
	_pool_tiles.set_meta("floor", "tiles")
	_bath_tiles = Mat.photo(BATH_TILES_TEX, BATH_TILES_METERS, BATH_TILES_NORMAL, BATH_TILES_ROUGHNESS, POOL_TILES_SPECULAR)
	_bath_tiles.set_meta("floor", "tiles")
	_bath_paint = Mat.photo(BATH_PAINT_TEX, BATH_PAINT_METERS, BATH_PAINT_NORMAL, BATH_PAINT_ROUGHNESS, BATH_PAINT_SPECULAR)
	_kitchen_floor = Mat.photo(KITCHEN_FLOOR_TEX, KITCHEN_TILES_METERS, KITCHEN_FLOOR_NORMAL, KITCHEN_FLOOR_ROUGHNESS,
		POOL_TILES_SPECULAR)
	_kitchen_floor.set_meta("floor", "tiles")
	_kitchen_tiles = Mat.photo(KITCHEN_WALL_TEX, KITCHEN_TILES_METERS, KITCHEN_WALL_NORMAL, KITCHEN_WALL_ROUGHNESS,
		POOL_TILES_SPECULAR)
	_dining_floor = Mat.photo(DINING_FLOOR_TEX, DINING_FLOOR_METERS, DINING_FLOOR_NORMAL, DINING_FLOOR_ROUGHNESS,
		WOOD_FLOOR_SPECULAR)
	_dining_floor.set_meta("floor", "wood")
	_pool_wall = Mat.photo(POOL_WALL_TEX, POOL_WALL_METERS, POOL_WALL_NORMAL)
	_pool_floor = Mat.photo(POOL_FLOOR_TEX, POOL_FLOOR_METERS, POOL_FLOOR_NORMAL, POOL_FLOOR_ROUGHNESS, POOL_FLOOR_SPECULAR)
	_pool_floor.set_meta("floor", "tiles")
	_pillar_stone = Mat.photo(PILLAR_TEX, PILLAR_METERS, "", PILLAR_ROUGHNESS, PILLAR_SPECULAR)
	_pillar_porous = Mat.photo(PILLAR_TEX, PILLAR_METERS, PILLAR_PORES, PILLAR_ROUGHNESS, PILLAR_SPECULAR).duplicate()
	_pillar_porous.set_shader_parameter("normal_tiling", PILLAR_METERS / PILLAR_PORES_METERS)
	_pillar_porous.set_shader_parameter("normal_strength", PILLAR_PORES_STRENGTH)
	_pillar_porous.set_shader_parameter("cavity", PILLAR_PORES_CAVITY)
	# Böden draußen werden im Regen nass (Weather, wet_ground.gdshaderinc) – eigene Materialien, nicht geteilt
	_grass = Mat.psx(Color(1, 1, 1), "grass", 1.0, Color.BLACK, 0.0, false)
	_stone = Mat.psx(Color(0.62, 0.57, 0.5), "concrete", 1.0, Color.BLACK, 0.0, false)
	_gravel = Mat.photo(GRAVEL_TEX, GRAVEL_METERS, GRAVEL_NORMAL).duplicate()
	(_gravel as ShaderMaterial).set_shader_parameter("normal_strength", GRAVEL_NORMAL_STRENGTH)
	Mat.wettable(_grass, WET_GLOSS.x)
	Mat.wettable(_stone, WET_GLOSS.y)
	_deck_under = Mat.psx(Color(0.07, 0.06, 0.05), "concrete", 1.0, Color.BLACK, 0.0, false)
	_deck_under.set_meta("floor", "wood")
	Mat.wettable(_gravel, WET_GLOSS.z)
	_ceramic = Mat.psx(Color(0.88, 0.88, 0.86))
	_doormat = Mat.psx(Color(0.4, 0.3, 0.18))
	# Untergeschoss (Spielkonzept 7.9): Wände aus Brettschalungsbeton, Boden und Decke einfach grau
	_cellar_wall = Mat.photo(CELLAR_WALL_TEX, CELLAR_WALL_METERS, CELLAR_WALL_NORMAL)
	_cellar_floor = Mat.psx(Color(0.45, 0.45, 0.45), "concrete", 1.0)
	_cellar_ceiling = Mat.psx(Color(0.5, 0.5, 0.5), "concrete", 0.5)
	_attic_planks = Mat.planks(ATTIC_PLANK_TINT)
	_attic_planks.set_meta("floor", "wood")
	_attic_roof = Mat.psx(ATTIC_ROOF_COLOR, "concrete", 1.0)


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
			_lobby = _rect(rc)
	for info in _map["rooms"]:
		if _wing_open(String(info["wing"])):
			_open_rooms[String(info["no"])] = true
		# Bäder gehören zum Zimmer hinter ihrer Tür
		for d in info.get("bath_doors", []):
			var bath := _place_at(_v2(d["pos"]) + _v2(d["normal"]) * 0.4)
			if not bath.is_empty() and bath["kind"] == "bath":
				_bath_owner[String(bath["id"])] = String(info["no"])


## Vorsatz der Raum-IDs auf diesem Stockwerk („“ im EG, „og1_“ darüber, „dg_“ im Dachgeschoss, „ug_“ darunter).
func _prefix() -> String:
	if _level < 0:
		return "ug_"
	if _attic:
		return "dg_"
	return "" if _level == 0 else "og%d_" % _level


## Rechteck des Plans [x0, z0, x1, z1] → Rect2 (x, z).
func _rect(rc: Array) -> Rect2:
	return Rect2(rc[0], rc[1], rc[2] - rc[0], rc[3] - rc[1])


func _bounds(rects: Array) -> Rect2:
	var r := _rect(rects[0])
	for rc in rects:
		r = r.merge(_rect(rc))
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
		"garden", "gravel", "terrace", "balcony":
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


## Sind die Zimmer dieses Flügels auf dem Stockwerk, das gerade gebaut wird, schon bewohnbar?
func _wing_open(wing: String) -> bool:
	return wing in (OPEN_WINGS_UPPER if _level > 0 else OPEN_WINGS)


## Haushalte dieses Stockwerks den Zimmern zuordnen: Jeder Haushalt (und jedes Sonderzimmer) hängt an einer Stelle
## im Plan (Pixel im Band des Stockwerks) – das Zimmer, dessen Fläche sie enthält, bekommt ihn.
func _index_households() -> void:
	if not FileAccess.file_exists(HOUSEHOLDS_PATH):
		return
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(HOUSEHOLDS_PATH))
	var origin: Array = _map["origin_px"]
	var mpp := float(_map["meters_per_pixel"])
	var at := func(entry: Dictionary) -> String:
		var px: Array = entry["px"]
		var p := Vector2((float(px[0]) - float(origin[0])) * mpp, (float(px[1]) - float(origin[1])) * mpp)
		for info in _map["rooms"]:
			for rc in info["rects"]:
				if _rect(rc).grow(0.05).has_point(p):
					return String(info["no"])
		push_warning("HAUSHALTE.md: kein Zimmer an der Stelle von %s (%s)" % [entry.get("id", entry.get("label")), px])
		return ""
	for entry: Dictionary in data.get("special", []):
		if int(entry["floor"]) == _level:
			var no: String = at.call(entry)
			if no != "":
				_room_kinds[no] = String(entry["kind"])
	for entry: Dictionary in data.get("households", []):
		if int(entry["floor"]) == _level:
			var no: String = at.call(entry)
			if no != "":
				_room_kinds[no] = "guest"
				households[no] = entry


## Name eines Haushalts an seiner Tür (6.20, beim Hinsehen) und im Hotelregister: mehrere Personen – Nachname, eine –
## Vor- und Nachname.
static func door_name(household: Dictionary) -> String:
	var members: Array = household["members"]
	if members.size() == 1:
		return "%s %s" % [members[0]["name"], household["surname"]]
	return String(household["surname"])


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
	if _in_shaft(a) and _in_shaft(b):
		return   # Mittelwand im Treppenhaus: baut _stairwells über alle Stockwerke
	var horizontal := is_equal_approx(a.y, b.y)
	var along := Vector2(1, 0) if horizontal else Vector2(0, 1)
	var side := Vector2(0, 1) if horizontal else Vector2(1, 0)   # „Plus“-Seite: Süden bzw. Osten
	var s0 := a.x if horizontal else a.y
	var s1 := b.x if horizontal else b.y
	var fixed := a.y if horizontal else a.x
	var openings: Array = w.get("openings", [])
	var glass := bool(w.get("glass", false))
	light_rooms.wall(a, b, float(w.get("thickness", T)))
	if glass:   # Glaswand: je Meter ein Fenster fürs Licht
		var panes := maxi(1, roundi((s1 - s0) / 1.0))
		for i in panes:
			light_rooms.window(a + along * (i + 0.5) * (s1 - s0) / panes, side)

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
	# Stoßkante der beiden Stücke ab (sonst blitzt dort der Boden dahinter durch)
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
	# sonst klafft in der Ecke eine Fuge, durch die der Boden dahinter blitzt. Endet
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
		if _attic and minus[i] != "attic" and plus[i] != "attic":
			continue   # Dachgeschoss: Striche ohne Dachboden daneben (Umriss des Treppenschachts) baut _attic_stair
		if glass:
			_glass_wall(horizontal, fixed, p0, p1)
		else:
			_wall_piece(horizontal, fixed, m0, m1, mine, minus[i], plus[i])
			var half := float(w.get("thickness", T)) / 2.0
			_note_wainscot(horizontal, fixed, half, -1.0, p0, p1, mine, minus[i])
			_note_wainscot(horizontal, fixed, half, 1.0, p0, p1, mine, plus[i])
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
## Wände – senkrechte stoßen immer an eine waagerechte. Reine Optik wie die Türrahmen. Quadratisch, 3 cm vor beiden
## Wandflächen und 5 cm vor der Stirnseite, im Holz der Türen und der Vertäfelung (Mat.hotel_wood): Sockel mit
## Fase, Stufe und Karnies, Schaft mit senkrechter Faser, Kapitell mit Rundstab, Hohlkehle und Deckplatte.
func _corner_posts() -> void:
	var wood := Mat.hotel_wood()
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
			var inner := 0.0   # Seite mit Innenecke (dort stößt eine senkrechte Wand bündig mit dem Kopf an)
			for s: float in [-1.0, 1.0]:
				kinds.append(_kind_at(Vector2(end.x - ex * 0.3, end.y + s * 0.3)))
				if not _vertical_at(end.x - ex * half, end.y + s * half):   # sonst Innenecke
					convex = true
					kinds.append(_kind_at(Vector2(end.x + ex * 0.3, end.y - s * 0.3)))
				else:
					inner = s
			if not convex or "outside" in kinds:
				_wainscot_corner(end, ex, half)
				continue
			var mats := {}
			for k in kinds:
				var m := _wall_material(k)
				mats[m if m else _skin_material(k)] = true
			if mats.size() < 2:
				_wainscot_corner(end, ex, half)
				continue
			var s := half + 0.03   # halbe Breite des Schafts
			var pos := Vector2(end.x + ex * (0.05 - s), end.y)
			var at := Vector3(pos.x, 0, pos.y)
			var variant := posmod(int(round(pos.x * 7.0 + pos.y * 13.0)), 4)   # andere Maserung je Pfeiler
			var shift := Vector2(0.53, 0.29) * variant
			# An der Innenecke endet der Pfeiler an den Wandflächen des Raums (2 mm darin), sonst ragten Schaft, Sockel
			# und Kapitell in seine Ecke; die anstoßende Wand ist so stark wie diese.
			var notch := Vector4(-ex, inner, 2.0 * half + 0.05 - s - 0.002, half - 0.002) if inner != 0.0 else Vector4.ZERO
			Geo.mesh(root, Geo.square_profile(_post_base(s), false, shift, 35.0, notch), wood, at)
			Geo.mesh(root, Geo.square_profile([Vector2(s, POST_BASE), Vector2(s, H - POST_CAP)], true, shift, 35.0,
				notch), wood, at)
			Geo.mesh(root, Geo.square_profile(_post_cap(s), false, shift, 35.0, notch), wood, at)
			# Die Vertäfelung läuft 2 mm in den Schaft (sie ist flacher als sein Vorsprung), unten deckt der Sockel sie
			var reach := s - 0.002
			_post_spans.append({"z": end.y, "span": Vector2(pos.x - reach, pos.x + reach)})


## Außenecken eines Wandkopfs ohne Holzpfeiler, an denen die Vertäfelung auf beiden Flächen läuft: Eckstück mit Gehrung
## (Wainscot.add_corner), sonst endeten beide Stücke offen an der Ecke und der Kopf bliebe kahl. Es läuft
## Wainscot.CORNER weit an der Wandseite entlang (dort endet die Vertäfelung, _post_spans) und über den Kopf – bis zur
## anstoßenden Wand bzw. bis zur Mitte, wenn auch die andere Seite eine Außenecke ist.
func _wainscot_corner(end: Vector2, ex: float, half: float) -> void:
	for s: float in [-1.0, 1.0]:
		if _vertical_at(end.x - ex * half, end.y + s * half):   # Innenecke
			continue
		if not (_wainscoted(_wall_side_kind(Vector2(end.x - ex * 0.3, end.y + s * 0.3)))
				and _wainscoted(_wall_side_kind(Vector2(end.x + ex * 0.3, end.y + s * 0.3)))):
			continue
		var across := 2.0 * half if _vertical_at(end.x - ex * half, end.y - s * half) else half
		_wainscot_corners.append([Vector3(end.x, 0, end.y + s * half), Vector3(0, 0, s), Vector3(ex, 0, 0),
			Wainscot.CORNER, across])
		var cut := Vector2(end.x - ex * Wainscot.CORNER, end.x)
		_post_spans.append({"z": end.y, "span": Vector2(minf(cut.x, cut.y), maxf(cut.x, cut.y))})


## Profil des Pfeilersockels um den Schaft der halben Breite s: Block, Fase, Stufe, Karnies (oben hohl, unten voll)
## hinauf zum Schaft.
func _post_base(s: float) -> Array:
	var o := POST_PLINTH
	var p := [Vector2(s + o, 0.0), Vector2(s + o, 0.185), Vector2(s + o - 0.007, 0.192), Vector2(s + 0.017, 0.192),
		Vector2(s + 0.017, 0.2)]
	for i in range(1, 9):   # Karnies von (s + 0,017 | 0,2) nach (s | POST_BASE)
		var t := float(i) / 8.0
		var x := s + 0.017 * (1.0 - (3.0 * t * t - 2.0 * t * t * t))
		p.append(Vector2(x, lerpf(0.2, POST_BASE - 0.006, t)))
	p.append(Vector2(s, POST_BASE))
	return p


## Profil des Kapitells über dem Schaft der halben Breite s bis zur Decke: Rundstab, Plättchen, Hohlkehle, Plättchen,
## Deckplatte mit Wulst darunter.
func _post_cap(s: float) -> Array:
	var y := H - POST_CAP
	var p := [Vector2(s, y)]
	for i in range(1, 8):   # Rundstab, 1,6 cm hoch
		var a := PI * float(i) / 8.0
		p.append(Vector2(s + 0.008 * sin(a), y + 0.008 - 0.008 * cos(a)))
	y += 0.016
	p.append_array([Vector2(s, y), Vector2(s + 0.004, y + 0.003), Vector2(s + 0.004, y + 0.012)])
	y += 0.012
	for i in range(1, 9):   # Hohlkehle 4,4 cm hinaus, 5 cm hoch
		var a := PI / 2.0 * float(i) / 8.0
		p.append(Vector2(s + 0.048 - 0.044 * cos(a), y + 0.05 * sin(a)))
	y += 0.05
	p.append_array([Vector2(s + 0.054, y), Vector2(s + 0.054, y + 0.008)])
	y += 0.008
	for i in range(1, 7):   # Wulst unter der Deckplatte, 1,8 cm hoch
		var a := PI / 2.0 * float(i) / 6.0
		p.append(Vector2(s + 0.054 + 0.012 * sin(a), y + 0.018 * (1.0 - cos(a))))
	p.append_array([Vector2(s + 0.066, H - 0.06), Vector2(s + 0.07, H - 0.056), Vector2(s + 0.07, H)])
	return p


## Wandseite für die Vertäfelung merken (Spielkonzept 7.2): Seite side (−1 = Nord- bzw. Westseite) der Wand bei fixed
## von p0 bis p1 mit den Öffnungen openings (Vector4 wie _opening_vec), Raumart kind (_wainscoted).
func _note_wainscot(horizontal: bool, fixed: float, half: float, side: float, p0: float, p1: float, openings: Array,
		kind: String) -> void:
	if _wainscoted(kind):
		_wainscot_runs.append({"horizontal": horizontal, "fixed": fixed, "half": half, "side": side, "from": p0,
			"to": p1, "openings": openings})


## Trägt die Wandseite der Raumart kind Vertäfelung? Alle mit Tapete außer Treppenhäusern, Aufzügen, verschlossenen
## Zimmern und Lufträumen über dem EG.
func _wainscoted(kind: String) -> bool:
	if _level < 0 or _attic:
		return false
	if kind.begins_with("hall:"):
		if _level > 0:
			return false
		kind = kind.trim_prefix("hall:")
	return kind not in ["stairs", "elevator", "sealed"] and _wall_material(kind) != null


## Vertäfelung der gemerkten Wandseiten (Wainscot): freie Stücke zwischen anstoßenden Wänden, Türen (bis unter die
## Bekleidung) und Holzpfeilern im Raster, unter Fenstern das Teil ohne Leiste. Ein Halbfeld kommt an das Ende an
## einer Tür oder einem Fenster.
func _wainscot() -> void:
	if _wainscot_runs.is_empty():
		return
	var kit := Wainscot.new()
	# Außenkante der Bekleidung neben der Öffnung (OpeningFrame; DoorCasing reicht 9,6 cm), 1 cm darunter geschoben
	var reach := 0.086 - 0.01
	for run in _wainscot_runs:
		var horizontal: bool = run["horizontal"]
		var side: float = run["side"]
		var face: float = float(run["fixed"]) + side * float(run["half"])
		var free: Array[Vector2] = [Vector2(run["from"], run["to"])]
		var windows: Array[Vector2] = []
		var edges: Array[float] = []   # Enden an Türen und Fenstern
		for op: Vector4 in run["openings"]:
			if op.w < Wainscot.HEIGHT - 0.01:   # Vector4 rechnet in 32 Bit: die Fensterbank 0,9 käme knapp darunter an
				var door := Vector2(op.x - op.y / 2.0 - reach, op.x + op.y / 2.0 + reach)
				free = _cut_span(free, door)
				edges.append_array([door.x, door.y])
			elif op.w < Wainscot.HEIGHT + 0.2:
				windows.append(Vector2(op.x - op.y / 2.0 - reach - 0.01, op.x + op.y / 2.0 + reach + 0.01))
				edges.append_array([windows[-1].x, windows[-1].y])
		for blk in _wainscot_blocks(horizontal, face, side, float(run["fixed"])):
			free = _cut_span(free, blk)
		var under: Array[Vector2] = []
		for win in windows:
			for f in free:
				if win.x < f.y and win.y > f.x:
					under.append(Vector2(maxf(win.x, f.x), minf(win.y, f.y)))
			free = _cut_span(free, win)
		var origin := Vector3(0, 0, face) if horizontal else Vector3(face, 0, 0)
		var along := Vector3(1, 0, 0) if horizontal else Vector3(0, 0, 1)
		var out := Vector3(0, 0, side) if horizontal else Vector3(side, 0, 0)
		var at_edge := func(t: float) -> bool: return edges.any(func(e: float) -> bool: return absf(e - t) < 0.001)
		for f in free:
			kit.add_run(origin, along, out, f.x, f.y, false, at_edge.call(f.y) and not at_edge.call(f.x))
		for u in under:
			kit.add_run(origin, along, out, u.x, u.y, true)
	for c: Array in _wainscot_corners:
		kit.add_corner(c[0], c[1], c[2], c[3], c[4])
	kit.finish(root)


## Was die Vertäfelung auf der Fläche face (Seite side der Wand bei fixed) unterbricht, als Bereiche entlang der Wand:
## senkrecht anstoßende oder durchlaufende Wände und Holzpfeiler.
func _wainscot_blocks(horizontal: bool, face: float, side: float, fixed: float) -> Array[Vector2]:
	var blocks: Array[Vector2] = []
	for w in _map["walls"]:
		var a := _v2(w["a"])
		var b := _v2(w["b"])
		if is_equal_approx(a.y, b.y) == horizontal:
			continue
		var at := a.x if horizontal else a.y
		var r0 := minf(a.y, b.y) if horizontal else minf(a.x, b.x)
		var r1 := maxf(a.y, b.y) if horizontal else maxf(a.x, b.x)
		var reaches := (r0 <= face + 0.02 and r1 >= face + 0.02) if side > 0.0 else (r1 >= face - 0.02 and r0 <= face - 0.02)
		if reaches:
			var h := float(w.get("thickness", T)) / 2.0
			blocks.append(Vector2(at - h, at + h))
	if horizontal:
		for post in _post_spans:
			if absf(float(post["z"]) - fixed) < 0.01:
				blocks.append(post["span"])
	return blocks


## Bereiche spans ohne cut (Reste unter 1 mm fallen weg).
func _cut_span(spans: Array[Vector2], cut: Vector2) -> Array[Vector2]:
	var result: Array[Vector2] = []
	for s in spans:
		if cut.y <= s.x or cut.x >= s.y:
			result.append(s)
			continue
		if cut.x - s.x > 0.001:
			result.append(Vector2(s.x, cut.x))
		if s.y - cut.y > 0.001:
			result.append(Vector2(cut.y, s.y))
	return result


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
		"door", "service_door", "frosted_door":
			return Vector4(center, width, DOOR_H if width < 1.5 else WIDE_DOOR_H, 0.0)
		"attic_door", "attic_inner_door":
			return Vector4(center, width, float(o.get("height", ATTIC_DOOR_H)), 0.0)
	return Vector4(center, width, WIDE_DOOR_H, 0.0)


## Art einer Wandseite: wie _kind_at, an einem Luftraum aber „hall:<Art im EG>“ – im EG darunter wie darüber
## (dort liegt im Plan keine Fläche, die Seite wäre sonst draußen und trüge Fassade).
func _wall_side_kind(p: Vector2) -> String:
	if _level >= 0 and not _attic:
		for hall in _halls:
			if (hall["rect"] as Rect2).has_point(p):
				return "hall:" + String(hall["kind"])
	return _skin_kind(p, _kind_at(p))


## Umkleiden und Duschen am Pool: Fliesen bis BATH_TILE_HEIGHT wie im Bad (ZIM-145), Küche bis unter die Decke
## gefliest – nur für die Wandflächen, sonst bleiben sie Betriebsräume (Türrichtung, Lampen, Namen)
func _skin_kind(p: Vector2, kind: String) -> String:
	var look := _look(kind, _room_id_at(p)) if kind == "service" else kind
	return kind if look == "dining" else look   # im Speisesaal nur der Boden eigen, die Wände tapeziert


## Aussehen eines Betriebsraums mit eigenen Böden, Wänden oder Decken: „bath“ (gefliest wie das Bad), „kitchen“,
## „dining“; sonst die Art selbst
func _look(kind: String, id: String) -> String:
	if kind != "service":
		return kind
	if id in TILED_CHANGING_ROOMS:
		return "bath"
	return {KITCHEN_ROOM: "kitchen", DINING_ROOM: "dining"}.get(id, kind)


func _wall_material(kind: String) -> Material:
	if _level < 0:
		return _cellar_wall   # im Untergeschoss überall Beton
	if _attic:
		return _attic_planks
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
		"room", "sealed", "library", "office", "secretariat":
			return _room_wallpaper
		"lobby", "cat_room":
			return _lobby_wallpaper   # rote Rauten
		"corridor", "bar", "bowling_lane", "foul_line", "party", "service", "stairs", "elevator":
			return _wallpaper
	return null


func _skin_material(kind: String) -> Material:
	if _level < 0:
		return null
	match kind:
		"outside":
			return _facade
		"toilet":
			return _wall_tiles
		"bath":
			return _bath_tiles   # nur bis BATH_TILE_HEIGHT, darüber _bath_paint (_wall_piece_at)
		"kitchen":
			return _kitchen_tiles
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
	var top := ATTIC_H if _attic else H
	if _attic:   # unter der Dachschräge folgt die Oberkante ihr (Kniestock an den Außenwänden)
		_wall_top = func(s: float) -> float: return _attic_ceiling(Vector2(s, fixed) if horizontal else Vector2(fixed, s)) + drop
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
		_wall_piece_at(horizontal, fixed, p0, p1, lifted, minus, plus, top + drop)
		_parent = keep
		_wall_top = Callable()
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
	# Häute (Fliesen, Fassade, Beton) liegen auf der Wandfläche selbst: je Seite eigene Flächen (Geo.wall_mesh mit
	# sides), im Bad Fliesen bis BATH_TILE_HEIGHT über dem Boden (über dem EG beginnt die Wand height − H darunter),
	# darüber gestrichen. Lokal +Z ist bei waagerechten Wänden die Plus-Seite, bei senkrechten die Minus-Seite.
	var faces := {}
	var split := 0.0
	for s: float in [-1.0, 1.0]:
		var kind := minus if s < 0 else plus
		var own: Material = m_minus if s < 0 else m_plus
		var skin := _skin_material(kind)
		var name := "plus" if (s > 0) == horizontal else "minus"
		var low: Material = skin if skin else (own if own else _wallpaper)
		var top := low
		if skin and kind == "bath":
			split = BATH_TILE_HEIGHT + height - H
			top = _bath_paint
		faces[name] = low
		faces[name + "_top"] = top
		if skin:   # freie Stirnseiten (eingezogene Wände) wie die geflieste Seite, nicht in der Tapete des Rests
			faces["ends"] = low
			faces["ends_top"] = top
	if _skin_material(minus) == null and _skin_material(plus) == null:
		faces = {}
	if horizontal:
		_wall_x(fixed, p0, p1, openings, mat, height, faces, split)
	else:
		_wall_z(fixed, p0, p1, openings, mat, height, faces, split)


## Aufzüge (Spielkonzept 7.4, 7.10): die Aufzugtüren aller Stockwerke nach Schacht gesammelt, je Schacht ein
## Elevator unter der Hauptszene (bewegte Kabine, nicht im NavMesh). Rahmen = Tür im EG (lokal +Z aus dem Schacht).
## Der westlichste Schacht fährt, die übrigen sind tot (7.10: einer wird repariert, der andere bleibt der Weg des
## Monsters).
func _elevators() -> void:
	var shafts := {}
	for o in _elevator_doors:
		var r: Rect2 = o["shaft"]
		if not r.has_area():
			continue
		var key := Vector2i(roundi(r.get_center().x * 10.0), roundi(r.get_center().y * 10.0))
		if not shafts.has(key):
			shafts[key] = []
		shafts[key].append(o)
	var keys := shafts.keys()
	keys.sort_custom(func(a: Vector2i, b: Vector2i) -> bool: return a.x < b.x or (a.x == b.x and a.y < b.y))
	for key: Vector2i in keys:
		var list: Array = shafts[key]
		list.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a["y"]) < float(b["y"]))
		var ref: Dictionary = list[0]
		var stops: Array[float] = []
		var levels: Array[int] = []
		for o: Dictionary in list:
			stops.append(float(o["y"]))
			levels.append(int(o["level"]))
			if int(o["level"]) == 0:
				ref = o
		var c: Vector2 = ref["center"]
		var out: Vector2 = ref["out"]
		var frame := Transform3D(Basis(Vector3.UP, atan2(out.x, out.y)), Vector3(c.x, 0, c.y))
		var r: Rect2 = ref["shaft"]
		var local := Rect2()
		for k in 4:
			var corner := r.position + r.size * Vector2(k & 1, k >> 1)
			var p := frame.affine_inverse() * Vector3(corner.x, 0, corner.y)
			local = Rect2(p.x, p.z, 0, 0) if k == 0 else local.expand(Vector2(p.x, p.z))
		var lift := Elevator.new().setup(elevators.is_empty(), stops, levels, ref["size"], local)
		lift.name = "Aufzug_%d" % (elevators.size() + 1)
		lift.transform = frame
		world.add_child(lift)
		elevators.append(lift)


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
	pane.collision_layer = HotelWindow.LAYER_GLASS
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
		light_rooms.window(c, side)
		return
	if kind == "elevator_door":   # Türen, Anzeige und Kabine baut _elevators je Schacht über alle Stockwerke
		var to_shaft := side if _kind_at(c + side * 0.5) == "elevator" else -side
		var shaft := _place_at(c + to_shaft * 0.5)
		_elevator_doors.append({"center": c, "out": -to_shaft, "size": Vector2(width, _opening_vec(o, 0.0).z),
			"y": _base_y, "level": _level, "shaft": _bounds(shaft["rects"]) if not shaft.is_empty() else Rect2()})
		light_rooms.window(c, side)
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
	match kind:   # gemalte Modelle (tools/build_doors.py): Zimmertüren und die Türen im Dachgeschoss
		"door":
			door.look = Door.Look.HOTEL
		"attic_door", "attic_inner_door":
			door.look = Door.Look.ATTIC
		"frosted_door":   # Pool, Duschen, Umkleiden (ZIM-143)
			door.look = Door.Look.FROSTED
	door.position = center - right * width / 2.0
	door.rotation.y = yaw
	root.add_child(door)
	_doors.append({"pos": center, "door": door, "kind": kind, "into": into3, "hinge": hinge})
	light_rooms.door(c, side, door)
	match kind:
		"main_entrance" when _level < 0:   # Untergeschoss: verschlossene Räume in der Farbe des Haupteingangs
			_seal(door, "Abgeschlossen.")
		"main_entrance":
			door.locked = true
			door.key_id = "ausgang"
			door.monster_can_open = false
			door.locked_text = "Der Ausgang ist verriegelt. Es muss einen anderen Weg hinaus geben …"
		"attic_door":   # Schlüssel im Heizraum hinter dem Gitter (4.21) – das Monster bricht sie nicht auf
			door.locked = true
			door.key_id = "dachboden"
			door.monster_can_open = false
			door.locked_text = "Die niedrige Tür ist abgeschlossen."
			attic_doors.append(door)
	if k_minus == "sealed" or k_plus == "sealed":
		_seal(door, "Abgeschlossen.")
	elif kind == "garden_door" and (k_minus == "outside") != (k_plus == "outside"):
		# Fenstertür: Der Lakengeist kommt auch hierher (Spielkonzept 4.18)
		var out := side * (-1.0 if k_minus == "outside" else 1.0)
		door.outward = Vector3(out.x, 0, out.y)
		door.room_id = _room_id_at(c - out * 0.5)
		door.add_to_group("french_doors")


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


## Debug --attic-door: Ohne Dachgeschoss im Plan wird die erste 0,8 m breite Tür des Plans (OG1, sonst EG) zur
## Kniestocktür – zum Ansehen, main.gd stellt dich davor (mit Dachgeschoss vor die echte).
static func _debug_attic_door(plan: Dictionary) -> void:
	for w: Dictionary in plan["walls"]:
		for o: Dictionary in w.get("openings", []):
			if o["kind"] == "door" and is_equal_approx(float(o["width"]), 0.8):
				o["kind"] = "attic_door"
				return


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
		holes.append(_rect(rc))
	if not _has_upper:
		holes.append(_lobby)   # die Lobby-Decke ist der Boden der Galerie (_gallery)
	for r in _map["regions"]:
		var kind := String(r["kind"])
		if kind == "elevator":
			continue   # Schacht offen über alle Stockwerke – Grube und Decke baut der Aufzug (Elevator)
		# Verschlossene Zimmer und Kellerräume: Boden nur zum Draufstehen (Debug-Teleport), auf der Ebene der Decken –
		# nicht im NavMesh, sonst planten Gäste und Monster Wege durch abgesperrte Türen
		var layer := LAYER_CEILING if (kind == "room" and not _room_open(String(r["id"]))) or kind == "cellar_room" else 1
		var look := _look(kind, String(r.get("id", "")))
		var ceilings := {"room": _room_ceiling, "bath": _bath_paint, "kitchen": _bath_paint}
		var ceiling: Material = _cellar_ceiling if _level < 0 else ceilings.get(look, _ceiling)
		if kind in ["terrace", "balcony"]:
			_deck(r)
		for rc in r["rects"]:
			if kind != "pool_water":   # das Becken baut _pool, die Decke darüber ist die Holzdecke der Halle
				_floor(look, rc, layer)
			if not bool(r["outdoor"]):
				for piece in _subtract(_rect(rc), holes):
					_ceiling_slab(piece, ceiling)
	for p in _map["floor_patches"]:
		for rc in p["rects"]:
			_floor(String(p["kind"]), rc)
			if not bool(p["outdoor"]):
				for piece in _subtract(_rect(rc), holes):
					_ceiling_slab(piece, _ceiling)
	for rs in _map["terrace_edges"] + _map.get("balcony_edges", []):
		for rc in rs:
			_floor_rect(rc, _stone)
	for rc in _map.get("hedge_arches", []):   # Rasen unter dem Torbogen
		_floor_rect(rc, _grass)
	# Über einem Luftraum (Lobby, Partyraum) schließt die Decke dieses Stockwerks die Halle nach oben ab
	for rc in _map["voids"]:
		_ceiling_slab(_rect(rc), _ceiling)
	# Schwellen: unter jeder Tür liegt die Wand – ohne Boden dort risse das NavMesh ab
	for d in _doors:
		var door: Door = d["door"]
		if door.monster_can_open:
			var into: Vector3 = d["into"]
			var size := Vector3(door.width, 0.2, T) if absf(into.z) > 0.5 else Vector3(T, 0.2, door.width)
			Geo.solid(root, size, (d["pos"] as Vector3) + Vector3(0, -0.1, 0), _wood)


## Deckenplatte über r (H … H + 0,2) auf der Ebene der Decken.
func _ceiling_slab(r: Rect2, mat: Material) -> void:
	structure_parts.append(Geo.solid(root, Vector3(r.size.x, 0.2, r.size.y), Vector3(r.get_center().x, H + 0.1, r.get_center().y), mat,
		LAYER_CEILING))


## Boden über dem EG: 0,3 m stark, liegt auf der Decke darunter (H … H + 0,2) auf – keine Fuge an Lufträumen
## und Balkonkanten, keine doppelte Fläche mit der Decke.
func _floor_rect(rc: Array, mat: Material, layer: int = 1) -> void:
	var thick := 0.2 if _level <= 0 else UP_Y - H - 0.2
	var size := Vector3(float(rc[2]) - float(rc[0]), thick, float(rc[3]) - float(rc[1]))
	structure_parts.append(Geo.solid(root, size, Vector3((float(rc[0]) + float(rc[2])) / 2.0, -thick / 2.0,
		(float(rc[1]) + float(rc[3])) / 2.0), mat, layer))


## Unter dem Holzdeck (Terrasse, Balkon – ZIM-127): Kollision wie ein Boden (Oberkante y = 0, dort stehen die
## Bretter), sichtbar ist die Platte aber DECK_DROP tiefer und dunkel – das sieht man durch die Fugen. Schritte
## klingen nach Holz (Meta „floor“ am Material).
func _deck_base(rc: Array, layer: int) -> void:
	var thick := 0.2 if _level <= 0 else UP_Y - H - 0.2
	var size := Vector3(float(rc[2]) - float(rc[0]), thick, float(rc[3]) - float(rc[1]))
	var body := Geo.collider(root, size, Vector3((float(rc[0]) + float(rc[2])) / 2.0, -thick / 2.0,
		(float(rc[1]) + float(rc[3])) / 2.0), layer)
	Geo.mesh(body, Geo.box(size), _deck_under, Vector3(0, -DECK_DROP, 0))
	structure_parts.append(body)


## Holzdeck einer Terrasse oder eines Balkons (Deck, ZIM-127). Die Bretter laufen von der Hauswand weg: quer zu der
## Seite, hinter der auf der längsten Strecke das Haus liegt (ohne Hauswand entlang der langen Seite). Zur Wand
## bleibt DECK_WALL_GAP, zur Hecke bzw. zum Geländer (Kantenstreifen im Plan) DECK_EDGE_GAP, zu Rasen und Kies nichts.
func _deck(region: Dictionary) -> void:
	var rects: Array[Rect2] = []
	for rc in region["rects"]:
		rects.append(_rect(rc))
	var edges: Array[Rect2] = []
	for rs in _map["terrace_edges"] + _map.get("balcony_edges", []):
		for rc in rs:
			edges.append(_rect(rc))
	var in_region := func(p: Vector2) -> bool: return rects.any(func(r: Rect2) -> bool: return r.has_point(p))
	# Hauswand je Seite (0 = x, 1 = z): wie lang die Kante ist, hinter deren Wand drinnen ist
	var house := [0.0, 0.0]
	for r in rects:
		for side in 4:
			var out := [Vector2(-1, 0), Vector2(1, 0), Vector2(0, -1), Vector2(0, 1)][side] as Vector2
			var along := Vector2(absf(out.y), absf(out.x))
			var start := r.position if side % 2 == 0 else r.end - along * (r.size.x if out.y != 0.0 else r.size.y)
			var length := r.size.x if out.y != 0.0 else r.size.y
			var t := 0.1
			while t < length:
				var p := start + along * t
				if not in_region.call(p + out * 0.05) and _kind_at(p + out * 0.4) != "outside":
					house[0 if out.x != 0.0 else 1] += 0.2
				t += 0.2
	var bounds := rects[0]
	for r in rects:
		bounds = bounds.merge(r)
	# Hauswand quer zu x (Seite links/rechts) → Bretter laufen entlang x
	var along_x: bool = house[0] > house[1] if house[0] != house[1] else bounds.size.x >= bounds.size.y
	var gap_at := func(p: Vector2, out: Vector2) -> float:
		var q := p + out * 0.1
		if edges.any(func(e: Rect2) -> bool: return e.has_point(q)):
			return DECK_EDGE_GAP
		return DECK_WALL_GAP if _place_at(q).is_empty() else 0.0
	Deck.build(root, rects, along_x, gap_at, hash([_level, String(region.get("id", ""))]))


## Boden eines Plan-Rechtecks. Flure tragen Teppich, nur in der Lobby Fliesen: Ragt ein Flurrechteck in die
## Lobby (der Südflur läuft als ein Stück quer hindurch), wird es an deren Rand geteilt.
func _floor(kind: String, rc: Array, layer: int = 1) -> void:
	if kind in ["terrace", "balcony"]:
		_deck_base(rc, layer)
		return
	if kind != "corridor":
		_floor_rect(rc, _floor_material(kind), layer)
		return
	var r := _rect(rc)
	var inside := r.intersection(_lobby) if _level == 0 else Rect2()   # die Galerie trägt Teppich
	if inside.has_area():
		_floor_rect([inside.position.x, inside.position.y, inside.end.x, inside.end.y], _lobby_floor)
	for piece in (_subtract(r, [_lobby]) if _level == 0 else [r]):
		_floor_rect([piece.position.x, piece.position.y, piece.end.x, piece.end.y], _carpet)


func _floor_material(kind: String) -> Material:
	if _level < 0:
		return _cellar_floor
	match kind:
		"room", "bar", "party", "cat_room", "library", "office", "secretariat":
			return _wood_floor
		"garden":
			return _grass
		"gravel":
			return _gravel
		"terrace", "balcony":
			return _stone
		"storage":
			return _concrete
		"pool_deck":
			return _pool_floor
		"bath":
			return _bath_tiles
		"kitchen":
			return _kitchen_floor
		"dining":
			return _dining_floor
		"bowling_lane":
			return _lane_floor
		"foul_line":
			return _foul_line
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
	if not _wing_open(String(plan["wing"])):
		return   # Bauphase: Tür verschlossen (_opening_object), kein Inneres
	assert(door != null, "Zimmer %s: keine Tür an der Stelle aus dem Plan" % no)
	var kind: String = _room_kinds.get(no, ROOM_KINDS.get(no, "vacant"))
	if bool(plan.get("vacant", false)) != (kind in ["vacant", "abandoned", "derelict", "locked"]):
		push_warning("Gebäudeplan: Zimmer %s ist im Plan %s, laut HAUSHALTE.md %s" % [no,
			"leer" if plan.get("vacant", false) else "bewohnt", kind])
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
		"baths": _room_baths(plan, holder),
	}
	if not plan.get("suite", false):   # Suiten betritt man durchs Nachbarzimmer: keine Plakette an der Verbindungstür
		door.add_room_number(no, label, info["door_front"])   # Spion und Plakette mit der Nummer auf der Flurseite
	if households.has(no):
		info["household"] = households[no]
		door.resident_name = door_name(households[no])   # erscheint beim Hinsehen an der Tür (6.20)
	# Das Innere steht im Plan (_furniture, _fittings, _items, _lights); hier nur, was die Zimmerart ausmacht
	match kind:
		"abandoned", "derelict":
			door.set_open.call_deferred(true)   # verlassen bzw. verfallen: die Tür steht offen
		"locked":
			door.locked = true
			door.key_id = "zimmer_18"
			door.locked_text = "Zimmer %s ist abgeschlossen." % label
	door.room_no = no
	if kind in ["guest", "vacant"]:   # Zimmer gehören den Gästen bzw. dem Hotel (Spielkonzept 6.19)
		door.locked = true
		door.key_id = "zimmer_%s" % no
		door.vacant = kind == "vacant"
		door.locked_text = "Zimmer %s ist abgeschlossen." % label
	rooms[no] = info
	_room_spots[no]["pos"] = info["center"]   # Mitte des Rechtecks an der Tür (bei L-Zimmern sicher drinnen)
	_parent = root


## Bäder des Zimmers (Spielkonzept 6.19, Badbenutzung der Gäste): je Badtür {door, id (Raum-ID des Bads), spot (ein
## Stück hinter der Tür im Bad)}.
func _room_baths(plan: Dictionary, holder: Node3D) -> Array:
	var baths := []
	for d in plan.get("bath_doors", []):
		var door := _door_near(_v3(d["pos"]))
		var place := _place_at(_v2(d["pos"]) + _v2(d["normal"]) * 0.4)
		if door == null or place.is_empty() or place["kind"] != "bath":
			continue
		var p := _v2(d["pos"]) + _v2(d["normal"]) * BATH_SPOT_DEPTH
		baths.append({"door": door, "id": String(place["id"]),
			"spot": _global(holder.transform.affine_inverse() * Vector3(p.x, 0.0, p.y))})
	return baths


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
	var rects: Array[Rect2] = []
	for rc in _map["reception"]:
		rects.append(_rect(rc))
	var model := _reception(rects)
	for r in rects:
		var desk: Node3D = model if model else Geo.solid(root, Vector3(r.size.x, RECEPTION_H, r.size.y), Vector3(r.get_center().x, RECEPTION_H / 2.0, r.get_center().y), _dark_wood)
		_furnishings.append({"kind": "reception", "rect": r, "top": RECEPTION_H, "front": Vector2.ZERO, "node": desk})
	var lockers: Array[Dictionary] = []
	var shelves: Array[Dictionary] = []
	for f in _map["furniture"]:
		var rc: Array = f["rect"]
		var rect := _rect(rc)
		var c := rect.get_center()
		if _kind_at(c) == "sealed":
			continue
		var kind := String(f["kind"])
		if kind == "chair" and _room_table_at(c).has_area():
			continue   # die Stühle der Tischgruppe setzt _room_table()
		var front := _facing(String(f.get("facing", "")), c)
		var yaw := atan2(front.x, front.y)
		var pos := Vector3(c.x, 0, c.y)
		var node: Node3D
		var top := 0.0
		match kind:
			"bed", "wardrobe", "double_bed":
				var spot: HideSpot
				if kind == "double_bed":
					spot = _double_bed(rect, String(f.get("head", "")))
					front = Vector2(sin(spot.rotation.y), cos(spot.rotation.y))
				elif kind == "bed":   # Länge quer zur Vorderseite, Breite entlang (Außenmaß des Balkenbetts)
					var deep := rect.size.x if absf(front.x) > 0.5 else rect.size.y
					spot = _hide_spot(HideSpot.Type.BED, pos, yaw, Vector2(rect.size.x + rect.size.y - deep, deep))
				else:
					spot = _hide_spot(HideSpot.Type.WARDROBE, pos, yaw)
				var room: Dictionary = rooms.get(_room_id_at(c), {})
				if not room.is_empty():
					spot.own_bed = kind != "wardrobe" and room["kind"] == "player"
					if kind != "wardrobe":
						spot.room_no = String(room["no"])   # auch fremde Betten (Spielkonzept 3.6)
					if spot.own_bed:   # ein frisches Laken zum Verkleiden (Spielkonzept 5.9)
						_item(Item.Kind.BED_SHEET, pos + Vector3(0, BedModel.blanket_top() + 0.02, 0))
					(room["spots"] as Array).append(spot)
				node = spot
				top = 2.18 if kind == "wardrobe" else BedModel.TOP
			"dresser":
				node = Dresser.new()   # Schubladen (Spielkonzept 3.5)
				top = Dresser.SIZE.y
			"nightstand":
				node = Nightstand.new()   # neben dem Bett, eine Schublade (30.10.)
				top = Nightstand.OUTER.y
			"chest":
				var chest := Chest.new()
				if rooms.has(_room_id_at(c)):
					_sweets_chest(chest, rect, front, pos)
				node = chest
				top = chest.size.y
			"snack_machine", "drink_machine":
				var machine := VendingMachine.new().setup("snack" if kind == "snack_machine" else "cola")
				var across := absf(front.y) > 0.5   # Front nach Norden oder Süden: Breite entlang x
				machine.size = Vector3(rect.size.x if across else rect.size.y, VendingMachine.SIZE.y, rect.size.y if across else rect.size.x)
				node = machine
				top = machine.size.y
			"bathtub":
				var tub := Bathtub.new()
				tub.tiles = _bath_tiles
				var along := absf(front.y) > 0.5   # Front nach Norden oder Süden: Länge entlang x
				tub.size = Vector3(rect.size.x if along else rect.size.y, BOX_HEIGHTS["bathtub"], rect.size.y if along else rect.size.x)
				node = tub
				top = tub.size.y
			"tub_shelf":
				# Ablage zum Anflanschen an die Wanne (24.10.): gefliester Block in Plangröße und Wannenhöhe – die
				# Fliesen liegen in Weltkoordinaten, die Fugen laufen von der Wanne her durch
				top = BOX_HEIGHTS["bathtub"]
				node = Geo.solid(root, Vector3(rect.size.x, top, rect.size.y), Vector3(c.x, top / 2.0, c.y), _bath_tiles)
			"doormat":
				node = Geo.mesh(root, Geo.box(Vector3(rect.size.x, DOORMAT_H, rect.size.y)), _doormat, Vector3(c.x, DOORMAT_H / 2.0, c.y))
				top = DOORMAT_H
			"chess_table":
				chess_table = ChessTable.new()
				node = chess_table
				top = 0.76
			"game_cabinet":
				if game_cabinet != null:
					push_warning("Gebäudeplan: zweiter Spieleschrank bei %s – es gibt nur einen" % c)
					continue
				front = _back_to_wall(rect, front)
				yaw = atan2(front.x, front.y)
				node = _game_cabinet(c - front * (_depth_of(rect, front) - GameCabinet.SIZE.z) / 2.0, yaw)
				top = GameCabinet.SIZE.y
			"slot_machine":   # Jackpot-Automat (6.10): wie die Videoautomaten mit dem Rücken an die nächste Wand
				if slot_machine != null:
					push_warning("Gebäudeplan: zweiter Spielautomat bei %s – es gibt nur einen" % c)
					continue
				front = _back_to_wall(rect, front)
				yaw = atan2(front.x, front.y)
				slot_machine = SlotMachine.new()
				node = slot_machine
				var back := c - front * (_depth_of(rect, front) - SlotMachine.SIZE.z) / 2.0
				pos = Vector3(back.x, 0, back.y)
				top = SlotMachine.SIZE.y
			"doll_house":   # baut DollHouse (5.16) – hier nur der Platz; Pläne mit Norden oben, gedreht nur bei langem z
				_plan(kind, c, Vector2(0, 1) if rect.size.x >= rect.size.y else Vector2(1, 0), rect)
				continue
			"bar_stool" when ResourceLoader.exists(BAR_STOOL_MODEL):   # einzeln gesetzt (ZIM-158), Sitz zur Vorderseite
				node = _fixture_body(BAR_STOOL_MODEL, c, front)
				node.rotation.y += _jitter(rect).randf_range(-0.6, 0.6)   # nicht alle gleich ausgerichtet
				Geo.add_box_shape(node, Vector3(0.4, BAR_STOOL_SEAT, 0.4), Vector3(0, BAR_STOOL_SEAT / 2.0, 0))
				top = BAR_STOOL_SEAT
			"arcade":
				front = _back_to_wall(rect, front)
				yaw = atan2(front.x, front.y)
				var arcade := ArcadeMachine.new().setup(ARCADE_GAMES[arcades.size() % ARCADE_GAMES.size()])
				arcades.append(arcade)
				node = arcade
				var back := c - front * (_depth_of(rect, front) - ArcadeMachine.SIZE.z) / 2.0
				pos = Vector3(back.x, 0, back.y)
				top = ArcadeMachine.SIZE.y
			"game_table":   # der erste mit dem Würfelbecher für Mäxchen, der zweite für die Barspiele (6.10)
				var table := GameTable.new()
				if game_table == null:
					game_table = table
				elif bar_table == null:
					bar_table = table
				node = table
				top = 0.76
			"couch":
				node = _couch(pos, yaw - PI / 2.0)   # das Modell sitzt nach +X
				top = 0.45
			"bench" when _kind_at(c) == "outside" and ResourceLoader.exists(BENCH_MODEL):
				var long_x := rect.size.x >= rect.size.y
				if (absf(front.x) > 0.5) == long_x:   # Vorderseite muss quer zur Länge liegen
					var to := _area_center(c) - c
					front = Vector2(0, -1 if to.y < 0 else 1) if long_x else Vector2(-1 if to.x < 0 else 1, 0)
				yaw = atan2(front.x, front.y)
				node = _bench(maxf(rect.size.x, rect.size.y))
				top = BENCH_SEAT * maxf(rect.size.x, rect.size.y) / BENCH_LENGTH
			"coffee_table" when _lobby.has_point(c):
				yaw = 0.0
				var side := minf(rect.size.x, rect.size.y)
				rect = Rect2(c - Vector2(side, side) / 2.0, Vector2(side, side))   # quadratisch, für _top_at
				node = _coffee_table(side)
				top = BOX_HEIGHTS["coffee_table"]
				lobby_table = Vector3(c.x, _base_y + top, c.y)
			"room_table" when ResourceLoader.exists(ROOM_TABLE_MODEL):
				yaw = 0.0   # Stühle stehen in Weltrichtung (_room_table)
				node = _room_table(rect)
				top = BOX_HEIGHTS["room_table"]
			"sink", "washbasin" when ResourceLoader.exists(WASHBASIN_MODEL):
				# Waschplatz an der Rückwand; im Bad ein Becken, in den Toiletten über die ganze Breite des Plans
				var back := c - front * _depth_of(rect, front) / 2.0
				var width := WASH_TABLE.x if kind == "sink" else _depth_of(rect, Vector2(front.y, front.x))
				node = _washbasin(back, front, width, _bath_tiles if kind == "sink" else _wall_tiles,
					_light_room_at(c) if kind == "sink" else "")
				rect = _local_rect(back, front, Rect2(-width / 2.0, 0, width, WASH_TABLE.z))   # Tischfläche
				top = WASH_TABLE_TOP
			"shower" when ResourceLoader.exists(SHOWER_MODEL):
				node = _shower(c, front)
				node.add_to_group("showers")   # Lakengeist in der Dusche (ShowerScare, Spielkonzept 4.24)
				top = SHOWER_TRAY
			"toilet" when ResourceLoader.exists(TOILET_MODEL):
				node = _toilet(c - front * _depth_of(rect, front) / 2.0, front, c)
				top = BOX_HEIGHTS["toilet"]
			"bar_counter" when ResourceLoader.exists(BAR_COUNTER_MODEL):
				var wall := _bar_wall(rect, front)
				front = wall[1]
				var origin: Vector2 = wall[0] + front * (BACK_BAR_DEPTH + BAR_RETURN)
				node = _bar_counter(origin, front)
				rect = _local_rect(origin, front, BAR_TOP_ARM)   # Platte des langen Schenkels (_common_rooms)
				_furnishings.append({"kind": "bar_return", "rect": _local_rect(origin, front, BAR_RETURN_BODY),
					"top": BAR_TOP, "front": front, "node": node})
				top = BAR_TOP
			"shelf" when ResourceLoader.exists(BACK_BAR_MODEL) and _named.has("bar") and (_named["bar"] as Rect2).has_point(c):
				var back := c - front * _depth_of(rect, front) / 2.0
				node = _back_bar(back, front)
				rect = _local_rect(back, front, Rect2(-BACK_BAR_BODY.x / 2.0, 0, BACK_BAR_BODY.x, BACK_BAR_DEPTH))
				top = BAR_TOP
			"garden_table":
				# leicht gedreht, bei jedem Start gleich (_jitter); quadratisch, die Vorderseite ist egal
				yaw = deg_to_rad(_jitter(rect).randf_range(-GARDEN_TABLE_TURN, GARDEN_TABLE_TURN))
				node = GardenFurniture.table()
				top = GardenFurniture.TABLE_H
			"garden_chair":
				# Blick zur Vorderseite im Plan, dazu fest je Stuhl ein wenig gedreht und verrückt (_jitter)
				var rng := _jitter(rect)
				yaw += deg_to_rad(rng.randf_range(GARDEN_CHAIR_TURN.x, GARDEN_CHAIR_TURN.y)) * (1.0 if rng.randf() < 0.5 else -1.0)
				var shift := Vector2.from_angle(rng.randf() * TAU) * rng.randf_range(0.0, GARDEN_CHAIR_SHIFT)
				c += shift
				rect.position += shift
				pos = Vector3(c.x, 0, c.y)
				node = GardenFurniture.chair()
				top = GardenFurniture.SEAT_FRONT
			"locker_bank":   # erst nach allen Möbeln: die Nummern laufen über alle Blöcke (_locker_banks)
				lockers.append({"rect": rect, "front": front})
				continue
			"bookshelf_4_1", "bookshelf_4_2", "bookshelf_5_1", "bookshelf_5_2":   # erst nach allen: Innenecken (_bookshelves)
				var spec := kind.split("_")
				if String(f.get("facing", "")) == "":   # ohne Vorderseite: quer zur langen Seite, zur Mitte der Fläche
					var to := _area_center(c) - c
					front = Vector2(0, -1 if to.y < 0 else 1) if rect.size.x >= rect.size.y else Vector2(-1 if to.x < 0 else 1, 0)
				shelves.append({"rect": rect, "front": front, "levels": int(spec[1]), "pitch": int(spec[2])})
				continue
			"desk", "secretary_desk":   # Büro der Direktion, Sekretariat (ZIM-154): feste Größe, mittig, Rücken an die Hinterkante des Rechtecks
				var variant := "direktion" if kind == "desk" else "sekretariat"
				var dims := Desk.dims(variant)
				var back := c - front * _depth_of(rect, front) / 2.0
				var mid := back + front * dims.z / 2.0
				pos = Vector3(mid.x, 0, mid.y)
				rect = _local_rect(back, front, Rect2(-dims.x / 2.0, 0, dims.x, dims.z))   # Platte
				node = Desk.new(variant)
				top = dims.y
				if kind == "desk":
					var chair_at := dims.z + Desk.CHAIR_GAP   # Sessel davor (Desk), Gegenstände landen auf dem Polster
					_furnishings.append({"kind": "armchair", "rect": _local_rect(back, front,
						Rect2(-Armchair.SIZE.x / 2.0, chair_at, Armchair.SIZE.x, Armchair.SIZE.z)), "top": Armchair.SEAT_H,
						"front": -front, "node": node})
			"dining_table" when ResourceLoader.exists(DiningTable.MODEL) and DiningTable.fits(rect.size):
				# Tafel (ZIM-157): so groß wie im Plan, Länge entlang der langen Seite, die Vorderseite ist egal
				var long_x := rect.size.x >= rect.size.y
				yaw = 0.0 if long_x else PI / 2.0
				var table := DiningTable.make(Vector2(maxf(rect.size.x, rect.size.y), minf(rect.size.x, rect.size.y)))
				var rng := _jitter(rect)
				table.grain = Vector2(rng.randf() * 7.0, rng.randf() * 7.0)
				node = table
				top = DiningTable.HEIGHT
			"chair":   # Stuhl (ZIM-156): feste Größe, mittig im Rechteck, Sitzseite zur Vorderseite
				node = Chair.new()
				rect = _local_rect(c, front, Rect2(-Chair.SIZE.x / 2.0, -Chair.SIZE.z / 2.0, Chair.SIZE.x, Chair.SIZE.z))
				top = Chair.SEAT_H
			"changing_bench":   # Länge entlang der langen Seite des Rechtecks, ohne Vorderseite
				yaw = 0.0 if rect.size.x >= rect.size.y else PI / 2.0
				node = ChangingBench.make(maxf(rect.size.x, rect.size.y))
				top = ChangingBench.HEIGHT
			"trash_can":
				# fest 50 × 50 cm (TrashCan), mittig auf dem Platz im Plan, aber nicht in der Wand
				c = _clear_of_walls(c, TrashCan.SIZE / 2.0 + TrashCan.WALL_GAP)
				pos = Vector3(c.x, 0, c.y)
				rect = Rect2(c - Vector2.ONE * TrashCan.SIZE / 2.0, Vector2.ONE * TrashCan.SIZE)
				node = TrashCan.new()
				top = TrashCan.HEIGHT
			"pillar":
				node = _pillar(rect)
				top = H
			"grave":   # baut der Friedhof (Cemetery) – hier nur der Platz
				grave_slots.append({"pos": Vector3(c.x, _base_y, c.y), "head": Vector3(-front.x, 0, -front.y)})
				continue
			"memorial":
				memorial_spot = {"pos": Vector3(c.x, _base_y, c.y), "front": Vector3(front.x, 0, front.y), "size": rect.size}
				continue
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
					_supply(ResourceSpot.new().setup(Item.Kind.SHEET_GHOST, "Lakengespenst", LAUNDRY_BOX_SIZE, 0.0), Vector3(lc.x, top, lc.y))
		if node.get_parent() == null:
			node.position = pos
			node.rotation.y = yaw
			root.add_child(node)
		_furnishings.append({"kind": kind, "rect": rect, "top": top, "front": front, "node": node})
	_locker_banks(lockers)
	_bookshelves(shelves)


## Bücherregale der Bibliothek (Bookshelf, ZIM-152): Rücken Bookshelf.BACK_GAP vor der Hinterkante des Rechtecks
## (Vertäfelung), die Zeile entlang der langen Seite, das Profil bleibt im Rechteck. Stoßen zwei gleich hohe Regale über
## Eck aneinander (Innenecke: das andere steht quer am Ende und blickt zurück zur Zeile), enden beide auf einer Gehrung –
## die Kante des Korpus liegt dann auf der Vorderseite des anderen. Ob das eine bis an die Wand reicht oder vor dem
## anderen endet, ist egal.
func _bookshelves(list: Array[Dictionary]) -> void:
	var shelves: Array[Bookshelf] = []
	for a in list:
		var rect: Rect2 = a["rect"]
		var front: Vector2 = a["front"]
		var right := Vector2(front.y, -front.x)   # lokal +X
		var c := rect.get_center()
		var deep := _depth_of(rect, front)
		var half := (rect.size.x + rect.size.y - deep) / 2.0
		var back := c - front * deep / 2.0
		var ends: Array[float] = [-half + Bookshelf.OVERHANG, half - Bookshelf.OVERHANG]
		var corner: Array[bool] = [false, false]
		for b in list:
			if b == a:
				continue
			var b_rect: Rect2 = b["rect"]
			var b_front: Vector2 = b["front"]
			var b_deep := _depth_of(b_rect, b_front)
			# wo b vor a beginnt (entlang front, ab a's Hinterkante)
			var near := minf((b_rect.position - back).dot(front), (b_rect.end - back).dot(front))
			if near < -0.25 or near > deep + 0.25:
				continue
			for i in 2:
				var e := -1.0 if i == 0 else 1.0
				if b_front.dot(right * -e) < 0.9:
					continue
				var b_back := (b_rect.get_center() - b_front * b_deep / 2.0 - back).dot(right)
				if e * b_back < half - 0.25 or e * b_back > half + b_deep + 0.25:
					continue
				if b["levels"] != a["levels"]:
					push_warning("Gebäudeplan: Bücherregale bei %s und %s sind verschieden hoch – keine Ecke" %
						[c, b_rect.get_center()])
					continue
				ends[i] = b_back - e * (Bookshelf.BACK_GAP + Bookshelf.DEPTH)
				corner[i] = true
		var length := ends[1] - ends[0]
		if length < Bookshelf.min_length():
			push_warning("Gebäudeplan: Bücherregal bei %s ist zu kurz (%.2f m)" % [c, length])
			continue
		var shelf := Bookshelf.make(a["levels"], a["pitch"], length, corner[0], corner[1])
		var rng := _jitter(rect)
		shelf.grain = Vector2(rng.randf() * 7.0, rng.randf() * 7.0)
		var at := back + front * (Bookshelf.BACK_GAP + Bookshelf.DEPTH / 2.0) + right * (ends[0] + ends[1]) / 2.0
		shelf.position = Vector3(at.x, 0, at.y)
		shelf.rotation.y = atan2(front.x, front.y)
		root.add_child(shelf)
		shelves.append(shelf)
		_furnishings.append({"kind": "bookshelf", "rect": rect, "top": Bookshelf.height(a["levels"]), "front": front,
			"node": shelf})
	Books.fill(shelves)   # Bücher in alle Fächer (ZIM-153)


## Spindblöcke der Umkleiden (LockerBank, ZIM-145): Rücken an der Hinterkante des Rechtecks im Plan, WALL_CLEAR davor
## (die Fliesenhaut steht vor der Wand), quer mittig. Nummern
## fortlaufend je Stockwerk, je Block LockerBank.PER_BANK: zuerst nach Raum von West nach Ost, im Raum der Block
## „links unten im Plan“ zuerst (kleinstes x − z) – so beginnt jeder Block von vorn gesehen links oben.
func _locker_banks(list: Array[Dictionary]) -> void:
	var room_x := func(c: Vector2) -> float:
		var id := _room_id_at(c)
		return (_named[id] as Rect2).get_center().x if _named.has(id) else c.x
	list.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var ca := (a["rect"] as Rect2).get_center()
		var cb := (b["rect"] as Rect2).get_center()
		var ra: float = room_x.call(ca)
		var rb: float = room_x.call(cb)
		if not is_equal_approx(ra, rb):
			return ra < rb
		return ca.x - ca.y < cb.x - cb.y)
	for i in list.size():
		var rect: Rect2 = list[i]["rect"]
		var front: Vector2 = list[i]["front"]
		var c := rect.get_center()
		var deep := _depth_of(rect, front)
		if absf(deep - LockerBank.DEPTH) > 0.15 or absf(rect.size.x + rect.size.y - deep - LockerBank.LENGTH) > 0.15:
			push_warning("Gebäudeplan: Spindblock bei %s ist %.1f × %.1f m, gebaut wird er %.1f × %.1f m" %
				[c, rect.size.x + rect.size.y - deep, deep, LockerBank.LENGTH, LockerBank.DEPTH])
		var at := c + front * (LockerBank.WALL_CLEAR + LockerBank.DEPTH / 2.0 - deep / 2.0)
		var bank := LockerBank.new()
		bank.first_number = 1 + i * LockerBank.PER_BANK
		bank.position = Vector3(at.x, 0, at.y)
		bank.rotation.y = atan2(front.x, front.y)
		root.add_child(bank)
		# Gegenstände des Plans landen auf der Sitzfläche (_top_at)
		_furnishings.append({"kind": "locker_bank", "rect": rect, "top": LockerBank.SEAT_H, "front": front, "node": bank})


## Teppiche aus dem Plan (Ebene „Teppiche“, Spielkonzept 7.5): flache Auflage ohne Kollision (Schritte hört man
## wie auf dem Boden darunter). Ein Läufer läuft entlang der langen Seite seines Rechtecks, das Muster spannt sich
## quer über die ganze Breite (TexGen._runner). Wo zwei Läufer zusammenstoßen, entscheidet der Plan.
func _rugs() -> void:
	for r in _map["rugs"]:
		var rc: Array = r["rect"]
		var rect := _rect(rc)
		var c := rect.get_center()
		var kind := String(r["kind"])
		if _kind_at(c) == "sealed":
			continue
		if kind == "rug":   # Teppich in Planmaßen (ZIM-158), wie bisher der vor der Rezeption
			_plan(kind, c, Vector2(0, 1), rect)
			Geo.mesh(root, Geo.box(Vector3(rect.size.x, 0.02, rect.size.y)), Mat.layer(LOBBY_RUG), Vector3(c.x, 0.01, c.y))
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
	for r in _map["regions"]:
		if String(r["kind"]) == "cat_room":
			_cat_room_rugs(_bounds(r["rects"]))


## Lose Teppiche im Katzenraum (CAT_ROOM_RUGS): flache Auflagen wie die Läufer, jeder ein paar Millimeter höher
## als der vorige, falls sie sich überlappen.
func _cat_room_rugs(b: Rect2) -> void:
	for i in CAT_ROOM_RUGS.size():
		var r: Dictionary = CAT_ROOM_RUGS[i]
		var size: Vector2 = r["size"]
		var c := b.position + b.size * (r["at"] as Vector2)
		var tex := TexGen.rug(r["colors"], maxi(8, roundi(size.x / RUG_PIXEL)), maxi(8, roundi(size.y / RUG_PIXEL)))
		var plane := PlaneMesh.new()
		plane.size = size
		plane.subdivide_width = maxi(0, ceili(size.x / Geo.MAX_FACE) - 1)
		plane.subdivide_depth = maxi(0, ceili(size.y / Geo.MAX_FACE) - 1)
		var mi := Geo.mesh(root, plane, Mat.layer_tex(tex), Vector3(c.x, RUG_Y + i * 0.003, c.y))
		mi.rotation.y = deg_to_rad(r["yaw"])


## Doppelbett aus dem Plan (PLANFARBEN.md): Versteck wie das Bett (unters Bett kriechen), so groß wie seine
## Grundfläche, das Kopfende an der helleren Kante. Heraus (lokal +Z) geht es zu der Längsseite mit mehr Platz.
func _double_bed(rect: Rect2, head_side: String) -> HideSpot:
	var c := rect.get_center()
	var head := _dir(head_side) if head_side != "" else -_facing("", c)
	var spot := HideSpot.new().setup(HideSpot.Type.BED)
	spot.bed_size = Vector2(rect.size.x, rect.size.y) if absf(head.x) > 0.5 else Vector2(rect.size.y, rect.size.x)
	var out := Vector2(head.y, -head.x)   # lokal −X zeigt dann zum Kopfende
	if _free_run(c, -out) > _free_run(c, out):
		out = -out
		spot.head_x = 1.0
	spot.position = Vector3(c.x, 0, c.y)
	spot.rotation.y = atan2(out.x, out.y)
	_parent.add_child(spot)
	return spot


## Wie weit man von p aus in Richtung dir im selben Raum bleibt (Schritte von 0,25 m, höchstens 4 m).
func _free_run(p: Vector2, dir: Vector2) -> float:
	var id := _room_id_at(p)
	var d := 0.25
	while d < 4.0 and _room_id_at(p + dir * d) == id:
		d += 0.25
	return d


## Truhe in einem Hotelzimmer = dessen Süßigkeiten-Truhe (Spielkonzept 6.13): so groß wie im Plan, darin
## SWEETS_CHEST_COUNT Süßigkeiten als echte Gegenstände. Gäste geben Kindern daraus (Social.take_room_sweet).
func _sweets_chest(chest: Chest, rect: Rect2, front: Vector2, pos: Vector3) -> void:
	var across := absf(front.y) > 0.5
	chest.size = Vector3(rect.size.x if across else rect.size.y, SWEETS_CHEST_H, rect.size.y if across else rect.size.x)
	chest.wood_color = SWEETS_CHEST_COLOR
	chest.title = "Süßigkeiten-Truhe"
	chest.set_meta("sweets_room", _room_id_at(rect.get_center()))
	chest.add_to_group("sweet_chests")
	var basis := Basis(Vector3.UP, atan2(front.x, front.y))
	for i in SWEETS_CHEST_COUNT:   # zwei Reihen, liegen sichtbar darin
		var row := floorf(i / 3.0)
		_item(Item.Kind.SWEETS, pos + basis * Vector3((i % 3 - 1) * chest.size.x * 0.28, 0.08 + 0.03 * row, (row - 0.5) * chest.size.z * 0.4))


## Möbel als Kasten in der Grundfläche des Plans; Theke mit Platte, Waschmaschine mit Bullauge vorn, Waschbecken mit
## Spiegel an der Wand dahinter.
func _box_furniture(kind: String, rect: Rect2, height: float, front: Vector2) -> StaticBody3D:
	var mat := _wood
	match kind:
		"bench", "bar_counter":
			mat = _dark_wood
		"sink", "toilet", "shower":
			mat = _ceramic
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
		"sink":
			# Spiegel mit Spiegelbild (Mirror) an der Wand hinter dem Becken – Unterkante MIRROR_BOTTOM, Oberkante
			# MIRROR_TOP: Figuren von 1,45 bis 2,00 m sehen darin Scheitel und Bauch (Spielkonzept 3.9)
			var across := absf(front.y) > 0.5
			var width := minf(rect.size.x if across else rect.size.y, MIRROR_WIDTH)
			var back := Vector3(-front.x * (rect.size.x / 2.0 - MIRROR_GAP), 0, -front.y * (rect.size.y / 2.0 - MIRROR_GAP))
			var mid := (MIRROR_BOTTOM + MIRROR_TOP) / 2.0 - height / 2.0
			Mirror.make(body, Vector2(width, MIRROR_TOP - MIRROR_BOTTOM), back + Vector3(0, mid, 0),
				Vector3(front.x, 0, front.y), MIRROR_RANGE).add_to_group("sink_mirrors")
	if kind in ["bench", "toilet"]:
		# Sitzplätze (Seat): Bank je SPOT_WIDTH einer, Toilette einer – Blick zur Vorderseite
		var across := absf(front.y) > 0.5
		var width := rect.size.x if across else rect.size.y
		var depth := rect.size.y if across else rect.size.x
		var title: String = {"bench": "bank", "toilet": "klo"}[kind]
		Seat.attach(body, title, height, Vector3(0, -height / 2.0, 0), Vector3(front.x, 0, front.y),
			width if kind == "bench" else minf(width, Seat.SPOT_WIDTH), depth / 2.0 + SEAT_CLEAR)
	return body


# --- Bad und Bar aus Modellen (tools/build_fixtures.py) ----------------------------------------------------

## Ausdehnung des Rechtecks entlang dir (waagerecht oder senkrecht).
func _depth_of(rect: Rect2, dir: Vector2) -> float:
	return rect.size.x if absf(dir.x) > 0.5 else rect.size.y


## Rechteck in Weltkoordinaten zu einem Rechteck im Möbel (x quer, y = lokal z nach vorn) mit Ursprung origin.
func _local_rect(origin: Vector2, front: Vector2, local: Rect2) -> Rect2:
	var right := Vector2(front.y, -front.x)   # lokal +X
	var a := origin + right * local.position.x + front * local.position.y
	var b := origin + right * local.end.x + front * local.end.y
	return Rect2(a.min(b), (a - b).abs())


## Steht neben der Stelle c in Richtung dir höchstens reach entfernt eine Wand?
func _wall_beside(c: Vector2, dir: Vector2, reach: float) -> bool:
	var side := ("east" if dir.x > 0 else "west") if absf(dir.x) > 0.5 else ("south" if dir.y > 0 else "north")
	return not _on_wall(c, side, reach).is_empty()


## Stelle c so weit von den Wänden weggerückt, dass ringsum mindestens clear bis zur Wandfläche bleibt (Möbel, das
## größer ist als sein Platz im Plan).
func _clear_of_walls(c: Vector2, clear: float) -> Vector2:
	for side: String in ["north", "south", "west", "east"]:
		var face := _on_wall(c, side, clear)
		if not face.is_empty():
			c -= _dir(side) * (clear - ((face["pos"] as Vector2) - c).dot(_dir(side)))
	return c


## Körper an der Stelle origin (Boden), lokal +Z nach front, mit dem Modell darin (Flächen nach _fixture_materials).
func _fixture_body(path: String, origin: Vector2, front: Vector2, tiles: Material = null) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.collision_mask = 0
	body.position = Vector3(origin.x, 0, origin.y)
	body.rotation.y = atan2(front.x, front.y)
	root.add_child(body)
	var model: Node3D = (load(path) as PackedScene).instantiate()
	model.name = "model"
	body.add_child(model)
	_fixture_materials(model, path, tiles)
	return body


## Flächen der Bad- und Barmodelle nach ihrem Namen (tools/build_fixtures.py); Farbtexturen über Mat.model.
func _fixture_materials(model: Node3D, path: String, tiles: Material) -> void:
	for m: MeshInstance3D in model.find_children("*", "MeshInstance3D", true, false):
		for s in m.mesh.get_surface_count():
			var src := m.mesh.surface_get_material(s)
			var mat: Material
			match src.resource_name if src else "":
				"tiles":
					mat = tiles
				"ceramic":
					mat = _ceramic
				"steel":
					mat = Mat.metal()
				"chrome":
					mat = Mat.metal(TOILET_CHROME)
				"brass":
					mat = Mat.metal(GrandStair.BRASS)
				"glass":
					mat = Mat.glass()
				"cushion":
					mat = Mat.psx(BAR_CUSHION)
				_:
					mat = Mat.model(path, m, s)
			m.set_surface_override_material(s, mat)


## Waschplatz an der Wand (back = Wandmitte, Blick nach front): gefliester Waschtisch so breit wie width, darauf je
## WASH_PLACE ein Aufsatzbecken mit Wandarmatur, darüber je ein Spiegel mit Spiegelbild (Mirror). bath_room: Raum-ID
## des Bads (leer in den Toiletten) – dessen Spiegel gehört zu `sink_mirrors` (Charaktererstellung, Spielkonzept 3.9)
## und hat darüber eine Spiegelleuchte, die mit dem Zimmer schaltet.
func _washbasin(back: Vector2, front: Vector2, width: float, tiles: Material, bath_room: String) -> StaticBody3D:
	var body := _fixture_body(WASHBASIN_MODEL, back, front, tiles)
	var first := body.get_node("model") as Node3D
	var table := first.find_child("table") as Node3D
	table.position.y = WASH_TABLE_TOP
	table.scale.x = width / WASH_TABLE.x   # Fliesen in Weltkoordinaten – sie strecken sich nicht mit
	Geo.add_box_shape(body, Vector3(width, WASH_TABLE.y, WASH_TABLE.z), Vector3(0, WASH_TABLE_TOP - WASH_TABLE.y / 2.0, WASH_TABLE.z / 2.0))
	var count := maxi(1, floori(width / WASH_PLACE + 0.001))
	for i in count:
		var x := (i + 0.5) * width / count - width / 2.0
		var model := first
		if i > 0:
			model = (load(WASHBASIN_MODEL) as PackedScene).instantiate()
			model.find_child("table").free()   # ein Tisch für alle
			body.add_child(model)
			_fixture_materials(model, WASHBASIN_MODEL, tiles)
		model.find_child("basin").position = Vector3(x, WASH_TABLE_TOP, 0)
		model.find_child("mirror_frame").position = Vector3(x, MIRROR_FRAME_BOTTOM, 0)
		var mirror := Mirror.make(body, MIRROR_GLASS, Vector3(x, MIRROR_FRAME_BOTTOM + MIRROR_GLASS_MID, MIRROR_GAP),
			Vector3.BACK, MIRROR_RANGE)
		if not bath_room.is_empty():
			mirror.add_to_group("sink_mirrors")
			var lamp := Lamp.new().setup(Lamp.Style.MIRROR, bath_room, MIRROR_LAMP_ENERGY, MIRROR_LAMP_RANGE, false)
			lamp.length = MIRROR_LAMP_WIDTH
			lamp.position = Vector3(x, MIRROR_LAMP_Y, 0)
			body.add_child(lamp)
	return body


## Duschecke in der Mitte c ihrer Planfläche, Tür nach front. Das Modell hat seine Wand bei −X – steht die Wand im
## Plan rechts, wird es gespiegelt. Kollision: Sockel samt Wanne (höher, SHOWER_BLOCK) und das Glas (klares Glas,
## Ebene 7: man sieht hindurch, kommt aber nicht hinein).
func _shower(c: Vector2, front: Vector2) -> StaticBody3D:
	var body := _fixture_body(SHOWER_MODEL, c, front, _bath_tiles)
	var side := -1.0 if _wall_beside(c, Vector2(front.y, -front.x), SHOWER_SIZE / 2.0 + 0.1) else 1.0
	(body.get_node("model") as Node3D).scale.x = side
	Geo.add_box_shape(body, Vector3(SHOWER_SIZE, SHOWER_BLOCK, SHOWER_SIZE), Vector3(0, SHOWER_BLOCK / 2.0, 0))
	var glass := StaticBody3D.new()
	glass.collision_layer = HotelWindow.LAYER_GLASS
	glass.collision_mask = 0
	body.add_child(glass)
	var g := SHOWER_SIZE / 2.0 - SHOWER_GLASS_INSET
	Geo.add_box_shape(glass, Vector3(0.02, SHOWER_GLASS_H, SHOWER_SIZE), Vector3(g * side, SHOWER_GLASS_H / 2.0, 0))
	Geo.add_box_shape(glass, Vector3(SHOWER_SIZE, SHOWER_GLASS_H, 0.02), Vector3(0, SHOWER_GLASS_H / 2.0, g))
	return body


## Wand-WC an der Wand (back = Wandmitte unter der Schüssel), Sitz nach front; der Papierhalter kommt auf die Seite
## ohne Wand. Sitzplatz wie bisher (Seat „klo“).
func _toilet(back: Vector2, front: Vector2, c: Vector2) -> StaticBody3D:
	var body := _fixture_body(TOILET_MODEL, back, front)
	if _wall_beside(c, Vector2(front.y, -front.x), TOILET_HOLDER_REACH):
		(body.get_node("model") as Node3D).scale.x = -1.0
	Geo.add_box_shape(body, TOILET_BOWL, Vector3(0, TOILET_BOWL.y / 2.0, TOILET_BOWL.z / 2.0))
	Seat.attach(body, "klo", TOILET_BOWL.y, Vector3(0, 0, TOILET_SIT), Vector3.BACK, TOILET_BOWL.x,
		TOILET_BOWL.z - TOILET_SIT + SEAT_CLEAR)
	return body


## Wand hinter der Bar: Mitte der Rückkante des Barregals aus dem Plan und die Richtung in den Raum – Regal und Theke
## richten sich danach. Ohne Regal die Rückkante der Theke selbst.
func _bar_wall(counter: Rect2, front: Vector2) -> Array:
	for f in _map["furniture"]:
		var r := _rect(f["rect"])
		if f["kind"] == "shelf" and _named.has("bar") and (_named["bar"] as Rect2).has_point(r.get_center()):
			var dir := _facing(String(f.get("facing", "")), r.get_center())
			return [r.get_center() - dir * _depth_of(r, dir) / 2.0, dir]
	return [counter.get_center() - front * _depth_of(counter, front) / 2.0, front]


## Barregal mit der Rückseite an der Wand (back = Wandmitte). Meta „back_bar“: Flaschen auf die Glasböden.
func _back_bar(back: Vector2, front: Vector2) -> StaticBody3D:
	var body := _fixture_body(BACK_BAR_MODEL, back + front * BACK_BAR_DEPTH / 2.0, front)
	Geo.add_box_shape(body, BACK_BAR_BODY, Vector3(0, BACK_BAR_BODY.y / 2.0, BACK_BAR_BODY.z / 2.0 - BACK_BAR_DEPTH / 2.0))
	body.set_meta("back_bar", true)
	return body


## Theke (L) mit Ursprung origin, Gästeseite nach front; der Rückschenkel reicht bis an das Barregal.
func _bar_counter(origin: Vector2, front: Vector2) -> StaticBody3D:
	var body := _fixture_body(BAR_COUNTER_MODEL, origin, front)
	for r: Rect2 in [BAR_ARM, BAR_RETURN_BODY]:
		var mid := r.get_center()
		Geo.add_box_shape(body, Vector3(r.size.x, BAR_TOP, r.size.y), Vector3(mid.x, BAR_TOP / 2.0, mid.y))
	return body


## Ausstattung (Ebene „Ausstattung“). Wandsachen hängen an der Wandseite aus dem Plan; Telefone, Zettel, Tagebuch
## und Vorräte stehen auf dem Möbel darunter. Zettel-Nummern und UV-Texte kommen aus CONTENT.
func _fittings() -> void:
	var paintings := {}   # Gruppe (Painting.GROUPS) → schon gehängt
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
				if id in ALWAYS_LIT:
					push_warning("Gebäudeplan: Lichtschalter (%s) bei Pixel %s – dort brennt das Licht immer, der Schalter entfällt (aus dem Plan nehmen)" % [_switch_label(id), _plan_pixel(p)])
					continue
				var sw := _switch(id, _switch_label(id), at.at(SWITCH_Y), at.yaw())
				if _behind_door(sw.position):
					var why := "liegt hinter der offenen Tür – auf die Griffseite setzen oder den Türanschlag ans andere Ende"
					push_warning("Gebäudeplan: Lichtschalter (%s) bei Pixel %s %s" % [_switch_label(id), _plan_pixel(p), why])
				if rooms.has(id) and rooms[id]["kind"] == "vacant":
					sw.set_on.call_deferred(false, true)   # unbewohnt: dunkel
			"painting":
				var at := _wall_spot(o, WALL_GAP)
				var area := _kind_at(at.inside)
				var y: float = {"lobby": 2.2, "office": 2.0, "bar": 1.9}.get(area, 1.75)   # im Flur über den Kommoden
				var group := Painting.group_for(area)
				var work := Painting.pick(group, paintings.get(group, 0))
				paintings[group] = paintings.get(group, 0) + 1
				if work == "":
					continue
				var pic := Painting.new().setup(work, area)
				pic.position = at.at(y)
				pic.rotation.y = at.yaw()
				_parent.add_child(pic)
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
			"pool_shower":   # Duschplatz am Pool: Drücker, Ablage, Duschkopf (Spielkonzept 7.13, ZIM-144)
				var at := _wall_spot(o, POOL_SHOWER_GAP)
				var shower := PoolShower.new().setup(self)
				shower.position = at.at(0.0)
				shower.rotation.y = at.yaw()
				root.add_child(shower)
			"floor_drain":   # Bodenablauf in der Dusche am Pool (Spielkonzept 7.13), im Becken auf dessen Boden
				var floor_y := -POOL_DEPTH if _place_at(p).get("kind", "") == "pool_water" else 0.0
				root.add_child(PoolShower.drain(Vector3(p.x, floor_y, p.y)))
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
				_supply(ResourceSpot.new().setup(Item.Kind.CANDLE, "Kerze aus dem Vorrat", 3, 150.0).refill_mornings(), Vector3(p.x, top, p.y))   # morgens (5.12)
			"bulb_supply":
				_supply(ResourceSpot.new().setup(Item.Kind.BULB, "Ersatzbirne aus dem Lager", 2, 300.0), Vector3(p.x, BULB_SUPPLY_Y, p.y))
			"leaf_pile":
				_supply(ResourceSpot.new().setup(Item.Kind.LEAVES, "Herbstlaub", 4, 60.0), Vector3(p.x, top, p.y))
			"dartboard":   # Darts (Spielkonzept 6.10): Scheibe an der Wand, Linie und Stehtisch davor, Pfeile darauf
				_dartboard(o)
			# Nur merken (planned, ZIM-158) – gebaut wird später an ihrer Stelle, ohne Planeintrag am alten Platz
			"mask_board", "fuse_box", "notice_board", "wall_clock", "leviathan_print", "photo_wall":
				_plan_wall(o)
			"apple_tub", "crow_nest":
				_plan(kind, p, Vector2(0, 1))
			"deco_box" when _attic:
				# Kiste mit wertvollerer alter Deko auf dem Dachboden (Spielkonzept 4.21, 5.7): wenige starke Stücke, kein
				# Nachschub – wie die alte Deko im Heizkeller
				var box := ResourceSpot.new().setup(Item.Kind.BROOM, "Alte Deko vom Dachboden", ATTIC_BOX_SIZE, 0.0) \
					.with_pool([Item.Kind.SKULL, Item.Kind.BROOM, Item.Kind.LIGHT_STRING, Item.Kind.SKULL])
				box.rotation.y = _upright_yaw(p)
				_supply(box, Vector3(p.x, top, p.y))
			"deco_box":
				# Karton mit alter Halloween-Deko: Lichterketten (Spielkonzept 5.6)
				var box := ResourceSpot.new().setup(Item.Kind.LIGHT_STRING, "Deko aus der Kiste", DECO_BOX_SIZE, 0.0) \
					.with_pool([Item.Kind.LIGHT_STRING, Item.Kind.BAT_GARLAND, Item.Kind.SPIDER])
				box.rotation.y = _upright_yaw(p)
				_supply(box, Vector3(p.x, top, p.y))
			_:
				push_warning("Gebäudeplan: unbekannte Ausstattung „%s“ bei %s" % [kind, p])


## Dartscheibe an der Wand aus dem Plan; die Pfeile liegen auf dem Stehtisch, wenn sie nicht im Plan stehen.
func _dartboard(o: Dictionary) -> void:
	if dart_board != null:
		push_warning("Gebäudeplan: zweite Dartscheibe bei %s – es gibt nur eine" % o["pos"])
		return
	var at := _wall_spot(o, 0.0)
	dart_board = DartBoard.new()
	dart_board.position = at.at(0.0)
	dart_board.rotation.y = at.yaw()
	root.add_child(dart_board)
	var planned := (_map["items"] as Array).any(func(i: Dictionary) -> bool: return i["kind"] == "DARTS")
	if not planned:
		var darts := Item.create(Item.Kind.DARTS)   # Gegenstände liegen in der Hauptszene (_item)
		darts.position = root.global_transform * (dart_board.transform * (DartBoard.TABLE_AT + Vector3.UP * (DartBoard.TABLE_TOP + 0.005)))
		darts.rotation.y = dart_board.rotation.y + 0.4
		world.add_child(darts)


## Bis die Dartscheibe im Plan steht (Ausstattung „Dartscheibe“): an der Südwand der Bar.
func _dart_fallback() -> void:
	if dart_board == null and _named.has("bar"):
		_dartboard(DART_FALLBACK)


## Spieleschrank an seinem Platz (Mitte am Boden, Blickrichtung) mit Inhalt: die Spiele aus Item.BAR_GAMES und ein
## Würfelbecher (GameCabinet.CONTENTS; Gegenstände liegen in der Hauptszene wie bei _item), die Türen sind zu.
func _game_cabinet(at: Vector2, yaw: float) -> GameCabinet:
	game_cabinet = GameCabinet.new()
	game_cabinet.position = Vector3(at.x, 0, at.y)
	game_cabinet.rotation.y = yaw
	root.add_child(game_cabinet)
	for c in GameCabinet.CONTENTS:
		var item := Item.create(Item.Kind.DICE_CUP) if c[0] == "becher" else Item.create(Item.Kind.BAR_GAME, String(c[0]))
		item.position = game_cabinet.spot(int(c[1]), float(c[2]))
		item.rotation.y = game_cabinet.rotation.y
		world.add_child(item)
	return game_cabinet


## Möbel ohne Vorderseite im Plan, die an einer Wand stehen (Spieleschrank, Videoautomat): Rücken an die nächste Wand,
## Vorderseite davon weg. Der Rücken liegt an einer langen Seite (in einer Ecke sonst die falsche Wand – der Schrank
## stünde quer und halb in der Wand). Steht keine Wand nah genug, bleibt die Vorderseite aus _facing.
func _back_to_wall(rect: Rect2, front: Vector2) -> Vector2:
	var best := INF
	for side: String in ["north", "south", "west", "east"]:
		var d := _dir(side)
		if _depth_of(rect, d) > _depth_of(rect, Vector2(d.y, d.x)) + 0.01:
			continue   # kurze Seite
		var edge := rect.get_center() + d * _depth_of(rect, d) / 2.0
		var face := _on_wall(edge, side, 0.3)
		if not face.is_empty() and edge.distance_to(face["pos"]) < best:
			best = edge.distance_to(face["pos"])
			front = -d
	return front


## Bowlingbahn (Spielkonzept 6.10, 28.10.): Kegel und Kugelständer auf die Fläche „Bowlingbahn“ im Plan (alle Stücke
## zusammen), die Foullinie trennt den Anlauf ab – ohne sie gilt das südliche Viertel als Anlauf.
func _bowling_lane() -> void:
	var lane := Rect2()
	var foul := INF
	for r in _map["regions"]:
		for rc in r["rects"]:
			if r["kind"] == "bowling_lane":
				lane = _rect(rc) if not lane.has_area() else lane.merge(_rect(rc))
			elif r["kind"] == "foul_line":
				foul = _rect(rc).get_center().y
	if not lane.has_area():
		return
	if foul == INF:
		foul = lane.end.y - lane.size.y / 4.0
	bowling = BowlingLane.new().setup(lane, foul)
	root.add_child(bowling)


## Spieleschrank (CABINET_FALLBACK) und Jackpot-Automat (SLOT_FALLBACK) in der Bar, solange sie nicht im Plan stehen.
func _bar_games_fallback() -> void:
	if not _named.has("bar"):
		return
	for o in [CABINET_FALLBACK, SLOT_FALLBACK]:
		var missing := slot_machine == null if o == SLOT_FALLBACK else game_cabinet == null
		if missing and not (_named["bar"] as Rect2).has_point(_v2(o["pos"])):
			push_warning("Gebäudeplan: %s-Platz %s liegt nicht mehr in der Bar – bitte in den Plan zeichnen" % [o["kind"], o["pos"]])
	if game_cabinet == null:
		var at := _wall_spot(CABINET_FALLBACK, GameCabinet.SIZE.z / 2.0 + 0.01)
		var spot := at.at(0.0)
		_game_cabinet(Vector2(spot.x, spot.z), at.yaw())
	if slot_machine != null:
		return
	var slot_at := _wall_spot(SLOT_FALLBACK, SlotMachine.SIZE.z / 2.0 + 0.01)
	slot_machine = SlotMachine.new()
	slot_machine.position = slot_at.at(0.0)
	slot_machine.rotation.y = slot_at.yaw()
	root.add_child(slot_machine)


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


## Den ersten Tisch je Zimmer merken (room_tables). Nur Möbel ab first (dieses Stockwerk).
func _note_room_tables(first: int) -> void:
	for f: Dictionary in _furnishings.slice(first):
		if not f["kind"] in ["table", "room_table"]:
			continue
		var c := (f["rect"] as Rect2).get_center()
		var id := _room_id_at(c)
		if rooms.has(id) and not room_tables.has(id):
			room_tables[id] = _global(Vector3(c.x, float(f["top"]), c.y))
			var r := f["rect"] as Rect2
			var long := Vector3.RIGHT * r.size.x / 2.0 if r.size.x >= r.size.y else Vector3.BACK * r.size.y / 2.0
			room_table_axes[id] = _parent.global_basis * long


## Gartentüren (garden_doors, nur Erdgeschoss) und Futtertisch der Krähen (4.25): der Tisch draußen, der einer Gartentür
## von Zimmer 13 am nächsten steht (höchstens FEED_TABLE_RANGE). Nur Möbel ab first (dieses Stockwerk); ohne Tisch
## bleibt feed_table leer.
func _note_gardens(first: int) -> void:
	if _level != 0:
		return
	var doors: Array[Vector2] = []
	for info: Dictionary in _map["rooms"]:
		for o: Dictionary in info.get("garden_doors", []):
			var n: Array = o["normal"]
			(garden_doors.get_or_add(String(info["no"]), []) as Array).append(
				{"pos": _global(_v3(o["pos"])), "out": Vector3(float(n[0]), 0, float(n[1]))})
			if String(info["no"]) == PLAYER_ROOM:
				doors.append(_v2(o["pos"]))
	var best := FEED_TABLE_RANGE
	for f: Dictionary in _furnishings.slice(first):
		if not f["kind"] in ["table", "room_table", "coffee_table", "dining_table", "garden_table"]:
			continue
		var r: Rect2 = f["rect"]
		if _kind_at(r.get_center()) != "outside":
			continue
		for d in doors:
			if d.distance_to(r.get_center()) < best:
				best = d.distance_to(r.get_center())
				feed_table = {"pos": _global(Vector3(r.get_center().x, float(f["top"]), r.get_center().y)), "size": r.size}


## Fester Fund in einer Schublade (CONTENT „drawer“, Spielkonzept 5.12): in die oberste Schublade der ersten Kommode
## im Raum. Steht dort (noch) keine, liegt er auf einem Tisch des Raums. Nur Möbel ab first (dieses Stockwerk).
func _drawer_content(first: int) -> void:
	for id: String in CONTENT:
		if not (CONTENT[id] as Dictionary).has("drawer"):
			continue
		var kind := Item.Kind.get(String(CONTENT[id]["drawer"])) as Item.Kind
		var table := {}
		var placed := false
		for f: Dictionary in _furnishings.slice(first):
			if _room_id_at((f["rect"] as Rect2).get_center()) != id:
				continue
			if f["kind"] == "dresser":
				(f["node"] as Dresser).fixed[0] = kind
				placed = true
				break
			if f["kind"] in ["table", "room_table"] and table.is_empty():
				table = f
		if placed or table.is_empty():
			continue
		var c := (table["rect"] as Rect2).get_center()
		_item(kind, Vector3(c.x + 0.2, float(table["top"]) + 0.02, c.y + 0.1))


## Lichter (Ebene „Lichter“): Wandleuchten an der Wand (Höhe und Helligkeit je Fläche, _lamp_style),
## Deckenleuchten an der Decke darüber, Kerzen und Schreibtischlampen auf dem Möbel darunter, Laternen im Garten.
## Defekt laut Plan.
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
			"desk_lamp":
				_desk_lamp(p, _light_room_at(p), broken)
			"halogen":
				_halogen(p, String(o.get("axis", "x")), float(o.get("length", 0.8)), _light_room_at(p), broken)
			"candle":
				_candle(Vector3(p.x, _top_at(p), p.y))
			"lantern":
				_lantern(Vector3(p.x, 0, p.y), broken, 1.0 if absf(p.x) < 15.0 else 0.8)   # in den Innenhöfen schwächer
			"disco_ball", "pool_lamp":   # nur merken (ZIM-158): baut _common_rooms bzw. _pool
				_plan(String(o["kind"]), p, Vector2(0, 1))
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
		"cat_room", "library", "office", "secretariat":
			return {"y": 2.2, "energy": ROOM_LAMP_ENERGY, "range": 7.0}
		"bath":
			return {"y": 2.0, "energy": ROOM_LAMP_ENERGY, "range": 4.5}
	return {"y": 2.1, "energy": WALL_LAMP_ENERGY, "range": 6.0}


## Wand gegenüber der Tür des Treppenhauses, in dem p liegt – dort liegen die Wendepodeste („“ = keins).
func _landing_side(p: Vector2) -> String:
	for s in _map["stairs"]:
		var rc: Array = s["rect"]
		if s["kind"] == "stairwell" and s.has("door") and _rect(rc).grow(0.3).has_point(p):
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


## Raum-ID für Lampen und Schalter: wie _room_id_at, nur teilen sich Umkleiden und Duschen einen Schalter. Das Bad
## eines Zimmers schaltet für sich (ZIM-149); wem es gehört, sagt home_of.
func _light_room_at(p: Vector2) -> String:
	var id := _room_id_at(p)
	if id in CHANGING_ROOMS:
		return "umkleiden"
	if id == "treppenhaus_ost":
		return "treppenhaus"
	return id


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


## Platz aus dem Plan merken (planned, ZIM-158). Von den Arten in PLANNED_ONCE gilt nur der erste.
func _plan(kind: String, pos: Vector2, out: Vector2, rect := Rect2()) -> void:
	var list: Array = planned.get_or_add(kind, [])
	if kind in PLANNED_ONCE and not list.is_empty():
		push_warning("Gebäudeplan: %s bei Pixel %s doppelt – es gibt nur einen, der erste gilt" % [kind, _plan_pixel(pos)])
		return
	list.append({"level": _level, "pos": pos, "out": out, "rect": rect, "at": _global(Vector3(pos.x, 0, pos.y))})


## Wandsache aus dem Plan nur merken (_plan): Punkt auf der Wandfläche, Blick in den Raum.
func _plan_wall(o: Dictionary) -> void:
	var at := _wall_spot(o, 0.0)
	_plan(String(o["kind"]), at.pos, at.out)


## Platz für kind aus dem Plan (der erste), y über dem Boden und gap vor der Wand, +Z in den Raum bzw. zur
## Vorderseite. Ohne Planeintrag fallback (global). Erst nach build() vollständig.
func planned_at(kind: String, fallback: Transform3D, y := 0.0, gap := 0.0) -> Transform3D:
	var list: Array = planned.get(kind, [])
	if list.is_empty():
		return fallback
	var out: Vector2 = list[0]["out"]
	var at: Vector3 = (list[0]["at"] as Vector3) + Vector3(out.x, 0, out.y) * gap + Vector3.UP * y
	return Transform3D(Basis(Vector3.UP, atan2(out.x, out.y)), at)


## Plätze der Art kind aus dem Plan auf dem geladenen Stockwerk, wahlweise nur in area.
func _planned_here(kind: String, area := Rect2()) -> Array:
	return (planned.get(kind, []) as Array).filter(func(p: Dictionary) -> bool:
		return int(p["level"]) == _level and (not area.has_area() or area.has_point(p["pos"])))


## Maskensammlung (Spielkonzept 5.19): das Maskenboard (MaskBoard, ZIM-128) mit acht Stiften, die Mitte am Punkt
## „Maskenboard“ im Plan (ZIM-158). Ohne ihn an der längsten freien Wand von Zimmer 13 – frei heißt ohne Tür und
## Fenster, ohne Möbel davor und ohne Wandsache (Schalter, Telefon, Lampe).
func _mask_hooks() -> void:
	var board := _planned_here("mask_board")
	if not board.is_empty():
		var out: Vector2 = board[0]["out"]
		var face: Vector2 = board[0]["pos"]
		_mask_board(face, out)
		return
	var info := {}
	for r in _map["rooms"]:
		if String(r["no"]) == PLAYER_ROOM:
			info = r
	var best := {}
	for rc in info.get("rects", []):
		for side in ["north", "south", "west", "east"]:
			var span := _free_wall(_rect(rc), side, info)
			if not span.is_empty() and (best.is_empty() or float(span["length"]) > float(best["length"])):
				best = span
	if best.is_empty() or float(best["length"]) < MASK_WALL_MIN:
		push_warning("Gebäudeplan: Zimmer %s hat keine %.1f m freie Wand für das Maskenboard" % [PLAYER_ROOM, MASK_WALL_MIN])
		return
	var dir := _dir(best["side"])
	var middle := (float(best["from"]) + float(best["to"])) / 2.0
	var line := float(best["line"])
	var p := Vector2(middle, line) if best["horizontal"] else Vector2(line, middle)
	_mask_board(_on_wall(p - dir * 0.2, best["side"], 0.6).get("pos", p), -dir)


## Maskenboard mittig an der Wandstelle face, Vorderseite nach out
func _mask_board(face: Vector2, out: Vector2) -> void:
	var b := MaskBoard.new()
	b.position = Vector3(face.x, MaskBoard.BOTTOM, face.y)
	b.rotation.y = atan2(out.x, out.y)
	root.add_child(b)


## Längstes freies Stück an der Seite side eines Zimmerrechtecks (_mask_hooks): {side, horizontal, line, from, to,
## length} oder {}. Blockiert: Öffnungen der Wände auf dieser Linie, Türen und Fenster des Zimmers, Möbel, Wandsachen
## und Lichter bis 0,6 m davor.
func _free_wall(rect: Rect2, side: String, info: Dictionary) -> Dictionary:
	var dir := _dir(side)
	var horizontal := absf(dir.y) > 0.5   # Wand verläuft entlang x
	var toward := dir.y if horizontal else dir.x
	var line := (rect.end.y if toward > 0.0 else rect.position.y) if horizontal else (rect.end.x if toward > 0.0 else rect.position.x)
	var lo := (rect.position.x if horizontal else rect.position.y) + MASK_WALL_MARGIN
	var hi := (rect.end.x if horizontal else rect.end.y) - MASK_WALL_MARGIN
	var along := func(p: Vector2) -> float: return p.x if horizontal else p.y
	var inward := func(p: Vector2) -> float: return ((p.y if horizontal else p.x) - line) * -toward
	var blocked: Array[Vector2] = []
	for w in _map["walls"]:
		var a := _v2(w["a"])
		var b := _v2(w["b"])
		if (absf(a.y - b.y) < 0.01) != horizontal or absf(float(inward.call(a))) > 0.4:
			continue
		var step := signf(float(along.call(b)) - float(along.call(a)))
		for o in w.get("openings", []):
			var start := float(along.call(a)) + step * float(o["at"])
			var end := start + step * float(o["width"])
			blocked.append(Vector2(minf(start, end), maxf(start, end)))
	var openings: Array = [info["door"]] if info.has("door") else []
	for key in ["windows", "garden_doors", "bath_doors"]:
		openings.append_array(info.get(key, []))
	for o in openings:
		var p := _v2(o["pos"])
		if absf(float(inward.call(p))) < 0.4:
			var c := float(along.call(p))
			blocked.append(Vector2(c - float(o["width"]) / 2.0, c + float(o["width"]) / 2.0))
	for f in _map["furniture"]:
		var r := _rect(f["rect"])
		var d0 := float(inward.call(r.position))
		var d1 := float(inward.call(r.end))
		if minf(d0, d1) < 0.6 and maxf(d0, d1) > 0.0:
			var x0 := float(along.call(r.position))
			var x1 := float(along.call(r.end))
			blocked.append(Vector2(minf(x0, x1), maxf(x0, x1)))
	for o in _map["fittings"] + _map["lights"]:
		if o.has("pos"):
			var d := float(inward.call(_v2(o["pos"])))
			if d > -0.15 and d < 0.6:
				var c := float(along.call(_v2(o["pos"])))
				blocked.append(Vector2(c - 0.2, c + 0.2))
	blocked.sort_custom(func(u: Vector2, v: Vector2) -> bool: return u.x < v.x)
	blocked.append(Vector2(hi + MASK_WALL_MARGIN, INF))
	var best := {}
	var from := lo
	for bl in blocked:
		var to := minf(bl.x - MASK_WALL_MARGIN, hi)
		if to - from > float(best.get("length", 0.0)):
			best = {"side": side, "horizontal": horizontal, "line": line, "from": from, "to": to, "length": to - from}
		from = maxf(from, bl.y + MASK_WALL_MARGIN)
	return best


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


## Fester Zufall je Möbel (leichte Drehung, Versatz – ZIM-51): Startwert aus Stockwerk und Lage im Plan, also bei jedem
## Start und nach dem Laden gleich, ohne Spielstand. Wird das Möbel im Plan verschoben, fällt es neu.
func _jitter(rect: Rect2) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([_level, roundi(rect.position.x * 100.0), roundi(rect.position.y * 100.0)])
	return rng


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
## Schilder, Aushangbrett (2.5). Die Einrichtung steht im Plan.
func _lobby_hall() -> void:
	lobby_center = Vector3(_lobby.get_center().x, 0, _lobby.get_center().y)
	lobby_rect = _lobby
	var west := _lobby.position.x
	var east := _lobby.end.x
	if _planned_here("rug", _lobby).is_empty():   # ohne Teppich im Plan der feste vor der Rezeption
		Geo.mesh(root, Geo.box(Vector3(LOBBY_RUG_SIZE.x, 0.02, LOBBY_RUG_SIZE.y)), Mat.layer(LOBBY_RUG),
			Vector3(LOBBY_RUG_AT.x, 0.01, LOBBY_RUG_AT.y))
	var front: Array = _map["reception"][0]
	for rc in _map["reception"]:
		if float(rc[2]) - float(rc[0]) > float(front[2]) - float(front[0]):
			front = rc
	var fz := (float(front[1]) + float(front[3])) / 2.0
	cat_perches.append({"floor": Vector3(2.9, 0, fz - 0.8), "top": Vector3(2.3, RECEPTION_H + 0.02, fz - 0.8), "yaw": PI / 2.0})
	# Hotelregister (2.3): auf der Front der Rezeption etwas neben der Mitte, zu den Gästen gedreht
	var hull := _rect(front)
	for rc in _map["reception"]:
		hull = hull.merge(_rect(rc))
	var fc := _rect(front).get_center()
	var guest_side := (fc - hull.get_center()).normalized()
	var book := fc + Vector2(guest_side.y, -guest_side.x) * REGISTER_SHIFT
	register_spot = Transform3D(Basis(Vector3.UP, atan2(guest_side.x, guest_side.y)),
		_global(Vector3(book.x, _top_at(book), book.y)))
	# Tischklingel (ZIM-146): auf der anderen Seite der Mitte, etwas zu den Gästen
	var bell := fc - Vector2(guest_side.y, -guest_side.x) * BELL_SHIFT + guest_side * BELL_OUT
	desk_bell = DeskBell.new()
	desk_bell.position = Vector3(bell.x, _top_at(bell), bell.y)
	desk_bell.rotation.y = atan2(guest_side.x, guest_side.y)
	_parent.add_child(desk_bell)
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
	notice_board = NoticeBoard.new()   # +Z in die Lobby
	notice_board.transform = planned_at("notice_board",
		Transform3D(Basis(Vector3.UP, PI / 2.0), Vector3(west + WALL_GAP, NOTICE_BOARD_Y, NOTICE_BOARD_Z)), NOTICE_BOARD_Y, WALL_GAP)
	_parent.add_child(notice_board)


## Wanduhr (WallClock) an ihrem Platz im Plan, sonst über dem Haupteingang: Zifferblatt in den Raum, ohne Kollision.
## Die Mitte hängt auf halber Höhe zwischen CLOCK_ABOVE_DOOR über Türhöhe des Haupteingangs und der Decke.
func _clock() -> void:
	var spot: Array = _planned_here("wall_clock")
	if not spot.is_empty():
		var clock := WallClock.create(CLOCK_DIAMETER)
		if clock == null:
			return
		var p: Vector2 = spot[0]["pos"]
		var out: Vector2 = spot[0]["out"]
		var ceiling := H
		for rc in _map["open_above"]:   # unter einem Luftraum hängt sie in der Halle über zwei Stockwerke
			if _rect(rc).has_point(p + out * 0.5):
				ceiling = UP_Y + H
		var back := p + out * CLOCK_GAP
		clock.position = Vector3(back.x, (ENTRANCE_H + CLOCK_ABOVE_DOOR + ceiling) / 2.0, back.y)
		clock.rotation.y = atan2(out.x, out.y)
		root.add_child(clock)
		return
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
			clock.position = Vector3(back.x, (ENTRANCE_H + CLOCK_ABOVE_DOOR + ceiling) / 2.0, back.y)
			clock.rotation.y = atan2(into.x, into.y)   # +Z der Uhr zeigt in die Lobby
			root.add_child(clock)
			return


func _void() -> Rect2:
	var rc: Array = _map["open_above"][0]
	return _rect(rc)


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
	# Holzleiste über der Fuge zwischen Lobbywand und Obergeschosswand (dazwischen blitzte ein Spalt)
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
	GrandStair.build(_parent, _rect(rc), String(stair.get("up", "north")), UP_Y)


## Ränder der Lufträume dieses Stockwerks (Lobby, Partyraum): Geländer mit Blende davor, wo Boden angrenzt – außer,
## wo eine Treppe von unten ankommt. Wo eine Wand angrenzt, nichts: Ihre Tapete läuft ohne Fuge von unten durch (_wall_side_kind).
func _void_edges() -> void:
	var stairs: Array[Rect2] = []
	for st in (_floors[0]["map"] as Dictionary)["stairs"]:
		if st["kind"] == "stair":
			var rc: Array = st["rect"]
			stairs.append(_rect(rc).grow(0.05))
	for rc in _map["voids"]:
		var v := _rect(rc)
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
					GrandStair.fascia(root, Vector3(p0.x, 0, p0.y), Vector3(p1.x, 0, p1.y), Vector3(-out.x, 0, -out.y), UP_Y - H,
						not by_a, not by_b)
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
			var r := _rect(rc)
			if r.size.x >= r.size.y:
				_railing(Vector3(r.position.x, 0, r.get_center().y), Vector3(r.end.x, 0, r.get_center().y))
			else:
				_railing(Vector3(r.get_center().x, 0, r.position.y), Vector3(r.get_center().x, 0, r.end.y))


## Säule bis unter die Galerie (Terrazzo): Plinthe und Deckplatte als Quader, dazwischen ein Drehkörper aus
## PILLAR_FOOT, dem Schaft und PILLAR_HEAD. Kollision: die Quader und ein Zylinder in Schaftstärke.
func _pillar(rect: Rect2) -> StaticBody3D:
	var c := rect.get_center()
	var body := StaticBody3D.new()
	body.collision_mask = 0
	body.position = Vector3(c.x, 0, c.y)
	root.add_child(body)
	var step_y := H - PILLAR_ABACUS.y - PILLAR_ABACUS_STEP.y   # Unterkante der Deckplattenstufe
	var profile: Array = PILLAR_FOOT.duplicate()
	var foot_y: float = PILLAR_FOOT[-1].y
	var head_y: float = step_y + PILLAR_HEAD[0].y
	for k in [1, 2]:   # Schaft in Stücken ≤ Geo.MAX_FACE
		profile.append(Vector2(PILLAR_SHAFT_RADIUS, lerpf(foot_y, head_y, k / 3.0)))
	for p: Vector2 in PILLAR_HEAD:
		profile.append(p + Vector2(0, step_y))
	Geo.mesh(body, Geo.lathe(profile, PILLAR_SIDES), _pillar_porous, Vector3.ZERO)
	for part: Array in [[PILLAR_PLINTH, PILLAR_PLINTH.y / 2.0], [PILLAR_ABACUS_STEP, step_y + PILLAR_ABACUS_STEP.y / 2.0],
			[PILLAR_ABACUS, H - PILLAR_ABACUS.y / 2.0]]:
		Geo.mesh(body, Geo.box(part[0]), _pillar_porous, Vector3(0, part[1], 0))
		Geo.add_box_shape(body, part[0], Vector3(0, part[1], 0))
	var shaft_h := step_y - PILLAR_PLINTH.y
	var cs := CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	shape.radius = PILLAR_SHAFT_RADIUS
	shape.height = shaft_h
	cs.shape = shape
	cs.position = Vector3(0, PILLAR_PLINTH.y + shaft_h / 2.0, 0)
	body.add_child(cs)
	return body


## Couchtisch der Lobby: vier Beine und eine Zarge darunter (Kantholz COFFEE_TABLE_WOOD), darauf die Steinplatte
## mit abgerundeten Ecken, die COFFEE_TABLE_SLAB über den Unterbau steht. Oberkante wie im Plan (BOX_HEIGHTS).
func _coffee_table(side: float) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.collision_mask = 0
	var top: float = BOX_HEIGHTS["coffee_table"]
	var under := top - COFFEE_TABLE_SLAB   # Unterkante der Platte
	var w := COFFEE_TABLE_WOOD
	var half := side / 2.0 - COFFEE_TABLE_SLAB - w / 2.0   # Mitte der Beine und der Zarge
	for sx: float in [-1.0, 1.0]:
		for sz: float in [-1.0, 1.0]:
			Geo.mesh(body, Geo.box(Vector3(w, under, w)), _dark_wood, Vector3(sx * half, under / 2.0, sz * half))
	var rail := 2.0 * half - w   # zwischen den Beinen, außen bündig
	for s: float in [-1.0, 1.0]:
		Geo.mesh(body, Geo.box(Vector3(rail, w, w)), _dark_wood, Vector3(0, under - w / 2.0, s * half))
		Geo.mesh(body, Geo.box(Vector3(w, w, rail)), _dark_wood, Vector3(s * half, under - w / 2.0, 0))
	Geo.mesh(body, _rounded_slab(side, COFFEE_TABLE_SLAB, COFFEE_TABLE_SLAB), _pillar_stone, Vector3(0, under, 0))
	Geo.add_box_shape(body, Vector3(side, top, side), Vector3(0, top / 2.0, 0))
	return body


## Quadratische Platte (Kantenlänge side, Stärke thick, Eckradius r) von y = 0 bis thick, Ursprung mittig unten.
## Die Seiten sind an den Ecken weich schattiert.
func _rounded_slab(side: float, thick: float, r: float) -> ArrayMesh:
	var sh := GrandStair.Shape.new()
	var ring: Array[Vector3] = []   # Umriss mit waagrechter Normale je Punkt
	var normals: Array[Vector3] = []
	var c := side / 2.0 - r
	for corner in 4:
		var center := Vector3(c if corner in [0, 3] else -c, 0, c if corner < 2 else -c)
		for s in COFFEE_TABLE_CORNER_SEGMENTS + 1:
			var phi := PI / 2.0 * (corner + float(s) / COFFEE_TABLE_CORNER_SEGMENTS)
			var n := Vector3(cos(phi), 0, sin(phi))
			ring.append(center + n * r)
			normals.append(n)
	var up := Vector3(0, thick, 0)
	for i in ring.size():
		var j := (i + 1) % ring.size()
		sh.tri(ring[i], ring[j], ring[j] + up, normals[i], normals[j], normals[j])
		sh.tri(ring[i], ring[j] + up, ring[i] + up, normals[i], normals[j], normals[i])
		sh.tri(up, ring[i] + up, ring[j] + up, Vector3.UP, Vector3.UP, Vector3.UP)
		sh.tri(Vector3.ZERO, ring[j], ring[i], Vector3.DOWN, Vector3.DOWN, Vector3.DOWN)
	return sh.commit()


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
## (Spielkonzept 6.10), Getränkedosen (3.2: auf der Theke für Geld, Kisten in Kühlraum und Lager), Kaffee (3.11: Tassen
## auf der Theke, Maschine links auf der Küchenzeile), Tanzfläche mit Discokugel und Plattenspieler-Tisch, Treffpunkte
## für Gäste und Monster.
func _common_rooms() -> void:
	var shelf := _furnishing("shelf", "bar")
	if not shelf.is_empty():
		var r: Rect2 = shelf["rect"]
		var along := Vector2(1, 0) if r.size.x >= r.size.y else Vector2(0, 1)
		var length := maxf(r.size.x, r.size.y)
		var spots: Array[Vector3] = []
		var node: Node3D = shelf["node"]
		if node.has_meta("back_bar"):   # Barregal-Modell: je Fach zwei Flaschen auf beiden Glasböden
			for y in BACK_BAR_SHELVES:
				for bay in BACK_BAR_BAYS:
					for dx in [-0.3, 0.25]:
						spots.append(node.transform * Vector3(bay + dx, y, BACK_BAR_SHELF_Z))
		else:
			for i in 14:
				var p := r.get_center() + along * (-length / 2.0 + 0.3 + i * (length - 0.6) / 13.0)
				spots.append(Vector3(p.x, float(shelf["top"]), p.y))
		var pack := (load(BOTTLES_MODEL) as PackedScene).instantiate()
		var bottles := pack.find_children("bottle_*", "MeshInstance3D", true, false)
		for i in spots.size():   # jede Flasche nur einmal (5 und 28 sind teilerfremd)
			var src: MeshInstance3D = bottles[i * 5 % bottles.size()]
			var bottle := Geo.mesh(root, src.mesh, Mat.model(BOTTLES_MODEL, src), spots[i])
			bottle.rotation.y = i * 1.3
		pack.free()
	var counter := _furnishing("bar_counter", "bar")
	if not counter.is_empty():
		var r: Rect2 = counter["rect"]
		var out: Vector2 = counter["front"]
		var along := Vector2(1, 0) if r.size.x >= r.size.y else Vector2(0, 1)
		var span := maxf(r.size.x, r.size.y) - 2.2
		var stools := _furnishings.filter(func(f: Dictionary) -> bool:
			return f["kind"] == "bar_stool" and (_named["bar"] as Rect2).has_point((f["rect"] as Rect2).get_center()))
		if not stools.is_empty():
			# Barhocker aus dem Plan (ZIM-158): Gäste stehen hinter je zwei benachbarten Hockern
			var at := func(f: Dictionary) -> float: return (f["rect"] as Rect2).get_center().dot(along)
			stools.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return at.call(a) < at.call(b))
			for i in range(1, stools.size()):
				var s := ((stools[i - 1]["rect"] as Rect2).get_center() + (stools[i]["rect"] as Rect2).get_center()) / 2.0 + out * 0.55
				bar_spots.append(Vector3(s.x, 0, s.y))
			if stools.size() == 1:
				var s := (stools[0]["rect"] as Rect2).get_center() + along * 0.5 + out * 0.55
				bar_spots.append(Vector3(s.x, 0, s.y))
		elif ResourceLoader.exists(BAR_STOOL_MODEL):
			# Barhocker vor der Platte (Kollision wie ein Stuhl); Gäste stehen dahinter zwischen zwei Hockern
			var edge := minf(r.size.x, r.size.y) / 2.0
			for i in BAR_STOOLS:
				var p := r.get_center() + along * (-span / 2.0 + i * span / (BAR_STOOLS - 1)) + out * (edge + BAR_STOOL_OUT)
				var stool := _fixture_body(BAR_STOOL_MODEL, p, out)
				stool.rotation.y += i * 0.4 - 1.0   # nicht alle gleich ausgerichtet
				Geo.add_box_shape(stool, Vector3(0.4, BAR_STOOL_SEAT, 0.4), Vector3(0, BAR_STOOL_SEAT / 2.0, 0))
				if i > 0:
					var s := p - along * span / (BAR_STOOLS - 1) / 2.0 + out * 0.55
					bar_spots.append(Vector3(s.x, 0, s.y))
		else:
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
		# Dosen zum Kaufen am Ende der Theke, gegenüber der Kerze
		var cans := ResourceSpot.new().setup(Item.Kind.SODA_CAN, "Getränkedose", 6, 240.0).for_sale(1)
		var can_at := at - along * (span / 2.0 + 0.2)
		cans.rotation.y = tap.rotation.y
		_supply(cans, Vector3(can_at.x, float(counter["top"]), can_at.y))
		# Kaffee für Geld (3.11) zwischen Flasche und Stühlen auf der anderen Seite
		var cups := ResourceSpot.new().setup(Item.Kind.COFFEE, "Tasse Kaffee", 6, 240.0).for_sale(1)
		var cup_at := at + along * (span / 4.0)
		cups.rotation.y = tap.rotation.y
		_supply(cups, Vector3(cup_at.x, float(counter["top"]), cup_at.y))
		# Tee daneben (3.12)
		var teas := ResourceSpot.new().setup(Item.Kind.TEA, "Tasse Tee", 6, 240.0).for_sale(1)
		var tea_at := cup_at + along * BAR_TEA_GAP
		teas.rotation.y = tap.rotation.y
		_supply(teas, Vector3(tea_at.x, float(counter["top"]), tea_at.y))
	# Getränkekisten auf dem Boden vor dem Regal in Kühlraum und Lager (im Lager weg von den Ersatzbirnen)
	for room: String in ["kuehlraum", "lager"]:
		var store := _furnishing("shelf", room)
		if store.is_empty():
			continue
		var sr: Rect2 = store["rect"]
		var room_center: Vector2 = (_named[room] as Rect2).get_center()
		var out := Vector2(signf(room_center.x - sr.get_center().x), 0) if sr.size.y > sr.size.x else Vector2(0, signf(room_center.y - sr.get_center().y))
		var p := sr.get_center() + out * (minf(sr.size.x, sr.size.y) / 2.0 + 0.3) + Vector2(out.y, out.x) * (1.2 if room == "lager" else 0.0)
		var crate := ResourceSpot.new().setup(Item.Kind.SODA_CAN, "Getränkedose aus der Kiste", 4 if room == "kuehlraum" else 2, 600.0)
		crate.rotation.y = PI / 2.0 if sr.size.y > sr.size.x else 0.0   # lange Seite am Regal entlang
		_supply(crate, Vector3(p.x, 0.0, p.y))
	# Partyraum: Plattenspieler auf dem Tisch, dunkle Ecke (dort steht es beim ersten Angriff), Tanzfläche mit
	# Discokugel darüber
	var r: Rect2 = _named["partyraum"]
	var c := r.get_center()
	var disco := _planned_here("disco_ball", r)
	if not disco.is_empty():   # Discokugel aus dem Plan (ZIM-158): die Tanzfläche liegt darunter
		c = disco[0]["pos"]
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
		if _rect(rc).has_point(c):
			top = UP_Y + H
	var ball := DiscoBall.new().setup(top - DISCO_Y)
	ball.position = Vector3(c.x, DISCO_Y, c.y)
	root.add_child(ball)
	# Bunte Partylampen und Konfetti (Spielkonzept 7.6, 2026-10-21)
	root.add_child(PartyLights.new().setup(r, minf(top, H) - 0.35, party_center))
	root.add_child(Confetti.new())
	var k: Rect2 = _named["kueche"]
	kitchen_spot = Vector3(k.get_center().x, 0, k.get_center().y)
	var inner := k.grow(-0.8)
	var nx := maxi(1, floori(inner.size.x / KITCHEN_SPOT_STEP) + 1)
	var nz := maxi(1, floori(inner.size.y / KITCHEN_SPOT_STEP) + 1)
	for ix in nx:
		for iz in nz:
			kitchen_spots.append(Vector3(inner.position.x + inner.size.x * (ix + 0.5) / nx, 0,
				inner.position.y + inner.size.y * (iz + 0.5) / nz))
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
	# Kaffeemaschine (Spielkonzept 3.11): am linken Ende der Küchenzeile, von vorn gesehen – rechts daneben der Wasserkocher
	var counter_info := _furnishing("kitchen_counter", "kueche")
	if not counter_info.is_empty():
		var kr: Rect2 = counter_info["rect"]
		var kf: Vector2 = counter_info["front"] if counter_info["front"] != Vector2.ZERO else Vector2(0, 1)
		var left := Vector2(-kf.y, kf.x)   # von vorn gesehen links
		var reach := (kr.size.x if absf(kf.x) < 0.5 else kr.size.y) / 2.0 - COFFEE_MACHINE_INSET
		var mp := kr.get_center() + left * reach
		var machine := CoffeeMachine.new()
		machine.position = Vector3(mp.x, float(counter_info["top"]), mp.y)
		machine.rotation.y = atan2(kf.x, kf.y)
		machine.front = Vector3(kf.x, 0, kf.y)
		root.add_child(machine)
		# Wasserkocher (3.12) rechts daneben
		var kp := mp - left * KETTLE_GAP
		var kettle := TeaKettle.new()
		kettle.position = Vector3(kp.x, float(counter_info["top"]), kp.y)
		kettle.rotation.y = machine.rotation.y
		kettle.front = machine.front
		root.add_child(kettle)
		# Brotkrumen für die Krähen (4.25): Brett mit Brot links der Mitte der Küchenzeile
		var bp := kr.get_center() + left * BREAD_OFFSET - kf * 0.08
		var bread := ResourceSpot.new().setup(Item.Kind.PUMPKIN_SEEDS, "Brotkrumen", 4, 300.0).with_extra("brot")
		bread.rotation.y = machine.rotation.y
		_supply(bread, Vector3(bp.x, float(counter_info["top"]), bp.y))
		# Salz (5.13): solange keins im Plan steht, SALT_BOXES Packungen am rechten Ende der Küchenzeile
		if not (_map["items"] as Array).any(func(i: Dictionary) -> bool: return i["kind"] == "SALT"):
			for i in SALT_BOXES:
				var sp := kr.get_center() - left * (reach - i * 0.09) - kf * 0.12
				var salt := Item.create(Item.Kind.SALT)
				salt.position = root.global_transform * Vector3(sp.x, float(counter_info["top"]) + 0.005, sp.y)
				salt.rotation.y = machine.rotation.y + randf_range(-0.2, 0.2)
				world.add_child(salt)
		# Eier (6.13): ein Karton neben dem Salz, morgens wieder EGG_BOX Stück
		var ep := kr.get_center() - left * (reach - SALT_BOXES * 0.09 - 0.2) - kf * 0.12
		var eggs := ResourceSpot.new().setup(Item.Kind.EGG, "Ei aus dem Karton", EGG_BOX, 150.0).refill_mornings(EGG_BOX)
		eggs.position = Vector3(ep.x, float(counter_info["top"]), ep.y)
		eggs.rotation.y = machine.rotation.y
		root.add_child(eggs)


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
	var depth := POOL_DEPTH
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
	# Unterwasserlampen: aus dem Plan (ZIM-158) in der nächsten Beckenwand, sonst gleichmäßig verteilt in beiden
	# Längswänden; am Schalter der Halle
	var long_x := w.size.x >= w.size.y
	var length := w.size.x if long_x else w.size.y
	var room_id := _light_room_at((_named["pool"] as Rect2).position + Vector2(0.5, 0.5))   # Umgang, nicht das Becken
	var lamps := _planned_here("pool_lamp", w.grow(0.5))
	for spot: Dictionary in lamps:
		var p: Vector2 = spot["pos"]
		var into := Vector2(0, 1)   # ins Becken, von der nächsten Wand weg
		var best := INF
		for d: Vector2 in [Vector2(0, 1), Vector2(0, -1), Vector2(1, 0), Vector2(-1, 0)]:
			var wall_at := w.get_center() - d * (_depth_of(w, d) / 2.0)
			var dist := absf((p - wall_at).dot(d))
			if dist < best:
				best = dist
				into = d
		var on := p - into * (p - (w.get_center() - into * (_depth_of(w, into) / 2.0 - 0.2))).dot(into)
		var lamp := Lamp.new().setup(Lamp.Style.POOL, room_id, POOL_LAMP_ENERGY, POOL_LAMP_RANGE, false)
		lamp.position = Vector3(on.x, POOL_LAMP_Y, on.y)
		lamp.rotation.y = atan2(into.x, into.y)   # lokale +Z zeigt ins Becken
		root.add_child(lamp)
	for s: float in ([] if not lamps.is_empty() else [-1.0, 1.0]):
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
func _rod(a: Vector3, b: Vector3, mat: Material) -> void:
	var mi := Geo.mesh(root, Geo.cylinder(0.025, a.distance_to(b), 6), mat, (a + b) / 2.0)
	var up := (b - a).normalized()
	var side := up.cross(Vector3.FORWARD if absf(up.z) < 0.9 else Vector3.RIGHT).normalized()
	mi.basis = Basis(side, up, side.cross(up))


# --- Gärten -----------------------------------------------------------------------------------------

func _gardens() -> void:
	_garden_beds()
	var trees: Array = _map["trees"]
	for i in trees.size():
		_tree(_v3(trees[i]["center"]), i)   # der Plan zeigt nur den Standort
	var has_model := ResourceLoader.exists(PLANTER_MODEL)
	for rc in _map["planters"]:
		var size := Vector2(float(rc[2]) - float(rc[0]), float(rc[3]) - float(rc[1]))
		var c := Vector3((float(rc[0]) + float(rc[2])) / 2.0, 0, (float(rc[1]) + float(rc[3])) / 2.0)
		if has_model:
			_planter(c, size)
		else:
			Geo.solid(root, Vector3(size.x, PLANTER_H, size.y), c + Vector3(0, PLANTER_H / 2.0, 0), _stone)
			Geo.mesh(root, Geo.sphere(size.x * 0.4, 1.2, 7, 4), _hedge, c + Vector3(0, PLANTER_H + 0.5, 0))
	Hedge.build(root, _map["terrace_edges"], _map["walls"])
	for rc in _map.get("hedge_arches", []):
		_hedge_arch(_rect(rc))


## Torbogen aus Hecke (Friedhof, Spielkonzept 5.15): auf beiden Seiten der Lücke ein Pfosten so dick wie die Hecke,
## darüber ein Halbbogen aus Heckenstücken. Kollision nur an den Pfosten, der Bogen liegt über Kopfhöhe.
func _hedge_arch(r: Rect2) -> void:
	var along := Vector3(0, 0, 1) if r.size.y >= r.size.x else Vector3(1, 0, 0)
	var span := maxf(r.size.x, r.size.y)
	var c := Vector3(r.get_center().x, _base_y, r.get_center().y)
	var post := Hedge.WIDTH
	var post_h := ARCH_POST_H
	var size := Vector3(post, post_h, post)
	for s: float in [-1.0, 1.0]:
		var p := c + along * s * (span / 2.0 - post / 2.0 + ARCH_INSET) + Vector3.UP * post_h / 2.0
		Geo.solid(root, size, p, _hedge)
	var radius := span / 2.0 - post / 2.0 + ARCH_INSET
	var steps := 9
	for i in steps:
		var a0 := PI * float(i) / steps
		var a1 := PI * float(i + 1) / steps
		var p0 := c + along * cos(a0) * radius + Vector3.UP * (post_h + sin(a0) * ARCH_RISE)
		var p1 := c + along * cos(a1) * radius + Vector3.UP * (post_h + sin(a1) * ARCH_RISE)
		var piece := Geo.mesh(root, Geo.box(Vector3(post, post * 0.8, p0.distance_to(p1) + 0.12)), _hedge, (p0 + p1) / 2.0)
		piece.basis = Basis.looking_at(p1 - p0, along.cross(Vector3.UP))


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
		garden_beds.append(Rect2(x0 - 0.8, z - 0.65, x1 - x0 + 1.6, 1.3))
		garden_spots.append(Vector3((x0 + x1) / 2.0, 0, z + 1.0))


## Baum Nummer index aus TREE_MODELS (der Reihe nach, je um TREE_TURN gedreht). Kollision nur am Stamm, unter der
## Krone kann man durchgehen. Blätter sind ausgestanzte Karten (Mat.model mit cutout), die Rinde einseitig.
func _tree(pos: Vector3, index: int) -> void:
	var info: Dictionary = TREE_MODELS[index % TREE_MODELS.size()]
	var path: String = info["path"]
	if ResourceLoader.exists(path):
		tree_spots.append({"pos": pos, "radius": info["radius"], "height": info["height"], "crown": info["crown"]})
		var trunk: float = info["trunk"]
		var body := Geo.collider(root, Vector3(trunk, TREE_TRUNK_H, trunk), pos + Vector3(0, TREE_TRUNK_H / 2.0, 0))
		var model: Node3D = (load(path) as PackedScene).instantiate()
		model.position.y = -TREE_TRUNK_H / 2.0
		model.rotation.y = deg_to_rad(TREE_TURN * index)
		body.add_child(model)
		for m: MeshInstance3D in model.find_children("*", "MeshInstance3D", true, false):
			for i in m.mesh.get_surface_count():
				var leaves := m.get_active_material(i).resource_name == "leaves"
				var mat := Mat.model(path, m, i, false, leaves)
				if leaves:
					mat.set_shader_parameter("sway", 1.0)   # Blätter flattern im Wind (Weather, 7.8)
				m.set_surface_override_material(i, mat)
		_falling_leaves(pos, info["radius"], info["height"], info["crown"])
		return
	var radius := TREE_RADIUS
	var height := clampf(radius * 1.1, 3.2, 6.0)
	tree_spots.append({"pos": pos, "radius": radius, "height": height + radius * 0.45, "crown": TREE_CROWN})
	_falling_leaves(pos, radius, height + radius * 0.45, TREE_CROWN)
	var trunk := Geo.solid(root, Vector3(0.5, height, 0.5), pos + Vector3(0, height / 2.0, 0), Mat.psx(Color(0.22, 0.15, 0.1)))
	var colors: Array[Color] = [Color(0.6, 0.25, 0.05), Color(0.7, 0.4, 0.08), Color(0.45, 0.12, 0.05)]
	var offsets: Array[Vector3] = [Vector3(0, height / 2.0, 0), Vector3(radius * 0.35, height / 2.0 - 0.6, radius * 0.2), Vector3(-radius * 0.3, height / 2.0 - 0.4, -radius * 0.25)]
	for i in 3:
		Geo.mesh(trunk, Geo.sphere(radius * (0.7 - i * 0.12), radius * (0.9 - i * 0.12), 8, 4), Mat.psx(colors[i]), offsets[i])


## Herbstlaub löst sich aus der Krone, sinkt schaukelnd und trudelnd und bleibt kurz flach am Boden liegen
## (floor_y im Partikel-Shader), bevor es verblasst. crown = Höhenbereich der Krone als Anteile von height.
func _falling_leaves(pos: Vector3, radius: float, height: float, crown: Vector2) -> void:
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
	leaves.position = pos + Vector3(0, height * (crown.x + crown.y) / 2.0, 0)
	leaves.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	leaves.emission_box_extents = Vector3(radius * 0.75, height * (crown.y - crown.x) / 2.0, radius * 0.75)
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
	leaf_emitters.append(leaves)


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


## Gartenlaterne (`assets/models/lantern.glb`): das Licht sitzt im Glaskasten – Kopf und Glas werfen deshalb keinen
## Schatten, sonst bliebe es darin gefangen; der Mast schon.
func _lantern(pos: Vector3, broken: bool, energy: float) -> void:
	var iron := Mat.psx(Color(0.1, 0.1, 0.1))
	var mat := Mat.psx(Color(1, 0.95, 0.8), "", 1.0, Color(1.0, 0.8, 0.5), 2.5, false)
	var light_y := 2.3
	if ResourceLoader.exists(LANTERN_MODEL):
		var body := StaticBody3D.new()
		body.collision_mask = 0
		body.position = pos
		root.add_child(body)
		var model: Node3D = (load(LANTERN_MODEL) as PackedScene).instantiate()
		body.add_child(model)
		for m: MeshInstance3D in model.find_children("*", "MeshInstance3D", true, false):
			m.material_override = mat if m.name == "glass" else iron
			if m.name != "post":
				m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		# Kollision (auch für das NavMesh): Fuß bis über den Wulst, Mast bis unter den Kopf
		Geo.add_box_shape(body, Vector3(0.5, 0.36, 0.5), Vector3(0, 0.18, 0))
		Geo.add_box_shape(body, Vector3(0.1, 2.04, 0.1), Vector3(0, 1.38, 0))
		light_y = LANTERN_LIGHT_Y
	else:
		Geo.solid(root, Vector3(0.12, 2.4, 0.12), pos + Vector3(0, 1.2, 0), iron)
		Geo.mesh(root, Geo.box(Vector3(0.25, 0.3, 0.25)), mat, pos + Vector3(0, 2.55, 0))
	var light := FlickerLight.new()
	light.position = pos + Vector3(0, light_y, 0)
	light.base_energy = energy * Lamp.BRIGHTNESS
	light.omni_range = 6.0 * Lamp.REACH
	light.light_color = Color(1.0, 0.75, 0.45)
	light.shadow_enabled = true
	light.broken = broken
	light.lamp_material = mat
	light.add_to_group("lamps")
	root.add_child(light)


# --- Dachgeschoss -----------------------------------------------------------------------------------

## Dachgeschoss (Spielkonzept 4.21, 7.10; Plan „DG“ seit 24.10.): grobe Bohlen an Boden, Wänden und Decke (ATTIC_H),
## an den Außenwänden ein Kniestock mit Dachschräge und Dachfenstern, niedrige Türen (die zum Treppenhaus ist die
## verschlossene Kniestocktür), Stützbalken mit Balkenkreuz, blaugrauer Staubnebel, Kisten mit alter Deko und auf dem
## roten Kreuz des Plans der Kopf des Kürbismanns. Dazu die Treppe vom Obergeschoss herauf (_attic_stair).
func _attic_floor(plan: Dictionary, level: int) -> void:
	var ground := root
	var attic := Node3D.new()
	attic.name = "Dachgeschoss"
	attic.position.y = UP_Y * level
	ground.add_child(attic)
	root = attic
	_parent = attic
	_begin_floor(plan, level)
	_attic_eaves()
	_attic_openings()
	for w in _map["walls"]:
		_build_wall(w)
	_attic_surfaces()
	_attic_slopes()
	_attic_beams()
	_furniture()
	_rugs()
	_fittings()
	_items()
	_lights()
	_attic_markers()
	_attic_haze()
	_floors.append(_state())
	root = ground
	_parent = root
	_attic_stair(plan, level)


## Türen und Dachfenster des Plans: Jede Tür im Dachgeschoss hat das Kniestocktür-Modell, ATTIC_DOOR_H hoch (unter
## einer Schräge niedriger, braucht dafür _eaves); die zum Treppenhaus ist die verschlossene Kniestocktür („attic_door“,
## Schlüssel im Heizraum), die übrigen gehen auf („attic_inner_door“). Dachfenster sitzen auf der Außenwand – sie kommen
## in die Schräge darüber (_attic_slopes), nicht in die Wand.
func _attic_openings() -> void:
	_roof_windows = []
	for w in _map["walls"]:
		var a := _v2(w["a"])
		var b := _v2(w["b"])
		var horizontal := is_equal_approx(a.y, b.y)
		var along := Vector2(1, 0) if horizontal else Vector2(0, 1)
		var side := Vector2(0, 1) if horizontal else Vector2(1, 0)
		var keep: Array = []
		for o: Dictionary in w.get("openings", []):
			var c := a + along * (float(o["at"]) + float(o["width"]) / 2.0)
			match String(o["kind"]):
				"roof_window":
					_roof_windows.append({"pos": c, "width": float(o["width"])})
					continue
				"door", "attic_door":
					var stairs := "stairs" in [_kind_at(c - side * 0.5), _kind_at(c + side * 0.5)]
					o["kind"] = "attic_door" if stairs else "attic_inner_door"
					var jamb := along * float(o["width"]) / 2.0
					var low := minf(_attic_ceiling(c - jamb), _attic_ceiling(c + jamb))
					o["height"] = minf(ATTIC_DOOR_H, floorf((low - ATTIC_DOOR_HEAD) / 0.05 + 0.001) * 0.05)
			keep.append(o)
		w["openings"] = keep


## Traufen: Stücke der Außenwände (draußen auf der einen, Dachboden auf der anderen Seite), über denen die Schräge
## ansetzt – abgetastet wie in _build_wall (alle GRID m, kurze Läufe geglättet).
func _attic_eaves() -> void:
	_eaves = []
	for w in _map["walls"]:
		var a := _v2(w["a"])
		var b := _v2(w["b"])
		var horizontal := is_equal_approx(a.y, b.y)
		var along := Vector2(1, 0) if horizontal else Vector2(0, 1)
		var side := Vector2(0, 1) if horizontal else Vector2(1, 0)
		var s0 := a.x if horizontal else a.y
		var s1 := b.x if horizontal else b.y
		var steps := maxi(1, roundi((s1 - s0) / GRID))
		var minus: Array[String] = []
		var plus: Array[String] = []
		for i in steps:
			var p := a + along * (i + 0.5) * (s1 - s0) / steps
			minus.append(_kind_at(p - side * 0.3))
			plus.append(_kind_at(p + side * 0.3))
		_smooth(minus)
		_smooth(plus)
		var start := 0
		var inward := 0
		for i in steps + 1:
			var dir := 0
			if i < steps:
				if minus[i] == "outside" and plus[i] == "attic":
					dir = 1
				elif plus[i] == "outside" and minus[i] == "attic":
					dir = -1
			if dir != inward:
				if inward != 0:
					_eaves.append({"horizontal": horizontal, "fixed": a.y if horizontal else a.x, "inward": inward,
						"from": s0 + start * (s1 - s0) / steps, "to": s0 + i * (s1 - s0) / steps})
				start = i
				inward = dir


## Höhe der Decke über p im Dachgeschoss (über dem Boden): ATTIC_H, unter einer Schräge tiefer – an der Innenfläche
## der Außenwand ATTIC_KNEE, ATTIC_SLOPE weiter innen wieder ATTIC_H. skip = Traufe, die nicht zählt (Index in _eaves).
func _attic_ceiling(p: Vector2, skip: int = -1) -> float:
	var h := ATTIC_H
	for i in _eaves.size():
		if i == skip:
			continue
		var e: Dictionary = _eaves[i]
		var horizontal: bool = e["horizontal"]
		var s := p.x if horizontal else p.y
		if s < float(e["from"]) - T / 2.0 or s > float(e["to"]) + T / 2.0:
			continue
		var d := ((p.y if horizontal else p.x) - float(e["fixed"])) * float(e["inward"]) - T / 2.0
		if d < -T or d > ATTIC_SLOPE:
			continue
		h = minf(h, ATTIC_KNEE + (ATTIC_H - ATTIC_KNEE) * clampf(d / ATTIC_SLOPE, 0.0, 1.0))
	return h


## Streifen unter der Schräge einer Traufe (von der Innenfläche der Außenwand ATTIC_SLOPE nach innen).
func _eave_strip(e: Dictionary) -> Rect2:
	var face := float(e["fixed"]) + float(e["inward"]) * T / 2.0
	var lo := minf(face, face + float(e["inward"]) * ATTIC_SLOPE)
	var a0 := float(e["from"]) - T / 2.0
	var a1 := float(e["to"]) + T / 2.0
	if e["horizontal"]:
		return Rect2(a0, lo, a1 - a0, ATTIC_SLOPE)
	return Rect2(lo, a0, ATTIC_SLOPE, a1 - a0)


## Boden aus Bohlen, Decke aus Bohlen auf ATTIC_H (außer unter den Schrägen), darüber die Dachhaut; Schwellen.
func _attic_surfaces() -> void:
	var strips: Array[Rect2] = []
	for e in _eaves:
		strips.append(_eave_strip(e))
	for r in _map["regions"]:
		for rc in r["rects"]:
			_floor_rect(rc, _attic_planks)
			# Die Dachhaut reicht über die Wände (halbe Wandstärke); die Decke darunter liegt zwischen ihnen
			for piece in _subtract(_rect(rc), strips):
				structure_parts.append(Geo.solid(root, Vector3(piece.size.x, 0.2, piece.size.y),
					Vector3(piece.get_center().x, ATTIC_H + 0.1, piece.get_center().y), _attic_planks, LAYER_CEILING))
			for piece in _subtract(_rect(rc).grow(T / 2.0), strips):
				Geo.mesh(root, Geo.box(Vector3(piece.size.x, 0.04, piece.size.y)), _attic_roof,
					Vector3(piece.get_center().x, ATTIC_H + 0.22, piece.get_center().y))
	for d in _doors:
		var door: Door = d["door"]
		var into: Vector3 = d["into"]
		var size := Vector3(door.width, 0.3, T) if absf(into.z) > 0.5 else Vector3(T, 0.3, door.width)
		Geo.solid(root, size, (d["pos"] as Vector3) + Vector3(0, -0.15, 0), _attic_planks)
		if d["kind"] == "attic_inner_door" and door.height < ATTIC_DOOR_H - 0.01:
			var link := NavigationLink3D.new()
			link.start_position = (d["pos"] as Vector3) - into * ATTIC_LINK_REACH
			link.end_position = (d["pos"] as Vector3) + into * ATTIC_LINK_REACH
			root.add_child(link)


## Dachschrägen über den Traufen: innen Bohlen, außen die Dachhaut, dazwischen die Dachfenster des Plans (Rahmen und
## Kreuz aus Holz, Glas ohne Schatten – Mondlicht fällt hindurch). Wo eine Schräge endet und daneben Dachboden mit
## voller Höhe liegt, schließt ein Giebeldreieck den Spalt darüber.
func _attic_slopes() -> void:
	var rise := ATTIC_H - ATTIC_KNEE
	var length := Vector2(ATTIC_SLOPE, rise).length()
	var frame_wood := Mat.wood(false, ATTIC_BEAM_TINT)
	for i in _eaves.size():
		var e: Dictionary = _eaves[i]
		var horizontal: bool = e["horizontal"]
		var inward := float(e["inward"])
		var a0 := float(e["from"]) - T / 2.0
		var a1 := float(e["to"]) + T / 2.0
		var face := float(e["fixed"]) + inward * T / 2.0
		var x_axis := Vector3(1, 0, 0) if horizontal else Vector3(0, 0, 1)
		var in3 := Vector3(0, 0, inward) if horizontal else Vector3(inward, 0, 0)
		var y_axis := (in3 * ATTIC_SLOPE + Vector3.UP * rise) / length
		var z_axis := x_axis.cross(y_axis)
		var out := 1.0 if z_axis.y > 0.0 else -1.0   # lokale Z-Richtung nach außen (oben)
		var holder := Node3D.new()
		holder.transform = Transform3D(Basis(x_axis, y_axis, z_axis),
			Vector3(0, ATTIC_KNEE, face) if horizontal else Vector3(face, ATTIC_KNEE, 0))
		root.add_child(holder)
		var windows: Array = []
		for wdw in _roof_windows:
			var p: Vector2 = wdw["pos"]
			var s := p.x if horizontal else p.y
			if absf((p.y if horizontal else p.x) - float(e["fixed"])) < 0.2 and s > a0 and s < a1:
				windows.append(Vector4(s, wdw["width"], ATTIC_WINDOW.y * length, ATTIC_WINDOW.x * length))
		var inner := Geo.mesh(holder, Geo.wall_mesh(a0, a1, length, 0.04, windows), _attic_planks, Vector3(0, 0, -out * 0.02))
		var skin := Geo.mesh(holder, Geo.wall_mesh(a0, a1, length, 0.04, windows), _attic_roof, Vector3(0, 0, out * 0.06))
		structure_parts.append(inner)
		structure_parts.append(skin)
		Geo.collider(holder, Vector3(a1 - a0, length, 0.12), Vector3((a0 + a1) / 2.0, length / 2.0, out * 0.02), LAYER_CEILING)
		for wdw: Vector4 in windows:
			_roof_window(holder, wdw, out, frame_wood)
			var below := Vector3(wdw.x, 0, face + inward * (ATTIC_SLOPE + 0.6)) if horizontal \
				else Vector3(face + inward * (ATTIC_SLOPE + 0.6), 0, wdw.x)
			attic_window_spots.append(Transform3D(Basis.looking_at(-in3), _global(below)))
		for end in 2:
			var s_end := a0 if end == 0 else a1
			var beyond := s_end + (0.3 if end == 1 else -0.3)
			var d := face + inward * ATTIC_SLOPE / 2.0
			var probe := Vector2(beyond, d) if horizontal else Vector2(d, beyond)
			if _kind_at(probe) == "attic" and _attic_ceiling(probe, i) > ATTIC_H - 0.01:
				_attic_gable(horizontal, s_end, face, inward)


## Dachfenster in der Schräge (lokal: x entlang der Traufe, y die Schräge hinauf, out = lokale Z nach außen): Rahmen,
## Kreuz aus Holz in der Mitte, Glasscheibe mit Regentropfen.
func _roof_window(holder: Node3D, w: Vector4, out: float, wood: Material) -> void:
	var bar := ATTIC_WINDOW_BAR
	var mid := (w.z + w.w) / 2.0
	var tall := w.z - w.w
	var depth := 0.14
	var z := out * 0.02
	for x: float in [w.x - w.y / 2.0 + bar / 2.0, w.x, w.x + w.y / 2.0 - bar / 2.0]:   # Seiten und Mittelpfosten
		Geo.mesh(holder, Geo.grain_box(Vector3(bar, tall, depth), 1, Vector2(1.0, 0.2), 0.2), wood, Vector3(x, mid, z))
	for y: float in [w.w + bar / 2.0, mid, w.z - bar / 2.0]:   # unten, Querholz, oben
		Geo.mesh(holder, Geo.grain_box(Vector3(w.y, bar, depth), 0, Vector2(1.0, 0.2), 0.2), wood, Vector3(w.x, y, z))
	var pane := QuadMesh.new()
	pane.size = Vector2(w.y, tall)
	var glass := Geo.mesh(holder, pane, Mat.glass(), Vector3(w.x, mid, out * 0.04))
	glass.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# Regen auf der Scheibe (7.8): Tropfen knapp über dem Glas; Rinnsale laufen die Schräge hinab
	HotelWindow.rain_drops(holder, pane, Vector3(w.x, mid, out * (0.04 + HotelWindow.DROPS_GAP)))
	# Licht, das durchs Fenster fällt: kalter Kegel ohne Schatten von außen hinein (AtticHaze regelt ihn mit dem Mond)
	var shaft := SpotLight3D.new()
	shaft.position = Vector3(w.x, mid, out * 0.4)
	if out < 0.0:
		shaft.rotation.y = PI   # Kegel zeigt entlang −Z: nach innen
	shaft.spot_angle = ATTIC_SHAFT_ANGLE
	shaft.spot_range = ATTIC_SHAFT_RANGE
	shaft.light_color = ATTIC_SHAFT_COLOR
	shaft.light_volumetric_fog_energy = ATTIC_SHAFT_FOG
	shaft.distance_fade_enabled = true
	shaft.distance_fade_begin = 25.0
	shaft.distance_fade_length = 5.0
	holder.add_child(shaft)
	_window_shafts.append(shaft)


## Giebeldreieck am Ende einer Schräge (bei s entlang der Traufe, face = Innenfläche der Außenwand): schließt den Raum
## über der Schräge zur Seite hin, mit Kollision.
func _attic_gable(horizontal: bool, s: float, face: float, inward: float) -> void:
	var at := func(d: float, y: float) -> Vector3:
		var across := face + inward * d
		return Vector3(s, y, across) if horizontal else Vector3(across, y, s)
	var pts := PackedVector3Array([at.call(0.0, ATTIC_KNEE), at.call(ATTIC_SLOPE, ATTIC_H), at.call(0.0, ATTIC_H)])
	var normal := Vector3(1, 0, 0) if horizontal else Vector3(0, 0, 1)
	var front := -(pts[1] - pts[0]).cross(pts[2] - pts[0]).normalized()   # Godot: von vorn im Uhrzeigersinn
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for k in 6:   # beide Seiten
		st.set_normal(front if k < 3 else -front)
		st.add_vertex(pts[[0, 1, 2, 0, 2, 1][k]])
	var gable := Geo.mesh(root, st.commit(), _attic_planks, Vector3.ZERO)
	structure_parts.append(gable)
	var body := StaticBody3D.new()
	body.collision_layer = LAYER_CEILING
	body.collision_mask = 0
	root.add_child(body)
	var shape := ConvexPolygonShape3D.new()
	var thick := normal * 0.05
	shape.points = PackedVector3Array([pts[0] - thick, pts[1] - thick, pts[2] - thick, pts[0] + thick, pts[1] + thick, pts[2] + thick])
	var cs := CollisionShape3D.new()
	cs.shape = shape
	body.add_child(cs)


## Stützbalken: In jeder Fläche des Dachbodens je Feld von etwa ATTIC_BAY m ein Pfosten in der Mitte (nicht unter der
## Schräge, nicht vor einer Tür), oben ein Balkenkreuz bis an die Wände bzw. bis zum nächsten Feld, jeder Arm mit
## einem Kopfband unter 45°. Je Fläche ein Mesh (Längsholz und Hirnholz) und ein Körper mit den Kollisionen.
func _attic_beams() -> void:
	var long := Mat.wood(false, ATTIC_BEAM_TINT)
	var ends := Mat.wood(true, ATTIC_BEAM_TINT)
	var rng := RandomNumberGenerator.new()
	rng.seed = 1987
	for r in _map["regions"]:
		if r["kind"] != "attic":
			continue
		var parts: Array = []   # [Mesh, Transform3D]
		var body := StaticBody3D.new()
		body.collision_mask = 0
		root.add_child(body)
		var beam := func(size: Vector3, grain: int, basis: Basis, pos: Vector3, solid: bool) -> void:
			var m := Geo.grain_box(size, grain, Vector2(2.0, 0.4), 0.3, Vector2(rng.randf(), rng.randf()))
			parts.append([m, Transform3D(basis, pos)])
			if solid:
				Geo.add_box_shape(body, size, pos)
		var b := _bounds(r["rects"])
		var n := Vector2i(maxi(1, roundi(b.size.x / ATTIC_BAY)), maxi(1, roundi(b.size.y / ATTIC_BAY)))
		var cell := b.size / Vector2(n)
		var arm_y := ATTIC_BEAM_BOTTOM + ATTIC_BEAM / 2.0
		for ix in n.x:
			for iz in n.y:
				var c := b.position + cell * Vector2(ix + 0.5, iz + 0.5)
				if not _in_region(c, r) or _attic_ceiling(c) < ATTIC_H - 0.01 or _near_door(c, ATTIC_POST_DOOR_GAP):
					continue
				beam.call(Vector3(ATTIC_POST, ATTIC_BEAM_BOTTOM, ATTIC_POST), 1, Basis(), Vector3(c.x, ATTIC_BEAM_BOTTOM / 2.0, c.y), true)
				_attic_posts.append(c)
				var arms: Array = []
				attic_beams.append({"pos": Vector3(c.x, _base_y, c.y), "arms": arms})
				for dir: Vector2 in [Vector2.RIGHT, Vector2.LEFT, Vector2.DOWN, Vector2.UP]:
					var reach := (cell.x if dir.x != 0.0 else cell.y) / 2.0
					var len := 0.0
					while len < reach:
						var next := minf(len + 0.1, reach)
						var p := c + dir * next
						if not _in_region(p, r) or _attic_ceiling(p) < ATTIC_BEAM_BOTTOM + ATTIC_BEAM:
							break
						len = next
					if len < reach:
						len += 0.08   # bis an die Wand bzw. in die Schräge
					if len < ATTIC_POST or _near_door(c + dir * len, ATTIC_ARM_DOOR_GAP):
						continue   # kein Arm, der neben einer Tür auf die Wand trifft – er säße im Rahmen
					arms.append([Vector3(dir.x, 0.0, dir.y), len])
					var x_dir := dir.x != 0.0
					var mid := c + dir * len / 2.0
					var size := Vector3(len, ATTIC_BEAM, ATTIC_BEAM) if x_dir else Vector3(ATTIC_BEAM, ATTIC_BEAM, len)
					beam.call(size, 0 if x_dir else 2, Basis(), Vector3(mid.x, arm_y, mid.y), true)
					if len < ATTIC_POST / 2.0 + ATTIC_BRACE + 0.1:
						continue
					# Kopfband: vom Pfosten schräg hinauf unter den Arm
					var axis := Vector3(dir.x, 1.0, dir.y).normalized()
					var side := Vector3(-dir.y, 0.0, dir.x)
					var basis := Basis(axis, side.cross(axis), side)
					var at := c + dir * (ATTIC_POST / 2.0 + ATTIC_BRACE / 2.0)
					beam.call(Vector3(ATTIC_BRACE * sqrt(2.0) + ATTIC_BRACE_SIZE, ATTIC_BRACE_SIZE, ATTIC_BRACE_SIZE), 0, basis,
						Vector3(at.x, ATTIC_BEAM_BOTTOM - ATTIC_BRACE / 2.0, at.y), false)
		if parts.is_empty():
			body.queue_free()
			continue
		var mesh := ArrayMesh.new()
		for surface in 2:
			var st := SurfaceTool.new()
			for part: Array in parts:
				st.append_from(part[0], surface, part[1])
			st.commit(mesh)
		var mi := Geo.mesh(root, mesh, null, Vector3.ZERO)
		mi.set_surface_override_material(0, long)
		mi.set_surface_override_material(1, ends)
		structure_parts.append(mi)


## Liegt p in der Fläche region (Plan-Region)?
func _in_region(p: Vector2, region: Dictionary) -> bool:
	var place := _place_at(p)
	return not place.is_empty() and is_same(place["region"], region)


## Steht eine Tür dieses Stockwerks näher als dist an p?
func _near_door(p: Vector2, dist: float) -> bool:
	for d in _doors:
		var pos: Vector3 = d["pos"]
		if Vector2(pos.x, pos.z).distance_to(p) < dist:
			return true
	return false


## Markierungen des Plans: Auf dem roten Kreuz liegt der richtige Kopf des Kürbismanns (Spielkonzept 4.21).
func _attic_markers() -> void:
	for m in _map.get("markers", []):
		if m["kind"] == "cross":
			var p := _v2(m["pos"])
			for post in _attic_posts:   # steht dort ein Stützbalken, liegt der Kopf an seinem Fuß
				if post.distance_to(p) < ATTIC_POST:
					p = post + Vector2(0, ATTIC_POST / 2.0 + 0.14)
			_item(Item.Kind.PUMPKIN_HEAD, Vector3(p.x, 0.02, p.y))
			pumpkin_head_spot = _global(Vector3(p.x, 0.0, p.y))


## Staubnebel (AtticHaze) über die Fläche des Dachbodens: das Raster der Flächen in 1-m-Zellen, zu Rechtecken
## zusammengefasst (über den Innenhöfen kein Nebel).
func _attic_haze() -> void:
	var lo := Vector2(INF, INF)
	var hi := Vector2(-INF, -INF)
	for r in _map["regions"]:
		var b := _bounds(r["rects"])
		lo = Vector2(minf(lo.x, b.position.x), minf(lo.y, b.position.y))
		hi = Vector2(maxf(hi.x, b.end.x), maxf(hi.y, b.end.y))
	if lo.x == INF:
		return
	var size := Vector2i(ceili(hi.x - lo.x), ceili(hi.y - lo.y))
	var used := PackedByteArray()
	used.resize(size.x * size.y)
	for z in size.y:
		for x in size.x:
			var p := lo + Vector2(x + 0.5, z + 0.5)
			used[z * size.x + x] = 1 if _kind_at(p) in ["attic", "stairs"] else 0
	var rects: Array[Rect2] = []
	for z in size.y:
		var x := 0
		while x < size.x:
			if used[z * size.x + x] != 1:
				x += 1
				continue
			var x1 := x
			while x1 < size.x and used[z * size.x + x1] == 1:
				x1 += 1
			var z1 := z + 1
			while z1 < size.y:
				var full := true
				for k in range(x, x1):
					if used[z1 * size.x + k] != 1:
						full = false
						break
				if not full:
					break
				z1 += 1
			for zz in range(z, z1):
				for k in range(x, x1):
					used[zz * size.x + k] = 2
			rects.append(Rect2(lo + Vector2(x, z), Vector2(x1 - x, z1 - z)))
			x = x1
	attic_haze = AtticHaze.new().setup(rects, _base_y, ATTIC_H, _window_shafts)
	attic_haze.name = "Dachbodennebel"
	world.add_child(attic_haze)
	# Kammern (nicht die offenen Böden): Flächen, die in ein Feld der Stützbalken passen – dort spukt es beim Blitz
	# – und alle Räume des Dachbodens für den Notausgang beim Urteil (4.33)
	var chambers: Array[Rect2] = []
	var all_rooms: Array = []
	for r in _map["regions"]:
		if r["kind"] != "attic":
			continue
		var b := _bounds(r["rects"])
		var room: Array[Rect2] = []
		for rc in r["rects"]:
			room.append(_rect(rc))
		all_rooms.append(room)
		if b.size.x < ATTIC_BAY * 1.25 and b.size.y < ATTIC_BAY * 1.25:
			chambers.append_array(room)
	attic_spook = AtticSpook.new().setup(chambers, all_rooms, _base_y, ATTIC_H)
	attic_spook.name = "Dachbodenspuk"
	world.add_child(attic_spook)


## Treppe vom Obergeschoss in den Dachboden (Spielkonzept 4.21): im Schacht des Treppenhauses unter dem Treppenpodest
## des Plans „DG“ ein steiler gerader Lauf auf der einen Seite hinauf bis zum Podest an der Rückwand, von dort auf der
## anderen Seite (Geländer zum Treppenloch) zur Kniestocktür in der Wand des Dachbodens. Unten schließt ein Boden auf
## Höhe des Obergeschosses den Schacht ab (darunter bleibt das Treppenhaus gesperrt). Über dem Obergeschoss ein
## Verschlag aus Bohlen mit Dach und einer schwachen Wandleuchte. Gebaut im Rahmen des Schachts (lokal −Z zum Podest,
## _index_shafts), wie die Treppenhäuser – nur dass die Tür hinauf auf der Podestseite liegt.
func _attic_stair(plan: Dictionary, level: int) -> void:
	if not _shafts.has(_attic_shaft):
		return
	var sh: Dictionary = _shafts[_attic_shaft]
	var s: Dictionary = sh["plan"]
	var stair: Dictionary = plan["stairs"][0]
	var frame := Node3D.new()
	frame.name = "Dachbodentreppe"
	frame.transform = sh["frame"]
	frame.position.y = UP_Y * (level - 1)
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
	var z_land := zn + 1.5
	var z_door := zs - 1.4
	if s.has("steps"):
		var st: Array = s["steps"]
		var s0 := inv * Vector3(st[0], 0, st[1])
		var s1 := inv * Vector3(st[2], 0, st[3])
		z_land = minf(s0.z, s1.z)
		z_door = maxf(s0.z, s1.z)
	var mid := (x0 + x1) / 2.0
	var lane_w := (x1 - x0 - T) / 2.0
	# Die Kniestocktür (Plan „DG“) liegt auf einer Seite der Mittelwand: dort führt der Gang oben zurück zu ihr, auf der
	# anderen steigt der Lauf
	var door_at := inv * _v3(stair["door"]["pos"])
	var walk_west := door_at.x < mid
	var walk_x := x0 + lane_w / 2.0 if walk_west else x1 - lane_w / 2.0
	var flight_x := x1 - lane_w / 2.0 if walk_west else x0 + lane_w / 2.0
	var z_wall := door_at.z - T / 2.0   # Fläche der Dachbodenwand mit der Kniestocktür
	var rise := UP_Y
	var top := rise + ATTIC_H
	var below := H   # Oberkante der Schachtwände des Stockwerks darunter (über dessen Boden)
	Geo.solid(frame, Vector3(x1 - x0, 0.3, zs - zn), Vector3(mid, -0.15, (zs + zn) / 2.0), _wood_floor)
	_flight(flight_x, z_door, z_land, 0.0, rise, lane_w, _attic_planks)
	Geo.solid(frame, Vector3(x1 - x0, 0.3, z_land - zn), Vector3(mid, rise - 0.15, (zn + z_land) / 2.0), _attic_planks)
	Geo.solid(frame, Vector3(lane_w, 0.3, z_wall - z_land), Vector3(walk_x, rise - 0.15, (z_land + z_wall) / 2.0), _attic_planks)
	Geo.solid(frame, Vector3(T, rise, z_door - z_land), Vector3(mid, rise / 2.0, (z_door + z_land) / 2.0), _wallpaper)
	# Geländer am Treppenloch
	var rail := z_wall - z_land
	Geo.collider(frame, Vector3(0.08, 1.0, rail), Vector3(mid, rise + 0.5, (z_land + z_wall) / 2.0))
	Geo.mesh(frame, Geo.grain_box(Vector3(0.08, 0.06, rail), 2, Vector2(2.0, 0.4), 0.3), Mat.wood(false, ATTIC_BEAM_TINT),
		Vector3(mid, rise + 0.95, (z_land + z_wall) / 2.0))
	var posts := maxi(1, roundi(rail / 1.0))
	for i in posts + 1:
		Geo.mesh(frame, Geo.box(Vector3(0.06, 0.92, 0.06)), Mat.wood(false, ATTIC_BEAM_TINT),
			Vector3(mid, rise + 0.46, z_land + rail * i / posts))
	# Verschlag über dem Obergeschoss bis an die Wand des Dachbodens, mit Dach
	var h_wall := top - below
	var y_wall := (top + below) / 2.0
	structure_parts.append(Geo.solid(frame, Vector3(x1 - x0 + 2.0 * T, h_wall, T), Vector3(mid, y_wall, zn - T / 2.0), _attic_planks))
	for x: float in [x0 - T / 2.0, x1 + T / 2.0]:
		structure_parts.append(Geo.solid(frame, Vector3(T, h_wall, z_wall - zn), Vector3(x, y_wall, (zn + z_wall) / 2.0), _attic_planks))
	structure_parts.append(Geo.solid(frame, Vector3(x1 - x0 + 2.0 * T, 0.2, z_wall - zn + T), Vector3(mid, top + 0.1,
		(zn - T + z_wall) / 2.0), _attic_planks, LAYER_CEILING))
	Geo.mesh(frame, Geo.box(Vector3(x1 - x0 + 2.0 * T, 0.04, z_wall - zn + T)), _attic_roof, Vector3(mid, top + 0.22,
		(zn - T + z_wall) / 2.0))
	_wall_lamp(Vector3(walk_x, rise + 1.7, zn + WALL_GAP), 0.0, WALL_LAMP_ENERGY * 0.6, 5.0, "treppenhaus")
	attic_stair_foot = Transform3D(frame.global_basis, frame.global_transform * Vector3(flight_x, 0.0, (zs + z_door) / 2.0))
	_parent = root


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
	var steps := maxi(1, roundi(rise / step_h))   # flacher als eine halbe Stufe: eine Stufe statt Division durch 0
	var step_rise := rise / steps
	for i in steps:
		var y_top := y_from + step_rise * (i + 0.5)
		var z := z_from + dir * run * (i + 0.5) / steps
		Geo.mesh(_parent, Geo.box(Vector3(width, y_top - y_from + 0.05, run / steps)), mat if mat else _concrete, Vector3(x, (y_top + y_from - 0.05) / 2.0, z))
		Geo.add_box_shape(treads, Vector3(width, 0.05, run / steps), Vector3(x, y_top - 0.025, z))


## Heizkeller im Untergeschoss (Spielkonzept 7.9): Versteck des Monsters, mit allem, was früher im Keller unter dem
## Treppenhaus lag – Kisten, altes Regal, Schlüssel zu Zimmer 18, Münzen, Batterie, Zettel 2011, UV-Schrift von 1987,
## Spinnweben, alte Deko (5.7), die kaputte Kellerleuchte und ihr Schalter. Der Eingang liegt laut Plan im Norden
## (schmaler Gang zwischen zwei Kellerräumen); die Sachen stehen in der Halle an der Südwand, weg von der Tür. Dazu der
## Kohlekessel mittig an der Ostwand (Boiler) und die Rohre (_boiler_pipes).
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
	var switched := false
	for r in _map["regions"]:   # Schalter im Eingangsgang, an der Ostwand neben der Tür
		if r["kind"] == "boiler_room":
			for rc in r["rects"]:
				if float(rc[3]) <= n + 0.01:
					_switch("keller", "Heizkeller", Vector3(float(rc[2]) - 0.02, SWITCH_Y, float(rc[1]) + 1.6), -PI / 2.0)
					switched = true
	for d in _doors if not switched else []:   # ohne Eingangsgang (Plan map_a): innen an der Nordwand neben der Tür
		var p: Vector3 = d["pos"]
		if absf(p.z - n) < 0.3 and p.x > w and p.x < e:
			_switch("keller", "Heizkeller", Vector3(p.x + (d["door"] as Door).width / 2.0 + 0.35, SWITCH_Y, n + 0.02), 0.0)
			break
	Geo.solid(root, Vector3(0.7, 0.7, 0.7), Vector3(e - 0.8, 0.35, s - 0.8), _dark_wood)
	Geo.solid(root, Vector3(0.6, 0.6, 0.6), Vector3(w + 0.7, 0.3, s - 0.7), _dark_wood)
	Geo.solid(root, Vector3(0.6, 0.45, 0.6), Vector3(w + 1.45, 0.225, s - 0.6), _dark_wood)
	Geo.solid(root, Vector3(0.5, 1.6, 1.8), Vector3(w + 0.27, 0.8, c.y + 1.0), _wood)   # altes Regal
	_item(Item.Kind.KEY, Vector3(e - 0.8, 0.72, s - 0.8), "zimmer_18")
	_item(Item.Kind.COINS, Vector3(c.x + 1.5, 0.02, n + 1.2), "2")
	_item(Item.Kind.BATTERY, Vector3(w + 0.3, 1.61, c.y + 1.4))   # auf dem alten Regal
	_item(Item.Kind.MUSIC_BOX, Vector3(w + 0.28, 1.61, c.y + 0.5))   # Marions Spieluhr (5.17), daneben
	_note("2011", Vector3(w + 0.7, 0.61, s - 0.7))
	_uv_writing("31.10.1987\nSIE HABEN IHN\nEINGESCHLOSSEN", Vector3(c.x, 1.5, s - 0.01), PI)
	_resource_web(Vector3(e - 0.5, 1.7, s - 0.02), PI)
	_resource_web(Vector3(w + 1.0, 1.7, n + 0.02), 0.0)
	# Alte Halloween-Deko früherer Jahre (Spielkonzept 5.7) – im Versteck des Monsters
	var old := ResourceSpot.new().setup(Item.Kind.BROOM, "Alte Deko", OLD_DECO_SIZE, 0.0) \
		.with_pool([Item.Kind.SKULL, Item.Kind.BROOM, Item.Kind.BAT_GARLAND])
	old.position = Vector3(w + 1.45, 0.45, s - 0.6)
	old.rotation.y = PI / 2.0
	root.add_child(old)
	# Kohlekessel mittig an der Ostwand, die offene Feuerklappe zur Raummitte (Westen)
	var boiler := Boiler.new()
	boiler.position = Vector3(e - BOILER_WALL, 0, c.y)
	boiler.rotation.y = -PI / 2.0
	root.add_child(boiler)
	_boiler_pipes(hall, boiler)


## Rohre im Heizkeller (PipeKit, nur Zierde): eine Ringleitung unter der Decke an allen vier Wänden, an Stangen
## aufgehängt. Vom Stutzen des Kessels steigt ein Rohr auf und mündet per T-Stück in den Ring an der Ostwand.
## Abzweige: Süd – hinab und als Rücklauf knapp über dem Boden an Süd- und Ostwand entlang bis neben den Kessel, dort
## in den Boden; West – hinab bis Hüfthöhe, Blindkappe; Nord – Kreuzstück, hinauf durch die Decke und hinab bis zu
## einem offenen Ende (abseits von Tür, Schalter und Kellerleuchte).
func _boiler_pipes(hall: Rect2, boiler: Boiler) -> void:
	var kit := PipeKit.new(_parent)
	var y := H - PIPE_RING
	var w := hall.position.x + PIPE_WALL
	var e := hall.end.x - PIPE_WALL
	var n := hall.position.y + PIPE_WALL
	var s := hall.end.y - PIPE_WALL
	var c := hall.get_center()
	var top := boiler.position + Boiler.PIPE_TOP
	var tee_e := Vector3(e, y, top.z)
	var tee_s := Vector3(c.x + 3.5, y, s)
	var tee_w := Vector3(w, y, c.y - 4.0)
	var cross_n := Vector3(_north_pipe_x(hall), y, n)
	# Ring, an jedem Abzweig unterbrochen
	kit.run([tee_e, Vector3(e, y, s), tee_s], "joint", "joint", H)
	kit.run([tee_s, Vector3(w, y, s), tee_w], "joint", "joint", H)
	kit.run([tee_w, Vector3(w, y, n), cross_n], "joint", "joint", H)
	kit.run([cross_n, Vector3(e, y, n), tee_e], "joint", "joint", H)
	kit.tee(tee_e, Vector3.BACK, Vector3.LEFT)
	kit.tee(tee_s, Vector3.RIGHT, Vector3.DOWN)
	kit.tee(tee_w, Vector3.BACK, Vector3.DOWN)
	kit.cross(cross_n, Vector3.RIGHT, Vector3.UP)
	# Kessel: Flansch auf dem Stutzen, hinauf und hinüber in den Ring
	kit.piece("flange", top + Vector3(0, 0.025, 0), Vector3.UP, Vector3.BACK)
	kit.run([top, Vector3(top.x, y, top.z), tee_e], "", "joint")
	# Abzweige
	var back := top.z + 1.2   # Rücklauf endet südlich neben dem Kessel
	kit.run([tee_s, Vector3(tee_s.x, PIPE_LOW, s), Vector3(e, PIPE_LOW, s), Vector3(e, PIPE_LOW, back), Vector3(e, 0.0, back)],
		"joint", "", 0.0)
	kit.run([tee_w, Vector3(w, 0.9, tee_w.z)], "joint", "cap")
	kit.run([cross_n, Vector3(cross_n.x, H, n)], "joint", "")
	kit.run([cross_n, Vector3(cross_n.x, 1.3, n)], "joint", "open")


## x des Abzweigs an der Nordwand: der erste Vorschlag mit mindestens 1 m Luft zu Tür, Schalter (rechts neben der
## Tür) und kaputter Kellerleuchte (c.x − 6), sonst der mit der meisten.
func _north_pipe_x(hall: Rect2) -> float:
	var c := hall.get_center()
	var best := c.x
	var best_gap := -INF
	for x: float in [c.x + 4.5, c.x - 3.0, c.x + 1.5, c.x - 1.5]:
		var gap := absf(x - (c.x - 6.0))
		for d in _doors:
			var p: Vector3 = d["pos"]
			if absf(p.z - hall.position.y) < 0.3:
				gap = minf(gap, absf(x - p.x) - (d["door"] as Door).width / 2.0 - 0.6)
		if gap >= 1.0:
			return x
		if gap > best_gap:
			best = x
			best_gap = gap
	return best


## Wäscherei im Untergeschoss (Spielkonzept 7.9): Stehen keine Waschmaschinen im Plan („Möbel: Waschmaschine“,
## ZIM-158), an beiden Längswänden eine Reihe, das Bullauge zur Raummitte.
func _laundry_room() -> void:
	var room := _largest_rect("laundry_room")
	if not room.has_area():
		return
	if _furnishings.any(func(f: Dictionary) -> bool:
			return f["kind"] == "washing_machine" and room.has_point((f["rect"] as Rect2).get_center())):
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
			var rect := _rect(rc)
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
	_corridor_zones("%s")
	for level in range(1, _top_level + 1):
		_on_floor(level, _upper_zones)
	_on_floor(_lower, _lower_zones)
	for no in rooms:
		var info: Dictionary = rooms[no]
		zones.append({"name": "Zimmer " + String(info["sign"]), "center": info["center"], "radius": 3.2})
	spawn_points = [
		cellar_center() + Vector3(0, 0.05, 0),                             # Heizkeller – das Versteck des Monsters
		(rooms["017"]["center"] as Vector3) + Vector3(0, 0.05, 0),        # verlassenes Zimmer
		garden_spots[0] + Vector3(0, 0.05, -12.0),                         # Garten
	]


## Zonen eines oberen Stockwerks (Plan geladen): Katzenraum, Bibliothek, Büro der Direktion, Sekretariat und die Flure.
func _upper_zones() -> void:
	for r in _map["regions"]:
		var kind := String(r["kind"])
		if kind in ["cat_room", "library", "office", "secretariat"]:
			var b := _bounds(r["rects"])
			zones.append({"name": KIND_NAMES[kind], "center": Vector3(b.get_center().x, _base_y, b.get_center().y),
				"radius": minf(b.size.x, b.size.y) / 2.0 + 0.5})
	_corridor_zones("%s (oben)")


## Flurabschnitte des geladenen Stockwerks als Kette von Kreisen (lange Flure); name = Format für den Namen.
func _corridor_zones(name: String) -> void:
	for c in _map["corridors"]:
		var a := _v2(c["a"])
		var b := _v2(c["b"])
		var n := maxi(1, ceili(a.distance_to(b) / 12.0))
		for i in n:
			var p := a.lerp(b, (i + 0.5) / n)
			zones.append({"name": name % c["name"], "center": Vector3(p.x, _base_y, p.y), "radius": a.distance_to(b) / n / 2.0 + 1.0})


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
## Kette von Kreisen je Planrechteck („Keller“).
func _lower_zones() -> void:
	var seen := {}   # je Art ein Kreis, auch wenn der Plan sie auf mehrere Flächen verteilt
	for r in _map["regions"]:
		var kind := String(r["kind"])
		if kind in ["boiler_room", "plant_room", "laundry_room"] and not seen.has(kind):
			seen[kind] = true
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
	var seen := {}
	for r in _map["regions"]:
		var kind := String(r["kind"])
		if kind in ["plant_room", "laundry_room"] and not seen.has(kind):
			seen[kind] = true
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
## Rasen (Fläche „Garten“ im EG, auch unter Bäumen) an der Stelle p (x, z)? Für die Grasbüschel (Grass).
func is_lawn(p: Vector2) -> bool:
	var place := _place_at(p)
	return not place.is_empty() and place["kind"] == "garden"


func room_at(p: Vector3) -> String:
	var level := _level_of(p.y)
	if level < 0:
		return ""
	return _on_floor(level, func() -> String: return _room_id_at(Vector2(p.x, p.z)))


## Raum an p, wie ihn Lampen und Schalter kennen (LightSwitch.room_id): Das Bad schaltet für sich, Umkleiden und
## Duschen teilen sich einen Schalter. Leer draußen und auf Treppenpodesten.
func light_room_at(p: Vector3) -> String:
	var level := _level_of(p.y)
	if level < 0:
		return ""
	return _on_floor(level, func() -> String: return _light_room_at(Vector2(p.x, p.z)))


## Wie room_at, nur zählt ein Bad zu dem Zimmer hinter seiner Tür.
func home_room_at(p: Vector3) -> String:
	return home_of(room_at(p))


## Raum-ID → das Zimmer, zu dem sie gehört (ein Bad zum Zimmer davor, sonst sie selbst).
func home_of(id: String) -> String:
	return String(_bath_owner.get(id, id))


## Ist p draußen (Garten, Innenhof, Terrasse, Balkon)?
func is_outdoor(p: Vector3) -> bool:
	var level := _level_of(p.y)
	if level < 0:
		return false
	return _on_floor(level, func() -> bool:
		var place := _place_at(Vector2(p.x, p.z))
		return not place.is_empty() and String(place["kind"]) in ["garden", "gravel", "terrace", "balcony"])


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
func _wall_x(z: float, x0: float, x1: float, openings: Array, mat: Material, height: float = H, faces := {},
		split := 0.0) -> void:
	var holder := Node3D.new()
	holder.position = Vector3(0, 0, z)
	_parent.add_child(holder)
	_wall(holder, x0, x1, openings, mat, height, faces, split)


## Wand entlang Z bei x. Öffnungen als Vector4(Mitte z, Breite, Oberkante, Unterkante).
func _wall_z(x: float, z0: float, z1: float, openings: Array, mat: Material, height: float = H, faces := {},
		split := 0.0) -> void:
	var holder := Node3D.new()
	holder.position = Vector3(x, 0, 0)
	holder.rotation.y = -PI / 2.0   # lokale +X zeigt entlang +Z, lokale +Z nach Westen
	_parent.add_child(holder)
	_wall(holder, z0, z1, openings, mat, height, faces, split)


## Wand im lokalen Rahmen von holder (entlang X von a0 bis a1): Kollision als Kästen wie gehabt
## (links, unter und über jeder Öffnung, rechts), die Optik als ein Mesh mit gemeinsamen Ecken (Geo.wall_mesh).
## Laibungen in Rahmenholz: Rutscht die Zarge weg, blitzt Holz statt Tapete durch
## (nur der Beton im Keller hat keinen Rahmen). faces: eigene Materialien der Wandflächen nach Flächenname
## (Geo.wall_mesh mit sides, lokal „plus“ = +Z) – Fliesen, Fassade, Beton auf der Wand selbst; mat gilt dann nur
## für Oberkante und Stirnseiten.
func _wall(holder: Node3D, a0: float, a1: float, openings: Array, mat: Material, height: float, faces := {},
		split := 0.0) -> void:
	var cursor := a0
	for o in openings:
		var op: Vector4 = o
		var a := op.x - op.y / 2.0
		if a > cursor:
			_wall_box(holder, cursor, a, 0.0, height)
		if op.w > 0.0:
			_wall_box(holder, a, op.x + op.y / 2.0, 0.0, op.w)
		if op.z < height:
			_wall_box(holder, a, op.x + op.y / 2.0, op.z, height)
		cursor = op.x + op.y / 2.0
	if a1 > cursor:
		_wall_box(holder, cursor, a1, 0.0, height)
	var trim := mat if mat == _concrete else OpeningFrame.trim_material()
	if not faces.is_empty():
		var sided := _cap_top(Geo.wall_mesh(a0, a1, height, T, openings + _top_breaks(a0, a1, height), true, split))
		var parts := Geo.mesh(holder, sided, null, Vector3.ZERO)
		for i in sided.get_surface_count():
			var name := sided.surface_get_name(i)
			parts.set_surface_override_material(i, faces.get(name, trim if name == "reveals" else mat))
		structure_parts.append(parts)
		return
	var wall := Geo.mesh(holder, _cap_top(Geo.wall_mesh(a0, a1, height, T, openings + _top_breaks(a0, a1, height))), null, Vector3.ZERO)
	wall.set_surface_override_material(0, mat)
	structure_parts.append(wall)   # hält das Licht aller Lampen auf (ShadowBudget.merge)
	if wall.mesh.get_surface_count() > 1:
		wall.set_surface_override_material(1, trim)


## Kollisionskasten eines Wandstücks von a bis b (entlang der Wand) und y0 bis y1 – im Dachgeschoss nur so hoch, wie die
## Wand unter der Schräge reicht (höchster Punkt im Stück).
func _wall_box(holder: Node3D, a: float, b: float, y0: float, y1: float) -> void:
	if _wall_top.is_valid():
		var top := 0.0
		var n := maxi(1, ceili((b - a) / GRID))
		for i in n + 1:
			top = maxf(top, _wall_top.call(lerpf(a, b, float(i) / n)))
		y1 = minf(y1, top)
	if y1 - y0 > 0.001:
		Geo.collider(holder, Vector3(b - a, y1 - y0, T), Vector3((a + b) / 2.0, (y0 + y1) / 2.0, 0))


## Dachgeschoss: Stützstellen für die Oberkante unter der Schräge – Öffnungen ohne Breite alle GRID m, wo _wall_top
## unter height liegt (Geo.wall_mesh legt dort Rasterlinien, _cap_top zieht deren Ecken herab).
func _top_breaks(a0: float, a1: float, height: float) -> Array:
	var out := []
	if not _wall_top.is_valid():
		return out
	var n := maxi(1, ceili((a1 - a0) / GRID))
	for i in range(1, n):
		var x := lerpf(a0, a1, float(i) / n)
		if _wall_top.call(x) < height - 0.001 or _wall_top.call(lerpf(a0, a1, float(i - 1) / n)) < height - 0.001 \
				or _wall_top.call(lerpf(a0, a1, float(i + 1) / n)) < height - 0.001:
			out.append(Vector4(x, 0.0, height, height))
	return out


## Dachgeschoss: Ecken eines Wand-Meshs (lokal x entlang der Wand) auf die Oberkante _wall_top herabziehen.
func _cap_top(m: ArrayMesh) -> ArrayMesh:
	if not _wall_top.is_valid():
		return m
	var out := ArrayMesh.new()
	for i in m.get_surface_count():
		var arrays := m.surface_get_arrays(i)
		var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		for k in verts.size():
			verts[k].y = minf(verts[k].y, _wall_top.call(verts[k].x))
		arrays[Mesh.ARRAY_VERTEX] = verts
		out.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		out.surface_set_name(i, m.surface_get_name(i))
	return out


## Feste Kerze als Deko-Licht (kein Gegenstand, FixedCandle): brennt, bis jemand sie ausbläst, flackert leicht und in
## Monsternähe.
## Kerzen und Kürbisse sind die hellsten Lichter im Haus (Spielkonzept 7.3).
func _candle(pos: Vector3) -> void:
	var candle := FixedCandle.new().setup(CANDLE_ENERGY)   # auspusten, anzünden, gespeichert (Spielkonzept 5.12)
	candle.position = pos
	_parent.add_child(candle)


## Wandleuchte; yaw dreht die lokale +Z-Achse (von der Wand weg) in den Raum.
func _wall_lamp(pos: Vector3, yaw: float, energy: float, light_range: float, room_id: String, broken: bool = false) -> void:
	var lamp := Lamp.new().setup(Lamp.Style.WALL, room_id, energy, light_range, broken)
	lamp.fixed = room_id in ALWAYS_LIT
	lamp.position = pos
	lamp.rotation.y = yaw
	_parent.add_child(lamp)


## Schreibtischlampe bei p auf dem Möbel darunter, der Schirm zum Sitzplatz davor (_seat_yaw): an der Ecke schräg
## zur Mitte, mittig gerade nach vorn; hat das Möbel keine Vorderseite, steht sie wie das Telefon (_upright_yaw).
## Dazu ein paar Grad fester Versatz aus der Lage (_jitter), damit sie hingestellt wirkt.
func _desk_lamp(p: Vector2, room_id: String, broken: bool) -> void:
	var lamp := Lamp.new().setup(Lamp.Style.DESK, room_id, DESK_LAMP_ENERGY, DESK_LAMP_RANGE, broken)
	lamp.fixed = room_id in ALWAYS_LIT
	lamp.position = Vector3(p.x, _top_at(p), p.y)
	var yaw := _seat_yaw(p, DESK_LAMP_MAX_TURN)
	lamp.rotation.y = (_upright_yaw(p) if is_nan(yaw) else yaw) \
		+ _jitter(Rect2(p, Vector2.ZERO)).randf_range(-DESK_LAMP_JITTER, DESK_LAMP_JITTER)
	_parent.add_child(lamp)


## Blickrichtung für etwas bei p auf dem obersten Möbel darunter: zum Sitzplatz SEAT_REACH vor der Mitte seiner
## Vorderkante, höchstens max_turn neben der Vorderseite. NAN, wenn dort kein Möbel mit Vorderseite steht.
func _seat_yaw(p: Vector2, max_turn: float) -> float:
	var best := {}
	for f in _furnishings:
		if (f["front"] as Vector2) != Vector2.ZERO and (f["rect"] as Rect2).grow(0.05).has_point(p) \
				and (best.is_empty() or float(f["top"]) > float(best["top"])):
			best = f
	if best.is_empty():
		return NAN
	var rect: Rect2 = best["rect"]
	var front: Vector2 = best["front"]
	var seat := rect.get_center() + front * (absf(front.dot(rect.size)) / 2.0 + SEAT_REACH)
	var turn := clampf(front.angle_to(seat - p), -max_turn, max_turn)
	var dir := front.rotated(turn)
	return atan2(dir.x, dir.y)


## Deckenleuchte bei p (Spielkonzept 7.3): runde Kupferleuchte bündig an der Decke (Lamp.Style.FLUSH), über dem
## Luftraum (open_above) als Pendel an einer Schnur von der oberen Decke herab (Lamp.Style.CEILING).
func _ceiling_lamp(p: Vector2, room_id: String, broken: bool) -> void:
	var y := H
	var style := Lamp.Style.FLUSH
	for rc in _map["open_above"]:
		if _rect(rc).has_point(p):
			var top := UP_Y + H
			y = PENDANT_Y
			style = Lamp.Style.CEILING
			Geo.mesh(_parent, Geo.cylinder(0.01, top - y, 4), Mat.psx(Color(0.2, 0.18, 0.16)), Vector3(p.x, (top + y) / 2.0, p.y))
	var lamp := Lamp.new().setup(style, room_id, CEILING_LAMP_ENERGY, CEILING_LAMP_RANGE, broken)
	lamp.fixed = room_id in ALWAYS_LIT
	lamp.position = Vector3(p.x, y, p.y)
	_parent.add_child(lamp)


## Halogenleuchte (Spielkonzept 7.9): Röhre der Länge length entlang axis („x“/„z“) bündig unter der Decke,
## kaltweiß, flackert ab und zu von selbst kurz auf (Lamp.Style.HALOGEN).
func _halogen(p: Vector2, axis: String, length: float, room_id: String, broken: bool) -> void:
	var lamp := Lamp.new().setup(Lamp.Style.HALOGEN, room_id, HALOGEN_ENERGY, HALOGEN_RANGE, broken)
	lamp.length = length
	lamp.position = Vector3(p.x, H - 0.03, p.y)
	if axis == "z":
		lamp.rotation.y = PI / 2.0   # die Röhre liegt lokal entlang X
	_parent.add_child(lamp)


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


## Lichtschalter für die Lichtgruppe room_id (_light_room_at). Bäder sind anfangs dunkel – niemand ist darin.
func _switch(room_id: String, label: String, pos: Vector3, yaw: float) -> LightSwitch:
	var sw := LightSwitch.new().setup(room_id, label)
	sw.position = pos
	sw.rotation.y = yaw
	_parent.add_child(sw)
	if _bath_owner.has(room_id):
		sw.set_on.call_deferred(false, true)
	return sw


func _hide_spot(type: HideSpot.Type, pos: Vector3, yaw: float, bed_size := Vector2.ZERO) -> HideSpot:
	var spot := HideSpot.new().setup(type)
	if bed_size != Vector2.ZERO:
		spot.bed_size = bed_size
	spot.position = pos
	spot.rotation.y = yaw
	_parent.add_child(spot)
	return spot


## Rezeption aus `RECEPTION_MODEL` über die Rechtecke des Plans (U aus Front und zwei Armen): mittig in ihrer
## Hülle, die Kundenseite zur Front hin gedreht. Platte = Säulenstein, Rohre = Messing der Treppe, Holz und Sockel
## mit den Texturen des Modells. Kollision (auch fürs NavMesh) aus dem Netz selbst, damit die runden Ecken stimmen.
## null, wenn das Modell fehlt oder der Plan keine Rezeption hat.
func _reception(rects: Array[Rect2]) -> StaticBody3D:
	if rects.is_empty() or not ResourceLoader.exists(RECEPTION_MODEL):
		return null
	var hull := rects[0]
	var front := rects[0]
	for r in rects:
		hull = hull.merge(r)
		if r.size.x * r.size.y > front.size.x * front.size.y:
			front = r
	var to_front := front.get_center() - hull.get_center()
	var body := StaticBody3D.new()
	body.collision_mask = 0
	body.position = Vector3(hull.get_center().x, 0, hull.get_center().y)
	body.rotation.y = atan2(to_front.x, to_front.y)   # +Z des Modells zur Front
	root.add_child(body)
	var model: Node3D = (load(RECEPTION_MODEL) as PackedScene).instantiate()
	body.add_child(model)
	for m: MeshInstance3D in model.find_children("*", "MeshInstance3D", true, false):
		for s in m.mesh.get_surface_count():
			var mat: Material
			var src := m.mesh.surface_get_material(s)
			match src.resource_name if src else "":
				"stone":
					mat = _pillar_stone
				"gold":
					mat = Mat.metal(GrandStair.BRASS)
				_:
					mat = Mat.model(RECEPTION_MODEL, m, s)
			m.set_surface_override_material(s, mat)
		var shape := CollisionShape3D.new()
		shape.shape = m.mesh.create_trimesh_shape()
		shape.transform = model.transform * m.transform
		body.add_child(shape)
	return body


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
	Seat.attach(body, "sofa", 0.45, Vector3(0.02, 0, 0), Vector3.RIGHT, 2.0, 0.3 + SEAT_CLEAR)   # zwischen den Armlehnen
	return body


## Parkbank (`assets/models/bench.glb`) mit der Länge aus dem Plan, gleichmäßig skaliert; Sitzseite nach +Z.
func _bench(length: float) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.collision_mask = 0
	var s := length / BENCH_LENGTH
	var model: Node3D = (load(BENCH_MODEL) as PackedScene).instantiate()
	model.scale = Vector3.ONE * s
	body.add_child(model)
	for m: MeshInstance3D in model.find_children("*", "MeshInstance3D", true, false):
		for i in m.mesh.get_surface_count():
			m.set_surface_override_material(i, Mat.model(BENCH_MODEL, m, i))
	# Kollision (auch für das NavMesh): Sitzblock und Lehne, Maße aus tools/build_bench.py
	Geo.add_box_shape(body, Vector3(1.6, BENCH_SEAT, 0.47) * s, Vector3(0, BENCH_SEAT / 2.0, 0.085) * s)
	Geo.add_box_shape(body, Vector3(1.6, 0.365, 0.11) * s, Vector3(0, 0.66, -0.18) * s)
	Seat.attach(body, "bank", BENCH_SEAT * s, Vector3(0, 0, 0.06 * s), Vector3.BACK, 1.5 * s, 0.26 * s + SEAT_CLEAR)
	return body


## Zimmertisch, zu dem ein Stuhl an p gehört (leeres Rechteck = keiner oder das Modell fehlt).
func _room_table_at(p: Vector2) -> Rect2:
	if not ResourceLoader.exists(ROOM_TABLE_MODEL):
		return Rect2()
	for f in _map["furniture"]:
		if f["kind"] == "room_table":
			var r := _rect(f["rect"])
			if r.grow(ROOM_CHAIR_REACH).has_point(p):
				return r
	return Rect2()


## Tischgruppe (`assets/models/room_table.glb`): Tisch so groß wie im Plan, zwei Stühle einander gegenüber. Die
## Achse nimmt sie von einem Paar gegenüberstehender Stühle im Plan, sonst Ost–West. Jeder Stuhl ist ein eigener
## Körper mit Sitzblock und Lehne; der Tisch ein voller Quader (für das NavMesh wie bisher).
func _room_table(rect: Rect2) -> StaticBody3D:
	var axis := Vector2(1, 0)
	var seen: Array[Vector2] = []
	for f in _map["furniture"]:
		if f["kind"] != "chair" or _room_table_at(_rect(f["rect"]).get_center()) != rect:
			continue
		var d := _dir(String(f.get("facing", "")))
		if seen.any(func(o: Vector2) -> bool: return o.dot(d) < -0.9):
			axis = d.abs()
			break
		seen.append(d)
	var body := StaticBody3D.new()
	body.collision_mask = 0
	var s := rect.size.x / ROOM_TABLE_SIDE
	var model: Node3D = (load(ROOM_TABLE_MODEL) as PackedScene).instantiate()
	var table: MeshInstance3D = model.get_node("table")
	var chair: MeshInstance3D = model.get_node("chair")
	model.remove_child(chair)
	chair.owner = null   # wird umgehängt
	model.scale = Vector3(s, 1.0, rect.size.y / ROOM_TABLE_SIDE)
	body.add_child(model)
	table.material_override = Mat.model(ROOM_TABLE_MODEL, table)
	Geo.add_box_shape(body, Vector3(rect.size.x, BOX_HEIGHTS["room_table"], rect.size.y), Vector3(0, BOX_HEIGHTS["room_table"] / 2.0, 0))
	for side: float in [-1.0, 1.0]:
		var out := axis * side
		var seat := StaticBody3D.new()
		seat.collision_mask = 0
		seat.position = Vector3(out.x, 0, out.y) * (ROOM_CHAIR_GAP * s)
		seat.rotation.y = atan2(-out.x, -out.y)   # zum Tisch
		body.add_child(seat)
		var c := chair if side > 0 else chair.duplicate() as MeshInstance3D
		c.transform = Transform3D.IDENTITY
		seat.add_child(c)
		c.material_override = Mat.model(ROOM_TABLE_MODEL, c)
		Geo.add_box_shape(seat, ROOM_CHAIR, Vector3(0, ROOM_CHAIR.y / 2.0, 0))
		Geo.add_box_shape(seat, Vector3(ROOM_CHAIR.x, ROOM_CHAIR_H - ROOM_CHAIR.y, 0.07), Vector3(0, (ROOM_CHAIR_H + ROOM_CHAIR.y) / 2.0, -0.18))
		Seat.attach(seat, "stuhl", ROOM_CHAIR.y, Vector3(0, 0, 0.02), Vector3.BACK, ROOM_CHAIR.x, ROOM_CHAIR.z / 2.0 + SEAT_CLEAR)
	return body


## Spinnweben, die man abnehmen kann (lokale +Z zeigt in den Raum, yaw im Bogenmaß).
func _resource_web(pos: Vector3, yaw: float) -> void:
	var spot := ResourceSpot.new().setup(Item.Kind.COBWEB, "Spinnenweben", 1, 240.0)
	spot.position = pos
	spot.rotation.y = yaw
	_parent.add_child(spot)


## Gegenstände liegen in der Hauptszene – pos im Rahmen des aktuellen Bauteils.
func _item(kind: Item.Kind, pos: Vector3, extra: String = "") -> void:
	var item := Item.create(kind, extra)
	item.position = _global(pos)
	world.add_child(item)


func _global(local: Vector3) -> Vector3:
	return _parent.global_transform * local
