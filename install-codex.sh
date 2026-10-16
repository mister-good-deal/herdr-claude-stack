#!/usr/bin/env bash
# Lie les skills de ce dépôt dans ~/.codex/skills/ (Codex ne lit pas les plugins Claude Code). Relancer après un pull
# n'est pas nécessaire : ce sont des liens.
set -euo pipefail
ici=$(cd "$(dirname "$0")" && pwd)
mkdir -p ~/.codex/skills
for s in "$ici"/plugins/*/skills/*/; do
    nom=$(basename "$s")
    ln -sfn "${s%/}" ~/.codex/skills/"$nom"
    echo "lié : ~/.codex/skills/$nom → ${s%/}"
done
