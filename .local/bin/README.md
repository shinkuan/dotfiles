# .local/bin

User-level executables, copied to `~/.local/bin` by `install.sh`.
Every script here must derive paths from the XDG base dirs
(`XDG_CONFIG_HOME` / `XDG_STATE_HOME` / `XDG_CACHE_HOME`, each with its spec
fallback) — never hardwire `$HOME/.config` or an absolute home path.

## scheme

Colour scheme generator (Material You via `materialyoucolor` +
`python-pillow`). Generates the full palette (M3 roles, `term0`–`term15`,
catppuccin-style aliases, KDE semantic colours, overlays, success roles) and
renders every consumer template:

| Output | Consumer |
|---|---|
| `$XDG_STATE_HOME/scheme/colours.json` | desktop shell (FileView hot reload) |
| `$XDG_CONFIG_HOME/hypr/scheme/current.lua` | hypr Lua config (border colours) |
| `$XDG_CONFIG_HOME/hypr/scheme/current.conf` | hyprlock |
| `$XDG_CONFIG_HOME/qt6ct/colors/scheme.colors` | Qt apps via qt6ct |
| `$XDG_CONFIG_HOME/gtk-{3.0,4.0}/gtk.css` | GTK apps |
| `$XDG_CACHE_HOME/scheme/foot.ini`, `sequences.txt` | terminals (see below) |

Usage: `scheme set [--name N] [--flavour F] [--mode dark|light]
[--variant V] [--random]`, `scheme sync`, `scheme get`, `scheme list`.
Defaults: `dynamic / default / dark / content`.

The terminal palette source is a switch in
`$XDG_CONFIG_HOME/scheme/config.json` (`{"terminal": {"source": ...}}`):
`hellwal` (default — `wallpaper` invokes hellwal, which overwrites the two
cache files above) or `m3` (rendered by `scheme` from `term0`–`term15`).

**Adding a preset scheme**: extend `PRESETS` in the script with palette
values taken from the scheme's upstream project (a seed `source` colour per
flavour, plus optional literal `terms` / `aliases` lists).

**Regression test**: `dev/verify-scheme.sh` must PASS (120/120 colours
identical to `dev/fixtures/scheme-baseline.json`) after any change to the
generation pipeline.

## wallpaper

Wallpaper switcher + theming pipeline: records
`$XDG_STATE_HOME/wallpaper/{path.txt,current,thumbnail.jpg}`, runs
`scheme sync`, generates the terminal palette (hellwal by default), reloads
Hyprland, and notifies the desktop shell. `wallpaper -f <image>`,
`wallpaper -r [dir]` (random), `wallpaper -g` (print current).

Note: hellwal is invoked here on purpose — it used to run from a
caelestia-cli hook, and without this call terminal colours silently stop
following the wallpaper.

## Others

- `clone_private` — clone a public repo into a new private one via `gh`.
- `compress_video` — ffmpeg wrapper for quick video compression.
