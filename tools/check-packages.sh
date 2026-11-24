#!/usr/bin/env bash
set -uo pipefail

# [OUT-01]
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
missing=0
total=0
apt-get update -qq >/dev/null 2>&1 || true
for list in "$ROOT"/packages/*.list; do
    name="$(basename "$list")"
    while read -r pkg _; do
        [[ -z "$pkg" || "$pkg" == \#* ]] && continue
        total=$((total + 1))
        if ! apt-cache show "$pkg" >/dev/null 2>&1; then
            printf '%s : %s introuvable\n' "$name" "$pkg"
            missing=$((missing + 1))
        fi
    done <"$list"
done
printf '%d paquets vérifiés, %d introuvable(s) sur %s\n' "$total" "$missing" \
    "$(sed -n 's/^PRETTY_NAME=//p' /etc/os-release | tr -d '"')"
((missing == 0))
