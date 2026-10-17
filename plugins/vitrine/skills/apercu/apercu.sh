#!/usr/bin/env bash
# Ouvre l'app web du worktree courant (son serveur de dev, avec fixtures et HMR) dans le navigateur du pane de droite. Un
# serveur par worktree, sur un port tiré de son chemin, démarré au premier appel puis réutilisé.
#   apercu.sh [/chemin?requête]    ouvre (ou rouvre) l'app, par défaut sur /
#   apercu.sh --serve [/chemin]    démarre seulement le serveur et affiche l'URL (agent hors du workspace de l'humain)
#   apercu.sh --stop               arrête le serveur de ce worktree (par son PID)
# Le serveur : APERCU_CMD dans <racine>/.apercu (shell, $PORT y vaut le port ; APERCU_DIR optionnel, relatif à la
# racine). Sans .apercu : le premier dossier (racine, */, */*/) qui a un index.html et node_modules/vite.
set -euo pipefail
root=$(git rev-parse --show-toplevel 2> /dev/null) || { echo "✗ pas dans un dépôt git" >&2; exit 2; }
port=$((5400 + $(printf '%s' "$root" | cksum | cut -d' ' -f1) % 400))
export PORT=$port
run=/tmp/claude-$(id -u)/apercu
mkdir -p "$run"
pidfile=$run/serveur-$port.pid
url=http://127.0.0.1:$port

serve=
if [ "${1:-}" = --serve ]; then serve=1; shift; fi
if [ "${1:-}" = --stop ]; then
    [ -f "$pidfile" ] || { echo "✗ aucun serveur lancé par apercu sur $url : arrête-le par son PID" >&2; exit 1; }
    kill "$(cat "$pidfile")" 2> /dev/null || true
    rm -f "$pidfile"
    for _ in $(seq 1 10); do curl -sf -o /dev/null "$url" || { echo "serveur arrêté ($url)"; exit 0; }; sleep 0.5; done
    echo "✗ $url répond encore : arrête-le par son PID" >&2
    exit 1
fi

APERCU_CMD= APERCU_DIR=.
if [ -f "$root/.apercu" ]; then
    # shellcheck source=/dev/null
    . "$root/.apercu"
else
    for d in "$root" "$root"/*/ "$root"/*/*/; do
        d=${d%/}
        if [ -f "$d/index.html" ] && [ -f "$d/node_modules/vite/bin/vite.js" ]; then
            APERCU_DIR=${d#"$root"}; APERCU_DIR=${APERCU_DIR#/}; APERCU_DIR=${APERCU_DIR:-.}
            APERCU_CMD='node node_modules/vite/bin/vite.js --host 127.0.0.1 --port $PORT --strictPort'
            break
        fi
    done
fi
[ -n "$APERCU_CMD" ] || { echo "✗ aucun serveur trouvé : écris APERCU_CMD dans $root/.apercu" >&2; exit 2; }

if ! curl -sf -o /dev/null "$url"; then
    (cd "$root/$APERCU_DIR" && setsid -f bash -c "$APERCU_CMD" > "$run/serveur-$port.log" 2>&1 < /dev/null)
    for _ in $(seq 1 60); do curl -sf -o /dev/null "$url" && break; sleep 1; done
    curl -sf -o /dev/null "$url" || { echo "✗ le serveur ne répond pas, voir $run/serveur-$port.log" >&2; exit 3; }
    # Le PID qui écoute : `setsid -f` fork et rend la main sans dire le PID du serveur.
    ss -Hltnp "sport = :$port" | grep -o 'pid=[0-9]*' | head -1 | cut -d= -f2 > "$pidfile"
fi
[ -n "$serve" ] || terminal-browser open "$url${1:-/}" --split right > /dev/null
echo "aperçu : $url${1:-/}  (worktree $root, journal $run/serveur-$port.log)"
