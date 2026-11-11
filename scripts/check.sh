#!/usr/bin/env bash
# Vérifications avant commit : analyse statique et formatage.
set -euo pipefail
cd "$(dirname "$0")/.."

luacheck GnomeraganIndependant
stylua --check GnomeraganIndependant
echo "OK"
