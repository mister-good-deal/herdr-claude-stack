#!/usr/bin/env bash
# Dispose l'onglet herdr de l'appelant pour une situation : son terminal, et à côté des vues (navigateur), des commandes
# ou la sortie d'autres agents. Ne touche qu'à la pane appelante et aux panes que ce script a créées pour elle.
#   disposition.sh lecture [pct] [cible]           terminal à gauche (pct %, défaut 45), une vue à droite
#   disposition.sh comparer [pct] cible cible...   vues côte à côte en haut, terminal en bas (35 %) ; à gauche si large
#   disposition.sh suivi [pct] cible...            terminal à gauche (défaut 40), les cibles empilées à droite
#   disposition.sh colonnes 40 60 [cible...]       découpe la pane appelante en colonnes, la 1re part lui reste
#   disposition.sh lignes 30 70 [cible...]         pareil, en lignes
#   disposition.sh focus                           terminal seul à l'écran (zoom), ou retour à la disposition
#   disposition.sh ranger                          ferme les panes créées par ce script, rien d'autre
# cible : URL, page .html, image ou .pdf → navigateur ; autre fichier → tail -F ; @agent ou @w2:p1 → sa sortie
# rafraîchie ; sinon une commande shell.
set -euo pipefail
ETROIT=160 LARGE=400 MIN=80
usage() { sed -n '4,12p' "$0" >&2; exit 2; }
die() { echo "✗ $1" >&2; exit 3; }
[ "${HERDR_ENV:-}" = 1 ] || die "pas dans une pane herdr"
[ $# -ge 1 ] || usage

read -r caller tab < <(herdr pane current --current | jq -r '.result.pane | "\(.pane_id) \(.tab_id)"')
W=$(herdr pane layout --pane "$caller" | jq -r .result.layout.area.width)
etat=/tmp/claude-$(id -u)/disposition/$caller
mkdir -p "${etat%/*}"
touch "$etat"

indice() { echo "Pour plus de place : console en plein écran (Super+↑), puis relance."; }
ratio() { jq -n "$1 / $2"; }
uns() { yes 1 | head -n "$1"; }
est_page() {
    case $1 in *.html | *.htm | *.png | *.jpg | *.jpeg | *.gif | *.svg | *.webp | *.pdf) return 0 ;; esac
    false
}
largeur() {
    herdr pane layout --pane "$caller" | jq -r --arg p "$1" '.result.layout.panes[] | select(.pane_id == $p).rect.width'
}

# Ferme les panes notées dans l'état (même onglet, même terminal : un id ne désigne plus la même pane après un
# redémarrage du serveur), sauf celle passée en argument.
ranger() {
    local id term vu garde=${1:-} reste=
    while read -r id term; do
        if [ "$id" = "$garde" ]; then reste+="$id $term"$'\n'; continue; fi
        vu=$(herdr pane get "$id" 2> /dev/null | jq -r '.result.pane | "\(.tab_id) \(.terminal_id)"') || true
        [ "$vu" != "$tab $term" ] || herdr pane close "$id" > /dev/null
    done < "$etat"
    printf '%s' "$reste" > "$etat"
}

nouvelle() {
    local j
    j=$(herdr pane split "$1" --direction "$2" --ratio "$3" --cwd "$PWD" --no-focus)
    jq -r '.result.pane | "\(.pane_id) \(.terminal_id)"' <<< "$j" >> "$etat"
    jq -r .result.pane.pane_id <<< "$j"
}

# diviser <pane> <right|down> <part>... : parts proportionnelles, la première reste à la pane ; affiche les créées.
diviser() {
    local p=$1 dir=$2 reste=0 x
    shift 2
    for x in "$@"; do reste=$((reste + x)); done
    while [ $# -gt 1 ]; do
        p=$(nouvelle "$p" "$dir" "$(ratio "$1" "$reste")")
        reste=$((reste - $1))
        shift
        echo "$p"
    done
}

remplir() {
    local cmd
    case $2 in
        @w*:p*) cmd="watch -t -w -n 5 'herdr pane read ${2#@} --source recent-unwrapped --lines \$LINES'" ;;
        @*) cmd="watch -t -w -n 5 'herdr agent read ${2#@} --source recent-unwrapped --lines \$LINES'" ;;
        *://* | about:* | localhost:* | 127.0.0.1:*) cmd="terminal-browser open $(printf %q "$2") --no-merge" ;;
        *) if est_page "$2"; then cmd="terminal-browser open $(printf %q "$(realpath "$2")") --no-merge"
           elif [ -f "$2" ]; then cmd="tail -F $(printf %q "$2")"
           else cmd=$2; fi ;;
    esac
    herdr pane run "$1" "$cmd" > /dev/null
}

# grille <zone> <colonnes> <cible>... : les cibles en lignes de <colonnes> cellules dans la zone.
grille() {
    local zone=$1 c=$2 r k i=0 cells=() rangs=("$1")
    shift 2
    mapfile -t -O 1 rangs < <(diviser "$zone" down $(uns $((($# + c - 1) / c))))
    for r in "${rangs[@]}"; do
        k=$(($# - ${#cells[@]}))
        [ "$k" -le "$c" ] || k=$c
        cells+=("$r")
        mapfile -t -O "${#cells[@]}" cells < <(diviser "$r" right $(uns "$k"))
    done
    for r in "$@"; do remplir "${cells[$i]}" "$r"; i=$((i + 1)); done
    echo "${cells[*]}"
}

colonnes_pour() {
    local c=$(($(largeur "$1") / MIN))
    [ "$c" -ge 1 ] || c=1
    [ "$c" -le "$2" ] || c=$2
    echo "$c"
}

# Règle à pct % la part de l'appelant dans la division qui le sépare de son voisin <right|down>.
ajuster() {
    local sens
    sens=$(herdr pane layout --pane "$caller" | jq -r --arg p "$caller" --arg d "$1" --argjson t "$2" '
        .result.layout as $l | ($l.panes[] | select(.pane_id == $p).rect) as $c
        | (if $d == "right" then ["x", "width", "y", "height", "left"] else ["y", "height", "x", "width", "up"] end)
            as [$a, $la, $b, $lb, $moins]
        | [$l.splits[] | select(.direction == $d and .rect[$b] <= $c[$b] and $c[$b] < .rect[$b] + .rect[$lb]
            and ((.rect[$a] + .rect[$la] * .ratio) - ($c[$a] + $c[$la]) | fabs) <= 1)] | last | select(. != null)
        | ($t / 100 - .ratio) as $x | if $x >= 0 then "\($d) \($x)" else "\($moins) \(-$x)" end')
    [ -z "$sens" ] || herdr pane resize --pane "$caller" --direction "${sens% *}" --amount "${sens#* }" > /dev/null
}

lecture() {
    local pct=45 dir=right nav voisin v
    if [[ ${1:-} =~ ^[0-9]+$ ]]; then pct=$1; shift; fi
    [ "$W" -ge "$ETROIT" ] || { dir=down; indice; }
    mapfile -t nav < <(terminal-browser ls --all --json 2> /dev/null \
        | jq -r --arg t "$tab" '.browsers[] | select(.pane.tab == $t) | "\(.pane.pane) \(.key)"')
    voisin=$(herdr pane neighbor --pane "$caller" --direction "$dir" 2> /dev/null \
        | jq -r '.result.neighbor.neighbor_pane_id // empty')
    if [ ${#nav[@]} = 1 ] && [ -n "$voisin" ] && [ "${nav[0]% *}" = "$voisin" ]; then
        ranger "$voisin"
        ajuster "$dir" "$pct"
        if [ -f "${1:-}" ]; then set -- "$(realpath "$1")"; fi
        [ -z "${1:-}" ] || terminal-browser new-tab --browser "${nav[0]#* }" "$1" > /dev/null
        echo "lecture : terminal $pct %, vue $voisin (navigateur déjà là)"
    else
        ranger
        v=$(nouvelle "$caller" "$dir" "$(ratio "$pct" 100)")
        remplir "$v" "${1:-about:blank}"
        echo "lecture : terminal $pct %, vue $v"
    fi
}

comparer() {
    local pct= zone c
    if [[ ${1:-} =~ ^[0-9]+$ ]]; then pct=$1; shift; fi
    [ $# -ge 2 ] || usage
    ranger
    if [ "$W" -ge "$LARGE" ]; then
        zone=$(nouvelle "$caller" right "$(ratio "${pct:-25}" 100)")
    else
        zone=$(nouvelle "$caller" down "$(ratio $((100 - ${pct:-35})) 100)")
        herdr pane swap --source-pane "$caller" --target-pane "$zone" > /dev/null
    fi
    c=$(colonnes_pour "$zone" $#)
    [ "$c" -ge $# ] || indice
    printf "comparer : "; grille "$zone" "$c" "$@"
}

suivi() {
    local pct=40 dir=right zone c=1
    if [[ ${1:-} =~ ^[0-9]+$ ]]; then pct=$1; shift; fi
    [ $# -ge 1 ] || usage
    ranger
    [ "$W" -ge "$ETROIT" ] || { dir=down; indice; }
    zone=$(nouvelle "$caller" "$dir" "$(ratio "$pct" 100)")
    [ "$W" -lt "$LARGE" ] || c=$(colonnes_pour "$zone" $#)
    printf "suivi : "; grille "$zone" "$c" "$@"
}

decouper() {
    local dir=$1 parts=() panes=() i=0 s
    shift
    while [[ ${1:-} =~ ^[0-9]+$ ]]; do parts+=("$1"); shift; done
    [ ${#parts[@]} -ge 2 ] || usage
    ranger
    mapfile -t panes < <(diviser "$caller" "$dir" "${parts[@]}")
    for s in "$@"; do [ $i -lt ${#panes[@]} ] && remplir "${panes[$i]}" "$s"; i=$((i + 1)); done
    echo "découpe : ${panes[*]}"
}

action=$1
shift
for a in "$@"; do
    case $a in *://* | @*) ;; *) ! est_page "$a" || [ -f "$a" ] || die "introuvable : $a" ;; esac
done
case $action in
    lecture | comparer | suivi) "$action" "$@" ;;
    colonnes) decouper right "$@" ;;
    lignes) decouper down "$@" ;;
    focus) herdr pane zoom "$caller" --toggle | jq -r '"focus : " + if .result.zoom.zoomed then "terminal seul"
        else "disposition rendue" end' ;;
    ranger) ranger; echo "rangé : les panes de la disposition sont fermées" ;;
    *) usage ;;
esac
