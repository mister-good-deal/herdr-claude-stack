#!/usr/bin/env bash
# Veille de la boîte aux lettres du coordinateur : le recours quand SendMessage ne passe pas (lieutenant sur une autre
# machine, Codex, coordinateur fermé). Attend au plus $1 s, puis affiche toutes les lignes jamais lues. Le pointeur de
# lecture est persistant : une ligne arrivée entre deux veilles n'est jamais perdue.
#   veille-boite.sh [secondes]     BOITE=~/.herdr/mail/coordinateur.md   HOTES="portable" (hôtes ssh, même chemin)
set -uo pipefail
boite=${BOITE:-$HOME/.herdr/mail/coordinateur.md}
hotes=${HOTES:-}
lu() { cat "$boite.lu-$1" 2> /dev/null || echo 0; }
compte() {
    if [ "$1" = local ]; then wc -l < "$boite" 2> /dev/null || echo 0
    else timeout 15 ssh -o BatchMode=yes "$1" "wc -l < '$boite' 2> /dev/null || echo 0" 2> /dev/null; fi
}
lignes() {
    if [ "$1" = local ]; then tail -n +"$2" "$boite"
    else timeout 15 ssh "$1" "tail -n +$2 '$boite'" | sed "s/^/[$1] /"; fi
}
fin=$((SECONDS + ${1:-3500}))
while (( SECONDS < fin )); do
    neuf=()
    for h in local $hotes; do
        c=$(compte "$h"); c=${c:-0}
        (( c > $(lu "$h") )) && neuf+=("$h")
    done
    if (( ${#neuf[@]} )); then
        sleep 20
        for h in "${neuf[@]}"; do
            c=$(compte "$h")
            lignes "$h" $(($(lu "$h") + 1)) | head -n $((c - $(lu "$h")))
            echo "$c" > "$boite.lu-$h"
        done
        exit 0
    fi
    sleep 15
done
echo "veille : rien en ${1:-3500} s"
