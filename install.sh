#!/usr/bin/env bash
# Installs Maprisma Bar as the Quickshell config "maprisma-bar" and restarts it.
# Start it at login with: qs -c maprisma-bar -n -d
set -euo pipefail
cd "$(dirname "$0")"
tests/run.sh
dest="${XDG_CONFIG_HOME:-$HOME/.config}/quickshell/maprisma-bar"
rm -rf "$dest.new"
mkdir -p "$dest.new"
cp -r shell.qml Bar.qml Slot.qml BarModel.js services widgets "$dest.new/"
rm -rf "$dest"
mv "$dest.new" "$dest"
mkdir -p "${XDG_CONFIG_HOME:-$HOME/.config}/maprisma-bar"
# A running copy (installed or from this folder) makes way for the new one.
qs kill -c maprisma-bar >/dev/null 2>&1 || true
qs kill -p "$PWD/shell.qml" >/dev/null 2>&1 || true
if [[ -n ${WAYLAND_DISPLAY:-} ]]; then
  setsid -f qs -c maprisma-bar -n -d >/dev/null 2>&1 < /dev/null || true
fi
echo "Installed Maprisma Bar into $dest"
