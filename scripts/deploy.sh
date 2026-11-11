#!/usr/bin/env bash
# Copie l'addon dans le dossier AddOns de WoW Forever, puis /reload en jeu.
# Dossier cible modifiable : WOW_ADDONS=/mnt/c/.../AddOns scripts/deploy.sh
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
target="${WOW_ADDONS:-/mnt/d/World of Warcraft/_forever_/Interface/AddOns}"
name="GnomeraganIndependant"

if [ ! -d "$target" ]; then
	echo "Dossier AddOns introuvable : $target (définir WOW_ADDONS)" >&2
	exit 1
fi

rsync -a --delete --exclude '*.md' --exclude '.*' "$root/$name/" "$target/$name/"
echo "Déployé dans $target/$name — tapez /reload en jeu."
