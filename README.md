# Herdr config

My Herdr App config, shared between devices through Git.

## What syncs

- `settings.json` (without `core`, which is per-device)
- `keys.json`
- custom layouts: `herdr-t3`, `main-timer` (and the T3 preview)
- custom mods: `t3-*`, `tabs-timer`
- custom theme: `alacritty`

## What does not sync

Herdr's shipped layouts, mods and themes; generated files (`AGENTS.md`, `*.d.ts`, `frame/`, `icons/`); and per-device state (`installed.json`, `view.json`, `shared.json`, `data/`, `seen.json`, `layouts/.state/`, window files). Herdr rewrites those, and they don't belong on another machine.

## Capture this device

```sh
~/herdr-config/sync.sh
cd ~/herdr-config
git add -A
git commit -m "Update Herdr config"
git push
```

`sync.sh` reads `~/.config/herdr-app` (or `$HERDR_APP_HOME`), copies only the custom parts, and strips the device-specific `core` path from `settings.json`.

## Set up another device

```sh
git clone git@github.com:<you>/herdr-config.git ~/herdr-config
~/herdr-config/install.sh
herdr-app do layout.switch --name herdr-t3
```

`install.sh` needs `jq`, `rsync`, and Herdr App. It merges `settings.json` and `keys.json` with the device's own files, so that device keeps its `core` path and any local-only keys; it copies the layouts, theme and mods, and runs `herdr-app check` on each mod.

## Update another device

```sh
cd ~/herdr-config && git pull && ./install.sh
```

## Notes

- Mods are copied, not symlinked: Herdr does not load a mod's SVGs through a symlink.
- Fonts are not synced. The config uses Maple Mono; install it on the other device, or change `font` in `settings.json`.
- `keys.json` is synced whole. Herdr treats an edited keys file as yours, so shortcuts added by a future Herdr release must be added by hand.
- `settings.json` in this repo never contains `core`. If a device needs a custom core path, its own `settings.json` value is kept by `install.sh`; otherwise Herdr finds `herdr-core` in `~/.local/bin` and the usual places.
