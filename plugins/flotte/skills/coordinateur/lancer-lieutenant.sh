#!/usr/bin/env bash
# Lance un lieutenant herdr : worktree + workspace, session Claude Code, lettre de mission comme premier prompt.
#   lancer-lieutenant.sh <nom> <dépôt> <branche> <base> <fichier-de-mission> [--machine <profil herdr>]
# <nom> : lt-<sujet>. <base> : la référence de départ, ex. origin/main ou origin/release/1.2.0.
# Modèle : LT_MODEL (claude-opus-5-5), LT_EFFORT (medium), LT_AUTOCOMPACT (150000).
set -euo pipefail
[ $# -ge 5 ] || { sed -n '3,5p' "$0" >&2; exit 2; }
nom=$1 depot=$2 branche=$3 base=$4 mission=$5
shift 5
h=(herdr)
if [ "${1:-}" = --machine ]; then h=(herdr --machine "$2"); fi
[[ $nom =~ ^[a-z][a-z0-9_-]{0,31}$ ]] || { echo "✗ nom herdr invalide : $nom" >&2; exit 2; }
[ -f "$mission" ] || { echo "✗ mission introuvable : $mission" >&2; exit 2; }

"${h[@]}" agent list | jq -e --arg n "$nom" '.result.agents[] | select(.name == $n)' > /dev/null \
    && { echo "✗ $nom tourne déjà" >&2; exit 3; }
ws=$("${h[@]}" worktree create --cwd "$depot" --branch "$branche" --base "$base" --label "$nom" --no-focus \
    | jq -r '.result.workspace.workspace_id')
[ -n "$ws" ] && [ "$ws" != null ] || { echo "✗ worktree non créé" >&2; exit 4; }
"${h[@]}" agent start "$nom" --kind claude --pane "$ws:p1" --timeout 180000 -- \
    --model "${LT_MODEL:-claude-opus-5-5}" --effort "${LT_EFFORT:-medium}" --autocompact "${LT_AUTOCOMPACT:-150000}" \
    > /dev/null
"${h[@]}" agent prompt "$nom" "$(cat "$mission")" > /dev/null
echo "lancé : $nom (workspace $ws, pane $ws:p1, branche $branche sur $base)"
