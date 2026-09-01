# systemd user units

Linked one by one into `~/.config/systemd/user/` by `install.sh` (also
`install.sh --link`). They are started by the Hyprland autostart
(`hypr/hyprland/execs.lua`) after it imports the session environment into the
user manager; nothing is enabled at boot.

| Unit | Runs | Notes |
|---|---|---|
| `desktop-shell.service` | `qs -c desktop` | the desktop shell; `Restart=on-failure`, logs in `journalctl --user -u desktop-shell` |
| `joystick-idle-watch.service` | `~/.local/bin/joystick-idle-watch` | keeps the session awake while a controller is used |
| `hypridle.service` | packaged unit from `hypridle` | idle lock / DPMS; not shipped here |

Adding a unit: drop the file here, re-run `install.sh --link`, add it to the
`systemctl --user restart ...` line in `execs.lua` if it should start with
the session.
