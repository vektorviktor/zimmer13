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
##   --unterbrechen[=laden]      nach 2 s „Unterbrechen und beenden“ wie im Spielmenü (8.10): Zwischenstand schreiben und
##                               beenden · laden: statt zu beenden gleich wieder laden – danach ist er gelöscht (Load 4)
##   --fortschritt[=grund]       nach 2 s Fortschritt melden (SaveManager.on_progress, 8.10) – Autosave im nächsten
##                               sicheren Moment; mit --trace „[Autosave]“
##   --albtraummodus[=n|pruefen] dieses Spiel im Albtraum-Modus (8.9) mit Slot n (Standard 3): Tagebuch und Autosave nur
##                               dorthin, der Tod löscht ihn · pruefen: nach 2 s normal speichern und „sterben“, dann
##                               Albtraum speichern, Autosave, Laden, Tod – „[Albtraum] … ok/FEHLER“, „Prüfung fertig“
##   --day=n                     zu Tag n im Oktober springen (15 Uhr)
##   --uhr=hh[:mm]               Uhrzeit am aktuellen Tag stellen (2.4; am 1. Oktober frühestens 15 Uhr) – nach --day
##   --attacks=n                 so viele Raubzüge gab es schon (ab 3 ist der nächste nicht mehr harmlos, 4.33)
##   --siegerehrung[=ohne]       Siegerehrung des Türschmuck-Wettbewerbs (2.5) sofort: Uhr auf den 2. Oktober 20 Uhr, die
##                               Gäste stehen schon um die Puppe, du vor ihr – gleich steht sie auf, dann der erste
##                               Angriff: Gustav Peters wird ungesehen geholt (ohne: du bleibst, wo du bist, die Uhr
##                               springt auf 22 Uhr, es geschieht ohne dich)
##   --grinch[=tot]              vor Zimmer 020, Gustav Peters (der „Halloween-Grinch“, 2.6) steht daneben – tot: er ist
##                               schon geholt, die Tür offen, Schleifspur und sein Tagebuch auf dem Tisch
##   --brett[=nachher|abgereist] vor das Aushangbrett in der Lobby (2.5) – nachher: der erste Angriff gilt als geschehen;
##                               abgereist: Gustav geholt, Morgen danach 7 Uhr, die Mitteilung „abgereist“ hängt (2.9)
##   --register[=tot][,offen|anfang]   vor die Rezeption, Blick aufs Hotelregister (2.3) – tot: Gustav ist geholt,
##                               3. Oktober 7 Uhr, sein Kreuz steht da (mit --kill=id weitere Tote) · offen: nach 1 s
##                               aufgeschlagen beim laufenden Oktober · anfang: bei Oktober 1987
##   --klingel[=nah|an]          vor die Rezeption, Blick auf die Tischklingel (ZIM-146) – nah: dicht heran, von oben ·
##                               an: nach 1 s anschlagen (mit --trace Lärm im Protokoll)
##   --zimmer18[=offen|gelesen]  in Zimmer 18 vor den Tisch mit dem Notizbuch des Hausmeisters, Schaltschlüssel und
##                               UV-Aufsatz (7.4) – offen: nach 1 s aufgeschlagen · gelesen: die drei Mängel stehen im
##                               Notizbuch (mit --show=aufgaben gleich aufgeschlagen)
##   --brief                     an den Schreibtisch in Zimmer 13, Blick auf den Willkommensbrief (2.5)
##   --spinde[=offen]            vor den ersten Spindblock der Pool-Umkleiden (ZIM-145) – offen: alle Spinde, die
##                               aufgehen, sind offen (auch die mit Schlüssel)
##   --stahlspinde[=offen|pruefen] vor die Stahlspinde (ZIM-174; ohne Plan eine Probereihe im Lager), Codes ins
##                               Protokoll – offen: alle offen · pruefen: Spind bei 180 cm, falscher/richtiger Code
##   --duschen[=an]              vor den ersten Duschplatz am Pool (Drücker, Ablage, Duschkopf; ZIM-144) – an: Wasser läuft
##   --automaten[=seite]         vor die beiden Videoautomaten der Bar (Deadra, Ghost Hotel; 6.10) – seite: schräg
##                               von der Seite (Seitenbilder); deadra|hotel: Münze einwerfen und spielen (mit
##                               --autoplay spielt er selbst); gast[,id]: der Gast (Standard ein Kind) spielt Ghost
##                               Hotel, du siehst zu
##   --bilder[=gruppe]           vor das erste Gemälde aus dem Plan (ZIM-151); hängt keins oder mit gruppe (lobby, bar,
##                               corridor, study, director, room, alle): die Werke als Reihe in der Lobby
##   --notizbuch                 Notizbuch mit Beispielen (Aufgaben: offen, erledigt, zu spät, Auftraggeber tot; Notizen
##                               über drei Tage) und ein paar Einträge im Tagebuch zum Nachlesen (3.10)
##   --gesehen                   Notizbuch einstecken, alle drei Bedrohungen gelten als gesehen (Lesezeichen „Gesehen“, 3.10) –
##                               mit --show=gesehen gleich aufgeschlagen
##   --tot[=monster|geist|kuerbis]   nach 1 s gestorben: Sterbebildschirm mit dem Porträt dessen, der dich geholt hat (8.7)
##   --zettel                    erster Angriff gilt als geschehen, der Warnungszettel von 1999 liegt hinter der Tür von
##                               Zimmer 13, du stehst davor (2.5)
##   --knock [--knock-fake] [--answer]   Klopfen an Zimmer 13 (falsche Stimme / Tür öffnen)
##   --spion[=leer|echt|falsch|auge]   vor der Tür von Zimmer 13 durch den Spion sehen (7.17), nach 6 s wieder [E] –
##                               echt/falsch: dabei klopft es (Gast bzw. falsche Stimme), auge: der Leviathan steht davor
##                               und beugt sich an die Linse
##   --schwelle[=flur|zimmer|nah]   Tür von Zimmer 13 offen, du siehst auf die Messingschiene darunter (ZIM-132);
##                               mit --trace: unter wie vielen Türen kein Boden liegt
##   --fenstertuer[=innen|aussen|eingang|glastuer]   vor die Gartentür von Zimmer 13 (von innen bzw. außen), den
##                                          Haupteingang oder die Doppel-Glastür zur Bar
##                               (aus der Lobby), Blick auf die Fenstertür (ZIM-126); mit --trace: Prüfung aller Außentüren
##   --zierleiste[=flur|zimmer|lobby|speisesaal]   Blick schräg hinauf in eine Ecke mit Zierleiste (ZIM-131);
##                               mit --trace: Stücke und Dreiecke je Stockwerk, Leisten in Keller/Dachgeschoss als Fehler
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
##   --kommode[=suchen|verstecken][,gast]  Gäste und Kommoden (3.5, ZIM-39): suchen – ein Gast durchsucht die Kommode
##                               vor dir (Girlande eines Gastes und Spinne des Spielers liegen darin) · verstecken – Kisten
##                               leer, er hat Angst, versteckt ein Stück aus dem Koffer, ein zweiter findet es · Prüfungen
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
##   --netz=gast1,gast2,gast3[,lob]  Freundesnetz (6.18, 1): gast1 hat sich über dich zu beklagen (mit lob: lobt dich),
##                               gast2 ist sein Freund, gast3 der von gast2 – alle drei stehen vor dir; es läuft zwei
##                               Stationen weit, je Station halb so stark (--trace „[Netz]“)
##   --budget=id                 Beziehung nicht erschleichen (6.18, 5): spielt mit dem Gast Gesprächsbereitschaft, Abbruch,
##                               Beziehungsbudget, Geschenke nach Wert, Beruhigen und Vergebung durch (--trace „[Budget]“)
##   --handel=id                 Verkaufspreise (6.4, ZIM-34): Hoteleigentum und Kaputtes kauft keiner, Füllmaterial bringt
##                               die Hälfte (--trace „[Handel]“)
##   --glas[=halten]             Bar (3.7, ZIM-35): Bier, Rotwein, Schnaps – drei Flaschen auf der Theke, Rausch je Sorte, ein
##                               Glas kaufen und austrinken, Rotwein einem Weinfreund schenken (er trinkt es), ein Kind lehnt
##                               ab, die Bitte „ein Glas von der Bar“. Meldet „[Glas] … ok“ bzw. „FEHLER“. halten: nur ein
##                               Glas Rotwein in die Hand (für --savetest)
##   --gastsitzen[=sofa|bank|stuhl|sessel[,id]]   Gäste setzen sich (3.1, ZIM-148): Gast (Standard edna) vor dem Sitzmöbel
##                               dieser Art nahe der Lobby setzt sich, nach 7 s Panik – er steht auf („[Gastsitzen] … ok“)
##   --neid[=id]                 Neid der Türnachbarn (6.18, 5): Kisten leer, vier Kürbisse vor Zimmer 13 – ein Morgen läuft,
##                               dann Untergrenze, Freund, spitzer Satz beim Vorbeigehen und im Gespräch (--trace „[Neid]“)
##   --kisten                    Knappheit (5.10): rechnet je Kiste ohne Nachschub den Monat durch (ohne Spieler leer um den 15.,
##                               mit dem Spieler früher) und zählt die Startdeko der Kernfiguren – „[Kisten] … ok“ bzw. „FEHLER“
##   --streit=dieb,opfer[,gesehen|freund|versoehnen|verblassen|halten]  Streit unter Gästen nach einem Diebstahl (6.16):
##                               beide stehen vor dir; gesehen – Opfer sieht es, Wortwechsel, danach meiden; freund – ein
##                               Freund erzählt es ihm; versoehnen – du vermittelst; verblassen – nach 3 Tagen; halten – nur
##                               ein Streit (für --savetest). Meldet „[Streit] … ok“ bzw. „FEHLER“ (mit --trace mehr)
##   --schuld=id[,klopfen|telefon|licht|begleiten|diebstahl|sorglos|keine|abgelaufen|zurueck|gedenken|halten]  Jeder Tod
##                               hat eine Ursache (6.18, 2): Gast und ein Freund als Zeuge vor dir, du tust ihm die Ursache
##                               an (Standard licht), er stirbt – prüft Ursache, Schuld, Schock, Halluzinationsname, Zeuge;
##                               keine/abgelaufen/zurueck ohne Schuld, gedenken mit Kerze vor seiner Tür, halten für
##                               --savetest. Meldet „[Schuld] … ok“ bzw. „FEHLER“
##   --trauer=id[,feuer|ohne|wunsch|halten]  Trauer der Gäste (6.12): ein Freund des Gastes (Standard edna) stirbt – prüft Haltung,
##                               kein Schmücken, mehr Ruhe; dann geht er zur Tür des Toten · feuer: stellt eine brennende
##                               Kerze aus seinem Vorrat hin · ohne: ohne Feuer keine Kerze · wunsch: Trauerwunsch, du
##                               stellst ein Licht auf, er dankt · halten:
##                               gleich mit Kerze vor der Tür (für --savetest). Meldet „[Trauer] … ok“ bzw. „FEHLER“
##   --zustand=art[,gast[,erfuellen|verfallen|halten]]  Schwere Momente (6.18, 3): art puppe, geist, verletzt, waise
##                               (seine Eltern sterben) oder katze (sie verschleppt sein Laub) – der Gast (Standard: ein
##                               passender ohne Kernrolle) steht vor dir; prüft Zustand, doppelte Beziehung, passendes
##                               Geschenk, Begrüßung und Wunsch (Kernfiguren eigener), angenommen · erfuellen: du
##                               erfüllst ihn · verfallen: der Zustand endet, still gestrichen · halten: bleibt offen
##                               (für --savetest). Meldet „[Wunsch] … ok“ bzw. „FEHLER“
##   --call=id[,panik]|creepy|dead|door [--answer]  Telefon in Zimmer 13 klingelt (Gast – mit ,panik ein Panikanruf –,
##                               Atmen, Verschwundener, vor der Tür) – mit --answer nimmt der Spieler nach 4 s ab
##   --gastanruf=id[,panik]      Gäste telefonieren (4.14): der Gast steht daheim, kennt eine frische Geschichte und ruft
##                               einen Freund an, der sie weitererfährt · panik: Panikanruf; mit --trace „[Telefon]“
##   --dial=n|lobby              vom Telefon in Zimmer 13 aus Zimmer n anrufen (0 = Rezeption) ·
##                               lobby: Wählseite am Haupttelefon mit Gästeverzeichnis
##   --menu=name                 nach 1 s ein Menü öffnen (pause, diary, diary_pages, settings, load, help, achievements)
##   --taste=aktion,taste[,platz]  Tastenbelegung (8.4) nur für die Sitzung, z. B. --taste=interact,f oder
##                               --taste=hold_breath,maus3 (Platz 1 = Zweittaste); getauscht wird wie in den Einstellungen
##   --erfolg=id|alle            Erfolg (8.11) freischalten und einblenden, z. B. --erfolg=chess – alle: alle still (für
##                               --menu=achievements); in Debug-Starts nur für die Sitzung, nichts wird gespeichert
##   --erfolge-zurueck           alle Erfolge im Profil (user://achievements.cfg) löschen
##   --title                     trotz Parametern mit dem Titelbildschirm starten · --title --splash: samt Vorspann (Logo)
##   --pos=x,y,z[,blickwinkel[,neigung]]   Spieler versetzen (Neigung in Grad, positiv = nach oben)
##   --tp=ort|zimmer|gast        hinspringen: Ort der F6-Liste (lobby, partyraum, keller, obergeschoss, katzenraum …), jedes Zimmer (Nummer oder Türschild, auch oben und verschlossene), vor einen Gast
##   --time=+n|-n                Spieltage vor- oder zurückspulen
##   --rot[=welk|eingefallen]    alle Kürbisse 10 s vor welk (5.10) – bzw. gleich welk oder eingefallen
##   --schmuckplan=angst|freund|tod|klau[,gast]   Gäste schmücken mit Plan (5.10, Stufe 3) – du stehst vor der Tür, um
##                               die es geht: angst: ein Gast (oder dieser) hat Angst und schmückt seine Tür · freund: er
##                               ist mit dir befreundet und schmückt Zimmer 13 · tod: er stirbt, seine Nachbarn schmücken
##                               gleich nach · klau: Kisten leer, er klaut von einer fremden Tür (mit --trace „[Schmuckplan]“)
##   --abweisung[=dunkel]        Schutzkreis = Lichtschein (5.10): brennende Deko vor Zimmer 13, du im Schein daneben, das
##                               Monster kommt den Flur herauf und wird abgewiesen – die Flammen ducken sich (dunkel: Deko
##                               ohne Licht zählt nur halb und nur an der Tür, es holt dich; mit --trace „[Abweisung]“)
##   --verwaschen[=schleier]     es regnet sofort, Blut, Wachs und Kürbismatsch draußen verlaufen zehnmal so schnell (4.13,
##                               RainVeil) – schleier: sofort ganz; z. B. mit
##                               --pos=45,0.1,-37 --fall=5,giant --verwaschen --trace
##   --aufzug[=innen|offen|fahrt|urteil|dach|reparatur]   vor den fahrenden Aufzug (7.4) an den Halt stellen, wo die Kabine steht
##                               (innen: in der Kabine mit Blick aufs Bedienfeld · offen: die Tür geht gleich auf · fahrt:
##                               in der Kabine, sie fährt gleich ins oberste Stockwerk, das sie anfährt · urteil: in der
##                               Kabine, nach 3 s ein Urteil über Zimmer 13 (4.33), die Kabine pendelt alle 10 s – das
##                               Monster wartet an der Haltestelle · dach: vor die Tür im Dachgeschoss, nach 1 s Ruf von
##                               oben, schaltet den Halt frei (7.10), nach 30 s „[Aufzug] Dachgeschoss: …“; ohne Halt oben
##                               im Plan nur die Meldung · reparatur: Sperre an, die drei Mängel der Reihe nach beheben
##                               – Schaltschlüssel, Hauptsicherung, Kurbel –, dann die erste Fahrt allein nach unten, mit
##                               Prüfungen „[Aufzug] Reparatur … ok/FEHLER“, ZIM-14)
##   --sitzen[=sofa|bank|stuhl|sessel|bett|klo]   aufs nächste Sitzmöbel dieser Art setzen (3.1), erster Platz – ohne Angabe Sofa
##   --tuer=zimmer[,innen|bad]   vor die Tür dieses Zimmers stellen (Nummer wie am Schild), Blick auf die Tür (6.19);
##                               innen: von drinnen auf ihre Bandseite, bad: im Bad auf die Badtür
##   --werkzeug=brecheisen|kasten|schluessel   Brecheisen bzw. Werkzeugkasten in die Hand, schluessel: Generalschlüssel
##                               an den Bund (6.19) – mit --tuer davor: nach 1 s [E] an der Tür (aufbrechen, reparieren,
##                               aufschließen)
##   --klopfen[=zimmer[,weg]]    vor die Tür eines Gästezimmers (Nummer wie am Schild, ohne Angabe das nächste bewohnte)
##                               und nach 1 s klopfen (6.19); weg = ehrlich|lampe|geschenk|panik|geld wählt die
##                               Antwort im Türgespräch gleich selbst – mit --trace Chance und Ausgang
##   --schluesseldieb[=zimmer[,tausch]]   der Haushaltsvorstand des Zimmers (ohne Angabe 003) liegt schlafend im Bett,
##                               du stehst daneben und nimmst nach 1 s seinen Zimmerschlüssel (6.19); tausch: das Schloss
##                               wird schon 10 s danach getauscht – tagsüber wacht er danach auf, nachts (--day=3
##                               --uhr=2:00) schläft er weiter; mit --trace Hinweis am Bett und Ablauf
##   --attic-door                Kniestocktür zum Ansehen (4.21): du stehst im Dachboden vor ihrer Bandseite (ohne Dachgeschoss
##                               im Plan wird beim Aufbau die erste 0,8 m breite Tür im OG1 zur Dachbodentür)
##   --dachboden[=kopf|fenster|treppe|blitz]  ins Dachgeschoss (4.21): hinter die Kniestocktür, Blick in die Kammer · kopf: vor
##                               den Kopf des Kürbismanns · fenster: unter das Dachfenster, durch das der Mond scheint, Blick hinauf
##                               · treppe: im OG1 an den Fuß der Dachbodentreppe · blitz: in die Kammer, Gewitter, nach 3 s
##                               ein Blitz, der dich sicher um 90° dreht (Spuk, --shot-on=attic_turn) · urteil: in die Kammer,
##                               nach 3 s ein Urteil über Zimmer 13, Notausgang 5 s nach dem Aufbruch der Tür – die
##                               Dachboden-Szene (4.33, 3a: Kniestocktür, Schritte, Staub, es stößt eine Kammertür auf) ·
##                               raubzug: in die Kammer, nach 3 s ein Raubzug, Notausgang nach 5 s offen – dieselbe Szene
##                               mit langer Warnung (8–10 s)
##   --buero[=sekretariat,auf]   ins Büro der Direktion (OG, ZIM-150) vor den Schreibtisch, mit sekretariat ins Sekretariat
##                               vor dessen Schreibtisch (ZIM-154) – steht keiner im Plan, kommt einer zum Ansehen in die
##                               Mitte des Raums; auf: alle Schubladen aufgezogen, in die erste ein Gegenstand; Blick
##                               hinten (Besucherseite), links (linker Unterschrank) oder nah (Platte von oben)
##   --buero=pruefen             Schlösser und Wege ins Sekretariat und Büro (ZIM-6): Türen, Sekretariatsschlüssel am
##                               Sicherungskasten, Zahlenschloss mit Generalschlüssel, Marions Hinweis, Josefs Bund am
##                               Kessel – „[Büro] … ok/FEHLER“, zuletzt „[Büro] Prüfung fertig“
##   --kernschutz                Schutz der Kernfiguren, bis ihre Rolle erfüllt ist (6.17, ZIM-120): wer geschützt ist,
##                               Überleben bei Leviathan und Lakengeist, kein Urteil, Ende über die Marken –
##                               „[Kernschutz] … ok/FEHLER“, zuletzt „[Kernschutz] Prüfung fertig“
##   --versiegelt[=132|038|042|brief]  vor die Tür eines versiegelten Zimmers von 1987 (6.19 (7), ZIM-30; ohne Wert 132)
##                               bzw. vor den Brief aus 038 auf dem Schreibtisch im Sekretariat
##   --versiegelt=pruefen        altes Schloss (Generalschlüssel, Brecheisen), Fenstertüren verriegelt, Liesels Schlüssel
##                               und Familienfoto, Brief und Rahmen vor 038 (ohne Bild im Plan ein Probebild), Ölkännchen
##                               – „[Versiegelt] … ok/FEHLER“, zuletzt „[Versiegelt] Prüfung fertig“
##   --schreibmaschine[=vertrag|dienstplan|aushang|lesen]  vor die Schreibmaschine der Chefsekretärin im Sekretariat
##                               (2.11, ZIM-119), vor die offene Mittelschublade im Büro mit dem Vertrag (ZIM-21), vor
##                               die offene Hängeregistratur mit dem Dienstplan, vor den Aushang Betriebsferien bzw.
##                               das Vertragsblatt offen (springendes „e“ ansehen)
##   --schreibmaschine=pruefen   springendes „e“, Notiz nach Willkommensbrief und Maschine, Aushänge, Dienstplan, Vertrag
##                               in der Hand – „[Type] … ok/FEHLER“, zuletzt „[Type] Prüfung fertig“
##   --regale[=nah]              in die Bibliothek (OG, ZIM-152) schräg vor das erste Bücherregal – steht keins im Plan,
##                               kommen zum Ansehen eine Innenecke (5 Ebenen, 1 m und 2 m) und eine freie Zeile (4 Ebenen);
##                               nah: dicht vor die Bücher (ZIM-153); meldet „[Bücher] …“ (Zahl der Bücher und MultiMeshes)
##   --stuhl[=hinten|seite|nah]  in den Speisesaal (EG, ZIM-156) schräg hinter den ersten Stuhl – steht keiner im Plan,
##                               kommen zwei an die mittlere Tafel und einer frei davor; hinten: von hinten (Wölbung der
##                               Lehne), seite: im Profil (Schräge der Pfosten), nah: über die Lehne aufs Kissen
##   --tafel[=nah|ende]          in den Speisesaal (EG, ZIM-157) schräg vor eine Ecke der ersten Tafel – steht keine im
##                               Plan, kommt eine zum Ansehen in die Mitte; nah: vor das Eckbein, ende: aufs Ende des Läufers
##   --wandleuchte[=nah,quer]    schräg vor die Wandleuchte, die dem Startpunkt am nächsten ist, Blick darauf (Lichtfächer,
##                               7.3) · nah: auf 1,5 m · quer: die nächste an einer Wand nach Osten oder Westen
##   --load-slot=n               Spielstand n laden, auch mitten im Spiel (Konsole: load n; save n = --diary=n)
##   --console[=befehl;befehl]   Debug-Konsole nach 1 s öffnen und Befehle eintippen (für Screenshots)
##   --monster=x,y,z             Monster sofort an dieser Stelle zeigen
##   --lure                      nach 1 s kommt das Monster zu dir (wie F7; ruht es, erscheint es ~25 m entfernt)
##   --splash=x,z                nach 1 s platscht es dort im Pool (Wellenring, Schaum, Spritzer)
##   --pool=still|tremor|slosh   Poolwasser so, als wäre das Monster nah: glatt · zitternde Ringe · schwappt (off = wieder normal)
##   --pocket                    Kompass, alle Kartenblätter und Schlüssel 18 einstecken
##   --flashlight[=uv]           eingeschaltete Taschenlampe mit voller Batterie in die Hand (uv: mit UV-Aufsatz, im UV-Modus)
##   --bag[=a,b,…]               Kleines in die Tasche (3.2): süßes, cola, limo, zierkürbis, kerze, messer, batterie, birne,
##                               uv, würfel, becher, streichhölzer (5.12), dartpfeile, salz, kerne (Kürbiskerne, 5.4),
##                               brot (Brotkrumen, 4.25), ei (6.13), karten, deckel, quiz (Barspiele, 6.10) – ohne Angabe
##                               Süßigkeiten, Cola, Zierkürbis und Batterie
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
##   --kerzen[=nah|wind]         Kerzenmodelle 0,8 m vor dir, Blick hinunter: Kerze brennend und aus (Gegenstand), rot und weiß
##                               brennend auf dem Teller · nah: weiß auf dem Teller 30 cm vor dem Auge, Flamme auf Augenhöhe,
##                               rot daneben (für Nahaufnahmen der Flamme) · wind: sechs brennende Kerzen und ein Kürbis
##                               1,5 m vor dir – draußen neigen sich die Flammen, Böen blasen sie aus (7.8, mit --weather=boe)
##   --show=map|keys|compass     Karte (bzw. Schlüsselblatt) oder Kompass hervorholen (wie Tab/F halten); aufgaben|notizen|
##                               gesehen: das Notizbuch bei diesem Lesezeichen (3.10)
##   --sprint · --winded         vorwärts rennen, bis die Ausdauer leer ist · gleich außer Atem starten (3.1) –
##                               mit --trace stehen „außer Atem“ und „beruhigt“ in der Konsole
##   --fps                       Bilder pro Sekunde einblenden (wie F10)
##   --nohud                     HUD ausblenden (Geld, Hinweise, Fadenkreuz) – für Screenshots
##   --fotomodus[=pruefen]       Fotomodus (wie F12): freie Kamera durch Wände, Zeit steht, der Spieler bleibt stehen –
##                               pruefen: an, fliegen, Zeit, Esc, aus, Enter; meldet „[Fotomodus] … ok/FEHLER“
##   --debug                     Debug-Werte einblenden
##   --nointro                   ohne den Gedanken an den Brief beim Start (2.5)
##   --figur[=schnell]           Erwachen am Waschbecken und Charaktererstellung (3.9) wie bei einem neuen Spiel –
##                               schnell: gleich der Bogen vor dem Spiegel (ohne --figur: Standardfigur)
##   --perf[=s]                  Frame-Zeiten nach temp/perf.csv schreiben, nach s Sekunden (Standard 20) beenden (PerfLog)
##   --static-eg[=pfad]          Erdgeschoss als statische Szene speichern (StaticExport, Standard res://temp/eg_static.scn):
##                               Wände mit Öffnungen, Böden, Decken, Lampen, zum Durchlaufen – als Startparameter danach beenden;
##                               daneben .glb und _lampen.json für den Engine-Vergleich. Messlauf in der Szene: --bench
##                               (StaticWalker, Szene direkt starten)
##   --meshes                    verschiedene Meshes und Flächen in der Szene zählen (Puffer auf der Grafikkarte) und
##                               ausgeben – als Startparameter danach beenden
##   --nur-stockwerk             nur das Stockwerk der Kamera zeichnen, die übrigen ausblenden (im Freien alle) – zum
##                               Messen mit --perf, was das Ausblenden brächte (ShadowBudget.floors_only); erneut: aus
##   --schatten-bias=b[,n]       Bias (und Normal Bias) aller Lampen setzen – zum Abgleichen im Spiel; ohne Wert der
##                               Standard ShadowBudget.BIAS
##   --lichtdiagnose[=position|licht|aus]  Lichtdiagnose (LightDiag, wie F2): Position im Format von --pos, Kompass,
##                               Stockwerk, Raum, Lichtbereich · licht: dazu Lampen, Belegung des Schattenatlas (Schätzung),
##                               letzte Wechsel von ShadowBudget und Leck-Zeiger am Fadenkreuz – ohne Wert weiterschalten
##   --atlas[=a,b,c,d]           Plätze je Quadrant des Schattenatlas (Godot 4,4,16,64) – ohne Wert die nächste Aufteilung
##                               aus LightDiag.ATLAS_PRESETS (wie F11)
##   --bericht[=s]               Lichtbericht nach s Sekunden (Standard 1): Bild und Text nach user://berichte/ (wie F4)
##   --grafik=niedrig|mittel|hoch  Grafikstufe (8.4) nur für die Sitzung setzen, samt Spiegelungen der Stufe – nichts wird
##                               gespeichert
##   --schrift=n                 Schrift & Menüs (8.4) auf n % (60 … 100) nur für die Sitzung, auch im Titelbildschirm
##   --trace                     Monster-Zustand alle 2 s und jedes Lärmereignis in die Konsole schreiben
##   --trace-nav                 mit --trace auch Ziel und Wegfindung jedes Gastes
##   --gedraenge                 alle 10 s „[Gedränge]“: wie viele stehende Gäste einander näher als 0,6 m sind und wie
##                               viele Plätze an Bar, Lobby, Küche und Garten belegt sind (ZIM-155)
##   --noise=art                 alle 6 s Lärm dieser Art am Spieler (door, hide, run, scream … – Senses.NOISE)
##   --warn                      sofort ein Raubzug (4.33, nicht harmlos) – wie --mode=raubzug
##   --pumpkin=ankündigung[,s]   Kürbismann kündigt sich an (4.19): Lampen rot, schrille Melodie, Kinder singen – in s
##                               Sekunden (Standard 20) kommt er übers Lobbydach; mit --trace „[Kürbismann] kündigt sich an“
##   --doll[=s[,zimmer]]         ein Urteil (5.5, 4.33): die Puppe liegt sofort vor der schwächsten bewohnten Tür (bzw.
##                               vor diesem Zimmer, z. B. 13 oder 113), es grollt, in s Sekunden (Standard 20) bricht das
##                               Monster auf und holt den Verurteilten; mit --trace „[Puppe]“, „[Urteil]“
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
##   --balkon[=nachbar|humpeln]  Balkongeländer (7.7, ZIM-36): du stehst auf einem Balkon vor der Außenkante und kletterst
##                               nach 1 s hinüber und springst in den Garten (laut, danach humpelst du) · nachbar: vor einem
##                               Trenngeländer, du steigst zum Nachbarbalkon · humpeln: nach der Landung 2 Spielstunden
##                               Zeitsprung – das Humpeln ist dann vorbei
##   --fledermaus[=tag|schwarm|dachboden|biss]  Fledermäuse (4.22): du stehst im Garten vor einem Baum und siehst hinauf –
##                               21 Uhr, sie kreisen · tag: 12 Uhr, sie hängen in der Krone · schwarm: wie tag, nach 3 s
##                               fliegen sie auf · dachboden: 12 Uhr auf dem Dachboden neben einem Pfosten, sie hängen
##                               unter dem Balkenkreuz (Licht oder Rennen scheucht sie auf) · biss: 21 Uhr, nach 1,5 s
##                               stürzt sich eine herab und beißt dich (Schwäche, das Bild pulsiert)
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
##   --kreisen[=liste|zeichen|tod|salz|schlaf|nacht|edna|halten][,id]  Gäste mit „kreisenden Händen“ (5.13, ZIM-32): liste –
##                               die beiden Gäste und ihre Nächte · zeichen: er kommt jetzt zum ersten (bzw. id) ans Fenster ·
##                               tod: Zeichen, dann holt er ihn · salz: dazu Salz vor seiner Tür – er lebt und dankt · schlaf:
##                               beides abstrakt im Schlaf, einer mit Salz · nacht: Zeichen-Nacht in 5 s, alle im Bett ·
##                               edna: ein Gast stirbt, Edna streut abends Salz · halten: für --savetest. „[Kreisen] … ok“/„FEHLER“
##   --hoerer                    der Hörer in Zimmer 13 liegt daneben (keine Anrufe, die einen wecken; 4.14)
##   --awake=h[,sicher]          so viele Stunden wach (3.6): ab 16 müde, ab 24 übermüdet, ab 36 Sekundenschlaf, ab 48–72 (je
##                               Spiel gewürfelt) sicher im Flur (4.18) – mit ,sicher ab genau dieser Wachzeit; der erste
##                               Angriff gilt als geschehen
##   --sleep=tag[,h]             am Tag h Stunden (Standard 1) im Bett von Zimmer 13 schlafen – die Zeit springt auch am Tag (3.6)
##   --fremdbett=id[,beziehung]  du schläfst ab 1,5 s im Bett dieses Gastes (Beziehung gesetzt), er steht in seinem Zimmer,
##                               zugleich beginnt die Nachtruhe und er findet dich (3.6) · frei[,h]: h Stunden (Standard 4)
##                               im Bett eines Zimmers ohne lebende Bewohner (sonst irgendeinem fremden), am Tag
##   --wache[=id]                Wache (6.18): der Gast (Standard Edna) ist guter Freund, steht in Zimmer 13 und hält
##                               Wache, sobald du dich ins Bett legst (mit --sleep=bett); mit --trace „[Wache]“
##   --eier=spieler[,id]|fenster  Eier (6.13): du wirfst nach 1,5 s ein Ei an die Tür des Gastes (Standard Edna), er sieht
##                               es aus dem Flur · fenster: im ersten Zimmer mit Außenfenster klebt Eigelb daran;
##                               Kinder: --prank=egg|eggwindow[,zimmer]; mit --trace „[Wurf]“, „[Eier]“
##   --mode=urteil|snack|raubzug|harmlos|anforderung|keller[,s]  dieser Modus des Leviathan (4.33) in s Sekunden
##                               (Standard 0) · urteil wie --doll · raubzug nicht harmlos, harmlos wie der erste ·
##                               keller: Runde im Keller; mit --trace „[Aufbruch]“
##   --frist=s                   Frist bis zum Notausgang des Leviathan (4.33) in s statt 60 s (Urteil gegen dich), 120 s
##                               (Urteil gegen einen Gast, Raubzug: so lange stehst du offen da) – mit --mode=raubzug
##                               erscheint es danach 1–2 Räume neben dir, 8–10 s Warnung
##   --plan                      mit --trace: den Plan der Modi gleich würfeln und ausgeben (der erste Angriff gilt als geschehen)
##   --bold=n                    Dreistigkeit setzen (ohne Obergrenze, Anforderung ab 55, 4.33)
##   --friend=id                 mit einem Gast befreundet starten (edna, bruno, mila, gast1 …)
##   --enemy=id                  mit einem Gast verfeindet starten
##   --relation=id,wert          Beziehung setzen (−100 … 100); ab ±80 werden die nötigen Taten mit eingetragen (6.3)
##   --einbruch=id[,eigen|tagebuch|zeuge]  Gast ist stark verfeindet und bricht gleich in Zimmer 13 ein (6.19), du
##                               stehst im Flur mit Blick auf die Tür · eigen: in Zimmer 13 liegt etwas, das du ihm genommen
##                               hast · tagebuch: im Tagebuch steht ein Diebstahl bei einem anderen Gast, der erfährt es vom
##                               Einbrecher · zeuge: ein Gast sieht neben der Tür zu und nennt später den Namen (--trace)
##   --feind=id[,tuer|versteck]  Feinde (6.18): tuer – verfeindet, daheim bei offener Tür, du davor, er schließt ab ·
##                               versteck – stark verfeindet, sieht dich in Zimmer 13 in den Schrank steigen und ruft es aus
##   --zweitschluessel=id[,zurueck]  mit dem Gast gut befreundet (mit den Taten, 6.3), er steht vor dir und gibt dir gleich
##                               den Zweitschlüssel seines Zimmers (6.19) · zurueck: danach verfeindet ihr euch, 10 s
##                               später ist das Schloss getauscht (--trace „[Zimmer]“)
##   --follow=id · --visit=id    Gast kommt mit (steht hinter dir) · Gast geht zu Zimmer 13 und klopft an
##   --attack=id                 Gast steht vor dir und schlägt zu
##   --punch=id                  Gast vor dich stellen und ihn schlagen (mit Nachfrage)
##   --kill=id[,geist|kuerbis]   Gast nach 3 s vom Monster holen lassen (überlebt mit 20 %, geschützte Kernfiguren immer: Kratzer, 6.17) · geist/kuerbis:
##                               nach 1,5 s vor dir erwürgt bzw. erschlagen, die Leiche bleibt liegen (Totenkopf)
##   --kill=id,leiche|weg[,blut][,hin]   sofort tot, ohne Monster: liegt da bzw. ist verschwunden (Kratzer, Schuh) · blut:
##                               Lache und Wandspritzer (ohneblut: auch beim Kürbismann keins) · hin: 1,3 m vor dir
##                               Statt der ID geht überall auch der Name (emil, EmilBecker, juergen …)
##   alle statt Gast             bei --relation, --friend, --enemy, --drunk=n,alle, --wound, --kill (nur sofort): für jeden
##                               lebenden Gast; kill/wound ohne Kinder (kinder: mit), hin wird ignoriert
##   --despawn[=monster|geist|kuerbis]   die Bedrohung (ohne Angabe alle) ist sofort fort, auch Vorwarnung/Ankündigung
##   --zugleich                  drei Bedrohungen zugleich (4.20, ZIM-48), jede auf ihrem eigenen Weg: Geisterstunde um
##                               Mitternacht, dann die Garantie des Kürbismanns, dann ein Snack – „[Zugleich] … ok“
##   --bulb-thief=id             Gast klaut sofort eine Glühbirne aus Zimmer 13
##   --lichtgang=id[,versteckt]  Gast geht ins dunkle Zimmer zum Schalter, nach 30 s wieder hinaus (7.3) · versteckt: du
##                               sitzt in seinem Schrank (sonst unterm Bett) – er macht beim Gehen trotzdem aus
##   --wecken=id[,gefahr|halluzination|klopfen]   Nachtruhe, alle im Bett, du stehst an seinem Bett und weckst ihn nach
##                               2 s (3.6) · gefahr: dazu eine echte Flackerwelle · halluzination: eine falsche (falscher
##                               Alarm) · klopfen: du stehst vor seiner Tür und klopfst
##   --birnenersatz=id[,lager|klauen|meiden]   im Zimmer des Gastes (Haushaltsvorstand) fehlen alle Birnen, er steht
##                               darin (7.3) · lager (Standard): er holt Ersatz aus dem Lager im Plan · klauen: mutig, ohne
##                               Lager, holt eine aus einem leeren Raum oder Flur · meiden: ängstlich, ohne Lager, nach
##                               20 s beginnt die Nachtruhe
##   --bad=id                    Gast geht gleich in sein Bad und schließt die Tür (6.19), du stehst im Zimmer davor
##   --kerzenpflege=id[,ohne]    Kerzen vor der Tür des Gastes gehen aus (ohne: in Kürbis und Totenkopf abgebrannt), er
##                               steht ein paar Meter davor und kümmert sich darum (5.12)
##   --abbrennen[=rest]          alle Kerzen (auch feste, in Kürbis und Totenkopf) haben nur noch rest übrig (Standard
##                               0,02 – etwa eine halbe Minute), 5.12
##   --steal-test                Ednas Deko unbemerkt nehmen (Schuld-Test)
##   --player-deco=x,z           geschnitzten Kürbis des Spielers an diese Stelle stellen
##   --wound=gast,scratch|axe|choke[,hin]   Gast hat überlebt (6.17): Kratzer, Axtwunde (Blutspur, ein Tag im Bett) bzw.
##                               Würgemale (heiser, schweres Atmen) · hin: steht vor dir statt im Bett (mit --talk=gast)
##   --wallblood[=smear]         Blutspritzer (smear: blutige Schmierspur) an die Wand, auf die du schaust (4.13)
##   --costumes[=art]            alle Gäste sofort verkleidet (sonst ab dem 25.): jeder sein Kostüm, art = sheet|witch|
##                               pumpkin|cape für alle gleich (5.9)
##   --disguise                  Bettlaken übergeworfen (5.9): Sicht durch Augenlöcher, Gäste erkennen dich nur aus der Nähe
##   --maske[=id[,pruefen]]      verbotene Masken (5.19): vor dem Maskenboard in Zimmer 13 stehen · id (pumpkin|doll|
##                               scarecrow|crow|cat): diese Maske gleich aufgesetzt (Kürbismann: Spaßschwelle tief; die drei
##                               ohne Gegenstand nur im Debug ohne Stift) · pruefen: leichte Wirkung prüfen – doll: ein Kind
##                               in der Lobby flüstert und hält Abstand, scarecrow: Krähen lassen Münze und Messer liegen,
##                               crow: Fütterung zählt doppelt, cat: eine Hotelkatze läuft nach („[Maske] … ok“/„FEHLER“)
##   --drunk=n[,gast]            n Gläser getrunken (du, mit Gast: er) – ab 2 angetrunken, ab 3 betrunken (3.7)
##   --weather=klar|regen|gewitter|boe|blitz|gestalt|blut   Wetter sofort in voller Stärke (7.8) · boe: Gewitter und gleich
##                       eine heftige Böe · blitz: gleich ein Blitz
##                       (mit Gewitter) · gestalt: dazu eine Gestalt zwischen den Bäumen, der Spieler wird hingedreht ·
##                       blut: Blutregen (Seltenwetter)
##   --party[=gast]              sofort eine Feier im Partyraum starten (mit Gast: er lädt ein, ~3/4 kommen;
##                               sonst du – dann kommen nur Eingeladene und Freunde)
##   --cat=id[,tragen]           Hotelkatze vor den Spieler setzen (minka, socke, kasimir; im Katzenraum luna, fussel, tiger, mausi) – mit tragen gleich auf den Arm
##   --pumpkin[=anim]            Kürbismann als Testfigur (ohne Verhalten) 2,5 m vor dich, Animation in Schleife:
##                               walk (Standard), run, spin_jump, chicken, macarena, hiphop – ersetzt eine alte
##   --pumpkin=jagd[,gast]       Kürbismann (Spielkonzept 4.19) kommt übers Lobbydach und jagt dich bzw. den Gast
##   --pumpkin=dach              wie F9: Kürbismann klettert übers Lobbydach, springt in den Garten, sucht die Lobby ab
##   --pumpkin=garten            Kürbismann gleich an den Kürbisbeeten im Garten (ohne Dach), jagt alle mit Spaß und dich
##   --pumpkin=zeigen[,was]      Kürbismann erscheint in der Lobby gut 5 m vor dir und jagt dich, du hältst einen Kürbis
##                               (4.21, 1): geschnitzt (Standard), kerze, eine Sorte (halloween, hokkaido …), mini, brei,
##                               braten – oder zwei (nach der ersten Betäubung ein zweiter geschnitzter in die Hand)
##   --talk=id                   direkt ein Gespräch mit dem Gast öffnen
##   --gespraech=frage,id,gast[,n]   Gespräch, in dem der Gast diese Frage stellt (6.9: ghosts, night, contest, room,
##                               brave, play, escort), mit n gleich die n-te Antwort
##   --gespraech=erlebnis,art,gast[,erzaehlen]   ein eigenes Erlebnis (monster, ghost, pumpkin, corpse, blood,
##                               ghost_visit, attic) hier, dann Gespräch – mit erzaehlen gleich als Anlass erzählt
##   --gespraech=luege,art,gast[,wer]   dem Gast etwas vorlügen (geist, monster, kuerbis, leiche, dieb); bei leiche/dieb
##                               kommt der Genannte nach 3 s vorbei – die Lüge fliegt auf (--trace)
##   --bitte=gast[,art[,annehmen|erfuellen]]  der Gast stellt seine Bitte (6.14; art: herz – Standard –, kuerbis,
##                               kerze, kaffee, suess, mag, ring – seltene Bitte, nur gerda); annehmen: gleich zusagen,
##                               erfuellen: auch erfüllen ([Bitte]; ring: aus dem Dachnest holen, „[Ring] … ok“/„FEHLER“)
##   --look=id[,pose]            Gast ansehen (ohne Dialog, er bleibt stehen); pose: carry (trägt einen Kürbis),
##                               panic (Arme hoch), dance (tanzt), sit (sitzt), walk (geht quer vorbei) –
##                               zum Prüfen der Gastmodelle
##   --shock=id[,blood|lache|corpse|ghostN|tür]  Gast erschrecken (6.12): Blutlache bzw. Leiche vor ihm im Flur (lache:
##                               fast unter ihm – er tritt an ihren Rand zurück, 4.13), oder der Lakengeist kommt zum N.
##                               Mal an sein dunkles Zimmerfenster (ab 3 würgt er) – mit --talk=id erzählt er davon
##   --dice=id                   sofort Mäxchen mit dem Gast (Einsatz 3 Geld)
##   --chess=id                  sofort Schach mit dem Gast in der Lobby (Einsatz 3 Geld; mit --autoplay zieht der Spieler selbst)
##   --darts[=id]                sofort Darts in der Bar: allein üben, mit id gegen den Gast (Einsatz 3 Geld; mit
##                               --autoplay wirft der Spieler selbst)
##   --spieleschrank             den Spieleschrank in der Bar öffnen (Spielkonzept 6.10)
##   --bowling                   Bowling an der Bahn in der Bar beginnen (Spielkonzept 6.10; mit --autoplay rollt
##                               der Spieler selbst in die Tasche und spielt Frame um Frame)
##   --zinken[=bar]              gezinkte Würfel in den Becher am Mäxchen- bzw. Barspieltisch tauschen (wie mit [E])
##   --bargame=spiel[,id]        sofort ein Barspiel am Würfeltisch gegen den Gast (Standard bruno, Einsatz 3 Geld):
##                               schocken, armdruecken, bierdeckel, trinkduell, siebzehn, quiz, wahrheit – das Spiel
##                               aus dem Schrank liegt dann gleich auf dem Tisch (Spielkonzept 6.10)
##   --challenge=id[,chess|darts|barspiel]  Gast fordert dich heraus (Mäxchen, Schach, Darts bzw. ein Barspiel)
##   --gastspiel[=schocken|armdruecken]  zwei Gäste spielen am zweiten Würfeltisch (6.10, ZIM-73), danach Prüfungen
##                               der Herausforderungen zum Lieblings-Barspiel („[Gastspiel] … ok“ bzw. „FEHLER“)
##   --autoplay                  Mäxchen-Antworten, Schachzüge, Dart- bzw. Bowlingwürfe automatisch wählen
##   --shot=pfad.png             Screenshot speichern und beenden
##   --frames=n                  Frames bis zum Screenshot (Standard 120)
##   --shot-size=BxH             Fenster für den Screenshot in dieser Größe (rahmenlos, auch über den Bildschirm hinaus)
##   --shot-on=jumpscare|strangle|shock|pumpkin|lightning|repel  Screenshot kurz nach einem Ereignis statt nach n Frames
##                               (Kürbismann auch pumpkin_roof|pumpkin_edge|pumpkin_leap|pumpkin_land|pumpkin_lobby;
##                               Kesselkatze kesselkatze beim Auftauchen, kesselkatze_rauch beim Auflösen)
##   --bg                        Fenster im Hintergrund: kein Fokus, außerhalb des Bildschirms (Game._to_background)
##   --navcheck                  Bau- und NavMesh-Zeit, Wege von Zimmer 13 zu allen wichtigen Orten (Spielkonzept 7.5)
##   --navcheck=tueren           Wege vom Keller (Versteck des Monsters) zu jeder bewohnten Zimmertür (4.33, Punkt 5)
## Vorzeichen und Spuk (4.25–4.31, 5.14–5.18, 6.21):
##   --kraehen[=groll]           im Garten 7 m vor den Krähen · groll: sie haben sich dich gemerkt und krächzen dich an
##   --kraehen=gunst|stehlen     volle Gunst · Münze und Messer liegen vor ihnen, du siehst weg – eine Krähe holt sie ins Nest
##   --kraehen=nest|werfen       2,5 m vor dem Krähennest gegenüber von Zimmer 042, Blick hinauf (darin dazu Münzen und Kompass)
##                               · werfen: nach 1 s fliegt eine Münze hinein, ein Stück fällt heraus
##   --kraehen=futter|schluessel vor dem Futtertisch im Gärtchen von 13 (ohne Tisch im Plan ein Ersatztisch), Brotkrumen
##                               darauf, die Zeit fast um, nach 3 s siehst du weg · schluessel: hohe Gunst nach drei Tagen –
##                               statt des Futters liegt der Schlüssel von 1987 da
##   --kraehen=geschenk          wie futter, Gunst knapp über der Schwelle – es kommt Kleinzeug (Batterie, Streichhölzer, Kerze)
##   --kraehen=dachnest          unter dem Dachfenster mit dem Krähennest (ZIM-50), Blick hinaus – darin Gerdas Ehering
##   --ratten[=welle]            fünf Ratten um dich im Keller (sonst im Heizkeller) · welle: nach 2 s rennen sie davon, als käme
##                               das Monster aus dem Heizkeller
##   --hund                      nach 1 s heult hinter der Waldkante ein Hund (sonst zufällig alle paar Spielminuten)
##   --tiere[=eule|kraehen|hunde]  Tiere in der Ferne (7.8): nach 1 s ruft die Eule, krächzen Krähen, bellen Hunde –
##                               ohne Wert alle nacheinander (sonst je nach Uhrzeit und Wetter)
##   --kesselkatze[=pruefen|rauch]  Nacht, UG, 10 m vor einem ungefundenen Story-Punkt: die schwarze Kesselkatze taucht
##                               seitlich im Blickfeld auf – sieh hin, sie geht voraus · pruefen: bleib stehen, prüft
##                               Auftauchen, Richtung, Rauch nach ≤ 60 s, gefundener Punkt fällt heraus (~75 s) ·
##                               rauch: nach 3 s löst sie sich im Blickfeld in Rauch auf
##   --spiegel[=tuch]            vor dem Spiegel in Zimmer 13, nach 2 s steht die Gestalt hinter dir · tuch: er ist verhängt
##   --strom[=kasten]            Gewitter, gleich fliegt die Sicherung · kasten: Strom aus, du vor dem Sicherungskasten im UG
##   --strom=telefon             Strom aus, ein Anruf und der Hörer bleiben tot; nach 4 s Sicherung rein, jetzt klingelt es
##   --albtraum                  Nacht am 16., du schläfst in Zimmer 13 ein – nach 3 s der Traum vom Heizkeller 1987
##   --vogelscheuche[=tag]       sie steht, wo sie an Halloween (bzw. an diesem Tag) stünde, du in der Lobby vor der Gartentür
##   --kind-zu-viel              der 28. abends, ein Kind vor deiner offenen Tür – und eins zu viel dahinter
##   --fotos[=jahr]              vor die Fotowand in der Lobby · jahr: dieses Foto gleich aufgeschlagen (1987, 1990 … 2026)
##                               (2005: das Foto aus dem Sekretariat) · pruefen: die Ernte alle drei Jahre (2.10, ZIM-117) –
##                               Fotos, Fundstück 2005, Register, Zettel, Zimmer 18, Walter/Oskar, Ankunftsfoto 2026 mit
##                               Gustavs Kreuz; „[Fotowand] … ok/FEHLER“, zuletzt „[Fotowand] Prüfung fertig“
##   --leviathan[=benannt|liesel] erste bestätigte Sichtung: Hugo holt Dorés Druck, du am Couchtisch der Lobby (4.32) ·
##                               benannt: schon geschehen, du vor dem Druck an der Wand · liesel: Hugo ist tot
##   --leviathanfoto[=haengt|pruefen] Paula hat eben einen Angriff fotografiert, gleich hängt das Foto (ZIM-101), du vor
##                               der Fotowand · haengt: es hängt schon, aufgeschlagen · pruefen: wann Paula es mitbekommt,
##                               Platz an der Wand, Skeptiker, Speichern, ohne Paula kein Foto; „[Leviathanfoto] … ok/FEHLER“
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

	var grass := Grass.new()   # Grasbüschel – nach dem NavMesh
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

	var bowling := BowlingMatch.new()
	bowling.name = "BowlingMatch"
	add_child(bowling)
	Game.bowling = bowling

	# Barspiele am Würfeltisch (Spielkonzept 6.10, 28.10.) – Reihenfolge wie im Dialog (BarMatch.GAMES)
	for bar_game: BarMatch in [SchockenMatch.new(), ArmWrestleMatch.new(), CoasterTowerMatch.new(), DrinkDuelMatch.new(),
			SeventeenFourMatch.new(), PubQuizMatch.new(), TruthDareMatch.new()]:
		bar_game.table = builder.bar_table if builder.bar_table else builder.game_table
		add_child(bar_game)
		Game.bar_games[bar_game.id] = bar_game

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
	var diag := LightDiag.new()   # F2/F4/F11: Position, Lichtanzeige, Bericht, Schattenatlas (ZIM-169)
	diag.name = "LightDiag"
	diag.shadows = $ShadowBudget
	diag.builder = builder
	add_child(diag)
	var photo := PhotoMode.new()   # F12: freie Kamera durch Wände, der Spieler bleibt stehen
	photo.name = "PhotoMode"
	photo.shadows = $ShadowBudget
	add_child(photo)

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
	var photos := PhotoWall.new().setup(builder)   # Gruppenfotos in der Lobby (5.14, Plan: ZIM-133)
	photos.name = "Fotowand"
	add_child(photos)
	Game.photo_wall = photos
	var register := HotelRegister.new().setup(builder)   # Hotelregister auf der Rezeption (2.3)
	register.name = "Hotelregister"
	add_child(register)
	register.global_transform = builder.register_spot
	Game.register = register
	var office := DirectorOffice.new()   # Büro der Direktion und Sekretariat: Schlüssel, Zahlenschloss (2.8, 2.10, ZIM-6)
	office.name = "BueroDerDirektion"
	add_child(office)
	office.setup(builder)   # Schreibmaschine im Sekretariat, Aushang Betriebsferien (2.11, ZIM-119)
	Game.director_office = office
	var sealed := SealedRooms.new()   # versiegelte Zimmer von 1987: 042, 132, 038 (6.19 (7), ZIM-30)
	sealed.name = "VersiegelteZimmer"
	add_child(sealed)
	sealed.setup(builder)
	Game.sealed_rooms = sealed
	CaretakerBook.furnish(builder)   # Zimmer 18: Notizbuch des Hausmeisters, Schaltschlüssel, UV-Aufsatz (7.4)
	LiftDrive.place(builder)   # Maschinenraum: Antrieb des Aufzugs mit der Kurbel für die Bremse (7.4, ZIM-14)
	var cemetery := Cemetery.new()   # Friedhof westlich des Kürbisfelds (5.15)
	cemetery.name = "Friedhof"
	add_child(cemetery)
	cemetery.setup(builder.grave_slots, builder.memorial_spot)
	Game.cemetery = cemetery
	var naming := LeviathanName.new().setup(builder)   # der Name Leviathan, Hugos Druck (4.32)
	naming.name = "NameLeviathan"
	add_child(naming)
	Game.leviathan_name = naming
	var doll_house := DollHouse.new()   # Puppenhaus in der Bibliothek (5.16)
	doll_house.spot = builder.planned_at("doll_house", doll_house.spot)
	doll_house.name = "Puppenhaus"
	add_child(doll_house)
	Game.doll_house = doll_house
	var faces := PumpkinFaces.new()   # Kürbisgesichter, die sich verändern (5.18)
	faces.name = "PumpkinFaces"
	add_child(faces)
	Game.pumpkin_faces = faces
	var tub := AppleTub.new()   # Apfeltauchen im Partyraum (6.21)
	tub.spot = builder.planned_at("apple_tub", Transform3D(Basis(), tub.spot)).origin
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
	SaveManager.reset_pending()


## Neues Spiel in einem Slot: Startzustand gleich speichern, damit „Fortsetzen“ greift.
func _save_start(slot: int) -> void:
	for i in 3:
		await get_tree().process_frame
	SaveManager.save_to(slot, DoorContest.ARRIVAL_ENTRY, get_viewport().get_texture().get_image())


## Einstellungen auf die Welt: Spiegelungen und die Grafikstufe (Settings.GRAPHICS – Fenster und RenderingServer stellt
## Settings.apply ein, die Kamera Player)
func _apply_settings() -> void:
	var g := Settings.graphics_level()
	_env.ssr_enabled = Settings.reflections
	_env.ssr_max_steps = g["ssr_steps"]
	_env.ssao_enabled = g["ssao"]
	_env.sdfgi_enabled = g["sdfgi"]
	_env.fog_depth_end = g["view"]
	(get_node("Moon") as DirectionalLight3D).directional_shadow_max_distance = g["moon_distance"]
	ShadowBudget.full = g["full"]
	Books.apply_graphics(get_tree())
	if _post:
		_post.set_shader_parameter("gamma", Settings.gamma)


func _process(delta: float) -> void:
	_sky_time += delta
	_sky.set_shader_parameter("sky_time", _sky_time)
	if _post and Game.player:   # verschwommene Sicht (Spielkonzept 3.6/3.7)
		_post.set_shader_parameter("blur", maxf(Game.player.sight_blur, Game.player.intro_blur))
		_post.set_shader_parameter("warp", Game.player.sight_warp)
		_post.set_shader_parameter("dark", Game.player.sight_dark)
		_post.set_shader_parameter("blur_time", _sky_time)
	if _autoplay and Engine.get_process_frames() % 100 == 0 and Game.dice.active:
		print("[Mäxchen] " + Game.dice.debug_press_random())
	if _autoplay and Engine.get_process_frames() % 30 == 0 and Game.chess.active:
		var step := Game.chess.debug_step()
		if step != "":
			print("[Schach] " + step)
	if _autoplay and Engine.get_process_frames() % 60 == 0:
		for bar_game: BarMatch in Game.bar_games.values():
			if bar_game.active:
				var step := bar_game.debug_press_random()
				if step != "":
					print("[%s] %s" % [bar_game.title, step])
	if _autoplay and Engine.get_process_frames() % 40 == 0 and Game.darts.active:
		var throw := Game.darts.debug_step()
		if throw != "":
			print("[Darts] " + throw)
	if _autoplay and Engine.get_process_frames() % 40 == 0 and Game.bowling.active:
		var roll := Game.bowling.debug_step()
		if roll != "":
			print("[Bowling] " + roll)
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
	env.ssr_max_steps = 128   # Hoch – je Grafikstufe in _apply_settings
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
	env.fog_depth_end = 66.0   # Hoch – Sichtweite je Grafikstufe in _apply_settings
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
	moon.directional_shadow_max_distance = 40.0   # je Grafikstufe in _apply_settings
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


## --meshes: zwei Bilder warten, dann zählen, wie viele verschiedene Meshes (und Flächen – je Fläche legt die
## Grafikkarte eigene Puffer an) in der Szene stecken. Manche Vulkan-Treiber (Onboard-Grafik) brechen bei zu
## vielen Puffern mit „VkResult error -10“ ab (TECHNIK.md 1 „Grafik“). Als Startparameter danach beenden.
func _count_meshes(quit: bool) -> void:
	for i in 2:
		await get_tree().process_frame
	var meshes := {}   # Instanz-ID → Mesh
	var instances := 0
	var stack: Array[Node] = [get_tree().root]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		stack.append_array(node.get_children())
		var m: Mesh = null
		if node is MeshInstance3D:
			m = (node as MeshInstance3D).mesh
		elif node is CPUParticles3D:
			m = (node as CPUParticles3D).mesh
		elif node is MultiMeshInstance3D and (node as MultiMeshInstance3D).multimesh:
			m = (node as MultiMeshInstance3D).multimesh.mesh
		if m:
			instances += 1
			meshes[m.get_instance_id()] = m
	var surfaces := 0
	var by_class := {}
	for m: Mesh in meshes.values():
		surfaces += m.get_surface_count()
		var kind := m.get_class() + (" (Datei)" if m.resource_path != "" else "")   # importierte Modelle teilen sich ohnehin
		by_class[kind] = by_class.get(kind, 0) + 1
	var text := "[Meshes] %d Instanzen, %d verschiedene Meshes, %d Flächen – %s" % [instances, meshes.size(), surfaces, by_class]
	print(text)
	if quit:
		get_tree().quit()
	else:
		Game.say(text, 6.0)


func _on_player_died() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	add_child(DeathScreen.new())


func _parse_debug_args() -> void:
	for arg in OS.get_cmdline_user_args():
		run_debug(arg)


## Ist arg der Debug-Befehl name, allein oder mit Wert („--name“ bzw. „--name=…“)?
static func _is_arg(arg: String, name: String) -> bool:
	return arg == name or arg.begins_with(name + "=")


## Wert eines Debug-Befehls: alles hinter „--name=“ – ohne Wert (auch bei „--name=“ ohne etwas dahinter) default.
## Ob arg überhaupt der Befehl name ist, prüft der Zweig in run_debug.
static func _arg_value(arg: String, name: String, default := "") -> String:
	var value := arg.substr(name.length() + 1) if arg.begins_with(name + "=") else ""
	return value if value != "" else default


## Wert eines Debug-Befehls, an den Kommas geteilt (ohne Wert: default bzw. ein leeres Stück).
static func _arg_parts(arg: String, name: String, default := "") -> PackedStringArray:
	return _arg_value(arg, name, default).split(",")


## --spion[=leer|echt|falsch|auge] (7.17): Spieler steht in Zimmer 13 vor der Tür und zielt auf den Spion, nach 1 s [E].
## echt/falsch: dabei klopft es (wie --knock), auge: der Leviathan steht seitlich im Flur und beugt sich an die Linse.
## Ohne auge drückt er nach 6 s noch einmal [E] (Hinsehen endet).
## --schwelle[=flur|zimmer|nah] (ZIM-132): Tür von Zimmer 13 offen, du stehst davor (im Flur bzw. im Zimmer) und siehst
## schräg hinab auf die Messingschiene, nah: dicht darüber. Mit --trace: unter wie vielen Türen kein Boden liegt.
func _debug_threshold(where: String) -> void:
	var info: Dictionary = Game.social.builder.rooms[LevelBuilder.PLAYER_ROOM]
	var door: Door = info["door"]
	var out := door.corridor_dir()
	var at := door.global_position + door.global_transform.basis.x * door.width / 2.0
	var side := -out if where == "zimmer" else out
	var p := Game.player
	p.global_position = at + side * (0.35 if where == "nah" else 1.1) + Vector3(0, 0.05, 0)
	p.rotation.y = atan2(side.x, side.z)
	p.head.rotation.x = deg_to_rad(-76.0 if where == "nah" else -38.0)
	door.set_open(true, true, true)
	if Game.tracing:
		get_tree().create_timer(0.5).timeout.connect(func() -> void:
			var space := p.get_world_3d().direct_space_state
			var missing := 0
			var doors := get_tree().get_nodes_in_group("doors")
			for node in doors:
				var d := node as Door
				var mid := d.global_position + d.global_transform.basis.x * d.width / 2.0
				# beide Hälften (genau auf der Fuge trifft der Strahl keins der Stücke), von oben bis unter den Boden;
				# was niemand öffnet, darf seinen Boden auch auf der Ebene der Decken haben
				for shift: float in [-0.05, 0.05]:
					var at_side: Vector3 = mid + d.global_transform.basis.z * shift
					var q := PhysicsRayQueryParameters3D.create(at_side + Vector3(0, 0.5, 0), at_side - Vector3(0, 0.3, 0),
						1 if d.monster_can_open else 1 | LevelBuilder.LAYER_CEILING)
					var hit := space.intersect_ray(q)
					if hit.is_empty() or absf((hit["position"] as Vector3).y - d.global_position.y) > 0.01:
						missing += 1
						print("[Schwelle] kein Boden bei %s (%s)" % [at_side.snapped(Vector3.ONE * 0.01),
							d.room_no if d.room_no != "" else d.room_id])
			print("[Schwelle] %d Türen, %d Hälften ohne Boden darunter" % [doors.size(), missing]))


## --fenstertuer[=innen|aussen|eingang|glastuer] (ZIM-126): Spieler 2,6 m vor der Gartentür von Zimmer 13 (sonst der
## ersten Fenstertür) im Zimmer bzw. draußen, 4 m vor dem Haupteingang in der Lobby oder 2,6 m vor der Doppel-Glastür,
## die der Bar am nächsten ist (Lobbyseite), Blick auf die Tür. Mit --trace: jede Fenstertür (french_doors) muss
## Look.GARDEN mit Glas sein, der Haupteingang Look.ENTRANCE, jede andere Glastür Look.GLAZED – sonst
## „[Fenstertuer] FEHLER“.
func _debug_french_door(where: String) -> void:
	var door: Door
	var bar: Rect2 = Game.social.builder._named.get("bar", Rect2())
	var near_bar := func(d: Door) -> float:
		return Vector2(d.center().x, d.center().z).distance_to(bar.get_center())
	for node in get_tree().get_nodes_in_group("doors"):
		var d := node as Door
		if where == "eingang" and d.key_id == "ausgang":
			door = d
		elif where == "glastuer":
			if d.look == Door.Look.GLAZED and (door == null or near_bar.call(d) < near_bar.call(door)):
				door = d
		elif where in ["innen", "aussen"] and d.is_in_group("french_doors") and (door == null or d.room_id == LevelBuilder.PLAYER_ROOM):
			door = d
	if door == null:
		push_error("--fenstertuer: keine passende Tür im Plan")
		return
	# Seite: draußen = outward; der Haupteingang geht nach innen auf (+Z)
	var out := door.outward if door.outward != Vector3.ZERO else -door.global_transform.basis.z
	var side := out if where == "aussen" else -out
	if where == "glastuer":   # von der Seite, die von der Bar abgewandt ist
		var c := door.center()
		side = out if Vector2(out.x, out.z).dot(Vector2(c.x, c.z) - bar.get_center()) > 0.0 else -out
	var at := door.center()
	var p := Game.player
	p.global_position = Vector3(at.x, door.global_position.y, at.z) + side * (4.0 if where == "eingang" else 2.6) 		+ Vector3(0, 0.05, 0)
	p.rotation.y = atan2(side.x, side.z)
	p.head.rotation.x = deg_to_rad(-2.0)
	if Game.tracing:
		var counts := {"garden": 0, "entrance": 0, "glazed": 0, "errors": 0}
		for node in get_tree().get_nodes_in_group("doors"):
			var d := node as Door
			var bad := ""
			if d.is_in_group("french_doors") and (d.look != Door.Look.GARDEN or not d.glass):
				bad = "Fenstertür ohne Glas-Modell"
			elif d.key_id == "ausgang" and d.look != Door.Look.ENTRANCE:
				bad = "Haupteingang ohne Modell"
			elif d.glass and not d.look in [Door.Look.GARDEN, Door.Look.ENTRANCE, Door.Look.GLAZED]:
				bad = "Glastür ohne Modell"
			if bad != "":
				counts["errors"] += 1
				print("[Fenstertuer] FEHLER %s bei %s" % [bad, d.global_position.snapped(Vector3.ONE * 0.01)])
			counts["garden"] += int(d.look == Door.Look.GARDEN)
			counts["entrance"] += int(d.look == Door.Look.ENTRANCE)
			counts["glazed"] += int(d.look == Door.Look.GLAZED)
		print("[Fenstertuer] %d Gartentüren, %d Haupteingang, %d Glastüren, %d Fehler" % [counts["garden"],
			counts["entrance"], counts["glazed"], counts["errors"]])


## --zierleiste[=flur|zimmer|lobby|speisesaal] (ZIM-131): Blick schräg hinauf in eine Ecke mit Zierleiste – vor
## Zimmer 13 den Flur entlang, im Zimmer in die hintere Ecke, in Lobby und Speisesaal (große Leiste) aus 4,5 m in die
## Nordwestecke (über einem Luftraum unter der Decke des OG). Mit --trace: Stücke und Dreiecke je Stockwerk; Leisten im
## Keller oder Dachgeschoss oder außerhalb der Höhe unter der Decke melden „[Zierleiste] FEHLER“.
func _debug_cornice(where: String) -> void:
	var b := Game.social.builder
	var info: Dictionary = b.rooms[LevelBuilder.PLAYER_ROOM]
	var p := Game.player
	var at: Vector3 = info["door_front"]
	var into: Vector3 = info["into"]
	var along: Vector3 = info["along"]
	var target := at + along * 4.0 - into * 1.2
	var top := LevelBuilder.H
	match where:
		"zimmer":
			at = (info["center"] as Vector3) - into * 0.5
			target = at + into * 4.0 + along * 4.0
		"lobby", "speisesaal":
			var r: Rect2 = b._lobby if where == "lobby" else b._named[LevelBuilder.DINING_ROOM]
			target = Vector3(r.position.x, 0.0, r.position.y)
			at = target + Vector3(1.0, 0.0, 1.0).normalized() * 4.5
			for hall in b._halls:
				if (hall["rect"] as Rect2).grow(0.5).has_point(Vector2(target.x, target.z)):
					top += LevelBuilder.UP_Y
	target.y = at.y + top - Cornice.HEIGHT
	p.global_position = at + Vector3(0, 0.05, 0)
	var flat := Vector3(target.x - at.x, 0.0, target.z - at.z)
	p.rotation.y = atan2(-flat.x, -flat.z)
	p.head.rotation.x = atan2(target.y - p.camera.global_position.y, flat.length())
	if not Game.tracing:
		return
	get_tree().create_timer(0.5).timeout.connect(func() -> void:
		var counts := {}
		var wrong := 0
		for node in b.root.find_children("*Zierleiste*", "MeshInstance3D", true, false):
			var mi := node as MeshInstance3D
			var storey := String(mi.get_parent().name) if mi.get_parent() != b.root else "Erdgeschoss"
			if not counts.has(storey):
				counts[storey] = Vector2i.ZERO
			counts[storey] += Vector2i(1, mi.mesh.surface_get_array_index_len(0) / 3)
			var box := mi.mesh.get_aabb()
			var low := LevelBuilder.H - Cornice.HEIGHT * Cornice.GRAND - 0.01
			if storey in ["Untergeschoss", "Dachgeschoss"] or box.position.y < low or box.end.y > LevelBuilder.H + 0.01:
				wrong += 1
				print("[Zierleiste] FEHLER: Stück in %s, Höhe %.3f … %.3f" % [storey, box.position.y, box.end.y])
		for storey: String in counts:
			print("[Zierleiste] %s: %d Stücke, %d Dreiecke" % [storey, counts[storey].x, counts[storey].y])
		if counts.is_empty():
			print("[Zierleiste] FEHLER: keine Zierleiste gebaut")
		print("[Zierleiste] %d Stücke außerhalb" % wrong))


func _debug_peephole(what: String) -> void:
	var info: Dictionary = Game.social.builder.rooms[LevelBuilder.PLAYER_ROOM]
	var door: Door = info["door"]
	var p := Game.player
	var out := door.corridor_dir()
	p.global_position = Vector3(door.peephole_point().x, door.global_position.y + 0.05, door.peephole_point().z) - out * 0.55
	p.rotation.y = atan2(out.x, out.z) + PI
	p.head.rotation.x = 0.0
	Game.director.first_attack_done = true
	var front: Vector3 = info["door_front"]
	match what:
		"echt", "falsch":
			door.locked = true   # sonst öffnete das Monster sie im Vorbeigehen (Monster._open_doors)
			Game.monster.spawn_at(Game.social.builder.wander_points[8] + Vector3(0, 0.05, 0))
			Game.social._knock_cooldown = 0.2
			Game.social.debug_fake_knock = what == "falsch"
			Game.social.debug_real_knock = what == "echt"
		"auge":
			door.locked = true   # unverschlossen öffnete es sie im Vorbeigehen (Monster._open_doors)
			Game.director.add_curiosity(front, 60.0)
			PeepholeView.debug_eye = true
	Door.update_lenses(p.global_position)
	if Game.tracing:
		print("[Spion] Lichtpunkte in der Nähe: %d" % Door._lit_dots.size())
	get_tree().create_timer(1.0, false).timeout.connect(func() -> void:
		var eye := p.camera.global_position
		var to := door.peephole_point() - eye
		p.head.rotation.x = atan2(to.y, Vector2(to.x, to.z).length())
		await get_tree().physics_frame
		await get_tree().physics_frame
		if Game.tracing:
			print("[Spion] Hinweis: %s" % door.get_prompt(p))
		if door.aims_at_peephole(p):
			door.interact(p)
		else:
			print("[Spion] FEHLER: Spion nicht anvisiert")
			p.peep(door)
		if what == "auge":
			# erst jetzt, seitlich im Flur und starrend – sonst risse es die Tür auf, bevor man hinsieht
			Game.monster.spawn_at(front + out.cross(Vector3.UP) * 2.0 + Vector3(0, 0.05, 0))
			Game.monster.stare()
		if Game.tracing:
			print("[Spion] SubViewport an: %s, Spielerkamera aus: %s" % [p.view_camera() != p.camera, p.camera.cull_mask == 0]))
	if what == "auge":
		get_tree().create_timer(5.0, false).timeout.connect(func() -> void:
			if Game.tracing:
				print("[Spion] Leviathan bemerkt: %s, schaut noch: %s" % [Game.monster.noticed, p.is_peeping()]))
		return
	get_tree().create_timer(6.0, false).timeout.connect(func() -> void:
		var ev := InputEventAction.new()
		ev.action = "interact"
		ev.pressed = true
		Input.parse_input_event(ev)
		await get_tree().process_frame
		await get_tree().process_frame
		if Game.tracing:
			print("[Spion] nach [E]: schaut noch: %s, Spielerkamera zurück: %s" % [p.is_peeping(), p.camera.cull_mask != 0]))


## --gedraenge (ZIM-155): Paare stehender Gäste enger als Guest.PERSONAL_SPACE und Belegung der festen Plätze.
func _report_crowding() -> void:
	var standing := Game.social.living_guests().filter(func(g: Guest) -> bool: return g.state == Guest.State.IDLE)
	var close := 0
	for i in standing.size():
		for j in range(i + 1, standing.size()):
			var a: Vector3 = standing[i].global_position
			var b: Vector3 = standing[j].global_position
			if absf(a.y - b.y) < 1.5 and Vector2(a.x - b.x, a.z - b.z).length() < Guest.PERSONAL_SPACE:
				close += 1
	var fill := ""
	if not standing.is_empty():
		var probe: Guest = standing[0]
		for key in ["bar", "lobby", "kitchen", "garden"]:
			var spots := probe._activity_spots(key)
			fill += " · %s %d/%d" % [key, roundi(probe._occupancy(spots) * spots.size()), spots.size()]
	print("[Gedränge] %d stehen, %d Paare enger als %.1f m%s" % [standing.size(), close, Guest.PERSONAL_SPACE, fill])


## Einen Debug-Befehl ausführen – beim Start für jeden Parameter, im Spiel aus der Debug-Konsole
## (DebugConsole, dort ohne „--“ getippt). false = unbekannt. Neuer Befehl: hier ein Zweig, eine Zeile
## im Kopfkommentar, in DebugConsole.COMMANDS und in der README.
func run_debug(arg: String) -> bool:
	if _debug_all(arg):
		return true
	if arg.begins_with("--mode="):
		# ein Modus des Leviathan (4.33) in s Sekunden – nach 1 s, damit Gäste und NavMesh stehen
		var parts := _arg_parts(arg, "--mode")
		var m := ["", "urteil", "snack", "raubzug", "anforderung", "keller", "harmlos"].find(parts[0])
		if m <= 0:
			return false
		var seconds := parts[1].to_float() if parts.size() > 1 else 0.0
		get_tree().create_timer(1.0).timeout.connect(func() -> void:
			if m == 6:   # harmlos: der erste Raubzug (4.33)
				Game.director.debug_start(MonsterDirector.Mode.RAID, seconds)
				Game.director.raids = 0
			else:
				Game.director.debug_start(m as MonsterDirector.Mode, seconds))
	elif arg.begins_with("--frist="):
		# Frist bis zum Notausgang (4.33): Urteil und Raubzug in s statt 60/120 s
		Game.director.debug_reach = maxf(0.0, _arg_value(arg, "--frist").to_float())
	elif arg == "--plan":
		Game.director.first_attack_done = true
		Game.director._make_plan()
	elif _is_arg(arg, "--static-eg"):
		_export_static(_arg_value(arg, "--static-eg", StaticExport.PATH), arg in OS.get_cmdline_user_args())
	elif arg == "--meshes":
		_count_meshes(arg in OS.get_cmdline_user_args())
	elif arg == "--nur-stockwerk":
		var shadows := $ShadowBudget as ShadowBudget
		shadows.floors_only = not shadows.floors_only
		Game.say("Nur das eigene Stockwerk: %s" % ("an" if shadows.floors_only else "aus"), 2.0)
	elif _is_arg(arg, "--schatten-bias"):
		var parts := _arg_parts(arg, "--schatten-bias", str(ShadowBudget.BIAS))
		if not parts[0].is_valid_float() or (parts.size() > 1 and not parts[1].is_valid_float()):
			return false
		ShadowBudget.set_bias(get_tree(), parts[0].to_float(), parts[1].to_float() if parts.size() > 1 else -1.0)
		Game.say("Schatten: Bias %s%s" % [parts[0], (", Normal Bias " + parts[1]) if parts.size() > 1 else ""], 2.0)
	elif arg.begins_with("--schrift="):
		if not Settings.set_ui_scale_arg(arg):
			return false
		Settings.apply()
		Game.say("Schrift & Menüs: %d %%" % roundi(Settings.ui_scale * 100.0), 2.0)
	elif arg.begins_with("--grafik="):
		var level := ["niedrig", "mittel", "hoch"].find(_arg_value(arg, "--grafik"))
		if level < 0:
			return false
		Settings.set_graphics(level, false)
		Game.say("Grafikstufe: %s" % Settings.graphics_level()["name"], 2.0)
	elif _is_arg(arg, "--lichtdiagnose"):
		var diag := get_node_or_null("LightDiag") as LightDiag
		var m := ["", "position", "licht", "aus"].find(_arg_value(arg, "--lichtdiagnose"))
		if diag == null or m < 0:
			return false
		diag.mode = (diag.mode + 1) % 3 if m == 0 else m % 3
	elif _is_arg(arg, "--atlas"):
		var diag := get_node_or_null("LightDiag") as LightDiag
		if diag == null:
			return false
		var value := _arg_value(arg, "--atlas")
		if value == "":
			diag.next_atlas()
		else:
			var counts := []
			for part in _arg_parts(arg, "--atlas"):
				if not part.is_valid_int():
					return false
				counts.append(part.to_int())
			return diag.set_atlas(counts)
	elif _is_arg(arg, "--bericht"):
		var diag := get_node_or_null("LightDiag") as LightDiag
		if diag == null:
			return false
		var seconds := maxf(0.0, _arg_value(arg, "--bericht", "1").to_float())
		get_tree().create_timer(seconds, false).timeout.connect(func() -> void: diag.report())
	elif arg == "--fps":
		Game.hud.fps_enabled = not Game.hud.fps_enabled
	elif arg == "--nohud":
		Game.hud.visible = not Game.hud.visible
	elif _is_arg(arg, "--fotomodus"):
		var photo := get_node_or_null("PhotoMode") as PhotoMode
		if photo == null:
			return false
		if _arg_value(arg, "--fotomodus") == "pruefen":
			_debug_photo_check(photo)
		else:
			get_tree().create_timer(0.5).timeout.connect(photo.start)
	elif arg.begins_with("--tp="):
		return _debug_teleport(_arg_value(arg, "--tp"))
	elif _is_arg(arg, "--aufzug"):
		var lifts := Game.social.builder.elevators
		if lifts.is_empty():
			return false
		var how := _arg_value(arg, "--aufzug")
		if how == "dach":
			return _debug_lift_attic(lifts[0])
		if how == "reparatur":
			return _debug_lift_repair(lifts[0])
		var at := lifts[0].spot(how in ["innen", "fahrt", "urteil"])
		TeleportUI.place_player(at[0], at[1])
		if how == "offen":
			lifts[0].open_doors()
		elif how == "fahrt":
			lifts[0].ride_to_top()
		elif how == "urteil":
			_debug_judgment_on_13()
			var shuttle := Timer.new()
			shuttle.wait_time = 10.0
			shuttle.timeout.connect(func() -> void:
				if not lifts[0].moving():
					lifts[0].ride_to_top())
			add_child(shuttle)
			shuttle.start()
	elif _is_arg(arg, "--sitzen"):
		var want := _arg_value(arg, "--sitzen", "sofa")
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
		var parts := _arg_parts(arg, "--tuer")
		var no := parts[0].pad_zeros(3)
		if not builder.rooms.has(no):
			return false
		var baths: Array = builder.rooms[no]["baths"]
		if parts.size() > 1 and parts[1] == "innen":   # von drinnen: Bandseite der Zimmertür
			TeleportUI.place_player(builder.rooms[no]["door_inside"], -builder.rooms[no]["into"])
		elif parts.size() > 1 and parts[1] == "bad" and not baths.is_empty():   # im Bad, Blick auf die Badtür
			var bath_door: Door = baths[0]["door"]
			var spot: Vector3 = baths[0]["spot"]
			var to_door := bath_door.global_transform * Vector3(bath_door.width / 2.0, 0, 0) - spot
			TeleportUI.place_player(spot - Vector3(to_door.x, 0, to_door.z).normalized() * 0.6,
				Vector3(to_door.x, 0, to_door.z).normalized())
			set_meta("debug_door", bath_door)
			return true
		else:
			TeleportUI.place_player(builder.rooms[no]["door_front"], builder.rooms[no]["into"])
		set_meta("debug_door", builder.rooms[no]["door"])
	elif _is_arg(arg, "--schluesseldieb"):
		var parts := _arg_parts(arg, "--schluesseldieb")
		var no := parts[0].pad_zeros(3) if parts.size() > 0 and parts[0] != "" else "003"
		var swap := parts.size() > 1 and parts[1] == "tausch"
		get_tree().create_timer(1.0, false).timeout.connect(func() -> void: Game.social.access.debug_steal(no, swap))
	elif arg.begins_with("--werkzeug="):
		var what := _arg_value(arg, "--werkzeug")
		if what == "schluessel":
			Game.player.add_key(RoomAccess.GENERAL_KEY)
		else:
			Game.player.drop_held()
			Game.player.receive_item(Item.create(Item.Kind.CROWBAR if what == "brecheisen" else Item.Kind.TOOLBOX))
		if has_meta("debug_door"):
			var door: Door = get_meta("debug_door")
			get_tree().create_timer(1.0).timeout.connect(func() -> void:
				if Game.tracing:
					print("[Zimmer] Tür %s: %s" % [door.room_no, door.get_prompt(Game.player)])
				door.interact(Game.player))
	elif _is_arg(arg, "--klopfen"):
		var parts := _arg_parts(arg, "--klopfen")
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
	elif arg == "--kernschutz":
		return _debug_core_protection()
	elif _is_arg(arg, "--versiegelt"):
		return _debug_sealed(_arg_value(arg, "--versiegelt", SealedRooms.TRUST_ROOM))
	elif _is_arg(arg, "--schreibmaschine"):
		return _debug_typewriter(_arg_value(arg, "--schreibmaschine", "maschine"))
	elif _is_arg(arg, "--buero"):
		var opts := _arg_parts(arg, "--buero")
		if opts.has("pruefen"):
			return _debug_office_check()
		var variant := "sekretariat" if opts.has("sekretariat") else "direktion"
		var room := "Sekretariat" if variant == "sekretariat" else "Büro der Direktion"
		var office := Game.social.builder.zones.filter(func(z: Dictionary) -> bool: return z["name"] == room)
		if office.is_empty():
			return false
		var desk: Desk = null
		for node in get_tree().get_nodes_in_group("desks"):
			if (node as Desk).variant == variant:
				desk = node
		if desk == null:
			desk = Desk.new(variant)
			add_child(desk)
			desk.global_position = office[0]["center"]
		if opts.has("auf"):
			for i in range(1, desk.is_open.size()):
				desk.set_open(i, true, true)
			desk.fixed[0] = Item.Kind.MATCHBOX   # die Mittelschublade wie im Spiel: aufziehen, Fund fällt hinein
			desk.use_drawer(0, Game.player)
		# schräg von vorn, damit der Sessel vor dem Tisch nicht im Weg steht; hinten: von der Besucherseite; links: vor den
		# linken Unterschrank; nah: über der Platte
		var side := 1.7 if variant == "direktion" else 0.6
		var at := desk.global_position + desk.global_basis.z * (1.3 if variant == "direktion" else 1.5) + desk.global_basis.x * side
		var look := desk.global_position + desk.global_basis.z * 0.6
		var pitch := -20.0
		if opts.has("hinten"):
			at = desk.global_position - desk.global_basis.z * 1.9 - desk.global_basis.x * 0.9
			look = desk.global_position
		elif opts.has("links"):   # schräg vor den linken Unterschrank (Beschläge, Füllungen, Furchen)
			at = desk.global_position + desk.global_basis.z * 1.0 - desk.global_basis.x * 1.6
			look = desk.global_position + desk.global_basis.z * 0.5 - desk.global_basis.x * 0.6
			pitch = -35.0
		elif opts.has("nah"):
			at = desk.global_position - desk.global_basis.z * 0.9 + desk.global_basis.x * 0.3
			look = desk.global_position
			pitch = -50.0
		TeleportUI.place_player(at, look - at)
		Game.player.head.rotation.x = deg_to_rad(pitch)
	elif _is_arg(arg, "--regale"):
		var library := Game.social.builder.zones.filter(func(z: Dictionary) -> bool: return z["name"] == "Bibliothek")
		if library.is_empty():
			return false
		var shelves := get_tree().get_nodes_in_group("bookshelves")
		var shelf: Bookshelf = shelves[0] if not shelves.is_empty() else _bookshelf_demo(library[0]["center"] + Vector3(5, 0, 0))
		# schräg von vorn auf das linke Ende – an einer Innenecke die Gehrung; nah: dicht vor die Bücher in der Mitte
		var end := shelf.global_transform * Vector3(-shelf.length / 2.0, 1.1, 0)
		var at := shelf.global_transform * Vector3(-shelf.length / 2.0 + 3.2, 0, 4.2)
		if _arg_parts(arg, "--regale").has("nah"):
			end = shelf.global_transform * Vector3(0.3, 0.9, 0)
			at = shelf.global_transform * Vector3(-0.2, 0, 1.1)
		TeleportUI.place_player(at, end - at)
		Game.player.head.rotation.x = deg_to_rad(-6.0)
		var books := 0
		var calls := 0
		for mmi: MultiMeshInstance3D in get_tree().get_nodes_in_group("books"):
			books += mmi.multimesh.instance_count
			calls += 1
		print("[Bücher] %d Bücher in %d MultiMeshes, %d Regale" % [books, calls, get_tree().get_nodes_in_group("bookshelves").size()])
	elif _is_arg(arg, "--stuhl"):
		var builder := Game.social.builder
		if not builder._named.has("speisesaal"):
			return false
		var hall: Rect2 = builder._named["speisesaal"]
		var chair: Chair = null
		for node in get_tree().get_nodes_in_group("chairs"):
			var ch := node as Chair
			if hall.has_point(Vector2(ch.global_position.x, ch.global_position.z)):
				chair = ch
				break
		if chair == null:
			chair = _chair_demo(hall)
		var opts := _arg_parts(arg, "--stuhl")
		# von der Gangseite (die Sitzseite zeigt zur Tafel): schräg von hinten; hinten: gerade von hinten auf die
		# Wölbung der Lehne; seite: im Profil (Schräge der Pfosten); nah: über die Lehne aufs Kissen
		var local := Vector3(0.9, 0, -1.0)
		if opts.has("hinten"):
			local = Vector3(0.15, 0, -1.3)
		elif opts.has("seite"):
			local = Vector3(1.4, 0, 0.1)
		elif opts.has("nah"):
			local = Vector3(0.35, 0, -0.75)
		var aim := chair.global_transform * Vector3(0, 0.55, 0)
		var at := chair.global_transform * local
		TeleportUI.place_player(at, aim - at)
		Game.player.head.rotation.x = deg_to_rad(-40.0 if opts.has("nah") else -28.0)
	elif _is_arg(arg, "--tafel"):
		var builder := Game.social.builder
		if not builder._named.has("speisesaal"):
			return false
		var hall: Rect2 = builder._named["speisesaal"]
		var table: DiningTable = null
		for node in get_tree().get_nodes_in_group("dining_tables"):
			var t := node as DiningTable
			if hall.has_point(Vector2(t.global_position.x, t.global_position.z)):
				table = t
				break
		if table == null:   # zum Ansehen in die Mitte des Saals
			table = DiningTable.make(Vector2(3.0, 1.1))
			table.position = Vector3(hall.get_center().x, 0, hall.get_center().y)
			add_child(table)
		var opts := _arg_parts(arg, "--tafel")
		# schräg auf eine Ecke; nah: vor das Eckbein (Furchen, Mulden der Zarge); ende: auf das herabhängende Ende des Läufers
		var ex := table.size.x / 2.0
		var ez := table.size.y / 2.0
		var local := Vector3(ex + 1.1, 0, ez + 1.5)
		var aim := Vector3(ex - 0.3, 0.55, ez - 0.2)
		var pitch := -22.0
		if opts.has("nah"):
			local = Vector3(ex + 0.45, 0, ez + 0.75)
			aim = Vector3(ex - 0.1, 0.55, ez - 0.1)
			pitch = -30.0
		elif opts.has("ende"):
			local = Vector3(ex + 1.2, 0, 0.5)
			aim = Vector3(ex, 0.7, 0)
			pitch = -18.0
		var at := table.global_transform * local
		var look := table.global_transform * aim
		TeleportUI.place_player(at, look - at)
		Game.player.head.rotation.x = deg_to_rad(pitch)
	elif _is_arg(arg, "--wandleuchte"):
		# die Wandleuchte, die dem Startpunkt am nächsten ist; schräg davor, Blick auf die Leuchte
		var opts := _arg_parts(arg, "--wandleuchte")
		var lamp: Lamp = null
		var best := INF
		for node in get_tree().get_nodes_in_group("lamp_fixtures"):
			var l := node as Lamp
			var d := l.global_position.distance_to(Game.player.global_position)
			var across := absf(l.global_basis.z.x) > 0.7   # quer: Wand nach Osten oder Westen
			if l.style == Lamp.Style.WALL and d < best and across == opts.has("quer"):
				best = d
				lamp = l
		if lamp == null:
			return false
		var dist := 1.5 if opts.has("nah") else 2.6
		var at := lamp.global_transform * Vector3(dist * 0.15, 0, dist)
		at.y = Game.player.global_position.y   # die nächste Leuchte hängt auf dem Stockwerk des Startpunkts
		TeleportUI.place_player(at, lamp.global_position - at)
		var target := lamp.global_position - (at + Vector3(0, Game.player.eye_height, 0))
		Game.player.head.rotation.x = atan2(target.y, Vector2(target.x, target.z).length())
	elif _is_arg(arg, "--dachboden"):
		var builder := Game.social.builder
		var where := _arg_value(arg, "--dachboden")
		match where:
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
				if where == "urteil":
					_debug_judgment_on_13()
					Game.director.debug_reach = 5.0
				if where == "raubzug":   # Raubzug (nicht harmlos), Notausgang nach 5 s offen auf dem Dachboden (4.33, 3.)
					Game.ghost.debug_rest(600.0)
					Game.director.debug_reach = 5.0
					get_tree().create_timer(1.0).timeout.connect(func() -> void:
						Game.director.debug_start(MonsterDirector.Mode.RAID, 2.0))
				if where == "blitz" and builder.attic_spook:
					builder.attic_spook.forced = true
					if Game.weather.kind != Weather.Kind.STORM:
						Game.weather.set_weather(Weather.Kind.STORM, true)
					get_tree().create_timer(3.0).timeout.connect(Game.weather.lightning)
	elif arg.begins_with("--time="):
		# Spieltage vor- oder zurückspulen (+1, -2 …)
		Game.director.elapsed = maxf(0.0, Game.director.elapsed + _arg_value(arg, "--time").to_float() * Calendar.DAY_SECONDS)
		Game.say(Calendar.date_text(Game.director.elapsed), 2.0)
	elif _is_arg(arg, "--console"):
		# Konsole nach 1 s öffnen, optional Befehle (mit ; getrennt) eintippen
		var console := get_node_or_null("DebugConsole") as DebugConsole
		if console == null:
			return false
		get_tree().create_timer(1.0).timeout.connect(func() -> void:
			console.open()
			for line in _arg_value(arg, "--console").split(";", false):
				console.submit(line))
	elif arg.begins_with("--load-slot="):
		SaveManager.load_slot(_arg_value(arg, "--load-slot").to_int())
	elif arg.begins_with("--pos="):
		var v := _arg_parts(arg, "--pos")
		Game.player.global_position = Vector3(v[0].to_float(), v[1].to_float(), v[2].to_float())
		if v.size() > 3:
			Game.player.rotation.y = deg_to_rad(v[3].to_float())
		if v.size() > 4:
			Game.player.head.rotation.x = deg_to_rad(v[4].to_float())
	elif arg.begins_with("--monster="):
		var m := _arg_parts(arg, "--monster")
		var pos := Vector3(m[0].to_float(), m[1].to_float(), m[2].to_float())
		Game.monster.spawn_at(pos)
		Game.director.phase = MonsterDirector.Phase.ACTIVE
	elif arg.begins_with("--splash="):
		var at := _arg_parts(arg, "--splash")
		get_tree().create_timer(1.0, false).timeout.connect(func() -> void:
			var water := get_tree().get_first_node_in_group("pool_water") as PoolWater
			if water:
				water.splash(Vector2(at[0].to_float(), at[1].to_float()), 1.0))
	elif arg == "--lure":
		get_tree().create_timer(1.0, false).timeout.connect(Game.director.debug_lure)
	elif _is_arg(arg, "--despawn"):
		_debug_despawn(_arg_value(arg, "--despawn"))
	elif arg == "--zugleich":
		get_tree().create_timer(1.0, false).timeout.connect(_debug_together)
	elif arg.begins_with("--pool="):
		var water := get_tree().get_first_node_in_group("pool_water") as PoolWater
		var stage := _arg_value(arg, "--pool")
		if water:
			water.debug_stage = "" if stage == "off" else stage
	elif arg == "--pocket":
		Game.player.give_compass()
		for page in HotelMap.PAGES:
			Game.player.add_map_page(page["id"])
		Game.player.add_key("zimmer_18")
	elif _is_arg(arg, "--bag-menu"):
		# erst nach den übrigen Parametern (--bag, --flashlight) öffnen
		Game.player.debug_open_bag.call_deferred(_arg_value(arg, "--bag-menu", "0").to_int() - 1)
	elif _is_arg(arg, "--bag"):
		var kinds := {"süßes": Item.Kind.SWEETS, "suesses": Item.Kind.SWEETS, "cola": Item.Kind.SODA_CAN, "limo": Item.Kind.SODA_CAN,
			"zierkürbis": Item.Kind.MINI_PUMPKIN, "zierkuerbis": Item.Kind.MINI_PUMPKIN, "kerze": Item.Kind.CANDLE,
			"messer": Item.Kind.KNIFE, "batterie": Item.Kind.BATTERY, "birne": Item.Kind.BULB, "uv": Item.Kind.UV_FILTER,
			"würfel": Item.Kind.LOADED_DICE, "wuerfel": Item.Kind.LOADED_DICE, "becher": Item.Kind.DICE_CUP,
			"streichhölzer": Item.Kind.MATCHBOX, "streichhoelzer": Item.Kind.MATCHBOX, "dartpfeile": Item.Kind.DARTS, "salz": Item.Kind.SALT,
			"kerne": Item.Kind.PUMPKIN_SEEDS, "brot": Item.Kind.PUMPKIN_SEEDS, "ei": Item.Kind.EGG,
			"karten": Item.Kind.BAR_GAME, "deckel": Item.Kind.BAR_GAME, "quiz": Item.Kind.BAR_GAME}
		var names := _arg_value(arg, "--bag", "süßes,cola,zierkürbis,batterie").split(",", false)
		for what in names:
			if not kinds.has(what):
				Game.say("Tasche: " + ", ".join(kinds.keys()), 3.0)
				return true
			var item := Item.create(kinds[what], what if what in ["cola", "limo", "brot", "karten", "deckel", "quiz"] else "")
			if Game.player.bag.size() < Player.BAG_SLOTS:
				Game.player.bag_add(item)
			else:
				item.free()
	elif _is_arg(arg, "--flashlight"):
		var uv := _arg_value(arg, "--flashlight") == "uv"
		var lamp := Item.create(Item.Kind.FLASHLIGHT, "c=1;on" + (";uv;m=uv" if uv else ""))
		Game.player.drop_held()
		Game.player.receive_item(lamp)
	elif arg.begins_with("--deco="):
		var kinds := {"gespenst": Item.Kind.SHEET_GHOST, "lichter": Item.Kind.LIGHT_STRING, "netz": Item.Kind.COBWEB,
			"laub": Item.Kind.LEAVES, "zierkürbis": Item.Kind.MINI_PUMPKIN, "zierkuerbis": Item.Kind.MINI_PUMPKIN,
			"fledermaus": Item.Kind.BAT_GARLAND, "spinne": Item.Kind.SPIDER, "totenkopf": Item.Kind.SKULL, "besen": Item.Kind.BROOM,
			"kerze": Item.Kind.CANDLE}
		var what := _arg_value(arg, "--deco").trim_suffix(",g")
		if not kinds.has(what):
			Game.say("Deko: gespenst, lichter, netz, laub, zierkürbis, fledermaus, spinne, totenkopf, besen oder kerze", 3.0)
			return true
		Game.player.drop_held()
		Game.player.receive_item(Item.create(kinds[what], "lit" if what == "kerze" else ""))
		if arg.ends_with(",g"):
			get_tree().create_timer(1.0).timeout.connect(func() -> void: Game.player.drop_held())
	elif _is_arg(arg, "--fall"):
		# Kürbis fällt 1,5 m vor dir aus h m Höhe (Standard 4) – ab 3 m zerplatzt er (5.8); dahinter Sorte oder „mini“,
		# „kerze“ (zerbricht ab 2 m) oder „birne“ (platzt ab 1,5 m)
		var parts := _arg_parts(arg, "--fall")
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
	elif _is_arg(arg, "--wurf"):
		# Werfen (3.13): nach 1 s einen Gegenstand in die Hand und mit Kraft k (0 … 1, Standard 1) in Blickrichtung werfen –
		# Standard ein Kürbis; Sorte aus PumpkinKinds, mini, kerze (brennend), birne, kaffee, tee, dose, messer, taschenlampe,
		# glas (Rotwein, ZIM-35)
		var parts := _arg_parts(arg, "--wurf")
		var power := clampf(parts[0].to_float(), 0.0, 1.0) if parts.size() > 0 and parts[0] != "" else 1.0
		var what := parts[1] if parts.size() > 1 else ""
		get_tree().create_timer(1.0).timeout.connect(func() -> void:   # nach --pos/--tp
			var kinds := {"mini": Item.Kind.MINI_PUMPKIN, "zierkuerbis": Item.Kind.MINI_PUMPKIN, "kerze": Item.Kind.CANDLE,
				"birne": Item.Kind.BULB, "kaffee": Item.Kind.COFFEE, "tee": Item.Kind.TEA, "dose": Item.Kind.SODA_CAN,
				"messer": Item.Kind.KNIFE, "taschenlampe": Item.Kind.FLASHLIGHT, "glas": Item.Kind.GLASS}
			var item := Item.create(kinds[what], {"kerze": "lit", "glas": "wein"}.get(what, "")) if kinds.has(what) \
				else Item.create(Item.Kind.PUMPKIN, "" if what in ["", "kuerbis", "kürbis"] else what)
			Game.player.drop_held()
			Game.player.receive_item(item)
			get_tree().create_timer(0.3).timeout.connect(func() -> void: Game.player.throw_held(power)))
	elif _is_arg(arg, "--kuerbis"):
		# Kürbismodelle (PumpkinModel, 5.8): glatt und alle Fratzen mit Kerze in einer Reihe vor dir – bzw. nur Fratze n
		var face := _arg_value(arg, "--kuerbis")
		var only := clampi(face.to_int(), 1, PumpkinModel.FACES) if face != "" else 0
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
	elif arg == "--kerzen" or arg == "--kerzen=nah" or arg == "--kerzen=wind":
		# Kerzenmodelle (CandleModel): Gegenstand brennend und aus, rot und weiß auf dem Teller (brennend) in einer Reihe –
		# nah: weiß auf dem Teller 30 cm vor dem Auge, die Flamme auf Augenhöhe, daneben rot ohne Teller · wind (7.8): sechs
		# brennende Kerzen und ein geschnitzter Kürbis 1,5 m vor dir (draußen bläst eine Böe sie aus, der Kürbis bleibt an)
		get_tree().create_timer(1.0).timeout.connect(func() -> void:   # nach --pos/--tp
			var front := -Game.player.global_basis.z
			front = Vector3(front.x, 0, front.z).normalized()
			var side := front.cross(Vector3.UP)
			if arg == "--kerzen=wind":
				for i in 7:
					var thing := Item.create(Item.Kind.CANDLE, "lit") if i < 6 else Item.create(Item.Kind.CARVED_PUMPKIN, "lit")
					Game.player.get_parent().add_child(thing)
					thing.global_position = Game.player.global_position + front * 1.5 + side * (i - 3) * 0.3 + Vector3.UP * 0.02
					if not thing.lit:
						thing.light_up(false)
				Game.player.head.rotation.x = -0.5
				get_tree().create_timer(40.0).timeout.connect(func() -> void:
					var burning := get_tree().get_nodes_in_group("items").filter(func(it: Item) -> bool:
						return it.lit and it.global_position.distance_to(Game.player.global_position) < 4.0)
					print("[Kerze] nach 40 s brennen noch %d von 7 (Wind %.2f)" % [burning.size(), Game.weather.wind]))
				return
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
		Game.player.debug_show = _arg_value(arg, "--show")
	elif arg == "--winded":
		Game.player.stamina = 0.0
		Game.player.winded = true
	elif arg == "--sprint":
		Game.player.debug_sprint = true
	elif arg.begins_with("--bold="):
		Game.director.boldness = _arg_value(arg, "--bold").to_float()
	elif arg.begins_with("--friend="):
		var friend := _guest(_arg_value(arg, "--friend"))
		if friend:
			friend.relation = 65.0   # befreundet (6.3)
	elif arg.begins_with("--relation="):
		# Beziehung setzen; für die Extreme werden die nötigen Taten gleich mit eingetragen (6.3)
		var rel := _arg_parts(arg, "--relation")
		var g := _guest(rel[0])
		if g and rel.size() > 1:
			g.relation = clampf(rel[1].to_float(), -100.0, 100.0)
			if g.relation >= 80.0:
				g.deeds.merge({"games": Social.BOND_GAMES, "gifts_to": Social.BOND_GIFTS_TO, "gifts_from": Social.BOND_GIFTS_FROM}, true)
			elif g.relation <= -80.0:
				g.deeds.merge({"hostile": Social.FEUD_HOSTILE, "revenge": Social.FEUD_REVENGE}, true)
	elif arg.begins_with("--einbruch="):
		var parts := _arg_parts(arg, "--einbruch")
		var foe := _guest(parts[0])
		if foe:
			foe.relation = -90.0   # stark verfeindet (6.3), mit den nötigen Taten
			foe.deeds.merge({"hostile": Social.FEUD_HOSTILE, "revenge": Social.FEUD_REVENGE}, true)
			get_tree().create_timer(1.0, false).timeout.connect(func() -> void:
				Game.social.break_in.debug(foe, parts[1] if parts.size() > 1 else ""))
	elif arg.begins_with("--feind="):
		var parts := _arg_parts(arg, "--feind")
		var foe := _guest(parts[0])
		if foe:
			var what := parts[1] if parts.size() > 1 else "tuer"
			get_tree().create_timer(1.0, false).timeout.connect(func() -> void: Game.social.access.debug_enemy(foe, what))
	elif arg.begins_with("--zweitschluessel="):
		var parts := _arg_parts(arg, "--zweitschluessel")
		var friend := _guest(parts[0])
		if friend:
			friend.relation = 90.0   # guter Freund (6.3), mit den nötigen Taten
			friend.deeds.merge({"games": Social.BOND_GAMES, "gifts_to": Social.BOND_GIFTS_TO, "gifts_from": Social.BOND_GIFTS_FROM}, true)
			_put_in_front(friend, 1.5)
			friend._set_idle(10.0)
			if parts.size() > 1 and parts[1] == "zurueck":
				get_tree().create_timer(4.0, false).timeout.connect(func() -> void: Game.social.access.debug_revoke(friend))
	elif arg.begins_with("--follow="):
		var follower := _guest(_arg_value(arg, "--follow"))
		if follower:
			_put_in_front(follower, -2.0, false)   # hinter dir
			follower.start_follow()
	elif arg.begins_with("--visit="):
		var visitor := _guest(_arg_value(arg, "--visit"))
		if visitor:
			Game.social.start_visit(visitor)
	elif arg.begins_with("--punch="):
		# Gast vor den Spieler stellen und zweimal zuschlagen (Nachfrage + Schlag)
		var target := _guest(_arg_value(arg, "--punch"))
		if target:
			_put_in_front(target, 1.0)
			target._set_idle(5.0)
			get_tree().create_timer(1.0).timeout.connect(func() -> void:
				Game.player.debug_punch(target)
				Game.player.debug_punch(target))
	elif arg.begins_with("--attack="):
		var attacker := _guest(_arg_value(arg, "--attack"))
		if attacker:
			_put_in_front(attacker, 4.0, false)
			get_tree().create_timer(1.0).timeout.connect(attacker.start_attack)
	elif arg.begins_with("--kill="):
		var kill_parts := _arg_parts(arg, "--kill")
		var victim := _guest(kill_parts[0])
		if victim == null:
			return true
		var opt := _kill_options(kill_parts)
		if opt["instant"]:
			# Sofort tot – geist/kuerbis: vor dir erwürgt bzw. erschlagen, die Leiche bleibt liegen (Todesmeldung, „… – tot“) ·
			# leiche/weg: wo er gerade ist (hin: vor dir), liegt da bzw. ist verschwunden · blut/ohneblut: Lache und Spritzer
			get_tree().create_timer(1.5 if opt["here"] else 0.1).timeout.connect(func() -> void:
				if victim.dead:
					return
				if opt["here"]:
					_put_in_front(victim, 1.3)
					Game.player.head.rotation.x = deg_to_rad(-45.0)
				_debug_kill(victim, opt["cause"], opt["corpse"], opt["blood"]))
			return true
		get_tree().create_timer(3.0).timeout.connect(func() -> void:
			if victim.dead:
				return
			Game.monster.spawn_at(victim.global_position + Vector3(1, 0, 0))
			Game.director.phase = MonsterDirector.Phase.ACTIVE
			Game.director.kill_guest(victim, null))
	elif arg.begins_with("--wound="):
		# Überlebender (Spielkonzept 6.17): gast,scratch|axe|choke[,hin] – verletzt wie nach dem Angriff; hin: er liegt
		# bzw. steht vor dir (mit --talk=gast erzählt er als Zeuge)
		var parts := _arg_parts(arg, "--wound")
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
		var enemy := _guest(_arg_value(arg, "--enemy"))
		if enemy:
			enemy.relation = -65.0   # verfeindet (6.3)
	elif arg.begins_with("--player-deco="):
		var xz := _arg_parts(arg, "--player-deco")
		var deco := Item.create(Item.Kind.CARVED_PUMPKIN)
		deco.owner_id = "player"
		deco.position = Vector3(xz[0].to_float(), 0.02, xz[1].to_float())
		add_child(deco)
	elif arg.begins_with("--dice="):
		var opponent := _guest(_arg_value(arg, "--dice"))
		if opponent == null:
			return true
		get_tree().create_timer(0.5).timeout.connect(func() -> void:
			Game.dice.start(opponent, {"money": 3, "item": false}))
	elif arg.begins_with("--chess="):
		var chess_opponent := _guest(_arg_value(arg, "--chess"))
		if chess_opponent == null:
			return true
		get_tree().create_timer(0.5).timeout.connect(func() -> void:
			Game.chess.start(chess_opponent, {"money": 3, "item": false}))
	elif _is_arg(arg, "--darts"):
		var dart_id := _arg_value(arg, "--darts")
		var dart_opponent := _guest(dart_id) if dart_id != "" else null
		if dart_id != "" and dart_opponent == null:
			return true
		get_tree().create_timer(0.5).timeout.connect(func() -> void:
			Game.player.global_position = Game.darts.board.throw_spot(false)
			if dart_opponent:
				dart_opponent.global_position = Game.darts.board.guest_seat.global_position + Vector3(0.5, 0.05, 0.8)
				Game.darts.start(dart_opponent, {"money": 3, "item": false})
			else:
				Game.darts.practice())
	elif arg == "--bowling":
		get_tree().create_timer(0.5).timeout.connect(func() -> void:
			var lane := Game.social.builder.bowling
			if lane == null:
				push_warning("--bowling: keine Bowlingbahn im Plan")
				return
			Game.player.global_position = lane.stand_spot() + Vector3(0, 0.05, 0)
			lane.interact(Game.player))
	elif arg == "--spieleschrank":
		# vor den Spieleschrank stellen und ihn öffnen (Spielkonzept 6.10)
		get_tree().create_timer(0.5).timeout.connect(func() -> void:
			var cabinet := Game.social.builder.game_cabinet
			if cabinet == null:
				push_warning("--spieleschrank: kein Spieleschrank")
				return
			var front := cabinet.global_basis.z.normalized()
			TeleportUI.place_player(cabinet.global_position + front * 1.3, -front)
			cabinet.set_open(true))
	elif _is_arg(arg, "--zinken"):
		# gezinkte Würfel in die Hand und wie der Spieler in den Becher am Tisch tauschen (Mäxchen bzw. Barspiele)
		var bar := _arg_value(arg, "--zinken") == "bar"
		get_tree().create_timer(0.3).timeout.connect(func() -> void:
			var table: GameTable = (Game.bar_games["schocken"] as BarMatch).table if bar else Game.dice.table
			var cup := table.cup_here()
			if cup == null:
				cup = Item.create(Item.Kind.DICE_CUP)
				add_child(cup)
				cup.global_position = table.top_center() + Vector3(-0.15, 0.02, 0.0)
			Game.player.drop_held()
			Game.player.receive_item(Item.create(Item.Kind.LOADED_DICE))
			cup.interact(Game.player)
			print("[Zinken] Becher %s gezinkt, Hand: %s" % ["ist" if table.loaded else "ist NICHT",
				Game.player.held.display_name if Game.player.held else "-"]))

		var cabinet := get_tree().get_first_node_in_group("chests")
		for node in get_tree().get_nodes_in_group("chests"):
			if node is GameCabinet:
				cabinet = node
		if cabinet is GameCabinet:
			cabinet.set_open(true, true)
	elif arg.begins_with("--bargame="):
		var bar_parts := _arg_parts(arg, "--bargame")
		var bar_game: BarMatch = Game.bar_games.get(bar_parts[0])
		if bar_game == null:
			Game.say("Barspiele: " + ", ".join(Game.bar_games.keys()), 3.0)
			return true
		var bar_opponent := _guest(bar_parts[1] if bar_parts.size() > 1 else "bruno")
		if bar_opponent == null:
			return true
		get_tree().create_timer(0.5).timeout.connect(func() -> void:
			var table := bar_game.table
			bar_opponent.global_position = table.guest_seat.global_position + Vector3(0.5, 0.05, 0.8)
			if not bar_game.has_gear(null):   # Spiel bzw. Becher aus dem Schrank gleich auf den Tisch
				var gear := Item.create(Item.Kind.DICE_CUP) if bar_game.gear_flavor == "wuerfel" 					else Item.create(Item.Kind.BAR_GAME, bar_game.gear_flavor)
				add_child(gear)
				gear.global_position = table.top_center() + Vector3(-0.15, 0.02, 0.0)
			var reason := bar_game.why_not(bar_opponent)
			if reason != "":
				print("[Barspiel] %s geht nicht: %s" % [bar_game.title, reason])
				return
			bar_game.start(bar_opponent, {"money": 0 if bar_game.id == "wahrheit" else 3, "item": false}))
	elif arg.begins_with("--challenge="):
		var parts := _arg_parts(arg, "--challenge")
		var challenger := _guest(parts[0])
		if challenger:
			var game := parts[1] if parts.size() > 1 else "dice"
			Game.social.challenge(challenger, game if game in ["chess", "darts"] or Game.bar_games.has(game) else "dice")
	elif arg == "--autoplay":
		_autoplay = true
	elif arg.begins_with("--cat="):
		# Katze vor den Spieler setzen (sitzt, zum Streicheln) – mit ",tragen" gleich auf den Arm
		var parts := _arg_parts(arg, "--cat")
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
		_debug_pumpkin_hunt(_arg_value(arg, "--pumpkin").trim_prefix("jagd").trim_prefix(","))
	elif arg.begins_with("--pumpkin=zeigen"):
		_debug_pumpkin_show(_arg_value(arg, "--pumpkin").trim_prefix("zeigen").trim_prefix(","))
	elif _is_arg(arg, "--pumpkin"):
		PumpkinMan.spawn_in_front_of(Game.player, _arg_value(arg, "--pumpkin", "walk"))
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
	elif _is_arg(arg, "--costumes"):
		Costume.force = _arg_value(arg, "--costumes", "all")
	elif arg == "--disguise":
		Game.player.set_disguised(true)
	elif _is_arg(arg, "--maske"):
		_debug_masks(_arg_value(arg, "--maske"))
	elif arg.begins_with("--drunk="):
		var parts := _arg_parts(arg, "--drunk")
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
		var what := _arg_value(arg, "--weather")
		match what:
			"klar":
				Game.weather.set_weather(Weather.Kind.CLEAR, true)
			"regen":
				Game.weather.set_weather(Weather.Kind.RAIN, true)
			"gewitter":
				Game.weather.set_weather(Weather.Kind.STORM, true)
			"boe":   # Gewitter und gleich eine heftige Böe (Kerzen draußen, 7.8)
				Game.weather.set_weather(Weather.Kind.STORM, true)
				Game.weather.force_gust()
			"blut":
				Game.weather.set_weather(Weather.Kind.RAIN, true, true)
			"blitz", "gestalt":
				if Game.weather.kind != Weather.Kind.STORM:
					Game.weather.set_weather(Weather.Kind.STORM, true)
				var figure := what == "gestalt"   # Gestalt im Blitz neben dem Baum, der am ehesten im Blick liegt
				get_tree().create_timer(3.0).timeout.connect(Game.weather.lightning.bind(figure))   # erst, wenn es regnet
			_:
				Game.say("Wetter: klar, regen, gewitter, boe, blitz, gestalt oder blut", 3.0)
	elif _is_arg(arg, "--party"):
		var host := _arg_value(arg, "--party", "player")
		if host == "player" or _guest(host):
			Game.social.start_party(host)
	elif arg.begins_with("--look="):
		var parts := _arg_parts(arg, "--look")
		var guest := _guest(parts[0])
		if guest:
			_debug_look(guest, parts[1] if parts.size() > 1 else "")
	elif arg.begins_with("--shock="):
		var parts := _arg_parts(arg, "--shock")
		var shocked := _guest(parts[0])
		if shocked:
			_debug_shock(shocked, parts[1] if parts.size() > 1 else "blood")
	elif arg.begins_with("--talk="):
		var partner := _guest(_arg_value(arg, "--talk"))
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
		var parts := _arg_parts(arg, "--bitte")
		get_tree().create_timer(0.5).timeout.connect(Game.social.requests.debug.bind(parts))
	elif arg.begins_with("--gespraech="):
		var parts := _arg_parts(arg, "--gespraech")
		get_tree().create_timer(0.5).timeout.connect(Game.social.talk.debug.bind(parts))
	elif arg == "--ghost=flur":
		Game.ghost.debug_summon_hall()
	elif _is_arg(arg, "--spinne"):
		Game.spiders.debug(_arg_value(arg, "--spinne"))
	elif _is_arg(arg, "--fledermaus"):
		Game.bats.debug_show(_arg_value(arg, "--fledermaus"))
	elif _is_arg(arg, "--balkon"):
		var mode := _arg_value(arg, "--balkon")
		get_tree().create_timer(0.5).timeout.connect(func() -> void: BalconyRailing.debug(mode))
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
	elif _is_arg(arg, "--dusche"):
		Game.shower_scare.debug(_arg_value(arg, "--dusche"))
	elif _is_arg(arg, "--salz"):
		_debug_salt(_arg_parts(arg, "--salz"))
	elif _is_arg(arg, "--kreisen"):
		var haunt_parts := _arg_parts(arg, "--kreisen")
		get_tree().create_timer(1.0, false).timeout.connect(func() -> void: Game.social.hauntings.debug(haunt_parts))
	elif arg.begins_with("--awake="):
		# so viele Stunden wach (Spielkonzept 3.6), mit ",sicher": ab dann sicher im Flur; der erste Angriff gilt als
		# geschehen, sonst spukt der Lakengeist noch nicht
		Game.director.first_attack_done = true
		Game.player.awake_time = _arg_value(arg, "--awake").get_slice(",", 0).to_float() * Calendar.HOUR
		if arg.ends_with(",sicher"):
			Game.player.sure_awake = maxf(Game.player.awake_time, Player.TIRED_FROM + Calendar.HOUR)
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
	elif arg.begins_with("--sleep=tag"):
		# am Tag h Stunden im Bett von Zimmer 13 – die Zeit springt auch am Tag (3.6)
		if arg.contains(","):
			Game.player.sleep_hours = clampi(arg.get_slice(",", 1).to_int(), Player.SLEEP_HOURS.x, Player.SLEEP_HOURS.y)
		get_tree().create_timer(1.5).timeout.connect(func() -> void:
			for spot in Game.director.rooms[LevelBuilder.PLAYER_ROOM]["spots"]:
				if (spot as HideSpot).own_bed:
					Game.player.start_sleep(spot))
	elif arg.begins_with("--fremdbett="):
		_debug_foreign_bed(_arg_parts(arg, "--fremdbett"))
	elif arg == "--wache" or arg.begins_with("--wache="):
		_debug_guard(arg.get_slice("=", 1) if arg.contains("=") else "edna")
	elif arg.begins_with("--wecken="):
		_debug_wake(_arg_parts(arg, "--wecken"))
	elif arg.begins_with("--birnenersatz="):
		_debug_bulb_refill(_arg_parts(arg, "--birnenersatz"))
	elif arg.begins_with("--ghost="):
		Game.ghost.debug_summon(_arg_value(arg, "--ghost").to_int())
	elif arg == "--warn":
		get_tree().create_timer(1.0).timeout.connect(func() -> void: Game.director.start_warning())
	elif arg.begins_with("--eier="):
		_debug_eggs(_arg_parts(arg, "--eier"))
	elif arg.begins_with("--prank="):
		var prank := _arg_parts(arg, "--prank")
		var prank_room := Game.director.room_by_label(prank[1]) if prank.size() > 1 else LevelBuilder.PLAYER_ROOM
		get_tree().create_timer(1.5).timeout.connect(func() -> void: Game.social.pranks.debug(prank[0], prank_room))
	elif arg == "--doll=kind":
		get_tree().create_timer(1.0).timeout.connect(func() -> void: Game.doll.debug_fetch())
	elif _is_arg(arg, "--doll"):
		# Angriff mit Puppe in s Sekunden – nach 1 s, damit Gäste und NavMesh stehen
		var parts := _arg_parts(arg, "--doll")
		var seconds := parts[0].to_float() if parts.size() > 0 and parts[0] != "" else 20.0
		Game.director.debug_doom = Game.director.room_by_label(parts[1]) if parts.size() > 1 else ""
		get_tree().create_timer(1.0).timeout.connect(func() -> void:
			Game.director.debug_start(MonsterDirector.Mode.JUDGMENT, seconds))
	elif arg.begins_with("--attacks="):
		# so viele Raubzüge gab es schon (ab HARMLESS_RAIDS ist der nächste nicht mehr harmlos, 4.33)
		Game.director.first_attack_done = true
		Game.director.raids = _arg_value(arg, "--attacks").to_int()
	elif arg == "--siegerehrung" or arg == "--siegerehrung=ohne":
		# Siegerehrung (2.5) – nach 1 s, damit NavMesh und Gäste stehen
		get_tree().create_timer(1.0).timeout.connect(func() -> void: Game.contest.debug_ceremony(arg.ends_with("ohne")))
	elif arg == "--grinch" or arg == "--grinch=tot":
		# nach 1 s, damit NavMesh und Gäste stehen
		get_tree().create_timer(1.0).timeout.connect(func() -> void: Game.social.grinch.debug(arg.ends_with("tot")))
	elif arg == "--brett" or arg == "--brett=nachher":
		Game.contest.debug_board(_arg_value(arg, "--brett"))
	elif arg == "--brett=abgereist":
		# nach 1 s, damit die Gäste stehen (Gustav wird geholt)
		get_tree().create_timer(1.0).timeout.connect(func() -> void: Game.contest.debug_board("abgereist"))
	elif _is_arg(arg, "--register"):
		# nach 1 s, damit die Gäste stehen (tot: Gustav wird geholt)
		var opts := _arg_parts(arg, "--register")
		get_tree().create_timer(1.0).timeout.connect(func() -> void: Game.register.debug("tot" in opts, "offen" in opts, "anfang" in opts))
	elif _is_arg(arg, "--klingel"):
		var opts := _arg_parts(arg, "--klingel")
		var bell: DeskBell = Game.social.builder.desk_bell
		if bell == null:
			return false
		bell.debug("nah" in opts, "an" in opts)
	elif _is_arg(arg, "--zimmer18"):
		var page := _arg_value(arg, "--zimmer18")
		get_tree().create_timer(0.5).timeout.connect(func() -> void:   # nach dem Aufbau des Spielers
			for book in get_tree().get_nodes_in_group("caretaker_books"):
				(book as CaretakerBook).debug(page))
	elif _is_arg(arg, "--spinde"):
		var open := _arg_value(arg, "--spinde") == "offen"
		get_tree().create_timer(0.5).timeout.connect(func() -> void: LockerBank.debug_show(get_tree(), open))
	elif _is_arg(arg, "--stahlspinde"):
		var mode := _arg_value(arg, "--stahlspinde")
		get_tree().create_timer(0.5).timeout.connect(func() -> void: SteelLocker.debug_show(get_tree(), mode))
	elif _is_arg(arg, "--duschen"):
		var water := _arg_value(arg, "--duschen") == "an"
		get_tree().create_timer(0.5).timeout.connect(PoolShower.debug_show.bind(get_tree(), water))
	elif _is_arg(arg, "--automaten"):
		var which := _arg_value(arg, "--automaten").split(",")
		if which[0] in ["deadra", "hotel", "gast"]:
			get_tree().create_timer(1.0).timeout.connect(func() -> void:
				ArcadeMachine.autoplay = _autoplay
				ArcadeMachine.debug_play(get_tree(), which[0], which[1] if which.size() > 1 else ""))
		else:
			get_tree().create_timer(0.5).timeout.connect(ArcadeMachine.debug_show.bind(get_tree(), which[0] == "seite"))
	elif _is_arg(arg, "--bilder"):
		var group := _arg_value(arg, "--bilder")
		get_tree().create_timer(0.5).timeout.connect(Painting.debug_show.bind(get_tree(), group))
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
	elif _is_arg(arg, "--tot"):
		var by: String = {"geist": "ghost", "kuerbis": "pumpkin", "kürbis": "pumpkin"}.get(_arg_value(arg, "--tot"), "monster")
		get_tree().create_timer(1.0).timeout.connect(func() -> void:
			if Game.game_over:
				return
			Game.game_over = true
			Game.player.dead = true
			Game.player.killed_by = by
			SaveManager.on_death()
			if Game.hud:
				Game.hud.visible = false
			Game.player_died.emit())
	elif arg == "--trick=13" or arg.begins_with("--trick=13,"):
		# Ein Kind steht vor Zimmer 13 (Tür auf) – mit „,n“ gibst du ihm n Süßigkeiten, eine je 1,5 s
		var trick := _arg_parts(arg, "--trick")
		var give := trick[1].to_int() if trick.size() > 1 else 0
		get_tree().create_timer(1.0).timeout.connect(func() -> void: Game.social.debug_trick_at_13(give))
	elif _is_arg(arg, "--trick"):
		var kid_id := _arg_value(arg, "--trick")
		var kid: Guest = Game.social.find_guest(kid_id) if kid_id != "" else null
		if kid == null:
			var kids := Game.social.living_guests().filter(func(g: Guest) -> bool: return g.is_child())
			kid = kids.pick_random() if not kids.is_empty() else null
		if kid == null or not kid.is_child() or not Game.social.start_round(kid):
			Game.say("Süßes oder Saures: kein Kind oder keine Gästetür in der Nähe", 3.0)
	elif _is_arg(arg, "--decorate"):
		# Schmück-Aktion sofort (Spielkonzept 5.9); „lobby“: in der Lobby; „allein“: ein Gast trägt allein ein Stück
		# Deko in sein Zimmer (mit „lobby“ in die Lobby); „hin“: Spieler vor die Stelle, Blick zur Wand
		var parts := _arg_parts(arg, "--decorate")
		if "allein" in parts:   # der Weg zur Kiste braucht das fertige NavMesh
			get_tree().create_timer(1.5).timeout.connect(func() -> void: _debug_decorate(parts))
		else:
			_debug_decorate(parts)
	elif _is_arg(arg, "--search"):
		# Deko-Suche (Spielkonzept 5.9) – der Weg zum Fundort braucht das fertige NavMesh
		var parts := _arg_parts(arg, "--search")
		get_tree().create_timer(1.5).timeout.connect(func() -> void: _debug_search(parts))
	elif _is_arg(arg, "--kommode"):
		var parts := _arg_parts(arg, "--kommode", "suchen")
		get_tree().create_timer(1.5, false).timeout.connect(func() -> void: _debug_dresser(parts))
	elif arg.begins_with("--cook="):
		_debug_cook(_arg_parts(arg, "--cook"))
	elif arg.begins_with("--kaffee="):
		_debug_coffee(_arg_parts(arg, "--kaffee"))
	elif arg.begins_with("--tee="):
		_debug_coffee(_arg_parts(arg, "--tee"), true)
	elif arg == "--mess" or arg == "--mess=wachs":
		get_tree().create_timer(1.5, false).timeout.connect(func() -> void: Game.social.tidying.debug(arg.ends_with("wachs")))
	elif arg.begins_with("--rival="):
		# Freund meines Feindes (6.16): gast1 und gast2 sind verfeindet, du wirst gleich mit gast1 befreundet
		var ids := _arg_parts(arg, "--rival")
		var a := Game.social.find_guest(ids[0])
		var b := Game.social.find_guest(ids[1]) if ids.size() > 1 else null
		if a and b:
			Game.social.pals.add_feud(a, b)
			b.global_position = Game.player.global_position - Game.player.global_transform.basis.z * 2.5
			b._set_idle(90.0)
			Game.social.change_relation(a, 80.0)
	elif arg.begins_with("--pals="):
		_debug_pals(_arg_parts(arg, "--pals"))
	elif arg.begins_with("--netz="):
		_debug_net(_arg_parts(arg, "--netz"))
	elif arg.begins_with("--budget="):
		_debug_budget(_arg_parts(arg, "--budget"))
	elif arg.begins_with("--handel="):
		_debug_trade(_arg_parts(arg, "--handel"))
	elif _is_arg(arg, "--glas"):
		_debug_glass(_arg_value(arg, "--glas"))
	elif _is_arg(arg, "--gastspiel"):
		_debug_pub_game(_arg_value(arg, "--gastspiel", "schocken"))
	elif _is_arg(arg, "--gastsitzen"):
		_debug_guest_sit(_arg_parts(arg, "--gastsitzen", "sofa"))
	elif arg == "--kisten":
		get_tree().create_timer(1.0, false).timeout.connect(_debug_boxes)
	elif arg.begins_with("--streit="):
		Game.social.quarrels.debug(_arg_parts(arg, "--streit"))
	elif _is_arg(arg, "--trauer"):
		var grief_parts := _arg_parts(arg, "--trauer")
		get_tree().create_timer(1.0, false).timeout.connect(func() -> void: Game.social.mourning.debug(grief_parts))
	elif _is_arg(arg, "--zustand"):
		var tender_parts := _arg_parts(arg, "--zustand")
		get_tree().create_timer(1.0, false).timeout.connect(func() -> void: Game.social.requests.debug_tender(tender_parts))
	elif _is_arg(arg, "--schuld"):
		var guilt_parts := _arg_parts(arg, "--schuld")
		get_tree().create_timer(1.0, false).timeout.connect(func() -> void: Game.social.deaths.debug(guilt_parts))
	elif arg == "--neid" or arg.begins_with("--neid="):
		_debug_envy(_arg_parts(arg, "--neid"))
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
	elif _is_arg(arg, "--spion"):
		_debug_peephole(_arg_value(arg, "--spion", "leer"))
	elif _is_arg(arg, "--schwelle"):
		_debug_threshold(_arg_value(arg, "--schwelle", "flur"))
	elif _is_arg(arg, "--fenstertuer"):
		_debug_french_door(_arg_value(arg, "--fenstertuer", "innen"))
	elif _is_arg(arg, "--zierleiste"):
		_debug_cornice(_arg_value(arg, "--zierleiste", "flur"))
	elif arg.begins_with("--gastanruf="):
		get_tree().create_timer(1.0).timeout.connect(Game.phones.debug_guest_call.bind(_arg_parts(arg, "--gastanruf")))
	elif arg.begins_with("--call=") or arg.begins_with("--dial="):
		# Telefon: Spieler steht in Zimmer 13 vor dem Schreibtisch und sieht auf den Apparat
		var phone_pos := Game.phones.home_phone.global_position
		Game.player.global_position = Vector3(phone_pos.x, 0.05, phone_pos.z + 0.9)
		Game.player.rotation.y = 0.0
		Game.player.head.rotation.x = -0.75
		var is_call := arg.begins_with("--call=")
		var value := _arg_value(arg, "--call" if is_call else "--dial")
		get_tree().create_timer(1.0).timeout.connect(func() -> void:
			if is_call:
				Game.phones.debug_call(value)
				if "--answer" in OS.get_cmdline_user_args():
					get_tree().create_timer(4.0).timeout.connect(func() -> void:
						Game.phones.answer(Game.phones.home_phone))
			else:
				Game.phones.debug_dial(value))
	elif arg == "--gedraenge":
		var timer := Timer.new()
		timer.wait_time = 10.0
		timer.autostart = true
		add_child(timer)
		timer.timeout.connect(_report_crowding)
	elif arg == "--trace":
		_trace = true
		Game.tracing = true
		Game.message_posted.connect(func(text: String, _d: float, _icon: String) -> void: print("  » " + text.replace("
", " ")))
	elif arg.begins_with("--noise="):
		var kind := _arg_value(arg, "--noise")
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
		Game.director.elapsed = Calendar.at(clampi(_arg_value(arg, "--day").to_int(), 1, Calendar.HALLOWEEN), Calendar.START_HOUR)
	elif _is_arg(arg, "--rot"):
		# alle Kürbisse kurz vor welk bzw. gleich in dieser Stufe (Spielkonzept 5.10)
		var target: float = {"welk": Item.ROT_WILT + 0.01, "eingefallen": Item.ROT_SAG + 0.01}.get(_arg_value(arg, "--rot"), Item.ROT_WILT)
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
		var hm := _arg_value(arg, "--uhr").split(":")
		var hour := hm[0].to_float() + (hm[1].to_float() / 60.0 if hm.size() > 1 else 0.0)
		Game.director.elapsed = maxf(0.0, Calendar.at(Calendar.day_of(Game.director.elapsed), hour))
	elif arg.begins_with("--bulb-thief="):
		# Gast klaut sofort eine Glühbirne aus Zimmer 13
		var thief := _guest(_arg_value(arg, "--bulb-thief"))
		var lamp: Lamp = thief._bulb_to_steal(true) if thief else null
		if lamp:
			thief._steal_lamp = lamp
			thief._walk_to(Vector3(lamp.global_position.x, 0, lamp.global_position.z) + thief._toward_room(lamp), Guest.State.STEAL)
	elif arg.begins_with("--lichtgang="):
		# Gast steht vor seiner Tür, drinnen ist das Licht aus: Er geht hinein und zum Schalter (7.3), nach 30 s
		# wieder hinaus in die Lobby und macht als Letzter aus (außer er vergisst es) – auch wenn du dich drin versteckst
		var light_args := _arg_parts(arg, "--lichtgang")
		var walker := _guest(light_args[0])
		var sw := LightSwitch.find(get_tree(), String(walker.home["no"])) if walker else null
		if sw:
			sw.set_on(false, true)
			walker.global_position = walker.home["door_front"]
			walker._walk_to(walker._room_point(), Guest.State.WALK)
			if light_args.size() > 1 and light_args[1] == "versteckt":
				var hide: HideSpot = null
				for spot: HideSpot in walker.home["spots"]:
					if hide == null or (spot.type == HideSpot.Type.WARDROBE and hide.type != HideSpot.Type.WARDROBE):
						hide = spot
				if hide:
					Game.player.global_position = hide.exit_point.global_position
					Game.player.enter_hide(hide)
			get_tree().create_timer(30.0, false).timeout.connect(func() -> void:
				if not walker.dead:
					walker._walk_to(Game.social.builder.lobby_seats.pick_random(), Guest.State.WALK))
	elif arg.begins_with("--bad="):
		# Gast geht ins Bad (6.19) – nach 1 s, wenn alle stehen
		var bather := _guest(_arg_value(arg, "--bad"))
		if bather:
			get_tree().create_timer(1.0, false).timeout.connect(func() -> void: Game.social.bath.debug(bather))
	elif arg.begins_with("--kerzenpflege="):
		# Gast kümmert sich um die dunklen Kerzen vor seiner Tür (5.12) – nach 1 s, wenn die Startdeko steht
		var parts := _arg_parts(arg, "--kerzenpflege")
		var carer := _guest(parts[0])
		if carer:
			get_tree().create_timer(1.0, false).timeout.connect(func() -> void:
				Game.social.candles.debug(carer, parts.size() > 1 and parts[1] == "ohne"))
	elif _is_arg(arg, "--abbrennen"):
		# Alle Kerzen fast heruntergebrannt (5.12) – nach 1 s, wenn die Startdeko steht
		var rest := _arg_value(arg, "--abbrennen", "0.02").to_float()
		get_tree().create_timer(1.0, false).timeout.connect(func() -> void:
			for node in get_tree().get_nodes_in_group("items"):
				var item := node as Item
				if item.has_wick():
					item.set_wax(rest)
			for node in get_tree().get_nodes_in_group("fixed_candles"):
				(node as FixedCandle).renew(rest, (node as FixedCandle).lit)
			print("[Kerzen] Debug: alle Kerzen auf %.0f %%" % (rest * 100.0)))
	elif arg.begins_with("--schmuckplan="):
		var parts := _arg_parts(arg, "--schmuckplan")
		var who := _guest(parts[1]) if parts.size() > 1 else null
		get_tree().create_timer(1.0, false).timeout.connect(_debug_deco_plan.bind(parts[0], who))
	elif arg == "--abweisung" or arg == "--abweisung=dunkel":
		get_tree().create_timer(1.0, false).timeout.connect(_debug_repel.bind(arg.ends_with("dunkel")))
	elif arg.begins_with("--diary="):
		# wie am Tagebuch speichern (nach 2 s)
		var slot := _arg_value(arg, "--diary").to_int()
		get_tree().create_timer(2.0).timeout.connect(func() -> void:
			var ok := SaveManager.save_to(slot, SaveManager.diary_sentence(), get_viewport().get_texture().get_image())
			print("[diary] Slot %d gespeichert: %s – „%s“" % [slot, ok, SaveManager.diary_sentence()]))
	elif arg == "--unterbrechen" or arg == "--unterbrechen=laden":
		if Engine.has_meta("debug_suspended"):   # nach dem Laden laufen die Parameter erneut – nur einmal
			return true
		Engine.set_meta("debug_suspended", true)
		get_tree().create_timer(2.0).timeout.connect(func() -> void:
			var ok := SaveManager.suspend(null)
			print("[Zwischenstand] %s – „%s“" % ["geschrieben" if ok else "gesperrt", SaveManager.diary_sentence()])
			if not ok:
				return
			if arg == "--unterbrechen":
				get_tree().quit()
				return
			SaveManager.load_slot(SaveManager.SUSPEND)
			print("[Zwischenstand] geladen, Datei %s" % ("noch da – FEHLER" if SaveManager.slot_exists(SaveManager.SUSPEND)
				else "gelöscht")))
	elif _is_arg(arg, "--fortschritt"):
		get_tree().create_timer(2.0).timeout.connect(SaveManager.on_progress.bind(_arg_value(arg, "--fortschritt", "Debug")))
	elif _is_arg(arg, "--albtraummodus"):
		if _arg_value(arg, "--albtraummodus") == "pruefen":
			get_tree().create_timer(2.0, false).timeout.connect(_debug_nightmare_check)
		else:
			Game.nightmare_mode = true
			Game.current_slot = clampi(_arg_value(arg, "--albtraummodus", "3").to_int(), 1, SaveManager.SLOTS)
	elif arg.begins_with("--menu="):
		# Menü für Screenshots öffnen: pause, diary, diary_pages, settings, load, help, achievements (controls: alter Name der Hilfe)
		var which := _arg_value(arg, "--menu")
		if which == "controls":
			which = "help"
		get_tree().create_timer(1.0).timeout.connect(func() -> void:
			if which in ["diary", "diary_pages"]:
				Game.menus.open_diary()
				if which == "diary_pages":   # die aufgeschriebenen Meilensteine, letzte Seite (3.10)
					Game.menus.call("_show_diary_pages", -1)
			else:
				Game.menus.open_pause()
				if which != "pause":
					Game.menus.call("_show_" + which))
	elif arg.begins_with("--taste="):
		# Tastenbelegung (8.4) nur für die Sitzung: --taste=aktion,taste[,platz] – Taste wie „f“, „space“ oder „maus2“
		var parts := _arg_parts(arg, "--taste")
		var event: InputEvent = null
		if parts.size() >= 2 and parts[1].begins_with("maus"):
			event = Keys.decode("mouse:" + parts[1].trim_prefix("maus"))
		elif parts.size() >= 2:
			event = Keys.decode("key:%d" % OS.find_keycode_from_string(parts[1].capitalize()))
		if event == null or not InputMap.has_action(parts[0]):
			push_warning("--taste: Aktion oder Taste unbekannt – " + arg)
		else:
			var note := Keys.assign(parts[0], parts[2].to_int() if parts.size() > 2 else 0, event)
			print("[Tasten] %s → %s %s · „%s“" % [parts[0], Keys.key_names(parts[0]), note,
				Keys.localize("Öffnen [E] · ablegen [G] · [Linksklick] · [Ein Knall]")])
	elif arg.begins_with("--erfolg=") or arg == "--erfolge-zurueck":
		return Game.achievements.debug_command(arg)
	elif arg == "--figur" or arg == "--figur=schnell":
		_start_creation(0, arg.ends_with("schnell"))
	elif arg == "--savetest":
		get_tree().create_timer(6.0).timeout.connect(_save_test)
	elif arg == "--navcheck":
		get_tree().create_timer(2.0).timeout.connect(_nav_check)
	elif arg == "--navcheck=tueren" or arg == "--navcheck=türen":
		get_tree().create_timer(2.0).timeout.connect(_nav_check_doors)
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
		"--tiere":
			Game.weather.animals.debug(value)
		"--kesselkatze":
			get_tree().create_timer(1.0).timeout.connect(Game.boiler_cat.debug_show.bind(value))
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
		"--leviathan":
			get_tree().create_timer(1.0).timeout.connect(Game.leviathan_name.debug.bind(value))
		"--leviathanfoto":
			get_tree().create_timer(1.0).timeout.connect(Game.leviathan_name.debug_photo.bind(value))
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


## --abweisung[=dunkel]: Schutzkreis = Lichtschein (Spielkonzept 5.10, Stufe 2). Vor der Tür von Zimmer 13 stehen ein
## geschnitzter Kürbis, ein Totenkopf und eine Kerze, alle brennend (dunkel: Kürbis ohne Kerze und Laub), du stehst
## 1,2 m daneben im Schein, Blick den Flur hinunter; nach 1 s kommt von dort das Monster. Mit Licht weist es ab, die Flammen
## ducken sich – ohne Licht zählt die Deko nur halb (und nur direkt an der Tür), es holt dich.
func _debug_repel(dark: bool) -> void:
	var info: Dictionary = Game.director.rooms[LevelBuilder.PLAYER_ROOM]
	var front: Vector3 = info["door_front"]
	var into: Vector3 = info["into"]
	into = Vector3(into.x, 0.0, into.z).normalized()
	var side := into.cross(Vector3.UP)
	var kinds := [[Item.Kind.CARVED_PUMPKIN, "unlit"], [Item.Kind.LEAVES, ""]] if dark \
		else [[Item.Kind.CARVED_PUMPKIN, ""], [Item.Kind.SKULL, "lit"], [Item.Kind.CANDLE, "lit"]]
	for i in kinds.size():
		var item := Item.create(kinds[i][0], kinds[i][1])
		Game.player.get_parent().add_child(item)
		item.global_position = front + into * 0.35 + side * (i - (kinds.size() - 1) / 2.0) * 0.45 + Vector3.UP * 0.05
		item.rotation.y = atan2(-into.x, -into.z)   # Gesicht zum Flur
	TeleportUI.place_player(front + side * 1.2, (-side + into * 0.5).normalized())
	Game.player.head.rotation.x = -0.3   # die Deko unten im Bild, der Flur dahinter
	get_tree().create_timer(1.0, false).timeout.connect(func() -> void:
		var from := NavigationServer3D.map_get_closest_point(get_world_3d().navigation_map, front - side * 9.0)
		print("[Abweisung] Debug: %s, Monster kommt von (%.1f, %.1f)" % ["ohne Licht" if dark else "mit Licht", from.x, from.z])
		var you := Game.player.global_position
		print("[Abweisung] an der Tür: Deko %.0f, Abschreckung %.0f, Druck %.0f · bei dir: Deko %.0f, Abschreckung %.0f" % [
			Game.director.deco_strength_at(front), Game.director.deterrence_at(front), Game.director.pressure_at(front, true),
			Game.director.deco_strength_at(you), Game.director.deterrence_at(you)])
		Game.monster.spawn_at(from)
		Game.monster.investigate(front))


## --schmuckplan=angst|freund|tod|klau[,gast]: Gäste schmücken mit Plan bzw. klauen (Spielkonzept 5.10, Stufe 3) – du
## stehst vor der Tür, um die es geht (DecoPlan.debug). tod: der Gast stirbt, seine Nachbarn schmücken nach.
func _debug_deco_plan(what: String, who: Guest) -> void:
	var plan := Game.social.decorating.plan
	var no := plan.debug(what, who)
	if no == "":
		print("[Schmuckplan] Debug: nichts gestartet")
		return
	var room: Dictionary = Game.director.rooms[no]
	var into: Vector3 = room["into"]
	TeleportUI.place_player(room["door_front"] - into * 0.8, into)
	Game.player.head.rotation.x = -0.3   # Tür und Boden davor im Bild
	if what == "tod":
		for g in Game.social.living_guests():
			if String((g as Guest).home["no"]) == no:
				_debug_kill(g, "", false, false)
				break


## --navcheck=tueren: Erreicht das Monster vom Keller aus (MonsterDirector.reachable, wie bei der Wahl der Puppentür)
## jede bewohnte Zimmertür (Spielkonzept 4.33, gegen Fehlverhalten des Spiels, Punkt 5)? Meldet wie --navcheck.
func _nav_check_doors() -> void:
	var director := Game.director
	var bad := 0
	var rooms := director.inhabited_rooms()
	for no in rooms:
		var reached := director.reachable(director.rooms[no]["door_front"])
		var who := "Spieler" if no == LevelBuilder.PLAYER_ROOM else ", ".join(Game.social.living_guests() \
			.filter(func(g: Guest) -> bool: return String(g.home["no"]) == no) \
			.map(func(g: Guest) -> String: return String(g.display_name)))
		print("[navcheck]   Zimmer %-6s %-30s %s" % [no, who, "erreichbar" if reached else "UNERREICHBAR"])
		bad += 0 if reached else 1
	print("[navcheck] %d bewohnte Türen geprüft" % rooms.size())
	print("[navcheck] alles erreichbar" if bad == 0 else "[navcheck] %d Orte unerreichbar" % bad)
	get_tree().quit()


## Debug --aufzug=dach (Spielkonzept 7.10, ZIM-42): vor die Aufzugtür im Dachgeschoss, nach 1 s Ruf von oben – das
## schaltet den Halt frei, die Kabine kommt; nach 30 s Prüfung „[Aufzug] Dachgeschoss: …“. Ohne Halt oben im Plan nur
## die Meldung, man bleibt stehen.
func _debug_lift_attic(lift: Elevator) -> bool:
	var top := lift.attic.find(true)
	if top < 0:
		print("[Aufzug] Dachgeschoss: kein Halt – im Plan „DG“ fehlen Schacht und Aufzugtür")
		Game.say("Der Aufzug hat im Dachgeschoss keinen Halt (Plan).", 4.0)
		return true
	var at := lift.waiting_spot(top, 1.5)
	TeleportUI.place_player(at[0], at[1] - at[0])
	get_tree().create_timer(1.0).timeout.connect(func() -> void:
		var before := lift.serves(top)
		lift.call_from(top)
		get_tree().create_timer(30.0).timeout.connect(func() -> void:
			var ok := not before and lift.unlocked and lift.next_stop() == top and not lift.moving()
			print("[Aufzug] Dachgeschoss: %s (vorher gesperrt %s, frei %s, Halt %s)" % ["ok" if ok else "FEHLER",
				not before, lift.unlocked, lift.next_stop()])))
	return true


## Debug --aufzug=reparatur (Spielkonzept 7.4, ZIM-14): Sperre an, in die Kabine, das Notizbuch des Hausmeisters gilt
## als gelesen. Dann der Reihe nach, je 1 s auseinander: Knopf ohne Strom, Schaltschlüssel an den Bund und in den
## Schalter, Hauptsicherung in die Hand und in den Sicherungskasten, Knopf ohne gelöste Bremse, die Kurbel ganz
## gedreht – zurück in die Kabine: nach FIRST_RIDE_DELAY fährt sie allein zum untersten Halt. Jede Prüfung meldet
## „[Aufzug] Reparatur … ok“ bzw. „FEHLER“, zuletzt „[Aufzug] Reparatur: fertig“.
func _debug_lift_repair(lift: Elevator) -> bool:
	var drive := get_tree().get_first_node_in_group("lift_drives") as LiftDrive
	var book := get_tree().get_first_node_in_group("caretaker_books") as CaretakerBook
	if drive == null or Game.power_cut == null:
		print("[Aufzug] Reparatur FEHLER: Antrieb oder Sicherungskasten fehlt")
		return true
	lift.set_repair_lock(true)
	Game.notebook.give(true)
	if book:
		book.read()
	var inside := func() -> void:
		var at := lift.spot(true)
		TeleportUI.place_player(at[0], at[1])
	inside.call()
	var check := func(text: String, ok: bool) -> void:
		print("[Aufzug] Reparatur %s: %s" % [text, "ok" if ok else "FEHLER"])
	var push := func(action: Elevator.Do, stop: int) -> void:
		var p := Elevator.Push.new()
		p.action = action
		p.stop = stop
		lift.press(p)
		p.free()
	var top := lift.stops.size() - 1
	var steps: Array[Callable] = [
		func() -> void:
			check.call("vorher steht sie", not lift.runs() and not lift.moving())
			push.call(Elevator.Do.FLOOR, top)
			check.call("Knopf ohne Strom", lift.next_stop() != top and not lift.moving()),
		func() -> void:
			Game.player.add_key(CaretakerBook.KEY_ID)
			push.call(Elevator.Do.KEY, -1)
			check.call("Schaltschlüssel", "key" in lift.repaired and Game.notebook.task_state("lift_key") == Notebook.TaskState.DONE),
		func() -> void:
			Game.player.receive_item(Item.create(Item.Kind.FUSE))
			var box := Game.power_cut.fuse_box
			var front := box.global_position + box.global_transform.basis.z * 1.0
			TeleportUI.place_player(Vector3(front.x, LevelBuilder.CELLAR_Y + 0.05, front.z), box.global_position - front)
			box.interact(Game.player)
			check.call("Hauptsicherung", "fuse" in lift.repaired and not Game.player.has_kind(Item.Kind.FUSE)),
		func() -> void:
			push.call(Elevator.Do.FLOOR, top)
			check.call("Knopf ohne Bremse", not lift.runs() and not lift.moving()),
		func() -> void:
			var front := drive.global_position + drive.global_transform.basis.z * 1.0
			TeleportUI.place_player(front, drive.global_position - front)
			for i in int(LiftDrive.CRANK_TIME / 0.5) + 1:
				drive.crank(0.5)
			check.call("Bremse", "brake" in lift.repaired and lift.runs() and lift.first_ride
				and Game.notebook.task_state("lift_brake") == Notebook.TaskState.DONE),
		inside,
	]
	for i in steps.size():
		get_tree().create_timer(1.0 + i).timeout.connect(steps[i])
	get_tree().create_timer(steps.size() + 1.0 + Elevator.FIRST_RIDE_DELAY + 25.0).timeout.connect(func() -> void:
		check.call("erste Fahrt", not lift.first_ride and lift.next_stop() == 0 and not lift.moving())
		print("[Aufzug] Reparatur: fertig"))
	return true


## Debug (--dachboden=urteil, --aufzug=urteil): nach 1 s ein Urteil über Zimmer 13 in 2 s (4.33).
func _debug_judgment_on_13() -> void:
	Game.director.debug_doom = LevelBuilder.PLAYER_ROOM
	Game.ghost.debug_rest(600.0)   # der Lakengeist käme sonst dazwischen
	get_tree().create_timer(1.0).timeout.connect(func() -> void:
		Game.director.debug_start(MonsterDirector.Mode.JUDGMENT, 2.0))


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


## --zugleich: drei Bedrohungen zugleich (Spielkonzept 4.1, 4.20, ZIM-48). Jede kommt auf ihrem natürlichen Weg, während
## die anderen schon unterwegs sind: Die Uhr springt kurz vor Mitternacht – der Lakengeist geht in der Geisterstunde um;
## dann fällt die Garantie des Kürbismanns (Ankündigung, rote Lampen); dann wird ein Snack fällig – das Monster bricht
## auf. Meldet „[Zugleich] … ok“ bzw. „FEHLER“ (zählt im Rauchtest).
func _debug_together() -> void:
	var director := Game.director
	var check := func(text: String, ok: bool) -> void:
		print("[Zugleich] %s: %s" % [text, "ok" if ok else "FEHLER"])
	director.first_attack_done = true
	director.elapsed = Calendar.at(Calendar.day_of(director.elapsed), 24.0 - 3.0 / Calendar.HOUR)
	director.hold(60.0)   # das Monster erst als Letztes
	for i in 60:   # vorher kommt er manchmal noch zu einem Gast ans Fenster
		await get_tree().create_timer(0.5, false).timeout
		if Game.ghost.state == SheetGhost.State.PATROL:
			break
	check.call("Lakengeist geht in der Geisterstunde um", Game.ghost.state == SheetGhost.State.PATROL)
	Game.pumpkin.guarantee_checked = true
	Game.pumpkin.guarantee_at = [director.elapsed]
	await get_tree().create_timer(3.0, false).timeout
	check.call("Kürbismann kündigt sich an, Lakengeist unterwegs", Game.pumpkin.announcing() and Game.ghost.is_active())
	director.debug_start(MonsterDirector.Mode.SNACK, 1.0)
	await get_tree().create_timer(4.0, false).timeout
	check.call("Monster bricht auf", Game.monster.is_active())
	check.call("drei Bedrohungen zugleich", Game.monster.is_active() and Game.ghost.is_active() \
		and (Game.pumpkin.announcing() or Game.pumpkin.in_house()))
	check.call("Szenen warten weiter", director.other_threat_active(null) and not director.threats_paused())


## --kill: Gast sofort tot, ohne dass das Monster kommt. corpse: er liegt da (wie nach Lakengeist und Kürbismann), sonst
## ist er verschwunden wie vom Monster geholt (Kratzer, ein Schuh); blood: Blutlache und Spritzer an der nächsten Wand.
## cause ("ghost", "pumpkin", "monster") bestimmt nur, was das Hotel hört und meldet (Social.on_guest_died).
## quiet: ohne Meldung und Glocke (--kill=alle meldet einmal für alle).
func _debug_kill(victim: Guest, cause: String, corpse: bool, blood: bool, quiet: bool = false) -> void:
	var where := victim.global_position
	if corpse:
		Game.sound_at("grunt", where, Senses.GRUNT_RANGE, victim)
	else:
		Game.noise("death_scream", where, victim)
	victim.die("ghost" if corpse else "monster")
	if blood and Game.traces:
		Game.traces.add_blood(where, randf() * TAU)
		Game.traces.add_wall_blood(where, "wall_splatter")
	Game.social.on_guest_died(victim, cause, quiet)


## Werte von --kill=gast,… : cause ("ghost"/"pumpkin"/"" = Monster holt ihn), instant (sofort tot statt Monster),
## corpse, blood, here (vor dich stellen).
func _kill_options(parts: PackedStringArray) -> Dictionary:
	var cause := ""
	for part in parts.slice(1):
		cause = {"geist": "ghost", "kuerbis": "pumpkin", "kürbis": "pumpkin"}.get(part, cause)
	var corpse := "leiche" in parts or (cause != "" and not "weg" in parts)
	return {"cause": cause if cause != "" else "ghost" if corpse else "monster", "instant": cause != "" or "leiche" in parts
		or "weg" in parts, "corpse": corpse, "blood": ("blut" in parts or cause == "pumpkin") and not "ohneblut" in parts,
		"here": cause != "" or "hin" in parts}


## „alle“ statt eines Gastes (Debug-Konsole und Startparameter): Der Befehl läuft für jeden lebenden Gast – bei kill und
## wound ohne Kinder, außer mit „kinder“. Welche Befehle es können und wo der Gast steht: DebugConsole.GUEST_ALL.
## false = kein „alle“ in diesem Befehl.
func _debug_all(arg: String) -> bool:
	var eq := arg.find("=")
	var cmd := arg.substr(2, eq - 2) if eq > 0 else ""
	if not DebugConsole.GUEST_ALL.has(cmd):
		return false
	var parts := _arg_parts(arg, "--" + cmd)
	var slot: int = DebugConsole.GUEST_ALL[cmd]
	if parts.size() <= slot or parts[slot] != "alle":
		return false
	var kids := "kinder" in parts or not cmd in ["kill", "wound"]
	var targets := Game.social.living_guests().filter(func(g: Guest) -> bool: return kids or not g.is_child())
	if cmd == "kill":
		var opt := _kill_options(parts)
		if not opt["instant"]:
			Game.say("kill=alle nur mit leiche, weg, geist oder kuerbis – das Monster holt nicht alle auf einmal", 4.0)
			return true
		for g: Guest in targets:   # wo jeder gerade ist – „hin“ würde alle auf einen Fleck stellen
			_debug_kill(g, opt["cause"], opt["corpse"], opt["blood"], true)
		Game.say("%d Gäste tot" % targets.size(), 4.0, "dead")
		get_tree().create_timer(Social.BELL_DELAY, false).timeout.connect(Game.play_sound.bind("bell"))
		return true
	for word in ["kinder", "hin"]:   # hin: alle vor dich – ergibt keinen Sinn
		var at := parts.find(word)
		if at >= 0:
			parts.remove_at(at)
			if at < slot:   # „alle“ rückt mit nach vorn
				slot -= 1
	for g: Guest in targets:
		parts[slot] = g.id
		run_debug("--%s=%s" % [cmd, ",".join(parts)])
	Game.say("%s für %d Gäste" % [cmd, targets.size()], 3.0)
	return true


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
		Game.ghost.debug_summon_guest(guest, maxi(1, what.trim_prefix("ghost").to_int()))
		return
	var front: Vector3 = home["door_front"]
	# in die Flurrichtung, in der 6 m frei sind
	var ray := PhysicsRayQueryParameters3D.create(front + Vector3.UP, front + Vector3.UP + along * 6.0, 1)
	if not get_world_3d().direct_space_state.intersect_ray(ray).is_empty():
		along = -along
	guest.global_position = front + Vector3(0, 0.05, 0)
	guest.rotation.y = atan2(-along.x, -along.z)
	var spot := front + along * (0.8 if what == "lache" else 2.5)   # lache: so nah, dass er zurücktritt (4.13)
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


## --albtraummodus=pruefen (Spielkonzept 8.9): normales Spiel in Slot 2 speichern, sterben – der Slot bleibt; dann Albtraum in
## Slot 3: Tagebuch und Autosave landen dort, der Modus kommt aus dem Stand zurück, der Tod löscht den Slot, Slot 2
## bleibt. Meldet je Schritt „[Albtraum] … ok“ bzw. „FEHLER“, am Ende „[Albtraum] Prüfung fertig“.
func _debug_nightmare_check() -> void:
	var check := func(what: String, good: bool) -> void: print("[Albtraum] %s: %s" % [what, "ok" if good else "FEHLER"])
	Game.nightmare_mode = false
	Game.current_slot = 2
	SaveManager.save_to(2, SaveManager.diary_sentence(), null)
	SaveManager.on_death()   # wie beim Sterben – im normalen Spiel ohne Folgen
	var normal := SaveManager.slot_info(2)
	check.call("normales Spiel bleibt nach dem Tod ladbar", not normal.is_empty() and normal["fits"] and not normal["nightmare"])
	Game.nightmare_mode = true
	Game.current_slot = 3
	SaveManager.save_to(3, "vorher", null)
	var diary := SaveManager.slot_info(3)
	check.call("Tagebuch in Slot 3, als Albtraum erkennbar", not diary.is_empty() and diary["fits"] and diary["nightmare"])
	check.call("Autosave geht in den Albtraum-Slot", SaveManager.autosave_slot() == 3)
	SaveManager.autosave("Prüfung")
	check.call("Autosave geschrieben", String(SaveManager.slot_info(3).get("text", "vorher")) != "vorher")
	var data: Dictionary = JSON.parse_string(JSON.stringify(SaveManager.collect()))
	Game.nightmare_mode = false
	SaveManager.apply(data)
	await get_tree().physics_frame
	check.call("Modus kommt aus dem Spielstand zurück", Game.nightmare_mode and Game.current_slot == 3)
	Game.director.player_slain("ghost")
	check.call("der Tod löscht den Albtraum-Slot", not SaveManager.slot_exists(3))
	check.call("das normale Spiel in Slot 2 bleibt", SaveManager.slot_exists(2))
	print("[Albtraum] Prüfung fertig")


## --savetest: Speichern und Laden ohne Datei durchspielen und Unterschiede ausgeben.
func _save_test() -> void:
	# Etwas Unordnung, damit der Test mehr abdeckt: Vorhang zu, Licht aus, Birne in der Hand
	(get_tree().get_nodes_in_group("windows").filter(func(w: Node) -> bool: return w.has_curtains())[0] as HotelWindow).set_closed(true)
	(get_tree().get_nodes_in_group("light_switches")[0] as LightSwitch).set_on(false)
	# eine Zimmerlampe (Raum-ID = Zimmernummer), sonst irgendeine – unabhängig davon, wie der Plan eingerichtet ist
	var fixtures := get_tree().get_nodes_in_group("lamp_fixtures").filter(func(l: Node) -> bool: return (l as Lamp).has_bulb and (l as Lamp).has_socket())
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


## Savetest: so viel Neugier bringt ein einzelner Lärm bis 12 m Hörweite (MonsterDirector.NOISE_CURIOSITY × 12)
const SAVETEST_NOISE_HEAT := 3.0


## Bekanntes Rauschen zwischen den beiden Sammelzeitpunkten angleichen, damit nur echte Lade-Lücken zählen:
## Lage von Gegenständen in der Hand (folgt der Hand, apply setzt sie nicht), Türen, die ein Gast im Türrahmen
## gleich nach dem Laden öffnet (sein Zustand – Klopfen, Schlafen … – wird nicht gespeichert, er steht danach
## untätig da), Drehung liegender Gegenstände bis ~15°, Katzen-Zeitgeber, die genau dazwischen abliefen, und heiße
## Stellen aus Lärm gleich nach dem Laden (wieder aufgeschreckte Krähen und Fledermäuse). Gibt Hinweise dazu zurück.
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
	# Krähen und Fledermäuse: Ob sie gerade fliegen, wird nicht gespeichert – nach dem Laden sitzen sie wieder und
	# fliegen vor einer Bedrohung in der Nähe (Lakengeist, Monster …) gleich noch einmal auf. Ihr Lärm macht eine neue,
	# schwache heiße Stelle (4.9) oder eine vorhandene etwas heißer – höchstens so viel wie ein einzelner Lärm.
	var hot_was: Array = before["director"]["state"].get("hot_spots", [])
	var hot_now: Array = after["director"]["state"].get("hot_spots", [])
	for i in range(hot_now.size() - 1, -1, -1):
		var b: Array = hot_now[i]
		var match_was: Array = []
		for a: Array in hot_was:
			if Vector3(a[0], a[1], a[2]).distance_to(Vector3(b[0], b[1], b[2])) < 0.01:
				match_was = a
		if match_was.is_empty() and float(b[3]) <= SAVETEST_NOISE_HEAT:
			hot_now.remove_at(i)
			notes.append("director.hot_spots: neue schwache Stelle bei (%.0f, %.0f, %.0f) – Lärm gleich nach dem Laden" % [b[0], b[1], b[2]])
		elif not match_was.is_empty() and float(b[3]) > float(match_was[3]) \
				and float(b[3]) - float(match_was[3]) <= SAVETEST_NOISE_HEAT:
			b[3] = match_was[3]
			notes.append("director.hot_spots: Stelle bei (%.0f, %.0f, %.0f) durch Lärm gleich nach dem Laden heißer" % [b[0], b[1], b[2]])
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


## --pumpkin=zeigen[,was]: Der Kürbismann erscheint in der Lobby vor dir und jagt dich, du hältst ihm einen Kürbis
## entgegen (Spielkonzept 4.21, 1). was: geschnitzt (Standard, ohne Kerze), kerze, eine Sorte aus PumpkinKinds, mini,
## brei, braten (die drei wirken nicht) oder zwei (nach der ersten Betäubung ein zweiter geschnitzter).
func _debug_pumpkin_show(what: String) -> void:
	var kinds := {"": [Item.Kind.CARVED_PUMPKIN, "unlit"], "geschnitzt": [Item.Kind.CARVED_PUMPKIN, "unlit"],
		"zwei": [Item.Kind.CARVED_PUMPKIN, "unlit"], "kerze": [Item.Kind.CARVED_PUMPKIN, ""],
		"mini": [Item.Kind.MINI_PUMPKIN, ""], "brei": [Item.Kind.PUMPKIN_MUSH, ""], "braten": [Item.Kind.ROAST_PUMPKIN, ""]}
	if not kinds.has(what) and not PumpkinKinds.DATA.has(what):
		Game.say("Zeigen: geschnitzt, kerze, mini, brei, braten, zwei oder eine Sorte (%s)" % ", ".join(PumpkinKinds.ORDER), 3.0)
		return
	var tries := 0
	while true:   # NavMesh muss erst synchronisiert sein
		await get_tree().create_timer(0.5, false).timeout
		if Game.pumpkin.debug_show():
			break
		tries += 1
		if tries >= 20:
			Game.say("Kürbismann: kein Platz zum Erscheinen")
			return
	var pick: Array = kinds.get(what, [Item.Kind.PUMPKIN, what])
	Game.player.drop_held()
	Game.player.receive_item(Item.create(pick[0], pick[1]))
	var stuns := 0
	var was := false
	while Game.pumpkin.in_house() and not Game.game_over:
		_face_toward(Game.pumpkin.global_position)   # du siehst ihn an
		var now: bool = Game.pumpkin.stunned()
		if now and not was:
			stuns += 1
		elif was and not now and what == "zwei" and stuns == 1:
			Game.player.drop_held()   # der erste wirkt nicht mehr – der zweite schon
			Game.player.receive_item(Item.create(Item.Kind.CARVED_PUMPKIN, "unlit"))
		was = now
		await get_tree().physics_frame


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


## --kommode[=suchen|verstecken][,gast] (Spielkonzept 3.5, ZIM-39): die Kommode im Flur, die dem Spieler am nächsten
## ist und die Gäste durchsuchen; er steht seitlich davor, ein freier Erwachsener (oder dieser) 3 m vor ihr.
## suchen: In der untersten Schublade liegt eine Plastikspinne des Spielers, in der zweiten eine Fledermausgirlande eines
## anderen Gastes (beide offen); der Gast durchsucht die Kommode. Prüft: alle Schubladen offen und durchsucht, Girlande
## in seiner Hand, Spinne liegt noch. verstecken: Kisten leer, er hat Angst und einen Totenkopf im Koffer und versteckt
## sein stärkstes Stück (DecoPlan.hide_when_scarce); danach durchsucht ein zweiter Gast die Kommode und nimmt es mit.
func _debug_dresser(parts: PackedStringArray) -> void:
	var check := func(what: String, ok: bool) -> void:
		print("[Kommode] %s: %s" % [what, "ok" if ok else "FEHLER"])
	var search := Game.social.search
	var p := Game.player
	var dressers := get_tree().get_nodes_in_group("dressers").filter(func(d: Dresser) -> bool:
		return d.guests_search() and d.global_position.y > -0.5 and not Game.director.rooms.has(Game.social.builder.room_at(d.global_position)))
	if dressers.is_empty():
		check.call("keine Kommode, die Gäste durchsuchen", false)
		return
	dressers.sort_custom(func(a: Dresser, b: Dresser) -> bool:
		return a.global_position.distance_to(p.global_position) < b.global_position.distance_to(p.global_position))
	var d: Dresser = dressers[0]
	var front := d.global_transform.basis.z
	var side := front.cross(Vector3.UP)
	p.global_position = d.global_position + front * 1.6 + side * 1.4 + Vector3.UP * 0.05
	_face_toward(d.global_position + Vector3.UP * 0.5)
	var free := Game.social.living_guests().filter(func(g: Guest) -> bool:
		return not g.is_child() and search._available(g) and not Grinch.is_grinch(g))
	var who: Guest = Game.social.find_guest(parts[1]) if parts.size() > 1 else null
	if who:
		free.erase(who)
		free.push_front(who)
	if free.size() < 2:
		check.call("zu wenige freie Gäste", false)
		return
	var walk_up := func(g: Guest) -> void:
		g._set_idle(5.0)
		g.global_position = NavigationServer3D.map_get_closest_point(get_world_3d().navigation_map, d.global_position + front * 3.0)
	var g: Guest = free[0]
	walk_up.call(g)
	if parts[0] == "verstecken":
		for node in get_tree().get_nodes_in_group("resource_spots"):
			if (node as ResourceSpot).runs_out():
				(node as ResourceSpot).uses = 0
		g.fear = 60.0
		g.stock[Item.Kind.SKULL] = int(g.stock.get(Item.Kind.SKULL, 0)) + 1
		var plan := Game.social.decorating.plan
		check.call("Knappheit", plan.scarce())
		check.call("%s will verstecken" % g.display_name, plan.hide_when_scarce(g))
		await _until(func() -> bool: return not search.is_busy(g), 40.0)
		await get_tree().create_timer(2.0, false).timeout
		var hidden: Item = null
		for node in get_tree().get_nodes_in_group("items"):
			if (node as Item).owner_id == g.id and not (node as Item).is_held and d.holds_point((node as Item).global_position):
				hidden = node
		check.call("versteckt in der Kommode: %s" % (hidden.display_name if hidden else "nichts"), hidden != null)
		check.call("Schublade wieder zu", not d.is_open.has(true))
		check.call("zweites Mal versteckt er nicht", not plan.hide_when_scarce(g))
		if hidden == null:
			return
		var g2: Guest = free[1]
		walk_up.call(g2)
		check.call("%s sucht" % g2.display_name, search.start(g2, false, d))
		await _until(func() -> bool: return not search.is_busy(g2), 40.0)
		check.call("%s nimmt das Versteckte mit" % g2.display_name, is_instance_valid(hidden) and g2.held == hidden)
		return
	var mine := Item.create(Item.Kind.SPIDER)
	mine.owner_id = "player"
	var theirs := Item.create(Item.Kind.BAT_GARLAND)
	theirs.owner_id = (free[1] as Guest).id
	d.set_open(0, true, true)
	d.set_open(1, true, true)
	d._drop_in(0, mine)
	d._drop_in(1, theirs)
	await get_tree().create_timer(1.0, false).timeout
	check.call("%s sucht" % g.display_name, search.start(g, false, d))
	await _until(func() -> bool: return not search.is_busy(g), 40.0)
	await get_tree().create_timer(1.0, false).timeout
	check.call("alle Schubladen offen", not d.is_open.has(false))
	check.call("alle durchsucht", not d.searched.has(false))
	check.call("Girlande in seiner Hand", is_instance_valid(theirs) and g.held == theirs)
	check.call("Spinne des Spielers liegt noch", is_instance_valid(mine) and not mine.is_held and d.holds_point(mine.global_position))
	check.call("Kommode ist leer für Gäste", not search._dressers_for(free[1]).has(d))


## Wartet, bis done() wahr ist, höchstens limit Sekunden Spielzeit.
func _until(done: Callable, limit: float) -> void:
	var waited := 0.0
	while not done.call() and waited < limit:
		await get_tree().create_timer(0.25, false).timeout
		waited += 0.25


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


## --maske[=id[,pruefen]]: Vor das Maskenboard in Zimmer 13 (Spielkonzept 5.19), Blick darauf; mit id die Maske vom
## Stift gleich aufgesetzt – die Masken ohne Gegenstand direkt (nur Debug). pruefen: _debug_mask_effect.
func _debug_masks(value: String) -> void:
	var parts := value.split(",")
	var id := parts[0]
	if parts.size() > 1 and parts[1] == "pruefen":
		_debug_masks(id)
		_debug_mask_effect(id)
		return
	var hooks := get_tree().get_nodes_in_group("mask_hooks")
	if hooks.is_empty():
		Game.say("Kein Maskenboard in Zimmer 13.", 3.0)
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
	if id in ["scarecrow", "crow", "cat"]:
		Game.player.set_mask(id)   # die Maske gibt es noch nicht als Gegenstand (5.19: Versteck fehlt)
		return
	Game.say("Keine Maske „%s“ am Haken." % id, 3.0)


## Leichte Wirkung der Masken prüfen (5.19, 2026-11-03), Meldung „[Maske] … ok“ bzw. „FEHLER“.
func _debug_mask_effect(id: String) -> void:
	var p := Game.player
	var report := func(what: String, ok: bool) -> void:
		print("[Maske] %s: %s" % [what, "ok" if ok else "FEHLER"])
	match id:
		"doll":
			var kid: Guest = null
			for g: Guest in Game.social.living_guests():
				if g.is_child() and g.hiding == null and g.state != Guest.State.SLEEP:
					kid = g
					break
			if kid == null:
				report.call("Puppe: kein Kind wach", false)
				return
			p.global_position = Game.social.builder.lobby_center + Vector3.UP * 0.1
			kid.global_position = p.global_position - p.global_transform.basis.z * 2.0
			kid._set_idle(30.0)
			await get_tree().create_timer(8.0).timeout
			var d := kid.global_position.distance_to(p.global_position)
			print("[Maske] Puppe: %s %.1f m vom Träger" % [kid.display_name, d])
			report.call("Puppe: Kind still und flüstert", kid.doll_hushed() or d >= Guest.DOLL_HUSH)
			report.call("Puppe: Kind hält Abstand", d >= Guest.DOLL_KEEP - 0.5)
		"scarecrow":
			var nest := Game.crows.nest.size()
			Game.crows.debug_show("stehlen")
			await get_tree().create_timer(15.0).timeout
			report.call("Vogelscheuche: Krähen stehlen nicht", Game.crows.nest.size() == nest
				and Game.crows._carry.all(func(c) -> bool: return c == null))
		"crow":
			Game.crows.debug_show("futter")
			var before := Game.crows.favor
			await get_tree().create_timer(12.0).timeout
			var gain := Game.crows.favor - before
			print("[Maske] Krähe: Ruf %+.2f nach der Fütterung" % gain)
			report.call("Krähe: Fütterung zählt doppelt", gain > Crows.FAVOR_FEED * 1.5)
		"cat":
			var cats := get_tree().get_nodes_in_group("cats")
			if cats.is_empty():
				report.call("Kesselkatze: keine Hotelkatze", false)
				return
			var cat: HotelCat = cats[0]
			p.global_position = Game.social.builder.lobby_center + Vector3.UP * 0.1
			cat.place_in_front_of(p)
			cat.global_position = p.global_position - p.global_transform.basis.z * 5.0 + Vector3.UP * 0.05
			p.rotation.y += PI   # weggehen: die Katze soll nachkommen
			await get_tree().create_timer(2.0).timeout
			p.global_position += -p.global_transform.basis.z * 2.0
			await get_tree().create_timer(10.0).timeout
			var d := cat.global_position.distance_to(p.global_position)
			print("[Maske] Kesselkatze: %s %.1f m hinter dir, Zustand %s" % [cat.display_name, d, HotelCat.State.keys()[cat.state]])
			report.call("Kesselkatze: Katze läuft nach", cat.state == HotelCat.State.FOLLOW and d < 3.0)


## --fremdbett=id[,beziehung] | frei[,h] (Spielkonzept 3.6): im Bett eines Gastes, der gleich schlafen geht – oder in
## einem Zimmer ohne lebende Bewohner.
func _debug_foreign_bed(args: PackedStringArray) -> void:
	var bed: HideSpot = null
	var guest: Guest = null
	if args[0] == "frei":   # ein Bett in einem Zimmer ohne lebende Bewohner – zu Beginn gibt es keins, dann irgendein fremdes
		var homes := Game.social.living_guests().map(func(g: Guest) -> String: return String(g.home["no"]))
		for node in get_tree().get_nodes_in_group("hide_spots"):
			var spot := node as HideSpot
			if spot.type == HideSpot.Type.BED and spot.room_no != "" and not spot.own_bed and (bed == null or not spot.room_no in homes):
				bed = spot
				if not spot.room_no in homes:
					break
	else:
		guest = Game.social.find_guest(args[0])
		if guest == null:
			push_warning("--fremdbett: kein Gast „%s“" % args[0])
			return
		if args.size() > 1:
			guest.relation = args[1].to_float()
		for spot: HideSpot in guest.home["spots"]:
			if spot.type == HideSpot.Type.BED and bed == null:
				bed = spot
	if bed == null:
		push_warning("--fremdbett: kein Bett gefunden")
		return
	Game.player.global_position = bed.exit_point.global_position
	if guest:
		guest.global_position = guest.home["center"]
	var hours := (args[1].to_int() if args.size() > 1 else 4) if guest == null else Player.SLEEP_HOURS.y
	get_tree().create_timer(1.5).timeout.connect(func() -> void:
		Game.player.bed_hours = clampi(hours, 1, Player.SLEEP_HOURS.y)
		Game.player.start_sleep(bed)
		if guest:
			Game.social.debug_sleep())   # Nachtruhe: Er geht ins Bett und findet dich
	if Game.tracing:
		print("[Fremdes Bett] Debug: Zimmer %s%s" % [bed.room_no, ", %s (Beziehung %.0f)" % [guest.display_name, guest.relation] if guest else ""])


## --wache[=id] (Spielkonzept 6.18, ZIM-62): Der Gast ist guter Freund, steht in Zimmer 13 und kommt auf deine Bitte
## mit – legst du dich hin (--sleep=bett), hält er Wache. Schläft er schon (--sleep=bett davor), steht er wieder auf.
func _debug_guard(id: String) -> void:
	var guest := Game.social.find_guest(id)
	if guest == null:
		push_warning("--wache: kein Gast „%s“" % id)
		return
	guest.relation = 90.0
	guest.wake_up()
	guest.global_position = Game.social.builder.rooms[LevelBuilder.PLAYER_ROOM]["center"]
	guest.start_guard()


## --eier=spieler|fenster[,zimmer] (Spielkonzept 6.13): spieler – du stehst 3 m vor der Tür von Zimmer (Standard Ednas),
## ein Ei in der Hand, der Bewohner sieht vom Flur aus zu, nach 1,5 s wirfst du; fenster – du stehst im ersten Zimmer
## mit Außenfenster davor und hast ein Ei, außen klebt schon eins (zum Ansehen und Wegwischen).
func _debug_eggs(args: PackedStringArray) -> void:
	var p := Game.player
	if args[0] == "fenster":
		for node in get_tree().get_nodes_in_group("windows"):
			var w := node as HotelWindow
			if w.exterior and not w.frosted and not w.sealed and w.room_id != "":
				p.global_position = w.global_transform * Vector3(0, 0, 1.6)
				p.global_position.y = w.global_position.y - 1.1
				_face_toward(w.global_position)
				Game.traces.add_window_egg(w, w.global_transform * Vector3(0.15, 0.1, 0), w.global_transform * Vector3(0, 0, -2))
				break
		p.receive_item(Item.create(Item.Kind.EGG))
		return
	var guest := Game.social.find_guest(args[1] if args.size() > 1 else "edna")
	if guest == null:
		push_warning("--eier: kein Gast")
		return
	var no := String(guest.home["no"])
	var room: Dictionary = Game.social.builder.rooms[no]
	var front: Vector3 = room["door_front"]
	p.global_position = front - (room["into"] as Vector3) * 2.2 + Vector3.UP * 0.05
	guest.global_position = front + (room["along"] as Vector3) * 3.0 + Vector3.UP * 0.05
	guest.look_at(Vector3(p.global_position.x, guest.global_position.y, p.global_position.z), Vector3.UP)
	guest._set_idle(20.0)
	p.receive_item(Item.create(Item.Kind.EGG))
	var door: Door = room["door"]
	_face_toward(door.center())
	p.head.rotation.x = 0.05
	get_tree().create_timer(1.5).timeout.connect(func() -> void:
		_face_toward(door.center())
		p.throw_held(0.6))


## --wecken=id[,gefahr|halluzination|klopfen] (Spielkonzept 3.6): Nachtruhe, alle liegen im Bett; nach 2 s weckst du
## den Gast an seinem Bett bzw. klopfst an seine Tür – mit echter oder falscher Flackerwelle.
func _debug_wake(args: PackedStringArray) -> void:
	var guest := Game.social.find_guest(args[0])
	if guest == null:
		push_warning("--wecken: kein Gast „%s“" % args[0])
		return
	var mode := args[1] if args.size() > 1 else ""
	Game.social.debug_sleep(true)
	var bed := guest.hiding as HideSpot
	var door: Door = guest.home["door"]
	if mode == "klopfen":
		Game.player.global_position = guest.home["door_front"]
	elif bed:
		Game.player.global_position = bed.exit_point.global_position
	else:
		push_warning("--wecken: %s liegt nicht im Bett" % guest.display_name)
		return
	get_tree().create_timer(2.0, false).timeout.connect(func() -> void:
		var director := Game.director
		if mode == "gefahr":
			director._start_wave(director.spawn_points[0], 1)
		elif mode == "halluzination":
			director._hallucination = 8.0
			director._start_wave(director.spawn_points[0], 2, true)
		if mode == "klopfen":
			Game.social.access.knock(door)
		elif bed:
			bed.interact(Game.player))


## --birnenersatz=id[,lager|klauen|meiden] (Spielkonzept 7.3): Im Zimmer des Haushaltsvorstands fehlen alle Birnen, er
## steht darin und überlegt gleich, was er tut.
func _debug_bulb_refill(args: PackedStringArray) -> void:
	var guest := Game.social.find_guest(args[0])
	if guest:
		guest = Game.social.household_lead(String(guest.home["no"]))
	if guest == null:
		push_warning("--birnenersatz: kein Gast „%s“" % args[0])
		return
	var mode := args[1] if args.size() > 1 else "lager"
	for lamp in guest._home_lamps():
		var bulb := lamp.take_bulb()
		if bulb:
			bulb.free()
	guest.stock[Item.Kind.BULB] = 0
	guest.clear_stance("bulb_tried")
	guest.profile["brave"] = 0.8 if mode == "klauen" else 0.2
	guest.global_position = guest.home["center"]
	guest._set_idle(1.0)
	if mode != "lager":
		# Ohne Lager: klauen bzw. meiden statt Ersatz aus dem Plan-Lager holen
		for node in get_tree().get_nodes_in_group("resource_spots"):
			if (node as ResourceSpot).kind == Item.Kind.BULB:
				node.remove_from_group("resource_spots")
				node.queue_free()
	if mode == "meiden":
		get_tree().create_timer(20.0, false).timeout.connect(func() -> void: Game.social.debug_sleep())
	if Game.tracing:
		print("[Birne] Debug: %s (Zimmer %s), %s" % [guest.display_name, guest.home["no"], mode])


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


## --netz=gast1,gast2,gast3[,lob]: Klage (bzw. Lob) von gast1 läuft übers Freundesnetz zu gast2 und weiter zu gast3
## (Spielkonzept 6.18, 1). Alle drei stehen nebeneinander vor dir.
func _debug_net(parts: PackedStringArray) -> void:
	var chain: Array[Guest] = []
	for part in parts:
		if part != "lob":
			var g := Game.social.find_guest(part)
			if g:
				chain.append(g)
	if chain.size() < 3:
		Game.say("--netz: drei Gäste angeben, z. B. --netz=mila,edna,bruno", 3.0)
		return
	var pals := Game.social.pals
	pals.counts[GuestPals.key(chain[0], chain[1])] = GuestPals.PAL_DEEDS
	pals.counts[GuestPals.key(chain[1], chain[2])] = GuestPals.PAL_DEEDS
	var p := Game.player
	var forward := -p.global_transform.basis.z
	var side := forward.cross(Vector3.UP).normalized()
	for i in chain.size():
		var g := chain[i]
		g.global_position = p.global_position + forward * 2.5 + side * (float(i) - 1.0) * 0.9
		g.fear = 0.0
		g._set_idle(60.0)
	var amount := 6.0 if "lob" in parts else -8.0
	if Game.tracing:
		print("[Netz] %s erzählt %s (%.0f): Freunde %s" % [chain[0].display_name, "Lob" if amount > 0.0 else "eine Klage", amount,
			", ".join(PackedStringArray(pals.pals_of(chain[0]).map(func(g: Guest) -> String: return g.display_name)))])
	pals.spread([chain[0]], amount, GuestPals.TELL_CAP if amount > 0.0 else 100.0)
	pals._scan = 0.5
	get_tree().create_timer(20.0, false).timeout.connect(func() -> void:
		if Game.tracing:
			print("[Netz] warten noch auf ein Treffen: %d" % pals.net_pending()))


## --handel=id: Verkaufspreise nach der Abstimmung (Spielkonzept 6.4, ZIM-34) – der Gast steht vor dir, nach 2 s meldet
## jede Regel „[Handel] … ok“ bzw. „FEHLER“.
func _debug_trade(parts: PackedStringArray) -> void:
	var g := Game.social.find_guest(parts[0]) if not parts.is_empty() else null
	if g == null or g.is_child():
		Game.say("--handel: einen erwachsenen Gast angeben, z. B. --handel=edna", 3.0)
		return
	var p := Game.player
	g.global_position = p.global_position - p.global_transform.basis.z * 1.5
	g._set_idle(60.0)
	get_tree().create_timer(2.0, false).timeout.connect(func() -> void:
		var ui := Game.dialog
		ui.open(g)
		var price := func(kind: Item.Kind, extra: String) -> int:
			var item := Item.create(kind, extra)
			var value: int = ui._buy_price(item)
			item.free()
			return value
		var check := func(what: String, ok: bool) -> void:
			print("[Handel] %s: %s" % [what, "ok" if ok else "FEHLER"])
		check.call("Schachbrett gehört dem Hotel", price.call(Item.Kind.CHESS_BOARD, "") == 0)
		check.call("kaputte Birne kauft keiner", price.call(Item.Kind.BULB, "broken") == 0)
		check.call("Laub höchstens 1", price.call(Item.Kind.LEAVES, "") <= 1)
		var candle: int = price.call(Item.Kind.CANDLE, "")
		check.call("Kerze (Füllmaterial) %d, die Hälfte" % candle, candle <= 2)
		var lamp: int = price.call(Item.Kind.FLASHLIGHT, "")
		check.call("Taschenlampe %d" % lamp, lamp >= 3)
		ui.close())


## --glas[=halten]: Getränke der Bar (Spielkonzept 3.7, ZIM-35) – nach 2 s meldet jede Regel „[Glas] … ok“ bzw.
## „FEHLER“; ein Weinfreund und ein Kind stehen dafür vor dir. halten: nur ein Glas Rotwein in die Hand (--savetest).
func _debug_glass(what: String) -> void:
	var p := Game.player
	if what == "halten":
		get_tree().create_timer(1.0, false).timeout.connect(func() -> void:
			p.drop_held()
			p.receive_item(Item.create(Item.Kind.GLASS, "wein")))
		return
	var adults := Game.social.living_guests().filter(func(g: Guest) -> bool: return not g.is_child())
	var fans := adults.filter(func(g: Guest) -> bool: return BarTap.likes_wine(g))
	var kids := Game.social.living_guests().filter(func(g: Guest) -> bool: return g.is_child())
	var check := func(what_: String, ok: bool) -> void:
		print("[Glas] %s: %s" % [what_, "ok" if ok else "FEHLER"])
	if fans.is_empty() or kids.is_empty():
		check.call("Weinfreund und Kind im Hotel", false)
		return
	var fan: Guest = fans[0]
	var kid: Guest = kids[0]
	for g: Guest in [fan, kid]:
		g.global_position = p.global_position - p.global_transform.basis.z * (1.5 if g == fan else 2.2)
		g._set_idle(60.0)
	get_tree().create_timer(2.0, false).timeout.connect(func() -> void:
		var taps := get_tree().get_nodes_in_group("bar_taps")
		check.call("%d Flaschen auf der Theke" % taps.size(), taps.size() == BarTap.ORDER.size()
			and taps.all(func(t: BarTap) -> bool: return t.sort in BarTap.ORDER))
		# Rausch je Sorte: Bier < Rotwein < Schnaps, zwei Schnäpse machen betrunken
		var levels := []
		for sort: String in BarTap.ORDER:
			p.drunk = 0.0
			p.drink(true, sort)
			levels.append(p.drunk)
		check.call("Rausch Bier %.2f < Rotwein %.2f < Schnaps %.2f" % levels, levels[0] < levels[1] and levels[1] < levels[2]
			and levels[2] * 2.0 >= BarTap.DRUNK and levels[0] * 2.0 >= BarTap.TIPSY)
		# Kaufen: mit freien Händen ins Glas in die Hand, Linksklick trinkt es aus
		p.drunk = 0.0
		p.drop_held()
		Game.money = 10
		var wine_tap: BarTap = taps.filter(func(t: BarTap) -> bool: return t.sort == "wein")[0]
		wine_tap.interact(p)
		check.call("Glas Rotwein gekauft (%s, %d Geld übrig)" % [p.held.display_name if p.held else "nichts", Game.money],
			p.held != null and p.held.kind == Item.Kind.GLASS and p.held.flavor == "wein" and Game.money == 8)
		p.drink_glass()
		check.call("ausgetrunken (Rausch %.2f)" % p.drunk, p.held == null and is_equal_approx(p.drunk, BarTap.strength("wein")))
		# Mit vollen Händen trinkt man gleich an der Theke
		p.receive_item(Item.create(Item.Kind.CANDLE))
		var beer_tap: BarTap = taps.filter(func(t: BarTap) -> bool: return t.sort == "bier")[0]
		beer_tap.interact(p)
		check.call("Bier an der Theke getrunken (Rausch %.2f)" % p.drunk,
			is_equal_approx(p.drunk, BarTap.strength("wein") + BarTap.strength("bier")) and Game.money == 7)
		p.drop_held()
		# Rotwein für einen Weinfreund: Lieblingsgeschenk, er trinkt es aus
		var ui := Game.dialog
		ui.open(fan)
		var glass := Item.create(Item.Kind.GLASS, "wein")
		p.receive_item(glass)
		var before := fan.relation
		var drunk_before := fan.drunk
		ui._gift(glass)
		check.call("%s freut sich über Rotwein (%+.1f): %s" % [fan.display_name, fan.relation - before, ui._text.text],
			fan.relation > before and "Rotwein!" in ui._text.text)
		ui.close()
		# Ein Kind nimmt keinen Alkohol – und kauft ihn auch nicht
		ui.open(kid)
		var offer := Item.create(Item.Kind.GLASS, "bier")
		p.receive_item(offer)
		ui._gift(offer)
		check.call("%s lehnt ab: %s" % [kid.display_name, ui._text.text], p.held == offer and "Alkohol" in ui._text.text)
		check.call("Kind kauft kein Glas", ui._buy_price(offer) == 0)
		ui.close()
		p.drop_held()
		# Bitte „ein Glas von der Bar“ in seiner Sorte
		var req: Dictionary = Game.social.requests._small_of(fan, "glass")
		var right := Item.create(Item.Kind.GLASS, "wein")
		var wrong := Item.create(Item.Kind.GLASS, "schnaps")
		check.call("Bitte: %s" % req.get("task", "?"), int(req.get("item", -1)) == Item.Kind.GLASS and req["variety"] == "wein"
			and Game.social.requests._fits(req, right) and not Game.social.requests._fits(req, wrong))
		right.free()
		wrong.free()
		get_tree().create_timer(15.0, false).timeout.connect(func() -> void:   # er hält es 8–14 s (Guest.receive_gift)
			check.call("%s hat das Glas getrunken (Rausch %.2f → %.2f)" % [fan.display_name, drunk_before, fan.drunk],
				fan.drunk > drunk_before and not (is_instance_valid(glass) and glass.is_inside_tree()))))


## --gastspiel[=schocken|armdruecken]: Gäste spielen untereinander (Spielkonzept 6.10, ZIM-73). Zwei Erwachsene
## stehen am zweiten Würfeltisch, du daneben in der Bar; sie setzen sich und spielen kurz (12 s). Danach Prüfungen der
## Herausforderungen: Freund und stolzer Gast fordern mit dem Lieblings-Barspiel, ein anderer nicht, außerhalb der Bar
## keiner. Jede meldet „[Gastspiel] … ok“ bzw. „FEHLER“.
func _debug_pub_game(game: String) -> void:
	if not game in BarMatch.GUEST_GAMES:
		Game.say("--gastspiel: " + ", ".join(BarMatch.GUEST_GAMES), 3.0)
		return
	var social := Game.social
	var bar_game: BarMatch = Game.bar_games[game]
	var table := bar_game.table
	var check := func(what: String, ok: bool) -> void:
		print("[Gastspiel] %s: %s" % [what, "ok" if ok else "FEHLER"])
	var adults: Array = social.living_guests().filter(func(g: Guest) -> bool:
		return not g.is_child() and not g.invited and g.state == Guest.State.IDLE)
	if adults.size() < 2:
		print("[Gastspiel] zu wenige freie Erwachsene")
		return
	var ga: Guest = adults[0]
	var gb: Guest = adults[1]
	for g: Guest in [ga, gb]:
		g.fear = 0.0
		g.global_position = (table.player_seat.global_position if g == ga else table.guest_seat.global_position) 			+ Vector3(0.0, 0.05, 0.9)
		g._set_idle(60.0)
	if game == "schocken" and not bar_game.has_gear(null):
		var cup := Item.create(Item.Kind.DICE_CUP)
		add_child(cup)
		cup.global_position = table.top_center() + Vector3(-0.15, 0.02, 0.0)
	var side := table.global_basis.x.normalized()
	TeleportUI.place_player(table.global_position + side * 3.0, -side)
	social.debug_pub_game = game
	social._pub_timer = 0.0
	get_tree().create_timer(4.0, false).timeout.connect(func() -> void:
		check.call("%s läuft" % BarMatch.GAMES[game], String(social._pub_game.get("game", "")) == game)
		check.call("Tisch belegt", table.busy)
		check.call("beide spielen", ga.state == Guest.State.MINIGAME and gb.state == Guest.State.MINIGAME)
		social.debug_pub_game = "")
	get_tree().create_timer(24.0, false).timeout.connect(func() -> void:
		check.call("Partie vorbei, Tisch frei", social._pub_game.is_empty() and not table.busy)
		check.call("beide wieder frei", ga.state != Guest.State.MINIGAME and gb.state != Guest.State.MINIGAME)
		var in_bar := social.builder.in_area(Game.player.global_position, "bar")
		check.call("Spieler steht in der Bar", in_bar)
		# Herausforderungen zum Lieblings-Barspiel (ohne Chance)
		var fan: Guest = null
		var plain: Guest = null
		var proud: Guest = null
		for g: Guest in social.living_guests():
			if BarMatch.favorite_of(g) == "":
				continue
			var pride := float(g.profile["dice"]["pride"])
			if fan == null:
				fan = g
			elif plain == null and pride <= BarMatch.PROUD:
				plain = g
			elif proud == null and pride > BarMatch.PROUD:
				proud = g
		if fan == null or plain == null or proud == null:
			print("[Gastspiel] keine passenden Gäste für die Herausforderungen")
			return
		var favorite := BarMatch.favorite_of(fan)
		fan.relation = 60.0
		plain.relation = 0.0
		proud.relation = 0.0
		check.call("Freund %s fordert zu %s" % [fan.display_name, BarMatch.GAMES[favorite]],
			social.bar_challenge(fan, true) == favorite)
		check.call("außerhalb der Bar nicht", social.bar_challenge(fan, false) == "")
		check.call("stolzer Gast %s fordert" % proud.display_name, social.bar_challenge(proud, true) == BarMatch.favorite_of(proud))
		check.call("neutraler %s fordert nicht" % plain.display_name, social.bar_challenge(plain, true) == "")
		social.challenge(fan, favorite)
		check.call("Herausforderung steht", fan.challenge_time > 0.0 and fan.challenge_game == favorite))


## --gastsitzen[=art[,id]]: Ein Gast wartet vor dem Sitzmöbel dieser Art, das der Lobby am nächsten ist, und setzt sich
## (ohne Würfeln, Spielkonzept 3.1); nach 4 s Prüfungen im Sitzen, nach 7 s Panik – er steht auf. Jede meldet
## „[Gastsitzen] … ok“ bzw. „FEHLER“. Mit --savetest (nach 6 s) wird sitzend gespeichert.
func _debug_guest_sit(parts: PackedStringArray) -> void:
	var want := parts[0]
	var g := Game.social.find_guest(parts[1] if parts.size() > 1 else "edna")
	var lobby := Game.social.builder.lobby_center
	var seat: Seat = null
	for node in get_tree().get_nodes_in_group("seats"):
		var s := node as Seat
		if s.kind == want and (seat == null or s.global_position.distance_to(lobby) < seat.global_position.distance_to(lobby)):
			seat = s
	if g == null or seat == null or not want in Guest.SIT_KINDS:
		Game.say("--gastsitzen: Art aus %s, Gast als id – z. B. --gastsitzen=stuhl,edna" % ", ".join(Guest.SIT_KINDS), 3.0)
		return
	var spot: Marker3D = seat.spots[0]
	var fwd := -spot.global_basis.z
	var front := spot.global_position + fwd * seat.stand_out
	g.global_position = front + fwd * 0.8
	TeleportUI.place_player(front + fwd * 3.0, -fwd)
	g._set_idle(60.0)
	var check := func(what: String, ok: bool) -> void:
		print("[Gastsitzen] %s: %s" % [what, "ok" if ok else "FEHLER"])
	check.call("%s sucht sich einen Platz (%s)" % [g.display_name, want], g.consider_seat(true))
	get_tree().create_timer(4.0, false).timeout.connect(func() -> void:
		var at: Marker3D = g._sit_spot
		check.call("sitzt", g.is_sitting())
		check.call("Platz für andere besetzt", at != null and not g._sit_seat.is_free(at))
		check.call("Sitzzeit 1–3 Spielminuten (noch %.0f s)" % g._timer, g._timer > 50.0 and g._timer <= Guest.SIT_TIME.y)
		check.call("gespeichert wird stehend vor dem Platz", at != null and g.stand_point().distance_to(at.global_position) > 0.3))
	get_tree().create_timer(7.0, false).timeout.connect(func() -> void:
		g.fear = 80.0)
	get_tree().create_timer(8.5, false).timeout.connect(func() -> void:
		check.call("Panik: steht auf (%s)" % Guest.State.keys()[g.state], not g.is_sitting() and g._sit_spot == null)
		check.call("Kollision wieder an", not g._collider.disabled))


## --budget=id: Beziehung nicht erschleichen (Spielkonzept 6.18, 5) – der Gast steht vor dir, nach 2 s laufen die Regeln
## nacheinander durch und jede meldet „[Budget] … ok“ bzw. „FEHLER“.
func _debug_budget(parts: PackedStringArray) -> void:
	var g := Game.social.find_guest(parts[0]) if not parts.is_empty() else null
	if g == null or g.is_child():
		Game.say("--budget: einen erwachsenen Gast angeben, z. B. --budget=edna", 3.0)
		return
	var p := Game.player
	g.global_position = p.global_position - p.global_transform.basis.z * 1.5
	g._set_idle(60.0)
	get_tree().create_timer(2.0, false).timeout.connect(func() -> void:
		var talk := Game.social.talk
		var ui := Game.dialog
		var check := func(what: String, ok: bool) -> void:
			print("[Budget] %s: %s" % [what, "ok" if ok else "FEHLER"])
		# Gesprächsbereitschaft: neutral 4 Gespräche, das fünfte nicht
		g.relation = 0.0
		g.fear = 0.0
		var opened := 0
		for i in 5:
			var before := g.talks_today if g.talk_day == Calendar.today() else 0
			ui.open(g)
			opened += 1 if g.talks_today > before else 0
			ui.close()
		check.call("neutral redet %d-mal am Tag" % opened, opened == 4)
		# Verärgert: 2 Gespräche, nach drei Antworten bricht er ab
		g.relation = -20.0
		g.talk_day = 0
		ui.open(g)
		for i in Talk.SHORT_TALK + 1:
			ui._show_main()
		check.call("genervt bricht ab", ui._buttons.size() == 1)
		ui.close()
		ui.open(g)
		ui.close()
		check.call("genervt hat nur 2 Gespräche", talk.talks_left(g) == 0)
		# Freunde ohne Grenze
		g.relation = 35.0
		check.call("freundlich ohne Grenze", talk.talks_left(g) == -1)
		# Beziehungsbudget: zwei Gesten voll, die dritte kaum
		g.relation = 0.0
		g.chat_day = 0
		var gains: Array[float] = []
		for i in 3:
			var r := g.relation
			talk.friendly(g, 6.0)
			gains.append(g.relation - r)
		check.call("Budget %.1f / %.1f / %.1f" % gains, gains[2] < gains[1] * 0.3)
		# Geschenke nach Wert
		g.relation = 0.0
		g.deeds.erase("gifts_to")
		g.filler_day = 0
		ui.guest = g
		var leaves_gain: Array[float] = []
		for i in 2:
			var leaves := Item.create(Item.Kind.LEAVES)
			p.receive_item(leaves)
			var r := g.relation
			ui._gift(leaves)
			leaves_gain.append(g.relation - r)
		check.call("Laub +%.1f, dann +%.1f" % leaves_gain, leaves_gain[0] > 0.0 and leaves_gain[0] <= 1.0 and leaves_gain[1] == 0.0)
		check.call("Laub zählt nicht für guter Freund", Game.social.deed(g, "gifts_to") == 0)
		var skull := Item.create(Item.Kind.SKULL)
		p.receive_item(skull)
		ui._gift(skull)
		check.call("Totenkopf zählt für guter Freund", Game.social.deed(g, "gifts_to") == 1)
		var own := Item.create(Item.Kind.SKULL)
		own.got_from = g.id
		p.receive_item(own)
		var r0 := g.relation
		ui._gift(own)
		check.call("bei ihm Gekauftes nimmt er nicht", g.relation == r0 and Game.social.deed(g, "gifts_to") == 1 and (p.held == own or own.in_bag))
		p.give_away(own).queue_free()
		ui.guest = null
		# Beruhigen nach selbst geschürter Angst
		ui.open(g)
		g.chat_day = 0
		ui._monster_talked()
		g.fear = 50.0
		var r1 := g.relation
		ui._calm()
		check.call("geschürt: Beruhigen ohne Beziehung", g.relation == r1)
		g.stoked_at = -INF
		g.fear = 50.0
		ui._calm()
		check.call("sonst mit Beziehung", g.relation > r1)
		ui.close()
		# Vergebung: ein Morgen ohne Tat – aus „stark verfeindet“ heraus
		g.deeds["hostile"] = Social.FEUD_HOSTILE
		g.deeds["revenge"] = Social.FEUD_REVENGE
		g.relation = -90.0
		g.hostile_day = Calendar.today() - 5
		Game.social._forgive_day = Calendar.today() - 1
		Game.social._update_forgiveness()
		check.call("Vergebung: %d Taten, %s" % [Game.social.deed(g, "hostile"), Social.relation_word(g.relation)],
			Game.social.deed(g, "hostile") == Social.FEUD_HOSTILE - 1 and Social.tier(g) == Social.Tier.ENEMY)
		g.hostile_day = Calendar.today()
		Game.social._forgive_day = Calendar.today() - 1
		Game.social._update_forgiveness()
		check.call("frische Tat: keine Vergebung", Game.social.deed(g, "hostile") == Social.FEUD_HOSTILE - 1)
		g.relation = 0.0)


## --kisten: Kisten ohne Nachschub und Startdeko der Kernfiguren (Spielkonzept 5.10, Entscheidung 2026-11-03). Je Kiste
## wird der Monat mit einer frischen Kiste gleicher Größe durchgerechnet: Gäste nehmen, wann immer sie dürfen – leer
## zwischen ResourceSpot.EMPTY_DAY − 1 und + 1; nimmt der Spieler am 1. drei Stück, früher. Dann je Kernfigur 4–5 Stück
## eigene Deko vor der Tür, darunter ein starkes Licht (brennender Kürbis, Totenkopf mit Kerze, Lichterkette).
func _debug_boxes() -> void:
	var check := func(what: String, ok: bool) -> void:
		print("[Kisten] %s: %s" % [what, "ok" if ok else "FEHLER"])
	var sizes := {}
	for node in get_tree().get_nodes_in_group("resource_spots"):
		var spot := node as ResourceSpot
		if spot.runs_out():
			sizes[spot.label + " (%d)" % spot.max_uses] = spot.max_uses
	if sizes.is_empty():
		print("[Kisten] keine Kiste ohne Nachschub im Hotel")
	for label: String in sizes:
		var empty := [0, 0]
		for player_takes in [0, 3]:
			var box := ResourceSpot.new().setup(Item.Kind.BROOM, label, int(sizes[label]), 0.0)
			box.uses -= player_takes
			for day in range(Calendar.FIRST_DAY, Calendar.HALLOWEEN + 1):
				if box.guest_may_take(day):   # wie guest_consume, nur ohne die Uhr
					box.guest_day = day
					box.guest_taken += 1
					box.uses -= 1
				if box.uses <= 0:
					empty[1 if player_takes > 0 else 0] = day
					break
			box.free()
		check.call("%s ohne Spieler leer am %d." % [label, empty[0]], absi(empty[0] - ResourceSpot.EMPTY_DAY) <= 1)
		check.call("%s mit 3 Stück vom Spieler leer am %d." % [label, empty[1]], empty[1] > 0 and empty[1] < empty[0])
	for id in GuestProfiles.ALL:
		var g := Game.social.find_guest(id)
		if g == null:
			continue
		var mine := g.own_deco_near_door()
		var strong := mine.filter(func(i: Item) -> bool:
			return i.lit and i.kind in [Item.Kind.CARVED_PUMPKIN, Item.Kind.SKULL] or i.kind == Item.Kind.LIGHT_STRING)
		check.call("%s: %d Stück Startdeko, starkes Licht %d (%s)" % [g.display_name, mine.size(), strong.size(),
			", ".join(mine.map(func(i: Item) -> String: return i.display_name))], mine.size() >= 4 and mine.size() <= 5 and not strong.is_empty())


## --neid[=id]: Neid der Türnachbarn (Spielkonzept 6.18, 5) – Kisten leer, vier erloschene Kürbisse vor Zimmer 13, die Deko vor der Tür
## des Nachbarn (id oder der erste erwachsene Türnachbar) ist weg. Er steht vor dir; nach 2 s laufen die Regeln durch und
## jede meldet „[Neid] … ok“ bzw. „FEHLER“.
func _debug_envy(parts: PackedStringArray) -> void:
	var social := Game.social
	var dir := Game.director
	var mine: Vector3 = dir.rooms[LevelBuilder.PLAYER_ROOM]["door_front"]
	var g: Guest = null
	for other: Guest in social.living_guests():
		var no := String(other.home.get("no", ""))
		if other.is_child() or no == LevelBuilder.PLAYER_ROOM or not dir.rooms.has(no) \
				or (parts[0] != "" and other != social.find_guest(parts[0])):
			continue
		var front: Vector3 = dir.rooms[no]["door_front"]
		if absf(front.y - mine.y) < 1.0 and front.distance_to(mine) < GuestPals.NEIGHBOR_RANGE:
			g = other
			break
	if g == null:
		print("[Neid] Debug: kein erwachsener Türnachbar von Zimmer 13%s" % ((" namens " + parts[0]) if parts[0] != "" else ""))
		return
	var no := String(g.home["no"])
	var room: Dictionary = dir.rooms[no]
	var front: Vector3 = room["door_front"]
	for node in get_tree().get_nodes_in_group("resource_spots"):
		var spot := node as ResourceSpot
		if spot.runs_out():
			spot.uses = 0
	for node in get_tree().get_nodes_in_group("items"):
		var item := node as Item
		if item.deco_strength > 0.0 and not item.is_held and item.global_position.distance_to(front) < DecoPlan.LOOT_REACH:
			item.queue_free()
	var along: Vector3 = dir.rooms[LevelBuilder.PLAYER_ROOM]["along"]
	for side in [-0.9, -0.5, 0.5, 0.9]:
		var pumpkin := Item.create(Item.Kind.CARVED_PUMPKIN)
		pumpkin.owner_id = "player"
		Game.player.get_parent().add_child(pumpkin)
		pumpkin.global_position = mine + along * side + Vector3.UP * 0.05
		pumpkin.blow_out()   # ohne Schein zählen sie nur an Tür 13 (5.10) – sonst schützt ihr Licht auch den Nachbarn
	var p := Game.player
	g.global_position = p.global_position - p.global_transform.basis.z * 1.5
	g._set_idle(60.0)
	print("[Neid] Debug: %s (Zimmer %s) ist Türnachbar von 13" % [g.display_name, String(room["sign"])])
	get_tree().create_timer(2.0, false).timeout.connect(func() -> void:
		var check := func(what: String, ok: bool) -> void:
			print("[Neid] %s: %s" % [what, "ok" if ok else "FEHLER"])
		# Seine Tür muss schwach sein (früh im Monat ist das Monster zahm): Druck erhöhen, bis sie nicht mehr hält
		for i in 30:
			if social.decorating.plan.weak(no):
				break
			dir.add_boldness(10.0)
		print("[Neid] Abschreckung 13 %.2f, Zimmer %s %.2f, hält nicht: %s, Knappheit: %s" % [dir.deterrence_at(mine), no,
			dir.deterrence_at(front), social.decorating.plan.weak(no), social.decorating.plan.scarce()])
		# Ein Morgen: −2
		g.relation = 0.0
		g.clear_stance("envy")
		social._envy_day = Calendar.today() - 1
		social._update_envy()
		check.call("ein Morgen: %.0f" % g.relation, g.relation == -Social.ENVY_DAILY and g.has_stance("envy"))
		# Zeitsprung über zwei Morgen: −4 (ab dem 2. Spieltag, davor gibt es keine zwei Morgen)
		if Calendar.today() >= 2:
			g.relation = 0.0
			social._envy_day = Calendar.today() - 2
			social._update_envy()
			check.call("zwei Morgen: %.0f" % g.relation, g.relation == -2.0 * Social.ENVY_DAILY)
		# Höchstens bis „wütend“
		g.relation = -29.0
		social._envy_day = Calendar.today() - 1
		social._update_envy()
		check.call("Untergrenze: %.0f (%s)" % [g.relation, Social.relation_word(g.relation)],
			g.relation == Social.ENVY_FLOOR and Social.tier(g) == Social.Tier.ANGRY)
		social._envy_day = Calendar.today() - 1
		social._update_envy()
		check.call("nicht tiefer als wütend", g.relation == Social.ENVY_FLOOR)
		# Befreundete sind nicht neidisch
		g.relation = 60.0
		check.call("Freund nicht neidisch", not g in social.envious_neighbors())
		# Im Gespräch
		g.relation = 0.0
		g.set_stance("envy", Calendar.DAY_SECONDS)
		var line := social.talk.greeting(g)
		check.call("im Gespräch: „%s“" % line, line in Social.ENVY_LINES and not g.has_stance("envy"))
		# Beim Vorbeigehen
		g.set_stance("envy", Calendar.DAY_SECONDS)
		g._set_idle(60.0)
		get_tree().create_timer(3.0, false).timeout.connect(func() -> void:
			check.call("beim Vorbeigehen", not g.has_stance("envy"))))


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


## Stühle zum Ansehen (--stuhl), solange im Speisesaal keiner im Plan steht: zwei an der Tafel, die der Mitte des Saals
## am nächsten ist, zu ihr gewandt, und einer frei im Gang davor, von ihr abgewandt und etwas gedreht – den gibt sie zurück.
func _chair_demo(hall: Rect2) -> Chair:
	var table := Rect2(hall.get_center() - Vector2(1.5, 0.5), Vector2(3.0, 1.0))
	var best := INF
	for f: Dictionary in Game.social.builder._furnishings:
		var r: Rect2 = f["rect"]
		if f["kind"] == "dining_table" and hall.encloses(r) and r.get_center().distance_to(hall.get_center()) < best:
			best = r.get_center().distance_to(hall.get_center())
			table = r
	var free: Chair = null
	for i in 3:
		var ch := Chair.new()
		if i < 2:
			ch.position = Vector3(table.get_center().x + (i - 0.5) * 0.65, 0, table.end.y + 0.15)
			ch.rotation.y = PI   # Sitzseite (+Z) zur Tafel
		else:
			ch.position = Vector3(table.get_center().x + 1.2, 0, table.end.y + 1.5)
			ch.rotation.y = deg_to_rad(25.0)
			free = ch
		add_child(ch)
	return free


## Debug --fotomodus=pruefen: F12 schaltet die freie Kamera ein (eigene Kamera aktuell, Spieler abgeschaltet, Zeit
## steht), sie fliegt nach vorn und durch den Boden nach unten, ohne dass sich der Spieler rührt, [T] lässt die Zeit
## laufen, Esc beendet ohne Spielmenü, F12 beendet mit der Spielerkamera und dem Spieler an alter Stelle, Enter setzt
## ihn unter die Kamera. Je ½ s auseinander, „[Fotomodus] … ok/FEHLER“, zuletzt „[Fotomodus] Prüfung fertig“.
func _debug_photo_check(photo: PhotoMode) -> void:
	var p := Game.player
	var check := func(text: String, ok: bool) -> void:
		print("[Fotomodus] %s: %s" % [text, "ok" if ok else "FEHLER"])
	var press := func(key: Key) -> void:
		for down in [true, false]:
			var event := InputEventKey.new()
			event.physical_keycode = key
			event.pressed = down
			Input.parse_input_event(event)
	var at := {}
	var steps: Array[Callable] = [
		func() -> void:
			at["player"] = p.global_position
			press.call(KEY_F12),
		func() -> void:
			check.call("an", photo.active and get_viewport().get_camera_3d() == photo.camera
				and p.process_mode == Node.PROCESS_MODE_DISABLED and get_tree().paused)
			at["cam"] = photo.camera.global_position
			photo.fly(Vector3(0, 0, -1), 2.0)
			photo.fly(Vector3(0, -1, 0), 1.0),
		func() -> void:
			var moved: Vector3 = photo.camera.global_position - at["cam"]
			check.call("fliegt (vorn %.1f m, unten %.1f m)" % [Vector2(moved.x, moved.z).length(), -moved.y],
				absf(Vector2(moved.x, moved.z).length() - 2.0 * PhotoMode.SPEED) < 0.5
				and absf(moved.y + PhotoMode.SPEED) < 0.01)
			check.call("Spieler steht", p.global_position.distance_to(at["player"]) < 0.01)
			press.call(KEY_T),
		func() -> void:
			check.call("Zeit läuft", photo.time_runs and not get_tree().paused and p.process_mode == Node.PROCESS_MODE_DISABLED)
			press.call(KEY_ESCAPE),
		func() -> void:
			check.call("Esc beendet ohne Menü", not photo.active and not Game.menus.is_open()
				and get_viewport().get_camera_3d() == p.camera and not get_tree().paused)
			press.call(KEY_F12),
		func() -> void:
			photo.fly(Vector3(1, 0, 0), 3.0)
			press.call(KEY_F12),
		func() -> void:
			check.call("F12 beendet", not photo.active and get_viewport().get_camera_3d() == p.camera
				and p.process_mode == Node.PROCESS_MODE_INHERIT and not get_tree().paused)
			check.call("Spieler an alter Stelle", Vector2(p.global_position.x - at["player"].x,
				p.global_position.z - at["player"].z).length() < 0.3)
			press.call(KEY_F12),
		func() -> void:
			photo.fly(Vector3(0, 0, -1), 0.5)
			at["cam"] = photo.camera.global_position
			press.call(KEY_ENTER),
		func() -> void:
			var eye := p.global_position + Vector3(0, Player.EYE_HEIGHT, 0)
			check.call("Enter setzt den Spieler an die Kamera (%.2f m daneben)" % eye.distance_to(at["cam"]),
				not photo.active and eye.distance_to(at["cam"]) < 0.3)
			print("[Fotomodus] Prüfung fertig"),
	]
	for i in steps.size():
		get_tree().create_timer(1.0 + 0.5 * i).timeout.connect(steps[i])


## Debug --buero=pruefen (Spielkonzept 2.8, 2.10, 6.19; ZIM-6): Sekretariat und Büro sind abgeschlossen; ohne Schlüssel
## bleibt die Tür zu; der Sekretariatsschlüssel hängt ab dem 6. am Sicherungskasten und schließt auf; die Schublade mit
## Zahlenschloss bleibt beim falschen Code zu und gibt beim richtigen den Generalschlüssel frei; Marion nennt ab dem 14.
## Josefs Bund; der Bund hängt dann am Kessel und schließt das Büro auf. Je 1 s auseinander, jede Prüfung meldet
## „[Büro] … ok“ bzw. „FEHLER“, zuletzt „[Büro] Prüfung fertig“.
func _debug_office_check() -> bool:
	var office := Game.director_office
	var check := func(text: String, ok: bool) -> void:
		print("[Büro] %s: %s" % [text, "ok" if ok else "FEHLER"])
	var door_of := func(id: String) -> Door:
		for node in get_tree().get_nodes_in_group("doors"):
			if (node as Door).key_id == id:
				return node
		return null
	var key_item := func(id: String) -> Item:
		for node in get_tree().get_nodes_in_group("items"):
			var item := node as Item
			if item.kind == Item.Kind.KEY and item.key_id == id:
				return item
		return null
	var desk: Desk = null
	for node in get_tree().get_nodes_in_group("desks"):
		if (node as Desk).variant == "sekretariat":
			desk = node
	var secretariat: Door = door_of.call(DirectorOffice.SECRETARIAT_KEY)
	var room: Door = door_of.call(DirectorOffice.OFFICE_KEY)
	if secretariat == null or room == null or desk == null:
		print("[Büro] FEHLER: Tür zum Sekretariat, Bürotür oder Sekretariatsschreibtisch fehlt")
		print("[Büro] Prüfung fertig")
		return true
	Game.notebook.give(true)
	var steps: Array[Callable] = [
		func() -> void:
			var front := secretariat.center() - secretariat.global_transform.basis.z * 1.2
			TeleportUI.place_player(Vector3(front.x, secretariat.global_position.y + 0.05, front.z), secretariat.center() - front)
			check.call("Türen abgeschlossen", secretariat.locked and room.locked)
			secretariat.interact(Game.player)
			check.call("ohne Schlüssel zu", secretariat.locked and not Game.player.has_key(DirectorOffice.SECRETARIAT_KEY)),
		func() -> void:
			office.place_due(DirectorOffice.SECRETARIAT_DAY - 1)
			check.call("vor dem 6. kein Schlüssel", key_item.call(DirectorOffice.SECRETARIAT_KEY) == null)
			office.place_due(DirectorOffice.SECRETARIAT_DAY)
			var key: Item = key_item.call(DirectorOffice.SECRETARIAT_KEY)
			check.call("Schlüssel am Sicherungskasten", key != null and key.freeze
				and key.global_position.distance_to(Game.power_cut.fuse_box.global_position) < 1.0)
			office.place_due(DirectorOffice.SECRETARIAT_DAY)
			var count := get_tree().get_nodes_in_group("items").filter(func(n: Node) -> bool:
				return (n as Item).kind == Item.Kind.KEY and (n as Item).key_id == DirectorOffice.SECRETARIAT_KEY).size()
			check.call("nur einmal", count == 1)
			if key:
				key.queue_free()
			Game.player.add_key(DirectorOffice.SECRETARIAT_KEY)
			secretariat.interact(Game.player)
			check.call("Sekretariat aufgeschlossen", not secretariat.locked and room.locked),
		func() -> void:
			var front := desk.global_position + desk.global_basis.z * 1.0
			TeleportUI.place_player(front, desk.global_position - front)
			var i := desk.code_drawer
			check.call("Zahlenschloss zu", i == DirectorOffice.CODE_DRAWER and desk.code_locked(i)
				and desk.drawer_prompt(i, Game.player).begins_with("Zahlenschloss"))
			desk.use_drawer(i, Game.player)
			var ui_open := office.lock_ui.visible
			office.lock_ui.enter("1987")
			check.call("falscher Code", ui_open and office.lock_ui.visible and desk.code_locked(i) and not desk.is_open[i])
			office.lock_ui.enter(DirectorOffice.CODE)
			check.call("richtiger Code", not office.lock_ui.visible and not desk.code_locked(i) and desk.is_open[i]),
		func() -> void:
			var key: Item = key_item.call(RoomAccess.GENERAL_KEY)
			check.call("Generalschlüssel in der Schublade", key != null and key.global_position.distance_to(desk.global_position) < 1.0)
			var marion: Guest = null
			for node in Game.social.living_guests():
				var g: Guest = node
				if not g.is_child() and String(g.profile.get("household", "")) == DirectorOffice.MARION_HOUSEHOLD:
					marion = g
			if marion:
				check.call("Marion vor dem 14. still", office.marion_hint(marion, DirectorOffice.JOSEF_DAY - 1) == "")
				check.call("Marion nennt den Bund", office.marion_hint(marion, DirectorOffice.JOSEF_DAY) == DirectorOffice.MARION_LINE
					and Game.notebook.has_note(DirectorOffice.JOSEF_KEYS))
				check.call("Marion nur einmal", office.marion_hint(marion, DirectorOffice.JOSEF_DAY) == "")
			else:
				print("[Büro] Marion fehlt – Hinweis nicht geprüft"),
		func() -> void:
			office.place_due(DirectorOffice.JOSEF_DAY)
			var bund: Item = key_item.call(DirectorOffice.JOSEF_KEYS)
			var boiler := get_tree().get_first_node_in_group("boilers") as Node3D
			check.call("Josefs Bund am Kessel", bund != null and boiler != null
				and bund.global_position.distance_to(boiler.global_position) < 2.0)
			check.call("Bürotür ohne Bund zu", not Game.player.has_key(DirectorOffice.OFFICE_KEY))
			if bund:
				bund.queue_free()
			Game.player.add_key(DirectorOffice.JOSEF_KEYS)
			room.interact(Game.player)
			check.call("Josefs Bund schließt das Büro auf", not room.locked and Game.player.has_key(DirectorOffice.SECRETARIAT_KEY))
			print("[Büro] Prüfung fertig"),
	]
	for i in steps.size():
		get_tree().create_timer(1.0 + i).timeout.connect(steps[i])
	return true


## Debug --versiegelt[=132|038|042|brief|pruefen] (Spielkonzept 6.19 (7); ZIM-30): vor die Tür eines versiegelten
## Zimmers, vor den Brief im Sekretariat oder die Prüfung (_debug_sealed_check).
func _debug_sealed(what: String) -> bool:
	var sealed := Game.sealed_rooms
	if what == "pruefen":
		return _debug_sealed_check()
	if what == "brief":
		var letter := sealed.letter()
		if letter == null:
			return false
		var desk := letter.get_parent() as Node3D
		var front := desk.global_position + desk.global_basis.z * 0.9
		TeleportUI.place_player(front, letter.global_position - front)
		Game.player.head.rotation.x = deg_to_rad(-40.0)
		return true
	var rooms := Game.social.builder.rooms
	var no := what.pad_zeros(3)
	if not no in SealedRooms.ROOMS or not rooms.has(no):
		return false
	TeleportUI.place_player(rooms[no]["door_front"], rooms[no]["into"])
	return true


## Debug --versiegelt=pruefen: Die drei Türen haben das alte Schloss (Generalschlüssel und Brecheisen helfen nicht), ihre
## Fenstertüren sind verriegelt und gehen von innen auf; Liesel gibt den Schlüssel von 132 erst als Freundin, drinnen liegt
## das Familienfoto, und bringt man es ihr, ist sie danach gute Freundin; der Brief liegt im Sekretariat, erst danach
## gibt das Bild vor 038 den Schlüssel her (ohne Bild im Plan ein Probebild); in 038 das Ölkännchen – eine geölte Tür
## knarrt nicht mehr, das letzte Mal Ölen leert es. Das gefundene Kännchen bleibt in der Hand (für --savetest). Meldet
## „[Versiegelt] … ok“ bzw. „FEHLER“, zuletzt „[Versiegelt] Prüfung fertig“.
func _debug_sealed_check() -> bool:
	var sealed := Game.sealed_rooms
	var builder := Game.social.builder
	var p := Game.player
	var check := func(text: String, ok: bool) -> void:
		print("[Versiegelt] %s: %s" % [text, "ok" if ok else "FEHLER"])
	var item_in := func(kind: Item.Kind, no: String) -> Item:
		for node in get_tree().get_nodes_in_group("items"):
			var item := node as Item
			if item.kind == kind and not item.is_held and builder.home_room_at(item.global_position) == no:
				return item
		return null
	var take := func(item: Item) -> void:   # aufheben, wo es liegt
		item.get_parent().remove_child(item)
		p.receive_item(item)
	var bolts := func(no: String) -> Array:
		return get_tree().get_nodes_in_group("french_doors").filter(func(n: Node) -> bool: return (n as Door).bolt_room == no)
	var liesel: Guest = null
	for g in Game.social.living_guests():
		if SealedRooms.is_liesel(g):
			liesel = g
	if liesel == null or not builder.rooms.has(SealedRooms.TRUST_ROOM) or not builder.rooms.has(SealedRooms.KNOWLEDGE_ROOM):
		print("[Versiegelt] FEHLER: Liesel, Zimmer 132 oder 038 fehlt")
		print("[Versiegelt] Prüfung fertig")
		return true
	var door_132: Door = builder.rooms[SealedRooms.TRUST_ROOM]["door"]
	var door_038: Door = builder.rooms[SealedRooms.KNOWLEDGE_ROOM]["door"]
	Game.notebook.give(true)
	var steps: Array[Callable] = [
		func() -> void:
			check.call("drei Türen mit altem Schloss", SealedRooms.ROOMS.all(func(no: String) -> bool:
				var d: Door = builder.rooms[no]["door"] if builder.rooms.has(no) else null
				return d != null and d.sealed and d.locked and d.key_id == "zimmer_" + no))
			check.call("Fenstertüren verriegelt (042: %d, 132: %d)" % [bolts.call("042").size(), bolts.call("132").size()],
				not bolts.call("042").is_empty() and not bolts.call("132").is_empty()
				and (bolts.call("042") + bolts.call("132")).all(func(d: Door) -> bool: return d.locked and not d.monster_can_open))
			TeleportUI.place_player(builder.rooms["132"]["door_front"], builder.rooms["132"]["into"])
			p.add_key(RoomAccess.GENERAL_KEY)
			door_132.interact(p)
			check.call("Generalschlüssel passt nicht", door_132.locked and not door_132.is_open)
			p.keyring.erase(RoomAccess.GENERAL_KEY)
			p.receive_item(Item.create(Item.Kind.CROWBAR))
			check.call("kein Aufbrechen angeboten", not "Aufbrechen" in door_132.get_prompt(p))
			door_132.interact(p)
			check.call("Brecheisen hilft nicht", door_132.locked and not door_132.broken and not door_132._working)
			p.consume_held(),
		func() -> void:
			liesel.relation = 0.0
			check.call("Liesel gibt ihn nicht als Bekannte", not sealed.would_give(liesel))
			liesel.relation = 60.0
			check.call("Liesel gibt ihn als Freundin", sealed.would_give(liesel))
			sealed.give_key(liesel)
			check.call("Schlüssel 132 am Bund", p.has_key("zimmer_132") and not sealed.would_give(liesel)
				and Item.key_label("zimmer_132") == "Alter Messingschlüssel, Anhänger 132")
			door_132.interact(p)
			check.call("132 aufgeschlossen", not door_132.locked)
			var bolt: Door = bolts.call("132")[0]
			TeleportUI.place_player(builder.rooms["132"]["center"], builder.rooms["132"]["into"])
			bolt.interact(p)
			check.call("Fenstertür geht von innen auf", not bolt.locked),
		func() -> void:
			var photo: Item = item_in.call(Item.Kind.FAMILY_PHOTO, "132")
			check.call("Familienfoto in 132", photo != null)
			if photo == null:
				return
			take.call(photo)
			check.call("Foto in der Hand", p.held == photo)
			Game.dialog.open(liesel)
			Game.dialog.call("_gift", photo)
			print("[Versiegelt] Liesel sagt: %s" % Game.dialog._text.text)
			Game.dialog.close()
			check.call("Liesel hat ihr Foto", p.held == null and photo.is_queued_for_deletion()
				and Game.notebook.has_note("liesels_foto") and Social.tier(liesel) == Social.Tier.GOOD_FRIEND),
		func() -> void:
			var letter := sealed.letter()
			check.call("Brief im Sekretariat", letter != null and (letter.get_parent() as Desk).variant == "sekretariat")
			var pic := sealed.frame()
			if pic == null:
				print("[Versiegelt] kein Bild im Plan vor 038 – Probebild nur für die Prüfung")
				pic = sealed.debug_probe_frame()
			TeleportUI.place_player(builder.rooms["038"]["door_front"], -(builder.rooms["038"]["into"] as Vector3))
			check.call("vor dem Brief kein Schlüssel im Rahmen", not sealed.frame_ready(pic) and pic.get_prompt(p).begins_with("Bild ansehen"))
			sealed.read_letter(false)
			check.call("Brief im Notizbuch", Game.notebook.has_note(SealedRooms.LETTER_NOTE))
			check.call("danach tasten", pic.get_prompt(p) == "Hinter dem Rahmen tasten [E]")
			pic.interact(p)
			check.call("Schlüssel 038 aus dem Rahmen", p.has_key("zimmer_038") and not sealed.frame_ready(pic)),
		func() -> void:
			door_038.interact(p)
			check.call("038 aufgeschlossen", not door_038.locked)
			p.receive_item(Item.create(Item.Kind.OIL_CAN, "1"))
			check.call("Ölen angeboten", door_132.get_prompt(p) == "Bänder ölen [E]")
			door_132.interact(p)
			check.call("letzter Rest geölt, Kännchen leer", door_132.oiled and p.held == null)
			var can: Item = item_in.call(Item.Kind.OIL_CAN, "038")
			check.call("Ölkännchen in 038", can != null)
			if can == null:
				return
			take.call(can)
			door_038.set_open(false, true, true)
			door_038.interact(p)
			check.call("038 geölt, Kännchen noch für %d" % (Item.OIL_DOORS - 1), door_038.oiled and p.held == can
				and can.oil_left == Item.OIL_DOORS - 1 and can.create_extra() == str(Item.OIL_DOORS - 1))
			Game.noise_log.clear()
			door_038.set_open(true, false, false, p)
			check.call("geölte Tür knarrt nicht", not Game.noise_log.any(func(l: String) -> bool: return " Lärm door " in l))
			print("[Versiegelt] Prüfung fertig"),
	]
	for i in steps.size():
		get_tree().create_timer(1.0 + i * 0.6).timeout.connect(steps[i])
	return true


## Debug --schreibmaschine[=vertrag|dienstplan|aushang|lesen|pruefen] (Spielkonzept 2.10, 2.11; ZIM-21, ZIM-119): vor
## die Schreibmaschine im Sekretariat, vor den Direktionsschreibtisch mit offener Mittelschublade (Vertrag), vor den
## Sekretariatsschreibtisch mit offener Hängeregistratur (Dienstplan), vor den Aushang Betriebsferien bzw. das
## Vertragsblatt zum Lesen offen.
func _debug_typewriter(what: String) -> bool:
	var office := Game.director_office
	if what == "pruefen":
		return _debug_typewriter_check()
	if what == "lesen":   # das Vertragsblatt offen: das „e“ sitzt zu hoch, „alle drei Jahre“ von Hand
		get_tree().create_timer(0.5).timeout.connect(office.read_contract)
		return true
	var target: Node3D = office.typewriter
	var drawer := -1
	if what == "vertrag":
		target = _desk_of("direktion")
		drawer = DirectorOffice.CONTRACT_DRAWER
	elif what == "dienstplan":
		target = _desk_of("sekretariat")
		drawer = DirectorOffice.FILES_DRAWER
	elif what == "aushang":
		target = office.leave_notice
	if target == null:
		return false
	if drawer >= 0:
		(target as Desk).use_drawer(drawer, Game.player)
	var front := target.global_basis.z
	var at := target.global_position + front * (0.9 if what == "aushang" else 1.1)
	if what == "aushang":
		at.y = office.leave_door.global_position.y
	TeleportUI.place_player(at, -front)
	Game.player.head.rotation.x = deg_to_rad(0.0 if what == "aushang" else -45.0)
	return true


## Schreibtisch einer Fassung (Desk.variant) – null, wenn der Plan keinen zeigt
func _desk_of(variant: String) -> Desk:
	for node in get_tree().get_nodes_in_group("desks"):
		if (node as Desk).variant == variant:
			return node
	return null


## Debug --schreibmaschine=pruefen: Das „e“ springt im Getippten, nicht in Handschrift und Beschreibung; die Maschine
## steht auf dem Sekretariatstisch; erst Willkommensbrief, dann das Blatt in der Maschine – danach steht die Notiz zur
## springenden Type im Notizbuch; die Aushänge der Lobby und der Aushang Betriebsferien (Wortlaut, Flurseite neben der
## Tür des Hausmeisterraums) sind getippt; Dienstplan bei den Personalakten, Vertrag in der Mittelschublade des Büros,
## lesbar in der Hand. Der Vertrag bleibt in der Hand (für --savetest). Meldet „[Type] … ok“ bzw. „FEHLER“, zuletzt
## „[Type] Prüfung fertig“.
func _debug_typewriter_check() -> bool:
	var office := Game.director_office
	var p := Game.player
	var check := func(text: String, ok: bool) -> void:
		print("[Type] %s: %s" % [text, "ok" if ok else "FEHLER"])
	var secretary := _desk_of("sekretariat")
	var director := _desk_of("direktion")
	Game.notebook.give(true)
	var steps: Array[Callable] = [
		func() -> void:
			var welcome := DoorContest.LETTER_TEXT
			check.call("„e“ springt im Willkommensbrief (%d)" % TypedPage.raised_count(welcome),
				TypedPage.raised_count(welcome) == welcome.count("e") and welcome.count("e") > 0)
			check.call("Handschrift und Beschreibung ohne",
				TypedPage.raised_count("[hand]eee[/hand] [note]ee[/note] e[s]e[/s]") == 2
				and "[s]" in TypedPage.bbcode("[s]x[/s]") and "[lb]" in TypedPage.bbcode("[x]"))
			check.call("Schreibmaschine auf dem Sekretariatstisch", office.typewriter != null and secretary != null
				and office.typewriter.get_parent() == secretary
				and absf(office.typewriter.position.y - Desk.dims("sekretariat").y) < 0.01)
			var board: NoticeBoard = Game.contest.board if Game.contest else null
			var sheets: Array = board.get_children().filter(func(n: Node) -> bool: return n is NoticeBoard.Sheet) if board else []
			check.call("Aushänge der Lobby getippt (%d)" % sheets.size(), not sheets.is_empty()
				and sheets.all(func(n: Node) -> bool: return (n as NoticeBoard.Sheet).doc_id.begins_with("aushang_"))),
		func() -> void:
			var letters := get_tree().get_nodes_in_group("contest_letters")
			if not letters.is_empty():
				letters[0].interact(p)   # wie im Spiel: Brief lesen, DoorContest merkt es sich
			check.call("Leseblatt mit springendem „e“ offen", Game.menus.is_open()
				and Game.menus.find_children("*", "RichTextLabel", true, false).size() > 0)
			Game.menus.close()
			check.call("nach dem Brief allein noch keine Notiz", not Game.notebook.has_note(DirectorOffice.JUMP_NOTE))
			if office.typewriter:
				office.typewriter.interact(p)
				Game.menus.close()
			check.call("Blatt in der Maschine notiert", Game.notebook.has_note(DirectorOffice.MACHINE_DOC))
			check.call("Notiz „Das ‚e‘ springt“", Game.notebook.has_note(DirectorOffice.JUMP_NOTE)),
		func() -> void:
			var notice := office.leave_notice
			check.call("Aushang Betriebsferien hängt", notice != null and notice.text == DirectorOffice.LEAVE_TEXT
				and notice.doc_id == DirectorOffice.LEAVE_DOC)
			if notice == null:
				return
			var door := office.leave_door
			var mid := door.global_position + door.global_basis.x * door.width / 2.0
			var locker := office._caretaker_locker()
			var face := notice.global_basis.z
			var high := notice.global_position.y - door.global_position.y
			check.call("Betriebsferien auf der Flurseite, %.2f m hoch" % high, face.dot(notice.global_position - mid) > 0.05
				and face.dot(locker.global_position - mid) < 0.0 and absf(high - DirectorOffice.LEAVE_HEIGHT) < 0.05)
			notice.interact(p)
			Game.menus.close()
			check.call("Betriebsferien notiert", Game.notebook.has_note(DirectorOffice.LEAVE_DOC)),
		func() -> void:
			var roster: NoticeBoard.Sheet = null
			if secretary:
				for n in secretary.find_children("*", "", true, false):
					if n is NoticeBoard.Sheet and (n as NoticeBoard.Sheet).doc_id == DirectorOffice.ROSTER_DOC:
						roster = n
			check.call("Dienstplan bei den Personalakten", roster != null and "22 Uhr Heizkeller" in roster.text)
			if roster:
				roster.interact(p)
				Game.menus.close()
			check.call("Dienstplan notiert", Game.notebook.has_note(DirectorOffice.ROSTER_DOC))
			check.call("Vertrag fest im Büro", director != null
				and director.fixed.get(DirectorOffice.CONTRACT_DRAWER) == Item.Kind.CONTRACT)
			if director:
				director.use_drawer(DirectorOffice.CONTRACT_DRAWER, p),
		func() -> void:
			var item: Item = null
			for node in get_tree().get_nodes_in_group("items"):
				if (node as Item).kind == Item.Kind.CONTRACT:
					item = node
			check.call("Vertrag in der Mittelschublade", item != null and director != null
				and item.global_position.distance_to(director.global_position) < 1.5)
			if item == null:
				print("[Type] Prüfung fertig")
				return
			check.call("Vertrag „alle drei Jahre“, 1987, unverkäuflich, passt in die Tasche",
				"[s]alljährlich[/s] [hand]alle drei Jahre[/hand]" in DirectorOffice.CONTRACT_TEXT
				and "31. Oktober 1987" in DirectorOffice.CONTRACT_TEXT and item.price() == 0 and item.kind in Item.POCKET_KINDS)
			item.get_parent().remove_child(item)
			p.receive_item(item)
			check.call("Vertrag in der Hand", p.held == item)
			var ev := InputEventAction.new()
			ev.action = "use_item"
			ev.pressed = true
			p._unhandled_input(ev)
			check.call("Vertrag mit Linksklick gelesen", Game.menus.is_open() and Game.notebook.has_note(DirectorOffice.CONTRACT_DOC))
			Game.menus.close()
			print("[Type] Prüfung fertig"),
	]
	for i in steps.size():
		get_tree().create_timer(1.0 + i * 0.8).timeout.connect(steps[i])
	return true


## Debug --kernschutz (Spielkonzept 6.17, 4.33; ZIM-120): Geschützt sind Bruno, Edna, Mila, Marion, Liesel und Oskar,
## nicht Hugo und nicht die übrigen Gäste; Geschützte überleben jeden Angriff (Wounds.survives, der Leviathan packt –
## Kratzer, der Lakengeist würgt im Schlaf – Würgemale) und werden nicht verurteilt. Dann endet der Schutz: Bruno über
## die Marke als Schlüssel (Hauptsicherung, ZIM-4), Mila über die Marke als Notiz (Skizze, ZIM-8), Edna und Marion per
## Debug (Marion zudem nach Halloween) – Marion ist dann verurteilbar. Danach ist alles wie vorher. Meldet
## „[Kernschutz] … ok“ bzw. „FEHLER“, zuletzt „[Kernschutz] Prüfung fertig“.
func _debug_core_protection() -> bool:
	var social := Game.social
	var check := func(text: String, ok: bool) -> void:
		print("[Kernschutz] %s: %s" % [text, "ok" if ok else "FEHLER"])
	var lead := func(household: String) -> Guest:
		for guest in social.guests:
			var g: Guest = guest
			if not g.is_child() and String(g.profile.get("household", "")) == household:
				return g
		return null
	get_tree().create_timer(1.0).timeout.connect(func() -> void:
		CoreRoles.forced_done.clear()
		var core := {"Bruno": social.guest_by_id("bruno"), "Edna": social.guest_by_id("edna"),
			"Mila": social.guest_by_id("mila"), "Marion": lead.call("H22"), "Liesel": lead.call("H26"),
			"Oskar": lead.call("H39")}
		for who: String in core:
			var g: Guest = core[who]
			check.call("%s geschützt" % who, g != null and not g.dead and g.is_protected())
		var hugo: Guest = lead.call(LeviathanName.HUGO)
		check.call("Hugo nicht geschützt (Ersatzweg Liesel)", hugo != null and not hugo.is_protected())
		var others := social.living_guests().filter(func(g: Guest) -> bool:
			return not g.is_child() and CoreRoles.role_of(g) == "")
		check.call("übrige %d Gäste nicht geschützt" % others.size(), not others.is_empty()
			and others.all(func(g: Guest) -> bool: return not g.is_protected()))
		var bruno: Guest = core["Bruno"]
		var marion: Guest = core["Marion"]
		var liesel: Guest = core["Liesel"]
		if bruno == null or marion == null or liesel == null:
			print("[Kernschutz] Prüfung fertig")
			return
		var always := true
		for i in 50:
			always = always and Wounds.survives(bruno)
		check.call("überlebt jeden Angriff (50 ×)", always)
		var d := Game.director
		var left := d.victims_left
		d.skipping = true   # ohne Monster in der Welt: nur Zugriff und Folgen (kill_guest)
		d.victims_left = 1
		d.kill_guest(bruno, null)
		d.skipping = false
		d.victims_left = left
		check.call("Leviathan: Bruno lebt mit Kratzern", not bruno.dead and bruno.wound == "scratch")
		social.hauntings._resolve_asleep(liesel, null, true)
		check.call("Lakengeist im Schlaf: Liesel lebt mit Würgemalen", not liesel.dead and liesel.wound == "choke")
		var room := String(marion.home["no"])
		check.call("Marion nicht verurteilt", d._condemned_in(room) != marion)
		check.call("Marion bis Halloween", not CoreRoles.role_done("marion", Calendar.HALLOWEEN)
			and CoreRoles.role_done("marion", Calendar.HALLOWEEN + 1))
		Game.player.add_key(CoreRoles.MARKS["bruno"])
		check.call("Hauptsicherung beim Spieler: Bruno ungeschützt", not bruno.is_protected())
		Game.player.keyring.erase(CoreRoles.MARKS["bruno"])
		var mila: Guest = core["Mila"]
		var nb := Game.notebook
		var owned := nb.owned
		nb.owned = true
		nb.add_note(CoreRoles.MARKS["mila"], "Mila hat mir ihre Skizze gezeigt.")
		check.call("Skizze gezeigt: Mila ungeschützt", mila != null and not mila.is_protected())
		for i in range(nb.notes.size() - 1, -1, -1):
			if nb.notes[i]["id"] == CoreRoles.MARKS["mila"]:
				nb.notes.remove_at(i)
		nb.owned = owned
		var edna: Guest = core["Edna"]
		CoreRoles.forced_done["edna"] = true
		check.call("Bedrohung vorbei: Edna ungeschützt", edna != null and not edna.is_protected())
		CoreRoles.forced_done["marion"] = true
		var alone := social.living_guests().filter(func(g: Guest) -> bool:
			return String(g.home["no"]) == room and not g.is_child()).size() == 1
		check.call("Rolle erfüllt: Marion verurteilbar", not marion.is_protected()
			and (d._condemned_in(room) == marion or not alone))
		var lost := false
		for i in 200:
			lost = lost or not Wounds.survives(marion)
		check.call("Rolle erfüllt: normales Überleben (200 ×)", lost)
		CoreRoles.forced_done.clear()
		check.call("danach wieder wie vorher", bruno.is_protected() and mila.is_protected() and marion.is_protected())
		print("[Kernschutz] Prüfung fertig"))
	return true


## Bücherregale zum Ansehen (--regale), solange im Plan keins steht: eine Innenecke aus zwei Zeilen mit 5 Ebenen
## (Teilung 1 m und 2 m) und rechts daneben eine freie Zeile mit 4 Ebenen. Gibt die Zeile mit der Ecke links zurück.
func _bookshelf_demo(at: Vector3) -> Bookshelf:
	var a := Bookshelf.make(5, 1, 3.3, true, false)
	var b := Bookshelf.make(5, 2, 4.2, false, true)
	var c := Bookshelf.make(4, 1, 2.6)
	var d := Bookshelf.DEPTH
	var spots := [[a, at, 0.0], [b, at + Vector3(-a.length / 2.0 - d / 2.0, 0, d / 2.0 + b.length / 2.0), PI / 2.0],
		[c, at + Vector3(a.length / 2.0 + 1.2 + c.length / 2.0, 0, 0), 0.0]]
	for i in spots.size():
		var shelf: Bookshelf = spots[i][0]
		shelf.grain = Vector2(1.7 * i, 2.3 * i)
		shelf.position = spots[i][1]
		shelf.rotation.y = spots[i][2]
		add_child(shelf)
	Books.fill(spots.map(func(e: Array) -> Bookshelf: return e[0]))
	return a
