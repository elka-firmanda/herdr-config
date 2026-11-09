#!/bin/sh
# Copy this device's custom Herdr App config into this repo.
# Shipped layouts/mods/themes, generated files and per-device state stay out.
set -eu
src=${HERDR_APP_HOME:-$HOME/.config/herdr-app}
dst=$(cd "$(dirname "$0")" && pwd)
[ -d "$src" ] || { echo "No Herdr App home at $src" >&2; exit 1; }
[ -f "$src/installed.json" ] || { echo "No installed.json in $src; start Herdr once" >&2; exit 1; }

shipped_mods=$(jq -r 'keys[] | select(startswith("layout:") | not)' "$src/installed.json" | tr '\n' ' ')
shipped_layouts=$(jq -r 'keys[] | select(startswith("layout:")) | sub("^layout:"; "")' "$src/installed.json" | tr '\n' ' ')

mkdir -p "$dst/layouts" "$dst/themes" "$dst/mods"
# The core path is this device's; the install script keeps each device's own.
jq 'del(.core)' "$src/settings.json" > "$dst/settings.json.tmp" && mv "$dst/settings.json.tmp" "$dst/settings.json"
cp "$src/keys.json" "$dst/keys.json"

# Custom layouts (json and preview svg), never Herdr's shipped ones.
for f in "$src"/layouts/*.json "$src"/layouts/*.svg; do
  [ -e "$f" ] || continue
  name=$(basename "$f")
  case " $shipped_layouts " in *" ${name%.*} "*) continue ;; esac
  cp "$f" "$dst/layouts/$name"
done
for f in "$dst"/layouts/*; do
  [ -e "$f" ] || continue
  [ -e "$src/layouts/$(basename "$f")" ] || rm -f "$f"
done

# Custom themes; Herdr ships atom-one-dark and win98.
for f in "$src"/themes/*.json; do
  [ -e "$f" ] || continue
  case $(basename "$f") in atom-one-dark.json|win98.json) continue ;; esac
  cp "$f" "$dst/themes/$(basename "$f")"
done
for f in "$dst"/themes/*; do
  [ -e "$f" ] || continue
  [ -e "$src/themes/$(basename "$f")" ] || rm -f "$f"
done

# Custom mods: every folder installed.json does not know, as real copies (no symlinks).
for m in "$src"/mods/*/; do
  [ -d "$m" ] || continue
  n=$(basename "$m")
  case " $shipped_mods " in *" $n "*) continue ;; esac
  mkdir -p "$dst/mods/$n"
  rsync -a --delete --exclude gpui-kit.d.ts --exclude jsconfig.json --exclude 'check*.cjs' "$m" "$dst/mods/$n/"
done
for d in "$dst"/mods/*/; do
  [ -d "$d" ] || continue
  [ -d "$src/mods/$(basename "$d")" ] || rm -rf "$d"
done

printf 'Synced %s to %s\n' "$src" "$dst"
