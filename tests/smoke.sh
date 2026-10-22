#!/bin/bash
# Rauchtest: spielt die Debug-Szenarien headless durch und prüft jeden Lauf auf Skriptfehler, ungültige Positionen
# (NaN), festhängende Gäste, Savetest und Navcheck; danach die Tests in tests/ (Spielstand-Regeln, Rechentests,
# Schach). ~25 min mit 3 Läufen nebeneinander, Protokolle in temp/smoke/.
#   bash tests/smoke.sh            alles
#   bash tests/smoke.sh pumpkin    nur Szenarien, deren Parameter „pumpkin“ enthalten (ohne die Tests danach)
# GODOT = Pfad zu Godot (Standard wie im README), JOBS = Läufe nebeneinander (Standard 3).
# Feste Schrittweite (--fixed-fps 60, --time-scale 3): jedes Bild sind genau 0,05 s Spielzeit, Frames-Angaben unten
# also Spielzeit × 20. Ohne sie holt Godot bei langsamen Bildern bis zu 8 Physikschritte je Bild nach und gerät in eine
# Abwärtsspirale. Absturz (Exit 139) oder Hängen nach der Endmarke „[Ende]“ von Game ist ein bekanntes, offenes
# Problem beim Beenden (TECHNIK.md, Testen) und zählt nicht als Fehler.

cd "$(dirname "$0")/.." || exit 1
GODOT="${GODOT:-/c/Users/vikto/Downloads/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe}"
JOBS="${JOBS:-3}"
FILTER="$1"
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
while IFS='|' read -r frames args; do
	[ -z "$frames" ] && continue
	[ -n "$FILTER" ] && [[ "$args" != *"$FILTER"* ]] && continue
	count=$((count + 1))
	while [ "$(jobs -rp | wc -l)" -ge "$JOBS" ]; do
		wait -n
	done
	scenario "$(printf '%02d' $count)" "$frames" "$args" &
done <<'LIST'
600|--savetest
600|--savetest --day=20
3000|--navcheck
3000|--day=12 --first-attack --trace
2400|--warn --intent=one --day=10 --trace
1500|--kill=mila --trace
3000|--pumpkin=jagd --trace
3000|--pumpkin=jagd,edna --trace
2000|--ghost=3 --trace
2000|--ghost=schrank --trace
2000|--ghost=tür --answer --trace
2000|--pos=34.45,0.1,-13.5 --ghost=4 --trace
1500|--lure --trace
3000|--decorate=gross,hin --trace
2000|--decorate=allein,haus --trace
2400|--search=,mit --trace
1500|--party --trace
1000|--call=edna --answer
1000|--cat=minka,tragen
2000|--trick --trace
4000|--dice=bruno --autoplay
4000|--chess=mila --autoplay --trace
1500|--cook=suppe,fertig
400|--flashlight=uv
600|--deco=lichter,g --pos=55,0.1,-7.9,180,14
600|--weather=blitz
400|--pool=slosh
400|--wallblood
1200|--bulb-thief=bruno
800|--wound=edna,axe,hin --talk=edna
1200|--shock=mila,corpse --trace
2400|--sleep=bett --trace
1500|--awake=3 --pos=40,0.1,0 --trace
400|--console=guests;tp keller
400|--menu=pause
400|--talk=edna
400|--dial=lobby
600|--pals=edna,bruno --trace
600|--weep=edna --look=edna
2000|--sprint --trace
LIST
wait

if [ -z "$FILTER" ]; then
	for test in "res://tests/run.tscn" "-s res://tests/chess_perft.gd" "-s res://tests/chess_ai_speed.gd"; do
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
	count=$((count + 1))
	log="$LOGS/$(printf '%02d' $count).log"
	timeout 120 "$GODOT" --headless --path . --quit-after 600 -- --title > "$log" 2>&1
	judge "--title" "$log" $? > "${log%.log}.res"
fi

cut -f2- "$LOGS"/*.res
failed=$(cut -f1 "$LOGS"/*.res | grep -c "^fail")
known=$(cut -f1 "$LOGS"/*.res | grep -c "^known")
echo
echo "$count Läufe, $failed mit Fehlern, $known mit Absturz oder Hänger beim Beenden (bekannt)"
[ "$failed" = 0 ]
