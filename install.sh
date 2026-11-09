#!/bin/sh
# Put this repo's Herdr App config into this device's Herdr home.
# Settings and keys are merged, so this device keeps its core path and local-only keys.
set -eu
app=${HERDR_APP_HOME:-$HOME/.config/herdr-app}
repo=$(cd "$(dirname "$0")" && pwd)

for tool in jq rsync; do
  command -v "$tool" >/dev/null || { echo "install needs $tool" >&2; exit 1; }
done
command -v herdr-app >/dev/null || { echo "install needs Herdr App (herdr-app on PATH)" >&2; exit 1; }

mkdir -p "$app/layouts" "$app/themes" "$app/mods"

if [ -f "$app/settings.json" ]; then
  jq -s '.[0] * .[1]' "$app/settings.json" "$repo/settings.json" > "$app/settings.json.tmp"
  mv "$app/settings.json.tmp" "$app/settings.json"
else
  cp "$repo/settings.json" "$app/settings.json"
fi

if [ -f "$app/keys.json" ]; then
  jq -s '.[0] * .[1]' "$app/keys.json" "$repo/keys.json" > "$app/keys.json.tmp"
  mv "$app/keys.json.tmp" "$app/keys.json"
else
  cp "$repo/keys.json" "$app/keys.json"
fi

for f in "$repo"/layouts/*; do
  [ -e "$f" ] || continue
  cp "$f" "$app/layouts/"
done
for f in "$repo"/themes/*; do
  [ -e "$f" ] || continue
  cp "$f" "$app/themes/"
done

fail=0
for m in "$repo"/mods/*/; do
  [ -d "$m" ] || continue
  n=$(basename "$m")
  mkdir -p "$app/mods/$n"
  rsync -a --delete --exclude gpui-kit.d.ts --exclude jsconfig.json --exclude 'check*.cjs' "$m" "$app/mods/$n/"
  if ! herdr-app check "$app/mods/$n" >/dev/null 2>&1; then
    echo "check failed: $n" >&2
    herdr-app check "$app/mods/$n" || true
    fail=1
  fi
done

if [ "$fail" -ne 0 ]; then
  echo "Installed to $app, but some mod checks failed." >&2
  exit 1
fi

echo "Installed to $app; all mod checks passed."
echo "Switch layouts with: herdr-app do layout.switch --name herdr-t3"
