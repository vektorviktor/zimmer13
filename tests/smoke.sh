#!/bin/bash
# Rauchtest: spielt Debug-Szenarien headless durch und prüft jeden Lauf auf Skriptfehler, ungültige Positionen (NaN),
# festhängende Gäste, Savetest und Navcheck. Drei Stufen (TECHNIK.md 10):
#   bash tests/smoke.sh schnell    nach jeder Änderung: Szenarien mit Stichwort „schnell“ + Spielstand-Regeln (~½ min)
#   bash tests/smoke.sh schlaf     nach Arbeit an einem System: Szenarien mit diesem Stichwort (oder Wort in den
#                                  Parametern, etwa „pumpkin“) – ohne die Tests danach
#   bash tests/smoke.sh            vor größeren Commits (~13 min): alles, danach die Tests in tests/ (Spielstand-Regeln,
#                                  Rechentests, Schach) und der Titelbildschirm
#   bash tests/smoke.sh stichworte die Stichworte mit Zahl der Szenarien
# Protokolle in temp/smoke/. GODOT = Pfad zu Godot (Standard wie im README), JOBS = Läufe nebeneinander (Standard 6).
# Liste unten: Frames|Stichworte|Parameter. Neue Szenarien bekommen ein oder mehrere Stichworte; „schnell“ nur für
# wenige, die viel auf einmal berühren (die schnelle Stufe soll unter einer Minute bleiben).
# Feste Schrittweite (--fixed-fps 60, --time-scale 3): jedes Bild sind genau 0,05 s Spielzeit, Frames-Angaben unten
# also Spielzeit × 20. Ohne sie holt Godot bei langsamen Bildern bis zu 8 Physikschritte je Bild nach und gerät in eine
# Abwärtsspirale. Absturz (Exit 139) oder Hängen nach der Endmarke „[Ende]“ von Game ist ein bekanntes, offenes
# Problem beim Beenden (TECHNIK.md, Testen) und zählt nicht als Fehler.

cd "$(dirname "$0")/.." || exit 1
GODOT="${GODOT:-/c/Users/vikto/Downloads/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe}"
JOBS="${JOBS:-6}"
FILTER="$1"
if [ "$FILTER" = "stichworte" ]; then
	sed -n "/^done <<'LIST'$/,/^LIST$/p" tests/smoke.sh | sed '1d;$d' | cut -d'|' -f2 | tr ',' '\n' | sort | uniq -c | sort -rn
	exit 0
fi

STUCK_MAX=10   # „kommt nicht weiter“ je Lauf – einzelne Gedränge sind normal, Dutzende nicht
LOGS=temp/smoke
mkdir -p "$LOGS"
rm -f "$LOGS"/*.log "$LOGS"/*.res

# judge <name> <log> <exit> → eine Zeile „ok|known|fail<TAB>Text“
judge() {
	local name="$1" log="$2" code="$3" problems=""
	local errors nan stuck
	errors=$(grep -c "SCRIPT ERROR\|Parse Error" "$log")
	nan=$(grep -c "is_finite" "$log")
	stuck=$(grep -c "kommt nicht weiter" "$log")
	[ "$errors" -gt 0 ] && problems+=" ${errors}× Skriptfehler"
	[ "$nan" -gt 0 ] && problems+=" ${nan}× NaN"
	[ "$stuck" -gt "$STUCK_MAX" ] && problems+=" ${stuck}× kommt nicht weiter"
	if [ "$code" != 0 ] && ! grep -q "^\[Ende\]" "$log"; then
		problems+=" $([ "$code" = 124 ] && echo Zeitüberschreitung || echo "Abbruch im Spiel (Exit $code)")"
	fi
	if grep -q "^\[savetest\] [0-9]" "$log" && ! grep -q "^\[savetest\] [0-9].*alles gleich" "$log"; then
		problems+=" Savetest: $(grep '^\[savetest\] [0-9]' "$log" | sed 's/.*– //')"
	fi
	if grep -q "navcheck\] [0-9]* Orte unerreichbar" "$log"; then
		problems+=" $(grep -o '[0-9]* Orte unerreichbar' "$log")"
	fi
	if [ -n "$problems" ]; then
		printf 'fail\tFEHLER  %s:%s   (%s)\n' "$name" "$problems" "$log"
	elif [ "$code" != 0 ]; then
		printf 'known\tok      %s   (Absturz/Hänger beim Beenden)\n' "$name"
	else
		printf 'ok\tok      %s\n' "$name"
	fi
}

scenario() {   # scenario <nr> <frames> <args>
	local log="$LOGS/$1.log"
	timeout 600 "$GODOT" --headless --path . --fixed-fps 60 --time-scale 3 --quit-after "$2" -- --nointro $3 > "$log" 2>&1
	judge "$3" "$log" $? > "$LOGS/$1.res"
}

count=0
while IFS='|' read -r frames tags args; do
	[ -z "$frames" ] && continue
	if [ -n "$FILTER" ] && [[ ",$tags," != *",$FILTER,"* ]] && [[ "$args" != *"$FILTER"* ]]; then
		continue
	fi
	count=$((count + 1))
	while [ "$(jobs -rp | wc -l)" -ge "$JOBS" ]; do
		wait -n
	done
	scenario "$(printf '%02d' $count)" "$frames" "$args" &
done <<'LIST'
600|schnell,speichern|--savetest
600|speichern,notizbuch|--notizbuch --show=aufgaben --savetest
400|bitten,gaeste,erfolge|--bitte=edna,herz,erfuellen --trace
300|erfolge|--erfolg=chess --erfolg=alle --menu=achievements
400|erfolge|--day=31 --trace
2000|bitten,kuerbis|--bitte=kemal,kuerbis,erfuellen --trace
900|bitten|--bitte=johanna,herz,erfuellen --trace
400|bitten|--bitte=elif,herz,erfuellen --trace
400|bitten,kinder|--bitte=max,herz,erfuellen --trace
600|bitten,speichern,notizbuch|--notizbuch --bitte=simon,herz,annehmen --savetest --trace
600|speichern|--savetest --day=20
600|speichern,spieler|--bag --flashlight --savetest
600|speichern,kuerbis|--day=12 --rot=eingefallen --savetest --trace
1200|kuerbis,deko|--day=26 --rot --decorate=allein --trace
400|spieler,ui|--bag --flashlight --bag-menu=2
3000|navmesh,level|--navcheck
3000|wettbewerb,puppe,monster|--day=12 --siegerehrung --trace
2400|wettbewerb,puppe|--siegerehrung=ohne --trace
2400|grinch,gaeste|--grinch --trace
1200|grinch,wettbewerb,speichern|--grinch=tot --savetest --trace
900|wettbewerb,grinch,speichern|--brett=abgereist --savetest --trace
2400|schnell,monster,gaeste,modi|--warn --day=10 --trace
1500|monster,modi|--pos=31.5,0,-8 --mode=snack --day=8 --trace
1500|monster,modi|--pos=31.5,0,-8 --mode=harmlos --day=5 --trace
3000|monster,modi,gaeste|--mode=anforderung --day=14 --trace
1500|monster,modi|--mode=keller --day=6 --trace
900|monster,modi,speichern|--plan --mode=anforderung,30 --day=12 --savetest --trace
3000|puppe,monster|--doll --trace
2400|puppe,monster|--doll=10,13 --trace
1600|puppe,kinder|--doll=kind --trace
600|masken,speichern|--maske=doll --savetest
900|masken,puppe|--maske=doll --doll=20 --trace
2400|masken,kuerbismann|--maske=pumpkin --pumpkin=jagd --trace
1500|monster,gaeste,tod|--kill=mila --trace
900|gaeste,tod,ui|--console=kill=Emil,leiche,blut,hin;guests --trace
900|gaeste,tod|--kill=emilhartung,weg,blut --trace
1200|monster,kuerbismann,despawn|--warn --pumpkin=ankündigung --console=despawn --trace
900|lakengeist,despawn|--ghost=3 --console=despawn --trace
3000|kuerbismann|--pumpkin=jagd --trace
3000|kuerbismann,gaeste|--pumpkin=jagd,edna --trace
2000|schnell,lakengeist|--ghost=3 --trace
2000|lakengeist,verstecke|--ghost=schrank --trace
2000|lakengeist,deko|--ghost=tür --answer --trace
2000|lakengeist|--pos=34.45,0.1,-13.5 --ghost=4 --trace
1400|lakengeist,nacht|--pos=31.5,0,-8 --ghost=stunde --trace
900|lakengeist,nacht|--pos=31.5,0,-8 --ghost=stunde,4 --trace
700|lakengeist,dusche|--dusche=los --trace
500|lakengeist,dusche|--dusche=fang --trace
900|lakengeist,dusche,schlaf,nacht|--day=3 --uhr=1:10 --hoerer --sleep=bett,8 --dusche=nacht --trace
600|dusche,speichern|--dusche --savetest
900|salz,lakengeist|--trace --salz=fenster --ghost=3
900|salz,lakengeist,gaeste|--trace --salz=gast,edna --shock=edna,ghost3
500|salz,monster|--trace --salz=monster
600|salz,speichern|--salz=tür --savetest
600|tiere|--fledermaus --trace
600|tiere|--fledermaus=schwarm --trace
600|tiere,dachboden|--fledermaus=dachboden --flashlight --trace
600|tiere|--tp=keller --spinne --trace
600|tiere|--spinne=schublade --trace
1500|monster|--lure --trace
3000|deko,gaeste|--decorate=gross,hin --trace
2000|deko,gaeste|--decorate=allein,haus --trace
2400|deko,gaeste|--search=,mit --trace
1500|schnell,feier,gaeste|--party --trace
1000|telefon,ui|--call=edna --answer
1000|katzen|--cat=minka,tragen
2000|kinder,streiche|--trick --trace
600|streiche|--prank=fire --trace
600|streiche,kerzen|--prank=candle --trace
500|kerzen,spieler,licht|--deco=kerze --sprint --bag=streichhoelzer --trace
600|streiche,kuerbis|--prank=pumpkin,111 --trace
600|werfen,kuerbis,speichern|--pos=-6,0,-21,180,-25 --wurf --savetest --trace
600|werfen,speichern|--pos=-6,0,-18,90,0 --wurf=1,kaffee --savetest --trace
600|werfen,monster|--monster=-2,0,-15 --pos=-6,0,-21,180,-25 --wurf=1,dose --trace
600|werfen,gaeste|--tp=edna --wurf=0.5 --trace
600|streiche|--prank=topple --trace
4000|spiele|--dice=bruno --autoplay
3000|spiele,darts|--darts=bruno --autoplay --trace
1200|darts|--darts --autoplay --trace
600|halloween,tiere|--kraehen=groll --trace
600|halloween,tiere,speichern|--kraehen --savetest
600|halloween,tiere|--tp=keller --ratten=welle --trace
400|halloween,tiere|--hund --trace
900|halloween,tiere|--kesselkatze --trace
600|halloween,spuk|--spiegel --trace
600|halloween,spuk,speichern|--spiegel=tuch --savetest
900|halloween,spuk,licht|--strom --trace
600|halloween,spuk,licht,speichern|--strom=kasten --savetest
1500|halloween,spuk,schlaf|--albtraum --trace
600|halloween,spuk|--vogelscheuche --trace
900|halloween,spuk,kinder|--kind-zu-viel --trace
500|halloween,erinnerung|--fotos=1987 --trace
2400|monster,gaeste,leviathan|--leviathan --trace
3600|monster,gaeste,leviathan|--leviathan=liesel --trace
600|monster,leviathan,speichern|--leviathan=benannt --savetest
900|halloween,erinnerung,friedhof|--beerdigen=jetzt --trace
600|halloween,erinnerung,friedhof,speichern|--beerdigen=jetzt --savetest
1500|halloween,erinnerung,friedhof|--trauerfeier --trace
900|halloween,erinnerung|--puppenhaus=urteil --trace
900|halloween,erinnerung,monster|--spieluhr=monster --trace
600|halloween,erinnerung|--fratzen --trace
900|halloween,spiele|--apfel=gesicht --trace
4000|spiele|--chess=mila --autoplay --trace
1500|kueche|--cook=suppe,fertig
2200|kueche,gaeste|--cook=gast --trace
1200|kaffee,kueche|--kaffee=maschine --trace
2400|kaffee,kueche,gaeste|--kaffee=gast --trace
4800|kaffee|--awake=40 --kaffee=3 --trace
1800|kaffee,schlaf|--awake=40 --kaffee=1 --sleep=bett,2 --trace
1200|tee,kueche|--tee=kocher --trace
2000|tee,kueche,gaeste,kinder|--tee=gast --trace
1800|tee,schlaf|--awake=40 --kaffee=1 --tee=1 --sleep=bett,2 --trace
600|tee,speichern|--tee=1 --kaffee=1 --savetest
600|symbole,notizbuch,speichern|--gesehen --show=gesehen --savetest
900|symbole,gaeste|--kill=edna,geist --trace
900|symbole,kuerbis|--kill=bruno,kuerbis --trace
300|symbole,ui|--tot=kuerbis
700|kinder,streiche|--trick=13,3 --trace
1500|level,gaeste|--day=10 --tp=westflügel --trace
1200|kuerbismann,kinder|--pumpkin=ankündigung,20 --trace
2400|spuren|--mess --trace
800|spuren|--mess=wachs --trace
1600|gaeste,beziehungen|--rival=edna,bruno --trace
4000|feier,monster,gaeste|--attacks=10 --party --trace
400|spieler,spuren|--flashlight=uv
600|deko,licht|--deco=lichter,g --pos=55,0.1,-7.9,180,14
600|welt,wetter|--weather=blitz
400|welt|--pool=slosh
400|spuren,monster|--wallblood
1200|licht,gaeste,streiche|--bulb-thief=bruno
1200|licht,gaeste|--lichtgang=bruno --trace
800|gaeste,tod,ui|--wound=edna,axe,hin --talk=edna
1200|gaeste,tod|--shock=mila,corpse --trace
2400|schlaf,nacht|--sleep=bett --trace
1800|schlaf,nacht|--awake=40 --sleep=bett,2 --trace
1500|schnell,schlaf,nacht,monster,puppe|--day=10 --uhr=1:10 --awake=40 --doll=5,13 --hoerer --sleep=bett,8 --trace
1500|schlaf,lakengeist|--awake=72,sicher --pos=50.5,0.1,-7 --trace
900|schlaf,muede|--awake=37 --trace
2400|schlaf,fremdbett,gaeste|--fremdbett=edna,0 --trace
2400|schlaf,fremdbett,gaeste|--fremdbett=bruno,-70 --trace
2400|schlaf,fremdbett,gaeste|--fremdbett=edna,90 --trace
1800|schlaf,fremdbett|--fremdbett=frei,3 --trace
1800|schlaf,tag|--sleep=tag,4 --trace
600|schlaf,speichern|--awake=30 --savetest
600|kuerbis|--pos=45,0.1,-37 --fall=5,giant --trace
600|kuerbis|--pos=45,0.1,-37 --fall=4,mini --trace
900|spuren,wetter,kuerbis|--pos=45,0.1,-37 --fall=5,giant --verwaschen --savetest --trace
400|licht|--fall=3,birne --trace
400|deko,spuren|--fall=2.5,kerze --trace
400|ui|--console=guests;tp keller
400|ui|--menu=pause
400|schnell,ui,gaeste|--talk=edna
400|telefon,ui|--dial=lobby
400|level,dachboden|--attic-door --flashlight
600|dachboden,speichern|--dachboden=kopf --flashlight --savetest
600|dachboden|--dachboden=treppe --trace
600|dachboden,wetter|--dachboden=blitz --trace
400|spieler|--sitzen=bett --trace
600|gaeste,beziehungen|--pals=edna,bruno --trace
2000|spieler|--sprint --trace
600|gespraech,gaeste|--gespraech=frage,night,bruno,2 --trace
600|gespraech,gaeste|--gespraech=frage,brave,edna,1 --trace
600|gespraech,gaeste|--gespraech=erlebnis,ghost,edna,erzaehlen --trace
900|gespraech,gaeste|--gespraech=luege,leiche,edna,mila --trace
900|gespraech,gaeste,beziehungen|--gespraech=luege,dieb,edna,bruno --trace
600|gespraech,speichern|--gespraech=luege,geist,edna --savetest
LIST
wait

# Tests in tests/: voll alle, schnell nur die Spielstand-Regeln
tests=()
if [ -z "$FILTER" ]; then
	tests=("res://tests/run.tscn" "-s res://tests/chess_perft.gd" "-s res://tests/chess_ai_speed.gd")
elif [ "$FILTER" = "schnell" ]; then
	tests=("res://tests/run.tscn")
fi
if [ ${#tests[@]} -gt 0 ]; then
	for test in "${tests[@]}"; do
		count=$((count + 1))
		log="$LOGS/$(printf '%02d' $count).log"
		timeout 600 "$GODOT" --headless --path . $test > "$log" 2>&1
		code=$?
		if grep -q "alles richtig" "$log"; then
			judge "$test" "$log" "$code" > "${log%.log}.res"
		else
			printf 'fail\tFEHLER  %s: %s  (%s)\n' "$test" "$(grep -h 'FALSCH\|FEHLER\|SCRIPT ERROR' "$log" | head -3 | tr '\n' ' ')" "$log" > "${log%.log}.res"
		fi
	done
fi
if [ -z "$FILTER" ]; then
	count=$((count + 1))
	log="$LOGS/$(printf '%02d' $count).log"
	timeout 120 "$GODOT" --headless --path . --quit-after 600 -- --title > "$log" 2>&1
	judge "--title" "$log" $? > "${log%.log}.res"
fi
if [ "$count" = 0 ]; then
	echo "Kein Szenario zu „$FILTER“ – Stichworte: bash tests/smoke.sh stichworte"
	exit 1
fi

cut -f2- "$LOGS"/*.res
failed=$(cut -f1 "$LOGS"/*.res | grep -c "^fail")
known=$(cut -f1 "$LOGS"/*.res | grep -c "^known")
echo
echo "$count Läufe, $failed mit Fehlern, $known mit Absturz oder Hänger beim Beenden (bekannt)"
[ "$failed" = 0 ]
