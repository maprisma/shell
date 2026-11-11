#!/usr/bin/env bash
# The layout model's tests, headless (no display, no Quickshell needed).
set -euo pipefail
cd "$(dirname "$0")"
unset DISPLAY WAYLAND_DISPLAY
QT_QPA_PLATFORM=offscreen QT_FORCE_STDERR_LOGGING=1 timeout 60 qml6 model_test.qml
