extends Node3D
## Prototyp „Zimmer 13“ – baut Umgebung, Level, Spieler, Monster und UI zusammen.
## Wird vom Titelbildschirm gestartet: neues Spiel (Game.new_game_slot) oder Laden
## eines Spielstands (Game.pending_load → SaveManager.apply nach dem Aufbau).
##
## Debug-Startparameter (nach „--“ an Godot übergeben; ohne Titelbildschirm). Im Spiel dieselben Befehle
## ohne „--“ in der Debug-Konsole ([^]/F1, DebugConsole) – ausgeführt von run_debug():
##   --load=n                    Spielstand n laden (0 = Autosave; TitleScreen)
##   --new=n                     neues Spiel in Slot n (TitleScreen)
##   --savetest                  Speichern → Laden → Vergleichen (Ausgabe in der Konsole)
##   --diary=n                   nach 2 s wie am Tagebuch in Slot n speichern
##   --day=n                     zu Tag n im Oktober springen (15 Uhr)
##   --uhr=hh[:mm]               Uhrzeit am aktuellen Tag stellen (2.4; am 1. Oktober frühestens 15 Uhr) – nach --day
##   --attacks=n                 so viele Angriffe gab es schon (> 9: nicht mehr harmlos, ob es holt, entscheidet die Tageskurve; sicher mit --intent)
##   --siegerehrung[=ohne]       Siegerehrung des Türschmuck-Wettbewerbs (2.5) sofort: Uhr auf den 2. Oktober 20 Uhr, die
##                               Gäste stehen schon um die Puppe, du vor ihr – gleich steht sie auf, dann der erste
##                               Angriff: Gustav Peters wird ungesehen geholt (ohne: du bleibst, wo du bist, die Uhr
##                               springt auf 22 Uhr, es geschieht ohne dich)
##   --grinch[=tot]              vor Zimmer 020, Gustav Peters (der „Halloween-Grinch“, 2.6) steht daneben – tot: er ist
##                               schon geholt, die Tür offen, Schleifspur und sein Tagebuch auf dem Tisch
##   --brett[=nachher]           vor das Aushangbrett in der Lobby (2.5) – nachher: der erste Angriff gilt als geschehen
##   --brief                     an den Schreibtisch in Zimmer 13, Blick auf den Willkommensbrief (2.5)
##   --notizbuch                 Notizbuch mit Beispielen (Aufgaben: offen, erledigt, zu spät, Auftraggeber tot; Notizen
##                               über drei Tage) und ein paar Einträge im Tagebuch zum Nachlesen (3.10)
##   --gesehen                   Notizbuch einstecken, alle drei Bedrohungen gelten als gesehen (Lesezeichen „Gesehen“, 3.10) –
##                               mit --show=gesehen gleich aufgeschlagen
##   --tot[=monster|geist|kuerbis]   nach 1 s gestorben: Sterbebildschirm mit dem Porträt dessen, der dich geholt hat (8.7)
##   --zettel                    erster Angriff gilt als geschehen, der Warnungszettel von 1999 liegt hinter der Tür von
##                               Zimmer 13, du stehst davor (2.5)
##   --knock [--knock-fake] [--answer]   Klopfen an Zimmer 13 (falsche Stimme / Tür öffnen)
##   --prank=art[,zimmer]        Streich (6.13): das erste Kind mit Eltern steht vor der Tür (Standard Zimmer 13) und
##                               spielt ihn – leaves, topple (Kürbis steht daneben), pumpkin, candle (steht damit in der Hand
##                               2 m davor und wirft), fire (brennende Kerze, daneben Laub und Lakengespenst, 5.11)
##   --trick=13[,n]              ein Kind steht vor Zimmer 13 (Tür auf) und will Süßes; ,n: du gibst ihm n Süßigkeiten (je 1,5 s)
##   --trick[=kind]              Süßes oder Saures von Tür zu Tür (6.13): ein Kind (oder dieses) zieht sofort los und
##                               klopft an die nächsten Gästetüren (mit --trace: Türen, Süßes oder Saures)
##   --decorate[=gast][,hin]     Schmück-Aktion sofort (5.9): ein Gast (oder dieser) ruft auf, Gäste aus der Nähe holen
##                               Deko und hängen sie an eine Tür bzw. in den Flur · hin: du stehst davor (mit --trace:
##                               Stelle, Mitmacher, jedes Stück, Ende) · sonst Anruf in Zimmer 13, mit --answer nach 4 s abnehmen
##   --decorate=lobby[,gast][,hin]   Schmück-Aktion in der Lobby
##   --decorate=allein[,gast][,lobby][,hin]   ein Gast holt allein Deko aus einer Kiste und hängt sie in seinem Zimmer
##                               auf (lobby: aus dem Koffer in die Lobby; haus: irgendwohin ins Hotel, wo wenig hängt)
##   --decorate=gross[,gast][,lobby][,hin]   großes Schmücken (2026-10-21): 10–20 Gäste, mehrere Stellen eines
##                               Flurbereichs (bzw. der Lobby), jeder mit einem Armvoll Deko
##   --decorate=hier[,gast]      wie „Lass uns hier schmücken!“ im Gespräch: geschmückt wird, wo du stehst (mit --tp/--pos)
##   --search[=gast][,mit]       Deko-Suche (5.9): ein Gast (oder dieser) zieht los · mit: du gehst mit (er führt, du
##                               folgst ihm von selbst, er teilt am Fundort) – mit --trace: Fundort, Teilen, Beziehung
##   --cook=gast[,id]            ein Gast (oder dieser) kocht gleich Kürbissuppe (er steht 4 m vor dem Herd, du daneben)
##   --cook=suppe|braten[,fertig]  Kochen (3.8): Kürbis liegt geschnitten im Topf bzw. in der Pfanne, du stehst am Herd ·
##                               fertig: gleich fertig (Suppe: Gäste kommen zum Essen)
##   --kaffee=n                  n Tassen Kaffee getrunken (3.11; ab der 3. zittert man) – mit --awake=n wird die Sicht klarer
##   --kaffee=maschine           du stehst vor der Kaffeemaschine in der Küche, die Tasse ist in 1 s fertig
##   --kaffee=gast[,id]          ein Gast (oder dieser) holt sich gleich Kaffee an der Maschine (er steht 4 m davor, du daneben)
##   --tee=n|kocher|gast[,id]    Tee (3.12) wie --kaffee: n Tassen getrunken · vor dem Wasserkocher, gleich fertig · ein Gast
##                               (ohne id ein Kind) holt sich Tee
##   --mess[=wachs]              Kürbismatsch (bzw. großer Wachsfleck) 3 m vor dir, ein ordentlicher Gast hinter dir putzt ihn weg
##                               (6.13; --trace „[Flecken]“)
##   --rival=gast1,gast2         gast1 und gast2 sind verfeindet, du wirst gleich mit gast1 befreundet – gast2 steht vor dir und
##                               erfährt es nach 20–60 s (--trace „[Feinde]“)
##   --pals=gast1,gast2          Weitererzählen (6.16): gast1 ist mit dir befreundet, beide sind Freunde und stehen vor dir
##                               nebeneinander – gast1 erzählt gast2 gleich Gutes über dich (mit --trace: Beziehung)
##   --call=id|creepy|dead|door [--answer]  Telefon in Zimmer 13 klingelt (Gast, Atmen, Verschwundener,
##                               vor der Tür) – mit --answer nimmt der Spieler nach 4 s ab
##   --dial=n|lobby              vom Telefon in Zimmer 13 aus Zimmer n anrufen (0 = Rezeption) ·
##                               lobby: Wählseite am Haupttelefon mit Gästeverzeichnis
##   --menu=name                 nach 1 s ein Menü öffnen (pause, diary, diary_pages, settings, load, help, achievements)
##   --erfolg=id|alle            Erfolg (8.11) freischalten und einblenden, z. B. --erfolg=chess – alle: alle still (für
##                               --menu=achievements); in Debug-Starts nur für die Sitzung, nichts wird gespeichert
##   --erfolge-zurueck           alle Erfolge im Profil (user://achievements.cfg) löschen
##   --title                     trotz Parametern mit dem Titelbildschirm starten · --title --splash: samt Vorspann (Logo)
##   --pos=x,y,z[,blickwinkel[,neigung]]   Spieler versetzen (Neigung in Grad, positiv = nach oben)
##   --tp=ort|zimmer|gast        hinspringen: Ort der F6-Liste (lobby, partyraum, keller, obergeschoss, katzenraum …), jedes Zimmer (Nummer oder Türschild, auch oben und verschlossene), vor einen Gast
##   --time=+n|-n                Spieltage vor- oder zurückspulen
##   --rot[=welk|eingefallen]    alle Kürbisse 10 s vor welk (5.10) – bzw. gleich welk oder eingefallen
##   --verwaschen[=schleier]     es regnet sofort, Blut, Wachs und Kürbismatsch draußen verlaufen zehnmal so schnell (4.13,
##                               RainVeil) – schleier: sofort ganz; z. B. mit
##                               --pos=45,0.1,-37 --fall=5,giant --verwaschen --trace
##   --aufzug[=innen|offen|fahrt]   vor den fahrenden Aufzug (7.4) an den Halt stellen, wo die Kabine steht (innen: in der
##                               Kabine mit Blick aufs Bedienfeld · offen: die Tür geht gleich auf · fahrt: in der Kabine, sie
##                               fährt gleich ins oberste Stockwerk)
##   --sitzen[=sofa|bank|stuhl|bett|klo]   aufs nächste Sitzmöbel dieser Art setzen (3.1), erster Platz – ohne Angabe Sofa
##   --tuer=zimmer               vor die Tür dieses Zimmers stellen (Nummer wie am Schild), Blick auf die Tür (6.19)
##   --werkzeug=brecheisen|kasten|schluessel   Brecheisen bzw. Werkzeugkasten in die Hand, schluessel: Generalschlüssel
##                               an den Bund (6.19) – mit --tuer davor: nach 1 s [E] an der Tür (aufbrechen, reparieren,
##                               aufschließen)
##   --klopfen[=zimmer[,weg]]    vor die Tür eines Gästezimmers (Nummer wie am Schild, ohne Angabe das nächste bewohnte)
##                               und nach 1 s klopfen (6.19); weg = ehrlich|lampe|geschenk|panik|geld wählt die
##                               Antwort im Türgespräch gleich selbst – mit --trace Chance und Ausgang
##   --attic-door                Kniestocktür zum Ansehen (4.21): du stehst im Dachboden vor ihrer Bandseite (ohne Dachgeschoss
##                               im Plan wird beim Aufbau die erste 0,8 m breite Tür im OG1 zur Dachbodentür)
##   --dachboden[=kopf|fenster|treppe|blitz]  ins Dachgeschoss (4.21): hinter die Kniestocktür, Blick in die Kammer · kopf: vor
##                               den Kopf des Kürbismanns · fenster: unter das Dachfenster, durch das der Mond scheint, Blick hinauf
##                               · treppe: im OG1 an den Fuß der Dachbodentreppe · blitz: in die Kammer, Gewitter, nach 3 s
##                               ein Blitz, der dich sicher um 90° dreht (Spuk, --shot-on=attic_turn)
##   --load-slot=n               Spielstand n laden, auch mitten im Spiel (Konsole: load n; save n = --diary=n)
##   --console[=befehl;befehl]   Debug-Konsole nach 1 s öffnen und Befehle eintippen (für Screenshots)
##   --monster=x,y,z             Monster sofort an dieser Stelle zeigen
##   --lure                      nach 1 s kommt das Monster zu dir (wie F7; ruht es, erscheint es ~25 m entfernt)
##   --splash=x,z                nach 1 s platscht es dort im Pool (Wellenring, Schaum, Spritzer)
##   --pool=still|tremor|slosh   Poolwasser so, als wäre das Monster nah: glatt · zitternde Ringe · schwappt (off = wieder normal)
##   --pocket                    Kompass, alle Kartenblätter und Schlüssel 18 einstecken
##   --flashlight[=uv]           eingeschaltete Taschenlampe mit voller Batterie in die Hand (uv: mit UV-Aufsatz, im UV-Modus)
##   --bag[=a,b,…]               Kleines in die Tasche (3.2): süßes, cola, limo, zierkürbis, kerze, messer, batterie, birne,
##                               uv, würfel, becher, streichhölzer (5.12) – ohne Angabe Süßigkeiten, Cola, Zierkürbis und
##                               Batterie
##   --bag-menu[=n]              Tasche offen halten wie mit gehaltenem [Q], Fach n (1–6) gewählt – für Screenshots
##   --deco=art[,g]              Deko in die Hand (5.6, 5.7): gespenst, lichter, netz, laub, zierkürbis, fledermaus,
##                               spinne, totenkopf, besen, kerze (brennend, 5.12) – an eine Wand sehen
##                               und [G] zum Aufhängen bzw. Verstreuen · ,g: nach 1 s selbst [G] (mit --pos auf eine Wand)
##   --fall[=h[,sorte]]          Kürbis fällt 1,5 m vor dir aus h m Höhe (Standard 4) – ab 3 m zerplatzt er zu Kürbismatsch
##                               (5.8); Sorte aus PumpkinKinds oder „mini“ (Zierkürbis), z. B. --fall=5,giant; mit
##                               --time=+2 danach ist der Matsch verblasst und weg · „kerze“ bzw. „birne“: eine brennende
##                               Kerze (zerbricht ab 2 m) bzw. Glühbirne (platzt ab 1,5 m), z. B. --fall=3,birne
##   --wurf[=k[,gegenstand]]     Werfen (3.13): nach 1 s einen Gegenstand in die Hand und mit Kraft k (0 … 1, Standard 1)
##                               in Blickrichtung werfen – Standard ein Kürbis; Sorte aus PumpkinKinds, mini, kerze, birne,
##                               kaffee, tee, dose, messer, taschenlampe; z. B. --pos=…,blick,neigung --wurf=0.6,kerze
##   --kuerbis[=n]               Kürbismodelle (5.8) 1,5 m vor dir, Gesicht zu dir, Blick hinunter: der glatte und die fünf
##                               Fratzen mit Kerze in einer Reihe – bzw. nur Fratze n (1–5)
##   --kerzen[=nah]              Kerzenmodelle 0,8 m vor dir, Blick hinunter: Kerze brennend und aus (Gegenstand), rot und weiß
##                               brennend auf dem Teller · nah: weiß auf dem Teller 30 cm vor dem Auge, Flamme auf Augenhöhe,
##                               rot daneben (für Nahaufnahmen der Flamme)
##   --show=map|keys|compass     Karte (bzw. Schlüsselblatt) oder Kompass hervorholen (wie Tab/F halten); aufgaben|notizen|
##                               gesehen: das Notizbuch bei diesem Lesezeichen (3.10)
##   --sprint · --winded         vorwärts rennen, bis die Ausdauer leer ist · gleich außer Atem starten (3.1) –
##                               mit --trace stehen „außer Atem“ und „beruhigt“ in der Konsole
##   --no-psx · --psx            ohne bzw. mit PS1-Look (wie der Schalter in den Einstellungen, wird nicht gespeichert)
##   --fps                       Bilder pro Sekunde einblenden (wie F10)
##   --nohud                     HUD ausblenden (Geld, Hinweise, Fadenkreuz) – für Screenshots
##   --debug                     Debug-Werte einblenden
##   --nointro                   ohne den Gedanken an den Brief beim Start (2.5)
##   --figur[=schnell]           Erwachen am Waschbecken und Charaktererstellung (3.9) wie bei einem neuen Spiel –
##                               schnell: gleich der Bogen vor dem Spiegel (ohne --figur: Standardfigur)
##   --perf[=s]                  Frame-Zeiten nach temp/perf.csv schreiben, nach s Sekunden (Standard 20) beenden (PerfLog)
##   --static-eg[=pfad]          Erdgeschoss als statische Szene speichern (StaticExport, Standard res://temp/eg_static.scn):
##                               Wände mit Öffnungen, Böden, Decken, Lampen, zum Durchlaufen – als Startparameter danach beenden
##   --trace                     Monster-Zustand alle 2 s und jedes Lärmereignis in die Konsole schreiben
##   --trace-nav                 mit --trace auch Ziel und Wegfindung jedes Gastes
##   --noise=art                 alle 6 s Lärm dieser Art am Spieler (door, hide, run, scream … – Senses.NOISE)
##   --warn                      sofort Vorwarnung → Monster erscheint
##   --pumpkin=ankündigung[,s]   Kürbismann kündigt sich an (4.19): Lampen rot, schrille Melodie, Kinder singen – in s
##                               Sekunden (Standard 20) kommt er übers Lobbydach; mit --trace „[Kürbismann] kündigt sich an“
##   --doll[=s[,zimmer]]         die Puppe (5.5): in s Sekunden (Standard 20) bricht das Monster zu einem Angriff mit
##                               einem Opfer auf (wie --intent=one), sie liegt sofort vor der schwächsten bewohnten Tür (bzw.
##                               vor diesem Zimmer, z. B. 13 oder 113) und es grollt; mit --trace „[Puppe]“ mit Weg und Opfern
##   --doll=kind                 ein Kind holt die Puppe gleich und legt sie vor die Tür seiner Familie
##   --ghost=n|flur|schrank|tür  Lakengeist sofort zum n. Mal am Außenfenster bzw. an der Fenstertür des Raums, in dem
##                               du stehst (beim Start Zimmer 13): Licht aus, Vorhang auf, Blick dorthin (4.18) · flur: alle Gäste
##                               schlafen sofort, er taucht in deinem Flur knapp 20 m vor dir auf und kommt (vorher mit
##                               --tp/--pos in einen Flur stellen) · schrank: kommt durch den Vorhang deines Zimmers
##                               herein, du versteckst dich sofort in dessen Schrank – er wartet davor (mit --trace:
##                               Wartezeit, Chance, ob er hineinfliegt) · tür: ein Lakengespenst hängt neben der Tür
##                               deines Zimmers (sonst Zimmer 13), er steht lautlos davor und hypnotisiert durch die
##                               Wand (5.6), mit --answer öffnest du nach 4 s · ohne Fenster bzw. Flur nur eine Meldung
##   --ghost=stunde[,n]          Geisterstunde (4.18): die Uhr springt kurz vor Mitternacht, die Glocke schlägt, danach geht
##                               er in deinem Flur um (vorher mit --tp/--pos hinstellen, sonst im Obergeschoss) und kommt zum
##                               n. Mal (Standard 1; ab 4 würgt er) – der erste Angriff gilt als geschehen
##   --spinne[=gesicht|schublade] Spinnen (4.23): acht krabbeln sofort vor dir · gesicht: eine springt
##                               dir ins Gesicht – Maus schnell hin und her schüttelt sie ab, sonst beißt sie (wie ein Glas) ·
##                               schublade: die nächste Schublade hat eine – beide: der erste Angriff gilt als geschehen
##   --fledermaus[=tag|schwarm]  Fledermäuse (4.22): du stehst im Garten vor einem Baum und siehst hinauf – 21 Uhr, sie
##                               kreisen · tag: 12 Uhr, sie hängen in der Krone · schwarm: wie tag, nach 3 s fliegen sie auf
##   --sleep[=bett[,h]]          Nachtruhe sofort beginnen – die Uhr springt auf ihren Beginn (Gäste gehen ins Bett) · bett: alle liegen sofort,
##                               du schläfst im Bett von Zimmer 13, h Stunden (1–8, Standard 1; 3.6) – in der Nachtruhe
##                               springt die Zeit (mit --uhr=1:10 nach Mitternacht beginnen, sonst weckt die Glocke)
##   --dusche[=fang|los|nacht]   Lakengeist in der Dusche (4.24): die Dusche in Zimmer 13 läuft sofort, du stehst im Bad,
##                               Blick zu ihr · fang: knapp vor der Duschtür – die Kamera fängt dich gleich, er kommt aus dem
##                               Nebel · los: dazu reißt du dich los (Handabdrücke, erlebt) · nacht: die erste Begegnung mit
##                               ihm liegt über einen Tag zurück, nach 3 s beginnt die Nachtruhe – die Dusche läuft nach der
##                               Regel (mit --sleep=bett wachst du davon auf)
##   --salz[=fenster|tür|monster|streuen|zimmer,nr|gast,id]  Salz (5.13): eine Salzpackung in der Hand · fenster: dazu Salz auf allen
##                               Außenfenstern und Fenstertüren deines Zimmers (beim Start 13; mit --ghost=3 kommt er nicht herein) · tür:
##                               innen vor seiner Tür · monster: dazu kommt das Monster den Flur entlang und will
##                               herein – es zögert an der Linie und verwischt sie · streuen: du stehst in deinem Zimmer
##                               vor der Tür, siehst hin und streust nach 0,5 s selbst · zimmer,nr / gast,id: auf den Fenstern von Zimmer nr bzw. des Gastes
##                               (mit --shock=id,ghost3 würgt er ihn nicht)
##   --hoerer                    der Hörer in Zimmer 13 liegt daneben (keine Anrufe, die einen wecken; 4.14)
##   --awake=n                   so viele Nächte ohne Schlaf, auch Bruchteile (Lakengeist häufiger, ab 3 sicher im Flur; 4.18) –
##                               der erste Angriff gilt dann als geschehen
##   --intent=roam|one|rampage|n Absicht beim Aufbruch erzwingen (umsehen, 1 oder 2 Opfer, oder n Opfer; 4.17)
##   --bold=n                    Dreistigkeit setzen (0–100)
##   --friend=id                 mit einem Gast befreundet starten (edna, bruno, mila, gast1 …)
##   --enemy=id                  mit einem Gast verfeindet starten
##   --relation=id,wert          Beziehung setzen (−100 … 100); ab ±80 werden die nötigen Taten mit eingetragen (6.3)
##   --follow=id · --visit=id    Gast kommt mit (steht hinter dir) · Gast geht zu Zimmer 13 und klopft an
##   --attack=id                 Gast steht vor dir und schlägt zu
##   --punch=id                  Gast vor dich stellen und ihn schlagen (mit Nachfrage)
##   --kill=id[,geist|kuerbis]   Gast nach 3 s vom Monster holen lassen (überlebt mit 20 %, Kernfiguren immer: Kratzer, 6.17) · geist/kuerbis:
##                               nach 1,5 s vor dir erwürgt bzw. erschlagen, die Leiche bleibt liegen (Totenkopf)
##   --kill=id,leiche|weg[,blut][,hin]   sofort tot, ohne Monster: liegt da bzw. ist verschwunden (Kratzer, Schuh) · blut:
##                               Lache und Wandspritzer (ohneblut: auch beim Kürbismann keins) · hin: 1,3 m vor dir
##                               Statt der ID geht überall auch der Name (emil, EmilBecker, juergen …)
##   --despawn[=monster|geist|kuerbis]   die Bedrohung (ohne Angabe alle) ist sofort fort, auch Vorwarnung/Ankündigung
##   --bulb-thief=id             Gast klaut sofort eine Glühbirne aus Zimmer 13
##   --steal-test                Ednas Deko unbemerkt nehmen (Schuld-Test)
##   --player-deco=x,z           geschnitzten Kürbis des Spielers an diese Stelle stellen
##   --wound=gast,scratch|axe|choke[,hin]   Gast hat überlebt (6.17): Kratzer, Axtwunde (Blutspur, ein Tag im Bett) bzw.
##                               Würgemale (heiser, schweres Atmen) · hin: steht vor dir statt im Bett (mit --talk=gast)
##   --wallblood[=smear]         Blutspritzer (smear: blutige Schmierspur) an die Wand, auf die du schaust (4.13)
##   --costumes[=art]            alle Gäste sofort verkleidet (sonst ab dem 25.): jeder sein Kostüm, art = sheet|witch|
##                               pumpkin|cape für alle gleich (5.9)
##   --disguise                  Bettlaken übergeworfen (5.9): Sicht durch Augenlöcher, Gäste erkennen dich nur aus der Nähe
##   --maske[=id]                verbotene Masken (5.19): vor den Haken in Zimmer 13 stehen · id (pumpkin|doll): diese
##                               Maske gleich aufgesetzt (Kürbismann: Spaßschwelle tief, Puppe: nächstes Urteil auf 13)
##   --drunk=n[,gast]            n Gläser getrunken (du, mit Gast: er) – ab 2 angetrunken, ab 3 betrunken (3.7)
##   --weather=klar|regen|gewitter|blitz   Wetter sofort in voller Stärke (7.8) · blitz: gleich ein Blitz (mit Gewitter)
##   --party[=gast]              sofort eine Feier im Partyraum starten (mit Gast: er lädt ein, ~3/4 kommen;
##                               sonst du – dann kommen nur Eingeladene und Freunde)
##   --cat=id[,tragen]           Hotelkatze vor den Spieler setzen (minka, socke, kasimir; im Katzenraum luna, fussel, tiger, mausi) – mit tragen gleich auf den Arm
##   --pumpkin[=anim]            Kürbismann als Testfigur (ohne Verhalten) 2,5 m vor dich, Animation in Schleife:
##                               walk (Standard), run, spin_jump, chicken, macarena, hiphop – ersetzt eine alte
##   --pumpkin=jagd[,gast]       Kürbismann (Spielkonzept 4.19) kommt übers Lobbydach und jagt dich bzw. den Gast
##   --pumpkin=dach              wie F9: Kürbismann klettert übers Lobbydach, springt in den Garten, sucht die Lobby ab
##   --pumpkin=garten            Kürbismann gleich an den Kürbisbeeten im Garten (ohne Dach), jagt alle mit Spaß und dich
##   --talk=id                   direkt ein Gespräch mit dem Gast öffnen
##   --gespraech=frage,id,gast[,n]   Gespräch, in dem der Gast diese Frage stellt (6.9: ghosts, night, contest, room,
##                               brave, play, escort), mit n gleich die n-te Antwort
##   --gespraech=erlebnis,art,gast[,erzaehlen]   ein eigenes Erlebnis (monster, ghost, pumpkin, corpse, blood,
##                               ghost_visit, attic) hier, dann Gespräch – mit erzaehlen gleich als Anlass erzählt
##   --gespraech=luege,art,gast[,wer]   dem Gast etwas vorlügen (geist, monster, kuerbis, leiche, dieb); bei leiche/dieb
##                               kommt der Genannte nach 3 s vorbei – die Lüge fliegt auf (--trace)
##   --bitte=gast[,art[,annehmen|erfuellen]]  der Gast stellt seine Bitte (6.14; art: herz – Standard –, kuerbis,
##                               kerze, kaffee, suess, mag); annehmen: gleich zusagen, erfuellen: auch erfüllen ([Bitte])
##   --look=id[,pose]            Gast ansehen (ohne Dialog, er bleibt stehen); pose: carry (trägt einen Kürbis),
##                               panic (Arme hoch), dance (tanzt), sit (sitzt), walk (geht quer vorbei) –
##                               zum Prüfen der Gastmodelle
##   --shock=id[,blood|corpse|ghostN|tür]  Gast erschrecken (6.12): Blutlache bzw. Leiche vor ihm im Flur, oder der
##                               Lakengeist kommt zum N. Mal an sein dunkles Zimmerfenster (ab 3 würgt er) –
##                               mit --talk=id erzählt er danach davon
##   --dice=id                   sofort Mäxchen mit dem Gast (Einsatz 3 Geld)
##   --chess=id                  sofort Schach mit dem Gast in der Lobby (Einsatz 3 Geld; mit --autoplay zieht der Spieler selbst)
##   --darts[=id]                sofort Darts in der Bar: allein üben, mit id gegen den Gast (Einsatz 3 Geld; mit
##                               --autoplay wirft der Spieler selbst)
##   --challenge=id[,chess|darts]  Gast fordert dich heraus (Mäxchen, Schach bzw. Darts)
##   --autoplay                  Mäxchen-Antworten, Schachzüge bzw. Dartwürfe automatisch wählen
##   --shot=pfad.png             Screenshot speichern und beenden
##   --frames=n                  Frames bis zum Screenshot (Standard 120)
##   --shot-size=BxH             Fenster für den Screenshot in dieser Größe (rahmenlos, auch über den Bildschirm hinaus)
##   --shot-on=jumpscare|strangle|shock|pumpkin|lightning  Screenshot kurz nach einem Ereignis statt nach n Frames
##                               (Kürbismann auch pumpkin_roof|pumpkin_edge|pumpkin_leap|pumpkin_land|pumpkin_lobby)
##   --bg                        Fenster im Hintergrund: kein Fokus, außerhalb des Bildschirms (Game._to_background)
##   --navcheck                  Bau- und NavMesh-Zeit, Wege von Zimmer 13 zu allen wichtigen Orten (Spielkonzept 7.5)
## Vorzeichen und Spuk (4.25–4.31, 5.14–5.18, 6.21):
##   --kraehen[=groll]           im Garten 7 m vor den Krähen · groll: sie haben sich dich gemerkt und krächzen dich an
##   --ratten[=welle]            fünf Ratten um dich im Keller (sonst im Heizkeller) · welle: nach 2 s rennen sie davon, als käme
##                               das Monster aus dem Heizkeller
##   --hund                      nach 1 s heult hinter der Waldkante ein Hund (sonst zufällig alle paar Spielminuten)
##   --kesselkatze               Nacht, Kellergang: die schwarze Kesselkatze sitzt 5 m vor dir – sieh hin, sie geht voraus
##   --spiegel[=tuch]            vor dem Spiegel in Zimmer 13, nach 2 s steht die Gestalt hinter dir · tuch: er ist verhängt
##   --strom[=kasten]            Gewitter, gleich fliegt die Sicherung · kasten: Strom aus, du vor dem Sicherungskasten im UG
##   --albtraum                  Nacht am 16., du schläfst in Zimmer 13 ein – nach 3 s der Traum vom Heizkeller 1987
##   --vogelscheuche[=tag]       sie steht, wo sie an Halloween (bzw. an diesem Tag) stünde, du in der Lobby vor der Gartentür
##   --kind-zu-viel              der 28. abends, ein Kind vor deiner offenen Tür – und eins zu viel dahinter
##   --fotos[=jahr]              vor die Fotowand in der Lobby · jahr: dieses Foto gleich aufgeschlagen (1987 … 2026)
##   --beerdigen[=gast]          ein erwürgter Gast liegt vor der Gedenkstätte auf dem Friedhof – [E] beerdigt ihn
##   --trauerfeier               zwei Gäste liegen seit gestern, 20 s vor der Totenglocke (9:30), du an der Gedenkstätte
##   --puppenhaus[=urteil]       vor das Puppenhaus in der Bibliothek · urteil: die Puppe urteilt gleich (die kleine weiß es zuerst)
##   --fratzen                   unter Schock, drei geschnitzte Kürbisse vor dir – sieh weg und wieder hin
##   --apfel[=gesicht]           über den Apfelbottich im Partyraum gebeugt · gesicht: nachts, beim Hochkommen das Gesicht im Wasser
##   --spieluhr[=monster]        Spieluhr in die Hand · monster: es kommt zu dir, nach 3 s ziehst du sie auf

var _post: ShaderMaterial
## Nachthimmel (shaders/night_sky.gdshader) – Wolkenzug nach Spielzeit
var _sky: ShaderMaterial
var _env: Environment
var _sky_time := 0.0

var _trace := false
var _trace_frames := 0
var _autoplay := false
## Dauer von LevelBuilder.build() und NavMesh-Backen in ms (--navcheck)
var _load_times := Vector2i.ZERO


func _ready() -> void:
	Game.reset()
	_setup_environment()

	var level := NavigationRegion3D.new()
	level.name = "Level"
	add_child(level)
	LevelBuilder.refresh_maps()   # Plan geändert? Dann erst neu einlesen
	LevelBuilder.refresh_households()   # HAUSHALTE.md geändert? Dann die Haushalte neu einlesen (6.20)
	var builder := LevelBuilder.new(level, self)
	var t0 := Time.get_ticks_msec()
	builder.build()
	var t1 := Time.get_ticks_msec()
	_bake_navigation(level)
	_load_times = Vector2i(t1 - t0, Time.get_ticks_msec() - t1)

	var audio := SynthAudio.new()
	audio.name = "SynthAudio"
	add_child(audio)
	Game.audio = audio

	var shadows := ShadowBudget.new()
	shadows.name = "ShadowBudget"
	shadows.rooms = builder.light_rooms
	add_child(shadows)

	var traces := Traces.new()
	traces.name = "Traces"
	add_child(traces)
	Game.traces = traces

	var player := Player.new()
	player.name = "Player"
	player.position = builder.player_spawn
	add_child(player)
	Game.player = player
	player.set_look(PlayerBody.default_look())   # neues Spiel: die Charaktererstellung ändert sie, ein Spielstand auch

	var monster := Monster.new()
	monster.name = "Monster"
	add_child(monster)
	Game.monster = monster

	var ghost := SheetGhost.new()
	ghost.name = "SheetGhost"
	add_child(ghost)
	Game.ghost = ghost

	var pumpkin := PumpkinMan.new()
	pumpkin.name = "PumpkinMan"
	add_child(pumpkin)
	Game.pumpkin = pumpkin

	var director := MonsterDirector.new()
	director.name = "MonsterDirector"
	add_child(director)
	director.setup(builder, monster)
	_post = _setup_post_fx()
	director.post_material = _post
	Game.director = director
	Settings.changed.connect(_apply_settings)
	_apply_settings()

	var social := Social.new()
	social.name = "Social"
	add_child(social)
	Game.social = social
	social.setup(builder, self)

	# Die Puppe (5.5) – sitzt am Anfang in der Lobby
	var doll := JuryDoll.new().setup(builder)
	doll.name = "Puppe"
	add_child(doll)
	doll.place_at_start()
	Game.doll = doll

	# Der Anfang (2.5): Brief, Aushangbrett, Durchsagen, Siegerehrung
	var contest := DoorContest.new()
	contest.name = "DoorContest"
	add_child(contest)
	Game.contest = contest
	contest.setup(builder)

	# Notizbuch (3.10) – steckt im Umschlag des Briefs; Tagebuch mit seinen Meilensteinen
	var notebook := Notebook.new()
	notebook.name = "Notebook"
	add_child(notebook)
	Game.notebook = notebook
	Game.diary = builder.diary

	# Hotelkatzen (6.11) – nach den Gästen, sie suchen sich einen Lieblingsgast
	for cat_id in HotelCat.PROFILES:
		var cat := HotelCat.new().setup(cat_id, builder)
		cat.name = "Katze_" + cat_id
		add_child(cat)
		cat.place_at_start()

	var weather := Weather.new()   # Regen und Gewitter draußen (Spielkonzept 7.8)
	weather.name = "Weather"
	add_child(weather)
	weather.setup(builder, get_node("Moon") as DirectionalLight3D, _sky)
	Game.weather = weather
	var bats := Bats.new()   # Fledermäuse in den Bäumen und über dem Garten (Spielkonzept 4.22)
	bats.name = "Bats"
	add_child(bats)
	bats.setup(builder)
	Game.bats = bats
	var spiders := Spiders.new()   # Spinnen am Boden und in Schubladen (Spielkonzept 4.23)
	spiders.name = "Spiders"
	add_child(spiders)
	spiders.setup(builder)
	Game.spiders = spiders
	var sleep_skip := SleepSkip.new()   # Zeitsprung im Schlaf (Spielkonzept 3.6)
	sleep_skip.name = "SleepSkip"
	add_child(sleep_skip)
	Game.sleep_skip = sleep_skip
	var shower_scare := ShowerScare.new().setup(builder)   # Lakengeist in der Dusche von Zimmer 13 (Spielkonzept 4.24)
	shower_scare.name = "ShowerScare"
	add_child(shower_scare)
	Game.shower_scare = shower_scare
	_setup_omens(builder)

	var grass := Grass.new()   # Grasbüschel, nur ohne PS1-Look – nach dem NavMesh
	grass.name = "Grass"
	add_child(grass)
	grass.setup(builder)

	var dialog := DialogUI.new()
	dialog.name = "Dialog"
	add_child(dialog)
	Game.dialog = dialog

	var phones := PhoneCalls.new()
	phones.name = "PhoneCalls"
	add_child(phones)
	phones.setup()
	Game.phones = phones

	var dice := DiceMatch.new()
	dice.name = "DiceMatch"
	dice.table = builder.game_table
	add_child(dice)
	Game.dice = dice

	var chess := ChessMatch.new()
	chess.name = "ChessMatch"
	chess.table = builder.chess_table
	add_child(chess)
	Game.chess = chess

	var darts := DartMatch.new()
	darts.name = "DartMatch"
	darts.board = builder.dart_board
	add_child(darts)
	Game.darts = darts

	var hud := Hud.new()
	hud.name = "Hud"
	add_child(hud)
	Game.hud = hud

	var menus := Menus.new()
	menus.name = "Menus"
	add_child(menus)
	Game.menus = menus

	var achievements := Achievements.new()
	achievements.name = "Achievements"
	add_child(achievements)
	Game.achievements = achievements

	var teleport := TeleportUI.new()   # nach den Menüs: bekommt Esc/F6 zuerst
	teleport.name = "Teleport"
	add_child(teleport)
	teleport.setup(builder)

	if DebugConsole.enabled():   # Befehle wie die Startparameter, im Spiel getippt
		var console := DebugConsole.new()
		console.name = "DebugConsole"
		add_child(console)
		console.setup(func(arg: String) -> bool:
			Game.achievements.cheated()   # wer in der Konsole tippt, schaltet nur noch für diese Sitzung frei (8.11)
			return run_debug(arg))

	for arg in OS.get_cmdline_user_args():
		if arg == "--perf" or arg.begins_with("--perf="):
			add_child(PerfLog.new(arg.substr(7).to_float() if arg.length() > 7 else 20.0))

	Game.player_died.connect(_on_player_died)
	SaveManager.note_world.call_deferred()   # nach dem Aufbau, bevor sich etwas bewegt
	if not Game.pending_load.is_empty():
		_load_pending.call_deferred()
	else:
		_fresh_session()
		if Game.new_game_slot > 0:   # vom Titelbildschirm: erst die Figur, dann der Gedanke an den Brief und Speichern
			_start_creation(Game.new_game_slot, false)
		elif not "--nointro" in OS.get_cmdline_user_args():
			Game.contest.welcome()
		Game.new_game_slot = 0
	_parse_debug_args.call_deferred()


## Vorzeichen und Spuk (Spielkonzept 4.25–4.31, 5.14–5.18, 6.21): Tiere, Artefakte und seltene Momente.
func _setup_omens(builder: LevelBuilder) -> void:
	var crows := Crows.new()   # Krähen im Garten, merken sich Gesichter (4.25)
	crows.name = "Crows"
	add_child(crows)
	crows.setup(builder)
	Game.crows = crows
	var rats := Rats.new()   # Ratten im Untergeschoss, rennen vor dem Monster (4.25)
	rats.name = "Rats"
	add_child(rats)
	rats.setup(builder)
	Game.rats = rats
	RatKing.place(self)
	var moths := Moths.new()   # Motten an den Lampen (4.25)
	moths.name = "Moths"
	add_child(moths)
	moths.setup(builder)
	Game.moths = moths
	var boiler_cat := BoilerCat.new().setup(builder)   # die schwarze Kesselkatze (4.26)
	boiler_cat.name = "Kesselkatze"
	add_child(boiler_cat)
	Game.boiler_cat = boiler_cat
	var mirrors := MirrorOmens.new()   # verhängte Spiegel, Gestalt im Spiegel (4.27)
	mirrors.name = "MirrorOmens"
	mirrors.setup(builder)
	add_child(mirrors)
	Game.mirror_omens = mirrors
	var power := PowerCut.new().setup(builder)   # Stromausfall im Gewitter (4.28)
	power.name = "PowerCut"
	add_child(power)
	Game.power_cut = power
	var nightmare := Nightmare.new().setup(builder)   # der Albtraum von 1987 (4.29)
	nightmare.name = "Nightmare"
	add_child(nightmare)
	Game.nightmare = nightmare
	var scarecrow := Scarecrow.new().setup(builder)   # die Vogelscheuche, die näher kommt (4.30)
	scarecrow.name = "Vogelscheuche"
	add_child(scarecrow)
	Game.scarecrow = scarecrow
	var extra := ExtraChild.new()   # das Kind zu viel (4.31)
	extra.name = "KindZuViel"
	add_child(extra)
	Game.extra_child = extra
	var photos := PhotoWall.new()   # Gruppenfotos in der Lobby (5.14)
	photos.name = "Fotowand"
	add_child(photos)
	Game.photo_wall = photos
	var cemetery := Cemetery.new()   # Friedhof westlich des Kürbisfelds (5.15)
	cemetery.name = "Friedhof"
	add_child(cemetery)
	cemetery.setup(builder.grave_slots, builder.memorial_spot)
	Game.cemetery = cemetery
	var doll_house := DollHouse.new()   # Puppenhaus in der Bibliothek (5.16)
	doll_house.name = "Puppenhaus"
	add_child(doll_house)
	Game.doll_house = doll_house
	var faces := PumpkinFaces.new()   # Kürbisgesichter, die sich verändern (5.18)
	faces.name = "PumpkinFaces"
	add_child(faces)
	Game.pumpkin_faces = faces
	var tub := AppleTub.new()   # Apfeltauchen im Partyraum (6.21)
	tub.name = "Apfelbottich"
	add_child(tub)
	Game.apple_tub = tub


func _load_pending() -> void:
	var data := Game.pending_load
	Game.pending_load = {}
	if not SaveManager.fits(data):   # Hotel seit dem Speichern umgebaut – nicht falsch befüllen
		_fresh_session()
		Game.say("Dieser Spielstand passt nicht mehr zum Hotel. Das Spiel beginnt von vorn.", 8.0)
		return
	SaveManager.apply(data)
	Game.say("„%s“" % String(data.get("text", "")), 5.0)


## Erwachen am Waschbecken und Charaktererstellung (Spielkonzept 3.9) – danach der Gedanke an den Brief (2.5) und, in
## einem Slot, der Startstand.
func _start_creation(slot: int, quick: bool) -> void:
	if has_node("CharacterCreation"):
		return
	var creation := CharacterCreation.new()
	creation.name = "CharacterCreation"
	creation.quick = quick
	creation.finished.connect(func() -> void:
		if not "--nointro" in OS.get_cmdline_user_args():
			Game.contest.welcome()
		if slot > 0:
			_save_start(slot))
	add_child(creation)


## Neues Spiel: noch nichts besucht (Autosave „neuer Bereich“), noch nicht gespeichert.
func _fresh_session() -> void:
	SaveManager.visited = []
	SaveManager.last_save_msec = -1


## Neues Spiel in einem Slot: Startzustand gleich speichern, damit „Fortsetzen“ greift.
func _save_start(slot: int) -> void:
	for i in 3:
		await get_tree().process_frame
	SaveManager.save_to(slot, DoorContest.ARRIVAL_ENTRY, get_viewport().get_texture().get_image())


func _apply_settings() -> void:
	_env.ssr_enabled = Settings.reflections
	if _post:
		_post.set_shader_parameter("gamma", Settings.gamma)
		_post.set_shader_parameter("dither", 1.0 if Settings.dither_on() else 0.0)
		_post.set_shader_parameter("color_levels", 28.0 if Settings.psx_look else 255.0)


func _process(delta: float) -> void:
	_sky_time += delta
	_sky.set_shader_parameter("sky_time", _sky_time)
	if _post and Game.player:   # verschwommene Sicht (Spielkonzept 3.6/3.7)
		_post.set_shader_parameter("blur", maxf(Game.player.sight_blur, Game.player.intro_blur))
		_post.set_shader_parameter("warp", Game.player.sight_warp)
		_post.set_shader_parameter("blur_time", _sky_time)
	if _autoplay and Engine.get_process_frames() % 100 == 0 and Game.dice.active:
		print("[Mäxchen] " + Game.dice.debug_press_random())
	if _autoplay and Engine.get_process_frames() % 30 == 0 and Game.chess.active:
		var step := Game.chess.debug_step()
		if step != "":
			print("[Schach] " + step)
	if _autoplay and Engine.get_process_frames() % 40 == 0 and Game.darts.active:
		var throw := Game.darts.debug_step()
		if throw != "":
			print("[Darts] " + throw)
	if _trace:
		_trace_frames += 1
		if _trace_frames % 120 == 0:
			var nav := "--trace-nav" in OS.get_cmdline_user_args()
			print("[%ds] Monster %s @ %s | Phase %s | Dreistigkeit %.1f" % [_trace_frames / 60,
				Monster.State.keys()[Game.monster.state], Game.monster.global_position.snapped(Vector3.ONE * 0.1),
				MonsterDirector.Phase.keys()[Game.director.phase], Game.director.effective_boldness()])
			print("      Spieler @ %s | Schock %.2f | Rausch %.2f | Schwäche %.2f | Geld %d | Hand: %s" % [Game.player.global_position.snapped(Vector3.ONE * 0.1), Game.player.shock, Game.player.drunk, Game.player.weakness(), Game.money, Game.player.held.display_name if Game.player.held else "-"])
			for guest in Game.social.guests:
				print("      %s: %s @ %s | Angst %.0f | Rausch %.2f | Beziehung %.0f | Hand: %s" % [guest.display_name,
					Guest.State.keys()[guest.state], guest.global_position.snapped(Vector3.ONE * 0.1), guest.fear,
					guest.drunk, guest.relation, guest.held.display_name if guest.held else "-"])
				if nav:
					print("        Ziel %s  nächster Punkt %s  fertig %s" % [guest.get("_target"), guest.agent.get_next_path_position(), guest.agent.is_navigation_finished()])


func _setup_environment() -> void:
	var env := Environment.new()
	# Nachthimmel mit Mond und Wolken (7.3): zu sehen im Garten und durch die Fenster. Er leuchtet nichts
	# aus – Umgebungslicht bleibt eine feste Farbe, Spiegelungen aus (sonst glänzte er in Tapete und Fliesen)
	_sky = ShaderMaterial.new()
	_sky.shader = load("res://shaders/night_sky.gdshader")
	var sky := Sky.new()
	sky.sky_material = _sky
	sky.process_mode = Sky.PROCESS_MODE_REALTIME   # Wolken ziehen jedes Bild; Strahlungs-Durchgang ist billig
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.reflected_light_source = Environment.REFLECTION_SOURCE_DISABLED
	# Spiegelbilder nur aus dem Bild selbst (SSR, 2026-10-21): polierter Lobbymarmor, Lack der Tapete, Poolwasser
	# spiegeln, was gerade zu sehen ist – zum Bildrand und nach hinten blendet es aus. Matte Flächen
	# (psx_surface, Rauheit 1) bleiben unberührt. Godot nimmt für Nichtmetalle fest 4 % Reflexion an, darum hat
	# der Lobbyboden etwas Metallic (LevelBuilder.LOBBY_FLOOR_MIRROR). Schritte: ein Bildpunkt je Schritt –
	# mit 64 fanden Strahlen über den Boden die Wände dahinter oft nicht
	env.ssr_enabled = Settings.reflections   # Einstellungen → Bild → Spiegelungen (_apply_settings)
	env.ssr_max_steps = 128
	env.ssr_fade_in = 0.15
	env.ssr_fade_out = 2.0
	env.ssr_depth_tolerance = 0.2
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.35, 0.38, 0.5)
	env.ambient_light_energy = 0.14  # ohne Deckenlampen: dunkle Ecken bleiben als Umriss erkennbar
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.fog_enabled = true
	env.fog_light_color = Color(0.02, 0.02, 0.03)
	# Nebel nach Entfernung: ab 4 m dichter, bei 66 m schwarz (Flurende verschwindet im Dunkel statt im Dunst)
	env.fog_mode = Environment.FOG_MODE_DEPTH
	env.fog_density = 1.0
	env.fog_depth_begin = 4.0
	env.fog_depth_end = 66.0
	env.fog_depth_curve = 0.6
	env.fog_sky_affect = 0.0   # Himmel bleibt hinter dem Nebel sichtbar, Bäume und Dächer stehen schwarz davor
	# Lichtschein im Dunst: Lampen werfen sichtbare Lichtkegel, dazwischen bleibt es finster
	env.volumetric_fog_enabled = true
	env.volumetric_fog_density = 0.0175
	env.volumetric_fog_albedo = Color(0.6, 0.6, 0.65)
	env.volumetric_fog_length = 12.0   # nur nah: weiter hinten würde das Lampenlicht den Flur beige verschleiern
	_env = env
	var world_env := WorldEnvironment.new()
	world_env.environment = env
	add_child(world_env)
	# Schwaches Mondlicht – erhellt den Garten und fällt durch die Lobbyfenster
	var moon := DirectionalLight3D.new()
	moon.name = "Moon"   # Weather lässt ihn blitzen
	moon.light_color = Color(0.55, 0.65, 1.0)
	moon.light_energy = 0.32
	moon.shadow_enabled = true
	moon.directional_shadow_max_distance = 40.0
	moon.rotation = Vector3(deg_to_rad(-55.0), deg_to_rad(-30.0), 0.0)
	add_child(moon)


## NavMesh zur Laufzeit backen: nur statische Kollision auf Ebene 1
## (Wände, Böden, Möbel). Türen (Ebene 2) bleiben offen für die Wegplanung.
func _bake_navigation(region: NavigationRegion3D) -> void:
	var nav_mesh := NavigationMesh.new()
	nav_mesh.cell_size = 0.1
	nav_mesh.cell_height = 0.1
	nav_mesh.agent_radius = 0.3
	nav_mesh.agent_height = 1.6
	nav_mesh.agent_max_climb = 0.2
	nav_mesh.geometry_parsed_geometry_type = NavigationMesh.PARSED_GEOMETRY_STATIC_COLLIDERS
	nav_mesh.geometry_collision_mask = 1
	region.navigation_mesh = nav_mesh
	region.bake_navigation_mesh(false)


func _setup_post_fx() -> ShaderMaterial:
	var layer := CanvasLayer.new()
	layer.name = "PostFx"
	layer.layer = 5
	add_child(layer)
	var material := ShaderMaterial.new()
	material.shader = load("res://shaders/psx_post.gdshader")
	var rect := ColorRect.new()
	rect.material = material
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(rect)
	rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	return material


## --static-eg: zwei Bilder warten (Lampen haben dann ihre Stärke), speichern, als Startparameter beenden.
func _export_static(path: String, quit: bool) -> void:
	for i in 2:
		await get_tree().process_frame
	var err := StaticExport.save(Game.social.builder, self, path)
	if not quit:
		Game.say("Statische Szene: %s" % (path if err == OK else error_string(err)), 4.0)
	else:
		get_tree().quit()


func _on_player_died() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	add_child(DeathScreen.new())


func _parse_debug_args() -> void:
	var args := OS.get_cmdline_user_args()
	for arg in args:   # vor allem, was einen Aufbruch auslöst (--warn …)
		if arg.begins_with("--intent=") or arg in ["--no-psx", "--psx"]:
			run_debug(arg)
	for arg in args:
		if not (arg.begins_with("--intent=") or arg in ["--no-psx", "--psx"]):
			run_debug(arg)


## Einen Debug-Befehl ausführen – beim Start für jeden Parameter, im Spiel aus der Debug-Konsole
## (DebugConsole, dort ohne „--“ getippt). false = unbekannt. Neuer Befehl: hier ein Zweig, eine Zeile
## im Kopfkommentar, in DebugConsole.COMMANDS und in der README.
func run_debug(arg: String) -> bool:
	if arg.begins_with("--intent="):
		var wanted := arg.substr(9)
		Game.director.debug_victims = wanted.to_int() if wanted.is_valid_int() else ["roam", "one", "rampage"].find(wanted)
	elif arg == "--no-psx" or arg == "--psx":
		Settings.psx_look = arg == "--psx"
		Settings.apply()
	elif arg == "--static-eg" or arg.begins_with("--static-eg="):
		_export_static(arg.substr(12) if arg.length() > 12 else StaticExport.PATH, arg in OS.get_cmdline_user_args())
	elif arg == "--fps":
		Game.hud.fps_enabled = not Game.hud.fps_enabled
	elif arg == "--nohud":
		Game.hud.visible = not Game.hud.visible
	elif arg.begins_with("--tp="):
		return _debug_teleport(arg.substr(5))
	elif arg == "--aufzug" or arg.begins_with("--aufzug="):
		var lifts := Game.social.builder.elevators
		if lifts.is_empty():
			return false
		var at := lifts[0].spot(arg.ends_with("=innen") or arg.ends_with("=fahrt"))
		TeleportUI.place_player(at[0], at[1])
		if arg.ends_with("=offen"):
			lifts[0].open_doors()
		elif arg.ends_with("=fahrt"):
			lifts[0].ride_to_top()
	elif arg == "--sitzen" or arg.begins_with("--sitzen="):
		var want := arg.substr(9) if arg.begins_with("--sitzen=") else "sofa"
		var here := Game.player.global_position
		var best: Seat = null
		for node in get_tree().get_nodes_in_group("seats"):
			var s := node as Seat
			if s.kind == want and (best == null or s.global_position.distance_to(here) < best.global_position.distance_to(here)):
				best = s
		if best == null:
			return false
		Game.player.sit_down(best, best.spots[0])
	elif arg.begins_with("--tuer="):
		var builder := Game.social.builder
		var no := arg.substr(7).pad_zeros(3)
		if not builder.rooms.has(no):
			return false
		TeleportUI.place_player(builder.rooms[no]["door_front"], builder.rooms[no]["into"])
		set_meta("debug_door", builder.rooms[no]["door"])
	elif arg.begins_with("--werkzeug="):
		var what := arg.substr(11)
		if what == "schluessel":
			Game.player.add_key(KeyCabinet.KEY_ID)
		else:
			Game.player.drop_held()
			Game.player.receive_item(Item.create(Item.Kind.CROWBAR if what == "brecheisen" else Item.Kind.TOOLBOX))
		if has_meta("debug_door"):
			var door: Door = get_meta("debug_door")
			get_tree().create_timer(1.0).timeout.connect(func() -> void:
				if Game.tracing:
					print("[Zimmer] Tür %s: %s" % [door.room_no, door.get_prompt(Game.player)])
				door.interact(Game.player))
	elif arg == "--klopfen" or arg.begins_with("--klopfen="):
		var parts := arg.substr(10).split(",") if arg.begins_with("--klopfen=") else PackedStringArray()
		var builder := Game.social.builder
		var no := parts[0].pad_zeros(3) if parts.size() > 0 and parts[0] != "" else ""
		if no == "":
			var best := INF
			for n: String in builder.households:
				var d := (builder.rooms[n]["door_front"] as Vector3).distance_to(Game.player.global_position)
				if d < best:
					best = d
					no = n
		if not builder.households.has(no):
			return false
		var info: Dictionary = builder.rooms[no]
		TeleportUI.place_player(info["door_front"], info["into"])
		var door: Door = info["door"]
		get_tree().create_timer(1.0).timeout.connect(func() -> void: door.interact(Game.player))
		if parts.size() > 1:
			var way: String = {"ehrlich": "honest", "lampe": "lie_lamp", "geschenk": "lie_gift", "panik": "panic",
				"geld": "bribe"}.get(parts[1], "honest")
			var answer := func(again: Callable) -> void:
				if Game.dialog.visible and Game.dialog.at_door():
					Game.dialog.answer_door(way)
				else:
					get_tree().create_timer(0.5).timeout.connect(again.bind(again))
			get_tree().create_timer(1.5).timeout.connect(answer.bind(answer))
	elif arg == "--attic-door":
		var builder := Game.social.builder
		if builder.attic_doors.is_empty():
			return false
		var door: Door = builder.attic_doors[0]
		var front := door.global_transform.basis.z   # Aufgehseite: Bänder und Kastenschloss
		TeleportUI.place_player(door.global_transform * Vector3(door.width / 2.0, 0, 0) + front * 2.2, -front)
		Game.player.head.rotation.x = deg_to_rad(-12.0)   # die Tür ist niedrig
	elif arg == "--dachboden" or arg.begins_with("--dachboden="):
		var builder := Game.social.builder
		match arg.get_slice("=", 1) if "=" in arg else "":
			"kopf":
				if builder.pumpkin_head_spot == Vector3.INF:
					return false
				TeleportUI.place_player(builder.pumpkin_head_spot + Vector3(1.4, 0, 0), Vector3.LEFT)
				Game.player.head.rotation.x = deg_to_rad(-35.0)
			"fenster":
				if builder.attic_window_spots.is_empty():
					return false
				# das Fenster, durch das der Mond am steilsten hereinscheint
				var light := -(get_node("Moon") as Node3D).global_basis.z
				var spot: Transform3D = builder.attic_window_spots[0]
				for t: Transform3D in builder.attic_window_spots:
					if (-t.basis.z).dot(-light) > (-spot.basis.z).dot(-light):
						spot = t
				TeleportUI.place_player(spot.origin, -spot.basis.z)
				Game.player.head.rotation.x = deg_to_rad(-8.0)
			"treppe":
				var foot := builder.attic_stair_foot
				TeleportUI.place_player(foot.origin, -foot.basis.z)
				Game.player.head.rotation.x = deg_to_rad(20.0)
			_:
				if builder.attic_doors.is_empty():
					return false
				var door: Door = builder.attic_doors[0]
				var into := door.global_transform.basis.z   # Aufgehseite = in den Dachboden
				TeleportUI.place_player(door.global_transform * Vector3(door.width / 2.0, 0, 0) + into * 1.6, into)
				if arg == "--dachboden=blitz" and builder.attic_spook:
					builder.attic_spook.forced = true
					if Game.weather.kind != Weather.Kind.STORM:
						Game.weather.set_weather(Weather.Kind.STORM, true)
					get_tree().create_timer(3.0).timeout.connect(Game.weather.lightning)
	elif arg.begins_with("--time="):
		# Spieltage vor- oder zurückspulen (+1, -2 …)
		Game.director.elapsed = maxf(0.0, Game.director.elapsed + arg.substr(7).to_float() * Calendar.DAY_SECONDS)
		Game.say(Calendar.date_text(Game.director.elapsed), 2.0)
	elif arg.begins_with("--console"):
		# Konsole nach 1 s öffnen, optional Befehle (mit ; getrennt) eintippen
		var console := get_node_or_null("DebugConsole") as DebugConsole
		if console == null:
			return false
		get_tree().create_timer(1.0).timeout.connect(func() -> void:
			console.open()
			for line in arg.substr(10).split(";", false):
				console.submit(line))
	elif arg.begins_with("--load-slot="):
		SaveManager.load_slot(arg.substr(12).to_int())
	elif arg.begins_with("--pos="):
		var v := arg.substr(6).split(",")
		Game.player.global_position = Vector3(v[0].to_float(), v[1].to_float(), v[2].to_float())
		if v.size() > 3:
			Game.player.rotation.y = deg_to_rad(v[3].to_float())
		if v.size() > 4:
			Game.player.head.rotation.x = deg_to_rad(v[4].to_float())
	elif arg.begins_with("--monster="):
		var m := arg.substr(10).split(",")
		var pos := Vector3(m[0].to_float(), m[1].to_float(), m[2].to_float())
		Game.monster.spawn_at(pos)
		Game.director.phase = MonsterDirector.Phase.ACTIVE
	elif arg.begins_with("--splash="):
		var at := arg.substr(9).split(",")
		get_tree().create_timer(1.0, false).timeout.connect(func() -> void:
			var water := get_tree().get_first_node_in_group("pool_water") as PoolWater
			if water:
				water.splash(Vector2(at[0].to_float(), at[1].to_float()), 1.0))
	elif arg == "--lure":
		get_tree().create_timer(1.0, false).timeout.connect(Game.director.debug_lure)
	elif arg == "--despawn" or arg.begins_with("--despawn="):
		_debug_despawn(arg.substr(10))
	elif arg.begins_with("--pool="):
		var water := get_tree().get_first_node_in_group("pool_water") as PoolWater
		if water:
			water.debug_stage = "" if arg == "--pool=off" else arg.substr(7)
	elif arg == "--pocket":
		Game.player.give_compass()
		for page in HotelMap.PAGES:
			Game.player.add_map_page(page["id"])
		Game.player.add_key("zimmer_18")
	elif arg.begins_with("--bag-menu"):
		# erst nach den übrigen Parametern (--bag, --flashlight) öffnen
		Game.player.debug_open_bag.call_deferred(arg.substr(11).to_int() - 1 if arg.begins_with("--bag-menu=") else -1)
	elif arg.begins_with("--bag"):
		var kinds := {"süßes": Item.Kind.SWEETS, "suesses": Item.Kind.SWEETS, "cola": Item.Kind.SODA_CAN, "limo": Item.Kind.SODA_CAN,
			"zierkürbis": Item.Kind.MINI_PUMPKIN, "zierkuerbis": Item.Kind.MINI_PUMPKIN, "kerze": Item.Kind.CANDLE,
			"messer": Item.Kind.KNIFE, "batterie": Item.Kind.BATTERY, "birne": Item.Kind.BULB, "uv": Item.Kind.UV_FILTER,
			"würfel": Item.Kind.LOADED_DICE, "wuerfel": Item.Kind.LOADED_DICE, "becher": Item.Kind.DICE_CUP,
			"streichhölzer": Item.Kind.MATCHBOX, "streichhoelzer": Item.Kind.MATCHBOX, "dartpfeile": Item.Kind.DARTS, "salz": Item.Kind.SALT}
		var names := (arg.substr(6) if arg.begins_with("--bag=") else "süßes,cola,zierkürbis,batterie").split(",", false)
		for what in names:
			if not kinds.has(what):
				Game.say("Tasche: " + ", ".join(kinds.keys()), 3.0)
				return true
			var item := Item.create(kinds[what], what if what in ["cola", "limo"] else "")
			if Game.player.bag.size() < Player.BAG_SLOTS:
				Game.player.bag_add(item)
			else:
				item.free()
	elif arg.begins_with("--flashlight"):
		var uv := arg == "--flashlight=uv"
		var lamp := Item.create(Item.Kind.FLASHLIGHT, "c=1;on" + (";uv;m=uv" if uv else ""))
		Game.player.drop_held()
		Game.player.receive_item(lamp)
	elif arg.begins_with("--deco="):
		var kinds := {"gespenst": Item.Kind.SHEET_GHOST, "lichter": Item.Kind.LIGHT_STRING, "netz": Item.Kind.COBWEB,
			"laub": Item.Kind.LEAVES, "zierkürbis": Item.Kind.MINI_PUMPKIN, "zierkuerbis": Item.Kind.MINI_PUMPKIN,
			"fledermaus": Item.Kind.BAT_GARLAND, "spinne": Item.Kind.SPIDER, "totenkopf": Item.Kind.SKULL, "besen": Item.Kind.BROOM,
			"kerze": Item.Kind.CANDLE}
		var what := arg.substr(7).trim_suffix(",g")
		if not kinds.has(what):
			Game.say("Deko: gespenst, lichter, netz, laub, zierkürbis, fledermaus, spinne, totenkopf, besen oder kerze", 3.0)
			return true
		Game.player.drop_held()
		Game.player.receive_item(Item.create(kinds[what], "lit" if what == "kerze" else ""))
		if arg.ends_with(",g"):
			get_tree().create_timer(1.0).timeout.connect(func() -> void: Game.player.drop_held())
	elif arg == "--fall" or arg.begins_with("--fall="):
		# Kürbis fällt 1,5 m vor dir aus h m Höhe (Standard 4) – ab 3 m zerplatzt er (5.8); dahinter Sorte oder „mini“,
		# „kerze“ (zerbricht ab 2 m) oder „birne“ (platzt ab 1,5 m)
		var parts := arg.substr(7).split(",") if arg.length() > 7 else PackedStringArray()
		var height := parts[0].to_float() if parts.size() > 0 and parts[0] != "" else 4.0
		var sort := parts[1] if parts.size() > 1 else ""
		get_tree().create_timer(1.0).timeout.connect(func() -> void:   # nach --pos/--tp
			var kinds := {"mini": Item.Kind.MINI_PUMPKIN, "kerze": Item.Kind.CANDLE, "birne": Item.Kind.BULB}
			var pumpkin := Item.create(kinds[sort], "lit" if sort == "kerze" else "") if kinds.has(sort) else Item.create(Item.Kind.PUMPKIN, sort)
			Game.player.get_parent().add_child(pumpkin)
			var front := -Game.player.global_basis.z
			pumpkin.global_position = Game.player.global_position + Vector3(front.x, 0, front.z).normalized() * 1.5 + Vector3.UP * height
			if Game.tracing:
				print("[Fall] %s fällt aus %.1f m bei %s" % [pumpkin.display_name, height, pumpkin.global_position]))
	elif arg == "--wurf" or arg.begins_with("--wurf="):
		# Werfen (3.13): nach 1 s einen Gegenstand in die Hand und mit Kraft k (0 … 1, Standard 1) in Blickrichtung werfen –
		# Standard ein Kürbis; Sorte aus PumpkinKinds, mini, kerze (brennend), birne, kaffee, tee, dose, messer, taschenlampe
		var parts := arg.substr(7).split(",") if arg.length() > 7 else PackedStringArray()
		var power := clampf(parts[0].to_float(), 0.0, 1.0) if parts.size() > 0 and parts[0] != "" else 1.0
		var what := parts[1] if parts.size() > 1 else ""
		get_tree().create_timer(1.0).timeout.connect(func() -> void:   # nach --pos/--tp
			var kinds := {"mini": Item.Kind.MINI_PUMPKIN, "zierkuerbis": Item.Kind.MINI_PUMPKIN, "kerze": Item.Kind.CANDLE,
				"birne": Item.Kind.BULB, "kaffee": Item.Kind.COFFEE, "tee": Item.Kind.TEA, "dose": Item.Kind.SODA_CAN,
				"messer": Item.Kind.KNIFE, "taschenlampe": Item.Kind.FLASHLIGHT}
			var item := Item.create(kinds[what], "lit" if what == "kerze" else "") if kinds.has(what) \
				else Item.create(Item.Kind.PUMPKIN, "" if what in ["", "kuerbis", "kürbis"] else what)
			Game.player.drop_held()
			Game.player.receive_item(item)
			get_tree().create_timer(0.3).timeout.connect(func() -> void: Game.player.throw_held(power)))
	elif arg == "--kuerbis" or arg.begins_with("--kuerbis="):
		# Kürbismodelle (PumpkinModel, 5.8): glatt und alle Fratzen mit Kerze in einer Reihe vor dir – bzw. nur Fratze n
		var only := clampi(arg.substr(10).to_int(), 1, PumpkinModel.FACES) if arg.begins_with("--kuerbis=") else 0
		get_tree().create_timer(1.0).timeout.connect(func() -> void:   # nach --pos/--tp
			var faces: Array = [only] if only > 0 else range(PumpkinModel.FACES + 1)
			var front := -Game.player.global_basis.z
			front = Vector3(front.x, 0, front.z).normalized()
			var side := front.cross(Vector3.UP)
			for i in faces.size():
				var f: int = faces[i]
				var pumpkin := Item.create(Item.Kind.PUMPKIN) if f == 0 else Item.create(Item.Kind.CARVED_PUMPKIN, "f=%d" % f)
				Game.player.get_parent().add_child(pumpkin)
				pumpkin.global_position = Game.player.global_position + front * 1.5 + side * (i - (faces.size() - 1) / 2.0) * 0.5 					+ Vector3.UP * 0.05
				pumpkin.rotation.y = atan2(-front.x, -front.z)
			Game.player.head.rotation.x = -0.6)   # Blick hinunter auf die Reihe
	elif arg == "--kerzen" or arg == "--kerzen=nah":
		# Kerzenmodelle (CandleModel): Gegenstand brennend und aus, rot und weiß auf dem Teller (brennend) in einer Reihe –
		# nah: weiß auf dem Teller 30 cm vor dem Auge, die Flamme auf Augenhöhe, daneben rot ohne Teller
		get_tree().create_timer(1.0).timeout.connect(func() -> void:   # nach --pos/--tp
			var front := -Game.player.global_basis.z
			front = Vector3(front.x, 0, front.z).normalized()
			var side := front.cross(Vector3.UP)
			if arg == "--kerzen=nah":
				Game.player.head.rotation.x = 0.0
				var eye := Game.player.camera.global_position
				for red in [false, true]:
					var holder := Node3D.new()
					Game.player.get_parent().add_child(holder)
					holder.global_position = eye + front * (0.3 if not red else 0.38) + side * (0.0 if not red else 0.11) \
						- Vector3.UP * (CandleModel.WICK_TOP + CandleModel.PLATE_FLOOR + 0.012)
					var wick := CandleModel.build(holder, red, not red)
					CandleModel.flame(holder, Vector3(0, wick, 0))
				return
			for i in 4:
				var at := Game.player.global_position + front * 0.8 + side * (i - 1.5) * 0.2 + Vector3.UP * 0.02
				if i < 2:
					var candle := Item.create(Item.Kind.CANDLE, "lit" if i == 0 else "")
					Game.player.get_parent().add_child(candle)
					candle.global_position = at
					continue
				var holder := Node3D.new()
				Game.player.get_parent().add_child(holder)
				holder.global_position = at
				var wick := CandleModel.build(holder, i == 2, true)
				CandleModel.flame(holder, Vector3(0, wick, 0))
			Game.player.head.rotation.x = -0.75)   # Blick hinunter auf die Reihe
	elif arg.begins_with("--show="):
		Game.player.debug_show = arg.substr(7)
	elif arg == "--winded":
		Game.player.stamina = 0.0
		Game.player.winded = true
	elif arg == "--sprint":
		Game.player.debug_sprint = true
	elif arg.begins_with("--bold="):
		Game.director.boldness = arg.substr(7).to_float()
	elif arg.begins_with("--friend="):
		var friend := _guest(arg.substr(9))
		if friend:
			friend.relation = 65.0   # befreundet (6.3)
	elif arg.begins_with("--relation="):
		# Beziehung setzen; für die Extreme werden die nötigen Taten gleich mit eingetragen (6.3)
		var rel := arg.substr(11).split(",")
		var g := _guest(rel[0])
		if g and rel.size() > 1:
			g.relation = clampf(rel[1].to_float(), -100.0, 100.0)
			if g.relation >= 80.0:
				g.deeds.merge({"games": Social.BOND_GAMES, "gifts_to": Social.BOND_GIFTS_TO, "gifts_from": Social.BOND_GIFTS_FROM}, true)
			elif g.relation <= -80.0:
				g.deeds.merge({"hostile": Social.FEUD_HOSTILE, "revenge": Social.FEUD_REVENGE}, true)
	elif arg.begins_with("--follow="):
		var follower := _guest(arg.substr(9))
		if follower:
			_put_in_front(follower, -2.0, false)   # hinter dir
			follower.start_follow()
	elif arg.begins_with("--visit="):
		var visitor := _guest(arg.substr(8))
		if visitor:
			Game.social.start_visit(visitor)
	elif arg.begins_with("--punch="):
		# Gast vor den Spieler stellen und zweimal zuschlagen (Nachfrage + Schlag)
		var target := _guest(arg.substr(8))
		if target:
			_put_in_front(target, 1.0)
			target._set_idle(5.0)
			get_tree().create_timer(1.0).timeout.connect(func() -> void:
				Game.player.debug_punch(target)
				Game.player.debug_punch(target))
	elif arg.begins_with("--attack="):
		var attacker := _guest(arg.substr(9))
		if attacker:
			_put_in_front(attacker, 4.0, false)
			get_tree().create_timer(1.0).timeout.connect(attacker.start_attack)
	elif arg.begins_with("--kill="):
		var kill_parts := arg.substr(7).split(",")
		var victim := _guest(kill_parts[0])
		if victim == null:
			return true
		var cause := ""
		for part in kill_parts.slice(1):
			cause = {"geist": "ghost", "kuerbis": "pumpkin", "kürbis": "pumpkin"}.get(part, cause)
		var instant := "leiche" in kill_parts or "weg" in kill_parts
		if cause != "" or instant:
			# Sofort tot – geist/kuerbis: vor dir erwürgt bzw. erschlagen, die Leiche bleibt liegen (Todesmeldung, „… – tot“) ·
			# leiche/weg: wo er gerade ist (hin: vor dir), liegt da bzw. ist verschwunden · blut/ohneblut: Lache und Spritzer
			var corpse := "leiche" in kill_parts or (cause != "" and not "weg" in kill_parts)
			var blood := ("blut" in kill_parts or cause == "pumpkin") and not "ohneblut" in kill_parts
			var here := cause != "" or "hin" in kill_parts
			get_tree().create_timer(1.5 if here else 0.1).timeout.connect(func() -> void:
				if victim.dead:
					return
				if here:
					_put_in_front(victim, 1.3)
					Game.player.head.rotation.x = deg_to_rad(-45.0)
				_debug_kill(victim, cause if cause != "" else "ghost" if corpse else "monster", corpse, blood))
			return true
		Game.director.attacks = MonsterDirector.HARMLESS_ATTACKS + 1   # wirklich holen
		get_tree().create_timer(3.0).timeout.connect(func() -> void:
			if victim.dead:
				return
			Game.monster.spawn_at(victim.global_position + Vector3(1, 0, 0))
			Game.director.phase = MonsterDirector.Phase.ACTIVE
			Game.director.kill_guest(victim, null))
	elif arg.begins_with("--wound="):
		# Überlebender (Spielkonzept 6.17): gast,scratch|axe|choke[,hin] – verletzt wie nach dem Angriff; hin: er liegt
		# bzw. steht vor dir (mit --talk=gast erzählt er als Zeuge)
		var parts := arg.substr(8).split(",")
		var hurt := Game.social.find_guest(parts[0])
		if hurt == null or parts.size() < 2 or not Wounds.KINDS.has(parts[1]):
			Game.say("--wound=gast,scratch|axe|choke[,hin]", 3.0)
		else:
			hurt.wound_by(parts[1])
			if "hin" in parts:
				_put_in_front(hurt, 1.4)
				hurt.wound_bed = 0.0   # zum Ansehen: steht vor dir statt im Bett
				hurt._set_idle(30.0)
				Game.player.head.rotation.x = deg_to_rad(-28.0 if parts[1] == "axe" else -5.0)
	elif arg == "--steal-test":
		# Spieler nimmt Ednas Deko unbemerkt (für Schuld-Test)
		for node in get_tree().get_nodes_in_group("items"):
			if node.owner_id == "edna":
				Game.player.try_pick_up(node)
				break
	elif arg.begins_with("--enemy="):
		var enemy := _guest(arg.substr(8))
		if enemy:
			enemy.relation = -65.0   # verfeindet (6.3)
	elif arg.begins_with("--player-deco="):
		var xz := arg.substr(14).split(",")
		var deco := Item.create(Item.Kind.CARVED_PUMPKIN)
		deco.owner_id = "player"
		deco.position = Vector3(xz[0].to_float(), 0.02, xz[1].to_float())
		add_child(deco)
	elif arg.begins_with("--dice="):
		var opponent := _guest(arg.substr(7))
		if opponent == null:
			return true
		get_tree().create_timer(0.5).timeout.connect(func() -> void:
			Game.dice.start(opponent, {"money": 3, "item": false}))
	elif arg.begins_with("--chess="):
		var chess_opponent := _guest(arg.substr(8))
		if chess_opponent == null:
			return true
		get_tree().create_timer(0.5).timeout.connect(func() -> void:
			Game.chess.start(chess_opponent, {"money": 3, "item": false}))
	elif arg == "--darts" or arg.begins_with("--darts="):
		var dart_opponent := _guest(arg.substr(8)) if arg.begins_with("--darts=") else null
		if arg.begins_with("--darts=") and dart_opponent == null:
			return true
		get_tree().create_timer(0.5).timeout.connect(func() -> void:
			Game.player.global_position = Game.darts.board.throw_spot(false)
			if dart_opponent:
				dart_opponent.global_position = Game.darts.board.guest_seat.global_position + Vector3(0.5, 0.05, 0.8)
				Game.darts.start(dart_opponent, {"money": 3, "item": false})
			else:
				Game.darts.practice())
	elif arg.begins_with("--challenge="):
		var challenger := _guest(arg.substr(12).split(",")[0])
		if challenger:
			var game := arg.get_slice(",", 1) if "," in arg else "dice"
			Game.social.challenge(challenger, game if game in ["chess", "darts"] else "dice")
	elif arg == "--autoplay":
		_autoplay = true
	elif arg.begins_with("--cat="):
		# Katze vor den Spieler setzen (sitzt, zum Streicheln) – mit ",tragen" gleich auf den Arm
		var parts := arg.substr(6).split(",")
		for cat in get_tree().get_nodes_in_group("cats"):
			if cat.id == parts[0]:
				cat.place_in_front_of(Game.player)
				if parts.size() > 1 and parts[1] == "tragen":
					cat.affection = maxi(cat.affection, HotelCat.CARRY_TRUST)
					Game.player.drop_held()
					cat.pick_up(Game.player)
	elif arg.begins_with("--pumpkin=ankündigung"):
		# Ankündigung (4.19): rote Lampen, Melodie, Kinder singen – in s Sekunden (Standard 20) kommt er übers Dach
		var wait := arg.get_slice(",", 1).to_float() if "," in arg else 20.0
		get_tree().create_timer(0.5, false).timeout.connect(func() -> void: Game.pumpkin.debug_announce(wait))
	elif arg == "--pumpkin=dach":
		get_tree().create_timer(0.5, false).timeout.connect(Game.pumpkin.debug_roof)   # NavMesh muss erst stehen
	elif arg == "--pumpkin=garten":
		get_tree().create_timer(0.5, false).timeout.connect(Game.pumpkin.debug_garden)   # NavMesh muss erst stehen
	elif arg.begins_with("--pumpkin=jagd"):
		_debug_pumpkin_hunt(arg.substr(14).trim_prefix(","))
	elif arg.begins_with("--pumpkin"):
		PumpkinMan.spawn_in_front_of(Game.player, arg.substr(10) if arg.begins_with("--pumpkin=") else "walk")
	elif arg == "--wallblood" or arg == "--wallblood=smear":
		var kind := "wall_smear" if arg.ends_with("smear") else "wall_splatter"
		# Ein Stück vor der Wand im Blick ansetzen – dann ist sie die nächste
		var cam := Game.player.camera
		var ahead := -cam.global_basis.z
		var hit := cam.get_world_3d().direct_space_state.intersect_ray(
			PhysicsRayQueryParameters3D.create(cam.global_position, cam.global_position + ahead * 6.0, 1))
		var near: Vector3 = hit.get("position", Vector3.ZERO) - ahead * 0.4
		near.y = Game.player.global_position.y   # Boden unter dem Spieler – die Spur sitzt in Höhe über dem Boden
		if hit.is_empty() or Game.traces.add_wall_blood(near, kind) == null:
			Game.say("Keine Wand im Blick.", 2.5)
	elif arg == "--costumes" or arg.begins_with("--costumes="):
		Costume.force = arg.substr(11) if arg.begins_with("--costumes=") else "all"
	elif arg == "--disguise":
		Game.player.set_disguised(true)
	elif arg == "--maske" or arg.begins_with("--maske="):
		_debug_masks(arg.substr(8) if arg.begins_with("--maske=") else "")
	elif arg.begins_with("--drunk="):
		var parts := arg.substr(8).split(",")
		var glasses := parts[0].to_int()
		var who: Guest = _guest(parts[1]) if parts.size() > 1 else null
		if parts.size() > 1 and who == null:
			return true   # nicht stattdessen selbst trinken
		for i in glasses:
			if who:
				who.drink()
			else:
				Game.player.drink(i < glasses - 1)
	elif arg.begins_with("--weather="):
		# Wetter sofort (7.8): klar, regen, gewitter (gleich in voller Stärke) oder blitz (ein Blitz, ggf. mit Gewitter)
		match arg.substr(10):
			"klar":
				Game.weather.set_weather(Weather.Kind.CLEAR, true)
			"regen":
				Game.weather.set_weather(Weather.Kind.RAIN, true)
			"gewitter":
				Game.weather.set_weather(Weather.Kind.STORM, true)
			"blitz":
				if Game.weather.kind != Weather.Kind.STORM:
					Game.weather.set_weather(Weather.Kind.STORM, true)
				get_tree().create_timer(3.0).timeout.connect(Game.weather.lightning)   # erst, wenn es regnet
			_:
				Game.say("Wetter: klar, regen, gewitter oder blitz", 3.0)
	elif arg == "--party" or arg.begins_with("--party="):
		var host := arg.substr(8) if arg.begins_with("--party=") else "player"
		if host == "player" or _guest(host):
			Game.social.start_party(host)
	elif arg.begins_with("--look="):
		var parts := arg.substr(7).split(",")
		var guest := _guest(parts[0])
		if guest:
			_debug_look(guest, parts[1] if parts.size() > 1 else "")
	elif arg.begins_with("--shock="):
		var parts := arg.substr(8).split(",")
		var shocked := _guest(parts[0])
		if shocked:
			_debug_shock(shocked, parts[1] if parts.size() > 1 else "blood")
	elif arg.begins_with("--talk="):
		var partner := _guest(arg.substr(7))
		if partner == null:
			return true
		var after_shock := Array(OS.get_cmdline_user_args()).any(func(a: String) -> bool: return a.begins_with("--shock="))
		if not after_shock:
			Game.player.global_position = partner.global_position + Vector3(0, 0, -1.4)
			Game.player.rotation.y = 0.0
		get_tree().create_timer(8.0 if after_shock else 1.0).timeout.connect(func() -> void:
			if after_shock:   # erst erschrecken lassen, dann hingehen
				var front := -partner.global_transform.basis.z
				Game.player.global_position = partner.global_position + front * 1.4
			_face_toward(partner.global_position)
			Game.dialog.open(partner))
	elif arg.begins_with("--bitte="):
		var parts := arg.substr(8).split(",")
		get_tree().create_timer(0.5).timeout.connect(Game.social.requests.debug.bind(parts))
	elif arg.begins_with("--gespraech="):
		var parts := arg.substr(12).split(",")
		get_tree().create_timer(0.5).timeout.connect(Game.social.talk.debug.bind(parts))
	elif arg == "--ghost=flur":
		Game.ghost.debug_summon_hall()
	elif arg == "--spinne" or arg.begins_with("--spinne="):
		Game.spiders.debug(arg.substr(9) if arg.length() > 9 else "")
	elif arg == "--fledermaus" or arg.begins_with("--fledermaus="):
		Game.bats.debug_show(arg.substr(13) if arg.length() > 13 else "")
	elif arg == "--ghost=stunde" or arg.begins_with("--ghost=stunde,"):
		Game.ghost.debug_ghost_hour(maxi(1, arg.get_slice(",", 1).to_int()) if "," in arg else 1)
	elif arg == "--ghost=tür" or arg == "--ghost=tuer":
		if Game.ghost.debug_summon_door() and "--answer" in OS.get_cmdline_user_args():
			get_tree().create_timer(4.0).timeout.connect(Game.ghost.debug_open_door)   # du machst nach 4 s auf
	elif arg == "--ghost=schrank":
		# kommt durch den Vorhang deines Zimmers herein – du versteckst dich gleich in dessen Schrank
		var room: Dictionary = Game.director.rooms.get(Game.social.builder.room_at(Game.player.global_position), {})
		var wardrobe: HideSpot = null
		for spot in room.get("spots", []):
			if (spot as HideSpot).type == HideSpot.Type.WARDROBE:
				wardrobe = spot
		if wardrobe == null:
			Game.say("Lakengeist: Hier ist kein Schrank.", 2.5)
		elif Game.ghost.debug_summon(4):
			get_tree().create_timer(1.5).timeout.connect(func() -> void:
				if Game.player.hiding == null:
					Game.player.enter_hide(wardrobe))
	elif arg == "--dusche=nacht":
		# erst nach 3 s – mit --sleep=bett schläfst du dann schon und wachst vom Wasser auf
		get_tree().create_timer(3.0).timeout.connect(Game.shower_scare.debug_night)
	elif arg == "--dusche" or arg.begins_with("--dusche="):
		Game.shower_scare.debug(arg.substr(9) if arg.length() > 9 else "")
	elif arg == "--salz" or arg.begins_with("--salz="):
		_debug_salt((arg.substr(7) if arg.length() > 7 else "").split(","))
	elif arg.begins_with("--awake="):
		# so viele Nächte ohne Schlaf (zählen erst nach dem ersten Angriff, also gilt der als geschehen)
		Game.director.first_attack_done = true
		Game.player.nights_awake = arg.substr(8).to_float()
	elif arg == "--sleep":
		Game.social.debug_sleep()
	elif arg == "--hoerer":
		Game.phones.home_phone.set_off_hook(true)
	elif arg.begins_with("--sleep=bett"):
		# alle Gäste sofort im Bett, du schläfst h Stunden im Bett von Zimmer 13
		Game.social.debug_sleep(true)
		if arg.contains(","):
			Game.player.sleep_hours = clampi(arg.get_slice(",", 1).to_int(), Player.SLEEP_HOURS.x, Player.SLEEP_HOURS.y)
		# nach 1,5 s, damit NavMesh und --doll stehen (der Zeitsprung braucht Wege)
		get_tree().create_timer(1.5).timeout.connect(func() -> void:
			for spot in Game.director.rooms[LevelBuilder.PLAYER_ROOM]["spots"]:
				if (spot as HideSpot).own_bed:
					Game.player.start_sleep(spot))
	elif arg.begins_with("--ghost="):
		Game.ghost.debug_summon(arg.substr(8).to_int())
	elif arg == "--warn":
		Game.director.start_warning()
	elif arg.begins_with("--prank="):
		var prank := arg.substr(8).split(",")
		var prank_room := Game.director.room_by_label(prank[1]) if prank.size() > 1 else LevelBuilder.PLAYER_ROOM
		get_tree().create_timer(1.5).timeout.connect(func() -> void: Game.social.pranks.debug(prank[0], prank_room))
	elif arg == "--doll=kind":
		get_tree().create_timer(1.0).timeout.connect(func() -> void: Game.doll.debug_fetch())
	elif arg == "--doll" or arg.begins_with("--doll="):
		# Angriff mit Puppe in s Sekunden – nach 1 s, damit Gäste und NavMesh stehen
		var parts := arg.substr(7).split(",") if arg.length() > 7 else PackedStringArray()
		var seconds := parts[0].to_float() if parts.size() > 0 and parts[0] != "" else 20.0
		Game.director.debug_doom = Game.director.room_by_label(parts[1]) if parts.size() > 1 else ""
		get_tree().create_timer(1.0).timeout.connect(func() -> void: Game.director.debug_doll(seconds))
	elif arg.begins_with("--attacks="):
		# so viele Angriffe gab es schon (über 2 = gefährlich, ob es holt, würfelt _choose_intent nach Tag)
		Game.director.first_attack_done = true
		Game.director.attacks = arg.substr(10).to_int()
	elif arg == "--siegerehrung" or arg == "--siegerehrung=ohne":
		# Siegerehrung (2.5) – nach 1 s, damit NavMesh und Gäste stehen
		get_tree().create_timer(1.0).timeout.connect(func() -> void: Game.contest.debug_ceremony(arg.ends_with("ohne")))
	elif arg == "--grinch" or arg == "--grinch=tot":
		# nach 1 s, damit NavMesh und Gäste stehen
		get_tree().create_timer(1.0).timeout.connect(func() -> void: Game.social.grinch.debug(arg.ends_with("tot")))
	elif arg == "--brett" or arg == "--brett=nachher":
		Game.contest.debug_board(arg.ends_with("nachher"))
	elif arg == "--brief":
		Game.contest.debug_letter()
	elif arg == "--zettel":
		Game.contest.debug_note()
	elif arg == "--notizbuch":
		get_tree().create_timer(0.5).timeout.connect(Game.notebook.debug_fill)   # nach den Gästen
	elif arg == "--gesehen":
		Game.notebook.give(true)
		for id in IconArt.THREAT_ORDER:
			Game.notebook.note_seen(id)
	elif arg == "--tot" or arg.begins_with("--tot="):
		var by: String = {"geist": "ghost", "kuerbis": "pumpkin", "kürbis": "pumpkin"}.get(arg.substr(6), "monster")
		get_tree().create_timer(1.0).timeout.connect(func() -> void:
			if Game.game_over:
				return
			Game.game_over = true
			Game.player.dead = true
			Game.player.killed_by = by
			if Game.hud:
				Game.hud.visible = false
			Game.player_died.emit())
	elif arg == "--trick=13" or arg.begins_with("--trick=13,"):
		# Ein Kind steht vor Zimmer 13 (Tür auf) – mit „,n“ gibst du ihm n Süßigkeiten, eine je 1,5 s
		var give := arg.substr(11).to_int() if arg.begins_with("--trick=13,") else 0
		get_tree().create_timer(1.0).timeout.connect(func() -> void: Game.social.debug_trick_at_13(give))
	elif arg == "--trick" or arg.begins_with("--trick="):
		var kid: Guest = Game.social.find_guest(arg.substr(8)) if arg.begins_with("--trick=") else null
		if kid == null:
			var kids := Game.social.living_guests().filter(func(g: Guest) -> bool: return g.is_child())
			kid = kids.pick_random() if not kids.is_empty() else null
		if kid == null or not kid.is_child() or not Game.social.start_round(kid):
			Game.say("Süßes oder Saures: kein Kind oder keine Gästetür in der Nähe", 3.0)
	elif arg == "--decorate" or arg.begins_with("--decorate="):
		# Schmück-Aktion sofort (Spielkonzept 5.9); „lobby“: in der Lobby; „allein“: ein Gast trägt allein ein Stück
		# Deko in sein Zimmer (mit „lobby“ in die Lobby); „hin“: Spieler vor die Stelle, Blick zur Wand
		var parts := arg.substr(11).split(",") if arg.begins_with("--decorate=") else PackedStringArray()
		if "allein" in parts:   # der Weg zur Kiste braucht das fertige NavMesh
			get_tree().create_timer(1.5).timeout.connect(func() -> void: _debug_decorate(parts))
		else:
			_debug_decorate(parts)
	elif arg == "--search" or arg.begins_with("--search="):
		# Deko-Suche (Spielkonzept 5.9) – der Weg zum Fundort braucht das fertige NavMesh
		var parts := arg.substr(9).split(",") if arg.begins_with("--search=") else PackedStringArray()
		get_tree().create_timer(1.5).timeout.connect(func() -> void: _debug_search(parts))
	elif arg.begins_with("--cook="):
		_debug_cook(arg.substr(7).split(","))
	elif arg.begins_with("--kaffee="):
		_debug_coffee(arg.substr(9).split(","))
	elif arg.begins_with("--tee="):
		_debug_coffee(arg.substr(6).split(","), true)
	elif arg == "--mess" or arg == "--mess=wachs":
		get_tree().create_timer(1.5, false).timeout.connect(func() -> void: Game.social.tidying.debug(arg.ends_with("wachs")))
	elif arg.begins_with("--rival="):
		# Freund meines Feindes (6.16): gast1 und gast2 sind verfeindet, du wirst gleich mit gast1 befreundet
		var ids := arg.substr(8).split(",")
		var a := Game.social.find_guest(ids[0])
		var b := Game.social.find_guest(ids[1]) if ids.size() > 1 else null
		if a and b:
			Game.social.pals.add_feud(a, b)
			b.global_position = Game.player.global_position - Game.player.global_transform.basis.z * 2.5
			b._set_idle(90.0)
			Game.social.change_relation(a, 80.0)
	elif arg.begins_with("--pals="):
		_debug_pals(arg.substr(7).split(","))
	elif arg == "--knock":
		# Klopfen an Zimmer 13 vorbereiten (Spieler steht im Zimmer, Monster ist unterwegs)
		Game.director.first_attack_done = true
		Game.player.global_position = (Game.social.builder.rooms[LevelBuilder.PLAYER_ROOM]["center"] as Vector3) + Vector3(0, 0.05, -0.6)
		Game.monster.spawn_at(Game.social.builder.wander_points[8] + Vector3(0, 0.05, 0))
		Game.social._knock_cooldown = 1.0
		Game.social.debug_fake_knock = "--knock-fake" in OS.get_cmdline_user_args()
		if "--answer" in OS.get_cmdline_user_args():
			# nach 4 s öffnet der Spieler die Tür
			get_tree().create_timer(4.0).timeout.connect(func() -> void:
				(Game.social.builder.rooms[LevelBuilder.PLAYER_ROOM]["door"] as Door).set_open(true))
	elif arg.begins_with("--call=") or arg.begins_with("--dial="):
		# Telefon: Spieler steht in Zimmer 13 vor dem Schreibtisch und sieht auf den Apparat
		var phone_pos := Game.phones.home_phone.global_position
		Game.player.global_position = Vector3(phone_pos.x, 0.05, phone_pos.z + 0.9)
		Game.player.rotation.y = 0.0
		Game.player.head.rotation.x = -0.75
		var value := arg.substr(7)
		get_tree().create_timer(1.0).timeout.connect(func() -> void:
			if arg.begins_with("--call="):
				Game.phones.debug_call(value)
				if "--answer" in OS.get_cmdline_user_args():
					get_tree().create_timer(4.0).timeout.connect(func() -> void:
						Game.phones.answer(Game.phones.home_phone))
			else:
				Game.phones.debug_dial(value))
	elif arg == "--trace":
		_trace = true
		Game.tracing = true
		Game.message_posted.connect(func(text: String, _d: float, _icon: String) -> void: print("  » " + text.replace("
", " ")))
	elif arg.begins_with("--noise="):
		var kind := arg.substr(8)
		var timer := Timer.new()
		timer.wait_time = 6.0
		timer.autostart = true
		timer.timeout.connect(func() -> void:
			if Game.player:
				Game.noise(kind, Game.player.global_position, Game.player))
		add_child(timer)
	elif arg == "--debug":
		Game.hud.debug_enabled = true
	elif arg.begins_with("--day="):
		# zu einem Tag im Oktober springen (1–31), dort 15 Uhr
		Game.director.elapsed = Calendar.at(clampi(arg.substr(6).to_int(), 1, Calendar.HALLOWEEN), Calendar.START_HOUR)
	elif arg == "--rot" or arg.begins_with("--rot="):
		# alle Kürbisse kurz vor welk bzw. gleich in dieser Stufe (Spielkonzept 5.10)
		var target: float = {"welk": Item.ROT_WILT + 0.01, "eingefallen": Item.ROT_SAG + 0.01}.get(arg.substr(6), Item.ROT_WILT)
		var count := 0
		for node in get_tree().get_nodes_in_group("items"):
			var item := node as Item
			if item.rot_at < INF:
				var life := Item.ROT_CARVED if item.kind == Item.Kind.CARVED_PUMPKIN else Item.ROT_WHOLE
				item.rot_at = Game.director.elapsed + life * (1.0 - target) + (10.0 if arg == "--rot" else 0.0)
				item._rot_timer = 0.0
				count += 1
		Game.say("%d Kürbisse altern" % count, 2.0)
	elif arg == "--verwaschen" or arg == "--verwaschen=schleier":
		# Regen sofort, Flecken draußen verwaschen schneller (4.13, RainVeil) – schleier: gleich ganz
		RainVeil.debug_speed = 10000.0 if arg.ends_with("schleier") else 10.0
		Game.weather.set_weather(Weather.Kind.RAIN, true)
	elif arg.begins_with("--uhr="):
		# Uhrzeit am aktuellen Tag (hh oder hh:mm); vor der Anreise am 1. Oktober geht es nicht
		var hm := arg.substr(6).split(":")
		var hour := hm[0].to_float() + (hm[1].to_float() / 60.0 if hm.size() > 1 else 0.0)
		Game.director.elapsed = maxf(0.0, Calendar.at(Calendar.day_of(Game.director.elapsed), hour))
	elif arg.begins_with("--bulb-thief="):
		# Gast klaut sofort eine Glühbirne aus Zimmer 13
		var thief := _guest(arg.substr(13))
		var lamp: Lamp = thief._bulb_to_steal(true) if thief else null
		if lamp:
			thief._steal_lamp = lamp
			thief._walk_to(Vector3(lamp.global_position.x, 0, lamp.global_position.z) + thief._toward_room(lamp), Guest.State.STEAL)
	elif arg.begins_with("--diary="):
		# wie am Tagebuch speichern (nach 2 s)
		var slot := arg.substr(8).to_int()
		get_tree().create_timer(2.0).timeout.connect(func() -> void:
			var ok := SaveManager.save_to(slot, SaveManager.diary_sentence(), get_viewport().get_texture().get_image())
			print("[diary] Slot %d gespeichert: %s – „%s“" % [slot, ok, SaveManager.diary_sentence()]))
	elif arg.begins_with("--menu="):
		# Menü für Screenshots öffnen: pause, diary, diary_pages, settings, load, help, achievements (controls: alter Name der Hilfe)
		var which := "help" if arg.substr(7) == "controls" else arg.substr(7)
		get_tree().create_timer(1.0).timeout.connect(func() -> void:
			if which in ["diary", "diary_pages"]:
				Game.menus.open_diary()
				if which == "diary_pages":   # die aufgeschriebenen Meilensteine, letzte Seite (3.10)
					Game.menus.call("_show_diary_pages", -1)
			else:
				Game.menus.open_pause()
				if which != "pause":
					Game.menus.call("_show_" + which))
	elif arg.begins_with("--erfolg=") or arg == "--erfolge-zurueck":
		return Game.achievements.debug_command(arg)
	elif arg == "--figur" or arg == "--figur=schnell":
		_start_creation(0, arg.ends_with("schnell"))
	elif arg == "--savetest":
		get_tree().create_timer(6.0).timeout.connect(_save_test)
	elif arg == "--navcheck":
		get_tree().create_timer(2.0).timeout.connect(_nav_check)
	elif _debug_omens(arg):
		pass
	else:
		return false
	return true


## Vorzeichen und Spuk (Spielkonzept 4.25–4.31, 5.14–5.18, 6.21) – Wert nach „=“, leer ohne. false = kein solcher Befehl.
## Was das NavMesh braucht (Katze, Ratten), läuft nach 1 s.
func _debug_omens(arg: String) -> bool:
	var cmd := arg.get_slice("=", 0)
	var value := arg.substr(cmd.length() + 1) if "=" in arg else ""
	match cmd:
		"--kraehen":
			Game.crows.debug_show(value)
		"--ratten":
			get_tree().create_timer(1.0).timeout.connect(Game.rats.debug.bind(value))
		"--hund":
			Game.weather.howl(1.0)
		"--kesselkatze":
			get_tree().create_timer(1.0).timeout.connect(Game.boiler_cat.debug_show)
		"--spiegel":
			get_tree().create_timer(0.5).timeout.connect(Game.mirror_omens.debug.bind(value))
		"--strom":
			Game.power_cut.debug(value)
		"--albtraum":
			Game.nightmare.debug()
		"--vogelscheuche":
			Game.scarecrow.debug_show(value)
		"--kind-zu-viel":
			get_tree().create_timer(1.0).timeout.connect(Game.extra_child.debug)
		"--fotos":
			Game.photo_wall.debug_show(value)
		"--beerdigen":
			Game.cemetery.debug_show("beerdigen," + value)
		"--trauerfeier":
			Game.cemetery.debug_show("trauerfeier")
		"--puppenhaus":
			Game.doll_house.debug_show(value)
		"--fratzen":
			Game.pumpkin_faces.debug()
		"--apfel":
			Game.apple_tub.debug(value)
		"--spieluhr":
			Game.player.receive_item(Item.create(Item.Kind.MUSIC_BOX))
			if value == "monster":   # es kommt, nach 3 s ziehst du sie auf
				Game.director.debug_lure()
				get_tree().create_timer(3.0, false).timeout.connect(func() -> void:
					if Game.player.held and Game.player.held.kind == Item.Kind.MUSIC_BOX:
						MusicBox.wind(Game.player.held, Game.player))
		_:
			return false
	return true


## --tp: zu einem Ort aus der F6-Liste (lobby, bar, küche, keller …), in ein Zimmer (Nummer) oder vor einen Gast.
func _debug_teleport(where: String) -> bool:
	var p := Game.player
	var guest := Game.social.find_guest(where)
	if guest and not guest.dead:
		var front := -guest.global_transform.basis.z
		TeleportUI.place_player(guest.global_position + front * 1.6, -front)
		return true
	# Zimmer: Nummer (auch verschlossene, auch oben), „13“ → 013, Türschild „13“ → 013
	var b := Game.social.builder
	var no := where
	if b.room_spot(no).is_empty() and where.is_valid_int():
		no = "%03d" % where.to_int()
	for key in b.rooms:
		if b.rooms[key]["sign"] == where:
			no = key
	var spot := b.room_spot(no)
	if not spot.is_empty():
		TeleportUI.place_player(spot["pos"], spot["look"])
		return true
	var entry := (get_node("Teleport") as TeleportUI).find(where)
	if entry.is_empty():
		return false
	if p.hiding:
		p.exit_hide()
	(get_node("Teleport") as TeleportUI).go_to(entry)
	return true


## --navcheck: Ladezeiten und ob die wichtigen Orte vom Spielerzimmer aus auf dem NavMesh erreichbar sind.
func _nav_check() -> void:
	var b := Game.social.builder
	print("[navcheck] Bau %d ms, NavMesh %d ms" % [_load_times.x, _load_times.y])
	var map := get_world_3d().navigation_map
	var from := NavigationServer3D.map_get_closest_point(map, b.player_spawn)
	var ground := b.wander_points.filter(func(p: Vector3) -> bool: return p.y < 1.0)
	var targets := {"Lobby": b.lobby_center, "Galerie": b.lobby_center + Vector3(-5.5, LevelBuilder.UP_Y, -2.0),
		"Bar": b.bar_spots[0], "Partyraum": b.party_spots[0], "Küche": b.kitchen_spot, "Garten": b.garden_spots[0],
		"Keller": b.cellar_center(), "Treppenhaus": b.stairwell_point + Vector3(0, 0, 2.2),
		"Westflügel": ground[ground.size() - 1]}
	for t in b._map["trees"]:
		targets["Innenhof %.0f,%.0f" % [t["center"][0], t["center"][1]]] = Vector3(t["center"][0], 0, t["center"][1] + 7.0)
	# Obergeschoss (Spielkonzept 7.7): Katzenraum, Bibliothek, ein Flur und ein Zimmer oben
	for zone in b.zones:
		var name := String(zone["name"])
		if (name in ["Katzenraum", "Bibliothek"] or (name.ends_with("(oben)") and not targets.has("Flur oben"))) \
				and not targets.has(name):
			targets["Flur oben" if name.ends_with("(oben)") else name] = zone["center"]
	# Untergeschoss (Spielkonzept 7.9): Gang unten am Treppenhaus, Technikraum, Wäscherei (der Heizkeller ist „Keller“)
	var below := b.zones.filter(func(z: Dictionary) -> bool: return z["name"] == "Keller")
	below.sort_custom(func(z1: Dictionary, z2: Dictionary) -> bool:
		return (z1["center"] as Vector3).distance_to(b.stairwell_point) < (z2["center"] as Vector3).distance_to(b.stairwell_point))
	if not below.is_empty():
		targets["Kellergang"] = below[0]["center"]
	for zone in b.zones:
		if zone["name"] in ["Technikraum", "Wäscherei"]:
			targets[zone["name"]] = zone["center"]
	for no in b.rooms:
		if b.rooms[no]["kind"] == "vacant" and (b.rooms[no]["center"] as Vector3).y > 2.0:
			targets["Zimmer %s" % no] = b.rooms[no]["center"]
			break
	var bad := 0
	for label in targets:
		var to := NavigationServer3D.map_get_closest_point(map, targets[label])
		# ohne Grenze bei der Suche, wie das Monster (Monster.agent.path_search_max_polygons)
		var query := NavigationPathQueryParameters3D.new()
		query.map = map
		query.start_position = from
		query.target_position = to
		query.path_search_max_polygons = 0
		var result := NavigationPathQueryResult3D.new()
		NavigationServer3D.query_path(query, result)
		var path := result.path
		var reached := not path.is_empty() and path[path.size() - 1].distance_to(to) < 0.5 and to.distance_to(targets[label]) < 1.0
		var length := 0.0
		for i in range(1, path.size()):
			length += path[i - 1].distance_to(path[i])
		print("[navcheck]   %-22s %s" % [label, ("%.0f m" % length) if reached else "UNERREICHBAR (nächster Punkt %s)" % to])
		bad += 0 if reached else 1
	print("[navcheck] alles erreichbar" if bad == 0 else "[navcheck] %d Orte unerreichbar" % bad)
	get_tree().quit()


## --despawn[=monster|geist|kuerbis]: diese Bedrohung (ohne Angabe alle) ist sofort fort – danach ruht sie wie nach
## einem Auftritt. Die Meldung sagt, wer weg ist.
func _debug_despawn(which: String) -> void:
	if not which in ["", "alle", "monster", "geist", "kuerbis", "kürbis"]:
		Game.say("--despawn[=monster|geist|kuerbis]", 3.0)
		return
	var gone: Array[String] = []
	if which in ["", "alle", "monster"] and Game.director.debug_despawn():
		gone.append("Monster")
	if which in ["", "alle", "geist"] and Game.ghost and Game.ghost.debug_despawn():
		gone.append("Lakengeist")
	if which in ["", "alle", "kuerbis", "kürbis"] and Game.pumpkin and Game.pumpkin.debug_despawn():
		gone.append("Kürbismann")
	Game.say("Fort: %s" % ", ".join(gone) if not gone.is_empty() else "Keine Bedrohung unterwegs", 3.0)


## --kill: Gast sofort tot, ohne dass das Monster kommt. corpse: er liegt da (wie nach Lakengeist und Kürbismann), sonst
## ist er verschwunden wie vom Monster geholt (Kratzer, ein Schuh); blood: Blutlache und Spritzer an der nächsten Wand.
## cause ("ghost", "pumpkin", "monster") bestimmt nur, was das Hotel hört und meldet (Social.on_guest_died).
func _debug_kill(victim: Guest, cause: String, corpse: bool, blood: bool) -> void:
	var where := victim.global_position
	if corpse:
		Game.sound_at("grunt", where, Senses.GRUNT_RANGE, victim)
	else:
		Game.noise("death_scream", where, victim)
	victim.die("ghost" if corpse else "monster")
	if blood and Game.traces:
		Game.traces.add_blood(where, randf() * TAU)
		Game.traces.add_wall_blood(where, "wall_splatter")
	Game.social.on_guest_died(victim, cause)


## Gast für einen Debug-Befehl – unbekannte ID: Meldung und null.
func _guest(id: String) -> Guest:
	var guest := Game.social.find_guest(id)
	if guest == null:
		Game.say("Unbekannter Gast: %s" % id, 3.0)
	return guest


## Gast `distance` m vor den Spieler stellen (negativ: dahinter); face: er schaut den Spieler an.
func _put_in_front(guest: Guest, distance: float, face: bool = true) -> void:
	guest.global_position = Game.player.global_position - Game.player.global_transform.basis.z * distance
	if face:
		guest.rotation.y = Game.player.rotation.y + PI


## Spieler waagerecht zu einem Punkt drehen.
func _face_toward(point: Vector3) -> void:
	var to := point - Game.player.global_position
	Game.player.rotation.y = atan2(-to.x, -to.z)


## --gespraech (Talk.debug): Der Gast kommt vor den Spieler (nicht umgekehrt – in seinem Zimmer wäre es
## Hausfriedensbruch, 6.19), dann Gespräch – mit question stellt er diese Frage (6.9).
func _debug_talk(guest: Guest, question: String) -> void:
	_put_in_front(guest, 1.4)
	guest._set_idle(5.0)
	get_tree().create_timer(0.5).timeout.connect(func() -> void:
		_face_toward(guest.global_position)
		Game.dialog.open(guest, question))


## --look: Spieler vor den Gast (in dessen Blickrichtung), der Gast bleibt stehen und schaut her.
## pose stellt eine Haltung nach, damit man die Gastmodelle prüfen kann (Spielkonzept 6.0).
func _debug_look(guest: Guest, pose: String) -> void:
	guest.state = Guest.State.TALKING
	guest.velocity = Vector3.ZERO
	var forward := -guest.global_transform.basis.z
	Game.player.global_position = guest.global_position + forward * 2.4
	Game.player.rotation.y = atan2(forward.x, forward.z)
	match pose:
		"walk":
			guest._walk_to(guest.global_position + forward.cross(Vector3.UP) * 2.0, Guest.State.WALK)
		"carry":
			guest._take_into_hand(Item.create(Item.Kind.PUMPKIN))
		"panic":
			guest.running = true
		"dance":
			guest.state = Guest.State.PARTY
			guest._target = guest.global_position
		"sit":
			guest.state = Guest.State.MINIGAME
			guest.seated = true


## --shock (Spielkonzept 6.12): Gast erschrecken lassen. blood/corpse: Er steht im Flur vor seiner Tür, 2,5 m
## vor ihm liegt eine Blutlache bzw. ein anderer Gast (erwürgt), der Spieler steht dahinter und sieht zu.
## ghostN: Er steht im dunklen Zimmer, der Lakengeist kommt zum N. Mal (ab 3 würgt er), der Spieler sieht
## aus der Zimmerecke zu (zählt dabei nicht als Zeuge).
func _debug_shock(guest: Guest, what: String) -> void:
	var home := guest.home
	var along: Vector3 = home["along"]
	var into: Vector3 = home["into"]
	guest.velocity = Vector3.ZERO
	guest._set_idle(60.0)
	if what == "tür" or what == "tuer":
		# Er steht im eigenen Zimmer, der Lakengeist vor seiner Tür; du stehst im Flur dahinter (kein Zeuge)
		var center: Vector3 = home["center"]
		guest.global_position = center + Vector3(0, 0.05, 0)
		var front: Vector3 = home["door_front"]
		Game.player.global_position = front - into * 3.5 + along * 2.5 + Vector3(0, 0.05, 0)
		_face_toward(front)
		Game.ghost.debug_summon_door(guest)
		return
	if what.begins_with("ghost"):
		var center: Vector3 = home["center"]
		guest.global_position = center + into * 0.8 + Vector3(0, 0.05, 0)
		guest.rotation.y = atan2(-into.x, -into.z)
		Game.player.global_position = center - into * 1.6 + along * 1.4 + Vector3(0, 0.05, 0)
		_face_toward(center + into * 2.5)
		Game.player.head.rotation.x = -0.2
		Game.ghost.debug_summon_guest(guest, maxi(1, what.substr(5).to_int()))
		return
	var front: Vector3 = home["door_front"]
	# in die Flurrichtung, in der 6 m frei sind
	var ray := PhysicsRayQueryParameters3D.create(front + Vector3.UP, front + Vector3.UP + along * 6.0, 1)
	if not get_world_3d().direct_space_state.intersect_ray(ray).is_empty():
		along = -along
	guest.global_position = front + Vector3(0, 0.05, 0)
	guest.rotation.y = atan2(-along.x, -along.z)
	var spot := front + along * 2.5
	if what == "corpse":
		for other in Game.social.living_guests():
			if other != guest and other.gen_seed >= 0:
				other.global_position = spot
				other.rotation.y = atan2(-into.x, -into.z)
				other.die("ghost")
				break
	else:
		Game.traces.add_blood(spot, 0.4)
	Game.player.global_position = front + along * 4.2 + Vector3(0, 0.05, 0)
	_face_toward(front)
	Game.player.head.rotation.x = -0.25


## --savetest: Speichern und Laden ohne Datei durchspielen und Unterschiede ausgeben.
func _save_test() -> void:
	# Etwas Unordnung, damit der Test mehr abdeckt: Vorhang zu, Licht aus, Birne in der Hand
	(get_tree().get_nodes_in_group("windows").filter(func(w: Node) -> bool: return w.has_curtains())[0] as HotelWindow).set_closed(true)
	(get_tree().get_nodes_in_group("light_switches")[0] as LightSwitch).set_on(false)
	# eine Zimmerlampe (Raum-ID = Zimmernummer), sonst irgendeine – unabhängig davon, wie der Plan eingerichtet ist
	var fixtures := get_tree().get_nodes_in_group("lamp_fixtures").filter(func(l: Node) -> bool: return (l as Lamp).has_bulb)
	var in_rooms := fixtures.filter(func(l: Node) -> bool: return String(l.room_id).is_valid_int())
	var lamp: Lamp = (in_rooms if not in_rooms.is_empty() else fixtures)[0]
	if Game.player.held == null:
		Game.player.receive_item(lamp.take_bulb())
	for kind in [Item.Kind.SWEETS, Item.Kind.SODA_CAN]:   # mit voller Hand: in die Tasche
		Game.player.receive_item(Item.create(kind))
	# Spielerfigur (3.9): eine andere als die Standardfigur – nach dem Sammeln zurückgesetzt, Laden muss sie wiederholen
	Game.player.set_look({"body": "woman_old", "height": 1.52, "slim": 0.1, "fit": 0.7, "skin": GuestGenerator.SKIN[5].to_html(false)})
	await get_tree().create_timer(0.5).timeout
	var before: Dictionary = JSON.parse_string(JSON.stringify(SaveManager.collect()))
	Game.player.set_look(PlayerBody.default_look())
	SaveManager.apply(before)
	await get_tree().physics_frame
	await get_tree().process_frame
	var after: Dictionary = JSON.parse_string(JSON.stringify(SaveManager.collect()))
	for note in _settle(before, after):
		print("[savetest]   (kein Fehler) " + note)
	var problems := 0
	for key in before:
		if key == "saved_at":
			continue
		if not _same(before[key], after.get(key)):
			problems += 1
			if before[key] is Array and after.get(key) is Array and before[key].size() == after[key].size():
				for i in before[key].size():
					if not _same(before[key][i], after[key][i]):
						print("[savetest]   %s[%d]: %s → %s" % [key, i, JSON.stringify(before[key][i]), JSON.stringify(after[key][i])])
				continue
			if before[key] is Array:
				var kinds := func(list: Array) -> String:
					return ", ".join(list.map(func(e) -> String: return "%s@%s" % [e.get("kind"), str(e.get("pos"))]))
				print("[savetest]   vorher  %d: %s\n[savetest]   nachher %d: %s" % [before[key].size(), kinds.call(before[key]), after[key].size(), kinds.call(after[key])])
				continue
			if before[key] is Dictionary and after.get(key) is Dictionary:
				for sub in before[key]:
					var was = before[key][sub]
					var now = after[key].get(sub)
					if _same(was, now):
						continue
					if was is Dictionary and now is Dictionary:   # nur die Felder, die abweichen (Gäste sind lang)
						for field in was:
							if not _same(was[field], now.get(field)):
								print("[savetest]   %s.%s.%s: %s → %s" % [key, sub, field, JSON.stringify(was[field]).left(600),
									JSON.stringify(now.get(field)).left(600)])
						continue
					print("[savetest]   %s.%s: %s → %s" % [key, sub, JSON.stringify(was).left(600), JSON.stringify(now).left(600)])
				continue
			print("[savetest] Unterschied in „%s“:\n  vorher  %s\n  nachher %s" % [key,
				JSON.stringify(before[key]).left(400), JSON.stringify(after.get(key)).left(400)])
	print("[savetest] %d Gegenstände, %d Gäste, %d Spuren, Angriffe %d – %s" % [(before["items"] as Array).size(), (before["guests"] as Dictionary).size(),
		(before["traces"] as Array).size(), int(before["director"]["state"]["attacks"]),
		"alles gleich" if problems == 0 else "%d Unterschiede" % problems])


## Bekanntes Rauschen zwischen den beiden Sammelzeitpunkten angleichen, damit nur echte Lade-Lücken zählen:
## Lage von Gegenständen in der Hand (folgt der Hand, apply setzt sie nicht), Türen, die ein Gast im Türrahmen
## gleich nach dem Laden öffnet (sein Zustand – Klopfen, Schlafen … – wird nicht gespeichert, er steht danach
## untätig da), Drehung liegender Gegenstände bis ~15° und Katzen-Zeitgeber, die genau dazwischen abliefen.
## Gibt Hinweise dazu zurück.
func _settle(before: Dictionary, after: Dictionary) -> Array[String]:
	var notes: Array[String] = []
	for data: Dictionary in [before, after]:
		var hands: Array = [data["player"]]
		hands.append_array((data["guests"] as Dictionary).values())
		for who: Dictionary in hands:
			if who.get("held") is Dictionary:
				who["held"].erase("pos")
				who["held"].erase("rot")
	var doors := get_tree().get_nodes_in_group("doors")
	var was: Array = before.get("doors", [])
	var now: Array = after.get("doors", [])
	if was.size() == doors.size() and now.size() == doors.size():
		for i in doors.size():
			var center: Vector3 = (doors[i] as Door).center()
			if bool(was[i]["open"]) != bool(now[i]["open"]) and Game.social.living_guests().any(func(g: Guest) -> bool:
					return center.distance_to(g.global_position + Vector3.UP) < 1.3):
				now[i] = was[i]
				notes.append("doors[%d]: ein Gast im Türrahmen hat sie nach dem Laden geöffnet" % i)
	# Liegende Gegenstände: Euler-Winkel sind nahe ±90° Neigung mehrdeutig, und was beim Sammeln noch rollte, setzt
	# sich ohne Schwung (wird nicht gespeichert) etwas anders – gleich, wenn die Lage auf ~15° stimmt
	var items_was: Array = before.get("items", [])
	var items_now: Array = after.get("items", [])
	if items_was.size() == items_now.size():
		for i in items_was.size():
			var a: Dictionary = items_was[i]
			var b: Dictionary = items_now[i]
			if a.get("kind") == b.get("kind") and a.get("rot") is Array and b.get("rot") is Array and a["rot"] != b["rot"]:
				var qa := Quaternion.from_euler(Vector3(a["rot"][0], a["rot"][1], a["rot"][2]))
				var qb := Quaternion.from_euler(Vector3(b["rot"][0], b["rot"][1], b["rot"][2]))
				if qa.angle_to(qb) < deg_to_rad(15.0):
					b["rot"] = a["rot"]
	var cats_was: Array = before.get("cats", [])
	var cats_now: Array = after.get("cats", [])
	if cats_was.size() == cats_now.size():
		for i in cats_was.size():
			if float(cats_was[i].get("timer", 1.0)) <= 0.05 and not _same(cats_was[i], cats_now[i]):
				cats_now[i] = cats_was[i]   # neuer Zeitgeber, neue Richtung – sie hat gerade etwas Neues angefangen
				notes.append("cats[%d]: Zeitgeber lief zwischen den Messungen ab" % i)
	# Wer auf dem Weg ins Versteck war (Zustand wird nicht gespeichert), sieht sich nach dem Laden gleich wieder um und
	# erschrickt vor Blut, an dem er gerade vorbeigerannt ist (Guest._scan_for_shock)
	var guests_was: Dictionary = before.get("guests", {})
	var guests_now: Dictionary = after.get("guests", {})
	for id in guests_was:
		var a: Dictionary = guests_was[id]
		var b: Dictionary = guests_now.get(id, {})
		if b.is_empty() or (b.get("seen", []) as Array).size() != (a.get("seen", []) as Array).size() + 1:
			continue
		for key in ["seen", "experiences", "fear"]:
			b[key] = a.get(key)
		notes.append("guests.%s: hat nach dem Laden gleich etwas Erschreckendes gesehen" % id)
	return notes


## Gleich bis auf kleine Zahlenabweichungen (zwischen den Messungen vergeht ein Frame).
func _same(a, b) -> bool:
	if typeof(a) == TYPE_FLOAT or typeof(a) == TYPE_INT:
		# Winkel: π und −π sind dieselbe Drehung (aufgehängte Deko blickt oft genau nach Süden)
		if typeof(b) != TYPE_FLOAT and typeof(b) != TYPE_INT:
			return false
		var diff := absf(float(a) - float(b))
		return diff < 2.0 or absf(diff - TAU) < 0.01
	if typeof(a) != typeof(b):
		return false
	if a is Array:
		if a.size() != b.size():
			return false
		for i in a.size():
			if not _same(a[i], b[i]):
				return false
		return true
	if a is Dictionary:
		if a.size() != b.size():
			return false
		for k in a:
			if not b.has(k) or not _same(a[k], b[k]):
				return false
		return true
	return a == b

## --pumpkin=jagd[,gast]: Der Kürbismann jagt den Spieler bzw. den Gast (auch ohne Spaß und vor dem ersten Angriff).
func _debug_pumpkin_hunt(id: String) -> void:
	await get_tree().create_timer(0.5, false).timeout   # NavMesh muss erst synchronisiert sein
	var target: Node3D = Game.player
	if id != "":
		target = Game.social.find_guest(id)
		if target == null:
			Game.say("Kein Gast „%s“" % id)
			return
		if (target as Guest).is_child():
			Game.say("Kindern tut der Kürbismann nichts")
			return
	if not Game.pumpkin.debug_hunt(target):
		Game.say("Kürbismann: kein Platz zum Erscheinen")


## --search[=gast][,mit]: Deko-Suche (Spielkonzept 5.9) – mit „mit“ geht der Spieler mit (folgt ihm von selbst).
func _debug_search(parts: PackedStringArray) -> void:
	var search := Game.social.search
	var who: Guest = null
	for part in parts:
		if part != "mit":
			who = Game.social.find_guest(part)
	var walkers: Array = [who] if who else Game.social.living_guests().filter(func(g: Guest) -> bool: return search._available(g))
	walkers.shuffle()
	for g: Guest in walkers.slice(0, 8):
		if search.start(g, "mit" in parts):
			if "mit" in parts:
				search.lead_off(g)
				# Der Spieler folgt ihm von selbst (2,5 m dahinter), bis er geteilt hat
				var follow := Timer.new()
				follow.wait_time = 0.3
				add_child(follow)
				follow.timeout.connect(func() -> void:
					if not search.is_busy(g):
						follow.queue_free()
						return
					var back := g.global_position - (-g.global_transform.basis.z) * 2.5
					Game.player.global_position = Vector3(back.x, g.global_position.y + 0.05, back.z)
					_face_toward(g.global_position))
				follow.start()
			return
	Game.say("Deko-Suche: kein Gast frei oder kein Fundort erreichbar", 3.0)


## --cook=suppe|braten[,fertig]: Kochen (Spielkonzept 3.8) – Spieler vor den Herd, Kürbis schon geschnitten.
func _debug_cook(parts: PackedStringArray) -> void:
	var stove := Game.kitchen
	if stove == null:
		Game.say("Kein Herd im Hotel", 3.0)
		return
	if parts[0] == "gast":   # ein Gast kocht selbst (2026-10-22): er steht 4 m vor dem Herd, du daneben
		var cook: Guest = Game.social.find_guest(parts[1]) if parts.size() > 1 else Game.social.living_guests().filter(func(g: Guest) -> bool: return not g.is_child())[0]
		var front: Vector3 = stove.front
		cook.global_position = Vector3(stove.global_position.x, 0.05, stove.global_position.z) + front * 4.0
		cook._set_idle(5.0)
		Game.player.global_position = cook.global_position + front.cross(Vector3.UP) * 1.5
		Game.player.rotation.y = atan2(front.x, front.z)
		stove.start_guest_cook(cook)
		return
	var soup := "braten" not in parts
	stove.dish = "soup" if soup else "roast"
	stove.variety = "halloween" if soup else "hokkaido"
	stove.phase = "cooking"
	stove._timer = 0.5 if "fertig" in parts else (Stove.SOUP_TIME if soup else Stove.ROAST_TIME)
	stove._show()
	var front: Vector3 = stove.front
	Game.player.global_position = Vector3(stove.global_position.x, 0.05, stove.global_position.z) + front * 1.4
	Game.player.rotation.y = atan2(front.x, front.z)
	Game.player.head.rotation.x = deg_to_rad(-25.0)


## --maske[=id]: Vor die Maskenhaken in Zimmer 13 (Spielkonzept 5.19), Blick darauf; mit id die Maske vom Haken
## gleich aufgesetzt.
func _debug_masks(id: String) -> void:
	var hooks := get_tree().get_nodes_in_group("mask_hooks")
	if hooks.is_empty():
		Game.say("Keine Maskenhaken in Zimmer 13.", 3.0)
		return
	var first := hooks[0] as Node3D
	var last := hooks[hooks.size() - 1] as Node3D
	var middle := (first.global_position + last.global_position) / 2.0
	var stand := middle + first.global_basis.z * 1.6
	Game.player.global_position = Vector3(stand.x, Game.player.global_position.y, stand.z)
	var to := middle - stand
	Game.player.rotation.y = atan2(-to.x, -to.z)   # die Kamera blickt nach −Z
	Game.player.head.rotation.x = deg_to_rad(5.0)
	if id == "":
		return
	for hook: MaskHook in hooks:
		if hook.mask_id == id and hook.hanging:
			hook.interact(Game.player)
			Game.player.put_on_mask()
			return
	Game.say("Keine Maske „%s“ am Haken." % id, 3.0)


## --salz[=fenster|tür|monster|zimmer,nr|gast,id]: Salz (Spielkonzept 5.13) – eine Packung in der Hand; fenster: dazu
## Linien auf allen Außenfenstern und Fenstertüren deines Zimmers (beim Start Zimmer 13), tür: innen vor seiner Tür,
## monster: dazu kommt das Monster den Flur entlang herein, zimmer/gast: auf den Fenstern von Zimmer nr bzw. des Gastes.
func _debug_salt(parts: PackedStringArray) -> void:
	Game.player.drop_held()
	Game.player.receive_item(Item.create(Item.Kind.SALT))
	var builder := Game.social.builder
	var room := builder.home_room_at(Game.player.global_position)
	if parts[0] == "zimmer" and parts.size() > 1:
		room = Game.director.room_by_label(parts[1])
	elif parts[0] == "gast" and parts.size() > 1 and Game.social.find_guest(parts[1]):
		room = String(Game.social.find_guest(parts[1]).home["no"])
	var root := Game.player.get_parent()
	if parts[0] == "streuen":   # wie im Spiel: vor die Tür deines Zimmers stellen, hinsehen, Linksklick
		var home: Dictionary = Game.director.rooms.get(room, {})
		if home.is_empty():
			return
		Game.player.global_position = (home["door_inside"] as Vector3) + (home["into"] as Vector3) * 0.3
		_face_toward((home["door"] as Door).center())
		Game.player.head.rotation.x = deg_to_rad(-38.0)   # auf den Boden vor der Tür
		get_tree().create_timer(0.5).timeout.connect(Game.player.strew_salt)
		return
	if parts[0] in ["tür", "tuer", "monster"]:
		var info: Dictionary = Game.director.rooms.get(room, {})
		if info.is_empty():
			Game.say("Salz: Hier ist kein Zimmer.", 2.5)
			return
		SaltLine.lay(root, SaltLine.spot_for(info["door"], info["door_inside"]))
		if parts[0] == "monster":   # nach 1,5 s (NavMesh) 5 m den Flur hinunter, es will ins Zimmer
			get_tree().create_timer(1.5).timeout.connect(func() -> void:
				var along: Vector3 = info["along"]
				Game.monster.spawn_at(info["door_front"] + along * 5.0)
				Game.monster.investigate(info["door_inside"] + (info["into"] as Vector3) * 1.0))
	elif parts[0] in ["fenster", "zimmer", "gast"]:
		var laid := 0
		for node in get_tree().get_nodes_in_group("windows") + get_tree().get_nodes_in_group("french_doors"):
			var door := node as Door
			var spot := SaltLine.spot_for(node, door.center() - door.outward if door else Vector3.ZERO)
			if spot.has("pos") and spot["room"] == room:
				SaltLine.lay(root, spot)
				laid += 1
		if laid == 0:
			Game.say("Salz: Zimmer %s hat kein Außenfenster und keine Fenstertür." % room, 2.5)


## --kaffee=n|maschine|gast[,id]: Kaffee (Spielkonzept 3.11) – n Tassen getrunken, vor der Maschine (gleich fertig)
## oder ein Gast holt sich Kaffee. tea: dasselbe mit Tee am Wasserkocher (--tee=n|kocher|gast, 3.12).
func _debug_coffee(parts: PackedStringArray, tea: bool = false) -> void:
	var p := Game.player
	if parts[0].is_valid_int():
		for i in parts[0].to_int():
			var cup := Item.create(Item.Kind.TEA if tea else Item.Kind.COFFEE)
			p.receive_item(cup)
			if p.held != cup:   # Hände voll – nichts anderes austrinken
				cup.queue_free()
				return
			if tea:
				p.drink_tea()
			else:
				p.drink_coffee()
		return
	var machine: CoffeeMachine = Game.kettle if tea else Game.coffee
	if machine == null:
		Game.say("Kein Wasserkocher im Hotel" if tea else "Keine Kaffeemaschine im Hotel", 3.0)
		return
	var front: Vector3 = machine.front
	var base := Vector3(machine.global_position.x, 0.05, machine.global_position.z)
	if parts[0] == "gast":
		# ohne id beim Tee ein Kind (das darf, 3.12), beim Kaffee ein Erwachsener
		var g: Guest = Game.social.find_guest(parts[1]) if parts.size() > 1 else Game.social.living_guests().filter(func(c: Guest) -> bool: return c.is_child() == tea)[0]
		g.global_position = base + front * 4.0
		g._set_idle(5.0)
		p.global_position = g.global_position + front.cross(Vector3.UP) * 1.5
		p.rotation.y = atan2(front.x, front.z)
		machine.start_guest(g)
		return
	p.global_position = base + front * 1.1
	p.rotation.y = atan2(front.x, front.z)
	p.head.rotation.x = deg_to_rad(-30.0)
	machine._start_brew(null, p)
	machine._timer = 1.0


## --pals=gast1,gast2: gast1 ist mit dir befreundet, beide sind Freunde und stehen vor dir (Spielkonzept 6.16).
func _debug_pals(parts: PackedStringArray) -> void:
	var a := Game.social.find_guest(parts[0])
	var b := Game.social.find_guest(parts[1]) if parts.size() > 1 else null
	if a == null or b == null:
		Game.say("--pals: zwei Gäste angeben, z. B. --pals=edna,bruno", 3.0)
		return
	a.relation = 60.0
	b.relation = minf(b.relation, 5.0)
	Game.social.pals.counts[GuestPals.key(a, b)] = GuestPals.PAL_DEEDS
	var p := Game.player
	var forward := -p.global_transform.basis.z
	var side := forward.cross(Vector3.UP).normalized()
	for g: Guest in [a, b]:
		g.global_position = p.global_position + forward * 2.5 + side * (0.6 if g == a else -0.6)
		g._set_idle(30.0)
	Game.social.pals._scan = 0.5


## --decorate[=…]: Schmück-Aktion bzw. allein schmückender Gast (Spielkonzept 5.9), mit „hin“ steht der Spieler davor.
func _debug_decorate(parts: PackedStringArray) -> void:
	var caller: Guest = null
	for part in parts:
		if not part in ["hin", "lobby", "allein", "gross", "hier", "haus"]:
			caller = Game.social.find_guest(part)
	var deco := Game.social.decorating
	var spot: Dictionary = {}
	if "hier" in parts:
		var host: Guest = caller if caller else Game.social.living_guests().filter(func(g: Guest) -> bool:
			return not g.is_child() and deco._available(g)).pick_random()
		var why := deco.call_here(host, false)
		if why != "":
			Game.say("Schmücken: " + why, 3.0)
		return
	if "gross" in parts:
		if deco.start_big(caller, Vector3.INF, false, "lobby" in parts):
			spot = deco.site
	elif "allein" in parts:
		var walkers: Array = [caller] if caller else Game.social.living_guests().filter(func(g: Guest) -> bool: return deco._available(g))
		walkers.shuffle()
		for g: Guest in walkers.slice(0, 8):
			if deco.start_solo(g, "lobby" in parts, "haus" in parts):
				spot = deco.solo_site(g)
				break
	elif deco.start(caller, "lobby" in parts):
		spot = deco.site
	if spot.is_empty():
		Game.say("Schmücken: kein Gast frei oder keine passende Stelle in der Nähe", 3.0)
	elif "hin" in parts:
		var out: Vector3 = spot["out"]
		var wall: Vector3 = spot["wall"]
		var back := 3.2   # so weit zurück, wie der Flur reicht
		var hit := Game.player.get_world_3d().direct_space_state.intersect_ray(
			PhysicsRayQueryParameters3D.create(wall + out * 0.1 + Vector3.UP * 1.2, wall + out * 3.6 + Vector3.UP * 1.2, 1 | 2))
		if not hit.is_empty():
			back = minf(back, wall.distance_to(Vector3(hit["position"].x, wall.y, hit["position"].z)) - 0.4)
		Game.player.global_position = wall + out * back + Vector3(0, 0.05, 0)
		Game.player.rotation.y = atan2(out.x, out.z)
		Game.player.head.rotation.x = deg_to_rad(-12.0)
	elif "--answer" in OS.get_cmdline_user_args():
		# in Zimmer 13 kommt die Einladung per Anruf – nach 4 s abnehmen
		get_tree().create_timer(4.0).timeout.connect(func() -> void: Game.phones.answer(Game.phones.home_phone))
