#!/usr/bin/env bash
# Vérifications avant commit : analyse statique, formatage, test de fumée hors jeu.
set -euo pipefail
cd "$(dirname "$0")/.."

luacheck -q GnomeraganIndependant tests
stylua --check GnomeraganIndependant tests
lua5.1 tests/smoke.lua >/dev/null
echo "OK"
