#!/bin/bash
# Compile GLSL shaders to Qt 6 shader bundles (.qsb)
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
QSB_BIN="/usr/lib/qt6/bin/qsb"

if ! command -v "$QSB_BIN" >/dev/null 2>&1; then
    QSB_BIN="$(command -v qsb || command -v qsb6 || true)"
fi

if [[ -z "$QSB_BIN" || ! -x "$QSB_BIN" ]]; then
    echo "Warning: qsb tool not found in /usr/lib/qt6/bin or PATH." >&2
    exit 1
fi

echo "Compiling shaders with $QSB_BIN..."
mkdir -p "$REPO_DIR/shaders"

"$QSB_BIN" --qt6 --batchable "$REPO_DIR/shaders/dither.frag" -o "$REPO_DIR/shaders/dither.frag.qsb"
echo "Compiled: $REPO_DIR/shaders/dither.frag.qsb"

"$QSB_BIN" --qt6 --batchable "$REPO_DIR/shaders/dither_scrim.frag" -o "$REPO_DIR/shaders/dither_scrim.frag.qsb"
echo "Compiled: $REPO_DIR/shaders/dither_scrim.frag.qsb"
