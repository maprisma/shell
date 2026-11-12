#!/usr/bin/env bash
# Installs Maprisma Shell as the Quickshell config "maprisma-shell" and restarts it.
# Start it at login with: qs -c maprisma-shell -n -d
set -euo pipefail
cd "$(dirname "$0")"
tests/run.sh
dest="${XDG_CONFIG_HOME:-$HOME/.config}/quickshell/maprisma-shell"
rm -rf "$dest.new"
mkdir -p "$dest.new"
cp -r shell.qml Bar.qml Slot.qml BarModel.js services widgets modules assets "$dest.new/"
rm -rf "$dest"
mv "$dest.new" "$dest"
# Helper commands for the Hyprland keys (screenshot, recording, clipboard, emoji).
mkdir -p "$HOME/.local/bin"
install -m 755 bin/maprisma-* "$HOME/.local/bin/"
cfg="${XDG_CONFIG_HOME:-$HOME/.config}"
mkdir -p "$cfg/maprisma-shell"
# Maprisma Bar's layout moves over once.
if [[ ! -e $cfg/maprisma-shell/bar.json && -f $cfg/maprisma-bar/bar.json ]]; then
  cp "$cfg/maprisma-bar/bar.json" "$cfg/maprisma-shell/bar.json"
fi
# A running copy (installed, from this folder, or the old Maprisma Bar) makes way for the new one.
qs kill -c maprisma-shell >/dev/null 2>&1 || true
qs kill -c maprisma-bar >/dev/null 2>&1 || true
qs kill -p "$PWD/shell.qml" >/dev/null 2>&1 || true
if [[ -n ${WAYLAND_DISPLAY:-} ]]; then
  setsid -f qs -c maprisma-shell -n -d >/dev/null 2>&1 < /dev/null || true
fi
echo "Installed Maprisma Shell into $dest"
