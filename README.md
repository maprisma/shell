# Maprisma Shell

The whole desktop shell of a Hyprland session in one [Quickshell](https://quickshell.org)
config, in the colours of Maprisma Theme:

- **Bar** on every screen, behaving like Omarchy's bar (details below).
- **Wallpaper** (shell.json `wallpaper`; Maprisma Theme sets it).
- **Notifications**: the shell is the notification server; popups at the top right, with
  their actions. Click: the default action. ✕ or a right-click: dismiss.
- **Volume and brightness card** at the bottom when either changes. Brightness goes through
  `brightnessctl` (a backlight, e.g. a laptop).
- **Lock screen** with the time and a password field (PAM: `assets/pam.d/passwd`,
  pam_unix with faillock).
- **Idle**: lock, then the screens off, then suspend (shell.json `idle`). Nothing happens
  while media plays (unless `whilePlaying`) or while an app inhibits idle.
- **Session menu**: lock, suspend, log out, restart, shut down.
- **Tray menus** in the theme's colours, submenus in place.

Popups are full-screen, see-through Overlay surfaces: a click outside or Escape closes them.

## The bar

- **Double-click empty bar space** to cycle the background: clear → glassy → opaque.
  Glassy is see-through with Hyprland's blur behind it (the shell sets that layer rule
  itself, at start and after every config reload).
- **Drag a widget or a tray icon** to move it. A line shows where it will land; the
  dragged item follows the pointer. A short press is still a click.
- Every tray icon is an item of its own and can be placed anywhere. Icons nobody placed
  sit together where `tray` is. Symbolic tray icons take the bar's text colour.
- It sits on the Overlay layer (above full-screen surfaces of other shells) and drops
  below a full-screen window.

Widgets: `launcher` (left: Maprisma Launcher, right: the app launcher fuzzel),
`workspaces`, `clock` (click: date), `bluetooth` and `network` (click: Maprisma
Bluetooth / WLAN Monitor; network right: connection editor), `audio` (left: mixer, a
second click closes it; right: mute, wheel: volume), `power` (the session menu).

## Files

| File | What |
|---|---|
| `~/.config/maprisma-shell/bar.json` | the bar's layout (below); Maprisma Manager writes it too |
| `~/.config/maprisma-shell/shell.json` | `wallpaper` (a path) and `idle` |
| `~/.local/state/maprisma-shell/scheme.json` | the colours, written by Maprisma Theme |

All are followed live. Write them atomically (a temporary file, then rename); a
half-written file is ignored.

### shell.json

```json
{
  "wallpaper": "/home/me/Pictures/wall.jpg",
  "idle": { "lock": 180, "screenOff": 300, "suspend": 600, "whilePlaying": false }
}
```

Idle times are seconds; 0 turns a step off. Missing keys take these defaults.

### scheme.json

`{"name": …, "mode": "dark"|"light", "colours": {"<Material name>": "rrggbb", …}}`. The
shell reads surface, surfaceContainer, surfaceContainerHigh, onSurface, onSurfaceVariant,
outline, primary, onPrimary and error.

### bar.json

```json
{
  "version": 1,
  "background": "opaque",
  "left": ["launcher", "workspaces"],
  "center": ["clock"],
  "right": ["tray", "bluetooth", "network", "audio", "power"],
  "hidden": []
}
```

- `background`: `clear`, `glassy` or `opaque`.
- `left`, `center`, `right`: the zones, in order. An entry is a widget id, `tray`
  (all tray icons without a place of their own), or `tray:<id>` (one tray icon, by its
  StatusNotifierItem id, e.g. `tray:maprisma-llm-monitor`; a second copy of an app
  gets `#2`). A placed icon whose app isn't running keeps its place and is hidden.
- `hidden`: widgets and `tray:<id>` icons taken off the bar (Maprisma Manager's
  "take out"); never `tray` itself. A hidden entry is drawn nowhere, not even in
  the `tray` group, and wins over a zone and over a missing widget coming back.
- Anything unknown is dropped; a missing widget comes back in its default zone (unless
  hidden), a missing `tray` at the start of `right`.

## Keys and commands

Hyprland binds reach the shell as global shortcuts, scripts through IPC:

| Global shortcut (`hl.dsp.global(…)`) | IPC (`qs -c maprisma-shell ipc call shell …`) |
|---|---|
| `maprisma:lock` | `lock`, `unlock` |
| `maprisma:session` | `session` |
| `maprisma:clearNotifs` | `clearNotifs`, `doNotDisturb` |
| `maprisma:launcher` | `launcher` |
| `maprisma:brightnessUp`, `maprisma:brightnessDown` | `brightness <step>` |

Helper commands, installed to `~/.local/bin`:

- `maprisma-screenshot [screen|region|freeze]`: to ~/Pictures/Screenshots and the clipboard
- `maprisma-record [-s] [-r]`: gpu-screen-recorder to ~/Videos/Recordings; again stops it
- `maprisma-clipboard [-d]`: cliphist history in fuzzel (pick copies, `-d` deletes)
- `maprisma-emoji [-p]`: emoji picker in fuzzel (clipboard; `-p` also types it)

## Install

```sh
./install.sh                # tests, ~/.config/quickshell/maprisma-shell, helpers, restart
qs -c maprisma-shell -n -d  # start (login: from Hyprland's execs)
tests/run.sh                # the layout model's tests (qml6, headless)
```

A first install takes over Maprisma Bar's `~/.config/maprisma-bar/bar.json`.

Needs Quickshell 0.3, `nmcli`, a Nerd Font (JetBrainsMono Nerd Font), and for the
helpers grim, slurp, wl-clipboard, cliphist, fuzzel, wtype and gpu-screen-recorder.

MIT license.
