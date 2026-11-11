# Maprisma Bar

A top bar for Hyprland in [Quickshell](https://quickshell.org), made for the
Caelestia session and behaving like Omarchy's bar:

- **Double-click empty bar space** to cycle the background: clear → glassy → opaque.
  Glassy is see-through with Hyprland's blur behind it (the bar sets that layer rule
  itself, at start and after every config reload).
- **Drag a widget or a tray icon** to move it. A line shows where it will land; the
  dragged item follows the pointer. A short press is still a click.
- Every tray icon (the Maprisma apps, NordVPN, …) is an item of its own and can be
  placed anywhere. Icons nobody placed sit together where `tray` is.
- Colours come from Caelestia's `~/.local/state/caelestia/scheme.json` and follow
  every theme change. Symbolic tray icons take the bar's text colour.

Widgets: `launcher` (left: Maprisma Launcher, right: Caelestia's launcher),
`workspaces`, `clock` (click: date), `bluetooth` and `network` (click: Maprisma
Bluetooth / WLAN Monitor; network right: connection editor), `audio` (left: mixer,
right: mute, wheel: volume), `power` (Caelestia's session menu).

## bar.json

`~/.config/maprisma-bar/bar.json` holds the layout. The bar rewrites it on every drag
or background change and follows changes other programs make to it.

```json
{
  "version": 1,
  "background": "opaque",
  "left": ["launcher", "workspaces"],
  "center": ["clock"],
  "right": ["tray", "bluetooth", "network", "audio", "power"]
}
```

- `background`: `clear`, `glassy` or `opaque`.
- `left`, `center`, `right`: the zones, in order. An entry is a widget id, `tray`
  (all tray icons without a place of their own), or `tray:<id>` (one tray icon, by its
  StatusNotifierItem id, e.g. `tray:maprisma-llm-monitor`; a second copy of an app
  gets `#2`). A placed icon whose app isn't running keeps its place and is hidden.
- Anything unknown is dropped; a missing widget comes back in its default zone, a
  missing `tray` at the start of `right`. So a file with only some entries is valid.

## Install

```sh
./install.sh            # runs the tests, installs ~/.config/quickshell/maprisma-bar, restarts it
qs -c maprisma-bar -n -d  # start (login: from ~/.config/caelestia/hypr-user.lua)
tests/run.sh            # the layout model's tests (qml6, headless)
```

Needs Quickshell 0.3 (with the SystemTray, Pipewire, Bluetooth and Hyprland
modules), `nmcli`, and a Nerd Font (JetBrainsMono Nerd Font).

MIT license.
